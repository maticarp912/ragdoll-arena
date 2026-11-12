-- LocalScript: StarterPlayer/StarterPlayerScripts/MainMenu
-- 12/11/2026 (Claude, pedido del usuario): menú inicial antes de jugar y animación de despertar.
--   · Escena propia (solo en este cliente, lejos del mapa): colina de pasto de noche con flores naranjas
--     y azules, cielo de estrellas doradas con luna, y la espada exclusiva del juego (Filo del Eclipse
--     Carmesí) clavada en la colina. Estilo de la imagen del caballero que pasó el usuario.
--   · A la izquierda: título y JUGAR, NOVEDADES y AJUSTES (funciona con mouse, mando y táctil).
--   · JUGAR: fundido, abrís los ojos en primera persona mirando el cielo, te sentás y, mientras te
--     parás, la cámara se aleja a tercera persona. Recién ahí aparecen el HUD y los controles.
-- Atributo MainMenuOpen = true mientras dura (lo leen GuidedTutorial y Tutorial). Medidas en PolishConfig.MainMenu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))
local WeaponBuilder = require(ReplicatedStorage:WaitForChild("WeaponBuilder"))

local M = Polish.MainMenu
local C = UiTheme.Colors
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local BLOCK_ACTION = "MainMenuBlock"

player:SetAttribute("MainMenuOpen", true)

----------------------------------------------------------------------
-- Escena
----------------------------------------------------------------------
local rng = Random.new(M.Seed)
local scene = Instance.new("Model")
scene.Name = "MainMenuScene"

local function part(name, shape, size, cf, color, material, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = scene
	return p
end

local O = M.Origin
-- colina: una esfera enorme de pasto, de la que asoma la parte de arriba
local hillCenter = O - Vector3.new(0, M.HillRadius - 2, 0)
part("Hill", Enum.PartType.Ball, Vector3.one * M.HillRadius * 2, CFrame.new(hillCenter), M.Grass, Enum.Material.Grass)
-- loma de atrás, más oscura, y siluetas de rocas contra el cielo
part("FarHill", Enum.PartType.Ball, Vector3.one * M.HillRadius * 2.4,
	CFrame.new(hillCenter + Vector3.new(0, -12, -M.HillRadius * 1.1)), M.FarGrass, Enum.Material.Grass)
for i = 1, 0 do -- 12/11/2026: los bloques negros del fondo se veían como cajas flotando; ahora no hay siluetas sueltas
	local x = rng:NextNumber(-1, 1) * M.RockSpread
	local h = rng:NextNumber(M.RockHeight.Min, M.RockHeight.Max)
	part("Ridge", Enum.PartType.Block, Vector3.new(rng:NextNumber(8, 20), h, rng:NextNumber(8, 16)),
		CFrame.new(O + Vector3.new(x, h / 2 - 8, -M.RockDistance - rng:NextNumber(0, 40))) * CFrame.Angles(0, rng:NextNumber(0, 6.28), rng:NextNumber(-0.2, 0.2)),
		M.Rock, Enum.Material.Slate)
end

local function surface(x, z)
	-- altura de la colina en (x, z) relativa al centro de la esfera
	local d2 = x * x + z * z
	local r = M.HillRadius
	return hillCenter.Y + math.sqrt(math.max(0, r * r - d2))
end

-- flores: naranjas que brillan y puntitos azules
for i = 1, M.Flowers do
	local x, z = rng:NextNumber(-1, 1) * M.FlowerSpread, rng:NextNumber(-1, 0.6) * M.FlowerSpread
	local orange = rng:NextNumber() < M.OrangeShare
	local size = orange and rng:NextNumber(0.35, 0.6) or rng:NextNumber(0.12, 0.22)
	local p = part("Flower", Enum.PartType.Ball, Vector3.one * size,
		CFrame.new(O.X + x, surface(x, z) + size * 0.4, O.Z + z), orange and M.Orange or M.Blue, Enum.Material.Neon)
	p:SetAttribute("Twinkle", not orange)
end

-- cielo: estrellas doradas en una cúpula delante de la cámara, y la luna
local stars = {}
for i = 1, M.Stars do
	local yaw = rng:NextNumber(-M.SkyYaw, M.SkyYaw)
	local pitch = rng:NextNumber(M.SkyPitch.Min, M.SkyPitch.Max)
	local dir = (CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)).LookVector
	local size = rng:NextNumber(M.StarSize.Min, M.StarSize.Max)
	local s = part("Star", Enum.PartType.Ball, Vector3.one * size, CFrame.new(O + dir * M.SkyRadius), M.Star, Enum.Material.Neon,
		rng:NextNumber(0, 0.35))
	table.insert(stars, s)
