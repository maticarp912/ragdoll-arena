# Tarea para Codex — Lote 4, etapa 2: tienda de skins, HUD vertical e idiomas

Proyecto Roblox (Luau) en `F:\RobloxJuegos\Plataforme 2v2`. Responde en español rioplatense. Antes de empezar, lee:
- `Notas/Decisiones.md`, `Notas/Estado.md`, `Notas/Pendientes.md` y `Notas/Skins y precios.md`
- `REVISION_CLAUDE_3.md` y `REVISION_CODEX_3.md`

Todo valor numérico y todo color va en módulos de datos (`Theme`, `PolishConfig`, `Skins`), nunca suelto en la lógica. **Ningún texto visible suelto en los scripts**: todo pasa por el sistema de idiomas del punto 3.

## Archivos que PUEDES tocar
`StarterPlayer/StarterPlayerScripts/Shop.client.lua`, `HUD.client.lua`, `Overhead.client.lua` · `ServerScriptService/ShopService.server.lua` · `ReplicatedStorage/Skins.lua`, `WeaponBuilder.lua` (solo diseños de skins, ver abajo), `Theme.lua` (UI e iconos; no cambies `Theme.Lighting`, `Theme.Arena` ni `Theme.Lobby`), `PolishConfig.lua` (sin tocar `Walk`) · `ServerScriptService/PlayerData.lua` (solo para guardar el idioma) · nuevos: `ReplicatedStorage/Localization.lua`, `LocaleES.lua`, `LocaleEN.lua`, `LocalePT.lua` y `StarterPlayer/StarterPlayerScripts/Settings.client.lua` (menú de Ajustes con Controles e Idioma, con su propio botón en pantalla. La tecla B de `Controls` sigue abriendo la tienda).

## Archivos que está tocando Claude (NO los edites)
`Combat`, `CombatConfig`, `Actions`, `Infusion.lua`, `Infusions.lua`, `WeaponData`, `Controls.client`, `Animator.client`, `AnimClips`, `MatchService`, `CombatService`, `Fx`, `Vfx.client`, `Infusion.client`, `Debug.client`, `Dummies`, `Ragdoll`, `LobbyBuilder`, `ArenaBuilder`, `Environment`. Si necesitas algo de ellos, anótalo en tu revisión.

## 1. Rediseño completo de la tienda (armería dark fantasy)
Debe ser uno de los puntos más atractivos del juego: una armería dark fantasy elegante, con personalidad, donde **los modelos 3D son los protagonistas**.

**Método: primero la sección de Espada con la calidad final** (tarjetas, una skin seleccionada, vista grande y estados de compra/equipamiento). Úsala de referencia y luego extiende el mismo diseño a Espadón, Dagas, Estoque y Maza.

### Organización
- Secciones claras: **Armas, Skins e Infusiones**. **Ajustes y Controles salen de la tienda**: van a un menú propio de Ajustes (ahí va también el selector de idioma del punto 3).
- Dentro de Skins, **un apartado por arma**.
- **Filtros**: por rareza, adquiridas y disponibles.
- Estados claros en cada tarjeta: **comprada, equipada o bloqueada**. Mantén el bloqueo de arma e infusión durante la partida.

### Cada skin visible en 3D
- Cada tarjeta muestra **su modelo 3D girando lentamente** (ViewportFrame), con una iluminación que deje apreciar forma, textura y materiales.
- Al seleccionar una skin se abre una **vista grande con rotación manual** (arrastrar con mouse, dedo o stick) y **zoom limitado**.
- Muestra nombre, rareza, descripción breve, precio y botón **Comprar** o **Equipar**.
- **La vista previa debe ser exactamente el modelo que se equipa**: usa `WeaponBuilder.buildModel(weaponId, skinId)`, el mismo constructor del Tool.
- **Modelos a partir de las referencias** de `F:\RobloxJuegos\skins armas`. Solo hay JPG, ningún modelo: `espadas` 8, `espadon` 6, `dagas` 5, `estoque` 7, `martillo hacha` 6.
  - Mira cada imagen y diseña la skin como **modelo de piezas** en `WeaponBuilder`, un diseño por skin, como los `Designs` actuales.
  - Lo que no puedas modelar con fidelidad, **regístralo en `Notas/Assets.md` como "modelo por crear"** y en la tienda muéstralo como "Próximamente". **No presentes imágenes como skins 3D terminadas.**
  - No cambies `WeaponBuilder.Info` (`gripZ`, `offhandZ`, `twoHanded`, `dual`, `trail`): las animaciones y el IK dependen de esos valores. Cada skin respeta el mismo agarre, una escala parecida y los attachments `BladeBase` / `BladeTip`.
  - Cada skin pertenece a un arma en `Skins.lua` (`weapon = "Sword"`, etc.). Las genéricas actuales pueden quedar como "todas las armas".

### Dirección artística
- Fondos de **piedra oscura y hierro envejecido**, detalles de **oro apagado** y **motivos góticos** (marcos, esquinas y separadores).
- **Armas bien iluminadas**: luz principal, relleno y contraluz en el ViewportFrame, y un fondo que no se coma las skins negras. Que una skin negra se distinga.
- **Colores de rareza solo como acentos discretos** en marcos y fondos.
- Tipografía temática en los títulos y **muy legible** en descripciones, precios y botones.
- La decoración **no compite con los modelos** ni confunde la navegación.

