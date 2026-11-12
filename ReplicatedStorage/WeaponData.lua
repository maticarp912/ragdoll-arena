-- ModuleScript: ReplicatedStorage/WeaponData
-- Números de cada arma. TODO valor es una propuesta a calibrar jugando.
-- archetype: tipo de animación (OneHand, TwoHand, Dual, Rapier, Hammer) en AnimClips.
-- La "ulti" es la infusión (Infusions) y es genérica para todas las armas.
--
-- combo  : 3 golpes (M1). Listas = golpe 1, 2 y 3.
--   damage / stun / knockback : por golpe
--   duration : duración total de cada golpe (s). Mientras dura no puedes encadenar otra acción.
--   hitTime  : momento del impacto (s desde el inicio) SI la animación no trae marcador "Hit".
--   reach / width : caja de golpe delante del personaje (studs).
--   hyperArmor    : por golpe; los golpes básicos del rival no lo interrumpen durante la preparación.
--   guardDrainMult: cuánta Guardia gasta el rival al bloquear este combo (x daño x CombatConfig.Guard.LightDrainMult).
--   staggerMult   : duración del aturdimiento corto que provoca cada golpe (interrupción).
--   sweetSpot     : golpes en el extremo del alcance (desde "from" x reach) hacen x"mult" de daño (Estoque).
--   widths        : (opcional) ancho por golpe; si falta se usa width.
--   whiffStaminaMult: (opcional) un golpe que no conecta gasta este múltiplo de su resistencia (Estoque).
-- heavy  : ataque fuerte (E / M2). Destello naranja; rompe la guardia pasiva.
--   windup / hitDelay / recovery: preparación (ventana de parry/esquiva), impacto y tiempo vulnerable.
--   feintable, hyperArmor, unblockable, blockDamageMult, guardBreakStunMult (ver CombatConfig).
-- mobility: dodgeDistance (x distancia del dash) y dodgeCost (x stamina del dash).
-- Situaciones que favorecen a cada arma: Notas/Equilibrio de armas.md

local WeaponData = {}

WeaponData.Order = { "Sword", "Greatsword", "Dagger", "Rapier", "Mace" }

-- 10/11/2026 «Contragolpe de peso» (riposte, solo Espadón y Maza): al bloquear un golpe básico, el atacante
-- queda trabado recoil s (se le corta el combo y lo que tenía encolado) y durante window s tu próximo golpe
-- básico sale con hiperarmadura, speedMult de la duración (más rápido) y damageMult de daño.
-- Armas con las que empieza un jugador nuevo. Se usa en la Fase E.
WeaponData.Starters = { "Sword", "Greatsword", "Dagger" }

