# Reporte 0.2 — Claude, ronda 1 (10/11/2026 13:51, Argentina)

Tarea: [[0.2 Ronda 1 - Claude]]. Decisiones aplicadas: D1, D2, D3 y D4 ([[Decisiones pendientes 0.2]]).
**Todo está escrito y compila, pero nada se probó en Studio** (regla de la etapa). Estados según [[Indicaciones para las IA]].

- `node tools/check_lua.js .` → OK, 73 archivos.
- Escáner LihFolk → 73 archivos, 0 errores, 0 avisos.

## Implementado (🟡 sin probar en Studio)
### 1. Combate direccional, pasos 1 a 5 (detrás de `CombatConfig.Directional.Enabled = false`)
- **Máquina de estados (C16)** en el servidor, módulo nuevo `ServerScriptService/Directional.lua`. Publica `CombatState`, `Stance`, `AttackDir` y `StateEnds` cada frame. El estado se deriva de las compuertas que ya existían (acción, fase, guardia, aturdimiento, derribo), así nunca se desincroniza de lo que el servidor permite.
- **Remoto `Input` ampliado (C25)**: número de secuencia, acción `Stance` validada contra {Up, Left, Right}, `KickRelease`, alias `GuardDown`/`GuardUp`, aviso `InputReject` para corregir la predicción.
- **Triángulo invertido** (`DirectionalHUD.client`, nuevo): sobre el rival fijado; tu postura en blanco (celeste con brillo al bloquear), el ataque que viene en rojo del lado por donde llega (dorado si es imbloqueable), punto naranja para la patada y destello dorado en el parry. En 2v2 también marca a otro rival cercano que te ataca.
- **Postura (D2)**: con objetivo fijado, el mouse queda centrado y un gesto corto (arriba, izquierda o derecha) elige el lado; en mando, el stick derecho. Abajo no hace nada. La postura queda. El cliente la muestra al instante y el servidor la valida.
- **Bloqueo y parry por dirección**: ventana común de 0,15 s; cambiar de lado tarda `SwitchTime` (×1,35 en espadón y maza, ×0,8 en dagas). **Margen de ping**: un golpe contra un jugador que no cubre ese lado espera hasta min(ping, 0,1 s); si en ese tiempo aprieta guardia del lado correcto, es parry. Nunca se usa una hora mandada por el cliente.
- **Combos por dirección y remate (D4)**: cada golpe sale por la postura de ese momento; si los dos primeros conectaron (golpe limpio), el tercero es un remate (×1,5 daño y Stun, ×1,6 empuje, hit-stop y temblor mayores, animación más exagerada, cartel «¡REMATE!»).
- **Patada (F)**: rompe cualquier guardia; si no conecta, recuperación larga que la esquiva no cancela. Estado `GuardBroken` de 0,8 s.
- **Derribado inmune a las armas** (D1): solo patada o levantar. Sobre un derribado, **tocar F lo patea** (empujón para sacarlo por el borde, la eliminación cuenta para quien pateó) y **mantener F 0,35 s lo levanta**. Lo decide el servidor con su reloj.
- **Fijado permanente en partida** (D1): no se suelta; T / R3 cambia al siguiente rival, y si el objetivo cae se fija solo al siguiente. En la ciudad y el patio sigue libre como antes.
- **Teclas (D1)**: con el direccional activo, `InputMap.DirectionalDefaults`: guardia Q / L2, patada F / B, esquiva Espacio / L1 (A también), fijar T / R3, cambiar objetivo G / cruceta derecha. Las asignaciones guardadas con el esquema viejo no se mezclan (marca `__layout`): con `Enabled = false` todo sigue como en la 0.1.
- **Excepciones por arma** (`WeaponData.Directional`): Maza, solo el fuerte de arriba es imbloqueable; Estoque, el fuerte atraviesa la guardia (el parry sigue valiendo). Propuesta de Codex en «Diseño Combate PvP Direccional Roblox».
- **Animaciones procedurales por lado** (`AnimClips.Directional`): la guardia y el reposo se inclinan hacia tu lado (el rival lo lee en tu cuerpo), y cada golpe carga hacia su lado y cruza al otro en el impacto.

### 2. Cámara en celular al fijar (`Controls.client`)
Causa probable: el suavizado partía de `camera.CFrame`, que la cámara de Roblox reescribe cada frame con su propio estado (arrastre táctil, zoom con dos dedos, oclusión). En el teléfono eso hacía que se trabara o saltara. Ahora el suavizado usa un estado propio, salta directo si la meta quedó lejos (al entrar a la arena) y fija `camera.Focus`.

