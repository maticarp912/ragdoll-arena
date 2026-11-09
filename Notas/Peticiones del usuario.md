# Peticiones del usuario

Registro de todo lo que pidió el usuario, para no perder el hilo. **Se actualiza en cada pedido nuevo y cada vez que algo avanza.**
Leyenda: ✅ comprobado en Studio · 🟡 implementado, sin probar jugando · 🔧 en curso · ⬜ pendiente · 👤 lo hace el usuario.
Responsables actuales: ver [[Reparto etapa 8]].

## Pendientes importantes (resumen)
1. 🔧 **Primera publicación para la beta** (hermano en celular con mando). Prueba en Studio del 9/11, 18:45:
   - ✅ Partida 1v1 con 2 jugadores.
   - ✅ Celular (iPhone XR) y emulador de mando.
   - ✅ Las 5 armas.
   - ⬜ Falta integrar la ronda 6 y volver a probar. — Claude
2. ✅ **Espada a dos manos y martillo más grande** (visto en Studio: espada tomada con las dos manos, maza grande en reposo alto): los hizo Claude (Gemini no los recibió). Maza ×1,3 con alcance 7 / 7,5.
3. ✅ **Botones táctiles ocultos cuando hay mando** (emulador de mando: se ocultan y vuelven al tocar). 🟡 B que cierra los menús, sin probar. — Claude
4. 🟡 **Arenas** (Codex ronda 2, revisado por Claude en Studio el 9/11): las 4 se construyen (Bosque, Cañón 243 piezas, Templo 495, Mano 198) y rotan por partida. Acabado básico: el Cañón es un anillo de bloques, el Templo se reconoce (columnas con jeroglíficos) y la Mano **no se lee como mano**. ✅ Derrumbe visto en Studio: las losas caen y se ve lava abajo, sin bloque negro. ⬜ Falta una segunda pasada de arte.
5. ✅ **Cielo de estrellas doradas** (Claude, visto en Studio): ~3.200 estrellas doradas (1.400 en celular) de tres tamaños, halos cálidos en las grandes, titileo, luna azulada con halo; sigue a la cámara (ciudad y arenas). Límite: la niebla de la atmósfera apaga lo lejano, por eso están a 650 studs; para igualar la densidad de la referencia haría falta un cielo con imágenes subidas (6 caras).
6. ⬜ **Ciudad estilo pueblo RPG**: Codex hace la taberna, el santuario del punto de aparición, los hongos y la vegetación (`CityProps`, ronda 3); Claude, el estilo general (tejados, caminos curvos).
7. ⬜ **Tableros de clasificación en la plaza.** — Codex (ronda 3); el servidor y el dibujo ya están.
8. 🟡 **Cámara de espectador** al morir en 2v2: sigue a un aliado vivo (o a un rival). — Claude
   - Falta probarla en una partida 2v2 (hacen falta 4 jugadores).
   - Arreglado el 9/11: Roblox regenera la vida de un cuerpo muerto, así que un aliado caído volvía a contar como vivo en la ronda, en el fijado y en el espectador. Ahora se mira `Eliminated` y el estado Dead.
9. 👤 Pasar el ID de Roblox del hermano para el menú de depuración. Crear los productos de Robux (skin `Requiem`, auras Ojos que vigilan y Fractura pálida).

## Pedidos del 9/11, 18:00
| Pedido | Resp. | Estado |
|---|---|---|
| Revisar LihFolk V2 y, si sirve, sumarlo al trabajo de las IA (con permiso para instalar) | Claude | 🟡 plugin configurado en `.claude/settings.json` (activo al abrir una sesión nueva); revisor pasado por los 71 archivos (3 avisos, arreglados; queda en 0); [[Referencia LihFolk]] escrita; regla C0 para todas las IA; prompts de la ronda 6 actualizados |

| ¿Rojo, Git y Wally sirven? Armar Git | Claude | ✅ repositorio creado (rama `main`, primer commit `dab2bce`, 255 archivos); regla C0b en [[Contratos etapa 8]]. Subido a GitHub privado: `maticarp912/ragdoll-arena`. ⬜ Rojo después de la ronda 6. Wally descartado por ahora |

## Pedidos del 9/11, 17:40
| Pedido | Resp. | Estado |
|---|---|---|
| Quitar los «golpecitos» del dash y dejar el woosh | Claude | 🟡 sin sonidos de librería y sin pasos de Roblox durante el dash |
| Botón Armería que no funcionaba | Codex | ✅ |
| Al fijar objetivo, HUD completo; en la arena se fija solo al rival | Claude | ✅ HUD con objetivo (visto); ✅ fijado automático al entrar a partida (visto con 2 jugadores) |
| Vista previa de auras incorrecta | Claude | ✅ arreglada |

