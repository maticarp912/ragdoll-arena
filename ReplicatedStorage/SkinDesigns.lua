-- ModuleScript: ReplicatedStorage/SkinDesigns
-- Modelos de piezas de las skins por arma (lote 6), hechos a partir de las imágenes de
-- F:/RobloxJuegos/skins armas. Solo cosmético: no cambia alcance ni daño.
--
-- Ejes (espacio del mango): la hoja crece hacia +Z, el ancho de la hoja va en Y y el grosor en X.
-- v(y, z, x) crea un punto. El mango (Handle) está en el origen y mide lo que diga handle.Size.
-- Largos de referencia (igual que las armas base, para que la estela y el agarre sigan bien):
--   Espada: hoja 1.0 → 5.1   · Estoque: 1.1 → 5.6 · Espadón: 1.25 → 6.4
--   Daga:   hoja 0.6 → 2.9   · Maza: cabeza en z = 3.75
-- Roles de color: cada diseño trae su paleta { Rol = { Color3, Material } }.
-- Presupuesto: 110 piezas como máximo por skin, 1 luz y 1 emisor de partículas.

local rgb = Color3.fromRGB
local M = Enum.Material

local function P(r, g, b, mat) return { rgb(r, g, b), mat } end

local D = {}

----------------------------------------------------------------------
-- Ayudantes comunes
----------------------------------------------------------------------
-- Mango: tamaño, envoltura y anillos de los extremos
local function grip(b, len, d, wraps, role, tilt)
	b.handle.Size = Vector3.new(d, d, len)
	b:wrap(-len / 2 + 0.04, len / 2 - 0.04, wraps, d + 0.04, role or "Grip", tilt)
end

-- Línea fina en las dos caras de la hoja (runas, vetas, bordes grabados)
local function faces(b, name, a, c, w, x, role)
	for _, s in { 1, -1 } do
		b:seg(name, a + Vector3.new(x * s, 0, 0), c + Vector3.new(x * s, 0, 0), 0.02, w, role)
	end
end

-- Rombo pequeño (gema) en las dos caras
local function gem(b, name, y, z, size, x, role)
	for _, s in { 1, -1 } do
		b:add(name, Vector3.new(0.03, size, size), CFrame.new(x * s, y, z) * CFrame.Angles(math.rad(45), 0, 0), role)
	end
end

----------------------------------------------------------------------
-- DAGAS (Relic01 – Relic05)
----------------------------------------------------------------------

-- Colmillos Carmesí: hoja curva negra como una garra, runas rojas encendidas, espolón y hoja en el pomo
D.Fangs = {
	palette = { Blade = P(24, 18, 20, M.Metal), Glow = P(230, 40, 36, M.Neon), Grip = P(30, 22, 24, M.Leather), Accent = P(40, 26, 28, M.Metal) },
	build = function(b, v)
		grip(b, 0.8, 0.2, 4, "Grip", 18)
		for i = 0, 2 do b:seg("GripRune", v(-0.02, -0.25 + i * 0.25, 0.115), v(0.03, -0.15 + i * 0.25, 0.115), 0.02, 0.03, "Glow") end
		b:cyl("Collar", 0.45, 0.12, 0.27, "Accent")
		local pts = { { 0, 0.5 }, { 0.05, 0.92 }, { 0.14, 1.38 }, { 0.26, 1.82 }, { 0.42, 2.20 }, { 0.58, 2.54 } }
		b:strip("Blade", pts, { 0.36, 0.38, 0.34, 0.28, 0.2, 0.12 }, 0.08, "Blade", 0.36)
		-- vena de runas encendida en las dos caras, pegada al lomo
		local runes = { { -0.08, 0.6 }, { -0.03, 1.0 }, { 0.06, 1.48 }, { 0.2, 1.92 }, { 0.38, 2.3 } }
		for _, x in { 0.045, -0.045 } do b:strip("Rune", runes, { 0.035, 0.035, 0.03, 0.025, 0.02 }, 0.02, "Glow", 0, x) end
		-- espolón que sube desde la guarda
		b:strip("Spur", { { -0.12, 0.5 }, { -0.36, 0.62 }, { -0.46, 0.85 }, { -0.42, 1.02 } }, { 0.14, 0.12, 0.08, 0.05 }, 0.07, "Blade", 0.14)
		-- hoja corta en el pomo, curvada hacia el otro lado
		b:strip("PommelBlade", { { 0, -0.42 }, { -0.06, -0.7 }, { -0.18, -0.95 }, { -0.34, -1.12 } }, { 0.2, 0.18, 0.13, 0.07 }, 0.07, "Blade", 0.2)
		b:seg("PommelRune", v(-0.03, -0.5, 0.045), v(-0.15, -0.9, 0.045), 0.02, 0.03, "Glow")
		b:light(Vector3.new(0, 0.2, 1.5), rgb(230, 40, 36), 5, 0.6)
	end,
}

-- Espinas Vivas: núcleo negro con grieta roja y crecimientos de hueso blanco en los filos
D.LivingThorns = {
	palette = { Blade = P(26, 24, 28, M.Basalt), Bone = P(200, 190, 170, M.Limestone), Glow = P(220, 30, 30, M.Neon), Grip = P(32, 28, 30, M.Fabric), Accent = P(36, 32, 36, M.Metal) },
	build = function(b, v)
		grip(b, 0.8, 0.2, 4, "Grip", 25)
		b:ball("PommelGem", v(0, -0.48), 0.2, "Glow")
		b:point("PommelSpike", v(0, -0.52), v(0, -0.85), 0.18, 0.12, "Accent")
		-- guarda de púas negras abiertas en abanico
		for i, a in { 20, 45, 70 } do
			local r = math.rad(a)
			for _, s in { 1, -1 } do b:point("GuardThorn", v(0.1 * s, 0.48), v(s * math.sin(r) * (0.55 - i * 0.06), 0.48 + math.cos(r) * 0.35), 0.1, 0.08, "Accent") end
		end
		b:strip("Blade", { { 0, 0.45 }, { 0, 1.2 }, { 0.02, 2.0 }, { 0, 2.55 } }, { 0.3, 0.28, 0.22, 0.14 }, 0.1, "Blade", 0.36)
		faces(b, "Crack", v(0, 0.55), v(0, 2.6), 0.035, 0.052, "Glow")
		-- crecimientos de hueso: hacia atrás y hacia afuera, más largos cerca de la guarda
		for i = 0, 8 do
			local z = 0.7 + i * 0.22
			local len = 0.6 - i * 0.045
			b:point("BoneGrowth", v(0.1, z), v(0.14 + len * 0.85, z + len * 0.55), 0.2, 0.14, "Bone")
			b:point("BoneGrowth", v(-0.1, z + 0.11), v(-0.14 - len * 0.7, z + 0.11 + len * 0.65), 0.17, 0.13, "Bone")
		end
		b:emit("Embers", 0.6, 2.4, rgb(230, 50, 40))
	end,
}

-- Lunas del Vacío: alfanje oscuro con vetas violetas y guarda en media luna
D.VoidMoons = {
	palette = { Blade = P(30, 28, 38, M.Metal), Glow = P(150, 110, 240, M.Neon), Accent = P(44, 42, 52, M.Metal), Grip = P(26, 24, 30, M.Leather) },
	build = function(b, v)
		grip(b, 0.82, 0.2, 5, "Grip", 15)
		b:point("Pommel", v(0, -0.42), v(0, -0.72), 0.24, 0.14, "Accent")
		b:point("Pommel", v(0, -0.42), v(0, -0.3), 0.24, 0.14, "Accent")
		b:cyl("Collar", 0.43, 0.08, 0.25, "Accent")
		-- media luna: arco que abre hacia la hoja y dos cuernos
		b:arc("Moon", v(0, 0.66), Vector3.yAxis, Vector3.zAxis, 0.3, math.pi * 1.05, math.pi * 1.95, 6, 0.1, 0.09, "Accent")
		b:point("MoonHorn", v(0.28, 0.6), v(0.36, 0.86), 0.09, 0.08, "Accent")
		b:point("MoonHorn", v(-0.28, 0.6), v(-0.36, 0.86), 0.09, 0.08, "Accent")
		local pts = { { 0, 0.5 }, { 0.03, 0.96 }, { 0, 1.42 }, { -0.09, 1.88 }, { -0.22, 2.26 }, { -0.38, 2.58 } }
		b:strip("Blade", pts, { 0.34, 0.42, 0.44, 0.4, 0.3, 0.16 }, 0.08, "Blade", 0.30)
		-- vetas violetas en zigzag
		local vein = { { 0.02, 0.75 }, { -0.06, 1.1 }, { 0.05, 1.45 }, { -0.09, 1.8 }, { -0.12, 2.15 }, { -0.28, 2.5 } }
		for _, x in { 0.045, -0.045 } do b:strip("Vein", vein, { 0.03, 0.04, 0.03, 0.035, 0.03, 0.02 }, 0.02, "Glow", 0, x) end
		b:light(Vector3.new(0, 0, 1.6), rgb(150, 110, 240), 5, 0.5)
		b:emit("Wisps", 0.8, 2.5, rgb(140, 100, 230))
	end,
}

-- Crecientes de Plata: hoja curva con filo plateado agrietado, gancho en la guarda y mango envuelto
D.SilverCrescent = {
	palette = { Blade = P(36, 36, 40, M.Metal), Edge = P(225, 226, 232, M.Foil), Accent = P(58, 58, 64, M.Metal), Grip = P(22, 22, 24, M.Fabric) },
	build = function(b, v)
		grip(b, 0.84, 0.2, 7, "Grip", 8)
		-- pomo angular con ventana
		b:add("Pommel", Vector3.new(0.14, 0.3, 0.18), CFrame.new(0, 0.04, -0.5) * CFrame.Angles(math.rad(-12), 0, 0), "Accent")
		b:add("PommelHole", Vector3.new(0.16, 0.09, 0.07), CFrame.new(0, 0.07, -0.5), "Dark")
		-- gancho grande (anillo abierto) del lado del filo
		b:arc("Hook", v(-0.22, 0.6), Vector3.yAxis, Vector3.zAxis, 0.2, math.pi * 0.1, math.pi * 1.35, 6, 0.08, 0.09, "Accent")
		b:add("GuardPlate", Vector3.new(0.12, 0.4, 0.22), CFrame.new(0, 0, 0.5), "Accent")
		local pts = { { 0, 0.55 }, { 0.04, 1.0 }, { 0.04, 1.48 }, { -0.03, 1.92 }, { -0.14, 2.30 }, { -0.30, 2.60 } }
		b:strip("Blade", pts, { 0.36, 0.4, 0.4, 0.36, 0.26, 0.14 }, 0.08, "Blade", 0.30)
		-- filo plateado en el lado cóncavo
		local edge = {}
		for i, p in pts do edge[i] = { p[1] - ({ 0.36, 0.4, 0.4, 0.36, 0.26, 0.14 })[i] / 2 + 0.03, p[2] } end
		b:strip("SilverEdge", edge, { 0.07, 0.07, 0.07, 0.06, 0.05, 0.04 }, 0.1, "Edge", 0)
		-- ranura central y grietas
		b:strip("Fuller", { { 0.08, 0.9 }, { 0.08, 1.6 }, { 0.02, 2.1 } }, { 0.06, 0.06, 0.04 }, 0.1, "Edge", 0)
		b:seg("Crack", v(-0.1, 1.2, 0.045), v(0.02, 1.35, 0.045), 0.02, 0.025, "Edge")
		b:seg("Crack", v(-0.08, 1.9, -0.045), v(0.04, 2.0, -0.045), 0.02, 0.025, "Edge")
	end,
}

