-- LocalScript: StarterPlayer/StarterPlayerScripts/Settings
-- Menú de Ajustes rediseñado (Fase 4, Contrato C10, responsable: Gemini, etapa 8).
-- Incluye:
-- 1. Volumen de música (OptMusic -> SoundService.Music), efectos (OptSfx -> SoundService.SFX),
--    sacudida de cámara (OptShake) y escala de interfaz (OptUiScale, 0.8..1.2).
-- 2. Selección de idioma (ES, EN, PT-BR).
-- 3. Reasignación de controles para Teclado/Ratón y Mando (BindsChanged).

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local UiTheme = require(RS:WaitForChild("UiTheme", 10))
local UiAssets = require(RS:WaitForChild("UiAssets", 10))
local L = require(RS:WaitForChild("Localization", 10))
local InputMap = require(RS:WaitForChild("InputMap", 10))

local player = Players.LocalPlayer
local remotesFolder = RS:WaitForChild("Remotes", 10)
local remote = remotesFolder and remotesFolder:WaitForChild("Settings", 10)
local Device = require(RS:WaitForChild("Device"))
local C = UiTheme.Colors

----------------------------------------------------------------------
-- 1. SoundGroups (Contrato C10: aplicar OptMusic y OptSfx al iniciar y al cambiar)
----------------------------------------------------------------------
local function ensureGroup(name)
	local g = SoundService:FindFirstChild(name)
	if not g or not g:IsA("SoundGroup") then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Volume = 1
		g.Parent = SoundService
	end
	return g
end

local musicGroup = ensureGroup("Music")
local sfxGroup = ensureGroup("SFX")

local function applyAudioVolumes()
	local mVol = player:GetAttribute("OptMusic")
	local sVol = player:GetAttribute("OptSfx")
	musicGroup.Volume = math.clamp(type(mVol) == "number" and mVol or 1, 0, 1)
	sfxGroup.Volume = math.clamp(type(sVol) == "number" and sVol or 1, 0, 1)
end

player:GetAttributeChangedSignal("OptMusic"):Connect(applyAudioVolumes)
player:GetAttributeChangedSignal("OptSfx"):Connect(applyAudioVolumes)
applyAudioVolumes()

----------------------------------------------------------------------
-- 2. ScreenGui y botón de acceso superior izquierdo (junto a Armería)
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SettingsGui"
gui.DisplayOrder = 12
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local topBtnScale = Instance.new("UIScale")
local toggleBtn = UiTheme.button({
	name = "SettingsToggle",
	parent = gui,
	position = UDim2.fromOffset(192, 12),
	size = UDim2.fromOffset(168, 44),
	text = L.t("settings"),
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "secondary",
})
topBtnScale.Parent = toggleBtn

local gearIcon = UiAssets.icon(toggleBtn, "settings", 20, C.GoldBright)
gearIcon.AnchorPoint = Vector2.new(0, 0.5)
gearIcon.Position = UDim2.new(0, 10, 0.5, 0)
toggleBtn.TextXAlignment = Enum.TextXAlignment.Left
toggleBtn.Visible = false
UiTheme.padding(toggleBtn, 0, 10, 0, 36)

local veil = Instance.new("Frame")
veil.Name = "Backdrop"
veil.Size = UDim2.fromScale(1, 1)
veil.BackgroundColor3 = C.BgAbyss
veil.BackgroundTransparency = 0.34
veil.BorderSizePixel = 0
veil.Visible = false
veil.Parent = gui

local BASE_W, BASE_H = 820, 720 -- 11/11: más alto para las opciones de rendimiento
local panel = UiTheme.panel({
	name = "SettingsPanel",
	parent = gui,
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.fromScale(0.5, 0.5),
	size = UDim2.fromOffset(BASE_W, BASE_H),
	bg = C.BgPrimary,
	borderColor = C.Gold,
	borderThickness = UiTheme.Stroke.Thick,
	ornaments = true,
	ornamentSize = 14,
	visible = false,
})
local scale = Instance.new("UIScale")
scale.Parent = panel

----------------------------------------------------------------------
-- 3. Estado local de opciones y controles
----------------------------------------------------------------------
local activeTab = "Audio" -- "Audio" | "Controls"
local bindingDevice = Device.isGamepad() and "Gamepad" or "Keyboard"
local function displayBinding(key)
	local localized = L.binding(key)
	return localized == key and InputMap.label(key) or localized
