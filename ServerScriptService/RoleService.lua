local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Roles = require(RS:WaitForChild("Roles"))
local Data = require(script.Parent.PlayerData)
local Service = {}
local resolved, attempted = {}, {}
function Service.isOwner(player)
 return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end
function Service.refresh(player)
 local data = Data.get(player)
 local role = "Player"
 if Service.isOwner(player) then role = "Owner"
 else
  for _, id in Roles.Order do
   local spec = Roles.Data[id]
   if id ~= "Owner" and (table.find(spec.ids, player.UserId) or resolved[player.UserId] == id) then role = id break end
  end
  local granted = data and data.GrantedRole
  if Roles.Data[granted] and granted ~= "Owner" and Roles.Data[granted].priority > Roles.Data[role].priority then role = granted end
  if role == "Player" and data and data.PlaySeconds < Roles.NewHours * Roles.SecondsPerHour then role = "Nuevo" end
 end
 player:SetAttribute("Role", role)
 player:SetAttribute("AllCosmetics", role == "Owner")
 player:SetAttribute("AdminAllowed", Roles.Data[role].permissions.Admin == true)
 player:SetAttribute("ModerateAllowed", Roles.Data[role].permissions.Moderate == true)
 player:SetAttribute("DebugAllowed", Roles.Data[role].permissions.Debug == true)
 if data then Data.refresh(player) end
end
function Service.has(player, permission)
 local spec = Roles.Data[player:GetAttribute("Role")]
 return spec ~= nil and spec.permissions[permission] == true
end
local function resolveNames()
 for _, role in Roles.Order do
  for _, name in Roles.Data[role].names do
   if not attempted[name] or os.clock() - attempted[name] >= Roles.ResolveRetry then
    attempted[name] = os.clock()
    local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
    if ok and (not resolved[id] or Roles.Data[role].priority > Roles.Data[resolved[id]].priority) then resolved[id] = role end
   end
  end
 end
end
Players.PlayerAdded:Connect(function(player) Service.refresh(player) end)
task.spawn(function()
 while true do
  resolveNames()
  for _, player in Players:GetPlayers() do Service.refresh(player) end
  task.wait(Roles.RefreshSeconds)
 end
end)
return Service
