-- World-only cosmetic renderer. No Highlight, recolouring or physics on the weapon.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Auras = require(script.Parent:WaitForChild("Auras"))
local F = Auras.Fx
local Fx = {}
function Fx.attach(target, auraId, options)
 options = options or {}
 local data = Auras.Data[auraId]
 if not data or not target or not target.Parent then return function() end end
 local body = data.kind == "Body"
 local root = body and target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Handle", true)
 if not root then root = target:FindFirstChildWhichIsA("BasePart", true) end
 local bladeBase = target:FindFirstChild("BladeBase", true)
 local bladeTip = target:FindFirstChild("BladeTip", true)
 if not root or (not body and (not bladeBase or not bladeTip or not bladeBase:IsA("Attachment") or not bladeTip:IsA("Attachment"))) then return function() end end
 local char = options.character or (body and target or target:FindFirstAncestorOfClass("Model"))
 local owner = char and Players:GetPlayerFromCharacter(char)
 local folder = Instance.new("Folder") folder.Name = "CosmeticAura" folder.Parent = target
 local holder = Instance.new("Part") holder.Name = "AuraOrigin" holder.Size = F.HolderSize
 holder.Transparency = F.One holder.Anchored = true holder.CanCollide = false holder.CanQuery = false holder.CanTouch = false holder.CastShadow = false holder.CFrame = root.CFrame holder.Parent = folder
 local nodes, beams, emitters = {}, {}, {}
 local function node()
  local a = Instance.new("Attachment") a.Parent = holder table.insert(nodes,a) return a
 end
 local function beam(a,b)
  local obj = Instance.new("Beam") obj.Attachment0 = a obj.Attachment1 = b obj.Width0 = F.BeamWidth obj.Width1 = F.BeamWidth
  obj.FaceCamera = true obj.LightInfluence = F.LightInfluence obj.Segments = F.Segments obj.Color = ColorSequence.new(data.color) obj.LightEmission = F.LightEmission obj.Transparency = NumberSequence.new(F.Transparency) obj.Parent = holder
  table.insert(beams,obj)
 end
 local function path(count,closed)
  local list = {} for _ = F.One,count do table.insert(list,node()) end
  for i = F.Two,#list do beam(list[i-F.One],list[i]) end
  if closed then beam(list[#list],list[F.One]) end
  return list
 end
 local function emitter(a,smoke)
  local e = Instance.new("ParticleEmitter") e.Texture = smoke and F.SmokeTexture or F.SparkTexture
  e.Color = ColorSequence.new(data.color) e.Rate = body and F.BodyRate or F.WeaponRate
  e.Lifetime = F.Life e.Speed = F.Speed e.Size = F.Size e.SpreadAngle = F.Spread
  e.Rotation = F.Rotation e.RotSpeed = F.Spin e.LightInfluence = F.LightInfluence e.LightEmission = F.LightEmission
  e.Transparency = NumberSequence.new(F.Transparency,F.One) e.Parent = a
  table.insert(emitters,{ effect=e, rate=e.Rate }) return e
 end
 local groups = {}
 local pattern = data.pattern
 local source = node()
 if pattern == "crown" then groups[F.One] = path(F.CrownNodes,true) emitter(source,true)
 elseif pattern == "chains" then for _=F.One,F.ChainCount do table.insert(groups,path(F.Runes,true)) end
 elseif pattern == "wings" then
  for _=F.One,F.Two do local list=path(#F.WingPath,false) table.insert(groups,list) emitter(list[F.Two],true) end
  for _,b in beams do b.Width0=F.WingWidth b.Width1=F.WingWidth*F.Half b.Texture=F.SmokeTexture b.TextureMode=Enum.TextureMode.Stretch b.TextureSpeed=F.WingTextureSpeed end
 elseif pattern == "mist" then local e=emitter(source,true) e.Size=F.MistSize e.Speed=F.Speed
 elseif pattern == "eyes" then
  for _=F.One,F.Eyes do local list=path(F.Runes,true) local pupil=path(F.Two,false) table.insert(groups,{outline=list,pupil=pupil}) end
 elseif pattern == "runes" then for _=F.One,F.Runes do table.insert(groups,path(#F.RunePath,false)) end
 elseif pattern == "fracture" then groups[F.One]=path(F.FractureNodes,false) emitter(source,false)
 else
  local e=emitter(source,pattern=="drip")
  if pattern=="blood" then e.Size=F.BloodSize e.Acceleration=F.BloodGravity e.Speed=F.DownSpeed e.EmissionDirection=Enum.NormalId.Bottom
  elseif pattern=="drip" then e.Acceleration=F.DripGravity e.EmissionDirection=Enum.NormalId.Bottom
  else e.Acceleration=F.EmberGravity end
 end
 local stopped=false
 local connection
 local function cleanup()
  if stopped then return end stopped=true
  if connection then connection:Disconnect() end
  folder:Destroy()
 end
 local previous=F.One
 local function update()
  if stopped then return end
  if not target.Parent or not root.Parent or not folder.Parent then cleanup() return end
  local t=workspace:GetServerTimeNow()
  local angle=t*F.OrbitSpeed
  local factor=F.One
  local simple=false
  if not options.preview then
   if char then
    local telegraph=char:GetAttribute("Telegraph")
    if telegraph and telegraph~="" then factor*=body and F.BodyTelegraph or F.WeaponTelegraph end
    if not body and char:GetAttribute("InfusionActive") then factor=F.Zero end
    simple=char:GetAttribute("Ragdolled")==true or char:GetAttribute("KnockedDown")==true or (char:GetAttribute("CarriedBy")~=nil and char:GetAttribute("CarriedBy")~=F.Zero and char:GetAttribute("CarriedBy")~="" and char:GetAttribute("CarriedBy")~=false)
    if simple then factor*=F.Simplified end
   end
   local localPlayer=Players.LocalPlayer
   if localPlayer and localPlayer:GetAttribute("InMatch") and owner~=localPlayer then factor*=F.OtherMatch end
  end
  holder.CFrame=root.CFrame
  if factor<previous then for _,entry in emitters do entry.effect:Clear() end end
  previous=factor
  for _,entry in emitters do entry.effect.Enabled=factor>F.Zero entry.effect.Rate=entry.rate*factor end
  for _,b in beams do b.Enabled=factor>F.Zero and not simple b.Transparency=NumberSequence.new(F.One-(F.One-F.Transparency)*factor) end
  local bob=math.sin(t*F.BobSpeed)*F.BobSize
  local function orbit(radius,height,a) return Vector3.new(math.cos(a)*radius,height,math.sin(a)*radius) end
  if pattern=="crown" then
   source.Position=Vector3.new(F.Zero,F.CrownHeight,F.Zero)
   for i,a in groups[F.One] do a.Position=orbit(F.CrownRadius,F.CrownHeight+bob+(i%F.Two)*F.CrownTooth,angle+i/F.CrownNodes*math.pi*F.Two) end
  elseif pattern=="chains" then
   for i,list in groups do
    local a=angle+i/F.ChainCount*math.pi*F.Two local center=orbit(F.ChainRadius,F.ChainHeight+math.sin(a)*F.Half,a)
    local tangent=Vector3.new(-math.sin(a),F.Zero,math.cos(a))*F.ChainHalf
    list[F.One].Position=center+tangent list[F.Two].Position=center+Vector3.yAxis*F.ChainHalf list[F.Two+F.One].Position=center-tangent list[F.Runes].Position=center-Vector3.yAxis*F.ChainHalf
   end
  elseif pattern=="wings" then
   for side,list in groups do local sign=side==F.One and -F.One or F.One
    for i,a in list do local v=F.WingPath[i] a.Position=Vector3.new(v.X*sign,v.Y+bob,v.Z+math.sin(t)*F.WingFlap*math.abs(v.X)) end
   end
  elseif pattern=="mist" then source.Position=orbit(F.MistRadius,F.FeetY,angle)
  elseif pattern=="eyes" then
   for i,g in groups do
    local center=orbit(F.EyeRadius,F.EyeHeight+bob,angle+i/F.Eyes*math.pi*F.Two)
    local blink=math.max(F.Zero,math.sin(t*F.BlinkSpeed+i))
    g.outline[F.One].Position=center-Vector3.xAxis*F.EyeWidth g.outline[F.Two].Position=center+Vector3.yAxis*F.EyeOpen*blink
    g.outline[F.Two+F.One].Position=center+Vector3.xAxis*F.EyeWidth g.outline[F.Runes].Position=center-Vector3.yAxis*F.EyeOpen*blink
    g.pupil[F.One].Position=center-Vector3.yAxis*F.EyeOpen*blink g.pupil[F.Two].Position=center+Vector3.yAxis*F.EyeOpen*blink
   end
  elseif pattern=="runes" then
   for i,list in groups do
    local cf=CFrame.new(orbit(F.RuneRadius,F.RuneHeight+bob,-angle+i/F.Runes*math.pi*F.Two))*CFrame.Angles(F.Zero,angle,F.Zero)
    for j,a in list do a.Position=cf:PointToWorldSpace(F.RunePath[j]*F.RuneSize) end
   end
  elseif not body then
   if not bladeBase.Parent or not bladeTip.Parent then cleanup() return end
   local base=holder.CFrame:PointToObjectSpace(bladeBase.WorldPosition)
   local tip=holder.CFrame:PointToObjectSpace(bladeTip.WorldPosition)
   source.Position=pattern=="blood" and tip or base:Lerp(tip,(math.sin(t)+F.One)*F.Half)
   if pattern=="fracture" then
    for i,a in groups[F.One] do local alpha=(i-F.One)/(F.FractureNodes-F.One) a.Position=base:Lerp(tip,alpha)+Vector3.new((i%F.Two==F.Zero and -F.One or F.One)*F.FractureOffset,F.FractureHeight,F.Zero) end
   end
  end
 end
 update()
 if not stopped then connection=RunService.Heartbeat:Connect(update) end
 return cleanup
end
return Fx
