-- LocalScript: StarterPlayer/StarterPlayerScripts/Controls
-- Entrada (teclado, ratón y toques), fijación de objetivo, botón de levantarse y efectos locales
-- (textos flotantes, hitstop, sacudida de cámara, destellos, esquiva).
--
-- Controles por defecto (reasignables, también con mando; ver InputMap):
-- Clic = combo | E (o M2 con objetivo fijado) = fuerte | F mantener = guardia, toque justo = parry
-- Teclas por defecto en InputMap: Espacio = esquiva | E = agarrar / lanzar / levantar aliado | C = patada | R = infusión
-- Cargando a alguien: clic = tirón corto, mantener E y soltar = lanzamiento cargado
-- T = fijar objetivo | Y = cambiar objetivo | B = menú | P = depuración

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Input = remotes:WaitForChild("Input")
local SettingsRF = remotes:WaitForChild("Settings")
local InputMap = require(ReplicatedStorage:WaitForChild("InputMap"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local InputBridge = require(ReplicatedStorage:WaitForChild("InputBridge"))
local Effect = remotes:WaitForChild("Effect")

local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))
local HapticService = game:GetService("HapticService")
local hapticVersion = 0
local C = Theme.Colors

-- Asignaciones de controles (Menú > Controles). Eventos locales compartidos con el menú (Shop)
local binds = InputMap.merge(nil)
local toggleMenu = Instance.new("BindableEvent")
toggleMenu.Name = "ToggleMenu"
toggleMenu.Parent = player
local bindsChanged = Instance.new("BindableEvent")
bindsChanged.Name = "BindsChanged"
bindsChanged.Parent = player
bindsChanged.Event:Connect(function(newBinds) binds = newBinds end)
task.spawn(function()
	local ok, result = pcall(function() return SettingsRF:InvokeServer("GetBinds") end)
	if ok and result then binds = result end
end)

-- Sin mochila: el arma no se puede soltar ni cambiar con las teclas numéricas
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local function getChar()
	local c = player.Character
	if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChildOfClass("Humanoid") then
		return c
	end
	return nil
end

----------------------------------------------------------------------
-- Fijación de objetivo (T / Y)
----------------------------------------------------------------------
local locked = nil

-- Lo lee el panel de depuración (objeto local, no se replica)
local lockValue = Instance.new("ObjectValue")
lockValue.Name = "LockTarget"
lockValue.Parent = player

-- Roblox regenera la vida de un Humanoid muerto, así que Health > 0 no alcanza:
-- también se mira el estado Dead y el atributo Eliminated del jugador dueño.
local function isAlive(hum)
	if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return false end
	local owner = Players:GetPlayerFromCharacter(hum.Parent)
	return not (owner and owner:GetAttribute("Eliminated"))
end

local function canLock(model)
	local char = getChar()
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	local mine = char and char:FindFirstChildOfClass("Humanoid")
	return model ~= nil and model.Parent ~= nil and isAlive(hum)
		and mine ~= nil and mine.Health > 0
		and not char:GetAttribute("Carrying") and not char:GetAttribute("CarriedBy")
		and char:GetAttribute("Action") ~= "PickUp"
		and not model:GetAttribute("CarriedBy")
end

local function isEnemyModel(m)
	if m == player.Character then return false end
	if m:GetAttribute("IsDummy") then return true end
	local p = Players:GetPlayerFromCharacter(m)
	if not p then return false end
	return player:GetAttribute("InMatch") == true and p:GetAttribute("InMatch") == true and p.Team ~= player.Team
end

local setLock
-- Solo en Studio: fijar objetivo desde la barra de comandos (pruebas automáticas)
--   game.Players.LocalPlayer.DebugLock:Invoke(modelo)
if RunService:IsStudio() then
	local debugLock = Instance.new("BindableFunction")
	debugLock.Name = "DebugLock"
	debugLock.OnInvoke = function(model) setLock(model) return locked end
	debugLock.Parent = player
end

function setLock(model)
	if model and not canLock(model) then model = nil end
	if locked then
		local old = locked:FindFirstChild("LockOn")
		if old then old:Destroy() end
	end
	locked = model
	lockValue.Value = model
	if model then
		local h = Instance.new("Highlight")
		h.Name = "LockOn"
		h.FillTransparency = 1
		h.OutlineColor = C.Gold
		h.OutlineTransparency = 0.1
		h.Parent = model
	else
		local char = getChar()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.AutoRotate = true end
	end
end

local function pickTarget(exclude, maxRange)
	local char = getChar()
	if not char then return nil end
	local myPos = char.HumanoidRootPart.Position
	local best, bestScore = nil, math.huge
	for _, c in CollectionService:GetTagged("Combatant") do
		local hum = c:FindFirstChildOfClass("Humanoid")
		local r = c:FindFirstChild("HumanoidRootPart")
		if c ~= exclude and canLock(c) and hum and hum.Health > 0 and r and isEnemyModel(c) then
			local d = r.Position - myPos
			if d.Magnitude <= (maxRange or CombatConfig.Controls.LockOnRange) then
				local score = d.Magnitude - camera.CFrame.LookVector:Dot(d.Unit) * 25
				if score < bestScore then
					best, bestScore = c, score
				end
			end
		end
	end
	return best
