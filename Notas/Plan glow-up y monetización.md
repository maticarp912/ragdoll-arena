# Plan: glow-up visual y monetización (11/11/2026)

Pedido del usuario (prompt armado con Gemini Pro, más dos complementos): acabado propio y limpio, tipografía y paleta nuevas, adaptación a PC, celular y consola, arreglo de la cámara de auras, cofres estilo Clash Royale del 1 al 6 con apertura lenta y Skip pago (200 R$), y un sistema completo de compras con Robux.
**Cambio del usuario:** la vida base **no** se toca (cada arma conserva la suya).
Estado: ✅ hecho y comprobado · 🔍 hecho, falta probar en Studio · 🔧 Codex · ⬜ pendiente · 👤 usuario.

## 1. Lo que ya hizo Claude (11/11, sin probar en Studio)
| Parte | Archivo | Estado |
|---|---|---|
| Cámara de la vista previa de auras: gira despacio alrededor del personaje hasta «Salir de la vista previa» (o Esc / B). Siempre vuelve a `Custom` siguiendo a tu Humanoid. El bloqueo pasaba al tocar «Probar» dos veces: se guardaba la cámara de la vista previa como si fuera la normal. | `Shop.client.lua` | 🔍 |
| Detección de dispositivo: `Device.platform()` (PC, Mobile, Console), `Device.input()` (Keyboard, Touch, Gamepad), `Device.Changed` y `Device.showFor(obj, modo)`. Usa `PreferredInput` y `ViewportDisplaySize` (las API de 2026) y publica los atributos `Platform` e `InputMode`. Las pistas «A: Seleccionar · B: Volver» de la tienda, la armería y las recompensas ya solo aparecen con mando. | `ReplicatedStorage/Device.lua` | 🔍 |
| Paleta «Eclipse»: obsidiana violácea, carmesí del Eclipse como acento de marca, marfil para el texto, verdín espectral para el foco del mando. El oro queda solo para el dinero y la rareza Legendaria. Se cambiaron los tokens de `UiTheme.Colors`, las rarezas y los botones; los nombres viejos (`Gold`...) siguen funcionando. | `UiTheme.lua` | 🔍 |
| Textos más grandes: XS 11 → 13, SM 13 → 15, MD 15 → 17, LG 18 → 20, XL 22 → 24, XXL 28 → 30. Tipografías: títulos Grenze Gotisch, textos Merriweather y números Builder Sans. | `UiTheme.lua` | 🔍 hay que revisar textos cortados |
| Sexto cofre «del Eclipse» (20.000 almas, siempre Legendaria: de Tormenta o del Eclipse). Cada skin pertenece a un grupo (`Shop`, `Roulette` o `Storm`) y cada caja elige sus grupos (`pools`). | `Rewards.lua`, `RewardService.lua` | 🔍 |
| Módulo central de pagos (ver sección 3). | `MonetizationConfig.lua`, `MonetizationManager.lua`, `MonetizationService.server.lua`, `PlayerData.processReceiptWith` | 🔍 |

## 2. Monetización: propuesta
Regla de oro: **nada que se venda da ventaja en combate.** Solo cosméticos, comodidad y velocidad de progreso. El PvP queda justo.

| Oferta | Tipo | Precio sugerido | Qué da |
|---|---|---|---|
| Skip de aperturas | Pase | 200 R$ (pedido) | Saltar la animación de cofres y ruleta para siempre |
| VIP del Eclipse | Pase | 399 R$ | +20 % de almas por partida, 1 tiro gratis extra por día, etiqueta VIP, aura exclusiva «Corona VIP» |
| Almas 500 / 1.200 / 3.500 / 8.000 | Producto | 49 / 99 / 249 / 499 R$ | Almas (los paquetes grandes rinden más) |
| 3 tiros de ruleta | Producto | 49 R$ | Tiros |
| Amuleto de la suerte (30 min) | Producto | 79 R$ | Épica y Legendaria ×2 en los cofres, mostrando el antes y el después con números |
| Auras premium | Producto | 149 a 299 R$ | Auras exclusivas (campo `productId` de `Auras.lua`, ya existe) |

