# Versión 0.2 (pedidos del 9/11, después de publicar la beta)

Contexto: [[Indicaciones para las IA]], [[Peticiones del usuario]], [[Equilibrio de armas]]. Lo que seguía abierto de la beta está en la sección 8 (historia en `Archivo 0.1/`).
La beta 0.1 está publicada: «[BETA] Dark Fantasy Plataforme 2v2 1v1 PVP», de PapuDoNacimento. Se probó con el hermano (Mateito) en celular.
Leyenda (revisada el 10/11 22:50): ✅ hecho y comprobado (en Studio o jugando el usuario) · 🔍 en revisión (implementado, falta probar o ajustar) · 🔧 en curso · ⬜ falta agregar · 👤 lo hace el usuario.

## Estado al 10/11/2026 22:50 (revisión de Claude)
**✅ Hecho y comprobado:** HUD nuevo, combate direccional (lo jugó el usuario), previa de 10 s, cinemática de entrada, roles y Owner, eventos de sensación del combate, colección y maestría (al usuario le gustó).
**🔍 En revisión (implementado, falta probar o ajustar):**
- Combate: golpe animado según la dirección, espadón y maza más rápidos con contragolpe, patada más larga, whoosh del dash.
- Skins de la 0.1 de vuelta, Eclipse Carmesí en las 5 armas y rayos solo para semanales.
- Tienda: vista previa de auras y pestaña Almas solo para testers.
- Punto doble, niveles, cajas, ruleta, panel de administración, migración del perfil (Schema 2).
- Celular: editor de botones y cámara (solo emulador).
- Sin probar todavía: 2v2, mando y teléfono real.
**👤 Opinión del usuario (10/11 23:59):** «el juego se ve bien en todo» y «en general ya está todo listo». Lo único que marcó fueron los tirones en la tienda y el mouse.
**🔍 Nuevo, sin probar (23:59):** tienda, armería y recompensas sin tirones (sin CanvasGroup); tres cajas de Tormenta con las 36 skins con rayos; tipografía nueva; anclado al piso (no subirse encima).
**✅ Revisión final de Codex hecha e integrada (11/11 00:40):** ver [[Integración 0.2]]. Falta probar en Studio lo que lista.
**⬜ Falta agregar:** sangrado de dagas, animaciones de captura para dagas y estoque, Arena de la Mano, clasificatorias con Elo, tableros en la plaza, ciudad estilo pueblo, cielo, mallas de Blender (decidir si se rehacen con los diseños de la 0.1), revisión de seguridad de la ronda 3.
**👤 Usuario:** UserId de Mateito, ícono y miniatura de la página, instalar Rojo (opcional), subir mallas cuando se decida.

## 1. Bugs vistos en la beta
| Pedido                                              | Detalle                                                                                                                                                                                                                                                    | Resp. sugerido | Estado |
| --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------ |
| Punto doble cuando caen los dos                     | Si los dos caen de la arena, hoy cada uno suma un punto. Tiene que ganar **el que cae segundo**. Hoy `MatchService` trata `alive.Red == 0 and alive.Blue == 0` como empate: guardar el orden de eliminación y darle la ronda al equipo del último en caer. | Codex          | 🔍 gana el último en caer (Codex); 11/11: si un equipo abandona, termina la serie. Falta probar caídas simultáneas y 2v2 |
| Cámara rota en celular al fijar objetivo en partida | En el teléfono la cámara se traba o salta con el fijado automático. Revisar `Controls.client` (fijado, órbita y joystick táctil) y probar en teléfono real.                                                                                                | Claude         | 🔍 ✅ en el emulador; falta teléfono real (Mateito) |

## 2. Celular (prioridad alta: el hermano juega en celular)
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Mejor soporte para celular | Botones más grandes y separados. Textos legibles en la Armería (hoy son muy chicos). Menús escalados a la pantalla. Revisar zonas seguras (notch). | Gemini | 🔍 Gemini ronda 2: botones más grandes, zona segura; falta teléfono real |
| Controles a preferencia | Mover y escalar los botones táctiles con un editor de diseño en Ajustes, guardado en el perfil. Ya existen controles reasignables para teclado y mando (`InputMap`). | Gemini (interfaz) + Codex (guardado) | 🔍 editor de botones táctiles en Ajustes y guardado (`SetTouchLayout`); falta probar en teléfono |

