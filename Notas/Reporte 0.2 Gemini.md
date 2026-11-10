# Reporte 0.2 — Gemini (Director de Arte e Interfaz)

## 0.2 Ronda 1 — 10/11/2026 14:06 (UTC-3, hora de Argentina)

---

### 1. Implementado (comprobado con herramientas)

- **Parte A — Rediseño de todas las skins al estándar de `Notas/Referencias/espada-concepto.png` y 3 skins nuevas de la Ruleta (D6, D15)**:
  - **Estudio e implementación 1:1 de la espada de referencia (`CrimsonEclipse`, gran premio semanal de la Ruleta)**:
    - Creada en `ReplicatedStorage/Skins.lua`, `ReplicatedStorage/SkinDesigns.lua`, `ReplicatedStorage/WeaponMeshes.lua`, `ReplicatedStorage/LocaleGemini.lua` y `tools/blender/generate_weapons.py`.
    - Geometría fiel a `Notas/Referencias/espada-concepto.png`: hoja asimétrica con bisel de filo de plata espejo (`Foil`), núcleo escalonado de obsidiana negra (`Slate`), acanaladura profunda (`Fuller`), **5 colmillos/dientes dorsales ganchudos** en el lomo (`-Y`) con base de obsidiana y punta de plata, **vena de relámpago carmesí** (`Neon`) quebrada en 7 tramos con ramificaciones diagonales desde el recazo hasta la punta (`TipZ = 5.10`), **recazo romboidal con 2 rubíes carmesí engarzados** en bisel de plata, **guarda asimétrica en media luna** con gavilán delantero (`+Y`) y guardamonte curvo envolvente (`-Y`), empuñadura negra estriada con 5 anillos en chevrón y **pomo de 3 garras con 1 rubí carmesí engarzado**.
  - **Dos skins compañeras nuevas para la Ruleta (D15)**:
    - `BloodMoonCleaver` (*Mandoble de Sangre Lunar*, `weapon = "Greatsword"`, `rarity = "Legendary"`, `roulette = true`, `TipZ = 7.60`): losa colosal de obsidiana con bisel de filo de plata espejo, 6 dientes dorsales ganchudos, arteria de relámpago carmesí, guarda monumental con guardamonte y recazo con 2 rubíes engarzados.
    - `CataclysmMaw` (*Quebrantahuesos del Eclipse*, `weapon = "Mace"`, `rarity = "Legendary"`, `roulette = true`, `TipZ = 4.90`): maza real de obsidiana y plata afilada con 6 aletas biseladas en cuña alrededor de un núcleo carmesí, 4 colmillos dorsales, recazo con 2 rubíes y espolón apical en `z = 4.90`.
  - **Rehechas las 36 skins existentes en `ReplicatedStorage/SkinDesigns.lua` con el mismo nivel de acabado**:
    - Constructores `dagger` (5 skins: `Fangs`, `LivingThorns`, `VoidMoons`, `SilverCrescent`, `EclipseClaws`), `sword` (9 skins: `RequiemHorns`, `Solar`, `Ossuary`, `DawnCrown`, `DragonEdge`, `Violet`, `Void`, `ExileTooth`, `DraconicRelic`), `greatsword` (6 skins: `EmeraldTomb`, `Devourer`, `RoyalMourning`, `DuskCross`, `Shroud`, `AbyssWings`), `rapier` (7 skins: `Duel`, `SilverCut`, `FireTongue`, `TwilightDuel`, `SpectralSting`, `AmethystVeil`, `DarkLament`) y `mace` (9 skins: `Flange`, `CrimsonShards`, `NorthExecutioner`, `Forge`, `AncientMaw`, `OssuaryAxe`, `AbyssVertebra`, `SepulcherJaws`, `OssuaryCrown`).
    - Todas incorporan ahora biseles de filo en cuña (`Wedge` + `Foil`), núcleo contrastado (`Slate`), acanaladura (`Fuller`), vena de relámpago central (`Neon`), dientes dorsales con punta metálica, recazo romboidal con 2 gemas engarzadas, guardamonte curvo y pomo de 3 garras con gema, manteniéndose entre **55 y 96 piezas por arma** (por debajo del tope de 110 piezas), `<= 1` luz, `<= 1` emisor de partículas y conservando exactamente la posición de `BladeTip` (`TipZ`) de cada clase de arma.
  - **Actualización de `ReplicatedStorage/WeaponBuilder.lua`**:
    - Añadido soporte explícito para el rol `"Gem"` (`Neon`) y bisel `"Edge"` (`Foil`) en `Builder:look(role)`, y aplicación de `WeaponBuilder.ClassScale[weaponId]` también dentro de `populateFromMesh` para que las mazas importadas por malla conserven la misma escala (`1.3x`) que las procedurales.
  - **Tanda 1 de Blender (`tools/blender/generate_weapons.py` y `modelos_armas/`, D6)**:
    - Script `tools/blender/generate_weapons.py` ampliado y ejecutado en Blender headless (`blender-launcher.exe -b --python tools/blender/generate_weapons.py`).
    - Generadas mallas 3D con mapeo UV por zonas de material (`.fbx` con textura incrustada + `.obj`/`.mtl`) y **texturas atlas de `1024x1024 px` (`*_tex.png`)** pensadas para móvil (**entre 998 y 2 272 triángulos**, muy por debajo del tope de 5 000 tris) para las **3 skins de la Ruleta** (`CrimsonEclipse`, `BloodMoonCleaver`, `CataclysmMaw`), **1 skin piloto por cada una de las 5 armas** (`EclipseClaws`, `RequiemHorns`, `AbyssWings`, `DarkLament`, `OssuaryCrown`) y las 5 armas base + variantes adicionales (21 modelos en total en `modelos_armas/`).
    - `ReplicatedStorage/WeaponMeshes.lua` y `modelos_armas/GUIA_SUBIDA_MALLAS.md` actualizados con las claves listas para pegar `MeshId` y `TextureId`.

