-- Studio-only: temporarily insert under StarterPlayerScripts in a test session.
-- Uses a following anchor to isolate acceleration/cap behavior from the 180-stud range.
local p=game.Players.LocalPlayer local c=p.Character local r=c.HumanoidRootPart local h=c.Humanoid
local m=require(script.Parent.MetalMotion)
local anchor=workspace.MetalAnchors.Anchor1 local original=anchor.CFrame
local results={}
local function check(name,pass,data) table.insert(results,{name=name,pass=pass,data=data}) end
local v=Vector3.zero
for i=1,480 do v=m.StepGround(v,Vector3.new(50,0,0),1/60,true,400,8,5) end
check("50 acceleration reaches 400 in 8 seconds",math.abs(v.X-400)<.01,v.X)
check("Stop cutoff snaps remaining slide to zero",m.StepGround(Vector3.new(5,0,0),Vector3.zero,.016,false,0,0,5)==Vector3.zero)
check("Zero friction preserves coast speed",m.StepGround(Vector3.new(20,0,0),Vector3.zero,1,false,0,0,5).X==20)
check("Friction slows coast",m.StepGround(Vector3.new(20,0,0),Vector3.zero,.1,false,0,2.3,0).X<20)
check("Editable range",m.SetRange("PullSpeed",0,1000) and m.SetSetting("PullSpeed",800)==800)
check("Reject reversed range",not m.SetRange("PullSpeed",100,50))
check("Reject nonfinite",not m.SetRange("PullSpeed",0,math.huge))
m.ResetSettings() m.SetSetting("PullFalloff",0) m.SetSetting("PushFalloff",0) -- Isolate acceleration and speed caps.
local function run(accel,friction,duration,sign)
 m.Cancel()
 r.CFrame=CFrame.new(-800,3.01,1010) r.AssemblyLinearVelocity=Vector3.zero task.wait(.4)
 m.SetRange("PullAcceleration",0,1000) m.SetSetting("PullAcceleration",accel)
 m.SetRange("PushAcceleration",0,1000) m.SetSetting("PushAcceleration",accel)
 m.SetSetting("PullSpeed",100) m.SetSetting("PushSpeed",100) m.SetSetting("CoastDrag",friction)
 anchor.CFrame=CFrame.new(r.Position+Vector3.new(100*sign,0,0))
 local follow=game:GetService("RunService").Heartbeat:Connect(function() anchor.CFrame=CFrame.new(r.Position+Vector3.new(100*sign,0,0)) end)
 m.Start(anchor,sign)
 task.wait(.5) local early=r.AssemblyLinearVelocity.Magnitude
 task.wait(duration-.5)
 local speed=r.AssemblyLinearVelocity.Magnitude
 check("Live top speed accel "..accel.." friction "..friction.." sign "..sign,math.abs(speed-100)<2,{early=early,final=speed})
 m.Stop(sign) follow:Disconnect()
 task.wait(.1) check("Coast retains slide",c:GetAttribute("MetalSliding")==true)
 m.Cancel()
end
run(20,2.3,5.5,1)
run(100,8,1.5,1)
run(100,2.3,1.5,-1)
r.CFrame=CFrame.new(0,3.01,300) r.AssemblyLinearVelocity=Vector3.zero task.wait(.3)
m.SetSetting("StopSpeed",10) m.SetSetting("CoastDrag",0)
anchor.CFrame=CFrame.new(r.Position+Vector3.new(50,0,0))
m.Start(anchor,1) m.Stop(1) r.AssemblyLinearVelocity=Vector3.new(9,0,0)
task.wait(.1)
check("Live cutoff",Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude<.01 and not c:GetAttribute("MetalSliding"),r.AssemblyLinearVelocity.Magnitude)
m.Cancel() m.ResetSettings() m.SetSetting("PullFalloff",0) m.SetSetting("PushFalloff",0) -- Isolate acceleration and speed caps. anchor.CFrame=original
r.CFrame=CFrame.new(0,5,0) r.AssemblyLinearVelocity=Vector3.zero
p.PlayerGui.MetalTuning:SetAttribute("ShowSpeedometer",true)
task.wait(.2)
check("Speedometer enabled",p.PlayerGui.MetalTuning.Speedometer.Visible)
check("Sliders with min/max boxes",p.PlayerGui.MetalTuning.Panel.Content.Sliders:FindFirstChild("PullSpeed",true):FindFirstChild("Min")~=nil)
workspace:SetAttribute("SpeedTuningTests",game.HttpService:JSONEncode(results))
script:Destroy()
