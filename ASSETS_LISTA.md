# Ragdoll Arena — lista de assets (animaciones, sonidos y renders)

> Checklist de todo lo que el usuario prepara. Marca `[x]` cuando esté **subido a Roblox y con su ID anotado**.
> Las **claves** (columna "Clave") son los nombres exactos que usará `Assets.lua`; no las cambies.
> Opus (código) **no espera** a estos assets: usa placeholders y los enchufa cuando le pases los IDs.
> **No hay escudos en el juego**: se bloquea con el arma, por eso la guardia, el golpe bloqueado y el parry son **animaciones por arma**.

## Dirección de arte: dark fantasy
**Tono:** melancólico, brutal y elegante. Ruinas góticas, catedrales derruidas, cielos de ceniza, niebla densa, metal ennegrecido y brasas. **Mundo apagado; color vivo solo en las infusiones y los avisos de combate.**

**Paleta** (referencia; los valores finales viven en `Theme.lua`)
| Uso | Color |
|---|---|
| Fondos / piedra | Negro carbón `#0E0F14`, gris piedra `#2A2D36`, ocre sucio y óxido |
| Paneles de UI | `#1A1C24` con borde dorado envejecido `#B89B5E` |
| Texto | Hueso `#E8E2D0` |
| Fuego | Naranja brasa `#FF6A2B` |
| Rayo | Azul-blanco `#7FD4FF` |
| Sangre | Carmesí `#B3122E` |
| Hielo | Azul pálido `#A8E6FF` |
| Veneno | Verde ácido `#8BE04A` |
| Sombra | Violeta oscuro `#6B3FA0` |
| Barras | Vida rojo oscuro · Stun ámbar · Guardia azul acero |

**Materiales y modelos**
- Acero ennegrecido u oxidado, cuero envejecido, tela raída, grabados y runas. Evita plásticos lisos y colores saturados fuera de las infusiones.
- Armas con silueta muy reconocible (se juega a distancia): cada una distinta de un vistazo.
- Texturas con desgaste, pero **separables** para poder hacer skins.

**Escenarios**
- **Arena 2v2 (grande):** coliseo o catedral abierta en ruinas, suelo de piedra antigua con runas, columnas rotas, cadenas colgando al vacío.
- **Arena 1v1 (pequeña):** plataforma circular de ritual.
- **Alrededor del vacío:** abismo de niebla, brasas ascendentes y ceniza; a lo lejos, un mar de lava o una luna rota.
- **Lobby:** santuario con un brasero central (diseño propio).
- **Baldosas:** piedra vieja; al desmoronarse, grietas con un brillo tenue y polvo oscuro.
- **Iluminación (para configurar en Studio):** poca exposición, `Atmosphere` con niebla densa, `ColorCorrection` desaturado, luces cálidas puntuales (antorchas, brasas), bloom suave, cielo de ceniza.

**Efectos visuales (VFX)**
- Estilizados, no realistas: llamas, arcos, volutas, cristales. La **sangre** son partículas rojo oscuro, sin gore.
- Los **avisos** (naranja = fuerte, rojo = imbloqueable) se distinguen de las infusiones por **forma** (destello/anillo en el arma) y por su **sonido de aviso**, para no confundirse con las llamas del Fuego ni la sangre.

**Interfaz**
- Marcos de piedra o metal envejecido, bordes dorados apagados, iconos grabados.
- Tipografía legible: una serif de aspecto antiguo para títulos y una sans clara para números (fuentes de Roblox como `Antique` o `Garamond`; evita blackletter ilegible).
- Lo crítico en combate (barras, avisos, carga de infusión) debe leerse al instante sobre fondo oscuro.

**Sonido y música**
- Ambiente: viento, campanas lejanas, cuervos, cadenas, crujidos de piedra.
- Música: coros graves, cuerdas oscuras, percusión pesada y órgano; épico y sombrío (nada brillante ni "arcade").
- Efectos: metal pesado y seco, con algo de reverberación de piedra. El **parry** es un choque metálico agudo y claro. Interfaz: golpes de metal/piedra y campanas suaves.

