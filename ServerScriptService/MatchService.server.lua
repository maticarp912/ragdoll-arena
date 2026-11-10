-- Script: ServerScriptService/MatchService
-- Cola, equipos, rondas al mejor de 3, dos arenas (2v2 grande y 1v1 pequeña) y monedas.
-- Una ronda se gana eliminando a todo el equipo rival:
--   un jugador queda eliminado al caer de la arena O al llegar su vida a 0.
-- La arena está hecha de baldosas que se desmoronan de fuera hacia dentro.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Lighting = game:GetService("Lighting")

local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Dummies = require(ServerScriptService:WaitForChild("Dummies"))
require(ServerScriptService:WaitForChild("Remotes"))

local ArenaConfig = require(ReplicatedStorage:WaitForChild("ArenaConfig"))
local ArenaBuilder = require(ServerScriptService:WaitForChild("ArenaBuilder"))
local Stats = require(ServerScriptService:WaitForChild("StatsService"))
local CombatEvents = require(ServerScriptService:WaitForChild("CombatEvents"))
local E = require(ReplicatedStorage:WaitForChild("Economy"))
local RunService = game:GetService("RunService")
local RoleService = require(ServerScriptService:WaitForChild("RoleService"))
local Progression = require(ServerScriptService:WaitForChild("ProgressionService"))
require(ServerScriptService:WaitForChild("AdminService"))
local function phase(name, duration, group)
 local ends = workspace:GetServerTimeNow() + (duration or 0)
 workspace:SetAttribute("PhaseEnds", ends) workspace:SetAttribute("MatchPhase", name)
 for _, p in Players:GetPlayers() do if p:GetAttribute("InMatch") then p:SetAttribute("MatchPhase", name) p:SetAttribute("PhaseEnds", ends) end end
 for _, player in group or {} do player:SetAttribute("MatchPhase", name) player:SetAttribute("PhaseEnds", ends) end
end
phase("Lobby")
local CONFIG = ArenaConfig.Match
local MODES = ArenaConfig.Modes

Players.CharacterAutoLoads = false

----------------------------------------------------------------------
-- Iluminación dark fantasy (valores en Theme.Lighting)
----------------------------------------------------------------------
local envModule = ReplicatedStorage:FindFirstChild("Environment")
local envOk = false
if envModule then
	envOk = pcall(function() require(envModule).apply() end)
	if not envOk then warn("[MatchService] Environment.apply falló; uso la iluminación básica") end
end
if not envOk then
	do
		local L = Theme.Lighting
		Lighting.ClockTime = L.ClockTime
		Lighting.Brightness = L.Brightness
		Lighting.Ambient = L.Ambient
		Lighting.OutdoorAmbient = L.OutdoorAmbient
		Lighting.ExposureCompensation = L.ExposureCompensation
		local function ensure(className)
			local obj = Lighting:FindFirstChildOfClass(className)
			if not obj then
				obj = Instance.new(className)
				obj.Parent = Lighting
			end
			return obj
		end
		local atm = ensure("Atmosphere")
		for k, v in L.Atmosphere do atm[k] = v end
		local cc = ensure("ColorCorrectionEffect")
		for k, v in L.ColorCorrection do cc[k] = v end
		local bloom = ensure("BloomEffect")
		for k, v in L.Bloom do bloom[k] = v end
	end
end

----------------------------------------------------------------------
-- Equipos
----------------------------------------------------------------------
local function makeTeam(name, color)
	local t = Instance.new("Team")
	t.Name = name
	t.TeamColor = BrickColor.new(color)
	t.AutoAssignable = false
	t.Parent = Teams
	return t
end

local TeamObjs = {
	Red = makeTeam("Red", "Bright red"),
	Blue = makeTeam("Blue", "Bright blue"),
}

----------------------------------------------------------------------
-- Mapas de prueba (puedes sustituirlos por los tuyos)
----------------------------------------------------------------------
local map = Instance.new("Folder")
map.Name = "GeneratedMap"
map.Parent = workspace

