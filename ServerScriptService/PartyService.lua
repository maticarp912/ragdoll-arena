-- ModuleScript: ServerScriptService/PartyService
-- 11/11/2026: party de 2 jugadores (máximo, por ahora).
--   · Cualquiera invita a otro jugador del servidor; el invitado acepta o rechaza (la invitación vence sola).
--   · Solo el líder (quien invitó) busca partida y mete a los dos. En 2v2 van en el mismo equipo; en 1v1 se
--     enfrentan entre ellos (duelo privado).
-- Remoto "Party" (RemoteFunction): "Invite", userId · "Accept" · "Decline" · "Leave"
-- Atributos del jugador: PartyLeader (UserId o 0), PartyPartner (UserId o 0), PartyInvite (UserId de quien invita o 0).
-- MatchService usa Party.partner / Party.isLeader / Party.Changed.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))

local Party = {}
Party.MaxSize = 2
Party.InviteSeconds = 30

local changed = Instance.new("BindableEvent")
Party.Changed = changed.Event -- (player) cuando cambia la party de alguien

local leaderOf = {} -- [jugador] = líder de su party
local memberOf = {} -- [líder] = el otro jugador
local invites = {}  -- [invitado] = { from = jugador, at = os.clock() }
local last = {}

local function publish(p)
	if not p.Parent then return end
	local leader = leaderOf[p]
	local partner = Party.partner(p)
	p:SetAttribute("PartyLeader", leader and leader.UserId or 0)
	p:SetAttribute("PartyPartner", partner and partner.UserId or 0)
	local inv = invites[p]
	p:SetAttribute("PartyInvite", inv and inv.from.UserId or 0)
end

function Party.partner(p)
	local leader = leaderOf[p]
	if not leader then return nil end
	if leader == p then return memberOf[p] end
	return leader
end
function Party.isLeader(p) return leaderOf[p] == p end
function Party.inParty(p) return leaderOf[p] ~= nil end

local function disband(p)
	local leader = leaderOf[p]
	if not leader then return end
	local member = memberOf[leader]
	leaderOf[leader] = nil
	memberOf[leader] = nil
	if member then leaderOf[member] = nil end
	publish(leader) changed:Fire(leader)
	if member then publish(member) changed:Fire(member) end
end

local function clearInvite(target)
	if invites[target] then invites[target] = nil publish(target) end
end

local RF = Remotes.get("Party", "RemoteFunction")
RF.OnServerInvoke = function(player, action, userId)
	if type(action) ~= "string" or #action > 10 then return false, "invalid" end
	local now = os.clock()
	if last[player] and now - last[player] < 0.5 then return false, "wait" end
	last[player] = now
	if action == "Invite" then
		if type(userId) ~= "number" or userId ~= userId then return false, "invalid" end
		local target = Players:GetPlayerByUserId(userId)
		if not target or target == player then return false, "invalid" end
		if Party.inParty(player) and not Party.isLeader(player) then return false, "notLeader" end
		if Party.partner(player) then return false, "full" end
		if Party.inParty(target) then return false, "busy" end
		invites[target] = { from = player, at = now }
		publish(target)
		task.delay(Party.InviteSeconds, function()
			local inv = invites[target]
			if inv and inv.from == player and inv.at == now then clearInvite(target) end
		end)
		return true
	elseif action == "Accept" then
		local inv = invites[player]
		clearInvite(player)
		if not inv or now - inv.at > Party.InviteSeconds or not inv.from.Parent then return false, "expired" end
		local leader = inv.from
		if Party.inParty(player) or Party.partner(leader) or (Party.inParty(leader) and not Party.isLeader(leader)) then
			return false, "busy"
		end
		leaderOf[leader] = leader
		leaderOf[player] = leader
		memberOf[leader] = player
		publish(leader) publish(player)
		changed:Fire(leader) changed:Fire(player)
		return true
	elseif action == "Decline" then
		clearInvite(player)
		return true
	elseif action == "Leave" then
		disband(player)
		return true
	end
	return false, "invalid"
end

Players.PlayerRemoving:Connect(function(p)
	disband(p)
	invites[p] = nil
	last[p] = nil
	for target, inv in invites do
		if inv.from == p then clearInvite(target) end
	end
end)

return Party
