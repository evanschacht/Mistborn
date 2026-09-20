local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Motion={}
local SlidePose=require(script.Parent:WaitForChild("MetalSlidePose"))
function Motion.IsInRange(part,position)
 if not part or not part:IsA("BasePart") or part.Parent~=workspace:FindFirstChild("MetalAnchors") then return false end
 local distance=(part.Position-position).Magnitude
 return distance>0.1 and distance<=Motion.Settings.AnchorRange
end
Motion.SettingSpecs={
 {key="AnchorRange",title="Steel and iron range",min=0,max=500,step=1,default=180,unit=" studs",hint="Reach of blue lines, selection and push/pull, in studs."},
 {key="PullAcceleration",title="Pull acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly E accelerates you."},
 {key="PushAcceleration",title="Push acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly Q accelerates you."},
 {key="PullSpeed",title="Pull top speed",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Maximum powered slide speed; acceleration sets how fast you reach it."},
 {key="PushSpeed",title="Push top speed",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Maximum powered slide speed; acceleration sets how fast you reach it."},
 {key="PullGravity",title="Pull gravity assistance",min=0,max=100,step=1,default=98,unit="%",hint="0 = full gravity; 100 = full weight support."},
 {key="PushGravity",title="Push gravity assistance",min=0,max=100,step=1,default=98,unit="%",hint="With both held, the two settings are averaged."},
 {key="GravityBlend",title="Gravity assistance buildup",min=0.1,max=4,step=0.1,default=1.5,unit=" s",hint="Time for weight support to reach full strength."},
 {key="FallBraking",title="Off-direction momentum braking",min=0,max=12,step=0.25,default=5,unit="",hint="Removes drift sideways to the combined force."},
 {key="HeldDrag",title="Airborne drag",min=0,max=5,step=0.1,default=1.2,unit="",hint="Airborne drift resistance; does not limit powered ground speed."},
 {key="CoastDrag",title="Slide friction",min=0,max=8,step=0.1,default=2.3,unit="",hint="Resistance while coasting after release. 0 = no slide friction."},
 {key="StopSpeed",title="Slide stop cutoff",min=0,max=30,step=0.5,default=5,unit=" studs/s",hint="Released ground slides snap to zero below this speed."},
}
-- Attributes share live values across UI, controller, and Studio inspection contexts.
Motion.Settings=setmetatable({},{
 __index=function(_,key) return script:GetAttribute(key) end,
 __newindex=function(_,key,value) script:SetAttribute(key,value) end,
})
for _,spec in Motion.SettingSpecs do
 if script:GetAttribute(spec.key)==nil then Motion.Settings[spec.key]=spec.default end
end

local function finite(n) return typeof(n)=="number" and n==n and math.abs(n)<math.huge end
function Motion.GetRange(key)
 for _,spec in Motion.SettingSpecs do
  if spec.key==key then return script:GetAttribute(key.."Min") or spec.min,script:GetAttribute(key.."Max") or spec.max end
 end
end
function Motion.SetSetting(key,value)
 for _,spec in Motion.SettingSpecs do
  if spec.key==key and finite(value) then
   local low,high=Motion.GetRange(key)
   value=math.clamp(math.floor(math.clamp(value,low,high)/spec.step+0.5)*spec.step,low,high)
   Motion.Settings[key]=value return value
  end
 end
end
function Motion.SetRange(key,low,high)
 if not finite(low) or not finite(high) or low>=high then return false end
 for _,spec in Motion.SettingSpecs do
  if spec.key==key then
   local floor=key=="GravityBlend" and 0.01 or 0
   local ceiling=(key=="PullGravity" or key=="PushGravity") and 100 or 10000
   if low<floor or high>ceiling then return false end
   script:SetAttribute(key.."Min",low) script:SetAttribute(key.."Max",high)
   Motion.SetSetting(key,Motion.Settings[key])
   return true
  end
 end
 return false
end
function Motion.ResetSettings()
 for _,spec in Motion.SettingSpecs do
  script:SetAttribute(spec.key.."Min",nil) script:SetAttribute(spec.key.."Max",nil)
  Motion.Settings[spec.key]=spec.default
 end
end
-- Constant acceleration until the cap; exponential coasting friction; independent stop cutoff.
function Motion.StepGround(velocity,acceleration,dt,powered,cap,friction,cutoff)
 if powered then
  local nextVelocity=velocity+acceleration*dt
  if nextVelocity.Magnitude>cap then nextVelocity=nextVelocity.Unit*cap end
  return nextVelocity
 end
 local nextVelocity=velocity*math.exp(-friction*dt)
 if nextVelocity.Magnitude<=cutoff then return Vector3.zero end
 return nextVelocity
end

local targets={}
local root,humanoid,attachment,actuator
local moving=false
local active=false
local heldDuration=0
local groundCommand

local previousAutoRotate
local previousWalkSpeed
local slideDirection=Vector3.zero
local function report()
 local effects=workspace:FindFirstChild("MetalAwareness")
 if effects then
  effects:SetAttribute("MotionMode",targets[1] and targets[-1] and "Push + Pull" or targets[1] and "Pull" or targets[-1] and "Push" or (moving and "Coast" or "Idle"))
  effects:SetAttribute("PullAnchor",targets[1] and targets[1].Name or "")
  effects:SetAttribute("PushAnchor",targets[-1] and targets[-1].Name or "")

 end
end
function Motion.Cancel()
 groundCommand=nil
 SlidePose.Clear()
 active=false
 heldDuration=0
 moving=false
 table.clear(targets)
 if actuator then actuator:Destroy() actuator=nil end
 if attachment then attachment:Destroy() attachment=nil end
 if humanoid and humanoid.Parent then
  humanoid.AutoRotate=previousAutoRotate~=false
  if previousWalkSpeed then humanoid.WalkSpeed=previousWalkSpeed end
  humanoid:Move(Vector3.zero)

 end
 report()
end
function Motion.Start(part,directionSign)
 if not part or not part:IsA("BasePart") or part.Parent~=workspace:FindFirstChild("MetalAnchors") then return false end
 local character=player.Character
 local newRoot=character and character:FindFirstChild("HumanoidRootPart")
 local newHumanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not newRoot or not newHumanoid or newHumanoid.Health<=0 then return false end
 if not Motion.IsInRange(part,newRoot.Position) then return false end
 if moving and root~=newRoot then Motion.Cancel() end
 root=newRoot
 humanoid=newHumanoid
 if not moving then
  previousAutoRotate=humanoid.AutoRotate
  previousWalkSpeed=humanoid.WalkSpeed
  attachment=Instance.new("Attachment")
  attachment.Name="MetalMotionAttachment"
  attachment.Parent=root
  actuator=Instance.new("VectorForce")
  actuator.Name="MetalMotionForce"
  actuator.Attachment0=attachment
  actuator.RelativeTo=Enum.ActuatorRelativeTo.World
  actuator.ApplyAtCenterOfMass=true
  actuator.Force=Vector3.zero
  actuator.Parent=root
 end
 if not active then heldDuration=0 end
 targets[directionSign==1 and 1 or -1]=part
 active=true
 moving=true
 local velocity=root.AssemblyLinearVelocity
 local direction=Vector3.new(velocity.X,0,velocity.Z)
 if direction.Magnitude<0.1 then direction=(part.Position-root.Position)*(directionSign==1 and 1 or -1) end
 SlidePose.Step(character,humanoid,root,humanoid.FloorMaterial~=Enum.Material.Air,direction,targets[1],targets[-1])
 -- Keep the normal humanoid controller and gravity active.
 report()
 return true
end
function Motion.Stop(directionSign)
 if not moving then return end
 if directionSign then targets[directionSign]=nil else table.clear(targets) end
 active=next(targets)~=nil
 if not active then heldDuration=0 end

 report()
end
function Motion.Resultant(position,pullPosition,pushPosition)
 local result=Vector3.zero
 if pullPosition then
  local delta=pullPosition-position
  if delta.Magnitude>0.1 then result+=delta.Unit end
 end
 if pushPosition then
  local delta=pushPosition-position
  if delta.Magnitude>0.1 then result-=delta.Unit end
 end
 return result
end
RunService.PreSimulation:Connect(function(dt)
 if not moving then return end
 if not root or not root.Parent or not humanoid or humanoid.Health<=0 then Motion.Cancel() return end
 for directionSign,part in pairs(targets) do
  if not Motion.IsInRange(part,root.Position) then Motion.Stop(directionSign) end
 end
 local current=root.AssemblyLinearVelocity
 local acceleration=Vector3.zero
 local grounded=humanoid.FloorMaterial~=Enum.Material.Air
 local topSpeed=0
 for directionSign,part in pairs(targets) do
  local delta=part.Position-root.Position
  if delta.Magnitude>0.1 then
   local direction=delta.Unit*directionSign
   local along=current:Dot(direction)
   local strength=directionSign==1 and Motion.Settings.PullAcceleration or Motion.Settings.PushAcceleration
   local speed=directionSign==1 and Motion.Settings.PullSpeed or Motion.Settings.PushSpeed
   topSpeed=math.max(topSpeed,speed)
   local thrust=grounded and strength or math.min(strength,math.max(speed-along,0)/math.max(dt,0.001))

   acceleration+=direction*thrust
  end
 end
 -- Sustained metal use gradually supports weight and brakes downward drift.
 -- Releasing the last key removes this assistance immediately.
 if active then
  heldDuration+=dt
  if humanoid.FloorMaterial==Enum.Material.Air then
   local blend=math.clamp(heldDuration/Motion.Settings.GravityBlend,0,1)
   blend=blend*blend*(3-2*blend)
   local assistance,count=0,0
   if targets[1] then assistance+=Motion.Settings.PullGravity count+=1 end
   if targets[-1] then assistance+=Motion.Settings.PushGravity count+=1 end
   local support=workspace.Gravity*(assistance/math.max(count,1))/100

   local resultant=Motion.Resultant(root.Position,targets[1] and targets[1].Position,targets[-1] and targets[-1].Position)
   local drift=current
   if resultant.Magnitude>0.01 then
    local axis=resultant.Unit
    drift=current-axis*current:Dot(axis)
   end
   -- Brake off-axis momentum, never oppose an intentional downward pull.
   acceleration+=Vector3.new(0,support*blend,0)-drift*Motion.Settings.FallBraking*blend

  end
 end
 -- Horizontal drag gives a short slide while released vertical motion falls naturally.

 local horizontal=Vector3.new(current.X,0,current.Z)
 if not grounded then
  if active then
   -- Resist drift perpendicular to propulsion, without lowering its terminal speed.
   local axis=acceleration.Magnitude>0.01 and acceleration.Unit or Vector3.zero
   acceleration-=(current-axis*current:Dot(axis))*Motion.Settings.HeldDrag
  else
   acceleration-=horizontal*Motion.Settings.CoastDrag
  end
 end

 if grounded then
  -- Integrate the commanded speed rather than accumulating Humanoid friction losses.
  -- A substantial collision/deflection resets the command to actual motion.
  if groundCommand and (groundCommand-horizontal).Magnitude>math.max(8,groundCommand.Magnitude*0.5) then groundCommand=nil end
  local startVelocity=active and groundCommand or horizontal
  local groundVelocity=Motion.StepGround(startVelocity or horizontal,Vector3.new(acceleration.X,0,acceleration.Z),dt,active,topSpeed,Motion.Settings.CoastDrag,Motion.Settings.StopSpeed)
  groundCommand=active and groundVelocity or nil
  -- Own only ground horizontal velocity; retain gravity, jumps and collision response.
  root.AssemblyLinearVelocity=Vector3.new(groundVelocity.X,current.Y,groundVelocity.Z)
  acceleration=Vector3.new(0,acceleration.Y,0)
  horizontal=groundVelocity
  humanoid.WalkSpeed=groundVelocity.Magnitude
  slideDirection=groundVelocity.Magnitude>0 and groundVelocity.Unit or Vector3.zero
  humanoid:Move(slideDirection,false)
 else
  -- Do not let default no-input air steering fight the metal-driven momentum.
  groundCommand=nil
  humanoid.WalkSpeed=horizontal.Magnitude
  slideDirection=horizontal.Magnitude>0.1 and horizontal.Unit or Vector3.zero

 end
 actuator.Force=acceleration*root.AssemblyMass
 SlidePose.Step(root.Parent,humanoid,root,humanoid.FloorMaterial~=Enum.Material.Air,slideDirection,targets[1],targets[-1])

 if not active and ((grounded and horizontal.Magnitude<=0.001) or (not grounded and horizontal.Magnitude<1)) then Motion.Cancel() end

end)
RunService:BindToRenderStep("MetalGroundSlide",Enum.RenderPriority.Input.Value+1,function()
 if moving and humanoid and humanoid.Parent then
  humanoid:Move(slideDirection,false)
 end
end)
player.CharacterRemoving:Connect(Motion.Cancel)

return Motion