**Personajes**
- Se parte del avatar R15 del jugador. Cosméticos futuros: yelmos, capas y hombreras oscuras. Un acento tenue con el color del equipo (rojo/azul) para distinguirlos.

**Skins de arma** (nombres a juego; hoy hay temporales como "Neón Cyber" que no encajan): Acero Viejo, Obsidiana, Hueso, Oro Ceniciento (monedas) · Runas Etéreas, Linaje Carmesí (Robux).

---

## Resumen de cantidades (Fase 1: 5 armas)
| Bloque | Cantidad aprox. |
|---|---|
| Animaciones | **64** (40 por arma + 24 genéricas) |
| Sonidos | **~170** archivos (con variantes) |
| Modelos 3D | **6** (5 armas, con las Dagas como pareja) |
| Texturas de VFX | **~50** |
| Interfaz (UI) | **~90** elementos |
| Escenarios | **~25** piezas |
| Marketing | **~15** |

---

## 1. Convenciones
**Animaciones**
- Rig **R15 (fijo para todo el juego; no se usa R6)**. Sube las animaciones con tipo de rig R15. Prioridad: ataques, guardia, parry y reacciones = `Action`; reposo = `Idle`.
- Marcadores (`KeyframeMarker`) con estos nombres exactos:
  | Marcador | Dónde | Para qué |
  |---|---|---|
  | `Hit` | En cada golpe (M1, fuerte, patada) | Momento exacto en que se aplica el daño |
  | `WindupEnd` | Ataque fuerte | Fin de la preparación (aquí acaba el telégrafo) |
  | `Release` | Lanzamientos | Instante en que se suelta al rival |
  | `Slap` | Palmada de rescate | Momento del contacto |
- Las animaciones de ataque deben respetar la duración total de abajo (±10%).

**Sonidos**
- `.ogg` o `.mp3`, 44,1 kHz. **Mono** para efectos 3D (golpes, pasos, impactos); **estéreo** para música, ambiente y UI.
- Normalizados (picos ≈ −3 dB). Bucles (`_Loop`) **sin corte audible**.
- Variantes numeradas `_1`, `_2`, `_3` para no sonar repetido.
- Sin música ni efectos con copyright. Al subir a Roblox pueden aplicar límites, costes y moderación: revisa las reglas vigentes.

**Renders**
- Texturas de partículas: PNG con transparencia, 256×256 o 512×512 (flipbooks en cuadrícula 4×4 si se animan).
- Modelos: origen en el agarre, escala en studs, texturas separables (base + color) para poder hacer skins.

---

## 2. Animaciones (R15)

### 2.1 Por arma — 8 por arma × 5 armas = 40
Repetir esta tabla para cada arma: `Sword`, `Greatsword`, `Dagger`, `Rapier`, `Mace`. Claves: `Weapons.<Arma>.<Clave>`.

| Clave | Qué es | Bucle | Marcadores | Prioridad |
|---|---|---|---|---|
| `Idle` | Reposo sosteniendo el arma | Sí | — | P1 |
| `Block` | Pose de guardia **con el arma** (se mantiene) | Sí | — | P1 |
| `BlockHit` | Sacudida corta al recibir un golpe bloqueado | No | — | P1 |
| `Parry` | Desvío rápido con el arma (choque metálico) | No | — | P1 |
| `M1_1` | Golpe 1 del combo | No | `Hit` | P1 |
| `M1_2` | Golpe 2 del combo | No | `Hit` | P1 |
| `M1_3` | Golpe 3 (final, más marcado) | No | `Hit` | P1 |
| `Heavy` | Ataque fuerte con preparación visible | No | `WindupEnd`, `Hit` | P1 |

**Estilo y tiempos por arma**
| Arma | Estilo | Duración de cada golpe (aprox.) | Preparación del fuerte | Notas |
|---|---|---|---|---|
| `Sword` Espada | Cortes fluidos, equilibrados | ~0,45 s | 0,45 s | *Tajo Cruzado* |
| `Greatsword` Espadón | Arcos amplios y lentos, a dos manos | ~0,80 s | 0,75 s | *Tajo Aplastante* vertical |
| `Dagger` Dagas | Dos dagas, golpes rápidos alternando manos | ~0,26 s | 0,30 s | *Doble Estocada* |
| `Rapier` Estoque | Estocadas lineales y precisas | ~0,32 s | 0,40 s | *Puntada Perforante* |
| `Mace` Maza | Golpes contundentes de arriba abajo | ~0,85 s | 0,70 s | *Machaque Pesado* (imbloqueable) |

