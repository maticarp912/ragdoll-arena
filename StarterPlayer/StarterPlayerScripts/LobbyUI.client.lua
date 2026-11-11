-- LocalScript: StarterPlayer/StarterPlayerScripts/LobbyUI
-- Interfaz del Lobby rediseñada (Fase 4, responsable: Gemini, etapa 8).
-- Incluye:
-- 1. Barra de cola inferior (Contrato C3: Remotes.Queue Join 1v1/2v2 y Leave, QueueCount1v1/2v2, QueueMode).
-- 2. Botón y panel de Misiones Diarias (Contrato C8: Remotes.Missions Get/Claim y Remotes.MissionsChanged).
-- 3. Acceso desde menú a las Tablas de Clasificación (Contrato C7: ReplicatedStorage.Leaderboards).
-- 4. Botón y panel de Clasificatorias ("Próximamente").

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme", 10))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets", 10))
local L = require(ReplicatedStorage:WaitForChild("Localization", 10))

local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local QueueRemote = remotes and remotes:WaitForChild("Queue", 10)

local player = Players.LocalPlayer
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local C = UiTheme.Colors
local NEED = { ["1v1"] = 2, ["2v2"] = 4 }

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 6
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

----------------------------------------------------------------------
-- 1. Columna vertical izquierda (Armería, Ajustes, Misiones, Clasificación)
--    Ubicada a media altura de la pantalla, con iconos a la izquierda con su propio espacio.
----------------------------------------------------------------------
local leftDock = Instance.new("Frame")
leftDock.Name = "LeftLobbyDock"
leftDock.AnchorPoint = Vector2.new(0, 0.5)
leftDock.Position = UDim2.new(0, 16, 0.5, 0)
leftDock.Size = UDim2.fromOffset(172, 294)
leftDock.BackgroundTransparency = 1
leftDock.Parent = gui
local dockScale = Instance.new("UIScale")
dockScale.Parent = leftDock

local dockLayout = Instance.new("UIListLayout")
dockLayout.FillDirection = Enum.FillDirection.Vertical
dockLayout.Padding = UDim.new(0, 8)
dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
dockLayout.Parent = leftDock

local activeModal = nil -- "Missions" | "Leaderboards" | "Ranked" | nil
local toggleModal

local function makeAlertBadge(parentBtn, name)
	local badge = Instance.new("Frame")
	badge.Name = name or "ClaimBadge"
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -4, 0, 4)
	badge.Size = UDim2.fromOffset(18, 18)
	badge.BackgroundColor3 = C.Danger
	badge.BorderSizePixel = 0
	badge.Visible = false
	badge.ZIndex = parentBtn.ZIndex + 4
	badge.Parent = parentBtn
	UiTheme.corner(badge, 9)
	UiTheme.stroke(badge, C.GoldBright, 1, 0.1)
	local lbl = UiTheme.label({
		parent = badge,
		size = UDim2.fromScale(1, 1),
		text = "!",
		font = "Bold",
		textSize = 12,
		color = C.TextPrimary,
		alignX = Enum.TextXAlignment.Center,
		zIndex = badge.ZIndex + 1,
	})
	return badge, lbl
end

local armoryBtn = UiTheme.button({
	name = "ArmoryBtn",
	parent = leftDock,
	layoutOrder = 1,
	size = UDim2.fromOffset(168, 42),
	text = L.t("ui.lobby.dock.armory"),
	icon = "armory",
	iconSize = 20,
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "secondary",
	onClick = function()
		local event = player:FindFirstChild("ToggleArmory")
		if event and event:IsA("BindableEvent") then
			event:Fire()
		end
	end,
})

local shopBtn = UiTheme.button({
	name = "ShopBtn",
	parent = leftDock,
	layoutOrder = 2,
	size = UDim2.fromOffset(168, 42),
	text = L.t("ui.lobby.dock.shop"),
	icon = "coin",
	iconSize = 20,
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "secondary",
	onClick = function()
		local event = player:FindFirstChild("ToggleMenu")
		if event and event:IsA("BindableEvent") then
			event:Fire()
		end
	end,
})

