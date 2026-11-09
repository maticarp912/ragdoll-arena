-- ModuleScript: ServerScriptService/ArenaBuilder
-- Constructor radial, derrumbe por baldosas y segunda pasada de arte de las 4 variantes (Ronda 3B, Gemini):
--   1. Forest : Bosque oscuro original con lago de lava contenido, islas de basalto, cadenas y máscara de montañas/bosque 360°.
--   2. Canyon : Coliseo excavado en cañón (referencias\arena 2.jpg) con arco monolítico inferior, gradas talladas, estratos, toldos, púas metálicas y picos gemelos.
--   3. Temple : Sagrario egipcio/abisal (referencias\arena 3.jpg) con agua oscura reflectante, columnas con jeroglíficos dorados brillantes, capiteles de loto, cúpula artesonada y haz de luz desde el óculo.
--   4. Hand   : Mano colosal de piedra con musgo (referencias\mano como arena 4.jpg) que sostiene la plataforma desde abajo (antebrazo, palma, 4 dedos + pulgar articulados), cascadas y cabeza de estatua ancestral a un costado.

local RS = game:GetService("ReplicatedStorage")
local Collection = game:GetService("CollectionService")
local Config = require(RS:WaitForChild("ArenaConfig", 10))
local Theme = require(RS:WaitForChild("Theme", 10))
local N = Theme.Metrics
local Fx = require(script.Parent:WaitForChild("Fx", 10))

local Builder = {}
local registry = {}

local FloorColors = {
	Forest = { Color3.fromRGB(176, 182, 180), Color3.fromRGB(154, 160, 158), Color3.fromRGB(44, 36, 48) },
	Canyon = { Color3.fromRGB(204, 176, 144), Color3.fromRGB(182, 152, 122), Color3.fromRGB(116, 76, 54) },
	Temple = { Color3.fromRGB(202, 196, 180), Color3.fromRGB(180, 174, 158), Color3.fromRGB(64, 54, 42) },
	Hand   = { Color3.fromRGB(164, 172, 160), Color3.fromRGB(144, 152, 140), Color3.fromRGB(74, 82, 76) },
}

local function part(parent, name, size, cf, color, class, material)
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.Material = material or Theme.Arena.Material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

----------------------------------------------------------------------
-- 1. Variante BOSQUE (Original + máscara perimetral cerrada 360°)
----------------------------------------------------------------------
local function buildForest(scenery, mode, S, core)
	local R = mode.radius
	local c = mode.center
	local s = math.max(0.65, R / 100)

	local function at(radius, y, angle)
		return c + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
	end

	-- Lecho abisal y lago de lava contenido dentro de la caldera
	local lavaDiam = R * 5.2
	scenery("AbyssBed", Vector3.new(lavaDiam + 40, 6, lavaDiam + 40), CFrame.new(c - Vector3.yAxis * (S.AbyssDepth + 4)), Config.Basalt, "Part", Enum.Material.Basalt)
	local lava = scenery("VoidSurface", Vector3.new(lavaDiam, Config.LavaThickness, lavaDiam), CFrame.new(c - Vector3.yAxis * S.SurfaceDepth), Config.Lava, "Part", Enum.Material.Neon)
	lava.Transparency = 0.05

	-- Islas de corteza basáltica sobre la lava (desfasadas en Y para evitar parpadeo)
	local rng = Random.new(101)
	for i = 1, Config.CrustCount do
		local a = (i / Config.CrustCount) * math.pi * 2 + rng:NextNumber(-0.12, 0.12)
		local dist = R * (0.45 + rng:NextNumber() * 1.65)
		local w = Config.CrustSize * (0.7 + rng:NextNumber() * 0.8) * s
		local crust = scenery(
			"LavaCrust",
			Vector3.new(w, 3.2 + (i % 3) * 0.6, w * 0.85),
			CFrame.new(at(dist, -S.SurfaceDepth + 1.8 + (i % 4) * 0.12, a)) * CFrame.Angles(0, a * 1.7, 0),
			Config.Basalt,
			"Part",
			Enum.Material.Basalt
		)
		Collection:AddTag(crust, "FloatingRock")
	end

	-- Pilar central escalonado bajo el núcleo fijo
	for layer = 1, 4 do
		local frac = 1 - (layer - 1) * 0.18
		local h = Config.BaseDepth / 4
		local yOff = -Config.Thickness - (layer - 0.5) * h
		local cyl = scenery(
			"CoreRoot_" .. layer,
			Vector3.new(h, core * 2 * frac, core * 2 * frac),
			CFrame.new(c + Vector3.yAxis * yOff) * CFrame.Angles(0, 0, math.pi / 2),
			Config.Basalt,
			"Part",
			Enum.Material.Basalt
		)
		cyl.Shape = Enum.PartType.Cylinder
	end

	-- 4 Cadenas monumentales tensadas desde la base hacia la caldera
	for k = 1, Config.ChainCount do
		local a = (k - 0.5) * (math.pi * 2 / Config.ChainCount)
		local p0 = at(R * 0.72, -6, a)
		local p1 = at(R * 1.95, -S.SurfaceDepth + 4, a)
		local span = p1 - p0
		local dist = span.Magnitude
		local steps = 10
		for link = 1, steps do
			local t0 = (link - 1) / steps
			local t1 = link / steps
			local mid = p0 + span * ((t0 + t1) * 0.5)
			scenery(
				"AnchorChain",
				Vector3.new(2.2 * s, 2.2 * s, (dist / steps) * 1.08),
				CFrame.lookAt(mid, p1) * CFrame.Angles(0, 0, (link % 2) * (math.pi / 4)),
				Config.Chain,
				"Part",
				Enum.Material.CorrodedMetal
			)
		end
	end

	-- Anillo de bosque sombrío (fuera del radio de cámara R + 28) y raíces hacia el abismo
	local treeCount = S.Count
	for i = 1, treeCount do
		local angle = (i / treeCount) * math.pi * 2
		local treeR = R * 1.62 + (i % 3) * (8 * s)
		local basePos = at(treeR, -S.Depth + 12, angle)
		local trunkH = Config.TreeSize.Y * (0.95 + (i % 4) * 0.12)
		scenery(
			"ForestTrunk",
			Vector3.new(Config.TreeSize.X * s, trunkH, Config.TreeSize.Z * s),
			CFrame.new(basePos + Vector3.yAxis * (trunkH * 0.42)) * CFrame.Angles(0.04 * math.sin(i), -angle, 0.04 * math.cos(i)),
			Config.TreeColor,
			"Part",
			Enum.Material.Slate
		)
		local crown = scenery(
			"ForestCrown",
			Vector3.new(Config.TreeCrown.X * s, Config.TreeCrown.Y * 0.85, Config.TreeCrown.Z * s),
			CFrame.new(basePos + Vector3.yAxis * (trunkH * 0.82)),
			Config.TreeColor,
			"Part",
			Enum.Material.Grass
		)
		crown.Shape = Enum.PartType.Ball

		-- Raíces/espolones bajos hacia el abismo (siempre bajo y = -18)
		scenery(
			"VoidRoot",
			Vector3.new(S.SpikeSize.X * s, S.SpikeSize.Y, S.SpikeSize.Z * s),
			CFrame.new(at(R * 1.28, -S.HazardDepth, angle)) * CFrame.Angles(0.35, -angle, 0),
			Config.Basalt,
			"WedgePart",
			Enum.Material.Slate
		)
	end

	-- Rocas flotantes encantadas (animadas en el cliente por Arena.client.lua)
	for i = 1, Config.RockCount do
		local angle = (i / Config.RockCount) * math.pi * 2 + 0.25
		local rPos = at(R * 1.46, -18 + (i % 3) * 14, angle)
		local rock = scenery("FloatingBasalt", Config.RockSize * s, CFrame.new(rPos) * CFrame.Angles(0.2 * i, angle, 0.15 * i), Config.Basalt, "Part", Enum.Material.Basalt)
		Collection:AddTag(rock, "FloatingRock")
	end

	-- Máscara exterior 360° de montañas volcánicas y muralla de niebla (cierra toda vista exterior)
	local wallSegs = 24
	local wallR = R * 2.55
	local segWidth = (2 * math.pi * wallR / wallSegs) * 1.18
	for i = 1, wallSegs do
		local angle = (i / wallSegs) * math.pi * 2
		local peakH = 175 + (i % 3) * 28 + (i % 2) * 18
		local wPos = at(wallR, -S.AbyssDepth + peakH * 0.5, angle)
		scenery(
			"ForestMountainMask",
			Vector3.new(segWidth, peakH, 38 * s),
			CFrame.lookAt(wPos, Vector3.new(c.X, wPos.Y, c.Z)) * CFrame.Angles(0.08, 0, 0),
			Color3.fromRGB(16, 22, 30),
			"Part",
			Enum.Material.Slate
		)
		-- Cresta cónica superior para silueta natural de cordillera y pinos gigantes
		local crestPos = at(wallR - 6 * s, -S.AbyssDepth + peakH + 18, angle)
		scenery(
			"MountainCrest",
			Vector3.new(segWidth * 0.72, 48, 32 * s),
			CFrame.lookAt(crestPos, Vector3.new(c.X, crestPos.Y, c.Z)) * CFrame.Angles(0, 0, math.pi / 4),
			Color3.fromRGB(12, 18, 26),
			"WedgePart",
			Enum.Material.Slate
		)
	end

	-- 6 Braseros de basalto alrededor del borde de la plataforma (≤ 6 PointLight, sin sombras)
	for k = 1, 6 do
		local a = (k - 1) * (math.pi * 2 / 6)
		local pPos = at(R * 1.05, 0.4, a)
		scenery(
			"ForestBrazierBase",
			Vector3.new(3.8 * s, 4.2, 3.8 * s),
			CFrame.lookAt(pPos, Vector3.new(c.X, pPos.Y, c.Z)),
			Config.Basalt,
			"Part",
			Enum.Material.Basalt
		)
		local coals = scenery(
			"ForestBrazierCoals",
			Vector3.new(2.6 * s, 1.4, 2.6 * s),
			CFrame.new(pPos + Vector3.yAxis * 2.6),
			Color3.fromRGB(255, 135, 45),
			"Part",
			Enum.Material.Neon
		)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 165, 80)
		light.Brightness = 2.2
		light.Range = 38 * s
		light.Shadows = false
		light.Parent = coals
	end
