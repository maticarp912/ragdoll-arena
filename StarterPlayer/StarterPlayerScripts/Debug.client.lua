-- LocalScript: StarterPlayer/StarterPlayerScripts/Debug
-- Panel de depuración (tecla P). Solo aparece en Studio o para quien tenga permiso (CombatConfig.Debug).
--   · Estado en vivo: tus barras, acción, i-frames, aturdimiento... y los del objetivo fijado (o el más cercano)
--   · Muñecos: modo, arma, reiniciar, añadir
--   · Visualizador de cajas de golpe, llenar infusión, curarte, "solo práctica" (no entrar en la cola)
--   · AnimTester: reproduce una animación (ID o clave de Assets) en tu personaje y mide sus marcadores

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local Theme = require(ReplicatedStorage:WaitForChild("Theme"))
local Assets = require(ReplicatedStorage:WaitForChild("Assets"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local CombatConfig = require(ReplicatedStorage:WaitForChild("CombatConfig"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local DebugRemote = remotes:WaitForChild("Debug")

local C = Theme.Colors
local MARKERS = { "Hit", "WindupEnd", "Release", "Slap" }
local DUMMY_MODES = {
	Idle = "Quieto", Block = "Bloquea", Parry = "Parrea", Dodge = "Esquiva",
	Attack = "Ataca (M1)", Heavy = "Fuertes", Mixed = "Mixto",
}

----------------------------------------------------------------------
-- Interfaz
----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "DebugPanel"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("ScrollingFrame")
-- 9/11: a la derecha (a la izquierda van los botones del lobby)
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 70)
panel.Size = UDim2.new(0, 330, 1, -140)
panel.CanvasSize = UDim2.new()
panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel.ScrollBarThickness = 5
panel.BackgroundTransparency = 0.1
panel.Parent = gui
Theme.panel(panel)

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function title(text)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = nextOrder()
	l.Size = UDim2.new(1, 0, 0, 22)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = C.Gold
	l.Font = Theme.Fonts.Title
	l.TextSize = 18
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = panel
	return l
end

local function textBlock(height)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = nextOrder()
	l.Size = UDim2.new(1, 0, 0, height)
	l.BackgroundColor3 = C.Charcoal
	l.BackgroundTransparency = 0.2
	l.BorderSizePixel = 0
	l.Text = ""
	l.TextColor3 = C.Bone
	l.Font = Enum.Font.Code
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextWrapped = true
	l.Parent = panel
	Theme.corner(l, 3)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 5)
	p.PaddingTop = UDim.new(0, 4)
	p.Parent = l
	return l
end

local function row()
	local f = Instance.new("Frame")
	f.LayoutOrder = nextOrder()
	f.Size = UDim2.new(1, 0, 0, 28)
	f.BackgroundTransparency = 1
	f.Parent = panel
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 4)
	l.Parent = f
	return f
end

local function button(parent, text, width, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(width, -4, 1, 0)
	b.BackgroundColor3 = C.PanelLight
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = C.Bone
	b.Font = Theme.Fonts.Body
	b.TextSize = 12
	b.TextTruncate = Enum.TextTruncate.AtEnd
	b.Parent = parent
	Theme.corner(b, 3)
	Theme.stroke(b, C.Gold, 1, 0.5)
	b.MouseButton1Click:Connect(onClick)
	return b
end

local function textBox(parent, placeholder, width)
	local t = Instance.new("TextBox")
	t.Size = UDim2.new(width, -4, 1, 0)
	t.BackgroundColor3 = C.Charcoal
	t.BorderSizePixel = 0
	t.PlaceholderText = placeholder
	t.PlaceholderColor3 = C.BoneDim
	t.Text = ""
	t.TextColor3 = C.Bone
	t.Font = Enum.Font.Code
	t.TextSize = 12
	t.ClearTextOnFocus = false
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = parent
	Theme.corner(t, 3)
	Theme.stroke(t, C.Gold, 1, 0.6)
	return t
end

local function send(action, arg)
	DebugRemote:FireServer(action, arg)
end

----------------------------------------------------------------------
-- Sección: estado
----------------------------------------------------------------------
title("Depuración  (P para cerrar)")
local stateText = textBlock(150)
local targetText = textBlock(110)

----------------------------------------------------------------------
-- Sección: herramientas
----------------------------------------------------------------------
title("Práctica")
local r1 = row()
local hitboxBtn = button(r1, "Cajas de golpe: NO", 0.5, function() send("ToggleHitboxes") end)
local practiceBtn = button(r1, "Solo práctica: NO", 0.5, function() send("PracticeOnly") end)
local r2 = row()
local modeBtn = button(r2, "Muñeco: Quieto", 0.5, function() send("DummyMode") end)
local weaponBtn = button(r2, "Arma muñeco: Espada", 0.5, function() send("DummyWeapon") end)
local r3 = row()
button(r3, "Reiniciar muñecos", 0.5, function() send("ResetDummies") end)
button(r3, "Añadir muñeco", 0.5, function() send("SpawnDummy") end)
local r4 = row()
button(r4, "Llenar infusión", 0.5, function() send("FillCharge") end)
button(r4, "Curarme", 0.5, function() send("Heal") end)

local arenaRow = row()
button(arenaRow, "Ir a la arena", 0.5, function() send("GoArena") end)
button(arenaRow, "Probar derrumbe", 0.5, function() send("TestCrumble") end)

local function refreshButtons()
	hitboxBtn.Text = "Cajas de golpe: " .. (workspace:GetAttribute("DebugHitboxes") and "SÍ" or "NO")
	practiceBtn.Text = "Solo práctica: " .. (player:GetAttribute("PracticeOnly") and "SÍ" or "NO")
	modeBtn.Text = "Muñeco: " .. (DUMMY_MODES[workspace:GetAttribute("DummyMode")] or "?")
	local w = WeaponData.Data[workspace:GetAttribute("DummyWeapon")]
	weaponBtn.Text = "Arma muñeco: " .. (w and w.name or "?")
end
for _, a in { "DebugHitboxes", "DummyMode", "DummyWeapon" } do
	workspace:GetAttributeChangedSignal(a):Connect(refreshButtons)
end
player:GetAttributeChangedSignal("PracticeOnly"):Connect(refreshButtons)
refreshButtons()

----------------------------------------------------------------------
-- Sección: AnimTester
----------------------------------------------------------------------
title("AnimTester")
local animKeys = Assets.listAnimations()
local keyIndex = 0

local r5 = row()
local idBox = textBox(r5, "ID o clave (Weapons.Sword.M1_1)", 1)
local r6 = row()
button(r6, "<", 0.15, function()
	keyIndex = (keyIndex - 2) % #animKeys + 1
	idBox.Text = animKeys[keyIndex]
end)
button(r6, ">", 0.15, function()
	keyIndex = keyIndex % #animKeys + 1
	idBox.Text = animKeys[keyIndex]
end)
local speedBox = textBox(r6, "vel 1", 0.2)
local loopOn = false
local loopBtn
loopBtn = button(r6, "Bucle: NO", 0.25, function()
	loopOn = not loopOn
	loopBtn.Text = "Bucle: " .. (loopOn and "SÍ" or "NO")
end)
local r7 = row()
local playBtn = button(r7, "Reproducir", 0.5, function() end)
local stopBtn = button(r7, "Parar", 0.5, function() end)
local animText = textBlock(130)

-- Destello grande en pantalla al llegar un marcador
local markerFlash = Instance.new("TextLabel")
markerFlash.AnchorPoint = Vector2.new(0.5, 0.5)
markerFlash.Position = UDim2.fromScale(0.5, 0.3)
markerFlash.Size = UDim2.fromOffset(300, 60)
markerFlash.BackgroundTransparency = 1
markerFlash.TextColor3 = C.TelegraphHeavy
markerFlash.TextStrokeTransparency = 0.2
markerFlash.Font = Theme.Fonts.Title
markerFlash.TextSize = 48
markerFlash.TextTransparency = 1
markerFlash.TextStrokeTransparency = 1
markerFlash.Text = ""
markerFlash.Parent = gui

local function flashMarker(name)
	markerFlash.Text = name
	markerFlash.TextTransparency = 0
	markerFlash.TextStrokeTransparency = 0.2
	TweenService:Create(markerFlash, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
end

-- Duración esperada y marcadores obligatorios según la clave (ASSETS_LISTA.md)
local function expectations(key)
	if not key then return nil, {} end
	local w, k = string.match(key, "^Weapons%.(%w+)%.([%w_]+)$")
	if w then
		local def = WeaponData.Data[w]
		if not def then return nil, {} end
		local step = string.match(k, "^M1_(%d)$")
		if step then
			return def.combo.duration[tonumber(step)], { "Hit" }
		elseif k == "Heavy" then
			local h = def.heavy
			return h.windup + h.hitDelay + h.recovery, { "WindupEnd", "Hit" }
		end
		return nil, {}
	end
	local g = string.match(key, "^Generic%.([%w_]+)$")
	if g == "Kick" then
		return CombatConfig.Kick.Windup + CombatConfig.Kick.Recovery, { "Hit" }
	elseif g == "ThrowShort" or g == "ThrowFar" then
		return nil, { "Release" }
	elseif g == "ReviveSlap" then
		return nil, { "Slap" }
	elseif g and string.sub(g, 1, 5) == "Dodge" then
		return 0.4, {}
	end
	return nil, {}
end

local current = nil   -- { track, conns, key, reached = {} }

local function stopCurrent()
	if not current then return end
	for _, c in current.conns do c:Disconnect() end
	if current.track.IsPlaying then current.track:Stop(0.1) end
	current.track:Destroy()
	current = nil
end

local function report()
	if not current then return end
	local track = current.track
	local lines = {}
	table.insert(lines, ("Clave: %s"):format(current.key or "(ID directo)"))
	table.insert(lines, ("ID: %s"):format(current.id))
	local len = track.Length
	local expected, required = expectations(current.key)
	if len > 0 then
		local line = ("Duración: %.2f s"):format(len)
		if expected then
			local diff = math.abs(len - expected) / expected
			line ..= ("  (esperado %.2f s: %s)"):format(expected, diff <= 0.1 and "OK" or "[!] fuera de ±10%, se ajustará la velocidad")
		end
		table.insert(lines, line)
	else
		table.insert(lines, "Duración: cargando...")
	end
	table.insert(lines, ("Prioridad: %s · Bucle: %s"):format(track.Priority.Name, tostring(track.Looped)))
	for _, m in MARKERS do
		local tpos = current.reached[m]
		if tpos then
			local pct = len > 0 and (" (%d%%)"):format(math.floor(tpos / len * 100 + 0.5)) or ""
			table.insert(lines, ("Marcador %s @ %.2f s%s"):format(m, tpos, pct))
		end
	end
	for _, m in required do
		if not current.reached[m] and current.finished then
			table.insert(lines, ("[!] FALTA el marcador '%s'"):format(m))
		end
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.RigType ~= Enum.HumanoidRigType.R15 then
		table.insert(lines, "[!] Tu personaje no es R15")
	end
	animText.Text = table.concat(lines, "\n")
end

local function play()
	stopCurrent()
	local input = string.gsub(idBox.Text, "%s", "")
	if input == "" then
		animText.Text = "Escribe un ID numérico o una clave de Assets (usa < >)."
		return
	end
	local key, id = nil, nil
	if string.match(input, "^%d+$") then
		id = "rbxassetid://" .. input
	elseif string.find(input, "://", 1, true) then
		id = input
	else
		key = input
		id = Assets.anim(key)
		if not id then
			animText.Text = ("'%s' no tiene ID en Assets.lua (se usa el placeholder).\nPega el ID en Assets.lua o escribe el número aquí."):format(key)
			return
		end
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then
		animText.Text = "No hay Animator en tu personaje."
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok or not track then
		animText.Text = "No se pudo cargar: " .. tostring(track) .. "\n(¿está subida con tu cuenta o grupo?)"
		return
	end
	current = { track = track, conns = {}, key = key, id = id, reached = {}, finished = false }
	local my = current
	for _, m in MARKERS do
		table.insert(my.conns, track:GetMarkerReachedSignal(m):Connect(function()
			if my.reached[m] == nil then my.reached[m] = track.TimePosition end
			flashMarker(string.upper(m))
			report()
		end))
	end
	table.insert(my.conns, track.Stopped:Connect(function()
		my.finished = true
		if current == my then report() end
	end))
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = loopOn
	local speed = tonumber(speedBox.Text) or 1
	track:Play(0.1, 1, speed)
	report()
	-- La duración tarda un instante en conocerse
	task.spawn(function()
		local t0 = os.clock()
		while current == my and track.Length <= 0 and os.clock() - t0 < 3 do task.wait(0.1) end
		if current == my then report() end
	end)
end

playBtn.MouseButton1Click:Connect(play)
stopBtn.MouseButton1Click:Connect(stopCurrent)
idBox.FocusLost:Connect(function(enter) if enter then play() end end)

----------------------------------------------------------------------
-- Estado en vivo
----------------------------------------------------------------------
local function remaining(t)
	local r = (t or 0) - workspace:GetServerTimeNow()
	return r > 0 and ("%.2fs"):format(r) or "-"
end

local function describe(model, label)
	if not model or not model.Parent then return label .. ": (ninguno)" end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local w = WeaponData.Data[model:GetAttribute("WeaponId")]
	local lines = {
		("%s: %s [%s]"):format(label, model.Name, w and w.name or "?"),
		("Vida %d/%d · Stun %d · Guardia %d/%d%s"):format(
			hum and math.floor(hum.Health) or 0, hum and math.floor(hum.MaxHealth) or 0,
			math.floor(model:GetAttribute("Stun") or 0),
			math.floor(model:GetAttribute("Guard") or 0), math.floor(model:GetAttribute("GuardMax") or 0),
			model:GetAttribute("GuardBroken") and " ROTA" or ""),
		("Acción: %s %s · combo %d · aviso %s"):format(
			model:GetAttribute("Action") or "", model:GetAttribute("ActionPhase") or "",
			model:GetAttribute("ComboStep") or 0, model:GetAttribute("Telegraph") or ""),
		("Bloqueo: %s · Hiperarmadura: %s · Derribado: %s"):format(
			model:GetAttribute("Blocking") and "SÍ" or "no",
			model:GetAttribute("HyperArmor") and "SÍ" or "no",
			model:GetAttribute("KnockedDown") and "SÍ" or "no"),
		("i-frames %s · aturdido %s · impacto en %s"):format(
			remaining(model:GetAttribute("IFrameUntil")), remaining(model:GetAttribute("StunnedUntil")),
			remaining(model:GetAttribute("HitAt"))),
		("Stamina %d · Infusión %d%% · Velocidad %.1f · Pelea: %s"):format(
			math.floor(model:GetAttribute("Stamina") or 0),
			math.floor(model:GetAttribute("InfusionCharge") or 0),
			hum and hum.WalkSpeed or 0, model:GetAttribute("CanFight") and "SÍ" or "no"),
	}
	return table.concat(lines, "\n")
end

local function nearestOther()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local best, bestD = nil, math.huge
	for _, m in CollectionService:GetTagged("Combatant") do
		local r = m:FindFirstChild("HumanoidRootPart")
		if m ~= char and r then
			local d = (r.Position - root.Position).Magnitude
			if d < bestD then best, bestD = m, d end
		end
	end
	return best
end

task.spawn(function()
	local lockValue = player:WaitForChild("LockTarget", 10)
	while true do
		task.wait(0.1)
		if gui.Enabled then
			stateText.Text = describe(player.Character, "Tú")
			local target = lockValue and lockValue.Value or nearestOther()
			targetText.Text = describe(target, (lockValue and lockValue.Value) and "Objetivo fijado" or "Más cercano")
		end
	end
end)

----------------------------------------------------------------------
-- Abrir / cerrar
----------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.P then return end
	if not player:GetAttribute("DebugAllowed") then return end
	gui.Enabled = not gui.Enabled
end)

-- Stage 8: fixed, server-authorized test economy operations.
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local E = require(ReplicatedStorage:WaitForChild("Economy"))
local ShopRF = remotes:WaitForChild("Shop")
local moneyRow = row()
local feedback = textBlock(E.DebugUI.Height)
local economyBusy, resetArmed = false, false
local function economyAction(action, id)
 if economyBusy then return end economyBusy = true
 task.spawn(function()
  local success, ok, msg = pcall(function() return ShopRF:InvokeServer(action, id) end)
  feedback.Text = success and L.format(msg) or L.t("error")
  economyBusy = false
 end)
end
local small = button(moneyRow, L.t("cx.debug.small"), E.DebugUI.Width, function() economyAction("DebugCoins", "Small") end)
local large = button(moneyRow, L.t("cx.debug.large"), E.DebugUI.Width, function() economyAction("DebugCoins", "Large") end)
local resetButton
resetButton = button(row(), L.t("cx.debug.reset"), E.One, function()
 if not resetArmed then resetArmed = true resetButton.Text = L.t("cx.debug.confirm") return end
 resetArmed = false resetButton.Text = L.t("cx.debug.reset") economyAction("DebugResetPurchases", "")
end)
L.Changed:Connect(function()
 small.Text = L.t("cx.debug.small") large.Text = L.t("cx.debug.large")
 resetButton.Text = L.t(resetArmed and "cx.debug.confirm" or "cx.debug.reset")
end)
