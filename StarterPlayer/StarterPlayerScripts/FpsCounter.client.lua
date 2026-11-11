-- LocalScript: StarterPlayerScripts/FpsCounter
-- 11/11/2026: contador de FPS arriba a la derecha, medio transparente. Se prende en Ajustes («Contador de FPS»,
-- atributo OptFps). Se actualiza dos veces por segundo con el promedio real (no el último frame) y cambia de
-- color: verde a partir de 55, amarillo entre 30 y 55, rojo por debajo.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local C = UiTheme.Colors

local FPS = { Update = 0.5, Good = 55, Ok = 30, Width = 92, Height = 28, Top = 8, Right = 8 }

local gui = Instance.new("ScreenGui")
gui.Name = "FpsCounter"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -FPS.Right, 0, FPS.Top)
label.Size = UDim2.fromOffset(FPS.Width, FPS.Height)
label.BackgroundColor3 = C.BgAbyss
label.BackgroundTransparency = 0.55
label.TextTransparency = 0.15
label.TextSize = 16
label.Text = "-- FPS"
label.TextColor3 = C.TextPrimary
label.Parent = gui
UiTheme.applyFont(label, "Number")
UiTheme.corner(label, UiTheme.Radius.SM)

local frames, elapsed = 0, 0
local conn

local function stop()
	if conn then conn:Disconnect() conn = nil end
end

local function start()
	if conn then return end
	frames, elapsed = 0, 0
	conn = RunService.RenderStepped:Connect(function(dt)
		frames += 1
		elapsed += dt
		if elapsed < FPS.Update then return end
		local fps = math.floor(frames / elapsed + 0.5)
		frames, elapsed = 0, 0
		label.Text = fps .. " FPS"
		label.TextColor3 = fps >= FPS.Good and C.Success or (fps >= FPS.Ok and C.Warning or C.Danger)
	end)
end

local function refresh()
	local on = player:GetAttribute("OptFps") == 1
	gui.Enabled = on
	if on then start() else stop() end
end

player:GetAttributeChangedSignal("OptFps"):Connect(refresh)
refresh()