end

----------------------------------------------------------------------
-- 2. Variante CAÑÓN (Coliseo excavado en cañón — referencias\arena 2.jpg)
----------------------------------------------------------------------
local function buildCanyon(scenery, mode, S, core)
	local R = mode.radius
	local c = mode.center
	local s = math.max(0.65, R / 100)

	local function at(radius, y, angle)
		return c + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
	end

	-- Suelo profundo del cañón con estratos rojizos y grieta abisal
	local floorSpan = R * 5.6
	scenery("CanyonAbyssFloor", Vector3.new(floorSpan, 6, floorSpan), CFrame.new(c - Vector3.yAxis * (S.AbyssDepth + 4)), S.SandDark, "Part", Enum.Material.Sandstone)
	scenery("VoidSurface", Vector3.new(floorSpan - 12, 3, floorSpan - 12), CFrame.new(c - Vector3.yAxis * S.SurfaceDepth), Color3.fromRGB(78, 50, 38), "Part", Enum.Material.Slate)

	-- Pedestal monolítico bajo la arena con el gran arco natural de roca de arena 2.jpg
	for tier = 1, 4 do
		local frac = 1.05 - (tier - 1) * 0.12
		local yOff = -Config.Thickness - (tier - 0.5) * 9
		local col = (tier % 2 == 0) and S.Sand or S.SandDark
		local cyl = scenery(
			"MonolithUnderTier_" .. tier,
			Vector3.new(8.5, core * 2.4 * frac, core * 2.4 * frac),
			CFrame.new(c + Vector3.yAxis * yOff) * CFrame.Angles(0, 0, math.pi / 2),
			col,
			"Part",
			Enum.Material.Sandstone
		)
		cyl.Shape = Enum.PartType.Cylinder
	end

	-- 4 Pilares de cañón masivos con arcos tallados que sostienen la meseta sobre el abismo
	for k = 1, 4 do
		local a = (k - 0.5) * (math.pi / 2)
		local pPos = at(R * 0.68, -36, a)
		scenery(
			"CanyonSupportPillar",
			Vector3.new(28 * s, 54, 24 * s),
			CFrame.lookAt(pPos, Vector3.new(c.X, pPos.Y, c.Z)),
			S.SandDark,
			"Part",
			Enum.Material.Sandstone
		)
		local archPos = at(R * 0.52, -16, a + math.pi / 4)
		scenery(
			"CanyonUnderArch",
			Vector3.new(34 * s, 12, 16 * s),
			CFrame.lookAt(archPos, Vector3.new(c.X, archPos.Y, c.Z)) * CFrame.Angles(0.18, 0, 0),
			S.Sand,
			"Part",
			Enum.Material.Sandstone
		)
	end

	-- Coliseo excavado en la roca: parapeto bajo + 5 gradas concéntricas + contrafuertes + púas + toldos
	local segs = 24
	for i = 1, segs do
		local angle = (i / segs) * math.pi * 2
		local lookCenter = function(pos)
			return CFrame.lookAt(pos, Vector3.new(c.X, pos.Y, c.Z))
		end

		-- Acantilado interior bajo el coliseo con estratos sedimentarios
		local cliffR = R * 1.42
		local cliffW = (2 * math.pi * cliffR / segs) * 1.06
		scenery("CanyonInnerCliff", Vector3.new(cliffW, 52, 14 * s), lookCenter(at(cliffR, -32, angle)), S.SandDark, "Part", Enum.Material.Sandstone)
		scenery("CanyonStrataBand", Vector3.new(cliffW + 0.4, 5, 15.2 * s), lookCenter(at(cliffR, -16 + (i % 2) * 0.2, angle)), S.SandLight, "Part", Enum.Material.Sandstone)

		-- Púas metálicas/óseas inferiores apuntando hacia el vacío del cañón
		scenery(
			"VoidSpike",
			Vector3.new(4.5 * s, 26 * s, 5.5 * s),
			lookCenter(at(R * 1.30, -24 - (i % 2) * 4, angle)) * CFrame.Angles(math.rad(58), 0, 0),
			S.IronDark,
			"WedgePart",
			Enum.Material.CorrodedMetal
		)

		-- 5 Gradas escalonadas del anfiteatro (empiezan en R * 1.48 y suben hacia R * 2.12)
		for tier = 1, S.Tiers do
			local tierR = R * (1.46 + (tier - 1) * 0.14)
			local tierY = -5 + (tier - 1) * 9.5 + (i % 2) * 0.08
			local tierW = (2 * math.pi * tierR / segs) * 1.05
			local tierCol = (tier % 3 == 1) and S.Sand or ((tier % 3 == 2) and S.SandLight or S.SandDark)
			scenery(
				"CanyonTerrace",
				Vector3.new(tierW, 8.8, 13 * s),
				lookCenter(at(tierR, tierY, angle)),
				tierCol,
				"Part",
				Enum.Material.Sandstone
			)
		end

		-- Contrafuertes radiales, braseros ardientes y grandes púas superiores apuntando a la arena
		if i % 2 == 0 then
			local buttressR = R * 2.16
			local bPos = at(buttressR, 26, angle)
			scenery("ColosseumButtress", Vector3.new(11 * s, 56, 18 * s), lookCenter(bPos), S.SandDark, "Part", Enum.Material.Sandstone)

			-- Gran púa metálica superior inclinada hacia la arena (como la corona dentada de arena 2.jpg)
			local spikePos = at(R * 1.96, 44, angle)
			scenery(
				"ColosseumRimSpike",
				Vector3.new(4.2 * s, 32 * s, 6.2 * s),
				lookCenter(spikePos) * CFrame.Angles(math.rad(-52), 0, 0),
				S.IronDark,
				"WedgePart",
				Enum.Material.CorrodedMetal
			)
			-- Diente secundario de arenisca clara junto a la púa
			local toothPos = at(R * 2.02, 47, angle + 0.06)
			scenery(
				"ColosseumRimTooth",
				Vector3.new(5.5 * s, 22 * s, 6 * s),
				lookCenter(toothPos) * CFrame.Angles(math.rad(-44), 0, 0),
				S.SandLight,
				"WedgePart",
				Enum.Material.Sandstone
			)
		end

		-- Toldos tensados del desierto entre los contrafuertes superiores y 6 braseros (≤ 6 PointLight, sin sombras)
		if i % 4 == 0 then
			local awningR = R * 2.04
			local awW = (2 * math.pi * awningR / (segs / 4)) * 0.68
			local aw = scenery(
				"CanyonAwning",
				Vector3.new(awW, 1.4, 20 * s),
				lookCenter(at(awningR, 49, angle)) * CFrame.Angles(math.rad(14), 0, 0),
				S.CanopyCloth,
				"Part",
				Enum.Material.Fabric
			)
			aw.Transparency = 0.06

			-- Brasero encendido en el balcón del coliseo iluminando la arena
			local brazierPos = at(R * 1.45, 2.5, angle)
			scenery("CanyonBrazierPedestal", Vector3.new(4.5 * s, 5, 4.5 * s), lookCenter(brazierPos), S.IronDark, "Part", Enum.Material.CorrodedMetal)
			local ember = scenery("CanyonBrazierFire", Vector3.new(3.2 * s, 1.6, 3.2 * s), CFrame.new(brazierPos + Vector3.yAxis * 3.1), Color3.fromRGB(255, 130, 42), "Part", Enum.Material.Neon)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 165, 80)
			light.Brightness = 2.2
			light.Range = 38 * s
			light.Shadows = false
			light.Parent = ember
		end

		-- Muralla exterior de cañón 360° con estratos y los dos Picos Gemelos monumentales de arena 2.jpg
		local outerR = R * 2.58
		local outerW = (2 * math.pi * outerR / segs) * 1.15
		local isTwinPeak = (i == 4 or i == 5 or i == 10 or i == 11 or i == 16 or i == 17 or i == 22 or i == 23)
		local wallH = isTwinPeak and 195 or 142
		local wallPos = at(outerR, -S.AbyssDepth + wallH * 0.5, angle)
		scenery("CanyonOuterWall", Vector3.new(outerW, wallH, 34 * s), lookCenter(wallPos), S.Sand, "Part", Enum.Material.Sandstone)
		scenery("CanyonOuterStrata1", Vector3.new(outerW + 0.6, 12, 35.5 * s), lookCenter(at(outerR, 28 + (i % 2) * 0.3, angle)), S.SandDark, "Part", Enum.Material.Sandstone)
		scenery("CanyonOuterStrata2", Vector3.new(outerW + 0.6, 10, 35.5 * s), lookCenter(at(outerR, 68 + (i % 2) * 0.3, angle)), S.SandLight, "Part", Enum.Material.Sandstone)
	end
