local p=game.Players.LocalPlayer local m=require(p.PlayerScripts.MetalMotion) local c=require(p.PlayerScripts.MetalSlideControl)
local snapshot=m.Snapshot(true) local read=c.Read local r=p.Character.HumanoidRootPart local origin=r.CFrame
local a=Instance.new("Part") a.Name="WCoastTest" a.Anchored=true a.Position=Vector3.new(800,3,600) a.Parent=workspace.MetalAnchors
local ok,err=pcall(function()
 local s=table.clone(snapshot.values) s.SlideWAcceleration=25 s.SlideWTopSpeed=200
 local v=Vector3.new(0,0,100)
 assert(c.Step(v,Vector2.new(0,1),s,1,false)==v)
 assert(math.abs(c.Step(v,Vector2.new(0,1),s,1,true).Magnitude-125)<.001)
 assert(c.Step(Vector3.new(0,0,250),Vector2.new(0,1),s,1,true).Magnitude==250)
 local function trial(w)
  m.Cancel() r.CFrame=CFrame.new(800,5,0) r.AssemblyLinearVelocity=Vector3.zero
  c.Read=function() return Vector2.zero end task.wait(.8)
  m.Start(a,1) task.wait(1)
  m.Stop() c.Read=function() return Vector2.new(0,w and 1 or 0) end
  local speed=function() return Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude end
  local start=speed() local max=start
  for i=1,24 do task.wait(1/60) max=math.max(max,speed()) end
  return speed()/start,max-start
 end
 local normal=trial(false) local held,gain=trial(true)
 assert(held<.99 and held>normal+.05,"W coast decay "..held.." versus "..normal)
 assert(gain<1,"W added coasting speed "..gain)
 workspace:SetAttribute("WCoastResult",string.format("PASS: speed retained without W %.0f%%, with W %.0f%%; max coasting gain %.2f",normal*100,held*100,gain))
end)
m.Cancel() c.Read=read m.ApplySettings(snapshot) a:Destroy() r.CFrame=origin r.AssemblyLinearVelocity=Vector3.zero
if not ok then workspace:SetAttribute("WCoastResult","FAIL: "..tostring(err)) error(err) end