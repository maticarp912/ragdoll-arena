-- ModuleScript: ServerScriptService/AnimTiming
-- Lee la duración y los marcadores (Hit, WindupEnd, Release, Slap) de las animaciones de Assets.
-- Así el daño se sincroniza con el marcador "Hit" en vez de con un tiempo fijo.
-- Se precargan en segundo plano al arrancar; si una animación aún no está leída (o su ID es 0),
-- el combate usa los tiempos de WeaponData/CombatConfig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Assets = require(ReplicatedStorage:WaitForChild("Assets"))

local AnimTiming = {}

local cache = {}    -- [contentId] = { length = n, markers = { Hit = t, ... } } | false (falló)
local pending = {}

local function read(contentId)
	local ok, seq = pcall(function()
		return KeyframeSequenceProvider:GetKeyframeSequenceAsync(contentId)
	end)
	if not ok or not seq then
		warn("[AnimTiming] No se pudo leer", contentId, "->", seq)
		return false
	end
	local info = { length = 0, markers = {} }
	for _, kf in seq:GetKeyframes() do
		if kf.Time > info.length then info.length = kf.Time end
		for _, m in kf:GetMarkers() do
			-- Si un marcador se repite, nos quedamos con el primero
			if info.markers[m.Name] == nil or kf.Time < info.markers[m.Name] then
				info.markers[m.Name] = kf.Time
			end
		end
	end
	seq:Destroy()
	return info
end

local function load(contentId)
	if cache[contentId] ~= nil or pending[contentId] then return end
	pending[contentId] = true
	task.spawn(function()
		cache[contentId] = read(contentId)
		pending[contentId] = nil
	end)
end

-- Devuelve { length, markers } o nil (sin animación o aún no leída). Nunca bloquea.
function AnimTiming.get(key)
	local id = Assets.anim(key)
	if not id then return nil end
	local info = cache[id]
	if info == nil then
		load(id)
		return nil
	end
	return info or nil
end

-- Precarga todas las animaciones con ID
function AnimTiming.preload()
	for _, key in Assets.listAnimations() do
		local id = Assets.anim(key)
		if id then load(id) end
	end
end

return AnimTiming
