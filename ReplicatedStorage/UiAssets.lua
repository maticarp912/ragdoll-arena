-- ModuleScript: ReplicatedStorage/UiAssets
-- Catálogo de IDs de imágenes subidas a Roblox y generador de iconos de respaldo dibujados con Frames
-- (Regla 4: imagen sin subir = 0, con respaldo dibujado con frames o texto).
-- Incluye las 4 insignias de infusión reversionadas (Fuego, Rayo, Hielo, Sombra) e ilustraciones temáticas
-- para las tarjetas verticales estilo referencias\infusiones ref2.jpg.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme", 10))

local UiAssets = {}

----------------------------------------------------------------------
-- 1. IDs de imágenes en Roblox (0 = usar respaldo procedural hasta subir los PNG de ui_assets/)
----------------------------------------------------------------------
UiAssets.Ids = {
	infusion_fire      = 98108965227022,
	infusion_lightning = 91017839053016,
	infusion_ice       = 74993689207241,
	infusion_shadow    = 115593789424085,
	coin               = 0,
	robux              = 0,
	rarity_common      = 131226750677691,
	rarity_rare        = 89294555509656,
	rarity_epic        = 129863316909924,
	rarity_legendary   = 127635052618810,
	rarity_mythic      = 98296435471760,
	mission            = 133623637778999,
	trophy             = 136349065744162,
	skull              = 86377107640527,
	knockdown          = 128311218795352,
	settings           = 77685706747835,
	armory             = 124633247653330,
	ranked             = 71137851432656,
	aura               = 0,
	aura_crown         = 136086513621503,
	aura_chains        = 116185918507221,
	aura_wings         = 109214059690456,
	aura_mist          = 132413137974881,
	aura_eyes          = 112605069209050,
	aura_runes         = 109774474771026,
	aura_drip          = 131373499791124,
	aura_embers        = 115762454736544,
	aura_blood         = 136282213639075,
	aura_fracture      = 74549041831811,
	health             = 139933301616232,
	stamina            = 140179622776190,
	guard              = 134517700676170,
	stun               = 104566802498854,
	attack             = 92397119386979,
	heavy              = 107605541113614,
	block              = 94205575739714,
	dodge              = 126727775856538,
	kick               = 126659133151194,
	interact           = 116198625062555,
	lockon             = 93147386926972,
	switch_target      = 119801881211413,

	-- 11/11/2026: arte del usuario (Referencias 0.2/Arte interfaz). Pegar acá el ID de cada imagen subida.
	-- Con 0 se usa el ícono dibujado de antes. Para retirar TODO el arte de una vez: UiAssets.UseArt = false.
	soul               = 134654221859108, -- icono_alma.png        (almas)
	gem                = 78823117403465, -- icono_moneda.png      (monedas)
	amulet             = 106423441679908, -- icono_amuleto.png     (amuleto de suerte)
	lock               = 85115316891177, -- icono_candado.png     (Skip bloqueado)
	skip               = 76314126269519, -- icono_skip.png        (Skip)
	vip                = 92539242850581, -- icono_vip.png         (corona VIP)
	frame_obsidian     = 134211523830539, -- marco_obsidiana.png   (marco de panel, todavía sin usar)
	pack_gems_400      = 96155066678089, -- pack_monedas_0400.png
	pack_gems_850      = 116253031835080, -- pack_monedas_0850.png
	pack_gems_2200     = 80218170316347, -- pack_monedas_2200.png
	pack_gems_4600     = 90077279241401, -- pack_monedas_4600.png
	pack_gems_10000    = 131416292676315, -- pack_monedas_10000.png
	pack_spins_3       = 75417800650244, -- pack_ruleta_3_tiros.png
	pass_skip          = 120398082207425, -- pase_skip_aperturas.png
	pass_vip           = 108842582911580, -- pase_vip_eclipse.png
	-- 11/11/2026: claves nuevas listas para el arte (ver Notas/Arte - lista de imágenes.md)
	boost_souls        = 123471410469112, -- multiplicador ×2 de almas
	boost_xp           = 74738766081022, -- multiplicador ×2 de XP
	boost_magnet       = 74588142879948, -- imán de almas
	shop               = 87987182061269, -- botón Tienda del lobby
	rewards            = 137580237006433, -- botón Recompensas del lobby
	leaderboard        = 77265873799987, -- botón Clasificación del lobby
	-- 11/11/2026 (tanda 3): guardia rota y recursos de HUD de plata clásica (marcos todavía sin conectar)
	guard_broken = 93659499765234,
	hud_bar_red = 121288131222477, hud_bar_cyan = 114096602913235, hud_bar_blue = 115799578034954, hud_bar_05 = 94464479484599,
	frame_avatar = 98703661478369, frame_arch = 128983919450093,
	frame_classic_1 = 115146949745382, frame_classic_2 = 109248225662281, frame_classic_3 = 111357391303578,
	frame_classic_4 = 119928089104368, frame_classic_5 = 118714582114035,
	border_dark_1 = 108420885024617, border_dark_2 = 88938737242151,
	corner_classic_tl = 95600733860151, corner_classic_tr = 98692641434464, -- esquina_clasica_01 y 02
	corner_classic_bl = 78148340074076, corner_classic_br = 122947440560620, -- esquina_clasica_03 y 04
	separator_classic_1 = 117795436187814, separator_classic_2 = 73562321296609, separator_classic_3 = 102087210021827,
	ornament_side_1 = 73138940308028, ornament_side_2 = 117707830823722, ornament_side_3 = 81933802141293, ornament_side_4 = 139928985111950,
	-- Cofres del 1 al 6, cerrado y abierto (subidos el 11/11)
	chest_1_closed     = 117493290127703, chest_1_open = 131124602014011, -- hierro
	chest_2_closed     = 112102957287363, chest_2_open = 81121421030094,  -- plata
	chest_3_closed     = 81738317245230,  chest_3_open = 133906942535835, -- verdín
	chest_4_closed     = 102803368763178, chest_4_open = 91502582109751,  -- violeta
	chest_5_closed     = 82406256229173,  chest_5_open = 86978747416585,  -- oro
	chest_6_closed     = 111801149076401, chest_6_open = 86485483140880,  -- eclipse
}

