local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Chat = game:GetService("TextChatService")
local player = Players.LocalPlayer
local Roles = require(RS:WaitForChild("Roles"))
local UI = require(RS:WaitForChild("UiTheme"))
local L = require(RS:WaitForChild("Localization"))
local Remote = RS:WaitForChild("Remotes"):WaitForChild("Admin")
Chat.OnIncomingMessage = function(message)
 local source = message.TextSource
 local sender = source and Players:GetPlayerByUserId(source.UserId)
 local role = sender and sender:GetAttribute("Role")
 local spec = Roles.Data[role]
 if not spec or role == "Player" then return nil end
 local props = Instance.new("TextChatMessageProperties")
 props.PrefixText = '<font color="#' .. spec.color:ToHex() .. '">[' .. L.t("cx.role." .. role) .. ']</font> ' .. message.PrefixText
 return props
end
local gui = Instance.new("ScreenGui") gui.Name = "AdminPanel" gui.ResetOnSpawn = false gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame") panel.Size = UDim2.fromScale(0.86, 0.66) panel.Position = UDim2.fromScale(0.07, 0.17)
panel.BackgroundColor3 = UI.Colors.BgPanel panel.Visible = false panel.Parent = gui
local function text(class, key, y)
 local obj = Instance.new(class) obj.Size = UDim2.fromScale(0.9, 0.09) obj.Position = UDim2.fromScale(0.05, y)
 obj.BackgroundColor3 = UI.Colors.BgPanelLight obj.TextColor3 = UI.Colors.TextPrimary obj.TextSize = 16 obj.Text = L.t(key) obj.Parent = panel
 -- Integración 0.2: en los campos la ayuda va como PlaceholderText (antes era el texto y se mezclaba con lo escrito)
 if class == "TextBox" then obj.ClearTextOnFocus = false obj.PlaceholderText = obj.Text obj.Text = "" obj.PlaceholderColor3 = UI.Colors.TextMuted or UI.Colors.TextPrimary end
 return obj
end
local toggle = Instance.new("TextButton") toggle.Size = UDim2.fromOffset(110, 36) toggle.AnchorPoint = Vector2.new(1, 0) toggle.Position = UDim2.new(1, -12, 0, 52) -- 12/11/2026: arriba a la derecha, debajo del contador de FPS (antes tapaba el retrato)
toggle.Text = L.t("cx.admin.title") toggle.BackgroundColor3 = UI.Colors.BgPanel toggle.TextColor3 = UI.Colors.TextGold toggle.Parent = gui
local target = text("TextBox", "cx.admin.target", 0.03)
local action = text("TextButton", "cx.admin.action", 0.15)
local value = text("TextBox", "cx.admin.value", 0.27)
local apply = text("TextButton", "cx.admin.apply", 0.39)
local search = text("TextButton", "cx.admin.search", 0.51)
local output = text("TextLabel", "cx.admin.help", 0.64) output.Size = UDim2.fromScale(0.9, 0.31) output.TextWrapped = true
local actions = { "Coins", "Weapon", "Skin", "Aura", "Level", "BoxRelic", "BoxSouls", "Spins", "Streak", "Role", "Kick", "Mute", "Unmute" }
local index, busy = 1, false
local function refresh()
 local allowed = player:GetAttribute("ModerateAllowed") == true
 toggle.Visible = allowed if not allowed then panel.Visible = false end
 action.Text = L.t("cx.admin." .. actions[index])
end
toggle.Activated:Connect(function() panel.Visible = not panel.Visible end)
action.Activated:Connect(function() index = index % #actions + 1 refresh() end)
local function invoke(a, id, v)
 if busy then return end busy = true
 local success, ok, result = pcall(function() return Remote:InvokeServer(a, id, v) end)
 busy = false
 if not success or not ok then output.Text = L.t("cx.admin.denied") return end
 if a == "List" then
  local lines = {}
  local query = string.lower(target.Text)
  for _, row in result do
   if query == "" or string.find(string.lower(row.name), query, 1, true) or tostring(row.userId) == query then table.insert(lines, row.name .. " (" .. row.userId .. ") · " .. L.t("cx.role." .. row.role)) end
  end
  output.Text = table.concat(lines, "\n")
 else output.Text = L.format(result) end
end
search.Activated:Connect(function() invoke("List") end)
apply.Activated:Connect(function()
 local id = tonumber(target.Text)
 if not id then for _, p in Players:GetPlayers() do if string.lower(p.Name) == string.lower(target.Text) then id = p.UserId break end end end
 local a = actions[index]
 invoke(a, id, (a == "Coins" or a == "Level" or a == "BoxRelic" or a == "BoxSouls" or a == "Spins" or a == "Streak") and tonumber(value.Text) or value.Text)
end)
player:GetAttributeChangedSignal("ModerateAllowed"):Connect(refresh)
L.Changed:Connect(function() target.PlaceholderText = L.t("cx.admin.target") value.PlaceholderText = L.t("cx.admin.value") toggle.Text = L.t("cx.admin.title") apply.Text = L.t("cx.admin.apply") search.Text = L.t("cx.admin.search") refresh() end)
refresh()
