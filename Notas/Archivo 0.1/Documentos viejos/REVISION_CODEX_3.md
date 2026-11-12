# Revisión Codex 3

## Implementado

Se miraron por separado las ocho imágenes de `referencias/`. Se editaron únicamente los archivos autorizados, más este resumen y el `.rbxlx` exigidos por la entrega. No se modificaron MatchService, Skins, los archivos de combate/animación de Claude ni las claves Walk de PolishConfig.

- `Environment.apply()` configura Lighting, Sky (5000 estrellas y luna grande), Atmosphere, ColorCorrection y Bloom. Paleta nocturna azul/violeta, exposición moderada y ambiente suficiente para distinguir personajes. Es idempotente y reutiliza los efectos existentes. Todos los ajustes están en Theme.Lighting.
- Arena.client agrega 2200 estrellas Neon doradas estáticas locales, sin sombras, colisiones, consultas ni luces individuales. La densidad, tamaños y semilla están en Theme.Lighting.Stars. No genera tráfico de replicación por estrella.
- LobbyBuilder.build(parentFolder) construye un pueblo con cuatro casas de madera, techos altos inclinados, ventanas cálidas, faroles, árboles verde azulado, flores violetas, barriles con aros y bancos. Suelo continuo de Cobblestone lavanda y puente ancho a práctica, sin casas bloqueando el paso. Decoración agrupada sin colisión, CanTouch ni CanQuery. Devuelve exactamente `{ spawn = CFrame, practiceCenter = Vector3, dummyHomes = { CFrame, CFrame, CFrame } }`. Conserva la ubicación previa del lobby y los muñecos.
- ArenaBuilder conserva build/reset/run/debug, las losas radiales físicas y su derrumbe individual con aviso. Sustituye lava, grietas volcánicas y cadenas por doce estratos de roca que se estrechan hasta una punta y un fondo de montañas/bosque oscuro. Base y fondo sin colisión ni consultas, para no detener las caídas. Radios 100/45 y límite de ronda 180 segundos conservados. La base queda fija, una de las opciones autorizadas.
- Tienda centrada, tarjetas más grandes con rareza y vista 3D sobre fondo oscuro con gradiente de color. Nombres, descripciones y botones separados; compras con monedas en dorado y Robux en violeta. Rarezas cosméticas en Theme.ShopStyle, sin cambiar el esquema de Skins. Se mantienen las cuatro pestañas y los controles reasignables. Las contras de infusión enumeran todas las derrotas en vez de depender de un único resultado de beatenBy.
- ShopService rechaza SelectWeapon y SelectInfusion si InMatch está activo, antes de modificar datos o personaje. La UI observa InMatch, muestra candado y no conecta selección de armas bloqueadas; tampoco envía selección de infusión bloqueada. El bloqueo cubre las pausas entre rondas siempre que MatchService mantenga InMatch hasta el cierre de la partida.
- HUD: retrato propio con marco rombo y vida inclinada arriba a la izquierda; hasta dos rivales con retratos y vida arriba a la derecha. Abajo quedan Guardia con símbolo de escudo, Stamina, Stun e infusión, conservando rastro de daño, estado ACTIVA/Agotada, color, avisos de stamina y música. Los rivales también tienen rastro de daño. El lobby vuelve a mostrar vida en el panel simple inferior. Overhead conserva avisos/contornos y agrega nombre/color/estado activo de infusión.
- Ajustes nuevos en Theme, ArenaConfig y PolishConfig. Las constantes numéricas de los scripts permitidos se centralizaron en Theme.Metrics; las magnitudes específicas siguen en sus secciones de datos.

## Conexión para Claude (sin editar sus archivos)

1. En MatchService, llamar `require(ReplicatedStorage:WaitForChild("Environment")).apply()` para sustituir el bloque previo de iluminación, o después de ese bloque.
2. En lugar de construir el lobby anterior, llamar `local lobby = require(ServerScriptService:WaitForChild("LobbyBuilder")).build(map)`. Usar `lobby.spawn` como lobbyCFrame, `lobby.practiceCenter` como practicePos y `lobby.dummyHomes` en Dummies.setup. No construir el suelo, braseros y cartel anteriores encima del pueblo nuevo.
3. Mantener InMatch verdadero entre rondas; recién apagarlo al cerrar la partida. La conservación de carga de infusión sigue siendo responsabilidad de la implementación de Claude.
4. El HUD identifica rivales por InMatch y equipo contrario, acorde al servicio actual de una partida simultánea. Si después se habilitan partidas simultáneas, exponer MatchId en jugadores y filtrar también por ese atributo.
5. Como Claude está editando en paralelo, regenerar nuevamente el lugar cuando termine sus cambios para incluir la última versión de sus scripts.

## Verificación

- `node tools/check_lua.js .`: 36 archivos sin problemas detectados.
- Verificación de referencias a Theme.Metrics: todas existen.
- `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`: generado correctamente con Environment y LobbyBuilder incluidos.
- No se abrió Studio ni se ejecutó Play: el chequeo del repositorio es básico, no acredita compilación de Luau, apariencia ni comportamiento en ejecución.

## Cómo probar

1. Conectar los dos módulos desde MatchService y regenerar. En Play, comprobar cielo/luna, lectura de personajes y pueblo sin geometría anterior superpuesta. Recorrer la calle y el puente hasta los tres muñecos.
2. Abrir B; recorrer Armas, Infusión, Skins y Controles. Revisar rarezas, previews y botones con mouse/mando y ventanas pequeñas. Elegir arma/infusión en lobby.
3. Con dos clientes iniciar 1v1; verificar ambos retratos, nombres, vida y rastro blanco al recibir daño. Con cuatro, comprobar los dos rivales y sus equipos. Revisar guardia, stamina, stun, infusión activa y agotamiento.
4. Durante combate y entre rondas, intentar cambiar arma/infusión; verificar candados y que el servidor devuelve el mensaje de bloqueo aun ante una invocación directa. Al terminar, comprobar que se habilitan de nuevo.
5. P → Ir a la arena / Probar derrumbe: verificar caída individual, vacío sin apoyo en la base decorativa, y restauración de losas al reiniciar. Probar ambas escalas de arena y medir FPS en un equipo modesto; reducir Theme.Lighting.Stars.Count si hace falta.
