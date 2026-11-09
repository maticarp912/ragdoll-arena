-- Aura y estados visuales. Sólo observa atributos replicados por el servidor.
local RS = game:GetService("ReplicatedStorage")
local Collection = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Infusions = require(RS:WaitForChild("Infusions"))
local A = require(RS:WaitForChild("PolishConfig")).Aura
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
 for _, obj in st.objects do obj:Destroy() end
 for trail, color in st.trails do if trail.Parent then trail.Color = color end end
 st.objects = {}
 st.trails = {}
end
local function add(st, obj) table.insert(st.objects, obj) return obj end
local function weapon(st, tool, id)
 local def = Infusions.get(id)
 local h = add(st, Instance.new("Highlight"))
 h.Adornee = tool
 h.FillColor = def.color
 h.OutlineColor = def.color
 h.FillTransparency = A.FreezeAlpha
 h.Parent = tool
 -- Las skins con muchas piezas de hoja solo llevan partículas en las más grandes
 local blades = {}
 for _, obj in tool:GetDescendants() do
  if obj:IsA("BasePart") and obj:GetAttribute("Role") == "Blade" then
   table.insert(blades, obj)
  elseif obj:IsA("Trail") and obj.Name == "SwingTrail" then
   st.trails[obj] = obj.Color
   obj.Color = ColorSequence.new(def.color)
  end
 end
 table.sort(blades, function(a, b) return a.Size.Magnitude > b.Size.Magnitude end)
 for i = 1, math.min(#blades, A.MaxBladeEmitters or 4) do
  local obj = blades[i]
  add(st, emitter(obj, id))
  emitter(obj, id, true)
  if id == "Ice" then
   local crystal = add(st, emitter(obj, id))
   crystal.Texture = A.Crystal
  end
 end
 local tip, base
 for _, obj in tool:GetDescendants() do
  if obj:IsA("Attachment") then
   if obj.Name == "BladeTip" then tip = obj elseif obj.Name == "BladeBase" then base = obj end
  end
 end
 if tip then
  local light = add(st, Instance.new("PointLight"))
  light.Color = def.color
  light.Brightness = A.Light
  light.Range = A.Range
  light.Parent = tip
 end
 if id == "Lightning" and tip and base and tip:IsA("Attachment") and base:IsA("Attachment") then
  local beam = add(st, Instance.new("Beam"))
  beam.Attachment0 = base
  beam.Attachment1 = tip
  beam.Color = ColorSequence.new(def.color)
  beam.Width0 = A.BeamWidth
  beam.Width1 = A.BeamWidth
  beam.FaceCamera = true
  beam.Parent = base
 end
end
local function watch(char)
 if states[char] then return end
 states[char] = { objects = {}, trails = {}, weapons = {}, id = nil }
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
  local id = alive and char:GetAttribute("InfusionActive") and char:GetAttribute("InfusionId") or nil
  if id ~= st.id then
   clear(st) st.weapons = {} st.id = id
   if id and root and Infusions.get(id) then
    local feet = add(st, Instance.new("Attachment"))
    feet.Position = A.Feet feet.Parent = root
    add(st, emitter(feet, id)) emitter(feet, id, true)
   end
  end
  if id and Infusions.get(id) then
   for _, child in char:GetChildren() do
    if (child:IsA("Tool") or child.Name == "OffhandWeapon") and not st.weapons[child] then
     st.weapons[child] = true weapon(st, child, id)
    end
   end
   for _, obj in st.objects do
    if obj:IsA("Beam") then
     obj.CurveSize0 = (math.random() * 2 - 1) * A.Curve
     obj.CurveSize1 = (math.random() * 2 - 1) * A.Curve
    end
   end
  end
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
