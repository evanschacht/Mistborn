local Config={}
Config.Specs={
 {key="AnchorRange",title="Steel and iron range",min=0,max=500,step=1,default=180,unit=" studs",hint="Reach of blue lines, selection and push/pull, in studs."},
 {key="PullAcceleration",title="Pull acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly E accelerates you."},
 {key="PushAcceleration",title="Push acceleration",min=50,max=800,step=10,default=340,unit=" studs/s²",hint="How strongly Q accelerates you."},
 {key="PullSpeed",title="Pull top speed",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Maximum powered slide speed; acceleration sets how fast you reach it."},
 {key="PushSpeed",title="Push top speed",min=20,max=400,step=5,default=160,unit=" studs/s",hint="Maximum powered slide speed; acceleration sets how fast you reach it."},
 {key="PullGravity",title="Pull gravity assistance",min=0,max=100,step=1,default=98,unit="%",hint="0 = full gravity; 100 = full weight support."},
 {key="PushGravity",title="Push gravity assistance",min=0,max=100,step=1,default=98,unit="%",hint="With both held, the two settings are averaged."},
 {key="GravityBlend",title="Gravity assistance buildup",min=0.1,max=4,step=0.1,default=1.5,unit=" s",hint="Time for weight support to reach full strength."},
 {key="FallBraking",title="Off-direction momentum braking",min=0,max=12,step=0.25,default=5,unit="",hint="Removes drift sideways to the combined force."},
 {key="HeldDrag",title="Airborne drag",min=0,max=5,step=0.1,default=1.2,unit="",hint="Airborne drift resistance; does not limit powered ground speed."},
 {key="CoastDrag",title="Slide friction",min=0,max=8,step=0.1,default=2.3,unit="",hint="Resistance while coasting after release. 0 = no slide friction."},
 {key="StopSpeed",title="Slide stop cutoff",min=0,max=30,step=0.5,default=5,unit=" studs/s",hint="Released ground slides snap to zero below this speed."},
}

local function finite(n)
 return typeof(n)=="number" and n==n and math.abs(n)<math.huge
end
-- Copy only known fields; never store client-supplied tables unvalidated.
function Config.Validate(data)
 if typeof(data)~="table" or typeof(data.values)~="table" or typeof(data.ranges)~="table" or typeof(data.showSpeedometer)~="boolean" then return nil end
 local clean={values={},ranges={},showSpeedometer=data.showSpeedometer}
 for _,spec in Config.Specs do
  local v,r=data.values[spec.key],data.ranges[spec.key]
  if typeof(r)~="table" then return nil end
  local low,high=r[1],r[2]
  local floor=spec.key=="GravityBlend" and 0.01 or 0
  local ceiling=(spec.key=="PullGravity" or spec.key=="PushGravity") and 100 or 10000
  if not finite(v) or not finite(low) or not finite(high) or low<floor or high>ceiling or low>=high or v<low or v>high then return nil end
  clean.values[spec.key]=v
  clean.ranges[spec.key]={low,high}
 end
 return clean
end
return Config