## Pedidos del 9/11, 16:40 (con capturas)
| Pedido | Resp. | Estado |
|---|---|---|
| Pegar y dashear rápido: encadenar acciones, menos tiempo entre ellas | Claude | ✅ el dash corta la recuperación del golpe y un golpe pulsado durante el dash sale al terminar (medido en Studio); dash cada 0,5 s, menos frenado |
| Bloquear hace más lenta la regeneración de stamina | Claude | 🟡 al 35 % |
| Lanzamiento cargado más corto | Claude | 🟡 ~40 % menos al máximo |
| Que no se vean las otras arenas: cada una aislada con una «máscara» temática | Gemini B | ✅ cada arena a 4.500 studs, con borde temático de 360° |
| Piso o fondo bajo la arena y desenfoque al caer | Gemini B | 🟡 fondo temático y desenfoque implementados; falta probar una caída |
| Menú de depuración a la derecha | Claude | 🟡 |
| Botones Duelo 1v1 / Arena 2v2 centrados, y RANKED junto a ellos (sale de la tienda) | Gemini A / Codex | ✅ |
| Armería, Ajustes, Misiones, Clasificación en columna a la izquierda | Gemini A / Codex | ✅ el botón Armería ya abre la tienda |
| HUD vertical abajo a la derecha, solo visible en batalla | Gemini A / Codex | ✅ 5 columnas verticales; se ve en partida, con objetivo fijado o tras pegar |
| Verse con el aura en la vista previa (el propio personaje) | Gemini A / Codex / Claude | ✅ panel completo a la izquierda y personaje entero con el aura a la derecha |
| Bug: algunas auras «apagan» las luces de la ciudad (causa probable: escenario de vista previa a 680 studs) | Gemini A | 🟡 escenario eliminado |
| Auras con más presencia y color | Claude | ✅ colores propios y saturados, más partículas y brillo (alas violetas vistas en Studio) |
| Modelo de personaje más esbelto, menos cuadrado | Claude | ✅ proporciones aplicadas al aparecer (torso 1,61 de ancho en vez de 2); falta juzgar el aspecto y las animaciones |
| Lobby con caminos, más vida y movimiento | Codex C (utilería y movimiento) + Claude (caminos generales) | 🟡 Codex: taberna, santuario, tableros, hongos, faroles, fuente y movimiento (319 piezas, 5 luces); ⬜ caminos generales de Claude |
| Precarga de texturas, sonidos y modelos antes de entrar | Gemini A / Codex | ✅ sin errores en la Salida |

## Ronda 3 (9/11, 16:30) — ver [[Tareas ronda 3]]
| Pedido | Resp. | Estado |
|---|---|---|
| Arreglos de interfaz vistos en Studio (iconos sobre el texto, HUD que tapa, pedestal de auras invisible, miniaturas chicas) | Gemini (Flash) | ✅ iconos separados del texto, miniaturas grandes, iconos propios por aura; 🔧 quedan los de A2 |
| Segunda pasada de arte de las arenas (Mano, Cañón, Templo) | Gemini | ✅ Cañón y Templo (dorado, mármol, haz de luz) vistos en Studio; luz de arena subida; ⬜ Mano fuera de la rotación hasta rehacerla |
| Taberna, santuario del punto de aparición, tableros, hongos y vegetación | Codex (Sol medio) | 🟡 hecho, visto por encima en Studio |

