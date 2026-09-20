-- Run as a temporary LocalScript in Studio Play. Does not write to DataStore.
local player=game.Players.LocalPlayer
local motion=require(player.PlayerScripts:WaitForChild("MetalMotion"))
local gui=player.PlayerGui:WaitForChild("MetalTuning",30)
assert(gui,"Tuning panel did not load")
local before=motion.Snapshot(gui:GetAttribute("ShowSpeedometer"))
local results={}
local function check(name,pass) table.insert(results,{name=name,passed=pass}) assert(pass,name) end
check("Save below Reset All",gui.Panel.Content.Save.Position.Y.Offset>gui.Panel.Content.Reset.Position.Y.Offset)
for _,spec in motion.SettingSpecs do
 check("Reset button: "..spec.key,gui.Panel.Content.Sliders[spec.key]:FindFirstChild("ResetDefault")~=nil)
end
motion.SetRange("HeldDrag",0,30)
motion.SetSetting("HeldDrag",8)
local other=motion.Settings.PullAcceleration
motion.ResetSetting("HeldDrag")
local low,high=motion.GetRange("HeldDrag")
check("Individual reset restores original value and range",motion.Settings.HeldDrag==1.2 and low==0 and high==5)
check("Individual reset preserves other sliders",motion.Settings.PullAcceleration==other)
motion.ResetSettings()
for _,spec in motion.SettingSpecs do
 local a,b=motion.GetRange(spec.key)
 check("Reset all: "..spec.key,motion.Settings[spec.key]==spec.default and a==spec.min and b==spec.max)
end
check("Snapshot restores all settings",motion.ApplySettings(before))
for _,spec in motion.SettingSpecs do
 check("Restored: "..spec.key,motion.Settings[spec.key]==before.values[spec.key])
end
workspace:SetAttribute("TuningPersistenceTests",game.HttpService:JSONEncode(results))
script:Destroy()
