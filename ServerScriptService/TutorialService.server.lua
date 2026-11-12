-- Script: ServerScriptService/TutorialService
-- Responsable: Claude (0.2, ronda 2). Certifica en el servidor los 3 pasos del tutorial del patio y se los
-- informa a RewardService.tutorial(player, paso) (Codex), que paga cada paso una sola vez (Rewards.TutorialSouls).
-- El cliente (Tutorial.client) solo muestra el progreso: nunca certifica nada.
--   Paso 1: pegarle 3 veces a un muñeco (CombatEvents "Damage", víctima con IsDummy).
--   Paso 2: ponerse en guardia cerca de un muñeco (atributo Blocking que pone el servidor).
--   Paso 3: patear a un muñeco (CombatEvents "Kick").
-- Solo cuenta fuera de partida (la práctica del patio).

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatEvents = require(ServerScriptService:WaitForChild("CombatEvents"))
local RewardService = require(ServerScriptService:WaitForChild("RewardService"))

local HITS_NEEDED = 3
local DUMMY_RANGE = 45

local hits = {}
Players.PlayerRemoving:Connect(function(p) hits[p] = nil end)

local function practicing(player)
	return player ~= nil and player.Parent ~= nil and player:GetAttribute("InMatch") ~= true
end

local function step(player, n)
	local ok, err = pcall(RewardService.tutorial, player, n)
	if not ok then warn("[Tutorial] paso", n, err) end
end

CombatEvents.Fired:Connect(function(kind, attacker, victim)
	local player = attacker and Players:GetPlayerFromCharacter(attacker)
	if not practicing(player) or not (victim and victim:GetAttribute("IsDummy")) then return end
	if kind == "Damage" then
		hits[player] = (hits[player] or 0) + 1
		if hits[player] >= HITS_NEEDED then step(player, 1) end
	elseif kind == "Kick" then
		step(player, 3)
	end
end)

local function nearDummy(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("Dummies")
	if not root or not folder then return false end
	for _, d in folder:GetChildren() do
		local r = d:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - root.Position).Magnitude <= DUMMY_RANGE then return true end
	end
	return false
end

local function onCharacter(player, char)
	char:GetAttributeChangedSignal("Blocking"):Connect(function()
		if char:GetAttribute("Blocking") and practicing(player) and nearDummy(char) then step(player, 2) end
	end)
end

local function onPlayer(player)
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
	if player.Character then onCharacter(player, player.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end

----------------------------------------------------------------------
-- 12/11/2026 (Claude): TUTORIAL GUIADO de la primera entrada (pedido del usuario)
-- La primera vez que alguien entra aparece en un patio de entrenamiento aparte (no en la ciudad).
-- GuidedTutorial.client muestra los pasos (moverse, fijar, cambiar de fijado, ataques, direcciones,
-- combo, derribo, bloqueo y parry contra un bot) y, al terminar o al saltarlo, el servidor lo manda
-- a la ciudad y lo guarda en el perfil (TutorialGuidedDone). No paga nada extra: los premios de siempre
-- salen de los pasos de arriba (golpes, guardia y patada a un muñeco).
----------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))
local Dummies = require(ServerScriptService:WaitForChild("Dummies"))
local CityConfig = require(ReplicatedStorage:WaitForChild("CityConfig"))

local G = CityConfig.GuidedTutorial
local GuidedRemote = Remotes.get("GuidedTutorial")
local guided = {} -- [Player] = { step = number }