local rewardsBtn = UiTheme.button({
	name = "RewardsBtn",
	parent = leftDock,
	layoutOrder = 3,
	size = UDim2.fromOffset(168, 42),
	text = L.t("ui.lobby.dock.rewards"),
	icon = "trophy",
	iconSize = 20,
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "gold",
	onClick = function()
		local event = player:FindFirstChild("ToggleRewards")
		if event and event:IsA("BindableEvent") then
			event:Fire()
		else
			player:SetAttribute("RewardsOpen", not player:GetAttribute("RewardsOpen"))
		end
	end,
})
local rewardsBadge = makeAlertBadge(rewardsBtn, "RewardsBadge")

local settingsBtn = UiTheme.button({
	name = "SettingsBtn",
	parent = leftDock,
	layoutOrder = 4,
	size = UDim2.fromOffset(168, 42),
	text = L.t("settings"),
	icon = "settings",
	iconSize = 20,
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "secondary",
	onClick = function()
		player:SetAttribute("SettingsOpen", not player:GetAttribute("SettingsOpen"))
	end,
})

local missionsBtn = UiTheme.button({
	name = "MissionsBtn",
	parent = leftDock,
	layoutOrder = 5,
	size = UDim2.fromOffset(168, 42),
	text = L.t("ui.lobby.missions"),
	icon = "mission",
	iconSize = 20,
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "secondary",
	onClick = function()
		toggleModal("Missions")
	end,
})
local missionBadge, missionBadgeText = makeAlertBadge(missionsBtn, "ClaimBadge")

local boardsBtn = UiTheme.button({
	name = "LeaderboardsBtn",
	parent = leftDock,
	layoutOrder = 6,
	size = UDim2.fromOffset(168, 42),
	text = L.t("ui.lobby.leaderboards"),
	icon = "trophy",
	iconSize = 20,
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "secondary",
	onClick = function()
		toggleModal("Leaderboards")
	end,
})

----------------------------------------------------------------------
-- 2. Barra de cola inferior (Contrato C3)
--    Abajo al centro, bien centrados: Buscar 1v1, 2v2 y RANKED ("Próximamente").
----------------------------------------------------------------------
local queueBar = UiTheme.panel({
	name = "QueueBar",
	parent = gui,
	anchor = Vector2.new(0.5, 1),
	position = UDim2.new(0.5, 0, 1, -16),
	size = UDim2.fromOffset(560, 54),
	bg = C.BgPanel,
	transparency = 0.08,
	borderColor = C.Gold,
	ornaments = true,
	ornamentSize = 8,
})
queueBar.AutomaticSize = Enum.AutomaticSize.X
local queueScale = Instance.new("UIScale")
queueScale.Parent = queueBar
UiTheme.padding(queueBar, 4, 14, 4, 14)

local qLayout = Instance.new("UIListLayout")
qLayout.FillDirection = Enum.FillDirection.Horizontal
qLayout.Padding = UDim.new(0, 12)
qLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
qLayout.VerticalAlignment = Enum.VerticalAlignment.Center
qLayout.SortOrder = Enum.SortOrder.LayoutOrder
qLayout.Parent = queueBar

local requestedMode = nil

local join1Btn = UiTheme.button({
	name = "Join1v1",
	parent = queueBar,
	layoutOrder = 1,
	size = UDim2.fromOffset(156, 42),
	text = L.t("ui.queue.1v1"),
	font = "Title",
	textSize = UiTheme.TextSizes.LG,
	variant = "gold",
	onClick = function()
		requestedMode = "1v1"
		if QueueRemote then QueueRemote:FireServer("Join", "1v1") end
	end,
})

local join2Btn = UiTheme.button({
	name = "Join2v2",
	parent = queueBar,
	layoutOrder = 2,
	size = UDim2.fromOffset(156, 42),
	text = L.t("ui.queue.2v2"),
	font = "Title",
	textSize = UiTheme.TextSizes.LG,
	variant = "primary",
	onClick = function()
		requestedMode = "2v2"
		if QueueRemote then QueueRemote:FireServer("Join", "2v2") end
	end,
})

