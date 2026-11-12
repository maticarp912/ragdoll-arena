-- Geometría, ambiente y calendario de la arena (Ronda 5: Templo dorado, arenas iluminadas en partida y rotación de 3 variantes).
return {
	Variants = { "Forest", "Canyon", "Temple" },

	Scenery = {
		Count = 24,
		Tiers = 5,
		Radius = 1.55,
		WallRadius = 2.65,
		Depth = 64,
		HazardDepth = 36,
		SurfaceDepth = 58,
		AbyssDepth = 66,
		EdgeInset = 0.08,
		SupportDepth = 9,
		Budget = 2500,

		-- Paleta general de materiales y piedra
		Stone = Color3.fromRGB(98, 106, 98),
		StoneDark = Color3.fromRGB(64, 70, 66),
		StoneLight = Color3.fromRGB(126, 132, 122),
		Moss = Color3.fromRGB(68, 112, 54),
		MossBright = Color3.fromRGB(86, 134, 64),
		Sand = Color3.fromRGB(168, 108, 74),
		SandLight = Color3.fromRGB(204, 146, 102),
		SandDark = Color3.fromRGB(112, 70, 50),
		CanopyCloth = Color3.fromRGB(214, 186, 142),
		IronDark = Color3.fromRGB(54, 48, 46),
		-- Oro cálido y brillante para el Templo (estilo arena 3.jpg, sin verde lima)
		Gold = Color3.fromRGB(240, 185, 80),
		GoldBright = Color3.fromRGB(255, 205, 95),
		GoldDark = Color3.fromRGB(180, 135, 50),
		TempleWall = Color3.fromRGB(34, 30, 26),
		TempleColumn = Color3.fromRGB(48, 40, 32),
		Water = Color3.fromRGB(20, 48, 52),
		WaterDeep = Color3.fromRGB(10, 22, 28),
		Waterfall = Color3.fromRGB(185, 225, 230),
		Foam = Color3.fromRGB(230, 245, 248),
		Sunbeam = Color3.fromRGB(255, 235, 175),
		-- Suelos claros para lectura óptima desde la cámara de combate
		Floor = Color3.fromRGB(176, 180, 178),
		FloorAlt = Color3.fromRGB(156, 160, 158),

		-- Tamaños base de referencia
		ColumnSize = Vector3.new(13, 132, 13),
		CapSize = Vector3.new(24, 4, 24),
		GlyphSize = Vector3.new(0.8, 2.2, 0.8),
		FingerSize = Vector3.new(14, 32, 16),
		WaterfallSize = Vector3.new(18, 175, 3),
		SpikeSize = Vector3.new(6, 28, 6),

		-- Flujo de cascadas y corrección de color por variante
		FlowRate = 8,
		FlowLife = NumberRange.new(1.4, 2.4),
		FlowSpeed = NumberRange.new(18, 28),
		FlowSize = NumberSequence.new(3.5, 7.5),
		Exposure = 0.20,
		AmbientTint = Color3.fromRGB(245, 242, 238),

		VariantAmbience = {
			Forest = {
				Brightness = 0.24,
				Contrast = 0.08,
				Saturation = 0.12,
				Tint = Color3.fromRGB(255, 240, 230),
				MistColor = Color3.fromRGB(60, 48, 56),
			},
			Canyon = {
				Brightness = 0.20,
				Contrast = 0.10,
				Saturation = 0.10,
				Tint = Color3.fromRGB(255, 242, 224),
				MistColor = Color3.fromRGB(162, 118, 88),
			},
			Temple = {
				Brightness = 0.22,
				Contrast = 0.10,
				Saturation = 0.10,
				Tint = Color3.fromRGB(255, 246, 228),
				MistColor = Color3.fromRGB(68, 56, 44),
			},
			Hand = {
				Brightness = 0.24,
				Contrast = 0.08,
				Saturation = 0.10,
				Tint = Color3.fromRGB(238, 250, 244),
				MistColor = Color3.fromRGB(145, 185, 182),
			},
		},

		-- Efecto de desenfoque y fundido de cámara al caer al vacío
		FallBlurMax = 28,
		FallBrightnessMin = -0.68,
		FallContrastMax = 0.28,
		FallStartDrop = 2.5,
	},

	TipRadius = 0.65,
	BaseLayers = 12,
	BaseDepth = 65,
	BaseInset = 0.92,
	SilhouetteTrees = 32,
	TreeSize = Vector3.new(12, 58, 12),
	TreeCrown = Vector3.new(38, 62, 38),
	TreeColor = Color3.fromRGB(18, 30, 40),
	BackgroundDepth = 85,
	SoundVolume = 1,

	Match = {
		RoundsToWin = 2,
		MaxRounds = 5,
		RoundTime = 180,
		Overtime = 60, -- 12/11/2026: si se acaba el tiempo con gente viva, 60 s más; después gana el equipo con más vida
		Countdown = 3,
		WinCoins = 50,
		LoseCoins = 15,
		Wait1v1 = 12,
		VoidDrop = 18,
	},

	-- Arenas separadas a miles de studs entre sí y respecto a la ciudad (0, 0, 0)
	Modes = {
		["2v2"] = { perTeam = 2, radius = 100, rings = 5, sectors = 16, center = Vector3.new(4500, 260, 0), crumbleStart = 30, crumbleInterval = 2 },
		["1v1"] = { perTeam = 1, radius = 45, rings = 3, sectors = 12, center = Vector3.new(-4500, 260, 0), crumbleStart = 30, crumbleInterval = 4 },
	},

	Thickness = 3,
	Gap = 0.12,
	CoreFraction = 0.22,
	SpawnFraction = 0.62,
	SpawnLane = 0.18,
	SpawnHeight = 5,

	WarningTime = 1.3,
	WarningStep = 0.08,
	Tremor = 0.12,
	FallLife = 4,
	Spin = Vector3.new(2, 1, 3),
	WarningLight = 3,
	WarningRange = 20,

	ChainCount = 4,
	ChainHeight = 100,
	LinkStep = 5,
	LinkRadius = 2.8,
	LinkThickness = 0.7,
	LinkSegments = 8,
	RingRadius = 5,

	LavaDepth = 110,
	LavaSize = 650,
	LavaThickness = 4,
	Lava = Color3.fromRGB(255, 85, 12),
	Basalt = Color3.fromRGB(32, 24, 36),
	Chain = Color3.fromRGB(56, 44, 52),

	CrustCount = 24,
	CrustSize = 22,
	MountainCount = 16,
	MountainDistance = 240,
	MountainSize = Vector3.new(85, 160, 85),
	CrackSize = Vector3.new(2, 100, 3),

	RockCount = 8,
	RockHeight = 45,
	RockSize = Vector3.new(8, 5, 7),
	RockBob = 2,
	RockSpeed = 0.6,
	RockRoll = 0.08,

	EmberRate = 30,
	EmberSpeed = NumberRange.new(8, 18),
	EmberLife = NumberRange.new(4, 8),
	EmberSize = NumberSequence.new(0.4, 0),
	DustCount = 25,

	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	DustTexture = "rbxasset://textures/particles/smoke_main.dds",
	CollapseSound = "Tile_Crumble",
}

