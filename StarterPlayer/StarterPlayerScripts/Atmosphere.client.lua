-- LocalScript: StarterPlayer/StarterPlayerScripts/Atmosphere
-- Ambiente dark fantasy en el cliente (valores en Theme.Ambience):
--   · lluvia alrededor de la cámara · viñeta oscura en los bordes · relámpagos ocasionales
--   · cuervos sobrevolando la ciudad · balanceo sutil de cámara en mano
--   · barrido de cámara sobre la ciudad la primera vez que apareces en el lobby
-- El balanceo es solo de posición: no altera hacia dónde mira la cámara (no se acumula).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local A = Theme.Ambience
local player = Players.LocalPlayer

----------------------------------------------------------------------
-- Lluvia
----------------------------------------------------------------------
local R = A.Rain
local rainPart = Instance.new("Part")
rainPart.Name = "RainEmitter"
rainPart.Anchored = true
rainPart.CanCollide = false
rainPart.CanQuery = false
rainPart.CanTouch = false
rainPart.Transparency = 1
rainPart.Size = Vector3.new(R.Area, 1, R.Area)
rainPart.Parent = workspace.CurrentCamera

local rain = Instance.new("ParticleEmitter")
rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
rain.Color = ColorSequence.new(R.Color)
rain.LightInfluence = 1
rain.Transparency = NumberSequence.new(R.Transparency)
rain.Size = NumberSequence.new(R.Size)
rain.Squash = NumberSequence.new(R.Stretch) -- negativo = estirada: gota alargada
rain.Orientation = Enum.ParticleOrientation.VelocityParallel
rain.EmissionDirection = Enum.NormalId.Bottom
rain.Speed = NumberRange.new(R.Speed)
rain.Lifetime = NumberRange.new(R.Lifetime)
rain.Rate = R.Rate
rain.SpreadAngle = Vector2.new(4, 4)
rain.Parent = rainPart

----------------------------------------------------------------------
-- Viñeta
----------------------------------------------------------------------
local V = A.Vignette
local gui = Instance.new("ScreenGui")
gui.Name = "DarkVignette"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = -2
gui.Parent = player:WaitForChild("PlayerGui")
local function edge(anchor, pos, size, rotation)
	local f = Instance.new("Frame")
	f.AnchorPoint = anchor
	f.Position = pos
	f.Size = size
	f.BorderSizePixel = 0
	f.BackgroundColor3 = V.Color
	f.BackgroundTransparency = V.Transparency
	f.Parent = gui
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	g.Transparency = NumberSequence.new(0, 1)
	g.Parent = f
end
edge(Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0), UDim2.fromScale(1, V.Width), 90)
edge(Vector2.new(0.5, 1), UDim2.fromScale(0.5, 1), UDim2.fromScale(1, V.Width), -90)
edge(Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), UDim2.fromScale(V.Width, 1), 0)
edge(Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), UDim2.fromScale(V.Width, 1), 180)

----------------------------------------------------------------------
-- Relámpagos (destello frío, doble)
----------------------------------------------------------------------
local LT = A.Lightning
local flash = Instance.new("ColorCorrectionEffect")
flash.Name = "LightningFlash"
flash.Parent = Lighting
task.spawn(function()
	while true do
		task.wait(LT.MinGap + math.random() * (LT.MaxGap - LT.MinGap))
		for _, strength in { 1, 0.6 } do
			flash.TintColor = LT.Tint
			flash.Brightness = LT.Flash * strength
			TweenService:Create(flash, TweenInfo.new(0.18), { Brightness = 0, TintColor = Color3.new(1, 1, 1) }):Play()
			task.wait(0.12 + math.random() * 0.1)
		end
	end
end)

----------------------------------------------------------------------
-- Cuervos dando vueltas sobre la ciudad
----------------------------------------------------------------------
local CR = A.Crows
local crows = {}
local crowFolder = Instance.new("Folder")
crowFolder.Name = "Crows"
crowFolder.Parent = workspace.CurrentCamera
for i = 1, CR.Count do
	local body = Instance.new("Part")
	body.Size = Vector3.new(0.6, 0.5, 1.6)
	body.Color = Color3.fromRGB(10, 10, 12)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.CastShadow = false
	body.Parent = crowFolder
	local wings = {}
	for _, s in { -1, 1 } do
		local w = body:Clone()
		w.Size = Vector3.new(2.2, 0.12, 1.1)
		w.Parent = crowFolder
		wings[s] = w
	end
	table.insert(crows, { body = body, wings = wings, phase = i / CR.Count * math.pi * 2, r = CR.Radius * (0.6 + math.random() * 0.6), h = CR.Height + math.random() * 25, speed = CR.Speed * (0.8 + math.random() * 0.5) })
end

----------------------------------------------------------------------
-- Cada frame: lluvia sigue a la cámara, cuervos, balanceo de cámara
----------------------------------------------------------------------
local B = A.CameraBob
RunService:BindToRenderStep("DarkAmbience", Enum.RenderPriority.Camera.Value + 4, function()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local t = os.clock()
	rainPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, R.Height, 0))

	for _, c in crows do
		local a = c.phase + t * c.speed
		local pos = CR.Center + Vector3.new(math.cos(a) * c.r, c.h + math.sin(t * 0.7 + c.phase) * 3, math.sin(a) * c.r)
		local ahead = CR.Center + Vector3.new(math.cos(a + 0.05) * c.r, c.h, math.sin(a + 0.05) * c.r)
		local cf = CFrame.lookAt(pos, ahead)
		c.body.CFrame = cf
		local flap = math.sin(t * 9 + c.phase) * 0.6
		c.wings[-1].CFrame = cf * CFrame.new(-1.1, 0, 0) * CFrame.Angles(0, 0, flap)
		c.wings[1].CFrame = cf * CFrame.new(1.1, 0, 0) * CFrame.Angles(0, 0, -flap)
	end

	-- Balanceo en mano (solo posición) con la cámara normal
	if camera.CameraType == Enum.CameraType.Custom then
		local nx = math.noise(t * B.Speed, 1.3) * B.Amount
		local ny = math.noise(t * B.Speed, 7.9) * B.Amount
		camera.CFrame = camera.CFrame * CFrame.new(nx, ny, 0)
	end
end)

----------------------------------------------------------------------
-- Barrido de cámara sobre la ciudad la primera vez que apareces en el lobby
----------------------------------------------------------------------
local I = A.Intro
local introDone = false
local function intro(char)
	if introDone or player:GetAttribute("InMatch") then return end
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root then return end
	task.wait(0.3)
	introDone = true
	local camera = workspace.CurrentCamera
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local target = root.Position + Vector3.new(0, 3, 0)
	local from = CFrame.lookAt(target + look * I.Back + Vector3.new(0, I.Height, 0), target + look * 20)
	local to = CFrame.lookAt(target - look * 15 + Vector3.new(0, 6, 0), target)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = from
	local tw = TweenService:Create(camera, TweenInfo.new(I.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = to })
	tw:Play()
	tw.Completed:Wait()
	camera.CameraType = Enum.CameraType.Custom
end
player.CharacterAdded:Connect(intro)
if player.Character then task.spawn(intro, player.Character) end