## Etapa 8 — pedido inicial (9/11)
| Pedido | Resp. | Estado |
|---|---|---|
| Espada por defecto sencilla; la actual pasa a skin de Robux (`Requiem`, Epic, 149 R$) sin perder el diseño ni romper compras | Gemini | 🟡 · 👤 crear producto |
| Botones de monedas en el menú P (solo Studio o autorizados) | Codex | ✅ |
| Armas más parecidas a las fotos, menos cuadradas | Gemini | 🟡 espadones y 3 mazas óseas; 🔧 resto |
| Espadones más grandes y pesados (Guts / Zabuza), revisados con las animaciones | Gemini / Claude | 🟡 modelos; ⬜ probar con animaciones. Alcance sin cambios: ya coincide con la hoja nueva |
| Más mazas con el estilo de Mandíbula Antigua | Gemini | 🟡 Vértebra del Abismo, Fauces del Sepulcro, Corona del Osario |
| Hachas como sexta arma | — | ⬜ otra etapa |
| Vista previa de la tienda = arma equipada | Gemini | 🟡 |
| Sección Auras (cuerpo y arma, compra, guardado, idiomas, vista previa) | Codex / Gemini | ✅ compra y equipar; 🟡 visibilidad corregida; 🟡 pestaña de la tienda |
| Vida +35 % | Claude | ✅ visto (243 la espada) |
| Dash más corto (16 → 12 studs) | Claude | 🟡 |
| Más lento al cargar a un derribado (0,8 → 0,6) | Claude | 🟡 |
| Lanzamiento más corto, normal y cargado | Claude | 🟡 |
| Punto rojo en la punta para todos los fuertes, sin teñir el arma; imbloqueable distinguible | Claude | ✅ |
| Ciudad: buscar y arreglar bugs visuales | Claude | ✅ parpadeo de la estatua; 🟡 pilar de la puerta y bordillos |
| Ciudad estilo pueblo RPG (`02_lobby_pueblo_noche`) | Claude | ⬜ |
| Cielo de estrellas doradas (`01_cielo_estrellas_doradas`) | Claude | ✅ (ver pendientes, punto 5) |
| Revisar las imágenes nuevas (taberna, punto de aparición, carga, tienda, infusiones, auras) | Claude / Gemini | 🔧 taberna, punto de aparición y ambiente para Claude; pantalla de carga e Infusiones para Gemini; la de auras está en blanco |
| Doble cola, mensajes de partida sin traducir, mando en la confirmación de compra, recibo de Robux | Codex / Gemini | ✅ mensajes traducidos; 🟡 el resto |
| Tres idiomas en todo lo nuevo; pruebas en escritorio, pantalla chica, móvil y mando | todos | 🔧 |
| Todo en Obsidian para que las IA lo tengan de referencia | Claude | ✅ |

## Ampliación (9/11)
| Pedido | Resp. | Estado |
|---|---|---|
| Tablas de clasificación en el lobby: victorias, eliminaciones, derribos, monedas | Codex / Gemini / Claude | 🟡 servidor y dibujo; ⬜ ubicar los tableros en la ciudad |
| Monedas por victoria y por misiones | Codex | 🟡 (220 por victoria, 65 por derrota, misiones de 100–130) |
| Apartado «Clasificatorias: próximamente» | Gemini | 🟡 |
| Dash que siga y rodee al objetivo fijado; arreglar su animación | Claude | ✅ medido en Studio |
| Bug: algo negro bajo la arena en el derrumbe | Codex | ✅ visto en un derrumbe (9/11): sin bloque negro, lava abajo |
| Peligros en el vacío (púas, lava) | Codex | 🟡 lava, púas y agua según la arena |
| Más de una arena (`arena 2`, `arena 3`, `mano como arena 4`) | Codex | 🟡 4 arenas en rotación; arte básico, la Mano necesita rehacerse |
| Interfaz trabajada por un profesional de diseño | Gemini | 🟡 |
| La ciudad está demasiado iluminada | Claude | ✅ ~25 % más oscura |
| El piso alrededor de la estatua parpadea | Claude | ✅ |

## Combate y armas (9/11, tarde)
| Pedido | Resp. | Estado |
|---|---|---|
| Golpes básicos y fuertes gastan stamina según el arma | Claude | 🟡 |
| Fijar objetivo solo de cerca | Claude | 🟡 (28 studs) |
| Martillo más grande | Gemini | 🔧 |
| Espadón y martillo apoyados en el hombro | Claude | ✅ |
| Todas las armas a dos manos salvo el estoque | Claude / Gemini | 🟡 mano izquierda por IK; 🔧 empuñadura larga de la espada |

## Beta (9/11)
| Pedido | Resp. | Estado |
|---|---|---|
| Publicar para probar con el hermano (celular con mando) y actualizar seguido | Claude / 👤 | ⬜ primera versión lista para publicar |
| Botones táctiles ocultos con mando | Claude | ✅ (emulador de mando en Studio) |
| Monedas de depuración para el hermano | Claude / 👤 | ⬜ falta su ID de Roblox |

## De etapas anteriores, todavía abiertos
| Pedido | Resp. | Estado |
|---|---|---|
| Animaciones de calidad AAA (For Honor / Sifu), golpes que se noten | Claude | 🟡 captura de movimiento incorporada; ⬜ sensación jugando |
| Animaciones de dagas y estoque (siguen procedurales) | Claude | ⬜ |
| Escuchar los SFX jugando y ajustar volumen y tramos | 👤 / Claude | ⬜ |
| Textos de combate traducidos | Claude | 🟡 |

## Ronda 7 — preparación beta (Codex)
Implementado: integración de fachadas Gemini, catálogo íntegro con monedas, stores separados Studio/live, reintentos y plazo del guardado final, carga cancelada con liberación, límites Shop/Debug y validación de direcciones/objetivos. Sin prueba de Studio por Codex todavía.
Post-beta de Ronda 6: hallazgo 5 (estado lease perdido), 7 (abandono y estadísticas), 8 (precios/catálogo si vuelven productos premium), 9 (coste CityLife/cache de nombres).
