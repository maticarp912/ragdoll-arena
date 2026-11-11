-- Script: ServerScriptService/MonetizationService
-- 11/11/2026: pone en marcha MonetizationManager, registra qué entrega cada tipo de producto y abre el remoto
-- "Monetization" (acciones: Catalog, Prompt). Los efectos de los pases (VIP, Skip) los aplica cada servicio
-- leyendo el atributo Pass_<clave> o Manager.ownsPass.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RunService = game:GetService("RunService")
local Manager = require(ServerScriptService:WaitForChild("MonetizationManager"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Config = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))
local Rewards = require(ReplicatedStorage:WaitForChild("Rewards"))
local Skins = require(ReplicatedStorage:WaitForChild("Skins"))
local Auras = require(ReplicatedStorage:WaitForChild("Auras"))

-- Qué entrega cada tipo. Se aplica a una copia del perfil; si devuelve true se guarda y recién ahí se confirma.
Manager.registerKind("Souls", function(_, product, data)
	data.Coins = (data.Coins or 0) + product.amount -- comprado: no lo multiplican los multiplicadores
	return true
end)
Manager.registerKind("Spins", function(_, product, data)
	data.Rewards = data.Rewards or {}
	data.Rewards.spins = math.min(Rewards.MaxCount, (data.Rewards.spins or 0) + product.amount)
	return true
end, function(_, product, data)
	return ((data.Rewards and data.Rewards.spins) or 0) + product.amount <= Rewards.MaxCount
end)
Manager.registerKind("Luck", function(_, product, data)
	data.Boosts = data.Boosts or {}
	-- Rewards.Luck (Codex) aplica Luck y LuckSeconds a las rarezas de los cofres y muestra el cambio en las probabilidades
	data.Boosts.Luck = math.max(data.Boosts.Luck or 1, product.multiplier)
	data.Boosts.LuckSeconds = math.min((data.Boosts.LuckSeconds or 0) + product.seconds, product.maxSeconds or product.seconds * 4)
	return true
end, function(_, product, data)
	return ((data.Boosts and data.Boosts.LuckSeconds) or 0) + product.seconds <= (product.maxSeconds or product.seconds * 4)
end)
Manager.registerKind("Aura", function(_, product, data)
	data.OwnedAuras = data.OwnedAuras or {}
	data.OwnedAuras[product.item] = true
	return true
end)
Manager.registerKind("Skin", function(_, product, data)
	data.OwnedSkins = data.OwnedSkins or {}
	data.OwnedSkins[product.item] = true
	return true
end)

-- Auras y skins premium: llevan productId en su catálogo
for id, aura in Auras.Data do
	if (aura.productId or 0) > 0 then Manager.registerProduct("Aura." .. id, { id = aura.productId, kind = "Aura", item = id }) end
end
for id, skin in Skins.Data do
	if (skin.productId or 0) > 0 then Manager.registerProduct("Skin." .. id, { id = skin.productId, kind = "Skin", item = id }) end
end

-- Remoto para la interfaz
local RF = Remotes.get("Monetization", "RemoteFunction")
RF.OnServerInvoke = function(player, action, key)
	if type(action) ~= "string" or #action > 20 then return false, "invalid" end
	if action == "Catalog" then
		return true, Manager.catalog(player)
	elseif action == "StudioTest" and RunService:IsStudio() then
		-- Solo en Studio (no hay DataStore y los recibos no se pueden guardar): entrega el producto en memoria
		-- para probar la interfaz y los efectos. Nunca existe en el juego publicado.
		local product = type(key) == "string" and Config.Products[key]
		local data = PlayerData.get(player)
		if not product or not data then return false, "invalid" end
		local ok = Manager.grantForTest(player, product, data)
		PlayerData.refresh(player)
		return ok
	elseif action == "Prompt" then
		if type(key) ~= "string" or #key > 40 then return false, "invalid" end
		return Manager.prompt(player, key)
	end
	return false, "invalid"
end

Players.PlayerAdded:Connect(Manager.track)
for _, player in Players:GetPlayers() do Manager.track(player) end
