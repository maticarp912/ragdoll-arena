-- ModuleScript: ReplicatedStorage/CityConfig
-- Datos de la ciudad del lobby (gótica victoriana, de noche y con lluvia). Lo usa LobbyBuilder.
-- Coordenadas en studs RELATIVAS al centro (X = este, Z = norte). Rectángulos = { x0, x1, z0, z1 }.

local rgb = Color3.fromRGB

local CityConfig = {}

CityConfig.Center = Vector3.new(-450, 50, 0) -- lejos de las arenas (0,100,0) y (450,100,0)

-- Zonas por donde se camina (calles, plaza, patios, antesala)
-- Separación de altura entre zonas de piso superpuestas (evita el parpadeo por z-fighting)
CityConfig.FloorLayerStep = 0.06

CityConfig.Walkable = {
	MainStreet = { -12, 12, -120, 150 },
	Plaza = { -36, 36, -70, -10 },
	CrossStreet = { -100, 100, -50, -30 },
	Practice = { 60, 100, -78, -2 },
	Cemetery = { -100, -60, -78, -2 },
	Antechamber = { -35, 35, 150, 214 },
}

-- Manzanas: se llenan de edificios altos (bloquean el paso y la vista)
CityConfig.Blocks = {
	{ 12, 100, -2, 150 }, { -100, -12, -2, 150 },
	{ 36, 60, -30, -2 }, { -60, -36, -30, -2 },
	{ 36, 60, -78, -50 }, { -60, -36, -78, -50 },
	{ 12, 100, -120, -78 }, { -100, -12, -120, -78 },
	{ 12, 36, -78, -70 }, { -36, -12, -78, -70 },
	-- cierres: que ninguna calle termine mirando al vacío
	{ -12, 12, -136, -122 }, { 100, 116, -80, 0 }, { -116, -100, -80, 0 },
}

-- Siluetas de fondo (no se pueden pisar): esconden el vacío y la arena
CityConfig.Skyline = { InnerRadius = 210, OuterRadius = 390, Count = 64, Height = { 40, 110 }, Width = { 18, 40 } }

CityConfig.Spawn = Vector3.new(0, 5, -100)          -- mira al norte, hacia la puerta
CityConfig.DummyHomes = { Vector3.new(88, 4, -60), Vector3.new(88, 4, -40), Vector3.new(88, 4, -20) }
CityConfig.QueueZones = {
	["1v1"] = { center = Vector3.new(-14, 1, 192), radius = 7, color = rgb(220, 170, 80) },
	["2v2"] = { center = Vector3.new(14, 1, 192), radius = 8, color = rgb(120, 140, 230) },
}

CityConfig.Building = {
	Width = { 13, 19.5 }, Height = { 21, 42 },
	FloorHeight = 7.4, GroundFloorHeight = 8.2,
	WindowSize = Vector3.new(2.2, 3.3, 0.24), WindowSpacing = 5.2,
	LitChance = 0.48, PitchedChance = 0.86, ChimneyChance = 0.62,
	DormerChance = 0.52, BalconyChance = 0.38, ShutterChance = 0.58,
	PlanterChance = 0.46, LanternChance = 0.64,
	JettyDepth = 0.65, EaveOverhang = 1.35, MaxWallLights = 10,
}
CityConfig.Lamp = { Spacing = 18, Range = 24, Brightness = 2.1, Height = 10 } -- 9/11: antes Range 26, Brightness 2.6
CityConfig.WallHeight = 90       -- muros invisibles
CityConfig.AntechamberWall = 34  -- muros de piedra de la antesala

