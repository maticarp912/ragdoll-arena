-- ModuleScript: ReplicatedStorage/Theme
-- Paleta y estilo dark fantasy. TODA la UI, placeholders y VFX provisionales leen de aquí:
-- para aplicar el arte final basta con cambiar este archivo.

local rgb = Color3.fromRGB

local Theme = {}

Theme.Colors = {
	-- Fondos / piedra
	Charcoal = rgb(14, 15, 20),     -- #0E0F14
	Stone = rgb(42, 45, 54),        -- #2A2D36
	StoneLight = rgb(58, 61, 70),
	Ochre = rgb(110, 92, 60),
	Rust = rgb(110, 58, 38),

	-- Interfaz
	Panel = rgb(26, 28, 36),        -- #1A1C24
	PanelLight = rgb(38, 40, 50),
	Gold = rgb(184, 155, 94),       -- #B89B5E (borde dorado envejecido)
	Bone = rgb(232, 226, 208),      -- #E8E2D0 (texto)
	BoneDim = rgb(160, 154, 140),
	Disabled = rgb(70, 70, 78),

	-- Barras
	Health = rgb(150, 24, 30),      -- rojo oscuro
	Stun = rgb(222, 160, 40),       -- ámbar
	Guard = rgb(90, 130, 170),      -- azul acero
	Stamina = rgb(120, 150, 70),    -- verde musgo
	IFrame = rgb(225, 235, 255),    -- brillo pálido de invulnerabilidad al esquivar
	BarBack = rgb(12, 12, 16),
	InfusionCharge = rgb(200, 180, 120),

	-- Avisos de combate (se distinguen también por forma y sonido, no solo por color)
	TelegraphHeavy = rgb(255, 140, 30),       -- destello naranja: fuerte
	TelegraphUnblockable = rgb(235, 30, 40),  -- destello rojo: imbloqueable
	ParryFlash = rgb(190, 225, 255),          -- destello azul/metálico
	BlockGlow = rgb(140, 170, 200),           -- arma en guardia
	Riposte = rgb(255, 200, 90),             -- 10/11: contragolpe de peso listo (Espadón y Maza)
	GuardBreak = rgb(255, 200, 120),
	Damage = rgb(232, 226, 208),
	Dodge = rgb(170, 170, 190),

	-- Debug
	Hitbox = rgb(255, 40, 40),
	HitboxHit = rgb(40, 255, 80),
}

-- Infusiones (único color vivo del juego, junto con los avisos)
Theme.Infusions = {
	Fire = rgb(255, 106, 43),       -- #FF6A2B
	Lightning = rgb(127, 212, 255), -- #7FD4FF
	Blood = rgb(179, 18, 46),       -- #B3122E
	Ice = rgb(168, 230, 255),       -- #A8E6FF
	Poison = rgb(139, 224, 74),     -- #8BE04A
	Shadow = rgb(107, 63, 160),     -- #6B3FA0
}

-- Equipos: contorno tenue para leer a los jugadores sobre fondos oscuros
Theme.Teams = {
	Red = rgb(190, 60, 55),
	Blue = rgb(70, 110, 190),
	None = rgb(200, 195, 180),
	OutlineTransparency = 0.55,
}

-- 10/11/2026: si una fuente no existiera en esta versión de Roblox, no se rompe la interfaz (cae a Gotham/Garamond)
local function safeFont(name)
	local ok, f = pcall(function() return Enum.Font[name] end)
	if ok and f then return f end
	return name == "GrenzeGotisch" and Enum.Font.Garamond or Enum.Font.GothamMedium
end
Theme.Fonts = {
	Title = safeFont("GrenzeGotisch"), -- 10/11: gótica para títulos (antes Garamond)
	Body = safeFont("Merriweather"),  -- 10/11: serif clásica (antes Gotham)
	Number = safeFont("BuilderSansBold"), -- números y teclas
}

