-- ModuleScript: ReplicatedStorage/Titles
-- 11/11/2026: títulos de la tarjeta del jugador (estilo Call of Duty). NO van sobre la cabeza: ahí solo nombre y
-- rangos [OWNER][ADMIN][VIP]. Son solo texto, por eso hay muchos.
-- Cómo se consiguen (campo source):
--   role  → automático por rol (role = "Owner"...)
--   pass  → automático con un pase (pass = "VIP")
--   stat  → automático al llegar a `goal` en data.Stats[stat] (Kills, Knockdowns, Wins, Matches ya se cuentan;
--           Parries, RingOuts, Kicks, GuardBreaks, Finishers y Throws los empieza a contar Codex en StatsService)
--   shop  → se compra con almas (`price`) desde la pestaña Títulos (TitleService → "Buy")
--   level / mastery / achievement → los concede el servidor correspondiente en data.Titles[id] = true
-- Textos en los tres idiomas acá mismo (es / en / pt). Los de nivel y maestría usan su clave de idioma (nameKey).

local Titles = {}

local function T(es, en, pt, rarity, extra)
	local t = { es = es, en = en, pt = pt, rarity = rarity }
	for k, v in extra or {} do t[k] = v end
	return t
end

Titles.Data = {
	-- Por rol
	DeadKing = T("El Rey Muerto", "The Dead King", "O Rei Morto", "Mythic", { source = "role", role = "Owner" }),
	ThroneExecutioner = T("Verdugo del Trono", "Executioner of the Throne", "Carrasco do Trono", "Legendary", { source = "role", role = "Admin" }),
	ShadowWarden = T("Guardián de las Sombras", "Warden of Shadows", "Guardião das Sombras", "Epic", { source = "role", role = "Mod" }),
	SoulTester = T("Probador de Almas", "Soul Tester", "Provador de Almas", "Rare", { source = "role", role = "Tester" }),
	-- Por pase
	EclipseHerald = T("Heraldo del Eclipse", "Herald of the Eclipse", "Arauto do Eclipse", "Legendary", { source = "pass", pass = "VIP" }),

	-- Eliminaciones
	Kills10 = T("Primera Sangre", "First Blood", "Primeiro Sangue", "Common", { source = "stat", stat = "Kills", goal = 10 }),
	Kills100 = T("Segador de Almas", "Soul Reaper", "Ceifador de Almas", "Rare", { source = "stat", stat = "Kills", goal = 100 }),
	Kills1000 = T("Heraldo de la Muerte", "Herald of Death", "Arauto da Morte", "Epic", { source = "stat", stat = "Kills", goal = 1000 }),
	Kills10000 = T("Señor de los Mil Sepulcros", "Lord of a Thousand Graves", "Senhor dos Mil Sepulcros", "Legendary", { source = "stat", stat = "Kills", goal = 10000 }),
	Kills50000 = T("La Peste Encarnada", "Plague Incarnate", "A Peste Encarnada", "Mythic", { source = "stat", stat = "Kills", goal = 50000 }),
	-- Derribos
	Knock50 = T("Rompehuesos", "Bonebreaker", "Quebra-Ossos", "Common", { source = "stat", stat = "Knockdowns", goal = 50 }),
	Knock500 = T("Martillo del Ocaso", "Hammer of Dusk", "Martelo do Ocaso", "Rare", { source = "stat", stat = "Knockdowns", goal = 500 }),
	Knock5000 = T("El Que Doblega Reyes", "Breaker of Kings", "Aquele Que Dobra Reis", "Epic", { source = "stat", stat = "Knockdowns", goal = 5000 }),
	Knock25000 = T("Terror de los Caídos", "Terror of the Fallen", "Terror dos Caídos", "Legendary", { source = "stat", stat = "Knockdowns", goal = 25000 }),
	-- Victorias
	Wins10 = T("Superviviente del Foso", "Pit Survivor", "Sobrevivente do Fosso", "Common", { source = "stat", stat = "Wins", goal = 10 }),
	Wins100 = T("Campeón de Ceniza", "Champion of Ash", "Campeão das Cinzas", "Rare", { source = "stat", stat = "Wins", goal = 100 }),
	Wins1000 = T("El Inquebrantable", "The Unbroken", "O Inquebrável", "Epic", { source = "stat", stat = "Wins", goal = 1000 }),
	Wins5000 = T("Soberano de la Arena", "Sovereign of the Arena", "Soberano da Arena", "Legendary", { source = "stat", stat = "Wins", goal = 5000 }),
	-- Partidas jugadas
	Matches50 = T("Peregrino de Sangre", "Blood Pilgrim", "Peregrino de Sangue", "Common", { source = "stat", stat = "Matches", goal = 50 }),
	Matches500 = T("Veterano del Abismo", "Veteran of the Abyss", "Veterano do Abismo", "Rare", { source = "stat", stat = "Matches", goal = 500 }),
	Matches5000 = T("Eterno Condenado", "Eternally Damned", "Eterno Condenado", "Epic", { source = "stat", stat = "Matches", goal = 5000 }),
	-- Parrys
	Parry100 = T("Muro de Hierro", "Iron Wall", "Muro de Ferro", "Rare", { source = "stat", stat = "Parries", goal = 100 }),
	Parry1000 = T("Danza de Espadas", "Dance of Blades", "Dança das Lâminas", "Epic", { source = "stat", stat = "Parries", goal = 1000 }),
	Parry10000 = T("El Intocable", "The Untouchable", "O Intocável", "Legendary", { source = "stat", stat = "Parries", goal = 10000 }),
	-- Caídas al vacío provocadas
	Ring50 = T("Empujador de Almas", "Soul Shover", "Empurrador de Almas", "Common", { source = "stat", stat = "RingOuts", goal = 50 }),
	Ring500 = T("Guardián del Vacío", "Warden of the Void", "Guardião do Vazio", "Epic", { source = "stat", stat = "RingOuts", goal = 500 }),
	Ring5000 = T("Boca del Abismo", "Maw of the Abyss", "Boca do Abismo", "Legendary", { source = "stat", stat = "RingOuts", goal = 5000 }),
	-- Patadas, guardias rotas, remates y lanzamientos
	Kick100 = T("Bota de Hierro", "Iron Boot", "Bota de Ferro", "Rare", { source = "stat", stat = "Kicks", goal = 100 }),
	Kick1000 = T("Pisoteador de Tumbas", "Grave Stomper", "Pisoteador de Túmulos", "Epic", { source = "stat", stat = "Kicks", goal = 1000 }),
	Break250 = T("Quiebraescudos", "Shieldbreaker", "Quebra-Escudos", "Rare", { source = "stat", stat = "GuardBreaks", goal = 250 }),
	Break2500 = T("Ruina de las Guardias", "Bane of Guards", "Ruína das Guardas", "Epic", { source = "stat", stat = "GuardBreaks", goal = 2500 }),
	Finisher100 = T("Verdugo Implacable", "Relentless Executioner", "Carrasco Implacável", "Epic", { source = "stat", stat = "Finishers", goal = 100 }),
	Finisher1000 = T("Fin de Todas las Cosas", "End of All Things", "Fim de Todas as Coisas", "Legendary", { source = "stat", stat = "Finishers", goal = 1000 }),
	Throw100 = T("Lanzador de Cadáveres", "Corpse Hurler", "Arremessador de Cadáveres", "Rare", { source = "stat", stat = "Throws", goal = 100 }),

	-- Con almas (tienda de títulos)
	Nightwalker = T("Caminante Nocturno", "Nightwalker", "Andarilho Noturno", "Common", { source = "shop", price = 1000 }),
	AshChild = T("Hijo de la Ceniza", "Child of Ash", "Filho das Cinzas", "Common", { source = "shop", price = 1500 }),
	GraveWhisper = T("Susurro de Tumba", "Grave Whisper", "Sussurro de Túmulo", "Common", { source = "shop", price = 1800 }),
	NightmareBearer = T("Portador de Pesadillas", "Nightmare Bearer", "Portador de Pesadelos", "Rare", { source = "shop", price = 3000 }),
	NamelessShade = T("Sombra sin Nombre", "Nameless Shade", "Sombra sem Nome", "Rare", { source = "shop", price = 3500 }),
	Bloodsworn = T("Juramentado de Sangre", "Bloodsworn", "Juramentado de Sangue", "Rare", { source = "shop", price = 4000 }),
	HollowKnight = T("Caballero Hueco", "Hollow Knight", "Cavaleiro Oco", "Rare", { source = "shop", price = 4500 }),
	RavenLament = T("Lamento del Cuervo", "Raven's Lament", "Lamento do Corvo", "Epic", { source = "shop", price = 6000 }),
	ThornCrown = T("Corona de Espinas", "Crown of Thorns", "Coroa de Espinhos", "Epic", { source = "shop", price = 7500 }),
	EclipseHeretic = T("Hereje del Eclipse", "Eclipse Heretic", "Herege do Eclipse", "Epic", { source = "shop", price = 9000 }),
	ChainedSaint = T("Santo Encadenado", "Chained Saint", "Santo Acorrentado", "Epic", { source = "shop", price = 10000 }),
	OssuaryKing = T("Último Rey del Osario", "Last King of the Ossuary", "Último Rei do Ossário", "Legendary", { source = "shop", price = 15000 }),
	LightDevourer = T("Aquel que Devora la Luz", "Devourer of Light", "Aquele que Devora a Luz", "Legendary", { source = "shop", price = 20000 }),
	VoidHeir = T("Heredero del Vacío", "Heir of the Void", "Herdeiro do Vazio", "Mythic", { source = "shop", price = 35000 }),

	-- Logros especiales (los concede Codex)
	Undying = T("El Que No Muere", "The Undying", "Aquele Que Não Morre", "Epic", { source = "achievement", hint = "mz.titleHint.Undying" }),
	Collector = T("Coleccionista de Reliquias", "Relic Collector", "Colecionador de Relíquias", "Legendary", { source = "achievement", hint = "mz.titleHint.Collector" }),
	Duelist = T("Duelista del Crepúsculo", "Twilight Duelist", "Duelista do Crepúsculo", "Rare", { source = "achievement", hint = "mz.titleHint.Duelist", track = "DuelistWins", goal = 25 }),
	BondedBlades = T("Hermanos de Acero", "Bonded Blades", "Irmãos de Aço", "Rare", { source = "achievement", hint = "mz.titleHint.BondedBlades", track = "PartyWins", goal = 25 }),

	-- Por nivel y maestría (ya existían; se guardan con su clave de idioma)
	["cx.title.25"] = { nameKey = "cx.title.25", rarity = "Rare", source = "level" },
	["cx.title.50"] = { nameKey = "cx.title.50", rarity = "Epic", source = "level" },
	["cx.title.75"] = { nameKey = "cx.title.75", rarity = "Legendary", source = "level" },
	["cx.title.100"] = { nameKey = "cx.title.100", rarity = "Mythic", source = "level" },
	["cx.mastery.title.Sword"] = { nameKey = "cx.mastery.title.Sword", rarity = "Epic", source = "mastery" },
	["cx.mastery.title.Greatsword"] = { nameKey = "cx.mastery.title.Greatsword", rarity = "Epic", source = "mastery" },
	["cx.mastery.title.Dagger"] = { nameKey = "cx.mastery.title.Dagger", rarity = "Epic", source = "mastery" },
	["cx.mastery.title.Rapier"] = { nameKey = "cx.mastery.title.Rapier", rarity = "Epic", source = "mastery" },
	["cx.mastery.title.Mace"] = { nameKey = "cx.mastery.title.Mace", rarity = "Epic", source = "mastery" },
}


