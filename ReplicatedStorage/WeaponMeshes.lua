-- ModuleScript: ReplicatedStorage/WeaponMeshes
-- Catálogo de mallas 3D (.fbx / .obj) y texturas 1024x1024 (_tex.png) generadas con Blender
-- mediante `tools/blender/generate_weapons.py` y exportadas en `modelos_armas/`.
--
-- Cómo activar las mallas en Roblox Studio (Importador 3D):
--   1) Abrí Asset Manager -> Bulk Import (o Avatar -> Import 3D) y seleccioná los archivos `.fbx`
--      (que ya llevan incrustada la textura `<Nombre>_tex.png` de 1024x1024) desde `modelos_armas/`.
--   2) Desmarcá "Rescale if too large" para respetar la escala 1:1 en studs y el origen (0,0,0) en el mango.
--   3) Copiá el Asset ID numérico de la malla (`MeshId`) y de su textura (`TextureId`) y pegalos abajo.
--   4) Mientras `MeshId = 0`, `WeaponBuilder` usa automáticamente el modelo procedural de alta definición
--      de `SkinDesigns.lua` / `WeaponBuilder.lua` sin errores ni dependencias externas.

local WeaponMeshes = {
	-- 0.3: Corte de Plata. Activar después de importar y verificar el agarre en Studio.
	SilverCut = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.identity,
		BladeBase = Vector3.new(0, 0, 0.68), BladeTip = Vector3.new(0, 0.42, 5.30), TipZ = 5.30,
		SourceFile = "modelos_armas/v0.3/SilverCut.fbx", TextureFile = "modelos_armas/v0.3/SilverCut_tex.png",
	},
	----------------------------------------------------------------------
	-- TANDA 1 DE BLENDER (0.2 D6 / D15): 3 SKINS DE LA RULETA + 5 PILOTOS
	----------------------------------------------------------------------

	-- 1. Tres skins de la Ruleta (D15)
	-- Gran premio semanal: Filo del Eclipse Carmesí (Notas/Referencias/espada-concepto.png)
	CrimsonEclipse = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 0.85),
		BladeTip = Vector3.new(0, 0, 5.10),
		TipZ = 5.10,
		SourceFile = "modelos_armas/CrimsonEclipse.fbx",
		TextureFile = "modelos_armas/CrimsonEclipse_tex.png",
	},
	-- Premio de la ruleta (Espadón): Mandoble de Sangre Lunar
	BloodMoonCleaver = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.45),
		BladeTip = Vector3.new(0, 0, 7.60),
		TipZ = 7.60,
		SourceFile = "modelos_armas/BloodMoonCleaver.fbx",
		TextureFile = "modelos_armas/BloodMoonCleaver_tex.png",
	},
	-- Premio de la ruleta (Maza): Quebrantahuesos del Eclipse
	CataclysmMaw = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 3.15),
		BladeTip = Vector3.new(0, 0, 4.90),
		TipZ = 4.90,
		SourceFile = "modelos_armas/CataclysmMaw.fbx",
		TextureFile = "modelos_armas/CataclysmMaw_tex.png",
	},

	-- 2. Cinco skins piloto (1 por clase de arma: Dagas, Espada, Espadón, Estoque, Maza)
	-- Piloto Dagas (Relic05: Garras del Eclipse)
	EclipseClaws = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 0.60),
		BladeTip = Vector3.new(0, 0, 2.88),
		TipZ = 2.88,
		SourceFile = "modelos_armas/EclipseClaws.fbx",
		TextureFile = "modelos_armas/EclipseClaws_tex.png",
	},
	-- Piloto Espada (Requiem: Réquiem Astado)
	RequiemHorns = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 0.85),
		BladeTip = Vector3.new(0, 0, 5.10),
		TipZ = 5.10,
		SourceFile = "modelos_armas/RequiemHorns.fbx",
		TextureFile = "modelos_armas/RequiemHorns_tex.png",
	},
	-- Piloto Espadón (Relic19: Alas del Abismo)
	AbyssWings = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.40),
		BladeTip = Vector3.new(0, 0, 7.60),
		TipZ = 7.60,
		SourceFile = "modelos_armas/AbyssWings.fbx",
		TextureFile = "modelos_armas/AbyssWings_tex.png",
	},
	-- Piloto Estoque (Relic26: Lamento Oscuro)
	DarkLament = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 0.92),
		BladeTip = Vector3.new(0, 0, 5.56),
		TipZ = 5.56,
		SourceFile = "modelos_armas/DarkLament.fbx",
		TextureFile = "modelos_armas/DarkLament_tex.png",
	},
	-- Piloto Maza (Maw04: Corona del Osario)
	OssuaryCrown = {
		MeshId = 0,
		TextureId = 0,
		Scale = Vector3.new(1, 1, 1),
		Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 3.15),
		BladeTip = Vector3.new(0, 0, 4.90),
		TipZ = 4.90,
		SourceFile = "modelos_armas/OssuaryCrown.fbx",
		TextureFile = "modelos_armas/OssuaryCrown_tex.png",
	},

	----------------------------------------------------------------------
	-- ARMAS BASE Y VARIANTES ADICIONALES EN modelos_armas/
	----------------------------------------------------------------------
	Dagger = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 0.60), BladeTip = Vector3.new(0, 0, 2.87), TipZ = 2.87,
		SourceFile = "modelos_armas/Dagger.fbx", TextureFile = "modelos_armas/Dagger_tex.png",
	},
	Sword = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 0.96), BladeTip = Vector3.new(0, 0, 5.10), TipZ = 5.10,
		SourceFile = "modelos_armas/Sword.fbx", TextureFile = "modelos_armas/Sword_tex.png",
	},
	Greatsword = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.40), BladeTip = Vector3.new(0, 0, 7.60), TipZ = 7.60,
		SourceFile = "modelos_armas/Greatsword.fbx", TextureFile = "modelos_armas/Greatsword_tex.png",
	},
	Rapier = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.20), BladeTip = Vector3.new(0, 0, 5.56), TipZ = 5.56,
		SourceFile = "modelos_armas/Rapier.fbx", TextureFile = "modelos_armas/Rapier_tex.png",
	},
	Mace = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 3.20), BladeTip = Vector3.new(0, 0, 4.90), TipZ = 4.90,
		SourceFile = "modelos_armas/Mace.fbx", TextureFile = "modelos_armas/Mace_tex.png",
	},
	EmeraldTomb = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.40), BladeTip = Vector3.new(0, 0, 7.60), TipZ = 7.60,
		SourceFile = "modelos_armas/EmeraldTomb.fbx", TextureFile = "modelos_armas/EmeraldTomb_tex.png",
	},
	Devourer = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.40), BladeTip = Vector3.new(0, 0, 7.60), TipZ = 7.60,
		SourceFile = "modelos_armas/Devourer.fbx", TextureFile = "modelos_armas/Devourer_tex.png",
	},
	RoyalMourning = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.40), BladeTip = Vector3.new(0, 0, 7.60), TipZ = 7.60,
		SourceFile = "modelos_armas/RoyalMourning.fbx", TextureFile = "modelos_armas/RoyalMourning_tex.png",
	},
	DuskCross = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.40), BladeTip = Vector3.new(0, 0, 7.60), TipZ = 7.60,
		SourceFile = "modelos_armas/DuskCross.fbx", TextureFile = "modelos_armas/DuskCross_tex.png",
	},
	Shroud = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 1.40), BladeTip = Vector3.new(0, 0, 7.58), TipZ = 7.58,
		SourceFile = "modelos_armas/Shroud.fbx", TextureFile = "modelos_armas/Shroud_tex.png",
	},
	AncientMaw = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 3.15), BladeTip = Vector3.new(0, 0, 4.85), TipZ = 4.85,
		SourceFile = "modelos_armas/AncientMaw.fbx", TextureFile = "modelos_armas/AncientMaw_tex.png",
	},
	AbyssVertebra = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 3.15), BladeTip = Vector3.new(0, 0, 4.90), TipZ = 4.90,
		SourceFile = "modelos_armas/AbyssVertebra.fbx", TextureFile = "modelos_armas/AbyssVertebra_tex.png",
	},
	SepulcherJaws = {
		MeshId = 0, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0),
		BladeBase = Vector3.new(0, 0, 3.15), BladeTip = Vector3.new(0, 0, 4.88), TipZ = 4.88,
		SourceFile = "modelos_armas/SepulcherJaws.fbx", TextureFile = "modelos_armas/SepulcherJaws_tex.png",
	},
}

return WeaponMeshes
