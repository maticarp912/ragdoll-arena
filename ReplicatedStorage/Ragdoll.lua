-- ModuleScript: ReplicatedStorage/Ragdoll
-- Ragdoll R15 con "esqueleto": cada articulación tiene su propio tipo y límites
-- (codos y rodillas = bisagras; hombros, caderas, cuello y cintura = rótulas con cono y giro limitados).
-- Extremidades pesadas, con fricción y sin rebote: caídas blandas y con peso, estilo Gang Beasts.
-- Usar SOLO desde el servidor. El Motor6D "Root" se mantiene: el HumanoidRootPart acompaña al torso.

local Players = game:GetService("Players")

local Ragdoll = {}

local PREFIX = "Ragdoll" -- todo lo que creamos empieza por esto, para limpiarlo luego

-- dir = hacia dónde va el hueso hijo desde la articulación (en el espacio de la articulación)
-- cone = cuánto puede salirse de la pose de reposo (grados) · twist = giro sobre el propio hueso
-- Las bisagras giran sobre el eje X de la articulación (doblar hacia delante = ángulo positivo).
local JOINTS = {
	Neck = { kind = "Ball", dir = Vector3.yAxis, cone = 40, twist = 45, friction = 2 },
	Waist = { kind = "Ball", dir = Vector3.yAxis, cone = 30, twist = 35, friction = 6 },
	RightShoulder = { kind = "Ball", dir = -Vector3.yAxis, cone = 110, twist = 70, friction = 1.5 },
	LeftShoulder = { kind = "Ball", dir = -Vector3.yAxis, cone = 110, twist = 70, friction = 1.5 },
	RightElbow = { kind = "Hinge", lower = -2, upper = 140 },
	LeftElbow = { kind = "Hinge", lower = -2, upper = 140 },
	RightWrist = { kind = "Ball", dir = -Vector3.yAxis, cone = 45, twist = 30, friction = 0.3 },
	LeftWrist = { kind = "Ball", dir = -Vector3.yAxis, cone = 45, twist = 30, friction = 0.3 },
	RightHip = { kind = "Ball", dir = -Vector3.yAxis, cone = 80, twist = 35, friction = 3 },
	LeftHip = { kind = "Ball", dir = -Vector3.yAxis, cone = 80, twist = 35, friction = 3 },
	RightKnee = { kind = "Hinge", lower = -140, upper = 2 },
	LeftKnee = { kind = "Hinge", lower = -140, upper = 2 },
	RightAnkle = { kind = "Ball", dir = -Vector3.yAxis, cone = 30, twist = 15, friction = 0.5 },
	LeftAnkle = { kind = "Ball", dir = -Vector3.yAxis, cone = 30, twist = 15, friction = 0.5 },
}

-- Peso y tacto de las piezas mientras son ragdoll (densidad, fricción, elasticidad)
local LIMB_PHYSICS = PhysicalProperties.new(0.9, 0.85, 0, 1, 1)
local TORSO_PHYSICS = PhysicalProperties.new(1.1, 0.7, 0, 1, 1)

local saved = setmetatable({}, { __mode = "k" }) -- [part] = { CanCollide, CustomPhysicalProperties }

-- Rotación que lleva el eje X (eje principal del Attachment) a "dir"
local function axisFrame(dir)
	if dir.Y > 0.5 then
		return CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.xAxis)
	end
	return CFrame.fromMatrix(Vector3.zero, -Vector3.yAxis, -Vector3.xAxis)
end

-- Dueño de la física de TODAS las piezas (en ragdoll cada extremidad es un ensamblaje distinto)
function Ragdoll.setOwner(character, owner)
	for _, p in character:GetDescendants() do
		if p:IsA("BasePart") and not p.Anchored then
			pcall(function()
				if p:CanSetNetworkOwnership() then p:SetNetworkOwner(owner) end
			end)
		end
	end
end

local function bodyParts(character)
	local list = {}
	for _, p in character:GetChildren() do
		if p:IsA("BasePart") then table.insert(list, p) end
	end
	return list
end

