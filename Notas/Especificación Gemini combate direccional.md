# Especificación de Gemini: combate direccional (10/11)

El usuario la armó hablando con Gemini y la trajo para implementar la mecánica. Es el texto original, resumido sin cambiar las reglas.
La arquitectura técnica y lo que choca con la beta están en [[Arquitectura Combate Direccional]]. Diseño previo: [[Diseño Combate PvP Direccional Roblox]].

## 1. Cámara, fijado y distancias
- **Fijado permanente:** en partida, la cámara siempre está fijada en el rival. El combate es de frente, sobre un eje (arena fighter puro).
- **Cambiar de objetivo:** en 2v2, [T] o [R3] pasa al siguiente enemigo.
- **Alcance:** el alcance de todas las armas sube entre un 25 % y un 40 %, para jugar a entrar y salir de rango.

## 2. Interfaz y combate en tres direcciones
- **Triángulo invertido** siempre en pantalla, con tres lados: arriba (neutro), izquierda y derecha. Se elige con el mouse o el stick derecho.
- **Colores:**
  - el lado desde donde ataca el rival brilla en **rojo**;
  - tu guardia brilla en **blanco**;
  - un parry perfecto destella en **dorado o celeste**, con un sonido muy satisfactorio.
- **Bloqueo:** mantener [L2] y poner la guardia del mismo lado que el ataque. Si no coincide, el golpe entra limpio con daño completo.

## 3. Controles
| Acción | Mando | PC |
|---|---|---|
| Dirección del ataque o de la defensa | Stick derecho | Mouse |
| Moverse | Stick izquierdo | WASD |
| Ataque normal (rápido, encadena combos) | R1 | Clic izquierdo |
| Ataque fuerte (lento, rompe guardias o la atraviesa según el arma) | R2 | Clic derecho |
| Defensa: tocar en la ventana exacta (0,15 s) = **parry** que aturde; mantener = bloqueo que gasta resistencia | L2 | Q |
| Esquiva (puede cortar la recuperación de un golpe) | L1 | Espacio o Shift |
| Cambiar de objetivo | R3 | T |
| Patada / agarre | Cuadrado (X) | F |

## 4. Patada y rompeguardias (riesgo y recompensa)
- Si el rival solo bloquea, la patada le rompe la guardia y asegura un golpe.
- Si la patada falla (por ejemplo, porque el rival esquivó hacia atrás), el que pateó queda vulnerable durante su recuperación.

## 5. Juego en el piso y ring-out
- **Derribado = inmune a las armas:** un jugador derribado (ragdoll) **no** recibe daño de R1 ni R2.
- **Sobre un derribado solo se puede hacer dos cosas:**
  1. **Levantarlo** para tirarlo fuera de la arena.
  2. **Patearlo [F]:** lo empuja exactamente 2 studs. Sirve para arrinconarlo o acercarlo de a poco al borde.

## Lo que Gemini pedía entregar
1. La máquina de estados del jugador: ataque y defensa por dirección, más la inmunidad en el piso.
2. La arquitectura del cliente para el triángulo invertido, manejado con el mouse o el stick derecho.
3. La lógica de red en Luau: predicción en el cliente, hit-stop y validación en el servidor.

Respuesta de Claude (diseño, sin código todavía): [[Arquitectura Combate Direccional]].
