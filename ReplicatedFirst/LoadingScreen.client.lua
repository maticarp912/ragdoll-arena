-- LocalScript: ReplicatedFirst/LoadingScreen
-- Pantalla de carga personalizada basada en referencias\idea pantalla de carga.png
-- (Fase 4, Contrato C13, responsable: Gemini, etapa 8).
-- Muestra barra de progreso real con ContentProvider.RequestQueueSize, consejos de combate traducidos
-- y transición suave al entrar a la ciudad.

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Traducciones inmediatas (para el primer fotograma antes de que termine de replicar ReplicatedStorage)
local FALLBACK_TEXT = {
	ES = {
		["ui.loading.subtitle"] = "ARENA DE DUELOS Y FANTASÍA OSCURA",
		["ui.loading.preparing"] = "Forjando el acero… {pct}%",
		["ui.loading.ready"] = "Entrando a la ciudad…",
		["ui.loading.skip"] = "Omitir",
		["ui.loading.tip1"] = "CONSEJO: Un toque justo al bloquear ejecuta un Parry que abre la guardia rival.",
		["ui.loading.tip2"] = "CONSEJO: Cuando derribes a un enemigo, acércate y usa Agarrar para lanzarlo fuera de la arena.",
		["ui.loading.tip3"] = "CONSEJO: Las infusiones siguen un ciclo: Fuego vence a Rayo, Rayo a Hielo, Hielo a Sombra y Sombra a Fuego.",
		["ui.loading.tip4"] = "CONSEJO: Los ataques con destello rojo-dorado son imbloqueables: esquivá o respondé con un Parry preciso.",
	},
	EN = {
		["ui.loading.subtitle"] = "DARK FANTASY DUELING ARENA",
		["ui.loading.preparing"] = "Forging the steel… {pct}%",
		["ui.loading.ready"] = "Entering the city…",
		["ui.loading.skip"] = "Skip",
		["ui.loading.tip1"] = "TIP: Timing your block right before impact triggers a Parry that staggers the opponent.",
		["ui.loading.tip2"] = "TIP: When an enemy is knocked down, move in and Grab them to hurl them out of the arena.",
		["ui.loading.tip3"] = "TIP: Infusions follow a cycle: Fire beats Lightning, Lightning beats Ice, Ice beats Shadow, and Shadow beats Fire.",
		["ui.loading.tip4"] = "TIP: Attacks with a golden-red flash are unblockable—dodge away or answer with a precise Parry.",
	},
	["PT-BR"] = {
		["ui.loading.subtitle"] = "ARENA DE DUELOS E FANTASIA SOMBRIA",
		["ui.loading.preparing"] = "Forjando o aço… {pct}%",
		["ui.loading.ready"] = "Entrando na cidade…",
		["ui.loading.skip"] = "Pular",
		["ui.loading.tip1"] = "DICA: Bloquear no instante exato executa um Parry que abre a guarda rival.",
		["ui.loading.tip2"] = "DICA: Ao derrubar um inimigo, aproxime-se e use Agarrar para lançá-lo para fora da arena.",
		["ui.loading.tip3"] = "DICA: As infusões seguem um ciclo: Fogo vence Raio, Raio vence Gelo, Gelo vence Sombra e Sombra vence Fogo.",
		["ui.loading.tip4"] = "DICA: Ataques com brilho vermelho-dourado são indefensáveis: esquive ou responda com um Parry preciso.",
	},
}

local Localization = nil
local function detectLang()
	local saved = player:GetAttribute("Language")
	if saved and FALLBACK_TEXT[saved] then return saved end
	local loc = string.lower(player.LocaleId or "es")
	if string.match(loc, "^es") then return "ES" end
	if string.match(loc, "^pt") then return "PT-BR" end
	return "EN"
end

local function tr(key, params)
	if not Localization then
		local mod = ReplicatedStorage:FindFirstChild("Localization")
		if mod then
			local ok, res = pcall(require, mod)
			if ok then Localization = res end
		end
	end
	if Localization then
		return Localization.t(key, params)
	end
	local lang = detectLang()
	local raw = (FALLBACK_TEXT[lang] and FALLBACK_TEXT[lang][key]) or FALLBACK_TEXT.EN[key] or key
	return (raw:gsub("{([%w_]+)}", function(k)
		return params and params[k] ~= nil and tostring(params[k]) or ""
	end))
