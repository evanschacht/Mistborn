local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Motion={}
Motion.SettingSpecs={
 {key="PullAcceleration",title="Pull acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly E accelerates you."},
 {key="PushAcceleration",title="Push acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly Q accelerates you."},
 {key="PullSpeed",title="Pull speed target",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Pull thrust fades near this speed."},
 {key="PushSpeed",title="Push speed target",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Push thrust fades near this speed."},
 {key="PullGravity",title="Pull gravity assistance",min=0,max=100,step=1,default=98,unit="%",hint="0 = full gravity; 100 = full weight support."},
 {key="PushGravity",title="Push gravity assistance",min=0,max=100,step=1,default=98,unit="%",hint="With both held, the two settings are averaged."},
 {key="GravityBlend",title="Gravity assistance buildup",min=0.1,max=4,step=0.1,default=1.5,unit=" s",hint="Time for weight support to reach full strength."},
 {key="FallBraking",title="Falling momentum braking",min=0,max=12,step=0.25,default=5,unit="",hint="Higher values level out a fall more quickly."},
 {key="HeldDrag",title="Drag while pushing / pulling",min=0,max=5,step=0.1,default=1.2,unit="",hint="Higher values reduce sideways momentum."},
 {key="CoastDrag",title="Slowdown after release",min=0.1,max=8,step=0.1,default=2.3,unit="",hint="Higher values shorten your glide and slide."},
}
-- Attributes share live values across UI, controller, and Studio inspection contexts.
Motion.Settings=setmetatable({},{
 __index=function(_,key) return script:GetAttribute(key) end,
 __newindex=function(_,key,value) script:SetAttribute(key,value) end,
})
for _,spec in Motion.SettingSpecs do
 if script:GetAttribute(spec.key)==nil then Motion.Settings[spec.key]=spec.default end
end

function Motion.SetSetting(key,value)
 for _,spec in Motion.SettingSpecs do
  if spec.key==key and typeof(value)=="number" and value==value then
   value=math.clamp(value,spec.min,spec.max)
   value=math.clamp(math.floor(value/spec.step+0.5)*spec.step,spec.min,spec.max)
   Motion.Settings[key]=value
   return value
  end
 end
end
function Motion.ResetSettings()
 for _,spec in Motion.SettingSpecs do Motion.Settings[spec.key]=spec.default end
end

local targets={}
local root,humanoid,attachment,actuator
local moving=false
local active=false
local heldDuration=0

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
  if part.Parent~=workspace:FindFirstChild("MetalAnchors") then Motion.Stop(directionSign) end
 end
 local current=root.AssemblyLinearVelocity
 local acceleration=Vector3.zero
 for directionSign,part in pairs(targets) do
  local delta=part.Position-root.Position
  if delta.Magnitude>0.1 then
   local direction=delta.Unit*directionSign
   local along=current:Dot(direction)
   local strength=directionSign==1 and Motion.Settings.PullAcceleration or Motion.Settings.PushAcceleration
   local speed=directionSign==1 and Motion.Settings.PullSpeed or Motion.Settings.PushSpeed
   local thrust=strength*math.clamp(1-math.max(along,0)/speed,0,1)

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

   local fallBraking=-math.min(current.Y,0)*Motion.Settings.FallBraking
   acceleration+=Vector3.new(0,(support+fallBraking)*blend,0)
  end
 end
 -- Horizontal drag gives a short slide while released vertical motion falls naturally.

 local horizontal=Vector3.new(current.X,0,current.Z)
 acceleration-=horizontal*(active and Motion.Settings.HeldDrag or Motion.Settings.CoastDrag)
 if humanoid.FloorMaterial~=Enum.Material.Air then
  -- Let the walking controller follow the slide instead of braking against it.
  local groundVelocity=horizontal+Vector3.new(acceleration.X,0,acceleration.Z)*math.min(dt,0.1)
  humanoid.WalkSpeed=groundVelocity.Magnitude
  slideDirection=groundVelocity.Magnitude>0.1 and groundVelocity.Unit or Vector3.zero
 else
  humanoid.WalkSpeed=previousWalkSpeed
  slideDirection=Vector3.zero
 end
 actuator.Force=acceleration*root.AssemblyMass

 if not active and horizontal.Magnitude<1 then Motion.Cancel() end

end)
RunService:BindToRenderStep("MetalGroundSlide",Enum.RenderPriority.Input.Value+1,function()
 if moving and humanoid and humanoid.Parent and humanoid.FloorMaterial~=Enum.Material.Air then
  humanoid:Move(slideDirection,false)
 end
end)
player.CharacterRemoving:Connect(Motion.Cancel)

return Motion
