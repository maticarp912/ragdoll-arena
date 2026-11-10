# Decisiones 0.2 — respondidas el 10/11/2026 (Argentina, UTC-3)

El usuario respondió a Claude: «apruebo todo», con los cambios de abajo. **Todas las decisiones están cerradas** (D6 confirmada después: «Sí, Blender»).
Si una respuesta cambia, se edita acá con fecha y hora, sin borrar la anterior.

## Combate
| # | Pregunta | Respuesta del usuario |
|---|---|---|
| D1 | Tabla de conflictos del direccional ([[Arquitectura Combate Direccional]], sección 0) | ✅ Aprobada completa: defensa Q/L2; F = patada (tocar) y levantar (mantener) sobre un derribado; fijado permanente en partida con T/R3; la postura queda; derribado inmune a las armas; +25 % de alcance; parry común de 0,15 s; táctil después; combo de 3 golpes. |
| D2 | Dirección en PC | ✅ **Con el mouse: el movimiento de cámara elige la dirección del ataque** (gesto corto arriba, izquierda o derecha; la postura queda). En mando, el stick derecho. |
| D3 | Números de [[Equilibrio de armas]] | ✅ Aprobados. |
| D4 | Combos por dirección | ✅ **Si los tres golpes del combo conectan, el tercero es un remate (golpe fuerte), sin importar las direcciones.** Cada golpe sale por la postura de ese momento. Cambia la recomendación de Claude (no hace falta repetir lado). |
| D5 | Almas | ✅ Las monedas pasan a llamarse «almas» (mismo saldo, sin migrar), con efecto y sonido de absorber al ganar. Sin pérdida al morir. |

## Skins, tienda y armería
| # | Pregunta | Respuesta del usuario |
|---|---|---|
| D6 | Skins: ¿por código o en Blender? | ✅ **Confirmado por el usuario (10/11/2026): Blender.** **todas las skins pasan a Blender**, en dos tandas. Tanda 1 (piloto): las 3 de la ruleta + 1 por arma, para validar el proceso de subida y cómo se ven. Tanda 2: el resto. Cada skin conserva su versión por código como respaldo hasta que se suba la malla. Gemini genera las mallas y texturas por script; **el usuario las sube** a Roblox (importador 3D de Studio, se pueden subir varias juntas) y pega los IDs en la lista que deja Gemini. Límites: mallas livianas para celular (pocos miles de triángulos por skin) y texturas de 1024 como máximo. |
| D7 | Roles | ✅ **Owner: PapuDoNacimento**, se detecta solo porque es el creador del juego (`game.CreatorId`, como ya hace el menú de depuración). **Tester: Mateito = usuario `mateodoupa`**: guardar el nombre en `Roles.lua` y resolver el UserId en el servidor (`GetUserIdFromNameAsync`, con caché); si el usuario pasa después el número de ID, se usa ese. Admin y Mod: ninguno por ahora. Permisos como la recomendación: Owner y Admin todo el panel; Mod expulsar y silenciar; Tester depuración; VIP etiqueta; Nuevo menos de 3 h. |
| D8 | Panel: darse cosas a sí mismo | ✅ El Owner ya tiene todo; un Admin no se da cosas ni roles iguales o mayores. Todo registrado. |
| D9 | Niveles | ✅ Máximo 100; XP por partida, victoria, eliminación y misión; premios cada 5 y cada 10 niveles. Codex propone la curva. |
| D10 | Ruleta y cajas | ✅ **Ampliado:** hacer la ruleta, las cajas de suerte y **todo el sistema de recompensas**: gancho para jugadores nuevos y motivos para volver a entrar. Diseño en [[Recompensas y retención 0.2]]. |
| D11 | Cambiar de arma entre rondas | ✅ Solo en la previa, antes de la primera ronda. |
| D12 | Tienda que rota | ✅ «Destacado» diario (4 a 6 objetos) + catálogo completo. |
| D13 | Armería | ✅ Desde la ciudad y en la previa; arma, skin, infusión y aura con el personaje en 3D. |
| D14 | HUD | ✅ Vida grande abajo al centro, infusión encima, resistencia y guardia a los costados. |
| D15 | Skins de la ruleta | ✅ La espada de referencia (premio grande de la primera semana), una de espadón y una de maza. |

## Resto
| # | Pregunta | Respuesta del usuario |
|---|---|---|
| D16 | Cinemática | ✅ 4 a 5 s dentro de la previa, sin saltear. |
| D17 | Editor de botones táctiles | ✅ Entra en la 0.2. |
| D18 | Elo | ✅ Para la 0.3. |
| D19 | Arena de la Mano | ✅ Para la 0.3. |
| D20 | Robux | ✅ Nada en la 0.2. |
| D21 | Rojo | ✅ En la sesión de integración; el usuario instala el plugin. |
| D22 | Hachas | ✅ Después de la 1.0. |