Theme.Sizes = {
	Corner = 4,       -- esquinas casi rectas (piedra/metal)
	Stroke = 1.5,     -- borde dorado
	TextSmall = 12,
	Text = 14,
	TextBig = 18,
	Title = 24,
}

-- Arena y lobby provisionales (piedra oscura, nada de SmoothPlastic)
Theme.Arena = {
	Material = Enum.Material.Slate,
	TileA = rgb(118, 113, 122),     -- piedra gris clara: se distingue el piso y sus bordes
	TileB = rgb(132, 127, 134),
	TileWarning = rgb(150, 40, 30),
	LobbyMaterial = Enum.Material.Cobblestone,
	Lobby = rgb(48, 46, 44),
	Practice = rgb(56, 50, 44),
	DummyBody = rgb(90, 84, 72),
}

-- Iluminación base (se aplica al arrancar el servidor)
Theme.Lighting = {
	ClockTime = 0,
	-- 9/11: la ciudad se veía demasiado iluminada; todo ~25 % más oscuro (antes 2.6 / 105,100,135 / 140,140,178 / 0.3)
	Brightness = 2.0,                -- luz de luna: se ven suelo, bordes y personajes
	Ambient = rgb(84, 80, 110),
	OutdoorAmbient = rgb(108, 108, 140),
	ExposureCompensation = 0.05,
	-- Filtro dark fantasy: frío, desaturado y con contraste (se leen los personajes; el color vivo queda en luces e infusiones)
	Atmosphere = { Density = 0.3, Offset = 0.08, Color = rgb(138, 146, 164), Decay = rgb(40, 44, 58), Glare = 0, Haze = 1.7 },
	ColorCorrection = { Saturation = -0.24, Contrast = 0.22, Brightness = 0.02, TintColor = rgb(212, 222, 240) },
	Bloom = { Intensity = 0.26, Size = 24, Threshold = 1.4 }, -- faroles y ventanas brillan (9/11: antes 0.32 / 26 / 1.25)
}

