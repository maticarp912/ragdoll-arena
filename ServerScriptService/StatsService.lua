local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local E = require(RS.Economy)
local Data = require(script.Parent.PlayerData)
local Missions = require(script.Parent.MissionService)
local Remotes = require(script.Parent.Remotes)
local Events = require(script.Parent.CombatEvents)
local Summary = Remotes.get("MatchSummary")
local Feed = Remotes.get("KillFeed")
require(script.Parent.LeaderboardService)
local Service = {}
local active = {}
function Service.begin(group, mode)
 for _, player in group do active[player] = { group = group, mode = mode, kills = E.Zero, knockdowns = E.Zero, damage = E.Zero, dead = {} } end
end
Events.Fired:Connect(function(kind, attackerChar, victimChar, info)
 local victim = victimChar and Players:GetPlayerFromCharacter(victimChar)
 local attacker = attackerChar and Players:GetPlayerFromCharacter(attackerChar)
 local v = victim and active[victim]
 if not v or not victim:GetAttribute("InMatch") then return end
 local a = attacker and active[attacker]
 if not a or a.group ~= v.group or not attacker:GetAttribute("InMatch") or attacker == victim or attacker.Team == victim.Team then attacker = nil a = nil end
 if kind == "Kill" then
  if v.dead[victimChar] then return end
  v.dead[victimChar] = true victim:SetAttribute("Eliminated", true)
 end
 if a then
  local data = Data.get(attacker)
  if not data then return end
  if kind == "Damage" then a.damage += math.max(E.Zero, tonumber(info.amount) or E.Zero)
  elseif kind == "Kill" then a.kills += E.One data.Stats.Kills = (data.Stats.Kills or E.Zero) + E.One
  elseif kind == "Knockdown" then a.knockdowns += E.One data.Stats.Knockdowns = (data.Stats.Knockdowns or E.Zero) + E.One end
  Missions.progress(attacker, kind, kind == "Damage" and math.max(E.Zero, tonumber(info.amount) or E.Zero) or E.One)
  Data.refresh(attacker)
 end
 if kind == "Kill" or kind == "Knockdown" then
  local message = { kind = kind, killer = attacker and attacker.Name, victim = victim.Name, killerTeam = attacker and attacker.Team and attacker.Team.Name, victimTeam = victim.Team and victim.Team.Name }
  for _, player in v.group do if player.Parent and player:GetAttribute("InMatch") then Feed:FireClient(player, message) end end
 end
end)
function Service.finish(player, won)
 local a = active[player] active[player] = nil
 local data = Data.get(player) if not a or not data then return end
 data.Stats.Matches = (data.Stats.Matches or E.Zero) + E.One
 if won then data.Stats.Wins = (data.Stats.Wins or E.Zero) + E.One end
 local coins = (won and E.Match.Win or E.Match.Lose) + math.min(E.Match.CombatCap, a.kills * E.Match.Kill + a.knockdowns * E.Match.Knockdown)
 local day = math.floor(os.time() / E.DaySeconds)
 if won and data.FirstWinDay ~= day then data.FirstWinDay = day coins += E.Match.FirstWin end
 data.Stats.Coins = (data.Stats.Coins or E.Zero) + coins
 Data.addCoins(player, coins)
 Missions.progress(player, "Match", E.One, data.WeaponId)
 if won then Missions.progress(player, "Win", E.One) end
 local available = E.Zero
 local daily = Missions.get(player)
 for _, m in daily and daily.list or {} do if not m.claimed and m.progress >= m.goal then available += m.reward end end
 -- Missions are claimable separately: total is the actually awarded match amount.
 if player.Parent then Summary:FireClient(player, { result = won and "Win" or "Lose", mode = a.mode, kills = a.kills, knockdowns = a.knockdowns, damage = math.floor(a.damage), coins = { match = coins, missions = E.Zero, total = coins }, missionCoinsAvailable = available }) end
 task.spawn(Data.save, player)
end
Players.PlayerRemoving:Connect(function(player) active[player] = nil end)
return Service
