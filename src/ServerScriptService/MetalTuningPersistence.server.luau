local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local store=game:GetService("DataStoreService"):GetDataStore("MistbornMetalTuning_v1")
local Config=require(ReplicatedStorage:WaitForChild("MetalTuningConfig"))
local remote=Instance.new("RemoteFunction")
remote.Name="MetalTuningPersistence"
local busy,lastSave,cache={},{},{}
remote.OnServerInvoke=function(player,action,payload)
 if action~="Load" and action~="Save" then return {ok=false,message="Unknown request"} end
 if busy[player] then return {ok=false,message="Please wait for the current request"} end
 local clean
 if action=="Save" then
  clean=Config.Validate(payload)
  if not clean then return {ok=false,message="Invalid settings; not saved"} end
  if lastSave[player] and os.clock()-lastSave[player]<5 then return {ok=false,message="Wait a few seconds, then save again"} end
 elseif cache[player] then
  return {ok=true,data=cache[player]}
 end
 busy[player]=true
 local key="player_"..tostring(player.UserId)
 local ok,result=pcall(function()
  if action=="Save" then
   lastSave[player]=os.clock()
   store:UpdateAsync(key,function() return clean end)
   return clean
  end
  return store:GetAsync(key)
 end)
 busy[player]=nil
 if not ok then
  warn("Metal tuning "..action.." failed: "..tostring(result))
  return {ok=false,message="Save service unavailable; retry"}
 end
 local data=result and Config.Validate(result)
 if result and not data then return {ok=false,message="Saved settings invalid; using project preset"} end
 if player.Parent then cache[player]=data end
 return {ok=true,data=data}
end
remote.Parent=ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)
 busy[player]=nil lastSave[player]=nil cache[player]=nil
end)
