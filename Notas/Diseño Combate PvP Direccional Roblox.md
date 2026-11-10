# Diseño Combate PvP Direccional (Roblox)

Propuesta del usuario (9/11) para [[Versión 0.2]]. **Es solo diseño: no se toca código ni el juego hasta que el usuario decida implementarlo.**

## Mecánicas ofensivas y defensivas (tres direcciones)
| Dirección | Ataque | Defensa |
|---|---|---|
| Superior (overhead) | Clic izquierdo (M1) | F (cubre el frente y arriba) |
| Lateral derecho | E | Bloqueo lateral derecho (E) |
| Lateral izquierdo | Q | Bloqueo lateral izquierdo (Q) |

## Resolución y reglas
- **Parry o bloqueo:**
  - Hay una ventana corta (0,12 a 0,15 s) para el parry perfecto: aturde al atacante y anula el daño.
  - Si se mantiene la tecla, pasa a bloqueo normal, que gasta postura o resistencia.
- **Lectura de dirección:** si la defensa no coincide con la dirección del ataque, el golpe entra limpio y con el daño completo.

## Control del terreno y ring-out
- **Levantar:** cargar un rato al rival mientras está derribado o en ragdoll. Por ahora se mantiene como está.
- **Patada para sacarlo de la arena:** con F en neutral u ofensiva. Aplica un empuje horizontal fuerte para expulsar al rival. También sirve para patear a un rival derribado y tirarlo.

## Sensación y red
- Pausa de impacto (hit-stop, congelado breve) y temblor de pantalla según la dirección del golpe.
- Efectos visuales locales, con validación estricta de distancia y raycast en el servidor.
- Clasificatorias con sistema Elo.

## Preguntas abiertas, decisiones y plan
- Las preguntas abiertas de Claude (doble uso de F, choque de E y Q, celular y mando, aviso de dirección, combo de 3 golpes, ventana de parry y ping) quedaron respondidas como propuestas en la tabla de conflictos de [[Arquitectura Combate Direccional]] (sección 0), que espera la aprobación del usuario.
- El plan por etapas de Claude fue reemplazado por el orden de implementación de esa misma nota (sección 5).
- Decisiones del usuario (9/11): el direccional es el eje de la 0.2; primero mando y teclado/mouse, táctil después. Resumen en [[Versión 0.2]], sección 10.

## Mesa de diseño 0.2 — controles, propuesta de Codex (9/11)

**Estado:** solo documentación. El usuario confirmó que el combate direccional es el eje de la 0.2; NO aprobó todavía el esquema concreto siguiente. No se cambió código, InputMap, contratos de red ni el place. Las propuestas previas de esta nota siguen como antecedentes, no como instrucciones finales de implementación.

### Estado separado
- **Implementado:** la beta 0.1 tiene controles reasignables. Lectura actual de InputMap: PC M1 básico, M2 fuerte, F bloqueo, Espacio esquiva, E agarrar, C patada, R infusión, Q fijado, T cambiar objetivo. Mando RB/R1 básico, RT/R2 fuerte, LB/L1 bloqueo, LT/L2 patada, B/Círculo esquiva, X/Cuadrado agarrar, Y/Triángulo infusión, R3 fijado, cruceta derecha cambiar objetivo y arriba menú. A también figura como atajo de esquiva. Esto es lectura de código, no una prueba nueva.
- **Comprobado en Studio:** las notas anteriores registran pruebas de la beta 0.1 con celular/emulador de mando y 1v1. No prueban el futuro combate direccional. El hermano ya probó la beta en celular; el bug de cámara reportado sigue abierto.
- **Pendiente:** prototipo direccional, todas las asignaciones de abajo y prueba en teléfono REAL con mando. Nada de lo propuesto se considera implementado por estar escrito acá.

### Regla común propuesta: postura persistente
Elegís arriba, izquierda o derecha y el personaje conserva esa selección al soltar el selector. Después pulsás ataque o bloqueo. El movimiento del personaje no cambia la dirección del arma; así podés retroceder y cortar de costado. Mostramos siempre la dirección propia elegida y el aviso del rival con forma además de color.
- Arranca arriba al aparecer. No vuelve a arriba cada vez que soltás mouse/stick.
- La selección ofensiva queda fijada al empezar la preparación del golpe; mover el selector durante ese golpe propone la dirección del siguiente, sin cambiar el impacto en curso.
- Cambiar de lado manteniendo bloqueo tiene una transición corta por calibrar; no vuelve a abrir el parry perfecto. Evita girar las tres defensas sin costo ni tiempo.
- La defensa no activa bloqueo por elegir dirección: hace falta mantener el botón de guardia. Al soltarlo, desbloquea de inmediato.
- La flecha de defensa debe indicar el lado que VOS tenés que cubrir. No copiar sin más izquierda/derecha del atacante: validar el espejo con dos personajes enfrentados y con cámara lateral.

