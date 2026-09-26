local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.MetalTuningConfig)
local Rules=require(game.ReplicatedStorage.CoinRules)
local Physics={}
local states={}
local tuning={}
function Physics.SetTuning(player,settings) tuning[player.UserId]=settings end
Players.PlayerRemoving:Connect(function(player) tuning[player.UserId]=nil end)
function Physics.Register(coin)
 states[coin]={controls={},ready=os.clock()+2,grounded=false,released=false}
 coin:SetAttribute("CoinState","Falling")
end
function Physics.ReleaseReady(coin,position,velocity)
 local state=states[coin]
 if not state or state.released then return end
 state.released=true state.ready=0 state.grounded=false state.supportNormal=nil
 coin:SetAttribute("CoinContactCFrame",nil)
 coin.CFrame=CFrame.new(position)*CFrame.Angles(0,0,math.pi/2)
 coin.Anchored=false
 coin:SetNetworkOwner(nil)
 coin.CanCollide=true coin.Transparency=0
 local v=velocity or coin:GetAttribute("ReleaseVelocity") or Vector3.zero
 coin.AssemblyLinearVelocity=Vector3.new(v.X,math.min(v.Y,-2*Rules.FallSpeedScale),v.Z)
 coin.AssemblyAngularVelocity=Vector3.zero
 coin:SetNetworkOwner(nil)
end
local function extent(coin,direction)
 local d=coin.CFrame:VectorToObjectSpace(direction)
 local half=coin.Size*.5
 return math.abs(d.X)*half.X+math.abs(d.Y)*half.Y+math.abs(d.Z)*half.Z
end
local function contact(coin,direction,params)
 return workspace:Raycast(coin.Position,direction*(extent(coin,direction)+.025),params)
end
function Physics.Control(player,coin,sign,settings)
 local state=states[coin]
 if not state or (sign~=1 and sign~=-1) then return end
 if not settings then
  local old=state.controls[sign]
  if old and old.player==player then state.controls[sign]=nil end
  return
 end
 state.controls[sign]={player=player,settings=settings,expires=os.clock()+.6}
end
local function queryParams()
 local list={}
 for coin in states do table.insert(list,coin) end
 for _,p in Players:GetPlayers() do if p.Character then table.insert(list,p.Character) end end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=list
 params.RespectCanCollide=true
 return params
end
function Physics.Step(dt)
 local params=queryParams()
 for coin,state in states do
  if not coin.Parent then states[coin]=nil continue end
  if not state.released then
   if os.clock()<state.ready then continue end
   Physics.ReleaseReady(coin,coin.Position)
  end
  for sign,control in state.controls do
   local c=control.player.Character
   local root=c and c:FindFirstChild("HumanoidRootPart")
   local h=c and c:FindFirstChildOfClass("Humanoid")
   if not root or not h or h.Health<=0 or os.clock()>control.expires or (root.Position-coin.Position).Magnitude>=Config.AnchorRangeForSize(coin.Size,control.settings.AnchorRange) then
    state.controls[sign]=nil
   else control.root=root end
  end
  local pull,push=state.controls[1],state.controls[-1]
  local control=pull or push
  local gravity=coin:FindFirstChild("CoinGravity")
  local thrust=coin:FindFirstChild("CoinThrust")
  if not thrust then
   thrust=Instance.new("VectorForce") thrust.Name="CoinThrust"
   thrust.Attachment0=gravity.Attachment0 thrust.RelativeTo=Enum.ActuatorRelativeTo.World
   thrust.ApplyAtCenterOfMass=true thrust.Parent=coin
  end
  thrust.Force=Vector3.zero
  coin:SetAttribute("CoinPushReaction",0)
  coin:SetAttribute("CoinPullReaction",0)
  local settings=control and control.settings or tuning[coin:GetAttribute("CoinOwner")] or require(game.ReplicatedStorage.MetalTuningPreset).values
  local g=settings.Gravity
  gravity.Force=Vector3.new(0,-coin:GetMass()*(g*Rules.FallSpeedScale^2-workspace.Gravity),0)
  if pull then
   state.grounded=false
   local delta=pull.root.Position-coin.Position
   local direction=delta.Magnitude>.001 and delta.Unit or Vector3.yAxis
   -- Check actual contact ahead, not a distant obstacle along the whole path.
   local hit=contact(coin,direction,params)
   local blocked=hit~=nil
   if delta.Magnitude<=3.5 and not workspace:Raycast(coin.Position,delta,params) then
    local c=pull.player.Character
    c:SetAttribute("Coins",math.min(Rules.Capacity,(c:GetAttribute("Coins") or 0)+1))
    coin:Destroy() states[coin]=nil continue
   end
   if blocked then
    coin:SetAttribute("CoinContactCFrame",coin.CFrame)
    coin.Anchored=true
    coin:SetAttribute("CoinState","Blocked")
    coin:SetAttribute("CoinPullReaction",pull.player.UserId)
    continue
   end
   if coin.Anchored then coin.Anchored=false coin:SetNetworkOwner(nil) end
   coin:SetAttribute("CoinContactCFrame",nil)
   coin:SetAttribute("CoinState","Pulling")
  else
   -- Revalidate support every frame: moving/deleted surfaces and corrected
   -- release positions must never leave a coin anchored in empty air.
   if state.grounded then
    local support=state.supportNormal and contact(coin,-state.supportNormal,params)
    if not support then state.grounded=false state.supportNormal=nil end
   end
   if not state.grounded then
    local hit
    if coin.AssemblyLinearVelocity.Y<=1 then hit=contact(coin,-Vector3.yAxis,params) end
    if not hit and push then
     local away=coin.Position-push.root.Position
     if away.Magnitude>.001 then hit=contact(coin,away.Unit,params) end
    end
    if hit then state.grounded=true state.supportNormal=hit.Normal end
   end
   if state.grounded then
    coin.AssemblyLinearVelocity=Vector3.zero coin.AssemblyAngularVelocity=Vector3.zero
    coin:SetAttribute("CoinContactCFrame",coin.CFrame)
    coin.Anchored=true coin:SetAttribute("CoinState","Grounded")
    if push then coin:SetAttribute("CoinPushReaction",push.player.UserId) end
    continue
   end
   if coin.Anchored then coin.Anchored=false coin:SetNetworkOwner(nil) end
   coin:SetAttribute("CoinContactCFrame",nil)
   coin:SetAttribute("CoinState",push and "Pushed" or "Falling")
  end
  local velocity=coin.AssemblyLinearVelocity
  local drag=(1-math.exp(-(settings.CoinAirDrag or 1.2)*dt))/math.max(dt,.001)
  local acceleration=-Vector3.new(velocity.X,0,velocity.Z)*drag
  for sign,action in state.controls do
   local delta=action.root.Position-coin.Position
   if delta.Magnitude>.01 then
    local direction=delta.Unit*sign
    local s=action.settings
    local strength=sign==1 and s.PullAcceleration or s.PushAcceleration
    strength*=Config.ForceScale(delta.Magnitude,s,sign,Config.AnchorRangeForSize(coin.Size,s.AnchorRange))
    local speed=sign==1 and s.PullSpeed or s.PushSpeed
    local along=coin.AssemblyLinearVelocity:Dot(direction)
    acceleration+=direction*math.min(strength,math.max(0,speed-along)/math.max(dt,.001))
   end
  end
  thrust.Force=acceleration*coin:GetMass()
 end
end
return Physics
