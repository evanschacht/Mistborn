-- Ground sliding input and integration, independent of camera orientation.
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local Control={}
function Control.Read()
 if Input:GetFocusedTextBox() or Gui.MenuIsOpen then return Vector2.zero end
 local function down(key) return Input:IsKeyDown(key) and 1 or 0 end
 return Vector2.new(down(Enum.KeyCode.D)-down(Enum.KeyCode.A),down(Enum.KeyCode.W)-down(Enum.KeyCode.S))
end
function Control.Step(velocity,input,settings,dt)
 local speed=velocity.Magnitude
 if speed<0.001 then return Vector3.zero end
 local direction=velocity/speed
 if input.Y>0 then
  speed+=math.min(settings.SlideWAcceleration*input.Y*dt,math.max(0,settings.SlideWTopSpeed-speed))
 elseif input.Y<0 then
  speed=math.max(0,speed-settings.SlideBraking*(-input.Y)*dt)
 end
 local rate=input.X<0 and settings.SlideLeftSteering or settings.SlideRightSteering
 local angle=-math.rad(rate)*input.X*dt
 direction=CFrame.Angles(0,angle,0):VectorToWorldSpace(direction)
 return direction*speed
end
return Control
