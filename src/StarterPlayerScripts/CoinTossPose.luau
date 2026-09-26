-- Last presentation layer: only the right arm; never changes metal forces.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Rules=require(game.ReplicatedStorage:WaitForChild("CoinRules"))
local Pose={}
local saved={}
local function restore()
 for joint,t in saved do if joint.Parent then joint.Transform=t end end
 table.clear(saved)
end
RunService.PreAnimation:Connect(restore)
local function aim(frame,target)
 local delta=frame:VectorToObjectSpace(target-frame.Position)
 if delta.Magnitude<.001 then return CFrame.identity end
 local dir=delta.Unit local down=-Vector3.yAxis
 local axis=down:Cross(dir) local dot=math.clamp(down:Dot(dir),-1,1)
 return axis.Magnitude>.001 and CFrame.fromAxisAngle(axis.Unit,math.acos(dot)) or (dot>0 and CFrame.identity or CFrame.Angles(math.pi,0,0))
end
local function smooth(a) a=math.clamp(a,0,1) return a*a*(3-2*a) end
function Pose.Step()
 local now=workspace:GetServerTimeNow()
 for _,player in Players:GetPlayers() do
  local c=player.Character local start=c and c:GetAttribute("CoinActionStart")
  local t=start and now-start
  if t and t>=0 and t<Rules.Duration then
   -- Play the original pose sequence twice as fast, matching the release timer.
   t=t*1.1/Rules.Duration
   local root=c:FindFirstChild("HumanoidRootPart") local lower=c:FindFirstChild("LowerTorso")
   local upper=c:FindFirstChild("UpperTorso")
   if not root or not lower or not upper then continue end
   local joints={} for _,v in c:GetDescendants() do if v:IsA("Motor6D") or v:IsA("AnimationConstraint") then joints[v.Name]=v end end
   local shoulder,elbow,wrist=joints.RightShoulder,joints.RightElbow,joints.RightWrist
   if not shoulder or not elbow or not wrist then continue end
   local function child(name,cf)
    local j=joints[name] return j and cf*j.C0*j.Transform*j.C1:Inverse() or cf
   end
   local lowerFrame=child("Root",root.CFrame)
   local upperFrame=child("Waist",lowerFrame)
   local opening=lower:FindFirstChild("PouchOpening")
   if not opening then continue end
   local pouch=(lowerFrame*opening.CFrame).Position
   local lift=(upperFrame*CFrame.new(.65,.15,-.8)).Position
   local flick=(upperFrame*CFrame.new(.5,-.1,-1.5)).Position
   local target=pouch
   if t>.28 and t<.53 then target=pouch:Lerp(lift,smooth((t-.28)/(.53-.28)))
   elseif t>=.53 then target=lift:Lerp(flick,smooth((t-.53)/.15)) end
   local frame=upperFrame*shoulder.C0
   local delta=target-frame.Position local d=delta.Magnitude
   local l1=math.max(.1,(shoulder.C1:Inverse()*elbow.C0).Position.Magnitude)
   local l2=math.max(.1,(elbow.C1:Inverse()*wrist.C0).Position.Magnitude+.25)
   local distance=math.clamp(d,.05,l1+l2-.01)
   local dir=d>.001 and delta.Unit or -Vector3.yAxis
   local bend=upperFrame.LookVector-dir*upperFrame.LookVector:Dot(dir)
   if bend.Magnitude<.01 then bend=upperFrame.RightVector end
   local angle=math.acos(math.clamp((l1*l1+distance*distance-l2*l2)/(2*l1*distance),-1,1))
   local elbowPoint=frame.Position+(dir*math.cos(angle)+bend.Unit*math.sin(angle))*l1
   local shoulderPose=aim(frame,elbowPoint)
   local elbowFrame=frame*shoulderPose*shoulder.C1:Inverse()*elbow.C0
   local elbowPose=aim(elbowFrame,target)
   local weight=math.min(smooth(t/.16),smooth((1.1-t)/.22))
   for _,item in {{shoulder,shoulderPose},{elbow,elbowPose},{wrist,CFrame.Angles(math.rad(t>.53 and -35 or 5),0,0)}} do
    local j=item[1] saved[j]=j.Transform j.Transform=j.Transform:Lerp(item[2],weight)
   end
  end
 end
end
return Pose
