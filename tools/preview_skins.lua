-- Vista rápida de TODAS las armas y skins en Studio (sin darle a Jugar).
-- Uso: en Studio, Ver → Barra de comandos, pega todo este archivo y pulsa Enter.
-- Crea la carpeta workspace.SkinPreview delante de la cámara: una fila por arma, la base primero.
-- Para borrarla: workspace.SkinPreview:Destroy()

local RS = game:GetService("ReplicatedStorage")
local WB = require(RS.WeaponBuilder)
local Skins = require(RS.Skins)
local WeaponData = require(RS.WeaponData)

local old = workspace:FindFirstChild("SkinPreview")
if old then old:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "SkinPreview"
folder.Parent = workspace

local cam = workspace.CurrentCamera
local origin = cam.CFrame * CFrame.new(-14, -4, -26)
local flat = CFrame.new(origin.Position) * CFrame.Angles(0, select(2, cam.CFrame:ToEulerAnglesYXZ()), 0)

local function place(weaponId, skinId, col, row)
	local m = WB.buildModel(weaponId, skinId)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored = true end
		if p:IsA("ParticleEmitter") then p.Enabled = true end
	end
	m:PivotTo(flat * CFrame.new(col * 3, -row * 8, 0) * CFrame.Angles(-math.pi / 2, 0, 0))
	m.Name = weaponId .. "_" .. skinId
	m.Parent = folder
	local count = 0
	for _, p in m:GetDescendants() do if p:IsA("BasePart") then count += 1 end end
	local handle = m.PrimaryPart
	local tipAtt = handle and handle:FindFirstChild("BladeTip")
	local tipZ = tipAtt and tipAtt.Position.Z or 0
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(150, 42)
	tag.StudsOffsetWorldSpace = Vector3.new(0, -2.4, 0)
	tag.AlwaysOnTop = true
	tag.Adornee = m.PrimaryPart
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.TextScaled = true
	t.Text = ("%s\n%d pzs | Z=%.2f"):format(skinId, count, tipZ)
	t.Parent = tag
	tag.Parent = m
	print(("[SkinPreview] %-10s | %-10s | %2d piezas | BladeTip.Z = %.2f"):format(weaponId, skinId, count, tipZ))
end

for row, weaponId in WeaponData.Order do
	place(weaponId, "Default", 0, row - 1)
	local col = 1
	for _, id in Skins.Order do
		local s = Skins.Data[id]
		if s.weapon == weaponId and not s.comingSoon then
			place(weaponId, id, col, row - 1)
			col += 1
		end
	end
end
print("SkinPreview listo: mira la Salida por avisos de [WeaponBuilder]")
