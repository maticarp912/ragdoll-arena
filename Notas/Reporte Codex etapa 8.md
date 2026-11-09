# Reporte Codex — etapa 8

## Estado final de la entrega de Codex
Implementadas las fases 1 y 2, la corrección de colas/mensajes (nuevo paso 1) y las auras (nuevo paso 2). Comprobación estática final: OK, 61 archivos. No probado en Studio. Las entradas de abajo conservan el detalle de cada fase; este estado final prevalece sobre sus pendientes históricos.
Arenas (fase 4 puntos 1–3): reasignadas a Claude por el usuario. No modifiqué ArenaBuilder.lua, ArenaConfig.lua, Arena.client.lua ni ArenaBackdrop.client.lua. No regeneré Ragdoll Arena.rbxlx. La integración de variantes en MatchService también queda para Claude, coordinando sobre la versión actual con las correcciones de colas y estadísticas.

### Comprobado al finalizar
- node tools/check_lua.js .: OK, 61 archivos; es un chequeo básico, no ejecución de Luau ni prueba de Roblox.
- Verificador estático local: mismas 54 claves en ES/EN/PT-BR, sin duplicados ni coincidencias con claves de LocaleES/EN/PT.
- Catálogo: 10 auras, 6 Body y 4 Weapon, precios de monedas dentro de los rangos solicitados y productos Robux en cero. Todos los nombres/descripciones tienen traducción.
- StatusParams precede a StatusKey y MatchService no escribe Status. HUD actual escucha ambos atributos (lectura del código).
- AuraFx no crea Highlight ni PointLight; PlayerData ya no usa SetAsync.
- Revisión de contratos C2/C3/C7/C8/C9/C10/C11 por lectura; funcionamiento efectivo pendiente de Studio.

### Qué falta realmente
Pruebas de ejecución, persistencia y rendimiento en Studio descritas debajo; ajuste visual de auras contra los modelos finales; integración de la interfaz de Gemini; crear productos Roblox si se venderán las dos auras premium. Ninguna compra premium funciona con productId=0. Claude conserva toda la tarea de arenas y la regeneración/integración del place.


## Fase 1 — implementada; Studio pendiente
PlayerData: UpdateAsync, bloqueo de sesión renovable, save booleano, migración de perfiles anteriores, cierre también en Studio, recibos acotados idempotentes. La concesión se prepara fuera del perfil vivo: si falla la escritura, no se concede ni se confirma. ShopService: validación de depuración, opciones C10, recibos de skins. Debug.client: +1.000, +10.000 y borrado confirmado de compras de prueba. Economy: valores y opciones. LocaleCodex: traducciones.
Comprobado: node tools/check_lua.js . → OK, 54 archivos tras aplicar fase 1. No se abrió Studio.
Pendiente Studio: fallo de API, cierre/reconexión, dos servidores, recibo repetido/fallido, permisos, opciones y botones. Auras se conectan en fase 3.

## Fase 2 — implementada; chequeo básico OK (58 archivos)
Economy centraliza recompensas. StatsService escucha C6 solo entre rivales de la misma partida, publica C7, KillFeed, resumen y Eliminated. MatchService inicia/cierra estadísticas. MissionService: tres misiones diarias deterministas de diez, reinicio UTC y reclamo manual. LeaderboardService: OrderedDataStore, top diez, refresco cada 60 s y fallback de jugadores actuales si falla API. Monedas de clasificación = ganancias históricas por juego/misiones; excluye monedas de depuración. LocaleCodex incorpora todas las claves nuevas en ES/EN/PT-BR.

### Economía
Victoria 220, derrota 65; eliminación 15, derribo 5, máximo 60 extra por partida; primera victoria UTC +120. Misiones 100–130 cada una. Ejemplo: 12 victorias con 1 eliminación y 2 derribos cada una = 2.940; +120 primera victoria +330 de tres misiones = 3.390. Quince victorias con esos mismos eventos y misiones = 4.125. Una Epic de 2.800–4.000 queda aproximadamente entre 10 y 15 victorias según actividad. No se implementa ranked.
Resumen: coins.missions=0 porque el reclamo es manual; coins.total es lo realmente ganado en partida. Campo adicional missionCoinsAvailable indica lo pendiente de reclamar, sin sumarlo al saldo.

### Pendiente de probar en Studio
- API activada/desactivada, persistencia y leaderboard entre servidores.
- Combate con dos/cuatro jugadores: dummies y lobby no suman; caídas sin atacante no acreditan kills.
- Misiones: progreso, reclamo simultáneo/repetido, cambio de día UTC y reconexión.
- Eliminated por muerte/caída y reinicio de ronda; payloads C7/C8/C9 en UI de Gemini.
- Fase 3 pendiente. Arenas reasignadas a Claude por el usuario.

### Pedidos a otros
Claude: integración y pruebas finales; no regeneré el place. Gemini: consumir contratos; las misiones no se cobran automáticamente en MatchSummary. Previsualización de auras irá en el mundo, no ViewportFrame.

