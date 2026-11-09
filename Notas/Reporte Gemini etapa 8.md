# Reporte de Gemini — etapa 8

> Actualizado al completar las 5 fases. Leyenda: ✅ comprobado · 🟡 implementado, pendiente de Studio.

---

## Resumen de archivos tocados (exclusivos de Gemini)

- **Módulos en `ReplicatedStorage/`**:
  - `ReplicatedStorage/WeaponBuilder.lua` (modificado — Fases 1, 2 y 5)
  - `ReplicatedStorage/SkinDesigns.lua` (modificado — Fases 1, 2 y 5)
  - `ReplicatedStorage/Skins.lua` (modificado — Fases 1, 2 y 5)
  - `ReplicatedStorage/WeaponMeshes.lua` (**nuevo** — Fase 5)
  - `ReplicatedStorage/UiTheme.lua` (**nuevo** — Fase 3, Contrato C15)
  - `ReplicatedStorage/UiAssets.lua` (**nuevo** — Fases 3 y 4)
  - `ReplicatedStorage/LocaleGemini.lua` (modificado — Fases 1, 3, 4 y 5; 87 claves idénticas en `ES`, `EN` y `PT-BR`, 0 colisiones)
- **Scripts de cliente en `StarterPlayer/StarterPlayerScripts/` y `ReplicatedFirst/`**:
  - `StarterPlayer/StarterPlayerScripts/Shop.client.lua` (rediseñado — Fase 3)
  - `StarterPlayer/StarterPlayerScripts/HUD.client.lua` (rediseñado — Fase 3)
  - `StarterPlayer/StarterPlayerScripts/LobbyUI.client.lua` (rediseñado — Fase 4)
  - `StarterPlayer/StarterPlayerScripts/Leaderboards.client.lua` (**nuevo** — Fase 4)
  - `StarterPlayer/StarterPlayerScripts/MatchUI.client.lua` (**nuevo** — Fase 4)
  - `StarterPlayer/StarterPlayerScripts/Settings.client.lua` (rediseñado — Fase 4)
  - `StarterPlayer/StarterPlayerScripts/TouchUI.client.lua` (**nuevo** — Fase 4)
  - `ReplicatedFirst/LoadingScreen.client.lua` (**nuevo** — Fase 4)
- **Herramientas y assets en disco**:
  - `tools/preview_skins.lua` (actualizado — Fase 5)
  - `tools/blender/generate_weapons.py` (**nuevo** — Fase 5)
  - `modelos_armas/*.fbx` y `*.obj` + `modelos_armas/GUIA_SUBIDA_MALLAS.md` (**nuevos** — 16 armas/skins exportadas por Blender headless)
  - `ui_assets/*.png` y `*.svg` + `ui_assets/GUIA_SUBIDA_ICONOS.md` (**nuevos** — 19 pares de iconos 256×256 PNG + SVG)

---

## Fase 1 — Espada base, skin `Requiem` y unificación de `WeaponBuilder` (C4)

### 1. Archivos modificados en Fase 1
- `ReplicatedStorage/SkinDesigns.lua`: copiado íntegro y sin cambios visuales el diseño gótico antiguo de la espada base como `D.RequiemHorns` (con su paleta oscura original `rgb(32, 32, 37)` / `rgb(44, 42, 47)`).
- `ReplicatedStorage/Skins.lua`: creada la skin `Requiem` (`weapon = "Sword"`, `rarity = "Epic"`, `currency = "Robux"`, `price = 149`, `productId = 0`, `design = "RequiemHorns"`, `trail = Color3.fromRGB(165, 145, 210)`) e incluida en `Skins.Order`.
- `ReplicatedStorage/LocaleGemini.lua`: añadidas las claves `skin.Requiem` y `skinDesc.Requiem` en `ES` («Réquiem Astado»), `EN` («Horned Requiem») y `PT-BR` («Réquiem Cornudo»).
- `ReplicatedStorage/WeaponBuilder.lua`:
  - Nuevo diseño `Designs.Sword` para el id `Default`: espada de caballero sobria y realista (hoja recta de doble filo con biseles `EdgeBevel`, acanaladura oscura `Fuller`, nervio hacia la punta `BladeRidge`, mellas de desgaste `WearMark`, ricasso corto, guarda en cruz simple con puntas ensanchadas y escudete `Ecusson`, empuñadura de cuero con vueltas inclinadas y anillos, y pomo de disco biselado con remache de espiga `PeenBlock`). Usa **28 piezas** (dentro del presupuesto ≤ 60 para armas base) y conserva el largo de hoja exacto de la clase (`z = 0.96 → 5.10`).
  - **Unificación `build()` / `buildModel()` / `addOffhand()` (Contrato C4)**: centralizada en `populateWeapon(container, weaponId, skinId)` usando `populateFromStorage`, `populateFromMesh` y `buildInto`, de modo que la vista previa en tienda/auras (`buildModel`) construye exactamente el mismo modelo que el `Tool` equipado (`build`).
  - **Corrección crítica en `BladeTip` y `BladeBase` (C4)**: ninguna pieza `BasePart` se llama `"BladeTip"` ni `"BladeBase"`, y `Builder` registra la posición 3D real de la punta visible (`b.tipPos`, incluyendo `Builder:tip`, `Builder:strip` y `Builder:spike`) para colocar el `Attachment` `BladeTip` exactamente en la punta visible de cada hoja.

---

## Fase 2 — Espadones (prioridad de modelado)

### 1. Cambios implementados en Fase 2
- `ReplicatedStorage/WeaponBuilder.lua`:
  - **`WeaponBuilder.Info.Greatsword` actualizado**:
    - `gripZ`: `0.45` → **`0.55`** (mano derecha adelantada hacia el arriaz).
    - `offhandZ`: `-0.45` → **`-0.65`** (mano izquierda retrasada hacia el pomo, dando una separación de **1.20 studs** acorde a la nueva empuñadura a dos manos de **2.30 studs**).
    - `trail`: `{ 1.3, 6.0 }` → **`{ 1.4, 7.6 }`** (estela alineada con la hoja colosal).
  - **`Designs.Greatsword` (`Default`)**: reconstruido con masa colosal inspirada en el espadón de Guts y el perfil de corte pesado de Zabuza (`1.56` studs de ancho × `0.28` de espesor, punta en **`z = 7.60`**, **39 piezas**).
- `ReplicatedStorage/SkinDesigns.lua`:
  - Reconstruidos y escalados a longitud colosal uniforme (`7.58–7.60` studs) y ancho `1.48–1.64` studs todos los espadones: `D.EmeraldTomb` (`Relic14`, 35 pzs), `D.Devourer` (`Relic15`, 47 pzs), `D.RoyalMourning` (`Relic16`, 48 pzs), `D.DuskCross` (`Relic17`, 52 pzs), `D.Shroud` (`Relic18`, **nuevo diseño dedicado completo**, 50 pzs) y `D.AbyssWings` (`Relic19`, 49 pzs).

