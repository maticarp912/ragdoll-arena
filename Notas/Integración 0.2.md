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
3. ✅ (10/11 15:22, salvo lo pendiente del reporte) Probar en Studio con las listas de los tres reportes: primero `Directional.Enabled = false` (debe quedar como la 0.1 más la sensación), después `true`; 1v1 y 2v2 con varios clientes; celular y mando.
4. Commit con el resultado de las pruebas.

## Decidido por el usuario
- ✅ **Skins de la ruleta: solo ruleta** (10/11/2026, D23). El servidor rechaza su compra (`rouletteOnly`), no entran en el Destacado y la tienda las muestra con «Solo en la Ruleta». Sin probar en Studio.

## Para la ronda 2 (Codex)
- En la tienda, los multiplicadores son de muestra: «comprar» solo muestra un aviso (`LocalBoost`). Venderlos con almas de verdad va con [[Recompensas y retención 0.2]].
- La pestaña «Almas y Monedas» usa `DebugCoins` (solo depuración). Sin Robux en la 0.2 (D20): decidir si la pestaña se quita o queda solo para Tester.

## Pruebas en Studio
Prompt: [[0.2 Integración - pruebas en Studio]].
**10/11/2026 15:22:** probado en Studio, resultados en [[Reporte 0.2 Integración]]. A, B, C y la mayor parte de D ✅. Arreglados: Destacado del servidor, clave `rotateHint`, campos del panel de administración, Owner de prueba en Studio y tamaño del triángulo. Pendiente: stick, fijado permanente con el direccional, ping simulado, Maza/Estoque y 2v2.

## Combate direccional activado
**10/11/2026 20:40:** el usuario pidió activarlo. `CombatConfig.Directional.Enabled = true` (antes la regla era dejarlo en false). Place regenerado. Falta probar en partida: stick del mando, fijado permanente (T / R3), margen de ping del parry, Maza (arriba imbloqueable), Estoque y 2v2.

## Pedidos del 10/11 a la noche (Claude, 22:50)

Implementado, **sin probar en Studio**:
- **Skins de la 0.1 de vuelta.** `SkinDesigns.lua` vuelve a ser el de la 0.1 (commit 1e3a189). La versión «con rayos» de Gemini quedó entera en `SkinDesignsStorm.lua`; de ahí se toman solo los cinco del Eclipse Carmesí: Filo (espada), Mandoble (espadón), Quebrantahuesos (maza) y dos nuevos con el mismo concepto, **Colmillos del Eclipse Carmesí** (dagas) y **Aguja del Eclipse Carmesí** (estoque), los cinco de la ruleta y en `Rewards.WeeklySkins`. `Skins.WeeklyPool` lista las 36 versiones con rayos como candidatas a semanal (sin activar). El bisel `Edge` por defecto volvió al metal de la 0.1.
- **Ojo con las mallas de Blender:** la tanda 1 se hizo con los diseños con rayos. Solo siguen valiendo las de los tres Eclipse y las armas base; las demás ahora corresponden a las candidatas semanales. No conviene subirlas para las skins de la tienda.
- **Vista previa de auras:** la tienda llamaba a `AuraFx.preview` y `AuraFx.clearPreview`, que no existen, y el pedestal estaba a 450 studs bajo tierra. Ahora hay un botón «Probar en mi personaje»: se esconde la tienda, la aura aparece sobre tu personaje (o sobre un arma de muestra si no tenés una en la mano) con la cámara de frente 4 s y la tienda vuelve.
- **Ceniza que «duplicaba»:** la pestaña Almas no es una compra, es la herramienta de prueba `DebugCoins` (suma almas gratis) y además los montos no coincidían (decía +500 y daba 1000; +2000 no existía; +5000 daba 10000). Ahora dice «Prueba: +N almas gratis», los montos coinciden (`Economy.DebugAmounts`) y la pestaña solo aparece si el servidor dice que podés depurar.
- **Patada al derribado:** `DownedPushSpeed` 16 → 32 y `DownedPushUp` 4 → 7 (objetivo ~5 studs). Calibrar.
- **Dash:** ya no suena `swing_pesado_2`; ahora es un whoosh corto de la librería, más grave y suave (`Assets` Dodge).
- **Golpe según la dirección:** con el direccional, el básico usa el clip cuyo recorrido coincide con la dirección (`AnimClips.DirMap`, claves `Weapons.<arma>.DirUp/DirLeft/DirRight`). El sentido de las capturas se midió por el giro de cintura entre la carga y el impacto; si alguna se ve al revés, se cambia en `DirMap`. El estoque son estocadas: inclina con la capa direccional. El fuerte sigue con su clip y la capa.
- **Espadón y maza:** más rápidos (espadón 0,92 → 0,78 s, impacto 0,50 → 0,40; maza 1,00 → 0,84, impacto 0,56 → 0,44; fuertes con menos preparación) y **contragolpe de peso** (`WeaponData.riposte`): bloquear un básico traba 0,35 s al atacante (se le corta el combo) y tu próximo básico en 0,8 s sale 40 % más rápido, con hiperarmadura y ×1,5 de daño. Arreglado de paso: el `knockback = 36` del fuerte de la maza había quedado dentro de un comentario.
- **Suspenso de recompensas y tiros pagos:** lo está haciendo Codex (gpt-6.1-sol, high) con [[0.2 Suspenso de recompensas - Codex]].

