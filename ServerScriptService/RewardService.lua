-- Server authority for earned rewards. Value-changing paths never yield.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local R = require(RS:WaitForChild("Rewards"))
local P = require(RS:WaitForChild("Progression"))
local Skins = require(RS:WaitForChild("Skins"))
local Weapons = require(RS:WaitForChild("WeaponData"))
local Data = require(script.Parent.PlayerData)
local Progression = require(script.Parent.ProgressionService)
local Telemetry = require(script.Parent.Telemetry)
local Remotes = require(script.Parent.Remotes)
local RF = Remotes.get("Rewards")
local Changed = Remotes.get("RewardsChanged")
local Announcement = Remotes.get("RewardAnnouncement")
local random = Random.new()
local Service = {}
local last, joined, connections = {}, {}, {}
local pendingChanged = {}
local function fail(key) return false, { key = key or "cx.reward.notReady" } end
local function notify(player)
 Data.refresh(player) Progression.refresh(player) Data.saveSoon(player)
 -- Coalesce bursts and let the client's read happen after the remote cooldown.
 if player.Parent and not pendingChanged[player] then
  pendingChanged[player] = true
  local function flush()
   if not pendingChanged[player] then return end
   local remaining = R.NotifyDelay - (os.clock() - (last[player] or 0))
   if player.Parent and remaining > 0 then task.delay(remaining, flush) return end
   pendingChanged[player] = nil
   if player.Parent and Data.get(player) then Changed:FireClient(player) end
  end
  task.delay(R.NotifyDelay, flush)
 end
