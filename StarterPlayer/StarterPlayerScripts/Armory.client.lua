-- LocalScript: StarterPlayer/StarterPlayerScripts/Armory
-- Armería del Campeón separada de la Tienda (Versión 0.2 — D13, C20).
-- Permite elegir y equipar Arma, Skin, Infusión (4 tarjetas altas) y Aura antes de salir al combate,
-- con vista 3D interactiva del personaje empuñando el arma y la skin seleccionada.
-- Se abre desde la ciudad (dock de LobbyUI o tecla B) y durante la antesala ("Prematch").

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
local Device = require(RS:WaitForChild("Device")) -- 11/11: PC, celular o consola
local Skins = require(RS:WaitForChild("Skins", 10))
local Rewards = require(RS:WaitForChild("Rewards"))
local Titles = require(RS:WaitForChild("Titles", 10))
local Weapons = require(RS:WaitForChild("WeaponData", 10))
local Infusions = require(RS:WaitForChild("Infusions", 10))
local Builder = require(RS:WaitForChild("WeaponBuilder", 10))

local Auras = nil
do
	local mAuras = RS:WaitForChild("Auras", 10)
	if mAuras then
		local ok, mod = pcall(require, mAuras)
		if ok then Auras = mod end
	end
end

local remotes = RS:WaitForChild("Remotes", 10)
local remote = remotes and remotes:WaitForChild("Shop", 10)
local C = UiTheme.Colors

----------------------------------------------------------------------
-- BindableEvent para abrir/cerrar la Armería desde LobbyUI, Shop o Prematch
----------------------------------------------------------------------
local toggleArmoryBindable = player:FindFirstChild("ToggleArmory")
if not toggleArmoryBindable then
	toggleArmoryBindable = Instance.new("BindableEvent")
	toggleArmoryBindable.Name = "ToggleArmory"
	toggleArmoryBindable.Parent = player
end

local gui = Instance.new("ScreenGui")
gui.Name = "ArmoryGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 11
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui", 10)

local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = C.BgModalVeil
backdrop.BackgroundTransparency = 0.24
backdrop.BorderSizePixel = 0
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Selectable = false
backdrop.Visible = false
backdrop.ZIndex = 1
backdrop.Parent = gui

local BASE_W, BASE_H = 1040, 640
local panel = UiTheme.panel({
	name = "ArmoryWindow",
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
-- Estado de la Armería
----------------------------------------------------------------------
local tab = "Weapons"
local weaponFilter = player:GetAttribute("WeaponId") or "Sword"
local skinOwnership = "owned" -- "owned" | "all" | "locked"
local skinSort = "quality" -- "quality" | "alpha" | "owned" (12/11/2026)
local SKIN_COLUMN = 150 -- ancho de la columna de armas en Skins
local RARITY_RANK = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
local selectedId = nil
local opened = false
local busy = false
local transition = 0

local spins = {}
local charSpin = nil
local dragInput = nil
local lastMousePos = Vector2.zero
local stick = Vector2.zero
local zoomAxis = 0
local statusLabel = nil
local render
local setOpen
local titleState, selectedTitle, titleScroll
local titleScrollPosition = Vector2.zero
local titleLoading, titleBusy = false, false
local titleStatus = ""

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

local function itemName(id)
	if Weapons.Data[id] then return L.t("weapon." .. id) end
	if Infusions.Data[id] then return L.t("infusion." .. id) end
	if Auras and Auras.Data[id] then return L.t("cx.aura." .. id) end
	return L.t("skin." .. id)
end

local function itemDesc(id)
	if Weapons.Data[id] then return L.t("weaponDesc." .. id) end
	if Infusions.Data[id] then return L.t("infusionDesc." .. id) end
	if Auras and Auras.Data[id] then return L.t("cx.aura." .. id .. ".desc") end
	return L.t("skinDesc." .. id)
end

local function setStatus(text, isError)
	if not statusLabel then return end
	statusLabel.Text = text or ""
	statusLabel.TextColor3 = isError and C.Danger or C.GoldBright
end

local function invokeArmory(action, id)
	if busy or not remote then return end
	-- En partida solo se permite cambiar equipamiento durante la antesala ("Prematch")
	local phase = (player:GetAttribute("MatchPhase") or workspace:GetAttribute("MatchPhase"))
	if player:GetAttribute("InMatch") and phase ~= "Prematch" then
		setStatus(L.t("locked"), true)
		UiTheme.playSound("UI_Error")
		return
	end
	busy = true
	local ok, success, msg = pcall(function()
		return remote:InvokeServer(action, id)
	end)
	busy = false
	if not ok then
		UiTheme.playSound("UI_Error")
		setStatus(L.t("error"), true)
		return
	end
	UiTheme.playSound(success and "UI_Equip" or "UI_Error")
	if type(msg) == "table" and msg.key then
		setStatus(L.t(msg.key, msg.params), not success)
	elseif type(msg) == "string" then
		setStatus(L.t(msg), not success)
	else
		setStatus(success and L.t("equipped") or L.t("error"), not success)
	end
	if opened then
		render()
	end
end

----------------------------------------------------------------------
-- Vistas previas 3D: Armas individuales y Personaje 3D completo
----------------------------------------------------------------------
local function makeWeaponPreview(parent, wid, sid, rect)
	local vp = Instance.new("ViewportFrame")
	vp.Position = UDim2.fromOffset(rect[1], rect[2])
	vp.Size = UDim2.fromOffset(rect[3], rect[4])
	vp.BackgroundColor3 = C.BgPreview
	vp.BackgroundTransparency = 0.15
	vp.BorderSizePixel = 0
	vp.Ambient = C.PreviewAmbient
	vp.LightColor = C.PreviewLight
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.Parent = parent
	UiTheme.corner(vp, UiTheme.Radius.SM)

	local world = Instance.new("WorldModel")
	world.Parent = vp
	local camera = Instance.new("Camera")
	camera.FieldOfView = 28
	camera.Parent = vp
	vp.CurrentCamera = camera

	local model = Builder.buildModel(wid, sid)
	model.Parent = world
	local cfBox, size = model:GetBoundingBox()
	local center = model.PrimaryPart and (model.PrimaryPart.CFrame:Inverse() * cfBox.Position) or Vector3.zero
	local base = CFrame.Angles(0, math.pi / 2, math.rad(26)) * CFrame.new(-center)
	local dist = math.max(size.X, size.Y, size.Z) * 0.88
	model:PivotTo(base)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, dist), Vector3.zero)

	table.insert(spins, {
		vp = vp,
		model = model,
		camera = camera,
		base = base,
		distance = dist,
		phase = #spins * 0.45,
		yaw = 0,
		pitch = 0,
		zoom = 1,
		manual = false,
	})
	return vp
end