Para probar: los tres sentidos con cada arma (que el tajo vaya hacia donde apunta el triángulo), el contragolpe contra alguien que spamea dagas o espada, la patada al derribado, «Probar» en una aura de cuerpo y en una de arma, la pestaña Almas con y sin rol de depuración, y las cinco skins del Eclipse.
- **Subirse encima del rival (23:20):** el paso del golpe y el dash ahora frenan a `CombatConfig.Spacing.MinGap` (3,2 studs) del otro, y si igual quedás parado sobre un personaje, `Controls.client` te desliza hacia afuera y hacia abajo. Guía para el usuario: [[0.2 Guía de pruebas - usuario]].

## Pedidos del 10/11, 23:59 (Claude)
Implementado, **sin probar en Studio**:
- **Tirones en la tienda y el mouse:** la tienda, la armería y las recompensas eran CanvasGroup con vistas 3D girando adentro, y cada vista que giraba obligaba a redibujar toda la ventana en cada frame. Ahora son Frame (se abren con un deslizamiento, sin fundido). Las tarjetas de la tienda y las miniaturas de la armería quedan quietas; solo gira la vista grande. De paso, las miniaturas de la armería ya no quedan de punta.
- **Cajas de Tormenta:** las 36 skins con rayos vuelven como `<id>Storm` (`Skins.lua`, generadas desde `Skins.WeeklyPool`) y solo salen de tres cajas nuevas:

  | Caja | Precio | Rara | Épica | Legendaria |
  |---|---|---|---|---|
  | Cofre de la Tormenta | 3000 | 72 % | 24 % | 4 % |
  | Arca de la Tormenta | 6500 | 30 % | 55 % | 15 % |
  | Relicario del Rayo | 12000 | — | 62 % | 38 % |

  La rareza de cada skin sale del precio de su original: hasta 1500 = Rara (7 skins), hasta 3100 = Épica (16), más = Legendaria (13). No se compran en la tienda y solo aparecen en la armería y la tienda si ya las tenés. La Reliquia ya no puede dar skins de Tormenta. Nombres: «<original> de Tormenta» / «Storm …» / «… da Tempestade».
- **Tipografía:** títulos en Grenze Gotisch (gótica), textos en Merriweather (serif clásica) y números en Builder Sans. Se cambia en un solo lugar: `UiTheme.Fonts`, `UiTheme.FontFaces` y `Theme.Fonts`. Si una fuente no existiera, cae sola a la anterior. Ojo: Merriweather es más ancha que Gotham y puede que algún texto quede cortado; avisar dónde.
- **Para Codex:** revisión de las cajas, la colección y sus pendientes en [[0.2 Revisión final - Codex]] (la manda el usuario).
