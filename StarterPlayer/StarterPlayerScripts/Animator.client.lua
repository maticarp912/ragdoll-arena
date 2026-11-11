-- LocalScript: StarterPlayer/StarterPlayerScripts/Animator
-- Anima a TODOS los luchadores (jugadores y muñecos) con las animaciones procedurales de AnimClips.
--   · Postura base según el estado: reposo con el arma, guardia, cargar a alguien, cargar el lanzamiento.
--   · Clips de acción que publica el servidor (AnimKey/AnimStart/AnimDur/AnimWindup/AnimHit), sincronizados
--     para que el golpe visual caiga justo cuando el servidor aplica el daño.
--   · IK de la mano izquierda en armas a dos manos (se agarra al mango de verdad).
--   · Estela del arma durante los golpes, hitstop, respiración, inclinación al moverse y piernas de los muñecos.
-- Se aplica en Stepped (después del Animator de Roblox, antes de la física): sobrescribe brazos y torso;
-- La locomoción procedural por distancia se aplica a jugadores y muñecos.

-- Parámetros de caminata: AnimClips.Locomotion
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local AnimClips = require(ReplicatedStorage:WaitForChild("AnimClips"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))
local Assets = require(ReplicatedStorage:WaitForChild("Assets"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Effect = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Effect")

local Playback = AnimClips.Playback
local J = AnimClips.Joints
local UPPER = AnimClips.Upper
local LOWER = AnimClips.Lower
local rad = math.rad
local ZERO = { 0, 0, 0, 0, 0, 0 }

local states = setmetatable({}, { __mode = "k" })
local frozenTracks = {}
local DIRCLIPS = AnimClips.Directional
local DIRCFG = CombatConfig.Directional

-- 0.2: ¿se dibujan las capas del combate direccional?
local function directionalOn()
	return DIRCFG ~= nil and DIRCFG.Enabled == true and DIRCLIPS ~= nil
end

local function smooth01(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

----------------------------------------------------------------------
-- Utilidades de poses (vectores de 6: rotX, rotY, rotZ, posX, posY, posZ)
----------------------------------------------------------------------
local function v6(v)
	if not v then return ZERO end
	return { v[1] or 0, v[2] or 0, v[3] or 0, v[4] or 0, v[5] or 0, v[6] or 0 }
end

local function lerpV(a, b, t)
	a = a or ZERO
	b = b or ZERO
	return {
		(a[1] or 0) + ((b[1] or 0) - (a[1] or 0)) * t,
		(a[2] or 0) + ((b[2] or 0) - (a[2] or 0)) * t,
		(a[3] or 0) + ((b[3] or 0) - (a[3] or 0)) * t,
		(a[4] or 0) + ((b[4] or 0) - (a[4] or 0)) * t,
		(a[5] or 0) + ((b[5] or 0) - (a[5] or 0)) * t,
		(a[6] or 0) + ((b[6] or 0) - (a[6] or 0)) * t,
	}
end

local function addV(a, b, w)
	a = a or ZERO
	b = b or ZERO
	w = w or 1
	return {
		(a[1] or 0) + (b[1] or 0) * w, (a[2] or 0) + (b[2] or 0) * w, (a[3] or 0) + (b[3] or 0) * w,
		(a[4] or 0) + (b[4] or 0) * w, (a[5] or 0) + (b[5] or 0) * w, (a[6] or 0) + (b[6] or 0) * w,
	}
end

local function toCF(v)
	return CFrame.new(v[4] or 0, v[5] or 0, v[6] or 0) * CFrame.Angles(rad(v[1] or 0), rad(v[2] or 0), rad(v[3] or 0))
end

local EASE = {
	linear = function(t) return t end,
	["in"] = function(t) return t * t * t end,
	out = function(t) return 1 - (1 - t) ^ 3 end,
	inout = function(t) return t * t * (3 - 2 * t) end,
}

----------------------------------------------------------------------
-- Estado por personaje
----------------------------------------------------------------------
local function archetypeOf(char)
	local def = WeaponData.Data[char:GetAttribute("WeaponId") or ""]
	return (def and def.archetype) or "OneHand"
end

local function getState(char)
	local st = states[char]
	if not st then
		st = { motors = {}, base = {}, frameBase = {}, transforms = {}, clip = nil, clipSeq = -1, weight = 0, elapsed = 0, phase = 0,
			frozenUntil = 0, relax = 0, hiddenWeapon = false }
		states[char] = st
	end
	-- Articulaciones (se vuelven a buscar si el personaje cambió).
	-- Valen Motor6D (rig clásico) y AnimationConstraint (Avatar Joint Upgrade de Roblox):
	-- en ambos el hijo queda en Part0 * C0 * Transform * C1:Inverse().
	if not st.motors.W or not st.motors.W.inst.Parent then
		st.motors = {}
		for short, name in J do
			local joint = char:FindFirstChild(name, true)
			if joint and joint:IsA("Motor6D") then
				st.motors[short] = { inst = joint, C0 = joint.C0, C1 = joint.C1 }
			elseif joint and joint:IsA("AnimationConstraint") and joint.Attachment0 and joint.Attachment1 then
				st.motors[short] = { inst = joint, C0 = joint.Attachment0.CFrame, C1 = joint.Attachment1.CFrame }
			end
		end
	end
	return st
end

local function hasAnimateScript(char)
	return char:FindFirstChild("Animate") ~= nil
end

-- Pose de una key (tabla, "base" o nombre de una postura común)
local function keyPose(key, base)
	local p = key[2]
	if p == "base" then return base end
	if type(p) == "string" then return AnimClips.Common[p] or base end
	return p
end

local function usesJoint(clip, joint)
	if clip._uses == nil then
		clip._uses = {}
		for _, k in clip.keys do
			if type(k[2]) == "table" then
				for j in k[2] do clip._uses[j] = true end
			end
		end
	end
	return clip._uses[joint] == true
end

-- Tiempo real -> tiempo normalizado del clip, anclando WindupEnd y Hit a lo que dice el servidor
local function warp(st)
	local clip = st.clip
	local e, d = st.elapsed, st.dur
	if d <= 0 then return 1 end
	local pts = { { 0, 0 } }
	if clip.windup and st.windup > 0 and st.windup < d then table.insert(pts, { st.windup, clip.windup }) end
	if clip.hit and st.hit > 0 and st.hit < d and st.hit > (pts[#pts][1]) then table.insert(pts, { st.hit, clip.hit }) end
	table.insert(pts, { d, 1 })
	if e >= d then return 1 end
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		if e <= b[1] then
			local f = (e - a[1]) / math.max(b[1] - a[1], 1e-3)
			return a[2] + (b[2] - a[2]) * f
		end
	end
	return 1
end

local function evalClip(clip, u, base, joint)
	local keys = clip.keys
	local k0, k1 = keys[1], keys[#keys]
	for i = 1, #keys - 1 do
		if u >= keys[i][1] and u <= keys[i + 1][1] then
			k0, k1 = keys[i], keys[i + 1]
			break
		end
	end
	local span = math.max(k1[1] - k0[1], 1e-3)
	local f = math.clamp((u - k0[1]) / span, 0, 1)
	f = (EASE[k1[3] or "inout"] or EASE.inout)(f)
	local fallback = clip.additive and ZERO or base[joint]
	local a = keyPose(k0, base)[joint] or fallback
	local b = keyPose(k1, base)[joint] or fallback
	return lerpV(a, b, f)
end

----------------------------------------------------------------------
-- IK de la mano izquierda (armas a dos manos)
----------------------------------------------------------------------
local function chain(parentCF, motor, t)
	return parentCF * motor.C0 * t * motor.C1:Inverse()
end

local function solveLeftArm(char, st, tf)
	local m = st.motors
	local root = char:FindFirstChild("HumanoidRootPart")
	local rhand = char:FindFirstChild("RightHand")
	local grip = rhand and rhand:FindFirstChild("RightGrip")
	local tool = char:FindFirstChildOfClass("Tool")
	if not (root and grip and tool and m.R and m.W and m.RS and m.RE and m.RW and m.LS and m.LE and m.LW) then return end
	local weaponId = tool:GetAttribute("WeaponId") or ""
	local info = WeaponBuilder.Info[weaponId]
	local offhandZ = info and (info.twoHanded and info.offhandZ or AnimClips.OffhandFallback[weaponId])
	if not offhandZ then return end

	-- Cinemática directa hasta el mango
	local lower = chain(root.CFrame, m.R, tf.R)
	local upper = chain(lower, m.W, tf.W)
	local rua = chain(upper, m.RS, tf.RS)
	local rla = chain(rua, m.RE, tf.RE)
	local rh = chain(rla, m.RW, tf.RW)
	local handle
	if grip:IsA("AnimationConstraint") then
		if not grip.Attachment0 or not grip.Attachment1 then return end
		handle = rh * grip.Attachment0.CFrame * grip.Transform * grip.Attachment1.CFrame:Inverse()
	elseif grip:IsA("JointInstance") then
		handle = rh * grip.C0 * grip.C1:Inverse()
	else
		return
	end
	local target = (handle * CFrame.new(0, 0, offhandZ)).Position

	-- Dos huesos
	local shoulderCF = upper * m.LS.C0
	local S = shoulderCF.Position
	local L1 = (m.LE.C0.Position - m.LS.C1.Position).Magnitude
	local L2 = (m.LW.C0.Position - m.LE.C1.Position).Magnitude + 0.3
	local toT = target - S
	if toT.Magnitude < 1e-3 or L1 <= 0 or L2 <= 0 then return end
	local d = math.clamp(toT.Magnitude, 0.05, L1 + L2 - 0.02)
	local dir = toT.Unit
	local a = (L1 * L1 - L2 * L2 + d * d) / (2 * d)
	local h = math.sqrt(math.max(L1 * L1 - a * a, 0))
	local pole = (upper * CFrame.new(-1.6, -1.4, 0.8)).Position - S
	local poleDir = pole - dir * pole:Dot(dir)
	if poleDir.Magnitude < 1e-3 then poleDir = -upper.UpVector end
	poleDir = poleDir.Unit
	local E = S + dir * a + poleDir * h
	local T = S + dir * d

	local yU = (S - E).Unit
	local fore = (T - E).Unit
	local zU = -(fore - yU * fore:Dot(yU))
	if zU.Magnitude < 1e-3 then zU = upper.ZVector end
	zU = zU.Unit
	local xU = yU:Cross(zU)
	local ua = CFrame.fromMatrix(S, xU, yU) * CFrame.new(-m.LS.C1.Position)
	tf.LS = shoulderCF:Inverse() * ua * m.LS.C1

	local elbowCF = ua * m.LE.C0
	local yL = (elbowCF.Position - T).Unit
	local zL = xU:Cross(yL)
	if zL.Magnitude < 1e-3 then zL = zU end
	local la = CFrame.fromMatrix(elbowCF.Position, xU, yL, zL.Unit) * CFrame.new(-m.LE.C1.Position)
	tf.LE = elbowCF:Inverse() * la * m.LE.C1
	tf.LW = CFrame.Angles(0, 0, rad(-10))
end

----------------------------------------------------------------------
-- Detalles visuales del arma
----------------------------------------------------------------------
local function weaponParts(char)
	local list = {}
	for _, c in char:GetChildren() do
		if c:IsA("Tool") or c.Name == "OffhandWeapon" then
			for _, p in c:GetDescendants() do
				if p:IsA("BasePart") then table.insert(list, p) end
			end
		end
	end
	return list
end

local function setTrails(char, on)
	for _, c in char:GetChildren() do
		if c:IsA("Tool") or c.Name == "OffhandWeapon" then
			for _, t in c:GetDescendants() do
				if t:IsA("Trail") and t.Name == "SwingTrail" and t.Enabled ~= on then
					t.Enabled = on
				end
			end
		end
	end
end

----------------------------------------------------------------------
-- Bucle principal
----------------------------------------------------------------------
local function update(char, dt, now)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 or char:GetAttribute("Ragdolled") then
		local st = states[char]
		if st and st.clip then
			st.clip = nil
			st.trailOn = false
			setTrails(char, false)
		end
		return
	end
	local st = getState(char)
	local m = st.motors
	if not m.W then return end
	local arch = archetypeOf(char)

	-- Hitstop: el tiempo de los clips casi se detiene. Cámara lenta breve (0.2): parry y guardia rota
	local clockNow = os.clock()
	local timeScale = (clockNow < st.frozenUntil) and CombatConfig.Hitstop.Speed or 1
	if clockNow < (st.slowUntil or 0) then timeScale = math.min(timeScale, st.slowScale or 1) end

	-- ¿Nuevo clip del servidor?
	local seq = char:GetAttribute("AnimSeq") or 0
	if seq ~= st.clipSeq then
		st.transitionFrom = table.clone(st.transforms)
		st.transitionTime = 0
		st.clipSeq = seq
		local key = char:GetAttribute("AnimKey") or ""
		local clip = nil
		if key ~= "" and not Assets.anim(key) then
			clip = AnimClips.resolve(key, arch)
		end
		if clip then
			st.clip = clip
			-- la captura de movimiento ya trae su recorrido real: no se exagera
			local isAttack = string.match(key, "^Weapons%.%w+%.M1_%d$") or string.match(key, "^Weapons%.%w+%.Heavy$")
				or string.match(key, "^Weapons%.%w+%.Dir%a+$") -- 10/11: golpe básico por dirección
			st.exag = not clip.mocap and isAttack and AnimClips.Playback.Exaggerate or nil
			-- 0.2 (C23): recibir un golpe se exagera más
			if not clip.mocap and string.match(key, "^Generic%.HitReact") then
				st.exag = AnimClips.Playback.HitReactExaggerate
			end
			st.isAttack = isAttack ~= nil
			st.elapsed = math.clamp(now - (char:GetAttribute("AnimStart") or now), 0, 0.25)
			local dur = char:GetAttribute("AnimDur") or 0
			st.dur = dur > 0 and dur or clip.dur
			st.windup = char:GetAttribute("AnimWindup") or 0
			st.hit = char:GetAttribute("AnimHit") or 0
			st.fading = false
			st.relax = 0
			if st.weight < 0.01 then st.weight = 0 end
		elseif st.clip then
			st.fading = true -- acción cortada: volver a la postura
		end
	end

	-- Postura base
	local stance = AnimClips.Stances[arch] or AnimClips.Stances.OneHand
	local target
	if char:GetAttribute("ThrowCharging") then
		target = AnimClips.Common.ThrowCharge
	elseif char:GetAttribute("Carrying") then
		target = AnimClips.Common.Carry
	elseif char:GetAttribute("Blocking") then
		target = stance.Guard
	else
		target = stance.Ready
	end
	-- Reposo en el hombro (armas pesadas): tras un rato sin acción ni bloqueo
	local restKey = AnimClips.Rest.Stances[arch]
	if st.clip or (char:GetAttribute("Action") or "") ~= "" or char:GetAttribute("Blocking") or char:GetAttribute("Carrying")
		or char:GetAttribute("ThrowCharging") or char:GetAttribute("KnockedDown") or char:GetAttribute("Ragdolled") then
		st.lastActive = now
	end
	st.resting = restKey ~= nil and now - (st.lastActive or 0) > AnimClips.Rest.Delay
	if st.resting and AnimClips.Stances[restKey] then target = AnimClips.Stances[restKey] end
	local k = 1 - math.exp(-Playback.StanceResponse * dt)
	for _, j in UPPER do
		st.base[j] = lerpV(st.base[j] or target[j], target[j], k)
	end

	-- Respiración, caminata y cabeza estable
	local vel = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	local speed = vel.Magnitude
	st.seed = st.seed or math.random() * 6
	local breathe = math.sin(now * 1.9 + st.seed)
	local base = st.frameBase
	table.clear(base)
	for _, j in UPPER do base[j] = st.base[j] end

	-- 0.2: postura direccional. La guardia se inclina hacia el lado elegido (en reposo, un poco):
	-- así el rival también lee tu lado en tu cuerpo, no solo en su triángulo.
	if directionalOn() then
		local guardPose = DIRCLIPS.Guard[char:GetAttribute("Stance") or ""]
		local w = char:GetAttribute("Blocking") and 1 or DIRCLIPS.ReadyWeight
		local kk = 1 - math.exp(-DIRCLIPS.StanceResponse * dt)
		st.stanceOff = st.stanceOff or {}
		for _, j in UPPER do
			local goal = guardPose and guardPose[j] and { guardPose[j][1] * w, guardPose[j][2] * w, guardPose[j][3] * w } or ZERO
			st.stanceOff[j] = lerpV(st.stanceOff[j] or ZERO, goal, kk)
			base[j] = addV(base[j], st.stanceOff[j])
		end
	end

	local Lo = AnimClips.Locomotion
	local feel = WeaponData.feel and WeaponData.feel(char:GetAttribute("WeaponId")) or nil
	local wt = Lo.Weight[(feel and feel.weight) or 2] or Lo.Weight[2]
	local idle = AnimClips.Common.LegsIdle
	local blend = 1 - math.exp(-Lo.Response * dt)
	st.move = (st.move or 0) + (math.clamp(speed / Lo.Speed, 0, 1) - (st.move or 0)) * blend
	local move = st.move
	local previous = st.walkPosition or root.Position
	local distance = ((root.Position - previous) * Vector3.new(1, 0, 1)).Magnitude
	st.walkPosition = root.Position
	st.phase += math.min(distance, 4) * Lo.PhaseRate / wt.stride
	local s, c = math.sin(st.phase), math.cos(st.phase)
	local localVel = root.CFrame:VectorToObjectSpace(vel)
	local fwdT = speed > 0.5 and math.clamp(-localVel.Z / speed, -1, 1) or 0
	local sideT = speed > 0.5 and math.clamp(localVel.X / speed, -1, 1) or 0
	st.fwd = (st.fwd or 0) + (fwdT - (st.fwd or 0)) * blend
	st.side = (st.side or 0) + (sideT - (st.side or 0)) * blend
	local fwd, side = st.fwd, st.side
	local hip = Lo.Hip * wt.stride
	local swingR, swingL = math.max(0, c), math.max(0, -c) -- la pierna que avanza dobla la rodilla
	local walkLegs = {
		R = { 0, s * Lo.Twist * fwd, 0, 0, -0.08 - Lo.Bob * wt.bob * s * s, 0 },
		RH = { s * hip * fwd, 0, s * Lo.Side * side },
		LH = { -s * hip * fwd, 0, -s * Lo.Side * side },
		RK = { -(swingR * Lo.Knee + 8), 0, 0 },
		LK = { -(swingL * Lo.Knee + 8), 0, 0 },
		RA = { -s * Lo.Ankle * fwd + swingR * 8, 0, 0 },
		LA = { s * Lo.Ankle * fwd + swingL * 8, 0, 0 },
	}
	for j, v in walkLegs do
		base[j] = lerpV(v6(idle[j]), v, move)
	end

	-- Torso: se inclina hacia donde va y compensa el giro de la pelvis. Cabeza: compensa ambos (no se bambolea)
	local leanPitch = -Lo.Lean * move * fwd
	local twistComp = -s * Lo.Twist * fwd * move * 0.9
	base.W = addV(base.W, { leanPitch + breathe * 1.2 * (1 - move), twistComp, 0 })
	local residualYaw = s * Lo.Twist * fwd * move * 0.1
	base.N = addV(base.N, { -leanPitch * Lo.HeadStabilize, -residualYaw * Lo.HeadStabilize, 0 })

	-- Brazos: el libre se balancea; el armado apenas
	local busy = char:GetAttribute("Carrying") or char:GetAttribute("ThrowCharging") or char:GetAttribute("Blocking")
	if not busy then
		if arch == "OneHand" or arch == "Rapier" then
			base.LS = addV(base.LS, { s * Lo.Arm * move * fwd, 0, 0 })
			base.RS = addV(base.RS, { -s * Lo.WeaponArm * move * fwd, 0, 0 })
		elseif arch == "Dual" then
			base.RS = addV(base.RS, { -s * Lo.WeaponArm * 1.6 * move * fwd, 0, 0 })
			base.LS = addV(base.LS, { s * Lo.WeaponArm * 1.6 * move * fwd, 0, 0 })
		end
	end

	-- En el aire (cayendo de la arena): piernas recogidas y brazos agitándose
	if hum.FloorMaterial == Enum.Material.Air and not char:GetAttribute("Carrying") then
		local wave = math.sin(now * Lo.AirFrequency) * Lo.AirWave
		base.RH = { Lo.Hip, 0, 0 } base.LH = { -Lo.Hip * 0.5, 0, 0 }
		base.RK = { -Lo.Knee, 0, 0 } base.LK = { -Lo.Knee * 1.2, 0, 0 }
		if not char:GetAttribute("ThrowCharging") then
			base.RS = { Lo.AirArms + wave, 0, Lo.Side }
			base.LS = { Lo.AirArms - wave, 0, -Lo.Side }
		end
	end
	local isDummy = true -- la locomoción procedural vale para todos los Combatant

	-- Peso del clip
	local clip = st.clip
	local u = 1
	if clip then
		st.elapsed += dt * timeScale
		u = warp(st)
		if st.fading then
			st.weight = math.max(0, st.weight - dt / 0.14)
			if st.weight <= 0 then st.clip = nil clip = nil end
		else
			st.weight = math.min(1, st.weight + dt / 0.05)
			if u >= 1 then
				st.clip = nil
				clip = nil
				st.weight = 0
				st.relax = Playback.Recovery
				st.recoveryFrom = table.clone(st.transforms)
			end
		end
	end

	-- Estela del arma durante la ventana de golpe
	local trailOn = clip ~= nil and clip.trail ~= nil and not st.fading and u >= clip.trail[1] and u <= clip.trail[2]
	if trailOn ~= st.trailOn then
		st.trailOn = trailOn
		setTrails(char, trailOn)
	end

	-- Arma oculta mientras cargas a alguien
	local action = char:GetAttribute("Action")
	local hide = char:GetAttribute("Carrying") == true or action == "PickUp" or action == "Throw"
	if hide ~= st.hiddenWeapon then
		st.hiddenWeapon = hide
		for _, p in weaponParts(char) do p.LocalTransparencyModifier = hide and 1 or 0 end
	end

	-- 0.2: golpe por dirección. Capa que carga hacia el lado del golpe y cruza al otro tras el impacto
	local dirLayer, dirW1, dirW2 = nil, 0, 0
	local attackDir = char:GetAttribute("AttackDir") or ""
	if clip and st.isAttack and attackDir ~= "" and directionalOn() and not st.fading then
		dirLayer = DIRCLIPS.Attack[attackDir]
		-- u ya está deformado para que el impacto caiga en clip.hit (ver warp)
		local dur = st.dur or clip.dur or 1
		local hitU = math.clamp(clip.hit or (dur > 0 and (st.hit or 0) / dur) or 0.5, 0.05, 0.95)
		if dirLayer then
			local mult = (char:GetAttribute("Finisher") and DIRCLIPS.FinisherMult or 1) * (clip.dirLayer or 1)
			if u < hitU then
				local pre = u / hitU
				local pk = DIRCLIPS.WindupPeak
				dirW1 = (pre < pk and smooth01(pre / pk) or 1 - smooth01((pre - pk) / (1 - pk))) * mult
			else
				local post = (u - hitU) / (1 - hitU)
				local pk = DIRCLIPS.FollowPeak
				dirW2 = (post < pk and smooth01(post / pk) or 1 - smooth01((post - pk) / (1 - pk))) * mult
			end
		end
	end

	-- Calcular transforms
	local tf = st.transforms
	table.clear(tf)
	local w = st.weight
	for _, j in UPPER do
		local v = base[j]
		if clip then
			local c = evalClip(clip, u, base, j)
			if st.exag and not clip.additive then
				c = lerpV(v, c, st.exag)
				if j == "RS" or j == "LS" then c[1] = math.clamp(c[1], -70, 195) end
			end
			if clip.additive then v = addV(v, c, w) else v = lerpV(v, c, w) end
		end
		if dirLayer then
			if dirW1 > 0 and dirLayer.windup[j] then v = addV(v, dirLayer.windup[j], dirW1 * w) end
			if dirW2 > 0 and dirLayer.follow[j] then v = addV(v, dirLayer.follow[j], dirW2 * w) end
		end
		tf[j] = toCF(v)
	end
	local fullClip = clip and clip.full and not clip.additive
	for _, j in LOWER do
		if fullClip then
			local c = evalClip(clip, u, base, j)
			if st.exag then c = lerpV(base[j] or ZERO, c, st.exag) end
			local from = isDummy and base[j] or (j == "R" and ZERO or nil)
			if from then
				tf[j] = toCF(lerpV(from, c, w))
			else
				tf[j] = m[j] and m[j].inst.Transform:Lerp(toCF(c), w) or toCF(c)
			end
		elseif isDummy then
			tf[j] = toCF(base[j] or ZERO)
		elseif j == "R" then
			tf[j] = CFrame.identity
		end
	end

	-- Afinado en vivo (solo depuración, tu personaje). Desde la barra de comandos del cliente:
	--   workspace:SetAttribute("PoseFreeze", "Weapons.Sword.M1_1@0.5")  -> congela un clip en ese instante
	--   workspace:SetAttribute("PoseTune", '{"RW":[-60,0,0]}')          -> suma grados a articulaciones
	if char == Players.LocalPlayer.Character then
		local freeze = workspace:GetAttribute("PoseFreeze")
		if type(freeze) == "string" and freeze ~= "" then
			local key, at = string.match(freeze, "^(.-)@([%d%.]+)$")
			local fclip = key and AnimClips.resolve(key, arch)
			if fclip then
				local fu = tonumber(at) or 0.5
				for _, j in UPPER do
					local c = evalClip(fclip, fu, base, j)
					tf[j] = toCF(fclip.additive and addV(base[j], c) or c)
				end
				if fclip.full then
					for _, j in LOWER do tf[j] = toCF(evalClip(fclip, fu, { R = ZERO }, j)) end
				end
			end
		end
		local tune = workspace:GetAttribute("PoseTune")
		if type(tune) == "string" and tune ~= "" then
			if st.tuneSrc ~= tune then
				st.tuneSrc = tune
				local ok, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(tune) end)
				st.tune = ok and decoded or nil
			end
			if st.tune then
				for j, v in st.tune do
					if m[j] then tf[j] = (tf[j] or m[j].inst.Transform) * toCF(v6(v)) end
				end
			end
		end
	end

	-- IK de la mano izquierda con armas a dos manos
	if AnimClips.TwoHandIK[arch] and not st.resting and not char:GetAttribute("Carrying") and not char:GetAttribute("ThrowCharging")
		and not (clip and not clip.additive and usesJoint(clip, "LS") and arch ~= "OneHand") then
		local ok = pcall(solveLeftArm, char, st, tf)
		if not ok then st.ikFailed = true end
	end

	-- Mezcla desde la pose visible: evita saltos al encadenar o interrumpir acciones.
	if st.transitionFrom and st.transitionTime < Playback.Transition then
		st.transitionTime += dt
		local a = math.clamp(st.transitionTime / Playback.Transition, 0, 1)
		a = a * a * (3 - 2 * a)
		for j, cf in tf do
			local previous = st.transitionFrom[j]
			if previous then tf[j] = previous:Lerp(cf, a) end
		end
	end
	-- Recuperar hacia caminar/reposo, sin llevar las piernas a identidad de golpe.
	if st.relax > 0 and st.recoveryFrom and not clip then
		st.relax = math.max(0, st.relax - dt)
		local a = 1 - st.relax / Playback.Recovery
		a = a * a * (3 - 2 * a)
		for j, previous in st.recoveryFrom do
			if m[j] then tf[j] = previous:Lerp(tf[j] or m[j].inst.Transform, a) end
		end
	end
	for j, cf in tf do
		local joint = m[j]
		if joint then joint.inst.Transform = cf end
	end
end

local warned = setmetatable({}, { __mode = "k" })
-- Se aplica en Stepped: después del Animator de Roblox y antes de la física (que resuelve las articulaciones)
RunService.Stepped:Connect(function(_, dt)
	local clock = os.clock()
	for track, entry in frozenTracks do
		if not track.IsPlaying or clock >= entry.untilTime then
			if track.IsPlaying then track:AdjustSpeed(entry.speed) end
			frozenTracks[track] = nil
		end
	end
	local now = workspace:GetServerTimeNow()
	for _, char in CollectionService:GetTagged("Combatant") do
		local ok, err = pcall(update, char, dt, now)
		if not ok and not warned[char] then
			warned[char] = true -- un aviso por personaje, para no inundar la salida
			warn("[Animator]", char.Name, err)
		end
	end
end)

-- Hitstop que manda el servidor
Effect.OnClientEvent:Connect(function(kind, a, b, speed)
	if kind ~= "Hitstop" or type(a) ~= "table" then return end
	-- 0.2: tope del hit-stop (guía lihfolk-vfx: más de 0,2 s se siente como lag)
	local maxStop = (CombatConfig.Feel and CombatConfig.Feel.HitstopMax) or 0.2
	local stopFor = math.min(type(b) == "number" and b or CombatConfig.Hitstop.Heavy, maxStop)
	for _, char in a do
		if typeof(char) == "Instance" then
			local st = states[char]
			local untilTime = os.clock() + stopFor
			if st then st.frozenUntil = math.max(st.frozenUntil, untilTime) end
			local hum = char:FindFirstChildOfClass("Humanoid")
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in animator:GetPlayingAnimationTracks() do
					local entry = frozenTracks[track]
					if entry then
						entry.untilTime = math.max(entry.untilTime, untilTime)
					else
						frozenTracks[track] = { speed = track.Speed, untilTime = untilTime }
						track:AdjustSpeed(speed or CombatConfig.Hitstop.Speed)
					end
				end
			end
		end
	end
end)

-- 0.2 (C23): cámara lenta breve en el parry y la guardia rota, solo en tu pantalla y alrededor tuyo
local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))
Effect.OnClientEvent:Connect(function(kind, role)
	if kind ~= "Feel" or not Polish.Feel then return end
	local cfg = Polish.Feel[role]
	if type(cfg) ~= "table" or not cfg.SlowScale then return end
	local me = Players.LocalPlayer.Character
	local myRoot = me and me:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local untilTime = os.clock() + cfg.SlowTime
	for _, char in CollectionService:GetTagged("Combatant") do
		local r = char:FindFirstChild("HumanoidRootPart")
		local st = states[char]
		if st and r and (r.Position - myRoot.Position).Magnitude <= cfg.SlowRadius then
			st.slowUntil = math.max(st.slowUntil or 0, untilTime)
			st.slowScale = cfg.SlowScale
		end
	end
end)

-- Limpiar al desaparecer
CollectionService:GetInstanceRemovedSignal("Combatant"):Connect(function(char)
	states[char] = nil
end)
