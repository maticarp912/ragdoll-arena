# Registro de cambios

## Etapa 8 — preparación (9/11/2026, Claude)
- Reparto entre Claude, Codex y Gemini con archivos exclusivos: [[Reparto etapa 8]], `TAREAS_CODEX_7.md`, `TAREAS_GEMINI_1.md`.
- Contratos:
  - `Localization` suma los fragmentos `LocaleCodex` y `LocaleGemini`. Las claves base ganan.
  - El HUD muestra los mensajes de partida con `StatusKey` y `StatusParams`, y se actualiza al cambiar de idioma.
  - Ambos sin probar en Studio. 🟡
- Verificados en el código los 4 puntos de Codex: siguen vigentes.
- Ampliación pedida por el usuario: tablas de clasificación, monedas por victoria y misiones, «Clasificatorias próximamente», dash con objetivo, bug negro del derrumbe, peligros en el vacío, más arenas e interfaz profesional. Reparto rehecho: Gemini interfaz y armas, Codex economía, auras y arenas, Claude combate, ciudad, cielo, pulido e integración.
- Contratos nuevos: `CombatEvents` (eventos de combate para estadísticas, conectado en `Combat`), `InputBridge` (táctil), carpeta `ReplicatedFirst` en el generador.
- Separación de archivos: `LobbyUI.client`, `ArenaBackdrop.client` y `Sky.client` salieron de `Lobby.client` y `Arena.client`.
- Todo en la bóveda: [[Contratos etapa 8]], [[Tareas Codex etapa 8]], [[Tareas Gemini etapa 8]].

## Etapa 8 — trabajo de Claude (9/11)
- Combate: vida +35 % (243 / 290 / 216 / 230 / 317), dash 16 → 12 studs (0,28 → 0,24 s), cargar a un derribado 0,8 → 0,6 (0,45 cargando el lanzamiento), lanzamiento ~30 % más corto (corto 34 → 29; lejano 46 + 34 × carga → 39 + 28 × carga). ✅ vida vista en Studio; 🟡 el resto sin jugar.
- Dash con objetivo fijado: orbita alrededor del objetivo, lo sigue y lo mira; la animación se elige respecto del objetivo. ✅ medido en Studio: distancia constante (8 studs), 64° alrededor, mirando al objetivo todo el tiempo (antes se alejaba de 10,7 a 17,3 en línea recta).
- Aviso de fuertes: punto rojo en la punta con anillo que se cierra y destello al golpear; imbloqueable con centro incandescente que late y doble anillo dorado; ya no se tiñe el arma. ✅ visto en Studio (espada y maza de un muñeco).
- Textos de combate y avisos con clave (ES/EN/PT). Botones táctiles conectados (`InputBridge`), sacudida según `OptShake`, sonidos en el grupo `SFX`. 🟡
- Revisión de Codex: compra y equipamiento de auras ✅ en Studio. Arreglos: reintentos al cargar el perfil antes de expulsar; auras autoiluminadas (con luz de escena casi no se veían) y alas con trazo de humo. 🟡 falta verlas de nuevo.
- **Ciudad, luz**: ~25 % más oscura (luna 2,6 → 2,0, ambiente y exposición más bajos, faroles 2,6 → 2,1, bloom más suave, ventanas ámbar en vez de blancas). ✅ visto en Studio.
- **Bugs visuales de la ciudad encontrados y resueltos** (búsqueda automática de caras superpuestas en el mismo plano, 1.992 piezas):
  1. Piso que aparecía y desaparecía alrededor del ángel: plaza, calle principal y calle cruzada estaban a la misma altura. Ahora cada zona va en su capa (`CityConfig.FloorLayerStep` = 0,06). ✅ visto en Studio.
  2. Cara de un edificio y del pilar de la gran puerta en el mismo plano (parpadeo en la pared): pilar 8 → 8,2 de ancho, centro 16 → 15,9. 🟡
  3. Bordillos alineados con el borde de la calle: 11,6 → 11,5. 🟡
  - Otros 14 pares son caras inferiores apoyadas en el suelo (no se ven). Pendiente: caras inferiores de las baldosas de la arena 1v1 (se ven desde abajo al caer).
