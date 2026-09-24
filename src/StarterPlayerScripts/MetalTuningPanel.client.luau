local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Motion=require(script.Parent:WaitForChild("MetalMotion"))
local remote=game:GetService("ReplicatedStorage"):WaitForChild("MetalTuningPersistence",10)
local loadMessage="Project preset loaded"
local canSave=false
if remote then
 local ok,response=pcall(function() return remote:InvokeServer("Load") end)
 if ok and typeof(response)=="table" then canSave=response.canSave==true end
 if ok and response.ok then
  if response.data and Motion.ApplySettings(response.data) then loadMessage="Master tuning loaded" end
 else loadMessage="Could not load master tuning; using preset" end
end
local screen=Instance.new("ScreenGui")
screen.Name="MetalTuning"
screen.ResetOnSpawn=false
screen.IgnoreGuiInset=true
screen.DisplayOrder=20
screen.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local function make(class,props,parent)
 local obj=Instance.new(class)
 for k,v in pairs(props) do obj[k]=v end
 obj.Parent=parent
 return obj
end
local panel=make("Frame",{Name="Panel",Position=UDim2.fromOffset(12,82),Size=UDim2.fromOffset(282,510),BackgroundColor3=Color3.fromRGB(17,24,36),BackgroundTransparency=0.08,BorderSizePixel=0,Active=true},screen)
panel.Visible=canSave
make("UICorner",{CornerRadius=UDim.new(0,10)},panel)
make("UIStroke",{Color=Color3.fromRGB(58,90,116),Transparency=0.35},panel)
local header=make("TextButton",{Name="Collapse",Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text="METAL TUNING   −",TextColor3=Color3.fromRGB(177,226,255),Font=Enum.Font.GothamBold,TextSize=15},panel)
local content=make("Frame",{Name="Content",Position=UDim2.fromOffset(0,42),Size=UDim2.new(1,0,1,-42),BackgroundTransparency=1},panel)
make("TextLabel",{Size=UDim2.new(1,-24,0,34),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,Text="Preview locally • Save applies to everyone\nQ push  /  E pull",TextColor3=Color3.fromRGB(165,178,195),Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},content)
local speedometer=make("Frame",{Name="Speedometer",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),Size=UDim2.fromOffset(108,108),BackgroundColor3=Color3.fromRGB(17,24,36),BackgroundTransparency=0.12,BorderSizePixel=0,Visible=false},screen)
make("UICorner",{CornerRadius=UDim.new(1,0)},speedometer)
make("UIStroke",{Color=Color3.fromRGB(95,202,255),Thickness=2,Transparency=0.25},speedometer)
local speedText=make("TextLabel",{Name="Speed",Position=UDim2.fromOffset(4,20),Size=UDim2.new(1,-8,0,44),BackgroundTransparency=1,Text="0",TextColor3=Color3.fromRGB(233,245,255),Font=Enum.Font.GothamBold,TextSize=32,TextScaled=true},speedometer)
make("TextLabel",{Position=UDim2.fromOffset(0,68),Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="studs / second",TextColor3=Color3.fromRGB(165,207,228),Font=Enum.Font.Gotham,TextSize=10},speedometer)
local speedToggle=make("TextButton",{Name="SpeedometerToggle",Position=UDim2.fromOffset(12,35),Size=UDim2.new(1,-24,0,26),BackgroundColor3=Color3.fromRGB(39,57,77),Text="Speedometer: OFF",TextColor3=Color3.fromRGB(220,233,245),Font=Enum.Font.GothamMedium,TextSize=12,BorderSizePixel=0},content)
make("UICorner",{CornerRadius=UDim.new(0,6)},speedToggle)
screen:SetAttribute("ShowSpeedometer",script.Parent.MetalMotion:GetAttribute("ShowSpeedometer")==true)
local function showSpeedometer()
 local on=screen:GetAttribute("ShowSpeedometer")==true
 speedometer.Visible=on speedToggle.Text=on and "Speedometer: ON" or "Speedometer: OFF"
 speedToggle.BackgroundColor3=on and Color3.fromRGB(31,99,133) or Color3.fromRGB(39,57,77)