end

----------------------------------------------------------------------
-- 3. Variante TEMPLO (Sagrario de columnas doradas y agua — referencias\arena 3.jpg)
----------------------------------------------------------------------
local function buildTemple(scenery, mode, S, core)
	local R = mode.radius
	local c = mode.center
	local s = math.max(0.65, R / 100)

	local function at(radius, y, angle)
		return c + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
	end

	-- Espejo de agua sagrada oscura con reflejos dorados y lecho profundo
	local waterSpan = R * 5.6
	local waterY = -44
	scenery("TempleDeepBasin", Vector3.new(waterSpan, 6, waterSpan), CFrame.new(c + Vector3.yAxis * (waterY - 7)), S.WaterDeep, "Part", Enum.Material.Slate)
	local waterSurface = scenery("VoidSurface", Vector3.new(waterSpan - 8, 2.4, waterSpan - 8), CFrame.new(c + Vector3.yAxis * waterY), S.Water, "Part", Enum.Material.Glass)
	waterSurface.Transparency = 0.22
	waterSurface.Reflectance = 0.35

	-- Escalinatas circulares sumergidas bajo el núcleo y anillo ritual dorado
	for stepIdx = 1, 3 do
		local stepR = core * (1.2 + stepIdx * 0.35)
		local cyl = scenery(
			"SubmergedAltarStep_" .. stepIdx,
			Vector3.new(10, stepR * 2, stepR * 2),
			CFrame.new(c + Vector3.yAxis * (-Config.Thickness - stepIdx * 8.5)) * CFrame.Angles(0, 0, math.pi / 2),
			stepIdx == 2 and S.GoldDark or S.TempleColumn,
			"Part",
			Enum.Material.Marble
		)
		cyl.Shape = Enum.PartType.Cylinder
	end

	-- 12 Columnas monumentales doradas (estilo arena 3.jpg) retiradas del borde para no tapar la cámara
	local colCount = 12
	local colR = R * 1.85
	local colH = 132
	local colDiam = 14 * s
	local colCenterY = waterY + colH * 0.5
	local wallR = R * 2.52

	for i = 1, colCount do
		local angle = (i / colCount) * math.pi * 2
		local colPos = at(colR, colCenterY, angle)
		local lookIn = CFrame.lookAt(colPos, Vector3.new(c.X, colPos.Y, c.Z))

		-- Basamento escalonado sobre el agua y reflejo dorado sutil en la superficie
		local basePos = at(colR, waterY + 3, angle)
		scenery("ColumnPlinth", Vector3.new(colDiam * 1.55, 6, colDiam * 1.55), CFrame.new(basePos) * CFrame.Angles(0, -angle, 0), S.TempleColumn, "Part", Enum.Material.Marble)
		scenery("ColumnGoldTrim", Vector3.new(colDiam * 1.38, 2.2, colDiam * 1.38), CFrame.new(basePos + Vector3.yAxis * 3.8) * CFrame.Angles(0, -angle, 0), S.Gold, "Part", Enum.Material.Metal)

		local reflPos = at(colR * 0.88, waterY + 1.35 + (i % 2) * 0.06, angle)
		local refl = scenery(
			"WaterGoldReflection",
			Vector3.new(colDiam * 0.95, 0.25, R * 0.36),
			CFrame.lookAt(reflPos, Vector3.new(c.X, reflPos.Y, c.Z)),
			S.Gold,
			"Part",
			Enum.Material.Glass
		)
		refl.Transparency = 0.82

		-- Fuste cilíndrico principal en bronce/obsidiana oscura
		local shaft = scenery(
			"TempleColumn",
			Vector3.new(colH, colDiam, colDiam),
			CFrame.new(colPos) * CFrame.Angles(0, 0, math.pi / 2),
			S.TempleColumn,
			"Part",
			Enum.Material.Slate
		)
		shaft.Shape = Enum.PartType.Cylinder

		-- 7 Anillos concéntricos de jeroglíficos dorados (oro cálido en Metal, sin neón verde)
		for ringIdx = 1, 7 do
			local ry = waterY + 14 + (ringIdx - 1) * 14.5
			local isFineAccent = (ringIdx == 4)
			local ringCyl = scenery(
				"HieroglyphRing",
				Vector3.new(isFineAccent and 0.6 or 2.4, colDiam + (isFineAccent and 0.6 or 0.4), colDiam + (isFineAccent and 0.6 or 0.4)),
				CFrame.new(at(colR, ry, angle)) * CFrame.Angles(0, 0, math.pi / 2),
				isFineAccent and S.GoldBright or S.Gold,
				"Part",
				isFineAccent and Enum.Material.Neon or Enum.Material.Metal
			)
			if isFineAccent then
				ringCyl.Transparency = 0.35
			end
			ringCyl.Shape = Enum.PartType.Cylinder
		end

		-- 6 Tiras verticales de jeroglíficos tallados en oro cálido hacia la arena (Metal/Foil)
		for strip = -2, 3 do
			local stripAngle = angle + strip * 0.045
			local stripPos = at(colR - colDiam * 0.49, colCenterY - 4, stripAngle)
			scenery(
				"CarvedGlyph",
				Vector3.new(0.6 * s, colH * 0.74, 0.6 * s),
				CFrame.lookAt(stripPos, Vector3.new(c.X, stripPos.Y, c.Z)),
				(strip % 2 == 0) and S.Gold or S.GoldDark,
				"Part",
				Enum.Material.Metal
			)
		end

		-- Capitel egipcio acampanado de 4 niveles concéntricos (Lotus Capital de arena 3.jpg)
		local capBaseY = waterY + colH - 12
		for tier = 1, 4 do
			local capD = colDiam * (1.15 + tier * 0.30)
			local capY = capBaseY + (tier - 1) * 3.2
			local capCyl = scenery(
				"LotusCapital_" .. tier,
				Vector3.new(3.0, capD, capD),
				CFrame.new(at(colR, capY, angle)) * CFrame.Angles(0, 0, math.pi / 2),
				(tier % 2 == 0) and S.Gold or S.GoldDark,
				"Part",
				Enum.Material.Metal
			)
			capCyl.Shape = Enum.PartType.Cylinder
		end
		-- Ábaco superior que recibe las vigas del techo
		scenery("CapitalAbacus", Vector3.new(colDiam * 1.8, 4, colDiam * 1.8), lookIn + Vector3.yAxis * (colH * 0.5 + 2), S.GoldDark, "Part", Enum.Material.Metal)

		-- Viga radial dorada desde la columna hacia el muro exterior (nunca sobre la plataforma)
		local beamMid = at(colR + (wallR - colR) * 0.5, waterY + colH + 4, angle)
		scenery(
			"CeilingRadialBeam",
			Vector3.new(7 * s, 5, (wallR - colR) * 1.05),
			CFrame.lookAt(beamMid, Vector3.new(c.X, beamMid.Y, c.Z)),
			S.GoldDark,
			"Part",
			Enum.Material.Metal
		)
	end

	-- Muro de cerramiento 360° del santuario + techo artesonado con Óculo
	local wallSegs = 24
	local ceilingY = waterY + colH + 6
	for i = 1, wallSegs do
		local angle = (i / wallSegs) * math.pi * 2
		local lookIn = function(pos)
			return CFrame.lookAt(pos, Vector3.new(c.X, pos.Y, c.Z))
		end

		-- Muro monumental que cierra por completo el horizonte
		local segW = (2 * math.pi * wallR / wallSegs) * 1.12
		local wPos = at(wallR, waterY + colH * 0.5, angle)
		scenery("TempleSanctuaryWall", Vector3.new(segW, colH + 18, 22 * s), lookIn(wPos), S.TempleWall, "Part", Enum.Material.Slate)

		-- Friso dorado superior e intermedio en el muro (Metal cálido)
		scenery("TempleWallFriezeTop", Vector3.new(segW + 0.4, 6, 24 * s), lookIn(at(wallR, ceilingY - 8 + (i % 2) * 0.15, angle)), S.GoldDark, "Part", Enum.Material.Metal)
		scenery("TempleWallFriezeMid", Vector3.new(segW * 0.72, 2.2, 23.5 * s), lookIn(at(wallR, 14, angle)), S.Gold, "Part", Enum.Material.Metal)

		-- Bóveda artesonada superior dejando libre el Óculo central (radio R * 0.44)
		local roofMidR = R * 1.48
		local roofW = (2 * math.pi * roofMidR / wallSegs) * 1.15
		scenery(
			"TempleCofferedRoof",
			Vector3.new(roofW, 6, R * 2.15),
			lookIn(at(roofMidR, ceilingY + 4 + (i % 2) * 0.18, angle)),
			S.TempleColumn,
			"Part",
			Enum.Material.Slate
		)
		-- Anillo dorado del Óculo sagrado
		local oculusR = R * 0.44
		local ocW = (2 * math.pi * oculusR / wallSegs) * 1.12
		scenery(
			"TempleOculusRing",
			Vector3.new(ocW, 8, 8 * s),
			lookIn(at(oculusR, ceilingY + 2, angle)),
			S.Gold,
			"Part",
			Enum.Material.Metal
		)
	end

	-- 6 Lámparas de altar doradas alrededor de la plataforma (≤ 6 PointLight, sin sombras)
	for k = 1, 6 do
		local a = (k - 1) * (math.pi * 2 / 6)
		local pPos = at(R * 1.05, 0.4, a)
		scenery(
			"TempleAltarStand",
			Vector3.new(3.6 * s, 4.4, 3.6 * s),
			CFrame.lookAt(pPos, Vector3.new(c.X, pPos.Y, c.Z)),
			S.GoldDark,
			"Part",
			Enum.Material.Metal
		)
		local flame = scenery(
			"TempleAltarFlame",
			Vector3.new(2.4 * s, 1.4, 2.4 * s),
			CFrame.new(pPos + Vector3.yAxis * 2.8),
			Color3.fromRGB(255, 195, 90),
			"Part",
			Enum.Material.Neon
		)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 205, 110)
		light.Brightness = 2.2
		light.Range = 38 * s
		light.Shadows = false
		light.Parent = flame
	end

	-- Haz de luz volumétrico (God-Ray) descendiendo desde el Óculo sobre el centro de la arena
	for cone = 1, 3 do
		local beamR = R * (0.20 + cone * 0.09)
		local beamH = ceilingY - 8
		local ray = scenery(
			"OculusSunbeam_" .. cone,
			Vector3.new(beamH, beamR * 2, beamR * 2),
			CFrame.new(c + Vector3.yAxis * (beamH * 0.5 + 4)) * CFrame.Angles(0, 0, math.pi / 2),
			S.Sunbeam,
			"Part",
			Enum.Material.Neon
		)
		ray.Shape = Enum.PartType.Cylinder
		ray.Transparency = 0.89 + cone * 0.03
		ray.CastShadow = false
	end
