-- ModuleScript: ServerScriptService/Directional
-- Responsable: Claude (0.2). Combate direccional en el servidor (Notas/Arquitectura Combate Direccional.md).
-- Todo está detrás de CombatConfig.Directional.Enabled; con false, Combat y Actions siguen como en la 0.1.
--
-- Contrato C16 (atributos del Model del personaje, los leen DirectionalHUD, el HUD de Gemini y Codex):
--   CombatState : Neutral, Windup, Active, Recovery, Guard, ParryWindow, Parried, Kick, GuardBroken,
--                 Staggered, Dodge, Downed, Carried
--   Stance      : Up, Left o Right (la postura queda hasta que se elige otra)
--   AttackDir   : dirección del golpe en curso ("" si no hay), en el marco DEL ATACANTE
--   StateEnds   : workspace:GetServerTimeNow() en que termina el estado (0 = sin fin)
--
-- Convención de lados: los dos luchadores se miran de frente. Un golpe que el atacante lanza por SU izquierda
-- llega por la DERECHA del defensor. Para bloquear, el defensor pone su postura en el lado por donde llega:
-- Directional.incomingSide(AttackDir). El triángulo del defensor muestra el aviso rojo en ese mismo lado.
--
-- La máquina de estados se deriva cada frame de las compuertas que ya existen (Action, ActionPhase, Blocking,
-- StunnedUntil, KnockedDown...): así nunca queda desincronizada de lo que el servidor permite. Las transiciones
-- se validan donde ya se validaban (Combat.canAct, busyUntil, GuardBrokenUntil); este módulo agrega la postura,
-- la resolución por lado y el parry con margen de ping.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))

local D = CombatConfig.Directional
local Directional = {}

local VALID = { Up = true, Left = true, Right = true }
local MIRROR = { Up = "Up", Left = "Right", Right = "Left" }

local data = setmetatable({}, { __mode = "k" }) -- [char] = { prev, changedAt, stanceTimes, pending }

local function now()
	return workspace:GetServerTimeNow()
end

local function get(char)
	local d = data[char]
	if not d then
		d = { prev = nil, changedAt = 0, stanceCount = 0, stanceWindow = 0, pending = {} }
		data[char] = d
	end
	return d
end

function Directional.enabled()
	return D.Enabled == true
end

-- Dirección válida o nil (el servidor descarta cualquier otro valor sin aviso)
function Directional.validDir(v)
	if typeof(v) == "string" and VALID[v] then return v end
	return nil
end

-- Lado por el que llega al defensor un golpe lanzado con esta dirección
function Directional.incomingSide(attackDir)
	return MIRROR[attackDir or ""] or "Up"
end

function Directional.setup(char)
	data[char] = nil
	char:SetAttribute("Stance", D.DefaultStance)
	char:SetAttribute("AttackDir", "")
	char:SetAttribute("CombatState", "Neutral")
	char:SetAttribute("StateEnds", 0)
	char:SetAttribute("ParriedUntil", 0)
	char:SetAttribute("GuardBrokenStateUntil", 0)
end

----------------------------------------------------------------------
-- Postura
----------------------------------------------------------------------
-- Cambia la postura. Devuelve true si se aceptó. No se puede en el suelo ni cargado.
function Directional.setStance(char, dir)
	dir = Directional.validDir(dir)
	if not dir then return false end
	if char:GetAttribute("KnockedDown") or char:GetAttribute("Ragdolled") or char:GetAttribute("CarriedBy")
		or char:GetAttribute("Frozen") then
		return false
	end
	local d = get(char)
	local t = now()
	-- Límite de cambios por segundo (el remoto ya limita a 30 mensajes/s en total)
	if t - d.stanceWindow > 1 then
		d.stanceWindow = t
		d.stanceCount = 0
	end
	d.stanceCount += 1
	if d.stanceCount > D.StanceMaxRate then return false end

	local current = char:GetAttribute("Stance") or D.DefaultStance
	if current == dir then return true end
	d.prev = current
	d.changedAt = t
	char:SetAttribute("Stance", dir)
	return true
end

-- Lado que cubre la guardia AHORA: durante SwitchTime sigue cubriendo el lado anterior
function Directional.guardSide(char)
	local d = get(char)
	local stance = char:GetAttribute("Stance") or D.DefaultStance
	local mult = WeaponData.directional(char:GetAttribute("WeaponId")).stanceSwitch or 1
	if d.prev and now() - d.changedAt < D.SwitchTime * mult then
		return d.prev
	end
	return stance
end

----------------------------------------------------------------------
-- Excepciones del fuerte por arma (Maza: arriba imbloqueable; Estoque: atraviesa)
----------------------------------------------------------------------
function Directional.heavyUnblockable(char, dir)
	local wd = WeaponData.directional(char:GetAttribute("WeaponId"))
	return wd.unblockableDirs ~= nil and wd.unblockableDirs[dir or ""] == true
