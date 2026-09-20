local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local player=Players.LocalPlayer
local anchors=workspace:WaitForChild("MetalAnchors")
local NEAR_PIXELS = 72
local effects=Instance.new("Folder")
effects.Name="MetalAwareness"
effects.Parent=workspace
local highlight=Instance.new("Highlight")
highlight.Name="SelectedAnchor"
highlight.FillColor=Color3.fromRGB(65,175,255)
highlight.FillTransparency=0.55
highlight.OutlineColor=Color3.fromRGB(165,240,255)
highlight.OutlineTransparency=0
highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled=false
highlight.Parent=effects
local entries={}
local selected
local root
local hovered
local Motion=require(script.Parent:WaitForChild("MetalMotion"))
local heldKeys={}
local function selectAnchor(part)
 if selected==part then return end
 selected=part
 highlight.Adornee=part
 highlight.Enabled=part~=nil
 effects:SetAttribute("SelectedAnchor",part and part.Name or "")
end
-- Six soft radial ribbons create a round energy volume instead of a camera-facing strip.
local RADIAL_LAYERS=6
local function addAnchor(part)
 if not part:IsA("BasePart") or entries[part] then return end
 local entry={layers={}}
 for i=1,RADIAL_LAYERS do
  local origin=Instance.new("Attachment")
  origin.Name="EnergyOrigin_"..part.Name.."_"..i
  local endpoint=Instance.new("Attachment")
  endpoint.Name="EnergyEndpoint_"..i
  endpoint.Parent=part
  local line=Instance.new("Beam")
  line.Name="LineTo_"..part.Name.."_"..i
  line.Attachment0=origin
  line.Attachment1=endpoint
  line.FaceCamera=false
  line.Segments=1
  line.LightEmission=0.55
  line.LightInfluence=0
  line.Texture="rbxasset://textures/particles/smoke_main.dds"
  line.TextureMode=Enum.TextureMode.Stretch
  line.TextureLength=0.5
  line:SetTextureOffset(0.25)
  line.TextureSpeed=0
  line.Transparency=NumberSequence.new(0.2)
  line.Enabled=false
  line.Parent=effects
  table.insert(entry.layers,{line=line,origin=origin,endpoint=endpoint,angle=(i-1)*math.pi/RADIAL_LAYERS})
 end
 entries[part]=entry
end
for _,part in anchors:GetChildren() do addAnchor(part) end
anchors.ChildAdded:Connect(addAnchor)
anchors.ChildRemoved:Connect(function(part)
 local entry=entries[part]
 if entry then
  for _,layer in entry.layers do
   layer.line:Destroy()
   layer.origin:Destroy()
   layer.endpoint:Destroy()
  end
  entries[part]=nil
 end
 if selected==part then selectAnchor(nil) end
end)
local function bindCharacter(character)
 local newRoot=character:WaitForChild("HumanoidRootPart")
 if player.Character==character then
  root=newRoot
  for _,entry in pairs(entries) do
   for _,layer in entry.layers do
    layer.origin:Destroy()
    layer.origin=Instance.new("Attachment")
    layer.origin.Name="EnergyOrigin"
    layer.origin.Parent=root
    layer.line.Attachment0=layer.origin
   end
  end
 end
end
player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function()
 root=nil
 for _,entry in pairs(entries) do
  for _,layer in entry.layers do
   layer.line.Enabled=false
   layer.origin.Parent=nil
  end
 end
