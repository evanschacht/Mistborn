local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local p=Players.LocalPlayer
local c=p.Character or p.CharacterAdded:Wait()
local h=c:WaitForChild("Humanoid")
local r=c:WaitForChild("HumanoidRootPart")
local Motion=require(script.Parent:WaitForChild("MetalMotion"))
local anchor=workspace.MetalAnchors.Anchor1
local original=anchor.CFrame
local camera=workspace.CurrentCamera
local results={}
local function log(name,pass,data) table.insert(results,{name=name,pass=pass,data=data}) print("AERIAL_TEST",name,pass,Http:JSONEncode(data or {})) end
local function vec(v) return {x=v.X,y=v.Y,z=v.Z} end
local function setup(y,v)
 Motion.Cancel()
 r.CFrame=CFrame.new(0,y,300)
 r.AssemblyLinearVelocity=v or Vector3.zero
 r.AssemblyAngularVelocity=Vector3.zero
 h:ChangeState(Enum.HumanoidStateType.Freefall)
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt(r.Position+Vector3.new(0,8,24),r.Position+Vector3.new(0,8,-20))
 task.wait(.15)
end
task.wait(1)
local ok,err=pcall(function()
 setup(1000)
 anchor.CFrame=CFrame.new(r.Position-Vector3.new(35,65,0))
 r.AssemblyLinearVelocity=Vector3.zero
 Motion.Start(anchor,-1)
 task.wait(.8)
 local release=r.AssemblyLinearVelocity
 Motion.Stop(-1)
 local immediate=r.AssemblyLinearVelocity
 local samples={}
 for i=1,12 do task.wait(.06) table.insert(samples,{t=os.clock(),v=vec(r.AssemblyLinearVelocity),state=h:GetState().Name}) end
 local last=r.AssemblyLinearVelocity
 local crossed=false
 for i=2,#samples do if samples[i-1].v.y>=0 and samples[i].v.y<0 then crossed=true end end
 local acceleration=(samples[#samples].v.y-samples[1].v.y)/(samples[#samples].t-samples[1].t)
 log("Diagonal push and release",release.X>15 and release.Y>0 and (release-immediate).Magnitude<.001,{release=vec(release),immediate=vec(immediate)})
 log("Horizontal momentum",math.abs(last.X-release.X)<2,{before=release.X,after=last.X})
 log("Smooth apex and fall",crossed and acceleration < -140 and acceleration > -180,{verticalAcceleration=acceleration,samples=samples})
 setup(1000)
 r.AssemblyLinearVelocity=Vector3.new(0,0,-70)
 Motion.Start(anchor,1) Motion.Stop(1)
 Motion.InputBegan(Enum.KeyCode.A,false) task.wait(.45) Motion.InputEnded(Enum.KeyCode.A)
 local left=r.AssemblyLinearVelocity
 Motion.InputBegan(Enum.KeyCode.D,false) task.wait(.9) Motion.InputEnded(Enum.KeyCode.D)
 local right=r.AssemblyLinearVelocity
 log("Left and right air steering",left.X < -5 and right.X>3 and math.abs(left.Z+70)<3 and math.abs(right.Z+70)<3,{left=vec(left),right=vec(right)})
 task.wait(.2)
 local rootJoint=c:FindFirstChild("Root",true)
 local _,tiltAngle=rootJoint.Transform.Rotation:ToAxisAngle()
 log("Visual lean",math.abs(tiltAngle)>.01 and math.abs(tiltAngle)<.4,{angleDegrees=math.deg(tiltAngle)})
 log("Airborne presentation",h:GetState()==Enum.HumanoidStateType.Freefall and not h.PlatformStand,{state=h:GetState().Name,platformStand=h.PlatformStand,rootJoint= rootJoint and tostring(rootJoint.Transform) or "missing"})
 for _,key in {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D} do
  setup(3.1)
  task.wait(.55)
  log("Ground reset "..key.Name,h.FloorMaterial~=Enum.Material.Air,{floor=h.FloorMaterial.Name})
  task.wait(.7)
  setup(500)
  r.AssemblyLinearVelocity=Vector3.zero
  Motion.Start(anchor,1) Motion.Stop(1)
  local direction=Motion.CameraDirection(key,camera.CFrame)
  Motion.InputBegan(key,false) Motion.InputEnded(key)
  task.wait(.07)
  Motion.InputBegan(key,false) Motion.InputEnded(key)
  task.wait(.2)
  local velocity=r.AssemblyLinearVelocity
  log("Double tap "..key.Name,velocity:Dot(direction)>20 and workspace.MetalAwareness:GetAttribute("BoostUsed")==true,{velocity=vec(velocity),along=velocity:Dot(direction)})
  log("Boost cooldown "..key.Name,Motion.RequestBoost(key)==false,{})
  if key==Enum.KeyCode.D then
   task.wait(1.3)
   log("One boost per airtime",Motion.RequestBoost(key)==false,{})
  end
 end
 setup(3.1) task.wait(.6)
 for i=1,20 do Motion.Start(anchor,1) Motion.Start(anchor,-1) Motion.Stop(1) Motion.Stop(-1) end
 task.wait(.5)
 local forces=0 local attachments=0
 for _,o in r:GetChildren() do if o.Name=="MetalMotionForce" then forces+=1 end if o.Name=="MetalMotionAttachment" then attachments+=1 end end
 local _,landAngle=rootJoint.Transform.Rotation:ToAxisAngle()
 log("Landing lean recovery",math.abs(landAngle)<.01,{angleDegrees=math.deg(landAngle)})
 log("Repeated use cleanup",forces==0 and attachments==0,{forces=forces,attachments=attachments,boostUsed=workspace.MetalAwareness:GetAttribute("BoostUsed")})
end)
Motion.Cancel()
anchor.CFrame=original
r.CFrame=CFrame.new(0,5,0) r.AssemblyLinearVelocity=Vector3.zero
camera.CameraType=Enum.CameraType.Custom camera.CameraSubject=h
workspace:SetAttribute("AerialTestResults",Http:JSONEncode({ok=ok,error=err,results=results}))
print("AERIAL_TEST_DONE",ok,err)
