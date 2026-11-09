-- LocalScript: StarterPlayer/StarterPlayerScripts/HUD
-- HUD de combate y estado de partida rediseñado (Fase 3, responsable: Gemini, etapa 8).
-- Conserva todos los contratos y lecturas (C2 StatusKey/StatusParams, C5 barras de Vida, Stamina,
-- Guardia, Stun e Infusión con icono que late, retratos de esquina y música) y añade el KillFeed (C9),
-- zonas seguras (GuiService:GetGuiInset) y escala de interfaz (OptUiScale, C10).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme", 10))
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme", 10))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets", 10))
local L = require(ReplicatedStorage:WaitForChild("Localization", 10))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig", 10))
local Infusions = require(ReplicatedStorage:WaitForChild("Infusions", 10))
local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig", 10))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData", 10))
local Assets = require(ReplicatedStorage:WaitForChild("Assets", 10))

local player = Players.LocalPlayer
local C = UiTheme.Colors
local H = Polish.HUD

local gui = Instance.new("ScreenGui")
gui.Name = "MatchHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 4
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

----------------------------------------------------------------------
-- 1. Estado de la partida (arriba, centrado) — Contrato C2 intacto
----------------------------------------------------------------------
local statusBanner = UiTheme.panel({
	name = "StatusBanner",
	parent = gui,
	anchor = Vector2.new(0.5, 0),
	position = UDim2.new(0.5, 0, 0, 10),
	size = UDim2.fromOffset(480, 40),
	bg = C.BgPanel,
	transparency = 0.12,
	borderColor = C.Gold,
	ornaments = true,
	ornamentSize = 8,
})
local statusScale = Instance.new("UIScale")
statusScale.Parent = statusBanner

local statusLabel = UiTheme.label({
	name = "StatusText",
	parent = statusBanner,
	position = UDim2.fromOffset(14, 2),
	size = UDim2.new(1, -28, 1, -4),
	text = "",
	font = "Title",
	textSize = UiTheme.TextSizes.LG,
	maxTextSize = 22,
	minTextSize = 11,
	scaled = true,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Center,
})

-- Contrato C2 (etapa 8): el servidor escribe StatusParams (JSON) y luego StatusKey (clave de idioma).
-- Los parámetros terminados en "Key" se traducen: { teamKey = "team.Red" } rellena {team}.
-- Si StatusKey está vacío se muestra Status tal cual (texto antiguo).
local function updateStatus()
	local key = workspace:GetAttribute("StatusKey")
	if type(key) == "string" and key ~= "" then
		local ok, params = pcall(HttpService.JSONDecode, HttpService, workspace:GetAttribute("StatusParams") or "{}")
		statusLabel.Text = L.t(key, ok and type(params) == "table" and params or nil)
	else
		statusLabel.Text = L.format(workspace:GetAttribute("Status"))
	end
	statusBanner.Visible = statusLabel.Text ~= ""
end

for _, name in { "Status", "StatusKey", "StatusParams" } do
	workspace:GetAttributeChangedSignal(name):Connect(updateStatus)
end
L.Changed:Connect(updateStatus)
updateStatus()

----------------------------------------------------------------------
-- 2. Panel de barras propias (abajo centrado, inspirado en 07_postura_combate_y_hud.webp)
--    Deja libre la izquierda (joystick móvil) y la derecha (botones táctiles).
----------------------------------------------------------------------
local holder = UiTheme.panel({
	name = "PlayerBars",
	parent = gui,
	anchor = Vector2.new(1, 1),
	position = UDim2.new(1, -20, 1, -20),
	size = UDim2.fromOffset(204, 184),
	bg = C.BgPanel,
	transparency = 0.14,
	borderColor = C.Gold,
	ornaments = true,
	ornamentSize = 10,
	canvasGroup = true,
})
local holderScale = Instance.new("UIScale")
holderScale.Parent = holder

UiTheme.padding(holder, 8, 10, 8, 10)

