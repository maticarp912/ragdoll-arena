-- ModuleScript: ReplicatedStorage/WeaponMeshes
-- Catálogo opcional de mallas importadas desde Blender (tools/blender/ -> modelos_armas/).
-- Mientras MeshId == 0 (valor por defecto), WeaponBuilder construye el modelo por piezas procedural.
-- Al subir un .fbx / .obj en Roblox Studio (Asset Manager -> Meshes), pegá el número de rbxassetid
-- en MeshId (y opcionalmente TextureId). WeaponBuilder lo usará automáticamente conservando
-- Handle, BladeBase, BladeTip y OffhandGrip.

local WeaponMeshes = {
	-- Armas base
	Dagger = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 2.87 },
	Sword = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	Greatsword = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 7.60 },
	Rapier = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.56 },
	Mace = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.90 },

	-- Skins de Daga
	Fangs = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 2.86 },
	LivingThorns = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 2.88 },
	VoidMoons = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 2.88 },
	SilverCrescent = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 2.88 },
	EclipseClaws = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 2.89 },

	-- Skins de Espada
	RequiemHorns = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.14 },
	Solar = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	Ossuary = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	DawnCrown = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	DragonEdge = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	Violet = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	Void = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	ExileTooth = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
	DraconicRelic = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.12 },

	-- Skins de Espadón
	EmeraldTomb = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 7.60 },
	Devourer = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 7.60 },
	RoyalMourning = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 7.60 },
	DuskCross = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 7.60 },
	Shroud = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 7.58 },
	AbyssWings = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 7.60 },

	-- Skins de Estoque
	Duel = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.56 },
	SilverCut = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.56 },
	FireTongue = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.58 },
	TwilightDuel = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.58 },
	SpectralSting = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.58 },
	AmethystVeil = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.58 },
	DarkLament = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.58 },

	-- Skins de Maza
	Flange = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.90 },
	CrimsonShards = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.86 },
	NorthExecutioner = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.88 },
	Forge = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.88 },
	AncientMaw = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.85 },
	OssuaryAxe = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.86 },
	AbyssVertebra = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.90 },
	SepulcherJaws = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.88 },
	OssuaryCrown = { MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 4.90 },
}

function WeaponMeshes.get(designOrWeapon)
	local entry = WeaponMeshes[designOrWeapon]
	if entry and type(entry.MeshId) == "number" and entry.MeshId > 0 then
		return entry
	end
	return nil
end

return WeaponMeshes
