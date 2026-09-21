local Geometry={}
local function cross(a,b,c)
 return (b.X-a.X)*(c.Y-a.Y)-(b.Y-a.Y)*(c.X-a.X)
end
-- Project the complete oriented box, so rotated anchors use their real shadow.
local function footprint(cf,size)
 local points={} local top=-math.huge
 for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
  local p=cf:PointToWorldSpace(size*Vector3.new(x,y,z)*.5)
  top=math.max(top,p.Y)
  table.insert(points,Vector2.new(p.X,p.Z))
 end end end
 table.sort(points,function(a,b) return a.X<b.X or (a.X==b.X and a.Y<b.Y) end)
 local unique={}
 for _,p in points do
  if #unique==0 or (p-unique[#unique]).Magnitude>1e-6 then table.insert(unique,p) end
 end
 local lower,upper={},{}
 for _,p in unique do
  while #lower>=2 and cross(lower[#lower-1],lower[#lower],p)<=0 do table.remove(lower) end
  table.insert(lower,p)
 end
 for i=#unique,1,-1 do
  local p=unique[i]
  while #upper>=2 and cross(upper[#upper-1],upper[#upper],p)<=0 do table.remove(upper) end
  table.insert(upper,p)
 end
 table.remove(lower) table.remove(upper)
 for _,p in upper do table.insert(lower,p) end
 return lower,top
end
local function separated(a,b)
 for i,p in a do
  local edge=a[i%#a+1]-p
  local axis=Vector2.new(-edge.Y,edge.X).Unit
  local lowA,highA,lowB,highB=math.huge,-math.huge,math.huge,-math.huge
  for _,v in a do local d=v:Dot(axis) lowA=math.min(lowA,d) highA=math.max(highA,d) end
  for _,v in b do local d=v:Dot(axis) lowB=math.min(lowB,d) highB=math.max(highB,d) end
  if highA<lowB-1e-5 or highB<lowA-1e-5 then return true end
 end
 return false
end
function Geometry.Direction(anchorCF,anchorSize,bodyCF,bodySize,sign)
 local anchor,top=footprint(anchorCF,anchorSize)
 if bodyCF.Position.Y>=top then
  local body=footprint(bodyCF,bodySize)
  if not separated(anchor,body) and not separated(body,anchor) then
   return Vector3.new(0,-sign,0)
  end
 end
 local delta=anchorCF.Position-bodyCF.Position
 return delta.Magnitude>.1 and delta.Unit*sign or Vector3.zero
end
return Geometry
