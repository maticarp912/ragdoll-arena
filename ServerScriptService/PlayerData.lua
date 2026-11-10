-- ModuleScript: ServerScriptService/PlayerData
-- Monedas, skins compradas, skin equipada y arma elegida. Se guarda en DataStore.
-- (Fase E: armas/infusiones desbloqueadas, infusión equipada por arma, XP y maestría.)
-- En Studio: Game Settings > Security > "Enable Studio Access to API Services".
-- Si el DataStore falla, el juego sigue funcionando (sin guardar).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerData = {}
local HttpService = game:GetService("HttpService")
local E = require(game:GetService("ReplicatedStorage"):WaitForChild("Economy"))
local P = require(game:GetService("ReplicatedStorage"):WaitForChild("Progression"))
local R = require(game:GetService("ReplicatedStorage"):WaitForChild("Rewards"))
local tokens, loading = {}, {}
local lost, leaseUntil = {}, {}
local finalizing = {}
local finalResults = setmetatable({}, { __mode = "k" })
local releaseHooks = {}
function PlayerData.beforeRelease(callback) table.insert(releaseHooks, callback) end
local shutdownDeadline
local writable, saving, closing = {}, {}, {}
local function copy(value)
 if type(value) ~= "table" then return value end
 local result = {} for k, v in value do result[k] = copy(v) end return result
end
local function touchLayout(payload)
 if type(payload) ~= "table" then return nil end
 local cfg, result, count = E.TouchLayout, {}, 0
 for id, row in payload do
  count += 1
  if count > cfg.MaxButtons or type(id) ~= "string" or not cfg.Actions[id] or type(row) ~= "table" then return nil end
  local fields = 0
  for key in row do
   fields += 1
   if fields > 3 or (key ~= "x" and key ~= "y" and key ~= "scale") then return nil end
  end
  for _, key in { "x", "y", "scale" } do
   local n = row[key]
   if type(n) ~= "number" or n ~= n or math.abs(n) == math.huge then return nil end
  end
  if row.x < cfg.MinX or row.x > cfg.MaxX or row.y < cfg.MinY or row.y > cfg.MaxY or row.scale < cfg.MinScale or row.scale > cfg.MaxScale then return nil end
  result[id] = { x = row.x, y = row.y, scale = row.scale }
 end
 return result
end

-- GetDataStore lanza error si el lugar no está publicado: lo capturamos para que el juego
-- funcione igual (sin guardar progreso).
local storeOk, storeOrErr = pcall(function()
	return DataStoreService:GetDataStore(RunService:IsStudio() and E.Stores.Studio or E.Stores.Live)
end)
local store = storeOk and storeOrErr or nil
if not store then
	warn("[PlayerData] DataStore no disponible (¿lugar sin publicar?). El progreso NO se guardará.")
end
local cache = {}

local function defaults()
	return {
		Schema = E.Schema, Level = 1, XP = 0, PlaySeconds = 0, GrantedRole = "",
        OwnedWeapons = {}, Titles = {}, Boxes = { Relic = 0 }, Boosts = { XP = 1, Coins = 1, XPSeconds = 0, CoinsSeconds = 0 },
        Coins = 0,
        Stats = { Wins = 0, Kills = 0, Knockdowns = 0, Matches = 0, Coins = 0 }, Daily = {}, FirstWinDay = -1,
        OwnedAuras = {}, EquippedAura = "", Receipts = {}, Options = {},
		OwnedSkins = { Default = true },
		EquippedSkin = "Default",
		WeaponId = "Sword",
		InfusionId = "Fire",
		Language = nil,
		Keybinds = nil, -- nil = controles de fábrica (InputMap)
	}
end

-- Copia los datos a leaderstats y atributos del jugador (los lee la UI)
local function refresh(player: Player)
	local data = PlayerData.get(player)
	if not data then return end

	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	local coins = ls:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = ls
	end
	coins.Value = data.Coins

	local owned = {}
	local skinSource = player:GetAttribute("AllCosmetics") and require(game:GetService("ReplicatedStorage").Skins).Data or data.OwnedSkins
	for id in skinSource do
		table.insert(owned, id)
	end
	table.sort(owned)
	player:SetAttribute("OwnedSkins", table.concat(owned, ","))
	player:SetAttribute("EquippedSkin", data.EquippedSkin)
	player:SetAttribute("WeaponId", data.WeaponId)
	player:SetAttribute("InfusionId", data.InfusionId)
	player:SetAttribute("Language", data.Language)
 player:SetAttribute("TouchLayoutJson", HttpService:JSONEncode(data.TouchLayout))
 for _, stat in { "Wins", "Kills", "Knockdowns", "Matches" } do player:SetAttribute("Stat" .. stat, data.Stats[stat] or E.Zero) end
 local auras = {} for id, owned in (player:GetAttribute("AllCosmetics") and require(game:GetService("ReplicatedStorage").Auras).Data or data.OwnedAuras) do if owned then table.insert(auras, id) end end
 table.sort(auras) player:SetAttribute("OwnedAuras", table.concat(auras, ","))
 player:SetAttribute("EquippedAura", data.EquippedAura)
 for key, spec in E.Options do player:SetAttribute(spec.attr, data.Options[key] or spec.default) end
