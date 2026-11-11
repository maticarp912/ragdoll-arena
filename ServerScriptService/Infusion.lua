-- ModuleScript: ServerScriptService/Infusion
-- Infusión = la "ulti". Con la barra llena, Q enciende el arma (Infusions.Duration s).
-- Mientras está activa:
--   · tus atributos cambian (mods de ReplicatedStorage/Infusions)
--   · tus golpes básicos y fuertes aplican su efecto al rival (quemadura, descarga, escarcha, sombra)
--   · tu fuerte es imbloqueable (pero parreable y esquivable)
--   · afinidad ±8 % según el emparejamiento (Fuego > Rayo > Hielo > Sombra > Fuego)
-- Se conecta al combate mediante Combat.hooks (sin dependencias circulares).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Infusions = require(ReplicatedStorage:WaitForChild("Infusions"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Anim = require(ServerScriptService:WaitForChild("Anim"))
local Fx = require(ServerScriptService:WaitForChild("Fx"))

local Infusion = {}
local now = Combat.now

local MOD_ATTRS = { "DamageMult", "AttackSpeedMult", "MoveSpeedMult", "StunMult", "GuardDrainMult",
	"GuardRegenMult", "DodgeDistanceMult" }

local hitCounts = setmetatable({}, { __mode = "k" }) -- [atacante] = { [víctima] = golpes }
local burns = setmetatable({}, { __mode = "k" })     -- [víctima] = { endsAt, dps, attacker }

local function activeDef(char)
	if not char or not char:GetAttribute("InfusionActive") then return nil, nil end
	local id = char:GetAttribute("InfusionId")
	return Infusions.get(id), id
end
Infusion.activeDef = activeDef

local function bump(attacker, victim)
	local list = hitCounts[attacker]
	if not list then
		list = setmetatable({}, { __mode = "k" })
		hitCounts[attacker] = list
	end
	list[victim] = (list[victim] or 0) + 1
	return list[victim]
end

----------------------------------------------------------------------
-- Encender / apagar
----------------------------------------------------------------------
function Infusion.activate(char)
	local player = Players:GetPlayerFromCharacter(char)
	local id = char:GetAttribute("InfusionId")
	local def = Infusions.get(id)
	if not def then
		Fx.toast(player, { key = "toast.pickInfusion" })
		return false
	end
	if char:GetAttribute("InfusionActive") then return false end
	local t = now()
	if (char:GetAttribute("InfusionLockUntil") or 0) > t then
		Fx.toast(player, { key = "toast.infusionExhausted" })
		return false
	end
	local charge = char:GetAttribute("InfusionCharge") or 0
	if charge < CombatConfig.InfusionCharge.Max then
		Fx.toast(player, { key = "toast.infusionCharging", params = { n = math.floor(charge) } })
		return false
	end
	if not Combat.canAct(char) or Combat.isBusy(char) then return false end
	if char:GetAttribute("Blocking") then Combat.blockEnd(char, true, true) end

	char:SetAttribute("InfusionActive", true)
	char:SetAttribute("InfusionEndsAt", t + Infusions.Duration)
	char:SetAttribute("InfusionLockUntil", t + Infusions.Duration + Infusions.Exhaust)
	for attr, v in def.mods do char:SetAttribute(attr, v) end
	if def.guardMaxMult then
		local base = char:GetAttribute("GuardMaxBase") or char:GetAttribute("GuardMax") or 100
		char:SetAttribute("GuardMax", base * def.guardMaxMult)
	end
	char:SetAttribute("InfusedHeavyUnblockable", Infusions.InfusedHeavyUnblockable == true)
	Combat.refreshSpeed(char)

	local token = Combat.beginAction(char, "Infuse", Infusions.ActivateTime, "Active")
	Anim.play(char, "Generic.InfuseActivate", { duration = Infusions.ActivateTime })
	task.delay(Infusions.ActivateTime, function() Combat.endAction(char, token) end)

	Fx.popAbove(char, "pop.infusion." .. id, def.color)
	Fx.soundAt("Infusion." .. id .. ".Start", char, 1)
	Fx.soundAt("Infusion_MeterFull", char, 0.7)
	Fx.soundAt("Cue_HeavyWindup", char, 0.6)
	Fx.shake(char, 0.35)
	return true
end

function Infusion.deactivate(char)
	if not char:GetAttribute("InfusionActive") then return end
	char:SetAttribute("InfusionActive", false)
	char:SetAttribute("InfusionCharge", 0)
	for _, attr in MOD_ATTRS do char:SetAttribute(attr, 1) end
	char:SetAttribute("DodgeIFrameBonus", 0)
	char:SetAttribute("InfusedHeavyUnblockable", false)
	char:SetAttribute("ShadowStrikeUntil", 0)
	local base = char:GetAttribute("GuardMaxBase")
	if base then char:SetAttribute("GuardMax", base) end
	Combat.refreshSpeed(char)
	Fx.soundAt("Infusion." .. tostring(char:GetAttribute("InfusionId")) .. ".End", char, 0.8)
	-- 11/11/2026: si elegiste otra infusión mientras esta estaba encendida, ahora se aplica la elegida
	-- (antes el personaje se quedaba con la vieja, casi siempre Fuego)
	local player = Players:GetPlayerFromCharacter(char)
	local chosen = player and player:GetAttribute("InfusionId")
	if chosen and chosen ~= char:GetAttribute("InfusionId") then char:SetAttribute("InfusionId", chosen) end
end

-- Sombra: tras esquivar, el siguiente golpe es más fuerte
function Infusion.onDodge(char)
	local def, id = activeDef(char)
	if id == "Shadow" then
		char:SetAttribute("ShadowStrikeUntil", now() + def.onHit.afterDodgeWindow)
	end
end

----------------------------------------------------------------------
-- Efectos sobre el rival
----------------------------------------------------------------------
local function burn(victim, attacker, dps, duration)
	local endsAt = now() + duration
	burns[victim] = { endsAt = endsAt, dps = dps, attacker = attacker }
	victim:SetAttribute("BurnUntil", endsAt)
	victim:SetAttribute("GuardRegenSlowUntil", endsAt)
end

local function isBehind(attacker, victim)
	local a = attacker:FindFirstChild("HumanoidRootPart")
	local v = victim:FindFirstChild("HumanoidRootPart")
	if not a or not v then return false end
	local toA = (a.Position - v.Position) * Vector3.new(1, 0, 1)
	if toA.Magnitude < 0.01 then return false end
	return v.CFrame.LookVector:Dot(toA.Unit) < -0.3
end

-- Multiplicadores de daño y Stun antes de resolver el golpe
Combat.hooks.damageMods = function(attacker, victim, hit)
	local dm, sm = 1, 1
	local t = now()
	-- Fragilidad (Hielo): recibe más daño de cualquiera
	if (victim:GetAttribute("FragileUntil") or 0) > t then
		dm *= victim:GetAttribute("FragileMult") or 1
	end
	if hit.kind ~= "Light" and hit.kind ~= "Heavy" then return dm, sm end
	local def, id = activeDef(attacker)
	if not def then return dm, sm end

	-- 11/11/2026: «pelea de infusiones». La ventaja o debilidad solo cuenta si el rival también tiene la suya
	-- encendida. Una infusión apagada no tiene ningún efecto en el PvP.
	local m = victim:GetAttribute("InfusionActive") == true and Infusions.matchup(id, victim:GetAttribute("InfusionId")) or 0
	if m ~= 0 then
		dm *= 1 + m * Infusions.Affinity
		sm *= 1 + m * Infusions.Affinity
	end
	if id == "Shadow" then
		if (attacker:GetAttribute("ShadowStrikeUntil") or 0) > t then
			dm *= def.onHit.afterDodge
			attacker:SetAttribute("ShadowStrikeUntil", 0)
			Fx.popAbove(attacker, "pop.fromShadows", def.color)
		end
		if isBehind(attacker, victim) then dm *= def.onHit.backstab end
	end
	return dm, sm
end

Combat.hooks.onHit = function(attacker, victim, hit, _damage)
	if hit.kind ~= "Light" and hit.kind ~= "Heavy" then return end
	local def, id = activeDef(attacker)
	if not def then return end
	local oh = def.onHit
	local t = now()
	local pos, dir = Fx.impactPoint(attacker, victim)
	Fx.infusionHit(pos, id, dir)
	Fx.soundAt("Infusion." .. id .. ".Hit", victim, 0.9)

	if id == "Fire" then
		burn(victim, attacker, oh.burnDps, oh.burnDuration)
	elseif id == "Lightning" then
		if bump(attacker, victim) % oh.shockEvery == 0 and not victim:GetAttribute("Ragdolled") then
			Combat.stagger(victim, oh.shockStagger, "Generic.HitReactFront")
			victim:SetAttribute("ShockedAt", t)
			Fx.popAbove(victim, "pop.discharge", def.color)
			Fx.soundAt("Status_ShockZap", victim, 1)
		end
	elseif id == "Ice" then
		victim:SetAttribute("SlowMult", oh.slowMult)
		victim:SetAttribute("SlowUntil", t + oh.slowDuration)
		Combat.refreshSpeed(victim)
		task.delay(oh.slowDuration + 0.05, function()
			if victim.Parent then Combat.refreshSpeed(victim) end
		end)
		if bump(attacker, victim) % oh.fragileEvery == 0 then
			victim:SetAttribute("FragileMult", oh.fragileMult)
			victim:SetAttribute("FragileUntil", t + oh.fragileDuration)
			Fx.popAbove(victim, "pop.fragile", def.color)
			Fx.soundAt("Status_SlowFreeze", victim, 1)
		end
	end
end

Combat.hooks.onBlocked = function(attacker, victim, hit, damage)
	if hit.kind ~= "Light" and hit.kind ~= "Heavy" then return end
	local def, id = activeDef(attacker)
	if not def then return end
	if id == "Fire" and def.onHit.chip > 0 then
		-- El fuego atraviesa parte del bloqueo
		Combat.applyDamage(attacker, victim, damage * def.onHit.chip)
		local pos, dir = Fx.impactPoint(attacker, victim)
		Fx.infusionHit(pos, id, dir)
	elseif id == "Ice" then
		local t = now()
		victim:SetAttribute("SlowMult", def.onHit.slowMult)
		victim:SetAttribute("SlowUntil", t + def.onHit.slowDuration * 0.5)
		Combat.refreshSpeed(victim)
	end
end

----------------------------------------------------------------------
-- Bucle: duración de la infusión y quemaduras
----------------------------------------------------------------------
local accum = 0
RunService.Heartbeat:Connect(function(dt)
	accum += dt
	if accum < 0.25 then return end
	local step = accum
	accum = 0
	local t = now()
	local max = CombatConfig.InfusionCharge.Max

	for _, char in CollectionService:GetTagged(Combat.TAG) do
		if char:GetAttribute("InfusionActive") then
			local hum = Combat.getHum(char)
			local endsAt = char:GetAttribute("InfusionEndsAt") or 0
			if not hum or t >= endsAt then
				Infusion.deactivate(char)
			else
				-- La barra se vacía mientras dura (la lee el HUD)
				char:SetAttribute("InfusionCharge", max * math.clamp((endsAt - t) / Infusions.Duration, 0, 1))
			end
		end
	end

	for victim, b in burns do
		local hum = victim.Parent and Combat.getHum(victim)
		if not hum or t >= b.endsAt then
			burns[victim] = nil
		else
			local amount = b.dps * step
			if b.attacker and b.attacker.Parent then
				Combat.applyDamage(b.attacker, victim, amount)
			else
				hum:TakeDamage(amount)
			end
		end
	end
end)

return Infusion
