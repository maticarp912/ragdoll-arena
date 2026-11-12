-- LocalScript: StarterPlayerScripts/CallingCard
-- 11/11/2026: tarjeta de jugador estilo Call of Duty: título grande, nombre, rangos y nivel, con el color y
-- brillo de la rareza del título. Aparece:
--   · en la presentación de la partida (fase Cinematic): tu equipo a la izquierda, los rivales a la derecha;
--   · cuando te eliminan: la tarjeta de quien te eliminó, abajo al centro.
-- El título NO va sobre la cabeza (ahí solo nombre y rangos).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local Titles = require(ReplicatedStorage:WaitForChild("Titles"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))

local C = UiTheme.Colors
local CARD = {
	Width = 340, Height = 92, Gap = 10, Margin = 24,
	IntroSeconds = 3.6, KilledBySeconds = 3.2,
	SlideIn = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	SlideOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Ranks = { "Owner", "Admin", "Mod", "Tester" }, -- rangos que se muestran como [RANGO]
}

local gui = Instance.new("ScreenGui")
gui.Name = "CallingCards"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")

local function titleText(id)
	return Titles.text(id, L.language and L.language() or "ES", L.t)
end

-- [OWNER][VIP] con su color (texto enriquecido)
local function rankTags(p)
	local tags = {}
	local role = p:GetAttribute("Role")
	local ok, Roles = pcall(require, ReplicatedStorage:WaitForChild("Roles"))
	for _, r in CARD.Ranks do
		if role == r then
			local color = ok and Roles.Data and Roles.Data[r] and Roles.Data[r].color or C.GoldBright
			table.insert(tags, ('<font color="#%s">[%s]</font>'):format(color:ToHex(), UiTheme.upper(r)))
		end
	end
	if p:GetAttribute("Pass_VIP") == true then
		local color = ok and Roles.Data and Roles.Data.VIP and Roles.Data.VIP.color or C.Coins
		table.insert(tags, ('<font color="#%s">[VIP]</font>'):format(color:ToHex()))
	end
	return table.concat(tags, "")
end

local function escape(text)
	return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

local function buildCard(p, captionKey)
	local id = p:GetAttribute("Title") or ""
	local t = Titles.Data[id]
	local rarity = UiTheme.Rarities[(t and t.rarity) or "Common"] or UiTheme.Rarities.Common

	local card = Instance.new("Frame")
	card.Name = "Card_" .. p.Name
	card.Size = UDim2.fromOffset(CARD.Width, CARD.Height)
	card.BackgroundColor3 = C.BgPanel
	card.BorderSizePixel = 0
	UiTheme.corner(card, UiTheme.Radius.MD)
	UiTheme.stroke(card, rarity.color, rarity.stroke + 0.6, 0.05)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, rarity.bg),
		ColorSequenceKeypoint.new(0.55, C.BgPanel),
		ColorSequenceKeypoint.new(1, C.BgAbyss),
	})
	grad.Rotation = 8
	grad.Parent = card

	-- Franja de rareza a la izquierda (el «emblema» de la viñeta)
	local band = Instance.new("Frame")
	band.Size = UDim2.new(0, 10, 1, 0)
	band.BackgroundColor3 = rarity.color
	band.BorderSizePixel = 0
	band.Parent = card
	UiTheme.corner(band, UiTheme.Radius.SM)

	local caption = captionKey and UiTheme.label({
		parent = card, position = UDim2.fromOffset(22, 6), size = UDim2.new(1, -34, 0, 16),
		text = L.t(captionKey), font = "Bold", textSize = UiTheme.TextSizes.XS, color = C.TextMuted,
	})
	local top = caption and 20 or 8
	UiTheme.label({
		parent = card, position = UDim2.fromOffset(22, top), size = UDim2.new(1, -34, 0, 34),
		text = titleText(id) or L.t("title.none"), font = "Title", textSize = UiTheme.TextSizes.XL,
		color = t and rarity.color or C.TextSecondary,
	})
	local nameLbl = UiTheme.label({
		parent = card, position = UDim2.fromOffset(22, top + 36), size = UDim2.new(1, -34, 0, 24),
		text = "", font = "Bold", textSize = UiTheme.TextSizes.MD, color = C.TextPrimary,
	})
	nameLbl.RichText = true
	local level = p:GetAttribute("Level")
	nameLbl.Text = escape(p.DisplayName) .. " " .. rankTags(p)
		.. (level and ('  <font color="#%s">%s %d</font>'):format(C.TextMuted:ToHex(), L.t("ui.levelShort"), level) or "")
	return card
end

local function slide(card, from, to, seconds)
	card.Position = from
	card.Parent = gui
	TweenService:Create(card, CARD.SlideIn, { Position = to }):Play()
	task.delay(seconds, function()
		if not card.Parent then return end
		local t = TweenService:Create(card, CARD.SlideOut, { Position = from })
		t:Play()
		t.Completed:Wait()
		card:Destroy()
	end)
end

----------------------------------------------------------------------
-- Presentación de la partida: tu equipo a la izquierda, rivales a la derecha
----------------------------------------------------------------------
local function showIntro()
	local mine, theirs = {}, {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("InMatch") and p:GetAttribute("MatchPhase") == "Cinematic" then
			if p == player or (player.Team and p.Team == player.Team) then table.insert(mine, p) else table.insert(theirs, p) end
		end
	end
	for side, list in { left = mine, right = theirs } do
		for i, p in list do
			local card = buildCard(p, nil)
			local y = 0.62
			local offY = (i - 1) * (CARD.Height + CARD.Gap)
			if side == "left" then
				slide(card, UDim2.new(0, -CARD.Width - 20, y, offY), UDim2.new(0, CARD.Margin, y, offY), CARD.IntroSeconds)
			else
				card.AnchorPoint = Vector2.new(1, 0)
				slide(card, UDim2.new(1, CARD.Width + 20, y, offY), UDim2.new(1, -CARD.Margin, y, offY), CARD.IntroSeconds)
			end
		end
	end
end

player:GetAttributeChangedSignal("MatchPhase"):Connect(function()
	if player:GetAttribute("MatchPhase") == "Cinematic" then task.delay(0.3, showIntro) end
end)

----------------------------------------------------------------------
-- Te eliminaron: tarjeta de quien lo hizo
----------------------------------------------------------------------
player:GetAttributeChangedSignal("Eliminated"):Connect(function()
	if player:GetAttribute("Eliminated") ~= true then return end
	task.defer(function()
		local id = player:GetAttribute("EliminatedBy")
		local killer = type(id) == "number" and id > 0 and Players:GetPlayerByUserId(id)
		if not killer then return end
		local card = buildCard(killer, "ui.card.killedBy")
		card.AnchorPoint = Vector2.new(0.5, 1)
		slide(card, UDim2.new(0.5, 0, 1, CARD.Height + 20), UDim2.new(0.5, 0, 1, -150), CARD.KilledBySeconds)
	end)
end)
