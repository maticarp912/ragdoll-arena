-- LocalScript: StarterPlayerScripts/PartyUI
-- 11/11/2026: interfaz de la party de 2 (servidor: PartyService). Botón «Party» a la izquierda en el lobby:
-- lista de jugadores del servidor con «Invitar», tu compañero con «Salir», y el aviso de invitación con
-- Aceptar / Rechazar. Si sos el compañero (no el líder), se avisa que solo el líder busca partida.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Party", 20)
if not remote then return end

local C = UiTheme.Colors
local UI = { ButtonW = 132, ButtonH = 44, PanelW = 300, RowH = 46, MaxRows = 6, Left = 16, Top = 0.36 }

local gui = Instance.new("ScreenGui")
gui.Name = "PartyUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")

local panel -- lista abierta
local busy = false

local function call(action, arg)
	if busy then return false end
	busy = true
	local ok, success, reason = pcall(function() return remote:InvokeServer(action, arg) end)
	busy = false
	return ok and success, reason
end

local function nameOf(userId)
	local p = type(userId) == "number" and userId > 0 and Players:GetPlayerByUserId(userId)
	return p and p.DisplayName or ""
end

local openButton = UiTheme.button({
	name = "PartyButton",
	parent = gui,
	anchor = Vector2.new(0, 0.5),
	position = UDim2.new(0, UI.Left, UI.Top, 0),
	size = UDim2.fromOffset(UI.ButtonW, UI.ButtonH),
	text = L.t("ui.party.button"),
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
})

local statusLbl = UiTheme.label({
	parent = gui,
	anchor = Vector2.new(0, 0),
	position = UDim2.new(0, UI.Left, UI.Top, UI.ButtonH / 2 + 6),
	size = UDim2.fromOffset(260, 40),
	text = "", font = "Bold", textSize = UiTheme.TextSizes.SM, color = C.TextSecondary,
})
statusLbl.TextWrapped = true

local function closePanel()
	if panel then panel:Destroy() panel = nil end
end

local function openPanel()
	closePanel()
	local others = {}
	for _, p in Players:GetPlayers() do if p ~= player then table.insert(others, p) end end
	local partnerId = player:GetAttribute("PartyPartner") or 0
	local rows = math.min(#others, UI.MaxRows)
	local h = 64 + math.max(1, rows) * UI.RowH + (partnerId ~= 0 and UI.RowH or 0)
	panel = UiTheme.panel({
		name = "PartyPanel", parent = gui,
		anchor = Vector2.new(0, 0.5), position = UDim2.new(0, UI.Left + UI.ButtonW + 10, UI.Top, 0),
		size = UDim2.fromOffset(UI.PanelW, h), bg = C.BgPanel, borderColor = C.Gold,
	})
	UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 10), size = UDim2.new(1, -60, 0, 30),
		text = L.t("ui.party.title"), font = "Title", textSize = UiTheme.TextSizes.XL, color = C.GoldBright })
	UiTheme.button({ parent = panel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -8, 0, 8), size = UDim2.fromOffset(40, 40),
		text = "✕", onClick = closePanel })
	local y = 56
	if partnerId ~= 0 then
		UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, y), size = UDim2.new(1, -150, 0, UI.RowH - 6),
			text = L.t("ui.party.with", { name = nameOf(partnerId) }), font = "Bold", textSize = UiTheme.TextSizes.SM, color = C.Accent })
		UiTheme.button({ parent = panel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -10, 0, y), size = UDim2.fromOffset(120, UI.RowH - 6),
			text = L.t("ui.party.leave"), variant = "danger", textSize = UiTheme.TextSizes.SM,
			onClick = function() call("Leave") closePanel() end })
		y += UI.RowH
	end
	if #others == 0 then
		UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, y), size = UDim2.new(1, -28, 0, UI.RowH - 6),
			text = L.t("ui.party.empty"), font = "Body", textSize = UiTheme.TextSizes.SM, color = C.TextMuted })
	end
	for i = 1, rows do
		local p = others[i]
		UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, y), size = UDim2.new(1, -150, 0, UI.RowH - 6),
			text = p.DisplayName, font = "Bold", textSize = UiTheme.TextSizes.SM, color = C.TextPrimary })
		local canInvite = partnerId == 0 and (player:GetAttribute("PartyLeader") or 0) == 0
			or (player:GetAttribute("PartyLeader") == player.UserId and partnerId == 0)
		UiTheme.button({ parent = panel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -10, 0, y), size = UDim2.fromOffset(120, UI.RowH - 6),
			text = L.t("ui.party.invite"), variant = "gold", textSize = UiTheme.TextSizes.SM, disabled = not canInvite,
			onClick = function()
				local ok = call("Invite", p.UserId)
				statusLbl.Text = ok and L.t("ui.party.sent", { name = p.DisplayName }) or L.t("ui.party.failed")
			end })
		y += UI.RowH
	end
end

openButton.Activated:Connect(function()
	if panel then closePanel() else openPanel() end
end)

-- Aviso de invitación
local invitePanel
local function refreshInvite()
	if invitePanel then invitePanel:Destroy() invitePanel = nil end
	local from = player:GetAttribute("PartyInvite") or 0
	if from == 0 then return end
	invitePanel = UiTheme.panel({
		name = "PartyInvite", parent = gui,
		anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 0, 90),
		size = UDim2.fromOffset(360, 112), bg = C.BgPanel, borderColor = C.Accent,
	})
	UiTheme.label({ parent = invitePanel, position = UDim2.fromOffset(14, 10), size = UDim2.new(1, -28, 0, 40),
		text = L.t("ui.party.invited", { name = nameOf(from) }), font = "Bold", textSize = UiTheme.TextSizes.MD, color = C.TextPrimary })
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
	openButton.Text = partner ~= 0 and (L.t("ui.party.button") .. " · 2") or L.t("ui.party.button")
	if panel then openPanel() end
end

local function refreshVisible()
	local inMatch = player:GetAttribute("InMatch") == true
	openButton.Visible = not inMatch
	statusLbl.Visible = not inMatch
	if inMatch then closePanel() end
end

player:GetAttributeChangedSignal("PartyInvite"):Connect(refreshInvite)
player:GetAttributeChangedSignal("PartyLeader"):Connect(refreshStatus)
player:GetAttributeChangedSignal("PartyPartner"):Connect(refreshStatus)
player:GetAttributeChangedSignal("InMatch"):Connect(refreshVisible)
Players.PlayerAdded:Connect(function() if panel then openPanel() end end)
Players.PlayerRemoving:Connect(function() task.defer(function() if panel then openPanel() end end) end)
L.Changed:Connect(function() refreshStatus() refreshInvite() end)
refreshInvite() refreshStatus() refreshVisible()
