-- LocalScript: StarterPlayer/StarterPlayerScripts/Rewards
-- Interfaz completa de «Recompensas y retención 0.2» (Contrato C19, D5, D10, D15, responsable: Gemini).
-- Incluye:
--   1. Modal de Bienvenida (máx. 2 pantallas) y elección de primera skin común gratis (Charcoal, Frost, Gold).
--   2. Ruleta del Ocaso de 8 sectores con animación de desaceleración decidida por el servidor,
--      contador de garantía de 30 giros, vista 3D del gran premio semanal y modal "i Probabilidades".
--   3. Cajas de Suerte (Caja de Almas 500 y Caja de Reliquias 1500) con garantía de 10 cajas,
--      conversión de duplicados a Almas (40 %) y animación de sacudida + estallido de luz + premio 3D.
--   4. Racha diaria de 7 días (con pausa sin reinicio), aviso de «Bienvenido de vuelta»,
--      cadena de 7 misiones «Primeros pasos» (skin épica garantizada) y misión semanal.
--   5. Álbum de Colección por arma (% completado -> Aura exclusiva al 100 %) y Maestría por arma (Nvl. 1..20).
--   6. Degradación elegante si Remotes.Rewards aún no está listo y sincronización de avisos rojos ("!").

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local UiTheme = require(RS:WaitForChild("UiTheme", 10))
local UiAssets = require(RS:WaitForChild("UiAssets", 10))
local L = require(RS:WaitForChild("Localization", 10))
local Skins = require(RS:WaitForChild("Skins", 10))
local Weapons = require(RS:WaitForChild("WeaponData", 10))
local Builder = require(RS:WaitForChild("WeaponBuilder", 10))

local RewardsConfig = nil
do
	local mod = RS:FindFirstChild("Rewards")
	if mod then
		local ok, r = pcall(require, mod)
		if ok and type(r) == "table" then RewardsConfig = r end
	end
end

local ProgressionConfig = nil
do
	local mod = RS:FindFirstChild("Progression")
	if mod then
		local ok, p = pcall(require, mod)
		if ok and type(p) == "table" then ProgressionConfig = p end
	end
end

local C = UiTheme.Colors
local remotes = RS:WaitForChild("Remotes", 10)

----------------------------------------------------------------------
-- BindableEvent para abrir/cerrar desde LobbyUI o el altar de la ciudad
----------------------------------------------------------------------
local toggleRewardsBindable = player:FindFirstChild("ToggleRewards")
if not toggleRewardsBindable then
	toggleRewardsBindable = Instance.new("BindableEvent")
	toggleRewardsBindable.Name = "ToggleRewards"
	toggleRewardsBindable.Parent = player
end

local gui = Instance.new("ScreenGui")
gui.Name = "RewardsGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 13
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

local BASE_W, BASE_H = 1040, 640
local panel = UiTheme.panel({
	name = "RewardsWindow",
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
-- Estado local y respaldo seguro (nunca lanza error si el servidor aún carga)
----------------------------------------------------------------------
local tab = "Roulette" -- "Roulette" | "Boxes" | "Streak" | "Collection"
local selectedWeapon = player:GetAttribute("WeaponId") or "Sword"
local opened = false
local busy = false
local spinning = false
local currentWheelAngle = 0
local spins3D = {}
local state = nil
local statusLabel = nil
local subModal = nil

local render
local setOpen
local showPrizeCelebration
local showOddsModal
local checkWelcomeModal

local DEFAULT_SECTORS = {
	{ kind = "Souls", amount = 75, probability = 0.30, rarity = "Common" },
	{ kind = "Souls", amount = 200, probability = 0.25, rarity = "Common" },
	{ kind = "Souls", amount = 600, probability = 0.15, rarity = "Rare" },
	{ kind = "XP", amount = 150, probability = 0.12, rarity = "Common" },
	{ kind = "Boost", stat = "XP", boost = "XP", multiplier = 1.5, seconds = 900, probability = 0.08, rarity = "Rare" },
	{ kind = "Boost", stat = "Coins", boost = "Coins", multiplier = 2, seconds = 1800, probability = 0.05, rarity = "Epic" },
	{ kind = "Box", id = "Relic", amount = 1, probability = 0.04, rarity = "Epic" },
	{ kind = "WeeklySkin", id = "CrimsonEclipse", probability = 0.01, rarity = "Legendary" },
}

local DEFAULT_FIRST_STEPS = {
	{ id = "Match", progress = 0, goal = 3 },
	{ id = "Win", progress = 0, goal = 1 },
	{ id = "Parry", progress = 0, goal = 5 },
	{ id = "Equip", progress = 0, goal = 1 },
	{ id = "Spin", progress = 0, goal = 1 },
	{ id = "OpenBox", progress = 0, goal = 1 },
	{ id = "Level", progress = 1, goal = 5 },
}

local function parseCsv(raw)
	local map = {}
	for token in string.gmatch(raw or "", "[^,]+") do
		map[token] = true
	end
	return map
end

local function buildFallbackState()
	local ls = player:FindFirstChild("leaderstats")
	local coinsObj = ls and ls:FindFirstChild("Coins")
	local ownedMap = parseCsv(player:GetAttribute("OwnedSkins"))
	ownedMap.Default = true

	local coll = {}
	local mastery = {}
	local aurasByW = (RewardsConfig and (RewardsConfig.Collection or RewardsConfig.CollectionAuras)) or {
		Sword = "AshCrown",
		Greatsword = "SmokeWings",
		Dagger = "FootShroud",
		Rapier = "GraveRunes",
		Mace = "SpectralChains",
	}

	for _, wid in Weapons.Order do
		local tot, own, skList = 0, 0, {}
		for sid, s in Skins.Data do
			if sid ~= "Default" and not s.comingSoon and (not s.weapon or s.weapon == wid) then
				tot += 1
				local has = ownedMap[sid] == true
				if has then own += 1 end
				table.insert(skList, { id = sid, owned = has })
			end
		end
		table.sort(skList, function(a, b) return a.id < b.id end)
		coll[wid] = {
			owned = own,
			total = tot,
			percent = tot > 0 and (own / tot) or 0,
			aura = aurasByW[wid] or "AshCrown",
			claimed = tot > 0 and own == tot,
			skins = skList,
		}
		mastery[wid] = {
			level = 1,
			xp = 0,
			xpNext = (ProgressionConfig and ProgressionConfig.Mastery and ProgressionConfig.Mastery.XPPerLevel) or 200,
			finish = (ProgressionConfig and ProgressionConfig.Mastery and ProgressionConfig.Mastery.Finishes and ProgressionConfig.Mastery.Finishes[wid]) or "Charcoal",
			trail = (ProgressionConfig and ProgressionConfig.Mastery and ProgressionConfig.Mastery.Trails and ProgressionConfig.Mastery.Trails[wid]) or "WeepingBlade",
		}
	end

	return {
		souls = coinsObj and coinsObj.Value or 0,
		resetAt = os.time() + 3600 * 8,
		weekResetAt = os.time() + 86400 * 4,
		weeklySkin = "CrimsonEclipse",
		roulette = DEFAULT_SECTORS,
		spinPity = 0,
		spinGuarantee = (RewardsConfig and (RewardsConfig.RoulettePity or RewardsConfig.SpinGuarantee)) or 30,
		freeSpin = true,
		spins = 0,
		paidSpins = 0,
		paidSpinPrice = 250,
		relicPity = 0,
		relicGuarantee = (RewardsConfig and (RewardsConfig.RelicPity or RewardsConfig.RelicGuarantee)) or 10,
		boxes = {
			Souls = { count = 0, price = 500 },
			Relic = { count = 0, price = 1500 },
		},
		streak = {
			day = 0,
			canClaim = true,
			rewards = { 50, 75, 100, 125, 150, 200, "Relic" },
			paused = false,
		},
		weekly = { event = "Win", nameKey = "cx.mission.wins", goal = 15, progress = 0, claimed = false },
		starter = { chosen = true, choices = { "Charcoal", "Frost", "Gold" } },
		tutorial = { spinAvailable = false },
		firstSteps = { list = DEFAULT_FIRST_STEPS, canClaim = false, claimed = false, skin = "Relic06" },
		returnNotice = false,
		collection = coll,
		mastery = mastery,
		notifications = { spin = true, streak = true, weekly = false, firstSteps = false },
	}
end

local function updateAlertsFromState()
	if not state then return end
	local n = state.notifications or {}
	local hasAlert = (n.spin == true) or (n.streak == true) or (n.weekly == true) or (n.firstSteps == true)
	player:SetAttribute("RewardsAlert", hasAlert)
end

local function getRewardsRemote()
	if not remotes then remotes = RS:FindFirstChild("Remotes") end
	return remotes and remotes:FindFirstChild("Rewards")
end

local function invokeRewards(action, id, source, callback)
	local rf = getRewardsRemote()
	if not rf or not rf:IsA("RemoteFunction") then
		if action == "GetState" then
			state = state or buildFallbackState()
			updateAlertsFromState()
			if callback then callback(true, state) end
		elseif callback then
			callback(false, { key = "loading" })
		end
		return
	end

	task.spawn(function()
		local callOk, r1, r2 = pcall(function()
			return rf:InvokeServer(action, id, source)
		end)
		if not callOk then
			if action == "GetState" and not state then
				state = buildFallbackState()
				updateAlertsFromState()
			end
			if callback then callback(false, { key = "error" }) end
			return
		end

		local success, payload
		if type(r1) == "boolean" then
			success = r1
			payload = r2
		elseif type(r1) == "table" then
			success = true
			payload = r1
		else
			success = r1 ~= nil
			payload = r2 or r1
		end

		if action == "GetState" and success and type(payload) == "table" then
			state = payload
			updateAlertsFromState()
			checkWelcomeModal()
		end
		if callback then
			callback(success, payload)
		end
	end)
end

local function refreshState(andRender)
	invokeRewards("GetState", nil, nil, function()
		if andRender and opened and not spinning then
			render()
		end
	end)
end

----------------------------------------------------------------------
-- Helpers visuales y vistas 3D
----------------------------------------------------------------------
local function formatTimeLeft(targetUnix)
	local rem = math.max(0, (tonumber(targetUnix) or 0) - os.time())
	local h = math.floor(rem / 3600)
	local m = math.floor((rem % 3600) / 60)
	local s = rem % 60
	return ("%02d:%02d:%02d"):format(h, m, s)
end

local function setStatus(text, isError)
	if not statusLabel or not statusLabel.Parent then return end
	statusLabel.Text = text or ""
	statusLabel.TextColor3 = isError and C.Danger or C.GoldBright
end

local function makeWeaponPreview3D(parent, wid, sid, rect, large)
	local vp = Instance.new("ViewportFrame")
	vp.Position = UDim2.fromOffset(rect[1], rect[2])
	vp.Size = UDim2.fromOffset(rect[3], rect[4])
	vp.BackgroundColor3 = C.BgPreview
	vp.BackgroundTransparency = large and 0.08 or 0.16
	vp.BorderSizePixel = 0
	vp.Ambient = Color3.fromRGB(170, 168, 184)
	vp.LightColor = Color3.fromRGB(255, 240, 214)
	vp.LightDirection = Vector3.new(-1, -1, -1)
	vp.Parent = parent
	UiTheme.corner(vp, UiTheme.Radius.SM)

	local world = Instance.new("WorldModel")
	world.Parent = vp
	local camera = Instance.new("Camera")
	camera.FieldOfView = 28
	camera.Parent = vp
	vp.CurrentCamera = camera

	local ok, model = pcall(Builder.buildModel, wid or "Sword", sid or "Default")
	if ok and model then
		model.Parent = world
		local cfBox, size = model:GetBoundingBox()
		local center = model.PrimaryPart and (model.PrimaryPart.CFrame:Inverse() * cfBox.Position) or Vector3.zero
		local base = CFrame.Angles(0, math.pi / 2, math.rad(26)) * CFrame.new(-center)
		local dist = math.max(size.X, size.Y, size.Z) * 0.88
		model:PivotTo(base)
		camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, dist), Vector3.zero)
		table.insert(spins3D, {
			vp = vp,
			model = model,
			camera = camera,
			base = base,
			distance = dist,
			phase = #spins3D * 0.5,
		})
	end
	return vp
