-- LocalScript: StarterPlayer/StarterPlayerScripts/Shop
-- Armería del Ocaso rediseñada (Fase 3, responsable: Gemini, etapa 8).
-- Pestañas: Armas, Skins, Infusiones (4 tarjetas altas estilo infusiones ref2.jpg), Auras (C11 con pedestal en el mundo)
-- y Clasificatorias ("Próximamente").
-- Incluye bloqueo de foco de mando dentro del diálogo de confirmación y soporte de ButtonB / Escape.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local Theme = require(RS:WaitForChild("Theme", 10))
local UiTheme = require(RS:WaitForChild("UiTheme", 10))
local UiAssets = require(RS:WaitForChild("UiAssets", 10))
local L = require(RS:WaitForChild("Localization", 10))
local Skins = require(RS:WaitForChild("Skins", 10))
local Weapons = require(RS:WaitForChild("WeaponData", 10))
local Infusions = require(RS:WaitForChild("Infusions", 10))
local Builder = require(RS:WaitForChild("WeaponBuilder", 10))

-- Carga segura de módulos de Codex (C11: Auras y AuraFx)
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
-- ScreenGui y botón de acceso (LobbyUI maneja el acceso principal en el dock izquierdo)
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local topBtnScale = Instance.new("UIScale")
local toggleBtn = UiTheme.button({
	name = "ArmoryToggle",
	parent = gui,
	position = UDim2.fromOffset(16, 12),
	size = UDim2.fromOffset(168, 44),
	text = L.t("armory"),
	font = "Header",
	textSize = UiTheme.TextSizes.MD,
	variant = "secondary",
})
topBtnScale.Parent = toggleBtn
toggleBtn.Visible = false -- Oculto: el botón principal está en el dock izquierdo de LobbyUI

local toggleIcon = UiAssets.icon(toggleBtn, "armory", 20, C.GoldBright)
toggleIcon.AnchorPoint = Vector2.new(0, 0.5)
toggleIcon.Position = UDim2.new(0, 10, 0.5, 0)
toggleBtn.TextXAlignment = Enum.TextXAlignment.Left

-- Velo de fondo oscuro cuando se abre la tienda
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = C.BgAbyss
backdrop.BackgroundTransparency = 0.32
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.Parent = gui

-- Panel principal de la Armería
local BASE_W, BASE_H = 1060, 640
local panel = UiTheme.panel({
	name = "ShopPanel",
	parent = gui,
	canvasGroup = true,
	anchor = Vector2.new(0.5, 0.5),
	position = UDim2.fromScale(0.5, 0.5),
	size = UDim2.fromOffset(BASE_W, BASE_H),
	bg = C.BgPrimary,
	borderColor = C.Gold,
	borderThickness = UiTheme.Stroke.Thick,
	ornaments = true,
	ornamentSize = 16,
	visible = false,
})
local scale = Instance.new("UIScale")
scale.Parent = panel

----------------------------------------------------------------------
-- Estado de la tienda
----------------------------------------------------------------------
local tab = "Skins"
local weapon = "Sword"
local selected = "Relic06"
local rarity = "all"
local ownership = "all"
local auraKind = "all"
local rarities = { "all", "Common", "Rare", "Epic", "Legendary", "Mythic" }
local filters = { "all", "owned", "available" }
local auraKinds = { "all", "Body", "Weapon" }

local spins = {}
local detailSpin = nil
local modal = nil
local content = nil
local detail = nil
local messageLabel = nil
local firstButton = nil
local lastSelectedBeforeModal = nil
local busy = false
local opened = false
local drag = nil
local lastPosition = nil
local stick = Vector2.zero
local zoomAxis = 0
local transition = 0

-- Estado del pedestal 3D en el mundo para vista previa de Auras (Contrato C11)
local auraStage = nil
local auraCleanup = nil
local auraTargetModel = nil
local auraSavedCamType = nil
local auraYaw = 0

local render, inspect, setOpen

----------------------------------------------------------------------
-- Funciones auxiliares de datos y estado
----------------------------------------------------------------------
local function parseSet(attrName)
	local result = {}
	for id in string.gmatch(player:GetAttribute(attrName) or "", "[^,]+") do
		result[id] = true
	end
	return result
end

local function ownSkins()
	return parseSet("OwnedSkins")
end

local function ownAuras()
	return parseSet("OwnedAuras")
end

local function pending(item)
	if not item then return true end
	return item.comingSoon
end

local function priceText(item)
	if not item then return "" end
	if item.price == 0 then return L.t("Free") end
	return L.t(item.currency, { amount = item.price })
end

local function itemName(id)
	if tab == "Weapons" then return L.t("weapon." .. id) end
	if tab == "Infusions" then return L.t("infusion." .. id) end
	if tab == "Auras" then
		local a = Auras and Auras.Data and Auras.Data[id]
		return a and L.t(a.nameKey) or id
	end
	local s = Skins.Data[id]
	return s and L.t(s.nameKey) or L.t("skin." .. id)
end

local function itemDesc(id)
	if tab == "Weapons" then return L.t("weaponDesc." .. id) end
	if tab == "Infusions" then return L.t("infusionDesc." .. id) end
	if tab == "Auras" then
		local a = Auras and Auras.Data and Auras.Data[id]
		return a and L.t(a.descKey) or ""
	end
	local s = Skins.Data[id]
	return s and L.t(s.descKey) or L.t("skinDesc." .. id)
end

