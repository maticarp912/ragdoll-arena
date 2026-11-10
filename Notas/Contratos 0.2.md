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
- Atributos en `workspace`: `MatchPhase` (Lobby, Prematch, Cinematic, Round, RoundEnd, Summary) y `PhaseEnds` (hora del servidor). **También en cada jugador de la partida** (integración, 10/11/2026): los clientes leen primero `player:GetAttribute("MatchPhase")` y `PhaseEnds`; `workspace` es respaldo.
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

### C19 — ronda 2, Codex, 10/11/2026 18:11 (Argentina, UTC-3)
🟡 API implementada; falta ejecutar en Studio. Esta sección reemplaza el anuncio de ronda 1 que decía que Rewards todavía no existía.
- `Remotes.Rewards` es RemoteFunction. Firma: `InvokeServer(action, id?, source?, requestId?)` → `ok, result`. Error: `false,{key}`. Límite global por jugador: `Rewards.Interval` (0,35 s). No enviar tablas, precios, premios, UserIds ni cantidades desde el cliente.
- `GetState` sin argumentos adicionales → `true,state`. Campos: `souls`, `resetAt`, `weekResetAt`, `weeklySkin`, `roulette` (8 sectores con `index`, `kind`, `rarity`, `probability`, `effectiveProbability` e `id` para skin semanal), `spinPity`, `spinGuarantee`, `freeSpin`, `spins` (tickets), `paidSpins`, `paidSpinPrice` (nil al agotar 3), `relicPity`, `relicGuarantee`, `boxes`, `boosts`, `streak`, `weekly`, `starter`, `tutorial`, `firstSteps`, `returnNotice`, `collection`, `mastery`, `notifications`, `nextRequest`.
- `Spin`, id = `Free|Ticket|Paid|Tutorial`. Sin id elige Tutorial disponible, después Free, después Ticket; **nunca gasta almas automáticamente**. Paid cuesta 250/500/1000, máximo 3 al día. Devuelve `{key,sector,reward,bonus?,mode,nextRequest}`. La tirada especial del tutorial da XP ×2 por 1800 s, incluso si coincide con la garantía del gran premio. Tras 30 fallos, la siguiente tirada da la skin semanal; tenerla la convierte en almas.
- `BuyBox`, id `Souls|Relic`: compra una caja y la guarda. `OpenBox`, mismo id, source `Owned` (por defecto) o `Buy` (paga y abre en la misma operación). Devuelve `{key,reward,box,nextRequest}`. No comprar implícitamente al quedarse sin cajas. La décima Reliquia sin épica o mejor la garantiza; un duplicado sigue contando como el resultado de esa rareza y paga 40 % del precio de catálogo.
- `ChooseStarter`, id `Charcoal|Frost|Gold`, una sola vez. `SkipTutorial` habilita la tirada especial sin cobrar los pasos omitidos. Sin id: `ClaimStreak`, `ClaimWeekly`, `ClaimFirstSteps`, `DismissReturn`. Reclamos repetidos no pagan. La racha se pausa si faltan días; tiene indicador de gracia semanal, nunca borra días ganados. Administración asigna el cursor sin cobrar días retroactivos ni limpiar el reclamo de hoy.
- `reward.kind` = `Souls|XP|Boost|Box|Skin`; Boost lleva `stat=XP|Coins`, `multiplier`, `seconds`; Skin lleva `id`; duplicados llevan `duplicate=<skinId>` y `kind=Souls,amount`. `boxes[id]` tiene `count`, `price`, `nameKey`, `probabilities`, `guaranteed`; Reliquias expone también skins por rareza y probabilidad por skin. Las probabilidades de la próxima caja ya incluyen su garantía.
- `streak={day,canClaim,rewards,graceAvailable,paused}`; `weekly={event,nameKey,goal,progress,claimed}`; `starter={chosen,choices}`; `tutorial={completed,steps,skipped,spinAvailable}` (`steps` usa claves string `"1".."3"`); `firstSteps={list,canClaim,claimed,skin}`; `collection[weapon]={owned,total,percent,aura,claimed,skins={{id,owned}...}}`; `notifications={spin,streak,weekly,firstSteps}`.
- `RewardsChanged` RemoteEvent sin argumentos: invalidar caché y refrescar respetando el límite. `RewardAnnouncement` RemoteEvent: `{key,params={name,prizeKey},reward}`, resultado armado por el servidor para premios legendarios reales; usar Localization.format, sin otro OnIncomingMessage.
- Reintentos opcionales: usar `state.nextRequest` como `requestId` (string secuencial, no UUID). El último pedido exitoso con esa clave devuelve el mismo resultado; claves anteriores se rechazan. Cada mutación exitosa devuelve el próximo `nextRequest`; sin clave sigue siendo compatible, con límites y reclamos únicos. No repetir una compra como operación nueva ante una respuesta incierta.
- `MatchSummary.progression` conserva XP/niveles y suma `eligible`, `reasonKey` si AFK, `mastery`, `rewards={firstMatchSouls,mastery,firstSteps,weekly,collection}`. `coins.bonus` y `coins.total` incluyen el bonus de primera partida. Solo participación válida avanza misiones, semanal, primeros pasos y maestría. Los multiplicadores corren con personaje vivo, sin congelar, habilitado para combatir en Round; pausan en lobby, previa, cinemática, entre rondas, eliminado y desconectado.
- **Claude, tutorial:** API exclusivamente servidor `RewardService.tutorial(player,1|2|3)`; o `CombatEvents.fire("TutorialStep",player.Character,nil,{step=1|2|3})` tras validar cada paso real. No hay remoto de «completé el tutorial». Cada paso paga 100 almas una vez. El Tutorial.client actual es local y todavía no produce estas pruebas; conectar desde el servidor. Los pasos deben corresponder al diseño de [[Recompensas y retención 0.2]].
- **C20 tienda:** `Shop:GetBoosts` sin id → `true,{items,order,debugSouls,collectionAuras}`; `BuyBoost`, id `Boost2xCoins|Boost2xXp|BoostSoulMagnet`, descuenta almas y activa el boost. Datos y textos en Rewards/LocaleCodex. La pestaña «Almas y Monedas» es solo depuración, visible si `debugSouls=true`; `DebugCoins` sigue comprobando permisos en servidor. Las auras de `collectionAuras` son premios de colección, no compras nuevas; las ya compradas se conservan. D23 mantiene las tres skins de ruleta fuera de Buy/Destacado. Gemini debe reemplazar `LocalBoost` por `BuyBoost` y usar estos datos.
- **C21 administración:** agrega `BoxRelic|BoxSouls|Spins`, valor entero 1..100, y `Streak`, valor 1..7; `Box` queda como alias de BoxRelic. Mismos permisos, jerarquía, cuota de acciones y AdminAudit que los regalos existentes.
- **C8 misiones:** cada reclamo diario agrega un ticket, además de almas y XP. La lista suma `spins`, el mensaje `cx.mission.claimed` usa `{amount,spins}`.

