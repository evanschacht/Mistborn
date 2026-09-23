-- One continuous gravity value for ordinary jumps and metal-powered flight.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.MetalTuningConfig)
local current=Config.Validate(require(ReplicatedStorage.MetalTuningPreset)).values
workspace.Gravity=current.Gravity
task.spawn(function()
 local state=ReplicatedStorage:WaitForChild("MetalTuningMasterState")
 local function apply()
  local ok,record=pcall(function() return game:GetService("HttpService"):JSONDecode(state.Value) end)
  local data=ok and Config.Validate(record.data)
  if data then
   current=data.values workspace.Gravity=current.Gravity
   for _,p in Players:GetPlayers() do
    local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if h then h.UseJumpPower=false h.JumpHeight=current.JumpStrength end
   end
  end
 end
 state.Changed:Connect(apply) apply()
end)
local function characterAdded(character)
 local h=character:WaitForChild("Humanoid")
 h.UseJumpPower=false
 h.JumpHeight=current.JumpStrength
end
local function playerAdded(player)
 player.CharacterAdded:Connect(characterAdded)
 if player.Character then task.spawn(characterAdded,player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _,player in Players:GetPlayers() do playerAdded(player) end
