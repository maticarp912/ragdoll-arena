-- LocalScript: StarterPlayer/StarterPlayerScripts/Shop
-- Escaparate del Ocaso — Tienda rediseñada separada de la Armería (Versión 0.2 — D12, D20, C20).
-- Incluye:
--   - Sección «Destacado del Día» (4 a 6 artículos con rotación determinista por fecha UTC y cuenta regresiva).
--   - Catálogo completo debajo y por pestañas: Destacado, Skins, Auras, Multiplicadores y Almas/Monedas (sin Robux en 0.2).
--   - Gran vista previa 3D interactiva de cada artículo, vista en pedestal para auras y acceso directo a la Armería.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local UiTheme = require(RS:WaitForChild("UiTheme", 10))
local UiAssets = require(RS:WaitForChild("UiAssets", 10))
local L = require(RS:WaitForChild("Localization", 10))
local Skins = require(RS:WaitForChild("Skins", 10))
local Weapons = require(RS:WaitForChild("WeaponData", 10))
local Builder = require(RS:WaitForChild("WeaponBuilder", 10))

local Auras = nil
local AuraFx = nil
do
	local mAuras = RS:WaitForChild("Auras", 10)
	if mAuras then
		local ok, mod = pcall(require, mAuras)
		if ok then Auras = mod end
	end
	local mFx = RS:WaitForChild("AuraFx", 10)
	if mFx then
		local ok, mod = pcall(require, mFx)
		if ok then AuraFx = mod end
	end
end

local remotes = RS:WaitForChild("Remotes", 10)
local remote = remotes and remotes:WaitForChild("Shop", 10)
local C = UiTheme.Colors

----------------------------------------------------------------------
-- Catálogo de Multiplicadores y Almas/Monedas (Versión 0.2 — D12, D20 sin Robux)
----------------------------------------------------------------------
local BOOST_ITEMS = {
	{
		id = "Boost2xCoins",
		kind = "Boost",
		rarity = "Epic",
		nameKey = "ui.shop.boost2xCoins",
		descKey = "ui.shop.boost2xCoinsDesc",
		icon = "coin",
		color = Color3.fromRGB(245, 198, 78),
		currency = "Coins",
		price = 1200,
	},
	{
		id = "Boost2xXp",
		kind = "Boost",
		rarity = "Epic",
		nameKey = "ui.shop.boost2xXp",
		descKey = "ui.shop.boost2xXpDesc",
		icon = "trophy",
		color = Color3.fromRGB(120, 205, 255),
		currency = "Coins",
		price = 1400,
	},
	{
		id = "BoostSoulMagnet",
		kind = "Boost",
		rarity = "Legendary",
		nameKey = "ui.shop.boostSoulMagnet",
		descKey = "ui.shop.boostSoulMagnetDesc",
		icon = "aura_crown",
		color = Color3.fromRGB(235, 48, 68),
		currency = "Coins",
		price = 2200,
	},
}

local SOUL_ITEMS = {
	{
		id = "Small",
		kind = "Souls",
		rarity = "Common",
		nameKey = "ui.shop.soulsPack1",
		descKey = "ui.shop.soulsPack1Desc",
		icon = "coin",
		color = Color3.fromRGB(218, 182, 96),
		amount = 500,
	},
	{
		id = "Medium",
		kind = "Souls",
		rarity = "Rare",
		nameKey = "ui.shop.soulsPack2",
		descKey = "ui.shop.soulsPack2Desc",
		icon = "coin",
		color = Color3.fromRGB(242, 202, 92),
		amount = 2000,
	},
	{
		id = "Large",
		kind = "Souls",
		rarity = "Legendary",
		nameKey = "ui.shop.soulsPack3",
		descKey = "ui.shop.soulsPack3Desc",
		icon = "trophy",
		color = Color3.fromRGB(245, 58, 72),
		amount = 5000,
	},
}

local BOOST_BY_ID = {}
for _, b in BOOST_ITEMS do BOOST_BY_ID[b.id] = b end
local SOUL_BY_ID = {}
for _, s in SOUL_ITEMS do SOUL_BY_ID[s.id] = s end

----------------------------------------------------------------------
-- ScreenGui y ventana principal del Escaparate
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui", 10)

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = C.BgModalVeil
backdrop.BackgroundTransparency = 0.22
backdrop.BorderSizePixel = 0
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Selectable = false
backdrop.Visible = false
backdrop.ZIndex = 1
backdrop.Parent = gui

local BASE_W, BASE_H = 1060, 650
local panel = UiTheme.panel({
	name = "ShopWindow",
	parent = gui,
	canvasGroup = true,
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.fromScale(0.5, 0.5),
	size = UDim2.fromOffset(BASE_W, BASE_H),
	bg = C.BgPrimary,
	borderColor = C.Gold,
	borderThickness = UiTheme.Stroke.Heavy,
	ornaments = true,
	ornamentSize = 20,
})
panel.Visible = false
panel.ZIndex = 2

local scale = Instance.new("UIScale")
scale.Parent = panel

----------------------------------------------------------------------
-- Estado de la tienda
----------------------------------------------------------------------
local tab = "Showcase"
local weapon = player:GetAttribute("WeaponId") or "Sword"
local rarity = "all"
local ownership = "all"
local auraKind = "all"
local selected = "CrimsonEclipse"
local opened = false
local busy = false
local modal = nil
local savedFocusBeforeModal = nil
local transition = 0

local spins = {}
local detailSpin = nil
local drag = nil
local lastPosition = Vector2.zero
local stick = Vector2.zero
local zoomAxis = 0
local content = nil
local detail = nil
local messageLabel = nil
local timerLabel = nil
local render
local setOpen

local rarities = { "all", "Common", "Rare", "Epic", "Legendary" }
local filters = { "all", "owned", "available" }
local auraKinds = { "all", "Body", "Weapon" }

----------------------------------------------------------------------
-- Pedestal de vista previa de Auras en el mundo (Contrato C11)
----------------------------------------------------------------------
local auraPreviewStage = nil

local function destroyAuraWorldPreview()
	if AuraFx then
		pcall(function() AuraFx.clearPreview() end)
	end
	if auraPreviewStage then
		auraPreviewStage:Destroy()
		auraPreviewStage = nil
	end
end

