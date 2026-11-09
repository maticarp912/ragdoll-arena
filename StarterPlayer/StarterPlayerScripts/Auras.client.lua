local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Auras = require(RS:WaitForChild("Auras"))
local Fx = require(RS:WaitForChild("AuraFx"))
local states = {}
local function disconnect(list) for _,c in list do c:Disconnect() end table.clear(list) end
local function clear(state) for _,cleanup in state.effects do cleanup() end table.clear(state.effects) end
local function track(player)
 if states[player] then return end
 local state={ effects={}, connections={}, characterConnections={}, queued=false } states[player]=state
 local function rebuild()
  state.queued=false if states[player]~=state then return end
  clear(state)
  local char=player.Character local id=player:GetAttribute("EquippedAura") local data=Auras.Data[id]
  if not char or not data then return end
  if data.kind=="Body" then table.insert(state.effects,Fx.attach(char,id,{character=char}))
  else
   -- One emitter per weapon; at most primary + offhand = two per character.
   local primary=char:FindFirstChildOfClass("Tool")
   if primary then table.insert(state.effects,Fx.attach(primary,id,{character=char})) end
   local offhand=char:FindFirstChild("OffhandWeapon")
   if offhand then table.insert(state.effects,Fx.attach(offhand,id,{character=char})) end
  end
 end
 local function schedule()
  if state.queued then return end state.queued=true task.defer(rebuild)
 end
 local function character(char)
  disconnect(state.characterConnections) clear(state)
  local function changed(obj)
   if obj:IsA("Tool") or obj.Name=="OffhandWeapon" or obj.Name=="BladeBase" or obj.Name=="BladeTip" or obj.Name=="HumanoidRootPart" then schedule() end
  end
  table.insert(state.characterConnections,char.DescendantAdded:Connect(changed))
  table.insert(state.characterConnections,char.DescendantRemoving:Connect(changed))
  schedule()
 end
 for _,attr in {"EquippedAura","EquippedSkin","WeaponId"} do table.insert(state.connections,player:GetAttributeChangedSignal(attr):Connect(schedule)) end
 table.insert(state.connections,player.CharacterAdded:Connect(character))
 table.insert(state.connections,player.CharacterRemoving:Connect(function() disconnect(state.characterConnections) clear(state) end))
 if player.Character then character(player.Character) end
end
Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(player)
 local state=states[player] if not state then return end states[player]=nil
 disconnect(state.connections) disconnect(state.characterConnections) clear(state)
end)
for _,player in Players:GetPlayers() do track(player) end
