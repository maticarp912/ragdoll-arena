-- ModuleScript: ReplicatedStorage/BalancePill
-- 11/11/2026: saldo de almas y monedas (tienda y recompensas), igual en las dos pantallas.
--   [ícono grande] 15.000      (+)
--                  ALMAS
-- El número va grande y con separador de miles; la palabra chica abajo; el «+» (comprar monedas) es un
-- círculo dentro de la misma píldora. Sin el «◈» de antes: el ícono es el arte del juego (alma / moneda).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))

local C = UiTheme.Colors
local PILL = { Icon = 30, Plus = 30, Pad = 8 }

local BalancePill = {}

-- 15000 → «15.000» (ES/PT) o «15,000» (EN)
function BalancePill.format(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local sep = L.language and L.language() == "EN" and "," or "."
	local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
	if out:sub(1, 1) == sep then out = out:sub(2) end
	return out
end

function BalancePill.create(parent, position, size, kind, amount, getGems)
	local gems = kind == "Gems"
	local tint = gems and C.Guard or C.Coins
	local pill = UiTheme.panel({ parent = parent, position = position, size = size, anchor = Vector2.new(1, 0.5),
		bg = C.BgAbyss, borderColor = tint, borderTrans = 0.35, radius = UiTheme.Radius.Pill, frameArt = false, gradient = false })
	pill.Name = gems and "GemsPill" or "SoulsPill"

	local icon = UiAssets.icon(pill, gems and "gem" or "soul", PILL.Icon, nil)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, PILL.Pad, 0.5, 0)

	local right = gems and (PILL.Plus + PILL.Pad * 2) or PILL.Pad * 2
	local left = PILL.Pad + PILL.Icon + 6
	local amountLbl = UiTheme.label({ parent = pill, position = UDim2.new(0, left, 0, 3), size = UDim2.new(1, -(left + right), 0.6, -3),
		text = BalancePill.format(amount), font = "Number", scaled = true, textSize = UiTheme.TextSizes.LG, minTextSize = 10,
		color = C.TextPrimary, alignX = Enum.TextXAlignment.Left })
	amountLbl.Name = "Amount"
	UiTheme.label({ parent = pill, position = UDim2.new(0, left, 0.58, -2), size = UDim2.new(1, -(left + right), 0.42, -2),
		text = UiTheme.upper(L.t(gems and "mz.gemsWord" or "ui.soulsWord")), font = "Bold", scaled = true,
		textSize = UiTheme.TextSizes.XS, minTextSize = 8, color = tint, alignX = Enum.TextXAlignment.Left })

	if gems then
		UiTheme.button({ name = "GetGems", parent = pill, anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, -PILL.Pad, 0.5, 0), size = UDim2.fromOffset(PILL.Plus, PILL.Plus), text = "+",
			font = "Number", textSize = UiTheme.TextSizes.LG, variant = "robux", onClick = getGems, -- verde: se compra con Robux
			radius = UiTheme.Radius.Pill })
	end
	return pill
end

return BalancePill
