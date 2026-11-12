-- LocalScript: StarterPlayer/StarterPlayerScripts/Prematch
-- Antesala del Duelo y Presentación Cinematográfica de Combatientes (Versión 0.2 — D11, D13, D16, C17).
-- Lee la fase del jugador (`player:GetAttribute("MatchPhase")`, C17: Lobby | Prematch | Cinematic | Round | RoundEnd | Summary), con `workspace` como respaldo,
-- y `PhaseEnds` (hora del servidor) del jugador o de `workspace`.
--   - En "Prematch": muestra la cuenta atrás y selección rápida de arma, skin e infusión (más botón para abrir la Armería completa).
--   - En "Cinematic": muestra los carteles dark-fantasy con nombre, nivel, rol y arma de cada combatiente de la partida.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local UiTheme = require(RS:WaitForChild("UiTheme", 10))
local UiAssets = require(RS:WaitForChild("UiAssets", 10))
local L = require(RS:WaitForChild("Localization", 10))
local Weapons = require(RS:WaitForChild("WeaponData", 10))
local Skins = require(RS:WaitForChild("Skins", 10))
local Infusions = require(RS:WaitForChild("Infusions", 10))

local remotes = RS:WaitForChild("Remotes", 10)
local shopRemote = remotes and remotes:WaitForChild("Shop", 10)
local C = UiTheme.Colors

local ROLE_COLORS = {
	OWNER = C.Coins,
	DEV = C.Guard,
	ADMIN = C.Danger,
	TESTER = C.Success,
}

local gui = Instance.new("ScreenGui")
gui.Name = "PrematchGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 9
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui", 10)

----------------------------------------------------------------------
-- 1. Contenedor de Antesala ("Prematch")
----------------------------------------------------------------------
local prematchRoot = Instance.new("Frame")
prematchRoot.Name = "PrematchRoot"
prematchRoot.Size = UDim2.fromScale(1, 1)
prematchRoot.BackgroundTransparency = 1
prematchRoot.Visible = false
prematchRoot.Parent = gui

local topBanner = UiTheme.panel({
	name = "PrematchBanner",
	parent = prematchRoot,
	anchor = Vector2.new(0.5, 0),
	position = UDim2.new(0.5, 0, 0, 14),
	size = UDim2.fromOffset(480, 74),
	bg = C.BgPrimary,
	borderColor = C.GoldBright,
	borderThickness = UiTheme.Stroke.Heavy,
	ornaments = true,
	ornamentSize = 12,
})
local topScale = Instance.new("UIScale")
topScale.Parent = topBanner

local bannerTitleLbl = UiTheme.label({
	parent = topBanner,
	position = UDim2.fromOffset(16, 6),
	size = UDim2.new(1, -32, 0, 24),
	text = L.t("ui.prematch.title"),
	font = "Title",
	textSize = UiTheme.TextSizes.LG,
	color = C.GoldBright,
	alignX = Enum.TextXAlignment.Center,
})

local countdownLbl = UiTheme.label({
	parent = topBanner,
	position = UDim2.fromOffset(16, 28),
	size = UDim2.new(1, -32, 0, 22),
	text = L.t("ui.prematch.startsIn", { sec = 10 }),
	font = "Number",
	textSize = UiTheme.TextSizes.MD,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Center,
})

local timerTrack = Instance.new("Frame")
timerTrack.AnchorPoint = Vector2.new(0.5, 1)
timerTrack.Position = UDim2.new(0.5, 0, 1, -8)
timerTrack.Size = UDim2.new(1, -36, 0, 6)
timerTrack.BackgroundColor3 = C.BgAbyss
timerTrack.BorderSizePixel = 0
timerTrack.Parent = topBanner
UiTheme.corner(timerTrack, 3)

local timerFill = Instance.new("Frame")
timerFill.Size = UDim2.fromScale(1, 1)
timerFill.BackgroundColor3 = C.GoldBright
timerFill.BorderSizePixel = 0
timerFill.Parent = timerTrack
UiTheme.corner(timerFill, 3)

