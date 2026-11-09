-- Revisión de TODOS los clips disponibles, con el arma equipada. Solo depuración.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local clips = require(RS:WaitForChild("AnimClips"))
local weapons = require(RS:WaitForChild("WeaponData"))
local gui = Instance.new("ScreenGui")
gui.Name = "PoseReview"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(340, 170)
panel.Position = UDim2.new(1, -352, 0, 80)
panel.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
panel.Parent = gui
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -16, 0, 70)
label.Position = UDim2.fromOffset(8, 4)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(232, 226, 208)
label.TextSize = 15
label.TextWrapped = true
label.Parent = panel
local keys, index, phase = {}, 1, 0.5
local ownedFreeze = nil

local function release()
	if workspace:GetAttribute("PoseFreeze") == ownedFreeze then workspace:SetAttribute("PoseFreeze", "") end
	ownedFreeze = nil
end
local function refresh()
	release()
	keys = {}
	local char = player.Character
	local weapon = char and char:GetAttribute("WeaponId") or "Sword"
	local def = weapons.get(weapon)
	local arch = def.archetype or "OneHand"
	for name in clips.Archetypes[arch] or clips.Archetypes.OneHand do table.insert(keys, "Weapons." .. weapon .. "." .. name) end
	for name in clips.Defense do table.insert(keys, "Weapons." .. weapon .. "." .. name) end
	for name in clips.Generic do table.insert(keys, "Generic." .. name) end
	table.sort(keys)
	index = math.clamp(index, 1, #keys)
	label.Text = "REVISIÓN DE POSES · F8\n" .. keys[index] .. "\n" .. math.floor(phase * 100) .. "% · Cambiá el arma desde B"
end
local function freeze()
	if not player:GetAttribute("DebugAllowed") then return end
	refresh()
	ownedFreeze = keys[index] .. "@" .. string.format("%.2f", phase)
	workspace:SetAttribute("PoseFreeze", ownedFreeze)
end
local function button(text, x, y, width, callback)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Size = UDim2.fromOffset(width, 30)
	b.Position = UDim2.fromOffset(x, y)
	b.BackgroundColor3 = Color3.fromRGB(48, 46, 44)
	b.TextColor3 = Color3.fromRGB(232, 226, 208)
	b.Parent = panel
	b.Activated:Connect(callback)
end
button("Anterior", 8, 76, 100, function() index = (index - 2) % #keys + 1 freeze() end)
button("Siguiente", 116, 76, 100, function() index = index % #keys + 1 freeze() end)
button("Soltar pose", 224, 76, 108, release)
for i, value in { 0, 0.25, 0.5, 0.75, 1 } do
	button(tostring(value * 100) .. "%", 8 + (i - 1) * 65, 116, 60, function() phase = value freeze() end)
end
UIS.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.F8 or not player:GetAttribute("DebugAllowed") then return end
	gui.Enabled = not gui.Enabled
	if gui.Enabled then refresh() else release() end
end)
local weaponConnection
local function hook(char)
	release()
	if weaponConnection then weaponConnection:Disconnect() end
	weaponConnection = char:GetAttributeChangedSignal("WeaponId"):Connect(function() if gui.Enabled then refresh() end end)
end
player.CharacterAdded:Connect(hook)
if player.Character then hook(player.Character) end
player:GetAttributeChangedSignal("DebugAllowed"):Connect(function()
	if not player:GetAttribute("DebugAllowed") then gui.Enabled = false release() end
end)
