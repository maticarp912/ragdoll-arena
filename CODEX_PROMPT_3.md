# Tarea para Codex — Lote 3: ambientación e interfaz (en paralelo con Claude)

Proyecto Roblox (Luau) en esta carpeta. Lee primero `README.md`, `RESUMEN_PROYECTO.md`, `TAREAS_CODEX_2.md` y `REVISION_CODEX_2.md`. Responde en español rioplatense. Todo valor numérico va en módulos de datos (`Theme`, `ArenaConfig`, `PolishConfig`), nunca suelto en la lógica.

**Mira las imágenes de `referencias/` antes de empezar** (son la referencia visual del usuario):
- `01_cielo_estrellas_doradas.webp` — el cielo que quiere
- `02_lobby_pueblo_noche.webp`, `03_lobby_calle_taberna.webp` — estética del lobby
- `04_arena_plataforma_flotante.webp` — idea de la arena
- `05_camara_picada_ejemplo.webp` — ejemplo de cámara (lo hace Claude)
- `06_inventario_ejemplo.webp`, `08_tienda_ejemplo.webp` — cómo quiere el inventario y la tienda
- `07_postura_combate_y_hud.webp` — postura de combate (Claude) y HUD de partida (vos)

## Contexto: TODOS los cambios que pidió el usuario
Para que entiendas el conjunto. Vos hacés solo la sección "Tu parte"; Claude hace "Parte de Claude".
1. Cielo como la imagen 01: miles de estrellas doradas brillantes, densas, sobre siluetas oscuras de árboles/montañas, con una luna brillante.
2. Lobby con la estética de las imágenes 02 y 03: pueblo de fantasía de noche, empedrado violeta/lavanda, casitas de madera con techos puntiagudos, faroles cálidos, árboles verde azulado, flores violetas, barriles.
3. Arena como la imagen 04 (plataforma de piedra flotante: losa plana arriba y una base de roca escalonada en forma de pirámide invertida que termina en punta), con el cielo y el fondo de la imagen 01 (siluetas oscuras de árboles y montañas, niebla). **Le gusta el derrumbe actual**: se mantiene (las losas siguen cayendo una a una).
4. No le gusta el brillo actual del mapa: hay que rehacer la iluminación junto con el cielo.
5. Tienda como la imagen 08 y **centrada en pantalla**: tarjetas con rareza (Legendario/Estándar…), el objeto grande sobre fondo oscuro con brillo de color, botón de precio (violeta = Robux/gemas, dorado = monedas). Inventario de armas con tarjetas como la imagen 06.
6. La infusión se elige ANTES de la partida, igual que el arma, y **no se puede cambiar durante la partida ni entre rondas**.
7. (Claude) La carga de la infusión se conserva entre rondas de la misma partida.
8. (Claude) Animaciones: al caminar la cabeza hace un movimiento raro; la pose de reposo tiene los brazos extendidos y la quiere con los brazos hacia abajo, natural; postura de combate como la imagen 07; todo más pulido y fluido; ataques un poco más lentos, con más recorrido y más exagerados, en todas las armas; las dagas deben alternar claramente una mano y la otra.
9. (Claude) Pequeña penalización de velocidad después del dash.
10. (Claude) Más vida para los jugadores.
11. (Claude) Que cada arma se sienta distinta (ahora parece la misma).
12. (Claude) Hitboxes de ataques y de jugadores más chicas y ajustadas al R15.
13. (Claude) Cámara sin zoom (ni acercar ni alejar) y en picada, un poco hacia la izquierda (imagen 05).

## Tu parte (solo estos archivos)
Puedes crear y editar **solo**:
`ReplicatedStorage/Theme.lua`, `ReplicatedStorage/ArenaConfig.lua`, `ReplicatedStorage/PolishConfig.lua` (salvo lo de caminar, ver abajo), `ServerScriptService/ArenaBuilder.lua`, `ServerScriptService/ShopService.server.lua`, `StarterPlayer/StarterPlayerScripts/Arena.client.lua`, `Shop.client.lua`, `HUD.client.lua`, `Overhead.client.lua`, y los nuevos `ServerScriptService/LobbyBuilder.lua` y `ReplicatedStorage/Environment.lua`.

