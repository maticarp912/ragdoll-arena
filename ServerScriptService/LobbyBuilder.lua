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
-- Edificios
----------------------------------------------------------------------
local B = Cfg.Building

local function windowsOnFace(f, center, along, normal, faceWidth, height)
	local cols = math.clamp(math.floor((faceWidth - 3) / B.WindowSpacing), 1, 6)
	local rows = math.clamp(math.floor((height - 5) / B.FloorHeight), 1, 6)
	local size = B.WindowSize
	for r = 1, rows do
		local y = 4 + (r - 1) * B.FloorHeight + size.Y / 2
		for c = 1, cols do
			local offset = (c - (cols + 1) / 2) * B.WindowSpacing
			local pos = center + along * offset + normal * 0.18 + Vector3.new(0, y, 0)
			local lit = rng:NextNumber() < B.LitChance
			local cf = CFrame.lookAt(pos, pos + normal)
			local w = part(f, lit and "LitWindow" or "Window", Vector3.new(size.X, size.Y, size.Z), cf,
				lit and COL.Window or COL.WindowDark, lit and M.Neon or M.Glass, false)
			if not lit then w.Reflectance = 0.15 end
			-- marco claro (sillar) bajo cada ventana
			part(f, "Sill", Vector3.new(size.X + 0.6, 0.3, 0.6), cf * CFrame.new(0, -size.Y / 2 - 0.15, -0.1), COL.Trim, M.Concrete, false)
		end
	end
	-- Puerta en la planta baja
	if faceWidth >= 8 then
		local pos = center + normal * 0.25 + Vector3.new(0, 3, 0)
		part(f, "Door", Vector3.new(3, 6, 0.4), CFrame.lookAt(pos, pos + normal), Color3.fromRGB(46, 30, 24), M.Wood, false)
	end
end