end
local moonDir = (CFrame.Angles(0, math.rad(M.MoonYaw), 0) * CFrame.Angles(math.rad(M.MoonPitch), 0, 0)).LookVector
local moon = part("Moon", Enum.PartType.Ball, Vector3.one * M.MoonSize, CFrame.new(O + moonDir * (M.SkyRadius - 20)), M.Moon, Enum.Material.Neon)
local moonLight = Instance.new("PointLight")
moonLight.Color = M.Moon
moonLight.Range = 60
moonLight.Brightness = 0.6
moonLight.Parent = moon

-- luz cálida sobre la colina para que el pasto y la espada se lean
local glow = part("Glow", Enum.PartType.Ball, Vector3.one, CFrame.new(O + M.LightOffset), M.Orange, Enum.Material.SmoothPlastic, 1)
local warm = Instance.new("PointLight")
warm.Color = M.WarmLight
warm.Range = M.WarmRange
warm.Brightness = M.WarmBrightness
warm.Parent = glow
local fill = Instance.new("PointLight") -- luz fría de luna desde la cámara
fill.Color = M.Moon
fill.Range = M.WarmRange
fill.Brightness = 0.8
fill.Parent = part("Fill", Enum.PartType.Ball, Vector3.one, CFrame.new(O + M.CameraOffset + Vector3.new(0, 6, -6)), M.Moon, Enum.Material.SmoothPlastic, 1)

-- la espada exclusiva, clavada y un poco inclinada
local swordPos = O + M.SwordOffset
local okSword, sword = pcall(WeaponBuilder.buildModel, "Sword", M.SwordSkin)
if okSword and sword then
	for _, d in sword:GetDescendants() do
		if d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanQuery = false end
	end
	sword.Parent = scene
	pcall(function() sword:ScaleTo(M.SwordScale) end)
	local cf, size = sword:GetBoundingBox()
	local handle = sword.PrimaryPart
	-- 12/11/2026 (pedido del usuario): de frente. Eje largo = el más largo de la caja (apuntando al mango);
	-- eje fino = el grosor de la hoja, que tiene que mirar a la cámara para que se vea la cara ancha.
	local axes = { { cf.RightVector, size.X }, { cf.UpVector, size.Y }, { cf.LookVector, size.Z } }
	table.sort(axes, function(a, b) return a[2] < b[2] end)
	local thin, long = axes[1][1], axes[3][1]
	if handle and (handle.Position - cf.Position):Dot(long) < 0 then long = -long end
	local target = (CFrame.Angles(0, 0, math.rad(M.SwordTilt)) * CFrame.Angles(math.rad(M.SwordLean), 0, 0)).UpVector
	local toCamera = ((O + M.CameraOffset) - swordPos) * Vector3.new(1, 0, 1)
	toCamera = toCamera.Magnitude > 0.01 and toCamera.Unit or Vector3.zAxis
	local face = (toCamera - target * toCamera:Dot(target)).Unit
	local source = CFrame.fromMatrix(Vector3.zero, long:Cross(thin).Unit, long)
	local goal = CFrame.fromMatrix(Vector3.zero, target:Cross(face).Unit, target)
	local rot = goal * source:Inverse()
	local length = math.max(size.X, size.Y, size.Z)
	local pivot = sword:GetPivot()
	-- llevar el centro de la caja al punto y rotar; después hundir la punta en la tierra
	local offset = pivot.Position - cf.Position
	sword:PivotTo(CFrame.new(swordPos + rot * offset + target * (length * (0.5 - M.SwordBuried))) * rot * pivot.Rotation)
end

scene.Parent = workspace

-- 12/11/2026: partículas del piso en movimiento (luciérnagas naranjas y azules que suben despacio)
local glowAttach = Instance.new("Attachment")
glowAttach.Parent = part("FireflyArea", Enum.PartType.Block, Vector3.new(M.FlowerSpread * 2, 1, M.FlowerSpread * 1.6),
	CFrame.new(O + Vector3.new(0, 4, -M.FlowerSpread * 0.2)), M.Orange, Enum.Material.SmoothPlastic, 1)
for _, spec in { { M.Orange, M.FireflyRate }, { M.Blue, M.FireflyRate * 0.6 } } do
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(spec[1])
	e.LightEmission = 1
	e.Brightness = 3
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, M.FireflySize),
		NumberSequenceKeypoint.new(0.8, M.FireflySize * 0.8), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(4, 8)
	e.Rate = spec[2]
	e.Speed = NumberRange.new(0.6, 1.6)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 0.35, 0)
	e.Drag = 0.4
	e.RotSpeed = NumberRange.new(-30, 30)
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	e.Parent = glowAttach.Parent
end
glowAttach:Destroy()

