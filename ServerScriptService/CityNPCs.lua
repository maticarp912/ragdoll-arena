-- Cosmetic R15 townspeople. No Combatant tag, combat scripts or player identity.
local Players=game:GetService("Players")
local Physics=game:GetService("PhysicsService")
local RunService=game:GetService("RunService")
local C={Health=100000,Count=5,Speed=5,Pause=3,TravelTimeout=18,SpawnHeight=4,Step=0.15,Arrival=3,
 Group="CityVillagers",PlayerGroup="CityVisitorBodies",Skin=Color3.fromRGB(173,147,123),
 Clothes={Color3.fromRGB(67,72,61),Color3.fromRGB(69,56,75),Color3.fromRGB(87,63,45)},
 Route={Vector3.new(-32,0,-18),Vector3.new(-30,0,-24),Vector3.new(-15,0,-35),Vector3.new(-14,0,-57),Vector3.new(16,0,-57),Vector3.new(20,0,-23),Vector3.new(8,0,-20)},
 CapeSize=Vector3.new(1.8,2.3,0.2),ApronSize=Vector3.new(1.4,1.8,0.12),HoodSize=Vector3.new(1.3,1.3,1.2),
}
local Service={}
local started=setmetatable({},{__mode="k"})
local collisionReady=false
local function collisions()
 if collisionReady then return end collisionReady=true
 for _,name in {C.Group,C.PlayerGroup} do pcall(Physics.RegisterCollisionGroup,Physics,name) end
 Physics:CollisionGroupSetCollidable(C.Group,C.Group,false)
 Physics:CollisionGroupSetCollidable(C.Group,C.PlayerGroup,false)
 local function character(char)
  local function part(obj)
   if obj:IsA("BasePart") then
    if obj.CollisionGroup=="Default" then obj.CollisionGroup=C.PlayerGroup
    else Physics:CollisionGroupSetCollidable(C.Group,obj.CollisionGroup,false) end
   end
  end
  for _,obj in char:GetDescendants() do part(obj) end
  char.DescendantAdded:Connect(part)
 end
 local function player(p) p.CharacterAdded:Connect(character) if p.Character then character(p.Character) end end
 Players.PlayerAdded:Connect(player) for _,p in Players:GetPlayers() do player(p) end
end
function Service.start(cityFolder,ctx)
 if started[cityFolder] then return end started[cityFolder]=true collisions()
 local folder=Instance.new("Folder") folder.Name="CityVillagers" folder.Parent=cityFolder
 local origin=ctx.origin+Vector3.yAxis*(ctx.floorTop or 0)
 for index=1,C.Count do task.spawn(function()
  local desc=Instance.new("HumanoidDescription")
  desc.HeadColor=C.Skin desc.LeftArmColor=C.Skin desc.RightArmColor=C.Skin
  local color=C.Clothes[(index-1)%#C.Clothes+1]
  desc.TorsoColor=color desc.LeftLegColor=color desc.RightLegColor=color
  local ok,char=pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(desc,Enum.HumanoidRigType.R15) end)
  desc:Destroy()
  if not ok then warn("[CityNPCs] R15 creation failed",char) return end
  if not cityFolder.Parent then char:Destroy() return end
  char.Name="CityVillager_"..index char:SetAttribute("CityVillager",true)
  local hum=char:FindFirstChildOfClass("Humanoid") local root=char:FindFirstChild("HumanoidRootPart")
  if not hum or not root then char:Destroy() return end
  hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None hum.WalkSpeed=C.Speed hum.BreakJointsOnDeath=false
  hum.MaxHealth=C.Health hum.Health=C.Health
  for _,obj in char:GetDescendants() do if obj:IsA("BasePart") then obj.CollisionGroup=C.Group end end
  local function clothing(name,size,part,offset)
   if not part then return end
   local obj=Instance.new("Part") obj.Name=name obj.Size=size obj.Color=color obj.Material=Enum.Material.Fabric obj.CanCollide=false obj.CanQuery=false obj.CanTouch=false obj.Massless=true obj.CollisionGroup=C.Group
   obj.CFrame=part.CFrame*offset obj.Parent=char
   local weld=Instance.new("WeldConstraint") weld.Part0=part weld.Part1=obj weld.Parent=obj
  end
  clothing("Cape",C.CapeSize,char:FindFirstChild("UpperTorso"),CFrame.new(0,-0.4,0.6))
  if index%2==0 then clothing("Apron",C.ApronSize,char:FindFirstChild("LowerTorso"),CFrame.new(0,0,-0.55))
  else clothing("Hood",C.HoodSize,char:FindFirstChild("Head"),CFrame.new(0,0.15,0.15)) end
  char.Parent=folder char:PivotTo(CFrame.new(origin+C.Route[index]+Vector3.yAxis*C.SpawnHeight))
  pcall(function() root:SetNetworkOwner(nil) end)
  -- 11/11/2026 (rendimiento): brazos y piernas los anima cada cliente (StarterPlayerScripts/Performance).
  -- Antes se movían acá 60 veces por segundo y cada cambio viajaba por la red a todos los jugadores.
  game:GetService("CollectionService"):AddTag(char,"CityWalker")
  local animation={Disconnect=function() end}
  local waypoint=index
  while folder.Parent and char.Parent and hum.Health>0 do
   waypoint=waypoint%#C.Route+1
   local goal=origin+C.Route[waypoint]+Vector3.yAxis*C.SpawnHeight
   hum:MoveTo(goal)
   local deadline=os.clock()+C.TravelTimeout
   while char.Parent and folder.Parent and os.clock()<deadline and (Vector3.new(root.Position.X,goal.Y,root.Position.Z)-goal).Magnitude>C.Arrival do task.wait(C.Step) end
   if char.Parent then hum:MoveTo(root.Position) end
   task.wait(C.Pause+index*C.Step)
  end
  animation:Disconnect() char:Destroy()
 end) end
 return folder
end
return Service