## 3. HUD en partida (captura del usuario)
- **Barra de vida grande y horizontal** abajo al centro (zona roja de la captura).
- **Barra de infusión** justo encima (zona amarilla).
- El panel vertical de abajo a la derecha queda solo para resistencia, guardia y aturdimiento, o se rediseña completo.
- Responsable sugerido: Gemini. Estado: ✅ HUD nuevo de Gemini (ronda 2); al usuario le encantó (10/11).

## 4. Sensación del combate (prioridad alta)
«No se siente lo suficientemente bien pegar o recibir un golpe.»
- **Ritmo más lento:**
  - animaciones más largas y exageradas: más anticipación, golpe marcado, seguimiento;
  - subir `duration` y `hitTime` en `WeaponData` de forma pareja, para no romper el equilibrio (ver [[Equilibrio de armas]]).
- **Que se distinga cada situación:**
  - **Pegar:** pausa de impacto corta (hit-stop) para el atacante, chispa y sonido grave, temblor leve.
  - **Recibir:** retroceso marcado, destello rojo en el borde de la pantalla, sonido de carne o armadura, temblor más fuerte, animación de dolor exagerada.
  - **Bloquear:** chispa metálica clara, sonido de metal contra metal, empuje corto hacia atrás, la barra de guardia parpadea y una pose de bloqueo más marcada.
  - **Romper guardia / parry:** efectos únicos, cámara lenta breve.
- Responsable: Claude (animaciones, efectos y sonido). Guías: LihFolk `lihfolk-vfx` (impactos, hit-stop, temblor) y `lihfolk-sfx`. Estado: ✅ eventos de sensación comprobados en Studio (hit-stop, borde rojo, destellos). 🔍 Falta que el usuario diga si ya se siente bien. Ver [[Reporte 0.2 Claude]] y [[Reporte 0.2 Integración]].

## 5. Roles y administración
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Roles | Owner, Admin, Mod, Tester, VIP, Nuevo, etc. Etiqueta con color sobre la cabeza y en el chat. El rol se decide en el servidor por lista de UserIds (en un módulo de datos), y «Nuevo» por las horas jugadas. | Codex | ✅ roles en el servidor y etiqueta sobre la cabeza (Studio); 👤 falta el UserId de Mateito |
| El Owner tiene todo | El Owner (PapuDoNacimento) tiene todas las armas, skins y auras sin comprarlas. | Codex | ✅ comprobado en Studio con el gancho `StudioOwnerUserId` |
| Panel de administración | Solo Owner y Admin. Buscar un jugador y darle monedas, armas, skins, auras, nivel o rol. Todo se valida en el servidor y queda registrado (quién dio qué a quién). | Codex (servidor) + Gemini (interfaz) | 🔍 abre y responde en Studio; 11/11: cupo por hora de cajas y tiros. Falta volver a probar los campos escribiendo |
## 6. Progresión
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Sistema de niveles | XP por partida, victoria, eliminación, derribo y misión. Curva de nivel en un módulo de datos. Nivel visible en el HUD y sobre la cabeza. Recompensas por nivel (monedas, cajas). | Codex | 🔍 niveles 1 a 100 y recompensas (Codex); falta probar la curva y la migración del perfil (Schema 2) |
| Cajas de suerte | Se abren con monedas del juego (sin Robux por ahora). Dan multiplicadores temporales de XP y de monedas (×1,5, ×2, ×3 por X minutos), y a veces skins. Probabilidades visibles en la caja. Si algún día se venden con Robux, hay que cumplir las reglas de Roblox para premios al azar pagos (ver la guía `roblox-monetization-compliance`). | Codex (servidor) + Gemini (interfaz y animación de apertura) | 🔍 suspenso al abrir (el usuario no marcó problemas). 23:59: tres cajas de Tormenta (3000 / 6500 / 12000) con las 36 skins con rayos |
## 7. Publicación
- 👤 La página del juego todavía muestra el ícono gris de Roblox. Hay que subir el ícono y la miniatura: el usuario ya tiene un arte «Dark Fantasy 1v1 · 2v2 PvP». Se suben en Creator Dashboard → la experiencia → Places/Thumbnails.
- 👤 Pasar el UserId de Mateito para darle el rol Tester.

