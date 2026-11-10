# Integración 0.2 — lista de trabajo

Revisión de Claude de los reportes de la ronda 1 (10/11/2026), cruzando contratos contra el código. **Nada probado en Studio.** Los tres pasan `check_lua` (82 archivos) y LihFolk (0/0) según sus reportes.
Reportes: [[Reporte 0.2 Claude]], [[Reporte 0.2 Codex]], [[Reporte 0.2 Gemini]].

## Desajustes entre entregas — ✅ arreglados en código el 10/11/2026 (sin probar en Studio)
| # | Problema | Dónde | Arreglo propuesto | Dueño |
|---|---|---|---|---|
| I1 | La previa y la armería leen `MatchPhase` de `workspace`, que es **global**. Si hay una partida en curso, un jugador en la ciudad puede ver el estado de otra. Codex también lo publica **por jugador**. | `Prematch.client`, `Armory.client` | Leer `player:GetAttribute("MatchPhase")` (y `InMatch`); `workspace` solo como respaldo. Usar los nombres de C17 (`Round`, no `Fighting`). | ✅ Claude: `MatchService` publica `MatchPhase` y `PhaseEnds` también por jugador; previa y armería leen primero los del jugador. |
| I2 | «Destacado del día»: el servidor ya tiene `GetFeatured` (día de Argentina), pero la tienda calcula su propia lista con el día UTC. Verían objetos distintos y el cambio sería a las 21:00. | `Shop.client` ↔ `ShopService` | La tienda pide la lista con `GetFeatured` y el contador apunta a las 00:00 de Argentina (`Economy.DayOffset`). | ✅ Claude: se pide al abrir la tienda; el cálculo local queda de respaldo. |
| I3 | La tecla **B** abre la armería, pero B ya es `Menu` en `InputMap` (abre la tienda). Se abrirían las dos. | `Armory.client` | Tecla propia en `InputMap`. | ✅ Claude: acción `Armory` reasignable (V / cruceta izquierda); B queda solo para la tienda. Textos: «Menú» pasa a «Tienda». |
| I4 | El rol Tester no habilita la depuración en `CombatService` (sigue con `CreatorId` + lista). | `CombatService` | Usar `RoleService.has(player, "Debug")` en las dos rutas. | ✅ Claude: también Studio y la lista de IDs siguen valiendo (antes el rol apagaba la depuración en Studio). |
| I5 | Gemini dice que Rojo ya tiene `default.project.json`: **no existe**. | raíz | Crearlo (D21). | ✅ `default.project.json` creado (solo sincroniza scripts; no toca Workspace ni Lighting). Falta instalar Rojo. |

## Pedidos ya resueltos
- Gemini pidió permitir elegir arma, infusión y skin durante la previa: **Codex ya lo hizo** en `ShopService` (es archivo de Codex, no de Claude).
- Colores de rol: `Overhead.client` (Claude) ya lee `Roles.Data[rol].color`, que es la forma que dejó Codex.
- `Frozen` / `CanFight` durante la previa: el combate ya los respeta (`Combat`, `Directional`).

## Pedidos de los reportes
- ✅ `CityLife.client`: cachea `CityDressing` y no lo busca durante la partida (hallazgo 9).
- ✅ `Debug.client`: modos `DirOne`/`DirRandom` y botón «Lado del muñeco».
- ✅ `TouchUI`: ya mandaba «soltar» en todos los botones; la patada al derribado funciona sin cambios.
- `Cinematic.client` (ronda 2): empezar solo con `MatchPhase = Cinematic` y un `PhaseEnds` válido.

## Para el usuario 👤
- Subir las 8 mallas de la tanda 1 con sus texturas (lista y pasos en [[Reporte 0.2 Gemini]], sección 5, y `modelos_armas/GUIA_SUBIDA_MALLAS.md`) y pegar los IDs en `WeaponMeshes.lua`. Mientras tanto se ven las versiones por código.
- Rojo es opcional: hace falta el programa (CLI) y el plugin de Studio. Sin Rojo se regenera el place con `node tools/make_rbxlx.js`, como siempre.

## Orden de la sesión de integración
1. ✅ Arreglar I1 a I5 y los pedidos de arriba (10/11/2026; `check_lua` OK 82 archivos, LihFolk 0/0).
2. `check_lua` + LihFolk; Rojo o regenerar el place.
3. Probar en Studio con las listas de los tres reportes: primero `Directional.Enabled = false` (debe quedar como la 0.1 más la sensación), después `true`; 1v1 y 2v2 con varios clientes; celular y mando.
4. Commit con el resultado de las pruebas.

## Para decidir el usuario
- **Skins de la ruleta a la venta:** hoy `CrimsonEclipse`, `BloodMoonCleaver` y `CataclysmMaw` también se pueden comprar en la tienda (9500 almas). Propuesta de Claude: que sean **exclusivas de la ruleta** (y de las cajas), para que el premio grande valga la pena; en la tienda se muestran con «Solo en la ruleta».

## Pruebas en Studio
Prompt para la sesión nueva: [[0.2 Integración - pruebas en Studio]].
