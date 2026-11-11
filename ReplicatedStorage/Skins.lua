-- ModuleScript: ReplicatedStorage/Skins
-- Skins de arma (cosméticas, valen para cualquier arma). Nombres dark fantasy.
-- Los IDs internos (Default, Charcoal...) no cambian para no romper datos guardados.
-- currency: "Free" | "Coins" (monedas del juego) | "Robux" (Developer Product)
-- Para las de Robux: crea un Developer Product en el Creator Hub y pega su ID en productId.
-- Mientras productId = 0 la skin aparece en la tienda pero no se puede comprar.

local Skins = {}

Skins.Order = { "Default", "Charcoal", "Frost", "Gold", "Cyber", "Blood" }

Skins.Data = {
	-- Sin colores: cada arma usa su paleta original (WeaponBuilder)
	Default = { name = "Acero Viejo", currency = "Free", price = 0, desc = "El acabado original de cada arma." },

	Charcoal = { name = "Obsidiana", currency = "Coins", price = 200, desc = "Piedra volcánica pulida con vetas violáceas.",
		blade = Color3.fromRGB(28, 26, 32), accent = Color3.fromRGB(90, 70, 110),
		material = Enum.Material.Slate, trail = Color3.fromRGB(120, 100, 150) },

	Frost = { name = "Hueso", currency = "Coins", price = 400, desc = "Tallada en el hueso de una bestia antigua.",
		blade = Color3.fromRGB(215, 205, 180), accent = Color3.fromRGB(120, 105, 85),
		material = Enum.Material.Limestone, trail = Color3.fromRGB(230, 220, 200) },

	Gold = { name = "Oro Ceniciento", currency = "Coins", price = 800, desc = "Oro viejo cubierto de ceniza de reyes caídos.",
		blade = Color3.fromRGB(170, 140, 80), accent = Color3.fromRGB(60, 50, 40),
		material = Enum.Material.Metal, trail = Color3.fromRGB(200, 170, 110) },

	Cyber = { name = "Runas Etéreas", currency = "Coins", price = 1600, productId = 0, desc = "Acero oscuro con runas que brillan en frío.",
		blade = Color3.fromRGB(40, 44, 56), accent = Color3.fromRGB(120, 200, 220),
		material = Enum.Material.Metal, neonAccent = true, trail = Color3.fromRGB(140, 220, 240) },

	Blood = { name = "Linaje Carmesí", currency = "Coins", price = 2400, productId = 0, desc = "Forjada con sangre de un linaje maldito.",
		blade = Color3.fromRGB(90, 20, 26), accent = Color3.fromRGB(160, 30, 40),
		material = Enum.Material.Metal, neonAccent = true, trail = Color3.fromRGB(170, 25, 40) },
}