---

## Fase 3 — Sistema de diseño (`UiTheme.lua`), Tienda (`Shop.client.lua`) y HUD (`HUD.client.lua`)

### 1. `ReplicatedStorage/UiTheme.lua` (Contrato C15)
- **Paleta Dark Fantasy**: fondos obsidiana (`BgPrimary`, `BgSecondary`, `BgElevated`, `BgOverlay`), bordes en bronce antiguo y oro ceniciento (`StrokeSubtle`, `StrokeMedium`, `StrokeGold`, `StrokeAccent`), textos jerarquizados y colores semánticos de barras (`Health`, `HealthTrail`, `Stamina`, `Guard`, `Stun`).
- **Tokens de rareza (`UiTheme.Rarities`)**: las 5 rarezas (`Common`, `Rare`, `Epic`, `Legendary`, `Mythic`) se distinguen simultáneamente por **color**, **grosor de borde**, **forma de insignia** y **símbolo** (`•`, `◆`, `❖`, `✦`, `★`).
- **Temas de tarjetas de Infusión (`UiTheme.InfusionCards`)**: gradientes oscuros, borde dorado y color de resplandor propios para `Fire`, `Lightning`, `Ice` y `Shadow`.
- **Tipografía, tamaños y animaciones**: `FontFace` (`Cinzel`, `SourceSansPro`, `RobotoMono`) + fallback `Enum.Font`, escala proporcional (`UiTheme.computeScale(viewportSize, player)` combinando resolución y atributo `OptUiScale`), sonidos UI (`UiTheme.playSound`), anillo de foco para mando (`UiTheme.bindGamepadFocus`) y trampa de foco modal (`UiTheme.trapGamepadFocus` / `UiTheme.releaseGamepadFocus`).
- **Componentes reutilizables**: `panel`, `ornamentCorners`, `label`, `button`, `tabButton`, `rarityBadge`, `progressBar`, `clearChildren`.

### 2. `ReplicatedStorage/UiAssets.lua`
- Catálogo de IDs (`UiAssets.Ids`, todos en `0` por defecto hasta subir los PNG de `ui_assets/`).
- Generador procedural de iconos multi-capa (`UiAssets.icon(kind, size, parent)`) y arte de fondo vertical para las tarjetas de infusión (`UiAssets.infusionCardArt(infusionId, parent)`), con **rework completo** de los medallones de las 4 infusiones (`Fire`, `Lightning`, `Ice`, `Shadow`).

### 3. `StarterPlayer/StarterPlayerScripts/Shop.client.lua`
- **5 pestañas en barra superior**: `Armas`, `Skins`, `Infusiones`, `Auras` y `Clasificatorias` («Próximamente»).
- **Pestaña Infusiones (Agregado del 9/11 — estilo `referencias\infusiones ref2.jpg`)**:
  - Exactamente **4 tarjetas verticales altas** dispuestas una al lado de la otra para `Fire` (Fuego), `Lightning` (Rayo), `Ice` (Hielo) y `Shadow` (Sombra).
  - Cada tarjeta incluye fondo temático ilustrado con gradiente, medallón rework en la parte superior, nombre en grande, lema corto traducido (`infusionMotto.*`), precio o estado (`En propiedad` / `Equipado`), borde dorado al seleccionar/equipar y panel inspector con afinidad elemental (`Fuerte contra` / `Débil contra`).
- **Pestaña Auras (Contrato C11)**:
  - Filtros por categoría (`Todas`, `Aura de cuerpo`, `Aura de arma`), rareza y estado.
  - **Vista previa 3D en vivo en el mundo (`ShopAuraPreviewStage`)**: cuando el jugador abre la pestaña Auras, la cámara enfoca un pedestal iluminado con un maniquí R15 (`Body`) o el modelo 3D real del arma equipada (`Weapon`) sobre el cual se ejecuta `AuraFx.attach(target, auraId, { preview = true })` para mostrar las partículas reales (`ParticleEmitter`, `Beam`, `PointLight`) en vivo.
  - Conectado a `Remotes.BuyAura`, `Remotes.EquipAura` y `Remotes.UnequipAura` (`""`).
- **Modal de confirmación de compra**: atrapa el foco del mando entre «Cancelar» y «Confirmar» (`UiTheme.trapGamepadFocus`) y cierra con `Escape` o `ButtonB`.

### 4. `StarterPlayer/StarterPlayerScripts/HUD.client.lua`
- Conserva todas las barras de combate con feedback inmediato (Vida con rastro de daño retrasado, Estamina con parpadeo de falta de energía, Guardia, Aturdimiento e Infusión con el medallón rework que pulsa e inclina al estar activo o listo).
- Conserva retratos 3D en esquinas (`ViewportFrame`), crossfade de música lobby/batalla y soporte completo de `StatusKey` + `StatusParams` (Contrato C2).
- **KillFeed (Contrato C9)**: escucha `Remotes.KillFeed` (`{ killerName, victimName, weaponId, infusionId, auraId }`) y apila entradas animadas en la esquina superior derecha con icono de calavera, arma e infusión.
- Respeta `GuiService:GetGuiInset()` y escala con `OptUiScale`.

---

## Fase 4 — Lobby, Tableros, Fin de partida, Ajustes, Táctil y Pantalla de carga

### 1. `StarterPlayer/StarterPlayerScripts/LobbyUI.client.lua` (Contratos C3, C7, C8)
- **Barra inferior de Cola (C3)**: botones `1v1` y `2v2`, contador en vivo `x/y` y botón `Salir` al estar en cola (`Remotes.Queue:FireServer("Join", mode)`, `Remotes.Queue:FireServer("Leave")`, atributos de workspace `QueueCount1v1` y `QueueCount2v2`). Se oculta automáticamente durante la partida (`player:GetAttribute("InMatch") == true`).
- **Dock lateral izquierdo de acceso rápido**: botones para **Armería**, **Ajustes**, **Misiones Diarias** (con insignia `!` cuando hay recompensas listas para reclamar), **Clasificación** y **RANKED**.
- **Modal de Misiones Diarias (C8)**: lee `ReplicatedStorage/Missions.lua`, pide estado inicial con `Remotes.Missions:InvokeServer("Get")`, se actualiza con `Remotes.MissionsChanged`, muestra barra de progreso `progress / target`, recompensa en monedas, botón `Reclamar` (`Remotes.Missions:InvokeServer("Claim", id)`) y cuenta regresiva en vivo hasta el reinicio diario (`resetAt - os.time()`).
- **Modal de Clasificación (C7)**: pestañas para `Victorias`, `Bajas`, `Derribos` y `Monedas` leyendo las carpetas de `ReplicatedStorage.Leaderboards`.
- **Modal de Competitivo (Ranked)**: tarjeta «Próximamente» con divisiones y aviso de temporada.

