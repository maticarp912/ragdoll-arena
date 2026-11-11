local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local E = require(RS.Economy)
local Data = require(script.Parent.PlayerData)
local Missions = require(script.Parent.MissionService)
local Progression = require(script.Parent.ProgressionService)
local Telemetry = require(script.Parent.Telemetry)
local Remotes = require(script.Parent.Remotes)
local Events = require(script.Parent.CombatEvents)
local Rewards = require(script.Parent.RewardService)
local R = require(RS.Rewards)
local Titles = require(RS.Titles)
local Party = require(script.Parent.PartyService)
local RunService = game:GetService("RunService")
local Summary = Remotes.get("MatchSummary")
local Feed = Remotes.get("KillFeed")
require(script.Parent.LeaderboardService)
local Service = {}
local active = {}

local STAT_EVENTS = { Parry = "Parries", RingOut = "RingOuts", Kick = "Kicks", GuardBreak = "GuardBreaks", Throw = "Throws" }

-- MatchService publishes cumulative points at the end of each round.
local function recordRoundScore()
 local key = workspace:GetAttribute("StatusKey")
 if key ~= "cx.match.point" and key ~= "cx.match.draw" then return end
 local encoded = workspace:GetAttribute("StatusParams")
 if type(encoded) ~= "string" then return end
 local ok, score = pcall(HttpService.JSONDecode, HttpService, encoded)
 if not ok or type(score) ~= "table" or type(score.red) ~= "number" or type(score.blue) ~= "number" then return end
 for player, match in active do
  if player:GetAttribute("MatchPhase") == "RoundEnd" then
   local red = match.team and match.team.Name == "Red"
   match.roundWins = math.max(match.roundWins, red and score.red or score.blue)
   match.roundLosses = math.max(match.roundLosses, red and score.blue or score.red)
  end
 end
end
workspace:GetAttributeChangedSignal("StatusKey"):Connect(recordRoundScore)
workspace:GetAttributeChangedSignal("StatusParams"):Connect(recordRoundScore)

local function awardStatTitles(player, d)
 for id, title in Titles.Data do
  if title.stat and (d.Stats[title.stat] or 0) >= title.goal then Data.awardTitle(player, id) end
 end
end

function Service.begin(group, mode)
 for _, player in group do
  if not player.Parent then continue end
  local partner = Party.partner(player)
  if partner and (mode ~= "2v2" or partner.Team ~= player.Team or not table.find(group, partner)) then partner = nil end
  active[player] = { group = group, mode = mode, team = player.Team, partyPartner = partner, roundWins = 0, roundLosses = 0, weapon = player:GetAttribute("WeaponId"), started = os.clock(), kills = 0, knockdowns = 0, damage = 0, dead = {}, seconds = 0, distance = 0, events = 0, parrys = 0, pending = {}, statCounts = {} }
  Telemetry.emit(player, "WeaponSelected", 1, player:GetAttribute("WeaponId"), mode)
 end
