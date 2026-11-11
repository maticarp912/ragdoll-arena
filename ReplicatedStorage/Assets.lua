-- ModuleScript: ReplicatedStorage/Assets
-- Contrato de assets: TODOS los IDs del juego viven aquí. El código nunca lleva IDs sueltos.
-- Flujo: subir el asset a Roblox (con tu cuenta o grupo) -> copiar el ID -> pegarlo aquí.
-- ID = 0  ->  se usa el placeholder (animación por defecto, silencio, partes simples).
--
-- Claves = las de ASSETS_LISTA.md. No las renombres.
-- Marcadores de animación esperados: Hit, WindupEnd, Release, Slap.

local Assets = {}

local function weaponAnims()
	return { Idle = 0, Block = 0, BlockHit = 0, Parry = 0, M1_1 = 0, M1_2 = 0, M1_3 = 0, Heavy = 0 }
end

Assets.Animations = {
	Generic = {
		DodgeF = 0, DodgeB = 0, DodgeL = 0, DodgeR = 0,
		Kick = 0,
		HitReactFront = 0, HitReactBack = 0,
		GuardBreakStagger = 0, ParriedStagger = 0, StunLoop = 0,
		KnockdownFall = 0, GetUpFront = 0, GetUpBack = 0, Crawl = 0,
		PickUp = 0, CarryIdle = 0, CarryWalk = 0, ThrowShort = 0, ThrowFar = 0,
		ReviveChannel = 0, ReviveSlap = 0,
		InfuseActivate = 0,
		Victory = 0, Defeat = 0,
	},
	Weapons = {
		Sword = weaponAnims(),
		Greatsword = weaponAnims(),
		Dagger = weaponAnims(),
		Rapier = weaponAnims(),
		Mace = weaponAnims(),
	},
}

-- Sonidos: un número o una lista de variantes { id1, id2, id3 } (se elige una al azar).
local function infusionSounds()
	return { Start = 0, Loop = 0, Hit = 0, End = 0 }
end

-- IDs públicos de la Creator Store, usables en cualquier experiencia:
--   ProSoundEffects (librería con licencia de Roblox), Roblox (UI), APMOfficial / DistroKid (música).
-- Para cambiar uno: pega otro ID. 0 o {} = silencio.
local SWING_LIGHT = { 9120704709, 9120704978, 9120742716 }   -- Whooshes rápidos
local SWING_THIN = { 9120972444, 9120972457, 9120972323 }    -- Whoosh fino (estoque, dagas)
local SWING_HEAVY = { 9120728815, 9120728883, 9120729007 }   -- Whoosh pesado

