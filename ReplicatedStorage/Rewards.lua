-- Initial retention tuning. All random outcomes are selected by RewardService.
local Config = require(script.Parent.MonetizationConfig)
local R = {
 Version = 1, Interval = 0.35, MaxCount = 100000, WeekDays = 7, MondayOffset = 4, WeekAnchor = 2966, ReturnDays = 3,
 SpinGuarantee = 30, RelicGuarantee = 10, DuplicateRate = 0.4, DuplicateFallback = 1500,
 ExtraPrices = { 250, 500, 1000 }, DailySouls = { 50, 75, 100, 125, 150, 200 },
 StarterSkins = { "Charcoal", "Frost", "Gold" }, FirstMatch = 300, TutorialSouls = 100, TutorialSteps = 3,
 WeeklyGoals = { Win = 15, Parry = 40 }, FirstGoals = { Match = 3, Win = 1, Parry = 5, Equip = 1, Spin = 1, OpenBox = 1, Level = 5 },
 WeeklySkins = { "CrimsonEclipse", "BloodMoonCleaver", "CataclysmMaw", "EclipseFang", "EclipseNeedle" },
 Spin = {
  { kind = "Souls", amount = 75, weight = 30 }, { kind = "Souls", amount = 200, weight = 25 },
  { kind = "Souls", amount = 600, weight = 15 }, { kind = "XP", amount = 150, weight = 12 },
  { kind = "Boost", boost = "XP", multiplier = 1.5, seconds = 900, weight = 8 },
  { kind = "Boost", boost = "XP", multiplier = 2, seconds = 1800, weight = 5 },
  { kind = "Box", id = "Relic", amount = 1, weight = 4 }, { kind = "Weekly", weight = 1 },
 },
 TutorialBoost = { kind = "Boost", boost = "XP", multiplier = 2, seconds = 1800 },
 Boxes = { Souls = { price = 500 }, Relic = { price = 1500 },
  -- 10/11/2026: cajas de Tormenta (skins con rayos, Skins.boxOnly = "Storm"). Más caras = mejores rarezas.
  StormLesser = { price = 3000, pool = "Storm", order = 3 },
  StormGreater = { price = 6500, pool = "Storm", order = 4 },
  StormRoyal = { price = 12000, pool = "Storm", order = 5 },
  -- 11/11/2026: sexto cofre, el mejor: siempre Legendaria, de Tormenta o del Eclipse Carmesí (D23).
  Eclipse = { price = 20000, pools = { "Storm", "Roulette" }, order = 6 },
 },
 StormRarities = {
  StormLesser = { { id = "Rare", weight = 72 }, { id = "Epic", weight = 24 }, { id = "Legendary", weight = 4 } },
  StormGreater = { { id = "Rare", weight = 30 }, { id = "Epic", weight = 55 }, { id = "Legendary", weight = 15 } },
  StormRoyal = { { id = "Epic", weight = 62 }, { id = "Legendary", weight = 38 } },
  Eclipse = { { id = "Legendary", weight = 100 } },
 },
 Rarities = { { id = "Common", weight = 60 }, { id = "Rare", weight = 28 }, { id = "Epic", weight = 10 }, { id = "Legendary", weight = 2 } },
 GuaranteedRarities = { { id = "Epic", weight = 10 }, { id = "Legendary", weight = 2 } },
 SoulsBox = {
  { kind = "Souls", amount = 300, weight = 35 }, { kind = "Souls", amount = 750, weight = 20 }, { kind = "Souls", amount = 1500, weight = 5 },
  { kind = "Boost", boost = "XP", multiplier = 1.5, seconds = 900, weight = 15 },
  { kind = "Boost", boost = "Coins", multiplier = 2, seconds = 1800, weight = 15 },
  { kind = "Boost", boost = "XP", multiplier = 3, seconds = 3600, weight = 5 },
  { kind = "Boost", boost = "Coins", multiplier = 3, seconds = 3600, weight = 5 },
 },
 AntiAFK = { Sample = 0.5, MinSeconds = 1, MinDistance = 6, MinEvents = 1, MaxStep = 16, MinStep = 0.4 },
 CollectionAuras = { Sword = "AshCrown", Greatsword = "SmokeWings", Dagger = "FootShroud", Rapier = "GraveRunes", Mace = "SpectralChains" },
}
-- Public C19 names. Compatibility aliases above retain the initial tuning.
R.Schema = 2
R.DaySeconds = 86400 R.DayOffset = 10800 R.Tick = 0.5 R.MaxIdLength = 64
R.NotifyDelay = R.Interval + 0.05
-- Reserved for a future version: no prompt, sales or receipt handler in 0.2.
-- Activate only after configuring a real product and server receipt fulfilment.
R.RobuxSpinPack = { enabled = false, productId = 0, spins = 3 }
R.MaxAdminGrant = 100 R.MaxSequence = 1e12 R.GraceDays = 1 R.GoodRank = 3
R.FirstMatchSouls = R.FirstMatch R.DuplicateFraction = R.DuplicateRate
R.RoulettePity = R.SpinGuarantee R.RelicPity = R.RelicGuarantee
R.ExtraSpinPrices = R.ExtraPrices R.Collection = R.CollectionAuras
R.RarityRank = { Common = 1, Rare = 2, Epic = 3, Legendary = 4 }
R.FirstStepsSkin = "Requiem"
R.Streak = table.clone(R.DailySouls) table.insert(R.Streak, "Relic")
R.FirstSteps = {
 { id = "matches", event = "Match", goal = 3 }, { id = "win", event = "Win", goal = 1 },
 { id = "parries", event = "Parry", goal = 5 }, { id = "equip", event = "Equip", goal = 1 },
 { id = "spin", event = "Spin", goal = 1 }, { id = "box", event = "OpenBox", goal = 1 },
 { id = "level", event = "Level", goal = 5 },
}
R.Weekly = { { event = "Win", goal = R.WeeklyGoals.Win }, { event = "Parry", goal = R.WeeklyGoals.Parry } }
R.TutorialSpinSector = 6
R.Roulette = {}
local sectorRarities = { "Common", "Common", "Rare", "Rare", "Rare", "Epic", "Epic", "Legendary" }
for i, row in R.Spin do
 local item = table.clone(row) item.stat = item.boost item.boost = nil item.rarity = sectorRarities[i]
 if item.kind == "Weekly" then item.kind = "WeeklySkin" end
 R.Roulette[i] = item
