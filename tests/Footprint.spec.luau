local g=require(game.ReplicatedStorage.MetalForceGeometry)
local size=Vector3.new(10,4,10)
local bodySize=Vector3.new(2,2,2)
local checks=0
local function check(pass,message) assert(pass,message) checks+=1 end
local function direction(x,y,z,sign,cf)
 return g.Direction(cf or CFrame.new(),size,CFrame.new(x,y,z),bodySize,sign or -1)
end
check(direction(0,5,0)==Vector3.yAxis,"Centered push")
check(direction(4,5,3)==Vector3.yAxis,"Off-center push")
check(direction(5.999,5,0)==Vector3.yAxis,"Tiny body overlap past edge")
check(direction(6.01,5,0).X>0,"Fully outside footprint regains horizontal force")
check(direction(4,5,3,1)==-Vector3.yAxis,"Pull above block points down")
check(direction(4,0,0).X>0,"Side of block must not point up")
check(direction(0,-5,0).Y<0,"Below block pushes down")
local rotated=CFrame.Angles(0,math.pi/4,0)
check(direction(6.5,5,0,-1,rotated)==Vector3.yAxis,"Rotated shadow overlap")
check(direction(6.5,5,6.5,-1,rotated).X>0,"Outside rotated shape but inside its bounding rectangle")
return {passed=checks}
