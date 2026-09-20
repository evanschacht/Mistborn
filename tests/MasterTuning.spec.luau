local Master=require(game.ServerScriptService.MetalTuningMaster)
local Config=require(game.ReplicatedStorage.MetalTuningConfig)
local preset=require(game.ReplicatedStorage.MetalTuningPreset)
local record,writes,notifications=nil,0,0
local store={}
function store:GetAsync(key) assert(key=="master") return record end
function store:UpdateAsync(key,transform)
 assert(key=="master") writes+=1 record=transform(record) return record
end
local a=Master.new(store,Config.Validate,function() notifications+=1 end)
local b=Master.new(store,Config.Validate,function() notifications+=1 end)
assert(not a:Save(preset,false) and writes==0,"Unauthorized save wrote data")
assert(not a:Save({},true) and writes==0,"Invalid payload wrote data")
assert(a:Save(preset,true) and a.revision==1,"Master save failed")
assert(b:Load() and b.data.values.AnchorRange==290,"Other server did not load master")
local changed=Config.Validate(preset) changed.values.AnchorRange=400
assert(b:Save(changed,true) and b.revision==2,"Second revision failed")
assert(a:Load() and a.data.values.AnchorRange==400,"Existing server did not refresh")
a:Accept({revision=1,data=preset})
assert(a.data.values.AnchorRange==400,"Stale revision overwrote master")
function store:UpdateAsync() error("simulated service failure") end
assert(not a:Save(preset,true) and a.data.values.AnchorRange==400,"Failed save changed active master")
assert(notifications==4,"Unexpected master notifications")
return {passed=9,storage="in-memory test double",liveDataStore="requires Studio API access"}
