local p=game.Players.LocalPlayer local h=p.Character.Humanoid local r=p.Character.HumanoidRootPart local ui=game:GetService("UserInputService") local result={}
local conn
conn=game:GetService("RunService").PostSimulation:Connect(function()
 local v=r.AssemblyLinearVelocity local flat=Vector3.new(v.X,0,v.Z)
 for _,key in {"W","A","S","D"} do
  if ui:IsKeyDown(Enum.KeyCode[key]) and h.FloorMaterial==Enum.Material.Air then
   local row=result[key] or {maxSpeed=0,airFrames=0,minFacingDot=1}
   row.maxSpeed=math.max(row.maxSpeed,flat.Magnitude) row.airFrames+=1
   if flat.Magnitude>2 then row.minFacingDot=math.min(row.minFacingDot,r.CFrame.LookVector:Dot(flat.Unit)) end
   result[key]=row
  end
 end
 p:SetAttribute("AirInputResults",game.HttpService:JSONEncode(result))
end)
task.wait(30) conn:Disconnect() script:Destroy()