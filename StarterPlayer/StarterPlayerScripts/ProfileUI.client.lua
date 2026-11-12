-- LocalScript: StarterPlayer/StarterPlayerScripts/ProfileUI
-- 12/11/2026 (Claude, pedido del usuario): pantalla de Perfil.
--   Arriba: retrato, título actual, nivel y victorias / derrotas / porcentaje de victorias / partidas.
--   Izquierda: las 3 armas más usadas (partidas y % de victorias con cada una; cuentan desde la 0.3).
--   Derecha: estadísticas generales (bajas, derribos, parries, caídas al vacío, patadas, remates...).
-- Se abre con el botón Perfil del lobby (atributo ProfileOpen). Los datos son atributos que publica el servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local Titles = require(ReplicatedStorage:WaitForChild("Titles"))

local C = UiTheme.Colors
local player = Players.LocalPlayer
local W, H = 860, 560

local gui = Instance.new("ScreenGui")
gui.Name = "ProfileGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local veil = Instance.new("TextButton")
veil.Name = "Veil"
veil.Text = ""
veil.AutoButtonColor = false
veil.Size = UDim2.fromScale(1, 1)
veil.BackgroundColor3 = C.BgModalVeil
veil.BackgroundTransparency = 0.35
veil.BorderSizePixel = 0
veil.Parent = gui
veil.Activated:Connect(function() player:SetAttribute("ProfileOpen", false) end)

local panel = UiTheme.panel({ name = "Profile", parent = gui, anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.5),
	size = UDim2.fromOffset(W, H), bg = C.BgPrimary, ornaments = true, ornamentSize = 16 })
local scale = Instance.new("UIScale")
scale.Parent = panel

local function stat(name)
	return tonumber(player:GetAttribute("Stat" .. name)) or 0
end
local function ratio(a, b)
	if b <= 0 then return a > 0 and string.format("%.2f", a) or "0.00" end
	return string.format("%.2f", a / b)
end

local function box(parent, pos, size)
	local f = Instance.new("Frame")
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = C.BgPanel
	f.BackgroundTransparency = 0.15
	f.BorderSizePixel = 0
	f.Parent = parent
	UiTheme.corner(f, UiTheme.Radius.SM)
	UiTheme.stroke(f, C.BorderDefault, 1, 0.3)
	return f
end

local function numberCell(parent, x, y, w, label, value, big)
	UiTheme.label({ parent = parent, position = UDim2.fromOffset(x, y), size = UDim2.fromOffset(w, 18), text = label,
		font = "Body", textSize = UiTheme.TextSizes.XS, color = C.TextSecondary, alignX = Enum.TextXAlignment.Center })
	UiTheme.label({ parent = parent, position = UDim2.fromOffset(x, y + 18), size = UDim2.fromOffset(w, big and 34 or 26), text = value,
		font = "Number", textSize = big and UiTheme.TextSizes.XL or UiTheme.TextSizes.LG, color = C.TextPrimary,
		alignX = Enum.TextXAlignment.Center })
end