**Ampliación, Codex, 10/11/2026 18:20 (Argentina, UTC-3):** `roulette[i].tutorialProbability` muestra la distribución del giro especial (100 % en el sector ×2, salvo garantía semanal, que además da el boost). Los otros giros usan `effectiveProbability`; `probability` conserva la distribución normal. Nuevas misiones `kicks` (patadas que hacen daño durante Action=Kick) y `ringouts` (caída bajo voidY, crédito C6). MatchService produce `CombatEvents.fire("RingOut",ultimoAtacante,personaje)` una sola vez por caída. No se cambió CombatEvents/Actions. Las patadas a derribados sin daño requieren que Claude publique el evento correspondiente si deben contar para la misión.

**C10/D17 — guardado táctil, Codex, 10/11/2026 18:20 (Argentina, UTC-3):** `Settings:GetTouchLayout` → tabla `{[actionId]={x,y,scale}}`. `SetTouchLayout`, esa misma tabla, → copia normalizada o nil si es inválida/limitada/sin perfil. `{}` restablece posiciones. Solo ids de `Economy.TouchLayout.Actions`, máximo 11 botones, exactamente x/y/scale finitos dentro de los límites de Economy; nada de JSON enviado por cliente. Guarda en PlayerData, publica `TouchLayoutJson` desde el servidor y agrupa las escrituras con saveSoon. Settings limita cada acción conocida por separado (0,25 s), sin colisionar GetBinds/GetOptions al iniciar. Gemini debe llamar estos métodos y escuchar el atributo al cargar el perfil; cambiar un atributo solo desde el cliente no persiste el diseño.

**Ajuste de integración, Codex, 10/11/2026 18:25 (Argentina, UTC-3):** `firstSteps.list[].id` usa `Match|Win|Parry|Equip|Spin|OpenBox|Level`, compatible con los textos actuales de Gemini; `nameKey` sigue disponible en LocaleCodex. Los ids guardados de esos contadores son internos y no se renombraron. RewardsChanged agrupa cambios y espera al vencimiento del límite de Rewards antes de avisar, para que el refresco posterior a un reclamo no sea descartado por frecuencia. El cliente también debe espaciar sus pedidos y manejar `cx.shop.wait`; puede usar `nextRequest` para compras cuyo resultado sea incierto.