-- Cabecera: icono y nombre del arma a la izquierda, puntos de vida a la derecha
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 22)
header.BackgroundTransparency = 1
header.Parent = holder

local weaponIcon = UiAssets.icon(header, "attack", 16, C.GoldBright)
weaponIcon.AnchorPoint = Vector2.new(0, 0.5)
weaponIcon.Position = UDim2.new(0, 0, 0.5, 0)

local weaponLabel = UiTheme.label({
	name = "WeaponName",
	parent = header,
	position = UDim2.fromOffset(20, 0),
	size = UDim2.new(0.55, -20, 1, 0),
	text = "",
	font = "Title",
	textSize = UiTheme.TextSizes.MD,
	color = C.GoldBright,
	alignX = Enum.TextXAlignment.Left,
	truncate = Enum.TextTruncate.AtEnd,
})

local hpNumber = UiTheme.label({
	name = "HpNumbers",
	parent = header,
	anchor = Vector2.new(1, 0),
	position = UDim2.fromScale(1, 0),
	size = UDim2.fromScale(0.45, 1),
	text = "",
	font = "Number",
	textSize = UiTheme.TextSizes.XS,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Right,
})

-- Contenedor de las 5 columnas verticales lado a lado (Punto 7: barras verticales una al lado de la otra)
local columnsContainer = Instance.new("Frame")
columnsContainer.Name = "Columns"
columnsContainer.Position = UDim2.fromOffset(0, 26)
columnsContainer.Size = UDim2.new(1, 0, 1, -26)
columnsContainer.BackgroundTransparency = 1
columnsContainer.Parent = holder

local colLayout = Instance.new("UIListLayout")
colLayout.FillDirection = Enum.FillDirection.Horizontal
colLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
colLayout.VerticalAlignment = Enum.VerticalAlignment.Center
colLayout.Padding = UDim.new(0, 6)
colLayout.SortOrder = Enum.SortOrder.LayoutOrder
colLayout.Parent = columnsContainer

local icons = {}
local rowLabels = {}

local function barColumn(order, name, colWidth, colHeight, color, withTrail)
	local col = Instance.new("Frame")
	col.Name = "Col_" .. name
	col.LayoutOrder = order
	col.Size = UDim2.fromOffset(colWidth, colHeight)
	col.BackgroundTransparency = 1
	col.Parent = columnsContainer

	local iconRoot, iconUpdate = UiAssets.icon(col, name == "infusion" and "Fire" or name, 18, color)
	iconRoot.AnchorPoint = Vector2.new(0.5, 0)
	iconRoot.Position = UDim2.new(0.5, 0, 0, 0)
	icons[name] = { root = iconRoot, update = iconUpdate, row = col, size = 18 }

	local barH = colHeight - 40
	local bg = Instance.new("Frame")
	bg.Name = "BarBg_" .. name
	bg.AnchorPoint = Vector2.new(0.5, 0)
	bg.Position = UDim2.new(0.5, 0, 0, 22)
	bg.Size = UDim2.new(1, 0, 0, barH)
	bg.BackgroundColor3 = C.BgBarBack
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Parent = col
	UiTheme.corner(bg, UiTheme.Radius.SM)
	UiTheme.stroke(bg, C.BorderSubtle, 1, 0.4)

	local trail = nil
	if withTrail then
		trail = Instance.new("Frame")
		trail.Name = "Trail"
		trail.AnchorPoint = Vector2.new(0, 1)
		trail.Position = UDim2.fromScale(0, 1)
		trail.Size = UDim2.fromScale(1, 1)
		trail.BackgroundColor3 = C.HealthTrail
		trail.BorderSizePixel = 0
		trail.Parent = bg
		UiTheme.corner(trail, UiTheme.Radius.SM)
	end

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = bg
	UiTheme.corner(fill, UiTheme.Radius.SM)

	local valLbl = UiTheme.label({
		name = "ValLabel",
		parent = col,
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, 0),
		size = UDim2.new(1, 6, 0, 16),
		text = "",
		font = "Number",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
		alignX = Enum.TextXAlignment.Center,
		scaled = true,
	})
	rowLabels[name] = valLbl

	return fill, bg, valLbl, trail