local ROMAN = {
	{1000, "M"}, {900, "CM"}, {500, "D"}, {400, "CD"}, {100, "C"}, {90, "XC"}, {50, "L"},
	{40, "XL"}, {10, "X"}, {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"},
}
local function roman(n)
	local parts = {}
	for _, digit in ROMAN do
		local count = math.floor(n / digit[1])
		if count > 0 then table.insert(parts, string.rep(digit[2], count)) n %= digit[1] end
	end
	return table.concat(parts)
end

function Titles.rebirthId(weapon, rebirths)
	return "cx.mastery.title." .. weapon .. "." .. (rebirths + 1)
end

-- Rebirth titles use the same translated weapon title on the card, with a Roman numeral.
setmetatable(Titles.Data, {
	__index = function(data, id)
		if type(id) ~= "string" or #id > 64 then return nil end
		local weapon, suffix = string.match(id, "^cx%.mastery%.title%.([%a]+)%.(%d+)$")
		if not weapon then return nil end
		local base = rawget(data, "cx.mastery.title." .. weapon)
		local rank = tonumber(suffix)
		if not base or not rank or rank < 2 or rank > 100001 or tostring(rank) ~= suffix then return nil end
		return { nameKey = base.nameKey, rarity = "Legendary", source = "mastery", roman = roman(rank) }
	end,
})

-- Orden para listas: por fuente y después por rareza y meta/precio
local SOURCE_ORDER = { role = 1, pass = 2, stat = 3, achievement = 4, level = 5, mastery = 6, shop = 7 }
local RARITY_ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5 }
Titles.Order = {}
for id in Titles.Data do table.insert(Titles.Order, id) end
table.sort(Titles.Order, function(a, b)
	local A, B = Titles.Data[a], Titles.Data[b]
	local sa, sb = SOURCE_ORDER[A.source] or 9, SOURCE_ORDER[B.source] or 9
	if sa ~= sb then return sa < sb end
	if A.stat ~= B.stat then return tostring(A.stat) < tostring(B.stat) end
	local ra, rb = RARITY_ORDER[A.rarity] or 0, RARITY_ORDER[B.rarity] or 0
	if ra ~= rb then return ra < rb end
	local va, vb = A.goal or A.price or 0, B.goal or B.price or 0
	if va ~= vb then return va < vb end
	return a < b
end)

-- Texto del título en el idioma pedido ("ES", "EN", "PT-BR"); translate = función L.t para los de nameKey
function Titles.text(id, lang, translate)
	local t = Titles.Data[id]
	if not t then return nil end
	if t.nameKey and translate then
		local s = translate(t.nameKey)
		if s and s ~= t.nameKey then return t.roman and (s .. " " .. t.roman) or s end
	end
	if lang == "EN" then return t.en or t.es end
	if lang == "PT-BR" then return t.pt or t.en or t.es end
	return t.es or t.en or id
end

-- ¿El jugador tiene este título?
--   owned = data.Titles · role = atributo Role · passes = { VIP = true } · stats = data.Stats
function Titles.owns(id, owned, role, passes, stats)
	local t = Titles.Data[id]
	if not t then return false end
	if t.role then return role == t.role end
	if t.pass then return passes ~= nil and passes[t.pass] == true end
	if owned ~= nil and owned[id] == true then return true end
	if t.stat and t.goal and stats then return (tonumber(stats[t.stat]) or 0) >= t.goal end
	return false
end

return Titles
