# Contratos 0.2 — 10/11/2026 (Argentina, UTC-3)

Puntos de conexión nuevos entre las IA para la 0.2. Se suman a [[Contratos etapa 8]] (C0 a C15 siguen vigentes).
Quien **produce** crea el contrato y lo documenta acá con los nombres finales; quien **consume** solo lee. Los nombres de abajo son la propuesta: si el productor los cambia, actualiza esta nota en la misma entrega.

## C16. Estado direccional del personaje (produce Claude; consumen Gemini y Codex)
Atributos del Model del personaje:
- `CombatState` (string): Neutral, Windup, Active, Recovery, Guard, ParryWindow, Parried, Kick, GuardBroken, Staggered, Dodge, Downed, Carried.
- `Stance` (string): Up, Left o Right.
- `AttackDir` (string o nil): dirección del golpe en curso.
- `StateEnds` (number): `workspace:GetServerTimeNow()` en que termina el estado.

Valores en `CombatConfig.Directional` (con `Enabled`).

**Nombres finales (Claude, 10/11/2026 13:51)** ✅ en código, sin probar en Studio:
- Los cuatro atributos se publican **siempre**, aunque `Enabled` sea false (`Stance` queda en `Up` y `AttackDir` en `""`). `CombatState` se recalcula cada frame en el servidor (`ServerScriptService/Directional.lua`) a partir de `Action`, `ActionPhase`, `Blocking`, `StunnedUntil`, `KnockedDown`, etc. `Windup`/`Active`/`Recovery` solo para golpes básicos y fuertes; la patada es `Kick` de punta a punta.
- **Convención de lados:** `AttackDir` está en el marco **del atacante**. El golpe llega al defensor por el lado espejo (Left ↔ Right, Up = Up) y se bloquea poniendo la postura en ese lado. El triángulo dibuja el aviso rojo ya en el lado espejo.
- Atributos extra del personaje: `ParriedUntil`, `GuardBrokenStateUntil` (horas de servidor) y `Finisher` (bool: el golpe en curso es un remate, D4).
- Remoto `Input` (C25) y teclas del direccional en `InputMap.DirectionalDefaults`.

## C17. Fases de la partida y previa (produce Codex; consumen Claude y Gemini)
- Atributos en `workspace`: `MatchPhase` (Lobby, Prematch, Cinematic, Round, RoundEnd, Summary) y `PhaseEnds` (hora del servidor).
- La previa dura al menos 10 s (en `Economy` o un módulo de datos de partida). Durante `Prematch` cada jugador elige arma, skin e infusión con el remoto de equipar existente (C20); al pasar a `Cinematic` se bloquea la elección.
- `Cinematic` dura lo que diga `CinematicTime` (propuesta 4,5 s). Claude dibuja la cámara (`Cinematic.client`); Gemini, los carteles (`Prematch.client`).
- Orden de eliminación: el servidor guarda quién cayó y cuándo; si caen todos, gana el equipo del último en caer.

## C18. Roles (produce Codex; consumen Claude y Gemini)
- `Roles.lua`: lista de UserIds por rol, colores, prioridad y permisos (dato, no código).
- Atributo del jugador `Role` (string). El color sale de `Roles`.
- Etiqueta en el chat: Codex (`RoleService` + su script de cliente). Etiqueta sobre la cabeza: Claude, en `Overhead.client`, leyendo `Role`.

## C19. Progresión y recompensas (produce Codex; consume Gemini)
- Atributos del jugador: `Level`, `XP`, `XPNext`, `MultXP`, `MultCoins`, `MultEnds`.
- Remoto `Rewards` (RemoteFunction): acciones `GetState`, `Spin`, `OpenBox`. Responde el premio ya decidido por el servidor; la interfaz solo lo anima.
- Datos en `Progression.lua` (curva y premios por nivel) y `Rewards.lua` (tabla de premios, probabilidades visibles, premio semanal).

## C20. Armería y tienda (produce Codex el servidor; consume Gemini)
- La armería equipa con el remoto de la tienda que ya existe (`ShopService`). Si falta una acción (por ejemplo, equipar todo junto), la agrega Codex y la documenta acá.
- Las vistas previas son solo del cliente: no tocan el servidor.
- La sección «Destacado» que rota cada día la calcula el servidor a partir de la fecha (todos ven lo mismo).

## C21. Administración (produce Codex)
- Remoto `Admin` (RemoteFunction). Toda acción se valida en el servidor contra `Roles` y queda registrada (quién, a quién, qué, cuándo).
- Interfaz: `AdminPanel.client` (Codex, funcional, con `UiTheme`).

## C22. Telemetría (produce Codex; usa los eventos de Claude)
- Codex escucha `CombatEvents` (C6) y el final de cada partida para registrar arma elegida, victorias por arma y duración, con `AnalyticsService` (eventos personalizados).

## C23. Sensación de combate (produce Claude)
- Hit-stop, temblor y efectos de golpear, recibir, bloquear y parry salen del evento `Effect` de `CombatEvents`, con valores en `PolishConfig`. El HUD de Gemini puede escuchar el mismo evento para el destello de la barra.
- **Nombre final (10/11/2026 13:51)** ✅ en código: remoto `Remotes.Effect`, tipo `"Feel"`, solo al jugador involucrado: `Effect.OnClientEvent:Connect(function(kind, role, info) if kind == "Feel" then ... end end)`.
  - `role`: `Deal` (pegaste), `Take` (te pegaron), `Block` (bloqueaste), `Blocked` (te bloquearon), `Parry` (parreaste), `Parried` (te parrearon), `GuardBreak` (rompiste una guardia), `GuardBroken` (te la rompieron).
  - `info`: `{ dir = Vector3, kind = "Light"|"Heavy"|"Kick", finisher = bool, amount = número (Deal/Take), guard = 0..1 (Block: guardia que queda) }`.
  - Valores: `PolishConfig.Feel` (sonido 2D, borde de pantalla, cámara lenta) y `CombatConfig.Feel` (ritmo y tope de hit-stop). Para el HUD de Gemini: `Take` → destello de la vida; `Block` con `guard` → parpadeo de la guardia; `GuardBroken` → barra de guardia rota.

## C25. Remoto `Input` ampliado (produce Claude; revisa Codex)
- `Input:FireServer(acción, arg, extra, seq)`. `seq` es un entero creciente por cliente; el servidor descarta lo repetido o viejo. Sin `seq` (clientes viejos) se acepta igual. Límite: 30 mensajes por segundo en total y `StanceMaxRate` (15) cambios de postura por segundo.
- Acciones nuevas: `Stance` (arg = `"Up"|"Left"|"Right"`, cualquier otro valor se descarta), `KickRelease` (soltar F: patear al derribado), `GuardDown`/`GuardUp` (alias de `BlockStart`/`BlockEnd`). `Kick` con el direccional decide en el servidor: derribado cerca → esperar `LiftHold` (levantar) o `KickRelease` (patear); si no, patada normal.
- Si el servidor rechaza una postura responde `Effect:FireClient(jugador, "InputReject", seq, acción)` y el cliente vuelve a la postura real.
- Depuración: `Remotes.Debug` acción `DummyDir` (arg `"Up"|"Left"|"Right"` o nada para rotar). Modos nuevos de muñeco: `DirOne`, `DirRandom` (claves `dummy.DirOne`, `dummy.DirRandom`).

## C24. Nombre de la moneda (según D5)
- Si las monedas pasan a llamarse «almas», solo cambian los textos (claves de idioma) y el ícono. El dato guardado sigue igual. Textos: cada IA en su archivo de idioma; ícono: Gemini.
