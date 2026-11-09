# Tareas de Codex — etapa 8

> Este archivo **es el prompt completo** para Codex. Sesión larga: trabajá por fases, en orden, y reportá al terminar cada fase.
>
> **Cambio del 9/11 (créditos de Codex al 65 %)**: fases 1 y 2 hechas. Orden nuevo: primero los dos arreglos de `MatchService` (doble cola y mensajes traducidos), después la fase 3 (auras). **Las arenas (fase 4, puntos 1 a 3) pasan a Claude**, junto con `ArenaBuilder.lua`, `ArenaConfig.lua`, `Arena.client.lua` y `ArenaBackdrop.client.lua`: no los toques. Actualizá tu reporte después de cada paso para que, si te quedás sin créditos, Claude sepa exactamente dónde seguir.

## Quién sos y con quién trabajás
Sos una de tres IA trabajando **al mismo tiempo** sobre la misma carpeta:
- **Claude** coordina e integra: combate, animaciones, ciudad, cielo, sonido y pruebas en Studio. Es el único que regenera el place.
- **Gemini**: interfaz completa (diseño profesional) y modelos de armas.
- **Vos (Codex)**: economía (estadísticas, monedas, misiones, tablas de clasificación), compras y guardado, auras (datos, efectos y servidor), partidas y **arenas** (varias arenas, peligros en el vacío y el bug negro del derrumbe).

Cada archivo tiene **un solo responsable**. Tocá solo los tuyos.

## Proyecto
- Carpeta: `F:\RobloxJuegos\Plataforme 2v2`. Juego: **Ragdoll Arena**, PvP 1v1/2v2 en Roblox **R15** con ragdoll, cinco armas (Espada, Espadón, Dagas, Estoque, Maza), skins cosméticas por arma, cuatro infusiones (Fuego, Rayo, Hielo, Sombra) y estética **dark fantasy**.
- Vault de Obsidian con todo el contexto: `Notas/`. Leé primero:
  - `Notas/00 Inicio.md`, `Notas/Estado.md` y `Notas/Decisiones.md`.
  - `Notas/Reparto etapa 8.md`: quién hace qué.
  - `Notas/Contratos etapa 8.md`: **obligatorio**, son los puntos de conexión con las otras IA.
  - `Notas/Equilibrio de armas.md`.