- **Stamina por arma** (pedido del usuario): los golpes básicos ahora gastan y el fuerte depende del arma (`WeaponData.Stamina`): Espada 6 / 20, Espadón 10 / 28, Dagas 4 / 14, Estoque 5 / 16, Maza 11 / 30 (básico / fuerte). Máximo 100, recupera 30/s. 🟡
- **Fijar objetivo solo de cerca**: alcance 120 → 28 studs; se suelta a 40 (antes 150). 🟡
- **Reposo en el hombro**: tras 2,5 s sin acción, espadón y martillo descansan sobre el hombro derecho con la hoja/cabeza hacia atrás (ángulos hallados con una búsqueda automática en Studio). Cualquier acción vuelve a la guardia. ✅ visto en Studio con los dos.
- **Agarre a dos manos**: la espada lleva la mano izquierda al mango por IK también durante los golpes (respaldo `offhandZ = -0,42` hasta que Gemini alargue la empuñadura). Estoque a una mano y dagas una en cada mano. 🟡 sin comprobar la posición de la mano.
- Pedido a Gemini: martillo más grande y espada con empuñadura para dos manos (agregado en [[Tareas Gemini etapa 8]]).
- **Combate más ágil** (16:50): la esquiva cancela la recuperación de un golpe básico o de la patada; un M1 pulsado durante la esquiva sale al terminar (buffer 0,35 s); dash cada 0,5 s (antes 0,65), recuperación 0,05 s (antes 0,12), frenado tras el dash ×0,8 durante 0,25 s (antes ×0,6 durante 0,35). ✅ encadenado medido en Studio.
- **Bloquear** regenera stamina al 35 %. **Lanzamiento cargado**: 36 + 16 × carga (antes 39 + 28). 🟡
- **Cuerpo esbelto**: `CombatConfig.Body` (ancho 0,82, profundidad 0,85, cabeza 0,95, tipo de cuerpo 0,35, proporción 0,6) aplicado con `LoadCharacterWithHumanoidDescription`. ✅ escalas aplicadas.
- **Auras**: colores propios y saturados, más partículas, más brillo y alas más anchas. ✅ visto.
- **Revisión de Gemini (ronda 2)**: los contratos en el código están bien; faltaban los pedidos extra, que hizo Claude: táctil oculto con mando, B en menús, espada a dos manos, maza ×1,3 (alcance 7 / 7,5). Error propio corregido: `Auras.lua` tenía `Segments` comentado y rompía la vista previa.
- **Cielo** (`Sky.client`, `Theme.Lighting.Stars`): ~3.200 estrellas doradas en tres tamaños con halos, titileo, luna azulada propia; sin las estrellas blancas ni la luna de Roblox; la cúpula sigue a la cámara. ✅ visto en Studio.
- **Cámara de espectador**: eliminado en una ronda, la cámara sigue a un aliado vivo (o a un rival). 🟡
- **Cuerpo esbelto**, **auras**, **menú de depuración a la derecha**. Ver arriba.
- **Integración rondas 4 y 5 (17:55)**: arreglado `Localization` (fallaba si la pantalla de carga lo pedía antes de que llegaran los idiomas y rompía toda la interfaz) y `AuraFx`; vista previa de auras con el panel escalado en vez de recortado; HUD visible con objetivo fijado; fijado automático al entrar a partida; dash sin «golpecitos». ✅ interfaz, auras, HUD y Templo vistos en Studio.
- En Studio, sin API de DataStore, el perfil es temporal: la persistencia solo se puede probar con el lugar publicado y «Enable Studio Access to API Services».
- **LihFolk V2 (18:20)**:
  - Plugin configurado en `.claude/settings.json` del proyecto.
  - Revisor pasado por los 71 archivos: 0 errores y 3 avisos.
  - Los 3 avisos se arreglaron con comprobación de tipo de `action` en `Queue` (`MatchService`), `Missions` (`MissionService`) y `Settings` (`ShopService`). El revisor queda en 0 avisos.
  - Nuevo `PlayerData.saveSoon`: las opciones, el idioma y la equipación de auras se agrupan en un solo guardado cada 6 s (`Economy.SaveDebounce`). Antes, cada petición del cliente guardaba en el DataStore. 🟡 sin probar en Studio.
  - Nota [[Referencia LihFolk]] y regla C0 en [[Contratos etapa 8]]. Place regenerado.
