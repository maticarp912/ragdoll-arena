-- LocalScript: StarterPlayer/StarterPlayerScripts/Arena (Ronda 3B, responsable: Gemini)
-- Oscilación y giro suave en el cliente de las rocas y fragmentos etiquetados como "FloatingRock".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Collection = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Theme = require(ReplicatedStorage:WaitForChild("Theme", 10))
local Config = require(ReplicatedStorage:WaitForChild("ArenaConfig", 10))
local N = Theme.Metrics

local rocks = {}
local function add(p)
	if p:IsA("BasePart") then
		rocks[p] = p.CFrame
	end
end

for _, p in Collection:GetTagged("FloatingRock") do
	add(p)
end
Collection:GetInstanceAddedSignal("FloatingRock"):Connect(add)
Collection:GetInstanceRemovedSignal("FloatingRock"):Connect(function(p)
	rocks[p] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow() * Config.RockSpeed
	for p, cf in rocks do
		if p.Parent then
			local phase = t + cf.Position.X
			p.CFrame = cf
				* CFrame.new(N.Zero, math.sin(phase) * Config.RockBob, N.Zero)
				* CFrame.Angles(math.cos(phase) * Config.RockRoll, N.Zero, math.sin(phase) * Config.RockRoll)
		end
	end
end)

