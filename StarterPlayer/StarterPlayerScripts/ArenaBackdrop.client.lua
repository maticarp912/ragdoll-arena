-- LocalScript: StarterPlayer/StarterPlayerScripts/ArenaBackdrop (Ronda 3B, responsable: Gemini)
-- Fondo y ambiente local de las arenas:
--   1. Mares de niebla, ceniza/rocío y rocas orbitando en cada arena aislada.
--   2. Escombros que se desprenden del borde durante la partida.
--   3. Efectos propios Arena* en Lighting activos solo con InMatch (ArenaDOF, ArenaTone por variante).
--   4. Desenfoque y fundido de cámara al caer al vacío (ArenaFallBlur y ArenaFallColor, solo para quien cae).
--   5. Flujo de espuma y rocío en las cascadas (partes "Waterfall").

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Theme = require(ReplicatedStorage:WaitForChild("Theme", 10))
local ArenaConfig = require(ReplicatedStorage:WaitForChild("ArenaConfig", 10))

local player = Players.LocalPlayer
local AA = Theme.Ambience.Arena
local S = ArenaConfig.Scenery

----------------------------------------------------------------------
-- 1. Capas de niebla, partículas abisales y rocas que orbitan por arena
----------------------------------------------------------------------
local fx = Instance.new("Folder")
fx.Name = "ArenaBackdrop"
fx.Parent = workspace

local function deco(name, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = color
	p.Material = material
	p.Transparency = transparency or 0
	p.Parent = fx
	return p
end

local rocks = {}
local mistEmitters = {} -- [modeName] = { emitter1, emitter2, ... }
local rng = Random.new(77)

for modeName, mode in ArenaConfig.Modes do
	local c, R = mode.center, mode.radius
	mistEmitters[modeName] = {}

	-- Mares de niebla espesa bajo la plataforma que tapan cualquier corte y dan profundidad
	for i, depth in AA.MistLayers do
		local holder = deco("MistLayer_" .. modeName, Vector3.new(R * 5, 1, R * 5), CFrame.new(c + Vector3.new(0, depth, 0)), Color3.new(), Enum.Material.SmoothPlastic, 1)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(AA.MistColor)
		e.LightInfluence = 0.85
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0.38 + i * 0.08),
			NumberSequenceKeypoint.new(0.75, 0.42 + i * 0.08),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Size = NumberSequence.new(R * 0.55, R * 0.95)
		e.Lifetime = NumberRange.new(16, 24)
		e.Rate = AA.MistRate
		e.Speed = NumberRange.new(1, 3)
		e.SpreadAngle = Vector2.new(70, 70)
		e.Acceleration = Vector3.new(0.5, 0, 0.3)
		e.RotSpeed = NumberRange.new(-4, 4)
		e.Rotation = NumberRange.new(0, 360)
		e.Parent = holder
		table.insert(mistEmitters[modeName], e)
	end

	-- Motas / ceniza que asciende desde el abismo
	local ashHolder = deco("AshLayer_" .. modeName, Vector3.new(R * 3, 1, R * 3), CFrame.new(c - Vector3.new(0, 38, 0)), Color3.new(), Enum.Material.SmoothPlastic, 1)
	local ash = Instance.new("ParticleEmitter")
	ash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	ash.Color = ColorSequence.new(Color3.fromRGB(175, 170, 165))
	ash.LightInfluence = 0.7
	ash.Size = NumberSequence.new(0.28, 0)
	ash.Transparency = NumberSequence.new(0.25, 1)
	ash.Lifetime = NumberRange.new(6, 10)
	ash.Rate = AA.AshRate
	ash.Speed = NumberRange.new(3, 6)
	ash.EmissionDirection = Enum.NormalId.Top
	ash.SpreadAngle = Vector2.new(30, 30)
	ash.Parent = ashHolder

	-- Rocas flotantes que orbitan en el abismo (siempre por debajo de la línea de cámara)
	for _ = 1, AA.Rocks do
		local size = Vector3.new(4 + rng:NextNumber() * 10, 3 + rng:NextNumber() * 6, 4 + rng:NextNumber() * 9)
		local rock = deco("OrbitRock", size, CFrame.new(c), Color3.fromRGB(58, 56, 62), Enum.Material.Slate)
		local chunk = deco("OrbitRock", size * 0.6, CFrame.new(c), Color3.fromRGB(42, 40, 48), Enum.Material.Basalt)
		table.insert(rocks, {
			parts = { rock, chunk },
			center = c,
			orbit = R * 1.45 + rng:NextNumber() * (R * 0.65),
			height = math.min(-10, AA.RockHeight[1] + rng:NextNumber() * (AA.RockHeight[2] - AA.RockHeight[1])),
			angle = rng:NextNumber() * math.pi * 2,
			spin = (rng:NextNumber() - 0.5) * 0.3,
			speed = AA.RockSpeed * (0.6 + rng:NextNumber()),
		})
	end