end
local binds = InputMap.merge(nil)
local options = {
	MusicVolume = 1,
	SfxVolume = 1,
	CameraShake = 1,
	UiScale = 1,
	ShowFps = 0,
	Effects = 1,
}
local capturing = nil
local busy = false
----------------------------------------------------------------------
-- 12/11/2026 (pedido del usuario): teclado completo y mando detallado en Controles.
-- Las teclas/botones asignados a una acción brillan en dorado; WASD (moverse) en plata.
----------------------------------------------------------------------
local KEY_ROWS = {
	{ { "Escape", 1, "Esc" }, { "", 0.6 }, { "F1" }, { "F2" }, { "F3" }, { "F4" }, { "", 0.4 }, { "F5" }, { "F6" }, { "F7" }, { "F8" },
		{ "", 0.4 }, { "F9" }, { "F10" }, { "F11" }, { "F12" } },
	{ { "Backquote", 1, "`" }, { "One", 1, "1" }, { "Two", 1, "2" }, { "Three", 1, "3" }, { "Four", 1, "4" }, { "Five", 1, "5" },
		{ "Six", 1, "6" }, { "Seven", 1, "7" }, { "Eight", 1, "8" }, { "Nine", 1, "9" }, { "Zero", 1, "0" }, { "Minus", 1, "-" },
		{ "Equals", 1, "=" }, { "Backspace", 2, "⌫" } },
	{ { "Tab", 1.5, "Tab" }, { "Q" }, { "W" }, { "E" }, { "R" }, { "T" }, { "Y" }, { "U" }, { "I" }, { "O" }, { "P" },
		{ "LeftBracket", 1, "[" }, { "RightBracket", 1, "]" }, { "BackSlash", 1.5, "\\" } },
	{ { "CapsLock", 1.75, "Bloq" }, { "A" }, { "S" }, { "D" }, { "F" }, { "G" }, { "H" }, { "J" }, { "K" }, { "L" },
		{ "Semicolon", 1, "Ñ" }, { "Quote", 1, "'" }, { "Return", 2.25, "Enter" } },
	{ { "LeftShift", 2.25, "Shift" }, { "Z" }, { "X" }, { "C" }, { "V" }, { "B" }, { "N" }, { "M" }, { "Comma", 1, "," },
		{ "Period", 1, "." }, { "Slash", 1, "-" }, { "RightShift", 2.75, "Shift" } },
	{ { "LeftControl", 1.5, "Ctrl" }, { "LeftAlt", 1.5, "Alt" }, { "Space", 9, "Espacio" }, { "RightAlt", 1.5, "Alt Gr" },
		{ "RightControl", 1.5, "Ctrl" } },
}
local MOVE_KEYS = { W = true, A = true, S = true, D = true }

local function keyCap(parent, x, y, w, h, text, state, z)
	local k = Instance.new("Frame")
	k.Position = UDim2.fromOffset(x, y)
	k.Size = UDim2.fromOffset(w, h)
	k.BackgroundColor3 = state == "bound" and C.GoldBright or (state == "move" and C.BorderStrong or C.BgAbyss)
	k.BorderSizePixel = 0
	k.ZIndex = z or 3
	k.Parent = parent
	UiTheme.corner(k, 4)
	local st = Instance.new("UIStroke")
	st.Color = state == "bound" and C.GoldBright or C.BorderDefault
	st.Thickness = state == "bound" and 2 or 1
	st.Transparency = state == "bound" and 0 or 0.4
	st.Parent = k
	if state == "bound" then
		local glow = Instance.new("UIGradient")
		glow.Rotation = 90
		glow.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 170, 110))
		glow.Parent = k
	end
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Text = text
	lbl.TextScaled = true
	lbl.FontFace = UiTheme.FontFaces.Bold
	lbl.TextColor3 = state == "bound" and C.BgAbyss or (state == "move" and C.BgAbyss or C.TextSecondary)
	lbl.ZIndex = (z or 3) + 1
	lbl.Parent = k
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0) pad.PaddingBottom = UDim.new(0.18, 0)
	pad.PaddingLeft = UDim.new(0, 3) pad.PaddingRight = UDim.new(0, 3)
	pad.Parent = lbl
	return k