1. **`Environment.lua`** (nuevo, ModuleScript en ReplicatedStorage) con `Environment.apply()` que configura todo `Lighting`: cielo nocturno como la imagen 01 (objeto `Sky` con muchas estrellas, luna visible y grande; además estrellas doradas densas y brillantes, por ejemplo con ParticleEmitter de vida larga y velocidad 0 en partes invisibles muy altas, o un domo de puntos Neon creado en el cliente), Atmosphere con niebla, ColorCorrection y Bloom. Que no quede ni quemado ni demasiado oscuro: hay que leer bien a los personajes. Valores en `Theme.Lighting`. Claude lo llamará desde MatchService.
2. **`LobbyBuilder.lua`** (nuevo) con `LobbyBuilder.build(parentFolder)`, que devuelve `{ spawn = CFrame, practiceCenter = Vector3, dummyHomes = { CFrame, CFrame, CFrame } }`. Debe construir el lobby y la zona de práctica con la estética de las imágenes 02 y 03: calle empedrada violeta, casitas con techos puntiagudos, faroles con luz cálida, árboles, flores, barriles y bancos. Mantener una zona de práctica plana para los 3 muñecos y el cartel. Sin colisiones raras: el suelo debe ser caminable. Rendimiento razonable (agrupar decoración, `CanQuery = false` en adornos). **No edites MatchService**: Claude conecta `LobbyBuilder` y `Environment`; si no existen, MatchService usa el lobby actual.
3. **Arena** (`ArenaBuilder`, `ArenaConfig`, `Arena.client`): plataforma flotante como la imagen 04 (losa plana con borde de piedra y base de roca escalonada en pirámide invertida que acaba en punta), suspendida en niebla. Alrededor y abajo, el fondo de la imagen 01: siluetas de árboles y montañas, niebla y el cielo dorado. La losa superior se sigue dividiendo en piezas que caen una a una, como ahora; la base de roca puede desprenderse en trozos al caer el borde, o quedar. Mantén la API actual de `ArenaBuilder` (`build`, `reset`, `run`, `debug`) y el tamaño jugable (2v2 grande, 1v1 más chica; rondas de 2 min o más).
4. **Tienda e inventario** (`Shop.client.lua`, `ShopService.server.lua`): menú centrado en pantalla con el estilo de las imágenes 06 y 08. Tarjetas con etiqueta de rareza, nombre, vista previa grande del arma o skin sobre un fondo oscuro con brillo de color, y botón de precio (violeta para Robux, dorado para monedas). Pestañas: Armas, Infusión, Skins, Controles. Agrega `rarity` a las skins solo si hace falta, en `Skins.lua`, sin quitar campos. **Durante una partida (`InMatch`) arma e infusión quedan bloqueadas**: el servidor rechaza `SelectWeapon` y `SelectInfusion` con un mensaje, y la UI las muestra bloqueadas con un candado.
5. **HUD de partida** (`HUD.client.lua`, `Overhead.client.lua`): en partida, estilo imagen 07. Arriba a la izquierda tu retrato con marco en rombo, nombre y barra de vida inclinada. Arriba a la derecha el rival (en 2v2, los dos rivales en pequeño). Abajo al centro la barra de Guardia con el icono de escudo, y la Stamina, el Stun y la infusión integrados con el mismo estilo. En el lobby, un HUD más simple. Mantén lo que ya funciona: rastro de daño, color y estado de la infusión, avisos.

## No toques (lo hace Claude en paralelo)
`AnimClips`, `Animator.client`, `WeaponData`, `CombatConfig`, `Combat`, `Actions`, `Infusion.lua`, `Infusions.lua`, `Dummies`, `Controls.client`, `MatchService`, `PlayerData`, `Assets`, `Fx`, `Vfx.client`, `Infusion.client`, `CombatService`, `Debug.client`, `InputMap`, `Ragdoll`, `WeaponBuilder`. En `PolishConfig.lua` no toques las claves de caminata/locomoción. Si necesitas algo de esos archivos, déjalo anotado en tu resumen en lugar de editarlo.

## Al terminar
- `node tools/check_lua.js .` sin errores.
- `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`.
- Escribe `REVISION_CODEX_3.md` con lo hecho, cómo probarlo y lo que necesites que Claude conecte.