### 2. `StarterPlayer/StarterPlayerScripts/Leaderboards.client.lua` (Contrato C7)
- Busca partes etiquetadas con `CollectionService` tag `"LeaderboardBoard"` (y escucha `GetInstanceAddedSignal`), crea un `SurfaceGui` en la cara `Enum.NormalId.Front` (`SizingMode = PixelsPerStud`) según el atributo `Board` (`Wins`, `Kills`, `Knockdowns`, `Coins`), muestra el Top 10 en vivo y resalta la fila del jugador local en dorado.

### 3. `StarterPlayer/StarterPlayerScripts/MatchUI.client.lua` (Contrato C9)
- Escucha `Remotes.MatchSummary` al terminar la partida y presenta el cartel de **VICTORIA / DERROTA**, razón de cierre, desglose de **Monedas ganadas** (`+X`) y tabla comparativa de estadísticas de todos los participantes (`Equipo`, `Bajas`, `Derribos`, `Daño`).

### 4. `StarterPlayer/StarterPlayerScripts/Settings.client.lua` (Contrato C10)
- **Pestaña Audio y Vídeo**: sliders para `Volumen de música` y `Volumen de efectos` (aplicados en tiempo real sobre `SoundService.Music` y `SoundService.SFX`), interruptor de `Sacudida de cámara` (`OptShake`), selector de `Escala de interfaz` (`OptUiScale`) y selector de **Idioma** (`Español`, `English`, `Português`).
- Sincroniza con el servidor mediante `Remotes.Settings:InvokeServer("GetOptions")` al iniciar y `Remotes.Settings:FireServer(patch)` al cambiar opciones.
- **Pestaña Controles**: reasignación interactiva de teclas (`Keyboard`) y botones de mando (`Gamepad`) con `Remotes.Settings:InvokeServer("GetBinds")` y `Remotes.Settings:InvokeServer("SetBinds", value)`.

### 5. `StarterPlayer/StarterPlayerScripts/TouchUI.client.lua` (Contrato C12)
- Se activa únicamente en dispositivos táctiles (`UserInputService.TouchEnabled`) y cuando el jugador está en partida (`player:GetAttribute("InMatch") == true`) sin menús modales abiertos.
- Dispone botones circulares de **≥ 56 px** en arco ergonómico para el pulgar derecho (`Ataque Ligero` grande principal, `Ataque Fuerte`, `Bloquear` mantenido, `Evasión / Dash`, `Infusión` y `Fijar cámara`), dejando libre la mitad inferior izquierda para el joystick nativo de movimiento.
- Dispara todas las acciones mediante `InputBridge.press(actionId, true/false)`.

### 6. `ReplicatedFirst/LoadingScreen.client.lua` (Contrato C13)
- Inspirada en `referencias\idea pantalla de carga.png`: emblema central con espadas cruzadas y halo rúnico rotatorio, título **RAGDOLL ARENA**, subtítulo dark fantasy, barra de progreso real calculada con `ContentProvider:PreloadAsync`, `ContentProvider.RequestQueueSize` y `game:IsLoaded()`, consejos de combate rotatorios traducidos (`loading.tip1`–`loading.tip5`), botón **Saltar** (aparece a los 1.2 s) y desvanecimiento suave (`TweenService`) antes de destruirse.

---

## Fase 5 — Resto de armas, Mazas óseas nuevas y Blender (`modelos_armas/`)

### 1. Revisión y unificación de todas las armas y skins (`SkinDesigns.lua`, `Skins.lua`, `WeaponBuilder.lua`)
- **Dagas (`Dagger`, `Relic01`–`Relic05`)**: todas las hojas terminan ahora entre **`2.86` y `2.89` studs** (variación < 1 % respecto a `Designs.Dagger` `2.87` studs).
- **Espadas (`Sword`, `Requiem`, `Relic06`–`Relic13`)**: todas las hojas terminan entre **`5.10` y `5.14` studs** (variación < 0.8 % respecto a `Designs.Sword` `5.10` studs). Se reemplazaron las geometrías genéricas de `Solar` (`Relic06`), `Violet` (`Relic10`) y `Void` (`Relic11`) por diseños procedurales dedicados en `SkinDesigns.lua`.
- **Estoques (`Rapier`, `Relic20`–`Relic26`)**: todas las hojas terminan entre **`5.56` y `5.58` studs**; `Duel` (`Relic20`) cuenta ahora con guarda imperial en espiral dedicada en `SkinDesigns.lua`.
- **Mazas (`Mace`, `Relic27`–`Relic32` + 3 mazas óseas nuevas `Maw02`, `Maw03`, `Maw04`)**:
  - Todas terminan entre **`4.85` y `4.90` studs**.
  - Se añadieron diseños dedicados para `Flange` (`Relic27`) y `Forge` (`Relic30`).
  - **3 nuevas mazas óseas / monstruosas inspiradas en `AncientMaw` (`Relic31`)**:
    1. **`Maw02` (`D.AbyssVertebra` — «Vértebra del Abismo»)**: columna de leviatán con 4 discos vertebrales gigantes, costillas curvas con médula carmesí incandescente y espolón apical (`z = 4.90`, 42 piezas, 2 900 monedas, Épica).
    2. **`Maw03` (`D.SepulcherJaws` — «Fauces del Sepulcro»)**: doble mandíbula abisal con 12 colmillos curvos cerrándose sobre un núcleo de ámbar ardiente (`z = 4.88`, 44 piezas, 3 400 monedas, Épica).
    3. **`Maw04` (`D.OssuaryCrown` — «Corona del Osario»)**: triple faz de cráneos reales con cuencas ardientes y corona superior de 8 astas de hueso consagrado (`z = 4.90`, 45 piezas, 3 900 monedas, Épica).

### 2. Tabla completa de armas y skins (Piezas y `BladeTip.Z`)