local function building(f, x0, x1, z0, z1, h)
	local w, d = x1 - x0, z1 - z0
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local color = COL.Bricks[rng:NextInteger(1, #COL.Bricks)]
	part(f, "Building", Vector3.new(w, h, d), at(cx, h / 2, cz), color, M.Brick, true)
	part(f, "Cornice", Vector3.new(w + 0.8, 0.8, d + 0.8), at(cx, h + 0.4, cz), COL.Trim, M.Concrete, false)
	part(f, "Plinth", Vector3.new(w + 0.4, 1.2, d + 0.4), at(cx, 0.6, cz), COL.DarkStone, M.Slate, false)

	-- Tejado: a dos aguas (cuñas) o plano con chimeneas
	local top = h + 0.8
	if rng:NextNumber() < B.PitchedChance then
		local rh = math.min(w, d) * 0.4
		if d >= w then
			part(f, "Roof", Vector3.new(d, rh, w / 2), at(x0 + w / 4, top + rh / 2, cz) * CFrame.Angles(0, math.rad(90), 0), COL.Roof, M.Slate, false, "WedgePart")
			part(f, "Roof", Vector3.new(d, rh, w / 2), at(x1 - w / 4, top + rh / 2, cz) * CFrame.Angles(0, math.rad(-90), 0), COL.Roof, M.Slate, false, "WedgePart")
		else
			part(f, "Roof", Vector3.new(w, rh, d / 2), at(cx, top + rh / 2, z0 + d / 4), COL.Roof, M.Slate, false, "WedgePart")
			part(f, "Roof", Vector3.new(w, rh, d / 2), at(cx, top + rh / 2, z1 - d / 4) * CFrame.Angles(0, math.pi, 0), COL.Roof, M.Slate, false, "WedgePart")
		end
	end
	if rng:NextNumber() < B.ChimneyChance then
		local px = cx + (rng:NextNumber() - 0.5) * w * 0.6
		local pz = cz + (rng:NextNumber() - 0.5) * d * 0.6
		local ch = part(f, "Chimney", Vector3.new(1.8, 6, 1.8), at(px, top + 3, pz), color, M.Brick, false)
		if rng:NextNumber() < 0.5 then
			local smoke = Instance.new("ParticleEmitter")
			smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
			smoke.Color = ColorSequence.new(Color3.fromRGB(70, 72, 80))
			smoke.Transparency = NumberSequence.new(0.6, 1)
			smoke.Size = NumberSequence.new(2, 7)
			smoke.Lifetime = NumberRange.new(4, 7)
			smoke.Rate = 2
			smoke.Speed = NumberRange.new(2, 4)
			smoke.Acceleration = Vector3.new(1.5, 0.5, 0)
			smoke.Parent = ch
		end
	end

	-- Ventanas y puerta solo en las caras que dan a una calle o plaza
	local faces = {
		{ n = Vector3.new(1, 0, 0), along = Vector3.zAxis, cx = x1, cz = cz, width = d },
		{ n = Vector3.new(-1, 0, 0), along = Vector3.zAxis, cx = x0, cz = cz, width = d },
		{ n = Vector3.new(0, 0, 1), along = Vector3.xAxis, cx = cx, cz = z1, width = w },
		{ n = Vector3.new(0, 0, -1), along = Vector3.xAxis, cx = cx, cz = z0, width = w },
	}
	for _, face in faces do
		local px, pz = face.cx + face.n.X * 3, face.cz + face.n.Z * 3
		if walkable(px, pz) then
			local center = Vector3.new(C.X + face.cx, GROUND, C.Z + face.cz)
			windowsOnFace(f, center, face.along, face.n, math.min(face.width, 34), h)
		end
	end
end

-- Llena una manzana con edificios en fila a lo largo de su lado más largo
local function fillBlock(f, r)
	local x0, x1, z0, z1 = r[1], r[2], r[3], r[4]
	local alongX = (x1 - x0) >= (z1 - z0)
	local a0, a1 = alongX and x0 or z0, alongX and x1 or z1
	local pos = a0
	while pos < a1 - 0.5 do
		local w = math.min(range(B.Width), a1 - pos)
		if a1 - (pos + w) < 8 then w = a1 - pos end -- sin edificios minúsculos al final
		local h = range(B.Height)
		if alongX then
			building(f, pos, pos + w, z0, z1, h)
		else
			building(f, x0, x1, pos, pos + w, h)
		end
		pos += w
	end
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
	part(f, "ClockTower", Vector3.new(w, h, d), at(cx, h / 2, cz), COL.Stone, M.Slate, true)
	part(f, "TowerBand", Vector3.new(w + 1.2, 1.2, d + 1.2), at(cx, 48, cz), COL.Trim, M.Concrete, false)
	part(f, "TowerBand", Vector3.new(w + 1.2, 1.2, d + 1.2), at(cx, h, cz), COL.Trim, M.Concrete, false)
	part(f, "Spire", Vector3.new(w * 0.5, 14, d * 0.5), at(cx, h + 7, cz), COL.Roof, M.Slate, false)
	part(f, "SpireTip", Vector3.new(0.7, 12, 0.7), at(cx, h + 20, cz), COL.Iron, M.Metal, false)
	-- Esfera del reloj mirando a la plaza (oeste)
	local dialPos = at(x0 - 0.25, 58, cz)
	local dial = part(f, "ClockFace", Vector3.new(0.4, 13, 13), dialPos, COL.Clock, M.Neon, false)
	dial.Shape = Enum.PartType.Cylinder
	light(dial, COL.Clock, 1.5, 22, false)
	part(f, "HourHand", Vector3.new(0.3, 3.6, 0.5), dialPos * CFrame.new(-0.35, 1.4, 0) * CFrame.Angles(math.rad(40), 0, 0), COL.Iron, M.Metal, false)
	part(f, "MinuteHand", Vector3.new(0.3, 5.4, 0.4), dialPos * CFrame.new(-0.4, 2.2, -0.9) * CFrame.Angles(math.rad(-25), 0, 0), COL.Iron, M.Metal, false)
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
