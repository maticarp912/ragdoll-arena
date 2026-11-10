-- LocalScript: StarterPlayer/StarterPlayerScripts/HUD
-- HUD de combate y estado de partida rediseñado (Versión 0.2 — D14, C2, C5, C9, C10, C19, C23).
-- Disposición D14:
--   • Abajo al centro: Barra grande de Vida (HP) con estela de daño y destello de impacto (C23).
--   • Encima de Vida: Barra de Infusión (InfusionCharge) con icono elemental animado y aviso de lista.
--   • A los costados: Barra de Estamina (izquierda) y Barra de Guardia (derecha) con destellos de bloqueo/rotura (C23).
--   • Esquinas superiores: Retrato propio (con nivel y multiplicadores C19), retratos rivales y KillFeed (C9).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

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
-- 2. Panel de barras propias (D14: abajo al centro; Vida grande en el centro,
--    Infusión arriba, Estamina a la izquierda y Guardia a la derecha)
----------------------------------------------------------------------
local holder = UiTheme.panel({
	name = "PlayerBars",
	parent = gui,
	anchor = Vector2.new(0.5, 1),
	position = UDim2.new(0.5, 0, 1, -14),
	size = UDim2.fromOffset(496, 98),
	bg = C.BgPanel,
	transparency = 0.12,
	borderColor = C.Gold,
	ornaments = true,
	ornamentSize = 10,
	canvasGroup = true,
})
local holderScale = Instance.new("UIScale")
holderScale.Parent = holder
local holderStroke = holder:FindFirstChildOfClass("UIStroke")

local icons = {}
local rowLabels = {}

-- Función auxiliar para crear barras horizontales con estela y capa de destello (C23)
local function createHorizBar(parent, name, pos, anchor, size, fillColor, borderColor, withTrail)
	local bg = Instance.new("Frame")
	bg.Name = "BarBg_" .. name
	bg.AnchorPoint = anchor
	bg.Position = pos
	bg.Size = size
	bg.BackgroundColor3 = C.BgBarBack
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Parent = parent
	UiTheme.corner(bg, UiTheme.Radius.SM)
	local st = UiTheme.stroke(bg, borderColor or C.BorderDefault, 1.4, 0.2)

	local trail = nil
	if withTrail then
		trail = Instance.new("Frame")
		trail.Name = "Trail"
		trail.Size = UDim2.fromScale(1, 1)
		trail.BackgroundColor3 = C.HealthTrail
		trail.BorderSizePixel = 0
		trail.ZIndex = 2
		trail.Parent = bg
		UiTheme.corner(trail, UiTheme.Radius.SM)
	end

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.ZIndex = 3
	fill.Parent = bg
	UiTheme.corner(fill, UiTheme.Radius.SM)

	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 230, 230)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 165, 165)),
	})
	shine.Parent = fill

	local flash = Instance.new("Frame")
	flash.Name = "FeelFlash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 5
	flash.Parent = bg
	UiTheme.corner(flash, UiTheme.Radius.SM)

	return bg, fill, trail, flash, st
end

-- 2A. Cabecera superior del cluster: Arma equipada a la izquierda, Barra de Infusión en el centro, Stun a la derecha
local weaponHolder = Instance.new("Frame")
weaponHolder.Name = "WeaponHeader"
weaponHolder.Position = UDim2.fromOffset(12, 8)
weaponHolder.Size = UDim2.fromOffset(112, 22)
weaponHolder.BackgroundTransparency = 1
weaponHolder.Parent = holder

local weaponIcon = UiAssets.icon(weaponHolder, "attack", 16, C.GoldBright)
weaponIcon.AnchorPoint = Vector2.new(0, 0.5)
weaponIcon.Position = UDim2.new(0, 0, 0.5, 0)

local weaponLabel = UiTheme.label({
	name = "WeaponName",
	parent = weaponHolder,
	position = UDim2.fromOffset(20, 0),
	size = UDim2.new(1, -20, 1, 0),
	text = "",
	font = "Title",
	textSize = UiTheme.TextSizes.SM,
	color = C.GoldBright,
	alignX = Enum.TextXAlignment.Left,
	truncate = Enum.TextTruncate.AtEnd,
})

