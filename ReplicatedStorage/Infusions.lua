-- ModuleScript: ReplicatedStorage/Infusions
-- Las infusiones son la "ulti": con la barra llena, R enciende el arma durante unos segundos.
-- Mientras está activa, el efecto se aplica a los golpes básicos (M1) y a los fuertes.
-- Cada una tiene ventajas (mods sobre ti), efectos al golpear (sobre el rival) y un coste.
-- Contras en ciclo (piedra-papel-tijera): Fuego > Rayo > Hielo > Sombra > Fuego.
-- 11/11/2026: solo cuentan en una «pelea de infusiones» (las dos encendidas). Apagada, no hace nada en el PvP.
-- Todo valor es una propuesta a calibrar. Sangre y Veneno quedan para más adelante (solo datos).

local Theme = require(script.Parent:WaitForChild("Theme"))

local Infusions = {}

Infusions.Order = { "Fire", "Lightning", "Ice", "Shadow" }

Infusions.Duration = 12          -- segundos activa
Infusions.Exhaust = 5            -- segundos sin ganar carga tras apagarse
Infusions.ActivateTime = 0.5     -- animación de encendido (no se puede atacar durante ella)
Infusions.InfusedHeavyUnblockable = true -- el fuerte infundido es imbloqueable (parreable y esquivable)
Infusions.Affinity = 0.08        -- ±8 % de daño y Stun según el emparejamiento (solo con las dos infusiones encendidas)

-- A quién gana cada una (y por tanto, quién le gana a ella)
Infusions.Beats = { Fire = "Lightning", Lightning = "Ice", Ice = "Shadow", Shadow = "Fire" }

-- mods: atributos que se multiplican en tu personaje mientras dura (1 = sin cambio)
-- onHit: efecto sobre el rival (lo aplica ServerScriptService/Infusion)
Infusions.Data = {
	Fire = {
		name = "Fuego", title = "Furia Ígnea", key = "FUEGO",
		color = Theme.Infusions.Fire, color2 = Color3.fromRGB(255, 50, 20),
		desc = "Presión y daño. Quema al rival y atraviesa parte de su bloqueo.",
		pros = { "+20 % de daño", "Quemadura: 4 de daño/s durante 4 s", "30 % del daño atraviesa el bloqueo",
			"La Guardia del quemado se regenera a la mitad" },
		cons = { "-30 % de Stun por golpe", "-10 % de velocidad" },
		mods = { DamageMult = 1.2, StunMult = 0.7, MoveSpeedMult = 0.9 },
		onHit = { burnDps = 4, burnDuration = 4, chip = 0.3 },
	},
	Lightning = {
		name = "Rayo", title = "Tormenta", key = "RAYO",
		color = Theme.Infusions.Lightning, color2 = Color3.fromRGB(230, 245, 255),
		desc = "Velocidad y control. Aturde y destroza guardias.",
		pros = { "+25 % de velocidad de ataque", "+10 % de velocidad", "+50 % de Stun por golpe",
			"Cada 3 golpes: descarga que aturde 0,6 s", "Bloquearle cuesta +50 % de Guardia" },
		cons = { "-20 % de daño" },
		mods = { AttackSpeedMult = 1.25, MoveSpeedMult = 1.1, StunMult = 1.5, DamageMult = 0.8, GuardDrainMult = 1.5 },
		onHit = { shockEvery = 3, shockStagger = 0.6 },
	},
	Ice = {
		name = "Hielo", title = "Escarcha", key = "HIELO",
		color = Theme.Infusions.Ice, color2 = Color3.fromRGB(240, 252, 255),
		desc = "Control y aguante. Ralentiza y vuelve frágil al rival.",
		pros = { "Cada golpe ralentiza un 30 % durante 2 s", "Tras 3 golpes: Fragilidad (+15 % de daño recibido, 4 s)",
			"+50 % de regeneración de Guardia" },
		cons = { "-15 % de velocidad de ataque", "-10 % de daño" },
		mods = { AttackSpeedMult = 0.85, DamageMult = 0.9, GuardRegenMult = 1.5 },
		onHit = { slowMult = 0.7, slowDuration = 2, fragileEvery = 3, fragileMult = 1.15, fragileDuration = 4 },
	},
	Shadow = {
		name = "Sombra", title = "Velo", key = "SOMBRA",
		color = Theme.Infusions.Shadow, color2 = Color3.fromRGB(40, 10, 60),
		desc = "Movilidad y ráfaga. Castiga desde la espalda y tras esquivar.",
		pros = { "+15 % de velocidad", "Esquiva +30 % más larga y +0,1 s de invulnerabilidad",
			"+20 % de daño por la espalda", "Tras esquivar: el siguiente golpe hace +25 %" },
		cons = { "-30 % de Guardia máxima", "-20 % de Stun por golpe" },
		mods = { MoveSpeedMult = 1.15, DodgeDistanceMult = 1.3, DodgeIFrameBonus = 0.1, StunMult = 0.8 },
		guardMaxMult = 0.7,
		onHit = { backstab = 1.2, afterDodge = 1.25, afterDodgeWindow = 2 },
	},
}

