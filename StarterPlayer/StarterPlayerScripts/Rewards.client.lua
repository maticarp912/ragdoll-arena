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
local Vault = require(RS:WaitForChild("VaultClient"))
local Format = require(RS:WaitForChild("Format"))
local Device = require(RS:WaitForChild("Device")) -- 11/11: PC, celular o consola
local Skins = require(RS:WaitForChild("Skins", 10))
local Weapons = require(RS:WaitForChild("WeaponData", 10))
local Builder = require(RS:WaitForChild("WeaponBuilder", 10))

-- Presentation tuning only. Never selects, buys or grants a reward.
local REVEAL = {
	CarouselSeconds = 3.5, SettleSeconds = 0.3, RevealSeconds = 1.2,
	FixedSeconds = 0.9, OpenSeconds = 0.55, BrakePower = 3,
	WheelSeconds = 2.7, WheelPause = 0.24, WheelFinalSeconds = 0.38,
	WheelTurns = 4, Circle = 360, FinalSectorFraction = 0.72,
	JackpotSeconds = 2.5, FlashSeconds = 0.55, JackpotFlashSeconds = 1.2,
	FlashTransparency = 0.35, JackpotFlashTransparency = 0.08,
	StripCount = 32, StripTail = 3, CardWidth = 128, CardHeight = 154, CardGap = 10,
	TickSound = "UI_Hover", WinSound = "UI_PurchaseOK", RequestPadding = 0.05,
	Width = 520, JackpotWidth = 600, Height = 446, JackpotExtraHeight = 64, Margin = 16, MobileBreakpoint = 780,
	TitleY = 16, TitleH = 52, StageY = 80, StageH = 190,
	NameY = 276, NameH = 60, DetailY = 338, DetailH = 42, ButtonBottom = 12, ButtonH = 46,
	NameSize = 28, JackpotNameSize = 34, DetailSize = 15, CardNameSize = 15,
	CardNameY = 72, CardNameH = 58, CardRarityH = 24, CardIconSize = 44, CardIconY = 12,
	CardPreviewLimit = 3, PointerWidth = 3, PointerAlpha = 0.25,
	ChestSize = 138, LidHeight = 34, LidLift = 62, LidRotation = -22, ShakeDegrees = 5, ShakeCycles = 6,
	ConfirmHeight = 250, ConfirmTextY = 28, ConfirmTextH = 130, ConfirmGap = 12,
	MobileWheelHeight = 510, MobileBoxHeight = 245, MobileGap = 14, MobileTabHeight = 44,
	BoxCardHeight = 204,
	ChestArtScale = 2, -- 11/11: tamaño del arte del cofre respecto del cofre dibujado
	CompactWidth = 375, CompactHeader = 112, CompactBodyY = 174,
	CompactMaxHeight = 780, CompactRowHeight = 58, CompactStepHeight = 48,
	CompactTitleHeight = 30, CompactTextSize = 13, WeeklyHeight = 114, DesktopWeeklyHeight = 82,
	WheelTop = 62, WheelDiameter = 308, WheelControlsHeight = 130, PityBottom = 128,
	RequestIntervalFallback = 0.35, WheelDescriptionHeight = 36,
	OddsHeight = 520, OddsRowHeight = 64, OddsNameFraction = 0.65,
	OddsHeaderHeight = 32, HeaderTextX = 52,
	SecondsPerMinute = 60,
	Layer = { Veil = 70, Box = 71, Stage = 72, Content = 73, Preview = 74, Pointer = 75, Button = 76, Flash = 77 },
}

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
local CHEST_TIERS = {
	Souls = { size = 50, stroke = 1, color = C.Stone, bg = C.IronDark, icon = "coin", image = "", openedImage = "" },
	Relic = { size = 56, stroke = 1.4, color = C.TextSecondary, bg = C.Iron, icon = "trophy", image = "", openedImage = "" },
	StormLesser = { size = 62, stroke = 1.8, color = C.Accent, bg = C.SuccessDark, icon = "stamina", image = "", openedImage = "" },
	StormGreater = { size = 68, stroke = 2.2, color = C.InfusionCharge, bg = C.BgPanelLight, icon = "stamina", image = "", openedImage = "" },
	StormRoyal = { size = 74, stroke = 2.6, color = C.Coins, bg = UiTheme.Rarities.Legendary.bg, icon = "crown", image = "", openedImage = "" },
	Eclipse = { size = 80, stroke = 3, color = C.GoldBright, bg = C.GoldDark, icon = "crown", lightning = true, image = "", openedImage = "" },
}
-- 11/11/2026: arte de los cofres del usuario (UiAssets chest_N_closed / chest_N_open). Sin imagen o con
-- UiAssets.UseArt = false se dibuja el cofre de marcos de antes.
for i, id in { "Souls", "Relic", "StormLesser", "StormGreater", "StormRoyal", "Eclipse" } do
	CHEST_TIERS[id].image = UiAssets.imageUri("chest_" .. i .. "_closed") or ""
	CHEST_TIERS[id].openedImage = UiAssets.imageUri("chest_" .. i .. "_open") or ""
end
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
	canvasGroup = false, -- 10/11: Frame (con vistas 3D adentro, el CanvasGroup redibujaba todo en cada frame)
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
local luckLabel = nil
local luckTimerSecond = -1
local oddsExpireAt = nil
local oddsBoxId = nil
local subModal = nil

local render
local setOpen
local showPrizeCelebration
local showOddsModal
local checkWelcomeModal
local showPaidConfirmation
local revealQueue = {}
local activeReveal = nil
local revealRunning = false
local serverStateReady = false
local subModalSelection = nil
local renderedViewport = nil
local boxScroller = nil
local boxScrollPosition = Vector2.zero
local function openGems()
	setOpen(false)
	Vault.open(player, "Gems")
end

-- 11/11/2026: píldora de saldo compartida (ReplicatedStorage/BalancePill)
local BalancePillModule = require(RS:WaitForChild("BalancePill"))
local function balancePill(parent, position, size, kind, amount, getGems)
	return BalancePillModule.create(parent, position, size, kind, amount, getGems)
end



