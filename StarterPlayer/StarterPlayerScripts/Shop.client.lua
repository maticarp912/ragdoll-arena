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
local Vault = require(RS:WaitForChild("VaultClient"))
local Rewards = require(RS:WaitForChild("Rewards"))
local Format = require(RS:WaitForChild("Format"))
local Device = require(RS:WaitForChild("Device")) -- 11/11: PC, celular o consola
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
		icon = "boost_souls",
		color = C.Coins,
		currency = "Coins",
		price = 1200,
	},
	{
		id = "Boost2xXp",
		kind = "Boost",
		rarity = "Epic",
		nameKey = "ui.shop.boost2xXp",
		descKey = "ui.shop.boost2xXpDesc",
		icon = "boost_xp",
		color = C.Guard,
		currency = "Coins",
		price = 1400,
	},
	{
		id = "BoostSoulMagnet",
		kind = "Boost",
		rarity = "Legendary",
		nameKey = "ui.shop.boostSoulMagnet",
		descKey = "ui.shop.boostSoulMagnetDesc",
		icon = "boost_magnet",
		color = C.HealthBright,
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
		icon = "soul",
		color = C.Coins,
		amount = 500,
	},
	{
		id = "Medium",
		kind = "Souls",
		rarity = "Rare",
		nameKey = "ui.shop.soulsPack2",
		descKey = "ui.shop.soulsPack2Desc",
		icon = "soul",
		color = C.Coins,
		amount = 2000,
	},
	{
		id = "Large",
		kind = "Souls",
		rarity = "Legendary",
		nameKey = "ui.shop.soulsPack3",
		descKey = "ui.shop.soulsPack3Desc",
		icon = "soul",
		color = C.GoldBright,
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
-- 12/11/2026 (pedido del usuario): categorías en una barra lateral a la izquierda, estilo tienda de temporada
local SIDEBAR = 210
local panel = UiTheme.panel({
	name = "ShopWindow",
	parent = gui,
	-- 10/11/2026: Frame en vez de CanvasGroup. Con vistas 3D girando adentro, el CanvasGroup redibujaba toda
	-- la ventana en cada frame y la tienda y el mouse iban a tirones.
	canvasGroup = false,
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

local cardPreviews = {}
local nextCardPreviewUpdate = 0
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
local vaultEntries, vaultLoading, vaultTarget, luckOdds
local vaultScroll = Vector2.zero
local inspecting = false
local compactShop = false

local function loadChestOdds()
 local rewards = remotes and remotes:FindFirstChild("Rewards")
 if not rewards then return nil end
 local function read() return rewards:InvokeServer("GetState") end
 local ok, accepted, state = pcall(read)
 if ok and not accepted then
  task.wait(Rewards.Interval + 0.05)
  ok, accepted, state = pcall(read)
 end
 if not ok or not accepted then return nil end
 local lines = { L.t("mz.highRarityOdds") }
 local lang = L.language()
 for level, id in Rewards.BoxOrder do
  local box = state.boxes[id]
  local base, boosted = 0, 0
  for _, row in box.probabilities do
   if Rewards.RarityRank[row.rarity] >= Rewards.GoodRank then
    base += row.baseProbability
    boosted += row.previewProbability
   end
  end
  table.insert(lines, L.t("mz.level", { level = level }) .. "  " .. Format.percent(base, lang) .. " → " .. Format.percent(boosted, lang))
 end
 return table.concat(lines, "\n")
end

local function loadVault()
 if vaultLoading then return end
 vaultLoading = true
 task.spawn(function()
  vaultEntries = Vault.catalog() or {}
  for _, item in vaultEntries do
   if item.available and item.kind == "Luck" then luckOdds = loadChestOdds() break end
  end
  vaultLoading = false
  if opened and tab == "Vault" then render() end
 end)
end

local vaultCoinsOnly = false -- 12/11/2026: la sección Monedas muestra solo los paquetes de monedas
local function openVault(section)
 vaultCoinsOnly = section == "Gems"
 if player:GetAttribute("InMatch") then return end
 vaultTarget = section
 tab = "Vault" inspecting = false
 if opened then render() else setOpen(true) end
 loadVault()
end

local rarities = { "all", "Common", "Rare", "Epic", "Legendary", "Exclusive" }
local filters = { "all", "owned", "available" }
local auraKinds = { "all", "Body", "Weapon" }

----------------------------------------------------------------------
-- Pedestal de vista previa de Auras en el mundo (Contrato C11)
----------------------------------------------------------------------
local auraPreviewStage = nil
local auraTryCleanup = nil
local auraPreviewActive = false
local auraOrbitConn = nil
local auraExitButton = nil

-- 11/11/2026: vista previa de auras con salida explícita. Antes la cámara volvía sola a los 4 s al tipo que
-- tenía antes; si tocabas «Probar» dos veces, guardaba la cámara de la vista previa y quedaba trabada ahí.
-- Ahora la cámara gira despacio alrededor de tu personaje hasta que tocás «Salir de la vista previa»
-- (o Esc / B del mando) y siempre vuelve a Custom siguiendo a tu Humanoid.
local AURA_PREVIEW = { Distance = 9, Height = 2.2, FocusY = 0.8, OrbitSpeed = 0.35 }

local function destroyAuraWorldPreview()
	if auraTryCleanup then
		pcall(auraTryCleanup)
		auraTryCleanup = nil
	end
	if auraPreviewStage then
		auraPreviewStage:Destroy()
		auraPreviewStage = nil
	end
end

local function showAuraWorldPreview(auraId)
	destroyAuraWorldPreview()
	if not AuraFx or not Auras or not Auras.Data[auraId] then return false end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local data = Auras.Data[auraId]
	local target = char
	if data.kind ~= "Body" then
		target = char:FindFirstChildOfClass("Tool")
		if not target then
			-- Sin arma en la mano (lobby): arma de muestra flotando delante del pecho
			local stage = Builder.buildModel(weapon, player:GetAttribute("EquippedSkin") or "Default")
			stage.Name = "AuraPreviewWeapon"
			for _, part in stage:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
				end
			end
			stage:PivotTo(root.CFrame * CFrame.new(0, 0.6, -2.2) * CFrame.Angles(math.rad(-70), 0, 0))
			stage.Parent = workspace
			auraPreviewStage = stage
			target = stage
		end
	end
	local ok, cleanup = pcall(AuraFx.attach, target, auraId, { character = char, preview = true })
	if ok and type(cleanup) == "function" then auraTryCleanup = cleanup end
	return ok
end

-- Devuelve la cámara al personaje: Custom y CameraSubject = tu Humanoid. Seguro de llamar varias veces.
local function restoreCamera()
	local cam = workspace.CurrentCamera
	if not cam then return end
	cam.CameraType = Enum.CameraType.Custom
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
end

local function exitAuraPreview(reopen)
	if auraOrbitConn then auraOrbitConn:Disconnect() auraOrbitConn = nil end
	if auraExitButton then auraExitButton:Destroy() auraExitButton = nil end
	destroyAuraWorldPreview()
	if not auraPreviewActive then return end
	auraPreviewActive = false
	restoreCamera()
	if reopen and opened then
		panel.Visible = true
		backdrop.Visible = true
	end
end

local function tryAuraOnCharacter(auraId)
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not cam or not root then return end
	if auraOrbitConn then auraOrbitConn:Disconnect() auraOrbitConn = nil end
	if auraExitButton then auraExitButton:Destroy() auraExitButton = nil end
	if not showAuraWorldPreview(auraId) then return end
	auraPreviewActive = true
	panel.Visible = false
	backdrop.Visible = false
	cam.CameraType = Enum.CameraType.Scriptable
	local angle = 0
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local baseYaw = math.atan2(look.X, look.Z)
	auraOrbitConn = RunService.RenderStepped:Connect(function(dt)
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not r then exitAuraPreview(true) return end
		angle += dt * AURA_PREVIEW.OrbitSpeed
		local yaw = baseYaw + angle
		local focus = r.Position + Vector3.new(0, AURA_PREVIEW.FocusY, 0)
		local offset = Vector3.new(math.sin(yaw), 0, math.cos(yaw)) * AURA_PREVIEW.Distance + Vector3.new(0, AURA_PREVIEW.Height, 0)
		cam.CFrame = CFrame.lookAt(focus + offset, focus)
	end)
	auraExitButton = UiTheme.button({
		name = "ExitAuraPreview",
		parent = gui,
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -40),
		size = UDim2.fromOffset(280, 52),
		text = L.t("ui.aura.exitPreview"),
		font = "Header",
		textSize = UiTheme.TextSizes.LG,
		variant = "gold",
		zIndex = 60,
		onClick = function() exitAuraPreview(true) end,
	})
	if Device.isGamepad() then GuiService.SelectedObject = auraExitButton end
end

UIS.InputBegan:Connect(function(input)
	if auraPreviewActive and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then
		exitAuraPreview(true)
	end
end)
player.CharacterRemoving:Connect(function() exitAuraPreview(false) end)

----------------------------------------------------------------------
-- Rotación diaria determinista para la sección «Destacado del Día» (D12)
----------------------------------------------------------------------
-- I2 (integración 0.2): la lista oficial la calcula el servidor (`Shop` → `GetFeatured`, día de Argentina).
-- El cálculo local queda solo como respaldo si el servidor no respondió.
local serverFeatured, serverResetAt = nil, nil
-- 10/11/2026: la pestaña «Almas» es una herramienta de prueba (suma almas gratis, acción DebugCoins), no una
-- compra. Solo se muestra si el servidor dice que este jugador puede depurar (GetBoosts → debugSouls).
local debugSouls = false
local function fetchServerFeatured()
	if not remote then return end
	local okB, successB, info = pcall(function() return remote:InvokeServer("GetBoosts") end)
	if okB and successB and type(info) == "table" then debugSouls = info.debugSouls == true end
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
		if skinId ~= "Default" and not skin.comingSoon and not skin.roulette and not skin.boxOnly then table.insert(ids, skinId) end
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


-- 11/11/2026: píldora de saldo compartida (ReplicatedStorage/BalancePill)
local BalancePillModule = require(RS:WaitForChild("BalancePill"))
local function balancePill(parent, position, size, kind, amount, getGems)
	return BalancePillModule.create(parent, position, size, kind, amount, getGems)
end

local function pending(item)
	if not item then return true end
	if item.comingSoon then return true end
	if item.currency == "Robux" then return (item.productId or 0) == 0 end
	return false
end

local function priceText(item)
	if not item then return "" end
	if item.kind == "Souls" then
		return "+" .. L.t("ui.souls", { amount = item.amount or 0 })
	end
	if item.currency == "Free" then return L.t("Free") end
	if item.currency == "Coins" then return L.t("ui.souls", { amount = item.price or 0 }) end
	if item.currency == "Gems" then return L.t("mz.gemsAmount", { amount = item.price or 0 }) end
	if item.currency == "Robux" and (item.productId or 0) > 0 then return L.t("mz.skinVault") end
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
		if rec.requiredPass then return "vipPass" end
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
	vp.Ambient = C.PreviewAmbient
	vp.LightColor = C.PreviewLight
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.Parent = parent
	UiTheme.corner(vp, UiTheme.Radius.SM)

	local world = Instance.new("WorldModel")
	world.Parent = vp
	local camera = Instance.new("Camera")
	camera.FieldOfView = manual and 34 or 28
	camera.Parent = vp
	vp.CurrentCamera = camera

	local model = Builder.buildModel(wid, sid)
	model.Parent = world
	local cfBox, size = model:GetBoundingBox()
	local center = model.PrimaryPart and (model.PrimaryPart.CFrame:Inverse() * cfBox.Position) or Vector3.zero
	local horizontal = not manual
	local base = (horizontal and CFrame.Angles(0, math.pi / 2, math.rad(26)) or CFrame.Angles(math.rad(-16), math.pi / 4, 0))
		* CFrame.new(-center)
	local dist = math.max(size.X, size.Y, size.Z) * (horizontal and 0.88 or 1.18)
	model:PivotTo(base)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, dist), Vector3.zero)

	local entry = {
		vp = vp,
		model = model,
		camera = camera,
		base = base,
		distance = dist,
		yaw = 0,
		pitch = 0,
		zoom = 1,
	}
	return vp, entry
