# Tareas ronda 4 — Codex (9/11, 17:30)

> Prompt completo para Codex. **Modelo: Sol, Medium.** Contexto: [[Reparto etapa 8]], [[Contratos etapa 8]], [[Peticiones del usuario]].
> Gemini Argon está trabajando en las arenas (`ArenaBuilder`, `ArenaConfig`, `ArenaBackdrop.client`, `Arena.client`): **no los toques**. Claude integra y prueba.
> Reglas de siempre:
> - Tocá solo tus archivos.
> - No regeneres `Ragdoll Arena.rbxlx`.
> - `node tools/check_lua.js .` tiene que dar OK.
> - Textos nuevos en `LocaleCodex.lua` con las mismas claves en ES, EN y PT-BR.
> - Reporte en `Notas/Reporte Codex etapa 8.md`, sección «Ronda 4», separando implementado / comprobado / pendiente de Studio, y actualizado después de cada tarea.

## Archivos exclusivos en esta ronda
| Archivo | Para |
|---|---|
| `StarterPlayer/StarterPlayerScripts/HUD.client.lua` | tarea 1 (pasa de Gemini a vos) |
| `StarterPlayer/StarterPlayerScripts/Shop.client.lua` | tarea 1 |
| `StarterPlayer/StarterPlayerScripts/LobbyUI.client.lua` | tarea 1 |
| `ReplicatedFirst/LoadingScreen.client.lua` | tarea 1 |
| `ReplicatedStorage/LocaleGemini.lua` | tarea 1 (solo si hace falta un texto de interfaz) |
| `ServerScriptService/CityProps.lua`, `StarterPlayer/StarterPlayerScripts/CityLife.client.lua` | tareas 2 y 3 (ya eran tuyos) |
| `ServerScriptService/CityNPCs.lua` | tarea 3 (nuevo; el gancho lo agrega Claude) |
| `ReplicatedStorage/LocaleCodex.lua` | textos |

Solo lectura: `UiTheme.lua` y `UiAssets.lua` (usá sus componentes), `LobbyBuilder.lua`, `Controls.client.lua`, `Auras.lua`, `AuraFx.lua`.

## 1. Arreglos de interfaz que vio Claude en Studio
Gemini hizo la interfaz y Claude la probó en Studio. Quedan estos errores:
1. **HUD vertical roto** (`HUD.client.lua`):
   - Abajo a la derecha se ve **una sola columna vacía** (icono rojo y barra oscura) en lugar de las 5: Vida, Resistencia, Guardia, Aturdimiento e Infusión.
   - Aparece también paseando por la ciudad, y no se llenó al golpear a un muñeco.
   - Tiene que verse con las 5 columnas llenas según los atributos del personaje (`Stamina`, `StaminaMax`, `Guard`, `GuardMax`, `Stun`, `InfusionCharge` y la vida del `Humanoid`).
   - Oculto paseando por la ciudad; visible con `InMatch` y al pegar o recibir un golpe en el patio de práctica (atributo `HitAt` o cambio de vida); se desvanece tras 8 s sin combate.
2. **Vista previa de auras** (`Shop.client.lua`):
   - Al elegir un aura la cámara se mueve pero **el personaje no aparece** en la zona libre de la derecha (se ve la calle vacía).
   - El recuadro todavía dice «Vista en vivo sobre el pedestal».
   - Encuadrá al personaje local de frente, en la mitad derecha de la pantalla (cámara `Scriptable` mirando al personaje desde delante y algo arriba, con giro lento), y sacá ese texto o recuadro.
   - Al cerrar o cambiar de pestaña, cámara y aura vuelven a lo normal.
3. **Botón RANKED** (`LobbyUI.client.lua`): en la barra de partida dice «Clasificatorias» y la etiqueta «Próximamente» se ve como un rectángulo negro vacío. Tiene que decir **RANKED** y la etiqueta tiene que leerse.
4. **Precarga** (`LoadingScreen.client.lua`):
   - La Salida se llena de «ContentId rbxassetid://… failed due to: Asset type does not match requested type».
   - Precargá los sonidos con instancias `Sound` (con su `SoundId`) y las imágenes con `ImageLabel`/`Decal`, no como IDs sueltos.
   - Los IDs de animación no se precargan.
5. **Botón Armería** del dock izquierdo (`LobbyUI.client.lua`): con un clic no abrió la tienda (con el evento `ToggleMenu` del jugador sí abre). Que los 4 botones del dock abran su panel con ratón, toque y mando.

## 2. Caminos de la ciudad (pedido del usuario: «agregá caminos»)
En `CityProps.lua`: caminos de losas irregulares de piedra que recorran la calle principal, la calle cruzada y la plaza con curvas suaves y bordes de pasto, más canteros con flores.
- Unen la entrada, el santuario del punto de aparición, la plaza, la taberna, el patio de práctica y la gran puerta.
- Se apoyan sobre el piso (`ctx.floorTop` para la plaza; el resto de las calles termina a 0,05 + capa × 0,06 sobre `ctx.origin`, con capa 0 para la calle principal y 1 para la cruzada).
- Las losas no colisionan (o son muy finas), no tapan los círculos de cola ni la armería, y no hay caras superpuestas en el mismo plano.
- Presupuesto total de `CityProps`: ≤ 1.400 piezas.

## 3. Más vida en el lobby
1. **Pueblerinos** (`CityNPCs.lua`, servidor):
   - Entre 4 y 6 personajes R15 sencillos (capa, capucha o delantal con piezas) que caminan despacio entre puntos de la ciudad, se detienen frente a la taberna y la fuente, y vuelven.
   - Con `Humanoid:MoveTo`, sin colisión con los jugadores (grupo de colisión propio) y sin poder ser atacados ni fijados: **sin** la etiqueta `Combatant`.
   - Exponé `CityNPCs.start(cityFolder, ctx)`; Claude lo conecta desde `LobbyBuilder`.
2. **En `CityLife.client.lua`**: murciélagos o cuervos que vuelan a lo lejos, banderines que ondean y algún gato que cruza (opcional).
   - Solo cerca del jugador y fuera de `InMatch`, igual que ahora.
