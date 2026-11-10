# Arquitectura del combate direccional (Claude, 10/11)

Responde a [[Especificación Gemini combate direccional]], sobre la base de [[Diseño Combate PvP Direccional Roblox]] (incluida la «Mesa de diseño» de Codex).
**Estado: solo diseño. No hay código.** Todo se monta sobre lo que ya funciona en la beta 0.1 (`Actions`, `Combat`, `CombatService`, `Controls.client`, `Overhead.client`, `Animator.client`), sin reescribir desde cero.

## 0. Lo que choca con la beta o entre las dos propuestas (decidir antes de programar)
| # | Tema | Beta 0.1 hoy | Gemini | Mesa de Codex | Propuesta de Claude |
|---|---|---|---|---|---|
| 1 | Tecla de defensa | F | Q / L2 | F / L1 | **Q / L2**, como dice Gemini. El bloqueo tiene que ir en un gatillo en el mando. La F queda libre para patear. |
| 2 | Patada y agarre | patada C, agarrar E | los dos en **F** | patada C, agarrar E | **F = patada.** Sobre un derribado: **tocar F = patear 2 studs, mantener F = levantarlo.** No se pisan. |
| 3 | Fijado | automático al entrar a partida, se puede soltar | **permanente** | Q fija, T cambia | **Permanente en partida**, con T / R3 para cambiar. En la ciudad y el patio, libre como hoy. |
| 4 | Dirección | — | mouse o stick derecho | gesto + postura que queda | **La postura queda** (idea de Codex): elegís el lado y queda, sin mantener el stick inclinado. |
| 5 | Derribado | puede recibir golpes | **inmune a las armas** | — | Inmune a R1 y R2. Solo patada o levantar. Cambia el ritmo: hay que probarlo. |
| 6 | Alcance | valores actuales | **+25 a 40 %** | — | +25 % parejo para empezar (`CombatConfig.Directional.ReachMult`), y se ajusta con pruebas. |
| 7 | Parry | ventana actual de `CombatConfig` | 0,15 s | una ventana común | **Una sola ventana común de 0,15 s**, con margen de red en el servidor (sección 3). |
| 8 | Celular sin mando | botones táctiles | — | adaptación posterior | Igual que la decisión del usuario: primero mando y PC, después táctil. |
| 9 | Combo de 3 golpes | sí | «encadena combos» | — | Se mantiene. Cada golpe sale por la dirección elegida en ese momento. |

## 1. Máquina de estados del jugador (vive en el servidor)
Se guarda como atributos del personaje, para que todos los clientes la vean:
- `CombatState`: el estado actual;
- `Stance`: arriba, izquierda o derecha;
- `AttackDir`: la dirección del golpe en curso;
- `StateEnds`: hora del servidor en que termina el estado.

Ya existen `Action` y `ActionPhase`: se reutilizan y se amplían.

| Estado | Entra por | Sale a | Notas |
|---|---|---|---|
| **Neutral** | fin de cualquier estado | todos | Puede mover, cambiar de postura y atacar. |
| **Windup** (carga del golpe) | R1 / R2 | Active, Feint (amago), Staggered | Publica `AttackDir` (el rival ve el lado en rojo). El fuerte se puede amagar. |
| **Active** (golpe activo) | fin del windup | Recovery | El servidor resuelve el impacto (sección 3). |
| **Recovery** (recuperación) | fin del golpe activo | Neutral, Dodge | Una esquiva puede cortarla (ya existe). R1 pulsado antes queda en cola (ya existe, 0,35 s). |
| **Guard** (bloqueo) | mantener Q / L2 | Neutral, Parry, GuardBroken | Bloquea solo los golpes que vienen del lado de `Stance`. Gasta resistencia. Cambiar de lado tarda un instante (`SwitchTime`). |
| **ParryWindow** | apretar Q / L2 (nueva pulsación) | Guard | Dura 0,15 s. Si en ese tiempo llega un golpe del mismo lado = parry. |
| **Parried** (aturdido por parry) | recibir un parry | Neutral | El atacante queda abierto. |
| **Kick** (patada) | F | Recovery larga si falla | Rompe la guardia de quien bloquea. Si no conecta, la recuperación es larga (castigo). |
| **GuardBroken** (guardia rota) | patada a quien bloquea, o guardia vacía | Neutral | Abierto a un golpe seguro. |
| **Staggered** (aturdido) | recibir un golpe | Neutral | Como hoy (Stun). |
| **Dodge** (esquiva) | L1 / Espacio | Neutral | Ya existe: 0,24 s y espera de 0,5 s. |
| **Downed** (derribado) | knockdown, guardia rota grave | Neutral (al levantarse), Carried | **Inmune a las armas.** Solo recibe patada (2 studs) o que lo levanten. |
| **Carried** (levantado) | mantener F sobre un derribado | Thrown, Escaped | Ya existe (agarre y lanzamiento). |

