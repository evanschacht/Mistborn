local Rules={PullAccelerationMultiplier=4,PullSteering=18,Capacity=15,Duration=0.55,GrabTime=0.14,ReleaseTime=0.34,FallSpeedScale=1.5,Size=Vector3.new(0.1,0.6,0.6)}
function Rules.CanToss(count,start,now)
 return count>0 and (not start or now-start>=Rules.Duration)
end
function Rules.ReleasePosition(root)
 local h=root.Parent:FindFirstChildOfClass("Humanoid")
 local distance=(h and h.HipHeight or 2)+root.Size.Y*.5+.15
 local params=RaycastParams.new() params.RespectCanCollide=true
 local exclude={root.Parent}
 local effects=workspace:FindFirstChild("MetalAwareness") if effects then table.insert(exclude,effects) end
 local anchors=workspace:FindFirstChild("MetalAnchors")
 if anchors then for _,part in anchors:GetChildren() do if part:GetAttribute("IsCoin") then table.insert(exclude,part) end end end
 params.FilterDescendantsInstances=exclude
 local hit=workspace:Raycast(root.Position,Vector3.new(0,-distance,0),params)
 return hit and hit.Position+Vector3.yAxis*.06 or root.Position-Vector3.yAxis*distance
end
-- Exact unpowered flight: horizontal drag and continuous downward gravity.
function Rules.Flight(position,velocity,gravity,drag,dt)
 dt=math.max(0,dt)
 local decay=math.exp(-drag*dt)
 local travel=drag>0.0001 and (1-decay)/drag or dt
 return position+Vector3.new(velocity.X*travel,velocity.Y*dt-.5*gravity*dt*dt,velocity.Z*travel),
  Vector3.new(velocity.X*decay,velocity.Y-gravity*dt,velocity.Z*decay)
end
return Rules