## Cambio de reparto y paso 1 — colas y mensajes implementados
La fase 4 puntos 1–3 pasa a Claude: NO modifiqué ArenaBuilder.lua, ArenaConfig.lua, Arena.client.lua ni ArenaBackdrop.client.lua. Claude también debe conectar la selección de variantes en MatchService cuando coordine la integración; esa selección no está implementada por Codex.
MatchService resuelve TODOS los círculos antes de sumar peticiones por botón; una sola lista por jugador, círculo prioritario, petición anterior eliminada al entrar. Rechaza añadir por botón jugadores muertos/sin perfil/en partida. Mensajes de preparación, ronda, derrumbe, punto, empate, victoria, espera y antesala ahora publican StatusParams JSON ANTES de StatusKey. Ya no escribe Status. LocaleCodex añade team.Red/team.Blue y textos ES/EN/PT-BR. Corrección menor de fase 2: la misión de dagas usa WeaponData.Dagger, singular.
Comprobación: lectura del flujo y preparación del chequeo; resultado del chequeo posterior se añade debajo. Studio no probado.
Pruebas para Claude: botón 1v1 + círculo 2v2 y viceversa; salir del círculo no recupera petición vieja; Leave fuera del círculo; muerte/reaparición; mensajes al cambiar idioma y parámetros cuando StatusKey permanece igual. El HUD debe observar StatusParams además de StatusKey.
Falta: fase 3 completa (Auras, AuraFx, Auras.client, integración ShopService/PlayerData y traducciones); pruebas de ejecución de todas las fases. No regeneré el place.

Resultado del paso 1 aplicado: node tools/check_lua.js . -> OK, 58 archivos. HUD actual observa StatusKey y StatusParams; comprobado por lectura. No probado en Studio.

## Paso 2 — fase 3 implementada; chequeo básico OK (61 archivos)
Archivos nuevos: Auras.lua (catálogo y valores), AuraFx.lua (renderer reutilizable C11), Auras.client.lua (ciclo de vida de todos los jugadores). Modificados: PlayerData.lua (compras cosméticas persistidas antes de concesión y equipar aura), ShopService.server.lua (BuyAura/EquipAura/UnequipAura y recibos), LocaleCodex.lua (nombres/descripciones/mensajes trilingües).
Diez auras: seis de cuerpo (corona, eslabones orbitantes, alas, niebla a los pies, ojos que parpadean, runas) y cuatro de arma (humo descendente, brasas, gotas de sangre, fractura luminosa). Precios: Rare 1.500–2.100, Epic 3.600–4.800, alas Legendary 8.000 monedas; ojos/fractura Robux con productId=0 (bloqueadas hasta configurar producto). Precios Robux 399/299 son propuestas de catálogo; el precio real lo define Roblox al crear el producto.
Sin Highlight, cambio de color del arma ni luces. Cuerpo máximo dos emisores/24 partículas por segundo; arma un emisor por modelo, máximo dos incluyendo OffhandWeapon. Geometría de cadenas/ojos/runas y fracturas usa Beam. Carpeta CosmeticAura por objetivo, limpieza al cambiar skin/arma/personaje o salir. Aviso fuerte reduce arma al 25% y cuerpo al 50%; infusión apaga aura del arma; ragdoll/carga reduce al 20% y quita Beam; otros jugadores se reducen al 60% durante partida. Se limpian partículas antiguas al reducir intensidad. preview=true funciona en modelos del mundo.
Compras de auras bloqueadas durante partida y validadas en servidor. Recibo de skin/aura solo se confirma tras persistencia; PurchaseId acotado a 256. Compras de monedas también usan bloqueo y concesión tras guardado; Studio sin API permite compras temporales con aviso explícito. No alteré armas, interfaz ni arenas.

### Pendiente de Studio — auras
- Construir las diez en pedestal del mundo con AuraFx.attach y llamar cleanup al cerrar.
- Equipar en todos los tipos de arma; dagas principal/secundaria; cambiar skin, arma, reaparecer y salir sin residuos.
- Observar las auras de otro jugador; comprobar telegraph, infusión, ragdoll/carga y reducción del 60%.
- Comprobar conteo de emisores y rendimiento en móvil, y afinar visualmente tamaño/orientación con modelos finales de Gemini.
- Comprar sin monedas, comprar repetida, equipar no poseída, comprar/equipar en partida, recibo duplicado/fallido, salir/entrar y productos cero.
### Pedidos a otros actualizados
Gemini: usar Order/Data y nameKey/descKey; vista previa WORLD (no ViewportFrame). Armas requieren BladeBase/BladeTip como Attachments reales. Claude: crea/configura productos si se decide venderlos; valida todo en Studio. Arenas siguen totalmente a cargo de Claude; ningún archivo de arena fue modificado ni se regeneró rbxlx.

### Cierre del paso 2
Chequeo ejecutado después de aplicar: OK, 61 archivos. Verificación estática adicional: 54 claves equivalentes por idioma, 10 auras con distribución y precios correctos, sin IDs inventados. No se abrió Studio; no se afirma validación visual ni funcionamiento en ejecución.

## Ronda 2
### Paso A1 — soporte y peligros
Implementado: eliminada la capa continua de RockStratum del ancho de la arena. Cada losa lleva su soporte SlabRock soldado que cae y se oculta con ella; solo el núcleo estable conserva base fija. Cuñas con espesor inferior reducido 0,08 y desplazamiento 0,04: techo conservado, caras inferiores separadas. El AbyssFloor negro de cliente y sus grietas se retiraron; VoidSurface pertenece al constructor y queda a 65 studs, debajo del umbral de muerte de 18 (sin cambios al daño). Peligros decorativos sin colisión/query/touch.
Causa comprobada por lectura: RockStratum cubría 92% del radio aunque las losas desaparecieran; AbyssFloor además cerraba el fondo negro a 260 studs. Sin Studio no se puede afirmar cuál dominaba la imagen reportada.
Pendiente Studio: derrumbe completo, vista inferior 1v1, bordes sin parpadeo y caída sin apoyo accidental. Variantes preparadas en constructor; selección de partida y ambiente en siguiente paso.

