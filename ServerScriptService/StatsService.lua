local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local E = require(RS.Economy)
local Data = require(script.Parent.PlayerData)
local Missions = require(script.Parent.MissionService)
local Progression = require(script.Parent.ProgressionService)
local Telemetry = require(script.Parent.Telemetry)
local Remotes = require(script.Parent.Remotes)
local Events = require(script.Parent.CombatEvents)
local Summary = Remotes.get("MatchSummary")
local Feed = Remotes.get("KillFeed")
require(script.Parent.LeaderboardService)
local Service = {}
local active = {}
function Service.begin(group, mode)
 for _, player in group do
  active[player] = { group = group, mode = mode, weapon = player:GetAttribute("WeaponId"), started = os.clock(), kills = 0, knockdowns = 0, damage = 0, dead = {} }
  Telemetry.emit(player, "WeaponSelected", 1, player:GetAttribute("WeaponId"), mode)
 end
end
Events.Fired:Connect(function(kind, attackerChar, victimChar, info)
 local attacker = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
 local a = attacker and active[attacker]
 -- Parry's attacker is the defender; it may not have a victim player.
 if kind == "Parry" and a and attacker:GetAttribute("InMatch") and Data.get(attacker) then Missions.progress(attacker, kind, 1, a.weapon) return end
 local victim = victimChar and Players:GetPlayerFromCharacter(victimChar)
 local v = victim and active[victim]
 if not v or not victim:GetAttribute("InMatch") then return end
 if not a or a.group ~= v.group or not attacker:GetAttribute("InMatch") or attacker == victim or attacker.Team == victim.Team then attacker = nil a = nil end
 if kind == "Kill" then
  if v.dead[victimChar] then return end
  v.dead[victimChar] = true victim:SetAttribute("Eliminated", true)
 end
 if a then
  local d = Data.get(attacker) if not d then return end
  local amount = type(info) == "table" and tonumber(info.amount) or 0
  if not amount or amount ~= amount or math.abs(amount) == math.huge then amount = 0 end
  if kind == "Damage" then a.damage += math.max(0, amount)
  elseif kind == "Kill" then a.kills += 1 d.Stats.Kills = (d.Stats.Kills or 0) + 1
  elseif kind == "Knockdown" then a.knockdowns += 1 d.Stats.Knockdowns = (d.Stats.Knockdowns or 0) + 1 end
  Missions.progress(attacker, kind, kind == "Damage" and math.max(0, amount) or 1, a.weapon)
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
 if won then
  d.Stats.Wins = (d.Stats.Wins or 0) + 1
  Telemetry.emit(player, "WeaponWin", 1, a.weapon, a.mode)
 end
 local coins = (won and E.Match.Win or E.Match.Lose) + math.min(E.Match.CombatCap, a.kills * E.Match.Kill + a.knockdowns * E.Match.Knockdown)
 local day = math.floor((os.time() - E.DayOffset) / E.DaySeconds)
 if won and d.FirstWinDay ~= day then d.FirstWinDay = day coins *= E.Match.FirstWinMultiplier end
 local mult = d.Boosts.CoinsSeconds > 0 and d.Boosts.Coins or 1
 coins = math.floor(coins * mult)
 d.Stats.Coins = (d.Stats.Coins or 0) + coins Data.addCoins(player, coins)
 local xpBefore, levelBefore = d.XP, d.Level
 local earned = Progression.grant(player, require(RS.Progression).Sources.Match + (won and require(RS.Progression).Sources.Win or 0) + a.kills * require(RS.Progression).Sources.Kill)
 Missions.progress(player, "Match", 1, a.weapon)
 if won then Missions.progress(player, "Win", 1, a.weapon) end
 local available = 0
 local daily = Missions.get(player)
 for _, m in daily and daily.list or {} do if not m.claimed and m.progress >= m.goal then available += m.reward end end
 if player.Parent then Summary:FireClient(player, { result = result, mode = a.mode, kills = a.kills, knockdowns = a.knockdowns, damage = math.floor(a.damage), coins = { match = coins, missions = 0, total = coins }, missionCoinsAvailable = available, progression = { xp = earned, xpBefore = xpBefore, xpAfter = d.XP, levelBefore = levelBefore, level = d.Level, xpNext = require(RS.Progression).required(d.Level) } }) end
 Data.saveSoon(player)
end
-- Runs synchronously BEFORE PlayerData snapshots/releases a leaving profile.
Data.beforeRelease(function(player) Service.finish(player, false, true) end)
return Service
