local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Chat = game:GetService("TextChatService")
local Roles = require(RS:WaitForChild("Roles"))
local Weapons = require(RS:WaitForChild("WeaponData"))
local Skins = require(RS:WaitForChild("Skins"))
local Auras = require(RS:WaitForChild("Auras"))
local RoleService = require(script.Parent.RoleService)
local Data = require(script.Parent.PlayerData)
local Progression = require(script.Parent.ProgressionService)
local Rewards = require(script.Parent.RewardService)
local RF = require(script.Parent.Remotes).get("Admin", "RemoteFunction")
local last, budgets = {}, {}
local audit = {}
local Service = {}
local function log(actor, target, action, value, ok)
 local row = { at = os.time(), actor = actor.UserId, target = target and target.UserId or 0, action = action, value = value, ok = ok }
 table.insert(audit, row)
 while #audit > Roles.Admin.AuditLimit do table.remove(audit, 1) end
 print("[AdminAudit] " .. Http:JSONEncode(row))
end
local function response(ok) return ok, { key = ok and "cx.admin.done" or "cx.admin.denied" } end
RF.OnServerInvoke = function(player, action, targetId, value)
 local now = os.clock()
 if last[player] and now - last[player] < Roles.Admin.Interval then return response(false) end
 last[player] = now
 if type(action) ~= "string" or #action > Roles.ActionLength or not RoleService.has(player, "Moderate") then return response(false) end
 if action == "List" then
  local rows = {}
  for _, p in Players:GetPlayers() do table.insert(rows, { userId = p.UserId, name = p.Name, role = p:GetAttribute("Role") }) end
  return true, rows
 end
 if type(targetId) ~= "number" or targetId ~= targetId or targetId % 1 ~= 0 then return response(false) end
 local target = Players:GetPlayerByUserId(targetId)
 local role = player:GetAttribute("Role")
 local targetRole = target and target:GetAttribute("Role")
 if not target or not Roles.Data[targetRole] or not Data.get(player) or not Data.get(target) then return response(false) end
 if not Data.canMutate(target) then return response(false) end
 local owner = RoleService.isOwner(player)
 if not owner and (target == player or Roles.Data[targetRole].priority >= Roles.Data[role].priority) then
  log(player, target, action, nil, false) return response(false)
 end
 if action ~= "Kick" and action ~= "Mute" and action ~= "Unmute" and not RoleService.has(player, "Admin") then return response(false) end
 local b = budgets[player]
 if not b or now - b.at >= Roles.Admin.Window then b = { at = now, actions = 0, coins = 0 } budgets[player] = b end
 if b.actions >= Roles.Admin.HourActions then return response(false) end
 local d = Data.get(target)
 local ok = false
 if action == "Coins" then
  if type(value) ~= "number" or value ~= value or value % 1 ~= 0 or value < 1 or value > Roles.Admin.MaxCoins or b.coins + value > Roles.Admin.HourCoins then return response(false) end
  b.coins += value Data.addCoins(target, value) ok = true
 elseif action == "Box" or action == "BoxRelic" or action == "BoxSouls" or action == "Spins" or action == "Streak" then
  ok = Rewards.admin(target, action, value)
 elseif action == "Level" then
  ok = Progression.setLevel(target, value)
 elseif action == "Weapon" or action == "Skin" or action == "Aura" then
  if type(value) ~= "string" or #value > Roles.IdLength then return response(false) end
  local catalog = action == "Weapon" and Weapons.Data or (action == "Skin" and Skins.Data or Auras.Data)
  if catalog[value] and not catalog[value].comingSoon then
   local field = action == "Weapon" and "OwnedWeapons" or (action == "Skin" and "OwnedSkins" or "OwnedAuras")
   d[field][value] = true Data.refresh(target) ok = true
  end
 elseif action == "Role" then
  local spec = type(value) == "string" and Roles.Data[value]
  if spec and value ~= "Owner" and (owner or spec.priority < Roles.Data[role].priority) then
   d.GrantedRole = value RoleService.refresh(target) ok = true
  end
 elseif action == "Mute" then
  target:SetAttribute("MutedUntil", os.time() + Roles.Admin.MuteSeconds) ok = true
 elseif action == "Unmute" then target:SetAttribute("MutedUntil", 0) ok = true
 elseif action == "Kick" then ok = true end
 if type(value) ~= "number" and type(value) ~= "string" then value = nil end
 if type(value) == "string" and #value > Roles.IdLength then value = nil end
 log(player, target, action, value, ok)
 if ok then
  b.actions += 1 Data.saveSoon(target)
  if action == "Kick" then target:Kick(require(RS.LocaleCodex).EN["cx.admin.kicked"]) end
 end
 return response(ok)
end
-- Change sending permission without replacing Roblox's channel delivery policies.
local originalSend = setmetatable({}, { __mode = "k" })
local function applySource(source)
 if not source:IsA("TextSource") then return end
 local player = Players:GetPlayerByUserId(source.UserId)
 local muted = player and (player:GetAttribute("MutedUntil") or 0) > os.time()
 if muted then
  if originalSend[source] == nil then originalSend[source] = source.CanSend end
  source.CanSend = false
 elseif originalSend[source] ~= nil then
  source.CanSend = originalSend[source] originalSend[source] = nil
 end
end
Chat.DescendantAdded:Connect(applySource)
local function watch(player)
 player:GetAttributeChangedSignal("MutedUntil"):Connect(function()
  for _, source in Chat:GetDescendants() do applySource(source) end
  local untilAt = player:GetAttribute("MutedUntil") or 0
  if untilAt > os.time() then
   task.delay(untilAt - os.time(), function()
    if player.Parent and player:GetAttribute("MutedUntil") == untilAt then player:SetAttribute("MutedUntil", 0) end
   end)
  end
 end)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do watch(player) end
Players.PlayerRemoving:Connect(function(player) last[player] = nil budgets[player] = nil end)
function Service.audit() return table.clone(audit) end
return Service
