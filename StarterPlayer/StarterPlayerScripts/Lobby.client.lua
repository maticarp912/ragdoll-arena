-- LocalScript: StarterPlayer/StarterPlayerScripts/Lobby (responsable: Claude)
--   · Traduce los carteles de la ciudad (atributo LocKey) y el punto de la armería
--   · La armería de la plaza abre la tienda (ProximityPrompt "OpenShop")
--   · Marcador de la ARENA visible solo en el lobby
-- Etapa 8: la barra de cola pasó a LobbyUI.client (Gemini) y el fondo de las arenas a ArenaBackdrop.client (Codex).


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")


local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))


local player = Players.LocalPlayer

----------------------------------------------------------------------
-- Textos (ES / EN / PT-BR). Respaldo: inglés.
----------------------------------------------------------------------
local TEXT = {
	ES = { ["lobby.arena"] = "ARENA", ["lobby.practice"] = "Práctica", ["lobby.shop"] = "Armería",
		["queue.1v1"] = "Buscar 1v1", ["queue.2v2"] = "Buscar 2v2", ["queue.leave"] = "Salir de la cola",
		["queue.searching"] = "Buscando {mode}…  {n}/{need}" },
	EN = { ["lobby.arena"] = "ARENA", ["lobby.practice"] = "Practice", ["lobby.shop"] = "Armory",
		["queue.1v1"] = "Find 1v1", ["queue.2v2"] = "Find 2v2", ["queue.leave"] = "Leave queue",
		["queue.searching"] = "Searching {mode}…  {n}/{need}" },
	["PT-BR"] = { ["lobby.arena"] = "ARENA", ["lobby.practice"] = "Treino", ["lobby.shop"] = "Arsenal",
		["queue.1v1"] = "Procurar 1v1", ["queue.2v2"] = "Procurar 2v2", ["queue.leave"] = "Sair da fila",
		["queue.searching"] = "Procurando {mode}…  {n}/{need}" },
}
local function tr(key, params)
	local lang = Localization.language()
	local s = (TEXT[lang] and TEXT[lang][key]) or TEXT.EN[key] or Localization.t(key)
	return (s:gsub("{([%w_]+)}", function(name) return params and params[name] ~= nil and tostring(params[name]) or "" end))
end

local function localizeAll()
	for _, d in workspace:GetDescendants() do
		if d:IsA("TextLabel") and d:GetAttribute("LocKey") then
			d.Text = tr(d:GetAttribute("LocKey"))
		elseif d:IsA("ProximityPrompt") and d.Name == "OpenShop" then
			d.ActionText = tr("lobby.shop")
		end
	end
end
task.delay(2, localizeAll)
workspace.DescendantAdded:Connect(function(d)
	if (d:IsA("TextLabel") and d:GetAttribute("LocKey")) or (d:IsA("ProximityPrompt") and d.Name == "OpenShop") then
		task.defer(localizeAll)
	end
end)
Localization.Changed:Connect(function() localizeAll() end)

-- La armería abre la tienda
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "OpenShop" then
		local toggle = player:FindFirstChild("ToggleMenu")
		if toggle and not player:GetAttribute("MenuOpen") then toggle:Fire() end
	end
end)


----------------------------------------------------------------------
-- Marcador de la arena: solo en el lobby
----------------------------------------------------------------------
-- 11/11/2026 (rendimiento): antes buscaba ArenaMarker en TODO el workspace en cada frame. Ahora se busca
-- una vez por segundo como mucho y solo cambia cuando cambia InMatch.
local arenaMarker = nil
local function updateMarker()
	if not arenaMarker or not arenaMarker.Parent then arenaMarker = workspace:FindFirstChild("ArenaMarker", true) end
	if arenaMarker then arenaMarker.Enabled = player:GetAttribute("InMatch") ~= true end
end
player:GetAttributeChangedSignal("InMatch"):Connect(updateMarker)
task.spawn(function()
	while true do
		if not arenaMarker or not arenaMarker.Parent then updateMarker() end
		task.wait(1)
	end
end)

