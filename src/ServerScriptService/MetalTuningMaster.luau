-- Shared master record; injectable store and notification callback for tests.
local Master={}
function Master.new(store,validate,onChange)
 local self={revision=0,data=nil}
 function self:Accept(record)
  if typeof(record)~="table" or typeof(record.revision)~="number" or record.revision<=self.revision then return end
  local clean=validate(record.data)
  if not clean then return end
  self.revision=record.revision self.data=clean
  onChange({revision=self.revision,data=clean})
 end
 function self:Load()
  local ok,result=pcall(function() return store:GetAsync("master") end)
  if not ok then return false end
  self:Accept(result)
  return true
 end
 function self:Save(payload,canSave)
  if not canSave then return false,"Only the game owner can save master tuning" end
  local clean=validate(payload)
  if not clean then return false,"Invalid settings; not saved" end
  local ok,result=pcall(function()
   return store:UpdateAsync("master",function(old)
    local revision=typeof(old)=="table" and tonumber(old.revision) or 0
    return {revision=(revision or 0)+1,data=clean}
   end)
  end)
  if not ok then return false,"Save service unavailable; retry" end
  self:Accept(result)
  return true
 end
 return self
end
return Master
