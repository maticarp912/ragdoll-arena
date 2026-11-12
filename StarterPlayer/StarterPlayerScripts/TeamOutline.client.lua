-- LocalScript: StarterPlayer/StarterPlayerScripts/TeamOutline
-- 12/11/2026 (pedido del usuario): en partida, contorno azul para tu compañero y rojo para los rivales.
-- Solo contorno (sin relleno). Cada cliente arma los suyos: el color depende de quién mira.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))

local P = Polish.TeamOutline
local player = Players.LocalPlayer
local outlines = {} -- [Player] = Highlight

local function clear(other)
	local h = outlines[other]
	if h then h:Destroy() end
	outlines[other] = nil
end

local function refresh()
	local mine = player:GetAttribute("InMatch") == true and player.Team
	for _, other in Players:GetPlayers() do
		local char = other.Character
		local show = mine and other ~= player and char and other:GetAttribute("InMatch") == true and other.Team ~= nil
			and not other:GetAttribute("Eliminated")
		if not show then
			clear(other)
		else
			local h = outlines[other]
			if not h or h.Adornee ~= char or not h.Parent then
				clear(other)
				h = Instance.new("Highlight")
				h.Name = "TeamOutline"
				h.FillTransparency = 1
				h.OutlineTransparency = P.Transparency
				h.DepthMode = Enum.HighlightDepthMode.Occluded
				h.Adornee = char
				h.Parent = char
				outlines[other] = h
			end
			h.OutlineColor = other.Team == player.Team and P.Ally or P.Enemy
		end
	end
end

Players.PlayerRemoving:Connect(clear)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < P.Interval then return end
	acc = 0
	refresh()
end)