### 2.2 Genéricas (valen para cualquier arma) — 24
Claves: `Generic.<Clave>`.

| Clave | Qué es | Bucle | Marcadores | Prioridad |
|---|---|---|---|---|
| `DodgeF` / `DodgeB` / `DodgeL` / `DodgeR` | Esquiva (rodillo) adelante / atrás / izquierda / derecha, ~0,4 s | No | — | P1 |
| `Kick` | Patada rompe-guardias | No | `Hit` | P1 |
| `HitReactFront` / `HitReactBack` | Sacudida al recibir daño (de frente / de espaldas) | No | — | P1 |
| `GuardBreakStagger` | Se rompe tu guardia: tambaleo | No | — | P1 |
| `ParriedStagger` | Te han parreado: quedas aturdido | No | — | P1 |
| `StunLoop` | Aturdido (conmoción) | Sí | — | P2 |
| `KnockdownFall` | Caída antes de pasar a ragdoll | No | — | P2 |
| `GetUpFront` / `GetUpBack` | Levantarse (boca abajo / boca arriba) | No | — | P2 |
| `Crawl` | Gatear en derribo crítico | Sí | — | P2 |
| `PickUp` | Alzar a un rival derribado al hombro | No | — | P2 |
| `CarryIdle` | Cargar al rival al hombro (quieto) | Sí | — | P2 |
| `CarryWalk` | Cargar al rival al hombro (andando) | Sí | — | P2 |
| `ThrowShort` | Tirón corto (M1) | No | `Release` | P2 |
| `ThrowFar` | Lanzamiento potente (M2) con carga | No | `Release` | P2 |
| `ReviveChannel` | Levantar a un aliado (canalización de 2 s) | Sí | — | P2 |
| `ReviveSlap` | Palmada rápida para levantar a un aliado | No | `Slap` | P2 |
| `InfuseActivate` | Activar la infusión (el arma se enciende) | No | — | P2 |
| `Victory` / `Defeat` | Fin de ronda/partida | No | — | P3 |

---

## 3. Sonidos (~170)
Patrón de nombres: `Categoria_Detalle_N`.

### 3.1 Ataques y armas (~27)
| Clave | Qué es | Variantes | Prio |
|---|---|---|---|
| `Swing_<Arma>_Light` (×5 armas) | Silbido del golpe normal | 3 | P1 |
| `Swing_<Arma>_Heavy` (×5 armas) | Silbido del ataque fuerte | 2 | P1 |
| `Cue_HeavyWindup` | Aviso sonoro del fuerte (destello naranja) | 1 | P1 |
| `Cue_Unblockable` | Aviso sonoro del imbloqueable (destello rojo) | 1 | P1 |

### 3.2 Impactos y defensa (~26)
| Clave | Qué es | Variantes | Prio |
|---|---|---|---|
| `Hit_Light` | Impacto de golpe normal | 4 | P1 |
| `Hit_Heavy` | Impacto de golpe fuerte | 3 | P1 |
| `Hit_Knockdown` | Impacto que derriba | 2 | P1 |
| `BlockHit_Light` | Golpe bloqueado con el arma (metal) | 3 | P1 |
| `BlockHit_Heavy` | Golpe fuerte bloqueado | 3 | P1 |
| `Parry` | **Choque metálico del parry** (el sonido más importante) | 2 | P1 |
| `ParrySpark` | Capa de chispas del parry | 1 | P1 |
| `GuardBreak` | Rotura de guardia | 2 | P1 |
| `Kick_Swing` / `Kick_Hit` | Patada y su impacto | 1 / 2 | P1 |
| `Dodge` | Esquiva (roce de tela, whoosh) | 3 | P1 |