Comprobado paso A1 aplicado: node tools/check_lua.js . OK, 68 archivos.
### Paso A2 — variantes y selección implementadas
ArenaConfig contiene Forest/Canyon/Temple/Hand. ArenaBuilder construye bosque original con vacío de lava; cañón con tres terrazas y púas; templo con columnas, capiteles y marcas geométricas en relieve sobre agua oscura; mano sugerida por cinco dedos articulados, cascadas y cabeza de estatua. Son interpretaciones procedurales de las referencias inspeccionadas, no reproducciones de mallas escultóricas. Conservan centro, spawns, núcleo, sectores, calendario y mecánica de derrumbe. Suelo aclarado y alternado para lectura nocturna.
MatchService rota las cuatro variantes por modo una vez por partida. Destruye geometría anterior, incluidas losas temporalmente sin Parent. Misma variante durante todas las rondas. No toca economía ni colas. ArenaBackdrop añade ArenaTone solo durante InMatch y flujo de cascadas local (3 partículas/s por cascada). No cambia cielo ni iluminación global. No fue necesario editar Arena.client.lua.
Presupuesto: constructor cuenta BaseParts y exige <=2500; publica PartCount y Variant en carpeta de arena. Construye una variante activa por modo. Máximo estimado templo 2v2: 1 núcleo + 320 piezas de losas + 1 base + 1 superficie + 324 de columnas/marcas +24 peligros = 671; muy por debajo del límite. Cero luces nuevas; cinco emisores locales como máximo en Hand. Adornos sin colisión/query/touch.
Pendiente Studio: recorrer cuatro partidas en 1v1 y 2v2; inspeccionar atributos Variant/PartCount, spawns, suelo, cámara en picada y separación de los dedos de la zona jugable; probar cinco derrumbes consecutivos y destrucción entre partidas; revisar lava/agua/cascadas, rendimiento móvil y colisión. No ejecutado en Studio ni regenerado rbxlx.

Comprobado paso A2: node tools/check_lua.js . OK, 68 archivos. Soportes con profundidad creciente hacia el centro para conservar silueta de pirámide invertida fragmentable. Validación de apariencia, conteo real y ejecución aún pendiente de Studio.
### Tarea B — revisión focalizada de solo lectura
Revisados puntos de conexión de Shop, HUD, LobbyUI, Settings, TouchUI, MatchUI y Leaderboards. Es una revisión de código, no prueba de navegación ni auditoría exhaustiva; Gemini sigue editando y puede haber cambios posteriores.
Hallazgos para Gemini:
- TouchUI.client.lua, updateVisibilityAndScale (aprox. 131): solo usa TouchEnabled y MenuOpen. No consulta mando activo ni LastInputTypeChanged: en celular con mando seguirá mostrando botones. Debe ocultarlos al usar Gamepad y liberar Block al ocultar/interrumpir un toque; comprobar cambio táctil/mando durante bloqueo.
- MatchUI.client.lua aprox. 246 y LobbyUI.client.lua aprox. 651: ButtonB exige not processed. El mando puede marcarlo procesado y no cerrar. Shop ya contempla ButtonB incluso procesado; unificar criterio y verificar junto a Controls.
- Resiliencia: requiere UiTheme/UiAssets/Localization con WaitForChild sin límite al comienzo de varias interfaces; si falta alguno, quedan esperando indefinidamente. Los módulos de auras sí tienen carga protegida en Shop, y MatchUI/Leaderboards usan tiempos de espera para sus remotos.
Conexiones observadas: HUD escucha StatusParams/StatusKey y KillFeed; LobbyUI envía Queue Join/Leave y Missions Get/Claim; Settings usa GetOptions/SetOptions y atributos OptMusic/OptSfx; Shop usa pedestal del mundo con AuraFx.attach(preview=true) y encierra foco de confirmación; MatchUI encierra foco del resumen. TouchUI envía InputBridge.press. Pendiente Studio: idioma completo, mando B/foco en todos los diálogos, clasificación sin API y recuperación si módulos/remotos aparecen tarde. No modifiqué ningún archivo de Gemini.
### Cierre Ronda 2
Implementado Tarea A y revisión focalizada Tarea B. Archivos de producto modificados: ArenaConfig.lua, ArenaBuilder.lua, MatchService.server.lua (solo selección), ArenaBackdrop.client.lua. Reporte actualizado; Arena.client.lua y LocaleCodex.lua no necesitaron cambios. No hay texto visible nuevo ni cambios en productos/compras/datos. No regeneré Ragdoll Arena.rbxlx. Claude debe integrar y ejecutar las pruebas de Studio indicadas arriba antes de considerar validada la entrega visual.

