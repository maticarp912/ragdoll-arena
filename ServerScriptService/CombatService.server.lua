-- Script: ServerScriptService/CombatService
-- Recibe las acciones de los jugadores y las ejecuta (el cliente solo envía intenciones).
-- También atiende el panel de depuración (tecla P), solo para quien tenga permiso.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local E=require(ReplicatedStorage:WaitForChild("Economy"))
local Collection=game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Actions = require(ServerScriptService:WaitForChild("Actions"))
local AnimTiming = require(ServerScriptService:WaitForChild("AnimTiming"))
local Dummies = require(ServerScriptService:WaitForChild("Dummies"))
local Fx = require(ServerScriptService:WaitForChild("Fx"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))

local Input = Remotes.get("Input")
local DebugRemote = Remotes.get("Debug")

AnimTiming.preload()

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function validDir(v)
	if typeof(v) ~= "Vector3" then return nil end
	for _,component in {v.X,v.Y,v.Z} do
  if component~=component or math.abs(component)==math.huge or math.abs(component)>E.MaxDirectionMagnitude then return nil end
 end
 if v.Magnitude>E.MaxDirectionMagnitude then return nil end
	local f = flat(v)
	if f.Magnitude < E.MinDirectionMagnitude then return nil end
	return f.Unit
end

----------------------------------------------------------------------
-- Entrada del jugador
----------------------------------------------------------------------
-- Límite de mensajes por jugador (anti-spam)
local rate = {}
local function allowed(player)
	local t = os.clock()
	local r = rate[player]
	if not r or t - r.start > 1 then
		rate[player] = { start = t, count = 1 }
		return true
	end
	r.count += 1
	return r.count <= 30
end
Players.PlayerRemoving:Connect(function(p) rate[p] = nil end)

-- Objetivo fijado que manda el cliente con la esquiva: solo combatientes vivos y cerca
local function validTarget(char, target)
	if typeof(target) ~= "Instance" or not target:IsA("Model") or target == char then return nil end
	if not target:IsDescendantOf(workspace) or not Collection:HasTag(target,"Combatant") then return nil end
 local tRoot, root = target:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("HumanoidRootPart")
	if not (tRoot and root and Combat.getHum(target)) then return nil end
	if (tRoot.Position - root.Position).Magnitude > CombatConfig.Controls.LockOnBreakRange then return nil end
	return target
end

Input.OnServerEvent:Connect(function(player, action, arg, extra)
	if typeof(action) ~= "string" or not allowed(player) then return end
	local char = player.Character
	if not char or not Combat.getHum(char) then return end
	if not char:FindFirstChild("HumanoidRootPart") then return end

	if action == "BlockStart" then
		Combat.blockStart(char, false)
	elseif action == "BlockEnd" then
		Combat.blockEnd(char, false)
	elseif action == "M1" then
		if char:GetAttribute("Carrying") then
			Combat.throw(char, validDir(arg)) -- tirón corto
		else
			Actions.m1(char)
		end
	elseif action == "Heavy" then
		if char:GetAttribute("Carrying") then
			Combat.throwChargeStart(char) -- mantener para cargar el lanzamiento
		else
			Actions.heavy(char)
		end
	elseif action == "HeavyRelease" then
		if char:GetAttribute("ThrowCharging") then
			Combat.throw(char, validDir(arg)) -- soltar: lanzamiento cargado
		end
	elseif action == "Dodge" then
		Actions.dodge(char, validDir(arg), validTarget(char, extra))
	elseif action == "Interact" then
		Actions.interact(char, validDir(arg))
	elseif action == "Kick" then
		Actions.kick(char)
	elseif action == "Infuse" then
		Actions.infuse(char)
	elseif action == "GetUp" then
		Combat.mashGetUp(char) -- machacar Espacio / clic / botón estando derribado
	end
end)

----------------------------------------------------------------------
-- Sin bloqueo de ratón con Shift (Shift es la esquiva)
----------------------------------------------------------------------
local function canDebug(player)
	if RunService:IsStudio() then return true end
	if CombatConfig.Debug.AllowInLiveGame then return true end
	if player.UserId == game.CreatorId then return true end
	return table.find(CombatConfig.Debug.AllowedUserIds, player.UserId) ~= nil
end

local function onPlayer(player)
	player.DevEnableMouseLock = false
	player:SetAttribute("DebugAllowed", canDebug(player))
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end

----------------------------------------------------------------------
-- Panel de depuración
----------------------------------------------------------------------
local debugAt={}
Players.PlayerRemoving:Connect(function(player) debugAt[player]=nil end)
DebugRemote.OnServerEvent:Connect(function(player, action, arg)
 local now=os.clock()
 if debugAt[player] and now-debugAt[player]<E.DebugInterval then return end
 debugAt[player]=now
	if typeof(action) ~= "string" or not canDebug(player) then return end
	local char = player.Character

	if action == "GoArena" or action == "TestCrumble" then
  require(script.Parent:WaitForChild("ArenaBuilder")).debug(player, action == "TestCrumble")
 elseif action == "ToggleHitboxes" then
		workspace:SetAttribute("DebugHitboxes", not workspace:GetAttribute("DebugHitboxes"))
	elseif action == "DummyMode" then
		if typeof(arg) == "string" then Dummies.setMode(arg) else Dummies.cycleMode() end
	elseif action == "DummyWeapon" then
		Dummies.cycleWeapon()
	elseif action == "ResetDummies" then
		Dummies.resetAll()
	elseif action == "SpawnDummy" then
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local pos = root.Position + root.CFrame.LookVector * 10
			if not Dummies.add(CFrame.lookAt(pos, root.Position * Vector3.new(1, 0, 1) + Vector3.new(0, pos.Y, 0))) then
				Fx.toast(player, { key = "toast.maxDummies" })
			end
		end
	elseif action == "FillCharge" then
		if char then char:SetAttribute("InfusionCharge", CombatConfig.InfusionCharge.Max) end
	elseif action == "Heal" then
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hum.Health = hum.MaxHealth
			char:SetAttribute("Stun", 0)
			char:SetAttribute("Guard", char:GetAttribute("GuardMax") or 100)
			char:SetAttribute("Stamina", char:GetAttribute("StaminaMax") or 100)
		end
	elseif action == "PracticeOnly" then
		-- No entrar en la cola de partidas: quedarse practicando en el lobby
		player:SetAttribute("PracticeOnly", not player:GetAttribute("PracticeOnly"))
	end
end)