end

local function formatSectorLabel(sec)
	if not sec then return "?" end
	local k = sec.kind
	if k == "Souls" then
		return L.t("ui.rewards.sectorSouls", { amount = sec.amount or 75 })
	elseif k == "XP" then
		return L.t("ui.rewards.sectorXp", { amount = sec.amount or 150 })
	elseif k == "Boost" then
		local st = sec.stat or sec.boost
		if st == "XP" then
			return L.t("ui.rewards.sectorBoostXp", { mult = sec.multiplier or 1.5 })
		else
			return L.t("ui.rewards.sectorBoostSouls", { mult = sec.multiplier or 2 })
		end
	elseif k == "Box" then
		return L.t("ui.rewards.sectorBoxRelic")
	elseif k == "WeeklySkin" or k == "Weekly" or k == "Skin" then
		return L.t("ui.rewards.sectorWeekly")
	end
	return tostring(k or "?")
end

local function sectorColor(sec, idx)
	local k = sec and sec.kind
	if k == "WeeklySkin" or k == "Weekly" or k == "Skin" then
		return Color3.fromRGB(165, 28, 42)
	elseif k == "Box" then
		return Color3.fromRGB(112, 46, 168)
	elseif k == "Boost" then
		return Color3.fromRGB(36, 98, 160)
	elseif k == "XP" then
		return Color3.fromRGB(38, 118, 82)
	end
	return (idx % 2 == 0) and Color3.fromRGB(44, 38, 30) or Color3.fromRGB(30, 28, 36)
end

----------------------------------------------------------------------
-- Modal de Celebración de Premio (Ruleta, Cajas y Primeros Pasos)
----------------------------------------------------------------------
local function closeSubModal()
	if subModal then
		subModal:Destroy()
		subModal = nil
	end
end

function showPrizeCelebration(reward, isBoxOpen)
	closeSubModal()
	if type(reward) ~= "table" then return end

	local modalVeil = Instance.new("TextButton")
	modalVeil.Name = "PrizeModalVeil"
	modalVeil.Size = UDim2.fromScale(1, 1)
	modalVeil.BackgroundColor3 = C.BgAbyss
	modalVeil.BackgroundTransparency = 0.2
	modalVeil.Text = ""
	modalVeil.AutoButtonColor = false
	modalVeil.ZIndex = 30
	modalVeil.Parent = panel
	subModal = modalVeil

	local rName = reward.rarity or (reward.kind == "Skin" and Skins.Data[reward.id] and Skins.Data[reward.id].rarity) or "Rare"
	if reward.kind == "Souls" and (reward.amount or 0) >= 600 then rName = "Epic" end
	local rSpec = UiTheme.Rarities[rName] or UiTheme.Rarities.Rare
	local accentColor = rSpec and rSpec.color or C.GoldBright

	-- Destello de pantalla completa en premios Épicos o Legendarios
	if rName == "Legendary" or rName == "Epic" then
		local burst = Instance.new("Frame")
		burst.Size = UDim2.fromScale(1, 1)
		burst.BackgroundColor3 = accentColor
		burst.BackgroundTransparency = 0.15
		burst.BorderSizePixel = 0
		burst.ZIndex = 40
		burst.Parent = modalVeil
		TweenService:Create(burst, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.7, function()
			if burst.Parent then burst:Destroy() end
		end)
	end

	local box = UiTheme.panel({
		name = "PrizeBox",
		parent = modalVeil,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromOffset(480, 390),
		bg = C.BgPrimary,
		borderColor = accentColor,
		borderThickness = UiTheme.Stroke.Heavy,
		ornaments = true,
		ornamentSize = 16,
		zIndex = 32,
	})

	local function populateRewardContent()
		for _, ch in box:GetChildren() do
			if not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
				ch:Destroy()
			end
		end

		UiTheme.playSound("UI_PurchaseOK")

		UiTheme.label({
			parent = box,
			position = UDim2.fromOffset(20, 16),
			size = UDim2.new(1, -40, 0, 30),
			text = L.t("ui.rewards.prizeWon"),
			font = "Title",
			textSize = UiTheme.TextSizes.XXL,
			color = accentColor,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 34,
		})

		if rSpec then
			local bdg = UiTheme.rarityBadge(box, rName, L.t(rName), UDim2.new(0.5, -52, 0, 50))
			bdg.ZIndex = 34
		end

		local titleText = ""
		local subText = ""
		local skinId = (reward.kind == "Skin" and reward.id) or reward.duplicate
		if skinId and Skins.Data[skinId] then
			local sData = Skins.Data[skinId]
			local vp = makeWeaponPreview3D(box, sData.weapon or "Sword", skinId, { 90, 82, 300, 165 }, true)
			vp.ZIndex = 34
			titleText = L.t("skin." .. skinId)
			if reward.duplicate then
				subText = L.t("ui.rewards.duplicateConverted", {
					skin = L.t("skin." .. reward.duplicate),
					amount = reward.amount or 0,
				})
			else
				subText = L.t("skinDesc." .. skinId)
			end
		else
			local emblem = Instance.new("Frame")
			emblem.AnchorPoint = Vector2.new(0.5, 0)
			emblem.Position = UDim2.new(0.5, 0, 0, 92)
			emblem.Size = UDim2.fromOffset(124, 124)
			emblem.BackgroundColor3 = C.BgPreview
			emblem.BorderSizePixel = 0
			emblem.ZIndex = 34
			emblem.Parent = box
			UiTheme.corner(emblem, 62)
			UiTheme.stroke(emblem, accentColor, 2.2, 0.1)

			local iconName = reward.kind == "Box" and "trophy" or (reward.kind == "XP" and "mission" or "coin")
			local ic = UiAssets.icon(emblem, iconName, 64, accentColor)
			ic.AnchorPoint = Vector2.new(0.5, 0.5)
			ic.Position = UDim2.fromScale(0.5, 0.5)
			ic.ZIndex = 35

			titleText = formatSectorLabel(reward)
			subText = L.t("acquired")
		end

		UiTheme.label({
			parent = box,
			position = UDim2.fromOffset(24, 256),
			size = UDim2.new(1, -48, 0, 28),
			text = titleText,
			font = "Title",
			textSize = UiTheme.TextSizes.XL,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 34,
		})

		UiTheme.label({
			parent = box,
			position = UDim2.fromOffset(28, 284),
			size = UDim2.new(1, -56, 0, 38),
			text = subText,
			font = "Body",
			textSize = UiTheme.TextSizes.xs or UiTheme.TextSizes.XS,
			color = reward.duplicate and C.Coins or C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
			zIndex = 34,
		})

		local okBtn = UiTheme.button({
			parent = box,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -16),
			size = UDim2.fromOffset(190, 42),
			text = L.t("ui.match.continue"),
			variant = "gold",
			zIndex = 35,
			onClick = function()
				closeSubModal()
				refreshState(true)
			end,
		})
		if UIS.GamepadEnabled then
			GuiService.SelectedObject = okBtn
		end
	end

	if isBoxOpen then
		-- Animación de cofre temblando + estallido de luz antes de revelar el premio
		local chestFrame = Instance.new("Frame")
		chestFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		chestFrame.Position = UDim2.fromScale(0.5, 0.46)
		chestFrame.Size = UDim2.fromOffset(136, 136)
		chestFrame.BackgroundColor3 = C.BgCard
		chestFrame.BorderSizePixel = 0
		chestFrame.ZIndex = 34
		chestFrame.Parent = box
		UiTheme.corner(chestFrame, 24)
		UiTheme.stroke(chestFrame, accentColor, 2.6, 0.05)

		local chestIc = UiAssets.icon(chestFrame, "trophy", 72, accentColor)
		chestIc.AnchorPoint = Vector2.new(0.5, 0.5)
		chestIc.Position = UDim2.fromScale(0.5, 0.5)
		chestIc.ZIndex = 35

		task.spawn(function()
			for step = 1, 10 do
				if not chestFrame.Parent then return end
				UiTheme.playSound("UI_Hover")
				chestFrame.Rotation = (step % 2 == 0 and 1 or -1) * (4 + step * 1.1)
				chestFrame.Size = UDim2.fromOffset(136 + step * 2, 136 + step * 2)
				task.wait(0.065)
			end
			if box.Parent then
				populateRewardContent()
			end
		end)
	else
		populateRewardContent()
	end