-- Interruptor general del arte nuevo: false = todo vuelve a los íconos dibujados (para probar y retirar).
UiAssets.UseArt = true
-- Las esquinas de plata de las ventanas las dibuja UiTheme (no puede leer este módulo): se apagan con el mismo interruptor
UiTheme.CornerArt.Enabled = UiAssets.UseArt

-- Arte a todo color: no se tiñe con el color del botón o tarjeta (los íconos viejos son blancos y sí se tiñen)
local FULL_COLOR = {
	soul = true, gem = true, amulet = true, lock = true, skip = true, vip = true, frame_obsidian = true,
	pack_gems_400 = true, pack_gems_850 = true, pack_gems_2200 = true, pack_gems_4600 = true, pack_gems_10000 = true,
	pack_spins_3 = true, pass_skip = true, pass_vip = true,
	chest_1_closed = true, chest_1_open = true, chest_2_closed = true, chest_2_open = true, chest_3_closed = true, chest_3_open = true,
	chest_4_closed = true, chest_4_open = true, chest_5_closed = true, chest_5_open = true, chest_6_closed = true, chest_6_open = true,
	-- arte a color (cuando tengan ID): multiplicadores, infusiones, auras y rarezas
	boost_souls = true, boost_xp = true, boost_magnet = true,
	infusion_fire = true, infusion_lightning = true, infusion_ice = true, infusion_shadow = true,
	aura_crown = true, aura_chains = true, aura_wings = true, aura_mist = true, aura_eyes = true, aura_runes = true,
	aura_drip = true, aura_embers = true, aura_blood = true, aura_fracture = true,
	rarity_common = true, rarity_rare = true, rarity_epic = true, rarity_legendary = true, rarity_mythic = true,
}

-- Si una clave nueva no tiene imagen, se dibuja este ícono viejo en su lugar
local FALLBACK = {
	soul = "coin", gem = "rarity_rare", amulet = "stamina", lock = "guard", skip = "dodge", vip = "aura_crown",
	pack_gems_400 = "rarity_rare", pack_gems_850 = "rarity_rare", pack_gems_2200 = "rarity_rare",
	pack_gems_4600 = "rarity_rare", pack_gems_10000 = "rarity_rare", pack_spins_3 = "trophy",
	pass_skip = "dodge", pass_vip = "aura_crown",
	boost_souls = "coin", boost_xp = "trophy", boost_magnet = "aura_crown",
	shop = "coin", rewards = "trophy", leaderboard = "trophy",
}
UiAssets.FullColor = FULL_COLOR

local ALIASES = {
	Fire      = "infusion_fire",
	Lightning = "infusion_lightning",
	Ice       = "infusion_ice",
	Shadow    = "infusion_shadow",
	Coins     = "coin",
	Robux     = "robux",
	Common    = "rarity_common",
	Rare      = "rarity_rare",
	Epic      = "rarity_epic",
	Legendary = "rarity_legendary",
	Mythic    = "rarity_mythic",
	crown     = "aura_crown",
	chains    = "aura_chains",
	wings     = "aura_wings",
	mist      = "aura_mist",
	eyes      = "aura_eyes",
	runes     = "aura_runes",
	drip      = "aura_drip",
	embers    = "aura_embers",
	blood     = "aura_blood",
	fracture  = "aura_fracture",
}

function UiAssets.resolveKey(key)
	return ALIASES[key] or key
end

