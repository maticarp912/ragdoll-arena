# Reparto etapa 8 (9/11/2026)

Tres IA trabajan en paralelo sobre la misma carpeta. **Cada archivo tiene un solo responsable.** Claude coordina, integra, prueba en Studio y es el único que regenera `Ragdoll Arena.rbxlx`.

- Prompts completos: [[Tareas Codex etapa 8]] y [[Tareas Gemini etapa 8]].
- Puntos de conexión: [[Contratos etapa 8]].
- Guías externas y revisor de código (regla C0): [[Referencia LihFolk]].
- Reportes (cada IA escribe el suyo): [[Reporte Codex etapa 8]] y [[Reporte Gemini etapa 8]].

## Reparto
- **Claude**: combate, animaciones, avisos de ataques fuertes, ciudad, cielo, sonido e integración. Es el que tiene Studio para inspeccionar la ciudad y probar todo.
- **Codex**: la parte de servidor y datos (economía, misiones, tablas de clasificación, compras, guardado y auras), y además las arenas.
- **Gemini**: toda la interfaz, como diseñador profesional, y los modelos de las armas.

## Tabla
| Resp. | Tarea | Archivos exclusivos | Depende de | Terminado cuando |
|---|---|---|---|---|
| Claude | ✅ Contratos iniciales | `Localization`, `CombatEvents` (nuevo), `InputBridge` (nuevo), `Sky.client` (separado de `Arena.client`), `tools/make_rbxlx.js` y `tools/check_lua.js` (ReplicatedFirst) | — | hecho |
| Claude | Combate: vida +35 %, dash más corto, carga y lanzamiento | `CombatConfig`, `WeaponData`, `Combat`, `Actions`, `CombatService` | — | valores documentados y probados jugando |
| Claude | Dash que sigue y rodea al objetivo fijado; bug de la animación del dash con objetivo | `Controls.client`, `Animator.client`, `AnimClips`, `Actions` | — | el dash con objetivo rodea bien y la animación sale correcta |
| Claude | Punto rojo en la punta para todos los fuertes; quitar el naranja del arma | `Overhead.client`, `Vfx.client`, `Infusion.client`, `PolishConfig` | `BladeTip` | señal clara, imbloqueable distinguible, la skin se sigue viendo |
| Claude | Animaciones con armas nuevas; alcance del espadón | `Animator.client`, `AnimClips`, `MocapClips` | fase 2 de Gemini | agarre, IK y estela bien; alcance ajustado y documentado |
| Claude | Ciudad (bugs y estilo pueblo RPG), tableros de clasificación ubicados. Según los nombres de las referencias: **taberna/alquimista** (`bar lobby.jpg`, `03_lobby_calle_taberna.webp`: estantes de pociones, frascos colgantes que brillan, barriles, banquetas, camino curvo), **punto de aparición** (`spawn.jpg`: círculo de runas doradas en la piedra bajo árboles retorcidos con musgo, niebla y lucecitas) y **ambiente** (`referencia ambiente de lobby*.jpg`: hongos gigantes luminosos, faroles colgantes, fuente, puestos de mercado; con énfasis dark fantasy) | `LobbyBuilder`, `CityConfig`, `Lobby.client` | — | lista de bugs con su arreglo; tableros con etiqueta (C7) |
| Claude | Cielo de estrellas doradas | `Sky.client`, `Atmosphere.client`, `Environment`, `Theme` | — | comparado con la referencia 01, límites explicados |
| Claude | Pulido: SoundGroups y opciones aplicadas, táctil conectado, textos de combate traducidos, cámara de espectador, validación de remotos | `Fx`, `Controls.client`, `CombatService`, `LocaleES/EN/PT`, `Assets`, `InputMap` | C9, C10, C12 | probado en Studio |
| Claude | Integración y pruebas finales | `Notas/*` (menos los reportes), `.rbxlx` | todo | `check_lua` OK, place regenerado, pruebas separadas por estado |
| Codex | Guardado confiable, recibos, monedas de depuración, opciones | `PlayerData`, `ShopService`, `Debug.client` | — | recibo solo si guarda; persistencia probada |
| Codex | Estadísticas, monedas por partida, misiones diarias, tablas de clasificación, resumen de partida | `StatsService`, `MissionService`, `LeaderboardService`, `Economy`, `Missions`, `MatchService` | C6 (hecho) | C7, C8 y C9 funcionando |
| Codex | Auras: catálogo, efectos, servidor | `Auras`, `AuraFx`, `Auras.client`, `LocaleCodex` | C4 | 10 auras, C11 funcionando |
| ~~Codex~~ **Claude** (9/11) | Arenas: bug negro del derrumbe, peligros en el vacío, 3 arenas nuevas | `ArenaBuilder`, `ArenaConfig`, `Arena.client`, `ArenaBackdrop.client` (la elección de arena en `MatchService` la pide Claude a Codex o la hace cuando Codex termine) | — | rotación de arenas en ambos modos |
| Codex | Doble cola y mensajes de partida traducidos | `MatchService` | C2 (hecho) | resueltos |
| Gemini | Espada base sencilla y skin `Requiem`; vista previa = arma equipada | `WeaponBuilder`, `SkinDesigns`, `Skins`, `LocaleGemini` | — | diseño conservado, `Default` intacto |
| Gemini | Espadones (prioridad), espadas, dagas, 2–3 mazas óseas, Blender | lo anterior más `WeaponMeshes`, `tools/preview_skins.lua`, `tools/blender/`, `modelos_armas/` | — | todas construyen; mismo largo por clase |
| Gemini | Sistema de diseño, tienda (con Auras y Clasificatorias «Próximamente»), HUD | `UiTheme`, `UiAssets`, `Shop.client`, `HUD.client` | C11, C2 | escritorio, pantalla chica, móvil y mando |
| Gemini | Lobby (cola, misiones, clasificatorias), tableros, fin de partida, ajustes, táctil, pantalla de carga, iconos | `LobbyUI.client`, `Leaderboards.client`, `MatchUI.client`, `Settings.client`, `TouchUI.client`, `ReplicatedFirst/LoadingScreen.client`, `ui_assets/` | C3, C7–C10, C12, C13 | funciona aunque falten módulos de Codex |