end

local function updateCardPreviews()
	local loadVisible = content and content.Visible and not modal
	local clipStart = loadVisible and content.AbsolutePosition
	local clipEnd = loadVisible and (clipStart + content.AbsoluteWindowSize)
	for _, item in cardPreviews do
		local card, rect = item.card, item.rect
		local scale = card.AbsoluteSize.X / card.Size.X.Offset
		local start = card.AbsolutePosition + Vector2.new(rect[1], rect[2]) * scale
		local finish = start + Vector2.new(rect[3], rect[4]) * scale
		item.visible = loadVisible and scale > 0 and start.X < clipEnd.X and finish.X > clipStart.X
			and start.Y < clipEnd.Y and finish.Y > clipStart.Y
		if not item.visible and item.viewport then
			item.viewport:Destroy()
			item.viewport = nil
		end
	end
	-- Repartir la construcción de los modelos al abrir o desplazar la grilla.
	local built = 0
	for _, item in cardPreviews do
		if item.visible and not item.viewport then
			item.viewport = preview(item.card, item.weapon, item.id, item.rect, false)
			built += 1
			if built == 2 then break end
		end
	end
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
	if Device.isGamepad() and savedFocusBeforeModal and savedFocusBeforeModal.Parent then
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
	local target = remote
	if action == "BuySkinGems" then target = remotes and remotes:FindFirstChild("Monetization") end
	if not target then return end
	busy = true
	local ok, success, msg = pcall(function()
		return target:InvokeServer(action, id)
	end)
	busy = false
	dismiss()
	if not ok then
		UiTheme.playSound("UI_Error")
		setStatus(L.t("error"), true)
		return
	end

	if success then
		UiTheme.playSound((action == "Buy" or action == "BuyAura" or action == "BuySkinGems") and "UI_PurchaseOK" or "UI_Equip")
		if detailSpin then
			detailSpin.flashUntil = os.clock() + 0.35
		end
	else
		UiTheme.playSound("UI_Error")
	end

	render()
	if type(msg) == "table" and msg.key == "mz.noGems" and type(msg.missing) == "number" then
		messageLabel.Text = ""
		local missing = UiTheme.button({ parent = panel, position = messageLabel.Position - UDim2.fromOffset(0, 14), size = UDim2.new(messageLabel.Size.X.Scale, messageLabel.Size.X.Offset, 0, 44),
			text = L.t("mz.missingGems", { amount = msg.missing }), textSize = UiTheme.TextSizes.XS, onClick = function() openVault("Gems") end })
		missing.TextWrapped = true
		return
	end
	if type(msg) == "table" and msg.key == "noCoins" and type(msg.missing) == "number" then
		setStatus(L.t("mz.missingSoulsEarn", { amount = msg.missing }), true)
	elseif type(msg) == "table" and msg.key then
		setStatus(L.t(msg.key, msg.params), not success)
	elseif type(msg) == "string" then
		setStatus(L.t(msg), not success)
	else
		setStatus(success and L.t("purchaseSuccess") or L.t("error"), not success)
	end
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
		size = UDim2.fromOffset(math.min(440, panel.Size.X.Offset - 28), 320),
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
		local pv = preview(box, item.weapon or weapon, id, { (box.Size.X.Offset - 220) / 2, 48, 220, 120 }, false)
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
		scaled = true,
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
	if Device.isGamepad() then
		GuiService.SelectedObject = confirmBtn
	end
