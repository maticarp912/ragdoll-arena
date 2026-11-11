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
