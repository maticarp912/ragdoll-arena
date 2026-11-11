-- Client-side presentation of the server's monetization catalogue.
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local L = require(RS:WaitForChild("Localization"))
local UiTheme = require(RS:WaitForChild("UiTheme"))
local Rewards = require(RS:WaitForChild("Rewards"))
local Config = require(RS:WaitForChild("MonetizationConfig"))
local C = UiTheme.Colors
local Vault = {}

local function request(action, key)
 local folder = RS:FindFirstChild("Remotes")
 local remote = folder and folder:FindFirstChild("Monetization")
 if not remote then return false, "unavailable" end
 local ok, accepted, value = pcall(function() return remote:InvokeServer(action, key) end)
 if not ok then return false, "unavailable" end
 return accepted == true, value
end

function Vault.catalog(key)
 local ok, entries = request("Catalog", key)
 if not ok or type(entries) ~= "table" then return nil end
 -- Roblox can quote different prices for different clients.
 local count = 0
 local done = Instance.new("BindableEvent")
 for _, item in entries do
  if item.available and not item.owned and item.id > 0 then
   count += 1
   task.defer(function()
    local infoType = item.type == "Pass" and Enum.InfoType.GamePass or Enum.InfoType.Product
    local fetched, info = pcall(function() return MarketplaceService:GetProductInfoAsync(item.id, infoType) end)
    item.available = fetched and type(info) == "table" and info.IsForSale == true and type(info.PriceInRobux) == "number"
    item.price = item.available and info.PriceInRobux or nil
    count -= 1 done:Fire()
   end)
  end
 end
 while count > 0 do done.Event:Wait() end
 done:Destroy()
 return entries
end


function Vault.chestOdds()
 local folder = RS:FindFirstChild("Remotes")
 local rewards = folder and folder:FindFirstChild("Rewards")
 if not rewards then return nil end
 local ok, accepted, state = pcall(function() return rewards:InvokeServer("GetState") end)
 if ok and not accepted then
  task.wait(Rewards.Interval + 0.05)
  ok, accepted, state = pcall(function() return rewards:InvokeServer("GetState") end)
 end
 if not ok or not accepted then return nil end
 local lines = { L.t("mz.highRarityOdds") }
 for tier, id in Rewards.BoxOrder do
  local before, after = 0, 0
  local box = state.boxes and state.boxes[id]
  if not box then return nil end
  for _, row in box.probabilities do
   if Rewards.RarityRank[row.rarity] >= Rewards.GoodRank then
    before += row.baseProbability
    after += row.previewProbability
   end
  end
  table.insert(lines, L.t("mz.level", { level = tier }) .. ("  %.4f%% → %.4f%%"):format(before * 100, after * 100))
 end
 return table.concat(lines, "\n")
end

function Vault.prompt(key)
 return request("Prompt", key)
end

function Vault.text(item)
 local params = { amount = item.amount, multiplier = item.multiplier, minutes = item.seconds and item.seconds / 60 }
 if item.type == "Pass" then return L.t(item.nameKey), L.t(item.descKey, { amount = Config.Passes.VIP.perks.fallbackSouls }) end
 if item.kind == "Aura" then return L.t("cx.aura." .. item.item), L.t("cx.aura." .. item.item .. ".desc") end
 if item.kind == "Skin" then return L.t("skin." .. item.item), L.t("skinDesc." .. item.item) end
 return L.t("mz.product." .. item.kind, params), L.t("mz.product." .. item.kind .. ".desc", params)
end

-- 11/11/2026: que se note que es Robux: botón verde (como en Roblox) y el símbolo oficial (U+E002) delante del precio
function Vault.priceButton(props, item)
 props.icon = nil
 props.text = item.owned and L.t("mz.owned") or (utf8.char(0xE002) .. " " .. tostring(item.price))
 props.textColor = C.TextPrimary
 props.variant = item.owned and "primary" or "robux"
 props.font = "Number"
 props.disabled = props.disabled or item.owned == true
 return UiTheme.button(props)
end

function Vault.souls(player)
 local stats = player:FindFirstChild("leaderstats")
 local coins = stats and stats:FindFirstChild("Coins")
 return coins and coins.Value or 0
end

function Vault.open(player, section)
 local event = player:FindFirstChild("OpenVault")
 if event and event:IsA("BindableEvent") then event:Fire(section) end
end

function Vault.shortfall(amount)
 return L.t("mz.missingSouls", { amount = amount })
end

return Vault