-- Todas las claves con arte del usuario (11/11): con UiAssets.UseArt = false vuelven todas al dibujo de antes
UiAssets.ArtKeys = {}
for k in FULL_COLOR do UiAssets.ArtKeys[k] = true end
for _, k in { "armory", "shop", "rewards", "settings", "mission", "leaderboard", "health", "stamina", "guard", "guard_broken",
	"stun", "knockdown", "skull", "attack", "heavy", "block", "dodge", "kick", "interact", "lockon", "switch_target", "trophy", "ranked" } do
	UiAssets.ArtKeys[k] = true
end

function UiAssets.imageUri(key)
	local k = UiAssets.resolveKey(key)
	if UiAssets.ArtKeys[k] and not UiAssets.UseArt then return nil end
	local id = UiAssets.Ids[k]
	if type(id) == "number" and id > 0 then
		return "rbxassetid://" .. tostring(id)
	end
	return nil
end

----------------------------------------------------------------------
-- 2. Primitivas internas de dibujo con Frames
----------------------------------------------------------------------
local function partFrame(parent, xScale, yScale, wScale, hScale, color, rot, radiusScale, trans, zOffset)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(xScale, yScale)
	f.Size = UDim2.fromScale(wScale, hScale)
	f.Rotation = rot or 0
	f.BackgroundColor3 = color
	f.BackgroundTransparency = trans or 0
	f.BorderSizePixel = 0
	f.ZIndex = parent.ZIndex + (zOffset or 1)
	f.Parent = parent
	if radiusScale and radiusScale > 0 then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(radiusScale, 0)
		c.Parent = f
	end
	return f
end

local function ringFrame(parent, xScale, yScale, wScale, hScale, color, rot, thickness, radiusScale, zOffset)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(xScale, yScale)
	f.Size = UDim2.fromScale(wScale, hScale)
	f.Rotation = rot or 0
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ZIndex = parent.ZIndex + (zOffset or 1)
	f.Parent = parent
	if radiusScale and radiusScale > 0 then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(radiusScale, 0)
		c.Parent = f
	end
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1.5
	s.Parent = f
	return f, s
end

