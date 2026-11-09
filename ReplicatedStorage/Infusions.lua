-- ModuleScript: ReplicatedStorage/Infusions
-- Las infusiones son la "ulti": con la barra llena, Q enciende el arma durante unos segundos.
-- Mientras está activa, el efecto se aplica a los golpes básicos (M1) y a los fuertes.
-- Cada una tiene ventajas (mods sobre ti), efectos al golpear (sobre el rival) y un coste.
-- Contras en ciclo (piedra-papel-tijera): Fuego > Rayo > Hielo > Sombra > Fuego.
-- Todo valor es una propuesta a calibrar. Sangre y Veneno quedan para más adelante (solo datos).

local Theme = require(script.Parent:WaitForChild("Theme"))

local Infusions = {}

Infusions.Order = { "Fire", "Lightning", "Ice", "Shadow" }

Infusions.Duration = 12          -- segundos activa
Infusions.Exhaust = 5            -- segundos sin ganar carga tras apagarse
Infusions.ActivateTime = 0.5     -- animación de encendido (no se puede atacar durante ella)
Infusions.InfusedHeavyUnblockable = true -- el fuerte infundido es imbloqueable (parreable y esquivable)
Infusions.Affinity = 0.08        -- ±8 % de daño y Stun según el emparejamiento

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
