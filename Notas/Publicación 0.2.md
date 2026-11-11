# Publicación de la 0.2 (11/11/2026)

Todo lo que va en la página del juego (create.roblox.com → tu experiencia). Copiar y pegar.

## 1. Antes de publicar (en Studio)
1. Cerrá sin guardar y abrí de nuevo `Ragdoll Arena.rbxlx` (la versión más nueva).
2. **No** dejes puesto `workspace:SetAttribute("StudioGrantPasses", true)` ni `StudioOwnerUserId`. Igual no funcionan fuera de Studio, pero mejor que no queden.
3. **Archivo → Publicar en Roblox como…** → elegí la experiencia existente «[BETA] Dark Fantasy Plataforme 2v2 1v1 PVP» (no crees una nueva, así se conservan visitas, pases y productos).
4. En **Configuración del juego → Seguridad**: «Habilitar acceso de Studio a servicios de API» encendido (para probar guardado en Studio; en el juego publicado el guardado funciona igual).

## 2. Nombre
`[BETA] Dark Fantasy Plataforme 2v2 1v1 PVP` (se mantiene).

## 3. Descripción (español + inglés)

```
⚔️ Duelos de fantasía oscura en arenas flotantes. Tirá a tu rival al vacío.

🗡️ COMBATE DIRECCIONAL
Atacá de arriba, izquierda o derecha y bloqueá del lado correcto. Parry perfecto, contragolpes, patadas al derribado y remates.

🔥 5 ARMAS, 5 ESTILOS
Espada, Espadón, Dagas, Estoque y Maza: cada una con su ritmo, alcance y fuerza.

✨ INFUSIONES
Fuego, Rayo, Hielo y Sombra. Encendé tu arma y ganá la pelea de infusiones.

🏆 PROGRESIÓN
Niveles, maestría por arma, títulos, colección de skins, cofres, ruleta diaria y misiones.

👥 1v1 y 2v2 · Jugá en party con un amigo · Bonus si jugás con amigos

🎮 PC, celular y mando.

Juego en BETA: ¡reportá errores y dejá tu like! 👍

—
⚔️ Dark fantasy duels on floating arenas. Knock your rival into the void.
Directional combat, 5 weapons, elemental infusions, titles, chests and daily rewards. 1v1 and 2v2, party with a friend. PC, mobile and controller.

Íconos / Icons: game-icons.net (CC BY 3.0)
```

## 4. Notas de la actualización (si se publican en un grupo, Discord o en la descripción)

```
🌑 ACTUALIZACIÓN 0.2 — LA PELEA CAMBIA

⚔️ Combate direccional: golpes de arriba, izquierda y derecha, con animación hacia cada lado.
🛡️ Espadón y Maza más rápidos y con contragolpe al bloquear.
🔥 Pelea de infusiones: la ventaja de elemento solo cuenta si los dos la tienen encendida.
💨 Stamina por arma, dash más barato y golpe instantáneo después del dash.
📦 6 cofres nuevos con vista previa de premios y probabilidades.
🎡 Ruleta con suspenso, tiros extra y premio semanal del Eclipse Carmesí.
🏷️ Más de 60 títulos y tarjeta de jugador.
👥 Party de 2 jugadores y bonus de +20 % con amigos.
💀 Skins de la 0.1 de vuelta y 36 skins de Tormenta.
🌙 Nueva interfaz, íconos y marcos; contador de FPS y efectos reducidos en Ajustes.
```

## 5. Imágenes
| Qué | Tamaño | Recomendación |
|---|---|---|
| Ícono del juego | 512 × 512 | El arte «Dark Fantasy 1v1 · 2v2 PvP» que ya tenías, o dos espadas cruzadas sobre el Eclipse Carmesí. Sin texto chico (en celular se ve diminuto). |
| Miniaturas (hasta 10) | 1920 × 1080 | 1) Choque de armas en la arena con el título. 2) Un 2v2 con infusiones encendidas. 3) Cofres abiertos y la ruleta. 4) Tienda/armería con skins del Eclipse. 5) Alguien cayendo al vacío. Sacalas en Studio (F12 o la herramienta de captura) con la cámara cerca, de noche, y efectos completos. |
| Video (opcional) | 30 s | Un duelo corto con parry, remate y caída al vacío. |

## 6. Configuración
- **Género:** Combate (Fighting / Lucha). Subgénero: PvP / Arena.
- **Dispositivos:** PC, Celular, Tablet y Consola (hay soporte de mando).
- **Jugadores por servidor:** 12 (el lobby se siente vivo y alcanza para varias partidas 2v2). Mínimo razonable: 8.
- **Servidores privados:** opcional. Si los activás, gratis o 50 Robux.
- **Idiomas:** español, inglés y portugués (los textos del juego ya están).

## 7. Cuestionario de madurez (Configuración → Cuestionario)
Respondé con la verdad. Para este juego:
- **Violencia:** armas blancas contra personajes estilo Roblox, sin sangre realista ni desmembramiento → violencia leve o moderada (fantasía).
- **Sangre:** el aura «Juramento de Sangre» y el efecto de sangrado son estilizados; si el cuestionario pregunta, «sangre leve / no realista».
- **Compras:** sí, hay compras con Robux.
- **Objetos aleatorios pagos:** **sí** (las monedas se compran con Robux y abren cofres). Las probabilidades están visibles en el juego.
- Chat, intercambios: sin intercambio ni regalos entre jugadores.

## 8. Después de publicar
1. Entrá al juego publicado con tu cuenta y comprá lo más barato (3 tiros o 400 monedas) para comprobar que llega y queda guardado al salir y volver.
2. Comprobá que tus datos (almas, skins) se guardan entre partidas.
3. Probá desde el celular (Mateito).
4. Mirá «Datos analíticos» en unos días: retención D1/D7 y compras.

## Si publicar se traba (11/11/2026, así se publicó la 0.2)
Publicar el .rbxlx entero se colgaba. Se hizo así:
1. `node tools/make_pack.js . "Paquete juego.rbxmx"` (todos los scripts en una carpeta __PACK).
2. En Studio, abrir la experiencia publicada desde Roblox → Archivo → Importar modelos Roblox → ese archivo.
3. En la barra de comandos, mover el contenido de __PACK a ReplicatedStorage, ServerScriptService, StarterPlayerScripts y ReplicatedFirst (comando en el historial de la sesión), y sacar __PACK.
4. Archivo → Publicar. Salió como versión 7.
