-- ModuleScript: ReplicatedStorage/CombatConfig
-- Reglas generales de combate (valen para todas las armas). Todo es propuesta a calibrar.
-- Lo específico de cada arma está en WeaponData; lo de infusiones irá en Infusions (Fase C).

local CombatConfig = {}

-- Quién se lleva una eliminación o un derribo: el último que golpeó dentro de esta ventana (s).
-- También cuenta si la víctima cae al vacío después del golpe. Lo usa CombatEvents.
CombatConfig.Credit = {
	Window = 8,
}

-- Proporciones del cuerpo (9/11): más esbelto y menos cuadrado, sin cambiar las articulaciones R15.
-- Se aplican al aparecer (MatchService). Valores de HumanoidDescription.
CombatConfig.Body = {
	Enabled = true,
	Scales = {
		WidthScale = 0.82,      -- 0,7..1: hombros y caderas más angostos
		DepthScale = 0.85,      -- 0,5..1: menos grueso de frente a espalda
		HeightScale = 1.0,
		HeadScale = 0.95,
		BodyTypeScale = 0.35,   -- 0..1: hacia proporciones más realistas
		ProportionScale = 0.6,  -- 0 normal .. 1 esbelto (se nota con BodyTypeScale > 0)
	},
}

-- Los golpes de muñecos no matan al jugador fuera de una partida.
CombatConfig.Practice = {
	MinimumHealth = 1,
}

-- Barras
CombatConfig.Stun = {
	Max = 100,
	DecayDelay = 2.0,     -- segundos sin recibir Stun antes de que empiece a vaciarse
	DecayPerSecond = 45,  -- se vacía rápido
}

CombatConfig.Guard = {
	DefaultMax = 100,          -- si el arma no define guardMax
	RegenDelay = 1.0,          -- segundos sin bloquear golpes antes de regenerar
	RegenPerSecond = 22,
	LightDrainMult = 1.5,      -- Guardia que drena un golpe básico bloqueado = daño * esto
	KickDrain = 999,           -- la patada rompe la guardia pasiva
	BrokenStagger = 0.6,       -- tambaleo corto al romperse la guardia (s)
	BrokenNoBlock = 2.4,       -- ROTURA DE GUARDIA: tiempo sin poder bloquear (s)...
	BrokenStunMult = 1.5,      -- ...durante el cual todo el Stun que recibes se multiplica por esto
	BrokenStunGain = 10,       -- Stun extra en el momento de romperse
	RefillAfterBreak = 0.5,    -- fracción de Guardia con la que se recupera tras romperse
}

CombatConfig.Block = {
	ArcDot = 0.1,              -- el bloqueo cubre lo que viene de frente (dot > esto)
	WalkSpeed = 7,             -- velocidad mientras bloqueas
	ParryWindow = 0.22,        -- s tras pulsar F en las que un golpe se parrea
	WhiffLock = 0.35,          -- si sueltas F dentro de la ventana sin parrear, no puedes volver a pulsar en este tiempo
	BlockHitStagger = 0.15,    -- micro-pausa del que bloquea al recibir un golpe
}

CombatConfig.Parry = {
	AttackerStagger = 0.45,    -- el ataque se detiene y el atacante se tambalea poco (s): no queda indefenso
	AttackerStunGain = 12,     -- Stun que recibe el atacante parreado
	DefenderInvuln = 0.2,      -- invulnerabilidad breve del que parrea
	PushBack = 12,             -- empuje al atacante
	CounterWindow = 0.7,       -- ventaja: el siguiente golpe del que parreó dentro de este tiempo...
	CounterDamageMult = 1.2,   -- ...hace este daño extra (contraataque)
	InfusionCharge = 10,       -- carga de infusión por parry
}

-- Movimiento general: multiplica la velocidad base de todas las armas
CombatConfig.Movement = {
	SpeedMult = 1.15,          -- +15% respecto a WeaponData.speed
}

