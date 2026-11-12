-- LocalScript: StarterPlayer/StarterPlayerScripts/DirectionalHUD
-- Responsable: Claude (0.2). Triángulo invertido del combate direccional (Arquitectura, sección 2).
-- Solo se ve con CombatConfig.Directional.Enabled y un objetivo fijado (LockTarget, de Controls).
--
--      ───────      lado de arriba  = Up
--      \     /      lado izquierdo  = Left   (izquierda de TU pantalla)
--       \   /       lado derecho    = Right
--        \ /
--
-- Lo que muestra (valores en PolishConfig.Directional):
--   · Tu postura: ese lado en blanco; más brillante y celeste mientras bloqueás.
--   · El ataque que viene: el lado por donde llega se pone rojo apenas el rival empieza a cargar
--     (dorado si es imbloqueable). Para bloquear, poné tu postura en ese mismo lado.
--   · La patada que viene: punto naranja en el vértice de abajo (no se bloquea: se esquiva).
--   · El parry: destello dorado de todo el triángulo (el sonido lo pone Vfx.client con el evento "Feel").
-- La postura se dibuja con la predicción del cliente (PredictedStance) hasta que el servidor confirma.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))
local Effect = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Effect")

local DIR = CombatConfig.Directional
local P = Polish.Directional
local player = Players.LocalPlayer

if not DIR or not P then return end

local MIRROR = { Up = "Up", Left = "Right", Right = "Left" }

----------------------------------------------------------------------
-- Construcción
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "DirectionalHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 2
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Triangle"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Size = UDim2.fromOffset(P.Side + P.Edge, P.Side + P.Edge)
root.BackgroundTransparency = 1
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = root

local H = P.Side * math.sqrt(3) / 2
local center = Vector2.new((P.Side + P.Edge) / 2, (P.Side + P.Edge) / 2)

-- Un lado del triángulo: barra rotada alrededor de su punto medio
local sides = {}
local function makeSide(name, mid, rotation)
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(center.X + mid.X, center.Y + mid.Y)
	f.Size = UDim2.fromOffset(P.Side - P.Gap * 2, P.Thickness)
	f.Rotation = rotation
	f.BorderSizePixel = 0
	f.BackgroundColor3 = P.Idle
	f.BackgroundTransparency = P.IdleTransparency
	f.Parent = root
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = P.Guard
	stroke.Thickness = 0
	stroke.Transparency = 0.2
	stroke.Parent = f
	sides[name] = { frame = f, stroke = stroke }
end
-- Vértices (y hacia abajo): A(-S/2, -H/3), B(S/2, -H/3), C(0, 2H/3)
makeSide("Up", Vector2.new(0, -H / 3), 0)
makeSide("Left", Vector2.new(-P.Side / 4, H / 6), 60)
makeSide("Right", Vector2.new(P.Side / 4, H / 6), -60)

-- 12/11/2026: acabado de plata. Cada lado lleva brillo metálico (el gradiente multiplica el color del
-- estado, así rojo/dorado/celeste se siguen viendo), un borde oscuro detrás y rombos de plata en los vértices.
for name, s in sides do
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = P.SilverSheen
	g.Parent = s.frame
	local rim = Instance.new("Frame")
	rim.Name = name .. "Rim"
	rim.AnchorPoint = s.frame.AnchorPoint
	rim.Position = s.frame.Position
	rim.Rotation = s.frame.Rotation
	rim.Size = s.frame.Size + UDim2.fromOffset(P.RimWidth * 2, P.RimWidth * 2)
	rim.BackgroundColor3 = P.Rim
	rim.BackgroundTransparency = P.RimTransparency
	rim.BorderSizePixel = 0
	rim.ZIndex = 0
	rim.Parent = root
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0.5, 0)
	rc.Parent = rim
end
for _, v in { Vector2.new(-P.Side / 2, -H / 3), Vector2.new(P.Side / 2, -H / 3), Vector2.new(0, H * 2 / 3) } do
	local gem = Instance.new("Frame")
	gem.Name = "Vertex"
	gem.AnchorPoint = Vector2.new(0.5, 0.5)
	gem.Position = UDim2.fromOffset(center.X + v.X, center.Y + v.Y)
	gem.Size = UDim2.fromOffset(P.Vertex, P.Vertex)
	gem.Rotation = 45
	gem.BackgroundColor3 = P.VertexColor
	gem.BackgroundTransparency = P.IdleTransparency * 0.5
	gem.BorderSizePixel = 0
	gem.ZIndex = 2
	gem.Parent = root
	local gs = Instance.new("UIStroke")
	gs.Color = P.Rim
	gs.Thickness = 1.5
	gs.Parent = gem
	local gg = Instance.new("UIGradient")
	gg.Rotation = 45
	gg.Color = P.SilverSheen
	gg.Parent = gem
