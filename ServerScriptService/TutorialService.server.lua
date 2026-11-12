-- Script: ServerScriptService/TutorialService
-- Responsable: Claude (0.2, ronda 2). Certifica en el servidor los 3 pasos del tutorial del patio y se los
-- informa a RewardService.tutorial(player, paso) (Codex), que paga cada paso una sola vez (Rewards.TutorialSouls).
-- 12/11/2026: el panel viejo del patio (Tutorial.client) se sacó; los pasos se siguen pagando en silencio
--   Paso 1: pegarle 3 veces a un muñeco (CombatEvents "Damage", víctima con IsDummy).
--   Paso 2: ponerse en guardia cerca de un muñeco (atributo Blocking que pone el servidor).
--   Paso 3: patear a un muñeco (CombatEvents "Kick").
-- Solo cuenta fuera de partida (la práctica del patio).

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Combat = require(ServerScriptService:WaitForChild("Combat"))
local CombatEvents = require(ServerScriptService:WaitForChild("CombatEvents"))
local RewardService = require(ServerScriptService:WaitForChild("RewardService"))

local HITS_NEEDED = 3
local DUMMY_RANGE = 45

local hits = {}
Players.PlayerRemoving:Connect(function(p) hits[p] = nil end)

local function practicing(player)
	return player ~= nil and player.Parent ~= nil and player:GetAttribute("InMatch") ~= true
end

local function step(player, n)
	local ok, err = pcall(RewardService.tutorial, player, n)
	if not ok then warn("[Tutorial] paso", n, err) end
end

CombatEvents.Fired:Connect(function(kind, attacker, victim)
	local player = attacker and Players:GetPlayerFromCharacter(attacker)
	if not practicing(player) or not (victim and victim:GetAttribute("IsDummy")) then return end
	if kind == "Damage" then
		hits[player] = (hits[player] or 0) + 1
		if hits[player] >= HITS_NEEDED then step(player, 1) end
	elseif kind == "Kick" then
		step(player, 3)
	end
end)

local function nearDummy(char)
	local root = char:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("Dummies")
	if not root or not folder then return false end
	for _, d in folder:GetChildren() do
		local r = d:FindFirstChild("HumanoidRootPart")
		if r and Combat.isEnemy(char, d) and (r.Position - root.Position).Magnitude <= DUMMY_RANGE then return true end
	end
	return false
end

local function onCharacter(player, char)
	char:GetAttributeChangedSignal("Blocking"):Connect(function()
		if char:GetAttribute("Blocking") and practicing(player) and nearDummy(char) then step(player, 2) end
	end)
end

local function onPlayer(player)
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
	if player.Character then onCharacter(player, player.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end

