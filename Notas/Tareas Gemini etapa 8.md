# Tareas de Gemini — etapa 8

> Este archivo **es el prompt completo** para Gemini (en Antigravity). Sesión larga: trabajá por fases, en orden, y reportá al terminar cada fase.

## Quién sos y con quién trabajás
Sos una de tres IA trabajando **al mismo tiempo** sobre la misma carpeta:
- **Claude** coordina e integra: combate, animaciones, ciudad, cielo, sonido y pruebas en Studio. Es el único que regenera el place.
- **Codex**: economía, estadísticas, misiones, tablas de clasificación, compras, guardado, auras (datos, efectos y servidor) y arenas.
- **Vos (Gemini)** tenés dos frentes:
  1. **Toda la interfaz del juego.** Trabajás como **diseñador senior de interfaces de videojuegos y diseñador gráfico**: sistema de diseño, jerarquía, tipografía, color, iconografía, estados, movimiento y adaptación a cada pantalla. No se trata de «hacer botones»: tiene que verse como un juego comercial pulido.
  2. **Los modelos de las armas**: armas base, skins y, donde valga la pena, mallas hechas en Blender.

Cada archivo tiene **un solo responsable**. Tocá solo los tuyos.

## Proyecto
- Carpeta: `F:\RobloxJuegos\Plataforme 2v2`. Juego: **Ragdoll Arena**, PvP 1v1/2v2 en Roblox **R15** con ragdoll y estética **dark fantasy** (oscuro, dorado viejo, piedra, hierro, velas).
  - Cinco armas: Espada (`Sword`), Espadón (`Greatsword`), Dagas (`Dagger`, una en cada mano), Estoque (`Rapier`) y Maza (`Mace`).
  - Cuatro infusiones de combate: Fuego, Rayo, Hielo y Sombra.
  - Idiomas ES, EN y PT-BR.
- Vault de Obsidian con todo el contexto: `Notas/`. Leé primero:
  - `Notas/00 Inicio.md`, `Notas/Estado.md` y `Notas/Decisiones.md`.
  - `Notas/Reparto etapa 8.md`: quién hace qué.
  - `Notas/Contratos etapa 8.md`: **obligatorio**, son los puntos de conexión con las otras IA.
  - `Notas/Catálogo de skins.md` y `Notas/Skins y precios.md`.
