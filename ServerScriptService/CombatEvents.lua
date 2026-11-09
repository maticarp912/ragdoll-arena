-- ModuleScript: ServerScriptService/CombatEvents
-- Responsable: Claude. Contrato de la etapa 8: avisos del combate para estadísticas, misiones
-- y tablas de clasificación (los escucha Codex; no hace falta tocar Combat).
--
--   CombatEvents.Fired:Connect(function(kind, attackerChar, victimChar, info) ... end)
--
-- kind:
--   "Damage"     info.amount = vida quitada de verdad
--   "Knockdown"  derribo por Stun (attacker = último que lo golpeó, puede ser nil)
--   "Kill"       muerte, también por caída al vacío (attacker = último que lo golpeó en
--                CombatConfig.Credit.Window segundos, puede ser nil)
--   "GuardBreak" attacker rompió la guardia de victim
--   "Parry"      attacker = quien parreó, victim = el parreado
--   "Throw"      attacker lanzó a victim
-- Los personajes pueden ser muñecos: Players:GetPlayerFromCharacter devuelve nil para ellos.
-- En partida, el jugador tiene el atributo InMatch = true.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))

local CombatEvents = {}
local event = Instance.new("BindableEvent")
CombatEvents.Fired = event.Event

local last = setmetatable({}, { __mode = "k" }) -- [víctima] = { atacante, hora }

function CombatEvents.noteAttacker(victim, attacker)
	if victim and attacker and attacker ~= victim then
		last[victim] = { attacker, os.clock() }
	end
end

function CombatEvents.lastAttacker(victim)
	local entry = last[victim]
	if entry and os.clock() - entry[2] <= CombatConfig.Credit.Window and entry[1].Parent then
		return entry[1]
	end
	return nil
end

function CombatEvents.fire(kind, attacker, victim, info)
	event:Fire(kind, attacker, victim, info or {})
end

return CombatEvents
