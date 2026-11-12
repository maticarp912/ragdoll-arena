-- ModuleScript: ReplicatedStorage/InputBridge
-- Responsable: Claude. Contrato de la etapa 8 entre la interfaz táctil (Gemini) y Controls (Claude).
--
-- La interfaz táctil llama:
--   InputBridge.press(actionId, true)   al apoyar el dedo
--   InputBridge.press(actionId, false)  al soltarlo
-- actionId es un id de InputMap.Actions: Attack, Heavy, Block, Dodge, Interact, Kick, Infuse,
-- LockOn, SwitchTarget, Menu. Block se mantiene (true al apoyar, false al soltar); el resto actúa al apoyar.
-- Controls escucha InputBridge.Action y hace lo mismo que con el teclado o el mando.
-- Para apuntar el lanzamiento se usa la dirección de la cámara (no hace falta un joystick extra).

local InputBridge = {}

local event = Instance.new("BindableEvent")
InputBridge.Action = event.Event
local stance = Instance.new("BindableEvent")
InputBridge.Stance = stance.Event

function InputBridge.selectStance(direction)
	stance:Fire(direction)
end

function InputBridge.press(actionId, isDown)
	event:Fire(actionId, isDown == true)
end

return InputBridge
