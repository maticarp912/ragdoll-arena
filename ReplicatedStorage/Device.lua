-- ModuleScript: ReplicatedStorage/Device
-- 11/11/2026: detección de dispositivo y de forma de jugar, en un solo lugar para toda la interfaz.
--   Device.platform() → "PC" | "Mobile" | "Console"   (qué aparato es; casi no cambia)
--   Device.input()    → "Keyboard" | "Touch" | "Gamepad" (con qué está jugando AHORA; cambia si enchufa un mando)
--   Device.Changed    → evento (input, platform) cada vez que cambia algo de lo anterior
--   Device.showFor(obj, "Gamepad" | "Touch" | "Keyboard" | { lista }) → muestra obj solo con esa forma de jugar
-- Las pistas de botones («A: Seleccionar · B: Volver», «Q: Fijar»...) tienen que usar Device.showFor y no
-- UserInputService.GamepadEnabled: GamepadEnabled es true en una PC con un mando conectado aunque juegue con mouse.
-- En el cliente también publica los atributos del jugador "Platform" y "InputMode" (solo informativos: el
-- servidor nunca debe confiar en ellos para nada que importe).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Device = {}

local changed = Instance.new("BindableEvent")
Device.Changed = changed.Event

local GAMEPAD = {}
for i = 1, 8 do
	local ok, t = pcall(function() return Enum.UserInputType["Gamepad" .. i] end)
	if ok and t then GAMEPAD[t] = true end
end

local function platformNow()
	-- Consola = pantalla grande (ViewportDisplaySize Large) sin teclado. IsTenFootInterface quedó obsoleta (abril 2026)
	-- y solo se usa si ViewportDisplaySize no existe.
	local okV, size = pcall(function() return (GuiService :: any).ViewportDisplaySize end)
	if okV and size ~= nil then
		if string.find(tostring(size), "Large") and UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then return "Console" end
	else
		local okTen, ten = pcall(function() return GuiService:IsTenFootInterface() end)
		if okTen and ten then return "Console" end
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
		return "Mobile"
	end
	return "PC"
end

-- PreferredInput (API nueva de Roblox) si existe; si no, el último tipo de entrada usado.
local function inputFromPreferred()
	local ok, pref = pcall(function() return (UserInputService :: any).PreferredInput end)
	if not ok or pref == nil then return nil end
	local name = tostring(pref)
	if string.find(name, "Gamepad") then return "Gamepad" end
	if string.find(name, "Touch") then return "Touch" end
	if string.find(name, "Keyboard") then return "Keyboard" end
	return nil
end

local function inputFromType(t)
	if GAMEPAD[t] then return "Gamepad" end
	if t == Enum.UserInputType.Touch then return "Touch" end
	if t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.TextInput
		or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2
		or t == Enum.UserInputType.MouseButton3 or t == Enum.UserInputType.MouseMovement
		or t == Enum.UserInputType.MouseWheel then
		return "Keyboard"
	end
	return nil
end

local current = { platform = "PC", input = "Keyboard" }

local function defaultInput(platform)
	if platform == "Console" then return "Gamepad" end
	if platform == "Mobile" then return "Touch" end
	return "Keyboard"
end

local function publish()
	local player = Players.LocalPlayer
	if player then
		player:SetAttribute("Platform", current.platform)
		player:SetAttribute("InputMode", current.input)
	end
end

local function set(input, platform)
	input = input or current.input
	platform = platform or current.platform
	if input == current.input and platform == current.platform then return end
	current.input, current.platform = input, platform
	publish()
	changed:Fire(input, platform)
end

function Device.platform() return current.platform end
function Device.input() return current.input end
function Device.isGamepad() return current.input == "Gamepad" end
function Device.isTouch() return current.input == "Touch" end

-- Muestra obj solo cuando la forma de jugar está en modes. Se actualiza solo y se limpia al destruir obj.
function Device.showFor(obj, modes)
	if not obj then return obj end
	local list = type(modes) == "table" and modes or { modes }
	local function apply()
		if obj.Parent == nil then return end
		obj.Visible = table.find(list, current.input) ~= nil
	end
	apply()
	local conn
	conn = changed.Event:Connect(function()
		if obj.Parent == nil then conn:Disconnect() return end
		apply()
	end)
	obj.Destroying:Connect(function() if conn then conn:Disconnect() end end)
	return obj
end

if RunService:IsClient() then
	current.platform = platformNow()
	current.input = inputFromPreferred() or inputFromType(UserInputService:GetLastInputType()) or defaultInput(current.platform)
	publish()
	UserInputService.LastInputTypeChanged:Connect(function(t)
		local mode = inputFromType(t)
		if mode then set(mode, platformNow()) end
	end)
	pcall(function()
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
			local mode = inputFromPreferred()
			if mode then set(mode, platformNow()) end
		end)
	end)
	UserInputService.GamepadDisconnected:Connect(function()
		if #UserInputService:GetConnectedGamepads() == 0 and current.input == "Gamepad" then
			set(defaultInput(platformNow()), platformNow())
		end
	end)
end

return Device