Assets.Sounds = {
	-- 3.1 Ataques
	Swing = {
		Sword = { Light = SWING_LIGHT, Heavy = SWING_HEAVY },
		Greatsword = { Light = SWING_HEAVY, Heavy = { 9113077334, 9120729339 } },
		Dagger = { Light = SWING_THIN, Heavy = SWING_LIGHT },
		Rapier = { Light = SWING_THIN, Heavy = SWING_LIGHT },
		Mace = { Light = SWING_HEAVY, Heavy = { 9113077334, 9120729339 } },
	},
	Cue_HeavyWindup = { 9119744718, 9119744642 },  -- "shing" metálico corto
	Cue_Unblockable = 9119707097,                   -- swoosh invertido (aviso rojo)

	-- 3.2 Impactos y defensa
	Hit_Light = { 9119748927, 9119749037, 9116197520, 9116197517 }, -- estocadas/tajos en carne
	Hit_Heavy = { 9116490163, 9118167124, 9113502506 },             -- golpes contundentes
	Hit_Blunt = { 9125672726, 9116490163 },                          -- martillo
	Hit_Knockdown = { 9113480915, 9113469292 },
	BlockHit_Light = { 9119072660, 9119072674, 9113449585 },         -- metal contra metal
	BlockHit_Heavy = { 9125362690, 9113133597 },
	Parry = { 9113132724, 9113132828 },                              -- choque metálico agudo
	ParrySpark = 9119742466,
	GuardBreak = { 9116673678, 9116546593 },
	Kick_Swing = 9120729339, Kick_Hit = { 9113564874, 9113513328 },
	Dodge = SWING_LIGHT, -- 10/11: whoosh de aire corto (librería), más grave y suave que un tajo; antes era swing_pesado_2 con ruido

	-- 3.3 Derribo, agarre y rescate
	Body_Fall = { 9113480915, 9113469292, 9113475819 }, Crawl_Loop = 0, GetUp = { 9113534108 },
	PickUp = 9113534108, Carry_Loop = 0,
	Throw_Short = 9120728883, Throw_Far = 9113077334, Throw_Impact = { 9113475819, 9113480915 },
	Revive_Loop = 0, Revive_Done = 0, Revive_Slap = 9113513328,
	RingOut_FallWind_Loop = 0, RingOut_Sting = 0, Intercept_Save = 0,

	-- 3.4 Arena
	Tile_Warning = { 9118689425 }, Tile_Crumble = { 9118692390, 9118664167 }, Tile_Fall_Distant = {},
	Arena_Rumble_Loop = 0, Ambient_Arena_Loop = 9113286782, Ambient_Lobby_Loop = 9113286782,
	Round_StartHorn = 9114821067,

	-- 3.5 Infusiones y estados (Fase C)
	Infusion = {
		Fire = infusionSounds(), Lightning = infusionSounds(), Blood = infusionSounds(),
		Ice = infusionSounds(), Poison = infusionSounds(), Shadow = infusionSounds(),
	},
	Status_BurnTick = 0, Status_BleedTick = 0, Status_PoisonTick = 0,
	Status_ShockZap = 0, Status_SlowFreeze = 0,
	Status_Mark = 0, Status_Fragile = 0, Status_Weakened = 0, Status_Corrode = 0,
	Infusion_MeterFull = 9113804401, Infusion_Exhausted = 0,

	-- 3.6 Interfaz y partida
	UI_Click = 10128760939, UI_Hover = 10066931761, UI_TabSwitch = 10128766965,
	UI_MenuOpen = 10066968815, UI_MenuClose = 10066914500,
	UI_Equip = 9119742750, UI_Error = 10066926605, UI_Notification = 10066968815,
	UI_PurchaseOK = { 10066947742, 9113728756 }, UI_PurchaseFail = 10066926605,
	UI_UnlockFanfare = 0, UI_LevelUp = 0, UI_XPGain = 0, UI_CoinGain = 9113728756,
	Match_Found = 9113804401, Countdown_3 = 9119717529, Countdown_2 = 9119717529, Countdown_1 = 9119717529,
	Countdown_Go = 9114821067,
	Round_Win = 9113804401, Round_Lose = 9113804401, Match_Win = 9113804573, Match_Lose = 9114352428,
	Timer_Warning = 0,

	-- 3.7 Música
	Music_Lobby_Loop = 139743346356072,   -- "Forgotten Crypt Ambient" (DistroKid)
	Music_Battle_Loop = 136168796475546,  -- "Run (Medieval Dark Ambient)" (DistroKid)
	Music_Victory_Sting = 0, Music_Defeat_Sting = 0,
}

-- SFX ELEGIDOS POR EL USUARIO (F:\RobloxJuegos\sfx, copias con nombre limpio en sfx_subir\).
-- Tienen prioridad: si un archivo tiene id, suena él en sus claves (Priority = probabilidad;
-- el resto de las veces suena una variante de la librería para que no se repita siempre igual).
-- Para activarlos: subir cada archivo a Roblox (Creator Hub > Audio) y pegar su ID en id.
-- region = { inicio, fin } en segundos para usar solo un tramo de un archivo largo.
Assets.Custom = {
	Priority = 0.8,
	-- Bajo estos sonidos propios suena también una variante de la librería, a este volumen relativo
	Layers = { Hit_Heavy = 0.45, Hit_Knockdown = 0.5, Hit_Blunt = 0.4, GuardBreak = 0.4, Parry = 0.3, Throw_Impact = 0.4 },
	Files = {
		{ file = "swing_corte_espada.mp3", id = 93877443722238, keys = { "Swing.Sword.Light", "Swing.Sword.Heavy", "Swing.Dagger.Light", "Swing.Dagger.Heavy", "Swing.Greatsword.Light" } },
		{ file = "swing_estoque.mp3", id = 119825603106581, keys = { "Swing.Rapier.Light", "Swing.Rapier.Heavy" }, region = { 0, 1.2 } }, -- archivo de 10 s: ajustar tramo
		{ file = "swing_pesado.mp3", id = 129083719160056, keys = { "Swing.Greatsword.Heavy", "Swing.Mace.Light", "Swing.Mace.Heavy", "Cue_HeavyWindup" } }, -- "sfx animation"
		{ file = "swing_pesado_2.mp3", id = 136483486196947, keys = { "Throw_Far" }, region = { 0, 1.5 } }, -- "sfx animation 2" (12 s). 10/11: ya no suena en el dash
		{ file = "golpe_espada.mp3", id = 138156964972112, keys = { "Hit_Light" } },
		{ file = "golpe_espada_2.mp3", id = 71796772336933, keys = { "Hit_Light", "Hit_Heavy" } },
		{ file = "golpe.mp3", id = 88283526744383, keys = { "Hit_Blunt", "Kick_Hit" } },
		{ file = "golpe_2.mp3", id = 123491203357883, keys = { "Hit_Blunt", "Kick_Hit", "Revive_Slap" } },
		{ file = "impacto_fuerte.mp3", id = 128186008564818, keys = { "Hit_Heavy", "Hit_Knockdown", "GuardBreak", "Throw_Impact" } },
		{ file = "impacto_suelo.mp3", id = 90091734516108, keys = { "Body_Fall", "Throw_Impact", "Tile_Crumble" } },
		{ file = "espada_bloqueada.mp3", id = 123096207909439, keys = { "BlockHit_Light", "BlockHit_Heavy" } },
		{ file = "espada_parry.mp3", id = 134610646419214, keys = { "Parry" } },
		{ file = "fuego.mp3", id = 83665036768188, keys = { "Infusion.Fire.Start", "Infusion.Fire.Loop" } }, -- 60 s: sirve de loop
		{ file = "hielo.mp3", id = 135505570907573, keys = { "Infusion.Ice.Start", "Infusion.Ice.Hit" } },
		{ file = "rayo.mp3", id = 137660112908456, keys = { "Infusion.Lightning.Start" } },
		{ file = "rayo_golpe.mp3", id = 73167738871819, keys = { "Infusion.Lightning.Hit" } },
		{ file = "sombra.mp3", id = 118890172653742, keys = { "Infusion.Shadow.Start" } },
		{ file = "sombra_golpe.mp3", id = 124809299969027, keys = { "Infusion.Shadow.Hit" } },
	},
}