local DEFAULT_SECTORS = {
	{ kind = "Souls", amount = 75, probability = 0.30, rarity = "Common" },
	{ kind = "Souls", amount = 200, probability = 0.25, rarity = "Common" },
	{ kind = "Souls", amount = 600, probability = 0.15, rarity = "Rare" },
	{ kind = "XP", amount = 150, probability = 0.12, rarity = "Common" },
	{ kind = "Gems", amount = 15, probability = 0.08, rarity = "Rare" },
	{ kind = "Boost", stat = "Coins", boost = "Coins", multiplier = 2, seconds = 1800, probability = 0.05, rarity = "Epic" },
	{ kind = "Box", id = "Relic", amount = 1, probability = 0.04, rarity = "Epic" },
	{ kind = "WeeklySkin", id = "CrimsonEclipse", probability = 0.01, rarity = "Exclusive" },
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
			if sid ~= "Default" and not s.comingSoon and s.boxOnly ~= "Storm"
				and (s.currency ~= "Robux" or (RewardsConfig and (sid == RewardsConfig.FirstStepsSkin or table.find(RewardsConfig.StarterSkins, sid))))
				and (not s.weapon or s.weapon == wid) then
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
		paidSpinsRemaining = 0,
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

-- Serialize reads and mutations, including RewardsChanged refreshes, under C19's cooldown.
local requests = {}
local requesting = false
local lastRequestAt = -math.huge
local function invokeRewards(action, id, source, callback, quotedOdds)
	local mutation = action ~= "GetState"
	if mutation and (busy or spinning) then return end
	if mutation then busy = true end
	table.insert(requests, { action = action, id = id, source = source, callback = callback, quotedOdds = quotedOdds })
	if requesting then return end
	requesting = true
	task.spawn(function()
		while #requests > 0 do
			local req = table.remove(requests, 1)
			local interval = (RewardsConfig and RewardsConfig.Interval or REVEAL.RequestIntervalFallback) + REVEAL.RequestPadding
			local remaining = interval - (os.clock() - lastRequestAt)
			if remaining > 0 then task.wait(remaining) end
			local success, payload = false, { key = "loading" }
			local rf = getRewardsRemote()
			if rf and rf:IsA("RemoteFunction") then
				lastRequestAt = os.clock()
				local requestId = req.action ~= "GetState" and serverStateReady and state and state.nextRequest or nil
				local callOk, ok, result = pcall(function()
					return rf:InvokeServer(req.action, req.id, req.source, requestId, req.quotedOdds)
				end)
				if callOk then success = ok == true payload = result
				else payload = { key = "cx.reward.reveal.uncertain" } end
				-- Do not repeat a mutation automatically after an uncertain response.
				if success and type(payload) == "table" then
					if req.action == "GetState" then
						state = payload serverStateReady = true
						updateAlertsFromState()
						if not busy and not spinning then checkWelcomeModal() end
					elseif state then state.nextRequest = payload.nextRequest end
				end
			elseif req.action == "GetState" then
				state = state or buildFallbackState()
				updateAlertsFromState()
			end
			if req.action ~= "GetState" then busy = false end
			if req.callback then
				local callbackOk, message = pcall(req.callback, success, payload)
				if not callbackOk then warn("[Rewards] Response: " .. tostring(message)) end
			end
		end
		requesting = false
	end)
end

local refreshQueued, refreshAgain, refreshRenderWanted = false, false, false
local function refreshState(andRender)
	refreshRenderWanted = refreshRenderWanted or andRender == true
	if refreshQueued then refreshAgain = true return end
	refreshQueued = true
	invokeRewards("GetState", nil, nil, function()
		refreshQueued = false
		local shouldRender = refreshRenderWanted
		refreshRenderWanted = false
		if shouldRender and opened and not spinning and not busy and not subModal then
			render()
		end
		if refreshAgain then refreshAgain = false refreshState(shouldRender) end
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

local function rewardError(result, fallbackKey)
	local missing = type(result) == "table" and result.missing
	local gemsMissing = type(result) == "table" and result.key == "mz.noGems"
	local text = L.t((type(result) == "table" and result.key) or fallbackKey or "error")
	UiTheme.playSound("UI_Error") setStatus(text, true)
	-- A read reconciles an uncertain response; no purchase or claim is repeated.
	invokeRewards("GetState", nil, nil, function()
		if not opened or spinning or busy or subModal then return end
		render()
		if gemsMissing and type(missing) == "number" and missing > 0 then
			local action = UiTheme.button({ parent = panel, position = statusLabel.Position - UDim2.fromOffset(0, 14), size = UDim2.new(statusLabel.Size.X.Scale, statusLabel.Size.X.Offset, 0, 44),
				text = L.t("mz.missingGems", { amount = missing }), textSize = UiTheme.TextSizes.XS, onClick = openGems })
			action.TextWrapped = true
		elseif type(missing) == "number" and missing > 0 then
			setStatus(L.t("mz.missingSoulsEarn", { amount = missing }), true)
		else setStatus(text, true) end
	end)
end

local function makeWeaponPreview3D(parent, wid, sid, rect, large, static)
	local vp = Instance.new("ViewportFrame")
	vp.Position = UDim2.fromOffset(rect[1], rect[2])
	vp.Size = UDim2.fromOffset(rect[3], rect[4])
	vp.BackgroundColor3 = C.BgPreview
	vp.BackgroundTransparency = large and 0.08 or 0.16
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

	local ok, model = pcall(Builder.buildModel, wid or "Sword", sid or "Default")
	if ok and model then
		model.Parent = world
		local cfBox, size = model:GetBoundingBox()
		local center = model.PrimaryPart and (model.PrimaryPart.CFrame:Inverse() * cfBox.Position) or Vector3.zero
		local base = CFrame.Angles(0, math.pi / 2, math.rad(26)) * CFrame.new(-center)
		local dist = math.max(size.X, size.Y, size.Z) * 0.88
		model:PivotTo(base)
		camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, dist), Vector3.zero)
		if not static then
			table.insert(spins3D, { vp = vp, model = model, camera = camera, base = base, distance = dist, phase = #spins3D * 0.5 })
		end
	end
	return vp
end

local function formatSectorLabel(sec)
	if not sec then return "?" end
	local k = sec.kind
	if k == "Gems" then return L.t("mz.gemsAmount", { amount = sec.amount or 0 }) end
	if k == "Souls" then
		return L.t("ui.rewards.sectorSouls", { amount = sec.amount or 75 })
	elseif k == "XP" then
		return L.t("ui.rewards.sectorXp", { amount = sec.amount or 150 })
	elseif k == "Boost" then
		local st = sec.stat or sec.boost
		return L.t(st == "XP" and "cx.reward.reveal.boostXp" or "cx.reward.reveal.boostSouls", {
			mult = sec.multiplier, minutes = (sec.seconds or 0) / REVEAL.SecondsPerMinute,
		})
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
		return UiTheme.Rarities.Mythic.bg
	elseif k == "Box" then
		return UiTheme.Rarities.Epic.bg
	elseif k == "Boost" then
		return UiTheme.Rarities.Rare.bg
	elseif k == "XP" then
		return C.SuccessDark
	end
	return (idx % 2 == 0) and C.BgPanelLight or C.IronDark
end

----------------------------------------------------------------------
-- Modal de Celebración de Premio (Ruleta, Cajas y Primeros Pasos)
----------------------------------------------------------------------
local function closeSubModal()
	oddsBoxId = nil oddsExpireAt = nil
	if subModal then
		subModal:Destroy()
		subModal = nil
	end
	if subModalSelection and subModalSelection.Parent then GuiService.SelectedObject = subModalSelection end
	subModalSelection = nil
end

-- These helpers describe a server reward, including the original skin on conversion.
local function rewardSkin(reward)
	return reward.duplicate or ((reward.kind == "Skin" or reward.kind == "WeeklySkin") and reward.id)
end
local function rewardRarity(reward)
	local skin = Skins.Data[rewardSkin(reward)]
	return reward.rarity or (skin and RewardsConfig and RewardsConfig.skinRarity(rewardSkin(reward), skin)) or "Common"
end
local function rewardColor(reward)
	if reward.kind == "Gems" then return C.Guard end
	local rarity = rewardRarity(reward)
	local spec = UiTheme.Rarities[rarity == "Exclusive" and "Mythic" or rarity] or UiTheme.Rarities.Common
	return spec.color
end
local function rewardName(reward)
	local skinId = rewardSkin(reward)
	if skinId then return L.t("skin." .. skinId) end
	if reward.kind == "Box" then return L.t("cx.reward.box." .. reward.id) end
	return formatSectorLabel(reward)
end

-- No invented skins, zero-probability rarities or staged legendary near misses.
local function boxCandidates(boxId)
	local pool = {}
	local box = state and state.boxes and state.boxes[boxId]
	for _, row in box and box.probabilities or {} do
		if (row.probability or 0) > 0 then
			if row.skins then
				for _, id in row.skins do
					table.insert(pool, { kind = "Skin", id = id, rarity = row.rarity })
				end
			else table.insert(pool, table.clone(row)) end
		end
	end
	return pool
end

local function usableViewport()
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(BASE_W, BASE_H)
	local topLeft, bottomRight = GuiService:GetGuiInset()
	return size - topLeft - bottomRight
end

local function fitOverlay(box, width, height)
	local size = Instance.new("UIScale") size.Parent = box
	local function fit()
		local view = usableViewport()
		size.Scale = math.min(1, (view.X - REVEAL.Margin * 2) / width, (view.Y - REVEAL.Margin * 2) / height)
	end
	fit()
	local connection = RunService.RenderStepped:Connect(fit)
	box.Destroying:Once(function() connection:Disconnect() end)
end

local function overlayBox(name, height, jackpot)
	local veil = Instance.new("TextButton")
	veil.Name = name veil.Size = UDim2.fromScale(1, 1)
	veil.Text = "" veil.AutoButtonColor = false veil.Selectable = false veil.Modal = true
	veil.BackgroundColor3 = C.BgAbyss veil.BackgroundTransparency = REVEAL.PointerAlpha
	veil.ZIndex = REVEAL.Layer.Veil veil.Parent = gui
	local view = usableViewport()
	local width = math.min(jackpot and REVEAL.JackpotWidth or REVEAL.Width, view.X - REVEAL.Margin * 2)
	local box = UiTheme.panel({ name = name .. "Card", parent = veil,
		anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromOffset(width, height), bg = C.BgPrimary, borderColor = C.GoldBright,
		borderThickness = UiTheme.Stroke.Heavy, zIndex = REVEAL.Layer.Box })
	fitOverlay(box, width, height)
	return veil, box
end

local function revealLabel(parent, text, y, height, size, color)
	return UiTheme.label({ parent = parent, position = UDim2.fromOffset(REVEAL.Margin, y),
		size = UDim2.new(1, -REVEAL.Margin * 2, 0, height), text = text, font = "Title",
		textSize = size, color = color or C.TextPrimary, alignX = Enum.TextXAlignment.Center, zIndex = REVEAL.Layer.Content })
end

-- The same curve drives both motion and ticks; skipping never calls the server.
local function animateReveal(job, seconds, update, power)
	local started = os.clock()
	while activeReveal == job and not job.skip and not job.cancelled do
		local t = math.clamp((os.clock() - started) / seconds, 0, 1)
		update(1 - (1 - t) ^ (power or REVEAL.BrakePower))
		if t >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	if activeReveal == job then update(1) end
end

local function animateWheel(job, options)
	local wheel, sector = options.wheel, options.sector
	local count = #options.sectors
	local step = REVEAL.Circle / count
	local start = wheel.Rotation % REVEAL.Circle
	local target = (REVEAL.Circle - (sector - 1) * step) % REVEAL.Circle
	local finish = start + REVEAL.Circle * REVEAL.WheelTurns + (target - start) % REVEAL.Circle
	local before = finish - step * REVEAL.FinalSectorFraction
	local lastTick = math.floor((start + step / 2) / step)
	local function rotate(angle)
		wheel.Rotation = angle
		local crossing = math.floor((angle + step / 2) / step)
		if not job.skip then
			for _ = lastTick + 1, crossing do UiTheme.playSound(REVEAL.TickSound) end
		end
		lastTick = crossing
	end
	animateReveal(job, REVEAL.WheelSeconds, function(t) rotate(start + (before - start) * t) end)
	animateReveal(job, REVEAL.WheelPause, function() end)
	animateReveal(job, REVEAL.WheelFinalSeconds, function(t) rotate(before + (finish - before) * t) end)
	currentWheelAngle = target wheel.Rotation = target
end

local function animateCarousel(job, stage, pool, reward)
	if #pool == 0 then pool = { reward } end
	local stride = REVEAL.CardWidth + REVEAL.CardGap
	local landing = REVEAL.StripCount - REVEAL.StripTail
	local strip = Instance.new("Frame")
	strip.Size = UDim2.fromOffset(REVEAL.StripCount * stride, REVEAL.CardHeight)
	strip.BackgroundTransparency = 1 strip.ZIndex = REVEAL.Layer.Content strip.Parent = stage
	local cards = {}
	-- Shuffle presentation candidates only; the winning entry is the response already granted.
	local visualRandom = Random.new()
	local order = table.clone(pool)
	for i = #order, 2, -1 do
		local j = visualRandom:NextInteger(1, i) order[i], order[j] = order[j], order[i]
	end
	for i = 1, REVEAL.StripCount do
		local item = i == landing and reward or order[(i - 1) % #order + 1]
		local card = UiTheme.panel({ parent = strip, position = UDim2.fromOffset((i - 1) * stride, 0),
			size = UDim2.fromOffset(REVEAL.CardWidth, REVEAL.CardHeight), bg = C.BgCard,
			borderColor = rewardColor(item), zIndex = REVEAL.Layer.Content })
		local label = revealLabel(card, rewardName(item), REVEAL.CardNameY, REVEAL.CardNameH, REVEAL.CardNameSize, rewardColor(item))
		label.FontFace = UiTheme.FontFaces.Bold
		revealLabel(card, L.t(rewardRarity(item)), REVEAL.CardHeight - REVEAL.CardRarityH, REVEAL.CardRarityH, UiTheme.TextSizes.XS, rewardColor(item))
		cards[i] = { frame = card, reward = item }
	end
	local pointer = Instance.new("Frame")
	pointer.AnchorPoint = Vector2.new(0.5, 0) pointer.Position = UDim2.fromScale(0.5, 0)
	pointer.Size = UDim2.new(0, REVEAL.PointerWidth, 1, 0) pointer.BorderSizePixel = 0
	pointer.BackgroundColor3 = C.GoldBright pointer.BackgroundTransparency = REVEAL.PointerAlpha
	pointer.ZIndex = REVEAL.Layer.Pointer pointer.Parent = stage
	local lastCenter = nil
	animateReveal(job, REVEAL.CarouselSeconds, function(t)
		local center = 1 + (landing - 1) * t
		strip.Position = UDim2.new(0.5, -REVEAL.CardWidth / 2 - (center - 1) * stride, 0.5, -REVEAL.CardHeight / 2)
		local nearest = math.floor(center + 0.5)
		if nearest == lastCenter then return end
		if lastCenter and not job.skip then UiTheme.playSound(REVEAL.TickSound) end
		lastCenter = nearest
		-- Only visible cards own 3D models, even for large relic catalogues.
		for i, entry in cards do
			local visible = math.abs(i - nearest) <= math.floor(REVEAL.CardPreviewLimit / 2)
			if entry.preview and not visible then entry.preview:Destroy() entry.preview = nil end
			if visible and not entry.preview then
				local sid = rewardSkin(entry.reward)
				local skin = sid and Skins.Data[sid]
				if skin then
					entry.preview = makeWeaponPreview3D(entry.frame, skin.weapon or "Sword", sid,
						{ REVEAL.CardGap, REVEAL.CardIconY, REVEAL.CardWidth - REVEAL.CardGap * 2, REVEAL.CardNameY - REVEAL.CardIconY }, false)
				else
					entry.preview = UiAssets.icon(entry.frame, entry.reward.kind == "Box" and "trophy" or (entry.reward.kind == "Gems" and "gem" or "soul"), REVEAL.CardIconSize, rewardColor(entry.reward))
					entry.preview.AnchorPoint = Vector2.new(0.5, 0) entry.preview.Position = UDim2.new(0.5, 0, 0, REVEAL.CardIconY)
				end
				entry.preview.ZIndex = REVEAL.Layer.Preview
			end
		end
	end)
	animateReveal(job, REVEAL.SettleSeconds, function() end)
end


local function drawChest(parent, tier, z)
 local size = tier.size
 if tier.image ~= "" then
  -- 11/11: con imagen el cofre va sin marco y más grande (el arte ya trae su forma y su brillo)
  local holder = Instance.new("Frame")
  holder.Name = "ChestArt" holder.AnchorPoint = Vector2.new(0.5, 0.5) holder.Position = UDim2.fromScale(0.5, 0.5)
  holder.Size = UDim2.fromOffset(size * REVEAL.ChestArtScale, size * REVEAL.ChestArtScale)
  holder.BackgroundTransparency = 1 holder.ZIndex = z holder.Parent = parent
  local image = Instance.new("ImageLabel")
  image.Size = UDim2.fromScale(1, 1) image.ScaleType = Enum.ScaleType.Fit
  image.BackgroundTransparency = 1 image.Image = tier.image image.ZIndex = z + 1 image.Parent = holder
  return holder, nil, image
 end
 local frame = UiTheme.panel({ parent = parent, name = "ChestArt", anchor = Vector2.new(0.5, 0.5),
  position = UDim2.fromScale(0.5, 0.5), size = UDim2.fromOffset(size * 1.35, size),
  bg = tier.bg, borderColor = tier.color, borderThickness = tier.stroke, ornaments = true, zIndex = z })
 if false then
  local image = Instance.new("ImageLabel")
  image.Size = UDim2.fromScale(1, 1) image.ScaleType = Enum.ScaleType.Fit
  image.BackgroundTransparency = 1 image.Image = tier.image image.ZIndex = z + 1 image.Parent = frame
  return frame, nil, image
 end
 local lid = UiTheme.panel({ parent = frame, size = UDim2.new(1, 0, 0.27, 0),
  bg = tier.color, borderColor = tier.color, zIndex = z + 2 })
 local emblem = UiAssets.icon(frame, tier.icon, math.floor(size * 0.56), tier.color)
 emblem.AnchorPoint = Vector2.new(0.5, 0.5) emblem.Position = UDim2.fromScale(0.5, 0.63) emblem.ZIndex = z + 1
 if tier.lightning then
  for _, x in { 0.18, 0.82 } do
   local spark = UiAssets.icon(frame, "stamina", math.floor(size * 0.32), C.TextPrimary)
   spark.AnchorPoint = Vector2.new(0.5, 0.5) spark.Position = UDim2.fromScale(x, 0.45) spark.ZIndex = z + 3
  end
 end
 return frame, lid
end

local function animateCard(job, stage, tier)
	tier = tier or CHEST_TIERS.Relic
	local revealTier = table.clone(tier)
	revealTier.size = math.floor(tier.size * 1.55)
	local chest, lid, image = drawChest(stage, revealTier, REVEAL.Layer.Content)
	animateReveal(job, REVEAL.FixedSeconds, function(t)
		chest.Rotation = math.sin(t * math.pi * REVEAL.ShakeCycles) * REVEAL.ShakeDegrees
	end, 1)
	animateReveal(job, REVEAL.OpenSeconds, function(t)
		if lid then
			lid.Position = UDim2.fromOffset(0, -REVEAL.LidLift * t) lid.Rotation = REVEAL.LidRotation * t
		elseif image and t >= 0.5 and tier.openedImage ~= "" then image.Image = tier.openedImage end
	end)
end


local function showSkipPass(job)
 if job.offer or job.ready then return end
 local veil, card = overlayBox("SkipPass", REVEAL.ConfirmHeight)
 job.offer = veil
 local before = GuiService.SelectedObject
 local function close()
  if job.offer ~= veil then return end
  job.offer = nil veil:Destroy()
  if before and before.Parent then GuiService.SelectedObject = before end
 end
 revealLabel(card, L.t("mz.pass.SkipOpening"), 12, 48, UiTheme.TextSizes.XL, C.GoldBright)
 local note = revealLabel(card, L.t("loading"), 64, 72, UiTheme.TextSizes.MD)
 local cancel = UiTheme.button({ parent = card, anchor = Vector2.new(0, 1), position = UDim2.new(0, 16, 1, -14),
  size = UDim2.new(0.48, -16, 0, 46), text = L.t("close"), zIndex = REVEAL.Layer.Button, onClick = close })
 if Device.isGamepad() then GuiService.SelectedObject = cancel end
 task.spawn(function()
  local entries = Vault.catalog("SkipOpening")
  if job.offer ~= veil or not veil.Parent then return end
  local pass = entries and entries[1]
  if not pass or not pass.available then note.Text = L.t("mz.noOffers") return end
  note.Text = L.t("mz.pass.SkipOpening.desc")
  Vault.priceButton({ parent = card, anchor = Vector2.new(1, 1), position = UDim2.new(1, -16, 1, -14),
   size = UDim2.new(0.48, -16, 0, 46), zIndex = REVEAL.Layer.Button, onClick = function()
    local ok, reason = Vault.prompt(pass.key)
    if not veil.Parent then return end
    if ok then close() else note.Text = L.t("mz.offer." .. (reason or "unavailable")) end
   end }, pass)
 end)
end

local function runCelebration(job)
	local reward, options = job.reward, job.options
	local jackpot = options.jackpot == true
	local extraHeight = jackpot and REVEAL.JackpotExtraHeight or 0
	local veil, box = overlayBox("RewardReveal", REVEAL.Height + extraHeight, jackpot)
	job.veil = veil
	local previousSelection = GuiService.SelectedObject
	local heading = revealLabel(box, L.t("cx.reward.reveal.opening"), REVEAL.TitleY, REVEAL.TitleH, UiTheme.TextSizes.XXL, C.GoldBright)
	local stage = Instance.new("CanvasGroup")
	stage.Position = UDim2.new(0, REVEAL.Margin, 0, REVEAL.StageY)
	stage.Size = UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.StageH + extraHeight)
	stage.BackgroundTransparency = 1 stage.ClipsDescendants = true stage.ZIndex = REVEAL.Layer.Stage stage.Parent = box
	local function canSkip() return player:GetAttribute("Pass_SkipOpening") == true end
	local function activate()
		if job.ready then job.dismiss = true
		elseif canSkip() then job.skip = true
		else showSkipPass(job) end
	end
	local button = UiTheme.button({ parent = box, anchor = Vector2.new(1, 1), position = UDim2.new(1, -REVEAL.Margin, 1, -REVEAL.ButtonBottom),
		size = UDim2.fromOffset(128, REVEAL.ButtonH), text = canSkip() and L.t("mz.skipLocked") or ("🔒 " .. L.t("mz.skipLocked")),
		textSize = UiTheme.TextSizes.XS, variant = "secondary", zIndex = REVEAL.Layer.Button, onClick = activate })
	local passChanged = player:GetAttributeChangedSignal("Pass_SkipOpening"):Connect(function()
		if canSkip() and not job.ready then button.Text = L.t("mz.skipLocked") end
	end)
	job.passChanged = passChanged
	veil.Activated:Connect(function() if canSkip() or job.ready then activate() end end)
	local input = game:GetService("ContextActionService")
	input:BindActionAtPriority("RewardRevealSkip", function(_, inputState)
		if job.offer then return Enum.ContextActionResult.Pass end
		if inputState == Enum.UserInputState.Begin then activate() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter, Enum.KeyCode.ButtonA)
	job.input = input
	if Device.isGamepad() then GuiService.SelectedObject = button end
	if options.wheel and options.wheel.Parent then
		box.Visible = false veil.BackgroundTransparency = 1
		-- Keep a physical-size skip target while the original wheel is visible.
		button.Parent = veil
		animateWheel(job, options)
		button.Parent = box box.Visible = true veil.BackgroundTransparency = REVEAL.PointerAlpha
	elseif options.pool then
		animateCard(job, stage, CHEST_TIERS[options.box])
		stage:ClearAllChildren()
		animateCarousel(job, stage, options.pool, reward)
	else animateCard(job, stage) end
	stage:ClearAllChildren()
	local color = rewardColor(reward)
	heading.Text = L.t(jackpot and "cx.reward.reveal.jackpot" or "ui.rewards.prizeWon") heading.TextColor3 = color
	local sid = rewardSkin(reward)
	local skin = sid and Skins.Data[sid]
	if skin then
		local vp = makeWeaponPreview3D(stage, skin.weapon or "Sword", sid, { 0, 0, 0, 0 }, true)
		vp.Size = UDim2.fromScale(1, 1) vp.ZIndex = REVEAL.Layer.Preview
	else
		local icon = UiAssets.icon(stage, reward.kind == "Box" and "trophy" or (reward.kind == "XP" and "mission" or (reward.kind == "Gems" and "gem" or "soul")), REVEAL.ChestSize, color)
		icon.AnchorPoint = Vector2.new(0.5, 0.5) icon.Position = UDim2.fromScale(0.5, 0.5) icon.ZIndex = REVEAL.Layer.Preview
	end
	local name = revealLabel(box, rewardName(reward), REVEAL.NameY + extraHeight, REVEAL.NameH, jackpot and REVEAL.JackpotNameSize or REVEAL.NameSize, color)
	name.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint") limit.MaxTextSize = name.TextSize limit.MinTextSize = REVEAL.DetailSize limit.Parent = name
	local detail = L.t(rewardRarity(reward))
	if reward.duplicate then detail = detail .. " · " .. L.t("ui.rewards.duplicateConverted", { skin = rewardName(reward), amount = reward.amount }) end
	if reward.kind == "Boost" then detail = detail .. " · " .. L.t("cx.reward.reveal.boostTime", { seconds = reward.seconds }) end
	if options.bonus then detail = detail .. " · " .. L.t("cx.reward.reveal.bonus", { reward = rewardName(options.bonus) }) end
	revealLabel(box, detail, REVEAL.DetailY + extraHeight, REVEAL.DetailH, REVEAL.DetailSize, reward.duplicate and C.Coins or color)
	local stroke = box:FindFirstChildOfClass("UIStroke") if stroke then stroke.Color = color end
	local flash = Instance.new("Frame") flash.Size = UDim2.fromScale(1, 1) flash.BorderSizePixel = 0
	flash.BackgroundColor3 = color flash.BackgroundTransparency = jackpot and REVEAL.JackpotFlashTransparency or REVEAL.FlashTransparency
	flash.ZIndex = REVEAL.Layer.Flash flash.Parent = veil
	TweenService:Create(flash, TweenInfo.new(jackpot and REVEAL.JackpotFlashSeconds or REVEAL.FlashSeconds), { BackgroundTransparency = 1 }):Play()
	UiTheme.playSound(REVEAL.WinSound)
	local duration = jackpot and REVEAL.JackpotSeconds or REVEAL.RevealSeconds
	animateReveal(job, duration, function(t)
		stage.GroupTransparency = 1 - t name.TextTransparency = 1 - t
	end)
	job.ready = true
	button.Text = L.t("ui.match.continue")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -REVEAL.ButtonBottom)
	button.Size = UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.ButtonH)
	if Device.isGamepad() and not job.offer then GuiService.SelectedObject = button end
	-- Result remains readable until Continue; this user-controlled hold is not animation time.
	while not job.dismiss do RunService.RenderStepped:Wait() end
	input:UnbindAction("RewardRevealSkip") job.input = nil
	veil:Destroy()
	if job.passChanged then job.passChanged:Disconnect() job.passChanged = nil end
	if previousSelection and previousSelection.Parent then GuiService.SelectedObject = previousSelection else GuiService.SelectedObject = nil end
