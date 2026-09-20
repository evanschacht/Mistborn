local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local store=game:GetService("DataStoreService"):GetDataStore("MistbornMetalTuning_v1")
local Config=require(ReplicatedStorage:WaitForChild("MetalTuningConfig"))
local Master=require(script.Parent:WaitForChild("MetalTuningMaster"))
local state=Instance.new("StringValue")
state.Name="MetalTuningMasterState"
state.Value=HttpService:JSONEncode({revision=0,data=require(ReplicatedStorage.MetalTuningPreset)})
state.Parent=ReplicatedStorage
local master=Master.new(store,Config.Validate,function(record)
 state.Value=HttpService:JSONEncode(record)
end)
local function canSave(player)
 if RunService:IsStudio() then return true end
 if game.CreatorType==Enum.CreatorType.User then return player.UserId==game.CreatorId end
 local ok,rank=pcall(function() return player:GetRankInGroupAsync(game.CreatorId) end)
 return ok and rank==255
end
local remote=Instance.new("RemoteFunction")
remote.Name="MetalTuningPersistence"
local saving=false
local lastSave=-math.huge
remote.OnServerInvoke=function(player,action,payload)
 local allowed=canSave(player)
 if action=="Load" then
  local ok=master.data~=nil or master:Load()
  return {ok=ok,data=master.data,canSave=allowed}
 end
 if action~="Save" then return {ok=false,message="Unknown request"} end
 if not allowed then return {ok=false,message="Only the game owner can save master tuning"} end
 if saving or os.clock()-lastSave<5 then return {ok=false,message="Wait a few seconds, then save again"} end
 saving=true lastSave=os.clock()
 local ok,message=master:Save(payload,allowed)
 saving=false
 return {ok=ok,message=message}
end
remote.Parent=ReplicatedStorage
-- Replication updates this server immediately; other live servers refresh in about
-- 30 seconds. Revisions prevent a stale read from undoing a newer saved config.
task.spawn(function()
 while true do
  master:Load()
  task.wait(30)
 end
end)
