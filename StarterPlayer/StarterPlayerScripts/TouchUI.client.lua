-- LocalScript: StarterPlayer/StarterPlayerScripts/TouchUI
-- Controles táctiles para dispositivos móviles (Fase 4, Contrato C12, responsable: Gemini, etapa 8).
-- Envía las acciones a InputBridge.press(actionId, isDown).
-- Solo visible con UserInputService.TouchEnabled. Respeta el joystick de movimiento a la izquierda
-- colocando el abanico de combate en la zona del pulgar derecho con áreas táctiles >= 48 px.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local InputBridge = require(ReplicatedStorage:WaitForChild("InputBridge"))

local player = Players.LocalPlayer
local C = UiTheme.Colors

local gui = Instance.new("ScreenGui")
gui.Name = "TouchControlsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local rightPad = Instance.new("Frame")
rightPad.Name = "RightThumbCluster"
rightPad.AnchorPoint = Vector2.new(1, 1)
rightPad.Position = UDim2.new(1, -16, 1, -16)
rightPad.Size = UDim2.fromOffset(310, 290)
rightPad.BackgroundTransparency = 1
rightPad.Parent = gui
local padScale = Instance.new("UIScale")
padScale.Parent = rightPad

-- Especificación ergonómica en arco alrededor del botón principal de Ataque (abajo a la derecha)
local BUTTON_SPECS = {
	-- Botón central grande de ataque básico
	{ id = "Attack",       labelKey = "ui.touch.attack",   icon = "attack",        x = 216, y = 194, size = 84, color = C.GoldBright, hold = false },
	-- Arco interior (Fuerte, Guardia mantener, Esquiva)
	{ id = "Heavy",        labelKey = "ui.touch.heavy",    icon = "heavy",         x = 124, y = 214, size = 66, color = C.Danger,     hold = true },
	{ id = "Block",        labelKey = "ui.touch.block",    icon = "block",         x = 136, y = 132, size = 66, color = C.Guard,      hold = true },
	{ id = "Dodge",        labelKey = "ui.touch.dodge",    icon = "dodge",         x = 222, y = 108, size = 64, color = C.Stamina,    hold = false },
	-- Arco exterior (Patada, Agarrar/Lanzar, Infusión)
	{ id = "Kick",         labelKey = "ui.touch.kick",     icon = "kick",          x = 46,  y = 222, size = 58, color = C.Warning,    hold = false },
	{ id = "Interact",     labelKey = "ui.touch.interact", icon = "interact",      x = 58,  y = 148, size = 58, color = C.Gold,       hold = false },
	{ id = "Infuse",       labelKey = "ui.touch.infuse",   icon = "Fire",          x = 148, y = 52,  size = 60, color = C.InfusionCharge, hold = false },
	-- Fila superior de puntería y menú
	{ id = "LockOn",       labelKey = "ui.touch.lock",     icon = "lockon",        x = 232, y = 34,  size = 52, color = C.GoldBright, hold = false },
	{ id = "SwitchTarget", labelKey = "ui.touch.switch",   icon = "switch_target", x = 74,  y = 74,  size = 50, color = C.TextPrimary, hold = false },
	{ id = "Menu",         labelKey = "ui.touch.menu",     icon = "armory",        x = 8,   y = 8,   size = 48, color = C.Gold,       hold = false },
}

local touchButtons = {}

for _, spec in BUTTON_SPECS do
	local btn = Instance.new("TextButton")
	btn.Name = "Touch_" .. spec.id
	btn.Position = UDim2.fromOffset(spec.x, spec.y)
	btn.Size = UDim2.fromOffset(spec.size, spec.size)
	btn.BackgroundColor3 = C.BgPanel
	btn.BackgroundTransparency = 0.22
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BorderSizePixel = 0
	btn.Parent = rightPad

	UiTheme.corner(btn, math.floor(spec.size / 2))
	local stroke = UiTheme.stroke(btn, spec.color, spec.id == "Attack" and 2.6 or 1.8, 0.12)

	local iconSize = math.floor(spec.size * 0.44)
	local ic = UiAssets.icon(btn, spec.icon, iconSize, spec.color)
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.new(0.5, 0, 0.38, 0)

	local lbl = UiTheme.label({
		name = "Caption",
		parent = btn,
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -5),
		size = UDim2.new(0.92, 0, 0, 14),
		text = L.t(spec.labelKey),
		font = "Bold",
		textSize = 10,
		maxTextSize = 11,
		minTextSize = 8,
		scaled = true,
		color = C.TextPrimary,
		alignX = Enum.TextXAlignment.Center,
	})

	local activeTouch = nil
	local isDown = false
	local function setPressed(down)
		if down == isDown then return end
		isDown = down
		if down then
			TweenService:Create(btn, UiTheme.Anim.TweenFast, {
				BackgroundColor3 = C.BgCardSelected,
				BackgroundTransparency = 0.05,
			}):Play()
			stroke.Thickness = 3
			InputBridge.press(spec.id, true)
		else
			TweenService:Create(btn, UiTheme.Anim.TweenFast, {
				BackgroundColor3 = C.BgPanel,
				BackgroundTransparency = 0.22,
			}):Play()
			stroke.Thickness = spec.id == "Attack" and 2.6 or 1.8
			InputBridge.press(spec.id, false)
		end
	end

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			activeTouch = input
			setPressed(true)
		end
	end)

	btn.InputEnded:Connect(function(input)
		if input == activeTouch or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			activeTouch = nil
			setPressed(false)
		end
	end)

	touchButtons[spec.id] = { button = btn, label = lbl, labelKey = spec.labelKey,
		release = function() activeTouch = nil setPressed(false) end }
end

-- Claude 9/11: en celular con mando los botones táctiles se ocultan (el beta tester juega así).
-- Vuelven al tocar la pantalla. Al ocultarse se sueltan los botones mantenidos (Bloquear, Fuerte).
local usingGamepad = UserInputService.GamepadEnabled
local function isGamepadInput(t)
	return t.Name:sub(1, 7) == "Gamepad"
end
UserInputService.LastInputTypeChanged:Connect(function(t)
	if isGamepadInput(t) then usingGamepad = true
	elseif t == Enum.UserInputType.Touch then usingGamepad = false end
end)
UserInputService.GamepadDisconnected:Connect(function()
	if #UserInputService:GetConnectedGamepads() == 0 then usingGamepad = false end
end)

local function updateVisibilityAndScale()
	local isTouch = UserInputService.TouchEnabled
	local menuOpen = player:GetAttribute("MenuOpen") == true
	local show = isTouch and not menuOpen and not usingGamepad
	if rightPad.Visible and not show then
		for _, entry in touchButtons do entry.release() end
	end
	rightPad.Visible = show

	local cam = workspace.CurrentCamera
	if cam then
		local opt = player:GetAttribute("OptUiScale") or 1
		local base = math.clamp(math.min(cam.ViewportSize.X / 880, cam.ViewportSize.Y / 520), 0.72, 1.15)
		padScale.Scale = base * opt
	end
end

UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(updateVisibilityAndScale)
player:GetAttributeChangedSignal("MenuOpen"):Connect(updateVisibilityAndScale)
player:GetAttributeChangedSignal("OptUiScale"):Connect(updateVisibilityAndScale)
RunService.Heartbeat:Connect(updateVisibilityAndScale)
updateVisibilityAndScale()

L.Changed:Connect(function()
	for _, entry in touchButtons do
		entry.label.Text = L.t(entry.labelKey)
	end
end)