end

----------------------------------------------------------------------
-- Cámara de combate: distancia fija (sin zoom), en picada y con el personaje un poco a la izquierda.
-- El giro horizontal lo sigue llevando el ratón/stick (cámara de Roblox); el ángulo y la distancia los fija
-- este script. Con el objetivo fijado, la cámara mira hacia el rival.
----------------------------------------------------------------------
local CAM = CombatConfig.Camera
player.CameraMinZoomDistance = CAM.Distance
player.CameraMaxZoomDistance = CAM.Distance

local aimWasOn = false
local camRay = RaycastParams.new()
camRay.FilterType = Enum.RaycastFilterType.Exclude

-- 0.2, bug de la cámara en celular al fijar (Versión 0.2, sección 1):
-- antes se suavizaba desde camera.CFrame, pero la cámara de Roblox la reescribe en cada frame (antes de este
-- paso) con su propio estado: en el teléfono el arrastre táctil, el zoom con dos dedos y el «popper» de oclusión
-- movían ese punto de partida y la cámara se trababa o saltaba. Ahora el suavizado parte de un estado propio
-- (lockCam), se reinicia al fijar y salta directo si la meta quedó lejos (teletransporte al entrar a la arena).
local lockCam = nil
local LOCK_SNAP_DISTANCE = 25

local function placeCamera(focus, flatDir, pitchDeg, smooth, dt)
	local p = math.rad(pitchDeg)
	local pos = focus - flatDir * math.cos(p) * CAM.Distance + Vector3.yAxis * math.sin(p) * CAM.Distance
	local goal = CFrame.lookAt(pos, focus) * CFrame.new(CAM.OffsetX, 0, 0)
	-- Que no atraviese paredes (casas del lobby, rocas)
	local filter = { player.Character, workspace:FindFirstChild("LocalVfx") }
	camRay.FilterDescendantsInstances = filter
	local toCam = goal.Position - focus
	local hit = workspace:Raycast(focus, toCam, camRay)
	if hit and hit.Instance.CanCollide then
		goal = goal - toCam.Unit * ((goal.Position - hit.Position).Magnitude + 0.6)
	end
	lockCam = lockCam or camera.CFrame
	if smooth and (lockCam.Position - goal.Position).Magnitude < LOCK_SNAP_DISTANCE then
		lockCam = lockCam:Lerp(goal, 1 - math.exp(-CombatConfig.Controls.LockOnSmoothing * math.min(dt, 0.1)))
	else
		lockCam = goal
	end
	camera.CFrame = lockCam
	camera.Focus = CFrame.new(focus)
end

-- 0.2 (D1): con el direccional, el fijado es permanente en partida. T / R3 cambia de objetivo en vez de soltarlo,
-- y si el objetivo cae se fija solo al siguiente rival.
local DIR = CombatConfig.Directional
local function directionalOn()
	return DIR ~= nil and DIR.Enabled == true
end
local function permanentLock()
	return directionalOn() and DIR.PermanentLockInMatch and player:GetAttribute("InMatch") == true
end
local relockAt = 0
local dirMouseOn = false -- el ratón quedó centrado por el direccional (hay que soltarlo al salir)

-- Fijado automático (9/11): al entrar a la arena se fija al rival más cercano. El HUD completo
-- se muestra mientras haya objetivo fijado (LockTarget.Value).
local function autoLockSoon()
	task.delay(1.5, function()
		if player:GetAttribute("InMatch") and not locked then setLock(pickTarget(nil, CombatConfig.Controls.MatchLockRange)) end
	end)
end
player:GetAttributeChangedSignal("InMatch"):Connect(function()
	if player:GetAttribute("InMatch") then autoLockSoon() else setLock(nil) end
end)
player.CharacterAdded:Connect(function()
	if player:GetAttribute("InMatch") then autoLockSoon() end
end)

-- Cámara de espectador (9/11): eliminado en una ronda, se sigue a un aliado vivo (o a un rival si no hay).
-- El servidor marca el atributo Eliminated (contrato C9). La cámara de Roblox sigue al Humanoid elegido.
local spectating = nil
local function aliveInMatch(p)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return p:GetAttribute("InMatch") == true and not p:GetAttribute("Eliminated") and h and h.Health > 0 and h or nil
end
local function updateSpectate()
	if not (player:GetAttribute("Eliminated") and player:GetAttribute("InMatch")) then
		if spectating then
			spectating = nil
			local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if myHum then camera.CameraSubject = myHum end
		end
		return nil
	end
	if spectating and spectating.Parent and isAlive(spectating) then return spectating end
	spectating = nil
	for _, pass in { true, false } do -- primero aliados, después cualquiera
		for _, p in Players:GetPlayers() do
			if p ~= player and (not pass or p.Team == player.Team) then
				local h = aliveInMatch(p)
				if h then spectating = h break end
			end
		end
		if spectating then break end
	end
	if spectating then camera.CameraSubject = spectating end
	return spectating
end

