# Revisión Claude — Lote 3 (combate, animación y cámara)

Hecho en paralelo con Codex (`CODEX_PROMPT_3.md`: ambientación, lobby, arena, tienda y HUD).

## Cambios
- **Vida +80 %** (`WeaponData`): Espada 180, Espadón 215, Dagas 160, Estoque 170, Maza 235.
- **Ataques más lentos** (+20–25 % de duración en combo y fuerte) y **más exagerados**: `AnimClips.Playback.Exaggerate = 1.22` amplía el recorrido de M1 y fuerte respecto a la postura (`Animator`).
- **Cada arma se siente distinta** (`WeaponData.Feel`): micro-pausa y sacudida según el peso, paso adelante con cada golpe (`lunge`: la estocada del Estoque avanza mucho, las Dagas casi nada) y caminata según el peso (zancada y bote).
- **Dagas**: golpe 1 con la derecha y golpe 2 con la izquierda, con el torso enroscado y la otra mano recogida a la cadera; golpe 3 en cruz con las dos.
- **Reposo natural**: brazos hacia abajo y arma baja por delante (como `referencias/07`), piernas en guardia ligeramente agachado con un pie adelantado.
- **Caminata nueva** (`AnimClips.Locomotion`): fase por distancia, rodilla de la pierna que avanza, bote suave, pelvis que gira y torso que compensa. **La cabeza se estabiliza**: ya no se bambolea al caminar.
- **Dash**: al terminar, velocidad ×0,6 durante 0,35 s (`CombatConfig.Dodge.AfterSlow*`).
- **Hitboxes más chicas** y ajustadas al R15: caja de 5 de alto, alcance y ancho reducidos por arma, y solo cuentan las piezas del cuerpo (ni accesorios, ni pelo, ni arma, ni HumanoidRootPart).
- **Cámara** (`Controls`, `CombatConfig.Camera`): sin zoom (distancia fija 15), en picada de 24° y con el personaje un poco a la izquierda. No atraviesa paredes y en ragdoll sigue al torso. Con el objetivo fijado mira al rival.
- **Carga de infusión entre rondas** (`MatchService` + `Combat.setupCharacter`): se guarda al terminar cada ronda y se restaura en la siguiente; cada partida empieza en 0. Si estaba encendida, se considera gastada.
- **MatchService** usa `ReplicatedStorage/Environment` (cielo e iluminación) y `ServerScriptService/LobbyBuilder` (lobby) si existen. Si fallan, vuelve al lobby y la iluminación básicos.

## Pendiente de Codex (su lote)
Bloqueo de arma e infusión durante la partida (`ShopService` + UI), cielo, lobby, arena flotante, tienda centrada y HUD de partida.

## Probar
P → Llenar infusión; caminar de frente, de lado y hacia atrás (mirar la cabeza); combo con cada arma (las Dagas alternan); dash (frenado breve al final); cámara (rueda del ratón sin efecto).
