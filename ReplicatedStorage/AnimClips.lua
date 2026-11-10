-- ModuleScript: ReplicatedStorage/AnimClips
-- Animaciones PROCEDURALES (sin assets): poses por keyframes que el cliente aplica a las
-- articulaciones R15 (Motor6D.Transform). Las usa StarterPlayerScripts/Animator.
-- En cuanto una clave tenga ID real en Assets.lua, se usa la animación real y esta se ignora.
--
-- Formato de pose: { Articulación = { rotX, rotY, rotZ [, posX, posY, posZ] } } en grados y studs,
-- en el marco de la articulación (X = derecha, Y = arriba, -Z = adelante del personaje).
--   Hombro (RS/LS): +X levanta el brazo hacia delante · +Z lo abre hacia fuera (RS) / -Z (LS)
--   Codo (RE/LE): +X dobla · Muñeca (RW/LW): +X inclina el arma hacia arriba, Y la gira sobre el antebrazo
--   Cintura/Cuello (W/N): -X inclina adelante · +Y gira a la izquierda · +Z inclina a la izquierda
--   Cadera (RH/LH): +X pierna adelante · Rodilla (RK/LK): -X dobla · Tobillo (RA/LA): +X punta arriba
--   Raíz (R): mueve/gira todo el cuerpo (posY < 0 = agacharse)
-- Clip: { dur = s, full = (incluye piernas), additive = (se suma a la pose base),
--         windup = 0..1, hit = 0..1 (momentos que el servidor sincroniza), trail = {desde, hasta},
--         keys = { {t, pose, ease}, ... } }   pose "base" = la postura actual del arma

local AnimClips = {}

AnimClips.Playback = {
	-- 0.2 (C23): golpes más exagerados (1,22 → 1,32) y reacciones de dolor más marcadas
	Exaggerate = 1.32,  -- amplía el recorrido de los golpes (M1 y fuerte) respecto a la postura
	HitReactExaggerate = 1.4, -- amplía Generic.HitReact* (recibir un golpe se tiene que ver)
	Transition = 0.09,
	Recovery = 0.16,
	StanceResponse = 16,
}

AnimClips.Joints = {
	R = "Root", W = "Waist", N = "Neck",
	RS = "RightShoulder", RE = "RightElbow", RW = "RightWrist",
	LS = "LeftShoulder", LE = "LeftElbow", LW = "LeftWrist",
	RH = "RightHip", RK = "RightKnee", RA = "RightAnkle",
	LH = "LeftHip", LK = "LeftKnee", LA = "LeftAnkle",
}
AnimClips.Upper = { "W", "N", "RS", "RE", "RW", "LS", "LE", "LW" }

-- 0.2: combate direccional (solo con CombatConfig.Directional.Enabled). Capas PROCEDURALES que se suman a las
-- posturas y a los golpes existentes, como se empezó con las dagas; más adelante pueden pasar a captura.
-- Valores en grados, mismo formato de pose. Propuesta a calibrar en Studio con PoseTune.
AnimClips.Directional = {
	-- Guardia por lado (se suma a la postura de guardia del arma). En reposo se suma ReadyWeight de esto,
	-- para que el rival vea de qué lado estás sin necesidad del triángulo.
	Guard = {
		Up = { W = { 6, 0, 0 }, N = { -4, 0, 0 }, RS = { 38, 0, 0 }, RE = { -18, 0, 0 }, LS = { 26, 0, 0 } },
		Left = { W = { 0, 26, 4 }, N = { 0, -18, 0 }, RS = { -6, 0, -24 }, RW = { 0, -38, 0 }, LS = { -8, 0, -10 } },
		Right = { W = { 0, -26, -4 }, N = { 0, 18, 0 }, RS = { -8, 0, 26 }, RW = { 0, 38, 0 }, LS = { 6, 0, 12 } },
	},
	ReadyWeight = 0.45,
	StanceResponse = 18, -- rapidez con que la pose sigue al cambio de lado
	-- Golpe por dirección (en el marco del atacante): carga hacia su lado y cruza al otro tras el impacto
	Attack = {
		Up = {
			windup = { W = { 14, 0, 0 }, RS = { 62, 0, 0 }, RE = { -22, 0, 0 }, LS = { 30, 0, 0 } },
			follow = { W = { -16, 0, 0 }, RS = { -34, 0, 0 }, RE = { 10, 0, 0 } },
		},
		Left = {
			windup = { W = { 0, 38, 0 }, N = { 0, -20, 0 }, RS = { 10, 0, -38 }, RW = { 0, -30, 0 } },
			follow = { W = { 0, -32, 0 }, N = { 0, 16, 0 }, RS = { -6, 0, 32 } },
		},
		Right = {
			windup = { W = { 0, -38, 0 }, N = { 0, 20, 0 }, RS = { 6, 0, 42 }, RW = { 0, 30, 0 } },
			follow = { W = { 0, 32, 0 }, N = { 0, -16, 0 }, RS = { -4, 0, -34 } },
		},
	},
	WindupPeak = 0.7, -- fracción de la carga en que la capa llega a su máximo (después cruza en el impacto)
	FollowPeak = 0.3, -- fracción de la recuperación en que el seguimiento llega a su máximo
	FinisherMult = 1.35, -- el remate (D4) exagera más
}
AnimClips.Lower = { "R", "RH", "RK", "RA", "LH", "LK", "LA" }

local BASE = "base"

----------------------------------------------------------------------
-- Posturas por tipo de arma (reposo y guardia)
----------------------------------------------------------------------
-- Reposo en el hombro: tras Delay segundos sin acción, bloqueo ni objetivo fijado, las armas
-- pesadas pasan a su postura de reposo. Cualquier acción las vuelve a la guardia al instante.
AnimClips.Rest = {
	Delay = 2.5,
	Stances = { TwoHand = "TwoHandRest", Hammer = "HammerRest" },
}

-- Agarre a dos manos (etapa 8): estas posturas llevan la mano izquierda al mango por IK aunque
-- el clip anime el brazo izquierdo (las capturas de espada eran a una mano).
AnimClips.TwoHandIK = { TwoHand = true, Hammer = true, OneHand = true }
-- Si WeaponBuilder.Info todavía no marca el arma como de dos manos, se usa este agarre.
AnimClips.OffhandFallback = { Sword = -0.42 }

