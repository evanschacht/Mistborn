-- Ground-slide presentation only. Movement strength, drag and velocity stay in MetalMotion.
local RunService=game:GetService("RunService")
local Pose={}
local character,humanoid,root
local joints,saved={},{}
local wasSliding=false
local lean=Vector2.zero
local autoRotate=true
local function angles(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local function restore()
 for joint,transform in pairs(saved) do if joint.Parent then joint.Transform=transform end end
 table.clear(saved)
end
function Pose.Clear()
 restore()
 if wasSliding and humanoid and humanoid.Parent then humanoid.AutoRotate=autoRotate end
 wasSliding=false
 if character then character:SetAttribute("MetalSliding",false) end
end
local function bind(c,h,r)
 Pose.Clear()
 character,humanoid,root=c,h,r
 table.clear(joints)
 for _,obj in c:GetDescendants() do
  if obj:IsA("Motor6D") or obj:IsA("AnimationConstraint") then joints[obj.Name]=obj end
 end
end
local function aim(frame,target)
 local direction=frame:VectorToObjectSpace(target-frame.Position).Unit
 local down=-Vector3.yAxis
 local dot=math.clamp(down:Dot(direction),-1,1)
 local axis=down:Cross(direction)
 if axis.Magnitude<0.0001 then return dot>0 and CFrame.identity or angles(180,0,0) end
 return CFrame.fromAxisAngle(axis.Unit,math.acos(dot))
end
function Pose.Step(c,h,r,sliding,direction,pull,push,input,dt)
 if character~=c then bind(c,h,r) end
 if not sliding then Pose.Clear() return end
 if not wasSliding then autoRotate=h.AutoRotate end
 wasSliding=true
 c:SetAttribute("MetalSliding",true)
 h.AutoRotate=true
 lean=lean:Lerp(input or Vector2.zero,1-math.exp(-10*(dt or 1/60)))
 c:SetAttribute("SlideForwardLean",lean.Y) c:SetAttribute("SlideSideLean",lean.X)
 -- Lower the visible rig, not the physics root or Humanoid hip height.
 local scale=h.HipHeight/2
 local pose={
  Root=CFrame.new(0,-1.3*scale,0)*angles(-8+12*lean.Y,0,22-14*lean.X),
  Waist=angles(-10+14*lean.Y,-12,10-8*lean.X),
  Neck=angles(12-10*lean.Y,12,-22+12*lean.X),
  RightHip=angles(82,-8,5), RightKnee=angles(-8,0,0), RightAnkle=angles(-12,0,0),
  LeftHip=angles(65,20,-25), LeftKnee=angles(-132,0,0), LeftAnkle=angles(32,0,0),
  LeftShoulder=angles(-12,0,-35), LeftElbow=angles(-12,0,0), LeftWrist=angles(0,0,-20),
  RightShoulder=angles(35,0,30), RightElbow=angles(-55,0,0), RightWrist=CFrame.identity,
 }
 pose.RootJoint=pose.Root
 local function childFrame(name,parentFrame)
  local j=joints[name]
  if not j then return parentFrame end
  return parentFrame*j.C0*(pose[name] or CFrame.identity)*j.C1:Inverse()
 end
 local lower=childFrame(joints.Root and "Root" or "RootJoint",r.CFrame)
 local upper=childFrame("Waist",lower)
 for _,spec in {{side="Right",target=pull},{side="Left",target=push}} do
  local shoulder=joints[spec.side.."Shoulder"]
  if shoulder and spec.target and spec.target.Parent then
   pose[spec.side.."Shoulder"]=aim(upper*shoulder.C0,spec.target.Position)
   pose[spec.side.."Elbow"]=CFrame.identity
   pose[spec.side.."Wrist"]=CFrame.identity
  end
 end
 for name,transform in pairs(pose) do
  local j=joints[name]
  if j and j.Parent then
   saved[j]=saved[j] or j.Transform
   j.Transform=transform
  end
 end
end
-- Remove the prior pose before Animator evaluates, so running/falling resumes cleanly.
local beforeAnimation=RunService.PreAnimation:Connect(restore)
function Pose.Destroy()
 Pose.Clear()
 beforeAnimation:Disconnect()
 table.clear(joints)
 character=nil humanoid=nil root=nil
end
script.Destroying:Connect(Pose.Destroy)
return Pose