## Ronda 3
### Implementado
CityProps.lua: ReplacesBlock[4], taberna/alquimista abierta al este con tejado inclinado, estructura de madera, estantes con 21 frascos, tres frascos colgantes, cartel LocKey, barriles, banquetas y mesa. Santuario en ctx.spawn con 24 piedras y runas, dos árboles retorcidos con musgo, luciérnagas y niebla baja. Cuatro tableros C7 en (±24,-26)/(±24,-54) con atributo Board y cara Front orientada al ángel. Hongos, vegetación, cinco faroles, fuente y conexiones cortas de piedra; sin tocar caminos generales de Claude.
CityLife.client.lua: efectos locales etiquetados CityLife (humo, hojas estilizadas, luciérnagas, niebla, agua de fuente), balanceo de faroles/cartel/frascos y pequeño movimiento del cuervo posado. Una actualización compartida a 20 Hz, solo cerca del jugador y fuera de InMatch; emisores desactivados fuera de alcance, limpieza al retirar etiquetas/objetos. Sin IDs externos.
Referencias inspeccionadas visualmente: 02_lobby_pueblo_noche, 03_lobby_calle_taberna, bar lobby, spawn y ambos ambientes de lobby. Interpretación procedural de sus materiales, vegetación y luz localizada; no mallas escultóricas. Valores numéricos en tablas al inicio. Presupuestos con asserts <=900 BaseParts y <=12 luces; cinco PointLights suaves. PartCount/LightCount publicados en CityDressing.
LocaleCodex: cx.city.tavern en ES/EN/PT-BR. Solo cuatro archivos autorizados modificados. No se tocó LobbyBuilder ni se regeneró rbxlx.
### Comprobado
Gancho de LobbyBuilder y ctx leídos; floorTop es relativo a origin. Pendiente chequeo tras aplicar.
### Pendiente Studio
Claude: integrar y comprobar que CityProps no avisa errores; verificar PartCount/LightCount; recorrer spawn sin colisión ni bloqueo central, plaza/tableros legibles, paso >=8 studs; comprobar entrada de taberna, tejado y estantes desde el este, ausencia de caras coplanares, fuente y caminos en combinación con cambios de Claude. Ver etiquetas C7 y textos al cambiar idioma. Probar movimiento cerca/lejos, streaming, respawn, InMatch y rendimiento móvil. Utilería no colisiona excepto paredes/mostrador; armería y colas sin cambios.

Resultado del chequeo aplicado: node tools/check_lua.js . -> OK, 70 archivos. Ajuste final: las dos hileras de piedras se separan perpendicularmente al camino, evitando superposición en tramos este-oeste. No se ejecutó en Studio; presupuestos comprobables en ejecución mediante atributos y asserts, sin afirmar conteos medidos.

## Ronda 4
### Tarea 1 — implementado
HUD: corregido color inexistente DamageTrail -> HealthTrail que interrumpía la primera columna; inicio oculto, sin activar combate por la lectura inicial de vida; HitAt y pérdida de vida activan HUD, fade de ocho segundos; StaminaMax reactivo. Dock Armería usa ToggleMenu; RANKED traducible y etiqueta delante del fondo. Preview de aura: cámara actualizada después de la cámara normal, personaje visible sin transparencia local, composición a la derecha y panel a la izquierda; se retira recuadro de pedestal y se restauran cámara y transparencias al cerrar/cambiar pestaña. Precarga usa instancias Sound e ImageLabel, excluye animaciones y no finaliza por temporizador antes de completar (Saltar sigue disponible).
Comprobado: revisión de código; chequeo posterior pendiente. Studio pendiente: cinco columnas/atributos, ocho segundos de fade, golpear muñecos, tres dispositivos, cuatro botones dock, RANKED legible, preview Body/Weapon y cerrar/reabrir/respawn, precarga sin errores de tipos.

Tarea 1 comprobada: node tools/check_lua.js . OK, 70 archivos.
### Tarea 2 — implementado
Se sustituyen conexiones cortas por adoquines irregulares en calle principal (-120 a 146), cruzada hacia cementerio/taberna y práctica, anillo y aproximaciones de plaza, con canteros de flores. Alturas locales: principal 0,05; cruzada 0,11; plaza ctx.floorTop; pequeño relieve no colisionable. Sin adoquines en antesala/colas ni puesto de armería; curva suave dentro de la calle. Presupuesto CityProps aumentado a 1400 con assert.
Pendiente Studio: continuidad con caminos generales que Claude modifica, paso libre, intersecciones, altura y superposiciones; conteo real. Chequeo posterior pendiente.

Tarea 2 comprobada: node tools/check_lua.js . OK, 70 archivos.
### Tarea 3 — implementado
CityNPCs.lua expone start(cityFolder,ctx), idempotente por ciudad. Crea cinco rigs R15 con HumanoidDescription, capa/hood o delantal, rutas con Humanoid:MoveTo y pausas frente a taberna/fuente; animación simple de articulaciones sin IDs. Sin Combatant. Grupos CityVillagers/CityVisitorBodies: NPCs no chocan entre sí ni con cuerpos de visitantes, pero conservan colisión con suelo Default. Partes de jugador que eran Default pasan a CityVisitorBodies; grupos personalizados se preservan y se desactiva su colisión con NPCs. Revisar interacción con otras mecánicas físicas antes de publicar. Si falla creación R15, avisa en salida sin detener la ciudad.
CityLife agrega cuatro cuervos de vuelo circular con alas y seis banderines locales ondulantes. Ocultos lejos/fuera de ciudad/en partida. Solo utilería cliente; no física ni scripts de combate. No se agregó gato (opcional).
Pendiente Studio: Claude debe conectar CityNPCs.start(cityFolder,ctx); no se tocó LobbyBuilder. Probar cinco NPCs R15, movimiento, pausas, colisiones con jugadores y suelo, ausencia de lock-on/daño, rutas sin atascarse, vuelo/banderines cerca/lejos y rendimiento móvil. Si modelos R15 no se crean por API, revisar aviso antes de integrar beta.

