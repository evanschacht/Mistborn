-- Studio-only integration probe: client-local StringValue changes exercise the
-- actual tuning panel Changed/applyMaster path. Never invokes a remote or saves.
-- Restart Play afterward: the panel's private revision cannot be rewound.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio(),"This fixture must only run in Studio")
local HttpService=game:GetService("HttpService")
local player=game.Players.LocalPlayer
local motion=require(player.PlayerScripts:WaitForChild("MetalMotion"))
local config=require(game.ReplicatedStorage:WaitForChild("MetalTuningConfig"))
local gui=assert(player.PlayerGui:WaitForChild("MetalTuning",30))
local content=gui:WaitForChild("Panel"):WaitForChild("Content")
local status=content:WaitForChild("SaveStatus")
local state=game.ReplicatedStorage:WaitForChild("MetalTuningMasterState",10)
assert(state,"Replicated tuning state missing")
local deadline=os.clock()+10
while gui:GetAttribute("MasterRevision")==nil and os.clock()<deadline do task.wait() end
local originalValue=state.Value
local originalRecord=HttpService:JSONDecode(originalValue)
local originalLive=motion.Snapshot()
local originalSaved=motion.GetSavedSettings()
local originalStatus=status.Text
local originalRevision=gui:GetAttribute("MasterRevision")
local revision=math.max(tonumber(originalRecord.revision) or 0,originalRevision or 0)+1000
local checks={}
local allowed={[originalValue]=true}
local expectedValue=originalValue
local externalChange=false
local connection=state.Changed:Connect(function(value)
 if not allowed[value] then externalChange=true end
end)
local function check(name,ok)
 table.insert(checks,{name=name,passed=ok==true})
 assert(ok,name)
end
local function same(a,b)
 if not a or not b or a.showSpeedometer~=b.showSpeedometer then return false end
 for _,spec in motion.SettingSpecs do
  local key=spec.key
  if a.values[key]~=b.values[key] or a.ranges[key][1]~=b.ranges[key][1] or a.ranges[key][2]~=b.ranges[key][2] then return false end
 end
 return true
end
local function publishLocal(nextRevision,data)
 assert(not externalChange and state.Value==expectedValue,"External master changed during fixture; aborting local simulation")
 local encoded=HttpService:JSONEncode({revision=nextRevision,data=data})
 allowed[encoded]=true
 expectedValue=encoded
 state.Value=encoded
 -- Allow real panel Changed and its attribute/UI signals to settle.
 task.wait()
 task.wait()
 assert(not externalChange and state.Value==encoded,"External master changed during fixture; aborting local simulation")
end
local function speedMatches(data)
 return gui:GetAttribute("ShowSpeedometer")==data.showSpeedometer
  and gui.Speedometer.Visible==data.showSpeedometer
  and content.SpeedometerToggle.Text==(data.showSpeedometer and "Speedometer: ON" or "Speedometer: OFF")
end
local passed,problem=xpcall(function()
 local master=assert(config.Validate(originalSaved))
 master.ranges.PullAcceleration={0,10000}
 master.values.PullAcceleration=math.min(9990,master.values.PullAcceleration+20)
 master.ranges.AnchorRange={0,10000}
 master.values.AnchorRange=math.min(9990,master.values.AnchorRange+10)
 master.showSpeedometer=not master.showSpeedometer
 master=assert(config.Validate(master))
 publishLocal(revision,master)
 check("Higher replicated revision is accepted",gui:GetAttribute("MasterRevision")==revision)
 check("Actual panel broadcast updates live tuning",same(motion.Snapshot(),master))
 check("Actual panel broadcast updates reset baseline",same(motion.GetSavedSettings(),master))
 check("Actual panel broadcast updates speedometer UI",speedMatches(master))
 local row=assert(content.Sliders:FindFirstChild("PullAcceleration",true))
 check("Actual panel broadcast refreshes slider value",tonumber(row.Value.Text)==master.values.PullAcceleration)
 check("Actual panel broadcast refreshes slider bounds",tonumber(row.Min.Text)==master.ranges.PullAcceleration[1] and tonumber(row.Max.Text)==master.ranges.PullAcceleration[2])

 check("Local preview edit accepted",motion.ApplySettings(originalLive))
 check("Local preview preserves broadcast baseline",same(motion.GetSavedSettings(),master))
 motion.ResetSetting("PullAcceleration")
 check("Individual reset restores latest broadcast value",motion.Settings.PullAcceleration==master.values.PullAcceleration)
 local low,high=motion.GetRange("PullAcceleration")
 check("Individual reset restores latest broadcast bounds",low==master.ranges.PullAcceleration[1] and high==master.ranges.PullAcceleration[2])
 motion.ResetSettings()
 task.wait()
 task.wait()
 check("Reset all restores latest broadcast",same(motion.Snapshot(),master))
 check("Reset all restores broadcast speedometer UI",speedMatches(master))

 publishLocal(revision-1,originalSaved)
 check("Stale positive revision is ignored",gui:GetAttribute("MasterRevision")==revision and same(motion.Snapshot(),master) and same(motion.GetSavedSettings(),master))
 publishLocal(0,originalSaved)
 check("Revision-zero fallback is ignored",gui:GetAttribute("MasterRevision")==revision and same(motion.Snapshot(),master) and same(motion.GetSavedSettings(),master))
 publishLocal(revision+1,{})
 check("Invalid newer record does not advance revision or defaults",gui:GetAttribute("MasterRevision")==revision and same(motion.Snapshot(),master) and same(motion.GetSavedSettings(),master))

 local nextMaster=assert(config.Validate(master))
 nextMaster.values.PullAcceleration=nextMaster.values.PullAcceleration-10
 nextMaster.showSpeedometer=not nextMaster.showSpeedometer
 publishLocal(revision+2,nextMaster)
 check("Next valid master advances revision",gui:GetAttribute("MasterRevision")==revision+2)
 check("Next valid master replaces baseline and live tuning",same(motion.Snapshot(),nextMaster) and same(motion.GetSavedSettings(),nextMaster))
 check("Next valid master updates speedometer UI",speedMatches(nextMaster))
 check("No unexpected external master change observed",not externalChange)
end,debug.traceback)
local restored,restoreProblem=pcall(function()
 assert(not externalChange and state.Value==expectedValue,"External master changed; restart Play instead of overwriting it")
 state.Value=originalValue
 assert(motion.ApplySavedSettings(originalSaved),"Could not restore original baseline")
 assert(motion.ApplySettings(originalLive),"Could not restore original live settings")
 gui:SetAttribute("ShowSpeedometer",originalLive.showSpeedometer)
 status.Text=originalStatus
 task.wait()
 task.wait()
 assert(state.Value==originalValue and not externalChange,"Original replicated value was not restored")
 assert(same(motion.GetSavedSettings(),originalSaved) and same(motion.Snapshot(),originalLive),"Original tuning was not restored")
 assert(speedMatches(originalLive),"Original speedometer UI was not restored")
end)
connection:Disconnect()
player:SetAttribute("ResetDefaultsMasterResults",HttpService:JSONEncode({
 passed=passed and restored,checks=checks,checkCount=#checks,error=problem,
 restored=restored,restoreError=restoreProblem,externalChange=externalChange,
 liveDataStoreWritten=false,serverStateWritten=false,requiresFreshSession=true,
}))
if not passed then warn(problem) end
if not restored then warn(restoreProblem) end
script:Destroy()