-- Garras del Eclipse: dos medias lunas enormes en la guarda y hoja curva larga
D.EclipseClaws = {
	palette = { Blade = P(70, 72, 78, M.Metal), Edge = P(170, 172, 178, M.Metal), Accent = P(46, 46, 52, M.Metal), Grip = P(90, 86, 80, M.Fabric), Dark = P(14, 14, 16, M.Metal) },
	build = function(b, v)
		grip(b, 0.84, 0.2, 6, "Grip", 30)
		b:cyl("Ferrule", -0.46, 0.1, 0.24, "Accent")
		b:ball("Pommel", v(0, -0.58), 0.22, "Accent")
		b:ring("PommelCrown", -0.66, 0.1, 0.05, 6, "Accent")
		b:cyl("Ferrule", 0.44, 0.08, 0.24, "Accent")
		-- garra hacia adelante (lado +Y) y garra hacia atrás (lado −Y)
		b:strip("ClawFront", { { 0.1, 0.55 }, { 0.32, 0.72 }, { 0.48, 1.0 }, { 0.52, 1.3 } }, { 0.16, 0.14, 0.1, 0.06 }, 0.07, "Blade", 0.25)
		b:strip("ClawBack", { { -0.1, 0.5 }, { -0.36, 0.42 }, { -0.5, 0.2 }, { -0.5, -0.06 } }, { 0.16, 0.14, 0.1, 0.06 }, 0.07, "Blade", 0.22)
		b:add("GuardCore", Vector3.new(0.14, 0.32, 0.26), CFrame.new(0, 0, 0.55), "Accent")
		-- dientes cortos sobre la guarda
		for i = 0, 2 do b:point("Teeth", v(0.05 + i * 0.06, 0.62), v(0.1 + i * 0.07, 0.8), 0.06, 0.05, "Blade") end
		local pts = { { 0, 0.6 }, { -0.05, 1.04 }, { -0.14, 1.48 }, { -0.26, 1.88 }, { -0.42, 2.24 }, { -0.60, 2.56 } }
		local widths = { 0.3, 0.34, 0.32, 0.28, 0.2, 0.1 }
		b:strip("Blade", pts, widths, 0.08, "Blade", 0.34)
		-- veta oscura (grieta) por el centro de la hoja
		for _, x in { 0.045, -0.045 } do b:strip("Crack", { { 0, 0.65 }, { -0.07, 1.15 }, { -0.15, 1.6 }, { -0.3, 2.05 }, { -0.48, 2.42 } }, { 0.035, 0.03, 0.03, 0.025, 0.02 }, 0.02, "Dark", 0, x) end
		local edge = {}
		for i, p in pts do edge[i] = { p[1] + widths[i] / 2 - 0.02, p[2] } end
		b:strip("Edge", edge, { 0.05, 0.05, 0.05, 0.04, 0.03, 0.02 }, 0.09, "Edge", 0)
	end,
}

----------------------------------------------------------------------
-- ESPADAS (Requiem + Relic07, 08, 09, 12, 13)
----------------------------------------------------------------------

-- Réquiem Astado (antigua espada base gótica: guarda con cuernos curvos, rizos, ganchos y pomo en espina)
D.RequiemHorns = {
	palette = {
		Blade = P(32, 32, 37, M.Metal),
		Accent = P(44, 42, 47, M.Metal),
		Grip = P(40, 30, 24, M.Fabric),
		Dark = P(24, 23, 26, M.Metal),
		Leather = P(30, 22, 18, M.Leather),
		Edge = P(103, 103, 108, M.Metal),
	},
	build = function(b)
		local h = b.handle
		h.Size = Vector3.new(0.3, 0.3, 1.3)
		for _, z in { -0.42, -0.14, 0.14, 0.42 } do
			b:add("GripRing", Vector3.new(0.34, 0.34, 0.06), CFrame.new(0, 0, z), "Dark")
		end
		-- Pomo: bola + espina
		b:add("Pommel", Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 0, -0.78), "Accent", nil, Enum.PartType.Ball)
		b:spike("PommelSpike", -0.92, 0.45, 0.22, "Accent", -1)
		-- Centro de la guarda
		b:add("GuardCore", Vector3.new(0.34, 0.5, 0.42), CFrame.new(0, 0, 0.82), "Accent")
		b:add("GuardGem", Vector3.new(0.38, 0.2, 0.2), CFrame.new(0, 0, 0.82), "Dark")
		-- Cuernos curvos hacia arriba (hacia la hoja) a ambos lados
		b:curve("GuardHorn", { { 0.22, 0.85 }, { 0.6, 0.98 }, { 0.95, 1.22 }, { 1.16, 1.58 }, { 1.2, 1.98 }, { 1.08, 2.32 } }, 0.2, 0.07, "Accent", true)
		-- Rizos hacia abajo
		b:curve("GuardCurl", { { 0.22, 0.76 }, { 0.55, 0.62 }, { 0.8, 0.4 }, { 0.84, 0.16 }, { 0.72, 0.02 } }, 0.15, 0.06, "Accent", true)
		-- Ganchos interiores pegados a la hoja
		b:curve("GuardHook", { { 0.2, 0.98 }, { 0.42, 1.18 }, { 0.46, 1.44 }, { 0.36, 1.62 } }, 0.12, 0.05, "Accent", true)
		-- Hoja
		local blade = b:add("Blade", Vector3.new(0.1, 0.38, 3.5), CFrame.new(0, 0, 0.98 + 1.75), "Blade")
		b:add("BladeRidge", Vector3.new(0.13, 0.07, 3.3), CFrame.new(0, 0, 0.98 + 1.7), "Accent")
		b:tip("BladePoint", 4.48, 0.62, 0.38, 0.1, "Blade")
		-- Filos biselados, ricasso, cuero entre los anillos y remaches de la guarda
		for _, s in { 1, -1 } do
			b:add("EdgeBevel", Vector3.new(0.06, 0.05, 3.4), CFrame.new(0, 0.18 * s, 0.98 + 1.72), "Edge")
			b:add("GuardRivet", Vector3.new(0.08, 0.08, 0.08), CFrame.new(0.18 * s, 0, 0.82), "Dark", nil, Enum.PartType.Ball)
		end
		b:add("Ricasso", Vector3.new(0.14, 0.3, 0.3), CFrame.new(0, 0, 1.12), "Accent")
		for _, z in { -0.28, 0, 0.28 } do
			b:add("Leather", Vector3.new(0.31, 0.31, 0.2), CFrame.new(0, 0, z) * CFrame.Angles(0, 0, math.rad(45)), "Leather")
		end
		b:add("PommelRing", Vector3.new(0.4, 0.4, 0.06), CFrame.new(0, 0, -0.62), "Dark")
		return blade, 0.98 + 1.75
	end,
}

-- Espina del Osario: hoja de vértebras con púas, máscara como guarda y mango de pelo negro
D.Ossuary = {
	palette = { Bone = P(214, 204, 182, M.Limestone), Blade = P(206, 196, 174, M.Limestone), Blood = P(104, 22, 24, M.CorrodedMetal), Grip = P(18, 18, 20, M.Fabric), Accent = P(40, 34, 38, M.Metal), Dark = P(10, 10, 12, M.Metal) },
	build = function(b, v)
		grip(b, 1.1, 0.22, 4, "Grip", 6)
		-- mechón de pelo: tiras que caen desde la guarda
		for i, y in { -0.12, 0, 0.12 } do b:seg("Hair", v(y, 0.62, 0.06 * (i - 2)), v(y * 1.6, -0.2), 0.05, 0.08, "Grip") end
		b:ball("Pommel", v(0, -0.66), 0.22, "Accent")
		b:cyl("Cord", -0.55, 0.06, 0.25, "Blood")
		-- máscara
		b:add("Mask", Vector3.new(0.26, 0.5, 0.5), CFrame.new(0, 0, 0.8), "Bone")
		b:add("MaskBrow", Vector3.new(0.3, 0.54, 0.08), CFrame.new(0, 0, 0.9), "Accent")
		for _, s in { 1, -1 } do
			b:ball("Eye", v(0.11 * s, 0.82, 0.12), 0.09, "Dark")
			b:point("MaskHorn", v(0.24 * s, 0.86), v(0.5 * s, 0.82), 0.1, 0.07, "Accent")
		end
		b:add("MaskSeal", Vector3.new(0.28, 0.06, 0.36), CFrame.new(0, 0, 0.72), "Blood")
		-- columna: núcleo + vértebras con púas que miran hacia la guarda
		local core = b:seg("Spine", v(0, 1.0), v(0, 4.75), 0.1, 0.1, "Blood")
		for i = 0, 9 do
			local z = 1.12 + i * 0.37
			local s = 1 - i * 0.05
			b:add("Vertebra", Vector3.new(0.2 * s, 0.24 * s, 0.22), CFrame.new(0, 0, z), "Bone")
			b:point("SpineThorn", v(0.1 * s, z), v(0.46 * s, z - 0.12), 0.1, 0.06, "Bone")
			b:point("SpineThorn", v(-0.1 * s, z), v(-0.46 * s, z - 0.12), 0.1, 0.06, "Bone")
		end
		b:point("Tip", v(0, 4.75), v(0, 5.12), 0.18, 0.1, "Bone")
		return core, 2.875
	end,
}

-- Corona del Alba: guarda de oro con alas caladas, hoja plateada ancha con muescas y grabado
D.DawnCrown = {
	palette = { Blade = P(206, 206, 212, M.Metal), Edge = P(236, 236, 240, M.Metal), Trim = P(214, 172, 72, M.Foil), Grip = P(22, 32, 28, M.Fabric), Rune = P(70, 70, 76, M.Metal), Dark = P(30, 24, 18, M.Metal) },
	build = function(b, v)
		grip(b, 1.1, 0.24, 7, "Grip", 35)
		-- pomo: corona de llamas
		b:ball("Pommel", v(0, -0.68), 0.26, "Trim")
		for _, a in { -35, 0, 35 } do local r = math.rad(a) b:point("Flame", v(0, -0.72), v(math.sin(r) * 0.3, -0.72 - math.cos(r) * 0.32), 0.1, 0.07, "Trim") end
		-- centro de la guarda con calavera y alas
		b:add("GuardCore", Vector3.new(0.3, 0.34, 0.44), CFrame.new(0, 0, 0.82), "Trim")
		b:point("GuardFang", v(0, 0.95), v(0, 1.35), 0.2, 0.12, "Trim")
		b:ball("Skull", v(0, 0.78, 0.15), 0.14, "Dark")
		for _, s in { 1, -1 } do
			b:strip("Wing", { { 0.14 * s, 0.86 }, { 0.5 * s, 0.98 }, { 0.86 * s, 0.98 }, { 1.06 * s, 0.82 } }, { 0.3, 0.3, 0.24, 0.16 }, 0.12, "Trim", 0)
			for i = 0, 2 do b:ball("WingHole", v((0.38 + i * 0.22) * s, 0.94, 0.03), 0.09, "Dark") end
			b:point("WingClaw", v(1.02 * s, 0.82), v(1.12 * s, 0.42), 0.11, 0.08, "Trim")
			b:point("WingClaw", v(0.78 * s, 0.9), v(0.84 * s, 0.6), 0.09, 0.07, "Trim")
		end
		-- hoja ancha que se afina
		local core = b:strip("Blade", { { 0, 1.0 }, { 0, 2.1 }, { 0, 3.4 }, { 0, 4.6 } }, { 0.56, 0.44, 0.32, 0.2 }, 0.1, "Blade", 0.5)
		faces(b, "Ridge", v(0, 1.9), v(0, 4.9), 0.04, 0.052, "Edge")
		for i = 0, 3 do faces(b, "Engraving", v(-0.06, 1.15 + i * 0.22), v(0.06, 1.27 + i * 0.22), 0.04, 0.052, "Rune") end
		-- muescas en flecha a los lados de la base
		for i = 0, 2 do
			local z = 1.25 + i * 0.32
			for _, s in { 1, -1 } do b:point("Notch", v(0.24 * s, z), v(0.4 * s, z - 0.08), 0.1, 0.08, "Blade") end
		end
		return core, 1.55
	end,
}

