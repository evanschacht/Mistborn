local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Rules=require(RS:WaitForChild("CoinRules"))
local Config=require(RS:WaitForChild("MetalTuningConfig"))
local Asset=require(RS:WaitForChild("CoinPouchAsset"))
local preset=require(RS:WaitForChild("MetalTuningPreset"))
local CoinPhysics=require(script.Parent:WaitForChild("CoinPhysics"))
local remote=Instance.new("RemoteEvent") remote.Name="CoinToss" remote.Parent=RS
local anchors=workspace:WaitForChild("MetalAnchors")
local ranges,coins={},{}
local function build(c)
 local lower=c:WaitForChild("LowerTorso",10) or c:FindFirstChild("Torso")
 local hand=c:WaitForChild("RightHand",10) or c:FindFirstChild("Right Arm")
 if not lower or not hand or not c.Parent then return end
 local pouch=Instance.new("Model") pouch.Name="CoinPouch" pouch.Parent=c
 local scale=lower.Size.Y
 local base=CFrame.new(lower.Size.X*.48,-.12*scale,-lower.Size.Z*.5-.19)*CFrame.Angles(0,math.rad(-12),0)
 local opening=Instance.new("Attachment") opening.Name="PouchOpening" opening.CFrame=base*CFrame.new(0,.4*scale,0) opening.Parent=lower
 for _,spec in Asset do
  local part=Instance.new("Part") part.Name=spec.name
  local size=Vector3.new(table.unpack(spec.size))*scale
  local cf=base*CFrame.new(Vector3.new(table.unpack(spec.pos))*scale)*CFrame.Angles(table.unpack(spec.rot))
  if spec.shape=="Sphere" then part.Shape=Enum.PartType.Ball
  elseif spec.shape=="Cylinder" then part.Shape=Enum.PartType.Cylinder size=Vector3.new(size.Y,size.X,size.Z) cf*=CFrame.Angles(0,0,math.pi/2) end
  part.Size=size part.Color=Color3.fromHex(spec.color:sub(2))
  part.Material=spec.coin>0 and Enum.Material.Metal or Enum.Material.Leather
  part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Massless=true
  part.CFrame=lower.CFrame*cf part:SetAttribute("PouchCoinIndex",spec.coin) part.Parent=pouch
  local weld=Instance.new("WeldConstraint") weld.Part0=lower weld.Part1=part weld.Parent=part
 end
 local held=Instance.new("Part") held.Name="HeldCoin" held.Shape=Enum.PartType.Cylinder held.Size=Rules.Size*.65
 held.Color=Color3.fromRGB(198,152,54) held.Material=Enum.Material.Metal held.Transparency=1
 held.CanCollide=false held.CanTouch=false held.CanQuery=false held.Massless=true
 held.CFrame=hand.CFrame*CFrame.new(0,-hand.Size.Y*.5,-.1)*CFrame.Angles(0,0,math.pi/2) held.Parent=c
 local weld=Instance.new("WeldConstraint") weld.Part0=hand weld.Part1=held weld.Parent=held
 c:SetAttribute("Coins",Rules.Capacity)
 local function update()
  local count=c:GetAttribute("Coins") or 0
  for _,p in pouch:GetChildren() do if p:IsA("BasePart") then local i=p:GetAttribute("PouchCoinIndex") if i and i>0 then p.Transparency=i<=count and 0 or 1 end end end
 end
 c:GetAttributeChangedSignal("Coins"):Connect(update) update()
end
local function cleanup(player)
 for coin,owner in coins do if owner==player then coins[coin]=nil coin:Destroy() end end
end
local function setup(player)
 ranges[player]=preset.values.AnchorRange
 player.CharacterAdded:Connect(function(c) cleanup(player) build(c) end)
 if player.Character then task.spawn(build,player.Character) end