end

----------------------------------------------------------------------
-- Construcción visual (inspirada en referencias\idea pantalla de carga.png)
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreenGui"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("CanvasGroup")
root.Name = "LoadingRoot"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(9, 10, 15)
root.BorderSizePixel = 0
root.Parent = gui

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 16, 26)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(11, 12, 18)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 7, 10)),
})
bgGrad.Rotation = 90
bgGrad.Parent = root

-- Marco perimetral dorado viejo
local outerFrame = Instance.new("Frame")
outerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
outerFrame.Position = UDim2.fromScale(0.5, 0.5)
outerFrame.Size = UDim2.new(1, -48, 1, -48)
outerFrame.BackgroundTransparency = 1
outerFrame.Parent = root
local outerStroke = Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(168, 136, 74)
outerStroke.Thickness = 1.6
outerStroke.Transparency = 0.25
outerStroke.Parent = outerFrame

-- Emblema central: espadas cruzadas sobre sello octogonal dorado
local crest = Instance.new("Frame")
crest.Name = "CenterCrest"
crest.AnchorPoint = Vector2.new(0.5, 0.5)
crest.Position = UDim2.fromScale(0.5, 0.34)
crest.Size = UDim2.fromOffset(128, 128)
crest.Rotation = 45
crest.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
crest.BorderSizePixel = 0
crest.Parent = root
local crestCorner = Instance.new("UICorner")
crestCorner.CornerRadius = UDim.new(0, 14)
crestCorner.Parent = crest
local crestStroke = Instance.new("UIStroke")
crestStroke.Color = Color3.fromRGB(234, 198, 118)
crestStroke.Thickness = 2.5
crestStroke.Parent = crest

local blade1 = Instance.new("Frame")
blade1.AnchorPoint = Vector2.new(0.5, 0.5)
blade1.Position = UDim2.fromScale(0.5, 0.5)
blade1.Size = UDim2.fromOffset(10, 96)
blade1.BackgroundColor3 = Color3.fromRGB(238, 231, 215)
blade1.BorderSizePixel = 0
blade1.Parent = crest

local blade2 = blade1:Clone()
blade2.Rotation = 90
blade2.Parent = crest

local innerGem = Instance.new("Frame")
innerGem.AnchorPoint = Vector2.new(0.5, 0.5)
innerGem.Position = UDim2.fromScale(0.5, 0.5)
innerGem.Size = UDim2.fromOffset(32, 32)
innerGem.BackgroundColor3 = Color3.fromRGB(218, 174, 84)
innerGem.BorderSizePixel = 0
innerGem.Parent = crest

-- Título monumental y subtítulo
local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0.50, 0)
title.Size = UDim2.new(0.8, 0, 0, 52)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Garamond
title.Text = "RAGDOLL ARENA"
title.TextColor3 = Color3.fromRGB(242, 212, 138)
title.TextSize = 46
title.TextStrokeTransparency = 0.35
title.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.new(0.5, 0, 0.58, 0)
subtitle.Size = UDim2.new(0.8, 0, 0, 26)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = tr("ui.loading.subtitle")
subtitle.TextColor3 = Color3.fromRGB(184, 176, 160)
subtitle.TextSize = 15
subtitle.Parent = root

-- Panel inferior de consejos de juego y barra de progreso real
local bottomPanel = Instance.new("Frame")
bottomPanel.AnchorPoint = Vector2.new(0.5, 1)
bottomPanel.Position = UDim2.new(0.5, 0, 1, -54)
bottomPanel.Size = UDim2.fromOffset(660, 108)
bottomPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 25)
bottomPanel.BackgroundTransparency = 0.1
bottomPanel.BorderSizePixel = 0
bottomPanel.Parent = root
local bpCorner = Instance.new("UICorner")
bpCorner.CornerRadius = UDim.new(0, 8)
bpCorner.Parent = bottomPanel
local bpStroke = Instance.new("UIStroke")
bpStroke.Color = Color3.fromRGB(204, 167, 92)
bpStroke.Thickness = 1.6
bpStroke.Parent = bottomPanel