end

----------------------------------------------------------------------
-- 4. Variante MANO (Mano gigante de piedra con musgo y estatua — referencias\mano como arena 4.jpg)
----------------------------------------------------------------------
local function buildHand(scenery, mode, S, _)
	local R = mode.radius
	local c = mode.center
	local s = math.max(0.68, R / 100)

	local function at(radius, y, angle)
		return c + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
	end

	-- Cuenca de agua esmeralda/pizarra y niebla bajo la mano
	local basinSpan = R * 5.8
	scenery("SanctuaryBasinBed", Vector3.new(basinSpan, 6, basinSpan), CFrame.new(c - Vector3.yAxis * (S.AbyssDepth + 4)), S.StoneDark, "Part", Enum.Material.Slate)
	local water = scenery("VoidSurface", Vector3.new(basinSpan - 10, 3, basinSpan - 10), CFrame.new(c - Vector3.yAxis * S.SurfaceDepth), S.Water, "Part", Enum.Material.Glass)
	water.Transparency = 0.28

	------------------------------------------------------------------
	-- A. MANO GIGANTE DE PIEDRA CON MUSGO SOSTENIENDO LA PLATAFORMA
	------------------------------------------------------------------
	local handYaw = math.rad(110) -- La mano entra desde el arco posterior izquierdo
	local handOrigin = c + Vector3.new(0, -10, 0)
	local handCF = CFrame.new(handOrigin) * CFrame.Angles(0, handYaw, 0)

	-- 1. Antebrazo y muñeca emergiendo oblicuamente del abismo
	local forearmCF = handCF * CFrame.new(0, -42, R * 0.82) * CFrame.Angles(math.rad(-42), 0, 0)
	scenery("HandForearm", Vector3.new(46 * s, 96, 36 * s), forearmCF, S.Stone, "Part", Enum.Material.Slate)
	scenery("HandForearmBracelet", Vector3.new(50 * s, 10, 40 * s), forearmCF * CFrame.new(0, 18, 0), S.StoneDark, "Part", Enum.Material.Slate)
	scenery("HandForearmMoss", Vector3.new(44 * s, 28, 12 * s), forearmCF * CFrame.new(0, 22, -14 * s), S.Moss, "Part", Enum.Material.Grass)

	local wristCF = handCF * CFrame.new(0, -10, R * 0.48) * CFrame.Angles(math.rad(-14), 0, 0)
	local wrist = scenery("HandWrist", Vector3.new(44 * s, 58 * s, 54 * s), wristCF * CFrame.Angles(0, 0, math.pi / 2), S.Stone, "Part", Enum.Material.Slate)
	wrist.Shape = Enum.PartType.Cylinder

	-- 2. Palma anatómica esculpida justo debajo de la arena (nunca sobresale sobre el piso de juego)
	scenery("HandPalmCenter", Vector3.new(R * 1.48, 12, R * 1.42), handCF * CFrame.new(0, -4, 0), S.Stone, "Part", Enum.Material.Slate)
	scenery("HandPalmHeel", Vector3.new(R * 1.28, 15, R * 0.65), handCF * CFrame.new(0, -5.5, R * 0.42) * CFrame.Angles(math.rad(-8), 0, 0), S.StoneDark, "Part", Enum.Material.Slate)
	scenery("HandPalmThenar", Vector3.new(R * 0.68, 14, R * 0.78), handCF * CFrame.new(R * 0.56, -3.5, R * 0.22) * CFrame.Angles(0, 0, math.rad(10)), S.Stone, "Part", Enum.Material.Slate)
	scenery("HandPalmHypothenar", Vector3.new(R * 0.58, 13, R * 0.76), handCF * CFrame.new(-R * 0.58, -4.2, R * 0.16) * CFrame.Angles(0, 0, math.rad(-10)), S.Stone, "Part", Enum.Material.Slate)

	-- Manto de musgo vivo sobre el borde de la palma y chorros de agua cayendo entre los pliegues
	for m = -2, 2 do
		local mCF = handCF * CFrame.new(m * R * 0.28, 2.2 + (m % 2) * 0.15, -R * 0.62)
		scenery("PalmMossLedge", Vector3.new(R * 0.34, 3.2, R * 0.36), mCF, (m % 2 == 0) and S.Moss or S.MossBright, "Part", Enum.Material.Grass)
		if m ~= 0 then
			local stream = scenery(
				"Waterfall",
				Vector3.new(5.5 * s, 48, 2.2),
				mCF * CFrame.new(0, -24, -R * 0.22) * CFrame.Angles(math.rad(12), 0, 0),
				S.Waterfall,
				"Part",
				Enum.Material.Glass
			)
			stream.Transparency = 0.38
		end
	end

	-- 3. Cuatro dedos articulados (Índice, Medio, Anular, Meñique) que se curvan por el borde posterior
	--    Situados a radio >= R * 1.38 para no tapar nunca la cámara (CombatConfig.Camera = 15 studs)
	local fingerSpecs = {
		{ name = "Index",  ang = math.rad(72),  len = 0.92, thick = 1.00, tilt = math.rad(-8)  },
		{ name = "Middle", ang = math.rad(98),  len = 1.06, thick = 1.06, tilt = math.rad(-2)  },
		{ name = "Ring",   ang = math.rad(124), len = 0.95, thick = 0.98, tilt = math.rad(5)   },
		{ name = "Pinky",  ang = math.rad(148), len = 0.78, thick = 0.86, tilt = math.rad(12)  },
	}

	for idx, f in ipairs(fingerSpecs) do
		local basePos = at(R * 1.34, -10, f.ang)
		local outwardDir = Vector3.new(math.cos(f.ang), 0, math.sin(f.ang))
		local baseFrame = CFrame.lookAt(basePos, basePos + outwardDir) * CFrame.Angles(0, 0, f.tilt)

		local fw = 15.5 * s * f.thick
		local fd = 16.5 * s * f.thick
		local l1 = 26 * s * f.len
		local l2 = 22 * s * f.len
		local l3 = 17 * s * f.len

		-- Nudillo base (Metacarpofalángico)
		local k1 = scenery("KnuckleBase_" .. f.name, Vector3.new(fw * 1.12, fd * 1.08, fd * 1.12), baseFrame, S.StoneDark, "Part", Enum.Material.Slate)
		k1.Shape = Enum.PartType.Ball

		-- 1ª Falange (Proximal): sube y se abre hacia afuera
		local f1CF = baseFrame * CFrame.Angles(math.rad(36), 0, 0) * CFrame.new(0, 0, -l1 * 0.5)
		scenery("FingerProximal_" .. f.name, Vector3.new(fw, fd, l1), f1CF, S.Stone, "Part", Enum.Material.Slate)
		scenery("FingerMoss1_" .. f.name, Vector3.new(fw * 0.86, 2.4, l1 * 0.82), f1CF * CFrame.new(0, fd * 0.5 + 0.6, 0), S.Moss, "Part", Enum.Material.Grass)

		-- Nudillo medio
		local j2CF = f1CF * CFrame.new(0, 0, -l1 * 0.5)
		local k2 = scenery("KnuckleMid_" .. f.name, Vector3.new(fw * 1.04, fd * 1.02, fd * 1.04), j2CF, S.StoneDark, "Part", Enum.Material.Slate)
		k2.Shape = Enum.PartType.Ball

		-- 2ª Falange (Media): se curva hacia arriba como la palma entreabierta de mano como arena 4.jpg
		local f2CF = j2CF * CFrame.Angles(math.rad(32), 0, 0) * CFrame.new(0, 0, -l2 * 0.5)
		scenery("FingerMiddle_" .. f.name, Vector3.new(fw * 0.92, fd * 0.92, l2), f2CF, S.Stone, "Part", Enum.Material.Slate)
		scenery("FingerMoss2_" .. f.name, Vector3.new(fw * 0.76, 2.0, l2 * 0.75), f2CF * CFrame.new(0, fd * 0.46 + 0.5, 0), S.MossBright, "Part", Enum.Material.Grass)

		-- Nudillo distal
		local j3CF = f2CF * CFrame.new(0, 0, -l2 * 0.5)
		local k3 = scenery("KnuckleTip_" .. f.name, Vector3.new(fw * 0.90, fd * 0.90, fd * 0.90), j3CF, S.StoneDark, "Part", Enum.Material.Slate)
		k3.Shape = Enum.PartType.Ball

		-- 3ª Falange (Distal / Yema) + Uña esculpida en el dorso
		local f3CF = j3CF * CFrame.Angles(math.rad(24), 0, 0) * CFrame.new(0, 0, -l3 * 0.5)
		scenery("FingerDistal_" .. f.name, Vector3.new(fw * 0.82, fd * 0.80, l3), f3CF, S.StoneLight, "Part", Enum.Material.Slate)
		scenery("Fingernail_" .. f.name, Vector3.new(fw * 0.64, 1.4, l3 * 0.62), f3CF * CFrame.new(0, -fd * 0.38 - 0.4, -l3 * 0.12), S.StoneDark, "Part", Enum.Material.Slate)

		-- Cascada fina cayendo desde la comisura de cada dedo hacia el abismo
		if idx <= 3 then
			local wf = scenery(
				"Waterfall",
				Vector3.new(4.5 * s, 54, 1.8),
				j2CF * CFrame.new(0, -28, 0),
				S.Waterfall,
				"Part",
				Enum.Material.Glass
			)
			wf.Transparency = 0.42
		end
	end

	-- 4. Pulgar opuesto gigante de piedra (en el costado derecho/frontal de la palma)
	do
		local thumbAng = math.rad(28)
		local tBasePos = at(R * 1.34, -12, thumbAng)
		local tOut = Vector3.new(math.cos(thumbAng), 0, math.sin(thumbAng))
		local tFrame = CFrame.lookAt(tBasePos, tBasePos + tOut) * CFrame.Angles(0, math.rad(22), math.rad(-16))
		local tw, td = 18 * s, 18 * s

		local tk1 = scenery("ThumbKnuckleBase", Vector3.new(tw * 1.15, td * 1.15, td * 1.15), tFrame, S.StoneDark, "Part", Enum.Material.Slate)
		tk1.Shape = Enum.PartType.Ball

		local tf1 = tFrame * CFrame.Angles(math.rad(34), 0, 0) * CFrame.new(0, 0, -13 * s)
		scenery("ThumbProximal", Vector3.new(tw, td, 26 * s), tf1, S.Stone, "Part", Enum.Material.Slate)
		scenery("ThumbMoss", Vector3.new(tw * 0.85, 2.4, 20 * s), tf1 * CFrame.new(0, td * 0.5 + 0.6, 0), S.Moss, "Part", Enum.Material.Grass)

		local tj2 = tf1 * CFrame.new(0, 0, -13 * s)
		local tk2 = scenery("ThumbKnuckleTip", Vector3.new(tw * 0.96, td * 0.96, td * 0.96), tj2, S.StoneDark, "Part", Enum.Material.Slate)
		tk2.Shape = Enum.PartType.Ball

		local tf2 = tj2 * CFrame.Angles(math.rad(28), 0, 0) * CFrame.new(0, 0, -10 * s)
		scenery("ThumbDistal", Vector3.new(tw * 0.86, td * 0.82, 20 * s), tf2, S.StoneLight, "Part", Enum.Material.Slate)
		scenery("Thumbnail", Vector3.new(tw * 0.66, 1.4, 12 * s), tf2 * CFrame.new(0, -td * 0.38 - 0.4, -2 * s), S.StoneDark, "Part", Enum.Material.Slate)
	end

	------------------------------------------------------------------
	-- B. CABEZA Y BUSTO DE LA ESTATUA ANCESTRAL A UN COSTADO (mano como arena 4.jpg)
	------------------------------------------------------------------
	local statueAng = math.rad(-38)
	local headCenter = at(R * 1.82, 16, statueAng)
	local faceCF = CFrame.lookAt(headCenter, Vector3.new(c.X, headCenter.Y - 4, c.Z))

	-- Pedestal escalonado, hombros y cuello de piedra con musgo
	scenery("StatueBustPedestal", Vector3.new(84 * s, 56, 62 * s), faceCF * CFrame.new(0, -48, 4 * s), S.StoneDark, "Part", Enum.Material.Slate)
	scenery("StatueShoulders", Vector3.new(76 * s, 20, 52 * s), faceCF * CFrame.new(0, -22, 2 * s), S.Stone, "Part", Enum.Material.Slate)
	scenery("StatueShoulderMoss", Vector3.new(72 * s, 3.5, 48 * s), faceCF * CFrame.new(0, -11.2, 2 * s), S.Moss, "Part", Enum.Material.Grass)
	scenery("StatueNeck", Vector3.new(38 * s, 18, 36 * s), faceCF * CFrame.new(0, -10, 0), S.StoneDark, "Part", Enum.Material.Slate)

	-- Cráneo, pómulos, mandíbula y mentón esculpidos
	scenery("StatueCranium", Vector3.new(44 * s, 42 * s, 44 * s), faceCF * CFrame.new(0, 12 * s, 2 * s), S.Stone, "Part", Enum.Material.Slate)
	scenery("StatueJaw", Vector3.new(38 * s, 22 * s, 38 * s), faceCF * CFrame.new(0, -2 * s, -2 * s), S.Stone, "Part", Enum.Material.Slate)
	scenery("StatueChin", Vector3.new(22 * s, 10 * s, 14 * s), faceCF * CFrame.new(0, -9 * s, -16 * s), S.StoneLight, "Part", Enum.Material.Slate)

	-- Frente y musgo asimétrico sobre el rostro (como la referencia)
	scenery("StatueBrowRidge", Vector3.new(42 * s, 7 * s, 14 * s), faceCF * CFrame.new(0, 17 * s, -18 * s), S.StoneLight, "Part", Enum.Material.Slate)
	scenery("StatueFaceMossLeft", Vector3.new(18 * s, 24 * s, 8 * s), faceCF * CFrame.new(-13 * s, 8 * s, -19.5 * s), S.MossBright, "Part", Enum.Material.Grass)
	scenery("StatueBrowMoss", Vector3.new(34 * s, 4 * s, 12 * s), faceCF * CFrame.new(-4 * s, 20.8 * s, -17.5 * s), S.Moss, "Part", Enum.Material.Grass)

	-- Ojos entrecerrados serenos, puente nasal y labios tallados
	for _, sign in { -1, 1 } do
		scenery("StatueCheek", Vector3.new(15 * s, 16 * s, 14 * s), faceCF * CFrame.new(sign * 14 * s, 4 * s, -16 * s), S.Stone, "Part", Enum.Material.Slate)
		scenery("StatueEyeSocket", Vector3.new(12 * s, 5.5 * s, 6 * s), faceCF * CFrame.new(sign * 10.5 * s, 11.5 * s, -20.5 * s), S.StoneDark, "Part", Enum.Material.Slate)
		scenery("StatueEyelid", Vector3.new(11.5 * s, 3.2 * s, 6.5 * s), faceCF * CFrame.new(sign * 10.5 * s, 12.2 * s, -21.2 * s) * CFrame.Angles(math.rad(14), 0, 0), S.StoneLight, "Part", Enum.Material.Slate)
		-- Orejas alargadas con pendientes ancestrales
		scenery("StatueEar", Vector3.new(6 * s, 24 * s, 10 * s), faceCF * CFrame.new(sign * 23.5 * s, 6 * s, 0), S.StoneDark, "Part", Enum.Material.Slate)
	end

	scenery("StatueNoseBridge", Vector3.new(7.5 * s, 16 * s, 10 * s), faceCF * CFrame.new(0, 6.5 * s, -23 * s) * CFrame.Angles(math.rad(-14), 0, 0), S.StoneLight, "Part", Enum.Material.Slate)
	scenery("StatueNoseTip", Vector3.new(10.5 * s, 5.5 * s, 8 * s), faceCF * CFrame.new(0, 0.5 * s, -25.5 * s), S.Stone, "Part", Enum.Material.Slate)
	scenery("StatueUpperLip", Vector3.new(18 * s, 3.6 * s, 8 * s), faceCF * CFrame.new(0, -4.2 * s, -23.2 * s), S.StoneLight, "Part", Enum.Material.Slate)
	scenery("StatueLowerLip", Vector3.new(16 * s, 3.8 * s, 8 * s), faceCF * CFrame.new(0, -7.2 * s, -22.6 * s), S.Stone, "Part", Enum.Material.Slate)

	-- Diadema y corona escalonada tipo templo Khmer con musgo
	scenery("StatueDiadem", Vector3.new(48 * s, 8 * s, 48 * s), faceCF * CFrame.new(0, 25 * s, 2 * s), S.StoneDark, "Part", Enum.Material.Slate)
	scenery("StatueDiademMoss", Vector3.new(49 * s, 3.2 * s, 49 * s), faceCF * CFrame.new(0, 29.6 * s, 2 * s), S.Moss, "Part", Enum.Material.Grass)
	for tier = 1, 3 do
		local w = (40 - tier * 9) * s
		local yOff = (28 + tier * 10) * s
		scenery("StatueCrownTier_" .. tier, Vector3.new(w, 10 * s, w), faceCF * CFrame.new(0, yOff, 2 * s) * CFrame.Angles(0, tier * 0.4, 0), S.Stone, "Part", Enum.Material.Slate)
	end
	scenery("StatueCrownSpire", Vector3.new(10 * s, 22 * s, 10 * s), faceCF * CFrame.new(0, 66 * s, 2 * s), S.StoneLight, "Part", Enum.Material.Slate)

	------------------------------------------------------------------
	-- C. MÁSCARA DE ACANTILADOS SANTUARIO 360° Y GRANDES CASCADAS DETRÁS
	------------------------------------------------------------------
	local cliffSegs = 24
	local cliffR = R * 2.58
	for i = 1, cliffSegs do
		local angle = (i / cliffSegs) * math.pi * 2
		local lookIn = function(pos)
			return CFrame.lookAt(pos, Vector3.new(c.X, pos.Y, c.Z))
		end

		local segW = (2 * math.pi * cliffR / cliffSegs) * 1.15
		local h = 180 + (i % 3) * 20
		local cPos = at(cliffR, -S.AbyssDepth + h * 0.5, angle)
		scenery("SanctuaryCliffMask", Vector3.new(segW, h, 32 * s), lookIn(cPos), S.StoneDark, "Part", Enum.Material.Slate)
		scenery("SanctuaryCliffMoss", Vector3.new(segW * 0.88, 8, 34 * s), lookIn(at(cliffR, 38 + (i % 4) * 14, angle)), S.Moss, "Part", Enum.Material.Grass)

		-- Grandes cascadas blancas cayendo desde lo alto de los acantilados (ArenaBackdrop añade flujo de partículas)
		if i % 3 == 0 then
			local wfPos = at(cliffR - 18 * s, 22, angle)
			local wf = scenery(
				"Waterfall",
				Vector3.new(20 * s, 165, 3.5),
				lookIn(wfPos),
				S.Waterfall,
				"Part",
				Enum.Material.Glass
			)
			wf.Transparency = 0.32

			-- Anillo de espuma luminosa donde rompe la cascada en el agua
			local foamPos = at(cliffR - 20 * s, -S.SurfaceDepth + 1.8, angle)
			local foam = scenery(
				"WaterfallFoam",
				Vector3.new(28 * s, 1.4, 18 * s),
				lookIn(foamPos),
				S.Foam,
				"Part",
				Enum.Material.Neon
			)
			foam.Transparency = 0.45
		end
	end
