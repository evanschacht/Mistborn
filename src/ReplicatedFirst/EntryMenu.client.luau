-- Mount before dismissing Roblox's loader; never depend on a character to show entry UI.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
while not player do
 Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
 player = Players.LocalPlayer
end
local playerGui = player:WaitForChild("PlayerGui")
local colors = {
 ink = Color3.fromRGB(12, 16, 20), stone = Color3.fromRGB(29, 37, 42),
 light = Color3.fromRGB(230, 231, 224), muted = Color3.fromRGB(146, 160, 164),
 gold = Color3.fromRGB(199, 176, 124), border = Color3.fromRGB(73, 87, 91),
}
local function make(className, properties, parent)
 local instance = Instance.new(className)
 for key, value in pairs(properties) do instance[key] = value end
 instance.Parent = parent
 return instance
end
local screen = make("ScreenGui", {
 Name = "EntryMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
 DisplayOrder = 1000000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)
local canvas = make("CanvasGroup", {
 Name = "EntryCanvas", Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.ink,
 BorderSizePixel = 0, GroupTransparency = 0, GroupColor3 = Color3.new(1, 1, 1),
}, screen)
local background = make("Frame", {
 Name = "MistBackground", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
 BorderSizePixel = 0,
}, canvas)
make("UIGradient", {
 Rotation = 125, Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 46, 50)),
  ColorSequenceKeypoint.new(0.55, colors.ink),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 24, 30)),
 }),
}, background)
-- Modal keeps the pointer available while the character camera is not yet active.
make("TextButton", {
 Name = "InputShield", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
 Text = "", Modal = true, Active = true, Selectable = false, AutoButtonColor = false,
}, canvas)
for index = 1, 3 do
 local ring = make("Frame", {
  Name = "MistRing" .. index, AnchorPoint = Vector2.new(0.5, 0.5),
  Position = UDim2.fromScale(0.83, 0.45), Size = UDim2.fromOffset(400 + index * 150, 400 + index * 150),
  BackgroundTransparency = 1, BorderSizePixel = 0,
 }, canvas)
 make("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
 make("UIStroke", { Color = colors.border, Transparency = 0.88, Thickness = 1 }, ring)
end
local content = make("Frame", {
 Name = "MenuContent", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
 Size = UDim2.new(1, -48, 0, 508), BackgroundTransparency = 1,
}, canvas)
make("UISizeConstraint", { MaxSize = Vector2.new(560, 508) }, content)
local scale = make("UIScale", { Scale = 1 }, content)
local function label(name, text, y, height, size, color)
 return make("TextLabel", {
  Name = name, Text = text, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, height),
  BackgroundTransparency = 1, TextColor3 = color or colors.light, Font = Enum.Font.Gotham,
  TextSize = size, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
 }, content)
