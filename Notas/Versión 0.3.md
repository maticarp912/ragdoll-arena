# Versión 0.3

## Primera tanda · 11/11/2026 23:16 (Argentina)

### Implementado

- **Combate direccional.** El servidor fija la postura durante el básico y el fuerte, desde la preparación hasta terminar la recuperación. El cliente ignora gestos mientras tanto y el triángulo marca el lado del ataque.
- **Fuertes.** Arriba, izquierda y derecha para espada, espadón, dagas, estoque y maza. Las variantes usan las poses direccionales y conservan los tiempos y el paso del fuerte de cada arma.
- **HUD móvil.** Separé cola, barras y controles táctiles usando el área segura. El lobby queda con 1v1 y 2v2. Rankeds queda fuera de la 0.3.
- **Dirección de arte.** Paleta de pizarra y acero azulado con plata. Conecté las barras de vida, guardia e infusión, el marco del avatar en HUD y party, un separador clásico en el lobby y el marco gótico de carga. La primera tanda reutiliza el arte existente.
- **Ciudad.** La plaza conserva su ubicación y circulación. Sumé dos puestos de madera y tela y un anillo de adoquines cortados alrededor de la estatua. Guardé diez imágenes originales como referencias en `Referencias 0.2/Referencias ciudad`. Las capturas muestran el estilo buscado para las siguientes zonas.
- **Blender.** Piloto Corte de Plata (Relic21), basado en la referencia de su ficha. 1.554 triángulos y atlas de 1.024 × 1.024. Archivo editable, FBX, OBJ, MTL, textura y render en `modelos_armas/v0.3`. El ejecutable está instalado desde Microsoft Store y se ejecuta con `blender-launcher.exe`.

### Comprobado en Studio

- En una copia local, el servidor rechazó cambiar de izquierda a derecha al iniciar un básico y un fuerte de espada, y rechazó subir durante la recuperación. Volvió a aceptar derecha al terminar ambos ataques.
- El juego resolvió los 15 clips direccionales. Falta revisar visualmente cada arma en combate.
- Con modo táctil simulado a 655 × 635 (área segura 655 × 577), verifiqué que las barras, la cola y los botones no se superponen en lobby ni durante el estado de partida. Cargaron las tres barras de arte y el separador de Misiones. La plaza generó sus 52 piezas nuevas en Play.

### Pendiente

- Probar en teléfono físico, también con mando. Revisar el marco de carga y terminar la aplicación de los demás recursos plateados según [[Arte - lista de imágenes]].
- Seguir el acabado de las calles y fachadas con las referencias de árboles, piedra, columnas, fuente y mobiliario. Las referencias son imágenes.
- Importar el FBX de Corte de Plata, revisar agarre y escala en Studio y asignar sus IDs. Modelar las demás skins por arma.
- Integrar los cambios al place oficial después de las pruebas.

## Place local activo · 12/11/2026 00:00

La prueba local fue integrada a `Ragdoll Arena.rbxlx` en la raíz del proyecto de F:. Abrir siempre ese archivo. Ver [[Versiones en Studio]].

## Carga y rediseño de interfaz · 12/11/2026 00:46 (Argentina)

### Implementado

- Carga inicial con bloqueo de movimiento y acciones, progreso por recurso y dos intentos de carga. Espera perfil, personaje y mapa inicial. Incluye texturas declaradas de UI, entorno, materiales y armas, animaciones y audio. Si quedan recursos inaccesibles tras el límite de espera, se muestra cuántos y recién entonces aparece «Entrar igualmente».
- Garamond de Roblox como aproximación a la serif de Valor Mortis en los textos del juego, sin contorno. La captura no permite confirmar la familia exacta. Roblox solo permite usar familias disponibles como assets.
- Arsenal con lista vertical, descripción y un solo visor 3D con giro y zoom. Previsualizar y elegir el arma son acciones distintas.
- Controles con diagramas de teclado/ratón y mando, y asignaciones del dispositivo seleccionado. Conserva el guardado de los cambios. HUD de combate en el sector superior izquierdo en pantallas amplias, inspirado en The Witcher. Conserva la disposición compacta anterior en pantallas chicas.
- Secuencia de duelo inspirada en el video de Soulcalibur VI. Presentación de los luchadores, sello de asalto durante la cuenta regresiva y señal de combate al habilitar el servidor los ataques.

