# Almas, monedas, títulos y party — Codex

> **Modelo: gpt-6.1-sol, high o muy alto.** Para pegar en Codex con permiso para editar. Escrito por Claude el 11/11/2026.
> Claude ya hizo: títulos (`ReplicatedStorage/Titles.lua`, `ServerScriptService/TitleService.server.lua`), tarjeta estilo Call of Duty (`CallingCard.client.lua`), nombre y rangos sobre la cabeza (`Overhead.client.lua`), party de 2 (`PartyService.lua`, `PartyUI.client.lua`, cola en `MatchService`). No los reescribas: usalos.

---
Sos el responsable de backend y de la interfaz de «Ragdoll Arena» (`F:\RobloxJuegos\Plataforme 2v2`).

**Leé primero:**
- `Notas/Indicaciones para las IA.md`;
- `Notas/Plan glow-up y monetización.md`;
- tu sección «Glow-up y monetización» en `Notas/Reporte 0.2 Codex.md`;
- `Titles.lua`, `TitleService.server.lua` y `PartyService.lua`.

**Pedido del usuario (resumen fiel):** dos monedas distintas.
- **Almas:** se ganan jugando y sirven para algunas cosas.
- **Monedas:** se compran con Robux o se consiguen de forma muy limitada.

**Regla fija:** nada que se venda da ventaja en combate.

**Tareas:**
1. **Dos monedas.**
   - **Almas** = el saldo actual (`data.Coins`, no lo renombres ni lo migres).
   - **Monedas** = campo nuevo `data.Gems` (en pantalla «Monedas», con un ícono propio), saneado en `R.reconcile`. Se publica en un atributo y en `leaderstats` si conviene.
2. **Para qué sirven las almas:**
   - tirar la ruleta 2 veces más por día (hoy son 3 pagos; dejá 2);
   - abrir los 2 cofres más baratos (cofre 1 y cofre 2);
   - renacer la maestría de un arma (punto 6);
   - comprar títulos de tienda (`TitleService` → `Buy` ya cobra `data.Coins`);
   - los multiplicadores que ya existen.
3. **Cómo se consiguen las monedas:**
   - **Robux:** los paquetes de `MonetizationConfig` pasan a ser de monedas. Sugerencia: 49 → 400, 99 → 850, 249 → 2.200, 499 → 4.600, 999 → 10.000. Agregá un tipo `Gems` en `MonetizationService`.
   - **Ruleta:** muy poco (un sector chico).
   - **Tutorial:** 200 monedas al completarlo.
   - **Misiones:** unas pocas por misión, para que en una o dos semanas se pueda comprar una skin decente de cada arma. Las almas que dan hoy se mantienen.
4. **Skins.**
   - De cada arma, 1 o 2 skins decentes a 1.200–2.000 monedas.
   - Algunas skins de lujo a 10.000, 12.000 y 15.000 monedas.
   - El resto se vende con Robux: `productId` en `Skins.lua`, campo `currency = "Robux"`; `MonetizationService` ya registra skins con `productId`.
   - Las de ruleta y Tormenta no cambian.
   - Proponé en el reporte la tabla completa de precios por skin, para que la apruebe el usuario.
5. **Cofres.**
   - Cofres 1 y 2 con almas, sin skin asegurada:
     - **cofre 1:** 10 % de skin;
     - **cofre 2:** 17 % de skin;
     - el resto: pocas monedas, multiplicadores de XP y almas.
   - Cofres 3 a 6 con monedas. Sugerencia: 600, 1.300, 2.400 y 4.000. Mantienen sus rarezas actuales.
   - Las probabilidades siempre visibles, con la suerte y la conversión de repetidas.
   - Azar pago: los cofres 3 a 6 se pagan con una moneda que se compra con Robux. Si `paidRandomAllowed` es false, ocultá o bloqueá los paquetes de monedas y esos cofres. Los cofres 1 y 2 con almas siguen como camino gratis.
6. **Renacer maestría.**
   - Con maestría 20 en un arma, pagar almas para volver a 1 y sumar un «renacimiento». El precio sube con cada renacimiento.
   - Cada renacimiento da una estrella visible en la armería y el título de esa maestría con número romano en la tarjeta (por ejemplo «Maestro de la Espada II»: agregá los títulos que hagan falta en `Titles.lua`, con el mismo formato).
   - No da poder.
7. **Bonus de amigos.** Si hay un amigo de Roblox tuyo en el mismo servidor (`Player:IsFriendsWith`, con caché), +20 % de XP y +20 % de almas ganadas jugando. No aplica a monedas ni a compras. Mostralo en el HUD del lobby y en el resumen de la partida.
8. **Estadísticas para los títulos.**
   - En `StatsService`, contar en `data.Stats` lo que falta: `Parries`, `RingOuts`, `Kicks`, `GuardBreaks`, `Finishers`, `Throws` (eventos de `CombatEvents`; el remate llega con `info.finisher` en el golpe). `Kills`, `Knockdowns`, `Wins` y `Matches` ya existen.
   - Los títulos por estadística se desbloquean solos en `TitleService`.
   - Conceder los logros de `Titles.lua` con `source = "achievement"` (`Undying`, `Collector`, `Duelist`, `BondedBlades`) en `data.Titles[id] = true`, con su aviso.
9. **Pestaña «Títulos»** en la armería (remoto `Titles`):
   - lista por categoría, con el texto del título (`Titles.text`), la rareza, el progreso (por ejemplo 340 / 1.000 eliminaciones), el precio en almas, comprar y equipar;
   - vista previa de la tarjeta.
   - Al desbloquear uno, aviso corto con la tarjeta.
10. **Textos** `mz.*` y los que falten, en ES, EN y PT-BR (`LocaleCodex.lua`).

**Archivos que podés tocar:** `Rewards.lua`, `RewardService.lua`, `Rewards.client.lua`, `Shop.client.lua`, `Armory.client.lua`, `PlayerData.lua`, `ProgressionService.lua`, `StatsService.lua`, `MissionService.lua`, `Missions.lua`, `MonetizationConfig.lua` (no cambies los IDs), `MonetizationService.server.lua`, `Skins.lua` (solo precio, moneda y `productId`), `Titles.lua` (agregar títulos), `TitleService.server.lua`, `LocaleCodex.lua`, `Economy.lua`, `HUD.client.lua`, `MatchUI.client.lua`.

**No toques:** el combate (`Combat`, `Actions`, `CombatConfig`, `WeaponData`, `AnimClips`, `Animator`, `Controls`), `PartyService.lua`, `PartyUI.client.lua`, `CallingCard.client.lua` ni `Overhead.client.lua`. Si ves algo mal ahí, anotalo para Claude.

**Reglas:**
- No abras Studio ni publiques.
- Nada de `git commit`, `checkout`, `reset`, `stash` ni `push`.
- Al terminar: `node tools/check_lua.js .` sin errores, LihFolk en 0, y una sección «Almas, monedas y títulos» en `Notas/Reporte 0.2 Codex.md` que separe lo hecho, lo probado fuera de Studio, lo que necesita Studio y las preguntas para el usuario (incluida la tabla de precios de skins).