-- 9/11: sin estrellas blancas ni luna de Roblox; las estrellas doradas y la luna azulada las dibuja Sky.client
Theme.Lighting.Sky = { StarCount = 0, MoonAngularSize = 18, SunAngularSize = 0, CelestialBodiesShown = false }
Theme.Lighting.Clouds = { Cover = 0.7, Density = 0.55, Color = rgb(64, 68, 82) } -- cielo cubierto, la luna asoma
-- Cielo de estrellas doradas (referencia 01_cielo_estrellas_doradas). Lo dibuja Sky.client y sigue a la cámara.
Theme.Lighting.Stars = {
	Count = 3200, MobileCount = 1400, Radius = 650, MinElevation = 0.08, Seed = 308, -- 650: más lejos la niebla de la atmósfera las apaga
	-- tamaños (studs a 650 de distancia): muchas chicas, algunas medianas y pocas grandes con halo
	Tiers = { { share = 0.7, size = { 1.1, 2.2 } }, { share = 0.23, size = { 2.6, 4.2 } }, { share = 0.07, size = { 5, 8 } } },
	Colors = { rgb(255, 214, 140), rgb(255, 186, 84), rgb(255, 232, 186), rgb(255, 160, 60) },
	HaloScale = 3.2, HaloTransparency = 0.82, HaloColor = rgb(255, 170, 70),
	TwinkleCount = 260, TwinkleSpeed = { 0.6, 2.2 }, TwinkleDepth = 0.55,
	DenseBias = 0.55, -- más densas hacia lo alto del cielo
	-- Glow: manchas de resplandor; apagadas (Count 0) porque con la niebla se veían como discos grises
	Glow = { Count = 0, Size = { 180, 320 }, Transparency = 0.955, Color = rgb(255, 150, 60), Elevation = { 0.35, 0.8 } },
	Moon = { Direction = Vector3.new(0.08, 0.55, 1), Size = 34, Color = rgb(186, 214, 255), HaloScale = 2.4, HaloTransparency = 0.86, HaloColor = rgb(120, 170, 255) },
	FollowDistance = 150, -- recentra la cúpula cuando la cámara se aleja tanto (ciudad, arenas)
}
Theme.Lobby = {
 OverheadDistance = 45, -- barras de vida sobre la cabeza en la ciudad: solo de cerca y sin atravesar paredes
 Center = Vector3.new(-450, 50, 0), Floor = Vector3.new(90, 2, 90), PracticeOffset = Vector3.new(70, 0, 0), PracticeSize = Vector3.new(60, 2, 60), BridgeSize = Vector3.new(25, 2, 14), BridgeOffset = Vector3.new(45, 0, 0), Spawn = Vector3.new(0, 5, 15), DummyX = 10, DummyY = 4, DummyZ = { -14, 0, 14 },
 Stone = rgb(150, 136, 188), Wood = rgb(65, 42, 48), Roof = rgb(47, 35, 79), Leaves = rgb(28, 91, 91), Flower = rgb(164, 85, 219), Warm = rgb(255, 204, 116),
 HouseSize = Vector3.new(17, 15, 18), HouseX = { -30, 30 }, HouseZ = { -28, 28 }, RoofSize = Vector3.new(21, 13, 22), RoofThickness = 0.8, WindowSize = Vector3.new(3, 4, 0.3), WindowOffset = Vector3.new(0, 2, -9.2), DoorSize = Vector3.new(4, 7, 0.4), DoorOffset = Vector3.new(0, -4, -9.3),
 TreeCount = 12, TreeRadius = 43, TrunkSize = Vector3.new(2, 17, 2), CrownSize = Vector3.new(15, 15, 15), CrownHeight = 18, TreeY = 9,
 LampSize = Vector3.new(1.5, 2.5, 1.5), LampHeight = 8, LampRange = 30, LampBrightness = 3, PostSize = Vector3.new(0.5, 8, 0.5), LampX = 14,
 FlowerCount = 36, FlowerSize = Vector3.new(1.2, 0.6, 1.2), FlowerX = 19, FlowerStep = 2,
 BarrelSize = Vector3.new(3, 4, 3), BarrelHoop = Vector3.new(0.25, 3.15, 3.15), BarrelHoopY = 1.2, BenchLeg = Vector3.new(0.7, 2, 2), BenchSize = Vector3.new(8, 1, 3), BenchBack = Vector3.new(8, 3, 0.6), BenchX = 22,
 SignSize = Vector3.new(0.5, 6, 16), SignOffset = Vector3.new(29, 5, 0), SignCanvas = Vector2.new(400, 150),
}
Theme.ShopStyle = { Robux = rgb(153, 62, 196), Coins = rgb(150, 111, 35), Rarity = { Default = "Estándar", Charcoal = "Estándar", Frost = "Estándar", Gold = "Épico", Cyber = "Legendario", Blood = "Legendario" }, GlowAlpha = 0.65 }

-- Utilidades de UI compartidas
Theme.CombatCamera = {
	FovKick = 4,
	FovDecay = 30,
	MaxFov = 120,
}

function Theme.corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or Theme.Sizes.Corner)
	c.Parent = obj
	return c
end