- **Parte B — Separación de Tienda y Armería, más pantalla de Antesala y Cinemática (D11, D12, D13, D16, D20, C17, C20)**:
  - **Armería nueva (`StarterPlayer/StarterPlayerScripts/Armory.client.lua`, D13, C20)**:
    - Pantalla dedicada para elegir y equipar **Arma**, **Skin** (con filtro *En propiedad / Todas*), **Infusión** (las 4 tarjetas altas estilo `referencias\infusiones ref2.jpg`) y **Aura**.
    - Incluye **vista 3D interactiva del personaje** (`CharacterViewport`) sobre un pedestal gótico con anillo luminoso del color de la infusión/aura, clonando el avatar del jugador (o un maniquí de armadura oscura si el avatar aún no está archivable) y equipándole en su mano derecha el arma y la skin seleccionadas (más la segunda daga en la mano izquierda si el arma es `Dagger`). Permite rotar con ratón o mando (`Thumbstick2`) y hacer zoom (`MouseWheel` / `L2`-`R2`).
    - Se abre desde el botón **Armería** del dock izquierdo en la ciudad (`LobbyUI.client.lua`), con la tecla `B`, mediante el `BindableEvent` `player.ToggleArmory` o desde la pantalla de Antesala (`Prematch.client.lua`). Se cierra automáticamente cuando la partida pasa de `"Prematch"` a `"Cinematic"` o `"Fighting"`.
  - **Tienda rediseñada como Escaparate (`StarterPlayer/StarterPlayerScripts/Shop.client.lua`, D12, D20, C20)**:
    - Sección superior **«Destacado del Día»** (`Showcase`) con rotación diaria determinista por fecha UTC (`math.floor(os.time() / 86400)`, o leída de `workspace:GetAttribute("ShopFeatured")` si el servidor la publica) de 5 artículos destacados —encabezados por el Gran Premio Semanal de la Ruleta `CrimsonEclipse`— y temporizador en vivo (`Rota en HH:MM:SS`).
    - **Catálogo Completo** debajo del escaparate y navegable por pestañas (`Destacado`, `Skins`, `Auras`, `Multiplicadores`, `Almas y Monedas`), con gran visor 3D a la derecha, insignias `RULETA` / `GRAN PREMIO SEMANAL`, aviso de versión 0.2 sin compras con Robux (D20), diálogo modal de confirmación con bloqueo de foco de mando (`trapGamepadFocus`) y botón directo para abrir la **Armería**.
  - **Dock de la ciudad actualizado (`StarterPlayer/StarterPlayerScripts/LobbyUI.client.lua`)**:
    - Separados los botones **Armería** (`ArmoryBtn` → `ToggleArmory`) y **Tienda** (`ShopBtn` → `ToggleMenu`) en el dock vertical izquierdo.
  - **Antesala y Cinemática de partida (`StarterPlayer/StarterPlayerScripts/Prematch.client.lua`, D11, D13, D16, C17)**:
    - Escucha `workspace:GetAttribute("MatchPhase")` y `workspace:GetAttribute("PhaseEnds")`.
    - En `"Prematch"`: muestra el banner superior con cuenta atrás (`COMBATE EN {sec} s`) y barra de tiempo, junto con el dock inferior de selección rápida de **Arma**, **Infusión** y **Skin** en propiedad, más el botón **«Armería Completa»** que abre `Armory.client.lua`. Al terminar `"Prematch"`, bloquea el equipamiento y oculta la antesala.
    - En `"Cinematic"` (D16): muestra las tarjetas dark-fantasy enfrentadas (`Red` vs `Blue` con emblema central `VS`) indicando el **Nombre**, **Nivel** (`Level`), **Insignia de Rol** (`Role`, p. ej. `[OWNER]`, `[DEV]`, `[ADMIN]`, `[TESTER]`), **Arma + Skin** e **Infusión** de cada participante de la partida.
  - **Traducciones completas (`ReplicatedStorage/LocaleGemini.lua`)**:
    - Todas las claves nuevas añadidas de forma simétrica en `ES`, `EN` y `PT-BR`.
  - **Verificación de herramientas**:
    - `node tools/check_lua.js .` → `OK: 75 archivos sin problemas detectados.`
    - `lihfolk-check.ps1 -Scan ServerScriptService ReplicatedStorage StarterPlayer ReplicatedFirst` → `0 errores y 0 avisos`.