### Mapa candidato por plataforma (a confirmar)
| Acción | PC | Celular táctil | Mando, también conectado a celular |
|---|---|---|---|
| Moverse | WASD | Joystick izquierdo | Stick izquierdo |
| Elegir arriba/izquierda/derecha | Gesto corto de mouse con objetivo fijado; alternativa reasignable 1/2/3 | Tres sectores grandes sobre un selector derecho; conserva el último elegido | Gesto de stick derecho arriba/izquierda/derecha con objetivo fijado; conserva al volver al centro |
| Básico | M1 | Botón Atacar: tocar usa postura; deslizar y soltar elige lado y ataca | RB/R1 |
| Fuerte | M2 | Botón Fuerte, con postura ya elegida | RT/R2 |
| Guardia/parry | Mantener F; inicio de pulsación intenta parry | Mantener botón Guardia; deslizar mientras se mantiene cambia cobertura | Mantener LB/L1 |
| Patada | C | Botón Patada separado | LT/L2 |
| Esquiva | Espacio | Botón Esquiva | B/Círculo; evaluar conservar A como atajo |
| Agarrar/levantar | E | Botón Agarrar | X/Cuadrado |
| Infusión | R | Botón Infusión | Y/Triángulo |
| Fijar / cambiar objetivo | Q / T | Botones propios | R3 / cruceta derecha |
| Menú | B; Escape para volver | Botón Menú | Cruceta arriba; B vuelve dentro de menús |

**Motivo:** conserva la memoria muscular de la beta y no obliga a mantener el stick inclinado durante todo el bloqueo. F deja de tener doble función y Q/E no se pisan con ataques. El esquema original Q/M1/E queda como alternativa a comparar en PC, no descartado por decisión del usuario.

### Cámara y entradas mixtas
- Con fijado: órbita horizontal automática y encuadre del rival; mouse/stick derecho selecciona postura. El stick hacia abajo no implica un cuarto ataque: inicialmente no cambia la postura. La inclinación vertical queda en un ajuste de cámara; definir si hace falta un modificador para mirarla en combate. No prometer a la vez cámara libre y selección con el mismo gesto.
- Sin fijado: mouse/stick derecho controla cámara; ataques usan la última postura. PC conserva 1/2/3 y táctil conserva selector. Falta decidir una alternativa de selector para mando SIN fijado: primera prueba usa fijado para el duelo direccional; no inventar acordes de botones sin probarlos. No activar fijado obligatorio en la beta sin aprobación.
- Apuntado al lanzar: suspender selección direccional y usar cámara/retícula para orientar, sin cambiar la postura del arma. Menús y espectador también suspenden selector y acciones de combate.
- Celular con mando utiliza el MISMO mapa y reglas que PC con mando. No activar ventajas de parry por ser teléfono. Al desconectar mando, mostrar táctil y liberar guardia/fuerte pendientes; el primer toque de reconexión no debe atacar por accidente.
- Zona muerta, umbral de gesto e histéresis configurables: calibrar drift sin que tiemble la guardia. Tamaño, posición y sensibilidad del táctil editables. Deslizar para elegir no espera a distinguir toque largo/corto antes de empezar a defender.

### Parry, ritmo y límites — propuestas
- No adoptar todavía 0,15 s PC frente a 0,20 s celular. Probar primero UNA ventana común y avisos suficientemente largos; ajustar con datos de ping/errores y la identidad de cada arma. Tamaño de pantalla y dispositivo de entrada son cosas distintas.
- El cliente puede mandar intención y tiempo estimado, pero el servidor no acepta cualquier timestamp: valida secuencia, contexto y un margen máximo de compensación. El detalle técnico se diseña después; no es autorización para confiar en el cliente.
- Parry se abre por una nueva pulsación válida de guardia, no por mover de lado ni por spamear soltar/apretar. Recuperación mínima por calibrar. Su éxito da una ventaja corta; no garantizar un combo entero ni un ring-out automático.
- Para el primer prototipo, tres ataques básicos seleccionables y un fuerte por dirección. No nueve combos independientes. Mantener como pregunta si se conserva el combo de tres pasos y cómo cambia de lado.
- La patada es corta y legible, cuesta resistencia y deja recuperación al fallar. Probar empuje diferente contra rival de pie y derribado; no convertirla en una eliminación garantizada desde cualquier posición. El levantamiento sigue teniendo utilidad.

### Armas: evitar excepciones que anulen el sistema
- Maza: conservar un fuerte superior especial con aviso de imbloqueable; no volver imbloqueable TODO básico superior.
- Estoque: comparar estocadas desde tres guardias con trayectoria estrecha. Tener alcance máximo y atravesar TODAS las defensas direccionales quitaría valor a leer la dirección; mantener el bypass como especial identificable, pendiente de equilibrio.
- Dagas: cambios ágiles pero con preparación visible. Espadón: alcance/empuje y compromiso mayor; Espada como referencia para aprender. Números sin decidir.

### Prototipo y prueba propuesta con Mateito
Primero patio de práctica, desactivado en partidas públicas: espada contra muñeco que anuncia una sola dirección; después tres al azar. Medir errores de selección, parry por dirección, tiempo hasta entender controles, cámara que se pierde y ring-outs por patada. Comparar mando en PC, EL MISMO mando en teléfono y táctil; probar también modo sin objetivo, cambio de objetivo y desconexión del mando mientras se bloquea.
**Primera decisión a pedir:** en PC, ¿preferís postura con mouse + M1/F o ataques directos Q/M1/E? Ninguno está aprobado todavía. Segunda decisión: comportamiento de cámara/selector fuera del fijado. Postergar Elo hasta estabilizar estas reglas, sin quitarlo de la lista de ideas de la 0.2.