### Comprobado en Studio

- En una copia aislada, el perfil temporal cargó y la pantalla terminó con cero recursos pendientes. Comprobé la serif sin contorno en Arsenal.
- El Arsenal mostró un visor. Seleccionar Estoque conservó Espada equipada hasta tocar «Elegir», que cambió el arma a Estoque.
- Alterné teclado/ratón y mando y confirmé que mostraban asignaciones distintas. En una ronda simulada con los atributos del servidor, «Asalto 1» pasó a «¡A luchar!» al habilitar el combate.

### Pendiente

- Revisar una partida real 1v1 y 2v2, y probar mapeado con mando físico y carga en celular. Los recursos de streaming o generados después de entrar se solicitan cuando aparecen.
- Integré el rediseño en el archivo local activo y guardé desde Studio. Los 103 scripts del place coinciden con el repositorio. La cámara volvió de Scriptable a Custom al terminar la cinemática simulada.



## Revisión de los cambios de Opus · 12/11/2026 12:05 (Argentina)

### Implementado por Opus

- Ajustó el contraste de carga, el techo del puesto de alquimia, el triángulo de plata y el aviso «¡A luchar!». Sumó el menú de inicio, el despertar y tutorial guiado, una nueva distribución del HUD, la tienda con barra lateral, el perfil, los filtros de armería y la búsqueda «Jugar» en ambas colas.
- El archivo local Ragdoll Arena.rbxlx coincide con los 107 scripts del repositorio. El control de sintaxis pasó los 107. La publicación 0.3 quedó registrada por Opus en [[Publicación 0.2]].

### Comprobado en Studio

- La copia local terminó la carga con cero recursos faltantes. Mostró el menú inicial y «Jugar» abrió el tutorial en el patio. La Salida avisó que el perfil de Studio era temporal.
- El «Jugar» del lobby se pudo activar durante el tutorial. Ambos contadores pasaron a 1 con InTutorial activo. Al simular el inicio de una partida y enviar «Saltar» al servidor, el personaje volvió a la ciudad con InMatch y Prematch todavía activos.
- Con un objetivo fijado en una antesala simulada, estuvieron visibles las barras propias y el triángulo. Las dos mitades del techo del puesto tienen la cumbrera arriba.
- Los nombres de las cuatro imágenes consultados en Studio confirmaron barra_hud_04 (121288131222477), 05 (94464479484599), 08 (114096602913235) y 14 (115799578034954).

### Hallazgos y pendientes

1. **P1 · Tutorial y partidas.** MatchService.server.lua:580 y :591 permiten entrar en cola desde el tutorial. TutorialService.server.lua:164 devuelve al jugador a la ciudad incluso con una partida activa. Bloquear la cola y la elegibilidad durante el tutorial y proteger la salida del tutorial mientras InMatch esté activo. Repetir con dos jugadores reales.
2. **P2 · Dirección táctil.** GuidedTutorial.client.lua:132 exige probar las tres direcciones y anuncia gestos táctiles. Controls.client.lua:573 solo traduce movimientos de mouse o del stick derecho a una postura. Con pantalla táctil sola se puede saltar el tutorial completo. Falta implementar el gesto o adaptar ese paso y comprobar en un teléfono con y sin mando.
3. **P2 · Cierre de partida.** MatchService.server.lua:504 liquida a todo el grupo dentro de una sola llamada protegida. Si Stats.finish falla para un jugador, los siguientes se quedan sin su cierre. Aislar la liquidación por jugador y verificar con un fallo inducido.
4. **P2 · Antesala.** HUD.client.lua:817 y DirectionalHUD.client.lua:222 muestran indicadores con objetivo fijado durante Prematch. Definir la visibilidad por fase y comprobar la distribución junto al panel de preparación en PC y celular.
5. **Arte.** Los 28 PNG están registrados. Once quedaron sin uso visible identificado en el código: marcos clásicos 03–05, bordes oscuros 01–02, separadores 02–03 y ornamentos laterales 01–04. «¡A luchar!» usa el separador 01. En modelos_armas/v0.3 sigue estando el piloto Corte de Plata y queda pendiente el resto del catálogo.
6. **Comprobación pendiente.** Partida completa 1v1 y 2v2, conteos de cola mientras hay una partida en curso, controles de celular y revisión de la versión publicada desde Roblox.