-- Construye un maniquí dark-fantasy o clona el personaje del jugador con su arma, skin, infusión y aura
local function buildCharacterAvatarModel(previewWeaponId, previewSkinId, previewInfusionId, previewAuraId)
	local stage = Instance.new("Model")
	stage.Name = "CharacterStage"

	local root = Instance.new("Part")
	root.Name = "StageRoot"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = stage
	stage.PrimaryPart = root

	-- Pedestal gótico bajo los pies
	local pedBase = Instance.new("Part")
	pedBase.Name = "Pedestal"
	pedBase.Shape = Enum.PartType.Cylinder
	pedBase.Size = Vector3.new(0.45, 4.4, 4.4)
	pedBase.Color = C.BgCard
	pedBase.Material = Enum.Material.Slate
	pedBase.Anchored = true
	pedBase.CanCollide = false
	pedBase.CFrame = CFrame.new(0, -3.15, 0) * CFrame.Angles(0, 0, math.rad(90))
	pedBase.Parent = stage

	-- Anillo de infusión / aura en el pedestal
	local infData = Infusions.Data[previewInfusionId or "Fire"] or Infusions.Data.Fire
	local auraData = Auras and Auras.Data and Auras.Data[previewAuraId or ""] or nil
	local ringColor = (auraData and auraData.color) or (infData and infData.color) or C.GoldBright

	local pedRing = Instance.new("Part")
	pedRing.Name = "PedestalRing"
	pedRing.Shape = Enum.PartType.Cylinder
	pedRing.Size = Vector3.new(0.50, 4.65, 4.65)
	pedRing.Color = ringColor
	pedRing.Material = Enum.Material.Neon
	pedRing.Transparency = 0.25
	pedRing.Anchored = true
	pedRing.CanCollide = false
	pedRing.CFrame = CFrame.new(0, -3.16, 0) * CFrame.Angles(0, 0, math.rad(90))
	pedRing.Parent = stage

	-- Intentar clonar el avatar del jugador; si no está disponible, crear maniquí de caballero
	local charClone = nil
	local realChar = player.Character
	if realChar then
		local prevArch = realChar.Archivable
		realChar.Archivable = true
		local ok, cl = pcall(function()
			return realChar:Clone()
		end)
		realChar.Archivable = prevArch
		if ok and cl then
			charClone = cl
		end
	end

	local rightHandCFrame = CFrame.new(1.35, -0.35, -0.45) * CFrame.Angles(math.rad(-25), math.rad(15), math.rad(-12))
	local leftHandCFrame = CFrame.new(-1.35, -0.40, -0.35) * CFrame.Angles(math.rad(-20), math.rad(-15), math.rad(12))

	if charClone then
		for _, d in charClone:GetDescendants() do
			if d:IsA("LuaSourceContainer") or d:IsA("Tool") or d:IsA("BillboardGui") or d:IsA("Highlight") or d:IsA("ForceField") or d.Name == "OffhandWeapon" then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end
		charClone:PivotTo(CFrame.new(0, -0.15, 0) * CFrame.Angles(0, math.pi, 0))
		charClone.Parent = stage
		local rHand = charClone:FindFirstChild("RightHand") or charClone:FindFirstChild("Right Arm")
		local lHand = charClone:FindFirstChild("LeftHand") or charClone:FindFirstChild("Left Arm")
		if rHand then
			rightHandCFrame = rHand.CFrame * CFrame.new(0, -0.25, 0) * CFrame.Angles(math.rad(-75), 0, 0)
		end
		if lHand then
			leftHandCFrame = lHand.CFrame * CFrame.new(0, -0.25, 0) * CFrame.Angles(math.rad(-75), 0, 0)
		end
	else
		-- Maniquí de armadura oscura
		local armorCol = C.IronLight
		local trimCol = C.TextSecondary
		local function addPart(sz, cframe, col, mat, shape)
			local p = Instance.new("Part")
			p.Size = sz
			p.CFrame = cframe
			p.Color = col
			p.Material = mat or Enum.Material.Metal
			if shape then p.Shape = shape end
			p.Anchored = true
			p.CanCollide = false
			p.Parent = stage
			return p
		end
		addPart(Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 1.45, 0), armorCol, Enum.Material.Metal, Enum.PartType.Ball)
		addPart(Vector3.new(1.85, 1.95, 0.95), CFrame.new(0, 0.0, 0), armorCol, Enum.Material.Metal)
		addPart(Vector3.new(1.92, 0.28, 1.02), CFrame.new(0, -0.75, 0), trimCol, Enum.Material.Foil)
		addPart(Vector3.new(0.72, 1.75, 0.72), CFrame.new(1.32, 0.05, -0.15) * CFrame.Angles(math.rad(25), 0, math.rad(-10)), armorCol)
		addPart(Vector3.new(0.72, 1.75, 0.72), CFrame.new(-1.32, 0.05, -0.10) * CFrame.Angles(math.rad(18), 0, math.rad(10)), armorCol)
		addPart(Vector3.new(0.82, 1.95, 0.82), CFrame.new(0.50, -1.95, 0), C.IronDark, Enum.Material.Slate)
		addPart(Vector3.new(0.82, 1.95, 0.82), CFrame.new(-0.50, -1.95, 0), C.IronDark, Enum.Material.Slate)
	end

	-- Arma principal en la mano derecha
	local wModel = Builder.buildModel(previewWeaponId, previewSkinId)
	for _, d in wModel:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local info = Builder.Info[previewWeaponId] or Builder.Info.Sword
	wModel:PivotTo(rightHandCFrame * CFrame.new(0, 0, -(info.gripZ or 0)))
	wModel.Parent = stage

	-- Segunda daga en la mano izquierda si el arma es Dagger
	if info.dual then
		local offModel = Builder.buildModel(previewWeaponId, previewSkinId)
		for _, d in offModel:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		offModel:PivotTo(leftHandCFrame * CFrame.new(0, 0, -(info.gripZ or 0)))
		offModel.Parent = stage
	end

	-- Halo visual si hay un aura seleccionada/equipada
	if auraData then
		local halo = Instance.new("Part")
		halo.Name = "AuraCrownPreview"
		halo.Shape = Enum.PartType.Cylinder
		halo.Size = Vector3.new(0.12, 2.2, 2.2)
		halo.Color = auraData.color or C.GoldBright
		halo.Material = Enum.Material.Neon
		halo.Transparency = 0.35
		halo.Anchored = true
		halo.CanCollide = false
		halo.CFrame = CFrame.new(0, 2.35, 0) * CFrame.Angles(0, 0, math.rad(90))
		halo.Parent = stage
	end

	return stage
end

----------------------------------------------------------------------
-- Renderizado completo de la Armería
----------------------------------------------------------------------

local function titleRemote(action, id)
	local rf = remotes and remotes:FindFirstChild("Titles")
	if not rf then return false, "loading" end
	local ok, success, payload = pcall(function() return rf:InvokeServer(action, id) end)
	if not ok then return false, "error" end
	return success == true, payload
end

local function loadTitles()
	if titleLoading then return end
	titleLoading = true
	task.spawn(function()
		local ok, payload = titleRemote("List")
		if not ok and payload == "cx.shop.wait" and opened then
			task.wait(0.4)
			ok, payload = titleRemote("List")
		end
		titleLoading = false
		if ok and type(payload) == "table" then titleState = payload end
		if opened then render() end
	end)
end

local function titleCard(parent, id, size, caption)
	local spec = Titles.Data[id]
	local rarity = UiTheme.Rarities[spec and spec.rarity or "Common"]
	local frame = UiTheme.panel({ parent = parent, size = size, bg = C.BgPanel, borderColor = rarity.color,
		borderThickness = rarity.stroke, topColor = rarity.bg, bottomColor = C.BgAbyss })
	local band = Instance.new("Frame")
	band.Size = UDim2.new(0, 5, 1, 0) band.BackgroundColor3 = rarity.color band.BorderSizePixel = 0 band.Parent = frame
	UiTheme.label({ parent = frame, position = UDim2.fromOffset(14, 6), size = UDim2.new(1, -24, 0, 20),
		text = caption, textSize = UiTheme.TextSizes.XS, color = C.TextSecondary })
	UiTheme.label({ parent = frame, position = UDim2.fromOffset(14, 28), size = UDim2.new(1, -24, 0, 32),
		text = Titles.text(id, L.language(), L.t) or L.t("title.none"), font = "Title",
		scaled = true, textSize = UiTheme.TextSizes.XL, color = rarity.color })
	UiTheme.label({ parent = frame, position = UDim2.fromOffset(14, 62), size = UDim2.new(1, -24, 0, 24),
		text = player.DisplayName .. " · " .. L.t("ui.hud.level", { level = player:GetAttribute("Level") or 1 }),
		scaled = true, textSize = UiTheme.TextSizes.SM, color = C.TextPrimary })
	return frame