end

-- Aviso de patada: punto en el vértice de abajo
local kickDot = Instance.new("Frame")
kickDot.Name = "Kick"
kickDot.AnchorPoint = Vector2.new(0.5, 0.5)
kickDot.Position = UDim2.fromOffset(center.X, center.Y + H * 2 / 3 + P.KickDot * 0.6)
kickDot.Size = UDim2.fromOffset(P.KickDot, P.KickDot)
kickDot.BackgroundColor3 = P.Kick
kickDot.BorderSizePixel = 0
kickDot.Rotation = 45
kickDot.Visible = false
kickDot.Parent = root

-- 12/11/2026 (pedido del usuario): timing a la vista.
--   · Anillo en el centro: cuando el rival ataca, se cierra hasta el instante del golpe. Bloqueá cuando está chico.
--   · Barra debajo: tu propio golpe. Mientras corre no podés cambiar de lado; cuando se vacía, ya podés.
local R = P.Rhythm
local ring = Instance.new("Frame")
ring.Name = "IncomingRing"
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.fromOffset(center.X, center.Y)
ring.BackgroundTransparency = 1
ring.Visible = false
ring.ZIndex = 4
ring.Parent = root
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(0.5, 0)
ringCorner.Parent = ring
local ringStroke = Instance.new("UIStroke")
ringStroke.Thickness = R.RingThickness
ringStroke.Color = P.Attack
ringStroke.Parent = ring
local ringTarget = Instance.new("Frame") -- el tamaño "ahora": cuando el anillo llega acá, pega
ringTarget.Name = "Now"
ringTarget.AnchorPoint = Vector2.new(0.5, 0.5)
ringTarget.Position = ring.Position
ringTarget.Size = UDim2.fromOffset(R.RingMin, R.RingMin)
ringTarget.BackgroundColor3 = P.Attack
ringTarget.BackgroundTransparency = 0.35
ringTarget.Visible = false
ringTarget.ZIndex = 4
ringTarget.Parent = root
local ntCorner = Instance.new("UICorner")
ntCorner.CornerRadius = UDim.new(0.5, 0)
ntCorner.Parent = ringTarget

local rhythm = Instance.new("Frame")
rhythm.Name = "Rhythm"
rhythm.AnchorPoint = Vector2.new(0.5, 0)
rhythm.Position = UDim2.fromOffset(center.X, center.Y + H * 2 / 3 + R.BarGap)
rhythm.Size = UDim2.fromOffset(P.Side * R.BarWidth, R.BarHeight)
rhythm.BackgroundColor3 = P.Rim
rhythm.BackgroundTransparency = 0.25
rhythm.BorderSizePixel = 0
rhythm.Visible = false
rhythm.Parent = root
local rhCorner = Instance.new("UICorner")
rhCorner.CornerRadius = UDim.new(0.5, 0)
rhCorner.Parent = rhythm
local rhythmFill = Instance.new("Frame")
rhythmFill.Name = "Fill"
rhythmFill.AnchorPoint = Vector2.new(0.5, 0)
rhythmFill.Position = UDim2.fromScale(0.5, 0)
rhythmFill.Size = UDim2.fromScale(1, 1)
rhythmFill.BorderSizePixel = 0
rhythmFill.Parent = rhythm
local rfCorner = Instance.new("UICorner")
rfCorner.CornerRadius = UDim.new(0.5, 0)
rfCorner.Parent = rhythmFill
local readyFlashUntil = 0
local wasBusy = false