local function render()
	for _, ch in panel:GetChildren() do
		if ch ~= scale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient")
			and ch.Name ~= "Ornaments" and ch.Name ~= "FrameArt" then
			ch:Destroy()
		end
	end

	-- Cabecera
	local icon = UiAssets.icon(panel, "trophy", 30, C.GoldBright)
	icon.Position = UDim2.fromOffset(28, 22)
	UiTheme.label({ parent = panel, position = UDim2.fromOffset(68, 18), size = UDim2.fromOffset(400, 40), text = L.t("pf.title"),
		font = "Title", textSize = UiTheme.TextSizes.XL, color = C.TextPrimary })
	local close = UiTheme.button({ name = "Close", parent = panel, anchor = Vector2.new(1, 0), position = UDim2.new(1, -22, 0, 18),
		size = UDim2.fromOffset(44, 44), text = "✕", variant = "danger", onClick = function() player:SetAttribute("ProfileOpen", false) end })
	local sep = Instance.new("Frame")
	sep.Position = UDim2.fromOffset(28, 72)
	sep.Size = UDim2.new(1, -56, 0, 1)
	sep.BackgroundColor3 = C.BorderDefault
	sep.BorderSizePixel = 0
	sep.Parent = panel

	-- Tarjeta superior: retrato, título, nivel y números principales
	local top = box(panel, UDim2.fromOffset(28, 86), UDim2.new(1, -56, 0, 108))
	local portrait = Instance.new("ImageLabel")
	portrait.Position = UDim2.fromOffset(14, 14)
	portrait.Size = UDim2.fromOffset(80, 80)
	portrait.BackgroundColor3 = C.BgAbyss
	portrait.Parent = top
	UiTheme.corner(portrait, 40)
	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		if ok and portrait.Parent then portrait.Image = url end
	end)
	local titleId = player:GetAttribute("Title")
	local titleText = type(titleId) == "string" and titleId ~= "" and Titles.text(titleId, player:GetAttribute("Language"), L.t) or L.t("pf.noTitle")
	UiTheme.label({ parent = top, position = UDim2.fromOffset(110, 16), size = UDim2.fromOffset(260, 22), text = player.DisplayName,
		font = "Header", textSize = UiTheme.TextSizes.LG, color = C.TextPrimary })
	UiTheme.label({ parent = top, position = UDim2.fromOffset(110, 40), size = UDim2.fromOffset(260, 22), text = titleText,
		font = "Title", textSize = UiTheme.TextSizes.MD, color = C.GoldBright })
	UiTheme.label({ parent = top, position = UDim2.fromOffset(110, 64), size = UDim2.fromOffset(260, 22),
		text = L.t("ui.hud.level", { level = player:GetAttribute("Level") or 1 }), font = "Bold", textSize = UiTheme.TextSizes.SM,
		color = C.TextSecondary })
	local wins, matches = stat("Wins"), stat("Matches")
	local losses = math.max(0, matches - wins)
	local cells = { { L.t("pf.wins"), tostring(wins) }, { L.t("pf.losses"), tostring(losses) },
		{ L.t("pf.wl"), ratio(wins, losses) }, { L.t("pf.total"), tostring(matches) } }
	for i, c in cells do
		numberCell(top, 390 + (i - 1) * 100, 22, 96, c[1], c[2], true)
	end

	-- Armas más usadas
	UiTheme.label({ parent = panel, position = UDim2.fromOffset(28, 206), size = UDim2.fromOffset(380, 24), text = L.t("pf.topWeapons"),
		font = "Header", textSize = UiTheme.TextSizes.MD, color = C.TextSecondary })
	local list = {}
	for entry in string.gmatch(player:GetAttribute("WeaponStats") or "", "[^,]+") do
		local wid, games, won = entry:match("^(%w+):(%d+):(%d+)$")
		if wid then table.insert(list, { id = wid, games = tonumber(games), wins = tonumber(won) }) end
	end
	table.sort(list, function(a, b) return a.games > b.games end)
	for i = 1, 3 do
		local e = list[i]
		local row = box(panel, UDim2.fromOffset(28, 236 + (i - 1) * 96), UDim2.fromOffset(380, 86))
		UiTheme.label({ parent = row, position = UDim2.fromOffset(16, 8), size = UDim2.fromOffset(60, 30), text = "#" .. i,
			font = "Title", textSize = UiTheme.TextSizes.XL, color = i == 1 and C.GoldBright or C.TextPrimary })
		if e then
			UiTheme.label({ parent = row, position = UDim2.fromOffset(16, 44), size = UDim2.fromOffset(200, 26), text = L.t("weapon." .. e.id),
				font = "Header", textSize = UiTheme.TextSizes.LG, color = C.TextPrimary })
			UiTheme.label({ parent = row, anchor = Vector2.new(1, 0), position = UDim2.new(1, -16, 0, 14), size = UDim2.fromOffset(160, 24),
				text = L.t("pf.games", { n = e.games }), font = "Number", textSize = UiTheme.TextSizes.MD, color = C.TextPrimary,
				alignX = Enum.TextXAlignment.Right })
			UiTheme.label({ parent = row, anchor = Vector2.new(1, 0), position = UDim2.new(1, -16, 0, 44), size = UDim2.fromOffset(160, 24),
				text = L.t("pf.winRate", { pct = math.floor(e.wins / math.max(1, e.games) * 100 + 0.5) }), font = "Number",
				textSize = UiTheme.TextSizes.SM, color = C.Success, alignX = Enum.TextXAlignment.Right })
			local ic = UiAssets.icon(row, "attack", 34, C.TextSecondary)
			ic.AnchorPoint = Vector2.new(0.5, 0.5)
			ic.Position = UDim2.new(0.5, 10, 0.5, 0)
		else
			UiTheme.label({ parent = row, position = UDim2.fromOffset(16, 44), size = UDim2.fromOffset(300, 24), text = L.t("pf.noWeapon"),
				font = "Body", textSize = UiTheme.TextSizes.SM, color = C.TextSecondary })
		end
	end

	-- Estadísticas generales
	UiTheme.label({ parent = panel, position = UDim2.fromOffset(432, 206), size = UDim2.fromOffset(380, 24), text = L.t("pf.stats"),
		font = "Header", textSize = UiTheme.TextSizes.MD, color = C.TextSecondary })
	local grid = box(panel, UDim2.fromOffset(432, 236), UDim2.new(1, -460, 0, 278))
	local kills = stat("Kills")
	local deaths = math.max(1, losses)
	local general = {
		{ "pf.kills", kills }, { "pf.kd", ratio(kills, deaths) }, { "pf.knockdowns", stat("Knockdowns") },
		{ "pf.parries", stat("Parries") }, { "pf.ringouts", stat("RingOuts") }, { "pf.kicks", stat("Kicks") },
		{ "pf.finishers", stat("Finishers") }, { "pf.guardBreaks", stat("GuardBreaks") }, { "pf.throws", stat("Throws") },
	}
	for i, g in general do
		local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
		numberCell(grid, 10 + col * 128, 18 + row * 86, 120, L.t(g[1]), tostring(g[2]), false)
	end

	UiTheme.label({ parent = panel, position = UDim2.fromOffset(28, H - 36), size = UDim2.new(1, -56, 0, 18), text = L.t("pf.note"),
		font = "Body", textSize = UiTheme.TextSizes.XS, color = C.TextMuted or C.TextSecondary })
	if Device.isGamepad() then GuiService.SelectedObject = close end
end

local function layout()
	local vp = gui.AbsoluteSize
	scale.Scale = math.clamp(math.min((vp.X - 24) / W, (vp.Y - 24) / H), 0.45, 1.1)
end

player:GetAttributeChangedSignal("ProfileOpen"):Connect(function()
	local open = player:GetAttribute("ProfileOpen") == true
	if open then
		player:SetAttribute("ShopOpen", false)
		player:SetAttribute("ArmoryOpen", false)
		player:SetAttribute("SettingsOpen", false)
		render()
		layout()
		UiTheme.playSound("UI_MenuOpen")
	elseif gui.Enabled then
		UiTheme.playSound("UI_MenuClose")
		GuiService.SelectedObject = nil
	end
	gui.Enabled = open
	player:SetAttribute("MenuOpen", open)
end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
L.Changed:Connect(function() if gui.Enabled then render() end end)
