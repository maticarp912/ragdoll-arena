-- LocalScript: StarterPlayer/StarterPlayerScripts/Sky (responsable: Claude, etapa 8)
-- Cielo de la referencia 01: muchísimas estrellas doradas de distintos tamaños y brillos, halos
-- cálidos en las grandes, resplandor dorado difuso y luna azulada. Todo local (sin red) y
-- autoiluminado (Neon + Bloom). La cúpula sigue a la cámara, así se ve igual en la ciudad y en
-- cualquier arena. Valores en Theme.Lighting.Stars.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Theme"))

local S = Theme.Lighting.Stars
local random = Random.new(S.Seed)

local dome = Instance.new("Model")
dome.Name = "GoldenStarDome"

local function ball(name, size, color, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * size
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0
	p.Parent = dome
	return p
end

-- Dirección al azar en la bóveda, con más densidad hacia arriba
local function skyDirection(minElevation)
	local u = random:NextNumber() ^ (1 - S.DenseBias)
	local elevation = minElevation + (1 - minElevation) * u
	local angle = random:NextNumber(0, math.pi * 2)
	local horizontal = math.sqrt(1 - elevation * elevation)
	return Vector3.new(math.cos(angle) * horizontal, elevation, math.sin(angle) * horizontal)
end

local function pickTier()
	local r = random:NextNumber()
	local acc = 0
	for _, tier in S.Tiers do
		acc += tier.share
		if r <= acc then return tier end
	end
	return S.Tiers[1]
end

-- Celulares: la mitad de estrellas
local mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local count = mobile and S.MobileCount or S.Count

local offsets = {} -- [parte] = posición relativa al centro de la cúpula
local twinkles = {}

-- Resplandor dorado difuso (manchas enormes casi transparentes detrás de las estrellas)
for i = 1, S.Glow.Count do
	local dir = skyDirection(S.Glow.Elevation[1])
	local size = random:NextNumber(S.Glow.Size[1], S.Glow.Size[2])
	local glow = ball("StarGlow", size, S.Glow.Color, S.Glow.Transparency)
	offsets[glow] = dir * (S.Radius + size)
end

for i = 1, count do
	local tier = pickTier()
	local size = random:NextNumber(tier.size[1], tier.size[2])
	local color = S.Colors[random:NextInteger(1, #S.Colors)]
	local dir = skyDirection(S.MinElevation)
	local star = ball("GoldenStar", size, color, 0)
	offsets[star] = dir * S.Radius
	if tier == S.Tiers[#S.Tiers] then
		local halo = ball("StarHalo", size * S.HaloScale, S.HaloColor, S.HaloTransparency)
		offsets[halo] = dir * (S.Radius + 1)
	end
	if #twinkles < S.TwinkleCount and random:NextNumber() < 0.25 then
		table.insert(twinkles, { part = star, speed = random:NextNumber(S.TwinkleSpeed[1], S.TwinkleSpeed[2]), phase = random:NextNumber(0, math.pi * 2) })
	end
end

-- Luna azulada con halo
local M = S.Moon
local moonDir = M.Direction.Unit
local moon = ball("BlueMoon", M.Size, M.Color, 0)
offsets[moon] = moonDir * S.Radius
local moonHalo = ball("BlueMoonHalo", M.Size * M.HaloScale, M.HaloColor, M.HaloTransparency)
offsets[moonHalo] = moonDir * (S.Radius + 2)

dome.Parent = workspace

-- Recentrar la cúpula en la cámara cuando se aleja (BulkMoveTo: un solo movimiento para todas las partes)
local parts, cframes = {}, {}
for p in offsets do table.insert(parts, p) end
local center = nil
local function recenter(at)
	center = at
	for i, p in parts do cframes[i] = CFrame.new(at + offsets[p]) end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local pos = cam.CFrame.Position
	if not center or (pos - center).Magnitude > S.FollowDistance then recenter(pos) end
	-- Titileo de una parte de las estrellas
	local t = os.clock()
	for _, tw in twinkles do
		tw.part.Transparency = (math.sin(t * tw.speed + tw.phase) * 0.5 + 0.5) * S.TwinkleDepth
	end
end)
