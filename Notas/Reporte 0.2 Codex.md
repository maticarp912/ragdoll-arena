# Reporte 0.2 Codex — ronda 1

Fecha: 10/11/2026 14:11 (Argentina, UTC-3).
Pedido: [[0.2 Ronda 1 - Codex]]. Decisiones D7-D9/D11/D16 y contratos C17-C22 aplicados. No se abrió Studio ni se usó pantalla; no se regeneró el place, no se hizo commit/push.

## Implementado, sin probar en Studio
- Punto doble: elimina una sola vez, registra última eliminación, muestrea por Heartbeat y estima cruces del vacío dentro del frame. Exacta simultaneidad: desempate estable por UserId mayor (criterio técnico, no ventaja de equipo). Desconexión/character ausente se considera eliminación detectada. Aplica a 1v1 y 2v2.
- Previa de selección 10 s, bloqueo antes de spawn, cinemática 4,5 s, fases y deadlines; selección de skin/arma/infusión/aura por los remotos existentes. No se permite cambiar entre rondas. La carga de personajes precede el timer de Cinematic para no consumir el tiempo de cámara.
- Roles configurables, creador Owner, mateodoupa Tester por resolución en servidor; Nuevo por menos de 3 h guardadas. Propiedad efectiva Owner sin escribir skins/auras en inventario. La beta ya permite todas las armas a todos: no se introduce bloqueo nuevo.
- Panel funcional con UiTheme y ES/EN/PT-BR. Busca conectados por nombre/UserId, concede almas/arma/skin/aura/nivel/rol y modera con kick/mute/unmute. Rate limit, catálogo, tipos, finitud/rango, jerarquía, no autorregalo Admin, cuotas por sesión y auditoría JSON acotada. Owner no puede crear otro Owner mediante el panel.
- Niveles 1-100; XP por partida/victoria/eliminación y misión reclamada. Curva corta 1-5; almas iniciales y cada 5; cajas cada 10; títulos 25/50/75/100. Multiplicadores persistidos por tipo, mayor potencia y tiempo acumulado con tope; reloj solo durante Round. La primera victoria del día duplica almas; reinicio diario Argentina. Las cajas acumuladas esperan RewardService de ronda 2.
- Telemetría de arma elegida, victoria por arma, duración y abandono. Fallos de AnalyticsService no rompen el juego.
- Hallazgo 5: sesión perdida rechaza mutaciones, marca Lost y pide reconectar; expiración local también cierra el acceso. Autosaves concurrentes evitan esperar a todos en serie. Hallazgo 7: abandono se liquida antes del snapshot final, sin premio ni duplicación de resultado. Hallazgo 9: caché de nombres con TTL y límite; CityLife solo diagnosticado.
- Destacado diario de 5 skins en servidor (mismo catálogo/fecha para todos). Perfil schema 1 aditivo, mismo saldo Coins, rechazo de esquemas futuros y conservación de campos extra. Ninguna pérdida de almas al morir.

## Validación estática
check_lua en la tanda preparada: OK, 78 archivos. LihFolk sobre todos los archivos de esa tanda: 78 archivos, 0 errores/0 avisos. Son revisores heurísticos, no compilación ni ejecución Luau; no certifican comportamiento en Studio. Verificación de la copia integrada se anota al final.
Revisión manual: dependencias de módulos sin ciclos nuevos; abandono antes de liberar perfil; consumidores que mutan consultan PlayerData.get; nuevos permisos decididos en servidor; arrays/ids del catálogo y límites de administración; ninguna lectura de callbacks de TextChatService (solo se asigna OnIncomingMessage).

## Archivos tocados
- ReplicatedStorage/Progression.lua
- ReplicatedStorage/Roles.lua
- ServerScriptService/RoleService.lua
- ServerScriptService/ProgressionService.lua
- ServerScriptService/Telemetry.lua
- ReplicatedStorage/Economy.lua
- ServerScriptService/PlayerData.lua
- ServerScriptService/AdminService.lua
- StarterPlayer/StarterPlayerScripts/AdminPanel.client.lua
- ServerScriptService/MatchService.server.lua
- ServerScriptService/ShopService.server.lua
- ServerScriptService/StatsService.lua
- ServerScriptService/MissionService.lua
- ServerScriptService/LeaderboardService.lua
- ReplicatedStorage/LocaleCodex.lua
- ReplicatedStorage/Missions.lua
- ServerScriptService/Remotes.lua

Además: Contratos 0.2, este reporte, Peticiones del usuario e Indicaciones para las IA. No se tocaron archivos de Claude/Gemini.

## Pedidos a otros
1. **Claude:** CombatService.server.lua sigue calculando DebugAllowed y autorizando Debug sin RoleService; conectar RoleService.has(player,"Debug") en AMBAS rutas, conservar allowed IDs/Studio si corresponde. Codex no puede editar ese archivo. Sin eso, el rol Tester no habilita todas las herramientas de depuración.
2. **Claude:** Overhead.client debe leer Role y Roles.Data[role].color; Cinematic.client debe esperar MatchPhase=Cinematic y PhaseEnds válido (primera transición bloquea carga con deadline inmediato). No iniciar cámara por el simple cambio sin comprobar el deadline actualizado. Nadie debe aceptar daño/acciones durante Prematch/Cinematic; MatchService pone Frozen/CanFight.
3. **Gemini:** Prematch, vistas previas y tienda consumen C17/C20; nuevo resumen de XP en C19. Owner se refleja en OwnedSkins/OwnedAuras efectivos y AllCosmetics, no inventario persistido. No instalar otro OnIncomingMessage que pise las etiquetas de AdminPanel.
4. **Claude:** CityLife.client (hallazgo 9) busca CityDressing recursivamente cada 0,08 s incluso en partida; proponer cache con invalidación/streaming y salir antes si InMatch. No se midió lag ni fuga; no se modificó archivo ajeno.
5. **Integrador:** revisar/sincronizar esta entrega. Auditoría AdminAudit es log de servidor, no historial persistente global. Mute es local al servidor; evaluar persistencia si hace falta después.

## Pruebas de integración pendientes (sin ejecutarlas acá)
1. 1v1 y 2v2: caídas separadas y en mismo frame, doble muerte por daño, desconexión, respawn sin raíz, salud que regenera después de muerte y empate por tiempo. Confirmar un solo punto por ronda y criterio de simultaneidad.
2. Medir previa >=10 s, equipar las cuatro selecciones, bloquear desde Cinematic, cámara 4,5 s tras spawn, no cambiar entre rondas; observar Frozen/CanFight y todos los deadlines.
3. Perfiles anteriores (sin campos nuevos), reconexión, fallo de guardado y sesión transferida en un store de prueba; saldo Coins idéntico, campos extra conservados, futuro Schema rechazado sin sobrescribir. Snapshot de datos antes de despliegue real.
4. Owner/Tester/Nuevo, resolución del nombre fallida y reintento, chat, overhead por Claude. Un Admin no puede darse nada ni actuar sobre pares/superiores; Mod no concede valor; payloads inválidos no mutan nada. Mute/unmute/vencimiento en canal general, equipo y whisper; permisos previos CanSend=false deben conservarse.
5. Niveles 1/5/10/25/100, XP multi-nivel, reclamo repetido, boosts XP/almas, pausa lobby/desconexión, primera victoria del día y frontera 00:00 Argentina. No cobrar premios por asignación administrativa de nivel. Revisión de balance de curva pendiente.
6. Abandonar durante la ronda y durante resumen, cierre de servidor, un solo Matches y Abandons; sin victoria/premio por abandono ni escrituras posteriores sobre sesión perdida.
7. Servidor publicado de prueba: eventos AnalyticsService con armas/modos/resultados correctos, sin dimensiones de alta cardinalidad; caché nombres acotada. Studio no emite Analytics.
8. Panel en celular/teclado/mando y textos ES/EN/PT-BR; revisar accesibilidad/tamaño con Gemini. Estos aspectos no fueron comprobados visualmente.