----------------------------------------------------------------------
-- 3. Dibujo procedural de cada icono (incluye infusiones reversionadas)
----------------------------------------------------------------------
local function drawProcedural(root, key, mainColor)
	local k = UiAssets.resolveKey(key)
	local gold = UiTheme.Colors.GoldBright
	local bone = UiTheme.Colors.TextPrimary
	local dark = UiTheme.Colors.BgAbyss
	local tintParts = {}
	local function mark(f)
		table.insert(tintParts, f)
		return f
	end

	if k == "infusion_fire" then
		-- Emblema solar ígneo reversionado: sello romboidal + llama de tres lenguas + núcleo candente
		local c1 = mainColor or Color3.fromRGB(255, 110, 36)
		local c2 = Color3.fromRGB(255, 210, 96)
		ringFrame(root, 0.5, 0.5, 0.84, 0.84, gold, 45, 1.5, 0.08, 1)
		mark(partFrame(root, 0.5, 0.58, 0.44, 0.44, c1, 45, 0.12, 0, 2))
		mark(partFrame(root, 0.5, 0.34, 0.24, 0.46, c1, 0, 0.3, 0, 2))
		mark(partFrame(root, 0.33, 0.46, 0.18, 0.34, c1, -24, 0.3, 0, 2))
		mark(partFrame(root, 0.67, 0.46, 0.18, 0.34, c1, 24, 0.3, 0, 2))
		partFrame(root, 0.5, 0.54, 0.20, 0.28, c2, 0, 0.4, 0, 3)
		partFrame(root, 0.5, 0.60, 0.12, 0.12, bone, 45, 0.1, 0, 4)

	elseif k == "infusion_lightning" then
		-- Emblema de fulgurita y tormenta reversionado: halo rúnico + rayo quebrado doble + destellos
		local c1 = mainColor or Color3.fromRGB(96, 196, 255)
		local c2 = Color3.fromRGB(230, 248, 255)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.5, 1, 1)
		mark(partFrame(root, 0.54, 0.30, 0.18, 0.42, c1, 26, 0.1, 0, 2))
		mark(partFrame(root, 0.46, 0.66, 0.16, 0.44, c1, 26, 0.1, 0, 2))
		partFrame(root, 0.50, 0.48, 0.34, 0.11, c2, -12, 0.1, 0, 3)
		partFrame(root, 0.52, 0.32, 0.08, 0.32, c2, 26, 0.1, 0, 3)
		partFrame(root, 0.48, 0.64, 0.08, 0.32, c2, 26, 0.1, 0, 3)
		mark(partFrame(root, 0.24, 0.30, 0.10, 0.10, c2, 45, 0, 0, 3))
		mark(partFrame(root, 0.76, 0.68, 0.10, 0.10, c2, 45, 0, 0, 3))

	elseif k == "infusion_ice" then
		-- Estrella glacial boreal reversionada: estrella de 6 puntas + prisma central de escarcha
		local c1 = mainColor or Color3.fromRGB(136, 224, 255)
		local c2 = Color3.fromRGB(232, 252, 255)
		ringFrame(root, 0.5, 0.5, 0.80, 0.80, c1, 45, 1.2, 0.06, 1)
		mark(partFrame(root, 0.5, 0.5, 0.14, 0.88, c1, 0, 0.2, 0, 2))
		mark(partFrame(root, 0.5, 0.5, 0.14, 0.88, c1, 60, 0.2, 0, 2))
		mark(partFrame(root, 0.5, 0.5, 0.14, 0.88, c1, -60, 0.2, 0, 2))
		partFrame(root, 0.5, 0.5, 0.34, 0.34, c2, 45, 0.08, 0, 3)
		partFrame(root, 0.5, 0.5, 0.16, 0.16, dark, 45, 0.08, 0, 4)

	elseif k == "infusion_shadow" then
		-- Creciente de eclipse y ojo del vacío reversionado: luna menguante + pupila abisal + dagas de sombra
		local c1 = mainColor or Color3.fromRGB(178, 102, 240)
		local c2 = Color3.fromRGB(228, 190, 255)
		mark(partFrame(root, 0.46, 0.5, 0.78, 0.78, c1, 0, 1, 0, 1))
		partFrame(root, 0.60, 0.44, 0.64, 0.64, dark, 0, 1, 0, 2)
		mark(partFrame(root, 0.56, 0.52, 0.30, 0.30, c2, 45, 0.1, 0, 3))
		partFrame(root, 0.56, 0.52, 0.10, 0.22, dark, 0, 0.4, 0, 4)
		ringFrame(root, 0.5, 0.5, 0.88, 0.88, gold, 45, 1.2, 1, 1)

	elseif k == "coin" then
		local c = mainColor or UiTheme.Colors.Coins
		partFrame(root, 0.5, 0.5, 0.82, 0.82, c, 0, 1, 0, 1)
		ringFrame(root, 0.5, 0.5, 0.82, 0.82, bone, 0, 1.5, 1, 2)
		partFrame(root, 0.5, 0.5, 0.38, 0.38, dark, 45, 0.08, 0.35, 2)
		partFrame(root, 0.5, 0.5, 0.22, 0.22, bone, 45, 0.08, 0, 3)

	elseif k == "robux" then
		local c = mainColor or UiTheme.Colors.Robux
		partFrame(root, 0.5, 0.5, 0.72, 0.72, c, 45, 0.18, 0, 1)
		partFrame(root, 0.5, 0.5, 0.44, 0.44, dark, 45, 0.12, 0, 2)
		partFrame(root, 0.5, 0.5, 0.22, 0.22, c, 45, 0.08, 0, 3)

	elseif k == "health" then
		local c = mainColor or UiTheme.Colors.Health
		mark(partFrame(root, 0.5, 0.5, 0.28, 0.78, c, 0, 0.15, 0, 1))
		mark(partFrame(root, 0.5, 0.5, 0.78, 0.28, c, 0, 0.15, 0, 1))
		partFrame(root, 0.5, 0.5, 0.18, 0.18, bone, 45, 0.1, 0, 2)

	elseif k == "stamina" then
		local c = mainColor or UiTheme.Colors.Stamina
		mark(partFrame(root, 0.38, 0.5, 0.42, 0.20, c, -28, 0.3, 0, 1))
		mark(partFrame(root, 0.62, 0.5, 0.42, 0.20, c, 28, 0.3, 0, 1))
		mark(partFrame(root, 0.5, 0.30, 0.28, 0.28, bone, 45, 0.1, 0, 2))

	elseif k == "guard" or k == "block" then
		local c = mainColor or UiTheme.Colors.Guard
		mark(partFrame(root, 0.5, 0.42, 0.68, 0.54, c, 0, 0.15, 0, 1))
		mark(partFrame(root, 0.5, 0.64, 0.48, 0.48, c, 45, 0.12, 0, 1))
		partFrame(root, 0.5, 0.48, 0.12, 0.56, bone, 0, 0.2, 0.25, 2)

	elseif k == "stun" then
		local c = mainColor or UiTheme.Colors.Stun
		mark(partFrame(root, 0.5, 0.5, 0.78, 0.18, c, 0, 0.2, 0, 1))
		mark(partFrame(root, 0.5, 0.5, 0.18, 0.78, c, 0, 0.2, 0, 1))
		mark(partFrame(root, 0.5, 0.5, 0.72, 0.16, c, 45, 0.2, 0, 1))
		mark(partFrame(root, 0.5, 0.5, 0.72, 0.16, c, -45, 0.2, 0, 1))
		partFrame(root, 0.5, 0.5, 0.22, 0.22, bone, 45, 0.1, 0, 2)

	elseif k == "trophy" then
		local c = mainColor or gold
		partFrame(root, 0.5, 0.38, 0.54, 0.44, c, 0, 0.25, 0, 1)
		partFrame(root, 0.5, 0.66, 0.16, 0.24, c, 0, 0, 0, 1)
		partFrame(root, 0.5, 0.80, 0.48, 0.12, c, 0, 0.2, 0, 1)
		ringFrame(root, 0.5, 0.36, 0.76, 0.30, c, 0, 1.5, 0.5, 1)

	elseif k == "skull" then
		local c = mainColor or bone
		partFrame(root, 0.5, 0.42, 0.66, 0.56, c, 0, 0.45, 0, 1)
		partFrame(root, 0.5, 0.70, 0.40, 0.24, c, 0, 0.15, 0, 1)
		partFrame(root, 0.36, 0.44, 0.16, 0.16, dark, 0, 1, 0, 2)
		partFrame(root, 0.64, 0.44, 0.16, 0.16, dark, 0, 1, 0, 2)
		partFrame(root, 0.5, 0.56, 0.10, 0.12, dark, 45, 0, 0, 2)

	elseif k == "knockdown" then
		local c = mainColor or UiTheme.Colors.Warning
		partFrame(root, 0.36, 0.48, 0.36, 0.60, c, -14, 0.15, 0, 1)
		partFrame(root, 0.66, 0.54, 0.34, 0.56, c, 18, 0.15, 0, 1)
		partFrame(root, 0.50, 0.50, 0.12, 0.84, bone, 22, 0.2, 0, 2)

	elseif k == "mission" then
		local c = mainColor or gold
		partFrame(root, 0.5, 0.5, 0.62, 0.76, c, 0, 0.12, 0, 1)
		partFrame(root, 0.5, 0.34, 0.40, 0.08, dark, 0, 0, 0.3, 2)
		partFrame(root, 0.5, 0.50, 0.40, 0.08, dark, 0, 0, 0.3, 2)
		partFrame(root, 0.62, 0.68, 0.22, 0.22, UiTheme.Colors.Danger, 0, 1, 0, 3)

	elseif k == "settings" then
		local c = mainColor or bone
		partFrame(root, 0.5, 0.5, 0.24, 0.84, c, 0, 0.15, 0, 1)
		partFrame(root, 0.5, 0.5, 0.84, 0.24, c, 0, 0.15, 0, 1)
		partFrame(root, 0.5, 0.5, 0.24, 0.84, c, 45, 0.15, 0, 1)
		partFrame(root, 0.5, 0.5, 0.84, 0.24, c, 45, 0.15, 0, 1)
		partFrame(root, 0.5, 0.5, 0.62, 0.62, c, 0, 1, 0, 2)
		partFrame(root, 0.5, 0.5, 0.28, 0.28, dark, 0, 1, 0, 3)

	elseif k == "attack" then
		local c = mainColor or bone
		partFrame(root, 0.5, 0.5, 0.14, 0.86, c, 42, 0.2, 0, 1)
		partFrame(root, 0.5, 0.48, 0.38, 0.10, gold, -48, 0.2, 0, 2)
		partFrame(root, 0.5, 0.5, 0.14, 0.86, c, -42, 0.2, 0, 1)
		partFrame(root, 0.5, 0.48, 0.38, 0.10, gold, 48, 0.2, 0, 2)

	elseif k == "heavy" then
		local c = mainColor or UiTheme.Colors.Danger
		partFrame(root, 0.5, 0.5, 0.20, 0.88, c, 32, 0.2, 0, 1)
		partFrame(root, 0.5, 0.5, 0.46, 0.46, gold, 45, 0.1, 0, 2)
		partFrame(root, 0.5, 0.5, 0.22, 0.22, bone, 0, 1, 0, 3)

	elseif k == "dodge" then
		local c = mainColor or UiTheme.Colors.Stamina
		partFrame(root, 0.42, 0.38, 0.48, 0.12, c, -32, 0.3, 0, 1)
		partFrame(root, 0.42, 0.62, 0.48, 0.12, c, 32, 0.3, 0, 1)
		partFrame(root, 0.66, 0.38, 0.42, 0.12, bone, -32, 0.3, 0, 2)
		partFrame(root, 0.66, 0.62, 0.42, 0.12, bone, 32, 0.3, 0, 2)

	elseif k == "kick" then
		local c = mainColor or UiTheme.Colors.Warning
		partFrame(root, 0.42, 0.40, 0.26, 0.44, c, -18, 0.15, 0, 1)
		partFrame(root, 0.56, 0.62, 0.48, 0.24, c, -10, 0.2, 0, 1)
		ringFrame(root, 0.72, 0.56, 0.36, 0.36, bone, 45, 1.5, 0.1, 2)

	elseif k == "interact" then
		local c = mainColor or gold
		ringFrame(root, 0.5, 0.5, 0.72, 0.72, c, 45, 2, 0.12, 1)
		partFrame(root, 0.5, 0.5, 0.30, 0.30, bone, 45, 0.1, 0, 2)

	elseif k == "lockon" or k == "switch_target" then
		local c = mainColor or gold
		ringFrame(root, 0.5, 0.5, 0.74, 0.74, c, 45, 1.8, 0.08, 1)
		partFrame(root, 0.5, 0.14, 0.08, 0.22, bone, 0, 0, 0, 2)
		partFrame(root, 0.5, 0.86, 0.08, 0.22, bone, 0, 0, 0, 2)
		partFrame(root, 0.14, 0.5, 0.22, 0.08, bone, 0, 0, 0, 2)
		partFrame(root, 0.86, 0.5, 0.22, 0.08, bone, 0, 0, 0, 2)
		partFrame(root, 0.5, 0.5, 0.16, 0.16, UiTheme.Colors.Danger, 45, 0, 0, 3)

	elseif k == "aura" or k == "aura_crown" then
		local c = mainColor or Color3.fromRGB(186, 136, 245)
		ringFrame(root, 0.5, 0.5, 0.84, 0.84, gold, 0, 1.5, 1, 1)
		mark(partFrame(root, 0.5, 0.64, 0.62, 0.14, c, 0, 0.08, 0, 2))
		mark(partFrame(root, 0.5, 0.44, 0.16, 0.36, c, 0, 0.1, 0, 2))
		mark(partFrame(root, 0.34, 0.50, 0.14, 0.26, c, -16, 0.1, 0, 2))
		mark(partFrame(root, 0.66, 0.50, 0.14, 0.26, c, 16, 0.1, 0, 2))
		partFrame(root, 0.5, 0.30, 0.10, 0.10, bone, 45, 0.05, 0, 3)
		partFrame(root, 0.30, 0.38, 0.08, 0.08, bone, 45, 0.05, 0, 3)
		partFrame(root, 0.70, 0.38, 0.08, 0.08, bone, 45, 0.05, 0, 3)

	elseif k == "aura_chains" then
		local c = mainColor or Color3.fromRGB(110, 121, 132)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		mark(ringFrame(root, 0.38, 0.5, 0.44, 0.28, c, -32, 2.4, 0.5, 2))
		mark(ringFrame(root, 0.62, 0.5, 0.44, 0.28, c, 32, 2.4, 0.5, 3))
		partFrame(root, 0.5, 0.5, 0.14, 0.14, bone, 45, 0.1, 0, 4)

	elseif k == "aura_wings" then
		local c = mainColor or Color3.fromRGB(99, 91, 113)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		mark(partFrame(root, 0.32, 0.42, 0.44, 0.16, c, 34, 0.4, 0, 2))
		mark(partFrame(root, 0.30, 0.56, 0.38, 0.14, c, 16, 0.4, 0, 2))
		mark(partFrame(root, 0.68, 0.42, 0.44, 0.16, c, -34, 0.4, 0, 2))
		mark(partFrame(root, 0.70, 0.56, 0.38, 0.14, c, -16, 0.4, 0, 2))
		partFrame(root, 0.5, 0.52, 0.12, 0.40, bone, 0, 0.1, 0, 3)
		partFrame(root, 0.5, 0.34, 0.14, 0.14, gold, 45, 0.08, 0, 4)

	elseif k == "aura_mist" then
		local c = mainColor or Color3.fromRGB(102, 112, 108)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		mark(partFrame(root, 0.5, 0.38, 0.66, 0.16, c, 0, 0.5, 0.15, 2))
		mark(partFrame(root, 0.44, 0.52, 0.72, 0.16, c, 0, 0.5, 0.25, 3))
		mark(partFrame(root, 0.56, 0.66, 0.60, 0.16, c, 0, 0.5, 0.35, 4))
		partFrame(root, 0.5, 0.52, 0.16, 0.16, bone, 45, 0.1, 0.2, 5)

	elseif k == "aura_eyes" then
		local c = mainColor or Color3.fromRGB(148, 108, 103)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		mark(ringFrame(root, 0.5, 0.5, 0.80, 0.44, c, 0, 2.4, 0.5, 2))
		partFrame(root, 0.5, 0.5, 0.30, 0.30, bone, 0, 1, 0, 3)
		partFrame(root, 0.5, 0.5, 0.10, 0.28, dark, 0, 0.4, 0, 4)
		partFrame(root, 0.46, 0.46, 0.06, 0.06, bone, 0, 1, 0, 5)

	elseif k == "aura_runes" then
		local c = mainColor or Color3.fromRGB(143, 132, 109)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.4, 1, 1)
		mark(partFrame(root, 0.5, 0.5, 0.10, 0.60, c, 0, 0.1, 0, 2))
		mark(partFrame(root, 0.60, 0.38, 0.24, 0.08, c, 38, 0.1, 0, 3))
		mark(partFrame(root, 0.40, 0.62, 0.24, 0.08, c, 38, 0.1, 0, 3))
		partFrame(root, 0.5, 0.22, 0.12, 0.12, bone, 45, 0, 0, 4)

	elseif k == "aura_drip" then
		local c = mainColor or Color3.fromRGB(89, 83, 100)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		partFrame(root, 0.5, 0.26, 0.74, 0.10, bone, 0, 0.1, 0, 2)
		mark(partFrame(root, 0.36, 0.48, 0.16, 0.28, c, 0, 0.5, 0, 3))
		mark(partFrame(root, 0.54, 0.66, 0.22, 0.34, c, 0, 0.5, 0, 3))
		mark(partFrame(root, 0.72, 0.46, 0.14, 0.22, c, 0, 0.5, 0, 3))

	elseif k == "aura_embers" then
		local c = mainColor or Color3.fromRGB(133, 104, 85)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		mark(partFrame(root, 0.5, 0.70, 0.50, 0.22, c, 0, 0.3, 0, 2))
		mark(partFrame(root, 0.36, 0.42, 0.14, 0.14, c, 45, 0.1, 0, 3))
		mark(partFrame(root, 0.58, 0.32, 0.18, 0.18, c, 45, 0.1, 0, 3))
		partFrame(root, 0.44, 0.20, 0.12, 0.12, bone, 45, 0.1, 0, 4)

	elseif k == "aura_blood" then
		local c = mainColor or Color3.fromRGB(112, 55, 59)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		mark(partFrame(root, 0.5, 0.58, 0.38, 0.48, c, 0, 0.4, 0, 2))
		mark(partFrame(root, 0.5, 0.34, 0.16, 0.30, c, 0, 0.1, 0, 2))
		partFrame(root, 0.44, 0.52, 0.08, 0.24, bone, -16, 0.4, 0.2, 3)

	elseif k == "aura_fracture" then
		local c = mainColor or Color3.fromRGB(155, 159, 143)
		ringFrame(root, 0.5, 0.5, 0.86, 0.86, gold, 0, 1.2, 1, 1)
		mark(ringFrame(root, 0.5, 0.5, 0.80, 0.80, c, 45, 2, 0.08, 2))
		mark(partFrame(root, 0.46, 0.42, 0.10, 0.48, bone, 28, 0.05, 0, 3))
		mark(partFrame(root, 0.56, 0.58, 0.08, 0.42, bone, -38, 0.05, 0, 3))
		partFrame(root, 0.50, 0.50, 0.16, 0.16, bone, 45, 0, 0, 4)

	else
		-- Emblema romboidal real por defecto (rarezas, armería, clasificatorias)
		local c = mainColor or gold
		ringFrame(root, 0.5, 0.5, 0.80, 0.80, c, 45, 1.8, 0.1, 1)
		mark(partFrame(root, 0.5, 0.5, 0.42, 0.42, c, 45, 0.1, 0, 2))
		partFrame(root, 0.5, 0.5, 0.16, 0.16, bone, 45, 0.1, 0, 3)
	end

	return function(fraction, exhausted)
		local f = math.clamp(fraction or 1, 0, 1)
		for _, p in tintParts do
			if p.Parent then
				p.BackgroundColor3 = exhausted and UiTheme.Colors.Disabled or (mainColor or gold)
				p.BackgroundTransparency = exhausted and 0.45 or (1 - f) * 0.45
			end
		end
	end
