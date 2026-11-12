-- ModuleScript: ReplicatedStorage/WeaponBuilder
-- Construye las armas (modelos de piezas basados en el arte conceptual del usuario).
-- Lo usan el servidor (Tool que empuña el personaje) y la tienda (vista previa en 3D).
-- Orden de preferencia en el servidor:
--   1) Tool/Model propio en ServerStorage/Weapons/<WeaponId>
--   2) MeshPart con Assets.Models.Weapons.<WeaponId>.MeshId
--   3) Modelo de piezas de este archivo
-- Ejes del arma (espacio del mango): la hoja apunta a +Z, su filo ancho está en Y y es fina en X.
-- Attachments BladeBase / BladeTip: estela de los golpes y destellos de aviso.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Skins = require(ReplicatedStorage:WaitForChild("Skins"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local Assets = require(ReplicatedStorage:WaitForChild("Assets"))
local SkinDesigns = require(ReplicatedStorage:WaitForChild("SkinDesigns"))

local WeaponBuilder = {}

local rgb = Color3.fromRGB
local M = Enum.Material

-- Paleta propia de cada arma (skin "Acero Viejo" = la del arte original)
local NATIVE = {
	Sword = { blade = rgb(148, 150, 156), bladeMat = M.Metal, accent = rgb(78, 74, 70), accentMat = M.Metal, grip = rgb(58, 40, 28) },
	Rapier = { blade = rgb(158, 158, 162), bladeMat = M.Metal, accent = rgb(72, 72, 76), accentMat = M.Metal, grip = rgb(38, 30, 26) },
	Greatsword = { blade = rgb(172, 172, 174), bladeMat = M.Metal, accent = rgb(128, 128, 132), accentMat = M.Metal, grip = rgb(96, 94, 92) },
	Dagger = { blade = rgb(176, 174, 170), bladeMat = M.Metal, accent = rgb(112, 112, 118), accentMat = M.Metal, grip = rgb(78, 54, 36) },
	Mace = { blade = rgb(104, 100, 96), bladeMat = M.CorrodedMetal, accent = rgb(58, 54, 50), accentMat = M.Metal, grip = rgb(64, 42, 28), wood = rgb(78, 54, 36) },
}

-- Información para animaciones: dónde agarra la mano derecha (gripZ) y la izquierda (offhandZ)
WeaponBuilder.Info = {
	Sword = { gripZ = 0.15, twoHanded = false, trail = { 1.0, 5.1 } },
	Rapier = { gripZ = 0.1, twoHanded = false, trail = { 1.2, 5.6 } },
	Greatsword = { gripZ = 0.55, twoHanded = true, offhandZ = -0.65, trail = { 1.4, 7.6 } },
	Dagger = { gripZ = 0.0, twoHanded = false, dual = true, trail = { 0.6, 2.87 } },
	Mace = { gripZ = 0.35, twoHanded = true, offhandZ = -0.45, trail = { 3.2, 4.5 } },
}

-- Escala de toda una clase de arma (base y todas sus skins). Claude 9/11: el usuario pidió el
-- martillo más grande. Se escala el modelo ya construido alrededor del mango; el agarre se ajusta acá.
-- El alcance real sigue en WeaponData (se ajustó explícitamente, ver Notas/Equilibrio de armas).
WeaponBuilder.ClassScale = { Mace = 1.3 }
for id, s in WeaponBuilder.ClassScale do
	local info = WeaponBuilder.Info[id]
	if info then
		info.gripZ *= s
		if info.offhandZ then info.offhandZ *= s end
	end
end

local function scaleWeapon(container, handle, s)
	for _, d in container:GetDescendants() do
		if d:IsA("BasePart") then
			d.Size *= s
		elseif d:IsA("Weld") and d.Part0 == handle then
			d.C0 = CFrame.new(d.C0.Position * s) * d.C0.Rotation
			d.C1 = CFrame.new(d.C1.Position * s) * d.C1.Rotation
			if d.Part1 then d.Part1.CFrame = handle.CFrame * d.C0 * d.C1:Inverse() end
		elseif d:IsA("Attachment") then
			d.Position *= s
		elseif d:IsA("SpecialMesh") then
			d.Scale *= s
			d.Offset *= s
		end
	end
end

----------------------------------------------------------------------
-- Ayudantes de construcción
----------------------------------------------------------------------
local Builder = {}
Builder.__index = Builder

local function newBuilder(container, handle, palette, skin)
	return setmetatable({ container = container, handle = handle, palette = palette, skin = skin, count = 0 }, Builder)
end

-- Color y material según el rol de la pieza (y la skin)
function Builder:look(role)
	local p, skin = self.palette, self.skin
	-- Paleta propia del diseño de la skin (SkinDesigns): { Rol = { Color3, Material } }
	local own = self.designPalette and self.designPalette[role]
	if own then return own[1], own[2] end
	if role == "Glow" then
		return skin.trail or skin.accent or rgb(220, 220, 230), M.Neon
	elseif role == "Gem" then
		return skin.trail or skin.accent or rgb(235, 32, 46), M.Neon
	elseif role == "Edge" then
		local c = (skin.blade or p.blade)
		return c:Lerp(rgb(235, 235, 240), 0.35), M.Metal -- 10/11: vuelve al acabado de la 0.1
	elseif role == "Trim" then
		return skin.accent or rgb(150, 120, 70), M.Metal
	elseif role == "Leather" then
		return (p.grip):Lerp(rgb(0, 0, 0), 0.25), M.Leather
	end
	if role == "Blade" then
		if skin.blade then return skin.blade, skin.material or p.bladeMat end
		return p.blade, p.bladeMat
	elseif role == "Accent" then
		if skin.accent then return skin.accent, (skin.neonAccent and M.Neon) or skin.material or p.accentMat end
		return p.accent, p.accentMat
	elseif role == "Grip" then
		return p.grip, M.Fabric
	elseif role == "Wood" then
		return p.wood or p.grip, M.Wood
	elseif role == "Dark" then
		return rgb(24, 23, 26), M.Metal
	elseif role == "Rune" then
		return rgb(30, 30, 34), M.SmoothPlastic
	end
	return p.accent, p.accentMat
end

-- Crea una pieza en "cf" (espacio del mango) y la suelda al mango
function Builder:add(name, size, cf, role, kind, shape)
	local p
	if kind == "Wedge" then
		p = Instance.new("WedgePart")
	elseif kind == "CornerWedge" then
		p = Instance.new("CornerWedgePart")
	else
		p = Instance.new("Part")
		if shape then p.Shape = shape end
	end
	self.count += 1
	if name == "BladeTip" or name == "BladeBase" then
		name = name .. "Part"
	end
	p.Name = name
	p.Size = size
	local color, mat = self:look(role)
	p.Color = color
	p.Material = mat
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false -- las cajas de golpe no deben detectar armas
	p.Massless = true
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("Role", role)
	p.CFrame = self.handle.CFrame * cf
	p.Parent = self.container
	local w = Instance.new("Weld")
	w.Part0 = self.handle
	w.Part1 = p
	w.C0 = cf
	w.Parent = p
	return p
end

-- Barra recta entre dos puntos (side = Y, z = Z) del plano de la hoja
function Builder:bar(name, a, b, width, thick, role)
	local pa = Vector3.new(0, a[1], a[2])
	local pb = Vector3.new(0, b[1], b[2])
	local mid = (pa + pb) / 2
	local len = (pb - pa).Magnitude
	local cf = CFrame.lookAt(mid, pb, Vector3.xAxis)
	return self:add(name, Vector3.new(width, thick, len + width * 0.6), cf, role)
end

-- Curva hecha de tramos (lista de puntos {side, z}), con grosor que se afina
function Builder:curve(name, points, w0, w1, role, mirror)
	local sides = mirror and { 1, -1 } or { 1 }
	for _, s in sides do
		for i = 1, #points - 1 do
			local f = (i - 1) / math.max(#points - 2, 1)
			local w = w0 + (w1 - w0) * f
			local a = { points[i][1] * s, points[i][2] }
			local b = { points[i + 1][1] * s, points[i + 1][2] }
			self:bar(name, a, b, w * 0.75, w, role)
		end
	end
end

-- Punta de hoja (dos cuñas) que empieza en z0 y mide len
function Builder:tip(name, z0, len, width, thick, role, yOffset)
	local mid = z0 + len / 2
	local y = yOffset or 0
	self:add(name, Vector3.new(thick, width / 2, len), CFrame.new(0, y + width / 4, mid) * CFrame.Angles(0, math.pi, 0), role, "Wedge")
	self:add(name, Vector3.new(thick, width / 2, len), CFrame.new(0, y - width / 4, mid) * CFrame.Angles(math.pi, 0, 0), role, "Wedge")
	if z0 + len > (self.tipZ or 0) then
		self.tipZ = z0 + len
		self.tipPos = Vector3.new(0, y, z0 + len)
	end
end

-- Espiga cónica aproximada (dos cuñas en cruz) apuntando en "dir" (+1 = hacia +Z)
function Builder:spike(name, z0, len, base, role, dir)
	dir = dir or 1
	local mid = z0 + dir * len / 2
	local rot = dir > 0 and CFrame.Angles(0, math.pi, 0) or CFrame.identity
	self:add(name, Vector3.new(base * 0.5, base, len), CFrame.new(0, 0, mid) * rot, role, "Wedge")
	self:add(name, Vector3.new(base * 0.5, base, len), CFrame.new(0, 0, mid) * rot * CFrame.Angles(0, 0, math.pi / 2), role, "Wedge")
	if dir > 0 and (z0 + len) > (self.tipZ or 0) then
		self.tipZ = z0 + len
		self.tipPos = Vector3.new(0, 0, z0 + len)
	end
end

-- Anillo (aro) en el plano X-Y alrededor del eje Z
function Builder:ring(name, z, radius, thick, segments, role)
	for i = 0, segments - 1 do
		local a0 = (i / segments) * math.pi * 2
		local a1 = ((i + 1) / segments) * math.pi * 2
		local p0 = Vector3.new(math.cos(a0) * radius, math.sin(a0) * radius, z)
		local p1 = Vector3.new(math.cos(a1) * radius, math.sin(a1) * radius, z)
		local mid = (p0 + p1) / 2
		self:add(name, Vector3.new(thick, thick, (p1 - p0).Magnitude + thick * 0.5), CFrame.lookAt(mid, p1, Vector3.zAxis), role)
	end
end

----------------------------------------------------------------------
-- Ayudantes 3D (lote 6): piezas entre dos puntos, puntas, arcos, hojas curvas, brillo y partículas
-- Los puntos son Vector3 en espacio del mango; v(y, z) es un punto del plano de la hoja.
----------------------------------------------------------------------
local function v(y, z, x) return Vector3.new(x or 0, y, z) end
WeaponBuilder.v = v

-- Marco con -Z apuntando de a hacia b; X local = eje fino del arma (X del mango) si se puede
local function frame(a, b)
	local d = (b - a)
	local len = d.Magnitude
	d = len > 1e-4 and d / len or Vector3.zAxis
	local ref = math.abs(d.X) < 0.9 and Vector3.xAxis or Vector3.yAxis
	local vx = (ref - d * ref:Dot(d)).Unit
	local vz = -d
	local vy = vz:Cross(vx)
	return CFrame.fromMatrix((a + b) / 2, vx, vy, vz), len
end

-- Pieza recta de a a b. sx = grosor (X), sy = ancho (en el plano de la hoja)
function Builder:seg(name, a, b, sx, sy, role, extra, shape)
	local cf, len = frame(a, b)
	return self:add(name, Vector3.new(sx, sy, len + (extra or 0)), cf, role, nil, shape)
end

-- Punta plana (dos cuñas) con la base en a y el pico en b
function Builder:point(name, a, b, width, thick, role)
	local cf, len = frame(a, b)
	self:add(name, Vector3.new(thick, width / 2, len), cf * CFrame.new(0, width / 4, 0), role, "Wedge")
	self:add(name, Vector3.new(thick, width / 2, len), cf * CFrame.new(0, -width / 4, 0) * CFrame.Angles(0, 0, math.pi), role, "Wedge")
	if b.Z > 1.8 and b.Z > (self.tipZ or 0) and math.abs(b.Y) < 1.25 then
		self.tipZ = b.Z
		self.tipPos = b
	end
end

-- Púa de cuatro caras (dos puntas planas cruzadas)
function Builder:thorn(name, a, b, base, role)
	local cf, len = frame(a, b)
	for _, r in { 0, math.pi / 2 } do
		local c = cf * CFrame.Angles(0, 0, r)
		self:add(name, Vector3.new(base * 0.35, base / 2, len), c * CFrame.new(0, base / 4, 0), role, "Wedge")
		self:add(name, Vector3.new(base * 0.35, base / 2, len), c * CFrame.new(0, -base / 4, 0) * CFrame.Angles(0, 0, math.pi), role, "Wedge")
	end
end

-- Hoja (o mango) hecha de tramos por una lista de puntos {y, z} con anchos por punto.
-- Si tipLen > 0 termina en punta.
function Builder:strip(name, pts, widths, thick, role, tipLen, x)
	local first, last
	for i = 1, #pts - 1 do
		local a, b = v(pts[i][1], pts[i][2], x), v(pts[i + 1][1], pts[i + 1][2], x)
		local w = (widths[i] + (widths[i + 1] or widths[i])) / 2
		local p = self:seg(name, a, b, thick, w, role, w * 0.22)
		first = first or p
		last = p
	end
	if tipLen and tipLen > 0 then
		local a, b = v(pts[#pts - 1][1], pts[#pts - 1][2], x), v(pts[#pts][1], pts[#pts][2], x)
		local d = (b - a).Unit
		self:point(name .. "Tip", b - d * 0.02, b + d * tipLen, widths[#widths] or widths[#widths - 1], thick, role)
	end
	return first, last
end

-- Arco en el plano (u, w) alrededor de c, de ángulo a0 a a1 (radianes)
function Builder:arc(name, c, u, w, radius, a0, a1, segments, sx, sy, role)
	local prev
	for i = 0, segments do
		local t = a0 + (a1 - a0) * i / segments
		local p = c + u * math.cos(t) * radius + w * math.sin(t) * radius
		if prev then self:seg(name, prev, p, sx, sy, role, math.max(sx, sy) * 0.5) end
		prev = p
	end
end

-- Cilindro a lo largo de Z centrado en z (diámetro d)
function Builder:cyl(name, z, len, d, role, y)
	return self:add(name, Vector3.new(len, d, d), CFrame.new(0, y or 0, z) * CFrame.Angles(0, math.pi / 2, 0), role, nil, Enum.PartType.Cylinder)
end

-- Bola (gema, remache, pomo)
function Builder:ball(name, pos, d, role)
	return self:add(name, Vector3.new(d, d, d), CFrame.new(pos), role, nil, Enum.PartType.Ball)
end

-- Mango envuelto: anillos inclinados de z0 a z1
function Builder:wrap(z0, z1, count, d, role, tilt)
	for i = 0, count - 1 do
		local z = z0 + (z1 - z0) * (i + 0.5) / count
		self:add("Wrap", Vector3.new(d, d, (z1 - z0) / count * 0.8), CFrame.new(0, 0, z) * CFrame.Angles(0, 0, math.rad(45)) * CFrame.Angles(math.rad(tilt or 12), 0, 0), role)
	end
end

-- Una sola luz por arma (débil)
function Builder:light(pos, color, range, brightness)
	if self.lit then return end
	self.lit = true
	local att = Instance.new("Attachment")
	att.Name = "GlowLight"
	att.Position = pos
	att.Parent = self.handle
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range or 6
	l.Brightness = brightness or 0.8
	l.Shadows = false
	l.Parent = att
end

-- Partículas suaves a lo largo de la hoja (Embers, Smoke, Frost, Wisps)
local EMIT = {
	Embers = { tex = "rbxasset://textures/particles/fire_sparks_main.dds", size = { 0.12, 0 }, life = { 0.5, 1 }, rate = 8, speed = { 0.4, 1.2 }, accel = Vector3.new(0, 2, 0), light = 1 },
	Smoke = { tex = "rbxasset://textures/particles/smoke_main.dds", size = { 0.5, 1.4 }, life = { 0.8, 1.6 }, rate = 7, speed = { 0.1, 0.4 }, accel = Vector3.new(0, 0.8, 0), light = 0, trans = 0.6 },
	Frost = { tex = "rbxasset://textures/particles/sparkles_main.dds", size = { 0.18, 0 }, life = { 0.6, 1.1 }, rate = 6, speed = { 0.1, 0.4 }, accel = Vector3.new(0, -0.6, 0), light = 1 },
	Wisps = { tex = "rbxasset://textures/particles/smoke_main.dds", size = { 0.3, 0.9 }, life = { 0.6, 1.2 }, rate = 9, speed = { 0.2, 0.6 }, accel = Vector3.new(0, 1.2, 0), light = 1, trans = 0.45 },
}
function Builder:emit(kind, z0, z1, color)
	local e = EMIT[kind]
	if not e or self.emitted then return end
	self.emitted = true
	local p = Instance.new("ParticleEmitter")
	p.Name = "SkinParticles"
	p.Texture = e.tex
	p.Color = ColorSequence.new(color)
	p.LightEmission = e.light
	p.Size = NumberSequence.new(e.size[1], e.size[2])
	p.Transparency = NumberSequence.new(e.trans or 0.2, 1)
	p.Lifetime = NumberRange.new(e.life[1], e.life[2])
	p.Rate = e.rate
	p.Speed = NumberRange.new(e.speed[1], e.speed[2])
	p.SpreadAngle = Vector2.new(180, 180)
	p.Acceleration = e.accel
	p.Shape = Enum.ParticleEmitterShape.Box
	p.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	-- caja de emisión: el largo de la hoja
	local box = Instance.new("Part")
	box.Name = "ParticleVolume"
	box.Size = Vector3.new(0.1, 0.3, math.max(0.2, z1 - z0))
	box.Transparency = 1
	box.CanCollide = false
	box.CanQuery = false
	box.CanTouch = false
	box.Massless = true
	box.CastShadow = false
	box.CFrame = self.handle.CFrame * CFrame.new(0, 0, (z0 + z1) / 2)
	box.Parent = self.container
	local w = Instance.new("Weld")
	w.Part0 = self.handle
	w.Part1 = box
	w.C0 = CFrame.new(0, 0, (z0 + z1) / 2)
	w.Parent = box
	p.Parent = box
end

local function addTrailAttachments(part, z0, z1, handleZ, tipPos, basePos)
	-- z0/z1 y tipPos/basePos en espacio del mango; se convierten al espacio de la pieza
	local bPos = basePos or Vector3.new(0, 0, z0)
	local tPos = tipPos or Vector3.new(0, 0, z1)
	local base = Instance.new("Attachment")
	base.Name = "BladeBase"
	base.Position = Vector3.new(bPos.X, bPos.Y, bPos.Z - handleZ)
	base.Parent = part
	local tip = Instance.new("Attachment")
	tip.Name = "BladeTip"
	tip.Position = Vector3.new(tPos.X, tPos.Y, tPos.Z - handleZ)
	tip.Parent = part
	local trail = Instance.new("Trail")
	trail.Name = "SwingTrail"
	trail.Attachment0 = base
	trail.Attachment1 = tip
	trail.Lifetime = 0.18
	trail.MinLength = 0.05
	trail.LightEmission = 0.35
	trail.LightInfluence = 0.4
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	trail.Enabled = false -- lo encienden los clientes durante los golpes
	trail.Parent = part
	return trail
end

----------------------------------------------------------------------
-- Diseños (inspirados en el arte conceptual: Espada, Estoque, Espadón, Dagas, Maza)
----------------------------------------------------------------------
local Designs = {}

-- ESPADA: hoja recta de caballero con acanaladura, guarda en cruz simple, cuero con vueltas, pomo de disco, biseles y desgaste
function Designs.Sword(b)
	local h = b.handle
	h.Size = Vector3.new(0.24, 0.26, 1.25)
	-- Cuero con vueltas inclinadas y anillos de sujeción
	b:wrap(-0.54, 0.54, 6, 0.28, "Leather", 16)
	for _, z in { -0.58, 0.0, 0.58 } do
		b:add("GripRing", Vector3.new(0.27, 0.30, 0.05), CFrame.new(0, 0, z), "Dark")
	end
	-- Pomo de disco con bisel central y remache de espiga
	b:add("PommelNeck", Vector3.new(0.20, 0.22, 0.14), CFrame.new(0, 0, -0.68), "Accent")
	b:add("PommelDisc", Vector3.new(0.22, 0.46, 0.46), CFrame.new(0, 0, -0.88), "Accent", nil, Enum.PartType.Cylinder)
	b:add("PommelHub", Vector3.new(0.28, 0.26, 0.26), CFrame.new(0, 0, -0.88), "Dark", nil, Enum.PartType.Cylinder)
	b:add("PeenBlock", Vector3.new(0.14, 0.14, 0.08), CFrame.new(0, 0, -1.12), "Accent")
	-- Guarda en cruz simple con brazos levemente ensanchados en las puntas y escudete central
	b:add("GuardCore", Vector3.new(0.28, 0.44, 0.24), CFrame.new(0, 0, 0.78), "Accent")
	b:add("Crossguard", Vector3.new(0.20, 1.56, 0.16), CFrame.new(0, 0, 0.78), "Accent")
	for _, s in { 1, -1 } do
		b:add("QuillonTip", Vector3.new(0.22, 0.18, 0.22), CFrame.new(0, 0.82 * s, 0.78) * CFrame.Angles(math.rad(12 * s), 0, 0), "Accent")
		b:add("QuillonCap", Vector3.new(0.24, 0.06, 0.24), CFrame.new(0, 0.91 * s, 0.78), "Dark")
		b:add("Ecusson", Vector3.new(0.05, 0.22, 0.28), CFrame.new(0.11 * s, 0, 0.92), "Accent")
		b:add("GuardRivet", Vector3.new(0.07, 0.07, 0.07), CFrame.new(0.14 * s, 0, 0.78), "Dark", nil, Enum.PartType.Ball)
	end
	-- Ricasso corto junto a la guarda
	b:add("Ricasso", Vector3.new(0.13, 0.38, 0.26), CFrame.new(0, 0, 1.02), "Accent")
	-- Hoja recta con doble filo biselado y acanaladura (fuller)
	local blade = b:add("Blade", Vector3.new(0.09, 0.36, 3.50), CFrame.new(0, 0, 0.96 + 1.75), "Blade")
	b:tip("BladePoint", 4.46, 0.64, 0.36, 0.09, "Blade")
	-- Acanaladura oscura en los dos primeros tercios y nervio hacia la punta
	b:add("Fuller", Vector3.new(0.105, 0.10, 2.50), CFrame.new(0, 0, 1.10 + 1.25), "Dark")
	b:add("BladeRidge", Vector3.new(0.105, 0.05, 0.90), CFrame.new(0, 0, 3.60 + 0.45), "Edge")
	for _, s in { 1, -1 } do
		b:add("EdgeBevel", Vector3.new(0.055, 0.05, 3.46), CFrame.new(0, 0.175 * s, 0.96 + 1.73), "Edge")
	end
	-- Marcas de uso y mellas sutiles en el filo
	b:add("WearMark", Vector3.new(0.098, 0.04, 0.22), CFrame.new(0, 0.14, 2.15) * CFrame.Angles(math.rad(18), 0, 0), "Dark")
	b:add("WearMark", Vector3.new(0.098, 0.035, 0.18), CFrame.new(0, -0.13, 3.05) * CFrame.Angles(math.rad(-22), 0, 0), "Dark")
	b:add("WearMark", Vector3.new(0.098, 0.03, 0.15), CFrame.new(0, 0.12, 3.85) * CFrame.Angles(math.rad(14), 0, 0), "Dark")
	return blade, 0.96 + 1.75
end

-- ESTOQUE: hoja muy fina y larga, cazoleta de cesta, gavilanes rectos
function Designs.Rapier(b)
	local h = b.handle
	h.Size = Vector3.new(0.22, 0.22, 1.1)
	for _, z in { -0.36, -0.12, 0.12, 0.36 } do
		b:add("Wire", Vector3.new(0.25, 0.25, 0.05), CFrame.new(0, 0, z), "Accent")
	end
	b:add("Pommel", Vector3.new(0.32, 0.32, 0.36), CFrame.new(0, 0, -0.72), "Accent", nil, Enum.PartType.Ball)
	-- Cesta: aro de base y meridianos
	local cz, r = 0.62, 0.58
	b:ring("BasketRim", cz, r, 0.06, 12, "Accent")
	for k = 0, 3 do
		local ang = k * math.pi / 4
		local d = Vector3.new(math.cos(ang), math.sin(ang), 0)
		local prev = nil
		for i = 0, 8 do
			local th = -math.pi / 2 + i * math.pi / 8
			local p = d * (math.sin(th) * r) + Vector3.new(0, 0, cz + math.cos(th) * r * 0.75)
			if prev then
				local mid = (prev + p) / 2
				b:add("Basket", Vector3.new(0.05, 0.05, (p - prev).Magnitude + 0.03), CFrame.lookAt(mid, p, Vector3.zAxis), "Accent")
			end
			prev = p
		end
	end
	-- Gavilanes rectos con remates
	b:add("Quillon", Vector3.new(0.09, 1.5, 0.09), CFrame.new(0, 0, cz + 0.1), "Accent")
	b:add("QuillonEnd", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0.78, cz + 0.16), "Accent", nil, Enum.PartType.Ball)
	b:add("QuillonEnd", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, -0.78, cz + 0.04), "Accent", nil, Enum.PartType.Ball)
	-- Hoja
	local blade = b:add("Blade", Vector3.new(0.06, 0.11, 4.4), CFrame.new(0, 0, 1.1 + 2.2), "Blade")
	b:tip("BladeTip", 5.3, 0.3, 0.11, 0.06, "Blade")
	-- Lote 6: arista central brillante, collar de la hoja y remate del pomo
	b:add("Ridge", Vector3.new(0.075, 0.025, 4.2), CFrame.new(0, 0, 1.15 + 2.1), "Edge")
	b:add("BladeCollar", Vector3.new(0.12, 0.2, 0.14), CFrame.new(0, 0, 1.12), "Accent")
	b:add("PommelCap", Vector3.new(0.12, 0.12, 0.14), CFrame.new(0, 0, -0.92), "Accent")
	return blade, 1.1 + 2.2
end

-- ESPADÓN: coloso de hierro forjado a dos manos (masa estilo Dragonslayer y silueta de cuchilla pesada con ojal y muesca)
function Designs.Greatsword(b)
	local h = b.handle
	h.Size = Vector3.new(0.32, 0.34, 2.30)
	-- Empuñadura larga a dos manos con vueltas de cuero y anillos de hierro
	b:wrap(-1.02, 1.02, 8, 0.36, "Leather", 18)
	for _, z in { -0.95, -0.32, 0.32, 0.95 } do
		b:add("GripRing", Vector3.new(0.38, 0.40, 0.08), CFrame.new(0, 0, z), "Dark")
	end
	-- Pomo de contrapeso macizo con facetas y espiga
	b:add("PommelNeck", Vector3.new(0.26, 0.28, 0.24), CFrame.new(0, 0, -1.25), "Accent")
	b:add("PommelRing", Vector3.new(0.56, 0.56, 0.10), CFrame.new(0, 0, -1.38), "Dark")
	b:add("Pommel", Vector3.new(0.54, 0.54, 0.54), CFrame.new(0, 0, -1.58), "Accent", nil, Enum.PartType.Ball)
	b:add("PommelSpike", Vector3.new(0.18, 0.18, 0.22), CFrame.new(0, 0, -1.90), "Accent")
	-- Guarda pesada de herrero con topes cuadrados y abrazadera de hoja (ricasso)
	b:add("Guard", Vector3.new(0.38, 2.68, 0.32), CFrame.new(0, 0, 1.26), "Accent")
	for _, s in { 1, -1 } do
		b:add("GuardCap", Vector3.new(0.44, 0.16, 0.40), CFrame.new(0, 1.24 * s, 1.26), "Dark")
		b:add("GuardBall", Vector3.new(0.46, 0.46, 0.46), CFrame.new(0, 1.44 * s, 1.26), "Accent", nil, Enum.PartType.Ball)
		b:add("Langet", Vector3.new(0.07, 0.52, 0.72), CFrame.new(0.16 * s, 0, 1.72), "Accent")
		b:add("LangetRivet", Vector3.new(0.10, 0.10, 0.10), CFrame.new(0.20 * s, 0, 1.92), "Dark", nil, Enum.PartType.Ball)
	end
	b:add("Ricasso", Vector3.new(0.36, 0.92, 0.44), CFrame.new(0, 0, 1.56), "Accent")
	-- Losa de acero colosal (ancho 1.56, grosor 0.28, punta en z = 7.60)
	local blade = b:add("Blade", Vector3.new(0.28, 1.56, 5.12), CFrame.new(0, 0, 1.38 + 2.56), "Blade")
	b:tip("BladePoint", 6.50, 1.10, 1.56, 0.28, "Blade")
	-- Ojal circular oscuro cerca de la base y muesca lateral de verdugo
	b:add("SlabEyelet", Vector3.new(0.30, 0.42, 0.42), CFrame.new(0, 0, 2.25), "Dark", nil, Enum.PartType.Cylinder)
	b:add("EyeletRim", Vector3.new(0.29, 0.52, 0.52), CFrame.new(0, 0, 2.25), "Accent", nil, Enum.PartType.Cylinder)
	b:add("SpineNotch", Vector3.new(0.31, 0.34, 0.38), CFrame.new(0, -0.66, 2.85), "Dark")
	-- Acanaladura ancha grabada con runas entre el ojal y el último tercio
	b:add("Fuller", Vector3.new(0.30, 0.38, 3.20), CFrame.new(0, 0, 2.65 + 1.60), "Rune")
	for i = 0, 5 do
		local z = 2.85 + i * 0.48
		b:add("Rune", Vector3.new(0.32, 0.22, 0.06), CFrame.new(0, 0, z) * CFrame.Angles(math.rad((i % 2 == 0) and 35 or -35), 0, 0), "Accent")
		b:add("Rune", Vector3.new(0.32, 0.06, 0.20), CFrame.new(0, (i % 2 == 0) and 0.07 or -0.07, z + 0.10), "Accent")
	end
	-- Filos biselados anchos y brillantes a ambos lados de la losa
	for _, s in { 1, -1 } do
		b:add("EdgeBevel", Vector3.new(0.16, 0.14, 5.06), CFrame.new(0, 0.74 * s, 1.42 + 2.53), "Edge")
	end
	return blade, 1.38 + 2.56
end

-- DAGAS: hoja dentada, guarda con púas y pomo en punta
function Designs.Dagger(b)
	local h = b.handle
	h.Size = Vector3.new(0.22, 0.22, 0.85)
	for _, z in { -0.28, -0.1, 0.08, 0.26 } do
		b:add("Wrap", Vector3.new(0.25, 0.25, 0.1), CFrame.new(0, 0, z) * CFrame.Angles(0, 0, math.rad(20)), "Grip")
	end
	b:add("PommelCap", Vector3.new(0.26, 0.26, 0.12), CFrame.new(0, 0, -0.48), "Accent")
	b:spike("PommelSpike", -0.54, 0.4, 0.22, "Accent", -1)
	-- Guarda con púas
	b:add("Guard", Vector3.new(0.24, 0.78, 0.2), CFrame.new(0, 0, 0.52), "Accent")
	b:bar("GuardSpike", { 0.35, 0.55 }, { 0.72, 0.42 }, 0.07, 0.1, "Accent")
	b:bar("GuardSpike", { -0.35, 0.55 }, { -0.72, 0.42 }, 0.07, 0.1, "Accent")
	b:bar("GuardSpike", { 0.3, 0.6 }, { 0.48, 0.85 }, 0.06, 0.08, "Accent")
	b:bar("GuardSpike", { -0.3, 0.6 }, { -0.48, 0.85 }, 0.06, 0.08, "Accent")
	-- Hoja
	local blade = b:add("Blade", Vector3.new(0.08, 0.34, 1.75), CFrame.new(0, 0, 0.62 + 0.875), "Blade")
	b:add("BladeRidge", Vector3.new(0.1, 0.05, 1.6), CFrame.new(0, 0, 0.62 + 0.85), "Accent")
	b:tip("BladeTip", 2.37, 0.5, 0.34, 0.08, "Blade")
	-- Dientes en los filos (cuñas hacia atrás)
	for i = 0, 3 do
		local z = 1.0 + i * 0.32
		for _, s in { 1, -1 } do
			local cf = CFrame.new(0, s * 0.22, z) * CFrame.Angles(s > 0 and 0 or math.pi, 0, 0)
			b:add("Serration", Vector3.new(0.07, 0.12, 0.2), cf, "Blade", "Wedge")
		end
	end
	-- Lote 6: filos biselados, remaches y collar del pomo
	b:add("EdgeBevel", Vector3.new(0.06, 0.04, 1.0), CFrame.new(0, 0.15, 0.62 + 0.45), "Edge")
	b:add("EdgeBevel", Vector3.new(0.06, 0.04, 1.0), CFrame.new(0, -0.15, 0.62 + 0.45), "Edge")
	for _, s in { 1, -1 } do
		b:add("GuardRivet", Vector3.new(0.07, 0.07, 0.07), CFrame.new(0.13 * s, 0.22, 0.52), "Dark", nil, Enum.PartType.Ball)
		b:add("GuardRivet", Vector3.new(0.07, 0.07, 0.07), CFrame.new(0.13 * s, -0.22, 0.52), "Dark", nil, Enum.PartType.Ball)
	end
	b:add("PommelCollar", Vector3.new(0.28, 0.28, 0.05), CFrame.new(0, 0, -0.41), "Dark")
	return blade, 0.62 + 0.875
end

-- MAZA (martillo de guerra): mango largo de madera, cabeza de bloque con bandas y remaches
function Designs.Mace(b)
	local h = b.handle
	h.Size = Vector3.new(0.32, 0.32, 1.4)
	for _, z in { -0.5, -0.25, 0, 0.25, 0.5 } do
		b:add("Wrap", Vector3.new(0.35, 0.35, 0.13), CFrame.new(0, 0, z) * CFrame.Angles(0, 0, math.rad(25)), "Grip")
	end
	b:add("Pommel", Vector3.new(0.4, 0.4, 0.2), CFrame.new(0, 0, -0.8), "Accent")
	b:spike("PommelSpike", -0.9, 0.35, 0.3, "Accent", -1)
	-- Mango de madera
	b:add("Haft", Vector3.new(0.28, 0.28, 2.6), CFrame.new(0, 0, 0.7 + 1.3), "Wood")
	b:add("Langet", Vector3.new(0.33, 0.33, 0.7), CFrame.new(0, 0, 2.95), "Accent")
	b:add("Band", Vector3.new(0.36, 0.36, 0.08), CFrame.new(0, 0, 2.6), "Dark")
	-- Cabeza (eje a lo largo de Y)
	local head = b:add("Head", Vector3.new(1.05, 2.0, 1.1), CFrame.new(0, 0, 3.75), "Blade")
	b:add("HeadBand", Vector3.new(1.13, 0.2, 1.18), CFrame.new(0, 0.55, 3.75), "Accent")
	b:add("HeadBand", Vector3.new(1.13, 0.2, 1.18), CFrame.new(0, -0.55, 3.75), "Accent")
	b:add("Face", Vector3.new(1.15, 0.14, 1.2), CFrame.new(0, 1.03, 3.75), "Accent")
	b:add("BackPeen", Vector3.new(0.7, 0.45, 0.7), CFrame.new(0, -1.22, 3.75), "Accent")
	b:add("BackPeenTip", Vector3.new(0.45, 0.25, 0.45), CFrame.new(0, -1.55, 3.75), "Accent")
	b:add("TopCap", Vector3.new(0.5, 0.5, 0.2), CFrame.new(0, 0, 4.4), "Accent")
	-- Remaches en las caras
	for _, y in { 0.25, -0.25 } do
		for _, x in { 0.54, -0.54 } do
			b:add("Rivet", Vector3.new(0.12, 0.12, 0.12), CFrame.new(x, y, 3.75), "Dark", nil, Enum.PartType.Ball)
		end
	end
	-- Lote 6: lengüetas de hierro por el mango, más bandas, púa superior y tachas en las bandas
	for _, s in { 1, -1 } do
		b:add("HaftLanget", Vector3.new(0.06, 0.1, 0.9), CFrame.new(0.15 * s, 0, 2.55), "Accent")
		b:add("HaftLanget", Vector3.new(0.1, 0.06, 0.9), CFrame.new(0, 0.15 * s, 2.55), "Accent")
		for _, y in { 0.55, -0.55 } do
			b:add("BandStud", Vector3.new(0.1, 0.1, 0.1), CFrame.new(0.58 * s, y, 3.75), "Dark", nil, Enum.PartType.Ball)
		end
	end
	for _, z in { 1.2, 1.9 } do b:add("HaftBand", Vector3.new(0.33, 0.33, 0.07), CFrame.new(0, 0, z), "Dark") end
	b:spike("TopSpike", 4.5, 0.45, 0.3, "Accent", 1)
	return head, 3.75
end

----------------------------------------------------------------------
-- Construcción pública
----------------------------------------------------------------------
local function paletteFor(weaponId)
	return NATIVE[weaponId] or NATIVE.Sword
end

-- Construye las piezas dentro de "container" (Tool o Model). Devuelve el mango.
local function buildInto(container, weaponId, skinId)
	local skin = Skins.Data[skinId or "Default"] or Skins.Data.Default
	if skin.comingSoon or (skin.weapon and skin.weapon ~= weaponId) then skin = Skins.Data.Default end
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.CFrame = CFrame.identity
	handle.Parent = container
	local b = newBuilder(container, handle, paletteFor(weaponId), skin)
	local color, mat = b:look("Grip")
	handle.Color = color
	handle.Material = mat
	handle:SetAttribute("Role", "Grip")

	local design = Designs[weaponId] or Designs.Sword
	local mainPart, mainZ
	local custom = skin.design and SkinDesigns[skin.design]
 local spec = not custom and skin.design and Skins.Designs[skin.design]
 if custom then
		b.designPalette = custom.palette
		local gc, gm = b:look("Grip")
		handle.Color = gc
		handle.Material = gm
		local ok, err = pcall(custom.build, b, v)
		-- la estela se ancla al mango (siempre alineado con el arma); las piezas pueden ir giradas
		mainPart, mainZ = handle, 0
		if not ok then
			-- si un diseño falla, el arma sale con su modelo base en vez de romperse
			warn(("[WeaponBuilder] Falló el diseño %s de la skin %s: %s"):format(tostring(skin.design), tostring(skinId), tostring(err)))
			for _, c in container:GetChildren() do if c ~= handle then c:Destroy() end end
			for _, c in handle:GetChildren() do c:Destroy() end
			b.designPalette, b.count, b.lit, b.emitted = nil, 0, nil, nil
			b.skin = Skins.Data.Default
			handle.Color, handle.Material = b:look("Grip")
			mainPart, mainZ = design(b)
		end
		if RunService:IsStudio() and b.count > 110 then
			warn(("[WeaponBuilder] La skin %s usa %d piezas (máximo 110)"):format(tostring(skinId), b.count))
		end
	elseif spec then
		handle.Size = Vector3.new(table.unpack(spec.handle))
		for _, part in spec.parts do
			b:add(part.n, Vector3.new(table.unpack(part.size)), CFrame.new(table.unpack(part.pos)) * CFrame.Angles(table.unpack(part.rot)), part.role, part.kind)
		end
		mainPart, mainZ = handle, spec.mainZ
	else
		mainPart, mainZ = design(b)
	end
	local info = WeaponBuilder.Info[weaponId] or WeaponBuilder.Info.Sword
	local trail = addTrailAttachments(mainPart, info.trail[1], info.trail[2], mainZ, b.tipPos, b.basePos)
	if skin.trail then
		trail.Color = ColorSequence.new(Color3.new(1, 1, 1), skin.trail)
	else
		trail.Color = ColorSequence.new(Color3.fromRGB(235, 235, 240), Color3.fromRGB(150, 150, 160))
	end
	local scale = WeaponBuilder.ClassScale[weaponId]
	if scale and scale ~= 1 then scaleWeapon(container, handle, scale) end
	return handle
end

local function newTool(weaponId)
	local def = WeaponData.get(weaponId)
	local info = WeaponBuilder.Info[weaponId] or WeaponBuilder.Info.Sword
	local tool = Instance.new("Tool")
	tool.Name = def.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ManualActivationOnly = true
	tool.GripPos = Vector3.new(0, 0, info.gripZ)
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)
	tool:SetAttribute("WeaponId", weaponId)
	return tool
end

-- 1) Modelo propio en ReplicatedStorage/Weapons o ServerStorage/Weapons (unificado para Tool y Model)
local function populateFromStorage(container, weaponId)
	local folder = ReplicatedStorage:FindFirstChild("Weapons")
	local src = folder and folder:FindFirstChild(weaponId)
	if not src and RunService:IsServer() then
		local ServerStorage = game:GetService("ServerStorage")
		local sFolder = ServerStorage:FindFirstChild("Weapons")
		src = sFolder and sFolder:FindFirstChild(weaponId)
	end
	if not src then return nil end
	local copy = src:Clone()
	local handle = copy:FindFirstChild("Handle") or (copy:IsA("Model") and copy.PrimaryPart) or copy:FindFirstChildWhichIsA("BasePart")
	if not handle then
		warn("[WeaponBuilder] El modelo", weaponId, "no tiene Handle ni PrimaryPart")
		copy:Destroy()
		return nil
	end
	handle.Name = "Handle"
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			d.Anchored = false
			if not d:GetAttribute("Role") then
				d:SetAttribute("Role", d == handle and "Grip" or "Blade")
			end
		end
	end
	for _, child in copy:GetChildren() do
		child.Parent = container
	end
	copy:Destroy()
	if not container:FindFirstChild("BladeBase", true) or not container:FindFirstChild("BladeTip", true) then
		local info = WeaponBuilder.Info[weaponId] or WeaponBuilder.Info.Sword
		addTrailAttachments(handle, info.trail[1], info.trail[2], 0)
	end
	return handle
end

-- 2) Malla por ID (Assets.Models.Weapons o WeaponMeshes) unificada para Tool y Model
local function populateFromMesh(container, weaponId, skinId)
	local skin = Skins.Data[skinId or "Default"] or Skins.Data.Default
	local meshSpec
	local wmModule = ReplicatedStorage:FindFirstChild("WeaponMeshes")
	if wmModule then
		local ok, wm = pcall(require, wmModule)
		if ok and type(wm) == "table" then
			local key = (skin and skin.design) or weaponId
			meshSpec = wm[key] or ((not skin or skinId == "Default") and wm[weaponId]) or nil
		end
	end
	if not meshSpec and (not skin or skinId == "Default") then
		meshSpec = Assets.Models and Assets.Models.Weapons and Assets.Models.Weapons[weaponId]
	end
	local meshId = meshSpec and Assets.toContent(meshSpec.MeshId)
	if not meshId then return nil end
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = meshSpec.HandleSize or Vector3.new(0.3, 0.3, 1.2)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle:SetAttribute("Role", "Grip")
	handle.Parent = container
	local body = Instance.new("Part")
	body.Name = "Blade"
	body.Size = meshSpec.PartSize or Vector3.new(1, 1, 4)
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.Massless = true
	body.Color = (skin and skin.blade) or paletteFor(weaponId).blade
	body.Material = (skin and skin.material) or paletteFor(weaponId).bladeMat
	body:SetAttribute("Role", "Blade")
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = meshId
	if meshSpec.Scale then mesh.Scale = meshSpec.Scale end
	local tex = Assets.toContent(meshSpec.TextureId)
	if tex then mesh.TextureId = tex end
	mesh.Parent = body
	body.Parent = container
	local w = Instance.new("Weld")
	w.Part0 = handle
	w.Part1 = body
	if meshSpec.Offset then w.C0 = meshSpec.Offset end
	w.Parent = body
	local info = WeaponBuilder.Info[weaponId] or WeaponBuilder.Info.Sword
	local tipPos = meshSpec.BladeTip or (meshSpec.TipZ and Vector3.new(0, 0, meshSpec.TipZ)) or nil
	local trail = addTrailAttachments(handle, info.trail[1], info.trail[2], 0, tipPos, meshSpec.BladeBase)
	if skin and skin.trail then
		trail.Color = ColorSequence.new(Color3.new(1, 1, 1), skin.trail)
	end
	local scale = WeaponBuilder.ClassScale[weaponId]
	if scale and scale ~= 1 then scaleWeapon(container, handle, scale) end
	return handle
end

-- Unifica la construcción para que build() y buildModel() den exactamente el mismo modelo (C4)
local function populateWeapon(container, weaponId, skinId)
	local resolvedSkinId = skinId or "Default"
	local skin = Skins.Data[resolvedSkinId]
	local isDefault = (not skin or resolvedSkinId == "Default")
	local handle = (isDefault and populateFromStorage(container, weaponId))
		or populateFromMesh(container, weaponId, resolvedSkinId)
		or buildInto(container, weaponId, resolvedSkinId)
	return handle
end

-- Tool que empuña el personaje
function WeaponBuilder.build(weaponId, skinId)
	local resolvedSkinId = skinId or "Default"
	local tool = newTool(weaponId)
	populateWeapon(tool, weaponId, resolvedSkinId)
	tool:SetAttribute("SkinId", resolvedSkinId)
	return tool
end

-- Modelo suelto (vistas previas de la tienda y auras). Devuelve Model con PrimaryPart = Handle
function WeaponBuilder.buildModel(weaponId, skinId)
	local resolvedSkinId = skinId or "Default"
	local model = Instance.new("Model")
	model.Name = weaponId
	local handle = populateWeapon(model, weaponId, resolvedSkinId)
	model.PrimaryPart = handle
	model:SetAttribute("WeaponId", weaponId)
	model:SetAttribute("SkinId", resolvedSkinId)
	return model
end

-- Segunda daga en la mano izquierda (Dagas)
function WeaponBuilder.addOffhand(char, weaponId, skinId)
	local old = char:FindFirstChild("OffhandWeapon")
	if old then old:Destroy() end
	local info = WeaponBuilder.Info[weaponId]
	if not info or not info.dual then return end
	local hand = char:FindFirstChild("LeftHand")
	if not hand then return end
	local resolvedSkinId = skinId or "Default"
	local model = Instance.new("Model")
	model.Name = "OffhandWeapon"
	local handle = populateWeapon(model, weaponId, resolvedSkinId)
	model.PrimaryPart = handle
	model:SetAttribute("WeaponId", weaponId)
	model:SetAttribute("SkinId", resolvedSkinId)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored = false end
	end
	-- Misma orientación que la mano derecha (como el agarre de un Tool)
	local grip = Instance.new("Weld")
	grip.Name = "OffhandGrip"
	grip.Part0 = hand
	grip.Part1 = handle
	local att = hand:FindFirstChild("LeftGripAttachment")
	grip.C0 = att and att.CFrame or (CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0))
	grip.C1 = CFrame.fromMatrix(Vector3.new(0, 0, info.gripZ), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1))
	grip.Parent = handle
	model.Parent = char
end

return WeaponBuilder