end

----------------------------------------------------------------------
-- Constructor principal (conserva el contrato con MatchService)
----------------------------------------------------------------------
function Builder.build(parent, name, mode, variant)
	variant = variant or Config.Variants[N.One]
	local S = Config.Scenery
	local palette = FloorColors[variant] or FloorColors.Forest
	local floorCol, floorAltCol, rockCol = palette[1], palette[2], palette[3]

	local folder = Instance.new("Folder")
	folder.Name = "Arena_" .. name
	folder.Parent = parent
	folder:SetAttribute("Variant", variant)

	local arena = {
		folder = folder,
		tiles = {},
		byRing = {},
		maxRing = mode.rings,
		token = N.Zero,
		crumbling = false,
		mode = mode,
		variant = variant,
	}

	local core = mode.radius * Config.CoreFraction
	local disk = part(
		folder,
		"StableCore",
		Vector3.new(Config.Thickness, core * N.Two, core * N.Two),
		CFrame.new(mode.center) * CFrame.Angles(N.Zero, N.Zero, math.pi / N.Two),
		floorCol
	)
	disk.Shape = Enum.PartType.Cylinder

	local step = (mode.radius - core) / mode.rings
	local half = math.pi / mode.sectors

	for r = N.One, mode.rings do
		arena.byRing[r] = {}
		for sector = N.One, mode.sectors do
			local inner = core + (r - N.One) * step
			local outer = inner + step - Config.Gap
			local depth = outer - inner
			local wi = inner * math.tan(half) - Config.Gap
			local wo = outer * math.tan(half) - Config.Gap
			local cf = CFrame.new(mode.center) * CFrame.Angles(N.Zero, sector * half * N.Two, N.Zero) * CFrame.new(N.Zero, N.Zero, (inner + outer) / N.Two)
			local color = (sector % N.Two == N.Zero) and floorCol or floorAltCol

			local root = part(folder, "RadialSlab", Vector3.new(wi * N.Two, Config.Thickness, depth), cf, color)
			local pieces = { root }

			-- Dos cuñas completan los lados del trapecio con colisión real.
			for _, sign in { -N.One, N.One } do
				local sideCF = cf * CFrame.new(sign * (wi + (wo - wi) / N.Two), N.Zero, N.Zero)
				local axes = CFrame.fromMatrix(sideCF.Position, cf.UpVector * -sign, cf.RightVector * sign, cf.ZVector)
				local wedge = part(folder, "SlabEdge", Vector3.new(Config.Thickness - S.EdgeInset, wo - wi, depth), axes + Vector3.yAxis * S.EdgeInset / N.Two, color, "WedgePart")
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = wedge
				weld.Parent = root
				wedge.Anchored = false
				table.insert(pieces, wedge)
			end

			-- Basamento de roca individual adherido a cada baldosa (se desploma junto con ella).
			local supportDepth = S.SupportDepth * (arena.maxRing - r + N.One)
			local support = part(
				folder,
				"SlabRock",
				Vector3.new(wi * N.Two - S.EdgeInset, supportDepth, depth - S.EdgeInset),
				cf * CFrame.new(N.Zero, -Config.Thickness / N.Two - supportDepth / N.Two - S.EdgeInset, N.Zero),
				rockCol,
				"Part",
				Enum.Material.Slate
			)
			support.CanCollide = false
			support.CanTouch = false
			support.CanQuery = false
			support.Anchored = false
			local supportWeld = Instance.new("WeldConstraint")
			supportWeld.Part0 = root
			supportWeld.Part1 = support
			supportWeld.Parent = root
			table.insert(pieces, support)

			local tile = { part = root, cf = cf, color = color, ring = r, pieces = pieces, offsets = {}, falling = false }
			for _, p in pieces do
				tile.offsets[p] = cf:ToObjectSpace(p.CFrame)
			end
			table.insert(arena.tiles, tile)
			table.insert(arena.byRing[r], tile)
		end
	end

	-- Decoración monumental sin colisión ni consulta de raycast
	local decor = Instance.new("Folder")
	decor.Name = "Scenery"
	decor.Parent = folder

	local function scenery(pName, size, cf, color, class, material)
		local p = part(decor, pName, size, cf, color, class, material)
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		return p
	end

	if variant == "Canyon" then
		buildCanyon(scenery, mode, S, core)
	elseif variant == "Temple" then
		buildTemple(scenery, mode, S, core)
	elseif variant == "Hand" then
		buildHand(scenery, mode, S, core)
	else
		buildForest(scenery, mode, S, core)
	end

	local count = N.Zero
	for _, obj in folder:GetDescendants() do
		if obj:IsA("BasePart") then
			count += N.One
		end
	end
	assert(count <= S.Budget, "Arena part budget exceeded: " .. tostring(count))
	folder:SetAttribute("PartCount", count)
	registry[name] = arena
	return arena