### Movimiento y respuesta
- Entrada y salida suaves, con desvanecimiento y un desplazamiento breve. Transiciones entre categorías y al seleccionar tarjetas.
- Respuesta **visual y sonora** al pasar, seleccionar, comprar y equipar (sonidos de `Assets.Sounds.UI_*`).
- **Efecto breve y especial al adquirir una skin** (destello del color de su rareza y el modelo girando), sin bloquear la navegación.
- **Rendimiento**: las tarjetas fuera de pantalla o de otra pestaña **no animan** sus ViewportFrames. Rota solo lo visible.

### Precios y comodidad
- **Rarezas y precios** según `Notas/Skins y precios.md`, en proporción al acabado y la espectacularidad de cada skin. Todas son **solo cosméticas**. Ajusta la propuesta si hace falta y explícala en tu revisión.
- **Monedas del juego y Robux bien diferenciados**, con icono y color propios.
- **Confirmación de compra**: un diálogo con nombre, modelo en miniatura, moneda y precio, y botones Confirmar y Cancelar. Que no haya compras accidentales.
- Funciona con **mouse, mando (navegación con `GuiService.SelectedObject`) y pantalla táctil**.
- Textos en los tres idiomas **sin recortes** (punto 3).
- La compra y el equipamiento los valida el servidor (`ShopService`).

### Verificación
**Prueba la tienda en Studio** con varios tamaños de pantalla: escritorio, portátil pequeño y móvil (usa el emulador de dispositivos de Studio). Si no puedes abrir Studio, dilo claramente y deja la lista exacta de lo que hay que comprobar.

## 2. HUD vertical a la derecha
- Columna en el borde derecho, compacta y que **no tape el combate**. Cada barra lleva su icono dibujado con piezas de UI (Frames, UIStroke, UICorner, rotaciones, gradientes) y estilo dark fantasy. Si hay ID en `Assets.Icons`, usa la imagen.
  - **Vida**: corazón.
  - **Stamina**: símbolo de energía sencillo que **no se confunda con Rayo** (por ejemplo una bota o zancada, o tres chevrons).
  - **Guardia**: escudo que **se agrieta** al bajar (grietas visibles por tramos), **se rompe** al agotarse (`GuardBroken`) y se ve cómo **se recompone** al recuperarse.
  - **Stun**: estrellas de aturdimiento que se llenan.
  - **Infusión**: icono propio por tipo (Fuego llama, Rayo **varios rayos**, Hielo cristal, Sombra **cráneos**), con carga, tiempo activo restante (`InfusionEndsAt`) y agotamiento (`InfusionLockUntil`).
- Mantén lo que ya funciona: rastro de daño, avisos de stamina, retratos de partida arriba (puedes reubicarlos si chocan).
- Atributos disponibles en el personaje: `Stamina`/`StaminaMax`, `Guard`/`GuardMax`/`GuardBroken`/`GuardBrokenUntil`, `Stun` (máx. `CombatConfig.Stun.Max`), `InfusionId`/`InfusionCharge`/`InfusionActive`/`InfusionEndsAt`/`InfusionLockUntil`. El tiempo es `workspace:GetServerTimeNow()`.

## 3. Idiomas: español, inglés y portugués de Brasil
- `Localization.lua` con `Localization.t(key, params)` (marcadores `{name}`), respaldo en inglés si falta una clave, y `Localization.format(msg)` que acepte texto o `{ key = "...", params = {...} }`, para que Claude migre los mensajes del servidor en la etapa 3.
- Tablas en `LocaleES.lua`, `LocaleEN.lua`, `LocalePT.lua` (el generador solo lee archivos sueltos en `ReplicatedStorage`, no subcarpetas). **Claves internas sin traducir; nombres visibles traducidos.** Traducciones **naturales** (inglés natural, portugués de Brasil) y terminología consistente: decide un glosario (Guardia/Guard/Guarda, Stun/Stun/Atordoamento, Infusión/Infusion/Infusão, etc.) y escríbelo en tu revisión.
- **Detección del idioma** por `player.LocaleId` (es-*, pt-*, resto inglés), selector en el **menú de Ajustes** (fuera de la tienda, junto con Controles) y **guardado** en `PlayerData` (campo `Language` y atributo `Language` del jugador). Al cambiarlo, la UI se rehace en el idioma nuevo.
- Traduce todo lo que tocas: tienda, HUD, Overhead, nombres y descripciones de armas, skins e infusiones (añade claves sin quitar los campos actuales de los datos), controles y ajustes.
- **Layouts que aguanten textos de distinta longitud**: `AutomaticSize`, `TextWrapped`, `UITextSizeConstraint`, sin recortes ni superposiciones. Revisa las tres versiones.

## Al terminar
1. `node tools/check_lua.js .` sin errores.
2. `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`.
3. Escribe `REVISION_CODEX_4.md` con: lo **implementado**, lo **comprobado en Studio** (si no abriste Studio, dilo) y lo **pendiente de probar**, el glosario de términos y lo que Claude deba conectar.
4. Actualiza `Notas/Estado.md` y `Notas/Registro de cambios.md` solo en tus apartados.