local function state(id)
	local inMatch = player:GetAttribute("InMatch") == true
	if tab == "Weapons" or tab == "Infusions" then
		if inMatch then return "locked" end
		local current = player:GetAttribute(tab == "Weapons" and "WeaponId" or "InfusionId")
		return current == id and "equipped" or "choose"
	elseif tab == "Auras" then
		local a = Auras and Auras.Data and Auras.Data[id]
		if not a then return "soon" end
		if player:GetAttribute("EquippedAura") == id then return "equipped" end
		if ownAuras()[id] then
			if inMatch then return "locked" end
			return "equip"
		end
		return pending(a) and "soon" or "buy"
	end

	local s = Skins.Data[id]
	if not s or s.comingSoon then return "soon" end
	if player:GetAttribute("EquippedSkin") == id and (not s.weapon or player:GetAttribute("WeaponId") == s.weapon) then
		return "equipped"
	end
	if ownSkins()[id] then
		if inMatch then return "locked" end
		if s.weapon and s.weapon ~= player:GetAttribute("WeaponId") then return "otherWeapon" end
		return "equip"
	end
	return pending(s) and "soon" or "buy"
end

----------------------------------------------------------------------
-- Vista previa de Auras sobre tu propio personaje (Puntos 3 y 8 de Ronda 3)
-- Sin escenario lejano a 680 studs: el personaje se ve en vivo en la ciudad con su aura.
----------------------------------------------------------------------
local previewHidden={}
local savedPreviewCam
local function destroyAuraWorldPreview()
 RunService:UnbindFromRenderStep("ShopCharacterPreview")
 for obj,value in previewHidden do if obj.Parent then obj.LocalTransparencyModifier=value end end
 table.clear(previewHidden)
 if savedPreviewCam then
  local camera=workspace.CurrentCamera
  if camera then camera.CFrame=savedPreviewCam.cf camera.CameraSubject=savedPreviewCam.subject camera.FieldOfView=savedPreviewCam.fov end
  savedPreviewCam=nil
 end
	if auraCleanup then
		pcall(auraCleanup)
		auraCleanup = nil
	end
	auraTargetModel = nil
	if auraStage then
		auraStage:Destroy()
		auraStage = nil
	end
	local cam = workspace.CurrentCamera
	if cam and auraSavedCamType then
		cam.CameraType = auraSavedCamType
		auraSavedCamType = nil
	end
	if panel then
		panel.AnchorPoint=Vector2.new(0.5,0.5)
 panel.Size=UDim2.fromOffset(BASE_W, BASE_H)
 panel.Position = UDim2.fromScale(0.5, 0.5)
		panel.BackgroundTransparency = 0
	end
	if backdrop then
		backdrop.BackgroundTransparency = 0.32
	end

	-- Al quitar la prueba vuelve la que tenga equipada el jugador
	local eqAura = player:GetAttribute("EquippedAura")
	if eqAura and eqAura ~= "" then
		player:SetAttribute("EquippedAura", eqAura)
	end
end

local function setupAuraWorldPreview(auraId)
	destroyAuraWorldPreview()
	if not opened or tab ~= "Auras" or not Auras or not AuraFx then return end
	local auraData = Auras.Data and Auras.Data[auraId]
	if not auraData then return end

	local char = player.Character
	if not char or not char.Parent then return end

	local isBody = auraData.kind == "Body"
	local target = char
	if not isBody then
		local tool = char:FindFirstChildWhichIsA("Tool") or (player.Backpack and player.Backpack:FindFirstChildWhichIsA("Tool"))
		if tool and tool.Parent ~= char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum:EquipTool(tool) end
		end
		target = tool or char
	end

	local ok, cleanupFn = pcall(function()
		return AuraFx.attach(target, auraId, { preview = true, character = char })
	end)
	if ok and type(cleanupFn) == "function" then
		auraCleanup = cleanupFn
	end

	local cam = workspace.CurrentCamera
	local root = char:FindFirstChild("HumanoidRootPart")
	if cam and root then
		savedPreviewCam={cf=cam.CFrame,subject=cam.CameraSubject,fov=cam.FieldOfView}
  auraSavedCamType = cam.CameraType
		cam.CameraType = Enum.CameraType.Scriptable
		local lookCF = root.CFrame
		local camPos = root.Position + lookCF.LookVector * 7.4 + lookCF.RightVector * 2.2 + Vector3.new(0, 1.2, 0)
		local targetPos = root.Position + Vector3.new(0, 0.3, 0)
		cam.CFrame = CFrame.lookAt(camPos, targetPos)
	end

	-- Claude 9/11: el panel se ESCALA entero a la mitad izquierda (antes se recortaba y tapaba el detalle
	-- y el botón de compra); el personaje queda completo en la mitad derecha.
	local function applyAuraLayout()
		local camera = workspace.CurrentCamera
		local vp = camera and camera.ViewportSize or Vector2.new(BASE_W, BASE_H)
		panel.AnchorPoint = Vector2.new(0, 0.5)
		panel.Position = UDim2.new(0, 12, 0.5, 0)
		panel.Size = UDim2.fromOffset(BASE_W, BASE_H)
		scale.Scale = math.min(0.5 * vp.X / BASE_W, 0.9 * vp.Y / BASE_H)
	end
	applyAuraLayout()
	backdrop.BackgroundTransparency = 0.75
	panel.BackgroundTransparency = 0.10
 RunService:BindToRenderStep("ShopCharacterPreview",Enum.RenderPriority.Camera.Value+4,function(dt)
  if not opened or tab~="Auras" then return end
  applyAuraLayout()
  local character=player.Character local rootPart=character and character:FindFirstChild("HumanoidRootPart")
  local camera=workspace.CurrentCamera if not rootPart or not camera then return end
  for _,obj in character:GetDescendants() do if obj:IsA("BasePart") then
   if previewHidden[obj]==nil then previewHidden[obj]=obj.LocalTransparencyModifier end obj.LocalTransparencyModifier=0
  end end
  auraYaw+=dt*0.15
  camera.CameraType=Enum.CameraType.Scriptable
  local targetPos=rootPart.Position+Vector3.yAxis*0.6
  -- cuerpo entero (con corona o alas) en la mitad derecha
  local offset=rootPart.CFrame:VectorToWorldSpace(Vector3.new(math.sin(auraYaw)*1.5,1.2,-11))
  local cf=CFrame.lookAt(targetPos+offset,targetPos)
  local aspect=camera.ViewportSize.X/math.max(camera.ViewportSize.Y,1)
  local shift=11*math.tan(math.rad(camera.FieldOfView/2))*aspect*0.5
  camera.CFrame=cf+cf.RightVector*(-shift)
 end)