-- Destello de parry: copia dorada del contorno que crece y se apaga
local flash = Instance.new("Frame")
flash.Name = "ParryFlash"
flash.AnchorPoint = Vector2.new(0.5, 0.5)
flash.Position = UDim2.fromScale(0.5, 0.5)
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundTransparency = 1
flash.Parent = root
local flashScale = Instance.new("UIScale")
flashScale.Parent = flash
local flashSides = {}
for name, s in sides do
	local c = s.frame:Clone()
	c.BackgroundColor3 = P.Parry
	c.BackgroundTransparency = 1
	local st = c:FindFirstChildOfClass("UIStroke")
	if st then st:Destroy() end
	c.Parent = flash
	flashSides[name] = c
end

----------------------------------------------------------------------
-- Lectura de estado
----------------------------------------------------------------------
local lockValue = player:WaitForChild("LockTarget", 10)
local predicted = player:WaitForChild("PredictedStance", 10)

local function myStance(char)
	local attack = char:GetAttribute("AttackDir")
	if table.find(DIR.Dirs, attack) then return attack end
	if predicted and predicted.Value ~= "" and os.clock() - (predicted:GetAttribute("At") or 0) < DIR.Input.PredictHold then
		return predicted.Value
	end
	return char:GetAttribute("Stance") or DIR.DefaultStance
end

local function aliveModel(m)
	local h = m and m.Parent and m:FindFirstChildOfClass("Humanoid")
	return h ~= nil and h.Health > 0
end

-- Ataques que vienen hacia mí: el fijado y, en 2v2, cualquier rival cercano que me mire mientras carga
local function incoming(me, target)
	local list = {}
	local myRoot = me:FindFirstChild("HumanoidRootPart")
	if not myRoot then return list end
	for _, m in CollectionService:GetTagged("Combatant") do
		if m ~= me and aliveModel(m) then
			local state = m:GetAttribute("CombatState") or ""
			local dir = m:GetAttribute("AttackDir") or ""
			local r = m:FindFirstChild("HumanoidRootPart")
			if r and (state == "Windup" or state == "Active" or state == "Kick") then
				local d = (myRoot.Position - r.Position) * Vector3.new(1, 0, 1)
				local facing = d.Magnitude < 0.1 or r.CFrame.LookVector:Dot(d.Unit) > 0.3
				if facing and (m == target or d.Magnitude <= P.OtherAttackers) then
					table.insert(list, {
						model = m,
						state = state,
						side = dir ~= "" and MIRROR[dir] or nil,
						unblockable = (m:GetAttribute("Telegraph") or "") == "Unblockable",
						main = m == target,
						hitAt = m:GetAttribute("HitAt") or 0,
						startAt = m:GetAttribute("ActionStartAt") or 0,
					})
				end
			end
		end
	end
	return list
end