local rankedBtn = UiTheme.button({
	name = "RankedBtn",
	parent = queueBar,
	layoutOrder = 3,
	size = UDim2.fromOffset(168, 42),
	text = L.t("cx.ui.ranked"),
	font = "Title",
	textSize = UiTheme.TextSizes.LG,
	variant = "secondary",
	onClick = function()
		toggleModal("Ranked")
	end,
})

local rankedTag = UiTheme.label({
	name = "RankedTag",
	parent = rankedBtn,
	anchor = Vector2.new(1, 0),
	position = UDim2.new(1, -6, 0, -6),
	size = UDim2.fromOffset(72, 18),
	text = L.t("soon"),
	font = "Bold",
	textSize = 10,
	color = C.GoldBright,
	alignX = Enum.TextXAlignment.Center,
})
local tagBg = Instance.new("Frame")
tagBg.Size = UDim2.fromScale(1, 1)
tagBg.BackgroundColor3 = C.BgAbyss
tagBg.BorderSizePixel = 0
tagBg.ZIndex = rankedTag.ZIndex - 1
tagBg.Parent = rankedBtn
 tagBg.AnchorPoint=rankedTag.AnchorPoint tagBg.Position=rankedTag.Position tagBg.Size=rankedTag.Size
 rankedTag.ZIndex=rankedBtn.ZIndex+3 tagBg.ZIndex=rankedBtn.ZIndex+2
UiTheme.corner(tagBg, 4)
UiTheme.stroke(tagBg, C.Gold, 1, 0.2)

local queueStatusLbl = UiTheme.label({
	name = "QueueStatus",
	parent = queueBar,
	layoutOrder = 4,
	size = UDim2.fromOffset(240, 42),
	autoSize = Enum.AutomaticSize.X,
	text = "",
	font = "Bold",
	textSize = UiTheme.TextSizes.MD,
	color = C.GoldBright,
	alignX = Enum.TextXAlignment.Center,
})
queueStatusLbl.Visible = false

local leaveBtn = UiTheme.button({
	name = "LeaveQueue",
	parent = queueBar,
	layoutOrder = 5,
	size = UDim2.fromOffset(156, 42),
	text = L.t("ui.queue.leave"),
	font = "Bold",
	textSize = UiTheme.TextSizes.MD,
	variant = "danger",
	onClick = function()
		requestedMode = nil
		if QueueRemote then QueueRemote:FireServer("Leave") end
	end,
})
leaveBtn.Visible = false

----------------------------------------------------------------------
-- 3. Contenedor modal para Misiones Diarias (C8), Clasificación (C7) y Clasificatorias
----------------------------------------------------------------------
local modalVeil = Instance.new("TextButton")
modalVeil.Name = "LobbyModalVeil"
modalVeil.Size = UDim2.fromScale(1, 1)
modalVeil.BackgroundColor3 = C.BgModalVeil
modalVeil.BackgroundTransparency = 0.3
modalVeil.Text = ""
modalVeil.AutoButtonColor = false
modalVeil.Selectable = false
modalVeil.Visible = false
modalVeil.ZIndex = 20
modalVeil.Parent = gui

local modalBox = UiTheme.panel({
	name = "LobbyModalBox",
	parent = modalVeil,
	canvasGroup = true,
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.fromScale(0.5, 0.5),
	size = UDim2.fromOffset(720, 480),
	bg = C.BgPrimary,
	borderColor = C.Gold,
	borderThickness = UiTheme.Stroke.Thick,
	ornaments = true,
	ornamentSize = 14,
	zIndex = 21,
})
local modalScale = Instance.new("UIScale")
modalScale.Parent = modalBox

local missionsData = nil
local selectedBoard = "Wins"
local boardTabs = { "Wins", "Kills", "Knockdowns", "Coins" }
local renderModal

local function formatCountdown(resetAt)
	local rem = math.max(0, (tonumber(resetAt) or 0) - os.time())
	local h = math.floor(rem / 3600)
	local m = math.floor((rem % 3600) / 60)
	local s = rem % 60
	return ("%02d:%02d:%02d"):format(h, m, s)