end

-- acciones por tecla: { ["Q"] = { "Block" }, ... }
local function reverseBinds(map)
	local out = {}
	for action, key in map or {} do
		if type(key) == "string" and action ~= "__layout" then
			out[key] = out[key] or {}
			table.insert(out[key], action)
		end
	end
	return out
end

local function drawKeyboard(parent, w, h, map, caption)
	local bound = reverseBinds(map)
	local mouseW = 96
	local unit = math.floor((w - mouseW - 40) / 15)
	local keyH = math.floor((h - 24) / 6) - 3
	local x0, y0 = 12, 12
	for r, row in KEY_ROWS do
		local x = x0
		for _, key in row do
			local name, units, text = key[1], key[2] or 1, key[3] or key[1]
			local kw = math.floor(units * unit) - 3
			if name ~= "" then
				local state = bound[name] and "bound" or (MOVE_KEYS[name] and "move" or nil)
				local cap = keyCap(parent, x, y0 + (r - 1) * (keyH + 3), kw, keyH, text, state)
				if bound[name] then
					cap.MouseEnter:Connect(function() caption(text, bound[name]) end)
				end
			end
			x += math.floor(units * unit)
		end
	end
	-- mouse
	local mx = w - mouseW - 12
	local body = Instance.new("Frame")
	body.Position = UDim2.fromOffset(mx, y0 + 6)
	body.Size = UDim2.fromOffset(mouseW - 12, h - 36)
	body.BackgroundColor3 = C.BgAbyss
	body.BorderSizePixel = 0
	body.Parent = parent
	UiTheme.corner(body, 34)
	UiTheme.stroke(body, C.BorderDefault, 1, 0.3)
	local bw = math.floor((mouseW - 12) / 2) - 2
	for i, btn in { { "MouseButton1", "M1" }, { "MouseButton2", "M2" } } do
		keyCap(body, (i - 1) * (bw + 4), 0, bw, 46, btn[2], bound[btn[1]] and "bound" or nil, 5)
	end
	keyCap(body, bw - 6, 10, 16, 24, "", bound.MouseButton3 and "bound" or nil, 7)
end

local PAD_BUTTONS = {
	-- nombre, x, y, ancho, alto, texto, lado de la etiqueta
	{ "ButtonL2", 0.30, 0.02, 0.10, 0.10, "LT", "L" }, { "ButtonL1", 0.30, 0.14, 0.10, 0.08, "LB", "L" },
	{ "ButtonR2", 0.60, 0.02, 0.10, 0.10, "RT", "R" }, { "ButtonR1", 0.60, 0.14, 0.10, 0.08, "RB", "R" },
	{ "ButtonL3", 0.335, 0.36, 0.075, 0.2, "L3", "L" }, { "ButtonR3", 0.545, 0.58, 0.075, 0.2, "R3", "R" },
	{ "DPadUp", 0.415, 0.55, 0.03, 0.09, "▲", "L" }, { "DPadDown", 0.415, 0.75, 0.03, 0.09, "▼", "L" },
	{ "DPadLeft", 0.385, 0.65, 0.03, 0.09, "◀", "L" }, { "DPadRight", 0.445, 0.65, 0.03, 0.09, "▶", "L" },
	{ "ButtonY", 0.615, 0.27, 0.04, 0.12, "Y", "R" }, { "ButtonX", 0.578, 0.39, 0.04, 0.12, "X", "R" },
	{ "ButtonB", 0.652, 0.39, 0.04, 0.12, "B", "R" }, { "ButtonA", 0.615, 0.51, 0.04, 0.12, "A", "R" },
	{ "ButtonSelect", 0.455, 0.36, 0.035, 0.08, "⧉", "L" }, { "ButtonStart", 0.51, 0.36, 0.035, 0.08, "≡", "R" },
}

