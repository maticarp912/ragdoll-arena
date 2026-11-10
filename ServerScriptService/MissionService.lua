local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local E = require(RS.Economy)
local Catalog = require(RS.Missions)
local Data = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)
local Changed = Remotes.get("MissionsChanged")
local RF = Remotes.get("Missions", "RemoteFunction")
local Progression = require(script.Parent.ProgressionService)
local claimAt = {}
Players.PlayerRemoving:Connect(function(p) claimAt[p] = nil end)
local Service = {}
local function daily(player)
 local data = Data.get(player) if not data then return nil end
 local day = math.floor((os.time() - E.DayOffset) / E.DaySeconds)
 if data.Daily.day ~= day then
  data.Daily = { day = day, progress = {}, claimed = {} }
 end
 return data.Daily
end
local function selection(day)
 local ids = {}
 for i = E.One, Catalog.DailyCount do
  table.insert(ids, Catalog.Order[(day * Catalog.RotationStep + i - E.One) % #Catalog.Order + E.One])
 end
 return ids
end
function Service.get(player)
 local d = daily(player) if not d then return nil end
 local list = {}
 for _, id in selection(d.day) do
  local m = Catalog.Data[id]
  table.insert(list, { id = id, nameKey = "cx.mission." .. id, params = { goal = m.goal }, progress = d.progress[id] or E.Zero, goal = m.goal, reward = m.reward, claimed = d.claimed[id] == true })
 end
 return { resetAt = (d.day + E.One) * E.DaySeconds + E.DayOffset, list = list }
end
function Service.progress(player, event, amount, weapon)
 local d = daily(player) if not d then return end
 local changed = false
 for _, id in selection(d.day) do
  local m = Catalog.Data[id]
  if m.event == event and (not m.weapon or m.weapon == weapon) and not d.claimed[id] then
   local old = d.progress[id] or E.Zero
   d.progress[id] = math.min(m.goal, old + amount)
   changed = changed or old ~= d.progress[id]
  end
 end
 if changed and player.Parent then Changed:FireClient(player) end
end
RF.OnServerInvoke = function(player, action, id)
 local now = os.clock()
 if claimAt[player] and now - claimAt[player] < E.ShopInterval then return false, { key = "cx.shop.wait" } end
 claimAt[player] = now
 if type(action) ~= "string" then return false, { key = "invalid" } end
 if action == "Get" then return Service.get(player) end
 if action ~= "Claim" or type(id) ~= "string" then return false, { key = "invalid" } end
 local d = daily(player)
 if not d or not table.find(selection(d.day), id) then return false, { key = "invalid" } end
 local m = Catalog.Data[id]
 if d.claimed[id] or (d.progress[id] or E.Zero) < m.goal then return false, { key = "cx.mission.notReady" } end
 -- No yield between claim marker and reward: duplicate requests cannot grant twice.
 d.claimed[id] = true
 local data = Data.get(player)
 data.Stats.Coins = (data.Stats.Coins or E.Zero) + m.reward
 Data.addCoins(player, m.reward)
 Progression.source(player, "Mission")
 Changed:FireClient(player)
 Data.saveSoon(player)
 return true, { key = "cx.mission.claimed", params = { amount = m.reward } }
end
task.spawn(function()
 local lastDay = math.floor((os.time() - E.DayOffset) / E.DaySeconds)
 while true do
  task.wait(E.LeaderboardInterval)
  local day = math.floor((os.time() - E.DayOffset) / E.DaySeconds)
  if day ~= lastDay then
   lastDay = day
   for _, player in Players:GetPlayers() do daily(player) Changed:FireClient(player) end
  end
 end
end)
return Service
