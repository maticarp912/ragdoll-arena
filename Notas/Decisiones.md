# Decisiones de diseño

Resumen vivo. `RESUMEN_PROYECTO.md` (carpeta del juego) es el documento original; estas decisiones mandan sobre él.

## Juego
- PvP **1v1 y 2v2**, físicas ragdoll, rig **R15**, **sin salto**, estilo **dark fantasy**.
- Se gana eliminando al rival: **caer de la arena** o **vida a 0**.
- **No hay escudos**: se bloquea con el arma.
- **Arma e infusión se eligen antes de la partida** y no se cambian ni entre rondas.
- La **carga de infusión se conserva** entre rondas de la misma partida.
- Arena: plataforma flotante que **se derrumba por piezas**.

## Combate
- Controles de la beta 0.1 (reasignables en `InputMap`): M1 combo, M2 fuerte, F guardia/parry, Espacio dash, E agarrar/interactuar, C patada, R infusión, Q fijar objetivo, T cambiar objetivo, B menú. El direccional de la 0.2 propone otros (sin aprobar): [[Arquitectura Combate Direccional]].
- Barras: Vida, Stamina, Guardia, Stun, Infusión.
- **Parry** = desvío y ventaja breve (no dejar al atacante indefenso demasiado tiempo).
- **Guardia** = aguante bloqueando. **Rotura de guardia** = estado temporal en el que acumulas Stun más fácil.
- Infusiones: Fuego > Rayo > Hielo > Sombra > Fuego.

## Cámara
- Distancia fija (sin zoom), se puede mirar arriba y abajo, encuadre con el personaje a la izquierda.
- Al cargar a alguien: apuntado con el mouse centrado.

## Monetización
- Skins **solo cosméticas**. Desde la beta todo se compra con monedas del juego; Robux más adelante, sin dar poder.

## Idiomas
- Español, inglés y portugués de Brasil. Respaldo: inglés. Se detecta el idioma y se puede cambiar en Ajustes.

## Trabajo
Reglas de trabajo entre las IA: [[Indicaciones para las IA]].
