-- Tutorial de primera entrada. El servidor lleva al jugador al patio y activa el bot.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UiTheme = require(ReplicatedStorage:WaitForChild("UiTheme"))
local L = require(ReplicatedStorage:WaitForChild("Localization"))
local Device = require(ReplicatedStorage:WaitForChild("Device"))
local InputMap = require(ReplicatedStorage:WaitForChild("InputMap"))
local G = require(ReplicatedStorage:WaitForChild("CityConfig")).GuidedTutorial
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GuidedRemote = Remotes:WaitForChild("GuidedTutorial")
local Effect = Remotes:WaitForChild("Effect")
local player = Players.LocalPlayer
local C = UiTheme.Colors

local touchKeys = {
	LockOn = "lock", SwitchTarget = "switch", Attack = "attack", Heavy = "heavy",
	Kick = "kick", Block = "block", Dodge = "dodge", Infuse = "infuse",
}
local binds = InputMap.defaults()
-- 12/11/2026 (pedido del usuario): las teclas y botones se ven resaltados en el texto, para que nadie se pierda
local KEY_COLOR = "#E8A33D"
local function key(action)
	local label
	if Device.isTouch() then
		label = L.t("ui.touch." .. touchKeys[action])
	else
		local device = Device.isGamepad() and "Gamepad" or "Keyboard"
		label = InputMap.label(binds[device][action])
	end
	return ('<font color="%s"><b>[%s]</b></font>'):format(KEY_COLOR, label)
end
-- acción que hay que tocar en cada paso (resalta su fila en la ayuda de botones)
local STEP_ACTION = {
	lock = "LockOn", switch = "SwitchTarget", light = "Attack", dirs = "Attack", heavy = "Heavy", combo = "Attack",
	dodge = "Dodge", down = "Kick", carry = "Interact", throw = "Heavy", block = "Block", parry = "Block", infuse = "Infuse",
}
local function dirHint()
	if Device.isTouch() then return L.t("gt.dirTouch") end
	return Device.isGamepad() and L.t("gt.dirPad") or L.t("gt.dirMouse")
end
-- palabras clave en negrita y color hueso (las teclas ya van en dorado)
local KEYWORDS = { "Armería", "Infusiones", "Infusión", "círculo azul", "muñeco", "triángulo", "guardia",
	"parry", "derribo", "derribá", "combo", "esquivá", "fijá", "levantá", "lanzá",
	"Armory", "Infusions", "blue circle", "dummy", "triangle", "Arsenal", "boneco", "triângulo" }
local function emphasize(text)
	for _, word in KEYWORDS do
		text = text:gsub(word, '<b><font color="#F2D8A6">%0</font></b>')
	end
	return text
end
local function stepText(id)
	return emphasize(L.t("gt." .. id .. ".body", {
		move = ("<font color=\"%s\"><b>%s</b></font>"):format(KEY_COLOR, Device.isTouch() and L.t("gt.stick") or (Device.isGamepad() and L.t("gt.leftStick") or "[W] [A] [S] [D]")),
		lock = key("LockOn"), switch = key("SwitchTarget"), attack = key("Attack"), heavy = key("Heavy"),
		kick = key("Kick"), block = key("Block"), dodge = key("Dodge"), infuse = key("Infuse"), dirs = dirHint(),
	}))
end

local gui = Instance.new("ScreenGui")
gui.Name = "GuidedTutorial"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = UiTheme.panel({ name = "Steps", parent = gui, anchor = Vector2.new(0.5, 0),
	position = UDim2.new(0.5, 0, 0, 8), size = UDim2.new(0.78, 0, 0, 170),
	bg = C.BgPanel, transparency = 0.06, ornaments = true, ornamentSize = 10 })
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(700, 170)
limit.Parent = panel
local counter = UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 8), size = UDim2.new(1, -28, 0, 17),
	text = "", font = "Number", textSize = UiTheme.TextSizes.XS, color = C.TextSecondary,
	alignX = Enum.TextXAlignment.Center })
local title = UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 24), size = UDim2.new(1, -28, 0, 32),
	text = "", font = "Title", textSize = 30, color = C.GoldBright, alignX = Enum.TextXAlignment.Center })
local body = UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 58), size = UDim2.new(1, -28, 0, 58),
	text = "", font = "Body", textSize = 21, minTextSize = 15, maxTextSize = 21, scaled = true, richText = true,
	color = C.TextPrimary, wrap = true, alignX = Enum.TextXAlignment.Center })
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
local check = UiTheme.label({ name = "Check", parent = panel, anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.45),
	size = UDim2.fromOffset(300, 60), text = "", font = "Title", textSize = 44, color = C.Success, alignX = Enum.TextXAlignment.Center, zIndex = 20 })
