-- Aura y estados visuales. Sólo observa atributos replicados por el servidor.
local RS = game:GetService("ReplicatedStorage")
local Collection = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Infusions = require(RS:WaitForChild("Infusions"))
local A = require(RS:WaitForChild("PolishConfig")).Aura
local AuraFx = require(RS:WaitForChild("AuraFx"))
local states = {}
local function emitter(parent, id, burst)
 local def = Infusions.get(id)
 local p = Instance.new("ParticleEmitter")
 p.Texture = A.Textures[id]
 p.Color = ColorSequence.new(def.color, def.color2)
 p.Lifetime = A.Life
 local profile = A.Profiles[id]
 p.Speed = profile.Speed
 p.Size = profile.Size
 p.Acceleration = profile.Acceleration
 p.Drag = profile.Drag
 p.SpreadAngle = A.Spread
 p.LightEmission = id == "Shadow" and 0 or 1
 p.Rate = burst and 0 or A.Rate
 p.Parent = parent
 if burst then p:Emit(A.Burst) Debris:AddItem(p, A.Life.Max) end
 return p
end
local function clear(st)
 if st.feet then st.feet:Destroy() st.feet = nil end
 for _, cleanup in st.weapons do cleanup() end
 table.clear(st.weapons)
end

local function syncWeapons(char, st, id)
 for weapon, cleanup in st.weapons do
  if weapon.Parent ~= char then cleanup() st.weapons[weapon] = nil end
 end
 for _, child in char:GetChildren() do
  local isWeapon = (child:IsA("Tool") or child.Name == "OffhandWeapon") and child:GetAttribute("WeaponId")
  if isWeapon and not st.weapons[child] then st.weapons[child] = AuraFx.attachInfusion(child, id) end
 end
end
local function watch(char)
 if states[char] then return end
 states[char] = { weapons = {} }
end
Collection:GetInstanceAddedSignal("Combatant"):Connect(watch)
for _, char in Collection:GetTagged("Combatant") do watch(char) end
Collection:GetInstanceRemovedSignal("Combatant"):Connect(function(char)
 local st = states[char]
 if st then clear(st) if st.burn then st.burn:Destroy() end if st.frost then st.frost:Destroy() end end
 states[char] = nil
end)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
 elapsed += dt
 if elapsed < A.Update then return end
 elapsed = 0
 local now = workspace:GetServerTimeNow()
 for char, st in states do
  local root = char:FindFirstChild("HumanoidRootPart")
  local hum = char:FindFirstChildOfClass("Humanoid")
  local alive = char.Parent and hum and hum.Health > 0
  local camera = workspace.CurrentCamera
  local near = root and camera and (root.Position - camera.CFrame.Position).Magnitude <= Infusions.Aura.MaxDistance
  local id = alive and near and char:GetAttribute("InfusionActive") and char:GetAttribute("InfusionId") or nil
  if id and not Infusions.get(id) then id = nil end
  if id ~= st.id then
   clear(st)
   st.id = id
   if id then
    local feet = Instance.new("Attachment")
    feet.Position = A.Feet
    feet.Parent = root
    st.feet = feet
    emitter(feet, id)
    emitter(feet, id, true)
   end
  end
  if id then syncWeapons(char, st, id) end
  local burn = alive and root and (char:GetAttribute("BurnUntil") or 0) > now
  if burn and not st.burn then st.burn = emitter(root, "Fire")
  elseif not burn and st.burn then st.burn:Destroy() st.burn = nil end
  local frost = alive and ((char:GetAttribute("SlowUntil") or 0) > now or (char:GetAttribute("FragileUntil") or 0) > now)
  if frost and not st.frost then
   st.frost = Instance.new("Highlight") st.frost.FillColor = Infusions.get("Ice").color
   st.frost.FillTransparency = A.FreezeAlpha st.frost.Adornee = char st.frost.Parent = char
  elseif not frost and st.frost then st.frost:Destroy() st.frost = nil end
  local shock = char:GetAttribute("ShockedAt")
  if shock ~= st.shock then st.shock = shock if alive and root and shock then emitter(root, "Lightning", true) end end
 end
end)
RS:WaitForChild("Remotes"):WaitForChild("Effect").OnClientEvent:Connect(function(kind, pos, id, dir)
 if kind ~= "InfusionHit" or not Infusions.get(id) then return end
 local anchor = Instance.new("Part")
 anchor.Anchored = true anchor.CanCollide = false anchor.CanQuery = false anchor.CanTouch = false anchor.Transparency = 1
 anchor.CFrame = CFrame.lookAt(pos, pos + (dir or Vector3.yAxis)) anchor.Parent = workspace
 local burst = emitter(anchor, id, true)
 if id == "Ice" then burst.Texture = A.Crystal end
 Debris:AddItem(anchor, A.Life.Max)
end)