## Pendiente para ronda 2
Rewards.lua/RewardService y remoto Rewards: ruleta, cajas, garantías, racha, semanal, maestría, colección, tutorial/primeros pasos y anti-AFK. No se empezaron porque son opcionales en esta ronda. El atributo MultEnds es proyección, MultRemaining es la duración real guardada; diseñar UI acorde.

## Referencias consultadas
LihFolk: Skill - Roblox DataStore Safety, Skill - Roblox Secure Remotes; diagnósticos previos de Session Locking and Profile Libraries, Economy Exploits - Dupes Races and Purchase Abuse, Memory Budgets and Leaks (sin copiar contenido externo).
Documentación oficial: https://create.roblox.com/docs/reference/engine/classes/AnalyticsService ; https://create.roblox.com/docs/reference/engine/classes/TextSource/CanSend ; https://create.roblox.com/docs/chat/in-experience-text-chat .

## Verificación de la integración aprobada — 10/11/2026 14:12 (Argentina, UTC-3)
El usuario aprobó explícitamente integrar la entrega. Copiados los 17 archivos exclusivos, verificados byte a byte contra la copia preparada. Cambios concurrentes de Claude/Gemini preservados. Proyecto completo: check_lua OK, 82 archivos; LihFolk 82 archivos, 0 errores y 0 avisos. Sin abrir Studio, sin regenerar place y sin commit/push. Pendientes: pruebas de ejecución y pedidos a otros enumerados arriba.

## Ronda 2 — 10/11/2026 18:20 (Argentina, UTC-3)

Pedido: sección Codex y reglas comunes de [[0.2 Ronda 2 - prompts]]. Se leyeron indicaciones, plan, contratos, decisiones, reporte de integración, diseño de recompensas y referencias de LihFolk. Se trabajó sobre los archivos exclusivos de Codex y las notas de continuidad. No se abrió Studio ni se usó pantalla; no se regeneró el place ni se hizo commit, checkout, reset, stash, restore o push.

### Implementado 🟡
- `Rewards.lua` y `RewardService`: resultados del servidor, ocho sectores, probabilidades visibles, giro diario a medianoche de Argentina, tickets por misiones/regreso/administración, hasta tres giros pagados por día con precio creciente. Las tres skins D15/D23 rotan por semana, primera semana desde el lunes 09/11: CrimsonEclipse. La garantía se conserva aunque cambie la semana: después de 30 fallos, el próximo giro da el gran premio; duplicado = almas equivalentes.
- Cajas Souls/Relic por almas, compra para guardar o pago/apertura en una operación, sin comprar automáticamente al agotar inventario. Reliquias: 60/28/10/2 %; tras nueve resultados inferiores a épica, la décima garantiza épica/legendaria (proporción 10:2). Catálogo incluye las tres skins de ruleta, excluye futuras/no disponibles y Robux. Duplicados pagan 40 % de su precio. Se muestran probabilidades por rareza y skin, incluidas las de garantía.
- Racha de siete reclamos, almas de días 1–6 y Reliquia el 7. Ausencias pausan sin borrar lo ganado; indicador de un día de gracia semanal. Semanal alterna victorias/parrys y paga una Reliquia. Regreso después de tres días otorga un ticket, tomando la última actividad/salida y no solamente la fecha de entrada.
- Bienvenida: elegir una de tres comunes una vez. API de tutorial exclusivamente servidor, 100 almas por paso comprobado una vez; omitir no paga los pasos, pero habilita el primer giro especial. Ese giro da XP ×2 por 30 minutos; si coincide con pity semanal, recibe también la skin. Siete objetivos persistidos de «Primeros pasos» y reclamo único de Requiem (épica), con conversión de duplicado.
- Partida: almas/XP al ganar o perder con participación válida, primera victoria diaria ×2 almas y bonus único de primera partida de 300 almas. Anti-AFK por tiempo vivo, desplazamiento horizontal acotado o eventos de combate contra enemigos de la misma partida. No cuenta caída vertical, desplazamiento durante derribo/carga/aturdimiento ni golpes a muñecos para progresión de partidas. AFK y abandono no avanzan objetivos, misiones o maestría ni cobran premios. Umbrales iniciales, no un detector completo de trampas.
- Misiones: añade patadas que hacen daño y ring-outs acreditados por el servidor; se conserva la rotación de tres por día. Reclamar cada diaria da también un ticket y XP. El progreso de combate se liquida al final válido; el resumen conserva C9 y agrega elegibilidad, bonus, primeros pasos, semanal, colección y maestría.
- Maestría 1–20 por arma, XP de partida/victoria/eliminaciones, acabado al 5, estela al 10 y título al 20. Reutiliza acabados y auras de arma existentes (elección técnica inicial, sin poder extra); no se añadieron modelos en archivos ajenos. Colección por arma, porcentaje, álbum y aura exclusiva. Las cinco auras del mapa Rewards.Collection dejan de ser nuevas compras; se respetan compras anteriores y propiedad efectiva del Owner. Nuevos acabados exclusivos o arte diferente quedarían para Gemini, no se simulan como entregados.
- Multiplicadores XP/almas ×1,5/×2/×3, mayor potencia y duración acumulada con tope, tiempo persistido que corre solo con personaje vivo habilitado para combatir en Round. Pausa fuera de combate, al ser eliminado y desconectado. Tienda: GetBoosts/BuyBoost, tres ids coherentes con el catálogo visual previo, cobro real y rechazo si excede la duración máxima; sin Robux en 0.2. «Almas y Monedas» se decide como herramienta de depuración, con permiso decidido por servidor. La conexión visual de estas compras es de Gemini.
- Panel funcional: BoxRelic, BoxSouls, Spins (1–100) y Streak (cursor 1–7). Mismos permisos, prohibición de autorregalo de Admin, jerarquía y cuotas existentes. Registra concesiones y rechazos de las acciones en AdminAudit. Asignar racha no paga días ni permite reclamar dos veces hoy. Auditoría acotada en memoria/log, no historial global persistente.
- Guardado: Schema 2, reconciliación aditiva de Rewards/Boxes/Mastery, campos extra conservados, mismas claves y stores; Coins no se renombra ni se migra. Compras con almas y premios modifican precio/inventario/marcadores sin yield; guardado diferido y salida con lease existente. Hooks de salida se ejecutan también en BindToClose, antes del snapshot. Nuevos remotos validan tipo, ids/rango/frecuencia; clave secuencial opcional permite reintentar el último resultado sin pagar de nuevo, y rechaza claves viejas.
- LocaleCodex: almas/souls/almas en los textos de ES/EN/PT-BR; 128 claves equivalentes, con parámetros coincidentes. Se agregan textos de premios, cajas, misiones, maestría, administración y mensajes de error.
- Telemetría: entrada, tutorial completado/omitido, primera partida, nivel 5, retorno D1/D7/D30, ruleta, cajas, reclamos y colecciones. Vocabulario acotado, sin UserIds como dimensiones; conserva la protección y desactivación en Studio de Telemetry.
- Complemento D17: guardado validado de layouts táctiles por Settings/GetTouchLayout/SetTouchLayout; publica TouchLayoutJson. Cantidad, ids, campos, números finitos y rangos en Economy. El editor actual requiere conexión de Gemini al remoto; no alcanza con cambiar el atributo local.