end

----------------------------------------------------------------------
-- ViewportFrame 3D para Armas y Skins (Punto 4: encuadre proporcional)
----------------------------------------------------------------------
local function preview(parent, w, s, rect, manual)
	local vp = Instance.new("ViewportFrame")
	vp.Position = UDim2.fromOffset(rect[1], rect[2])
	vp.Size = UDim2.fromOffset(rect[3], rect[4])
	vp.BackgroundColor3 = C.BgPreview
	vp.Ambient = Color3.fromRGB(155, 150, 145)
	vp.LightColor = Color3.fromRGB(255, 240, 215)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.BorderSizePixel = 0
	vp.Parent = parent
	UiTheme.corner(vp, UiTheme.Radius.SM)
	UiTheme.stroke(vp, C.BorderSubtle, 1, 0.35)

	local model = Builder.buildModel(w, s)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored = true end
	end

	local horizontal = rect[3] > rect[4] * 1.15
	local orientation = horizontal and (CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, math.rad(18))) or CFrame.Angles(-math.pi / 2, 0, 0)
	model:PivotTo(orientation)
	model.Parent = vp

	local bounds, size = model:GetBoundingBox()
	local base = CFrame.new(-bounds.Position) * orientation
	model:PivotTo(base)

	local camera = Instance.new("Camera")
	camera.FieldOfView = 26
	camera.Parent = vp
	vp.CurrentCamera = camera

	local aspect = math.max(0.5, rect[3] / math.max(1, rect[4]))
	local halfTan = math.tan(math.rad(camera.FieldOfView / 2))
	local spanW = size.X
	local spanH = size.Y
	local reqDistX = (spanW * 0.5) / (halfTan * aspect * 0.84)
	local reqDistY = (spanH * 0.5) / (halfTan * 0.84)
	local distance = math.max(reqDistX, reqDistY) + 0.15

	local view = {
		vp = vp,
		model = model,
		camera = camera,
		base = base,
		distance = distance,
		yaw = 0.35,
		pitch = 0,
		zoom = 1,
		manual = manual,
		horizontal = horizontal,
	}
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, distance), Vector3.zero)
	table.insert(spins, view)

	if manual then
		vp.Active = true
		vp.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				drag = input
				lastPosition = input.Position
			end
		end)
		vp.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				view.zoom = math.clamp(view.zoom - input.Position.Z * 0.12, 0.55, 1.65)
			end
		end)
	end
	return view
end

----------------------------------------------------------------------
-- Avisos y llamadas al servidor (Remotes.Shop)
----------------------------------------------------------------------
local function notice(value, failed)
	if messageLabel and messageLabel.Parent then
		messageLabel.Text = L.format(value)
		messageLabel.TextColor3 = failed and C.Danger or C.GoldBright
	end
end

local function act(action, id)
	if busy then return end
	busy = true
	task.spawn(function()
		local callOK, ok, result = pcall(function()
			return remote:InvokeServer(action, id)
		end)
		busy = false
		if opened then render() end
		notice(callOK and result or { key = "error" }, not callOK or not ok)
		UiTheme.playSound(callOK and ok and ((action == "Buy" or action == "BuyAura") and "UI_PurchaseOK" or "UI_Equip") or "UI_Error")
		if callOK and ok and action == "Buy" and ownSkins()[id] and detailSpin then
			detailSpin.flashUntil = os.clock() + 0.65
		end
	end)
end

----------------------------------------------------------------------
-- Diálogo de confirmación de compra con foco de mando encerrado
----------------------------------------------------------------------
local MODAL_FOCUS_GROUP = "ShopConfirmModalGroup"

local function dismiss()
	UiTheme.releaseGamepadFocus(MODAL_FOCUS_GROUP)
	if modal then
		modal:Destroy()
		modal = nil
	end
	if UIS.GamepadEnabled and opened then
		local target = (lastSelectedBeforeModal and lastSelectedBeforeModal.Parent and lastSelectedBeforeModal) or firstButton
		GuiService.SelectedObject = target
	end
end