end

function showPrizeCelebration(reward, options)
	if type(reward) ~= "table" then return end
	closeSubModal()
	table.insert(revealQueue, { reward = reward, options = type(options) == "table" and options or {} })
	if revealRunning then return end
	revealRunning = true spinning = true
	task.spawn(function()
		while #revealQueue > 0 do
			local job = table.remove(revealQueue, 1) activeReveal = job
			if player:GetAttribute("InMatch") then job.cancelled = true job.dismiss = true end
			local ok, message = pcall(runCelebration, job)
			if job.input then job.input:UnbindAction("RewardRevealSkip") end
			if job.passChanged then job.passChanged:Disconnect() end
			if job.offer then job.offer:Destroy() end
			if job.veil and job.veil.Parent then job.veil:Destroy() end
			if not ok then warn("[Rewards] Reveal: " .. tostring(message)) end
		end
		activeReveal = nil revealRunning = false spinning = false
		if player:GetAttribute("InMatch") or player:GetAttribute("ShopOpen") or player:GetAttribute("ArmoryOpen") or player:GetAttribute("SettingsOpen") then setOpen(false) end
		refreshState(true)
	end)
end

function showPaidConfirmation(onConfirm)
	if busy or spinning or not serverStateReady or not state.paidSpinPrice then return end
	closeSubModal()
	local price, used, resetAt = state.paidSpinPrice, state.paidSpins, state.resetAt
	local veil, box = overlayBox("ConfirmPaidSpin", REVEAL.ConfirmHeight)
	subModalSelection = GuiService.SelectedObject
	subModal = veil
	revealLabel(box, L.t("cx.reward.spin.confirm", { price = price, remaining = state.paidSpinsRemaining, balance = state.souls }),
		REVEAL.ConfirmTextY, REVEAL.ConfirmTextH, UiTheme.TextSizes.LG, C.GoldBright)
	local accepted = false
	local cancel = UiTheme.button({ parent = box, anchor = Vector2.new(0, 1), position = UDim2.new(0, REVEAL.Margin, 1, -REVEAL.Margin),
		size = UDim2.new(0.5, -REVEAL.Margin - REVEAL.ConfirmGap / 2, 0, REVEAL.ButtonH), text = L.t("cx.reward.spin.cancel"), zIndex = REVEAL.Layer.Preview, onClick = closeSubModal })
	UiTheme.button({ parent = box, anchor = Vector2.new(1, 1), position = UDim2.new(1, -REVEAL.Margin, 1, -REVEAL.Margin),
		size = UDim2.new(0.5, -REVEAL.Margin - REVEAL.ConfirmGap / 2, 0, REVEAL.ButtonH), text = L.t("cx.reward.spin.accept", { price = price }), variant = "gold", zIndex = REVEAL.Layer.Preview,
		onClick = function()
			if accepted then return end accepted = true
			invokeRewards("GetState", nil, nil, function(ok)
				if subModal ~= veil then return end
				closeSubModal()
				if not ok or state.paidSpinPrice ~= price or state.paidSpins ~= used or state.resetAt ~= resetAt then
					rewardError({ key = "cx.reward.spin.changed" }) return
				end
				onConfirm()
			end)
		end })
	if Device.isGamepad() then GuiService.SelectedObject = cancel end