### Cierre Ronda 4
Chequeos después de tareas 1/2/3: OK, respectivamente 70/70/71 archivos. Bordes de pasto añadidos fuera del corredor central y santuario. Salud finita alta para pueblerinos; exclusión del combate depende de no tener Combatant (validar en Studio).
Implementado en archivos autorizados; ningún archivo de arenas/combate/UiTheme/UiAssets ni LobbyBuilder fue modificado, no se regeneró rbxlx. No se ejecutó Studio en esta sesión. Claude: conectar CityNPCs, ejecutar checklist de cada tarea y revisar apariencia/posiciones con los cambios paralelos; el chequeo básico no prueba navegación, física, cámara ni carga real de assets.

## Ronda 6 — revisión técnica previa a beta, solo lectura

### Alcance y comprobaciones
Leídas reglas y sección B de Tareas ronda 6 y Referencia LihFolk. Revisados los seis handlers: Input, Debug, Shop, Settings, Queue y Missions; guardado/recibos, estadísticas/partida, carga cliente, auras y vida de ciudad. No se repiten como fallos los tipos action de Queue/Missions/Settings ni el guardado diferido saveSoon que Claude ya corrigió.
- LihFolk ejecutado PRIMERO con -Scan ServerScriptService ReplicatedStorage StarterPlayer ReplicatedFirst desde el proyecto: **71 archivos, 0 errores, 0 avisos, 0 info**.
- node tools/check_lua.js .: **OK, 71 archivos**.
- Consultadas las cinco skills indicadas y sus notas de apoyo: se usaron Checklist y Common mistakes de Rate Limiting and Abuse Prevention, Session Locking and Profile Libraries, Purchase Data and Receipts, Economy Exploits - Dupes Races and Purchase Abuse y Memory Budgets and Leaks. Las notas Skill son índices; las listas Checklist están en las notas temáticas. No se copia contenido de las guías al vault: abajo solo títulos citados y análisis propio del proyecto.
- git status --short devolvió «this operation must be run in a work tree» en este entorno. No se modificó configuración de Git, ramas ni commits. Otros agentes trabajan en paralelo; líneas corresponden a esta lectura, confirmar al integrar.
- No se editó ningún archivo de código ni se regeneró el place. Única entrega: esta sección. Revisor heurístico limpio no equivale a beta validada.

### Hallazgos ordenados por gravedad

#### 1. P1 — Studio escribe el mismo perfil que producción
**Archivo/línea:** ServerScriptService/PlayerData.lua:24; ServerScriptService/PlayerData.lua:104; ServerScriptService/ShopService.server.lua:28 y :100.
**Problema:** el nombre RagdollArena_v2 y las claves u_UserId se usan también en Studio. Con API activada, monedas gratuitas/reset de compras de prueba se guardan en el perfil real. LeaderboardService.lua:11 también usa nombres productivos para OrderedDataStore. No es una fuga por sí misma, pero permite alterar datos reales durante pruebas rutinarias.
**Arreglo propuesto:** separar namespace/perfil y clasificaciones Studio/beta/producción antes de probar guardado. Mantener la prueba de persistencia en un entorno aislado; no migrar automáticamente compras de test al real.
**LihFolk:** «Session Locking and Profile Libraries», Checklist; «Skill - Roblox DataStore Safety», aislamiento de Studio.
**Verificación pendiente:** misma cuenta en Studio y servidor privado, confirmar claves distintas sin tocar saldo productivo.

#### 2. P1 — fallo del guardado final descarta la única copia en memoria
**Archivo/línea:** ServerScriptService/PlayerData.lua:122, :136, :278 y :284.
**Problema:** persist hace un único intento. PlayerRemoving ignora false de save y borra cache/writable de todas formas. Una recompensa posterior al último autosave puede perderse si falla la escritura al salir. BindToClose tampoco reintenta según resultado y su espera no tiene plazo explícito; la espera del mutex puede consumir el tiempo de cierre.
**Arreglo propuesto:** reintentos acotados con backoff/jitter, plazo común de cierre, cola de finalización y observabilidad del fallo; conservar snapshot hasta agotarlo y no anunciar persistencia antes de confirmarla. Autosaves escalonados y control de presupuesto.
**LihFolk:** «Skill - Roblox DataStore Safety»; «Session Locking and Profile Libraries», Checklist.
**Verificación pendiente:** inyectar fallo transitorio de UpdateAsync solo en entorno de prueba; salir con recompensa pendiente y volver.