end)
if player.Character then task.spawn(bindCharacter,player.Character) end
RunService.RenderStepped:Connect(function()
 if not root or not root.Parent then return end
 for part,entry in pairs(entries) do
  local delta=part.Position-root.Position
  local enabled=delta.Magnitude>0.1
  if enabled then
   local direction=delta.Unit
   local reference=math.abs(direction.Y)>0.98 and Vector3.xAxis or Vector3.yAxis
   local radial=direction:Cross(reference).Unit
   local other=direction:Cross(radial).Unit
   local size=(part.Size.X*part.Size.Y*part.Size.Z)^(1/3)
   local width=math.clamp(0.4864*(size/6)^0.65,0.256,1.2288)
   local active=part==selected
   if active then width*=1.4 end
   local color=ColorSequence.new(active and Color3.fromRGB(130,230,255) or Color3.fromRGB(40,155,255))
   for _,layer in entry.layers do
    if layer.origin.Parent~=root then layer.origin.Parent=root end
    local up=radial*math.cos(layer.angle)+other*math.sin(layer.angle)
    local frame=CFrame.fromMatrix(root.Position,direction,up,direction:Cross(up))
    layer.origin.CFrame=root.CFrame:ToObjectSpace(frame)
    layer.endpoint.CFrame=part.CFrame:ToObjectSpace(frame+delta)
    layer.line.Width0=width
    layer.line.Width1=width
    layer.line.Color=color
   end
  end
  for _,layer in entry.layers do layer.line.Enabled=enabled end
 end
 local camera=workspace.CurrentCamera
 if not camera then return end
 if UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then hovered=nil return end
 local mouse=UserInputService:GetMouseLocation()
 local tuning=player.PlayerGui:FindFirstChild("MetalTuning")
 local panel=tuning and tuning:FindFirstChild("Panel")
 if panel and panel.Visible then
  local p,size=panel.AbsolutePosition,panel.AbsoluteSize
  if mouse.X>=p.X and mouse.X<=p.X+size.X and mouse.Y>=p.Y and mouse.Y<=p.Y+size.Y then
   hovered=nil
   effects:SetAttribute("HoveredAnchor","")
   return
  end
 end

 local best,bestScore
 for part in pairs(entries) do
  local center,onScreen=camera:WorldToViewportPoint(part.Position)
  if onScreen and center.Z>0 then
   local low=Vector2.new(math.huge,math.huge)
   local high=Vector2.new(-math.huge,-math.huge)
   local allInFront=true
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local corner=camera:WorldToViewportPoint(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)*0.5))
    if corner.Z<=0 then allInFront=false end
    low=Vector2.new(math.min(low.X,corner.X),math.min(low.Y,corner.Y))
    high=Vector2.new(math.max(high.X,corner.X),math.max(high.Y,corner.Y))
   end end end
   local dx=math.max(low.X-mouse.X,0,mouse.X-high.X)
   local dy=math.max(low.Y-mouse.Y,0,mouse.Y-high.Y)
   local edgeDistance=Vector2.new(dx,dy).Magnitude
   if allInFront and edgeDistance<=NEAR_PIXELS then
    local score=(mouse-Vector2.new(center.X,center.Y)).Magnitude
    if not bestScore or score<bestScore then best,bestScore=part,score end
   end
  end
 end
 hovered=best
 effects:SetAttribute("HoveredAnchor",best and best.Name or "")
 -- Keep the last selection when the mouse moves away.
 if best then selectAnchor(best) end
end)

-- Each key locks its own target until that key is released.
UserInputService.InputBegan:Connect(function(input,processed)
 if processed or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return end
 local key=input.KeyCode
 if key~=Enum.KeyCode.Q and key~=Enum.KeyCode.E then return end
 if heldKeys[key] then return end
 local sign=key==Enum.KeyCode.E and 1 or -1
 if hovered and Motion.Start(hovered,sign) then heldKeys[key]=sign end
end)
UserInputService.InputEnded:Connect(function(input)
 local sign=heldKeys[input.KeyCode]
 if sign then
  heldKeys[input.KeyCode]=nil
  Motion.Stop(sign)
 end
end)
local function releaseMotion()
 table.clear(heldKeys)
 hovered=nil
 Motion.Stop()
end
UserInputService.WindowFocusReleased:Connect(releaseMotion)
UserInputService.TextBoxFocused:Connect(releaseMotion)
GuiService.MenuOpened:Connect(releaseMotion)
player.CharacterRemoving:Connect(function() table.clear(heldKeys) hovered=nil end)
