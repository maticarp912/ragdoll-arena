-- LocalScript: StarterPlayer/StarterPlayerScripts/TouchUI
-- Controles táctiles para dispositivos móviles (Versión 0.2 — Contrato C12, D17, responsable: Gemini).
-- Mejoras 0.2 Ronda 2:
--   • Botones más grandes, mejor espaciados, con etiquetas de alto contraste y zonas seguras.
--   • El botón de Patada ("Kick") mantiene estado (hold = true) y garantiza enviar InputBridge.press("Kick", false)
--     al soltar el dedo (incluso si el dedo se desliza fuera del botón), activando KickRelease en el servidor.
--   • Editor interactivo de botones táctiles (D17): permite arrastrar cada botón a una posición personalizada,
--     ajustar su escala individual (75%..140%) y restablecer el diseño por defecto.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local InputBridge = require(ReplicatedStorage:WaitForChild("InputBridge"))

local player = Players.LocalPlayer
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local C = UiTheme.Colors
local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))
local Mobile = Polish.MobileHUD
local Directional = require(ReplicatedStorage:WaitForChild("CombatConfig")).Directional

local gui = Instance.new("ScreenGui")
gui.Name = "TouchControlsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local PAD_W, PAD_H = 290, 274
local rightPad = Instance.new("Frame")
rightPad.Name = "RightThumbCluster"
rightPad.AnchorPoint = Vector2.new(1, 1)
rightPad.Position = UDim2.new(1, -20, 1, -18)
rightPad.Size = UDim2.fromOffset(PAD_W, PAD_H)
rightPad.BackgroundTransparency = 1
rightPad.Parent = gui
local padScale = Instance.new("UIScale")
padScale.Parent = rightPad

-- Especificación ergonómica en arco amplio con botones más grandes y mejor separados (D17)
local BUTTON_SPECS = {
	{ id = "Attack", labelKey = "ui.touch.attack", icon = "attack", x = 199, y = 191, size = 82, color = C.GoldBright },
	{ id = "Heavy", labelKey = "ui.touch.heavy", icon = "heavy", x = 125, y = 201, size = 62, color = C.Danger, hold = true },
	{ id = "Block", labelKey = "ui.touch.block", icon = "block", x = 199, y = 115, size = 66, color = C.Guard, hold = true },
	{ id = "Dodge", labelKey = "ui.touch.dodge", icon = "dodge", x = 122, y = 122, size = 62, color = C.Stamina },
	{ id = "Kick", labelKey = "ui.touch.kick", icon = "kick", x = 52, y = 205, size = 57, color = C.Warning, hold = true },
	{ id = "Interact", labelKey = "ui.touch.interact", icon = "interact", x = 52, y = 130, size = 57, color = C.Gold },
	{ id = "Infuse", labelKey = "ui.touch.infuse", icon = "Fire", x = 52, y = 55, size = 57, color = C.InfusionCharge },
	{ id = "LockOn", labelKey = "ui.touch.lock", icon = "lockon", x = 52, y = 0, size = 49, color = C.GoldBright },
	{ id = "SwitchTarget", labelKey = "ui.touch.switch", icon = "switch_target", x = 0, y = 0, size = 49, color = C.TextPrimary },
	{ id = "Menu", labelKey = "ui.touch.menu", icon = "armory", x = 0, y = 56, size = 48, color = C.Gold },
}

local touchButtons = {}
local customLayout = {} -- { [id] = { x = number, y = number, scale = number } }
local editMode = false
local selectedEditId = "Attack"
local draggingBtnId = nil
local dragStartInput = nil
local dragStartMouse = Vector2.zero
local dragStartPos = Vector2.zero

local function loadSavedLayout()
	customLayout = {}
	local raw = player:GetAttribute("TouchLayoutJson")
	if type(raw) == "string" and raw ~= "" then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(decoded) == "table" then
			for id, spec in decoded do
				if type(spec) == "table" and type(spec.x) == "number" and type(spec.y) == "number" then
					customLayout[id] = { x = math.min(spec.x, PAD_W - 48), y = math.min(spec.y, PAD_H - 48), scale = spec.scale }
				end
			end
		end
	end
end

-- Integración 0.2 (ronda 2): el diseño se guarda en el perfil por Settings → SetTouchLayout (Codex, C10/D17).
-- Se espera 1,5 s sin cambios antes de mandarlo, para no saturar el remoto mientras se arrastra.
local SettingsRF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Settings", 10)
local saveToken = 0
local savingLocal = false

