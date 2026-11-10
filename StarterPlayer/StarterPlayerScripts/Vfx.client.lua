-- LocalScript: StarterPlayer/StarterPlayerScripts/Vfx
-- Efectos visuales de combate (los dibuja cada cliente; el servidor solo avisa qué pasó):
--   · Impactos: sangre estilizada, chispas de metal al bloquear, destello y onda en el parry,
--     esquirlas al romper la guardia, polvo y escombros en golpes contundentes
--   · Polvo al caer al suelo (derribos y lanzamientos)
--   · Imagen residual al esquivar, luz en el arma durante el aviso del fuerte
--   · Cámara: golpe de FOV y desenfoque en impactos fuertes, destello en el parry
--   · Viñeta roja cuando te queda poca vida
-- Texturas: partículas que trae Roblox de fábrica (rbxasset://textures/particles/...).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Effect = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Effect")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local C = Theme.Colors

local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fireSpark = "rbxasset://textures/particles/fire_sparks_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	ring = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
	core = "rbxasset://textures/particles/explosion01_core_main.dds",
	square = "rbxasset://textures/particles/SquareParticle.png",
}

local fxFolder = Instance.new("Folder")
fxFolder.Name = "LocalVfx"
fxFolder.Parent = workspace

----------------------------------------------------------------------
-- Partículas
----------------------------------------------------------------------
local function anchorAt(position, dir, life)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one * 0.2
	local d = (dir and dir.Magnitude > 0.01) and dir.Unit or Vector3.yAxis
	if math.abs(d:Dot(Vector3.yAxis)) > 0.99 then
		p.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(-90), 0, 0)
	else
		p.CFrame = CFrame.lookAt(position, position + d)
	end
	p.Parent = fxFolder
	Debris:AddItem(p, life or 2)
	return p
end

local function seq(a, b)
	return NumberSequence.new(a, b)
end

local function burst(parent, count, props)
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.Texture = props.texture or TEX.spark
	e.Color = ColorSequence.new(props.color or Color3.new(1, 1, 1), props.color2 or props.color or Color3.new(1, 1, 1))
	e.LightEmission = props.light or 0
	e.LightInfluence = props.influence or 0
	e.Size = props.size or seq(0.3, 0)
	e.Transparency = props.transparency or seq(0, 1)
	e.Lifetime = props.life or NumberRange.new(0.2, 0.4)
	e.Speed = props.speed or NumberRange.new(10, 20)
	e.SpreadAngle = props.spread or Vector2.new(40, 40)
	e.Acceleration = props.accel or Vector3.zero
	e.Drag = props.drag or 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = props.rotSpeed or NumberRange.new(0, 0)
	e.EmissionDirection = Enum.NormalId.Front
	e.Orientation = props.orientation or Enum.ParticleOrientation.FacingCamera
	e.ZOffset = props.zoffset or 0.5
	e.Parent = parent
	e:Emit(count)
	return e
end

local function flashLight(parent, color, brightness, range, t)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
	TweenService:Create(l, TweenInfo.new(t or 0.2), { Brightness = 0 }):Play()
	Debris:AddItem(l, (t or 0.2) + 0.05)
end

local BLOOD = Color3.fromRGB(110, 8, 18)
local BLOOD2 = Color3.fromRGB(60, 4, 10)

local function bloodBurst(holder, n)
	burst(holder, n, { texture = TEX.square, color = BLOOD, color2 = BLOOD2, size = seq(0.22, 0.05),
		life = NumberRange.new(0.3, 0.55), speed = NumberRange.new(10, 22), spread = Vector2.new(35, 35),
		accel = Vector3.new(0, -55, 0), drag = 2, influence = 1 })
	burst(holder, math.ceil(n / 2), { texture = TEX.smoke, color = BLOOD, color2 = BLOOD2, size = seq(0.6, 1.4),
		transparency = seq(0.4, 1), life = NumberRange.new(0.25, 0.4), speed = NumberRange.new(2, 5), influence = 1 })
end