-- Barra de Infusión centrada arriba de la Vida
local infRow = Instance.new("Frame")
infRow.Name = "InfusionRow"
infRow.AnchorPoint = Vector2.new(0.5, 0)
infRow.Position = UDim2.new(0.5, 0, 0, 8)
infRow.Size = UDim2.fromOffset(238, 22)
infRow.BackgroundTransparency = 1
infRow.Parent = holder

local infIconHolder = Instance.new("Frame")
infIconHolder.Name = "InfIconHolder"
infIconHolder.Position = UDim2.fromOffset(0, 0)
infIconHolder.Size = UDim2.fromOffset(24, 22)
infIconHolder.BackgroundTransparency = 1
infIconHolder.Parent = infRow

local infIconRoot, infIconUpdate = UiAssets.icon(infIconHolder, "Fire", 20, C.InfusionCharge)
icons.infusion = { root = infIconRoot, update = infIconUpdate, row = infIconHolder, size = 20, id = "Fire" }

local infBg, infFill, _, infFlash, infStroke = createHorizBar(
	infRow,
	"infusion",
	UDim2.fromOffset(28, 2),
	Vector2.new(0, 0),
	UDim2.fromOffset(210, 18),
	C.InfusionCharge,
	C.GoldDim,
	false
)

local infText = UiTheme.label({
	name = "InfusionName",
	parent = infBg,
	position = UDim2.fromOffset(8, 0),
	size = UDim2.new(0.48, -8, 1, 0),
	text = "",
	font = "Bold",
	textSize = UiTheme.TextSizes.XS,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Left,
	zIndex = 6,
})

local infState = UiTheme.label({
	name = "InfusionState",
	parent = infBg,
	anchor = Vector2.new(1, 0),
	position = UDim2.new(1, -8, 0, 0),
	size = UDim2.new(0.55, -8, 1, 0),
	text = "",
	font = "Number",
	textSize = UiTheme.TextSizes.XS,
	color = C.GoldBright,
	alignX = Enum.TextXAlignment.Right,
	zIndex = 6,
})
rowLabels.infusion = infState

-- Barra compacta de Aturdimiento (Stun) arriba a la derecha del cluster
local stunHolder = Instance.new("Frame")
stunHolder.Name = "StunHolder"
stunHolder.AnchorPoint = Vector2.new(1, 0)
stunHolder.Position = UDim2.new(1, -12, 0, 9)
stunHolder.Size = UDim2.fromOffset(108, 20)
stunHolder.BackgroundTransparency = 1
stunHolder.Parent = holder

local stunIconRoot, stunIconUpdate = UiAssets.icon(stunHolder, "stun", 15, C.Stun)
stunIconRoot.AnchorPoint = Vector2.new(0, 0.5)
stunIconRoot.Position = UDim2.new(0, 0, 0.5, 0)
icons.stun = { root = stunIconRoot, update = stunIconUpdate, row = stunHolder, size = 15 }

local stunBg, stunFill = createHorizBar(
	stunHolder,
	"stun",
	UDim2.fromOffset(20, 4),
	Vector2.new(0, 0),
	UDim2.fromOffset(88, 12),
	C.Stun,
	C.BorderSubtle,
	false
)

-- 2B. Barra grande de Vida (HP) abajo al centro
local hpBasePos = UDim2.new(0.5, 0, 1, -12)
local hpBg, hpFill, hpTrail, hpFlash, hpStroke = createHorizBar(
	holder,
	"health",
	hpBasePos,
	Vector2.new(0.5, 1),
	UDim2.fromOffset(238, 30),
	C.Health,
	C.Gold,
	true
)

local hpIconRoot, hpIconUpdate = UiAssets.icon(hpBg, "health", 16, C.TextPrimary)
hpIconRoot.AnchorPoint = Vector2.new(0, 0.5)
hpIconRoot.Position = UDim2.new(0, 8, 0.5, 0)
hpIconRoot.ZIndex = 6
icons.health = { root = hpIconRoot, update = hpIconUpdate, row = hpBg, size = 16 }