end

----------------------------------------------------------------------
-- Modal "i Probabilidades" (transparencia total de Ruleta y Cajas)
----------------------------------------------------------------------
function showOddsModal()
	closeSubModal()
	local modalVeil = Instance.new("TextButton")
	modalVeil.Name = "OddsModalVeil"
	modalVeil.Size = UDim2.fromScale(1, 1)
	modalVeil.BackgroundColor3 = C.BgAbyss
	modalVeil.BackgroundTransparency = 0.24
	modalVeil.Text = ""
	modalVeil.AutoButtonColor = false
	modalVeil.ZIndex = 30
	modalVeil.Parent = panel
	subModal = modalVeil

	local box = UiTheme.panel({
		name = "OddsBox",
		parent = modalVeil,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromOffset(620, 440),
		bg = C.BgPrimary,
		borderColor = C.Gold,
		borderThickness = UiTheme.Stroke.Heavy,
		ornaments = true,
		zIndex = 32,
	})

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(22, 14),
		size = UDim2.new(1, -140, 0, 32),
		text = L.t("ui.rewards.oddsTitle"),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
		zIndex = 33,
	})

	local closeBtn = UiTheme.button({
		parent = box,
		anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -16, 0, 12),
		size = UDim2.fromOffset(100, 36),
		text = L.t("close"),
		zIndex = 34,
		onClick = closeSubModal,
	})

	local sectors = (state and state.roulette) or DEFAULT_SECTORS
	for i, sec in sectors do
		local row = UiTheme.panel({
			parent = box,
			position = UDim2.fromOffset(22 + ((i - 1) % 2) * 292, 58 + math.floor((i - 1) / 2) * 44),
			size = UDim2.fromOffset(284, 38),
			bg = C.BgCard,
			borderColor = C.BorderSubtle,
			zIndex = 33,
		})
		UiTheme.label({
			parent = row,
			position = UDim2.fromOffset(12, 0),
			size = UDim2.new(0.68, -12, 1, 0),
			text = formatSectorLabel(sec),
			font = "Bold",
			textSize = UiTheme.TextSizes.SM,
			color = C.TextPrimary,
			zIndex = 34,
		})
		local pct = (tonumber(sec.probability) or 0) * 100
		UiTheme.label({
			parent = row,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -12, 0, 0),
			size = UDim2.new(0.32, -12, 1, 0),
			text = string.format("%.0f%%", pct),
			font = "Number",
			textSize = UiTheme.TextSizes.SM,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Right,
			zIndex = 34,
		})
	end

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(24, 246),
		size = UDim2.new(1, -48, 0, 48),
		text = L.t("ui.rewards.boxRelicDesc"),
		font = "Body",
		textSize = UiTheme.TextSizes.SM,
		color = C.TextPrimary,
		zIndex = 33,
	})

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(24, 302),
		size = UDim2.new(1, -48, 0, 48),
		text = L.t("ui.rewards.duplicateRule"),
		font = "Body",
		textSize = UiTheme.TextSizes.SM,
		color = C.Coins,
		zIndex = 33,
	})

	UiTheme.label({
		parent = box,
		position = UDim2.fromOffset(24, 362),
		size = UDim2.new(1, -48, 0, 28),
		text = L.t("ui.rewards.pity", {
			cur = (state and state.spinPity) or 0,
			max = (state and state.spinGuarantee) or 30,
		}) .. "  ·  " .. L.t("ui.rewards.relicPity", {
			cur = (state and state.relicPity) or 0,
			max = (state and state.relicGuarantee) or 10,
		}),
		font = "Bold",
		textSize = UiTheme.TextSizes.SM,
		color = C.GoldBright,
		alignX = Enum.TextXAlignment.Center,
		zIndex = 33,
	})

	if UIS.GamepadEnabled then
		GuiService.SelectedObject = closeBtn
	end
end

----------------------------------------------------------------------
-- Bienvenida corta (máx. 2 pantallas) y elección de primera skin común
----------------------------------------------------------------------
local welcomeVeil = nil
local welcomeStep = 1

function checkWelcomeModal()
	if not state or type(state.starter) ~= "table" then return end
	if state.starter.chosen ~= false then
		if welcomeVeil then
			welcomeVeil:Destroy()
			welcomeVeil = nil
		end
		return
	end
	if player:GetAttribute("InMatch") == true or welcomeVeil then return end

	welcomeVeil = Instance.new("Frame")
	welcomeVeil.Name = "WelcomeStarterVeil"
	welcomeVeil.Size = UDim2.fromScale(1, 1)
	welcomeVeil.BackgroundColor3 = C.BgModalVeil
	welcomeVeil.BackgroundTransparency = 0.18
	welcomeVeil.BorderSizePixel = 0
	welcomeVeil.ZIndex = 50
	welcomeVeil.Parent = gui

	local wBox = UiTheme.panel({
		name = "WelcomeBox",
		parent = welcomeVeil,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromOffset(720, 440),
		bg = C.BgPrimary,
		borderColor = C.GoldBright,
		borderThickness = UiTheme.Stroke.Heavy,
		ornaments = true,
		ornamentSize = 18,
		zIndex = 51,
	})
	local wScale = Instance.new("UIScale")
	wScale.Parent = wBox
	if workspace.CurrentCamera then
		wScale.Scale = UiTheme.computeScale(workspace.CurrentCamera.ViewportSize, 760, 480, player)
	end

	local function renderWelcomeStep()
		for _, ch in wBox:GetChildren() do
			if ch ~= wScale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
				ch:Destroy()
			end
		end

		if welcomeStep == 1 then
			local crest = UiAssets.icon(wBox, "armory", 74, C.GoldBright)
			crest.AnchorPoint = Vector2.new(0.5, 0)
			crest.Position = UDim2.new(0.5, 0, 0, 36)
			crest.ZIndex = 52

			UiTheme.label({
				parent = wBox,
				position = UDim2.fromOffset(32, 128),
				size = UDim2.new(1, -64, 0, 40),
				text = L.t("ui.welcome.step1Title"),
				font = "Title",
				textSize = UiTheme.TextSizes.Hero,
				color = C.GoldBright,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 52,
			})

			UiTheme.label({
				parent = wBox,
				position = UDim2.fromOffset(56, 182),
				size = UDim2.new(1, -112, 0, 110),
				text = L.t("ui.welcome.step1Body"),
				font = "Body",
				textSize = UiTheme.TextSizes.LG,
				color = C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 52,
			})

			local nextBtn = UiTheme.button({
				parent = wBox,
				anchor = Vector2.new(0.5, 1),
				position = UDim2.new(0.5, 0, 1, -36),
				size = UDim2.fromOffset(290, 48),
				text = L.t("ui.welcome.next"),
				font = "Header",
				textSize = UiTheme.TextSizes.LG,
				variant = "gold",
				zIndex = 53,
				onClick = function()
					welcomeStep = 2
					renderWelcomeStep()
				end,
			})
			if UIS.GamepadEnabled then GuiService.SelectedObject = nextBtn end
		else
			UiTheme.label({
				parent = wBox,
				position = UDim2.fromOffset(24, 18),
				size = UDim2.new(1, -48, 0, 34),
				text = L.t("ui.welcome.step2Title"),
				font = "Title",
				textSize = UiTheme.TextSizes.XXL,
				color = C.GoldBright,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 52,
			})
			UiTheme.label({
				parent = wBox,
				position = UDim2.fromOffset(24, 52),
				size = UDim2.new(1, -48, 0, 22),
				text = L.t("ui.welcome.step2Sub"),
				font = "Body",
				textSize = UiTheme.TextSizes.SM,
				color = C.TextSecondary,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 52,
			})

			local choices = (state.starter and state.starter.choices) or { "Charcoal", "Frost", "Gold" }
			local cardW = 206
			for idx, skinId in choices do
				local cFrame = UiTheme.panel({
					parent = wBox,
					position = UDim2.fromOffset(34 + (idx - 1) * (cardW + 16), 88),
					size = UDim2.fromOffset(cardW, 316),
					bg = C.BgCard,
					borderColor = C.Gold,
					zIndex = 52,
				})
				local vp = makeWeaponPreview3D(cFrame, "Sword", skinId, { 12, 14, cardW - 24, 150 }, false)
				vp.ZIndex = 53

				UiTheme.label({
					parent = cFrame,
					position = UDim2.fromOffset(10, 174),
					size = UDim2.new(1, -20, 0, 26),
					text = L.t("skin." .. skinId),
					font = "Title",
					textSize = UiTheme.TextSizes.LG,
					color = C.GoldBright,
					alignX = Enum.TextXAlignment.Center,
					zIndex = 53,
				})

				UiTheme.label({
					parent = cFrame,
					position = UDim2.fromOffset(10, 202),
					size = UDim2.new(1, -20, 0, 48),
					text = L.t("skinDesc." .. skinId),
					font = "Body",
					textSize = UiTheme.TextSizes.XS,
					color = C.TextSecondary,
					alignX = Enum.TextXAlignment.Center,
					zIndex = 53,
				})

				local pickBtn = UiTheme.button({
					parent = cFrame,
					anchor = Vector2.new(0.5, 1),
					position = UDim2.new(0.5, 0, 1, -14),
					size = UDim2.fromOffset(cardW - 24, 40),
					text = L.t("ui.welcome.claimStarter"),
					variant = "gold",
					textSize = UiTheme.TextSizes.SM,
					zIndex = 54,
					onClick = function()
						invokeRewards("ChooseStarter", skinId, nil, function(ok)
							if ok then
								local shopRF = remotes and remotes:FindFirstChild("Shop")
								if shopRF and shopRF:IsA("RemoteFunction") then
									pcall(function() shopRF:InvokeServer("Equip", skinId) end)
								end
								if welcomeVeil then
									welcomeVeil:Destroy()
									welcomeVeil = nil
								end
								refreshState(true)
							end
						end)
					end,
				})
				if idx == 1 and UIS.GamepadEnabled then
					GuiService.SelectedObject = pickBtn
				end
			end
		end
	end

	renderWelcomeStep()