local function drawGamepad(parent, w, h, map, actionName)
	local bound = reverseBinds(map)
	-- cuerpo del mando
	local body = Instance.new("Frame")
	body.Position = UDim2.new(0.31, 0, 0.22, 0)
	body.Size = UDim2.new(0.38, 0, 0.7, 0)
	body.BackgroundColor3 = C.BgCard
	body.BorderSizePixel = 0
	body.Parent = parent
	UiTheme.corner(body, 40)
	UiTheme.stroke(body, C.BorderStrong, 1.5, 0.1)
	for _, side in { 0, 1 } do
		local grip = Instance.new("Frame")
		grip.AnchorPoint = Vector2.new(side, 0)
		grip.Position = UDim2.new(side == 0 and 0.31 or 0.69, 0, 0.5, 0)
		grip.Size = UDim2.new(0.1, 0, 0.48, 0)
		grip.BackgroundColor3 = C.BgCard
		grip.BorderSizePixel = 0
		grip.Parent = parent
		UiTheme.corner(grip, 30)
	end
	local left, right = {}, {}
	for _, b in PAD_BUTTONS do
		local state = bound[b[1]] and "bound" or nil
		local round = b[1]:match("^Button[ABXY]$") or b[1]:match("[LR]3$")
		local cap = keyCap(parent, math.floor(b[2] * w), math.floor(b[3] * h), math.max(14, math.floor(b[4] * w)),
			math.max(12, math.floor(b[5] * h)), b[6], state, 6)
		if round then UiTheme.corner(cap, 99) end
		if state then
			local names = {}
			for _, a in bound[b[1]] do table.insert(names, actionName(a)) end
			table.insert(b[7] == "L" and left or right, { y = b[3], text = b[6] .. "  ·  " .. table.concat(names, " / ") })
		end
	end
	-- etiquetas a los costados, ordenadas de arriba a abajo
	for side, list in { L = left, R = right } do
		table.sort(list, function(a, b2) return a.y < b2.y end)
		for i, item in list do
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Position = UDim2.new(side == "L" and 0.01 or 0.72, 0, 0, 10 + (i - 1) * 24)
			lbl.Size = UDim2.new(0.27, 0, 0, 22)
			lbl.Text = item.text
			lbl.TextXAlignment = side == "L" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
			lbl.TextColor3 = C.TextPrimary
			lbl.FontFace = UiTheme.FontFaces.Body
			lbl.TextScaled = true
			lbl.Parent = parent
			local c = Instance.new("UITextSizeConstraint")
			c.MaxTextSize = 15
			c.Parent = lbl
		end
	end
end

local render, setOpen

local function syncOptionsFromAttributes()
	options.MusicVolume = tonumber(player:GetAttribute("OptMusic")) or options.MusicVolume or 1
	options.SfxVolume = tonumber(player:GetAttribute("OptSfx")) or options.SfxVolume or 1
	options.CameraShake = tonumber(player:GetAttribute("OptShake")) or options.CameraShake or 1
	options.UiScale = tonumber(player:GetAttribute("OptUiScale")) or options.UiScale or 1
	options.ShowFps = tonumber(player:GetAttribute("OptFps")) or options.ShowFps or 0
	options.Effects = tonumber(player:GetAttribute("OptFx")) or options.Effects or 1
	topBtnScale.Scale = options.UiScale
end
syncOptionsFromAttributes()

local function notifyBinds(value)
	if type(value) ~= "table" then return end
	binds = value
	local event = player:FindFirstChild("BindsChanged")
	if event then event:Fire(value) end
end

local function invoke(action, payload, callback)
	if busy then return end
	busy = true
	task.spawn(function()
		local ok, result = pcall(function()
			return remote:InvokeServer(action, payload)
		end)
		busy = false
		if ok and result then
			callback(result)
		else
			render("error")
		end
	end)
end

local function updateOption(key, newVal)
	local payload = {
		MusicVolume = options.MusicVolume,
		SfxVolume = options.SfxVolume,
		CameraShake = options.CameraShake,
		UiScale = options.UiScale,
		ShowFps = options.ShowFps,
		Effects = options.Effects,
	}
	payload[key] = newVal
	options[key] = newVal

	-- Reflejo inmediato en cliente para respuesta instantánea
	if key == "MusicVolume" then musicGroup.Volume = math.clamp(newVal, 0, 1)
	elseif key == "SfxVolume" then sfxGroup.Volume = math.clamp(newVal, 0, 1) end

	invoke("SetOptions", payload, function(savedOpts)
		if type(savedOpts) == "table" then
			for k, v in savedOpts do options[k] = v end
		end
		applyAudioVolumes()
		if panel.Visible then render("ui.settings.saved") end
	end)