local hpTitleLbl = UiTheme.label({
	name = "HpCaption",
	parent = hpBg,
	position = UDim2.fromOffset(28, 0),
	size = UDim2.fromOffset(80, 30),
	text = L.t("health"),
	font = "Header",
	textSize = UiTheme.TextSizes.SM,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Left,
	zIndex = 6,
})
rowLabels.health = hpTitleLbl

local hpNumber = UiTheme.label({
	name = "HpNumbers",
	parent = hpBg,
	anchor = Vector2.new(1, 0),
	position = UDim2.new(1, -10, 0, 0),
	size = UDim2.fromOffset(118, 30),
	text = "100 / 100",
	font = "Number",
	textSize = UiTheme.TextSizes.SM,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Right,
	zIndex = 6,
})

local damageTween = nil
local damageVersion = 0

-- 2C. Costado izquierdo: Barra de Estamina (Stamina)
local stamHeader = Instance.new("Frame")
stamHeader.Position = UDim2.fromOffset(12, 36)
stamHeader.Size = UDim2.fromOffset(108, 16)
stamHeader.BackgroundTransparency = 1
stamHeader.Parent = holder

local stamIconRoot, stamIconUpdate = UiAssets.icon(stamHeader, "stamina", 14, C.Stamina)
stamIconRoot.AnchorPoint = Vector2.new(0, 0.5)
stamIconRoot.Position = UDim2.new(0, 0, 0.5, 0)
icons.stamina = { root = stamIconRoot, update = stamIconUpdate, row = stamHeader, size = 14 }

local stamCaption = UiTheme.label({
	parent = stamHeader,
	position = UDim2.fromOffset(18, 0),
	size = UDim2.new(1, -50, 1, 0),
	text = L.t("stamina"),
	font = "Bold",
	textSize = UiTheme.TextSizes.XS,
	color = C.TextSecondary,
	truncate = Enum.TextTruncate.AtEnd,
})
rowLabels.stamina = stamCaption

local stamNumber = UiTheme.label({
	parent = stamHeader,
	anchor = Vector2.new(1, 0),
	position = UDim2.fromScale(1, 0),
	size = UDim2.fromOffset(34, 16),
	text = "100",
	font = "Number",
	textSize = UiTheme.TextSizes.XS,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Right,
})

local stamBg, stamFill, _, stamFlash = createHorizBar(
	holder,
	"stamina",
	UDim2.new(0, 12, 1, -12),
	Vector2.new(0, 1),
	UDim2.fromOffset(108, 22),
	C.Stamina,
	C.BorderDefault,
	false
)

-- 2D. Costado derecho: Barra de Guardia (Guard)
local guardHeader = Instance.new("Frame")
guardHeader.AnchorPoint = Vector2.new(1, 0)
guardHeader.Position = UDim2.new(1, -12, 0, 36)
guardHeader.Size = UDim2.fromOffset(108, 16)
guardHeader.BackgroundTransparency = 1
guardHeader.Parent = holder

local guardIconRoot, guardIconUpdate = UiAssets.icon(guardHeader, "guard", 14, C.Guard)
guardIconRoot.AnchorPoint = Vector2.new(0, 0.5)
guardIconRoot.Position = UDim2.new(0, 0, 0.5, 0)
icons.guard = { root = guardIconRoot, update = guardIconUpdate, row = guardHeader, size = 14 }

local guardCaption = UiTheme.label({
	parent = guardHeader,
	position = UDim2.fromOffset(18, 0),
	size = UDim2.new(1, -50, 1, 0),
	text = L.t("guard"),
	font = "Bold",
	textSize = UiTheme.TextSizes.XS,
	color = C.TextSecondary,
	truncate = Enum.TextTruncate.AtEnd,
})
rowLabels.guard = guardCaption

local guardNumber = UiTheme.label({
	parent = guardHeader,
	anchor = Vector2.new(1, 0),
	position = UDim2.fromScale(1, 0),
	size = UDim2.fromOffset(34, 16),
	text = "100",
	font = "Number",
	textSize = UiTheme.TextSizes.XS,
	color = C.TextPrimary,
	alignX = Enum.TextXAlignment.Right,
})