CombatConfig.Dodge = {
	IFrames = 0.25,            -- invulnerabilidad (s)
	Duration = 0.24,           -- duración del desplazamiento (s). Etapa 8: era 0.28
	Distance = 12,             -- studs recorridos. Etapa 8: era 16 (-25 %); se sentía demasiado largo
	Cooldown = 0.5,            -- desde el inicio de una esquiva hasta poder hacer otra (9/11: era 0.65)
	Recovery = 0.05,           -- tras el desplazamiento, breve momento sin atacar (9/11: era 0.12)
	-- 9/11: combate más ágil. La esquiva cancela la recuperación de un golpe básico o de la patada
	-- (después del impacto), y un M1 pulsado durante la esquiva sale apenas termina.
	CancelsRecovery = true,
	CancelsHeavy = true,       -- esquivar cancela la preparación del fuerte (finta)
	AfterSlowMult = 0.8,       -- al terminar el dash: velocidad reducida... (9/11: era 0.6)
	AfterSlowTime = 0.25,      -- ...durante este tiempo (s) (9/11: era 0.35)
	-- Con objetivo fijado (etapa 8): el dash lateral orbita alrededor del objetivo y lo sigue mirando
	LockOrbit = true,
	LockMinRadius = 3.5,       -- no se acerca más que esto al objetivo (no lo atraviesa)
	LockRadiusHold = 10,       -- fuerza con la que mantiene la distancia en el dash lateral
	LockFollow = 1,            -- cuánto de la velocidad del objetivo se suma (1 = lo sigue)
}

CombatConfig.Kick = {
	Windup = 0.28, Recovery = 0.4, Cooldown = 1.4,
	Damage = 4, Stun = 18, Knockback = 18,
	Reach = 5, Width = 3.5,
	Parryable = false,         -- la patada no se parrea: se esquiva
}

CombatConfig.Attack = {
	ComboResetTime = 0.9,      -- s tras terminar un golpe para seguir el combo
	BufferWindow = 0.35,       -- si pulsas M1 en los últimos X s de un golpe o esquiva, se encola el siguiente (9/11: era 0.25)
	MoveSpeedMult = 0.55,      -- velocidad mientras atacas
	HitStagger = 0.22,         -- aturdimiento corto al recibir un golpe (interrumpe preparación)
	HeavyHitStagger = 0.45,
	HeavyFeintCutoff = 0.85,   -- solo se puede fintar antes de este % de la preparación
	BoxHeight = 5,             -- altura de la caja de golpe (ajustada al R15)
	BoxCenterY = 0.3,          -- centro de la caja respecto al HumanoidRootPart
	HeavyCooldown = 0.4,       -- tras terminar un fuerte, espera mínima para otro
}

CombatConfig.Knockdown = {
	StunDuration = 4,          -- derribo por Stun (ragdoll temporal)
	ImmuneAfter = 2.0,         -- inmunidad a otro derribo tras levantarse
	Knockback = 30,
	MashReduce = 0.15,         -- cada pulsación (Espacio / clic / botón) quita estos segundos
	MinDown = 1.2,             -- mínimo en el suelo aunque machaques
}

-- Agarrar, cargar al hombro y lanzar
CombatConfig.Grab = {
	Range = 7,
	PickUpTime = 0.6,          -- alzarlo por encima de la cabeza
	CarryHeight = 3.1,         -- altura del cargado sobre el torso de quien carga (brazos arriba)
	CarryForward = -0.2,       -- adelante (-) / atrás (+) respecto al torso
	LiftBlend = 0.3,           -- segundos que tarda en subir del suelo a la posición de carga
	ReleaseNoCollide = 0.28,   -- tras lanzar, el cuerpo no choca con quien lo lanzó durante este tiempo
	CarrySpeedMult = 0.6,      -- -40% de velocidad cargando (etapa 8: era 0.8)
	ChargeSpeedMult = 0.45,    -- aún más lento mientras cargas el lanzamiento (etapa 8: era 0.6)
	MaxCarryTime = 4.5,        -- si no lo lanzas, se libera solo
	StruggleReduce = 0.18,     -- cada pulsación del cargado le acerca la liberación
	ChargeTime = 1.0,          -- segundos para cargar el lanzamiento al máximo
	ThrowShortTime = 0.45, ThrowFarTime = 0.7,
	-- Etapa 8: velocidades x0,84 (alcance ~ v², unos -30 % de distancia). Antes: corto 34, lejano 46 + 34 x carga (máx. 80)
	ShortSpeed = 29, ShortAngle = 20, ShortDamage = 5,
	-- 9/11: lanzamiento cargado más corto (antes 39 + 28 × carga, máx. 67): ~40 % menos de distancia al máximo
	FarSpeed = 36, FarSpeedCharged = 16, FarAngle = 30, FarDamage = 8, FarDamageCharged = 6, -- máx. 52
	LandGetUp = 1.3,           -- tiempo en el suelo tras aterrizar (además del vuelo)
	DropGetUp = 1.0,           -- si te sueltan (golpe al que carga)
	EscapeGetUp = 0.5,         -- si te liberas forcejeando
}

