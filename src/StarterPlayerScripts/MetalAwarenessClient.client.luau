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
local pushHighlight=highlight:Clone()
pushHighlight.Name="PushTargetHighlight"
pushHighlight.Parent=effects
local pullHighlight=highlight:Clone()
pullHighlight.Name="PullTargetHighlight"
pullHighlight.Parent=effects
local entries={}
local selected
local root
local hovered
local Motion=require(script.Parent:WaitForChild("MetalMotion"))
local Config=require(game:GetService("ReplicatedStorage"):WaitForChild("MetalTuningConfig"))
local heldKeys={}
local function visual(part)
 local entry=part and entries[part]
 return entry and entry.visual or part
end
local function selectAnchor(part)
 if selected==part then return end
 selected=part
 highlight.Adornee=visual(part)
 highlight.Enabled=part~=nil
 effects:SetAttribute("SelectedAnchor",part and part.Name or "")
end
-- One soft ribbon avoids angle-dependent additive overlap between beam layers.
local RADIAL_LAYERS=1
-- A pixel-sized halo remains readable when the physical coin is sub-pixel.
local function createCoinGlow(part)
 local glow=Instance.new("BillboardGui")
 glow.Name="CoinGlow_"..part.Name
 glow.Adornee=part
 glow.Size=UDim2.fromOffset(28,28)
 glow.AlwaysOnTop=true
 glow.LightInfluence=0
 glow.Enabled=false
 glow.Parent=effects
 for _,layer in {{28,0.94},{24,0.9},{20,0.82},{16,0.65},{12,0.3},{7,0}} do
  local dot=Instance.new("Frame")
  dot.AnchorPoint=Vector2.new(0.5,0.5)
  dot.Position=UDim2.fromScale(0.5,0.5)
  dot.Size=UDim2.fromOffset(layer[1],layer[1])
  dot.BackgroundColor3=layer[1]==7 and Color3.fromRGB(235,255,255) or Color3.fromRGB(70,210,255)
  dot.BackgroundTransparency=layer[2]
  dot.BorderSizePixel=0
  dot.Parent=glow
  local corner=Instance.new("UICorner")
  corner.CornerRadius=UDim.new(1,0)
  corner.Parent=dot
 end
 return glow
end
local function addAnchor(part)
 if not part:IsA("BasePart") or entries[part] then return end
 local entry={layers={},outline={}}
 -- Twelve local-space edges provide adjustable pixel thickness through walls.
 -- This avoids a separate Highlight instance/render slot for every anchor.
 for axis=1,3 do
  for a=-1,1,2 do for b=-1,1,2 do
   local edge=Instance.new("LineHandleAdornment")
   edge.Name="AnchorOutline_"..part.Name
   edge.Adornee=part
   edge.AlwaysOnTop=true
   edge.ZIndex=1
   edge.Visible=false
   edge.Parent=effects
   table.insert(entry.outline,{edge=edge,axis=axis,a=a,b=b})
  end end
 end
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
  line.FaceCamera=true
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
  if entry.visual then entry.visual:Destroy() end
  if entry.glow then entry.glow:Destroy() end
  for _,item in entry.outline do item.edge:Destroy() end
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
 selectAnchor(nil)
 pushHighlight.Enabled=false
 pullHighlight.Enabled=false
 for _,entry in pairs(entries) do
  entry.outlineEnabled=false
  if entry.glow then entry.glow.Enabled=false end
  for _,item in entry.outline do item.edge.Visible=false end
  for _,layer in entry.layers do
   layer.line.Enabled=false
   layer.origin.Parent=nil
  end
 end