end

function PlayerData.load(player: Player)
 if cache[player] or loading[player] or not player.Parent then return end
 loading[player] = true
 local session = game.JobId .. HttpService:GenerateGUID(false)
 tokens[player] = session
 local data = defaults()
 local ok, saved = false, nil
 -- Claude (etapa 8): reintentos antes de expulsar. Un fallo pasajero del DataStore o el bloqueo
 -- de un servidor que acaba de cerrar ya no echan al jugador al primer intento.
 if store then
  for attempt = E.One, E.LoadAttempts do
   if not player.Parent then break end
   ok, saved = pcall(function()
    return store:UpdateAsync("u_" .. player.UserId, function(old)
     old = type(old) == "table" and old or defaults()
     if type(old.Schema) == "number" and old.Schema > E.Schema then return nil end
     local lock = old.Session
     if type(lock) == "table" and lock.id ~= session and (lock.expires or E.Zero) > os.time() then return nil end
     local nextData = copy(old)
     nextData.Session = { id = session, expires = os.time() + E.SessionTTL }
     return nextData
    end)
   end)
   if ok and type(saved) == "table" then break end
   if attempt < E.LoadAttempts and player.Parent then task.wait(E.LoadRetryDelay * attempt) end
  end
 end
 -- A disconnected load must not publish a profile or leave its newly acquired lease.
 if not player.Parent then
  if ok and type(saved)=="table" and saved.Session and saved.Session.id==session then
   local released=false
   for attempt=E.One,E.FinalSaveAttempts do
    local success=pcall(function()
     store:UpdateAsync("u_"..player.UserId,function(old)
      if type(old)~="table" or type(old.Session)~="table" or old.Session.id~=session then return nil end
      old.Session=nil return old
     end)
    end)
    if success then released=true break end
    if attempt<E.FinalSaveAttempts then task.wait(E.FinalSaveDelay*attempt) end
   end
   if not released then warn("[PlayerData] Cancelled load lease release failed: "..player.UserId) end
  end
  tokens[player], loading[player] = nil, nil
  return
 end
 loading[player] = nil
 writable[player] = ok and type(saved) == "table" and saved.Session and saved.Session.id == session
 if writable[player] then
  for key, value in saved do if data[key] == nil and key ~= "Session" then data[key] = copy(value) end end
  for key in data do if type(saved[key]) == type(data[key]) then data[key] = copy(saved[key]) end end
  data.Keybinds = type(saved.Keybinds) == "table" and saved.Keybinds or nil
  if saved.Language == "ES" or saved.Language == "EN" or saved.Language == "PT-BR" then data.Language = saved.Language end
  data.Coins = math.max(E.Zero, math.floor(data.Coins))
  data.OwnedSkins.Default = true
  data.Schema = E.Schema
  local function finite(n, fallback, min, max)
   if type(n) ~= "number" or n ~= n or math.abs(n) == math.huge then return fallback end
   return math.clamp(n, min, max)
  end
  data.Level = math.floor(finite(data.Level, 1, 1, P.MaxLevel))
  data.XP = finite(data.XP, 0, 0, P.MaxGrant)
  data.PlaySeconds = finite(data.PlaySeconds, 0, 0, E.MaxPlaySeconds)
  if type(data.Boxes) ~= "table" then data.Boxes = {} end
  if type(data.Boosts) ~= "table" then data.Boosts = {} end
  data.Boxes.Relic = math.floor(finite(data.Boxes.Relic, 0, 0, P.MaxGrant))
  for _, kind in { "XP", "Coins" } do
   data.Boosts[kind] = finite(data.Boosts[kind], 1, 1, P.MaxMultiplier)
   data.Boosts[kind .. "Seconds"] = finite(data.Boosts[kind .. "Seconds"], 0, 0, P.MaxBoostSeconds)
  end
 elseif not RunService:IsStudio() then
  local locales = require(game:GetService("ReplicatedStorage"):WaitForChild("LocaleCodex"))
  local lang = string.lower(player.LocaleId)
  local key = string.match(lang, "^es") and "ES" or (string.match(lang, "^pt") and "PT-BR" or "EN")
  player:Kick(locales[key]["cx.profile.unavailable"]) return
 else
  warn("[PlayerData] Studio profile is temporary; persistent purchases are disabled.")
 end
 R.reconcile(data)
 data.TouchLayout = touchLayout(data.TouchLayout) or {}
 leaseUntil[player] = writable[player] and saved.Session.expires or nil
 cache[player] = data player:SetAttribute("ProfileState", writable[player] and "Ready" or "Temporary") refresh(player)