local function slashFlash(holder, size, color)
	burst(holder, 1, { texture = TEX.glow, color = color or Color3.new(1, 1, 1), size = seq(size, 0),
		life = NumberRange.new(0.08, 0.12), speed = NumberRange.new(0, 0), light = 1 })
end

local function ring(holder, size, color, life)
	burst(holder, 1, { texture = TEX.ring, color = color or Color3.new(1, 1, 1), size = seq(0.5, size),
		transparency = seq(0.1, 1), life = NumberRange.new(life or 0.25, life or 0.25), speed = NumberRange.new(0, 0), light = 0.7 })
end

local function metalSparks(holder, n, color)
	burst(holder, n, { texture = TEX.fireSpark, color = color or Color3.fromRGB(255, 200, 110), color2 = Color3.fromRGB(255, 120, 40),
		size = seq(0.35, 0), life = NumberRange.new(0.15, 0.35), speed = NumberRange.new(18, 34),
		spread = Vector2.new(70, 70), accel = Vector3.new(0, -40, 0), light = 1, drag = 1 })
end

local function shards(position, dir, color, n)
	for _ = 1, n do
		local p = Instance.new("WedgePart")
		p.Size = Vector3.new(0.08, math.random() * 0.4 + 0.15, math.random() * 0.4 + 0.15)
		p.Color = color
		p.Material = Enum.Material.Metal
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Parent = fxFolder
		local spread = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5) * 30
		p.AssemblyLinearVelocity = dir * 18 + spread
		p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 30
		TweenService:Create(p, TweenInfo.new(0.7), { Transparency = 1 }):Play()
		Debris:AddItem(p, 0.75)
	end
end

local function dust(position, scale)
	scale = scale or 1
	local holder = anchorAt(position, Vector3.yAxis, 3)
	burst(holder, math.floor(10 * scale), { texture = TEX.smoke, color = Color3.fromRGB(110, 100, 90), color2 = Color3.fromRGB(70, 64, 58),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * scale), NumberSequenceKeypoint.new(1, 3.4 * scale) }),
		transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
		life = NumberRange.new(0.7, 1.2), speed = NumberRange.new(5 * scale, 10 * scale), spread = Vector2.new(85, 85),
		accel = Vector3.new(0, 2, 0), drag = 3, influence = 1, rotSpeed = NumberRange.new(-40, 40) })
	burst(holder, math.floor(8 * scale), { texture = TEX.square, color = Color3.fromRGB(70, 66, 60), size = seq(0.2, 0.1),
		life = NumberRange.new(0.4, 0.7), speed = NumberRange.new(10, 18), spread = Vector2.new(60, 60),
		accel = Vector3.new(0, -60, 0), influence = 1 })
end

----------------------------------------------------------------------
-- Cámara
----------------------------------------------------------------------
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Name = "CombatBlur"
blur.Parent = Lighting

local flashCC = Instance.new("ColorCorrectionEffect")
flashCC.Name = "CombatFlash"
flashCC.Parent = Lighting

local fovKick = 0
local appliedKick = 0
local lastFov = nil
local cameraSettings = Theme.CombatCamera
RunService:BindToRenderStep("CombatFov", Enum.RenderPriority.Camera.Value + 3, function(dt)
	local current = workspace.CurrentCamera
	if current ~= camera then
		if camera and lastFov and math.abs(camera.FieldOfView - lastFov) < 0.01 then
			camera.FieldOfView -= appliedKick
		end
		camera = current
		appliedKick = 0
		lastFov = nil
	end
	if not camera then return end
	-- Quitar solo nuestro aporte anterior; respetar cambios de otros controladores.
	local base = camera.FieldOfView
	if lastFov and math.abs(base - lastFov) < 0.01 then base -= appliedKick end
	fovKick = math.max(0, fovKick - dt * cameraSettings.FovDecay)
	if fovKick == 0 and appliedKick == 0 then return end
	local result = math.min(cameraSettings.MaxFov, base + fovKick)
	appliedKick = result - base
	camera.FieldOfView = result
	lastFov = result
end)

local function involvesMe(a, b)
	local me = player.Character
	return me ~= nil and (a == me or b == me)