end

local function actTitle(action, id)
	if titleBusy then return end
	titleBusy = true
	local ok, response = titleRemote(action, id)
	titleBusy = false
	titleStatus = ok and "" or L.t(type(response) == "string" and response or "error")
	if ok and action == "Rebirth" and type(response) == "string" then selectedTitle = response end
	if ok then loadTitles() elseif opened then render() end
end

local TITLE_SOURCES = { "role", "pass", "stat", "achievement", "level", "mastery", "shop" }
local function renderTitles(width, height, top, compact)
	local usableWidth = width - 40
	local listWidth = compact and usableWidth or math.floor(usableWidth * 0.58)
	local previewWidth = compact and usableWidth or usableWidth - listWidth - 12
	local previewHeight = 158
	local previewX = compact and 20 or 32 + listWidth
	local listY = compact and top + previewHeight + 8 or top
	local preview = UiTheme.panel({ parent = panel, position = UDim2.fromOffset(previewX, top),
		size = UDim2.fromOffset(previewWidth, previewHeight), borderColor = C.BorderDefault })
	local list = Instance.new("ScrollingFrame")
	list.Name = "TitlesList"
	list.Position = UDim2.fromOffset(20, listY) list.Size = UDim2.fromOffset(listWidth, height - listY - 38)
	list.BackgroundTransparency = 1 list.BorderSizePixel = 0 list.ScrollBarThickness = 5 list.Parent = panel
	titleScroll = list

	local previewButtons = {}
	local function drawPreview()
		for _, child in preview:GetChildren() do
			if child:IsA("GuiObject") then child:Destroy() end
		end
		table.clear(previewButtons)
		local equipped = titleState and titleState.equipped or ""
		local id = selectedTitle or equipped
		local row
		for _, candidate in titleState and titleState.titles or {} do
			if candidate.id == id then row = candidate break end
		end
		local card = titleCard(preview, id, UDim2.new(1, -20, 0, 90), L.t("mz.titlePreview"))
		card.Position = UDim2.fromOffset(10, 8)
		local isEquipped = equipped ~= "" and equipped == id
		local action = isEquipped and "Equip" or (row and (row.owned and "Equip" or (row.price and "Buy")))
		if action then
			local label = isEquipped and L.t("mz.titleUnequip") or (action == "Buy"
				and (L.t("buy") .. " · " .. L.t("ui.souls", { amount = row.price })) or L.t("equip"))
			local button = UiTheme.button({ parent = preview, position = UDim2.fromOffset(10, 104),
				size = UDim2.new(1, -20, 0, 44), text = label, variant = "primary",
				textSize = UiTheme.TextSizes.SM, onClick = function() actTitle(action, isEquipped and "" or id) end })
			button.TextWrapped = true
			table.insert(previewButtons, button)
		elseif row and row.hint then
			UiTheme.label({ parent = preview, position = UDim2.fromOffset(12, 104), size = UDim2.new(1, -24, 0, 42),
				text = L.t(row.hint), textSize = UiTheme.TextSizes.SM, color = C.TextSecondary })
		end
	end
	drawPreview()

	local y = 0
	local first
	local function heading(key)
		UiTheme.label({ parent = list, position = UDim2.fromOffset(6, y), size = UDim2.new(1, -16, 0, 26),
			text = L.t(key), font = "Title", textSize = UiTheme.TextSizes.LG, color = C.GoldBright })
		y += 30
	end
	if not titleState then
		heading("loading")
	else
		heading("mz.titles.mastery")
		for _, weapon in Weapons.Order do
			local mastery = titleState.mastery[weapon]
			local row = UiTheme.panel({ parent = list, position = UDim2.fromOffset(0, y), size = UDim2.new(1, -8, 0, 82),
				bg = C.BgCard, borderColor = C.BorderDefault })
			UiTheme.label({ parent = row, position = UDim2.fromOffset(10, 2), size = UDim2.new(1, -20, 0, 20),
				text = L.t("weapon." .. weapon) .. " · " .. L.t("mz.masteryLine",
					{ level = mastery.level, max = mastery.maxLevel, count = mastery.rebirths }),
				textSize = UiTheme.TextSizes.XS, font = "Bold", color = C.TextPrimary })
			local rebirth = UiTheme.button({ parent = row, position = UDim2.fromOffset(10, 28),
				size = UDim2.new(1, -20, 0, 44), text = mastery.price and L.t("mz.masteryRebirth", { price = mastery.price }) or L.t("mz.masteryMaxed"),
				-- 11/11: 5 renacimientos como máximo; después el botón queda en «Maestría máxima»
				textSize = UiTheme.TextSizes.SM, disabled = not mastery.price or mastery.level < mastery.maxLevel or player:GetAttribute("InMatch") == true,
				onClick = function() actTitle("Rebirth", weapon) end })
			rebirth.TextWrapped = true
			if not first and rebirth.Selectable then first = rebirth end
			y += 88
		end
		for _, source in TITLE_SOURCES do
			local sectionDrawn = false
			for _, row in titleState.titles do
				if row.source ~= source then continue end
				if not sectionDrawn then heading("mz.titles." .. source) sectionDrawn = true end
				local id = row.id
				local rarity = UiTheme.Rarities[row.rarity]
				local rowPanel = UiTheme.panel({ parent = list, position = UDim2.fromOffset(0, y),
					size = UDim2.new(1, -8, 0, 64), bg = C.BgCard, borderColor = rarity.color })
				UiTheme.label({ parent = rowPanel, position = UDim2.fromOffset(10, 3), size = UDim2.new(1, -20, 0, 28),
					text = Titles.text(id, L.language(), L.t), font = "Title", textSize = UiTheme.TextSizes.LG, scaled = true, color = rarity.color })
				local progress = row.progress ~= nil and ("%d / %d"):format(row.progress, row.goal)
					or (row.price and L.t("ui.souls", { amount = row.price })) or ""
				local info = L.t(row.rarity)
				if titleState.equipped == id then info = info .. " · " .. L.t("equipped")
				elseif row.owned then info = info .. " · " .. L.t("mz.owned")
				elseif progress ~= "" then info = info .. " · " .. progress end
				UiTheme.label({ parent = rowPanel, position = UDim2.fromOffset(10, 34), size = UDim2.new(1, -20, 0, 24),
					text = info, textSize = UiTheme.TextSizes.XS, color = C.TextSecondary })
				local hit = Instance.new("TextButton")
				hit.Name = id hit.Size = UDim2.fromScale(1, 1) hit.BackgroundTransparency = 1 hit.Text = "" hit.Parent = rowPanel
				UiTheme.bindGamepadFocus(hit, rowPanel:FindFirstChildOfClass("UIStroke"), rarity.color)
				hit.Activated:Connect(function()
					selectedTitle = id drawPreview()
					if Device.isGamepad() and previewButtons[1] then GuiService.SelectedObject = previewButtons[1] end
				end)
				if not first then first = hit end
				y += 70
			end
		end
	end
	list.CanvasSize = UDim2.fromOffset(0, y)
	list.CanvasPosition = titleScrollPosition
	UiTheme.label({ parent = panel, position = UDim2.fromOffset(20, height - 34), size = UDim2.new(1, -40, 0, 30),
		text = titleStatus, textSize = UiTheme.TextSizes.XS, color = C.Danger })
	return first
