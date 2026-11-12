-- LocalScript: ReplicatedFirst/LoadingScreen
-- Pantalla de carga personalizada basada en referencias\idea pantalla de carga.png
-- (Fase 4, Contrato C13, responsable: Gemini, etapa 8).
-- Muestra barra de progreso real con ContentProvider.RequestQueueSize, consejos de combate traducidos
-- y transición suave al entrar a la ciudad.

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local actionName = "InitialLoadingMovement"
player:SetAttribute("InitialLoading", true)
ContextActionService:BindActionAtPriority(actionName, function()
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, table.unpack(Enum.PlayerActions:GetEnumItems()))

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
-- The first loading frame can appear before ReplicatedStorage is available.
local C = {
 BgAbyss = Color3.fromRGB(8, 11, 15), BgPanel = Color3.fromRGB(21, 28, 37), BgPrimary = Color3.fromRGB(15, 20, 27),
 BgModalVeil = Color3.fromRGB(4, 7, 11), BgHeader = Color3.fromRGB(19, 26, 35), BgBarBack = Color3.fromRGB(10, 14, 20),
 BorderStrong = Color3.fromRGB(162, 183, 205), BorderDefault = Color3.fromRGB(91, 107, 126), Iron = Color3.fromRGB(49, 59, 72),
 Gold = Color3.fromRGB(177, 193, 210), GoldBright = Color3.fromRGB(228, 237, 247), GoldDim = Color3.fromRGB(105, 125, 147),
 TextPrimary = Color3.fromRGB(241, 244, 248), TextSecondary = Color3.fromRGB(191, 203, 216),
}
local themeModule = ReplicatedStorage:FindFirstChild("UiTheme")
if themeModule and ReplicatedStorage:FindFirstChild("Assets") then
 local ok, theme = pcall(require, themeModule)
 if ok then C = theme.Colors end
end
local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreenGui"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local root = Instance.new("CanvasGroup")
root.Name = "LoadingRoot"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = C.BgAbyss
root.BorderSizePixel = 0
root.Parent = gui

-- 12/11/2026: el degradado va en un fondo propio. Puesto sobre el CanvasGroup teñía TODO el grupo
-- (textos, emblema y barra) con los colores oscuros y la pantalla de carga se veía casi negra.
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(1, 1, 1)
backdrop.BorderSizePixel = 0
backdrop.ZIndex = 0
backdrop.Parent = root

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C.BgPanel),
	ColorSequenceKeypoint.new(0.55, C.BgPrimary),
	ColorSequenceKeypoint.new(1, C.BgModalVeil),
})
bgGrad.Rotation = 90
bgGrad.Parent = backdrop

-- Marco perimetral dorado viejo
local outerFrame = Instance.new("Frame")
outerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
outerFrame.Position = UDim2.fromScale(0.5, 0.5)
outerFrame.Size = UDim2.new(1, -48, 1, -48)
outerFrame.BackgroundTransparency = 1
outerFrame.Parent = root
local outerStroke = Instance.new("UIStroke")
outerStroke.Color = C.BorderStrong
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
crest.BackgroundColor3 = C.BgHeader
crest.BorderSizePixel = 0
crest.Parent = root
local crestCorner = Instance.new("UICorner")
crestCorner.CornerRadius = UDim.new(0, 14)
crestCorner.Parent = crest
local crestStroke = Instance.new("UIStroke")
crestStroke.Color = C.GoldBright
crestStroke.Thickness = 2.5
crestStroke.Parent = crest

local blade1 = Instance.new("Frame")
blade1.AnchorPoint = Vector2.new(0.5, 0.5)
blade1.Position = UDim2.fromScale(0.5, 0.5)
blade1.Size = UDim2.fromOffset(10, 96)
blade1.BackgroundColor3 = C.TextPrimary
blade1.BorderSizePixel = 0
blade1.Parent = crest

local blade2 = blade1:Clone()
blade2.Rotation = 90
blade2.Parent = crest