end

function Directional.heavyPierces(char)
	return WeaponData.directional(char:GetAttribute("WeaponId")).piercesGuard == true
end

----------------------------------------------------------------------
-- Parry con margen de ping
--   El servidor anota a qué hora recibió la pulsación de guardia (BlockStart). Un golpe que impacta en T se
--   parrea si la pulsación llegó en [T - ParryWindow, T + gracia], con gracia = min(ping del defensor, ParryGrace).
--   Para la parte «después del impacto», el golpe queda en espera (pendiente) hasta gracia segundos: si en ese
--   tiempo llega la pulsación por el lado correcto, se resuelve como parry; si no, se resuelve normal.
--   Nunca se acepta una hora mandada por el cliente.
----------------------------------------------------------------------
function Directional.grace(victim)
	local p = Players:GetPlayerFromCharacter(victim)
	if not p then return 0 end
	local ok, ping = pcall(function() return p:GetNetworkPing() end)
	if not ok or type(ping) ~= "number" or ping ~= ping then return 0 end
	return math.clamp(ping, 0, D.ParryGrace)
end

-- ¿La guardia está en su ventana de parry (pulsación nueva reciente)?
function Directional.inParryWindow(victim)
	-- Volver a la guardia sin pulsar (tras un ataque) pone BlockStart en el pasado: no abre ventana
	if not victim:GetAttribute("Blocking") then return false end
	return now() - (victim:GetAttribute("BlockStart") or 0) <= D.ParryWindow
end

-- Deja un golpe en espera. resolveFn(asParry) se llama una sola vez: true si llegó un parry a tiempo.
function Directional.defer(victim, side, seconds, resolveFn)
	local d = get(victim)
	local entry = { side = side, fn = resolveFn, done = false }
	table.insert(d.pending, entry)
	task.delay(seconds, function()
		if entry.done then return end
		entry.done = true
		local i = table.find(d.pending, entry)
		if i then table.remove(d.pending, i) end
		resolveFn(false)
	end)
end

-- Pulsación nueva de guardia: resuelve como parry los golpes en espera que llegan por el lado cubierto
function Directional.onGuardPress(victim)
	local d = data[victim]
	if not d or #d.pending == 0 then return end
	local side = Directional.guardSide(victim)
	for i = #d.pending, 1, -1 do
		local entry = d.pending[i]
		if not entry.done and entry.side == side then
			entry.done = true
			table.remove(d.pending, i)
			entry.fn(true)
		end
	end
end

----------------------------------------------------------------------
-- Máquina de estados (C16): se recalcula cada frame desde el estado del servidor
----------------------------------------------------------------------
-- st = Combat.state(char) (se pasa para no crear una dependencia circular con Combat)
function Directional.compute(char, st)
	local t = now()
	if char:GetAttribute("CarriedBy") then
		return "Carried", char:GetAttribute("CarryEndsAt") or 0
	end
	if char:GetAttribute("KnockedDown") or char:GetAttribute("Ragdolled") then
		return "Downed", char:GetAttribute("KnockdownEndsAt") or 0
	end
	local parried = char:GetAttribute("ParriedUntil") or 0
	if parried > t then return "Parried", parried end
	local broken = char:GetAttribute("GuardBrokenStateUntil") or 0
	if broken > t then return "GuardBroken", broken end
	local stunned = char:GetAttribute("StunnedUntil") or 0
	if stunned > t then return "Staggered", stunned end

	local action = st.action or ""
	if action ~= "" and st.busyUntil > t then
		if action == "Dodge" then return "Dodge", st.busyUntil end
		if action == "Kick" then return "Kick", st.busyUntil end
		if action == "M1" or action == "Heavy" then
			local phase = char:GetAttribute("ActionPhase") or ""
			local hitAt = char:GetAttribute("HitAt") or 0
			if phase == "Windup" then
				return "Windup", (action == "Heavy" and st.windupEnd > t) and st.windupEnd or hitAt
			elseif phase == "Active" then
				return "Active", hitAt > 0 and hitAt or st.busyUntil
			end
			return "Recovery", st.busyUntil
		end
		-- Otras acciones (levantar, lanzar, palmada) cuentan como recuperación: no se puede bloquear
		return "Recovery", st.busyUntil
	end

	if char:GetAttribute("Blocking") then
		if Directional.inParryWindow(char) then
			return "ParryWindow", (char:GetAttribute("BlockStart") or t) + D.ParryWindow
		end
		return "Guard", 0
	end
	return "Neutral", 0
end

function Directional.refresh(char, st)
	local state, ends = Directional.compute(char, st)
	if char:GetAttribute("CombatState") ~= state then char:SetAttribute("CombatState", state) end
	if char:GetAttribute("StateEnds") ~= ends then char:SetAttribute("StateEnds", ends) end
end

return Directional
