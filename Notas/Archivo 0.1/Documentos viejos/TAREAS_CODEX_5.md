# Tarea para Codex — Lote 5: terminar HUD, tienda e idiomas

> **YA HECHO POR CLAUDE (9/11/2026). No se lo des a Codex.** El HUD, la tienda y los idiomas se revisaron y completaron en el lote 6. Ver `Notas/Registro de cambios.md`.

Proyecto Roblox (Luau) en `F:\RobloxJuegos\Plataforme 2v2`. **Trabaja directamente en esta carpeta**, no en una copia: la vez anterior trabajaste en `OneDrive\Documentos\ChatGPT\plataforma roblox\lote4` y Claude tuvo que integrarlo a mano. Responde en español rioplatense.

Lee primero: `Notas/Estado.md`, `Notas/Pendientes.md`, `Notas/Decisiones.md`, `Notas/Catálogo de skins.md` y `TAREAS_CODEX_4.md`, que es la tarea anterior y sigue vigente en lo no terminado.

## Estado de tu lote 4 (ya integrado en el proyecto)
- Integrado: `Localization`, `LocaleES/EN/PT`, `Skins` (32 skins: 8 con modelo de piezas y 24 «modelo por crear»), `WeaponBuilder`, `Theme`, `PlayerData` (idioma), `ShopService`, `Shop.client`, `Settings.client`, `HUD.client`, `Overhead.client`.
- **Sin terminar**: el HUD no tiene el escudo que se agrieta, las estrellas de Stun, los cráneos de Sombra, los varios rayos de Rayo ni un icono de stamina distinto del Rayo. Tampoco hay `REVISION_CODEX_4.md`.
- Nada se probó en Studio.

## Archivos que PUEDES tocar
`HUD.client.lua`, `Overhead.client.lua`, `Shop.client.lua`, `Settings.client.lua`, `ShopService.server.lua`, `Skins.lua`, `WeaponBuilder.lua` (solo diseños de skins; no cambies `WeaponBuilder.Info`), `Localization.lua`, `LocaleES/EN/PT.lua`, `PlayerData.lua` (solo idioma).
En `Theme.lua` solo las partes de UI y tienda (`Theme.Armory`, `Theme.ShopStyle`, colores de UI). **No toques** `Theme.Lighting`, `Theme.Ambience`, `Theme.Arena` ni `Theme.Lobby`.

## Archivos de Claude (NO los toques)
`Combat`, `CombatConfig`, `Actions`, `Infusion`, `Infusions`, `WeaponData`, `Controls.client`, `Animator.client`, `AnimClips`, `MatchService`, `CombatService`, `Fx`, `Vfx.client`, `Infusion.client`, `Atmosphere.client`, `Debug.client`, `Dummies`, `Ragdoll`, `LobbyBuilder`, `CityConfig`, `ArenaBuilder`, `ArenaConfig`, `Environment`.

## Qué hacer
1. **HUD vertical derecho completo** (punto 2 de `TAREAS_CODEX_4.md`):
   - Escudo que se agrieta por tramos, se rompe con `GuardBroken` y se recompone al regenerarse.
   - Estrellas de aturdimiento para el Stun.
   - Icono de stamina distinto del Rayo, por ejemplo una bota o tres chevrons.
   - Icono por infusión: llama, varios rayos, cristal y cráneos, con carga, tiempo activo y agotamiento.
   - Sin tapar el combate.
2. **Tienda** (punto 1): completa lo que falte de la especificación.
   - Vista grande con rotación manual y zoom limitado.
   - Filtros por rareza, adquiridas y disponibles.
   - Diálogo de confirmación de compra.
   - Efecto al comprar.
   - Las tarjetas fuera de pantalla no animan.
   - Mando y táctil.
   - Diseña más modelos de skins a partir de las imágenes, empezando por la Espada.
3. **Idiomas**: revisa que todo lo tuyo (tienda, HUD, ajustes, overhead) use `Localization.t` y se vea bien en ES, EN y PT-BR, sin recortes.
4. Mantén el bloqueo de arma e infusión en partida.

## Al terminar
1. `node tools/check_lua.js .` sin errores y `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`.
2. Escribe `REVISION_CODEX_5.md` separando **implementado**, **comprobado en Studio** y **pendiente de probar**.
3. Actualiza `Notas/Estado.md` y `Notas/Registro de cambios.md` solo en tus apartados.
