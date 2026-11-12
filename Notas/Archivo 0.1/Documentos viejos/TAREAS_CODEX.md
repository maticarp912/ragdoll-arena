# Ragdoll Arena — tareas pendientes (para Codex u otra sesión)

> Proyecto Roblox (Luau) en `F:\RobloxJuegos\Plataforme 2v2`. Leé primero `README.md` y `RESUMEN_PROYECTO.md`.
> Idioma con el usuario: español rioplatense. Todo valor numérico va en módulos de datos (`CombatConfig`, `WeaponData`, `Theme`, `Assets`).

## Cómo trabajar
- Comprobar sintaxis: `node tools/check_lua.js .` (chequeo básico; no es un analizador completo).
- Generar el lugar: `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"` y abrirlo en Roblox Studio (`RobloxStudioBeta.exe` en `%LOCALAPPDATA%\Roblox\Versions\...`). Si Studio ya está abierto con el lugar: cerrarlo **sin guardar** (la fuente de verdad son los `.lua`) y reabrir.
- Probar: F5 (Play). Ventana > Salida para ver errores. Tecla **P** = panel de depuración (modos del muñeco, cajas de golpe, AnimTester, +monedas).
- Barra de comandos de Studio (contexto **Cliente** durante Play), útil para afinar animaciones sin reiniciar:
  - Cámara lateral fija: `local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable local r=game.Players.LocalPlayer.Character.HumanoidRootPart r.Anchored=true cam.CFrame=CFrame.lookAt((r.CFrame*CFrame.new(10,1.5,-1)).Position, r.Position+Vector3.new(0,1.2,-1))`
  - Congelar un clip en un instante: `workspace:SetAttribute('PoseFreeze','Weapons.Sword.M1_1@0.5')` (vacío `''` para soltar)
  - Sumar grados a una articulación: `workspace:SetAttribute('PoseTune','{"RW":[-40,0,0]}')`
  - Cambiar modo del muñeco: `game.ReplicatedStorage.Remotes.Debug:FireServer('DummyMode','Heavy')`
- **IMPORTANTE (descubierto probando):** esta versión de Roblox usa el *Avatar Joint Upgrade*: las articulaciones del R15 son `AnimationConstraint` (con `Attachment0/1`), no `Motor6D`. `Animator.client.lua` y `Ragdoll.lua` ya soportan ambos. Los `Transform` se escriben en `RunService.Stepped` (después del Animator de Roblox y antes de la física). No usar `C0` (da "read only").

## Estado verificado en Studio (8/11/2026)
- Arranca sin errores de scripts. HUD inferior, stamina, lobby/zona de práctica, braseros, muñecos, menú.
- Postura de reposo de la Espada y el clip `M1_1` se ven bien (preparación y golpe).
- Los muñecos se animan (se vio la preparación del fuerte) y el derribo/ragdoll del jugador funciona.
- **No verificado aún:** resto de armas, IK de dos manos, agarre/carga/lanzamiento, sonidos (que todos los IDs carguen), tienda con vistas previas, menú de controles con mando, VFX.

