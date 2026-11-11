-- ModuleScript: ServerScriptService/MonetizationManager
-- 11/11/2026: módulo central de pagos. Único dueño de MarketplaceService.ProcessReceipt (Roblox permite uno solo).
--   · Developer Products (consumibles): recibo idempotente con PlayerData.processReceiptWith (se guarda ANTES de
--     devolver PurchaseGranted; si no se pudo guardar, NotProcessedYet y Roblox reintenta).
--   · Game Passes (permanentes): propiedad consultada con reintentos y caché por jugador; se publica en el
--     atributo Pass_<clave>. Nunca se cree al cliente; "no sé" (fallo de red) no se guarda como "no lo tiene".
--   · Políticas: los productos paidRandom no se ofrecen ni se venden si PolicyService los restringe (o falla).
-- API para otros servicios:
--   Manager.registerKind(kind, function(player, product, data) -> mutar data, devolver true end)
--   Manager.ownsPass(player, key) -> true | false | nil (nil = todavía no se sabe)
--   Manager.onPassGranted(function(player, key) end)
--   Manager.paidRandomAllowed(player) -> boolean
--   Manager.catalog(player) -> lista para la interfaz

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Manager = {}

local kinds = {}            -- [kind] = grant(player, product, data)
local limits = {}           -- [kind] = canBuy(player, product, data) -> boolean (no cobrar si ya está en el tope)
local byProductId = {}      -- [productId] = { key, product } | false (id repetido: no se entrega nada)
local passOwned = {}        -- [player] = { [key] = true | false }
local policy = {}           -- [player] = { paidRandom = boolean }
local passListeners = {}
local promptAt = {}

local function retry(fn)
	for attempt = 1, Config.Retry.Attempts do
		local ok, result = pcall(fn)
		if ok then return true, result end
		local wait = Config.Retry.Delays[attempt]
		if wait then task.wait(wait) end
	end
	return false, nil
end

----------------------------------------------------------------------
-- Registro de productos
----------------------------------------------------------------------
local function register(key, product)
	local id = product.id
	if type(id) ~= "number" or id <= 0 then return end
	local existing = byProductId[id]
	if existing == nil then
		byProductId[id] = { key = key, product = product }
	elseif existing then
		byProductId[id] = false
		warn("[Monetization] productId repetido: " .. tostring(id) .. " (no se entrega para evitar errores)")
	end
end

function Manager.registerKind(kind, grant, canBuy)
	assert(type(kind) == "string" and type(grant) == "function", "registerKind(kind, grant, canBuy?)")
	kinds[kind] = grant
	limits[kind] = canBuy
end

-- Productos sueltos que vienen de otros catálogos (auras y skins con productId)
function Manager.registerProduct(key, product)
	register(key, product)
end

for key, product in Config.Products do register(key, product) end

----------------------------------------------------------------------
-- Políticas (azar pago)
----------------------------------------------------------------------
local function loadPolicy(player)
	local ok, info = retry(function() return PolicyService:GetPolicyInfoForPlayerAsync(player) end)
	-- Si falla, se cierra: se trata como restringido (fail closed)
	local restricted = not ok or type(info) ~= "table" or info.ArePaidRandomItemsRestricted ~= false
	policy[player] = { paidRandom = not restricted, known = ok }
	if player.Parent then player:SetAttribute("PaidRandomAllowed", not restricted) end
	-- Si la consulta falló, se reintenta (mientras tanto sigue cerrado)
	if not ok then
		task.delay(Config.Retry.RecheckSeconds, function() if player.Parent then loadPolicy(player) end end)
	end
end

function Manager.paidRandomAllowed(player)
	local p = policy[player]
	return p ~= nil and p.paidRandom == true
end

----------------------------------------------------------------------
-- Pases
----------------------------------------------------------------------
local function studioGrant()
	return RunService:IsStudio() and workspace:GetAttribute(Config.StudioGrantAttribute) == true
end

local function setPass(player, key, owned)
	passOwned[player] = passOwned[player] or {}
	local before = passOwned[player][key]
	passOwned[player][key] = owned
	if player.Parent then player:SetAttribute("Pass_" .. key, owned) end
	if owned and not before then
		for _, fn in passListeners do task.spawn(fn, player, key) end
	end
end

local function checkPass(player, key)
	local pass = Config.Passes[key]
	if not pass then return end
	if studioGrant() then setPass(player, key, true) return end
	if pass.id <= 0 then setPass(player, key, false) return end
	local ok, owns = retry(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id) end)
	if ok then
		setPass(player, key, owns == true)
	else
		-- No se sabe: no se guarda false. Se vuelve a intentar más tarde.
		task.delay(Config.Retry.RecheckSeconds, function()
			if player.Parent and passOwned[player] and passOwned[player][key] == nil then checkPass(player, key) end
		end)
	end
end

-- Solo Studio (MonetizationService → StudioTest): aplica la entrega sin recibo para probar.
function Manager.grantForTest(player, product, data)
	if not RunService:IsStudio() then return false end
	local grant = kinds[product.kind]
	if not grant or not Manager.underLimit(player, product) then return false end
	local ok, result = pcall(grant, player, product, data)
	return ok and result == true
