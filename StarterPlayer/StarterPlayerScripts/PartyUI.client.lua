-- LocalScript: StarterPlayerScripts/PartyUI
-- 11/11/2026: party de 2 (servidor: PartyService). Va dentro de la barra de partidas (QueueBar de LobbyUI), a la
-- al lado de la cola: tu foto y la de tu compañero, o un «+» para invitar.
-- Al tocar «+» se abre la lista de jugadores del servidor, con tus amigos de Roblox arriba de todo.
-- Al tocar la foto de tu compañero: salir de la party. Aviso de invitación con Aceptar / Rechazar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Party", 20)
if not remote then return end

local C = UiTheme.Colors
local UI = {
	Avatar = 38, SlotGap = 6, WidgetPad = 6, LayoutOrder = 10,
	PanelW = 320, RowH = 50, MaxRows = 7, PanelAboveBar = 12,
}

local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "PartyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9
gui.Parent = playerGui

local busy = false
local function call(action, arg)
	if busy then return false end
	busy = true
	local ok, success, reason = pcall(function() return remote:InvokeServer(action, arg) end)
	busy = false
	return ok and success, reason
end

local thumbs = {}
local function thumb(userId)
	if thumbs[userId] == nil then
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		thumbs[userId] = ok and url or ""
	end
	return thumbs[userId]
end

local friends = {}
local function isFriend(userId)
	if friends[userId] == nil then
		local ok, yes = pcall(function() return player:IsFriendsWith(userId) end)
		friends[userId] = ok and yes == true
	end
	return friends[userId]
end

local function nameOf(userId)
	local p = type(userId) == "number" and userId > 0 and Players:GetPlayerByUserId(userId)
	return p and p.DisplayName or ""
end

local function avatarCircle(parent, userId, size)
	local img = Instance.new("ImageButton")
	img.Size = UDim2.fromOffset(size, size)
	img.BackgroundColor3 = C.BgPreview
	img.BorderSizePixel = 0
	img.AutoButtonColor = false
	img.Image = userId and userId > 0 and thumb(userId) or ""
	img.Parent = parent
	UiTheme.corner(img, size)
	local portrait = UiAssets.imageUri("frame_avatar")
	if portrait then
		local rim = Instance.new("ImageLabel")
		rim.Name = "SilverPortrait"
		rim.BackgroundTransparency = 1
		rim.Size = UDim2.fromScale(1, 1)
		rim.Image = portrait
		rim.Parent = img
	else
		UiTheme.stroke(img, C.Gold, 1.5, 0.15)
	end
	return img
end

----------------------------------------------------------------------
-- Widget dentro de la barra de partidas
----------------------------------------------------------------------
local widget, mySlot, friendSlot
local panel, invitePanel

local function closePanel() if panel then panel:Destroy() panel = nil end end

local openPanel -- se define abajo

local function buildWidget(bar)
	if widget then widget:Destroy() end
	widget = Instance.new("Frame")
	widget.Name = "PartySlots"
	widget.LayoutOrder = UI.LayoutOrder
	widget.Size = UDim2.fromOffset(UI.Avatar * 2 + UI.SlotGap + UI.WidgetPad * 2, UI.Avatar + UI.WidgetPad)
	widget.BackgroundColor3 = C.BgCard
	widget.BorderSizePixel = 0
	widget.Parent = bar
	UiTheme.corner(widget, UiTheme.Radius.MD)
	UiTheme.stroke(widget, C.BorderDefault, 1.2, 0.2)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, UI.SlotGap)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = widget

	mySlot = avatarCircle(widget, player.UserId, UI.Avatar)
	mySlot.LayoutOrder = 1
	friendSlot = avatarCircle(widget, nil, UI.Avatar)
	friendSlot.LayoutOrder = 2
	local plus = Instance.new("TextLabel")
	plus.Name = "Plus"
	plus.Size = UDim2.fromScale(1, 1)
	plus.BackgroundTransparency = 1
	plus.Text = "+"
	plus.TextColor3 = C.GoldBright
	plus.TextSize = 28
	plus.Parent = friendSlot
	UiTheme.applyFont(plus, "Bold")
	friendSlot.Activated:Connect(function()
		if panel then closePanel() else openPanel() end
	end)