-- Panel inferior de selección rápida (Arma, Skin, Infusión y botón Armería Completa)
local quickDock = UiTheme.panel({
	name = "QuickLoadoutDock",
	parent = prematchRoot,
	anchor = Vector2.new(0.5, 1),
	position = UDim2.new(0.5, 0, 1, -16),
	size = UDim2.fromOffset(820, 152),
	bg = C.BgPrimary,
	borderColor = C.Gold,
	borderThickness = UiTheme.Stroke.Heavy,
	ornaments = true,
	ornamentSize = 14,
})
local dockScale = Instance.new("UIScale")
dockScale.Parent = quickDock

----------------------------------------------------------------------
-- 2. Contenedor de Presentación Cinematográfica ("Cinematic" — D16)
----------------------------------------------------------------------
local cinematicRoot = Instance.new("Frame")
cinematicRoot.Name = "CinematicRoot"
cinematicRoot.Size = UDim2.fromScale(1, 1)
cinematicRoot.BackgroundTransparency = 1
cinematicRoot.Visible = false
cinematicRoot.Parent = gui

local cineScale = Instance.new("UIScale")
cineScale.Parent = cinematicRoot

local busy = false
local phaseStartClock = os.clock()
local phaseDuration = 10

local function parseCsv(raw)
	local map = {}
	for token in string.gmatch(raw or "", "[^,]+") do
		map[token] = true
	end
	return map
end

local function ownSkins()
	local map = parseCsv(player:GetAttribute("OwnedSkins"))
	map.Default = true
	return map
end

local function invokeQuickLoadout(action, id)
	if busy or not shopRemote then return end
	if (player:GetAttribute("MatchPhase") or workspace:GetAttribute("MatchPhase")) ~= "Prematch" then return end
	busy = true
	local ok, success = pcall(function()
		return shopRemote:InvokeServer(action, id)
	end)
	busy = false
	UiTheme.playSound((ok and success) and "UI_Equip" or "UI_Error")
end