local function saveLayout()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, customLayout)
	if not ok then return end
	savingLocal = true
	player:SetAttribute("TouchLayoutJson", encoded)
	savingLocal = false
	saveToken += 1
	local my = saveToken
	task.delay(1.5, function()
		if my ~= saveToken or not SettingsRF then return end
		pcall(function() SettingsRF:InvokeServer("SetTouchLayout", customLayout) end)
	end)
end

loadSavedLayout()

local updateEditHighlight

local function applyButtonTransform(spec)
	local entry = touchButtons[spec.id]
	if not entry then return end
	local custom = customLayout[spec.id]
	local bx = (custom and tonumber(custom.x)) or spec.x
	local by = (custom and tonumber(custom.y)) or spec.y
	local bScale = math.clamp((custom and tonumber(custom.scale)) or 1, 0.75, 1.40)
	local pxSize = math.floor(spec.size * bScale + 0.5)

	entry.button.Position = UDim2.fromOffset(bx, by)
	entry.button.Size = UDim2.fromOffset(pxSize, pxSize)
	if entry.corner then
		entry.corner.CornerRadius = UDim.new(0, math.floor(pxSize / 2))
	end
	if entry.iconRoot then
		local icSz = math.floor(pxSize * 0.44)
		entry.iconRoot.Size = UDim2.fromOffset(icSz, icSz)
	end
end

for _, spec in BUTTON_SPECS do
	local btn = Instance.new("TextButton")
	btn.Name = "Touch_" .. spec.id
	btn.Position = UDim2.fromOffset(spec.x, spec.y)
	btn.Size = UDim2.fromOffset(spec.size, spec.size)
	btn.BackgroundColor3 = C.BgPanel
	btn.BackgroundTransparency = 0.16
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.BorderSizePixel = 0
	btn.Parent = rightPad

	local corner = UiTheme.corner(btn, math.floor(spec.size / 2))
	local stroke = UiTheme.stroke(btn, spec.color, spec.id == "Attack" and 2.8 or 2.0, 0.08)

	local iconSize = math.floor(spec.size * 0.44)
	local ic = UiAssets.icon(btn, spec.icon, iconSize, spec.color)
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.new(0.5, 0, 0.36, 0)

	-- Pastilla inferior oscura para máxima legibilidad del texto sobre cualquier arena
	local capBg = Instance.new("Frame")
	capBg.Name = "CaptionPill"
	capBg.AnchorPoint = Vector2.new(0.5, 1)
	capBg.Position = UDim2.new(0.5, 0, 1, -4)
	capBg.Size = UDim2.new(0.92, 0, 0, 16)
	capBg.BackgroundColor3 = C.BgAbyss
	capBg.BackgroundTransparency = 0.25
	capBg.BorderSizePixel = 0
	capBg.Parent = btn
	UiTheme.corner(capBg, 8)

	local lbl = UiTheme.label({
		name = "Caption",
		parent = capBg,
		size = UDim2.fromScale(1, 1),
		text = L.t(spec.labelKey),
		font = "Bold",
		textSize = 11,
		maxTextSize = 13,
		minTextSize = 9,
		scaled = true,
		color = C.TextPrimary,
		alignX = Enum.TextXAlignment.Center,
		stroke = true,
	})

	local activeTouch = nil
	local stateConn = nil
	local isDown = false

	local function disconnectStateConn()
		if stateConn then
			stateConn:Disconnect()
			stateConn = nil
		end
	end

	local function setPressed(down)
		if down == isDown then return end
		isDown = down
		if down then
			TweenService:Create(btn, UiTheme.Anim.TweenFast, {
				BackgroundColor3 = C.BgCardSelected,
				BackgroundTransparency = 0.04,
			}):Play()
			stroke.Thickness = 3.2
			InputBridge.press(spec.id, true)
		else
			disconnectStateConn()
			TweenService:Create(btn, UiTheme.Anim.TweenFast, {
				BackgroundColor3 = C.BgPanel,
				BackgroundTransparency = 0.16,
			}):Play()
			stroke.Thickness = spec.id == "Attack" and 2.8 or 2.0
			-- Siempre envía false al soltar (crítico para Kick -> KickRelease, Block -> BlockEnd, Heavy -> HeavyRelease)
			InputBridge.press(spec.id, false)
		end
	end

	btn.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if editMode then
			selectedEditId = spec.id
			draggingBtnId = spec.id
			dragStartInput = input
			dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
			local cur = customLayout[spec.id]
			dragStartPos = Vector2.new((cur and cur.x) or spec.x, (cur and cur.y) or spec.y)
			if updateEditHighlight then updateEditHighlight() end
			return
		end
		activeTouch = input
		disconnectStateConn()
		stateConn = input:GetPropertyChangedSignal("UserInputState"):Connect(function()
			if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
				if activeTouch == input then
					activeTouch = nil
					setPressed(false)
				end
			end
		end)
		setPressed(true)
	end)

	btn.InputEnded:Connect(function(input)
		if editMode then
			if input == dragStartInput then
				draggingBtnId = nil
				dragStartInput = nil
				saveLayout()
			end
			return
		end
		if input == activeTouch or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			activeTouch = nil
			setPressed(false)
		end
	end)

	touchButtons[spec.id] = {
		spec = spec,
		button = btn,
		corner = corner,
		stroke = stroke,
		iconRoot = ic,
		label = lbl,
		labelKey = spec.labelKey,
		isActiveInput = function(inp)
			return activeTouch ~= nil and inp == activeTouch
		end,
		release = function()
			activeTouch = nil
			setPressed(false)
		end,
	}
	applyButtonTransform(spec)
