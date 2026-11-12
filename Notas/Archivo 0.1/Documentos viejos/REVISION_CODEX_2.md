# Revisión Codex 2 — 8/11/2026

Se trabajaron los puntos 1 a 7 en el orden de TAREAS_CODEX_2.md. El punto 8 se intentó, pero la validación en Play queda pendiente por el bloqueo de control de Studio detallado abajo.

## Implementación

1. **Tienda:** pestaña Infusión con las cuatro tarjetas, color, nombre y título, descripción, ventajas, costes y contras calculadas con `Infusions.matchup` y `beatenBy`. Elegir llama al `SelectInfusion` existente y la vista observa `InfusionId`. Se acomodaron las pestañas y las monedas para evitar superposiciones.
2. **Aura:** nuevo `Infusion.client.lua`, observador de todos los Combatant. Partículas sobre piezas Blade de Tool y OffhandWeapon, perfiles por tipo, rayos Beam entre los attachments BladeBase/BladeTip, niebla y cristales de hielo, humo de sombra, Highlight, luz en la punta, color temporal de SwingTrail y aura en los pies. Estallidos de activación e InfusionHit; llamas de quemadura, tinte de frío/fragilidad y chispas de descarga. Limpieza al apagarse, morir o quitar la etiqueta; restauración del color original de estelas. Se distinguen los attachments BladeTip de las piezas con el mismo nombre.
3. **HUD:** color y nombre de la infusión, carga y cuenta regresiva ACTIVA Ns usando el reloj del servidor, y texto Agotada durante el bloqueo. La vida tiene un rastro blanco que espera y baja con tween, cancelando las actualizaciones anteriores al recibir otro golpe o reaparecer.
4. **Cámara:** trauma acumulativo con decaimiento, ruido continuo math.noise para desplazamiento y roll, empujón según la dirección recibida y HapticService con las intensidades configuradas. Los números de daño aparecen con rebote de escala.
5. **Impactos:** flash blanco de la víctima y trazo Neon diagonal que se desvanece en golpes Light/Heavy. Objetos temporales retirados con Debris.
6. **Animación:** Carry con hombros a 172°, apertura ±14°, codos 22° y cintura +6°; carga del lanzamiento inclinada atrás; lanzamiento corto desde Carry y conservación del lanzamiento lejano sobre la cabeza. PickUp termina en Carry. Se agregó GetUpFront, con apoyo de brazos y paso desde el suelo a rodillas y de pie. Dash con anticipación, extensión y frenado. Locomoción procedural para jugadores y muñecos, con fase por distancia horizontal recorrida, movimiento adelante/lateral de cadera, rodilla y tobillo, brazo libre, bote de raíz y pose aérea con agitación de brazos. Se conservan clips de acción, IK y soporte de Motor6D/AnimationConstraint.
7. **Arena:** nuevo ArenaBuilder integrado a MatchService. Radios 100/45 para 2v2/1v1, disco central estable y anillos de losas trapezoidales con grietas. Cada losa combina una pieza central y dos cuñas soldadas, formando una sola unidad física que cae y gira. Cuatro cadenas de eslabones y argollas en el borde; rocas etiquetadas FloatingRock con movimiento local en Arena.client.lua; lava Neon, costras de basalto, montañas y grietas brillantes, brasas y atmósfera rojiza/violeta con bloom. Caída individual desde fuera hacia dentro, con aviso rojo, temblor, polvo y sonidos de Assets. El reinicio cancela tareas anteriores y restaura posiciones, colores y velocidades. Se mantiene el límite de ronda de 180 segundos; una eliminación puede terminarla antes. Botones Ir a la arena y Probar derrumbe, con autorización de depuración validada por CombatService. Fuera de partidas, Ir a la arena activa Solo práctica para poder probar sin entrar en cola.

## Datos y arquitectura

- `PolishConfig.lua`: ajustes de UI, partículas, HUD, rebote, cortes y caminata.
- `ArenaConfig.lua`: geometría, ambiente, derrumbe, modos y reglas de ronda.
- Poses y tiempos de clips permanecen en `AnimClips.lua`; iluminación en `Theme.lua`; intensidades de cámara y mando en `CombatConfig.lua`.
- El servidor conserva decisiones de combate y derrumbe. Los clientes observan atributos y dibujan efectos.
- No había una imagen de referencia adjunta en esta sesión; se implementó la descripción escrita del punto 7.

## Verificación y límite del punto 8

- Se ejecutó `node tools/check_lua.js .`: 34 archivos sin problemas detectados. Es el chequeo básico del repositorio, no una compilación ni una prueba de ejecución de Luau.
- Se ejecutó `node tools/make_rbxlx.js . 'Ragdoll Arena.rbxlx'`: lugar regenerado con los módulos y LocalScripts nuevos.
- Se abrió el lugar generado con Studio y se revisaron los tres logs nuevos en `%LOCALAPPDATA%/Roblox/logs`.
- El log `0.746.0.7461269_20261108T234544Z_Studio_B5BA0_last.log` registra la ruta del lugar y `StudioGameStateType_Edit`. No se encontraron entradas CreatorError ni Infinite yield en esos tres logs. Esto sólo acredita apertura en edición, no arranque del juego.
- La revisión automática rechazó el acceso a la ventana: **Computer Use was not approved to use Roblox Studio**. No se pudo pulsar Play, ni verificar visualmente físicas, poses, sonido, rendimiento o arranque de scripts. El punto 8 queda **pendiente de prueba en Play**, sin afirmar que todo arranca sin errores.

## Prueba manual pendiente

Abrir el archivo generado actualizado y ejecutar Play. Revisar Salida y el log nuevo; usar P → Llenar infusión, seleccionar cada infusión en el menú y activarla con Q. Probar golpes y estados contra muñecos, recoger/lanzar, caminar de frente/lateral y caer. Usar P → Ir a la arena y Probar derrumbe; comprobar grietas, colisión de cuñas y restauración de losas. Finalmente probar 2 clientes para 1v1 y 4 para 2v2, incluido el reinicio entre rondas. No guardar desde Studio sobre los fuentes: regenerar el lugar tras modificar los .lua.