local function renderQuickDock()
	for _, ch in quickDock:GetChildren() do
		if ch ~= dockScale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" and ch.Name ~= "FrameArt" then
			ch:Destroy()
		end
	end

	local eqWeapon = player:GetAttribute("WeaponId") or "Sword"
	local eqSkin = player:GetAttribute("EquippedSkin") or "Default"
	local eqInfusion = player:GetAttribute("InfusionId") or "Fire"
	local ownedMap = ownSkins()

	-- Fila 1: Armas (izquierda) + Infusiones (derecha)
	UiTheme.label({
		parent = quickDock,
		position = UDim2.fromOffset(18, 10),
		size = UDim2.fromOffset(90, 28),
		text = L.t("ui.prematch.weapon"),
		font = "Bold",
		textSize = UiTheme.TextSizes.XS,
		color = C.GoldBright,
	})

	for i, wid in Weapons.Order do
		UiTheme.button({
			parent = quickDock,
			position = UDim2.fromOffset(88 + (i - 1) * 86, 8),
			size = UDim2.fromOffset(82, 32),
			text = L.t("weapon." .. wid),
			selected = wid == eqWeapon,
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				invokeQuickLoadout("SelectWeapon", wid)
			end,
		})
	end

	-- Selector rápido de las 4 Infusiones
	UiTheme.label({
		parent = quickDock,
		position = UDim2.fromOffset(18, 50),
		size = UDim2.fromOffset(90, 28),
		text = L.t("ui.prematch.infusion"),
		font = "Bold",
		textSize = UiTheme.TextSizes.XS,
		color = C.GoldBright,
	})

	for i, infId in Infusions.Order do
		UiTheme.button({
			parent = quickDock,
			position = UDim2.fromOffset(88 + (i - 1) * 108, 48),
			size = UDim2.fromOffset(102, 32),
			text = L.t("infusion." .. infId),
			selected = infId == eqInfusion,
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				invokeQuickLoadout("SelectInfusion", infId)
			end,
		})
	end

	-- Fila 2: Skins en propiedad para el arma actual
	UiTheme.label({
		parent = quickDock,
		position = UDim2.fromOffset(18, 92),
		size = UDim2.fromOffset(90, 28),
		text = L.t("ui.prematch.skin"),
		font = "Bold",
		textSize = UiTheme.TextSizes.XS,
		color = C.GoldBright,
	})

	local skinScroll = Instance.new("ScrollingFrame")
	skinScroll.Position = UDim2.fromOffset(88, 90)
	skinScroll.Size = UDim2.fromOffset(536, 46)
	skinScroll.BackgroundTransparency = 1
	skinScroll.BorderSizePixel = 0
	skinScroll.ScrollingDirection = Enum.ScrollingDirection.X
	skinScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	skinScroll.CanvasSize = UDim2.new()
	skinScroll.ScrollBarThickness = 4
	skinScroll.ScrollBarImageColor3 = C.Gold
	skinScroll.Parent = quickDock

	local sLayout = Instance.new("UIListLayout")
	sLayout.FillDirection = Enum.FillDirection.Horizontal
	sLayout.Padding = UDim.new(0, 6)
	sLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sLayout.Parent = skinScroll

	local orderIdx = 0
	for _, sid in Skins.Order do
		local s = Skins.Data[sid]
		if s and ownedMap[sid] and (not s.weapon or s.weapon == eqWeapon) then
			orderIdx += 1
			UiTheme.button({
				parent = skinScroll,
				layoutOrder = orderIdx,
				size = UDim2.fromOffset(124, 36),
				text = L.t("skin." .. sid),
				selected = sid == eqSkin,
				textSize = UiTheme.TextSizes.XS,
				onClick = function()
					invokeQuickLoadout("Equip", sid)
				end,
			})
		end
	end

	-- Botón para abrir la Armería completa con vista 3D del personaje
	UiTheme.button({
		name = "OpenFullArmoryBtn",
		parent = quickDock,
		anchor = Vector2.new(1, 0.5),
		position = UDim2.new(1, -18, 0.5, 0),
		size = UDim2.fromOffset(168, 52),
		text = L.t("ui.prematch.openArmory"),
		icon = "armory",
		iconSize = 20,
		variant = "gold",
		textSize = UiTheme.TextSizes.SM,
		onClick = function()
			local ev = player:FindFirstChild("ToggleArmory")
			if ev and ev:IsA("BindableEvent") then
				ev:Fire(true)
			end
		end,
	})
end

