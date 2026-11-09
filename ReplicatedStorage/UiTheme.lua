-- ModuleScript: ReplicatedStorage/UiTheme
-- Sistema de diseño de interfaz (Contrato C15, responsable: Gemini, etapa 8).
-- Estética Dark Fantasy comercial: hierro forjado, piedra nocturna, pergamino hueso y oro viejo bruñido.
-- Provee tokens de color, tipografía (FontFace + Enum.Font), escala, espaciado, bordes, curvas de animación
-- y constructores de componentes con estados hover, presionado, seleccionado, deshabilitado y foco de mando.

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage:WaitForChild("Assets", 10))

local UiTheme = {}

----------------------------------------------------------------------
-- 1. Paleta de colores (Dark Fantasy)
----------------------------------------------------------------------
UiTheme.Colors = {
	-- Fondos y superficies
	BgAbyss        = Color3.fromRGB(8, 9, 13),
	BgPrimary      = Color3.fromRGB(14, 15, 21),
	BgPanel        = Color3.fromRGB(20, 22, 30),
	BgPanelLight   = Color3.fromRGB(27, 30, 40),
	BgHeader       = Color3.fromRGB(17, 18, 25),
	BgCard         = Color3.fromRGB(24, 26, 35),
	BgCardHover    = Color3.fromRGB(33, 36, 48),
	BgCardSelected = Color3.fromRGB(39, 35, 28),
	BgCardDisabled = Color3.fromRGB(16, 17, 22),
	BgPreview      = Color3.fromRGB(12, 13, 18),
	BgBarBack      = Color3.fromRGB(11, 12, 16),
	BgModalVeil    = Color3.fromRGB(4, 5, 8),

	-- Hierro y piedra
	IronDark       = Color3.fromRGB(28, 30, 38),
	Iron           = Color3.fromRGB(40, 43, 54),
	IronLight      = Color3.fromRGB(58, 62, 76),
	Stone          = Color3.fromRGB(74, 76, 86),

	-- Oro viejo y acentos reales
	GoldBright     = Color3.fromRGB(242, 212, 138),
	Gold           = Color3.fromRGB(204, 167, 92),
	GoldDim        = Color3.fromRGB(142, 115, 64),
	GoldDark       = Color3.fromRGB(88, 68, 36),

	-- Texto (alto contraste sobre fondos oscuros)
	TextPrimary    = Color3.fromRGB(238, 231, 215), -- Hueso claro / pergamino
	TextSecondary  = Color3.fromRGB(184, 176, 160), -- Hueso medio
	TextMuted      = Color3.fromRGB(126, 120, 110), -- Ceniza
	TextGold       = Color3.fromRGB(224, 188, 110), -- Dorado titular
	TextDark       = Color3.fromRGB(18, 16, 14),    -- Sobre botones dorados

	-- Bordes y foco de mando
	BorderSubtle   = Color3.fromRGB(54, 56, 68),
	BorderDefault  = Color3.fromRGB(124, 102, 60),
	BorderStrong   = Color3.fromRGB(204, 167, 92),
	BorderFocus    = Color3.fromRGB(255, 232, 160), -- Foco brillante para mando/TV

	-- Estados semánticos y monedas
	Success        = Color3.fromRGB(92, 184, 116),
	SuccessDark    = Color3.fromRGB(34, 72, 46),
	Warning        = Color3.fromRGB(230, 168, 64),
	Danger         = Color3.fromRGB(214, 68, 62),
	DangerDark     = Color3.fromRGB(82, 26, 26),
	Disabled       = Color3.fromRGB(78, 78, 86),
	Coins          = Color3.fromRGB(240, 196, 84),
	Robux          = Color3.fromRGB(96, 218, 134),

	-- Barras de combate y equipos
	Health         = Color3.fromRGB(196, 46, 46),
	HealthBright   = Color3.fromRGB(232, 72, 68),
	HealthTrail    = Color3.fromRGB(245, 238, 225),
	Stamina        = Color3.fromRGB(72, 168, 108),
	Guard          = Color3.fromRGB(92, 148, 214),
	GuardBroken    = Color3.fromRGB(110, 110, 120),
	Stun           = Color3.fromRGB(218, 164, 58),
	StunDanger     = Color3.fromRGB(235, 86, 48),
	InfusionCharge = Color3.fromRGB(192, 134, 230),
	TeamRed        = Color3.fromRGB(218, 72, 68),
	TeamBlue       = Color3.fromRGB(76, 146, 230),
}