local function part(name, size, cf, color, material, parent, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Patio de entrenamiento: piso de piedra, muro bajo, columnas con antorchas y el círculo de llegada
local origin = G.Origin
local yard = Instance.new("Folder")
yard.Name = "TrainingYard"
yard.Parent = workspace
part("YardFloor", Vector3.new(G.Size, 2, G.Size), CFrame.new(origin - Vector3.yAxis), G.Floor, Enum.Material.Cobblestone, yard)
for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
	local along = side[1] == 0
	part("YardWall", along and Vector3.new(G.Size, G.WallHeight, 2) or Vector3.new(2, G.WallHeight, G.Size),
		CFrame.new(origin + Vector3.new(side[1] * G.Size / 2, G.WallHeight / 2, side[2] * G.Size / 2)), G.Wall, Enum.Material.Slate, yard)
end
for _, corner in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
	local base = origin + Vector3.new(corner[1] * (G.Size / 2 - 3), 0, corner[2] * (G.Size / 2 - 3))
	part("YardPillar", Vector3.new(3, G.PillarHeight, 3), CFrame.new(base + Vector3.yAxis * G.PillarHeight / 2), G.Wall, Enum.Material.Slate, yard)
	local flame = part("YardTorch", Vector3.new(1.2, 1.6, 1.2), CFrame.new(base + Vector3.yAxis * (G.PillarHeight + 0.8)), G.Torch, Enum.Material.Neon, yard)
	local light = Instance.new("PointLight")
	light.Color = G.Torch
	light.Range = G.TorchRange
	light.Brightness = G.TorchBrightness
	light.Parent = flame
end
local marker = part("TutorialMarker", Vector3.new(0.3, G.MarkerSize, G.MarkerSize),
	CFrame.new(origin + G.MarkerOffset) * CFrame.Angles(0, 0, math.rad(90)), G.Marker, Enum.Material.Neon, yard, 0.35)
marker.Shape = Enum.PartType.Cylinder
marker.CanCollide = false
yard:SetAttribute("Spawn", CFrame.lookAt(origin + G.SpawnOffset, origin + G.MarkerOffset))

-- Dos muñecos quietos para fijar, cambiar de objetivo y pegar; y un bot que ataca solo cuando alguien
-- está en los pasos de bloqueo o parry (el resto del tiempo se queda quieto, para no frustrar).
local function botMode()
	for _, state in guided do
		if state.step >= G.BotFromStep then return "Attack" end
	end
	return "Idle"
end
task.defer(function()
	for _, offset in G.DummyOffsets do
		Dummies.add(CFrame.lookAt(origin + offset, origin + G.SpawnOffset), "Idle")
	end
	Dummies.add(CFrame.lookAt(origin + G.BotOffset, origin + G.SpawnOffset), botMode)
end)

local function needsTutorial(player)
	local data = PlayerData.get(player)
	for _ = 1, 20 do
		if data or not player.Parent then break end
		task.wait(0.5)
		data = PlayerData.get(player)
	end
	if not data or data.TutorialGuidedDone == true then return false end
	-- quien ya jugaba antes de la 0.3 no lo necesita
	if (data.Level or 1) > 1 or ((data.Stats and data.Stats.Matches) or 0) > 0 then
		data.TutorialGuidedDone = true
		return false
	end
	return true
end

local function sendToCity(player)
	local char = player.Character
	local spawn = workspace:GetAttribute("LobbySpawn")
	if char and typeof(spawn) == "CFrame" then char:PivotTo(spawn) end
end

local function finish(player)
	local data = PlayerData.get(player)
	if data then
		data.TutorialGuidedDone = true
		PlayerData.saveSoon(player)
	end
	guided[player] = nil
	player:SetAttribute("InTutorial", false)
	sendToCity(player)
end

local function placeInYard(player, char)
	if not needsTutorial(player) or player:GetAttribute("InMatch") or player.Character ~= char then return end
	task.wait(0.3) -- después de que MatchService lo ponga en la ciudad
	if player.Character ~= char then return end
	guided[player] = guided[player] or { step = 1 }
	player:SetAttribute("InTutorial", true)
	char:PivotTo(yard:GetAttribute("Spawn"))
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		-- en el tutorial no se muere: si baja mucho la vida, se recupera
		hum.HealthChanged:Connect(function(hp)
			if player:GetAttribute("InTutorial") and hp < hum.MaxHealth * G.MinHealth then
				hum.Health = hum.MaxHealth * G.RefillHealth
			end
		end)
	end
end

local function watch(player)
	player.CharacterAdded:Connect(function(char) task.spawn(placeInYard, player, char) end)
	if player.Character then task.spawn(placeInYard, player, player.Character) end
end
Players.PlayerAdded:Connect(watch)
for _, p in Players:GetPlayers() do watch(p) end
Players.PlayerRemoving:Connect(function(p) guided[p] = nil end)

GuidedRemote.OnServerEvent:Connect(function(player, action, value)
	if type(action) ~= "string" then return end
	local state = guided[player]
	if not state then return end
	if action == "Step" and type(value) == "number" and value % 1 == 0 and value >= 1 and value <= G.Steps then
		state.step = value
	elseif action == "Done" or action == "Skip" then
		finish(player)
	end
end)

-- Si alguien se cae del patio, vuelve al punto de partida
RunService.Heartbeat:Connect(function()
	for player in guided do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < origin.Y - G.FallLimit then
			player.Character:PivotTo(yard:GetAttribute("Spawn"))
		end
	end
end)