end
local sample = 0
RunService.Heartbeat:Connect(function(dt)
 sample += dt if sample < R.AntiAFK.Sample then return end
 local elapsed = sample sample = 0
 for player, a in active do
  local char = player.Character local root = char and char:FindFirstChild("HumanoidRootPart")
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  if player:GetAttribute("MatchPhase") == "Round" and not player:GetAttribute("Eliminated") and root and hum and hum.Health > 0 and not char:GetAttribute("Frozen") then
   a.seconds += elapsed
   if a.position and a.character == char then
    local delta = root.Position - a.position
    local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
    if not char:GetAttribute("Ragdolled") and not char:GetAttribute("KnockedDown") and not char:GetAttribute("CarriedBy") and (char:GetAttribute("StunnedUntil") or 0) <= workspace:GetServerTimeNow() and distance >= R.AntiAFK.MinStep and distance <= R.AntiAFK.MaxStep then a.distance += distance end
   end
   a.position = root.Position a.character = char
  else a.position = nil end
 end
end)
Events.Fired:Connect(function(kind, attackerChar, victimChar, info)
 local attacker = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
 local a = attacker and active[attacker]
 local victim = victimChar and Players:GetPlayerFromCharacter(victimChar)
 local v = victim and active[victim]
 local phase = victim and victim:GetAttribute("MatchPhase")
 -- Deferred server signals from the decisive hit may arrive after RoundEnd starts.
 if not v or victim.Character ~= victimChar or (phase ~= "Round" and phase ~= "RoundEnd") then return end
 local attackerPhase = attacker and attacker:GetAttribute("MatchPhase")
 if not a or a.group ~= v.group or attacker.Character ~= attackerChar or (attackerPhase ~= "Round" and attackerPhase ~= "RoundEnd") or attacker == victim or attacker.Team == victim.Team then attacker = nil a = nil end
 if kind == "Kill" then
  if v.dead[victimChar] then return end
  v.dead[victimChar] = true victim:SetAttribute("Eliminated", true)
 end
 if a then
  local d = Data.get(attacker) if not d then return end
  info = type(info) == "table" and info or {}
  local amount = tonumber(info.amount) or 0
  if not amount or amount ~= amount or math.abs(amount) == math.huge then amount = 0 end
  if kind == "Damage" then a.damage += math.max(0, amount)
  elseif kind == "Kill" then a.kills += 1
  elseif kind == "Knockdown" then a.knockdowns += 1
  elseif kind == "Parry" then a.parrys += 1 end
  a.events += 1
  a.pending[kind] = (a.pending[kind] or 0) + (kind == "Damage" and math.max(0, amount) or 1)
  local stat = STAT_EVENTS[kind]
  if kind == "Damage" and amount > 0 and (info.finisher == true or (info.finisher == nil and
    attackerChar:GetAttribute("Action") == "M1" and attackerChar:GetAttribute("Finisher") == true)) then stat = "Finishers" end
  if stat then a.statCounts[stat] = (a.statCounts[stat] or 0) + 1 end
  Data.refresh(attacker)
 end
 if kind == "Kill" or kind == "Knockdown" then
  local message = { kind = kind, killer = attacker and attacker.Name, victim = victim.Name, killerTeam = attacker and attacker.Team and attacker.Team.Name, victimTeam = victim.Team and victim.Team.Name }
  for _, player in v.group do if player.Parent and player:GetAttribute("InMatch") then Feed:FireClient(player, message) end end
 end
end)
function Service.finish(player, won, abandoned)
 local a = active[player] active[player] = nil
 local d = Data.get(player) if not a or not d then return end
 d.Stats.Matches = (d.Stats.Matches or 0) + 1
 local result = abandoned and "Abandon" or (won and "Win" or "Lose")
 Telemetry.emit(player, "MatchDuration", math.max(0, os.clock() - a.started), a.weapon, a.mode, result)
 if abandoned then
  d.Stats.Abandons = (d.Stats.Abandons or 0) + 1
  Telemetry.emit(player, "MatchAbandoned", 1, a.weapon, a.mode)
  Data.refresh(player) return
 end
 local eligible = a.seconds >= R.AntiAFK.MinSeconds and (a.distance >= R.AntiAFK.MinDistance or a.events >= R.AntiAFK.MinEvents)
 if not eligible then
  if player.Parent then Summary:FireClient(player, { result = result, mode = a.mode, kills = a.kills, knockdowns = a.knockdowns, damage = math.floor(a.damage), coins = { match = 0, missions = 0, total = 0 }, progression = { eligible = false, reasonKey = "cx.reward.afk", xp = 0, levelBefore = d.Level, level = d.Level, xpBefore = d.XP, xpAfter = d.XP, xpNext = require(RS.Progression).required(d.Level) } }) end
  Data.refresh(player) Data.saveSoon(player) return
 end
 for kind, amount in a.pending do Missions.progress(player, kind, amount, a.weapon) end
 d.Stats.Kills = (d.Stats.Kills or 0) + a.kills
 d.Stats.Knockdowns = (d.Stats.Knockdowns or 0) + a.knockdowns
 for stat, count in a.statCounts do d.Stats[stat] = (d.Stats[stat] or 0) + count end
 Rewards.progress(player, "Parry", a.parrys)
 if won then
  d.Stats.Wins = (d.Stats.Wins or 0) + 1
  if a.roundWins > 0 and a.roundLosses == 0 then Data.awardTitle(player, "Undying") end
  local title = a.mode == "1v1" and "Duelist" or (a.partyPartner and "BondedBlades")
  if title then
   local spec = Titles.Data[title]
   d.Stats[spec.track] = (d.Stats[spec.track] or 0) + 1
   if d.Stats[spec.track] >= spec.goal then Data.awardTitle(player, title) end
  end
  Telemetry.emit(player, "WeaponWin", 1, a.weapon, a.mode)
 end
 awardStatTitles(player, d)
 local friendBonus = player:GetAttribute("FriendBonus") == true and E.FriendBonus or 0
 local coins = (won and E.Match.Win or E.Match.Lose) + math.min(E.Match.CombatCap, a.kills * E.Match.Kill + a.knockdowns * E.Match.Knockdown)
 local day = math.floor((os.time() - E.DayOffset) / E.DaySeconds)
 if won and d.FirstWinDay ~= day then d.FirstWinDay = day coins *= E.Match.FirstWinMultiplier end
 local mult = d.Boosts.CoinsSeconds > 0 and d.Boosts.Coins or 1
 coins = math.floor(coins * mult)
 coins = Data.addEarnedCoins(player, coins)
 local xpBefore, levelBefore = d.XP, d.Level
 local earned, levels, levelRewards = Progression.grant(player, require(RS.Progression).Sources.Match + (won and require(RS.Progression).Sources.Win or 0) + a.kills * require(RS.Progression).Sources.Kill, true)
 local levelSouls = levelRewards and levelRewards.souls or 0
 Missions.progress(player, "Match", 1, a.weapon)
 if won then Missions.progress(player, "Win", 1, a.weapon) end
 local beforeBonus = d.Coins
 local rewards = Rewards.match(player, won, a.weapon, a.kills)
 local bonus = d.Coins - beforeBonus
 local available = 0
 local daily = Missions.get(player)
 for _, m in daily and daily.list or {} do if not m.claimed and m.progress >= m.goal then available += m.reward end end
 if player.Parent then Summary:FireClient(player, { result = result, mode = a.mode, kills = a.kills, knockdowns = a.knockdowns, damage = math.floor(a.damage), coins = { match = coins, bonus = bonus, levels = levelSouls, missions = 0, total = coins + bonus + levelSouls }, missionCoinsAvailable = available, friendBonus = friendBonus, progression = { eligible = true, mastery = rewards and rewards.mastery, rewards = rewards, levels = levels or 0, levelRewards = levelRewards, xp = earned, xpBefore = xpBefore, xpAfter = d.XP, levelBefore = levelBefore, level = d.Level, xpNext = require(RS.Progression).required(d.Level) } }) end
 Data.saveSoon(player)
end
-- Runs synchronously BEFORE PlayerData snapshots/releases a leaving profile.
Data.beforeRelease(function(player) Service.finish(player, false, true) end)
return Service