local innerGem = Instance.new("Frame")
innerGem.AnchorPoint = Vector2.new(0.5, 0.5)
innerGem.Position = UDim2.fromScale(0.5, 0.5)
innerGem.Size = UDim2.fromOffset(32, 32)
innerGem.BackgroundColor3 = C.Gold
innerGem.BorderSizePixel = 0
innerGem.Parent = crest

-- Título monumental y subtítulo
local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0.50, 0)
title.Size = UDim2.new(0.8, 0, 0, 52)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Garamond
-- 11/11/2026: mismo nombre que la página de Roblox «[BETA] Dark Fantasy Plataforme 2v2 1v1 PVP»
title.Text = "DARK FANTASY PLATAFORME"
title.TextColor3 = C.GoldBright
title.TextSize = 46
title.TextScaled = true
local titleMax = Instance.new("UITextSizeConstraint") titleMax.MaxTextSize = 46 titleMax.Parent = title
title.TextStrokeTransparency = 1
title.Parent = root

local tagline = Instance.new("TextLabel")
tagline.AnchorPoint = Vector2.new(0.5, 1)
tagline.Position = UDim2.new(0.5, 0, 0.50, -4)
tagline.Size = UDim2.new(0.8, 0, 0, 22)
tagline.BackgroundTransparency = 1
tagline.Font = Enum.Font.Garamond
tagline.Text = "[BETA]  ·  2V2  ·  1V1  ·  PVP"
tagline.TextColor3 = C.TextSecondary
tagline.TextSize = 16
tagline.Parent = root

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.new(0.5, 0, 0.58, 0)
subtitle.Size = UDim2.new(0.8, 0, 0, 26)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Garamond
subtitle.Text = tr("ui.loading.subtitle")
subtitle.TextColor3 = C.TextSecondary
subtitle.TextSize = 15
subtitle.Parent = root

-- Panel inferior de consejos de juego y barra de progreso real
local bottomPanel = Instance.new("Frame")
bottomPanel.AnchorPoint = Vector2.new(0.5, 1)
bottomPanel.Position = UDim2.new(0.5, 0, 1, -54)
bottomPanel.Size = UDim2.fromOffset(660, 108)
bottomPanel.BackgroundColor3 = C.BgPanel
bottomPanel.BackgroundTransparency = 0.1
bottomPanel.BorderSizePixel = 0
bottomPanel.Parent = root
local bpCorner = Instance.new("UICorner")
bpCorner.CornerRadius = UDim.new(0, 8)
bpCorner.Parent = bottomPanel
local bpStroke = Instance.new("UIStroke")
bpStroke.Color = C.GoldDim
bpStroke.Thickness = 1.6
bpStroke.Parent = bottomPanel

local tipLabel = Instance.new("TextLabel")
tipLabel.Position = UDim2.fromOffset(20, 12)
tipLabel.Size = UDim2.new(1, -40, 0, 42)
tipLabel.BackgroundTransparency = 1
tipLabel.Font = Enum.Font.Garamond
tipLabel.TextColor3 = C.TextPrimary
tipLabel.TextSize = 14
tipLabel.TextWrapped = true
tipLabel.Text = tr("ui.loading.tip1")
tipLabel.Parent = bottomPanel

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(20, 62)
barBack.Size = UDim2.new(1, -40, 0, 14)
barBack.BackgroundColor3 = C.BgBarBack
barBack.BorderSizePixel = 0
barBack.Parent = bottomPanel
local bbCorner = Instance.new("UICorner")
bbCorner.CornerRadius = UDim.new(0, 4)
bbCorner.Parent = barBack
local bbStroke = Instance.new("UIStroke")
bbStroke.Color = C.BorderDefault
bbStroke.Thickness = 1
bbStroke.Parent = barBack

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0.05, 1)
barFill.BackgroundColor3 = C.Gold
barFill.BorderSizePixel = 0
barFill.Parent = barBack
local bfCorner = Instance.new("UICorner")
bfCorner.CornerRadius = UDim.new(0, 4)
bfCorner.Parent = barFill

