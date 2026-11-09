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
	Width = { 12, 20 }, Height = { 22, 44 },
	FloorHeight = 7, WindowSize = Vector3.new(2.2, 3.4, 0.3), WindowSpacing = 5,
	LitChance = 0.35, PitchedChance = 0.55, ChimneyChance = 0.5,
}
CityConfig.Lamp = { Spacing = 18, Range = 24, Brightness = 2.1, Height = 10 } -- 9/11: antes Range 26, Brightness 2.6
CityConfig.WallHeight = 90       -- muros invisibles
CityConfig.AntechamberWall = 34  -- muros de piedra de la antesala

CityConfig.Colors = {
	Cobble = rgb(96, 98, 108), Street = rgb(78, 80, 90), Plaza = rgb(104, 104, 112),
	Bricks = { rgb(74, 50, 44), rgb(60, 54, 58), rgb(70, 64, 60), rgb(52, 50, 60), rgb(82, 60, 50) },
	Trim = rgb(150, 146, 140), Roof = rgb(40, 42, 50), Iron = rgb(28, 28, 32),
	Window = rgb(226, 146, 74), WindowDark = rgb(34, 40, 52), Lamp = rgb(255, 196, 120), -- 9/11: ventanas ámbar (antes 255,196,110: se veían blancas con el bloom)
	Stone = rgb(112, 110, 116), DarkStone = rgb(70, 70, 78), Grass = rgb(42, 54, 46),
	Skyline = rgb(26, 28, 36), LightShaft = rgb(235, 238, 255), Clock = rgb(230, 225, 200),
}

-- Orientación hacia la arena y armería (tienda) en la plaza
CityConfig.Guide = { Color = rgb(235, 200, 120), Transparency = 0.35, ArrowSpacing = 22, BeaconHeight = 140 }
CityConfig.Shop = { Position = Vector3.new(-26, 0, -60) }

CityConfig.Seed = 1888

return CityConfig