local function newPart(name, size, position, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Color = color
	p.Material = Theme.Arena.Material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or map
	return p
end

-- Lobby: el de LobbyBuilder (estética de pueblo de fantasía) si existe; si no, el básico
local lobbyCFrame, dummyHomes
local lobbyInfo = nil
local lobbyModule = ServerScriptService:FindFirstChild("LobbyBuilder")
if lobbyModule then
	local ok, res = pcall(function() return require(lobbyModule).build(map) end)
	if ok and type(res) == "table" and typeof(res.spawn) == "CFrame" then
		lobbyInfo = res
	else
		warn("[MatchService] LobbyBuilder falló, uso el lobby básico:", res)
	end
end
if lobbyInfo then
	lobbyCFrame = lobbyInfo.spawn
	dummyHomes = lobbyInfo.dummyHomes or {}
else
	local lobbyPos = Vector3.new(-450, 50, 0)
	local lobbyFloor = newPart("LobbyFloor", Vector3.new(80, 2, 80), lobbyPos, Theme.Arena.Lobby)
	lobbyFloor.Material = Theme.Arena.LobbyMaterial
	lobbyCFrame = CFrame.new(lobbyPos + Vector3.new(0, 4, 0))

	-- Zona de práctica junto al lobby: muñecos para probar el combate con 1 solo jugador
	local practicePos = lobbyPos + Vector3.new(70, 0, 0)
	newPart("PracticeFloor", Vector3.new(60, 2, 60), practicePos, Theme.Arena.Practice)
	newPart("PracticeBridge", Vector3.new(12, 2, 10), lobbyPos + Vector3.new(40 + 1, 0, 0), Theme.Arena.Lobby)
	do
		local sign = newPart("PracticeSign", Vector3.new(0.5, 6, 16), practicePos + Vector3.new(29, 5, 0), Theme.Colors.Panel)
		sign.CanCollide = false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Left
		gui.CanvasSize = Vector2.new(400, 150)
		gui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "ZONA DE PRÁCTICA\nP: panel de depuración"
		label.TextColor3 = Theme.Colors.Gold
		label.Font = Theme.Fonts.Title
		label.TextScaled = true
		label.Parent = gui
	end
	dummyHomes = {}
	for i, z in { -14, 0, 14 } do
		local pos = practicePos + Vector3.new(10, 4, z)
		dummyHomes[i] = CFrame.lookAt(pos, Vector3.new(lobbyPos.X, pos.Y, pos.Z))
	end

	-- Braseros: fuego y luz cálida (ambientación dark fantasy)
	local function brazier(pos)
		local base = newPart("BrazierBase", Vector3.new(1.6, 3, 1.6), pos + Vector3.new(0, 1.5, 0), Theme.Colors.Charcoal)
		base.Shape = Enum.PartType.Cylinder
		base.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		base.Material = Enum.Material.CorrodedMetal
		local bowl = newPart("BrazierBowl", Vector3.new(0.8, 3, 3), pos + Vector3.new(0, 3.3, 0), Theme.Colors.Charcoal)
		bowl.Shape = Enum.PartType.Cylinder
		bowl.CFrame = CFrame.new(pos + Vector3.new(0, 3.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		bowl.Material = Enum.Material.CorrodedMetal
		local coals = newPart("Coals", Vector3.new(0.3, 2.4, 2.4), pos + Vector3.new(0, 3.75, 0), Color3.fromRGB(255, 110, 40))
		coals.Shape = Enum.PartType.Cylinder
		coals.CFrame = CFrame.new(pos + Vector3.new(0, 3.75, 0)) * CFrame.Angles(0, 0, math.rad(90))
		coals.Material = Enum.Material.Neon
		local fire = Instance.new("Fire")
		fire.Size = 6
		fire.Heat = 9
		fire.Color = Color3.fromRGB(255, 120, 40)
		fire.SecondaryColor = Color3.fromRGB(120, 30, 10)
		fire.Parent = coals
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 80)
		light.Brightness = 2.2
		light.Range = 26
		light.Shadows = true
		light.Parent = coals
		for _, p in { base, bowl, coals } do
			p.CanQuery = false
		end
	end
	local floorTop = lobbyPos.Y + 1
	for _, offset in { Vector3.new(-36, 0, -36), Vector3.new(-36, 0, 36), Vector3.new(36, 0, -36), Vector3.new(36, 0, 36) } do
		brazier(Vector3.new(lobbyPos.X + offset.X, floorTop, lobbyPos.Z + offset.Z))
	end
	for _, offset in { Vector3.new(26, 0, -26), Vector3.new(26, 0, 26), Vector3.new(-6, 0, -26), Vector3.new(-6, 0, 26) } do
		brazier(Vector3.new(practicePos.X + offset.X, floorTop, practicePos.Z + offset.Z))
	end
end

local arenas = {}      -- [modo] = { folder, tiles, byRing, maxRing, token, crumbling }
local spawnPoints = {} -- [modo][equipo] = lista de CFrames

for modeName, mode in MODES do
 arenas[modeName] = ArenaBuilder.build(map, modeName, mode)
 local red, blue = {}, {}
 for i = 1, mode.perTeam do
  local z = mode.perTeam == 1 and 0 or (i % 2 == 0 and 1 or -1)*mode.radius*ArenaConfig.SpawnLane
  local function spawn(sign)
   local pos = mode.center+Vector3.new(sign*mode.radius*ArenaConfig.SpawnFraction, ArenaConfig.SpawnHeight, z)
   return CFrame.lookAt(pos, Vector3.new(mode.center.X, pos.Y, mode.center.Z))
  end
  table.insert(red, spawn(-1)) table.insert(blue, spawn(1))
 end
 spawnPoints[modeName] = { Red = red, Blue = blue }
end
local function resetArena(modeName)
 ArenaBuilder.reset(arenas[modeName])
end
local function runCrumble(modeName, token)
 ArenaBuilder.run(arenas[modeName], token)
end

----------------------------------------------------------------------
-- Utilidades
----------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local function setStatus(key: string, params)
 workspace:SetAttribute("StatusParams", HttpService:JSONEncode(params or {}))
 workspace:SetAttribute("StatusKey", key)
end

local function shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

local spawnInLobby -- declaración adelantada

local function watchDeath(player: Player, char: Model, hum: Humanoid)
	hum.Died:Connect(function()
		if player:GetAttribute("InMatch") then player:SetAttribute("Eliminated", true) end
		Ragdoll.enable(char, nil, true)
		if not player:GetAttribute("InMatch") then
			task.delay(3, function()
				if player.Parent and not player:GetAttribute("InMatch") then
					spawnInLobby(player)
				end
			end)
		end
	end)
end

-- Cuerpo más esbelto (9/11, pedido del usuario): se aparece con el aspecto del jugador pero con
-- las proporciones de CombatConfig.Body. Si no se puede leer su apariencia, se usa la normal.
local bodyCache = {}
Players.PlayerRemoving:Connect(function(p) bodyCache[p] = nil end)
local function loadCharacter(player: Player)
	local B = CombatConfig.Body
	local desc = bodyCache[player]
	if desc == nil and B and B.Enabled then
		local ok, d = pcall(function() return Players:GetHumanoidDescriptionFromUserId(math.max(1, player.UserId)) end)
		desc = ok and d or false
		if desc then
			for key, value in B.Scales do desc[key] = value end
		end
		bodyCache[player] = desc
	end
	if desc then
		local ok = pcall(function() player:LoadCharacterWithHumanoidDescription(desc:Clone()) end)
		if ok and player.Character then return end
	end
	player:LoadCharacter()
end

local function spawnAt(player: Player, cf: CFrame)
	loadCharacter(player)
	local char = player.Character
	if not char then return nil, nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil, nil end
	char:PivotTo(cf)
	Combat.setupCharacter(player, char)
	watchDeath(player, char, hum)
	return char, hum
end

function spawnInLobby(player: Player)
	local char = spawnAt(player, lobbyCFrame)
	-- En el lobby se puede pelear, pero solo contra los muñecos (Combat.isEnemy evita el PvP)
	if char then char:SetAttribute("CanFight", true) end
end

----------------------------------------------------------------------
-- Rondas y partidas
----------------------------------------------------------------------
local function runRound(roundNumber: number, modeName: string, teamsMap)
	local mode = MODES[modeName]
	local arena = arenas[modeName]
	local voidY = mode.center.Y - CONFIG.VoidDrop

	resetArena(modeName)
	local fighters = {}
 local connections = {}
 local lastEliminated
 local function eliminate(f, at)
  if f.eliminatedAt then return end
  f.eliminatedAt = at f.player:SetAttribute("Eliminated", true)
  if not lastEliminated or at > lastEliminated.eliminatedAt or (at == lastEliminated.eliminatedAt and f.player.UserId > lastEliminated.player.UserId) then lastEliminated = f end
 end

	for teamName, list in teamsMap do
		for i, player in list do
			if player.Parent then
				player:SetAttribute("Eliminated", false)
				local char, hum = spawnAt(player, spawnPoints[modeName][teamName][i])
				if char and hum then
					char:SetAttribute("Frozen", true)
					Combat.refreshSpeed(char)
					local f = { player = player, team = teamName, char = char, hum = hum }
     table.insert(fighters, f)
     table.insert(connections, hum.HealthChanged:Connect(function(health) if health <= 0 then eliminate(f, os.clock()) end end))
				end
			end
		end
	end

	if roundNumber == 1 then
  phase("Cinematic", E.CinematicTime, nil)
  task.wait(E.CinematicTime)
 end
 phase("Round", CONFIG.RoundTime + CONFIG.Countdown)
 for i = CONFIG.Countdown, 1, -1 do
		setStatus("cx.match.prepare", { round = roundNumber, seconds = i })
		task.wait(1)
	end

	for _, f in fighters do
  f.player:SetAttribute("MatchPhase", "Round")
		if f.hum.Parent then
			f.char:SetAttribute("Frozen", false)
			f.char:SetAttribute("CanFight", true)
			Combat.refreshSpeed(f.char)
		end
	end

	task.spawn(runCrumble, modeName, arena.token)

	local endTime = os.clock() + CONFIG.RoundTime
	local winner = nil
	local lastText = ""

	while true do
		local alive = { Red = 0, Blue = 0 }
		local health = { Red = 0, Blue = 0 }

  local now = os.clock()
  -- Sample every Heartbeat. Interpolate void crossings within the last frame;
  -- an exactly simultaneous crossing uses UserId as a stable, documented tie-break.
  for _, f in fighters do
   local root = f.char:FindFirstChild("HumanoidRootPart")
   if not f.eliminatedAt then
    if not f.player.Parent or not f.hum.Parent or not root then eliminate(f, now)
    elseif root.Position.Y < voidY then
     local at = now
     if f.previousY and f.previousY >= voidY and f.previousY > root.Position.Y then
      at = f.previousAt + (now - f.previousAt) * (f.previousY - voidY) / (f.previousY - root.Position.Y)
     end
     eliminate(f, at)
     CombatEvents.fire("RingOut", CombatEvents.lastAttacker(f.char), f.char)
     f.hum.Health = 0
    elseif f.hum.Health <= 0 or f.player:GetAttribute("Eliminated") then eliminate(f, now)
    else alive[f.team] += 1 health[f.team] += f.hum.Health end
   end
   f.previousY = root and root.Position.Y f.previousAt = now
  end

		if alive.Red == 0 and alive.Blue == 0 then
   winner = lastEliminated and lastEliminated.team
			break
		elseif alive.Red == 0 then
			winner = "Blue"
			break
		elseif alive.Blue == 0 then
			winner = "Red"
			break
		end

		local remaining = math.ceil(endTime - os.clock())
		if remaining <= 0 then
			if health.Red > health.Blue then winner = "Red"
			elseif health.Blue > health.Red then winner = "Blue" end
			break
		end

		local key = arena.crumbling and "cx.match.crumbling" or "cx.match.round"
  local stamp = HttpService:JSONEncode({ roundNumber, alive.Red, alive.Blue, remaining, key })
  if stamp ~= lastText then
   lastText = stamp
   setStatus(key, { round = roundNumber, red = alive.Red, blue = alive.Blue, seconds = remaining })
  end
		RunService.Heartbeat:Wait()
	end

	for _, connection in connections do connection:Disconnect() end
 phase("RoundEnd", E.RoundEndTime)
 arena.token += 1 -- detiene el derrumbe
	for _, f in fighters do
		f.char:SetAttribute("CanFight", false)
		Combat.drop(f.char)
		-- La carga de infusión pasa a la ronda siguiente (si estaba encendida, ya se gastó)
		if f.player.Parent then
			local charge = f.char:GetAttribute("InfusionActive") and 0 or (f.char:GetAttribute("InfusionCharge") or 0)
			f.player:SetAttribute("MatchInfusionCharge", charge)
		end
	end
	return winner
end

local variantCursor = {}
local function runMatch(group, modeName: string)
 local old = arenas[modeName]
 old.token += 1
 -- Falling slabs can be temporarily unparented; explicitly dispose those too.
 for _,tile in old.tiles do for _,piece in tile.pieces do piece:Destroy() end end
 old.folder:Destroy()
 local index = (variantCursor[modeName] or 0) % #ArenaConfig.Variants + 1
 variantCursor[modeName] = index
 arenas[modeName] = ArenaBuilder.build(map,modeName,MODES[modeName],ArenaConfig.Variants[index])
 workspace:SetAttribute("ArenaVariant" .. modeName,ArenaConfig.Variants[index])
	shuffle(group)
	local teamsMap = { Red = {}, Blue = {} }
	for i, player in group do
		local teamName = (i % 2 == 1) and "Red" or "Blue"
		table.insert(teamsMap[teamName], player)
		player.Team = TeamObjs[teamName]
		player:SetAttribute("InMatch", true)
		player:SetAttribute("MatchInfusionCharge", 0) -- cada partida empieza sin carga
	end

	phase("Prematch", math.max(E.MinPrematchTime, E.PrematchTime), group)
 for _, player in group do if player.Character then player.Character:SetAttribute("CanFight", false) player.Character:SetAttribute("Frozen", true) Combat.refreshSpeed(player.Character) end end
 task.wait(math.max(E.MinPrematchTime, E.PrematchTime))
 -- Lock BEFORE any yielding character loads. Cinematic timer starts after spawning.
 phase("Cinematic", nil, group)
 Stats.begin(group, modeName)
	local wins = { Red = 0, Blue = 0 }
	local round = 0
	while wins.Red < CONFIG.RoundsToWin and wins.Blue < CONFIG.RoundsToWin and round < CONFIG.MaxRounds do
		round += 1
		local winner = runRound(round, modeName, teamsMap)
		if winner then wins[winner] += 1 end
		setStatus(winner and "cx.match.point" or "cx.match.draw", { teamKey = winner and "team." .. winner, red = wins.Red, blue = wins.Blue })
		task.wait(E.RoundEndTime)
	end

	local matchWinner = nil
	if wins.Red > wins.Blue then matchWinner = "Red" elseif wins.Blue > wins.Red then matchWinner = "Blue" end
	if matchWinner then
		setStatus("cx.match.winner", { teamKey = "team." .. matchWinner })
	end

	phase("Summary", E.SummaryTime, group)
	for teamName, list in teamsMap do
		for _, player in list do
			if player.Parent then
				Stats.finish(player, teamName == matchWinner)
			end
		end
	end
	task.wait(E.SummaryTime)

	for _, player in group do
		if player.Parent then
			player:SetAttribute("InMatch", false)
   player:SetAttribute("MatchPhase", "Lobby")
			player:SetAttribute("Eliminated", false)
			player.Team = nil
			spawnInLobby(player)
		end
	end
	resetArena(modeName)
 phase("Lobby")
end

----------------------------------------------------------------------
-- Jugadores y cola
----------------------------------------------------------------------
local function setupPlayer(player: Player)
	player:SetAttribute("InMatch", false)
	PlayerData.load(player)
	if PlayerData.get(player) and player.Parent then RoleService.refresh(player) Progression.refresh(player) spawnInLobby(player) end
end

Dummies.setup(dummyHomes)

Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(setupPlayer, p)
end

-- Colas por círculos de la antesala (LobbyBuilder.queueZones). Sin círculos (lobby básico): cola automática.
local QUEUE_NEED = { ["1v1"] = 2, ["2v2"] = 4 }

-- Botones de cola (Lobby.client): entrar o salir de la cola sin ir a los círculos
local queueRequests = {} -- [jugador] = "1v1" | "2v2"
local QueueRemote = require(ServerScriptService:WaitForChild("Remotes")).get("Queue")
local queueAt = {}
Players.PlayerRemoving:Connect(function(p) queueAt[p] = nil end)
QueueRemote.OnServerEvent:Connect(function(player, action, mode)
 local now = os.clock()
 if queueAt[player] and now - queueAt[player] < E.QueueInterval then return end
 queueAt[player] = now
	if type(action) ~= "string" then return end
	if action == "Join" and type(mode) == "string" and QUEUE_NEED[mode] and not player:GetAttribute("InMatch") then
		queueRequests[player] = mode
	elseif action == "Leave" then
		queueRequests[player] = nil
	end
end)
Players.PlayerRemoving:Connect(function(p) queueRequests[p] = nil end)

local function playersInZone(zone)
	local list = {}
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 and not p:GetAttribute("InMatch") and PlayerData.get(p) then
			local d = (root.Position - zone.center) * Vector3.new(1, 0, 1)
			if d.Magnitude <= zone.radius and math.abs(root.Position.Y - zone.center.Y) < 8 then
				table.insert(list, p)
			end
		end
	end
	return list
end

task.spawn(function()
	local zones = lobbyInfo and lobbyInfo.queueZones
	local waitedSince = nil
	while true do
		if zones then
			-- Quién está en cada círculo
   local queued = { ["1v1"] = {}, ["2v2"] = {} }
   local physical = {}
   -- Resolve every circle before considering any button request. One player, one queue.
   for _, mode in { "1v1", "2v2" } do
    local zone = zones[mode]
    if zone then
     for _, p in playersInZone(zone) do
      if not physical[p] then
       physical[p] = mode
       queueRequests[p] = nil
       table.insert(queued[mode], p)
      end
     end
    end
   end
   for p, mode in queueRequests do
    local char = p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not physical[p] and queued[mode] and p.Parent and hum and hum.Health > 0 and not p:GetAttribute("InMatch") and PlayerData.get(p) then
     table.insert(queued[mode], p)
    end
   end
   for mode, list in queued do
    for _, p in list do p:SetAttribute("QueueMode", mode) end
    local zone = zones[mode]
    if zone and zone.label then zone.label.Text = ("%d / %d"):format(#list, QUEUE_NEED[mode]) end
    workspace:SetAttribute("QueueCount" .. mode, #list)
   end
			for _, p in Players:GetPlayers() do
				local mode = p:GetAttribute("QueueMode")
				if mode and not (queued[mode] and table.find(queued[mode], p)) then p:SetAttribute("QueueMode", nil) end
			end
			if #queued["2v2"] >= QUEUE_NEED["2v2"] then
				local g = queued["2v2"]
				for i = 1, 4 do queueRequests[g[i]] = nil g[i]:SetAttribute("QueueMode", nil) end
				runMatch({ g[1], g[2], g[3], g[4] }, "2v2")
			elseif #queued["1v1"] >= QUEUE_NEED["1v1"] then
				local g = queued["1v1"]
				for i = 1, 2 do queueRequests[g[i]] = nil g[i]:SetAttribute("QueueMode", nil) end
				runMatch({ g[1], g[2] }, "1v1")
			else
				setStatus("cx.match.queue")
				task.wait(0.5)
			end
		else
			local waiting = {}
			for _, p in Players:GetPlayers() do
				if not p:GetAttribute("InMatch") and not p:GetAttribute("PracticeOnly") and p.Character and PlayerData.get(p) then
					table.insert(waiting, p)
				end
			end
			if #waiting >= 4 then
				waitedSince = nil
				runMatch({ waiting[1], waiting[2], waiting[3], waiting[4] }, "2v2")
			elseif #waiting >= 2 then
				waitedSince = waitedSince or os.clock()
				local left = math.ceil(CONFIG.Wait1v1 - (os.clock() - waitedSince))
				if left <= 0 then
					waitedSince = nil
					runMatch({ waiting[1], waiting[2] }, "1v1")
				else
					setStatus("cx.match.waitDuel", { count = #waiting, seconds = left })
					task.wait(1)
				end
			else
				waitedSince = nil
				setStatus("cx.match.waiting", { count = #waiting })
				task.wait(1)
			end
		end
	end
end)
