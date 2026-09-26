local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Rules=require(RS:WaitForChild("CoinRules"))
local remote=RS:WaitForChild("CoinToss")
local motionScript=script.Parent:WaitForChild("MetalMotion")
local pendingUntil=0
remote.OnClientEvent:Connect(function(action,coinName)
 if action~="Release" or typeof(coinName)~="string" then return end
 local coin=workspace:WaitForChild("MetalAnchors"):WaitForChild(coinName,2)
 if not coin or not coin:IsA("BasePart") then return end
 local c=player.Character
 local root=c and c:FindFirstChild("HumanoidRootPart")
 if not root or not coin.Parent then return end
 -- Use the current local position when the physical coin becomes visible,
 -- rather than the older character position received by the server.
 coin.CFrame=CFrame.new(root.Position-Vector3.yAxis)*CFrame.Angles(0,0,math.pi/2)
 coin.AssemblyLinearVelocity=Vector3.new(0,-2*Rules.FallSpeedScale,0)
 coin.AssemblyAngularVelocity=Vector3.zero
 local force=coin:FindFirstChild("CoinGravity")
 if force then force.Force=Vector3.new(0,-coin.AssemblyMass*workspace.Gravity*(Rules.FallSpeedScale^2-1),0) end
end)
local gui=Instance.new("ScreenGui") gui.Name="CoinCounter" gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel") label.Name="Coins" label.AnchorPoint=Vector2.new(0,1)
label.Position=UDim2.new(0,18,1,-18) label.Size=UDim2.fromOffset(164,44)
label.BackgroundColor3=Color3.fromRGB(17,24,36) label.BackgroundTransparency=.1
label.TextColor3=Color3.fromRGB(230,201,132) label.Font=Enum.Font.GothamBold label.TextSize=18
label.BorderSizePixel=0 label.Parent=gui
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,10) corner.Parent=label
local connection
local function bind(c)
 pendingUntil=0
 if connection then connection:Disconnect() end
 local function update() label.Text="Coins: "..tostring(c:GetAttribute("Coins") or Rules.Capacity).." / "..Rules.Capacity end
 connection=c:GetAttributeChangedSignal("Coins"):Connect(update) update()
end
player.CharacterAdded:Connect(bind) if player.Character then bind(player.Character) end
local function updateRange() remote:FireServer("Range",motionScript:GetAttribute("AnchorRange") or 750) end
motionScript:GetAttributeChangedSignal("AnchorRange"):Connect(updateRange) updateRange()
UIS.InputBegan:Connect(function(input,processed)
 if processed or input.KeyCode~=Enum.KeyCode.R or UIS:GetFocusedTextBox() or GuiService.MenuIsOpen then return end
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid")
 local now=workspace:GetServerTimeNow()
 if not h or h.Health<=0 or now<pendingUntil or not Rules.CanToss(c:GetAttribute("Coins") or 0,c:GetAttribute("CoinActionStart"),now) then return end
 pendingUntil=now+Rules.Duration
 remote:FireServer("Toss")
end)