---

### 2. Sin probar en Studio

- Inspección visual en vivo con iluminación de Roblox Studio del contraste entre el bisel `Foil` de plata espejo, el núcleo `Slate` de obsidiana y la vena `Neon` carmesí de `CrimsonEclipse`, `BloodMoonCleaver`, `CataclysmMaw` y las 36 skins rehechas.
- Clonado en vivo del avatar R15 del jugador dentro del `ViewportFrame` de `Armory.client.lua` en sesión de Play Solo.
- Flujo completo de transición de `MatchPhase` (`"Prematch"` → `"Cinematic"` → `"Fighting"`) en partida real cuando `MatchService` publique los atributos del Contrato C17.

---

### 3. Pendiente

- Nada pendiente de la Ronda 1 de Gemini.
- La pantalla de recompensas diarias y ruleta (`StarterPlayer/StarterPlayerScripts/Rewards.client.lua`, D14 y D15) queda programada para la **Ronda 2** según `Notas/Plan de desarrollo 0.2.md` y `Notas/0.2 Ronda 1 - Gemini.md`, una vez que Codex publique los remotos de recompensas y ruleta (Contratos C18 y C19).

---

### 4. Archivos tocados

- `ReplicatedStorage/Skins.lua`
- `ReplicatedStorage/SkinDesigns.lua`
- `ReplicatedStorage/WeaponBuilder.lua`
- `ReplicatedStorage/WeaponMeshes.lua`
- `ReplicatedStorage/LocaleGemini.lua`
- `StarterPlayer/StarterPlayerScripts/Armory.client.lua` *(nuevo)*
- `StarterPlayer/StarterPlayerScripts/Shop.client.lua`
- `StarterPlayer/StarterPlayerScripts/LobbyUI.client.lua`
- `StarterPlayer/StarterPlayerScripts/Prematch.client.lua` *(nuevo)*
- `tools/blender/generate_weapons.py`
- `modelos_armas/GUIA_SUBIDA_MALLAS.md`
- `modelos_armas/*.fbx`, `modelos_armas/*.obj`, `modelos_armas/*.mtl`, `modelos_armas/*_tex.png` *(21 mallas y 21 texturas 1024x1024 generadas por Blender)*
- `Notas/Reporte 0.2 Gemini.md` *(nuevo)*

---

### 5. Guía de subida de mallas de Blender (Tanda 1 — D6 / D15)

#### A. Lista exacta de archivos de la Tanda 1 a subir desde `modelos_armas/`
1. **3 Skins de la Ruleta (D15)**:
   - `modelos_armas/CrimsonEclipse.fbx` + `modelos_armas/CrimsonEclipse_tex.png` (`1554 tris`, `TipZ = 5.10`, Espada de referencia / Gran premio semanal)
   - `modelos_armas/BloodMoonCleaver.fbx` + `modelos_armas/BloodMoonCleaver_tex.png` (`1554 tris`, `TipZ = 7.60`, Espadón de la ruleta)
   - `modelos_armas/CataclysmMaw.fbx` + `modelos_armas/CataclysmMaw_tex.png` (`2272 tris`, `TipZ = 4.90`, Maza de la ruleta)
2. **5 Skins Piloto (1 por cada clase de arma)**:
   - **Dagas (`Dagger`)**: `modelos_armas/EclipseClaws.fbx` + `modelos_armas/EclipseClaws_tex.png` (`1194 tris`, `TipZ = 2.88`, skin `Relic05`)
   - **Espada (`Sword`)**: `modelos_armas/RequiemHorns.fbx` + `modelos_armas/RequiemHorns_tex.png` (`1342 tris`, `TipZ = 5.10`, skin `Requiem`)
   - **Espadón (`Greatsword`)**: `modelos_armas/AbyssWings.fbx` + `modelos_armas/AbyssWings_tex.png` (`1570 tris`, `TipZ = 7.60`, skin `Relic19`)
   - **Estoque (`Rapier`)**: `modelos_armas/DarkLament.fbx` + `modelos_armas/DarkLament_tex.png` (`1574 tris`, `TipZ = 5.56`, skin `Relic26`)
   - **Maza (`Mace`)**: `modelos_armas/OssuaryCrown.fbx` + `modelos_armas/OssuaryCrown_tex.png` (`2076 tris`, `TipZ = 4.90`, skin `Maw04`)

