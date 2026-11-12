-- Generado por tools/mocap_to_lua.js. No editar a mano.
-- Conserva las claves de los clips para los consumidores de MocapClips.
local clips = {}
for _, group in {
	require(script.Parent:WaitForChild("MocapClipsGreatsword")),
	require(script.Parent:WaitForChild("MocapClipsMace")),
	require(script.Parent:WaitForChild("MocapClipsSword")),
	require(script.Parent:WaitForChild("MocapClipsShared")),
} do
	for name, clip in group do
		clips[name] = clip
	end
end
return clips