end
local function profile(player)
 local data = Data.get(player) if not data then return nil end
 local d = data.Rewards
 local day = R.day(os.time())
 if d.day ~= day then d.day = day d.paidSpins = 0 Data.saveSoon(player) end
 local week = R.week(day)
 if type(d.weekly) ~= "table" or d.weekly.week ~= week then d.weekly = { week = week, progress = 0, claimed = false } Data.saveSoon(player) end
 local progress = d.weekly.progress
 if type(progress) ~= "number" or progress ~= progress or math.abs(progress) == math.huge then progress = 0 end
 d.weekly.progress = math.clamp(math.floor(progress), 0, R.Weekly[week % #R.Weekly + 1].goal)
 if not joined[player] then
  joined[player] = true
  if d.lastVisit >= 0 and day - d.lastVisit >= R.ReturnDays then
   d.spins = math.min(R.MaxCount, d.spins + 1) d.returnNotice = true
  end
  d.loginCount = math.min(R.MaxCount, d.loginCount + (d.lastVisit ~= day and 1 or 0))
  if type(d.firstDay) ~= "number" or d.firstDay ~= d.firstDay or d.firstDay < 0 or d.firstDay > day then d.firstDay = day end
  local age = day - d.firstDay
  if d.lastVisit ~= day then
   Telemetry.emit(player, "RewardLogin", 1, nil, nil, tostring(age == 1 and "D1" or (age == 7 and "D7" or (age == 30 and "D30" or "Other"))))
  end
  d.lastVisit = day Data.saveSoon(player)
  Telemetry.emit(player, "RewardEnter")
 elseif d.lastVisit ~= day then d.lastVisit = day Data.saveSoon(player)
 end
 return data, d, day
end
local function skinPool(rarity)
 local pool = {}
 for id, skin in Skins.Data do
  if id ~= "Default" and not skin.comingSoon and skin.currency ~= "Robux" and skin.rarity == rarity then table.insert(pool, id) end
 end
 table.sort(pool) return pool
end
local function weighted(rows, minRank)
 local total = 0
 for _, row in rows do if not minRank or R.RarityRank[row.rarity] >= minRank then total += row.weight end end
 assert(total > 0, "Empty reward distribution")
 local n = random:NextNumber() * total
 for i, row in rows do
  if not minRank or R.RarityRank[row.rarity] >= minRank then
   n -= row.weight if n <= 0 then return table.clone(row), i end
  end
 end
 return table.clone(rows[#rows]), #rows
end
local function souls(player, amount)
 local data = Data.get(player)
 data.Stats.Coins = (data.Stats.Coins or 0) + amount
 Data.addCoins(player, amount)
end
local function award(player, reward, weeklySkin)
 local data = Data.get(player)
 local out = table.clone(reward) out.weight = nil
 if out.kind == "WeeklySkin" then out.kind = "Skin" out.id = weeklySkin end
 if out.kind == "Skin" then
  local skin = Skins.Data[out.id]
  assert(skin and not skin.comingSoon, "Missing reward skin")
  out.rarity = skin.rarity
  if Data.owns(player, "OwnedSkins", out.id) then
   out.duplicate = out.id out.kind = "Souls" out.amount = math.floor(skin.price * R.DuplicateFraction)
   souls(player, out.amount)
  else data.OwnedSkins[out.id] = true end
 elseif out.kind == "Souls" then souls(player, out.amount)
 elseif out.kind == "XP" then out.earned, out.levels, out.levelRewards = Progression.grant(player, out.amount)
 elseif out.kind == "Boost" then Progression.boost(player, out.stat, out.multiplier, out.seconds)
 elseif out.kind == "Box" then data.Boxes[out.id] = math.min(R.MaxCount, data.Boxes[out.id] + out.amount) end
 if out.rarity == "Legendary" and out.kind == "Skin" and not out.duplicate then
  Announcement:FireAllClients({ key = "cx.reward.announcement", params = { name = player.DisplayName, prizeKey = "skin." .. out.id }, reward = out })
 end
 return out
end
function Service.progress(player, event, amount)
 local data, d = profile(player) if not data then return end
 if event == "Level" and data.Level >= P.EarlyLevels and not d.level5 then d.level5 = true Telemetry.emit(player, "Level5") end
 local changed = false
 for _, step in R.FirstSteps do
  if step.event == event then
   local old = d.steps[step.id]
   d.steps[step.id] = math.min(step.goal, event == "Level" and data.Level or old + amount)
   changed = changed or d.steps[step.id] ~= old
  end
 end
 local weekly = R.Weekly[d.weekly.week % #R.Weekly + 1]
 if weekly.event == event and not d.weekly.claimed then
  d.weekly.progress = math.min(weekly.goal, d.weekly.progress + amount) changed = true
 end
 if changed then notify(player) end
end
function Service.collection(player)
 local data, d = profile(player) if not data then return {} end
 local list, granted = {}, false
 for weapon, aura in R.Collection do
  local owned, total, ids = 0, 0, {}
  for id, skin in Skins.Data do
   if id ~= "Default" and not skin.comingSoon and (not skin.weapon or skin.weapon == weapon) then
    total += 1 local has = Data.owns(player, "OwnedSkins", id)
    if has then owned += 1 end
    table.insert(ids, { id = id, owned = has })
   end
  end
  table.sort(ids, function(a, b) return a.id < b.id end)
  -- Owner's effective catalogue must not persist collection rewards as purchases.
  if total > 0 and owned == total and not d.collection[weapon] and not player:GetAttribute("AllCosmetics") then
   d.collection[weapon] = true data.OwnedAuras[aura] = true granted = true
   Telemetry.emit(player, "CollectionComplete", 1, weapon)
  end
  list[weapon] = { owned = owned, total = total, percent = total > 0 and owned / total or 0, aura = aura, claimed = d.collection[weapon] == true, skins = ids }
 end
 if granted then notify(player) end
 return list
end
local function probabilities(rows, minRank)
 local result, total = {}, 0
 for _, row in rows do if not minRank or R.RarityRank[row.rarity] >= minRank then total += row.weight end end
 for i, row in rows do
  local r = table.clone(row) r.index = i
  r.probability = (not minRank or R.RarityRank[row.rarity] >= minRank) and row.weight / total or 0
  table.insert(result, r)
 end
 return result
end
function Service.getState(player)
 local data, d, day = profile(player) if not data then return nil end
 Service.progress(player, "Level", 0)
 local weekly = R.Weekly[d.weekly.week % #R.Weekly + 1]
 local steps, complete = {}, true
 for _, step in R.FirstSteps do
  table.insert(steps, { id = step.event, nameKey = "cx.firstSteps." .. step.id, progress = d.steps[step.id], goal = step.goal })
  complete = complete and d.steps[step.id] >= step.goal
 end
 local boxes = {}
 for id, box in R.Boxes do
  local guaranteed = id == "Relic" and d.relicPity >= R.RelicPity - 1
  local rows = probabilities(box.rarities or box.rewards, guaranteed and R.GoodRank or nil)
  if box.rarities then
   for _, row in rows do
    row.skins = skinPool(row.rarity)
    row.probabilityPerSkin = #row.skins > 0 and row.probability / #row.skins or 0
   end
  end
  boxes[id] = { count = data.Boxes[id], price = box.price, nameKey = box.nameKey, probabilities = rows, guaranteed = guaranteed }
 end
 local tutorialCount = 0 for i = 1, R.TutorialSteps do if d.tutorial[tostring(i)] == true then tutorialCount += 1 end end
 local roulette = probabilities(R.Roulette)
 local weeklySkin = R.weeklySkin(day)
 for _, row in roulette do
  if row.kind == "WeeklySkin" then row.id = weeklySkin end
  row.effectiveProbability = d.spinPity >= R.RoulettePity and (row.kind == "WeeklySkin" and 1 or 0) or row.probability
  row.tutorialProbability = d.spinPity >= R.RoulettePity and (row.kind == "WeeklySkin" and 1 or 0) or (row.index == R.TutorialSpinSector and 1 or 0)
 end
 local mastery = {}
 for _, weapon in Weapons.Order do
  local m = data.Mastery[weapon]
  mastery[weapon] = { level = m and m.level or 1, xp = m and m.xp or 0, xpNext = m and m.level == P.Mastery.MaxLevel and 0 or P.Mastery.XPPerLevel, titleKey = "cx.mastery.title." .. weapon, finish = P.Mastery.Finishes[weapon], trail = P.Mastery.Trails[weapon] }
 end
 return {
  souls = data.Coins, nextRequest = tostring(d.sequence + 1), resetAt = R.nextDay(day), weekResetAt = R.nextWeek(day),
  weeklySkin = weeklySkin, roulette = roulette, spinPity = d.spinPity, spinGuarantee = R.RoulettePity,
  freeSpin = d.freeDay ~= day, spins = d.spins, paidSpins = d.paidSpins,
  paidSpinsRemaining = math.max(0, #R.ExtraSpinPrices - d.paidSpins),
  paidSpinPrice = R.ExtraSpinPrices[d.paidSpins + 1], relicPity = d.relicPity, relicGuarantee = R.RelicPity,
  boxes = boxes, boosts = data.Boosts,
  streak = { day = d.streak, canClaim = d.streakDay ~= day, rewards = R.Streak, graceAvailable = d.graceWeek ~= R.week(day), paused = d.streakDay >= 0 and day - d.streakDay > 1 },
  weekly = { event = weekly.event, nameKey = "cx.weekly." .. weekly.event, goal = weekly.goal, progress = d.weekly.progress, claimed = d.weekly.claimed },
  starter = { chosen = d.starter == true, choices = R.StarterSkins },
  tutorial = { completed = tutorialCount, steps = d.tutorial, skipped = d.tutorialSkipped == true, spinAvailable = d.tutorialReady == true and not d.tutorialSpin },
  firstSteps = { list = steps, canClaim = complete and not d.firstStepsClaimed, claimed = d.firstStepsClaimed == true, skin = R.FirstStepsSkin },
  returnNotice = d.returnNotice == true, collection = Service.collection(player), mastery = mastery,
  notifications = { spin = d.freeDay ~= day or d.spins > 0 or (d.tutorialReady and not d.tutorialSpin) == true, streak = d.streakDay ~= day, weekly = d.weekly.progress >= weekly.goal and not d.weekly.claimed, firstSteps = complete and not d.firstStepsClaimed },
 }
end
function Service.buyBoost(player, id)
 local data = Data.get(player) local spec = R.Boosts[id]
 if not data or not spec then return fail("invalid") end
 if player:GetAttribute("InMatch") then return fail("locked") end
 if not Data.canMutate(player) then return fail("cx.shop.wait") end
 if data.Coins < spec.price then return fail("noCoins") end
 local b = data.Boosts
 if b[spec.stat .. "Seconds"] + spec.seconds > P.MaxBoostSeconds then return fail("cx.reward.boostFull") end
 Data.addCoins(player, -spec.price) Progression.boost(player, spec.stat, spec.multiplier, spec.seconds)
 notify(player) return true, { key = "cx.reward.boostBought" }
end
function Service.tutorial(player, step)
 local data, d = profile(player)
 if not data or type(step) ~= "number" or step % 1 ~= 0 or step < 1 or step > R.TutorialSteps then return false end
 if d.tutorialSkipped or d.tutorial[tostring(step)] then return false end
 -- Called only by trusted server tutorial/combat events; never a client remote.
 d.tutorial[tostring(step)] = true souls(player, R.TutorialSouls)
 Telemetry.emit(player, "RewardClaim", 1, nil, nil, "TutorialStep")
 local complete = true for i = 1, R.TutorialSteps do complete = complete and d.tutorial[tostring(i)] == true end
 if complete then d.tutorialReady = true Telemetry.emit(player, "TutorialComplete") end
 -- Presentation only; the souls above have already been granted once by the server.
 Changed:FireClient(player, { reward = { kind = "Souls", amount = R.TutorialSouls }, source = "Tutorial" })
 notify(player) return true
end
function Service.match(player, won, weapon, kills)
 local data, d = profile(player) if not data then return nil end
 local bonus = 0
 if not d.firstMatch then d.firstMatch = true bonus = R.FirstMatchSouls souls(player, bonus) Telemetry.emit(player, "FirstMatch") Telemetry.emit(player, "RewardClaim", 1, nil, nil, "FirstMatch") end
 Service.progress(player, "Match", 1) if won then Service.progress(player, "Win", 1) end
 Service.progress(player, "Level", 0)
 if data.Level >= P.EarlyLevels and not d.level5 then d.level5 = true Telemetry.emit(player, "Level5") end
 local mastery = Progression.mastery(player, weapon, won, kills)
 local collection = Service.collection(player)
 notify(player)
 return { firstMatchSouls = bonus, mastery = mastery, firstSteps = table.clone(d.steps), weekly = table.clone(d.weekly), collection = collection }
end
function Service.admin(player, action, amount)
 local data, d = profile(player)
 if not data or type(amount) ~= "number" or amount ~= amount or amount % 1 ~= 0 or amount < 1 or amount > R.MaxAdminGrant then return false end
 if action == "Box" or action == "BoxRelic" or action == "BoxSouls" then
  local id = action == "BoxSouls" and "Souls" or "Relic"
  if data.Boxes[id] + amount > R.MaxCount then return false end
  data.Boxes[id] += amount
 elseif action == "Spins" then
  if d.spins + amount > R.MaxCount then return false end d.spins += amount
 elseif action == "Streak" then
  if amount > #R.Streak then return false end
  -- Assign the calendar cursor, never award past days or reset today's claim marker.
  d.streak = amount
 else return false end
 notify(player) return true
end
local function act(player, action, id, source)
 local data, d, day = profile(player) if not data then return fail("loading") end
 if action == "GetState" then return true, Service.getState(player) end
 if not Data.canMutate(player) then return fail("cx.shop.wait") end
 if action == "ChooseStarter" then
  if d.starter or not table.find(R.StarterSkins, id) then return fail() end
  if not Skins.Data[id] or Skins.Data[id].comingSoon then return fail("cx.reward.unavailable") end
  d.starter = true data.OwnedSkins[id] = true
  notify(player) return true, { key = "cx.reward.claimed", reward = { kind = "Skin", id = id, rarity = Skins.Data[id].rarity } }
 elseif action == "SkipTutorial" then
  if d.tutorialReady then return fail() end
  d.tutorialSkipped = true d.tutorialReady = true
  Telemetry.emit(player, "TutorialSkipped")
 elseif action == "DismissReturn" then d.returnNotice = false
 elseif action == "ClaimStreak" then
  if d.streakDay == day then return fail() end
  if d.streakDay >= 0 and day - d.streakDay == R.GraceDays + 1 and d.graceWeek ~= R.week(day) then d.graceWeek = R.week(day) end
  d.streak = d.streak % #R.Streak + 1 d.streakDay = day
  local reward = R.Streak[d.streak]
  local spec = type(reward) == "number" and { kind = "Souls", amount = reward } or { kind = "Box", id = reward, amount = 1, rarity = "Epic" }
  local granted = award(player, spec)
  notify(player) return true, { key = "cx.reward.claimed", reward = granted }
 elseif action == "ClaimWeekly" then
  local weekly = R.Weekly[d.weekly.week % #R.Weekly + 1]
  if d.weekly.claimed or d.weekly.progress < weekly.goal then return fail() end
  d.weekly.claimed = true data.Boxes.Relic = math.min(R.MaxCount, data.Boxes.Relic + 1)
  notify(player) return true, { key = "cx.reward.claimed", reward = { kind = "Box", id = "Relic", amount = 1, rarity = "Epic" } }
 elseif action == "ClaimFirstSteps" then
  Service.progress(player, "Level", 0)
  if d.firstStepsClaimed then return fail() end
  for _, step in R.FirstSteps do if d.steps[step.id] < step.goal then return fail() end end
  if not Skins.Data[R.FirstStepsSkin] or Skins.Data[R.FirstStepsSkin].comingSoon then return fail("cx.reward.unavailable") end
  d.firstStepsClaimed = true
  local reward = award(player, { kind = "Skin", id = R.FirstStepsSkin })
  Service.collection(player) notify(player) return true, { key = "cx.reward.claimed", reward = reward }
 elseif action == "Spin" then
  local grandPrize = Skins.Data[R.weeklySkin(day)]
  if not grandPrize or grandPrize.comingSoon then return fail("cx.reward.unavailable") end
  local mode = id
  if mode == nil then mode = d.tutorialReady and not d.tutorialSpin and "Tutorial" or (d.freeDay ~= day and "Free" or "Ticket") end
  if mode == "Tutorial" then
   if not d.tutorialReady or d.tutorialSpin then return fail() end d.tutorialSpin = true
  elseif mode == "Free" then
   if d.freeDay == day then return fail() end d.freeDay = day
  elseif mode == "Ticket" then
   if d.spins < 1 then return fail() end d.spins -= 1
  elseif mode == "Paid" then
   local price = R.ExtraSpinPrices[d.paidSpins + 1]
   if not price then return fail() end if data.Coins < price then return fail("noCoins") end
   Data.addCoins(player, -price) d.paidSpins += 1
  else return fail("invalid") end
  local row, sector
  if d.spinPity >= R.RoulettePity then sector = #R.Roulette row = table.clone(R.Roulette[sector])
  elseif mode == "Tutorial" then sector = R.TutorialSpinSector row = table.clone(R.Roulette[sector])
  else row, sector = weighted(R.Roulette) end
  d.spinPity = row.kind == "WeeklySkin" and 0 or d.spinPity + 1
  local reward = award(player, row, R.weeklySkin(day))
  -- Tutorial always includes its promised boost even when pity takes priority.
  local bonus
  if mode == "Tutorial" and sector ~= R.TutorialSpinSector then bonus = award(player, R.Roulette[R.TutorialSpinSector]) end
  Service.progress(player, "Spin", 1) Service.progress(player, "Level", 0)
  Telemetry.emit(player, "RewardSpin", 1, nil, nil, mode)
  Service.collection(player) notify(player)
  return true, { key = "cx.reward.claimed", sector = sector, reward = reward, bonus = bonus, mode = mode }
 elseif action == "BuyBox" or action == "OpenBox" then
  local box = R.Boxes[id] if not box then return fail("invalid") end
  local purchase = action == "BuyBox" or source == "Buy"
  if purchase then
   if data.Coins < box.price then return fail("noCoins") end
   if data.Boxes[id] >= R.MaxCount then return fail() end
  elseif data.Boxes[id] < 1 then return fail() end
  local row
  if action == "OpenBox" then
   if id == "Relic" then
    local rarity = weighted(box.rarities, d.relicPity >= R.RelicPity - 1 and R.GoodRank or nil)
    local pool = skinPool(rarity.rarity)
    if #pool == 0 then return fail("cx.reward.unavailable") end
    row = { kind = "Skin", id = pool[random:NextInteger(1, #pool)], rarity = rarity.rarity }
   else row = weighted(box.rewards) end
  end
  if purchase then Data.addCoins(player, -box.price) else data.Boxes[id] -= 1 end
  if action == "BuyBox" then data.Boxes[id] += 1
  else
   if id == "Relic" then d.relicPity = R.RarityRank[row.rarity] >= R.GoodRank and 0 or d.relicPity + 1 end
   local reward = award(player, row)
   Service.progress(player, "OpenBox", 1) Service.progress(player, "Level", 0)
   Telemetry.emit(player, "RewardBox", 1, nil, nil, id)
   Service.collection(player) notify(player) return true, { key = "cx.reward.claimed", reward = reward, box = id }
  end
 else return fail("invalid") end
 notify(player) return true, { key = "cx.reward.claimed" }
end
local idActions = { ChooseStarter = true, Spin = true, BuyBox = true, OpenBox = true }
RF.OnServerInvoke = function(player, action, id, source, requestId)
 local now = os.clock()
 if last[player] and now - last[player] < R.Interval then return fail("cx.shop.wait") end
 last[player] = now
 if type(action) ~= "string" or #action > R.MaxIdLength then return fail("invalid") end
 if id ~= nil and (type(id) ~= "string" or #id > R.MaxIdLength) then return fail("invalid") end
 if not idActions[action] and id ~= nil then return fail("invalid") end
 if source ~= nil and (type(source) ~= "string" or action ~= "OpenBox" or (source ~= "Owned" and source ~= "Buy")) then return fail("invalid") end
 if requestId ~= nil and (type(requestId) ~= "string" or #requestId == 0 or #requestId > R.MaxIdLength) then return fail("invalid") end
 local data = Data.get(player) if not data then return fail("loading") end
 local d = data.Rewards
 -- Optional durable retry key: a replay never spends or awards twice.
 if requestId and type(d.lastRequest) == "table" and d.lastRequest.id == requestId then
  local old = d.lastRequest
  if old.action ~= action or old.item ~= id or old.source ~= source then return fail("invalid") end
  return old.ok, old.result
 end
 if requestId and action ~= "GetState" and requestId ~= tostring(d.sequence + 1) then return fail("cx.reward.stale") end
 local ok, result = act(player, action, id, source)
 if ok and action ~= "GetState" then
  Telemetry.emit(player, "RewardClaim", 1, nil, nil, action)
  d.sequence += 1 result.nextRequest = tostring(d.sequence + 1)
  d.lastRequest = { id = requestId or tostring(d.sequence), action = action, item = id, source = source, ok = ok, result = result }
  Data.saveSoon(player)
 end
 return ok, result
end
local function watch(player)
 local list = {}
 connections[player] = list
 table.insert(list, player:GetAttributeChangedSignal("ProfileState"):Connect(function() if Data.get(player) then profile(player) end end))
 table.insert(list, player:GetAttributeChangedSignal("OwnedSkins"):Connect(function() Service.collection(player) end))
 if Data.get(player) then profile(player) end
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do watch(player) end
Players.PlayerRemoving:Connect(function(player)
 for _, connection in connections[player] or {} do connection:Disconnect() end
 connections[player] = nil last[player] = nil joined[player] = nil pendingChanged[player] = nil
end)
-- The tutorial owner can emit this trusted server event after validating a step.
require(script.Parent.CombatEvents).Fired:Connect(function(kind, attackerChar, victimChar, info)
 if kind ~= "TutorialStep" or type(info) ~= "table" then return end
 local player = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
 if player and not player:GetAttribute("InMatch") then Service.tutorial(player, info.step) end
end)
Data.beforeRelease(function(player)
 local data = Data.get(player)
 if data then data.Rewards.lastVisit = R.day(os.time()) end
end)
return Service
