-- ModuleScript: ServerScriptService/Remotes
-- Crea (una sola vez) los RemoteEvents/RemoteFunctions en ReplicatedStorage/Remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local Remotes = {}
local classes = { Admin = "RemoteFunction", Shop = "RemoteFunction", Settings = "RemoteFunction", Missions = "RemoteFunction", Rewards = "RemoteFunction", Monetization = "RemoteFunction", RewardsChanged = "RemoteEvent", RewardAnnouncement = "RemoteEvent" }

function Remotes.get(name: string, className: string?)
	className = className or classes[name] or "RemoteEvent"
 local r = folder:FindFirstChild(name)
 if r then assert(r:IsA(className), "Remote type mismatch: " .. name) end
	if not r then
		r = Instance.new(className or "RemoteEvent")
		r.Name = name
		r.Parent = folder
	end
	return r
end

return Remotes