end

----------------------------------------------------------------------
-- Renderizado de las 4 pestañas principales de Recompensas
----------------------------------------------------------------------
function render()
	table.clear(spins3D)
	closeSubModal()
	if not state then
		state = buildFallbackState()
	end

	for _, ch in panel:GetChildren() do
		if ch ~= scale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
			ch:Destroy()
		end
	end

	local cam = workspace.CurrentCamera
	local viewport = cam and cam.ViewportSize or Vector2.new(BASE_W, BASE_H)
	local mobile = viewport.X < 780
	local width = mobile and 720 or BASE_W
	local height = mobile and 620 or BASE_H
	panel.Size = UDim2.fromOffset(width, height)
	scale.Scale = UiTheme.computeScale(viewport, width, height, player)

	-- Cabecera
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = panel
	UiTheme.corner(header, UiTheme.Radius.MD)

	local crest = UiAssets.icon(header, "trophy", 26, C.GoldBright)
	crest.AnchorPoint = Vector2.new(0, 0.5)
	crest.Position = UDim2.new(0, 18, 0.5, 0)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 6),
		size = UDim2.fromOffset(420, 28),
		text = L.t("ui.rewards.title"),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
	})
	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 32),
		size = UDim2.fromOffset(460, 18),
		text = L.t("ui.rewards.subtitle"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
	})

	-- Contador de Almas en cabecera
	local ls = player:FindFirstChild("leaderstats")
	local coinsVal = ls and ls:FindFirstChild("Coins")
	local soulsAmount = (coinsVal and coinsVal.Value) or state.souls or 0

	local soulPill = Instance.new("Frame")
	soulPill.AnchorPoint = Vector2.new(1, 0.5)
	soulPill.Position = UDim2.new(1, -132, 0.5, 0)
	soulPill.Size = UDim2.fromOffset(172, 36)
	soulPill.BackgroundColor3 = C.BgAbyss
	soulPill.BorderSizePixel = 0
	soulPill.Parent = header
	UiTheme.corner(soulPill, UiTheme.Radius.Pill)
	UiTheme.stroke(soulPill, C.GoldDim, 1, 0.25)

	local soulIc = UiAssets.icon(soulPill, "coin", 20, C.Coins)
	soulIc.AnchorPoint = Vector2.new(0, 0.5)
	soulIc.Position = UDim2.new(0, 10, 0.5, 0)

	UiTheme.label({
		parent = soulPill,
		position = UDim2.fromOffset(34, 0),
		size = UDim2.new(1, -42, 1, 0),
		text = L.t("ui.souls", { amount = soulsAmount }),
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
		size = UDim2.fromOffset(104, 38),
		text = L.t("close"),
		variant = "secondary",
		onClick = function()
			if not spinning then setOpen(false) end
		end,
	})

	-- Barra de 4 pestañas con avisos rojos ("!")
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

	local notif = state.notifications or {}
	local tabDefs = {
		{ id = "Roulette",   label = L.t("ui.rewards.tab.Roulette"),   alert = notif.spin == true },
		{ id = "Boxes",      label = L.t("ui.rewards.tab.Boxes"),      alert = ((state.boxes and state.boxes.Souls and state.boxes.Souls.count or 0) + (state.boxes and state.boxes.Relic and state.boxes.Relic.count or 0)) > 0 },
		{ id = "Streak",     label = L.t("ui.rewards.tab.Streak"),     alert = (notif.streak == true) or (notif.firstSteps == true) or (notif.weekly == true) },
		{ id = "Collection", label = L.t("ui.rewards.tab.Collection"), alert = false },
	}
	local firstTabBtn = nil
	for i, def in tabDefs do
		local b = UiTheme.tabButton({
			name = "Tab_" .. def.id,
			parent = tabsBar,
			layoutOrder = i,
			size = UDim2.fromOffset(mobile and 164 or 210, 42),
			text = def.label,
			active = tab == def.id,
			onClick = function()
				if spinning then return end
				tab = def.id
				render()
			end,
		})
		if def.alert then
			local dot = Instance.new("Frame")
			dot.AnchorPoint = Vector2.new(1, 0)
			dot.Position = UDim2.new(1, -6, 0, 4)
			dot.Size = UDim2.fromOffset(16, 16)
			dot.BackgroundColor3 = C.Danger
			dot.BorderSizePixel = 0
			dot.ZIndex = b.ZIndex + 3
			dot.Parent = b
			UiTheme.corner(dot, 8)
			UiTheme.label({
				parent = dot,
				size = UDim2.fromScale(1, 1),
				text = "!",
				font = "Bold",
				textSize = 11,
				color = C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
				zIndex = dot.ZIndex + 1,
			})
		end
		if i == 1 then firstTabBtn = b end
	end

	local bodyY = 116
	local bodyH = height - bodyY - 40
	local body = Instance.new("Frame")
	body.Name = "TabBody"
	body.Position = UDim2.fromOffset(20, bodyY)
	body.Size = UDim2.fromOffset(width - 40, bodyH)
	body.BackgroundTransparency = 1
	body.Parent = panel

	------------------------------------------------------------------
	-- PESTAÑA 1: RULETA DEL OCASO (8 sectores)
	------------------------------------------------------------------
	if tab == "Roulette" then
		local leftW = math.floor((width - 54) * 0.56)
		local rightW = (width - 40) - leftW - 14

		local wheelPanel = UiTheme.panel({
			name = "WheelPanel",
			parent = body,
			size = UDim2.fromOffset(leftW, bodyH),
			bg = C.BgPanel,
			borderColor = C.Gold,
			ornaments = true,
		})

		-- Botón "i Probabilidades" arriba a la derecha del panel de la ruleta
		UiTheme.button({
			name = "OddsInfoBtn",
			parent = wheelPanel,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -14, 0, 12),
			size = UDim2.fromOffset(154, 32),
			text = L.t("ui.rewards.oddsBtn"),
			variant = "secondary",
			textSize = UiTheme.TextSizes.XS,
			onClick = showOddsModal,
		})

		-- Rueda circular de 8 sectores
		local wheelDia = math.min(308, bodyH - 150)
		local wheelOuter = Instance.new("Frame")
		wheelOuter.Name = "WheelOuter"
		wheelOuter.AnchorPoint = Vector2.new(0.5, 0)
		wheelOuter.Position = UDim2.new(0.5, 0, 0, 22)
		wheelOuter.Size = UDim2.fromOffset(wheelDia, wheelDia)
		wheelOuter.BackgroundColor3 = C.BgAbyss
		wheelOuter.BorderSizePixel = 0
		wheelOuter.Parent = wheelPanel
		UiTheme.corner(wheelOuter, math.floor(wheelDia / 2))
		UiTheme.stroke(wheelOuter, C.GoldBright, 3, 0)

		local wheelInner = Instance.new("Frame")
		wheelInner.Name = "WheelRotatable"
		wheelInner.AnchorPoint = Vector2.new(0.5, 0.5)
		wheelInner.Position = UDim2.fromScale(0.5, 0.5)
		wheelInner.Size = UDim2.fromScale(1, 1)
		wheelInner.BackgroundTransparency = 1
		wheelInner.Rotation = currentWheelAngle
		wheelInner.Parent = wheelOuter

		local sectors = state.roulette or DEFAULT_SECTORS
		local radius = wheelDia * 0.34
		for i = 1, 8 do
			local sec = sectors[i] or DEFAULT_SECTORS[i]
			local deg = (i - 1) * 45
			local rad = math.rad(deg)

			-- Línea divisoria entre sectores
			local spoke = Instance.new("Frame")
			spoke.AnchorPoint = Vector2.new(0.5, 0.5)
			spoke.Position = UDim2.fromScale(0.5, 0.5)
			spoke.Size = UDim2.fromOffset(2, wheelDia - 8)
			spoke.BackgroundColor3 = C.GoldDim
			spoke.BackgroundTransparency = 0.35
			spoke.BorderSizePixel = 0
			spoke.Rotation = deg + 22.5
			spoke.Parent = wheelInner

			-- Medallón del sector
			local sx = math.sin(rad) * radius
			local sy = -math.cos(rad) * radius
			local node = Instance.new("Frame")
			node.Name = "Sector_" .. i
			node.AnchorPoint = Vector2.new(0.5, 0.5)
			node.Position = UDim2.new(0.5, sx, 0.5, sy)
			node.Size = UDim2.fromOffset(78, 44)
			node.BackgroundColor3 = sectorColor(sec, i)
			node.BorderSizePixel = 0
			node.Rotation = deg
			node.Parent = wheelInner
			UiTheme.corner(node, UiTheme.Radius.SM)
			UiTheme.stroke(node, (sec and (sec.kind == "WeeklySkin" or sec.kind == "Weekly")) and C.GoldBright or C.GoldDim, 1.4, 0.1)

			UiTheme.label({
				parent = node,
				position = UDim2.fromOffset(4, 2),
				size = UDim2.new(1, -8, 1, -4),
				text = formatSectorLabel(sec),
				font = "Bold",
				textSize = 10,
				maxTextSize = 11,
				minTextSize = 8,
				scaled = true,
				color = C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
			})
		end

		-- Núcleo central gótico de la rueda
		local hub = Instance.new("Frame")
		hub.AnchorPoint = Vector2.new(0.5, 0.5)
		hub.Position = UDim2.fromScale(0.5, 0.5)
		hub.Size = UDim2.fromOffset(58, 58)
		hub.BackgroundColor3 = C.BgPrimary
		hub.BorderSizePixel = 0
		hub.ZIndex = 6
		hub.Parent = wheelOuter
		UiTheme.corner(hub, 29)
		UiTheme.stroke(hub, C.GoldBright, 2.2, 0)
		local hubIc = UiAssets.icon(hub, "trophy", 30, C.GoldBright)
		hubIc.AnchorPoint = Vector2.new(0.5, 0.5)
		hubIc.Position = UDim2.fromScale(0.5, 0.5)
		hubIc.ZIndex = 7

		-- Puntero superior fijo (12 en punto)
		local pointer = Instance.new("Frame")
		pointer.Name = "TopPointer"
		pointer.AnchorPoint = Vector2.new(0.5, 0)
		pointer.Position = UDim2.new(0.5, 0, 0, 10)
		pointer.Size = UDim2.fromOffset(22, 22)
		pointer.Rotation = 45
		pointer.BackgroundColor3 = C.GoldBright
		pointer.BorderSizePixel = 0
		pointer.ZIndex = 8
		pointer.Parent = wheelPanel
		UiTheme.stroke(pointer, C.BgAbyss, 2, 0)

		-- Barra de garantía (Pity 30 giros)
		local pityCur = tonumber(state.spinPity) or 0
		local pityMax = math.max(1, tonumber(state.spinGuarantee) or 30)
		UiTheme.progressBar({
			parent = wheelPanel,
			position = UDim2.new(0.08, 0, 1, -104),
			size = UDim2.new(0.84, 0, 0, 20),
			fraction = math.clamp(pityCur / pityMax, 0, 1),
			fillColor = C.Gold,
			showText = true,
			text = L.t("ui.rewards.pity", { cur = pityCur, max = pityMax }),
		})

		-- Botón principal de giro (Gratis tutorial / Gratis diario / Ticket / Con Almas)
		local spinMode = nil
		local spinBtnText = ""
		local canSpin = true
		if state.tutorial and state.tutorial.spinAvailable then
			spinMode = "Tutorial"
			spinBtnText = L.t("ui.rewards.spinTutorial")
		elseif state.freeSpin then
			spinMode = "Free"
			spinBtnText = L.t("ui.rewards.spinFree")
		elseif (tonumber(state.spins) or 0) > 0 then
			spinMode = "Ticket"
			spinBtnText = L.t("ui.rewards.spinTicket", { count = state.spins })
		elseif state.paidSpinPrice then
			spinMode = "Paid"
			spinBtnText = L.t("ui.rewards.spinPaid", { price = state.paidSpinPrice })
		else
			canSpin = false
			spinBtnText = L.t("ui.rewards.spinWait", { time = formatTimeLeft(state.resetAt) })
		end

		UiTheme.button({
			name = "SpinButton",
			parent = wheelPanel,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -46),
			size = UDim2.fromOffset(290, 46),
			text = spinBtnText,
			font = "Title",
			textSize = UiTheme.TextSizes.LG,
			variant = canSpin and "gold" or "secondary",
			disabled = not canSpin or spinning,
			onClick = function()
				if spinning or not canSpin then return end
				spinning = true
				setStatus(L.t("ui.rewards.spinning"), false)
				invokeRewards("Spin", spinMode, nil, function(ok, res)
					if not ok or type(res) ~= "table" then
						spinning = false
						UiTheme.playSound("UI_Error")
						setStatus(L.t((type(res) == "table" and res.key) or "error"), true)
						return
					end
					local sectorIdx = math.clamp(tonumber(res.sector) or 1, 1, 8)
					local targetMod = (360 - (sectorIdx - 1) * 45) % 360
					local startRot = wheelInner.Rotation
					local baseTurns = math.floor(startRot / 360) * 360 + 360 * 5
					local targetRot = baseTurns + targetMod

					-- Sonidos de clic que se desaceleran junto con la rueda
					task.spawn(function()
						local delays = { 0.06, 0.06, 0.07, 0.08, 0.09, 0.11, 0.13, 0.16, 0.20, 0.25, 0.32, 0.42 }
						for _, d in delays do
							if not spinning then break end
							UiTheme.playSound("UI_Hover")
							task.wait(d)
						end
					end)

					local tw = TweenService:Create(
						wheelInner,
						TweenInfo.new(3.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
						{ Rotation = targetRot }
					)
					tw:Play()
					tw.Completed:Wait()
					currentWheelAngle = targetRot % 360
					spinning = false
					showPrizeCelebration(res.reward, false)
				end)
			end,
		})

		UiTheme.label({
			parent = wheelPanel,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -14),
			size = UDim2.new(0.9, 0, 0, 22),
			text = state.freeSpin and "" or L.t("ui.rewards.spinWait", { time = formatTimeLeft(state.resetAt) }),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
		})

		-- Panel derecho: Vista 3D del Gran Premio Semanal (CrimsonEclipse)
		local prizePanel = UiTheme.panel({
			name = "WeeklyPrizePanel",
			parent = body,
			position = UDim2.fromOffset(leftW + 14, 0),
			size = UDim2.fromOffset(rightW, bodyH),
			bg = C.BgPanel,
			borderColor = C.GoldBright,
			ornaments = true,
		})

		local wSkinId = state.weeklySkin or "CrimsonEclipse"
		local wSkinData = Skins.Data[wSkinId] or Skins.Data.CrimsonEclipse or Skins.Data.Default
		local wWeaponId = (wSkinData and wSkinData.weapon) or "Sword"

		UiTheme.label({
			parent = prizePanel,
			position = UDim2.fromOffset(16, 14),
			size = UDim2.new(1, -32, 0, 24),
			text = L.t("ui.rewards.weeklyGrand"),
			font = "Title",
			textSize = UiTheme.TextSizes.LG,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})

		UiTheme.rarityBadge(prizePanel, "Legendary", L.t("Legendary"), UDim2.new(0.5, -52, 0, 42))

		makeWeaponPreview3D(prizePanel, wWeaponId, wSkinId, { 16, 74, rightW - 32, math.max(180, bodyH - 230) }, true)

		UiTheme.label({
			parent = prizePanel,
			position = UDim2.new(0, 16, 1, -144),
			size = UDim2.new(1, -32, 0, 28),
			text = L.t("skin." .. wSkinId),
			font = "Title",
			textSize = UiTheme.TextSizes.XL,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})

		UiTheme.label({
			parent = prizePanel,
			position = UDim2.new(0, 18, 1, -112),
			size = UDim2.new(1, -36, 0, 92),
			text = L.t("skinDesc." .. wSkinId),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
			alignY = Enum.TextYAlignment.Top,
		})

	------------------------------------------------------------------
	-- PESTAÑA 2: CAJAS DE SUERTE (Caja de Almas 500 y Caja de Reliquias 1500)
	------------------------------------------------------------------
	elseif tab == "Boxes" then
		local cardW = math.floor((width - 40 - 18) / 2)
		local boxSpecs = {
			{
				id = "Souls",
				titleKey = "ui.rewards.boxSouls",
				descKey = "ui.rewards.boxSoulsDesc",
				price = (state.boxes and state.boxes.Souls and state.boxes.Souls.price) or 500,
				count = (state.boxes and state.boxes.Souls and state.boxes.Souls.count) or 0,
				color = C.Gold,
				icon = "coin",
				hasPity = false,
			},
			{
				id = "Relic",
				titleKey = "ui.rewards.boxRelic",
				descKey = "ui.rewards.boxRelicDesc",
				price = (state.boxes and state.boxes.Relic and state.boxes.Relic.price) or 1500,
				count = (state.boxes and state.boxes.Relic and state.boxes.Relic.count) or 0,
				color = C.GoldBright,
				icon = "trophy",
				hasPity = true,
			},
		}

		for idx, bSpec in boxSpecs do
			local bCard = UiTheme.panel({
				name = "BoxCard_" .. bSpec.id,
				parent = body,
				position = UDim2.fromOffset((idx - 1) * (cardW + 18), 0),
				size = UDim2.fromOffset(cardW, bodyH),
				bg = C.BgPanel,
				borderColor = bSpec.color,
				ornaments = true,
			})

			UiTheme.label({
				parent = bCard,
				position = UDim2.fromOffset(20, 18),
				size = UDim2.new(1, -40, 0, 32),
				text = L.t(bSpec.titleKey),
				font = "Title",
				textSize = UiTheme.TextSizes.XXL,
				color = bSpec.color,
				alignX = Enum.TextXAlignment.Center,
			})

			-- Cofre central ilustrado / visor 3D
			if bSpec.id == "Relic" then
				makeWeaponPreview3D(bCard, "Greatsword", "BloodMoonCleaver", { 32, 60, cardW - 64, 175 }, true)
			else
				local emblem = Instance.new("Frame")
				emblem.AnchorPoint = Vector2.new(0.5, 0)
				emblem.Position = UDim2.new(0.5, 0, 0, 68)
				emblem.Size = UDim2.fromOffset(152, 152)
				emblem.BackgroundColor3 = C.BgPreview
				emblem.BorderSizePixel = 0
				emblem.Parent = bCard
				UiTheme.corner(emblem, 76)
				UiTheme.stroke(emblem, bSpec.color, 2.2, 0.1)
				local ic = UiAssets.icon(emblem, bSpec.icon, 78, bSpec.color)
				ic.AnchorPoint = Vector2.new(0.5, 0.5)
				ic.Position = UDim2.fromScale(0.5, 0.5)
			end

			UiTheme.label({
				parent = bCard,
				position = UDim2.fromOffset(24, 248),
				size = UDim2.new(1, -48, 0, 54),
				text = L.t(bSpec.descKey),
				font = "Body",
				textSize = UiTheme.TextSizes.SM,
				color = C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
			})

			if bSpec.hasPity then
				local pCur = tonumber(state.relicPity) or 0
				local pMax = math.max(1, tonumber(state.relicGuarantee) or 10)
				UiTheme.progressBar({
					parent = bCard,
					position = UDim2.fromOffset(32, 312),
					size = UDim2.new(1, -64, 0, 20),
					fraction = math.clamp(pCur / pMax, 0, 1),
					fillColor = C.GoldBright,
					showText = true,
					text = L.t("ui.rewards.relicPity", { cur = pCur, max = pMax }),
				})
			else
				UiTheme.label({
					parent = bCard,
					position = UDim2.fromOffset(24, 312),
					size = UDim2.new(1, -48, 0, 24),
					text = L.t("ui.rewards.duplicateRule"),
					font = "Body",
					textSize = UiTheme.TextSizes.XS,
					color = C.TextSecondary,
					alignX = Enum.TextXAlignment.Center,
				})
			end

			UiTheme.label({
				parent = bCard,
				position = UDim2.fromOffset(24, 346),
				size = UDim2.new(1, -48, 0, 24),
				text = L.t("ui.rewards.boxOwned", { count = bSpec.count }),
				font = "Bold",
				textSize = UiTheme.TextSizes.MD,
				color = bSpec.count > 0 and C.Success or C.TextSecondary,
				alignX = Enum.TextXAlignment.Center,
			})

			local hasOwned = bSpec.count > 0
			local openBtnText = hasOwned
				and L.t("ui.rewards.openOwned", { count = bSpec.count })
				or L.t("ui.rewards.buyAndOpen", { price = bSpec.price })

			UiTheme.button({
				name = "OpenBox_" .. bSpec.id,
				parent = bCard,
				anchor = Vector2.new(0.5, 1),
				position = UDim2.new(0.5, 0, 1, -24),
				size = UDim2.fromOffset(cardW - 64, 48),
				text = openBtnText,
				font = "Title",
				textSize = UiTheme.TextSizes.LG,
				variant = "gold",
				onClick = function()
					if busy then return end
					busy = true
					local src = hasOwned and "Owned" or "Buy"
					invokeRewards("OpenBox", bSpec.id, src, function(ok, res)
						busy = false
						if ok and type(res) == "table" and res.reward then
							showPrizeCelebration(res.reward, true)
						else
							UiTheme.playSound("UI_Error")
							setStatus(L.t((type(res) == "table" and res.key) or "noCoins"), true)
						end
					end)
				end,
			})
		end

	------------------------------------------------------------------
	-- PESTAÑA 3: RACHA DIARIA (7 DÍAS), BIENVENIDO DE VUELTA Y PRIMEROS PASOS
	------------------------------------------------------------------
	elseif tab == "Streak" then
		local topOffset = 0
		if state.returnNotice then
			local retBar = UiTheme.panel({
				parent = body,
				position = UDim2.fromOffset(0, 0),
				size = UDim2.new(1, 0, 0, 44),
				bg = C.BgCardSelected,
				borderColor = C.GoldBright,
			})
			UiTheme.label({
				parent = retBar,
				position = UDim2.fromOffset(18, 0),
				size = UDim2.new(1, -150, 1, 0),
				text = L.t("ui.rewards.returnBanner"),
				font = "Bold",
				textSize = UiTheme.TextSizes.MD,
				color = C.GoldBright,
			})
			UiTheme.button({
				parent = retBar,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -10, 0.5, 0),
				size = UDim2.fromOffset(110, 32),
				text = L.t("close"),
				variant = "gold",
				textSize = UiTheme.TextSizes.XS,
				onClick = function()
					invokeRewards("DismissReturn", nil, nil, function()
						refreshState(true)
					end)
				end,
			})
			topOffset = 52
		end

		-- Sección superior: Racha diaria de 7 días
		local streakH = 192
		local streakPanel = UiTheme.panel({
			parent = body,
			position = UDim2.fromOffset(0, topOffset),
			size = UDim2.new(1, 0, 0, streakH),
			bg = C.BgPanel,
			borderColor = C.Gold,
		})

		UiTheme.label({
			parent = streakPanel,
			position = UDim2.fromOffset(18, 8),
			size = UDim2.fromOffset(420, 24),
			text = L.t("ui.rewards.streakTitle"),
			font = "Title",
			textSize = UiTheme.TextSizes.LG,
			color = C.GoldBright,
		})
		UiTheme.label({
			parent = streakPanel,
			position = UDim2.fromOffset(18, 30),
			size = UDim2.new(1, -240, 0, 18),
			text = L.t("ui.rewards.streakSub"),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
		})

		local stData = state.streak or { day = 0, canClaim = true, rewards = { 50, 75, 100, 125, 150, 200, "Relic" } }
		local curDay = tonumber(stData.day) or 0
		local canClaimStreak = stData.canClaim == true
		local nextClaimDay = (curDay % 7) + 1

		UiTheme.button({
			name = "ClaimStreakBtn",
			parent = streakPanel,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -16, 0, 10),
			size = UDim2.fromOffset(200, 38),
			text = canClaimStreak and L.t("ui.rewards.claimStreak", { d = nextClaimDay }) or L.t("ui.rewards.streakClaimed"),
			variant = canClaimStreak and "gold" or "secondary",
			disabled = not canClaimStreak,
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				invokeRewards("ClaimStreak", nil, nil, function(ok)
					if ok then UiTheme.playSound("UI_PurchaseOK") end
					refreshState(true)
				end)
			end,
		})

		local rewardsList = stData.rewards or { 50, 75, 100, 125, 150, 200, "Relic" }
		local dayGap = 10
		local dayW = math.floor((width - 40 - 36 - dayGap * 6) / 7)
		for d = 1, 7 do
			local rVal = rewardsList[d]
			local isPast = (not canClaimStreak and d <= curDay) or (canClaimStreak and d <= curDay)
			local isToday = canClaimStreak and d == nextClaimDay
			local dCard = UiTheme.panel({
				parent = streakPanel,
				position = UDim2.fromOffset(18 + (d - 1) * (dayW + dayGap), 56),
				size = UDim2.fromOffset(dayW, 122),
				bg = isToday and C.BgCardSelected or C.BgCard,
				borderColor = isToday and C.GoldBright or (isPast and C.Success or C.BorderDefault),
				borderThickness = isToday and 2.2 or 1.2,
			})

			UiTheme.label({
				parent = dCard,
				position = UDim2.fromOffset(6, 6),
				size = UDim2.new(1, -12, 0, 20),
				text = L.t("ui.rewards.dayN", { d = d }),
				font = "Header",
				textSize = UiTheme.TextSizes.SM,
				color = isToday and C.GoldBright or C.TextSecondary,
				alignX = Enum.TextXAlignment.Center,
			})

			local icName = type(rVal) == "number" and "coin" or "trophy"
			local icCol = type(rVal) == "number" and C.Coins or C.GoldBright
			local ic = UiAssets.icon(dCard, icName, 34, icCol)
			ic.AnchorPoint = Vector2.new(0.5, 0.5)
			ic.Position = UDim2.new(0.5, 0, 0.48, 0)

			local valText = type(rVal) == "number"
				and L.t("ui.rewards.sectorSouls", { amount = rVal })
				or L.t("ui.rewards.sectorBoxRelic")
			UiTheme.label({
				parent = dCard,
				position = UDim2.fromOffset(4, 88),
				size = UDim2.new(1, -8, 0, 26),
				text = valText,
				font = "Bold",
				textSize = UiTheme.TextSizes.XS,
				color = isPast and C.Success or C.TextPrimary,
				alignX = Enum.TextXAlignment.Center,
				scaled = true,
				maxTextSize = 12,
				minTextSize = 8,
			})
		end

		-- Sección inferior: Cadena «Primeros Pasos» (7 misiones) + Misión Semanal
		local bottomY = topOffset + streakH + 10
		local bottomH = bodyH - bottomY
		local stepsPanel = UiTheme.panel({
			parent = body,
			position = UDim2.fromOffset(0, bottomY),
			size = UDim2.new(1, 0, 0, bottomH),
			bg = C.BgPanel,
			borderColor = C.GoldDim,
		})

		UiTheme.label({
			parent = stepsPanel,
			position = UDim2.fromOffset(18, 8),
			size = UDim2.fromOffset(440, 24),
			text = L.t("ui.rewards.firstStepsTitle"),
			font = "Title",
			textSize = UiTheme.TextSizes.LG,
			color = C.GoldBright,
		})
		UiTheme.label({
			parent = stepsPanel,
			position = UDim2.fromOffset(18, 30),
			size = UDim2.new(1, -250, 0, 18),
			text = L.t("ui.rewards.firstStepsSub"),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
		})

		local fs = state.firstSteps or { list = DEFAULT_FIRST_STEPS, canClaim = false, claimed = false }
		UiTheme.button({
			name = "ClaimFirstStepsBtn",
			parent = stepsPanel,
			anchor = Vector2.new(1, 0),
			position = UDim2.new(1, -16, 0, 10),
			size = UDim2.fromOffset(210, 38),
			text = fs.claimed and L.t("ui.missions.claimed") or L.t("ui.rewards.claimEpic"),
			variant = fs.canClaim and "gold" or "secondary",
			disabled = not fs.canClaim,
			textSize = UiTheme.TextSizes.SM,
			onClick = function()
				invokeRewards("ClaimFirstSteps", nil, nil, function(ok, res)
					if ok and type(res) == "table" and res.reward then
						showPrizeCelebration(res.reward, false)
					else
						refreshState(true)
					end
				end)
			end,
		})

		local stepsScroll = Instance.new("ScrollingFrame")
		stepsScroll.Position = UDim2.fromOffset(18, 54)
		stepsScroll.Size = UDim2.new(1, -36, 1, -64)
		stepsScroll.BackgroundTransparency = 1
		stepsScroll.BorderSizePixel = 0
		stepsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		stepsScroll.CanvasSize = UDim2.new()
		stepsScroll.ScrollBarThickness = 5
		stepsScroll.ScrollBarImageColor3 = C.Gold
		stepsScroll.Parent = stepsPanel

		local gLayout = Instance.new("UIGridLayout")
		gLayout.CellSize = UDim2.fromOffset(math.floor((width - 40 - 48) / 2), 46)
		gLayout.CellPadding = UDim2.fromOffset(10, 8)
		gLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gLayout.Parent = stepsScroll

		for idx, st in (fs.list or DEFAULT_FIRST_STEPS) do
			local prog = math.floor(tonumber(st.progress) or 0)
			local goal = math.max(1, math.floor(tonumber(st.goal) or 1))
			local done = prog >= goal
			local sRow = UiTheme.panel({
				parent = stepsScroll,
				layoutOrder = idx,
				bg = C.BgCard,
				borderColor = done and C.Success or C.BorderSubtle,
			})
			local labelKey = "ui.rewards.step." .. tostring(st.id)
			UiTheme.label({
				parent = sRow,
				position = UDim2.fromOffset(12, 4),
				size = UDim2.new(1, -24, 0, 20),
				text = L.t(labelKey, { p = prog, g = goal }),
				font = "Bold",
				textSize = UiTheme.TextSizes.XS,
				color = done and C.Success or C.TextPrimary,
			})
			UiTheme.progressBar({
				parent = sRow,
				position = UDim2.fromOffset(12, 26),
				size = UDim2.new(1, -24, 0, 12),
				fraction = math.clamp(prog / goal, 0, 1),
				fillColor = done and C.Success or C.Gold,
			})
		end

	------------------------------------------------------------------
	-- PESTAÑA 4: COLECCIÓN Y MAESTRÍA POR ARMA
	------------------------------------------------------------------
	elseif tab == "Collection" then
		-- Barra selectora de las 5 armas arriba
		local wBar = Instance.new("Frame")
		wBar.Size = UDim2.new(1, 0, 0, 38)
		wBar.BackgroundTransparency = 1
		wBar.Parent = body

		local bw = math.floor((width - 40) / #Weapons.Order)
		for i, wid in Weapons.Order do
			UiTheme.button({
				parent = wBar,
				position = UDim2.fromOffset((i - 1) * bw, 0),
				size = UDim2.fromOffset(bw - 8, 36),
				text = L.t("weapon." .. wid),
				selected = wid == selectedWeapon,
				textSize = UiTheme.TextSizes.SM,
				onClick = function()
					selectedWeapon = wid
					render()
				end,
			})
		end

		local colY = 46
		local colH = bodyH - colY
		local leftW = math.floor((width - 54) * 0.60)
		local rightW = (width - 40) - leftW - 14

		-- Panel izquierdo: Álbum de Colección del arma seleccionada
		local albumPanel = UiTheme.panel({
			parent = body,
			position = UDim2.fromOffset(0, colY),
			size = UDim2.fromOffset(leftW, colH),
			bg = C.BgPanel,
			borderColor = C.Gold,
		})

		local cData = (state.collection and state.collection[selectedWeapon]) or { owned = 0, total = 1, percent = 0, aura = "AshCrown", skins = {} }
		local pct = math.floor((tonumber(cData.percent) or 0) * 100 + 0.5)

		UiTheme.label({
			parent = albumPanel,
			position = UDim2.fromOffset(16, 10),
			size = UDim2.new(1, -32, 0, 22),
			text = L.t("ui.rewards.collectionTitle") .. " — " .. string.upper(L.t("weapon." .. selectedWeapon)),
			font = "Title",
			textSize = UiTheme.TextSizes.LG,
			color = C.GoldBright,
		})

		UiTheme.label({
			parent = albumPanel,
			position = UDim2.fromOffset(16, 32),
			size = UDim2.new(1, -32, 0, 18),
			text = L.t("ui.rewards.collectionAura", { aura = L.t("cx.aura." .. tostring(cData.aura or "AshCrown")) }),
			font = "Bold",
			textSize = UiTheme.TextSizes.XS,
			color = C.Gold,
		})

		UiTheme.progressBar({
			parent = albumPanel,
			position = UDim2.fromOffset(16, 54),
			size = UDim2.new(1, -32, 0, 20),
			fraction = math.clamp(tonumber(cData.percent) or 0, 0, 1),
			fillColor = pct >= 100 and C.Success or C.GoldBright,
			showText = true,
			text = string.format("%d / %d (%d%%)", cData.owned or 0, cData.total or 0, pct),
		})

		local albumScroll = Instance.new("ScrollingFrame")
		albumScroll.Position = UDim2.fromOffset(16, 82)
		albumScroll.Size = UDim2.new(1, -32, 1, -94)
		albumScroll.BackgroundTransparency = 1
		albumScroll.BorderSizePixel = 0
		albumScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		albumScroll.CanvasSize = UDim2.new()
		albumScroll.ScrollBarThickness = 5
		albumScroll.ScrollBarImageColor3 = C.Gold
		albumScroll.Parent = albumPanel

		local cols = mobile and 2 or 3
		local cellW = math.floor((leftW - 44 - (cols - 1) * 10) / cols)
		local aGrid = Instance.new("UIGridLayout")
		aGrid.CellSize = UDim2.fromOffset(cellW, 146)
		aGrid.CellPadding = UDim2.fromOffset(10, 10)
		aGrid.SortOrder = Enum.SortOrder.LayoutOrder
		aGrid.Parent = albumScroll

		for idx, entry in (cData.skins or {}) do
			local sid = entry.id
			local has = entry.owned == true
			local sInfo = Skins.Data[sid]
			local rSpec = sInfo and sInfo.rarity and UiTheme.Rarities[sInfo.rarity]
			local sCard = UiTheme.panel({
				parent = albumScroll,
				layoutOrder = idx,
				bg = has and C.BgCard or C.BgAbyss,
				borderColor = has and (rSpec and rSpec.color or C.Gold) or C.BorderSubtle,
			})
			local vp = makeWeaponPreview3D(sCard, selectedWeapon, sid, { 8, 8, cellW - 16, 88 }, false)
			if not has then
				vp.ImageColor3 = Color3.fromRGB(70, 70, 80)
				vp.ImageTransparency = 0.35
			end
			UiTheme.label({
				parent = sCard,
				position = UDim2.fromOffset(8, 100),
				size = UDim2.new(1, -16, 0, 20),
				text = L.t("skin." .. sid),
				font = "Header",
				textSize = UiTheme.TextSizes.XS,
				color = has and C.TextPrimary or C.TextMuted,
				truncate = Enum.TextTruncate.AtEnd,
			})
			UiTheme.label({
				parent = sCard,
				position = UDim2.fromOffset(8, 120),
				size = UDim2.new(1, -16, 0, 18),
				text = has and L.t("owned") or L.t("notOwned"),
				font = "Bold",
				textSize = UiTheme.TextSizes.XS,
				color = has and C.Success or C.TextMuted,
			})
		end

		-- Panel derecho: Maestría por Arma (Nvl. 1..20)
		local mastPanel = UiTheme.panel({
			parent = body,
			position = UDim2.fromOffset(leftW + 14, colY),
			size = UDim2.fromOffset(rightW, colH),
			bg = C.BgPanel,
			borderColor = C.GoldBright,
			ornaments = true,
		})

		local mData = (state.mastery and state.mastery[selectedWeapon]) or { level = 1, xp = 0, xpNext = 200, finish = "Charcoal", trail = "WeepingBlade" }
		local mLvl = tonumber(mData.level) or 1
		local mXp = tonumber(mData.xp) or 0
		local mNext = math.max(1, tonumber(mData.xpNext) or 200)

		UiTheme.label({
			parent = mastPanel,
			position = UDim2.fromOffset(16, 14),
			size = UDim2.new(1, -32, 0, 26),
			text = L.t("ui.rewards.masteryTitle", { weapon = string.upper(L.t("weapon." .. selectedWeapon)) }),
			font = "Title",
			textSize = UiTheme.TextSizes.LG,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})

		makeWeaponPreview3D(mastPanel, selectedWeapon, mData.finish or "Charcoal", { 16, 48, rightW - 32, math.max(150, colH - 210) }, true)

		UiTheme.label({
			parent = mastPanel,
			position = UDim2.new(0, 16, 1, -148),
			size = UDim2.new(1, -32, 0, 24),
			text = L.t("ui.rewards.masteryLevel", { level = mLvl }),
			font = "Title",
			textSize = UiTheme.TextSizes.XL,
			color = C.GoldBright,
			alignX = Enum.TextXAlignment.Center,
		})

		UiTheme.progressBar({
			parent = mastPanel,
			position = UDim2.new(0, 20, 1, -116),
			size = UDim2.new(1, -40, 0, 20),
			fraction = mLvl >= 20 and 1 or math.clamp(mXp / mNext, 0, 1),
			fillColor = C.Gold,
			showText = true,
			text = L.t("ui.hud.xp", { xp = math.floor(mXp), next = math.floor(mNext) }),
		})

		UiTheme.label({
			parent = mastPanel,
			position = UDim2.new(0, 16, 1, -86),
			size = UDim2.new(1, -32, 0, 68),
			text = L.t("ui.rewards.masteryMilestones", {
				finish = L.t("skin." .. tostring(mData.finish or "Charcoal")),
				trail = L.t("cx.aura." .. tostring(mData.trail or "WeepingBlade")),
			}),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
		})
	end

	statusLabel = UiTheme.label({
		name = "StatusMessage",
		parent = panel,
		position = UDim2.fromOffset(22, height - 34),
		size = UDim2.fromOffset(width - 260, 24),
		text = "",
		font = "Bold",
		textSize = UiTheme.TextSizes.SM,
		color = C.GoldBright,
	})

	UiTheme.label({
		parent = panel,
		position = UDim2.fromOffset(width - 240, height - 34),
		size = UDim2.fromOffset(220, 24),
		text = L.t("ui.gamepadHint"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextMuted,
		alignX = Enum.TextXAlignment.Right,
	})

	if UIS.GamepadEnabled and firstTabBtn and not subModal then
		GuiService.SelectedObject = firstTabBtn
	end
end

----------------------------------------------------------------------
-- Apertura / cierre y sincronización con otros menús
----------------------------------------------------------------------
function setOpen(value)
	if opened == value or spinning then return end
	if value and player:GetAttribute("InMatch") then return end
	opened = value
	player:SetAttribute("RewardsOpen", value)
	if value then
		player:SetAttribute("ShopOpen", false)
		player:SetAttribute("ArmoryOpen", false)
		player:SetAttribute("SettingsOpen", false)
	end
	player:SetAttribute("MenuOpen", value
		or player:GetAttribute("ShopOpen") == true
		or player:GetAttribute("ArmoryOpen") == true
		or player:GetAttribute("SettingsOpen") == true)
	UiTheme.playSound(value and "UI_MenuOpen" or "UI_MenuClose")

	if value then
		backdrop.Visible = true
		panel.Visible = true
		render()
		refreshState(true)
		panel.GroupTransparency = 1
		panel.Position = UDim2.fromScale(0.5, 0.53)
		TweenService:Create(panel, UiTheme.Anim.TweenNorm, {
			GroupTransparency = 0,
			Position = UDim2.fromScale(0.5, 0.5),
		}):Play()
	else
		closeSubModal()
		backdrop.Visible = false
		panel.Visible = false
		table.clear(spins3D)
		GuiService.SelectedObject = nil
	end
end

toggleRewardsBindable.Event:Connect(function(forceState)
	if type(forceState) == "boolean" then
		setOpen(forceState)
	else
		setOpen(not opened)
	end
end)

player:GetAttributeChangedSignal("RewardsOpen"):Connect(function()
	local desired = player:GetAttribute("RewardsOpen") == true
	if desired ~= opened then
		setOpen(desired)
	end
end)

for _, otherAttr in { "ShopOpen", "ArmoryOpen", "SettingsOpen", "InMatch" } do
	player:GetAttributeChangedSignal(otherAttr):Connect(function()
		if player:GetAttribute(otherAttr) == true and opened then
			setOpen(false)
		end
	end)
end

-- Si el jugador interactúa con un ProximityPrompt de la Ruleta en la ciudad, abre directamente la Ruleta
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggerPlayer)
	if triggerPlayer ~= player then return end
	local name = string.lower(prompt.Name .. " " .. (prompt.Parent and prompt.Parent.Name or ""))
	if string.find(name, "roulette") or string.find(name, "ruleta") or string.find(name, "wheel") then
		tab = "Roulette"
		setOpen(true)
	end
end)

