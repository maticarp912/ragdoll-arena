# Reporte 0.2 — Integración en Studio (Claude, 10/11/2026 15:22, Argentina)

Prompt: [[0.2 Integración - pruebas en Studio]]. Lista de trabajo: [[Integración 0.2]].
Se probó en Studio, con dos métodos:
- **Jugando:** el usuario jugó la partida 1v1 con dos clientes.
- **Con scripts:** Claude disparó acciones por los remotos reales y leyó los eventos del juego.

Al terminar: `check_lua` OK (82 archivos), LihFolk 0/0, y `CombatConfig.Directional.Enabled` sigue en **false**.

> Ojo para las próximas pruebas: hacer `require` de un módulo del servidor desde la barra de comandos crea **otra copia** del módulo, con sus propios bucles. Para probar, usar los remotos y los atributos (`DummyMode`, `DummyDir`), no `require(Combat)`.

## Resultados
### A. Direccional apagado (0.1 + sensación)
| Prueba | Resultado |
|---|---|
| Golpear, recibir, bloquear, ser bloqueado, romper guardia y parry: cada uno manda su evento `Feel` propio (C23) | ✅ |
| Hit-stop con tope de 0,2 s; sonidos 2D con ID válido | ✅ |
| Borde rojo de pantalla al recibir; destello blanco del impacto | ✅ visto en pantalla |
| Alcance +25 %: la espada pega a 7,99 studs (antes llegaba a 7) | ✅ |
| Cámara al fijar en celular (emulador iPhone 17 Pro): 0 studs de salto por frame arrastrando el dedo | ✅ en emulador; ⬜ teléfono real |
| Esquema de teclas clásico (`InputMap.layout() = Classic`) | ✅ |

### B. Ciudad
| Prueba | Resultado |
|---|---|
| Armería con V, vista 3D del personaje con arma y skin | ✅ |
| Skins rehechas y las 3 de la ruleta en tienda y armería | ✅ |
| Tienda: Destacado del servidor, sin skins de la ruleta; cuenta hasta las 00:00 de Argentina | ✅ tras el arreglo 1 |
| Owner: todas las skins y botón «Administración»; Player2 = Nuevo, sin panel | ✅ con el gancho de prueba (arreglo 4) |
| Panel de administración: abre y responde | ✅; campos arreglados (arreglo 3), probarlos otra vez escribiendo |
| Panel de depuración (P) | ✅ |

### C. Partida 1v1 con dos clientes (la jugó el usuario)
| Prueba | Resultado |
|---|---|
| Cola, previa de 10 s con elección de arma, infusión y skin, cinemática, rondas, final | ✅ «Todo bien» (usuario) |

### D. Direccional encendido (solo en la copia de Studio, sin tocar el archivo)
| Prueba | Resultado |
|---|---|
| Atributos C16 publicados (`Stance`, `CombatState`, `AttackDir`, `StateEnds`) | ✅ |
| Postura por el remoto: válida aceptada, inválida («Abajo») descartada | ✅ |
| Muñeco `DirOne` ataca por Left; bloqueo con postura Right (lado espejo) | ✅ 4 de 4 bloqueados |
| Golpe por el lado no cubierto: entra | ✅ |
| Parry con pulsación justa del lado correcto | ✅ 6 de 6 |
| Golpe contra guardia del lado correcto → bloqueado; patada → guardia rota; combo sobre guardia rota → remate | ✅ |
| Remate (D4): tercer golpe con `finisher = true` y derribo | ✅ |
| Derribado inmune a las armas (la vida no baja) | ✅ |
| F tocada sobre el derribado: lo empuja 2,14 studs (D1 pide 2) | ✅ |
| F mantenida: lo levanta (estado `Carried`) | ✅ |
| Gesto del mouse: postura predicha al instante y confirmada por el servidor en ~60 ms | ✅ (gestos exactos sin probar: el mouse queda centrado) |
| Triángulo invertido con tu lado en blanco | ✅ a escala ×3; a tamaño normal casi no se veía → arreglo 5 |
| Stick derecho del mando | ⬜ sin mando |
| Fijado permanente en partida y T / R3 | ⬜ (no se jugó partida con el direccional encendido) |
| Margen de ping del parry (red simulada) | ⬜ |
| Maza (arriba imbloqueable) y Estoque (atraviesa) | ⬜ solo revisión de código |

### E. 2v2 con 4 clientes
⬜ No se corrió.

## Arreglos aplicados en esta sesión
1. **Destacado:** `ShopService` rechazaba `GetFeatured` porque exigía un id; la tienda caía a su lista local, que traía skins de la ruleta. Ahora el servidor lo acepta sin id. El respaldo del cliente hace el mismo cálculo que el servidor (día de Argentina, sin ruleta).
2. **Tienda:** la clave cruda `rotateHint` → `ui.armory.rotateHint`.
3. **Panel de administración:** los campos usaban la ayuda como texto y se mezclaba con lo escrito. Ahora va como `PlaceholderText`.
4. **Owner en Studio:** el place sin publicar tiene `CreatorId = 0` y nadie era Owner. Gancho **solo para Studio**: `workspace:SetAttribute("StudioOwnerUserId", <UserId>)` (-1 = Player1 en «Servidor y clientes»).
5. **Triángulo direccional:** 92 → 140 px, trazo 7 → 10, transparencia en reposo 0,72 → 0,5.

## Pendiente
- ⬜ Direccional: stick derecho, fijado permanente en partida, ping simulado, Maza y Estoque, 2v2.
- ⬜ Teléfono real (Mateito) para la cámara y el táctil.
- 🎨 Armería (Gemini): las miniaturas giran tipo vitrina y en algunos momentos el arma queda de punta y se ve chica. Además el texto «Arrastrá para girar» queda tapado en la vista 3D.
- 👤 Subir las mallas de Blender (ver [[Reporte 0.2 Gemini]]).