end

local function persist(player, data, release)
 if not store or not writable[player] then return false end
 local rejected = false
 local ok, result = pcall(function()
  return store:UpdateAsync("u_" .. player.UserId, function(old)
   if type(old) ~= "table" or type(old.Session) ~= "table" or old.Session.id ~= tokens[player] then rejected = true return nil end
   local nextData = copy(data)
   if release then nextData.Session = nil
   else nextData.Session = { id = tokens[player], expires = os.time() + E.SessionTTL } end
   return nextData
  end)
 end)
 if ok and rejected then
  lost[player] = true writable[player] = nil
  player:SetAttribute("ProfileState", "Lost")
  task.defer(function() if player.Parent then player:Kick(require(game:GetService("ReplicatedStorage").LocaleCodex).EN["cx.profile.lost"]) end end)
 end
 if ok and result and result.Session then leaseUntil[player] = result.Session.expires end
 return ok and result ~= nil
end

function PlayerData.save(player: Player, release)
 local function expired() return shutdownDeadline and os.clock()>=shutdownDeadline end
 if not release and closing[player] then return false end
 if release then
  if finalResults[player]~=nil then return finalResults[player] end
  if finalizing[player] then
   while finalizing[player] and not expired() do task.wait(E.RetryDelay) end
   return finalResults[player]==true
  end
  -- Also run on BindToClose; finish abandoned matches before the final snapshot.
  for _, hook in releaseHooks do hook(player) end
  finalizing[player]=true closing[player]=true
 end
 while saving[player] and not expired() do task.wait(E.RetryDelay) end
 if not release and closing[player] then return false end
 local ok=false
 if not saving[player] and cache[player] and not expired() then
  saving[player]=true
  local snapshot=copy(cache[player])
  local attempts=release and E.FinalSaveAttempts or E.One
  for attempt=E.One,attempts do
   if expired() then break end
   ok=persist(player,snapshot,release)
   if ok then break end
   if attempt<attempts then
    local delay=E.FinalSaveDelay*attempt
    if shutdownDeadline then delay=math.min(delay,math.max(E.Zero,shutdownDeadline-os.clock())) end
    task.wait(delay)
   end
  end
  saving[player]=nil
 end
 if release then
  if not ok and cache[player] then warn("[PlayerData] Final save failed for UserId "..player.UserId) end
  finalResults[player]=ok finalizing[player]=nil
  if ok then writable[player]=nil end
 end
 return ok
end

-- Guardado diferido para cambios del cliente (opciones, idioma, auras): varias peticiones seguidas
-- se juntan en un solo guardado, así un cliente no puede gastar el presupuesto de DataStore del servidor.
local pendingSave = {}
function PlayerData.saveSoon(player: Player)
 if pendingSave[player] then return end
 pendingSave[player] = true
 task.delay(E.SaveDebounce, function()
  pendingSave[player] = nil
  if cache[player] and not closing[player] then PlayerData.save(player) end
 end)
end

-- Receipt grants are staged outside the live profile. Failed writes cannot erase concurrent rewards.
function PlayerData.processReceipt(player, purchaseId, itemId, aura)
 while saving[player] do task.wait(E.RetryDelay) end
 local data = PlayerData.get(player)
 if not data or closing[player] or not writable[player] then return false end
 if table.find(data.Receipts, purchaseId) then return true end
 saving[player] = true
 local pending = copy(data)
 local field = aura and "OwnedAuras" or "OwnedSkins"
 pending[field][itemId] = true
 table.insert(pending.Receipts, purchaseId)
 while #pending.Receipts > E.ReceiptLimit do table.remove(pending.Receipts, E.One) end
 local ok = persist(player, pending, false)
 if ok then
  data[field][itemId] = true
  data.Receipts = pending.Receipts
  refresh(player)
 end
 saving[player] = nil
 return ok
end

function PlayerData.equipAura(player, id)
 local data = PlayerData.get(player)
 if not data or (id~="" and not PlayerData.owns(player, "OwnedAuras", id)) then return false end
 data.EquippedAura=id refresh(player) return true
end
-- Earned-soul purchases apply price and ownership together, without yielding.
function PlayerData.buyCosmetic(player, id, price, aura)
 local data = PlayerData.get(player)
 if not data or closing[player] then return false, "loading" end
 if saving[player] then return false, "cx.shop.wait" end
 if player:GetAttribute("InMatch") then return false, "locked" end
 local field=aura and "OwnedAuras" or "OwnedSkins"
 if data[field][id] then return false, "alreadyOwned" end
 if data.Coins<price then return false, "noCoins" end
 -- Earned currency uses the same atomic, non-yielding profile path as rewards.
 data.Coins -= price data[field][id] = true refresh(player) PlayerData.saveSoon(player)
 return true, "acquired"