end
screen:GetAttributeChangedSignal("ShowSpeedometer"):Connect(showSpeedometer)
showSpeedometer()
speedToggle.Activated:Connect(function() screen:SetAttribute("ShowSpeedometer",not speedometer.Visible) end)
local elapsed=0
local speedConnection=RunService.RenderStepped:Connect(function(dt)
 elapsed+=dt
 if elapsed<0.1 or not speedometer.Visible then return end
 elapsed=0
 local c=Players.LocalPlayer.Character local r=c and c:FindFirstChild("HumanoidRootPart")
 local speed=r and r.AssemblyLinearVelocity.Magnitude or 0
 speedText.Text=string.format("%.0f",speed)
 speedometer:SetAttribute("Speed",speed)
end)
script.Destroying:Connect(function() speedConnection:Disconnect() screen:Destroy() end)
local list=make("ScrollingFrame",{Name="Sliders",Position=UDim2.fromOffset(12,68),Size=UDim2.new(1,-24,1,-168),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(94,193,255),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},content)
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},list)
local drag
local updates={}

-- Categories start closed; each expands independently inside the scrolling area.
local groups={
 {name="GroundMovement",title="Ground movement",keys={"GroundSpeed","GroundAcceleration"}},
 {name="AerialMovement",title="Aerial movement",keys={"AirSpeed","AirAcceleration","AirDrag","JumpStrength","Gravity"}},
 {name="Sliding",title="Sliding",keys={"SlideWAcceleration","SlideWTopSpeed","SlideBraking","SlideLeftSteering","SlideRightSteering","CoastDrag","StopSpeed"}},
 {name="PushPull",title="Push & pull",keys={"PullAcceleration","PushAcceleration","PullSpeed","PushSpeed","PullFalloff","PushFalloff","ForceNearClamp","ForceFarClamp"}},
 {name="MetalSensing",title="Metal sensing",keys={"AnchorRange"}},
}
local rowParents={}
local rowOrders={}
for order,group in groups do
 local section=make("Frame",{Name=group.name,Size=UDim2.new(1,-8,0,34),LayoutOrder=order,BackgroundTransparency=1},list)
 local toggle=make("TextButton",{Name="Toggle",Size=UDim2.new(1,0,0,34),BackgroundColor3=Color3.fromRGB(34,51,70),BorderSizePixel=0,Text="+  "..group.title,TextColor3=Color3.fromRGB(177,226,255),Font=Enum.Font.GothamMedium,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},section)
 make("UICorner",{CornerRadius=UDim.new(0,6)},toggle)
 make("UIPadding",{PaddingLeft=UDim.new(0,10)},toggle)
 local body=make("Frame",{Name="Rows",Position=UDim2.fromOffset(0,40),Size=UDim2.new(1,0,0,#group.keys*162-6),BackgroundTransparency=1,Visible=false},section)
 make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},body)
 section:SetAttribute("Expanded",false)
 local function refreshSection()
  local expanded=section:GetAttribute("Expanded")==true
  body.Visible=expanded
  section.Size=UDim2.new(1,-8,0,expanded and (40+#group.keys*162-6) or 34)
  toggle.Text=(expanded and "-  " or "+  ")..group.title
  if not expanded then drag=nil list.ScrollingEnabled=true end
 end
 section:GetAttributeChangedSignal("Expanded"):Connect(refreshSection)
 toggle.Activated:Connect(function() section:SetAttribute("Expanded",not section:GetAttribute("Expanded")) end)
 for position,key in group.keys do rowParents[key]=body rowOrders[key]=position end
end

for index,spec in Motion.SettingSpecs do
 local row=make("Frame",{Name=spec.key,Size=UDim2.new(1,0,0,156),LayoutOrder=rowOrders[spec.key] or index,BackgroundTransparency=1},assert(rowParents[spec.key],"Missing tuning category: "..spec.key))
 make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=spec.title,TextColor3=Color3.fromRGB(233,239,246),TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left},row)
 local value=make("TextBox",{Name="Value",ClearTextOnFocus=false,Position=UDim2.fromOffset(0,21),Size=UDim2.new(1,0,0,20),BackgroundColor3=Color3.fromRGB(28,40,55),BorderSizePixel=0,TextColor3=Color3.fromRGB(95,202,255),Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},row)
 local hit=make("TextButton",{Name="Slider",Position=UDim2.fromOffset(0,39),Size=UDim2.new(1,0,0,24),Text="",AutoButtonColor=false,BackgroundTransparency=1},row)
 local track=make("Frame",{Name="Track",Position=UDim2.new(0,7,0.5,-3),Size=UDim2.new(1,-14,0,6),BackgroundColor3=Color3.fromRGB(48,64,83),BorderSizePixel=0},hit)
 make("UICorner",{CornerRadius=UDim.new(1,0)},track)
 local fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(60,173,236),BorderSizePixel=0},track)
 make("UICorner",{CornerRadius=UDim.new(1,0)},fill)
 local knob=make("Frame",{Name="Knob",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.fromRGB(185,233,255),BorderSizePixel=0},track)
 make("UICorner",{CornerRadius=UDim.new(1,0)},knob)
 make("TextLabel",{Position=UDim2.fromOffset(0,99),Size=UDim2.new(1,0,0,27),BackgroundTransparency=1,Text=spec.hint,TextWrapped=true,TextColor3=Color3.fromRGB(155,168,186),TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},row)
 local function rangeBox(name,x)
  make("TextLabel",{Position=UDim2.new(x,0,0,67),Size=UDim2.new(0.14,0,0,24),BackgroundTransparency=1,Text=name,Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(155,168,186),TextXAlignment=Enum.TextXAlignment.Left},row)
  return make("TextBox",{Name=name,ClearTextOnFocus=false,Position=UDim2.new(x+0.14,0,0,67),Size=UDim2.new(0.33,0,0,24),BackgroundColor3=Color3.fromRGB(28,40,55),BorderSizePixel=0,TextColor3=Color3.fromRGB(214,231,242),Font=Enum.Font.Gotham,TextSize=12},row)
 end
 local minBox,maxBox=rangeBox("Min",0),rangeBox("Max",0.51)
 local function refresh()
  local v=Motion.Settings[spec.key]
  local low,high=Motion.GetRange(spec.key)
  local fraction=math.clamp((v-low)/(high-low),0,1)
  minBox.Text=tostring(low) maxBox.Text=tostring(high)
  fill.Size=UDim2.fromScale(fraction,1)
  knob.Position=UDim2.fromScale(fraction,0.5)
  value.Text=tostring(v)
  value.PlaceholderText=spec.unit
  row:SetAttribute("Value",v)
 end
 value.FocusLost:Connect(function() Motion.SetSetting(spec.key,tonumber(value.Text)) refresh() end)
 local function changeRange()
  local valid=Motion.SetRange(spec.key,tonumber(minBox.Text),tonumber(maxBox.Text))
  refresh()
  if not valid then
   minBox.TextColor3=Color3.fromRGB(255,135,135) maxBox.TextColor3=minBox.TextColor3
   task.delay(1,function() if minBox.Parent then minBox.TextColor3=Color3.fromRGB(214,231,242) maxBox.TextColor3=minBox.TextColor3 end end)
  end
 end
 minBox.FocusLost:Connect(changeRange) maxBox.FocusLost:Connect(changeRange)
 updates[spec.key]=refresh
 local resetOne=make("TextButton",{Name="ResetDefault",Position=UDim2.fromOffset(0,129),Size=UDim2.new(1,0,0,23),BackgroundColor3=Color3.fromRGB(39,57,77),Text="Reset to Default",TextColor3=Color3.fromRGB(220,233,245),Font=Enum.Font.GothamMedium,TextSize=11,BorderSizePixel=0},row)
 make("UICorner",{CornerRadius=UDim.new(0,5)},resetOne)
 resetOne.Activated:Connect(function() Motion.ResetSetting(spec.key) refresh() end)
 local function setAt(x)
  local fraction=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
  local low,high=Motion.GetRange(spec.key)
  Motion.SetSetting(spec.key,low+fraction*(high-low))
  refresh()
 end
 hit.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   drag={setAt=setAt,input=input}
   list.ScrollingEnabled=false
   setAt(input.Position.X)
  end
 end)
 refresh()
