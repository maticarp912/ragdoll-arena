-- ModuleScript: ReplicatedStorage/InputMap
-- Acciones del juego y sus teclas/botones (teclado + ratón y mando/joystick).
-- Cada jugador puede reasignarlas en Menú (B) > Controles; se guardan en su perfil (PlayerData.Keybinds).

local InputMap = {}

InputMap.Actions = {
	{ id = "Attack", name = "Combo (ataque)" },
	{ id = "Heavy", name = "Fuerte / cargar lanzamiento" },
	{ id = "Block", name = "Guardia (toque: parry)" },
	{ id = "Dodge", name = "Esquiva" },
	{ id = "Interact", name = "Agarrar / lanzar / levantar" },
	{ id = "Kick", name = "Patada" },
	{ id = "Infuse", name = "Infusión" },
	{ id = "LockOn", name = "Fijar objetivo" },
	{ id = "SwitchTarget", name = "Cambiar objetivo" },
	{ id = "Menu", name = "Menú" },
}

InputMap.Defaults = {
	Keyboard = {
		Attack = "MouseButton1", Heavy = "MouseButton2", Block = "F", Dodge = "Space", Interact = "E",
		Kick = "C", Infuse = "R", LockOn = "Q", SwitchTarget = "T", Menu = "B",
	},
	Gamepad = {
		Attack = "ButtonR1", Heavy = "ButtonR2", Block = "ButtonL1", Dodge = "ButtonB", Interact = "ButtonX",
		Kick = "ButtonL2", Infuse = "ButtonY", LockOn = "ButtonR3", SwitchTarget = "DPadRight", Menu = "DPadUp",
	},
}

-- Atajos fijos además de los asignables (no se muestran en el menú)
InputMap.Extra = {
	ButtonA = "Dodge",        -- A del mando también esquiva
}

-- Teclas reservadas por Roblox que no se pueden asignar
InputMap.Reserved = {
	Escape = true, ButtonStart = true, ButtonSelect = true, Thumbstick1 = true, Thumbstick2 = true,
	W = true, A = true, S = true, D = true, Slash = true, Tab = true, F9 = true, P = true,
}

local LABELS = {
	MouseButton1 = "Clic izq.", MouseButton2 = "Clic der.", MouseButton3 = "Rueda",
	LeftShift = "Shift", RightShift = "Shift der.", LeftControl = "Ctrl", RightControl = "Ctrl der.",
	LeftAlt = "Alt", Space = "Espacio", Return = "Enter", BackSpace = "Borrar",
	ButtonA = "A", ButtonB = "B", ButtonX = "X", ButtonY = "Y",
	ButtonR1 = "RB / R1", ButtonR2 = "RT / R2", ButtonR3 = "R3 (stick der.)",
	ButtonL1 = "LB / L1", ButtonL2 = "LT / L2", ButtonL3 = "L3 (stick izq.)",
	DPadUp = "Cruceta arriba", DPadDown = "Cruceta abajo", DPadLeft = "Cruceta izq.", DPadRight = "Cruceta der.",
	One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
}

function InputMap.label(name)
	if not name or name == "" then return "—" end
	return LABELS[name] or name
end

-- Nombre de una entrada ("E", "MouseButton1", "ButtonR2"...)
function InputMap.inputName(input)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
		return t.Name
	end
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		return input.KeyCode.Name
	end
	return nil
end

function InputMap.isGamepad(input)
	return string.sub(input.UserInputType.Name, 1, 7) == "Gamepad"
end

-- Une las asignaciones guardadas con las de fábrica (y descarta lo inválido)
function InputMap.merge(saved)
	local out = { Keyboard = {}, Gamepad = {} }
	for device, defaults in InputMap.Defaults do
		local s = type(saved) == "table" and type(saved[device]) == "table" and saved[device] or {}
		for action, def in defaults do
			local v = s[action]
			out[device][action] = (type(v) == "string" and #v <= 32 and not InputMap.Reserved[v]) and v or def
		end
	end
	return out
end

-- Acción asociada a una entrada (o nil)
function InputMap.actionFor(binds, input)
	local name = InputMap.inputName(input)
	if not name then return nil end
	local device = InputMap.isGamepad(input) and "Gamepad" or "Keyboard"
	for action, key in binds[device] do
		if key == name then return action end
	end
	return InputMap.Extra[name]
end

return InputMap
