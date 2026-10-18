-- Run as a temporary server Script in Play, after EntryFlow is installed.
-- Pure admission validation; this test does not spawn or teleport players.
local Config = require(game:GetService("ServerScriptService"):WaitForChild("EntryFlowConfig"))
local function valid()
	return {
		SourcePlaceId = 123,
		TeleportData = {
			entryFlowVersion = Config.ProtocolVersion,
			mode = "Tutorial",
			sourcePlaceId = 123,
			userId = 456,
			requestId = "test-request",
		},
	}
end
assert(Config.IsTutorialJoin(valid(), 123, 456, true), "Reserved same-place arrival must admit")
assert(not Config.IsTutorialJoin(valid(), 123, 456, false), "Public/VIP server must reject")
assert(not Config.IsTutorialJoin(valid(), 999, 456, true), "Cross-place arrival must reject")
assert(not Config.IsTutorialJoin(valid(), 123, 999, true), "Different user must reject")
for _, malformed in { false, "Tutorial", 12 } do
	assert(not Config.IsTutorialJoin(malformed, 123, 456, true), "Malformed join data must reject")
end
for key, replacement in {
	entryFlowVersion = -1,
	mode = "Dev",
	sourcePlaceId = -1,
	userId = -1,
	requestId = "",
} do
	local data = valid()
	data.TeleportData[key] = replacement
	assert(not Config.IsTutorialJoin(data, 123, 456, true), "Invalid " .. key .. " must reject")
end
local data = valid()
data.TeleportData = nil
assert(not Config.IsTutorialJoin(data, 123, 456, true), "Missing TeleportData must reject")
assert(not Config.IsTutorialJoin(nil, 123, 456, true), "Missing join data must reject")
assert(Config.GetRespawnRetryDelay(1) == 2, "First respawn retry must wait two seconds")
assert(Config.GetRespawnRetryDelay(2) == 4, "Second respawn retry must back off")
assert(Config.GetRespawnRetryDelay(3) == 8, "Third respawn retry must back off")
assert(Config.GetRespawnRetryDelay(4) == nil, "Respawn retries must terminate")
assert(Config.GetRespawnRetryDelay(0) == nil, "An unfailed spawn must not schedule a retry")
print("EntryFlowJoinValidation=PASS")