-- Articulación del rig: Motor6D (rig clásico) o AnimationConstraint (Avatar Joint Upgrade de Roblox)
local function isRigJoint(inst)
	return (inst:IsA("Motor6D") or inst:IsA("AnimationConstraint")) and JOINTS[inst.Name] ~= nil
end

-- Partes y marcos de la articulación (equivalentes a Part0/Part1/C0/C1)
local function jointInfo(joint)
	if joint:IsA("Motor6D") then
		return joint.Part0, joint.Part1, joint.C0, joint.C1
	end
	local a0, a1 = joint.Attachment0, joint.Attachment1
	if not a0 or not a1 then return nil end
	return a0.Parent, a1.Parent, a0.CFrame, a1.CFrame
end

local function buildJoint(motor)
	local spec = JOINTS[motor.Name]
	local part0, part1, c0, c1 = jointInfo(motor)
	if not spec or not part0 or not part1 then return end

	local frame = spec.kind == "Hinge" and CFrame.identity or axisFrame(spec.dir)
	local a0 = Instance.new("Attachment")
	a0.Name = PREFIX .. "A0"
	a0.CFrame = c0 * frame
	a0.Parent = part0
	local a1 = Instance.new("Attachment")
	a1.Name = PREFIX .. "A1"
	a1.CFrame = c1 * frame
	a1.Parent = part1

	local c
	if spec.kind == "Hinge" then
		c = Instance.new("HingeConstraint")
		c.LimitsEnabled = true
		c.LowerAngle = spec.lower
		c.UpperAngle = spec.upper
		c.Restitution = 0
	else
		c = Instance.new("BallSocketConstraint")
		c.LimitsEnabled = true
		c.UpperAngle = spec.cone
		c.TwistLimitsEnabled = true
		c.TwistLowerAngle = -spec.twist
		c.TwistUpperAngle = spec.twist
		c.Restitution = 0
		c.MaxFrictionTorque = spec.friction or 1
	end
	c.Name = PREFIX .. motor.Name
	c.Attachment0 = a0
	c.Attachment1 = a1
	c.Parent = part0

	-- Las dos piezas de una articulación no chocan entre sí
	local nc = Instance.new("NoCollisionConstraint")
	nc.Name = PREFIX .. "NoCollide"
	nc.Part0 = part0
	nc.Part1 = part1
	nc.Parent = part0
end

-- Activa el ragdoll. duration = segundos hasta levantarse (nil = hasta que lo desactives).
-- force = true permite ragdoll aunque el personaje ya esté muerto (para el KO final).
function Ragdoll.enable(character, duration, force)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if hum.Health <= 0 and not force then return end

	-- El token evita que un temporizador viejo levante al jugador tras un golpe nuevo
	local token = (character:GetAttribute("RagdollToken") or 0) + 1
	character:SetAttribute("RagdollToken", token)

	if not character:GetAttribute("Ragdolled") then
		character:SetAttribute("Ragdolled", true)
		hum.PlatformStand = true
		hum.AutoRotate = false
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)

		for _, motor in character:GetDescendants() do
			if isRigJoint(motor) then
				buildJoint(motor)
				motor.Enabled = false
			elseif motor:IsA("BallSocketConstraint") and motor.Name:sub(1, #PREFIX) ~= PREFIX then
				-- Rótulas que trae el rig nuevo de Roblox: se apagan mientras usamos las nuestras
				motor:SetAttribute("RagdollWasEnabled", motor.Enabled)
				motor.Enabled = false
			end
		end

		for _, p in bodyParts(character) do
			if not saved[p] then
				saved[p] = { collide = p.CanCollide, physics = p.CustomPhysicalProperties }
			end
			if p.Name == "HumanoidRootPart" then
				p.CanCollide = false
			else
				p.CanCollide = true
				p.CustomPhysicalProperties = (p.Name == "UpperTorso" or p.Name == "LowerTorso") and TORSO_PHYSICS or LIMB_PHYSICS
			end
		end

		-- El servidor simula el ragdoll: igual para todos
		Ragdoll.setOwner(character, nil)
	end

	if duration then
		task.delay(duration, function()
			if character.Parent and character:GetAttribute("RagdollToken") == token then
				Ragdoll.disable(character)
			end
		end)
	end
end

-- Altura del suelo debajo de una posición (para levantarse sobre él)
local function groundBelow(character, pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local r = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), params)
	return r and r.Position.Y or nil