----------------------------------------------------------------------
-- 2. Rarezas (color + grosor + símbolo + forma para accesibilidad visual)
----------------------------------------------------------------------
UiTheme.Rarities = {
	Common = {
		color = Color3.fromRGB(158, 160, 168),
		bg = Color3.fromRGB(30, 32, 40),
		glow = Color3.fromRGB(110, 114, 124),
		symbol = "•",
		stroke = 1.2,
		doubleBorder = false,
	},
	Rare = {
		color = Color3.fromRGB(78, 156, 235),
		bg = Color3.fromRGB(20, 36, 58),
		glow = Color3.fromRGB(52, 118, 196),
		symbol = "◆",
		stroke = 1.6,
		doubleBorder = false,
	},
	Epic = {
		color = Color3.fromRGB(178, 98, 238),
		bg = Color3.fromRGB(40, 22, 58),
		glow = Color3.fromRGB(138, 64, 198),
		symbol = "❖",
		stroke = 2.0,
		doubleBorder = true,
	},
	Legendary = {
		color = Color3.fromRGB(238, 178, 62),
		bg = Color3.fromRGB(56, 40, 16),
		glow = Color3.fromRGB(204, 142, 36),
		symbol = "✦",
		stroke = 2.4,
		doubleBorder = true,
	},
	Mythic = {
		color = Color3.fromRGB(236, 68, 78),
		bg = Color3.fromRGB(62, 18, 24),
		glow = Color3.fromRGB(198, 38, 48),
		symbol = "★",
		stroke = 2.8,
		doubleBorder = true,
	},
}

----------------------------------------------------------------------
-- 3. Temas por Infusión (para tarjetas altas estilo infusiones ref2.jpg)
----------------------------------------------------------------------
UiTheme.InfusionThemes = {
	Fire = {
		top = Color3.fromRGB(68, 18, 12),
		mid = Color3.fromRGB(128, 36, 16),
		bottom = Color3.fromRGB(26, 10, 10),
		accent = Color3.fromRGB(255, 120, 42),
		glow = Color3.fromRGB(255, 176, 72),
		badge = Color3.fromRGB(92, 26, 16),
	},
	Lightning = {
		top = Color3.fromRGB(18, 34, 68),
		mid = Color3.fromRGB(36, 78, 142),
		bottom = Color3.fromRGB(12, 18, 34),
		accent = Color3.fromRGB(110, 200, 255),
		glow = Color3.fromRGB(210, 242, 255),
		badge = Color3.fromRGB(22, 46, 86),
	},
	Ice = {
		top = Color3.fromRGB(16, 48, 64),
		mid = Color3.fromRGB(42, 108, 136),
		bottom = Color3.fromRGB(10, 24, 34),
		accent = Color3.fromRGB(148, 232, 255),
		glow = Color3.fromRGB(224, 250, 255),
		badge = Color3.fromRGB(20, 58, 76),
	},
	Shadow = {
		top = Color3.fromRGB(36, 16, 54),
		mid = Color3.fromRGB(72, 32, 108),
		bottom = Color3.fromRGB(14, 8, 24),
		accent = Color3.fromRGB(186, 112, 245),
		glow = Color3.fromRGB(226, 178, 255),
		badge = Color3.fromRGB(46, 20, 68),
	},
}