- Referencias de interfaz en `referencias\`:
  - `08_tienda_ejemplo.webp` y `06_inventario_ejemplo.webp`: tienda e inventario.
  - `07_postura_combate_y_hud.webp`: HUD.
  - `idea pantalla de carga.png`: pantalla de carga.
  - `logos infusiones(reversionarlas).jpg`: iconos de infusión, para **reversionar**, no copiar.
  - `infusiones ref2.jpg`.
  - `bar lobby.jpg`, `spawn.jpg`, `referencia ambiente de lobby*.jpg`, `02_lobby_pueblo_noche.webp` y `03_lobby_calle_taberna.webp`: ambiente general.
- Fotos de referencia de las armas: `F:\RobloxJuegos\skins armas\` (carpetas `espadas`, `espadon`, `dagas`, `estoque`, `martillo hacha`). Cada skin dice en `source` qué foto la inspiró. También `referencias\muestra skins.png`.
- Blender está instalado (Microsoft Store). Sin interfaz: `%LOCALAPPDATA%\Microsoft\WindowsApps\blender-launcher.exe -b --python <script.py> -- <args>`. El `.exe` de la Store da «Acceso denegado».
- Chequeo: `node tools/check_lua.js .` (podés usarlo; solo lee). `node tools/make_rbxlx.js` **no**: lo corre Claude.

## Reglas
1. **Solo tus archivos**. Si necesitás un cambio en otro, pedilo en tu reporte, en «Pedidos a otros», con el cambio exacto.
2. **No regeneres** `Ragdoll Arena.rbxlx`. No copies desde backups.
3. Todo texto visible nuevo va en `ReplicatedStorage/LocaleGemini.lua`, con las **mismas claves en ES, EN y PT-BR**. Sin repetir claves de `LocaleES/EN/PT.lua`. Nada de texto fijo en español dentro de la interfaz: todo con `Localization.t`.
4. **No cambies IDs de skins existentes** (hay compras guardadas). No inventes IDs de Roblox:
   - producto sin crear = `productId = 0`;
   - malla sin subir = `MeshId = 0`;
   - imagen sin subir = `0`, con un respaldo dibujado con frames o texto.
5. Probablemente no puedas abrir Studio: separá **implementado**, **comprobado** (y cómo) y **pendiente de probar en Studio**. Claude lo prueba al integrar.
6. Tu reporte va en el vault: `Notas/Reporte Gemini etapa 8.md` (es tuyo). Actualizalo al terminar cada fase.

## Archivos exclusivos tuyos
| Archivo | |
|---|---|
| `ReplicatedStorage/WeaponBuilder.lua`, `SkinDesigns.lua`, `Skins.lua` | existentes |
| `ReplicatedStorage/WeaponMeshes.lua` | **nuevo**, solo si usás mallas |
| `ReplicatedStorage/UiTheme.lua`, `UiAssets.lua` | **nuevos** (sistema de diseño e IDs de imágenes) |
| `ReplicatedStorage/LocaleGemini.lua` | creado vacío por Claude; ahora es tuyo |
| `StarterPlayer/StarterPlayerScripts/Shop.client.lua` | existente (tienda) |
| `StarterPlayer/StarterPlayerScripts/HUD.client.lua` | existente (conservá el contrato C2 que agregó Claude) |
| `StarterPlayer/StarterPlayerScripts/Settings.client.lua` | existente |
| `StarterPlayer/StarterPlayerScripts/LobbyUI.client.lua` | existente (Claude separó ahí la barra de cola) |
| `StarterPlayer/StarterPlayerScripts/Leaderboards.client.lua`, `MatchUI.client.lua`, `TouchUI.client.lua` | **nuevos** |
| `ReplicatedFirst/LoadingScreen.client.lua` | **nuevo** |
| `tools/preview_skins.lua`, `tools/blender/`, `modelos_armas/`, `ui_assets/` | carpetas y herramientas tuyas |
| `Notas/Reporte Gemini etapa 8.md` | **nuevo** |

**Solo lectura**: todo lo demás. Importantes:
- `Theme.lua` (de Claude, lo usa todo el juego: tus tokens nuevos van en `UiTheme.lua`).
- `Controls.client.lua` (crea el `BindableEvent` `ToggleMenu` en el jugador y lee el atributo `MenuOpen`: mantené ese funcionamiento).
- `Overhead.client.lua` (barras sobre las cabezas y avisos de ataque, de Claude).
- `Localization.lua`, `InputMap.lua`, `Auras.lua`/`AuraFx.lua`/`Missions.lua` (de Codex, cuando existan), `WeaponData.lua` y `AnimClips.lua`.

## Contratos clave (detalle en `Notas/Contratos etapa 8.md`)
- **Consumís**: C2 (estado de partida), C3 (cola), C7 (tablas de clasificación), C8 (misiones), C9 (resumen de partida y avisos de eliminaciones), C10 (opciones), C11 (auras en la tienda), C12 (táctil), C13 (pantalla de carga).
- **Producís**: C4 (el arma) y C15 (`UiTheme`).
- Los módulos de Codex se están escribiendo al mismo tiempo. Programá contra el contrato y, si un módulo todavía no existe, que tu interfaz no se rompa: muestra «sin datos» o «próximamente» y usa `FindFirstChild` o `pcall` en los `require`.

## Fase 1 — Espada base y skin de Robux
- La espada por defecto (`Designs.Sword`: guarda gótica con cuernos curvos, rizos, ganchos y pomo en espina) es demasiado elaborada para ser gratuita.
  - Copiala **sin cambios visuales** a `SkinDesigns` como diseño `RequiemHorns`.
  - Creá en `Skins.lua` la skin **`Requiem`**: `weapon = "Sword"`, `rarity = "Epic"`, `currency = "Robux"`, `price = 149`, `productId = 0`, `design = "RequiemHorns"` y una estela acorde. Rareza y precio los propone Claude, al nivel de «Linaje Carmesí».
  - Nombre y descripción en `LocaleGemini` (`skin.Requiem`, `skinDesc.Requiem`), por ejemplo «Réquiem Astado».
- **Espada base nueva** sencilla y de calidad: hoja recta con acanaladura, guarda en cruz simple, cuero con vueltas, pomo de disco, biseles y algo de desgaste. El id `Default` no cambia.
- Revisá las otras armas base. Si alguna es demasiado elaborada para ser gratuita, proponelo en el reporte (no la conviertas).
- **Vista previa = arma equipada** (C4): hoy `build()` puede usar para `Default` un modelo de `ServerStorage/Weapons` o una malla de `Assets`, pero `buildModel()` no. Unificalo.

## Fase 2 — Espadones (prioridad de modelado)
- Base y todas sus skins (`Relic14`–`Relic19` y las de `Skins.Designs` que sean de espadón): más grandes, anchos y pesados. Inspiración: la masa del espadón de Guts y la silueta del de Zabuza, sin copias literales.
- Empuñadura larga acorde para dos manos. Si cambiás `gripZ` u `offhandZ` en `WeaponBuilder.Info`, anotá el valor viejo y el nuevo: Claude ajusta las animaciones de Mixamo.
- **Sin ventaja oculta**: el alcance real lo define `WeaponData` (de Claude), no el modelo. Todas las skins de una misma clase tienen el **mismo largo de hoja** (`BladeTip` dentro de ±5 % del valor de la clase). Proponé el largo nuevo del espadón; Claude decide si ajusta el alcance.
- Avisá en el reporte apenas termines esta fase: Claude la necesita para probar las animaciones.

## Fase 3 — Sistema de diseño, tienda y HUD
1. **`UiTheme.lua`**: paleta (fondos, superficies, texto, dorado, rarezas, estados), tipografía (fuentes de Roblox con `Font.new`/`FontFace`: una de títulos con carácter fantasy y una de lectura clara), escalas de tamaño, espaciados, radios, trazos, sombras, duraciones y curvas de animación, y componentes reutilizables (botón primario/secundario, pestaña, tarjeta, panel, ventana modal, aviso flotante, barra de progreso, insignia de rareza, precio). Estados: hover, presionado, seleccionado, deshabilitado y **foco de mando** visible.
2. **Tienda** (`Shop.client`): rediseño completo con pestañas Armas, Skins, Infusiones, **Auras** (nueva) y **Clasificatorias «Próximamente»**.
   - Filtros y rareza, vista grande con rotación.
   - Confirmación de compra con la selección del mando **encerrada en el diálogo**; B cierra. Este es el bug técnico que detectó Codex y ahora es tuyo.
   - Estado claro para lo de Robux sin producto («próximamente») y para «equipada».
   - **Auras**: vista previa en el mundo (pedestal de vista previa con su propia cámara) usando `AuraFx.attach(..., { preview = true })`, porque las partículas no se ven en ViewportFrame. Las de cuerpo, sobre un maniquí o el avatar; las de arma, sobre `WeaponBuilder.buildModel` del arma equipada.
   - Compra y equipamiento con las acciones de C11.
3. **HUD** (`HUD.client`): rediseño.
   - Conservá todos los datos actuales: vida, Stun, Guardia, stamina, carga e icono de infusión, retratos, estado de partida con C2.
   - Agregá el aviso de eliminaciones (C9) arriba a la derecha.
   - Respetá las zonas seguras (`GuiService:GetGuiInset`, la muesca del móvil) y no tapes la acción en el centro.

### Agregado del 9/11 (nombres de las referencias)
- **Pestaña Infusiones**: seguí `referenciasinfusiones ref2.jpg`: una tarjeta alta por infusión, con ilustración o fondo temático, icono reversionado arriba, nombre, lema corto y marco dorado. Solo las 4 infusiones del juego (Fuego, Rayo, Hielo, Sombra): no agregues elementos nuevos.
- **Iconos de infusión**: `logos infusiones(reversionarlas).jpg` pide versiones propias, no copias.
- **Pantalla de carga**: `idea pantalla de carga.png`.

### Agregado del 9/11 (pedido del usuario: agarre a dos manos y martillo)
Hacelo junto con la fase 2, antes de la interfaz:
- **Martillo/maza más grande**: base y todas sus skins (incluidas las mazas óseas nuevas). Cabeza más voluminosa y mango más largo para dos manos (que se lea como martillo de guerra pesado). Mismo largo por clase en todas las skins. Avisá el nuevo `gripZ`/`offhandZ`/`trail`.
- **Espada a dos manos**: el usuario quiere que todas las armas se agarren con dos manos salvo el estoque (las dagas siguen una en cada mano). En `WeaponBuilder.Info.Sword` poné `twoHanded = true` y un `offhandZ` acorde, con una empuñadura lo bastante larga para dos manos (espada bastarda) en la espada base y en todas las skins de espada (incluida `Requiem`). Mientras no lo cambies, Claude usa `offhandZ = -0.42` como respaldo (`AnimClips.OffhandFallback`).
- Claude ya hizo el **reposo en el hombro** del espadón y el martillo (animación). Si cambiás mucho el mango, avisá para reajustar la postura.

### Agregado del 9/11 (beta con celular y mando)
- El beta tester juega **en celular con un mando conectado**. `TouchUI.client` tiene que ocultar los botones táctiles mientras haya un mando en uso (`UserInputService.GamepadEnabled` / `GetLastInputType()` y los eventos `GamepadConnected`/`LastInputTypeChanged`) y volver a mostrarlos si toca la pantalla sin mando.
- Toda la interfaz tiene que ser navegable con mando también en pantalla de celular (foco visible, B para volver) y legible en pantalla chica.

## Fase 4 — Lobby, menús, táctil y carga
1. **`LobbyUI.client`**: barra de cola (C3) rediseñada, botón **Clasificatorias** con panel «Próximamente», botón y panel de **Misiones diarias** (C8: progreso, recompensa, reclamar, tiempo hasta el reinicio) y acceso a las **tablas de clasificación** también desde el menú.
2. **`Leaderboards.client`**: `SurfaceGui` de cada tablero de la ciudad (C7: Victorias, Eliminaciones, Derribos, Monedas). Top 10, con el jugador local resaltado si aparece; legible a distancia y coherente con la ciudad dark fantasy.
3. **`MatchUI.client`**: pantalla de fin de partida (C9: resultado, eliminaciones, derribos, daño, monedas ganadas y de misiones) y aviso de eliminaciones si no lo pusiste en el HUD.
4. **`Settings.client`**: rediseño. Volumen de música y efectos, sacudida de cámara y escala de interfaz (C10), más controles e idioma (ya existen). Aplicá el volumen a `SoundService.SFX` y `SoundService.Music` según los atributos `OptSfx` y `OptMusic`, y la escala a toda tu interfaz.
5. **`TouchUI.client`**: controles táctiles (hoy **no hay**: el juego es injugable en móvil). Botones grandes en la zona del pulgar derecho para Ataque, Fuerte, Bloquear (mantener), Esquivar, Patada, Agarrar, Infusión, Fijar objetivo y Menú, usando `InputBridge` (C12). Solo visibles con `TouchEnabled`. Respetan la palanca de movimiento de Roblox, a la izquierda.
6. **`ReplicatedFirst/LoadingScreen.client.lua`**: pantalla de carga basada en `idea pantalla de carga.png`, con barra de progreso real (`ContentProvider`), consejos de juego traducidos y transición suave.
7. **Iconos** (`ui_assets/` + `UiAssets.lua`): infusiones reversionadas, monedas, Robux, rarezas, misiones, trofeo, calavera, derribo, ajustes, etc. Entregá PNG (con SVG fuente si podés) y una guía paso a paso para que el usuario los suba (Creator Hub → Decals/Images). Hasta tener IDs, cada icono tiene su respaldo dibujado.

## Fase 5 — Resto de armas
- **Espadas**: proporciones más realistas de hoja, guarda, pomo, cuero y desgaste.
- **Dagas**: están bien; solo mejoras puntuales.
- **Mazas y martillos**: bien. La favorita del usuario es **Mandíbula Antigua** (`Relic31`, diseño `AncientMaw`). Modelá **2 o 3 mazas nuevas** con ese lenguaje óseo, monstruoso y oscuro (ids nuevos, por ejemplo `Maw02` y `Maw03`; Coins, Epic, 2.800–4.000).
- **Hachas: no**. Quedan para otra etapa.
- **Piezas o Blender**: decidí y justificá dónde conviene cada cosa.
  - Mallas: scripts en `tools/blender/`, exportaciones en `modelos_armas/` (escala en studs, origen en el mango, hoja hacia +Z) e instrucciones de subida para el usuario.
  - `WeaponMeshes.lua`: `{ [diseño] = { MeshId = 0, TextureId = 0, ... } }`. Con `MeshId = 0` se usa el modelo de piezas.
  - En tiempo de ejecución `MeshPart.MeshId` no se puede asignar: usá `SpecialMesh` sobre una `Part` o `AssetService:CreateMeshPartAsync`, y explicá la elección.
- Opcional: rehacer los 7 diseños antiguos de `Skins.Designs` con `SkinDesigns`.
- **Presupuesto por arma**: ≤ 110 piezas por skin (armas base ≤ 60), una luz como máximo, ≤ 2 emisores, mallas ≤ 5.000 triángulos. Contratos del arma (C4) intactos.

## Calidad de interfaz exigida
- Coherencia total con `UiTheme`: nada de colores o tamaños sueltos.
- Legible en **escritorio, pantalla chica (800×600), móvil (por ejemplo iPhone en el emulador de Studio) y TV con mando**. Usá `UIScale`, `UISizeConstraint`, `UITextSizeConstraint` y `AutomaticSize`. Áreas táctiles de 44 px como mínimo.
- Navegación completa con mando: foco inicial, orden lógico y B para volver.
- Animaciones cortas (120–250 ms) y con intención; nada que tape el combate.
- Contraste suficiente sobre fondos oscuros; las rarezas se distinguen por algo más que el color (borde, forma o etiqueta).
- Rendimiento: sin `Heartbeat` innecesarios; las listas largas no se reconstruyen en cada fotograma.

## Criterio de terminado
- `node tools/check_lua.js .` da OK.
- `LocaleGemini` tiene las mismas claves en los tres idiomas.
- Todas las armas y skins se construyen sin errores. Dejá `tools/preview_skins.lua` actualizado, incluidas `Requiem` y las mazas nuevas.
- La interfaz no se rompe si todavía faltan los módulos de Codex.
- `Notas/Reporte Gemini etapa 8.md` incluye:
  - archivos cambiados;
  - decisiones de diseño (paleta, tipografía, componentes) con su porqué;
  - cambios por arma y skin, piezas por skin y largo de hoja por clase (antes y después);
  - cambios en `WeaponBuilder.Info`;
  - mallas e iconos y sus pasos de subida;
  - implementado / comprobado / pendiente de Studio;
  - lista de pruebas para Claude;
  - «Pedidos a otros».


---

## Arreglos de la revisión (9/11, Codex + Claude)
Hacelos junto con los pedidos de agarre a dos manos y martillo:
1. **TouchUI** (aprox. línea 131, `updateVisibilityAndScale`): solo mira `TouchEnabled` y `MenuOpen`. Tiene que ocultar los botones cuando hay mando en uso (`GetLastInputType` / `LastInputTypeChanged` / `GamepadConnected`) y soltar `Block` (`InputBridge.press("Block", false)`) si se ocultan o se corta un toque mientras se bloquea.
2. **MatchUI** (aprox. 246) y **LobbyUI** (aprox. 651): el botón B exige `not processed` y con mando puede venir marcado como procesado, así que no cierra. Usá el mismo criterio que `Shop`.
3. **Resiliencia**: varias interfaces hacen `WaitForChild` sin límite de `UiTheme`/`UiAssets`/`Localization` al empezar; si falta uno se quedan colgadas para siempre. Usá un tiempo límite o `require` protegido.
4. **HUD en el lobby** (visto por Claude en Studio): el panel de barras quedó abajo al centro, justo encima de los botones de cola, y tapa al personaje. Ubicalo para que no se superponga con la barra de cola ni con el centro de la acción (por ejemplo, abajo a la izquierda), también en pantalla chica.
