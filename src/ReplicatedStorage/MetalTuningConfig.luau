local Config={}
Config.Specs={
 {key="AnchorRange",title="Steel and iron range",min=0,max=500,step=1,default=180,unit=" studs",hint="Reach of blue lines, selection and push/pull, in studs."},
 {key="ForceFalloff",title="Force falloff",min=0,max=5,step=0.05,default=1,unit="",hint="0 = constant; 1 = inverse-linear; higher = faster weakening."},
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
function Config.ForceScale(distance,settings)
 if distance>=settings.AnchorRange then return 0 end
 local near=math.max(0.1,settings.ForceNearClamp)
 local far=math.max(near,settings.ForceFarClamp)
 local d=math.clamp(distance,near,far)
 return 1/(1+math.max(0,settings.ForceFalloff)*(d/near-1))
end
-- Copy only known fields; never store client-supplied tables unvalidated.
function Config.Validate(data)
 if typeof(data)~="table" or typeof(data.values)~="table" or typeof(data.ranges)~="table" or typeof(data.showSpeedometer)~="boolean" then return nil end
 local clean={values={},ranges={},showSpeedometer=data.showSpeedometer}
 for _,spec in Config.Specs do
  local v,r=data.values[spec.key],data.ranges[spec.key]
  -- Migrate older master saves without discarding their existing tuning.
  if v==nil and r==nil and (spec.key=="ForceFalloff" or spec.key=="ForceNearClamp" or spec.key=="ForceFarClamp") then
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