check.TextStrokeTransparency = 0.2
local skip = UiTheme.button({ name = "Skip", parent = panel, anchor = Vector2.new(1, 1),
	position = UDim2.new(1, -8, 1, -6), size = UDim2.fromOffset(150, 32), text = L.t("gt.skip"),
	textSize = 14, minTextSize = 12, maxTextSize = 14, scaled = true, variant = "secondary",
	onClick = function() GuidedRemote:FireServer("Skip") end })

-- Botón de Armería: solo en su paso, a la izquierda (donde está en la ciudad), en carmesí y con una flecha que lo señala
local armoryHolder = Instance.new("Frame")
armoryHolder.Name = "ArmoryCallout"
armoryHolder.AnchorPoint = Vector2.new(0, 0.5)
armoryHolder.Position = UDim2.new(0, 16, 0.5, 0)
armoryHolder.Size = UDim2.fromOffset(300, 60)
armoryHolder.BackgroundTransparency = 1
armoryHolder.Visible = false
armoryHolder.Parent = gui
local armory = UiTheme.button({ name = "TutorialArmory", parent = armoryHolder, size = UDim2.fromOffset(190, 56),
	text = L.t("ui.lobby.dock.armory"), icon = "armory", iconSize = 24, font = "Title", textSize = 22, variant = "focal",
	onClick = function()
		local toggle = player:FindFirstChild("ToggleArmory")
		if toggle then toggle:Fire(true) end
	end })
local arrow = UiTheme.label({ name = "Arrow", parent = armoryHolder, anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 200, 0.5, 0),
	size = UDim2.fromOffset(90, 56), text = "◀", font = "Title", textSize = 48, color = C.GoldBright, alignX = Enum.TextXAlignment.Left })
arrow.TextStrokeTransparency = 0.2
RunService.RenderStepped:Connect(function()
	if armoryHolder.Visible then
		arrow.Position = UDim2.new(0, 200 + math.abs(math.sin(os.clock() * 5)) * 14, 0.5, 0)
	end
end)

-- 12/11/2026 (pedido del usuario): después de la infusión, una ficha rápida de qué hace cada infusión y cada arma
local UiAssets = require(ReplicatedStorage:WaitForChild("UiAssets"))
local Infusions = require(ReplicatedStorage:WaitForChild("Infusions"))
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local codexCard = UiTheme.panel({ name = "Codex", parent = gui, anchor = Vector2.new(0.5, 0), position = UDim2.new(0.5, 0, 0, 190),
	size = UDim2.fromOffset(760, 330), bg = C.BgPrimary, transparency = 0.04, ornaments = true, ornamentSize = 10 })
codexCard.Visible = false
local codexScale = Instance.new("UIScale")
codexScale.Parent = codexCard
local advanceRef -- se completa más abajo (advance se define después)
local function buildCodex()
	for _, ch in codexCard:GetChildren() do
		if ch:IsA("GuiObject") and ch.Name ~= "FrameArt" and ch.Name ~= "Ornaments" then ch:Destroy() end
	end
	local function section(y, text)
		UiTheme.label({ parent = codexCard, position = UDim2.fromOffset(20, y), size = UDim2.new(1, -40, 0, 22), text = text,
			font = "Title", textSize = 20, color = C.GoldBright })
	end
	section(12, L.t("gt.codex.infusions"))
	for i, id in Infusions.Order do
		local def = Infusions.get(id)
		local cell = Instance.new("Frame")
		cell.BackgroundTransparency = 1
		cell.Position = UDim2.fromOffset(20 + (i - 1) * 182, 38)
		cell.Size = UDim2.fromOffset(176, 92)
		cell.Parent = codexCard
		local ic = UiAssets.icon(cell, id, 34, def and def.color or C.TextPrimary)
		ic.Position = UDim2.fromOffset(0, 2)
		UiTheme.label({ parent = cell, position = UDim2.fromOffset(40, 0), size = UDim2.new(1, -40, 0, 22), text = L.t("infusion." .. id),
			font = "Header", textSize = 18, color = def and def.color or C.TextPrimary })
		local d = UiTheme.label({ parent = cell, position = UDim2.fromOffset(0, 40), size = UDim2.new(1, -4, 0, 50),
			text = L.t("infusionMotto." .. id), font = "Body", textSize = 15, color = C.TextSecondary,
			alignY = Enum.TextYAlignment.Top })
		d.TextWrapped = true
	end
	section(136, L.t("gt.codex.weapons"))
	for i, id in WeaponData.Order do
		local cell = Instance.new("Frame")
		cell.BackgroundTransparency = 1
		cell.Position = UDim2.fromOffset(20 + (i - 1) * 145, 162)
		cell.Size = UDim2.fromOffset(140, 104)
		cell.Parent = codexCard
		UiTheme.label({ parent = cell, size = UDim2.new(1, 0, 0, 22), text = L.t("weapon." .. id), font = "Header", textSize = 18,
			color = C.TextPrimary })
		local d = UiTheme.label({ parent = cell, position = UDim2.fromOffset(0, 24), size = UDim2.new(1, -6, 0, 78),
			text = L.t("weaponDesc." .. id), font = "Body", textSize = 15, color = C.TextSecondary, alignY = Enum.TextYAlignment.Top })
		d.TextWrapped = true
	end
	UiTheme.label({ parent = codexCard, position = UDim2.fromOffset(20, 270), size = UDim2.new(1, -230, 0, 44),
		text = L.t("gt.codex.hint"), font = "Body", textSize = 15, color = C.TextSecondary, alignY = Enum.TextYAlignment.Top }).TextWrapped = true
	UiTheme.button({ name = "CodexOk", parent = codexCard, anchor = Vector2.new(1, 1), position = UDim2.new(1, -16, 1, -14),
		size = UDim2.fromOffset(190, 48), text = L.t("gt.codex.ok"), font = "Title", textSize = 20, variant = "focal",
		onClick = function() if advanceRef then advanceRef() end end })