local function showAuraWorldPreview(auraId)
	destroyAuraWorldPreview()
	if not AuraFx or not Auras or not Auras.Data[auraId] then return end
	local stage = Instance.new("Model")
	stage.Name = "AuraPreviewPedestal"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Transparency = 0.85
	root.Color = C.Gold
	root.CFrame = CFrame.new(0, -450, 0)
	root.Parent = stage
	stage.PrimaryPart = root

	local wModel = Builder.buildModel(weapon, player:GetAttribute("EquippedSkin") or "Default")
	wModel.Name = "PreviewWeapon"
	for _, p in wModel:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored = true end
	end
	wModel:PivotTo(root.CFrame * CFrame.new(1.2, 0, -0.8))
	wModel.Parent = stage
	stage.Parent = workspace
	auraPreviewStage = stage
	pcall(function() AuraFx.preview(stage, auraId) end)
end

----------------------------------------------------------------------
-- Rotación diaria determinista para la sección «Destacado del Día» (D12)
----------------------------------------------------------------------
-- I2 (integración 0.2): la lista oficial la calcula el servidor (`Shop` → `GetFeatured`, día de Argentina).
-- El cálculo local queda solo como respaldo si el servidor no respondió.
local serverFeatured, serverResetAt = nil, nil
local function fetchServerFeatured()
	if not remote then return end
	local ok, success, data = pcall(function() return remote:InvokeServer("GetFeatured") end)
	if ok and success and type(data) == "table" and type(data.ids) == "table" and #data.ids > 0 then
		serverFeatured = data.ids
		serverResetAt = tonumber(data.resetAt)
	end
end