-- Filo del Dragón: hoja de dos tramos (ancha grabada y punta fina), garras en la guarda, pomo de dragón
D.DragonEdge = {
	palette = { Blade = P(132, 128, 116, M.Metal), Edge = P(170, 166, 154, M.Metal), Accent = P(96, 96, 102, M.Metal), Grip = P(70, 46, 34, M.Leather), Rune = P(92, 88, 78, M.Metal), Dark = P(30, 28, 30, M.Metal) },
	build = function(b, v)
		grip(b, 1.1, 0.24, 8, "Grip", 10)
		-- pomo: cabeza de dragón con cuernos
		b:add("DragonHead", Vector3.new(0.26, 0.3, 0.32), CFrame.new(0, 0, -0.72), "Accent")
		b:point("Snout", v(0, -0.86), v(0.04, -1.08), 0.22, 0.2, "Accent")
		for _, s in { 1, -1 } do b:point("Horn", v(0.1 * s, -0.8), v(0.32 * s, -1.02), 0.08, 0.07, "Accent") end
		b:cyl("Ferrule", 0.6, 0.1, 0.3, "Accent")
		-- garras de la guarda: tres por lado, curvas
		b:add("GuardCore", Vector3.new(0.26, 0.42, 0.3), CFrame.new(0, 0, 0.82), "Accent")
		for _, s in { 1, -1 } do
			b:strip("Claw", { { 0.18 * s, 0.86 }, { 0.5 * s, 0.98 }, { 0.72 * s, 0.86 }, { 0.82 * s, 0.6 } }, { 0.12, 0.1, 0.08, 0.05 }, 0.08, "Accent", 0.18)
			b:strip("Claw", { { 0.16 * s, 0.94 }, { 0.42 * s, 1.18 }, { 0.6 * s, 1.18 } }, { 0.09, 0.07, 0.05 }, 0.07, "Accent", 0.14)
			b:point("Claw", v(0.18 * s, 0.76), v(0.46 * s, 0.4), 0.09, 0.07, "Accent")
		end
		-- tramo ancho grabado y aserrado + punta fina con aletas
		local core = b:strip("Blade", { { 0, 0.95 }, { 0, 1.5 }, { 0, 2.55 }, { 0, 2.95 } }, { 0.42, 0.62, 0.58, 0.34 }, 0.1, "Blade", 0)
		b:strip("Blade", { { 0, 2.9 }, { 0, 4.0 }, { 0, 4.70 } }, { 0.3, 0.24, 0.16 }, 0.09, "Blade", 0.40)
		faces(b, "Ridge", v(0, 2.9), v(0, 5.0), 0.04, 0.047, "Edge")
		for i = 0, 3 do
			local z = 1.45 + i * 0.3
			for _, s in { 1, -1 } do b:point("Serration", v(0.27 * s, z), v(0.38 * s, z - 0.1), 0.14, 0.08, "Blade") end
			faces(b, "Engraving", v(-0.12, z), v(0.12, z + 0.14), 0.035, 0.052, "Rune")
		end
		for _, z in { 3.15, 4.1 } do for _, s in { 1, -1 } do b:point("Fin", v(0.12 * s, z - 0.1), v(0.22 * s, z + 0.08), 0.12, 0.07, "Blade") end end
		return core, 1.95
	end,
}

-- Diente del Exilio: espada de hierro sobria, guarda curva tachonada y pomo de corona
D.ExileTooth = {
	palette = { Blade = P(74, 76, 80, M.Metal), Edge = P(124, 126, 130, M.Metal), Accent = P(64, 62, 60, M.Metal), Trim = P(120, 112, 98, M.Metal), Grip = P(58, 44, 34, M.Leather), Dark = P(26, 26, 28, M.Metal) },
	build = function(b, v)
		grip(b, 1.0, 0.24, 7, "Grip", 40)
		b:add("Pommel", Vector3.new(0.26, 0.44, 0.24), CFrame.new(0, 0, -0.64), "Accent")
		for i = -1, 1 do b:ball("PommelStud", v(i * 0.13, -0.64, 0.13), 0.07, "Trim") end
		b:add("PommelCrown", Vector3.new(0.22, 0.4, 0.06), CFrame.new(0, 0, -0.79), "Trim")
		-- guarda curvada hacia la hoja, con tachas
		b:strip("Guard", { { -0.95, 0.98 }, { -0.5, 0.86 }, { 0, 0.82 }, { 0.5, 0.86 }, { 0.95, 0.98 } }, { 0.2, 0.2, 0.22, 0.2, 0.2 }, 0.2, "Accent", 0)
		for _, y in { -0.75, -0.4, 0, 0.4, 0.75 } do b:ball("Stud", v(y, 0.86 + math.abs(y) * 0.12, 0.1), 0.08, "Trim") end
		for _, s in { 1, -1 } do b:add("GuardEnd", Vector3.new(0.22, 0.1, 0.26), CFrame.new(0, 1.02 * s, 1.0), "Trim") end
		local core = b:strip("Blade", { { 0, 0.92 }, { 0, 2.3 }, { 0, 3.7 }, { 0, 4.65 } }, { 0.5, 0.44, 0.34, 0.22 }, 0.11, "Blade", 0.45)
		faces(b, "Fuller", v(0, 1.0), v(0, 3.9), 0.1, 0.056, "Dark")
		-- grabado cerca de la guarda
		for i = 0, 2 do faces(b, "Etch", v(-0.08 + i * 0.08, 1.05), v(-0.04 + i * 0.04, 1.5), 0.025, 0.058, "Edge") end
		return core, 2.4
	end,
}

-- Reliquia Dracónica: espada negra ornamentada con gema azul y runas que brillan en frío
D.DraconicRelic = {
	palette = { Blade = P(28, 28, 34, M.Metal), Accent = P(36, 36, 44, M.Metal), Glow = P(150, 180, 255, M.Neon), Edge = P(200, 205, 220, M.Metal), Grip = P(20, 20, 26, M.Fabric), Gem = P(60, 90, 230, M.Neon) },
	build = function(b, v)
		grip(b, 1.2, 0.22, 6, "Grip", 0)
		for i = 0, 3 do gem(b, "GripDiamond", 0, -0.45 + i * 0.3, 0.08, 0.12, "Edge") end
		-- pomo en forma de llama con gema
		b:add("PommelCage", Vector3.new(0.24, 0.3, 0.3), CFrame.new(0, 0, -0.72), "Accent")
		b:ball("PommelGem", v(0, -0.72, 0.1), 0.12, "Gem")
		b:point("PommelFlame", v(0, -0.86), v(0, -1.2), 0.2, 0.12, "Accent")
		for _, s in { 1, -1 } do b:point("PommelFlame", v(0.08 * s, -0.84), v(0.2 * s, -1.06), 0.1, 0.08, "Accent") end
		-- guarda: zarcillos negros y gema azul
		b:add("GuardCore", Vector3.new(0.3, 0.46, 0.36), CFrame.new(0, 0, 0.82), "Accent")
		b:ball("GuardGem", v(0, 0.82, 0.13), 0.16, "Gem")
		for _, s in { 1, -1 } do
			b:strip("Tendril", { { 0.2 * s, 0.82 }, { 0.48 * s, 0.9 }, { 0.62 * s, 1.1 }, { 0.56 * s, 1.3 } }, { 0.12, 0.1, 0.08, 0.05 }, 0.08, "Accent", 0.15)
			b:strip("Tendril", { { 0.2 * s, 0.76 }, { 0.42 * s, 0.6 }, { 0.46 * s, 0.38 } }, { 0.1, 0.08, 0.05 }, 0.07, "Accent", 0.12)
			b:ball("GuardPearl", v(0.4 * s, 0.84, 0.06), 0.07, "Glow")
		end
		local core = b:strip("Blade", { { 0, 1.0 }, { 0, 2.6 }, { 0, 4.0 }, { 0, 4.68 } }, { 0.42, 0.4, 0.36, 0.3 }, 0.1, "Blade", 0.44)
		for _, s in { 1, -1 } do b:seg("Edge", v(0.2 * s, 1.0), v(0.15 * s, 4.8), 0.11, 0.04, "Edge") end
		faces(b, "Groove", v(0, 1.1), v(0, 4.6), 0.07, 0.052, "Accent")
		for i = 0, 4 do faces(b, "Rune", v(-0.05, 1.5 + i * 0.6), v(0.05, 1.62 + i * 0.6), 0.05, 0.056, "Glow") end
		b:light(Vector3.new(0, 0, 0.9), rgb(90, 120, 255), 5, 0.6)
		b:emit("Wisps", 1.2, 4.6, rgb(190, 200, 255))
		return core, 1.8
	end,
}

----------------------------------------------------------------------
-- ESPADONES (Relic14, 15, 16, 17, 18, 19) — Escala colosal unificada (hoja 1.38 → 7.60)
----------------------------------------------------------------------

-- Tumba Esmeralda: monolito de piedra oscura con un anillo verde y una vena rúnica que baja hasta la punta
D.EmeraldTomb = {
	palette = { Blade = P(34, 40, 44, M.Slate), Edge = P(70, 80, 84, M.Slate), Glow = P(60, 255, 120, M.Neon), Accent = P(48, 52, 56, M.Metal), Grip = P(40, 44, 48, M.Fabric) },
	build = function(b, v)
		grip(b, 2.30, 0.30, 6, "Grip", 0)
		b:add("Pommel", Vector3.new(0.38, 0.38, 0.34), CFrame.new(0, 0, -1.32), "Accent")
		b:add("PommelCap", Vector3.new(0.28, 0.28, 0.16), CFrame.new(0, 0, -1.54), "Accent")
		-- guarda recta y ancha con remates
		b:add("Guard", Vector3.new(0.24, 3.05, 0.20), CFrame.new(0, 0, 1.26), "Accent")
		for _, s in { 1, -1 } do b:add("GuardEnd", Vector3.new(0.28, 0.20, 0.26), CFrame.new(0, 1.54 * s, 1.26), "Accent") end
		b:add("Shoulder", Vector3.new(0.34, 1.66, 0.28), CFrame.new(0, 0, 1.44), "Blade")
		local core = b:add("Blade", Vector3.new(0.30, 1.58, 5.14), CFrame.new(0, 0, 1.42 + 2.57), "Blade")
		b:point("BladePoint", v(0, 6.55), v(0, 7.60), 1.58, 0.30, "Glow")
		for _, s in { 1, -1 } do b:seg("Edge", v(0.79 * s, 1.48), v(0.79 * s, 6.56), 0.32, 0.08, "Edge") end
		-- anillo esmeralda grande en las dos caras
		for _, x in { 0.16, -0.16 } do b:arc("Ring", v(0, 2.38, x), Vector3.yAxis, Vector3.zAxis, 0.50, 0, math.pi * 2, 10, 0.04, 0.08, "Glow") end
		-- Pilar central dentro del anillo, vena central y ramas rúnicas
		faces(b, "RingPillar", v(0, 1.88), v(0, 2.88), 0.10, 0.16, "Accent")
		faces(b, "Vein", v(0, 2.88), v(0, 6.60), 0.06, 0.16, "Glow")
		for i, z in { 3.45, 4.20, 4.95, 5.70 } do
			local s = (i % 2 == 0) and 1 or -1
			faces(b, "Branch", v(0, z), v(0.30 * s, z - 0.32), 0.04, 0.16, "Glow")
		end
		-- Brillo que sube desde la punta
		for _, s in { 1, -1 } do b:seg("TipGlow", v(0.54 * s, 6.15, 0.16), v(0.26 * s, 6.56, 0.16), 0.03, 0.07, "Glow") end
		b:light(Vector3.new(0, 0, 2.40), rgb(60, 255, 120), 8, 0.75)
		b:emit("Wisps", 5.0, 7.3, rgb(70, 255, 130))
		return core, 3.99
	end,
}

-- Devorador: losa tallada con un rostro, costillas que asoman, un cuerno y un ala de plumas de hierro
local function devourerBase(b, v, wingsBothSides)
	grip(b, 2.30, 0.30, 9, "Grip", 45)
	b:cyl("PommelRing", -1.22, 0.14, 0.38, "Accent")
	b:add("Pommel", Vector3.new(0.34, 0.34, 0.28), CFrame.new(0, 0, -1.42), "Accent")
	-- Collar de dientes alrededor de la base
	b:arc("Collar", v(0, 1.45), Vector3.yAxis, Vector3.zAxis, 0.60, math.pi * 1.05, math.pi * 1.95, 5, 0.36, 0.15, "Accent")
	for i = 0, 6 do
		local t = math.pi * (1.1 + i * 0.8 / 6)
		local p = v(math.cos(t) * 0.60, 1.45 + math.sin(t) * 0.60)
		b:point("CollarTooth", p, p + Vector3.new(0, math.cos(t), math.sin(t)) * 0.26, 0.10, 0.24, "Accent")
	end
	-- Ala de plumas (lado +Y) y cuerno o ala (lado −Y)
	local function wing(s)
		for i = 0, 5 do
			local a = math.rad(15 + i * 13)
			local o = v(0.54 * s, 1.32 - i * 0.06)
			b:seg("Feather", o, o + v(math.cos(a) * (1.28 - i * 0.08) * s, -math.sin(a) * (1.28 - i * 0.08)), 0.16, 0.15, "Accent")
		end
	end
	wing(1)
	if wingsBothSides then wing(-1) else
		b:strip("Horn", { { -0.56, 1.35 }, { -0.92, 1.16 }, { -1.12, 0.84 }, { -1.08, 0.50 } }, { 0.28, 0.24, 0.18, 0.10 }, 0.24, "Accent", 0.24)
		for i = 0, 3 do b:seg("HornRidge", v(-0.68 - i * 0.10, 1.34 - i * 0.20), v(-0.78 - i * 0.12, 1.20 - i * 0.22), 0.28, 0.05, "Dark") end
	end
	local core = b:add("Blade", Vector3.new(0.32, 1.62, 5.15), CFrame.new(0, 0, 1.40 + 2.575), "Blade")
	b:point("BladePoint", v(0, 6.55), v(-0.10, 7.58), 1.62, 0.32, "Blade")
	-- Canales grabados junto a los filos
	for _, s in { 1, -1 } do faces(b, "Groove", v(0.56 * s, 2.95), v(0.56 * s, 6.50), 0.06, 0.165, "Dark") end
	faces(b, "Groove", v(0.56, 2.95), v(-0.14, 2.45), 0.06, 0.165, "Dark")
	return core