end

----------------------------------------------------------------------
-- 2. Efectos Arena* en Lighting (activos solo con InMatch) y desenfoque al caer
----------------------------------------------------------------------
local dof = Lighting:FindFirstChild("ArenaDOF") or Instance.new("DepthOfFieldEffect")
dof.Name = "ArenaDOF"
for k, v in AA.DOF do
	dof[k] = v
end
dof.Enabled = false
dof.Parent = Lighting

local arenaTone = Lighting:FindFirstChild("ArenaTone") or Instance.new("ColorCorrectionEffect")
arenaTone.Name = "ArenaTone"
arenaTone.Brightness = S.Exposure
arenaTone.TintColor = S.AmbientTint
arenaTone.Enabled = false
arenaTone.Parent = Lighting

-- Efectos exclusivos para quien cae al vacío de la arena
local fallBlur = Lighting:FindFirstChild("ArenaFallBlur") or Instance.new("BlurEffect")
fallBlur.Name = "ArenaFallBlur"
fallBlur.Size = 0
fallBlur.Enabled = false
fallBlur.Parent = Lighting

local fallColor = Lighting:FindFirstChild("ArenaFallColor") or Instance.new("ColorCorrectionEffect")
fallColor.Name = "ArenaFallColor"
fallColor.Brightness = 0
fallColor.Contrast = 0
fallColor.TintColor = Color3.fromRGB(255, 255, 255)
fallColor.Enabled = false
fallColor.Parent = Lighting

local fallIntensity = 0

local function clearFallEffects()
	fallIntensity = 0
	if fallBlur then
		fallBlur.Size = 0
		fallBlur.Enabled = false
	end
	if fallColor then
		fallColor.Brightness = 0
		fallColor.Contrast = 0
		fallColor.TintColor = Color3.fromRGB(255, 255, 255)
		fallColor.Enabled = false
	end
end

-- Limpieza garantizada al reaparecer o al revivir (nunca pantalla borrosa en la ciudad)
player.CharacterAdded:Connect(function()
	clearFallEffects()
end)

player:GetAttributeChangedSignal("Eliminated"):Connect(function()
	if not player:GetAttribute("Eliminated") then
		clearFallEffects()
	end
end)

local function findClosestMode(pos)
	local bestName, bestMode, bestDist = nil, nil, math.huge
	for modeName, mode in ArenaConfig.Modes do
		local d = (pos - mode.center).Magnitude
		if d < bestDist then
			bestDist = d
			bestName = modeName
			bestMode = mode
		end
	end
	return bestName, bestMode, bestDist
end

local function getActiveVariant(modeName)
	local attr = workspace:GetAttribute("ArenaVariant" .. modeName)
	if type(attr) == "string" and attr ~= "" then
		return attr
	end
	local mapFolder = workspace:FindFirstChild("GeneratedMap")
	local arenaFolder = mapFolder and mapFolder:FindFirstChild("Arena_" .. modeName)
	local v = arenaFolder and arenaFolder:GetAttribute("Variant")
	return (type(v) == "string" and v ~= "") and v or "Forest"
end

local function updateArenaLighting()
	local inMatch = player:GetAttribute("InMatch") == true
	dof.Enabled = inMatch
	arenaTone.Enabled = inMatch

	if not inMatch then
		clearFallEffects()
		return
	end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local modeName = "1v1"
	if root then
		local closestName = findClosestMode(root.Position)
		if closestName then modeName = closestName end
	end

	local variant = getActiveVariant(modeName)
	local preset = S.VariantAmbience and S.VariantAmbience[variant]
	if preset then
		arenaTone.Brightness = preset.Brightness
		arenaTone.Contrast = preset.Contrast
		arenaTone.Saturation = preset.Saturation
		arenaTone.TintColor = preset.Tint
		local emitters = mistEmitters[modeName]
		if emitters and preset.MistColor then
			for _, em in emitters do
				em.Color = ColorSequence.new(preset.MistColor)
			end
		end
	else
		arenaTone.Brightness = S.Exposure
		arenaTone.Contrast = 0
		arenaTone.Saturation = 0
		arenaTone.TintColor = S.AmbientTint
	end
end

player:GetAttributeChangedSignal("InMatch"):Connect(updateArenaLighting)
workspace:GetAttributeChangedSignal("ArenaVariant1v1"):Connect(updateArenaLighting)
workspace:GetAttributeChangedSignal("ArenaVariant2v2"):Connect(updateArenaLighting)
updateArenaLighting()

