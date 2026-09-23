-- One continuous gravity value for ordinary jumps and metal-powered flight.
local Players=game:GetService("Players")
workspace.Gravity=60
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