-- Ajustes por sonido (clave = primer tramo de la ruta). volume, pitch, var = variación aleatoria de tono
Assets.SoundSettings = {
	Swing = { volume = 0.55, pitch = 1.05, var = 0.08 },
	Cue_HeavyWindup = { volume = 0.9, pitch = 0.9, var = 0.03 },
	Cue_Unblockable = { volume = 1, pitch = 0.75, var = 0 },
	Hit_Light = { volume = 0.75, pitch = 1, var = 0.1 },
	Hit_Heavy = { volume = 0.95, pitch = 0.85, var = 0.08 },
	Hit_Blunt = { volume = 0.95, pitch = 0.8, var = 0.06 },
	Hit_Knockdown = { volume = 1, pitch = 0.9, var = 0.05 },
	BlockHit_Light = { volume = 0.6, pitch = 1.1, var = 0.1 },
	BlockHit_Heavy = { volume = 0.8, pitch = 0.95, var = 0.06 },
	Parry = { volume = 1, pitch = 1.15, var = 0.05 },
	ParrySpark = { volume = 0.6, pitch = 1.3, var = 0.05 },
	GuardBreak = { volume = 1, pitch = 0.9, var = 0.05 },
	Kick_Swing = { volume = 0.5, pitch = 1.1, var = 0.05 },
	Kick_Hit = { volume = 0.9, pitch = 0.8, var = 0.08 },
	Dodge = { volume = 0.32, pitch = 0.78, var = 0.06 }, -- whoosh de cuerpo: más grave que el tajo del arma
	Body_Fall = { volume = 0.9, pitch = 1, var = 0.08 },
	Throw_Impact = { volume = 1, pitch = 0.85, var = 0.08 },
	Throw_Far = { volume = 0.8, pitch = 0.9, var = 0.05 },
	UI_Click = { volume = 0.5 }, UI_Hover = { volume = 0.25 }, UI_TabSwitch = { volume = 0.4 },
	Ambient_Lobby_Loop = { volume = 0.25 }, Ambient_Arena_Loop = { volume = 0.25 },
	Music_Lobby_Loop = { volume = 0.2 }, Music_Battle_Loop = { volume = 0.22 },
}

function Assets.soundSettings(path)
	local first = string.match(path, "^[^%.]+")
	return Assets.SoundSettings[first] or {}
end

-- Modelos de arma. Dos formas de enchufarlos (la primera que exista gana):
--   1) Un Tool o Model con el nombre de la clave dentro de ServerStorage/Weapons
--      (con Handle y Attachments GripPoint, BladeBase, BladeTip).
--   2) Un ID de MeshPart aquí (MeshId) + TextureId opcional.
Assets.Models = {
	Weapons = {
		Sword = { MeshId = 0, TextureId = 0 },
		Greatsword = { MeshId = 0, TextureId = 0 },
		Dagger = { MeshId = 0, TextureId = 0 },   -- Dagger_R / Dagger_L comparten malla
		Rapier = { MeshId = 0, TextureId = 0 },
		Mace = { MeshId = 0, TextureId = 0 },
	},
}