----------------------------------------------------------------------
-- 4. Tipografía (FontFace con Font.new / Font.fromEnum + Enum.Font)
----------------------------------------------------------------------
UiTheme.Fonts = {
	Title  = Enum.Font.Garamond,
	Header = Enum.Font.Antique,
	Body   = Enum.Font.GothamMedium,
	Bold   = Enum.Font.GothamBold,
	Number = Enum.Font.GothamBold,
}

UiTheme.FontFaces = {
	Title  = Font.new("rbxasset://fonts/families/RomanAntique.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Header = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Body   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	Bold   = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Number = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
}

UiTheme.TextSizes = {
	XS   = 11,
	SM   = 13,
	MD   = 15,
	LG   = 18,
	XL   = 22,
	XXL  = 28,
	Hero = 36,
}

----------------------------------------------------------------------
-- 5. Escalas, espaciados, radios, trazos y animaciones (120–250 ms)
----------------------------------------------------------------------
UiTheme.Spacing = {
	XXS = 4,
	XS  = 6,
	SM  = 8,
	MD  = 12,
	LG  = 16,
	XL  = 24,
	XXL = 32,
}

UiTheme.Radius = {
	XS   = 3,
	SM   = 5,
	MD   = 8,
	LG   = 12,
	Pill = 999,
}

UiTheme.Stroke = {
	Thin    = 1,
	Default = 1.5,
	Thick   = 2,
	Heavy   = 2.5,
	Focus   = 2.6,
}

UiTheme.MinHitSize = 44

UiTheme.Anim = {
	Fast       = 0.12,
	Normal     = 0.18,
	Slow       = 0.24,
	TweenFast  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	TweenNorm  = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	TweenSlow  = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	TweenBack  = TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

----------------------------------------------------------------------
-- 6. Utilidades de sonido y escala adaptable
----------------------------------------------------------------------
function UiTheme.playSound(key)
	local id = Assets.sound(key)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	local cfg = Assets.soundSettings(key)
	s.Volume = (cfg and cfg.volume) or 0.5
	local group = SoundService:FindFirstChild("SFX")
	if group and group:IsA("SoundGroup") then
		s.SoundGroup = group
	end
	s.Parent = SoundService
	SoundService:PlayLocalSound(s)
	task.delay(2, function()
		if s.Parent then s:Destroy() end
	end)
end

function UiTheme.computeScale(viewportSize, refWidth, refHeight, player)
	local vw = math.max(320, viewportSize.X)
	local vh = math.max(240, viewportSize.Y)
	local fitW = (vw - 24) / math.max(1, refWidth or 1040)
	local fitH = (vh - 24) / math.max(1, refHeight or 640)
	local base = math.min(1.15, fitW, fitH)
	local opt = (player and player:GetAttribute("OptUiScale")) or 1
	return math.clamp(base * opt, 0.45, 1.35)
end

function UiTheme.applyFont(instance, kind)
	local face = UiTheme.FontFaces[kind or "Body"]
	if face then
		pcall(function() instance.FontFace = face end)
	else
		instance.Font = UiTheme.Fonts[kind or "Body"] or Enum.Font.GothamMedium
	end
end

----------------------------------------------------------------------
-- 7. Decoradores básicos (esquinas, trazos, gradientes, ornamentos)
----------------------------------------------------------------------
function UiTheme.corner(parent, radius)
	local c = parent:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or UiTheme.Radius.SM)
	c.Parent = parent
	return c
end

function UiTheme.stroke(parent, color, thickness, transparency)
	local s = parent:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.Color = color or UiTheme.Colors.Gold
	s.Thickness = thickness or UiTheme.Stroke.Default
	s.Transparency = transparency or 0.15
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UiTheme.gradient(parent, topColor, bottomColor, rotation)
	local g = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Color = ColorSequence.new(topColor, bottomColor)
	g.Rotation = rotation or 90
	g.Parent = parent
	return g
end

function UiTheme.padding(parent, top, right, bottom, left)
	local p = parent:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, top or 8)
	p.PaddingRight = UDim.new(0, right or top or 8)
	p.PaddingBottom = UDim.new(0, bottom or top or 8)
	p.PaddingLeft = UDim.new(0, left or right or top or 8)
	p.Parent = parent
	return p
