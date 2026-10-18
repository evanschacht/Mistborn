-- Run as a temporary LocalScript in a fresh Studio Play session after the panel loads.
-- Exercises the real Motion module; never invokes Save or writes a DataStore.
-- Captures and restores both the saved baseline and current live tuning on every exit.
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local player=Players.LocalPlayer
local motion=require(player.PlayerScripts:WaitForChild("MetalMotion"))
local config=require(game.ReplicatedStorage:WaitForChild("MetalTuningConfig"))
local gui=assert(player.PlayerGui:WaitForChild("MetalTuning",30),"Tuning panel did not load")
gui:WaitForChild("Panel"):WaitForChild("Content"):WaitForChild("SaveStatus")
local deadline=os.clock()+10
while gui:GetAttribute("MasterRevision")==nil and os.clock()<deadline do task.wait() end
local module=player.PlayerScripts:WaitForChild("MetalMotion")
local originalLive=motion.Snapshot()
local originalSaved=motion.GetSavedSettings()
local originalRevision=gui:GetAttribute("MasterRevision")
local checks={}
local function check(name,passed)
 table.insert(checks,{name=name,passed=passed==true})
 assert(passed,name)
end
local function same(a,b)
 if not a or not b or a.showSpeedometer~=b.showSpeedometer then return false end
 for _,spec in motion.SettingSpecs do
  local key=spec.key
  if a.values[key]~=b.values[key] or a.ranges[key][1]~=b.ranges[key][1] or a.ranges[key][2]~=b.ranges[key][2] then return false end
 end
 return true
end
local function changed(snapshot)
 local copy=assert(config.Validate(snapshot))
 for _,spec in motion.SettingSpecs do
  local key=spec.key
  copy.ranges[key]={(key=="ForceNearClamp" or key=="ForceFarClamp") and 0.1 or 0,10000}
  copy.values[key]=snapshot.values[key]+spec.step*2
 end
 copy.showSpeedometer=not snapshot.showSpeedometer
 return assert(config.Validate(copy))
