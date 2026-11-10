# Versión 0.2 (pedidos del 9/11, después de publicar la beta)

Contexto: [[Peticiones del usuario]], [[Reparto etapa 8]], [[Equilibrio de armas]], [[Referencia LihFolk]].
La beta 0.1 está publicada: «[BETA] Dark Fantasy Plataforme 2v2 1v1 PVP», de PapuDoNacimento. Se probó con el hermano (Mateito) en celular.
Leyenda: ✅ comprobado en Studio · 🟡 implementado · 🔧 en curso · ⬜ pendiente · 👤 usuario.

## 1. Bugs vistos en la beta
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Punto doble cuando caen los dos | Si los dos caen de la arena, hoy cada uno suma un punto. Tiene que ganar **el que cae segundo**. Hoy `MatchService` trata `alive.Red == 0 and alive.Blue == 0` como empate: guardar el orden de eliminación y darle la ronda al equipo del último en caer. | Codex | ⬜ |
| Cámara rota en celular al fijar objetivo en partida | En el teléfono la cámara se traba o salta con el fijado automático. Revisar `Controls.client` (fijado, órbita y joystick táctil) y probar en teléfono real. | Claude | ⬜ |

## 2. Celular (prioridad alta: el hermano juega en celular)
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Mejor soporte para celular | Botones más grandes y separados. Textos legibles en la Armería (hoy son muy chicos). Menús escalados a la pantalla. Revisar zonas seguras (notch). | Gemini | ⬜ |
| Controles a preferencia | Mover y escalar los botones táctiles con un editor de diseño en Ajustes, guardado en el perfil. Ya existen controles reasignables para teclado y mando (`InputMap`). | Gemini (interfaz) + Codex (guardado) | ⬜ |

## 3. HUD en partida (captura del usuario)
- **Barra de vida grande y horizontal** abajo al centro (zona roja de la captura).
- **Barra de infusión** justo encima (zona amarilla).
- El panel vertical de abajo a la derecha queda solo para resistencia, guardia y aturdimiento, o se rediseña completo.
- Responsable sugerido: Gemini. Estado: ⬜

## 4. Sensación del combate (prioridad alta)
«No se siente lo suficientemente bien pegar o recibir un golpe.»
- **Ritmo más lento:**
  - animaciones más largas y exageradas: más anticipación, golpe marcado, seguimiento;
  - subir `duration` y `hitTime` en `WeaponData` de forma pareja, para no romper el equilibrio (ver [[Equilibrio de armas]]).
- **Que se distinga cada situación:**
  - **Pegar:** pausa de impacto corta (hit-stop) para el atacante, chispa y sonido grave, temblor leve.
  - **Recibir:** retroceso marcado, destello rojo en el borde de la pantalla, sonido de carne o armadura, temblor más fuerte, animación de dolor exagerada.
  - **Bloquear:** chispa metálica clara, sonido de metal contra metal, empuje corto hacia atrás, la barra de guardia parpadea y una pose de bloqueo más marcada.
  - **Romper guardia / parry:** efectos únicos, cámara lenta breve.
- Responsable: Claude (animaciones, efectos y sonido). Guías: LihFolk `lihfolk-vfx` (impactos, hit-stop, temblor) y `lihfolk-sfx`. Estado: ⬜

## 5. Roles y administración
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Roles | Owner, Admin, Mod, Tester, VIP, Nuevo, etc. Etiqueta con color sobre la cabeza y en el chat. El rol se decide en el servidor por lista de UserIds (en un módulo de datos), y «Nuevo» por las horas jugadas. | Codex | ⬜ |
| El Owner tiene todo | El Owner (PapuDoNacimento) tiene todas las armas, skins y auras sin comprarlas. | Codex | ⬜ |
| Panel de administración | Solo Owner y Admin. Buscar un jugador y darle monedas, armas, skins, auras, nivel o rol. Todo se valida en el servidor y queda registrado (quién dio qué a quién). | Codex (servidor) + Gemini (interfaz) | ⬜ |

## 6. Progresión
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Sistema de niveles | XP por partida, victoria, eliminación, derribo y misión. Curva de nivel en un módulo de datos. Nivel visible en el HUD y sobre la cabeza. Recompensas por nivel (monedas, cajas). | Codex | ⬜ |
| Cajas de suerte | Se abren con monedas del juego (sin Robux por ahora). Dan multiplicadores temporales de XP y de monedas (×1,5, ×2, ×3 por X minutos), y a veces skins. Probabilidades visibles en la caja. Si algún día se venden con Robux, hay que cumplir las reglas de Roblox para premios al azar pagos (ver la guía `roblox-monetization-compliance`). | Codex (servidor) + Gemini (interfaz y animación de apertura) | ⬜ |

## 7. Publicación
- 👤 La página del juego todavía muestra el ícono gris de Roblox. Hay que subir el ícono y la miniatura: el usuario ya tiene un arte «Dark Fantasy 1v1 · 2v2 PvP». Se suben en Creator Dashboard → la experiencia → Places/Thumbnails.
- 👤 Pasar el UserId de Mateito para darle el rol Tester.