local guardBasePos = UDim2.new(1, -12, 1, -12)
local guardBg, guardFill, _, guardFlash, guardStroke = createHorizBar(
	holder,
	"guard",
	guardBasePos,
	Vector2.new(1, 1),
	UDim2.fromOffset(108, 22),
	C.Guard,
	C.BorderDefault,
	false
)

----------------------------------------------------------------------
-- 2E. Contrato C23: Destellos de barra al recibir Remotes.Effect ("Feel")
----------------------------------------------------------------------
local lastCombatTime = -math.huge
local function noteCombat()
	lastCombatTime = os.clock()
end

local function pulseBarFlash(flashFrame, strokeObj, baseStrokeColor, flashColor, duration)
	if not flashFrame then return end
	flashFrame.BackgroundColor3 = flashColor
	flashFrame.BackgroundTransparency = 0.15
	TweenService:Create(flashFrame, TweenInfo.new(duration or 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	if strokeObj then
		strokeObj.Color = flashColor
		TweenService:Create(strokeObj, TweenInfo.new(duration or 0.32), {
			Color = baseStrokeColor,
		}):Play()
	end
end

local function handleCombatFeel(kind, role, info)
	if kind ~= "Feel" then return end
	noteCombat()
	if role == "Take" then
		-- Destello carmesí/blanco y sacudida breve en la barra grande de Vida
		pulseBarFlash(hpFlash, hpStroke, C.Gold, Color3.fromRGB(255, 220, 220), 0.26)
		hpBg.Position = UDim2.new(0.5, math.random(-5, 5), 1, -12 + math.random(-3, 3))
		TweenService:Create(hpBg, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = hpBasePos,
		}):Play()
	elseif role == "Block" or role == "Blocked" then
		-- Destello azul/dorado en la barra de Guardia y actualización instantánea si viene info.guard
		if type(info) == "table" and type(info.guard) == "number" then
			local gFrac = math.clamp(info.guard, 0, 1)
			guardFill.Size = UDim2.fromScale(gFrac, 1)
			guardNumber.Text = tostring(math.floor(gFrac * 100 + 0.5))
		end
		pulseBarFlash(guardFlash, guardStroke, C.BorderDefault, C.GoldBright, 0.24)
	elseif role == "GuardBroken" then
		-- Estallido rojo en la barra de Guardia al romperse
		pulseBarFlash(guardFlash, guardStroke, C.Danger, C.Danger, 0.45)
		guardBg.Position = UDim2.new(1, -12 + math.random(-6, 6), 1, -12 + math.random(-3, 3))
		TweenService:Create(guardBg, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = guardBasePos,
		}):Play()
	elseif role == "Parry" then
		-- Destello dorado heroico en Guardia e Infusión al lograr un Parry
		pulseBarFlash(guardFlash, guardStroke, C.GoldBright, C.GoldBright, 0.32)
		pulseBarFlash(infFlash, infStroke, C.GoldDim, C.GoldBright, 0.32)
	elseif role == "Deal" or role == "GuardBreak" then
		-- Pulso sutil en la barra de infusión al acertar golpes
		if holderStroke then
			holderStroke.Color = C.GoldBright
			TweenService:Create(holderStroke, TweenInfo.new(0.25), { Color = C.Gold }):Play()
		end
	end
end

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
	local effectRemote = remotes and remotes:WaitForChild("Effect", 15)
	if effectRemote and effectRemote:IsA("RemoteEvent") then
		effectRemote.OnClientEvent:Connect(handleCombatFeel)
	end
end)

----------------------------------------------------------------------
-- 3. Retratos de esquina (propio a la izquierda + Nivel/Multiplicadores C19, rivales a la derecha)
----------------------------------------------------------------------
local function portraitPanel(right, slot)
	local frame = Instance.new("Frame")
	frame.Name = right and ("RivalPortrait_" .. slot) or "OwnPortrait"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(right and 1 or 0, 0)
	frame.Position = UDim2.new(right and (1 - H.Side) or H.Side, 0, H.Top, (slot - 1) * H.EnemyStep)
	frame.Size = UDim2.new(H.Width, 0, 0, H.Height + (right and 0 or 26))
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