Skins.Order[#Skins.Order + 1] = "Requiem"
Skins.Data.Requiem = {
	name = "Réquiem Astado",
	desc = "Acero negro de guardia gótica con cuernos curvos y espina funeraria.",
	weapon = "Sword",
	rarity = "Epic",
	currency = "Coins",
	price = 3400,
	productId = 0,
	comingSoon = false,
	design = "RequiemHorns",
	blade = Color3.fromRGB(32, 32, 37),
	accent = Color3.fromRGB(44, 42, 47),
	trail = Color3.fromRGB(165, 145, 210),
	material = Enum.Material.Metal,
}

-- Lote 4: provenance and per-weapon catalog. Reference entries without approved geometry stay unavailable.
Skins.Order[#Skins.Order + 1] = "Relic01"
Skins.Data.Relic01 = { name = "Colmillos Carmesí", desc = "", weapon = "Dagger", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Fangs", source = "F:/RobloxJuegos/skins armas/dagas/14e51e7801b333ba6eb569fdf26fcee2.jpg", blade = Color3.fromRGB(24, 18, 20), accent = Color3.fromRGB(230, 40, 36), trail = Color3.fromRGB(230, 50, 40), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic02"
Skins.Data.Relic02 = { name = "Espinas Vivas", desc = "", weapon = "Dagger", rarity = "Epic", currency = "Coins", price = 3200, comingSoon = false, design = "LivingThorns", source = "F:/RobloxJuegos/skins armas/dagas/39f6ad2c698895e49f5631c5f579dd62.jpg", blade = Color3.fromRGB(26, 24, 28), accent = Color3.fromRGB(225, 222, 214), trail = Color3.fromRGB(220, 40, 40), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic03"
Skins.Data.Relic03 = { name = "Lunas del Vacío", desc = "", weapon = "Dagger", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "VoidMoons", source = "F:/RobloxJuegos/skins armas/dagas/a2fc9a600b5cd1e46ad6e33223940fb1.jpg", blade = Color3.fromRGB(30, 28, 38), accent = Color3.fromRGB(150, 110, 240), trail = Color3.fromRGB(160, 120, 240), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic04"
Skins.Data.Relic04 = { name = "Crecientes de Plata", desc = "", weapon = "Dagger", rarity = "Rare", currency = "Coins", price = 1400, comingSoon = false, design = "SilverCrescent", source = "F:/RobloxJuegos/skins armas/dagas/b42a5033db8e544d95f9a2305d648270.jpg", blade = Color3.fromRGB(36, 36, 40), accent = Color3.fromRGB(225, 226, 232), trail = Color3.fromRGB(220, 220, 230), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic05"
Skins.Data.Relic05 = { name = "Garras del Eclipse", desc = "", weapon = "Dagger", rarity = "Rare", currency = "Coins", price = 1500, comingSoon = false, design = "EclipseClaws", source = "F:/RobloxJuegos/skins armas/dagas/cd40456f61e10c0e19e1aadffe578636.jpg", blade = Color3.fromRGB(70, 72, 78), accent = Color3.fromRGB(170, 172, 178), trail = Color3.fromRGB(190, 190, 200), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic06"
Skins.Data.Relic06 = { name = "Juramento Solar", desc = "", weapon = "Sword", rarity = "Epic", currency = "Coins", price = 2800, comingSoon = false, design = "Solar", source = "F:/RobloxJuegos/skins armas/espadas/06963e122b1a4a4b9cc7542de871f79e.jpg", blade = Color3.fromRGB(175, 177, 183), accent = Color3.fromRGB(177, 149, 85), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic07"
Skins.Data.Relic07 = { name = "Espina del Osario", desc = "", weapon = "Sword", rarity = "Epic", currency = "Coins", price = 3200, comingSoon = false, design = "Ossuary", source = "F:/RobloxJuegos/skins armas/espadas/28fa98fd4b020e63a28ca5eba6f13bdc.jpg", blade = Color3.fromRGB(214, 204, 182), accent = Color3.fromRGB(104, 22, 24), trail = Color3.fromRGB(200, 180, 160), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic08"
Skins.Data.Relic08 = { name = "Corona del Alba", desc = "", weapon = "Sword", rarity = "Epic", currency = "Coins", price = 2800, comingSoon = false, design = "DawnCrown", source = "F:/RobloxJuegos/skins armas/espadas/59ed808043b9a400174c685f2ff72297.jpg", blade = Color3.fromRGB(206, 206, 212), accent = Color3.fromRGB(214, 172, 72), trail = Color3.fromRGB(240, 210, 140), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic09"
Skins.Data.Relic09 = { name = "Filo del Dragón", desc = "", weapon = "Sword", rarity = "Rare", currency = "Coins", price = 1500, comingSoon = false, design = "DragonEdge", source = "F:/RobloxJuegos/skins armas/espadas/61pqNB20FVL._AC_SX679_.jpg", blade = Color3.fromRGB(132, 128, 116), accent = Color3.fromRGB(96, 96, 102), trail = Color3.fromRGB(200, 196, 180), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic10"
Skins.Data.Relic10 = { name = "Vigilia Violeta", desc = "", weapon = "Sword", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Violet", source = "F:/RobloxJuegos/skins armas/espadas/666cbeed9aec5569d54b076fd2f6be9f.jpg", blade = Color3.fromRGB(48, 48, 59), accent = Color3.fromRGB(154, 92, 213), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic11"
Skins.Data.Relic11 = { name = "Aguja del Vacío", desc = "", weapon = "Sword", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Void", source = "F:/RobloxJuegos/skins armas/espadas/9950712683b665de57adfacd9d4c74ad.jpg", blade = Color3.fromRGB(48, 48, 59), accent = Color3.fromRGB(76, 67, 94), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic12"
Skins.Data.Relic12 = { name = "Diente del Exilio", desc = "", weapon = "Sword", rarity = "Rare", currency = "Coins", price = 1000, comingSoon = false, design = "ExileTooth", source = "F:/RobloxJuegos/skins armas/espadas/a959eab45ebecb4bf87730749a78798e.jpg", blade = Color3.fromRGB(74, 76, 80), accent = Color3.fromRGB(120, 112, 98), trail = Color3.fromRGB(170, 170, 175), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic13"
Skins.Data.Relic13 = { name = "Reliquia Dracónica", desc = "", weapon = "Sword", rarity = "Epic", currency = "Coins", price = 3500, comingSoon = false, design = "DraconicRelic", source = "F:/RobloxJuegos/skins armas/espadas/cff7ba45e70937f24e4ec4850e131489.jpg", blade = Color3.fromRGB(28, 28, 34), accent = Color3.fromRGB(60, 90, 230), trail = Color3.fromRGB(150, 180, 255), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic14"
Skins.Data.Relic14 = { name = "Tumba Esmeralda", desc = "", weapon = "Greatsword", rarity = "Epic", currency = "Coins", price = 4000, comingSoon = false, design = "EmeraldTomb", source = "F:/RobloxJuegos/skins armas/espadon/35282046d1d0218a43fbed4e31bee0dd.jpg", blade = Color3.fromRGB(34, 40, 44), accent = Color3.fromRGB(60, 255, 120), trail = Color3.fromRGB(70, 255, 130), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic15"
Skins.Data.Relic15 = { name = "Devorador", desc = "", weapon = "Greatsword", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Devourer", source = "F:/RobloxJuegos/skins armas/espadon/6c232dc7d8fcd049ab8c3811f5c69319.jpg", blade = Color3.fromRGB(56, 58, 62), accent = Color3.fromRGB(64, 66, 70), trail = Color3.fromRGB(150, 150, 160), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic16"
Skins.Data.Relic16 = { name = "Luto Real", desc = "", weapon = "Greatsword", rarity = "Epic", currency = "Coins", price = 2800, comingSoon = false, design = "RoyalMourning", source = "F:/RobloxJuegos/skins armas/espadon/d05e673dc1bd3ea19bba7617f258b27b.jpg", blade = Color3.fromRGB(40, 40, 44), accent = Color3.fromRGB(196, 190, 186), trail = Color3.fromRGB(210, 210, 220), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic17"
Skins.Data.Relic17 = { name = "Cruz del Ocaso", desc = "", weapon = "Greatsword", rarity = "Epic", currency = "Coins", price = 3500, comingSoon = false, design = "DuskCross", source = "F:/RobloxJuegos/skins armas/espadon/d22a3b407a30046db5c1bc41fbd6816b.jpg", blade = Color3.fromRGB(196, 156, 62), accent = Color3.fromRGB(232, 196, 104), trail = Color3.fromRGB(240, 200, 110), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic18"
Skins.Data.Relic18 = { name = "Sudario", desc = "", weapon = "Greatsword", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Shroud", source = "F:/RobloxJuegos/skins armas/espadon/d25f35246ddd5e803891f7214856ba3d.jpg", blade = Color3.fromRGB(36, 38, 44), accent = Color3.fromRGB(194, 182, 154), trail = Color3.fromRGB(210, 198, 172), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic19"
Skins.Data.Relic19 = { name = "Alas del Abismo", desc = "", weapon = "Greatsword", rarity = "Epic", currency = "Coins", price = 3800, comingSoon = false, design = "AbyssWings", source = "F:/RobloxJuegos/skins armas/espadon/e541c757412cec3921855b89ef7223f2.jpg", blade = Color3.fromRGB(22, 22, 26), accent = Color3.fromRGB(120, 90, 200), trail = Color3.fromRGB(130, 100, 210), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic20"
Skins.Data.Relic20 = { name = "Duelo Dorado", desc = "", weapon = "Rapier", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Duel", source = "F:/RobloxJuegos/skins armas/estoque/090c9a92064ade0ff85bc1d939bf476e.jpg", blade = Color3.fromRGB(175, 177, 183), accent = Color3.fromRGB(177, 149, 85), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic21"
Skins.Data.Relic21 = { name = "Corte de Plata", desc = "", weapon = "Rapier", rarity = "Rare", currency = "Coins", price = 1200, comingSoon = false, design = "SilverCut", source = "F:/RobloxJuegos/skins armas/estoque/1f82374c863180957fef76fecef56440.jpg", blade = Color3.fromRGB(66, 66, 70), accent = Color3.fromRGB(150, 150, 156), trail = Color3.fromRGB(190, 190, 200), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic22"
Skins.Data.Relic22 = { name = "Lengua de Fuego", desc = "", weapon = "Rapier", rarity = "Epic", currency = "Coins", price = 3500, comingSoon = false, design = "FireTongue", source = "F:/RobloxJuegos/skins armas/estoque/3cb10b82054957138b6e7a10acd8293f.jpg", blade = Color3.fromRGB(116, 100, 82), accent = Color3.fromRGB(255, 120, 40), trail = Color3.fromRGB(255, 140, 60), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic23"
Skins.Data.Relic23 = { name = "Duelo del Crepúsculo", desc = "", weapon = "Rapier", rarity = "Rare", currency = "Coins", price = 1000, comingSoon = false, design = "TwilightDuel", source = "F:/RobloxJuegos/skins armas/estoque/550790fef44540de63ca3ea425f88e3d.jpg", blade = Color3.fromRGB(150, 150, 156), accent = Color3.fromRGB(130, 126, 120), trail = Color3.fromRGB(210, 210, 220), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic24"
Skins.Data.Relic24 = { name = "Aguijón Espectral", desc = "", weapon = "Rapier", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "SpectralSting", source = "F:/RobloxJuegos/skins armas/estoque/5fd50b1f76d4f6946604ef4db9a2f07d.jpg", blade = Color3.fromRGB(38, 36, 46), accent = Color3.fromRGB(196, 160, 240), trail = Color3.fromRGB(200, 170, 245), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic25"
Skins.Data.Relic25 = { name = "Velo Amatista", desc = "", weapon = "Rapier", rarity = "Epic", currency = "Coins", price = 2800, comingSoon = false, design = "AmethystVeil", source = "F:/RobloxJuegos/skins armas/estoque/6d7380e864ecf979643d04af511de89c.jpg", blade = Color3.fromRGB(116, 74, 138), accent = Color3.fromRGB(236, 110, 210), trail = Color3.fromRGB(230, 140, 220), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic26"
Skins.Data.Relic26 = { name = "Lamento Oscuro", desc = "", weapon = "Rapier", rarity = "Epic", currency = "Coins", price = 3200, comingSoon = false, design = "DarkLament", source = "F:/RobloxJuegos/skins armas/estoque/a6a15ee6ae3a5c26d25461e043057091.jpg", blade = Color3.fromRGB(14, 14, 16), accent = Color3.fromRGB(46, 46, 52), trail = Color3.fromRGB(70, 70, 90), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic27"
Skins.Data.Relic27 = { name = "Juicio de Hierro", desc = "", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Flange", source = "F:/RobloxJuegos/skins armas/martillo hacha/04d2ea2b142228f34fb473758042c9c7.jpg", blade = Color3.fromRGB(175, 177, 183), accent = Color3.fromRGB(177, 149, 85), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic28"
Skins.Data.Relic28 = { name = "Espinas Carmesí", desc = "", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 3500, comingSoon = false, design = "CrimsonShards", source = "F:/RobloxJuegos/skins armas/martillo hacha/1e16574d3e366830880002912d0ccce8.jpg", blade = Color3.fromRGB(66, 42, 50), accent = Color3.fromRGB(220, 40, 100), trail = Color3.fromRGB(220, 60, 110), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic29"
Skins.Data.Relic29 = { name = "Verdugo del Norte", desc = "", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "NorthExecutioner", source = "F:/RobloxJuegos/skins armas/martillo hacha/746908fa76f0e9f00afcd1ce68cb0d7f.jpg", blade = Color3.fromRGB(58, 60, 70), accent = Color3.fromRGB(196, 196, 200), trail = Color3.fromRGB(200, 200, 210), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic30"
Skins.Data.Relic30 = { name = "Corazón de Forja", desc = "", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 3000, comingSoon = false, design = "Forge", source = "F:/RobloxJuegos/skins armas/martillo hacha/882dfb5c22965ea331c360a1791ccb81.jpg", blade = Color3.fromRGB(48, 48, 59), accent = Color3.fromRGB(240, 122, 48), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic31"
Skins.Data.Relic31 = { name = "Mandíbula Antigua", desc = "", weapon = "Mace", rarity = "Rare", currency = "Coins", price = 1500, comingSoon = false, design = "AncientMaw", source = "F:/RobloxJuegos/skins armas/martillo hacha/89652cca0974e476f947634d7031b18a.jpg", blade = Color3.fromRGB(66, 60, 54), accent = Color3.fromRGB(170, 152, 120), trail = Color3.fromRGB(190, 170, 130), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Relic32"
Skins.Data.Relic32 = { name = "Hacha del Osario", desc = "", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 3200, comingSoon = false, design = "OssuaryAxe", source = "F:/RobloxJuegos/skins armas/martillo hacha/9bfc902081277142d2dbd0c82a258dc3.jpg", blade = Color3.fromRGB(186, 160, 124), accent = Color3.fromRGB(40, 40, 48), trail = Color3.fromRGB(210, 190, 150), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Maw02"
Skins.Data.Maw02 = { name = "Vértebra del Abismo", desc = "Columna de leviatán fosilizada con púas dorsales y médula carmesí.", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 2900, comingSoon = false, design = "AbyssVertebra", blade = Color3.fromRGB(58, 52, 48), accent = Color3.fromRGB(182, 164, 132), trail = Color3.fromRGB(185, 42, 48), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Maw03"
Skins.Data.Maw03 = { name = "Fauces del Sepulcro", desc = "Doble mandíbula de bestia abisal cerrada sobre un núcleo de ámbar.", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 3400, comingSoon = false, design = "SepulcherJaws", blade = Color3.fromRGB(64, 58, 52), accent = Color3.fromRGB(190, 172, 138), trail = Color3.fromRGB(235, 148, 52), material = Enum.Material.Metal }
Skins.Order[#Skins.Order + 1] = "Maw04"
Skins.Data.Maw04 = { name = "Corona del Osario", desc = "Maza real de cráneos coronados y astas de hueso consagrado.", weapon = "Mace", rarity = "Epic", currency = "Coins", price = 3900, comingSoon = false, design = "OssuaryCrown", blade = Color3.fromRGB(68, 62, 56), accent = Color3.fromRGB(198, 180, 144), trail = Color3.fromRGB(214, 175, 84), material = Enum.Material.Metal }

-- 0.2 (D15): Tres skins nuevas de la Ruleta (la espada de referencia + espadón y maza compañeros)
Skins.Order[#Skins.Order + 1] = "CrimsonEclipse"
Skins.Data.CrimsonEclipse = {
	name = "Filo del Eclipse Carmesí",
	desc = "Gran premio semanal de la ruleta. Hoja de obsidiana negra con bisel de plata espejo, cinco colmillos dorsales y una vena de relámpago carmesí alimentada por tres rubíes de sangre.",
	weapon = "Sword",
	rarity = "Legendary",
	currency = "Coins",
	price = 9500,
	comingSoon = false,
	roulette = true,
	weeklyPrize = true,
	design = "CrimsonEclipse",
	source = "Notas/Referencias/espada-concepto.png",
	blade = Color3.fromRGB(22, 22, 28),
	accent = Color3.fromRGB(218, 224, 236),
	trail = Color3.fromRGB(235, 22, 38),
	material = Enum.Material.Metal,
}

Skins.Order[#Skins.Order + 1] = "BloodMoonCleaver"
Skins.Data.BloodMoonCleaver = {
	name = "Mandoble de Sangre Lunar",
	desc = "Premio de la ruleta. Losa colosal de obsidiana negra con filo de plata biselado, sierra dorsal desgarradora y arterias de relámpago carmesí.",
	weapon = "Greatsword",
	rarity = "Legendary",
	currency = "Coins",
	price = 9000,
	comingSoon = false,
	roulette = true,
	design = "BloodMoonCleaver",
	blade = Color3.fromRGB(20, 20, 26),
	accent = Color3.fromRGB(214, 220, 232),
	trail = Color3.fromRGB(230, 24, 42),
	material = Enum.Material.Metal,
}

Skins.Order[#Skins.Order + 1] = "CataclysmMaw"
Skins.Data.CataclysmMaw = {
	name = "Quebrantahuesos del Eclipse",
	desc = "Premio de la ruleta. Maza real de obsidiana y plata afilada cuyas aletas curvas y colmillos dorsales laten con relámpagos carmesí.",
	weapon = "Mace",
	rarity = "Legendary",
	currency = "Coins",
	price = 9000,
	comingSoon = false,
	roulette = true,
	design = "CataclysmMaw",
	blade = Color3.fromRGB(22, 22, 28),
	accent = Color3.fromRGB(214, 220, 232),
	trail = Color3.fromRGB(235, 26, 44),
	material = Enum.Material.Metal,
}

-- 10/11/2026: Eclipse Carmesí para dagas y estoque (mismo concepto que la espada), también de la ruleta
Skins.Order[#Skins.Order + 1] = "EclipseFang"
Skins.Data.EclipseFang = {
	name = "Colmillos del Eclipse Carmesí",
	desc = "Premio de la ruleta. Dagas gemelas de obsidiana con bisel de plata espejo, garras en la guarda y una vena de relámpago carmesí.",
	weapon = "Dagger",
	rarity = "Legendary",
	currency = "Coins",
	price = 9000,
	comingSoon = false,
	roulette = true,
	design = "EclipseFang",
	blade = Color3.fromRGB(22, 22, 28),
	accent = Color3.fromRGB(214, 220, 232),
	trail = Color3.fromRGB(235, 22, 38),
	material = Enum.Material.Metal,
}

Skins.Order[#Skins.Order + 1] = "EclipseNeedle"
Skins.Data.EclipseNeedle = {
	name = "Aguja del Eclipse Carmesí",
	desc = "Premio de la ruleta. Estoque de obsidiana con cazoleta de plata, rubíes de sangre y un relámpago carmesí que corre hasta la punta.",
	weapon = "Rapier",
	rarity = "Legendary",
	currency = "Coins",
	price = 9000,
	comingSoon = false,
	roulette = true,
	design = "EclipseNeedle",
	blade = Color3.fromRGB(22, 22, 28),
	accent = Color3.fromRGB(214, 220, 232),
	trail = Color3.fromRGB(235, 22, 38),
	material = Enum.Material.Metal,
}

-- 10/11/2026: candidatas a skin exclusiva semanal (versión "con rayos" de las skins de la tienda, en
-- SkinDesignsStorm). Todavía no están activas: para usar una, crearle su entrada en Skins.Data con
-- roulette = true y un design que la lea de SkinDesignsStorm, y sumarla a Rewards.WeeklySkins.
Skins.WeeklyPool = {
	"Fangs", "LivingThorns", "VoidMoons", "SilverCrescent", "EclipseClaws",
	"RequiemHorns", "Solar", "Ossuary", "DawnCrown", "DragonEdge", "Violet", "Void", "ExileTooth", "DraconicRelic",
	"EmeraldTomb", "Devourer", "RoyalMourning", "DuskCross", "Shroud", "AbyssWings",
	"Duel", "SilverCut", "FireTongue", "TwilightDuel", "SpectralSting", "AmethystVeil", "DarkLament",
	"Flange", "CrimsonShards", "NorthExecutioner", "Forge", "AncientMaw", "OssuaryAxe", "AbyssVertebra", "SepulcherJaws", "OssuaryCrown",
}

-- 10/11/2026: las 36 versiones con rayos vuelven como skins de las cajas de Tormenta (solo cajas, no se compran
-- ni salen en la ruleta). Id = id de la original + "Storm"; diseño = SkinDesignsStorm. Rareza según el precio de
-- la original (Skins.StormRarity), así las cajas caras dan más Legendarias. Nombre: Localization (skin.stormName).
Skins.StormRarity = { { maxPrice = 1500, rarity = "Rare" }, { maxPrice = 3100, rarity = "Epic" }, { maxPrice = math.huge, rarity = "Legendary" } }
do
	local byDesign = {}
	for _, id in Skins.Order do
		local s = Skins.Data[id]
		if s and s.design and not s.roulette and not byDesign[s.design] then byDesign[s.design] = id end
	end
	for _, design in Skins.WeeklyPool do
		local origId = byDesign[design]
		local o = origId and Skins.Data[origId]
		if o then
			local id = origId .. "Storm"
			local rarity = "Epic"
			for _, tier in Skins.StormRarity do
				if (o.price or 0) <= tier.maxPrice then rarity = tier.rarity break end
			end
			local s = table.clone(o)
			s.design = design .. "Storm"
			s.rarity = rarity
			s.stormOf = origId
			s.boxOnly = "Storm"
			s.roulette = nil
			s.weeklyPrize = nil
			s.productId = nil
			s.source = nil
			Skins.Order[#Skins.Order + 1] = id
			Skins.Data[id] = s
		end
	end
end

for id, skin in Skins.Data do
	skin.nameKey = "skin." .. id
	skin.descKey = "skinDesc." .. id
	skin.rarity = skin.rarity or "Common"
end
Skins.Data.Charcoal.price = 300
Skins.Data.Gold.price = 600
Skins.Data.Cyber.rarity = "Rare"
Skins.Data.Blood.rarity = "Rare"
Skins.Data.Relic18.accent = Color3.fromRGB(216, 210, 193)

Skins.Designs = {}
return Skins