end

-- Respaldo global: si el dedo se desliza fuera del botón táctil y se levanta en cualquier parte de la pantalla,
-- garantizamos que se suelte la acción (KickRelease / BlockEnd / HeavyRelease).
UserInputService.InputEnded:Connect(function(input)
	if editMode and input == dragStartInput then
		draggingBtnId = nil
		dragStartInput = nil
		saveLayout()
		return
	end
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		for _, entry in touchButtons do
			if entry.isActiveInput(input) then
				entry.release()
			end
		end
	end
end)

----------------------------------------------------------------------
-- Editor interactivo de botones táctiles (D17)
----------------------------------------------------------------------
local editorBanner = UiTheme.panel({
	name = "TouchEditorBanner",
	parent = gui,
	anchor = Vector2.new(0.5, 0),
	position = UDim2.new(0.5, 0, 0, 12),
	size = UDim2.fromOffset(620, 88),
	bg = C.BgPrimary,
	borderColor = C.GoldBright,
	borderThickness = UiTheme.Stroke.Thick,
	ornaments = true,
	visible = false,
})
local editorScale = Instance.new("UIScale")
editorScale.Parent = editorBanner

local editorTitleLbl = UiTheme.label({
	parent = editorBanner,
	position = UDim2.fromOffset(18, 6),
	size = UDim2.new(1, -36, 0, 22),
	text = L.t("ui.touch.editorTitle"),
	font = "Title",
	textSize = UiTheme.TextSizes.LG,
	color = C.GoldBright,
	alignX = Enum.TextXAlignment.Center,
})

local editorHintLbl = UiTheme.label({
	parent = editorBanner,
	position = UDim2.fromOffset(18, 26),
	size = UDim2.new(1, -36, 0, 18),
	text = L.t("ui.touch.editorHint"),
	font = "Body",
	textSize = UiTheme.TextSizes.XS,
	color = C.TextSecondary,
	alignX = Enum.TextXAlignment.Center,
})

local scaleLabel = UiTheme.label({
	parent = editorBanner,
	position = UDim2.fromOffset(80, 48),
	size = UDim2.fromOffset(150, 32),
	text = L.t("ui.touch.scale", { pct = 100 }),
	font = "Number",
	textSize = UiTheme.TextSizes.SM,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Center,
})

local function adjustSelectedScale(delta)
	local entry = touchButtons[selectedEditId]
	if not entry then return end
	local cur = customLayout[selectedEditId] or { x = entry.spec.x, y = entry.spec.y, scale = 1 }
	cur.scale = math.clamp(math.floor(((cur.scale or 1) + delta) * 20 + 0.5) / 20, 0.75, 1.40)
	customLayout[selectedEditId] = cur
	applyButtonTransform(entry.spec)
	saveLayout()
	updateEditHighlight()
end

UiTheme.button({
	parent = editorBanner,
	position = UDim2.fromOffset(28, 48),
	size = UDim2.fromOffset(44, 32),
	text = "−",
	font = "Number",
	textSize = UiTheme.TextSizes.LG,
	onClick = function()
		adjustSelectedScale(-0.10)
	end,
})

UiTheme.button({
	parent = editorBanner,
	position = UDim2.fromOffset(236, 48),
	size = UDim2.fromOffset(44, 32),
	text = "+",
	font = "Number",
	textSize = UiTheme.TextSizes.LG,
	onClick = function()
		adjustSelectedScale(0.10)
	end,
})

