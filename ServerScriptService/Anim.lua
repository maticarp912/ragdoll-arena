-- ModuleScript: ServerScriptService/Anim
-- Animaciones de los personajes (jugadores y muñecos), decididas por el servidor.
--   · Si la clave tiene ID en Assets -> se reproduce esa animación real (AnimationTrack).
--   · Si no -> animación PROCEDURAL: el servidor publica en atributos qué toca y cuándo
--     (AnimKey, AnimStart, AnimDur, AnimWindup, AnimHit, AnimSeq) y cada cliente la dibuja
--     con AnimClips (StarterPlayerScripts/Animator). Así todos la ven sincronizada.
-- Las poses base (reposo, guardia, cargar) no pasan por aquí: salen de los atributos del combate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage:WaitForChild("Assets"))

local Anim = {}

local tracksByChar = setmetatable({}, { __mode = "k" }) -- [char] = { [key] = AnimationTrack }

local function animatorOf(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	return animator
end

local function getTrack(char, key)
	local id = Assets.anim(key)
	if not id then return nil end
	local list = tracksByChar[char]
	if not list then
		list = {}
		tracksByChar[char] = list
	end
	local track = list[key]
	if track and track.Animation and track.Animation.AnimationId == id then
		return track
	end
	local animator = animatorOf(char)
	if not animator then return nil end
	local a = Instance.new("Animation")
	a.AnimationId = id
	local ok, t = pcall(function()
		return animator:LoadAnimation(a)
	end)
	if not ok then
		warn("[Anim] No se pudo cargar", key, id, t)
		return nil
	end
	list[key] = t
	return t
end

-- opts: speed, fade, priority, looped,
--       duration (s), windup (s hasta WindupEnd), hitTime (s hasta Hit/Release/Slap)
-- Devuelve el AnimationTrack real o nil (procedural).
function Anim.play(char, key, opts)
	opts = opts or {}
	if not opts.looped then
		char:SetAttribute("AnimKey", key)
		char:SetAttribute("AnimStart", workspace:GetServerTimeNow())
		char:SetAttribute("AnimDur", opts.duration or 0)
		char:SetAttribute("AnimWindup", opts.windup or 0)
		char:SetAttribute("AnimHit", opts.hitTime or 0)
		char:SetAttribute("AnimSeq", (char:GetAttribute("AnimSeq") or 0) + 1)
	end
	local track = getTrack(char, key)
	if not track then return nil end
	track.Priority = opts.priority or Enum.AnimationPriority.Action
	if opts.looped ~= nil then track.Looped = opts.looped end
	track:Play(opts.fade or 0.08, 1, opts.speed or 1)
	return track
end

function Anim.stop(char, key, fade)
	local list = tracksByChar[char]
	local track = list and list[key]
	if track and track.IsPlaying then track:Stop(fade or 0.12) end
end

-- Corta la animación de acción en curso (golpe recibido, finta...)
function Anim.stopActions(char, fade)
	char:SetAttribute("AnimKey", "")
	char:SetAttribute("AnimSeq", (char:GetAttribute("AnimSeq") or 0) + 1)
	local list = tracksByChar[char]
	if not list then return end
	for _, track in list do
		if track.IsPlaying and not track.Looped then
			track:Stop(fade or 0.1)
		end
	end
end

-- Compatibilidad: ya no hace falta el placeholder de herramienta (hay animación procedural)
function Anim.placeholder()
end

return Anim