end

function PlayerData.getOptions(player)
 local data = PlayerData.get(player) if not data then return nil end
 local result = {} for key, spec in E.Options do result[key] = data.Options[key] or spec.default end return result
end
function PlayerData.setOptions(player, payload)
 local data = PlayerData.get(player) if not data or type(payload) ~= "table" then return nil end
 local options = PlayerData.getOptions(player)
 for key, value in payload do
  local spec = E.Options[key]
  if not spec or type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return nil end
  options[key] = math.clamp(value, spec.min, spec.max)
 end
 data.Options = options refresh(player) return copy(options)
end
function PlayerData.resetTestPurchases(player)
 local data = PlayerData.get(player) if not data then return false end
 data.OwnedSkins = { Default = true } data.EquippedSkin = "Default"
 data.OwnedAuras = {} data.EquippedAura = ""
 refresh(player) return true
end

function PlayerData.owns(player, field, id)
 local data = PlayerData.get(player)
 return data ~= nil and (player:GetAttribute("AllCosmetics") == true or data[field][id] == true)
end
function PlayerData.refresh(player) refresh(player) end
function PlayerData.setTouchLayout(player, payload)
 local data = PlayerData.get(player) local layout = touchLayout(payload)
 if not data or not layout then return nil end
 data.TouchLayout = layout refresh(player) PlayerData.saveSoon(player) return copy(layout)
end
function PlayerData.getTouchLayout(player)
 local data = PlayerData.get(player) return data and copy(data.TouchLayout) or nil
end
function PlayerData.canMutate(player) return not closing[player] and not saving[player] and PlayerData.get(player) ~= nil end
function PlayerData.isPersistent(player) return not lost[player] and writable[player] == true end
function PlayerData.get(player: Player)
 if leaseUntil[player] and os.time() >= leaseUntil[player] and not lost[player] then
  lost[player] = true writable[player] = nil player:SetAttribute("ProfileState", "Lost")
  task.defer(function() if player.Parent then player:Kick(require(game:GetService("ReplicatedStorage").LocaleCodex).EN["cx.profile.lost"]) end end)
 end
 return not lost[player] and cache[player] or nil
end

function PlayerData.addCoins(player: Player, amount: number)
	local data = PlayerData.get(player)
	if not data or type(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge then return end
	data.Coins = math.max(0, data.Coins + math.floor(amount))
	refresh(player)
end

function PlayerData.grantSkin(player: Player, skinId: string)
	local data = PlayerData.get(player)
	if not data then return end
	data.OwnedSkins[skinId] = true
	refresh(player)
end

function PlayerData.equipSkin(player: Player, skinId: string)
	local data = PlayerData.get(player)
	if not data or not PlayerData.owns(player, "OwnedSkins", skinId) then return false end
	data.EquippedSkin = skinId
	refresh(player)
	return true
end

function PlayerData.setLanguage(player, language)
 if language ~= "ES" and language ~= "EN" and language ~= "PT-BR" then return false end
 local data = PlayerData.get(player) if not data then return false end
 data.Language = language refresh(player) return true
end

function PlayerData.setKeybinds(player: Player, binds)
	local data = PlayerData.get(player)
	if not data then return end
	data.Keybinds = binds
end

function PlayerData.setInfusion(player: Player, infusionId: string)
	local data = PlayerData.get(player)
	if not data then return end
	data.InfusionId = infusionId
	refresh(player)
end

function PlayerData.setWeapon(player: Player, weaponId: string)
	local data = PlayerData.get(player)
	if not data then return end
	data.WeaponId = weaponId
	refresh(player)
end

Players.PlayerRemoving:Connect(function(player)
	closing[player] = true
	PlayerData.save(player, true)
	cache[player], writable[player] = nil, nil
 if not loading[player] then tokens[player]=nil end
 lost[player]=nil leaseUntil[player]=nil
 closing[player]=nil
end)

game:BindToClose(function()
	shutdownDeadline=os.clock()+E.CloseTimeout
 local remaining = E.Zero
 for player in cache do
  remaining += E.One
  task.spawn(function() closing[player] = true PlayerData.save(player, true) remaining -= E.One end)
 end
 while remaining > E.Zero and os.clock()<shutdownDeadline do task.wait(math.min(E.RetryDelay,math.max(E.Zero,shutdownDeadline-os.clock()))) end
end)

task.spawn(function()
	while true do
		task.wait(E.Autosave)
		for _, player in Players:GetPlayers() do
			task.spawn(PlayerData.save, player)
		end
	end
end)

return PlayerData
