-- LocalScript: StarterPlayer/StarterPlayerScripts/MatchUI
-- Pantalla de resumen de fin de partida (Contrato C9: Remotes.MatchSummary, responsable: Gemini, etapa 8).
-- Muestra resultado (Victoria / Derrota), modo (1v1 / 2v2), eliminaciones, derribos, daño infligido,
-- desglose de monedas ganadas y de misiones, con navegación completa para mando y ratón.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))

local player = Players.LocalPlayer
local C = UiTheme.Colors

local gui = Instance.new("ScreenGui")
gui.Name = "MatchSummaryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 18
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local veil = Instance.new("TextButton")
veil.Name = "SummaryVeil"
veil.Size = UDim2.fromScale(1, 1)
veil.BackgroundColor3 = C.BgModalVeil
veil.BackgroundTransparency = 0.25
veil.Text = ""
veil.AutoButtonColor = false
veil.Selectable = false
veil.Visible = false
veil.Parent = gui

local card = UiTheme.panel({
	name = "SummaryCard",
	parent = veil,
	canvasGroup = true,
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.fromScale(0.5, 0.5),
	size = UDim2.fromOffset(580, 440),
	bg = C.BgPrimary,
	borderColor = C.Gold,
	borderThickness = UiTheme.Stroke.Heavy,
	ornaments = true,
	ornamentSize = 18,
})
local scale = Instance.new("UIScale")
scale.Parent = card

local lastSummary = nil
local closeSummary

local function renderSummary(data)
	lastSummary = data
	for _, ch in card:GetChildren() do
		if ch ~= scale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
			ch:Destroy()
		end
	end

	local won = data.result == "Win"
	local accent = won and C.GoldBright or C.Danger
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = accent end

	-- Medallón superior (Trofeo en Victoria, Calavera en Derrota)
	local crestHolder = Instance.new("Frame")
	crestHolder.AnchorPoint = Vector2.new(0.5, 0)
	crestHolder.Position = UDim2.new(0.5, 0, 0, 18)
	crestHolder.Size = UDim2.fromOffset(64, 64)
	crestHolder.BackgroundColor3 = C.BgAbyss
	crestHolder.BorderSizePixel = 0
	crestHolder.Parent = card
	UiTheme.corner(crestHolder, 32)
	UiTheme.stroke(crestHolder, accent, 2, 0.05)

	local crestIcon = UiAssets.icon(crestHolder, won and "trophy" or "skull", 42, accent)
	crestIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	crestIcon.Position = UDim2.fromScale(0.5, 0.5)

	UiTheme.label({
		parent = card,
		position = UDim2.fromOffset(24, 88),
		size = UDim2.new(1, -48, 0, 40),
		text = L.t(won and "ui.match.victory" or "ui.match.defeat"),
		font = "Title",
		textSize = UiTheme.TextSizes.Hero,
		color = accent,
		alignX = Enum.TextXAlignment.Center,
	})

	UiTheme.label({
		parent = card,
		position = UDim2.fromOffset(24, 128),
		size = UDim2.new(1, -48, 0, 22),
		text = L.t("ui.match.mode", { mode = tostring(data.mode or "1v1") }),
		font = "Header",
		textSize = UiTheme.TextSizes.MD,
		color = C.TextSecondary,
		alignX = Enum.TextXAlignment.Center,
	})

	-- Tres tarjetas de estadísticas de combate: Eliminaciones, Derribos, Daño
	local statsRow = Instance.new("Frame")
	statsRow.Position = UDim2.fromOffset(28, 162)
	statsRow.Size = UDim2.new(1, -56, 0, 92)
	statsRow.BackgroundTransparency = 1
	statsRow.Parent = card

	local statSpecs = {
		{ icon = "skull", label = L.t("ui.match.kills"), value = tostring(math.floor(data.kills or 0)), color = C.Danger },
		{ icon = "knockdown", label = L.t("ui.match.knockdowns"), value = tostring(math.floor(data.knockdowns or 0)), color = C.Warning },
		{ icon = "heavy", label = L.t("ui.match.damage"), value = tostring(math.floor(data.damage or 0)), color = C.GoldBright },
	}
	local boxW = math.floor((580 - 56 - 20) / 3)
	for i, st in statSpecs do
		local sBox = UiTheme.panel({
			parent = statsRow,
			position = UDim2.fromOffset((i - 1) * (boxW + 10), 0),
			size = UDim2.fromOffset(boxW, 92),
			bg = C.BgCard,
			borderColor = C.BorderDefault,
		})
		local ic = UiAssets.icon(sBox, st.icon, 24, st.color)
		ic.AnchorPoint = Vector2.new(0.5, 0)
		ic.Position = UDim2.new(0.5, 0, 0, 10)

		UiTheme.label({
			parent = sBox,
			position = UDim2.fromOffset(6, 38),
			size = UDim2.new(1, -12, 0, 28),
			text = st.value,
			font = "Number",
			textSize = UiTheme.TextSizes.XL,
			color = C.TextPrimary,
			alignX = Enum.TextXAlignment.Center,
		})
		UiTheme.label({
			parent = sBox,
			position = UDim2.fromOffset(6, 66),
			size = UDim2.new(1, -12, 0, 18),
			text = st.label,
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
		})
	end

	-- Desglose de monedas (Partida, Misiones y Total)
	local coinsData = type(data.coins) == "table" and data.coins or {}
	local matchCoins = math.floor(coinsData.match or 0)
	local missionCoins = math.floor((coinsData.missions and coinsData.missions > 0 and coinsData.missions) or data.missionCoinsAvailable or 0)
	local totalCoins = math.floor(coinsData.total or matchCoins)

	local rewardPanel = UiTheme.panel({
		parent = card,
		position = UDim2.fromOffset(28, 266),
		size = UDim2.new(1, -56, 0, 96),
		bg = C.BgPanel,
		borderColor = C.GoldDim,
	})

	local function coinLine(y, title, amount, highlight)
		UiTheme.label({
			parent = rewardPanel,
			position = UDim2.fromOffset(16, y),
			size = UDim2.new(0.65, -16, 0, 24),
			text = title,
			font = highlight and "Bold" or "Body",
			textSize = highlight and UiTheme.TextSizes.MD or UiTheme.TextSizes.SM,
			color = highlight and C.GoldBright or C.TextSecondary,
		})
		UiTheme.label({
			parent = rewardPanel,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -16, 0, y),
			size = UDim2.fromOffset(160, 24),
			text = "+" .. L.t("Coins", { amount = amount }),
			font = "Number",
			textSize = highlight and UiTheme.TextSizes.MD or UiTheme.TextSizes.SM,
			color = C.Coins,
			alignX = Enum.TextXAlignment.Right,
		})
	end

	coinLine(10, L.t("ui.match.coinsMatch"), matchCoins, false)
	coinLine(36, L.t("ui.match.coinsMissions"), missionCoins, false)
	coinLine(64, L.t("ui.match.coinsTotal"), totalCoins, true)

	local continueBtn = UiTheme.button({
		name = "ContinueBtn",
		parent = card,
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -16),
		size = UDim2.fromOffset(220, 44),
		text = L.t("ui.match.continue"),
		font = "Header",
		textSize = UiTheme.TextSizes.LG,
		variant = "gold",
		onClick = function()
			closeSummary()
		end,
	})

	UiTheme.trapGamepadFocus("MatchSummaryModalGroup", { continueBtn })
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = continueBtn
	end