#### B. Cómo subirlos con el Importador 3D de Roblox Studio
1. Abrí el proyecto en **Roblox Studio** y hacé clic en **Import 3D** (cinta superior *Home* o *Avatar*) o abrí **View → Asset Manager → Bulk Import**.
2. Seleccioná cada archivo `.fbx` de la lista anterior en `modelos_armas/`.
3. En las opciones del importador:
   - Desmarcá **Rescale if too large** y verificá que **Scale Unit** esté en **Studs (1:1)** (el origen `(0,0,0)` ya coincide con el centro del mango `Handle` y la hoja apunta a `+Z`).
   - Confirmá haciendo clic en **Import / Upload**.
4. En **Asset Manager → Meshes** y **Asset Manager → Images**, hacé clic derecho sobre cada malla y su textura `*_tex` y elegí **Copy ID to Clipboard**.

#### C. Dónde pegar cada ID
Abrí `ReplicatedStorage/WeaponMeshes.lua` y pegá los números copiados en los campos `MeshId` y `TextureId` de cada entrada:
```lua
CrimsonEclipse = {
    MeshId = 1234567890,    -- ID de la malla subida
    TextureId = 9876543210, -- ID de CrimsonEclipse_tex.png
    ...
},
```
Mientras `MeshId = 0`, `WeaponBuilder` utiliza automáticamente el modelo procedural de alta definición de `SkinDesigns.lua`.

---

### 6. Pruebas para la integración (para Claude en Studio)

1. **Sincronizar con Rojo** (`default.project.json` ya monta `StarterPlayer/StarterPlayerScripts` y `ReplicatedStorage`, por lo que `Armory.client.lua` y `Prematch.client.lua` entran automáticamente).
2. **Probar en Play Solo en la ciudad**:
   - Verificar que el dock izquierdo muestre los botones separados **Armería** y **Tienda**.
   - Abrir **Armería** (botón o tecla `B`): comprobar que el visor 3D del personaje muestra al avatar empuñando el arma/skin seleccionada, que permite rotar/hacer zoom y cambiar de Arma, Skin, Infusión y Aura.
   - Abrir **Tienda** (botón del dock o puesto de la ciudad): comprobar la sección superior **«Destacado del Día»** (con cuenta atrás y `Filo del Eclipse Carmesí` encabezado como Gran Premio Semanal) y el **Catálogo Completo** debajo, verificando las 3 skins nuevas de la Ruleta (`CrimsonEclipse`, `BloodMoonCleaver`, `CataclysmMaw`) y las 36 skins rehechas.
3. **Probar Antesala y Cinemática (`Prematch.client.lua`)**:
   - Al entrar a una partida (o probando en la barra de comandos de Studio `workspace:SetAttribute("PhaseEnds", workspace:GetServerTimeNow() + 12); workspace:SetAttribute("MatchPhase", "Prematch"); game.Players.LocalPlayer:SetAttribute("InMatch", true)`), comprobar que aparece el banner de cuenta atrás y el dock rápido inferior de Arma/Skin/Infusión + acceso a la Armería completa.
   - Cambiar `workspace:SetAttribute("MatchPhase", "Cinematic")` y comprobar que se cierra la antesala/armería y aparecen las tarjetas dark-fantasy de presentación con Nombre, Nivel, Rol y Arma + Skin.

---

### 7. Pedidos a otros

- **A Claude (`MatchService.server.lua` / `ShopService.server.lua`)**:
  - Cuando `MatchPhase == "Prematch"`, permitir en `ShopService.server.lua` que `SelectWeapon`, `SelectInfusion` y `Equip` funcionen aunque `player:GetAttribute("InMatch")` sea `true` (actualmente `ShopService.server.lua` línea 75 bloquea `SelectWeapon`, `SelectInfusion` y `Equip` si `InMatch == true`; basta con permitirlo cuando `workspace:GetAttribute("MatchPhase") == "Prematch"` según el Contrato C17 y D11).
- **A Codex (Ronda 2 — Contratos C18 y C19)**:
  - Cuando estén listos los remotos `Remotes.Rewards` y `Remotes.Roulette` (con los IDs de las 3 nuevas skins de ruleta `CrimsonEclipse`, `BloodMoonCleaver` y `CataclysmMaw`), armaré `StarterPlayer/StarterPlayerScripts/Rewards.client.lua` en la Ronda 2.
