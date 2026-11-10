# Guía de Subida de Mallas 3D y Texturas (`modelos_armas/` → `ReplicatedStorage/WeaponMeshes.lua`)

Esta carpeta contiene las mallas 3D de alta resolución (`.fbx` y `.obj`, entre **1 000 y 2 300 triángulos** pensadas para móvil) junto con sus texturas atlas `1024x1024` (`*_tex.png`), generadas de forma reproducible mediante:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" -b --python "F:\RobloxJuegos\Plataforme 2v2\tools\blender\generate_weapons.py"
```

## Convenciones técnicas de cada malla

- **Presupuesto de polígonos para móvil**: Entre **998 y 2 272 triángulos** (muy por debajo del límite de 5 000 triángulos de Roblox).
- **Textura (`*_tex.png`)**: Resolución `1024 x 1024 px` con 8 zonas UV separadas por material (`Edge` plata espejo, `Blade` obsidiana, `Glow` vena de relámpago carmesí, `Gem` rubí engarzado, `Accent` acero de guarda, `Trim` filigrana, `Grip` cuero estriado y `Dark` acanaladura).
- **Origen `(0, 0, 0)`**: Centrado exactamente en el mango (`Handle`), listo para soldarse (`Weld`) sin desfases.
- **Orientación de ejes**:
  - `+Z`: Dirección de la hoja / cabeza hacia la punta (`BladeTip` en `TipZ`).
  - `Y`: Ancho del filo / guarda.
  - `X`: Grosor de la hoja.
- **Escala**: `1 unidad = 1 stud` de Roblox.

## Tanda 1 de Blender (0.2 D6 / D15): 3 Skins de la Ruleta + 1 Skin Piloto por Arma

| Clave en `WeaponMeshes.lua` | Archivo `.fbx` / `.obj` | Textura `1024x1024` | Arma / Rol en 0.2 | Triángulos | Punta `TipZ` |
| :--- | :--- | :--- | :--- | :---: | :---: |
| `CrimsonEclipse` | `CrimsonEclipse.fbx` | `CrimsonEclipse_tex.png` | **Espada (`Sword`) — Gran premio semanal Ruleta (`espada-concepto.png`)** | `1 554` | `5.10` |
| `BloodMoonCleaver` | `BloodMoonCleaver.fbx` | `BloodMoonCleaver_tex.png` | **Espadón (`Greatsword`) — Premio de la Ruleta** | `1 554` | `7.60` |
| `CataclysmMaw` | `CataclysmMaw.fbx` | `CataclysmMaw_tex.png` | **Maza (`Mace`) — Premio de la Ruleta** | `2 272` | `4.90` |
| `EclipseClaws` | `EclipseClaws.fbx` | `EclipseClaws_tex.png` | **Piloto Dagas (`Dagger`, skin `Relic05`)** | `1 194` | `2.88` |
| `RequiemHorns` | `RequiemHorns.fbx` | `RequiemHorns_tex.png` | **Piloto Espada (`Sword`, skin `Requiem`)** | `1 342` | `5.10` |
| `AbyssWings` | `AbyssWings.fbx` | `AbyssWings_tex.png` | **Piloto Espadón (`Greatsword`, skin `Relic19`)** | `1 570` | `7.60` |
| `DarkLament` | `DarkLament.fbx` | `DarkLament_tex.png` | **Piloto Estoque (`Rapier`, skin `Relic26`)** | `1 574` | `5.56` |
| `OssuaryCrown` | `OssuaryCrown.fbx` | `OssuaryCrown_tex.png` | **Piloto Maza (`Mace`, skin `Maw04`)** | `2 076` | `4.90` |

## Armas Base y Variantes Adicionales en `modelos_armas/`

| Clave en `WeaponMeshes.lua` | Archivo `.fbx` / `.obj` | Textura `1024x1024` | Tipo / Skin | Triángulos | Punta `TipZ` |
| :--- | :--- | :--- | :--- | :---: | :---: |
| `Dagger` | `Dagger.fbx` | `Dagger_tex.png` | Arma base (Dagas) | `998` | `2.87` |
| `Sword` | `Sword.fbx` | `Sword_tex.png` | Arma base (Espada) | `1 106` | `5.10` |
| `Greatsword` | `Greatsword.fbx` | `Greatsword_tex.png` | Arma base (Espadón) | `1 278` | `7.60` |
| `Rapier` | `Rapier.fbx` | `Rapier_tex.png` | Arma base (Estoque) | `1 250` | `5.56` |
| `Mace` | `Mace.fbx` | `Mace_tex.png` | Arma base (Maza) | `1 036` | `4.90` |
| `EmeraldTomb` | `EmeraldTomb.fbx` | `EmeraldTomb_tex.png` | Skin `Relic14` (Espadón) | `1 546` | `7.60` |
| `Devourer` | `Devourer.fbx` | `Devourer_tex.png` | Skin `Relic15` (Espadón) | `1 594` | `7.60` |
| `RoyalMourning` | `RoyalMourning.fbx` | `RoyalMourning_tex.png` | Skin `Relic16` (Espadón) | `1 538` | `7.60` |
| `DuskCross` | `DuskCross.fbx` | `DuskCross_tex.png` | Skin `Relic17` (Espadón) | `1 538` | `7.60` |
| `Shroud` | `Shroud.fbx` | `Shroud_tex.png` | Skin `Relic18` (Espadón) | `1 570` | `7.58` |
| `AncientMaw` | `AncientMaw.fbx` | `AncientMaw_tex.png` | Skin `Relic31` (Maza ósea) | `1 796` | `4.85` |
| `AbyssVertebra` | `AbyssVertebra.fbx` | `AbyssVertebra_tex.png` | Skin `Maw02` (Maza ósea) | `1 868` | `4.90` |
| `SepulcherJaws` | `SepulcherJaws.fbx` | `SepulcherJaws_tex.png` | Skin `Maw03` (Maza ósea) | `1 748` | `4.88` |

## Pasos para subir con el Importador 3D de Roblox Studio y pegar cada ID

1. Abrí el proyecto en **Roblox Studio**.
2. En la cinta superior (*Home* o *Avatar*), hacé clic en **Import 3D** (o abrí **View → Asset Manager → Bulk Import**).
3. Seleccioná los archivos `.fbx` de la Tanda 1 en `modelos_armas/`:
   - `CrimsonEclipse.fbx`, `BloodMoonCleaver.fbx`, `CataclysmMaw.fbx`
   - `EclipseClaws.fbx`, `RequiemHorns.fbx`, `AbyssWings.fbx`, `DarkLament.fbx`, `OssuaryCrown.fbx`
4. En el panel del **Importador 3D**:
   - En *Transform / File Dimensions*, **desmarcá** *Rescale if too large* y verificá que *Scale Unit* sea **Studs (1:1)**.
   - Verificá que *Import Only As Model* o *Upload to Roblox* esté activo (el `.fbx` ya lleva incrustada su textura `<Nombre>_tex.png`; si subís el `.obj`, importá también `<Nombre>_tex.png` en *Images*).
   - Hacé clic en **Import**.
5. En **Asset Manager → Meshes** (y **Images**), hacé clic derecho sobre cada malla y textura subida y elegí **Copy ID to Clipboard**.
6. Abrí `ReplicatedStorage/WeaponMeshes.lua` y pegá los números en `MeshId` y `TextureId` de la clave correspondiente:
   ```lua
   CrimsonEclipse = {
       MeshId = 1234567890,    -- <-- Pegá acá el MeshId copiado
       TextureId = 9876543210, -- <-- Pegá acá el TextureId copiado
       ...
   },
   ```
7. Mientras `MeshId = 0`, `WeaponBuilder` construye automáticamente el modelo procedural de alta definición de `SkinDesigns.lua` sin errores.