end

function Builder.reset(arena)
	arena.token += N.One
	arena.crumbling = false
	for _, tile in arena.tiles do
		tile.part.Anchored = true
		tile.part.CFrame = tile.cf
		tile.part.AssemblyLinearVelocity = Vector3.zero
		tile.part.AssemblyAngularVelocity = Vector3.zero
		tile.falling = false
		for _, p in tile.pieces do
			p.CFrame = tile.cf * tile.offsets[p]
			p.Color = (p.Name == "SlabRock") and ((FloorColors[arena.variant] or FloorColors.Forest)[3]) or tile.color
			p.CanCollide = p.Name ~= "SlabRock"
			p.Parent = arena.folder
		end
	end
end

function Builder.crumble(arena, tile, token)
	if arena.token ~= token or tile.falling then return end
	tile.falling = true
	arena.crumbling = true
	local light = Instance.new("PointLight")
	light.Color = Theme.Arena.TileWarning
	light.Range = Config.WarningRange
	light.Brightness = Config.WarningLight
	light.Parent = tile.part

	local dust = Instance.new("ParticleEmitter")
	dust.Texture = Config.DustTexture
	dust.Rate = N.Zero
	dust.Parent = tile.part
	dust:Emit(Config.DustCount)

	Fx.sound("Tile_Warning", tile.part, Config.SoundVolume)
	for _, p in tile.pieces do
		p.Color = Theme.Arena.TileWarning
	end

	local finish = os.clock() + Config.WarningTime
	while os.clock() < finish and arena.token == token do
		tile.part.CFrame = tile.cf * CFrame.new((math.random() - N.Half) * Config.Tremor, N.Zero, (math.random() - N.Half) * Config.Tremor)
		task.wait(Config.WarningStep)
	end

	light:Destroy()
	dust:Destroy()
	if arena.token ~= token then return end

	Fx.sound(Config.CollapseSound, tile.part, Config.SoundVolume)
	tile.part.Anchored = false
	tile.part.AssemblyAngularVelocity = Config.Spin
	task.wait(Config.FallLife)
	if arena.token == token then
		for _, p in tile.pieces do
			p.Parent = nil
		end
	end
end

function Builder.run(arena, token)
	task.wait(arena.mode.crumbleStart)
	for r = arena.maxRing, N.One, -N.One do
		for _, tile in arena.byRing[r] do
			if arena.token ~= token then return end
			task.spawn(Builder.crumble, arena, tile, token)
			task.wait(arena.mode.crumbleInterval)
		end
	end
end

function Builder.debug(player, collapse)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or player:GetAttribute("InMatch") then return end
	local arena = registry["1v1"]
	if not arena then return end
	player:SetAttribute("PracticeOnly", true)
	if collapse then
		for r = arena.maxRing, N.One, -N.One do
			for _, tile in arena.byRing[r] do
				if not tile.falling then
					task.spawn(Builder.crumble, arena, tile, arena.token)
					return
				end
			end
		end
	else
		Builder.reset(arena)
		char:PivotTo(CFrame.new(arena.mode.center + Vector3.yAxis * Config.SpawnHeight))
	end
end

return Builder