### Sin probar en Studio
Toda esta ronda. Las comprobaciones de la ronda 1 en [[Reporte 0.2 Integración]] no prueban estos cambios. Los revisores son estáticos/heurísticos; no se dispuso de un ejecutor Luau independiente y no se abrió Studio para suplirlo. No se validó visualmente el panel ni se ejecutaron remotos contra clientes reales.

### Pendiente y pedidos a otros
1. **Gemini:** consumir C19 actualizado en [[Contratos 0.2]] (GetState devuelve `ok,state`), animar exclusivamente el sector/premio devuelto y mostrar probabilidades/garantías reales. No hace falta crear un remoto Roulette: todo sale por Rewards. Escuchar RewardsChanged respetando el intervalo; RewardAnnouncement ya lleva clave y parámetros traducibles.
2. **Gemini:** reemplazar LocalBoost de Shop por BuyBoost y catálogo GetBoosts; ocultar la pestaña de saldo a quien no tenga `debugSouls`, y las compras nuevas de auras reservadas a colección. Cambiar sus propios textos a almas y el ícono. La verificación de permisos y el cobro están en servidor; la tienda actual todavía tiene el camino LocalBoost.
3. **Claude:** tutorial actual es local y sus pasos difieren del diseño aprobado. Producir `RewardService.tutorial(player,step)` o el evento servidor TutorialStep tras comprobar atacar por dirección / defensa y parry / patada al derribado. No pedir al cliente que certifique el logro. El backend ya paga y marca cada paso. Si la misión de patadas debe incluir el empujón al derribado sin daño, publicar Kick en C6 y conectarlo al contador sin doble conteo.
4. **Gemini:** conectar su editor táctil con C10/D17. Hoy saveLayout solo modifica TouchLayoutJson localmente: todavía no persiste entre sesiones. Settings devuelve una tabla validada, no acepta JSON arbitrario.
5. **Claude/Gemini:** integrar avisos/efectos de rareza, ruleta, cajas, calendario, bienvenida y progreso; su arte y pantallas no fueron modificados por Codex. Las auras de colección y acabados de maestría reutilizan el catálogo existente, según el mapa de datos.
6. **Integrador:** revisar cambios paralelos antes de regenerar el place. Durante esta ejecución hubo escrituras simultáneas incluso en Rewards/Shop/Stats/Admin; se conservaron y reconciliaron sus aportes. No se eliminaron cambios de Claude/Gemini. Hacer snapshot de perfiles de prueba antes de probar migración y no usar stores vivos.

### Archivos
Nuevos: `ReplicatedStorage/Rewards.lua`, `ServerScriptService/RewardService.lua`.
Modificados de Codex: `Economy`, `Progression`, `Missions`, `LocaleCodex`, `PlayerData`, `ProgressionService`, `StatsService`, `MissionService`, `MatchService.server`, `ShopService.server`, `AdminService`, `Remotes`, `AdminPanel.client`.
Notas: este reporte, Contratos 0.2, Peticiones del usuario, Versión 0.2 e Indicaciones para las IA. Los cambios concurrentes de otros responsables que aparezcan en git diff no son una entrega propia ni se sobrescribieron.

### Pruebas
- `node tools/check_lua.js .`: OK, 86 archivos en la copia revisada.
- LihFolk: 86 archivos, 0 errores y 0 avisos. Un primer aviso por source en Rewards quedó corregido con validación explícita de tipo y enumeración.
- `git diff --check`: sin problemas.
- Comprobación adicional con Node: referencias usadas de Rewards y métodos PlayerData definidas; ids de skins revisados contra el catálogo; 128 claves de LocaleCodex coincidentes en los tres idiomas y mismos parámetros; sin textos con el nombre anterior de la moneda; RewardService sin InvokeClient, esperas o escrituras directas de DataStore.
- Siete fronteras de fecha evaluadas desde las expresiones aritméticas del módulo: 23:59:59/00:00 Argentina, reset diario, lunes y reset semanal. Es evaluación parcial de expresiones en Node, no ejecución de los módulos en Roblox.
- Revisión manual: sin ciclos nuevos de require; compras/reclamos sin yield entre validación y mutación; estado de perfil consultado antes de conceder; asignación administrativa no cobra premios; garantías globales sin reiniciar al cambiar el día/semana; contadores del tutorial con claves string guardables.

Pruebas de integración a ejecutar: perfil 0.1/schema1 y schema futuro; cajas acumuladas por niveles; guardar/reconectar/perder lease; free/Tutorial/Ticket/Paid y cuarto giro pagado; 30 fallos de ruleta y cambio semanal; novena/décima Reliquia y duplicados; odds suman 100 % y coinciden con catálogo real; reclamos repetidos/concurrentes y reintentos con claves viejas; racha 7/8 y ausencias con/sin gracia; regreso tras sesión larga; semanal y Primeros pasos; XP/niveles/maestría multiumbral; AFK quieto, solo movimiento, parry, empuje recibido, eliminación rápida, abandono/cierre y 1v1/2v2; boosts en lobby/previa/round/eliminado/reconexión y tope; permisos/jerarquía/cuotas de administración; compras de colección/ruleta rechazadas; layouts vacíos, ids extra, tablas profundas, NaN/inf y spam; visualización ES/EN/PT-BR y celular. Ninguna está marcada como ejecutada.

Referencias consultadas sin copiar contenido: LihFolk **Roblox Secure Remotes**, **Roblox DataStore Safety**, **Server Authority and Validation**, **Data Schema Design and Migrations**. API detallada y ejemplos de consumo: [[Contratos 0.2]], C19/C20/C21/C10.

### Cierre de revisión — 10/11/2026 18:25 (Argentina, UTC-3)
La incorporación paralela de Rewards.client aumentó el proyecto a 87 scripts. Revisado su consumo de C19 sin editar el archivo ajeno: coincide con GetState/Spin/OpenBox/reclamos, y el backend publica los ids de Primeros pasos que sus textos esperan. RewardsChanged se agrupa y se emite después del cooldown para permitir el refresco. Pendientes de Gemini observados en esta copia: Shop todavía usa LocalBoost; TouchUI todavía solo escribe un atributo local; completar acceso a ClaimWeekly/SkipTutorial y revisar probabilidades especiales y reintentos. Stats acepta señales servidor del golpe decisivo al pasar a RoundEnd y exige que pertenezcan al personaje actual.
Verificación de esa copia: `check_lua` OK (87 archivos), comprobación adicional Node OK (128 claves/3 idiomas, referencias y siete fronteras de fecha), `git diff --check` limpio; LihFolk 87 archivos, 0 errores y 0 avisos.

