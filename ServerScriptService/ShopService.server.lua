local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Theme"))
local N = Theme.Metrics
local E = require(game:GetService("ReplicatedStorage"):WaitForChild("Economy"))
-- Script: ServerScriptService/ShopService
-- Tienda de skins (monedas o Robux) y selección de arma.
-- (Fase E: desbloqueos de armas/infusiones con monedas o Robux.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

local Auras = require(ReplicatedStorage:WaitForChild("Auras"))
local Skins = require(ReplicatedStorage:WaitForChild("Skins"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local Infusions = require(ReplicatedStorage:WaitForChild("Infusions"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Combat = require(ServerScriptService:WaitForChild("Combat"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))

local ShopRF = Remotes.get("Shop", "RemoteFunction")
local SettingsRF = Remotes.get("Settings", "RemoteFunction")
local RunService = game:GetService("RunService")
local InputMap = require(ReplicatedStorage:WaitForChild("InputMap"))
local RoleService = require(ServerScriptService:WaitForChild("RoleService"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))

-- Herramientas de prueba (monedas gratis) solo en Studio o para quien tenga permiso
local function canDebug(player)
	if RunService:IsStudio() or RoleService.has(player, "Debug") then return true end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then return true end
	return table.find(CombatConfig.Debug.AllowedUserIds, player.UserId) ~= nil
end

-- Controles reasignables (teclado y mando)
SettingsRF.OnServerInvoke = function(player, action, payload)
	if type(action) ~= "string" then return nil end
	local data = PlayerData.get(player)
	if not data then return nil end
	if action == "GetOptions" then return PlayerData.getOptions(player)
 elseif action == "SetOptions" then
  local options = PlayerData.setOptions(player, payload)
  if options then PlayerData.saveSoon(player) end
  return options
 elseif action == "SetLanguage" then
		if not PlayerData.setLanguage(player, payload) then return nil end
		PlayerData.saveSoon(player)
		return payload
	elseif action == "GetBinds" then
		return InputMap.merge(data.Keybinds)
	elseif action == "SetBinds" then
		if type(payload) ~= "table" then return nil end
		local binds = InputMap.merge(payload)
		PlayerData.setKeybinds(player, binds)
		return binds
	elseif action == "ResetBinds" then
		PlayerData.setKeybinds(player, nil)
		return InputMap.merge(nil)
	end
	return nil
end

-- En el lobby, rehace el arma al momento (sin perder la práctica). En partida no se permite cambiar la seleccion.
local function refreshWeapon(player: Player)
	if player:GetAttribute("InMatch") then return end
	local char = player.Character
	if char then Combat.setupCharacter(player, char) end
end

local shopAt, shopBusy = {}, {}
Players.PlayerRemoving:Connect(function(player) shopAt[player]=nil shopBusy[player]=nil end)
local function shopAction(player, action, id)
	-- Integración 0.2: GetFeatured no lleva id (la tienda lo pide sin argumento y antes se rechazaba)
	if type(action) ~= "string" or (type(id) ~= "string" and action ~= "GetFeatured") then
		return false, { key = "invalid" }
	end
	if player:GetAttribute("InMatch") and player:GetAttribute("MatchPhase") ~= "Prematch" and (action == "SelectWeapon" or action == "SelectInfusion" or action == "Equip") then
  return false, { key = "locked" }
 end
 local data = PlayerData.get(player)
	if not data then return false, { key = "loading" } end
 if action == "GetFeatured" then
  local ids = {} for skinId, skin in Skins.Data do if skinId ~= "Default" and not skin.comingSoon and not skin.roulette then table.insert(ids, skinId) end end
  table.sort(ids) local result = {} local day = math.floor((os.time() - E.DayOffset) / E.DaySeconds)
  for i = 1, math.min(E.FeaturedCount, #ids) do table.insert(result, ids[(day * E.FeaturedCount + i - 1) % #ids + 1]) end
  return true, { ids = result, resetAt = (day + 1) * E.DaySeconds + E.DayOffset }
 end

	if action == "BuyAura" or action == "EquipAura" or action == "UnequipAura" then
  if player:GetAttribute("InMatch") and player:GetAttribute("MatchPhase") ~= "Prematch" then return false, { key = "locked" } end
  if action == "UnequipAura" then
   PlayerData.equipAura(player, "") PlayerData.saveSoon(player)
   return true, { key = "cx.aura.removed" }
  end
  local aura=Auras.Data[id]
  if not aura then return false, { key = "invalid" } end
  if action == "EquipAura" then
   if not PlayerData.equipAura(player,id) then return false, { key = "notOwned" } end
   PlayerData.saveSoon(player) return true, { key = "cx.aura.equipped" }
  end
  if PlayerData.owns(player, "OwnedAuras", id) then return false, { key = "alreadyOwned" } end
  if aura.currency == "Coins" then
   local ok,key=PlayerData.buyCosmetic(player,id,aura.price,true)
   return ok, { key = key }
  elseif aura.currency == "Robux" then
   if aura.productId <= E.Zero then return false, { key = "soon" } end
   MarketplaceService:PromptProductPurchase(player,aura.productId)
   return true, { key = "robloxConfirm" }
  end
  return false, { key = "invalid" }
 elseif action == "DebugResetPurchases" then
  if not canDebug(player) or player:GetAttribute("InMatch") then return false, { key = "invalid" } end
  PlayerData.resetTestPurchases(player) refreshWeapon(player)
  local saved = PlayerData.save(player)
  return true, { key = saved and "cx.debug.resetDone" or "cx.debug.temporary" }
 elseif action == "DebugCoins" then
		if not canDebug(player) then return false, { key = "debug" } end
		local amount = E.DebugAmounts[id]
  if not amount then return false, { key = "invalid" } end
  PlayerData.addCoins(player, amount)
  local saved = PlayerData.save(player)
  return true, { key = saved and "cx.debug.added" or "cx.debug.temporary", params = { amount = amount } }

	elseif action == "SelectWeapon" then
  if data.WeaponId==id then return true end
		if not WeaponData.Data[id] then return false, { key = "invalid" } end
		local equipped = Skins.Data[data.EquippedSkin]
		if equipped and equipped.weapon and equipped.weapon ~= id then PlayerData.equipSkin(player, "Default") end
		PlayerData.setWeapon(player, id)
  PlayerData.saveSoon(player)
		refreshWeapon(player)
		return true

	elseif action == "SelectInfusion" then
  if data.InfusionId==id then return true end
		if not Infusions.Data[id] then return false, { key = "invalid" } end
		PlayerData.setInfusion(player, id)
  PlayerData.saveSoon(player)
		-- Se aplica al momento si no está encendida ahora mismo (en partida, también entre rondas)
		local char = player.Character
		if char and not char:GetAttribute("InfusionActive") then
			char:SetAttribute("InfusionId", id)
		end
		return true, { key = "infusion." .. id }

	elseif action == "Equip" then
  if data.EquippedSkin==id then return true end
		local skin = Skins.Data[id]
		if not skin or skin.comingSoon then return false, { key = "soon" } end
		if skin.weapon and skin.weapon ~= data.WeaponId then return false, { key = "otherWeapon" } end
		if not PlayerData.equipSkin(player, id) then return false, { key = "notOwned" } end
  PlayerData.saveSoon(player)
		refreshWeapon(player)
		return true

	elseif action == "Buy" then
		local skin = Skins.Data[id]
		if not skin then return false, { key = "invalid" } end
		if skin.comingSoon then return false, { key = "soon" } end
		-- Decisión del usuario (10/11/2026): las skins de la ruleta solo salen de la ruleta y las cajas.
		if skin.roulette then return false, { key = "rouletteOnly" } end
		if PlayerData.owns(player, "OwnedSkins", id) then return false, { key = "alreadyOwned" } end

		if skin.currency == "Coins" then
			local ok,key=PlayerData.buyCosmetic(player,id,skin.price,false)
   return ok, { key = key }
		elseif skin.currency == "Robux" then
			if not skin.productId or skin.productId <= N.Zero then
				return false, { key = "soon" }
			end
			MarketplaceService:PromptProductPurchase(player, skin.productId)
			return true, { key = "robloxConfirm" }
		end
		return false, { key = "invalid" }
	end

	return false, { key = "invalid" }
end

ShopRF.OnServerInvoke = function(player, action, id)
 local now=os.clock()
 if shopBusy[player] or (shopAt[player] and now-shopAt[player]<E.ShopInterval) then return false, {key="cx.shop.wait"} end
 shopAt[player]=now
 if type(action)~="string" or type(id)~="string" then return false,{key="invalid"} end
 shopBusy[player]=true
 local success,ok,message=pcall(shopAction,player,action,id)
 shopBusy[player]=nil
 if not player.Parent then shopAt[player]=nil end
 if not success then warn("[Shop] Request failed for UserId "..player.UserId) return false,{key="error"} end
 return ok,message
end

-- Compras con Robux: se concede la skin y se confirma el recibo
local productToSkin = {}
for id, skin in Skins.Data do
	if skin.productId and skin.productId > N.Zero then
		productToSkin[skin.productId] = id
	end
end

local productToAura = {}
for id, aura in Auras.Data do
 if aura.productId > E.Zero then
  if productToSkin[aura.productId] then warn("[Shop] Duplicate productId: " .. tostring(aura.productId))
  else productToAura[aura.productId] = id end
 end
end

MarketplaceService.ProcessReceipt = function(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local auraId = productToAura[info.ProductId]
 local skinId = auraId or productToSkin[info.ProductId]
	if not skinId or not PlayerData.get(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if PlayerData.processReceipt(player, tostring(info.PurchaseId), skinId, auraId ~= nil) then
  return Enum.ProductPurchaseDecision.PurchaseGranted
 end
 return Enum.ProductPurchaseDecision.NotProcessedYet
end