end)
if player.Character then task.spawn(bindCharacter,player.Character) end
RunService.RenderStepped:Connect(function(dt)
 if not root or not root.Parent then return end
 local pushTarget=Motion.GetTarget(-1)
 local pullTarget=Motion.GetTarget(1)
 pushHighlight.Adornee=visual(pushTarget)
 pullHighlight.Adornee=visual(pullTarget)
 pushHighlight.Enabled=pushTarget~=nil and pushTarget~=selected and Motion.IsInRange(pushTarget,root.Position)
 pullHighlight.Enabled=pullTarget~=nil and pullTarget~=selected and pullTarget~=pushTarget and Motion.IsInRange(pullTarget,root.Position)
 if selected and not Motion.IsInRange(selected,root.Position) then selectAnchor(nil) end
 if hovered and not Motion.IsInRange(hovered,root.Position) then
  hovered=nil
  effects:SetAttribute("HoveredAnchor","")
 end
 for part,entry in pairs(entries) do
  if part:GetAttribute("IsCoin") then
   if not entry.visual then
    local proxy=Instance.new("Part")
    proxy.Name="CoinVisual_"..part.Name proxy.Shape=Enum.PartType.Cylinder
    proxy.Size=part.Size proxy.Color=part.Color proxy.Material=part.Material
    proxy.Anchored=true proxy.CanCollide=false proxy.CanTouch=false proxy.CanQuery=false
    proxy.CFrame=part.CFrame proxy.Parent=effects entry.visual=proxy
    for _,item in entry.outline do item.edge.Adornee=proxy end
    for _,layer in entry.layers do layer.endpoint.Parent=proxy end
   end
   local proxy=entry.visual
   local visible=part.Transparency<1
   -- Render-only smoothing absorbs packet cadence; physical coins stay authoritative.
   if not entry.wasVisible or part.Anchored then proxy.CFrame=part.CFrame
   else proxy.CFrame=proxy.CFrame:Lerp(part.CFrame,1-math.exp(-25*dt)) end
   proxy.Transparency=visible and 0 or 1 entry.wasVisible=visible
   part.LocalTransparencyModifier=1
   if selected==part then highlight.Adornee=proxy end
  end
  local shown=visual(part)
  local delta=shown.Position-root.Position
  local enabled=Motion.IsInRange(part,root.Position) and (not entry.visual or entry.wasVisible)
  local active=part==selected or part==pushTarget or part==pullTarget
  local coin=part:GetAttribute("IsCoin")==true
  if coin and not entry.glow then entry.glow=createCoinGlow(shown) end
  if entry.glow then
   entry.glow.Enabled=enabled
   if entry.glowActive~=active then
    entry.glowActive=active
    for _,dot in entry.glow:GetChildren() do
     if dot:IsA("Frame") then
      local core=dot.Size.X.Offset==7
      dot.BackgroundColor3=active and (core and Color3.fromRGB(255,250,210) or Color3.fromRGB(255,185,55)) or (core and Color3.fromRGB(235,255,255) or Color3.fromRGB(70,210,255))
     end
    end
   end
  end
  if entry.outlineEnabled~=enabled or entry.outlineActive~=active or entry.outlineSize~=part.Size then
   entry.outlineEnabled=enabled entry.outlineActive=active entry.outlineSize=part.Size
   local half=part.Size*0.5
   for _,item in entry.outline do
    local start,finish
    if item.axis==1 then
     start=Vector3.new(-half.X,item.a*half.Y,item.b*half.Z) finish=Vector3.new(half.X,start.Y,start.Z)
    elseif item.axis==2 then
     start=Vector3.new(item.a*half.X,-half.Y,item.b*half.Z) finish=Vector3.new(start.X,half.Y,start.Z)
    else
     start=Vector3.new(item.a*half.X,item.b*half.Y,-half.Z) finish=Vector3.new(start.X,start.Y,half.Z)
    end
    item.edge.CFrame=CFrame.lookAt(start,finish)
    item.edge.Length=(finish-start).Magnitude
    item.edge.Thickness=coin and (active and 5 or 3.5) or (active and 3 or 1.5)
    item.edge.Color3=coin and (active and Color3.fromRGB(235,255,255) or Color3.fromRGB(150,230,255)) or (active and Color3.fromRGB(175,240,255) or Color3.fromRGB(65,155,215))
    item.edge.Transparency=coin and 0 or (active and 0.05 or 0.4)
    item.edge.Visible=enabled
   end
  end
  if enabled then
   local direction=delta.Unit
   local reference=math.abs(direction.Y)>0.98 and Vector3.xAxis or Vector3.yAxis
   local radial=direction:Cross(reference).Unit
   local other=direction:Cross(radial).Unit
   local width,transparency=Config.LineStyle(part.Size,delta.Magnitude,Motion.Settings.AnchorRange)
   local color=ColorSequence.new(Color3.fromRGB(40,155,255))
   for _,layer in entry.layers do
    if layer.origin.Parent~=root then layer.origin.Parent=root end
    local up=radial*math.cos(layer.angle)+other*math.sin(layer.angle)
    local frame=CFrame.fromMatrix(root.Position,direction,up,direction:Cross(up))
    layer.origin.CFrame=root.CFrame:ToObjectSpace(frame)
    layer.endpoint.CFrame=shown.CFrame:ToObjectSpace(frame+delta)
    layer.line.Width0=width
    layer.line.Width1=width
    layer.line.Color=color
    layer.line.Transparency=NumberSequence.new(transparency)
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
  local shown=visual(part)
  local center,onScreen=camera:WorldToViewportPoint(shown.Position)
  if onScreen and center.Z>0 and part.Transparency<1 and Motion.IsInRange(part,root.Position) then
   local low=Vector2.new(math.huge,math.huge)
   local high=Vector2.new(-math.huge,-math.huge)
   local allInFront=true
   for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local corner=camera:WorldToViewportPoint(shown.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)*0.5))
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
 if selected and Motion.Start(selected,sign) then heldKeys[key]=sign end
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
