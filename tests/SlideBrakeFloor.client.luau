local p=game.Players.LocalPlayer local m=require(p.PlayerScripts.MetalMotion) local c=require(p.PlayerScripts.MetalSlideControl)
local saved=m.Snapshot(true) local read=c.Read local root=p.Character.HumanoidRootPart local origin=root.CFrame
local anchor=Instance.new("Part") anchor.Name="SBrakeTest" anchor.Anchored=true anchor.Position=Vector3.new(800,3,600) anchor.Parent=workspace.MetalAnchors
local ok,err=pcall(function()
 local settings=table.clone(saved.values) settings.SlideSMinSpeed=30 settings.SlideBraking=80
 assert(math.abs(c.Step(Vector3.new(100,0,0),Vector2.new(0,-1),settings,2).Magnitude-30)<.001)
 assert(c.Step(Vector3.new(20,0,0),Vector2.new(0,-1),settings,2).Magnitude==20)
 settings.SlideSMinSpeed=0 assert(c.Step(Vector3.new(100,0,0),Vector2.new(0,-1),settings,2)==Vector3.zero)
 local old=table.clone(saved) old.values=table.clone(saved.values) old.ranges=table.clone(saved.ranges)
 old.values.SlideSMinSpeed=nil old.ranges.SlideSMinSpeed=nil
 assert(require(game.ReplicatedStorage.MetalTuningConfig).Validate(old).values.SlideSMinSpeed==30)
 assert(p.PlayerGui.MetalTuning.Panel.Content.Sliders.Sliding.Rows:FindFirstChild("SlideSMinSpeed"))
 m.Cancel() root.CFrame=CFrame.new(800,5,0) root.AssemblyLinearVelocity=Vector3.zero task.wait(.8)
 c.Read=function() return Vector2.zero end m.Start(anchor,1) task.wait(.7)
 c.Read=function() return Vector2.new(0,-1) end task.wait(2)
 local function speed() return Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude end
 assert(math.abs(speed()-30)<2,"powered floor "..speed())
 m.Stop() task.wait(1)
 assert(math.abs(speed()-30)<2,"coasting floor "..speed())
 m.Cancel() task.wait(.3) p.Character.Humanoid.WalkSpeed=20 p.Character.Humanoid:Move(Vector3.zAxis,false) root.AssemblyLinearVelocity=Vector3.new(0,0,20) m.Start(anchor,1) m.Stop() task.wait(.5)
 assert(speed()<22,"S accelerated below floor "..speed())
 workspace:SetAttribute("SBrakeResult","PASS: powered/coasting 30 floor, below-floor no acceleration, zero floor, migration and category")
end)
m.Cancel() c.Read=read m.ApplySettings(saved) anchor:Destroy() root.CFrame=origin root.AssemblyLinearVelocity=Vector3.zero
if not ok then workspace:SetAttribute("SBrakeResult","FAIL: "..tostring(err)) error(err) end