end

function closeSummary()
	if not veil.Visible then return end
	UiTheme.releaseGamepadFocus("MatchSummaryModalGroup")
	UiTheme.playSound("UI_MenuClose")
	TweenService:Create(card, UiTheme.Anim.TweenFast, { GroupTransparency = 1 }):Play()
	task.delay(0.14, function()
		veil.Visible = false
		GuiService.SelectedObject = nil
	end)
end

local function showSummary(data)
	if type(data) ~= "table" then return end
	local cam = workspace.CurrentCamera
	if cam then
		scale.Scale = UiTheme.computeScale(cam.ViewportSize, 620, 480, player)
	end
	veil.Visible = true
	card.GroupTransparency = 1
	card.Position = UDim2.fromScale(0.5, 0.54)
	renderSummary(data)
	UiTheme.playSound(data.result == "Win" and "UI_PurchaseOK" or "UI_MenuOpen")
	TweenService:Create(card, UiTheme.Anim.TweenNorm, {
		GroupTransparency = 0,
		Position = UDim2.fromScale(0.5, 0.5),
	}):Play()
end

UserInputService.InputBegan:Connect(function(input, processed)
	-- B del mando cierra aunque venga marcado como procesado (la selección de la GUI lo marca así)
	if veil.Visible and (input.KeyCode == Enum.KeyCode.ButtonB or (not processed and input.KeyCode == Enum.KeyCode.Escape)) then
		closeSummary()
	end
end)

L.Changed:Connect(function()
	if veil.Visible and lastSummary then
		renderSummary(lastSummary)
	end
end)

RunService.Heartbeat:Connect(function()
	if veil.Visible and workspace.CurrentCamera then
		scale.Scale = UiTheme.computeScale(workspace.CurrentCamera.ViewportSize, 620, 480, player)
	end
end)

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
	local summaryRemote = remotes and remotes:WaitForChild("MatchSummary", 15)
	if summaryRemote and summaryRemote:IsA("RemoteEvent") then
		summaryRemote.OnClientEvent:Connect(showSummary)
	end
end)