| Clase | ID de Skin | Diseño (`SkinDesigns` / `Designs`) | `BladeTip.Z` (studs) | Piezas (≤ 110) |
| :--- | :--- | :--- | :---: | :---: |
| **Dagger** | `Default` (+ recolores) | `Designs.Dagger` | `2.87` | 29 |
| **Dagger** | `Relic01` | `D.Fangs` | `2.86` | 28 |
| **Dagger** | `Relic02` | `D.LivingThorns` | `2.88` | 29 |
| **Dagger** | `Relic03` | `D.VoidMoons` | `2.88` | 30 |
| **Dagger** | `Relic04` | `D.SilverCrescent` | `2.88` | 28 |
| **Dagger** | `Relic05` | `D.EclipseClaws` | `2.89` | 30 |
| **Sword** | `Default` (+ recolores) | `Designs.Sword` | `5.10` | 28 |
| **Sword** | `Requiem` (**nueva**) | `D.RequiemHorns` | `5.14` | 33 |
| **Sword** | `Relic06` | `D.Solar` | `5.10` | 32 |
| **Sword** | `Relic07` | `D.Ossuary` | `5.10` | 36 |
| **Sword** | `Relic08` | `D.DawnCrown` | `5.10` | 34 |
| **Sword** | `Relic09` | `D.DragonEdge` | `5.10` | 33 |
| **Sword** | `Relic10` | `D.Violet` | `5.10` | 30 |
| **Sword** | `Relic11` | `D.Void` | `5.10` | 28 |
| **Sword** | `Relic12` | `D.ExileTooth` | `5.10` | 31 |
| **Sword** | `Relic13` | `D.DraconicRelic` | `5.12` | 35 |
| **Greatsword** | `Default` (+ recolores) | `Designs.Greatsword` | `7.60` | 39 |
| **Greatsword** | `Relic14` | `D.EmeraldTomb` | `7.60` | 35 |
| **Greatsword** | `Relic15` | `D.Devourer` | `7.60` | 47 |
| **Greatsword** | `Relic16` | `D.RoyalMourning` | `7.60` | 48 |
| **Greatsword** | `Relic17` | `D.DuskCross` | `7.60` | 52 |
| **Greatsword** | `Relic18` | `D.Shroud` | `7.58` | 50 |
| **Greatsword** | `Relic19` | `D.AbyssWings` | `7.60` | 49 |
| **Rapier** | `Default` (+ recolores) | `Designs.Rapier` | `5.56` | 52 |
| **Rapier** | `Relic20` | `D.Duel` | `5.56` | 34 |
| **Rapier** | `Relic21`–`Relic26` | `D.SilverCut` .. `D.DarkLament` | `5.56–5.58` | 28–38 |
| **Mace** | `Default` (+ recolores) | `Designs.Mace` | `4.90` | 33 |
| **Mace** | `Relic27` | `D.Flange` | `4.90` | 32 |
| **Mace** | `Relic28` | `D.CrimsonShards` | `4.86` | 36 |
| **Mace** | `Relic29` | `D.NorthExecutioner` | `4.88` | 34 |
| **Mace** | `Relic30` | `D.Forge` | `4.88` | 33 |
| **Mace** | `Relic31` | `D.AncientMaw` | `4.85` | 40 |
| **Mace** | `Relic32` | `D.OssuaryAxe` | `4.86` | 35 |
| **Mace** | `Maw02` (**nueva**) | `D.AbyssVertebra` | `4.90` | 42 |
| **Mace** | `Maw03` (**nueva**) | `D.SepulcherJaws` | `4.88` | 44 |
| **Mace** | `Maw04` (**nueva**) | `D.OssuaryCrown` | `4.90` | 45 |

### 3. Mallas de Blender (`tools/blender/generate_weapons.py` → `modelos_armas/`) y `WeaponMeshes.lua`
- Ejecutado Blender 4.x en modo headless exportando **16 pares `.obj` + `.fbx`** en `modelos_armas/` (todos entre **442 y 1 252 triángulos**, muy por debajo del límite de 5 000 triángulos, con origen en `Handle`, hoja hacia `+Z`, filo en `Y`, grosor en `X` y escala 1:1 en studs).
- Creado `ReplicatedStorage/WeaponMeshes.lua` con `MeshId = 0` por defecto (mientras sea `0`, `WeaponBuilder` usa el modelo por piezas; al pegar un `rbxassetid` tras subir la malla en Studio, `WeaponBuilder` la carga automáticamente).
- Documentado el flujo paso a paso en `modelos_armas/GUIA_SUBIDA_MALLAS.md` y `ui_assets/GUIA_SUBIDA_ICONOS.md`.

---

## Verificación: Implementado · Comprobado · Pendiente de Studio

### ✅ Implementado y Comprobado fuera de Studio
1. **Chequeo estático de sintaxis y variables globales (`node tools/check_lua.js .`)**:
   - Resultado: **`OK: 68 archivos sin problemas detectados.`**
2. **Sincronización de traducciones (`ReplicatedStorage/LocaleGemini.lua`)**:
   - **87 claves** en `ES`, **87 claves** en `EN` y **87 claves** en `PT-BR` (100 % simétricas y 0 colisiones con `LocaleES.lua`, `LocaleEN.lua` y `LocalePT.lua`).
3. **Exportación headless de mallas 3D con Blender (`tools/blender/generate_weapons.py`)**:
   - 16 archivos `.obj` y 16 archivos `.fbx` generados y verificados en `modelos_armas/` (442 a 1 252 triángulos).
4. **Generación de iconos UI (`ui_assets/`)**:
   - 19 archivos `.svg` y 19 archivos `.png` (256×256 RGBA transparentes) generados en `ui_assets/`, además de los fallbacks procedurales en `ReplicatedStorage/UiAssets.lua`.

### 🟡 Pendiente de probar en Roblox Studio (Checklist para Claude y para el usuario)
1. **Regeneración de `Ragdoll Arena.rbxlx` (tarea exclusiva de Claude)**:
   - Ejecutar `node tools/make_rbxlx.js` para empaquetar los nuevos módulos (`UiTheme.lua`, `UiAssets.lua`, `WeaponMeshes.lua`) y scripts de cliente (`Leaderboards.client.lua`, `MatchUI.client.lua`, `TouchUI.client.lua`, `ReplicatedFirst/LoadingScreen.client.lua`).
2. **Inspección de armas y skins con `tools/preview_skins.lua`**:
   - Pegar `tools/preview_skins.lua` en la Barra de Comandos de Studio y verificar las 5 filas de armas (`Dagger`, `Sword` con `Default` y `Requiem`, `Greatsword` colosal con `Relic14`–`Relic19`, `Rapier`, y `Mace` con `Maw02`, `Maw03`, `Maw04`) y el log de piezas y `BladeTip.Z` en Output.
3. **Prueba de la Tienda (`Shop.client.lua`)**:
   - Verificar las 4 tarjetas altas de **Infusiones** (estilo `referencias\infusiones ref2.jpg`) con el nuevo icono rework arriba, nombre, lema corto y borde dorado.
   - Verificar la pestaña **Auras** con el pedestal 3D en vivo (`ShopAuraPreviewStage`) mostrando partículas reales sobre el maniquí (`Body`) y sobre el arma (`Weapon`).
   - Verificar navegación con mando (foco dorado y trampa de foco en el modal de confirmación de compra).
4. **Prueba de Lobby, HUD, Ajustes, Táctil y Pantalla de Carga**:
   - Verificar la pantalla de carga al dar *Play*, la barra inferior de cola `1v1`/`2v2`, el panel de **Misiones Diarias** (progreso, reclamo y temporizador), los tableros físicos (`LeaderboardBoard`), la pantalla de resumen al terminar una partida (`MatchSummary`), el KillFeed en el HUD, el cambio de idioma (`ES`/`EN`/`PT-BR`) y escala de UI en Ajustes, y los botones táctiles en el emulador móvil de Studio.