end

local BAR_COL_H = 138
local hpFill, hpBg, _, hpTrail = barColumn(1, "health", 36, BAR_COL_H, C.Health, true)
local damageTween = nil
local damageVersion = 0

local stamFill, stamBg, stamNumber = barColumn(2, "stamina", 30, BAR_COL_H, C.Stamina, false)
local guardFill = barColumn(3, "guard", 26, BAR_COL_H, C.Guard, false)
local stunFill = barColumn(4, "stun", 26, BAR_COL_H, C.Stun, false)
local infFill, infBg, infState = barColumn(5, "infusion", 36, BAR_COL_H, C.InfusionCharge, false)
local infText = infState

----------------------------------------------------------------------
-- 3. Retratos de esquina (propio a la izquierda, rivales a la derecha)
----------------------------------------------------------------------
local function portraitPanel(right, slot)
	local frame = Instance.new("Frame")
	frame.Name = right and ("RivalPortrait_" .. slot) or "OwnPortrait"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	frame.Position = UDim2.new(right and (1 - H.Side) or H.Side, 0, H.Top, (slot - 1) * H.EnemyStep)
	frame.Size = UDim2.new(H.Width, 0, 0, H.Height)
	frame.Parent = gui

	local diamond = Instance.new("Frame")
	diamond.Size = UDim2.fromOffset(H.Portrait, H.Portrait)
	diamond.Position = UDim2.new(right and 1 or 0, right and -H.Portrait or 0, 0, H.Portrait / 2)
	diamond.AnchorPoint = Vector2.new(0, 0.5)
	diamond.Rotation = H.PortraitAngle
	diamond.BackgroundColor3 = C.BgPanel
	diamond.BorderSizePixel = 0
	diamond.Parent = frame
	UiTheme.stroke(diamond, C.Gold, 1.8, 0.1)

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Rotation = -H.PortraitAngle
	image.Parent = diamond
	UiTheme.corner(image, H.Portrait)

	local name = UiTheme.label({
		parent = frame,
		position = UDim2.fromOffset(right and 0 or (H.Portrait + H.NameHeight), 0),
		size = UDim2.new(1, -H.Portrait - H.NameHeight, 0, H.NameHeight),
		text = "",
		font = "Header",
		textSize = H.NameSize,
		color = C.TextPrimary,
		alignX = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
		truncate = Enum.TextTruncate.AtEnd,
	})
	return frame, image, name
end

local ownFrame, ownImage, ownName = portraitPanel(false, 1)
ownName.Text = player.DisplayName

local function thumbnail(p, image)
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and image.Parent then
			image.Image = url
		end
	end)
end
thumbnail(player, ownImage)

local rivals = {}
for slot = 1, H.Opponents do
	local frame, image, name = portraitPanel(true, slot)
	local back, fill, trail = UiTheme.progressBar({
		parent = frame,
		position = UDim2.fromOffset(0, H.BarTop),
		size = UDim2.new(1, -H.Portrait - H.NameHeight, 0, H.BarHeight),
		fillColor = C.Health,
		withTrail = true,
	})
	back.Rotation = -H.BarAngle
	rivals[slot] = { frame = frame, image = image, name = name, fill = fill, trail = trail, hp = 1, hitAt = 0 }
end

----------------------------------------------------------------------
-- 4. KillFeed arriba a la derecha (Contrato C9: Remotes.KillFeed)
----------------------------------------------------------------------
local killFeedContainer = Instance.new("Frame")
killFeedContainer.Name = "KillFeed"
killFeedContainer.AnchorPoint = Vector2.new(1, 0)
killFeedContainer.Position = UDim2.new(1, -18, 0, 236)
killFeedContainer.Size = UDim2.fromOffset(310, 180)
killFeedContainer.BackgroundTransparency = 1
killFeedContainer.Parent = gui
local killFeedScale = Instance.new("UIScale")
killFeedScale.Parent = killFeedContainer