RunService:BindToRenderStep("LockOn", Enum.RenderPriority.Camera.Value + 1, function(dt)
	camera = workspace.CurrentCamera
	if not camera or camera.CameraType ~= Enum.CameraType.Custom then return end
	local spectatingNow = updateSpectate()
	local char = getChar()
	if (spectatingNow or not char) and dirMouseOn then
		dirMouseOn = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	if spectatingNow then return end -- la cámara de Roblox sigue al espectado
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char.HumanoidRootPart
	-- Derribado o cargado: seguir al torso (el HumanoidRootPart puede quedar raro en ragdoll)
	local body = (char:GetAttribute("Ragdolled") and char:FindFirstChild("UpperTorso")) or root
	local focus = body.Position + Vector3.new(0, CAM.FocusHeight, 0)

	if locked and not canLock(locked) then setLock(nil) end
	local tHum = locked and locked:FindFirstChildOfClass("Humanoid")
	local tRoot = locked and locked:FindFirstChild("HumanoidRootPart")
	if locked and (not (locked.Parent and isAlive(tHum) and tRoot)
		or (tRoot.Position - root.Position).Magnitude > (player:GetAttribute("InMatch") and CombatConfig.Controls.MatchLockRange or CombatConfig.Controls.LockOnBreakRange)) then
		setLock(nil)
	end

	local carrying = char:GetAttribute("Carrying") == true
	if carrying and locked then setLock(nil) end -- el cargado nunca es objetivo: evita el bucle de cámara
	-- Fijado permanente: sin objetivo (cayó, se alejó, terminaste de cargar), buscar el siguiente rival
	if not locked and not carrying and permanentLock() and os.clock() >= relockAt then
		relockAt = os.clock() + 0.3
		setLock(pickTarget(nil, CombatConfig.Controls.MatchLockRange))
		tRoot = locked and locked:FindFirstChild("HumanoidRootPart")
	end

	-- Modo apuntado al cargar: ratón centrado, la cámara gira con el ratón y el cuerpo mira hacia donde lanzará
	local aiming = carrying and not player:GetAttribute("MenuOpen") and hum.Health > 0
	if aiming then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.05 and not char:GetAttribute("Ragdolled") then
			hum.AutoRotate = false
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
		end
		aimWasOn = true
	elseif aimWasOn then
		-- Al lanzar, soltar, morir o cortarse el agarre: control normal del ratón y la cámara
		aimWasOn = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		if not locked then hum.AutoRotate = true end
	end

	-- Direccional (D2): con objetivo fijado el mouse no gira la cámara; queda centrado y sus gestos eligen el lado
	local phase = workspace:GetAttribute("MatchPhase")
	local wantDirMouse = directionalOn() and locked ~= nil and UserInputService.MouseEnabled and not aiming
		and not player:GetAttribute("MenuOpen") and hum.Health > 0
		and (phase == nil or phase == "" or phase == "Round" or phase == "Lobby")
	if wantDirMouse then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		dirMouseOn = true
	elseif dirMouseOn then
		dirMouseOn = false
		if not aiming then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
	end

	if locked and tRoot then
		local rp, tp = root.Position, tRoot.Position
		local flatDir = Vector3.new(tp.X - rp.X, 0, tp.Z - rp.Z)
		if flatDir.Magnitude < 0.1 then return end
		flatDir = flatDir.Unit
		-- Con objetivo fijado también lo mira durante la esquiva (las animaciones L/R/F/B son relativas a él)
		if not hum.PlatformStand and not char:GetAttribute("Ragdolled") then
			hum.AutoRotate = false
			root.CFrame = CFrame.lookAt(rp, rp + flatDir)
		end
		placeCamera(focus, flatDir, CAM.LockPitch, true, dt)
	else
		lockCam = nil -- al volver a fijar, el suavizado arranca desde la cámara actual
		-- Libre: el ángulo (arriba/abajo) y el giro los lleva la cámara de Roblox; la distancia es fija
		-- (zoom bloqueado) y solo se desplaza a la derecha para que el personaje quede a la izquierda.
		local goal = camera.CFrame * CFrame.new(CAM.OffsetX, 0, 0)
		camRay.FilterDescendantsInstances = { char, workspace:FindFirstChild("LocalVfx") }
		local toCam = goal.Position - focus
		local hit = toCam.Magnitude > 0.1 and workspace:Raycast(focus, toCam, camRay)
		if hit and hit.Instance.CanCollide then
			goal = goal - toCam.Unit * ((goal.Position - hit.Position).Magnitude + 0.6)
		end
		camera.CFrame = goal
	end
end)

----------------------------------------------------------------------
-- Indicador discreto del lanzamiento (trayectoria de puntos) mientras cargas a alguien
----------------------------------------------------------------------
local GRAB = CombatConfig.Grab
local AIM_DOTS = 14
local aimFolder = Instance.new("Folder")
aimFolder.Name = "ThrowAim"
local aimDots = {}
for i = 1, AIM_DOTS do
	local d = Instance.new("Part")
	d.Shape = Enum.PartType.Ball
	d.Size = Vector3.one * (i == AIM_DOTS and 0.9 or 0.35)
	d.Anchored = true
	d.CanCollide = false
	d.CanQuery = false
	d.CanTouch = false
	d.CastShadow = false
	d.Material = Enum.Material.Neon
	d.Color = C.Gold
	d.Transparency = 1
	d.Parent = aimFolder
	aimDots[i] = d
