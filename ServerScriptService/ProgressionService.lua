local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local P = require(RS:WaitForChild("Progression"))
local Data = require(script.Parent.PlayerData)
local Service = {}
local Weapons = require(RS:WaitForChild("WeaponData"))
local last = {}
local function valid(n) return type(n) == "number" and n == n and n >= 0 and n <= P.MaxGrant end
local function playing(player)
 local char = player.Character local hum = char and char:FindFirstChildOfClass("Humanoid")
 return player:GetAttribute("InMatch") and player:GetAttribute("MatchPhase") == "Round" and not player:GetAttribute("Eliminated") and hum and hum.Health > 0 and not char:GetAttribute("Frozen") and char:GetAttribute("CanFight") == true
end
function Service.refresh(player)
 local d = Data.get(player) if not d then return end
 player:SetAttribute("Level", d.Level) player:SetAttribute("XP", d.XP)
 player:SetAttribute("XPNext", P.required(d.Level))
 local b = d.Boosts
 player:SetAttribute("MultXP", b.XPSeconds > 0 and b.XP or 1)
 player:SetAttribute("MultCoins", b.CoinsSeconds > 0 and b.Coins or 1)
 -- Remaining PLAY seconds, projected to server time only during Round.
 local remaining = math.max(b.XPSeconds, b.CoinsSeconds)
 player:SetAttribute("MultRemaining", remaining)
 player:SetAttribute("MultEnds", playing(player) and workspace:GetServerTimeNow() + remaining or 0)
end
function Service.grant(player, amount)
 local d = Data.get(player) if not d or not valid(amount) then return 0 end
 if d.Level >= P.MaxLevel then Service.refresh(player) return 0, 0 end
 local before = d.Level
 local mult = d.Boosts.XPSeconds > 0 and d.Boosts.XP or 1
 local earned = math.floor(amount * mult)
 local rewards = { souls = 0, boxes = 0, titles = {} }
 d.XP += earned
 while d.Level < P.MaxLevel and d.XP >= P.required(d.Level) do
  d.XP -= P.required(d.Level) d.Level += 1
  if P.Titles[d.Level] then d.Titles[P.Titles[d.Level]] = true table.insert(rewards.titles, P.Titles[d.Level]) end
  if d.Level <= P.EarlyLevels then rewards.souls += P.EarlyCoins end
  if d.Level % P.EveryCoins == 0 then rewards.souls += P.LevelCoins end
  if d.Level % P.EveryBox == 0 then d.Boxes.Relic += 1 rewards.boxes += 1 end
 end
 if d.Level == P.MaxLevel then d.XP = 0 end
 if rewards.souls > 0 then d.Stats.Coins = (d.Stats.Coins or 0) + rewards.souls Data.addCoins(player, rewards.souls) end
 Service.refresh(player) Data.saveSoon(player)
 return earned, d.Level - before, rewards
end
function Service.source(player, source)
 return Service.grant(player, P.Sources[source] or 0)
end
function Service.setLevel(player, level)
 local d = Data.get(player)
 if not d or not valid(level) or level % 1 ~= 0 or level < 1 or level > P.MaxLevel then return false end
 -- Administrative assignment is not a level-up reward exploit.
 d.Level = level d.XP = 0 Service.refresh(player) Data.saveSoon(player) return true
end
function Service.boost(player, kind, multiplier, seconds)
 local d = Data.get(player)
 if not d or (kind ~= "XP" and kind ~= "Coins") or not valid(multiplier) or multiplier < 1 or multiplier > P.MaxMultiplier or not valid(seconds) then return false end
 local b = d.Boosts local key = kind .. "Seconds"
 b[kind] = b[key] > 0 and math.max(b[kind], multiplier) or multiplier
 b[key] = math.min(P.MaxBoostSeconds, b[key] + seconds)
 Service.refresh(player) Data.saveSoon(player) return true
end
function Service.mastery(player, weapon, won, kills)
 local d = Data.get(player)
 if not d or not Weapons.Data[weapon] then return nil end
 local m = d.Mastery[weapon]
 if type(m) ~= "table" then m = { level = 1, xp = 0, awarded = {} } d.Mastery[weapon] = m end
 local cfg = P.Mastery
 if type(m.awarded) ~= "table" then m.awarded = {} end
 local function bounded(n, fallback, max)
  return type(n) == "number" and n == n and math.abs(n) < math.huge and math.clamp(math.floor(n), 0, max) or fallback
 end
 m.level = math.max(1, bounded(m.level, 1, cfg.MaxLevel))
 m.xp = bounded(m.xp, 0, cfg.XPPerLevel - 1)
 local before, xpBefore = m.level, m.xp
 local earned = cfg.MatchXP + (won and cfg.WinXP or 0) + kills * cfg.KillXP
 if m.level < cfg.MaxLevel then m.xp += earned else earned = 0 end
 while m.level < cfg.MaxLevel and m.xp >= cfg.XPPerLevel do m.xp -= cfg.XPPerLevel m.level += 1 end
 if m.level == cfg.MaxLevel then m.xp = 0 end
 local unlocked = {}
 for kind, level in { Finish = cfg.FinishLevel, Trail = cfg.TrailLevel, Title = cfg.TitleLevel } do
  if m.level >= level and not m.awarded[kind] then
   m.awarded[kind] = true
   local id = kind == "Finish" and cfg.Finishes[weapon] or (kind == "Trail" and cfg.Trails[weapon] or "cx.mastery.title." .. weapon)
   if kind == "Finish" then d.OwnedSkins[id] = true elseif kind == "Trail" then d.OwnedAuras[id] = true else d.Titles[id] = true end
   table.insert(unlocked, { kind = kind, id = id })
  end
 end
 Data.refresh(player) Data.saveSoon(player)
 return { weapon = weapon, levelBefore = before, level = m.level, xpBefore = xpBefore, xp = earned, xpAfter = m.xp, xpNext = m.level < cfg.MaxLevel and cfg.XPPerLevel or 0, unlocked = unlocked }
end
RunService.Heartbeat:Connect(function(dt)
 for _, player in Players:GetPlayers() do
  local d = Data.get(player)
  if d then
   d.PlaySeconds += dt
   if playing(player) then
    for _, kind in { "XP", "Coins" } do
     local key = kind .. "Seconds" d.Boosts[key] = math.max(0, d.Boosts[key] - dt)
     if d.Boosts[key] == 0 then d.Boosts[kind] = 1 end
    end
   end
   last[player] = (last[player] or 0) + dt
   if last[player] >= P.Tick then last[player] = 0 Service.refresh(player) end
  end
 end
end)
Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
return Service