## Controles táctiles, tutorial y equilibrio · 12/11/2026 12:54 (Argentina)

### Implementado

- Agrupé ataque, fuerte, guardia y esquiva para el pulgar derecho. La cruceta de tres lados usa la postura compartida con mouse y mando. Aparece con objetivo fijado y se desactiva junto a los controles de combate en la antesala.
- El tutorial tiene 16 pasos, instrucciones centradas y un botón de salto más grande. Enseña Armas e Infusiones en una Armería reducida, esquiva, agarre, lanzamiento y activación de infusión. Solo muestra los controles útiles a la lección. Oculta tienda, recompensas, cola y HUD general. El servidor excluye a los participantes de las colas durante el tutorial.
- La curación pasiva funciona en el lobby y se suspende durante las partidas. Espadón de 290 a 260 de vida y fuerte de 50 a 45 de daño. Maza de 317 a 270 de vida y fuerte de 46 a 41 de daño. Bajaron también sus básicos y la presión de sus golpes pesados. La resistencia por básico/fuerte quedó en 22/45 Espada, 29/60 Espadón, 15/29 Dagas, 18/36 Estoque y 29/60 Maza.
- Exporté 107 combinaciones de arma y skin en cinco .blend por clase, con cada pieza separada. Hay un sexto .blend con los 21 pilotos FBX y sus texturas empaquetadas. Carpeta `modelos_armas/Blender - catálogo 0.3`. Los modelos de juego convertidos conservan la forma y los colores de Roblox con materiales equivalentes de Blender.

### Comprobado

- Los 108 scripts del place local de F: coinciden con el repo. Chequeo de Lua y LihFolk sin errores ni avisos.
- En Play local, la vida quedó en 155,52 durante una ronda simulada y volvió a subir en el lobby. Confirmé Armería con las dos pestañas y el acceso a tienda oculto. El HUD del lobby quedó oculto en el tutorial y el servidor rechazó la solicitud de cola.
- En modo táctil simulado, fijé un muñeco y pulsé la cruceta para pasar de arriba a derecha y a izquierda. El servidor conservó la postura izquierda al intentar cambiarla durante un ataque simulado. Con las acciones reales del servidor, un básico de Espada consumió 22 de resistencia y después se pudo hacer una esquiva.
- Reabrí los seis .blend. Verifiqué 25 espadas, 19 espadones, 17 dagas, 21 estoques, 25 mazas y 21 pilotos FBX con 21 texturas empaquetadas.

### Pendiente

- Completar las 16 lecciones de punta a punta en un celular físico, con y sin mando, y calibrar el balance en partidas 1v1 y 2v2.
- Al publicar esta tanda por paquete, copiar también `__PACK/SCS/Health` a `StarterPlayer/StarterCharacterScripts` como Script. El place local ya lo incluye.


## Tutorial privado y espada al aparecer · 12/11/2026 13:55 (Argentina)

### Implementado

- MatchService equipa el arma antes de asignar el patio. La carga espera el personaje preparado y el despertar devuelve la visibilidad del personaje y del arma si se interrumpe.
- Cada jugador nuevo recibe un patio propio con dos muñecos quietos y un bot para bloqueo y parry. El servidor restringe daño, agarre y objetivos al patio del dueño. Reaparecer conserva el patio y el paso. Terminar, saltar o desconectarse libera el patio y sus tres muñecos.
- Integrado en Ragdoll Arena.rbxlx de F:. Los 109 scripts coinciden con el repo. Chequeos de Lua y LihFolk sin errores ni avisos.

### Comprobado en Studio

