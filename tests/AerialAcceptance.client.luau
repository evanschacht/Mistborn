local p=game.Players.LocalPlayer local h=p.Character:FindFirstChildOfClass("Humanoid") local r=p.Character.HumanoidRootPart
local air=require(p.PlayerScripts.AerialMovement)
local v=Vector3.zero for i=1,60 do v=air.Horizontal(v,Vector3.xAxis,1/60) end
assert(math.abs(v.X-32)<.01)
assert(air.Horizontal(Vector3.new(160,0,0),Vector3.xAxis,1/60).X==160)
assert(air.Horizontal(Vector3.new(160,0,0),-Vector3.xAxis,1/60).X<160)
local y=r.Position.Y local maxY=y local start=os.clock() h.Jump=true
local airborne=false local time=0
repeat game:GetService("RunService").Heartbeat:Wait() maxY=math.max(maxY,r.Position.Y) if h.FloorMaterial==Enum.Material.Air then airborne=true end time=os.clock()-start until (airborne and h.FloorMaterial~=Enum.Material.Air) or time>3
task.wait(.1)
p:SetAttribute("AerialTest",game.HttpService:JSONEncode({steeringCap=v.X,airtime=time,height=maxY-y,landed=airborne and h.FloorMaterial~=Enum.Material.Air,walkSpeed=h.WalkSpeed}))
script:Destroy()