# Animaciones (assets en `F:\RobloxJuegos\assets animaciones`)

## Qué hay
Animaciones de **Mixamo** en **FBX** con esqueleto `mixamorig` (el de Mixamo, no el R15 de Roblox):
- Sueltas: `Great Sword 180 Turn`, `Great Sword Run`, `Standing Melee Attack Backhand`, `Standing Melee Attack Downward`, `Sword And Shield Attack`, `patada bloqueo` (también FBX, sin extensión).
- `Great Sword Pack.zip`: 51 animaciones de espadón (idle, walk, strafe, run, slash 1–5, blocking 1–3, impact 1–5, kick, jump attack, slide attack, high spin attack, casting, power up, death, desenvainar…).

## Estado: ya están en el juego (lote 7) ✅
Se incorporaron **sin subirlas a Roblox**, con la conversión automática de abajo («Conversión automática»): 21 clips en `ReplicatedStorage/MocapClips.lua`.
- Espadón: tajos 1–3 y fuerte de giro. Maza: 3 golpes y fuerte por arriba. Espada: revés, tajo y golpe descendente.
- Patada «patada bloqueo» para todas las armas; reacciones de impacto de cuerpo entero (más fuertes con los golpes fuertes).
- Dagas y estoque siguen procedurales.
- ✅ En Studio se reproducen sin errores. ⬜ Falta jugar y juzgar la sensación. ⬜ Etapa 8: comprobar con las proporciones nuevas de las armas (espadón más grande).

La importación manual de abajo queda como alternativa (por ejemplo, para locomoción con IDs de Roblox).

## Alternativa: importarlas a mano en Studio (no hace falta hoy)
Roblox no reproduce FBX de Mixamo directamente: hay que pasarlas a R15, publicarlas con tu cuenta y pegar el ID en `Assets.lua`. El juego usa la animación con ID en lugar de la procedural y sincroniza el daño con el marcador `Hit` (y `WindupEnd` en el fuerte).
1. En Studio: **Avatar → Rig Builder → R15 (bloques)** para tener un maniquí.
2. Abre el **Animation Editor** con el rig seleccionado → menú `...` → **Import → From FBX Animation** y elige el `.fbx`.
   - Si el rig no se mueve o se deforma, es por el retarget de Mixamo: usa un plugin de retarget Mixamo→R15 de la Creator Store, o pásalo por Blender con un rig R15.
3. Añade los **marcadores**: `Hit` en el impacto; en los fuertes también `WindupEnd` al terminar la preparación.
4. **Publish to Roblox** y copia el ID en `Assets.lua`.

## Qué archivo iría a cada clave si se importaran a mano
| Clave en `Assets.lua` | Archivo |
|---|---|
| `Weapons.Greatsword.Idle` | `great sword idle` (o idle 2–5) |
| `Weapons.Greatsword.M1_1` / `M1_2` / `M1_3` | `great sword slash`, `slash (2)`, `slash (3)` |
| `Weapons.Greatsword.Heavy` | `great sword high spin attack` o `great sword attack` |
| `Weapons.Greatsword.Block` | `great sword blocking` |
| `Weapons.Greatsword.BlockHit` | `great sword impact` |
| `Generic.HitReactFront` / `HitReactBack` | `great sword impact (2)` / `(3)` |
| `Generic.Kick` | `great sword kick` o `patada bloqueo` |
| `Generic.InfuseActivate` | `great sword power up` o `casting` |
| `Weapons.Sword.M1_1` / `M1_2` | `Standing Melee Attack Backhand` / `Downward` |
| `Weapons.Sword.Heavy` | `Sword And Shield Attack` (sin escudo en el juego: revisa la mano izquierda) |
| `Generic.DodgeF` | `great sword slide attack` (recortado) |

Caminar, correr y girar (`walk`, `run`, `strafe`, `turn`) hoy los hace la caminata procedural. Si se quieren reales, hay que añadir claves de locomoción a `Assets.lua` y al `Animator`.

## Conversión automática (lote 7)
1. `blender-launcher.exe -b --python tools/mixamo_to_r15.py -- tools/mocap_all.json <fbx...>`. Blender está en la Microsoft Store; usar el alias `%LOCALAPPDATA%\Microsoft\WindowsApps\blender-launcher.exe`.
2. `node tools/mocap_to_lua.js tools/mocap_all.json`: elige y recorta los clips (tabla `PICK`) y escribe `ReplicatedStorage/MocapClips.lua`.
3. En `AnimClips.MocapMap` y `AnimClips.MocapGeneric` se elige qué clip reemplaza a cada golpe.

Método: rotación de cada hueso respecto de la T-pose, en el espacio del personaje. Los brazos se corrigen de T-pose a brazos abajo y el resultado se pasa a `Motor6D.Transform`. No hace falta subir animaciones a Roblox.