Fuera de esta etapa: hachas (sexta arma) y clasificatorias con lógica (solo «Próximamente»).

## Cambios de reparto
- 9/11: Codex lleva el 65 % de sus créditos con las fases 1 y 2 hechas. Las arenas pasan a Claude. Codex sigue con doble cola, mensajes traducidos y auras. Si se queda sin créditos, lo pendiente (y sus archivos) pasa a Claude según su reporte.

- 9/11, 14:25: **Codex terminó** (fases 1–3 y arreglos de cola y mensajes). Sus archivos pasan a Claude: `PlayerData`, `ShopService`, `MatchService`, `StatsService`, `MissionService`, `LeaderboardService`, `Economy`, `Missions`, `Auras`, `AuraFx`, `Auras.client`, `Debug.client`, `LocaleCodex`.

- 9/11, 16:00: **Codex ronda 2** (créditos reiniciados): vuelve a tomar las arenas (`ArenaBuilder`, `ArenaConfig`, `Arena.client`, `ArenaBackdrop.client`, la elección de arena en `MatchService` y `LocaleCodex`) y, si le sobra, revisa en solo lectura la interfaz de Gemini. Claude se queda con el resto de los archivos que eran de Codex.

- 9/11, 16:30: **Ronda 3** (ver [[Tareas ronda 3]]). Gemini: arreglos de interfaz (Flash) y segunda pasada de arte de las arenas (Argon); los archivos de arena pasan de Codex a Gemini. Codex: `CityProps.lua` (taberna, santuario del punto de aparición, tableros, hongos y vegetación). Claude: estilo general de la ciudad, cielo, cámara de espectador, pruebas e integración; ya tomó `TouchUI`, `MatchUI` y `LobbyUI` para arreglos puntuales (vuelven a Gemini en la ronda 3), y `WeaponBuilder` para la espada a dos manos y la escala de la maza.

- 9/11, 17:30: **Ronda 4** ([[Tareas ronda 4]]). Codex estaba libre y Argon tarda: los arreglos de interfaz (A2) pasan a Codex junto con los archivos `HUD`, `Shop`, `LobbyUI` y `LoadingScreen`. También le tocan caminos de la ciudad y pueblerinos (`CityNPCs`). Gemini Argon sigue solo con las arenas.

## Separaciones hechas para que nadie comparta archivos (Claude, 9/11)
- `Lobby.client` → la barra de cola pasó a `LobbyUI.client` (Gemini) y el fondo de las arenas a `ArenaBackdrop.client` (Codex). `Lobby.client` queda con carteles, armería y marcador (Claude).
- `Arena.client` → las estrellas pasaron a `Sky.client` (Claude). `Arena.client` queda con las rocas flotantes (Codex).
- `Shop.client` pasa de Codex a Gemini. Codex provee los datos, el servidor y los efectos de las auras (C11).

## Auditoría de pulido (9/11, leyendo el código)
| Hallazgo | Responsable |
|---|---|
| No hay controles táctiles: en móvil no se puede pelear | Gemini (`TouchUI`) + Claude (`InputBridge` en `Controls`) |
| No hay SoundGroups ni volumen de música o efectos | Claude (sonidos) + Codex (guardar opciones) + Gemini (Ajustes) |
| Textos sobre la cabeza en español fijo («¡DERRIBADO!», «¡PARRY!», «GUARDIA ROTA», etc.) | Claude |
| Sin pantalla de carga (el generador no tenía ReplicatedFirst: ya lo tiene) | Gemini |
| Sin resumen de partida ni aviso de eliminaciones | Codex (datos) + Gemini (pantalla) |
| Sin cámara de espectador al morir en 2v2 | Claude (con el atributo `Eliminated` de Codex) |
| Guardado con `SetAsync`, sin bloqueo de sesión ni resultado | Codex |
| Remoto `Input` sin límite de frecuencia | Claude |
| Monedas por partida fijas (50 / 15) y sin misiones | Codex |
| Doble cola, mensajes de partida sin traducir, mando en la confirmación de compra, recibo de Robux | Codex (los dos primeros y el recibo) y Gemini (mando) |

## Orden
1. ✅ Contratos y separación de archivos (Claude).
2. En paralelo: Claude (combate, dash, avisos, ciudad, cielo, pulido), Codex (fases 1–4) y Gemini (fases 1–5).
3. Claude integra: lee los reportes, prueba las animaciones con los espadones nuevos, corre `check_lua`, regenera el place y prueba en Studio (escritorio, pantalla chica, móvil y mando).