end

function Manager.ownsPass(player, key)
	local t = passOwned[player]
	if not t then return nil end
	return t[key]
end

function Manager.onPassGranted(fn) table.insert(passListeners, fn) end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then return end
	for key, pass in Config.Passes do
		if pass.id == passId then
			-- Siempre se confirma con Roblox: esta señal la puede falsificar un cliente con trampas.
			-- La compra puede tardar en verse, así que se reintenta con esperas cada vez más largas.
			for _, wait in Config.Retry.PurchaseConfirm do
				local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId) end)
				if ok and owns then setPass(player, key, true) return end
				task.wait(wait)
				if not player.Parent then return end
			end
			return
		end
	end
end)

----------------------------------------------------------------------
-- Recibos de Developer Products
----------------------------------------------------------------------
MarketplaceService.ProcessReceipt = function(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local entry = byProductId[info.ProductId]
	if not player or not entry or not PlayerData.get(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local grant = kinds[entry.product.kind]
	if not grant then
		warn("[Monetization] sin manejador para el tipo " .. tostring(entry.product.kind))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok = PlayerData.processReceiptWith(player, tostring(info.PurchaseId), function(data)
		assert(grant(player, entry.product, data) == true, "grant failed")
	end)
	if ok then
		-- lihfolk-ignore: receipt-grant-before-save (processReceiptWith guarda la copia con el PurchaseId antes de tocar el perfil en memoria)
		player:SetAttribute("LastPurchase", entry.key)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

----------------------------------------------------------------------
-- Catálogo y pedidos de compra (el cliente pide, el servidor decide)
----------------------------------------------------------------------
local priceCache = {} -- [clave] = { price = n | false, at = os.clock() }; los fallos se reintentan al minuto
local function realPrice(id, infoType, fallback)
	if id <= 0 then return fallback end
	local cacheKey = tostring(infoType) .. id
	local entry = priceCache[cacheKey]
	if entry == nil or (entry.price == false and os.clock() - entry.at > 60) then
		local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, infoType) end)
		entry = { price = ok and type(info) == "table" and info.PriceInRobux or false, at = os.clock() }
		priceCache[cacheKey] = entry
	end
	return entry.price or fallback
end

local function enabled(product) return product.id > 0 and product.enabled ~= false end
function Manager.underLimit(player, product)
	local canBuy = limits[product.kind]
	local data = PlayerData.get(player)
	if not data then return false end
	if not canBuy then return true end
	local ok, result = pcall(canBuy, player, product, data)
	return ok and result == true
end
local underLimit = Manager.underLimit

function Manager.catalog(player)
	local list = {}
	local allowed = Manager.paidRandomAllowed(player)
	local policyKnown = policy[player] ~= nil and policy[player].known == true
	for key, pass in Config.Passes do
		table.insert(list, {
			key = key, type = "Pass", order = pass.order, nameKey = pass.nameKey, descKey = pass.descKey,
			price = realPrice(pass.id, Enum.InfoType.GamePass, pass.robux), owned = Manager.ownsPass(player, key) == true,
			available = pass.id > 0 or studioGrant(),
		})
	end
	for key, product in Config.Products do
		table.insert(list, {
			key = key, type = "Product", kind = product.kind, order = product.order, amount = product.amount,
			multiplier = product.multiplier, seconds = product.seconds, badge = product.badge,
			price = realPrice(product.id, Enum.InfoType.Product, product.robux),
			available = enabled(product) and (not product.paidRandom or allowed) and underLimit(player, product),
			restricted = product.paidRandom == true and not allowed and policyKnown,
			atLimit = enabled(product) and not underLimit(player, product),
		})
	end
	table.sort(list, function(a, b)
		if a.type ~= b.type then return a.type == "Pass" end
		return (a.order or 99) < (b.order or 99)
	end)
	return list
end

function Manager.prompt(player, key)
	local now = os.clock()
	if promptAt[player] and now - promptAt[player] < Config.PromptCooldown then return false, "wait" end
	promptAt[player] = now
	local pass = Config.Passes[key]
	if pass then
		if pass.id <= 0 then return false, "unavailable" end
		if Manager.ownsPass(player, key) then return false, "owned" end
		MarketplaceService:PromptGamePassPurchase(player, pass.id)
		return true
	end
	local product = Config.Products[key]
	if not product or not enabled(product) then return false, "unavailable" end
	if product.paidRandom and not Manager.paidRandomAllowed(player) then return false, "restricted" end
	if not underLimit(player, product) then return false, "limit" end -- no cobrar algo que no se puede entregar
	MarketplaceService:PromptProductPurchase(player, product.id)
	return true
end

----------------------------------------------------------------------
-- Ciclo del jugador
----------------------------------------------------------------------
function Manager.track(player)
	task.spawn(loadPolicy, player)
	for key in Config.Passes do task.spawn(checkPass, player, key) end
end

Players.PlayerRemoving:Connect(function(player)
	passOwned[player] = nil
	policy[player] = nil
	promptAt[player] = nil
end)

return Manager