end

D.Devourer = {
	palette = { Blade = P(56, 58, 62, M.Slate), Accent = P(64, 66, 70, M.Metal), Grip = P(44, 46, 50, M.Fabric), Dark = P(16, 16, 18, M.Basalt), Relief = P(112, 112, 118, M.Slate) },
	build = function(b, v)
		local core = devourerBase(b, v, false)
		-- Relieve del rostro en la parte alta (lado −Y), en las dos caras
		for _, x in { 0.18, -0.18 } do
			b:add("Face", Vector3.new(0.10, 0.66, 0.88), CFrame.new(x, -0.34, 2.15), "Relief")
			b:ball("Eye", v(-0.20, 2.34, x * 1.25), 0.13, "Dark")
			b:add("Jaw", Vector3.new(0.09, 0.40, 0.26), CFrame.new(x * 1.1, -0.38, 1.72), "Relief")
			for i = 0, 3 do b:seg("Tendon", v(-0.08 - i * 0.10, 2.55 + i * 0.08, x), v(0.08 + i * 0.14, 3.40 + i * 0.15, x), 0.06, 0.06, "Relief") end
		end
		-- Costillas que asoman por el filo −Y
		for i = 0, 4 do
			local z = 2.15 + i * 0.34
			b:seg("Rib", v(-0.74, z), v(-1.22 + i * 0.04, z - 0.06), 0.10, 0.10, "Relief")
		end
		return core, 3.975
	end,
}

D.AbyssWings = {
	palette = { Blade = P(22, 22, 26, M.Metal), Accent = P(34, 34, 40, M.Metal), Grip = P(26, 26, 30, M.Fabric), Dark = P(8, 8, 10, M.Basalt), Glow = P(120, 90, 200, M.Neon), Edge = P(120, 120, 130, M.Metal) },
	build = function(b, v)
		local core = devourerBase(b, v, true)
		for _, s in { 1, -1 } do b:seg("Edge", v(0.80 * s, 1.50), v(0.80 * s, 6.55), 0.34, 0.07, "Edge") end
		faces(b, "Ridge", v(0, 1.65), v(0, 6.65), 0.08, 0.168, "Glow")
		b:light(Vector3.new(0, 0, 3.6), rgb(120, 90, 200), 7, 0.55)
		b:emit("Smoke", 1.6, 6.9, rgb(30, 26, 40))
		return core, 3.975
	end,
}

-- Luto Real: hoja colosal en forma de hoja de árbol con un panel de filigrana plateada
D.RoyalMourning = {
	palette = { Blade = P(40, 40, 44, M.Metal), Edge = P(150, 150, 156, M.Metal), Trim = P(196, 190, 186, M.Metal), Accent = P(38, 38, 42, M.Metal), Grip = P(22, 22, 24, M.Leather), Dark = P(16, 16, 18, M.Metal) },
	build = function(b, v)
		grip(b, 2.30, 0.28, 5, "Grip", 0)
		for _, z in { -0.75, -0.25, 0.25, 0.75 } do b:cyl("GripRing", z, 0.10, 0.36, "Accent") end
		b:cyl("PommelNeck", -1.25, 0.22, 0.26, "Accent")
		b:cyl("Pommel", -1.48, 0.24, 0.42, "Accent")
		b:point("PommelTip", v(0, -1.60), v(0, -1.92), 0.30, 0.30, "Accent")
		-- Guarda rectangular plana y pesada
		b:add("Guard", Vector3.new(0.36, 2.24, 0.24), CFrame.new(0, 0, 1.24), "Accent")
		b:add("GuardTrim", Vector3.new(0.40, 2.12, 0.08), CFrame.new(0, 0, 1.16), "Trim")
		local pts = { { 0, 1.32 }, { 0, 2.85 }, { 0, 4.85 }, { 0, 6.45 } }
		local core = b:strip("Blade", pts, { 1.38, 1.64, 1.50, 1.02 }, 0.28, "Blade", 1.15)
		for _, s in { 1, -1 } do b:strip("Edge", { { 0.69 * s, 1.32 }, { 0.80 * s, 2.85 }, { 0.73 * s, 4.85 }, { 0.49 * s, 6.45 }, { 0, 7.60 } }, { 0.08, 0.08, 0.08, 0.07, 0.05 }, 0.30, "Edge", 0) end
		-- Panel de filigrana: columna central y rombos reales
		faces(b, "Filigree", v(0, 1.50), v(0, 6.75), 0.08, 0.145, "Trim")
		for i = 0, 6 do
			local z = 1.80 + i * 0.76
			local w = 0.44 - math.abs(i - 3) * 0.05
			gem(b, "Lozenge", 0, z, w, 0.145, "Trim")
			faces(b, "Scroll", v(-w, z + 0.12), v(-w * 0.4, z + 0.38), 0.045, 0.148, "Trim")
			faces(b, "Scroll", v(w, z + 0.12), v(w * 0.4, z + 0.38), 0.045, 0.148, "Trim")
		end
		return core, 2.1
	end,
}

-- Cruz del Ocaso: espadón colosal de oro con cruz en relieve, punta ensanchada y medallón corrompido
D.DuskCross = {
	palette = { Blade = P(196, 156, 62, M.Foil), Trim = P(232, 196, 104, M.Foil), Accent = P(176, 136, 52, M.Metal), Grip = P(160, 120, 46, M.Metal), Dark = P(14, 12, 12, M.Basalt) },
	build = function(b, v)
		grip(b, 2.30, 0.30, 9, "Grip", 50)
		b:cyl("PommelNeck", -1.25, 0.18, 0.30, "Accent")
		b:cyl("Pommel", -1.46, 0.28, 0.48, "Trim")
		-- Guarda en cruz con ruedas de sol con rayos
		b:add("Guard", Vector3.new(0.28, 2.32, 0.26), CFrame.new(0, 0, 1.24), "Accent")
		b:cyl("SunWheel", 1.24, 0.36, 0.58, "Trim")
		for i = 0, 7 do
			local a = i * math.pi / 4
			b:point("SunRay", v(math.cos(a) * 0.28, 1.24 + math.sin(a) * 0.28), v(math.cos(a) * 0.62, 1.24 + math.sin(a) * 0.62), 0.09, 0.06, "Trim")
		end
		for _, s in { 1, -1 } do
			b:ball("GuardEnd", v(1.22 * s, 1.24), 0.30, "Trim")
			b:point("GuardSpike", v(0.82 * s, 1.18), v(0.90 * s, 0.78), 0.10, 0.08, "Trim")
		end
		local core = b:add("Blade", Vector3.new(0.28, 1.48, 5.05), CFrame.new(0, 0, 1.38 + 2.525), "Blade")
		b:add("TipBase", Vector3.new(0.28, 1.82, 0.42), CFrame.new(0, 0, 6.52), "Blade")
		b:point("Tip", v(0, 6.72), v(0, 7.60), 1.82, 0.28, "Blade")
		for _, s in { 1, -1 } do b:seg("Rim", v(0.71 * s, 1.42), v(0.71 * s, 6.38), 0.30, 0.07, "Trim") end
		-- Cruz con tres travesaños y flecha
		faces(b, "Cross", v(0, 1.85), v(0, 5.55), 0.09, 0.145, "Trim")
		for i = 0, 2 do faces(b, "CrossBar", v(-0.28, 2.20 + i * 0.32), v(0.28, 2.20 + i * 0.32), 0.08, 0.145, "Trim") end
		faces(b, "CrossBar", v(-0.22, 5.10), v(0.22, 5.10), 0.08, 0.145, "Trim")
		for _, s in { 1, -1 } do faces(b, "Arrow", v(0, 5.65), v(0.20 * s, 5.42), 0.07, 0.145, "Trim") end
		-- Medallón y corrupción negra
		for _, x in { 0.15, -0.15 } do b:arc("Medallion", v(0, 6.35, x), Vector3.yAxis, Vector3.zAxis, 0.42, 0, math.pi * 2, 8, 0.04, 0.08, "Trim") end
		for i = 0, 4 do
			local a = math.rad(-60 + i * 30)
			b:seg("Corruption", v(0.76, 6.00 + i * 0.15, 0.15), v(0.76 - math.cos(a) * 0.54, 6.00 + i * 0.15 + math.sin(a) * 0.38, 0.15), 0.04, 0.06, "Dark")
		end
		return core, 3.905
	end,
}

-- Sudario (Relic18): cuchilla colosal de verdugo envuelta en vendas funerarias cruzadas, con ojal circular y tiras colgantes
D.Shroud = {
	palette = {
		Blade = P(32, 34, 40, M.Metal),
		Edge = P(192, 198, 208, M.Metal),
		Bandage = P(194, 182, 154, M.Fabric),
		BandageDark = P(158, 146, 120, M.Fabric),
		Accent = P(56, 60, 68, M.Metal),
		Grip = P(98, 38, 34, M.Leather),
		Dark = P(16, 16, 20, M.Metal),
	},
	build = function(b, v)
		grip(b, 2.30, 0.28, 9, "Grip", 24)
		b:cyl("PommelCap", -1.24, 0.14, 0.38, "Accent")
		b:cyl("PommelRing", -1.36, 0.08, 0.44, "Dark")
		-- Guarda industrial remachada con tiras de sudario colgando hacia abajo
		b:add("Guard", Vector3.new(0.36, 2.22, 0.30), CFrame.new(0, 0, 1.25), "Accent")
		for _, y in { -0.82, -0.42, 0.42, 0.82 } do
			b:ball("GuardRivet", v(y, 1.25, 0.18), 0.10, "Dark")
			b:ball("GuardRivet", v(y, 1.25, -0.18), 0.10, "Dark")
		end
		-- Dos vendas largas que cuelgan desde la guarda
		b:strip("ShroudTail", { { -0.52, 1.15 }, { -0.78, 0.45 }, { -0.96, -0.35 }, { -1.08, -1.10 } }, { 0.18, 0.20, 0.22, 0.16 }, 0.05, "Bandage", 0)
		b:strip("ShroudTail", { { -0.44, 1.10 }, { -0.62, 0.35 }, { -0.74, -0.45 } }, { 0.14, 0.16, 0.14 }, 0.05, "BandageDark", 0, 0.06)
		-- Losa de cuchilla pesada (lomo negro en −Y, filo plateado ancho en +Y)
		local core = b:add("Blade", Vector3.new(0.28, 1.56, 5.15), CFrame.new(0, 0, 1.38 + 2.575), "Blade")
		b:seg("SilverBevel", v(0.46, 1.40), v(0.46, 6.55), 0.26, 0.66, "Edge")
		-- Punta asimétrica de cuchilla (termina en z = 7.60)
		b:point("BladePoint", v(0, 6.55), v(-0.18, 7.60), 1.56, 0.28, "Edge")
		-- Ojal circular cerca de la guarda (inspiración Zabuza / verdugo)
		b:add("CleaverHole", Vector3.new(0.32, 0.38, 0.38), CFrame.new(0, -0.22, 1.92), "Dark", nil, Enum.PartType.Cylinder)
		-- Vendas funerarias cruzadas a lo largo de toda la hoja
		for i = 0, 10 do
			local z = 1.65 + i * 0.46
			local tilt = (i % 2 == 0) and 0.28 or -0.24
			local role = (i % 3 == 0) and "BandageDark" or "Bandage"
			b:seg("BandageWrap", v(-0.79, z), v(0.79, z + tilt), 0.33, 0.20, role)
		end
		return core, 3.955
	end,
}

