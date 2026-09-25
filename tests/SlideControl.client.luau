local p=game.Players.LocalPlayer
local c=require(p.PlayerScripts.MetalSlideControl)
local m=require(p.PlayerScripts.MetalMotion)
local config=require(game.ReplicatedStorage.MetalTuningConfig)
local settings=table.clone(m.Snapshot(true).values)
settings.SlideSMinSpeed=0
local v=Vector3.new(0,0,-100)
assert(math.abs(c.Step(v,Vector2.new(0,1),settings,1).Magnitude-125)<.01)
assert(c.Step(Vector3.new(0,0,-250),Vector2.new(0,1),settings,1).Magnitude==250)
assert(c.Step(v,Vector2.new(0,-1),settings,2)==Vector3.zero)
assert(c.Step(v,Vector2.new(-1,0),settings,.1).X<0)
assert(c.Step(v,Vector2.new(1,0),settings,.1).X>0)
assert(math.abs(c.Step(v,Vector2.new(1,0),settings,.1).Magnitude-100)<.01)
local old=m.Snapshot(true)
for _,k in {"SlideWAcceleration","SlideWTopSpeed","SlideBraking","SlideLeftSteering","SlideRightSteering"} do
 assert(p.PlayerGui.MetalTuning.Panel.Content.Sliders:FindFirstChild(k,true))
 old.values[k]=nil old.ranges[k]=nil
end
assert(config.Validate(old).values.SlideWTopSpeed==200)
local h=p.Character.Humanoid local r=p.Character.HumanoidRootPart
local origin=r.CFrame
local originalRead=c.Read
local anchor=Instance.new("Part") anchor.Name="SlideTestAnchor" anchor.Anchored=true anchor.Size=Vector3.new(4,4,4) anchor.Position=Vector3.new(800,3,1000) anchor.Parent=workspace.MetalAnchors
m.Cancel() r.CFrame=CFrame.new(800,5,800) r.AssemblyLinearVelocity=Vector3.zero task.wait(1)
c.Read=function() return Vector2.zero end
assert(m.Start(anchor,1)) task.wait(.4)
m.Stop() c.Read=function() return Vector2.new(0,1) end
local start=Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude
task.wait(.4)
local boosted=Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude
assert(boosted>start+2,"W coasting boost did not increase speed")
c.Read=function() return Vector2.new(1,0) end task.wait(.25)
assert(p.Character:GetAttribute("SlideSideLean")>.5)
local floor=m.Settings.SlideSMinSpeed m.SetSetting("SlideSMinSpeed",0)
c.Read=function() return Vector2.new(0,-1) end task.wait(3)
m.SetSetting("SlideSMinSpeed",floor)
assert(Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude<2,"S did not stop coast")
m.Cancel() c.Read=originalRead anchor:Destroy() r.CFrame=origin r.AssemblyLinearVelocity=Vector3.zero
workspace:SetAttribute("SlideControlTest","PASS: boost "..string.format("%.1f -> %.1f",start,boosted)..", steering lean, braking stop, curves, caps, UI and migration")
