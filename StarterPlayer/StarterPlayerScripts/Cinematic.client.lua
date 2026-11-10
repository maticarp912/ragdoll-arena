-- LocalScript: StarterPlayer/StarterPlayerScripts/Cinematic
-- Responsable: Claude (0.2, ronda 2). Cámara de la cinemática antes del combate (D16: 4 a 5 s, sin saltear).
-- Contrato C17: MatchService (Codex) pone en el jugador MatchPhase = "Cinematic" y PhaseEnds = hora del servidor
-- en que termina. Primero publica "Cinematic" SIN duración (mientras aparecen los personajes): ahí no se hace nada.
-- Cuando llega un PhaseEnds con al menos PolishConfig.Cinematic.MinTime por delante, arma tres planos:
--   1. vista general que gira alrededor de los luchadores;
--   2. tu equipo de frente (acercamiento lento);
--   3. los rivales de frente.
-- Los carteles con nombre, nivel, rol y arma los dibuja Prematch.client (Gemini). Al terminar (o si cambia la fase)
-- la cámara vuelve a la normal y Controls.client retoma el fijado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Polish = require(ReplicatedStorage:WaitForChild("PolishConfig"))
local CIN = Polish.Cinematic
local player = Players.LocalPlayer

if not CIN then return end

local BIND = "MatchCinematic"
local playing = 0 -- token de la cinemática en curso
local savedFov = nil
local currentEnds = nil -- PhaseEnds de la cinemática en curso (no reiniciar si llega repetido)

----------------------------------------------------------------------
-- Franjas de cine
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "CinematicBars"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 0 -- debajo de los carteles de Prematch
gui.Parent = player:WaitForChild("PlayerGui")

local function bar(anchorY)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0, anchorY)
	f.Position = UDim2.fromScale(0, anchorY)
	f.Size = UDim2.fromScale(1, 0)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.Parent = gui
	return f
end
local topBar, bottomBar = bar(0), bar(1)

local function showBars(on)
	local info = TweenInfo.new(CIN.BarsTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local size = UDim2.fromScale(1, on and CIN.Bars or 0)
	TweenService:Create(topBar, info, { Size = size }):Play()
	TweenService:Create(bottomBar, info, { Size = size }):Play()
end

----------------------------------------------------------------------
-- Luchadores de esta partida
----------------------------------------------------------------------
local function rootOf(p)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if r and h and h.Health > 0 then return r end
	return nil
end

local function gather()
	local myRoot = rootOf(player)
	if not myRoot then return nil end
	local mine, theirs, all = {}, {}, {}
	for _, p in Players:GetPlayers() do
		local r = rootOf(p)
		if r and p:GetAttribute("InMatch") and (r.Position - myRoot.Position).Magnitude <= CIN.Range then
			table.insert(all, r)
			if p == player or (player.Team and p.Team == player.Team) then
				table.insert(mine, r)
			else
				table.insert(theirs, r)
			end
		end
	end
	return mine, theirs, all
end

local function centerOf(list)
	local sum = Vector3.zero
	for _, r in list do sum += r.Position end
	return sum / math.max(1, #list)
end

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Plano de frente a un grupo: la cámara se acerca despacio a la altura del pecho
local function frontShot(group, u)
	local c = centerOf(group)
	local lead = group[1]
	local forward = lead.CFrame.LookVector * Vector3.new(1, 0, 1)
	if forward.Magnitude < 0.1 then forward = Vector3.zAxis end
	forward = forward.Unit
	local right = forward:Cross(Vector3.yAxis)
	local dist = CIN.CloseDistance + (CIN.CloseEnd - CIN.CloseDistance) * smooth(u)
	local spread = 0
	for _, r in group do spread = math.max(spread, (r.Position - c).Magnitude) end
	local eye = c + forward * (dist + spread) + right * CIN.CloseSide + Vector3.yAxis * CIN.CloseHeight
	return CFrame.lookAt(eye, c + Vector3.yAxis * CIN.LookHeight)
end

----------------------------------------------------------------------
-- Reproducción
----------------------------------------------------------------------
local function stop(token)
	if token and token ~= playing then return end
	playing += 1
	pcall(function() RunService:UnbindFromRenderStep(BIND) end)
	local camera = workspace.CurrentCamera
	if camera and camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then camera.CameraSubject = hum end
	end
	if camera and savedFov then camera.FieldOfView = savedFov end
	savedFov = nil
	currentEnds = nil
	showBars(false)
end

local function play(endsAt)
	if currentEnds and math.abs(currentEnds - endsAt) < 0.01 then return end
	local now = workspace:GetServerTimeNow()
	local total = endsAt - now
	if total < CIN.MinTime then return end
	local mine, theirs, all = gather()
	if not mine or #all == 0 then return end
	if #theirs == 0 then theirs = mine end

	stop()
	playing += 1
	local token = playing
	currentEnds = endsAt
	local camera = workspace.CurrentCamera
	savedFov = camera.FieldOfView
	camera.CameraType = Enum.CameraType.Scriptable
	showBars(true)

	local startAt = now
	local s1 = total * CIN.Shots[1]
	local s2 = s1 + total * CIN.Shots[2]
	local center = centerOf(all)
	local spread = 0
	for _, r in all do spread = math.max(spread, (r.Position - center).Magnitude) end
	local radius = math.max(CIN.OrbitMin, math.min(CIN.OrbitRadius, spread * 1.6 + 12))
	-- La vista general arranca detrás de tu equipo, para que la orientación se entienda
	local fromMine = (centerOf(mine) - center) * Vector3.new(1, 0, 1)
	local angle0 = fromMine.Magnitude > 0.1 and math.atan2(fromMine.X, fromMine.Z) or 0

	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 10, function()
		if token ~= playing then return end
		local t = workspace:GetServerTimeNow() - startAt
		if t >= total or player:GetAttribute("MatchPhase") ~= "Cinematic" then
			stop(token)
			return
		end
		camera.CameraType = Enum.CameraType.Scriptable
		local cf
		if t < s1 then
			local u = t / s1
			local a = angle0 + math.rad(CIN.OrbitTurn) * smooth(u)
			local eye = center + Vector3.new(math.sin(a), 0, math.cos(a)) * radius + Vector3.yAxis * CIN.OrbitHeight
			cf = CFrame.lookAt(eye, center + Vector3.yAxis * 2)
			camera.FieldOfView = CIN.Fov
		elseif t < s2 then
			cf = frontShot(mine, (t - s1) / (s2 - s1))
			camera.FieldOfView = CIN.FovClose
		else
			cf = frontShot(theirs, (t - s2) / (total - s2))
			camera.FieldOfView = CIN.FovClose
		end
		camera.CFrame = cf
	end)
end

local function check()
	if player:GetAttribute("MatchPhase") == "Cinematic" then
		local endsAt = player:GetAttribute("PhaseEnds") or workspace:GetAttribute("PhaseEnds") or 0
		play(endsAt)
	else
		stop()
	end
end

player:GetAttributeChangedSignal("MatchPhase"):Connect(check)
player:GetAttributeChangedSignal("PhaseEnds"):Connect(check)
player.CharacterRemoving:Connect(function() stop() end)