end

function Ragdoll.disable(character)
	if not character:GetAttribute("Ragdolled") then return end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end -- los muertos se quedan en el suelo

	character:SetAttribute("Ragdolled", false)

	-- Dónde y hacia dónde mira el cuerpo antes de levantarse
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
	local root = character:FindFirstChild("HumanoidRootPart")
	local pos = torso and torso.Position or Vector3.zero
	local look = torso and torso.CFrame.LookVector * Vector3.new(1, 0, 1) or Vector3.zAxis
	if look.Magnitude < 0.1 then look = Vector3.zAxis end

	for _, d in character:GetDescendants() do
		if d.Name:sub(1, #PREFIX) == PREFIX and (d:IsA("Constraint") or d:IsA("Attachment") or d:IsA("NoCollisionConstraint")) then
			d:Destroy()
		elseif d:IsA("Motor6D") or (d:IsA("AnimationConstraint") and JOINTS[d.Name]) then
			d.Enabled = true
		elseif d:IsA("BallSocketConstraint") and d:GetAttribute("RagdollWasEnabled") ~= nil then
			d.Enabled = d:GetAttribute("RagdollWasEnabled")
			d:SetAttribute("RagdollWasEnabled", nil)
		end
	end
	for _, p in bodyParts(character) do
		local s = saved[p]
		if s then
			p.CanCollide = s.collide
			p.CustomPhysicalProperties = s.physics
			saved[p] = nil
		end
	end

	-- Ponerlo de pie sobre el suelo
	if root then
		local ground = groundBelow(character, pos)
		local y = ground and (ground + hum.HipHeight + root.Size.Y / 2 + 0.1) or (pos.Y + 2)
		character:PivotTo(CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(pos.X, y, pos.Z) + look.Unit))
		for _, p in bodyParts(character) do
			p.AssemblyLinearVelocity = Vector3.zero
			p.AssemblyAngularVelocity = Vector3.zero
		end
	end

	hum.PlatformStand = false
	hum.AutoRotate = true
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	Ragdoll.setOwner(character, Players:GetPlayerFromCharacter(character))
end

-- Mientras lo cargan al hombro: liviano y sin chocar (las extremidades cuelgan sin enredarse)
local CARRIED_PHYSICS = PhysicalProperties.new(0.05, 0.3, 0, 1, 1)
function Ragdoll.setCarried(character, carried)
	if not character:GetAttribute("Ragdolled") then return end
	for _, p in bodyParts(character) do
		if p.Name ~= "HumanoidRootPart" then
			p.CanCollide = not carried
			if carried then
				p.CustomPhysicalProperties = CARRIED_PHYSICS
			else
				p.CustomPhysicalProperties = (p.Name == "UpperTorso" or p.Name == "LowerTorso") and TORSO_PHYSICS or LIMB_PHYSICS
			end
		end
	end
end

-- Desplaza todas las piezas del ragdoll (sin romper sus articulaciones)
function Ragdoll.translate(character, offset)
	for _, p in bodyParts(character) do
		p.CFrame = p.CFrame + offset
	end
end

-- ¿Está boca abajo? (para elegir la animación de levantarse)
function Ragdoll.isFaceDown(character)
	local torso = character:FindFirstChild("UpperTorso")
	return torso ~= nil and torso.CFrame.LookVector.Y < -0.25
end

-- Lanza el cuerpo entero (todas las piezas) con giro, para vuelos tipo Gang Beasts
function Ragdoll.fling(character, velocity, spin)
	for _, p in bodyParts(character) do
		p.AssemblyLinearVelocity = velocity
	end
	local torso = character:FindFirstChild("UpperTorso")
	if torso and spin then
		torso.AssemblyAngularVelocity = spin
	end
end

return Ragdoll
