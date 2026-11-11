-- Script: ServerScriptService/TitleService
-- 11/11/2026: equipar títulos. Remoto "Titles" (RemoteFunction):
--   "List"          → { titles = { { id, owned, progress, goal, price, source, rarity }... }, equipped = id }
--   "Equip", id     → equipa (id = "" lo quita). Solo títulos que el servidor confirma que tenés.
--   "Buy", id       → compra con almas un título de tienda (source = "shop") y lo equipa.
-- Publica el atributo Title del jugador (lo leen la tarjeta y la interfaz). Se guarda en data.EquippedTitle.
-- Si no elegiste ninguno, se usa el de tu rol (el Owner muestra «El Rey Muerto»).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Titles = require(ReplicatedStorage:WaitForChild("Titles"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))

local RF = Remotes.get("Titles", "RemoteFunction")
local last = {}

local function passes(player)
	return { VIP = player:GetAttribute("Pass_VIP") == true }
end

local function owns(player, id)
	local data = PlayerData.get(player)
	return Titles.owns(id, data and data.Titles, player:GetAttribute("Role"), passes(player), data and data.Stats)
end

local function roleTitle(player)
	local role = player:GetAttribute("Role")
	for _, id in Titles.Order do
		if Titles.Data[id].role and Titles.Data[id].role == role then return id end
	end
	return ""
end

local function publish(player)
	local data = PlayerData.get(player)
	if not data then return end
	local id = type(data.EquippedTitle) == "string" and data.EquippedTitle or ""
	if id ~= "" and not owns(player, id) then id = "" end
	if id == "" and data.EquippedTitle == nil then id = roleTitle(player) end
	player:SetAttribute("Title", id)
end

RF.OnServerInvoke = function(player, action, id)
	if type(action) ~= "string" or #action > 12 then return false end
	local now = os.clock()
	if last[player] and now - last[player] < 0.4 then return false, "wait" end
	last[player] = now
	local data = PlayerData.get(player)
	if not data then return false, "loading" end
	if action == "List" then
		local list = {}
		local stats = data.Stats or {}
		for _, tid in Titles.Order do
			local t = Titles.Data[tid]
			local mine = owns(player, tid)
			-- Los de rol solo se muestran a quien los tiene
			if mine or not t.role then
				table.insert(list, { id = tid, owned = mine, source = t.source, rarity = t.rarity, price = t.price,
					goal = t.goal, progress = t.stat and math.min(tonumber(stats[t.stat]) or 0, t.goal or 0) or nil, hint = t.hint })
			end
		end
		return true, { titles = list, equipped = player:GetAttribute("Title") or "" }
	elseif action == "Buy" then
		local t = type(id) == "string" and Titles.Data[id]
		if not t or t.source ~= "shop" or type(t.price) ~= "number" then return false, "invalid" end
		if owns(player, id) then return false, "alreadyOwned" end
		if not PlayerData.canMutate(player) then return false, "loading" end
		if (data.Coins or 0) < t.price then return false, "noCoins" end
		-- Sin esperas entre comprobar y cobrar: el cambio es atómico en memoria y se guarda después
		data.Coins -= t.price
		data.Titles = data.Titles or {}
		data.Titles[id] = true
		data.EquippedTitle = id
		PlayerData.refresh(player)
		PlayerData.saveSoon(player)
		publish(player)
		return true
	elseif action == "Equip" then
		if type(id) ~= "string" or #id > 64 then return false, "invalid" end
		if id ~= "" and not owns(player, id) then return false, "notOwned" end
		data.EquippedTitle = id
		PlayerData.saveSoon(player)
		publish(player)
		return true
	end
	return false, "invalid"
end

local function track(player)
	-- Espera el perfil y el rol; se vuelve a publicar si cambian el rol o el pase VIP
	task.spawn(function()
		for _ = 1, 60 do
			if PlayerData.get(player) or not player.Parent then break end
			task.wait(0.5)
		end
		if player.Parent then publish(player) end
	end)
	player:GetAttributeChangedSignal("Role"):Connect(function() publish(player) end)
	player:GetAttributeChangedSignal("Pass_VIP"):Connect(function() publish(player) end)
end

Players.PlayerAdded:Connect(track)
for _, p in Players:GetPlayers() do track(p) end
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