## Errores / pulido detectados (prioridad alta)
1. **Panel "DERRIBADO" visible estando muerto** (`Controls.client.lua`, `isDown`/RenderStepped): ocultarlo si `Humanoid.Health <= 0`.
2. **El muñeco en modo Fuertes te mata en la zona de práctica** (45 de daño × 3). Proponer al usuario: en el lobby la vida no baja de 1 (o el daño de los muñecos ×0.5). Hacerlo en `Combat.applyDamage` según `InMatch`.
3. **Revisar poses de todas las armas** con `PoseFreeze`/`PoseTune` (keys de `AnimClips.lua`): `Stances.*.Ready/Guard` y `M1_1..3/Heavy` de `OneHand`, `TwoHand`, `Hammer`, `Dual`, `Rapier`; genéricas `Dodge*`, `Kick`, `HitReact*`, `GuardBreakStagger`, `ParriedStagger`, `GetUpBack`, `PickUp`, `ThrowShort/Far`, `ReviveSlap`, y `Common.Carry/ThrowCharge`. Ajustar ángulos hasta que se vean naturales (la hoja debe apuntar al rival en reposo; guardia con el arma cruzada).
4. **IK de la mano izquierda** (Espadón y Maza, `solveLeftArm` en `Animator.client.lua`): verificar que existe la soldadura `RightGrip` en `RightHand` con el rig nuevo y que la mano izquierda queda en el mango (`WeaponBuilder.Info[*].offhandZ`). Si el codo dobla al revés, invertir el polo (`CFrame.new(-1.6,-1.4,0.8)`).
5. **Ragdoll** (`Ragdoll.lua`): comprobar que codos y rodillas doblan hacia el lado correcto (signos de `HingeConstraint` en `JOINTS`), que no tiembla y que al levantarse queda de pie sobre el suelo. Ajustar `JOINTS` (cono/giro/fricción) y `LIMB_PHYSICS` para la sensación "Gang Beasts".
6. **Agarre/carga/lanzamiento** (`Combat.lua`: `grab`, `attachToShoulders`, `throw`, `checkCarry`, `struggle`): probar R sobre un muñeco derribado, que quede cruzado sobre los hombros, clic = tirón corto, mantener E/RT = barra de carga y lanzamiento lejano, forcejeo del cargado, que un golpe al que carga lo suelte. Ajustar `CombatConfig.Grab`.
7. **Sonidos** (`Assets.lua`): ver en Salida si algún ID falla ("Failed to load sound"). Reemplazar por audios públicos (preferir creador `ProSoundEffects` / `Roblox`). Búsqueda sin auth: `https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Audio&query=<texto>&maxPageSize=30`. Ajustar volúmenes en `Assets.SoundSettings`.
8. **Modelos de armas** (`ReplicatedStorage/WeaponBuilder.lua`, basados en el arte del usuario): revisar proporciones y orientación en la mano (`Info[*].gripZ`), y la daga de la mano izquierda (`addOffhand`).
9. **Tienda y menú** (`Shop.client.lua`): encuadre de las vistas 3D, navegación con mando (`GuiService.SelectedObject`), reasignar teclas/botones y que se guarden (`SettingsRF`, `PlayerData.Keybinds`), "+1000 monedas" de prueba.
10. **VFX** (`Vfx.client.lua`): tamaño/cantidad de partículas; el golpe de FOV fuerza `camera.FieldOfView` cada frame (no pelear con el lock-on); viñeta de poca vida.
11. Quitar en `Controls.client.lua` el hitstop viejo sobre `AnimationTrack` (ya lo hace `Animator.client.lua`).
12. Rendimiento de `Animator.client.lua`: crea tablas cada frame por personaje; reutilizar buffers si hay muchos jugadores.
13. Confirmar que el generador aplica `Lighting.Technology = Future` y `StarterPlayer.GameSettingsAvatar = R15` (si Studio ignora la propiedad, documentarlo para que el usuario lo ponga a mano).

## Fases pendientes del diseño (ver `RESUMEN_PROYECTO.md` §12–13)
- **Fase B completa:** derribo crítico en 2v2 (vida 0 → desangrado 20 s, rescate del aliado con R 2 s y 35 % de vida), gatear, intercepción de lanzamientos, interrupción de rescates por golpes (las Dagas interrumpen agarres).
- **Fase C:** `Infusions.lua` + `Effects.lua` (6 infusiones, Q para activar, 12 s + 5 s de agotamiento, hexágono de contras y afinidad ±8 %, icono visible, VFX/sonidos por infusión). La carga ya existe (`InfusionCharge`).
- **Fase E:** `Progression.lua` (XP, niveles, maestría por arma, desbloqueos con monedas/Robux, `ProcessReceipt`), misiones diarias.
- **Móvil:** se quitó el panel de botones de la derecha; hacen falta botones táctiles (ataque, fuerte, guardia, esquiva, R, Q).
- Animaciones reales: cuando el usuario suba IDs a `Assets.lua`, reemplazan solas a las procedurales (el servidor lee los marcadores `Hit`/`WindupEnd` con `AnimTiming`).