end

----------------------------------------------------------------------
-- 4. Renderizado del panel de Ajustes
----------------------------------------------------------------------
local OPTION_ROWS = {
	{ key = "MusicVolume", labelKey = "ui.settings.music", min = 0, max = 1, step = 0.1, isScale = false },
	{ key = "SfxVolume",   labelKey = "ui.settings.sfx",   min = 0, max = 1, step = 0.1, isScale = false },
	{ key = "CameraShake", labelKey = "ui.settings.shake", min = 0, max = 1, step = 0.1, isScale = false },
	{ key = "UiScale",     labelKey = "ui.settings.uiScale", min = 0.8, max = 1.2, step = 0.05, isScale = true },
	-- 11/11: interruptores (paso 1): el texto de la barra dice Apagado/Encendido o Reducidos/Completos
	{ key = "ShowFps",     labelKey = "ui.settings.fps", min = 0, max = 1, step = 1, labels = { "ui.settings.off", "ui.settings.on" } },
	{ key = "Effects",     labelKey = "ui.settings.effects", min = 0, max = 1, step = 1, labels = { "ui.settings.fxLow", "ui.settings.fxHigh" } },
}

function render(messageKey)
	capturing = nil
	syncOptionsFromAttributes()
	for _, v in panel:GetChildren() do
		if v ~= scale and not v:IsA("UIStroke") and not v:IsA("UICorner") and not v:IsA("UIGradient") and v.Name ~= "Ornaments" and v.Name ~= "FrameArt" then
			v:Destroy()
		end
	end

	-- Cabecera
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = panel
	UiTheme.corner(header, UiTheme.Radius.MD)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(22, 0),
		size = UDim2.fromOffset(420, 54),
		text = string.upper(L.t("settings")),
		font = "Title",
		textSize = UiTheme.TextSizes.XXL,
		color = C.GoldBright,
	})

	local closeBtn = UiTheme.button({
		name = "CloseBtn",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = UDim2.new(1, -16, 0.5, 0),
		size = UDim2.fromOffset(106, 38),
		text = L.t("close"),
		onClick = function()
			setOpen(false)
		end,
	})

	-- Pestañas internas: Audio y Vídeo | Controles
	local tabBar = Instance.new("Frame")
	tabBar.Position = UDim2.fromOffset(22, 64)
	tabBar.Size = UDim2.new(1, -44, 0, 42)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = panel

	local firstTabBtn = UiTheme.tabButton({
		parent = tabBar,
		position = UDim2.fromOffset(0, 0),
		size = UDim2.fromOffset(220, 42),
		text = L.t("ui.settings.tabAudio"),
		active = activeTab == "Audio",
		onClick = function()
			activeTab = "Audio"
			render()
		end,
	})

	UiTheme.tabButton({
		parent = tabBar,
		position = UDim2.fromOffset(230, 0),
		size = UDim2.fromOffset(220, 42),
		text = L.t("ui.settings.tabControls"),
		active = activeTab == "Controls",
		onClick = function()
			activeTab = "Controls"
			render()
		end,
	})

	if activeTab == "Audio" then
		-- Selección de idioma
		local langPanel = UiTheme.panel({
			parent = panel,
			position = UDim2.fromOffset(22, 118),
			size = UDim2.new(1, -44, 0, 68),
			bg = C.BgCard,
			borderColor = C.BorderDefault,
		})

		UiTheme.label({
			parent = langPanel,
			position = UDim2.fromOffset(18, 0),
			size = UDim2.fromOffset(200, 68),
			text = L.t("language"),
			font = "Header",
			textSize = UiTheme.TextSizes.LG,
			color = C.GoldBright,
		})

		for i, language in { "ES", "EN", "PT-BR" } do
			UiTheme.button({
				parent = langPanel,
				position = UDim2.fromOffset(240 + (i - 1) * 176, 12),
				size = UDim2.fromOffset(166, 44),
				text = L.t("language." .. language),
				selected = L.language() == language,
				onClick = function()
					invoke("SetLanguage", language, function()
						render("ui.settings.saved")
					end)
				end,
			})
		end

		-- Controles deslizantes por pasos (compatibles con ratón, táctil y mando)
		for idx, spec in OPTION_ROWS do
			local y = 200 + (idx - 1) * 72
			local rowCard = UiTheme.panel({
				parent = panel,
				position = UDim2.fromOffset(22, y),
				size = UDim2.new(1, -44, 0, 66),
				bg = C.BgCard,
				borderColor = C.BorderSubtle,
			})

			local curVal = options[spec.key] or 1
			local frac = math.clamp((curVal - spec.min) / (spec.max - spec.min), 0, 1)
			local pctText = spec.labels and L.t(spec.labels[math.floor(curVal + 0.5) + 1] or spec.labels[1])
				or ("%d%%"):format(math.floor(curVal * 100 + 0.5))

			UiTheme.label({
				parent = rowCard,
				position = UDim2.fromOffset(18, 0),
				size = UDim2.fromOffset(230, 66),
				text = L.t(spec.labelKey),
				font = "Header",
				textSize = UiTheme.TextSizes.LG,
				color = C.TextPrimary,
			})

			UiTheme.button({
				parent = rowCard,
				position = UDim2.fromOffset(260, 11),
				size = UDim2.fromOffset(48, 44),
				text = "−",
				font = "Number",
				textSize = UiTheme.TextSizes.XL,
				onClick = function()
					local nextV = math.clamp(math.floor(((curVal - spec.step) / spec.step) + 0.5) * spec.step, spec.min, spec.max)
					updateOption(spec.key, nextV)
				end,
			})

			local barBg = UiTheme.progressBar({
				parent = rowCard,
				position = UDim2.fromOffset(318, 23),
				size = UDim2.fromOffset(320, 20),
				fraction = frac,
				fillColor = C.Gold,
				showText = true,
				text = pctText,
			})

			-- Clic directo en la barra para elegir porcentaje rápidamente
			local barHit = Instance.new("TextButton")
			barHit.Size = UDim2.fromScale(1, 1)
			barHit.BackgroundTransparency = 1
			barHit.Text = ""
			barHit.Selectable = false
			barHit.ZIndex = barBg.ZIndex + 4
			barHit.Parent = barBg
			barHit.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
					local rel = math.clamp((inp.Position.X - barBg.AbsolutePosition.X) / math.max(1, barBg.AbsoluteSize.X), 0, 1)
					local raw = spec.min + rel * (spec.max - spec.min)
					local snapped = math.clamp(math.floor((raw / spec.step) + 0.5) * spec.step, spec.min, spec.max)
					updateOption(spec.key, snapped)
				end
			end)

			UiTheme.button({
				parent = rowCard,
				position = UDim2.fromOffset(648, 11),
				size = UDim2.fromOffset(48, 44),
				text = "+",
				font = "Number",
				textSize = UiTheme.TextSizes.XL,
				onClick = function()
					local nextV = math.clamp(math.floor(((curVal + spec.step) / spec.step) + 0.5) * spec.step, spec.min, spec.max)
					updateOption(spec.key, nextV)
				end,
			})
		end
	else
		-- Pestaña Controles: reasignación de Teclado y Mando
		UiTheme.label({
			parent = panel,
			position = UDim2.fromOffset(28, 114),
			size = UDim2.fromOffset(280, 26),
			text = L.t("controls"),
			font = "Header",
			textSize = UiTheme.TextSizes.LG,
			color = C.GoldBright,
		})
		for i, device in { "Keyboard", "Gamepad" } do
			UiTheme.button({
				name = "Map_" .. device, parent = panel,
				position = UDim2.fromOffset(380 + (i - 1) * 190, 108),
				size = UDim2.fromOffset(180, 32),
				text = L.t(device == "Keyboard" and "keyboard" or "gamepad"),
				selected = bindingDevice == device,
				onClick = function() bindingDevice = device render() end,
			})
		end

		local DIAGRAM_H = 216
		local diagram = UiTheme.panel({
			name = "InputDiagram", parent = panel, position = UDim2.fromOffset(22, 148),
			size = UDim2.fromOffset(BASE_W - 44, DIAGRAM_H), bg = C.BgPreview,
			borderColor = C.BorderSubtle, frameArt = false,
		})
		local hint = UiTheme.label({ parent = panel, position = UDim2.fromOffset(22, 148 + DIAGRAM_H + 2),
			size = UDim2.fromOffset(BASE_W - 44, 18), text = L.t("ctl.hint"), font = "Body",
			textSize = UiTheme.TextSizes.XS, color = C.TextSecondary })
		local function actionName(a) return L.t("action." .. a) end
		if bindingDevice == "Gamepad" then
			drawGamepad(diagram, BASE_W - 44, DIAGRAM_H, binds.Gamepad, actionName)
		else
			drawKeyboard(diagram, BASE_W - 44, DIAGRAM_H, binds.Keyboard, function(key, actions)
				local names = {}
				for _, a in actions do table.insert(names, actionName(a)) end
				hint.Text = key .. "  ·  " .. table.concat(names, " / ")
			end)
		end

		local bindsScroll = Instance.new("ScrollingFrame")
		bindsScroll.Name = "BindingsList"
		bindsScroll.Position = UDim2.fromOffset(22, 148 + DIAGRAM_H + 24)
		bindsScroll.Size = UDim2.fromOffset(BASE_W - 44, 162)
		bindsScroll.BackgroundTransparency = 1
		bindsScroll.BorderSizePixel = 0
		bindsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		bindsScroll.CanvasSize = UDim2.new()
		bindsScroll.ScrollBarThickness = 5
		bindsScroll.ScrollBarImageColor3 = C.Gold
		bindsScroll.Parent = panel

		local bLayout = Instance.new("UIListLayout")
		bLayout.Padding = UDim.new(0, 6)
		bLayout.SortOrder = Enum.SortOrder.LayoutOrder
		bLayout.Parent = bindsScroll

		for i, action in InputMap.Actions do
			local row = UiTheme.panel({ parent = bindsScroll, layoutOrder = i,
				size = UDim2.new(1, -10, 0, 42), bg = C.BgCard, borderColor = C.BorderSubtle })
			UiTheme.label({ parent = row, position = UDim2.fromOffset(14, 0), size = UDim2.new(1, -245, 1, 0),
				text = L.t("action." .. action.id), font = "Body", textSize = UiTheme.TextSizes.MD })
			local device = bindingDevice
			local b
			b = UiTheme.button({
				name = "Bind_" .. device .. "_" .. action.id, parent = row,
				anchor = Vector2.new(1, 0), position = UDim2.new(1, -12, 0, 3),
				size = UDim2.fromOffset(200, 36), text = displayBinding(binds[device][action.id]),
				textSize = UiTheme.TextSizes.SM, onClick = function()
					if busy then return end
					capturing = { device = device, action = action.id }
					b.Text = L.t("press")
					local prompt = panel:FindFirstChild("Message")
					if prompt and prompt:IsA("TextLabel") then prompt.Text = L.t("press") end
				end,
			})
		end

		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(22, 560),
			size = UDim2.fromOffset(214, 40),
			text = L.t("reset"),
			variant = "secondary",
			onClick = function()
				invoke("ResetBinds", nil, function(value)
					notifyBinds(value)
					render("ui.settings.saved")
				end)
			end,
		})

		UiTheme.button({
			name = "EditTouchLayoutBtn",
			parent = panel,
			position = UDim2.fromOffset(246, 560),
			size = UDim2.fromOffset(230, 40),
			text = L.t("ui.touch.editLayout"),
			variant = "gold",
			onClick = function()
				setOpen(false)
				player:SetAttribute("TouchEditMode", true)
			end,
		})

		UiTheme.label({
			parent = panel,
			position = UDim2.fromOffset(488, 560),
			size = UDim2.fromOffset(310, 40),
			text = L.t("fixed"),
			font = "Body",
			textSize = UiTheme.TextSizes.SM,
			color = C.TextSecondary,
		})
	end

	local msg = UiTheme.label({
		name = "Message",
		parent = panel,
		position = UDim2.fromOffset(22, BASE_H - 36),
		size = UDim2.new(1, -44, 0, 26),
		text = messageKey and L.t(messageKey) or "",
		font = "Bold",
		textSize = UiTheme.TextSizes.SM,
		color = C.GoldBright,
	})
	msg.Name = "Message"

	toggleBtn.Text = L.t("settings")
	if Device.isGamepad() then
		GuiService.SelectedObject = firstTabBtn or closeBtn
	end
