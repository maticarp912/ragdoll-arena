# Integración 0.2 — lista de trabajo

Revisión de Claude de los reportes de la ronda 1 (10/11/2026), cruzando contratos contra el código. **Nada probado en Studio.** Los tres pasan `check_lua` (82 archivos) y LihFolk (0/0) según sus reportes.
Reportes: [[Reporte 0.2 Claude]], [[Reporte 0.2 Codex]], [[Reporte 0.2 Gemini]].

## Desajustes entre entregas (arreglar en la integración)
| # | Problema | Dónde | Arreglo propuesto | Dueño |
|---|---|---|---|---|
| I1 | La previa y la armería leen `MatchPhase` de `workspace`, que es **global**. Si hay una partida en curso, un jugador en la ciudad puede ver el estado de otra. Codex también lo publica **por jugador**. | `Prematch.client`, `Armory.client` | Leer `player:GetAttribute("MatchPhase")` (y `InMatch`); `workspace` solo como respaldo. Usar los nombres de C17 (`Round`, no `Fighting`). | Gemini (o Claude en la integración) |
| I2 | «Destacado del día»: el servidor ya tiene `GetFeatured` (día de Argentina), pero la tienda calcula su propia lista con el día UTC. Verían objetos distintos y el cambio sería a las 21:00. | `Shop.client` ↔ `ShopService` | La tienda pide la lista con `GetFeatured` y el contador apunta a las 00:00 de Argentina (`Economy.DayOffset`). | Gemini |
| I3 | La tecla **B** abre la armería, pero B ya es `Menu` en `InputMap` (abre la tienda). Se abrirían las dos. | `Armory.client` | Tecla propia en `InputMap` (por ejemplo `Armory = "V"`) o solo el botón del dock. | Claude (`InputMap`) + Gemini |
| I4 | El rol Tester no habilita la depuración en `CombatService` (sigue con `CreatorId` + lista). | `CombatService` | Usar `RoleService.has(player, "Debug")` en las dos rutas. | Claude |
| I5 | Gemini dice que Rojo ya tiene `default.project.json`: **no existe**. | raíz | Crearlo en la sesión de integración (D21). | Claude |

## Pedidos ya resueltos
- Gemini pidió permitir elegir arma, infusión y skin durante la previa: **Codex ya lo hizo** en `ShopService` (es archivo de Codex, no de Claude).
- Colores de rol: `Overhead.client` (Claude) ya lee `Roles.Data[rol].color`, que es la forma que dejó Codex.
- `Frozen` / `CanFight` durante la previa: el combate ya los respeta (`Combat`, `Directional`).

## Pedidos pendientes para Claude (de los reportes)
- `CityLife.client`: cachear `CityDressing` y no buscar durante la partida (hallazgo 9 de Codex).
- `Cinematic.client` (ronda 2): empezar solo con `MatchPhase = Cinematic` y un `PhaseEnds` válido.
- `Debug.client` (Codex): modos `DirOne`/`DirRandom` y botón `DummyDir`.
- `TouchUI` (Gemini): soltar patada → `InputBridge.press("Kick", false)`.

## Para el usuario 👤
- Subir las 8 mallas de la tanda 1 con sus texturas (lista y pasos en [[Reporte 0.2 Gemini]], sección 5, y `modelos_armas/GUIA_SUBIDA_MALLAS.md`) y pegar los IDs en `WeaponMeshes.lua`. Mientras tanto se ven las versiones por código.
- Instalar el plugin de Rojo antes de la sesión de integración.

## Orden de la sesión de integración
1. Arreglar I1 a I5 y los pedidos de arriba.
2. `check_lua` + LihFolk; Rojo o regenerar el place.
3. Probar en Studio con las listas de los tres reportes: primero `Directional.Enabled = false` (debe quedar como la 0.1 más la sensación), después `true`; 1v1 y 2v2 con varios clientes; celular y mando.
4. Commit con el resultado de las pruebas.
