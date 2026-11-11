-- ModuleScript: ReplicatedStorage/MonetizationConfig
-- 11/11/2026: catálogo de compras con Robux. Solo datos: la lógica está en ServerScriptService/MonetizationManager.
-- Cada ID se crea en Creator Hub (Developer Product o Game Pass) y se pega acá. Con id = 0 la oferta
-- no se muestra ni se puede comprar. El precio real lo pone Roblox; `robux` es solo el valor sugerido.
--
-- Reglas que no se rompen (PvP justo y normas de Roblox):
--   · Nada de lo que se vende da ventaja en combate: solo cosméticos, comodidad y velocidad de progreso.
--   · paidRandom = true: el producto compra azar (monedas que abren cofres, tiros, suerte). Si PolicyService dice
--     ArePaidRandomItemsRestricted para ese jugador (o la consulta falla), NO se le ofrece ni se le vende.
--   · La suerte de cofres cambia las probabilidades: la interfaz tiene que mostrar el antes y el después con números.

local M = {}

-- Pases (pago único, para siempre)
M.Passes = {
	SkipOpening = { id = 2078852439, robux = 200, order = 1, nameKey = "mz.pass.SkipOpening", descKey = "mz.pass.SkipOpening.desc" },
	VIP = {
		id = 2078456436, robux = 399, order = 2, nameKey = "mz.pass.VIP", descKey = "mz.pass.VIP.desc",
		-- Ventajas (las aplica cada servicio leyendo el atributo Pass_VIP del jugador):
		perks = { soulsBonus = 0.2, extraDailySpin = 1, fallbackSouls = 150, role = "VIP", aura = "VipCrown",
			-- 11/11/2026: regalo de bienvenida, una sola vez por cuenta, al tener el pase
			welcome = { spins = 10, boxes = { StormLesser = 5, StormGreater = 5, StormRoyal = 5, Eclipse = 5 },
				restrictedSouls = 15000 } }, -- si Roblox restringe el azar pago: almas en vez de tiros y cofres
	},
}

-- Productos (consumibles, se pueden comprar muchas veces). kind decide qué se entrega.
M.Products = {
	-- 11/11 (revisión de Fable 5.2): rinden más cuanto más grandes y el último alcanza para el cofre 6
	Souls1 = { id = 3730436241, robux = 49, kind = "Gems", amount = 400, order = 1, paidRandom = true },
	Souls2 = { id = 3730436394, robux = 99, kind = "Gems", amount = 850, order = 2, paidRandom = true },
	Souls3 = { id = 3730436511, robux = 249, kind = "Gems", amount = 2200, order = 3, paidRandom = true, badge = "popular" },
	Souls4 = { id = 3730436603, robux = 499, kind = "Gems", amount = 4600, order = 4, paidRandom = true },
	Souls5 = { id = 3730436685, robux = 999, kind = "Gems", amount = 10000, order = 5, paidRandom = true, badge = "best" },
	Spins3 = { id = 3730436787, robux = 49, kind = "Spins", amount = 3, order = 6, paidRandom = true },
	-- Suerte de cofres: multiplica el peso de Épica y Legendaria (Rewards.Luck lo aplica) durante `seconds`.
	-- Disponible con ID válido, política habilitada y espacio de duración.
	Luck30 = { id = 3730436846, robux = 79, kind = "Luck", multiplier = 2, seconds = 1800, order = 7, paidRandom = true, enabled = true, maxSeconds = 7200 },
}

-- Auras y skins que se venden con Robux: llevan su `productId` en Auras.lua / Skins.lua (ya existe el campo).
-- MonetizationManager las registra solas al arrancar.

-- Ventajas que se pueden activar sin Robux para probar en Studio (workspace atributo StudioGrantPasses = true)
M.StudioGrantAttribute = "StudioGrantPasses"

-- Reintentos para consultar Roblox (propiedad de pases y políticas)
M.Retry = { Attempts = 3, Delays = { 1, 2 }, RecheckSeconds = 30, PurchaseConfirm = { 2, 4, 8, 15, 30 } }
M.PriceCacheSeconds = 60
M.ReceiptProfileWait = 25
M.PromptCooldown = 1 -- s entre pedidos de compra del mismo jugador

return M