**Desglose de nivel, Codex, 10/11/2026 18:28 (Argentina, UTC-3):** `ProgressionService.grant` mantiene sus dos retornos y suma un tercero `{souls,boxes,titles}` (boxes = cantidad de Reliquias, titles = claves de idioma). `MatchSummary.progression` añade `levels` y `levelRewards`; `coins.levels` contiene las almas de niveles y `coins.total` suma partida + bonus inicial + niveles. Un premio XP de Rewards también devuelve `earned`, `levels`, `levelRewards` cuando corresponda. Así el total mostrado coincide con las almas otorgadas en la liquidación, sin pagar otra vez desde el cliente.

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


## Nombres finales de Codex, ronda 1 — 10/11/2026 14:11 (Argentina, UTC-3)
- **C17:** workspace MatchPhase/PhaseEnds; jugador MatchPhase solo para participantes. Estados Lobby → Prematch (Economy.PrematchTime, mínimo 10 s) → Cinematic (4,5 s tras cargar personajes) → Round → RoundEnd → Summary → Lobby. La selección se bloquea antes del primer spawn de arena. El countdown existente sigue después de Cinematic. Un servidor corre una partida a la vez, como en 0.1. El doble KO se resuelve por la última eliminación; cruce del vacío interpolado por frame y UserId mayor si los tiempos son exactamente iguales. No es tiempo informado por cliente.
- **C18:** Roles.Data[rol] = {priority,color,ids,names,permissions}; atributos Role, AllCosmetics, AdminAllowed, ModerateAllowed, DebugAllowed. RoleService.has(player,permission), refresh(player). Owner solo por creador de tipo User. Tester se resuelve desde mateodoupa en servidor. Chat: AdminPanel.client es el único dueño nuevo de TextChatService.OnIncomingMessage. Owner tiene propiedad efectiva, sin llenar inventarios guardados. Las armas de la beta ya eran accesibles a todos: se conserva eso.
- **C19:** Level=1..100, XP es progreso dentro del nivel, XPNext=0 al máximo; MultXP/MultCoins, MultRemaining (segundos de partida restantes), MultEnds=proyección de hora de servidor solo durante Round, 0 fuera. Boosts separados para XP y Coins; no apilar potencia, sumar tiempo con tope. ProgressionService.grant(player,baseXP), source(player,Match|Win|Kill|Mission), boost(player,XP|Coins,multiplier,seconds), setLevel(player,level). Premios de nivel: almas, Boxes.Relic y Titles (claves de idioma) en perfil. Asignación administrativa no cobra premios de niveles. MatchSummary añade progression={xp,xpBefore,xpAfter,levelBefore,level,xpNext}. Rewards RemoteFunction y RewardService se entregan en ronda 2; no esperar esos remotos todavía.
- **C20:** Shop RemoteFunction mantiene SelectWeapon,SelectInfusion,Equip,EquipAura,UnequipAura. Se admiten durante Prematch y se rechazan desde Cinematic, incluso entre rondas. Usar ids string. Nuevo GetFeatured con id string vacío devuelve true,{ids={skinId...},resetAt=unix}, 5 destacados deterministas por día de Argentina. No hace falta EquipLoadout nuevo: las acciones existentes cubren la previa.
- **C21:** Admin RemoteFunction: List → true,{{userId,name,role}...}; Coins/Weapon/Skin/Aura/Level/Role/Kick/Mute/Unmute, targetUserId, value → ok,{key}. Solo conectados; no confiar en campos enviados por cliente. Mod: List/Kick/Mute/Unmute; Owner/Admin: todo, respetando jerarquía y D8. UI funcional en AdminPanel.client. Mute dura 600 s en este servidor; no es sanción persistente global. Se usa TextSource.CanSend sin reemplazar políticas de canales. Auditoría acotada en memoria + salida JSON AdminAudit; no es registro persistente de DataStore.
- **C22:** Telemetry.emit es solo servidor. Eventos WeaponSelected,WeaponWin,MatchDuration,MatchAbandoned. CustomField01=arma,02=modo,03=resultado. Sin UserIds como dimensiones. Desactivado en Studio, protegido por pcall. Los eventos de combate alimentan estadísticas/XP por partida. Abandono cuenta Matches/Abandons antes del guardado final, sin premio y sin doble finish.
- **Datos:** Schema=1, migración aditiva del perfil anterior, mismo Coins y mismos stores. Rechaza esquemas futuros antes de adquirir la sesión; conserva campos adicionales. ProfileState=Ready|Temporary|Lost. PlayerData.get devuelve nil al perder lease o vencer su última renovación; mutadores usan esa barrera. PlayerData.beforeRelease(callback) es exclusivamente servidor, sin yield: Stats lo usa antes del snapshot de salida.
Implementado en archivos; sin pruebas de Studio. Pedidos a Claude y plan de pruebas en [[Reporte 0.2 Codex]].