-- Texturas de VFX e iconos (decals/imágenes)
Assets.VFX = {
	ParryFlash = 0, ParrySparks = 0, GuardBreak = 0,
	TelegraphOrange = 0, TelegraphRed = 0,
	SlashArc = { Sword = 0, Greatsword = 0, Dagger = 0, Rapier = 0, Mace = 0 },
	HitSparkLight = 0, HitSparkHeavy = 0,
	DustKnockdown = 0, LockOnReticle = 0,
}

Assets.Icons = {
	Weapons = { Sword = 0, Greatsword = 0, Dagger = 0, Rapier = 0, Mace = 0 },
	Infusions = { Fire = 0, Lightning = 0, Blood = 0, Ice = 0, Poison = 0, Shadow = 0 },
	Status = {},
	Keys = { F = 0, E = 0, R = 0, Q = 0, T = 0, Y = 0, Shift = 0, Space = 0, MouseLeft = 0, MouseRight = 0 },
}

----------------------------------------------------------------------
-- Ayudantes (no tocar)
----------------------------------------------------------------------

-- Busca una ruta tipo "Weapons.Sword.M1_1" dentro de una tabla.
local function lookup(root, path)
	local node = root
	for part in string.gmatch(path, "[^%.]+") do
		if type(node) ~= "table" then return nil end
		node = node[part]
	end
	return node
end

local function toContent(id)
	if type(id) == "string" then
		if id == "" or id == "0" then return nil end
		if string.find(id, "://", 1, true) then return id end
		return "rbxassetid://" .. id
	end
	if type(id) == "number" and id > 0 then
		return "rbxassetid://" .. tostring(id)
	end
	return nil
end
Assets.toContent = toContent

-- Devuelve "rbxassetid://..." de una animación, o nil si es placeholder.
-- Ejemplo: Assets.anim("Weapons.Sword.M1_1") / Assets.anim("Generic.DodgeF")
function Assets.anim(path)
	return toContent(lookup(Assets.Animations, path))
end

-- Índice clave -> archivos propios con ID
local customByKey = {}
for _, f in Assets.Custom.Files do
	local c = toContent(f.id)
	if c then
		for _, key in f.keys do
			customByKey[key] = customByKey[key] or {}
			table.insert(customByKey[key], { content = c, region = f.region })
		end
	end
end

-- Tramo a reproducir de un sonido propio (o nil = entero)
local lastRegion, isOwn = {}, {}
for _, list in customByKey do for _, o in list do isOwn[o.content] = true end end
function Assets.soundRegion(content)
	return lastRegion[content]
end
function Assets.isCustom(content)
	return isOwn[content] == true
end

-- Solo la librería (sin los propios): para las capas
function Assets.librarySound(path)
	local v = lookup(Assets.Sounds, path)
	if type(v) == "table" then
		local valid = {}
		for _, id in v do
			local c = toContent(id)
			if c then table.insert(valid, c) end
		end
		return #valid > 0 and valid[math.random(#valid)] or nil
	end
	return toContent(v)
end

-- Devuelve el content id de un sonido (elige variante si es lista), o nil.
-- Los SFX propios (Assets.Custom) tienen prioridad.
function Assets.sound(path)
	local own = customByKey[path]
	if own and #own > 0 then
		local fallback = lookup(Assets.Sounds, path)
		if not fallback or fallback == 0 or math.random() < Assets.Custom.Priority then
			local pick = own[math.random(#own)]
			lastRegion[pick.content] = pick.region
			return pick.content
		end
	end
	local v = lookup(Assets.Sounds, path)
	if type(v) == "table" then
		local valid = {}
		for _, id in v do
			local c = toContent(id)
			if c then table.insert(valid, c) end
		end
		if #valid == 0 then return nil end
		return valid[math.random(#valid)]
	end
	return toContent(v)
end

function Assets.image(path)
	return toContent(lookup(Assets, path))
end

-- Lista plana de todas las claves de animación (para el AnimTester)
function Assets.listAnimations()
	local out = {}
	local generic = {}
	for k in Assets.Animations.Generic do table.insert(generic, k) end
	table.sort(generic)
	for _, k in generic do table.insert(out, "Generic." .. k) end
	local weapons = {}
	for w in Assets.Animations.Weapons do table.insert(weapons, w) end
	table.sort(weapons)
	for _, w in weapons do
		for _, k in { "Idle", "Block", "BlockHit", "Parry", "M1_1", "M1_2", "M1_3", "Heavy" } do
			table.insert(out, "Weapons." .. w .. "." .. k)
		end
	end
	return out
end

return Assets
