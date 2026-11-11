# Glow-up y monetización — Codex

> **Modelo: gpt-6.1-sol, high (o muy alto).** Para pegar en el chat de Codex con permiso para editar archivos. Escrito por Claude el 11/11/2026. Plan completo: [[Plan glow-up y monetización]].

---
Sos el responsable de backend y, mientras Gemini no tenga cuota, de la interfaz de «Ragdoll Arena» (`F:\RobloxJuegos\Plataforme 2v2`).

**Leé primero:**
- `Notas/Indicaciones para las IA.md`;
- `Notas/Plan glow-up y monetización.md` (secciones 2, 4 y 5);
- `ReplicatedStorage/MonetizationConfig.lua`, `ServerScriptService/MonetizationManager.lua`, `ServerScriptService/MonetizationService.server.lua` y `ReplicatedStorage/Device.lua` (los hizo Claude: usalos, no los reescribas);
- en `UiTheme.lua`, la paleta «Eclipse» y la escala de texto nuevas.

**Regla fija:** nada que se venda puede dar ventaja en combate.

**Tareas:**
1. **Suerte de cofres** (`Rewards.lua`, `RewardService.lua`):
   - `Rewards.Luck` aplica `data.Boosts.Luck` y `LuckSeconds` a los pesos de Épica y Legendaria de todas las cajas (no a la ruleta).
   - El tiempo corre en tiempo real y se descuenta al leer.
   - `GetState` devuelve las probabilidades con la suerte aplicada y también las de base, para mostrar el antes y el después.
   - Sanear `Luck` y `LuckSeconds` en `R.reconcile`.
2. **VIP** (`Pass_VIP` o `Manager.ownsPass`):
   - +20 % de almas ganadas jugando (no en compras ni regalos);
   - 1 tiro gratis extra por día en `RewardService`;
   - rol VIP automático en `RoleService` (sin pisar Owner, Admin ni Mod);
   - aura `VipCrown`: entrada en `Auras.lua` con un patrón existente, que solo se puede equipar con el pase.
3. **Skip y apertura lenta** (`Rewards.client.lua`):
   - subir las duraciones de `REVEAL`: cofre que tiembla y se abre, tira más larga, de 5 a 7 s en total;
   - el Skip (Enter, A o tocar) solo funciona si el jugador tiene el atributo `Pass_SkipOpening`;
   - si no lo tiene, mostrar «Saltar» chico con candado que abre la tarjeta del pase (`Monetization` → `Prompt "SkipOpening"`).
4. **Cofres del 1 al 6** (`Rewards.client.lua`):
   - grilla de 3 × 2 en PC y lista en celular, con el orden de `Rewards.BoxOrder`;
   - cada nivel más grande y brillante: hierro, plata, verdín, violeta, oro y carmesí con relámpagos;
   - los valores de cada nivel van en una tabla `CHEST_TIERS` al principio del archivo;
   - hasta que llegue el arte, usar íconos y marcos de color, preparados para reemplazar por un ImageId de cada cofre.
5. **Bóveda** (`Shop.client.lua`, ahora también tuyo):
   - pestaña «Bóveda» que lee `Monetization` → `Catalog`: pases arriba, paquetes abajo, etiquetas «Popular» y «Mejor valor», ícono de Robux y precio real;
   - las ofertas no disponibles no se muestran;
   - si `restricted`, nada de azar pago.
   - Saldo de almas con un «+» chico en el encabezado de la tienda y de las recompensas.
   - Cuando falten almas para un cofre o una skin: «Te faltan N almas · Conseguir almas» en vez del error.
   - Sacar la pestaña vieja de prueba «Almas» de la vista normal (sigue para depuración).
6. **Barrido de interfaz** (todos los `.client.lua` de interfaz):
   - pistas de teclado, táctil o mando con `Device.showFor`, no con `UIS.GamepadEnabled`;
   - colores puestos a mano → tokens de `UiTheme.Colors`;
   - revisar textos cortados con la escala nueva (sobre todo a 375 px).
   - No toques `Controls.client.lua`, `Animator.client.lua` ni el combate.
7. **Textos** `mz.*` en `LocaleCodex.lua` (ES, EN y PT-BR), para pases, productos, Bóveda, candado de Skip y «Te faltan N almas».
8. **Revisá** `MonetizationManager` y `PlayerData.processReceiptWith`. Si encontrás un error, arreglalo y explicalo.

**Además (evaluación de Fable 5.2, ver la sección 3b del plan):**
- cuando la suerte funcione de punta a punta, poné `enabled = true` en `Luck30`;
- el tiro extra del VIP es azar pago: si `Manager.paidRandomAllowed` es false, dar almas fijas en su lugar;
- mostrar la conversión de repetidas (40 %) junto a las probabilidades.

**Reglas:**
- No abras Studio ni publiques.
- No toques los IDs de `MonetizationConfig` (los pone el usuario).
- Nada de `git commit`, `checkout`, `reset`, `stash` ni `push`.
- Al terminar: `node tools/check_lua.js .` sin errores, LihFolk en 0, y una sección «Glow-up y monetización» en `Notas/Reporte 0.2 Codex.md` que separe lo hecho, lo probado fuera de Studio, lo que necesita Studio y las preguntas para el usuario.
