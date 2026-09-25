local Config={}
Config.Specs={
 {key="AirPoseThreshold",title="Flight pose start speed",min=0,max=300,step=1,default=30,unit=" studs/s",hint="Horizontal speed above which the flight pose blends in."},
 {key="AirPoseStartLean",title="Flight pose starting lean",min=0,max=80,step=1,default=30,unit=" degrees",hint="Forward lean at the flight pose threshold."},
 {key="AirPoseMaxLean",title="Flight pose maximum lean",min=0,max=80,step=1,default=60,unit=" degrees",hint="Maximum forward lean; never less than starting lean. Hard safety limit 80 degrees."},
 {key="AirPoseFullSpeed",title="Flight pose full lean speed",min=0,max=500,step=1,default=150,unit=" studs/s",hint="Horizontal speed reaching maximum lean; must exceed start speed."},
 {key="SlideWAcceleration",title="Slide W acceleration",min=0,max=200,step=1,default=25,unit=" studs/s^2",hint="Extra W acceleration while pushing/pulling. Coasting W only halves slide friction."},
 {key="SlideWTopSpeed",title="Slide W top speed",min=0,max=500,step=5,default=200,unit=" studs/s",hint="W boost limit; does not slow faster inherited momentum."},
 {key="SlideSMinSpeed",title="Slide S minimum speed",min=0,max=200,step=1,default=30,unit=" studs/s",hint="S brakes down to this speed; never accelerates you up to it. 0 allows stopping."},
 {key="SlideBraking",title="Slide S braking",min=0,max=1000,step=5,default=120,unit=" studs/s^2",hint="How quickly S slows you toward its minimum speed."},
 {key="SlideLeftSteering",title="Slide A steering",min=0,max=360,step=5,default=65,unit=" deg/s",hint="Left turn rate relative to slide direction."},
 {key="SlideRightSteering",title="Slide D steering",min=0,max=360,step=5,default=65,unit=" deg/s",hint="Right turn rate relative to slide direction."},
 {key="GroundSpeed",title="Ground walking speed",min=0,max=100,step=1,default=16,unit=" studs/s",hint="Walking speed only; separate from air and metal sliding."},
 {key="GroundAcceleration",title="Ground walking acceleration",min=0,max=500,step=5,default=100,unit=" studs/s�",hint="How quickly walking builds speed."},
 {key="AirSpeed",title="Aerial movement speed",min=0,max=200,step=1,default=64,unit=" studs/s",hint="Speed added by WASD in the air; preserves faster metal momentum."},
 {key="AirAcceleration",title="Aerial acceleration",min=0,max=1000,step=5,default=240,unit=" studs/s�",hint="How quickly airborne WASD changes your movement."},
 {key="AirDrag",title="Air drag",min=0,max=8,step=0.05,default=0.15,unit="",hint="Horizontal resistance while airborne with WASD released. 0 = no drag."},
 {key="JumpStrength",title="Jump strength",min=0,max=50,step=0.5,default=8,unit=" studs",hint="Height of an ordinary jump. 0 disables jumping."},
 {key="Gravity",title="Gravity",min=0,max=400,step=1,default=60,unit=" studs/s�",hint="Continuous downward acceleration, including metal flight."},
 {key="AnchorRange",title="Steel and iron range",min=0,max=500,step=1,default=180,unit=" studs",hint="Reach of blue lines, selection and push/pull, in studs."},
 {key="PullFalloff",title="Pull force falloff",min=0,max=5,step=0.05,default=1,unit="",hint="0 = constant; 1 = inverse-linear; higher = faster weakening."},
 {key="PushFalloff",title="Push force falloff",min=0,max=5,step=0.05,default=1,unit="",hint="0 = constant; 1 = inverse-linear; higher = faster weakening."},
 {key="ForceNearClamp",title="Close clamp distance",min=0.1,max=50,step=0.1,default=5,unit=" studs",hint="Full force inside this distance. Cannot spike at contact."},
 {key="ForceFarClamp",title="Far clamp distance",min=0.1,max=500,step=0.1,default=150,unit=" studs",hint="Weakening stops here; steel and iron range still cuts force to zero."},
 {key="PullAcceleration",title="Pull acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly E accelerates you."},
 {key="PushAcceleration",title="Push acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly Q accelerates you."},
 {key="PullSpeed",title="Pull top speed",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Maximum powered slide speed; acceleration sets how fast you reach it."},
 {key="PushSpeed",title="Push top speed",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Maximum powered slide speed; acceleration sets how fast you reach it."},
 {key="CoastDrag",title="Slide friction",min=0,max=8,step=0.1,default=2.3,unit="",hint="Resistance while coasting after release. 0 = no slide friction."},
 {key="StopSpeed",title="Slide stop cutoff",min=0,max=30,step=0.5,default=5,unit=" studs/s",hint="Released ground slides snap to zero below this speed."},
}

local function finite(n)
 return typeof(n)=="number" and n==n and math.abs(n)<math.huge
end
function Config.ForceScale(distance,settings,directionSign)
 if distance>=settings.AnchorRange then return 0 end
 local near=math.max(0.1,settings.ForceNearClamp)
 local far=math.max(near,settings.ForceFarClamp)
 local d=math.clamp(distance,near,far)
 local falloff=directionSign==-1 and settings.PushFalloff or settings.PullFalloff
 if falloff==nil then falloff=settings.ForceFalloff or 1 end
 return 1/(1+math.max(0,falloff)*(d/near-1))
end
-- Copy only known fields; never store client-supplied tables unvalidated.
function Config.Validate(data)
 if typeof(data)~="table" or typeof(data.values)~="table" or typeof(data.ranges)~="table" or typeof(data.showSpeedometer)~="boolean" then return nil end
 local clean={values={},ranges={},showSpeedometer=data.showSpeedometer}
 for _,spec in Config.Specs do
  local v,r=data.values[spec.key],data.ranges[spec.key]
  if v==nil and r==nil and (spec.key=="PullFalloff" or spec.key=="PushFalloff") then
   v=data.values.ForceFalloff or spec.default r=data.ranges.ForceFalloff or {spec.min,spec.max}
  end
  -- Migrate older master saves without discarding their existing tuning.
  if v==nil and r==nil and (string.sub(spec.key,1,7)=="AirPose" or spec.key=="ForceFalloff" or spec.key=="ForceNearClamp" or spec.key=="ForceFarClamp" or spec.key=="GroundSpeed" or spec.key=="GroundAcceleration" or spec.key=="AirSpeed" or spec.key=="AirAcceleration" or spec.key=="Gravity" or spec.key=="AirDrag" or spec.key=="JumpStrength" or spec.key=="SlideWAcceleration" or spec.key=="SlideWTopSpeed" or spec.key=="SlideSMinSpeed" or spec.key=="SlideBraking" or spec.key=="SlideLeftSteering" or spec.key=="SlideRightSteering") then
   v=spec.default r={spec.min,spec.max}
  end
  if typeof(r)~="table" then return nil end
  local low,high=r[1],r[2]
  local floor=(spec.key=="ForceNearClamp" or spec.key=="ForceFarClamp") and 0.1 or 0
  local ceiling=10000
  if not finite(v) or not finite(low) or not finite(high) or low<floor or high>ceiling or low>=high or v<low or v>high then return nil end
  clean.values[spec.key]=v
  clean.ranges[spec.key]={low,high}
 end
 return clean
end
return Config