#### 3. P1 — Shop permite reconstrucciones caras sin límite por jugador
**Archivo/línea:** ServerScriptService/ShopService.server.lua:69, :115, :137; refreshWeapon en :63. DebugRemote en ServerScriptService/CombatService.server.lua:120.
**Problema:** SelectWeapon/Equip vuelven a ejecutar Combat.setupCharacter incluso si la selección no cambia, sin bucket ni estado ocupado. Un cliente puede forzar reconstrucciones repetidas de armas/personaje. Las compras y prompts de Shop tampoco tienen límite inicial; el mutex de PlayerData serializa la compra, pero no limita tareas esperando. Debug también ejecuta reset/spawn/trabajo de arena sin frecuencia, aunque sí está restringido por permisos (menor alcance).
**Arreglo propuesto:** limiter por jugador/acción fija antes del trabajo, ignorar selección ya activa y mutex para refresh; limitar cola de peticiones y prompts. Mantener lista de permisos de Debug y añadir su propio bucket, limpiando al salir.
**LihFolk:** «Rate Limiting and Abuse Prevention», Checklist/Common mistakes; «Skill - Roblox Secure Remotes»; «Skill - Roblox Anti-Exploit Review».
**Verificación pendiente:** pruebas controladas de spam en Studio, comprobar coste y estado final. No se realizó prueba ofensiva ni se generaron scripts de explotación.

#### 4. P2 — salida durante load puede publicar un perfil huérfano
**Archivo/línea:** ServerScriptService/PlayerData.lua:82, :104, :119 y :278.
**Problema:** load cede durante UpdateAsync/reintentos. Si el jugador sale antes de que cache exista, PlayerRemoving no guarda nada. Si luego termina load, vuelve a añadir cache y writable para un Player que ya salió; no vuelve a dispararse PlayerRemoving ni el autosave lo visita (recorre Players). El lease queda hasta expirar y retiene referencias; puede impedir una reconexión inmediata. En un mismo servidor el token es común a todos los perfiles/cargas, de modo que también conviene evitar dos cargas simultáneas del mismo UserId.
**Arreglo propuesto:** estado loading/cancelado por UserId y token de carga; comprobar presencia tras cada yield y liberar el lease recién adquirido si la carga fue cancelada. No publicar cache para jugador desconectado; impedir cargas dobles.
**LihFolk:** «Session Locking and Profile Libraries»; «Memory Budgets and Leaks», Checklist.
**Verificación pendiente:** retrasar carga artificialmente y desconectar/reconectar durante ella; confirmar liberación y eliminación de referencias.

#### 5. P2 — lease perdido no bloquea mutaciones posteriores
**Archivo/línea:** ServerScriptService/PlayerData.lua:122, :136, :240 (get/isPersistent y mutadores); ServerScriptService/MissionService.lua:57; ServerScriptService/StatsService.lua:40.
**Problema:** la escritura rechaza un token ajeno, pero no marca la sesión como perdida ni desactiva writable. Tras una transferencia por expiración, el servidor viejo puede seguir entregando recompensas en memoria e indicar progreso que nunca podrá guardar. No significa que pueda sobrescribir al dueño nuevo: el fencing de la escritura sí existe.
**Arreglo propuesto:** distinguir guardado transitoriamente fallido de lease perdido; marcar estado lost, negar nuevos cambios de valor y finalizar/reconectar de forma controlada. Renovación escalonada sin esperar a guardar todos los jugadores en serie.
**LihFolk:** «Session Locking and Profile Libraries», Checklist; «Economy Exploits - Dupes Races and Purchase Abuse», Checklist.
**Verificación pendiente:** simular expiración y adquisición por segundo servidor de prueba.

#### 6. P2 — vectores infinitos y objetivos fuera del conjunto esperado
**Archivo/línea:** ServerScriptService/CombatService.server.lua:27 y :53.
**Problema:** validDir rechaza NaN de X/Z, pero acepta infinitos; f.Unit puede producir componentes no finitos que pasan a dodge/throw. validTarget comprueba Model, raíces, humanoide y distancia, pero no pertenencia a Workspace/Combatant ni enemigo/misma partida. El comentario promete un combatiente; el handler permite también pueblerinos cercanos como referencia de dash. No se demostró daño a NPCs por este camino.
**Arreglo propuesto:** componentes finitos y módulo acotado antes de normalizar; validar descendencia, etiqueta, salud y contexto del objetivo contra la política de lock-on del servidor. Input ya tiene límite 30/s: conservarlo.
**LihFolk:** «Skill - Roblox Secure Remotes»; «Skill - Roblox Anti-Exploit Review», validación de objetos/física.
**Verificación pendiente:** valores límite y objetivos ajenos en harness local de Studio, sin datos productivos.

#### 7. P2 — desconectarse omite el cierre estadístico de la partida
**Archivo/línea:** ServerScriptService/StatsService.lua:60; ServerScriptService/MatchService.server.lua:332, :405 y :421.
**Problema:** la ronda deja de contar al desconectado (bien), pero StatsService borra active al salir y MatchService solo finaliza jugadores con Parent. No queda partida/derrota en sus totales ni progreso de Match; en 1v1 se resuelven las rondas restantes contra un equipo vacío, y en 2v2 el compañero sigue solo. Es una decisión incompleta de abandono, no un bloqueo demostrado de la cola. Puede sesgar las estadísticas por abandonar antes del resultado.
**Arreglo propuesto:** definir abandono antes de beta: cerrar registro y persistir una sola vez antes de liberar perfil, sin monedas gratis por salir; terminar por forfeit si no queda equipo, permitir al compañero seguir si se desea. Coordinar orden PlayerRemoving con PlayerData y evitar doble finish.
**LihFolk:** «Economy Exploits - Dupes Races and Purchase Abuse», Checklist; «Skill - Roblox Anti-Exploit Review».
**Verificación pendiente:** salir en cola, cuenta atrás, primera ronda y última ronda con 2/4 clientes; revisar arena, resumen de quienes siguen, premio único e InMatch.

