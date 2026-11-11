-- ModuleScript: ReplicatedStorage/MonetizationConfig
-- 11/11/2026: catálogo de compras con Robux. Solo datos: la lógica está en ServerScriptService/MonetizationManager.
-- Cada ID se crea en Creator Hub (Developer Product o Game Pass) y se pega acá. Con id = 0 la oferta
-- no se muestra ni se puede comprar. El precio real lo pone Roblox; `robux` es solo el valor sugerido.
--
-- Reglas que no se rompen (PvP justo y normas de Roblox):
--   · Nada de lo que se vende da ventaja en combate: solo cosméticos, comodidad y velocidad de progreso.
--   · paidRandom = true: el producto compra azar (almas que abren cofres, tiros, suerte). Si PolicyService dice
--     ArePaidRandomItemsRestricted para ese jugador (o la consulta falla), NO se le ofrece ni se le vende.
--   · La suerte de cofres cambia las probabilidades: la interfaz tiene que mostrar el antes y el después con números.

local M = {}

-- Pases (pago único, para siempre)
M.Passes = {
	SkipOpening = { id = 0, robux = 200, order = 1, nameKey = "mz.pass.SkipOpening", descKey = "mz.pass.SkipOpening.desc" },
	VIP = {
		id = 0, robux = 399, order = 2, nameKey = "mz.pass.VIP", descKey = "mz.pass.VIP.desc",
		-- Ventajas (las aplica cada servicio leyendo el atributo Pass_VIP del jugador):
		perks = { soulsBonus = 0.2, extraDailySpin = 1, role = "VIP", aura = "VipCrown" },
	},
}

-- Productos (consumibles, se pueden comprar muchas veces). kind decide qué se entrega.
M.Products = {
	-- 11/11 (revisión de Fable 5.2): rinden más cuanto más grandes y el último alcanza para el cofre 6
	Souls1 = { id = 0, robux = 49, kind = "Souls", amount = 600, order = 1, paidRandom = true },
	Souls2 = { id = 0, robux = 99, kind = "Souls", amount = 1400, order = 2, paidRandom = true },
	Souls3 = { id = 0, robux = 249, kind = "Souls", amount = 4000, order = 3, paidRandom = true, badge = "popular" },
	Souls4 = { id = 0, robux = 499, kind = "Souls", amount = 9000, order = 4, paidRandom = true },
	Souls5 = { id = 0, robux = 999, kind = "Souls", amount = 20000, order = 5, paidRandom = true, badge = "best" },
	Spins3 = { id = 0, robux = 49, kind = "Spins", amount = 3, order = 6, paidRandom = true },
	-- Suerte de cofres: multiplica el peso de Épica y Legendaria (Rewards.Luck lo aplica) durante `seconds`.
	-- enabled = false hasta que Rewards.Luck esté hecho (Codex): no se vende algo que todavía no hace nada.
	Luck30 = { id = 0, robux = 79, kind = "Luck", multiplier = 2, seconds = 1800, order = 7, paidRandom = true, enabled = false, maxSeconds = 7200 },
}

-- Auras y skins que se venden con Robux: llevan su `productId` en Auras.lua / Skins.lua (ya existe el campo).
-- MonetizationManager las registra solas al arrancar.

-- Ventajas que se pueden activar sin Robux para probar en Studio (workspace atributo StudioGrantPasses = true)
M.StudioGrantAttribute = "StudioGrantPasses"

-- Reintentos para consultar Roblox (propiedad de pases y políticas)
M.Retry = { Attempts = 3, Delays = { 1, 2 }, RecheckSeconds = 30, PurchaseConfirm = { 2, 4, 8, 15, 30 } }
M.PromptCooldown = 1 -- s entre pedidos de compra del mismo jugador

return M