local resetLayoutBtn = UiTheme.button({
	parent = editorBanner,
	position = UDim2.fromOffset(316, 48),
	size = UDim2.fromOffset(138, 32),
	text = L.t("ui.touch.resetLayout"),
	variant = "secondary",
	textSize = UiTheme.TextSizes.SM,
	onClick = function()
		table.clear(customLayout)
		for _, spec in BUTTON_SPECS do
			applyButtonTransform(spec)
		end
		saveLayout()
		updateEditHighlight()
	end,
})

local saveLayoutBtn = UiTheme.button({
	parent = editorBanner,
	position = UDim2.fromOffset(464, 48),
	size = UDim2.fromOffset(138, 32),
	text = L.t("ui.touch.save"),
	variant = "gold",
	textSize = UiTheme.TextSizes.SM,
	onClick = function()
		player:SetAttribute("TouchEditMode", false)
	end,
})

function updateEditHighlight()
	local selCustom = customLayout[selectedEditId]
	local pct = math.floor(((selCustom and selCustom.scale) or 1) * 100 + 0.5)
	scaleLabel.Text = L.t("ui.touch.scale", { pct = pct })
	for id, entry in touchButtons do
		if editMode and id == selectedEditId then
			entry.stroke.Color = C.GoldBright
			entry.stroke.Thickness = 3.4
		else
			entry.stroke.Color = entry.spec.color
			entry.stroke.Thickness = id == "Attack" and 2.8 or 2.0
		end
	end
end

UserInputService.InputChanged:Connect(function(input)
	if not editMode or not draggingBtnId then return end
	if input == dragStartInput or input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local entry = touchButtons[draggingBtnId]
		if not entry then return end
		local sc = math.max(0.4, padScale.Scale)
		local delta = (Vector2.new(input.Position.X, input.Position.Y) - dragStartMouse) / sc
		local cur = customLayout[draggingBtnId] or { x = entry.spec.x, y = entry.spec.y, scale = 1 }
		local pxSize = math.floor(entry.spec.size * (cur.scale or 1))
		cur.x = math.clamp(math.floor(dragStartPos.X + delta.X + 0.5), -140, PAD_W - pxSize + 12)
		cur.y = math.clamp(math.floor(dragStartPos.Y + delta.Y + 0.5), -80, PAD_H - pxSize + 12)
		customLayout[draggingBtnId] = cur
		applyButtonTransform(entry.spec)
	end
end)

-- La cruceta usa la misma predicción, bloqueo de animación y validación que mouse y mando.
local directionPad = Instance.new("Frame")
directionPad.Name = "StancePad"
directionPad.BackgroundTransparency = 1
directionPad.Position = UDim2.fromOffset(119, 3)
directionPad.Size = UDim2.fromOffset(165, 107)
directionPad.Parent = rightPad
local directionCaption = UiTheme.label({ parent = directionPad, position = UDim2.fromOffset(0, 1),
	size = UDim2.new(1, 0, 0, 16), text = L.t("gt.directionPad"), font = "Bold", textSize = 14,
	alignX = Enum.TextXAlignment.Center, color = C.TextPrimary, stroke = true })
local directionButtons = {}
for _, item in { { "Up", "↑", 56, 17 }, { "Left", "←", 1, 56 }, { "Right", "→", 111, 56 } } do
	local direction = item[1]
	local button = UiTheme.button({ name = direction, parent = directionPad,
		position = UDim2.fromOffset(item[3], item[4]), size = UDim2.fromOffset(52, 47),
		text = item[2], textSize = 26, variant = "secondary",
		onClick = function() if not editMode then InputBridge.selectStance(direction) end end })
	button.Selectable = false
	directionButtons[direction] = button
end

local tutorialButtons = {
	lock = { LockOn = true }, switch = { SwitchTarget = true, LockOn = true },
	light = { Attack = true, LockOn = true }, heavy = { Heavy = true, LockOn = true },
	dirs = { Attack = true, LockOn = true }, combo = { Attack = true, LockOn = true },
	dodge = { Dodge = true }, down = { Attack = true, Heavy = true, Kick = true, LockOn = true, SwitchTarget = true },
	carry = { Kick = true, Attack = true, Heavy = true, LockOn = true },
	throw = { Kick = true, Attack = true, Heavy = true, LockOn = true },
	block = { Block = true, LockOn = true, SwitchTarget = true }, parry = { Block = true, LockOn = true, SwitchTarget = true },
	infuse = { Infuse = true },
}