- **Git (18:30)**: la carpeta del juego es un repositorio (rama `main`, primer commit `3db216c`). Fuera del repositorio: `.rbxlx`, `_backup_*`, `ragdoll-2v2/`, `.log` y el estado de Obsidian. Solo Claude hace commits (regla C0b).

## Lote 7 — 9/11/2026 (Claude)
- **Controles por defecto**: los de la captura del usuario. La **patada** tiene tecla propia: C en teclado y LT/L2 en mando. Agarrar (E / X) ya no patea. Con el ratón libre, el clic derecho funciona así: toque corto = fuerte, arrastrar = cámara. 🟡
- **SFX del usuario**:
  - 18 archivos en `sfx_subir/` con nombre limpio, mapeados en `Assets.Custom`: suenan el 80 % de las veces y conservan la librería como variación.
  - Bajo los impactos fuertes suena una capa extra de la librería.
  - Se pueden usar tramos de los archivos largos.
  - ✅ El usuario los subió (9/11). Los 18 IDs están en `Assets.lua` y cargan en Studio. ⬜ Falta escucharlos jugando.
- **Animaciones con captura de movimiento**:
  - `tools/mixamo_to_r15.py` (Blender) convierte FBX de Mixamo a poses R15.
  - `tools/mocap_to_lua.js` genera `ReplicatedStorage/MocapClips.lua`. Ver [[Animaciones]].
  - Espadón: 3 tajos y golpe fuerte de giro. Maza: 3 golpes y fuerte por arriba. Espada: revés, tajo y golpe descendente.
  - La patada usa «patada bloqueo» para todas las armas.
  - Golpes recibidos: impactos de cuerpo entero al azar, más fuertes con los golpes fuertes.
  - Dagas y estoque siguen procedurales.
  - ✅ En Studio: las poses se ven bien en la vista previa, y M1, patada y fuerte se reproducen sin errores. ⬜ Falta jugar y juzgar la sensación.
- **Ciudad**: las barras de vida de los muñecos ya no se ven a través de los edificios. En la ciudad se ven solo a menos de 45 studs; en partida, siempre. 🟡

## Lote 6 — 9/11/2026
- Claude: orientación en la ciudad (flechas en el suelo, poste con carteles, columna de luz y marcador «ARENA» sobre la puerta). 🟡
- Claude: armería en la plaza con tecla E que abre la tienda. 🟡
- Claude: botones de cola abajo (1v1 / 2v2 / salir) con contador; el servidor los suma a los círculos de la antesala. 🟡
- Claude: fondo de la arena: abismo de basalto con grietas, niebla en movimiento, rocas en órbita, ceniza, escombros y desenfoque del fondo en partida. 🟡
- Claude: carteles de la ciudad traducidos en el cliente. 🟡
- ~~Para Codex: `TAREAS_CODEX_6.md`~~. Codex se quedó sin tokens y lo hizo Claude (los lotes 5 y 6 de Codex):
  - Las **25 skins** que faltaban, modeladas a partir de sus imágenes en `SkinDesigns.lua`, con rareza, precio, colores de estela y descripción en ES, EN y PT. Ver [[Catálogo de skins]]. 🟡
  - Nuevos ayudantes en `WeaponBuilder` para hojas curvas, puntas, púas, arcos, cilindros, una luz y partículas por arma. Si un diseño falla, el arma vuelve al modelo base. 🟡
  - **Armas base con más detalle**: filos biselados, cuero, remaches, lengüetas, anillos y púa superior en la maza. 🟡
  - **HUD**: el icono de infusión late cuando está activa o con la carga llena, y se ladea cuando está agotada. Ya estaban el escudo que se agrieta, las estrellas de Stun y las botas o chevrons de stamina. 🟡
  - **Aura de infusión**: partículas solo en las 4 piezas de hoja más grandes, porque las skins nuevas tienen muchas piezas. 🟡
  - **Tienda**: se revisó. Ya tenía filtros, confirmación, efecto al comprar, rotación y zoom, mando, táctil, encuadre por tamaño y tarjetas que no animan fuera de pantalla. ✅ en código, sin probar en Studio.
  - **Idiomas**: las claves de ES, EN y PT coinciden.
  - `tools/preview_skins.lua`: muestra todas las armas y skins en Studio desde la barra de comandos.