local function getDailyFeaturedIds()
	if serverFeatured and (not serverResetAt or os.time() < serverResetAt) then return serverFeatured end
	-- Si el servidor publica una lista en workspace:GetAttribute("ShopFeatured"), se usa esa;
	-- si no, se calcula de forma determinista por día UTC (4 a 6 artículos).
	local rawServer = workspace:GetAttribute("ShopFeatured")
	if type(rawServer) == "string" and #rawServer > 0 then
		local list = {}
		for token in string.gmatch(rawServer, "[^,]+") do
			table.insert(list, token)
		end
		if #list >= 4 then return list end
	end

	-- Respaldo: el MISMO cálculo que ShopService (GetFeatured), para que nunca muestre otra lista.
	-- Sin skins de la ruleta (D23), día de Argentina (Economy.DayOffset).
	local E = require(RS:WaitForChild("Economy"))
	local ids = {}
	for skinId, skin in Skins.Data do
		if skinId ~= "Default" and not skin.comingSoon and not skin.roulette then table.insert(ids, skinId) end
	end
	table.sort(ids)
	local featured = {}
	if #ids == 0 then return featured end
	local day = math.floor((os.time() - E.DayOffset) / E.DaySeconds)
	for i = 1, math.min(E.FeaturedCount, #ids) do
		table.insert(featured, ids[(day * E.FeaturedCount + i - 1) % #ids + 1])
	end
	return featured
end

local function formatDailyCountdown()
	local now = os.time()
	local rem = serverResetAt and math.max(0, serverResetAt - now) or (86400 - ((now - 10800) % 86400)) -- 00:00 de Argentina (UTC-3)
	local h = math.floor(rem / 3600)
	local m = math.floor((rem % 3600) / 60)
	local s = rem % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

----------------------------------------------------------------------
-- Utilidades de datos y estado de cada artículo
----------------------------------------------------------------------
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

local function ownAuras()
	return parseCsv(player:GetAttribute("OwnedAuras"))
end

local function pending(item)
	if not item then return true end
	if item.comingSoon then return true end
	if item.currency == "Robux" then return true end -- D20: sin Robux en 0.2
	return false
end

local function priceText(item)
	if not item then return "" end
	if item.kind == "Souls" then
		return "+" .. L.t("Coins", { amount = item.amount or 0 })
	end
	if item.currency == "Free" then return L.t("Free") end
	if item.currency == "Coins" then return L.t("Coins", { amount = item.price or 0 }) end
	return L.t("soon")
end

local function itemName(id)
	if BOOST_BY_ID[id] then return L.t(BOOST_BY_ID[id].nameKey) end
	if SOUL_BY_ID[id] then return L.t(SOUL_BY_ID[id].nameKey) end
	if Auras and Auras.Data[id] then return L.t("cx.aura." .. id) end
	if Weapons.Data[id] then return L.t("weapon." .. id) end
	return L.t("skin." .. id)
end

local function itemDesc(id)
	if BOOST_BY_ID[id] then return L.t(BOOST_BY_ID[id].descKey) end
	if SOUL_BY_ID[id] then return L.t(SOUL_BY_ID[id].descKey) end
	if Auras and Auras.Data[id] then return L.t("cx.aura." .. id .. ".desc") end
	if Weapons.Data[id] then return L.t("weaponDesc." .. id) end
	return L.t("skinDesc." .. id)
end

local function getItemRecord(id)
	if Skins.Data[id] then return Skins.Data[id], "Skin" end
	if Auras and Auras.Data[id] then return Auras.Data[id], "Aura" end
	if BOOST_BY_ID[id] then return BOOST_BY_ID[id], "Boost" end
	if SOUL_BY_ID[id] then return SOUL_BY_ID[id], "Souls" end
	return nil, nil
end

local function state(id)
	local rec, kind = getItemRecord(id)
	if kind == "Aura" then
		if player:GetAttribute("EquippedAura") == id then return "equipped" end
		if ownAuras()[id] then return "equip" end
		if pending(rec) then return "soon" end
		return "buy"
	elseif kind == "Boost" then
		return "buy"
	elseif kind == "Souls" then
		return "choose"
	elseif kind == "Skin" then
		local skinWeapon = rec.weapon or weapon
		if player:GetAttribute("EquippedSkin") == id and player:GetAttribute("WeaponId") == skinWeapon then
			return "equipped"
		end
		if ownSkins()[id] then return "equip" end
		if pending(rec) then return "soon" end
		return "buy"
	end
	return "soon"
end

local function setStatus(text, isError)
	if not messageLabel then return end
	messageLabel.Text = text or ""
	messageLabel.TextColor3 = isError and C.Danger or C.GoldBright
end

----------------------------------------------------------------------
-- Visor 3D en ViewportFrame
----------------------------------------------------------------------
local function preview(parent, wid, sid, rect, manual)
	local vp = Instance.new("ViewportFrame")
	vp.Position = UDim2.fromOffset(rect[1], rect[2])
	vp.Size = UDim2.fromOffset(rect[3], rect[4])
	vp.BackgroundColor3 = C.BgPreview
	vp.BackgroundTransparency = manual and 0.05 or 0.15
	vp.BorderSizePixel = 0
	vp.Ambient = Color3.fromRGB(165, 165, 180)
	vp.LightColor = Color3.fromRGB(255, 240, 214)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.Parent = parent
	UiTheme.corner(vp, UiTheme.Radius.SM)

	local world = Instance.new("WorldModel")
	world.Parent = vp
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.Parent = vp
	vp.CurrentCamera = camera

	local model = Builder.buildModel(wid, sid)
	model.Parent = world
	local cfBox, size = model:GetBoundingBox()
	local center = model.PrimaryPart and (model.PrimaryPart.CFrame:Inverse() * cfBox.Position) or Vector3.zero
	local horizontal = not manual and rect[3] > rect[4] * 1.15
	local base = (horizontal and CFrame.Angles(0, math.pi / 2, math.rad(14)) or CFrame.Angles(math.rad(-16), math.pi / 4, 0))
		* CFrame.new(-center)
	local dist = math.max(size.X, size.Y, size.Z) * (horizontal and 1.12 or 1.25)
	model:PivotTo(base)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, dist), Vector3.zero)

	local entry = {
		vp = vp,
		model = model,
		camera = camera,
		base = base,
		distance = dist,
		horizontal = horizontal,
		yaw = 0,
		pitch = 0,
		zoom = 1,
		manual = manual,
	}
	table.insert(spins, entry)
	return vp, entry
end

----------------------------------------------------------------------
-- Modal de confirmación de compra con bloqueo de foco de mando
----------------------------------------------------------------------
local function dismiss()
	UiTheme.releaseGamepadFocus("ShopModalGroup")
	if modal then
		modal:Destroy()
		modal = nil
	end
	if UIS.GamepadEnabled and savedFocusBeforeModal and savedFocusBeforeModal.Parent then
		GuiService.SelectedObject = savedFocusBeforeModal
	end
	savedFocusBeforeModal = nil
end

local function act(action, id)
	if busy or not remote then return end
	if player:GetAttribute("InMatch") and (action == "SelectWeapon" or action == "Equip" or action == "EquipAura" or action == "UnequipAura") then
		setStatus(L.t("locked"), true)
		UiTheme.playSound("UI_Error")
		return
	end
	busy = true
	local ok, success, msg = pcall(function()
		return remote:InvokeServer(action, id)
	end)
	busy = false
	dismiss()
	if not ok then
		UiTheme.playSound("UI_Error")
		setStatus(L.t("error"), true)
		return
	end

	if success then
		UiTheme.playSound((action == "Buy" or action == "BuyAura") and "UI_PurchaseOK" or "UI_Equip")
		if detailSpin then
			detailSpin.flashUntil = os.clock() + 0.35
		end
	else
		UiTheme.playSound("UI_Error")
	end

	if type(msg) == "table" and msg.key then
		setStatus(L.t(msg.key, msg.params), not success)
	elseif type(msg) == "string" then
		setStatus(L.t(msg), not success)
	else
		setStatus(success and L.t("purchaseSuccess") or L.t("error"), not success)
	end
	render()
end

local function confirmPurchase(id, item, buyAction)
	dismiss()
	savedFocusBeforeModal = GuiService.SelectedObject
	UiTheme.playSound("UI_MenuOpen")

	modal = Instance.new("TextButton")
	modal.Name = "ConfirmOverlay"
	modal.Size = UDim2.fromScale(1, 1)
	modal.BackgroundColor3 = C.BgModalVeil
	modal.BackgroundTransparency = 0.25
	modal.Text = ""
	modal.AutoButtonColor = false
	modal.Selectable = false
	modal.ZIndex = 40
	modal.Parent = panel

	local box = UiTheme.panel({
		name = "ConfirmBox",
		parent = modal,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromOffset(440, 320),
		bg = C.BgPrimary,
		borderColor = C.GoldBright,
		borderThickness = UiTheme.Stroke.Heavy,
		ornaments = true,
		zIndex = 41,
	})

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(20, 14),
		size = UDim2.new(1, -40, 0, 30),
		text = L.t("confirmTitle"),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
		alignX = Enum.TextXAlignment.Center,
		zIndex = 42,
	})

	if Skins.Data[id] then
		local pv = preview(box, item.weapon or weapon, id, { 110, 48, 220, 120 }, false)
		pv.ZIndex = 42
	else
		local emblem = Instance.new("Frame")
		emblem.AnchorPoint = Vector2.new(0.5, 0)
		emblem.Position = UDim2.new(0.5, 0, 0, 56)
		emblem.Size = UDim2.fromOffset(96, 96)
		emblem.BackgroundColor3 = C.BgPreview
		emblem.BorderSizePixel = 0
		emblem.ZIndex = 42
		emblem.Parent = box
		UiTheme.corner(emblem, 48)
		UiTheme.stroke(emblem, item.color or C.GoldBright, 2, 0.1)
		local ic = UiAssets.icon(emblem, item.icon or ("aura_" .. (item.pattern or "crown")), 56, item.color or C.GoldBright)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		ic.ZIndex = 43
	end

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(24, 174),
		size = UDim2.new(1, -48, 0, 26),
		text = L.t("confirmAsk", { item = itemName(id), price = priceText(item) }),
		font = "Bold",
		textSize = UiTheme.TextSizes.MD,
		color = C.TextPrimary,
		alignX = Enum.TextXAlignment.Center,
		zIndex = 42,
	})

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(24, 204),
		size = UDim2.new(1, -48, 0, 42),
		text = L.t("ui.confirmBody"),
		font = "Body",
		textSize = UiTheme.TextSizes.SM,
		color = C.TextSecondary,
		alignX = Enum.TextXAlignment.Center,
		zIndex = 42,
	})

	local confirmBtn = UiTheme.button({
		name = "ConfirmBuyBtn",
		parent = box,
		position = UDim2.fromOffset(32, 258),
		size = UDim2.fromOffset(180, 44),
		text = L.t("confirm"),
		variant = "gold",
		zIndex = 43,
		onClick = function()
			if buyAction == "LocalBoost" then
				UiTheme.playSound("UI_PurchaseOK")
				dismiss()
				setStatus(L.t("ui.shop.noRobuxNotice"), false)
			else
				act(buyAction or "Buy", id)
			end
		end,
	})

	local cancelBtn = UiTheme.button({
		name = "CancelBuyBtn",
		parent = box,
		position = UDim2.fromOffset(228, 258),
		size = UDim2.fromOffset(180, 44),
		text = L.t("cancel"),
		variant = "secondary",
		zIndex = 43,
		onClick = dismiss,
	})

	UiTheme.trapGamepadFocus("ShopModalGroup", { confirmBtn, cancelBtn })
	if UIS.GamepadEnabled then
		GuiService.SelectedObject = confirmBtn
	end
end