## 8. Pendientes que vienen de la 0.1
| Pendiente | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Cámara de espectador en 2v2 | Probar con 4 jugadores. También el arreglo de «vivo» (`Eliminated` + estado Dead). | Claude | 🔍 falta una partida 2v2 con 4 clientes |
| Botón B del mando | Que cierre los menús. Probar con un mando real. | Claude | 🔍 falta probar con un mando real |
| Animaciones de dagas y estoque | Siguen siendo procedurales. Pasarlas a captura de movimiento como las demás. | Claude | ⬜ siguen procedurales (ahora con el golpe por dirección) |
| Sangrado de las dagas | La Doble Estocada dice «sangrado», pero el efecto no está hecho. | Claude | ⬜ no está hecho |
| Equilibrio | Matriz y cambios a probar en [[Equilibrio de armas]]:
- estoque: fallar gasta más resistencia;
- dagas: más tiempo entre el golpe 2 y el 3;
- maza: barrido más ancho o seguimiento del rival.

Revisar con datos de la beta.

Pedido del 10/11 (habló con Gemini Pro):
- más alcance;
- reforzar la maza;
- bajar dagas y estoque;
- que las armas grandes no se sientan débiles.

Números propuestos en [[Equilibrio de armas]] («Propuesta de números para la 0.2»), aprobados (D3) y aplicados en `WeaponData`. 10/11: espadón y maza más rápidos y con contragolpe de peso. | Claude | 🔍 sin probar en partida |
| Arena de la Mano | Fuera de la rotación porque no se entiende como mano. Rehacerla. | Gemini (Argon) | ⬜ |
| Revisión de Codex, ronda 6 | Pendientes: hallazgo 5 (sesión perdida), 7 (estadísticas al abandonar una partida), 8 (precios reales si vuelve Robux) y 9 (rendimiento de `CityLife` y de la caché de nombres). | Codex | ✅ 5, 7 y 9 ya resueltos; 8 (recibos) arreglado; precios de Robux para cuando vuelva Robux |
| Cielo | Más estrellas usando imágenes de cielo (6 caras), si hace falta. | Claude | ⬜ |
| Rojo | Cambios en vivo en Studio sin regenerar el place. | Claude | 🔍 `default.project.json` creado; 👤 falta instalar Rojo (CLI y plugin) |
| Robux | Productos y precios reales, más adelante. | 👤 + Codex | ⬜ la 0.2 es sin Robux; el paquete de tiros con Robux queda preparado con `productId = 0` |
| Ciudad estilo pueblo RPG | Estilo general y caminos de `referencias/02_lobby_pueblo_noche` (la utilería de Codex ya está). | Claude | ⬜ |
| Tableros de clasificación en la ciudad | El servidor y el dibujo existen; falta ubicarlos en la plaza. | Claude | ⬜ |
| Espadones con las animaciones | Probar agarre, estela y que no atraviesen el cuerpo. | Claude | 🔍 ahora el espadón usa el tajo de captura según la dirección; probar agarre y estela |
| Sonidos | El usuario escucha los SFX jugando y dice qué ajustar. | 👤 + Claude | 🔍 10/11: dash con un whoosh nuevo; el usuario sigue escuchando y avisando |
| Hachas como sexta arma | Idea de la etapa 8, para otra versión. | — | ⬜ para otra versión |