end

local toastGui = Instance.new("ScreenGui")
toastGui.Name = "TitleNotices" toastGui.DisplayOrder = 45 toastGui.ResetOnSpawn = false toastGui.Parent = gui.Parent
local toastQueue = {}
local showingToast = false
local function showNextTitle()
	local id = table.remove(toastQueue, 1)
	if not id then showingToast = false return end
	showingToast = true
	local toast = titleCard(toastGui, id, UDim2.new(0.9, 0, 0, 92), L.t("mz.titleUnlocked"))
	toast.AnchorPoint = Vector2.new(0.5, 0) toast.Position = UDim2.new(0.5, 0, 0, 62)
	local limits = Instance.new("UISizeConstraint")
	limits.MaxSize = Vector2.new(340, 92) limits.Parent = toast
	task.delay(3.1, function() toast:Destroy() showNextTitle() end)
end

task.spawn(function()
	local notice = remotes and remotes:WaitForChild("TitleUnlocked", 15)
	if not notice then return end
	notice.OnClientEvent:Connect(function(id)
		if not Titles.Data[id] then return end
		table.insert(toastQueue, id)
		if not showingToast then showNextTitle() end
		if opened then loadTitles() else titleState = nil end
	end)
end)

local function renderArsenal(width, height, top, compact, equippedWeapon, equippedSkin)
	local railWidth = compact and math.floor(width * 0.36) or 218
	local panelHeight = height - top - 54
	local stageX = railWidth + 32
	local stageWidth = width - stageX - 20
	if not Weapons.Data[selectedId] then selectedId = equippedWeapon end
	local focus
	for i, weapon in Weapons.Order do
		local id = weapon
		local selected = id == selectedId
		local row = UiTheme.button({
			name = "Arsenal_" .. id, parent = panel,
			position = UDim2.fromOffset(20, top + (i - 1) * 60),
			size = UDim2.fromOffset(railWidth, 52),
			text = "", selected = selected, textSize = UiTheme.TextSizes.SM,
			onClick = function() selectedId = id render() end,
		})
		UiAssets.skinThumbnail(row, id, { weapon = id, blade = C.Gold, accent = C.GoldDim }, row.ZIndex + 1)
		UiTheme.label({
			parent = row, position = UDim2.fromOffset(54, 2), size = UDim2.new(1, -60, 1, -4),
			text = itemName(id), scaled = true, minTextSize = 10, maxTextSize = UiTheme.TextSizes.MD,
			color = selected and C.TextPrimary or C.TextSecondary, zIndex = row.ZIndex + 1,
		})
		if selected then focus = row end
	end

	local id = selectedId
	local descH = compact and 72 or 48
	local titleH = compact and 34 or 44
	local previewY = top + titleH + descH + 10
	local previewH = math.max(96, panelHeight - titleH - descH - 68)
	UiTheme.label({
		name = "ArsenalWeaponName", parent = panel, position = UDim2.fromOffset(stageX, top),
		size = UDim2.fromOffset(stageWidth, titleH), text = itemName(id), font = "Title",
		textSize = UiTheme.TextSizes.XXL, scaled = compact, color = C.TextPrimary,
	})
	UiTheme.label({
		parent = panel, position = UDim2.fromOffset(stageX, top + titleH),
		size = UDim2.fromOffset(stageWidth, descH), text = itemDesc(id), scaled = compact,
		font = "Body", textSize = UiTheme.TextSizes.SM, minTextSize = 11, alignY = Enum.TextYAlignment.Top,
		color = C.TextSecondary,
	})

	local vp = makeWeaponPreview(panel, id, id == equippedWeapon and equippedSkin or "Default",
		{ stageX, previewY, stageWidth, previewH })
	vp.Name = "ArsenalViewport"
	vp.BackgroundTransparency = 1
	local entry = table.remove(spins)
	entry.base = CFrame.Angles(0, math.pi / 2, math.rad(30)) * entry.base.Rotation:Inverse() * entry.base
	local _, modelSize = entry.model:GetBoundingBox()
	local angle = math.rad(entry.camera.FieldOfView / 2)
	local aspect = math.min(1, stageWidth / previewH)
	entry.distance = modelSize.Magnitude * 0.58 / math.sin(math.atan(math.tan(angle) * aspect))
	entry.lookHeight = 0
	charSpin = entry
	vp.Active = true
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
			lastMousePos = input.Position
		end
	end)
	vp.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			entry.zoom = math.clamp(entry.zoom - input.Position.Z * 0.1, 0.65, 1.45)
		end
	end)
	UiTheme.button({
		name = "ArsenalEquip", parent = panel,
		position = UDim2.fromOffset(stageX, previewY + previewH + 8),
		size = UDim2.fromOffset(stageWidth, 42), text = L.t(id == equippedWeapon and "equipped" or "choose"),
		variant = "primary", disabled = id == equippedWeapon,
		onClick = function() weaponFilter = id invokeArmory("SelectWeapon", id) end,
	})
	return focus
end

