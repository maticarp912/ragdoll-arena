local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local P = require(RS:WaitForChild("Progression"))
local Data = require(script.Parent.PlayerData)
local Service = {}
local last = {}
local function valid(n) return type(n) == "number" and n == n and n >= 0 and n <= P.MaxGrant end
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
 player:SetAttribute("MultEnds", player:GetAttribute("InMatch") and workspace:GetAttribute("MatchPhase") == "Round" and workspace:GetServerTimeNow() + remaining or 0)
end
function Service.grant(player, amount)
 local d = Data.get(player) if not d or not valid(amount) then return 0 end
 if d.Level >= P.MaxLevel then Service.refresh(player) return 0, 0 end
 local before = d.Level
 local mult = d.Boosts.XPSeconds > 0 and d.Boosts.XP or 1
 local earned = math.floor(amount * mult)
 d.XP += earned
 while d.Level < P.MaxLevel and d.XP >= P.required(d.Level) do
  d.XP -= P.required(d.Level) d.Level += 1
  if P.Titles[d.Level] then d.Titles[P.Titles[d.Level]] = true end
  if d.Level <= P.EarlyLevels then Data.addCoins(player, P.EarlyCoins) end
  if d.Level % P.EveryCoins == 0 then Data.addCoins(player, P.LevelCoins) end
  if d.Level % P.EveryBox == 0 then d.Boxes.Relic += 1 end
 end
 if d.Level == P.MaxLevel then d.XP = 0 end
 Service.refresh(player) Data.saveSoon(player)
 return earned, d.Level - before
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
RunService.Heartbeat:Connect(function(dt)
 for _, player in Players:GetPlayers() do
  local d = Data.get(player)
  if d then
   d.PlaySeconds += dt
   if player:GetAttribute("InMatch") and workspace:GetAttribute("MatchPhase") == "Round" then
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
