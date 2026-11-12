-- Exclusive city dressing. Coordinates are relative to ctx.origin; floorTop is local Y.
local Collection = game:GetService("CollectionService")
local P = { ReplacesBlock = { [4] = true } }
local D = {
 Budget=1400, Lights=12, Seed=813, Half=0.5, Two=2, Zero=0, One=1,
 Stone=Color3.fromRGB(91,96,95), Wood=Color3.fromRGB(64,43,34), Trim=Color3.fromRGB(114,79,49), Roof=Color3.fromRGB(43,45,61), Moss=Color3.fromRGB(48,72,57), Gold=Color3.fromRGB(220,176,96), Iron=Color3.fromRGB(30,33,37), Water=Color3.fromRGB(65,116,126),
 Potions={Color3.fromRGB(96,172,152),Color3.fromRGB(165,107,184),Color3.fromRGB(211,128,75)},
 Tavern=Vector3.new(-48,0,-16), Width=20, Depth=24, Height=15, Wall=0.6, Beam=0.7, RoofRise=5, RoofTilt=math.rad(27),
 ShelfRows=3, Bottles=7, BottleSize=Vector3.new(0.7,1.2,0.7), NeckSize=Vector3.new(0.3,0.5,0.3), ShelfStep=3,
 BoardPositions={Vector3.new(-24,0,-26),Vector3.new(24,0,-26),Vector3.new(-24,0,-54),Vector3.new(24,0,-54)}, Boards={"Wins","Kills","Knockdowns","Coins"}, BoardSize=Vector3.new(10,7,0.5), BoardHeight=6, Angel=Vector3.new(0,0,-40),
 RuneCount=24, RuneRadius=6, RuneWidth=0.09, RuneLength=0.7, RuneLift=0.13,
 TreeSides={-1,1}, TreeX=10, TreeSegments=5, TreeRise=2.5, TreeLean=0.6,
 Mushrooms={Vector3.new(-31,0,-31),Vector3.new(31,0,-31),Vector3.new(-31,0,-48),Vector3.new(31,0,-48),Vector3.new(-10,0,-105),Vector3.new(10,0,-105)}, ClusterCount=4,
 Lamps={Vector3.new(-10,7,-90),Vector3.new(10,7,-90)}, -- 12/11/2026: sacados los 3 que colgaban en el aire (-34,-24 / 31,-40 / -31,-40)
 LampSize=Vector3.new(0.8,1.4,0.8), LightRange=12, Brightness=0.8,
 Paths={{Vector3.new(-32,0,-18),Vector3.new(-35,0,-18)},{Vector3.new(35,0,-40),Vector3.new(59,0,-40)},{Vector3.new(0,0,-72),Vector3.new(0,0,-91)}}, StoneStep=3, PathLanes={-1,1}, LaneWidth=2, StoneSize=Vector3.new(2.2,0.12,2.4), StoneLift=0.14,
 Fountain=Vector3.new(20,0,-16), FountainRadius=3, FountainSegments=16,
 BarrelPositions={Vector3.new(-34,0,-8),Vector3.new(-34,0,-27)}, StoolPositions={Vector3.new(-33,0,-13),Vector3.new(-33,0,-19)},
}
P.Config=D
local V={n0=0,n1=4,n2=9,n3=14,n4=8,n5=12,n6=20,n7=3,n8=18,n9=1.5,n10=1,n11=0.35,n12=7,n13=0.8,n14=2.5,n15=0.7,n16=5,n17=10,n18=0.05,n19=0.3,n20=2.8,n21=480,n22=240,n23=13,n24=0.2,n25=2.2,n26=0.4,n27=2.6,n28=2.3,n29=1.8,n30=0.5,n31=0.9,n32=33,n33=2.7,n34=23,n35=0.6,n36=1.35,n37=2,n38=3.5,n39=1.3,n40=0.16,n41=0.18,n42=0.12,n43=5.6,n44=4.2,n45=0.15,n46=0.65,n47=1.4,n48=1.1,n49=0.08,n50=0.1,n51=5.4,n52=20.7}
local Roads={MainStart=-120,MainEnd=146,Step=3.4,Lanes={-2.5,0,2.5},Size=Vector3.new(2.15,0.10,2.5),Lift=0.12,MainFloor=0.05,CrossFloor=0.11,PlazaMin=-70,PlazaMax=-10,CrossZ=-40,CrossStart=-98,CrossEnd=59,PlazaRadius=13,ArcCount=28,Grass=Color3.fromRGB(53,76,54),Flower=Color3.fromRGB(154,109,166),Beds={Vector3.new(-10,0,-82),Vector3.new(10,0,-82),Vector3.new(-31,0,-13),Vector3.new(31,0,-67)}}
function P.build(parent,ctx)
 local previous=parent:FindFirstChild("CityDressing") if previous then previous:Destroy() end
 local folder=Instance.new("Folder") folder.Name="CityDressing" folder.Parent=parent
 local origin=ctx.origin+Vector3.yAxis*ctx.floorTop
 local count,lights=D.Zero,D.Zero
 local rng=Random.new(D.Seed)
 local function part(name,size,cf,color,material,solid,container)
  count+=D.One assert(count<=D.Budget,"CityProps part budget exceeded")
  local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=CFrame.new(origin)*cf p.Color=color p.Material=material or Enum.Material.Slate
  p.Anchored=true p.CanCollide=solid==true p.CanQuery=solid==true p.CanTouch=false p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=container or folder return p
 end
 local function box(name,size,pos,color,mat,solid,container) return part(name,size,CFrame.new(pos),color,mat,solid,container) end
 local function model(name) local m=Instance.new("Model") m.Name=name m.Parent=folder return m end
 local function life(obj,kind) obj:SetAttribute("CityLifeKind",kind) Collection:AddTag(obj,"CityLife") end
 local function source(kind,pos) local p=box(kind,Vector3.one,CFrame.new(pos).Position,D.Stone) p.Transparency=D.One life(p,kind) return p end
 local function light(p)
  lights+=D.One assert(lights<=D.Lights,"CityProps light budget exceeded")
  local l=Instance.new("PointLight") l.Color=D.Gold l.Range=D.LightRange l.Brightness=D.Brightness l.Shadows=false l.Parent=p
 end
 local function rod(name,a,b,width,color,container)
  return part(name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/D.Two,b),color,Enum.Material.Wood,false,container)
 end
 local function cylinder(name,size,pos,color,mat)
  local p=part(name,size,CFrame.new(pos)*CFrame.Angles(V.n0,V.n0,math.pi/D.Two),color,mat) p.Shape=Enum.PartType.Cylinder return p
 end
 -- Alchemist tavern: an open eastern bay, shelves visible from the plaza.
 local c=D.Tavern
 box("TavernBack",Vector3.new(D.Wall,D.Height,D.Depth),c+Vector3.new(-D.Width/D.Two,D.Height/D.Two,V.n0),D.Stone,nil,true)
 for _,sign in D.TreeSides do
  box("TavernSide",Vector3.new(D.Width,D.Height,D.Wall),c+Vector3.new(V.n0,D.Height/D.Two,sign*D.Depth/D.Two),D.Wood,Enum.Material.WoodPlanks,true)
  for _,x in D.TreeSides do box("TimberPost",Vector3.new(D.Beam,D.Height,D.Beam),c+Vector3.new(x*D.Width/D.Two,D.Height/D.Two,sign*D.Depth/D.Two),D.Trim,Enum.Material.Wood) end
  part("PitchedRoof",Vector3.new(D.Width+D.Two,D.Beam,D.Depth/D.Two+D.Two),CFrame.new(c+Vector3.new(V.n0,D.Height+D.RoofRise/D.Two,sign*D.Depth/V.n1))*CFrame.Angles(sign*D.RoofTilt,V.n0,V.n0),D.Roof,Enum.Material.Slate) -- 12/11/2026: el signo estaba invertido (techo en V)
  rod("DiagonalBrace",c+Vector3.new(D.Width/D.Two,V.n2,sign*D.Depth/D.Two),c+Vector3.new(D.Width/D.Two,V.n3,sign*V.n4),D.Beam,D.Trim)
 end
 rod("RoofRidge",c+Vector3.new(-V.n5,V.n6,V.n0),c+Vector3.new(V.n5,V.n6,V.n0),D.Beam,D.Trim)
 box("Counter",Vector3.new(V.n7,V.n7,V.n8),c+Vector3.new(V.n4,V.n9,V.n0),D.Wood,Enum.Material.WoodPlanks,true)
 for row=V.n10,D.ShelfRows do
  box("PotionShelf",Vector3.new(V.n7,V.n11,V.n6),c+Vector3.new(-V.n12,row*D.ShelfStep,V.n0),D.Trim,Enum.Material.Wood)
  for i=V.n10,D.Bottles do
   local pos=c+Vector3.new(-V.n12,row*D.ShelfStep+V.n13,(i-V.n1)*V.n14)
   local col=D.Potions[(i+row)%#D.Potions+V.n10]
   local bottle=box("Potion",D.BottleSize,pos,col,Enum.Material.Neon) bottle.Shape=Enum.PartType.Ball
   box("BottleNeck",D.NeckSize,pos+Vector3.yAxis*V.n15,col,Enum.Material.Glass)
  end
 end
 for i=V.n10,D.ShelfRows do
  local pos=c+Vector3.new(V.n4,V.n2,i*V.n16-V.n17)
  rod("BottleCord",pos,pos+Vector3.yAxis*V.n7,V.n18,D.Iron)
  local bottle=box("HangingPotion",D.BottleSize,pos,D.Potions[i],Enum.Material.Neon) bottle.Shape=Enum.PartType.Ball life(bottle,"Sway")
 end
 local sign=box("TavernSign",Vector3.new(V.n19,V.n20,V.n16),c+Vector3.new(V.n5,V.n17,V.n12),D.Wood,Enum.Material.Wood)
 local sg=Instance.new("SurfaceGui") sg.Face=Enum.NormalId.Right sg.CanvasSize=Vector2.new(V.n21,V.n22) sg.Parent=sign
 local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(V.n10,V.n10) label.BackgroundTransparency=V.n10 label.Font=Enum.Font.Garamond label.TextScaled=true label.TextColor3=D.Gold label.Text="The Ashen Flask" label:SetAttribute("LocKey","cx.city.tavern") label.Parent=sg life(sign,"Sway")
 rod("SignBracket",c+Vector3.new(V.n2,V.n5,V.n12),c+Vector3.new(V.n23,V.n5,V.n12),V.n24,D.Iron)
 for _,pos in D.BarrelPositions do
  cylinder("Barrel",Vector3.new(V.n7,V.n25,V.n25),pos+Vector3.yAxis*V.n9,D.Wood,Enum.Material.WoodPlanks)
  for _,y in {V.n26,V.n27} do cylinder("BarrelHoop",Vector3.new(V.n24,V.n28,V.n28),pos+Vector3.yAxis*y,D.Iron,Enum.Material.Metal) end
 end
 for _,pos in D.StoolPositions do cylinder("Stool",Vector3.new(V.n19,V.n29,V.n29),pos+Vector3.yAxis*V.n29,D.Trim) box("StoolLeg",Vector3.new(V.n30,V.n29,V.n30),pos+Vector3.yAxis*V.n31,D.Wood) end
 cylinder("OutdoorTable",Vector3.new(V.n19,V.n7,V.n7),Vector3.new(-V.n32,V.n33,-V.n34),D.Trim) box("TableLeg",Vector3.new(V.n35,V.n33,V.n35),Vector3.new(-V.n32,V.n36,-V.n34),D.Wood)
 local chimney=box("Chimney",Vector3.new(V.n37,V.n12,V.n37),c+Vector3.new(-V.n16,V.n6,-V.n12),D.Stone) source("Smoke",chimney.Position-origin+Vector3.yAxis*V.n38)
 -- Spawn ring is decorative and noncolliding, leaving the middle clear.
 local spawn=Vector3.new(ctx.spawn.X,V.n0,ctx.spawn.Z)
 for i=V.n10,D.RuneCount do
  local angle=i/D.RuneCount*math.pi*V.n37
  local cf=CFrame.new(spawn)*CFrame.Angles(V.n0,angle,V.n0)*CFrame.new(V.n0,D.RuneLift,D.RuneRadius)
  part("RuneStone",Vector3.new(V.n39,V.n40,V.n9),cf,D.Stone)
  for _,signDir in D.TreeSides do part("GoldenRune",Vector3.new(D.RuneWidth,V.n18,D.RuneLength),cf*CFrame.new(signDir*V.n41,V.n42,V.n0)*CFrame.Angles(V.n0,signDir*V.n30,V.n0),D.Gold,Enum.Material.Neon) end
 end
 for _,signDir in D.TreeSides do
  local base=spawn+Vector3.new(signDir*D.TreeX,V.n0,V.n0)
  local tip=base
  for j=V.n10,D.TreeSegments do local nextTip=base+Vector3.new(signDir*math.sin(j)*D.TreeLean,j*D.TreeRise,math.cos(j)*D.TreeLean) rod("TwistedTrunk",tip,nextTip,V.n37-j*V.n24,D.Wood) tip=nextTip end
  for branch=V.n10,V.n7 do
   local endPos=tip+Vector3.new(signDir*branch,branch-V.n37,branch*V.n37)
   rod("CrookedBranch",tip,endPos,V.n30,D.Wood)
   local moss=box("MossCrown",Vector3.new(V.n1,V.n9,V.n7),endPos,D.Moss,Enum.Material.Grass) moss.Shape=Enum.PartType.Ball
  end
  source("Leaves",tip) source("Fireflies",base+Vector3.yAxis*V.n37)
 end
 source("Mist",spawn+Vector3.yAxis*V.n24)
 -- C7: the -Z Front face points towards the angel.
 for i,pos in D.BoardPositions do
  local center=pos+Vector3.yAxis*D.BoardHeight
  local cf=CFrame.lookAt(center,Vector3.new(D.Angel.X,center.Y,D.Angel.Z))
  local board=part("LeaderboardBoard",D.BoardSize,cf,D.Wood,Enum.Material.WoodPlanks)
  board:SetAttribute("Board",D.Boards[i]) Collection:AddTag(board,"LeaderboardBoard")
  for _,signDir in D.TreeSides do part("BoardPillar",Vector3.new(V.n13,V.n17,V.n10),cf*CFrame.new(signDir*V.n43,-V.n10,V.n0),D.Stone) end
  part("BoardCrown",Vector3.new(V.n5,V.n13,V.n39),cf*CFrame.new(V.n0,V.n44,V.n0),D.Trim)
 end
 for _,pos in D.Mushrooms do
  for j=V.n10,D.ClusterCount do
   local p=pos+Vector3.new(rng:NextNumber(-V.n10,V.n10),V.n0,rng:NextNumber(-V.n10,V.n10))
   box("MushroomStem",Vector3.new(V.n45,V.n35,V.n45),p+Vector3.yAxis*V.n19,D.Trim)
   local cap=box("MushroomCap",Vector3.new(V.n31,V.n19,V.n31),p+Vector3.yAxis*V.n46,D.Potions[j%#D.Potions+V.n10],Enum.Material.Neon) cap.Shape=Enum.PartType.Ball
  end
  local bush=box("IvyBush",Vector3.new(V.n37,V.n47,V.n37),pos+Vector3.yAxis*V.n30,D.Moss,Enum.Material.Grass) bush.Shape=Enum.PartType.Ball
 end
 for _,pos in D.Lamps do
  local m=model("HangingLantern")
  local lamp=box("LanternGlass",D.LampSize,pos,D.Gold,Enum.Material.Neon,false,m) light(lamp)
  box("LanternRoof",Vector3.new(V.n48,V.n24,V.n48),pos+Vector3.yAxis*V.n13,D.Iron,nil,false,m)
  rod("LanternCord",pos+Vector3.yAxis, pos+Vector3.yAxis*V.n7,V.n49,D.Iron,m)
  m.PrimaryPart=lamp life(m,"Sway")
 end
 for _,path in {} do
  local a,b=path[V.n10],path[V.n37] local steps=math.max(V.n10,math.floor((b-a).Magnitude/D.StoneStep))
  for j=V.n0,steps do for _,lane in D.PathLanes do
   local pos=a:Lerp(b,j/steps)+(b-a).Unit:Cross(Vector3.yAxis)*(lane*D.LaneWidth)+Vector3.yAxis*D.StoneLift
   part("PathStone",D.StoneSize,CFrame.new(pos)*CFrame.Angles(V.n0,rng:NextNumber(-V.n19,V.n19),V.n0),D.Stone)
  end end
 end
 local f=D.Fountain
 for i=V.n10,D.FountainSegments do local a=i/D.FountainSegments*math.pi*V.n37 part("FountainRim",Vector3.new(V.n48,V.n10,V.n35),CFrame.new(f)*CFrame.Angles(V.n0,a,V.n0)*CFrame.new(V.n0,V.n30,D.FountainRadius),D.Stone) end
 cylinder("FountainWater",Vector3.new(V.n50,V.n51,V.n51),f+Vector3.yAxis*V.n26,D.Water,Enum.Material.Glass)
 source("Fountain",f+Vector3.yAxis*V.n37)
 local crow=box("PerchedCrow",Vector3.new(V.n35,V.n13,V.n48),c+Vector3.new(V.n37,V.n52,V.n0),D.Iron) crow.Shape=Enum.PartType.Ball life(crow,"Crow")

 -- Irregular paving above the actual road layers, with an eight-stud clear corridor.
 local function paving(pos,y,turn)
  part("RoadPaving",Roads.Size,CFrame.new(pos.X,y-ctx.floorTop+Roads.Lift,pos.Z)*CFrame.Angles(0,turn,0),D.Stone)
 end
 for z=Roads.MainStart,Roads.MainEnd,Roads.Step do
  if z<Roads.PlazaMin or z>Roads.PlazaMax then
   local curve=math.sin(z/25)*1.2
   for _,lane in Roads.Lanes do paving(Vector3.new(lane+curve,0,z),Roads.MainFloor,rng:NextNumber(-0.18,0.18)) end
  end
 end
 for x=Roads.CrossStart,Roads.CrossEnd,Roads.Step do
  if x < -36 or x > 36 then for _,lane in Roads.Lanes do paving(Vector3.new(x,0,Roads.CrossZ+lane+math.sin(x/20)),Roads.CrossFloor,math.pi/2+rng:NextNumber(-0.15,0.15)) end end
 end
 for i=1,Roads.ArcCount do
  local angle=i/Roads.ArcCount*math.pi*2
  for _,lane in {-1.5,1.5} do paving(Vector3.new(math.cos(angle)*(Roads.PlazaRadius+lane),0,-40+math.sin(angle)*(Roads.PlazaRadius+lane)),ctx.floorTop,-angle) end
 end
 -- North/south approach through plaza; leave the angel's footprint clear.
 for _,sign in {-1,1} do for j=0,4 do for _,lane in Roads.Lanes do paving(Vector3.new(lane,0,-40+sign*(17+j*3.4)),ctx.floorTop,0) end end end
 for z=Roads.MainStart,Roads.MainEnd,12 do
  if (z < -106 or z > -90) and (z < Roads.PlazaMin or z > Roads.PlazaMax) then
   for _,side in {-1,1} do
    local grass=box("RoadsideGrass",Vector3.new(1.3,0.35,2.7),Vector3.new(side*9,Roads.MainFloor-ctx.floorTop+0.2,z),Roads.Grass,Enum.Material.Grass)
    grass.Shape=Enum.PartType.Ball
   end
  end
 end
 for _,pos in Roads.Beds do
  box("FlowerBed",Vector3.new(2.5,0.25,4),pos+Vector3.yAxis*0.2,Roads.Grass,Enum.Material.Grass)
  for j=1,5 do
   local stem=pos+Vector3.new(rng:NextNumber(-0.8,0.8),0.6,rng:NextNumber(-1.5,1.5))
   box("FlowerStem",Vector3.new(0.08,0.6,0.08),stem,D.Moss)
   local blossom=box("Blossom",Vector3.new(0.4,0.22,0.4),stem+Vector3.yAxis*0.35,Roads.Flower) blossom.Shape=Enum.PartType.Ball
  end
 end
 folder:SetAttribute("PartCount",count) folder:SetAttribute("LightCount",lights)
 return folder
end
return P