----------------------------------------------------------------------
-- ESTOQUES (Relic21 – Relic26)
----------------------------------------------------------------------

-- Corte de Plata: sable de hoja curva con arco de nudillos y anillo lateral
D.SilverCut = {
	palette = { Blade = P(66, 66, 70, M.Metal), Edge = P(150, 150, 156, M.Metal), Accent = P(54, 52, 52, M.Metal), Grip = P(36, 32, 30, M.Leather) },
	build = function(b, v)
		grip(b, 0.95, 0.2, 6, "Grip", 30)
		b:cyl("Pommel", -0.58, 0.22, 0.3, "Accent")
		b:cyl("PommelCap", -0.72, 0.08, 0.2, "Accent")
		b:cyl("GuardDisc", 0.56, 0.06, 0.5, "Accent")
		b:cyl("Collar", 0.66, 0.14, 0.18, "Accent")
		-- arco de nudillos que baja hasta el pomo, con remate de hoja
		b:strip("KnuckleBow", { { 0.12, 0.58 }, { 0.42, 0.42 }, { 0.5, 0.05 }, { 0.44, -0.32 }, { 0.22, -0.56 } }, { 0.06, 0.06, 0.06, 0.06, 0.05 }, 0.07, "Accent", 0)
		b:strip("Quillon", { { -0.12, 0.6 }, { -0.4, 0.66 }, { -0.5, 0.56 }, { -0.44, 0.46 } }, { 0.06, 0.06, 0.05, 0.04 }, 0.07, "Accent", 0.1)
		b:arc("SideRing", v(0, 0.48, 0.1), Vector3.xAxis, Vector3.zAxis, 0.18, -math.pi * 0.2, math.pi * 1.2, 5, 0.04, 0.04, "Accent")
		local pts = { { 0, 0.7 }, { 0.01, 1.8 }, { 0.06, 2.9 }, { 0.16, 3.9 }, { 0.3, 4.8 }, { 0.42, 5.3 } }
		local core = b:strip("Blade", pts, { 0.17, 0.17, 0.16, 0.14, 0.11, 0.08 }, 0.06, "Blade", 0.35)
		local back = {}
		for i, p in pts do back[i] = { p[1] - 0.07, p[2] } end
		b:strip("Spine", back, { 0.03, 0.03, 0.03, 0.03, 0.02, 0.02 }, 0.07, "Edge", 0)
		return core, 1.25
	end,
}

-- Lengua de Fuego: estoque retorcido, dos hebras en espiral alrededor de una aguja, brasas
D.FireTongue = {
	palette = { Blade = P(116, 100, 82, M.CorrodedMetal), Accent = P(92, 78, 64, M.CorrodedMetal), Glow = P(255, 120, 40, M.Neon), Grip = P(70, 58, 48, M.Wood) },
	build = function(b, v)
		b.handle.Size = Vector3.new(0.2, 0.2, 0.95)
		-- mango nudoso: tramos torcidos
		for i = 0, 3 do b:seg("Gnarl", v(0.04 * (i % 2 == 0 and 1 or -1), -0.5 + i * 0.25, 0.03), v(-0.04 * (i % 2 == 0 and 1 or -1), -0.25 + i * 0.25, -0.03), 0.16, 0.16, "Grip") end
		b:point("PommelSpike", v(0, -0.5), v(0.05, -0.95), 0.14, 0.12, "Accent")
		-- guarda corta con dos ganchos
		b:add("Guard", Vector3.new(0.18, 0.6, 0.16), CFrame.new(0, 0, 0.55), "Accent")
		b:point("GuardHook", v(0.28, 0.55), v(0.42, 0.4), 0.1, 0.08, "Accent")
		b:point("GuardHook", v(-0.28, 0.55), v(-0.38, 0.7), 0.1, 0.08, "Accent")
		local core = b:strip("Blade", { { 0, 0.6 }, { 0, 2.4 }, { 0, 4.2 }, { 0, 5.0 } }, { 0.13, 0.1, 0.07, 0.04 }, 0.08, "Blade", 0.5)
		-- dos hebras en espiral que se cierran hacia la punta
		for k = 0, 1 do
			local prev
			for i = 0, 10 do
				local z = 0.65 + i * 0.3
				local r = 0.16 * (1 - i / 12)
				local a = i * 0.9 + k * math.pi
				local p = Vector3.new(math.cos(a) * r, math.sin(a) * r, z)
				if prev then b:seg("Strand", prev, p, 0.07, 0.07, "Blade", 0.04) end
				prev = p
			end
		end
		for _, z in { 1.2, 2.1, 3.0 } do b:ball("Ember", Vector3.new(0, 0, z), 0.09, "Glow") end
		b:light(Vector3.new(0, 0, 2), rgb(255, 120, 40), 5, 0.6)
		b:emit("Embers", 0.8, 4.4, rgb(255, 130, 50))
		return core, 1.5
	end,
}

-- Duelo del Crepúsculo: espada de duelo larga, cazoleta de media concha y gavilanes rectos
D.TwilightDuel = {
	palette = { Blade = P(150, 150, 156, M.Metal), Edge = P(196, 196, 202, M.Metal), Accent = P(92, 90, 92, M.Metal), Trim = P(130, 126, 120, M.Metal), Grip = P(74, 58, 48, M.Leather) },
	build = function(b, v)
		grip(b, 0.95, 0.2, 7, "Grip", 40)
		b:ball("Pommel", v(0, -0.62), 0.26, "Accent")
		b:point("PommelTip", v(0, -0.72), v(0, -0.92), 0.12, 0.12, "Accent")
		-- media concha
		b:arc("Shell", v(0, 0.6), Vector3.yAxis, Vector3.zAxis, 0.42, 0, math.pi, 6, 0.36, 0.12, "Accent")
		b:add("ShellFace", Vector3.new(0.4, 0.7, 0.06), CFrame.new(0, 0, 0.66), "Accent")
		gem(b, "ShellOrnament", 0, 0.82, 0.16, 0.2, "Trim")
		-- gavilanes rectos con remates retorcidos
		b:add("Quillon", Vector3.new(0.09, 2.0, 0.09), CFrame.new(0, 0, 0.58), "Accent")
		for _, s in { 1, -1 } do b:add("QuillonEnd", Vector3.new(0.14, 0.3, 0.14), CFrame.new(0, 1.0 * s, 0.58) * CFrame.Angles(math.rad(45 * s), 0, 0), "Trim") end
		local core = b:strip("Blade", { { 0, 0.6 }, { 0, 2.6 }, { 0, 4.6 }, { 0, 5.2 } }, { 0.16, 0.13, 0.1, 0.07 }, 0.07, "Blade", 0.4)
		faces(b, "Ridge", v(0, 0.9), v(0, 5.2), 0.025, 0.037, "Edge")
		return core, 1.6
	end,
}

-- Aguijón Espectral: hoja fina oscura con filos lilas y alas negras en la guarda
D.SpectralSting = {
	palette = { Blade = P(38, 36, 46, M.Metal), Glow = P(196, 160, 240, M.Neon), Accent = P(20, 20, 24, M.Metal), Trim = P(196, 196, 206, M.Metal), Grip = P(22, 22, 26, M.Leather) },
	build = function(b, v)
		grip(b, 0.9, 0.18, 5, "Grip", 20)
		b:point("Pommel", v(0, -0.48), v(0, -0.78), 0.2, 0.14, "Trim")
		-- alas negras curvas, todas hacia atrás del lado −Y
		for i = 0, 3 do
			local spread = 0.25 + i * 0.12
			b:strip("Wing", { { -0.06, 0.55 }, { -spread, 0.45 - i * 0.05 }, { -spread - 0.12, 0.15 - i * 0.12 }, { -spread - 0.06, -0.1 - i * 0.16 } }, { 0.12, 0.1, 0.07, 0.04 }, 0.05, "Accent", 0.15)
		end
		b:strip("Crest", { { 0.06, 0.55 }, { 0.26, 0.5 }, { 0.32, 0.3 } }, { 0.08, 0.06, 0.04 }, 0.05, "Accent", 0.12)
		b:strip("KnuckleBow", { { 0.08, 0.5 }, { 0.3, 0.2 }, { 0.3, -0.2 }, { 0.12, -0.45 } }, { 0.05, 0.05, 0.05, 0.05 }, 0.06, "Accent", 0)
		local core = b:strip("Blade", { { 0, 0.55 }, { 0, 1.35 }, { 0, 3.3 }, { 0, 5.25 } }, { 0.22, 0.13, 0.13, 0.1 }, 0.06, "Blade", 0.3)
		for _, s in { 1, -1 } do b:strip("GlowEdge", { { 0.1 * s, 0.6 }, { 0.068 * s, 1.35 }, { 0.068 * s, 3.3 }, { 0.052 * s, 5.25 } }, { 0.025, 0.025, 0.025, 0.02 }, 0.065, "Glow", 0) end
		for _, z in { 1.3, 3.35 } do
			b:point("Node", v(0, z), v(0, z + 0.3), 0.22, 0.09, "Trim")
			b:point("Node", v(0, z), v(0, z - 0.3), 0.22, 0.09, "Trim")
		end
		b:light(Vector3.new(0, 0, 3), rgb(196, 160, 240), 4, 0.4)
		return core, 1.5
	end,
}

-- Velo Amatista: hoja violeta con gemas, cazoleta de alambre en espiral y pomo de cristal
D.AmethystVeil = {
	palette = { Blade = P(116, 74, 138, M.Metal), Edge = P(150, 108, 170, M.Metal), Accent = P(84, 104, 104, M.Metal), Gem = P(236, 110, 210, M.Neon), Grip = P(44, 54, 56, M.Leather), Crystal = P(200, 230, 240, M.Glass) },
	build = function(b, v)
		grip(b, 0.9, 0.18, 4, "Grip", 0)
		for _, z in { -0.2, 0.15 } do gem(b, "GripGem", 0, z, 0.08, 0.1, "Gem") end
		b:cyl("PommelRing", -0.5, 0.06, 0.24, "Gem")
		b:cyl("PommelBand", -0.57, 0.08, 0.2, "Accent")
		b:ball("Crystal", v(0, -0.68), 0.2, "Crystal")
		b:point("CrystalTip", v(0, -0.72), v(0, -0.9), 0.12, 0.12, "Crystal")
		-- cazoleta: dos anillos inclinados y rizos
		b:ring("CageRing", 0.42, 0.36, 0.04, 8, "Accent")
		b:arc("CageLoop", v(0, 0.2), Vector3.yAxis, Vector3.zAxis, 0.38, -math.pi * 0.4, math.pi * 1.4, 7, 0.04, 0.04, "Accent")
		for _, s in { 1, -1 } do
			b:strip("Curl", { { 0.08 * s, 0.62 }, { 0.3 * s, 0.68 }, { 0.42 * s, 0.82 }, { 0.36 * s, 0.94 } }, { 0.05, 0.05, 0.04, 0.03 }, 0.05, "Accent", 0)
			b:ball("Eye", v(0.08 * s, 0.68, 0.06), 0.06, "Gem")
		end
		b:strip("Vine", { { 0.08, 0.7 }, { -0.08, 1.0 }, { 0.06, 1.3 } }, { 0.035, 0.035, 0.03 }, 0.035, "Accent", 0, 0.05)
		local core = b:strip("Blade", { { 0, 0.62 }, { 0, 2.6 }, { 0, 4.8 } }, { 0.18, 0.17, 0.15 }, 0.08, "Blade", 0.55)
		faces(b, "Ridge", v(0, 0.7), v(0, 5.0), 0.04, 0.045, "Edge")
		for _, z in { 1.9, 2.6, 3.3 } do gem(b, "BladeGem", 0, z, 0.07, 0.045, "Gem") end
		return core, 1.6
	end,
}