end

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not char:GetAttribute("Carrying") then
		if aimFolder.Parent then aimFolder.Parent = nil end
		return
	end
	if aimFolder.Parent ~= workspace.CurrentCamera then aimFolder.Parent = workspace.CurrentCamera end
	local look = workspace.CurrentCamera.CFrame.LookVector
	local dir = Vector3.new(look.X, 0, look.Z)
	if dir.Magnitude < 0.05 then dir = root.CFrame.LookVector * Vector3.new(1, 0, 1) end
	dir = dir.Unit
	-- Misma física que el servidor (Combat.throw): tirón corto o lanzamiento cargado
	local far = char:GetAttribute("ThrowCharging") == true
	local power = far and math.clamp((workspace:GetServerTimeNow() - (char:GetAttribute("ThrowChargeStart") or 0)) / GRAB.ChargeTime, 0, 1) or 0
	local ang = math.rad(far and GRAB.FarAngle or GRAB.ShortAngle)
	local speed = far and (GRAB.FarSpeed + GRAB.FarSpeedCharged * power) or GRAB.ShortSpeed
	local vel = (dir * math.cos(ang) + Vector3.yAxis * math.sin(ang)) * speed
	local p0 = root.Position + dir * 2.6 + Vector3.new(0, GRAB.CarryHeight + 1.2, 0)
	local g = Vector3.new(0, -workspace.Gravity, 0)
	local floorY = root.Position.Y - 3
	local step = 0.07
	for i, d in aimDots do
		local tt = i * step
		local p = p0 + vel * tt + 0.5 * g * tt * tt
		if p.Y < floorY then p = Vector3.new(p.X, floorY, p.Z) end
		d.Position = p
		d.Transparency = (far and 0.25 or 0.5) + (i / AIM_DOTS) * 0.3
		d.Color = (far and power >= 0.95) and C.TelegraphUnblockable or C.Gold
	end
end)

local function aimDirection()
	local char = getChar()
	if not char then return Vector3.zAxis end
	local root = char.HumanoidRootPart
	local dir
	if locked and canLock(locked) and locked:FindFirstChild("HumanoidRootPart") then
		dir = locked.HumanoidRootPart.Position - root.Position
	else
		dir = camera.CFrame.LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.05 then dir = root.CFrame.LookVector end
	return dir.Unit
end

----------------------------------------------------------------------
-- Enviar acciones al servidor
----------------------------------------------------------------------
-- Número de secuencia de cada mensaje al servidor (0.2): el servidor descarta lo repetido o viejo
local seqCounter = 0
local function nextSeq()
	seqCounter += 1
	return seqCounter
end