local tipLabel = Instance.new("TextLabel")
tipLabel.Position = UDim2.fromOffset(20, 12)
tipLabel.Size = UDim2.new(1, -40, 0, 42)
tipLabel.BackgroundTransparency = 1
tipLabel.Font = Enum.Font.GothamMedium
tipLabel.TextColor3 = Color3.fromRGB(238, 231, 215)
tipLabel.TextSize = 14
tipLabel.TextWrapped = true
tipLabel.Text = tr("ui.loading.tip1")
tipLabel.Parent = bottomPanel

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(20, 62)
barBack.Size = UDim2.new(1, -40, 0, 14)
barBack.BackgroundColor3 = Color3.fromRGB(9, 10, 14)
barBack.BorderSizePixel = 0
barBack.Parent = bottomPanel
local bbCorner = Instance.new("UICorner")
bbCorner.CornerRadius = UDim.new(0, 4)
bbCorner.Parent = barBack
local bbStroke = Instance.new("UIStroke")
bbStroke.Color = Color3.fromRGB(142, 115, 64)
bbStroke.Thickness = 1
bbStroke.Parent = barBack

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0.05, 1)
barFill.BackgroundColor3 = Color3.fromRGB(218, 178, 92)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
local bfCorner = Instance.new("UICorner")
bfCorner.CornerRadius = UDim.new(0, 4)
bfCorner.Parent = barFill

local progressLabel = Instance.new("TextLabel")
progressLabel.Position = UDim2.fromOffset(20, 80)
progressLabel.Size = UDim2.new(1, -40, 0, 22)
progressLabel.BackgroundTransparency = 1
progressLabel.Font = Enum.Font.GothamBold
progressLabel.TextColor3 = Color3.fromRGB(204, 167, 92)
progressLabel.TextSize = 12
progressLabel.Text = tr("ui.loading.preparing", { pct = 5 })
progressLabel.Parent = bottomPanel

local skipBtn = Instance.new("TextButton")
skipBtn.AnchorPoint = Vector2.new(1, 0)
skipBtn.Position = UDim2.new(1, -36, 0, 36)
skipBtn.Size = UDim2.fromOffset(108, 38)
skipBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
skipBtn.TextColor3 = Color3.fromRGB(238, 231, 215)
skipBtn.Font = Enum.Font.GothamBold
skipBtn.TextSize = 14
skipBtn.Text = tr("ui.loading.skip")
skipBtn.Visible = false
skipBtn.Parent = root
local skCorner = Instance.new("UICorner")
skCorner.CornerRadius = UDim.new(0, 6)
skCorner.Parent = skipBtn
local skStroke = Instance.new("UIStroke")
skStroke.Color = Color3.fromRGB(204, 167, 92)
skStroke.Thickness = 1.4
skStroke.Parent = skipBtn

