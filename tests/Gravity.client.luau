-- Temporary Studio LocalScript. Isolated anchors, real unmodified Roblox gravity.
local p=game.Players.LocalPlayer
local m=require(p.PlayerScripts.MetalMotion)
local r=p.Character.HumanoidRootPart
local h=p.Character.Humanoid
local saved=m.Snapshot(true)
local original=r.CFrame
local results={}
local anchor=Instance.new("Part")
anchor.Name="GravityTestAnchor" anchor.Anchored=true anchor.CanCollide=false
anchor.Parent=workspace.MetalAnchors
local follow
local function check(name,pass,data) table.insert(results,{name=name,pass=pass,data=data}) end
local function reset(position)
 if follow then follow:Disconnect() follow=nil end
 m.Cancel() r.CFrame=CFrame.new(position) r.AssemblyLinearVelocity=Vector3.zero
 m.SetSetting("PullAcceleration",230) m.SetSetting("PushAcceleration",230)
 m.SetSetting("PullSpeed",160) m.SetSetting("PushSpeed",160)
end
local ok,err=pcall(function()
 for _,sign in {1,-1} do
  reset(Vector3.new(800,150,800))
  task.wait(.1)
  anchor.Position=r.Position+Vector3.new(100*sign,0,0)
  follow=game:GetService("RunService").PreSimulation:Connect(function() anchor.Position=r.Position+Vector3.new(100*sign,0,0) end)
  r.AssemblyLinearVelocity=Vector3.new(0,50,0)
  m.Start(anchor,sign)
  local startY=r.AssemblyLinearVelocity.Y
  task.wait(.2)
  local force=r:FindFirstChild("MetalMotionForce")
  local ay=force and force.Force.Y/r.AssemblyMass or math.huge
  check("Horizontal metal retains jump gravity sign "..sign,r.AssemblyLinearVelocity.Y<startY-25 and math.abs(ay)<5,{start=startY,finish=r.AssemblyLinearVelocity.Y,metalY=ay})
 end
 for _,sign in {1,-1} do
  reset(Vector3.new(800,100,800)) task.wait(.1)
  anchor.Position=r.Position+Vector3.new(0,100*sign,0)
  r.AssemblyLinearVelocity=Vector3.zero m.Start(anchor,sign)
  task.wait(.25)
  check("Vertical metal lifts against gravity sign "..sign,r.AssemblyLinearVelocity.Y>3,{vy=r.AssemblyLinearVelocity.Y,gravity=workspace.Gravity})
 end
 m.Stop()
 local before=r.AssemblyLinearVelocity.Y task.wait(.2)
 check("Release immediately resumes ballistic fall",r.AssemblyLinearVelocity.Y<before-25,{before=before,after=r.AssemblyLinearVelocity.Y})
 reset(Vector3.new(800,100,800)) task.wait(.1)
 anchor.Position=r.Position+Vector3.new(100,0,0)
 r.AssemblyLinearVelocity=Vector3.zero
 m.Start(anchor,1) m.Start(anchor,-1) task.wait(.2)
 local force=r.MetalMotionForce.Force/r.AssemblyMass
 check("Opposing metal forces cancel but gravity remains",force.Magnitude<.01 and r.AssemblyLinearVelocity.Y< -25,{metalForce=force.Magnitude,vy=r.AssemblyLinearVelocity.Y})
 reset(Vector3.new(800,8,800)) task.wait(.6)
 local start=r.Position
 anchor.Position=start+Vector3.new(60,20,0)
 m.SetSetting("PullSpeed",20) m.Start(anchor,1)
 task.wait(.3)
 check("Shallow pull stays on ground",h.FloorMaterial~=Enum.Material.Air and math.abs(r.Position.Y-start.Y)<1,{rise=r.Position.Y-start.Y})
 local lifted=false local maxRise=0
 for i=1,300 do
  task.wait(1/60)
  maxRise=math.max(maxRise,r.Position.Y-start.Y)
  if maxRise>2 and h.FloorMaterial==Enum.Material.Air then lifted=true break end
 end
 check("Static elevated anchor lifts as angle steepens",lifted,{rise=maxRise})
end)
if follow then follow:Disconnect() end
m.Cancel() m.ApplySettings(saved) anchor:Destroy()
r.CFrame=original r.AssemblyLinearVelocity=Vector3.zero
if not ok then table.insert(results,{name="Harness",pass=false,error=tostring(err)}) end
workspace:SetAttribute("GravityTests",game.HttpService:JSONEncode(results))
script:Destroy()