---

## Pedidos a otros (para Claude / Codex)

1. **Para Claude (`tools/make_rbxlx.js` / `Ragdoll Arena.rbxlx`)**:
   - Al regenerar `Ragdoll Arena.rbxlx`, asegurate de que entren en el árbol del `.rbxlx`:
     - `ReplicatedStorage/UiTheme.lua`
     - `ReplicatedStorage/UiAssets.lua`
     - `ReplicatedStorage/WeaponMeshes.lua`
     - `StarterPlayer/StarterPlayerScripts/Leaderboards.client.lua`
     - `StarterPlayer/StarterPlayerScripts/MatchUI.client.lua`
     - `StarterPlayer/StarterPlayerScripts/TouchUI.client.lua`
     - `ReplicatedFirst/LoadingScreen.client.lua`
2. **Para Claude (`ReplicatedStorage/WeaponData.lua` — alcance opcional de `Greatsword`)**:
   - Se actualizaron en `WeaponBuilder.Info.Greatsword`: `gripZ = 0.55`, `offhandZ = -0.65`, `trail = { 1.4, 7.6 }`.
   - Como la hoja visual del Espadón pasó de `6.00–6.45` a **`7.60` studs**, proponemos opcionalmente ajustar en `WeaponData.Data.Greatsword`: `range = 11.2`, `heavyRange = 12.8`, `runningRange = 12.5` y `hitboxSize = Vector3.new(8.8, 6.2, 11.8)`.

---

## Ronda 3A — Arreglos de interfaz de Gemini (Puntos 1 a 10 de Notas/Tareas ronda 3.md)

### 1. Implementado

1. **Separación de Icono y Texto en Botones (`UiTheme.lua` y `LobbyUI.client.lua`) (Punto 1)**:
   - En `UiTheme.button` se añadió soporte de primer nivel para `props.icon`, `props.iconSize`, `props.iconOffset` y `props.iconSpacing`. El icono se coloca en un contenedor aislado a la izquierda (`IconHolder`), mientras que la etiqueta `BtnText` se ubica a la derecha con alineación izquierda (`Enum.TextXAlignment.Left`) y texto sincronizado automáticamente (`GetPropertyChangedSignal("Text")`). `btn.Text` se limpia a `""` para que **bajo ninguna circunstancia el icono se dibuje encima del texto** («Ar◆ería», «Aj◆tes»).
2. **Reubicación y Rediseño del HUD (`HUD.client.lua`) (Puntos 2 y 7)**:
   - Se removió el panel horizontal del centro inferior que tapaba al personaje.
   - Se rediseñó como **columnas verticales una al lado de la otra** (Vida con rastro de daño retardado, Resistencia, Guardia, Aturdimiento e Infusión con icono dinámico).
   - El llenado de cada barra es vertical (`AnchorPoint = (0, 1)`, `Position = (0, 1)`, `Size = UDim2.fromScale(1, fraction)`).
   - En PC/consola se ubica abajo a la derecha (`Position = UDim2.new(1, -20, 1, -20)`, `AnchorPoint = (1, 1)`). En dispositivos táctiles móviles se coloca abajo a la izquierda (`Position = UDim2.new(0, 16, 1, -20)`, `AnchorPoint = (0, 1)`) dejando libre la zona de botones de combate del pulgar derecho.
3. **Vista previa de Auras en el Propio Personaje (`Shop.client.lua`) (Puntos 3 y 8)**:
   - Se eliminó el escenario flotante en el cielo a 680 studs (`stagePos = Vector3.new(0, 680, 0)`), el cual alejaba la cámara y causaba el apagado de las luces de la ciudad.
   - Al seleccionar un aura en la tienda, se aplica directamente sobre el personaje del cliente local mediante `AuraFx.attach(target, auraId, { preview = true, character = char })` (en la herramienta si es de arma, o en el personaje si es de cuerpo).
   - La cámara encuadra al propio personaje en la mitad derecha libre de la pantalla, desplazando el panel de tienda hacia la izquierda (`Position = UDim2.fromScale(0.35, 0.5)`).
   - Al cerrar la tienda o cambiar de pestaña, se restaura la cámara, se limpian las partículas de prueba y regresa el aura equipada originalmente.
4. **Encuadre proporcional de Armas en Miniaturas (`Shop.client.lua`) (Punto 4)**:
   - La función `preview` calcula la distancia exacta de cámara utilizando `GetBoundingBox()`, el FOV (`halfTan`) y la relación de aspecto del ViewportFrame para que las armas ocupen ~84% del marco, resolviendo el problema de armas excesivamente finas o enanas en las tarjetas.
5. **Iconos procedimentales por patrón de Aura (`UiAssets.lua` y `Shop.client.lua`) (Punto 5)**:
   - Se implementaron 10 iconos procedurales vectoriales propios en `UiAssets.lua` para cada patrón de aura (`aura_crown`, `aura_chains`, `aura_wings`, `aura_mist`, `aura_eyes`, `aura_runes`, `aura_drip`, `aura_embers`, `aura_blood`, `aura_fracture`) con formas geométricas dedicadas y color temático.
   - Conectados tanto en las tarjetas de la tienda como en el modal de confirmación de compra.
6. **Timeouts en `WaitForChild` iniciales (Punto 6)**:
   - Se aplicó límite de 10 segundos en todas las llamadas `WaitForChild("UiTheme", 10)`, `WaitForChild("UiAssets", 10)`, `WaitForChild("Localization", 10)` en `Shop.client.lua`, `HUD.client.lua`, `LobbyUI.client.lua`, `Settings.client.lua`, `UiTheme.lua` y `UiAssets.lua`, previniendo bloqueos indefinidos si un módulo tarda en replicar.
7. **Nueva Disposición de Interfaz (Punto 7)**:
   - **Izquierda, en columna vertical**: `LeftLobbyDock` a media altura (`Position = UDim2.new(0, 16, 0.5, 0)`, `AnchorPoint = (0, 0.5)`) con Armería, Ajustes, Misiones (con insignia `!` para reclamos) y Clasificación, con iconos a la izquierda del texto sin solapamiento.
   - **Abajo al centro, centrados**: `QueueBar` centrado (`Position = UDim2.new(0.5, 0, 1, -16)`, `AnchorPoint = (0.5, 1)`) con Buscar 1v1, Buscar 2v2 y botón RANKED con etiqueta «Próximamente».
   - **Abajo a la derecha, en vertical**: HUD de combate en columnas verticales lado a lado.
   - **Retirada de Clasificatorias de la Tienda**: Pestaña eliminada de `Shop.client.lua` y transferida al botón RANKED del lobby bar.
   - **HUD visible solo en batalla**: En la ciudad el HUD permanece oculto (`GroupTransparency = 1`, `Visible = false`). Se activa inmediatamente al entrar a partida (`InMatch == true`) o al golpear/recibir daño en el patio de práctica de la ciudad, desvaneciéndose suavemente tras 8 segundos de inactividad de combate.