-- Insignia de Nivel, XP y Multiplicadores activos (Contrato C19) bajo el nombre propio
local progBarHolder = Instance.new("Frame")
progBarHolder.Name = "ProgressionSubBar"
progBarHolder.Position = UDim2.fromOffset(H.Portrait + H.NameHeight, H.NameHeight + 2)
progBarHolder.Size = UDim2.new(1, -H.Portrait - H.NameHeight, 0, 34)
progBarHolder.BackgroundTransparency = 1
progBarHolder.Parent = ownFrame

local levelBadgeLbl = UiTheme.label({
	parent = progBarHolder,
	position = UDim2.fromOffset(0, 0),
	size = UDim2.fromOffset(72, 16),
	text = L.t("ui.hud.level", { level = 1 }),
	font = "Bold",
	textSize = UiTheme.TextSizes.XS,
	color = C.GoldBright,
})

local boostBadgeLbl = UiTheme.label({
	parent = progBarHolder,
	position = UDim2.fromOffset(76, 0),
	size = UDim2.new(1, -76, 0, 16),
	text = "",
	font = "Number",
	textSize = UiTheme.TextSizes.XS,
	color = C.Success,
})

local xpBarBg, xpBarFill = UiTheme.progressBar({
	parent = progBarHolder,
	position = UDim2.fromOffset(0, 18),
	size = UDim2.fromOffset(148, 8),
	fraction = 0,
	fillColor = C.Gold,
})
xpBarBg.Name = "XPBar"

local function updateOwnProgression()
	local lvl = tonumber(player:GetAttribute("Level")) or 1
	local xp = tonumber(player:GetAttribute("XP")) or 0
	local xpNext = math.max(1, tonumber(player:GetAttribute("XPNext")) or 150)
	levelBadgeLbl.Text = L.t("ui.hud.level", { level = lvl })
	xpBarFill.Size = UDim2.fromScale(math.clamp(xp / xpNext, 0, 1), 1)

	local multXp = tonumber(player:GetAttribute("MultXP")) or 1
	local multCoins = tonumber(player:GetAttribute("MultCoins")) or 1
	local parts = {}
	if multXp > 1 then
		table.insert(parts, L.t("ui.hud.boostXp", { mult = multXp }))
	end
	if multCoins > 1 then
		table.insert(parts, L.t("ui.hud.boostSouls", { mult = multCoins }))
	end
	boostBadgeLbl.Text = table.concat(parts, " · ")
end

for _, attr in { "Level", "XP", "XPNext", "MultXP", "MultCoins", "MultRemaining" } do
	player:GetAttributeChangedSignal(attr):Connect(updateOwnProgression)
end
updateOwnProgression()

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
	ownFrame.Visible = not (player:GetAttribute("MenuOpen") == true)
	statusBanner.Position = UDim2.new(0.5, 0, 0, safeTop)

	-- D14: Abajo al centro tanto en PC como en móvil (deja libre el joystick izquierdo y los botones derechos)
	local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, isTouch and -10 or -16)
	if not inMatch and not isTouch then
		-- En el lobby con la barra de cola visible, se eleva levemente para no superponerse con QueueBar
		holder.Position = UDim2.new(0.5, 0, 1, -76)
	end
end