end
local passed,problem=xpcall(function()
 check("Fresh join settings equal saved baseline",same(originalLive,originalSaved))
 motion.ResetSettings()
 check("Reset immediately after join changes nothing",same(motion.Snapshot(),originalLive))
 check("Join speedometer agrees with panel",gui:GetAttribute("ShowSpeedometer")==originalSaved.showSpeedometer)

 local preset=assert(config.Validate(require(game.ReplicatedStorage.MetalTuningPreset)))
 check("Portable preset is accepted as saved defaults",motion.ApplySavedSettings(preset))
 local edited=changed(preset)
 check("Local preview applies",motion.ApplySettings(edited))
 check("Local preview does not replace saved defaults",same(motion.GetSavedSettings(),preset))
 for _,spec in motion.SettingSpecs do
  local key=spec.key
  check("Install edited fixture: "..key,motion.ApplySettings(edited))
  check("Editable bounds accept wider range: "..key,motion.SetRange(key,edited.ranges[key][1],edited.ranges[key][2]))
  check("Editable value accepts preview: "..key,motion.SetSetting(key,edited.values[key])~=nil)
  motion.ResetSetting(key)
  local actual=motion.Snapshot()
  check("Individual value reset: "..key,actual.values[key]==preset.values[key])
  check("Individual bounds reset: "..key,actual.ranges[key][1]==preset.ranges[key][1] and actual.ranges[key][2]==preset.ranges[key][2])
  check("Individual reset preserves speedometer: "..key,actual.showSpeedometer==edited.showSpeedometer)
  local othersUnchanged=true
  for _,other in motion.SettingSpecs do
   if other.key~=key then
    othersUnchanged=othersUnchanged and actual.values[other.key]==edited.values[other.key]
     and actual.ranges[other.key][1]==edited.ranges[other.key][1]
     and actual.ranges[other.key][2]==edited.ranges[other.key][2]
   end
  end
  check("Individual reset preserves all other settings: "..key,othersUnchanged)
  motion.SetSetting(key,-10000)
  check("Restored lower bound clamps edits: "..key,motion.Settings[key]>=preset.ranges[key][1])
  motion.SetSetting(key,20000)
  check("Restored upper bound clamps edits: "..key,motion.Settings[key]<=preset.ranges[key][2])
 end
 motion.ResetSettings()
 check("Reset all restores saved preset values, bounds and speedometer",same(motion.Snapshot(),preset))
 task.wait()
 check("Reset all synchronizes panel speedometer",gui:GetAttribute("ShowSpeedometer")==preset.showSpeedometer)
 check("Reset all synchronizes speedometer visibility",gui.Speedometer.Visible==preset.showSpeedometer)
 check("Reset all synchronizes speedometer toggle",gui.Panel.Content.SpeedometerToggle.Text==(preset.showSpeedometer and "Speedometer: ON" or "Speedometer: OFF"))
 check("Reset all did not substitute factory acceleration",motion.Settings.PullAcceleration==preset.values.PullAcceleration)
 check("Reset all did not substitute factory sensing range",motion.Settings.AnchorRange==preset.values.AnchorRange)

 local input=changed(preset)
 local master=assert(config.Validate(input))
 check("Accepted master promotes saved baseline",motion.ApplySavedSettings(input))
 input.values.PullAcceleration=1
 input.ranges.PullAcceleration[2]=2
 input.showSpeedometer=not input.showSpeedometer
 check("Saved baseline is isolated from input tables",same(motion.GetSavedSettings(),master))
 local exported=motion.GetSavedSettings()
 exported.values.AnchorRange=1
 exported.ranges.AnchorRange[2]=2
 check("Saved baseline getter returns an isolated copy",same(motion.GetSavedSettings(),master))
 local snapshot=motion.Snapshot()
 snapshot.values.AnchorRange=1
 snapshot.ranges.AnchorRange[2]=2
 check("Live snapshot returns isolated ranges and values",same(motion.Snapshot(),master))
 check("Snapshot omitted flag follows current speedometer",motion.Snapshot().showSpeedometer==master.showSpeedometer)
 check("Snapshot explicit flag remains supported",motion.Snapshot(not master.showSpeedometer).showSpeedometer~=master.showSpeedometer)
 check("Explicit snapshot flag does not change live speedometer",motion.Snapshot().showSpeedometer==master.showSpeedometer)
 local encoded=HttpService:JSONDecode(assert(module:GetAttribute("SavedTuningDefaults")))
 check("Shared baseline attribute contains accepted master",same(config.Validate(encoded),master))

 check("Apply a later local edit",motion.ApplySettings(preset))
 motion.ResetSettings()
 check("Reset after master update restores latest saved master",same(motion.Snapshot(),master))
 local invalid=assert(config.Validate(preset))
 invalid.ranges.AnchorRange={5,5}
 check("Invalid saved baseline rejected",not motion.ApplySavedSettings(invalid))
 check("Rejected baseline preserves live state",same(motion.Snapshot(),master))
 check("Rejected baseline preserves saved state",same(motion.GetSavedSettings(),master))
 local beforeUnknown=motion.Snapshot()
 motion.ResetSetting("UnknownSetting")
 check("Unknown key reset preserves state",same(motion.Snapshot(),beforeUnknown))
 check("Reset does not advance persisted master revision",gui:GetAttribute("MasterRevision")==originalRevision)
end,debug.traceback)
local restored,restoreProblem=pcall(function()
 assert(motion.ApplySavedSettings(originalSaved),"Could not restore original saved baseline")
 assert(motion.ApplySettings(originalLive),"Could not restore original live tuning")
 gui:SetAttribute("ShowSpeedometer",originalLive.showSpeedometer)
 assert(same(motion.GetSavedSettings(),originalSaved),"Original saved baseline was not restored")
 assert(same(motion.Snapshot(),originalLive),"Original live tuning was not restored")
end)
player:SetAttribute("ResetDefaultsResults",HttpService:JSONEncode({
 passed=passed and restored,checks=checks,checkCount=#checks,error=problem,
 restored=restored,restoreError=restoreProblem,liveDataStoreWritten=false,
}))
if not passed then warn(problem) end
if not restored then warn(restoreProblem) end
script:Destroy()
