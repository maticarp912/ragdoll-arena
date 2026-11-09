local Lighting = game:GetService("Lighting")
local Theme = require(script.Parent:WaitForChild("Theme"))
local Environment = {}
function Environment.apply()
 local L = Theme.Lighting
 for _, key in { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation" } do Lighting[key] = L[key] end
 local function effect(class, values)
  local obj = Lighting:FindFirstChildOfClass(class) or Instance.new(class)
  for k,v in values do obj[k] = v end
  obj.Parent = Lighting
 end
 effect("Sky", L.Sky) effect("Atmosphere", L.Atmosphere) effect("ColorCorrectionEffect", L.ColorCorrection) effect("BloomEffect", L.Bloom)
 -- Nubes del terreno: cielo cubierto y oscuro
 if L.Clouds then
  local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
  for k, v in L.Clouds do clouds[k] = v end
  clouds.Parent = workspace.Terrain
 end
end
return Environment
