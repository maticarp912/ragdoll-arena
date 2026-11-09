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

function Remotes.get(name: string, className: string?)
	local r = folder:FindFirstChild(name)
	if not r then
		r = Instance.new(className or "RemoteEvent")
		r.Name = name
		r.Parent = folder
	end
	return r
end

return Remotes