local function confirmPurchase(id, isAura)
	if modal then return end
	local item = isAura and (Auras and Auras.Data and Auras.Data[id]) or Skins.Data[id]
	if not item then return end

	lastSelectedBeforeModal = GuiService.SelectedObject

	local veil = Instance.new("TextButton")
	veil.Name = "ConfirmModalVeil"
	veil.Text = ""
	veil.AutoButtonColor = false
	veil.Selectable = false
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = C.BgModalVeil
	veil.BackgroundTransparency = 0.22
	veil.ZIndex = 40
	veil.Parent = panel
	modal = veil

	local rarityInfo = UiTheme.Rarities[item.rarity or "Common"] or UiTheme.Rarities.Common
	local box = UiTheme.panel({
		name = "DialogBox",
		parent = veil,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromOffset(440, 340),
		bg = C.BgPanel,
		borderColor = rarityInfo.color,
		borderThickness = UiTheme.Stroke.Heavy,
		ornaments = true,
		zIndex = 41,
	})

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(20, 16),
		size = UDim2.new(1, -40, 0, 32),
		text = L.t("confirmTitle", { name = L.t(item.nameKey) }),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
		alignX = Enum.TextXAlignment.Center,
		zIndex = 42,
	})

	UiTheme.rarityBadge(box, item.rarity, L.t(item.rarity or "Common"), UDim2.new(0.5, 0, 0, 52), Vector2.new(0.5, 0)).ZIndex = 42

	if not isAura then
		local vpView = preview(box, item.weapon or weapon, id, { 40, 82, 360, 132 }, false)
		vpView.vp.ZIndex = 42
	else
		local iconHolder = Instance.new("Frame")
		iconHolder.AnchorPoint = Vector2.new(0.5, 0)
		iconHolder.Position = UDim2.new(0.5, 0, 0, 92)
		iconHolder.Size = UDim2.fromOffset(96, 96)
		iconHolder.BackgroundColor3 = C.BgPreview
		iconHolder.ZIndex = 42
		iconHolder.Parent = box
		UiTheme.corner(iconHolder, 48)
		UiTheme.stroke(iconHolder, item.color or rarityInfo.color, 2, 0.1)
		local ic = UiAssets.icon(iconHolder, "aura_" .. (item.pattern or "crown"), 60, item.color or rarityInfo.color)
		ic.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.Position = UDim2.fromScale(0.5, 0.5)
		ic.ZIndex = 43
	end

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(24, 220),
		size = UDim2.new(1, -48, 0, 28),
		text = priceText(item),
		font = "Number",
		textSize = UiTheme.TextSizes.LG,
		color = C.Coins,
		alignX = Enum.TextXAlignment.Center,
		zIndex = 42,
	})

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(24, 248),
		size = UDim2.new(1, -48, 0, 22),
		text = L.t("ui.confirmBody"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
		alignX = Enum.TextXAlignment.Center,
		zIndex = 42,
	})

	local cancelBtn = UiTheme.button({
		name = "CancelBtn",
		parent = box,
		position = UDim2.fromOffset(24, 278),
		size = UDim2.fromOffset(186, 44),
		text = L.t("cancel"),
		variant = "secondary",
		zIndex = 43,
		onClick = dismiss,
	})

	local confirmBtn = UiTheme.button({
		name = "ConfirmBtn",
		parent = box,
		position = UDim2.fromOffset(230, 278),
		size = UDim2.fromOffset(186, 44),
		text = L.t("confirm"),
		variant = "gold",
		zIndex = 43,
		onClick = function()
			dismiss()
			act(isAura and "BuyAura" or "Buy", id)
		end,
	})

	-- Encerrar el foco del mando estrictamente entre Cancelar y Confirmar
	UiTheme.trapGamepadFocus(MODAL_FOCUS_GROUP, { cancelBtn, confirmBtn })
	if UIS.GamepadEnabled then
		GuiService.SelectedObject = cancelBtn
	end
end

