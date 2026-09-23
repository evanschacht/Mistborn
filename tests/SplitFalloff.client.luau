local p=game.Players.LocalPlayer local c=require(game.ReplicatedStorage.MetalTuningConfig)
local s={AnchorRange=750,ForceNearClamp=5,ForceFarClamp=150,PullFalloff=0,PushFalloff=1}
assert(c.ForceScale(20,s,1)==1)
assert(c.ForceScale(20,s,-1)==.25)
s.PullFalloff=2 assert(c.ForceScale(20,s,-1)==.25)
assert(c.ForceScale(750,s,1)==0 and c.ForceScale(750,s,-1)==0)
local old=require(game.ReplicatedStorage.MetalTuningPreset)
old=table.clone(old) old.values=table.clone(old.values) old.ranges=table.clone(old.ranges)
old.values.PullFalloff=nil old.values.PushFalloff=nil old.ranges.PullFalloff=nil old.ranges.PushFalloff=nil
old.values.ForceFalloff=.35 old.ranges.ForceFalloff={0,7}
local migrated=c.Validate(old)
assert(migrated.values.PullFalloff==.35 and migrated.values.PushFalloff==.35)
assert(migrated.ranges.PushFalloff[2]==7 and migrated.ranges.PullFalloff[2]==7)
local rows=p.PlayerGui.MetalTuning.Panel.Content.Sliders
assert(rows.PullFalloff and rows.PushFalloff and not rows:FindFirstChild("ForceFalloff"))
return "Independent curves, shared cutoff, old-save migration and both UI controls passed"