-- Derribado o cargado (también lo usa la postura direccional)
local function isDownLocal(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum == nil or hum.Health <= 0
		or char:GetAttribute("KnockedDown") == true or char:GetAttribute("CarriedBy") == true
end

local function faceAim(char, aim)
	if char:GetAttribute("Ragdolled") or char:GetAttribute("Action") == "Dodge" then return end
	local root = char.HumanoidRootPart
	root.CFrame = CFrame.lookAt(root.Position, root.Position + aim)
end

local function send(action)
	local char = getChar()
	if not char then return end
	local arg, extra = nil, nil
	if action == "M1" or action == "Heavy" or action == "Interact" or action == "HeavyRelease" then
		arg = aimDirection()
		if action ~= "HeavyRelease" then faceAim(char, arg) end -- girar hacia el objetivo antes de golpear
	elseif action == "Dodge" then
		local hum = char:FindFirstChildOfClass("Humanoid")
		local move = hum and hum.MoveDirection or Vector3.zero
		move = Vector3.new(move.X, 0, move.Z)
		if move.Magnitude > 0.1 then
			arg = move.Unit
		else
			arg = -char.HumanoidRootPart.CFrame.LookVector -- sin dirección: esquiva hacia atrás
		end
		if locked and canLock(locked) then extra = locked end -- el servidor elige la animación respecto de él
	end
	Input:FireServer(action, arg, extra, nextSeq())
end

----------------------------------------------------------------------
-- 0.2: postura direccional (D2). Se elige con un gesto corto del mouse (con objetivo fijado) o con el stick
-- derecho; queda hasta elegir otra. El cliente la muestra al instante (predicción) y el servidor la valida.
-- DirectionalHUD lee PredictedStance (objeto local, no se replica) y el atributo Stance del personaje.
----------------------------------------------------------------------
local predictedStance = Instance.new("StringValue")
predictedStance.Name = "PredictedStance"
predictedStance.Parent = player

local function setStance(dir)
	if not directionalOn() or not table.find(DIR.Dirs, dir) then return end
	local char = getChar()
	if not char or isDownLocal(char) then return end
	local current = predictedStance.Value ~= "" and predictedStance.Value or char:GetAttribute("Stance")
	if current == dir then return end
	predictedStance.Value = dir
	predictedStance:SetAttribute("At", os.clock())
	Input:FireServer("Stance", dir, nil, nextSeq())
end

-- El servidor rechazó la postura: volver a la real
Effect.OnClientEvent:Connect(function(kind, _seq, action)
	if kind == "InputReject" and action == "Stance" then
		local char = getChar()
		predictedStance.Value = char and (char:GetAttribute("Stance") or "") or ""
		predictedStance:SetAttribute("At", 0)
	end
end)
player.CharacterAdded:Connect(function()
	predictedStance.Value = ""
	predictedStance:SetAttribute("At", 0)
end)

local function stanceInputActive()
	if not directionalOn() or not locked or player:GetAttribute("MenuOpen") then return false end
	local char = getChar()
	return char ~= nil and not isDownLocal(char)
end

-- Gesto del mouse: se acumula el movimiento y se pierde rápido; pasado el umbral elige el lado
local gestureX, gestureY = 0, 0
local stickSector = nil
local IN = DIR and DIR.Input

local function sectorOf(x, upY)
	-- upY > 0 = hacia arriba. Abajo no hace nada (D1)
	local angle = math.deg(math.atan2(x, upY)) -- 0 = arriba, +90 = derecha
	if math.abs(angle) <= 50 then return "Up" end
	if angle > 50 and angle <= 140 then return "Right" end
	if angle < -50 and angle >= -140 then return "Left" end
	return nil
end

UserInputService.InputChanged:Connect(function(input)
	if not stanceInputActive() then
		gestureX, gestureY = 0, 0
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		gestureX += input.Delta.X
		gestureY += input.Delta.Y
		local up = -gestureY
		if math.sqrt(gestureX * gestureX + up * up) >= IN.MouseThreshold then
			local dir
			if up > math.abs(gestureX) * IN.MouseUpBias then
				dir = "Up"
			elseif math.abs(gestureX) >= math.abs(up) then
				dir = gestureX > 0 and "Right" or "Left"
			end
			gestureX, gestureY = 0, 0
			if dir then setStance(dir) end
		end
	elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
		local p = input.Position
		local mag = Vector2.new(p.X, p.Y).Magnitude
		if mag < IN.StickRelease then
			stickSector = nil
		elseif mag >= IN.StickDeadZone then
			local sector = sectorOf(p.X, p.Y)
			if sector and sector ~= stickSector then
				stickSector = sector
				setStance(sector)
			end
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if gestureX ~= 0 or gestureY ~= 0 then
		local k = math.exp(-(IN and IN.MouseDecay or 10) * dt)
		gestureX *= k
		gestureY *= k
	end
end)

----------------------------------------------------------------------
-- Interfaz propia: aviso contextual, avisos cortos y botón para levantarse.
-- Tus barras están abajo (HUD). Ya no hay panel de teclas a la derecha.
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Controls"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Aviso contextual encima de tus barras (R para agarrar / levantar, lanzar...)
local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -130)
hint.Size = UDim2.fromOffset(460, 22)
hint.BackgroundTransparency = 1
hint.TextColor3 = C.Gold
hint.TextStrokeTransparency = 0.35
hint.Font = Theme.Fonts.Body
hint.TextSize = 16
hint.Text = ""
hint.Parent = gui

-- Aviso corto (Toast del servidor)
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -156)
toast.Size = UDim2.fromOffset(520, 26)
toast.BackgroundTransparency = 1
toast.TextColor3 = C.Bone
toast.TextStrokeTransparency = 0.4
toast.Font = Theme.Fonts.Body
toast.TextSize = 16
toast.Text = ""
toast.Parent = gui
local toastToken = 0

local function showToast(text)
	toastToken += 1
	local my = toastToken
	toast.Text = text
	toast.TextTransparency = 0
	task.delay(2.5, function()
		if toastToken == my then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		end
	end)
end

-- Derribado: botón grande para levantarse (se puede machacar) + Espacio / clic
local downPanel = Instance.new("Frame")
downPanel.AnchorPoint = Vector2.new(0.5, 0.5)
downPanel.Position = UDim2.fromScale(0.5, 0.62)
downPanel.Size = UDim2.fromOffset(320, 108)
downPanel.BackgroundTransparency = 0.15
downPanel.Visible = false
downPanel.Parent = gui
Theme.panel(downPanel)

local downTitle = Instance.new("TextLabel")
downTitle.Position = UDim2.fromOffset(0, 4)
downTitle.Size = UDim2.new(1, 0, 0, 26)
downTitle.BackgroundTransparency = 1
downTitle.Font = Theme.Fonts.Title
downTitle.TextSize = 24
downTitle.TextColor3 = C.TelegraphHeavy
downTitle.Text = "DERRIBADO"
downTitle.Parent = downPanel

local downBarBg = Instance.new("Frame")
downBarBg.Position = UDim2.fromOffset(12, 34)
downBarBg.Size = UDim2.new(1, -24, 0, 8)
downBarBg.BackgroundColor3 = C.BarBack
downBarBg.BorderSizePixel = 0
downBarBg.Parent = downPanel
Theme.stroke(downBarBg, C.Gold, 1, 0.5)

local downBarFill = Instance.new("Frame")
downBarFill.Size = UDim2.fromScale(0, 1)
downBarFill.BackgroundColor3 = C.Gold
downBarFill.BorderSizePixel = 0
downBarFill.Parent = downBarBg