-- Palmada para levantar a un aliado derribado por Stun (R junto a él)
CombatConfig.Revive = {
	SlapTime = 0.5,            -- canalización; un golpe la interrumpe
	Range = 7,
}

-- Stamina: la gastan la esquiva, los golpes básicos, el fuerte y la patada.
-- Etapa 8: el gasto de los golpes depende del arma (WeaponData.Stamina); Heavy y M1 de acá son el respaldo.
CombatConfig.Stamina = {
	Max = 100,
	RegenDelay = 0.8,          -- s sin gastar antes de regenerar
	RegenPerSecond = 30,
	BlockRegenMult = 0.35,     -- 9/11: bloqueando, la stamina se regenera a este ritmo (35 %)
	Dodge = 30,
	Heavy = 20,
	Kick = 15,
	M1 = 0,
	DummiesUseStamina = false, -- los muñecos de práctica no se cansan
}

CombatConfig.Hitstop = {
	Heavy = 0.12,
	Parry = 0.15,
	GuardBreak = 0.1,
	Light = 0.05,              -- micro-pausa en golpes básicos: da peso al impacto
	Speed = 0.03,              -- velocidad de la animación durante el hitstop
}

-- Sacudida de cámara (0..1 de "trauma"; se suma y decae)
CombatConfig.CameraShake = {
	Light = 0.22, Heavy = 0.55, Parry = 0.45, GuardBreak = 0.6, Knockdown = 0.7,
	Decay = 1.8,               -- trauma que se pierde por segundo
	MaxOffset = 0.9,           -- studs de desplazamiento con trauma 1
	MaxRoll = 3.5,             -- grados de giro con trauma 1
	Kick = 0.45,               -- empujón de cámara en la dirección del golpe (studs)
}

-- Vibración del mando en los impactos (0 = apagado)
CombatConfig.Haptics = { Light = 0.25, Heavy = 0.7, Parry = 0.5, Duration = 0.12 }

-- Carga de infusión (decisión 1). Se moverá a Infusions.lua en la Fase C.
CombatConfig.InfusionCharge = {
	Max = 100,
	DealtMult = 1.2,
	TakenMult = 0.8,
	MaxPerHit = 15,
}

-- Controles
-- Cámara: sin zoom, en picada y con el personaje un poco a la izquierda
CombatConfig.Camera = {
	Distance = 15,             -- distancia fija (no se puede acercar ni alejar)
	Pitch = 24,                -- grados mirando hacia abajo
	OffsetX = 1.7,             -- studs a la derecha (el personaje queda a la izquierda)
	FocusHeight = 1.8,         -- altura del punto que sigue sobre el HumanoidRootPart
	LockPitch = 20,            -- picada con el objetivo fijado
}

CombatConfig.Controls = {
	-- M2 como alias del fuerte. Solo actúa con el objetivo fijado o con el ratón bloqueado,
	-- para no disparar fuertes al girar la cámara con el clic derecho.
	HeavyOnMouse2 = true,
	-- clic derecho asignado con el ratón libre: toque corto = acción, arrastre = cámara
	Mouse2Tap = { MaxTime = 0.3, MaxMove = 8 },
	LockOnRange = 28,          -- 9/11: solo se fija un objetivo cercano (antes 120)
	LockOnSmoothing = 17,
	LockOnBreakRange = 40,     -- se suelta si se aleja más de esto (antes 150)
	MatchLockRange = 220,      -- 9/11: en partida el rival se fija solo al entrar y no se suelta por distancia dentro de la arena
}

-- Herramientas de depuración (Fase 0). En Studio siempre están permitidas.
CombatConfig.Debug = {
	AllowInLiveGame = false,   -- true = cualquier jugador puede usarlas en el juego publicado (¡solo para pruebas!)
	AllowedUserIds = {},       -- IDs con permiso en el juego publicado (además del creador)
	DummyRespawn = 3,
	DummyHealDelay = 4,        -- el muñeco se cura entero tras X s sin recibir daño
	DummyReaction = 0.12,      -- reacción mínima del muñeco ante un ataque (s)
}

return CombatConfig