end

local function cameraPunch(strength)
	fovKick = math.max(fovKick, cameraSettings.FovKick * strength)
	blur.Size = math.max(blur.Size, 10 * strength)
	TweenService:Create(blur, TweenInfo.new(0.25), { Size = 0 }):Play()
end

local function screenFlash(color, intensity)
	flashCC.TintColor = color
	flashCC.Brightness = 0.25 * intensity
	flashCC.Contrast = 0.2 * intensity
	TweenService:Create(flashCC, TweenInfo.new(0.3), { Brightness = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }):Play()
end

----------------------------------------------------------------------
-- Impactos
----------------------------------------------------------------------
local Impact = require(ReplicatedStorage:WaitForChild("PolishConfig")).Impact
local function hitFx(position, kind, dir, attacker, victim)
 if kind == "Light" or kind == "Heavy" then
  if typeof(victim) == "Instance" and victim.Parent then
   local flash = Instance.new("Highlight")
   flash.Adornee = victim flash.FillColor = Impact.White flash.FillTransparency = 0 flash.OutlineTransparency = 1
   flash.Parent = victim
   TweenService:Create(flash, TweenInfo.new(Impact.Life), { FillTransparency = 1 }):Play()
   Debris:AddItem(flash, Impact.Life)
  end
  local slash = Instance.new("Part")
  slash.Size = Impact.SlashSize slash.Material = Enum.Material.Neon slash.Color = Impact.White
  slash.Anchored = true slash.CanCollide = false slash.CanTouch = false slash.CanQuery = false
  slash.CFrame = CFrame.lookAt(position, position + dir) * CFrame.Angles(0, 0, math.rad(Impact.SlashAngle)) * CFrame.Angles(0, math.rad(Impact.SlashYaw), 0)
  slash.Parent = fxFolder
  TweenService:Create(slash, TweenInfo.new(Impact.SlashLife), { Transparency = 1 }):Play()
  Debris:AddItem(slash, Impact.SlashLife)
 end
	local holder = anchorAt(position, dir, 2)
	local mine = involvesMe(attacker, victim)
	if kind == "Light" then
		bloodBurst(holder, 10)
		slashFlash(holder, 1.6)
		if mine then cameraPunch(0.25) end
	elseif kind == "Heavy" then
		bloodBurst(holder, 20)
		slashFlash(holder, 3)
		ring(holder, 5, Color3.fromRGB(255, 235, 220), 0.22)
		flashLight(holder, Color3.fromRGB(255, 220, 200), 3, 12, 0.2)
		if mine then cameraPunch(1) end
	elseif kind == "Blunt" then
		bloodBurst(holder, 8)
		ring(holder, 4.5, Color3.fromRGB(200, 190, 170), 0.25)
		dust(position - Vector3.new(0, 1.5, 0), 0.6)
		if mine then cameraPunch(0.6) end
	elseif kind == "Block" or kind == "BlockHeavy" then
		local heavy = kind == "BlockHeavy"
		metalSparks(holder, heavy and 26 or 14)
		slashFlash(holder, heavy and 2.2 or 1.3, Color3.fromRGB(255, 210, 150))
		flashLight(holder, Color3.fromRGB(255, 180, 90), heavy and 4 or 2, 10, 0.15)
		if mine and heavy then cameraPunch(0.35) end
	elseif kind == "Parry" then
		metalSparks(holder, 34, Color3.fromRGB(210, 235, 255))
		slashFlash(holder, 4.5, C.ParryFlash)
		ring(holder, 9, C.ParryFlash, 0.3)
		flashLight(holder, C.ParryFlash, 6, 18, 0.3)
		if mine then
			cameraPunch(0.7)
			screenFlash(C.ParryFlash, 1)
		end
	elseif kind == "GuardBreak" then
		metalSparks(holder, 22)
		shards(position, dir, Color3.fromRGB(150, 150, 160), 7)
		ring(holder, 7, C.GuardBreak, 0.3)
		flashLight(holder, C.GuardBreak, 5, 14, 0.25)
		if mine then
			cameraPunch(0.9)
			screenFlash(C.GuardBreak, 0.6)
		end
	end