**Cómo se resuelve un golpe** (en el servidor, en el momento del impacto):
1. El objetivo está en **Downed** → no recibe daño (solo patada o levantar).
2. El objetivo está en **ParryWindow** del mismo lado → parry: el atacante pasa a **Parried** y suena el destello dorado.
3. El objetivo está en **Guard** del mismo lado → bloqueo:
   - gasta guardia y resistencia;
   - las excepciones de cada arma siguen igual (Maza imbloqueable en su fuerte superior, Estoque que atraviesa en su fuerte).
4. Cualquier otro caso → golpe limpio con daño completo, y el objetivo pasa a **Staggered**.

## 2. Cliente: el triángulo invertido
Un script nuevo, `DirectionalHUD.client`, centrado sobre el rival fijado (o en la pantalla) y con valores en `UiTheme` / `CombatConfig.Directional`.
- **Elegir el lado:**
  - **Mouse:** con el fijado, el mouse ya no gira la cámara. Se toma el movimiento relativo del mouse (gesto corto con umbral) y la postura queda en el último lado elegido.
  - **Stick derecho:** inclinar pasado una zona muerta elige el sector (arriba, izquierda o derecha) y la postura queda al soltar.
  - El stick hacia abajo no hace nada.
  - Zona muerta, umbral e histéresis configurables en Ajustes.
- **Lo que se ve:**
  - **Tu postura:** el lado se marca en blanco y brilla más mientras bloqueás.
  - **El ataque del rival:** su `AttackDir` se marca en rojo apenas empieza a cargar. El tiempo de carga es lo que permite reaccionar.
  - **El parry:** destello dorado o celeste y un sonido propio. Es la «dopamina».
  - **La patada que viene:** aviso propio, distinto de los golpes.
- **El cliente anticipa:** al apretar, cambia la postura del triángulo y arranca la animación al instante, sin esperar al servidor. Si el servidor rechaza la acción, se corrige.
- **Animaciones:** `AnimClips` necesita tres variantes por golpe (arriba, izquierda y derecha) y tres poses de guardia. Se pueden empezar por pose procedural, como las dagas, y después pasarlas a captura de movimiento.

## 3. Red: sin lag que se note y con el servidor como juez
- **Un solo remoto.** Se amplía el remoto `Input` que ya existe, con límite de 30 por segundo:
  - acciones nuevas `Stance`, `Kick` y `GuardDown`/`GuardUp`;
  - argumentos: la dirección, validada contra la lista {Up, Left, Right}, y un **número de secuencia**.
- **Predicción en el cliente:** animación, triángulo, sonido de golpe al aire y temblor leve salen al instante en tu pantalla. Lo que no se predice es el **resultado** (daño, parry, bloqueo): eso lo decide el servidor.
- **El servidor es el juez:**
  - cambia de estado solo si la transición es válida;
  - el impacto se resuelve con la hitbox del servidor en el momento `HitAt`, que ya existe.
- **Compensación de red para el parry:**
  - el servidor anota a qué hora recibió el «apreté guardia»;
  - para ser justo con el ping, acepta un parry si ese aviso llega **hasta X ms después** del impacto, con X = min(ping estimado del jugador, 100 ms) en `CombatConfig.Directional.ParryGrace`;
  - nunca acepta una hora mandada por el cliente sin límite.
- **Hit-stop:**
  - lo dispara el evento de confirmación (ya existe `CombatEvents` → `Effect`);
  - cada cliente congela localmente 60 a 100 ms, solo las animaciones de los dos involucrados (la física no se frena);
  - temblor de pantalla según la dirección del golpe.
  - Todo va en `PolishConfig`.
- **Validación:** distancia y raycast en el servidor (Codex ya agregó que el objetivo esté en `workspace` y tenga `Combatant`). Las direcciones inválidas se descartan sin aviso.

## 4. Datos nuevos (todo numérico en módulos de datos)
- **`CombatConfig.Directional`:**
  - `Enabled` (empieza en false);
  - `ParryWindow` = 0,15;
  - `ParryGrace` = 0,1;
  - `SwitchTime` = 0,12;
  - `ReachMult` = 1,25;
  - `KickPush` = 2 (studs, contra un derribado);
  - `KickGuardBreak`;
  - `KickWhiffRecovery`;
  - zonas muertas.
- **`WeaponData`:** por arma, qué golpes son especiales (`unblockableDirs`, `piercesGuard`) y la velocidad de cambio de lado.
- **`InputMap`:** las teclas de la sección 0. Siguen siendo reasignables.

## 5. Orden de implementación propuesto
1. Datos + máquina de estados en el servidor + remoto ampliado, apagado (`Enabled = false`).
2. Triángulo y elección de lado con mouse y mando. Patio de práctica con muñecos que atacan por un lado (después por lados al azar).
3. Resolución de bloqueo y parry por dirección, con hit-stop y efectos.
4. Patada, rompeguardias, derribado inmune y patada de 2 studs.
5. Fijado permanente en partida y cambio de objetivo.
6. Prueba con Mateito (celular con mando) y ajuste de números.
7. Táctil, después.

**Reparto sugerido:**
- **Claude:** pasos 1, 3 y 4 (combate y servidor), animaciones y hit-stop.
- **Gemini:** el triángulo y el HUD (paso 2, parte visual).
- **Codex:** `InputMap`, Ajustes, revisión del remoto y pruebas.
