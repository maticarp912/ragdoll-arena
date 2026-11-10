-- ModuleScript: ServerScriptService/Fx
-- Efectos de feedback decididos por el servidor: sonidos (desde Assets), textos flotantes,
-- hitstop, sacudida de cámara, destellos en el arma y cajas de golpe de depuración.
-- Los efectos visuales los dibuja cada cliente (Controls/Overhead) a partir de estos eventos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local Assets = require(ReplicatedStorage:WaitForChild("Assets"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Remotes = require(ServerScriptService:WaitForChild("Remotes"))

local Effect = Remotes.get("Effect")

local Fx = {}

-- Grupos de sonido (contrato C10): Ajustes (Gemini) les pone el volumen en cada cliente
-- según los atributos OptSfx y OptMusic. Todo efecto va a SFX; la música irá a Music.
local SoundService = game:GetService("SoundService")
local function soundGroup(name)
	local g = SoundService:FindFirstChild(name)
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = name
		g.Parent = SoundService
	end
	return g
end
local SFX = soundGroup("SFX")
soundGroup("Music")

local debugFolder = workspace:FindFirstChild("DebugHitboxes")
if not debugFolder then
	debugFolder = Instance.new("Folder")
	debugFolder.Name = "DebugHitboxes"
	debugFolder.Parent = workspace
end

-- Reproduce un sonido de Assets (ruta tipo "Hit_Light" o "Swing.Sword.Light") en una parte.
-- Si el ID es 0 no hace nada (placeholder = silencio).
function Fx.sound(path, parent, volume)
	local id = Assets.sound(path)
	if not id or not parent then return nil end
	local cfg = Assets.soundSettings(path)
	local var = cfg.var or 0.05
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = (volume or 1) * (cfg.volume or 0.8)
	s.PlaybackSpeed = (cfg.pitch or 1) * (1 + (math.random() * 2 - 1) * var)
	s.RollOffMaxDistance = 140
	s.RollOffMinDistance = 10
	s.SoundGroup = SFX
	local region = Assets.soundRegion(id)
	if region then
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(region[1], region[2])
	end
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 6)
	-- Capa extra: bajo un sonido propio, una variante de la librería más baja (impactos con más cuerpo)
	local layer = Assets.Custom.Layers[path]
	if layer and Assets.isCustom(id) then
		local libId = Assets.librarySound(path)
		if libId then
			local l = s:Clone()
			l.SoundId = libId
			l.PlaybackRegionsEnabled = false
			l.Volume = s.Volume * layer
			l.PlaybackSpeed = s.PlaybackSpeed * 0.92
			l.Parent = parent
			l:Play()
			Debris:AddItem(l, 6)
		end
	end
	return s
end

-- Efecto visual de impacto (lo dibuja cada cliente). kind: Light, Heavy, Blunt, Block, BlockHeavy, Parry, GuardBreak
function Fx.hit(position, kind, dir, attacker, victim)
	Effect:FireAllClients("HitFx", position, kind, dir or Vector3.zAxis, attacker, victim)
end

-- Polvo al caer al suelo (derribos, lanzamientos)
function Fx.dust(position, scale)
	Effect:FireAllClients("Dust", position, scale or 1)
end

-- Punto de impacto aproximado entre atacante y víctima (a la altura del pecho)
function Fx.impactPoint(attacker, victim)
	local a = attacker and attacker:FindFirstChild("HumanoidRootPart")
	local v = victim and victim:FindFirstChild("UpperTorso") or (victim and victim:FindFirstChild("HumanoidRootPart"))
	if not v then return Vector3.zero, Vector3.zAxis end
	if not a then return v.Position, Vector3.zAxis end
	local d = (v.Position - a.Position) * Vector3.new(1, 0, 1)
	local dir = d.Magnitude > 0.01 and d.Unit or Vector3.zAxis
	return v.Position - dir * 0.6 + Vector3.new(0, 0.3, 0), dir
end

-- Sonido en el HumanoidRootPart de un personaje
function Fx.soundAt(path, char, volume)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return Fx.sound(path, root, volume)
end

function Fx.pop(position, text, color)
	Effect:FireAllClients("Pop", position, text, color or Theme.Colors.Damage)
end

function Fx.popAbove(char, text, color)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then Fx.pop(root.Position + Vector3.new(0, 3.2, 0), text, color) end
end

function Fx.toast(player, text)
	if player then Effect:FireClient(player, "Toast", text) end
end

-- Congela un instante las animaciones de los personajes indicados (todos los clientes lo ven)
function Fx.hitstop(chars, duration)
	if not duration or duration <= 0 then return end
	Effect:FireAllClients("Hitstop", chars, duration, CombatConfig.Hitstop.Speed)
end

-- intensity: 0..1 de "trauma" · dir (opcional): dirección del golpe, empuja la cámara hacia ahí
function Fx.shake(char, intensity, dir)
	local p = char and Players:GetPlayerFromCharacter(char)
	if p and intensity and intensity > 0 then
		Effect:FireClient(p, "Shake", intensity, typeof(dir) == "Vector3" and dir or nil)
	end
end

-- Sensación del combate (contrato C23). Le avisa SOLO al jugador involucrado qué le pasó, para que su cliente
-- distinga golpear, recibir, bloquear y parry (hit-stop local, temblor, viñeta, sonido 2D propio).
--   role: "Deal" (pegaste), "Take" (te pegaron), "Block" (bloqueaste), "Blocked" (te bloquearon),
--         "Parry" (parreaste), "Parried" (te parrearon), "GuardBreak" (rompiste), "GuardBroken" (te rompieron)
--   info: { dir = Vector3, kind = "Light"|"Heavy"|"Kick", finisher = bool, amount = número, guard = 0..1 }
-- El HUD de Gemini puede escuchar el mismo evento (Effect, tipo "Feel") para el destello de las barras.
function Fx.feel(char, role, info)
	local p = char and Players:GetPlayerFromCharacter(char)
	if p then Effect:FireClient(p, "Feel", role, info or {}) end
end

-- Efecto visual de una infusión al golpear (lo dibuja cada cliente)
function Fx.infusionHit(position, infusionId, dir)
	Effect:FireAllClients("InfusionHit", position, infusionId, dir or Vector3.zAxis)
end

-- Destello en el arma del personaje (parry, rotura de guardia...)
function Fx.flash(char, color, duration)
	Effect:FireAllClients("Flash", char, color, duration or 0.2)
end

-- Caja de golpe visible (solo si el visualizador está activado)
function Fx.debugBox(cframe, size, hit)
	if not workspace:GetAttribute("DebugHitboxes") then return end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.ForceField
	p.Color = hit and Theme.Colors.HitboxHit or Theme.Colors.Hitbox
	p.Transparency = 0.35
	p.Size = size
	p.CFrame = cframe
	p.Parent = debugFolder
	Debris:AddItem(p, 0.3)
end

return Fx
