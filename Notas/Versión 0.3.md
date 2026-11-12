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

