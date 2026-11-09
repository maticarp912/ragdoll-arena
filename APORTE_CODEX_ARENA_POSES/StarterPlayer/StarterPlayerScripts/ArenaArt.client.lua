-- Montaña fragmentada: cada roca acompaña una baldosa, incluso durante su caída.
-- Todas las piezas son visuales, ancladas y sin colisión/consulta/contacto.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(RS:WaitForChild("ArenaArtConfig"))
if not Config.Enabled then return end

local folder = Instance.new("Folder")
folder.Name = "ArenaArtLocal"
folder.Parent = workspace
local entries = {}
local watching = {}
local pending = {}

local function isArena(obj)
	return obj:IsA("Folder") and (obj.Name == "Arena_1v1" or obj.Name == "Arena_2v2")
end

local function addTile(tile, center, radius)
	if entries[tile] or not tile:IsA("BasePart") or tile.Name ~= "Tile" then return end
	local delta = tile.Position - center
	local edge = math.clamp(math.max(math.abs(delta.X), math.abs(delta.Z)) / math.max(radius, 1), 0, 1)
	local depth = Config.MinimumDepth + (1 - edge) * Config.PeakDepth
	local seed = math.floor(tile.Position.X * 31 + tile.Position.Z * 17)
	local rng = Random.new(seed)
	local shade = rng:NextInteger(-Config.RockVariation, Config.RockVariation)
	local rock = Instance.new("WedgePart")
	rock.Name = "MountainFragment"
	rock.Size = Vector3.new(tile.Size.X - Config.RockInset, depth, tile.Size.Z - Config.RockInset)
	rock.Material = Enum.Material.Slate
	local c = Config.RockColor
	rock.Color = Color3.new(math.clamp(c.R + shade / 255, 0, 1), math.clamp(c.G + shade / 255, 0, 1), math.clamp(c.B + shade / 255, 0, 1))
	rock.Anchored = true
	rock.CanCollide = false
	rock.CanTouch = false
	rock.CanQuery = false
	local offset = CFrame.new(0, -tile.Size.Y / 2 - depth / 2, 0) * CFrame.Angles(0, rng:NextInteger(0, 3) * math.pi / 2, 0)
	rock.CFrame = tile.CFrame * offset
	rock.Parent = folder
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, depth / 2, 0)
	attachment.Parent = rock
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Config.DustColor)
	dust.Lifetime = Config.DustLifetime
	dust.Speed = NumberRange.new(3, 7)
	dust.SpreadAngle = Vector2.new(80, 80)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 5) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(1, 1) })
	dust.Rate = 0
	dust.Parent = attachment
	entries[tile] = { rock = rock, offset = offset, dust = dust, falling = not tile.Anchored }
end

local function scanArena(arena)
	pending[arena] = nil
	if not arena:IsDescendantOf(workspace) then return end
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	local tiles = {}
	for _, tile in arena:GetChildren() do
		if tile:IsA("BasePart") and tile.Name == "Tile" and tile.Anchored then
			table.insert(tiles, tile)
			minX, maxX = math.min(minX, tile.Position.X), math.max(maxX, tile.Position.X)
			minZ, maxZ = math.min(minZ, tile.Position.Z), math.max(maxZ, tile.Position.Z)
		end
	end
	if #tiles == 0 then return end
	local center = Vector3.new((minX + maxX) / 2, 0, (minZ + maxZ) / 2)
	local radius = math.max(maxX - minX, maxZ - minZ) / 2
	for _, tile in tiles do addTile(tile, center, radius) end
end

local function schedule(arena)
	if pending[arena] then return end
	pending[arena] = true
	task.defer(scanArena, arena)
end
local function watch(arena)
	if watching[arena] or not isArena(arena) then return end
	watching[arena] = arena.ChildAdded:Connect(function() schedule(arena) end)
	schedule(arena)
end
workspace.DescendantAdded:Connect(watch)
for _, obj in workspace:GetDescendants() do watch(obj) end

local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < Config.UpdateInterval then return end
	elapsed = 0
	local camera = workspace.CurrentCamera
	for tile, entry in entries do
		if not tile:IsDescendantOf(workspace) then
			entry.rock:Destroy()
			entries[tile] = nil
		else
			local visible = camera and (camera.CFrame.Position - tile.Position).Magnitude < Config.MaxDistance
			entry.rock.LocalTransparencyModifier = visible and 0 or 1
			if visible then
				entry.rock.CFrame = tile.CFrame * entry.offset
				if not tile.Anchored and not entry.falling then entry.dust:Emit(Config.DustCount) end
			end
			entry.falling = not tile.Anchored
		end
	end
	for arena, connection in watching do
		if not arena:IsDescendantOf(workspace) then connection:Disconnect() watching[arena] = nil end
	end
end)
