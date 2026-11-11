-- ModuleScript: ServerScriptService/Combat
-- Núcleo del combate (servidor): estado de cada luchador, barras de Stun y Guardia,
-- bloqueo, parry, rotura de guardia, resolución de golpes, derribo por Stun, agarrar/lanzar.
-- Vale para jugadores y para muñecos de práctica (cualquier Model con la etiqueta "Combatant").
--
-- Atributos replicados en el personaje (los leen Overhead, Controls y el panel de depuración):
--   WeaponId, BaseSpeed, CanFight, Frozen
--   Stun, Guard, GuardMax, InfusionCharge
--   Blocking, BlockStart, GuardBroken, GuardBrokenUntil
--   Action ("", "M1", "Heavy", "Kick", "Dodge"), ActionPhase ("Windup", "Active", "Recovery"),
--   HitAt (hora de servidor del próximo impacto), ComboStep, Telegraph ("", "Heavy", "Unblockable")
--   HyperArmor, IFrameUntil, StunnedUntil, InvulnUntil, KnockedDown, KnockdownImmuneUntil
--   Ragdolled, Carrying, CarriedBy
-- Todos los tiempos son workspace:GetServerTimeNow() (iguales en servidor y clientes).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Ragdoll = require(ReplicatedStorage:WaitForChild("Ragdoll"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))
local Anim = require(ServerScriptService:WaitForChild("Anim"))
local Fx = require(ServerScriptService:WaitForChild("Fx"))
local CombatEvents = require(ServerScriptService:WaitForChild("CombatEvents"))
local Directional = require(ServerScriptService:WaitForChild("Directional"))

local CFG = CombatConfig
local C = Theme.Colors

local Combat = {}
Combat.TAG = "Combatant"

-- Ganchos que rellenan otros módulos (Infusion) sin crear dependencias circulares:
--   damageMods(attacker, victim, hit) -> multDaño, multStun
--   onHit(attacker, victim, hit, damage) · onBlocked(attacker, victim, hit, damage)
Combat.hooks = {}

local carrying = {} -- [quien carga] = { victim, instances }
local states = setmetatable({}, { __mode = "k" })

function Combat.now()
	return workspace:GetServerTimeNow()
end
local now = Combat.now

----------------------------------------------------------------------
-- Estado interno (solo servidor)
----------------------------------------------------------------------
function Combat.state(char)
	local s = states[char]
	if not s then
		s = {
			token = 0,            -- cambia al cancelar una acción: invalida sus temporizadores
			action = "",
			busyUntil = 0,
			actionStart = 0,
			windupEnd = 0,
			comboStep = 0,
			comboExpires = 0,
			queuedM1 = false,
			wantsBlock = false,
			lastStunAt = 0,
			lastGuardUseAt = 0,
			lastStaminaUseAt = 0,
			dodgeReadyAt = 0,
			kickReadyAt = 0,
			heavyReadyAt = 0,
		}
		states[char] = s
	end
	return s
end

local function getHum(char)
	local h = char and char:FindFirstChildOfClass("Humanoid")
	if h and h.Health > 0 then
		return h
	end
	return nil
end
Combat.getHum = getHum

function Combat.weaponOf(char)
	return WeaponData.get(char:GetAttribute("WeaponId"))
end

----------------------------------------------------------------------
-- Equipos y objetivos
----------------------------------------------------------------------
function Combat.isEnemy(attackerChar, victimChar)
	if attackerChar == victimChar then return false end
	if attackerChar:GetAttribute("IsDummy") and victimChar:GetAttribute("IsDummy") then return false end
	local ap = Players:GetPlayerFromCharacter(attackerChar)
	local vp = Players:GetPlayerFromCharacter(victimChar)
	if ap and vp then
		-- Fuera de una partida (lobby/práctica) no hay PvP: solo contra muñecos
		if not (ap:GetAttribute("InMatch") and vp:GetAttribute("InMatch")) then return false end
		return ap.Team ~= vp.Team
	end
	return true
end

