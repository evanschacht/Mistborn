-- One continuous gravity value for ordinary jumps and metal-powered flight.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.MetalTuningConfig)
workspace.Gravity=Config.Validate(require(ReplicatedStorage.MetalTuningPreset)).values.Gravity
task.spawn(function()
 local state=ReplicatedStorage:WaitForChild("MetalTuningMasterState")
 local function apply()
  local ok,record=pcall(function() return game:GetService("HttpService"):JSONDecode(state.Value) end)
  local data=ok and Config.Validate(record.data)
  if data then workspace.Gravity=data.values.Gravity end
 end
 state.Changed:Connect(apply) apply()
end)
local function characterAdded(character)
 local h=character:WaitForChild("Humanoid")
 h.UseJumpPower=false
 h.JumpHeight=8
end
local function playerAdded(player)
 player.CharacterAdded:Connect(characterAdded)
 if player.Character then task.spawn(characterAdded,player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _,player in Players:GetPlayers() do playerAdded(player) end