UIS.InputBegan:Connect(function(input, processed)
	if not opened or spinning then return end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		if subModal then
			closeSubModal()
		elseif not processed or input.KeyCode == Enum.KeyCode.ButtonB then
			setOpen(false)
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not opened and not welcomeVeil then return end
	for i = #spins3D, 1, -1 do
		local v = spins3D[i]
		if not v.vp.Parent then
			table.remove(spins3D, i)
		else
			v.phase = (v.phase or 0) + dt * 1.35
			local yaw = math.sin(v.phase) * 0.36
			local pitch = math.cos(v.phase * 0.7) * 0.12
			v.model:PivotTo(CFrame.Angles(pitch, yaw, 0) * v.base)
			v.camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, v.distance), Vector3.zero)
		end
	end
end)

----------------------------------------------------------------------
-- Eventos del servidor: RewardsChanged y RewardAnnouncement (Legendarias)
----------------------------------------------------------------------
task.spawn(function()
	refreshState(false)
	if not remotes then remotes = RS:WaitForChild("Remotes", 15) end
	if not remotes then return end

	local changedEv = remotes:WaitForChild("RewardsChanged", 15)
	if changedEv and changedEv:IsA("RemoteEvent") then
		changedEv.OnClientEvent:Connect(function()
			refreshState(true)
		end)
	end

	local announceEv = remotes:WaitForChild("RewardAnnouncement", 15)
	if announceEv and announceEv:IsA("RemoteEvent") then
		announceEv.OnClientEvent:Connect(function(payload)
			if type(payload) ~= "table" then return end
			local params = type(payload.params) == "table" and payload.params or {}
			local winnerName = tostring(params.name or "?")
			local prizeName = params.prizeKey and L.t(params.prizeKey) or L.t("Legendary")

			local banner = UiTheme.panel({
				name = "LegendaryAnnouncement",
				parent = gui,
				anchor = Vector2.new(0.5, 0),
				position = UDim2.new(0.5, 0, 0, 56),
				size = UDim2.fromOffset(540, 38),
				bg = Color3.fromRGB(42, 14, 22),
				borderColor = C.GoldBright,
				borderThickness = 2,
				ornaments = true,
				zIndex = 60,
			})
			UiTheme.label({
				parent = banner,
				position = UDim2.fromOffset(14, 0),
				size = UDim2.new(1, -28, 1, 0),
				text = L.t("ui.rewards.legendaryToast", { name = winnerName, prize = prizeName }),
				font = "Title",
				textSize = UiTheme.TextSizes.MD,
				color = C.GoldBright,
				alignX = Enum.TextXAlignment.Center,
				zIndex = 61,
			})
			task.delay(4.5, function()
				if banner.Parent then banner:Destroy() end
			end)
		end)
	end
end)

L.Changed:Connect(function()
	if opened and not spinning then render() end
end)