local getUpBtn = Instance.new("TextButton")
getUpBtn.Position = UDim2.fromOffset(12, 52)
getUpBtn.Size = UDim2.new(1, -24, 0, 46)
getUpBtn.BackgroundColor3 = C.PanelLight
getUpBtn.AutoButtonColor = true
getUpBtn.Text = "LEVANTARSE\nmachacá Espacio, clic o este botón"
getUpBtn.TextColor3 = C.Bone
getUpBtn.Font = Theme.Fonts.Number
getUpBtn.TextSize = 14
getUpBtn.Parent = downPanel
Theme.corner(getUpBtn, 3)
Theme.stroke(getUpBtn, C.Gold, 1.5, 0.1)

local function mashGetUp()
	send("GetUp")
	-- pequeño "golpe" visual en el botón
	getUpBtn.BackgroundColor3 = C.Gold
	TweenService:Create(getUpBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.PanelLight }):Play()
end
getUpBtn.MouseButton1Down:Connect(mashGetUp)

local function isDown(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
		and (char:GetAttribute("KnockedDown") == true or char:GetAttribute("CarriedBy") == true)
end

-- Barra de carga del lanzamiento (mientras mantienes el fuerte cargando a alguien)
local chargeBg = Instance.new("Frame")
chargeBg.AnchorPoint = Vector2.new(0.5, 1)
chargeBg.Position = UDim2.new(0.5, 0, 1, -108)
chargeBg.Size = UDim2.fromOffset(260, 10)
chargeBg.BackgroundColor3 = C.BarBack
chargeBg.BorderSizePixel = 0
chargeBg.Visible = false
chargeBg.Parent = gui
Theme.stroke(chargeBg, C.Gold, 1, 0.3)
local chargeFill = Instance.new("Frame")
chargeFill.Size = UDim2.fromScale(0, 1)
chargeFill.BackgroundColor3 = C.TelegraphHeavy
chargeFill.BorderSizePixel = 0
chargeFill.Parent = chargeBg

local function hookCharacter(char)
	local hum = char:WaitForChild("Humanoid")
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) -- en este juego no se salta
	setLock(nil)
	-- Personaje nuevo: sin modo apuntado pendiente
	if aimWasOn then
		aimWasOn = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	-- En ragdoll el Humanoid deja de intentar mantenerse en pie (lo controla la física)
	char:GetAttributeChangedSignal("Ragdolled"):Connect(function()
		if char:GetAttribute("Ragdolled") then
			hum:ChangeState(Enum.HumanoidStateType.Physics)
		else
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then task.spawn(hookCharacter, player.Character) end

local function usingGamepad()
	local t = UserInputService:GetLastInputType()
	return string.sub(t.Name, 1, 7) == "Gamepad"
end

local function keyLabel(action)
	local device = usingGamepad() and "Gamepad" or "Keyboard"
	return InputMap.label(binds[device][action])
end

-- Panel de derribo / forcejeo y barra de lanzamiento (cada frame)
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local now = workspace:GetServerTimeNow()
	if isDown(char) then
		downPanel.Visible = true
		local carried = char:GetAttribute("CarriedBy") == true
		if carried then
			downTitle.Text = "¡TE ESTÁN CARGANDO!"
			getUpBtn.Text = "FORCEJEAR\nmachacá " .. keyLabel("Dodge") .. ", " .. keyLabel("Attack") .. " o este botón"
			local ends = char:GetAttribute("CarryEndsAt") or 0
			local frac = 1 - math.clamp((ends - now) / CombatConfig.Grab.MaxCarryTime, 0, 1)
			downBarFill.Size = UDim2.fromScale(frac, 1)
		else
			downTitle.Text = "DERRIBADO"
			getUpBtn.Text = "LEVANTARSE\nmachacá " .. keyLabel("Dodge") .. ", " .. keyLabel("Attack") .. " o este botón"
			local start = char:GetAttribute("KnockdownStart") or 0
			local ends = char:GetAttribute("KnockdownEndsAt") or 0
			local frac = ends > start and (now - start) / (ends - start) or 1
			downBarFill.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
		end
	else
		downPanel.Visible = false
	end

	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and char:GetAttribute("ThrowCharging") then
		chargeBg.Visible = true
		local f = math.clamp((now - (char:GetAttribute("ThrowChargeStart") or now)) / CombatConfig.Grab.ChargeTime, 0, 1)
		chargeFill.Size = UDim2.fromScale(f, 1)
		chargeFill.BackgroundColor3 = f >= 1 and C.TelegraphUnblockable or C.TelegraphHeavy
	else
		chargeBg.Visible = false
	end
end)

-- Aviso contextual
task.spawn(function()
	while true do
		task.wait(0.12)
		local text = ""
		local char = getChar()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not isDown(char) then
			if char:GetAttribute("Carrying") then
				text = ("%s: tirón corto · mantené %s y soltá: lanzar lejos"):format(keyLabel("Attack"), keyLabel("Heavy"))
			else
				local root = char.HumanoidRootPart
				local me = player
				for _, c in CollectionService:GetTagged("Combatant") do
					local r = c:FindFirstChild("UpperTorso") or c:FindFirstChild("HumanoidRootPart")
					if c ~= char and r and (r.Position - root.Position).Magnitude <= 7 and c:GetAttribute("Ragdolled") then
						local p = Players:GetPlayerFromCharacter(c)
						if c:GetAttribute("KnockedDown") and p and p.Team == me.Team and me:GetAttribute("InMatch") and p:GetAttribute("InMatch") then
							text = keyLabel("Interact") .. ": levantar al aliado"
							break
						elseif c:GetAttribute("KnockedDown") and not c:GetAttribute("CarriedBy") and isEnemyModel(c) then
							text = directionalOn() and L.t("hint.kickDowned", { key = keyLabel("Kick") })
							or (keyLabel("Interact") .. ": agarrar al derribado")
							break
						end
					end
				end
			end
		end
		hint.Text = text
	end
end)

