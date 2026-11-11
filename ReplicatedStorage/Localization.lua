local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- WaitForChild: la pantalla de carga (ReplicatedFirst) puede pedir este módulo antes de que lleguen
-- los archivos de idioma al cliente; sin esperar, el módulo fallaba y rompía toda la interfaz.
local parent = script.Parent
local tables = { ES = require(parent:WaitForChild("LocaleES")), EN = require(parent:WaitForChild("LocaleEN")), ["PT-BR"] = require(parent:WaitForChild("LocalePT")) }

-- Fragmentos de idioma de cada IA (etapa 8). Cada archivo devuelve
--   { ES = { clave = "texto" }, EN = { ... }, ["PT-BR"] = { ... } }
-- y tiene un solo responsable: LocaleCodex (Codex) y LocaleGemini (Gemini).
-- Las claves de LocaleES/EN/PT tienen prioridad; en Studio se avisa si un fragmento repite una.
for _, name in { "LocaleCodex", "LocaleGemini" } do
 local module = parent:FindFirstChild(name) or parent:WaitForChild(name, 5)
 local ok, fragment = false, nil
 if module then ok, fragment = pcall(require, module) end
 if module and not ok then warn(("[Localization] %s falló: %s"):format(name, tostring(fragment))) end
 if ok and type(fragment) == "table" then
  for lang, base in tables do
   for key, text in fragment[lang] or {} do
    if base[key] == nil then
     base[key] = text
    elseif RunService:IsStudio() then
     warn(("[Localization] %s repite la clave %s (%s): se ignora"):format(name, key, lang))
    end
   end
  end
 end
end

-- 10/11/2026: nombres de las skins de Tormenta = nombre traducido de la original con el formato skin.stormName
do
 local module = parent:FindFirstChild("Skins") or parent:WaitForChild("Skins", 5)
 local ok, Skins = false, nil
 if module then ok, Skins = pcall(require, module) end
 if ok and type(Skins) == "table" and Skins.Data then
  for id, s in Skins.Data do
   if s.stormOf then
    for _, base in tables do
     local orig = base["skin." .. s.stormOf] or s.name
     if base["skin." .. id] == nil then base["skin." .. id] = string.format(base["skin.stormName"] or "%s", orig) end
     if base["skinDesc." .. id] == nil then base["skinDesc." .. id] = base["skinDesc.storm"] end
    end
   end
  end
 end
end

local Localization = {}
local changed = Instance.new("BindableEvent")
Localization.Changed = changed.Event
local player = Players.LocalPlayer
function Localization.language()
 local saved = player and player:GetAttribute("Language")
 if tables[saved] then return saved end
 local locale = player and string.lower(player.LocaleId) or "en"
 if string.match(locale, "^es") then return "ES" end
 if string.match(locale, "^pt") then return "PT-BR" end
 return "EN"
end
function Localization.t(key, params)
 local text = tables[Localization.language()][key] or tables.EN[key] or key
 return (text:gsub("{([%w_]+)}", function(name)
  local value = params and params[name]
  -- {team} se rellena con params.team, o traduciendo params.teamKey (una clave de idioma)
  if value == nil and params and type(params[name .. "Key"]) == "string" then
   value = Localization.t(params[name .. "Key"])
  end
  return value ~= nil and tostring(value) or ("{" .. name .. "}")
 end))
end
function Localization.format(message)
 if type(message) == "table" and type(message.key) == "string" then return Localization.t(message.key, message.params) end
 return type(message) == "string" and message or ""
end
function Localization.binding(name)
 if tables.EN[name] then return Localization.t(name) end
 return name or ""
end
if player then player:GetAttributeChangedSignal("Language"):Connect(function() changed:Fire() end) end
return Localization