end

----------------------------------------------------------------------
-- Vista previa de los premios de un cofre o de la ruleta.
----------------------------------------------------------------------
local function boxOpenButton(props, id, spec)
 local hasOwned = spec and spec.openable > 0
 local canBuy = spec and spec.canBuy
 local usesGems = spec and spec.currency == "Gems"
 local missing = not hasOwned and canBuy and math.max(0, spec.price - (usesGems and state.gems or state.souls)) or 0
 local ready = serverStateReady and spec ~= nil
 local label = L.t("loading")
 if ready then
  if hasOwned then label = L.t("ui.rewards.openOwned", { count = spec.openable })
  elseif not canBuy then label = L.t("mz.restricted")
  elseif missing > 0 then label = L.t(usesGems and "mz.missingGems" or "mz.missingSoulsEarn", { amount = missing })
  else label = L.t(usesGems and "mz.buyBoxGems" or "ui.rewards.buyAndOpen", { price = spec.price }) end
 end
 props.name = "OpenBox_" .. id
 props.text = label
 props.font = "Title"
 props.textSize = UiTheme.TextSizes.MD
 props.variant = "primary"
 props.disabled = not ready or (not hasOwned and not canBuy) or (missing > 0 and not usesGems)
 props.onClick = function()
  if busy or spinning then return end
  if missing > 0 then closeSubModal() if usesGems then openGems() end return end
  local candidates = boxCandidates(id)
  invokeRewards("OpenBox", id, hasOwned and "Owned" or "Buy", function(ok, result)
   if ok and type(result) == "table" and result.reward then
    closeSubModal()
    showPrizeCelebration(result.reward, { pool = candidates, box = id })
   elseif type(result) == "table" and result.key == "mz.oddsChanged" and oddsBoxId == id then
    local current = subModal
    invokeRewards("GetState", nil, nil, function(read)
     if read and subModal == current then showOddsModal(id, result.key) end
    end)
   else
    closeSubModal()
    rewardError(result, "noCoins")
   end
  end, spec.oddsVersion)
 end
 local button = UiTheme.button(props)
 button.TextWrapped = true button.TextScaled = true
 UiTheme.textConstraint(button, UiTheme.TextSizes.XS, UiTheme.TextSizes.MD)
 return button