----------------------------------------------------------------------
-- Entrada: teclado, ratón y mando (asignaciones en Menú > Controles)
----------------------------------------------------------------------
local function m2Allowed()
	if not CombatConfig.Controls.HeavyOnMouse2 then return false end
	local char = player.Character
	if char and char:GetAttribute("Carrying") then return true end
	return locked ~= nil or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function onAction(action, began)
	local char = getChar()
	if began and isDown(char) then
		-- Derribado o cargado: casi cualquier botón sirve para levantarse / forcejear
		if action == "Attack" or action == "Dodge" or action == "Interact" or action == "Heavy" or action == "Kick" then
			mashGetUp()
		end
		return
	end
	if action == "Attack" then
		if began then send("M1") end
	elseif action == "Heavy" then
		send(began and "Heavy" or "HeavyRelease")
	elseif action == "Block" then
		send(began and "BlockStart" or "BlockEnd")
	elseif action == "Dodge" then
		if began then send("Dodge") end
	elseif action == "Interact" then
		if began then send("Interact") end
	elseif action == "Kick" then
		-- Direccional: tocar F sobre un derribado lo patea, mantenerla lo levanta (lo decide el servidor)
		if began then
			send("Kick")
		elseif directionalOn() then
			send("KickRelease")
		end
	elseif action == "Infuse" then
		if began then send("Infuse") end
	elseif action == "LockOn" then
		if began then
			if permanentLock() then
				-- En partida no se suelta: cambia al siguiente rival (D1, T / R3)
				local range = CombatConfig.Controls.MatchLockRange
				local nextTarget = locked and pickTarget(locked, range) or pickTarget(nil, range)
				if nextTarget then setLock(nextTarget) end
			elseif locked then
				setLock(nil)
			else
				setLock(pickTarget(nil))
			end
		end
	elseif action == "SwitchTarget" then
		if began and locked then
			local nextTarget = pickTarget(locked, permanentLock() and CombatConfig.Controls.MatchLockRange or nil)
			if nextTarget then setLock(nextTarget) end
		end
	elseif action == "Menu" then
		if began then toggleMenu:Fire() end
	end
end

local function actionOf(input)
	local action = InputMap.actionFor(binds, input)
	if not action and input.UserInputType == Enum.UserInputType.MouseButton2 and m2Allowed() then
		action = "Heavy" -- M2 como alias del fuerte
	end
	return action
end

-- Clic derecho asignado a una acción sin el ratón bloqueado: el clic derecho también gira la cámara.
-- Un toque corto y quieto dispara la acción; arrastrar solo gira la cámara.
local M2 = CombatConfig.Controls.Mouse2Tap
local m2Press = nil
local function isFreeMouse2(input)
	return input.UserInputType == Enum.UserInputType.MouseButton2 and not m2Allowed()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local action = actionOf(input)
	if not action then return end
	-- Con el menú abierto solo funciona la tecla del menú
	if player:GetAttribute("MenuOpen") and action ~= "Menu" then return end
	if isFreeMouse2(input) then
		m2Press = { action = action, at = os.clock(), pos = UserInputService:GetMouseLocation() }
		return
	end
	onAction(action, true)
end)

UserInputService.InputEnded:Connect(function(input)
	local action = actionOf(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 and m2Press then
		local press = m2Press
		m2Press = nil
		local moved = (UserInputService:GetMouseLocation() - press.pos).Magnitude
		if os.clock() - press.at <= M2.MaxTime and moved <= M2.MaxMove and not player:GetAttribute("MenuOpen") then
			onAction(press.action, true)
			if press.action == "Block" or press.action == "Heavy" then onAction(press.action, false) end
		end
		return
	end
	if action == "Block" or action == "Heavy" or action == "Kick" then
		onAction(action, false)
	end
end)

-- Botones táctiles (TouchUI de Gemini, contrato C12): mismas acciones que teclado y mando
InputBridge.Action:Connect(function(action, isDown)
	if player:GetAttribute("MenuOpen") and action ~= "Menu" then return end
	if isDown then
		onAction(action, true)
	elseif action == "Block" or action == "Heavy" or action == "Kick" then
		onAction(action, false)
	end
end)

----------------------------------------------------------------------
-- Sacudida de cámara
----------------------------------------------------------------------
local shakeAmount = 0
local shakeDir = Vector3.zero
RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 2, function(dt)
 camera = workspace.CurrentCamera
 if not camera then return end
 local cfg = CombatConfig.CameraShake
 shakeAmount = math.max(0, shakeAmount - dt * cfg.Decay)
 local power = shakeAmount * shakeAmount * (player:GetAttribute("OptShake") or 1) -- opción de Ajustes (C10)
 local t = os.clock() * Polish.Camera.Frequency
 local offset = Vector3.new(math.noise(t, Polish.Camera.SeedX), math.noise(t, Polish.Camera.SeedY), 0) * cfg.MaxOffset * power
 local kick = camera.CFrame:VectorToObjectSpace(shakeDir) * cfg.Kick * power
 camera.CFrame *= CFrame.new(offset + kick) * CFrame.Angles(0, 0, math.rad(math.noise(t, Polish.Camera.SeedRoll) * cfg.MaxRoll * power))
end)

