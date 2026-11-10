# Plan de desarrollo 0.2 — 10/11/2026 (Argentina, UTC-3)

Pedido del usuario: entrar en desarrollo, repartir parejo según la mejor virtud de cada IA, sin escatimar calidad, hasta pulir rumbo a la 1.0.
**Regla de esta etapa: se escribe todo el código sin probar en Studio.** Nadie usa la pantalla ni abre Studio. La integración y las pruebas se hacen después, en una sesión aparte de Claude.
Antes de arrancar, el usuario responde [[Decisiones pendientes 0.2]]. Las tareas que dependen de una decisión lo dicen (D1, D2…).

## Roles: cada IA en lo que mejor hace
| IA | Virtud | Rol en la 0.2 | Modelo |
|---|---|---|---|
| **Claude** | Sistemas complejos entre muchos archivos, tiempo real, combate y animación, coordinación | **Arquitecto de combate e integrador.** Combate direccional completo, sensación, cámara, cinemáticas, triángulo, integración final y pruebas en Studio. Único que hace commits (C0b). | **Opus 5.5**, esfuerzo alto (xhigh para la máquina de estados) |
| **Codex** | Precisión en servidor, datos y seguridad; revisión de código | **Backend y guardián.** Partida, guardado, economía, progresión, roles, administración, telemetría, y revisión de seguridad de lo que entregan los demás. | **Sol, High** (Medium solo para la revisión final) |
| **Gemini** | Diseño visual, modelado por código, interfaz y estética | **Director de arte y UI.** Skins, tienda, armería, previa, HUD, celular, ruleta. | **Argon, High** para arte y pantallas grandes; **Flash, Medium** para ajustes chicos |

## Presupuesto (semana del 10/11)
- **Argon (44 % libre) es el cuello de botella.** Va solo a lo que más luce: skins, tienda y armería, pantalla de la previa. HUD, celular y ruleta van en Flash.
- **Codex (60 % libre)** absorbe también el panel de administración (interfaz funcional, sin arte) y la revisión de seguridad, para no gastar Argon.
- **Claude (68 % libre)** hace el triángulo del direccional completo (lógica y visual), para que no quede repartido entre dos IA.
- Si Argon se agota: lo que quede de la UI de Gemini pasa a Flash High, y el arte de skins espera a la semana siguiente.

## Archivos exclusivos (nadie toca archivos de otro)
| IA | Archivos |
|---|---|
| Claude | `CombatConfig`, `WeaponData`, `Combat`, `Actions`, `CombatService`, `CombatEvents`, `Anim`, `AnimTiming`, `Dummies`, `Fx`, `PolishConfig`, `InputMap`, `InputBridge`, `AnimClips`, `MocapClips`, `Ragdoll`, `Controls.client`, `Animator.client`, `Overhead.client`, `Vfx.client`, `Infusion.client`, `Infusion` (servidor), **nuevos** `DirectionalHUD.client`, `Cinematic.client`, `LocaleES/EN/PT` (textos de combate) |
| Codex | `MatchService`, `PlayerData`, `ShopService`, `Economy`, `Missions`, `MissionService`, `StatsService`, `LeaderboardService`, `Debug.client`, `LocaleCodex`, `Remotes`, **nuevos** `Roles`, `RoleService`, `AdminService`, `AdminPanel.client`, `Progression`, `ProgressionService`, `Rewards`, `RewardService`, `Telemetry` |
| Gemini | `SkinDesigns`, `Skins`, `WeaponBuilder`, `WeaponMeshes`, `UiTheme`, `UiAssets`, `Shop.client`, `HUD.client`, `TouchUI.client`, `Settings.client`, `LobbyUI.client`, `MatchUI.client`, `LocaleGemini`, `tools/blender/`, `modelos_armas/`, `ui_assets/`, **nuevos** `Armory.client`, `Prematch.client`, `Rewards.client` |
| Sin dueño en la 0.2 | Ciudad y arenas (`LobbyBuilder`, `CityConfig`, `CityProps`, `ArenaBuilder`…): solo Claude en la ronda 3, si da el tiempo. |

`Remotes` lo edita solo Codex: si otra IA necesita un remoto nuevo, lo pide en «Pedidos a otros» o usa los que crea Codex en la ronda 1 (ver [[Contratos 0.2]]).

## Rondas
### Ronda 1: bases en paralelo
| IA | Tarea | Depende de |
|---|---|---|
| Claude | Direccional pasos 1 a 5 detrás de `Enabled` (máquina de estados, triángulo, bloqueo y parry por dirección, patada, derribado inmune, fijado permanente), combos por dirección | D1, D2, D4 |
| Claude | Bug de la cámara en celular al fijar; sensación del combate (hit-stop, golpe/recibir/bloqueo distintos, animaciones más largas); números de equilibrio | D3 |
| Codex | Bug del punto doble; previa de 10 s en el servidor; roles y administración; niveles y XP; telemetría de armas; hallazgos 5, 7 y 9 | D7, D8, D9, D11 |
| Gemini (Argon) | Rediseño de todas las skins con la espada de referencia, más 2 o 3 nuevas para la ruleta | D6, D15 |
| Gemini (Argon) | Tienda y armería separadas con vistas previas; pantalla de la previa (arma, skin, infusión, nombres) | D12, D13 |

### Ronda 2: lo que depende de la ronda 1
| IA | Tarea |
|---|---|
| Codex | Ruleta diaria y semanal, cajas de suerte y multiplicadores (servidor); almas según D5; panel de administración (interfaz funcional) |
| Gemini (Flash) | HUD nuevo (vida abajo al centro, infusión encima), celular (botones, textos, zonas seguras, editor de botones), interfaz de la ruleta y de subir de nivel |
| Claude | Cinemática antes del combate (cámara y poses) sobre la previa de Codex; patio de práctica con muñecos por dirección; táctil del direccional si da el tiempo |

### Ronda 3: revisión y pulido
- **Codex (Sol, Medium):** revisión de seguridad de todos los remotos nuevos y de la migración de datos, con reporte.
- **Gemini (Flash):** textos en los tres idiomas y pantallas chicas.
- **Claude:** arena de la Mano, ciudad estilo pueblo y cielo si sobra tiempo; preparar la integración.

### Sesión de integración (Claude, más adelante)
Juntar todo, `check_lua` y LihFolk, regenerar el place, probar en Studio (1v1 con dos clientes, 2v2, celular y mando), arreglar y recién ahí hacer commit y subir.

## Prompts listos para copiar
- Codex: [[0.2 Ronda 1 - Codex]]
- Gemini: [[0.2 Ronda 1 - Gemini]]
- Claude: [[0.2 Ronda 1 - Claude]]