-- Lamento Oscuro: hoja negra muy curva tipo sable, tsuba pequeña, mango nudoso con espina y humo
D.DarkLament = {
	palette = { Blade = P(14, 14, 16, M.Metal), Edge = P(46, 46, 52, M.Metal), Accent = P(34, 36, 44, M.Metal), Grip = P(30, 34, 44, M.Slate) },
	build = function(b, v)
		grip(b, 0.95, 0.2, 6, "Grip", 55)
		for i = 0, 2 do b:point("GripThorn", v(0.1, -0.3 + i * 0.25), v(0.2, -0.36 + i * 0.25), 0.06, 0.05, "Accent") end
		b:point("PommelSpike", v(0, -0.45), v(0.08, -1.1), 0.18, 0.14, "Accent")
		b:point("PommelSpike", v(-0.06, -0.55), v(-0.2, -0.85), 0.08, 0.07, "Accent")
		b:cyl("Tsuba", 0.52, 0.06, 0.42, "Accent")
		b:cyl("Habaki", 0.6, 0.12, 0.17, "Edge")
		local pts = { { 0, 0.6 }, { 0.03, 1.5 }, { 0.12, 2.4 }, { 0.28, 3.3 }, { 0.5, 4.15 }, { 0.78, 4.9 } }
		local core = b:strip("Blade", pts, { 0.2, 0.2, 0.19, 0.17, 0.14, 0.1 }, 0.07, "Blade", 0.5)
		local edge = {}
		for i, p in pts do edge[i] = { p[1] + 0.085, p[2] - 0.01 } end
		b:strip("Edge", edge, { 0.03, 0.03, 0.03, 0.03, 0.025, 0.02 }, 0.075, "Edge", 0)
		b:emit("Smoke", 1.0, 4.6, rgb(40, 40, 48))
		return core, 1.6
	end,
}

----------------------------------------------------------------------
-- MAZAS / MARTILLOS / HACHAS (Relic28, 29, 31, 32)
----------------------------------------------------------------------

-- Espinas Carmesí: martillo de cristales oscuros con calavera y aletas, mango retorcido con gancho
D.CrimsonShards = {
	palette = { Blade = P(58, 36, 44, M.Metal), Shard = P(92, 46, 70, M.Glass), Accent = P(124, 96, 64, M.Metal), Bone = P(150, 130, 100, M.Limestone), Glow = P(220, 40, 100, M.Neon), Grip = P(78, 50, 46, M.Wood), Dark = P(16, 10, 12, M.Metal) },
	build = function(b, v)
		b.handle.Size = Vector3.new(0.26, 0.26, 1.4)
		-- mango retorcido con gancho y collar de púas abajo
		b:strip("Haft", { { 0, 0.6 }, { 0.06, 1.4 }, { -0.04, 2.2 }, { 0, 3.1 } }, { 0.24, 0.24, 0.22, 0.22 }, 0.24, "Grip", 0)
		b:wrap(-0.65, 0.65, 6, 0.3, "Grip", 30)
		b:strip("Hook", { { 0, -0.7 }, { 0.06, -0.95 }, { 0.22, -1.12 }, { 0.38, -1.12 } }, { 0.22, 0.18, 0.12, 0.07 }, 0.2, "Grip", 0.15)
		b:cyl("SpikeCollar", -0.78, 0.14, 0.34, "Accent")
		for i = 0, 3 do
			local a = i * math.pi / 2 + 0.4
			b:point("CollarSpike", Vector3.new(math.cos(a) * 0.15, math.sin(a) * 0.15, -0.78), Vector3.new(math.cos(a) * 0.42, math.sin(a) * 0.42, -0.7), 0.1, 0.08, "Accent")
		end
		b:cyl("Langet", 3.05, 0.4, 0.34, "Accent")
		-- cabeza: bloque con cristales que salen en todas direcciones
		local head = b:add("Head", Vector3.new(0.92, 1.9, 1.0), CFrame.new(0, 0, 3.75), "Blade")
		local shards = {
			{ v(0.6, 3.9), v(1.2, 4.25) }, { v(0.85, 3.6), v(1.25, 3.3) }, { v(0.5, 4.2), v(0.8, 4.75) },
			{ v(-0.6, 3.95), v(-1.05, 4.4) }, { v(-0.8, 3.55), v(-1.25, 3.4) }, { v(-0.3, 4.2), v(-0.45, 4.8) },
			{ v(0.1, 4.2), v(0.15, 4.65) }, { v(0.95, 3.75), v(1.3, 3.8) },
		}
		for _, sh in shards do b:point("Shard", sh[1], sh[2], 0.32, 0.3, "Shard") end
		-- calavera con aletas en las dos caras
		for _, s in { 1, -1 } do
			local x = 0.5 * s
			b:ball("Skull", Vector3.new(x, -0.1, 3.75), 0.4, "Bone")
			b:ball("SkullEye", Vector3.new(x * 1.32, -0.18, 3.82), 0.1, "Glow")
			b:ball("SkullEye", Vector3.new(x * 1.32, -0.02, 3.82), 0.1, "Glow")
			for i = 0, 3 do
				local a = math.rad(-60 + i * 40)
				b:point("Fin", Vector3.new(x, -0.1, 3.75), Vector3.new(x, -0.1 + math.sin(a) * 0.75, 3.75 + math.cos(a) * 0.75), 0.18, 0.06, "Accent")
			end
		end
		b:add("Face", Vector3.new(0.96, 0.12, 1.04), CFrame.new(0, 0.98, 3.75), "Dark")
		b:light(Vector3.new(0, 0, 3.75), rgb(220, 40, 100), 5, 0.5)
		return head, 3.75
	end,
}

-- Verdugo del Norte: martillo doble plateado con calavera, alas y sellos; mango con cuero rojo en espiral
D.NorthExecutioner = {
	palette = { Blade = P(58, 60, 70, M.Metal), Trim = P(196, 196, 200, M.Metal), Accent = P(84, 86, 96, M.Metal), Leather = P(118, 54, 40, M.Leather), Grip = P(54, 56, 66, M.Metal), Dark = P(18, 18, 22, M.Metal) },
	build = function(b, v)
		b.handle.Size = Vector3.new(0.24, 0.24, 1.4)
		b:cyl("Haft", 1.9, 2.6, 0.24, "Grip")
		b:wrap(-0.65, 2.4, 9, 0.27, "Leather", 14)
		for _, z in { 2.55, 2.7, 3.0 } do b:cyl("Collar", z, 0.08, 0.34, "Trim") end
		b:cyl("ButtCap", -0.8, 0.16, 0.32, "Trim")
		b:point("ButtSpike", v(0, -0.88), v(0, -1.25), 0.2, 0.2, "Trim")
		-- cabeza doble
		local head = b:add("Head", Vector3.new(0.9, 1.4, 0.95), CFrame.new(0, 0, 3.75), "Blade")
		for _, s in { 1, -1 } do
			b:add("Block", Vector3.new(1.0, 0.36, 1.05), CFrame.new(0, 0.86 * s, 3.75), "Accent")
			b:add("Seal", Vector3.new(0.12, 0.62, 0.62), CFrame.new(0, 1.08 * s, 3.75) * CFrame.Angles(0, 0, math.pi / 2), "Trim", nil, Enum.PartType.Cylinder)
			b:add("SealMark", Vector3.new(0.06, 0.1, 0.36), CFrame.new(0, 1.15 * s, 3.75), "Dark")
			-- alas sobre la cabeza
			for i = 0, 3 do
				local a = math.rad(20 + i * 20)
				local o = v(0.35 * s, 4.25)
				b:seg("WingFeather", o, o + v(math.cos(a) * (0.95 - i * 0.12) * s, math.sin(a) * (0.95 - i * 0.12)), 0.18, 0.16, "Trim")
			end
		end
		-- calavera en las dos caras
		for _, s in { 1, -1 } do
			b:ball("Skull", Vector3.new(0.47 * s, 0, 3.82), 0.38, "Trim")
			b:add("SkullJaw", Vector3.new(0.12, 0.22, 0.16), CFrame.new(0.52 * s, 0, 3.58), "Trim")
			b:ball("SkullEye", Vector3.new(0.62 * s, -0.08, 3.86), 0.09, "Dark")
			b:ball("SkullEye", Vector3.new(0.62 * s, 0.08, 3.86), 0.09, "Dark")
		end
		return head, 3.75
	end,
}

-- Mandíbula Antigua: cuchilla envuelta en vendas con lomo aserrado, sobre un mango curvo vendado
D.AncientMaw = {
	palette = { Blade = P(66, 60, 54, M.Metal), Grip = P(152, 136, 110, M.Fabric), Bandage = P(170, 152, 120, M.Fabric), Accent = P(70, 64, 60, M.Metal), Dark = P(30, 26, 22, M.Metal), Glow = P(220, 190, 120, M.Neon) },
	build = function(b, v)
		b.handle.Size = Vector3.new(0.26, 0.26, 1.4)
		b:strip("Haft", { { 0, 0.6 }, { -0.12, 1.3 }, { -0.04, 2.0 }, { 0.06, 2.6 } }, { 0.26, 0.26, 0.24, 0.24 }, 0.26, "Grip", 0)
		b:wrap(-0.65, 0.65, 7, 0.3, "Bandage", 25)
		for i = 0, 3 do b:seg("Rag", v(-0.12 + i * 0.03, 1.0 + i * 0.35), v(-0.42 - i * 0.04, 0.9 + i * 0.3), 0.04, 0.1, "Bandage") end
		b:add("Hub", Vector3.new(0.3, 0.42, 0.42), CFrame.new(0, 0.08, 2.75) * CFrame.Angles(0, math.pi / 2, 0), "Accent", nil, Enum.PartType.Cylinder)
		b:ball("HubBolt", v(0.08, 2.75, 0.17), 0.12, "Dark")
		-- cuchilla grande hacia +Y, inclinada
		local head = b:add("Cleaver", Vector3.new(0.14, 1.05, 2.0), CFrame.new(0, 0.38, 3.75) * CFrame.Angles(math.rad(-8), 0, 0), "Blade")
		b:point("CleaverHook", v(0.62, 4.65), v(0.95, 4.8), 0.5, 0.14, "Blade")
		-- lomo aserrado (lado −Y)
		for i = 0, 6 do
			local z = 2.95 + i * 0.26
			b:point("Serration", v(-0.12 - (z - 2.95) * 0.14, z), v(-0.36 - (z - 2.95) * 0.14, z - 0.08), 0.16, 0.1, "Blade")
		end
		-- vendas cruzadas en las dos caras
		for i = 0, 4 do
			local z = 3.0 + i * 0.36
			for _, x in { 0.08, -0.08 } do b:seg("Bandage", v(-0.12, z, x), v(0.85, z + 0.28 * (i % 2 == 0 and 1 or -1), x), 0.03, 0.1, "Bandage") end
		end
		-- runas cosidas
		for i = 0, 2 do b:seg("Stitch", v(0.15 + i * 0.12, 3.4, 0.09), v(0.15 + i * 0.12, 3.6, 0.09), 0.02, 0.03, "Glow") end
		return head, 3.75
	end,
}

-- Hacha del Osario: hacha doble de hueso con púas, núcleo de hierro mecánico y mango de vértebras
D.OssuaryAxe = {
	palette = { Bone = P(196, 170, 132, M.Limestone), Blade = P(186, 160, 124, M.Limestone), Iron = P(40, 40, 48, M.Metal), Rope = P(88, 64, 40, M.Fabric), Grip = P(176, 152, 118, M.Limestone), Dark = P(60, 44, 30, M.Wood) },
	build = function(b, v)
		b.handle.Size = Vector3.new(0.24, 0.24, 1.4)
		-- mango de hueso con nudos de vértebra y cuerda
		b:cyl("Haft", 1.9, 2.6, 0.22, "Grip")
		for _, z in { 0.9, 1.5, 2.1, 2.7 } do b:ball("Knuckle", v(0, z), 0.32, "Bone") end
		b:wrap(-0.3, 0.6, 5, 0.27, "Rope", 30)
		b:ball("ButtKnuckle", v(0, -0.75), 0.34, "Bone")
		b:point("ButtClaw", v(0.1, -0.8), v(0.4, -1.15), 0.12, 0.1, "Bone")
		b:point("ButtClaw", v(-0.1, -0.8), v(-0.35, -1.2), 0.12, 0.1, "Bone")
		b:point("ButtSpike", v(0, -0.85), v(0, -1.3), 0.14, 0.14, "Iron")
		-- núcleo de hierro con púas
		local head = b:add("Core", Vector3.new(0.4, 0.5, 0.9), CFrame.new(0, 0, 3.85), "Iron")
		b:point("TopSpike", v(0, 4.3), v(0, 4.95), 0.22, 0.2, "Iron")
		for _, s in { 1, -1 } do b:point("SideSpike", Vector3.new(0.2 * s, 0, 3.55), Vector3.new(0.65 * s, 0, 3.4), 0.18, 0.12, "Iron") end
		b:add("Bracket", Vector3.new(0.44, 0.7, 0.12), CFrame.new(0, 0, 3.45), "Iron")
		-- dos hojas de hueso en abanico con púas en el borde
		for _, s in { 1, -1 } do
			b:strip("AxeBlade", { { 0.22 * s, 3.85 }, { 0.6 * s, 3.85 }, { 0.95 * s, 3.85 } }, { 0.7, 1.05, 1.35 }, 0.14, "Blade", 0)
			for i = 0, 4 do
				local z = 3.25 + i * 0.3
				b:point("EdgeSpike", v(1.0 * s, z), v(1.28 * s, z + (z - 3.85) * 0.5), 0.16, 0.1, "Dark")
			end
			b:ball("Hole", v(0.7 * s, 4.2, 0.06), 0.1, "Dark")
		end
		return head, 3.85
	end,
}