-- Caja de golpe delante del personaje. Devuelve la lista de rivales dentro.
function Combat.hitbox(char, reach, width)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return {} end
	local size = Vector3.new(width, CFG.Attack.BoxHeight, reach + 1)
	local cf = root.CFrame * CFrame.new(0, CFG.Attack.BoxCenterY or 0, -(reach + 1) / 2 + 0.5)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	local list, seen = {}, {}
	for _, part in workspace:GetPartBoundsInBox(cf, size, params) do
		-- Solo cuenta el cuerpo R15 (piezas directas del personaje): ni accesorios, ni pelo, ni armas,
		-- ni el HumanoidRootPart (una caja más grande que el cuerpo)
		local model = part.Parent
		if not (model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid"))
			or part.Name == "HumanoidRootPart" then
			model = nil
		end
		-- Las partes del arma están dentro de un Tool dentro del personaje
		while model and not model:FindFirstChildOfClass("Humanoid") do
			model = model:FindFirstAncestorOfClass("Model")
		end
		if model and not seen[model] then
			seen[model] = true
			if getHum(model) and CollectionService:HasTag(model, Combat.TAG) and Combat.isEnemy(char, model) then
				table.insert(list, model)
			end
		end
	end
	Fx.debugBox(cf, size, #list > 0)
	return list
end

----------------------------------------------------------------------
-- Velocidad (nunca se puede saltar)
----------------------------------------------------------------------
function Combat.refreshSpeed(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if hum.JumpHeight ~= 0 then hum.JumpHeight = 0 end
	if hum.JumpPower ~= 0 then hum.JumpPower = 0 end

	local t = now()
	local speed = 0
	if not char:GetAttribute("Frozen")
		and not char:GetAttribute("Ragdolled")
		and (char:GetAttribute("StunnedUntil") or 0) <= t then
		speed = (char:GetAttribute("BaseSpeed") or 16) * CFG.Movement.SpeedMult
		local action = char:GetAttribute("Action") or ""
		if char:GetAttribute("Blocking") then
			speed = math.min(speed, CFG.Block.WalkSpeed)
		elseif action == "M1" or action == "Heavy" or action == "Kick" then
			speed *= CFG.Attack.MoveSpeedMult
		elseif action == "Revive" then
			speed = 0
		end
		if char:GetAttribute("Carrying") then
			speed *= CFG.Grab.CarrySpeedMult
			if char:GetAttribute("ThrowCharging") then speed *= CFG.Grab.ChargeSpeedMult end
		end
		speed *= (char:GetAttribute("MoveSpeedMult") or 1) -- infusión activa
		if (char:GetAttribute("SlowUntil") or 0) > t then
			speed *= (char:GetAttribute("SlowMult") or 1) -- ralentización (Hielo)
		end
		if (char:GetAttribute("DashSlowUntil") or 0) > t then
			speed *= CFG.Dodge.AfterSlowMult -- breve penalización tras el dash
		end
	end
	if math.abs(hum.WalkSpeed - speed) > 0.01 then
		hum.WalkSpeed = speed
	end
end

----------------------------------------------------------------------
-- Acciones: inicio, fase, fin y cancelación
----------------------------------------------------------------------
function Combat.canAct(char)
	return getHum(char) ~= nil
		and char:GetAttribute("CanFight") == true
		and not char:GetAttribute("Ragdolled")
		and not char:GetAttribute("Carrying")
		and not char:GetAttribute("CarriedBy")
		and not char:GetAttribute("Frozen")
		and (char:GetAttribute("StunnedUntil") or 0) <= now()
end

function Combat.isBusy(char)
	return Combat.state(char).busyUntil > now()
end

-- Empieza una acción. Devuelve el token que deben comprobar sus temporizadores.
function Combat.beginAction(char, action, duration, phase)
	local st = Combat.state(char)
	st.token += 1
	st.action = action
	st.actionStart = now()
	st.busyUntil = st.actionStart + duration
	char:SetAttribute("Action", action)
	char:SetAttribute("ActionPhase", phase or "Active")
	char:SetAttribute("HitAt", 0)
	Combat.refreshSpeed(char)
	return st.token
end

function Combat.valid(char, token)
	return char.Parent ~= nil and Combat.state(char).token == token and getHum(char) ~= nil
end

function Combat.setPhase(char, phase)
	char:SetAttribute("ActionPhase", phase)
end

local function clearActionAttrs(char)
	char:SetAttribute("Action", "")
	char:SetAttribute("ActionPhase", "")
	char:SetAttribute("HitAt", 0)
	char:SetAttribute("Telegraph", "")
	char:SetAttribute("HyperArmor", false)
	char:SetAttribute("AttackDir", "")
	char:SetAttribute("Finisher", false)
end

-- Fin normal de una acción
function Combat.endAction(char, token)
	if token and not Combat.valid(char, token) then return end
	local st = Combat.state(char)
	st.action = ""
	st.busyUntil = 0
	clearActionAttrs(char)
	Combat.refreshSpeed(char)
	-- Si el jugador sigue manteniendo F, vuelve a la guardia (sin ventana de parry)
	if st.wantsBlock then
		Combat.blockStart(char, true)
	end
end

-- Interrumpe la acción en curso (golpe recibido, parry, finta...)
function Combat.cancelAction(char)
	local st = Combat.state(char)
	st.token += 1
	st.action = ""
	st.busyUntil = 0
	st.queuedM1 = false
	st.comboStep = 0
	clearActionAttrs(char)
	Anim.stopActions(char)
	Combat.refreshSpeed(char)
end

-- Aturdimiento corto: no puede actuar ni moverse
function Combat.stagger(char, seconds, animKey)
	Combat.cancelAction(char)
	local untilT = now() + seconds
	if (char:GetAttribute("StunnedUntil") or 0) < untilT then
		char:SetAttribute("StunnedUntil", untilT)
	end
	if char:GetAttribute("Blocking") then
		char:SetAttribute("Blocking", false)
	end
	if animKey then Anim.play(char, animKey, { duration = seconds + 0.2 }) end
	Combat.refreshSpeed(char)
end

----------------------------------------------------------------------
-- Barras: Stun, Guardia y carga de infusión
----------------------------------------------------------------------
function Combat.addCharge(char, amount)
	local IC = CFG.InfusionCharge
	amount = math.min(amount, IC.MaxPerHit)
	if amount <= 0 then return end
	-- Con la infusión activa o en el agotamiento posterior no se gana carga
	if char:GetAttribute("InfusionActive") or (char:GetAttribute("InfusionLockUntil") or 0) > now() then return end
	local v = math.min(IC.Max, (char:GetAttribute("InfusionCharge") or 0) + amount)
	char:SetAttribute("InfusionCharge", v)
end

-- Derribo por Stun (Fase A: ragdoll temporal de 4 s. La Fase B añade machacar teclas y la palmada del aliado)
function Combat.knockdown(char, velocity)
	local t = now()
	if (char:GetAttribute("KnockdownImmuneUntil") or 0) > t or char:GetAttribute("Ragdolled") then
		return false
	end
	Combat.cancelAction(char)
	local st = Combat.state(char)
	st.wantsBlock = false
	char:SetAttribute("Blocking", false)
	char:SetAttribute("KnockedDown", true)
	char:SetAttribute("Stun", CFG.Stun.Max)
	CombatEvents.fire("Knockdown", CombatEvents.lastAttacker(char), char)
	if char:GetAttribute("Carrying") then Combat.drop(char, "drop") end
	Anim.play(char, "Generic.KnockdownFall")
	-- Sin temporizador del Ragdoll: el bucle lo levanta al llegar KnockdownEndsAt
	-- (machacar teclas o la palmada de un aliado lo adelantan)
	char:SetAttribute("KnockdownStart", t)
	char:SetAttribute("KnockdownEndsAt", t + CFG.Knockdown.StunDuration)
	Ragdoll.enable(char, nil)
	Fx.popAbove(char, "pop.down", C.TelegraphHeavy)
	local kroot = char:FindFirstChild("HumanoidRootPart")
	if kroot then
		task.delay(0.35, function() Fx.dust(kroot.Position - Vector3.new(0, 2.5, 0), 1) end)
	end
	Fx.soundAt("Body_Fall", char)
	Fx.soundAt("Hit_Knockdown", char)
	Fx.shake(char, CFG.CameraShake.Knockdown)
	if velocity then
		task.defer(function()
			if char.Parent then Ragdoll.fling(char, velocity, nil) end
		end)
	end
	return true
end

-- Machacar Espacio / clic / botón estando derribado: adelanta el levantarse
function Combat.mashGetUp(char)
	if char:GetAttribute("CarriedBy") then
		Combat.struggle(char)
		return
	end
	if not char:GetAttribute("KnockedDown") then return end
	local K = CFG.Knockdown
	local minEnd = (char:GetAttribute("KnockdownStart") or 0) + K.MinDown
	local endsAt = (char:GetAttribute("KnockdownEndsAt") or 0) - K.MashReduce
	char:SetAttribute("KnockdownEndsAt", math.max(minEnd, endsAt))
end

-- Levantar ya (palmada de un aliado)
function Combat.getUp(char)
	if not char:GetAttribute("KnockedDown") or char:GetAttribute("CarriedBy") then return end
	char:SetAttribute("KnockdownEndsAt", now())
	if char:GetAttribute("Ragdolled") then
		Combat.state(char).getUpFront = Ragdoll.isFaceDown(char)
		Ragdoll.disable(char)
	end
end

-- Aliado derribado por Stun cerca (mismo equipo dentro de una partida)
function Combat.findDownedAlly(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	local me = Players:GetPlayerFromCharacter(char)
	if not root or not me or not me:GetAttribute("InMatch") then return nil end
	for _, model in CollectionService:GetTagged(Combat.TAG) do
		local p = Players:GetPlayerFromCharacter(model)
		if model ~= char and p and p:GetAttribute("InMatch") and p.Team == me.Team
			and model:GetAttribute("KnockedDown") and not model:GetAttribute("CarriedBy") and getHum(model) then
			local r = model:FindFirstChild("HumanoidRootPart")
			if r and (r.Position - root.Position).Magnitude <= CFG.Revive.Range then
				return model
			end
		end
	end
	return nil
end

-- Stamina: devuelve false si no alcanza (y avisa al cliente para que parpadee la barra)
function Combat.spendStamina(char, amount)
	if not amount or amount <= 0 then return true end
	if char:GetAttribute("IsDummy") and not CFG.Stamina.DummiesUseStamina then return true end
	local s = char:GetAttribute("Stamina") or CFG.Stamina.Max
	if s < amount then
		char:SetAttribute("StaminaFailAt", now())
		return false
	end
	char:SetAttribute("Stamina", s - amount)
	Combat.state(char).lastStaminaUseAt = now()
	return true
end

function Combat.addStun(char, amount, knockVelocity)
	if amount <= 0 or char:GetAttribute("KnockedDown") then return end
	-- Rotura de guardia: mientras dura, el Stun entra más fácil
	if char:GetAttribute("GuardBroken") then amount *= CFG.Guard.BrokenStunMult end
	local st = Combat.state(char)
	st.lastStunAt = now()
	local v = (char:GetAttribute("Stun") or 0) + amount
	if v >= CFG.Stun.Max then
		if not Combat.knockdown(char, knockVelocity) then
			-- inmune a derribos ahora mismo: se queda casi lleno
			char:SetAttribute("Stun", CFG.Stun.Max * 0.9)
		end
	else
		char:SetAttribute("Stun", v)
	end
end

----------------------------------------------------------------------
-- Bloqueo (F) y parry (F justo al impacto)
----------------------------------------------------------------------
-- quiet = true: volver a la guardia sin ventana de parry (p. ej. tras terminar un ataque)
function Combat.blockStart(char, quiet)
	local st = Combat.state(char)
	st.wantsBlock = true
	if not Combat.canAct(char) then return false end
	local t = now()
	if char:GetAttribute("Blocking") then return true end
	if (char:GetAttribute("GuardBrokenUntil") or 0) > t then return false end
	if (char:GetAttribute("BlockLockUntil") or 0) > t and not quiet then return false end

	if st.busyUntil > t then
		-- Finta: F cancela la preparación del fuerte
		if not Combat.tryFeint(char) then return false end
	end

	char:SetAttribute("Blocking", true)
	char:SetAttribute("BlockStart", quiet and (t - Combat.parryWindow() - 1) or t)
	Anim.play(char, "Weapons." .. (char:GetAttribute("WeaponId") or "Sword") .. ".Block", { looped = true, fade = 0.06 })
	Combat.refreshSpeed(char)
	-- Direccional: una pulsación nueva puede parrear golpes que esperan por el margen de ping
	if not quiet and Directional.enabled() then Directional.onGuardPress(char) end
	return true
end

-- Ventana de parry vigente (0.1: CombatConfig.Block; direccional: la común de 0,15 s)
function Combat.parryWindow()
	if Directional.enabled() then return CFG.Directional.ParryWindow end
	return CFG.Block.ParryWindow
end

-- noLock = true: no castigar el soltar F (lo usan las rupturas y los muñecos)
function Combat.blockEnd(char, noLock, keepWanting)
	local st = Combat.state(char)
	if not keepWanting then st.wantsBlock = false end
	if not char:GetAttribute("Blocking") then return end
	char:SetAttribute("Blocking", false)
	local t = now()
	if not noLock and t - (char:GetAttribute("BlockStart") or 0) <= Combat.parryWindow() then
		-- Soltar F dentro de la ventana sin parrear: breve bloqueo para evitar el spam de parry
		local lock = Directional.enabled() and CFG.Directional.ParryWhiffLock or CFG.Block.WhiffLock
		char:SetAttribute("BlockLockUntil", t + lock)
	end
	Anim.stop(char, "Weapons." .. (char:GetAttribute("WeaponId") or "Sword") .. ".Block")
	Combat.refreshSpeed(char)
end

-- Cancela la preparación de un fuerte (F o esquiva). Devuelve true si se fintó.
function Combat.tryFeint(char)
	local st = Combat.state(char)
	if st.action ~= "Heavy" or char:GetAttribute("ActionPhase") ~= "Windup" then return false end
	local def = Combat.weaponOf(char)
	if not def.heavy.feintable then return false end
	local windup = st.windupEnd - st.actionStart
	local progress = windup > 0 and (now() - st.actionStart) / windup or 1
	if progress > CFG.Attack.HeavyFeintCutoff then return false end
	Combat.cancelAction(char)
	Fx.popAbove(char, "pop.feint", C.BoneDim)
	return true
end

local function isFacing(victimChar, attackerChar)
	local vRoot = victimChar:FindFirstChild("HumanoidRootPart")
	local aRoot = attackerChar:FindFirstChild("HumanoidRootPart")
	if not vRoot or not aRoot then return false end
	local toAttacker = (aRoot.Position - vRoot.Position) * Vector3.new(1, 0, 1)
	if toAttacker.Magnitude < 0.01 then return true end
	return vRoot.CFrame.LookVector:Dot(toAttacker.Unit) > CFG.Block.ArcDot
end

----------------------------------------------------------------------
-- Empuje
----------------------------------------------------------------------
local Effect = require(ServerScriptService:WaitForChild("Remotes")).get("Effect")

local function push(victimChar, velocity)
	local root = victimChar:FindFirstChild("HumanoidRootPart")
	if not root or velocity.Magnitude < 0.01 then return end
	if victimChar:GetAttribute("Ragdolled") then
		-- En ragdoll cada extremidad es un ensamblaje: se empuja todo el cuerpo
		if victimChar:GetAttribute("CarriedBy") then return end
		for _, part in victimChar:GetChildren() do
			if part:IsA("BasePart") then part:ApplyImpulse(velocity * part.AssemblyMass) end
		end
		return
	end
	local p = Players:GetPlayerFromCharacter(victimChar)
	if p then
		Effect:FireClient(p, "Impulse", velocity) -- el cliente es dueño de su física
	else
		root.AssemblyLinearVelocity = velocity
	end
end
Combat.push = push

local function flatDir(fromChar, toChar)
	local a = fromChar:FindFirstChild("HumanoidRootPart")
	local b = toChar:FindFirstChild("HumanoidRootPart")
	if not a or not b then return Vector3.zAxis end
	local d = (b.Position - a.Position) * Vector3.new(1, 0, 1)
	if d.Magnitude < 0.01 then return a.CFrame.LookVector end
	return d.Unit
end

----------------------------------------------------------------------
-- Resultados de un golpe
----------------------------------------------------------------------
local function doParry(defender, attacker)
	local P = CFG.Parry
	local t = now()
	local wid = defender:GetAttribute("WeaponId") or "Sword"

	CombatEvents.fire("Parry", defender, attacker)
	-- El atacante queda aturdido, recibe Stun y es empujado hacia atrás
	Combat.stagger(attacker, P.AttackerStagger, "Generic.ParriedStagger")
	attacker:SetAttribute("ParriedUntil", t + P.AttackerStagger) -- estado Parried (C16)
	Combat.addStun(attacker, P.AttackerStunGain)
	push(attacker, flatDir(defender, attacker) * P.PushBack + Vector3.new(0, 4, 0))
	if attacker:GetAttribute("Carrying") then Combat.drop(attacker, "drop") end

	-- El defensor: breve invulnerabilidad y prioridad para contraatacar
	defender:SetAttribute("InvulnUntil", t + P.DefenderInvuln)
	-- Ventaja breve: el siguiente golpe del defensor hace más daño (contraataque)
	defender:SetAttribute("CounterUntil", t + P.CounterWindow)
	Anim.play(defender, "Weapons." .. wid .. ".Parry")
	Combat.addCharge(defender, P.InfusionCharge)

	Fx.popAbove(defender, "pop.parry", C.ParryFlash)
	Fx.flash(defender, C.ParryFlash, 0.25)
	local pos, d = Fx.impactPoint(attacker, defender)
	Fx.hit(pos, "Parry", d, attacker, defender)
	Fx.soundAt("Parry", defender, 1)
	Fx.soundAt("ParrySpark", defender, 0.7)
	Fx.hitstop({ defender, attacker }, CFG.Hitstop.Parry)
	Fx.shake(defender, CFG.CameraShake.Parry, d)
	Fx.shake(attacker, CFG.CameraShake.Parry, -d)
	Fx.feel(defender, "Parry", { dir = d })
	Fx.feel(attacker, "Parried", { dir = -d })
	return "parry"
end

local function applyDamage(attacker, victim, damage)
	local hum = getHum(victim)
	if not hum or damage <= 0 then return end
	local victimPlayer = Players:GetPlayerFromCharacter(victim)
	if attacker and attacker:GetAttribute("IsDummy") and victimPlayer
		and victimPlayer:GetAttribute("InMatch") ~= true then
		damage = math.min(damage, math.max(0, hum.Health - CFG.Practice.MinimumHealth))
	end
	local before = hum.Health
	CombatEvents.noteAttacker(victim, attacker)
	hum:TakeDamage(damage)
	damage = math.max(0, before - hum.Health)
	if damage > 0 then CombatEvents.fire("Damage", attacker, victim, { amount = damage }) end
	Combat.addCharge(attacker, damage * CFG.InfusionCharge.DealtMult)
	Combat.addCharge(victim, damage * CFG.InfusionCharge.TakenMult)
	if victim:GetAttribute("IsDummy") then victim:SetAttribute("LastDamagedAt", now()) end
	return damage
end
Combat.applyDamage = applyDamage

local function guardBreak(victim, attacker, hit, damage, stunGain)
	local G = CFG.Guard
	local t = now()
	local st = Combat.state(victim)
	CombatEvents.fire("GuardBreak", attacker, victim)
	victim:SetAttribute("Guard", 0)
	victim:SetAttribute("GuardBroken", true)
	victim:SetAttribute("GuardBrokenUntil", t + G.BrokenNoBlock)
	st.lastGuardUseAt = t
	Combat.blockEnd(victim, true, true)
	Combat.stagger(victim, G.BrokenStagger, "Generic.GuardBreakStagger")
	if Directional.enabled() then
		-- Estado GuardBroken (C16): abierto a un golpe seguro
		victim:SetAttribute("GuardBrokenStateUntil", t + math.max(G.BrokenStagger, CFG.Directional.Kick.GuardBrokenTime))
	end
	applyDamage(attacker, victim, damage)
	Fx.hitstop({ attacker, victim }, hit.kind == "Heavy" and CFG.Hitstop.Heavy or CFG.Hitstop.GuardBreak)
	Fx.popAbove(victim, "pop.guardBreak", C.GuardBreak)
	Fx.flash(victim, C.GuardBreak, 0.3)
	local gpos, gdir = Fx.impactPoint(attacker, victim)
	Fx.hit(gpos, "GuardBreak", gdir, attacker, victim)
	Fx.soundAt("GuardBreak", victim, 1)
	Fx.shake(victim, CFG.CameraShake.GuardBreak, gdir)
	Fx.shake(attacker, CFG.CameraShake.GuardBreak * 0.4, gdir)
	Fx.feel(attacker, "GuardBreak", { dir = gdir, kind = hit.kind })
	Fx.feel(victim, "GuardBroken", { dir = gdir, kind = hit.kind })
	local dir = flatDir(attacker, victim)
	Combat.addStun(victim, stunGain + G.BrokenStunGain, dir * CFG.Knockdown.Knockback + Vector3.new(0, 12, 0))
	if not victim:GetAttribute("Ragdolled") then
		push(victim, dir * (hit.knockback or 0) * 0.6)
	end
	return "guardbreak"
end

local function doBlocked(victim, attacker, hit, damage)
	local G = CFG.Guard
	local t = now()
	local st = Combat.state(victim)
	local drain = (hit.guardDrain or damage * G.LightDrainMult) * (hit.guardDrainMult or 1) * (attacker:GetAttribute("GuardDrainMult") or 1)
	local guard = (victim:GetAttribute("Guard") or 0) - drain
	st.lastGuardUseAt = t
	if guard <= 0 then
		return guardBreak(victim, attacker, hit, 0, 0)
	end
	victim:SetAttribute("Guard", guard)
	local wid = victim:GetAttribute("WeaponId") or "Sword"
	Anim.play(victim, "Weapons." .. wid .. ".BlockHit", { priority = Enum.AnimationPriority.Action2 })
	Fx.soundAt(hit.kind == "Heavy" and "BlockHit_Heavy" or "BlockHit_Light", victim)
	Fx.flash(victim, C.BlockGlow, 0.12)
	local bpos, bdir = Fx.impactPoint(attacker, victim)
	Fx.hit(bpos, hit.kind == "Heavy" and "BlockHeavy" or "Block", bdir, attacker, victim)
	Fx.hitstop({ attacker, victim }, CFG.Hitstop.Light * 0.8)
	Fx.shake(victim, CFG.CameraShake.Light * 0.7, bdir)
	push(victim, flatDir(attacker, victim) * (hit.knockback or 0) * 0.35)
	-- 10/11/2026 Contragolpe de peso (WeaponData.riposte): bloquear un básico con Espadón o Maza traba al
	-- atacante (no puede seguir spameando) y deja listo un contraataque rápido, fuerte y con hiperarmadura.
	local riposte = Combat.weaponOf(victim).riposte
	if riposte and hit.kind == "Light" then
		victim:SetAttribute("RiposteUntil", t + riposte.window)
		local ast = Combat.state(attacker)
		ast.comboStep = 0
		ast.queuedM1 = false
		attacker:SetAttribute("ComboStep", 0)
		Combat.stagger(attacker, riposte.recoil)
		Fx.flash(victim, C.Riposte, 0.25)
	end
	if Combat.hooks.onBlocked then Combat.hooks.onBlocked(attacker, victim, hit, damage) end
	Fx.feel(victim, "Block", { dir = bdir, kind = hit.kind, guard = guard / math.max(1, victim:GetAttribute("GuardMax") or 100) })
	Fx.feel(attacker, "Blocked", { dir = bdir, kind = hit.kind })
	return "blocked"
end

local function doHit(attacker, victim, hit, damage)
	local t = now()
	damage = applyDamage(attacker, victim, damage) or damage
	if victim:GetAttribute("Carrying") then Combat.drop(victim, "drop") end
	Fx.popAbove(victim, tostring(math.floor(damage + 0.5)), hit.kind == "Heavy" and C.TelegraphHeavy or C.Damage)
	if Combat.hooks.onHit then Combat.hooks.onHit(attacker, victim, hit, damage) end

	if victim:GetAttribute("CarriedBy") then
		return "hit" -- al que están cargando solo le afecta el daño
	end

	local dir = flatDir(attacker, victim)
	-- El remate (D4) se siente como un fuerte
	local heavy = hit.kind == "Heavy" or hit.finisher == true
	local blunt = Combat.weaponOf(attacker).blunt == true
	Fx.feel(attacker, "Deal", { dir = dir, kind = hit.kind, finisher = hit.finisher == true, amount = damage })
	Fx.feel(victim, "Take", { dir = dir, kind = hit.kind, finisher = hit.finisher == true, amount = damage })
	if hit.finisher then Fx.popAbove(victim, "pop.finisher", C.TelegraphHeavy) end
	if hit.kind == "Kick" then
		Fx.soundAt("Kick_Hit", victim)
	else
		Fx.soundAt(blunt and "Hit_Blunt" or (heavy and "Hit_Heavy" or "Hit_Light"), victim)
		if heavy and not blunt then Fx.soundAt("Hit_Heavy", victim, 0.6) end
	end
	local hpos = Fx.impactPoint(attacker, victim)
	Fx.hit(hpos, heavy and "Heavy" or (blunt and "Blunt" or "Light"), dir, attacker, victim)

	if victim:GetAttribute("Ragdolled") then
		push(victim, dir * (hit.knockback or 0) * 0.5)
		return "hit"
	end

	-- Hiperarmadura: los golpes básicos no interrumpen (el daño y el Stun sí entran)
	local armored = victim:GetAttribute("HyperArmor") and hit.kind == "Light"
	if not armored then
		local vRoot = victim:FindFirstChild("HumanoidRootPart")
		local fromBack = vRoot and vRoot.CFrame.LookVector:Dot(-dir) < 0
		Combat.stagger(victim, (heavy and CFG.Attack.HeavyHitStagger or CFG.Attack.HitStagger) * (hit.staggerMult or 1),
			fromBack and "Generic.HitReactBack" or (heavy and "Generic.HitReactHeavy" or "Generic.HitReactFront"))
	else
		Fx.flash(victim, C.TelegraphHeavy, 0.1)
	end

	local knockVel = dir * CFG.Knockdown.Knockback + Vector3.new(0, 14, 0)
	-- 11/11/2026: cuanto menos vida tiene el rival, más fácil derribarlo (curva por arma del atacante)
	local curve = WeaponData.StunVsHealth[attacker:GetAttribute("WeaponId") or "Sword"] or CFG.StunByHealth
	local vHum = victim:FindFirstChildOfClass("Humanoid")
	local hpFrac = vHum and math.clamp(vHum.Health / math.max(1, vHum.MaxHealth), 0, 1) or 1
	local healthMult = curve.empty + (curve.full - curve.empty) * hpFrac
	Combat.addStun(victim, (hit.stun or 0) * (attacker:GetAttribute("StunMult") or 1) * healthMult, knockVel)
	if not victim:GetAttribute("Ragdolled") then
		push(victim, dir * (hit.knockback or 0) + Vector3.new(0, 2, 0))
	end

	-- El peso del arma cambia cuánto se congela el golpe y cuánto tiembla la cámara
	local feel = WeaponData.feel(attacker:GetAttribute("WeaponId"))
	if heavy then
		local fin = hit.finisher and CFG.Directional.Finisher or nil
		Fx.hitstop({ attacker, victim }, CFG.Hitstop.Heavy * feel.hitstop * (fin and fin.HitstopMult or 1))
		Fx.shake(victim, CFG.CameraShake.Heavy * feel.shake * (fin and fin.ShakeMult or 1), dir)
		Fx.shake(attacker, CFG.CameraShake.Heavy * 0.45 * feel.shake, dir)
	else
		if CFG.Hitstop.Light > 0 then Fx.hitstop({ attacker, victim }, CFG.Hitstop.Light * feel.hitstop) end
		Fx.shake(victim, CFG.CameraShake.Light * feel.shake, dir)
		Fx.shake(attacker, CFG.CameraShake.Light * 0.5 * feel.shake, dir)
	end
	return "hit"
end

-- Resolución direccional (0.2, CombatConfig.Directional.Enabled). Orden (Arquitectura, sección 1):
--   1. derribado -> inmune a las armas (solo patada o levantar)
--   2. ventana de parry del mismo lado -> parry
--   3. guardia del mismo lado -> bloqueo (salvo fuerte imbloqueable por dirección o que atraviesa)
--   4. cualquier otro caso -> golpe limpio
-- La patada rompe cualquier guardia (no se parrea: se esquiva).
local function dealDirectional(attacker, victim, hit, damage)
	local DC = CFG.Directional
	if DC.DownedWeaponImmune and hit.kind ~= "Kick"
		and (victim:GetAttribute("KnockedDown") or victim:GetAttribute("Ragdolled")) then
		return "immune"
	end
	local side = Directional.incomingSide(hit.dir)
	local function guarding()
		return victim:GetAttribute("Blocking") and not victim:GetAttribute("Ragdolled") and isFacing(victim, attacker)
	end
	local blocking = guarding()
	local covers = blocking and Directional.guardSide(victim) == side
	local canParry = hit.parryable ~= false

	if hit.kind == "Kick" then
		if blocking then return guardBreak(victim, attacker, hit, damage * 0.5, hit.stun or 0) end
		return doHit(attacker, victim, hit, damage)
	end
	if covers and canParry and Directional.inParryWindow(victim) then
		return doParry(victim, attacker)
	end

	-- Resultado con el estado del defensor en el momento de resolver
	local function settle()
		if guarding() and Directional.guardSide(victim) == side then
			if hit.kind == "Heavy" and hit.unblockable then
				return doHit(attacker, victim, hit, damage)
			elseif hit.kind == "Heavy" and hit.pierces then
				return doHit(attacker, victim, hit, damage * (hit.blockDamageMult or 1))
			end
			return doBlocked(victim, attacker, hit, damage)
		end
		return doHit(attacker, victim, hit, damage * (blocking and DC.SideHitGuardMult or 1))
	end

	-- Margen de ping: si el defensor (jugador) todavía podría parrear este golpe, espera hasta la gracia
	if canParry and not covers then
		local grace = Directional.grace(victim)
		if grace > 0.01 then
			Directional.defer(victim, side, grace, function(asParry)
				local r = "none"
				if attacker.Parent and victim.Parent and getHum(attacker) and getHum(victim) then
					if asParry then
						r = doParry(victim, attacker)
					elseif (victim:GetAttribute("IFrameUntil") or 0) > now() then
						Fx.popAbove(victim, "pop.dodge", C.Dodge)
						r = "dodged"
					else
						r = settle()
					end
				end
				if hit.onResult then hit.onResult(r) end
			end)
			return "pending"
		end
	end
	return settle()
end

-- hit = { kind = "Light"|"Heavy"|"Kick", damage, stun, knockback, unblockable, parryable,
--         blockDamageMult, guardBreakStunMult, guardDrain,
--         dir (direccional: AttackDir del atacante), pierces, finisher, onResult(resultado) }
-- Devuelve: "hit" | "blocked" | "parry" | "guardbreak" | "dodged" | "none" | "immune" | "pending"
-- "pending" (solo direccional): el golpe espera el margen de ping; onResult recibe el resultado final.
local resolve
function Combat.deal(attacker, victim, hit)
	local r = resolve(attacker, victim, hit)
	if r ~= "pending" and hit.onResult then hit.onResult(r) end
	return r
end

function resolve(attacker, victim, hit)
	local vHum = getHum(victim)
	if not vHum or not getHum(attacker) or not Combat.isEnemy(attacker, victim) then return "none" end
	if not victim:GetAttribute("CanFight") then return "none" end

	local t = now()
	if (victim:GetAttribute("IFrameUntil") or 0) > t then
		Fx.popAbove(victim, "pop.dodge", C.Dodge)
		return "dodged"
	end
	if (victim:GetAttribute("InvulnUntil") or 0) > t then return "none" end

	local damage = (hit.damage or 0) * (attacker:GetAttribute("DamageMult") or 1)
	-- Infusiones: afinidad, golpe desde las sombras, fragilidad...
	if Combat.hooks.damageMods then
		local dm, sm = Combat.hooks.damageMods(attacker, victim, hit)
		damage *= dm or 1
		if sm and sm ~= 1 then
			hit = table.clone(hit)
			hit.stun = (hit.stun or 0) * sm
		end
	end

	-- Contraataque tras un parry (ventaja breve)
	if (hit.kind == "Light" or hit.kind == "Heavy") and (attacker:GetAttribute("CounterUntil") or 0) > t then
		damage *= CFG.Parry.CounterDamageMult
		attacker:SetAttribute("CounterUntil", 0)
		Fx.popAbove(attacker, "pop.counter", C.ParryFlash)
	end

	if Directional.enabled() then
		return dealDirectional(attacker, victim, hit, damage)
	end

	local blocking = victim:GetAttribute("Blocking")
		and not victim:GetAttribute("Ragdolled")
		and isFacing(victim, attacker)

	if blocking then
		local inParry = t - (victim:GetAttribute("BlockStart") or 0) <= CFG.Block.ParryWindow
		if inParry and hit.parryable ~= false then
			return doParry(victim, attacker)
		end
		if hit.kind == "Kick" then
			return guardBreak(victim, attacker, hit, damage * 0.5, hit.stun or 0)
		elseif hit.kind == "Heavy" then
			if not hit.unblockable then
				-- El fuerte rompe la guardia pasiva
				return guardBreak(victim, attacker, hit,
					damage * (hit.blockDamageMult or 0.5),
					(hit.stun or 0) * (hit.guardBreakStunMult or 1))
			end
			-- imbloqueable: entra como golpe normal
		else
			return doBlocked(victim, attacker, hit, damage)
		end
	end

	return doHit(attacker, victim, hit, damage)
end

----------------------------------------------------------------------
-- Agarrar, cargar al hombro y lanzar (solo a rivales derribados)
--   R junto al derribado -> lo alza (0,5 s) y lo carga sobre los hombros (-20% de velocidad)
--   Clic / R -> tirón corto · Mantener E (o M2) y soltar -> lanzamiento cargado en parábola (~30°)
--   El cargado puede machacar teclas para soltarse antes. Un golpe al que carga lo suelta.
----------------------------------------------------------------------
local GRAB = CFG.Grab

local function detach(entry)
	if entry.deathConnection then entry.deathConnection:Disconnect() end
	if entry.liftConnection then entry.liftConnection:Disconnect() end
	for _, inst in entry.instances do
		if inst.Parent then inst:Destroy() end
	end
	table.clear(entry.instances)
end

-- Separa el cuerpo de quien lo cargaba y le devuelve las colisiones un instante después
-- (si se devuelven en el acto, el cuerpo choca con quien lo lanza y sale disparado de forma rara).
local function releaseBody(char, victim, forward)
	if not victim.Parent then return end
	Ragdoll.setOwner(victim, nil)
	if forward and forward.Magnitude > 0.01 then
		Ragdoll.translate(victim, forward.Unit * 2.2 + Vector3.new(0, 0.4, 0))
	end
	task.delay(GRAB.ReleaseNoCollide, function()
		if victim.Parent and victim:GetAttribute("Ragdolled") and not victim:GetAttribute("CarriedBy") then
			Ragdoll.setCarried(victim, false)
		end
	end)
end

function Combat.victimOf(char)
	local c = carrying[char]
	return c and c.victim or nil
end

-- Suelta al que cargas. mode: "drop" (cae a tus pies), "escape" (se libera), "throw" (lo gestiona throw)
function Combat.drop(attackerChar, mode)
	local c = carrying[attackerChar]
	if not c then return nil end
	carrying[attackerChar] = nil
	detach(c)
	attackerChar:SetAttribute("Carrying", false)
	attackerChar:SetAttribute("ThrowCharging", false)
	Combat.refreshSpeed(attackerChar)
	local victim = c.victim
	if victim.Parent then
		victim:SetAttribute("CarriedBy", false)
		victim:SetAttribute("CarryEndsAt", 0)
		local root = attackerChar:FindFirstChild("HumanoidRootPart")
		local look = root and root.CFrame.LookVector * Vector3.new(1, 0, 1) or Vector3.zero
		if mode == "throw" then
			-- throw() lo coloca y le da velocidad; aquí solo se separa
			releaseBody(attackerChar, victim, nil)
		else
			releaseBody(attackerChar, victim, look)
			local t = now()
			victim:SetAttribute("KnockdownEndsAt", t + (mode == "escape" and GRAB.EscapeGetUp or GRAB.DropGetUp))
			Ragdoll.fling(victim, look * 10 + Vector3.new(0, 4, 0), nil)
			if mode == "escape" then
				Fx.popAbove(victim, "pop.escaped", C.Bone)
				Combat.stagger(attackerChar, 0.4, "Generic.HitReactFront")
			end
		end
	end
	return victim
end

-- Busca un rival derribado cerca
function Combat.findGrabTarget(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	for _, model in CollectionService:GetTagged(Combat.TAG) do
		if model ~= char and model:GetAttribute("Ragdolled") and model:GetAttribute("KnockedDown")
			and not model:GetAttribute("CarriedBy") and getHum(model) and Combat.isEnemy(char, model) then
			local vroot = model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
			if vroot and (vroot.Position - root.Position).Magnitude <= GRAB.Range then
				return model
			end
		end
	end
	return nil
end

-- Posición del cargado respecto al torso de quien carga: tumbado boca arriba, cruzado por encima
-- de la cabeza (cabeza a la derecha, piernas a la izquierda), sostenido con los dos brazos en alto.
local function carryOffset()
	return CFrame.fromMatrix(Vector3.new(0, GRAB.CarryHeight, GRAB.CarryForward),
		Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))
end

-- Suelda el torso del derribado al torso de quien carga. Con una soldadura (y no fuerzas) el cuerpo
-- forma parte del ensamblaje de quien carga: no hay retraso, ni tirones, ni rebotes. Brazos y piernas
-- siguen colgando con el ragdoll. El paso del suelo a la posición final se interpola (LiftBlend).
local function attachOverhead(char, victim)
	local torso = char:FindFirstChild("UpperTorso")
	local vtorso = victim:FindFirstChild("UpperTorso")
	if not torso or not vtorso then return nil end
	local entry = { victim = victim, instances = {} }

	local target = carryOffset()
	local start = torso.CFrame:ToObjectSpace(vtorso.CFrame)
	-- Si el cuerpo estaba muy lejos (lag), empezar más cerca para no cruzar el mapa
	if start.Position.Magnitude > 12 then start = target * CFrame.new(0, -4, 0) end

	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = torso
	weld.Part1 = vtorso
	weld.C0 = start
	weld.C1 = CFrame.identity
	weld.Parent = vtorso
	table.insert(entry.instances, weld)
	entry.weld = weld

	-- Subida suave hasta encima de la cabeza
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not weld.Parent then conn:Disconnect() return end
		local a = math.clamp((os.clock() - t0) / GRAB.LiftBlend, 0, 1)
		a = 1 - (1 - a) ^ 3
		weld.C0 = start:Lerp(target, a)
		if a >= 1 then conn:Disconnect() end
	end)
	entry.liftConnection = conn
	return entry
end

function Combat.grab(char)
	if carrying[char] or not Combat.canAct(char) or Combat.isBusy(char) then return false end
	local victim = Combat.findGrabTarget(char)
	if not victim then return false end
	Combat.blockEnd(char, true)

	-- Reservar al derribado para que nadie más lo agarre
	victim:SetAttribute("CarriedBy", true)
	local token = Combat.beginAction(char, "PickUp", GRAB.PickUpTime, "Active")
	Anim.play(char, "Generic.PickUp", { duration = GRAB.PickUpTime })
	Fx.soundAt("PickUp", char)

	task.delay(GRAB.PickUpTime * 0.55, function()
		if not Combat.valid(char, token) or not victim.Parent or not getHum(victim)
			or not victim:GetAttribute("Ragdolled") then
			if victim.Parent then victim:SetAttribute("CarriedBy", false) end
			return
		end
		-- Sin colisiones ni peso ANTES de soldarlo (si no, empuja a quien lo carga)
		Ragdoll.setCarried(victim, true)
		local entry = attachOverhead(char, victim)
		if not entry then
			Ragdoll.setCarried(victim, false)
			victim:SetAttribute("CarriedBy", false)
			return
		end
		carrying[char] = entry
		char:SetAttribute("Carrying", true)
		victim:SetAttribute("CarryEndsAt", now() + GRAB.MaxCarryTime)
		-- Las extremidades (ensamblajes sueltos) las simula quien carga: cuelgan sin tirones
		Ragdoll.setOwner(victim, Players:GetPlayerFromCharacter(char))
		Fx.popAbove(char, "pop.grabbed", C.TelegraphHeavy)
		Combat.refreshSpeed(char)

		local vhum = getHum(victim)
		if vhum then
			entry.deathConnection = vhum.Died:Connect(function()
				if carrying[char] == entry then Combat.drop(char, "drop") end
			end)
		end
	end)
	task.delay(GRAB.PickUpTime, function()
		if not Combat.valid(char, token) then
			if carrying[char] == nil and victim.Parent then
				victim:SetAttribute("CarriedBy", false)
			end
			return
		end
		Combat.endAction(char, token)
	end)
	return true
end

-- El cargado machaca teclas: se acerca el momento de soltarse
function Combat.struggle(victim)
	if not victim:GetAttribute("CarriedBy") then return end
	local endsAt = (victim:GetAttribute("CarryEndsAt") or 0) - GRAB.StruggleReduce
	victim:SetAttribute("CarryEndsAt", endsAt)
end

-- Empezar a cargar el lanzamiento (mantener E / M2)
function Combat.throwChargeStart(char)
	if not carrying[char] or Combat.isBusy(char) or char:GetAttribute("ThrowCharging") then return end
	char:SetAttribute("ThrowCharging", true)
	char:SetAttribute("ThrowChargeStart", now())
	Combat.refreshSpeed(char)
end

-- Lanzar. Sin carga = tirón corto; si se estaba cargando, lanzamiento lejano según la carga
function Combat.throw(char, aim)
	local c = carrying[char]
	if not c or Combat.isBusy(char) then return false end
	local far = false
	local power = 0
	if char:GetAttribute("ThrowCharging") then
		far = true
		power = math.clamp((now() - (char:GetAttribute("ThrowChargeStart") or now())) / GRAB.ChargeTime, 0, 1)
	end
	char:SetAttribute("ThrowCharging", false)
	CombatEvents.noteAttacker(c.victim, char)
	CombatEvents.fire("Throw", char, c.victim)

	local root = char:FindFirstChild("HumanoidRootPart")
	local dir = (typeof(aim) == "Vector3" and Vector3.new(aim.X, 0, aim.Z)) or Vector3.zero
	if dir.Magnitude < 0.1 and root then dir = root.CFrame.LookVector * Vector3.new(1, 0, 1) end
	dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.zAxis

	local duration = far and GRAB.ThrowFarTime or GRAB.ThrowShortTime
	local releaseAt = duration * (far and 0.48 or 0.4)
	local key = far and "Generic.ThrowFar" or "Generic.ThrowShort"
	local token = Combat.beginAction(char, "Throw", duration, "Windup")
	Anim.play(char, key, { duration = duration, hitTime = releaseAt })

	task.delay(releaseAt, function()
		if not Combat.valid(char, token) or carrying[char] ~= c then return end
		local victim = Combat.drop(char, "throw")
		if not victim or not getHum(victim) then return end
		local ang = math.rad(far and GRAB.FarAngle or GRAB.ShortAngle)
		local speed = far and (GRAB.FarSpeed + GRAB.FarSpeedCharged * power) or GRAB.ShortSpeed
		local vel = (dir * math.cos(ang) + Vector3.yAxis * math.sin(ang)) * speed
		local right = dir:Cross(Vector3.yAxis)
		-- Sale por delante de quien lanza (no a través de él) y con la velocidad del lanzamiento
		Ragdoll.translate(victim, dir * 2.6 + Vector3.new(0, 0.3, 0))
		Ragdoll.fling(victim, vel, right * -(far and 9 or 5))
		-- El cambio de dueño de red (cliente -> servidor) puede pisar la velocidad el primer frame: se reaplica
		task.delay(0.07, function()
			local torso = victim:FindFirstChild("UpperTorso")
			if torso and victim:GetAttribute("Ragdolled") and torso.AssemblyLinearVelocity.Magnitude < speed * 0.45 then
				Ragdoll.fling(victim, vel, nil)
			end
		end)
		applyDamage(char, victim, far and (GRAB.FarDamage + GRAB.FarDamageCharged * power) or GRAB.ShortDamage)
		victim:SetAttribute("KnockdownEndsAt", now() + GRAB.LandGetUp + (far and (0.6 + power * 0.6) or 0.3))
		Fx.soundAt(far and "Throw_Far" or "Throw_Short", char)
		local label = "pop.out"
		if far then label = power >= 0.95 and "pop.maxThrow" or "pop.thrown" end
		Fx.popAbove(victim, label, C.TelegraphHeavy)
		Fx.shake(char, far and 0.4 or 0.25, dir)

		-- Aterrizaje: polvo y golpe seco
		local torso = victim:FindFirstChild("UpperTorso")
		if torso then
			local landed = false
			local conn
			conn = torso.Touched:Connect(function(other)
				if landed or other:IsDescendantOf(victim) or other:IsDescendantOf(char) then return end
				if other.Parent and other.Parent:FindFirstChildOfClass("Humanoid") then return end
				landed = true
				conn:Disconnect()
				Fx.dust(torso.Position - Vector3.new(0, 1, 0), far and 1.4 or 1)
				Fx.soundAt("Throw_Impact", victim)
				Fx.shake(victim, 0.6)
			end)
			task.delay(4, function()
				if conn.Connected then conn:Disconnect() end
			end)
		end
	end)
	task.delay(duration, function()
		Combat.endAction(char, token)
	end)
	return true
end

-- Revisa cada tick si el cargado ya se liberó
function Combat.checkCarry(char)
	local c = carrying[char]
	if not c then return end
	local victim = c.victim
	if not victim.Parent or not getHum(victim) then
		Combat.drop(char, "drop")
	elseif now() >= (victim:GetAttribute("CarryEndsAt") or 0) and not Combat.isBusy(char) then
		Combat.drop(char, "escape")
	end
end

----------------------------------------------------------------------
-- Preparar un luchador (jugador o muñeco)
----------------------------------------------------------------------
function Combat.setupCombatant(char, weaponId)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if not WeaponData.Data[weaponId] then weaponId = "Sword" end
	local def = WeaponData.Data[weaponId]

	if hum.RigType ~= Enum.HumanoidRigType.R15 then
		warn(("[Combat] %s no es R15. Pon Game Settings > Avatar > Avatar Type = R15."):format(char.Name))
	end

	states[char] = nil
	local st = Combat.state(char)
	st.token = 1

	hum.MaxHealth = def.hp
	hum.Health = def.hp
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false

	local guardMax = def.guardMax or CFG.Guard.DefaultMax
	char:SetAttribute("WeaponId", weaponId)
	char:SetAttribute("BaseSpeed", def.speed)
	-- Al cambiar de arma en el lobby se conserva CanFight (la práctica sigue activa)
	char:SetAttribute("CanFight", char:GetAttribute("CanFight") == true)
	char:SetAttribute("Frozen", false)
	char:SetAttribute("Blocking", false)
	char:SetAttribute("BlockStart", 0)
	char:SetAttribute("Carrying", false)
	char:SetAttribute("CarriedBy", false)
	char:SetAttribute("Stun", 0)
	char:SetAttribute("Guard", guardMax)
	char:SetAttribute("GuardMax", guardMax)
	char:SetAttribute("GuardBroken", false)
	char:SetAttribute("InfusionCharge", 0)
	char:SetAttribute("Stamina", CFG.Stamina.Max)
	char:SetAttribute("StaminaMax", CFG.Stamina.Max)
	char:SetAttribute("ComboStep", 0)
	char:SetAttribute("KnockedDown", false)
	char:SetAttribute("GuardMaxBase", guardMax)
	-- Modificadores (los cambia la infusión activa; 1 = sin cambios)
	for _, attr in { "DamageMult", "AttackSpeedMult", "MoveSpeedMult", "StunMult", "GuardDrainMult",
		"GuardRegenMult", "DodgeDistanceMult" } do
		char:SetAttribute(attr, 1)
	end
	char:SetAttribute("DodgeIFrameBonus", 0)
	char:SetAttribute("InfusionActive", false)
	char:SetAttribute("InfusionEndsAt", 0)
	char:SetAttribute("InfusionLockUntil", 0)
	char:SetAttribute("InfusedHeavyUnblockable", false)
	char:SetAttribute("SlowUntil", 0)
	clearActionAttrs(char)
	Directional.setup(char) -- C16: Stance, AttackDir, CombatState, StateEnds (también con Enabled = false)
	CollectionService:AddTag(char, Combat.TAG)
	Combat.refreshSpeed(char)

	-- Pose de reposo del arma (si existe la animación)
	Anim.play(char, "Weapons." .. weaponId .. ".Idle", { priority = Enum.AnimationPriority.Idle, looped = true, fade = 0.2 })

	hum.Died:Connect(function()
		CombatEvents.fire("Kill", CombatEvents.lastAttacker(char), char)
		Combat.drop(char)
		Combat.cancelAction(char)
	end)
	return def
end

-- Arma del jugador según su elección y skin
function Combat.setupCharacter(player, char)
	local def = Combat.setupCombatant(char, player:GetAttribute("WeaponId"))
	if not def then return end
	local weaponId = char:GetAttribute("WeaponId")
	local hum = char:FindFirstChildOfClass("Humanoid")
	char:SetAttribute("InfusionId", player:GetAttribute("InfusionId") or "Fire")
	-- En partida, la carga de infusión se conserva de una ronda a la siguiente
	if player:GetAttribute("InMatch") then
		char:SetAttribute("InfusionCharge", player:GetAttribute("MatchInfusionCharge") or 0)
	end

	local backpack = player:WaitForChild("Backpack", 3)
	if not backpack then return end
	for _, t in backpack:GetChildren() do
		if t:IsA("Tool") then t:Destroy() end
	end
	for _, t in char:GetChildren() do
		if t:IsA("Tool") then t:Destroy() end
	end
	local tool = WeaponBuilder.build(weaponId, player:GetAttribute("EquippedSkin"))
	tool.Parent = backpack
	hum:EquipTool(tool)
	WeaponBuilder.addOffhand(char, weaponId, player:GetAttribute("EquippedSkin"))
end

----------------------------------------------------------------------
-- Bucle: vaciado de Stun, regeneración de Guardia, fin de derribos y velocidad
----------------------------------------------------------------------
local accum = 0
RunService.Heartbeat:Connect(function(dt)
	accum += dt
	if accum < 0.1 then return end
	local step = accum
	accum = 0
	local t = now()

	for _, char in CollectionService:GetTagged(Combat.TAG) do
		local hum = getHum(char)
		if hum then
			local st = Combat.state(char)

			-- Derribo por Stun: se levanta al llegar KnockdownEndsAt (no mientras lo cargan)
			if char:GetAttribute("KnockedDown") and char:GetAttribute("Ragdolled") and not char:GetAttribute("CarriedBy")
				and t >= (char:GetAttribute("KnockdownEndsAt") or 0) then
				st.getUpFront = Ragdoll.isFaceDown(char)
				Ragdoll.disable(char)
			end

			if char:GetAttribute("Carrying") then Combat.checkCarry(char) end

			-- Stamina: se regenera tras un momento sin gastar
			local smax = char:GetAttribute("StaminaMax") or CFG.Stamina.Max
			local stam = char:GetAttribute("Stamina") or smax
			if stam < smax and t - st.lastStaminaUseAt >= CFG.Stamina.RegenDelay then
				local regen = CFG.Stamina.RegenPerSecond * (char:GetAttribute("Blocking") and CFG.Stamina.BlockRegenMult or 1)
				char:SetAttribute("Stamina", math.min(smax, stam + regen * step))
			end

			-- Fin del derribo por Stun: al levantarse, Stun a 0 e inmunidad breve
			if char:GetAttribute("KnockedDown") and not char:GetAttribute("Ragdolled") then
				char:SetAttribute("KnockedDown", false)
				char:SetAttribute("Stun", 0)
				char:SetAttribute("KnockdownImmuneUntil", t + CFG.Knockdown.ImmuneAfter)
				Anim.play(char, st.getUpFront and "Generic.GetUpFront" or "Generic.GetUpBack", { duration = 0.85 })
				st.getUpFront = false
				if st.wantsBlock then Combat.blockStart(char, true) end
			end

			-- Stun: se vacía rápido tras unos segundos sin recibir
			local stun = char:GetAttribute("Stun") or 0
			if stun > 0 and not char:GetAttribute("KnockedDown") and t - st.lastStunAt >= CFG.Stun.DecayDelay then
				char:SetAttribute("Stun", math.max(0, stun - CFG.Stun.DecayPerSecond * step))
			end

			-- Guardia: se regenera si no bloqueas golpes durante un rato
			local gmax = char:GetAttribute("GuardMax") or CFG.Guard.DefaultMax
			if char:GetAttribute("GuardBroken") and t >= (char:GetAttribute("GuardBrokenUntil") or 0) then
				char:SetAttribute("GuardBroken", false)
				char:SetAttribute("Guard", math.max(char:GetAttribute("Guard") or 0, gmax * CFG.Guard.RefillAfterBreak))
			end
			local guard = char:GetAttribute("Guard") or gmax
			if guard > gmax then
				char:SetAttribute("Guard", gmax) -- la Guardia máxima pudo bajar (infusión de Sombra)
			elseif guard < gmax and not char:GetAttribute("GuardBroken") and t - st.lastGuardUseAt >= CFG.Guard.RegenDelay then
				local regen = CFG.Guard.RegenPerSecond * (char:GetAttribute("GuardRegenMult") or 1)
				if (char:GetAttribute("GuardRegenSlowUntil") or 0) > t then regen *= 0.5 end -- quemadura
				char:SetAttribute("Guard", math.min(gmax, guard + regen * step))
			end

			-- Si quería bloquear y ya puede, vuelve a la guardia
			if st.wantsBlock and not char:GetAttribute("Blocking") and st.busyUntil <= t and Combat.canAct(char)
				and (char:GetAttribute("GuardBrokenUntil") or 0) <= t then
				Combat.blockStart(char, true)
			end

			Combat.refreshSpeed(char)
		end
	end
end)

-- Máquina de estados direccional (C16): cada frame, para que el triángulo del rival reaccione al instante.
-- Se publica siempre (aunque Enabled sea false) para que el HUD y Codex puedan leerla.
RunService.Heartbeat:Connect(function()
	for _, char in CollectionService:GetTagged(Combat.TAG) do
		if char.Parent and getHum(char) then
			Directional.refresh(char, Combat.state(char))
		end
	end
end)

return Combat