end

local function refreshWidget()
	if not friendSlot then return end
	local partner = player:GetAttribute("PartyPartner") or 0
	friendSlot.Image = partner ~= 0 and thumb(partner) or ""
	local plus = friendSlot:FindFirstChild("Plus")
	if plus then plus.Visible = partner == 0 end
end

-- Encuentra la barra de partidas de LobbyUI y se mete adentro (vuelve a intentar si LobbyUI la rehace)
task.spawn(function()
	while gui.Parent do
		local lobby = playerGui:FindFirstChild("LobbyGui")
		local bar = lobby and lobby:FindFirstChild("QueueBar", true)
		if bar and (not widget or widget.Parent ~= bar) then
			buildWidget(bar)
			refreshWidget()
		end
		task.wait(1)
	end
end)

----------------------------------------------------------------------
-- Lista para invitar (amigos arriba de todo)
----------------------------------------------------------------------
local statusLbl

function openPanel()
	closePanel()
	if not widget then return end
	local partnerId = player:GetAttribute("PartyPartner") or 0
	local others = {}
	for _, p in Players:GetPlayers() do if p ~= player then table.insert(others, p) end end
	table.sort(others, function(a, b)
		local fa, fb = isFriend(a.UserId), isFriend(b.UserId)
		if fa ~= fb then return fa end
		return a.DisplayName < b.DisplayName
	end)
	local rows = math.min(#others, UI.MaxRows)
	local h = 58 + math.max(1, rows) * UI.RowH + (partnerId ~= 0 and UI.RowH or 0) + 8
	local wp, ws = widget.AbsolutePosition, widget.AbsoluteSize
	panel = UiTheme.panel({
		name = "PartyPanel", parent = gui,
		anchor = Vector2.new(0.5, 1),
		position = UDim2.fromOffset(wp.X + ws.X / 2, wp.Y + game:GetService("GuiService"):GetGuiInset().Y - UI.PanelAboveBar),
		size = UDim2.fromOffset(UI.PanelW, h), bg = C.BgPanel, borderColor = C.Gold,
	})
	UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 10), size = UDim2.new(1, -64, 0, 30),
		text = L.t("ui.party.title"), font = "Title", textSize = UiTheme.TextSizes.XL, color = C.GoldBright })
	UiTheme.button({ parent = panel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -8, 0, 8), size = UDim2.fromOffset(40, 40),
		text = "✕", onClick = closePanel })
	local y = 56
	local function row(p, userId, rightText, variant, onClick, disabled, tag)
		local av = avatarCircle(panel, userId, UI.RowH - 12)
		av.Position = UDim2.fromOffset(14, y + 6)
		local lbl = UiTheme.label({ parent = panel, position = UDim2.fromOffset(14 + UI.RowH, y), size = UDim2.new(1, -(150 + UI.RowH), 0, UI.RowH),
			text = (p and p.DisplayName or nameOf(userId)) .. (tag and ("  ·  " .. tag) or ""), font = "Bold",
			textSize = UiTheme.TextSizes.SM, color = tag and C.Accent or C.TextPrimary })
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		UiTheme.button({ parent = panel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -10, 0, y + 6), size = UDim2.fromOffset(116, UI.RowH - 12),
			text = rightText, variant = variant, textSize = UiTheme.TextSizes.SM, disabled = disabled, onClick = onClick })
		y += UI.RowH
	end
	if partnerId ~= 0 then
		row(nil, partnerId, L.t("ui.party.leave"), "danger", function() call("Leave") closePanel() end, false, L.t("ui.party.partner"))
	end
	if #others == 0 then
		UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, y), size = UDim2.new(1, -28, 0, UI.RowH),
			text = L.t("ui.party.empty"), font = "Body", textSize = UiTheme.TextSizes.SM, color = C.TextMuted })
	end
	local leader = player:GetAttribute("PartyLeader") or 0
	local canInvite = partnerId == 0 and (leader == 0 or leader == player.UserId)
	for i = 1, rows do
		local p = others[i]
		if p.UserId ~= partnerId then
			row(p, p.UserId, L.t("ui.party.invite"), "gold", function()
				local ok = call("Invite", p.UserId)
				if statusLbl then statusLbl.Text = ok and L.t("ui.party.sent", { name = p.DisplayName }) or L.t("ui.party.failed") end
			end, not canInvite, isFriend(p.UserId) and L.t("ui.party.friend") or nil)
		end
	end