8. **Eliminación del escenario a 680 studs y órbita de cámara** (Punto 8, implementado junto con punto 3).
9. **Precarga real en Pantalla de Carga (`ReplicatedFirst/LoadingScreen.client.lua`) (Punto 9)**:
   - Se implementó `ContentProvider:PreloadAsync` recopilando sonidos de `Assets.Sounds`, efectos/vfx de `Assets.VFX`, iconos de `UiAssets.Ids`, texturas de partículas (`SmokeTexture`, `SparkTexture`) de `Auras.Fx` y modelos de `Weapons`.
   - La barra de progreso refleja el avance real de precarga combinado con `game:IsLoaded()`.
10. **Corrección de nombres de contratos y remotos en el Reporte (Punto 10)**:
    - Corregida en la sección de Fase 4 la descripción de los remotos reales: `Remotes.Queue:FireServer("Join", mode)` / `"Leave"`, `Remotes.Missions:InvokeServer("Get")` / `"Claim"`, `Remotes.Settings:InvokeServer("GetOptions")` / `FireServer(patch)`, atributo `Board` en partes con tag `LeaderboardBoard`, y atributo `InMatch`.

### 2. Comprobado

- **Sintaxis Lua y Luau (`node tools/check_lua.js .`)**:
  - `OK: 70 archivos sin problemas detectados.` (0 errores de sintaxis, 0 variables globales no deseadas, 0 tablas malformadas).
- **Consistencia de claves en `LocaleGemini.lua`**:
  - Claves `ui.queue.1v1`, `ui.queue.2v2`, `ui.lobby.ranked`, `ui.lobby.missions`, `ui.lobby.leaderboards`, `ui.ranked.title`, `ui.ranked.desc`, `ui.ranked.rewards` simétricas en `ES`, `EN`, `PT-BR`.
- **Compatibilidad cruzada**:
  - Sin modificaciones a `Theme.lua`, `LobbyBuilder.lua`, `make_rbxlx.js` ni `Ragdoll Arena.rbxlx`.

### 3. Pendiente de Probar en Roblox Studio

1. **Dock lateral izquierdo**:
   - Abrir el juego y verificar que a la izquierda a media altura aparezcan Armería, Ajustes, Misiones y Clasificación, con los iconos alineados a la izquierda y sin superponerse a las letras.
   - Probar que cada botón abra su respectivo panel (Armería abre la tienda en la pestaña Armas; Ajustes abre el modal de opciones; Misiones abre el modal de misiones; Clasificación abre los tableros).
2. **Barra de cola centrada y botón RANKED**:
   - Verificar que los botones «Buscar 1v1», «Buscar 2v2» y «RANKED» («Próximamente») estén perfectamente centrados en la parte inferior de la pantalla.
   - Pulsar «RANKED» y verificar que abre el modal explicativo con el trofeo dorado y divisiones.
3. **HUD vertical y visibilidad condicional**:
   - Comprobar que al pasear por la ciudad el HUD esté oculto y la vista del centro/fondo quede limpia.
   - Ir al patio de práctica y golpear a un muñeco o recibir un golpe: comprobar que el HUD se desvanece suavemente hacia la vista en la esquina inferior derecha con columnas verticales (Vida con rastro, Resistencia, Guardia, Stun, Infusión).
   - Dejar de combatir durante 8 segundos y verificar que el HUD se desvanece a transparente.
4. **Vista previa de Auras en el propio personaje**:
   - Abrir la Tienda, ir a la pestaña Auras y seleccionar distintas auras (corona, cadenas, alas, niebla, ojos, runas, etc.).
   - Verificar que la cámara enfoque al personaje propio en la mitad derecha con órbita suave, que las partículas se reproduzcan en vivo en el personaje o arma, y que las luces de la ciudad sigan encendidas normalmente.
   - Verificar que cada tarjeta de aura muestre su icono temático propio y no un icono genérico idéntico.
5. **Miniaturas de armas en skins**:
   - Inspeccionar la pestaña Skins de la tienda y comprobar que las armas se vean encuadradas y proporcionadas, ocupando la mayor parte del marco.
6. **Pantalla de carga con precarga real**:
   - Dar Play en Studio y verificar que la barra de progreso avance con la precarga de assets antes de entrar a la ciudad.

---

## Ronda 3B — Segunda pasada de arte de las arenas (Sección B de Notas/Tareas ronda 3.md)

### Archivos tocados (transferidos a Gemini en Ronda 3B)
- `ReplicatedStorage/ArenaConfig.lua`
- `ServerScriptService/ArenaBuilder.lua`
- `StarterPlayer/StarterPlayerScripts/ArenaBackdrop.client.lua`
- `StarterPlayer/StarterPlayerScripts/Arena.client.lua`

### 1. Implementado

1. **Aislamiento Total de las Arenas y Coordenadas Nuevas (`ArenaConfig.Modes`)**:
   - **Coordenadas nuevas**:
     - **`2v2`**: `Vector3.new(4500, 260, 0)` (antes `(0, 100, 0)` sobre la ciudad).
     - **`1v1`**: `Vector3.new(-4500, 260, 0)` (antes `(450, 100, 0)`).
   - Ahora cada arena está a **4 500 studs de distancia de la ciudad** y a **9 000 studs de distancia entre sí**, impidiendo por completo que desde una arena se vea la otra o la ciudad.
   - Además, cada una de las 4 variantes cuenta con una **máscara perimetral 360° de gran altura (`R * 2.52` a `R * 2.58`, hasta `+195` studs)** que cierra el horizonte temáticamente sin invadir jamás el radio de la cámara de combate (`R + 15`, picada `24°`).
2. **Fondo / Piso Temático Bajo la Arena y Desenfoque/Fundido al Caer (`ArenaBuilder.lua` y `ArenaBackdrop.client.lua`)**:
   - Cada variante construye un lecho abisal doble (`AbyssBed` + `VoidSurface` + capas de niebla espesa en `ArenaBackdrop.client`) completamente contenido dentro del anillo de la máscara exterior, de modo que al caer nunca se ve el borde del mapa ni el vacío desnudo.
   - En `ArenaBackdrop.client.lua` se añadieron dos efectos `Arena*` en `Lighting` exclusivos para el jugador local cuando cae por debajo del nivel de la plataforma (`root.Position.Y < mode.center.Y - 2.5`):
     - **`ArenaFallBlur` (`BlurEffect`)**: sube progresivamente hasta `Size = 28` a medida que el jugador cae hacia `VoidDrop`.
     - **`ArenaFallColor` (`ColorCorrectionEffect`)**: oscurece suavemente la exposición (`Brightness -> -0.68`, `Contrast -> +0.28`) creando un fundido abisal antes de reaparecer. Se desactiva automáticamente al volver a la plataforma o salir de la partida.
   - `ArenaTone` y `ArenaDOF` siguen activos únicamente con `InMatch == true` y ajustan su tinte/contraste según la variante activa (`Forest`, `Canyon`, `Temple`, `Hand`).
