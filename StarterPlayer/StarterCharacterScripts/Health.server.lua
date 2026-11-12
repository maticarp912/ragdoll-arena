-- Sustituye el Health de Roblox. La curación pasiva queda en el lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local policy = require(ReplicatedStorage:WaitForChild("CombatConfig")).LobbyHealth
local char = script.Parent
local player = Players:GetPlayerFromCharacter(char)
local humanoid = char:WaitForChild("Humanoid")

while player and player.Character == char and humanoid.Health > 0 do
	local elapsed = task.wait(policy.Interval)
	if player.Character == char and not player:GetAttribute("InMatch") and humanoid.Health > 0 then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * policy.Fraction * elapsed)
	end
end
