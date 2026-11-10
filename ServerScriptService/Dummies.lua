-- ModuleScript: ServerScriptService/Dummies
-- Muñecos de práctica (Fase 0). Usan exactamente la misma lógica de combate que los jugadores.
-- Modo global (workspace atributo "DummyMode"), se cambia desde el panel de depuración (tecla P):
--   Idle   : quieto, recibe golpes
--   Block  : mantiene la guardia (prueba drenaje de Guardia, fuertes y patadas)
--   Parry  : parrea todo lo que puede (practica fintas y esquivas)
--   Dodge  : esquiva justo antes de cada impacto
--   Attack : te persigue y hace combos M1 (practica bloqueo y parry)
--   Heavy  : te persigue y lanza fuertes (practica parry y esquiva contra el aviso naranja/rojo)
--   Mixed  : mezcla de todo
--   DirOne : (0.2, direccional) te persigue y ataca SIEMPRE por el mismo lado (workspace "DummyDir", Left por defecto)
--   DirRandom: (0.2, direccional) igual, pero cada golpe sale por un lado al azar
-- Con el direccional activo, los muñecos que bloquean o parrean ponen la guardia del lado por donde llega el golpe.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Actions = require(ServerScriptService:WaitForChild("Actions"))
local Directional = require(ServerScriptService:WaitForChild("Directional"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))

local CFG = CombatConfig
local now = Combat.now

local Dummies = {}

Dummies.Modes = { "Idle", "Block", "Parry", "Dodge", "Attack", "Heavy", "Mixed", "DirOne", "DirRandom" }
Dummies.ModeNames = {
	Idle = "Quieto", Block = "Bloquea", Parry = "Parrea", Dodge = "Esquiva",
	Attack = "Ataca (M1)", Heavy = "Fuertes", Mixed = "Mixto",
	DirOne = "Ataca por un lado", DirRandom = "Lados al azar",
}
-- Pausa entre elegir el lado y empezar el golpe (para que se lea en el triángulo)
local DIR_TELL = 0.3
local MAX_DUMMIES = 6
local TARGET_RANGE = 26   -- solo persigue a jugadores cerca de su sitio

local folder = workspace:FindFirstChild("Dummies")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Dummies"
	folder.Parent = workspace
end

workspace:SetAttribute("DummyMode", workspace:GetAttribute("DummyMode") or "Idle")
workspace:SetAttribute("DummyWeapon", workspace:GetAttribute("DummyWeapon") or "Sword")
workspace:SetAttribute("DummyDir", workspace:GetAttribute("DummyDir") or "Left")

local slots = {} -- { home = CFrame, model = Model?, brain = {} }

----------------------------------------------------------------------
-- Construcción
----------------------------------------------------------------------
local function build(home)
	local desc = Instance.new("HumanoidDescription")
	local body = Theme.Arena.DummyBody
	desc.HeadColor = body
	desc.TorsoColor = body
	desc.LeftArmColor = body
	desc.RightArmColor = body
	desc.LeftLegColor = body
	desc.RightLegColor = body

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[Dummies] No se pudo crear el muñeco:", model)
		return nil
	end
	model.Name = "Muñeco"
	-- Su script Animate es local y no corre en un NPC: lo quitamos
	local animate = model:FindFirstChild("Animate")
	if animate then animate:Destroy() end

	model:PivotTo(home)
	model.Parent = folder
	local root = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		model:Destroy()
		return nil
	end
	pcall(function() root:SetNetworkOwner(nil) end)

	model:SetAttribute("IsDummy", true)
	local weaponId = workspace:GetAttribute("DummyWeapon") or "Sword"
	Combat.setupCombatant(model, weaponId)
	model:SetAttribute("CanFight", true)
	hum.AutoRotate = false

	local tool = WeaponBuilder.build(weaponId, "Default")
	hum:EquipTool(tool)
	WeaponBuilder.addOffhand(model, weaponId, "Default")
	return model
end

----------------------------------------------------------------------
-- Inteligencia (muy simple, a propósito)
----------------------------------------------------------------------
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function findTarget(model, home)
	local best, bestDist = nil, math.huge
	local root = model:FindFirstChild("HumanoidRootPart")
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if r and root and Combat.getHum(c) and c:GetAttribute("CanFight") and Combat.isEnemy(model, c)
			and (r.Position - home.Position).Magnitude <= TARGET_RANGE then
			local d = (r.Position - root.Position).Magnitude
			if d < bestDist then
				best, bestDist = c, d
			end
		end
	end
	return best, bestDist