-- En celular con mando, Device elige el dispositivo activo.
local function updateVisibilityAndScale()
	editMode = player:GetAttribute("TouchEditMode") == true
	editorBanner.Visible = editMode

	local isTouch = Device.isTouch()
	local menuOpen = player:GetAttribute("MenuOpen") == true
	local inTutorial = player:GetAttribute("InTutorial") == true
	local inMatch = player:GetAttribute("InMatch") == true
	local canFight = not inMatch or player:GetAttribute("MatchPhase") == "Round"
	local lesson = player:GetAttribute("TutorialLesson")
	local lessonButtons = tutorialButtons[lesson]
	local show = editMode or (isTouch and canFight and not menuOpen and not player:GetAttribute("MainMenuOpen")
		and not player:GetAttribute("InitialLoading") and (not inTutorial or lessonButtons ~= nil))
	rightPad.Visible = show
	for id, entry in touchButtons do
		local visible = show and (editMode or not inTutorial or (lessonButtons and lessonButtons[id] == true))
		if entry.button.Visible and not visible then entry.release() end
		entry.button.Visible = visible == true
	end
	local lock = player:FindFirstChild("LockTarget")
	local char = player.Character
	local stance = char and (char:GetAttribute("AttackDir") or "")
	if stance == "" and char then
		local predicted = player:FindFirstChild("PredictedStance")
		stance = predicted and os.clock() - (predicted:GetAttribute("At") or 0) < Directional.Input.PredictHold
			and predicted.Value or char:GetAttribute("Stance")
	end
	directionPad.Visible = Directional.Enabled and show and not editMode and lock ~= nil and lock.Value ~= nil
		and (not inTutorial or lesson == "dirs" or lesson == "block" or lesson == "parry")
	for direction, button in directionButtons do
		local selected = direction == stance
		button.BackgroundColor3 = selected and C.BgCardSelected or C.BgPanel
		button.TextColor3 = selected and Polish.Directional.Stance or C.TextSecondary
	end

	local vp = gui.AbsoluteSize
	if vp.X <= 0 or vp.Y <= 0 then return end
	local bottom = (inMatch or inTutorial or editMode) and Mobile.PadEdge
		or Mobile.QueueBottom + Mobile.QueueHeight + Mobile.Gap
	rightPad.Position = UDim2.new(1, -Mobile.PadEdge, 1, -bottom)

	local opt = player:GetAttribute("OptUiScale") or 1
	local widthCap = (vp.X * Mobile.PadWidthShare - Mobile.PadEdge) / PAD_W
	local topInset = inTutorial and (vp.Y < 440 and 132 or 163) or Mobile.Margin
	local heightCap = math.min(vp.Y * Mobile.PadHeightShare, vp.Y - bottom - topInset) / PAD_H
	padScale.Scale = math.max(0.1, math.min(widthCap, heightCap, Mobile.PadMaxScale * opt))
	editorScale.Scale = UiTheme.computeScale(vp, 660, 480, player)
end

player:GetAttributeChangedSignal("TouchEditMode"):Connect(function()
	for _, entry in touchButtons do entry.release() end
	updateVisibilityAndScale()
	updateEditHighlight()
end)

Device.Changed:Connect(updateVisibilityAndScale)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateVisibilityAndScale)
for _, attr in { "InMatch", "InTutorial", "TutorialLesson", "MenuOpen", "MatchPhase", "InitialLoading", "MainMenuOpen", "OptUiScale" } do
	player:GetAttributeChangedSignal(attr):Connect(updateVisibilityAndScale)
end
-- 11/11 (rendimiento): 10 veces por segundo en vez de cada frame
local touchAcc = 0
RunService.Heartbeat:Connect(function(dt)
	touchAcc += dt
	if touchAcc < 0.1 then return end
	touchAcc = 0
	updateVisibilityAndScale()
end)
updateVisibilityAndScale()

L.Changed:Connect(function()
	directionCaption.Text = L.t("gt.directionPad")
	editorTitleLbl.Text = L.t("ui.touch.editorTitle")
	editorHintLbl.Text = L.t("ui.touch.editorHint")
	resetLayoutBtn.Text = L.t("ui.touch.resetLayout")
	saveLayoutBtn.Text = L.t("ui.touch.save")
	updateEditHighlight()
	for _, entry in touchButtons do
		entry.label.Text = L.t(entry.labelKey)
	end
end)

-- Integración 0.2 (ronda 2): el perfil guardado llega después de que arranca este script (TouchLayoutJson lo
-- publica PlayerData al cargar). Al llegar, se vuelve a aplicar el diseño (salvo mientras se edita).
player:GetAttributeChangedSignal("TouchLayoutJson"):Connect(function()
	if savingLocal or editMode then return end
	loadSavedLayout()
	for _, entry in touchButtons do
		applyButtonTransform(entry.spec)
	end
end)
