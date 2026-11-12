-- LocalScript: StarterPlayer/StarterPlayerScripts/Tutorial
-- Responsable: Claude (0.2, ronda 2). Tutorial de 3 pasos en el patio de práctica, para jugadores nuevos.
--   1. Pegarle 3 veces a un muñeco (evento Effect "Feel", rol Deal, contrato C23).
--   2. Ponerse en guardia (atributo Blocking).
--   3. Patearlo (rol Deal con kind = "Kick").
-- Son los mismos pasos que certifica TutorialService (servidor), que es el que paga con RewardService.
-- Se muestra solo fuera de partida, cerca de los muñecos, a quien todavía no jugó partidas (StatMatches) o tiene el
-- rol «Nuevo». Las teclas salen de InputMap (y se actualizan si el jugador las reasigna). Valores en PolishConfig.Tutorial.
-- Este script no guarda ni certifica nada: solo muestra el progreso.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local InputMap = require(ReplicatedStorage:WaitForChild("InputMap"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local TUT = require(ReplicatedStorage:WaitForChild("PolishConfig")).Tutorial
local Effect = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Effect")

local player = Players.LocalPlayer
local C = Theme.Colors
if not TUT then return end

local binds = InputMap.merge(nil)
task.spawn(function()
	local ev = player:WaitForChild("BindsChanged", 10)
	if ev then ev.Event:Connect(function(b) binds = b end) end
end)

local function key(action)
	local UIS = game:GetService("UserInputService")
	local pad = string.sub(UIS:GetLastInputType().Name, 1, 7) == "Gamepad"
	local device = pad and "Gamepad" or "Keyboard"
	return InputMap.label(binds[device] and binds[device][action])
end

----------------------------------------------------------------------
-- Estado
----------------------------------------------------------------------
local hits, blocked, kicked = 0, false, false
local finishedAt = nil

Effect.OnClientEvent:Connect(function(kind, role, info)
	if kind ~= "Feel" or finishedAt or role ~= "Deal" then return end
	if type(info) == "table" and info.kind == "Kick" then
		kicked = true
	else
		hits = math.min(3, hits + 1)
	end
end)

----------------------------------------------------------------------
-- Interfaz
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Tutorial"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.fromScale(0.5, TUT.Top)
panel.Size = UDim2.fromOffset(TUT.Width, TUT.RowHeight * 5 + 16)
panel.BackgroundTransparency = 0.2
panel.Parent = gui
Theme.panel(panel)

local function label(y, size, color)
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromOffset(12, y)
	l.Size = UDim2.new(1, -24, 0, TUT.RowHeight)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Theme.Fonts.Body
	l.TextSize = size
	l.TextColor3 = color
	l.TextStrokeTransparency = 1
	l.Parent = panel
	return l
end
local title = label(6, 18, C.Gold)
title.Font = Theme.Fonts.Title
local rows = { label(6 + TUT.RowHeight, 15, C.Bone), label(6 + TUT.RowHeight * 2, 15, C.Bone), label(6 + TUT.RowHeight * 3, 15, C.Bone) }
local hint = label(6 + TUT.RowHeight * 4, 13, C.BoneDim)

local function row(l, done, text)
	l.Text = (done and "✓  " or "•  ") .. text
	l.TextColor3 = done and TUT.Check or C.Bone
end

----------------------------------------------------------------------
-- Cuándo se muestra
----------------------------------------------------------------------
local function eligible()
	if player:GetAttribute("InMatch") or player:GetAttribute("MenuOpen") then return false end
	local matches = player:GetAttribute("StatMatches")
	local isNew = player:GetAttribute("Role") == "Nuevo" or (type(matches) == "number" and matches <= TUT.MaxMatches)
	if not isNew then return false end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local dummies = workspace:FindFirstChild("Dummies")
	if not root or not dummies then return false end
	for _, d in dummies:GetChildren() do
		local r = d:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - root.Position).Magnitude <= TUT.DummyRange then return true end
	end
	return false
end

local acc = 0
RunService.RenderStepped:Connect(function(dt)
	acc += dt
	if acc < 0.2 then return end
	acc = 0
	if finishedAt and os.clock() - finishedAt > TUT.DoneHold then
		gui.Enabled = false
		return
	end
	local show = finishedAt ~= nil or eligible()
	gui.Enabled = show
	if not show then return end

	if player.Character and player.Character:GetAttribute("Blocking") then blocked = true end

	title.Text = L.t("tutorial.title")
	row(rows[1], hits >= 3, L.t("tutorial.hit", { key = key("Attack"), n = hits }))
	row(rows[2], blocked, L.t("tutorial.block", { key = key("Block") }))
	row(rows[3], kicked, L.t("tutorial.kick", { key = key("Kick") }))
	if hits >= 3 and blocked and kicked then
		finishedAt = finishedAt or os.clock()
		hint.Text = L.t("tutorial.done")
		hint.TextColor3 = TUT.Check
	else
		hint.Text = L.t("tutorial.dummyHint")
	end
end)
