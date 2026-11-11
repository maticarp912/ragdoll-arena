# Arte: lista de imágenes del juego (11/11/2026)

Para cambiar todos los íconos e imágenes. **El nombre del archivo tiene que ser exactamente el de la columna «Archivo»**: así, cuando las subas, Claude pega cada ID en su lugar sin adivinar.
Las armas y skins no llevan imagen: se muestran en 3D.

## Ya hechas y conectadas ✅
Alma, moneda, amuleto, candado, Skip, VIP, marco de obsidiana, 5 paquetes de monedas, paquete de 3 tiros, 2 pases y los 6 cofres (abierto y cerrado).

## Tipo A — a todo color (como las que ya hiciste)
PNG de **256 × 256**, fondo transparente, mismo estilo que `icono_alma` y `icono_moneda`. El juego no las tiñe.

| Archivo | Dónde aparece | Idea |
|---|---|---|
| `infusion_fire` | Armería, previa, botón táctil | Llama carmesí y naranja sobre runa |
| `infusion_lightning` | idem | Rayo blanco azulado |
| `infusion_ice` | idem | Cristal de escarcha celeste |
| `infusion_shadow` | idem | Humo violeta con ojo o media luna |
| `aura_crown` | Tienda y armería (auras) | Corona de ceniza flotante |
| `aura_chains` | idem | Cadenas espectrales celestes |
| `aura_wings` | idem | Alas de humo violeta |
| `aura_mist` | idem | Niebla verde a los pies |
| `aura_eyes` | idem | Ojos rojos que miran |
| `aura_runes` | idem | Runas doradas girando |
| `aura_drip` | idem | Hoja que gotea violeta |
| `aura_embers` | idem | Brasas negras y naranjas |
| `aura_blood` | idem | Gotas de sangre en la hoja |
| `aura_fracture` | idem | Hoja agrietada con luz blanca |
| `boost_souls` | Tienda (multiplicadores) | Alma con «×2» |
| `boost_xp` | idem | Pergamino o libro con «×2» |
| `boost_magnet` | idem | Imán o calavera que atrae almas |
| `rarity_common` | Insignias de rareza | Gema gris hueso |
| `rarity_rare` | idem | Gema cian |
| `rarity_epic` | idem | Gema violeta |
| `rarity_legendary` | idem | Gema dorada |
| `rarity_mythic` | idem (Exclusiva) | Gema carmesí con rayo |

## Tipo B — siluetas blancas
PNG de **128 × 128**, **solo blanco** sobre fondo transparente, sin sombras ni colores: el juego las pinta del color de cada botón. Trazo grueso y simple, que se entienda en chico (celular).

| Archivo | Dónde aparece | Idea |
|---|---|---|
| `armory` | Botón Armería y menú táctil | Espada y escudo cruzados |
| `shop` | Botón Tienda | Bolsa o puesto de mercader |
| `rewards` | Botón Recompensas | Cofre pequeño |
| `settings` | Botón Ajustes | Engranaje |
| `mission` | Botón Misiones | Pergamino con sello |
| `leaderboard` | Botón Clasificación | Podio o copa |
| `health` | HUD | Corazón |
| `stamina` | HUD | Rayo o pulmón |
| `guard` | HUD | Escudo |
| `stun` | HUD | Estrellas o espiral de mareo |
| `knockdown` | HUD | Figura caída |
| `skull` | Eliminaciones | Calavera |
| `attack` | Botón táctil | Espada |
| `heavy` | Botón táctil | Martillo o espada con impacto |
| `block` | Botón táctil | Escudo levantado |
| `dodge` | Botón táctil | Flecha con estela |
| `kick` | Botón táctil | Bota |
| `interact` | Botón táctil | Mano |
| `lockon` | Botón táctil | Mira |
| `switch_target` | Botón táctil | Dos flechas en círculo |
| `trophy` | Varios | Copa |
| `ranked` | Botón RANKED | Escudo con estrella |

**Total: 22 a color + 22 siluetas = 44 imágenes.** El ícono de Robux no se hace: Roblox pide usar el oficial.

## Cómo subirlas
Igual que la vez anterior:
1. Studio → Ver → Administrador de recursos → Importar en bloque.
2. Elegí todas las imágenes de la carpeta.
3. Copiá cada ID y pasáselo a Claude con su nombre de archivo.

Se pueden subir de a tandas. Las que no tengan ID siguen con el ícono de ahora.
Para retirar todo el arte nuevo de una vez: `UiAssets.UseArt = false`.

## Prompt base para generarlas (pegar antes de cada pedido)
Tipo A: «Ícono de videojuego de fantasía oscura, estilo pintado y nítido, sin texto, centrado, fondo totalmente transparente, 256 × 256, paleta obsidiana, carmesí y marfil con brillo del color del elemento, contorno oscuro fino, mismo estilo que [adjuntar icono_alma.png]. Objeto: …»
Tipo B: «Ícono plano de interfaz, silueta blanca pura sobre fondo transparente, sin sombras, sin degradados ni texto, trazo grueso y redondeado, legible a 32 px, 128 × 128. Objeto: …»