end

function UiTheme.textConstraint(label, minSize, maxSize)
	local tc = label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
	tc.MinTextSize = minSize or 10
	tc.MaxTextSize = maxSize or 28
	tc.Parent = label
	return tc
end

-- Ornamento sutil de esquinas estilo fantasía oscura (4 escuadras doradas)
function UiTheme.ornamentCorners(parent, color, length, thickness)
	local col = color or UiTheme.Colors.Gold
	local len = length or 10
	local th = thickness or 2
	local folder = parent:FindFirstChild("Ornaments")
	if folder then folder:Destroy() end
	folder = Instance.new("Folder")
	folder.Name = "Ornaments"
	folder.Parent = parent

	local corners = {
		{ Vector2.new(0, 0), UDim2.fromOffset(3, 3), 1, 1 },
		{ Vector2.new(1, 0), UDim2.new(1, -3, 0, 3), -1, 1 },
		{ Vector2.new(0, 1), UDim2.new(0, 3, 1, -3), 1, -1 },
		{ Vector2.new(1, 1), UDim2.new(1, -3, 1, -3), -1, -1 },
	}
	for _, spec in corners do
		local h = Instance.new("Frame")
		h.AnchorPoint = spec[1]
		h.Position = spec[2]
		h.Size = UDim2.fromOffset(len, th)
		h.BackgroundColor3 = col
		h.BackgroundTransparency = 0.25
		h.BorderSizePixel = 0
		h.ZIndex = parent.ZIndex + 2
		h.Parent = folder

		local v = Instance.new("Frame")
		v.AnchorPoint = spec[1]
		v.Position = spec[2]
		v.Size = UDim2.fromOffset(th, len)
		v.BackgroundColor3 = col
		v.BackgroundTransparency = 0.25
		v.BorderSizePixel = 0
		v.ZIndex = parent.ZIndex + 2
		v.Parent = folder
	end
	return folder
end

----------------------------------------------------------------------
-- 8. Foco de mando visible (SelectionGained / SelectionLost)
----------------------------------------------------------------------
function UiTheme.bindGamepadFocus(button, strokeInstance, defaultColor, defaultThickness, defaultTrans)
	local focusRing = Instance.new("Frame")
	focusRing.Name = "FocusRing"
	focusRing.AnchorPoint = Vector2.new(0.5, 0.5)
	focusRing.Position = UDim2.fromScale(0.5, 0.5)
	focusRing.Size = UDim2.new(1, 6, 1, 6)
	focusRing.BackgroundTransparency = 1
	focusRing.Visible = false
	focusRing.ZIndex = button.ZIndex + 5
	focusRing.Parent = button
	UiTheme.corner(focusRing, UiTheme.Radius.MD)
	local ringStroke = UiTheme.stroke(focusRing, UiTheme.Colors.BorderFocus, UiTheme.Stroke.Focus, 0)

	button.SelectionGained:Connect(function()
		focusRing.Visible = true
		if strokeInstance then
			strokeInstance.Color = UiTheme.Colors.BorderFocus
			strokeInstance.Thickness = math.max(UiTheme.Stroke.Focus, (defaultThickness or 1.5) + 0.8)
			strokeInstance.Transparency = 0
		end
		UiTheme.playSound("UI_Hover")
	end)
	button.SelectionLost:Connect(function()
		focusRing.Visible = false
		if strokeInstance then
			strokeInstance.Color = defaultColor or UiTheme.Colors.Gold
			strokeInstance.Thickness = defaultThickness or UiTheme.Stroke.Default
			strokeInstance.Transparency = defaultTrans or 0.2
		end
	end)
	return focusRing, ringStroke
end

----------------------------------------------------------------------
-- 9. Componentes reutilizables
----------------------------------------------------------------------