end
UIS.InputChanged:Connect(function(input)
 if drag and (input.UserInputType==Enum.UserInputType.MouseMovement or input==drag.input) then drag.setAt(input.Position.X) end
end)
UIS.InputEnded:Connect(function(input)
 if drag and (input.UserInputType==Enum.UserInputType.MouseButton1 or input==drag.input) then drag=nil list.ScrollingEnabled=true end
end)
UIS.WindowFocusReleased:Connect(function() drag=nil list.ScrollingEnabled=true end)
local reset=make("TextButton",{Name="Reset",Position=UDim2.new(0,12,1,-92),Size=UDim2.new(1,-24,0,28),BackgroundColor3=Color3.fromRGB(39,57,77),Text="Reset all to defaults",TextColor3=Color3.fromRGB(220,233,245),Font=Enum.Font.GothamMedium,TextSize=12,BorderSizePixel=0},content)
make("UICorner",{CornerRadius=UDim.new(0,6)},reset)
reset.Activated:Connect(function() Motion.ResetSettings() for _,update in pairs(updates) do update() end end)
local save=make("TextButton",{Name="Save",Position=UDim2.new(0,12,1,-58),Size=UDim2.new(1,-24,0,28),BackgroundColor3=Color3.fromRGB(31,99,133),Text="Save Metal Tuning",TextColor3=Color3.fromRGB(235,246,255),Font=Enum.Font.GothamMedium,TextSize=12,BorderSizePixel=0},content)
make("UICorner",{CornerRadius=UDim.new(0,6)},save)
local status=make("TextLabel",{Name="SaveStatus",Position=UDim2.new(0,12,1,-26),Size=UDim2.new(1,-24,0,22),BackgroundTransparency=1,Text=loadMessage,TextWrapped=true,TextColor3=Color3.fromRGB(165,207,228),Font=Enum.Font.Gotham,TextSize=10},content)
local saving=false
local masterState=game:GetService("ReplicatedStorage"):WaitForChild("MetalTuningMasterState",10)
local revision=-1
local function applyMaster()
 if not masterState then return end
 local ok,record=pcall(function() return game:GetService("HttpService"):JSONDecode(masterState.Value) end)
 if not ok or typeof(record)~="table" or typeof(record.revision)~="number" or record.revision<=revision then return end
 if not Motion.ApplySettings(record.data) then return end
 revision=record.revision
 screen:SetAttribute("MasterRevision",revision)
 screen:SetAttribute("ShowSpeedometer",record.data.showSpeedometer)
 for _,update in pairs(updates) do update() end
 if revision>0 then status.Text="Master tuning applied to everyone" end
