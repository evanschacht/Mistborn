-- Floaty traversal layered beneath metal thrust; never edits vertical velocity.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local inputService=game:GetService("UserInputService")
local controls={}
function controls:GetMoveVector()
 if inputService:GetFocusedTextBox() or game:GetService("GuiService").MenuIsOpen then return Vector3.zero end
 local function down(key) return inputService:IsKeyDown(Enum.KeyCode[key]) and 1 or 0 end
 local v=Vector3.new(down("D")-down("A")+down("Right")-down("Left"),0,down("S")-down("W")+down("Down")-down("Up"))
 if inputService.GamepadEnabled then
  for _,state in inputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
   if state.KeyCode==Enum.KeyCode.Thumbstick1 and state.Position.Magnitude>.15 then v+=Vector3.new(state.Position.X,0,-state.Position.Y) end
  end
 end
 return v.Magnitude>1 and v.Unit or v
end
local Air={Speed=32,Acceleration=85,Drag=0.15}
local character,humanoid,root
local joints,saved={},{}
local active=false
local walkSpeed,autoRotate
local blend=0
local function angles(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local function restorePose()
 for joint,value in saved do if joint.Parent then joint.Transform=value end end
 table.clear(saved)
end
function Air.Reset()
 restorePose()
 if active and humanoid and humanoid.Parent then humanoid.WalkSpeed=walkSpeed humanoid.AutoRotate=autoRotate end
 active=false blend=0
end
function Air.Horizontal(velocity,input,dt)
 if input.Magnitude>0.01 then
  local direction=input.Unit
  -- Limit only speed added by steering, never clamp inherited metal momentum.
  return velocity+direction*math.min(Air.Acceleration*dt,math.max(0,Air.Speed-velocity:Dot(direction)))
 end
 return velocity*math.exp(-Air.Drag*dt)
end
function Air.Step(dt)
 local c=player.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or not r or h.Health<=0 then Air.Reset() return end
 if c~=character then
  Air.Reset() character,humanoid,root=c,h,r table.clear(joints)
  for _,j in c:GetDescendants() do if j:IsA("Motor6D") or j:IsA("AnimationConstraint") then joints[j.Name]=j end end
 end
 local state=h:GetState()
 if h.FloorMaterial~=Enum.Material.Air or (state~=Enum.HumanoidStateType.Jumping and state~=Enum.HumanoidStateType.Freefall) then Air.Reset() return end
 if not active then walkSpeed=h.WalkSpeed autoRotate=h.AutoRotate end
 active=true
 local raw=controls:GetMoveVector()
 local cam=workspace.CurrentCamera
 local forward=cam and Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z) or Vector3.new(0,0,-1)
 if forward.Magnitude<0.001 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
 local input=forward*(-raw.Z)+forward:Cross(Vector3.yAxis)*raw.X
 local v=r.AssemblyLinearVelocity
 local flat=Air.Horizontal(Vector3.new(v.X,0,v.Z),input,dt)
 r.AssemblyLinearVelocity=Vector3.new(flat.X,v.Y,flat.Z)
 h.WalkSpeed=flat.Magnitude h.AutoRotate=false
 h:Move(flat.Magnitude>0.01 and flat.Unit or Vector3.zero,false)
 if flat.Magnitude>2 then
  r.CFrame=r.CFrame:Lerp(CFrame.lookAt(r.Position,r.Position+flat.Unit),1-math.exp(-10*dt))
 end
 blend=math.min(1,blend+dt*9)
 local lean=math.min(flat.Magnitude/32,1)
 local pose={Root=angles(-8*lean,0,0),Waist=angles(-6,0,0),Neck=angles(8,0,0),
 RightHip=angles(48,0,8),LeftHip=angles(38,0,-8),RightKnee=angles(-72,0,0),LeftKnee=angles(-62,0,0),
 RightAnkle=angles(15,0,0),LeftAnkle=angles(15,0,0),
 RightShoulder=angles(30,0,65),LeftShoulder=angles(30,0,-65),RightElbow=angles(-65,0,0),LeftElbow=angles(-65,0,0)}
 pose.RootJoint=pose.Root
 pose["Right Hip"]=angles(25,0,8) pose["Left Hip"]=angles(20,0,-8)
 pose["Right Shoulder"]=pose.RightShoulder pose["Left Shoulder"]=pose.LeftShoulder
 for name,target in pose do local j=joints[name] if j then saved[j]=j.Transform j.Transform=j.Transform:Lerp(target,blend) end end
end
RunService.PreAnimation:Connect(restorePose)
RunService:BindToRenderStep("AerialMomentum",Enum.RenderPriority.Input.Value+2,function()
 if active and root and root.Parent then
  local v=root.AssemblyLinearVelocity local flat=Vector3.new(v.X,0,v.Z)
  humanoid.WalkSpeed=flat.Magnitude humanoid:Move(flat.Magnitude>0.01 and flat.Unit or Vector3.zero,false)
 end
end)
player.CharacterRemoving:Connect(Air.Reset)
return Air
