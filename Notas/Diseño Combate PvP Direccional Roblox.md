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

## Preguntas abiertas (anotadas por Claude, para decidir antes de implementar)
1. **F tiene dos usos:** bloqueo superior y patada. ¿Cómo se distinguen? Algunas opciones:
   - mantener F = bloquear y tocar F = patear;
   - patear solo si el rival está derribado.
2. **E y Q chocan con los controles actuales.** Hoy esas teclas ya hacen otras cosas (ver `InputMap`). Habría que reasignar agarrar, infusión y lo que esté en esas teclas.
3. **¿Cómo se hace en celular y con mando?**
   - Celular: tres botones de ataque, o un botón con deslizamiento hacia arriba, izquierda o derecha.
   - Mando: dirección con el stick derecho más gatillo.
4. **Hay que decir de dónde viene cada golpe.** El aviso de ataque fuerte (punto rojo) tendría que indicar también la dirección, para que se pueda leer y defender.
5. **Combo actual de 3 golpes.** ¿Se reemplaza por golpes direccionales, o cada dirección tiene su propio combo?
6. **Equilibrio:** la ventana de 0,12 a 0,15 s es muy exigente con la latencia de celular. Considerar una ventana más amplia en celular, o compensar el ping.

## Decisión del usuario (9/11)
El combate direccional **entra como eje de la 0.2**. Para el usuario es lo que diferencia al juego del resto del género.

## Plan propuesto por Claude (por etapas, sin romper lo que ya funciona)
1. **Prototipo apagado por defecto.** Se activa con `CombatConfig.Directional.Enabled`, primero solo en el patio de práctica. Los muñecos atacan y bloquean por dirección, para entrenar.
2. **Lectura de la dirección:** cada ataque muestra de dónde viene (flecha o arco de color sobre el rival) antes de impactar. Sin esto no se puede defender.
3. **Controles en las tres plataformas** (propuesta, a confirmar):
   - **PC:** clic izquierdo + la dirección del mouse en el momento del clic. O Q, clic y E como en el diseño original, reasignando lo que hoy usa Q y E.
   - **Celular:** un botón de ataque que se desliza hacia arriba, izquierda o derecha, y otro igual para bloquear.
   - **Mando:** stick derecho para la dirección, gatillo derecho para atacar y gatillo izquierdo para bloquear.
4. **Parry con margen para el ping:**
   - ventana de 0,15 s en PC y de 0,2 s en celular (los valores van en `CombatConfig`);
   - el servidor juzga usando el momento en que el cliente apretó, con un límite máximo.
5. **Patada (F):**
   - tocar F = patada;
   - contra un rival derribado = patada de ring-out.
   - Si se usa mantener F para el bloqueo superior, las dos acciones no se pisan.
6. **Equilibrio:** cada arma conserva su identidad.
   - **Dagas:** cambian de dirección más rápido.
   - **Maza:** su golpe superior es imbloqueable.
   - **Estoque:** solo ataca de frente, con más alcance.
7. **Probar en la beta con el hermano antes de activarlo en partidas.**

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

## Decisión del usuario — plataformas principales (9/11)
**Confirmado:** el enfoque principal del combate direccional es mando y teclado/mouse. El táctil se adapta después, buscando que sea usable sin condicionar todo el diseño a la cantidad de botones en pantalla. No significa eliminar el soporte táctil ni aprobar un esquema concreto de controles.
- Celular CON mando pertenece al objetivo principal de mando: conservar los mismos controles que en PC/consola y probar cámara, tamaño de HUD y lectura de avisos en teléfono real con Mateito.
- Celular SIN mando: adaptación secundaria, con esquema simplificado de entrada si hace falta. Propuesta de Codex: simplificar gestos/disposición, manteniendo las reglas de daño, guardia y parry comunes. Esta igualdad de reglas sigue como propuesta, no decisión adicional del usuario.
- Orden de diseño propuesto: cerrar mando y teclado/mouse; validar con práctica; adaptar táctil. La elección PC mouse frente a Q/M1/E y la cámara/selector sin fijado siguen abiertas.
**Implementado:** solo documentación de la decisión. **Comprobado en Studio:** ninguna prueba nueva del direccional. **Pendiente:** definir controles, prototipo y pruebas en PC y teléfono con mando; luego táctil.

## 10/11
El usuario trajo una especificación de Gemini: [[Especificación Gemini combate direccional]]. Claude escribió la arquitectura y la tabla de conflictos con la beta y con la Mesa de Codex: [[Arquitectura Combate Direccional]].
