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
local Economy = require(ReplicatedStorage:WaitForChild("Economy"))
local Skins = require(ReplicatedStorage:WaitForChild("Skins"))
local Auras = require(ReplicatedStorage:WaitForChild("Auras"))

-- Qué entrega cada tipo. Se aplica a una copia del perfil; si devuelve true se guarda y recién ahí se confirma.
Manager.registerKind("Gems", function(_, product, data)
	data.Gems = (data.Gems or 0) + product.amount
	return true
end, function(_, product, data)
	return data.Gems + product.amount <= Economy.GemMax
end)
Manager.registerKind("Spins", function(_, product, data)
	data.Rewards = data.Rewards or {}
	data.Rewards.boughtSpins = (data.Rewards.boughtSpins or 0) + product.amount
	return true
end, function(_, product, data)
	return ((data.Rewards and data.Rewards.boughtSpins) or 0) + product.amount <= Rewards.MaxCount
end)
Manager.registerKind("Luck", function(_, product, data)
	local multiplier, remaining = Rewards.Luck(data, os.time())
	data.Boosts.Luck = math.max(multiplier, product.multiplier)
	data.Boosts.LuckSeconds = remaining + product.seconds
	return true
end, function(_, product, data)
	local _, remaining = Rewards.Luck(data, os.time(), true)
	return remaining + product.seconds <= product.maxSeconds
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
end, function(player, product)
	return not PlayerData.owns(player, "OwnedSkins", product.item)
end)

-- Auras y skins premium: llevan productId en su catálogo
for id, aura in Auras.Data do
	if (aura.productId or 0) > 0 and not aura.requiredPass then Manager.registerProduct("Aura." .. id, { id = aura.productId, kind = "Aura", item = id }) end
end
for id, skin in Skins.Data do
	if skin.currency == "Robux" and (skin.productId or 0) > 0 and not skin.roulette and not skin.boxOnly and not skin.comingSoon then Manager.registerProduct("Skin." .. id, { id = skin.productId, kind = "Skin", item = id }) end
end

-- Remoto para la interfaz
local RF = Remotes.get("Monetization", "RemoteFunction")
local catalogBusy = {}
local catalogAt = {}
local buyAt = {}
Players.PlayerRemoving:Connect(function(player) catalogBusy[player] = nil catalogAt[player] = nil buyAt[player] = nil end)
RF.OnServerInvoke = function(player, action, key)
	if type(action) ~= "string" or #action > 20 then return false, "invalid" end
	if action == "Catalog" then
		if key ~= nil and (type(key) ~= "string" or #key > 40 or not Config.Passes[key]) then return false, "invalid" end
		local now = os.clock()
		if catalogBusy[player] or (catalogAt[player] and now - catalogAt[player] < Config.PromptCooldown) then return false, "wait" end
		catalogAt[player] = now catalogBusy[player] = true
		local ok, list = pcall(Manager.catalog, player, key)
		catalogBusy[player] = nil
		return ok, ok and list or "unavailable"
	elseif action == "StudioTest" and RunService:IsStudio() then
		-- Solo en Studio (no hay DataStore y los recibos no se pueden guardar): entrega el producto en memoria
		-- para probar la interfaz y los efectos. Nunca existe en el juego publicado.
		local product = type(key) == "string" and Config.Products[key]
		local data = PlayerData.get(player)
		if not product or not data or not PlayerData.canMutate(player) then return false, "invalid" end
		local ok = Manager.grantForTest(player, product, data)
		PlayerData.refresh(player)
		if ok then player:SetAttribute("PurchaseVersion", (player:GetAttribute("PurchaseVersion") or 0) + 1) end
		return ok
	elseif action == "BuySkinGems" then
		if type(key) ~= "string" or #key > Rewards.MaxIdLength then return false, { key = "invalid" } end
		local now = os.clock()
		if buyAt[player] and now - buyAt[player] < Economy.ShopInterval then return false, { key = "cx.shop.wait" } end
		buyAt[player] = now
		local skin = Skins.Data[key]
		if not skin or skin.currency ~= "Gems" or skin.roulette or skin.boxOnly or skin.comingSoon then
			return false, { key = "invalid" }
		end
		if PlayerData.owns(player, "OwnedSkins", key) then return false, { key = "alreadyOwned" } end
		local ok, message, missing = PlayerData.buyCosmetic(player, key, skin.price, false, "Gems")
		return ok, { key = message, missing = missing }
	elseif action == "Prompt" then
		if type(key) ~= "string" or #key > 40 then return false, "invalid" end
		return Manager.prompt(player, key)
	end
	return false, "invalid"
end

Players.PlayerAdded:Connect(Manager.track)
for _, player in Players:GetPlayers() do Manager.track(player) end