----------------------------------------------------------------------
-- Renderizado de los carteles de presentación en "Cinematic" (D16)
----------------------------------------------------------------------
local function renderCinematicCards()
	for _, ch in cinematicRoot:GetChildren() do
		if ch ~= cineScale then
			ch:Destroy()
		end
	end

	local redFighters = {}
	local blueFighters = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InMatch") then
			local teamName = p.Team and p.Team.Name or "Red"
			if teamName == "Blue" then
				table.insert(blueFighters, p)
			else
				table.insert(redFighters, p)
			end
		end
	end
	if #redFighters == 0 and #blueFighters == 0 then
		table.insert(redFighters, player)
	end

	-- Cabecera superior de presentación
	local titleBox = UiTheme.panel({
		name = "CinematicTitle",
		parent = cinematicRoot,
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 18),
		size = UDim2.fromOffset(440, 48),
		bg = C.BgPrimary,
		borderColor = C.GoldBright,
		ornaments = true,
	})
	UiTheme.label({
		parent = titleBox,
		size = UDim2.fromScale(1, 1),
		text = L.t("ui.cinematic.title"),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
		alignX = Enum.TextXAlignment.Center,
	})

	local function buildFighterCard(fighter, side, index, total)
		local isRed = side == "Red"
		local accent = isRed and C.TeamRed or C.TeamBlue
		local cardH = 98
		local yOffset = (index - (total + 1) * 0.5) * (cardH + 14)

		local card = UiTheme.panel({
			name = "FighterCard_" .. fighter.Name,
			parent = cinematicRoot,
			anchor = Vector2.new(isRed and 0 or 1, 0.5),
			position = UDim2.new(isRed and 0 or 1, isRed and 28 or -28, 0.52, yOffset),
			size = UDim2.fromOffset(330, cardH),
			bg = C.BgPrimary,
			borderColor = accent,
			borderThickness = 2,
			ornaments = true,
		})

		-- Nivel del jugador
		local lvl = fighter:GetAttribute("Level") or 1
		local lvlBadge = Instance.new("Frame")
		lvlBadge.Position = UDim2.fromOffset(14, 14)
		lvlBadge.Size = UDim2.fromOffset(62, 24)
		lvlBadge.BackgroundColor3 = C.BgAbyss
		lvlBadge.BorderSizePixel = 0
		lvlBadge.Parent = card
		UiTheme.corner(lvlBadge, UiTheme.Radius.Pill)
		UiTheme.stroke(lvlBadge, C.GoldBright, 1.2, 0.15)
		UiTheme.label({
			parent = lvlBadge,
			size = UDim2.fromScale(1, 1),
			text = L.t("ui.cinematic.level", { level = tostring(lvl) }),
			font = "Number",
			textSize = UiTheme.TextSizes.XS,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})

		-- Insignia de Rol (si tiene Role en atributos, p. ej. OWNER / DEV / ADMIN / TESTER)
		local roleStr = fighter:GetAttribute("Role")
		if type(roleStr) == "string" and #roleStr > 0 then
			local rCol = ROLE_COLORS[string.upper(roleStr)] or C.GoldBright
			local roleBadge = Instance.new("Frame")
			roleBadge.Position = UDim2.fromOffset(82, 14)
			roleBadge.Size = UDim2.fromOffset(84, 24)
			roleBadge.BackgroundColor3 = C.BgAbyss
			roleBadge.BorderSizePixel = 0
			roleBadge.Parent = card
			UiTheme.corner(roleBadge, UiTheme.Radius.Pill)
			UiTheme.stroke(roleBadge, rCol, 1.2, 0.1)
			UiTheme.label({
				parent = roleBadge,
				size = UDim2.fromScale(1, 1),
				text = "[" .. string.upper(roleStr) .. "]",
				font = "Bold",
				textSize = UiTheme.TextSizes.XS,
				color = rCol,
				alignX = Enum.TextXAlignment.Center,
			})
		end

		-- Nombre del jugador
		UiTheme.label({
			parent = card,
			position = UDim2.fromOffset(14, 42),
			size = UDim2.new(1, -28, 0, 26),
			text = fighter.DisplayName or fighter.Name,
			font = "Title",
			textSize = UiTheme.TextSizes.LG,
			color = C.TextPrimary,
			truncate = Enum.TextTruncate.AtEnd,
		})

		-- Arma + Skin equipada
		local wid = fighter:GetAttribute("WeaponId") or "Sword"
		local sid = fighter:GetAttribute("EquippedSkin") or "Default"
		local infId = fighter:GetAttribute("InfusionId") or "Fire"
		UiTheme.label({
			parent = card,
			position = UDim2.fromOffset(14, 68),
			size = UDim2.new(1, -28, 0, 20),
			text = L.t("ui.cinematic.weapon", {
				weapon = L.t("weapon." .. wid),
				skin = L.t("skin." .. sid),
			}) .. " · " .. L.t("infusion." .. infId),
			font = "Bold",
			textSize = UiTheme.TextSizes.XS,
			color = accent,
			truncate = Enum.TextTruncate.AtEnd,
		})
	end

	for idx, f in redFighters do
		buildFighterCard(f, "Red", idx, #redFighters)
	end
	for idx, f in blueFighters do
		buildFighterCard(f, "Blue", idx, #blueFighters)
	end

	-- Emblema central VS si hay ambos equipos
	if #redFighters > 0 and #blueFighters > 0 then
		local vsCrest = Instance.new("Frame")
		vsCrest.AnchorPoint = Vector2.new(0.5, 0.5)
		vsCrest.Position = UDim2.fromScale(0.5, 0.52)
		vsCrest.Size = UDim2.fromOffset(68, 68)
		vsCrest.BackgroundColor3 = C.BgPrimary
		vsCrest.BorderSizePixel = 0
		vsCrest.Parent = cinematicRoot
		UiTheme.corner(vsCrest, 34)
		UiTheme.stroke(vsCrest, C.GoldBright, 2.2, 0.05)
		UiTheme.label({
			parent = vsCrest,
			size = UDim2.fromScale(1, 1),
			text = L.t("ui.cinematic.vs"),
			font = "Title",
			textSize = UiTheme.TextSizes.XL,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})
	end
end

----------------------------------------------------------------------
-- Sincronización con MatchPhase y PhaseEnds (Contrato C17)
----------------------------------------------------------------------
local function refreshPhaseState()
	local phase = (player:GetAttribute("MatchPhase") or workspace:GetAttribute("MatchPhase")) or "Idle"
	local inMatch = player:GetAttribute("InMatch") == true
	local endsAt = tonumber((player:GetAttribute("PhaseEnds") or workspace:GetAttribute("PhaseEnds"))) or 0
	local nowServer = workspace:GetServerTimeNow()
	local rem = math.max(0, endsAt - nowServer)

	if phase == "Prematch" and inMatch then
		phaseStartClock = os.clock()
		phaseDuration = math.max(1, rem > 0 and rem or 10)
		prematchRoot.Visible = true
		cinematicRoot.Visible = false
		bannerTitleLbl.Text = L.t("ui.prematch.title")
		renderQuickDock()
	elseif phase == "Cinematic" and inMatch then
		prematchRoot.Visible = false
		cinematicRoot.Visible = true
		renderCinematicCards()
	else
		prematchRoot.Visible = false
		cinematicRoot.Visible = false
	end
end

workspace:GetAttributeChangedSignal("MatchPhase"):Connect(refreshPhaseState)
player:GetAttributeChangedSignal("MatchPhase"):Connect(refreshPhaseState)
player:GetAttributeChangedSignal("PhaseEnds"):Connect(refreshPhaseState)
workspace:GetAttributeChangedSignal("PhaseEnds"):Connect(refreshPhaseState)
player:GetAttributeChangedSignal("InMatch"):Connect(refreshPhaseState)

for _, attr in { "WeaponId", "EquippedSkin", "InfusionId", "OwnedSkins", "OptUiScale" } do
	player:GetAttributeChangedSignal(attr):Connect(function()
		if prematchRoot.Visible then
			renderQuickDock()
		elseif cinematicRoot.Visible then
			renderCinematicCards()
		end
	end)
end

L.Changed:Connect(function()
	refreshPhaseState()
end)

local lastPrematchKey = nil
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	-- 11/11 (rendimiento): la escala solo se recalcula si cambia la pantalla
	local key = cam and (tostring(cam.ViewportSize) .. tostring(player:GetAttribute("OptUiScale")))
	if cam and key ~= lastPrematchKey then
		lastPrematchKey = key
		local sc = UiTheme.computeScale(cam.ViewportSize, 1020, 620, player)
		topScale.Scale = sc
		dockScale.Scale = sc
		cineScale.Scale = sc
	end

	if prematchRoot.Visible then
		local endsAt = tonumber((player:GetAttribute("PhaseEnds") or workspace:GetAttribute("PhaseEnds"))) or 0
		local rem = math.max(0, endsAt - workspace:GetServerTimeNow())
		if endsAt <= 0 then
			rem = math.max(0, phaseDuration - (os.clock() - phaseStartClock))
		end
		countdownLbl.Text = L.t("ui.prematch.startsIn", { sec = math.ceil(rem) })
		local frac = math.clamp(rem / math.max(1, phaseDuration), 0, 1)
		timerFill.Size = UDim2.fromScale(frac, 1)
		local armoryOpen = player:GetAttribute("ArmoryOpen") == true
		quickDock.Visible = not armoryOpen
	end
end)

refreshPhaseState()