end
-- First tutorial spin has the same sector geometry and its guaranteed x2 reward.
R.Roulette[R.TutorialSpinSector].stat = "XP"
R.Boxes.Souls.nameKey = "cx.reward.box.Souls" R.Boxes.Souls.rewards = {}
for i, row in R.SoulsBox do
 local item = table.clone(row) item.stat = item.boost item.boost = nil
 item.rarity = item.kind == "Boost" and (item.multiplier >= 3 and "Epic" or "Rare") or (item.amount >= 1500 and "Epic" or "Common")
 R.Boxes.Souls.rewards[i] = item
end
R.Boxes.Relic.nameKey = "cx.reward.box.Relic" R.Boxes.Relic.rarities = {}
for i, row in R.Rarities do R.Boxes.Relic.rarities[i] = { rarity = row.id, weight = row.weight } end
R.Boxes.Souls.order = 1 R.Boxes.Relic.order = 2
for id, rows in R.StormRarities do
 local box = R.Boxes[id] box.nameKey = "cx.reward.box." .. id box.descKey = "cx.reward.box." .. id .. ".desc" box.rarities = {}
 for i, row in rows do box.rarities[i] = { rarity = row.id, weight = row.weight } end
end
R.BoxOrder = {} for id in R.Boxes do table.insert(R.BoxOrder, id) end
table.sort(R.BoxOrder, function(a, b) return (R.Boxes[a].order or 99) < (R.Boxes[b].order or 99) end)
R.BoostOrder = { "Boost2xCoins", "Boost2xXp", "BoostSoulMagnet" }
R.Boosts = {
 Boost2xCoins = { stat = "Coins", multiplier = 2, seconds = 1800, price = 1200, nameKey = "cx.reward.boost.Boost2xCoins", descKey = "cx.reward.boost.desc" },
 Boost2xXp = { stat = "XP", multiplier = 2, seconds = 1800, price = 1400, nameKey = "cx.reward.boost.Boost2xXp", descKey = "cx.reward.boost.desc" },
 BoostSoulMagnet = { stat = "Coins", multiplier = 3, seconds = 900, price = 2400, nameKey = "cx.reward.boost.BoostSoulMagnet", descKey = "cx.reward.boost.desc" },
}
function R.day(now) return math.floor((now - R.DayOffset) / R.DaySeconds) end
function R.week(day) return math.floor((day - R.MondayOffset) / R.WeekDays) end
function R.weeklySkin(day) return R.WeeklySkins[(R.week(day) - R.WeekAnchor) % #R.WeeklySkins + 1] end
function R.nextDay(day) return (day + 1) * R.DaySeconds + R.DayOffset end
function R.nextWeek(day) return (R.week(day) * R.WeekDays + R.MondayOffset + R.WeekDays) * R.DaySeconds + R.DayOffset end
function R.exclusiveAura(id)
 for _, aura in R.Collection do if id == aura then return true end end
 return false
end
function R.Luck(data, now, readOnly)
 local boosts = data.Boosts
 local multiplier = math.clamp(boosts.Luck or 1, 1, Config.Products.Luck30.multiplier)
 local elapsed = math.max(0, now - (boosts.LuckUpdatedAt or now))
 local remaining = multiplier > 1 and math.max(0, (boosts.LuckSeconds or 0) - elapsed) or 0
 if remaining == 0 then multiplier = 1 end
 if not readOnly then
  boosts.Luck = multiplier boosts.LuckSeconds = remaining boosts.LuckUpdatedAt = now
 end
 return multiplier, remaining
end
function R.boxWeight(row, multiplier)
 return R.RarityRank[row.rarity] >= R.GoodRank and row.weight * multiplier or row.weight
end
function R.reconcile(data)
 local function count(t, key, fallback, max)
  local n = t[key]
  if type(n) ~= "number" or n ~= n or math.abs(n) == math.huge then n = fallback end
  t[key] = math.floor(math.clamp(n, -1, max or R.MaxCount))
 end
 local function object(t, key) if type(t[key]) ~= "table" then t[key] = {} end return t[key] end
 local d = object(data, "Rewards")
 for _, key in { "spins", "boughtSpins", "spinPity", "relicPity", "paidSpins", "streak", "loginCount" } do count(d, key, 0) d[key] = math.max(0, d[key]) end
 for _, key in { "day", "lastVisit", "freeDay", "vipDay", "streakDay", "graceWeek" } do count(d, key, -1) end
 count(d, "streak", 0, #R.Streak) count(d, "spinPity", 0, R.RoulettePity) count(d, "relicPity", 0, R.RelicPity - 1)
 count(d, "paidSpins", 0, #R.ExtraSpinPrices)
 count(d, "sequence", 0, R.MaxSequence) d.sequence = math.max(0, d.sequence)
 object(d, "steps") object(d, "tutorial") object(d, "collection")
 for _, step in R.FirstSteps do count(d.steps, step.id, 0, step.goal) d.steps[step.id] = math.max(0, d.steps[step.id]) end
 local boxes = object(data, "Boxes")
 local paidBoxes = object(d, "paidBoxes")
 for id in R.Boxes do
  count(boxes, id, 0) boxes[id] = math.max(0, boxes[id])
  count(paidBoxes, id, 0, boxes[id]) paidBoxes[id] = math.max(0, paidBoxes[id])
 end
 local boosts = object(data, "Boosts")
 local now = os.time()
 local luck = boosts.Luck
 if type(luck) ~= "number" or luck ~= luck or math.abs(luck) == math.huge then luck = 1 end
 boosts.Luck = math.clamp(luck, 1, Config.Products.Luck30.multiplier)
 count(boosts, "LuckSeconds", 0) boosts.LuckSeconds = math.max(0, boosts.LuckSeconds)
 count(boosts, "LuckUpdatedAt", now, now)
 if boosts.LuckUpdatedAt < 0 then boosts.LuckUpdatedAt = now end
 R.Luck(data, now)
 object(data, "Mastery")
 local progression = require(script.Parent.Progression)
 for weapon in R.Collection do
  local m = data.Mastery[weapon]
  if type(m) == "table" then
   count(m, "level", 1, progression.Mastery.MaxLevel) m.level = math.max(1, m.level)
   count(m, "xp", 0, progression.Mastery.XPPerLevel - 1) m.xp = math.max(0, m.xp)
   object(m, "awarded")
  else data.Mastery[weapon] = nil end
 end
 return d
end
return R