local flowerParts = {}
for _, d in scene:GetChildren() do if d.Name == "Flower" then table.insert(flowerParts, { part = d, base = d.CFrame, phase = rng:NextNumber(0, 6.28) }) end end
local twinkleConn = RunService.Heartbeat:Connect(function()
	for _ = 1, M.TwinklePerFrame do
		local s = stars[rng:NextInteger(1, #stars)]
		s.Transparency = rng:NextNumber(0, 0.6)
	end
	-- las flores se mecen con el viento
	local t = os.clock()
	for i = 1, #flowerParts, 3 do
		local f = flowerParts[i]
		f.part.CFrame = f.base + Vector3.new(math.sin(t * 1.3 + f.phase) * 0.15, math.sin(t * 2 + f.phase) * 0.06, 0)
	end
end)

----------------------------------------------------------------------
-- Cámara del menú
----------------------------------------------------------------------
local camStart = os.clock()
local function menuCamera()
	local t = os.clock() - camStart
	local drift = Vector3.new(math.sin(t * 0.07) * M.CameraDrift, math.sin(t * 0.11) * M.CameraDrift * 0.4, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = M.FieldOfView
	camera.CFrame = CFrame.lookAt(O + M.CameraOffset + drift, O + M.CameraLook)
end
RunService:BindToRenderStep("MainMenuCamera", Enum.RenderPriority.Camera.Value + 1, menuCamera)

-- Sin controles mientras está el menú
ContextActionService:BindActionAtPriority(BLOCK_ACTION, function() return Enum.ContextActionResult.Sink end, false,
	Enum.ContextActionPriority.High.Value, table.unpack(Enum.PlayerActions:GetEnumItems()))

-- Ocultar las otras pantallas (HUD, lobby, cola) hasta terminar el despertar
local hidden = {}
local KEEP = { MainMenu = true, LoadingScreenGui = true, SettingsGui = true, Settings = true }
local function hideOthers()
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and not KEEP[g.Name] then
			hidden[g] = true
			g.Enabled = false
		end
	end
end
local function restoreOthers()
	for g in hidden do if g.Parent then g.Enabled = true end end
	table.clear(hidden)
end

----------------------------------------------------------------------
-- Interfaz
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "MainMenu"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local shade = Instance.new("Frame")
shade.Name = "LeftShade"
shade.Size = UDim2.fromScale(0.55, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BorderSizePixel = 0
shade.Parent = gui
local shadeGrad = Instance.new("UIGradient")
shadeGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
shadeGrad.Parent = shade

local column = Instance.new("Frame")
column.Name = "Column"
column.BackgroundTransparency = 1
column.Position = UDim2.fromScale(0.06, 0.12)
column.Size = UDim2.fromOffset(460, 560)
column.Parent = gui
local colScale = Instance.new("UIScale")
colScale.Parent = column

UiTheme.label({ parent = column, size = UDim2.fromOffset(460, 70), text = "DARK FANTASY", font = "Title", textSize = 64,
	scaled = true, maxTextSize = 70, color = M.TitleColor })
UiTheme.label({ parent = column, position = UDim2.fromOffset(4, 70), size = UDim2.fromOffset(460, 44), text = "PLATAFORME",
	font = "Title", textSize = 40, scaled = true, maxTextSize = 44, color = M.TitleColor })
UiTheme.label({ parent = column, position = UDim2.fromOffset(6, 118), size = UDim2.fromOffset(460, 22), text = L.t("mm.subtitle"),
	font = "Header", textSize = UiTheme.TextSizes.SM, color = C.TextSecondary })

local buttons = {}
local function option(i, key, onClick)
	local b = Instance.new("TextButton")
	b.Name = key:sub(4) -- "play", "news", "settings"
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Position = UDim2.fromOffset(6, 200 + (i - 1) * M.OptionStep)
	b.Size = UDim2.fromOffset(300, M.OptionHeight)
	b.Text = L.t(key)
	b.FontFace = UiTheme.FontFaces.Title
	b.TextSize = M.OptionSize
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextColor3 = M.OptionColor
	b.SelectionImageObject = Instance.new("Frame")
	b.SelectionImageObject.BackgroundTransparency = 1
	b.Parent = column
	local function focus(on)
		TweenService:Create(b, TweenInfo.new(0.15), { TextColor3 = on and M.OptionHover or M.OptionColor,
			Position = UDim2.fromOffset(on and 22 or 6, b.Position.Y.Offset) }):Play()
	end
	b.MouseEnter:Connect(function() focus(true) end)
	b.MouseLeave:Connect(function() focus(false) end)
	b.SelectionGained:Connect(function() focus(true) end)
	b.SelectionLost:Connect(function() focus(false) end)
	b.Activated:Connect(function()
		UiTheme.playSound("UI_Click")
		onClick()
	end)
	buttons[i] = b
	return b
end

-- Novedades: panel a la derecha
local news = UiTheme.panel({ name = "News", parent = gui, anchor = Vector2.new(1, 0.5), position = UDim2.new(0.95, 0, 0.5, 0),
	size = UDim2.fromOffset(460, 340), bg = C.BgPanel, transparency = 0.1, ornaments = true, ornamentSize = 12 })
news.Visible = false
UiTheme.label({ parent = news, position = UDim2.fromOffset(24, 18), size = UDim2.new(1, -48, 0, 32), text = L.t("mm.newsTitle"),
	font = "Title", textSize = UiTheme.TextSizes.XL, color = C.GoldBright })
local newsBody = UiTheme.label({ parent = news, position = UDim2.fromOffset(24, 60), size = UDim2.new(1, -48, 1, -120),
	text = L.t("mm.newsBody"), font = "Body", textSize = UiTheme.TextSizes.SM, color = C.TextPrimary, alignY = Enum.TextYAlignment.Top })
newsBody.TextWrapped = true
UiTheme.button({ name = "CloseNews", parent = news, anchor = Vector2.new(1, 1), position = UDim2.new(1, -18, 1, -16),
	size = UDim2.fromOffset(120, 34), text = L.t("mm.close"), variant = "secondary", onClick = function() news.Visible = false end })

local started = false
local play -- definida abajo
option(1, "mm.play", function() play() end)
option(2, "mm.news", function() news.Visible = not news.Visible end)
option(3, "mm.settings", function()
	column.Visible = false
	player:SetAttribute("SettingsOpen", true)
end)
player:GetAttributeChangedSignal("SettingsOpen"):Connect(function()
	if not player:GetAttribute("SettingsOpen") and not started then
		column.Visible = true
		if Device.isGamepad() then GuiService.SelectedObject = buttons[3] end
	end
end)

local function layout()
	local vp = gui.AbsoluteSize
	colScale.Scale = math.clamp(math.min(vp.X / 1500, vp.Y / 850), 0.55, 1.2)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

----------------------------------------------------------------------
-- Despertar
----------------------------------------------------------------------
local fade = Instance.new("Frame")
fade.Name = "Fade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.ZIndex = 20
fade.Parent = gui

local lids = {}
for i, anchorY in { 0, 1 } do
	local lid = Instance.new("Frame")
	lid.Name = "Eyelid" .. i
	lid.AnchorPoint = Vector2.new(0.5, anchorY)
	lid.Position = UDim2.fromScale(0.5, anchorY)
	lid.Size = UDim2.fromScale(1.4, 0.5)
	lid.BackgroundColor3 = Color3.new(0, 0, 0)
	lid.BorderSizePixel = 0
	lid.ZIndex = 19
	lid.Visible = false
	lid.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = lid
	lids[i] = lid
end
local function eyes(open, time)
	-- open = 0 cerrado, 1 abierto: cada párpado se va de la pantalla
	local tw
	for i, lid in lids do
		local y = i == 1 and (0 - open * 0.55) or (1 + open * 0.55)
		tw = TweenService:Create(lid, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Position = UDim2.fromScale(0.5, y), Size = UDim2.fromScale(1.4, 0.5 + (1 - open) * 0.12) })
		tw:Play()
	end
	return tw
end

local function setLocalVisible(char, alpha)
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = alpha end
	end
end

local function ease(t) return t * t * (3 - 2 * t) end

local function wakeUp()
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart", 10)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root then return end
	-- esperar a que el servidor lo deje en su lugar (ciudad o patio del tutorial)
	task.wait(M.SettleTime)
	root = char:FindFirstChild("HumanoidRootPart") or root
	root.Anchored = true

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char, scene }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -20, 0), params)
	local ground = hit and hit.Position.Y or (root.Position.Y - 3)
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.01 and look.Unit or Vector3.zAxis
	local right = look:Cross(Vector3.yAxis)
	local base = Vector3.new(root.Position.X, ground, root.Position.Z)

	-- poses de cámara: acostado mirando el cielo → sentado → parado → tercera persona
	local lying = CFrame.lookAt(base + Vector3.yAxis * M.LieHeight - look * 0.8, base + Vector3.yAxis * 40 + look * 6)
	local sitting = CFrame.lookAt(base + Vector3.yAxis * M.SitHeight, base + Vector3.yAxis * M.SitHeight * 0.8 + look * 10)
	local standing = CFrame.lookAt(base + Vector3.yAxis * M.EyeHeight, base + Vector3.yAxis * M.EyeHeight + look * 10)
	local third = CFrame.lookAt(base + Vector3.yAxis * (M.EyeHeight + M.ThirdUp) - look * M.ThirdBack + right * M.ThirdSide,
		base + Vector3.yAxis * (M.EyeHeight - 0.4) + look * 6)

	local phase = "lying"
	local t0 = os.clock()
	local blur = Instance.new("BlurEffect")
	blur.Size = M.BlurStart
	blur.Parent = Lighting
	RunService:UnbindFromRenderStep("MainMenuCamera")
	RunService:BindToRenderStep("MainMenuCamera", Enum.RenderPriority.Camera.Value + 1, function()
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 70
		local t = os.clock() - t0
		local cf
		if phase == "lying" then
			cf = lying * CFrame.Angles(math.sin(t * 0.8) * 0.01, math.sin(t * 0.5) * 0.015, 0)
			setLocalVisible(char, 1)
		elseif phase == "sit" then
			cf = lying:Lerp(sitting, ease(math.min(1, t / M.SitTime)))
			setLocalVisible(char, 1)
		else
			local k = ease(math.min(1, t / M.StandTime))
			-- se para (sube) y a la vez la cámara sale de la cabeza hacia atrás
			local up = sitting:Lerp(standing, math.min(1, k * 1.6))
			cf = up:Lerp(third, k)
			setLocalVisible(char, k < 0.25 and 1 or (1 - math.min(1, (k - 0.25) / 0.35)))
		end
		camera.CFrame = cf
	end)

	-- ojos: dos parpadeos y se abren del todo
	for _, lid in lids do lid.Visible = true end
	eyes(0, 0)
	TweenService:Create(fade, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	task.wait(0.4)
	eyes(0.35, 0.7).Completed:Wait()
	eyes(0.05, 0.25).Completed:Wait()
	eyes(0.7, 0.6).Completed:Wait()
	eyes(0.45, 0.25).Completed:Wait()
	eyes(1, 0.9)
	TweenService:Create(blur, TweenInfo.new(2.2), { Size = 0 }):Play()
	task.wait(M.LieTime)

	phase, t0 = "sit", os.clock()
	task.wait(M.SitTime + 0.2)
	phase, t0 = "stand", os.clock()
	task.wait(M.StandTime)

	RunService:UnbindFromRenderStep("MainMenuCamera")
	blur:Destroy()
	setLocalVisible(char, 0)
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = hum
	if root.Parent then root.Anchored = false end
end

function play()
	if started or player:GetAttribute("InitialLoading") ~= false then return end
	started = true
	news.Visible = false
	GuiService.SelectedObject = nil
	TweenService:Create(fade, TweenInfo.new(0.5), { BackgroundTransparency = 0 }):Play()
	task.wait(0.55)
	column.Visible = false
	shade.Visible = false
	twinkleConn:Disconnect()
	scene:Destroy()
	local ok, err = pcall(wakeUp)
	if not ok then
		warn("[MainMenu] despertar:", err)
		RunService:UnbindFromRenderStep("MainMenuCamera")
		camera.CameraType = Enum.CameraType.Custom
		local char = player.Character
		if char then
			setLocalVisible(char, 0)
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then root.Anchored = false end
		end
	end
	ContextActionService:UnbindAction(BLOCK_ACTION)
	restoreOthers()
	player:SetAttribute("MainMenuOpen", false)
	gui:Destroy()
end

----------------------------------------------------------------------
-- Arranque: después de la pantalla de carga
----------------------------------------------------------------------
task.spawn(function()
	while player:GetAttribute("InitialLoading") ~= false do
		player:GetAttributeChangedSignal("InitialLoading"):Wait()
	end
end)
hideOthers()
-- las pantallas que se crean después (HUD, lobby) también esperan
player.PlayerGui.ChildAdded:Connect(function(g)
	if not started and g:IsA("ScreenGui") and not KEEP[g.Name] then
		task.defer(function()
			if not started and g.Enabled then hidden[g] = true g.Enabled = false end
		end)
	end
end)
if Device.isGamepad() then GuiService.SelectedObject = buttons[1] end