local feedLayout = Instance.new("UIListLayout")
feedLayout.FillDirection = Enum.FillDirection.Vertical
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
feedLayout.Padding = UDim.new(0, 6)
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Parent = killFeedContainer

local feedOrder = 0
local function pushKillFeed(entry)
	if type(entry) ~= "table" then return end
	feedOrder += 1
	local isKill = entry.kind == "Kill"
	local killer = entry.killer
	local victim = entry.victim or "?"

	local msgText
	if isKill then
		msgText = (killer and killer ~= "") and L.t("ui.killfeed.kill", { killer = killer, victim = victim })
			or L.t("ui.killfeed.killSelf", { victim = victim })
	else
		msgText = (killer and killer ~= "") and L.t("ui.killfeed.knockdown", { killer = killer, victim = victim })
			or L.t("ui.killfeed.knockdownSelf", { victim = victim })
	end

	local borderCol = isKill and C.Danger or C.Warning
	if entry.killerTeam == "Red" then borderCol = C.TeamRed
	elseif entry.killerTeam == "Blue" then borderCol = C.TeamBlue end

	local item = UiTheme.panel({
		name = "FeedEntry",
		parent = killFeedContainer,
		canvasGroup = true,
		layoutOrder = feedOrder,
		size = UDim2.fromOffset(300, 34),
		bg = C.BgPanel,
		transparency = 0.1,
		borderColor = borderCol,
		radius = UiTheme.Radius.SM,
	})
	item.GroupTransparency = 1

	local ic = UiAssets.icon(item, isKill and "skull" or "knockdown", 20, isKill and C.Danger or C.Warning)
	ic.AnchorPoint = Vector2.new(0, 0.5)
	ic.Position = UDim2.new(0, 8, 0.5, 0)

	UiTheme.label({
		parent = item,
		position = UDim2.fromOffset(34, 0),
		size = UDim2.new(1, -42, 1, 0),
		text = msgText,
		font = "Bold",
		textSize = UiTheme.TextSizes.SM,
		color = C.TextPrimary,
		truncate = Enum.TextTruncate.AtEnd,
	})

	TweenService:Create(item, UiTheme.Anim.TweenFast, { GroupTransparency = 0 }):Play()
	task.delay(4.5, function()
		if item.Parent then
			local tw = TweenService:Create(item, UiTheme.Anim.TweenSlow, { GroupTransparency = 1 })
			tw:Play()
			task.delay(0.28, function()
				if item.Parent then item:Destroy() end
			end)
		end
	end)
end

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
	local feedRemote = remotes and remotes:WaitForChild("KillFeed", 15)
	if feedRemote and feedRemote:IsA("RemoteEvent") then
		feedRemote.OnClientEvent:Connect(pushKillFeed)
	end
end)

----------------------------------------------------------------------
-- 5. Disposición adaptable, zonas seguras y escala (OptUiScale)
----------------------------------------------------------------------
holder.Visible = false
holder.GroupTransparency = 1
local lastCombatTime = -math.huge
local function noteCombat()
	lastCombatTime = os.clock()
end

local function updateLayout()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local insetTopLeft = GuiService:GetGuiInset()
	local safeTop = math.max(8, insetTopLeft.Y + 4)

	local opt = player:GetAttribute("OptUiScale") or 1
	local baseScale = math.min(1, vp.Y / 720, math.max(0.55, vp.X / 1050)) * opt

	holderScale.Scale = baseScale
	statusScale.Scale = baseScale
	killFeedScale.Scale = baseScale
	for _, f in { ownFrame, rivals[1].frame, rivals[H.Opponents].frame } do
		local sc = f:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		sc.Scale = baseScale
		sc.Parent = f
	end

	local inMatch = player:GetAttribute("InMatch") == true
	ownFrame.Visible = inMatch
	statusBanner.Position = UDim2.new(0.5, 0, 0, safeTop)

	-- Punto 7: En escritorio abajo a la derecha; en táctil móvil abajo a la izquierda para no tapar botones
	local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if isTouch then
		holder.AnchorPoint = Vector2.new(0, 1)
		holder.Position = UDim2.new(0, 16, 1, -20)
	else
		holder.AnchorPoint = Vector2.new(1, 1)
		holder.Position = UDim2.new(1, -20, 1, -20)
	end