local progressLabel = Instance.new("TextLabel")
progressLabel.Position = UDim2.fromOffset(20, 80)
progressLabel.Size = UDim2.new(1, -40, 0, 22)
progressLabel.BackgroundTransparency = 1
progressLabel.Font = Enum.Font.Garamond
progressLabel.TextColor3 = C.GoldDim
progressLabel.TextSize = 12
progressLabel.Text = tr("ui.loading.preparing", { pct = 5 })
progressLabel.Parent = bottomPanel

local skipBtn = Instance.new("TextButton")
skipBtn.AnchorPoint = Vector2.new(1, 0)
skipBtn.Position = UDim2.new(1, -36, 0, 36)
skipBtn.Size = UDim2.fromOffset(174, 38)
skipBtn.BackgroundColor3 = C.Iron
skipBtn.TextColor3 = C.TextPrimary
skipBtn.Font = Enum.Font.Garamond
skipBtn.TextSize = 14
skipBtn.Text = ""
skipBtn.Visible = false
skipBtn.Parent = root
local skCorner = Instance.new("UICorner")
skCorner.CornerRadius = UDim.new(0, 6)
skCorner.Parent = skipBtn
local skStroke = Instance.new("UIStroke")
skStroke.Color = C.GoldDim
skStroke.Thickness = 1.4
skStroke.Parent = skipBtn

----------------------------------------------------------------------
-- Primero esperamos al personaje y al mapa inicial. Luego pedimos cada recurso por
-- su tipo real, con progreso por lote resuelto y una segunda pasada para los fallidos.
local function initialWorldReady()
	local character = player.Character
	local profile = player:GetAttribute("ProfileState")
	local map = workspace:FindFirstChild("GeneratedMap")
	return game:IsLoaded() and map and character and character:GetAttribute("LobbySpawnReady")
		and character:FindFirstChild("HumanoidRootPart")
		and (profile == "Ready" or profile == "Temporary")
end

local contentProperties = {
	Animation = { "AnimationId" }, Sound = { "SoundId" },
	Decal = { "Texture" }, Texture = { "Texture" },
	ParticleEmitter = { "Texture" }, Trail = { "Texture" }, Beam = { "Texture" },
	MeshPart = { "MeshId", "TextureID" }, SpecialMesh = { "MeshId", "TextureId" },
	SurfaceAppearance = { "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap" },
	MaterialVariant = { "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap" },
	Sky = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SunTextureId", "MoonTextureId" },
	ImageLabel = { "Image" }, ImageButton = { "Image" }, ImageHandleAdornment = { "Image" },
}