**Normas de Roblox:** si las almas se venden con Robux, los cofres pasan a ser «premios al azar pagos». Por eso:
- las probabilidades se muestran siempre, y con la suerte se muestran las nuevas;
- a quien Roblox le restringe el azar pago (`PolicyService`), o si la consulta falla, no se le ofrecen almas, tiros ni suerte;
- el Skip no cambia las probabilidades.

## 3. Módulo central de pagos (MonetizationManager)
- **Datos:** `ReplicatedStorage/MonetizationConfig.lua` lista pases y productos. Con `id = 0` la oferta no aparece. Los IDs los pega 👤 desde Creator Hub.
- **Recibos:** `MarketplaceService.ProcessReceipt` está solo en el Manager (Roblox permite uno; se sacó de ShopService). Cada tipo (`Souls`, `Spins`, `Luck`, `Aura`, `Skin`) tiene su función con `registerKind`. Las auras y skins con `productId` se registran solas.
  - `PlayerData.processReceiptWith` aplica la compra a una copia, la guarda con el PurchaseId y recién ahí la aplica al perfil. Si no se pudo guardar, Roblox reintenta. Un recibo repetido no vuelve a dar nada.
- **Pases:** `UserOwnsGamePassAsync` con 3 intentos. Si falla, no se marca «no lo tiene» y se vuelve a consultar a los 30 s. Al comprar se confirma con Roblox. Se publica `Pass_SkipOpening` y `Pass_VIP` en el jugador. Para probar en Studio: `workspace:SetAttribute("StudioGrantPasses", true)`.
- **Remoto `Monetization`:**
  - `Catalog` devuelve precios reales (`GetProductInfo`), qué tenés y qué está disponible para vos;
  - `Prompt` pide la compra. El servidor decide y respeta las políticas.
- **Ojo:** las compras reales solo se pueden probar en el juego publicado (en Studio no hay DataStore y el recibo no se guarda).

## 3b. Evaluación de Fable 5.2 (11/11)
Revisó la monetización en modo solo lectura. Lo que encontró, y qué se hizo:
- ✅ Arreglado por Claude:
  - el pase se concedía si llegaba la señal de compra aunque Roblox no la confirmara (un cliente con trampas la puede falsificar). Ahora se confirma con reintentos (2, 4, 8, 15 y 30 s);
  - se podía cobrar con los tiros o la suerte ya en el tope. Ahora la compra se bloquea antes (`canBuy` por tipo);
  - si fallaba aplicar la compra en memoria, el próximo guardado la borraba. Ahora se usa la copia guardada;
  - las políticas no se reintentaban tras un fallo; ahora sí;
  - los precios fallidos quedaban en caché para siempre; ahora se reintentan al minuto;
  - `ownsPass` devolvía nil en vez de false;
  - prueba de compras en Studio: acción `StudioTest` del remoto, solo en Studio.
- ✅ Suerte (Luck30) apagada (`enabled = false`) hasta que Codex la implemente: no se vende algo que todavía no hace nada.
- ✅ Paquetes de almas: 600 / 1.400 / 4.000 / 9.000 y uno nuevo de 20.000 por 999 R$ (rinden más cuanto más grandes; el último alcanza para el cofre 6).
- 🔧 Codex: el tiro extra del VIP es azar pago (para jugadores restringidos, darles almas fijas en su lugar); mostrar la conversión de repetidas al 40 % junto a las probabilidades.
- 👤 Decidir: para buscar Legendaria, el Relicario del Rayo (12.000, 38 %) sale peor que el Cofre del Eclipse (20.000, 100 %). Opciones: bajar el Relicario a ~9.000 y el Eclipse a ~15.000, o dejarlo así porque el Relicario da muchas Épicas.
- 👤 Al publicar: declarar en el cuestionario de la experiencia que hay premios al azar comprables.

