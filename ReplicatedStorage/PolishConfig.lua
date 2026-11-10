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
  InfusionIcon = { Size = 28, ActiveAmp = 0.14, ActiveSpeed = 9, FullAmp = 0.06, FullSpeed = 4, ActiveWobble = 40, ExhaustTilt = 14 } },
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
  IdleTransparency = 0.5, StanceTransparency = 0.05, GuardGlow = 2.5,
  Idle = Color3.fromRGB(235, 228, 214), Stance = Color3.fromRGB(255, 255, 255), Guard = Color3.fromRGB(150, 205, 255),
  Attack = Color3.fromRGB(255, 40, 32), Unblockable = Color3.fromRGB(255, 196, 64), Kick = Color3.fromRGB(255, 140, 30),
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
}
