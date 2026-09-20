local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Config=require(ReplicatedStorage:WaitForChild("AllomancyConfig"))
local remote=ReplicatedStorage:WaitForChild("AllomancyBoost")
local Motion={}
Motion.SettingSpecs={
 {key="PullAcceleration",title="Pull acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="Strength of E's force toward its locked anchor."},
 {key="PushAcceleration",title="Push acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="Strength of Q's force away from its locked anchor."},
 {key="PullSpeed",title="Pull speed target",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Pull thrust fades near this speed."},
 {key="PushSpeed",title="Push speed target",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Push thrust fades near this speed."},
 {key="EffectiveGravityMultiplier",title="Aerial gravity",min=0.3,max=1,step=0.05,default=Config.EffectiveGravityMultiplier,unit="×",hint="0.8 = 80% of normal gravity. No apex hover."},
 {key="AirAcceleration",title="Air steering acceleration",min=0,max=60,step=1,default=Config.AirAcceleration,unit="",hint="Gentle WASD acceleration, relative to the camera."},
 {key="AirTurnStrength",title="Air turning strength",min=0,max=1,step=0.05,default=Config.AirTurnStrength,unit="",hint="Higher retains more steering at high speed."},
 {key="MaximumHorizontalSpeed",title="Air steering speed ceiling",min=40,max=300,step=5,default=Config.MaximumHorizontalSpeed,unit=" studs/s",hint="Limits added steering, never erases momentum."},
 {key="CharacterTiltAmount",title="Aerial lean",min=0,max=18,step=1,default=Config.CharacterTiltAmount,unit="°",hint="Visual tilt only; physics and camera stay upright."},
 {key="CoastDrag",title="Ground slide slowdown",min=0.1,max=8,step=0.1,default=Config.GroundCoastDrag,unit="",hint="Only affects ground sliding, not aerial momentum."},
}
Motion.Settings=setmetatable({},{
 __index=function(_,key) local v=script:GetAttribute(key) if v==nil then return Config[key] end return v end,
 __newindex=function(_,key,value) script:SetAttribute(key,value) end,
})
for _,spec in Motion.SettingSpecs do if script:GetAttribute(spec.key)==nil then Motion.Settings[spec.key]=spec.default end end
function Motion.SetSetting(key,value)
 for _,spec in Motion.SettingSpecs do
  if spec.key==key and typeof(value)=="number" and value==value then
   value=math.clamp(math.floor(math.clamp(value,spec.min,spec.max)/spec.step+0.5)*spec.step,spec.min,spec.max)
   Motion.Settings[key]=value return value
  end
 end
end
function Motion.ResetSettings() for _,spec in Motion.SettingSpecs do Motion.Settings[spec.key]=spec.default end end
local targets,keys,taps={},{},{}
local root,humanoid,attachment,force,joint,baseTransform
local oldWalkSpeed,slideDirection=16,Vector3.zero
local engaged,aerial,usedBoost,pending=false,false,false,false
local support,tilt,lastBoost=0,CFrame.identity,-math.huge
local connections={}
local function report()
 local f=workspace:FindFirstChild("MetalAwareness")
 if f then
  f:SetAttribute("MotionMode",targets[1] and targets[-1] and "Push + Pull" or targets[1] and "Pull" or targets[-1] and "Push" or aerial and "Ballistic" or engaged and "Slide" or "Idle")
  f:SetAttribute("PullAnchor",targets[1] and targets[1].Name or "")
  f:SetAttribute("PushAnchor",targets[-1] and targets[-1].Name or "")
  f:SetAttribute("BoostUsed",usedBoost)
 end
end
local function removeForce()
 if force then force:Destroy() force=nil end
 if attachment then attachment:Destroy() attachment=nil end
end
local function ensureForce()
 if force then return end
 attachment=Instance.new("Attachment") attachment.Name="MetalMotionAttachment" attachment.Parent=root
 force=Instance.new("VectorForce") force.Name="MetalMotionForce" force.Attachment0=attachment
 force.RelativeTo=Enum.ActuatorRelativeTo.World force.ApplyAtCenterOfMass=true force.Parent=root
end
function Motion.Cancel()
 table.clear(targets) table.clear(keys) table.clear(taps)
 engaged=false aerial=false usedBoost=false pending=false support=0
 removeForce()
 if humanoid and humanoid.Parent then humanoid.WalkSpeed=oldWalkSpeed humanoid:Move(Vector3.zero) end
 if joint and joint.Parent and baseTransform then joint.Transform=baseTransform end
 tilt=CFrame.identity
 report()
end
local function findJoint(character)
 for _,obj in character:GetDescendants() do
  if (obj:IsA("Motor6D") or obj:IsA("AnimationConstraint")) and (obj.Name=="Root" or obj.Name=="RootJoint") then joint=obj baseTransform=obj.Transform return end
 end
end
local function bind(character)
 Motion.Cancel()
 root=character:WaitForChild("HumanoidRootPart")
 humanoid=character:WaitForChild("Humanoid")
 oldWalkSpeed=humanoid.WalkSpeed
 joint=nil baseTransform=nil
 findJoint(character)
end
function Motion.Start(part,sign)
 if not root or not root.Parent or not humanoid or humanoid.Health<=0 then return false end
 if not part or not part:IsA("BasePart") or part.Parent~=workspace:FindFirstChild("MetalAnchors") then return false end
 targets[sign==1 and 1 or -1]=part engaged=true
 ensureForce() report() return true
end
function Motion.Stop(sign)
 if sign then targets[sign]=nil else table.clear(targets) end
 -- Deliberately do not change velocity, gravity phase, or airborne momentum.
 report()
end
function Motion.Resultant(position,pull,push)
 local result=Vector3.zero
 if pull and (pull-position).Magnitude>0.1 then result+=(pull-position).Unit end
 if push and (push-position).Magnitude>0.1 then result-=(push-position).Unit end
 return result
end
function Motion.CameraDirection(key,frame)
 local look=Vector3.new(frame.LookVector.X,0,frame.LookVector.Z)
 if look.Magnitude<0.01 then
  local right=Vector3.new(frame.RightVector.X,0,frame.RightVector.Z).Unit
  look=Vector3.yAxis:Cross(right)
 else look=look.Unit end
 local right=look:Cross(Vector3.yAxis)
 return key==Enum.KeyCode.W and look or key==Enum.KeyCode.S and -look or key==Enum.KeyCode.A and -right or key==Enum.KeyCode.D and right or Vector3.zero
end
function Motion.SteeringAcceleration(horizontal,input)
 if input.Magnitude<0.01 then return Vector3.zero end
 local speed=horizontal.Magnitude
 local factor=1/(1+speed/math.max(Motion.Settings.MaximumHorizontalSpeed,1))
 local acceleration=input.Unit*Motion.Settings.AirAcceleration*(factor+(1-factor)*Motion.Settings.AirTurnStrength)
 if speed>=Motion.Settings.MaximumHorizontalSpeed then
  local forward=horizontal.Unit
  acceleration-=forward*math.max(acceleration:Dot(forward),0)
 end
 return acceleration
end
function Motion.RequestBoost(key)
 if not root or not humanoid or humanoid.Health<=0 or humanoid.FloorMaterial~=Enum.Material.Air then return false end
 if pending or os.clock()-lastBoost<Config.AirBoostCooldown or (Config.OneBoostPerAirtime and usedBoost) then return false end
 local camera=workspace.CurrentCamera if not camera then return false end
 pending=true
 remote:FireServer(key.Name,Motion.CameraDirection(Enum.KeyCode.W,camera.CFrame))
 return true
end
function Motion.InputBegan(key,processed)
 if processed then return end
 if key~=Enum.KeyCode.W and key~=Enum.KeyCode.A and key~=Enum.KeyCode.S and key~=Enum.KeyCode.D then return end
 if keys[key] then return end
 keys[key]=true
 local now=os.clock()
 if taps[key] and now-taps[key]<=Config.DoubleTapWindow then Motion.RequestBoost(key) taps[key]=nil else taps[key]=now end
end
function Motion.InputEnded(key) keys[key]=nil end
function Motion.ReleaseInput() table.clear(keys) table.clear(taps) Motion.Stop() end
table.insert(connections,remote.OnClientEvent:Connect(function(accepted,delta)
 pending=false
 if not accepted or not root or not humanoid or humanoid.Health<=0 or humanoid.FloorMaterial~=Enum.Material.Air then return end
 -- One impulse adds to existing velocity. It never holds or overwrites velocity.
 root:ApplyImpulse(delta*root.AssemblyMass)
 local velocity=root.AssemblyLinearVelocity
 local horizontal=Vector3.new(velocity.X,0,velocity.Z)
 humanoid.WalkSpeed=horizontal.Magnitude
 slideDirection=horizontal.Magnitude>0.1 and horizontal.Unit or Vector3.zero
 humanoid:Move(slideDirection,false)
 lastBoost=os.clock() usedBoost=true engaged=true aerial=true ensureForce() report()
end))
local function updatePresentation(dt)
 if not root or not root.Parent or not humanoid then return end
 if not joint and player.Character then findJoint(player.Character) end
 local desired=CFrame.identity
 if aerial and joint then
  local velocity=root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
  local maxTilt=math.rad(Motion.Settings.CharacterTiltAmount)
  desired=CFrame.Angles(math.clamp(-velocity.Z/100,-1,1)*-maxTilt,0,math.clamp(velocity.X/100,-1,1)*-maxTilt)
 end
 tilt=tilt:Lerp(desired,1-math.exp(-Config.CharacterTiltResponsiveness*dt))
 if joint and joint.Parent then
  baseTransform=joint.Transform
  joint.Transform=baseTransform*tilt
 end
end
-- Remove our previous visual offset before Animator evaluates the next pose.
table.insert(connections,RunService.PreAnimation:Connect(function()
 if joint and joint.Parent and baseTransform then joint.Transform=baseTransform end
end))
table.insert(connections,RunService.PreSimulation:Connect(function(dt)
 updatePresentation(dt)
 if not root or not root.Parent or not humanoid or humanoid.Health<=0 then
  if engaged then Motion.Cancel() end return
 end
 local grounded=humanoid.FloorMaterial~=Enum.Material.Air
 if grounded and aerial then aerial=false usedBoost=false pending=false report() end
 if grounded then usedBoost=false end
 local active=next(targets)~=nil
 if active then engaged=true end
 if not grounded and engaged then aerial=true end
 if not engaged then return end
 ensureForce()
 local velocity=root.AssemblyLinearVelocity
 local horizontal=Vector3.new(velocity.X,0,velocity.Z)
 local acceleration=Vector3.zero
 for sign,part in pairs(targets) do
  if part.Parent~=workspace:FindFirstChild("MetalAnchors") then targets[sign]=nil report()
  else
   local delta=part.Position-root.Position
   if delta.Magnitude>0.1 then
    local direction=delta.Unit*sign
    local strength=sign==1 and Motion.Settings.PullAcceleration or Motion.Settings.PushAcceleration
    local limit=sign==1 and Motion.Settings.PullSpeed or Motion.Settings.PushSpeed
    acceleration+=direction*strength*math.clamp(1-math.max(velocity:Dot(direction),0)/limit,0,1)
   end
  end
 end
 active=next(targets)~=nil
 local desiredSupport=aerial and (1-Motion.Settings.EffectiveGravityMultiplier) or 0
 support+=(desiredSupport-support)*(1-math.exp(-dt/Config.GravityTransitionTime))
 if not grounded then
  acceleration+=Vector3.yAxis*workspace.Gravity*support
  local input=Vector3.zero
  local camera=workspace.CurrentCamera
  if camera then for key in pairs(keys) do input+=Motion.CameraDirection(key,camera.CFrame) end end
  acceleration+=Motion.SteeringAcceleration(horizontal,input)
  -- Keep the controller's own air steering from braking our existing velocity.
  local nextHorizontal=horizontal+Vector3.new(acceleration.X,0,acceleration.Z)*math.min(dt,0.1)
  humanoid.WalkSpeed=nextHorizontal.Magnitude
  slideDirection=nextHorizontal.Magnitude>0.1 and nextHorizontal.Unit or Vector3.zero
  local state=humanoid:GetState()
  if state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.RunningNoPhysics then
   humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
  end
 else
  if not active then acceleration-=horizontal*Motion.Settings.CoastDrag end
  local groundVelocity=horizontal+Vector3.new(acceleration.X,0,acceleration.Z)*math.min(dt,0.1)
  humanoid.WalkSpeed=groundVelocity.Magnitude
  slideDirection=groundVelocity.Magnitude>0.1 and groundVelocity.Unit or Vector3.zero
 end
 humanoid:Move(slideDirection,false)
 force.Force=acceleration*root.AssemblyMass
 if grounded and not active and horizontal.Magnitude<1 and support<0.005 then
  engaged=false removeForce() humanoid.WalkSpeed=oldWalkSpeed humanoid:Move(Vector3.zero) report()
 end
end))
RunService:BindToRenderStep("MetalAerialPresentation",Enum.RenderPriority.Input.Value+1,function(dt)
 if engaged and humanoid then humanoid:Move(slideDirection,false) end
end)
table.insert(connections,player.CharacterAdded:Connect(bind))
table.insert(connections,player.CharacterRemoving:Connect(function() Motion.Cancel() root=nil humanoid=nil joint=nil end))
function Motion.Destroy()
 Motion.Cancel()
 RunService:UnbindFromRenderStep("MetalAerialPresentation")
 for _,c in connections do c:Disconnect() end
 table.clear(connections)
end
table.insert(connections,script.Destroying:Connect(Motion.Destroy))
if player.Character then task.spawn(bind,player.Character) end
return Motion