### Desglose final de premios — 10/11/2026 18:28 (Argentina, UTC-3)
El resumen ahora incluye también las almas concedidas al subir de nivel en `coins.levels/total`, y el desglose `progression.levelRewards={souls,boxes,titles}`; los premios XP de la ruleta exponen el mismo resultado de nivel. Esas almas también alimentan Stats.Coins. No se cambia la curva ni se repagan niveles asignados por administración. `check_lua` sigue OK (87 archivos) y `git diff --check` limpio; ejecución final de LihFolk sobre este ajuste registrada debajo.

**Verificación final — 10/11/2026 18:29 (Argentina, UTC-3):** LihFolk terminó sobre los 87 archivos con **0 errores, 0 avisos**. Sin más cambios de código después de los chequeos finales. Entrega local lista para integrar; continúan pendientes las conexiones ajenas y las pruebas de ejecución enumeradas arriba.


## Suspenso de recompensas (10/11)

Registro: 10/11/2026 23:08 (Argentina, UTC-3). Pedido y autorización excepcional para la UI: [[0.2 Suspenso de recompensas - Codex]]. Entrega local para integrar con Claude. No se abrió Studio, no se regeneró el place ni se publicó o hizo commit. Se conservaron los cambios concurrentes de las otras IA, incluidas las cinco `WeeklySkins`.

### Implementado — 🟡

- `Rewards.client.lua`: carrusel horizontal para Almas y Reliquia **después de recibir el premio del servidor**. Sus opciones salen de `GetState.boxes[id].probabilities`, con skins reales, nombres, rarezas y colores; excluye las rarezas con probabilidad cero por garantía. Mezcla solamente la presentación, sin elegir el premio ni preparar falsos casi-premios legendarios. La tarjeta final es la respuesta del servidor, también al convertir una skin repetida. Mantiene hasta tres vistas 3D activas en la tira, en lugar de cargar un modelo por tarjeta.
- Revelación compartida: destello de rareza, nombre grande, ViewportFrame con WeaponBuilder para skins y duplicados, aviso de conversión a almas, multiplicador y duración reales. Racha, Primeros pasos, semanal, bienvenida y pasos certificados del tutorial usan una carta/cofre que tiembla y abre la tapa. El bono del giro de tutorial se muestra también si coincide con la garantía semanal. Reclamar la caja semanal no la abre ni la cobra otra vez.
- Ruleta: desaceleración cúbica, tic al cruzar cada sector, pausa de 0,24 s antes de entrar al sector final y revelación compartida. El gran premio semanal, incluso duplicado, tiene panel y visor más grandes, nombre mayor, destello más intenso y revelación más larga.
- Ajustes concentrados en `REVEAL`, al principio del cliente: cajas 4,12 s (2,8 + 0,22 + 1,1), giro normal 4,42 s, gran premio semanal 5,82 s; premio fijo 1,97 s. Son duraciones objetivo de animación, **sin contar red ni el tiempo que el jugador deja el resultado abierto hasta Continuar**. Saltear con botón, Enter, Enter numérico, A del mando o toque muestra el premio ya concedido; nunca vuelve a invocar una compra. Los premios recibidos juntos se encolan. Se liberan input, modal y selección al cerrar; al entrar en partida se interrumpe la presentación sin alterar el premio.
- Tiros pagos: «Tirar otra vez · {precio} almas», saldo y tiros pagos restantes hoy; disponible después del gratuito, también si quedan tickets. Confirmación explícita antes de `Spin/Paid`; Cancelar no compra. Reconsulta `GetState` y exige confirmar otra vez si cambió precio, contador o día. Precios y límite siguen en servidor: 250 / 500 / 1000 y un máximo de tres pagos por día.
- Pedidos C19 serializados y espaciados según `Rewards.Interval`; refrescos agrupados, exclusión de dobles clics y `nextRequest` enviado en mutaciones. Una respuesta incierta provoca una lectura del estado, sin repetir la mutación automáticamente.
- Celular: ruleta, cajas y reclamos en una columna desplazable, con controles de 44–46 px; revelación, confirmación y probabilidades independientes del escalado del panel principal. Se descuenta el inset de Roblox y se adapta al ancho/orientación. La pestaña de colección conserva su diseño anterior. El modal de probabilidades usa las efectivas/tutorial y desglosa las skins reales de las cajas, incluidas garantías.
- `LocaleCodex.lua`: 15 claves nuevas en ES / EN / PT-BR, con los mismos parámetros. Sin editar LocaleGemini.
- `Rewards.lua`: `RobuxSpinPack={enabled=false,productId=0,spins=3}` reservado y documentado. Tres tiros es un valor técnico provisional para un futuro paquete; la 0.2 no lo vende ni tiene botón de Robux. No se modificó `ProcessReceipt` ni se agregó un prompt de compra.

**C19: ampliaciones aditivas para integrar (documentadas acá por el límite de archivos autorizado):**

- `GetState.paidSpinsRemaining`: entero 0..3. `paidSpins` sigue siendo el contador usado; `paidSpinPrice` sigue siendo nil al agotar el cupo.
- `ChooseStarter`, `ClaimStreak` y `ClaimWeekly` agregan `result.reward` con el premio realmente concedido. Conservan `key` y el `nextRequest` del manejador; los reclamos repetidos siguen rechazados por el servidor.
- `RewardsChanged` conserva sus avisos sin argumentos y puede llevar `{source="Tutorial",reward={kind="Souls",amount=Rewards.TutorialSouls}}` inmediatamente después de certificar y pagar un paso. Los consumidores viejos que ignoran argumentos siguen funcionando. El refresco posterior sigue pasando por el cooldown. La notificación no concede nada en el cliente.

### Probado fuera de Studio

- `node tools/check_lua.js .`: **OK, 89 archivos sin problemas detectados**. Es el chequeo estático del proyecto, no compilación/ejecución del motor.
- `git diff --check`: limpio.
- Evaluación adicional con Node, usando la configuración actual: 2.880 combinaciones de ángulo inicial y sector de ruleta; destino exacto, una entrada al sector final después de la pausa e intervalos crecientes entre tics. Centrado del resultado del carrusel para anchos 375, 390, 768 y 1920; duraciones normales entre 3 y 5 s y extensión semanal. Comprobación aritmética del encuadre y controles de 46 px en 375×667 descontando el inset.
- Revisión estática y aritmética de precios/cupo (250/500/1000, luego nil/0), revalidación previa a confirmar, cinco skins semanales conservadas y reserva Robux deshabilitada. No fue una compra ejecutada en un servidor Roblox.
- Idiomas: 143 claves por idioma, sin claves duplicadas, mismos parámetros en los tres y referencias nuevas del cliente presentes. Se verificó el UTF-8 de los textos nuevos.
- Referencia consultada: LihFolk **Server Authority and Validation**, apartados Common mistakes y Checklist, sin copiar su contenido. Resultado del escáner final registrado al cierre de esta sección.

### Pendiente de probar en Studio — ⬜

