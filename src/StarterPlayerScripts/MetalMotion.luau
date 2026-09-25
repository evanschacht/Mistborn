local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Motion={}
local SlideControl=require(script.Parent:WaitForChild("MetalSlideControl"))
local Air=require(script.Parent:WaitForChild("AerialMovement"))
local SlidePose=require(script.Parent:WaitForChild("MetalSlidePose"))
function Motion.IsInRange(part,position)
 if not part or not part:IsA("BasePart") or part.Parent~=workspace:FindFirstChild("MetalAnchors") then return false end
 local distance=(part.Position-position).Magnitude
 return distance>0.1 and distance<Motion.Settings.AnchorRange
end
local Config=require(game:GetService("ReplicatedStorage"):WaitForChild("MetalTuningConfig"))
local ForceGeometry=require(game:GetService("ReplicatedStorage"):WaitForChild("MetalForceGeometry"))
Motion.SettingSpecs=Config.Specs
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
   local floor=(key=="ForceNearClamp" or key=="ForceFarClamp") and 0.1 or 0
   local ceiling=10000
   if low<floor or high>ceiling then return false end
   script:SetAttribute(key.."Min",low) script:SetAttribute(key.."Max",high)
   Motion.SetSetting(key,Motion.Settings[key])
   return true
  end
 end
 return false
end
function Motion.ResetSetting(key)
 for _,spec in Motion.SettingSpecs do
  if spec.key==key then
   script:SetAttribute(key.."Min",nil) script:SetAttribute(key.."Max",nil)
   Motion.Settings[key]=spec.default
   return
  end
 end
end
function Motion.ResetSettings()
 for _,spec in Motion.SettingSpecs do Motion.ResetSetting(spec.key) end
end
function Motion.ApplySettings(data)
 local clean=Config.Validate(data)
 if not clean then return false end
 for _,spec in Motion.SettingSpecs do
  local key=spec.key
  script:SetAttribute(key.."Min",clean.ranges[key][1])
  script:SetAttribute(key.."Max",clean.ranges[key][2])
  Motion.Settings[key]=clean.values[key]
 end
 script:SetAttribute("ShowSpeedometer",clean.showSpeedometer)
 return true
end
function Motion.Snapshot(showSpeedometer)
 local data={values={},ranges={},showSpeedometer=showSpeedometer==true}
 for _,spec in Motion.SettingSpecs do
  data.values[spec.key]=Motion.Settings[spec.key]
  local low,high=Motion.GetRange(spec.key)
  data.ranges[spec.key]={low,high}
 end
 return data
end
Motion.ApplySettings(require(game:GetService("ReplicatedStorage"):WaitForChild("MetalTuningPreset")))
-- Constant acceleration until the cap; exponential coasting friction; independent stop cutoff.
function Motion.StepGround(velocity,acceleration,dt,powered,cap,friction,cutoff)
 if powered then
  local nextVelocity=velocity+acceleration*dt
  local limit=math.max(cap,velocity.Magnitude)
  if nextVelocity.Magnitude>limit then nextVelocity=nextVelocity.Unit*limit end
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

 moving=false
 table.clear(targets)
 if actuator then actuator:Destroy() actuator=nil end
 if attachment then attachment:Destroy() attachment=nil end
 if humanoid and humanoid.Parent then
  humanoid.AutoRotate=true
  humanoid.WalkSpeed=Motion.Settings.GroundSpeed
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
 Air.Step(dt,Motion.Settings,moving)
 if not moving then return end
 if not root or not root.Parent or not humanoid or humanoid.Health<=0 then Motion.Cancel() return end
 for directionSign,part in pairs(targets) do
  if not Motion.IsInRange(part,root.Position) then Motion.Stop(directionSign) end
 end
 local current=root.AssemblyLinearVelocity
 local acceleration=Vector3.zero
 local grounded=humanoid.FloorMaterial~=Enum.Material.Air
 local slideInput=grounded and SlideControl.Read() or Vector2.zero
 local topSpeed=0
 for directionSign,part in pairs(targets) do
  local delta=part.Position-root.Position
  if delta.Magnitude>0.1 then
   local direction=ForceGeometry.Direction(part.CFrame,part.Size,root.CFrame,root.Size,directionSign)
   local along=current:Dot(direction)
   local strength=directionSign==1 and Motion.Settings.PullAcceleration or Motion.Settings.PushAcceleration
   strength*=Config.ForceScale(delta.Magnitude,Motion.Settings,directionSign)
   local speed=directionSign==1 and Motion.Settings.PullSpeed or Motion.Settings.PushSpeed
   topSpeed=math.max(topSpeed,speed)
   local thrust=grounded and strength or math.min(strength,math.max(speed-along,0)/math.max(dt,0.001))

   acceleration+=direction*thrust
  end
 end
 -- Release the Humanoid's floor constraint when actual upward thrust beats
 -- gravity. Freefall adds no jump impulse; VectorForce performs the lift.
 if grounded and acceleration.Y>workspace.Gravity then
  humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
  grounded=false
 end
 -- Roblox applies gravity continuously. Metal thrust contains only the current
 -- anchor direction; no weight support or vertical/off-axis velocity damping.
 local horizontal=Vector3.new(current.X,0,current.Z)
 -- Air drag is separate from ground slide friction.
 if grounded then
  -- Integrate the commanded speed rather than accumulating Humanoid friction losses.
  -- A substantial collision/deflection resets the command to actual motion.
  if groundCommand and (groundCommand-horizontal).Magnitude>math.max(8,groundCommand.Magnitude*0.5) then groundCommand=nil end
  local startVelocity=(active or slideInput.Y<0) and groundCommand or horizontal
  local groundVelocity=Motion.StepGround(startVelocity or horizontal,Vector3.new(acceleration.X,0,acceleration.Z),dt,active,topSpeed,slideInput.Y~=0 and 0 or Motion.Settings.CoastDrag,slideInput.Y~=0 and 0 or Motion.Settings.StopSpeed)
  if slideInput.Y<0 then
   -- Braking wins over additional ground thrust, without reversing momentum.
   local speed=math.min(groundVelocity.Magnitude,(startVelocity or horizontal).Magnitude)
   groundVelocity=groundVelocity.Magnitude>0.001 and groundVelocity.Unit*speed or Vector3.zero
  end
  groundVelocity=SlideControl.Step(groundVelocity,slideInput,Motion.Settings,dt)
  groundCommand=(active or slideInput.Y<0) and groundVelocity or nil
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
 SlidePose.Step(root.Parent,humanoid,root,grounded,slideDirection,targets[1],targets[-1],slideInput,dt)

 if not active and ((grounded and horizontal.Magnitude<=0.001) or (not grounded and horizontal.Magnitude<1)) then Motion.Cancel() end

end)
RunService:BindToRenderStep("MetalGroundSlide",Enum.RenderPriority.Input.Value+1,function()
 if moving and humanoid and humanoid.Parent and humanoid.FloorMaterial~=Enum.Material.Air then
  humanoid:Move(slideDirection,false)
 end
end)
player.CharacterRemoving:Connect(Motion.Cancel)

return Motion