end

-- Próximo impacto que viene hacia el muñeco: (segundos hasta el golpe, atacante, HitAt)
local function incoming(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local t = now()
	local bestDt, bestChar, bestAt = nil, nil, nil
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		local hitAt = c and c:GetAttribute("HitAt") or 0
		if r and hitAt > t and (r.Position - root.Position).Magnitude <= 16 and Combat.isEnemy(c, model) then
			local dt = hitAt - t
			if not bestDt or dt < bestDt then
				bestDt, bestChar, bestAt = dt, c, hitAt
			end
		end
	end
	return bestDt, bestChar, bestAt
end

local function face(model, targetPos)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root or model:GetAttribute("Ragdolled") then return end
	local d = flat(targetPos - root.Position)
	if d.Magnitude < 0.5 then return end
	root.CFrame = CFrame.lookAt(root.Position, root.Position + d.Unit)
end

local function pickDefense(mode)
	if mode == "Block" or mode == "Parry" or mode == "Dodge" then return mode end
	if mode == "Mixed" then
		local r = math.random()
		if r < 0.35 then return "Block" elseif r < 0.65 then return "Parry" elseif r < 0.85 then return "Dodge" end
		return "None"
	end
	return "None"
end

local function think(slot)
	local model = slot.model
	local hum = model and Combat.getHum(model)
	local root = model and model:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	local brain = slot.brain
	local t = now()
	local mode = workspace:GetAttribute("DummyMode") or "Idle"

	-- Se cura solo tras un rato sin recibir daño
	if hum.Health < hum.MaxHealth and t - (model:GetAttribute("LastDamagedAt") or 0) >= CFG.Debug.DummyHealDelay then
		hum.Health = hum.MaxHealth
	end

	if not Combat.canAct(model) then return end

	local target, dist = findTarget(model, slot.home)

	-- Defensa ante un golpe que llega
	local dt, attacker, hitAt = incoming(model)
	-- Direccional: la guardia va del lado por donde llega el golpe (lo que haría un jugador que lee el triángulo)
	if dt and Directional.enabled() and mode ~= "DirOne" and mode ~= "DirRandom" then
		local atk = attacker:GetAttribute("AttackDir") or ""
		if atk ~= "" then Directional.setStance(model, Directional.incomingSide(atk)) end
	end
	if dt and brain.lastThreat ~= hitAt then
		local choice = brain.choice
		if brain.choiceFor ~= hitAt then
			choice = pickDefense(mode)
			brain.choice, brain.choiceFor = choice, hitAt
		end
		if choice == "Parry" and dt <= CFG.Block.ParryWindow * 0.65 then
			brain.lastThreat = hitAt
			face(model, attacker.HumanoidRootPart.Position)
			Combat.blockEnd(model, true)
			if Combat.blockStart(model, false) then
				task.delay(0.4, function()
					if model.Parent and (workspace:GetAttribute("DummyMode") ~= "Block") then
						Combat.blockEnd(model, true)
					end
				end)
			end
		elseif choice == "Dodge" and dt <= 0.18 then
			brain.lastThreat = hitAt
			local away = flat(root.Position - attacker.HumanoidRootPart.Position)
			local side = away.Magnitude > 0.1 and away.Unit:Cross(Vector3.yAxis) or root.CFrame.RightVector
			if math.random() < 0.5 then side = -side end
			Actions.dodge(model, side)
		elseif choice == "Block" and not model:GetAttribute("Blocking") then
			face(model, attacker.HumanoidRootPart.Position)
			if Combat.blockStart(model, true) and mode == "Mixed" then
				task.delay(0.8, function()
					if model.Parent and workspace:GetAttribute("DummyMode") == "Mixed" then
						Combat.blockEnd(model, true)
					end
				end)
			end
		end
	end

	if mode == "Block" then
		if not model:GetAttribute("Blocking") then Combat.blockStart(model, true) end
	elseif model:GetAttribute("Blocking") and mode ~= "Mixed" and mode ~= "Parry" then
		Combat.blockEnd(model, true)
	end

	local dirMode = mode == "DirOne" or mode == "DirRandom"
	local aggressive = mode == "Attack" or mode == "Heavy" or mode == "Mixed" or dirMode
	if target then
		face(model, target.HumanoidRootPart.Position)
	end

	if aggressive and target then
		local def = Combat.weaponOf(model)
		local reach = Actions.reach(def.combo.reach)
		if dist > reach * 0.85 then
			hum:MoveTo(target.HumanoidRootPart.Position)
		else
			hum:Move(Vector3.zero)
			if dirMode and t >= (brain.nextAttackAt or 0) and not Combat.isBusy(model) and not brain.tellAt then
				-- Elige el lado y lo muestra un instante antes de atacar
				local dirs = CFG.Directional.Dirs
				local side = mode == "DirOne" and (Directional.validDir(workspace:GetAttribute("DummyDir")) or "Left")
					or dirs[math.random(1, #dirs)]
				Directional.setStance(model, side)
				brain.tellAt = t + DIR_TELL
			end
			local ready = not dirMode or (brain.tellAt ~= nil and t >= brain.tellAt)
			if ready and t >= (brain.nextAttackAt or 0) and not Combat.isBusy(model) then
				brain.tellAt = nil
				local doHeavy = mode == "Heavy" or (mode == "Mixed" and math.random() < 0.3)
					or (dirMode and math.random() < 0.2)
				if model:GetAttribute("Blocking") then Combat.blockEnd(model, true) end
				if doHeavy then
					if Actions.heavy(model) then
						brain.nextAttackAt = t + 1.6 + math.random() * 1.2
					end
				else
					if Actions.m1(model) then
						local step = Combat.state(model).comboStep
						-- tras el 3er golpe (o al azar en Mixto) hace una pausa
						if step >= #def.combo.damage or (mode == "Mixed" and math.random() < 0.35)
							or (dirMode and math.random() < 0.3) then
							brain.nextAttackAt = t + 1.2 + math.random()
						end
					end
				end
			end
		end
	else
		-- Vuelve a su sitio
		local home = slot.home.Position
		if (flat(root.Position - home)).Magnitude > 3 then
			hum:MoveTo(home)
		elseif not target then
			face(model, home + slot.home.LookVector * 10)
		end
	end
end

----------------------------------------------------------------------
-- Gestión
----------------------------------------------------------------------
local function respawn(slot)
	if slot.model then slot.model:Destroy() end
	slot.model = build(slot.home)
	slot.brain = {}
	local model = slot.model
	if not model then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.Died:Connect(function()
		task.delay(CFG.Debug.DummyRespawn, function()
			if slot.model == model then respawn(slot) end
		end)
	end)
end

function Dummies.add(home)
	if #slots >= MAX_DUMMIES then return false end
	local slot = { home = home, model = nil, brain = {} }
	table.insert(slots, slot)
	respawn(slot)
	return true
end

function Dummies.setup(homes)
	for _, cf in homes do
		Dummies.add(cf)
	end
end

function Dummies.resetAll()
	for _, slot in slots do
		respawn(slot)
	end
end

function Dummies.setMode(mode)
	if not Dummies.ModeNames[mode] then return end
	workspace:SetAttribute("DummyMode", mode)
	for _, slot in slots do
		slot.brain = {}
		if slot.model and slot.model:GetAttribute("Blocking") then
			Combat.blockEnd(slot.model, true)
		end
	end
end

function Dummies.cycleMode()
	local current = workspace:GetAttribute("DummyMode")
	local idx = table.find(Dummies.Modes, current) or 0
	Dummies.setMode(Dummies.Modes[idx % #Dummies.Modes + 1])
end

-- Lado fijo del modo DirOne (panel de depuración)
function Dummies.setDir(dir)
	dir = Directional.validDir(dir)
	if dir then workspace:SetAttribute("DummyDir", dir) end
end

function Dummies.cycleDir()
	local dirs = CFG.Directional.Dirs
	local idx = table.find(dirs, workspace:GetAttribute("DummyDir")) or 0
	workspace:SetAttribute("DummyDir", dirs[idx % #dirs + 1])
end

function Dummies.cycleWeapon()
	local current = workspace:GetAttribute("DummyWeapon")
	local idx = table.find(WeaponData.Order, current) or 0
	workspace:SetAttribute("DummyWeapon", WeaponData.Order[idx % #WeaponData.Order + 1])
	Dummies.resetAll()
end

-- Bucle de IA (20 veces por segundo) y vigilancia de caídas
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.05 then return end
	acc = 0
	for _, slot in slots do
		local model = slot.model
		if model and model.Parent then
			local root = model:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y < slot.home.Position.Y - 40 then
				respawn(slot)
			else
				local ok, err = pcall(think, slot)
				if not ok then warn("[Dummies]", err) end
			end
		end
	end
end)

return Dummies