AnimClips.Stances = {
	-- Espada a una mano: hoja adelantada en diagonal, mano izquierda suelta
	OneHand = {
		Ready = { W = { -3, 10, 0 }, N = { 0, -9, 0 },
			RS = { 16, 0, 8 }, RE = { 42, 0, 0 }, RW = { -24, 10, 0 },
			LS = { 6, 0, -8 }, LE = { 16, 0, 0 }, LW = { 0, 0, 0 } },
		Guard = { W = { 0, 6, 0 }, N = { 0, -6, 0 },
			RS = { 72, 0, -4 }, RE = { 72, 0, 0 }, RW = { 0, 88, 0 },
			LS = { 48, 0, -8 }, LE = { 72, 0, 0 }, LW = { 0, 0, 0 } },
	},
	-- Espadón: dos manos, hoja en diagonal frente al cuerpo (la izquierda va por IK)
	TwoHand = {
		Ready = { W = { -3, 18, 0 }, N = { 0, -15, 0 },
			RS = { 14, 0, -14 }, RE = { 56, 0, 0 }, RW = { -30, 28, 0 },
			LS = { 20, 0, 10 }, LE = { 50, 0, 0 }, LW = { 0, 0, 0 } },
		Guard = { W = { 0, 12, 0 }, N = { 0, -12, 0 },
			RS = { 58, 0, -24 }, RE = { 72, 0, 0 }, RW = { -48, 0, 0 },
			LS = { 50, 0, 20 }, LE = { 70, 0, 0 }, LW = { 0, 0, 0 } },
	},
	-- Reposo en el hombro (etapa 8): fuera de combate el espadón descansa sobre el hombro derecho
	-- con la hoja hacia atrás; la mano izquierda queda suelta (sin IK). Ver AnimClips.Rest.
	TwoHandRest = { W = { 0, 8, 0 }, N = { 0, -6, 0 },
		RS = { 83, 15, 13 }, RE = { 135, 0, 0 }, RW = { -80, -33, -15 }, -- búsqueda automática en Studio: hoja atrás y arriba
		LS = { 8, 0, -6 }, LE = { 14, 0, 0 }, LW = { 0, 0, 0 } },
	-- Martillo: mango cruzado, cabeza arriba junto al hombro izquierdo
	Hammer = {
		Ready = { W = { -3, 20, 0 }, N = { 0, -17, 0 },
			RS = { 12, 0, -16 }, RE = { 62, 0, 0 }, RW = { -20, 42, 0 },
			LS = { 20, 0, 10 }, LE = { 50, 0, 0 }, LW = { 0, 0, 0 } },
		Guard = { W = { 0, 8, 0 }, N = { 0, -8, 0 },
			RS = { 70, 0, 12 }, RE = { 62, 0, 0 }, RW = { 0, 90, 0 },
			LS = { 60, 0, -10 }, LE = { 60, 0, 0 }, LW = { 0, 0, 0 } },
	},
	-- Martillo al hombro: igual que el espadón, con la cabeza detrás del hombro
	HammerRest = { W = { 0, 8, 0 }, N = { 0, -6, 0 },
		RS = { 83, 15, 13 }, RE = { 135, 0, 0 }, RW = { -80, -33, -15 }, -- búsqueda automática en Studio: hoja atrás y arriba
		LS = { 8, 0, -6 }, LE = { 14, 0, 0 }, LW = { 0, 0, 0 } },
	-- Dagas: puños a la altura del pecho, hojas al frente
	Dual = {
		Ready = { W = { -5, 0, 0 }, N = { 4, 0, 0 },
			RS = { 14, 0, 14 }, RE = { 50, 0, 0 }, RW = { -30, 0, 0 },
			LS = { 14, 0, -14 }, LE = { 50, 0, 0 }, LW = { -30, 0, 0 } },
		Guard = { W = { 0, 0, 0 }, N = { 6, 0, 0 },
			RS = { 88, 0, -18 }, RE = { 92, 0, 0 }, RW = { -20, 40, 0 },
			LS = { 88, 0, 18 }, LE = { 92, 0, 0 }, LW = { -20, -40, 0 } },
	},
	-- Estoque: guardia de esgrima, de perfil, brazo armado extendido y el izquierdo arriba atrás
	Rapier = {
		Ready = { W = { 0, 30, 0 }, N = { 0, -26, 0 },
			RS = { 36, 0, 24 }, RE = { 30, 0, 0 }, RW = { -50, 0, 0 },
			LS = { 30, 0, -30 }, LE = { 70, 0, 0 }, LW = { 0, 0, 0 } },
		Guard = { W = { 0, 34, 0 }, N = { 0, -30, 0 },
			RS = { 62, 0, 30 }, RE = { 62, 0, 0 }, RW = { -30, 0, 0 },
			LS = { 130, 0, -36 }, LE = { 82, 0, 0 }, LW = { 0, 0, 0 } },
	},
}


-- Caminata procedural (todas las armas). La cabeza se estabiliza: compensa el giro y la inclinación del torso.
AnimClips.Locomotion = {
	Speed = 16,          -- velocidad de referencia (studs/s)
	PhaseRate = 0.55,    -- avance de la zancada por stud recorrido
	Hip = 30, Knee = 46, Ankle = 14, Side = 18,
	Arm = 18,            -- balanceo del brazo libre
	WeaponArm = 5,       -- balanceo del brazo armado
	Bob = 0.12,          -- bote de la cadera (studs)
	Twist = 7,           -- giro de la pelvis; el torso lo compensa
	Lean = 6,            -- inclinación hacia la dirección de avance
	Response = 10,       -- suavizado al arrancar/frenar
	HeadStabilize = 0.85,
	-- por peso del arma (WeaponData.Feel.weight): zancada y bote
	Weight = { { stride = 1.12, bob = 0.8 }, { stride = 1.0, bob = 1.0 }, { stride = 0.86, bob = 1.35 } },
	AirArms = 110, AirWave = 18, AirFrequency = 9,
}

-- Posturas comunes
AnimClips.Common = {
	Carry = { W = { 6, 0, 0 }, N = { -6, 0, 0 },
		RS = { 172, 0, 14 }, RE = { 22, 0, 0 }, RW = { 0, 0, 0 },
		LS = { 172, 0, -14 }, LE = { 22, 0, 0 }, LW = { 0, 0, 0 } },
	ThrowCharge = { W = { 22, 0, 0 }, N = { -12, 0, 0 },
		RS = { 172, 0, 42 }, RE = { 50, 0, 0 }, RW = { 0, 0, 0 },
		LS = { 165, 0, -6 }, LE = { 60, 0, 0 }, LW = { 0, 0, 0 } },
	-- Piernas de los muñecos (no tienen script de animación propio)
	LegsIdle = { R = { 0, 0, 0, 0, -0.18, 0 }, RH = { -4, 0, 6 }, RK = { -16, 0, 0 }, RA = { 10, 0, 0 },
		LH = { 16, 0, -6 }, LK = { -20, 0, 0 }, LA = { 4, 0, 0 } },
}

----------------------------------------------------------------------
-- Ataques por tipo de arma
----------------------------------------------------------------------
local A = {}
AnimClips.Archetypes = A

