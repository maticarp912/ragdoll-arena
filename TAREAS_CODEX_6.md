# Tarea para Codex — Lote 6: modelar las skins y dar más detalle a las armas

> **YA HECHO POR CLAUDE (9/11/2026). No se lo des a Codex.** Ver `Notas/Registro de cambios.md` y `Notas/Catálogo de skins.md`.

Proyecto Roblox (Luau) en `F:\RobloxJuegos\Plataforme 2v2`. **Trabaja directamente en esta carpeta**, no en una copia. Responde en español rioplatense.

Si el lote 5 (`TAREAS_CODEX_5.md`: HUD, tienda e idiomas) no está terminado, termínalo primero. Este lote es solo de modelos.

Lee primero:
- `Notas/Estado.md`, `Notas/Decisiones.md` y `Notas/Catálogo de skins.md`.
- `ReplicatedStorage/Skins.lua` y `ReplicatedStorage/WeaponBuilder.lua`, sobre todo `buildInto`, `Designs.*` y `Skins.Designs`.

## Situación actual
- `Skins.lua` tiene 32 skins por arma (`Relic01`…`Relic32`). Solo 7 tienen modelo: `Solar`, `Duel`, `Violet`, `Void`, `Shroud`, `Flange` y `Forge`.
- Las otras **25** tienen `comingSoon = true`, `design = nil` y colores genéricos. En la tienda aparecen como «próximamente» y no se ven.
- Cada una tiene su imagen de referencia en `source`, en `F:/RobloxJuegos/skins armas/<arma>/`. **Mira la imagen de cada skin antes de modelarla.**
- Las armas base (`Designs.Sword/Rapier/Greatsword/Dagger/Mace` en `WeaponBuilder`) son simples. El usuario pidió más detalle en general.

## Qué hacer
1. **Modelar las 25 skins que faltan**, por arma y en este orden: Espada, Espadón, Estoque, Daga, Maza/Hacha.
   - Cada una debe parecerse a su imagen: silueta, guarda, pomo, grabados, gemas, colores y materiales.
   - Al terminarla: `comingSoon = false`, `design = "<Nombre>"`, colores `blade`/`accent`/`trail` propios y `desc` con una línea dark fantasy.
   - Si una imagen es imposible de hacer con piezas, deja esa skin en `comingSoon` y explica por qué en la revisión.
2. **Más detalle en las 5 armas base**: biseles y acanaladura en la hoja, guarda con forma, cuero enrollado en el mango, remaches y pomo trabajado. Mantén su identidad (la daga corta, el espadón enorme, la maza pesada).
3. **Detalle extra en las 7 skins que ya existen** si quedaron pobres al lado de las nuevas.
4. **Herramientas del constructor** (en `WeaponBuilder`): puedes ampliar `Skins.Designs` para aceptar:
   - Las formas `Cylinder`, `Ball`, `Wedge` y `CornerWedge`.
   - Piezas que brillen: un rol `Glow` en Neon con `PointLight` opcional y débil.
   - Partículas suaves opcionales: brasas, escarcha o humo.
   - Si escribir las piezas a mano es muy largo, puedes generarlas con funciones de ayuda (curvas, anillos, filas de dientes), siempre que el resultado sea determinista.
5. **Vista en la tienda**: todas las skins con modelo deben verse en su tarjeta y en la vista grande con el mismo `WeaponBuilder.buildModel`. Comprueba que el encuadre de la cámara del `ViewportFrame` se adapte al tamaño de cada arma, para que el espadón no quede cortado ni la daga diminuta.
6. **Nombres y descripciones** de las skins en `LocaleES/EN/PT.lua` (`skin.<id>` y `skinDesc.<id>`).

## Reglas
- **Solo cosmético**: no cambies `WeaponBuilder.Info`, alcances, daños ni nada de `WeaponData`. El golpe lo calcula el servidor; el modelo solo se ve.
- No muevas el agarre: el `Handle` sigue en el origen y la hoja crece hacia +Z, como ahora. `mainZ` y los adjuntos del rastro (`addTrailAttachments`) tienen que seguir funcionando.
- **Presupuesto de piezas**:
  - Arma base: 60 como máximo.
  - Skin: 110 como máximo.
  - Luces: 1 `PointLight` por arma como máximo.
  - Todas las piezas `Massless`, sin colisión, `CanQuery = false` y `CanTouch = false`. `buildInto` ya se encarga si usas `b:add`.
- Todos los números de diseño van en los módulos de datos (`Skins.lua` y las tablas de `WeaponBuilder`), no sueltos en la tienda.
- Mantén la paleta dark fantasy: metales gastados, poco brillo y Neon solo en runas o gemas.

## Archivos que PUEDES tocar
`Skins.lua`, `WeaponBuilder.lua` (diseños y constructor; **no** `WeaponBuilder.Info`), `Shop.client.lua` (solo la vista de modelos), `LocaleES.lua`, `LocaleEN.lua`, `LocalePT.lua`, `Notas/Catálogo de skins.md`.

## Archivos de Claude (NO los toques)
`Combat`, `CombatConfig`, `Actions`, `Infusion`, `Infusions`, `WeaponData`, `Controls.client`, `Animator.client`, `AnimClips`, `MatchService`, `CombatService`, `Fx`, `Vfx.client`, `Infusion.client`, `Atmosphere.client`, `Lobby.client`, `Debug.client`, `Dummies`, `Ragdoll`, `LobbyBuilder`, `CityConfig`, `ArenaBuilder`, `ArenaConfig`, `Environment`, y en `Theme.lua` las partes `Lighting`, `Ambience`, `Arena` y `Lobby`.

## Al terminar
1. `node tools/check_lua.js .` sin errores.
2. `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`.
3. Escribe `REVISION_CODEX_6.md` con:
   - Una tabla por skin: id, nombre, imagen, cantidad de piezas y estado.
   - Las secciones **implementado**, **comprobado en Studio** y **pendiente de probar**.
4. Actualiza `Notas/Catálogo de skins.md`. Actualiza `Notas/Estado.md` y `Notas/Registro de cambios.md` solo en tus apartados.
