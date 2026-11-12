-- LocalScript: StarterPlayer/StarterPlayerScripts/Leaderboards
-- Tableros físicos de clasificación en la ciudad (Contrato C7, responsable: Gemini, etapa 8).
-- Dibuja un SurfaceGui sobre la cara Front de cada BasePart etiquetada con "LeaderboardBoard"
-- (atributo Board = "Wins" | "Kills" | "Knockdowns" | "Coins"), leyendo ReplicatedStorage.Leaderboards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))

local player = Players.LocalPlayer
local C = UiTheme.Colors

local BOARD_ICONS = {
	Wins       = "trophy",
	Kills      = "skull",
	Knockdowns = "knockdown",
	Coins      = "coin",
}

local activeBoards = {}

local function parseTop10(boardName)
	local folder = ReplicatedStorage:FindFirstChild("Leaderboards")
	local valObj = folder and folder:FindFirstChild(boardName)
	if not valObj or not valObj:IsA("StringValue") then
		return {}
	end
	local ok, list = pcall(HttpService.JSONDecode, HttpService, valObj.Value)
	if ok and type(list) == "table" then
		return list
	end
	return {}
end

local function renderBoard(part)
	local entry = activeBoards[part]
	if not entry or not part.Parent then return end

	local boardName = part:GetAttribute("Board") or "Wins"
	local root = entry.root
	for _, ch in root:GetChildren() do
		if not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" and ch.Name ~= "FrameArt" then
			ch:Destroy()
		end
	end

	-- Cabecera monumental legible a distancia
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 96)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = root
	UiTheme.corner(header, UiTheme.Radius.MD)

	local ic = UiAssets.icon(header, BOARD_ICONS[boardName] or "trophy", 48, C.GoldBright)
	ic.AnchorPoint = Vector2.new(0, 0.5)
	ic.Position = UDim2.new(0, 24, 0.5, 0)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(84, 12),
		size = UDim2.new(1, -104, 0, 72),
		text = L.t("ui.board." .. boardName),
		font = "Title",
		textSize = 42,
		maxTextSize = 44,
		minTextSize = 20,
		scaled = true,
		color = C.GoldBright,
	})

	local listHolder = Instance.new("Frame")
	listHolder.Position = UDim2.fromOffset(18, 110)
	listHolder.Size = UDim2.new(1, -36, 1, -128)
	listHolder.BackgroundTransparency = 1
	listHolder.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listHolder

	local rows = parseTop10(boardName)
	if #rows == 0 then
		UiTheme.label({
			parent = listHolder,
			size = UDim2.new(1, 0, 0, 120),
			text = L.t("ui.board.empty"),
			font = "Header",
			textSize = 28,
			color = C.TextMuted,
			alignX = Enum.TextXAlignment.Center,
		})
		return
	end

	for rank = 1, math.min(10, #rows) do
		local item = rows[rank]
		local isLocal = tonumber(item.userId) == player.UserId
		local rowBg = isLocal and C.BgCardSelected or (rank <= 3 and C.BgPanelLight or C.BgCard)
		local strokeCol = isLocal and C.GoldBright or (rank == 1 and C.GoldBright or (rank <= 3 and C.Gold or C.BorderSubtle))

		local row = UiTheme.panel({
			parent = listHolder,
			layoutOrder = rank,
			size = UDim2.new(1, 0, 0, 62),
			bg = rowBg,
			borderColor = strokeCol,
			borderThickness = (isLocal or rank == 1) and 2.5 or 1.2,
		})

		UiTheme.label({
			parent = row,
			position = UDim2.fromOffset(16, 0),
			size = UDim2.fromOffset(66, 62),
			text = "#" .. tostring(rank),
			font = "Number",
			textSize = 28,
			color = rank == 1 and C.GoldBright or (rank <= 3 and C.Gold or C.TextSecondary),
		})

		local pName = tostring(item.name or item.userId or "?")
		if isLocal then
			pName = pName .. " ★"
		end

		UiTheme.label({
			parent = row,
			position = UDim2.fromOffset(88, 0),
			size = UDim2.new(1, -240, 1, 0),
			text = pName,
			font = isLocal and "Bold" or "Header",
			textSize = 28,
			color = isLocal and C.GoldBright or C.TextPrimary,
			truncate = Enum.TextTruncate.AtEnd,
		})

		UiTheme.label({
			parent = row,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -18, 0, 0),
			size = UDim2.fromOffset(136, 62),
			text = tostring(item.value or 0),
			font = "Number",
			textSize = 30,
			color = boardName == "Coins" and C.Coins or C.GoldBright,
			alignX = Enum.TextXAlignment.Right,
		})
	end
end

local function attachBoard(part)
	if not part:IsA("BasePart") or activeBoards[part] then return end

	local old = part:FindFirstChild("LeaderboardSurfaceGui")
	if old then old:Destroy() end

	local sgui = Instance.new("SurfaceGui")
	sgui.Name = "LeaderboardSurfaceGui"
	sgui.Face = Enum.NormalId.Front
	sgui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sgui.CanvasSize = Vector2.new(640, 820)
	sgui.LightInfluence = 0.15
	sgui.Brightness = 1.4
	sgui.MaxDistance = 140
	sgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sgui.Adornee = part
	sgui.Parent = part

	local root = UiTheme.panel({
		name = "BoardRoot",
		parent = sgui,
		size = UDim2.fromScale(1, 1),
		bg = C.BgPrimary,
		borderColor = C.Gold,
		borderThickness = 3,
		ornaments = true,
		ornamentSize = 22,
	})

	activeBoards[part] = { gui = sgui, root = root }
	part:GetAttributeChangedSignal("Board"):Connect(function()
		renderBoard(part)
	end)
	renderBoard(part)
end

local function detachBoard(part)
	local entry = activeBoards[part]
	if entry then
		if entry.gui and entry.gui.Parent then entry.gui:Destroy() end
		activeBoards[part] = nil
	end
end

for _, inst in CollectionService:GetTagged("LeaderboardBoard") do
	attachBoard(inst)
end
CollectionService:GetInstanceAddedSignal("LeaderboardBoard"):Connect(attachBoard)
CollectionService:GetInstanceRemovedSignal("LeaderboardBoard"):Connect(detachBoard)

local function refreshAll()
	for part in activeBoards do
		renderBoard(part)
	end
end

L.Changed:Connect(refreshAll)

task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("Leaderboards", 20)
	if not folder then return end
	for _, ch in folder:GetChildren() do
		if ch:IsA("StringValue") then
			ch.Changed:Connect(refreshAll)
		end
	end
	folder.ChildAdded:Connect(function(ch)
		if ch:IsA("StringValue") then
			ch.Changed:Connect(refreshAll)
			refreshAll()
		end
	end)
	refreshAll()
end)