## 9. Ideas del usuario
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Cinemáticas antes del combate | Presentación de los jugadores al entrar a la arena: cámara recorriendo la arena, nombres, armas y pose de entrada. Se hace en el motor (cámara + animaciones), porque tiene que mostrar el avatar, el arma y la skin reales de cada jugador. Opinión de Claude (10/11/2026): Higgsfield u otro generador de video sirve para el tráiler, la página del juego y bocetos de planos, no para esta previa. | Claude (cámara y poses) + Gemini (carteles) | ✅ cinemática de entrada en partida («todo bien», usuario) |
| Previa de 10 s antes de cada partida | Al menos 10 s antes de que arranque, con una pantalla para elegir **arma, skin e infusión**. Hoy no se puede cambiar de arma en partida. | Codex (servidor) + Gemini (interfaz) | ✅ elección de arma, skin e infusión (lo jugó el usuario) |
| Patear al rival derribado | Mantener la mecánica de levantar y agregar una patada para tirar al rival derribado fuera de la arena. | Claude | 🔍 ✅ en Studio; 10/11: empuje más largo (16 → 32), falta calibrar |
| Combate direccional | Ataques y bloqueos arriba, izquierda y derecha, parry perfecto, patada de ring-out, hit-stop y Elo para las clasificatorias. Diseño completo y preguntas abiertas en [[Diseño Combate PvP Direccional Roblox]]. Especificación de Gemini (10/11): [[Especificación Gemini combate direccional]]. Arquitectura y conflictos a decidir: [[Arquitectura Combate Direccional]]. Confirmado como eje de la 0.2 (sección 10). | Claude | ✅ activado y jugado por el usuario. 🔍 falta stick del mando, fijado T/R3, ping, Maza/Estoque y 2v2 |
| Clasificatorias con Elo | Parte del diseño direccional. Hoy RANKED dice «Próximamente». | Codex | ⬜ RANKED sigue en «Próximamente» |

## Orden sugerido
1. Bugs: el punto doble y la cámara en celular.
2. HUD nuevo y soporte de celular.
3. Sensación de combate.
4. Roles, Owner y panel de administración.
5. Niveles y cajas de suerte.


## 10. Combate direccional: decisiones del usuario (9/11)
- Es el eje de la 0.2.
- Se diseña primero para **mando y teclado/mouse**; celular con mando entra en ese grupo (Mateito). El táctil se adapta después.
- Ningún mapa de botones está aprobado todavía. Propuestas de Codex (postura persistente, parry común, prototipo con espada y muñeco) en [[Diseño Combate PvP Direccional Roblox]]; conflictos a decidir en [[Arquitectura Combate Direccional]].