end

local function updateMissionBadge()
	local readyCount = 0
	if missionsData and type(missionsData.list) == "table" then
		for _, m in missionsData.list do
			if not m.claimed and (tonumber(m.progress) or 0) >= (tonumber(m.goal) or 1) then
				readyCount += 1
			end
		end
	end
	missionBadge.Visible = readyCount > 0
	missionBadgeText.Text = tostring(readyCount)
end

local function fetchMissions()
	task.spawn(function()
		local rf = remotes:FindFirstChild("Missions")
		if not rf or not rf:IsA("RemoteFunction") then return end
		local ok, res = pcall(function()
			return rf:InvokeServer("Get")
		end)
		if ok and type(res) == "table" then
			missionsData = res
			updateMissionBadge()
			if activeModal == "Missions" then
				renderModal()
			end
		end
	end)
end

function renderModal()
	for _, ch in modalBox:GetChildren() do
		if ch ~= modalScale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
			ch:Destroy()
		end
	end
	if not activeModal then return end

	local w, h = modalBox.Size.X.Offset, modalBox.Size.Y.Offset

	-- Cabecera del modal
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.ZIndex = 22
	header.Parent = modalBox
	UiTheme.corner(header, UiTheme.Radius.MD)

	local titleKey = activeModal == "Missions" and "ui.missions.title"
		or (activeModal == "Leaderboards" and "ui.lobby.leaderboards" or "ui.ranked.title")
	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(22, 0),
		size = UDim2.fromOffset(w - 160, 54),
		text = string.upper(L.t(titleKey)),
		font = "Title",
		textSize = UiTheme.TextSizes.XXL,
		color = C.GoldBright,
		zIndex = 23,
	})

	local closeBtn = UiTheme.button({
		name = "CloseModal",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = UDim2.new(1, -14, 0.5, 0),
		size = UDim2.fromOffset(104, 38),
		text = L.t("close"),
		zIndex = 23,
		onClick = function()
			toggleModal(nil)
		end,
	})

	if activeModal == "Missions" then
		-- Subtítulo con cuenta regresiva hasta el reinicio diario
		local resetLbl = UiTheme.label({
			name = "ResetCountdown",
			parent = modalBox,
			position = UDim2.fromOffset(24, 62),
			size = UDim2.fromOffset(w - 48, 24),
			text = missionsData and L.t("ui.missions.resetIn", { time = formatCountdown(missionsData.resetAt) }) or L.t("ui.missions.empty"),
			font = "Body",
			textSize = UiTheme.TextSizes.SM,
			color = C.TextSecondary,
			zIndex = 22,
		})

		local listFrame = Instance.new("Frame")
		listFrame.Position = UDim2.fromOffset(24, 94)
		listFrame.Size = UDim2.fromOffset(w - 48, h - 148)
		listFrame.BackgroundTransparency = 1
		listFrame.ZIndex = 22
		listFrame.Parent = modalBox

		local mLayout = Instance.new("UIListLayout")
		mLayout.Padding = UDim.new(0, 12)
		mLayout.SortOrder = Enum.SortOrder.LayoutOrder
		mLayout.Parent = listFrame

		local msgLbl = UiTheme.label({
			parent = modalBox,
			position = UDim2.fromOffset(24, h - 42),
			size = UDim2.fromOffset(w - 48, 28),
			text = "",
			font = "Bold",
			textSize = UiTheme.TextSizes.SM,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 22,
		})

		for idx, m in (missionsData and missionsData.list) or {} do
			local card = UiTheme.panel({
				parent = listFrame,
				layoutOrder = idx,
				size = UDim2.new(1, 0, 0, 96),
				bg = C.BgCard,
				borderColor = (not m.claimed and m.progress >= m.goal) and C.GoldBright or C.BorderDefault,
				zIndex = 23,
			})

			local ic = UiAssets.icon(card, "mission", 34, C.GoldBright)
			ic.AnchorPoint = Vector2.new(0, 0.5)
			ic.Position = UDim2.new(0, 16, 0.5, 0)
			ic.ZIndex = 24

			UiTheme.label({
				parent = card,
				position = UDim2.fromOffset(62, 12),
				size = UDim2.new(1, -230, 0, 26),
				text = L.t(m.nameKey, m.params),
				font = "Header",
				textSize = UiTheme.TextSizes.LG,
				color = C.TextPrimary,
				zIndex = 24,
			})

			local frac = math.clamp((tonumber(m.progress) or 0) / math.max(1, tonumber(m.goal) or 1), 0, 1)
			local barBg = UiTheme.progressBar({
				parent = card,
				position = UDim2.fromOffset(62, 46),
				size = UDim2.new(1, -230, 0, 18),
				fraction = frac,
				fillColor = frac >= 1 and C.Success or C.Gold,
				showText = true,
				text = ("%d / %d"):format(math.floor(m.progress or 0), math.floor(m.goal or 1)),
				zIndex = 24,
			})
			barBg.ZIndex = 24

			-- Recompensa en almas (D5, C24)
			UiTheme.label({
				parent = card,
				position = UDim2.fromOffset(62, 68),
				size = UDim2.fromOffset(220, 20),
				text = L.t("ui.souls", { amount = m.reward or 0 }),
				font = "Number",
				textSize = UiTheme.TextSizes.SM,
				color = C.Coins,
				zIndex = 24,
			})

			local ready = not m.claimed and (m.progress or 0) >= (m.goal or 1)
			local btnLabel = m.claimed and L.t("ui.missions.claimed") or (ready and L.t("ui.missions.claim") or L.t("ui.missions.inProgress"))
			UiTheme.button({
				parent = card,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -16, 0.5, 0),
				size = UDim2.fromOffset(136, 44),
				text = btnLabel,
				variant = ready and "gold" or (m.claimed and "success" or "secondary"),
				disabled = not ready,
				zIndex = 24,
				onClick = function()
					local rf = remotes:FindFirstChild("Missions")
					if not rf then return end
					task.spawn(function()
						local ok, claimedOk, payload = pcall(function()
							return rf:InvokeServer("Claim", m.id)
						end)
						if ok and payload then
							msgLbl.Text = L.format(payload)
							msgLbl.TextColor3 = claimedOk and C.Success or C.Danger
						end
						fetchMissions()
					end)
				end,
			})
		end

	elseif activeModal == "Leaderboards" then
		-- Pestañas: Victorias, Eliminaciones, Derribos, Monedas
		local tabRow = Instance.new("Frame")
		tabRow.Position = UDim2.fromOffset(24, 64)
		tabRow.Size = UDim2.fromOffset(w - 48, 40)
		tabRow.BackgroundTransparency = 1
		tabRow.ZIndex = 22
		tabRow.Parent = modalBox
		local tLayout = Instance.new("UIListLayout")
		tLayout.FillDirection = Enum.FillDirection.Horizontal
		tLayout.Padding = UDim.new(0, 8)
		tLayout.Parent = tabRow

		for i, bKey in boardTabs do
			UiTheme.tabButton({
				parent = tabRow,
				layoutOrder = i,
				size = UDim2.fromOffset(math.floor((w - 48 - 24) / 4), 40),
				text = L.t("ui.board." .. bKey),
				active = selectedBoard == bKey,
				onClick = function()
					selectedBoard = bKey
					renderModal()
				end,
			}).ZIndex = 23
		end

		local scroll = Instance.new("ScrollingFrame")
		scroll.Position = UDim2.fromOffset(24, 114)
		scroll.Size = UDim2.fromOffset(w - 48, h - 166)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.new()
		scroll.ScrollBarThickness = 6
		scroll.ScrollBarImageColor3 = C.Gold
		scroll.ZIndex = 22
		scroll.Parent = modalBox

		local sLayout = Instance.new("UIListLayout")
		sLayout.Padding = UDim.new(0, 6)
		sLayout.SortOrder = Enum.SortOrder.LayoutOrder
		sLayout.Parent = scroll

		local lbFolder = ReplicatedStorage:FindFirstChild("Leaderboards")
		local valObj = lbFolder and lbFolder:FindFirstChild(selectedBoard)
		local rows = {}
		if valObj and valObj:IsA("StringValue") then
			local ok, parsed = pcall(HttpService.JSONDecode, HttpService, valObj.Value)
			if ok and type(parsed) == "table" then rows = parsed end
		end

		if #rows == 0 then
			UiTheme.label({
				parent = scroll,
				size = UDim2.new(1, 0, 0, 80),
				text = L.t("ui.board.empty"),
				font = "Body",
				textSize = UiTheme.TextSizes.MD,
				color = C.TextMuted,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 23,
			})
		else
			for rank, entry in rows do
				local isMe = tonumber(entry.userId) == player.UserId
				local row = UiTheme.panel({
					parent = scroll,
					layoutOrder = rank,
					size = UDim2.new(1, -8, 0, 36),
					bg = isMe and C.BgCardSelected or C.BgCard,
					borderColor = isMe and C.GoldBright or (rank <= 3 and C.Gold or C.BorderSubtle),
					borderThickness = isMe and 2 or 1,
					zIndex = 23,
				})

				UiTheme.label({
					parent = row,
					position = UDim2.fromOffset(12, 0),
					size = UDim2.fromOffset(42, 36),
					text = "#" .. tostring(rank),
					font = "Number",
					textSize = UiTheme.TextSizes.MD,
					color = rank == 1 and C.GoldBright or (rank <= 3 and C.Gold or C.TextSecondary),
					zIndex = 24,
				})

				local displayName = tostring(entry.name or entry.userId or "?")
				if isMe then
					displayName = displayName .. "  [" .. L.t("ui.board.you") .. "]"
				end
				UiTheme.label({
					parent = row,
					position = UDim2.fromOffset(60, 0),
					size = UDim2.new(1, -180, 1, 0),
					text = displayName,
					font = isMe and "Bold" or "Body",
					textSize = UiTheme.TextSizes.MD,
					color = isMe and C.GoldBright or C.TextPrimary,
					zIndex = 24,
				})

				UiTheme.label({
					parent = row,
					anchor = Vector2.new(1, 0),
					position = UDim2.new(1, -16, 0, 0),
					size = UDim2.fromOffset(110, 36),
					text = tostring(entry.value or 0),
					font = "Number",
					textSize = UiTheme.TextSizes.MD,
					color = C.GoldBright,
					alignX = Enum.TextXAlignment.Right,
					zIndex = 24,
				})
			end
		end

		-- Pie con estadísticas propias guardadas (StatWins, StatKills, StatKnockdowns)
		UiTheme.label({
			parent = modalBox,
			position = UDim2.fromOffset(24, h - 42),
			size = UDim2.fromOffset(w - 48, 28),
			text = L.t("ui.board.yourStats", {
				wins = player:GetAttribute("StatWins") or 0,
				kills = player:GetAttribute("StatKills") or 0,
				knockdowns = player:GetAttribute("StatKnockdowns") or 0,
			}),
			font = "Bold",
			textSize = UiTheme.TextSizes.SM,
			color = C.Gold,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 23,
		})

	elseif activeModal == "Ranked" then
		local crest = UiAssets.icon(modalBox, "trophy", 88, C.GoldBright)
		crest.AnchorPoint = Vector2.new(0.5, 0.5)
		crest.Position = UDim2.new(0.5, 0, 0.34, 0)
		crest.ZIndex = 23

		UiTheme.label({
			parent = modalBox,
			position = UDim2.new(0.1, 0, 0.52, 0),
			size = UDim2.new(0.8, 0, 0, 64),
			text = L.t("ui.ranked.desc"),
			font = "Body",
			textSize = UiTheme.TextSizes.LG,
			color = C.TextPrimary,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 23,
		})

		UiTheme.label({
			parent = modalBox,
			position = UDim2.new(0.1, 0, 0.72, 0),
			size = UDim2.new(0.8, 0, 0, 32),
			text = L.t("ui.ranked.rewards"),
			font = "Header",
			textSize = UiTheme.TextSizes.MD,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 23,
		})
	end

	if Device.isGamepad() then
		GuiService.SelectedObject = closeBtn
	end