#### 8. P2 condicional — precios premium estáticos antes de habilitar productos
**Archivo/línea:** StarterPlayer/StarterPlayerScripts/Shop.client.lua:165; ServerScriptService/ShopService.server.lua:162 y :170.
**Problema:** priceText muestra item.price sin obtener precio efectivo de MarketplaceService. Con productos actuales en cero la compra está bloqueada: no es un cobro incorrecto activo. Al configurar productos, la etiqueta puede diferir del diálogo de Roblox. Además el mapa de skins sobreescribe IDs repetidos y el de auras solo advierte colisión contra skins, sin comprobar duplicados dentro de auras.
**Arreglo propuesto:** precio desde información del producto, cacheado con estado no disponible; validar unicidad del catálogo al arrancar y mantener handlers para productos retirados. Confirmar catálogo de Creator Dashboard antes de habilitar venta.
**LihFolk:** «Skill - Roblox Monetization Compliance»; «Purchase Data and Receipts», Checklist. Se cita criterio de diseño de la guía, no se certifica cumplimiento legal ni políticas actuales.
**Verificación pendiente:** producto de prueba válido, precio por cuenta/región y correspondencia ID-recompensa. No se consultó Dashboard.

#### 9. P3 — búsqueda recursiva de ciudad se mantiene fuera del lobby
**Archivo/línea:** StarterPlayer/StarterPlayerScripts/CityLife.client.lua:76 y :79; ServerScriptService/LeaderboardService.lua:8 y :27.
**Problema:** CityLife recorre Workspace con FindFirstChild(...,true) cada 0,08 s incluso en partida/lejos de la ciudad. El cache names de LeaderboardService retiene cada jugador visto durante la vida del servidor sin tope ni limpieza. Son riesgos de coste/crecimiento; no se midió lag ni pendiente de memoria, por lo que no se afirma una fuga grave.
**Arreglo propuesto:** conservar referencia a CityDressing con invalidación/streaming y saltar consulta antes si InMatch; cache de nombres acotada con TTL/LRU. Perfilar antes de decidir más cambios.
**LihFolk:** «Memory Budgets and Leaks», Checklist/Common mistakes; «Skill - Roblox Performance Audit».
**Verificación pendiente:** sesión de 15 minutos en teléfono real y ciclos de respawn/menús/auras; medir tiempo de frame y pendiente de memoria, no solo FPS de Studio.

### Puntos comprobados sin hallazgo nuevo
- Búsqueda de requires directos a hijos en cliente/ReplicatedStorage: los módulos encontrados del runtime usan WaitForChild. Los require(RS.Economy) de Stats/Mission/Leaderboard son servidor; no se reportan como carrera de replicación cliente. No se certifica toda carga por esta búsqueda.
- Auras.client limpia efectos/conexiones por personaje y jugador; AuraFx devuelve cleanup y desconecta Heartbeat. No se observó duplicación evidente en ese ciclo por lectura.
- Recibos: una sola asignación ProcessReceipt; grant y PurchaseId se guardan juntos, y PurchaseGranted se devuelve después de persistencia. Lista acotada; resetTestPurchases conserva Receipts. No se confirma una duplicación de Robux. Sigue pendiente prueba de recibo repetido/fallo concurrente en sandbox.
- Missions marca claimed antes de conceder sin yield en ese tramo; no se encontró doble cobro directo por reclamo simultáneo. Get sin bucket tiene coste acotado a tres misiones; menor prioridad que reconstrucción de Shop.
- Controles táctiles existentes usan InputBridge y mando tiene rutas alternativas. No se encontró aquí una acción esencial exclusivamente de ratón; navegación efectiva y retención de Block requieren pruebas en móvil con mando. No se probó Studio en esta revisión.

### Implementado / comprobado / pendiente
**Implementado:** únicamente este informe, sin correcciones de código por instrucción de solo lectura.
**Comprobado:** revisión estática y referencias originales, escaneo LihFolk limpio y check_lua limpio.
**Pendiente:** Claude debe priorizar 1–3 antes de beta; ejecutar pruebas aisladas indicadas y volver a pasar ambos revisores tras los cambios. No dar por corregido un hallazgo solo por desaparecer un aviso heurístico.

## Ronda 7 — integración de beta
### Tarea 0
Revisado diff Gemini: cambios limitados al bloque de edificios y torre del reloj y CityConfig. Ganchos de CityProps/CityNPCs, suelo, puerta, guía, colas y armería sin cambios. Integrado tal cual en commit 311092c. El presupuesto ~2250 reportado por Gemini no fue medido en Studio por Codex; se comprobará allí, al igual que caras coplanares.
### Tarea 1
Todo el catálogo pasa a monedas: Requiem 3400 (Epic); WatchingEyes 8500 y PaleFracture 7800 (Legendary); también Cyber 1600 y Blood 2400, dos recolores antiguos que seguían en Robux. ProductId permanece cero y ProcessReceipt intacto. La tienda usa color/iconografía de monedas y deja de bloquear estos artículos por no tener producto. Pendiente Studio: compra, confirmación y equipamiento de los cinco.