end

Effect.OnClientEvent:Connect(function(kind, a, b, c, d, e)
	if kind == "HitFx" then
		hitFx(a, b, c, d, e)
	elseif kind == "Dust" then
		dust(a, b)
	end
end)

----------------------------------------------------------------------
-- Imagen residual al esquivar y luz en el arma durante el aviso
----------------------------------------------------------------------
local function afterimage(char)
	for i = 0, 1 do
		task.delay(i * 0.09, function()
			if not char.Parent then return end
			for _, part in char:GetChildren() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
					local ok, ghost = pcall(function() return part:Clone() end)
					if ok and ghost then
						ghost:ClearAllChildren()
						ghost.Anchored = true
						ghost.CanCollide = false
						ghost.CanQuery = false
						ghost.CanTouch = false
						ghost.CastShadow = false
						ghost.Material = Enum.Material.ForceField
						ghost.Color = C.IFrame
						ghost.Transparency = 0.2
						ghost.CFrame = part.CFrame
						ghost.Parent = fxFolder
						TweenService:Create(ghost, TweenInfo.new(0.35), { Transparency = 1 }):Play()
						Debris:AddItem(ghost, 0.4)
					end
				end
			end
		end)
	end
end

local telegraphLights = setmetatable({}, { __mode = "k" })

local function watch(char)
	char:GetAttributeChangedSignal("IFrameUntil"):Connect(function()
		if (char:GetAttribute("IFrameUntil") or 0) > 0 then afterimage(char) end
	end)
	char:GetAttributeChangedSignal("Telegraph"):Connect(function()
		local old = telegraphLights[char]
		if old then old:Destroy() telegraphLights[char] = nil end
		local tg = char:GetAttribute("Telegraph") or ""
		if tg == "" then return end
		local tool = char:FindFirstChildOfClass("Tool")
		local tip = tool and tool:FindFirstChild("BladeTip", true)
		if not tip then return end
		-- etapa 8: luz roja corta en la punta (no tiñe toda el arma); el punto lo dibuja Overhead
		local TG = require(ReplicatedStorage:WaitForChild("PolishConfig")).Telegraph
		local l = Instance.new("PointLight")
		l.Color = tg == "Unblockable" and TG.UnblockableHalo or TG.HeavyHalo
		l.Brightness = 0
		l.Range = TG.LightRange
		l.Parent = tip
		TweenService:Create(l, TweenInfo.new(0.25), { Brightness = TG.LightBrightness }):Play()
		telegraphLights[char] = l
		-- chispa de aviso en la punta del arma (forma distinta al fuego de las infusiones)
		burst(tip, 1, { texture = TEX.ring, color = l.Color, size = seq(4, 0.3), transparency = seq(0.1, 0.6),
			life = NumberRange.new(0.35, 0.35), speed = NumberRange.new(0, 0), light = 1, zoffset = 1 })
	end)
end

CollectionService:GetInstanceAddedSignal("Combatant"):Connect(watch)
for _, m in CollectionService:GetTagged("Combatant") do watch(m) end

----------------------------------------------------------------------
-- Viñeta roja con poca vida
----------------------------------------------------------------------
local vgui = Instance.new("ScreenGui")
vgui.Name = "LowHealth"
vgui.IgnoreGuiInset = true
vgui.ResetOnSpawn = false
vgui.DisplayOrder = -1
vgui.Parent = player:WaitForChild("PlayerGui")

local edges = {}
local function edge(anchor, pos, size, rotation)
	local f = Instance.new("Frame")
	f.AnchorPoint = anchor
	f.Position = pos
	f.Size = size
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.fromRGB(90, 0, 8)
	f.BackgroundTransparency = 1
	f.Parent = vgui
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	g.Transparency = NumberSequence.new(0, 1)
	g.Parent = f
	table.insert(edges, f)
end
edge(Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 0.25), 90)
edge(Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.25), -90)
edge(Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(0.2, 1), 0)
edge(Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromScale(0.2, 1), 180)