end

local ODDS_RARITIES = { "Exclusive", "Legendary", "Epic", "Rare", "Common" }
local ODDS_ICONS = { Souls = "soul", Gems = "gem", Boost = "stamina", XP = "stamina", Box = "mission" }

function showOddsModal(id, messageKey)
 if spinning or busy or not serverStateReady then return end
 local spec = id and state.boxes and state.boxes[id]
 if id and not spec then return end
 closeSubModal()
 local veil, box = overlayBox("RewardOdds", REVEAL.OddsHeight)
 subModal = veil subModalSelection = GuiService.SelectedObject oddsBoxId = id
 local title = revealLabel(box, L.t(spec and spec.nameKey or "ui.rewards.oddsTitle"),
  REVEAL.TitleY, REVEAL.TitleH, UiTheme.TextSizes.XL, C.GoldBright)
 title.TextScaled = true
 UiTheme.textConstraint(title, UiTheme.TextSizes.SM, UiTheme.TextSizes.XL)

 local scroll = Instance.new("ScrollingFrame")
 scroll.Position = UDim2.fromOffset(REVEAL.Margin, REVEAL.StageY)
 scroll.Size = UDim2.new(1, -REVEAL.Margin * 2, 1, -REVEAL.StageY - REVEAL.ButtonH - REVEAL.Margin * 2)
 scroll.BackgroundTransparency = 1 scroll.BorderSizePixel = 0 scroll.ZIndex = REVEAL.Layer.Content
 scroll.ScrollBarThickness = UiTheme.Spacing.XXS scroll.CanvasSize = UDim2.new() scroll.Parent = box

 local y = 0
 local firstRow, lastRow
 local function section(value, height, color)
  height = height or REVEAL.OddsHeaderHeight
  revealLabel(scroll, value, y, height, UiTheme.TextSizes.SM, color or C.GoldBright)
  y += height
 end
 local activeLuck = spec and state.luck and state.luck.multiplier > 1
 oddsExpireAt = activeLuck and state.luck.endsAt or nil
 local function percent(probability) return Format.percent(probability, L.language()) end
 local function row(name, color, probability, baseProbability, item)
  local formatted = percent(probability)
  if activeLuck then formatted = percent(baseProbability) .. " →\n" .. formatted end
  local height = item and REVEAL.OddsRowHeight or REVEAL.OddsHeaderHeight + 8
  local card = UiTheme.panel({ parent = scroll, position = UDim2.fromOffset(0, y), size = UDim2.new(1, -REVEAL.CardGap, 0, height),
   borderColor = color, zIndex = REVEAL.Layer.Content })
  local rowTop = y
  card.Selectable = true
  card.SelectionGained:Connect(function()
   local top = scroll.CanvasPosition.Y
   local bottom = top + scroll.AbsoluteWindowSize.Y
   local target = rowTop < top and rowTop or math.max(top, rowTop + height - (bottom - top))
   scroll.CanvasPosition = Vector2.new(0, target)
  end)
  if lastRow then lastRow.NextSelectionDown = card card.NextSelectionUp = lastRow else firstRow = card end
  lastRow = card
  local inset = REVEAL.CardGap
  if item then
   local sid = rewardSkin(item)
   local skin = sid and Skins.Data[sid]
   if skin then
    local thumbnail = makeWeaponPreview3D(card, skin.weapon or "Sword", sid, { 6, 6, 52, height - 12 }, false, true)
    thumbnail.ZIndex = REVEAL.Layer.Preview
   else
    local icon = UiAssets.icon(card, ODDS_ICONS[item.kind] or "rarity_rare", 24, color)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, 20, 0.5, 0)
    icon.ZIndex = REVEAL.Layer.Preview
   end
   inset = 66
  end
  UiTheme.label({ parent = card, position = UDim2.fromOffset(inset, 0),
   size = UDim2.new(REVEAL.OddsNameFraction, -inset - 4, 1, 0), text = name,
   textSize = REVEAL.CompactTextSize, color = color, zIndex = REVEAL.Layer.Preview })
  UiTheme.label({ parent = card, position = UDim2.fromScale(REVEAL.OddsNameFraction, 0),
   size = UDim2.new(1 - REVEAL.OddsNameFraction, -REVEAL.CardGap, 1, 0), text = formatted,
   textSize = REVEAL.CompactTextSize, alignX = Enum.TextXAlignment.Right, zIndex = REVEAL.Layer.Preview })
  y += height + 4
 end
 if messageKey then section(L.t(messageKey), 48, C.TextPrimary) end
 if spec then
  section(L.t("mz.boxRarities"))
  if activeLuck then section(L.t("mz.oddsCompare")) end
  local tiers, other, baseOther = {}, 0, 0
  for _, item in spec.probabilities do
   if item.skins then tiers[item.rarity] = item
   else other += item.probability baseOther += item.baseProbability end
  end
  for _, rarity in ODDS_RARITIES do
   local item = tiers[rarity]
   if item then row(L.t(rarity), rewardColor(item), item.probability, item.baseProbability) end
  end
  if other > 0 or baseOther > 0 then row(L.t("mz.otherPrizes"), C.TextPrimary, other, baseOther) end
  for _, guarantee in spec.guarantees do
   local color = rewardColor(guarantee)
   local key = guarantee.remaining == 1 and "mz.guaranteeNext" or "mz.guaranteeIn"
   local rarity = L.t(guarantee.rarity)
   if guarantee.rarity ~= "Exclusive" then rarity = L.t("mz.rarityOrHigher", { rarity = rarity }) end
   section(L.t(key, { rarity = rarity, count = guarantee.remaining }), 40, color)
  end
 end
 section(L.t("mz.duplicate", { percent = percent(state.duplicateFraction) }), 42, C.TextSecondary)
 section(L.t("mz.oddsRounded"), 42, C.TextSecondary)
 if spec then
  section(L.t("mz.viewRewards"))
  for _, item in spec.probabilities do
   if not item.skins then
    row(rewardName(item), rewardColor(item), item.probability, item.baseProbability, item)
   end
  end
  for _, rarity in ODDS_RARITIES do
   local group
   for _, item in spec.probabilities do if item.skins and item.rarity == rarity then group = item break end end
   if group then
    section(L.t(rarity), nil, rewardColor(group))
    for _, sid in group.skins do
     local item = { kind = "Skin", id = sid, rarity = rarity }
     row(rewardName(item), rewardColor(item), group.probabilityPerSkin, group.baseProbabilityPerSkin, item)
    end
   end
  end
 else
  local tutorial = state.tutorial and state.tutorial.spinAvailable
  for _, item in state.roulette or DEFAULT_SECTORS do
   local chance = tutorial and item.tutorialProbability or item.effectiveProbability
   row(rewardName(item), rewardColor(item), chance or item.probability, nil, item)
  end
 end
 scroll.CanvasSize = UDim2.fromOffset(0, y)
 local close = UiTheme.button({ parent = box, anchor = Vector2.new(0, 1),
  position = UDim2.new(0, REVEAL.Margin, 1, -REVEAL.ButtonBottom),
  size = spec and UDim2.new(0.34, -REVEAL.Margin, 0, REVEAL.ButtonH) or UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.ButtonH),
  text = L.t("close"), zIndex = REVEAL.Layer.Button, onClick = closeSubModal })
 if spec then
  local open = boxOpenButton({ parent = box, anchor = Vector2.new(1, 1),
   position = UDim2.new(1, -REVEAL.Margin, 1, -REVEAL.ButtonBottom),
   size = UDim2.new(0.66, -REVEAL.Margin - REVEAL.CardGap, 0, REVEAL.ButtonH), zIndex = REVEAL.Layer.Button }, id, spec)
  close.NextSelectionRight = open
  open.NextSelectionLeft = close
 end
 if firstRow then
  close.NextSelectionUp = firstRow
  firstRow.NextSelectionUp = close
  lastRow.NextSelectionDown = close
 end
 if Device.isGamepad() then GuiService.SelectedObject = close end
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
			if Device.isGamepad() then GuiService.SelectedObject = nextBtn end
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
						invokeRewards("ChooseStarter", skinId, nil, function(ok, res)
							if ok then
								local shopRF = remotes and remotes:FindFirstChild("Shop")
								if shopRF and shopRF:IsA("RemoteFunction") then
									pcall(function() shopRF:InvokeServer("Equip", skinId) end)
								end
								if welcomeVeil then
									welcomeVeil:Destroy()
									welcomeVeil = nil
								end
								if type(res) == "table" and res.reward then showPrizeCelebration(res.reward) end
								refreshState(true)
							end
						end)
					end,
				})
				if idx == 1 and Device.isGamepad() then
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
local function claimFixed(action)
	invokeRewards(action, nil, nil, function(ok, res)
		if ok and type(res) == "table" and res.reward then showPrizeCelebration(res.reward)
		else rewardError(res) end
	end)