### Tarea 2 — guardado, tienda y remotos
Nombres de DataStore/OrderedDataStore separados para Studio en Economy. Guardado final hasta cuatro intentos con espera creciente, mutex compartido de finalización (salida/cierre), aviso con UserId al fallar y plazo global de cierre de 25 s; no se borra cache hasta terminar. Una llamada UpdateAsync ya iniciada no se puede cancelar; el coordinador de cierre deja de esperar al vencer el plazo. Cargas canceladas no publican cache y liberan su propio lease; tokens por carga evitan que una reconexión sea liberada por la carga anterior. ShopRF: 0,25 s por jugador, un request en curso, limpieza al salir y selección repetida sin reconstrucción. DebugRemote: 0,25 s. validDir rechaza NaN, infinitos y magnitud >1000; validTarget exige Workspace y Combatant. Textos nuevos trilingües.
Referencias de diseño: Session Locking and Profile Libraries; Purchase Data and Receipts; Rate Limiting and Abuse Prevention (LihFolk). Pendiente pruebas de fallos y concurrencia en entorno aislado de Studio.

### Tarea 3 — comprobado y entrega
- node tools/check_lua.js .: OK, 71 archivos.
- LihFolk -Scan ServerScriptService ReplicatedStorage StarterPlayer ReplicatedFirst: 71 archivos, 0 errores, 0 avisos, 0 info (repetido tras los ajustes finales).
- git diff --check sin errores. Commits separados: 311092c integración Gemini; b3df317 catálogo de monedas; e8175eb guardado/tienda/remotos. Esta comprobación/documentación se registra en el cuarto commit.
- Verificación estática adicional: ningún artículo Skins/Auras con currency Robux; Shop.client sin referencias Robux; claves de LocaleCodex simétricas ES/EN/PT-BR; XML generado contiene stores Studio, reintentos, wrapper Shop y nueva traducción.
- Regenerado Ragdoll Arena.rbxlx con make_rbxlx: 71 scripts, aproximadamente 1161 KB. El place es local y sigue excluido por .gitignore a propósito; GitHub recibe fuentes/generador/notas, no se fuerza la subida de un artefacto ignorado.
- No se abrió Studio durante esta ronda. Check_lua y LihFolk son estáticos: no prueban escrituras reales de DataStore ni navegación/combate.

### Pruebas que debe hacer el usuario en Studio
1. Abrir el Ragdoll Arena.rbxlx REGENERADO (cerrar la versión anterior). Play solo: revisar Salida; recorrer ciudad, tejados, puertas, armería y NPCs. Confirmar que no hay parpadeo ni calles obstruidas. El conteo ~2250 de edificios proviene del reporte de Gemini, no de una medición de Codex: medir Buildings en Workspace y confirmar <=3500 antes de aprobar el arte.
2. Menú P: sumar monedas; comprar Requiem, WatchingEyes y PaleFracture con monedas. Revisar también Cyber/Blood. Nada debe mostrar precio/icono/botón Robux ni abrir una compra de Roblox. Comprar sin saldo y comprar repetida: sin saldo negativo ni concesión duplicada; equipar/probar aura y cerrar tienda restaura cámara.
3. Con API Services habilitada: salir/reentrar y confirmar monedas/equipamiento/opciones. Studio ahora comienza con otro perfil y clasificación: no esperar ver los datos de producción. Comprobar nombres *_Studio sin editar las claves reales.
4. Prueba controlada de fallo de persistencia, en entorno aislado: salida y cierre con recompensa pendiente; confirmar reintentos, recuperación ante fallo transitorio y aviso con UserId si se agotan. Salir mientras carga un perfil: reconectar y confirmar que la carga anterior no deja lease ni publica cache. El cierre coordinado deja de esperar a 25 s, aunque una llamada de servicio ya iniciada puede seguir suspendida hasta el límite del motor.
5. Seleccionar repetidamente arma/infusión/skin ya equipadas: no rehacer personaje. Cambiar normalmente con pausa; pulsar rápido: rechazo temporal traducido, sin bloquear permanentemente la tienda. Confirmar límites de Debug sin perjudicar acciones normales.
6. Servidor y dos clientes: partida 1v1 completa, rondas/derrumbes, resultado y monedas una sola vez, vuelta al lobby; probar bloqueo, dash con objetivo y agarrar/lanzar. NPCs no deben ser objetivos de dash/lock-on. Si se ensayan entradas inválidas, hacerlo solo en harness de Studio sin datos reales.
7. Device Simulator iPhone y mando: dock, RANKED, HUD cinco columnas, tienda, auras, ajustes e idiomas; botones táctiles ocultos al usar mando y B vuelve correctamente. Repetir en teléfono real para rendimiento (15 min); el simulador no certifica fluidez.

### Pendientes explícitos después de beta
Se mantienen los hallazgos 5 (estado lease perdido), 7 (abandono estadístico), 8 (precios reales/unicidad de productos si vuelven Robux) y 9 (coste/cache CityLife y nombres). La separación implementada es Studio/live; una beta publicada usa el namespace live actual. No afirmar que existe un tercer entorno beta independiente.