-- 0.2 (C23): borde de impacto. Rojo al recibir, acero al bloquear, naranja al quedar abierto.
-- Va en un marco aparte para no pelear con la viñeta de poca vida.
local hitEdges = {}
for _, src in edges do
	local f = src:Clone()
	f.Parent = vgui
	table.insert(hitEdges, f)
end
local hitEdge, hitEdgeMax, hitEdgeTime = 0, 0, 0.3

RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local frac = hum and hum.MaxHealth > 0 and hum.Health / hum.MaxHealth or 1
	local intensity = 0
	if hum and hum.Health > 0 and frac < 0.35 then
		intensity = (0.35 - frac) / 0.35
		intensity = intensity * (0.75 + 0.25 * math.sin(os.clock() * 5))
	end
	for _, f in edges do
		f.BackgroundTransparency = 1 - intensity * 0.7
	end
	if hitEdge > 0 then
		hitEdge = math.max(0, hitEdge - dt * hitEdgeMax / math.max(0.05, hitEdgeTime))
	end
	for _, f in hitEdges do
		f.BackgroundTransparency = 1 - hitEdge
	end
end)

----------------------------------------------------------------------
-- 0.2: sensación del combate (contrato C23). El servidor avisa a cada involucrado qué le pasó (Effect "Feel"):
-- golpear, recibir, bloquear y parry suenan y se ven distinto. Los sonidos van en 2D y bajos: son el «cuerpo»
-- propio que se suma al sonido 3D del impacto (guía lihfolk-sfx: lo tuyo en 2D, nunca adelantar el resultado).
----------------------------------------------------------------------
local Assets = require(ReplicatedStorage:WaitForChild("Assets"))
local FEEL = require(ReplicatedStorage:WaitForChild("PolishConfig")).Feel
local SoundService = game:GetService("SoundService")

local function sound2D(path, volume, pitch)
	local id = path and Assets.sound(path)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = (pitch or 1) * (1 + (math.random() * 2 - 1) * 0.04)
	s.SoundGroup = SoundService:FindFirstChild("SFX")
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 4)
end

local function edgeFlash(color, amount, time)
	for _, f in hitEdges do f.BackgroundColor3 = color end
	hitEdge = math.clamp(math.max(hitEdge, amount), 0, 0.9)
	hitEdgeMax = hitEdge
	hitEdgeTime = time or 0.3
end

local EDGE_COLOR = {
	Take = "TakeColor", Block = "BlockColor", Parried = "ParriedColor", GuardBroken = "GuardBrokenColor",
}

Effect.OnClientEvent:Connect(function(kind, role, info)
	if kind ~= "Feel" or type(role) ~= "string" or not FEEL then return end
	local cfg = FEEL[role]
	if type(cfg) ~= "table" then return end
	info = type(info) == "table" and info or {}
	local fin = info.finisher == true and FEEL.Finisher or nil
	local heavy = info.kind == "Heavy" or fin ~= nil
	sound2D(cfg.Sound, (cfg.Volume or 0.4) * (heavy and 1.2 or 1) * (fin and fin.VolumeMult or 1), cfg.Pitch)
	if cfg.Edge and EDGE_COLOR[role] then
		edgeFlash(FEEL[EDGE_COLOR[role]], cfg.Edge * (heavy and 1.25 or 1) * (fin and fin.EdgeMult or 1), cfg.EdgeTime)
	end
	if cfg.Punch then cameraPunch(cfg.Punch * (heavy and 1.6 or 1)) end
end)

----------------------------------------------------------------------
-- 0.2 ronda 2: almas (D5) y subida de nivel. Solo en tu pantalla, sobre tu personaje.
--   Almas: cuando sube leaderstats.Coins, unas luces pálidas llegan desde alrededor y se absorben en el pecho.
--   Nivel: cuando sube el atributo Level, anillo dorado que se abre y una columna de luz.
----------------------------------------------------------------------
local POL = require(ReplicatedStorage:WaitForChild("PolishConfig"))
local SOULS, LEVELUP = POL.Souls, POL.LevelUp