### 3.3 Derribo, agarre y rescate (~18)
| Clave | Qué es | Variantes | Prio |
|---|---|---|---|
| `Body_Fall` | Cuerpo cayendo al suelo | 3 | P2 |
| `Crawl_Loop` | Gatear | 1 | P2 |
| `GetUp` | Levantarse | 2 | P2 |
| `PickUp` | Alzar al hombro | 1 | P2 |
| `Carry_Loop` | Cargar (tela/armadura) | 1 | P2 |
| `Throw_Short` / `Throw_Far` | Lanzamientos | 1 / 1 | P2 |
| `Throw_Impact` | Cuerpo lanzado que aterriza | 2 | P2 |
| `Revive_Loop` / `Revive_Done` | Rescate | 1 / 1 | P2 |
| `Revive_Slap` | Palmada | 1 | P2 |
| `RingOut_FallWind_Loop` | Viento al caer al vacío | 1 | P2 |
| `RingOut_Sting` | Golpe musical corto al caer | 1 | P2 |
| `Intercept_Save` | Salvar a un aliado en el aire | 1 | P3 |

### 3.4 Arena (~12)
| Clave | Qué es | Variantes | Prio |
|---|---|---|---|
| `Tile_Warning` | Crujido de aviso de la baldosa | 3 | P2 |
| `Tile_Crumble` | Baldosa que se desmorona | 3 | P2 |
| `Tile_Fall_Distant` | Caída lejana al vacío | 2 | P2 |
| `Arena_Rumble_Loop` | Retumbar mientras se desmorona | 1 | P2 |
| `Ambient_Arena_Loop` / `Ambient_Lobby_Loop` | Ambiente (viento, etc.) | 1 / 1 | P3 |
| `Round_StartHorn` | Cuerno de inicio de ronda | 1 | P2 |

### 3.5 Infusiones (~41)
Para cada una de las **6** (`Fire`, `Lightning`, `Blood`, `Ice`, `Poison`, `Shadow`): 

| Clave | Qué es | Variantes | Prio |
|---|---|---|---|
| `Infusion_<X>_Start` | Activación (el arma se enciende) | 1 | P2 (Fire y Lightning P1) |
| `Infusion_<X>_Loop` | Bucle mientras está activa | 1 | P2 |
| `Infusion_<X>_Hit` | Impacto con la infusión | 2 | P2 |
| `Infusion_<X>_End` | Se apaga | 1 | P2 |

Estados y sistema:
| Clave | Qué es | Prio |
|---|---|---|
| `Status_BurnTick`, `Status_BleedTick`, `Status_PoisonTick` | Latido del daño en el tiempo | P2 |
| `Status_ShockZap` | Descarga de la conmoción | P2 |
| `Status_SlowFreeze` | Ralentización helada | P2 |
| `Status_Mark`, `Status_Fragile`, `Status_Weakened`, `Status_Corrode` | Aplicación de marca/fragilidad/debilidad/corrosión | P3 |
| `Infusion_MeterFull` | La barra está llena (listo para Q) | P2 |
| `Infusion_Exhausted` | Fin del agotamiento | P3 |

### 3.6 Interfaz y partida (~24)
| Clave | Qué es | Prio |
|---|---|---|
| `UI_Click`, `UI_Hover`, `UI_TabSwitch`, `UI_MenuOpen`, `UI_MenuClose` | Menús | P2 |
| `UI_Equip`, `UI_Error`, `UI_Notification` | Acciones | P2 |
| `UI_PurchaseOK`, `UI_PurchaseFail` | Compras | P2 |
| `UI_UnlockFanfare`, `UI_LevelUp`, `UI_XPGain`, `UI_CoinGain` | Progresión | P2 |
| `Match_Found` | Partida encontrada | P2 |
| `Countdown_3`, `Countdown_2`, `Countdown_1`, `Countdown_Go` | Cuenta atrás | P2 |
| `Round_Win`, `Round_Lose`, `Match_Win`, `Match_Lose` | Fin de ronda/partida | P2 |
| `Timer_Warning` | Últimos 10 s | P3 |

