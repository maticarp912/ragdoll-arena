-- ModuleScript: ServerScriptService/LobbyBuilder
-- Ciudad del lobby: gótica victoriana de noche (referencias del usuario: calles empedradas entre
-- edificios altos con ventanas encendidas, faroles, torre del reloj, cementerio con ángel y una
-- gran puerta con gárgolas). La puerta lleva a la ANTESALA, donde dos círculos eligen 1v1 o 2v2.
-- Muros invisibles alrededor y siluetas de ciudad al fondo: no se ve el vacío ni la arena.
-- Datos en ReplicatedStorage/CityConfig.
--
-- LobbyBuilder.build(parent) -> { spawn, practiceCenter, dummyHomes, queueZones }
--   queueZones[modo] = { center = Vector3 (mundo), radius = número, label = TextLabel }

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage:WaitForChild("CityConfig"))

local LobbyBuilder = {}

local COL = Cfg.Colors
local C = Cfg.Center
local GROUND = C.Y + 1 -- cara superior del suelo
local M = Enum.Material

local rng = Random.new(Cfg.Seed)

local function at(x, y, z)
	return CFrame.new(C.X + x, GROUND + y, C.Z + z)
end

local function part(parent, name, size, cf, color, material, collide, class)
	local p = Instance.new(class or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = material or M.Slate
	p.CanCollide = collide == true
	p.CanQuery = collide == true
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function folderIn(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function inRect(r, x, z)
	return x >= r[1] and x <= r[2] and z >= r[3] and z <= r[4]
end

local function walkable(x, z)
	for _, r in Cfg.Walkable do
		if inRect(r, x, z) then return true end
	end
	return false
end

local function range(t)
	return t[1] + rng:NextNumber() * (t[2] - t[1])
end

local function light(parent, color, brightness, rangeValue, shadows)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = rangeValue
	l.Shadows = shadows == true
	l.Parent = parent
	return l
end

----------------------------------------------------------------------
-- Suelo, calles y bordillos
----------------------------------------------------------------------
local function ground(root)
	local f = folderIn(root, "Ground")
	part(f, "CityGround", Vector3.new(222, 2, 352), at(0, -1, 45), COL.Cobble, M.Cobblestone, true)
	-- Calles con otro tono y bordillos (se distinguen bordes y caminos)
	-- Las zonas se superponen (la plaza cruza las dos calles): cada una va en su propia capa de altura.
	-- Antes estaban todas a la misma altura y el piso parpadeaba (z-fighting) alrededor del ángel.
	local function street(r, color, material, layer)
		local w, d = r[2] - r[1], r[4] - r[3]
		local y = -0.05 + layer * Cfg.FloorLayerStep
		part(f, "Street", Vector3.new(w, 0.2, d), at((r[1] + r[2]) / 2, y, (r[3] + r[4]) / 2), color, material, false)
	end
	street(Cfg.Walkable.MainStreet, COL.Street, M.Cobblestone, 0)
	street(Cfg.Walkable.CrossStreet, COL.Street, M.Cobblestone, 1)
	street(Cfg.Walkable.Practice, COL.Plaza, M.Slate, 2)
	street(Cfg.Walkable.Antechamber, COL.Plaza, M.Slate, 1)
	street(Cfg.Walkable.Cemetery, COL.Grass, M.Grass, 2)
	street(Cfg.Walkable.Plaza, COL.Plaza, M.Slate, 3)
	-- Bordillos a lo largo de la calle principal (fuera de la plaza)
	for _, side in { -1, 1 } do
		for _, seg in { { -120, -70 }, { -10, 150 } } do
			local len = seg[2] - seg[1]
			part(f, "Curb", Vector3.new(0.8, 0.35, len), at(side * 11.5, 0.1, (seg[1] + seg[2]) / 2), COL.DarkStone, M.Concrete, false) -- 11.5: sin coincidir con el borde de la calle
		end
	end
end

----------------------------------------------------------------------
-- Edificios (Pueblo RPG Dark Fantasy: piedra en planta baja, entramado
-- de madera sobre revoque claro en planta alta, tejados a dos aguas
-- con aleros/buhardillas o torreones cónicos, balcones, postigos y maceteros)
----------------------------------------------------------------------
local B = Cfg.Building
local wallLightCount = 0

local function isFaceOpen(cx, cz, n)
	if walkable(cx + n.X * 3, cz + n.Z * 3) then
		return true
	end
	-- Borde norte de la plaza (entre z = -10 y z = -2 frente a la fuente y taberna)
	if cz == -2 and n.Z == -1 and math.abs(cx) < 36 then
		return true
	end
	return false
end

local function windowsOnFace(f, center, along, normal, faceWidth, height, style)
	style = style or {}
	local groundH = style.groundH or B.GroundFloorHeight or 8.2
	local jetty = style.jetty or B.JettyDepth or 0.65
	local timberCol = style.timberCol or (COL.Timber and COL.Timber[1]) or Color3.fromRGB(52, 36, 28)
	local shutterCol = style.shutterCol or (COL.Shutter and COL.Shutter[1]) or Color3.fromRGB(58, 42, 32)
	local plasterCol = style.plasterCol or (COL.Plaster and COL.Plaster[1]) or COL.Trim
	local roofCol = style.roofCol or COL.Roof
	local roofMat = style.roofMat or M.Slate
	local feature = style.feature or "shutters"

	local upperH = math.max(height - groundH, 7)
	local cols = math.clamp(math.floor((faceWidth - 2.6) / B.WindowSpacing), 1, 4)
	local rows = math.clamp(math.floor((upperH - 1.2) / B.FloorHeight), 1, 3)
	local size = B.WindowSize
	local colSpan = (faceWidth - 3.2) / math.max(cols, 1)
	local rowStep = (upperH - 1.4) / math.max(rows, 1)
	local baseCf = CFrame.lookAt(center, center + normal)

	-- 1. Entramado de madera (Half-timbering) en la planta alta sobre el voladizo
	local uDepth = jetty + 0.11
	-- Postes verticales de madera en esquinas y entre vanos
	for c = 0, cols do
		local xOff = (c - cols / 2) * colSpan
		local stud = part(f, "TimberStud", Vector3.new(0.36, upperH - 0.5, 0.22),
			baseCf * CFrame.new(xOff, groundH + upperH / 2, -uDepth), timberCol, M.Wood, false)
		stud.CastShadow = false
	end
	-- Vigas horizontales entre pisos superiores
	for r = 1, rows - 1 do
		local by = groundH + r * rowStep
		local belt = part(f, "TimberBelt", Vector3.new(faceWidth - 0.3, 0.38, 0.26),
			baseCf * CFrame.new(0, by, -(jetty + 0.14)), timberCol, M.Wood, false)
		belt.CastShadow = false
	end
	-- Riostras diagonales de madera en los extremos de la fachada alta
	if faceWidth >= 10 then
		local braceY = groundH + rowStep * 0.5
		local braceH = math.min(rowStep - 0.7, 5.8)
		for _, side in { -1, 1 } do
			local bx = side * (faceWidth * 0.5 - 1.35)
			local brace = part(f, "TimberBrace", Vector3.new(0.32, braceH, 0.18),
				baseCf * CFrame.new(bx, braceY, -(jetty + 0.09)) * CFrame.Angles(0, 0, math.rad(side * 28)),
				timberCol, M.Wood, false)
			brace.CastShadow = false
		end
	end
	-- Ménsulas (canecillos) sosteniendo el voladizo de la planta alta
	for _, side in { -1, 1 } do
		local corbel = part(f, "TimberCorbel", Vector3.new(0.45, 1.3, jetty + 0.25),
			baseCf * CFrame.new(side * (faceWidth * 0.36), groundH - 0.65, -(jetty * 0.5 + 0.08)),
			timberCol, M.Wood, false, "WedgePart")
		corbel.CastShadow = false
	end

	-- 2. Puerta con arco en la planta baja + farol de pared
	local doorX = 0
	if faceWidth >= 8 then
		if cols >= 3 and style.doorSide then
			doorX = style.doorSide * (colSpan * 0.5)
		end
		local doorW, doorH = 3.2, 5.2
		-- Escalón de piedra sobre la acera (por encima de todas las capas de suelo)
		part(f, "DoorStep", Vector3.new(doorW + 1.3, 0.32, 0.95),
			baseCf * CFrame.new(doorX, 0.42, -0.42), COL.Stone, M.Slate, false).CastShadow = false
		-- Jambas de piedra del arco
		part(f, "DoorArchFrame", Vector3.new(doorW + 0.76, doorH, 0.38),
			baseCf * CFrame.new(doorX, doorH / 2 + 0.3, -0.18), COL.DarkStone, M.Cobblestone, false).CastShadow = false
		-- Arco superior de piedra (cilindro)
		local archStone = part(f, "DoorArchTopStone", Vector3.new(0.40, doorW + 0.76, doorW + 0.76),
			baseCf * CFrame.new(doorX, doorH + 0.3, -0.19) * CFrame.Angles(0, math.rad(90), 0),
			COL.Trim, M.Concrete, false)
		archStone.Shape = Enum.PartType.Cylinder
		archStone.CastShadow = false
		-- Hoja de madera de la puerta y remate en arco
		part(f, "Door", Vector3.new(doorW, doorH - 0.1, 0.24),
			baseCf * CFrame.new(doorX, doorH / 2 + 0.3, -0.28), COL.DoorWood or Color3.fromRGB(50, 33, 24), M.WoodPlanks, false).CastShadow = false
		local archWood = part(f, "DoorArchWood", Vector3.new(0.26, doorW, doorW),
			baseCf * CFrame.new(doorX, doorH + 0.3, -0.29) * CFrame.Angles(0, math.rad(90), 0),
			COL.DoorWood or Color3.fromRGB(50, 33, 24), M.WoodPlanks, false)
		archWood.Shape = Enum.PartType.Cylinder
		archWood.CastShadow = false
		-- Herraje transversal de hierro
		part(f, "DoorStrap", Vector3.new(doorW - 0.3, 0.22, 0.08),
			baseCf * CFrame.new(doorX, 3.2, -0.43), COL.Iron, M.Metal, false).CastShadow = false

		-- Farol de pared cálido junto a la puerta
		if rng:NextNumber() < (B.LanternChance or 0.64) then
			local lSide = (doorX >= 0) and -1 or 1
			local lx = doorX + lSide * (doorW * 0.5 + 1.05)
			part(f, "WallBracket", Vector3.new(0.22, 0.28, 0.95),
				baseCf * CFrame.new(lx, 5.7, -0.48), COL.Iron, M.Metal, false).CastShadow = false
			local wLantern = part(f, "WallLantern", Vector3.new(0.62, 1.0, 0.62),
				baseCf * CFrame.new(lx, 5.1, -0.82), COL.Lamp, M.Neon, false)
			wLantern.CastShadow = false
			part(f, "WallLanternCap", Vector3.new(0.84, 0.22, 0.84),
				baseCf * CFrame.new(lx, 5.68, -0.82), COL.Iron, M.Metal, false).CastShadow = false
			if wallLightCount < (B.MaxWallLights or 10) and rng:NextNumber() < 0.28 then
				wallLightCount += 1
				light(wLantern, COL.Lamp, 1.25, 14, false)
			end
		end

		-- Ventana baja de taberna/taller al otro lado de la planta baja si la fachada es ancha
		if faceWidth >= 13.5 then
			local gx = (doorX <= 0) and (colSpan * 0.78) or (-colSpan * 0.78)
			if math.abs(gx - doorX) >= 3.6 then
				local gwLit = rng:NextNumber() < (B.LitChance + 0.12)
				local gw = part(f, gwLit and "LitWindow" or "Window", Vector3.new(size.X, size.Y * 0.82, 0.18),
					baseCf * CFrame.new(gx, 4.2, -0.14), gwLit and COL.Window or COL.WindowDark, gwLit and M.Neon or M.Glass, false)
				gw.CastShadow = false
				part(f, "Sill", Vector3.new(size.X + 0.55, 0.3, 0.42),
					baseCf * CFrame.new(gx, 4.2 - size.Y * 0.41 - 0.16, -0.22), COL.Trim, M.Concrete, false).CastShadow = false
			end
		end
	end

	-- 3. Ventanas de la planta alta con marco, alféizar, postigos y maceteros
	local flowerPalette = COL.PlanterFlowers or { Color3.fromRGB(148, 96, 178) }
	for r = 1, rows do
		local y = groundH + (r - 0.5) * rowStep + 0.15
		for c = 1, cols do
			local offset = (c - (cols + 1) / 2) * colSpan
			-- Si hay mirador/voladizo central en el primer piso alto, se construye aparte abajo
			local isOrielSlot = (feature == "oriel" and r == 1 and cols >= 2 and c == math.ceil(cols / 2))
			if not isOrielSlot then
				local wCf = baseCf * CFrame.new(offset, y, -(jetty + 0.09))
				local lit = rng:NextNumber() < B.LitChance
				local w = part(f, lit and "LitWindow" or "Window", Vector3.new(size.X, size.Y, 0.16), wCf,
					lit and COL.Window or COL.WindowDark, lit and M.Neon or M.Glass, false)
				w.CastShadow = false
				if not lit then w.Reflectance = 0.15 end

				-- Dintel superior y parteluz central de madera (marco de ventana sin solapar el vidrio)
				part(f, "WindowLintel", Vector3.new(size.X + 0.52, 0.26, 0.22),
					wCf * CFrame.new(0, size.Y / 2 + 0.14, -0.06), timberCol, M.Wood, false).CastShadow = false
				part(f, "WindowMullion", Vector3.new(0.16, size.Y, 0.14),
					wCf * CFrame.new(0, 0, -0.08), timberCol, M.Wood, false).CastShadow = false

				-- Alféizar (Sill)
				part(f, "Sill", Vector3.new(size.X + 0.62, 0.28, 0.44),
					wCf * CFrame.new(0, -size.Y / 2 - 0.15, -0.12), COL.Trim, M.Concrete, false).CastShadow = false

				-- Postigos de madera a ambos lados en parte de las ventanas
				if (feature == "shutters" or (r + c) % 2 == 0) and rng:NextNumber() < (B.ShutterChance or 0.58) then
					local shW = size.X * 0.36
					for _, sSide in { -1, 1 } do
						local sh = part(f, "Shutter", Vector3.new(shW, size.Y - 0.08, 0.12),
							wCf * CFrame.new(sSide * (size.X / 2 + shW * 0.5 + 0.06), 0, -0.07) * CFrame.Angles(0, math.rad(sSide * -12), 0),
							shutterCol, M.WoodPlanks, false)
						sh.CastShadow = false
					end
				end

				-- Maceteros con vegetación y flores nocturnas bajo el alféizar (piso 1 alto)
				if r == 1 and (feature == "planters" or rng:NextNumber() < (B.PlanterChance or 0.46)) then
					part(f, "PlanterBox", Vector3.new(size.X + 0.36, 0.42, 0.44),
						wCf * CFrame.new(0, -size.Y / 2 - 0.48, -0.18),
						COL.PlanterWood or timberCol, M.Wood, false).CastShadow = false
					local flCol = flowerPalette[rng:NextInteger(1, #flowerPalette)]
					part(f, "PlanterFoliage", Vector3.new(size.X + 0.24, 0.32, 0.38),
						wCf * CFrame.new(0, -size.Y / 2 - 0.16, -0.22),
						COL.PlanterFoliage or COL.Grass, M.Grass, false).CastShadow = false
					part(f, "PlanterBlossom", Vector3.new(size.X * 0.68, 0.24, 0.28),
						wCf * CFrame.new(0, -size.Y / 2 - 0.02, -0.26),
						flCol, M.SmoothPlastic, false).CastShadow = false
				end
			end
		end
	end

	-- 4. Balcón de madera y forja o mirador en voladizo (Oriel Bay Window)
	if feature == "balcony" and faceWidth >= 10.5 then
		local bw = math.min(faceWidth * 0.46, 6.8)
		local bd = 1.95
		local by = groundH + 0.18
		local bCf = baseCf * CFrame.new(0, by, -(jetty + bd * 0.5 + 0.06))
		part(f, "BalconyFloor", Vector3.new(bw, 0.34, bd), bCf, timberCol, M.WoodPlanks, false).CastShadow = false
		part(f, "BalconyRailFront", Vector3.new(bw, 1.75, 0.20),
			bCf * CFrame.new(0, 1.02, -bd * 0.5 + 0.12), COL.Iron, M.Metal, false).CastShadow = false
		for _, sSide in { -1, 1 } do
			part(f, "BalconyPost", Vector3.new(0.24, 1.85, bd),
				bCf * CFrame.new(sSide * (bw * 0.5 - 0.14), 1.05, 0), timberCol, M.Wood, false).CastShadow = false
		end
	elseif feature == "oriel" and cols >= 2 then
		local ox = (math.ceil(cols / 2) - (cols + 1) / 2) * colSpan
		local oy = groundH + rowStep * 0.52
		local ow, oh, od = 3.6, math.min(rowStep - 0.4, 6.4), 1.35
		local oCf = baseCf * CFrame.new(ox, oy, -(jetty + od * 0.5 + 0.05))
		part(f, "OrielBayBox", Vector3.new(ow, oh, od), oCf, plasterCol, M.Concrete, false).CastShadow = false
		part(f, "OrielSupport", Vector3.new(ow * 0.7, 1.2, od),
			oCf * CFrame.new(0, -oh * 0.5 - 0.55, 0.05), timberCol, M.Wood, false, "WedgePart").CastShadow = false
		part(f, "OrielRoof", Vector3.new(ow + 0.5, 1.2, od + 0.35),
			oCf * CFrame.new(0, oh * 0.5 + 0.55, -0.05), roofCol, roofMat, false, "WedgePart").CastShadow = false
		local oWin = part(f, "LitWindow", Vector3.new(ow - 0.9, oh - 1.4, 0.16),
			oCf * CFrame.new(0, 0.1, -od * 0.5 - 0.06), COL.Window, M.Neon, false)
		oWin.CastShadow = false
	end
end

local function building(f, x0, x1, z0, z1, h, style)
	style = style or {}
	local w, d = x1 - x0, z1 - z0
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2

	-- Detectar qué caras dan a calles o plazas caminables
	local faces = {
		{ n = Vector3.new(1, 0, 0), along = Vector3.zAxis, cx = x1, cz = cz, width = d },
		{ n = Vector3.new(-1, 0, 0), along = Vector3.zAxis, cx = x0, cz = cz, width = d },
		{ n = Vector3.new(0, 0, 1), along = Vector3.xAxis, cx = cx, cz = z1, width = w },
		{ n = Vector3.new(0, 0, -1), along = Vector3.xAxis, cx = cx, cz = z0, width = w },
	}
	local openFaces = {}
	local expX0, expX1, expZ0, expZ1 = -0.08, -0.08, -0.08, -0.08
	local jetty = style.jetty or B.JettyDepth or 0.65
	for _, face in faces do
		if isFaceOpen(face.cx, face.cz, face.n) then
			table.insert(openFaces, face)
			if face.n.X == 1 then expX1 = jetty
			elseif face.n.X == -1 then expX0 = jetty
			elseif face.n.Z == 1 then expZ1 = jetty
			elseif face.n.Z == -1 then expZ0 = jetty end
		end
	end

	local stoneCol = style.stoneCol or (COL.BaseStone and COL.BaseStone[rng:NextInteger(1, #COL.BaseStone)]) or COL.Stone
	local plasterCol = style.plasterCol or (COL.Plaster and COL.Plaster[rng:NextInteger(1, #COL.Plaster)]) or COL.Trim
	local timberCol = style.timberCol or (COL.Timber and COL.Timber[rng:NextInteger(1, #COL.Timber)]) or Color3.fromRGB(52, 36, 28)
	local roofCol = style.roofCol or (COL.RoofTiles and COL.RoofTiles[rng:NextInteger(1, #COL.RoofTiles)]) or COL.Roof
	local roofMat = style.roofMat or (rng:NextNumber() < 0.68 and M.Slate or M.WoodPlanks)
	local groundH = style.groundH or (B.GroundFloorHeight or 8.2)
	local upperH = math.max(h - groundH, 6)

	-- 1. Planta baja de mampostería de piedra (ligeramente remetida en medianeras para evitar caras coplanares)
	local bw, bd = w - 0.12, d - 0.12
	part(f, "BuildingBase", Vector3.new(bw, groundH, bd), at(cx, groundH / 2, cz), stoneCol, M.Cobblestone, true)
	local plinthH = 1.05 + (style.plinthOff or 0)
	part(f, "Plinth", Vector3.new(bw + 0.44, plinthH, bd + 0.44), at(cx, plinthH / 2 + 0.08, cz), COL.DarkStone, M.Slate, false)

	-- 2. Planta alta de revoque claro con voladizo hacia la calle y cinturón de madera
	local ux0, ux1 = x0 - expX0, x1 + expX1
	local uz0, uz1 = z0 - expZ0, z1 + expZ1
	local uw, ud = ux1 - ux0, uz1 - uz0
	local ucx, ucz = (ux0 + ux1) / 2, (uz0 + uz1) / 2

	part(f, "JettyBeam", Vector3.new(uw + 0.28, 0.52, ud + 0.28), at(ucx, groundH, ucz), timberCol, M.Wood, false)
	part(f, "BuildingUpper", Vector3.new(uw, upperH, ud), at(ucx, groundH + upperH / 2, ucz), plasterCol, M.Concrete, true)
	part(f, "Cornice", Vector3.new(uw + 0.56, 0.65, ud + 0.56), at(ucx, h + 0.2, ucz), timberCol, M.Wood, false)

	-- 3. Tejados con forma: a dos aguas con aleros/hastial, con buhardillas, o torreón cónico
	local top = h + 0.52
	local ov = B.EaveOverhang or 1.35
	local roofType = style.roofType or "GableStreet"
	local primaryFace = openFaces[1]

	-- Determinar dirección de la cumbrera:
	-- En "GableStreet" la cumbrera es perpendicular a la calle principal para que el hastial triangular mire a la calle.
	local ridgeAlongZ = (d >= w)
	if primaryFace then
		if roofType == "GableStreet" then
			ridgeAlongZ = (primaryFace.n.Z ~= 0)
		else
			ridgeAlongZ = (primaryFace.n.X ~= 0)
		end
	end

	local span = ridgeAlongZ and uw or ud
	local pitchFactor = (roofType == "GableStreet") and 0.56 or 0.48
	local rh = math.clamp(span * pitchFactor, 6.5, 13.5)
	local rw, rd = uw + ov * 2, ud + ov * 2

	if ridgeAlongZ then
		-- Faldones del tejado con alero sobresaliente
		part(f, "Roof", Vector3.new(rd, rh, rw / 2),
			at(ucx - rw / 4, top + rh / 2, ucz) * CFrame.Angles(0, math.rad(90), 0), roofCol, roofMat, false, "WedgePart")
		part(f, "Roof", Vector3.new(rd, rh, rw / 2),
			at(ucx + rw / 4, top + rh / 2, ucz) * CFrame.Angles(0, math.rad(-90), 0), roofCol, roofMat, false, "WedgePart")
		-- Hastial triangular de revoque claro bajo el alero
		part(f, "GableWall", Vector3.new(ud - 0.1, rh - 0.35, uw / 2 - 0.1),
			at(ucx - uw / 4, top + (rh - 0.35) / 2, ucz) * CFrame.Angles(0, math.rad(90), 0), plasterCol, M.Concrete, false, "WedgePart")
		part(f, "GableWall", Vector3.new(ud - 0.1, rh - 0.35, uw / 2 - 0.1),
			at(ucx + uw / 4, top + (rh - 0.35) / 2, ucz) * CFrame.Angles(0, math.rad(-90), 0), plasterCol, M.Concrete, false, "WedgePart")
		-- Viga de cumbrera
		part(f, "RidgeBeam", Vector3.new(0.62, 0.62, rd + 0.4), at(ucx, top + rh, ucz), timberCol, M.Wood, false).CastShadow = false
		-- Óculo/ventana de buhardilla en el hastial si mira a la calle
		if primaryFace and primaryFace.n.Z ~= 0 and rh >= 7.2 then
			local gz = ucz + primaryFace.n.Z * (ud * 0.5 + 0.08)
			local oculus = part(f, "GableOculus", Vector3.new(0.24, 2.3, 2.3),
				at(ucx, top + rh * 0.42, gz) * CFrame.Angles(0, math.rad(90), 0), COL.Window, M.Neon, false)
			oculus.Shape = Enum.PartType.Cylinder
			oculus.CastShadow = false
			local ocRing = part(f, "GableOculusFrame", Vector3.new(0.18, 2.75, 2.75),
				at(ucx, top + rh * 0.42, gz + primaryFace.n.Z * 0.05) * CFrame.Angles(0, math.rad(90), 0), timberCol, M.Wood, false)
			ocRing.Shape = Enum.PartType.Cylinder
			ocRing.CastShadow = false
		end
	else
		-- Faldones del tejado con alero sobresaliente (cumbrera en X)
		part(f, "Roof", Vector3.new(rw, rh, rd / 2),
			at(ucx, top + rh / 2, ucz - rd / 4), roofCol, roofMat, false, "WedgePart")
		part(f, "Roof", Vector3.new(rw, rh, rd / 2),
			at(ucx, top + rh / 2, ucz + rd / 4) * CFrame.Angles(0, math.pi, 0), roofCol, roofMat, false, "WedgePart")
		-- Hastial triangular de revoque claro bajo el alero
		part(f, "GableWall", Vector3.new(uw - 0.1, rh - 0.35, ud / 2 - 0.1),
			at(ucx, top + (rh - 0.35) / 2, ucz - ud / 4), plasterCol, M.Concrete, false, "WedgePart")
		part(f, "GableWall", Vector3.new(uw - 0.1, rh - 0.35, ud / 2 - 0.1),
			at(ucx, top + (rh - 0.35) / 2, ucz + ud / 4) * CFrame.Angles(0, math.pi, 0), plasterCol, M.Concrete, false, "WedgePart")
		-- Viga de cumbrera
		part(f, "RidgeBeam", Vector3.new(rw + 0.4, 0.62, 0.62), at(ucx, top + rh, ucz), timberCol, M.Wood, false).CastShadow = false
		-- Óculo en el hastial si mira a la calle
		if primaryFace and primaryFace.n.X ~= 0 and rh >= 7.2 then
			local gx = ucx + primaryFace.n.X * (uw * 0.5 + 0.08)
			local oculus = part(f, "GableOculus", Vector3.new(0.24, 2.3, 2.3),
				at(gx, top + rh * 0.42, ucz), COL.Window, M.Neon, false)
			oculus.Shape = Enum.PartType.Cylinder
			oculus.CastShadow = false
			local ocRing = part(f, "GableOculusFrame", Vector3.new(0.18, 2.75, 2.75),
				at(gx + primaryFace.n.X * 0.05, top + rh * 0.42, ucz), timberCol, M.Wood, false)
			ocRing.Shape = Enum.PartType.Cylinder
			ocRing.CastShadow = false
		end
	end

	-- 4. Buhardilla (Dormer) sobre el faldón del tejado que mira a la calle
	if primaryFace and (roofType == "SideRidgeDormer" or rng:NextNumber() < (B.DormerChance or 0.52)) then
		local slopeFacesStreet = (ridgeAlongZ and primaryFace.n.X ~= 0) or (not ridgeAlongZ and primaryFace.n.Z ~= 0)
		if slopeFacesStreet then
			local dDist = (ridgeAlongZ and (uw * 0.28) or (ud * 0.28))
			local dPos = Vector3.new(C.X + ucx, GROUND + top + rh * 0.36, C.Z + ucz) + primaryFace.n * dDist
			local dCf = CFrame.lookAt(dPos, dPos + primaryFace.n)
			part(f, "DormerBox", Vector3.new(3.2, 3.0, 3.2), dCf, plasterCol, M.Concrete, false).CastShadow = false
			part(f, "DormerTrim", Vector3.new(3.5, 0.32, 3.4), dCf * CFrame.new(0, 1.55, -0.05), timberCol, M.Wood, false).CastShadow = false
			part(f, "DormerRoofL", Vector3.new(3.6, 1.5, 1.85),
				dCf * CFrame.new(-0.925, 2.3, -0.05) * CFrame.Angles(0, math.rad(90), 0), roofCol, roofMat, false, "WedgePart").CastShadow = false
			part(f, "DormerRoofR", Vector3.new(3.6, 1.5, 1.85),
				dCf * CFrame.new(0.925, 2.3, -0.05) * CFrame.Angles(0, math.rad(-90), 0), roofCol, roofMat, false, "WedgePart").CastShadow = false
			local dw = part(f, "LitWindow", Vector3.new(1.5, 1.85, 0.16),
				dCf * CFrame.new(0, 0.05, -1.62), COL.Window, M.Neon, false)
			dw.CastShadow = false
		end
	end

	-- 5. Torreón circular con tejado cónico de bruja/mago (como en 02_lobby_pueblo_noche.webp)
	if roofType == "ConicalTurret" and primaryFace then
		local tr = math.clamp(math.min(w, d) * 0.32, 3.8, 5.2)
		local th = h + 6.5
		local tShift = primaryFace.along * ((primaryFace.width * 0.5) - tr * 0.85)
		local tWorld = Vector3.new(C.X + primaryFace.cx, GROUND, C.Z + primaryFace.cz) + tShift - primaryFace.n * (tr * 0.35)
		local tx, tz = tWorld.X - C.X, tWorld.Z - C.Z

		local tBase = part(f, "TurretBase", Vector3.new(groundH + 1.5, tr * 2.08, tr * 2.08),
			at(tx, (groundH + 1.5) / 2, tz) * CFrame.Angles(0, 0, math.rad(90)), stoneCol, M.Cobblestone, true)
		tBase.Shape = Enum.PartType.Cylinder
		local tShaftH = th - groundH - 1.5
		local tShaft = part(f, "TurretShaft", Vector3.new(tShaftH, tr * 1.98, tr * 1.98),
			at(tx, groundH + 1.5 + tShaftH / 2, tz) * CFrame.Angles(0, 0, math.rad(90)), plasterCol, M.Concrete, true)
		tShaft.Shape = Enum.PartType.Cylinder
		local tBelt = part(f, "TurretBelt", Vector3.new(0.75, tr * 2.24, tr * 2.24),
			at(tx, th - 0.2, tz) * CFrame.Angles(0, 0, math.rad(90)), timberCol, M.Wood, false)
		tBelt.Shape = Enum.PartType.Cylinder
		tBelt.CastShadow = false

		-- Ventana encendida del torreón mirando a la calle
		local twPos = Vector3.new(C.X + tx, GROUND + th - 3.4, C.Z + tz) + primaryFace.n * (tr * 0.96)
		local tw = part(f, "LitWindow", Vector3.new(1.5, 2.5, 0.24),
			CFrame.lookAt(twPos, twPos + primaryFace.n), COL.Window, M.Neon, false)
		tw.CastShadow = false

		-- Tejado cónico escalonado + aguja piramidal aguda
		local coneH = tr * 2.9
		for tier = 1, 3 do
			local frac = (tier - 1) / 3
			local tierR = tr * (1.28 - frac * 0.58)
			local tierH = coneH * 0.22
			local tierY = th + frac * (coneH * 0.55) + tierH / 2
			local cPart = part(f, "TurretConeTier", Vector3.new(tierH, tierR * 2, tierR * 2),
				at(tx, tierY, tz) * CFrame.Angles(0, 0, math.rad(90)), roofCol, roofMat, false)
			cPart.Shape = Enum.PartType.Cylinder
			cPart.CastShadow = false
		end
		local spireBaseY = th + coneH * 0.35
		local spireH = coneH * 0.72
		local spireW = tr * 1.35
		part(f, "TurretSpire", Vector3.new(spireW, spireH, spireW / 2),
			at(tx, spireBaseY + spireH / 2, tz - spireW / 4), roofCol, roofMat, false, "WedgePart").CastShadow = false
		part(f, "TurretSpire", Vector3.new(spireW, spireH, spireW / 2),
			at(tx, spireBaseY + spireH / 2, tz + spireW / 4) * CFrame.Angles(0, math.pi, 0), roofCol, roofMat, false, "WedgePart").CastShadow = false
		part(f, "TurretFinial", Vector3.new(0.35, 3.4, 0.35), at(tx, spireBaseY + spireH + 1.5, tz), COL.Iron, M.Metal, false).CastShadow = false
	end

	-- 6. Chimenea de ladrillo/piedra con remate y humo nocturno
	if #openFaces > 0 and rng:NextNumber() < B.ChimneyChance then
		local px = ucx + (rng:NextNumber() - 0.5) * uw * 0.48
		local pz = ucz + (rng:NextNumber() - 0.5) * ud * 0.48
		local chY = top + rh * 0.55
		local chCol = COL.Bricks[rng:NextInteger(1, #COL.Bricks)]
		local ch = part(f, "Chimney", Vector3.new(1.9, 6.2, 1.9), at(px, chY + 2.2, pz), chCol, M.Brick, false)
		part(f, "ChimneyCap", Vector3.new(2.4, 0.45, 2.4), at(px, chY + 5.4, pz), COL.DarkStone, M.Slate, false).CastShadow = false
		if rng:NextNumber() < 0.45 then
			local smoke = Instance.new("ParticleEmitter")
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(Color3.fromRGB(70, 72, 80))
			smoke.Transparency = NumberSequence.new(0.62, 1)
			smoke.Size = NumberSequence.new(2, 6.5)
			smoke.Lifetime = NumberRange.new(4, 6.5)
			smoke.Rate = 2
			smoke.Speed = NumberRange.new(2, 3.8)
			smoke.Acceleration = Vector3.new(1.4, 0.5, 0)
			smoke.Parent = ch
		end
	end

	-- 7. Fachadas detalladas solo en las caras que dan a una calle o plaza
	for idx, face in openFaces do
		local center = Vector3.new(C.X + face.cx, GROUND, C.Z + face.cz)
		local faceStyle = {
			groundH = groundH,
			jetty = jetty,
			timberCol = timberCol,
			shutterCol = style.shutterCol,
			plasterCol = plasterCol,
			roofCol = roofCol,
			roofMat = roofMat,
			feature = (idx == 1) and style.feature or "shutters",
			doorSide = style.doorSide,
		}
		windowsOnFace(f, center, face.along, face.n, math.min(face.width, 32), h, faceStyle)
	end
end

-- Llena una manzana garantizando que nunca haya dos fachadas seguidas iguales
local ROOF_ARCHETYPES = { "GableStreet", "SideRidgeDormer", "GableStreet", "ConicalTurret" }
local FACADE_FEATURES = { "balcony", "shutters", "oriel", "planters" }
local HEIGHT_TIERS = {
	{ 21, 25.5 }, -- Casa baja de 2 plantas
	{ 27.5, 32.5 }, -- Casa media de 3 plantas
	{ 34.5, 41.5 }, -- Mansión/posada alta
}

local function fillStrip(f, x0, x1, z0, z1)
	local alongX = (x1 - x0) >= (z1 - z0)
	local a0, a1 = alongX and x0 or z0, alongX and x1 or z1
	local pos = a0
	local idx = 0
	local prevPlaster, prevRoof, prevStone, prevTier = 0, 0, 0, 0
	local wideLot = (rng:NextNumber() < 0.5)

	while pos < a1 - 0.5 do
		idx += 1
		wideLot = not wideLot
		local minW = wideLot and 16.0 or B.Width[1]
		local maxW = wideLot and B.Width[2] or 15.4
		local w = math.min(minW + rng:NextNumber() * (maxW - minW), a1 - pos)
		if a1 - (pos + w) < 10.5 then
			w = a1 - pos
		end

		-- Altura en escalones para evitar dos edificios contiguos de igual altura
		local tier = (prevTier % #HEIGHT_TIERS) + 1
		if rng:NextNumber() < 0.45 then
			tier = ((prevTier + 1) % #HEIGHT_TIERS) + 1
		end
		prevTier = tier
		local h = range(HEIGHT_TIERS[tier])

		-- Colores distintos al vecino inmediato
		local pCount = #(COL.Plaster or { COL.Trim })
		local plasterIdx = (prevPlaster % pCount) + 1 + rng:NextInteger(0, math.max(pCount - 2, 0))
		plasterIdx = ((plasterIdx - 1) % pCount) + 1
		prevPlaster = plasterIdx

		local rCount = #(COL.RoofTiles or { COL.Roof })
		local roofIdx = ((prevRoof + rng:NextInteger(0, math.max(rCount - 2, 0))) % rCount) + 1
		prevRoof = roofIdx

		local sCount = #(COL.BaseStone or { COL.Stone })
		local stoneIdx = ((prevStone + rng:NextInteger(0, math.max(sCount - 2, 0))) % sCount) + 1
		prevStone = stoneIdx

		local roofType = ROOF_ARCHETYPES[((idx - 1) % #ROOF_ARCHETYPES) + 1]
		local feature = FACADE_FEATURES[((idx + rng:NextInteger(0, 1)) % #FACADE_FEATURES) + 1]
		local shCount = #(COL.Shutter or { COL.Roof })

		local style = {
			plasterCol = COL.Plaster and COL.Plaster[plasterIdx] or COL.Trim,
			roofCol = COL.RoofTiles and COL.RoofTiles[roofIdx] or COL.Roof,
			stoneCol = COL.BaseStone and COL.BaseStone[stoneIdx] or COL.Stone,
			timberCol = COL.Timber and COL.Timber[((idx - 1) % #COL.Timber) + 1] or Color3.fromRGB(52, 36, 28),
			shutterCol = COL.Shutter and COL.Shutter[((idx - 1) % shCount) + 1] or Color3.fromRGB(58, 42, 32),
			roofMat = (idx % 3 == 0) and M.WoodPlanks or M.Slate,
			roofType = roofType,
			feature = feature,
			groundH = (B.GroundFloorHeight or 8.2) + ((idx % 2 == 0) and 0.45 or -0.35),
			jetty = (B.JettyDepth or 0.65) + ((idx % 2 == 0) and 0.12 or -0.08),
			plinthOff = (idx % 3) * 0.08,
			doorSide = (idx % 2 == 0) and 1 or -1,
		}

		if alongX then
			building(f, pos, pos + w, z0, z1, h, style)
		else
			building(f, x0, x1, pos, pos + w, h, style)
		end
		pos += w
	end
end

local function fillBlock(f, r)
	local x0, x1, z0, z1 = r[1], r[2], r[3], r[4]
	local bw, bd = x1 - x0, z1 - z0
	-- Para las manzanas profundas junto a la calle principal, subdividir el frente de MainStreet
	-- en parcelas estrechas (~24 studs de fondo) para que las casas tengan proporción medieval real
	-- en lugar de muros laterales de 42 a 88 studs.
	if bw > 50 and bd > 36 then
		local streetDepth = 24
		if x0 == 12 then
			-- Manzana Este: tira frontal hacia MainStreet (x = 12..36) + resto hacia Práctica/Plaza
			fillStrip(f, x0, x0 + streetDepth, z0, z1)
			if bd > 80 then
				fillStrip(f, x0 + streetDepth, x1, z0, z0 + 24)
				building(f, x0 + streetDepth, x1, z0 + 24, z1, 38)
			else
				fillStrip(f, x0 + streetDepth, x1, z0, z1)
			end
			return
		elseif x1 == -12 then
			-- Manzana Oeste: tira frontal hacia MainStreet (x = -36..-12) + resto hacia Cementerio/Plaza
			fillStrip(f, x1 - streetDepth, x1, z0, z1)
			if bd > 80 then
				fillStrip(f, x0, x1 - streetDepth, z0, z0 + 24)
				building(f, x0, x1 - streetDepth, z0 + 24, z1, 38)
			else
				fillStrip(f, x0, x1 - streetDepth, z0, z1)
			end
			return
		end
	end
	fillStrip(f, x0, x1, z0, z1)
end

----------------------------------------------------------------------
-- Faroles
----------------------------------------------------------------------
local L = Cfg.Lamp
local function lamp(f, x, z, armDir)
	local H = L.Height
	part(f, "LampBase", Vector3.new(1.3, 0.8, 1.3), at(x, 0.4, z), COL.Iron, M.Metal, true)
	part(f, "LampPost", Vector3.new(0.45, H, 0.45), at(x, H / 2, z), COL.Iron, M.Metal, true)
	local ax, az = x + armDir.X * 1.2, z + armDir.Z * 1.2
	part(f, "LampArm", Vector3.new(armDir.X ~= 0 and 2.4 or 0.3, 0.3, armDir.Z ~= 0 and 2.4 or 0.3), at(ax, H - 0.4, az), COL.Iron, M.Metal, false)
	local lx, lz = x + armDir.X * 2.4, z + armDir.Z * 2.4
	local lantern = part(f, "Lantern", Vector3.new(1.1, 1.7, 1.1), at(lx, H - 1.4, lz), COL.Lamp, M.Neon, false)
	part(f, "LanternCap", Vector3.new(1.5, 0.35, 1.5), at(lx, H - 0.4, lz), COL.Iron, M.Metal, false)
	light(lantern, COL.Lamp, L.Brightness, L.Range, false)
end

local function lamps(root)
	local f = folderIn(root, "Lamps")
	-- Calle principal (fuera de la plaza), a ambos lados
	for z = -112, 144, L.Spacing do
		if z < -72 or z > -8 then
			lamp(f, -10, z, Vector3.new(1, 0, 0))
			lamp(f, 10, z + L.Spacing / 2, Vector3.new(-1, 0, 0))
		end
	end
	-- Calle transversal
	for x = -96, 96, L.Spacing do
		if math.abs(x) > 40 then
			lamp(f, x, -48, Vector3.new(0, 0, 1))
			lamp(f, x + L.Spacing / 2, -32, Vector3.new(0, 0, -1))
		end
	end
	-- Esquinas de la plaza
	for _, p in { { -32, -66 }, { 32, -66 }, { -32, -14 }, { 32, -14 } } do
		lamp(f, p[1], p[2], Vector3.new(p[1] > 0 and -1 or 1, 0, 0))
	end
end

----------------------------------------------------------------------
-- Plaza: ángel de piedra (referencia del cementerio) y torre del reloj
----------------------------------------------------------------------
local function ring(f, name, center, radius, thickness, segments, color, material)
	for i = 0, segments - 1 do
		local a0 = i / segments * math.pi * 2
		local a1 = (i + 1) / segments * math.pi * 2
		local p0 = center + Vector3.new(math.cos(a0) * radius, 0, math.sin(a0) * radius)
		local p1 = center + Vector3.new(math.cos(a1) * radius, 0, math.sin(a1) * radius)
		local mid = (p0 + p1) / 2
		part(f, name, Vector3.new(thickness, thickness, (p1 - p0).Magnitude + thickness * 0.4),
			CFrame.lookAt(mid, p1), color, material, false)
	end
end

local function angel(f, x, z, scale)
	scale = scale or 1
	local s = scale
	part(f, "Pedestal", Vector3.new(8, 5, 8) * s, at(x, 2.5 * s, z), COL.Stone, M.Slate, true)
	part(f, "PedestalTop", Vector3.new(9, 0.8, 9) * s, at(x, 5.2 * s, z), COL.Trim, M.Concrete, false)
	local robe = part(f, "AngelRobe", Vector3.new(7, 3.2, 3.2) * s, at(x, 9.1 * s, z) * CFrame.Angles(0, 0, math.rad(90)), COL.DarkStone, M.Slate, false)
	robe.Shape = Enum.PartType.Cylinder
	local head = part(f, "AngelHead", Vector3.new(1.7, 1.7, 1.7) * s, at(x, 13.4 * s, z), COL.DarkStone, M.Slate, false)
	head.Shape = Enum.PartType.Ball
	for _, side in { -1, 1 } do
		part(f, "AngelWing", Vector3.new(0.7, 8, 5.5) * s,
			at(x + side * 2.6 * s, 13 * s, z + 0.8 * s) * CFrame.Angles(0, math.rad(side * 70), math.rad(side * -35)),
			COL.DarkStone, M.Slate, false, "WedgePart")
	end
	ring(f, "Halo", Vector3.new(C.X + x, GROUND + 15.4 * s, C.Z + z), 1.1 * s, 0.18 * s, 12, COL.LightShaft, M.Neon)
end

local function clockTower(f, r)
	local x0, x1, z0, z1 = r[1], r[2], r[3], r[4]
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local w, d, h = x1 - x0, z1 - z0, 78
	local timberCol = (COL.Timber and COL.Timber[1]) or Color3.fromRGB(52, 36, 28)
	local plasterCol = (COL.Plaster and COL.Plaster[1]) or COL.Trim
	local roofCol = (COL.RoofTiles and COL.RoofTiles[1]) or COL.Roof

	-- 1. Basamento de sillería oscura, fuste principal y cuerpo superior de entramado
	part(f, "ClockTowerBase", Vector3.new(w, 24, d), at(cx, 12, cz), COL.DarkStone, M.Cobblestone, true)
	part(f, "ClockTowerPlinth", Vector3.new(w + 1.4, 1.8, d + 1.4), at(cx, 0.9, cz), COL.DarkStone, M.Slate, false)
	part(f, "ClockTower", Vector3.new(w - 0.8, 26, d - 0.8), at(cx, 37, cz), COL.Stone, M.Slate, true)
	part(f, "ClockTowerUpper", Vector3.new(w + 0.6, 28, d + 0.6), at(cx, 64, cz), plasterCol, M.Concrete, true)

	-- Cornisas y cinturones de piedra y madera
	part(f, "TowerBand", Vector3.new(w + 1.6, 1.1, d + 1.6), at(cx, 24, cz), COL.Trim, M.Concrete, false)
	part(f, "TowerBand", Vector3.new(w + 1.8, 1.2, d + 1.8), at(cx, 50, cz), timberCol, M.Wood, false)
	part(f, "TowerBand", Vector3.new(w + 2.2, 1.4, d + 2.2), at(cx, h, cz), timberCol, M.Wood, false)

	-- 2. Contrafuertes de esquina y pináculos góticos
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local bx = cx + sx * (w * 0.5 - 0.4)
			local bz = cz + sz * (d * 0.5 - 0.4)
			part(f, "TowerButtress", Vector3.new(2.6, 50, 2.6), at(bx, 25, bz), COL.DarkStone, M.Slate, false)
			part(f, "TowerCornerTimber", Vector3.new(1.1, 27, 1.1), at(cx + sx * (w * 0.5 + 0.2), 64, cz + sz * (d * 0.5 + 0.2)), timberCol, M.Wood, false).CastShadow = false
			-- Pináculos en las 4 esquinas de la cornisa superior
			local px, pz = cx + sx * (w * 0.5 + 0.3), cz + sz * (d * 0.5 + 0.3)
			part(f, "TowerPinnacle", Vector3.new(2.2, 5.5, 2.2), at(px, h + 3.4, pz), COL.DarkStone, M.Slate, false).CastShadow = false
			local pCap = part(f, "TowerPinnacleCap", Vector3.new(1.8, 3.8, 1.8), at(px, h + 8.0, pz), roofCol, M.Slate, false)
			pCap.CastShadow = false
		end
	end

	-- 3. Portal en arco mirando a la plaza (oeste) y ventanales góticos ámbar
	local westCf = CFrame.lookAt(Vector3.new(C.X + x0, GROUND, C.Z + cz), Vector3.new(C.X + x0 - 1, GROUND, C.Z + cz))
	part(f, "TowerDoorFrame", Vector3.new(5.4, 8.5, 0.6), westCf * CFrame.new(0, 4.25, -0.25), COL.Trim, M.Concrete, false)
	part(f, "TowerDoor", Vector3.new(4.2, 8.0, 0.35), westCf * CFrame.new(0, 4.0, -0.38), COL.DoorWood or timberCol, M.WoodPlanks, false)
	local tArch = part(f, "TowerDoorArch", Vector3.new(0.45, 4.2, 4.2), westCf * CFrame.new(0, 8.0, -0.40) * CFrame.Angles(0, math.rad(90), 0), COL.DoorWood or timberCol, M.WoodPlanks, false)
	tArch.Shape = Enum.PartType.Cylinder
	for _, side in { -1, 1 } do
		local lw = part(f, "LitWindow", Vector3.new(2.2, 9.5, 0.25), westCf * CFrame.new(side * 4.6, 37, 0.25), COL.Window, M.Neon, false)
		lw.CastShadow = false
		part(f, "WindowMullion", Vector3.new(0.24, 9.8, 0.25), westCf * CFrame.new(side * 4.6, 37, 0.14), timberCol, M.Wood, false).CastShadow = false
	end

	-- 4. Esferas del reloj: Oeste (hacia la plaza) y Sur (hacia la llegada desde el Spawn)
	-- Oeste
	local dialPosW = at(x0 - 0.55, 64, cz)
	local bezelW = part(f, "ClockBezel", Vector3.new(0.36, 14.4, 14.4), dialPosW, timberCol, M.Wood, false)
	bezelW.Shape = Enum.PartType.Cylinder
	local dialW = part(f, "ClockFace", Vector3.new(0.46, 13, 13), dialPosW * CFrame.new(-0.08, 0, 0), COL.Clock, M.Neon, false)
	dialW.Shape = Enum.PartType.Cylinder
	light(dialW, COL.Clock, 1.5, 24, false)
	part(f, "HourHand", Vector3.new(0.3, 3.6, 0.5), dialPosW * CFrame.new(-0.38, 1.4, 0) * CFrame.Angles(math.rad(40), 0, 0), COL.Iron, M.Metal, false)
	part(f, "MinuteHand", Vector3.new(0.3, 5.4, 0.4), dialPosW * CFrame.new(-0.44, 2.2, -0.9) * CFrame.Angles(math.rad(-25), 0, 0), COL.Iron, M.Metal, false)

	-- Sur (rotado 90 grados para mirar al sur)
	local dialPosS = at(cx, 64, z0 - 0.55) * CFrame.Angles(0, math.rad(90), 0)
	local bezelS = part(f, "ClockBezelSouth", Vector3.new(0.36, 13.4, 13.4), dialPosS, timberCol, M.Wood, false)
	bezelS.Shape = Enum.PartType.Cylinder
	local dialS = part(f, "ClockFaceSouth", Vector3.new(0.46, 12, 12), dialPosS * CFrame.new(0.08, 0, 0), COL.Clock, M.Neon, false)
	dialS.Shape = Enum.PartType.Cylinder
	part(f, "HourHandSouth", Vector3.new(0.3, 3.4, 0.45), dialPosS * CFrame.new(0.38, 1.3, 0) * CFrame.Angles(math.rad(40), 0, 0), COL.Iron, M.Metal, false)
	part(f, "MinuteHandSouth", Vector3.new(0.3, 5.0, 0.38), dialPosS * CFrame.new(0.44, 2.0, -0.8) * CFrame.Angles(math.rad(-25), 0, 0), COL.Iron, M.Metal, false)

	-- 5. Chapitel gótico escarpado de dos niveles con aleros y veleta de hierro
	local eaveW, eaveD, eaveH = w + 3.6, d + 3.6, 8.5
	part(f, "SpireEave", Vector3.new(eaveD, eaveH, eaveW / 2),
		at(cx - eaveW / 4, h + 0.7 + eaveH / 2, cz) * CFrame.Angles(0, math.rad(90), 0), roofCol, M.Slate, false, "WedgePart")
	part(f, "SpireEave", Vector3.new(eaveD, eaveH, eaveW / 2),
		at(cx + eaveW / 4, h + 0.7 + eaveH / 2, cz) * CFrame.Angles(0, math.rad(-90), 0), roofCol, M.Slate, false, "WedgePart")

	local spireBase = h + 6.5
	local spireW, spireD, spireH = w * 0.58, d * 0.58, 22
	part(f, "Spire", Vector3.new(spireD, spireH, spireW / 2),
		at(cx - spireW / 4, spireBase + spireH / 2, cz) * CFrame.Angles(0, math.rad(90), 0), roofCol, M.Slate, false, "WedgePart")
	part(f, "Spire", Vector3.new(spireD, spireH, spireW / 2),
		at(cx + spireW / 4, spireBase + spireH / 2, cz) * CFrame.Angles(0, math.rad(-90), 0), roofCol, M.Slate, false, "WedgePart")
	part(f, "SpireCross", Vector3.new(spireW, spireH, spireD / 2),
		at(cx, spireBase + spireH / 2, cz - spireD / 4), roofCol, M.Slate, false, "WedgePart")
	part(f, "SpireCross", Vector3.new(spireW, spireH, spireD / 2),
		at(cx, spireBase + spireH / 2, cz + spireD / 4) * CFrame.Angles(0, math.pi, 0), roofCol, M.Slate, false, "WedgePart")
	part(f, "SpireTip", Vector3.new(0.65, 11, 0.65), at(cx, spireBase + spireH + 5, cz), COL.Iron, M.Metal, false)
	part(f, "SpireVane", Vector3.new(3.6, 0.35, 0.35), at(cx, spireBase + spireH + 8.5, cz), COL.Iron, M.Metal, false)
end

----------------------------------------------------------------------
-- Cementerio
----------------------------------------------------------------------
local function cemetery(root)
	local f = folderIn(root, "Cemetery")
	local r = Cfg.Walkable.Cemetery
	-- Verja de hierro en el lado de la calle (con hueco en la calle transversal)
	for z = r[3] + 1, r[4] - 1, 2 do
		if z < -53 or z > -27 then
			part(f, "FencePost", Vector3.new(0.25, 3.4, 0.25), at(r[2] - 0.5, 1.7, z), COL.Iron, M.Metal, true)
		end
	end
	for _, seg in { { r[3], -53 }, { -27, r[4] } } do
		for _, y in { 1.2, 3.0 } do
			part(f, "FenceRail", Vector3.new(0.2, 0.2, seg[2] - seg[1]), at(r[2] - 0.5, y, (seg[1] + seg[2]) / 2), COL.Iron, M.Metal, false)
		end
	end
	-- Lápidas y cruces
	for _ = 1, 22 do
		local x = r[1] + 4 + rng:NextNumber() * (r[2] - r[1] - 8)
		local z = r[3] + 4 + rng:NextNumber() * (r[4] - r[3] - 8)
		if z < -54 or z > -26 then
			local tilt = CFrame.Angles(math.rad((rng:NextNumber() - 0.5) * 12), math.rad(90 + (rng:NextNumber() - 0.5) * 20), math.rad((rng:NextNumber() - 0.5) * 8))
			if rng:NextNumber() < 0.7 then
				part(f, "Tombstone", Vector3.new(2.4, 3.2, 0.6), at(x, 1.4, z) * tilt, COL.DarkStone, M.Slate, true)
			else
				part(f, "Cross", Vector3.new(0.5, 4.2, 0.5), at(x, 2.1, z) * tilt, COL.DarkStone, M.Slate, true)
				part(f, "CrossArm", Vector3.new(2.4, 0.5, 0.5), at(x, 3.1, z) * tilt, COL.DarkStone, M.Slate, false)
			end
		end
	end
	-- Árboles secos
	for _, p in { { -92, -70 }, { -70, -12 }, { -96, -20 } } do
		part(f, "DeadTrunk", Vector3.new(1.1, 11, 1.1), at(p[1], 5.5, p[2]), Color3.fromRGB(38, 32, 30), M.Wood, true)
		for i = 1, 3 do
			local a = i * 2.1
			part(f, "DeadBranch", Vector3.new(0.45, 5.5, 0.45),
				at(p[1] + math.cos(a) * 1.4, 9 + i, p[2] + math.sin(a) * 1.4) * CFrame.Angles(math.sin(a) * 0.8, 0, math.cos(a) * 0.8),
				Color3.fromRGB(38, 32, 30), M.Wood, false)
		end
	end
	angel(f, -82, -40, 0.7)
end

----------------------------------------------------------------------
-- Gran puerta con gárgolas y antesala con los círculos 1v1 / 2v2
----------------------------------------------------------------------
local function gargoyle(f, x, y, z, side)
	part(f, "GargoyleBody", Vector3.new(4.2, 4, 4.2), at(x, y + 2, z), COL.DarkStone, M.Slate, false)
	local head = part(f, "GargoyleHead", Vector3.new(2.6, 2.6, 2.6), at(x, y + 5.2, z - 0.6), COL.DarkStone, M.Slate, false)
	head.Shape = Enum.PartType.Ball
	for _, s in { -1, 1 } do
		part(f, "GargoyleHorn", Vector3.new(0.35, 2.6, 0.9), at(x + s * 0.9, y + 7.2, z - 0.6) * CFrame.Angles(0, 0, math.rad(s * -25)), COL.DarkStone, M.Slate, false, "WedgePart")
	end
end

local function gateAndAntechamber(root, result)
	local f = folderIn(root, "Gate")
	local gz = 150
	for _, s in { -1, 1 } do
		-- 9/11: 8.2 de ancho y centro en 15.9: su cara ya no coincide con la de los edificios de la calle (parpadeaba)
		part(f, "GatePillar", Vector3.new(8.2, 44, 8), at(s * 15.9, 22, gz), COL.Stone, M.Slate, true)
		part(f, "PillarCap", Vector3.new(9.5, 1.5, 9.5), at(s * 16, 44.7, gz), COL.Trim, M.Concrete, false)
		gargoyle(f, s * 16, 45.5, gz, s)
		-- Hojas de la puerta abiertas hacia la antesala
		part(f, "GateDoor", Vector3.new(12, 32, 1.2), at(s * 12, 16, gz) * CFrame.Angles(0, math.rad(s * 70), 0) * CFrame.new(-s * 6, 0, 0),
			COL.DarkStone, M.Slate, true)
	end
	part(f, "GateLintel", Vector3.new(40, 6, 8), at(0, 41, gz), COL.Stone, M.Slate, false)
	-- Rayo de luz en el umbral
	local shaft = part(f, "LightShaft", Vector3.new(0.35, 32, 0.35), at(0, 16, gz + 0.5), COL.LightShaft, M.Neon, false)
	shaft.Transparency = 0.25
	light(shaft, COL.LightShaft, 1.6, 24, false)

	-- Muros de la antesala
	local a = Cfg.Walkable.Antechamber
	local wh = Cfg.AntechamberWall
	local midZ = (a[3] + a[4]) / 2
	part(f, "AnteWall", Vector3.new(3, wh, a[4] - a[3]), at(a[1] - 1.5, wh / 2, midZ), COL.Stone, M.Slate, true)
	part(f, "AnteWall", Vector3.new(3, wh, a[4] - a[3]), at(a[2] + 1.5, wh / 2, midZ), COL.Stone, M.Slate, true)
	part(f, "AnteWall", Vector3.new(a[2] - a[1] + 6, wh, 3), at(0, wh / 2, a[4] + 1.5), COL.Stone, M.Slate, true)
	for _, s in { -1, 1 } do
		part(f, "AnteFront", Vector3.new(a[2] - 20, wh, 3), at(s * (20 + (a[2] - 20) / 2), wh / 2, gz - 1.5), COL.Stone, M.Slate, true)
		for zz = a[3] + 12, a[4] - 6, 16 do
			part(f, "Buttress", Vector3.new(3, wh - 4, 3), at(s * (a[2] - 1), (wh - 4) / 2, zz), COL.DarkStone, M.Slate, true)
		end
	end
	angel(f, 0, 208, 0.9)

	-- Círculos de cola
	result.queueZones = {}
	for mode, z in Cfg.QueueZones do
		local center = Vector3.new(C.X + z.center.X, GROUND, C.Z + z.center.Z)
		local disk = part(f, "QueueZone_" .. mode, Vector3.new(0.3, z.radius * 2, z.radius * 2),
			CFrame.new(center + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), COL.DarkStone, M.Slate, false)
		disk.Shape = Enum.PartType.Cylinder
		ring(f, "QueueRing", center + Vector3.new(0, 0.25, 0), z.radius, 0.45, 28, z.color, M.Neon)
		light(disk, z.color, 2, z.radius * 2.5, false)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(180, 90)
		bb.StudsOffset = Vector3.new(0, 7, 0)
		bb.AlwaysOnTop = false
		bb.MaxDistance = 90
		bb.Parent = disk
		local title = Instance.new("TextLabel")
		title.Size = UDim2.fromScale(1, 0.6)
		title.BackgroundTransparency = 1
		title.Text = mode
		title.TextScaled = true
		title.Font = Enum.Font.Garamond
		title.TextColor3 = z.color
		title.TextStrokeTransparency = 0.3
		title.Parent = bb
		local count = Instance.new("TextLabel")
		count.Position = UDim2.fromScale(0, 0.6)
		count.Size = UDim2.fromScale(1, 0.4)
		count.BackgroundTransparency = 1
		count.Text = ""
		count.TextScaled = true
		count.Font = Enum.Font.GothamBold
		count.TextColor3 = COL.Clock
		count.TextStrokeTransparency = 0.3
		count.Parent = bb
		result.queueZones[mode] = { center = center, radius = z.radius, label = count }
	end
	-- Braseros en las esquinas
	for _, p in { { -30, 158 }, { 30, 158 }, { -30, 208 }, { 30, 208 } } do
		local bowl = part(f, "Brazier", Vector3.new(3, 1.2, 3), at(p[1], 3.2, p[2]), COL.Iron, M.CorrodedMetal, true)
		part(f, "BrazierLeg", Vector3.new(0.8, 2.6, 0.8), at(p[1], 1.3, p[2]), COL.Iron, M.CorrodedMetal, true)
		local fire = Instance.new("Fire")
		fire.Size = 5
		fire.Heat = 8
		fire.Color = Color3.fromRGB(255, 130, 50)
		fire.SecondaryColor = Color3.fromRGB(120, 30, 10)
		fire.Parent = bowl
		light(bowl, Color3.fromRGB(255, 150, 80), 2.2, 26, false)
	end
end

----------------------------------------------------------------------
-- Patio de práctica, siluetas de fondo y muros invisibles
----------------------------------------------------------------------
local function practiceYard(root)
	local f = folderIn(root, "Practice")
	local r = Cfg.Walkable.Practice
	-- Estandarte con espadas cruzadas (sin texto: vale para todos los idiomas)
	local px, pz = r[2] - 2, (r[3] + r[4]) / 2
	part(f, "Banner", Vector3.new(0.4, 9, 6), at(px, 6.5, pz), Color3.fromRGB(70, 20, 24), M.Fabric, false)
	for _, s in { -1, 1 } do
		part(f, "BannerSword", Vector3.new(0.3, 7, 0.5), at(px - 0.4, 6.5, pz) * CFrame.Angles(math.rad(s * 35), 0, 0), COL.Trim, M.Metal, false)
	end
end

local function skyline(root)
	local f = folderIn(root, "Skyline")
	local S = Cfg.Skyline
	local mid = Vector3.new(0, 0, 45)
	for i = 1, S.Count do
		local ang = (i / S.Count) * math.pi * 2 + rng:NextNumber() * 0.08
		local dist = S.InnerRadius + rng:NextNumber() * (S.OuterRadius - S.InnerRadius)
		local x, z = mid.X + math.cos(ang) * dist, mid.Z + math.sin(ang) * dist
		local h = range(S.Height)
		local w = range(S.Width)
		local b = part(f, "Silhouette", Vector3.new(w, h, w * 0.8), at(x, h / 2 - 4, z) * CFrame.Angles(0, -ang, 0), COL.Skyline, M.Slate, false)
		b.CastShadow = false
		-- algunas ventanas lejanas encendidas
		for _ = 1, rng:NextInteger(0, 3) do
			local wy = 6 + rng:NextNumber() * (h - 12)
			local wx = (rng:NextNumber() - 0.5) * w * 0.7
			local win = part(f, "FarWindow", Vector3.new(1.4, 2, 0.4), b.CFrame * CFrame.new(wx, wy - h / 2, -w * 0.4 - 0.2), COL.Window, M.Neon, false)
			win.CastShadow = false
		end
		if rng:NextNumber() < 0.15 then
			part(f, "Spire", Vector3.new(1.2, h * 0.5, 1.2), at(x, h + h * 0.25 - 4, z), COL.Skyline, M.Slate, false).CastShadow = false
		end
	end
end

local function invisibleWalls(root)
	local f = folderIn(root, "InvisibleWalls")
	local x0, x1, z0, z1 = -101, 101, -121, 216
	local h = Cfg.WallHeight
	local function wall(size, cf)
		local p = part(f, "InvisibleWall", size, cf, Color3.new(), M.SmoothPlastic, true)
		p.Transparency = 1
		p.CanQuery = false -- no estorba a la cámara ni a los golpes
		p.CastShadow = false
	end
	wall(Vector3.new(2, h, z1 - z0), at(x0 - 1, h / 2, (z0 + z1) / 2))
	wall(Vector3.new(2, h, z1 - z0), at(x1 + 1, h / 2, (z0 + z1) / 2))
	wall(Vector3.new(x1 - x0, h, 2), at(0, h / 2, z0 - 1))
	wall(Vector3.new(x1 - x0, h, 2), at(0, h / 2, z1 + 1))
end

----------------------------------------------------------------------
-- Orientación: flechas en el suelo, cartel, haz de luz sobre la puerta y la armería
-- Los textos se traducen en el cliente (Lobby.client): las etiquetas llevan el atributo LocKey.
----------------------------------------------------------------------
local function locLabel(parent, key, color, size)
	local l = Instance.new("TextLabel")
	l.Size = size or UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = key
	l.TextScaled = true
	l.Font = Enum.Font.Garamond
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.4
	l:SetAttribute("LocKey", key)
	l.Parent = parent
	return l
end

local function guidance(root)
	local f = folderIn(root, "Guidance")
	local G = Cfg.Guide
	-- Flechas (chevrones) en la calle principal apuntando a la gran puerta (norte)
	for z = -112, 140, G.ArrowSpacing do
		if z < -72 or z > -8 then
			for _, s in { -1, 1 } do
				local p = part(f, "GuideArrow", Vector3.new(0.5, 0.12, 3.2), at(s * 0.9, 0.08, z) * CFrame.Angles(0, math.rad(s * 40), 0), G.Color, M.Neon, false)
				p.Transparency = G.Transparency
				p.CastShadow = false
			end
		end
	end
	-- Cartel en la plaza: tres brazos (Arena al norte, Práctica al este, Armería al oeste)
	local sx, sz = 8, -66
	part(f, "SignPost", Vector3.new(0.6, 9, 0.6), at(sx, 4.5, sz), Color3.fromRGB(52, 36, 28), M.Wood, true)
	for i, arm in { { dir = Vector3.new(0, 0, 1), key = "lobby.arena", y = 8 }, { dir = Vector3.new(1, 0, 0), key = "lobby.practice", y = 6.8 }, { dir = Vector3.new(-1, 0, 0), key = "lobby.shop", y = 5.6 } } do
		local center = Vector3.new(C.X + sx, GROUND + arm.y, C.Z + sz) + arm.dir * 2.4
		local board = part(f, "SignBoard", Vector3.new(4.4, 1, 0.25), CFrame.lookAt(center, center + Vector3.yAxis:Cross(arm.dir)) , Color3.fromRGB(70, 48, 34), M.Wood, false)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			local sg = Instance.new("SurfaceGui")
			sg.Face = face
			sg.CanvasSize = Vector2.new(440, 100)
			sg.LightInfluence = 0
			sg.Parent = board
			locLabel(sg, arm.key, i == 1 and G.Color or COL.Clock)
		end
	end
	-- Haz de luz sobre la gran puerta: se ve desde toda la ciudad
	local beam = part(f, "ArenaBeacon", Vector3.new(3, G.BeaconHeight, 3), at(0, 44 + G.BeaconHeight / 2, 150), G.Color, M.Neon, false)
	beam.Transparency = 0.6
	beam.CastShadow = false
	light(beam, G.Color, 3, 40, false)
	local bb = Instance.new("BillboardGui")
	bb.Name = "ArenaMarker"
	bb.Size = UDim2.fromOffset(220, 60)
	bb.StudsOffsetWorldSpace = Vector3.new(0, -G.BeaconHeight / 2 + 6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 600
	bb.Parent = beam
	locLabel(bb, "lobby.arena", G.Color)
end

local function armory(root)
	local f = folderIn(root, "Armory")
	local S = Cfg.Shop
	local x, z = S.Position.X, S.Position.Z
	local wood, cloth = Color3.fromRGB(58, 40, 30), Color3.fromRGB(96, 22, 30)
	part(f, "Counter", Vector3.new(8, 3.2, 2.4), at(x, 1.6, z), wood, M.Wood, true)
	part(f, "CounterTop", Vector3.new(8.6, 0.4, 2.8), at(x, 3.4, z), Color3.fromRGB(40, 28, 22), M.WoodPlanks, false)
	part(f, "BackWall", Vector3.new(8, 9, 0.6), at(x, 4.5, z - 3.4), wood, M.WoodPlanks, true)
	for _, s in { -1, 1 } do
		part(f, "StallPost", Vector3.new(0.6, 9, 0.6), at(x + s * 3.8, 4.5, z + 1.2), wood, M.Wood, true)
	end
	part(f, "Awning", Vector3.new(9.4, 2.2, 5), at(x, 9.6, z - 1) * CFrame.Angles(0, math.pi, 0), cloth, M.Fabric, false, "WedgePart")
	-- Armas colgadas en la pared
	for i = -1, 1 do
		local blade = part(f, "RackBlade", Vector3.new(0.25, 4.2, 0.7), at(x + i * 2.4, 5, z - 3) * CFrame.Angles(0, 0, math.rad(i * 18)), COL.Trim, M.Metal, false)
		part(f, "RackGuard", Vector3.new(1.4, 0.3, 0.4), blade.CFrame * CFrame.new(0, -1.6, 0), COL.Iron, M.Metal, false)
	end
	local lantern = part(f, "StallLantern", Vector3.new(1, 1.5, 1), at(x + 3, 7.6, z + 1.2), COL.Lamp, M.Neon, false)
	light(lantern, COL.Lamp, 2.4, 22, false)
	-- Cartel y punto de interacción (abre la tienda)
	local sign = part(f, "ArmorySign", Vector3.new(6, 1.4, 0.3), at(x, 11.4, z + 1.4), wood, M.Wood, false)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.CanvasSize = Vector2.new(600, 140)
		sg.LightInfluence = 0
		sg.Parent = sign
		locLabel(sg, "lobby.shop", COL.Clock)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenShop"
	prompt.ActionText = "lobby.shop"
	prompt.ObjectText = ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = f:FindFirstChild("Counter")
end

----------------------------------------------------------------------
-- Construcción
----------------------------------------------------------------------
function LobbyBuilder.build(parent)
	local root = folderIn(parent, "City")
	local result = {}
	-- Contrato etapa 8: CityProps (Codex) agrega taberna, santuario del punto de aparición y tableros.
	-- Puede reemplazar manzanas enteras (CityProps.ReplacesBlock[i] = true).
	local propsModule = script.Parent:FindFirstChild("CityProps")
	local okProps, props = false, nil
	if propsModule then okProps, props = pcall(require, propsModule) end
	if propsModule and not okProps then warn("[LobbyBuilder] CityProps falló al cargar:", props) props = nil end

	ground(root)
	local bf = folderIn(root, "Buildings")
	for i, r in Cfg.Blocks do
		if i == 3 then
			clockTower(bf, r) -- junto a la plaza
		elseif props and props.ReplacesBlock and props.ReplacesBlock[i] then
			-- la construye CityProps
		else
			fillBlock(bf, r)
		end
	end
	lamps(root)
	local plaza = folderIn(root, "Plaza")
	angel(plaza, 0, -40, 1)
	cemetery(root)
	practiceYard(root)
	gateAndAntechamber(root, result)
	guidance(root)
	armory(root)
	skyline(root)
	invisibleWalls(root)
	if props and props.build then
		local ok, err = pcall(props.build, folderIn(root, "Props"), {
			origin = Vector3.new(C.X, GROUND, C.Z), -- (0,0,0) de CityConfig, a ras del suelo
			blocks = Cfg.Blocks, walkable = Cfg.Walkable, spawn = Cfg.Spawn,
			floorTop = Cfg.FloorLayerStep * 4 + 0.05, -- altura del piso más alto (la plaza)
		})
		if not ok then warn("[LobbyBuilder] CityProps.build falló:", err) end
	end
	-- Contrato ronda 4: pueblerinos que caminan por la ciudad (Codex, CityNPCs.start)
	local npcModule = script.Parent:FindFirstChild("CityNPCs")
	if npcModule then
		task.spawn(function()
			local ok, err = pcall(function()
				require(npcModule).start(root, {
					origin = Vector3.new(C.X, GROUND, C.Z), blocks = Cfg.Blocks, walkable = Cfg.Walkable, spawn = Cfg.Spawn,
					floorTop = Cfg.FloorLayerStep * 4 + 0.05,
				})
			end)
			if not ok then warn("[LobbyBuilder] CityNPCs falló:", err) end
		end)
	end

	local spawnPos = Vector3.new(C.X + Cfg.Spawn.X, GROUND + 3, C.Z + Cfg.Spawn.Z)
	result.spawn = CFrame.lookAt(spawnPos, spawnPos + Vector3.zAxis)
	result.practiceCenter = Vector3.new(C.X + 80, GROUND, C.Z - 40)
	result.dummyHomes = {}
	for i, p in Cfg.DummyHomes do
		local pos = Vector3.new(C.X + p.X, GROUND + p.Y - 1, C.Z + p.Z)
		result.dummyHomes[i] = CFrame.lookAt(pos, pos - Vector3.xAxis)
	end
	return result
end

return LobbyBuilder
