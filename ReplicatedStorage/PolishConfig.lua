-- Parámetros visuales compartidos; la lógica no contiene ajustes de balance.
return {
 Shop = { TabWidth = 100, TabLeft = 230, TabStep = 106, CardWidth = 355, CardHeight = 400, WeaponWidth = 232, WeaponHeight = 360, SkinWidth = 232, SkinHeight = 360, PreviewHeight = 200, PreviewInset = 6, RarityHeight = 22, NameTop = 226, DetailTop = 250, DetailHeight = 34, PriceTop = 284, PreviewFov = 30, PreviewFit = 0.62, PreviewPad = 1, PreviewSpin = 0.45, MinScale = 0.2, ViewWidth = 820, ViewHeight = 560, GridGap = 10, TextSize = 14, Padding = 12, Footer = 44, ButtonHeight = 32, CoinsBottom = 30, CoinsRight = 18, MessageWidth = 0.65 },
 Aura = { Rate = 18, Burst = 28, Life = NumberRange.new(0.25, 0.65), Speed = NumberRange.new(1, 4), Size = NumberSequence.new(0.65, 0), Light = 1.5, Range = 10, Curve = 2.5, BeamWidth = 0.09, Update = 0.1, Feet = Vector3.new(0, -2.6, 0), Spread = Vector2.new(180, 180), FreezeAlpha = 0.65, MaxBladeEmitters = 4,
 Profiles = {
 Fire = { Acceleration = Vector3.new(0, 8, 0), Drag = 1, Size = NumberSequence.new(0.8, 0), Speed = NumberRange.new(2, 5) },
 Lightning = { Acceleration = Vector3.zero, Drag = 4, Size = NumberSequence.new(0.2, 0), Speed = NumberRange.new(5, 12) },
 Ice = { Acceleration = Vector3.new(0, -2, 0), Drag = 3, Size = NumberSequence.new(0.5, 0.1), Speed = NumberRange.new(1, 3) },
 Shadow = { Acceleration = Vector3.new(0, 3, 0), Drag = 2, Size = NumberSequence.new(0.5, 1.2), Speed = NumberRange.new(1, 2) },
 },
 Textures = { Fire = "rbxasset://textures/particles/fire_main.dds", Lightning = "rbxasset://textures/particles/sparkles_main.dds", Ice = "rbxasset://textures/particles/smoke_main.dds", Shadow = "rbxasset://textures/particles/smoke_main.dds" }, Crystal = "rbxasset://textures/particles/sparkles_main.dds" },
 HUD = { DamageDelay = 0.4, DamageTime = 0.65, Top = 0.06, Side = 0.025, Width = 0.34, Height = 80, Portrait = 54, PortraitAngle = 45, BarAngle = -2, NameHeight = 24, BarTop = 35, BarHeight = 16, EnemyStep = 92, Opponents = 2, Max = 100, ScaleWidth = 1100, ScaleMin = 0.5, BottomWidth = 440, StatusWidth = 0.24, StatusHeight = 0.045, NameSize = 16,
  -- icono de infusión: latido activa / carga llena, ladeo agotada
  -- 12/11/2026: barras de arte (UiAssets.BarArt, solo la infusión) y disposición del HUD propio (px, sin escalar)
  ArtBars = { EmptyTransparency = 0.18, LostTransparency = 0.45 },
  Bars = { TopWidth = 420, TopHeight = 130, HealthY = 0, HealthWidth = 360, WeaponWidth = 120, BarsX = 72,
   InfusionY = 76, InfusionWidth = 210, InfusionHeight = 9, InfusionIcon = 22, InfusionCaption = 130,
   UltiColor = Color3.fromRGB(255, 214, 64), ShadowTintLift = 0.35,
   StaminaY = 98, StaminaWidth = 230, StaminaHeight = 8, StaminaCaption = 120, RivalWidth = 300, HealthHeight = 18,
   StunWidth = 260, StunHeight = 8, GuardY = 26, GuardWidth = 440, GuardHeight = 14, Shield = 34 },
  InfusionIcon = { Size = 28, ActiveAmp = 0.14, ActiveSpeed = 9, FullAmp = 0.06, FullSpeed = 4, ActiveWobble = 40, ExhaustTilt = 14 } },
 -- 12/11/2026: menú inicial (MainMenu.client): escena del caballero, opciones y despertar
 MainMenu = {
  Seed = 77, Origin = Vector3.new(0, 1400, -7000), HillRadius = 220, Rocks = 7, RockSpread = 170, RockDistance = 150,
  RockHeight = { Min = 8, Max = 22 }, Flowers = 260, FlowerSpread = 60, OrangeShare = 0.55,
  Stars = 420, SkyYaw = 75, SkyPitch = { Min = 8, Max = 70 }, SkyRadius = 260, StarSize = { Min = 0.5, Max = 1.6 }, TwinklePerFrame = 4,
  MoonYaw = -8, MoonPitch = 34, MoonSize = 9,
  Grass = Color3.fromRGB(46, 112, 66), FarGrass = Color3.fromRGB(12, 26, 22), Rock = Color3.fromRGB(20, 26, 40),
  Orange = Color3.fromRGB(255, 96, 24), Blue = Color3.fromRGB(110, 180, 255), Star = Color3.fromRGB(255, 186, 74),
  Moon = Color3.fromRGB(205, 225, 255), WarmLight = Color3.fromRGB(255, 170, 110), WarmRange = 70, WarmBrightness = 2.2,
  LightOffset = Vector3.new(4, 14, 6),
  SwordSkin = "CrimsonEclipse", SwordScale = 2.6, SwordOffset = Vector3.new(4, 2, -2), SwordTilt = -12, SwordLean = 6, SwordBuried = 0.22,
  CameraOffset = Vector3.new(-2, 7, 24), CameraLook = Vector3.new(2, 13, -12), CameraDrift = 0.8, FieldOfView = 60,
  TitleColor = Color3.fromRGB(242, 230, 190), OptionColor = Color3.fromRGB(226, 218, 196), OptionHover = Color3.fromRGB(255, 196, 92),
  OptionSize = 34, OptionHeight = 48, OptionStep = 62,
  SettleTime = 0.6, LieHeight = 0.7, SitHeight = 2.3, EyeHeight = 4.6, ThirdUp = 1.6, ThirdBack = 11, ThirdSide = 1.5,
  LieTime = 1.2, SitTime = 1.4, StandTime = 1.8, BlurStart = 22,
 },
 -- 12/11/2026: ayuda de botones abajo a los costados (ControlHints.client), solo PC y mando
 ControlHints = { Margin = 12, Bottom = 10, Width = 420, Gap = 4, RowHeight = 26, RowTransparency = 0.25, ChipHeight = 20,
  ChipColor = Color3.fromRGB(236, 238, 242), ChipText = Color3.fromRGB(16, 18, 24), ChipTextSize = 13, TextSize = 16 },
 -- 12/11/2026: contorno de equipo en partida (TeamOutline.client)
 TeamOutline = { Ally = Color3.fromRGB(70, 150, 255), Enemy = Color3.fromRGB(235, 50, 50), Transparency = 0.1, Interval = 0.25 },
 MobileHUD = {
  Margin = 8, QueueHeight = 54, QueueBottom = 12, Gap = 10,
  BarsWidth = 460, BarsHeight = 60, BarsWidthShare = 0.55, BarsMinHeightShare = 0.26, TouchBarsCenter = 0.38,
  PadWidthShare = 0.43, PadHeightShare = 0.78, PadMaxScale = 1.18, PadEdge = 16,
 },
 Camera = { Frequency = 24, SeedX = 11, SeedY = 37, SeedRoll = 71, BounceStart = 0.35, BounceTime = 0.22 },
 Impact = { Life = 0.1, SlashLife = 0.18, SlashSize = Vector3.new(0.08, 0.12, 5), SlashAngle = 35, SlashYaw = 90, White = Color3.new(1, 1, 1) },
 Walk = { Phase = 0.5, MaxStep = 4, Speed = 16, Hip = 34, Knee = 52, Ankle = 18, Side = 22, Arm = 22, Bob = 0.13, AirArms = 110, AirWave = 18, AirFrequency = 9 },
 -- Aviso de ataque fuerte (etapa 8): punto rojo en la punta del arma, sin teñir el arma.
 --   Fuerte: punto rojo + anillo rojo que se cierra. Imbloqueable: centro blanco incandescente que late,
 --   halo rojo y doble anillo dorado. Al llegar el golpe, el punto destella y se apaga.
 Telegraph = {
  HeavyCore = Color3.fromRGB(255, 46, 38), HeavyHalo = Color3.fromRGB(255, 30, 24), HeavyRing = Color3.fromRGB(255, 52, 40),
  UnblockableCore = Color3.fromRGB(255, 244, 228), UnblockableHalo = Color3.fromRGB(255, 26, 26), UnblockableRing = Color3.fromRGB(255, 196, 64),
  Canvas = 96, Dot = 0.2, Halo = 0.48, HaloTransparency = 0.55, DotGrow = 1.45, Ring = 1, RingEnd = 0.2, RingThickness = 3,
  Pulse = 10, PulseAmp = 0.18, FlashScale = 2.4, FlashTime = 0.16,
  LightRange = 6, LightBrightness = 2.5,
 },
 -- 0.2 (Claude): triángulo del combate direccional (DirectionalHUD.client). Tamaños en píxeles, tiempos en s.
 Directional = {
  -- Integración 0.2: en Studio a 92 px y 0,72 de transparencia casi no se veía; más grande y más opaco
  Side = 140, Thickness = 10, Gap = 8, OffsetY = -10, Edge = 80,
  IdleTransparency = 0.4, StanceTransparency = 0.05, GuardGlow = 2.5,
  -- 12/11/2026: estética de plata (antes Idle era crema 235, 228, 214)
  Idle = Color3.fromRGB(196, 202, 214), Stance = Color3.fromRGB(255, 255, 255),
  SilverSheen = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
   ColorSequenceKeypoint.new(0.45, Color3.fromRGB(170, 175, 188)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(225, 229, 238)),
   ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 124, 138)) }),
  Rim = Color3.fromRGB(16, 18, 24), RimWidth = 2, RimTransparency = 0.35, Vertex = 13, VertexColor = Color3.fromRGB(214, 219, 230), Guard = Color3.fromRGB(150, 205, 255),
  Committed = Color3.fromRGB(155, 201, 224), Attack = Color3.fromRGB(255, 40, 32), Unblockable = Color3.fromRGB(255, 196, 64), Kick = Color3.fromRGB(255, 140, 30),
  Parry = Color3.fromRGB(255, 226, 120), ParryTime = 0.35, ParryScale = 1.35,
  Pulse = 14, PulseAmp = 0.25, OtherAttackers = 14, KickDot = 16,
 },
 -- 0.2 (Claude): sensación del combate (C23). Lo usa Vfx.client con el evento Effect "Feel".
 Feel = {
  Deal = { Sound = "Hit_Blunt", Volume = 0.3, Pitch = 0.82, Punch = 0.2 },
  Take = { Sound = "Hit_Heavy", Volume = 0.45, Pitch = 0.78, Edge = 0.55, EdgeTime = 0.35, Punch = 0.45 },
  Block = { Sound = "BlockHit_Light", Volume = 0.5, Pitch = 1.18, Edge = 0.25, EdgeTime = 0.18 },
  Blocked = { Sound = "BlockHit_Light", Volume = 0.3, Pitch = 0.9 },
  Parry = { Sound = "ParrySpark", Volume = 0.6, Pitch = 1.1, SlowScale = 0.3, SlowTime = 0.22, SlowRadius = 30 },
  Parried = { Sound = "Parry", Volume = 0.35, Pitch = 0.8, Edge = 0.4, EdgeTime = 0.3 },
  GuardBreak = { Sound = "GuardBreak", Volume = 0.4, Pitch = 1.0, SlowScale = 0.35, SlowTime = 0.2, SlowRadius = 30 },
  GuardBroken = { Sound = "GuardBreak", Volume = 0.45, Pitch = 0.85, Edge = 0.5, EdgeTime = 0.4 },
  Finisher = { VolumeMult = 1.4, EdgeMult = 1.3 },
  TakeColor = Color3.fromRGB(150, 0, 12), BlockColor = Color3.fromRGB(200, 200, 215),
  ParriedColor = Color3.fromRGB(255, 70, 40), GuardBrokenColor = Color3.fromRGB(255, 120, 40),
 },
 -- 0.2 (Claude): respaldo de colores de rol para la etiqueta sobre la cabeza (manda ReplicatedStorage.Roles de Codex)
 Roles = { Colors = {
  Owner = Color3.fromRGB(255, 196, 64), Admin = Color3.fromRGB(255, 80, 70), Mod = Color3.fromRGB(90, 170, 255),
  Tester = Color3.fromRGB(120, 230, 140), VIP = Color3.fromRGB(220, 130, 255), New = Color3.fromRGB(200, 200, 200),
 } },
 -- 0.2 ronda 2 (Claude): cámara de la cinemática antes del combate (Cinematic.client, D16, C17)
 Cinematic = {
  MinTime = 1.5,           -- si PhaseEnds deja menos que esto, no se arma la cinemática (fase de bloqueo sin duración)
  Shots = { 0.36, 0.32, 0.32 }, -- fracción del tiempo: vista general, tu equipo, rivales
  OrbitRadius = 34, OrbitMin = 26, OrbitHeight = 16, OrbitTurn = 50, -- grados que gira la vista general
  CloseDistance = 7.5, CloseEnd = 5.2, CloseHeight = 1.6, CloseSide = 2.2, LookHeight = 1.3,
  Fov = 55, FovClose = 42,
  CueEnter = 0.24, CueHold = 0.55, CueExit = 0.33,
  Bars = 0.09, BarsTime = 0.35, -- franjas negras de cine (fracción de la altura de pantalla)
  Range = 260,             -- solo cuenta luchadores a esta distancia (otra partida en otra arena no entra)
 },
 -- 0.2 ronda 2 (Claude): almas que se absorben al ganar (D5) y subida de nivel. Lo usa Vfx.client.
 Souls = { PerWisp = 10, MinWisps = 3, MaxWisps = 14, Radius = 7, Height = 3.5, Stagger = 0.06, Travel = 0.55,
  Size = 0.45, Color = Color3.fromRGB(170, 230, 255), Core = Color3.fromRGB(255, 255, 255), Sound = "UI_CoinGain", Volume = 0.45 },
 LevelUp = { RingSize = 12, RingTime = 0.7, PillarHeight = 22, PillarTime = 0.9, Color = Color3.fromRGB(255, 205, 90),
  Sound = "Match_Win", Volume = 0.5 },
 -- 0.2 ronda 2 (Claude): tutorial de 3 pasos en el patio (Tutorial.client)
 Tutorial = { DummyRange = 45, MaxMatches = 0, Width = 340, RowHeight = 24, Top = 0.16, DoneHold = 4, Check = Color3.fromRGB(120, 230, 140) },
}