### 3. Sensación del combate (C23), también con `Enabled = false`
- Evento `Effect` tipo `"Feel"` a cada involucrado: golpear, recibir, bloquear, ser bloqueado, parry, ser parreado, romper y que te rompan la guardia.
- Cada uno suena y se ve distinto. Hay un sonido 2D propio (reutiliza sonidos que ya están en `Assets`; ningún ID nuevo ni inventado). También borde de pantalla rojo al recibir, acero al bloquear y naranja al quedar abierto, y golpe de cámara.
- Cámara lenta breve (local, 30 studs) en el parry y la guardia rota.
- Hit-stop con tope de 0,2 s (guía `lihfolk-vfx`).
- Ritmo un 10 % más lento y parejo (`CombatConfig.Feel.TempoMult = 1,1`).
- Golpes más exagerados (1,22 → 1,32) y reacciones de dolor ×1,4.
- Guías usadas: `lihfolk-vfx` (tope de hit-stop, destellos cortos) y `lihfolk-sfx` (lo propio en 2D, no adelantar el resultado, no inventar IDs).

### 4. Equilibrio (D3)
Números de [[Equilibrio de armas]] aplicados en `WeaponData`. El +25 % de alcance (`ReachMult`) se aplica **siempre** (era un pedido general del usuario, no solo del direccional).

### 5. Etiqueta de rol (C18)
`Overhead.client` muestra «[ROL] Nombre» con el color del rol, leyendo el atributo `Role`. Lee `ReplicatedStorage.Roles` de Codex sin suponer su forma exacta (`Roles.color(rol)`, `Roles.Colors[rol]`, `Roles.Data[rol].color`…). Si todavía no existe, usa `PolishConfig.Roles`.

### 6. Muñecos del patio
Modos nuevos `DirOne` (siempre por el mismo lado, `workspace.DummyDir`) y `DirRandom` (cada golpe por un lado al azar). Muestran el lado 0,3 s antes de atacar. Con el direccional, los muñecos que bloquean o parrean ponen la guardia del lado correcto.

## Archivos tocados
`CombatConfig`, `WeaponData`, `PolishConfig`, `InputMap`, `AnimClips`, `LocaleES/EN/PT`, `Combat`, `Actions`, `CombatService`, `Fx`, `Dummies`, `Controls.client`, `Animator.client`, `Vfx.client`, `Overhead.client`. Nuevos: `ServerScriptService/Directional.lua` y `StarterPlayer/StarterPlayerScripts/DirectionalHUD.client.lua`.
Notas: [[Contratos 0.2]] (C16 y C23 con nombres finales, C25 nuevo), [[Versión 0.2]], [[Arquitectura Combate Direccional]], [[Equilibrio de armas]], [[Plan de desarrollo 0.2]], [[Peticiones del usuario]].

## Propuestas mías (no decididas por el usuario)
- Con el direccional, un fuerte bloqueado del lado correcto gasta mucha guardia pero ya no rompe la guardia automáticamente (en la 0.1 sí). La rotura queda para la patada y para la guardia vacía.
- Convención espejo de lados (ver C16).
- Cambiar de objetivo en teclado: G (T queda para fijar y, en partida, también cambia).
- Ritmo ×1,1 y exageración de animaciones: valores a ajustar jugando.

## Pendiente
- **Probar todo en Studio** (lista de abajo) y calibrar números: gesto del mouse, zona muerta del stick, `SwitchTime`, empujón de la patada al derribado (`DownedPushSpeed`) y capas de animación por lado (`PoseTune`).
- Táctil del direccional (D1: después).
- Opciones de zona muerta y umbral del gesto en Ajustes: interfaz de Gemini o Codex.
- Maza: «seguimiento del rival en el golpe lateral» ([[Equilibrio de armas]]): no hecho.
- Animaciones por dirección con captura de movimiento: hoy son capas procedurales.
- Cinemática (ronda 2).

## Pruebas para la sesión de integración
**Con `Enabled = false` (tiene que quedar como la 0.1, más la sensación):**
1. Teclas de la 0.1 intactas (F guardia, C patada, Q fijar). Combo, fuerte, parry, patada, agarrar y lanzar como antes.
2. Al golpear, recibir, bloquear y parrear se siente distinto: sonido propio, borde de pantalla y cámara lenta breve en el parry.
3. Alcance +25 % y ritmo un poco más lento en las 5 armas. La maza pega más; las dagas y el estoque, menos.
4. Celular: fijar en partida no traba ni hace saltar la cámara (girar con el dedo, zoom con dos dedos, entrar a la arena).
5. Etiqueta de rol sobre la cabeza con `Role` (por ejemplo `Tester` en mateodoupa) cuando exista `RoleService`.

