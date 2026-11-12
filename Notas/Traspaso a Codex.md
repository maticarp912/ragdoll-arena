# Traspaso a Codex (11/11/2026 21:30)

Claude le pasa la integración a Codex: a Claude le quedan pocos tokens. Codex puede editar todo el proyecto, probar en Studio (MCP), commitear y hacer push.

## Cómo arrancar Codex
- App de Codex: abrir la carpeta `F:\RobloxJuegos\Plataforme 2v2` (ya es de confianza). Lee `AGENTS.md` solo.
- CLI: `codex --profile ragdoll` (puede editar la carpeta y usar la red para `git push`; pide permiso para lo de afuera).
- Roblox Studio abierto con el plugin MCP prendido.

## Estado
- **0.2 publicada** el 11/11/2026 como versión 7 de «[BETA] Dark Fantasy Plataforme 2v2 1v1 PVP». Detalle en [[Publicación 0.2]] y [[Versión 0.2]].
- Último commit de Claude: ver `git log`.

## Falta comprobar (usuario + Codex)
1. Juego publicado: ciudad, partida, guardado de almas/skins al salir y volver.
2. Compra barata (3 tiros o 400 monedas) llega y queda guardada. Regalo VIP de bienvenida.
3. `Lighting.Technology` = Future en el place publicado (desde la barra de comandos no se puede; con MCP o a mano).
4. Calibrar marcos de plata y barras del HUD con capturas (`UiTheme.FrameArt`, `UiAssets` hud_bar_*).
5. Página del juego: descripción, miniaturas y cuestionario ([[Publicación 0.2]]).

## Próxima versión (0.3), pendientes grandes
- Ruleta nueva según `Referencias 0.2/ruleta .jpg`.
- Sangrado de dagas; animaciones mocap de dagas y estoque.
- Hand Arena; modo ranked con Elo; leaderboards en la plaza; ciudad tipo pueblo; cielo.
- Mallas de Blender.

## Cómo publicar
- Normal: `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`, abrir en Studio y publicar sobre la experiencia existente.
- Si se traba o para actualizar solo scripts: con el MCP de Studio se pueden reemplazar los scripts directo en el place publicado. Alternativa: `tools/make_pack.js` (pasos en [[Publicación 0.2]]).

## Para qué sirve el MCP de Studio
- Leer y editar el place abierto (scripts, partes, propiedades) sin regenerar el `.rbxlx`.
- Correr Luau en Studio y leer la Salida: probar cambios y encontrar errores solo.
- Iniciar y parar el modo Play para probar.
- Reemplaza el control de pantalla (más rápido y sin errores de clics).