-- Apariencia de la hoja. Las cifras de combate siguen en Data.
Infusions.Aura = {
	MaxDistance = 145, MinBladeLength = 0.15,
	CoreWidth = 0.115, CoreAlpha = 0.13, TipWidth = 0.7, BeamSegments = 12,
	BeamTexture = "rbxasset://textures/particles/sparkles_main.dds", BeamTextureLength = 0.65,
	-- Flipbooks Grid8x8 del ejemplo Volcano Island de Roblox Creator Hub.
	ArcAtlas = "rbxassetid://17363668312", SparkAtlas = "rbxassetid://17363669906",
	Stationary = NumberRange.new(0), LightRange = 5, LightInfluence = 0.22,
	ParticleRotation = NumberRange.new(-180, 180),
	Glow = {
		{ width = 0.21, speed = 0.72, alpha = 0.42, curve = -0.85 },
		{ width = 0.36, speed = 0.43, alpha = 0.61, curve = 0.55 },
		{ width = 0.56, speed = -0.19, alpha = 0.77, curve = 0.25 },
	},
	Arcs = { rate = 9, size = 1.05, life = NumberRange.new(0.22, 0.38), alpha = NumberSequence.new(0.28, 1) },
	Volutes = { size = 0.68, life = NumberRange.new(0.28, 0.58), spread = Vector2.new(60, 60), alpha = NumberSequence.new(0.28, 1) },
	Sparks = { rate = 11, size = 0.29, life = NumberRange.new(0.25, 0.52), alpha = NumberSequence.new(0.08, 1) },
	Weapons = {
		Sword = { width = 1, volume = Vector2.new(0.38, 0.38), depth = 0.16, rate = 1 },
		Greatsword = { width = 1.22, volume = Vector2.new(0.64, 0.64), depth = 0.29, rate = 1.16 },
		Dagger = { width = 0.68, volume = Vector2.new(0.25, 0.25), depth = 0.10, rate = 0.57 },
		Rapier = { width = 0.71, volume = Vector2.new(0.25, 0.25), depth = 0.10, rate = 0.9 },
		Mace = { width = 1.38, volume = Vector2.new(1.65, 3.1), depth = 0.86, rate = 1.12, surfaceVolutes = true },
	},
	Profiles = {
		Fire = {
			flow = 5.8, arcFps = 17, curl = 0.19, emission = 0.86, light = 0.88, rate = 14, drag = 1.8,
			speed = NumberRange.new(1.2, 2.8), acceleration = Vector3.new(0, 9, 0),
			texture = "rbxasset://textures/particles/fire_main.dds",
		},
		Lightning = {
			flow = 11.5, arcFps = 29, curl = 0.29, emission = 1, light = 1.1, rate = 14, drag = 4,
			speed = NumberRange.new(2.5, 6), acceleration = Vector3.new(0, 0.8, 0),
			texture = "rbxasset://textures/particles/sparkles_main.dds",
		},
		Ice = {
			flow = -4.8, arcFps = 13, curl = 0.09, emission = 0.76, light = 0.65, rate = 12, drag = 2.6,
			speed = NumberRange.new(0.6, 1.7), acceleration = Vector3.new(0, -7, 0),
			texture = "rbxasset://textures/particles/smoke_main.dds",
		},
		Shadow = {
			flow = 2.5, arcFps = 7, curl = 0.25, emission = 0.52, light = 0.36, rate = 9, drag = 3.5,
			speed = NumberRange.new(0.4, 1.15), acceleration = Vector3.new(0, 1.7, 0),
			texture = "rbxasset://textures/particles/smoke_main.dds",
		},
	},
}

function Infusions.get(id)
	return Infusions.Data[id]
end

-- 1 si "a" gana a "b", -1 si pierde, 0 si es neutral
function Infusions.matchup(a, b)
	if not a or not b or a == b then return 0 end
	if Infusions.Beats[a] == b then return 1 end
	if Infusions.Beats[b] == a then return -1 end
	return 0
end

-- Quién gana a "id"
function Infusions.beatenBy(id)
	for k, v in Infusions.Beats do
		if v == id then return k end
	end
	return nil
end

return Infusions