----------------------------------------------------------------------
-- DISEÑOS REHECHOS DE SKINS ANTIGUAS (Solar, Violet, Void, Duel, Flange, Forge)
----------------------------------------------------------------------

-- Juramento Solar (Relic06): espada de caballero solar con halo radiante en la guarda, cuero carmesí y hoja de oro bruñido
D.Solar = {
	palette = { Blade = P(214, 178, 102, M.Metal), Edge = P(248, 224, 152, M.Foil), Accent = P(178, 134, 58, M.Metal), Grip = P(84, 34, 28, M.Leather), Glow = P(255, 198, 92, M.Neon), Dark = P(42, 30, 20, M.Metal) },
	build = function(b, v)
		grip(b, 1.18, 0.24, 7, "Grip", 18)
		b:cyl("PommelCollar", -0.64, 0.08, 0.28, "Accent")
		b:cyl("SunPommel", -0.78, 0.14, 0.42, "Accent")
		b:ball("PommelSunCore", v(0, -0.78), 0.20, "Glow")
		-- Guarda en cruz con halo solar calado y rayos laterales
		b:add("GuardCore", Vector3.new(0.28, 0.44, 0.32), CFrame.new(0, 0, 0.80), "Accent")
		b:arc("SolarHalo", v(0, 0.84), Vector3.yAxis, Vector3.zAxis, 0.42, 0, math.pi * 2, 10, 0.08, 0.08, "Accent")
		for _, s in { 1, -1 } do
			b:strip("SunQuillon", { { 0.18 * s, 0.80 }, { 0.58 * s, 0.84 }, { 0.96 * s, 0.92 } }, { 0.20, 0.16, 0.10 }, 0.14, "Accent", 0.18)
			b:point("SolarRay", v(0.32 * s, 0.92), v(0.56 * s, 1.24), 0.12, 0.08, "Edge")
		end
		local core = b:strip("Blade", { { 0, 0.96 }, { 0, 2.40 }, { 0, 3.80 }, { 0, 4.62 } }, { 0.46, 0.42, 0.34, 0.24 }, 0.10, "Blade", 0.48)
		faces(b, "SolarFuller", v(0, 1.08), v(0, 3.70), 0.10, 0.052, "Dark")
		faces(b, "SunVein", v(0, 1.14), v(0, 4.10), 0.035, 0.056, "Glow")
		for _, s in { 1, -1 } do
			b:seg("EdgeBevel", v(0.21 * s, 1.00), v(0.14 * s, 4.60), 0.07, 0.04, "Edge")
		end
		b:light(Vector3.new(0, 0, 1.8), rgb(255, 198, 92), 5, 0.55)
		return core, 2.80
	end,
}

-- Vigilia Violeta (Relic10): espada de centinela nocturno con guarda en V invertida, cuero oscuro y fuller amatista
D.Violet = {
	palette = { Blade = P(64, 54, 86, M.Metal), Edge = P(168, 152, 204, M.Metal), Accent = P(98, 76, 134, M.Metal), Grip = P(32, 24, 42, M.Leather), Glow = P(186, 118, 255, M.Neon), Dark = P(22, 18, 30, M.Metal) },
	build = function(b, v)
		grip(b, 1.16, 0.23, 6, "Grip", 22)
		b:add("Pommel", Vector3.new(0.24, 0.38, 0.32), CFrame.new(0, 0, -0.74) * CFrame.Angles(math.rad(45), 0, 0), "Accent")
		gem(b, "PommelGem", 0, -0.74, 0.14, 0.13, "Glow")
		b:add("GuardHub", Vector3.new(0.28, 0.46, 0.34), CFrame.new(0, 0, 0.80), "Accent")
		gem(b, "GuardAmethyst", 0, 0.82, 0.18, 0.15, "Glow")
		for _, s in { 1, -1 } do
			b:strip("WingGuard", { { 0.18 * s, 0.80 }, { 0.56 * s, 0.92 }, { 0.92 * s, 1.12 } }, { 0.22, 0.16, 0.10 }, 0.14, "Accent", 0.16)
			b:point("GuardSpur", v(0.38 * s, 0.76), v(0.58 * s, 0.56), 0.10, 0.08, "Edge")
		end
		local core = b:strip("Blade", { { 0, 0.96 }, { 0, 2.35 }, { 0, 3.75 }, { 0, 4.62 } }, { 0.44, 0.40, 0.32, 0.22 }, 0.10, "Blade", 0.48)
		faces(b, "Fuller", v(0, 1.06), v(0, 3.65), 0.11, 0.052, "Dark")
		for i = 0, 4 do
			gem(b, "VigilRune", 0, 1.35 + i * 0.52, 0.08, 0.055, "Glow")
		end
		for _, s in { 1, -1 } do
			b:seg("EdgeBevel", v(0.20 * s, 1.00), v(0.13 * s, 4.60), 0.07, 0.04, "Edge")
		end
		b:light(Vector3.new(0, 0, 2.0), rgb(186, 118, 255), 5, 0.5)
		return core, 2.80
	end,
}

-- Aguja del Vacío (Relic11): espada de estocada y corte con ventana abisal en el recazo y nervio estelar
D.Void = {
	palette = { Blade = P(24, 24, 34, M.Metal), Edge = P(128, 122, 168, M.Metal), Accent = P(46, 42, 66, M.Metal), Grip = P(18, 18, 26, M.Leather), Glow = P(158, 92, 248, M.Neon), Dark = P(10, 10, 16, M.Metal) },
	build = function(b, v)
		grip(b, 1.18, 0.22, 7, "Grip", 28)
		b:ball("VoidPommel", v(0, -0.74), 0.26, "Accent")
		b:point("PommelTail", v(0, -0.82), v(0, -1.12), 0.16, 0.12, "Accent")
		b:add("GuardCore", Vector3.new(0.26, 0.42, 0.34), CFrame.new(0, 0, 0.80), "Accent")
		for _, s in { 1, -1 } do
			b:strip("VoidHorn", { { 0.16 * s, 0.82 }, { 0.48 * s, 1.02 }, { 0.72 * s, 1.34 }, { 0.64 * s, 1.68 } }, { 0.18, 0.14, 0.10, 0.06 }, 0.10, "Accent", 0.16)
			b:seg("LowerQuillon", v(0.16 * s, 0.76), v(0.56 * s, 0.58), 0.10, 0.12, "Accent")
		end
		-- Ventana abisal en la base de la hoja + aguja larga hasta z = 5.10
		b:ball("VoidEye", v(0, 1.24), 0.18, "Glow")
		for _, s in { 1, -1 } do
			b:seg("RicassoArch", v(0.18 * s, 0.94), v(0.16 * s, 1.56), 0.11, 0.12, "Blade")
		end
		local core = b:strip("Blade", { { 0, 1.52 }, { 0, 2.80 }, { 0, 4.00 }, { 0, 4.60 } }, { 0.38, 0.32, 0.24, 0.18 }, 0.10, "Blade", 0.50)
		faces(b, "VoidVein", v(0, 1.58), v(0, 4.55), 0.04, 0.054, "Glow")
		b:light(Vector3.new(0, 0, 1.4), rgb(158, 92, 248), 5, 0.55)
		return core, 3.00
	end,
}

-- Duelo Dorado (Relic20): estoque real con cazoleta de filigrana imperial, lazos barridos y hoja adamantina (z = 5.55)
D.Duel = {
	palette = { Blade = P(210, 198, 172, M.Metal), Edge = P(244, 236, 214, M.Foil), Accent = P(204, 162, 74, M.Foil), Grip = P(72, 26, 28, M.Leather), Dark = P(38, 28, 18, M.Metal) },
	build = function(b, v)
		grip(b, 0.98, 0.20, 7, "Grip", 32)
		b:ball("Pommel", v(0, -0.64), 0.28, "Accent")
		b:point("PommelFinial", v(0, -0.74), v(0, -0.96), 0.14, 0.14, "Accent")
		b:arc("RoyalCup", v(0, 0.58), Vector3.yAxis, Vector3.zAxis, 0.40, 0, math.pi, 7, 0.36, 0.10, "Accent")
		b:ring("CupRim", 0.58, 0.40, 0.06, 10, "Accent")
		b:strip("KnuckleBow", { { 0.14, 0.58 }, { 0.44, 0.38 }, { 0.48, -0.04 }, { 0.38, -0.42 }, { 0.16, -0.60 } }, { 0.06, 0.06, 0.06, 0.05, 0.05 }, 0.06, "Accent", 0)
		b:add("Quillon", Vector3.new(0.08, 1.86, 0.08), CFrame.new(0, 0, 0.58), "Accent")
		local core = b:strip("Blade", { { 0, 0.64 }, { 0, 2.40 }, { 0, 4.10 }, { 0, 5.05 } }, { 0.16, 0.13, 0.10, 0.07 }, 0.07, "Blade", 0.50)
		faces(b, "GoldRidge", v(0, 0.80), v(0, 5.00), 0.03, 0.038, "Accent")
		return core, 2.80
	end,
}

-- Juicio de Hierro (Relic27): maza de armas bridada de 6 aletas biseladas con corona de impacto (z = 4.90)
D.Flange = {
	palette = { Blade = P(84, 88, 96, M.Metal), Edge = P(146, 150, 160, M.Metal), Accent = P(56, 58, 66, M.Metal), Grip = P(58, 42, 32, M.Leather), Wood = P(64, 46, 34, M.Wood), Dark = P(24, 26, 30, M.Metal) },
	build = function(b, v)
		b.handle.Size = Vector3.new(0.28, 0.28, 1.40)
		b:wrap(-0.62, 0.62, 6, 0.32, "Grip", 24)
		b:cyl("PommelRing", -0.78, 0.14, 0.38, "Accent")
		b:point("ButtSpike", v(0, -0.84), v(0, -1.18), 0.22, 0.22, "Accent")
		b:cyl("Haft", 1.95, 2.50, 0.26, "Wood")
		for _, z in { 1.25, 2.05, 2.85 } do b:cyl("HaftBand", z, 0.08, 0.32, "Accent") end
		local head = b:cyl("HeadCore", 3.75, 1.35, 0.52, "Accent")
		for i = 0, 5 do
			local a = (i / 6) * math.pi * 2
			local cf = CFrame.new(math.cos(a) * 0.36, math.sin(a) * 0.36, 3.75) * CFrame.Angles(0, 0, a)
			b:add("FlangeWing", Vector3.new(0.46, 0.10, 1.18), cf, "Blade")
			b:add("FlangeEdge", Vector3.new(0.14, 0.07, 1.12), cf * CFrame.new(0.22, 0, 0), "Edge")
		end
		b:cyl("TopCollar", 4.46, 0.12, 0.44, "Accent")
		b:point("TopSpike", v(0, 4.50), v(0, 4.92), 0.28, 0.28, "Edge")
		return head, 3.75
	end,
}