**Con `Enabled = true` (cambiar en `CombatConfig`):**
1. Patio, muñeco `DirOne`: el triángulo marca en rojo el lado espejo; poniendo la postura ahí, bloquea; con pulsación justa, parry y destello dorado. Del lado equivocado, el golpe entra.
2. `DummyDir` (panel P o `Remotes.Debug:FireServer("DummyDir", "Up")`) cambia el lado fijo; `DirRandom` alterna.
3. Mouse: gesto corto arriba, izquierda o derecha cambia la postura y queda. El mouse no gira la cámara con objetivo fijado. Al abrir el menú, el mouse se suelta.
4. Mando: el stick derecho elige el lado; hacia abajo no hace nada.
5. Combo de 3 que conecta entero: el tercero muestra «¡REMATE!» y pega más. Si el 1 o el 2 fallan o los bloquean, no hay remate.
6. Patada contra quien bloquea: rompe la guardia. Patada al aire: recuperación larga y no se puede esquivar para cortarla.
7. Rival derribado: las armas no le hacen nada. Tocar F lo empuja unos 2 studs (calibrar); mantener F lo levanta. Patearlo fuera de la arena da la eliminación.
8. Partida: el fijado no se suelta; T / R3 cambia de rival; si cae, pasa solo al siguiente.
9. Con ping alto (Studio > Network > latencia simulada de 100 ms): un parry un poco tarde todavía entra.
10. Maza: el fuerte de arriba no se bloquea, los de los lados sí. Estoque: el fuerte atraviesa la guardia, pero se puede parrear.
11. 2v2: el triángulo también avisa del segundo rival que ataca de cerca.

## Pedidos a otros
- **Codex:**
  - Revisar la seguridad del remoto `Input` ampliado (C25).
  - En `Debug.client`: agregar los nombres de los modos `DirOne`/`DirRandom` a su tabla y un botón para `DummyDir`.
  - `Roles.lua`: si expone colores, que sea `Roles.Colors[rol]` o `Roles.color(rol)`. El nombre del rol (`Owner`, `Tester`, `VIP`, `New`…) se muestra con las claves `overhead.role.*`.
- **Gemini:**
  - `TouchUI` tiene que llamar `InputBridge.press("Kick", false)` al soltar el botón de patada: con el direccional, soltar = patear al derribado. Hoy C12 dice que solo Guardia se mantiene.
  - El HUD nuevo puede escuchar `Effect` tipo `"Feel"` (C23) para el destello de las barras.
  - Ajustes: los controles muestran el esquema que corresponda solo (usa `InputMap.merge`).

## Ronda 2 — 10/11/2026 18:40 (Argentina)
Prompts: [[0.2 Ronda 2 - prompts]]. Codex y Gemini corrieron por sus CLI (Codex: Sol, esfuerzo alto; Gemini: terminó su tanda aunque la consola mostraba errores 503). `check_lua` OK (88 archivos) y LihFolk 0/0. **Nada de la ronda 2 se probó en Studio todavía.**

### Implementado por Claude (🟡 sin probar en Studio)
- **Cinemática** (`Cinematic.client`, nuevo, D16/C17): arranca solo con `MatchPhase = Cinematic` y un `PhaseEnds` válido (ignora la primera fase sin duración). Tres planos: vista general en órbita, tu equipo de frente y los rivales de frente. Tiene franjas de cine y la cámara vuelve sola. Valores en `PolishConfig.Cinematic`. Las poses de entrada quedan pendientes.
- **Almas y nivel** (`Vfx.client`): al subir `leaderstats.Coins`, luces que se absorben en el pecho (ignora la carga del saldo al entrar). Al subir `Level`, anillo dorado y columna de luz. Sonidos ya existentes en `Assets`.
- **Tutorial del patio** (`Tutorial.client` y `TutorialService.server`, nuevos): 3 pasos (pegarle 3 veces a un muñeco, ponerse en guardia, patearlo). Los certifica el servidor y los paga `RewardService.tutorial` (pedido de Codex). El cliente solo muestra el progreso.
- **C6:** evento nuevo `Kick` (informativo; el daño sigue llegando como `Damage`). `strike` devuelve también las víctimas.

### Arreglos de integración entre IA
- Editor táctil (Gemini) conectado al guardado de Codex (`Settings` → `SetTouchLayout`, con espera de 1,5 s). Reaplica el diseño guardado cuando llega del perfil.
- La tienda compra multiplicadores con `BuyBoost` (cobro real) en vez de `LocalBoost`.
- El pedido de Codex sobre depuración por rol ya estaba resuelto (I4).

### Pendiente
- Probar en Studio toda la ronda 2: recompensas (ruleta, cajas, racha, primeros pasos, colección, maestría), HUD nuevo, editor táctil, resumen pospartida, cinemática con 2 clientes, tutorial, multiplicadores, migración del perfil a Schema 2 (Codex pide snapshot antes y no usar stores vivos).
- Poses de entrada en la cinemática.