end

local index, count = 1, 0
local seenDirs = {}
local comboTimes = {}
local lastDir = ""
local lastLock
local visitedInfusions = false
local attemptedThrow = false
local needs = { light = G.LightHits, dirs = 3, block = G.BlocksNeeded }

local function render()
	local step = G.Steps[index]
	title.Text = L.t("gt." .. step .. ".title")
	body.Text = stepText(step)
	counter.Text = L.t("gt.counter", { step = index, total = #G.Steps })
	if needs[step] then counter.Text ..= (" · %d/%d"):format(count, needs[step]) end
	skip.Text = L.t("gt.skip")
	armory.Text = L.t("ui.lobby.dock.armory")
	skip.Visible = step ~= "done"
	armoryHolder.Visible = step == "armory" and gui.Enabled
	local showCodex = step == "codex" and gui.Enabled
	if showCodex and not codexCard.Visible then
		buildCodex()
		local vp = gui.AbsoluteSize
		local fit = math.clamp(math.min((vp.X - 24) / 760, (vp.Y - 200) / 330), 0.5, 1)
		codexScale.Scale = fit * 0.9
		game:GetService("TweenService"):Create(codexScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit }):Play()
		if Device.isGamepad() then game:GetService("GuiService").SelectedObject = codexCard:FindFirstChild("CodexOk", true) end
	end
	codexCard.Visible = showCodex
	player:SetAttribute("TutorialAction", STEP_ACTION[step])
end

local function advance()
	if index >= #G.Steps then return end
	index += 1
	count = 0
	table.clear(seenDirs)
	table.clear(comboTimes)
	player:SetAttribute("TutorialLesson", G.Steps[index])
	GuidedRemote:FireServer("Step", index)
	UiTheme.playSound("UI_PurchaseOK")
	-- «¡Bien!» y el panel salta un poco: se nota que el paso cambió
	check.Text = L.t("gt.good")
	check.TextTransparency = 0
	check.TextStrokeTransparency = 0.2
	panelScale.Scale = 1.08
	game:GetService("TweenService"):Create(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	game:GetService("TweenService"):Create(check, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	render()
	if G.Steps[index] == "done" then
		task.delay(3, function()
			if player:GetAttribute("InTutorial") then GuidedRemote:FireServer("Done") end
		end)
	end
end

advanceRef = function() if G.Steps[index] == "codex" then advance() end end

local function bump(id)
	if not gui.Enabled or G.Steps[index] ~= id then return end
	count += 1
	if count >= (needs[id] or 1) then advance() else UiTheme.playSound("UI_Click") render() end
end

Effect.OnClientEvent:Connect(function(kind, role, info)
	if kind ~= "Feel" or not gui.Enabled then return end
	local id = G.Steps[index]
	if role == "Deal" then
		local hitKind = type(info) == "table" and info.kind or "Light"
		if id == "light" and hitKind == "Light" then bump("light")
		elseif id == "heavy" and hitKind == "Heavy" then bump("heavy")
		elseif id == "dirs" and table.find({ "Up", "Left", "Right" }, lastDir) and not seenDirs[lastDir] then
			seenDirs[lastDir] = true
			bump("dirs")
		elseif id == "combo" and hitKind == "Light" then
			local now = os.clock()
			table.insert(comboTimes, now)
			while comboTimes[1] and now - comboTimes[1] > G.ComboWindow do table.remove(comboTimes, 1) end
			if #comboTimes >= 3 then bump("combo") end
		end
	elseif role == "Block" then
		bump("block")
	elseif role == "Parry" then
		if id == "block" then bump("block") else bump("parry") end
	end
end)

local function watchCharacter(char)
	char:GetAttributeChangedSignal("AttackDir"):Connect(function()
		local direction = char:GetAttribute("AttackDir")
		if type(direction) == "string" and direction ~= "" then lastDir = direction end
	end)
	char:GetAttributeChangedSignal("Action"):Connect(function()
		if char:GetAttribute("Action") == "Dodge" then bump("dodge") end
	end)
	char:GetAttributeChangedSignal("Carrying"):Connect(function()
		if char:GetAttribute("Carrying") then
			bump("carry")
		elseif attemptedThrow and gui.Enabled and G.Steps[index] == "throw" then
			advance()
		end
	end)
	char:GetAttributeChangedSignal("ThrowCharging"):Connect(function()
		if gui.Enabled and G.Steps[index] == "throw" and char:GetAttribute("ThrowCharging") then attemptedThrow = true end
	end)
	char:GetAttributeChangedSignal("InfusionActive"):Connect(function()
		if char:GetAttribute("InfusionActive") then bump("infuse") end
	end)
end
player.CharacterAdded:Connect(watchCharacter)
if player.Character then watchCharacter(player.Character) end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then return end
	acc += dt
	if acc < 0.12 then return end
	acc = 0
	local id = G.Steps[index]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local lock = player:FindFirstChild("LockTarget")
	local target = lock and lock.Value
	if id == "move" then
		local yards = workspace:FindFirstChild("TrainingYards")
		local yard = yards and yards:FindFirstChild(tostring(player.UserId))
		local marker = yard and yard:FindFirstChild("TutorialMarker")
		if root and marker and ((root.Position - marker.Position) * Vector3.new(1, 0, 1)).Magnitude <= G.MarkerReach then advance() end
	elseif id == "lock" then
		if target then lastLock = target advance() end
	elseif id == "switch" then
		if target and lastLock and target ~= lastLock then advance()
		elseif target then lastLock = lastLock or target end
	elseif id == "down" and target and target:GetAttribute("KnockedDown") then
		advance()
	elseif id == "throw" and char then
		body.Text = char:GetAttribute("Carrying") and stepText(id)
			or L.t("gt.throw.recover", { kick = key("Kick"), heavy = key("Heavy") })
	end
end)

local function focusTutorial()
	if Device.isGamepad() and gui.Enabled and G.Steps[index] == "armory" then
		game:GetService("GuiService").SelectedObject = armory
	end
end
player:GetAttributeChangedSignal("TutorialLesson"):Connect(focusTutorial)
player:GetAttributeChangedSignal("TutorialArmoryTab"):Connect(function()
	if player:GetAttribute("TutorialArmoryTab") == "Infusions" then visitedInfusions = true end
end)
player:GetAttributeChangedSignal("ArmoryOpen"):Connect(function()
	if visitedInfusions and not player:GetAttribute("ArmoryOpen") and G.Steps[index] == "armory" then advance() end
end)

local function updateLayout()
	local compact = gui.AbsoluteSize.Y > 0 and gui.AbsoluteSize.Y < 440
	local height = compact and 132 or 170
	limit.MaxSize = Vector2.new(700, height)
	panel.Size = UDim2.new(compact and 0.67 or 0.78, 0, 0, height)
	title.Position = UDim2.fromOffset(14, compact and 20 or 24)
	title.TextSize = compact and 24 or 30
	body.Position = UDim2.fromOffset(14, compact and 46 or 58)
	body.Size = UDim2.new(1, -28, 0, compact and 44 or 58)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
updateLayout()

local wasInYard = false
local function refresh()
	local inYard = player:GetAttribute("InTutorial") == true
	if inYard and not wasInYard then
		index, count = 1, 0
		visitedInfusions, attemptedThrow = false, false
		player:SetAttribute("TutorialLesson", G.Steps[1])
	elseif not inYard then
		player:SetAttribute("TutorialLesson", nil)
		player:SetAttribute("TutorialAction", nil)
		armoryHolder.Visible = false
		codexCard.Visible = false
	end
	wasInYard = inYard
	gui.Enabled = inYard and not player:GetAttribute("InitialLoading") and not player:GetAttribute("MainMenuOpen")
		and not player:GetAttribute("MenuOpen")
	if gui.Enabled then render() focusTutorial() else armoryHolder.Visible = false codexCard.Visible = false end
end
for _, attr in { "InTutorial", "InitialLoading", "MainMenuOpen", "MenuOpen" } do
	player:GetAttributeChangedSignal(attr):Connect(refresh)
end
task.spawn(function()
	local changed = player:WaitForChild("BindsChanged", 10)
	if changed then changed.Event:Connect(function(newBinds)
		binds = newBinds
		if gui.Enabled then render() end
	end) end
end)
Device.Changed:Connect(refresh)
L.Changed:Connect(refresh)
refresh()