end

function toggleModal(kind)
	if activeModal == kind then
		activeModal = nil
	else
		activeModal = kind
	end
	modalVeil.Visible = activeModal ~= nil
	UiTheme.playSound(activeModal and "UI_MenuOpen" or "UI_MenuClose")
	if activeModal == "Missions" then
		fetchMissions()
	end
	if activeModal then
		renderModal()
	else
		GuiService.SelectedObject = nil
	end
end

modalVeil.Activated:Connect(function()
	toggleModal(nil)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	-- B del mando cierra aunque venga marcado como procesado (la selección de la GUI lo marca así)
	if activeModal and (input.KeyCode == Enum.KeyCode.ButtonB or (not processed and input.KeyCode == Enum.KeyCode.Escape)) then
		toggleModal(nil)
	end
end)

----------------------------------------------------------------------
-- 4. Conexión de eventos de Misiones (C8) y refresco de cola (C3)
----------------------------------------------------------------------
task.spawn(function()
	fetchMissions()
	local changedEvent = remotes:WaitForChild("MissionsChanged", 15)
	if changedEvent and changedEvent:IsA("RemoteEvent") then
		changedEvent.OnClientEvent:Connect(fetchMissions)
	end
end)

local function refreshBar()
	local inMatch = player:GetAttribute("InMatch") == true
	local menuOpen = player:GetAttribute("MenuOpen") == true
	queueBar.Visible = not inMatch and not menuOpen
	leftDock.Visible = not inMatch and not menuOpen
	if inMatch then
		requestedMode = nil
		if activeModal then toggleModal(nil) end
	end

	local mode = player:GetAttribute("QueueMode") or requestedMode
	join1Btn.Text = L.t("ui.queue.1v1")
	join2Btn.Text = L.t("ui.queue.2v2")
	rankedBtn.Text = L.t("cx.ui.ranked")
	leaveBtn.Text = L.t("ui.queue.leave")
	armoryBtn.Text = L.t("ui.lobby.dock.armory")
	shopBtn.Text = L.t("ui.lobby.dock.shop")
	rewardsBtn.Text = L.t("ui.lobby.dock.rewards")
	settingsBtn.Text = L.t("settings")
	missionsBtn.Text = L.t("ui.lobby.missions")
	boardsBtn.Text = L.t("ui.lobby.leaderboards")
	rewardsBadge.Visible = player:GetAttribute("RewardsAlert") == true

	join1Btn.Visible = mode == nil
	join2Btn.Visible = mode == nil
	rankedBtn.Visible = mode == nil
	leaveBtn.Visible = mode ~= nil
	queueStatusLbl.Visible = mode ~= nil
	if mode then
		queueStatusLbl.Text = L.t("ui.queue.searching", {
			mode = mode,
			n = workspace:GetAttribute("QueueCount" .. mode) or 0,
			need = NEED[mode] or 2,
		})
	end

	local cam = workspace.CurrentCamera
	if cam then
		local sc = UiTheme.computeScale(cam.ViewportSize, 1060, 640, player)
		queueScale.Scale = sc
		dockScale.Scale = sc
		modalScale.Scale = sc
		leftDock.AnchorPoint = Vector2.new(0, 0.5)
		leftDock.Position = UDim2.new(0, 16, 0.5, 0)
	end
end

L.Changed:Connect(function()
	refreshBar()
	if activeModal then renderModal() end
end)

local barAcc = 0 -- 11/11 (rendimiento): 5 veces por segundo en vez de cada frame
RunService.Heartbeat:Connect(function(dt)
	barAcc += dt
	if barAcc < 0.2 then return end
	barAcc = 0
	if gui.Enabled then
		refreshBar()
		if activeModal == "Missions" and missionsData then
			local lbl = modalBox:FindFirstChild("ResetCountdown")
			if lbl and lbl:IsA("TextLabel") then
				lbl.Text = L.t("ui.missions.resetIn", { time = formatCountdown(missionsData.resetAt) })
			end
		end
	end
end)