## 4. Integración en la interfaz (limpia, sin botones gigantes de COMPRAR)
- **Una sola puerta:** pestaña «Bóveda» en la tienda, con pases arriba (tarjetas grandes con sus ventajas) y paquetes abajo (tarjetas chicas, con la etiqueta «Popular» o «Mejor valor»).
- **Saldo de almas** en el encabezado (tienda, cofres, ruleta) con un «+» chico que abre los paquetes.
- **Ofertas en contexto:** cuando no te alcanzan las almas para un cofre o una skin, en vez de un error aparece «Te faltan N almas · Conseguir almas».
- **Skip:** durante la apertura, quien no tiene el pase ve un «Saltar» chico con candado; al tocarlo, aparece la tarjeta del pase. Quien lo tiene, salta.
- **VIP:** corona junto al nombre y beneficios en la Bóveda.
- **Suerte activa:** una ficha con el tiempo que queda («Suerte ×2 · 24:31») y la tabla de probabilidades con el antes y el después.
- **Al entrar:** nada de ventanas de oferta. Como mucho una tarjeta rotativa en el lobby.
- **Botones de compra:** botón principal carmesí con el ícono de Robux; el oro solo para las almas.

## 5. Cofres estilo Clash Royale (del 1 al 6)
Orden: 1 Almas (500) · 2 Reliquia (1.500) · 3 Cofre de la Tormenta (3.000) · 4 Arca de la Tormenta (6.500) · 5 Relicario del Rayo (12.000) · 6 Cofre del Eclipse (20.000).
- Grilla de 3 × 2.
- Cada nivel es más grande y brilla más: hierro → plata → verdín → violeta → oro → carmesí con relámpagos.
- Apertura lenta a propósito: el cofre tiembla, se abre, pasa la tira y se revela el premio (5 a 7 s), con Skip solo con el pase.
- Arte de los cofres: 👤 ver sección 7. Hasta que llegue, Codex usa íconos y marcos de color.

## 6. Reparto
**Claude (hecho, sección 1):** arquitectura de pagos y políticas, `Device`, paleta y escala de texto, cámara, datos de los cofres.

**Codex** ([[Glow-up y monetización - Codex]]):
1. Suerte de cofres en `RewardService`, con las probabilidades nuevas en `GetState`.
2. Ventajas VIP: almas +20 %, tiro extra, rol VIP y aura.
3. Skip con pase y apertura lenta en `Rewards.client`.
4. Cofres 1 a 6 en grilla.
5. Pestaña «Bóveda», saldo con «+» y ofertas en contexto.
6. Barrido de `Device.showFor` y de los colores sueltos en toda la interfaz, y textos cortados.
7. Textos `mz.*` en tres idiomas.
8. Pruebas fuera de Studio.

**👤 Usuario:**
- crear los pases y productos en Creator Hub y pegar sus IDs en `MonetizationConfig.lua`;
- decidir los precios;
- traer las referencias de la sección 7;
- probar las compras en el juego publicado con una cuenta de prueba.

## 7. Referencias que necesito del usuario
1. **Arte de los 6 cofres:** cerrado y abierto, de frente, fondo transparente (PNG 512 × 512), del más pobre al más rico. Puede ser de un generador de imágenes o comprado. Es lo que más cambia la sensación «Clash Royale».
2. **Íconos:** alma (moneda), corona VIP, rayo de Skip, trébol o amuleto de suerte, candado. PNG 256 × 256, con un solo estilo para todos.
3. **Marcos de panel:** una imagen de 9 cortes (borde de obsidiana con filo carmesí) para paneles y tarjetas. Es lo que más saca el «acabado IA».
4. **Dos o tres capturas de juegos cuya interfaz te guste** (por ejemplo, la tienda de Clash Royale o el menú de Elden Ring): sirven para la composición, no para copiar.
5. Si querés otras fuentes: el nombre o una captura. Las de Roblox que seguro existen son Builder Sans, Montserrat, Grenze Gotisch y Merriweather (las dos últimas se vieron funcionando en tu captura).

Las imágenes se suben en Creator Hub → Imágenes, y se pasan los IDs (o se dejan en `referencias/`).
