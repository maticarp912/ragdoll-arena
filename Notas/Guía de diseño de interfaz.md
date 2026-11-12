# Guía de diseño de interfaz (12/11/2026)

Fuente: skill «anti-ui-slop» (F:\RobloxJuegos\skills\anti-ui-slop) y la guía de diseño que pasó el usuario. Adaptado a Roblox.

## Antes de tocar una pantalla
1. Leer la pantalla, quién la usa y cuál es su acción principal (ej.: Tienda → comprar; Ruleta → girar).
2. Reusar `UiTheme` (colores, fuentes, `FrameArt` de plata), `UiAssets` y `BalancePill`. No inventar estilos sueltos.
3. En un rediseño grande, escribir antes un plan corto: 4–6 colores con hex, tipografía y su rol, un boceto ASCII del layout y qué elemento es el memorable.
4. Revisar el plan: si se parece a lo que saldría para cualquier juego, cambiarlo y decir por qué.

## Reglas
- Un solo elemento llamativo por pantalla; el resto, sobrio. Antes de terminar, sacar un adorno.
- Bordes, numeración y separadores solo si informan algo (numerar solo secuencias reales, como el tutorial).
- Evitar los tics de diseño generado: etiquetas en MAYÚSCULAS sobre todo, «A · B · C» para metadatos, «→» en los botones, todo en tarjetas iguales con la misma sombra, degradados de adorno.
- Animación solo para responder a una acción del jugador o para un único momento (abrir el cofre, girar la ruleta).
- Textos: lo que el jugador entiende, voz activa y botones que dicen lo que hacen («Comprar 400 monedas», no «Confirmar»). El mismo nombre en todo el flujo.
- Errores claros y sin disculpas: qué pasó y cómo seguir. Pantalla vacía = invitación a actuar.
- Siempre cubrir los estados: cargando, vacío, error, éxito, desactivado y sin permiso (por ejemplo, azar pago restringido).
- No inventar datos para llenar (estadísticas, actividad o reseñas falsas).

## Antes de entregar
- Probar en Studio por MCP: captura en PC y con tamaño de celular; arreglar recortes, superposiciones y botones que no responden.
- Mando: foco visible (`GuiService.SelectedObject`).
- `node tools/check_lua.js .` sin errores.
