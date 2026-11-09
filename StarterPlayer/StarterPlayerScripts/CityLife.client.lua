local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local C={ Distance=180, Step=0.05, Sway=0.035, Speed=0.8, SmokeRate=3, LeafRate=1, FlyRate=4, MistRate=1, WaterRate=10,
 Smoke="rbxasset://textures/particles/smoke_main.dds", Spark="rbxasset://textures/particles/sparkles_main.dds", Warm=Color3.fromRGB(218,181,102), Leaf=Color3.fromRGB(84,103,63), Water=Color3.fromRGB(120,173,183) }
local V={n0=0,n1=1,n2=0.65,n3=0.4,n4=2,n5=3,n6=5,n7=0.5,n8=1.2,n9=0.8,n10=0.12,n11=180,n12=4,n13=0.3,n14=0.1,n15=50,n16=7,n17=0.2,n18=8,n19=25}
local player=Players.LocalPlayer
local entries={}
local elapsed=V.n0
local function add(obj)
 if entries[obj] then return end
 local kind=obj:GetAttribute("CityLifeKind")
 local entry={kind=kind,cf=obj:IsA("Model") and obj:GetPivot() or obj:IsA("BasePart") and obj.CFrame}
 if not entry.cf then return end
 entries[obj]=entry
 if kind=="Sway" or kind=="Crow" then return end
 if not obj:IsA("BasePart") then return end
 local e=Instance.new("ParticleEmitter") e.Name="CityLifeParticles" e.Texture=C.Smoke e.LightInfluence=V.n1
 e.Transparency=NumberSequence.new(V.n2,V.n1) e.Size=NumberSequence.new(V.n3,V.n4)
 e.Lifetime=NumberRange.new(V.n5,V.n6) e.Speed=NumberRange.new(V.n7,V.n8) e.Rate=C.SmokeRate
 if kind=="Fireflies" then
  e.Texture=C.Spark e.Color=ColorSequence.new(C.Warm) e.LightEmission=V.n9 e.Rate=C.FlyRate
  e.Size=NumberSequence.new(V.n10,V.n0) e.SpreadAngle=Vector2.new(V.n11,V.n11) e.Lifetime=NumberRange.new(V.n4,V.n12)
 elseif kind=="Leaves" then
  e.Texture=C.Spark e.Color=ColorSequence.new(C.Leaf) e.Rate=C.LeafRate e.LightEmission=V.n0
  e.EmissionDirection=Enum.NormalId.Bottom e.Acceleration=Vector3.new(V.n13,-V.n9,V.n14) e.RotSpeed=NumberRange.new(-V.n15,V.n15)
 elseif kind=="Mist" then
  e.Rate=C.MistRate e.Size=NumberSequence.new(V.n12,V.n16) e.Speed=NumberRange.new(V.n14,V.n17) e.Lifetime=NumberRange.new(V.n5,V.n12)
 elseif kind=="Fountain" then
  e.Texture=C.Spark e.Color=ColorSequence.new(C.Water) e.Rate=C.WaterRate e.Speed=NumberRange.new(V.n5,V.n6)
  e.Acceleration=Vector3.new(V.n0,-V.n18,V.n0) e.Size=NumberSequence.new(V.n10,V.n0) e.Lifetime=NumberRange.new(V.n3,V.n9) e.SpreadAngle=Vector2.new(V.n19,V.n19)
 end
 e.Enabled=false e.Parent=obj entry.emitter=e
end
local function remove(obj)
 local entry=entries[obj] if not entry then return end
 if entry.emitter then entry.emitter:Destroy() end
 if obj.Parent and entry.cf then if obj:IsA("Model") then obj:PivotTo(entry.cf) else obj.CFrame=entry.cf end end
 entries[obj]=nil
end
Collection:GetInstanceAddedSignal("CityLife"):Connect(add)
Collection:GetInstanceRemovedSignal("CityLife"):Connect(remove)
for _,obj in Collection:GetTagged("CityLife") do add(obj) end
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt if elapsed<C.Step then return end elapsed=V.n0
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local t=workspace:GetServerTimeNow()
 for obj,entry in entries do
  if not obj.Parent then remove(obj) continue end
  local active=root and not player:GetAttribute("InMatch") and (root.Position-entry.cf.Position).Magnitude<C.Distance
  if entry.emitter then entry.emitter.Enabled=active==true end
  if active and (entry.kind=="Sway" or entry.kind=="Crow") then
   local angle=math.sin(t*C.Speed+entry.cf.Position.X)*C.Sway
   local cf=entry.cf*CFrame.Angles(V.n0,entry.kind=="Crow" and angle*V.n5 or V.n0,angle)
   if obj:IsA("Model") then obj:PivotTo(cf) else obj.CFrame=cf end
  end
 end
end)

-- Distant flights and cloth pennants, strictly client-side.
local Life={Birds=4,Flags=6,Radius=38,Height=24,Speed=0.18,Range=180,Step=0.08,Color=Color3.fromRGB(36,38,45),Cloth=Color3.fromRGB(91,61,71)}
local localFolder=Instance.new("Folder") localFolder.Name="CityLifeLocal" localFolder.Parent=workspace
local birds,flags={},{}
local lifeTime=0
local cityOrigin
local function localPart(name,size,color)
 local p=Instance.new("Part") p.Name=name p.Size=size p.Color=color p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Transparency=1 p.Parent=localFolder return p
end
for i=1,Life.Birds do
 local body=localPart("FlyingCrow",Vector3.new(0.4,0.4,1),Life.Color)
 local left=localPart("LeftWing",Vector3.new(1.3,0.12,0.5),Life.Color)
 local right=localPart("RightWing",Vector3.new(1.3,0.12,0.5),Life.Color)
 birds[i]={body,left,right}
end
for i=1,Life.Flags do flags[i]=localPart("StreetPennant",Vector3.new(0.05,1.5,1.1),Life.Cloth) end
RunService.Heartbeat:Connect(function(dt)
 lifeTime+=dt if lifeTime<Life.Step then return end lifeTime=0
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local city=workspace:FindFirstChild("CityDressing",true)
 if city and not cityOrigin then
  local source=city:FindFirstChild("Fountain")
  if source and source:IsA("BasePart") then cityOrigin=source.Position-Vector3.new(20,2,-16) end
 end
 local active=root and city and cityOrigin and not player:GetAttribute("InMatch") and (root.Position-cityOrigin).Magnitude<Life.Range
 local t=workspace:GetServerTimeNow()
 for i,parts in birds do
  for _,p in parts do p.Transparency=active and 0 or 1 end
  if active then
   local a=t*Life.Speed+i*math.pi/2
   local pos=cityOrigin+Vector3.new(math.cos(a)*Life.Radius,Life.Height+i,math.sin(a)*Life.Radius)
   local cf=CFrame.lookAt(pos,pos+Vector3.new(-math.sin(a),0,math.cos(a)))
   parts[1].CFrame=cf
   parts[2].CFrame=cf*CFrame.new(-0.8,0,0)*CFrame.Angles(0,0,math.sin(t*7)*0.5)
   parts[3].CFrame=cf*CFrame.new(0.8,0,0)*CFrame.Angles(0,0,-math.sin(t*7)*0.5)
  end
 end
 for i,p in flags do
  p.Transparency=active and 0 or 1
  if active then p.CFrame=CFrame.new(cityOrigin+Vector3.new(-34,6,-28+i*2))*CFrame.Angles(math.sin(t*2+i)*0.12,0,0) end
 end
end)
