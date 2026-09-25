local ps=game.Players.LocalPlayer.PlayerScripts
local pose=require(ps:WaitForChild("AerialFlightPose"))
local settings={AirPoseThreshold=30,AirPoseStartLean=30,AirPoseMaxLean=60,AirPoseFullSpeed=150}
assert(pose.Weight(30,settings)==0 and pose.Weight(30.1,settings)==1)
assert(pose.Lean(30,settings)==30 and pose.Lean(90,settings)==45 and pose.Lean(10000,settings)==60)
assert(pose.Lean(10000,{AirPoseStartLean=500,AirPoseMaxLean=1000})==80)
local config=require(game.ReplicatedStorage.MetalTuningConfig)
local preset=require(game.ReplicatedStorage.MetalTuningPreset)
local old={values=table.clone(preset.values),ranges=table.clone(preset.ranges),showSpeedometer=preset.showSpeedometer}
for _,key in {"AirPoseThreshold","AirPoseStartLean","AirPoseMaxLean","AirPoseFullSpeed"} do old.values[key]=nil old.ranges[key]=nil end
local migrated=config.Validate(old)
assert(migrated and migrated.values.AirPoseStartLean==30 and migrated.values.PullAcceleration==preset.values.PullAcceleration)
print("PASS: aerial pose threshold, lean interpolation, cap and legacy tuning migration")