-- Panel estilizado
function UiTheme.panel(props)
	local className = props.canvasGroup and "CanvasGroup" or "Frame"
	local frame = Instance.new(className)
	frame.Name = props.name or "Panel"
	frame.AnchorPoint = props.anchor or Vector2.zero
	frame.Position = props.position or UDim2.new()
	frame.Size = props.size or UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = props.bg or UiTheme.Colors.BgPanel
	frame.BackgroundTransparency = props.transparency or 0
	frame.BorderSizePixel = 0
	if props.zIndex then frame.ZIndex = props.zIndex end
	if props.layoutOrder then frame.LayoutOrder = props.layoutOrder end
	if props.visible ~= nil then frame.Visible = props.visible end
	frame.Parent = props.parent

	UiTheme.corner(frame, props.radius or UiTheme.Radius.MD)
	local stroke = UiTheme.stroke(frame, props.borderColor or UiTheme.Colors.Gold, props.borderThickness or UiTheme.Stroke.Default, props.borderTrans or 0.18)
	if props.gradient ~= false then
		UiTheme.gradient(frame, props.topColor or Color3.fromRGB(255, 255, 255), props.bottomColor or Color3.fromRGB(195, 190, 180), 90)
	end
	if props.ornaments then
		UiTheme.ornamentCorners(frame, props.borderColor or UiTheme.Colors.Gold, props.ornamentSize or 12, 2)
	end
	return frame, stroke
end

-- Etiqueta de texto con tipografía del sistema
function UiTheme.label(props)
	local lbl = Instance.new("TextLabel")
	lbl.Name = props.name or "Label"
	lbl.AnchorPoint = props.anchor or Vector2.zero
	lbl.Position = props.position or UDim2.new()
	lbl.Size = props.size or UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = props.text or ""
	lbl.TextColor3 = props.color or UiTheme.Colors.TextPrimary
	lbl.TextSize = props.textSize or UiTheme.TextSizes.MD
	lbl.TextWrapped = props.wrapped ~= false
	lbl.TextScaled = props.scaled == true
	lbl.TextXAlignment = props.alignX or Enum.TextXAlignment.Left
	lbl.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
	lbl.TextStrokeTransparency = props.strokeTrans or 0.55
	lbl.RichText = props.richText == true
	if props.truncate then lbl.TextTruncate = props.truncate end
	if props.zIndex then lbl.ZIndex = props.zIndex end
	if props.layoutOrder then lbl.LayoutOrder = props.layoutOrder end
	if props.autoSize then lbl.AutomaticSize = props.autoSize end
	UiTheme.applyFont(lbl, props.font or "Body")
	if props.scaled or props.maxTextSize then
		UiTheme.textConstraint(lbl, props.minTextSize or 10, props.maxTextSize or props.textSize or 28)
	end
	lbl.Parent = props.parent
	return lbl
end

