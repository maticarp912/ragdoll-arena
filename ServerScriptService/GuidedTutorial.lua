-- Patio privado del tutorial de primera entrada. MatchService lo asigna al terminar el spawn.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Dummies = require(ServerScriptService:WaitForChild("Dummies"))
local Infusion = require(ServerScriptService:WaitForChild("Infusion"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local G = require(ReplicatedStorage:WaitForChild("CityConfig")).GuidedTutorial

local GuidedTutorial = {}
local sessions, occupied = {}, {}
local yards = Instance.new("Folder")
yards.Name = "TrainingYards"
yards.Parent = workspace

local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeYard(player, origin)
	local yard = Instance.new("Model")
	yard.Name = tostring(player.UserId)
	part(yard, "YardFloor", Vector3.new(G.Size, 2, G.Size), origin - Vector3.yAxis, G.Floor, Enum.Material.Cobblestone)
	for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
		local size = Vector3.new(2, G.WallHeight, 2) + Vector3.new(math.abs(side.Z), 0, math.abs(side.X)) * (G.Size - 2)
		part(yard, "YardWall", size, origin + side * G.Size / 2 + Vector3.yAxis * G.WallHeight / 2, G.Wall, Enum.Material.Slate)
	end
	for _, corner in { Vector3.new(1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(-1, 0, -1) } do
		local base = origin + corner * (G.Size / 2 - 3)
		part(yard, "YardPillar", Vector3.new(3, G.PillarHeight, 3), base + Vector3.yAxis * G.PillarHeight / 2, G.Wall, Enum.Material.Slate)
		local flame = part(yard, "YardTorch", Vector3.new(1.2, 1.6, 1.2), base + Vector3.yAxis * (G.PillarHeight + 0.8), G.Torch, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Color = G.Torch
		light.Range = G.TorchRange
		light.Brightness = G.TorchBrightness
		light.Parent = flame
	end
	local marker = part(yard, "TutorialMarker", Vector3.new(0.3, G.MarkerSize, G.MarkerSize), origin + G.MarkerOffset, G.Marker, Enum.Material.Neon)
	marker.Shape = Enum.PartType.Cylinder
	marker.Orientation = Vector3.new(0, 0, 90)
	marker.Transparency = 0.35
	marker.CanCollide = false
	yard.Parent = yards
	return yard
end

local function createSession(player)
	local slot = 0
	while occupied[slot] do slot += 1 end
	occupied[slot] = true
	local origin = G.Origin + Vector3.new(slot % G.YardColumns, 0, math.floor(slot / G.YardColumns)) * G.YardSpacing
	local state = {
		slot = slot,
		origin = origin,
		yard = makeYard(player, origin),
		spawn = CFrame.lookAt(origin + G.SpawnOffset, origin + G.MarkerOffset),
		step = 1,
		dummies = {},
	}
	sessions[player] = state

	local function addDummy(offset, mode)
		local home = CFrame.lookAt(origin + offset, origin + G.SpawnOffset)
		local _, dummy = Dummies.add(home, mode, player.UserId)
		table.insert(state.dummies, dummy)
	end
	for _, offset in G.DummyOffsets do addDummy(offset, "Idle") end
	addDummy(G.BotOffset, function()
		local lesson = G.Steps[state.step]
		-- 12/11/2026: cada golpe del bot sale por un lado al azar (antes siempre el mismo), y lo anuncia antes
		return (lesson == "block" or lesson == "parry") and "DirRandom" or "Idle"
	end)
	return state
end

local function removeSession(player)
	local state = sessions[player]
	if not state then return end
	sessions[player] = nil
	if state.healthConnection then state.healthConnection:Disconnect() end
	for _, dummy in state.dummies do Dummies.remove(dummy) end
	state.yard:Destroy()
	occupied[state.slot] = nil
end

function GuidedTutorial.arrive(player, char)
	local data = PlayerData.get(player)
	if not data or data.TutorialGuidedDone or not player.Parent then return end
	-- Quienes ya jugaban antes de esta versión conservan el acceso directo a la ciudad.
	if not sessions[player] and ((data.Level or 1) > 1 or ((data.Stats and data.Stats.Matches) or 0) > 0) then
		data.TutorialGuidedDone = true
		return
	end

	local state = sessions[player] or createSession(player)
	if state.healthConnection then state.healthConnection:Disconnect() end
	char:SetAttribute("TutorialOwnerUserId", player.UserId)
	char:PivotTo(state.spawn)
	if G.Steps[state.step] == "infuse" then char:SetAttribute("InfusionCharge", CombatConfig.InfusionCharge.Max) end
	local hum = char:FindFirstChildOfClass("Humanoid")
	state.healthConnection = hum.HealthChanged:Connect(function(hp)
		if sessions[player] == state and player.Character == char and not player:GetAttribute("InMatch")
			and hp > 0 and hp < hum.MaxHealth * G.MinHealth then
			hum.Health = hum.MaxHealth * G.RefillHealth
		end
	end)
	player:SetAttribute("InTutorial", true)
end

local function finish(player)
	local data = PlayerData.get(player)
	if data then
		data.TutorialGuidedDone = true
		PlayerData.saveSoon(player)
	end
	local char = player.Character
	if char then
		if char:GetAttribute("Carrying") then Combat.drop(char, "drop") end
		if char:GetAttribute("InfusionActive") then Infusion.deactivate(char) end
		char:SetAttribute("InfusionCharge", 0)
		char:SetAttribute("InfusionLockUntil", 0)
		local spawn = workspace:GetAttribute("LobbySpawn")
		if typeof(spawn) == "CFrame" then char:PivotTo(spawn) end
		char:SetAttribute("TutorialOwnerUserId", nil)
	end
	removeSession(player)
	player:SetAttribute("InTutorial", false)
end

Players.PlayerRemoving:Connect(removeSession)
Remotes.get("GuidedTutorial").OnServerEvent:Connect(function(player, action, value)
	if type(action) ~= "string" then return end
	local state = sessions[player]
	if not state or player:GetAttribute("InMatch") then return end
	if action == "Step" and type(value) == "number" and value == state.step + 1 and G.Steps[value] then
		state.step = value
		local char = player.Character
		if G.Steps[value] == "infuse" and char then char:SetAttribute("InfusionCharge", CombatConfig.InfusionCharge.Max) end
	elseif action == "Done" or action == "Skip" then
		finish(player)
	end
end)

RunService.Heartbeat:Connect(function()
	for player, state in sessions do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and Combat.getHum(char) and char:GetAttribute("TutorialOwnerUserId") == player.UserId
			and root.Position.Y < state.origin.Y - G.FallLimit then
			char:PivotTo(state.spawn)
		end
	end
end)

return GuidedTutorial