- Dos clientes nuevos aparecieron con espada equipada y soldada a la mano. Los patios quedaron a 2048 studs entre sí, con tres muñecos propios cada uno. Un cliente reapareció armado en su mismo patio y el otro salió a la ciudad sin alterar la sesión restante. El servidor rechazó los muñecos ajenos como objetivos de combate.
- En una prueba adicional, pulsé «Jugar» y confirmé el tutorial activo y 35 piezas de la espada visibles después de despertar.

### Pendiente

- Publicar esta tanda y repetir la primera entrada desde Roblox con dos cuentas nuevas.


## Fase 0 · Animación, infusiones y skins · 12/11/2026 14:47 (Argentina)

### Estado y propuesta

- **F1.** El proyecto guarda 55 conversiones en tools/mocap_all.json y 21 clips en MocapClips. El conversor actual exporta rotaciones R15 cada dos cuadros y solo posición de raíz. Extender el flujo de Blender en segundo plano para guardar transformación de todos los huesos por cuadro y pedir por nombre solo los FBX fuente que falten. Para Estoque, partir de una estocada. Para Dagas, adaptar dos manos de forma independiente. generate_animation queda para huecos.
- **F2.** Ya se mapean 15 partes de R15 y el cliente hace IK de mano izquierda. El conversor usa una altura fija y no valida intersecciones. Aplicar las proporciones de CombatConfig.Body y evaluar hoja contra torso. Informar cuadros corregidos y error máximo de agarre en studs. Espada y Estoque a una mano, Espadón y Maza a dos, Dagas una por mano. La Espada actual tiene tanto twoHanded como OffhandFallback, que se deben corregir juntos en esta fase.
- **F3.** En Studio se resolvieron los 30 ataques direccionales existentes. Seis ligeros usan Mixamo y los otros 24 ataques tienen animación procedural. Presupuesto de variantes por pulir, ligero/fuerte: Espada 0/3, Espadón 1/3, Dagas 3/3, Estoque 3/3 y Maza 2/3. Son 24 clips objetivo con fuentes reutilizables. Guardias direccionales, combo de tres, patada, parry, impacto, aturdimiento y derribo ya tienen poses o clips. Mantener Animator en cliente con Transform en Stepped y sincronizar con AnimHit/AnimWindup del servidor.
- **F4.** Infusion.client ya usa emisores, luz y un Beam de Rayo. AuraFx ya atenúa las auras cosméticas del arma durante la infusión. El builder da BladeBase y BladeTip en los cinco modelos base. Agregar el anclaje intermedio y completar el rayo, arcos, volutas, chispas fijas y triple brillo dentro de la ruta existente. Declarar las cuatro variantes en Infusions.lua y ajustar posición y coste para hojas cortas, largas y cabeza de maza.
- **F5.** La tecla R y el umbral de 100 están conectados. El servidor ya vacía la barra a medida que transcurren los 12 segundos y desactiva el buff al llegar a cero. El HUD lee la carga replicada y muestra el tiempo restante. Conservar este flujo y probar las cuatro variantes cuando estén conectadas al aura nueva.
- **F6.** Revisé las 36 referencias visuales de las cinco clases, incluidas las 10 de espadas. El Handle procedural de las cinco armas base es cuadrado y los 22 MeshId registrados están en cero. Piloto propuesto: Vigilia Violeta (Relic10, 666cbeed9aec5569d54b076fd2f6be9f.jpg), por su vista frontal de 878 × 1500. Mango extruido de 24 lados, silueta original, espesor menor en el eje X, Mirror donde corresponde y Solidify. Proyectar la imagen original sobre la hoja y comprobar menos de 2000 triángulos en el FBX final. Para mazas sin perfil lateral, registrar el grosor estimado. Conservar el pivote de agarre y el catálogo.

### Comprobado en Studio y en el repo

- En Edit comprobé la resolución de los clips, las dos manos de la Espada actual, los cinco mangos cuadrados, los dos anclajes por arma y el registro de mallas. El chequeo de Luau pasó los 109 scripts.
- En Play pulsé R con 99 y con 100 de carga. Con 99 quedó apagada. Con 100 se activó Fuego y el multiplicador de daño pasó de 1 a 1,2. La carga bajó durante el efecto, terminó en 0 y el daño volvió a ×1.

### Pendiente