## 11. Correcciones del 10/11/2026 12:28
Referencia visual: [[Referencias/espada-concepto.png]] (concepto 2D hecho a partir del dibujo del usuario; no es modelo 3D).
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Combos según dirección | Series de combos por dirección dentro del direccional. Sin definir: secuencias, transiciones, cantidad de golpes, cancelaciones, resistencia. | Claude | 🔍 remate si conectan los 3 golpes (D4, ✅ en Studio); el golpe ya se anima hacia el lado elegido (10/11) |
| Todas las skins al acabado de la espada | Más detalle, acabado y brillo; formas menos cuadradas y más filosas. El dibujo del usuario es la referencia principal (Pinterest, secundaria). Conservar la identidad de cada skin; revisar silueta, materiales y lectura en juego. | Gemini | ✅ skins de la 0.1 de vuelta y Eclipse Carmesí en las 5 armas; las 36 con rayos salen en las cajas de Tormenta. ⬜ mallas de Blender (decidir si se rehacen) |
| Ruleta diaria y premio semanal | La espada y un par de skins más en la **misma** ruleta de monedas y XP. Tiradas diarias; skin o premio grande que rota cada semana. Sin definir: tiradas por día, reinicio, probabilidades, duplicados, calendario. | Codex (servidor) + Gemini (interfaz) | 🔍 ruleta, premio semanal, suspenso y tiros pagos hechos; el usuario no marcó problemas |
| Tienda nueva | Rediseñar la actual reutilizando lo que hay, presentación al estilo Fortnite con vistas previas (sin copiar su identidad). Vende skins, multiplicadores y monedas. | Gemini | ✅ hecha. 🔍 23:59: arreglados los tirones (la ventana redibujaba todo en cada frame) |
| Armería separada | Elegir arma, skin e infusión con vista previa antes de salir. | Gemini + Codex | 🔍 23:59: miniaturas quietas y de perfil (ya no quedan de punta), sin tirones; falta ver el texto «Arrastrá para girar» |
## 13. Pedidos del 10/11 a la noche
| Pedido | Detalle | Resp. | Estado |
|---|---|---|---|
| Golpe animado según la dirección | `AnimClips.DirMap` por arma | Claude | 🔍 el usuario no marcó problemas |
| Espadón y maza contra el spam | Más rápidos y contragolpe de peso al bloquear | Claude | 🔍 ajustar con más partidas |
| Patada al derribado más larga | 16 → 32 de velocidad | Claude | 🔍 calibrar |
| Whoosh del dash | Sin el sonido pesado con ruido | Claude | 🔍 |
| Vista previa de auras | «Probar en mi personaje» | Claude | 🔍 |
| Bug de la ceniza | Era la herramienta de prueba; ahora solo testers y montos correctos | Claude | 🔍 |
| No subirse encima del rival | Separación mínima y bajada automática | Claude | 🔍 |
| Tirones en la tienda y el mouse | Ventanas sin CanvasGroup y tarjetas quietas | Claude | 🔍 |
| Más cajas con las skins retiradas | Tres cajas de Tormenta | Claude + Codex (revisión) | 🔍 |
| Tipografía nueva | Grenze Gotisch, Merriweather y Builder Sans | Claude | 🔍 avisar si algún texto queda cortado |

## Registro
- 09/11/2026: nota creada con los pedidos de la beta 0.1.
- 10/11/2026: sumadas las correcciones de las 12:28 y los pendientes abiertos de la 0.1; resumidas las secciones repetidas del direccional.
- 10/11/2026 23:59: el usuario considera la 0.2 casi lista; sección 13 y estados al día.
- 10/11/2026 22:50: estados revisados contra Git y los reportes de las rondas 1 y 2 (pedido del usuario): ✅ hecho, 🔍 en revisión, ⬜ falta.

## 12. Retención y almas — 10/11/2026 12:50 (Argentina, UTC-3)
**Pedido:** investigar cómo los juegos de Roblox motivan a volver por skins y recompensas. El usuario agregó que le gusta sumar algo como las almas de Dark Souls. Interés confirmado; mecánicas siguientes propuestas por Codex, no decisiones cerradas. Solo diseño.

### Investigación
- **Adopt Me:** actualización oficial del 11/09/2026: Bucks y una estrella por ingreso diario, canjeable por premios. Patrón observado: visita diaria y meta acumulable. Fuente: https://www.playadopt.me/news/new-star-rewards . No demuestra su impacto cuantitativo en retención.
- **Jailbreak como ejemplo:** Roblox lo usa en su guía de temporadas con misiones, niveles y premio final. Recomienda mostrar recompensas 3D y facilitar ponerse al día. Fuente: https://create.roblox.com/docs/production/game-design/season-pass-design . Referencia de diseño, no auditoría del pase actual de Jailbreak.
- **Primera sesión:** enseñar lo esencial, llegar pronto a jugar y mostrar progreso. Aplicación inferida: primer duelo y desbloqueo accesibles. Fuente: https://create.roblox.com/docs/production/game-design/onboarding .
- **Medición:** retorno D1/D7/D30 por cohortes. Fuente: https://create.roblox.com/docs/production/analytics/retention . Copiar una mecánica no garantiza retención ni permite afirmar cambios neuroquímicos.

