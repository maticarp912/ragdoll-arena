-- Cosmetic catalogue and all effect tuning. Product IDs remain zero until published.
-- 9/11 (pedido del usuario): colores saturados y propios de cada aura, más partículas, más brillo.
local A = {}
A.Order = { "AshCrown", "SpectralChains", "SmokeWings", "FootShroud", "WatchingEyes", "GraveRunes", "WeepingBlade", "BlackEmbers", "BloodOath", "PaleFracture" }
A.Data = {
 AshCrown = { kind = "Body", rarity = "Rare", currency = "Coins", price = 1800, pattern = "crown", color = Color3.fromRGB(255,150,60) },
 SpectralChains = { kind = "Body", rarity = "Epic", currency = "Coins", price = 3900, pattern = "chains", color = Color3.fromRGB(90,220,255) },
 SmokeWings = { kind = "Body", rarity = "Legendary", currency = "Coins", price = 8000, pattern = "wings", color = Color3.fromRGB(170,90,255) },
 FootShroud = { kind = "Body", rarity = "Rare", currency = "Coins", price = 1500, pattern = "mist", color = Color3.fromRGB(110,255,170) },
 WatchingEyes = { kind = "Body", rarity = "Legendary", currency = "Coins", price = 8500, productId = 0, pattern = "eyes", color = Color3.fromRGB(255,60,70) },
 GraveRunes = { kind = "Body", rarity = "Epic", currency = "Coins", price = 4200, pattern = "runes", color = Color3.fromRGB(255,205,90) },
 WeepingBlade = { kind = "Weapon", rarity = "Rare", currency = "Coins", price = 2100, pattern = "drip", color = Color3.fromRGB(150,80,220) },
 BlackEmbers = { kind = "Weapon", rarity = "Epic", currency = "Coins", price = 3600, pattern = "embers", color = Color3.fromRGB(255,90,40) },
 BloodOath = { kind = "Weapon", rarity = "Epic", currency = "Coins", price = 4800, pattern = "blood", color = Color3.fromRGB(225,25,45) },
 PaleFracture = { kind = "Weapon", rarity = "Legendary", currency = "Coins", price = 7800, productId = 0, pattern = "fracture", color = Color3.fromRGB(200,235,255) },
}
for id, data in A.Data do data.nameKey = "cx.aura." .. id data.descKey = data.nameKey .. ".desc" data.productId = data.productId or 0 end
A.Fx = {
 Zero = 0, One = 1, Two = 2, Half = 0.5, Quarter = 0.25,
 HolderSize = Vector3.new(0.05,0.05,0.05), BodyRate = 26, WeaponRate = 18, -- Claude 9/11: más presencia (antes 12 / 8, luego 18 / 12)
 BodyTelegraph = 0.5, WeaponTelegraph = 0.25, OtherMatch = 0.6, Simplified = 0.2,
 SmokeTexture = "rbxasset://textures/particles/smoke_main.dds", SparkTexture = "rbxasset://textures/particles/sparkles_main.dds",
 Life = NumberRange.new(0.35,0.8), Speed = NumberRange.new(0.15,0.5), DownSpeed = NumberRange.new(0.5,1.2),
 Size = NumberSequence.new(0.95,0), MistSize = NumberSequence.new(1.5,2.4), BloodSize = NumberSequence.new(0.12,0),
 Spread = Vector2.new(18,18), Rotation = NumberRange.new(0,360), Spin = NumberRange.new(-15,15),
 LightEmission = 0.75, Transparency = 0.15, BeamWidth = 0.18, -- Claude 9/11: antes 0.15 / 0.5 / 0.055 (casi invisibles de noche)
 LightInfluence = 0, -- Claude 9/11: autoiluminadas; con luz de escena los colores oscuros desaparecían
 Segments = 1,
 WingWidth = 0.6, WingTextureSpeed = 0.6, -- alas: trazo ancho de humo que fluye
 OrbitSpeed = 0.45, BobSpeed = 1.2, BobSize = 0.12,
 CrownNodes = 12, CrownRadius = 0.95, CrownHeight = 2.7, CrownTooth = 0.35,
 ChainCount = 8, ChainRadius = 2.1, ChainHalf = 0.25, ChainHeight = 0.5,
 WingPath = { Vector3.new(0.5,0.7,0.6),Vector3.new(1.6,1.9,0.9),Vector3.new(3,2.3,1.2),Vector3.new(2.5,0.9,1),Vector3.new(2.2,-0.3,0.8),Vector3.new(1.3,0.2,0.7) },
 WingFlap = 0.25, FeetY = -2.7, MistRadius = 0.75,
 Eyes = 3, EyeRadius = 2.3, EyeHeight = 1.1, EyeWidth = 0.45, EyeOpen = 0.23, BlinkSpeed = 1.3,
 Runes = 4, RuneRadius = 1.9, RuneHeight = -0.7, RuneSize = 0.3,
 RunePath = { Vector3.new(-1,1,0),Vector3.new(0,0,0),Vector3.new(1,1,0),Vector3.new(0,0,0),Vector3.new(0,-1,0) },
 FractureNodes = 7, FractureOffset = 0.07, FractureHeight = 0.04,
 DripGravity = Vector3.new(0,-1,0), BloodGravity = Vector3.new(0,-5,0), EmberGravity = Vector3.new(0,0.8,0),
}
return A