-- Botón primario / secundario / dorado / peligro (con área táctil >= 44 px y foco de mando)
function UiTheme.button(props)
	local variant = props.variant or "secondary"
	local disabled = props.disabled == true
	local selected = props.selected == true

	local bgBase, bgHover, bgPress, borderCol, textCol
	if disabled then
		bgBase = UiTheme.Colors.BgCardDisabled
		bgHover = UiTheme.Colors.BgCardDisabled
		bgPress = UiTheme.Colors.BgCardDisabled
		borderCol = UiTheme.Colors.Disabled
		textCol = UiTheme.Colors.TextMuted
	elseif variant == "primary" or variant == "gold" then
		bgBase = Color3.fromRGB(168, 132, 62)
		bgHover = Color3.fromRGB(198, 158, 78)
		bgPress = Color3.fromRGB(138, 106, 48)
		borderCol = UiTheme.Colors.GoldBright
		textCol = UiTheme.Colors.TextPrimary
	elseif variant == "success" then
		bgBase = UiTheme.Colors.SuccessDark
		bgHover = Color3.fromRGB(46, 96, 62)
		bgPress = Color3.fromRGB(28, 58, 38)
		borderCol = UiTheme.Colors.Success
		textCol = UiTheme.Colors.TextPrimary
	elseif variant == "danger" then
		bgBase = UiTheme.Colors.DangerDark
		bgHover = Color3.fromRGB(112, 36, 36)
		bgPress = Color3.fromRGB(64, 20, 20)
		borderCol = UiTheme.Colors.Danger
		textCol = UiTheme.Colors.TextPrimary
	elseif selected then
		bgBase = UiTheme.Colors.BgCardSelected
		bgHover = Color3.fromRGB(52, 46, 36)
		bgPress = Color3.fromRGB(32, 28, 22)
		borderCol = UiTheme.Colors.GoldBright
		textCol = UiTheme.Colors.GoldBright
	else
		bgBase = UiTheme.Colors.IronDark
		bgHover = UiTheme.Colors.Iron
		bgPress = UiTheme.Colors.BgPrimary
		borderCol = UiTheme.Colors.BorderDefault
		textCol = UiTheme.Colors.TextPrimary
	end

	local btn = Instance.new("TextButton")
	btn.Name = props.name or "Button"
	btn.AnchorPoint = props.anchor or Vector2.zero
	btn.Position = props.position or UDim2.new()
	btn.Size = props.size or UDim2.fromOffset(140, UiTheme.MinHitSize)
	if props.autoSize then btn.AutomaticSize = props.autoSize end
	btn.BackgroundColor3 = bgBase
	btn.BackgroundTransparency = props.transparency or 0.04
	btn.AutoButtonColor = false
	btn.Text = props.icon and "" or (props.text or "")
	btn.TextColor3 = props.textColor or textCol
	btn.TextSize = props.textSize or UiTheme.TextSizes.MD
	btn.TextStrokeTransparency = 0.55
	btn.BorderSizePixel = 0
	btn.Active = not disabled
	btn.Selectable = not disabled and (props.selectable ~= false)
	if props.zIndex then btn.ZIndex = props.zIndex end
	if props.layoutOrder then btn.LayoutOrder = props.layoutOrder end
	UiTheme.applyFont(btn, props.font or "Bold")
	btn.Parent = props.parent

	if props.icon then
		local iSize = props.iconSize or 20
		local iOffset = props.iconOffset or 10
		local iconHolder = Instance.new("Frame")
		iconHolder.Name = "IconHolder"
		iconHolder.Size = UDim2.fromOffset(iSize, iSize)
		iconHolder.AnchorPoint = Vector2.new(0, 0.5)
		iconHolder.Position = UDim2.new(0, iOffset, 0.5, 0)
		iconHolder.BackgroundTransparency = 1
		iconHolder.BorderSizePixel = 0
		iconHolder.Parent = btn

		local uiAssetsMod = ReplicatedStorage:FindFirstChild("UiAssets")
		if uiAssetsMod then
			local ok, UA = pcall(require, uiAssetsMod)
			if ok and UA and UA.icon then
				local ic = UA.icon(iconHolder, props.icon, iSize, props.iconColor or UiTheme.Colors.GoldBright)
				ic.AnchorPoint = Vector2.new(0.5, 0.5)
				ic.Position = UDim2.fromScale(0.5, 0.5)
			end
		end

		local textLeft = iOffset + iSize + (props.iconSpacing or 8)
		local lbl = UiTheme.label({
			name = "BtnText",
			parent = btn,
			position = UDim2.fromOffset(textLeft, 0),
			size = UDim2.new(1, -(textLeft + 8), 1, 0),
			text = props.text or "",
			font = props.font or "Bold",
			textSize = props.textSize or UiTheme.TextSizes.MD,
			color = props.textColor or textCol,
			alignX = props.alignX or Enum.TextXAlignment.Left,
		})

		btn:GetPropertyChangedSignal("Text"):Connect(function()
			if btn.Text ~= "" then
				lbl.Text = btn.Text
				btn.Text = ""
			end
		end)
	end

	if props.paddingX then
		UiTheme.padding(btn, 0, props.paddingX, 0, props.paddingX)
	end

	UiTheme.corner(btn, props.radius or UiTheme.Radius.SM)
	local strokeThick = selected and UiTheme.Stroke.Thick or (props.borderThickness or UiTheme.Stroke.Default)
	local strokeTrans = selected and 0 or (disabled and 0.55 or 0.2)
	local stroke = UiTheme.stroke(btn, borderCol, strokeThick, strokeTrans)

	UiTheme.bindGamepadFocus(btn, stroke, borderCol, strokeThick, strokeTrans)

	if not disabled then
		btn.MouseEnter:Connect(function()
			UiTheme.playSound("UI_Hover")
			TweenService:Create(btn, UiTheme.Anim.TweenFast, { BackgroundColor3 = bgHover }):Play()
			TweenService:Create(stroke, UiTheme.Anim.TweenFast, { Transparency = 0 }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, UiTheme.Anim.TweenFast, { BackgroundColor3 = bgBase }):Play()
			TweenService:Create(stroke, UiTheme.Anim.TweenFast, { Transparency = strokeTrans }):Play()
		end)
		btn.MouseButton1Down:Connect(function()
			TweenService:Create(btn, UiTheme.Anim.TweenFast, { BackgroundColor3 = bgPress }):Play()
		end)
		btn.MouseButton1Up:Connect(function()
			TweenService:Create(btn, UiTheme.Anim.TweenFast, { BackgroundColor3 = bgHover }):Play()
		end)
		if props.onClick then
			btn.Activated:Connect(function()
				UiTheme.playSound(props.sound or "UI_Click")
				props.onClick()
			end)
		end
	end

	return btn, stroke