WeaponData.Data = {
	-- ESPADA: equilibrada y consistente. Nada destaca, nada falla.
	Sword = {
		archetype = "OneHand", name = "Espada", desc = "Equilibrada y consistente. Combo fluido y fuerte rápido.",
		hp = 243, speed = 16, guardMax = 100, -- etapa 8: vida +35 % (era 180)
		combo = {
			damage = { 11, 12, 16 }, stun = { 15, 15, 30 }, knockback = { 6, 6, 16 },
			duration = { 0.55, 0.55, 0.68 }, hitTime = { 0.28, 0.28, 0.36 },
			reach = 7, width = 5,
			hyperArmor = { false, false, false }, guardDrainMult = 1.0, staggerMult = 1.0,
		},
		heavy = {
			name = "Tajo Cruzado", damage = 28, stun = 45, knockback = 26,
			windup = 0.4, hitDelay = 0.09, recovery = 0.42, reach = 7.5, width = 5.5,
			feintable = true, hyperArmor = false, unblockable = false,
			blockDamageMult = 0.5, guardBreakStunMult = 1,
		},
		mobility = { dodgeDistance = 1.0, dodgeCost = 1.0 },
		trait = "Fuerte rápido y fintable; buena en cualquier situación",
	},

	-- ESPADÓN: lento y previsible, pero alcance, barrido ancho, presión sobre la guardia
	-- e hiperarmadura en los golpes 2 y 3 (los golpes rápidos del rival no lo frenan). Empuja lejos.
	Greatsword = {
		archetype = "TwoHand", name = "Espadón", desc = "Lento y previsible, pero con alcance, barridos anchos y presión que no se frena.",
		hp = 260, speed = 12.5, guardMax = 115,
		combo = {
			-- 0.2 (D3): 17·19·26 → 19·21·29 y alcance 9,5 → 10
			-- 10/11/2026: más rápido (el usuario: «contra alguien que te spamee no tenés oportunidad»)
			-- duración 0,92·0,92·1,05 → 0,78·0,78·0,90 e impacto 0,50·0,50·0,58 → 0,40·0,40·0,48
			damage = { 17, 19, 26 }, stun = { 25, 28, 45 }, knockback = { 14, 14, 32 },
			duration = { 0.78, 0.78, 0.9 }, hitTime = { 0.4, 0.4, 0.48 },
			reach = 10, width = 7.5,
			hyperArmor = { false, true, true }, guardDrainMult = 1.6, staggerMult = 1.3,
		},
		heavy = {
			name = "Tajo Aplastante", damage = 45, stun = 70, knockback = 50,
			windup = 0.56, hitDelay = 0.1, recovery = 0.6, reach = 10, width = 7, -- 10/11: 0,64 / 0,66 → 0,56 / 0,60
			feintable = true, hyperArmor = true, unblockable = false,
			blockDamageMult = 0.5, guardBreakStunMult = 1.6,
		},
		mobility = { dodgeDistance = 0.9, dodgeCost = 1.25 },
		riposte = { window = 0.8, damageMult = 1.5, speedMult = 0.6, recoil = 0.35 }, -- 10/11: contragolpe de peso
		trait = "Hiperarmadura en golpes 2-3 y en el fuerte; barre de lado y empuja hacia el borde",
	},

	-- DAGAS: velocidad y presión cuerpo a cuerpo. Interrumpen, se mueven más, pero alcance corto
	-- y casi sin empuje (no sacan a nadie de la arena) y poca Guardia.
	Dagger = {
		archetype = "Dual", name = "Dagas", desc = "Velocidad y presión de cerca. Interrumpen y esquivan mejor que nadie.",
		hp = 216, speed = 18.5, guardMax = 80, -- etapa 8: +35 % (era 160)
		combo = {
			-- 0.2 (D3): 7·8·12 → 6·7·11; los golpes 2 y 3 impactan más tarde para dejar lugar al parry
			-- 11/11: el combo derriba menos (aturdimiento 11·11·20 → 6·6·11)
			damage = { 6, 7, 11 }, stun = { 6, 6, 11 }, knockback = { 3, 3, 8 },
			-- 12/11/2026: reacción humana ~200 ms; el golpe se anuncia en el triángulo al menos 0,24 s antes de pegar
			duration = { 0.4, 0.46, 0.52 }, hitTime = { 0.24, 0.25, 0.28 },
			reach = 5, width = 4,
			hyperArmor = { false, false, false }, guardDrainMult = 0.9, staggerMult = 0.85,
		},
		heavy = {
			name = "Doble Estocada", damage = 20, stun = 25, knockback = 12,
			windup = 0.28, hitDelay = 0.06, recovery = 0.32, reach = 5.5, width = 4,
			feintable = true, hyperArmor = false, unblockable = false,
			blockDamageMult = 0.5, guardBreakStunMult = 1,
			bleed = true, -- sangrado propio (Effects, más adelante)
		},
		mobility = { dodgeDistance = 1.15, dodgeCost = 0.75 },
		trait = "Dash más largo y barato; golpes que interrumpen rápido",
	},

	-- ESTOQUE: precisión y alcance frontal. Hace más daño en la punta, pero su caja es estrecha
	-- (falla de lado) y empuja y aturde poco.
	Rapier = {
		archetype = "Rapier", name = "Estoque", desc = "Precisión y alcance frontal. La punta castiga; de lado falla.",
		hp = 230, speed = 17, guardMax = 90, -- etapa 8: +35 % (era 170)
		combo = {
			-- 0.2 (D3): 9·11·15 → 8·10·14, duración 0,40·0,40·0,50 → 0,40·0,45·0,55, punta +25 % → +15 %
			damage = { 8, 10, 14 }, stun = { 12, 12, 24 }, knockback = { 5, 5, 12 },
			duration = { 0.44, 0.48, 0.57 }, hitTime = { 0.24, 0.24, 0.28 }, -- 12/11/2026: mínimo 0,24 s para reaccionar
			reach = 10, width = 2.5,
			hyperArmor = { false, false, false }, guardDrainMult = 0.9, staggerMult = 1.0,
			sweetSpot = { from = 0.65, mult = 1.15 },
			whiffStaminaMult = 1.5, -- 0.2 (D3): fallar un golpe gasta +50 % de resistencia
		},
		heavy = {
			name = "Puntada Perforante", damage = 26, stun = 35, knockback = 20,
			windup = 0.36, hitDelay = 0.06, recovery = 0.42, reach = 11, width = 2.5,
			feintable = true, hyperArmor = false, unblockable = false,
			blockDamageMult = 1.0, guardBreakStunMult = 1, -- atraviesa el bloqueo: entra todo el daño
		},
		mobility = { dodgeDistance = 1.05, dodgeCost = 0.9 },
		trait = "La punta premia la distancia precisa; la Puntada tiene más alcance",
	},

	-- MAZA: presión sobre Guardia y Stun. Destroza bloqueos y aturde, pero es lenta, corta
	-- y pesada para esquivar.
	Mace = {
		archetype = "Hammer", name = "Maza", desc = "Presión sobre la Guardia y el Stun. Rompe bloqueos y aturde; lenta y corta.",
		hp = 270, speed = 12.5, guardMax = 110,
		combo = {
			-- 0.2 (D3): 13·15·20 → 17·19·26, alcance 7 → 8, golpe 3 más ancho (5 → 6,5)
			-- 10/11/2026: más rápida. Duración 1,00·1,00·1,12 → 0,84·0,84·0,95 e impacto 0,56·0,56·0,63 → 0,44·0,44·0,52
			damage = { 15, 17, 22 }, stun = { 30, 30, 48 }, knockback = { 8, 8, 22 },
			-- 11/11: más rápida todavía (0,84·0,84·0,95 → 0,70·0,70·0,80; impacto 0,44·0,44·0,52 → 0,36·0,36·0,42).
			-- Queda un poco más rápida que el espadón pero con menos alcance (8 contra 10).
			duration = { 0.7, 0.7, 0.8 }, hitTime = { 0.36, 0.36, 0.42 },
			reach = 8, width = 5, widths = { 5, 5, 6.5 },
			hyperArmor = { false, false, true }, guardDrainMult = 2.0, staggerMult = 1.3,
		},
		heavy = {
			-- 10/11: el knockback = 36 había quedado adentro del comentario (el fuerte no empujaba)
			name = "Machaque Pesado", damage = 41, stun = 77, knockback = 36,
			windup = 0.46, hitDelay = 0.1, recovery = 0.5, reach = 7.5, width = 5.5, -- 11/11: 0,52 / 0,62 → 0,46 / 0,50 -- 9/11: 7 → 7.5 · 10/11: 0,60 / 0,68 → 0,52 / 0,62
			feintable = true, hyperArmor = false, unblockable = true,
			blockDamageMult = 1.0, guardBreakStunMult = 1,
		},
		mobility = { dodgeDistance = 0.9, dodgeCost = 1.25 },
		riposte = { window = 0.8, damageMult = 1.5, speedMult = 0.6, recoil = 0.35 }, -- 10/11: contragolpe de peso
		trait = "Castiga la Guardia y causa mucho aturdimiento con Machaque",
		blunt = true, -- martillo de guerra: sonido y efectos contundentes
	},
}

