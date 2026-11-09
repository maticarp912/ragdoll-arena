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

local BASE_W, BASE_H = 820, 580
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
local binds = InputMap.merge(nil)
local options = {
	MusicVolume = 1,
	SfxVolume = 1,
	CameraShake = 1,
	UiScale = 1,
}
local capturing = nil
local busy = false
local render, setOpen

local function syncOptionsFromAttributes()
	options.MusicVolume = tonumber(player:GetAttribute("OptMusic")) or options.MusicVolume or 1
	options.SfxVolume = tonumber(player:GetAttribute("OptSfx")) or options.SfxVolume or 1
	options.CameraShake = tonumber(player:GetAttribute("OptShake")) or options.CameraShake or 1
	options.UiScale = tonumber(player:GetAttribute("OptUiScale")) or options.UiScale or 1
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
}

function render(messageKey)
	capturing = nil
	syncOptionsFromAttributes()
	for _, v in panel:GetChildren() do
		if v ~= scale and not v:IsA("UIStroke") and not v:IsA("UICorner") and not v:IsA("UIGradient") and v.Name ~= "Ornaments" then
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
			local y = 200 + (idx - 1) * 76
			local rowCard = UiTheme.panel({
				parent = panel,
				position = UDim2.fromOffset(22, y),
				size = UDim2.new(1, -44, 0, 66),
				bg = C.BgCard,
				borderColor = C.BorderSubtle,
			})

			local curVal = options[spec.key] or 1
			local frac = math.clamp((curVal - spec.min) / (spec.max - spec.min), 0, 1)
			local pctText = ("%d%%"):format(math.floor(curVal * 100 + 0.5))

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
		UiTheme.label({
			parent = panel,
			position = UDim2.fromOffset(330, 114),
			size = UDim2.fromOffset(200, 26),
			text = L.t("keyboard"),
			font = "Bold",
			textSize = UiTheme.TextSizes.SM,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
		})
		UiTheme.label({
			parent = panel,
			position = UDim2.fromOffset(550, 114),
			size = UDim2.fromOffset(200, 26),
			text = L.t("gamepad"),
			font = "Bold",
			textSize = UiTheme.TextSizes.SM,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
		})

		local bindsScroll = Instance.new("ScrollingFrame")
		bindsScroll.Position = UDim2.fromOffset(22, 144)
		bindsScroll.Size = UDim2.fromOffset(BASE_W - 44, 340)
		bindsScroll.BackgroundTransparency = 1
		bindsScroll.BorderSizePixel = 0
		bindsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		bindsScroll.CanvasSize = UDim2.new()
		bindsScroll.ScrollBarThickness = 6
		bindsScroll.ScrollBarImageColor3 = C.Gold
		bindsScroll.Parent = panel

		local bLayout = Instance.new("UIListLayout")
		bLayout.Padding = UDim.new(0, 6)
		bLayout.SortOrder = Enum.SortOrder.LayoutOrder
		bLayout.Parent = bindsScroll

		for i, action in InputMap.Actions do
			local row = UiTheme.panel({
				parent = bindsScroll,
				layoutOrder = i,
				size = UDim2.new(1, -10, 0, 42),
				bg = C.BgCard,
				borderColor = C.BorderSubtle,
			})

			UiTheme.label({
				parent = row,
				position = UDim2.fromOffset(14, 0),
				size = UDim2.fromOffset(290, 42),
				text = L.t("action." .. action.id),
				font = "Body",
				textSize = UiTheme.TextSizes.MD,
				color = C.TextPrimary,
			})

			for col, device in { "Keyboard", "Gamepad" } do
				local b = UiTheme.button({
					parent = row,
					position = UDim2.fromOffset(308 + (col - 1) * 220, 3),
					size = UDim2.fromOffset(200, 36),
					text = L.binding(binds[device][action.id]),
					textSize = UiTheme.TextSizes.SM,
					onClick = function()
						if busy then return end
						render()
						capturing = { device = device, action = action.id }
						local prompt = panel:FindFirstChild("Message")
						if prompt and prompt:IsA("TextLabel") then
							prompt.Text = L.t("press")
						end
					end,
				})
				b.Name = "Bind_" .. device .. "_" .. action.id
			end
		end

		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(22, 494),
			size = UDim2.fromOffset(230, 40),
			text = L.t("reset"),
			variant = "secondary",
			onClick = function()
				invoke("ResetBinds", nil, function(value)
					notifyBinds(value)
					render("ui.settings.saved")
				end)
			end,
		})

		UiTheme.label({
			parent = panel,
			position = UDim2.fromOffset(268, 494),
			size = UDim2.fromOffset(520, 40),
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
	if UIS.GamepadEnabled then
		GuiService.SelectedObject = firstTabBtn or closeBtn
	end
end

function setOpen(value)
	capturing = nil
	panel.Visible = value
	veil.Visible = value
	player:SetAttribute("SettingsOpen", value)
	player:SetAttribute("MenuOpen", value or player:GetAttribute("ShopOpen") == true)
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

RunService.Heartbeat:Connect(function()
	local cam = workspace.CurrentCamera
	if cam then
		scale.Scale = UiTheme.computeScale(cam.ViewportSize, BASE_W, BASE_H, player)
	end
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