end

----------------------------------------------------------------------
-- Panel derecho de inspección detallada (3D Grande)
----------------------------------------------------------------------
local function inspect(id)
	selected = id
	for _, ch in detail:GetChildren() do
		if not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" and ch.Name ~= "FrameArt" then
			ch:Destroy()
		end
	end
	detailSpin = nil

	local rec, kind = getItemRecord(id)
	if not rec then return end

	local rarityName = Skins.Data[id] and Rewards.skinRarity(id, rec) or rec.rarity
	local rSpec = rarityName and UiTheme.Rarities[Rewards.rarityTheme(rarityName)] or nil
	if rSpec then
		UiTheme.rarityBadge(detail, Rewards.rarityTheme(rarityName), L.t(rarityName), UDim2.fromOffset(16, 12))
	end

	-- Insignia de Ruleta / Gran Premio Semanal (D15)
	if rec.roulette then
		local rBadge = Instance.new("Frame")
		rBadge.AnchorPoint = Vector2.new(1, 0)
		rBadge.Position = UDim2.new(1, -16, 0, 12)
		rBadge.Size = UDim2.fromOffset(rec.weeklyPrize and 178 or 110, 22)
		rBadge.BackgroundColor3 = C.GoldDim
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
		scaled = compactShop,
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
		truncate = compactShop and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
	})

	local vpW = detail.Size.X.Offset - 32
	local vpH = math.clamp(math.floor((detail.Size.Y.Offset - 210) * 0.62), 76, 230)

	if kind == "Aura" then
		destroyAuraWorldPreview()

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
		UiTheme.button({
			name = "TryAuraBtn",
			parent = stageBox,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -32),
			size = UDim2.fromOffset(190, 34),
			text = L.t("ui.aura.tryOn"),
			variant = "gold",
			onClick = function() tryAuraOnCharacter(id) end,
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
		for mode, key in { Keyboard = "mz.rotateKeyboard", Gamepad = "mz.rotateGamepad", Touch = "mz.rotateTouch" } do
			Device.showFor(UiTheme.label({
				parent = vp,
				anchor = Vector2.new(0.5, 1),
				position = UDim2.new(0.5, 0, 1, -6),
				size = UDim2.new(1, -12, 0, 16),
				text = L.t(key),
				font = "Body",
				textSize = UiTheme.TextSizes.XS,
				color = C.TextMuted,
				alignX = Enum.TextXAlignment.Center,
			}), mode)
		end
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
	local usesGems = rec.currency == "Gems"
	local missing = 0
	if st == "buy" and (usesGems or rec.currency == "Coins") then
		missing = math.max(0, rec.price - (usesGems and (player:GetAttribute("Gems") or 0) or Vault.souls(player)))
	end

	if st == "vipPass" then
		labelText = L.t("mz.pass.VIP")
	elseif st == "buy" and kind == "Skin" and rec.roulette then
		-- Solo ruleta (decisión del usuario, 10/11/2026): no se compra.
		labelText = L.t("ui.shop.rouletteOnly")
		variant = "secondary"
		disabled = true
	elseif missing > 0 then
		labelText = L.t(usesGems and "mz.missingGems" or "mz.missingSoulsEarn", { amount = missing })
		disabled = not usesGems
	elseif st == "buy" and rec.currency == "Robux" then
		labelText = L.t("mz.skinVault")
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

	local mainAction = UiTheme.button({
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
			if st == "vipPass" then openVault("VIP") return end
			if missing > 0 then if usesGems then openVault("Gems") end return end
			if st == "buy" and rec.currency == "Robux" then openVault(kind .. "." .. id) return end
			if kind == "Aura" then
				if st == "buy" then
					confirmPurchase(id, rec, "BuyAura")
				elseif st == "equip" then
					act("EquipAura", id)
				end
			elseif kind == "Skin" then
				if st == "buy" then
					confirmPurchase(id, rec, usesGems and "BuySkinGems" or "Buy")
				elseif st == "equip" then
					if rec.weapon and rec.weapon ~= player:GetAttribute("WeaponId") then
						act("SelectWeapon", rec.weapon)
					end
					act("Equip", id)
				end
			elseif kind == "Boost" then
				confirmPurchase(id, rec, "BuyBoost") -- integración 0.2: cobro real en el servidor (RewardService.buyBoost)
			elseif kind == "Souls" then
				act("DebugCoins", id)
			end
		end,
	})
	mainAction.TextWrapped = true
	mainAction.TextScaled = true
	UiTheme.textConstraint(mainAction, UiTheme.TextSizes.XS, UiTheme.TextSizes.MD)
end

----------------------------------------------------------------------
-- Renderizado completo del Escaparate y Catálogo
----------------------------------------------------------------------

local function renderVault(parent, width, mobile)
 local y = 0
 local firstPassY, firstPackY, targetY
 for _, group in { "Pass", "Product" } do
  local offers = {}
  for _, item in vaultEntries or {} do
   if item.available and item.type == group and (not vaultCoinsOnly or item.kind == "Gems") then table.insert(offers, item) end
  end
  if #offers == 0 then continue end
  if group == "Pass" then firstPassY = y else firstPackY = y end
  UiTheme.label({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, 36),
   text = L.t(group == "Pass" and "mz.passes" or "mz.packs"), font = "Title", textSize = UiTheme.TextSizes.XL, color = C.GoldBright })
  y += 40
  local columns = mobile and 1 or (group == "Pass" and 2 or 3)
  local gap = 12
  local cardWidth = math.floor((width - gap * (columns - 1)) / columns)
  local heights, offsets = {}, {}
  for index, item in offers do
   local row = math.floor((index - 1) / columns) + 1
   local height = group == "Pass" and 186 or (item.kind == "Luck" and 298 or 165)
   heights[row] = math.max(heights[row] or 0, height)
  end
  local sectionHeight = 0
  for row, rowHeight in heights do offsets[row] = sectionHeight sectionHeight += rowHeight + gap end
  for index, item in offers do
   local row = math.floor((index - 1) / columns) + 1
   local col = (index - 1) % columns
   local top = y + offsets[row]
   local cardHeight = group == "Pass" and 186 or (item.kind == "Luck" and 298 or 165)
   if vaultTarget == item.key or (vaultTarget == "Gems" and item.kind == "Gems" and targetY == nil) then targetY = top end
   local card = UiTheme.panel({ parent = parent, position = UDim2.fromOffset(col * (cardWidth + gap), top),
    size = UDim2.fromOffset(cardWidth, cardHeight), borderColor = item.badge and C.GoldBright or C.BorderDefault, ornaments = group == "Pass" })
   local title, description = Vault.text(item)
   -- 11/11: arte del usuario por oferta (UiAssets); sin imagen subida se dibuja el ícono de antes
   local artByKey = { SkipOpening = "pass_skip", VIP = "pass_vip", Spins3 = "pack_spins_3", Luck30 = "amulet" }
   local iconByKind = { Gems = "gem", Spins = "pack_spins_3", Luck = "amulet", Aura = "crown", Skin = "armory" }
   local iconName = artByKey[item.key] or (item.kind == "Gems" and item.amount and ("pack_gems_" .. item.amount))
   if not iconName or not UiAssets.imageUri(iconName) then iconName = iconByKind[item.kind] or "stamina" end
   local crest = UiAssets.icon(card, iconName, UiAssets.imageUri(iconName) and 40 or 30, item.kind == "Gems" and C.Guard or C.GoldBright)
   crest.Position = UDim2.fromOffset(14, 18)
   UiTheme.label({ parent = card, position = UDim2.fromOffset(54, 12), size = UDim2.new(1, -68, 0, 42),
    text = title, font = "Title", scaled = true, textSize = UiTheme.TextSizes.XL, color = C.TextPrimary })
   UiTheme.label({ parent = card, position = UDim2.fromOffset(14, 58), size = UDim2.new(1, -28, 0, 62),
    text = description, textSize = UiTheme.TextSizes.SM, alignY = Enum.TextYAlignment.Top, color = C.TextSecondary })
   if item.badge then
    UiTheme.label({ parent = card, position = UDim2.new(0, 14, 1, -50), size = UDim2.new(1, -150, 0, 32),
     text = L.t("mz.badge." .. item.badge), font = "Bold", scaled = true, textSize = UiTheme.TextSizes.XS, color = C.GoldBright })
   end
   if item.kind == "Luck" then
    UiTheme.label({ parent = card, position = UDim2.fromOffset(14, 115), size = UDim2.new(1, -28, 0, 114),
     text = luckOdds or L.t("loading"), font = "Number", textSize = UiTheme.TextSizes.XS,
     alignY = Enum.TextYAlignment.Top, color = C.Accent })
   end
   local buy = Vault.priceButton({ parent = card, anchor = Vector2.new(1, 1), position = UDim2.new(1, -14, 1, -12),
    size = UDim2.fromOffset(112, 44), textSize = UiTheme.TextSizes.SM, disabled = item.kind == "Luck" and not luckOdds,
    onClick = function()
     if busy then return end
     busy = true
     local ok, reason = Vault.prompt(item.key)
     busy = false
     if not ok then setStatus(L.t("mz.offer." .. (reason or "unavailable")), true) loadVault() end
    end }, item)
   if item.owned then buy.TextScaled = true UiTheme.textConstraint(buy, UiTheme.TextSizes.XS, UiTheme.TextSizes.SM) end
  end
  y += sectionHeight
 end
 if not firstPassY and not firstPackY then
  UiTheme.label({ parent = parent, position = UDim2.fromOffset(4, 16), size = UDim2.new(1, -12, 0, 48),
   text = L.t(vaultEntries == nil and "loading" or "mz.noOffers"), textSize = UiTheme.TextSizes.MD, color = C.TextSecondary })
 end
 parent.AutomaticCanvasSize = Enum.AutomaticSize.None
 parent.CanvasSize = UDim2.fromOffset(0, y)
 if vaultTarget and vaultEntries then
  local target = targetY or firstPackY or firstPassY or 0
  vaultTarget = nil
  task.defer(function() if parent.Parent then parent.CanvasPosition = Vector2.new(0, target) end end)
 end