end

player:GetAttributeChangedSignal("InMatch"):Connect(updateLayout)
player:GetAttributeChangedSignal("OptUiScale"):Connect(updateLayout)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateLayout)
updateLayout()

----------------------------------------------------------------------
-- 6. Actualización de rivales e infusión en tiempo real
----------------------------------------------------------------------
local lastVp = Vector2.zero
RunService.Heartbeat:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize ~= lastVp then
		lastVp = cam.ViewportSize
		updateLayout()
	end

	-- Visibilidad del HUD según combate (Punto 7: InMatch o combate en el patio de práctica)
	local inMatch = player:GetAttribute("InMatch") == true
	-- 9/11 (Claude): con un objetivo fijado (Controls: player.LockTarget) también se muestra el HUD completo
	local lockTarget = player:FindFirstChild("LockTarget")
	local locking = lockTarget ~= nil and lockTarget.Value ~= nil
	local inCombat = inMatch or locking or (os.clock() - lastCombatTime < 8)
	local targetAlpha = inCombat and 0 or 1
	if holder.GroupTransparency ~= targetAlpha then
		local cur = holder.GroupTransparency
		local step = (targetAlpha - cur) * math.min(1, dt * 8)
		if math.abs(targetAlpha - cur) < 0.03 then
			holder.GroupTransparency = targetAlpha
		else
			holder.GroupTransparency = cur + step
		end
	end
	holder.Visible = holder.GroupTransparency < 0.99

	local enemies = {}
	if player:GetAttribute("InMatch") and player.Team then
		for _, other in Players:GetPlayers() do
			if other ~= player and other:GetAttribute("InMatch") and other.Team and other.Team ~= player.Team then
				table.insert(enemies, other)
			end
		end
	end
	table.sort(enemies, function(a, b) return a.UserId < b.UserId end)

	for slot, view in rivals do
		local other = enemies[slot]
		local char = other and other.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		view.frame.Visible = hum ~= nil
		if hum then
			if view.player ~= other then
				view.player = other
				thumbnail(other, view.image)
				view.hp = 1
				view.trail.Size = UDim2.fromScale(1, 1)
			end
			view.name.Text = other.DisplayName
			local fraction = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
			local now = workspace:GetServerTimeNow()
			if fraction < view.hp then view.hitAt = now end
			view.hp = fraction
			view.fill.Size = UDim2.fromScale(fraction, 1)
			if fraction >= view.trail.Size.X.Scale then
				view.trail.Size = view.fill.Size
			elseif now - view.hitAt >= H.DamageDelay then
				local step = math.min(1, (now - view.hitAt - H.DamageDelay) / H.DamageTime)
				view.trail.Size = UDim2.fromScale(view.trail.Size.X.Scale + (fraction - view.trail.Size.X.Scale) * step, 1)
			end
		end
	end

	-- Barra e icono reversionado de infusión (late activa o llena; se ladea agotada)
	local char = player.Character
	local infusionId = (char and char:GetAttribute("InfusionId")) or player:GetAttribute("InfusionId") or "Fire"
	local def = Infusions.get(infusionId)
	if not char or not def then return end

	local now = workspace:GetServerTimeNow()
	infFill.BackgroundColor3 = def.color
	infText.Text = L.t("infusion." .. infusionId)

	if icons.infusion.id ~= infusionId then
		icons.infusion.root:Destroy()
		icons.infusion.root, icons.infusion.update = UiAssets.icon(icons.infusion.row, infusionId, 22, def.color)
		icons.infusion.id = infusionId
	end

	if char:GetAttribute("InfusionActive") then
		infState.Text = L.t("active", { seconds = math.max(0, math.ceil((char:GetAttribute("InfusionEndsAt") or now) - now)) })
	elseif (char:GetAttribute("InfusionLockUntil") or 0) > now then
		infState.Text = L.t("exhausted", { seconds = math.ceil(char:GetAttribute("InfusionLockUntil") - now) })
	else
		infState.Text = L.t("charge", { amount = math.floor(char:GetAttribute("InfusionCharge") or 0) })
	end

	weaponLabel.Text = L.t("weapon." .. (char:GetAttribute("WeaponId") or player:GetAttribute("WeaponId") or "Sword"))

	local IA = H.InfusionIcon
	local full = (char:GetAttribute("InfusionCharge") or 0) >= CombatConfig.InfusionCharge.Max
	local active = char:GetAttribute("InfusionActive") == true
	local exhausted = (char:GetAttribute("InfusionLockUntil") or 0) > now
	icons.infusion.update(1, exhausted)

	local root = icons.infusion.root
	local basePx = 22
	local pulse = (active and IA.ActiveAmp or (full and IA.FullAmp or 0)) * math.sin(os.clock() * (active and IA.ActiveSpeed or IA.FullSpeed))
	local px = math.floor(basePx * (1 + pulse))
	root.Size = UDim2.fromOffset(px, px)
	root.Position = UDim2.fromOffset((basePx - px) / 2, 3 + (basePx - px) / 2)
	root.Rotation = exhausted and IA.ExhaustTilt or (active and pulse * IA.ActiveWobble or 0)