----------------------------------------------------------------------
-- Panel derecho de inspección detallada (3D Grande)
----------------------------------------------------------------------
local function inspect(id)
	selected = id
	for _, ch in detail:GetChildren() do
		if not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
			ch:Destroy()
		end
	end
	detailSpin = nil

	local rec, kind = getItemRecord(id)
	if not rec then return end

	local rSpec = rec.rarity and UiTheme.Rarities[rec.rarity] or nil
	if rSpec then
		UiTheme.rarityBadge(detail, rec.rarity, L.t(rec.rarity), UDim2.fromOffset(16, 12))
	end

	-- Insignia de Ruleta / Gran Premio Semanal (D15)
	if rec.roulette then
		local rBadge = Instance.new("Frame")
		rBadge.AnchorPoint = Vector2.new(1, 0)
		rBadge.Position = UDim2.new(1, -16, 0, 12)
		rBadge.Size = UDim2.fromOffset(rec.weeklyPrize and 178 or 110, 22)
		rBadge.BackgroundColor3 = Color3.fromRGB(115, 18, 28)
		rBadge.BorderSizePixel = 0
		rBadge.Parent = detail
		UiTheme.corner(rBadge, UiTheme.Radius.Pill)
		UiTheme.stroke(rBadge, C.GoldBright, 1.2, 0.1)
		UiTheme.label({
			parent = rBadge,
			size = UDim2.fromScale(1, 1),
			text = rec.weeklyPrize and L.t("ui.shop.weeklyGrandPrize") or L.t("ui.shop.rouletteBadge"),
			font = "Bold",
			textSize = UiTheme.TextSizes.XS,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})
	end

	UiTheme.label({
		parent = detail,
		position = UDim2.fromOffset(16, 38),
		size = UDim2.new(1, -32, 0, 28),
		text = itemName(id),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
		truncate = Enum.TextTruncate.AtEnd,
	})

	local dSize = detail.AbsoluteSize
	local vpW = math.max(200, (dSize.X > 0 and dSize.X or 360) - 32)
	local vpH = math.clamp(math.floor(((dSize.Y > 0 and dSize.Y or 460) - 210) * 0.62), 140, 230)

	if kind == "Aura" then
		destroyAuraWorldPreview()
		showAuraWorldPreview(id)

		local stageBox = Instance.new("Frame")
		stageBox.Position = UDim2.fromOffset(16, 70)
		stageBox.Size = UDim2.fromOffset(vpW, vpH)
		stageBox.BackgroundColor3 = C.BgPreview
		stageBox.BorderSizePixel = 0
		stageBox.Parent = detail
		UiTheme.corner(stageBox, UiTheme.Radius.SM)
		UiTheme.stroke(stageBox, rec.color or C.Gold, 1.5, 0.25)

		local ic = UiAssets.icon(stageBox, "aura_" .. (rec.pattern or "crown"), 84, rec.color or C.GoldBright)
		ic.AnchorPoint = Vector2.new(0.5, 0.44)
		ic.Position = UDim2.fromScale(0.5, 0.44)

		UiTheme.label({
			parent = stageBox,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -8),
			size = UDim2.new(1, -16, 0, 20),
			text = L.t("ui.aura.worldPreview") .. " · " .. L.t(rec.kind == "Body" and "ui.aura.body" or "ui.aura.weapon"),
			font = "Bold",
			textSize = UiTheme.TextSizes.XS,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})
	elseif kind == "Skin" then
		destroyAuraWorldPreview()
		local wid = rec.weapon or weapon
		local vp, spin = preview(detail, wid, id, { 16, 70, vpW, vpH }, true)
		detailSpin = spin
		vp.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				drag = inp
				lastPosition = inp.Position
			end
		end)
		vp.InputChanged:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseWheel and detailSpin then
				detailSpin.zoom = math.clamp(detailSpin.zoom - inp.Position.Z * 0.1, 0.55, 1.65)
			end
		end)
		UiTheme.label({
			parent = vp,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -6),
			size = UDim2.new(1, -12, 0, 16),
			text = L.t("ui.armory.rotateHint"),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextMuted,
			alignX = Enum.TextXAlignment.Center,
		})
	else
		destroyAuraWorldPreview()
		local stageBox = Instance.new("Frame")
		stageBox.Position = UDim2.fromOffset(16, 70)
		stageBox.Size = UDim2.fromOffset(vpW, vpH)
		stageBox.BackgroundColor3 = C.BgPreview
		stageBox.BorderSizePixel = 0
		stageBox.Parent = detail
		UiTheme.corner(stageBox, UiTheme.Radius.SM)
		UiTheme.stroke(stageBox, rec.color or C.Gold, 1.5, 0.25)

		local ic = UiAssets.icon(stageBox, rec.icon or "coin", 78, rec.color or C.GoldBright)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
	end

	local bodyY = 78 + vpH
	UiTheme.label({
		parent = detail,
		position = UDim2.fromOffset(16, bodyY),
		size = UDim2.new(1, -32, 0, 54),
		text = itemDesc(id),
		font = "Body",
		textSize = UiTheme.TextSizes.SM,
		color = C.TextSecondary,
		alignY = Enum.TextYAlignment.Top,
	})

	if rec.roulette then
		UiTheme.label({
			parent = detail,
			position = UDim2.fromOffset(16, bodyY + 54),
			size = UDim2.new(1, -32, 0, 20),
			text = L.t("ui.shop.rouletteHint"),
			font = "Bold",
			textSize = UiTheme.TextSizes.XS,
			color = C.GoldBright,
		})
	end

	-- Botón principal de acción en la parte inferior del detalle
	local st = state(id)
	local labelText = L.t(st)
	local variant = "primary"
	local disabled = false

	if st == "buy" and kind == "Skin" and rec.roulette then
		-- Solo ruleta (decisión del usuario, 10/11/2026): no se compra.
		labelText = L.t("ui.shop.rouletteOnly")
		variant = "secondary"
		disabled = true
	elseif st == "buy" then
		labelText = L.t("buy") .. " · " .. priceText(rec)
		variant = "gold"
	elseif st == "equipped" then
		variant = "secondary"
		disabled = true
	elseif st == "soon" then
		variant = "secondary"
		disabled = true
	elseif kind == "Souls" then
		labelText = priceText(rec)
		variant = "gold"
	end

	UiTheme.button({
		name = "MainActionButton",
		parent = detail,
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -14),
		size = UDim2.new(1, -32, 0, 44),
		text = labelText,
		font = "Header",
		textSize = UiTheme.TextSizes.MD,
		variant = variant,
		disabled = disabled,
		onClick = function()
			if kind == "Aura" then
				if st == "buy" then
					confirmPurchase(id, rec, "BuyAura")
				elseif st == "equip" then
					act("EquipAura", id)
				end
			elseif kind == "Skin" then
				if st == "buy" then
					confirmPurchase(id, rec, "Buy")
				elseif st == "equip" then
					if rec.weapon and rec.weapon ~= player:GetAttribute("WeaponId") then
						act("SelectWeapon", rec.weapon)
					end
					act("Equip", id)
				end
			elseif kind == "Boost" then
				confirmPurchase(id, rec, "LocalBoost")
			elseif kind == "Souls" then
				act("DebugCoins", id)
			end
		end,
	})