----------------------------------------------------------------------
-- Progreso real de ContentProvider:PreloadAsync y rotación de consejos
-- (Punto 9: precarga de texturas, sonidos, UiAssets, partículas y armas)
----------------------------------------------------------------------
local finished = false
local function finishLoading()
	if finished then return end
	finished = true
	progressLabel.Text = tr("ui.loading.ready")
	TweenService:Create(barFill, TweenInfo.new(0.2), { Size = UDim2.fromScale(1, 1) }):Play()
	task.wait(0.22)
	local fade = TweenService:Create(root, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()
	if gui.Parent then
		gui:Destroy()
	end
end

skipBtn.Activated:Connect(finishLoading)

task.spawn(function()
	local tips = { "ui.loading.tip1", "ui.loading.tip2", "ui.loading.tip3", "ui.loading.tip4" }
	local tipIdx = math.random(1, #tips)
	tipLabel.Text = tr(tips[tipIdx])

	-- Recolección de assets para PreloadAsync
	local preloadList = {}
	local seen = {}
 local holders={}
 local function addAsset(id,class,property)
  if typeof(id)=="Instance" then table.insert(preloadList,id) return end
  if type(id)=="number" then if id<=0 then return end id="rbxassetid://"..id end
  if type(id)~="string" or id=="" then return end
  class=class or "ImageLabel" property=property or "Image"
  local key=class..id if seen[key] then return end seen[key]=true
  local obj=Instance.new(class) obj[property]=id table.insert(holders,obj) table.insert(preloadList,obj)
 end
 local function collectIds(tbl,class,property)
  if type(tbl)~="table" then return end
  for _,v in pairs(tbl) do
   if type(v)=="table" then collectIds(v,class,property)
   elseif type(v)=="number" or (type(v)=="string" and (v:find("rbxasset",1,true) or v:find("roblox.com",1,true))) then addAsset(v,class,property) end
  end
 end

	-- Esperamos por los módulos principales con límite de seguridad
	local assetsMod = ReplicatedStorage:WaitForChild("Assets", 6)
	if assetsMod then
		local ok, Assets = pcall(require, assetsMod)
		if ok and type(Assets) == "table" then
			collectIds(Assets.Sounds,"Sound","SoundId")
			collectIds(Assets.VFX)
			collectIds(Assets.Icons)
		end
	end

	local uiAssetsMod = ReplicatedStorage:WaitForChild("UiAssets", 6)
	if uiAssetsMod then
		local ok, UiAssets = pcall(require, uiAssetsMod)
		if ok and type(UiAssets) == "table" and UiAssets.Ids then
			collectIds(UiAssets.Ids)
		end
	end

	local aurasMod = ReplicatedStorage:WaitForChild("Auras", 6)
	if aurasMod then
		local ok, Auras = pcall(require, aurasMod)
		if ok and type(Auras) == "table" and Auras.Fx then
			if Auras.Fx.SmokeTexture then addAsset(Auras.Fx.SmokeTexture) end
			if Auras.Fx.SparkTexture then addAsset(Auras.Fx.SparkTexture) end
		end
	end

	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
	if weaponsFolder then
		addAsset(weaponsFolder)
	end

	local totalAssets = #preloadList
	local loadedAssets = 0
	local preloadComplete = false

	task.spawn(function()
		if totalAssets > 0 then
			pcall(function()
				ContentProvider:PreloadAsync(preloadList, function()
					loadedAssets += 1
				end)
			end)
		end
		for _,obj in holders do obj:Destroy() end
  preloadComplete = true
	end)

	local startTime = os.clock()
	local peakQueue = math.max(1, ContentProvider.RequestQueueSize)
	local displayedPct = 0.05

	while not finished do
		local elapsed = os.clock() - startTime
		local q = ContentProvider.RequestQueueSize
		if q > peakQueue then peakQueue = q end

		if elapsed > 1.2 and not skipBtn.Visible then
			skipBtn.Visible = true
			skipBtn.Text = tr("ui.loading.skip")
		end

		if math.floor(elapsed / 3.2) ~= math.floor((elapsed - 0.08) / 3.2) then
			tipIdx = (tipIdx % #tips) + 1
			tipLabel.Text = tr(tips[tipIdx])
		end

		local preloadRatio = totalAssets > 0 and (loadedAssets / totalAssets) or (preloadComplete and 1 or 0.5)
		local queueRatio = peakQueue > 0 and (1 - (q / peakQueue)) or 1
		local combinedRatio = (preloadRatio * 0.75) + (queueRatio * 0.25)
		local timeRatio = math.clamp(elapsed / 2.8, 0, 1)

		local targetPct = math.min(preloadComplete and 1 or 0.95,preloadRatio)
		displayedPct = math.clamp(math.max(displayedPct, targetPct), 0.05, 1)

		barFill.Size = UDim2.fromScale(displayedPct, 1)
		progressLabel.Text = tr("ui.loading.preparing", { pct = math.floor(displayedPct * 100) })
		crest.Rotation = 45 + math.sin(elapsed * 2) * 4

		local readyToFinish = preloadComplete
			and game:IsLoaded()
			and (q == 0 or elapsed >= 2.6)
			and elapsed >= 1.2

		if readyToFinish then
			finishLoading()
			break
		end
		task.wait(0.05)
	end
end)