end

function render()
	if content and content.Parent and content.Name == "VaultScroll" then vaultScroll = content.CanvasPosition end
	table.clear(cardPreviews)
	nextCardPreviewUpdate = 0
	detailSpin = nil
	for _, ch in panel:GetChildren() do
		if ch ~= scale and ch ~= modal and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" and ch.Name ~= "FrameArt" then
			ch:Destroy()
		end
	end

	local cam = workspace.CurrentCamera
	local viewport = cam and cam.ViewportSize or Vector2.new(BASE_W, BASE_H)
	local mobile = viewport.X < 780
	local insetA, insetB = GuiService:GetGuiInset()
	local usable = viewport - insetA - insetB
	local width = mobile and math.min(700, usable.X - 28) or BASE_W
	local height = mobile and math.clamp(usable.Y - 28, 540, 760) or BASE_H
	compactShop = mobile
	local side = mobile and 0 or SIDEBAR
	panel.Size = UDim2.fromOffset(width + side, height)
	scale.Scale = mobile and math.min(1, (usable.Y - 28) / height) or UiTheme.computeScale(usable, width + side, height, player)

	-- Cabecera: título del Escaparate, saldo de monedas, botón Abrir Armería y botón Cerrar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, mobile and 143 or 58)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = panel
	UiTheme.corner(header, UiTheme.Radius.MD)

	local shopIcon = UiAssets.icon(header, "coin", 26, C.GoldBright)
	shopIcon.AnchorPoint = Vector2.new(0, 0.5)
	shopIcon.Position = mobile and UDim2.fromOffset(18, 22) or UDim2.new(0, 18, 0.5, 0)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 6),
		size = mobile and UDim2.new(1, -70, 0, 34) or UDim2.fromOffset(360, 28),
		text = L.t("ui.shop.title"),
		scaled = mobile,
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
	})
	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 32),
		size = UDim2.fromOffset(380, 18),
		text = mobile and "" or L.t("ui.shop.subtitle"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
	})

	local balanceW = mobile and math.floor((width - 48) / 2) or 148
	balancePill(header, mobile and UDim2.new(0.5, -4, 0, 68) or UDim2.new(1, -444, 0.5, 0),
		UDim2.fromOffset(balanceW, 44), "Coins", Vault.souls(player))
	balancePill(header, mobile and UDim2.new(1, -16, 0, 68) or UDim2.new(1, -290, 0.5, 0),
		UDim2.fromOffset(balanceW, 44), "Gems", player:GetAttribute("Gems") or 0, function() openVault("Gems") end)
	local armoryBtn = UiTheme.button({
		name = "OpenArmoryBtn",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = mobile and UDim2.new(1, -94, 0, 116) or UDim2.new(1, -130, 0.5, 0),
		size = UDim2.fromOffset(mobile and math.floor((width - 44) * 0.31) or 150, 44),
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

	armoryBtn.TextWrapped = true
	armoryBtn.TextScaled = true
	UiTheme.textConstraint(armoryBtn, UiTheme.TextSizes.XS, UiTheme.TextSizes.SM)
	UiTheme.button({
		name = "CloseButton",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = mobile and UDim2.new(1, -16, 0, 116) or UDim2.new(1, -16, 0.5, 0),
		size = UDim2.fromOffset(mobile and 70 or 104, 44),
		text = L.t("close"),
		variant = "secondary",
		onClick = function()
			setOpen(false)
		end,
	})

	local root = panel
	local sidebar, host
	if not mobile then
		sidebar = Instance.new("Frame")
		sidebar.Name = "Sidebar"
		sidebar.Position = UDim2.fromOffset(0, 66)
		sidebar.Size = UDim2.new(0, SIDEBAR, 1, -78)
		sidebar.BackgroundColor3 = C.BgAbyss
		sidebar.BackgroundTransparency = 0.35
		sidebar.BorderSizePixel = 0
		sidebar.Parent = root
		host = Instance.new("Frame")
		host.Name = "Content"
		host.BackgroundTransparency = 1
		host.Position = UDim2.fromOffset(SIDEBAR, 0)
		host.Size = UDim2.new(1, -SIDEBAR, 1, 0)
		host.Parent = root
	end
	local panel = host or root -- lo que sigue se dibuja a la derecha de la barra lateral

	-- Barra de pestañas del Escaparate: Destacado, Skins, Auras, Multiplicadores, Almas y Monedas
	local tabsBar = Instance.new(mobile and "ScrollingFrame" or "Frame")
	if mobile then
		tabsBar.AutomaticCanvasSize = Enum.AutomaticSize.X tabsBar.CanvasSize = UDim2.new()
		tabsBar.ScrollingDirection = Enum.ScrollingDirection.X tabsBar.ScrollBarThickness = 3 tabsBar.BorderSizePixel = 0
	end
	tabsBar.Name = "TabsBar"
	tabsBar.Position = UDim2.fromOffset(20, mobile and 149 or 66)
	tabsBar.Size = UDim2.new(1, -40, 0, 48)
	tabsBar.BackgroundTransparency = 1
	tabsBar.Parent = panel
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabsBar

	local firstButton = nil
	local tabDefs = {
		{ id = "Showcase", label = L.t("ui.shop.side.Weapons"), icon = "armory" },
		{ id = "Skins", label = L.t("ui.shop.tab.Skins"), icon = "attack" },
		{ id = "Auras", label = L.t("ui.shop.tab.Auras"), icon = "aura_crown" },
		{ id = "Boosts", label = L.t("ui.shop.side.Boosts"), icon = "boost_souls" },
		{ id = "Vault", label = L.t("mz.vault"), icon = "rewards" },
		{ id = "Coins", label = L.t("ui.shop.side.Souls"), icon = "gem" },
	}
	if debugSouls then table.insert(tabDefs, { id = "Souls", label = L.t("ui.shop.tab.Souls"), icon = "soul" }) end
	if tab == "Souls" and not debugSouls then tab = "Showcase" end
	for i, def in tabDefs do
		local b = UiTheme.tabButton({
			name = "Tab_" .. def.id,
			parent = tabsBar,
			layoutOrder = i,
			size = UDim2.fromOffset(mobile and 126 or 158, 42),
			text = def.label,
			active = tab == def.id,
			onClick = function()
				if def.id == "Vault" then openVault(nil) return end
				if def.id == "Coins" then openVault("Gems") return end
				tab = def.id inspecting = false
				render()
			end,
		})
		b.TextWrapped = true
		if def.id == tab then
			firstButton = b
			if mobile then tabsBar.CanvasPosition = Vector2.new((i - 1) * 134, 0) end
		end
	end

	-- Barra lateral (PC y mando): categorías grandes, la activa en dorado con una marca a la izquierda
	if sidebar then
		tabsBar.Visible = false
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 4)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = sidebar
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 14)
		pad.Parent = sidebar
		for i, def in tabDefs do
			local active = (def.id == "Coins" and tab == "Vault" and vaultCoinsOnly)
				or (def.id == tab and not (def.id == "Vault" and vaultCoinsOnly))
			local b = Instance.new("TextButton")
			b.Name = "Side_" .. def.id
			b.LayoutOrder = i
			b.AutoButtonColor = false
			b.Size = UDim2.new(1, 0, 0, 54)
			b.BackgroundColor3 = C.BgPanel
			b.BackgroundTransparency = active and 0.2 or 1
			b.BorderSizePixel = 0
			b.Text = ""
			b.Parent = sidebar
			local mark = Instance.new("Frame")
			mark.Size = UDim2.new(0, 4, 1, -12)
			mark.Position = UDim2.fromOffset(0, 6)
			mark.BackgroundColor3 = C.GoldBright
			mark.BorderSizePixel = 0
			mark.Visible = active
			mark.Parent = b
			local ic = UiAssets.icon(b, def.icon, 24, active and C.GoldBright or C.TextSecondary)
			ic.AnchorPoint = Vector2.new(0, 0.5)
			ic.Position = UDim2.new(0, 18, 0.5, 0)
			UiTheme.label({ parent = b, position = UDim2.fromOffset(52, 0), size = UDim2.new(1, -58, 1, 0),
				text = UiTheme.upper(def.label), font = "Title", textSize = UiTheme.TextSizes.LG, scaled = true, maxTextSize = 24,
				minTextSize = 12, color = active and C.GoldBright or C.TextSecondary })
			b.MouseEnter:Connect(function() if not active then b.BackgroundTransparency = 0.6 end end)
			b.MouseLeave:Connect(function() if not active then b.BackgroundTransparency = 1 end end)
			b.Activated:Connect(function()
				UiTheme.playSound("UI_Click")
				if def.id == "Vault" then openVault(nil) return end
				if def.id == "Coins" then openVault("Gems") return end
				tab = def.id inspecting = false
				render()
			end)
			if active then firstButton = b end
		end
		-- título grande de la categoría arriba del contenido
		local current
		for _, def in tabDefs do
			if (def.id == "Coins" and tab == "Vault" and vaultCoinsOnly) or (def.id == tab and not (tab == "Vault" and vaultCoinsOnly)) then
				current = def
			end
		end
		UiTheme.label({ parent = panel, position = UDim2.fromOffset(20, 66), size = UDim2.new(1, -40, 0, 42),
			text = UiTheme.upper(current and current.label or ""), font = "Title", textSize = UiTheme.TextSizes.XXL or 30,
			scaled = true, maxTextSize = 34, color = C.TextPrimary })
	end

	local top = mobile and 204 or 116
	local listWidth = mobile and (width - 40) or math.floor(width * 0.61) - 24
	if tab == "Skins" then
		local weaponBar = Instance.new("Frame")
		weaponBar.Position = UDim2.fromOffset(20, top)
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
			position = UDim2.fromOffset(20, top + 40),
			size = UDim2.fromOffset(mobile and math.floor((listWidth - 8) / 2) or 195, 44),
			text = L.t("ui.filter.rarity", { value = L.t(rarity) }),
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				rarity = rarities[(table.find(rarities, rarity) % #rarities) + 1]
				render()
			end,
		})
		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(mobile and (24 + math.floor(listWidth / 2)) or 222, top + 40),
			size = UDim2.fromOffset(mobile and math.floor((listWidth - 8) / 2) or 195, 44),
			text = L.t("ui.filter.ownership", { value = L.t(ownership) }),
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				ownership = filters[(table.find(filters, ownership) % #filters) + 1]
				render()
			end,
		})
		top += 90
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
		top += 42
	end

	local contentH = height - top - 44
	local listHeight = contentH

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
	-- 12/11/2026: sin esto el borde de arriba de la primera fila de tarjetas quedaba cortado
	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingTop = UDim.new(0, 3)
	contentPad.PaddingLeft = UDim.new(0, 2)
	contentPad.Parent = content

	detail = UiTheme.panel({
		name = "DetailPanel",
		parent = panel,
		canvasGroup = false, -- 10/11: ver ShopWindow
		position = UDim2.fromOffset(mobile and 20 or (28 + listWidth), mobile and top or 116),
		size = UDim2.fromOffset(mobile and (width - 40) or (width - listWidth - 48), mobile and contentH or (height - 116 - 44)),
		bg = C.BgPanel,
		borderColor = C.Gold,
		ornaments = true,
	})

	if mobile then detail.Visible = inspecting content.Visible = not inspecting end
	local shown = {}
	local ownedSkinsMap = ownSkins()
	local ownedAurasMap = ownAuras()

	-- Helper para crear una tarjeta de artículo en el escaparate o catálogo
	local function buildItemCard(parentFrame, id, cardW, cardH, orderIdx, isFeaturedBanner)
		local rec, kind = getItemRecord(id)
		if not rec then return end
		table.insert(shown, id)

		local rarityName = Skins.Data[id] and Rewards.skinRarity(id, rec) or rec.rarity
		local rSpec = rarityName and UiTheme.Rarities[Rewards.rarityTheme(rarityName)] or nil
		local st = state(id)
		local borderCol = (selected == id or rec.weeklyPrize) and C.GoldBright or (rSpec and rSpec.color or C.Gold)

		local card = Instance.new("Frame")
		card.Name = "Card_" .. id
		card.LayoutOrder = orderIdx
		card.Size = UDim2.fromOffset(cardW, cardH)
		card.BackgroundColor3 = rec.weeklyPrize and C.BgCardSelected or C.BgCard
		card.BorderSizePixel = 0
		card.Parent = parentFrame
		UiTheme.corner(card, UiTheme.Radius.SM)
		local cardStroke = UiTheme.stroke(card, borderCol, (selected == id or isFeaturedBanner) and 2.2 or 1.4, st == "equipped" and 0 or 0.18)
		if isFeaturedBanner then
			UiTheme.ornamentCorners(card, borderCol, 10, 2)
		end

		if rSpec then
			UiTheme.rarityBadge(card, Rewards.rarityTheme(rarityName), L.t(rarityName), UDim2.fromOffset(8, 6)).ZIndex = 4
		end

		if rec.roulette then
			local rb = Instance.new("Frame")
			rb.AnchorPoint = Vector2.new(1, 0)
			rb.Position = UDim2.new(1, -8, 0, 6)
			rb.Size = UDim2.fromOffset(rec.weeklyPrize and 138 or 78, 20)
			rb.BackgroundColor3 = C.GoldDim
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
			table.insert(cardPreviews, {
				card = card, weapon = rec.weapon or weapon, id = id, rect = { 8, 30, cardW - 16, vpH },
			})
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
		local subText = st == "vipPass" and L.t("mz.pass.VIP") or (rouletteOnly and L.t("ui.shop.rouletteOnly")) or ((st == "buy" or kind == "Souls") and priceText(rec) or L.t(st))
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
			if mobile then inspecting = true selected = id render() return end
			UiTheme.playSound("UI_Click")
			inspect(id)
		end)
	end

	if tab == "Vault" then
		content.Name = "VaultScroll"
		content.CanvasPosition = vaultScroll
		detail.Visible = false content.Visible = true
		content.Size = UDim2.fromOffset(width - 40, contentH)
		timerLabel = nil
		renderVault(content, width - 50, mobile)
		if not vaultTarget and vaultScroll.Y > 0 then content.CanvasPosition = vaultScroll end
	elseif tab == "Showcase" then
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
			size = UDim2.new(0.58, -12, 0, 22),
			text = L.t("ui.shop.featured"),
			font = "Title",
			textSize = UiTheme.TextSizes.MD,
			color = C.GoldBright,
		})
		UiTheme.label({
			parent = featHeader,
			position = UDim2.fromOffset(12, 20),
			size = UDim2.fromOffset(320, 16),
			text = mobile and "" or L.t("ui.shop.featuredSub"),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
		})

		timerLabel = UiTheme.label({
			parent = featHeader,
			anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, -12, 0.5, 0),
			size = UDim2.new(0.42, -12, 0, 30),
			scaled = true,
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

		local fCols = math.max(1, math.min(#featuredIds, mobile and 2 or 5))
		local fGap = 8
		local fCardW = math.floor((listWidth - 10 - fGap * (fCols - 1)) / fCols)
		local fLayout = Instance.new("UIListLayout")
		fLayout.FillDirection = Enum.FillDirection.Horizontal
		fLayout.Padding = UDim.new(0, fGap)
		fLayout.SortOrder = Enum.SortOrder.LayoutOrder
		fLayout.Parent = featGridFrame

		for i = 1, math.min(fCols, #featuredIds) do
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
				if s and id ~= "Default" and not s.comingSoon and (not s.boxOnly or ownedSkinsMap[id]) then -- 10/11: las de Tormenta solo si las tenés
					local matches = (not s.weapon or s.weapon == weapon)
						and (rarity == "all" or Rewards.skinRarity(id, s) == rarity)
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
	if selected and tab ~= "Vault" and (not mobile or inspecting) then
		inspect(selected)
		if mobile then
			shopIcon.Visible = false
			local back = UiTheme.button({ parent = header, position = UDim2.fromOffset(4, 2), size = UDim2.fromOffset(44, 44),
				text = "‹", zIndex = 8, onClick = function() inspecting = false render() end })
			if Device.isGamepad() then firstButton = back end
		end
	end

	messageLabel = UiTheme.label({
		name = "StatusMessage",
		parent = panel,
		position = UDim2.fromOffset(22, height - 34),
		size = UDim2.fromOffset(mobile and width - 44 or width - 280, 30),
		text = "",
		font = "Bold",
		textSize = UiTheme.TextSizes.XS,
		color = C.GoldBright,
	})

	Device.showFor(UiTheme.label({
		parent = panel,
		position = UDim2.fromOffset(width - 250, height - 34),
		size = UDim2.fromOffset(228, 24),
		text = L.t("ui.gamepadHint"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextMuted,
		alignX = Enum.TextXAlignment.Right,
	}), "Gamepad") -- 11/11: solo con mando (Device)

	if Device.isGamepad() and not modal then
		GuiService.SelectedObject = firstButton
	end
end

----------------------------------------------------------------------
-- Apertura / cierre y bucle de rotación
----------------------------------------------------------------------
function setOpen(value)
	if opened == value then return end
	if value and (player:GetAttribute("InMatch") or player:GetAttribute("InTutorial")) then
		return
	end
	opened = value
	transition += 1
	local version = transition
	player:SetAttribute("ShopOpen", value)
	if value then
		player:SetAttribute("SettingsOpen", false)
		player:SetAttribute("ArmoryOpen", false)
		player:SetAttribute("RewardsOpen", false)
	end
	player:SetAttribute("MenuOpen", value
		or player:GetAttribute("SettingsOpen") == true
		or player:GetAttribute("ArmoryOpen") == true
		or player:GetAttribute("RewardsOpen") == true)
	UiTheme.playSound(value and "UI_MenuOpen" or "UI_MenuClose")

	if value then
		if tab == "Vault" then loadVault() end
		backdrop.Visible = true
		panel.Visible = true
		render()
		panel.Position = UDim2.fromScale(0.5, 0.53)
	else
		dismiss()
		exitAuraPreview(false)
		drag = nil
		stick = Vector2.zero
		zoomAxis = 0
		backdrop.Visible = false
		GuiService.SelectedObject = nil
	end

	TweenService:Create(panel, UiTheme.Anim.TweenNorm, {
		Position = UDim2.fromScale(0.5, value and 0.5 or 0.53),
	}):Play()

	if not value then
		task.delay(UiTheme.Anim.Normal, function()
			if version == transition then
				panel.Visible = false
				for _, item in cardPreviews do
					if item.viewport then item.viewport:Destroy() end
				end
				table.clear(cardPreviews)
				if detailSpin then
					detailSpin.vp:Destroy()
					detailSpin = nil
				end
			end
		end)
	end
end

local vaultEvent = Instance.new("BindableEvent")
vaultEvent.Name = "OpenVault" vaultEvent.Parent = player
vaultEvent.Event:Connect(openVault)
for _, attr in { "Pass_VIP", "Pass_SkipOpening", "PaidRandomAllowed", "PurchaseVersion" } do
	player:GetAttributeChangedSignal(attr):Connect(function()
		if opened and tab == "Vault" then loadVault() else vaultEntries = nil end
	end)
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

player:GetAttributeChangedSignal("RewardsOpen"):Connect(function()
	if player:GetAttribute("RewardsOpen") and opened then
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
		elseif compactShop and inspecting then
			inspecting = false render()
		elseif not processed or input.KeyCode == Enum.KeyCode.ButtonB then
			setOpen(false)
		end
	end
end)

local lastClockUpdate = 0
RunService.RenderStepped:Connect(function(dt)
	if not opened then return end

	local now = os.clock()
	if now >= nextCardPreviewUpdate then
		nextCardPreviewUpdate = now + 0.08
		updateCardPreviews()
	end
	if timerLabel and timerLabel.Parent and (now - lastClockUpdate >= 1.0) then
		lastClockUpdate = now
		timerLabel.Text = L.t("ui.shop.refreshesIn", { time = formatDailyCountdown() })
	end

	local v = detailSpin
	if not v or not v.vp.Parent or modal then return end
	v.yaw += stick.X * dt * 2.0
	v.pitch = math.clamp(v.pitch - stick.Y * dt, -0.65, 0.65)
	v.zoom = math.clamp(v.zoom + zoomAxis * dt * 0.65, 0.55, 1.65)
	if drag == nil and stick.Magnitude < 0.05 then
		v.yaw += dt * 0.35
	end
	if v.flashUntil and now < v.flashUntil then
		v.yaw += dt * 8
	end
	local rot = CFrame.Angles(v.pitch, v.yaw, 0)
	v.model:PivotTo(rot * v.base)
	v.camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, v.distance * v.zoom), Vector3.zero)
end)

for _, attr in { "Gems", "OwnedSkins", "EquippedSkin", "OwnedAuras", "EquippedAura", "WeaponId", "InfusionId", "InMatch", "OptUiScale" } do
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