end
Players.PlayerAdded:Connect(setup)
for _,p in Players:GetPlayers() do setup(p) end
Players.PlayerRemoving:Connect(function(p) cleanup(p) ranges[p]=nil end)
remote.OnServerEvent:Connect(function(player,action,value)
 if action=="ReleaseReady" and typeof(value)=="table" then
  local coin,position=value.coin,value.position
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if typeof(coin)=="Instance" and coins[coin]==player and root and typeof(position)=="Vector3" and (position-root.Position).Magnitude<=32 then
   local velocity=value.velocity
   if typeof(velocity)~="Vector3" or not (velocity.Magnitude<100000) then return end
   CoinPhysics.ReleaseReady(coin,position,velocity)
  end
  return
 end
 if action=="Control" and typeof(value)=="table" then
  if typeof(value.coin)~="Instance" or not coins[value.coin] then return end
  local clean=value.settings and Config.Validate(value.settings)
  CoinPhysics.Control(player,value.coin,value.sign,clean and clean.values)
  return
 end
 if action=="Range" then
  if typeof(value)=="number" and value==value and value>=0 and value<=10000 then ranges[player]=value end
  return
 end
 if action~="Toss" then return end
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid") local root=c and c:FindFirstChild("HumanoidRootPart")
 if not h or h.Health<=0 or not root then return end
 local now=workspace:GetServerTimeNow()
 local count=c:GetAttribute("Coins") or 0
 if not Rules.CanToss(count,c:GetAttribute("CoinActionStart"),now) then return end
 c:SetAttribute("CoinActionStart",now)
 c:SetAttribute("Coins",count-1)
 local held=c:FindFirstChild("HeldCoin")
 task.delay(Rules.GrabTime,function()
  if held and held.Parent and player.Character==c and h.Health>0 then held.Transparency=0 end
 end)
 task.delay(Rules.ReleaseTime,function()
  if held and held.Parent then held.Transparency=1 end
  if player.Character~=c or not root.Parent or h.Health<=0 then return end
  local coin=Instance.new("Part") coin.Name="Coin_"..player.UserId.."_"..tostring(math.floor(now*1000))
  coin.Shape=Enum.PartType.Cylinder coin.Size=Rules.Size coin.Color=Color3.fromRGB(198,152,54) coin.Material=Enum.Material.Metal
  coin.CustomPhysicalProperties=PhysicalProperties.new(7.8,.65,0,100,100)
  coin:SetAttribute("IsCoin",true) coin:SetAttribute("CanMetalMove",true) coin:SetAttribute("CoinOwner",player.UserId)
  local dropPosition=root.Position-Vector3.yAxis
  coin.CFrame=CFrame.new(dropPosition)*CFrame.Angles(0,0,math.pi/2)
  coin.Parent=anchors
  for _,part in c:GetDescendants() do if part:IsA("BasePart") then
   local nc=Instance.new("NoCollisionConstraint") nc.Part0=coin nc.Part1=part nc.Parent=coin
  end end
  local gravityAttachment=Instance.new("Attachment") gravityAttachment.Parent=coin
  local gravityForce=Instance.new("VectorForce") gravityForce.Name="CoinGravity"
  gravityForce.Attachment0=gravityAttachment gravityForce.RelativeTo=Enum.ActuatorRelativeTo.World
  gravityForce.ApplyAtCenterOfMass=true
  gravityForce.Force=Vector3.new(0,-coin.AssemblyMass*workspace.Gravity*(Rules.FallSpeedScale^2-1),0)
  gravityForce.Parent=coin
  coin:SetNetworkOwner(player)
  -- Preserve character momentum, with a small extra downward release speed.
  coin.AssemblyLinearVelocity=root.AssemblyLinearVelocity+Vector3.new(0,-2*Rules.FallSpeedScale,0)
  coin.AssemblyAngularVelocity=Vector3.zero
  coins[coin]=player
  CoinPhysics.Register(coin)
  remote:FireClient(player,"Release",coin.Name)
 end)
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 CoinPhysics.Step(dt)
 elapsed+=dt if elapsed<.1 then return end elapsed=0
 for coin,owner in coins do
  local root=owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
  if not coin.Parent or not root or (coin.Position-root.Position).Magnitude>=Config.AnchorRangeForSize(coin.Size,ranges[owner] or 0) then
   coins[coin]=nil coin:Destroy()
  end
 end
end)
