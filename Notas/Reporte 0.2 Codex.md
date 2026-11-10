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