end)

----------------------------------------------------------------------
-- 7. Conexión de atributos del personaje local (Contrato C5)
----------------------------------------------------------------------
local function setFill(fill, frac)
	fill.Size = UDim2.fromScale(1, math.clamp(frac or 0, 0, 1))
end

local conns = {}
local function hook(char)
	for _, c in conns do c:Disconnect() end
	table.clear(conns)
	damageVersion += 1
	if damageTween then damageTween:Cancel() end
	hpTrail.Size = UDim2.fromScale(1, 1)

	lastCombatTime = -math.huge
 local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	local previousHealth = hum.Health
 local function on(signal, fn)
		table.insert(conns, signal:Connect(fn))
		fn()
	end

	table.insert(conns,char:GetAttributeChangedSignal("HitAt"):Connect(noteCombat))
	on(hum.HealthChanged, function()
		local frac = hum.Health / math.max(hum.MaxHealth, 1)
		damageVersion += 1
		local version = damageVersion
		if damageTween then damageTween:Cancel() end
		if hum.Health < previousHealth then noteCombat() end
		previousHealth = hum.Health
		if frac >= hpFill.Size.Y.Scale then
			setFill(hpTrail, frac)
		else
			task.delay(H.DamageDelay, function()
				if version ~= damageVersion or player.Character ~= char then return end
				damageTween = TweenService:Create(hpTrail, TweenInfo.new(H.DamageTime), { Size = UDim2.fromScale(1, frac) })
				damageTween:Play()
			end)
		end
		setFill(hpFill, frac)
		hpNumber.Text = ("%d / %d"):format(math.max(0, math.ceil(hum.Health)), math.floor(hum.MaxHealth))
	end)

	on(hum:GetPropertyChangedSignal("MaxHealth"), function()
		setFill(hpFill, hum.Health / math.max(hum.MaxHealth, 1))
		hpNumber.Text = ("%d / %d"):format(math.max(0, math.ceil(hum.Health)), math.floor(hum.MaxHealth))
	end)

	on(char:GetAttributeChangedSignal("WeaponId"), function()
		local wid = char:GetAttribute("WeaponId")
		local def = WeaponData.Data[wid]
		weaponLabel.Text = def and L.t("weapon." .. wid) or ""
	end)

	local function updateStamina()
		local max = char:GetAttribute("StaminaMax") or CombatConfig.Stamina.Max
		local cur = char:GetAttribute("Stamina") or max
		if cur < max - 5 then noteCombat() end
		setFill(stamFill, cur / math.max(max,1))
		stamNumber.Text = ("%d"):format(math.floor(cur))
 end
 on(char:GetAttributeChangedSignal("Stamina"),updateStamina)
 on(char:GetAttributeChangedSignal("StaminaMax"),updateStamina)

	on(char:GetAttributeChangedSignal("StaminaFailAt"), function()
		if not char:GetAttribute("StaminaFailAt") then return end
		noteCombat()
		stamBg.BackgroundColor3 = C.Danger
		TweenService:Create(stamBg, TweenInfo.new(0.35), { BackgroundColor3 = C.BgBarBack }):Play()
	end)

	local function updateGuard()
		local gmax = char:GetAttribute("GuardMax") or 100
		local gcur = char:GetAttribute("Guard") or gmax
		local broken = char:GetAttribute("GuardBroken") == true
		if gcur < gmax - 5 or broken then noteCombat() end
		setFill(guardFill, gcur / math.max(gmax, 1))
		guardFill.BackgroundColor3 = broken and C.GuardBroken or C.Guard
		icons.guard.update(gcur / math.max(gmax, 1), broken)
	end
	on(char:GetAttributeChangedSignal("Guard"), updateGuard)
	on(char:GetAttributeChangedSignal("GuardBroken"), updateGuard)
	on(char:GetAttributeChangedSignal("GuardMax"), updateGuard)

	on(char:GetAttributeChangedSignal("Stun"), function()
		local s = char:GetAttribute("Stun") or 0
		if s > 0 then noteCombat() end
		local frac = s / CombatConfig.Stun.Max
		setFill(stunFill, frac)
		icons.stun.update(frac, false)
		stunFill.BackgroundColor3 = frac >= 0.75 and C.StunDanger or C.Stun
	end)

	on(char:GetAttributeChangedSignal("InfusionCharge"), function()
		local ch = char:GetAttribute("InfusionCharge") or 0
		local max = CombatConfig.InfusionCharge.Max
		setFill(infFill, ch / max)
	end)

	on(char:GetAttributeChangedSignal("InfusionActive"), function()
		if char:GetAttribute("InfusionActive") then noteCombat() end
	end)
