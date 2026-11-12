-- LocalScript: StarterPlayer/StarterPlayerScripts/GuidedTutorial
-- 12/11/2026 (Claude, pedido del usuario): tutorial guiado de la primera entrada, en el patio de entrenamiento.
-- Muestra lo básico sin frustrar: un paso por vez, con las teclas del dispositivo que se está usando.
--   1 moverse · 2 fijar · 3 cambiar de fijado · 4 ataque ligero · 5 ataque fuerte · 6 direcciones
--   7 combo · 8 derribar · 9 bloquear al bot · 10 parry · 11 listo (vuelve a la ciudad)
-- El servidor (TutorialService) pone al jugador en el patio (atributo InTutorial), maneja el bot y lo
-- devuelve a la ciudad con "Done" o "Skip". Este script solo mira lo que pasa y avanza los pasos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local InputMap = require(ReplicatedStorage:WaitForChild("InputMap"))
local CityConfig = require(ReplicatedStorage:WaitForChild("CityConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GuidedRemote = Remotes:WaitForChild("GuidedTutorial")
local Effect = Remotes:WaitForChild("Effect")

local G = CityConfig.GuidedTutorial
local C = UiTheme.Colors
local player = Players.LocalPlayer

local function key(action)
	local device = Device.isGamepad() and "Gamepad" or "Keyboard"
	local defaults = InputMap.defaults()[device] or {}
	return InputMap.label(defaults[action])
end
local function dirHint()
	if Device.isTouch() then return L.t("gt.dirTouch") end
	return Device.isGamepad() and L.t("gt.dirPad") or L.t("gt.dirMouse")
end

-- Cada paso: título y texto (con teclas) y cuántas veces hay que hacerlo
local STEPS = {
	{ id = "move" }, { id = "lock" }, { id = "switch" }, { id = "light", need = G.LightHits }, { id = "heavy" },
	{ id = "dirs", need = 3 }, { id = "combo" }, { id = "down" }, { id = "block", need = G.BlocksNeeded },
	{ id = "parry" }, { id = "done" },
}
local function stepText(id)
	return L.t("gt." .. id .. ".body", {
		move = Device.isTouch() and L.t("gt.stick") or (Device.isGamepad() and L.t("gt.leftStick") or "W A S D"),
		lock = key("LockOn"), switch = key("SwitchTarget"), attack = key("Attack"), heavy = key("Heavy"),
		kick = key("Kick"), block = key("Block"), dirs = dirHint(),
	})
end

----------------------------------------------------------------------
-- Panel (a la derecha, sin tapar el centro)
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "GuidedTutorial"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = UiTheme.panel({ name = "Steps", parent = gui, anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -18, 0.42, 0),
	size = UDim2.fromOffset(330, 176), bg = C.BgPanel, transparency = 0.08, ornaments = true, ornamentSize = 10 })
local scale = Instance.new("UIScale")
scale.Parent = panel
local header = UiTheme.label({ parent = panel, position = UDim2.fromOffset(18, 12), size = UDim2.new(1, -36, 0, 18),
	text = L.t("gt.header"), font = "Bold", textSize = UiTheme.TextSizes.XS, color = C.GoldDim })
local counter = UiTheme.label({ parent = panel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -18, 0, 12),
	size = UDim2.fromOffset(80, 18), text = "", font = "Number", textSize = UiTheme.TextSizes.XS, color = C.GoldDim,
	alignX = Enum.TextXAlignment.Right })
local title = UiTheme.label({ parent = panel, position = UDim2.fromOffset(18, 32), size = UDim2.new(1, -36, 0, 28),
	text = "", font = "Title", textSize = UiTheme.TextSizes.LG, color = C.GoldBright })
local body = UiTheme.label({ parent = panel, position = UDim2.fromOffset(18, 62), size = UDim2.new(1, -36, 0, 64),
	text = "", font = "Body", textSize = UiTheme.TextSizes.SM, color = C.TextPrimary, wrap = true,
	alignY = Enum.TextYAlignment.Top })
body.TextWrapped = true
local progress = UiTheme.label({ parent = panel, position = UDim2.fromOffset(18, 128), size = UDim2.new(0.5, -18, 0, 18),
	text = "", font = "Number", textSize = UiTheme.TextSizes.XS, color = C.Success })
local skip = UiTheme.button({ name = "Skip", parent = panel, anchor = Vector2.new(1, 1), position = UDim2.new(1, -14, 1, -12),
	size = UDim2.fromOffset(130, 30), text = L.t("gt.skip"), textSize = UiTheme.TextSizes.XS, variant = "secondary",
	onClick = function() GuidedRemote:FireServer("Skip") end })

