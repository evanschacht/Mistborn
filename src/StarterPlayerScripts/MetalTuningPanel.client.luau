local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Motion=require(script.Parent:WaitForChild("MetalMotion"))
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
make("UICorner",{CornerRadius=UDim.new(0,10)},panel)
make("UIStroke",{Color=Color3.fromRGB(58,90,116),Transparency=0.35},panel)
local header=make("TextButton",{Name="Collapse",Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text="METAL TUNING   −",TextColor3=Color3.fromRGB(177,226,255),Font=Enum.Font.GothamBold,TextSize=15},panel)
local content=make("Frame",{Name="Content",Position=UDim2.fromOffset(0,42),Size=UDim2.new(1,0,1,-42),BackgroundTransparency=1},panel)
make("TextLabel",{Size=UDim2.new(1,-24,0,34),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,Text="Live changes • this play session\nQ push  /  E pull",TextColor3=Color3.fromRGB(165,178,195),Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},content)
local list=make("ScrollingFrame",{Name="Sliders",Position=UDim2.fromOffset(12,40),Size=UDim2.new(1,-24,1,-88),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Color3.fromRGB(94,193,255),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},content)
make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},list)
local drag
local updates={}
for index,spec in Motion.SettingSpecs do
 local row=make("Frame",{Name=spec.key,Size=UDim2.new(1,-8,0,88),LayoutOrder=index,BackgroundTransparency=1},list)
 make("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=spec.title,TextColor3=Color3.fromRGB(233,239,246),TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left},row)
 local value=make("TextLabel",{Position=UDim2.fromOffset(0,21),Size=UDim2.new(1,0,0,17),BackgroundTransparency=1,TextColor3=Color3.fromRGB(95,202,255),Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},row)
 local hit=make("TextButton",{Name="Slider",Position=UDim2.fromOffset(0,39),Size=UDim2.new(1,0,0,24),Text="",AutoButtonColor=false,BackgroundTransparency=1},row)
 local track=make("Frame",{Name="Track",Position=UDim2.new(0,7,0.5,-3),Size=UDim2.new(1,-14,0,6),BackgroundColor3=Color3.fromRGB(48,64,83),BorderSizePixel=0},hit)
 make("UICorner",{CornerRadius=UDim.new(1,0)},track)
 local fill=make("Frame",{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(60,173,236),BorderSizePixel=0},track)
 make("UICorner",{CornerRadius=UDim.new(1,0)},fill)
 local knob=make("Frame",{Name="Knob",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.fromRGB(185,233,255),BorderSizePixel=0},track)
 make("UICorner",{CornerRadius=UDim.new(1,0)},knob)
 make("TextLabel",{Position=UDim2.fromOffset(0,64),Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text=spec.hint,TextWrapped=true,TextColor3=Color3.fromRGB(155,168,186),TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},row)
 local function refresh()
  local v=Motion.Settings[spec.key]
  local fraction=(v-spec.min)/(spec.max-spec.min)
  fill.Size=UDim2.fromScale(fraction,1)
  knob.Position=UDim2.fromScale(fraction,0.5)
  value.Text=string.format(spec.step>=1 and "%.0f%s" or "%.2f%s",v,spec.unit)
  row:SetAttribute("Value",v)
 end
 updates[spec.key]=refresh
 local function setAt(x)
  local fraction=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
  Motion.SetSetting(spec.key,spec.min+fraction*(spec.max-spec.min))
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
local reset=make("TextButton",{Name="Reset",Position=UDim2.new(0,12,1,-38),Size=UDim2.new(1,-24,0,28),BackgroundColor3=Color3.fromRGB(39,57,77),Text="Reset all to defaults",TextColor3=Color3.fromRGB(220,233,245),Font=Enum.Font.GothamMedium,TextSize=12,BorderSizePixel=0},content)
make("UICorner",{CornerRadius=UDim.new(0,6)},reset)
reset.Activated:Connect(function() Motion.ResetSettings() for _,update in pairs(updates) do update() end end)
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