end

local function weeklyCard(parent, width, y, compact)
	local weekly = state.weekly or {}
	local height = compact and REVEAL.WeeklyHeight or REVEAL.DesktopWeeklyHeight
	local card = UiTheme.panel({ name = "WeeklyClaim", parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, height) })
	local text = L.t(weekly.nameKey or "cx.weekly.Win", { goal = weekly.goal })
	text = text .. " · " .. tostring(weekly.progress or 0) .. "/" .. tostring(weekly.goal or 0)
	UiTheme.label({ parent = card, position = UDim2.fromOffset(REVEAL.Margin, 0),
		size = compact and UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.ButtonH) or UDim2.new(0.5, -REVEAL.Margin * 2, 1, 0), text = text,
		textSize = REVEAL.CompactTextSize, color = C.GoldBright })
	UiTheme.button({ parent = card, anchor = Vector2.new(1, 1), position = UDim2.new(1, -REVEAL.Margin, 1, -REVEAL.MobileGap),
		size = compact and UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.ButtonH) or UDim2.new(0.5, 0, 0, REVEAL.ButtonH),
		text = L.t(weekly.claimed and "ui.missions.claimed" or "cx.reward.weekly.claim"), textSize = REVEAL.CompactTextSize,
		disabled = weekly.claimed or (weekly.progress or 0) < (weekly.goal or math.huge),
		onClick = function() claimFixed("ClaimWeekly") end })
	return height + REVEAL.MobileGap
end

local function compactStreak(parent, width)
	local y = weeklyCard(parent, width, 0, true)
	if state.returnNotice then
		UiTheme.label({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, REVEAL.ButtonH),
			text = L.t("cx.reward.return"), textSize = REVEAL.CompactTextSize, color = C.GoldBright })
		y += REVEAL.ButtonH + REVEAL.MobileGap
	end
	local streak = state.streak or {}
	local rewards = streak.rewards or {}
	UiTheme.label({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, REVEAL.CompactTitleHeight),
		text = L.t("ui.rewards.streakTitle"), font = "Title", color = C.GoldBright })
	y += REVEAL.CompactTitleHeight
	UiTheme.button({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, REVEAL.ButtonH),
		text = L.t(streak.canClaim and "ui.rewards.claimStreak" or "ui.rewards.streakClaimed", { d = (streak.day or 0) % math.max(1, #rewards) + 1 }),
		disabled = not streak.canClaim, onClick = function() claimFixed("ClaimStreak") end })
	y += REVEAL.ButtonH + REVEAL.MobileGap
	for day, value in rewards do
		local text = L.t("ui.rewards.dayN", { d = day }) .. " · "
		text = text .. (type(value) == "number" and L.t("cx.currency.souls", { amount = value }) or L.t("cx.reward.box." .. value))
		UiTheme.label({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, REVEAL.CompactRowHeight),
			text = text, textSize = UiTheme.TextSizes.MD, color = day <= (streak.day or 0) and C.Success or C.TextPrimary })
		y += REVEAL.CompactRowHeight
	end
	local first = state.firstSteps or {}
	UiTheme.label({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, REVEAL.CompactTitleHeight),
		text = L.t("ui.rewards.firstStepsTitle"), font = "Title", color = C.GoldBright })
	y += REVEAL.CompactTitleHeight
	UiTheme.button({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, REVEAL.ButtonH),
		text = L.t(first.claimed and "ui.missions.claimed" or "ui.rewards.claimEpic"), disabled = not first.canClaim,
		onClick = function() claimFixed("ClaimFirstSteps") end })
	y += REVEAL.ButtonH + REVEAL.MobileGap
	for _, step in first.list or {} do
		UiTheme.label({ parent = parent, position = UDim2.fromOffset(0, y), size = UDim2.fromOffset(width, REVEAL.CompactStepHeight),
			text = L.t(step.nameKey or ("ui.rewards.step." .. step.id), { p = step.progress, g = step.goal }) .. " · " .. tostring(step.progress) .. "/" .. tostring(step.goal),
			textSize = REVEAL.CompactTextSize, color = step.progress >= step.goal and C.Success or C.TextPrimary })
		y += REVEAL.CompactStepHeight
	end
	parent.CanvasSize = UDim2.fromOffset(0, y)
end

