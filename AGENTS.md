# Ragdoll Arena — instrucciones para Codex (y cualquier IA)

Desde el 11/11/2026 **Codex es el integrador principal**: escribe código, prueba en Studio, hace commits y push. Claude queda de apoyo.

Leer primero `Notas/Traspaso a Codex.md` (estado, pendientes y cómo publicar), después `Notas/Indicaciones para las IA.md`.

## Reglas
- Responder en español rioplatense.
- Cada pedido del usuario: una fila en `Notas/Peticiones del usuario.md` (fecha y hora de Argentina).
- Números en módulos de datos (`CombatConfig`, `WeaponData`, `Economy`, `Rewards`, `UiTheme`, `MonetizationConfig`…).
- **No cambiar la vida base** (decisión del usuario).
- Estados honestos: implementado ≠ comprobado en Studio.
- Antes de commitear: `node tools/check_lua.js .` sin errores.
- Git: rama `main`, repo `maticarp912/ragdoll-arena`. Autor de commits: identidad noreply (nunca el email del usuario). Mensajes en español, formato `área: qué cambió`.

## Estructura
- `ReplicatedStorage/`, `ServerScriptService/`, `StarterPlayer/StarterPlayerScripts/`, `ReplicatedFirst/`: código Luau (compatible con Rojo, ver `default.project.json`).
- `tools/make_rbxlx.js`: genera `Ragdoll Arena.rbxlx` desde los `.lua` (`node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`).
- `tools/make_pack.js`: genera `Paquete juego.rbxmx` para subir scripts a un place ya publicado.
- `tools/check_lua.js`: chequeo de sintaxis.
- `Notas/`: bóveda de Obsidian (fuente de verdad del diseño y estado).
- `Referencias 0.2/`, `referencias/`, `ui_assets/`, `sfx_subir/`, `modelos_armas/`: arte y fuentes.
- `_archivo/` (fuera de Git): backups y logs viejos. No leer.

## Roblox Studio MCP
Está conectado (`Roblox_Studio` en `~/.codex/config.toml`). Usarlo para leer el árbol del place, correr Luau en Studio, revisar la Salida y probar en modo Play, en vez de controlar la pantalla. Studio tiene que estar abierto con el plugin MCP prendido.
