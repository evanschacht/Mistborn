local Players = game:GetService("Players")
-- Set this before requiring modules or yielding: entry is explicitly admitted.
Players.CharacterAutoLoads = false

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(script.Parent:WaitForChild("EntryFlowConfig"))

local remotes = Instance.new("Folder")
remotes.Name = "EntryFlow"
local chooseMode = Instance.new("RemoteEvent")
chooseMode.Name = "ChooseMode"
chooseMode.Parent = remotes
local status = Instance.new("RemoteEvent")
status.Name = "Status"
status.Parent = remotes
remotes.Parent = ReplicatedStorage

local states = {}
local worldState = "Dev"
local worldError
local devWasAdmitted = false
local worldChanged = Instance.new("BindableEvent")
workspace:SetAttribute("WorldMode", "Dev")

local function send(player, stateName, message)
	local state = states[player]
	if not state or player.Parent ~= Players then return end
	state.status, state.message = stateName, message or ""
	status:FireClient(player, stateName, state.message)
end

local function alive(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart")
end

local function buildTutorial()
	if worldState == "Building" then
		repeat worldChanged.Event:Wait() until worldState ~= "Building"
	end
	if worldState == "Tutorial" then return true end
	if worldState == "Failed" then return false, worldError end
	if devWasAdmitted then return false, "Dev Mode is already running in this server." end
	worldState = "Building"
	worldError = nil

	-- Preserve the anchor Folder identity: existing coin scripts hold a reference.
	-- Construct off-world before touching the current map; retain old instances
	-- through the final swap so a failed Studio preview can recover as well.
	local anchors = workspace:FindFirstChild("MetalAnchors")
	if not anchors then
		anchors = Instance.new("Folder")
		anchors.Name = "MetalAnchors"
		anchors.Parent = workspace
	end
	local backup = Instance.new("Folder")
	backup.Name = "EntryFlowWorldBackup"
	backup.Parent = ServerStorage
	local anchorBackup = Instance.new("Folder")
	anchorBackup.Name = "Anchors"
	anchorBackup.Parent = backup
	local staging = Instance.new("Folder")
	staging.Name = "EntryFlowTutorialStaging"
	staging.Parent = ServerStorage
	local original = {}
	local previousChildren = {}
	for _, child in workspace:GetChildren() do previousChildren[child] = true end
	local ok, result = pcall(function()
		local module = ServerStorage:WaitForChild("TutorialWorld", Config.WorldTimeout)
		assert(module and module:IsA("ModuleScript"), "TutorialWorld module is missing")
		local builder = require(module)
		assert(type(builder) == "table" and type(builder.Build) == "function", "Invalid TutorialWorld module")
		local root, spawn = builder.Build(staging)
		assert(root and root:IsDescendantOf(staging), "TutorialWorld did not create a map")
		assert(spawn and spawn:IsA("SpawnLocation") and spawn:IsDescendantOf(root), "Tutorial spawn is missing")
		for _, child in workspace:GetChildren() do
			if child ~= workspace.Terrain and not child:IsA("Camera") and child ~= anchors then
				original[child] = true
				child.Parent = backup
			end
		end
		for _, child in anchors:GetChildren() do child.Parent = anchorBackup end
		root.Parent = workspace
		workspace.Terrain:Clear()
	end)
	staging:Destroy()
	if ok then
		backup:Destroy()
		worldState = "Tutorial"
		workspace:SetAttribute("WorldMode", "Tutorial")
		workspace:SetAttribute("TutorialStudioPreview", RunService:IsStudio())
	else
		for _, child in workspace:GetChildren() do
			if not previousChildren[child] then child:Destroy() end
		end
		for child in original do child.Parent = workspace end
		for _, child in anchorBackup:GetChildren() do child.Parent = anchors end
		backup:Destroy()
		worldError = "The tutorial map could not load. Rejoin and try again."
		-- Production remains closed to avoid racing another tutorial arrival.
		-- Studio can retry the preview or enter the restored development map.
		worldState = RunService:IsStudio() and "Dev" or "Failed"
		warn("EntryFlow tutorial build failed:", result)
	end
	worldChanged:Fire()
	return ok, worldError
end

local spawnCharacter
local function characterUnavailable(player, state)
	if states[player] ~= state or state.terminating then return end
	state.terminating = true
	state.busy = false
	player:Kick("Your character is unavailable right now. Please rejoin to try again.")
end

local function retryRespawn(player, state)
	state.spawnFailures = (state.spawnFailures or 0) + 1
	state.respawnRequested = false
	local delay = Config.GetRespawnRetryDelay(state.spawnFailures)
	if not delay then
		characterUnavailable(player, state)
		return
	end
	state.respawnRetryPending = true
	task.delay(delay, function()
		if states[player] ~= state or state.terminating then return end
		state.respawnRetryPending = false
		if not alive(player) then spawnCharacter(player) end
	end)
end

spawnCharacter = function(player)
	local state = states[player]
	if not state or not state.mode or state.terminating then return end
	if state.spawnInFlight then
		if state.hasEntered then
			state.respawnRequested = true
		else
			send(player, "Error", "Your character is still loading. Wait a moment, then try again.")
		end
		return
	end
	if state.busy or state.respawnRetryPending then return end
	state.busy = true
	state.spawnToken = (state.spawnToken or 0) + 1
	local token = state.spawnToken
	state.spawnInFlight = token
	send(player, "Loading", "Spawning...")
	local function finish(ok, detail)
		if states[player] ~= state or state.spawnInFlight ~= token or state.terminating then return end
		state.spawnInFlight = nil
		state.busy = false
		if ok and alive(player) then
			state.hasEntered = true
			state.spawnFailures = 0
			state.respawnRequested = false
			send(player, "Entered", state.mode)
		else
			warn("EntryFlow character spawn failed:", detail)
			if state.hasEntered then
				retryRespawn(player, state)
			else
				send(player, "Error", "Your character could not load. Choose your mode again to retry.")
			end
		end
	end
	task.delay(Config.SpawnTimeout, function()
		if states[player] ~= state or state.spawnInFlight ~= token then return end
		-- LoadCharacterAsync cannot be cancelled. Keep its flight token until it
		-- returns so retries cannot overlap a slow original avatar request.
		state.busy = false
		if state.hasEntered then
			-- The entry menu is already gone. An unresolved engine request cannot
			-- safely be retried, so provide a clear finite recovery path instead.
			characterUnavailable(player, state)
		else
			send(player, "Error", "Your character is taking too long to load. Wait a moment, then try again.")
		end
	end)
	task.spawn(function()
		local ok, detail = pcall(function() player:LoadCharacterAsync() end)
		finish(ok, detail)
	end)
end

local function admit(player, mode)
	local state = states[player]
	if not state or player.Parent ~= Players then return end
	state.mode = mode
	if mode == "Dev" then devWasAdmitted = true end
	player:SetAttribute("EntryMode", mode)
	state.busy = false
	spawnCharacter(player)
end

local function enterTutorial(player)
	local state = states[player]
	if not state then return end
	state.busy = true
	send(player, "Loading", "Preparing tutorial...")
	local ok, message = buildTutorial()
	if states[player] ~= state then return end
	state.busy = false
	if ok then admit(player, "Tutorial") else send(player, "Error", message) end
end

local function failTeleport(player, requestId, detail)
	local state = states[player]
	if type(requestId) ~= "string" or not state or state.teleportRequest ~= requestId then return end
	state.teleportRequest = nil
	if state.teleportInFlight == requestId then state.teleportInFlight = nil end
	state.busy = false
	warn("EntryFlow tutorial teleport failed:", detail)
	send(player, "Error", "Could not join the tutorial server. Please try again, or choose Dev Mode.")
end

local function teleportTutorial(player)
	local state = states[player]
	local requestId = HttpService:GenerateGUID(false)
	state.teleportRequest = requestId
	state.teleportInFlight = requestId
	state.busy = true
	send(player, "Loading", "Joining your tutorial server...")
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	options:SetTeleportData({
		entryFlowVersion = Config.ProtocolVersion,
		mode = "Tutorial",
		userId = player.UserId,
		sourcePlaceId = game.PlaceId,
		requestId = requestId,
	})
	task.delay(Config.TeleportTimeout, function()
		if states[player] ~= state or state.teleportRequest ~= requestId then return end
		-- TeleportAsync can return before travel completes; Roblox offers no
		-- cancellation. Preserve the pending transfer until explicit failure or
		-- departure so a late transfer cannot race a new choice or a Dev spawn.
		state.busy = false
		warn("EntryFlow tutorial transfer is still pending after timeout")
		send(player, "Error", "The tutorial connection is taking too long. Please rejoin before choosing a mode again.")
	end)
	task.spawn(function()
		local ok, detail = pcall(function() TeleportService:TeleportAsync(game.PlaceId, { player }, options) end)
		if states[player] == state and state.teleportInFlight == requestId then state.teleportInFlight = nil end
		if not ok then failTeleport(player, requestId, detail) end
	end)
end

TeleportService.TeleportInitFailed:Connect(function(player, _, message, placeId, options)
	if placeId ~= game.PlaceId or not options then return end
	local ok, data = pcall(function() return options:GetTeleportData() end)
	if ok and type(data) == "table" then failTeleport(player, data.requestId, message) end
end)

local function setup(player)
	if states[player] then return end
	local state = { busy = false, lastChoice = -math.huge, lastReady = -math.huge }
	states[player] = state
	player:SetAttribute("EntryMode", nil)
	local ok, joinData = pcall(function() return player:GetJoinData() end)
	state.tutorialArrival = ok and Config.IsTutorialJoin(joinData, game.PlaceId, player.UserId,
		game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)
	player.CharacterAdded:Connect(function(character)
		if not state.mode then
			-- Also covers an external script accidentally loading a menu player's character.
			task.defer(function() if character.Parent then character:Destroy() end end)
			return
		end
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then return end
		humanoid.Died:Connect(function()
			task.delay(Players.RespawnTime, function()
				if states[player] == state and player.Character == character then
					state.respawnRequested = true
					-- The pending load's completion handles this dead character;
					-- never overlap LoadCharacterAsync or discard the respawn request.
					if not state.spawnInFlight then spawnCharacter(player) end
				end
			end)
		end)
	end)
	if player.Character then player.Character:Destroy() end
	if state.tutorialArrival then
		state.busy = true
		send(player, "Loading", "Preparing tutorial...")
		task.spawn(enterTutorial, player)
	else
		send(player, "Ready", "Choose a mode.")
	end
end

chooseMode.OnServerEvent:Connect(function(player, mode)
	local state = states[player]
	if not state or type(mode) ~= "string" then return end
	if mode == "Ready" then
		if os.clock() - state.lastReady < 0.5 then return end
		state.lastReady = os.clock()
		send(player, state.status or "Ready", state.message)
		return
	end
	if mode ~= "Dev" and mode ~= "Tutorial" then return end
	if state.busy then return end
	local cooldown = Config.ChoiceCooldown - (os.clock() - state.lastChoice)
	if cooldown > 0 then
		-- A valid client disables its buttons before sending; silently dropping
		-- a quick retry would strand that UI. Coalesce spam into one reply.
		if not state.cooldownReplyPending then
			state.cooldownReplyPending = true
			task.delay(cooldown, function()
				if states[player] ~= state then return end
				state.cooldownReplyPending = false
				send(player, state.status or "Ready", state.message)
			end)
		end
		return
	end
	state.lastChoice = os.clock()
	if state.mode then
		if mode ~= state.mode then
			send(player, "Error", "Rejoin to choose a different mode.")
		elseif alive(player) then
			send(player, "Entered", state.mode)
		else
			spawnCharacter(player)
		end
		return
	end
	if state.teleportRequest then
		send(player, "Error", "Your tutorial connection is still pending. Please rejoin to choose a mode again.")
		return
	end
	if worldState == "Building" or worldState == "Failed" then
		send(player, "Error", worldError or "This server is preparing its tutorial. Please wait.")
		return
	end
	if mode == "Dev" then
		if worldState ~= "Dev" then
			send(player, "Error", "This is a tutorial server. Choose Tutorial Level or rejoin for Dev Mode.")
		else
			admit(player, "Dev")
		end
	elseif worldState == "Tutorial" then
		enterTutorial(player)
	elseif RunService:IsStudio() then
		if devWasAdmitted or #Players:GetPlayers() ~= 1 then
			send(player, "Error", "Studio preview needs a fresh single-player test. Stop Play, then test Tutorial Level first.")
		else
			enterTutorial(player)
		end
	elseif game.PlaceId <= 0 then
		send(player, "Error", "Publish this place before testing tutorial server travel.")
	else
		teleportTutorial(player)
	end
end)

Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do setup(player) end