-- Corazón de Forja (Relic30): gran martillo de herrero con cámara de magma incandescente y chimeneas (z = 4.90)
D.Forge = {
	palette = { Blade = P(52, 48, 50, M.Metal), Edge = P(138, 108, 76, M.Metal), Accent = P(92, 68, 48, M.CorrodedMetal), Grip = P(68, 44, 32, M.Leather), Glow = P(255, 112, 34, M.Neon), Dark = P(22, 18, 18, M.Metal) },
	build = function(b, v)
		b.handle.Size = Vector3.new(0.28, 0.28, 1.40)
		b:wrap(-0.62, 0.62, 6, 0.32, "Grip", 20)
		b:cyl("PommelAnvil", -0.80, 0.18, 0.42, "Accent")
		b:cyl("Haft", 1.95, 2.50, 0.26, "Accent")
		b:cyl("NeckCollar", 3.10, 0.24, 0.42, "Edge")
		local head = b:add("ForgeHead", Vector3.new(1.06, 2.04, 1.12), CFrame.new(0, 0, 3.75), "Blade")
		b:add("MagmaHeart", Vector3.new(1.12, 0.68, 0.56), CFrame.new(0, 0, 3.75), "Glow")
		for _, s in { 1, -1 } do
			b:add("StrikeFace", Vector3.new(1.16, 0.22, 1.20), CFrame.new(0, 0.98 * s, 3.75), "Edge")
			b:add("GrateBar", Vector3.new(1.16, 0.10, 0.62), CFrame.new(0, 0.22 * s, 3.75), "Blade")
		end
		b:point("AnvilCrown", v(0, 4.32), v(0, 4.90), 0.46, 0.36, "Edge")
		b:light(Vector3.new(0, 0, 3.75), rgb(255, 112, 34), 6, 0.65)
		b:emit("Embers", 3.2, 4.4, rgb(255, 120, 40))
		return head, 3.75
	end,
}

----------------------------------------------------------------------
-- 3 NUEVAS MAZAS ÓSEAS / MONSTRUOSAS (Fase 5: inspiradas en AncientMaw / Relic31)
----------------------------------------------------------------------

-- 1) Vértebra del Abismo (Maw02): columna curva de hueso fosilizado, quijada monstruosa abierta con colmillos
--    dorsales, corazón abisal carmesí enjaulado en costillas y vendas cosidas con runas (punta en z = 4.88)
D.AbyssVertebra = {
	palette = {
		Blade   = P(44, 40, 42, M.Slate),
		Bone    = P(198, 184, 158, M.Limestone),
		Bandage = P(146, 132, 110, M.Fabric),
		Grip    = P(122, 108, 90, M.Fabric),
		Accent  = P(58, 50, 48, M.Metal),
		Dark    = P(20, 16, 18, M.Metal),
		Glow    = P(235, 52, 46, M.Neon),
	},
	build = function(b, v)
		b.handle.Size = Vector3.new(0.26, 0.26, 1.40)
		b:wrap(-0.65, 0.65, 7, 0.31, "Bandage", 26)
		b:ball("ButtSkull", v(0, -0.78), 0.34, "Bone")
		b:point("ButtFang", v(0.08, -0.84), v(0.24, -1.18), 0.14, 0.10, "Bone")
		b:point("ButtFang", v(-0.08, -0.84), v(-0.24, -1.18), 0.14, 0.10, "Bone")

		-- Astil curvo de vértebras con nudos óseos y jirones de venda colgantes
		b:strip("SpineHaft", { { 0, 0.62 }, { -0.14, 1.35 }, { -0.06, 2.05 }, { 0.08, 2.75 } }, { 0.26, 0.28, 0.26, 0.28 }, 0.26, "Grip", 0)
		for _, z in { 0.95, 1.55, 2.15, 2.68 } do
			b:ball("VertebraNode", v(-0.06, z), 0.34, "Bone")
		end
		for i = 0, 2 do
			b:seg("TatteredBandage", v(-0.10, 1.15 + i * 0.48), v(-0.46 - i * 0.05, 0.96 + i * 0.42), 0.04, 0.11, "Bandage")
		end

		-- Núcleo abisal enjaulado entre costillas de hueso y cuchilla de mandíbula hacia +Y
		local head = b:add("JawCore", Vector3.new(0.26, 0.92, 1.85), CFrame.new(0, 0.28, 3.78) * CFrame.Angles(math.rad(-6), 0, 0), "Blade")
		b:ball("AbyssHeart", v(0.18, 3.68), 0.38, "Glow")
		for i = 0, 3 do
			local z = 3.12 + i * 0.42
			for _, s in { 1, -1 } do
				b:seg("RibCage", Vector3.new(0.16 * s, -0.10, z), Vector3.new(0.22 * s, 0.68, z + 0.14), 0.09, 0.12, "Bone")
			end
		end

		-- Quijada superior con colmillos curvos hacia adelante (+Y) y sierra dorsal (−Y)
		for i = 0, 4 do
			local z = 3.02 + i * 0.36
			b:point("MawFang", v(0.68, z), v(1.12, z - 0.10), 0.22, 0.14, "Bone")
			b:point("DorsalSpine", v(-0.18, z), v(-0.52, z - 0.14), 0.18, 0.12, "Bone")
		end
		b:point("ApexFang", v(0.32, 4.45), v(0.56, 4.88), 0.44, 0.18, "Bone")

		-- Vendas cruzadas y puntadas rúnicas carmesí
		for i = 0, 3 do
			local z = 3.10 + i * 0.38
			for _, x in { 0.14, -0.14 } do
				b:seg("MawWrap", v(-0.14, z, x), v(0.66, z + (i % 2 == 0 and 0.24 or -0.24), x), 0.04, 0.10, "Bandage")
			end
		end
		b:light(Vector3.new(0, 0.2, 3.75), rgb(235, 52, 46), 5, 0.55)
		return head, 3.78
	end,
}

-- 2) Fauces del Sepulcro (Maw03): maza pesada de doble quijada de bestia ancestral atada con hierro de verdugo
--    y vendas funerarias, con colmillos de marfil contrapuestos y remaches oscuros (punta en z = 4.88)
D.SepulcherJaws = {
	palette = {
		Blade   = P(56, 54, 58, M.Metal),
		Bone    = P(212, 198, 172, M.Limestone),
		Bandage = P(164, 148, 122, M.Fabric),
		Grip    = P(136, 120, 98, M.Fabric),
		Accent  = P(76, 70, 66, M.CorrodedMetal),
		Dark    = P(24, 22, 24, M.Metal),
		Glow    = P(228, 196, 128, M.Neon),
	},
	build = function(b, v)
		b.handle.Size = Vector3.new(0.26, 0.26, 1.40)
		b:wrap(-0.65, 0.65, 7, 0.31, "Bandage", 22)
		b:cyl("IronPommel", -0.78, 0.16, 0.38, "Accent")
		b:point("PommelClaw", v(0, -0.84), v(0, -1.22), 0.24, 0.18, "Bone")

		-- Mango curvo envuelto en tiras de mortaja y abrazaderas de hierro
		b:strip("Haft", { { 0, 0.62 }, { 0.10, 1.32 }, { 0.03, 2.02 }, { -0.05, 2.72 } }, { 0.26, 0.26, 0.25, 0.28 }, 0.26, "Grip", 0)
		for _, z in { 1.15, 1.85, 2.55 } do
			b:cyl("IronClamp", z, 0.10, 0.34, "Accent")
		end
		for i = 0, 2 do
			b:seg("ShroudTail", v(0.08, 1.30 + i * 0.45), v(0.44 + i * 0.05, 1.08 + i * 0.40), 0.04, 0.10, "Bandage")
		end

		-- Bloque central de hierro de verdugo con dos quijadas monstruosas opuestas (+Y y −Y)
		local head = b:add("IronBlock", Vector3.new(0.38, 0.76, 1.72), CFrame.new(0, 0, 3.76), "Blade")
		for _, s in { 1, -1 } do
			b:strip("BeastJaw", { { 0.26 * s, 2.96 }, { 0.58 * s, 3.45 }, { 0.72 * s, 4.05 }, { 0.48 * s, 4.58 } }, { 0.28, 0.36, 0.34, 0.22 }, 0.24, "Bone", 0.24)
			for i = 0, 3 do
				local z = 3.12 + i * 0.36
				b:point("JawTooth", v(0.68 * s, z), v(1.06 * s, z - 0.08), 0.20, 0.14, "Bone")
			end
			b:ball("EyeSocket", Vector3.new(0.20 * s, 0, 3.95), 0.18, "Glow")
		end

		-- Vendas funerarias cruzadas sobre el hierro y aguja de hueso en la cima
		for i = 0, 3 do
			local z = 3.12 + i * 0.38
			for _, x in { 0.20, -0.20 } do
				b:seg("CrossBandage", v(-0.46, z, x), v(0.46, z + (i % 2 == 0 and 0.26 or -0.26), x), 0.04, 0.11, "Bandage")
			end
		end
		b:point("CrownSpike", v(0, 4.46), v(0, 4.88), 0.34, 0.22, "Bone")
		return head, 3.76
	end,
}

-- 3) Corona de Osario (Maw04): cráneo de leviatán astado con aletas de costillas petrificadas,
--    quijada inferior dentada y fulgor espectral pálido (punta en z = 4.90)
D.OssuaryCrown = {
	palette = {
		Blade   = P(48, 52, 50, M.Slate),
		Bone    = P(204, 194, 174, M.Limestone),
		Bandage = P(148, 138, 118, M.Fabric),
		Grip    = P(54, 40, 32, M.Leather),
		Accent  = P(68, 72, 68, M.Metal),
		Dark    = P(18, 20, 18, M.Metal),
		Glow    = P(158, 232, 196, M.Neon),
	},
	build = function(b, v)
		b.handle.Size = Vector3.new(0.26, 0.26, 1.40)
		b:wrap(-0.65, 0.65, 7, 0.31, "Grip", 24)
		b:ball("BonePommel", v(0, -0.78), 0.34, "Bone")
		b:point("PommelSpike", v(0, -0.86), v(0, -1.24), 0.20, 0.20, "Bone")

		-- Astil de hierro y vértebras con vendas cruzadas en el cuello
		b:cyl("Haft", 1.88, 2.40, 0.24, "Accent")
		for _, z in { 1.05, 1.75, 2.45 } do
			b:ball("SpineRing", v(0, z), 0.34, "Bone")
		end
		b:wrap(2.55, 3.05, 4, 0.32, "Bandage", 28)

		-- Cráneo colosal en z = 3.78 con cuernos curvos y costillas radiales
		local head = b:add("SkullCore", Vector3.new(0.84, 0.96, 1.38), CFrame.new(0, 0, 3.78), "Bone")
		b:add("IronCrown", Vector3.new(0.90, 1.02, 0.22), CFrame.new(0, 0, 4.22), "Accent")
		for _, s in { 1, -1 } do
			b:ball("SpectralEye", Vector3.new(0.36 * s, 0.22, 4.02), 0.20, "Glow")
			-- Cuernos grandes curvados hacia arriba y afuera
			b:strip("LeviathanHorn", { { 0.28 * s, 4.18 }, { 0.68 * s, 4.36 }, { 0.96 * s, 4.62 }, { 0.84 * s, 4.88 } }, { 0.24, 0.20, 0.14, 0.08 }, 0.18, "Bone", 0.18)
			-- 4 costillas petrificadas que sobresalen como aletas de maza
			for i = 0, 3 do
				local z = 3.22 + i * 0.32
				b:point("PetrifiedRib", v(0.42 * s, z), v(1.04 * s, z - 0.06), 0.20, 0.14, "Bone")
			end
		end

		-- Corona de espinas óseas en el remate superior (z = 4.90)
		b:point("ApexCrown", v(0, 4.42), v(0, 4.90), 0.38, 0.26, "Bone")
		b:light(Vector3.new(0, 0, 3.85), rgb(158, 232, 196), 5, 0.5)
		return head, 3.78
	end,
}

----------------------------------------------------------------------
-- 0.2: Eclipse Carmesí (ruleta). 10/11/2026: el resto vuelve al diseño de la 0.1;
-- la versión "con rayos" quedó en SkinDesignsStorm como candidata a skin semanal.
----------------------------------------------------------------------
local Storm = require(script.Parent:WaitForChild("SkinDesignsStorm"))
for _, id in { "CrimsonEclipse", "BloodMoonCleaver", "CataclysmMaw", "EclipseFang", "EclipseNeedle" } do
	D[id] = Storm[id]
end

return D