end

----------------------------------------------------------------------
-- Aviso de invitación y estado
----------------------------------------------------------------------
statusLbl = UiTheme.label({
	parent = gui, anchor = Vector2.new(0.5, 1), position = UDim2.new(0.5, 0, 1, -96),
	size = UDim2.fromOffset(520, 24), text = "", font = "Bold", textSize = UiTheme.TextSizes.SM, color = C.TextSecondary,
	alignX = Enum.TextXAlignment.Center,
})

local function refreshInvite()
	if invitePanel then invitePanel:Destroy() invitePanel = nil end
	local from = player:GetAttribute("PartyInvite") or 0
	if from == 0 then return end
	invitePanel = UiTheme.panel({
		name = "PartyInvite", parent = gui,
		anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 0, 90),
		size = UDim2.fromOffset(380, 116), bg = C.BgPanel, borderColor = C.Accent,
	})
	local av = avatarCircle(invitePanel, from, 48)
	av.Position = UDim2.fromOffset(14, 12)
	UiTheme.label({ parent = invitePanel, position = UDim2.fromOffset(72, 10), size = UDim2.new(1, -86, 0, 52),
		text = L.t("ui.party.invited", { name = nameOf(from) }), font = "Bold", textSize = UiTheme.TextSizes.MD, color = C.TextPrimary }).TextWrapped = true
	UiTheme.button({ parent = invitePanel, position = UDim2.new(0, 14, 1, -54), size = UDim2.new(0.5, -20, 0, 44),
		text = L.t("ui.party.accept"), variant = "gold", onClick = function() call("Accept") end })
	UiTheme.button({ parent = invitePanel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -14, 1, -54), size = UDim2.new(0.5, -20, 0, 44),
		text = L.t("ui.party.decline"), onClick = function() call("Decline") end })
end

local function refreshStatus()
	local leader = player:GetAttribute("PartyLeader") or 0
	local partner = player:GetAttribute("PartyPartner") or 0
	if partner ~= 0 and leader ~= player.UserId then
		statusLbl.Text = L.t("ui.party.leaderOnly", { name = nameOf(leader) })
	elseif partner ~= 0 then
		statusLbl.Text = L.t("ui.party.with", { name = nameOf(partner) })
	else
		statusLbl.Text = ""
	end
	refreshWidget()
	if panel then openPanel() end
end

local function refreshVisible()
	local inMatch = player:GetAttribute("InMatch") == true
	local inTutorial = player:GetAttribute("InTutorial") == true
	gui.Enabled = not inTutorial
	statusLbl.Visible = not inMatch
	if inMatch or inTutorial then closePanel() end
end

player:GetAttributeChangedSignal("PartyInvite"):Connect(refreshInvite)
player:GetAttributeChangedSignal("PartyLeader"):Connect(refreshStatus)
player:GetAttributeChangedSignal("PartyPartner"):Connect(refreshStatus)
player:GetAttributeChangedSignal("InMatch"):Connect(refreshVisible)
player:GetAttributeChangedSignal("InTutorial"):Connect(refreshVisible)
Players.PlayerAdded:Connect(function() if panel then openPanel() end end)
Players.PlayerRemoving:Connect(function() task.defer(function() if panel then openPanel() end end) end)
L.Changed:Connect(function() refreshStatus() refreshInvite() end)
refreshInvite() refreshStatus() refreshVisible()
