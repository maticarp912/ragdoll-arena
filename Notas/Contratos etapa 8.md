# Contratos de la etapa 8 (Claude, Codex y Gemini)

Puntos de conexión entre las tres IA. Quien «produce» lo crea y lo mantiene; quien «consume» solo lo lee. **No cambies un contrato por tu cuenta**: si hace falta, pedilo en tu reporte («Pedidos a otros»). Lo marcado ✅ ya existe en el código.

## C0. Revisión antes de entregar (desde el 9/11) ✅
Antes de terminar una tarea, cada IA pasa `node tools/check_lua.js .` **y** el revisor LihFolk (comando en [[Referencia LihFolk]]): 0 errores, y cada aviso nuevo en sus archivos arreglado o justificado en el reporte.

## C0b. Git (desde el 9/11) ✅
La carpeta del juego es un repositorio de Git (rama `main`). **Solo Claude hace commits**: uno al integrar cada ronda y otro antes de empezar la siguiente.
- Codex y Gemini pueden usar `git status` y `git diff` para ver qué cambiaron.
- No hacen `commit`, `checkout`, `reset`, `stash`, `restore` ni cambian de rama.
- El place `.rbxlx`, los `_backup_*` y los `.log` no se versionan (ver `.gitignore`).

## C1. Idiomas ✅
`Localization.lua` (Claude) mezcla `ReplicatedStorage/LocaleCodex.lua` (Codex) y `ReplicatedStorage/LocaleGemini.lua` (Gemini).
Formato: `return { ES = { clave = "texto" }, EN = {...}, ["PT-BR"] = {...} }`, mismas claves en los tres. Las claves de `LocaleES/EN/PT.lua` ganan (en Studio se avisa si se repiten). Parámetros `{nombre}`; un parámetro `nombreKey` con una clave de idioma se traduce y rellena `{nombre}`.

## C2. Mensaje de estado de partida ✅ (produce Codex, muestra Gemini)
`workspace:SetAttribute("StatusParams", HttpService:JSONEncode(params))` y **después** `workspace:SetAttribute("StatusKey", "clave")`. Si `StatusKey` está vacío se muestra `Status` (texto viejo). `HUD.client` ya lo soporta: quien rediseñe el HUD tiene que conservarlo.

## C3. Colas ✅ (servidor Codex, interfaz Gemini)
Remoto `Remotes.Queue` (RemoteEvent): `FireServer("Join", "1v1"|"2v2")`, `FireServer("Leave")`. Lectura: `workspace` `QueueCount1v1` / `QueueCount2v2`, atributo de jugador `QueueMode`. Los círculos físicos de la antesala siguen funcionando.

## C4. Arma ✅ (produce Gemini)
`Handle`; attachments `BladeBase` y `BladeTip` en la base y la punta **visible** de la hoja; atributo `Role` en cada pieza (`Blade`, `Edge`, `Accent`, `Dark`, `Grip`, `Leather`, `Glow`, `Trim`…); el `Tool` tiene atributos `WeaponId` y `SkinId`; segunda daga en `char.OffhandWeapon`; `WeaponBuilder.Info[arma]` (`gripZ`, `twoHanded`, `offhandZ`, `dual`, `trail`). `WeaponBuilder.buildModel(arma, skin)` debe dar **el mismo modelo** que se empuña.

## C5. Estado del personaje ✅ (produce Claude)
Atributos del `Model`: `Telegraph` (`""`, `"Heavy"`, `"Unblockable"`), `Action`, `ActionPhase`, `InfusionActive`, `InfusionId`, `Ragdolled`, `KnockedDown`, `CarriedBy`, `Carrying`, `Stun`, `Guard`, `GuardMax`, `InfusionCharge`, `Stamina`, `StaminaMax`, `WeaponId`. Jugador: `InMatch`, `WeaponId`, `InfusionId`, `EquippedSkin`, `OwnedSkins`, `Language`.

## C6. Eventos de combate ✅ (produce Claude, consume Codex)
`ServerScriptService/CombatEvents.lua`: `CombatEvents.Fired:Connect(function(kind, attackerChar, victimChar, info) end)`.
`kind`: `Damage` (`info.amount`), `Knockdown`, `Kill` (también por caída al vacío: se acredita al último que golpeó en `CombatConfig.Credit.Window` = 8 s; puede ser `nil`), `GuardBreak`, `Parry` (attacker = quien parreó), `Throw`. Pueden ser muñecos (`Players:GetPlayerFromCharacter` = nil). Contar estadísticas solo con `InMatch`.

## C7. Estadísticas y tablas de clasificación (produce Codex, muestra Gemini, ubica Claude)
- Atributos de jugador: `StatWins`, `StatKills`, `StatKnockdowns`, `StatMatches` (totales guardados).
- `ReplicatedStorage.Leaderboards` (Folder) con `StringValue` `Wins`, `Kills`, `Knockdowns`, `Coins`. `Value` = JSON con el top 10: `[{"userId":123,"name":"Nombre","value":45}]`. Se actualiza como mucho cada 60 s (OrderedDataStore; en Studio sin API, con los jugadores del servidor).
- Tableros en la ciudad: partes con la etiqueta de CollectionService `LeaderboardBoard` y el atributo `Board` (`"Wins"`, `"Kills"`, `"Knockdowns"`, `"Coins"`); se dibuja sobre la cara `Front`. Las coloca Claude en `LobbyBuilder`; Gemini dibuja su `SurfaceGui` desde el cliente (`Leaderboards.client.lua`). Para probar antes, Gemini puede crear una parte de prueba desde la barra de comandos.