### Propuesta para este PvP
| Plazo | Motivo | Aplicación propuesta |
|---|---|---|
| Primera sesión | Identidad propia | Primer cosmético accesible y preview de la skin objetivo, tutorial breve. |
| Cada partida | Avance incluso perdiendo | Recompensa y progreso hacia objetivo elegido; participación válida, no AFK. |
| Día | Meta breve y variada | Misiones de completar duelos/aprender defensas, no únicamente victorias ni conductas que perjudiquen al equipo. |
| Semana | Novedad deseada | Misma ruleta monedas/XP ya pedida, premio semanal y preview 3D; ruta garantizada adicional hacia cosméticos. |
| Largo plazo | Dominio e identidad | Maestría por arma, títulos, acabados y efectos cosméticos; sin poder por skin. |

La ruleta aporta sorpresa; la progresión principal conviene que sea comprensible y acumulable. Propuesta: duplicados aportan a progreso cosmético sin sumar otra moneda obligatoria; colección/contrato persistente para skins anteriores. No borrar esfuerzo por faltar un día. Cantidades, probabilidades y cadencias pendientes. Celebrar logros reales, sin casi-premios falsos.

### Almas: idea del usuario, función pendiente
- Confirmado: le gusta sumar algo parecido a las almas de Dark Souls. No aprobó copiar todo el sistema.
- **Opción recomendada por Codex:** almas como identidad dark fantasy del recurso de progresión; evaluar renombrar monedas existentes antes de añadir un saldo redundante. Destino: skins/apariencia, no daño.
- **Alternativa:** monedas para tienda y almas para maestría/forja cosmética, solo si la separación tiene una utilidad clara.
- Ejemplo propuesto: terminás un duelo, ganás almas, ves avanzar la forja de la skin elegida y la previsualizás en armería. La ruleta semanal sigue como extra.
- Pregunta central: ¿ambientación/recurso y progreso, o también pérdida/recuperación al morir? No implementar pérdida, robo o recuperación por defecto. En PvP afectaría especialmente a nuevos; evaluar aparte, quizá como modo opcional.
- No migrar perfiles ni reemplazar monedas hasta decidir su función. Costes y cantidades pendientes.

### Alcance y validación propuestos
Primera versión pequeña: preview del objetivo + progreso pospartida + misión breve + ruleta semanal existente. Resolver almas/monedas primero. Evaluar un pase completo después: exige producción sostenida de arte.
Medir llegada al primer duelo/desbloqueo, partidas completas, cosméticos reclamados/usados, retorno D1/D7/D30, abandono y progreso de principiantes. Comparar cohortes con línea base y pocas modificaciones por vez; pocos jugadores no dan conclusiones firmes. Combate, cámara y rendimiento siguen siendo centrales.
**Implementado:** solo documentación. **Comprobado en Studio:** nada nuevo. **Pendiente:** definir almas, aprobar alcance, balancear, implementar y medir. Reparto sugerido: Claude integración/combate, Codex economía/guardado/medición, Gemini previews/interfaz.

## Entrega backend ronda 1 — 10/11/2026 14:12 (Argentina, UTC-3)
🔍 Código de la ronda 1 de Codex integrado con aprobación explícita del usuario. Detalle único de alcance, contratos, limitaciones y pruebas en [[Reporte 0.2 Codex]]; nombres finales en [[Contratos 0.2]]. Revisión estática completa: 82 archivos OK y LihFolk 0 errores/avisos. No comprobado en Studio; faltan los puntos de integración de Claude/Gemini del reporte. Recompensas completas: ronda 2.

## Entrega backend ronda 2 — 10/11/2026 18:20 (Argentina, UTC-3)
Pedido: ejecutar la sección Codex de [[0.2 Ronda 2 - prompts]] y sus reglas comunes. 🔍 Servidor y datos de recompensas, compras reales de multiplicadores con almas y nuevas acciones administrativas implementados. Alcance, pruebas, decisiones técnicas y pendientes en la sección «Ronda 2» de [[Reporte 0.2 Codex]]; API definitiva y guardado táctil en [[Contratos 0.2]], C19/C10. Se preserva Coins y se denomina almas en LocaleCodex. Sin Studio, sin regenerar place y sin commit/push. Las conexiones pendientes del tutorial y las pantallas siguen en los archivos de Claude/Gemini, según el reparto.

