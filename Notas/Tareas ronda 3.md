# Tareas ronda 3 (9/11, después de la revisión de Claude en Studio)

Contexto general en [[Reparto etapa 8]], [[Contratos etapa 8]] y [[Peticiones del usuario]]. Reglas de siempre: tocá **solo** tus archivos, no regeneres `Ragdoll Arena.rbxlx`, `node tools/check_lua.js .` tiene que dar OK, y tu reporte separa implementado / comprobado / pendiente de Studio. Los textos nuevos van en tu archivo de idioma con las mismas claves en ES, EN y PT-BR.

**Ya hecho por Claude (no lo repitas):**
- `TouchUI` oculta los botones con mando y suelta Bloquear/Fuerte.
- B cierra `MatchUI` y `LobbyUI` aunque venga como procesado.
- Espada a dos manos (`WeaponBuilder.Info.Sword`: `twoHanded = true`, `offhandZ = -0.42`).
- Maza ×1,3 (`WeaponBuilder.ClassScale`), con el alcance ajustado en `WeaponData`.
- Error de la vista previa de auras (`Auras.lua`).

**También lo hace Claude en paralelo (no lo toques):** combate más ágil (encadenar golpe y dash), bloquear frena la regeneración de stamina, lanzamiento cargado más corto, menú de depuración a la derecha, cuerpo más esbelto, auras con más color, caminos generales de la ciudad, cielo y cámara de espectador.

---

## A. Gemini — arreglos de interfaz (modelo: **Gemini 3.8 Flash, Medium**)
Archivos: `HUD.client.lua`, `LobbyUI.client.lua`, `Shop.client.lua`, `UiTheme.lua`, `UiAssets.lua`, `LocaleGemini.lua`, `Notas/Reporte Gemini etapa 8.md`. Los ves en Studio Claude.
1. **Botones de arriba** (Armería, Ajustes, Misiones, Clasificación, Clasificatorias): el icono se dibuja **encima del texto** («Ar◆ería», «Aj◆tes»…). Icono a la izquierda del texto, con su propio espacio.
2. **HUD en el lobby y en partida**: el panel de barras (Vida, Resistencia, Guardia, Aturdimiento, Fuego) está abajo al centro, **tapa al personaje** y queda pegado a la barra de cola. Llevalo abajo a la izquierda (o achicalo en el lobby) para que el centro quede libre, también en 800×600 y en celular.
3. **Vista previa de auras**: el recuadro «Vista en vivo sobre el pedestal» queda **vacío**; el pedestal del mundo no se ve detrás del panel. Que el aura se vea de verdad en ese recuadro (encuadre de cámara hacia el pedestal y panel con hueco transparente, o el método que prefieras, menos un ViewportFrame, porque no muestra partículas).
4. **Tarjetas de skins**: las armas salen muy finas y chicas en la miniatura. Encuadralas por su tamaño, igual que la vista grande.
5. **Tarjetas de auras**: todas tienen el mismo icono genérico. Dales un icono o color propio por aura (al menos por forma: corona, cadenas, alas, niebla, ojos, runas, humo, brasas, sangre, fractura).
6. **`WaitForChild` sin límite** de `UiTheme`/`UiAssets`/`Localization` al empezar (lo encontró Codex): poné un límite o un `require` protegido.
7. **Nueva disposición pedida por el usuario** (con capturas):
   - **Izquierda, en columna vertical**: Armería, Ajustes, Misiones y Clasificación (uno debajo del otro, a media altura de la pantalla). Los iconos, a la izquierda del texto (punto 1).
   - **Abajo al centro, bien centrados**: Buscar **1v1**, **2v2** y **RANKED** (este último con el aviso «Próximamente»). Hoy los dos botones no están centrados en su barra.
   - **Abajo a la derecha, en vertical**: el HUD de vida, resistencia, guardia, aturdimiento e infusión, como columnas o barras verticales una al lado de la otra.
   - **La tienda ya no tiene la pestaña Clasificatorias**: pasa al botón RANKED de la barra de partida.
   - **El HUD solo se muestra en batalla** (`InMatch`, o al recibir o dar un golpe en el patio de práctica). Paseando por la ciudad no se ve.
   - El menú de depuración (P) pasa a la derecha: lo hace Claude.