CityConfig.Colors = {
	Cobble = rgb(96, 98, 108), Street = rgb(78, 80, 90), Plaza = rgb(104, 104, 112),
	Bricks = { rgb(74, 50, 44), rgb(60, 54, 58), rgb(70, 64, 60), rgb(52, 50, 60), rgb(82, 60, 50) },
	Plaster = {
		rgb(153, 149, 137), -- cal envejecida
		rgb(174, 156, 132), -- ocre arena suave
		rgb(166, 164, 154), -- caliza ceniza clara
		rgb(170, 152, 144), -- arcilla rosada vieja
		rgb(154, 162, 152), -- salvia pálido nocturno
		rgb(147, 145, 134), -- revoque gris cálido
	},
	Timber = {
		rgb(52, 36, 28),    -- roble oscuro
		rgb(64, 43, 32),    -- nogal tostado
		rgb(42, 30, 24),    -- viga ahumada
	},
	BaseStone = {
		rgb(88, 86, 96),    -- piedra gris azulada
		rgb(96, 90, 86),    -- mampostería cálida
		rgb(78, 82, 88),    -- pizarra musgosa
		rgb(84, 78, 86),    -- granito sombrío
	},
	RoofTiles = {
		rgb(38, 40, 54),    -- pizarra azul noche
		rgb(48, 38, 50),    -- pizarra ciruela oscura
		rgb(48, 36, 32),    -- teja de madera antigua
		rgb(34, 42, 48),    -- pizarra verdosa oscura
	},
	Shutter = {
		rgb(58, 42, 32),    -- postigo de roble
		rgb(44, 56, 52),    -- verde bosque apagado
		rgb(62, 40, 46),    -- borgoña nocturno
	},
	DoorWood = rgb(50, 33, 24),
	PlanterWood = rgb(60, 40, 28),
	PlanterFoliage = rgb(44, 68, 50),
	PlanterFlowers = { rgb(148, 96, 178), rgb(174, 112, 190), rgb(114, 100, 186), rgb(212, 142, 84) },
	Trim = rgb(150, 146, 140), Roof = rgb(40, 42, 50), Iron = rgb(28, 28, 32),
	Window = rgb(226, 146, 74), WindowDark = rgb(34, 40, 52), Lamp = rgb(255, 196, 120), -- 9/11: ventanas ámbar (antes 255,196,110: se veían blancas con el bloom)
	Stone = rgb(112, 110, 116), DarkStone = rgb(70, 70, 78), Grass = rgb(42, 54, 46),
	Skyline = rgb(26, 28, 36), LightShaft = rgb(235, 238, 255), Clock = rgb(230, 225, 200),
}

-- Orientación hacia la arena y armería (tienda) en la plaza
CityConfig.Guide = { Color = rgb(235, 200, 120), Transparency = 0.35, ArrowSpacing = 22, BeaconHeight = 140 }
CityConfig.Shop = { Position = Vector3.new(-26, 0, -60) }

CityConfig.PlazaFinish = {
	Stalls = { Vector3.new(-26, 0, -63), Vector3.new(26, 0, -63) },
	Canvas = { rgb(88, 79, 75), rgb(59, 71, 78) },
	CanvasHem = rgb(143, 134, 117),
	Paving = { rgb(91, 96, 103), rgb(106, 110, 115), rgb(118, 118, 113) },
	PavingRadius = 9, PavingSegments = 26,
}

CityConfig.Seed = 1888

-- 12/11/2026 (pedido del usuario): el centro del lobby iluminado y el resto de las luces de la ciudad 40 % más tenues
CityConfig.LobbyLight = { OthersScale = 0.6, Height = 14, Range = 60, Brightness = 2.6, Color = Color3.fromRGB(255, 214, 160) }

-- 12/11/2026: patio del tutorial guiado (TutorialService + GuidedTutorial.client). Lejos de la ciudad, flotando.
CityConfig.GuidedTutorial = {
	Origin = Vector3.new(-450, 300, 900), YardSpacing = 2048, YardColumns = 6,
	Size = 90, WallHeight = 3, PillarHeight = 12,
	Floor = Color3.fromRGB(86, 88, 96), Wall = Color3.fromRGB(58, 60, 68), Torch = Color3.fromRGB(255, 170, 80),
	TorchRange = 22, TorchBrightness = 1.6, Marker = Color3.fromRGB(120, 200, 255), MarkerSize = 9,
	SpawnOffset = Vector3.new(0, 3, 32), MarkerOffset = Vector3.new(0, 0.2, 14),
	DummyOffsets = { Vector3.new(-9, 3, -6), Vector3.new(9, 3, -6) }, BotOffset = Vector3.new(0, 3, -24),
	Steps = { "move", "armory", "lock", "switch", "light", "dirs", "heavy", "combo", "dodge", "down", "carry", "throw", "block", "parry", "infuse", "done" },
	MinHealth = 0.3, RefillHealth = 0.7, FallLimit = 40,
	MarkerReach = 6, ComboWindow = 3, LightHits = 2, BlocksNeeded = 2,
}

return CityConfig
