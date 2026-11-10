-- ModuleScript: ServerScriptService/Actions
-- Acciones de combate (M1, fuerte, patada, esquiva, R contextual, infusión).
-- Las usan CombatService (jugadores) y Dummies (muñecos): misma lógica para ambos.
-- Tiempos: si la animación tiene marcadores (Hit / WindupEnd) se usan; si no, los de WeaponData.
-- La duración total la marcan los datos; la animación se acelera/frena para encajar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local Assets = require(ReplicatedStorage:WaitForChild("Assets"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Anim = require(ServerScriptService:WaitForChild("Anim"))
local AnimTiming = require(ServerScriptService:WaitForChild("AnimTiming"))
local Fx = require(ServerScriptService:WaitForChild("Fx"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))
local Infusion = require(ServerScriptService:WaitForChild("Infusion"))
local Directional = require(ServerScriptService:WaitForChild("Directional"))
local CombatEvents = require(ServerScriptService:WaitForChild("CombatEvents"))

local Effect = Remotes.get("Effect")
local CFG = CombatConfig
local now = Combat.now

local Actions = {}

-- 0.2: ritmo más lento y parejo (C23) y alcance general +25 % (D1/D3)
local function tempo()
	return (CFG.Feel and CFG.Feel.TempoMult) or 1
end
function Actions.reach(r)
	return r * ((CFG.Directional and CFG.Directional.ReachMult) or 1)
end

-- Resistencia extra al fallar (Estoque, WeaponData.combo.whiffStaminaMult)
local function whiffPenalty(char, kind, mult)
	if not mult or mult <= 1 then return end
	if char:GetAttribute("IsDummy") and not CFG.Stamina.DummiesUseStamina then return end
	local extra = WeaponData.staminaCost(char:GetAttribute("WeaponId"), kind) * (mult - 1)
	char:SetAttribute("Stamina", math.max(0, (char:GetAttribute("Stamina") or 0) - extra))
	Combat.state(char).lastStaminaUseAt = now()
end

-- Calcula velocidad de la animación y tiempos escalados.
-- Devuelve speed (para AdjustSpeed), y una función que convierte un marcador en segundos reales.
local function timing(animKey, duration)
	local info = AnimTiming.get(animKey)
	if not info or info.length <= 0 then
		return 1, function() return nil end
	end
	local speed = info.length / duration
	return speed, function(markerName)
		local m = info.markers[markerName]
		if m then return m / speed end
		return nil
	end
end

-- Paso adelante con el golpe (cada arma avanza distinto: WeaponData.Feel.lunge).
-- Se da justo antes del impacto y se anula si la acción se cortó (parry, golpe recibido...).
local function lunge(char, token, distance, at)
	if not distance or distance <= 0 then return end
	local dur = 0.14
	task.delay(math.max(0, at - dur), function()
		if not Combat.valid(char, token) or char:GetAttribute("Ragdolled") then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local dir = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		if dir.Magnitude < 0.01 then return end
		dir = dir.Unit
		local speed = distance / dur
		local player = Players:GetPlayerFromCharacter(char)
		if player then
			Effect:FireClient(player, "Dash", dir, speed, dur)
		else
			root.AssemblyLinearVelocity = Vector3.new(dir.X * speed, root.AssemblyLinearVelocity.Y, dir.Z * speed)
		end
	end)
end

-- Aplica el golpe a todos los rivales de la caja. Para si el atacante fue parreado.
-- sweetSpot (Estoque): los rivales en el extremo del alcance reciben más daño
local function strike(char, reach, width, hit, sweetSpot)
	local results = {}
	local root = char:FindFirstChild("HumanoidRootPart")
	for _, victim in Combat.hitbox(char, reach, width) do
		local h = hit
		local vr = victim:FindFirstChild("HumanoidRootPart")
		if sweetSpot and root and vr
			and ((vr.Position - root.Position) * Vector3.new(1, 0, 1)).Magnitude >= reach * sweetSpot.from then
			h = table.clone(hit)
			h.damage = (hit.damage or 0) * sweetSpot.mult
		end
		local r = Combat.deal(char, victim, h)
		table.insert(results, r)
		if r == "parry" then break end
	end
	return results
end

----------------------------------------------------------------------
-- M1: combo de 3 golpes (no rompe guardia; drena Guardia)
----------------------------------------------------------------------
function Actions.m1(char)
	if not Combat.canAct(char) then return false end
	local st = Combat.state(char)
	local t = now()

	if st.busyUntil > t then
		-- Buffer: si estás terminando un golpe, encola el siguiente
		if (st.action == "M1" or st.action == "Dodge") and st.busyUntil - t <= CFG.Attack.BufferWindow then
			st.queuedM1 = true
		end
		return false
	end

	if char:GetAttribute("Blocking") then
		Combat.blockEnd(char, true, true) -- atacar desde la guardia; si sigues con F, vuelves a ella
	end

	-- 9/11: los golpes básicos gastan stamina según el arma (WeaponData.stamina.m1)
	if not Combat.spendStamina(char, WeaponData.staminaCost(char:GetAttribute("WeaponId"), "m1")) then return false end

	local def = Combat.weaponOf(char)
	local combo = def.combo
	local step = 1
	if st.comboStep > 0 and st.comboStep < #combo.damage and t <= st.comboExpires then
		step = st.comboStep + 1
	end

	local atkSpeed = char:GetAttribute("AttackSpeedMult") or 1
	local duration = combo.duration[step] * tempo() / atkSpeed
	local wid = char:GetAttribute("WeaponId") or "Sword"
	local animKey = "Weapons." .. wid .. ".M1_" .. step
	local animSpeed, marker = timing(animKey, duration)
	local hitTime = marker("Hit") or (combo.hitTime[step] * tempo() / atkSpeed)

	-- Direccional: el golpe sale por la postura de este momento (D4). Remate si los anteriores conectaron.
	local dirOn = Directional.enabled()
	local dir = dirOn and (char:GetAttribute("Stance") or CFG.Directional.DefaultStance) or ""
	if step == 1 then
		st.comboChain = (st.comboChain or 0) + 1
		st.comboLanded = {}
	end
	local chain = st.comboChain or 0
	local landed = st.comboLanded or {}
	local finisher = dirOn and step == #combo.damage and step > 1
	if finisher then
		for i = 1, step - 1 do
			if not landed[i] then finisher = false break end
		end
	end

	local token = Combat.beginAction(char, "M1", duration, "Windup")
	st.comboStep = step
	st.comboExpires = math.huge
	st.queuedM1 = false
	char:SetAttribute("ComboStep", step)
	char:SetAttribute("HitAt", t + hitTime)
	char:SetAttribute("AttackDir", dir)
	char:SetAttribute("Finisher", finisher == true) -- el remate (D4) se anima más exagerado
	-- Hiperarmadura por golpe (Espadón 2-3, Maza 3): los golpes básicos no lo interrumpen al preparar
	char:SetAttribute("HyperArmor", combo.hyperArmor ~= nil and combo.hyperArmor[step] == true)

	Anim.play(char, animKey, { speed = animSpeed, duration = duration, hitTime = hitTime })
	Fx.soundAt("Swing." .. wid .. ".Light", char)
	lunge(char, token, WeaponData.feel(wid).lunge * (step == #combo.damage and 1.3 or 1), hitTime)

	task.delay(hitTime, function()
		if not Combat.valid(char, token) then return end
		Combat.setPhase(char, "Recovery")
		char:SetAttribute("HitAt", 0)
		char:SetAttribute("HyperArmor", false)
		local F = CFG.Directional.Finisher
		local results = strike(char, Actions.reach(combo.reach), (combo.widths and combo.widths[step]) or combo.width, {
			kind = "Light",
			damage = combo.damage[step] * (finisher and F.DamageMult or 1),
			stun = combo.stun[step] * (finisher and F.StunMult or 1),
			knockback = combo.knockback[step] * (finisher and F.KnockbackMult or 1),
			guardDrainMult = combo.guardDrainMult,
			staggerMult = combo.staggerMult,
			dir = dir,
			finisher = finisher or nil,
			onResult = function(r)
				if r == "hit" and st.comboChain == chain and st.comboLanded then st.comboLanded[step] = true end
			end,
		}, combo.sweetSpot)
		if #results == 0 then whiffPenalty(char, "m1", combo.whiffStaminaMult) end
	end)

	task.delay(duration, function()
		if not Combat.valid(char, token) then return end
		local queued = st.queuedM1
		st.comboExpires = now() + CFG.Attack.ComboResetTime
		if step >= #combo.damage then
			st.comboStep = 0
			char:SetAttribute("ComboStep", 0)
		end
		Combat.endAction(char, token)
		if queued then
			st.queuedM1 = false
			Actions.m1(char)
		end
	end)
	return true
end

----------------------------------------------------------------------
-- Fuerte (E / M2): preparación con aviso, rompe guardia pasiva
----------------------------------------------------------------------
function Actions.heavy(char)
	if not Combat.canAct(char) then return false end
	local st = Combat.state(char)
	local t = now()
	if st.busyUntil > t or t < st.heavyReadyAt then return false end
	if not Combat.spendStamina(char, WeaponData.staminaCost(char:GetAttribute("WeaponId"), "heavy")) then return false end

	if char:GetAttribute("Blocking") then
		Combat.blockEnd(char, true, true)
	end

	local def = Combat.weaponOf(char)
	local h = def.heavy
	local atkSpeed = char:GetAttribute("AttackSpeedMult") or 1
	local wid = char:GetAttribute("WeaponId") or "Sword"
	local animKey = "Weapons." .. wid .. ".Heavy"

	local baseWindup = h.windup * tempo() / atkSpeed
	local baseHit = baseWindup + h.hitDelay * tempo() / atkSpeed
	local duration = baseHit + h.recovery * tempo() / atkSpeed
	local animSpeed, marker = timing(animKey, duration)
	local windup = marker("WindupEnd") or baseWindup
	local hitTime = marker("Hit") or math.max(baseHit, windup + 0.02)

	-- Imbloqueable: por arma, o por estar con la infusión activa (decisión 2, Fase C).
	-- Direccional: la excepción de cada arma depende de la dirección (Maza: solo arriba).
	local dirOn = Directional.enabled()
	local dir = dirOn and (char:GetAttribute("Stance") or CFG.Directional.DefaultStance) or ""
	local infused = char:GetAttribute("InfusedHeavyUnblockable") == true
	local unblockable
	if dirOn then
		unblockable = Directional.heavyUnblockable(char, dir) or infused
	else
		unblockable = h.unblockable or infused
	end

	local token = Combat.beginAction(char, "Heavy", duration, "Windup")
	st.comboStep = 0
	char:SetAttribute("ComboStep", 0)
	st.windupEnd = t + windup
	char:SetAttribute("HitAt", t + hitTime)
	char:SetAttribute("AttackDir", dir)
	char:SetAttribute("Telegraph", unblockable and "Unblockable" or "Heavy")
	char:SetAttribute("HyperArmor", h.hyperArmor == true)

	Anim.play(char, animKey, { speed = animSpeed, duration = duration, windup = windup, hitTime = hitTime })
	Fx.soundAt(unblockable and "Cue_Unblockable" or "Cue_HeavyWindup", char, 1)
	lunge(char, token, WeaponData.feel(wid).lunge * 1.5, hitTime)

	-- Fin de la preparación: se acaba la hiperarmadura y la finta
	task.delay(windup, function()
		if not Combat.valid(char, token) then return end
		Combat.setPhase(char, "Active")
		char:SetAttribute("HyperArmor", false)
	end)

	task.delay(hitTime, function()
		if not Combat.valid(char, token) then return end
		Combat.setPhase(char, "Recovery")
		char:SetAttribute("HitAt", 0)
		char:SetAttribute("Telegraph", "")
		Fx.soundAt("Swing." .. wid .. ".Heavy", char)
		local results = strike(char, Actions.reach(h.reach), h.width, {
			kind = "Heavy",
			damage = h.damage,
			stun = h.stun,
			knockback = h.knockback,
			unblockable = unblockable,
			blockDamageMult = h.blockDamageMult,
			guardBreakStunMult = h.guardBreakStunMult,
			dir = dir,
			pierces = dirOn and Directional.heavyPierces(char) or nil,
		})
		if #results == 0 then whiffPenalty(char, "heavy", def.combo.whiffStaminaMult) end
	end)

	task.delay(duration, function()
		if not Combat.valid(char, token) then return end
		st.heavyReadyAt = now() + CFG.Attack.HeavyCooldown
		Combat.endAction(char, token)
	end)
	return true
end

----------------------------------------------------------------------
-- Patada (R en neutro): rompe la guardia pasiva, no se parrea, se esquiva
----------------------------------------------------------------------
function Actions.kick(char)
	if not Combat.canAct(char) then return false end
	local st = Combat.state(char)
	local t = now()
	if st.busyUntil > t or t < st.kickReadyAt then return false end
	if not Combat.spendStamina(char, CFG.Stamina.Kick) then return false end
	if char:GetAttribute("Blocking") then Combat.blockEnd(char, true, true) end

	local K = CFG.Kick
	-- Direccional: tiempos propios y castigo si la patada no conecta
	local DK = Directional.enabled() and CFG.Directional.Kick or nil
	local windupT = DK and DK.Windup or K.Windup
	local duration = windupT + (DK and DK.Recovery or K.Recovery)
	local animSpeed, marker = timing("Generic.Kick", duration)
	local hitTime = marker("Hit") or windupT

	local token = Combat.beginAction(char, "Kick", duration, "Windup")
	st.kickReadyAt = t + (DK and DK.Cooldown or K.Cooldown)
	st.comboStep = 0
	char:SetAttribute("HitAt", t + hitTime)
	Anim.play(char, "Generic.Kick", { speed = animSpeed, duration = duration, hitTime = hitTime })
	Fx.soundAt("Kick_Swing", char)

	local whiffed = false
	task.delay(hitTime, function()
		if not Combat.valid(char, token) then return end
		Combat.setPhase(char, "Recovery")
		char:SetAttribute("HitAt", 0)
		local results = strike(char, K.Reach, K.Width, {
			kind = "Kick",
			damage = K.Damage,
			stun = K.Stun,
			knockback = K.Knockback,
			parryable = K.Parryable,
		})
		if #results > 0 then
			Fx.soundAt("Kick_Hit", char)
		elseif DK then
			-- Patada al aire: recuperación larga (se ve venir, se castiga)
			whiffed = true
			st.kickWhiffToken = token -- la esquiva no cancela esta recuperación
			st.busyUntil = math.max(st.busyUntil, now() + (duration - hitTime) + DK.WhiffRecovery)
		end
	end)

	task.delay(duration, function()
		if whiffed and DK then
			task.delay(DK.WhiffRecovery, function() Combat.endAction(char, token) end)
		else
			Combat.endAction(char, token)
		end
	end)
	return true
end

----------------------------------------------------------------------
-- Direccional (D1): F sobre un rival derribado. Tocar = patearlo 2 studs; mantener = levantarlo.
-- Sin derribado cerca, F es la patada normal. El servidor decide con su propio reloj (no confía en el cliente).
----------------------------------------------------------------------
-- Patada a un derribado: lo empuja (sirve para sacarlo por el borde). No hace daño.
function Actions.kickDowned(char, victim)
	if not Combat.canAct(char) or Combat.isBusy(char) then return false end
	local st = Combat.state(char)
	local t = now()
	if t < st.kickReadyAt then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	local vbody = victim and (victim:FindFirstChild("UpperTorso") or victim:FindFirstChild("HumanoidRootPart"))
	if not root or not vbody then return false end
	if not Combat.spendStamina(char, CFG.Stamina.Kick) then return false end
	local DK = CFG.Directional.Kick
	local duration = DK.Windup + DK.Recovery * 0.6
	local token = Combat.beginAction(char, "Kick", duration, "Windup")
	st.kickReadyAt = t + DK.Cooldown * 0.6
	Anim.play(char, "Generic.Kick", { duration = duration, hitTime = DK.Windup })
	Fx.soundAt("Kick_Swing", char)
	task.delay(DK.Windup, function()
		if not Combat.valid(char, token) or not victim.Parent or not victim:GetAttribute("KnockedDown")
			or victim:GetAttribute("CarriedBy") then return end
		Combat.setPhase(char, "Recovery")
		local d = (vbody.Position - root.Position) * Vector3.new(1, 0, 1)
		if d.Magnitude > CFG.Grab.Range + 2 then return end
		d = d.Magnitude > 0.01 and d.Unit or root.CFrame.LookVector
		CombatEvents.noteAttacker(victim, char) -- si cae al vacío, la eliminación es de quien pateó
		Combat.push(victim, d * DK.DownedPushSpeed + Vector3.new(0, DK.DownedPushUp, 0))
		Fx.soundAt("Kick_Hit", victim)
		Fx.dust(vbody.Position - Vector3.new(0, 1, 0), 0.6)
		Fx.shake(char, CFG.CameraShake.Light, d)
	end)
	task.delay(duration, function() Combat.endAction(char, token) end)
	return true
end

-- F apretada
function Actions.kickPress(char)
	if not Directional.enabled() then return Actions.kick(char) end
	local st = Combat.state(char)
	local victim = Combat.findGrabTarget(char)
	if victim and Combat.canAct(char) and not Combat.isBusy(char) then
		st.kickHoldToken = (st.kickHoldToken or 0) + 1
		local token = st.kickHoldToken
		st.kickHeld = victim
		task.delay(CFG.Directional.Kick.LiftHold, function()
			if st.kickHoldToken ~= token or not st.kickHeld then return end
			st.kickHeld = nil
			Combat.grab(char) -- mantener F: levantarlo
		end)
		return true
	end
	return Actions.kick(char)
end

-- F soltada antes de LiftHold: patear al derribado
function Actions.kickRelease(char)
	local st = Combat.state(char)
	local victim = st.kickHeld
	if not victim then return false end
	st.kickHeld = nil
	st.kickHoldToken = (st.kickHoldToken or 0) + 1
	return Actions.kickDowned(char, victim)
end

----------------------------------------------------------------------
-- Esquiva (Shift / Espacio) con i-frames
----------------------------------------------------------------------
-- face: hacia dónde mira el que esquiva (con objetivo fijado, hacia el objetivo)
local function dodgeAnimKey(root, dir, face)
	local look = (face or root.CFrame.LookVector) * Vector3.new(1, 0, 1)
	local right = look:Cross(Vector3.yAxis)
	local f = look.Magnitude > 0 and dir:Dot(look.Unit) or 0
	local r = right.Magnitude > 0 and dir:Dot(right.Unit) or 0
	if math.abs(f) >= math.abs(r) then
		return f >= 0 and "Generic.DodgeF" or "Generic.DodgeB"
	end
	return r >= 0 and "Generic.DodgeR" or "Generic.DodgeL"
end

-- dir: dirección horizontal en el mundo (si es nil, hacia atrás)
-- target: objetivo fijado (opcional): la animación se elige respecto de él y el cliente orbita
function Actions.dodge(char, dir, target)
	if not Combat.canAct(char) then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local st = Combat.state(char)
	local t = now()
	if t < st.dodgeReadyAt then return false end
	local mobility = Combat.weaponOf(char).mobility or {}
	local cost = CFG.Stamina.Dodge * (mobility.dodgeCost or 1)
	if (char:GetAttribute("Stamina") or 0) < cost and not (char:GetAttribute("IsDummy") and not CFG.Stamina.DummiesUseStamina) then
		char:SetAttribute("StaminaFailAt", t)
		return false
	end
	if st.busyUntil > t then
		-- Se puede esquivar desde la preparación de un fuerte (finta) o, tras el impacto,
		-- desde la recuperación de un golpe básico o de la patada (encadenar golpe y dash)
		local phase = char:GetAttribute("ActionPhase")
		if CFG.Dodge.CancelsRecovery and (st.action == "M1" or st.action == "Kick") and phase == "Recovery"
			and not (st.action == "Kick" and st.kickWhiffToken == st.token) then
			Combat.cancelAction(char)
			st.comboStep = 0
		elseif not (CFG.Dodge.CancelsHeavy and Combat.tryFeint(char)) then
			return false
		end
	end
	if char:GetAttribute("Blocking") then Combat.blockEnd(char, true, true) end
	Combat.spendStamina(char, cost)

	if typeof(dir) ~= "Vector3" then dir = -root.CFrame.LookVector end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.1 then dir = -root.CFrame.LookVector * Vector3.new(1, 0, 1) end
	dir = dir.Unit

	local D = CFG.Dodge
	local distance = D.Distance * (mobility.dodgeDistance or 1) * (char:GetAttribute("DodgeDistanceMult") or 1)
	local iframes = D.IFrames + (char:GetAttribute("DodgeIFrameBonus") or 0)
	local token = Combat.beginAction(char, "Dodge", D.Duration + D.Recovery, "Active")
	st.dodgeReadyAt = t + D.Cooldown
	st.comboStep = 0
	char:SetAttribute("IFrameUntil", t + iframes)
	Infusion.onDodge(char)

	local face = nil
	local tRoot = target and target:FindFirstChild("HumanoidRootPart")
	if tRoot then
		local toT = (tRoot.Position - root.Position) * Vector3.new(1, 0, 1)
		if toT.Magnitude > 0.1 then face = toT.Unit end
	end
	Anim.play(char, dodgeAnimKey(root, dir, face), { duration = D.Duration + D.Recovery })
	Fx.soundAt("Dodge", char)

	local speed = distance / D.Duration
	local player = Players:GetPlayerFromCharacter(char)
	if player then
		Effect:FireClient(player, "Dash", dir, speed, D.Duration)
	else
		-- Muñeco: el servidor mueve su física
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			if os.clock() - t0 > D.Duration or not root.Parent or char:GetAttribute("Ragdolled") then
				conn:Disconnect()
				return
			end
			root.AssemblyLinearVelocity = Vector3.new(dir.X * speed, root.AssemblyLinearVelocity.Y, dir.Z * speed)
		end)
	end

	task.delay(D.Duration, function()
		if Combat.valid(char, token) then Combat.setPhase(char, "Recovery") end
		-- Breve penalización de velocidad al terminar el dash
		if char.Parent then
			char:SetAttribute("DashSlowUntil", now() + D.AfterSlowTime)
			Combat.refreshSpeed(char)
			task.delay(D.AfterSlowTime + 0.05, function()
				if char.Parent then Combat.refreshSpeed(char) end
			end)
		end
	end)
	task.delay(D.Duration + D.Recovery, function()
		if not Combat.valid(char, token) then return end
		Combat.endAction(char, token)
		-- M1 pulsado durante la esquiva: sale apenas termina
		if st.queuedM1 then
			st.queuedM1 = false
			Actions.m1(char)
		end
	end)
	return true
end

----------------------------------------------------------------------
-- Palmada: levanta a un aliado derribado por Stun (0,5 s; un golpe la interrumpe)
----------------------------------------------------------------------
function Actions.revive(char, ally)
	if not Combat.canAct(char) or Combat.isBusy(char) then return false end
	if char:GetAttribute("Blocking") then Combat.blockEnd(char, true, true) end
	local duration = CFG.Revive.SlapTime
	local animSpeed, marker = timing("Generic.ReviveSlap", duration)
	local slapTime = marker("Slap") or duration

	local token = Combat.beginAction(char, "Revive", duration, "Active")
	Anim.play(char, "Generic.ReviveSlap", { speed = animSpeed, duration = duration, hitTime = slapTime })
	Fx.popAbove(ally, "pop.reviving", Theme.Colors.Bone)

	task.delay(slapTime, function()
		if not Combat.valid(char, token) then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		local aroot = ally:FindFirstChild("HumanoidRootPart")
		if root and aroot and (aroot.Position - root.Position).Magnitude <= CFG.Revive.Range + 2 then
			Combat.getUp(ally)
			Fx.soundAt("Revive_Slap", ally)
			Fx.popAbove(ally, "pop.up", Theme.Colors.Gold)
		end
	end)
	task.delay(duration, function()
		Combat.endAction(char, token)
	end)
	return true
end

----------------------------------------------------------------------
-- R contextual: lanzar (si cargas) > levantar aliado > agarrar (rival derribado cerca) > patada
-- (Fase B: rescate en derribo crítico, tirón corto con M1 y lanzamiento cargado con M2)
----------------------------------------------------------------------
function Actions.interact(char, aim)
	if char:GetAttribute("Carrying") then
		local root = char:FindFirstChild("HumanoidRootPart")
		local dir = aim or (root and root.CFrame.LookVector) or Vector3.zAxis
		return Combat.throw(char, dir)
	end
	local ally = Combat.findDownedAlly(char)
	if ally then
		return Actions.revive(char, ally)
	end
	if Combat.findGrabTarget(char) then
		return Combat.grab(char)
	end
	-- la patada tiene su propia tecla (InputMap: Kick)
	return false
end

----------------------------------------------------------------------
-- Q: infusión (ServerScriptService/Infusion)
----------------------------------------------------------------------
function Actions.infuse(char)
	return Infusion.activate(char)
end

return Actions