----------------------------------------------------------------------
-- Bucle de dibujo
----------------------------------------------------------------------
local flashUntil = 0

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local target = lockValue and lockValue.Value
	local show = DIR.Enabled and char ~= nil and hum ~= nil and hum.Health > 0 and target ~= nil and aliveModel(target)
		and not char:GetAttribute("KnockedDown") and not char:GetAttribute("CarriedBy")
	local lesson = player:GetAttribute("TutorialLesson")
	show = show and not player:GetAttribute("MenuOpen") and not player:GetAttribute("MainMenuOpen")
		and not player:GetAttribute("InitialLoading")
		and (not player:GetAttribute("InMatch") or player:GetAttribute("MatchPhase") == "Round")
		and (not player:GetAttribute("InTutorial") or lesson == "dirs" or lesson == "block" or lesson == "parry")
	gui.Enabled = show == true
	if not show then return end

	-- Sobre el rival fijado (a la altura del pecho)
	local camera = workspace.CurrentCamera
	local anchor = target:FindFirstChild("UpperTorso") or target:FindFirstChild("HumanoidRootPart")
	if not camera or not anchor then return end
	local sp, onScreen = camera:WorldToViewportPoint(anchor.Position)
	if onScreen then
		root.Position = UDim2.fromOffset(sp.X, sp.Y + P.OffsetY)
	else
		local vp = camera.ViewportSize
		root.Position = UDim2.fromOffset(vp.X / 2, vp.Y * 0.42)
	end

	local stance = myStance(char)
	local blocking = char:GetAttribute("Blocking") == true
	local lockedSide = char:GetAttribute("AttackDir") == stance
	local t = os.clock()
	local pulse = 1 - P.PulseAmp * (0.5 + 0.5 * math.sin(t * P.Pulse))

	-- Base: lados apagados y tu postura en blanco
	for name, s in sides do
		local f = s.frame
		if name == stance then
			f.BackgroundColor3 = blocking and P.Guard or (lockedSide and P.Committed or P.Stance)
			f.BackgroundTransparency = P.StanceTransparency
			s.stroke.Thickness = (blocking or lockedSide) and P.GuardGlow or 0
			s.stroke.Color = blocking and P.Guard or P.Committed
		else
			f.BackgroundColor3 = P.Idle
			f.BackgroundTransparency = P.IdleTransparency
			s.stroke.Thickness = 0
		end
	end

	-- Ataques que vienen: rojo (o dorado si es imbloqueable) del lado por donde llegan
	local kick = false
	for _, a in incoming(char, target) do
		if a.state == "Kick" then
			kick = true
		elseif a.side and sides[a.side] then
			local s = sides[a.side]
			s.frame.BackgroundColor3 = a.unblockable and P.Unblockable or P.Attack
			s.frame.BackgroundTransparency = (a.main and 0 or 0.35) + (1 - pulse) * 0.5
			s.stroke.Color = P.Attack
			s.stroke.Thickness = a.main and P.GuardGlow or 1
		end
	end
	kickDot.Visible = kick
	if kick then kickDot.BackgroundTransparency = (1 - pulse) * 0.6 end

	-- Anillo del golpe que viene (el del rival fijado, o el más cercano a pegar)
	local serverNow = workspace:GetServerTimeNow()
	local soonest
	for _, a in incoming(char, target) do
		if a.hitAt > serverNow and (not soonest or a.hitAt < soonest.hitAt) then soonest = a end
	end
	if soonest then
		local total = math.max(0.05, soonest.hitAt - math.min(soonest.startAt > 0 and soonest.startAt or soonest.hitAt - R.Window, soonest.hitAt))
		local frac = math.clamp((soonest.hitAt - serverNow) / total, 0, 1)
		local size = R.RingMin + (R.RingMax - R.RingMin) * frac
		ring.Size = UDim2.fromOffset(size, size)
		ringStroke.Color = soonest.unblockable and P.Unblockable or P.Attack
		ringTarget.BackgroundColor3 = ringStroke.Color
		ring.Visible = true
		ringTarget.Visible = true
	else
		ring.Visible = false
		ringTarget.Visible = false
	end

	-- Tu ritmo: mientras dura tu acción, la barra se vacía; al terminar destella "ya podés"
	local endsAt = char:GetAttribute("ActionEndsAt") or 0
	local startAt = char:GetAttribute("ActionStartAt") or 0
	local busy = endsAt > serverNow and (char:GetAttribute("AttackDir") or "") ~= ""
	if busy then
		local frac = math.clamp((endsAt - serverNow) / math.max(0.05, endsAt - startAt), 0, 1)
		rhythmFill.Size = UDim2.fromScale(frac, 1)
		local myHit = char:GetAttribute("HitAt") or 0
		rhythmFill.BackgroundColor3 = myHit > serverNow and R.Windup or R.Recovery
		rhythm.Visible = true
		wasBusy = true
	else
		if wasBusy then readyFlashUntil = t + R.ReadyFlash end
		wasBusy = false
		local flash = readyFlashUntil - t
		rhythm.Visible = flash > 0
		rhythmFill.Size = UDim2.fromScale(1, 1)
		rhythmFill.BackgroundColor3 = R.Ready
		rhythmFill.BackgroundTransparency = 1 - math.clamp(flash / R.ReadyFlash, 0, 1)
	end
	if busy then rhythmFill.BackgroundTransparency = 0 end

	-- Destello de parry
	local left = flashUntil - t
	if left > 0 then
		local a = left / P.ParryTime
		for _, c in flashSides do c.BackgroundTransparency = 1 - a end
		flashScale.Scale = 1 + (P.ParryScale - 1) * (1 - a)
	else
		for _, c in flashSides do c.BackgroundTransparency = 1 end
	end
end)

----------------------------------------------------------------------
-- Resultados que manda el servidor (contrato C23, evento "Feel")
----------------------------------------------------------------------
Effect.OnClientEvent:Connect(function(kind, role)
	if kind ~= "Feel" then return end
	if role == "Parry" then
		flashUntil = os.clock() + P.ParryTime
		scale.Scale = 1.15
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	elseif role == "Block" then
		scale.Scale = 1.06
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end
end)