function Theme.stroke(obj, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.Gold
	s.Thickness = thickness or Theme.Sizes.Stroke
	s.Transparency = transparency or 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

-- Panel estándar: fondo oscuro + borde dorado envejecido
function Theme.panel(obj)
	obj.BackgroundColor3 = Theme.Colors.Panel
	obj.BorderSizePixel = 0
	Theme.corner(obj)
	Theme.stroke(obj)
	return obj
end

-- Constantes de geometria y composicion de las vistas; ajustes centralizados.
Theme.Metrics = {
 Zero = 0,
 Value_0_02 = 0.02,
 Value_0_06 = 0.06,
 Value_0_12 = 0.12,
 Value_0_15 = 0.15,
 Value_0_18 = 0.18,
 Value_0_2 = 0.2,
 Value_0_27 = 0.27,
 Value_0_29 = 0.29,
 Value_0_3 = 0.3,
 Value_0_35 = 0.35,
 Value_0_4 = 0.4,
 Value_0_42 = 0.42,
 Value_0_43 = 0.43,
 Half = 0.5,
 Value_0_53 = 0.53,
 Value_0_55 = 0.55,
 Value_0_6 = 0.6,
 Value_0_62 = 0.62,
 Value_0_7 = 0.7,
 Value_0_71 = 0.71,
 Value_0_72 = 0.72,
 Value_0_75 = 0.75,
 Value_0_85 = 0.85,
 One = 1,
 Two = 2,
 Three = 3,
 Value_3_4 = 3.4,
 Four = 4,
 Value_5 = 5,
 Value_6 = 6,
 Value_8 = 8,
 Value_10 = 10,
 Value_11 = 11,
 Value_12 = 12,
 Value_13 = 13,
 Value_14 = 14,
 Value_15 = 15,
 Value_16 = 16,
 Value_17 = 17,
 Value_18 = 18,
 Value_19 = 19,
 Value_20 = 20,
 Value_22 = 22,
 Value_24 = 24,
 Value_26 = 26,
 Value_28 = 28,
 Value_30 = 30,
 Value_32 = 32,
 Value_34 = 34,
 Value_36 = 36,
 Value_38 = 38,
 Value_40 = 40,
 Value_45 = 45,
 Value_46 = 46,
 Value_50 = 50,
 Value_56 = 56,
 Value_57 = 57,
 Value_60 = 60,
 Value_62 = 62,
 Value_70 = 70,
 Value_90 = 90,
 Value_94 = 94,
 Value_100 = 100,
 Value_120 = 120,
 Value_124 = 124,
 Value_160 = 160,
 Value_200 = 200,
 Value_212 = 212,
 Value_220 = 220,
 Value_500 = 500,
 Value_780 = 780,
 Value_1000 = 1000,
}

-- Lote 4 UI only. Numeric styling and drawn icon geometry belong here.
Theme.Armory = {
 Width = 1040, Height = 670, MobileWidth = 600, MobileHeight = 880,
 MobileAt = 740, Padding = 16, Duration = .22, Spin = .24, WideRatio = 1.6, -- vista ancha: arma acostada
 Background = Color3.fromRGB(25,29,35), Iron = Color3.fromRGB(53,59,66),
 Preview = Color3.fromRGB(76,84,96), Ambient = Color3.fromRGB(180,190,208),
 Light = Color3.fromRGB(255,239,213), Direction = Vector3.new(-1,-.5,-.8),
 Coins = Color3.fromRGB(208,177,104), Robux = Color3.fromRGB(145,210,195),
 Rarity = { Common = Color3.fromRGB(154,158,164), Rare = Color3.fromRGB(116,162,192), Epic = Color3.fromRGB(173,139,197), Legendary = Color3.fromRGB(211,178,104), Mythic = Color3.fromRGB(198,106,110) },
 HUDWidth = 205, HUDRow = 42, HUDY = .57, HUDMargin = 14, HUDScaleHeight = 600,
}
local A = Theme.Armory
function Theme.armoryText(parent, text, rect, title)
 local t = Instance.new("TextLabel") t.BackgroundTransparency = 1 t.Text = text
 t.Position = UDim2.fromOffset(rect[1],rect[2]) t.Size = UDim2.fromOffset(rect[3],rect[4])
 t.Font = title and Theme.Fonts.Title or Theme.Fonts.Body t.TextColor3 = Theme.Colors.Bone
 t.TextSize = title and 24 or 15 t.TextWrapped = true t.TextXAlignment = Enum.TextXAlignment.Left
 t.Parent = parent return t
end
function Theme.armoryButton(parent, text, rect)
 local b = Instance.new("TextButton") b.Text = text b.Position = UDim2.fromOffset(rect[1],rect[2]) b.Size = UDim2.fromOffset(rect[3],rect[4])
 b.Font = Theme.Fonts.Body b.TextSize = 14 b.TextWrapped = true b.TextColor3 = Theme.Colors.Bone
 b.BackgroundColor3 = A.Iron b.BorderSizePixel = 0 b.Selectable = true b.Parent = parent
 Theme.corner(b,4) Theme.stroke(b,Theme.Colors.Gold,1,.6)
 return b
end
-- Rectangular primitives; rotated squares make diamonds, rounded lobes make hearts/skulls.
function Theme.statusIcon(parent, kind, color)
 local root = Instance.new("Frame") root.Name = "StatusIcon" root.BackgroundTransparency = 1 root.Size = UDim2.fromOffset(28,28) root.Parent = parent
 local pieces, cracks = {}, {}
 local function piece(x,y,w,h,r,round,dark)
  local f = Instance.new("Frame") f.BorderSizePixel = 0 f.BackgroundColor3 = dark and A.Background or color
  f.AnchorPoint = Vector2.new(.5,.5) f.Position = UDim2.fromScale(x,y) f.Size = UDim2.fromScale(w,h) f.Rotation = r or 0 f.Parent = root
  if round then Theme.corner(f,28) end
  if not dark then table.insert(pieces,f) end return f
 end
 if kind == "health" then
  piece(.5,.58,.5,.5,45) piece(.32,.36,.43,.43,0,true) piece(.68,.36,.43,.43,0,true)
 elseif kind == "stamina" then
  for _,y in {.24,.5,.76} do piece(.36,y,.32,.09,30) piece(.64,y,.32,.09,-30) end
 elseif kind == "guard" then
  piece(.5,.39,.7,.56) piece(.5,.66,.48,.48,45)
  for i,p in {{.46,.33,.08,.32,25},{.55,.56,.08,.3,-30},{.43,.73,.07,.27,30}} do cracks[i]=piece(p[1],p[2],p[3],p[4],p[5],false,true) end
 elseif kind == "stun" then
  for _,p in {{.24,.5},{.73,.24},{.73,.77}} do piece(p[1],p[2],.12,.37) piece(p[1],p[2],.37,.12) piece(p[1],p[2],.2,.2,45) end
 elseif kind == "Fire" then
  piece(.5,.62,.6,.6,45,true) piece(.57,.27,.29,.56,25) piece(.37,.45,.25,.4,-25)
 elseif kind == "Ice" then
  piece(.5,.5,.4,.7,0) piece(.5,.19,.28,.28,45) piece(.5,.81,.28,.28,45)
  piece(.27,.55,.12,.45,-25) piece(.73,.55,.12,.45,25)
 elseif kind == "Lightning" then
  for _,x in {.24,.66} do piece(x,.3,.12,.45,28) piece(x+.05,.51,.29,.1) piece(x+.1,.71,.12,.4,28) end
 elseif kind == "Shadow" then
  for _,x in {.27,.74} do
   piece(x,.42,.42,.48,0,true) piece(x,.7,.28,.22)
   piece(x-.09,.43,.1,.12,0,true,true) piece(x+.09,.43,.1,.12,0,true,true)
   piece(x,.72,.045,.2,0,false,true)
  end
 end
 local function update(fraction, broken)
  for i,f in cracks do f.Visible = broken or fraction < (1-i*.25) end
  root.Rotation = broken and 14 or 0
  for _,f in pieces do
   f.BackgroundTransparency = (kind == "stun") and (1-fraction)*.7 or (broken and .5 or 0)
  end
 end
 update(1,false) return root,update
end

Theme.Armory.Values = {
 V0 = 5,
 V1 = 0.5,
 V2 = 14,
 V3 = 150,
 V4 = 44,
 V5 = 0,
 V6 = 3,
 V7 = 1,
 V8 = 2,
 V9 = 4,
 V10 = 30,
 V11 = 0.62,
 V12 = 15,
 V13 = 0.3,
 V14 = 0.08,
 V15 = 0.65,
 V16 = 1.45,
 V17 = 0.8,
 V18 = 0.1,
 V19 = 20,
 V20 = 440,
 V21 = 470,
 V22 = 400,
 V23 = 60,
 V24 = 80,
 V25 = 280,
 V26 = 240,
 V27 = 330,
 V28 = 32,
 V29 = 410,
 V30 = 190,
 V31 = 230,
 V32 = 16,
 V33 = 10,
 V34 = 48,
 V35 = 12,
 V36 = 62,
 V37 = 24,
 V38 = 90,
 V39 = 260,
 V40 = 70,
 V41 = 184,
 V42 = 64,
 V43 = 114,
 V44 = 42,
 V45 = 22,
 V46 = 11,
 V47 = 68,
 V48 = 25,
 V49 = 40,
 V50 = 8,
 V51 = 145,
 V52 = 38,
 V53 = 110,
 V54 = 56,
 V55 = 140,
 V56 = 36,
 V57 = 104,
 V58 = 6,
 V59 = 170,
 V60 = 200,
 V61 = 194,
 V62 = 106,
 V63 = 0.56,
 V64 = 28,
 V65 = 245,
 V66 = 18,
 V67 = 0.44,
 V68 = 76,
 V69 = 0.55,
 V70 = 58,
 V71 = 146,
 V72 = 100,
 V73 = 154,
 V74 = 19,
 V75 = 192,
 V76 = 52,
 V77 = 235,
 V78 = 215,
 V79 = 0.53,
 V80 = 0.012,
 V81 = 0.008,
 V82 = 0.6,
 V83 = 640,
 V84 = 650,
 V85 = 480,
 V86 = 520,
 V87 = 130,
 V88 = 155,
 V89 = 116,
 V90 = 254,
 V91 = 442,
 V92 = 156,
 V93 = 224,
 V94 = 188,
 V95 = 174,
 V96 = 536,
 V97 = 300,
 V98 = 532,
 V99 = 320,
 V100 = 50,
 V101 = 590,
 V102 = 600,
}
-- Ambiente dark fantasy en el cliente (Atmosphere.client): lluvia, viñeta, relámpagos, cuervos y cámara
Theme.Ambience = {
	Rain = { Rate = 900, Speed = 115, Area = 150, Height = 45, Size = 0.11, Stretch = -3, Color = rgb(176, 188, 210), Transparency = 0.55, Lifetime = 1.0 },
	Vignette = { Transparency = 0.5, Width = 0.22, Color = rgb(4, 4, 8) },
	Lightning = { MinGap = 22, MaxGap = 48, Flash = 0.32, Tint = rgb(210, 220, 255) },
	Crows = { Count = 7, Radius = 70, Height = 85, Speed = 0.25, Center = Vector3.new(-450, 50, 20) },
	CameraBob = { Amount = 0.06, Speed = 0.45 },          -- balanceo sutil de cámara en mano (studs)
	Intro = { Duration = 3.4, Height = 70, Back = 90 },     -- barrido sobre la ciudad al entrar al lobby
	-- Vacío de la arena: suelo del abismo con textura, mares de niebla, rocas que orbitan, ceniza y escombros
	Arena = {
		AbyssDepth = 260, AbyssSize = 1600, AbyssColor = rgb(24, 26, 34), CrackColor = rgb(96, 74, 150), Cracks = 14,
		MistLayers = { -70, -115, -165 }, MistColor = rgb(120, 128, 152), MistRate = 6,
		Rocks = 14, RockOrbit = { 40, 170 }, RockHeight = { -70, 35 }, RockSpeed = 0.02,
		AshRate = 30, DebrisEvery = { 3, 6 },
		-- desenfoque del fondo solo en partida
		DOF = { FocusDistance = 30, InFocusRadius = 95, FarIntensity = 0.4, NearIntensity = 0 },
	},
}

return Theme