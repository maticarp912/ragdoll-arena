-- ModuleScript: ReplicatedStorage/SkinDesigns
-- Geometría procedural 3D de alta definición (Estándar 0.2 D6/D15: nivel de acabado de Notas/Referencias/espada-concepto.png).
-- Cada skin combina:
--   - Biseles de filo plateados/metálicos en cuña (Wedge + Foil/Metal) diferenciados del núcleo oscuro (Slate/Metal).
--   - Acanaladura (Fuller) y vena/relámpago central luminoso (Neon) con ramificaciones diagonales.
--   - Recazo romboidal con gemas engarzadas, guarda en media luna / guardamonte y pomo astado con gema.
--   - Presupuesto estricto: <= 110 BaseParts, <= 1 PointLight, <= 1 ParticleEmitter y punta exacta en TipZ (BladeTip).

local SkinDesigns = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local ang = CFrame.Angles
local cf = CFrame.new
local rad = math.rad

-- ============================================================================
-- UTILIDADES COMUNES DE ACABADO (ESTÁNDAR ESPADA DE REFERENCIA)
-- ============================================================================

-- Vena de relámpago quebrada a lo largo de la hoja (z0 -> z1) con ramificaciones
local function addLightningVein(b, v, z0, z1, segments, ampY, thickX, widthY, role, forks)
	local dz = (z1 - z0) / segments
	local prevY = 0
	for i = 1, segments do
		local za = z0 + (i - 1) * dz
		local zb = z0 + i * dz
		local nextY = (i == segments) and 0 or ((i % 2 == 1 and 1 or -1) * ampY * (0.65 + 0.35 * ((i % 3) / 2)))
		b:seg("LightningVein", v(prevY, za), v(nextY, zb), thickX, widthY, role, 0.015)
		if forks and (i % 2 == 1) and i < segments then
			local dir = (i % 4 == 1) and 1 or -1
			b:seg("VeinFork", v(nextY, zb), v(nextY + dir * (ampY * 1.9), zb + dz * 0.55), thickX * 0.92, widthY * 0.65, role, 0.01)
		end
		prevY = nextY
	end
end

-- Dientes dorsales ganchudos (estilo sierra de espada-concepto.png: base oscura + filo de plata)
local function addDorsalHooks(b, v, zList, ySpine, dirY, hookW, hookL, thickX, baseRole, edgeRole)
	for _, z in zList do
		local pBase = v(ySpine, z)
		local pMid = v(ySpine + dirY * (hookW * 0.62), z - hookL * 0.45)
		local pTip = v(ySpine + dirY * hookW, z - hookL)
		b:point("DorsalHookBase", pBase, pMid, hookW * 0.68, thickX * 0.88, baseRole)
		b:point("DorsalHookEdge", pMid, pTip, hookW * 0.48, thickX * 0.72, edgeRole or "Edge")
	end
end

-- Recazo romboidal con 2 gemas engarzadas en bisel (fiel a espada-concepto.png)
local function addDiamondBolsterGems(b, v, z0, z1, bolsterW, thickX, frameRole, darkRole, gemRole)
	local zMid = (z0 + z1) * 0.5
	local len = z1 - z0
	b:add("BolsterCore", Vector3.new(thickX, bolsterW, len), cf(0, 0, zMid), darkRole or "Dark")
	b:add("BolsterFrameL", Vector3.new(thickX + 0.02, bolsterW * 0.46, len * 0.76), cf(0, bolsterW * 0.24, zMid) * ang(rad(14), 0, 0), frameRole or "Edge", "Wedge")
	b:add("BolsterFrameR", Vector3.new(thickX + 0.02, bolsterW * 0.46, len * 0.76), cf(0, -bolsterW * 0.24, zMid) * ang(rad(-14), 0, rad(180)), frameRole or "Edge", "Wedge")
	for idx, gz in { z0 + len * 0.28, z0 + len * 0.74 } do
		local gScale = idx == 1 and 1.0 or 0.82
		b:add("GemBezel", Vector3.new(thickX + 0.035, 0.13 * gScale, 0.13 * gScale), cf(0, 0, gz) * ang(rad(45), 0, 0), frameRole or "Trim")
		b:add("BolsterGem", Vector3.new(thickX + 0.052, 0.085 * gScale, 0.085 * gScale), cf(0, 0, gz) * ang(rad(45), 0, 0), gemRole or "Gem")
	end
end

-- Pomo de tres garras con gema central engarzada (fiel a espada-concepto.png)
local function addClawedGemPommel(b, v, zPommel, radius, thickX, clawLen, metalRole, edgeRole, gemRole)
	b:add("PommelCore", Vector3.new(thickX, radius * 1.65, radius * 1.45), cf(0, 0, zPommel) * ang(rad(45), 0, 0), metalRole or "Accent")
	b:add("PommelBezel", Vector3.new(thickX + 0.025, radius * 0.92, radius * 0.92), cf(0, 0, zPommel) * ang(rad(45), 0, 0), edgeRole or "Edge")
	b:add("PommelGem", Vector3.new(thickX + 0.045, radius * 0.56, radius * 0.56), cf(0, 0, zPommel) * ang(rad(45), 0, 0), gemRole or "Gem")
	-- Espiga central y dos garras laterales curvas
	b:point("PommelCenterSpike", v(0, zPommel - radius * 0.4), v(0, zPommel - radius * 0.4 - clawLen), radius * 0.75, thickX * 0.78, edgeRole or "Edge")
	for _, s in { 1, -1 } do
		b:point("PommelSideClaw", v(s * radius * 0.55, zPommel - radius * 0.12), v(s * radius * 1.18, zPommel - radius * 0.12 - clawLen * 0.78), radius * 0.58, thickX * 0.68, metalRole or "Accent")
	end
end