end

player.CharacterAdded:Connect(hook)
if player.Character then task.spawn(hook, player.Character) end

----------------------------------------------------------------------
-- 8. Música y ambiente (locales, en bucle y conectados a SoundGroups C10)
----------------------------------------------------------------------
local function ensureSoundGroup(name)
	local g = SoundService:FindFirstChild(name)
	if not g or not g:IsA("SoundGroup") then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Volume = 1
		g.Parent = SoundService
	end
	return g
end

local musicGroup = ensureSoundGroup("Music")
ensureSoundGroup("SFX")

local function loop(key)
	local id = Assets.sound(key)
	if not id then return nil end
	local s = Instance.new("Sound")
	s.Name = key
	s.SoundId = id
	s.Looped = true
	local cfg = Assets.soundSettings(key)
	s.Volume = (cfg and cfg.volume) or 0.2
	s.SoundGroup = musicGroup
	s.Parent = SoundService
	s:Play()
	return s
end

local lobbyMusic = loop("Music_Lobby_Loop")
local battleMusic = loop("Music_Battle_Loop")
loop("Ambient_Lobby_Loop")
if battleMusic then battleMusic.Volume = 0 end

local function updateMusic()
	local inMatch = player:GetAttribute("InMatch") == true
	local lv = Assets.soundSettings("Music_Lobby_Loop").volume or 0.2
	local bv = Assets.soundSettings("Music_Battle_Loop").volume or 0.2
	if lobbyMusic then
		TweenService:Create(lobbyMusic, TweenInfo.new(2), { Volume = inMatch and 0 or lv }):Play()
	end
	if battleMusic then
		TweenService:Create(battleMusic, TweenInfo.new(2), { Volume = inMatch and bv or 0 }):Play()
	end
end
player:GetAttributeChangedSignal("InMatch"):Connect(updateMusic)
updateMusic()

L.Changed:Connect(function()
	updateStatus()
	for key, text in rowLabels do
		text.Text = L.t(key)
	end
end)