function render()
	if titleScroll and titleScroll.Parent then titleScrollPosition = titleScroll.CanvasPosition end
	titleScroll = nil
	table.clear(spins)
	charSpin = nil
	for _, ch in panel:GetChildren() do
		if ch ~= scale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" and ch.Name ~= "FrameArt" then
			ch:Destroy()
		end
	end

	local cam = workspace.CurrentCamera
	local viewport = cam and cam.ViewportSize or Vector2.new(BASE_W, BASE_H)
	local mobile = viewport.X < 780
	local insetA, insetB = GuiService:GetGuiInset()
	local usable = viewport - insetA - insetB
	local width = mobile and math.min(700, usable.X - 28) or BASE_W
	local height = mobile and math.clamp(usable.Y - 28, 560, 760) or BASE_H
	panel.Size = UDim2.fromOffset(width, height)
	scale.Scale = mobile and math.min(1, (usable.Y - 28) / height) or UiTheme.computeScale(usable, width, height, player)

	local equippedWeapon = player:GetAttribute("WeaponId") or "Sword"
	local equippedSkin = player:GetAttribute("EquippedSkin") or "Default"
	local equippedInfusion = player:GetAttribute("InfusionId") or "Fire"
	local equippedAura = player:GetAttribute("EquippedAura") or ""

	-- Cabecera
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, mobile and 100 or 58)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = panel
	UiTheme.corner(header, UiTheme.Radius.MD)

	local crest = UiAssets.icon(header, "armory", 26, C.GoldBright)
	crest.AnchorPoint = Vector2.new(0, 0.5)
	crest.Position = mobile and UDim2.fromOffset(18, 22) or UDim2.new(0, 18, 0.5, 0)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 6),
		size = mobile and UDim2.new(1, -66, 0, 35) or UDim2.fromOffset(380, 28),
		text = L.t("ui.armory.title"),
		scaled = mobile,
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
	})
	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 32),
		size = UDim2.fromOffset(420, 18),
		text = mobile and "" or L.t("ui.armory.subtitle"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
	})

	-- Botón para ir a la Tienda (si no está en partida)
	if not player:GetAttribute("InMatch") then
		UiTheme.button({
			name = "OpenShopBtn",
			parent = header,
			anchor = Vector2.new(1, 0.5),
			position = mobile and UDim2.new(1, -132, 0, 72) or UDim2.new(1, -132, 0.5, 0),
			size = UDim2.fromOffset(154, mobile and 44 or 38),
			text = L.t("ui.armory.openShop"),
			variant = "gold",
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				setOpen(false)
				local toggleMenu = player:FindFirstChild("ToggleMenu")
				if toggleMenu and toggleMenu:IsA("BindableEvent") then
					toggleMenu:Fire()
				end
			end,
		})
	end

	UiTheme.button({
		name = "CloseButton",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = mobile and UDim2.new(1, -16, 0, 72) or UDim2.new(1, -16, 0.5, 0),
		size = UDim2.fromOffset(106, mobile and 44 or 38),
		text = L.t("close"),
		variant = "secondary",
		onClick = function()
			setOpen(false)
		end,
	})

	-- Barra de pestañas de la Armería: Armas, Skins, Infusiones, Auras
	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "TabsBar"
	tabsBar.Position = UDim2.fromOffset(20, mobile and 106 or 66)
	tabsBar.Size = UDim2.new(1, -40, 0, 44)
	tabsBar.BackgroundTransparency = 1
	tabsBar.Parent = panel
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabsBar

	local firstButton = nil
	local tabDefs = {
		{ id = "Weapons", label = L.t("Weapons") },
		{ id = "Skins", label = L.t("Skins") },
		{ id = "Infusions", label = L.t("Infusions") },
		{ id = "Auras", label = L.t("ui.tab.Auras") },
		{ id = "Titles", label = L.t("mz.titles") },
	}
	for i, def in tabDefs do
		local b = UiTheme.tabButton({
			name = "Tab_" .. def.id,
			parent = tabsBar,
			layoutOrder = i,
			size = UDim2.fromOffset(mobile and math.floor((width - 72) / #tabDefs) or 158, 44),
			text = def.label,
			active = tab == def.id,
			onClick = function()
				tab = def.id
				selectedId = nil
				if tab == "Titles" then titleStatus = "" if not titleState then loadTitles() end end
				render()
			end,
		})
		b.TextWrapped = true
		if mobile then b.TextSize = UiTheme.TextSizes.XS end
		if i == 1 then firstButton = b end
	end

	-- Subbarra de filtros en Skins
	local top = mobile and 154 or 118
	if tab == "Weapons" then
		statusLabel = UiTheme.label({
			name = "StatusMessage", parent = panel, position = UDim2.fromOffset(20, height - 34),
			size = UDim2.new(1, -40, 0, 24), textSize = UiTheme.TextSizes.SM, color = C.TextSecondary,
		})
		local focus = renderArsenal(width, height, top, mobile, equippedWeapon, equippedSkin)
		if Device.isGamepad() then GuiService.SelectedObject = focus or firstButton end
		return
	end
	if tab == "Titles" then
		local titleButton = renderTitles(width, height, top, mobile)
		if Device.isGamepad() then GuiService.SelectedObject = titleButton or firstButton end
		return
	end
	local leftW = mobile and (width - 40) or math.floor(width * 0.58)
	-- 12/11/2026 (pedido del usuario): en Skins, las armas en una columna a la izquierda y arriba
	-- los filtros de estado (todas / en propiedad / bloqueadas) y de orden (calidad, A-Z, primero las mías).
	local listX = 20
	if tab == "Skins" then
		local stateKeys = { all = "ar.state.all", owned = "ar.state.owned", locked = "ar.state.locked" }
		local sortKeys = { quality = "ar.sort.quality", alpha = "ar.sort.alpha", owned = "ar.sort.owned" }
		local filterW = mobile and math.floor((leftW - 8) / 2) or 220
		UiTheme.button({
			name = "StateFilter",
			parent = panel,
			position = UDim2.fromOffset(mobile and 20 or (20 + SKIN_COLUMN + 10), top),
			size = UDim2.fromOffset(filterW, 32),
			text = L.t("ar.state", { value = L.t(stateKeys[skinOwnership] or "ar.state.all") }),
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				skinOwnership = ({ all = "owned", owned = "locked", locked = "all" })[skinOwnership] or "all"
				render()
			end,
		})
		UiTheme.button({
			name = "SortFilter",
			parent = panel,
			position = UDim2.fromOffset(mobile and (28 + filterW) or (20 + SKIN_COLUMN + 10 + filterW + 8), top),
			size = UDim2.fromOffset(filterW, 32),
			text = L.t("ar.sort", { value = L.t(sortKeys[skinSort] or "ar.sort.quality") }),
			textSize = UiTheme.TextSizes.XS,
			onClick = function()
				skinSort = ({ quality = "alpha", alpha = "owned", owned = "quality" })[skinSort] or "quality"
				render()
			end,
		})
		top += 40

		if mobile then
			local weaponBar = Instance.new("Frame")
			weaponBar.Position = UDim2.fromOffset(20, top)
			weaponBar.Size = UDim2.fromOffset(leftW, 34)
			weaponBar.BackgroundTransparency = 1
			weaponBar.Parent = panel
			local bw = math.floor(leftW / #Weapons.Order)
			for i, wid in Weapons.Order do
				UiTheme.button({ parent = weaponBar, position = UDim2.fromOffset((i - 1) * bw, 0), size = UDim2.fromOffset(bw - 6, 34),
					text = L.t("weapon." .. wid), selected = wid == weaponFilter, textSize = UiTheme.TextSizes.XS,
					onClick = function() weaponFilter = wid selectedId = nil render() end })
			end
			top += 40
		else
			-- columna de armas
			for i, wid in Weapons.Order do
				UiTheme.button({ name = "Weapon_" .. wid, parent = panel, position = UDim2.fromOffset(20, top + (i - 1) * 50),
					size = UDim2.fromOffset(SKIN_COLUMN, 44), text = L.t("weapon." .. wid), selected = wid == weaponFilter,
					icon = "attack", iconSize = 18, textSize = UiTheme.TextSizes.SM,
					onClick = function() weaponFilter = wid selectedId = nil render() end })
			end
			listX = 20 + SKIN_COLUMN + 10
			leftW -= SKIN_COLUMN + 10
		end
	end

	local contentH = height - top - 44
	local listH = mobile and math.floor(contentH * 0.5) or contentH

	local content = Instance.new("ScrollingFrame")
	content.Name = "ArmoryList"
	content.Position = UDim2.fromOffset(listX, top)
	content.Size = UDim2.fromOffset(leftW, listH)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.ScrollBarThickness = 6
	content.ScrollBarImageColor3 = C.Gold
	content.Parent = panel

	-- Panel derecho: Vista 3D del Personaje + resumen de pieza seleccionada
	local rightX = mobile and 20 or (listX + 8 + leftW)
	local rightY = mobile and (top + listH + 8) or 118
	local rightW = mobile and (width - 40) or (width - (listX + 8 + leftW) - 20)
	local rightH = mobile and (contentH - listH - 8) or (height - 118 - 44)

	local stagePanel = UiTheme.panel({
		name = "CharacterStagePanel",
		parent = panel,
		position = UDim2.fromOffset(rightX, rightY),
		size = UDim2.fromOffset(rightW, rightH),
		bg = C.BgPanel,
		borderColor = C.Gold,
		ornaments = true,
	})

	local shown = {}
	local ownedSkinsMap = ownSkins()
	local ownedAurasMap = ownAuras()

	if tab == "Infusions" then
		-- 4 tarjetas altas estilo referencias\infusiones ref2.jpg
		local gap = 8
		local count = #Infusions.Order
		local columns = mobile and 2 or count
		local cardW = math.floor((leftW - gap * (columns - 1) - 8) / columns)
		local cardH = mobile and 180 or math.max(250, listH - 8)
		local rowLayout = Instance.new("UIGridLayout")
		rowLayout.CellSize = UDim2.fromOffset(cardW, cardH)
		rowLayout.CellPadding = UDim2.fromOffset(gap, gap)
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = content

		for idx, id in Infusions.Order do
			table.insert(shown, id)
			local isEq = equippedInfusion == id
			local isSel = selectedId == id or (not selectedId and isEq)

			local card = Instance.new("Frame")
			card.Name = "InfusionCard_" .. id
			card.LayoutOrder = idx
			card.Size = UDim2.fromOffset(cardW, cardH)
			card.BackgroundColor3 = C.BgCard
			card.BorderSizePixel = 0
			card.Parent = content
			UiTheme.corner(card, UiTheme.Radius.MD)

			UiAssets.infusionCardArt(card, id)
			local cStroke = UiTheme.stroke(card, isEq and C.GoldBright or C.Gold, (isEq or isSel) and 2.4 or 1.4, isEq and 0 or 0.18)
			UiTheme.ornamentCorners(card, C.GoldBright, 10, 2)

			UiTheme.label({
				parent = card,
				position = UDim2.new(0, 6, 0.50, 0),
				size = UDim2.new(1, -12, 0, 28),
				text = string.upper(itemName(id)),
				font = "Title",
				textSize = UiTheme.TextSizes.LG,
				color = C.GoldBright,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 5,
			})

			UiTheme.label({
				parent = card,
				position = UDim2.new(0, 8, 0.60, 0),
				size = UDim2.new(1, -16, 0.22, 0),
				text = L.t("infusionMotto." .. id),
				font = "Body",
				textSize = UiTheme.TextSizes.XS,
				color = C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 5,
			})

			local pill = Instance.new("Frame")
			pill.AnchorPoint = Vector2.new(0.5, 1)
			pill.Position = UDim2.new(0.5, 0, 1, -12)
			pill.Size = UDim2.new(0.84, 0, 0, 30)
			pill.BackgroundColor3 = isEq and C.SuccessDark or C.IronDark
			pill.BorderSizePixel = 0
			pill.ZIndex = 5
			pill.Parent = card
			UiTheme.corner(pill, UiTheme.Radius.SM)
			UiTheme.stroke(pill, isEq and C.Success or C.Gold, 1.2, 0.15)

			UiTheme.label({
				parent = pill,
				size = UDim2.fromScale(1, 1),
				text = L.t(isEq and "equipped" or "choose"),
				font = "Bold",
				textSize = UiTheme.TextSizes.XS,
				color = isEq and C.GoldBright or C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 6,
			})

			local hit = Instance.new("TextButton")
			hit.Size = UDim2.fromScale(1, 1)
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.ZIndex = 8
			hit.Parent = card
			UiTheme.bindGamepadFocus(hit, cStroke, isEq and C.GoldBright or C.Gold, 2, 0.15)
			hit.Activated:Connect(function()
				selectedId = id
				invokeArmory("SelectInfusion", id)
			end)
		end
	else
		local cols = mobile and 2 or 3
		local gap = 10
		local cw = math.floor((leftW - gap * cols - 8) / cols)
		local ch = 186
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(cw, ch)
		grid.CellPadding = UDim2.fromOffset(gap, gap)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = content

		local ids = tab == "Weapons" and Weapons.Order
			or (tab == "Skins" and Skins.Order or (Auras and Auras.Order or {}))
		if tab == "Skins" then
			ids = table.clone(ids)
			local function rank(id)
				local sd = Skins.Data[id]
				local r = sd and Rewards.rarityTheme(Rewards.skinRarity(id, sd))
				return RARITY_RANK[r] or 0
			end
			local orderOf = {}
			for i, id in Skins.Order do orderOf[id] = i end
			table.sort(ids, function(x, y)
				if skinSort == "owned" and (ownedSkinsMap[x] and true or false) ~= (ownedSkinsMap[y] and true or false) then
					return ownedSkinsMap[x] == true
				end
				if skinSort == "alpha" then
					local nx, ny = itemName(x), itemName(y)
					if nx ~= ny then return nx < ny end
				else
					local rx, ry = rank(x), rank(y)
					if rx ~= ry then return rx > ry end
				end
				return orderOf[x] < orderOf[y]
			end)
		end

		for _, id in ids do
			local s = tab == "Skins" and Skins.Data[id] or nil
			local a = tab == "Auras" and (Auras and Auras.Data and Auras.Data[id]) or nil
			local show = true
			if tab == "Skins" and s then
				show = (not s.weapon or s.weapon == weaponFilter)
					and not s.comingSoon
					and (skinOwnership == "all" or (skinOwnership == "owned" and ownedSkinsMap[id])
						or (skinOwnership == "locked" and not ownedSkinsMap[id]))
					and (not s.boxOnly or ownedSkinsMap[id]) -- 10/11: las de Tormenta solo si las tenés
			elseif tab == "Auras" and a then
				show = ownedAurasMap[id] or skinOwnership == "all"
			end

			if show then
				table.insert(shown, id)
				local isEq = (tab == "Weapons" and equippedWeapon == id)
					or (tab == "Skins" and equippedSkin == id and (not s or not s.weapon or s.weapon == equippedWeapon))
					or (tab == "Auras" and equippedAura == id)
				local isOwned = (tab == "Weapons")
					or (tab == "Skins" and ownedSkinsMap[id])
					or (tab == "Auras" and ownedAurasMap[id])
				local rarityName = (s and Rewards.skinRarity(id, s)) or (a and a.rarity) or nil
				local rSpec = rarityName and UiTheme.Rarities[Rewards.rarityTheme(rarityName)] or nil
				local borderCol = isEq and C.GoldBright or (rSpec and rSpec.color or C.Gold)

				local card = Instance.new("Frame")
				card.Name = "Card_" .. id
				card.LayoutOrder = #shown
				card.BackgroundColor3 = C.BgCard
				card.BorderSizePixel = 0
				card.Parent = content
				UiTheme.corner(card, UiTheme.Radius.SM)
				local cardStroke = UiTheme.stroke(card, borderCol, isEq and 2.2 or 1.4, isEq and 0 or 0.22)

				local mastery = tab == "Weapons" and titleState and titleState.mastery[id]
				if mastery and mastery.rebirths > 0 then
					UiTheme.label({ parent = card, position = UDim2.fromOffset(8, 4), size = UDim2.new(1, -16, 0, 22),
						text = "★ " .. mastery.rebirths, font = "Number", textSize = UiTheme.TextSizes.SM, color = C.Coins,
						alignX = Enum.TextXAlignment.Right, zIndex = 4 })
				end
				if rSpec then
					UiTheme.rarityBadge(card, Rewards.rarityTheme(rarityName), L.t(rarityName), UDim2.fromOffset(8, 6)).ZIndex = 4
				end

				if tab == "Auras" and a then
					local holder = Instance.new("Frame")
					holder.AnchorPoint = Vector2.new(0.5, 0)
					holder.Position = UDim2.new(0.5, 0, 0, 32)
					holder.Size = UDim2.fromOffset(72, 72)
					holder.BackgroundColor3 = C.BgPreview
					holder.BorderSizePixel = 0
					holder.Parent = card
					UiTheme.corner(holder, 36)
					UiTheme.stroke(holder, a.color or borderCol, 1.6, 0.15)
					local ic = UiAssets.icon(holder, "aura_" .. (a.pattern or "crown"), 44, a.color or borderCol)
					ic.AnchorPoint = Vector2.new(0.5, 0.5)
					ic.Position = UDim2.fromScale(0.5, 0.5)
				else
					local wid = tab == "Weapons" and id or (s and s.weapon or weaponFilter)
					local sid = tab == "Skins" and id or (wid == equippedWeapon and equippedSkin or "Default")
					makeWeaponPreview(card, wid, sid, { 8, 30, cw - 16, 90 })
				end

				UiTheme.label({
					parent = card,
					position = UDim2.fromOffset(8, 126),
					size = UDim2.fromOffset(cw - 16, 24),
					text = itemName(id),
					font = "Header",
					textSize = UiTheme.TextSizes.SM,
					color = C.TextPrimary,
					truncate = Enum.TextTruncate.AtEnd,
				})

				local statusKey = isEq and "equipped" or (isOwned and "equip" or "buy")
				if tab == "Weapons" then
					statusKey = isEq and "equipped" or "choose"
				end
				UiTheme.label({
					parent = card,
					position = UDim2.fromOffset(8, 152),
					size = UDim2.fromOffset(cw - 16, 22),
					text = L.t(statusKey),
					font = "Bold",
					textSize = UiTheme.TextSizes.XS,
					color = isEq and C.Success or (isOwned and C.GoldBright or C.TextMuted),
				})

				local hit = Instance.new("TextButton")
				hit.Size = UDim2.fromScale(1, 1)
				hit.BackgroundTransparency = 1
				hit.Text = ""
				hit.ZIndex = 6
				hit.Parent = card
				UiTheme.bindGamepadFocus(hit, cardStroke, borderCol, 1.8, 0.18)

				hit.Activated:Connect(function()
					selectedId = id
					if tab == "Weapons" then
						weaponFilter = id
						invokeArmory("SelectWeapon", id)
					elseif tab == "Skins" then
						if ownedSkinsMap[id] then
							if s and s.weapon and s.weapon ~= equippedWeapon then
								invokeArmory("SelectWeapon", s.weapon)
							end
							invokeArmory("Equip", id)
						else
							render()
						end
					elseif tab == "Auras" then
						if isEq then
							invokeArmory("UnequipAura", id)
						elseif ownedAurasMap[id] then
							invokeArmory("EquipAura", id)
						else
							render()
						end
					end
				end)
			end
		end
	end

	if not selectedId or not table.find(shown, selectedId) then
		selectedId = shown[1]
	end

	-- Determinar el equipo a previsualizar en el personaje 3D
	local previewW = equippedWeapon
	local previewS = equippedSkin
	local previewI = equippedInfusion
	local previewA = equippedAura

	if tab == "Weapons" and selectedId then
		previewW = selectedId
		local eqSkinData = Skins.Data[previewS]
		if eqSkinData and eqSkinData.weapon and eqSkinData.weapon ~= previewW then
			previewS = "Default"
		end
	elseif tab == "Skins" and selectedId then
		local s = Skins.Data[selectedId]
		previewW = (s and s.weapon) or weaponFilter
		previewS = selectedId
	elseif tab == "Infusions" and selectedId then
		previewI = selectedId
	elseif tab == "Auras" and selectedId then
		previewA = selectedId
	end

	-- Visor 3D del personaje con el arma y skin en mano
	UiTheme.label({
		parent = stagePanel,
		position = UDim2.fromOffset(16, 10),
		size = UDim2.new(1, -32, 0, 22),
		text = L.t("ui.armory.characterPreview"),
		font = "Header",
		textSize = UiTheme.TextSizes.SM,
		color = C.GoldBright,
		alignX = Enum.TextXAlignment.Center,
	})

	local vpH = mobile and math.max(52, rightH - 86) or math.max(170, rightH - 188)
	local charVp = Instance.new("ViewportFrame")
	charVp.Name = "CharacterViewport"
	charVp.Position = UDim2.fromOffset(14, 34)
	charVp.Size = UDim2.new(1, -28, 0, vpH)
	charVp.BackgroundColor3 = C.BgPreview
	charVp.BorderSizePixel = 0
	charVp.Ambient = C.PreviewAmbient
	charVp.LightColor = C.PreviewLight
	charVp.LightDirection = Vector3.new(-1, -1, -1)
	charVp.Parent = stagePanel
	UiTheme.corner(charVp, UiTheme.Radius.SM)
	UiTheme.stroke(charVp, C.GoldDim, 1.2, 0.25)

	local world = Instance.new("WorldModel")
	world.Parent = charVp
	local cam3D = Instance.new("Camera")
	cam3D.FieldOfView = 36
	cam3D.Parent = charVp
	charVp.CurrentCamera = cam3D

	local avatarModel = buildCharacterAvatarModel(previewW, previewS, previewI, previewA)
	avatarModel.Parent = world
	charSpin = {
		vp = charVp,
		model = avatarModel,
		camera = cam3D,
		base = CFrame.new(0, 0.55, 0),
		distance = 8.4,
		yaw = -0.35,
		pitch = 0.08,
		zoom = 1.0,
	}

	charVp.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp
			lastMousePos = inp.Position
		end
	end)
	charVp.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseWheel and charSpin then
			charSpin.zoom = math.clamp(charSpin.zoom - inp.Position.Z * 0.1, 0.65, 1.45)
		end
	end)

	local rotatePill = Instance.new("Frame")
	rotatePill.Name = "RotateHintPill"
	rotatePill.AnchorPoint = Vector2.new(0.5, 1)
	rotatePill.Position = UDim2.new(0.5, 0, 1, -8)
	rotatePill.Size = UDim2.new(1, -24, 0, 22)
	rotatePill.BackgroundColor3 = C.BgAbyss
	rotatePill.BackgroundTransparency = 0.14
	rotatePill.BorderSizePixel = 0
	rotatePill.ZIndex = 12
	rotatePill.Parent = charVp
	UiTheme.corner(rotatePill, UiTheme.Radius.Pill)
	UiTheme.stroke(rotatePill, C.GoldDim, 1, 0.25)

	for mode, key in { Keyboard = "mz.rotateKeyboard", Gamepad = "mz.rotateGamepad", Touch = "mz.rotateTouch" } do
		Device.showFor(UiTheme.label({
			name = "RotateHintLabel",
			parent = rotatePill,
			size = UDim2.fromScale(1, 1),
			text = L.t(key),
			font = "Bold",
			textSize = UiTheme.TextSizes.XS,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 13,
		}), mode)
	end

	-- Resumen inferior del equipo activo + pieza seleccionada
	local infoY = 38 + vpH
	UiTheme.label({
		parent = stagePanel,
		position = UDim2.fromOffset(16, infoY),
		size = UDim2.new(1, -32, 0, 24),
		scaled = mobile,
		text = selectedId and itemName(selectedId) or itemName(previewW),
		font = "Title",
		textSize = UiTheme.TextSizes.LG,
		color = C.GoldBright,
	})

	UiTheme.label({
		parent = stagePanel,
		position = UDim2.fromOffset(16, infoY + 24),
		size = UDim2.new(1, -32, 0, mobile and math.max(20, rightH - infoY - 28) or 44),
		text = selectedId and itemDesc(selectedId) or itemDesc(previewW),
		scaled = mobile,
		minTextSize = 10,
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
		alignY = Enum.TextYAlignment.Top,
	})

	-- Resumen de las 4 piezas equipadas actualmente
	local summaryBar = Instance.new("Frame")
	summaryBar.Visible = not mobile
	summaryBar.AnchorPoint = Vector2.new(0.5, 1)
	summaryBar.Position = UDim2.new(0.5, 0, 1, -12)
	summaryBar.Size = UDim2.new(1, -28, 0, 62)
	summaryBar.BackgroundColor3 = C.BgAbyss
	summaryBar.BorderSizePixel = 0
	summaryBar.Parent = stagePanel
	UiTheme.corner(summaryBar, UiTheme.Radius.SM)
	UiTheme.stroke(summaryBar, C.GoldDim, 1, 0.25)

	UiTheme.label({
		parent = summaryBar,
		position = UDim2.fromOffset(12, 6),
		size = UDim2.new(1, -24, 0, 18),
		text = L.t("ui.armory.equippedLoadout"),
		font = "Bold",
		textSize = UiTheme.TextSizes.XS,
		color = C.GoldBright,
	})

	local eqSummaryText = string.format(
		"%s · %s · %s%s",
		itemName(equippedWeapon),
		itemName(equippedSkin),
		itemName(equippedInfusion),
		equippedAura ~= "" and (" · " .. itemName(equippedAura)) or ""
	)
	UiTheme.label({
		parent = summaryBar,
		position = UDim2.fromOffset(12, 26),
		size = UDim2.new(1, -24, 0, 28),
		text = eqSummaryText,
		font = "Body",
		textSize = UiTheme.TextSizes.SM,
		color = C.TextPrimary,
		truncate = Enum.TextTruncate.AtEnd,
	})

	statusLabel = UiTheme.label({
		name = "StatusMessage",
		parent = panel,
		position = UDim2.fromOffset(22, height - 34),
		size = UDim2.fromOffset(mobile and width - 44 or width - 260, 24),
		text = "",
		font = "Bold",
		textSize = UiTheme.TextSizes.SM,
		color = C.GoldBright,
	})

	Device.showFor(UiTheme.label({
		parent = panel,
		position = UDim2.fromOffset(width - 240, height - 34),
		size = UDim2.fromOffset(220, 24),
		text = L.t("ui.gamepadHint"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextMuted,
		alignX = Enum.TextXAlignment.Right,
	}), "Gamepad") -- 11/11: solo con mando (Device)

	if Device.isGamepad() and firstButton then
		GuiService.SelectedObject = firstButton
	end
end

----------------------------------------------------------------------
-- Apertura / cierre
----------------------------------------------------------------------
function setOpen(value)
	if opened == value then return end
	if value then
		local phase = (player:GetAttribute("MatchPhase") or workspace:GetAttribute("MatchPhase"))
		if player:GetAttribute("InMatch") and phase ~= "Prematch" then
			return
		end
		player:SetAttribute("SettingsOpen", false)
		player:SetAttribute("ShopOpen", false)
		player:SetAttribute("RewardsOpen", false)
	end
	opened = value
	transition += 1
	local version = transition
	player:SetAttribute("ArmoryOpen", value)
	player:SetAttribute("MenuOpen", value
		or player:GetAttribute("ShopOpen") == true
		or player:GetAttribute("SettingsOpen") == true
		or player:GetAttribute("RewardsOpen") == true)
	UiTheme.playSound(value and "UI_MenuOpen" or "UI_MenuClose")

	if value then
		weaponFilter = player:GetAttribute("WeaponId") or "Sword"
		backdrop.Visible = true
		panel.Visible = true
		loadTitles()
		render()
		panel.Position = UDim2.fromScale(0.5, 0.53)
	else
		dragInput = nil
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
				table.clear(spins)
				charSpin = nil
			end
		end)
	end
end

toggleArmoryBindable.Event:Connect(function(forceState)
	if type(forceState) == "boolean" then
		setOpen(forceState)
	else
		setOpen(not opened)
	end
end)

player:GetAttributeChangedSignal("ShopOpen"):Connect(function()
	if player:GetAttribute("ShopOpen") and opened then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("SettingsOpen"):Connect(function()
	if player:GetAttribute("SettingsOpen") and opened then
		setOpen(false)
	end
end)

player:GetAttributeChangedSignal("RewardsOpen"):Connect(function()
	if player:GetAttribute("RewardsOpen") and opened then
		setOpen(false)
	end
end)

local function closeIfLocked()
	local phase = (player:GetAttribute("MatchPhase") or workspace:GetAttribute("MatchPhase"))
	if opened and player:GetAttribute("InMatch") and phase ~= "Prematch" then
		setOpen(false)
	end
end
workspace:GetAttributeChangedSignal("MatchPhase"):Connect(closeIfLocked)
player:GetAttributeChangedSignal("MatchPhase"):Connect(closeIfLocked)

UIS.InputChanged:Connect(function(input)
	if not opened then return end
	if input.KeyCode == Enum.KeyCode.Thumbstick2 then
		stick = Vector2.new(input.Position.X, input.Position.Y)
	elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
		zoomAxis = input.Position.Z
	elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
		zoomAxis = -input.Position.Z
	elseif dragInput and charSpin and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - lastMousePos
		lastMousePos = input.Position
		charSpin.yaw += delta.X * 0.012
		charSpin.pitch = math.clamp(charSpin.pitch + delta.Y * 0.008, -0.35, 0.45)
	end
end)

UIS.InputEnded:Connect(function(input)
	if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragInput = nil
	end
	if input.KeyCode == Enum.KeyCode.ButtonL2 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		zoomAxis = 0
	end
end)

UIS.InputBegan:Connect(function(input, processed)
	if opened and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then
		if not processed or input.KeyCode == Enum.KeyCode.ButtonB then
			setOpen(false)
		end
		return
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not opened then return end
	if charSpin and charSpin.vp.Parent then
		if not dragInput and stick.Magnitude < 0.05 then
			charSpin.yaw += dt * 0.32
		else
			charSpin.yaw += stick.X * dt * 2.0
			charSpin.pitch = math.clamp(charSpin.pitch - stick.Y * dt, -0.35, 0.45)
		end
		charSpin.zoom = math.clamp(charSpin.zoom + zoomAxis * dt * 0.65, 0.65, 1.45)
		local rot = CFrame.Angles(charSpin.pitch, charSpin.yaw, 0)
		charSpin.model:PivotTo(rot * charSpin.base)
		local look = charSpin.lookHeight or 0.1
		local eye = charSpin.lookHeight or 0.4
		charSpin.camera.CFrame = CFrame.lookAt(Vector3.new(0, eye, charSpin.distance * charSpin.zoom), Vector3.new(0, look, 0))
	end

	for i = #spins, 1, -1 do
		local v = spins[i]
		if not v.vp.Parent then
			table.remove(spins, i)
		else
			-- 10/11: miniaturas quietas, de perfil (antes oscilaban todas en cada frame y la armería iba a tirones;
			-- además así no quedan de punta). Se acomodan una sola vez.
			if not v.placed then
				v.placed = true
				v.model:PivotTo(v.base)
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