end
if masterState then
 masterState.Changed:Connect(applyMaster)
 applyMaster()
end
save.Activated:Connect(function()
 if saving then return end
 local focused=UIS:GetFocusedTextBox()
 if focused then focused:ReleaseFocus() task.wait() end
 saving=true save.Text="Saving…" status.Text=""
 local snapshot=Motion.Snapshot(screen:GetAttribute("ShowSpeedometer"))
 local ok,response=pcall(function()
  if not remote then remote=game:GetService("ReplicatedStorage"):FindFirstChild("MetalTuningPersistence") end
  if not remote then error("Save service not ready") end
  return remote:InvokeServer("Save",snapshot)
 end)
 local success=ok and typeof(response)=="table" and response.ok
 status.Text=success and "Master saved • applies to everyone" or (ok and response.message or "Save failed; please retry")
 status.TextColor3=success and Color3.fromRGB(137,233,175) or Color3.fromRGB(255,155,135)
 screen:SetAttribute("LastSaveSucceeded",success==true)
 save.Text="Save Metal Tuning" saving=false
end)
local collapsed=false
local function resize()
 local camera=workspace.CurrentCamera
 local height=math.clamp((camera and camera.ViewportSize.Y or 720)-100,160,510)
 panel.Size=UDim2.fromOffset(282,collapsed and 42 or height)
end
header.Activated:Connect(function()
 collapsed=not collapsed content.Visible=not collapsed
 header.Text=collapsed and "METAL TUNING   +" or "METAL TUNING   −"
 resize()
end)
local function watchCamera()
 local camera=workspace.CurrentCamera
 if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
 resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
