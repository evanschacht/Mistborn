local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS:WaitForChild("AllomancyConfig"))
local remote=RS:WaitForChild("AllomancyBoost")
local states={}
local connections={}
local function disconnect(state)
 if state.character then state.character:Disconnect() end
 if state.landing then state.landing:Disconnect() end
end
local function bind(player,character)
 local state=states[player]
 if not state then return end
 if state.landing then state.landing:Disconnect() end
 state.used=false
 local h=character:WaitForChild("Humanoid",10)
 if not h or states[player]~=state or player.Character~=character then return end
 state.landing=h.StateChanged:Connect(function(_,nextState)
  if nextState==Enum.HumanoidStateType.Landed or nextState==Enum.HumanoidStateType.Running then state.used=false end
 end)
end
local function add(player)
 local state={last=-math.huge,lastRequest=-math.huge,used=false}
 states[player]=state
 state.character=player.CharacterAdded:Connect(function(c) bind(player,c) end)
 if player.Character then task.spawn(bind,player,player.Character) end
end
table.insert(connections,Players.PlayerAdded:Connect(add))
table.insert(connections,Players.PlayerRemoving:Connect(function(player)
 local state=states[player]
 if state then disconnect(state) end
 states[player]=nil
end))
for _,p in Players:GetPlayers() do add(p) end
table.insert(connections,remote.OnServerEvent:Connect(function(player,key,forward)
 local state=states[player] if not state then return end
 local now=os.clock()
 if now-state.lastRequest<0.08 then remote:FireClient(player,false) return end
 state.lastRequest=now
 local c=player.Character local h=c and c:FindFirstChildOfClass("Humanoid") local r=c and c:FindFirstChild("HumanoidRootPart")
 if not h or not r or h.Health<=0 or h.FloorMaterial~=Enum.Material.Air
  or now-state.last<Config.AirBoostCooldown or (Config.OneBoostPerAirtime and state.used)
  or (key~="W" and key~="A" and key~="S" and key~="D") or typeof(forward)~="Vector3"
  or forward.X~=forward.X or forward.Z~=forward.Z or math.abs(forward.X)>2 or math.abs(forward.Z)>2 then
  remote:FireClient(player,false) return
 end
 forward=Vector3.new(forward.X,0,forward.Z)
 if forward.Magnitude<0.1 then remote:FireClient(player,false) return end
 forward=forward.Unit local right=forward:Cross(Vector3.yAxis)
 local direction=key=="W" and forward or key=="S" and -forward or key=="A" and -right or right
 local velocity=r.AssemblyLinearVelocity
 local horizontal=Vector3.new(velocity.X,0,velocity.Z)
 local addition=direction*Config.AirBoostSpeed
 if horizontal.Magnitude>=Config.MaximumHorizontalSpeed then
  local axis=horizontal.Unit addition-=axis*math.max(addition:Dot(axis),0)
 end
 state.last=now state.used=true
 -- The owning client applies only this server-approved, fixed-size impulse.
 remote:FireClient(player,true,addition+Vector3.yAxis*Config.AirBoostUpwardSpeed)
end))
script.Destroying:Connect(function()
 for _,connection in connections do connection:Disconnect() end
 for _,state in states do disconnect(state) end
 table.clear(states)
end)
