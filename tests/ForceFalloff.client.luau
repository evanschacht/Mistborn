local p=game.Players.LocalPlayer
local m=require(p.PlayerScripts.MetalMotion)
local config=require(game.ReplicatedStorage.MetalTuningConfig)
local saved=m.Snapshot(true)
local r=p.Character.HumanoidRootPart
local original=r.CFrame
local results={}
local function check(name,pass,data) table.insert(results,{name=name,pass=pass,data=data}) end
local s={AnchorRange=290,ForceFalloff=1,ForceNearClamp=5,ForceFarClamp=150}
check("Contact bounded at full strength",config.ForceScale(0,s)==1 and config.ForceScale(5,s)==1)
check("Inverse linear midpoint",config.ForceScale(10,s)==.5 and config.ForceScale(20,s)==.25)
check("Far clamp plateaus",config.ForceScale(150,s)==config.ForceScale(280,s))
check("Range is exact zero cutoff",config.ForceScale(290,s)==0 and config.ForceScale(500,s)==0)
s.ForceFalloff=0 check("Zero falloff gives constant force",config.ForceScale(100,s)==1)
s.ForceFalloff=2 check("Falloff knob steepens curve",config.ForceScale(10,s)<.5)
s.ForceFarClamp=1 check("Far below close remains safe",config.ForceScale(10,s)==1)
local legacy=m.Snapshot(true)
for _,key in {"ForceFalloff","ForceNearClamp","ForceFarClamp"} do legacy.values[key]=nil legacy.ranges[key]=nil end
local migrated=config.Validate(legacy)
check("Older master tuning migrates",migrated and migrated.values.ForceNearClamp==5 and migrated.values.PullAcceleration==legacy.values.PullAcceleration)
local a=Instance.new("Part") a.Name="FalloffTestAnchor" a.Anchored=true a.CanCollide=false a.Parent=workspace.MetalAnchors
local follow
local ok,err=pcall(function()
 m.SetSetting("PullFalloff",1) m.SetSetting("PushFalloff",1) m.SetSetting("ForceNearClamp",5) m.SetSetting("ForceFarClamp",150)
 m.SetSetting("AnchorRange",290)
 m.SetSetting("PullAcceleration",230) m.SetSetting("PushAcceleration",230)
 for _,sign in {1,-1} do for _,distance in {5,20,200} do
  m.Cancel() r.CFrame=CFrame.new(800,150,800) r.AssemblyLinearVelocity=Vector3.zero
  a.Position=r.Position+Vector3.new(distance*sign,0,0)
  follow=game:GetService("RunService").PreSimulation:Connect(function() a.Position=r.Position+Vector3.new(distance*sign,0,0) end)
  assert(m.Start(a,sign)) task.wait(.06)
  local measured=r.MetalMotionForce.Force.Magnitude/r.AssemblyMass
  local expected=230*config.ForceScale(distance,m.Settings)
  check("Live force sign "..sign.." distance "..distance,math.abs(measured-expected)<expected*.12,{measured=measured,expected=expected})
  follow:Disconnect() follow=nil
 end end
 a.Position=r.Position+Vector3.new(300,0,0) task.wait(.1)
 check("Moving out of range stops force",workspace.MetalAwareness:GetAttribute("PushAnchor")=="")
 check("Out of range cannot start",not m.Start(a,1))
end)
if follow then follow:Disconnect() end
m.Cancel() m.ApplySettings(saved) a:Destroy() r.CFrame=original r.AssemblyLinearVelocity=Vector3.zero
if not ok then check("Harness",false,tostring(err)) end
workspace:SetAttribute("ForceFalloffTests",game.HttpService:JSONEncode(results))
script:Destroy()
