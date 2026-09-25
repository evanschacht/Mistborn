local Rules={Capacity=15,Duration=1.1,GrabTime=0.28,ReleaseTime=0.68,Size=Vector3.new(0.1,0.6,0.6)}
function Rules.CanToss(count,start,now)
 return count>0 and (not start or now-start>=Rules.Duration)
end
return Rules