end

----------------------------------------------------------------------
-- 4. Constructor público de iconos (con respaldo dibujado)
----------------------------------------------------------------------
function UiAssets.icon(parent, key, sizePx, colorOverride)
	local px = sizePx or 24
	local uri = UiAssets.imageUri(key)
	local resolved = UiAssets.resolveKey(key)
	if not uri and FALLBACK[resolved] then
		key = FALLBACK[resolved]
		uri = UiAssets.imageUri(key)
	elseif uri and FULL_COLOR[resolved] then
		colorOverride = nil -- el arte a color no se tiñe
	end
	if uri then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon_" .. tostring(key)
		img.Size = UDim2.fromOffset(px, px)
		img.BackgroundTransparency = 1
		img.Image = uri
		if colorOverride then img.ImageColor3 = colorOverride end
		img.Parent = parent
		local function update(fraction, exhausted)
			local f = math.clamp(fraction or 1, 0, 1)
			img.ImageColor3 = exhausted and UiTheme.Colors.Disabled or (colorOverride or Color3.new(1, 1, 1))
			img.ImageTransparency = exhausted and 0.45 or (1 - f) * 0.45
		end
		return img, update
	end

	local holder = Instance.new("Frame")
	holder.Name = "Icon_" .. tostring(key)
	holder.Size = UDim2.fromOffset(px, px)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Parent = parent
	local update = drawProcedural(holder, key, colorOverride)
	return holder, update