- Claude revisó todo en Studio (9/11):
  - Las 37 armas se construyen sin errores. ✅
  - Ajustes visuales:
    - Metal oxidado cambiado por metal oscuro en Garras del Eclipse, Tumba Esmeralda, Devorador, Diente del Exilio, Corte de Plata, Espinas Carmesí y Mandíbula Antigua.
    - Huesos más grandes en Espinas Vivas.
    - Las alas del Verdugo ahora se ven.
    - Alas más gruesas en Corona del Alba.
    - Cuero menos puntiagudo en el Verdugo.
  - Tienda: la vista grande acuesta el arma y gira sobre su eje. Se arregló el encuadre: la caja del modelo va en ejes del mango y el largo se tomaba como alto, por eso las armas salían chicas. ✅ visto en Studio.

## Lote 5 — 9/11/2026
- Claude: integrado el lote 4 de Codex (estaba en una copia en OneDrive): tienda con rarezas, filtros y confirmación, 32 skins (8 con modelo), Ajustes con idioma, ES/EN/PT. HUD de Codex a medias. 🟡
- Claude: ataque fuerte ~25 % más rápido (sigue más lento que el combo). 🟡
- Claude: ciudad gótica victoriana grande (calles, edificios con ventanas, faroles, torre del reloj, plaza con ángel, cementerio, patio de práctica), muros invisibles, siluetas de fondo, gran puerta con gárgolas y antesala con círculos 1v1 / 2v2 para buscar partida. 🟡
- Claude: filtro dark fantasy (frío, desaturado, contraste), nubes, lluvia, viñeta, relámpagos, cuervos, balanceo de cámara y barrido sobre la ciudad al entrar. 🟡
- Animaciones de Mixamo revisadas: guía en [[Animaciones]]. Resuelto en el lote 7: se convirtieron con Blender sin subirlas.

## Lote 4 — 9/11/2026
- Claude: corregido el BOM de `LobbyBuilder.lua` (el pueblo no cargaba) y el generador quita BOMs. 🟡
- Claude: más luz de luna, ambiente y exposición; piedra de arena y pueblo más clara; faroles más fuertes. 🟡
- Claude: parry más justo (tambaleo 0,45 s, ventana de contraataque 0,7 s con +20 %), rotura de guardia = 2,4 s sin bloquear con Stun ×1,5. 🟡
- Claude: equilibrio de las 5 armas (alcance, barrido, hiperarmadura por golpe, gasto de Guardia, interrupción, golpe en la punta del Estoque, movilidad del dash). Ver [[Equilibrio de armas]]. 🟡
- Claude: cámara libre arriba/abajo con distancia fija y desplazada a la derecha; apuntado con el ratón centrado al cargar, trayectoria de puntos, sin fijar al cargado, control normal al terminar. 🟡
- Etapa 2 repartida: ver [[Pendientes]] y `TAREAS_CODEX_4.md`.

## Lote 3 — 8/11/2026
- Claude: vida +80 %, ataques más lentos y exagerados, sensación por arma, dagas alternando, reposo natural, caminata con la cabeza estable, frenado tras el dash, hitboxes R15, cámara fija en picada, carga de infusión entre rondas. Detalle: `REVISION_CLAUDE_3.md`.
- Codex: cielo de estrellas, pueblo, arena flotante, tienda centrada con rarezas, HUD de partida, bloqueo de arma e infusión. Detalle: `REVISION_CODEX_3.md`.

## Lote 2 — 8/11/2026
- Infusiones (Fuego, Rayo, Hielo, Sombra), carga sobre la cabeza, arreglo del lanzamiento, aura del arma, arena circular. `REVISION_CODEX_2.md`.

## Lote 1 — 8/11/2026
- Núcleo de combate, ragdoll, muñecos, tienda, menú de controles. `REVISION_CODEX.md`.