- Inicio de la Fase 1 sujeto al OK del usuario. Luego se acuerda la lista exacta de FBX y se prueba una exportación. Fases 2 a 6 quedan para sus respectivas revisiones.


## Piloto de fuertes de Espada y Vigilia Violeta · 12/11/2026 15:20 (Argentina)

### Implementado

- Guardé el estado previo en main en el commit 1ad5dda. Incluye la interfaz de Claude, los arreglos de tutorial y los recursos del proyecto. El único enlace de instalación local que quedó afuera es el de frontend-design en .claude/skills.
- Fuertes de Espada a partir de los FBX existentes en F:/RobloxJuegos/assets animaciones. Arriba usa Standing Melee Attack Downward.fbx, izquierda usa Sword And Shield Attack.fbx y derecha usa Standing Melee Attack Backhand.fbx.
- Blender exporta todos los huesos cuadro por cuadro con posición y cuaternión. El piloto usa las articulaciones, el torso y el agarre del R15 medido en Studio. La Espada y el Estoque dejaron de fijar la mano izquierda por la regla del arma. Los tres clips pasan por MocapClips y Animator.client con tiempos del servidor.
- Vigilia Violeta (Relic10) quedó editable y exportada a FBX con textura original proyectada, mango de 24 lados y hoja de 0,055 studs de grosor. La malla exportada tiene 1484 triángulos. La ficha Violet está preparada en WeaponMeshes.lua.

### Comprobado

- Los tres fuertes ejecutaron los clips nuevos y cada uno quitó 28 de vida al muñeco. El impacto del servidor fue a los 0,539 s. Las capturas muestran las poses de preparación de esos clips en el mismo patio de la prueba.
- Retarget de arriba, izquierda y derecha con 56, 56 y 62 claves. Corregí 0, 9 y 5 cuadros fuente respectivamente y agregué una clave de transición a izquierda. La comprobación de los cuadros y tres muestras por intervalo dio cero cruces con el torso. Error máximo del agarre derecho de 0,0000003 studs en el cálculo con el rig medido.
- El place local quedó con los 109 scripts del repo y las correcciones de interfaz. Chequeo Lua y LihFolk sin errores ni avisos.
- Los artefactos y el reporte de retarget están en modelos_armas/v0.3/Piloto Espada. Los de Vigilia están en modelos_armas/v0.3/Vigilia Violeta.

### Pendiente

- Studio MCP rechazó subir el FBX porque la carpeta de F: no está autorizada para cargas. Importar el FBX desde Studio y pasar MeshId y TextureID o ColorMap. Después probar escala, orientación y textura de Vigilia equipada y en la vista previa.
- Revisar el piloto antes de preparar las otras 21 variantes o modelar otra skin. La publicación queda pendiente.


## Mocap por arma (punto A)

### Implementado

- El generador deja 8 clips en Espadón, 3 en Maza, 6 en Espada y 7 en el módulo compartido. `MocapClips` conserva las mismas 24 claves para `AnimClips`. Dagas y Estoque siguen usando sus rutas actuales.
- Comparé el contenido de los 24 clips con el de Git, incluidos los tiempos y cada clave de pose. Los datos coinciden. El módulo más grande ocupa 86.747 bytes y el chequeo de Luau pasó los 113 archivos.

### Comprobado en Studio

- La copia local `Ragdoll Sword pilot test.rbxlx` se guardó con los cuatro módulos y el índice. Antes de integrarlos comprobé que sus controles, tutorial y configuración coincidieran con el repo.
- En Edit el índice devolvió los 24 clips. En Play, los tres fuertes de Espada ejecutaron el clip correspondiente, quitaron 28 de vida al muñeco y marcaron el impacto a los 0,539 s.
- Capturas de la preparación de los tres golpes en `F:/RobloxJuegos/Archivo Ragdoll Arena/Capturas Mocap por arma`. Se encuadraron en Play con el HUD oculto y luz ambiente ajustada para la captura.

### Pendiente

- Revisar las capturas y esperar el OK para empezar B, la importación y prueba de Vigilia Violeta. Las otras 21 animaciones y las infusiones de cinco capas quedan para C y D.
- La publicación sigue pendiente de indicación del usuario.
