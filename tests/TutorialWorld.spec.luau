-- Run in the Studio SERVER command bar after installing ServerStorage.TutorialWorld.
-- Builds in an unparented Folder: leaves the live map and tuning untouched.
local TutorialWorld = require(game:GetService("ServerStorage"):WaitForChild("TutorialWorld"))
local fixture = Instance.new("Folder")
local anchors = Instance.new("Folder")
anchors.Name = "MetalAnchors"
anchors.Parent = fixture
local marker = Instance.new("Part")
marker.Parent = anchors
local ok, problem = pcall(function()
	local root, spawn = TutorialWorld.Build(fixture)
	assert(root.Parent == fixture and root.Name == "TutorialWorld", "Missing tutorial root")
	assert(#root:GetChildren() == 3, "Expected exactly baseplate, wall, spawn")
	assert(spawn:IsA("SpawnLocation") and spawn:IsDescendantOf(root), "Missing spawn")
	assert(spawn.Neutral and spawn.Enabled and spawn.Duration == 0, "Invalid tutorial spawn")
	assert(spawn.CFrame.LookVector:Dot(Vector3.new(0, 0, -1)) > .999, "Spawn must face wall")
	assert(spawn.Position == Vector3.new(0, .5, 120), "Spawn must be unobstructed at the approach")
	local ground = root:FindFirstChild("Baseplate") :: Part
	assert(ground.Position.Y + ground.Size.Y / 2 == 0, "Baseplate surface must be y=0")
	assert(ground.Size == Vector3.new(720, 8, 720), "Unexpected baseplate size")
	local wall = root:FindFirstChild("MedievalStoneWall") :: Model
	local count, collisions = 0, 0
	local min, max = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, descendant in wall:GetDescendants() do
		if descendant:IsA("BasePart") then
			count += 1
			if descendant.CanCollide then collisions += 1 end
			assert(descendant.Anchored, "Every wall piece must stay anchored")
			assert(descendant:GetAttribute("CanMetalMove") == false, "Wall must be nonmetal")
			assert(descendant:GetAttribute("IsMetal") == false, "Wall must be nonmetal")
			assert(not descendant.CanTouch and descendant.CanQuery == descendant.CanCollide, "Unexpected physics flags")
			min = min:Min(descendant.Position - descendant.Size / 2)
			max = max:Max(descendant.Position + descendant.Size / 2)
		end
	end
	assert(count == 1074 and collisions == 141, "Wall part budget changed")
	assert(math.abs((max-min).X - 300) < .01 and math.abs((max-min).Y - 100) < .01, "Wall must be REALLY BIG")
	assert(math.abs(min.Y) < .01 and max.Z < -60, "Wall must sit on the baseplate away from spawn")
	assert(fixture:FindFirstChild("MetalAnchors") == anchors and marker.Parent == anchors, "Builder must preserve anchors")
	print("TutorialWorld=PASS parts=" .. count .. " collisions=" .. collisions .. " size=" .. tostring(max-min))
end)
fixture:Destroy()
assert(ok, problem)
