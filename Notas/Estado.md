# Estado (actualizado 9/11/2026, etapa 8)

> ✅ comprobado en Studio · 🟡 implementado, sin comprobar jugando · ⬜ pendiente
> El chequeo de sintaxis (`tools/check_lua.js`, 68 archivos OK) es básico: **no** equivale a probar en Studio.
> Lista de pedidos con su estado: [[Peticiones del usuario]]. Historial: [[Registro de cambios]].

## Comprobado en Studio ✅ (9/11, Claude)
- **Combate**: vida nueva (243 con la espada).
- **Dash con objetivo fijado**: orbita al objetivo a distancia constante (8 studs, 64°) mirándolo todo el tiempo.
- **Aviso de fuertes**: punto rojo en la punta (espada) e imbloqueable con centro blanco y doble anillo dorado (maza); el arma ya no se tiñe.
- **Reposo en el hombro**: espadón y martillo.
- **Ciudad**: luz ~25 % más baja, ventanas ámbar; el piso de la estatua ya no parpadea.
- **Economía y auras (Codex)**: los botones de monedas de depuración dan monedas, compras de auras con descuento correcto y equipar aura; mensajes de partida traducidos.
- **Interfaz de Gemini**:
  - La tienda nueva abre, con pestañas Armas, Skins, Infusiones (tarjetas altas) y Auras, y con Clasificatorias «Próximamente».
  - La barra de cola y el menú superior se ven.
  - La vista previa de auras ya no da error, aunque el pedestal no se ve.
- **Arenas (Codex)**: las 4 variantes se construyen (Cañón 243 piezas, Templo 495, Mano 198).

## Implementado, sin comprobar jugando 🟡
| Área | Qué | Dónde |
|---|---|---|
| Combate | Dash 12 studs, cargar ×0,6, lanzamiento −30 %, stamina por arma, fijar objetivo hasta 28 studs | `CombatConfig`, `WeaponData`, `Actions` |
| Armas | Espada a dos manos (IK de la mano izquierda), maza ×1,3 con alcance 7 / 7,5 | `WeaponBuilder`, `Animator`, `WeaponData` |
| Armas (Gemini) | Espada base nueva, `Requiem`, espadones de 7,6 studs, 3 mazas óseas, diseños dedicados para las 7 skins viejas, todas las clases con largo uniforme | `WeaponBuilder`, `SkinDesigns`, `Skins` |
| Mallas e iconos (Gemini) | 16 mallas `.obj`/`.fbx` y 19 iconos `.png`/`.svg` exportados; **no se usan hasta subirlos** y pegar los IDs | `modelos_armas/`, `ui_assets/`, `WeaponMeshes`, `UiAssets` |
| Interfaz (Gemini) | HUD con aviso de eliminaciones, misiones, clasificación, fin de partida, ajustes con volumen y escala, táctil, pantalla de carga | archivos de interfaz |
| Táctil y mando | Botones táctiles ocultos con mando; B cierra los menús | `TouchUI`, `MatchUI`, `LobbyUI` |
| Guardado (Codex) | `UpdateAsync` con bloqueo de sesión, reintentos al cargar, recibos que se confirman solo si se guardó | `PlayerData`, `ShopService` |
| Economía (Codex) | Estadísticas, monedas por partida (220 / 65), misiones diarias, tablas de clasificación | `StatsService`, `MissionService`, `LeaderboardService`, `Economy` |
| Arenas (Codex) | Sin la capa de roca continua ni el suelo negro (causa probable del negro del derrumbe), peligros en el vacío, rotación de 4 arenas | `ArenaBuilder`, `ArenaConfig`, `MatchService` |
| Pulido | Textos de combate traducidos, grupo de sonido `SFX`, opción de sacudida de cámara | `Combat`, `Fx`, `Controls`, idiomas |
| Ciudad | Pilar de la gran puerta y bordillos sin parpadeo | `LobbyBuilder` |

## Pendiente de probar (en este orden, antes de publicar la beta)
1. **Celular con mando** en el emulador de Studio: botones táctiles ocultos, menús navegables, HUD legible.
2. **Espadones nuevos** con las animaciones de captura: agarre izquierdo, estela, que no atraviesen el cuerpo. Alcance sin cambios (ver [[Equilibrio de armas]]).
3. **Espada a dos manos y maza grande** en golpes.
4. **Derrumbe completo** de una arena: confirmar que ya no queda nada negro.
5. **Dos jugadores** (Prueba → 2 jugadores): partida, estadísticas, aviso de eliminaciones, resumen, misiones y monedas.
6. **Persistencia**: solo con el lugar publicado (o «Enable Studio Access to API Services»).

## Pendiente de hacer ⬜
- Ronda 3 ([[Tareas ronda 3]]): arreglos de interfaz y arte de arenas (Gemini); taberna, santuario del punto de aparición y tableros (Codex).
- Claude: estilo general de la ciudad, cielo de estrellas doradas, cámara de espectador, animaciones de dagas y estoque.
- Usuario: crear productos de Robux (`Requiem`, Ojos que vigilan, Fractura pálida), subir mallas e iconos si se quieren usar, pasar el ID del hermano para el menú de depuración.