### 3.7 Música (~6)
`Music_Lobby_Loop` · `Music_Battle_Loop` (idealmente dos capas: calma/intensa) · `Music_Victory_Sting` · `Music_Defeat_Sting` · `Music_Shop_Loop` (opcional) — **P3**.

### 3.8 Esfuerzos y gritos (~12, opcional P3)
`Effort_Light` ×3 · `Effort_Heavy` ×3 · `Hurt` ×3 · `KO` ×2 · `Throw_Grunt` ×1. Evita voces con copyright.

---

## 4. Renders

### 4.1 Modelos 3D de armas (Fase 1)
Cada arma: MeshPart con origen en el agarre, 4–7 studs, ≤ ~5k triángulos, **Attachments** llamados `GripPoint`, `BladeBase` y `BladeTip` (para las estelas) y texturas separables.

| Clave | Arma | Notas | Prio |
|---|---|---|---|
| `Sword` | Espada larga | Equilibrada | P1 |
| `Greatsword` | Espadón | Grande, a dos manos | P1 |
| `Dagger_R` y `Dagger_L` | Par de dagas | Una en cada mano | P1 |
| `Rapier` | Estoque | Larga y fina | P1 |
| `Mace` | Maza | Cabeza pesada | P1 |

Fases 2 y 3 (más adelante): Katana, Lanza, Alabarda, Hacha de Guerra, Espada Colosal, Martillo Gigante. Diseños **originales** (nada de copiar armas de juegos o anime concretos).

### 4.2 Efectos visuales (texturas y partículas)
**Por infusión** (×6: `Fire` llamas naranjas · `Lightning` arcos azul-blanco · `Blood` gotas y hilos rojo oscuro · `Ice` cristales y escarcha celeste · `Poison` nubes/gotas verde ácido · `Shadow` volutas negro-violeta):
| Clave | Qué es |
|---|---|
| `VFX_<X>_Aura` | Partículas sobre el arma mientras está activa |
| `VFX_<X>_Trail` | Textura de estela del arma |
| `VFX_<X>_Hit` | Explosión de impacto (flipbook opcional) |
| `VFX_<X>_Feet` | Anillo/aura en los pies |

**De combate**
| Clave | Qué es | Prio |
|---|---|---|
| `VFX_ParryFlash` / `VFX_ParrySparks` | Destello metálico y chispas del parry | P1 |
| `VFX_GuardBreak` | Fragmentos/anillo al romperse la guardia | P1 |
| `VFX_TelegraphOrange` / `VFX_TelegraphRed` | Brillo del arma para el fuerte (naranja) e imbloqueable (rojo) | P1 |
| `VFX_SlashArc_<Arma>` (×5) | Arco del golpe de cada arma | P1 |
| `VFX_HitSparkLight` / `VFX_HitSparkHeavy` | Chispas de impacto | P1 |
| `VFX_DustKnockdown` | Polvo al derribar | P2 |
| `VFX_LockOnReticle` | Marca del objetivo fijado | P2 |
| `VFX_ThrowTrail`, `VFX_ReviveGlow` | Estela del lanzamiento y brillo del rescate | P3 |
| `VFX_TileCrack` (×3) | Decales de grieta en baldosas | P2 |
| `VFX_TileDebris` (×3 mallas) | Escombros | P2 |
| `VFX_DustSmoke` | Humo/polvo genérico | P2 |

### 4.3 Interfaz (UI)
| Elemento | Detalle | Prio |
|---|---|---|
| Teclas | F, E, R, Q, T, Y, Shift, Espacio, ratón izquierdo, ratón derecho | P1 |
| Iconos de armas | 5 (y 6 más para fases 2/3) | P2 |
| Iconos de infusiones | 6 + marco de "infusión activa" | P2 |
| Iconos de estados | Quemadura, Sangrado, Veneno, Conmoción, Ralentización, Fragilidad, Debilidad, Corrosión de guardia, Marca, Pesadez, Silencio (11) | P2 |
| Barras sobre la cabeza | Vida, Stun, Guardia (marco y relleno) | P1 |
| HUD | Barra de carga de infusión, panel de controles | P1 |
| Menú | Paneles, pestañas, botones (normal/hover/pulsado), tarjetas de arma y de skin, candados | P2 |
| Progresión | Insignia de nivel, estrellas de maestría, barra de XP, iconos de moneda y XP | P2 |
| Pantallas | Cuenta atrás, victoria/derrota, resumen de partida, carga | P3 |

