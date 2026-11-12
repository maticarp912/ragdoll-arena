-- LocalScript: StarterPlayer/StarterPlayerScripts/MatchUI
-- Pantalla de resumen de fin de partida (Contratos C9 y C19: Remotes.MatchSummary, responsable: Gemini).
-- Mejoras 0.2 Ronda 2:
--   • Barra animada de experiencia pospartida (data.progression: xp, xpBefore, xpAfter, levelBefore, level, xpNext).
--   • Cartel e insignia festiva cuando el jugador sube de nivel (level > levelBefore).
--   • Desglose de Almas (D5, C24) con animación de almas doradas volando hacia el contador total.

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
local Device = require(ReplicatedStorage:WaitForChild("Device"))
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

local BASE_W, BASE_H = 600, 520
local card = UiTheme.panel({
	name = "SummaryCard",
	parent = veil,
	canvasGroup = true,
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.fromScale(0.5, 0.5),
	size = UDim2.fromOffset(BASE_W, BASE_H),
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

local function spawnFlyingSouls(parentCard, targetPos)
	for i = 1, 6 do
		task.delay((i - 1) * 0.08, function()
			if not parentCard.Parent or not veil.Visible then return end
			local orb = Instance.new("Frame")
			orb.Name = "SoulOrb_" .. i
			orb.AnchorPoint = Vector2.new(0.5, 0.5)
			orb.Position = UDim2.fromOffset(BASE_W * 0.5 + math.random(-90, 90), 210 + math.random(-20, 20))
			orb.Size = UDim2.fromOffset(14, 14)
			orb.BackgroundColor3 = C.GoldBright
			orb.BorderSizePixel = 0
			orb.ZIndex = 15
			orb.Parent = parentCard
			UiTheme.corner(orb, 7)
			UiTheme.stroke(orb, C.Coins, 1.5, 0)

			local tw = TweenService:Create(orb, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = targetPos,
				Size = UDim2.fromOffset(6, 6),
				BackgroundTransparency = 0.2,
			})
			tw:Play()
			task.delay(0.58, function()
				if orb.Parent then orb:Destroy() end
			end)
		end)
	end
end

local function renderSummary(data)
	lastSummary = data
	for _, ch in card:GetChildren() do
		if ch ~= scale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" and ch.Name ~= "FrameArt" then
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
	crestHolder.Position = UDim2.new(0.5, 0, 0, 14)
	crestHolder.Size = UDim2.fromOffset(58, 58)
	crestHolder.BackgroundColor3 = C.BgAbyss
	crestHolder.BorderSizePixel = 0
	crestHolder.Parent = card
	UiTheme.corner(crestHolder, 29)
	UiTheme.stroke(crestHolder, accent, 2, 0.05)

	local crestIcon = UiAssets.icon(crestHolder, won and "trophy" or "skull", 38, accent)
	crestIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	crestIcon.Position = UDim2.fromScale(0.5, 0.5)

	UiTheme.label({
		parent = card,
		position = UDim2.fromOffset(24, 76),
		size = UDim2.new(1, -48, 0, 36),
		text = L.t(won and "ui.match.victory" or "ui.match.defeat"),
		font = "Title",
		textSize = UiTheme.TextSizes.Hero,
		color = accent,
		alignX = Enum.TextXAlignment.Center,
	})

	UiTheme.label({
		parent = card,
		position = UDim2.fromOffset(24, 112),
		size = UDim2.new(1, -48, 0, 20),
		text = L.t("ui.match.mode", { mode = tostring(data.mode or "1v1") }),
		font = "Header",
		textSize = UiTheme.TextSizes.MD,
		color = C.TextSecondary,
		alignX = Enum.TextXAlignment.Center,
	})

	-- Tres tarjetas de estadísticas de combate: Eliminaciones, Derribos, Daño
	local statsRow = Instance.new("Frame")
	statsRow.Position = UDim2.fromOffset(28, 140)
	statsRow.Size = UDim2.new(1, -56, 0, 84)
	statsRow.BackgroundTransparency = 1
	statsRow.Parent = card

	local statSpecs = {
		{ icon = "skull", label = L.t("ui.match.kills"), value = tostring(math.floor(data.kills or 0)), color = C.Danger },
		{ icon = "knockdown", label = L.t("ui.match.knockdowns"), value = tostring(math.floor(data.knockdowns or 0)), color = C.Warning },
		{ icon = "heavy", label = L.t("ui.match.damage"), value = tostring(math.floor(data.damage or 0)), color = C.GoldBright },
	}
	local boxW = math.floor((BASE_W - 56 - 20) / 3)
	for i, st in statSpecs do
		local sBox = UiTheme.panel({
			parent = statsRow,
			position = UDim2.fromOffset((i - 1) * (boxW + 10), 0),
			size = UDim2.fromOffset(boxW, 84),
			bg = C.BgCard,
			borderColor = C.BorderDefault,
		})
		local ic = UiAssets.icon(sBox, st.icon, 22, st.color)
		ic.AnchorPoint = Vector2.new(0.5, 0)
		ic.Position = UDim2.new(0.5, 0, 0, 8)

		UiTheme.label({
			parent = sBox,
			position = UDim2.fromOffset(6, 34),
			size = UDim2.new(1, -12, 0, 26),
			text = st.value,
			font = "Number",
			textSize = UiTheme.TextSizes.XL,
			color = C.TextPrimary,
			alignX = Enum.TextXAlignment.Center,
		})
		UiTheme.label({
			parent = sBox,
			position = UDim2.fromOffset(6, 60),
			size = UDim2.new(1, -12, 0, 18),
			text = st.label,
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
		})
	end

	-- Progreso de Nivel y XP pospartida (Contrato C19: data.progression)
	local prog = type(data.progression) == "table" and data.progression or {}
	local xpGained = math.floor(tonumber(prog.xp) or 0)
	local levelBefore = math.floor(tonumber(prog.levelBefore) or tonumber(player:GetAttribute("Level")) or 1)
	local levelAfter = math.floor(tonumber(prog.level) or tonumber(player:GetAttribute("Level")) or levelBefore)
	local xpBefore = math.max(0, tonumber(prog.xpBefore) or tonumber(player:GetAttribute("XP")) or 0)
	local xpAfter = math.max(0, tonumber(prog.xpAfter) or tonumber(player:GetAttribute("XP")) or xpBefore)
	local xpNext = math.max(1, tonumber(prog.xpNext) or tonumber(player:GetAttribute("XPNext")) or 150)
	local leveledUp = levelAfter > levelBefore
	local friendBonus = math.floor((tonumber(data.friendBonus) or 0) * 100 + 0.5)

	local progPanel = UiTheme.panel({
		name = "ProgressionPanel",
		parent = card,
		position = UDim2.fromOffset(28, 234),
		size = UDim2.new(1, -56, 0, 92),
		bg = C.BgCard,
		borderColor = leveledUp and C.GoldBright or C.GoldDim,
	})
	local progStroke = progPanel:FindFirstChildOfClass("UIStroke")

	local lvlLbl = UiTheme.label({
		parent = progPanel,
		position = UDim2.fromOffset(16, 8),
		size = UDim2.fromOffset(160, 24),
		text = L.t("ui.hud.level", { level = levelBefore }),
		font = "Title",
		textSize = UiTheme.TextSizes.LG,
		color = C.GoldBright,
	})

	UiTheme.label({
		parent = progPanel,
		anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -16, 0, 8),
		size = UDim2.fromOffset(220, 24),
		text = L.t("ui.match.xpEarned", { xp = xpGained }),
		font = "Number",
		textSize = UiTheme.TextSizes.SM,
		color = C.Success,
		alignX = Enum.TextXAlignment.Right,
	})

	local startFrac = math.clamp(xpBefore / xpNext, 0, 1)
	local endFrac = math.clamp(xpAfter / xpNext, 0, 1)
	local xpBarBg, xpBarFill = UiTheme.progressBar({
		parent = progPanel,
		position = UDim2.fromOffset(16, 38),
		size = UDim2.new(1, -32, 0, 18),
		fraction = startFrac,
		fillColor = C.Gold,
		showText = true,
		text = L.t("ui.hud.xp", { xp = math.floor(xpAfter), next = math.floor(xpNext) }),
	})
	xpBarBg.Name = "MatchXPBar"

	local levelUpBanner = UiTheme.label({
		name = "LevelUpBanner",
		parent = progPanel,
		position = UDim2.fromOffset(16, 62),
		size = UDim2.new(friendBonus > 0 and 0.48 or 1, -32, 0, 22),
		text = leveledUp and L.t("ui.match.levelUp", { level = levelAfter }) or "",
		font = "Title",
		textSize = UiTheme.TextSizes.MD,
		color = C.GoldBright,
		alignX = Enum.TextXAlignment.Center,
	})

	if friendBonus > 0 then
		UiTheme.label({ parent = progPanel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -16, 0, 62),
			size = UDim2.new(0.55, -16, 0, 22), text = L.t("mz.friendBonus", { percent = friendBonus }),
			textSize = UiTheme.TextSizes.SM, scaled = true, color = C.Accent, alignX = Enum.TextXAlignment.Right })
	end

	-- Animación de llenado de la barra de XP y festejo de subida de nivel
	task.delay(0.22, function()
		if not xpBarFill.Parent then return end
		if leveledUp then
			local tw1 = TweenService:Create(xpBarFill, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(1, 1),
			})
			tw1:Play()
			task.delay(0.48, function()
				if not xpBarFill.Parent then return end
				lvlLbl.Text = L.t("ui.hud.level", { level = levelAfter })
				UiTheme.playSound("UI_PurchaseOK")
				if progStroke then
					progStroke.Thickness = 2.6
					progStroke.Color = C.GoldBright
				end
				xpBarFill.Size = UDim2.fromScale(0, 1)
				TweenService:Create(xpBarFill, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromScale(endFrac, 1),
				}):Play()
			end)
		else
			TweenService:Create(xpBarFill, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(endFrac, 1),
			}):Play()
		end
	end)

	-- Desglose de Almas (Partida, Misiones y Total — D5, C24)
	local coinsData = type(data.coins) == "table" and data.coins or {}
	local matchCoins = math.floor(coinsData.match or 0)
	local missionCoins = math.floor((coinsData.missions and coinsData.missions > 0 and coinsData.missions) or data.missionCoinsAvailable or 0)
	local totalCoins = math.floor(coinsData.total or matchCoins)

	local rewardPanel = UiTheme.panel({
		parent = card,
		position = UDim2.fromOffset(28, 336),
		size = UDim2.new(1, -56, 0, 102),
		bg = C.BgPanel,
		borderColor = C.GoldDim,
	})

	local function soulLine(y, title, amount, highlight)
		UiTheme.label({
			parent = rewardPanel,
			position = UDim2.fromOffset(16, y),
			size = UDim2.new(0.62, -16, 0, 24),
			text = title,
			font = highlight and "Bold" or "Body",
			textSize = highlight and UiTheme.TextSizes.MD or UiTheme.TextSizes.SM,
			color = highlight and C.GoldBright or C.TextSecondary,
		})
		UiTheme.label({
			parent = rewardPanel,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -16, 0, y),
			size = UDim2.fromOffset(180, 24),
			text = "+" .. L.t("ui.souls", { amount = amount }),
			font = "Number",
			textSize = highlight and UiTheme.TextSizes.MD or UiTheme.TextSizes.SM,
			color = C.Coins,
			alignX = Enum.TextXAlignment.Right,
		})
	end

	soulLine(10, L.t("ui.match.coinsMatch"), matchCoins, false)
	soulLine(38, L.t("ui.match.coinsMissions"), missionCoins, false)
	soulLine(68, L.t("ui.match.coinsTotal"), totalCoins, true)

	if totalCoins > 0 then
		spawnFlyingSouls(card, UDim2.fromOffset(BASE_W - 76, 336 + 78))
	end

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
	if Device.isGamepad() then
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
		scale.Scale = UiTheme.computeScale(cam.ViewportSize, BASE_W + 40, BASE_H + 40, player)
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
		scale.Scale = UiTheme.computeScale(workspace.CurrentCamera.ViewportSize, BASE_W + 40, BASE_H + 40, player)
	end
end)

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
	local summaryRemote = remotes and remotes:WaitForChild("MatchSummary", 15)
	if summaryRemote and summaryRemote:IsA("RemoteEvent") then
		summaryRemote.OnClientEvent:Connect(showSummary)
	end
end)