end

----------------------------------------------------------------------
-- Renderizado completo del Escaparate y Catálogo
----------------------------------------------------------------------
function render()
	table.clear(spins)
	detailSpin = nil
	for _, ch in panel:GetChildren() do
		if ch ~= scale and ch ~= modal and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
			ch:Destroy()
		end
	end

	local cam = workspace.CurrentCamera
	local viewport = cam and cam.ViewportSize or Vector2.new(BASE_W, BASE_H)
	local mobile = viewport.X < 780
	local width = mobile and 700 or BASE_W
	local height = mobile and 620 or BASE_H
	panel.Size = UDim2.fromOffset(width, height)
	scale.Scale = UiTheme.computeScale(viewport, width, height, player)

	-- Cabecera: título del Escaparate, saldo de monedas, botón Abrir Armería y botón Cerrar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = panel
	UiTheme.corner(header, UiTheme.Radius.MD)

	local shopIcon = UiAssets.icon(header, "coin", 26, C.GoldBright)
	shopIcon.AnchorPoint = Vector2.new(0, 0.5)
	shopIcon.Position = UDim2.new(0, 18, 0.5, 0)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 6),
		size = UDim2.fromOffset(360, 28),
		text = L.t("ui.shop.title"),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
	})
	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 32),
		size = UDim2.fromOffset(380, 18),
		text = L.t("ui.shop.subtitle"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
	})

	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	local coinBox = Instance.new("Frame")
	coinBox.AnchorPoint = Vector2.new(1, 0.5)
	coinBox.Position = UDim2.new(1, -290, 0.5, 0)
	coinBox.Size = UDim2.fromOffset(165, 36)
	coinBox.BackgroundColor3 = C.BgAbyss
	coinBox.BorderSizePixel = 0
	coinBox.Parent = header
	UiTheme.corner(coinBox, UiTheme.Radius.Pill)
	UiTheme.stroke(coinBox, C.GoldDim, 1, 0.25)

	local coinIc = UiAssets.icon(coinBox, "coin", 20, C.Coins)
	coinIc.AnchorPoint = Vector2.new(0, 0.5)
	coinIc.Position = UDim2.new(0, 10, 0.5, 0)

	UiTheme.label({
		parent = coinBox,
		position = UDim2.fromOffset(34, 0),
		size = UDim2.new(1, -42, 1, 0),
		text = L.t("Coins", { amount = coinsVal and coinsVal.Value or 0 }),
		font = "Number",
		textSize = UiTheme.TextSizes.SM,
		color = C.Coins,
		alignX = Enum.TextXAlignment.Right,
	})

	UiTheme.button({
		name = "OpenArmoryBtn",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = UDim2.new(1, -130, 0.5, 0),
		size = UDim2.fromOffset(150, 38),
		text = L.t("ui.shop.openArmory"),
		variant = "primary",
		textSize = UiTheme.TextSizes.SM,
		onClick = function()
			setOpen(false)
			local armoryEv = player:FindFirstChild("ToggleArmory")
			if armoryEv and armoryEv:IsA("BindableEvent") then
				armoryEv:Fire(true)
			end
		end,
	})

	UiTheme.button({
		name = "CloseButton",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = UDim2.new(1, -16, 0.5, 0),
		size = UDim2.fromOffset(104, 38),
		text = L.t("close"),
		variant = "secondary",
		onClick = function()
			setOpen(false)
		end,
	})

	-- Barra de pestañas del Escaparate: Destacado, Skins, Auras, Multiplicadores, Almas y Monedas
	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "TabsBar"
	tabsBar.Position = UDim2.fromOffset(20, 66)
	tabsBar.Size = UDim2.new(1, -40, 0, 42)
	tabsBar.BackgroundTransparency = 1
	tabsBar.Parent = panel
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabsBar

	local firstButton = nil
	local tabDefs = {
		{ id = "Showcase", label = L.t("ui.shop.tab.Showcase") },
		{ id = "Skins", label = L.t("ui.shop.tab.Skins") },
		{ id = "Auras", label = L.t("ui.shop.tab.Auras") },
		{ id = "Boosts", label = L.t("ui.shop.tab.Boosts") },
		{ id = "Souls", label = L.t("ui.shop.tab.Souls") },
	}
	for i, def in tabDefs do
		local b = UiTheme.tabButton({
			name = "Tab_" .. def.id,
			parent = tabsBar,
			layoutOrder = i,
			size = UDim2.fromOffset(mobile and 126 or 158, 42),
			text = def.label,
			active = tab == def.id,
			onClick = function()
				tab = def.id
				render()
			end,
		})
		if i == 1 then firstButton = b end
	end

	local top = 116
	local listWidth = mobile and (width - 40) or math.floor(width * 0.61) - 24
	if tab == "Skins" then
		local weaponBar = Instance.new("Frame")
		weaponBar.Position = UDim2.fromOffset(20, 114)
		weaponBar.Size = UDim2.fromOffset(listWidth, 34)
		weaponBar.BackgroundTransparency = 1
		weaponBar.Parent = panel

		local bw = math.floor(listWidth / #Weapons.Order)
		for i, wid in Weapons.Order do
			UiTheme.button({
				parent = weaponBar,
				position = UDim2.fromOffset((i - 1) * bw, 0),
				size = UDim2.fromOffset(bw - 6, 34),
				text = L.t("weapon." .. wid),
				selected = wid == weapon,
				textSize = UiTheme.TextSizes.XS,
				onClick = function()
					weapon = wid
					render()
				end,
			})
		end

		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(20, 154),
			size = UDim2.fromOffset(195, 32),
			text = L.t("ui.filter.rarity", { value = L.t(rarity) }),
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				rarity = rarities[(table.find(rarities, rarity) % #rarities) + 1]
				render()
			end,
		})
		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(222, 154),
			size = UDim2.fromOffset(195, 32),
			text = L.t("ui.filter.ownership", { value = L.t(ownership) }),
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				ownership = filters[(table.find(filters, ownership) % #filters) + 1]
				render()
			end,
		})
		top = 194
	elseif tab == "Auras" then
		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(20, 114),
			size = UDim2.fromOffset(195, 34),
			text = L.t("ui.filter.auraKind", { value = auraKind == "all" and L.t("all") or L.t(auraKind == "Body" and "ui.aura.body" or "ui.aura.weapon") }),
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				auraKind = auraKinds[(table.find(auraKinds, auraKind) % #auraKinds) + 1]
				render()
			end,
		})
		top = 156
	end

	local contentH = height - top - 44
	local listHeight = mobile and math.floor(contentH * 0.52) or contentH

	content = Instance.new("ScrollingFrame")
	content.Name = "ShopScroll"
	content.Position = UDim2.fromOffset(20, top)
	content.Size = UDim2.fromOffset(listWidth, listHeight)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.ScrollBarThickness = 6
	content.ScrollBarImageColor3 = C.Gold
	content.Parent = panel

	detail = UiTheme.panel({
		name = "DetailPanel",
		parent = panel,
		canvasGroup = true,
		position = UDim2.fromOffset(mobile and 20 or (28 + listWidth), mobile and (top + listHeight + 8) or 116),
		size = UDim2.fromOffset(mobile and (width - 40) or (width - listWidth - 48), mobile and (contentH - listHeight - 8) or (height - 116 - 44)),
		bg = C.BgPanel,
		borderColor = C.Gold,
		ornaments = true,
	})

	local shown = {}
	local ownedSkinsMap = ownSkins()
	local ownedAurasMap = ownAuras()

	-- Helper para crear una tarjeta de artículo en el escaparate o catálogo
	local function buildItemCard(parentFrame, id, cardW, cardH, orderIdx, isFeaturedBanner)
		local rec, kind = getItemRecord(id)
		if not rec then return end
		table.insert(shown, id)

		local rSpec = rec.rarity and UiTheme.Rarities[rec.rarity] or nil
		local st = state(id)
		local borderCol = (selected == id or rec.weeklyPrize) and C.GoldBright or (rSpec and rSpec.color or C.Gold)

		local card = Instance.new("Frame")
		card.Name = "Card_" .. id
		card.LayoutOrder = orderIdx
		card.Size = UDim2.fromOffset(cardW, cardH)
		card.BackgroundColor3 = rec.weeklyPrize and Color3.fromRGB(28, 16, 22) or C.BgCard
		card.BorderSizePixel = 0
		card.Parent = parentFrame
		UiTheme.corner(card, UiTheme.Radius.SM)
		local cardStroke = UiTheme.stroke(card, borderCol, (selected == id or isFeaturedBanner) and 2.2 or 1.4, st == "equipped" and 0 or 0.18)
		if isFeaturedBanner then
			UiTheme.ornamentCorners(card, borderCol, 10, 2)
		end

		if rSpec then
			UiTheme.rarityBadge(card, rec.rarity, L.t(rec.rarity), UDim2.fromOffset(8, 6)).ZIndex = 4
		end

		if rec.roulette then
			local rb = Instance.new("Frame")
			rb.AnchorPoint = Vector2.new(1, 0)
			rb.Position = UDim2.new(1, -8, 0, 6)
			rb.Size = UDim2.fromOffset(rec.weeklyPrize and 138 or 78, 20)
			rb.BackgroundColor3 = Color3.fromRGB(120, 18, 28)
			rb.BorderSizePixel = 0
			rb.ZIndex = 4
			rb.Parent = card
			UiTheme.corner(rb, UiTheme.Radius.Pill)
			UiTheme.stroke(rb, C.GoldBright, 1, 0.15)
			UiTheme.label({
				parent = rb,
				size = UDim2.fromScale(1, 1),
				text = rec.weeklyPrize and L.t("ui.shop.weeklyGrandPrize") or L.t("ui.shop.rouletteBadge"),
				font = "Bold",
				textSize = UiTheme.TextSizes.XS,
				color = C.GoldBright,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 5,
			})
		end

		local vpH = cardH - 68
		if kind == "Skin" then
			preview(card, rec.weapon or weapon, id, { 8, 30, cardW - 16, vpH }, false)
		else
			local emblemHolder = Instance.new("Frame")
			emblemHolder.AnchorPoint = Vector2.new(0.5, 0)
			emblemHolder.Position = UDim2.new(0.5, 0, 0, 34)
			emblemHolder.Size = UDim2.fromOffset(math.min(82, vpH - 6), math.min(82, vpH - 6))
			emblemHolder.BackgroundColor3 = C.BgPreview
			emblemHolder.BorderSizePixel = 0
			emblemHolder.Parent = card
			UiTheme.corner(emblemHolder, 42)
			UiTheme.stroke(emblemHolder, rec.color or borderCol, 1.6, 0.15)
			local ic = UiAssets.icon(emblemHolder, rec.icon or ("aura_" .. (rec.pattern or "crown")), 48, rec.color or borderCol)
			ic.AnchorPoint = Vector2.new(0.5, 0.5)
			ic.Position = UDim2.fromScale(0.5, 0.5)
		end

		UiTheme.label({
			parent = card,
			position = UDim2.fromOffset(8, cardH - 36),
			size = UDim2.fromOffset(cardW - 16, 20),
			text = itemName(id),
			font = "Header",
			textSize = UiTheme.TextSizes.SM,
			color = C.TextPrimary,
			truncate = Enum.TextTruncate.AtEnd,
		})

		local rouletteOnly = kind == "Skin" and rec.roulette and st == "buy"
		local subText = rouletteOnly and L.t("ui.shop.rouletteOnly") or ((st == "buy" or kind == "Souls") and priceText(rec) or L.t(st))
		local subColor = st == "equipped" and C.Success or ((st == "buy" or kind == "Souls") and C.Coins or C.TextSecondary)
		UiTheme.label({
			parent = card,
			position = UDim2.fromOffset(8, cardH - 18),
			size = UDim2.fromOffset(cardW - 16, 16),
			text = subText,
			font = "Bold",
			textSize = UiTheme.TextSizes.XS,
			color = subColor,
		})

		local hit = Instance.new("TextButton")
		hit.Name = "CardHit"
		hit.Size = UDim2.fromScale(1, 1)
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.ZIndex = 6
		hit.Parent = card
		UiTheme.bindGamepadFocus(hit, cardStroke, borderCol, 1.8, 0.18)

		hit.Activated:Connect(function()
			UiTheme.playSound("UI_Click")
			inspect(id)
			detail.GroupTransparency = 0.22
			TweenService:Create(detail, UiTheme.Anim.TweenFast, { GroupTransparency = 0 }):Play()
		end)
	end

	if tab == "Showcase" then
		-- Layout vertical con Sección «Destacado del Día» arriba + «Catálogo Completo» abajo
		local vLayout = Instance.new("UIListLayout")
		vLayout.FillDirection = Enum.FillDirection.Vertical
		vLayout.Padding = UDim.new(0, 12)
		vLayout.SortOrder = Enum.SortOrder.LayoutOrder
		vLayout.Parent = content

		-- Cabecera de Destacado del Día con temporizador de rotación
		local featHeader = Instance.new("Frame")
		featHeader.LayoutOrder = 1
		featHeader.Size = UDim2.fromOffset(listWidth - 10, 38)
		featHeader.BackgroundColor3 = C.BgHeader
		featHeader.BorderSizePixel = 0
		featHeader.Parent = content
		UiTheme.corner(featHeader, UiTheme.Radius.SM)
		UiTheme.stroke(featHeader, C.Gold, 1.2, 0.2)

		UiTheme.label({
			parent = featHeader,
			position = UDim2.fromOffset(12, 2),
			size = UDim2.fromOffset(280, 20),
			text = L.t("ui.shop.featured"),
			font = "Title",
			textSize = UiTheme.TextSizes.MD,
			color = C.GoldBright,
		})
		UiTheme.label({
			parent = featHeader,
			position = UDim2.fromOffset(12, 20),
			size = UDim2.fromOffset(320, 16),
			text = L.t("ui.shop.featuredSub"),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
		})

		timerLabel = UiTheme.label({
			parent = featHeader,
			anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, -12, 0.5, 0),
			size = UDim2.fromOffset(180, 22),
			text = L.t("ui.shop.refreshesIn", { time = formatDailyCountdown() }),
			font = "Number",
			textSize = UiTheme.TextSizes.SM,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Right,
		})

		-- Fila de 5 tarjetas escaparate destacadas
		local featuredIds = getDailyFeaturedIds()
		local featGridFrame = Instance.new("Frame")
		featGridFrame.LayoutOrder = 2
		featGridFrame.Size = UDim2.fromOffset(listWidth - 10, 212)
		featGridFrame.BackgroundTransparency = 1
		featGridFrame.Parent = content

		local fCols = math.min(#featuredIds, mobile and 3 or 5)
		local fGap = 8
		local fCardW = math.floor((listWidth - 10 - fGap * (fCols - 1)) / fCols)
		local fLayout = Instance.new("UIListLayout")
		fLayout.FillDirection = Enum.FillDirection.Horizontal
		fLayout.Padding = UDim.new(0, fGap)
		fLayout.SortOrder = Enum.SortOrder.LayoutOrder
		fLayout.Parent = featGridFrame

		for i = 1, fCols do
			buildItemCard(featGridFrame, featuredIds[i], fCardW, 210, i, true)
		end

		-- Cabecera de Catálogo Completo debajo
		local catHeader = Instance.new("Frame")
		catHeader.LayoutOrder = 3
		catHeader.Size = UDim2.fromOffset(listWidth - 10, 30)
		catHeader.BackgroundColor3 = C.BgHeader
		catHeader.BorderSizePixel = 0
		catHeader.Parent = content
		UiTheme.corner(catHeader, UiTheme.Radius.SM)
		UiTheme.stroke(catHeader, C.GoldDim, 1, 0.25)

		UiTheme.label({
			parent = catHeader,
			position = UDim2.fromOffset(12, 0),
			size = UDim2.new(1, -24, 1, 0),
			text = L.t("ui.shop.catalog"),
			font = "Title",
			textSize = UiTheme.TextSizes.MD,
			color = C.GoldBright,
		})

		-- Cuadrícula del catálogo completo debajo del escaparate
		local catCols = mobile and 2 or 3
		local catGap = 10
		local catCardW = math.floor((listWidth - 10 - catGap * (catCols - 1)) / catCols)
		local catCardH = 184

		local catalogIds = {}
		for _, id in Skins.Order do
			if id ~= "Default" and not Skins.Data[id].comingSoon then
				table.insert(catalogIds, id)
			end
		end
		if Auras and Auras.Order then
			for _, id in Auras.Order do
				table.insert(catalogIds, id)
			end
		end

		local rows = math.ceil(#catalogIds / catCols)
		local catGridHolder = Instance.new("Frame")
		catGridHolder.LayoutOrder = 4
		catGridHolder.Size = UDim2.fromOffset(listWidth - 10, rows * (catCardH + catGap))
		catGridHolder.BackgroundTransparency = 1
		catGridHolder.Parent = content

		local catGrid = Instance.new("UIGridLayout")
		catGrid.CellSize = UDim2.fromOffset(catCardW, catCardH)
		catGrid.CellPadding = UDim2.fromOffset(catGap, catGap)
		catGrid.SortOrder = Enum.SortOrder.LayoutOrder
		catGrid.Parent = catGridHolder

		for idx, id in catalogIds do
			buildItemCard(catGridHolder, id, catCardW, catCardH, idx, false)
		end
	else
		-- Pestañas individuales: Skins, Auras, Boosts, Souls
		timerLabel = nil
		local cols = mobile and 2 or 3
		local gap = 10
		local cw = math.floor((listWidth - gap * cols - 8) / cols)
		local ch = 188
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(cw, ch)
		grid.CellPadding = UDim2.fromOffset(gap, gap)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = content

		if tab == "Skins" then
			for idx, id in Skins.Order do
				local s = Skins.Data[id]
				if s and id ~= "Default" and not s.comingSoon then
					local matches = (not s.weapon or s.weapon == weapon)
						and (rarity == "all" or s.rarity == rarity)
						and (ownership == "all" or (ownership == "owned" and ownedSkinsMap[id]) or (ownership == "available" and not ownedSkinsMap[id]))
					if matches then
						buildItemCard(content, id, cw, ch, idx, s.roulette == true)
					end
				end
			end
		elseif tab == "Auras" and Auras and Auras.Order then
			for idx, id in Auras.Order do
				local a = Auras.Data[id]
				if a and (auraKind == "all" or a.kind == auraKind) then
					buildItemCard(content, id, cw, ch, idx, false)
				end
			end
		elseif tab == "Boosts" then
			for idx, b in BOOST_ITEMS do
				buildItemCard(content, b.id, cw, ch, idx, true)
			end
		elseif tab == "Souls" then
			for idx, s in SOUL_ITEMS do
				buildItemCard(content, s.id, cw, ch, idx, true)
			end
		end
	end

	if not selected or not table.find(shown, selected) then
		selected = shown[1]
	end
	if selected then
		inspect(selected)
	end

	messageLabel = UiTheme.label({
		name = "StatusMessage",
		parent = panel,
		position = UDim2.fromOffset(22, height - 34),
		size = UDim2.fromOffset(width - 280, 24),
		text = L.t("ui.shop.noRobuxNotice"),
		font = "Bold",
		textSize = UiTheme.TextSizes.XS,
		color = C.GoldBright,
	})

	UiTheme.label({
		parent = panel,
		position = UDim2.fromOffset(width - 250, height - 34),
		size = UDim2.fromOffset(228, 24),
		text = L.t("ui.gamepadHint"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextMuted,
		alignX = Enum.TextXAlignment.Right,
	})

	if UIS.GamepadEnabled and not modal then
		GuiService.SelectedObject = firstButton
	end
end

----------------------------------------------------------------------
-- Apertura / cierre y bucle de rotación
----------------------------------------------------------------------
function setOpen(value)
	if opened == value then return end
	if value and player:GetAttribute("InMatch") then
		return
	end
	opened = value
	transition += 1
	local version = transition
	player:SetAttribute("ShopOpen", value)
	if value then
		player:SetAttribute("SettingsOpen", false)
		player:SetAttribute("ArmoryOpen", false)
	end
	player:SetAttribute("MenuOpen", value or player:GetAttribute("SettingsOpen") == true or player:GetAttribute("ArmoryOpen") == true)
	UiTheme.playSound(value and "UI_MenuOpen" or "UI_MenuClose")

	if value then
		backdrop.Visible = true
		panel.Visible = true
		render()
		panel.GroupTransparency = 1
		panel.Position = UDim2.fromScale(0.5, 0.53)
	else
		dismiss()
		destroyAuraWorldPreview()
		drag = nil
		stick = Vector2.zero
		zoomAxis = 0
		backdrop.Visible = false
		GuiService.SelectedObject = nil
	end

	TweenService:Create(panel, UiTheme.Anim.TweenNorm, {
		GroupTransparency = value and 0 or 1,
		Position = UDim2.fromScale(0.5, value and 0.5 or 0.53),
	}):Play()

	if not value then
		task.delay(UiTheme.Anim.Normal, function()
			if version == transition then
				panel.Visible = false
				table.clear(spins)
			end
		end)
	end
end

player:GetAttributeChangedSignal("SettingsOpen"):Connect(function()
	if player:GetAttribute("SettingsOpen") and opened then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("ArmoryOpen"):Connect(function()
	if player:GetAttribute("ArmoryOpen") and opened then
		setOpen(false)
	end
end)

task.spawn(function()
	local toggleMenu = player:WaitForChild("ToggleMenu", 15)
	if toggleMenu and toggleMenu:IsA("BindableEvent") then
		toggleMenu.Event:Connect(function()
			if not opened and (not serverFeatured or (serverResetAt and os.time() >= serverResetAt)) then fetchServerFeatured() end
			setOpen(not opened)
		end)
	end
end)

UIS.InputChanged:Connect(function(input)
	if not opened or modal then return end
	if input.KeyCode == Enum.KeyCode.Thumbstick2 then
		stick = Vector2.new(input.Position.X, input.Position.Y)
	end
	if input.KeyCode == Enum.KeyCode.ButtonL2 then zoomAxis = input.Position.Z end
	if input.KeyCode == Enum.KeyCode.ButtonR2 then zoomAxis = -input.Position.Z end
	if drag and detailSpin and (input == drag or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - lastPosition
		lastPosition = input.Position
		detailSpin.yaw += delta.X * 0.012
		detailSpin.pitch = math.clamp(detailSpin.pitch + delta.Y * 0.01, -0.65, 0.65)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input == drag or input.UserInputType == Enum.UserInputType.MouseButton1 then
		drag = nil
	end
	if input.KeyCode == Enum.KeyCode.ButtonL2 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		zoomAxis = 0
	end
end)

UIS.InputBegan:Connect(function(input, processed)
	if not opened then return end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		if modal then
			dismiss()
		elseif not processed or input.KeyCode == Enum.KeyCode.ButtonB then
			setOpen(false)
		end
	end
end)

local lastClockUpdate = 0
RunService.RenderStepped:Connect(function(dt)
	if not opened then return end

	local now = os.clock()
	if timerLabel and timerLabel.Parent and (now - lastClockUpdate >= 1.0) then
		lastClockUpdate = now
		timerLabel.Text = L.t("ui.shop.refreshesIn", { time = formatDailyCountdown() })
	end

	for i = #spins, 1, -1 do
		local v = spins[i]
		if not v.vp.Parent then
			table.remove(spins, i)
		else
			local visible = not modal or v.vp:IsDescendantOf(modal)
			if content and v.vp:IsDescendantOf(content) then
				local y = v.vp.AbsolutePosition.Y
				visible = visible and (y + v.vp.AbsoluteSize.Y > content.AbsolutePosition.Y) and (y < content.AbsolutePosition.Y + content.AbsoluteSize.Y)
			end
			if visible then
				if v.manual then
					v.yaw += stick.X * dt * 2.0
					v.pitch = math.clamp(v.pitch - stick.Y * dt, -0.65, 0.65)
					v.zoom = math.clamp(v.zoom + zoomAxis * dt * 0.65, 0.55, 1.65)
				else
					v.yaw += dt * 0.45
				end
				if v.flashUntil and os.clock() < v.flashUntil then
					v.yaw += dt * 8
				end
				local rot = v.horizontal and CFrame.Angles(v.yaw, v.pitch, 0) or CFrame.Angles(v.pitch, v.yaw, 0)
				v.model:PivotTo(rot * v.base)
				v.camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, v.distance * v.zoom), Vector3.zero)
			end
		end
	end
end)

for _, attr in { "OwnedSkins", "EquippedSkin", "OwnedAuras", "EquippedAura", "WeaponId", "InfusionId", "InMatch", "OptUiScale" } do
	player:GetAttributeChangedSignal(attr):Connect(function()
		if opened and not busy then
			render()
		end
	end)
end

L.Changed:Connect(function()
	if opened then render() end
end)

local lastSize = Vector2.zero
RunService.Heartbeat:Connect(function()
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize ~= lastSize then
		lastSize = cam.ViewportSize
		if opened then render() end
	end
end)

task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 15)
	local coins = ls and ls:WaitForChild("Coins", 15)
	if coins then
		coins.Changed:Connect(function()
			if opened and not busy and not modal then
				render()
			end
		end)
	end
end)