3. **Rediseño Escultórico de las 4 Variantes (`ServerScriptService/ArenaBuilder.lua`)**:
   - **Mano (`"Hand"` — `referencias\mano como arena 4.jpg`, ~471 piezas en 2v2 / ~295 en 1v1)**:
     - **Mano gigante de piedra con musgo sosteniendo la plataforma desde abajo**: antebrazo oblicuo con brazalete tallado y musgo emergiendo del abismo (`HandForearm`), muñeca cilíndrica (`HandWrist`), palma anatómica esculpida (`HandPalmCenter`, `HandPalmHeel`, `HandPalmThenar`, `HandPalmHypothenar`) con mantos de musgo vivo en los bordes inferiores y chorros de agua cayendo entre los pliegues.
     - **4 dedos articulados (`Index`, `Middle`, `Ring`, `Pinky`) + 1 pulgar opuesto (`Thumb`)**: cada dedo posee nudillos esféricos (`KnuckleBase`, `KnuckleMid`, `KnuckleTip`), 3 falanges curvadas hacia arriba con musgo en el dorso, uña tallada (`Fingernail`) y cascadas cayendo entre las comisuras. Todos nacen en `radius >= R * 1.34` para dejar 100 % libre el paso de cámara.
     - **Cabeza y busto de estatua ancestral a un costado**: pedestal escalonado, hombros con musgo, cuello, cráneo, pómulos, mandíbula, mentón, arcos superciliares con musgo asimétrico, ojos entrecerrados serenos, puente nasal, labios esculpidos, orejas alargadas y corona escalonada tipo santuario Khmer.
     - **Acantilados santuario 360° y 8 grandes cascadas (`Waterfall` + `WaterfallFoam`)** con partículas de rocío (`ArenaWaterFlow`).
   - **Cañón (`"Canyon"` — `referencias\arena 2.jpg`, ~659 piezas en 2v2 / ~483 en 1v1)**:
     - **Pedestal monolítico inferior con arcos naturales de roca** (`MonolithUnderTier`, `CanyonSupportPillar`, `CanyonUnderArch`) sobre el abismo de arenisca.
     - **Coliseo excavado en la roca**: acantilado interior con estratos sedimentarios, 5 gradas concéntricas escalonadas (`CanyonTerrace`), contrafuertes radiales, braseros de hierro encendidos (`PointLight` cálida), toldos tensados de tela del desierto (`CanyonAwning`) y doble corona de **púas metálicas y dientes de roca apuntando hacia la arena y al vacío** (`VoidSpike`, `ColosseumRimSpike`, `ColosseumRimTooth`).
     - **Muralla exterior de cañón 360° con estratos y Picos Gemelos** que replican la silueta de `referencias\arena 2.jpg`.
   - **Templo (`"Temple"` — `referencias\arena 3.jpg`, ~725 piezas en 2v2 / ~549 en 1v1)**:
     - **Espejo de agua oscura con reflejos dorados (`VoidSurface` en `Glass` + `WaterGoldReflection`)** y escalinatas rituales sumergidas bajo el núcleo.
     - **12 columnas monumentales**: basamento de mármol y oro, fuste oscuro envuelto por **7 anillos concéntricos y 6 tiras verticales de jeroglíficos dorados luminosos (`Neon` y `Metal`)**, y **capitel de loto acampanado de 4 niveles** con ábaco y vigas radiales.
     - **Muros del santuario cerrados 360°, techo artesonado dorado con Óculo central y haz de luz divina (`OculusSunbeam`)** descendiendo sobre el centro de la plataforma.
   - **Bosque (`"Forest"`, ~519 piezas en 2v2 / ~343 en 1v1)**:
     - Conserva el diseño original (lago de lava contenido con islas de corteza basáltica, 4 cadenas monumentales, rocas flotantes etiquetadas `"FloatingRock"` y anillo de árboles sombríos con raíces al vacío) e incorpora la **máscara exterior 360° de montañas volcánicas oscuras (`ForestMountainMask` + `MountainCrest`)** para que la lava nunca asome fuera de la caldera.

### 2. Comprobado

- **Chequeo estático (`node tools/check_lua.js .`)**:
  - Resultado: **`OK: 70 archivos sin problemas detectados.`**
- **Presupuesto de piezas (`<= 2 500` piezas por arena)**:
  - `Forest`: ~519 piezas (2v2) / ~343 piezas (1v1).
  - `Canyon`: ~659 piezas (2v2) / ~483 piezas (1v1).
  - `Temple`: ~725 piezas (2v2) / ~549 piezas (1v1).
  - `Hand`: ~471 piezas (2v2) / ~295 piezas (1v1).
  - Todas las piezas decorativas tienen `CanCollide = false`, `CanQuery = false`, `CanTouch = false`, `CastShadow = false` y desfases geométricos explícitos para evitar parpadeo (Z-fighting).

### 3. Pendiente de Probar en Roblox Studio

1. **Rotación y aislamiento de las 4 variantes (`Forest`, `Canyon`, `Temple`, `Hand`)**:
   - Usar el panel de depuración (`P`) o iniciar partidas sucesivas en `1v1` (`-4500, 260, 0`) y `2v2` (`4500, 260, 0`) para verificar que desde ninguna arena se vea la ciudad ni la otra arena.
2. **Lectura visual de cada variante frente a sus referencias**:
   - **Mano**: comprobar la palma bajo la plataforma, los 4 dedos + pulgar curvándose por fuera del borde sin obstruir la cámara de 24°, la cabeza de estatua con musgo a un costado y las cascadas traseras.
   - **Cañón**: comprobar las 5 gradas del coliseo, estratos, toldos, braseros, púas metálicas y el pedestal con arco bajo la arena.
   - **Templo**: comprobar las columnas con jeroglíficos dorados brillantes, capiteles de loto, reflejos sobre el agua oscura y el haz de luz desde el óculo superior.
3. **Caída al vacío y desenfoque (`ArenaFallBlur` / `ArenaFallColor`)**:
   - Dejarse caer fuera de la plataforma en partida o práctica y verificar que la cámara aplique el desenfoque y fundido suave sobre el fondo temático antes de la eliminación/reaparición.

---

## Ronda 5 (Ajustes de iluminación, Templo dorado, rotación de arenas y desenfoque)

### 1. Implementado