end

-- Pestaña de navegación con barra activa dorada inferior
function UiTheme.tabButton(props)
	local active = props.active == true
	local btn, stroke = UiTheme.button({
		name = props.name or "Tab",
		parent = props.parent,
		position = props.position,
		size = props.size or UDim2.fromOffset(130, 44),
		layoutOrder = props.layoutOrder,
		text = props.text or "",
		font = "Header",
		textSize = props.textSize or UiTheme.TextSizes.LG,
		selected = active,
		sound = "UI_TabSwitch",
		onClick = props.onClick,
	})

	local bar = Instance.new("Frame")
	bar.Name = "ActiveBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -2)
	bar.Size = UDim2.new(active and 0.76 or 0, 0, 0, 3)
	bar.BackgroundColor3 = UiTheme.Colors.GoldBright
	bar.BorderSizePixel = 0
	bar.Parent = btn
	UiTheme.corner(bar, 2)

	if props.badgeText and props.badgeText ~= "" then
		local badge = Instance.new("TextLabel")
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, -4, 0, 3)
		badge.Size = UDim2.fromOffset(0, 15)
		badge.AutomaticSize = Enum.AutomaticSize.X
		badge.BackgroundColor3 = UiTheme.Colors.GoldDark
		badge.TextColor3 = UiTheme.Colors.GoldBright
		badge.TextSize = 10
		badge.Text = " " .. props.badgeText .. " "
		UiTheme.applyFont(badge, "Bold")
		badge.Parent = btn
		UiTheme.corner(badge, 4)
	end

	return btn, stroke
end

