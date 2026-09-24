local p=game.Players.LocalPlayer local m=require(p.PlayerScripts.MetalMotion)
local config=require(game.ReplicatedStorage.MetalTuningConfig)
local air=require(p.PlayerScripts.AerialMovement)
local before=m.Snapshot(true)
local results={}
local function check(name,ok) results[name]=ok assert(ok,name) end
local ok,err=pcall(function()
 for _,k in {"GroundSpeed","GroundAcceleration","AirSpeed","AirAcceleration","Gravity"} do
  check(k.." UI",p.PlayerGui.MetalTuning.Panel.Content.Sliders:FindFirstChild(k,true)~=nil)
 end
 local old=m.Snapshot(true)
 for _,k in {"GroundSpeed","GroundAcceleration","AirSpeed","AirAcceleration","Gravity"} do old.values[k]=nil old.ranges[k]=nil end
 check("Old saves migrate",config.Validate(old).values.GroundSpeed==16)
 m.SetSetting("AirSpeed",90) m.SetSetting("AirAcceleration",400) m.SetSetting("Gravity",125)
 task.wait(.15)
 check("Live air speed",air.Speed==90) check("Live air acceleration",air.Acceleration==400)
 check("Live gravity",workspace.Gravity==125)
 check("Ground independent",m.Settings.GroundSpeed==16 and p.Character.Humanoid.WalkSpeed<=16)
 m.ResetSetting("Gravity") task.wait(.1) check("Gravity reset",workspace.Gravity==60)
 local baseWidth,baseColor,baseTransparency local count=0 local selected=workspace.MetalAwareness:GetAttribute("SelectedAnchor")
 for _,b in workspace.MetalAwareness:GetChildren() do
  if b:IsA("Beam") and b.Enabled and b.Name~="LineTo_"..tostring(selected).."_1" then
   count+=1
   if baseWidth then check("Beam width "..count,b.Width0==baseWidth and b.Width1==baseWidth) check("Beam color "..count,b.Color.Keypoints[1].Value==baseColor) check("Beam alpha "..count,b.Transparency.Keypoints[1].Value==baseTransparency)
   else baseWidth=b.Width0 baseColor=b.Color.Keypoints[1].Value baseTransparency=b.Transparency.Keypoints[1].Value end
  end
 end
 check("Multiple baseline beams",count>3)
end)
m.ApplySettings(before)
p:SetAttribute("MovementTuningResults",game.HttpService:JSONEncode({passed=ok,error=err,checks=results}))
script:Destroy()