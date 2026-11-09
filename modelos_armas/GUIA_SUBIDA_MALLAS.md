# Guía de Subida de Mallas 3D (`modelos_armas/` → `ReplicatedStorage/WeaponMeshes.lua`)

Esta carpeta contiene las mallas 3D en formato `.fbx` y `.obj` generadas de forma reproducible mediante:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe" -b --python "F:\RobloxJuegos\Plataforme 2v2\tools\blender\generate_weapons.py"
```

## Convenciones técnicas de cada malla

- **Presupuesto de polígonos**: Todas las mallas tienen entre **300 y 1 200 triángulos** (muy por debajo del máximo de 5 000 triángulos de Roblox).
- **Origen `(0, 0, 0)`**: Centrado exactamente en el mango (`Handle`), listo para soldarse (`Weld`) sin desfases.
- **Orientación de ejes**:
  - `+Z`: Dirección de la hoja / cabeza hacia la punta (`BladeTip`).
  - `Y`: Ancho del filo / guarda.
  - `X`: Grosor de la hoja.
- **Escala**: `1 unidad = 1 stud` de Roblox.

## Catálogo de archivos exportados

| Clave en `WeaponMeshes.lua` | Archivo `.fbx` / `.obj` | Tipo / Skin | Punta `TipZ` (studs) |
| :--- | :--- | :--- | :---: |
| `Dagger` | `Dagger.fbx` / `.obj` | Arma base (Dagas) | `2.87` |
| `Sword` | `Sword.fbx` / `.obj` | Arma base (Espada caballeresca) | `5.10` |
| `Greatsword` | `Greatsword.fbx` / `.obj` | Arma base (Espadón colosal) | `7.60` |
| `Rapier` | `Rapier.fbx` / `.obj` | Arma base (Estoque) | `5.56` |
| `Mace` | `Mace.fbx` / `.obj` | Arma base (Maza / Martillo) | `4.90` |
| `RequiemHorns` | `RequiemHorns.fbx` / `.obj` | Skin `Requiem` (Espada gótica) | `5.14` |
| `EmeraldTomb` | `EmeraldTomb.fbx` / `.obj` | Skin `Relic14` (Espadón) | `7.60` |
| `Devourer` | `Devourer.fbx` / `.obj` | Skin `Relic15` (Espadón) | `7.60` |
| `RoyalMourning` | `RoyalMourning.fbx` / `.obj` | Skin `Relic16` (Espadón) | `7.60` |
| `DuskCross` | `DuskCross.fbx` / `.obj` | Skin `Relic17` (Espadón) | `7.60` |
| `Shroud` | `Shroud.fbx` / `.obj` | Skin `Relic18` (Espadón) | `7.58` |
| `AbyssWings` | `AbyssWings.fbx` / `.obj` | Skin `Relic19` (Espadón) | `7.60` |
| `AncientMaw` | `AncientMaw.fbx` / `.obj` | Skin `Relic31` (Maza ósea base) | `4.85` |
| `AbyssVertebra` | `AbyssVertebra.fbx` / `.obj` | Skin `Maw02` (Maza ósea nueva) | `4.90` |
| `SepulcherJaws` | `SepulcherJaws.fbx` / `.obj` | Skin `Maw03` (Maza ósea nueva) | `4.88` |
| `OssuaryCrown` | `OssuaryCrown.fbx` / `.obj` | Skin `Maw04` (Maza ósea nueva) | `4.90` |

## Pasos para subir en Roblox Studio y activar en el juego

1. Abrí el proyecto en **Roblox Studio**.
2. Abrí **View → Asset Manager** (o **Import 3D** desde la pestaña *Home* / *Avatar*).
3. Hacé clic en **Bulk Import** y seleccioná los archivos `.fbx` (o `.obj`) de `modelos_armas/`.
   - Desmarcá *Rescale if too large* para conservar la escala exacta en studs (`1:1`).
   - Confirmá la importación.
4. En **Asset Manager → Meshes**, hacé clic derecho sobre cada malla subida y elegí **Copy ID to Clipboard** (obtendrás un número como `1234567890`).
5. Abrí `ReplicatedStorage/WeaponMeshes.lua` y pegá ese número en el campo `MeshId` correspondiente:
   ```lua
   Sword = { MeshId = 1234567890, TextureId = 0, Scale = Vector3.new(1, 1, 1), Offset = CFrame.new(0, 0, 0), TipZ = 5.10 },
   ```
6. Mientras `MeshId = 0` (por defecto), `WeaponBuilder` construye automáticamente el modelo por piezas procedural sin errores ni dependencias externas.