----------------------------------------------------------------------
-- Panel derecho de inspección detallada
----------------------------------------------------------------------
function inspect(id)
	selected = id
	for _, v in detail:GetChildren() do
		if not v:IsA("UIStroke") and not v:IsA("UICorner") and not v:IsA("UIGradient") and v.Name ~= "Ornaments" then
			v:Destroy()
		end
	end
	detailSpin = nil

	local w = detail.Size.X.Offset
	local h = detail.Size.Y.Offset
	local isSkin = tab == "Skins"
	local isAura = tab == "Auras"
	local s = isSkin and Skins.Data[id] or nil
	local a = isAura and (Auras and Auras.Data and Auras.Data[id]) or nil
	local item = s or a
	local rarityId = item and item.rarity or nil
	local raritySpec = rarityId and UiTheme.Rarities[rarityId] or nil

	if isAura then
		setupAuraWorldPreview(id)
		detail.BackgroundTransparency = 0.72
	else
		destroyAuraWorldPreview()
		detail.BackgroundTransparency = 0
	end

	-- Título del elemento seleccionado
	UiTheme.label({
		parent = detail,
		position = UDim2.fromOffset(16, 12),
		size = UDim2.fromOffset(w - 32, 30),
		text = itemName(id),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = raritySpec and raritySpec.color or C.GoldBright,
	})

	-- Insignia de rareza o subcategoría
	if rarityId then
		UiTheme.rarityBadge(detail, rarityId, L.t(rarityId), UDim2.fromOffset(16, 44))
	end
	if isAura and a then
		UiTheme.label({
			parent = detail,
			position = UDim2.fromOffset(145, 44),
			size = UDim2.fromOffset(w - 160, 22),
			text = L.t(a.kind == "Body" and "ui.aura.body" or "ui.aura.weapon"),
			font = "Body",
			textSize = UiTheme.TextSizes.SM,
			color = C.TextSecondary,
		})
	end

	local previewTop = rarityId and 74 or 48
	local previewH = math.max(130, h - previewTop - 162)

	if tab == "Infusions" then
		local artHolder = Instance.new("Frame")
		artHolder.Position = UDim2.fromOffset(16, previewTop)
		artHolder.Size = UDim2.fromOffset(w - 32, previewH)
		artHolder.BackgroundTransparency = 1
		artHolder.Parent = detail
		UiAssets.infusionCardArt(artHolder, id)

		local beatsId = Infusions.Beats[id]
		local weakId = Infusions.beatenBy(id)
		UiTheme.label({
			parent = artHolder,
			position = UDim2.new(0, 14, 1, -54),
			size = UDim2.new(1, -28, 0, 22),
			text = L.t("ui.infusion.beats", { target = L.t("infusion." .. tostring(beatsId)) }),
			font = "Bold",
			textSize = UiTheme.TextSizes.SM,
			color = C.Success,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 6,
		})
		UiTheme.label({
			parent = artHolder,
			position = UDim2.new(0, 14, 1, -30),
			size = UDim2.new(1, -28, 0, 22),
			text = L.t("ui.infusion.weak", { target = L.t("infusion." .. tostring(weakId)) }),
			font = "Bold",
			textSize = UiTheme.TextSizes.SM,
			color = C.Warning,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 6,
		})
	elseif isAura then
  -- Character is rendered in the unobstructed right half of the screen.
	elseif not (s and s.comingSoon) then
		detailSpin = preview(detail, tab == "Weapons" and id or (s and s.weapon or weapon), isSkin and id or "Default", { 16, previewTop, w - 32, previewH }, true)
	else
		UiTheme.label({
			parent = detail,
			position = UDim2.fromOffset(16, previewTop),
			size = UDim2.fromOffset(w - 32, previewH),
			text = L.t("soon"),
			font = "Title",
			textSize = UiTheme.TextSizes.XXL,
			color = C.TextMuted,
			alignX = Enum.TextXAlignment.Center,
		})
	end

	-- Descripción y precio
	UiTheme.label({
		parent = detail,
		position = UDim2.fromOffset(16, h - 148),
		size = UDim2.fromOffset(w - 32, 42),
		text = itemDesc(id),
		font = "Body",
		textSize = UiTheme.TextSizes.SM,
		color = C.TextSecondary,
	})

	if item then
		UiTheme.label({
			parent = detail,
			position = UDim2.fromOffset(16, h - 102),
			size = UDim2.fromOffset(w - 32, 24),
			text = L.t(item.rarity or "Common") .. "  ·  " .. priceText(item),
			font = "Number",
			textSize = UiTheme.TextSizes.MD,
			color = C.Coins,
		})
	end

	-- Botón de acción principal (Comprar / Equipar / Elegir / Equipada / Próximamente)
	local current = state(id)
	local actionable = current == "buy" or current == "equip" or current == "choose"
	local btnVariant = current == "buy" and "gold" or (current == "equipped" and "success" or (actionable and "primary" or "secondary"))

	local actionW = (isAura and current == "equipped") and (w - 152) or (w - 32)
	UiTheme.button({
		name = "ActionButton",
		parent = detail,
		position = UDim2.fromOffset(16, h - 72),
		size = UDim2.fromOffset(actionW, 44),
		text = L.t(current),
		variant = btnVariant,
		disabled = not actionable,
		onClick = function()
			if current == "buy" then
				confirmPurchase(id, isAura)
			elseif current == "equip" then
				act(isAura and "EquipAura" or "Equip", id)
			elseif current == "choose" then
				act(tab == "Weapons" and "SelectWeapon" or "SelectInfusion", id)
			end
		end,
	})

	if isAura and current == "equipped" then
		UiTheme.button({
			name = "UnequipAuraBtn",
			parent = detail,
			position = UDim2.fromOffset(24 + actionW, h - 72),
			size = UDim2.fromOffset(112, 44),
			text = L.t("ui.aura.unequip"),
			variant = "danger",
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				act("UnequipAura", id)
			end,
		})
	end

	UiTheme.label({
		parent = detail,
		position = UDim2.fromOffset(16, h - 24),
		size = UDim2.fromOffset(w - 110, 20),
		text = L.t(UIS.GamepadEnabled and "inspectPad" or "inspect"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextMuted,
	})

	if detailSpin then
		UiTheme.button({
			parent = detail,
			position = UDim2.fromOffset(w - 88, previewTop + 8),
			size = UDim2.fromOffset(32, 32),
			text = "−",
			onClick = function()
				detailSpin.zoom = math.min(1.65, detailSpin.zoom + 0.18)
			end,
		})
		UiTheme.button({
			parent = detail,
			position = UDim2.fromOffset(w - 52, previewTop + 8),
			size = UDim2.fromOffset(32, 32),
			text = "+",
			onClick = function()
				detailSpin.zoom = math.max(0.55, detailSpin.zoom - 0.18)
			end,
		})
	end
end

----------------------------------------------------------------------
-- Renderizado completo del panel de la Tienda
----------------------------------------------------------------------
function render()
	dismiss()
	table.clear(spins)
	detailSpin = nil
	drag = nil
	if tab ~= "Auras" then
		destroyAuraWorldPreview()
	end

	for _, c in panel:GetChildren() do
		if c ~= scale and not c:IsA("UIStroke") and not c:IsA("UICorner") and not c:IsA("UIGradient") and c.Name ~= "Ornaments" then
			c:Destroy()
		end
	end

	local cam = workspace.CurrentCamera
	local viewport = cam and cam.ViewportSize or Vector2.new(BASE_W, BASE_H)
	local mobile = viewport.X < 760
	local width = mobile and 680 or BASE_W
	local height = mobile and 620 or BASE_H
	panel.Size = UDim2.fromOffset(width, height)
	scale.Scale = UiTheme.computeScale(viewport, width, height, player)

	-- Cabecera: título, saldo de monedas y botón cerrar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = panel
	UiTheme.corner(header, UiTheme.Radius.MD)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(22, 0),
		size = UDim2.fromOffset(340, 56),
		text = L.t("armory"),
		font = "Title",
		textSize = UiTheme.TextSizes.XXL,
		color = C.GoldBright,
	})

	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	local coinBox = Instance.new("Frame")
	coinBox.AnchorPoint = Vector2.new(1, 0.5)
	coinBox.Position = UDim2.new(1, -134, 0.5, 0)
	coinBox.Size = UDim2.fromOffset(170, 36)
	coinBox.BackgroundColor3 = C.BgAbyss
	coinBox.BorderSizePixel = 0
	coinBox.Parent = header
	UiTheme.corner(coinBox, UiTheme.Radius.Pill)
	UiTheme.stroke(coinBox, C.GoldDim, 1, 0.25)

	local coinIcon = UiAssets.icon(coinBox, "coin", 20, C.Coins)
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.Position = UDim2.new(0, 10, 0.5, 0)

	UiTheme.label({
		parent = coinBox,
		position = UDim2.fromOffset(36, 0),
		size = UDim2.new(1, -44, 1, 0),
		text = L.t("Coins", { amount = coinsVal and coinsVal.Value or 0 }),
		font = "Number",
		textSize = UiTheme.TextSizes.SM,
		color = C.Coins,
		alignX = Enum.TextXAlignment.Right,
	})

	UiTheme.button({
		name = "CloseButton",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = UDim2.new(1, -16, 0.5, 0),
		size = UDim2.fromOffset(106, 40),
		text = L.t("close"),
		variant = "secondary",
		onClick = function()
			setOpen(false)
		end,
	})

	-- Barra de pestañas: Armas, Skins, Infusiones, Auras, Clasificatorias
	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "TabsBar"
	tabsBar.Position = UDim2.fromOffset(20, 64)
	tabsBar.Size = UDim2.new(1, -40, 0, 44)
	tabsBar.BackgroundTransparency = 1
	tabsBar.Parent = panel
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabsBar

	local tabDefs = {
		{ id = "Weapons", label = L.t("Weapons") },
		{ id = "Skins", label = L.t("Skins") },
		{ id = "Infusions", label = L.t("Infusions") },
		{ id = "Auras", label = L.t("ui.tab.Auras") },
	}
	for i, def in tabDefs do
		local b = UiTheme.tabButton({
			name = "Tab_" .. def.id,
			parent = tabsBar,
			layoutOrder = i,
			size = UDim2.fromOffset(mobile and 122 or 164, 44),
			text = def.label,
			badgeText = def.badge,
			active = tab == def.id,
			onClick = function()
				tab = def.id
				selected = nil
				render()
			end,
		})
		if i == 1 then firstButton = b end
	end

	-- Subbarra de filtros para Skins y Auras
	local top = 118
	if tab == "Skins" then
		local weaponBar = Instance.new("Frame")
		weaponBar.Position = UDim2.fromOffset(20, 114)
		weaponBar.Size = UDim2.fromOffset(width - 40, 36)
		weaponBar.BackgroundTransparency = 1
		weaponBar.Parent = panel

		local bw = math.floor((width - 40) / #Weapons.Order)
		for i, wid in Weapons.Order do
			UiTheme.button({
				parent = weaponBar,
				position = UDim2.fromOffset((i - 1) * bw, 0),
				size = UDim2.fromOffset(bw - 6, 36),
				text = L.t("weapon." .. wid),
				selected = wid == weapon,
				textSize = UiTheme.TextSizes.SM,
				onClick = function()
					weapon = wid
					selected = nil
					render()
				end,
			})
		end

		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(20, 156),
			size = UDim2.fromOffset(210, 34),
			text = L.t("ui.filter.rarity", { value = L.t(rarity) }),
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				rarity = rarities[(table.find(rarities, rarity) % #rarities) + 1]
				render()
			end,
		})
		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(238, 156),
			size = UDim2.fromOffset(210, 34),
			text = L.t("ui.filter.ownership", { value = L.t(ownership) }),
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				ownership = filters[(table.find(filters, ownership) % #filters) + 1]
				render()
			end,
		})
		top = 198
	elseif tab == "Auras" then
		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(20, 116),
			size = UDim2.fromOffset(200, 36),
			text = L.t("ui.filter.auraKind", { value = auraKind == "all" and L.t("all") or L.t(auraKind == "Body" and "ui.aura.body" or "ui.aura.weapon") }),
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				auraKind = auraKinds[(table.find(auraKinds, auraKind) % #auraKinds) + 1]
				render()
			end,
		})
		UiTheme.button({
			parent = panel,
			position = UDim2.fromOffset(228, 116),
			size = UDim2.fromOffset(200, 36),
			text = L.t("ui.filter.rarity", { value = L.t(rarity) }),
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				rarity = rarities[(table.find(rarities, rarity) % #rarities) + 1]
				render()
			end,
		})
		top = 160
	end

	-- Geometría de contenido (izquierda) y panel de inspección (derecha)
	local contentH = height - top - 46
	local listWidth = mobile and (width - 40) or math.floor(width * 0.60) - 28
	local listHeight = mobile and math.floor(contentH * 0.50) or contentH

	content = Instance.new("ScrollingFrame")
	content.Name = "ItemList"
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
		position = UDim2.fromOffset(mobile and 20 or (28 + listWidth), mobile and (top + listHeight + 8) or top),
		size = UDim2.fromOffset(mobile and (width - 40) or (width - listWidth - 48), mobile and (contentH - listHeight - 8) or contentH),
		bg = C.BgPanel,
		borderColor = C.Gold,
		ornaments = true,
	})

	local shown = {}

	-- PESTAÑA INFUSIONES (Agregado 9/11: referencias\infusiones ref2.jpg)
	-- Una tarjeta alta por infusión, solo las 4 del juego (Fire, Lightning, Ice, Shadow),
	-- con fondo temático, icono reversionado arriba, nombre, lema corto y marco dorado.
	if tab == "Infusions" then
		local gap = 10
		local count = #Infusions.Order -- Exactamente las 4 infusiones del juego
		local cardW = math.floor((listWidth - gap * (count - 1) - 4) / count)
		local cardH = math.max(260, listHeight - 8)

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.Padding = UDim.new(0, gap)
		rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rowLayout.Parent = content

		for idx, id in Infusions.Order do
			table.insert(shown, id)
			local isEquipped = player:GetAttribute("InfusionId") == id
			local isSelected = selected == id or (not selected and idx == 1)

			local card = Instance.new("Frame")
			card.Name = "InfusionCard_" .. id
			card.LayoutOrder = idx
			card.Size = UDim2.fromOffset(cardW, cardH)
			card.BackgroundColor3 = C.BgCard
			card.BorderSizePixel = 0
			card.Parent = content
			UiTheme.corner(card, UiTheme.Radius.MD)

			-- Ilustración temática e icono reversionado en medallón superior
			UiAssets.infusionCardArt(card, id)

			-- Marco dorado (más grueso y luminoso cuando está equipada o seleccionada)
			local cardStroke = UiTheme.stroke(card, isEquipped and C.GoldBright or C.Gold, (isEquipped or isSelected) and 2.5 or 1.6, isEquipped and 0 or 0.15)
			UiTheme.ornamentCorners(card, C.GoldBright, 12, 2)

			-- Nombre en tipografía titular grande
			UiTheme.label({
				parent = card,
				position = UDim2.new(0, 8, 0.50, 0),
				size = UDim2.new(1, -16, 0, 30),
				text = string.upper(itemName(id)),
				font = "Title",
				textSize = UiTheme.TextSizes.XL,
				color = C.GoldBright,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 5,
			})

			-- Separador dorado sutil
			local div = Instance.new("Frame")
			div.AnchorPoint = Vector2.new(0.5, 0)
			div.Position = UDim2.new(0.5, 0, 0.50, 32)
			div.Size = UDim2.new(0.66, 0, 0, 2)
			div.BackgroundColor3 = C.Gold
			div.BackgroundTransparency = 0.25
			div.BorderSizePixel = 0
			div.ZIndex = 5
			div.Parent = card

			-- Lema corto de la infusión
			UiTheme.label({
				parent = card,
				position = UDim2.new(0, 10, 0.60, 0),
				size = UDim2.new(1, -20, 0.22, 0),
				text = L.t("infusionMotto." .. id),
				font = "Body",
				textSize = UiTheme.TextSizes.SM,
				color = C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 5,
			})

			-- Etiqueta de estado inferior (Equipada / Elegir)
			local st = state(id)
			local pill = Instance.new("Frame")
			pill.AnchorPoint = Vector2.new(0.5, 1)
			pill.Position = UDim2.new(0.5, 0, 1, -14)
			pill.Size = UDim2.new(0.84, 0, 0, 32)
			pill.BackgroundColor3 = st == "equipped" and C.SuccessDark or C.IronDark
			pill.BorderSizePixel = 0
			pill.ZIndex = 5
			pill.Parent = card
			UiTheme.corner(pill, UiTheme.Radius.SM)
			UiTheme.stroke(pill, st == "equipped" and C.Success or C.Gold, 1.2, 0.15)

			UiTheme.label({
				parent = pill,
				size = UDim2.fromScale(1, 1),
				text = L.t(st),
				font = "Bold",
				textSize = UiTheme.TextSizes.SM,
				color = st == "equipped" and C.GoldBright or C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 6,
			})

			local hit = Instance.new("TextButton")
			hit.Name = "CardHit"
			hit.Size = UDim2.fromScale(1, 1)
			hit.BackgroundTransparency = 1
			hit.Text = ""
			hit.ZIndex = 8
			hit.Parent = card
			UiTheme.bindGamepadFocus(hit, cardStroke, isEquipped and C.GoldBright or C.Gold, 2, 0.15)

			hit.Activated:Connect(function()
				UiTheme.playSound("UI_Click")
				inspect(id)
				if st == "choose" then
					act("SelectInfusion", id)
				end
			end)
		end
	else
		-- Cuadrícula de tarjetas para Armas, Skins y Auras
		local cols = mobile and 2 or 3
		local gap = 10
		local cw = math.floor((listWidth - gap * cols - 8) / cols)
		local ch = 196
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(cw, ch)
		grid.CellPadding = UDim2.fromOffset(gap, gap)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = content

		local ids = tab == "Skins" and Skins.Order
			or (tab == "Weapons" and Weapons.Order or (Auras and Auras.Order or {}))
		local ownedSkinsMap = ownSkins()
		local ownedAurasMap = ownAuras()

		for _, id in ids do
			local s = tab == "Skins" and Skins.Data[id] or nil
			local a = tab == "Auras" and (Auras and Auras.Data and Auras.Data[id]) or nil
			local item = s or a
			local matches = true

			if tab == "Skins" and s then
				matches = (not s.weapon or s.weapon == weapon)
					and (rarity == "all" or s.rarity == rarity)
					and (ownership == "all" or (ownership == "owned" and ownedSkinsMap[id]) or (ownership == "available" and not ownedSkinsMap[id] and not pending(s)))
			elseif tab == "Auras" and a then
				matches = (auraKind == "all" or a.kind == auraKind)
					and (rarity == "all" or a.rarity == rarity)
					and (ownership == "all" or (ownership == "owned" and ownedAurasMap[id]) or (ownership == "available" and not ownedAurasMap[id] and not pending(a)))
			end

			if matches then
				table.insert(shown, id)
				local rSpec = item and UiTheme.Rarities[item.rarity] or nil
				local st = state(id)
				local borderCol = st == "equipped" and C.GoldBright or (rSpec and rSpec.color or C.Gold)

				local card = Instance.new("Frame")
				card.Name = "Card_" .. id
				card.LayoutOrder = #shown
				card.BackgroundColor3 = C.BgCard
				card.BorderSizePixel = 0
				card.Parent = content
				UiTheme.corner(card, UiTheme.Radius.SM)
				local cardStroke = UiTheme.stroke(card, borderCol, rSpec and rSpec.stroke or 1.4, st == "equipped" and 0 or 0.22)

				if rSpec then
					UiTheme.rarityBadge(card, item.rarity, L.t(item.rarity), UDim2.fromOffset(8, 6)).ZIndex = 4
				end

				if tab == "Auras" and a then
					local emblemHolder = Instance.new("Frame")
					emblemHolder.AnchorPoint = Vector2.new(0.5, 0)
					emblemHolder.Position = UDim2.new(0.5, 0, 0, 34)
					emblemHolder.Size = UDim2.fromOffset(76, 76)
					emblemHolder.BackgroundColor3 = C.BgPreview
					emblemHolder.BorderSizePixel = 0
					emblemHolder.Parent = card
					UiTheme.corner(emblemHolder, 38)
					UiTheme.stroke(emblemHolder, a.color or borderCol, 1.6, 0.15)
					local ic = UiAssets.icon(emblemHolder, "aura_" .. (a.pattern or "crown"), 48, a.color or borderCol)
					ic.AnchorPoint = Vector2.new(0.5, 0.5)
					ic.Position = UDim2.fromScale(0.5, 0.5)
				elseif not (s and s.comingSoon) then
					preview(card, tab == "Weapons" and id or (s and s.weapon or weapon), s and id or "Default", { 8, 32, cw - 16, 96 }, false)
				else
					UiTheme.label({
						parent = card,
						position = UDim2.fromOffset(8, 32),
						size = UDim2.fromOffset(cw - 16, 96),
						text = L.t("soon"),
						font = "Header",
						textSize = UiTheme.TextSizes.MD,
						color = C.TextMuted,
						alignX = Enum.TextXAlignment.Center,
					})
				end

				UiTheme.label({
					parent = card,
					position = UDim2.fromOffset(8, 134),
					size = UDim2.fromOffset(cw - 16, 26),
					text = itemName(id),
					font = "Header",
					textSize = UiTheme.TextSizes.MD,
					color = C.TextPrimary,
					truncate = Enum.TextTruncate.AtEnd,
				})

				local subText = (st == "buy" and item) and priceText(item) or L.t(st)
				local subColor = st == "equipped" and C.Success
					or (st == "buy" and item and (C.Coins) or C.TextSecondary)

				UiTheme.label({
					parent = card,
					position = UDim2.fromOffset(8, 162),
					size = UDim2.fromOffset(cw - 16, 22),
					text = subText,
					font = "Bold",
					textSize = UiTheme.TextSizes.SM,
					color = subColor,
				})

				local hit = Instance.new("TextButton")
				hit.Name = "CardHit"
				hit.Size = UDim2.fromScale(1, 1)
				hit.BackgroundTransparency = 1
				hit.Text = ""
				hit.ZIndex = 6
				hit.Parent = card
				UiTheme.bindGamepadFocus(hit, cardStroke, borderCol, rSpec and rSpec.stroke or 1.4, 0.22)

				hit.Activated:Connect(function()
					UiTheme.playSound("UI_Click")
					inspect(id)
					detail.GroupTransparency = 0.25
					TweenService:Create(detail, UiTheme.Anim.TweenFast, { GroupTransparency = 0 }):Play()
				end)
				hit.SelectionGained:Connect(function()
					content.CanvasPosition = Vector2.new(0, math.max(0, card.AbsolutePosition.Y - content.AbsolutePosition.Y + content.CanvasPosition.Y - 20))
				end)
			end
		end
	end

	if not table.find(shown, selected) then
		selected = shown[1]
	end
	if selected then
		inspect(selected)
	else
		UiTheme.label({
			parent = detail,
			position = UDim2.fromOffset(20, 20),
			size = UDim2.new(1, -40, 0, 60),
			text = L.t("empty"),
			font = "Body",
			textSize = UiTheme.TextSizes.MD,
			color = C.TextMuted,
			alignX = Enum.TextXAlignment.Center,
		})
	end

	-- Barra inferior de estado y ayuda de mando
	messageLabel = UiTheme.label({
		name = "StatusMessage",
		parent = panel,
		position = UDim2.fromOffset(22, height - 36),
		size = UDim2.fromOffset(width - 280, 26),
		text = "",
		font = "Bold",
		textSize = UiTheme.TextSizes.SM,
		color = C.GoldBright,
	})

	UiTheme.label({
		parent = panel,
		position = UDim2.fromOffset(width - 250, height - 36),
		size = UDim2.fromOffset(228, 26),
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
-- Apertura / cierre y bucle de rotación de vistas previas
----------------------------------------------------------------------
function setOpen(value)
	if opened == value then return end
	opened = value
	transition += 1
	local version = transition
	player:SetAttribute("ShopOpen", value)
	if value then
		player:SetAttribute("SettingsOpen", false)
	end
	player:SetAttribute("MenuOpen", value or player:GetAttribute("SettingsOpen") == true)
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

toggleBtn.Activated:Connect(function()
	setOpen(not opened)
end)

player:GetAttributeChangedSignal("SettingsOpen"):Connect(function()
	if player:GetAttribute("SettingsOpen") then
		setOpen(false)
	end
end)

task.spawn(function()
	player:WaitForChild("ToggleMenu").Event:Connect(function()
		setOpen(not opened)
	end)
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

-- Escape y ButtonB del mando cierran primero el modal de confirmación, o la tienda si no hay modal
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

RunService.RenderStepped:Connect(function(dt)
	if not opened then return end


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
		local opt = player:GetAttribute("OptUiScale") or 1
		topBtnScale.Scale = opt
		if opened and not busy then
			render()
		end
	end)
end

L.Changed:Connect(function()
	toggleBtn.Text = L.t("armory")
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
	local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
	coins.Changed:Connect(function()
		if opened and not busy and not modal then
			render()
		end
	end)
end)