-- ESPADA (una mano)
A.OneHand = {
	-- Tajo diagonal de arriba-derecha a abajo-izquierda
	M1_1 = { dur = 0.45, hit = 0.5, trail = { 0.32, 0.7 }, keys = {
		{ 0, BASE },
		{ 0.32, { W = { 2, -30, 0 }, N = { 0, 26, 0 }, RS = { 150, 0, 36 }, RE = { 42, 0, 0 }, RW = { 12, -20, 0 },
			LS = { 30, 0, -30 }, LE = { 40, 0, 0 } }, "out" },
		{ 0.5, { W = { -8, 34, 0 }, N = { 0, -26, 0 }, RS = { 40, 0, -36 }, RE = { 14, 0, 0 }, RW = { -22, 30, 0 },
			LS = { 10, 0, -38 }, LE = { 30, 0, 0 } }, "in" },
		{ 0.72, { W = { -5, 30, 0 }, N = { 0, -22, 0 }, RS = { 24, 0, -40 }, RE = { 24, 0, 0 }, RW = { -26, 34, 0 },
			LS = { 12, 0, -34 }, LE = { 30, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Revés de abajo-izquierda a derecha
	M1_2 = { dur = 0.45, hit = 0.5, trail = { 0.3, 0.7 }, keys = {
		{ 0, BASE },
		{ 0.3, { W = { 0, 32, 0 }, N = { 0, -22, 0 }, RS = { 62, 0, -52 }, RE = { 80, 0, 0 }, RW = { 0, 60, 0 },
			LS = { 22, 0, -20 }, LE = { 40, 0, 0 } }, "out" },
		{ 0.5, { W = { -6, -36, 0 }, N = { 0, 26, 0 }, RS = { 78, 0, 52 }, RE = { 10, 0, 0 }, RW = { 0, -40, 0 },
			LS = { 20, 0, -30 }, LE = { 40, 0, 0 } }, "in" },
		{ 0.74, { W = { -4, -30, 0 }, N = { 0, 22, 0 }, RS = { 60, 0, 56 }, RE = { 24, 0, 0 }, RW = { 0, -46, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Golpe vertical por encima de la cabeza
	M1_3 = { dur = 0.55, hit = 0.5, trail = { 0.36, 0.7 }, keys = {
		{ 0, BASE },
		{ 0.34, { W = { 10, 8, 0 }, N = { -6, -6, 0 }, RS = { 176, 0, 10 }, RE = { 62, 0, 0 }, RW = { 22, 0, 0 },
			LS = { 110, 0, -12 }, LE = { 50, 0, 0 } }, "out" },
		{ 0.5, { W = { -24, 4, 0 }, N = { 12, -4, 0 }, RS = { 38, 0, -4 }, RE = { 4, 0, 0 }, RW = { -32, 0, 0 },
			LS = { 18, 0, -18 }, LE = { 30, 0, 0 } }, "in" },
		{ 0.78, { W = { -16, 4, 0 }, N = { 8, -4, 0 }, RS = { 26, 0, -4 }, RE = { 14, 0, 0 }, RW = { -30, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Tajo Cruzado: se enrosca, aguanta (aviso) y suelta un tajo con paso al frente
	Heavy = { dur = 1.0, full = true, windup = 0.55, hit = 0.68, trail = { 0.56, 0.85 }, keys = {
		{ 0, BASE },
		{ 0.18, { W = { 2, -40, 0 }, N = { 0, 34, 0 }, RS = { 125, 0, 42 }, RE = { 80, 0, 0 }, RW = { 10, -20, 0 },
			LS = { 40, 0, -40 }, LE = { 40, 0, 0 },
			R = { 0, 0, 0, 0, -0.25, 0.1 }, RH = { -12, 0, 0 }, RK = { -22, 0, 0 }, LH = { 22, 0, 0 }, LK = { -20, 0, 0 } }, "out" },
		{ 0.55, { W = { 8, -55, 0 }, N = { 0, 46, 0 }, RS = { 166, 0, 56 }, RE = { 50, 0, 0 }, RW = { 22, -30, 0 },
			LS = { 42, 0, -52 }, LE = { 42, 0, 0 },
			R = { 0, 0, 0, 0, -0.4, 0.3 }, RH = { -20, 0, 0 }, RK = { -30, 0, 0 }, LH = { 30, 0, 0 }, LK = { -32, 0, 0 } }, "inout" },
		{ 0.68, { W = { -16, 50, 0 }, N = { 0, -36, 0 }, RS = { 30, 0, -46 }, RE = { 10, 0, 0 }, RW = { -30, 40, 0 },
			LS = { 22, 0, -60 }, LE = { 20, 0, 0 },
			R = { 0, 0, 0, 0, -0.55, -1.0 }, RH = { 52, 0, 0 }, RK = { -42, 0, 0 }, LH = { -30, 0, 0 }, LK = { -22, 0, 0 } }, "in" },
		{ 0.86, { W = { -10, 44, 0 }, N = { 0, -30, 0 }, RS = { 24, 0, -46 }, RE = { 18, 0, 0 }, RW = { -30, 40, 0 },
			R = { 0, 0, 0, 0, -0.45, -0.8 }, RH = { 40, 0, 0 }, RK = { -36, 0, 0 }, LH = { -24, 0, 0 }, LK = { -20, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
}

-- ESPADÓN (dos manos)
A.TwoHand = {
	M1_1 = { dur = 0.8, hit = 0.52, trail = { 0.34, 0.72 }, keys = {
		{ 0, BASE },
		{ 0.34, { W = { 2, -50, 0 }, N = { 0, 40, 0 }, RS = { 118, 0, 42 }, RE = { 88, 0, 0 }, RW = { -10, -10, 0 } }, "out" },
		{ 0.52, { W = { -12, 46, 0 }, N = { 0, -36, 0 }, RS = { 82, 0, -38 }, RE = { 20, 0, 0 }, RW = { -60, 60, 0 } }, "in" },
		{ 0.76, { W = { -8, 50, 0 }, N = { 0, -38, 0 }, RS = { 70, 0, -46 }, RE = { 26, 0, 0 }, RW = { -60, 64, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	M1_2 = { dur = 0.8, hit = 0.52, trail = { 0.34, 0.72 }, keys = {
		{ 0, BASE },
		{ 0.32, { W = { 0, 46, 0 }, N = { 0, -36, 0 }, RS = { 92, 0, -50 }, RE = { 62, 0, 0 }, RW = { -40, 70, 0 } }, "out" },
		{ 0.52, { W = { -12, -46, 0 }, N = { 0, 38, 0 }, RS = { 82, 0, 50 }, RE = { 20, 0, 0 }, RW = { -60, -40, 0 } }, "in" },
		{ 0.76, { W = { -6, -50, 0 }, N = { 0, 40, 0 }, RS = { 70, 0, 56 }, RE = { 26, 0, 0 }, RW = { -60, -44, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	M1_3 = { dur = 0.9, full = true, hit = 0.53, trail = { 0.38, 0.72 }, keys = {
		{ 0, BASE },
		{ 0.36, { W = { 12, 0, 0 }, N = { -8, 0, 0 }, RS = { 176, 0, 2 }, RE = { 52, 0, 0 }, RW = { 30, 0, 0 },
			R = { 0, 0, 0, 0, -0.1, 0.2 } }, "out" },
		{ 0.53, { W = { -32, 0, 0 }, N = { 16, 0, 0 }, RS = { 44, 0, -10 }, RE = { 2, 0, 0 }, RW = { -42, 0, 0 },
			R = { 0, 0, 0, 0, -0.5, -0.3 }, RH = { 46, 0, 0 }, RK = { -54, 0, 0 }, LH = { -14, 0, 0 }, LK = { -32, 0, 0 } }, "in" },
		{ 0.8, { W = { -26, 0, 0 }, N = { 12, 0, 0 }, RS = { 40, 0, -10 }, RE = { 6, 0, 0 }, RW = { -42, 0, 0 },
			R = { 0, 0, 0, 0, -0.45, -0.3 }, RH = { 40, 0, 0 }, RK = { -50, 0, 0 }, LH = { -12, 0, 0 }, LK = { -30, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	Heavy = { dur = 1.6, full = true, windup = 0.6, hit = 0.7, trail = { 0.6, 0.86 }, keys = {
		{ 0, BASE },
		{ 0.3, { W = { 8, -10, 0 }, N = { -6, 8, 0 }, RS = { 150, 0, 14 }, RE = { 80, 0, 0 }, RW = { 20, 0, 0 },
			R = { 0, 0, 0, 0, -0.35, 0.2 }, RH = { 20, 0, 0 }, RK = { -40, 0, 0 }, LH = { 24, 0, 0 }, LK = { -40, 0, 0 } }, "out" },
		{ 0.6, { W = { 16, 0, 0 }, N = { -10, 0, 0 }, RS = { 182, 0, 4 }, RE = { 72, 0, 0 }, RW = { 42, 0, 0 },
			R = { 0, 0, 0, 0, -0.25, 0.3 }, RH = { 14, 0, 0 }, RK = { -30, 0, 0 }, LH = { 18, 0, 0 }, LK = { -30, 0, 0 } }, "inout" },
		{ 0.7, { W = { -38, 0, 0 }, N = { 18, 0, 0 }, RS = { 40, 0, -10 }, RE = { 0, 0, 0 }, RW = { -46, 0, 0 },
			R = { 0, 0, 0, 0, -0.85, -0.9 }, RH = { 62, 0, 0 }, RK = { -64, 0, 0 }, LH = { -26, 0, 0 }, LK = { -34, 0, 0 } }, "in" },
		{ 0.9, { W = { -30, 0, 0 }, N = { 14, 0, 0 }, RS = { 36, 0, -10 }, RE = { 6, 0, 0 }, RW = { -46, 0, 0 },
			R = { 0, 0, 0, 0, -0.75, -0.8 }, RH = { 54, 0, 0 }, RK = { -60, 0, 0 }, LH = { -22, 0, 0 }, LK = { -30, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
}

-- MARTILLO: como el espadón pero más vertical y con impacto contra el suelo
A.Hammer = {
	M1_1 = { dur = 0.85, hit = 0.53, trail = { 0.36, 0.72 }, keys = {
		{ 0, BASE },
		{ 0.36, { W = { 4, -46, 0 }, N = { 0, 38, 0 }, RS = { 150, 0, 40 }, RE = { 76, 0, 0 }, RW = { 10, -16, 0 } }, "out" },
		{ 0.53, { W = { -18, 40, 0 }, N = { 6, -32, 0 }, RS = { 54, 0, -30 }, RE = { 10, 0, 0 }, RW = { -50, 40, 0 } }, "in" },
		{ 0.78, { W = { -12, 36, 0 }, N = { 4, -30, 0 }, RS = { 44, 0, -34 }, RE = { 18, 0, 0 }, RW = { -50, 44, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	M1_2 = { dur = 0.85, hit = 0.53, trail = { 0.36, 0.72 }, keys = {
		{ 0, BASE },
		{ 0.36, { W = { 0, 44, 0 }, N = { 0, -34, 0 }, RS = { 96, 0, -46 }, RE = { 60, 0, 0 }, RW = { -30, 70, 0 } }, "out" },
		{ 0.53, { W = { -12, -44, 0 }, N = { 0, 36, 0 }, RS = { 84, 0, 50 }, RE = { 16, 0, 0 }, RW = { -58, -40, 0 } }, "in" },
		{ 0.78, { W = { -8, -46, 0 }, N = { 0, 38, 0 }, RS = { 72, 0, 54 }, RE = { 22, 0, 0 }, RW = { -58, -44, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	M1_3 = { dur = 0.95, full = true, hit = 0.53, trail = { 0.38, 0.7 }, keys = {
		{ 0, BASE },
		{ 0.38, { W = { 14, 0, 0 }, N = { -10, 0, 0 }, RS = { 182, 0, 0 }, RE = { 50, 0, 0 }, RW = { 36, 0, 0 },
			R = { 0, 0, 0, 0, 0.1, 0.25 } }, "out" },
		{ 0.53, { W = { -40, 0, 0 }, N = { 18, 0, 0 }, RS = { 32, 0, -8 }, RE = { 0, 0, 0 }, RW = { -50, 0, 0 },
			R = { 0, 0, 0, 0, -0.7, -0.4 }, RH = { 56, 0, 0 }, RK = { -62, 0, 0 }, LH = { -18, 0, 0 }, LK = { -36, 0, 0 } }, "in" },
		{ 0.8, { W = { -34, 0, 0 }, N = { 14, 0, 0 }, RS = { 30, 0, -8 }, RE = { 4, 0, 0 }, RW = { -50, 0, 0 },
			R = { 0, 0, 0, 0, -0.65, -0.4 }, RH = { 50, 0, 0 }, RK = { -58, 0, 0 }, LH = { -16, 0, 0 }, LK = { -34, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Machaque Pesado: se agacha, salta un poco y aplasta contra el suelo
	Heavy = { dur = 1.5, full = true, windup = 0.6, hit = 0.7, trail = { 0.6, 0.85 }, keys = {
		{ 0, BASE },
		{ 0.32, { W = { 10, -8, 0 }, N = { -6, 6, 0 }, RS = { 160, 0, 10 }, RE = { 70, 0, 0 }, RW = { 30, 0, 0 },
			R = { 0, 0, 0, 0, -0.6, 0.2 }, RH = { 40, 0, 0 }, RK = { -70, 0, 0 }, LH = { 40, 0, 0 }, LK = { -70, 0, 0 } }, "out" },
		{ 0.6, { W = { 20, 0, 0 }, N = { -12, 0, 0 }, RS = { 186, 0, 2 }, RE = { 60, 0, 0 }, RW = { 46, 0, 0 },
			R = { 0, 0, 0, 0, 0.5, 0 }, RH = { 10, 0, 0 }, RK = { -20, 0, 0 }, LH = { 14, 0, 0 }, LK = { -24, 0, 0 } }, "out" },
		{ 0.7, { W = { -46, 0, 0 }, N = { 20, 0, 0 }, RS = { 26, 0, -8 }, RE = { 0, 0, 0 }, RW = { -56, 0, 0 },
			R = { 0, 0, 0, 0, -1.0, -0.8 }, RH = { 66, 0, 0 }, RK = { -76, 0, 0 }, LH = { -20, 0, 0 }, LK = { -40, 0, 0 } }, "in" },
		{ 0.9, { W = { -38, 0, 0 }, N = { 16, 0, 0 }, RS = { 26, 0, -8 }, RE = { 4, 0, 0 }, RW = { -56, 0, 0 },
			R = { 0, 0, 0, 0, -0.9, -0.7 }, RH = { 60, 0, 0 }, RK = { -72, 0, 0 }, LH = { -18, 0, 0 }, LK = { -38, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
}

-- DAGAS
A.Dual = {
	-- Puñalada derecha: el torso se enrosca y la izquierda se recoge
	M1_1 = { dur = 0.32, hit = 0.46, trail = { 0.26, 0.66 }, keys = {
		{ 0, BASE },
		{ 0.26, { W = { -4, -34, 0 }, N = { 0, 28, 0 }, RS = { 30, 0, 26 }, RE = { 125, 0, 0 }, RW = { -70, 0, 0 },
			LS = { 58, 0, -10 }, LE = { 95, 0, 0 }, LW = { -40, 0, 0 } }, "out" },
		{ 0.46, { W = { -12, 38, 0 }, N = { 0, -32, 0 }, RS = { 92, 0, -6 }, RE = { 4, 0, 0 }, RW = { -90, 0, 0 },
			LS = { -12, 0, -18 }, LE = { 72, 0, 0 }, LW = { -20, 0, 0 } }, "in" },
		{ 0.72, { W = { -9, 32, 0 }, N = { 0, -26, 0 }, RS = { 84, 0, 0 }, RE = { 16, 0, 0 }, RW = { -86, 0, 0 },
			LS = { -6, 0, -16 }, LE = { 64, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Puñalada izquierda (espejo): ahora se recoge la derecha
	M1_2 = { dur = 0.32, hit = 0.46, trail = { 0.26, 0.66 }, keys = {
		{ 0, BASE },
		{ 0.26, { W = { -4, 34, 0 }, N = { 0, -28, 0 }, LS = { 30, 0, -26 }, LE = { 125, 0, 0 }, LW = { -70, 0, 0 },
			RS = { 58, 0, 10 }, RE = { 95, 0, 0 }, RW = { -40, 0, 0 } }, "out" },
		{ 0.46, { W = { -12, -38, 0 }, N = { 0, 32, 0 }, LS = { 92, 0, 6 }, LE = { 4, 0, 0 }, LW = { -90, 0, 0 },
			RS = { -12, 0, 18 }, RE = { 72, 0, 0 }, RW = { -20, 0, 0 } }, "in" },
		{ 0.72, { W = { -9, -32, 0 }, N = { 0, 26, 0 }, LS = { 84, 0, 0 }, LE = { 16, 0, 0 }, LW = { -86, 0, 0 },
			RS = { -6, 0, 16 }, RE = { 64, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Tajo en cruz con las dos: se abren arriba y cruzan hacia abajo
	M1_3 = { dur = 0.42, hit = 0.5, trail = { 0.3, 0.72 }, keys = {
		{ 0, BASE },
		{ 0.3, { W = { 10, 0, 0 }, N = { -6, 0, 0 }, RS = { 128, 0, 70 }, RE = { 34, 0, 0 }, RW = { -20, -30, 0 },
			LS = { 128, 0, -70 }, LE = { 34, 0, 0 }, LW = { -20, 30, 0 } }, "out" },
		{ 0.5, { W = { -18, 0, 0 }, N = { 10, 0, 0 }, RS = { 58, 0, -50 }, RE = { 8, 0, 0 }, RW = { -52, 30, 0 },
			LS = { 58, 0, 50 }, LE = { 8, 0, 0 }, LW = { -52, -30, 0 } }, "in" },
		{ 0.76, { W = { -14, 0, 0 }, RS = { 52, 0, -52 }, RE = { 16, 0, 0 }, LS = { 52, 0, 52 }, LE = { 16, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Doble Estocada: se encoge y se lanza con las dos dagas
	Heavy = { dur = 0.71, full = true, windup = 0.48, hit = 0.6, trail = { 0.48, 0.8 }, keys = {
		{ 0, BASE },
		{ 0.48, { W = { 12, 0, 0 }, N = { -8, 0, 0 }, RS = { 22, 0, 26 }, RE = { 112, 0, 0 }, RW = { -60, 0, 0 },
			LS = { 22, 0, -26 }, LE = { 112, 0, 0 }, LW = { -60, 0, 0 },
			R = { 0, 0, 0, 0, -0.45, 0.4 }, RH = { 30, 0, 0 }, RK = { -60, 0, 0 }, LH = { 30, 0, 0 }, LK = { -60, 0, 0 } }, "out" },
		{ 0.6, { W = { -16, 0, 0 }, N = { 8, 0, 0 }, RS = { 86, 0, -4 }, RE = { 0, 0, 0 }, RW = { -90, 0, 0 },
			LS = { 86, 0, 4 }, LE = { 0, 0, 0 }, LW = { -90, 0, 0 },
			R = { 0, 0, 0, 0, -0.55, -1.4 }, RH = { 58, 0, 0 }, RK = { -40, 0, 0 }, LH = { -36, 0, 0 }, LK = { -14, 0, 0 } }, "in" },
		{ 0.82, { W = { -12, 0, 0 }, RS = { 80, 0, 0 }, RE = { 10, 0, 0 }, LS = { 80, 0, 0 }, LE = { 10, 0, 0 },
			R = { 0, 0, 0, 0, -0.45, -1.1 }, RH = { 46, 0, 0 }, RK = { -36, 0, 0 }, LH = { -28, 0, 0 }, LK = { -14, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
}

-- ESTOQUE
A.Rapier = {
	M1_1 = { dur = 0.32, hit = 0.47, trail = { 0.3, 0.66 }, keys = {
		{ 0, BASE },
		{ 0.28, { W = { 0, 54, 0 }, N = { 0, -48, 0 }, RS = { 72, 0, 30 }, RE = { 74, 0, 0 }, RW = { -70, 0, 0 } }, "out" },
		{ 0.47, { W = { -6, 34, 0 }, N = { 0, -30, 0 }, RS = { 86, 0, 40 }, RE = { 0, 0, 0 }, RW = { -90, 0, 0 } }, "in" },
		{ 0.72, { W = { -4, 38, 0 }, N = { 0, -34, 0 }, RS = { 84, 0, 40 }, RE = { 16, 0, 0 }, RW = { -88, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	M1_2 = { dur = 0.32, hit = 0.47, trail = { 0.3, 0.66 }, keys = {
		{ 0, BASE },
		{ 0.28, { W = { 2, 54, 0 }, N = { 0, -48, 0 }, RS = { 96, 0, 26 }, RE = { 80, 0, 0 }, RW = { -60, 0, 0 } }, "out" },
		{ 0.47, { W = { -4, 32, 0 }, N = { 0, -28, 0 }, RS = { 102, 0, 36 }, RE = { 0, 0, 0 }, RW = { -96, 0, 0 } }, "in" },
		{ 0.72, { W = { -2, 36, 0 }, N = { 0, -32, 0 }, RS = { 98, 0, 36 }, RE = { 14, 0, 0 }, RW = { -94, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Estocada a fondo
	M1_3 = { dur = 0.4, full = true, hit = 0.5, trail = { 0.32, 0.7 }, keys = {
		{ 0, BASE },
		{ 0.3, { W = { 2, 56, 0 }, N = { 0, -50, 0 }, RS = { 70, 0, 28 }, RE = { 80, 0, 0 }, RW = { -66, 0, 0 },
			R = { 0, 0, 0, 0, -0.2, 0.3 }, RH = { 10, 0, 0 }, RK = { -20, 0, 0 }, LH = { 0, 0, 0 }, LK = { -26, 0, 0 } }, "out" },
		{ 0.5, { W = { -10, 30, 0 }, N = { 0, -26, 0 }, RS = { 86, 0, 42 }, RE = { 0, 0, 0 }, RW = { -90, 0, 0 },
			LS = { 100, 0, -50 }, LE = { 10, 0, 0 },
			R = { 0, 0, 0, 0, -0.6, -1.6 }, RH = { 64, 0, 0 }, RK = { -50, 0, 0 }, LH = { -42, 0, 0 }, LK = { -6, 0, 0 } }, "in" },
		{ 0.78, { W = { -8, 32, 0 }, RS = { 84, 0, 42 }, RE = { 10, 0, 0 },
			R = { 0, 0, 0, 0, -0.5, -1.3 }, RH = { 54, 0, 0 }, RK = { -46, 0, 0 }, LH = { -34, 0, 0 }, LK = { -6, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Puntada Perforante: retrocede, carga y perfora con todo el cuerpo
	Heavy = { dur = 0.91, full = true, windup = 0.44, hit = 0.56, trail = { 0.44, 0.8 }, keys = {
		{ 0, BASE },
		{ 0.44, { W = { 6, 62, 0 }, N = { 0, -56, 0 }, RS = { 64, 0, 22 }, RE = { 100, 0, 0 }, RW = { -60, 0, 0 },
			LS = { 150, 0, -40 }, LE = { 70, 0, 0 },
			R = { 0, 0, 0, 0, -0.45, 0.6 }, RH = { 20, 0, 0 }, RK = { -40, 0, 0 }, LH = { -10, 0, 0 }, LK = { -50, 0, 0 } }, "inout" },
		{ 0.56, { W = { -14, 26, 0 }, N = { 0, -22, 0 }, RS = { 88, 0, 42 }, RE = { 0, 0, 0 }, RW = { -92, 0, 0 },
			LS = { 90, 0, -60 }, LE = { 6, 0, 0 },
			R = { 0, 0, 0, 0, -0.75, -2.0 }, RH = { 72, 0, 0 }, RK = { -56, 0, 0 }, LH = { -46, 0, 0 }, LK = { -4, 0, 0 } }, "in" },
		{ 0.82, { W = { -10, 28, 0 }, RS = { 86, 0, 42 }, RE = { 8, 0, 0 },
			R = { 0, 0, 0, 0, -0.6, -1.6 }, RH = { 60, 0, 0 }, RK = { -50, 0, 0 }, LH = { -38, 0, 0 }, LK = { -4, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
}

----------------------------------------------------------------------
-- Defensa (comunes a todas las armas; se suman a la postura de guardia)
----------------------------------------------------------------------
AnimClips.Defense = {
	-- Desvío seco del arma hacia fuera
	Parry = { dur = 0.38, additive = true, keys = {
		{ 0, {} },
		{ 0.22, { W = { 6, -18, 0 }, N = { 0, 14, 0 }, RS = { 22, 0, 40 }, RE = { -30, 0, 0 }, RW = { 10, -30, 0 } }, "out" },
		{ 1, {}, "inout" },
	} },
	-- Sacudida al bloquear un golpe
	BlockHit = { dur = 0.26, additive = true, keys = {
		{ 0, {} },
		{ 0.25, { W = { 9, 0, 0 }, N = { 6, 0, 0 }, RS = { -14, 0, 0 }, RE = { 16, 0, 0 }, LS = { -10, 0, 0 } }, "out" },
		{ 1, {}, "inout" },
	} },
}

----------------------------------------------------------------------
-- Genéricas
----------------------------------------------------------------------
local function dodge(rootPose, legs, arms)
	local mid = { R = rootPose }
	for k, v in legs do mid[k] = v end
	for k, v in arms do mid[k] = v end
	return { dur = 0.42, full = true, keys = {
		{ 0, BASE },
		{ 0.12, { R = { 0, 0, 0, 0, -0.25, 0 }, RK = { -38, 0, 0 }, LK = { -38, 0, 0 } }, "in" },
		{ 0.36, mid, "out" },
		{ 0.72, { R = { 0, 0, 0, 0, -0.35, 0 }, RK = { -42, 0, 0 }, LK = { -42, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} }
end

AnimClips.Generic = {
	-- Esquivas: paso rápido y bajo, con el cuerpo inclinado hacia la dirección
	DodgeL = dodge({ 0, 0, 22, -0.9, -0.55, 0 },
		{ RH = { 0, 0, 26 }, RK = { -30, 0, 0 }, LH = { 30, 0, -8 }, LK = { -56, 0, 0 } },
		{ W = { -10, 0, 10 }, RS = { 24, 0, 46 }, LS = { 30, 0, -50 }, LE = { 30, 0, 0 } }),
	DodgeR = dodge({ 0, 0, -22, 0.9, -0.55, 0 },
		{ LH = { 0, 0, -26 }, LK = { -30, 0, 0 }, RH = { 30, 0, 8 }, RK = { -56, 0, 0 } },
		{ W = { -10, 0, -10 }, RS = { 30, 0, 50 }, LS = { 24, 0, -46 }, RE = { 30, 0, 0 } }),
	DodgeF = dodge({ -28, 0, 0, 0, -0.95, -0.5 },
		{ RH = { 64, 0, 0 }, RK = { -80, 0, 0 }, LH = { -10, 0, 0 }, LK = { -60, 0, 0 } },
		{ W = { -18, 0, 0 }, N = { 14, 0, 0 }, RS = { -30, 0, 20 }, LS = { -30, 0, -20 } }),
	DodgeB = dodge({ 16, 0, 0, 0, -0.5, 0.6 },
		{ RH = { 34, 0, 0 }, RK = { -40, 0, 0 }, LH = { -16, 0, 0 }, LK = { -50, 0, 0 } },
		{ W = { 8, 0, 0 }, N = { -6, 0, 0 }, RS = { 40, 0, 20 }, LS = { 40, 0, -20 }, LE = { 40, 0, 0 } }),

	-- Patada frontal rompe-guardias
	Kick = { dur = 0.68, full = true, hit = 0.42, keys = {
		{ 0, BASE },
		{ 0.28, { W = { 8, 0, 0 }, LS = { 30, 0, -34 }, LE = { 40, 0, 0 }, RH = { 54, 0, 0 }, RK = { -96, 0, 0 },
			LK = { -14, 0, 0 }, R = { 0, 0, 0, 0, -0.1, 0.1 } }, "out" },
		{ 0.42, { W = { 18, 0, 0 }, N = { -10, 0, 0 }, LS = { 40, 0, -50 }, LE = { 20, 0, 0 }, RS = { 20, 0, 40 },
			RH = { 84, 0, 0 }, RK = { -4, 0, 0 }, RA = { 24, 0, 0 }, LK = { -18, 0, 0 },
			R = { 0, 0, 0, 0, -0.1, 0.35 } }, "in" },
		{ 0.65, { W = { 10, 0, 0 }, RH = { 40, 0, 0 }, RK = { -50, 0, 0 }, R = { 0, 0, 0, 0, -0.1, 0.15 } }, "out" },
		{ 1, BASE, "inout" },
	} },

	-- Reacciones (se suman a la postura)
	HitReactFront = { dur = 0.4, additive = true, keys = {
		{ 0, {} },
		{ 0.22, { W = { 20, 6, 0 }, N = { 16, 0, 0 }, RS = { -16, 0, 22 }, LS = { -10, 0, -26 }, LE = { 20, 0, 0 } }, "out" },
		{ 1, {}, "inout" },
	} },
	HitReactBack = { dur = 0.4, additive = true, keys = {
		{ 0, {} },
		{ 0.22, { W = { -20, 0, 0 }, N = { -12, 0, 0 }, RS = { 14, 0, 18 }, LS = { 14, 0, -18 } }, "out" },
		{ 1, {}, "inout" },
	} },
	-- Guardia rota: brazos abiertos, tambaleo hacia atrás
	GuardBreakStagger = { dur = 1.3, full = true, keys = {
		{ 0, BASE },
		{ 0.18, { W = { 22, 0, 10 }, N = { 16, 0, 0 }, RS = { 118, 0, 64 }, RE = { 20, 0, 0 }, RW = { 20, 0, 0 },
			LS = { 100, 0, -62 }, LE = { 20, 0, 0 },
			R = { 6, 0, 0, 0, -0.2, 0.5 }, RH = { -18, 0, 0 }, RK = { -20, 0, 0 }, LH = { 24, 0, 0 }, LK = { -30, 0, 0 } }, "out" },
		{ 0.6, { W = { 12, 0, 6 }, N = { 8, 0, 0 }, RS = { 60, 0, 40 }, RE = { 30, 0, 0 }, LS = { 50, 0, -40 }, LE = { 30, 0, 0 },
			R = { 2, 0, 0, 0, -0.25, 0.3 }, RH = { -8, 0, 0 }, RK = { -24, 0, 0 }, LH = { 14, 0, 0 }, LK = { -26, 0, 0 } }, "inout" },
		{ 1, BASE, "inout" },
	} },
	-- Te parrearon: el brazo armado sale despedido hacia atrás
	ParriedStagger = { dur = 1.1, full = true, keys = {
		{ 0, BASE },
		{ 0.15, { W = { 16, -26, 0 }, N = { 6, 20, 0 }, RS = { 160, 0, 44 }, RE = { 22, 0, 0 }, RW = { 30, 0, 0 },
			LS = { 30, 0, -40 }, LE = { 30, 0, 0 },
			R = { 4, 0, 0, 0, -0.15, 0.4 }, RH = { -14, 0, 0 }, RK = { -18, 0, 0 }, LH = { 18, 0, 0 }, LK = { -24, 0, 0 } }, "out" },
		{ 0.6, { W = { 10, -18, 0 }, N = { 4, 14, 0 }, RS = { 130, 0, 40 }, RE = { 30, 0, 0 }, RW = { 20, 0, 0 },
			R = { 2, 0, 0, 0, -0.15, 0.25 }, RK = { -18, 0, 0 }, LK = { -20, 0, 0 } }, "inout" },
		{ 1, BASE, "inout" },
	} },

	-- Levantarse del suelo (tras el ragdoll): de rodillas a de pie
	GetUpBack = { dur = 0.85, full = true, keys = {
		{ 0, { R = { -70, 0, 0, 0, -2.3, 0 }, W = { -20, 0, 0 }, RS = { 70, 0, 20 }, LS = { 70, 0, -20 },
			RH = { 90, 0, 0 }, RK = { -110, 0, 0 }, LH = { 90, 0, 0 }, LK = { -110, 0, 0 } } },
		{ 0.4, { R = { -26, 0, 0, 0, -1.5, 0 }, W = { -14, 0, 0 }, RS = { 50, 0, 20 }, LS = { 40, 0, -20 }, RE = { 30, 0, 0 },
			RH = { 92, 0, 0 }, RK = { -96, 0, 0 }, LH = { 10, 0, 0 }, LK = { -100, 0, 0 } }, "out" },
		{ 0.75, { R = { -8, 0, 0, 0, -0.4, 0 }, W = { -6, 0, 0 }, RH = { 30, 0, 0 }, RK = { -40, 0, 0 }, LH = { 10, 0, 0 }, LK = { -30, 0, 0 } }, "inout" },
		{ 1, BASE, "inout" },
	} },

	-- Alzar al derribado: se agacha, lo engancha y sube (termina en la postura de cargar)
	PickUp = { dur = 0.5, full = true, keys = {
		{ 0, BASE },
		{ 0.45, { R = { -26, 0, 0, 0, -1.25, 0 }, W = { -26, 0, 0 }, N = { 14, 0, 0 },
			RS = { 92, 0, 12 }, RE = { 22, 0, 0 }, LS = { 92, 0, -12 }, LE = { 22, 0, 0 },
			RH = { 74, 0, 0 }, RK = { -94, 0, 0 }, LH = { 74, 0, 0 }, LK = { -94, 0, 0 } }, "out" },
		{ 1, "Carry", "inout" },
	} },
	-- Tirón corto: empujón con los dos brazos
	ThrowShort = { dur = 0.45, full = true, hit = 0.4, keys = {
		{ 0, "Carry" },
		{ 0.25, { W = { 10, 0, 0 }, RS = { 170, 0, 20 }, LS = { 170, 0, -20 }, RE = { 22, 0, 0 }, LE = { 22, 0, 0 },
			R = { 0, 0, 0, 0, -0.2, 0.2 } }, "out" },
		{ 0.4, { W = { -22, 0, 0 }, N = { 10, 0, 0 }, RS = { 100, 0, 10 }, LS = { 100, 0, -10 }, RE = { 8, 0, 0 }, LE = { 8, 0, 0 },
			R = { 0, 0, 0, 0, -0.35, -0.45 }, RH = { 42, 0, 0 }, RK = { -30, 0, 0 }, LH = { -14, 0, 0 } }, "in" },
		{ 0.7, { W = { -14, 0, 0 }, RS = { 70, 0, 10 }, LS = { 70, 0, -10 }, R = { 0, 0, 0, 0, -0.25, -0.3 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Lanzamiento cargado: torsión hacia atrás y latigazo por encima de la cabeza
	ThrowFar = { dur = 0.7, full = true, hit = 0.48, keys = {
		{ 0, "ThrowCharge" },
		{ 0.34, { W = { 16, -42, 0 }, N = { -8, 34, 0 }, RS = { 176, 0, 50 }, RE = { 40, 0, 0 }, LS = { 170, 0, 8 }, LE = { 50, 0, 0 },
			R = { 0, 0, 0, 0, -0.4, 0.4 }, RH = { -22, 0, 0 }, RK = { -20, 0, 0 }, LH = { 32, 0, 0 }, LK = { -42, 0, 0 } }, "out" },
		{ 0.48, { W = { -32, 32, 0 }, N = { 14, -26, 0 }, RS = { 78, 0, -20 }, RE = { 4, 0, 0 }, LS = { 70, 0, -30 }, LE = { 4, 0, 0 },
			R = { 0, 0, 0, 0, -0.5, -1.0 }, RH = { 62, 0, 0 }, RK = { -40, 0, 0 }, LH = { -30, 0, 0 }, LK = { -10, 0, 0 } }, "in" },
		{ 0.76, { W = { -20, 26, 0 }, N = { 8, -20, 0 }, RS = { 50, 0, -20 }, LS = { 46, 0, -30 },
			R = { 0, 0, 0, 0, -0.4, -0.8 }, RH = { 50, 0, 0 }, RK = { -38, 0, 0 }, LH = { -24, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
	-- Palmada para levantar a un aliado
	ReviveSlap = { dur = 0.5, full = true, hit = 0.92, keys = {
		{ 0, BASE },
		{ 0.5, { R = { -14, 0, 0, 0, -1.0, 0 }, W = { -28, 0, 0 }, N = { 14, 0, 0 }, RS = { 132, 0, 22 }, RE = { 30, 0, 0 },
			LS = { 30, 0, -20 }, RH = { 62, 0, 0 }, RK = { -84, 0, 0 }, LH = { 62, 0, 0 }, LK = { -84, 0, 0 } }, "out" },
		{ 0.92, { R = { -18, 0, 0, 0, -1.05, 0 }, W = { -40, 0, 0 }, N = { 18, 0, 0 }, RS = { 40, 0, 12 }, RE = { 8, 0, 0 },
			LS = { 30, 0, -20 }, RH = { 64, 0, 0 }, RK = { -86, 0, 0 }, LH = { 64, 0, 0 }, LK = { -86, 0, 0 } }, "in" },
		{ 1, BASE, "inout" },
	} },
	-- Activar la infusión (Fase C): levanta el arma
	InfuseActivate = { dur = 0.6, keys = {
		{ 0, BASE },
		{ 0.4, { W = { 8, 0, 0 }, N = { -10, 0, 0 }, RS = { 150, 0, 10 }, RE = { 20, 0, 0 }, RW = { 40, 0, 0 } }, "out" },
		{ 1, BASE, "inout" },
	} },
}

----------------------------------------------------------------------
AnimClips.Generic.GetUpFront = { dur = 0.95, full = true, keys = {
 { 0, { R = { 80, 0, 0, 0, -2.2, 0 }, RS = { 85, 0, 15 }, LS = { 85, 0, -15 }, RE = { 85, 0, 0 }, LE = { 85, 0, 0 } } },
 { 0.35, { R = { 40, 0, 0, 0, -1.5, 0 }, RS = { 70, 0, 15 }, LS = { 70, 0, -15 }, RE = { 12, 0, 0 }, LE = { 12, 0, 0 }, RH = { 70, 0, 0 }, RK = { -100, 0, 0 }, LK = { -95, 0, 0 } }, "out" },
 { 0.7, { R = { 12, 0, 0, 0, -0.6, 0 }, RH = { 50, 0, 0 }, RK = { -60, 0, 0 }, LH = { 15, 0, 0 }, LK = { -35, 0, 0 } }, "inout" },
 { 1, BASE, "inout" },
} }

-- Defensa con respuesta propia por arma; conserva los tiempos de combate.
AnimClips.DefenseByArchetype = {}
local defenseScale = {
 OneHand = { torso = 1, arm = 1 },
 TwoHand = { torso = 0.75, arm = 0.65 },
 Hammer = { torso = 1.1, arm = 0.55 },
 Dual = { torso = 0.7, arm = 0.8, mirror = true },
 Rapier = { torso = 0.5, arm = 0.55 },
}
for arch, scale in defenseScale do
 local set = {}
 for name, source in AnimClips.Defense do
  local clip = table.clone(source)
  clip.keys = {}
  for _, key in source.keys do
   local pose = {}
   for joint, angles in key[2] do
    local factor = (joint == "W" or joint == "N") and scale.torso or scale.arm
    pose[joint] = { angles[1] * factor, angles[2] * factor, angles[3] * factor }
   end
   if scale.mirror and pose.RS then
    pose.LS = { pose.RS[1], -pose.RS[2], -pose.RS[3] }
    if pose.RE then pose.LE = table.clone(pose.RE) end
    if pose.RW then pose.LW = { pose.RW[1], -pose.RW[2], -pose.RW[3] } end
   end
   table.insert(clip.keys, { key[1], pose, key[3] })
  end
  set[name] = clip
 end
 AnimClips.DefenseByArchetype[arch] = set
end

----------------------------------------------------------------------
-- Captura de movimiento (Mixamo convertido con tools/mixamo_to_r15.py -> MocapClips)
-- Se mete entre la postura del arma (al principio y al final) para que entre y salga suave.
----------------------------------------------------------------------
local MocapOK, Mocap = pcall(require, script.Parent:WaitForChild("MocapClips", 5))
AnimClips.MocapSettings = { In = 0.07, Out = 0.9, TrailAfterHit = 0.16 }

local function mocap(name)
	local c = MocapOK and Mocap and Mocap[name]
	if not c then return nil end
	local S = AnimClips.MocapSettings
	local span = S.Out - S.In
	local keys = { { 0, BASE } }
	for _, k in c.keys do table.insert(keys, { S.In + k[1] * span, k[2] }) end
	table.insert(keys, { 1, BASE, "inout" })
	local hit, windup = S.In + c.hit * span, S.In + c.windup * span
	return { dur = c.dur / span, full = true, mocap = true, hit = hit, windup = windup,
		trail = { windup, math.min(1, hit + S.TrailAfterHit) }, keys = keys }
end

-- Qué clip de captura reemplaza a cada golpe (por tipo de arma). Los que no figuran siguen procedurales.
AnimClips.MocapMap = {
	TwoHand = { M1_1 = "GS_Slash1", M1_2 = "GS_Slash2", M1_3 = "GS_Slash3", Heavy = "GS_Spin" },
	Hammer = { M1_1 = "GS_Attack", M1_2 = "GS_Slash4", M1_3 = "GS_Slash5", Heavy = "GS_Slash1" },
	OneHand = { M1_1 = "Melee_Backhand", M1_2 = "SwordShield", M1_3 = "Melee_Downward" },
}
AnimClips.MocapGeneric = {
	Kick = { "KickBlock" },
	HitReactFront = { "Impact1", "Impact4", "Impact5" },
	HitReactHeavy = { "Impact2", "Impact3" },
}

local mocapCache = {}
local function mocapCached(name)
	if mocapCache[name] == nil then mocapCache[name] = mocap(name) or false end
	return mocapCache[name] or nil
end

-- Resolución de claves de Assets -> clip
----------------------------------------------------------------------
-- key: "Weapons.Sword.M1_1", "Weapons.Rapier.Parry", "Generic.DodgeL"... ; archetype: de WeaponData
function AnimClips.resolve(key, archetype)
	if not key or key == "" then return nil end
	local w, k = string.match(key, "^Weapons%.(%w+)%.([%w_]+)$")
	if k then
		local mm = AnimClips.MocapMap[archetype or "OneHand"]
		local mclip = mm and mm[k] and mocapCached(mm[k])
		if mclip then return mclip end
		local set = A[archetype or "OneHand"] or A.OneHand
		local defense = AnimClips.DefenseByArchetype[archetype or "OneHand"] or AnimClips.Defense
		return set[k] or defense[k]
	end
	local g = string.match(key, "^Generic%.([%w_]+)$")
	if g then
		local list = AnimClips.MocapGeneric[g]
		if list then
			-- variantes al azar (en el servidor se usa la primera para que los tiempos sean fijos)
			local pick = game:GetService("RunService"):IsServer() and list[1] or list[math.random(#list)]
			local mclip = mocapCached(pick)
			if mclip then return mclip end
		end
		return AnimClips.Generic[g] or (g == "HitReactHeavy" and AnimClips.Generic.HitReactFront) or nil
	end
	return nil
end

return AnimClips