- Abrir ambas cajas, sin y con garantía, recibir cada clase de premio y duplicados; comprobar que la tarjeta final, la skin 3D, rareza, sonido y conversión coincidan con inventario/saldo. Medir el tiempo y rendimiento real en celular con los modelos actuales.
- Ruleta en los ocho sectores, gratuito/Tutorial/Ticket/Paid, garantía y rotación semanal; gran premio nuevo y repetido; caso de garantía + bono de tutorial. Escuchar tics y pausa, y revisar brillo y legibilidad.
- Pagar 250, 500 y 1000; rechazar cuarto pago y saldo insuficiente. Cancelar, pulsar dos veces, confirmar durante reset diario, latencia, respuesta incierta, reconexión y persistencia. Comprobar que refrescar/saltear/cerrar nunca cobra ni concede otra vez.
- Racha de almas y del día 7, Primeros pasos, semanal, bienvenida y cada paso de `TutorialService.server.lua`; avisos simultáneos y tutorial con la ventana de recompensas cerrada.
- Mouse/Enter, mando A/B y navegación, toque en 375 px, ES/EN/PT-BR, orientación y cambio de escala. Revisar selección al volver, avisos, modal de probabilidades, transición a partida y cierre de menús.

**Comprobado en Studio:** nada en esta entrega. Claude integra y ejecuta estas pruebas antes de marcar ✅.

**Cierre de verificación — 10/11/2026 23:09 (Argentina, UTC-3):** LihFolk revisó los 89 archivos de la copia final con **0 errores, 0 avisos y 0 info**. `node tools/check_lua.js .` también pasó sobre 89 archivos. Sin cambios de Lua posteriores a esos controles.

## Revisión final (11/11)

Registro del 11/11/2026 00:18 (Argentina, UTC−3). Revisé los cinco commits recientes y los diffs desde `HEAD~3`, incluido `1cd1be2` (cajas de Tormenta y ventanas Frame).

### Arreglado — 🟡

- **Perfiles.** `PlayerData` delega todos los contadores de cajas a `Rewards.reconcile` antes de publicar el perfil. Conserva el saldo y las Reliquias válidas, crea los contadores faltantes en cero y aplica el mismo saneo entero de 0 a 100.000 a las cinco cajas.
- **Colección.** Excluí las variantes `boxOnly = "Storm"` de la lista, del numerador y del denominador por arma, tanto en el servidor como en el respaldo del cliente. Así se mantiene el progreso de las colecciones previas y el requisito de sus auras. Las skins de Tormenta ganadas siguen equipables desde la armería. La maestría sigue contando XP de combate por arma.
- **Pantalla de cajas.** La lista conserva su desplazamiento al reconstruirse y recupera el foco del botón de caja con mando si sigue disponible. Los títulos y botones ajustan el texto en pantalla angosta. Abrir y consultar probabilidades queda deshabilitado hasta recibir el estado del servidor, que trae los precios y el inventario.
- **Multiplicadores y compras.** Quedó `Rewards.Boosts` como único catálogo de venta, con los precios activos de 1.200, 1.400 y 2.400 almas. Actualicé el comentario de `buyCosmetic` para que describa el cambio en memoria y el guardado diferido.
- **Hallazgo 8, IDs de recibos.** Unifiqué el registro de skins y auras. Un ID duplicado dentro de un catálogo o entre ambos genera un aviso y su recibo queda pendiente. Los IDs únicos conservan el destino de cada cosmético. La 0.2 sigue con compras en almas.

### Revisado sin cambios

- **Cajas y tienda.** `BuyBox` y `OpenBox` usan la configuración de las cinco cajas. Tormenta solo entrega sus variantes. La Reliquia excluye Tormenta, conserva la garantía y puede dar las cinco skins semanales de la ruleta. La tienda rechaza la compra directa de ambos grupos y los excluye del Destacado.
- **Presentación.** El carrusel toma candidatos de la caja elegida con probabilidad positiva y la revelación usa el premio que devuelve el servidor. El modal de probabilidades recorre las cinco cajas. El panel principal es Frame. `GroupTransparency` se usa en el CanvasGroup de la revelación.
- **Hallazgo 5, sesión perdida.** `PlayerData` ya marca `Lost` al vencer el lease local o detectar un token ajeno, desactiva la escritura y deja de exponer el perfil a los servicios.
- **Hallazgo 7, abandono.** El cierre estadístico ya se ejecuta antes de guardar el perfil. Registra partida y abandono una vez, sin premio para quien se va. Para Claude queda el cierre de la serie completa por abandono si se vacía un equipo. `MatchService.server.lua` todavía puede resolver rondas adicionales hasta llegar a `RoundsToWin`.
- **Hallazgo 9, rendimiento.** `CityLife` conserva la referencia a `CityDressing` y evita la búsqueda recursiva durante partidas. La caché de nombres ya tiene vencimiento de 600 s y tope de 200 entradas.
- **Hallazgo 8, precio premium.** El precio efectivo por producto queda para la etapa en que se habilite Robux. La rama actual rechaza esas compras y `RobuxSpinPack` está deshabilitado. La futura presentación del precio necesita `Shop.client.lua`.

### Comprobado fuera de Studio

- `node tools/check_lua.js .` pasó sobre 89 archivos. LihFolk examinó 89 archivos con 0 errores, 0 avisos y 0 mensajes informativos.
- Compilé los archivos del encargo con Luau y ejecuté `Rewards`, `Skins` y `RewardService` con servicios Roblox simulados. Verifiqué migración, saneo de los cinco contadores, los 36 premios de Tormenta (7 raros, 16 épicos y 13 legendarios), colección y maestría.
- Las cinco distribuciones de `GetState` sumaron 100 % por rareza y por premio, incluida la Reliquia con garantía (5/6 épica y 1/6 legendaria). Probé los ocho cruces caja/rareza de Tormenta con tiradas deterministas, compra para guardar, apertura de inventario, pago directo, duplicados, saldo insuficiente, tope y repetición de solicitud. La garantía de Reliquia quedó intacta al abrir Tormenta.
- Probé el bloque de recibos con IDs simulados. Las colisiones de skins, de auras y cruzadas quedan pendientes. Los IDs únicos llegan al cosmético correcto.
- Revisión estática del cliente a 375 px útiles. La ventana mide 343 px, las tarjetas 303 px y el botón de apertura 239 × 48 px. Las claves de las tres cajas y de su restricción de compra existen en ES, EN y PT-BR. El redondeo de cada fila del modal a dos decimales puede variar la suma visible.

### Necesita Studio — ⬜

- Cargar un perfil de 0.1 con Reliquias, abrir y comprar las tres cajas nuevas, reconectar y comparar inventario, saldo, colección, maestría y auras. Verificar la décima Reliquia y una skin de ruleta obtenida desde Reliquia.
- Abrir las cinco cajas con toque, mouse y mando. En 375 px, revisar el desplazamiento hasta la última tarjeta, la recuperación del foco tras refrescar, los textos en los tres idiomas, el modal de probabilidades, el carrusel, los modelos 3D, el resultado y su conversión por duplicado. Medir rendimiento en celular.
- En el entorno de guardado aislado, comprobar expiración y traspaso de lease, abandono 1v1/2v2 antes y durante una ronda, y comportamiento de `CityLife` con streaming. Probar recibos reales solo cuando existan productos de prueba.
- Comprobado en Studio en esta revisión · ninguno.

### Pendientes para Claude

- **Cuota horaria de concesiones.** `AdminService.lua` conoce al administrador y hoy limita 100 acciones por hora, mientras `Rewards.admin` limita a 100 unidades por concesión. Falta comprobar el cupo antes de conceder y descontar las unidades del presupuesto del administrador al completar la concesión. El presupuesto tiene que compartirse entre destinatarios. `MissionService` usa `Rewards.admin` para los tiros ganados, así que el cupo corresponde al panel en `AdminService.lua`, fuera de los archivos de este encargo.