local function collect()
	local resources, seen = {}, {}
	local function add(id, kind)
		if type(id) == "number" then
			if id <= 0 then return end
			id = "rbxassetid://" .. id
		end
		if type(id) ~= "string" or not id:match("^rbxasset") and not id:match("^https?://") then return end
		local numeric = id:match("[?&]id=(%d+)") or id:match("^rbxassetid://(%d+)$")
		if numeric == "0" then return end
		local key = numeric or id
		if seen[key] then return end
		seen[key] = true
		local proxy = Instance.new(kind or "ImageLabel")
		local property = kind == "Sound" and "SoundId" or kind == "Animation" and "AnimationId"
			or kind == "SpecialMesh" and "MeshId" or "Image"
		if kind == "SpecialMesh" then proxy.MeshType = Enum.MeshType.FileMesh end
		proxy[property] = id
		table.insert(resources, proxy)
	end
	local function walk(tbl, kind)
		if type(tbl) ~= "table" then return end
		for _, v in tbl do
			if type(v) == "table" then walk(v, kind) else add(v, kind) end
		end
	end
	local function module(name)
		local src = ReplicatedStorage:FindFirstChild(name)
		if src and src:IsA("ModuleScript") then
			local ok, value = pcall(require, src)
			if ok then return value end
		end
		return {}
	end
	local assets = module("Assets")
	walk(assets.Animations, "Animation")
	walk(assets.Sounds, "Sound")
	walk(assets.VFX)
	walk(assets.Icons)
	local ui = module("UiAssets")
	walk(ui.Ids)
	local aura = module("Auras").Fx or {}
	add(aura.SmokeTexture)
	add(aura.SparkTexture)
	walk((module("PolishConfig").Aura or {}).Textures)
	for _, library in { (assets.Models and assets.Models.Weapons) or {}, module("WeaponMeshes") } do
		for _, spec in library do
			if type(spec) == "table" then
				add(spec.MeshId, "SpecialMesh")
				add(spec.TextureId)
			end
		end
	end
	for _, service in { workspace, game:GetService("Lighting"), game:GetService("MaterialService"), ReplicatedStorage, gui.Parent } do
		for _, object in service:GetDescendants() do
			local properties = contentProperties[object.ClassName]
			if properties then
				for _, property in properties do
					local ok, id = pcall(function() return object[property] end)
					local kind = property == "MeshId" and "SpecialMesh" or object:IsA("Sound") and "Sound"
						or object:IsA("Animation") and "Animation" or nil
					if ok then add(id, kind) end
				end
			end
		end
	end
	if ui.imageUri and ui.imageUri("frame_arch") then
		local theme = module("UiTheme")
		if theme.frameArt then
			local rim = theme.frameArt(outerFrame, "Loading")
			if rim then
				rim:GetPropertyChangedSignal("IsLoaded"):Connect(function()
					if rim.IsLoaded then outerStroke.Transparency = 1 end
				end)
			end
		end
	end
	return resources
end

local function finish()
	skipBtn.Visible = false
	task.wait(0.2)
	local fade = TweenService:Create(root, TweenInfo.new(0.35), { GroupTransparency = 1 })
	fade:Play()
	fade.Completed:Wait()
	ContextActionService:UnbindAction(actionName)
	player:SetAttribute("InitialLoading", false)
	gui:Destroy()
end

task.spawn(function()
	local tips = { "ui.loading.tip1", "ui.loading.tip2", "ui.loading.tip3", "ui.loading.tip4" }
	local tipIndex = 1
	tipLabel.Text = tr(tips[tipIndex])
	while not initialWorldReady() do
		progressLabel.Text = tr("v3.loading.world")
		task.wait(0.2)
	end

	local assets = collect()
	local total, finished, failures = #assets, 0, 0
	local index = 0
	local complete = false
	for _ = 1, math.min(total, 8) do
		task.spawn(function()
			while index < total and not complete do
				index += 1
				local asset = assets[index]
				local loaded = false
				for _attempt = 1, 2 do
					local ok = pcall(function()
						ContentProvider:PreloadAsync({ asset }, function(_, status)
							loaded = status == Enum.AssetFetchStatus.Success
						end)
					end)
					if ok and loaded or complete then break end
				end
				if not loaded then failures += 1 end
				finished += 1
				asset:Destroy()
			end
		end)
	end

	local started = os.clock()
	while finished < total and os.clock() - started < 75 do
		local ratio = finished / math.max(1, total)
		barFill.Size = UDim2.fromScale(ratio, 1)
		progressLabel.Text = tr("ui.loading.preparing", { pct = math.floor(ratio * 100) })
		local tip = math.floor((os.clock() - started) / 5) % #tips + 1
		if tip ~= tipIndex then tipIndex = tip tipLabel.Text = tr(tips[tip]) end
		task.wait(0.1)
	end
	complete = true
	local missing = failures + total - finished
	player:SetAttribute("InitialAssetsMissing", missing)
	if missing > 0 then
		progressLabel.Text = tr("v3.loading.unavailable", { count = missing })
		skipBtn.Text = tr("v3.loading.continue")
		skipBtn.Visible = true
		skipBtn.Activated:Wait()
	else
		barFill.Size = UDim2.fromScale(1, 1)
		progressLabel.Text = tr("ui.loading.ready")
	end
	for _, asset in assets do asset:Destroy() end
	finish()
end)