-- Los costos de ataque y esquiva dejan margen para combinar golpes con movimiento.
-- 11/11/2026: curva de derribo según la vida del rival (ver CombatConfig.StunByHealth).
-- full = multiplicador con el rival a vida llena · empty = con el rival casi muerto.
-- Espadón y maza derriban bien aunque el rival tenga vida; dagas y estoque casi solo cuando ya está bajo.
WeaponData.StunVsHealth = {
	Sword = { full = 0.65, empty = 1.35 },
	Greatsword = { full = 0.9, empty = 1.3 },
	Mace = { full = 0.95, empty = 1.3 },
	Rapier = { full = 0.55, empty = 1.35 },
	Dagger = { full = 0.5, empty = 1.4 },
}

WeaponData.Stamina = {
	Sword = { m1 = 22, heavy = 45 },
	Greatsword = { m1 = 29, heavy = 60 },
	Dagger = { m1 = 15, heavy = 29 },
	Rapier = { m1 = 18, heavy = 36 },
	Mace = { m1 = 29, heavy = 60 },
}

function WeaponData.staminaCost(id, kind)
	local s = WeaponData.Stamina[id] or WeaponData.Stamina.Sword
	return s[kind] or 0
end

-- Sensación de cada arma (para que se note cuál llevas): peso del impacto y del movimiento.
--   hitstop / shake : multiplican la micro-pausa y la sacudida de cámara al golpear
--   lunge           : studs que avanzas con cada golpe (el fuerte avanza x1,5)
--   weight          : 1 ligera .. 3 pesada (zancada, balanceo y bote al caminar)
WeaponData.Feel = {
	Sword = { hitstop = 1.0, shake = 1.0, lunge = 2.2, weight = 2 },
	Greatsword = { hitstop = 1.5, shake = 1.45, lunge = 3.2, weight = 3 },
	Dagger = { hitstop = 0.55, shake = 0.6, lunge = 1.4, weight = 1 },
	Rapier = { hitstop = 0.75, shake = 0.75, lunge = 3.6, weight = 1 },
	Mace = { hitstop = 1.7, shake = 1.65, lunge = 2.0, weight = 3 },
}

-- Combate direccional (0.2): excepciones por arma, sin anular el sistema (propuesta de Codex en
-- «Diseño Combate PvP Direccional Roblox»: maza solo el fuerte de arriba imbloqueable; estoque atraviesa solo con el fuerte).
-- Solo se usan con CombatConfig.Directional.Enabled = true.
function WeaponData.feel(id)
	return WeaponData.Feel[id] or WeaponData.Feel.Sword
end

function WeaponData.get(id)
	return WeaponData.Data[id] or WeaponData.Data.Sword
end

return WeaponData