-- Insignia de rareza (se distingue por símbolo, forma/borde, fondo y etiqueta de texto)
function UiTheme.rarityBadge(parent, rarityId, labelText, position, anchor)
	local spec = UiTheme.Rarities[rarityId or "Common"] or UiTheme.Rarities.Common
	local badge = Instance.new("Frame")
	badge.Name = "RarityBadge"
	badge.AnchorPoint = anchor or Vector2.zero
	badge.Position = position or UDim2.new()
	badge.Size = UDim2.fromOffset(0, 22)
	badge.AutomaticSize = Enum.AutomaticSize.X
	badge.BackgroundColor3 = spec.bg
	badge.BorderSizePixel = 0
	badge.Parent = parent

	UiTheme.corner(badge, spec.doubleBorder and UiTheme.Radius.XS or UiTheme.Radius.Pill)
	UiTheme.stroke(badge, spec.color, spec.stroke, 0.1)
	UiTheme.padding(badge, 0, 8, 0, 8)

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromOffset(0, 22)
	txt.AutomaticSize = Enum.AutomaticSize.X
	txt.BackgroundTransparency = 1
	txt.TextColor3 = spec.color
	txt.TextSize = UiTheme.TextSizes.XS
	txt.Text = spec.symbol .. " " .. string.upper(labelText or rarityId or "")
	UiTheme.applyFont(txt, "Bold")
	txt.Parent = badge

	return badge
end

-- Barra de progreso con rastro de impacto opcional y etiqueta
function UiTheme.progressBar(props)
	local bg = Instance.new("Frame")
	bg.Name = props.name or "ProgressBar"
	bg.AnchorPoint = props.anchor or Vector2.zero
	bg.Position = props.position or UDim2.new()
	bg.Size = props.size or UDim2.new(1, 0, 0, 12)
	bg.BackgroundColor3 = props.bgColor or UiTheme.Colors.BgBarBack
	bg.BorderSizePixel = 0
	if props.zIndex then bg.ZIndex = props.zIndex end
	bg.Parent = props.parent

	UiTheme.corner(bg, props.radius or UiTheme.Radius.XS)
	UiTheme.stroke(bg, props.borderColor or UiTheme.Colors.Gold, 1, 0.45)

	local trail = nil
	if props.withTrail then
		trail = Instance.new("Frame")
		trail.Name = "Trail"
		trail.Size = UDim2.fromScale(props.fraction or 1, 1)
		trail.BackgroundColor3 = props.trailColor or UiTheme.Colors.HealthTrail
		trail.BorderSizePixel = 0
		trail.ZIndex = bg.ZIndex + 1
		trail.Parent = bg
		UiTheme.corner(trail, props.radius or UiTheme.Radius.XS)
	end

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(math.clamp(props.fraction or 1, 0, 1), 1)
	fill.BackgroundColor3 = props.fillColor or UiTheme.Colors.Gold
	fill.BorderSizePixel = 0
	fill.ZIndex = bg.ZIndex + 2
	fill.Parent = bg
	UiTheme.corner(fill, props.radius or UiTheme.Radius.XS)
	UiTheme.gradient(fill, Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 190), 90)

	local valueLabel = nil
	if props.showText then
		valueLabel = UiTheme.label({
			name = "Value",
			parent = bg,
			size = UDim2.fromScale(1, 1),
			text = props.text or "",
			font = "Number",
			textSize = props.textSize or UiTheme.TextSizes.XS,
			alignX = Enum.TextXAlignment.Center,
			zIndex = bg.ZIndex + 3,
		})
	end

	return bg, fill, trail, valueLabel
end

-- Encerrar el foco del mando dentro de una lista de botones (por ejemplo, en un diálogo modal)
function UiTheme.trapGamepadFocus(groupName, buttons)
	pcall(function()
		GuiService:RemoveSelectionGroup(groupName)
		GuiService:AddSelectionTuple(groupName, table.unpack(buttons))
	end)
	local count = #buttons
	for i, b in buttons do
		local prevBtn = buttons[((i - 2) % count) + 1]
		local nextBtn = buttons[(i % count) + 1]
		b.NextSelectionLeft = prevBtn
		b.NextSelectionUp = prevBtn
		b.NextSelectionRight = nextBtn
		b.NextSelectionDown = nextBtn
	end
end

function UiTheme.releaseGamepadFocus(groupName)
	pcall(function()
		GuiService:RemoveSelectionGroup(groupName)
	end)
end

return UiTheme
