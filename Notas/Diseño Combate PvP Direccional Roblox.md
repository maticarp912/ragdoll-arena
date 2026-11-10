# Diseño Combate PvP Direccional (Roblox)

Propuesta del usuario (9/11) para [[Versión 0.2]]. **Es solo diseño: no se toca código ni el juego hasta que el usuario decida implementarlo.**

## Mecánicas ofensivas y defensivas (tres direcciones)
| Dirección | Ataque | Defensa |
|---|---|---|
| Superior (overhead) | Clic izquierdo (M1) | F (cubre el frente y arriba) |
| Lateral derecho | E | Bloqueo lateral derecho (E) |
| Lateral izquierdo | Q | Bloqueo lateral izquierdo (Q) |

## Resolución y reglas
- **Parry o bloqueo:**
  - Hay una ventana corta (0,12 a 0,15 s) para el parry perfecto: aturde al atacante y anula el daño.
  - Si se mantiene la tecla, pasa a bloqueo normal, que gasta postura o resistencia.
- **Lectura de dirección:** si la defensa no coincide con la dirección del ataque, el golpe entra limpio y con el daño completo.

## Control del terreno y ring-out
- **Levantar:** cargar un rato al rival mientras está derribado o en ragdoll. Por ahora se mantiene como está.
- **Patada para sacarlo de la arena:** con F en neutral u ofensiva. Aplica un empuje horizontal fuerte para expulsar al rival. También sirve para patear a un rival derribado y tirarlo.

## Sensación y red
- Pausa de impacto (hit-stop, congelado breve) y temblor de pantalla según la dirección del golpe.
- Efectos visuales locales, con validación estricta de distancia y raycast en el servidor.
- Clasificatorias con sistema Elo.

## Preguntas abiertas (anotadas por Claude, para decidir antes de implementar)
1. **F tiene dos usos:** bloqueo superior y patada. ¿Cómo se distinguen? Algunas opciones:
   - mantener F = bloquear y tocar F = patear;
   - patear solo si el rival está derribado.
2. **E y Q chocan con los controles actuales.** Hoy esas teclas ya hacen otras cosas (ver `InputMap`). Habría que reasignar agarrar, infusión y lo que esté en esas teclas.
3. **¿Cómo se hace en celular y con mando?**
   - Celular: tres botones de ataque, o un botón con deslizamiento hacia arriba, izquierda o derecha.
   - Mando: dirección con el stick derecho más gatillo.
4. **Hay que decir de dónde viene cada golpe.** El aviso de ataque fuerte (punto rojo) tendría que indicar también la dirección, para que se pueda leer y defender.
5. **Combo actual de 3 golpes.** ¿Se reemplaza por golpes direccionales, o cada dirección tiene su propio combo?
6. **Equilibrio:** la ventana de 0,12 a 0,15 s es muy exigente con la latencia de celular. Considerar una ventana más amplia en celular, o compensar el ping.