function render()
	if spinning or busy then return end
	table.clear(spins3D)
	closeSubModal()
	if not state then
		state = buildFallbackState()
	end

	luckLabel = nil luckTimerSecond = -1
	local focusedBoxButtonName = nil
	if boxScroller then
		boxScrollPosition = boxScroller.CanvasPosition
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(boxScroller) then
			focusedBoxButtonName = selected.Name
		end
		boxScroller = nil
	end

	for _, ch in panel:GetChildren() do
		if ch ~= scale and not ch:IsA("UIStroke") and not ch:IsA("UICorner") and not ch:IsA("UIGradient") and ch.Name ~= "Ornaments" then
			ch:Destroy()
		end
	end

	local viewport = usableViewport()
	renderedViewport = viewport
	local mobile = viewport.X < REVEAL.MobileBreakpoint
	local compact = mobile and tab ~= "Collection"
	local width = compact and math.min(REVEAL.CompactWidth, viewport.X - REVEAL.Margin * 2) or (mobile and 720 or BASE_W)
	local height = compact and math.clamp(viewport.Y - REVEAL.Margin * 2, 560, REVEAL.CompactMaxHeight) or (mobile and 620 or BASE_H)
	panel.Size = UDim2.fromOffset(width, height)
	scale.Scale = compact and math.min(1, (viewport.Y - REVEAL.Margin * 2) / height) or UiTheme.computeScale(viewport, width, height, player)

	-- Cabecera
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, compact and REVEAL.CompactHeader or 58)
	header.BackgroundColor3 = C.BgHeader
	header.BorderSizePixel = 0
	header.Parent = panel
	UiTheme.corner(header, UiTheme.Radius.MD)

	local crest = UiAssets.icon(header, "trophy", 26, C.GoldBright)
	crest.AnchorPoint = Vector2.new(0, 0.5)
	crest.Position = compact and UDim2.new(0, 18, 0, REVEAL.CompactTitleHeight / 2) or UDim2.new(0, 18, 0.5, 0)

	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 6),
		size = compact and UDim2.new(1, -REVEAL.HeaderTextX - 94, 0, REVEAL.CompactTitleHeight) or UDim2.fromOffset(420, 28),
		text = L.t("ui.rewards.title"),
		font = "Title",
		textSize = UiTheme.TextSizes.XL,
		color = C.GoldBright,
	})
	UiTheme.label({
		parent = header,
		position = UDim2.fromOffset(52, 32),
		size = compact and UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.CompactTitleHeight) or UDim2.fromOffset(460, 18),
		text = compact and "" or L.t("ui.rewards.subtitle"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextSecondary,
	})

	local soulsAmount = Vault.souls(player)
	local gemsAmount = player:GetAttribute("Gems") or state.gems or 0
	local balanceW = compact and math.floor((width - 48) / 2) or 152
	balancePill(header, compact and UDim2.new(0.5, -4, 0, 78) or UDim2.new(1, -290, 0.5, 0),
		UDim2.fromOffset(balanceW, 44), "Coins", soulsAmount)
	balancePill(header, compact and UDim2.new(1, -16, 0, 78) or UDim2.new(1, -132, 0.5, 0),
		UDim2.fromOffset(balanceW, 44), "Gems", gemsAmount, openGems)

	UiTheme.button({
		name = "CloseButton",
		parent = header,
		anchor = Vector2.new(1, 0.5),
		position = compact and UDim2.new(1, -REVEAL.Margin, 0, 28) or UDim2.new(1, -16, 0.5, 0),
		size = compact and UDim2.fromOffset(78, REVEAL.ButtonH) or UDim2.fromOffset(104, 38),
		text = L.t("close"),
		variant = "secondary",
		onClick = function()
			if not spinning then setOpen(false) end
		end,
	})

	-- Barra de 4 pestañas con avisos rojos ("!")
	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "TabsBar"
	tabsBar.Position = UDim2.fromOffset(20, compact and REVEAL.CompactHeader + REVEAL.MobileGap or 66)
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
		{ id = "Boxes",      label = L.t("ui.rewards.tab.Boxes"),      alert = (function() local n = 0 for _, b in state.boxes or {} do n += b.count or 0 end return n > 0 end)() },
		{ id = "Streak",     label = L.t("ui.rewards.tab.Streak"),     alert = (notif.streak == true) or (notif.firstSteps == true) or (notif.weekly == true) },
		{ id = "Collection", label = L.t("ui.rewards.tab.Collection"), alert = false },
	}
	local firstTabBtn = nil
	for i, def in tabDefs do
		local b = UiTheme.tabButton({
			name = "Tab_" .. def.id,
			parent = tabsBar,
			layoutOrder = i,
			size = compact and UDim2.fromOffset((width - 40 - 8 * 3) / #tabDefs, REVEAL.MobileTabHeight) or UDim2.fromOffset(mobile and 164 or 210, 42),
			text = def.label,
			active = tab == def.id,
			onClick = function()
				if spinning or busy then return end
				tab = def.id
				render()
			end,
		})
		if compact then b.TextSize = REVEAL.CompactTextSize b.TextWrapped = true end
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

	local bodyY = compact and REVEAL.CompactBodyY or 116
	local bodyH = height - bodyY - 40
	local body = Instance.new(compact and "ScrollingFrame" or "Frame")
	if compact then
		body.CanvasSize = UDim2.new() body.ScrollBarThickness = UiTheme.Spacing.XXS body.BorderSizePixel = 0
	end
	body.Name = "TabBody"
	body.Position = UDim2.fromOffset(20, bodyY)
	body.Size = UDim2.fromOffset(width - 40, bodyH)
	body.BackgroundTransparency = 1
	body.Parent = panel

	------------------------------------------------------------------
	-- PESTAÑA 1: RULETA DEL OCASO (8 sectores)
	------------------------------------------------------------------
	if tab == "Roulette" then
		local bodyH = compact and REVEAL.MobileWheelHeight or bodyH
		local leftW = compact and width - 40 or math.floor((width - 54) * 0.56)
		local rightW = compact and leftW or (width - 40) - leftW - 14
		if compact then body.CanvasSize = UDim2.fromOffset(0, bodyH * 2 + REVEAL.MobileGap) end

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
			size = UDim2.fromOffset(154, REVEAL.ButtonH),
			text = L.t("ui.rewards.oddsBtn"),
			variant = "secondary",
			textSize = UiTheme.TextSizes.XS,
			disabled = not serverStateReady,
			onClick = function() showOddsModal() end,
		})

		-- Rueda circular de 8 sectores
		local wheelDia = math.min(REVEAL.WheelDiameter, leftW - REVEAL.Margin * 2, bodyH - REVEAL.WheelTop - REVEAL.WheelControlsHeight)
		local wheelOuter = Instance.new("Frame")
		wheelOuter.Name = "WheelOuter"
		wheelOuter.AnchorPoint = Vector2.new(0.5, 0)
		wheelOuter.Position = UDim2.new(0.5, 0, 0, REVEAL.WheelTop)
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
		pointer.Position = UDim2.new(0.5, 0, 0, REVEAL.WheelTop - REVEAL.MobileGap)
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
			position = UDim2.new(0.08, 0, 1, -REVEAL.PityBottom),
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
		elseif state.vipAvailable then
			spinMode = "VIP"
			spinBtnText = state.vipFallbackSouls and L.t("mz.vipSouls", { amount = state.vipFallbackSouls }) or L.t("mz.vipSpin")
		elseif (tonumber(state.spins) or 0) > 0 then
			spinMode = "Ticket"
			spinBtnText = L.t("ui.rewards.spinTicket", { count = state.spins })
		elseif state.paidSpinPrice then
			spinMode = "Paid"
			spinBtnText = L.t("cx.reward.spin.paid", { price = state.paidSpinPrice })
		else
			canSpin = false
			spinBtnText = L.t("ui.rewards.spinWait", { time = formatTimeLeft(state.resetAt) })
		end

		local function beginSpin(mode)
			if busy or spinning or not canSpin or not wheelInner.Parent then return end
			if compact then body.CanvasPosition = Vector2.zero end
			setStatus(L.t("ui.rewards.spinning"), false)
			invokeRewards("Spin", mode, nil, function(ok, res)
				if not ok or type(res) ~= "table" or not res.reward then
					rewardError(res) return
				end
				if res.mode == "VIPFallback" then showPrizeCelebration(res.reward) return end
				local sector = math.clamp(tonumber(res.sector) or 1, 1, #sectors)
				local weekly = sectors[sector] and sectors[sector].kind == "WeeklySkin"
				showPrizeCelebration(res.reward, { wheel = wheelInner, sector = sector, sectors = sectors, jackpot = weekly, bonus = res.bonus })
			end)
		end
		UiTheme.button({
			name = "SpinButton", parent = wheelPanel, anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -REVEAL.ButtonH), size = UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.ButtonH),
			text = spinBtnText, font = "Title", textSize = UiTheme.TextSizes.SM,
			variant = canSpin and "gold" or "secondary", disabled = not canSpin or not serverStateReady,
			onClick = function()
				if spinMode == "Paid" then showPaidConfirmation(function() beginSpin("Paid") end)
				else beginSpin(spinMode) end
			end,
		})

		UiTheme.label({
			parent = wheelPanel,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -14),
			size = UDim2.new(0.9, 0, 0, 22),
			text = not state.freeSpin and L.t("cx.reward.spin.remaining", { count = state.paidSpinsRemaining or 0 }) or "",
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
		})

		-- Panel derecho: Vista 3D del Gran Premio Semanal (CrimsonEclipse)
		local prizePanel = UiTheme.panel({
			name = "WeeklyPrizePanel",
			parent = body,
			position = compact and UDim2.fromOffset(0, bodyH + REVEAL.MobileGap) or UDim2.fromOffset(leftW + 14, 0),
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

		UiTheme.rarityBadge(prizePanel, "Mythic", L.t("Exclusive"), UDim2.new(0.5, -52, 0, 42))

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
			size = UDim2.new(1, -36, 0, not state.freeSpin and state.paidSpinPrice and REVEAL.WheelDescriptionHeight or 92),
			text = L.t("skinDesc." .. wSkinId),
			font = "Body",
			textSize = UiTheme.TextSizes.XS,
			color = C.TextSecondary,
			alignX = Enum.TextXAlignment.Center,
			alignY = Enum.TextYAlignment.Top,
		})

		-- Soul spins stay available after the daily free spin, also when tickets remain.
		if not state.freeSpin and spinMode ~= "Paid" and state.paidSpinPrice then
			UiTheme.button({ name = "ExtraPaidSpin", parent = prizePanel,
				anchor = Vector2.new(0.5, 1), position = UDim2.new(0.5, 0, 1, -REVEAL.Margin),
				size = UDim2.new(1, -REVEAL.Margin * 2, 0, REVEAL.ButtonH), textSize = UiTheme.TextSizes.SM,
				text = L.t("cx.reward.spin.paid", { price = state.paidSpinPrice }), disabled = not serverStateReady,
				onClick = function() showPaidConfirmation(function() beginSpin("Paid") end) end })
		end

	------------------------------------------------------------------
	-- PESTAÑA 2: CAJAS DE SUERTE
	------------------------------------------------------------------

	elseif tab == "Boxes" then
		local oddsHeight = state.luck and state.luck.multiplier > 1 and REVEAL.ButtonH or 0
		luckLabel = UiTheme.label({ parent = body, size = UDim2.new(1, 0, 0, oddsHeight),
			text = "", font = "Number", textSize = UiTheme.TextSizes.SM, color = C.Accent, alignX = Enum.TextXAlignment.Right })
		local bodyH = compact and REVEAL.MobileBoxHeight or REVEAL.BoxCardHeight
		local perRow = compact and 1 or 3
		local gap = REVEAL.MobileGap
		local cardW = math.floor((width - 46 - (perRow - 1) * gap) / perRow)
		local order = RewardsConfig and RewardsConfig.BoxOrder or { "Souls", "Relic" }
		local holder = body
		if not compact then
			holder = Instance.new("ScrollingFrame")
			holder.Name = "BoxList"
			holder.Size = UDim2.fromScale(1, 1)
			holder.BackgroundTransparency = 1 holder.BorderSizePixel = 0
			holder.ScrollBarThickness = UiTheme.Spacing.XXS holder.ScrollingDirection = Enum.ScrollingDirection.Y
			holder.Parent = body
			luckLabel.Parent = holder
		end
		boxScroller = holder
		holder.CanvasSize = UDim2.fromOffset(0, oddsHeight + math.ceil(#order / perRow) * (bodyH + gap))

		for idx, id in order do
			local tier = CHEST_TIERS[id]
			local spec = state.boxes and state.boxes[id]
			local count = spec and spec.count or 0
			local usesGems = spec and spec.currency == "Gems"
			local ready = serverStateReady and spec ~= nil
			local col, row = (idx - 1) % perRow, math.floor((idx - 1) / perRow)
			local card = UiTheme.panel({ name = "BoxCard_" .. id, parent = holder,
				position = UDim2.fromOffset(col * (cardW + gap), oddsHeight + row * (bodyH + gap)),
				size = UDim2.fromOffset(cardW, bodyH), bg = C.BgPanel, borderColor = tier.color,
				borderThickness = tier.stroke, ornaments = idx >= 4 })

			UiTheme.label({ parent = card, position = UDim2.fromOffset(10, 4), size = UDim2.new(1, -20, 0, 22),
				text = L.t("mz.level", { level = idx }), font = "Number", color = tier.color, textSize = UiTheme.TextSizes.XS,
				alignX = Enum.TextXAlignment.Center })
			UiTheme.label({ parent = card, position = UDim2.fromOffset(10, 22), size = UDim2.new(1, -20, 0, 28),
				text = L.t("cx.reward.box." .. id), font = "Title", scaled = true, textSize = UiTheme.TextSizes.XL,
				color = C.TextPrimary, alignX = Enum.TextXAlignment.Center })
			local art = Instance.new("Frame")
			art.Position = UDim2.fromOffset(0, 50) art.Size = UDim2.new(1, 0, 0, compact and 110 or 76)
			art.BackgroundTransparency = 1 art.Parent = card
			drawChest(art, tier, card.ZIndex + 1)
			local meta = L.t("ui.rewards.boxOwned", { count = count })
			if serverStateReady and spec and not usesGems then
				local skinChance = 0
				for _, row in spec.probabilities do if row.skins then skinChance += row.probability end end
				meta = meta .. " · " .. L.t("mz.skinChance", { percent = Format.percent(skinChance, L.language()) })
			end
			UiTheme.label({ parent = card, anchor = Vector2.new(0, 1), position = UDim2.new(0, 8, 1, -54),
				size = UDim2.new(1, -16, 0, 22), text = meta, scaled = true, textSize = UiTheme.TextSizes.XS,
				color = C.TextSecondary, alignX = Enum.TextXAlignment.Center })

			local preview = UiTheme.button({ name = "BoxOdds_" .. id, parent = card, anchor = Vector2.new(0, 1),
				position = UDim2.new(0, 8, 1, -8), size = UDim2.new(0.47, -12, 0, 44),
				icon = "aura_eyes", iconSize = 16, text = L.t("mz.viewRewards"), textSize = UiTheme.TextSizes.XS,
				disabled = not ready, onClick = function() showOddsModal(id) end })
			preview.TextWrapped = true
			local open = boxOpenButton({ parent = card, anchor = Vector2.new(1, 1),
				position = UDim2.new(1, -8, 1, -8), size = UDim2.new(0.53, -8, 0, 44) }, id, spec)
			preview.NextSelectionRight = open
			open.NextSelectionLeft = preview
		end
		holder.CanvasPosition = boxScrollPosition

	elseif tab == "Streak" and compact then
		compactStreak(body, width - 40)
	elseif tab == "Streak" then
		local topOffset = weeklyCard(body, width - 40, 0, false)
		if state.returnNotice then
			local retBar = UiTheme.panel({
				parent = body,
				position = UDim2.fromOffset(0, topOffset),
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
			topOffset += 52
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
				invokeRewards("ClaimStreak", nil, nil, function(ok, res)
					if ok and type(res) == "table" and res.reward then showPrizeCelebration(res.reward)
					else setStatus(L.t((type(res) == "table" and res.key) or "error"), true) refreshState(false) end
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
						showPrizeCelebration(res.reward)
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
				vp.ImageColor3 = C.Disabled
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
		size = UDim2.fromOffset(compact and width - 44 or width - 260, 24),
		text = "",
		font = "Bold",
		textSize = UiTheme.TextSizes.SM,
		color = C.GoldBright,
	})

	Device.showFor(UiTheme.label({
		parent = panel,
		position = UDim2.fromOffset(width - 240, height - 34),
		size = UDim2.fromOffset(220, 24),
		text = compact and "" or L.t("ui.gamepadHint"),
		font = "Body",
		textSize = UiTheme.TextSizes.XS,
		color = C.TextMuted,
		alignX = Enum.TextXAlignment.Right,
	}), "Gamepad") -- 11/11: solo con mando (Device)

	if Device.isGamepad() and firstTabBtn and not subModal then
		local focusedBox = boxScroller and focusedBoxButtonName and boxScroller:FindFirstChild(focusedBoxButtonName, true)
		GuiService.SelectedObject = focusedBox and focusedBox.Selectable and focusedBox or firstTabBtn
	end
end

----------------------------------------------------------------------
-- Apertura / cierre y sincronización con otros menús
----------------------------------------------------------------------
function setOpen(value)
	if opened == value or spinning or busy then return end
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
		panel.Position = UDim2.fromScale(0.5, 0.53)
		TweenService:Create(panel, UiTheme.Anim.TweenNorm, {
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
		if player:GetAttribute(otherAttr) == true then
			if activeReveal and otherAttr == "InMatch" then activeReveal.cancelled = true activeReveal.dismiss = true end
			if opened then setOpen(false) end
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
	if not opened or spinning or busy then return end
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		if subModal then
			closeSubModal()
		elseif not processed or input.KeyCode == Enum.KeyCode.ButtonB then
			setOpen(false)
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if subModal and subModal.Name == "RewardOdds" and oddsExpireAt and workspace:GetServerTimeNow() >= oddsExpireAt then
		oddsExpireAt = nil
		local current, id = subModal, oddsBoxId
		invokeRewards("GetState", nil, nil, function(ok)
			if ok and subModal == current then showOddsModal(id) end
		end)
	end
	if opened and luckLabel and luckLabel.Parent and state.luck then
		local remaining = math.max(0, math.ceil(state.luck.endsAt - workspace:GetServerTimeNow()))
		if remaining ~= luckTimerSecond then
			luckTimerSecond = remaining
			luckLabel.Text = remaining > 0 and state.luck.multiplier > 1 and L.t("mz.luckTimer", {
				multiplier = state.luck.multiplier, time = ("%02d:%02d"):format(math.floor(remaining / 60), remaining % 60),
			}) or ""
			if remaining == 0 and state.luck.multiplier > 1 then refreshState(true) end
		end
	end
	if opened and not spinning and not busy and not subModal and usableViewport() ~= renderedViewport then render() end
	if not opened and not welcomeVeil and not activeReveal then return end
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
for _, attr in { "Pass_VIP", "PaidRandomAllowed", "PurchaseVersion", "Gems" } do
	player:GetAttributeChangedSignal(attr):Connect(function() refreshState(true) end)
end

task.spawn(function()
	refreshState(false)
	if not remotes then remotes = RS:WaitForChild("Remotes", 15) end
	if not remotes then return end

	local changedEv = remotes:WaitForChild("RewardsChanged", 15)
	if changedEv and changedEv:IsA("RemoteEvent") then
		changedEv.OnClientEvent:Connect(function(payload)
			if type(payload) == "table" and payload.source == "Tutorial" and type(payload.reward) == "table" then
				showPrizeCelebration(payload.reward)
			end
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
			local color = payload.reward and rewardColor(payload.reward) or C.GoldBright

			local banner = UiTheme.panel({
				name = "LegendaryAnnouncement",
				parent = gui,
				anchor = Vector2.new(0.5, 0),
				position = UDim2.new(0.5, 0, 0, 56),
				size = UDim2.fromOffset(math.min(540, usableViewport().X - REVEAL.Margin * 2), 44),
				bg = C.BgPanel,
				borderColor = color,
				borderThickness = 2,
				ornaments = true,
				zIndex = 60,
			})
			UiTheme.label({
				parent = banner,
				position = UDim2.fromOffset(14, 0),
				size = UDim2.new(1, -28, 1, 0),
				text = L.t("cx.reward.announcement", { name = winnerName, prize = prizeName }),
				font = "Title",
				textSize = UiTheme.TextSizes.MD,
				color = color,
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
	if opened and not spinning and not busy and not subModal then render() end
end)
