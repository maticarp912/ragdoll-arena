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
local function key(action)
	if Device.isTouch() then return L.t("ui.touch." .. touchKeys[action]) end
	local device = Device.isGamepad() and "Gamepad" or "Keyboard"
	return InputMap.label(binds[device][action])
end
local function dirHint()
	if Device.isTouch() then return L.t("gt.dirTouch") end
	return Device.isGamepad() and L.t("gt.dirPad") or L.t("gt.dirMouse")
end
local function stepText(id)
	return L.t("gt." .. id .. ".body", {
		move = Device.isTouch() and L.t("gt.stick") or (Device.isGamepad() and L.t("gt.leftStick") or "W A S D"),
		lock = key("LockOn"), switch = key("SwitchTarget"), attack = key("Attack"), heavy = key("Heavy"),
		kick = key("Kick"), block = key("Block"), dodge = key("Dodge"), infuse = key("Infuse"), dirs = dirHint(),
	})
end

local gui = Instance.new("ScreenGui")
gui.Name = "GuidedTutorial"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = UiTheme.panel({ name = "Steps", parent = gui, anchor = Vector2.new(0.5, 0),
	position = UDim2.new(0.5, 0, 0, 8), size = UDim2.new(0.78, 0, 0, 153),
	bg = C.BgPanel, transparency = 0.06, ornaments = true, ornamentSize = 10 })
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(640, 153)
limit.Parent = panel
local counter = UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 8), size = UDim2.new(1, -28, 0, 17),
	text = "", font = "Number", textSize = UiTheme.TextSizes.XS, color = C.TextSecondary,
	alignX = Enum.TextXAlignment.Center })
local title = UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 25), size = UDim2.new(1, -28, 0, 24),
	text = "", font = "Title", textSize = 23, color = C.TextPrimary, alignX = Enum.TextXAlignment.Center })
local body = UiTheme.label({ parent = panel, position = UDim2.fromOffset(14, 49), size = UDim2.new(1, -28, 0, 51),
	text = "", font = "Body", textSize = 17, minTextSize = 13, maxTextSize = 17, scaled = true,
	color = C.TextPrimary, wrap = true, alignX = Enum.TextXAlignment.Center })
local skip = UiTheme.button({ name = "Skip", parent = panel, anchor = Vector2.new(1, 1),
	position = UDim2.new(1, -8, 1, -6), size = UDim2.new(0.49, -5, 0, 44), text = L.t("gt.skip"),
	textSize = 16, minTextSize = 13, maxTextSize = 16, scaled = true, variant = "secondary",
	onClick = function() GuidedRemote:FireServer("Skip") end })
local armory = UiTheme.button({ name = "TutorialArmory", parent = panel, anchor = Vector2.new(0, 1),
	position = UDim2.new(0, 8, 1, -6), size = UDim2.new(0.49, -5, 0, 44), text = L.t("ui.lobby.dock.armory"),
	textSize = 16, minTextSize = 13, maxTextSize = 16, scaled = true, variant = "primary",
	onClick = function()
		local toggle = player:FindFirstChild("ToggleArmory")
		if toggle then toggle:Fire(true) end
	end })

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
	armory.Visible = step ~= "done"
end

local function advance()
	if index >= #G.Steps then return end
	index += 1
	count = 0
	table.clear(seenDirs)
	table.clear(comboTimes)
	player:SetAttribute("TutorialLesson", G.Steps[index])
	GuidedRemote:FireServer("Step", index)
	UiTheme.playSound("UI_Equip")
	render()
	if G.Steps[index] == "done" then
		task.delay(3, function()
			if player:GetAttribute("InTutorial") then GuidedRemote:FireServer("Done") end
		end)
	end
end

local function bump(id)
	if not gui.Enabled or G.Steps[index] ~= id then return end
	count += 1
	if count >= (needs[id] or 1) then advance() else render() end
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
	local height = compact and 122 or 153
	limit.MaxSize = Vector2.new(640, height)
	panel.Size = UDim2.new(compact and 0.67 or 0.78, 0, 0, height)
	title.Position = UDim2.fromOffset(14, compact and 19 or 25)
	title.TextSize = compact and 19 or 23
	body.Position = UDim2.fromOffset(14, compact and 40 or 49)
	body.Size = UDim2.new(1, -28, 0, compact and 35 or 51)
	local buttonHeight = compact and 40 or 44
	skip.Size = UDim2.new(0.49, -5, 0, buttonHeight)
	armory.Size = skip.Size
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
	end
	wasInYard = inYard
	gui.Enabled = inYard and not player:GetAttribute("InitialLoading") and not player:GetAttribute("MainMenuOpen")
		and not player:GetAttribute("MenuOpen")
	if gui.Enabled then render() focusTutorial() end
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