end

----------------------------------------------------------------------
-- 5. Ilustración temática para tarjetas verticales de Infusiones
--    (Estilo referencias\infusiones ref2.jpg: fondo atmosférico + rayos/halos + icono reversionado arriba)
----------------------------------------------------------------------
function UiAssets.infusionCardArt(parent, infusionId)
	local theme = UiTheme.InfusionThemes[infusionId] or UiTheme.InfusionThemes.Fire

	local art = Instance.new("Frame")
	art.Name = "InfusionArt"
	art.Size = UDim2.fromScale(1, 1)
	art.BackgroundColor3 = Color3.new(1, 1, 1)
	art.BorderSizePixel = 0
	art.ClipsDescendants = true
	art.Parent = parent
	UiTheme.corner(art, UiTheme.Radius.MD)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.top),
		ColorSequenceKeypoint.new(0.45, theme.mid),
		ColorSequenceKeypoint.new(1, theme.bottom),
	})
	grad.Rotation = 90
	grad.Parent = art

	-- Halo de fondo tras el medallón superior
	partFrame(art, 0.5, 0.28, 0.72, 0.36, theme.accent, 45, 0.12, 0.78, 1)
	ringFrame(art, 0.5, 0.28, 0.78, 0.39, UiTheme.Colors.Gold, 45, 1.2, 0.08, 1)
	ringFrame(art, 0.5, 0.28, 0.60, 0.30, theme.glow, 0, 1, 1, 1)

	-- Motivos ambientales de fondo según la infusión (solo las 4 del juego)
	if infusionId == "Fire" then
		partFrame(art, 0.25, 0.58, 0.08, 0.32, theme.accent, -16, 0.4, 0.72, 1)
		partFrame(art, 0.75, 0.56, 0.08, 0.34, theme.accent, 16, 0.4, 0.72, 1)
		partFrame(art, 0.50, 0.52, 0.14, 0.40, theme.glow, 0, 0.4, 0.80, 1)
	elseif infusionId == "Lightning" then
		partFrame(art, 0.35, 0.52, 0.04, 0.45, theme.glow, 24, 0, 0.68, 1)
		partFrame(art, 0.65, 0.54, 0.04, 0.45, theme.glow, -24, 0, 0.68, 1)
		ringFrame(art, 0.5, 0.28, 0.86, 0.43, theme.accent, 22, 1, 0.1, 1)
	elseif infusionId == "Ice" then
		partFrame(art, 0.5, 0.28, 0.05, 0.62, theme.glow, 30, 0.2, 0.75, 1)
		partFrame(art, 0.5, 0.28, 0.05, 0.62, theme.glow, -30, 0.2, 0.75, 1)
		partFrame(art, 0.24, 0.50, 0.12, 0.12, theme.accent, 45, 0, 0.72, 1)
		partFrame(art, 0.76, 0.50, 0.12, 0.12, theme.accent, 45, 0, 0.72, 1)
	elseif infusionId == "Shadow" then
		partFrame(art, 0.5, 0.28, 0.68, 0.34, UiTheme.Colors.BgAbyss, 0, 1, 0.45, 1)
		partFrame(art, 0.28, 0.56, 0.10, 0.34, theme.accent, 18, 0.4, 0.72, 1)
		partFrame(art, 0.72, 0.56, 0.10, 0.34, theme.accent, -18, 0.4, 0.72, 1)
	end

	-- Viñeta oscura en la mitad inferior para lectura perfecta del nombre, lema y estado
	local shade = Instance.new("Frame")
	shade.AnchorPoint = Vector2.new(0, 1)
	shade.Position = UDim2.fromScale(0, 1)
	shade.Size = UDim2.fromScale(1, 0.58)
	shade.BackgroundColor3 = UiTheme.Colors.BgAbyss
	shade.BorderSizePixel = 0
	shade.ZIndex = art.ZIndex + 2
	shade.Parent = art
	local shadeGrad = Instance.new("UIGradient")
	shadeGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 0.22),
		NumberSequenceKeypoint.new(1, 0.04),
	})
	shadeGrad.Rotation = 90
	shadeGrad.Parent = shade

	-- Medallón octogonal superior con el icono reversionado de la infusión
	local medallion = Instance.new("Frame")
	medallion.Name = "Medallion"
	medallion.AnchorPoint = Vector2.new(0.5, 0.5)
	medallion.Position = UDim2.fromScale(0.5, 0.27)
	medallion.Size = UDim2.fromOffset(78, 78)
	medallion.BackgroundColor3 = UiTheme.Colors.BgAbyss
	medallion.BackgroundTransparency = 0.12
	medallion.BorderSizePixel = 0
	medallion.ZIndex = art.ZIndex + 3
	medallion.Parent = art
	UiTheme.corner(medallion, 39)
	UiTheme.stroke(medallion, UiTheme.Colors.GoldBright, 2, 0.05)

	local icon = UiAssets.icon(medallion, infusionId, 56, theme.accent)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.ZIndex = medallion.ZIndex + 1

	return art
end

return UiAssets