end

function setOpen(value)
	capturing = nil
	panel.Visible = value
	veil.Visible = value
	if value then
		player:SetAttribute("TouchEditMode", false)
		player:SetAttribute("ShopOpen", false)
		player:SetAttribute("ArmoryOpen", false)
		player:SetAttribute("RewardsOpen", false)
	end
	player:SetAttribute("SettingsOpen", value)
	player:SetAttribute("MenuOpen", value
		or player:GetAttribute("ShopOpen") == true
		or player:GetAttribute("ArmoryOpen") == true
		or player:GetAttribute("RewardsOpen") == true)
	UiTheme.playSound(value and "UI_MenuOpen" or "UI_MenuClose")

	if value then
		render()
		invoke("GetBinds", nil, function(result)
			notifyBinds(result)
			if panel.Visible then render() end
		end)
		task.spawn(function()
			local ok, optRes = pcall(function()
				return remote:InvokeServer("GetOptions")
			end)
			if ok and type(optRes) == "table" then
				for k, v in optRes do options[k] = v end
				applyAudioVolumes()
				if panel.Visible then render() end
			end
		end)
	else
		GuiService.SelectedObject = nil
	end
end

toggleBtn.Activated:Connect(function()
	setOpen(not panel.Visible)
end)

player:GetAttributeChangedSignal("SettingsOpen"):Connect(function()
	local desired = player:GetAttribute("SettingsOpen") == true
	if desired ~= panel.Visible then
		setOpen(desired)
	end
end)