player:GetAttributeChangedSignal("InMatch"):Connect(updateLayout)
player:GetAttributeChangedSignal("MenuOpen"):Connect(updateLayout)
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

	local inMatch = player:GetAttribute("InMatch") == true
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

	-- Barra e icono de infusión (late activa o llena; se ladea agotada)
	local char = player.Character
	local infusionId = (char and char:GetAttribute("InfusionId")) or player:GetAttribute("InfusionId") or "Fire"
	local def = Infusions.get(infusionId)
	if not char or not def then return end

	local now = workspace:GetServerTimeNow()
	infFill.BackgroundColor3 = def.color
	infText.Text = L.t("infusion." .. infusionId)

	if icons.infusion.id ~= infusionId then
		icons.infusion.root:Destroy()
		icons.infusion.root, icons.infusion.update = UiAssets.icon(icons.infusion.row, infusionId, 20, def.color)
		icons.infusion.id = infusionId
	end

	local chargeVal = char:GetAttribute("InfusionCharge") or 0
	local full = chargeVal >= CombatConfig.InfusionCharge.Max
	local active = char:GetAttribute("InfusionActive") == true
	local exhausted = (char:GetAttribute("InfusionLockUntil") or 0) > now

	if active then
		local endAt = char:GetAttribute("InfusionEndsAt") or char:GetAttribute("InfusionEnd") or now
		infState.Text = L.t("active", { seconds = math.max(0, math.ceil(endAt - now)) })
		infStroke.Color = C.GoldBright
	elseif exhausted then
		local lockUntil = char:GetAttribute("InfusionLockUntil") or char:GetAttribute("InfusionExhaustUntil") or now
		infState.Text = L.t("exhausted", { seconds = math.ceil(lockUntil - now) })
		infStroke.Color = C.BorderSubtle
	elseif full then
		infState.Text = L.t("ui.hud.infusionReady")
		infStroke.Color = C.GoldBright
	else
		infState.Text = L.t("charge", { amount = math.floor(chargeVal) })
		infStroke.Color = C.GoldDim
	end

	weaponLabel.Text = L.t("weapon." .. (char:GetAttribute("WeaponId") or player:GetAttribute("WeaponId") or "Sword"))

	local IA = H.InfusionIcon
	icons.infusion.update(1, exhausted)
	local root = icons.infusion.root
	local basePx = 20
	local pulse = (active and IA.ActiveAmp or (full and IA.FullAmp or 0)) * math.sin(os.clock() * (active and IA.ActiveSpeed or IA.FullSpeed))
	local px = math.floor(basePx * (1 + pulse))
	root.Size = UDim2.fromOffset(px, px)
	root.Position = UDim2.fromOffset((basePx - px) / 2, 1 + (basePx - px) / 2)
	root.Rotation = exhausted and IA.ExhaustTilt or (active and pulse * IA.ActiveWobble or 0)
end)

----------------------------------------------------------------------
-- 7. Conexión de atributos del personaje local (Contrato C2 / C5)
----------------------------------------------------------------------
local function setFill(fill, frac)
	fill.Size = UDim2.fromScale(math.clamp(frac or 0, 0, 1), 1)
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

	table.insert(conns, char:GetAttributeChangedSignal("HitAt"):Connect(noteCombat))
	on(hum.HealthChanged, function()
		local frac = hum.Health / math.max(hum.MaxHealth, 1)
		damageVersion += 1
		local version = damageVersion
		if damageTween then damageTween:Cancel() end
		if hum.Health < previousHealth then
			noteCombat()
			pulseBarFlash(hpFlash, hpStroke, C.Gold, Color3.fromRGB(255, 220, 220), 0.22)
		end
		previousHealth = hum.Health
		if frac >= hpFill.Size.X.Scale then
			setFill(hpTrail, frac)
		else
			task.delay(H.DamageDelay, function()
				if version ~= damageVersion or player.Character ~= char then return end
				damageTween = TweenService:Create(hpTrail, TweenInfo.new(H.DamageTime), { Size = UDim2.fromScale(frac, 1) })
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
		setFill(stamFill, cur / math.max(max, 1))
		stamNumber.Text = ("%d"):format(math.floor(cur))
	end
	on(char:GetAttributeChangedSignal("Stamina"), updateStamina)
	on(char:GetAttributeChangedSignal("StaminaMax"), updateStamina)

	on(char:GetAttributeChangedSignal("StaminaFailAt"), function()
		if not char:GetAttribute("StaminaFailAt") then return end
		noteCombat()
		pulseBarFlash(stamFlash, nil, C.BorderDefault, C.Danger, 0.35)
	end)

	local function updateGuard()
		local gmax = char:GetAttribute("GuardMax") or 100
		local gcur = char:GetAttribute("Guard") or gmax
		local broken = char:GetAttribute("GuardBroken") == true
		if gcur < gmax - 5 or broken then noteCombat() end
		setFill(guardFill, gcur / math.max(gmax, 1))
		guardFill.BackgroundColor3 = broken and C.GuardBroken or C.Guard
		guardNumber.Text = ("%d"):format(math.floor(gcur))
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
	updateOwnProgression()
	hpTitleLbl.Text = L.t("health")
	stamCaption.Text = L.t("stamina")
	guardCaption.Text = L.t("guard")
end)
