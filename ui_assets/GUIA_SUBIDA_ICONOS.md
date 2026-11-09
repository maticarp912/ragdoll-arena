# Guía de Subida de Iconos (`ui_assets/` → `ReplicatedStorage/UiAssets.lua`)

Esta carpeta contiene los **19 iconos de interfaz** en formato `.svg` (vectorial editable) y `.png` (256×256 px con fondo transparente y medallón dark fantasy) listos para subir a Roblox Studio.

> **Importante**: Mientras el ID en `ReplicatedStorage/UiAssets.lua` sea `0` (valor por defecto para cumplir con la regla de no inventar `rbxassetid`), `UiAssets.icon()` dibuja automáticamente el **fallback vectorial por capas de Frames** (medallones multi-capa con llamas, rayos, cristales, eclipses, coronas, trofeos y escudos). Por lo tanto, la interfaz ya luce completa en Studio aun antes de subir los PNG.

## Catálogo de iconos

| Clave en `UiAssets.Ids` | Archivo `.png` / `.svg` | Uso principal en UI |
| :--- | :--- | :--- |
| `infusion_fire` | `infusion_fire.png` / `.svg` | Medallón rework de Infusión **Fuego** (Tienda + HUD) |
| `infusion_lightning` | `infusion_lightning.png` / `.svg` | Medallón rework de Infusión **Rayo** (Tienda + HUD) |
| `infusion_ice` | `infusion_ice.png` / `.svg` | Medallón rework de Infusión **Hielo** (Tienda + HUD) |
| `infusion_shadow` | `infusion_shadow.png` / `.svg` | Medallón rework de Infusión **Sombra** (Tienda + HUD) |
| `coin` | `coin.png` / `.svg` | Moneda del juego (Tienda, Misiones, Resumen de partida) |
| `robux` | `robux.png` / `.svg` | Moneda Robux (Tienda) |
| `rarity_common` | `rarity_common.png` / `.svg` | Emblema de rareza Común |
| `rarity_rare` | `rarity_rare.png` / `.svg` | Emblema de rareza Rara |
| `rarity_epic` | `rarity_epic.png` / `.svg` | Emblema de rareza Épica |
| `rarity_legendary` | `rarity_legendary.png` / `.svg` | Emblema de rareza Legendaria |
| `rarity_mythic` | `rarity_mythic.png` / `.svg` | Emblema de rareza Mítica |
| `mission` | `mission.png` / `.svg` | Botón y cabecera de Misiones Diarias (LobbyUI) |
| `trophy` | `trophy.png` / `.svg` | Botón y cabecera de Clasificación / Victorias |
| `skull` | `skull.png` / `.svg` | Icono de bajas (KillFeed, Clasificación, MatchUI) |
| `knockdown` | `knockdown.png` / `.svg` | Icono de derribos (Clasificación, MatchUI) |
| `settings` | `settings.png` / `.svg` | Botón de Ajustes |
| `armory` | `armory.png` / `.svg` | Botón de Armería / Armas |
| `aura` | `aura.png` / `.svg` | Pestaña de Auras (Tienda) |
| `ranked` | `ranked.png` / `.svg` | Pestaña y modal de Competitivo / Ranked |

## Pasos para subir en Roblox Studio

1. Abrí el proyecto en **Roblox Studio**.
2. Abrí **View → Asset Manager → Images** y hacé clic en **Bulk Import**.
3. Seleccioná los 19 archivos `.png` de `ui_assets/`.
4. Una vez subidos, hacé clic derecho sobre cada imagen en **Asset Manager → Images** y elegí **Copy ID to Clipboard**.
5. Abrí `ReplicatedStorage/UiAssets.lua` y reemplazá el `0` en `UiAssets.Ids.<clave>` por el número de ID copiado:
   ```lua
   UiAssets.Ids = {
       infusion_fire = 1234567890,
       infusion_lightning = 1234567891,
       -- ...
   }
   ```
6. Al ser distinto de `0`, `UiAssets.icon()` usará automáticamente la `ImageLabel` con tu PNG subido en lugar del icono procedural.