----------------------------------------------------------------------
-- 3. Bucle de animación: rocas en órbita + desenfoque y fundido al caer
----------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	-- 11/11 (rendimiento): con efectos reducidos las rocas de fondo no orbitan
	for _, r in (player:GetAttribute("OptFx") == 0 and {} or rocks) do
		r.angle += r.speed * dt
		local pos = r.center + Vector3.new(
			math.cos(r.angle) * r.orbit,
			r.height + math.sin(t * 0.4 + r.angle) * 2,
			math.sin(r.angle) * r.orbit
		)
		local rot = CFrame.Angles(t * r.spin, t * r.spin * 0.7, 0)
		r.parts[1].CFrame = CFrame.new(pos) * rot
		r.parts[2].CFrame = CFrame.new(pos) * rot * CFrame.new(r.parts[1].Size.X * 0.4, -r.parts[1].Size.Y * 0.5, 0)
	end

	-- Desenfoque y fundido de cámara al caer de la arena (solo para quien cae)
	local inArena = (player:GetAttribute("InMatch") == true) or (player:GetAttribute("PracticeOnly") == true)
	if not inArena then
		if fallIntensity > 0 or fallBlur.Enabled or fallColor.Enabled then
			clearFallEffects()
		end
		return
	end

	local targetFall = 0
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		local modeName, mode, dist = findClosestMode(root.Position)
		if mode and dist < mode.radius * 3.5 then
			local drop = (mode.center.Y - S.FallStartDrop) - root.Position.Y
			if drop > 0 then
				local span = math.max(8, ArenaConfig.Match.VoidDrop - S.FallStartDrop)
				targetFall = math.clamp(drop / span, 0, 1)
			end
			-- Si ya fue eliminado por caída, mantenemos el fundido hasta reaparecer
			if player:GetAttribute("Eliminated") == true and root.Position.Y < mode.center.Y - 4 then
				targetFall = math.max(targetFall, 0.92)
			end
			-- Actualizamos el tinte de la variante si cambió
			local variant = getActiveVariant(modeName)
			local preset = S.VariantAmbience and S.VariantAmbience[variant]
			if preset and arenaTone.Enabled then
				arenaTone.TintColor = preset.Tint
			end
		else
			-- Jugador en partida pero fuera del radio de arena (ej. transición o lobby)
			clearFallEffects()
			return
		end
	else
		clearFallEffects()
		return
	end

	local speed = (targetFall > fallIntensity) and 10 or 6
	fallIntensity += (targetFall - fallIntensity) * math.min(1, dt * speed)
	if fallIntensity < 0.01 and targetFall == 0 then
		clearFallEffects()
		return
	end

	if fallIntensity > 0 then
		fallBlur.Enabled = true
		fallBlur.Size = fallIntensity * S.FallBlurMax
		fallColor.Enabled = true
		fallColor.Brightness = fallIntensity * S.FallBrightnessMin
		fallColor.Contrast = fallIntensity * S.FallContrastMax
		fallColor.TintColor = Color3.fromRGB(
			math.floor(255 - fallIntensity * 75),
			math.floor(255 - fallIntensity * 70),
			math.floor(255 - fallIntensity * 55)
		)
	else
		clearFallEffects()
	end
end)

----------------------------------------------------------------------
-- 4. Escombros que se desprenden del borde (solo en partida)
----------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(AA.DebrisEvery[1] + math.random() * (AA.DebrisEvery[2] - AA.DebrisEvery[1]))
		if player:GetAttribute("InMatch") then
			for _, mode in ArenaConfig.Modes do
				local a = math.random() * math.pi * 2
				local p = mode.center + Vector3.new(math.cos(a) * mode.radius * 0.95, -6, math.sin(a) * mode.radius * 0.95)
				local d = deco("FallingDebris", Vector3.one * (1 + math.random() * 2.5), CFrame.new(p), Color3.fromRGB(70, 68, 74), Enum.Material.Slate)
				d.Anchored = false
				d.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 6
				Debris:AddItem(d, 6)
			end
		end
	end
end)

----------------------------------------------------------------------
-- 5. Partículas de agua y rocío para las cascadas (variante Mano)
----------------------------------------------------------------------
local flows = {}
local function addFlow(obj)
	if obj.Name ~= "Waterfall" or not obj:IsA("BasePart") or flows[obj] then return end
	flows[obj] = true
	local e = Instance.new("ParticleEmitter")
	e.Name = "ArenaWaterFlow"
	e.Texture = ArenaConfig.DustTexture
	e.Color = ColorSequence.new(S.Foam, S.Waterfall)
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.6, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Rate = S.FlowRate
	e.Lifetime = S.FlowLife
	e.Speed = S.FlowSpeed
	e.Size = S.FlowSize
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Parent = obj
end

for _, obj in workspace:GetDescendants() do
	addFlow(obj)
end
workspace.DescendantAdded:Connect(addFlow)
workspace.DescendantRemoving:Connect(function(obj)
	flows[obj] = nil
end)