- Referencias visuales: `referencias\`. Para arenas: `04_arena_plataforma_flotante.webp` (la actual: plataforma flotante en pirámide invertida en un bosque con niebla), `arena 2.jpg` (coliseo en un cañón con púas), `arena 3.jpg` (templo de columnas doradas con jeroglíficos sobre agua oscura), `mano como arena 4.jpg` (mano gigante de piedra con cascadas y una cabeza de estatua). Para la tienda y el estilo: `08_tienda_ejemplo.webp`, `06_inventario_ejemplo.webp`, `infusiones ref2.jpg`.
- `auras armas y personas..png` está **en blanco**: diseñá las auras con criterio propio.
- Los lotes 5 y 6 que tenías asignados antes **ya los hizo Claude**: no los repitas.
- Generación y chequeo: `node tools/check_lua.js .` (podés usarlo; solo lee). `node tools/make_rbxlx.js` **no**: lo corre Claude.
- Regla del proyecto: los valores numéricos van en módulos de datos, no sueltos en la lógica.

## Reglas
1. **Solo tus archivos**. Si necesitás un cambio en otro, pedilo en tu reporte, en «Pedidos a otros», con el cambio exacto.
2. **No regeneres** `Ragdoll Arena.rbxlx`. No copies desde backups ni desde otras carpetas.
3. Texto visible nuevo en `ReplicatedStorage/LocaleCodex.lua`, con las **mismas claves en ES, EN y PT-BR**. Sin repetir claves de `LocaleES/EN/PT.lua`.
4. No inventes IDs de Roblox. Producto sin crear = `productId = 0`.
5. Probablemente no puedas abrir Studio: separá **implementado**, **comprobado** (y cómo) y **pendiente de probar en Studio**. No marques como probado algo que solo pasó `check_lua`.
6. Tu reporte va en el vault: `Notas/Reporte Codex etapa 8.md` (es tuyo). Actualizalo al terminar cada fase.

## Archivos exclusivos tuyos
| Archivo | |
|---|---|
| `ServerScriptService/PlayerData.lua` | existente |
| `ServerScriptService/ShopService.server.lua` | existente (incluye `Remotes.Settings`) |
| `ServerScriptService/MatchService.server.lua` | existente |
| `ServerScriptService/ArenaBuilder.lua` | existente |
| `ReplicatedStorage/ArenaConfig.lua` | existente |
| `StarterPlayer/StarterPlayerScripts/Arena.client.lua` | existente (rocas flotantes; las estrellas pasaron a `Sky.client` de Claude) |
| `StarterPlayer/StarterPlayerScripts/ArenaBackdrop.client.lua` | existente (Claude lo separó de `Lobby.client`: abismo, niebla, rocas, ceniza, escombros, desenfoque) |
| `StarterPlayer/StarterPlayerScripts/Debug.client.lua` | existente (menú P) |
| `ServerScriptService/StatsService.lua`, `MissionService.lua`, `LeaderboardService.lua` | **nuevos** (nombres sugeridos; podés organizarlos distinto) |
| `ReplicatedStorage/Economy.lua`, `Missions.lua`, `Auras.lua`, `AuraFx.lua` | **nuevos** |
| `StarterPlayer/StarterPlayerScripts/Auras.client.lua` | **nuevo** |
| `ReplicatedStorage/LocaleCodex.lua` | creado vacío por Claude; ahora es tuyo |
| `Notas/Reporte Codex etapa 8.md` | **nuevo** |

**Solo lectura**: todo lo demás, en especial `Theme.lua`, `Skins.lua`, `WeaponBuilder.lua`, `Combat.lua`, `CombatEvents.lua`, `CombatConfig.lua`, `WeaponData.lua`, `Localization.lua`, `Remotes.lua`, `LobbyBuilder.lua`, `Shop.client.lua`, `HUD.client.lua` y `LobbyUI.client.lua` (los dos últimos son de Gemini).
**No toques `Shop.client.lua`**: ahora es de Gemini. Tu parte de la tienda es servidor, datos y efectos; Gemini dibuja la pestaña de Auras usando tus contratos (C11).

## Fase 1 — Datos, guardado y compras
1. **Guardado confiable** (`PlayerData`):
   - `save` devuelve `true`/`false`.
   - Usá `UpdateAsync`, con un bloqueo de sesión simple para que dos servidores no se pisen.
   - Guardá también en Studio al cerrar, si la API está activa.
   - Datos viejos (sin los campos nuevos) cargan sin errores.
2. **Recibos de Robux** (`ShopService`):
   - Conceder, guardar y devolver `PurchaseGranted` solo si el guardado salió bien. Si falla, deshacer en memoria y devolver `NotProcessedYet`.
   - Registrar los `PurchaseId` procesados (lista acotada) para no conceder dos veces.
   - Sirve para skins y auras.
   - Gemini va a crear la skin de Robux `Requiem` con `productId = 0`. No hace falta conocerla: alcanza con leer `productId`.
3. **Monedas desde depuración** (menú P, `Debug.client`):
   - Botones +1.000 y +10.000 monedas, y «Quitar compras de prueba» (borra skins y auras compradas, deja `Default`).
   - Validá en el servidor con `canDebug` de `ShopService` (Studio, creador o `CombatConfig.Debug.AllowedUserIds`). Las cantidades salen de una lista fija del servidor.
   - Objetivo: probar compra, confirmación, equipamiento y persistencia (salir y volver a entrar).
4. **Opciones** (C10): `GetOptions` / `SetOptions` validadas y guardadas; atributos `OptMusic`, `OptSfx`, `OptShake`, `OptUiScale`.

## Fase 2 — Economía, estadísticas, misiones y tablas de clasificación
1. **Estadísticas**: escuchá `CombatEvents` (C6) y `MatchService`. Contá solo en partida: victorias, partidas, eliminaciones y derribos. Guardalas y publicalas como atributos (C7).
2. **Monedas**:
   - Hoy se dan `ArenaConfig.Match.WinCoins = 50` al ganar y `LoseCoins = 15` al perder.
   - Pasá la economía a `Economy.lua` y proponé valores: monedas por victoria, por eliminación y por derribo (con tope por partida), y bonificación por primera victoria del día.
   - Que una skin Epic (2.800–4.000) cueste unas 10–15 partidas ganadas con misiones. Explicá la cuenta en el reporte.
3. **Misiones diarias** (C8):
   - 3 por día, sacadas de un catálogo de ~10. Por ejemplo: «gana 2 partidas», «derriba a 5 rivales», «haz 3 parrys», «rompe 4 guardias», «lanza a 3 rivales», «juega 3 partidas con el Espadón».
   - Se reinician a las 00:00 UTC y se reclaman a mano.
   - Las recompensas van en `Missions.lua` o `Economy.lua`.
4. **Tablas de clasificación** (C7):
   - Victorias, eliminaciones, derribos y monedas, con OrderedDataStore y el top 10 publicado en `ReplicatedStorage.Leaderboards`.
   - Para «monedas», recomiendo el **total ganado histórico** (no el saldo, que baja al comprar). Decidilo y documentalo.
   - En Studio sin API, usar los jugadores del servidor.
5. **Fin de partida y avisos** (C9): `MatchSummary`, `KillFeed` y el atributo `Eliminated`.
6. **Clasificatorias**: todavía **no** se implementan. Solo dejá en `Economy.lua` un lugar comentado para el futuro (sin lógica). La pestaña «Próximamente» la hace Gemini.

## Fase 3 — Auras
Auras cosméticas oscuras, de **formas y movimientos distintos** (no el mismo efecto con otro color).
- **Catálogo** (`Auras.lua`, C11): unas **10 auras, 6 de cuerpo y 4 de arma**.
  - Cuerpo: corona de ceniza flotante, cadenas espectrales que orbitan, alas de humo, sudario de niebla a los pies, ojos que se abren alrededor, runas que giran.
  - Arma: humo que gotea del filo, brasas negras, sangre que cae de la punta, grietas de luz pálida.
  - Precios en monedas: Rare 1.500–2.500, Epic 3.500–5.000, Legendary 7.000–9.000. Una o dos Legendary de Robux con `productId = 0`.
- **Efectos** (`AuraFx.lua` + `Auras.client.lua`): se dibujan las auras de todos los jugadores a partir de `EquippedAura` y se rehacen al cambiar de personaje, arma o skin. Las de arma siguen `BladeBase`→`BladeTip` y también la daga de la mano izquierda (`OffhandWeapon`).
- **Distintas de las infusiones**: las infusiones son elementales, saturadas y usan `Highlight`. Las auras **no usan `Highlight`** (Roblox permite 31 activos y ya se usan), no tiñen el arma, son de baja intensidad, desaturadas y con un solo acento.
- **Lectura del combate**:
  - Con `Telegraph ~= ""`, el aura de arma baja a ≤ 25 % y la de cuerpo a ≤ 50 %.
  - Con `InfusionActive`, el aura de arma se apaga.
  - Con ragdoll o cargado, se simplifica.
- **Rendimiento** (por personaje):
  - Cuerpo: ≤ 3 emisores y ≤ 40 partículas/s en total.
  - Arma: ≤ 2 emisores (más `Beam`/`Trail`).
  - Sin `PointLight`, salvo una tenue en Legendary.
  - Todo dentro de la carpeta `CosmeticAura`. En partida, las auras de los demás a ~60 %.
- **Servidor**: `BuyAura`, `EquipAura` y `UnequipAura` validados (existe, la tiene, alcanzan las monedas; bloqueado en partida como las skins). En `PlayerData`: `OwnedAuras` y `EquippedAura`.
- **Vista previa**: `AuraFx.attach(..., { preview = true })` tiene que funcionar sobre un maniquí o un modelo de arma en el mundo. Las partículas no se ven en ViewportFrame; Gemini arma el pedestal de la tienda con esta función.

## Fase 4 — Arenas
1. **Bug negro bajo la arena en el derrumbe**: al caerse las baldosas queda algo negro debajo. Buscá la causa. Candidatos:
   - el suelo del abismo de `ArenaBackdrop.client` (`Theme.Ambience.Arena.AbyssDepth` 260, basalto oscuro);
   - las capas de la base en pirámide (`ArenaConfig.BaseLayers`);
   - piezas de baldosa que no se ocultan;
   - la lava (`LavaDepth` 110).
   Arreglalo y explicá la causa.
2. **Peligros en el vacío**:
   - El vacío se ve vacío. Hoy hay lava a 110 studs de profundidad.
   - Agregá peligros visibles y temáticos según la arena: púas, lava, agua oscura con formas, raíces o estacas.
   - Morir al caer tiene que seguir igual; el peligro es visual o acelera la muerte, sin castigos nuevos raros.
3. **Más arenas**:
   - Hoy hay una por modo (`ArenaConfig.Modes`). Armá un sistema de **variantes de arena** y al menos **3 arenas nuevas** inspiradas en las referencias, además de la actual: coliseo del cañón con púas, templo dorado sobre agua oscura y mano de piedra con cascadas.
   - `MatchService` elige una al azar (o en rotación) por partida, en ambos modos.
   - Cada arena conserva la mecánica de derrumbe por baldosas, el centro, los puntos de aparición, la lectura del suelo y buena visibilidad desde la cámara en picada (`CombatConfig.Camera`: distancia 15, picada 24°).
   - Presupuesto: ≤ 2.500 piezas por arena, luces contadas y partículas moderadas. Los adornos lejanos no colisionan (`CanCollide`, `CanQuery` y `CanTouch` en false).
   - Lo ambiental de cada arena (niebla, desenfoque, partículas) va en tus scripts de cliente, con efectos propios `Arena*` en `Lighting` (C14). No toques `Atmosphere.client` ni `Sky.client`.
4. **Arreglos técnicos** (verificados por Claude en el código, siguen vigentes):
   - **Doble cola** (`MatchService`): quien está en un círculo y además apretó el botón de otro modo queda en las dos listas. Regla: el círculo manda, y al entrar a un círculo se borra la petición del botón.
   - **Mensajes sin traducir**: ronda, espera, victoria, «¡Gana el equipo %s!» y antesala. Pasalos a `StatusKey`/`StatusParams` (C2), con claves en `LocaleCodex` (incluidas `team.Red` y `team.Blue`), y dejá de escribir texto en `Status`.
   - **Recibo de Robux**: resuelto en la fase 1.
   - El cuarto punto (mando en la confirmación de compra) ahora es de Gemini.

## Criterio de terminado
- `node tools/check_lua.js .` da OK.
- `LocaleCodex` tiene las mismas claves en los tres idiomas.
- Cada contrato que producís (C2, C3, C7, C8, C9, C10, C11) funciona tal como está escrito en `Notas/Contratos etapa 8.md`.
- `Notas/Reporte Codex etapa 8.md` incluye:
  - archivos cambiados y qué hace cada cambio;
  - implementado / comprobado / pendiente de Studio;
  - la **lista de pruebas** que Claude tiene que hacer en Studio;
  - valores de economía elegidos y su justificación;
  - «Pedidos a otros».


---

# Ronda 2 de Codex (9/11, tras el reinicio de créditos)

Las fases 1–3 y los arreglos de cola y mensajes ya están hechos (ver [[Reporte Codex etapa 8]]). Claude revisó y retocó: reintentos al cargar el perfil (`PlayerData`) y auras más visibles (`Auras.lua`, `AuraFx.lua`). Partí de esos archivos tal como están.

## Archivos exclusivos en esta ronda
| Archivo | |
|---|---|
| `ServerScriptService/ArenaBuilder.lua` | existente |
| `ReplicatedStorage/ArenaConfig.lua` | existente |
| `StarterPlayer/StarterPlayerScripts/Arena.client.lua` | existente (rocas flotantes) |
| `StarterPlayer/StarterPlayerScripts/ArenaBackdrop.client.lua` | existente (abismo, niebla, rocas, ceniza, desenfoque) |
| `ServerScriptService/MatchService.server.lua` | vuelve a ser tuyo: solo para elegir la arena de cada partida |
| `ReplicatedStorage/LocaleCodex.lua` | vuelve a ser tuyo (nombres de arenas si los mostrás) |
| `Notas/Reporte Codex etapa 8.md` | agregá una sección «Ronda 2» |

**No toques** nada más; en especial `WeaponBuilder`, `SkinDesigns`, `Skins` y toda la interfaz (`Shop`, `HUD`, `LobbyUI`, `Settings`, `TouchUI`, `MatchUI`, `Leaderboards`, `UiTheme`): son de Gemini y está trabajando ahora. `Atmosphere.client`, `Sky.client`, `LobbyBuilder`, `Combat`, `Controls` y `Animator` son de Claude.

## Tarea A — Arenas (la fase 4 original, puntos 1 a 3)
1. **Bug negro bajo la arena en el derrumbe**: al caerse baldosas queda algo negro debajo. Candidatos: el suelo del abismo de `ArenaBackdrop.client` (`Theme.Ambience.Arena.AbyssDepth` 260, basalto oscuro), las capas de la pirámide (`ArenaConfig.BaseLayers`), piezas que no se ocultan, la lava (`LavaDepth` 110). Encontrá la causa, arreglala y explicala.
   - Claude además detectó que las caras inferiores de las baldosas de la arena 1v1 coinciden en el mismo plano (parpadeo visto desde abajo al caer): separalas.
2. **Peligros en el vacío**: púas, lava, agua oscura, raíces o estacas según la arena. Morir al caer sigue igual.
3. **Más arenas**: sistema de variantes y al menos 3 arenas nuevas, además de la actual, inspiradas en `referenciasarena 2.jpg` (coliseo en un cañón con púas), `referenciasarena 3.jpg` (templo de columnas doradas con jeroglíficos sobre agua oscura) y `referenciasmano como arena 4.jpg` (mano gigante de piedra con cascadas y cabeza de estatua). `MatchService` elige una al azar o en rotación, en 1v1 y 2v2.
   - Cada arena conserva: derrumbe por baldosas, centro, puntos de aparición, lectura clara del suelo y buena visibilidad con la cámara en picada (`CombatConfig.Camera`: distancia 15, picada 24°).
   - Presupuesto: ≤ 2.500 piezas por arena; adornos lejanos sin colisión (`CanCollide`, `CanQuery`, `CanTouch` en false); luces y partículas moderadas.
   - Ambiente propio de cada arena en tus scripts de cliente, con efectos `Arena*` en `Lighting` activos solo con `InMatch` (no toques `Atmosphere.client` ni `Sky.client`). La iluminación global de noche bajó un 25 % el 9/11: que el suelo de la arena se siga leyendo bien.
   - Evitá caras coplanares superpuestas (z-fighting): Claude encontró varias en la ciudad.

## Tarea B — Revisión del trabajo de Gemini (solo lectura)
Si te quedan créditos después de la tarea A: leé los archivos de interfaz de Gemini y anotá en tu reporte los problemas que encuentres (no los edites). Comprobá sobre todo:
- Que respeten los contratos de [[Contratos etapa 8]]: C2 (`StatusKey`/`StatusParams`), C3 (cola), C7 (tablas), C8 (misiones: `Get`/`Claim`), C9 (`MatchSummary`, `KillFeed`), C10 (opciones), C11 (acciones `BuyAura`/`EquipAura`/`UnequipAura`, `AuraFx.attach` en el mundo) y C12 (`InputBridge`).
- Que no se rompan si falta un módulo, que todo texto use `Localization`, y la navegación con mando (foco inicial, B para volver, selección encerrada en los diálogos).
- Que `TouchUI` oculte los botones cuando hay un mando en uso (el beta tester juega en celular con mando).

## Reglas
Iguales que antes: no regeneres `Ragdoll Arena.rbxlx`, `node tools/check_lua.js .` tiene que dar OK, separá implementado / comprobado / pendiente de Studio, y actualizá el reporte después de cada paso por si te quedás sin créditos.