----------------------------------------------------------------------
-- Estado
----------------------------------------------------------------------
local index, count = 1, 0
local seenDirs = {}
local comboTimes = {}
local lastDir = ""
local lastLock

local function render()
	local step = STEPS[index]
	title.Text = L.t("gt." .. step.id .. ".title")
	body.Text = stepText(step.id)
	counter.Text = L.t("gt.counter", { step = index, total = #STEPS })
	progress.Text = step.need and step.need > 1 and ("%d / %d"):format(count, step.need) or ""
	skip.Visible = step.id ~= "done"
end

local function advance()
	index = math.min(#STEPS, index + 1)
	count = 0
	table.clear(seenDirs)
	table.clear(comboTimes)
	GuidedRemote:FireServer("Step", index)
	UiTheme.playSound("UI_Equip")
	panel.Position = UDim2.new(1, 6, 0.42, 0)
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(1, -18, 0.42, 0) }):Play()
	render()
	if STEPS[index].id == "done" then
		task.delay(3, function()
			if player:GetAttribute("InTutorial") then GuidedRemote:FireServer("Done") end
		end)
	end
end

local function bump(id, amount)
	local step = STEPS[index]
	if not gui.Enabled or step.id ~= id then return end
	count += amount or 1
	if count >= (step.need or 1) then advance() else render() end
end

-- Golpes, bloqueos y parry llegan por el mismo evento que usan el HUD y los efectos
Effect.OnClientEvent:Connect(function(kind, role, info)
	if kind ~= "Feel" or not gui.Enabled then return end
	local id = STEPS[index].id
	if role == "Deal" then
		local hitKind = type(info) == "table" and info.kind or "Light"
		if id == "light" and hitKind == "Light" then bump("light")
		elseif id == "heavy" and hitKind == "Heavy" then bump("heavy")
		elseif id == "dirs" and (lastDir == "Up" or lastDir == "Left" or lastDir == "Right") and not seenDirs[lastDir] then
			seenDirs[lastDir] = true
			bump("dirs")
		elseif id == "combo" then
			local now = os.clock()
			table.insert(comboTimes, now)
			while comboTimes[1] and now - comboTimes[1] > G.ComboWindow do table.remove(comboTimes, 1) end
			if #comboTimes >= 3 then bump("combo") end
		end
	elseif role == "Block" then
		bump("block")
	elseif role == "Parry" then
		bump("parry")
	end
end)

local function watchCharacter(char)
	char:GetAttributeChangedSignal("AttackDir"):Connect(function()
		local d = char:GetAttribute("AttackDir")
		if type(d) == "string" and d ~= "" then lastDir = d end
	end)
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character) end

-- Pasos que se miran cuadro a cuadro: llegar al círculo, fijar, cambiar de objetivo, derribar
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then return end
	acc += dt
	if acc < 0.15 then return end
	acc = 0
	local id = STEPS[index].id
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local lock = player:FindFirstChild("LockTarget")
	local target = lock and lock.Value
	if id == "move" then
		local marker = workspace:FindFirstChild("TrainingYard") and workspace.TrainingYard:FindFirstChild("TutorialMarker")
		if root and marker and ((root.Position - marker.Position) * Vector3.new(1, 0, 1)).Magnitude <= G.MarkerReach then advance() end
	elseif id == "lock" then
		if target then lastLock = target advance() end
	elseif id == "switch" then
		if target and lastLock and target ~= lastLock then advance()
		elseif target then lastLock = lastLock or target end
	elseif id == "down" then
		local folder = workspace:FindFirstChild("Dummies")
		for _, d in folder and folder:GetChildren() or {} do
			if d:GetAttribute("KnockedDown") then advance() break end
		end
	end
end)

----------------------------------------------------------------------
-- Se muestra solo en el patio y después del menú inicial
----------------------------------------------------------------------
local wasInYard = false
local function refresh()
	local on = player:GetAttribute("InTutorial") == true and player:GetAttribute("MainMenuOpen") ~= true
		and player:GetAttribute("MenuOpen") ~= true
	-- arranca de cero solo al entrar al patio (abrir un menú no reinicia el progreso)
	local inYard = player:GetAttribute("InTutorial") == true
	if inYard and not wasInYard then
		index, count = 1, 0
	end
	wasInYard = inYard
	if on then render() end
	gui.Enabled = on
	scale.Scale = Device.isTouch() and 0.8 or 1
end
player:GetAttributeChangedSignal("InTutorial"):Connect(refresh)
player:GetAttributeChangedSignal("MainMenuOpen"):Connect(refresh)
player:GetAttributeChangedSignal("MenuOpen"):Connect(refresh)
L.Changed:Connect(function() if gui.Enabled then render() end end)
header.Text = L.t("gt.header")
refresh()
