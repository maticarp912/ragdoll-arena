-- LocalScript: StarterPlayer/StarterPlayerScripts/ControlHints
-- 12/11/2026 (pedido del usuario): ayuda de botones abajo a los costados, como en la referencia.
-- Izquierda: esquivar, fijar y cambiar objetivo. Derecha: guardia, ataques, patada e infusión.
-- Solo con teclado/mouse o mando (en táctil ya están los botones en pantalla). Se oculta con menús abiertos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local InputMap = require(ReplicatedStorage:WaitForChild("InputMap"))
local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))

local P = Polish.ControlHints
local C = UiTheme.Colors
local player = Players.LocalPlayer

local SHORT = {
	MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3", Space = "Espacio",
	ButtonR1 = "RB", ButtonR2 = "RT", ButtonL1 = "LB", ButtonL2 = "LT", ButtonR3 = "R3", ButtonL3 = "L3",
	DPadUp = "↑", DPadDown = "↓", DPadLeft = "←", DPadRight = "→",
}
local LEFT = { { "Dodge", "hint.dodge" }, { "LockOn", "hint.lock" }, { "SwitchTarget", "hint.switch" } }
local RIGHT = { { "Block", "hint.block" }, { { "Attack", "Heavy" }, "hint.attack" }, { "Kick", "hint.kick" }, { "Infuse", "hint.infuse" } }

local gui = Instance.new("ScreenGui")
gui.Name = "ControlHints"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3
gui.Parent = player:WaitForChild("PlayerGui")

local function column(right)
	local f = Instance.new("Frame")
	f.Name = right and "Right" or "Left"
	f.BackgroundTransparency = 1
	f.AnchorPoint = Vector2.new(right and 1 or 0, 1)
	f.Position = UDim2.new(right and 1 or 0, right and -P.Margin or P.Margin, 1, -P.Bottom)
	f.Size = UDim2.fromOffset(P.Width, 200)
	f.Parent = gui
	local list = Instance.new("UIListLayout")
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
	list.Padding = UDim.new(0, P.Gap)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = f
	local sc = Instance.new("UIScale")
	sc.Parent = f
	return f, sc
end
local leftCol, leftScale = column(false)
local rightCol, rightScale = column(true)

local function chip(parent, text, order)
	local box = Instance.new("TextLabel")
	box.LayoutOrder = order
	box.AutomaticSize = Enum.AutomaticSize.X
	box.Size = UDim2.fromOffset(P.ChipHeight, P.ChipHeight)
	box.BackgroundColor3 = P.ChipColor
	box.BackgroundTransparency = 0.05
	box.TextColor3 = P.ChipText
	box.FontFace = UiTheme.Fonts.Bold
	box.TextSize = P.ChipTextSize
	box.Text = text
	box.Parent = parent
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 5)
	pad.Parent = box
	UiTheme.corner(box, 4)
	return box
end

local function row(parent, actions, key, order, right)
	local r = Instance.new("Frame")
	r.Name = key
	r.LayoutOrder = order
	r.BackgroundColor3 = C.BgAbyss
	r.BackgroundTransparency = P.RowTransparency
	r.BorderSizePixel = 0
	r.AutomaticSize = Enum.AutomaticSize.X
	r.Size = UDim2.fromOffset(0, P.RowHeight)
	r.Parent = parent
	local grad = Instance.new("UIGradient")
	grad.Transparency = NumberSequence.new(right and 1 or 0, right and 0 or 1)
	grad.Parent = r
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = r
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = r
	local device = Device.isGamepad() and "Gamepad" or "Keyboard"
	local defaults = InputMap.defaults()[device] or {}
	for i, a in type(actions) == "table" and actions or { actions } do
		local name = defaults[a]
		chip(r, SHORT[name] or InputMap.label(name), i)
	end
	local lbl = Instance.new("TextLabel")
	lbl.LayoutOrder = 10
	lbl.BackgroundTransparency = 1
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.Size = UDim2.fromOffset(0, P.RowHeight)
	lbl.Text = L.t(key)
	lbl.TextColor3 = C.TextPrimary
	lbl.FontFace = UiTheme.Fonts.Body
	lbl.TextSize = P.TextSize
	lbl.Parent = r
end

local function rebuild()
	for _, col in { leftCol, rightCol } do
		for _, ch in col:GetChildren() do
			if ch:IsA("Frame") then ch:Destroy() end
		end
	end
	for i, h in LEFT do row(leftCol, h[1], h[2], i, false) end
	for i, h in RIGHT do row(rightCol, h[1], h[2], i, true) end
end

local function refresh()
	local vp = gui.AbsoluteSize
	local sc = math.clamp(math.min(vp.X / 1600, vp.Y / 900), 0.6, 1)
	leftScale.Scale, rightScale.Scale = sc, sc
	gui.Enabled = not Device.isTouch() and player:GetAttribute("OptControlHints") ~= false
		and not player:GetAttribute("MenuOpen") and not player:GetAttribute("MainMenuOpen")
end

Device.Changed:Connect(function() rebuild() refresh() end)
L.Changed:Connect(rebuild)
for _, a in { "MenuOpen", "MainMenuOpen", "OptControlHints" } do
	player:GetAttributeChangedSignal(a):Connect(refresh)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
rebuild()
refresh()