----------------------------------------------------------------------
-- Efectos que envía el servidor
----------------------------------------------------------------------
local function pop(position, text, color)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position
	anchor.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(170, 36)
	bb.AlwaysOnTop = true
	bb.Adornee = anchor
	bb.Parent = anchor

	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.Font = Theme.Fonts.Title
	l.TextScaled = true
	l.Parent = bb
 local scale = Instance.new("UIScale")
 scale.Scale = Polish.Camera.BounceStart
 scale.Parent = l
 TweenService:Create(scale, TweenInfo.new(Polish.Camera.BounceTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	TweenService:Create(anchor, TweenInfo.new(0.9), { Position = position + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

-- El hitstop se gestiona únicamente en Animator.client.lua.

-- Destello en el arma de un personaje
local function flashWeapon(char, color, duration)
	if typeof(char) ~= "Instance" or not char.Parent then return end
	local tool = char:FindFirstChildOfClass("Tool")
	local h = Instance.new("Highlight")
	h.Adornee = tool or char
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = tool and 0.1 or 0.6
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = char
	TweenService:Create(h, TweenInfo.new(duration), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(h, duration + 0.05)
end

Effect.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "Pop" then
		pop(a, L.t(tostring(b)), c) -- el servidor manda claves (pop.*); los números pasan tal cual
		return
	elseif kind == "Toast" then
		showToast(L.format(a)) -- texto o { key, params }
		return
	elseif kind == "Shake" then
		shakeAmount = math.clamp(shakeAmount + a, 0, 1)
  shakeDir = typeof(b) == "Vector3" and b or Vector3.zero
  hapticVersion += 1
  local version = hapticVersion
  pcall(function()
   if HapticService:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large) then
    local strength = a >= CombatConfig.CameraShake.Heavy and CombatConfig.Haptics.Heavy
     or (a >= CombatConfig.CameraShake.Parry and CombatConfig.Haptics.Parry or CombatConfig.Haptics.Light)
    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, strength)
    task.delay(CombatConfig.Haptics.Duration, function()
     if version == hapticVersion then HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0) end
    end)
   end
  end)
		return
	elseif kind == "Flash" then
		flashWeapon(a, b, c)
		return
	end

	local char = getChar()
	if not char then return end
	local root = char.HumanoidRootPart

	if kind == "Impulse" then
		root.AssemblyLinearVelocity = a
	elseif kind == "Dash" then
		local dir, speed, duration = a, b, c
		-- 9/11: los pasos de Roblox a alta velocidad sonaban como golpecitos durante el dash: se silencian
		local steps = root:FindFirstChild("Running")
		if steps and steps:IsA("Sound") then
			local vol = steps:GetAttribute("BaseVolume") or steps.Volume
			steps:SetAttribute("BaseVolume", vol)
			steps.Volume = 0
			task.delay(duration + 0.15, function() if steps.Parent then steps.Volume = vol end end)
		end
		local D = CombatConfig.Dodge
		local target = D.LockOrbit and locked and canLock(locked) and locked:FindFirstChild("HumanoidRootPart") or nil
		-- Con objetivo: la dirección se reparte en radial (acercarse/alejarse) y tangencial (rodearlo)
		local radial, tangent, holdRadius = 0, 0, nil
		if target then
			local toT = (target.Position - root.Position) * Vector3.new(1, 0, 1)
			if toT.Magnitude > 0.5 then
				toT = toT.Unit
				radial = dir:Dot(toT)
				tangent = dir:Dot(toT:Cross(Vector3.yAxis))
				-- dash sobre todo lateral: mantiene la distancia y da la vuelta alrededor
				if math.abs(tangent) > math.abs(radial) then
					holdRadius = ((target.Position - root.Position) * Vector3.new(1, 0, 1)).Magnitude
				end
			else
				target = nil
			end
		end
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			if os.clock() - t0 > duration or not root.Parent or char:GetAttribute("Ragdolled") then
				conn:Disconnect()
				return
			end
			local v = dir * speed
			if target and target.Parent then
				local offset = (root.Position - target.Position) * Vector3.new(1, 0, 1)
				local dist = offset.Magnitude
				if dist > 0.1 then
					local toT = -offset / dist
					local side = toT:Cross(Vector3.yAxis)
					local r = radial
					if r > 0 and dist <= D.LockMinRadius then r = 0 end -- no lo atraviesa
					v = (toT * r + side * tangent) * speed
					if holdRadius then v += toT * (dist - holdRadius) * D.LockRadiusHold end
					v += target.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * D.LockFollow
				end
			end
			root.AssemblyLinearVelocity = Vector3.new(v.X, root.AssemblyLinearVelocity.Y, v.Z)
		end)
	end
end)