8. **Vista previa de auras sobre tu propio personaje** (reemplaza el punto 3): el usuario quiere verse a sí mismo con el aura. Al elegir un aura en la tienda, ponela con `AuraFx.attach(personajeLocal, id, { preview = true })` solo en su cliente, y que la cámara encuadre al personaje en la parte de la pantalla que no tapa el panel (podés achicar o correr el panel a un costado mientras la pestaña Auras está abierta). **Sacá el escenario a 680 studs de altura**: es la causa probable del bug de que «se apagan todas las luces de la ciudad» al elegir algunas auras, porque la cámara se va lejos de los faroles. Al cerrar o cambiar de pestaña, se quita el aura de prueba y vuelve la que tenga equipada.
9. **Precarga** en `ReplicatedFirst/LoadingScreen.client.lua`: antes de entrar, `ContentProvider:PreloadAsync` de texturas, sonidos (`Assets`), imágenes de `UiAssets`, partículas y modelos de armas, con la barra de progreso real. Que no entre al juego con cosas sin cargar.
10. **Tu reporte describe remotos que no existen** (`JoinQueue`, `GetMissions`, `ClaimMission`, `GetOptions` como remoto, `BoardType`, `InBattle`). El código usa bien los contratos; corregí el reporte para que coincida con el código.

## B. Gemini — segunda pasada de arte de las arenas (modelo: **Gemini 4 Argon, High**)

**Pedidos nuevos del usuario (prioridad):**
- **Cada arena tiene que parecer un lugar totalmente aparte**: hoy desde una arena se ven las otras, la ciudad y la lava gigante de la del bosque. Alejalas mucho entre sí (por ejemplo a varios miles de studs; las posiciones están en `ArenaConfig.Modes`) y rodeá cada una con una «máscara» temática que cierre la vista: paredes de cañón, bosque con niebla, cúpula del templo, acantilados y cascadas. Niebla o fondo propio para que no se vea el resto del mapa. Si movés las arenas, avisá las coordenadas nuevas en tu reporte.
- **Piso o fondo bajo la arena**: al caer no se tiene que ver cómo se rompe el mapa. Poné un fondo temático (agua, lava, niebla espesa, bosque) que tape, y un **desenfoque o fundido de cámara al caer** (efecto `Arena*` en `Lighting`, solo para quien cae, desde `ArenaBackdrop.client`).

Archivos (pasan de Codex a Gemini): `ServerScriptService/ArenaBuilder.lua`, `ReplicatedStorage/ArenaConfig.lua`, `StarterPlayer/StarterPlayerScripts/ArenaBackdrop.client.lua`, `StarterPlayer/StarterPlayerScripts/Arena.client.lua`.
Codex armó 4 variantes que rotan (Bosque, Cañón, Templo, Mano) y funcionan, pero en Studio se ven muy básicas:
- **Mano** (`referencias\mano como arena 4.jpg`): hoy son unas formas oscuras chicas y una esfera; **no se entiende como mano**. Tiene que ser una mano gigante de piedra con musgo que sostiene la plataforma desde abajo (palma bajo la arena, dedos que suben por los bordes sin tapar la cámara), cascadas detrás y la cabeza de la estatua a un costado.
- **Cañón** (`referencias\arena 2.jpg`): hoy es un anillo de bloques marrones. Tiene que leerse como un coliseo excavado en un cañón: gradas o terrazas talladas, paredes de roca con estratos, púas metálicas apuntando hacia la arena y el vacío.
- **Templo** (`referencias\arena 3.jpg`): es la mejor; pulila con columnas doradas con jeroglíficos que brillen, agua oscura con reflejos y un haz de luz desde arriba.
- **Bosque**: es la original; dejala como está.

Reglas:
- Cada arena conserva el derrumbe por baldosas, el centro, los puntos de aparición y buena lectura del suelo con la cámara en picada (`CombatConfig.Camera`: distancia 15, picada 24°). Nada debe tapar la cámara desde el borde de la plataforma.
- Adornos lejanos sin colisión (`CanCollide`, `CanQuery`, `CanTouch` en false). Máximo 2.500 piezas por arena, luces y partículas moderadas.
- Sin caras superpuestas en el mismo plano (parpadeo).
- La iluminación global la maneja Claude (`Atmosphere.client`, `Sky.client`): para el ambiente de cada arena usá efectos propios `Arena*` en `Lighting`, activos solo con `InMatch`.
- Si ves que la Mano no llega a buen nivel, sacala de `ArenaConfig.Variants` y avisá.

---

## C. Codex — utilería de la ciudad (modelo: **Sol, Medium**)
Archivo nuevo y exclusivo: `ServerScriptService/CityProps.lua` (más `LocaleCodex.lua` y tu reporte, en una sección «Ronda 3»).
Claude ya dejó el gancho en `LobbyBuilder` (no lo toques):
- Si existe `CityProps`, se llama `CityProps.build(folder, ctx)` al final de la construcción de la ciudad.
- `ctx.origin` es el (0,0,0) de `CityConfig` a ras del suelo. Las coordenadas de `CityConfig` son relativas: X = este, Z = norte.
- Otros campos: `ctx.blocks`, `ctx.walkable`, `ctx.spawn` y `ctx.floorTop` (altura del piso más alto, la plaza: apoyá ahí lo que vaya sobre ella).
- Si definís `CityProps.ReplacesBlock = { [4] = true }`, LobbyBuilder no construye los edificios de esa manzana y la ocupás vos.

