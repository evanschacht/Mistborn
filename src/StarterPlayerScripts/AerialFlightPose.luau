-- Presentation only: no forces, root repositioning, or velocity edits.
local Pose={}
local function angles(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
function Pose.Weight(speed,settings)
 return speed>(settings.AirPoseThreshold or 30) and 1 or 0
end
function Pose.Lean(speed,settings)
 local start=settings.AirPoseThreshold or 30
 local finish=math.max(start+0.01,settings.AirPoseFullSpeed or 150)
 local low=math.clamp(settings.AirPoseStartLean or 30,0,80)
 local high=math.clamp(settings.AirPoseMaxLean or 60,low,80)
 return low+(high-low)*math.clamp((speed-start)/(finish-start),0,1)
end
function Pose.Build(speed,settings)
 local lean=Pose.Lean(speed,settings)
 return {
 Root=angles(-lean,0,0),Waist=CFrame.identity,Neck=angles(lean*.5,0,0),
 RightHip=angles(65,0,8),RightKnee=angles(-95,0,0),RightAnkle=angles(10,0,0),
 LeftHip=angles(-10,0,-5),LeftKnee=angles(-8,0,0),LeftAnkle=angles(-12,0,0),
 RightShoulder=angles(-55,0,12),LeftShoulder=angles(-55,0,-12),
 RightElbow=angles(-8,0,0),LeftElbow=angles(-8,0,0),
 RightWrist=CFrame.identity,LeftWrist=CFrame.identity,
 }
end
function Pose.Aim(pose,joints,rootFrame,pull,push,weight)
 local function child(name,frame)
  local j=joints[name]
  return j and frame*j.C0*(pose[name] or CFrame.identity)*j.C1:Inverse() or frame
 end
 local lower=child(joints.Root and "Root" or "RootJoint",rootFrame)
 local upper=child("Waist",lower)
 for _,spec in {{side="Right",target=pull},{side="Left",target=push}} do
  local name=spec.side.."Shoulder"
  local j=joints[name]
  if j and spec.target and spec.target.Parent then
   local frame=upper*j.C0
   local delta=frame:VectorToObjectSpace(spec.target.Position-frame.Position)
   if delta.Magnitude>0.001 then
    local direction=delta.Unit
    local down=-Vector3.yAxis
    local dot=math.clamp(down:Dot(direction),-1,1)
    local axis=down:Cross(direction)
    local aim=axis.Magnitude>0.0001 and CFrame.fromAxisAngle(axis.Unit,math.acos(dot)) or (dot>0 and CFrame.identity or angles(180,0,0))
    pose[name]=pose[name]:Lerp(aim,weight)
    pose[spec.side.."Elbow"]=pose[spec.side.."Elbow"]:Lerp(CFrame.identity,weight)
   end
  end
 end
end
return Pose