end
label("Eyebrow", "A S H   &   A L L O M A N C Y", 0, 24, 11, colors.gold)
local title = label("Title", "MISTBORN", 34, 72, 54)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
make("UITextSizeConstraint", { MinTextSize = 24, MaxTextSize = 54 }, title)
label("Subtitle", "Find your footing. Then take to the mist.", 112, 48, 16, colors.muted)
make("Frame", {
 Name = "Divider", Position = UDim2.fromOffset(0, 179), Size = UDim2.new(1, 0, 0, 1),
 BackgroundColor3 = colors.border, BackgroundTransparency = 0.4, BorderSizePixel = 0,
}, content)
label("ChooseLabel", "CHOOSE YOUR PATH", 198, 24, 11, colors.muted)
local buttons = {}
local strokes = {}
local function modeButton(mode, text, description, y)
 local button = make("TextButton", {
  Name = mode .. "Button", Text = text, Position = UDim2.fromOffset(0, y),
  Size = UDim2.new(1, 0, 0, 92), BackgroundColor3 = colors.stone,
  BackgroundTransparency = 0.25, BorderSizePixel = 0, AutoButtonColor = false,
  TextColor3 = colors.light, TextSize = 21, Font = Enum.Font.GothamMedium,
  TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
  Selectable = false, Active = false,
 }, content)
 make("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
 make("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 17) }, button)
 local stroke = make("UIStroke", { Color = colors.border, Transparency = 0.4, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
 make("TextLabel", {
  Name = "Description", Text = description, Position = UDim2.fromOffset(0, 30),
  Size = UDim2.new(1, 0, 0, 31), BackgroundTransparency = 1, TextColor3 = colors.muted,
  Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
 }, button)
 buttons[mode] = button
 strokes[mode] = stroke
 return button
end
local dev = modeButton("Dev", "Dev Mode", "Explore the sandbox and tune your movement.", 238)
local tutorial = modeButton("Tutorial", "Tutorial Level", "Enter the training grounds beside the old stone wall.", 342)
dev.NextSelectionDown = tutorial
dev.NextSelectionUp = tutorial
tutorial.NextSelectionDown = dev
tutorial.NextSelectionUp = dev
local status = label("Status", "Connecting to the world…", 450, 48, 13, colors.muted)
status.TextYAlignment = Enum.TextYAlignment.Top
screen:SetAttribute("State", "Connecting")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local closed = false
local revealing = false
local ready = false
local busy = false
local remote
local connections = {}
local suppressed = {}
local savedCore = {}
local savedCameras = {}
local previousSelection = GuiService.SelectedObject
local function connect(signal, callback)
 local connection = signal:Connect(callback)
 table.insert(connections, connection)
 return connection
end
-- Preserve each HUD's enabled state, including HUDs added during replication.
local function suppressGui(gui)
 if gui == screen or not gui:IsA("ScreenGui") or suppressed[gui] ~= nil then return end
 suppressed[gui] = gui.Enabled
 gui.Enabled = false
 connect(gui:GetPropertyChangedSignal("Enabled"), function()
  if not closed and gui.Enabled then
   suppressed[gui] = true
   gui.Enabled = false
  end
 end)
end
connect(playerGui.ChildAdded, suppressGui)
for _, child in ipairs(playerGui:GetChildren()) do suppressGui(child) end
-- Core scripts may not be registered on the first frame. Capture before each first write.
task.spawn(function()
 for attempt = 1, 20 do
  if closed then return end
  local pending = false
  for _, coreType in ipairs(Enum.CoreGuiType:GetEnumItems()) do
   if coreType ~= Enum.CoreGuiType.All and savedCore[coreType] == nil then
    local ok, enabled = pcall(function() return StarterGui:GetCoreGuiEnabled(coreType) end)
    if ok then
     local hidden = pcall(function() StarterGui:SetCoreGuiEnabled(coreType, false) end)
     if hidden then savedCore[coreType] = enabled else pending = true end
    else pending = true end
   end
  end
  if not pending then return end
  task.wait(0.15)
 end
end)
ContextActionService:BindActionAtPriority("EntryMenuBlockMovement", function()
 return Enum.ContextActionResult.Sink
end, false, 10000, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
 Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.Space,
 Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)

local function updateViewport()
 local camera = workspace.CurrentCamera
 local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
 local fit = math.clamp((viewport.Y - 32) / 508, 0.45, 1)
 scale.Scale = fit
 -- Keep the logical width legible in portrait while allowing landscape to shrink vertically.
 content.Size = UDim2.new(0, math.min(560, (viewport.X - 48) / fit), 0, 508)
end
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), updateViewport)
-- No world view is needed behind the opaque menu; preserve the existing camera's transform.
RunService:BindToRenderStep("EntryMenuCamera", Enum.RenderPriority.Camera.Value + 1, function()
 local camera = workspace.CurrentCamera
 if camera and not savedCameras[camera] then
  savedCameras[camera] = { cameraType = camera.CameraType, subject = camera.CameraSubject, cframe = camera.CFrame }
 end
 if camera then
  camera.CameraType = Enum.CameraType.Scriptable
  camera.CFrame = savedCameras[camera].cframe
 end
 updateViewport()
end)
local function available()
 return ready and not busy and not revealing and not closed
end
local function updateButtons()
 for _, button in pairs(buttons) do
  button.Active = available()
  button.Selectable = available()
  button.TextTransparency = available() and 0 or 0.35
 end
 if not available() and (GuiService.SelectedObject == dev or GuiService.SelectedObject == tutorial) then
  GuiService.SelectedObject = nil
 elseif available() and UserInputService.GamepadEnabled and not GuiService.SelectedObject then
  GuiService.SelectedObject = dev
 end
end
connect(UserInputService.GamepadConnected, updateButtons)
connect(UserInputService.LastInputTypeChanged, function(inputType)
 if inputType.Name:match("^Gamepad") then updateButtons() end
end)
for mode, button in pairs(buttons) do
 local function highlight(on)
  TweenService:Create(strokes[mode], TweenInfo.new(0.15), {
   Color = on and colors.gold or colors.border, Transparency = on and 0.08 or 0.4,
  }):Play()
 end
 connect(button.MouseEnter, function() if available() then highlight(true) end end)
 connect(button.MouseLeave, function() highlight(GuiService.SelectedObject == button) end)
 connect(button.SelectionGained, function() highlight(true) end)
 connect(button.SelectionLost, function() highlight(false) end)
 connect(button.Activated, function()
  if not available() or not remote then return end
  busy = true
  screen:SetAttribute("SelectedMode", mode)
  screen:SetAttribute("State", "Loading")
  status.TextColor3 = colors.muted
  status.Text = mode == "Tutorial" and "Preparing your tutorial…" or "Preparing the sandbox…"
  updateButtons()
  remote:FireServer(mode)
 end)
end
local function restore(humanoid)
 closed = true
 RunService:UnbindFromRenderStep("EntryMenuCamera")
 RunService:UnbindFromRenderStep("EntryMenuTutorialFraming")
 ContextActionService:UnbindAction("EntryMenuBlockMovement")
 for _, connection in ipairs(connections) do connection:Disconnect() end
 for gui, enabled in pairs(suppressed) do
  if gui.Parent then gui.Enabled = enabled end
 end
 for coreType, enabled in pairs(savedCore) do
  pcall(function() StarterGui:SetCoreGuiEnabled(coreType, enabled) end)
 end
 for camera, previous in pairs(savedCameras) do
  if camera.Parent then
   camera.CameraType = humanoid and Enum.CameraType.Custom or previous.cameraType
   camera.CameraSubject = humanoid or previous.subject
  end
 end
 if previousSelection and previousSelection.Parent then GuiService.SelectedObject = previousSelection
 elseif GuiService.SelectedObject == dev or GuiService.SelectedObject == tutorial then GuiService.SelectedObject = nil end
end
local function tryReveal()
 if closed or revealing or not game:IsLoaded() then return end
 local mode = player:GetAttribute("EntryMode")
 local admitted = mode == "Dev" or mode == "Tutorial" or workspace:GetAttribute("WorldMode") == "Tutorial"
 local character = player.Character
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 local root = character and character:FindFirstChild("HumanoidRootPart")
 if not admitted or not humanoid or not root or humanoid.Health <= 0 then return end
 revealing = true
 screen:SetAttribute("State", "Entered")
 status.Text = "You’re ready."
 updateButtons()
 -- Restore the character camera under the opaque layer, then reveal its first rendered frame.
 RunService:UnbindFromRenderStep("EntryMenuCamera")
 local camera = workspace.CurrentCamera
 if camera then camera.CameraType = Enum.CameraType.Custom; camera.CameraSubject = humanoid end
 local tutorialArrival = mode == "Tutorial" or workspace:GetAttribute("WorldMode") == "Tutorial"
 if tutorialArrival then
  -- Seed the normal camera from behind the arrival, facing the wall. Apply after
  -- the controller's first two frames so its initial subject reset cannot hide it.
  local arrivalPosition = root.Position
  local focus = arrivalPosition + Vector3.new(0, 5, -45)
  local framing = CFrame.lookAt(arrivalPosition + Vector3.new(0, 7, 20), focus)
  RunService:BindToRenderStep("EntryMenuTutorialFraming", Enum.RenderPriority.Camera.Value + 2, function()
   local current = workspace.CurrentCamera
   if current then
    current.CFrame = framing
    current.Focus = CFrame.new(focus)
   end
  end)
 end
 task.spawn(function()
  RunService.RenderStepped:Wait()
  if tutorialArrival then
   RunService.RenderStepped:Wait()
   RunService:UnbindFromRenderStep("EntryMenuTutorialFraming")
  end
  if closed then return end
  local fade = TweenService:Create(canvas, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
  fade:Play()
  fade.Completed:Wait()
  if closed then return end
  restore(humanoid)
  screen:Destroy()
 end)
end
connect(game.Loaded, tryReveal)
connect(player:GetAttributeChangedSignal("EntryMode"), tryReveal)
connect(workspace:GetAttributeChangedSignal("WorldMode"), tryReveal)
connect(player.CharacterAdded, function(character)
 connect(character.ChildAdded, tryReveal)
 tryReveal()
end)
if player.Character then connect(player.Character.ChildAdded, tryReveal) end
connect(script.Destroying, function()
 if not closed then restore(nil); screen:Destroy() end
end)
-- Polling covers the small gap between root replication and a live Humanoid.
task.spawn(function()
 while not closed and not revealing do tryReveal(); task.wait(0.1) end
end)
task.spawn(function()
 -- Do not wait for game.Loaded: both the UI and Ready handshake work during replication.
 local flow = ReplicatedStorage:WaitForChild("EntryFlow", 20)
 remote = flow and flow:WaitForChild("ChooseMode", 20)
 local statusRemote = flow and flow:WaitForChild("Status", 20)
 if closed or revealing then return end
 if not remote or not statusRemote or not remote:IsA("RemoteEvent") or not statusRemote:IsA("RemoteEvent") then
  screen:SetAttribute("State", "Error")
  status.Text = "Entry service unavailable. Please rejoin the experience."
  status.TextColor3 = colors.gold
  return
 end
 connect(statusRemote.OnClientEvent, function(state, message)
  if closed or revealing then return end
  if state ~= "Ready" and state ~= "Loading" and state ~= "Entered" and state ~= "Error" then return end
  screen:SetAttribute("State", state)
  status.TextColor3 = state == "Error" and colors.gold or colors.muted
  if state == "Ready" then
   ready = true; busy = false
   status.Text = "Select a mode to enter."
  elseif state == "Error" then
   ready = true; busy = false
   status.Text = typeof(message) == "string" and message or "Could not enter. Choose a mode to try again."
  else
   busy = true
   status.Text = typeof(message) == "string" and message or "Preparing your arrival…"
  end
  updateButtons()
  tryReveal()
 end)
 remote:FireServer("Ready")
 while not closed and not revealing and not ready do
  task.wait(3)
  if not closed and not revealing and not ready then remote:FireServer("Ready") end
 end
end)
