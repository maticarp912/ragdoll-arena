-- Server-only, bounded event vocabulary and low-cardinality fields.
local Analytics = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")
local Service = {}
function Service.emit(player, event, value, weapon, mode, result)
 if RunService:IsStudio() then return end
 task.spawn(function()
  pcall(function()
   Analytics:LogCustomEvent(player, event, value or 1, {
    [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = weapon or "None",
    [Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = mode or "None",
    [Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = result or "None",
   })
  end)
 end)
end
return Service