## C8. Misiones diarias (produce Codex, muestra Gemini)
- `ReplicatedStorage/Missions.lua` (Codex): catálogo y números.
- `Remotes.Missions` (RemoteFunction): `InvokeServer("Get")` → `{ resetAt = <unix>, list = { { id, nameKey, params, progress, goal, reward, claimed } } }`; `InvokeServer("Claim", id)` → `ok, { key = "..." }`.
- `Remotes.MissionsChanged` (RemoteEvent, sin argumentos): el servidor avisa al jugador cuando cambia algo.

## C9. Fin de partida y avisos (produce Codex, muestra Gemini)
- `Remotes.MatchSummary` (RemoteEvent, a cada jugador): `{ result = "Win"|"Lose", mode = "1v1"|"2v2", kills, knockdowns, damage, coins = { match = n, missions = n, total = n } }`.
- `Remotes.KillFeed` (RemoteEvent, a todos los de esa partida): `{ kind = "Kill"|"Knockdown", killer = "Nombre" o nil, victim = "Nombre", killerTeam, victimTeam }`.
- Atributo de jugador `Eliminated` (bool): `true` al morir dentro de una ronda, `false` al empezar la siguiente. Claude lo usa para la cámara de espectador.

## C10. Opciones (guarda Codex, interfaz Gemini, aplica Claude)
- `Remotes.Settings` (RemoteFunction, ya existe en `ShopService`): nuevas acciones `GetOptions` → tabla y `SetOptions(tabla)` validada.
- Claves (0..1): `MusicVolume`, `SfxVolume`, `CameraShake`; además `UiScale` (0.8..1.2).
- Codex las refleja en atributos de jugador `OptMusic`, `OptSfx`, `OptShake`, `OptUiScale`.
- Claude mete todos los sonidos en `SoundService.SFX` y `SoundService.Music` (SoundGroups) y aplica `OptShake` a la sacudida de cámara. `Settings.client` (Gemini) pone el volumen de esos SoundGroups según los atributos, al iniciar y al cambiar.

## C11. Auras (produce Codex, tienda de Gemini)
- `ReplicatedStorage/Auras.lua` (Codex): `Auras.Order` y `Auras.Data[id] = { kind = "Body"|"Weapon", rarity, currency = "Coins"|"Robux", price, productId, nameKey, descKey, ... }`.
- `Remotes.Shop` (RemoteFunction): acciones nuevas `BuyAura`, `EquipAura`, `UnequipAura` con el id → `ok, { key = "..." }`. Las de Robux abren la compra de Roblox igual que las skins.
- Atributos de jugador `OwnedAuras` (ids separados por comas) y `EquippedAura` (id o `""`).
- `ReplicatedStorage/AuraFx.lua` (Codex): `AuraFx.attach(target, auraId, options) -> cleanup()`; `target` es un personaje (`Body`) o un modelo/Tool de arma (`Weapon`); `options.preview = true` para la tienda.
- **Ojo**: las partículas **no se ven dentro de un ViewportFrame**. La vista previa de auras tiene que ser en el mundo (por ejemplo, un pedestal de vista previa con su propia cámara).

## C12. Controles táctiles ✅ (interfaz Gemini, lógica Claude)
`ReplicatedStorage/InputBridge.lua`: `InputBridge.press(actionId, isDown)` con los ids de `InputMap.Actions` (`Attack`, `Heavy`, `Block`, `Dodge`, `Interact`, `Kick`, `Infuse`, `LockOn`, `SwitchTarget`, `Menu`). `Block` se mantiene; el resto actúa al apoyar. Claude lo conecta en `Controls`.

## C13. Pantalla de carga ✅ (Gemini)
Carpeta `ReplicatedFirst/` en la raíz del proyecto: sus `.lua` se generan como LocalScripts de ReplicatedFirst (`make_rbxlx.js` y `check_lua.js` ya la leen).

## C14. Iluminación
`Atmosphere.client` y `Sky.client` (Claude) son los únicos que tocan `Lighting.Atmosphere`, `Sky`, `ColorCorrection`, `Bloom` y la hora. Las arenas (Codex) pueden crear sus propios efectos en `Lighting` con nombre `Arena*` (como `ArenaDOF`) y activarlos solo con `InMatch`.

## C15. Estilo visual de interfaz
`Theme.lua` es de Claude (lo usan el mundo y la interfaz actual): solo lectura para los demás. Los tokens nuevos de interfaz van en `ReplicatedStorage/UiTheme.lua` (Gemini). Los demás leen `UiTheme` para que todo combine.