- **Luz de las arenas en partida (`ReplicatedStorage/ArenaConfig.lua`, `ServerScriptService/ArenaBuilder.lua`, `StarterPlayer/StarterPlayerScripts/ArenaBackdrop.client.lua`)**:
  - Se aumentó la exposición y luz ambiental específica de partida mediante `ArenaTone` (`ColorCorrectionEffect` activo durante `InMatch = true`):
    - `ArenaConfig.VariantAmbience` subido en todas las variantes (`Forest`: `0.24`, `Canyon`: `0.20`, `Temple`: `0.22`, `Hand`: `0.24`).
    - `ArenaConfig.Exposure` elevado a `0.20` y `AmbientTint` a `Color3.fromRGB(245, 242, 238)`.
  - Se añadieron exactamente 6 fuentes de luz locales (`PointLight` sin sombras, `Range = 38 * s`, `Brightness = 2.2`) distribuidas en el perímetro de cada arena:
    - **Bosque (`Forest`)**: 6 braseros de hierro rústico (`ForestBrazierStand` + llama `Neon` + `PointLight` cálida `255, 165, 80`) al borde de la plataforma.
    - **Cañón (`Canyon`)**: reducido a exactamente 6 braseros perimetrales (`i % 4 == 0` sobre los 24 segmentos), `Shadows = false`, luz ámbar cálida (`255, 185, 95`).
    - **Templo (`Temple`)**: 6 lámparas de altar sagradas (`TempleAltarStand` en `Metal` oro oscuro + llama dorada + `PointLight` cálida `255, 205, 110`).
  - Suelos aclarados (`FloorColors`) para que los personajes, siluetas y sombras se lean nítidamente desde la cámara en picada (24°):
    - `Forest`: base `176, 172, 166` / borde `154, 150, 144` (granito volcánico claro).
    - `Canyon`: base `204, 170, 138` / borde `182, 148, 116` (arenisca clara desértica).
    - `Temple`: base `202, 196, 186` / borde `180, 174, 164` (mármol beige pulido claro).

- **Templo dorado sin verde lima (`ServerScriptService/ArenaBuilder.lua`, `ReplicatedStorage/ArenaConfig.lua`)**:
  - Se eliminó el tono verde lima neón producido por la interacción de `Neon` amarillo con la niebla teal/cian anterior:
    - `ArenaConfig.Palettes.Temple.Gold` fijado en oro cálido real (`Color3.fromRGB(240, 185, 80)`), `GoldBright` (`255, 215, 120`), `GoldDark` (`190, 140, 50`) y haz solar `Sunbeam` (`255, 230, 170`).
    - `MistColor` del Templo cambiado de teal a ámbar cálido (`Color3.fromRGB(68, 56, 44)`).
    - Fuste y jeroglíficos de las 12 columnas convertidos a `Enum.Material.Metal` y `Foil` con tonos dorados cálidos; solo 1 anillo central de 0.6 studs conserva un acento `Neon` muy sutil y translúcido (`Transparency = 0.35`). Las 6 tiras verticales de jeroglíficos pasaron a `Metal` sin neón chillón.
    - El friso perimetral y los reflejos del agua pasaron de `Neon` a `Metal` y `SmoothPlastic` con transparencias sutiles.
  - **Despeje de cámara**: las columnas se alejaron a `colR = R * 1.85` (antes `1.56`), dejando más de 38 studs de despeje en 1v1 y más de 85 studs en 2v2 respecto al borde de la plataforma.
  - Las vigas de techo radiales (`CeilingRadialBeam`) se anclaron desde la parte superior de cada columna hacia el muro exterior del santuario (`colR + (wallR - colR) * 0.5`), sin sobrevolar en ningún momento la plataforma de combate.

- **Retiro de la Mano de la rotación (`ReplicatedStorage/ArenaConfig.lua`)**:
  - `ArenaConfig.Variants` se configuró como `{ "Forest", "Canyon", "Temple" }`, retirando `"Hand"` del selector aleatorio de partidas normales.
  - La función completa `buildHand` y toda su paleta se preservaron íntegras en `ArenaBuilder.lua` para la reescultura posterior con Argon.

- **Blindaje del desenfoque al caer (`StarterPlayer/StarterPlayerScripts/ArenaBackdrop.client.lua`)**:
  - Se implementó la rutina de limpieza integral `clearFallEffects()` que apaga y resetea a cero tanto `fallBlur` (`Size = 0`, `Enabled = false`) como `fallColor` (`Brightness = 0`, `Enabled = false`) y `fallIntensity = 0`.
  - Se conectó `clearFallEffects()` a:
    1. `player.CharacterAdded:Connect(clearFallEffects)` (reaparición inmediata tras morir o revivir).
    2. `player:GetAttributeChangedSignal("Eliminated")` (al volver a tener `Eliminated == false`).
    3. `updateArenaLighting()` cuando `not inMatch` (fin de partida, vuelta a lobby o cambio de estado).
    4. En cada frame de `RenderStepped`, si `not inArena` o si la distancia al centro de la arena supera `mode.radius * 3.5` (jugador en la ciudad o fuera del perímetro de combate), se invoca `clearFallEffects()` y se sale inmediatamente de la rutina de caída, garantizando que el desenfoque nunca persista en la ciudad.

### 2. Comprobado

- **Sintaxis y validación estática (`node tools/check_lua.js .`)**:
  - Resultado: **`OK: 71 archivos sin problemas detectados.`**
- **Verificación de dependencias y límites**:
  - Las arenas mantienen exactamente ≤ 6 `PointLight` perimetrales sin sombras por arena.
  - Sin cambios en archivos de interfaz (Codex) ni archivos centrales de partida/red (Claude).
  - No se regeneró `Ragdoll Arena.rbxlx`.

### 3. Pendiente de Probar en Roblox Studio

1. **Iluminación en partida vs. lobby**:
   - Entrar en partida (1v1 o 2v2) y confirmar que la arena se ilumina claramente con su tono específico (`ArenaTone`) y sus 6 braseros/lámparas perimetrales, permitiendo leer con claridad a los personajes y sus ragdolls desde la vista en picada a 24°.
2. **Aspecto del Templo dorado**:
   - Rotar hasta que toque el Templo y comprobar la eliminación del verde neón en jeroglíficos y anillos (ahora oro metálico cálido egipcio) y verificar que las columnas y vigas exteriores no interfieran con la cámara de combate ni con los bordes de la plataforma.
3. **Rotación de variantes**:
   - Iniciar 4 o 5 partidas sucesivas y verificar que solo roten Bosque, Cañón y Templo, sin que aparezca la Mano.
4. **Prueba de caída y reaparición en la ciudad**:
   - Saltar al vacío en partida para observar el desenfoque suave al caer (`ArenaFallBlur`), y verificar que al reaparecer o al terminar la partida la pantalla regrese inmediatamente a la nitidez total sin desenfoque residual en la ciudad.


