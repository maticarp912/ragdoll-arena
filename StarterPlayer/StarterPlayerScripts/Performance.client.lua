-- LocalScript: StarterPlayerScripts/Performance
-- 11/11/2026: estrategias de rendimiento del lado del cliente (todo local: no cambia nada para los demás).
--   1. Luces lejanas apagadas: con iluminación Future cada PointLight cuesta en la GPU aunque esté lejos.
--      Se prenden solo las que están a menos de LightRange de la cámara (se revisa 4 veces por segundo).
--   2. Piezas chicas sin sombra: botellas, tejas, adornos y accesorios no proyectan sombra (casi no se nota
--      y es de lo más caro del mapa de sombras).
--   3. Efectos reducidos (Ajustes → «Efectos visuales: Reducidos», atributo OptFx = 0): sin sombras globales,
--      sin desenfoque de profundidad ni rayos de sol, bloom más suave y luces a menor distancia.
--   4. NPC de la ciudad: sus brazos y piernas se animan acá (antes el servidor los movía 60 veces por segundo
--      y mandaba cada cambio a todos los jugadores). Solo se animan los cercanos.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

local PERF = {
	LightRange = 160,          -- studs desde la cámara con efectos completos
	LightRangeLow = 90,        -- con efectos reducidos
	LightCheck = 0.25,         -- s entre revisiones de luces
	SmallPart = 3,             -- piezas cuyo lado más grande mide menos que esto no hacen sombra
	NpcAnimRange = 120,        -- studs: NPC de la ciudad más lejos no mueven brazos ni piernas
	NpcSwing = 0.28, NpcSpeed = 5,
}

local function lowFx() return player:GetAttribute("OptFx") == 0 end

----------------------------------------------------------------------
-- 1 y 2. Luces y sombras
----------------------------------------------------------------------
local lights = {}       -- [luz] = true
local forcedOff = {}    -- [luz] = true: la apagamos nosotros (las que apagó el juego no se tocan)

local function track(obj)
	if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
		lights[obj] = true
	elseif obj:IsA("BasePart") and obj.CastShadow then
		local s = obj.Size
		if math.max(s.X, s.Y, s.Z) < PERF.SmallPart or obj:FindFirstAncestorOfClass("Accessory") then
			obj.CastShadow = false
		end
	end
end

-- El mapa se arma en el servidor de a poco: se revisa todo una vez y después lo que vaya apareciendo
task.defer(function()
	for _, obj in workspace:GetDescendants() do track(obj) end
end)
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Light") or obj:IsA("BasePart") then task.defer(track, obj) end
end)
workspace.DescendantRemoving:Connect(function(obj)
	lights[obj] = nil
	forcedOff[obj] = nil
end)

local lightAcc = 0
RunService.Heartbeat:Connect(function(dt)
	lightAcc += dt
	if lightAcc < PERF.LightCheck then return end
	lightAcc = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	local range = lowFx() and PERF.LightRangeLow or PERF.LightRange
	for light in lights do
		local part = light.Parent
		if part and part:IsA("BasePart") then
			local near = (part.Position - camPos).Magnitude <= range + light.Range
			if near and forcedOff[light] then
				forcedOff[light] = nil
				light.Enabled = true
			elseif not near and light.Enabled then
				forcedOff[light] = true
				light.Enabled = false
			end
		elseif light.Parent == nil then
			lights[light] = nil
		end
	end
end)

----------------------------------------------------------------------
-- 3. Efectos reducidos
----------------------------------------------------------------------
local saved = nil
local function applyFx()
	if lowFx() then
		if not saved then
			saved = { GlobalShadows = Lighting.GlobalShadows, effects = {} }
			Lighting.GlobalShadows = false
			for _, e in Lighting:GetChildren() do
				if e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect") then
					saved.effects[e] = { Enabled = e.Enabled }
					e.Enabled = false
				elseif e:IsA("BloomEffect") then
					saved.effects[e] = { Size = e.Size, Intensity = e.Intensity }
					e.Size = math.min(e.Size, 12)
					e.Intensity = e.Intensity * 0.6
				end
			end
		end
	elseif saved then
		Lighting.GlobalShadows = saved.GlobalShadows
		for e, props in saved.effects do
			if e.Parent then for k, v in props do e[k] = v end end
		end
		saved = nil
	end
end
player:GetAttributeChangedSignal("OptFx"):Connect(applyFx)
applyFx()

----------------------------------------------------------------------
-- 4. NPC de la ciudad (etiqueta CityWalker, la pone CityNPCs en el servidor)
----------------------------------------------------------------------
local walkers = {} -- [modelo] = { root, joints = { [motor] = C0 base } }

local function addWalker(char)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root or walkers[char] then return end
	local joints = {}
	for _, obj in char:GetDescendants() do
		if obj:IsA("Motor6D") and (obj.Name == "LeftHip" or obj.Name == "RightHip" or obj.Name == "LeftShoulder" or obj.Name == "RightShoulder") then
			joints[obj] = obj.C0
		end
	end
	walkers[char] = { root = root, joints = joints }
end
for _, char in CollectionService:GetTagged("CityWalker") do task.spawn(addWalker, char) end
CollectionService:GetInstanceAddedSignal("CityWalker"):Connect(function(char) task.spawn(addWalker, char) end)
CollectionService:GetInstanceRemovedSignal("CityWalker"):Connect(function(char) walkers[char] = nil end)

RunService.RenderStepped:Connect(function()
	if next(walkers) == nil or player:GetAttribute("InMatch") then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local camPos = cam.CFrame.Position
	local t = os.clock()
	for char, w in walkers do
		if not char.Parent then
			walkers[char] = nil
		elseif (w.root.Position - camPos).Magnitude <= PERF.NpcAnimRange then
			local moving = w.root.AssemblyLinearVelocity.Magnitude > 1
			local swing = moving and math.sin(t * PERF.NpcSpeed) * PERF.NpcSwing or 0
			for joint, base in w.joints do
				if joint.Parent then
					joint.C0 = base * CFrame.Angles(string.find(joint.Name, "Left") and swing or -swing, 0, 0)
				end
			end
		end
	end
end)
