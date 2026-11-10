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

## C24. Nombre de la moneda (según D5)
- Si las monedas pasan a llamarse «almas», solo cambian los textos (claves de idioma) y el ícono. El dato guardado sigue igual. Textos: cada IA en su archivo de idioma; ícono: Gemini.
