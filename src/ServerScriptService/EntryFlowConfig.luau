-- Tutorial uses a fresh reserved server of this same place, so no extra place
-- needs publishing. TeleportData carries routing hints, never gameplay rewards.
local Config = {
	ProtocolVersion = 1,
	ChoiceCooldown = 1,
	TeleportTimeout = 45,
	SpawnTimeout = 25,
	WorldTimeout = 15,
	RespawnRetries = 3,
	RespawnRetryBaseDelay = 2,
}

function Config.GetRespawnRetryDelay(failureCount)
	if failureCount < 1 or failureCount > Config.RespawnRetries then return nil end
	return Config.RespawnRetryBaseDelay * 2 ^ (failureCount - 1)
end

function Config.IsTutorialJoin(joinData, placeId, userId, isReserved)
	if not isReserved or type(joinData) ~= "table" or joinData.SourcePlaceId ~= placeId then
		return false
	end
	local data = joinData.TeleportData
	return type(data) == "table"
		and data.entryFlowVersion == Config.ProtocolVersion
		and data.mode == "Tutorial"
		and data.sourcePlaceId == placeId
		and data.userId == userId
		and type(data.requestId) == "string"
		and #data.requestId > 0
end

return Config