## 8. Pendientes que vienen de la 0.1
| Pendiente | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Cámara de espectador en 2v2 | Probar con 4 jugadores. También el arreglo de «vivo» (`Eliminated` + estado Dead). | Claude | 🟡 |
| Botón B del mando | Que cierre los menús. Probar con un mando real. | Claude | 🟡 |
| Animaciones de dagas y estoque | Siguen siendo procedurales. Pasarlas a captura de movimiento como las demás. | Claude | ⬜ |
| Sangrado de las dagas | La Doble Estocada dice «sangrado», pero el efecto no está hecho. | Claude | ⬜ |
| Equilibrio | Matriz y cambios a probar en [[Equilibrio de armas]]:
- estoque: fallar gasta más resistencia;
- dagas: más tiempo entre el golpe 2 y el 3;
- maza: barrido más ancho o seguimiento del rival.

Revisar con datos de la beta. | Claude | ⬜ |
| Arena de la Mano | Fuera de la rotación porque no se entiende como mano. Rehacerla. | Gemini (Argon) | ⬜ |
| Revisión de Codex, ronda 6 | Pendientes: hallazgo 5 (sesión perdida), 7 (estadísticas al abandonar una partida), 8 (precios reales si vuelve Robux) y 9 (rendimiento de `CityLife` y de la caché de nombres). | Codex | ⬜ |
| Cielo | Más estrellas usando imágenes de cielo (6 caras), si hace falta. | Claude | ⬜ |
| Rojo | Cambios en vivo en Studio sin regenerar el place. | Claude | ⬜ |
| Robux | Productos y precios reales, más adelante. | 👤 + Codex | ⬜ |

## 9. Ideas del usuario
| Pedido | Detalle | Resp. sugerido | Estado |
|---|---|---|---|
| Cinemáticas antes del combate | Presentación de los jugadores al entrar a la arena: cámara recorriendo la arena, nombres, armas y pose de entrada. | Claude (cámara y poses) + Gemini (carteles) | ⬜ |
| Previa de 10 s antes de cada partida | Al menos 10 s antes de que arranque, con una pantalla para elegir **arma, skin e infusión**. Hoy no se puede cambiar de arma en partida. | Codex (servidor) + Gemini (interfaz) | ⬜ |
| Patear al rival derribado | Mantener la mecánica de levantar y agregar una patada para tirar al rival derribado fuera de la arena. | Claude | ⬜ |
| Combate direccional | Ataques y bloqueos arriba, izquierda y derecha, parry perfecto, patada de ring-out, hit-stop y Elo para las clasificatorias. Diseño completo y preguntas abiertas en [[Diseño Combate PvP Direccional Roblox]]. Cambio grande: decidir antes si entra en la 0.2 o en la 0.3. | Claude | ⬜ diseño |
| Clasificatorias con Elo | Parte del diseño direccional. Hoy RANKED dice «Próximamente». | Codex | ⬜ |

## Orden sugerido
1. Bugs: el punto doble y la cámara en celular.
2. HUD nuevo y soporte de celular.
3. Sensación de combate.
4. Roles, Owner y panel de administración.
5. Niveles y cajas de suerte.

## Registro
- 9/11: nota creada con los pedidos de la beta 0.1.

## 10. Mesa de diseño direccional — propuestas nuevas, sin implementación (9/11)
Decisión ya confirmada por el usuario: el direccional es el eje de la 0.2. Detalle actualizado en [[Diseño Combate PvP Direccional Roblox]], sección Mesa de diseño 0.2.
- Propuesta: postura persistente de tres direcciones separada de atacar/bloquear, manteniendo controles conocidos del mando; celular con mando usa exactamente el mismo esquema.
- F bloqueo, C patada, E agarrar y Q fijar como mapa candidato PC; comparar mouse frente a ataques directos Q/M1/E antes de decidir. Selector táctil con sectores y gesto; sin depender de puntería en botones chicos.
- Priorizar arreglo de cámara en celular antes del prototipo. Resolver explícitamente quién usa el stick derecho en fijado, sin fijado y al lanzar.
- Probar una ventana de parry común, sin ventaja automática por dispositivo; cambiar de guardia no renueva parry.
- Primer prototipo con espada y muñeco en práctica; no activarlo en partidas públicas hasta jugarlo con Mateito en teléfono con mando y con táctil.
- Propuesta de aprendizaje: ejercicio de una dirección, después tres, indicador propio y aviso enemigo con formas además de color. Registrar errores de selección/cámara, no solo victorias.
- Revisar imbloqueable de Maza y bypass del Estoque para que leer la dirección siga teniendo sentido. Dejar números y Elo para después de validar controles.
**Implementado:** ninguna mecánica nueva en esta sesión; solo notas. **Comprobado en Studio:** nada nuevo del direccional. **Pendiente:** confirmar esquema con el usuario, diseñar/probar prototipo y cerrar las preguntas abiertas. No modifica el estado histórico de la beta 0.1.

## Prioridad de plataformas confirmada por el usuario (9/11)
El combate direccional se diseña principalmente para **mando y teclado/mouse**. El celular táctil se adapta después como soporte secundario. Celular con mando sigue dentro del objetivo principal: requiere cámara estable y avisos/HUD legibles en pantalla chica. No se considera aprobado todavía ningún mapa de botones particular. Ver [[Diseño Combate PvP Direccional Roblox]].
**Implementado:** solo actualización de diseño. **Comprobado en Studio:** nada nuevo. **Pendiente:** cerrar controles principales, prototipar y probar con Mateito; adaptar táctil después.