-- ============================================================================
-- 1. CONSTRUCTOR DE DAGAS (5 SKINS: Relic01 - Relic05)
-- ============================================================================
local function dagger(cfg)
	return {
		palette = cfg.palette,
		build = function(b, v)
			b.handle.Size = Vector3.new(0.18, 0.22, 0.85)
			b.basePos = v(0, 0.55)

			-- Empuñadura contorneada con anillos en chevrón
			b:add("GripCore", Vector3.new(0.19, 0.24, 0.78), cf(0, 0, 0), "Grip")
			b:wrap(-0.32, 0.32, 4, 0.24, "Trim", 18)
			b:add("GripCollarB", Vector3.new(0.22, 0.28, 0.08), cf(0, 0, -0.39), "Accent")
			b:add("GripCollarF", Vector3.new(0.24, 0.32, 0.10), cf(0, 0, 0.41), "Accent")

			-- Pomo astado con gema engarzada
			addClawedGemPommel(b, v, -0.52, 0.16, 0.20, 0.28, "Accent", "Edge", "Gem")

			-- Guarda en media luna con guardamonte y recazo con 2 gemas
			local gSpan = cfg.guardSpan or 0.48
			local gSweep = cfg.guardSweep or 0.18
			for _, s in { 1, -1 } do
				b:seg("GuardWing", v(0, 0.50), v(s * gSpan * 0.65, 0.50 + gSweep * 0.5), 0.18, 0.14, "Accent", 0.04)
				b:point("GuardClaw", v(s * gSpan * 0.60, 0.50 + gSweep * 0.45), v(s * gSpan, 0.50 + gSweep), 0.13, 0.12, "Edge")
			end
			-- Arco guardamonte asimétrico (-Y) estilo referencia
			b:arc("KnuckleBow", v(-0.10, 0.05), v(0, 1), v(-1, 0), 0.34, rad(-15), rad(175), 3, 0.10, 0.08, "Accent")

			-- Recazo romboidal con 2 gemas
			addDiamondBolsterGems(b, v, 0.48, 0.78, 0.30, 0.16, "Edge", "Dark", "Gem")

			-- Hoja multicapa: núcleo oscuro + biseles de filo plateados/metálicos + punta en TipZ ~ 2.88
			local pts = cfg.pts
			local widths = cfg.widths
			local tipLen = cfg.tip or 0.44
			local coreWidths = {}
			local edgePts = {}
			local edgeWidths = {}
			for i = 1, #pts do
				coreWidths[i] = widths[i] * 0.68
				edgePts[i] = { pts[i][1] + widths[i] * 0.16, pts[i][2] }
				edgeWidths[i] = widths[i] * 0.46
			end
			-- Bisel de filo exterior pulido ("Edge") y núcleo contrastado ("Blade" / "Dark")
			b:strip("EdgeBevel", pts, widths, 0.062, "Edge", tipLen)
			b:strip("BladeCore", pts, coreWidths, 0.088, "Blade", tipLen * 0.72)

			-- Acanaladura oscura y vena de relámpago luminosa hasta la punta
			local fPts = { pts[1], pts[math.ceil(#pts / 2)], pts[#pts - 1] }
			b:strip("Fuller", fPts, { 0.08, 0.06, 0.04 }, 0.098, "Dark", 0)
			addLightningVein(b, v, 0.78, 2.48, 5, 0.032, 0.106, 0.028, "Glow", true)

			-- Variantes específicas de cada daga
			if cfg.hooks then
				for i = 1, cfg.hooks do
					local z = 0.92 + i * 0.32
					b:point("BackHookBase", v(-0.10, z), v(-0.24, z - 0.12), 0.10, 0.08, "Blade")
					b:point("BackHookEdge", v(-0.18, z - 0.06), v(-0.30, z - 0.20), 0.08, 0.06, "Edge")
				end
			end
			if cfg.thorns then
				b:curve("ThornVine", { { 0.0, 0.70 }, { 0.15, 1.15 }, { -0.13, 1.60 }, { 0.11, 2.05 }, { -0.05, 2.45 } }, 0.07, 0.04, "Accent")
				for _, th in { { 0.15, 1.12, 0.30, 0.98 }, { -0.13, 1.56, -0.28, 1.42 }, { 0.11, 2.00, 0.25, 1.86 }, { -0.07, 2.32, -0.20, 2.20 } } do
					b:point("VineThorn", v(th[1], th[2]), v(th[3], th[4]), 0.08, 0.065, "Edge")
				end
			end
			if cfg.crescent then
				b:arc("CrescentMoon", v(0.04, 1.45), v(0, 1), v(1, 0), 0.36, rad(-125), rad(55), 5, 0.09, 0.08, "Accent")
				b:ball("MoonOrb", v(0.08, 1.45), 0.14, "Gem")
			end
			if cfg.filigree then
				for _, s in { 1, -1 } do
					b:arc("FiligreeCurl", v(s * 0.20, 0.78), v(0, 1), v(s, 0), 0.18, rad(-60), rad(150), 4, 0.08, 0.06, "Trim")
				end
			end
			if cfg.claws then
				for _, s in { 1, -1 } do
					b:point("SideClaw", v(s * 0.16, 1.02), v(s * 0.40, 1.68), 0.11, 0.065, "Edge")
					b:point("InnerClaw", v(s * 0.12, 0.84), v(s * 0.30, 1.32), 0.09, 0.075, "Accent")
				end
			end

			b:light(v(0, 1.6), cfg.light, 5, 0.75)
			if cfg.emit then b:emit(cfg.emit, 0.75, 2.65, cfg.light) end
		end,
	}
end

-- Relic01: Colmillos Carmesí (Dagas)
SkinDesigns.Fangs = dagger({
	palette = {
		Blade = { rgb(20, 16, 20), M.Slate },
		Edge = { rgb(225, 228, 236), M.Foil },
		Accent = { rgb(48, 20, 24), M.Metal },
		Trim = { rgb(175, 180, 192), M.Metal },
		Dark = { rgb(12, 10, 14), M.Slate },
		Grip = { rgb(26, 16, 18), M.Leather },
		Gem = { rgb(245, 28, 38), M.Neon },
		Glow = { rgb(255, 38, 44), M.Neon },
	},
	pts = { { 0, 0.56 }, { 0.05, 0.96 }, { 0.12, 1.42 }, { 0.10, 1.88 }, { -0.02, 2.24 }, { 0.04, 2.48 } },
	widths = { 0.36, 0.40, 0.36, 0.30, 0.24, 0.16 },
	tip = 0.40,
	guardSpan = 0.52,
	guardSweep = 0.22,
	hooks = 4,
	light = rgb(240, 40, 36),
	emit = "Embers",
})

-- Relic02: Espinas Vivas (Dagas)
SkinDesigns.LivingThorns = dagger({
	palette = {
		Blade = { rgb(22, 20, 26), M.Slate },
		Edge = { rgb(232, 228, 220), M.Foil },
		Accent = { rgb(198, 192, 182), M.Metal },
		Trim = { rgb(140, 32, 38), M.Metal },
		Dark = { rgb(14, 12, 16), M.Slate },
		Grip = { rgb(30, 22, 24), M.Leather },
		Gem = { rgb(235, 34, 42), M.Neon },
		Glow = { rgb(245, 48, 56), M.Neon },
	},
	pts = { { 0, 0.56 }, { -0.03, 1.00 }, { 0.05, 1.48 }, { -0.03, 1.94 }, { 0.02, 2.44 } },
	widths = { 0.32, 0.30, 0.27, 0.23, 0.16 },
	tip = 0.44,
	guardSpan = 0.46,
	guardSweep = -0.14,
	thorns = true,
	 hooks = 3,
	light = rgb(230, 45, 45),
	emit = "Embers",
})

-- Relic03: Lunas del Vacío (Dagas)
SkinDesigns.VoidMoons = dagger({
	palette = {
		Blade = { rgb(22, 18, 34), M.Slate },
		Edge = { rgb(216, 206, 248), M.Foil },
		Accent = { rgb(68, 52, 108), M.Metal },
		Trim = { rgb(168, 132, 245), M.Foil },
		Dark = { rgb(12, 10, 20), M.Slate },
		Grip = { rgb(22, 18, 32), M.Leather },
		Gem = { rgb(185, 130, 255), M.Neon },
		Glow = { rgb(172, 118, 255), M.Neon },
	},
	pts = { { 0, 0.56 }, { 0.07, 0.98 }, { 0.15, 1.44 }, { 0.11, 1.92 }, { 0.02, 2.42 } },
	widths = { 0.36, 0.38, 0.34, 0.26, 0.16 },
	tip = 0.46,
	guardSpan = 0.50,
	guardSweep = 0.24,
	crescent = true,
	hooks = 3,
	light = rgb(165, 115, 255),
	emit = "Wisps",
})

-- Relic04: Crecientes de Plata (Dagas)
SkinDesigns.SilverCrescent = dagger({
	palette = {
		Blade = { rgb(28, 30, 38), M.Slate },
		Edge = { rgb(240, 242, 250), M.Foil },
		Accent = { rgb(192, 198, 212), M.Metal },
		Trim = { rgb(232, 236, 245), M.Foil },
		Dark = { rgb(16, 18, 24), M.Slate },
		Grip = { rgb(24, 24, 30), M.Leather },
		Gem = { rgb(210, 232, 255), M.Neon },
		Glow = { rgb(195, 225, 255), M.Neon },
	},
	pts = { { 0, 0.56 }, { 0.04, 1.02 }, { 0.08, 1.52 }, { 0.05, 2.00 }, { 0.0, 2.44 } },
	widths = { 0.34, 0.34, 0.30, 0.24, 0.15 },
	tip = 0.44,
	guardSpan = 0.48,
	guardSweep = 0.16,
	filigree = true,
	hooks = 3,
	light = rgb(210, 225, 250),
})

-- Relic05: Garras del Eclipse (Dagas — Piloto Tanda 1 de Blender)
SkinDesigns.EclipseClaws = dagger({
	palette = {
		Blade = { rgb(20, 22, 28), M.Slate },
		Edge = { rgb(228, 232, 242), M.Foil },
		Accent = { rgb(64, 68, 78), M.Metal },
		Trim = { rgb(190, 196, 210), M.Foil },
		Dark = { rgb(12, 14, 18), M.Slate },
		Grip = { rgb(22, 22, 26), M.Leather },
		Gem = { rgb(235, 36, 52), M.Neon },
		Glow = { rgb(235, 42, 58), M.Neon },
	},
	pts = { { 0, 0.56 }, { 0.05, 1.00 }, { 0.11, 1.48 }, { 0.07, 1.96 }, { 0.0, 2.42 } },
	widths = { 0.38, 0.40, 0.34, 0.26, 0.16 },
	tip = 0.46,
	guardSpan = 0.54,
	guardSweep = 0.26,
	claws = true,
	hooks = 4,
	light = rgb(235, 48, 62),
	emit = "Embers",
})

-- ============================================================================
-- 2. GRAN PREMIO DE LA RULETA: FILO DEL ECLIPSE CARMESÍ (Notas/Referencias/espada-concepto.png)
-- ============================================================================
SkinDesigns.CrimsonEclipse = {
	palette = {
		Blade = { rgb(18, 18, 24), M.Slate },      -- Núcleo de obsidiana mate profunda
		Edge = { rgb(232, 236, 246), M.Foil },     -- Bisel de filo de plata espejo
		Accent = { rgb(52, 54, 64), M.Metal },     -- Acero oscuro de guarda y pomo
		Trim = { rgb(196, 202, 216), M.Foil },     -- Reborde plateado de la guarda y engastes
		Dark = { rgb(10, 10, 14), M.Slate },       -- Acanaladura interior negra
		Grip = { rgb(20, 18, 22), M.Leather },     -- Cuero negro estriado
		Gem = { rgb(245, 18, 34), M.Neon },        -- Rubíes carmesí engarzados
		Glow = { rgb(255, 28, 42), M.Neon },       -- Vena de relámpago carmesí
	},
	build = function(b, v)
		b.handle.Size = Vector3.new(0.22, 0.26, 1.15)
		b.basePos = v(0, 0.82)

		-- 1. Empuñadura negra estriada con 5 costillas en chevrón y virolas biseladas
		b:add("GripCore", Vector3.new(0.21, 0.28, 1.06), cf(0, 0, 0), "Grip")
		b:wrap(-0.44, 0.44, 5, 0.29, "Accent", 18)
		b:add("GripCollarB", Vector3.new(0.25, 0.34, 0.10), cf(0, 0, -0.54), "Trim")
		b:add("GripCollarF", Vector3.new(0.27, 0.38, 0.12), cf(0, 0, 0.56), "Trim")

		-- 2. Pomo de tres púas/garras con 1 rubí carmesí engarzado (fiel a espada-concepto.png)
		addClawedGemPommel(b, v, -0.72, 0.22, 0.24, 0.38, "Accent", "Edge", "Gem")

		-- 3. Guarda asimétrica en media luna + guardamonte envolvente (-Y) y gavilán afilado (+Y)
		b:add("GuardHeart", Vector3.new(0.30, 0.52, 0.28), cf(0, 0, 0.72), "Accent")
		-- Gavilán delantero superior (+Y) con bisel de plata
		b:seg("QuillonTop", v(0.18, 0.70), v(0.76, 1.02), 0.22, 0.18, "Accent", 0.04)
		b:point("QuillonTopBlade", v(0.68, 0.96), v(1.12, 1.24), 0.18, 0.14, "Edge")
		-- Guardamonte curvo en media luna (-Y) que baja protegiendo la empuñadura
		b:arc("CrescentKnuckleGuard", v(-0.14, 0.14), v(0, 1), v(-1, 0), 0.58, rad(-12), rad(168), 5, 0.18, 0.13, "Accent")
		b:arc("CrescentKnuckleTrim", v(-0.14, 0.14), v(0, 1), v(-1, 0), 0.62, rad(-8), rad(162), 4, 0.12, 0.07, "Edge")
		b:point("KnuckleTailSpike", v(-0.48, -0.34), v(-0.78, -0.58), 0.14, 0.12, "Edge")

		-- 4. Recazo romboidal con 2 rubíes carmesí engarzados en bisel de plata (z = 0.74 y z = 1.06)
		addDiamondBolsterGems(b, v, 0.66, 1.18, 0.48, 0.24, "Edge", "Blade", "Gem")

		-- 5. Hoja asimétrica de obsidiana con bisel de filo de plata espejo (+Y) y barrido hacia la punta (TipZ = 5.10)
		local edgePts = {
			{ 0.08, 0.86 },
			{ 0.12, 1.65 },
			{ 0.14, 2.55 },
			{ 0.13, 3.45 },
			{ 0.08, 4.22 },
		}
		local edgeWidths = { 0.34, 0.38, 0.38, 0.34, 0.26 }
		b:strip("SilverRazorBevel", edgePts, edgeWidths, 0.068, "Edge", 0.88)

		-- Núcleo de obsidiana negra escalonado sobre el bisel de plata
		local corePts = {
			{ -0.03, 0.90 },
			{ -0.02, 1.70 },
			{ -0.01, 2.60 },
			{ -0.01, 3.48 },
			{ 0.01, 4.18 },
		}
		local coreWidths = { 0.36, 0.38, 0.36, 0.30, 0.20 }
		b:strip("ObsidianCore", corePts, coreWidths, 0.105, "Blade", 0.68)

		-- Acanaladura profunda de obsidiana
		b:strip("ObsidianFuller", { { -0.02, 1.10 }, { -0.01, 2.55 }, { 0.0, 3.95 } }, { 0.14, 0.12, 0.07 }, 0.118, "Dark", 0)

		-- 6. Cinco dientes/colmillos dorsales ganchudos en el lomo (-Y) con punta de plata
		addDorsalHooks(b, v, { 1.52, 2.08, 2.64, 3.20, 3.76 }, -0.16, -1, 0.24, 0.28, 0.095, "Blade", "Edge")

		-- 7. Vena de relámpago carmesí quebrada desde las gemas del recazo hasta la punta (con ramificaciones)
		addLightningVein(b, v, 1.08, 4.68, 7, 0.048, 0.126, 0.036, "Glow", true)

		b:light(v(0, 2.75), rgb(245, 24, 40), 7, 1.0)
		b:emit("Embers", 1.05, 4.85, rgb(245, 28, 44))
	end,
}

-- ============================================================================
-- 3. CONSTRUCTOR DE ESPADAS (9 SKINS: Requiem + Relic06 - Relic13)
-- ============================================================================
local function sword(cfg)
	return {
		palette = cfg.palette,
		build = function(b, v)
			b.handle.Size = Vector3.new(0.22, 0.26, 1.15)
			b.basePos = v(0, 0.82)

			-- Empuñadura ergonómica con costillas metálicas
			b:add("GripCore", Vector3.new(0.21, 0.28, 1.06), cf(0, 0, 0), "Grip")
			b:wrap(-0.44, 0.44, 5, 0.28, "Trim", 16)
			b:add("GripCollarB", Vector3.new(0.24, 0.32, 0.10), cf(0, 0, -0.54), "Accent")
			b:add("GripCollarF", Vector3.new(0.26, 0.36, 0.12), cf(0, 0, 0.56), "Accent")

			-- Pomo astado con gema engarzada
			addClawedGemPommel(b, v, -0.72, 0.21, 0.23, 0.34, "Accent", "Edge", "Gem")

			-- Guarda esculpida con gavilanes en cuña y recazo con 2 gemas
			local gSpan = cfg.guardSpan or 0.88
			local gSweep = cfg.guardSweep or 0.24
			b:add("GuardCenter", Vector3.new(0.28, 0.52, 0.26), cf(0, 0, 0.72), "Accent")
			for _, s in { 1, -1 } do
				b:seg("GuardArm", v(0, 0.72), v(s * gSpan * 0.65, 0.72 + gSweep * 0.55), 0.20, 0.18, "Accent", 0.05)
				b:point("GuardQuillonTip", v(s * gSpan * 0.60, 0.72 + gSweep * 0.50), v(s * gSpan, 0.72 + gSweep), 0.16, 0.14, "Edge")
			end
			addDiamondBolsterGems(b, v, 0.66, 1.16, 0.46, 0.22, "Edge", "Dark", "Gem")

			-- Hoja multicapa (TipZ = 5.10): bisel de filo exterior ("Edge") + núcleo contrastado ("Blade")
			local w0 = cfg.w0 or 0.40
			local w1 = cfg.w1 or 0.34
			local tipLen = cfg.tipLen or 0.90
			local zTipStart = 5.10 - tipLen
			local zMid = (0.86 + zTipStart) * 0.5
			local bladeLen = zTipStart - 0.86

			-- Bisel de filo exterior en cuña y núcleo escalonado
			for _, s in { 1, -1 } do
				b:add("EdgeBevel", Vector3.new(0.064, w0 * 0.32, bladeLen), cf(0, s * (w0 * 0.34), zMid), "Edge", "Wedge")
			end
			b:add("BladeCore", Vector3.new(0.098, w0 * 0.66, bladeLen), cf(0, 0, zMid), "Blade")
			b:tip("RazorTipEdge", zTipStart, tipLen, w1, 0.068, "Edge")
			b:tip("RazorTipCore", zTipStart, tipLen * 0.76, w1 * 0.66, 0.098, "Blade")

			-- Acanaladura oscura y vena de relámpago luminosa hasta la punta
			b:add("Fuller", Vector3.new(0.112, w0 * 0.28, bladeLen * 0.82), cf(0, 0, 1.02 + bladeLen * 0.41), "Dark")
			addLightningVein(b, v, 1.12, 4.62, 6, 0.042, 0.122, 0.032, "Glow", true)

			-- Dientes dorsales en el lomo para silueta agresiva
			addDorsalHooks(b, v, { 1.65, 2.45, 3.25 }, -w0 * 0.42, -1, 0.16, 0.22, 0.085, "Blade", "Edge")

			-- Variantes icónicas por skin
			if cfg.variant == "horns" then
				for _, s in { 1, -1 } do
					b:curve("GothicHornF", { { s * 0.24, 0.72 }, { s * 0.64, 0.96 }, { s * 0.86, 1.38 }, { s * 0.68, 1.78 } }, 0.18, 0.06, "Accent")
					b:curve("GothicHornB", { { s * 0.22, 0.66 }, { s * 0.56, 0.44 }, { s * 0.70, 0.12 } }, 0.15, 0.05, "Edge")
				end
			elseif cfg.variant == "sun" then
				b:ring("SolarHalo", 0.90, 0.54, 0.08, 10, "Trim")
				for i = 0, 5 do
					local a = rad(-75 + i * 30)
					local r0, r1 = 0.54, 0.82
					b:point("SunRay", v(math.sin(a) * r0, 0.90 + math.cos(a) * r0 * 0.45), v(math.sin(a) * r1, 0.90 + math.cos(a) * r1 * 0.45), 0.10, 0.08, "Edge")
				end
			elseif cfg.variant == "bones" then
				for i = 1, 5 do
					local z = 1.30 + i * 0.52
					b:add("BoneVertebra", Vector3.new(0.15, w0 + 0.14, 0.14), cf(0, 0, z) * ang(rad(8), 0, 0), "Trim")
					for _, s in { 1, -1 } do
						b:point("RibBarb", v(s * (w0 * 0.46), z), v(s * (w0 * 0.46 + 0.22), z - 0.16), 0.10, 0.08, "Edge")
					end
				end
			elseif cfg.variant == "crown" then
				for _, s in { 1, -1 } do
					b:arc("CrownWing", v(0, 0.82), v(0, 1), v(s, 0), 0.58, rad(-20), rad(85), 4, 0.16, 0.10, "Trim")
				end
				for _, dy in { -0.26, 0, 0.26 } do
					b:point("CrownSpire", v(dy, 1.06), v(dy * 1.15, 1.56), 0.11, 0.09, "Edge")
				end
			elseif cfg.variant == "scales" then
				for i = 1, 6 do
					local z = 1.25 + i * 0.45
					b:point("DragonScale", v(0, z - 0.16), v(0, z + 0.22), w0 * 0.86, 0.125, "Trim")
				end
			elseif cfg.variant == "crystal" then
				for _, s in { 1, -1 } do
					b:point("CrystalWing", v(s * 0.18, 0.76), v(s * 0.68, 1.48), 0.20, 0.13, "Gem")
					b:point("CrystalSub", v(s * 0.22, 0.68), v(s * 0.54, 0.30), 0.15, 0.11, "Trim")
				end
			elseif cfg.variant == "split" then
				for _, s in { 1, -1 } do
					b:seg("VoidBladeProng", v(s * 0.16, 1.05), v(s * 0.13, 4.15), 0.09, 0.14, "Edge", 0.02)
				end
				for i = 1, 4 do
					b:ball("VoidNode", v(0, 1.20 + i * 0.65), 0.12, "Gem")
				end
			elseif cfg.variant == "serrated" then
				addDorsalHooks(b, v, { 1.40, 1.95, 2.50, 3.05, 3.60, 4.10 }, w0 * 0.44, 1, 0.18, 0.22, 0.085, "Blade", "Edge")
			elseif cfg.variant == "dragon" then
				for _, s in { 1, -1 } do
					b:curve("DragonWing", { { s * 0.16, 0.72 }, { s * 0.58, 0.94 }, { s * 0.94, 0.68 }, { s * 1.12, 0.28 } }, 0.20, 0.08, "Accent")
					b:point("DragonClaw", v(s * 0.58, 0.94), v(s * 0.82, 1.38), 0.14, 0.11, "Edge")
				end
			end

			b:light(v(0, 2.6), cfg.light, 6, 0.85)
			if cfg.emit then b:emit(cfg.emit, 1.0, 4.8, cfg.light) end
		end,
	}
end

-- Requiem: Réquiem Astado (Espada — Piloto Tanda 1 de Blender)
SkinDesigns.RequiemHorns = sword({
	palette = {
		Blade = { rgb(22, 22, 28), M.Slate },
		Edge = { rgb(218, 214, 232), M.Foil },
		Accent = { rgb(42, 40, 50), M.Metal },
		Trim = { rgb(156, 142, 198), M.Foil },
		Dark = { rgb(12, 12, 16), M.Slate },
		Grip = { rgb(20, 18, 24), M.Leather },
		Gem = { rgb(185, 138, 255), M.Neon },
		Glow = { rgb(172, 128, 245), M.Neon },
	},
	w0 = 0.42, w1 = 0.36, tipLen = 0.90,
	guardSpan = 0.92, guardSweep = 0.30,
	variant = "horns",
	light = rgb(170, 135, 235),
	emit = "Wisps",
})

-- Relic06: Juramento Solar
SkinDesigns.Solar = sword({
	palette = {
		Blade = { rgb(38, 36, 32), M.Slate },
		Edge = { rgb(245, 238, 215), M.Foil },
		Accent = { rgb(198, 162, 78), M.Metal },
		Trim = { rgb(245, 212, 118), M.Foil },
		Dark = { rgb(24, 20, 16), M.Slate },
		Grip = { rgb(48, 32, 22), M.Leather },
		Gem = { rgb(255, 215, 95), M.Neon },
		Glow = { rgb(255, 200, 80), M.Neon },
	},
	w0 = 0.38, w1 = 0.32, tipLen = 0.88,
	guardSpan = 0.88, guardSweep = 0.14,
	variant = "sun",
	light = rgb(255, 205, 95),
	emit = "Embers",
})

-- Relic07: Espina del Osario
SkinDesigns.Ossuary = sword({
	palette = {
		Blade = { rgb(32, 26, 24), M.Slate },
		Edge = { rgb(232, 222, 202), M.Foil },
		Accent = { rgb(124, 24, 28), M.Metal },
		Trim = { rgb(212, 198, 174), M.Limestone },
		Dark = { rgb(18, 14, 14), M.Slate },
		Grip = { rgb(42, 18, 20), M.Leather },
		Gem = { rgb(235, 38, 44), M.Neon },
		Glow = { rgb(225, 34, 40), M.Neon },
	},
	w0 = 0.40, w1 = 0.34, tipLen = 0.88,
	guardSpan = 0.90, guardSweep = -0.22,
	variant = "bones",
	light = rgb(220, 45, 45),
	emit = "Smoke",
})

-- Relic08: Corona del Alba
SkinDesigns.DawnCrown = sword({
	palette = {
		Blade = { rgb(34, 36, 44), M.Slate },
		Edge = { rgb(242, 244, 250), M.Foil },
		Accent = { rgb(218, 176, 74), M.Metal },
		Trim = { rgb(250, 220, 128), M.Foil },
		Dark = { rgb(20, 22, 28), M.Slate },
		Grip = { rgb(34, 30, 42), M.Leather },
		Gem = { rgb(255, 230, 140), M.Neon },
		Glow = { rgb(255, 222, 125), M.Neon },
	},
	w0 = 0.40, w1 = 0.34, tipLen = 0.90,
	guardSpan = 0.92, guardSweep = 0.28,
	variant = "crown",
	light = rgb(255, 220, 130),
})

-- Relic09: Filo del Dragón
SkinDesigns.DragonEdge = sword({
	palette = {
		Blade = { rgb(28, 26, 24), M.Slate },
		Edge = { rgb(216, 212, 198), M.Foil },
		Accent = { rgb(82, 80, 86), M.Metal },
		Trim = { rgb(178, 168, 148), M.Metal },
		Dark = { rgb(16, 15, 14), M.Slate },
		Grip = { rgb(38, 28, 22), M.Leather },
		Gem = { rgb(255, 132, 42), M.Neon },
		Glow = { rgb(255, 118, 36), M.Neon },
	},
	w0 = 0.44, w1 = 0.36, tipLen = 0.86,
	guardSpan = 0.94, guardSweep = -0.26,
	variant = "scales",
	light = rgb(245, 125, 45),
	emit = "Embers",
})

-- Relic10: Vigilia Violeta
SkinDesigns.Violet = sword({
	palette = {
		Blade = { rgb(24, 20, 34), M.Slate },
		Edge = { rgb(228, 214, 248), M.Foil },
		Accent = { rgb(118, 68, 178), M.Metal },
		Trim = { rgb(198, 142, 250), M.Foil },
		Dark = { rgb(14, 12, 22), M.Slate },
		Grip = { rgb(24, 18, 34), M.Leather },
		Gem = { rgb(215, 135, 255), M.Neon },
		Glow = { rgb(198, 115, 255), M.Neon },
	},
	w0 = 0.40, w1 = 0.34, tipLen = 0.90,
	guardSpan = 0.86, guardSweep = 0.32,
	variant = "crystal",
	light = rgb(190, 120, 255),
	emit = "Wisps",
})

-- Relic11: Aguja del Vacío
SkinDesigns.Void = sword({
	palette = {
		Blade = { rgb(16, 16, 24), M.Slate },
		Edge = { rgb(210, 205, 238), M.Foil },
		Accent = { rgb(68, 58, 96), M.Metal },
		Trim = { rgb(152, 132, 212), M.Foil },
		Dark = { rgb(10, 10, 16), M.Slate },
		Grip = { rgb(18, 16, 26), M.Leather },
		Gem = { rgb(168, 120, 255), M.Neon },
		Glow = { rgb(150, 105, 245), M.Neon },
	},
	w0 = 0.38, w1 = 0.30, tipLen = 0.94,
	guardSpan = 0.82, guardSweep = 0.34,
	variant = "split",
	light = rgb(155, 115, 245),
	emit = "Wisps",
})

-- Relic12: Diente del Exilio
SkinDesigns.ExileTooth = sword({
	palette = {
		Blade = { rgb(28, 30, 34), M.Slate },
		Edge = { rgb(212, 216, 224), M.Foil },
		Accent = { rgb(118, 108, 92), M.Metal },
		Trim = { rgb(172, 162, 144), M.Metal },
		Dark = { rgb(16, 18, 20), M.Slate },
		Grip = { rgb(44, 34, 26), M.Leather },
		Gem = { rgb(235, 155, 65), M.Neon },
		Glow = { rgb(225, 140, 55), M.Neon },
	},
	w0 = 0.44, w1 = 0.38, tipLen = 0.84,
	guardSpan = 0.86, guardSweep = -0.18,
	variant = "serrated",
	light = rgb(215, 150, 75),
})

-- Relic13: Reliquia Dracónica
SkinDesigns.DraconicRelic = sword({
	palette = {
		Blade = { rgb(18, 20, 28), M.Slate },
		Edge = { rgb(222, 232, 252), M.Foil },
		Accent = { rgb(48, 76, 198), M.Metal },
		Trim = { rgb(125, 168, 255), M.Foil },
		Dark = { rgb(10, 12, 18), M.Slate },
		Grip = { rgb(18, 22, 34), M.Leather },
		Gem = { rgb(110, 175, 255), M.Neon },
		Glow = { rgb(90, 160, 255), M.Neon },
	},
	w0 = 0.42, w1 = 0.36, tipLen = 0.90,
	guardSpan = 0.96, guardSweep = 0.26,
	variant = "dragon",
	light = rgb(100, 165, 255),
	emit = "Frost",
})

-- ============================================================================
-- 4. CONSTRUCTOR DE ESPADONES (6 SKINS + RULETA BloodMoonCleaver, TipZ = 7.60)
-- ============================================================================
local function greatsword(cfg)
	return {
		palette = cfg.palette,
		build = function(b, v)
			b.handle.Size = Vector3.new(0.28, 0.34, 2.30)
			b.basePos = v(0, 1.40)

			-- Mango a dos manos con 7 anillos en chevrón
			b:add("GripCore", Vector3.new(0.26, 0.34, 2.18), cf(0, 0, 0), "Grip")
			b:wrap(-0.96, 0.96, 7, 0.35, "Trim", 16)
			b:add("GripCollarB", Vector3.new(0.32, 0.42, 0.14), cf(0, 0, -1.10), "Accent")
			b:add("GripCollarF", Vector3.new(0.36, 0.48, 0.16), cf(0, 0, 1.12), "Accent")

			-- Pomo colosal de tres garras con gema engarzada
			addClawedGemPommel(b, v, -1.36, 0.30, 0.32, 0.46, "Accent", "Edge", "Gem")

			-- Guarda monumental (ancho ~2.80 studs) y recazo romboidal con 2 gemas
			local gSpan = cfg.guardSpan or 1.42
			local gSweep = cfg.guardSweep or 0.32
			b:add("GuardBlock", Vector3.new(0.44, 0.94, 0.38), cf(0, 0, 1.30), "Accent")
			for _, s in { 1, -1 } do
				b:seg("GreatGuardWing", v(0, 1.30), v(s * gSpan * 0.68, 1.30 + gSweep * 0.55), 0.32, 0.28, "Accent", 0.06)
				b:point("GreatGuardTalon", v(s * gSpan * 0.62, 1.30 + gSweep * 0.50), v(s * gSpan, 1.30 + gSweep), 0.26, 0.22, "Edge")
			end
			-- Arco guardamonte pesado (-Y)
			b:arc("GreatKnuckleBow", v(-0.22, 0.32), v(0, 1), v(-1, 0), 0.92, rad(-10), rad(165), 4, 0.20, 0.14, "Accent")
			addDiamondBolsterGems(b, v, 1.24, 2.02, 0.96, 0.34, "Edge", "Dark", "Gem")

			-- Losa colosal multicapa (ancho 1.48 - 1.58, TipZ = 7.60)
			local w0 = cfg.w0 or 1.52
			local w1 = cfg.w1 or 1.38
			local tipLen = cfg.tipLen or 1.15
			local zTipStart = 7.60 - tipLen
			local bladeLen = zTipStart - 1.45
			local zMid = (1.45 + zTipStart) * 0.5

			-- Bisel de filo exterior plateado/metálico ("Edge") y núcleo de obsidiana/acero ("Blade")
			for _, s in { 1, -1 } do
				b:add("GreatEdgeBevel", Vector3.new(0.14, w0 * 0.30, bladeLen), cf(0, s * (w0 * 0.35), zMid), "Edge", "Wedge")
			end
			b:add("GreatBladeCore", Vector3.new(0.24, w0 * 0.64, bladeLen), cf(0, 0, zMid), "Blade")
			b:tip("GreatTipEdge", zTipStart, tipLen, w1, 0.16, "Edge")
			b:tip("GreatTipCore", zTipStart, tipLen * 0.78, w1 * 0.64, 0.24, "Blade")

			-- Acanaladura profunda y vena de relámpago quebrada hasta la punta
			b:add("GreatFuller", Vector3.new(0.26, w0 * 0.28, bladeLen * 0.82), cf(0, 0, 1.65 + bladeLen * 0.41), "Dark")
			addLightningVein(b, v, 1.85, 6.95, 7, 0.085, 0.28, 0.055, "Glow", true)

			-- Sierra dorsal de colmillos ganchudos (5 dientes)
			local hookCount = cfg.dorsalHooks or 5
			local hookZs = {}
			for i = 1, hookCount do
				hookZs[i] = 2.15 + (i - 1) * 0.78
			end
			addDorsalHooks(b, v, hookZs, -w0 * 0.44, -1, 0.32, 0.38, 0.18, "Blade", "Edge")

			-- Variantes por skin
			if cfg.variant == "tomb" then
				for i = 1, 3 do
					local z = 2.40 + i * 1.10
					b:add("TombSeal", Vector3.new(0.29, w0 * 0.52, 0.32), cf(0, 0, z) * ang(rad(45), 0, 0), "Trim")
				end
			elseif cfg.variant == "jaws" then
				addDorsalHooks(b, v, { 2.35, 3.15, 3.95, 4.75, 5.55 }, w0 * 0.44, 1, 0.30, 0.36, 0.18, "Blade", "Edge")
			elseif cfg.variant == "mourning" then
				b:ring("MourningHalo", 1.55, 0.72, 0.12, 10, "Trim")
			elseif cfg.variant == "cross" then
				b:ring("SolarCrossHalo", 1.55, 0.78, 0.12, 10, "Trim")
				for _, s in { 1, -1 } do
					b:point("CrossSideFlange", v(s * (w0 * 0.48), 2.75), v(s * (w0 * 0.82), 3.15), 0.28, 0.20, "Edge")
				end
			elseif cfg.variant == "shroud" then
				for i = 1, 6 do
					local z = 2.15 + i * 0.68
					b:add("ShroudWrap", Vector3.new(0.28, w0 * 0.96, 0.16), cf(0, 0, z) * ang(rad((i % 2 == 0 and 1 or -1) * 10), 0, 0), "Trim")
				end
			elseif cfg.variant == "wings" then
				for _, s in { 1, -1 } do
					b:curve("AbyssWing", { { s * 0.30, 1.32 }, { s * 0.96, 1.68 }, { s * 1.48, 2.28 }, { s * 1.24, 2.95 } }, 0.30, 0.10, "Trim")
				end
			end

			b:light(v(0, 4.2), cfg.light, 8, 0.95)
			if cfg.emit then b:emit(cfg.emit, 1.6, 7.2, cfg.light) end
		end,
	}
end

-- Relic14: Tumba Esmeralda
SkinDesigns.EmeraldTomb = greatsword({
	palette = {
		Blade = { rgb(20, 26, 28), M.Slate },
		Edge = { rgb(210, 242, 224), M.Foil },
		Accent = { rgb(42, 58, 52), M.Metal },
		Trim = { rgb(72, 245, 138), M.Foil },
		Dark = { rgb(12, 16, 18), M.Slate },
		Grip = { rgb(18, 24, 22), M.Leather },
		Gem = { rgb(65, 255, 135), M.Neon },
		Glow = { rgb(60, 255, 128), M.Neon },
	},
	w0 = 1.54, w1 = 1.40, tipLen = 1.15,
	guardSpan = 1.44, guardSweep = 0.24,
	variant = "tomb",
	light = rgb(65, 255, 130),
	emit = "Wisps",
})

-- Relic15: Devorador
SkinDesigns.Devourer = greatsword({
	palette = {
		Blade = { rgb(24, 22, 24), M.Slate },
		Edge = { rgb(220, 222, 228), M.Foil },
		Accent = { rgb(58, 54, 58), M.Metal },
		Trim = { rgb(172, 174, 182), M.Metal },
		Dark = { rgb(14, 12, 14), M.Slate },
		Grip = { rgb(32, 20, 22), M.Leather },
		Gem = { rgb(235, 52, 42), M.Neon },
		Glow = { rgb(240, 60, 45), M.Neon },
	},
	w0 = 1.56, w1 = 1.42, tipLen = 1.15,
	guardSpan = 1.46, guardSweep = -0.28,
	variant = "jaws",
	light = rgb(235, 58, 45),
	emit = "Embers",
})

-- Relic16: Luto Real
SkinDesigns.RoyalMourning = greatsword({
	palette = {
		Blade = { rgb(20, 20, 26), M.Slate },
		Edge = { rgb(236, 234, 242), M.Foil },
		Accent = { rgb(48, 48, 56), M.Metal },
		Trim = { rgb(206, 202, 198), M.Foil },
		Dark = { rgb(12, 12, 16), M.Slate },
		Grip = { rgb(22, 20, 26), M.Leather },
		Gem = { rgb(225, 225, 245), M.Neon },
		Glow = { rgb(215, 218, 240), M.Neon },
	},
	w0 = 1.50, w1 = 1.36, tipLen = 1.15,
	guardSpan = 1.42, guardSweep = 0.22,
	variant = "mourning",
	light = rgb(215, 215, 235),
})

-- Relic17: Cruz del Ocaso
SkinDesigns.DuskCross = greatsword({
	palette = {
		Blade = { rgb(36, 28, 20), M.Slate },
		Edge = { rgb(248, 228, 172), M.Foil },
		Accent = { rgb(196, 152, 58), M.Metal },
		Trim = { rgb(245, 206, 108), M.Foil },
		Dark = { rgb(22, 16, 12), M.Slate },
		Grip = { rgb(46, 30, 20), M.Leather },
		Gem = { rgb(255, 212, 95), M.Neon },
		Glow = { rgb(255, 198, 82), M.Neon },
	},
	w0 = 1.54, w1 = 1.40, tipLen = 1.15,
	guardSpan = 1.48, guardSweep = 0.16,
	variant = "cross",
	light = rgb(255, 205, 95),
	emit = "Embers",
})

-- Relic18: Sudario
SkinDesigns.Shroud = greatsword({
	palette = {
		Blade = { rgb(22, 24, 30), M.Slate },
		Edge = { rgb(226, 222, 212), M.Foil },
		Accent = { rgb(62, 60, 56), M.Metal },
		Trim = { rgb(216, 210, 193), M.Fabric },
		Dark = { rgb(12, 14, 18), M.Slate },
		Grip = { rgb(34, 30, 26), M.Leather },
		Gem = { rgb(235, 220, 185), M.Neon },
		Glow = { rgb(225, 210, 175), M.Neon },
	},
	w0 = 1.52, w1 = 1.38, tipLen = 1.15,
	guardSpan = 1.38, guardSweep = -0.18,
	variant = "shroud",
	light = rgb(220, 205, 175),
	emit = "Smoke",
})

-- Relic19: Alas del Abismo (Espadón — Piloto Tanda 1 de Blender)
SkinDesigns.AbyssWings = greatsword({
	palette = {
		Blade = { rgb(16, 16, 22), M.Slate },
		Edge = { rgb(224, 216, 248), M.Foil },
		Accent = { rgb(52, 42, 86), M.Metal },
		Trim = { rgb(154, 122, 236), M.Foil },
		Dark = { rgb(10, 10, 14), M.Slate },
		Grip = { rgb(18, 16, 26), M.Leather },
		Gem = { rgb(175, 128, 255), M.Neon },
		Glow = { rgb(162, 112, 250), M.Neon },
	},
	w0 = 1.56, w1 = 1.42, tipLen = 1.15,
	guardSpan = 1.50, guardSweep = 0.38,
	variant = "wings",
	light = rgb(160, 115, 245),
	emit = "Wisps",
})

-- Ruleta D15: Mandoble de Sangre Lunar (Espadón compañero de la espada de referencia)
SkinDesigns.BloodMoonCleaver = greatsword({
	palette = {
		Blade = { rgb(16, 16, 22), M.Slate },
		Edge = { rgb(234, 238, 248), M.Foil },
		Accent = { rgb(48, 50, 60), M.Metal },
		Trim = { rgb(202, 208, 222), M.Foil },
		Dark = { rgb(10, 10, 14), M.Slate },
		Grip = { rgb(20, 16, 20), M.Leather },
		Gem = { rgb(245, 18, 36), M.Neon },
		Glow = { rgb(255, 26, 44), M.Neon },
	},
	w0 = 1.58, w1 = 1.44, tipLen = 1.18,
	guardSpan = 1.52, guardSweep = 0.36,
	dorsalHooks = 6,
	variant = "wings",
	light = rgb(245, 24, 42),
	emit = "Embers",
})

-- ============================================================================
-- 5. CONSTRUCTOR DE ESTOQUES (7 SKINS: Relic20 - Relic26, TipZ = 5.56)
-- ============================================================================
local function rapier(cfg)
	return {
		palette = cfg.palette,
		build = function(b, v)
			b.handle.Size = Vector3.new(0.18, 0.22, 1.05)
			b.basePos = v(0, 0.92)

			-- Empuñadura fina con costillas en chevrón
			b:add("GripCore", Vector3.new(0.18, 0.22, 0.98), cf(0, 0, 0), "Grip")
			b:wrap(-0.40, 0.40, 5, 0.23, "Trim", 18)
			b:add("GripCollarB", Vector3.new(0.22, 0.26, 0.08), cf(0, 0, -0.48), "Accent")
			b:add("GripCollarF", Vector3.new(0.24, 0.30, 0.10), cf(0, 0, 0.50), "Accent")

			-- Pomo de tres garras con gema
			addClawedGemPommel(b, v, -0.66, 0.18, 0.20, 0.32, "Accent", "Edge", "Gem")

			-- Cazoleta real con costillas en espiral, gavilanes afilados y guardamonte
			local cupR = cfg.cupR or 0.44
			b:add("CupBase", Vector3.new(0.24, cupR * 1.45, 0.18), cf(0, 0, 0.64), "Accent")
			for i = 0, 5 do
				local a = (i / 6) * math.pi * 2
				local py = math.sin(a) * cupR * 0.85
				local px = math.cos(a) * cupR * 0.65
				b:seg("BasketRib", Vector3.new(px * 0.35, py * 0.35, 0.54), Vector3.new(px, py, 0.94), 0.07, 0.09, i % 2 == 0 and "Edge" or "Trim", 0.02)
			end
			for _, s in { 1, -1 } do
				b:point("SweptQuillon", v(0, 0.62), v(s * 0.92, 0.62 + s * 0.12), 0.12, 0.10, "Edge")
			end
			b:arc("RapierKnuckleBow", v(0.12, 0.08), v(0, 1), v(1, 0), 0.52, rad(-12), rad(168), 4, 0.09, 0.08, "Trim")

			-- Recazo romboidal con 2 gemas engarzadas
			addDiamondBolsterGems(b, v, 0.68, 1.18, 0.28, 0.16, "Edge", "Dark", "Gem")

			-- Aguja de sección romboidal multicapa (TipZ = 5.56)
			local zTipStart = 4.78
			local tipLen = 0.78
			local bladeLen = zTipStart - 0.96
			local zMid = (0.96 + zTipStart) * 0.5

			for _, s in { 1, -1 } do
				b:add("NeedleEdgeBevel", Vector3.new(0.052, 0.075, bladeLen), cf(0, s * 0.052, zMid), "Edge", "Wedge")
			end
			b:add("NeedleCore", Vector3.new(0.082, 0.11, bladeLen), cf(0, 0, zMid), "Blade")
			b:tip("NeedleTipEdge", zTipStart, tipLen, 0.14, 0.058, "Edge")
			b:tip("NeedleTipCore", zTipStart, tipLen * 0.75, 0.09, 0.082, "Blade")

			-- Espolones cerca del recazo y vena de relámpago fina a lo largo del estoque
			addDorsalHooks(b, v, { 1.38, 1.78, 2.18 }, -0.07, -1, 0.14, 0.18, 0.065, "Blade", "Edge")
			addLightningVein(b, v, 1.18, 5.05, 6, 0.024, 0.096, 0.022, "Glow", false)

			b:light(v(0, 2.8), cfg.light, 6, 0.80)
			if cfg.emit then b:emit(cfg.emit, 1.1, 5.3, cfg.light) end
		end,
	}
end

-- Relic20: Duelo Dorado
SkinDesigns.Duel = rapier({
	palette = {
		Blade = { rgb(32, 30, 28), M.Slate },
		Edge = { rgb(245, 242, 232), M.Foil },
		Accent = { rgb(196, 158, 72), M.Metal },
		Trim = { rgb(248, 214, 118), M.Foil },
		Dark = { rgb(18, 16, 14), M.Slate },
		Grip = { rgb(44, 28, 20), M.Leather },
		Gem = { rgb(255, 215, 95), M.Neon },
		Glow = { rgb(255, 202, 85), M.Neon },
	},
	cupR = 0.46,
	light = rgb(255, 210, 100),
})

-- Relic21: Corte de Plata
SkinDesigns.SilverCut = rapier({
	palette = {
		Blade = { rgb(24, 26, 32), M.Slate },
		Edge = { rgb(242, 245, 252), M.Foil },
		Accent = { rgb(168, 174, 186), M.Metal },
		Trim = { rgb(228, 234, 245), M.Foil },
		Dark = { rgb(14, 16, 20), M.Slate },
		Grip = { rgb(22, 24, 30), M.Leather },
		Gem = { rgb(205, 232, 255), M.Neon },
		Glow = { rgb(190, 222, 255), M.Neon },
	},
	cupR = 0.42,
	light = rgb(205, 225, 250),
})

-- Relic22: Lengua de Fuego
SkinDesigns.FireTongue = rapier({
	palette = {
		Blade = { rgb(32, 22, 18), M.Slate },
		Edge = { rgb(255, 218, 172), M.Foil },
		Accent = { rgb(142, 68, 32), M.Metal },
		Trim = { rgb(255, 138, 48), M.Foil },
		Dark = { rgb(20, 12, 10), M.Slate },
		Grip = { rgb(42, 20, 16), M.Leather },
		Gem = { rgb(255, 120, 35), M.Neon },
		Glow = { rgb(255, 105, 28), M.Neon },
	},
	cupR = 0.45,
	light = rgb(255, 125, 42),
	emit = "Embers",
})

-- Relic23: Duelo del Crepúsculo
SkinDesigns.TwilightDuel = rapier({
	palette = {
		Blade = { rgb(28, 28, 36), M.Slate },
		Edge = { rgb(226, 224, 236), M.Foil },
		Accent = { rgb(118, 110, 104), M.Metal },
		Trim = { rgb(188, 182, 174), M.Foil },
		Dark = { rgb(16, 16, 22), M.Slate },
		Grip = { rgb(30, 26, 32), M.Leather },
		Gem = { rgb(215, 195, 245), M.Neon },
		Glow = { rgb(198, 180, 235), M.Neon },
	},
	cupR = 0.44,
	light = rgb(200, 190, 230),
})

-- Relic24: Aguijón Espectral
SkinDesigns.SpectralSting = rapier({
	palette = {
		Blade = { rgb(20, 18, 30), M.Slate },
		Edge = { rgb(228, 212, 252), M.Foil },
		Accent = { rgb(82, 64, 122), M.Metal },
		Trim = { rgb(196, 160, 245), M.Foil },
		Dark = { rgb(12, 10, 18), M.Slate },
		Grip = { rgb(22, 18, 32), M.Leather },
		Gem = { rgb(205, 155, 255), M.Neon },
		Glow = { rgb(192, 142, 250), M.Neon },
	},
	cupR = 0.46,
	light = rgb(195, 150, 250),
	emit = "Wisps",
})

-- Relic25: Velo Amatista
SkinDesigns.AmethystVeil = rapier({
	palette = {
		Blade = { rgb(28, 18, 36), M.Slate },
		Edge = { rgb(246, 210, 242), M.Foil },
		Accent = { rgb(128, 62, 148), M.Metal },
		Trim = { rgb(236, 118, 214), M.Foil },
		Dark = { rgb(16, 10, 22), M.Slate },
		Grip = { rgb(32, 18, 36), M.Leather },
		Gem = { rgb(248, 115, 225), M.Neon },
		Glow = { rgb(240, 102, 215), M.Neon },
	},
	cupR = 0.45,
	light = rgb(238, 115, 215),
	emit = "Wisps",
})

-- Relic26: Lamento Oscuro (Estoque — Piloto Tanda 1 de Blender)
SkinDesigns.DarkLament = rapier({
	palette = {
		Blade = { rgb(14, 14, 18), M.Slate },
		Edge = { rgb(218, 224, 236), M.Foil },
		Accent = { rgb(42, 44, 52), M.Metal },
		Trim = { rgb(172, 178, 194), M.Foil },
		Dark = { rgb(8, 8, 12), M.Slate },
		Grip = { rgb(16, 16, 20), M.Leather },
		Gem = { rgb(235, 28, 46), M.Neon },
		Glow = { rgb(245, 34, 52), M.Neon },
	},
	cupR = 0.48,
	light = rgb(235, 36, 54),
	emit = "Smoke",
})

-- ============================================================================
-- 6. CONSTRUCTOR DE MAZAS Y HACHAS DE GUERRA (9 SKINS + RULETA CataclysmMaw, TipZ = 4.90)
-- ============================================================================
local function mace(cfg)
	return {
		palette = cfg.palette,
		build = function(b, v)
			b.handle.Size = Vector3.new(0.28, 0.28, 1.40)
			b.basePos = v(0, 3.05)

			-- Empuñadura reforzada con costillas en chevrón
			b:add("GripCore", Vector3.new(0.28, 0.30, 1.32), cf(0, 0, 0), "Grip")
			b:wrap(-0.56, 0.56, 5, 0.32, "Trim", 16)
			b:add("GripCollarB", Vector3.new(0.34, 0.36, 0.12), cf(0, 0, -0.68), "Accent")
			b:add("GripCollarF", Vector3.new(0.36, 0.38, 0.14), cf(0, 0, 0.70), "Accent")

			-- Pomo de tres garras con gema
			addClawedGemPommel(b, v, -0.88, 0.24, 0.26, 0.36, "Accent", "Edge", "Gem")

			-- Vara larga octogonal con anillos de refuerzo, recazo con 2 gemas y vena de energía
			b:cyl("MainShaft", 1.95, 2.40, 0.26, "Blade")
			for _, rz in { 1.15, 1.75, 2.35, 2.95 } do
				b:cyl("ShaftNode", rz, 0.14, 0.34, "Accent")
			end
			addDiamondBolsterGems(b, v, 2.85, 3.32, 0.44, 0.32, "Edge", "Dark", "Gem")
			addLightningVein(b, v, 1.10, 4.35, 6, 0.038, 0.30, 0.032, "Glow", true)

			-- Cabeza de impacto (z = 3.25 .. 4.42) + espolón apical afilado hasta TipZ = 4.90
			local hz = 3.82
			b:add("HeadCore", Vector3.new(0.76, 0.82, 1.08), cf(0, 0, hz), "Blade")
			b:add("HeadDarkInlay", Vector3.new(0.80, 0.48, 0.86), cf(0, 0, hz), "Dark")

			if cfg.variant == "flanges" or cfg.variant == "cataclysm" then
				local count = 6
				for i = 0, count - 1 do
					local a = (i / count) * math.pi * 2
					local cFrame = cf(0, 0, hz) * ang(0, 0, a)
					b:add("FlangeCore", Vector3.new(0.14, 0.64, 1.02), cFrame * cf(0, 0.48, 0), "Blade", "Wedge")
					b:add("FlangeRazorEdge", Vector3.new(0.10, 0.76, 1.08), cFrame * cf(0, 0.58, 0), "Edge", "Wedge")
				end
				if cfg.variant == "cataclysm" then
					addDorsalHooks(b, v, { 2.05, 2.50, 3.48, 4.12 }, -0.22, -1, 0.28, 0.30, 0.14, "Blade", "Edge")
				end
			elseif cfg.variant == "shards" then
				for i = 0, 7 do
					local a = (i / 8) * math.pi * 2
					local dir = Vector3.new(math.cos(a), math.sin(a), 0)
					b:point("CrimsonShard", dir * 0.32 + Vector3.new(0, 0, hz - 0.12), dir * 0.96 + Vector3.new(0, 0, hz + 0.18), 0.24, 0.18, i % 2 == 0 and "Edge" or "Gem")
				end
			elseif cfg.variant == "executioner" or cfg.variant == "axe" then
				-- Filo de hacha en media luna (+Y) con bisel de plata y pico rompecascos (-Y)
				local bladeArc = { { 0.48, 3.22 }, { 0.96, 3.50 }, { 1.12, 3.82 }, { 0.96, 4.14 }, { 0.48, 4.40 } }
				b:strip("AxeRazorBevel", bladeArc, { 0.32, 0.44, 0.48, 0.44, 0.32 }, 0.11, "Edge", 0)
				b:strip("AxeDarkBack", { { 0.36, 3.30 }, { 0.74, 3.82 }, { 0.36, 4.32 } }, { 0.28, 0.38, 0.28 }, 0.16, "Blade", 0)
				b:point("BackBeakCore", v(-0.36, hz), v(-1.12, hz - 0.16), 0.32, 0.22, "Blade")
				b:point("BackBeakEdge", v(-0.68, hz - 0.06), v(-1.28, hz - 0.22), 0.24, 0.16, "Edge")
			elseif cfg.variant == "forge" then
				b:add("HammerHead", Vector3.new(0.96, 1.78, 1.08), cf(0, 0, hz), "Blade")
				for _, s in { 1, -1 } do
					b:add("HammerFaceBevel", Vector3.new(0.88, 0.20, 1.14), cf(0, s * 0.92, hz), "Edge")
					b:add("ForgeVent", Vector3.new(1.00, 0.24, 0.24), cf(0, s * 0.48, hz) * ang(rad(45), 0, 0), "Glow")
				end
			elseif cfg.variant == "maw" or cfg.variant == "vertebra" or cfg.variant == "jaws" or cfg.variant == "crown" then
				for _, s in { 1, -1 } do
					b:curve("BoneJaw", { { s * 0.32, 3.28 }, { s * 0.78, 3.62 }, { s * 0.84, 4.02 }, { s * 0.46, 4.36 } }, 0.28, 0.16, "Accent")
					for k = 1, 3 do
						local zk = 3.38 + (k - 1) * 0.34
						b:point("JawFang", v(s * 0.56, zk), v(s * 1.06, zk - 0.12), 0.18, 0.14, "Edge")
					end
				end
				b:ball("MawCoreGem", v(0, hz), 0.46, "Gem")
			end

			-- Gemas laterales en las mejillas de la cabeza
			b:add("HeadGemBezel", Vector3.new(0.84, 0.26, 0.26), cf(0, 0, hz) * ang(rad(45), 0, 0), "Trim")
			b:add("HeadGem", Vector3.new(0.88, 0.16, 0.16), cf(0, 0, hz) * ang(rad(45), 0, 0), "Gem")

			-- Espolón apical afilado hasta TipZ = 4.90
			b:cyl("ApicalCollar", 4.40, 0.14, 0.44, "Accent")
			b:tip("ApicalSpikeEdge", 4.42, 0.48, 0.34, 0.18, "Edge")
			b:tip("ApicalSpikeCore", 4.42, 0.36, 0.22, 0.24, "Blade")

			b:light(v(0, 3.82), cfg.light, 7, 0.95)
			if cfg.emit then b:emit(cfg.emit, 3.15, 4.85, cfg.light) end
		end,
	}
end

-- Relic27: Juicio de Hierro
SkinDesigns.Flange = mace({
	palette = {
		Blade = { rgb(30, 30, 34), M.Slate },
		Edge = { rgb(238, 240, 246), M.Foil },
		Accent = { rgb(186, 152, 74), M.Metal },
		Trim = { rgb(242, 206, 112), M.Foil },
		Dark = { rgb(18, 18, 22), M.Slate },
		Grip = { rgb(42, 28, 20), M.Leather },
		Gem = { rgb(255, 208, 92), M.Neon },
		Glow = { rgb(255, 195, 78), M.Neon },
	},
	variant = "flanges",
	light = rgb(255, 205, 95),
})

-- Relic28: Espinas Carmesí
SkinDesigns.CrimsonShards = mace({
	palette = {
		Blade = { rgb(26, 18, 22), M.Slate },
		Edge = { rgb(236, 222, 232), M.Foil },
		Accent = { rgb(92, 28, 52), M.Metal },
		Trim = { rgb(225, 48, 108), M.Foil },
		Dark = { rgb(14, 10, 14), M.Slate },
		Grip = { rgb(28, 16, 22), M.Leather },
		Gem = { rgb(255, 42, 105), M.Neon },
		Glow = { rgb(245, 38, 98), M.Neon },
	},
	variant = "shards",
	light = rgb(240, 48, 105),
	emit = "Embers",
})

-- Relic29: Verdugo del Norte
SkinDesigns.NorthExecutioner = mace({
	palette = {
		Blade = { rgb(24, 28, 36), M.Slate },
		Edge = { rgb(238, 244, 252), M.Foil },
		Accent = { rgb(92, 102, 118), M.Metal },
		Trim = { rgb(198, 212, 232), M.Foil },
		Dark = { rgb(14, 16, 22), M.Slate },
		Grip = { rgb(28, 24, 22), M.Leather },
		Gem = { rgb(165, 225, 255), M.Neon },
		Glow = { rgb(150, 215, 255), M.Neon },
	},
	variant = "executioner",
	light = rgb(165, 220, 255),
	emit = "Frost",
})

-- Relic30: Corazón de Forja
SkinDesigns.Forge = mace({
	palette = {
		Blade = { rgb(24, 22, 26), M.Slate },
		Edge = { rgb(228, 224, 220), M.Foil },
		Accent = { rgb(78, 52, 38), M.Metal },
		Trim = { rgb(245, 132, 48), M.Foil },
		Dark = { rgb(14, 12, 14), M.Slate },
		Grip = { rgb(36, 22, 18), M.Leather },
		Gem = { rgb(255, 138, 42), M.Neon },
		Glow = { rgb(255, 118, 32), M.Neon },
	},
	variant = "forge",
	light = rgb(255, 130, 42),
	emit = "Embers",
})

-- Relic31: Mandíbula Antigua
SkinDesigns.AncientMaw = mace({
	palette = {
		Blade = { rgb(32, 28, 24), M.Slate },
		Edge = { rgb(232, 222, 198), M.Foil },
		Accent = { rgb(168, 150, 118), M.Limestone },
		Trim = { rgb(214, 196, 162), M.Limestone },
		Dark = { rgb(18, 16, 14), M.Slate },
		Grip = { rgb(38, 28, 22), M.Leather },
		Gem = { rgb(235, 175, 78), M.Neon },
		Glow = { rgb(225, 162, 68), M.Neon },
	},
	variant = "maw",
	light = rgb(225, 170, 82),
	emit = "Smoke",
})

-- Relic32: Hacha del Osario
SkinDesigns.OssuaryAxe = mace({
	palette = {
		Blade = { rgb(26, 24, 28), M.Slate },
		Edge = { rgb(236, 224, 198), M.Foil },
		Accent = { rgb(176, 152, 118), M.Limestone },
		Trim = { rgb(218, 198, 164), M.Foil },
		Dark = { rgb(14, 14, 18), M.Slate },
		Grip = { rgb(32, 24, 22), M.Leather },
		Gem = { rgb(235, 58, 48), M.Neon },
		Glow = { rgb(225, 48, 42), M.Neon },
	},
	variant = "axe",
	light = rgb(225, 62, 52),
	emit = "Smoke",
})

-- Maw02: Vértebra del Abismo
SkinDesigns.AbyssVertebra = mace({
	palette = {
		Blade = { rgb(26, 22, 22), M.Slate },
		Edge = { rgb(232, 220, 196), M.Foil },
		Accent = { rgb(178, 160, 128), M.Limestone },
		Trim = { rgb(212, 192, 158), M.Limestone },
		Dark = { rgb(16, 12, 12), M.Slate },
		Grip = { rgb(34, 20, 22), M.Leather },
		Gem = { rgb(235, 38, 46), M.Neon },
		Glow = { rgb(225, 32, 42), M.Neon },
	},
	variant = "vertebra",
	light = rgb(225, 42, 48),
	emit = "Embers",
})

-- Maw03: Fauces del Sepulcro
SkinDesigns.SepulcherJaws = mace({
	palette = {
		Blade = { rgb(28, 24, 22), M.Slate },
		Edge = { rgb(238, 226, 202), M.Foil },
		Accent = { rgb(186, 168, 134), M.Limestone },
		Trim = { rgb(224, 204, 168), M.Foil },
		Dark = { rgb(16, 14, 12), M.Slate },
		Grip = { rgb(38, 26, 20), M.Leather },
		Gem = { rgb(255, 158, 52), M.Neon },
		Glow = { rgb(245, 142, 44), M.Neon },
	},
	variant = "jaws",
	light = rgb(245, 150, 52),
	emit = "Embers",
})

-- Maw04: Corona del Osario (Maza — Piloto Tanda 1 de Blender)
SkinDesigns.OssuaryCrown = mace({
	palette = {
		Blade = { rgb(28, 26, 24), M.Slate },
		Edge = { rgb(244, 234, 208), M.Foil },
		Accent = { rgb(194, 176, 140), M.Limestone },
		Trim = { rgb(238, 198, 102), M.Foil },
		Dark = { rgb(16, 14, 14), M.Slate },
		Grip = { rgb(36, 26, 22), M.Leather },
		Gem = { rgb(255, 198, 78), M.Neon },
		Glow = { rgb(245, 185, 68), M.Neon },
	},
	variant = "crown",
	light = rgb(245, 190, 80),
	emit = "Embers",
})

-- Ruleta D15: Quebrantahuesos del Eclipse (Maza compañera de la espada de referencia)
SkinDesigns.CataclysmMaw = mace({
	palette = {
		Blade = { rgb(18, 18, 24), M.Slate },
		Edge = { rgb(234, 238, 248), M.Foil },
		Accent = { rgb(48, 50, 60), M.Metal },
		Trim = { rgb(202, 208, 222), M.Foil },
		Dark = { rgb(10, 10, 14), M.Slate },
		Grip = { rgb(20, 16, 20), M.Leather },
		Gem = { rgb(245, 18, 36), M.Neon },
		Glow = { rgb(255, 26, 44), M.Neon },
	},
	variant = "cataclysm",
	light = rgb(245, 24, 42),
	emit = "Embers",
})

return SkinDesigns