### D23 confirmada — 👤

- 11/11/2026 00:23 (Argentina, UTC−3). El usuario confirmó que las cinco skins del Eclipse Carmesí se consiguen en la rotación semanal de la ruleta y como premios legendarios de la Caja de Reliquias. La compra directa sigue bloqueada. Verificado por lectura del código.
- Para la próxima revisión de interfaz: cambiar «Solo en la Ruleta» por «Ruleta o Caja de Reliquias» en los textos de tienda de los tres idiomas. Las dos claves están en `LocaleGemini.lua`, fuera de los archivos de este encargo.

## Glow-up y monetización

Registro del 11/11/2026 01:57 (Argentina, UTC−3). Encargo en [[Plan glow-up y monetización]], secciones 2, 3b, 4 y 5.

### Implementado — 🟡

- **Suerte de cofres.** `Rewards.Luck` descuenta tiempo real al leer, incluso tras desconexión. `R.reconcile` sanea el multiplicador, los segundos y el reloj del perfil. La misma distribución del servidor se usa para sortear y para `GetState`. El estado incluye probabilidades base, efectivas y con el amuleto, por rareza y por skin cuando corresponde. El peso épico y legendario se duplica. Por ejemplo, la probabilidad de obtener Épica o Legendaria en la Reliquia sin garantía pasa de 12 % a 21,428571 %. En la Reliquia con garantía y el Cofre del Eclipse, los pesos disponibles suben en la misma proporción y los porcentajes se mantienen. La ruleta conserva su distribución. El modal muestra la conversión del 40 % por duplicado y la Bóveda muestra los porcentajes antes de ofrecer el amuleto. `Luck30.enabled = true`, con todos los IDs de monetización intactos.
- **VIP.** Aplica +20 % a almas ganadas en partidas, primer partido y misiones completadas. Conserva los valores de compras, duplicados, regalos y recompensas fijas. Un beneficio diario reclamable usa el mismo calendario que la ruleta. Entrega un tiro extra cuando la política lo permite y 150 almas fijas cuando devuelve restricción o se desconoce. El reclamo de almas consume el beneficio del día sin avanzar la garantía de ruleta. El rol mantiene la prioridad de Owner, Admin, Mod y Tester. Corona junto al nombre y aura `VipCrown` equipable exclusivamente con el pase, validada en servidor.
- **Azar pago.** Cuando se configuran ventas de almas, el servidor bloquea la compra de cofres y los giros con almas para cuentas restringidas. Los cofres comprados y los tickets comprados tienen contadores separados. Los premios de juego, la ruleta diaria y las cajas ganadas conservan su camino gratuito. Para cuentas restringidas, la suerte activa queda sin efecto y se ocultan los productos de azar pago. [Guía oficial de Roblox](https://create.roblox.com/docs/production/monetization/paid-random-items)
- **Cofres y Skip.** Seis niveles en orden de `Rewards.BoxOrder`, grilla de 3 × 2 en PC y lista en celular. `CHEST_TIERS` define marco, color, tamaño, ícono y slots para las imágenes cerrada y abierta de cada nivel. La apertura objetivo dura 6,45 s entre sacudida, apertura, tira, frenado y revelación, antes de «Continuar». Enter, A y toque pueden saltarla con `Pass_SkipOpening`. El botón con candado abre la ficha del pase y consulta su precio. La compra y el sorteo siguen separados de la animación.
- **Bóveda e interfaz.** Pases arriba y paquetes abajo, con precio consultado a Roblox, ícono de Robux y etiquetas de catálogo. El «+» del saldo abre los paquetes desde tienda y recompensas. Las compras de skins y cofres muestran el faltante y el acceso a la Bóveda. La pestaña Almas anterior queda bajo permiso de depuración. Pistas mediante `Device`, tokens de Eclipse y ajustes de ancho, títulos, filtros y controles en recompensas, tienda y armería. Se actualizaron las vistas previas, el HUD, las pantallas de menú y la paleta de carga. Hay 40 claves `mz.*` en ES, EN y PT-BR.
- **Revisión de pagos.** `MonetizationManager` usaba el precio sugerido cuando fallaba la consulta. Ahora el catálogo y el cliente consultan precios de Roblox y ocultan las ofertas que carecen de precio válido o autorización. También corregí el reintento de un pase si la primera consulta fallaba antes de crear su caché. En `PlayerData.processReceiptWith`, la entrega se aplica una sola vez a una copia. La escritura guarda el premio con el PurchaseId y una revisión. Tras confirmar, se incorporan solo los campos afectados y se conservan las almas ganadas mientras se guardaba. La revisión impide que un guardado viejo pise una compra confirmada cuya respuesta se perdió. `PurchaseVersion` actualiza la interfaz también cuando se compra dos veces el mismo paquete. Referencia LihFolk «Purchase Data and Receipts». [Precios regionales](https://create.roblox.com/docs/production/monetization/regional-pricing)

### Probado fuera de Studio

- `node tools/check_lua.js .` pasó sobre 94 archivos. LihFolk examinó 94 archivos con 0 errores, 0 avisos y 0 mensajes informativos. Compilé los 94 scripts con Luau y `git diff --check` quedó limpio.
- Con APIs simuladas y los módulos reales, probé los seis cofres, la suma del 100 % de las probabilidades base, efectivas y de vista previa, la caducidad y la recarga de la suerte, y la garantía. Probé sorteos deterministas de las filas disponibles y verifiqué que la ruleta conserva sus pesos.
- Probé una compra confirmada, un recibo repetido, un premio ganado durante el guardado y una respuesta perdida después de persistir. También probé precio faltante y recuperación, restricciones, separación de tickets y cofres, rol VIP, Corona VIP y el beneficio diario único.
- Comprobación aritmética a 375 px útiles. Recompensas mide 343 px, tienda y armería 347 px, y las tarjetas de cofres y Bóveda 297 px. El botón de abrir y el de precio conservan 44 px de alto en esa vista. Verifiqué la paridad de las claves en los tres idiomas.

### Necesita Studio — ⬜

- **Comprobado en Studio en este encargo** · ninguno.
- A 375 px y en horizontal, probar tienda, armería y recompensas con toque, teclado/mouse y mando. Revisar textos en los tres idiomas, navegación, filtros, scroll, Bóveda desde el saldo y desde un faltante, y apertura de los seis niveles. Probar Enter, A, toque, candado, cerrar la ficha, final natural y entrada a partida.
- Con `StudioGrantPasses` y la acción `Monetization/StudioTest` de prueba, revisar el rol y la Corona VIP, la ficha de suerte al entregar o vencer el amuleto, las probabilidades visibles, la conversión de repetidas y el refresco al comprar otra vez el mismo paquete. Probar el reinicio diario y el camino de reemplazo de 150 almas.
- En una publicación de prueba con los IDs cargados, verificar precio regional en el diálogo de Roblox, recibos reales y reconexión. El arte final de cofres queda pendiente de cargar en los slots de `CHEST_TIERS`.

### Preguntas para el usuario — 👤

- Usé **150 almas** como reemplazo fijo del tiro VIP restringido. ¿Te sirve ese monto diario?
- ¿Querés conservar Relicario del Rayo en 12.000 y Cofre del Eclipse en 20.000? Los precios actuales siguen vigentes.

## Almas, monedas y títulos

Registro del 11/11/2026 10:56 (Argentina, UTC−3). Encargo en [[Almas, monedas, títulos y party - Codex]]. El usuario aprobó los precios propuestos para el catálogo existente y dejó las skins básicas nuevas para otra etapa.

### Implementado — 🟡

- **Saldos.** Almas sigue en `data.Coins`. Monedas usa `data.Gems`, con migración aditiva y publicación en el atributo `Gems`. Tienda y recompensas muestran los dos saldos, con un rombo azul para monedas. La Bóveda conserva sus cinco productos y sus IDs, con 400 / 850 / 2.200 / 4.600 / 10.000 monedas por 49 / 99 / 249 / 499 / 999 Robux sugeridos. El catálogo consulta el precio real.
- **Cómo se ganan.** El tutorial completo entrega 200 monedas una sola vez, incluso si un perfil anterior ya tenía sus tres pasos completados. Cada misión diaria da 40 monedas, además de las almas y el tiro ya existentes. La ruleta tiene un sector de 15 monedas al 8 % en la distribución base. Con tutorial y tres misiones por día, las skins de 1.200 a 2.000 monedas equivalen a unos 9 a 15 días por skin antes de sumar cofres o ruleta.
- **Gasto.** Dos giros diarios extra por almas, a 250 y 500. Las almas también sirven para los cofres 1 y 2, los multiplicadores, los títulos de tienda y el renacimiento. La compra de skins con monedas valida el precio y la propiedad en servidor.
- **Cofres.** Almas y Reliquias cuestan 500 y 1.500 almas, con 10 % y 17 % de skin base. El resto de resultados son monedas y multiplicadores. La Reliquia usa su nueva distribución desde la primera apertura y sigue pudiendo entregar skins del Eclipse Carmesí. Los niveles 3 a 6 cuestan 600 / 1.300 / 2.400 / 4.000 monedas. Se conservan las rarezas de Tormenta generando sus variantes antes de cambiar los precios de venta. Siguen visibles las probabilidades base y con suerte, y la conversión de duplicados al 40 % del valor anterior en almas.
- **Azar pago.** Se bloquean la compra y la apertura de los cofres 3 a 6 para cuentas restringidas, y se ocultan los paquetes de monedas. Los dos primeros cofres y los giros con almas siguen disponibles para esas cuentas. La política también se comprueba en servidor. [Guía oficial de Roblox](https://create.roblox.com/docs/production/monetization/paid-random-items)
- **Renacimiento.** En maestría 20 se puede volver a nivel 1 desde la pestaña Títulos. Precio inicial de 5.000 almas, con 2.500 adicionales por renacimiento. Se conserva el historial de recompensas desbloqueadas. Cada renacimiento añade una estrella al arma y un título con numeral romano para la tarjeta.
- **Amigos.** +20 % de almas y XP ganadas jugando al coincidir con un amigo de Roblox en el servidor. Las almas acumulan el bonus de amigos y VIP de forma aditiva. Se usa `IsFriendsWithAsync` con caché por par presente, y se quita el bonus al salir el último amigo. Indicador en el HUD del lobby y en el resumen de partida. [Referencia de Player](https://create.roblox.com/docs/reference/engine/classes/Player#IsFriendsWithAsync)
- **Títulos.** Armería con categorías, rareza, progreso, compra con almas, equipamiento, vista previa de tarjeta y avisos breves. Se contabilizan Parries, RingOuts, Kicks, GuardBreaks, Finishers y Throws, y se conceden Undying, Collector, Duelist y BondedBlades. Undying toma los puntos de ronda publicados por MatchService. BondedBlades usa la party y el equipo al iniciar la partida. El evento actual de daño trae solo `amount`. El contador de remates usa `info.finisher` cuando está presente y el estado servidor `M1` con `Finisher` como respaldo.
- **Interfaz.** Textos nuevos en ES, EN y PT-BR. El catálogo existente mantiene los modelos, las referencias y las vías exclusivas de ruleta y Tormenta.

### Tabla completa de venta directa

| Arma | Monedas · precio aplicado | 99 Robux · precio sugerido | 199 Robux · precio sugerido |
|---|---|---|---|
| Universales | — | Obsidiana, Hueso, Oro Ceniciento, Runas Etéreas, Linaje Carmesí | — |
| Espada | Filo del Dragón · 1.400 / Vigilia Violeta · 2.000 / Reliquia Dracónica · 12.000 | Juramento Solar, Corona del Alba, Aguja del Vacío, Diente del Exilio | Réquiem Astado, Espina del Osario |
| Espadón | Luto Real · 1.200 / Devorador · 1.800 / Alas del Abismo · 10.000 | Sudario | Tumba Esmeralda, Cruz del Ocaso |
| Dagas | Crecientes de Plata · 1.200 / Lunas del Vacío · 1.800 | Colmillos Carmesí, Garras del Eclipse | Espinas Vivas |
| Estoque | Corte de Plata · 1.200 / Lamento Oscuro · 2.000 | Duelo Dorado, Duelo del Crepúsculo, Aguijón Espectral, Velo Amatista | Lengua de Fuego |
| Maza | Juicio de Hierro · 1.200 / Mandíbula Antigua · 1.600 / Corona del Osario · 15.000 | Verdugo del Norte, Corazón de Forja, Vértebra del Abismo | Espinas Carmesí, Hacha del Osario, Fauces del Sepulcro |

Acero Viejo es el acabado inicial. Las tres skins iniciales y Réquiem Astado también conservan sus vías de recompensa existentes. La tabla Robux clasifica según el precio anterior del catálogo (hasta 3.100 almas para estándar). Los productos de skins requieren que el usuario configure sus IDs y precios en Roblox.

### Probado fuera de Studio

- `node tools/check_lua.js .` pasó sobre 100 archivos. LihFolk examinó 100 archivos con 0 errores, 0 avisos y 0 mensajes informativos. Compilé los 100 scripts con Luau y `git diff --check` quedó limpio.
- Con APIs Roblox simuladas y los módulos reales, probé migración y saneo de saldos, tutorial y misión únicos, recibo repetido, ingreso concurrente de monedas y compra de skin con cada moneda de venta. Contrasté los 13 precios aprobados y la distribución original de las 36 variantes de Tormenta.
- Probé los seis cofres y sus probabilidades base, efectivas y de vista previa. Verifiqué 10 % y 17 % base, apertura sin garantía previa, monedas en la ruleta, los dos giros diarios por almas y el bloqueo de los cuatro cofres con monedas para cuentas restringidas.
- Probé presencia y salida de un amigo, XP de juego frente a XP de recompensa, seis estadísticas, los cuatro logros, compra y equipo de títulos, renacimiento con título II, y conservación de saldos y títulos al guardar y volver a entrar.

### Necesita Studio — ⬜

- Comprobado en Studio en este encargo · ninguno.
- Probar a 375 px y con mando la Bóveda, ambos saldos, las tarjetas de cofres, sus probabilidades y la armería. Revisar en los tres idiomas el faltante, el scroll por categorías, la vista previa, los avisos y el botón de renacimiento.
- Probar partidos 1v1 y 2v2 con amigo, party y rondas empatadas, más una victoria sin perder rondas y un abandono. Verificar especialmente el respaldo de remates con golpes simultáneos y la tarjeta real tras equipar el título II.
- Probar la cuenta restringida y la elegible en una publicación de prueba, con IDs configurados. Verificar los importes del diálogo Roblox, el recibo y el inventario después de reconectar.

### Preguntas para el usuario — 👤

- El renacimiento quedó en 5.000 almas iniciales y +2.500 por repetición. ¿Te sirve ese ritmo?
- Con 40 monedas por misión, el objetivo de una skin accesible queda en alrededor de 9 a 15 días con las tres diarias. ¿Querés mantener ese ritmo después de probarlo?

### Vista previa y probabilidades de cofres · 11/11/2026

**Implementado**

- Cada tarjeta tiene el botón **Ver recompensas** con un ojo. La ventana muestra un solo cofre, las chances de skin por rareza, el total de otros premios cuando corresponde y el detalle por premio, con miniaturas 3D para las skins. Se puede abrir desde ahí. La ventana también muestra la conversión de repetidas al 40 % y el progreso de cada garantía.
- `RewardService` usa la misma distribución para la apertura y `GetState`. Las chances de cada skin salen de su rareza dividida por el número de skins elegibles. Cuando hay suerte, se muestra la distribución de la próxima apertura con y sin el multiplicador. Si cambia la distribución entre la consulta y la apertura, el servidor pide refrescarla antes de cobrar. Cofres, ruleta y Bóveda muestran porcentajes con `Format.percent`.
- **Exclusiva** es una rareza superior a Legendaria, con el color `UiTheme.Rarities.Mythic`. Las cinco skins de Eclipse Carmesí siguen rotando como premio de la ruleta y pueden salir de los cofres 2 a 6. Para habilitar la probabilidad de Legendaria de los cofres 1 y 2, usé tres skins de lujo del catálogo existente como Legendarias: Reliquia Dracónica, Alas del Abismo y Corona del Osario.
- El cofre 1 y la Reliquia dan 10 % y 17 % de skin respectivamente en aperturas base. Reliquia asegura una skin Épica o superior como máximo al décimo cofre desde el último resultado que cumple. Eclipse asegura Legendaria o superior al décimo y Exclusiva al cuadragésimo. Las repetidas también cuentan para la garantía. Una Exclusiva satisface ambos umbrales de Eclipse. Se guardan los contadores por cofre y se migra el avance anterior de Reliquia desde `relicPity`.
- Los premios de moneda y multiplicadores de los dos cofres de almas conservan sus pesos. Se conserva la restricción del servidor sobre los cofres de monedas. Se agregaron los textos ES, EN y PT-BR.

**Probado fuera de Studio**

- `node tools/check_lua.js .` pasó sobre 100 archivos. LihFolk revisó 100 archivos con 0 errores, 0 avisos y 0 mensajes informativos. También compilaron los 100 scripts con Luau.
- Con los módulos reales y servicios Roblox simulados, validé que los pesos base coinciden con la tabla pedida, que las distribuciones suman 100 % y que la chance de cada skin recompone su rareza. Probé la suerte activa y su vencimiento, las chances de la ruleta, el rechazo antes de consumir un cofre con una distribución vencida, el reintento del mismo pedido, la política de azar, la compra, la conversión de duplicados, el contador antiguo y el guardado de los tres contadores nuevos. En Eclipse comprobé los dos topes en toda la muestra.
- La simulación abrió **100.000 cofres de cada tipo** mediante el remoto real `OpenBox` con inventario precargado, un perfil nuevo por tipo, sin suerte y semilla 20261111. Se contrastó contra el modelo de la tabla de pesos y el estado de los contadores. Cada celda muestra **observado / esperado**, incluyendo las aperturas forzadas por garantías.

| Cofre | Otros premios (%) | Rara (%) | Épica (%) | Legendaria (%) | Exclusiva (%) |
|---|---:|---:|---:|---:|---:|
| Cofre 1 | 90,095 / 90 | 7,864 / 8 | 1,845 / 1,8 | 0,196 / 0,2 | — |
| Cofre 2 · Reliquia | 76,386 / 76,482 | 11,149 / 11,058 | 10,005 / 9,969 | 2,223 / 2,243 | 0,237 / 0,249 |
| Cofre 3 · Tormenta menor | — | 70,07 / 70 | 25,872 / 26 | 3,551 / 3,5 | 0,507 / 0,5 |
| Cofre 4 · Tormenta mayor | — | 39,919 / 40 | 50,034 / 50 | 9,081 / 9 | 0,966 / 1 |
| Cofre 5 · Tormenta real | — | — | 75,038 / 75 | 22,543 / 22,5 | 2,419 / 2,5 |
| Cofre 6 · Eclipse | — | — | 54,715 / 54,47 | 39,561 / 39,784 | 5,724 / 5,745 |

Las esperas observadas miden el promedio de aperturas desde el inicio o desde el último premio de la categoría hasta el siguiente. Para Eclipse, un perfil con ambos contadores en cero tarda en teoría 2,49 aperturas hasta su primera Legendaria exacta, 2,22 hasta su primera Legendaria o superior y 17,41 hasta su primera Exclusiva. Los ejemplos de unas 25 aperturas en Tormenta menor y unas 4 en Tormenta real corresponden a Legendaria o superior.

| Cofre | Hasta Legendaria | Hasta Legendaria o superior | Hasta Exclusiva | Almas por cofre | Monedas por cofre |
|---|---:|---:|---:|---:|---:|
| Cofre 1 | 500,96 / 500 | 500,96 / 500 | — | 68,93 / 69,39 | 12,18 / 12,2 |
| Cofre 2 · Reliquia | 44,96 / 44,58 | 40,63 / 40,13 | 421,51 / 401,26 | 224,06 / 224,11 | 24,66 / 24,6 |
| Cofre 3 · Tormenta menor | 28,16 / 28,57 | 24,64 / 25 | 197,02 / 200 | 736,63 / 737,13 | 0 / 0 |
| Cofre 4 · Tormenta mayor | 11,01 / 11,11 | 9,95 / 10 | 103,4 / 100 | 957,84 / 958,6 | 0 / 0 |
| Cofre 5 · Tormenta real | 4,44 / 4,44 | 4,01 / 4 | 41,33 / 40 | 1285,63 / 1287,74 | 0 / 0 |
| Cofre 6 · Eclipse | 2,53 / 2,51 | 2,21 / 2,2 | 17,47 / 17,41 | 1403,52 / 1405,05 | 0 / 0 |

Los pagos son brutos y las almas incluyen la conversión de duplicados. La expectativa de almas usa los valores al completar la colección. La mayor desviación relativa fue **5,04 %**, en la espera de Exclusiva en Reliquia. Todas las frecuencias y pagos quedaron dentro del margen del 10 %.

**Pendiente de comprobar en Studio**

- Probar las ventanas de los seis cofres a 375 px y en PC. Revisar recorte de nombres y botones, scroll y selección con mando, miniaturas, legibilidad de los tres idiomas y que el carrusel conserve el premio real.
- Abrir desde la ventana con un cofre propio y con saldo para comprar, ver el paso de una garantía a «próximo cofre» y agotar la suerte con la ventana abierta. Verificar el aspecto del aviso de Exclusiva y el saldo actualizado tras una repetida.