Estilo: pueblo de juego de rol **dark fantasy**, con luz cálida localizada. Mirá `referencias\02_lobby_pueblo_noche.webp`, `03_lobby_calle_taberna.webp`, `bar lobby.jpg`, `spawn.jpg` y `referencia ambiente de lobby*.jpg`.

1. **Taberna/alquimista** en la manzana 4 (`{ -60, -36, -30, -2 }`, al oeste de la plaza; reemplazala con `ReplacesBlock[4]`).
   - Fachada hacia la plaza (cara este, x = -36): tejado con forma, vigas de madera, cartel colgante.
   - Ventana o puerta abierta donde se vean estantes con frascos de colores que brillan, y frascos colgantes.
   - Afuera: barriles, banquetas, una mesa y un farol.
   - Texto del cartel con `LocKey` (Lobby.client traduce los TextLabel con ese atributo) y claves en `LocaleCodex`.
2. **Santuario del punto de aparición** en `ctx.spawn` (calle principal, entre x = -12 y 12): círculo de runas doradas que brillan sobre piedra (radio ~6), dos árboles retorcidos con musgo a los costados de la calle, lucecitas cálidas y algo de niebla baja. El jugador aparece ahí: no lo tapes ni le pongas colisiones en el centro.
3. **Tableros de clasificación** (contrato C7):
   - Cuatro tableros de piedra y madera en la plaza, alrededor del ángel (0, -40), por ejemplo en (±24, -26) y (±24, -54), mirando al ángel.
   - Cada uno es una parte con la etiqueta de CollectionService `LeaderboardBoard` y el atributo `Board` = `Wins` / `Kills` / `Knockdowns` / `Coins`, con la cara `Front` (de unos 10 × 7 studs) mirando a la plaza.
   - El dibujo lo hace `Leaderboards.client` (Gemini): vos solo hacés la estructura.
4. **Caminos y vida** (pedido del usuario: «dale más vida y movimiento»): caminos de piedra irregulares que salgan de la plaza hacia la taberna, el patio de práctica y el santuario. Cosas que se muevan: luciérnagas, humo de chimeneas, carteles y faroles que se balancean, hojas que caen, cuervos que se posan, agua de una fuente. Animalo en el cliente si hace falta: creá `StarterPlayer/StarterPlayerScripts/CityLife.client.lua`, que también es tuyo.
5. **Ambiente**:
   - Racimos de hongos luminosos (azul, violeta y verde suaves) y faroles colgantes en la calle cruzada (z -50 a -30) y en la plaza.
   - Vegetación (arbustos, hiedra) al pie de los edificios, sin invadir el paso.

Reglas:
- Dejá libres al menos 8 studs de paso en calles y plaza.
- Nada sobre los círculos de cola (antesala, z ≈ 192) ni sobre la armería (-26, -60).
- Adornos sin colisión salvo paredes y mostradores.
- ≤ 900 piezas en total y ≤ 12 luces.
- Sin caras superpuestas en el mismo plano.
- Valores numéricos en tablas al inicio del módulo.


---

## A2. ~~Gemini~~ → pasó a Codex en [[Tareas ronda 4]] (9/11, 17:30) — arreglos tras la prueba de Claude en Studio
Mismos archivos que la sección A. Visto por Claude en Studio el 9/11 a las 17:24:
1. **HUD vertical roto**: abajo a la derecha se ve **una sola columna vacía** (icono rojo y barra oscura), no las 5. Además aparece **también en la ciudad** sin combate, y no se llenó al golpear a un muñeco. Revisá que las 5 columnas se vean, que los rellenos reflejen los valores (vida, resistencia, guardia, aturdimiento, infusión) y la lógica de mostrar/ocultar: oculto paseando, visible en partida y al pegar o recibir un golpe en el patio de práctica.
2. **Vista previa de auras**: al elegir un aura la cámara se mueve, pero **el personaje no aparece** en la zona libre de la derecha (se ve la calle vacía), y el recuadro todavía dice «Vista en vivo sobre el pedestal». Encuadrá de verdad al personaje local en la mitad derecha y sacá ese recuadro o texto.
3. **Botón RANKED**: en la barra de partida dice «Clasificatorias» y la etiqueta «Próximamente» se ve como un **rectángulo negro vacío** encima. Tiene que decir **RANKED** con la etiqueta legible.
4. **Precarga**: la Salida se llena de «ContentId rbxassetid://… failed due to: Asset type does not match requested type». Estás precargando IDs de sonido (y quizá de animación) como si fueran imágenes. Precargá los sonidos creando instancias `Sound` con su `SoundId`, y las imágenes con `ImageLabel`/`Decal`; no pases IDs sueltos.
5. **Botón Armería del dock izquierdo**: al hacerle clic no abrió la tienda (con el evento `ToggleMenu` sí abre). Revisá que los 4 botones del dock abran su panel con ratón, toque y mando.