### 4.4 Escenarios
| Clave | Qué es | Prio |
|---|---|---|
| `Tile_Normal`, `Tile_Cracked`, `Tile_Edge` | Baldosa modular (10×2×10 studs) en 3 estados | P1 |
| `Arena_2v2` | Entorno de la arena grande (21×21 baldosas de 10 studs; provisional: cuadrado básico) | P2 |
| `Arena_1v1` | Entorno de la arena pequeña (7×7 baldosas) | P2 |
| `Skybox` + `LightingPreset` | Cielo, atmósfera, iluminación y color | P2 |
| `Void_Surroundings` | Qué hay bajo y alrededor del vacío (nubes, abismo, lava…) | P2 |
| `Lobby` | Zona de espera con spawns y decoración | P2 |
| `Props` | Pilares, estandartes, ruinas (decoración fuera de las baldosas) | P3 |

### 4.5 Marketing (importante para atraer jugadores)
Icono del juego 512×512 · 5–10 miniaturas 1920×1080 · logo · iconos de Game Passes y Developer Products · imágenes de la tienda — **P2** (antes de publicar).

---

## 5. Orden de entrega recomendado (por lotes)
**Idea:** entrega primero **una sola arma completa (la Espada)** para validar todo el sistema de principio a fin; después el resto.

| Lote | Contenido | Para qué sirve |
|---|---|---|
| **1 — Espada completa** | Modelo `Sword` + sus 8 animaciones + sonidos de golpes/bloqueo/parry + `VFX_ParryFlash`, `TelegraphOrange/Red`, `SlashArc_Sword` + teclas de la UI | Probar combate, bloqueo con arma, parry y hitstop con arte real |
| **2 — Combate genérico** | `Dodge`×4, `Kick`, `HitReact`, `GuardBreakStagger`, `ParriedStagger` + sonidos `Dodge`, `Kick_*`, `GuardBreak`, `Hit_*` | Esquiva, patada, reacciones |
| **3 — Derribo y rescate** | `KnockdownFall`, `GetUp*`, `Crawl`, `PickUp`, `Carry*`, `Throw*`, `Revive*` + sonidos 3.3 | Derribo, agarre, lanzamiento y rescate |
| **4 — Resto de armas** | Espadón, Dagas, Estoque, Maza: modelo + 8 animaciones + swings | Arsenal completo de la Fase 1 |
| **5 — Infusiones** | Primero **Fuego y Rayo** (VFX, sonidos, iconos), luego Sangre, Hielo, Veneno y Sombra | Sistema de infusiones y contras |
| **6 — Arena** | Baldosas, arenas, cielo, lobby + sonidos 3.4 | Escenario y desmoronamiento |
| **7 — UI y progresión** | Menús, iconos, tienda, sonidos de UI, música | Interfaz final y monetización |
| **8 — Fases 2/3 y skins** | Armas nuevas y cosméticos | Más contenido |

---

## 6. Cómo pasárselas a Opus
Cuando tengas un lote listo, **sube cada asset a Roblox** (Creator Hub o Studio) y pega esta tabla en el chat (una fila por asset):

```
Clave                         | ID (rbxassetid)  | Notas
Weapons.Sword.Idle            | 123456789        | loop
Weapons.Sword.M1_1            | 123456790        | marcador Hit al 40%
Sounds.Parry                  | 123456791        |
Models.Sword                  | 123456792        | MeshPart + attachments
```
- Las **animaciones y sonidos** deben estar subidos con **tu cuenta (o tu grupo)**, si no, no se reproducen en tu juego.
- Los **modelos**: sube la `MeshPart` con su textura y pasa el ID de malla y de textura, o publica el arma como `Model` con sus `Attachments` y pasa ese ID.
- Opus los coloca en `Assets.lua` y ajusta los tiempos con los marcadores. Si algo no encaja (duración, pose, volumen), se lo dices y lo corrige.