local function neonPart(size, color, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	if shape then p.Shape = shape end
	p.Parent = fxFolder
	return p
end

local function absorbSouls(amount)
	local char = player.Character
	local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"))
	if not torso or not SOULS then return end
	local n = math.clamp(math.floor(amount / SOULS.PerWisp), SOULS.MinWisps, SOULS.MaxWisps)
	sound2D(SOULS.Sound, SOULS.Volume, 1)
	for i = 1, n do
		task.delay((i - 1) * SOULS.Stagger, function()
			if not torso.Parent then return end
			local a = math.random() * math.pi * 2
			local start = torso.Position + Vector3.new(math.cos(a) * SOULS.Radius, (math.random() - 0.3) * SOULS.Height, math.sin(a) * SOULS.Radius)
			local w = neonPart(Vector3.one * SOULS.Size, SOULS.Color, Enum.PartType.Ball)
			w.Position = start
			w.Transparency = 0.15
			local light = Instance.new("PointLight")
			light.Color = SOULS.Color
			light.Range = 5
			light.Brightness = 1.2
			light.Parent = w
			local tw = TweenService:Create(w, TweenInfo.new(SOULS.Travel, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = torso.Position, Size = Vector3.one * SOULS.Size * 0.4 })
			tw:Play()
			tw.Completed:Connect(function()
				w:Destroy()
				if torso.Parent then
					local holder = anchorAt(torso.Position, Vector3.yAxis, 1)
					burst(holder, 4, { color = SOULS.Core, color2 = SOULS.Color, size = seq(0.35, 0), light = 1,
						life = NumberRange.new(0.15, 0.3), speed = NumberRange.new(2, 5), spread = Vector2.new(180, 180) })
				end
			end)
			Debris:AddItem(w, SOULS.Travel + 0.5)
		end)
	end
end

local function levelUpFx()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not LEVELUP then return end
	sound2D(LEVELUP.Sound, LEVELUP.Volume, 1.1)
	local base = root.Position - Vector3.new(0, 2.8, 0)
	local ring = neonPart(Vector3.new(0.2, 1, 1), LEVELUP.Color, Enum.PartType.Cylinder)
	ring.CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.2
	TweenService:Create(ring, TweenInfo.new(LEVELUP.RingTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.2, LEVELUP.RingSize, LEVELUP.RingSize), Transparency = 1 }):Play()
	Debris:AddItem(ring, LEVELUP.RingTime + 0.1)
	local pillar = neonPart(Vector3.new(1.2, 0.5, 1.2), LEVELUP.Color, Enum.PartType.Cylinder)
	pillar.CFrame = CFrame.new(base) * CFrame.Angles(0, 0, math.rad(90))
	pillar.Transparency = 0.35
	TweenService:Create(pillar, TweenInfo.new(LEVELUP.PillarTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(LEVELUP.PillarHeight, 0.4, 0.4),
		CFrame = CFrame.new(base + Vector3.yAxis * LEVELUP.PillarHeight / 2) * CFrame.Angles(0, 0, math.rad(90)),
		Transparency = 1,
	}):Play()
	Debris:AddItem(pillar, LEVELUP.PillarTime + 0.1)
	flashLight(anchorAt(root.Position + Vector3.yAxis * 3, Vector3.yAxis, 1.2), LEVELUP.Color, 3, 16, 0.6)
end

task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 30)
	local coins = stats and stats:WaitForChild("Coins", 30)
	if not coins then return end
	local last = coins.Value
	local readyAt = os.clock() + 8 -- al entrar se carga el saldo guardado: eso no es ganar almas
	coins.Changed:Connect(function(v)
		local gained = v - last
		last = v
		if gained > 0 and os.clock() >= readyAt then absorbSouls(gained) end
	end)
end)

local lastLevel = player:GetAttribute("Level")
player:GetAttributeChangedSignal("Level"):Connect(function()
	local lv = player:GetAttribute("Level")
	if type(lv) == "number" and type(lastLevel) == "number" and lv > lastLevel then levelUpFx() end
	lastLevel = lv
end)
