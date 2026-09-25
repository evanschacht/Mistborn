local c=require(game.ReplicatedStorage.MetalTuningConfig)
assert(math.abs(c.AnchorRangeForSize(Vector3.one*3,100)-50)<.001)
assert(math.abs(c.AnchorRangeForSize(Vector3.one*6,100)-100)<.001)
assert(math.abs(c.AnchorRangeForSize(Vector3.one*12,100)-200)<.001)
assert(c.AnchorRangeForSize(Vector3.one*12,0)==0)
local s={AnchorRange=100,ForceNearClamp=5,ForceFarClamp=150,PullFalloff=1,PushFalloff=1}
for _,sign in {-1,1} do
 assert(c.ForceScale(150,s,sign,200)>0)
 assert(c.ForceScale(50,s,sign,50)==0)
end
local near,t=c.LineStyle(Vector3.one*6,10,100)
local far,f=c.LineStyle(Vector3.one*6,90,100)
assert(near>far and t<f)
assert(c.LineStyle(Vector3.one*12,10,100)>near)
print("PASS: size ranges, both force cutoffs, near/far line style")
