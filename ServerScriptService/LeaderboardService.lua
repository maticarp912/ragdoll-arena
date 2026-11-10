local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local E = require(RS.Economy)
local Data = require(script.Parent.PlayerData)
local folder = Instance.new("Folder") folder.Name = "Leaderboards" folder.Parent = RS
local boards, names = {}, {}
for _, key in { "Wins", "Kills", "Knockdowns", "Coins" } do
 local value = Instance.new("StringValue") value.Name = key value.Value = "[]" value.Parent = folder
 local ok, store = pcall(function() return DSS:GetOrderedDataStore((RunService:IsStudio() and E.Stores.BoardsStudio or E.Stores.BoardsLive) .. key) end)
 boards[key] = { value = value, store = ok and store or nil }
end
local function nameFor(id)
 local cached = names[id]
 if cached and cached.expires > os.clock() then return cached.name end
 names[id] = nil
 local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
 if ok then
  local count = 0 local oldest, oldestAt
  for key, row in names do count += 1 if not oldestAt or row.expires < oldestAt then oldest = key oldestAt = row.expires end end
  if count >= E.NameCacheLimit then names[oldest] = nil end
  names[id] = { name = name, expires = os.clock() + E.NameCacheTTL }
 end
 return ok and name or tostring(id)
end
local function update()
 for key, board in boards do
  local fallback = {}
  for _, player in Players:GetPlayers() do
   local data = Data.get(player)
   if data then
    local value = math.floor(data.Stats[key] or E.Zero)
    -- Connected players already supply their names; do not grow the lookup cache.
    table.insert(fallback, { userId = player.UserId, name = player.Name, value = value })
    if board.store and Data.isPersistent(player) then
     pcall(function() board.store:UpdateAsync(tostring(player.UserId), function(old) return math.max(old or E.Zero, value) end) end)
    end
   end
  end
  table.sort(fallback, function(a, b) if a.value == b.value then return a.userId < b.userId end return a.value > b.value end)
  while #fallback > E.LeaderboardSize do table.remove(fallback) end
  local ok, rows = pcall(function()
   if not board.store then error("OrderedDataStore unavailable") end
   return board.store:GetSortedAsync(false, E.LeaderboardSize):GetCurrentPage()
  end)
  if ok then
   fallback = {}
   for _, row in rows do
    local id = tonumber(row.key)
    if id then table.insert(fallback, { userId = id, name = nameFor(id), value = row.value }) end
   end
  end
  board.value.Value = Http:JSONEncode(fallback)
 end
end
task.spawn(function() while true do update() task.wait(E.LeaderboardInterval) end end)
return {}