player:GetAttributeChangedSignal("ShopOpen"):Connect(function()
	if player:GetAttribute("ShopOpen") and panel.Visible then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("ArmoryOpen"):Connect(function()
	if player:GetAttribute("ArmoryOpen") and panel.Visible then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("RewardsOpen"):Connect(function()
	if player:GetAttribute("RewardsOpen") and panel.Visible then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("OptUiScale"):Connect(function()
	syncOptionsFromAttributes()
end)

UIS.InputBegan:Connect(function(input, processed)
	if not panel.Visible then return end
	if input.KeyCode == Enum.KeyCode.Escape or (not capturing and input.KeyCode == Enum.KeyCode.ButtonB) then
		if capturing then
			render()
		else
			setOpen(false)
		end
		return
	end
	if not capturing or busy then return end
	if (capturing.device == "Gamepad") ~= InputMap.isGamepad(input) then return end
	local name = InputMap.inputName(input)
	if not name or input.UserInputType == Enum.UserInputType.MouseMovement then return end
	if InputMap.Reserved[name] then
		local msg = panel:FindFirstChild("Message")
		if msg and msg:IsA("TextLabel") then msg.Text = L.t("reserved") end
		return
	end
	local cap = capturing
	capturing = nil
	local value = {
		Keyboard = table.clone(binds.Keyboard),
		Gamepad = table.clone(binds.Gamepad),
	}
	for action, key in value[cap.device] do
		if key == name and action ~= cap.action then
			value[cap.device][action] = value[cap.device][cap.action]
		end
	end
	value[cap.device][cap.action] = name
	invoke("SetBinds", value, function(result)
		notifyBinds(result)
		render("ui.settings.saved")
	end)
end)

L.Changed:Connect(function()
	toggleBtn.Text = L.t("settings")
	if panel.Visible then render() end
end)

-- 11/11: solo se recalcula cuando cambia la pantalla o la escala elegida (antes en cada frame)
local lastScaleKey = nil
RunService.Heartbeat:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local key = tostring(cam.ViewportSize) .. tostring(player:GetAttribute("OptUiScale"))
	if key == lastScaleKey then return end
	lastScaleKey = key
	scale.Scale = UiTheme.computeScale(cam.ViewportSize, BASE_W, BASE_H, player)
end)

-- Al iniciar la sesión, pedimos GetOptions para sincronizar volúmenes y escala guardados
task.spawn(function()
	local ok, optRes = pcall(function()
		return remote:InvokeServer("GetOptions")
	end)
	if ok and type(optRes) == "table" then
		for k, v in optRes do options[k] = v end
		applyAudioVolumes()
	end
end)
