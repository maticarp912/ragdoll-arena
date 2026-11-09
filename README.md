# Ragdoll Arena

Juego de Roblox PvP 1v1 y 2v2 con físicas ragdoll, estilo dark fantasy.

## Empieza aquí
| Archivo | Para qué sirve |
|---|---|
| **`PROMPT_INICIAL_OPUS.md`** | El mensaje que se pega al empezar la sesión con Opus |
| **`RESUMEN_PROYECTO.md`** | Todo el diseño, reglas, arquitectura, plan por fases y decisiones |
| **`ASSETS_LISTA.md`** | Checklist de animaciones, sonidos y renders (con claves y orden de entrega) |

## Estado
- **Demo jugable (~70%)**: combate completo, 5 armas modeladas según el arte, animaciones procedurales, ragdoll con esqueleto, agarrar/cargar/lanzar, sonidos (Creator Store), VFX, tienda de skins con vistas 3D y menú de controles con mando.
- **Pendientes y errores conocidos: ver `TAREAS_CODEX.md`.**
- Ojo: Roblox usa el *Avatar Joint Upgrade* (articulaciones `AnimationConstraint`); el código soporta ambos rigs.
- Assets: todos los IDs van en `ReplicatedStorage/Assets.lua` (0 = placeholder). Colores y fuentes en `Theme.lua`. Reglas de combate en `CombatConfig.lua`; números de armas en `WeaponData.lua`.

## Carpetas
- `ReplicatedStorage/`, `ServerScriptService/`, `StarterPlayer/StarterPlayerScripts/` — scripts de Luau (estructura compatible con Rojo).
- `_backup_v_anterior/` — copia del código del diseño anterior (elementos y ulti). No entra en el `.rbxlx`.
- `tools/make_rbxlx.js` — genera `Ragdoll Arena.rbxlx` con los scripts ya colocados (requiere Node). Fuerza R15 y quita el Shift Lock.
- `tools/check_lua.js` — chequeo básico de sintaxis (bloques, paréntesis, strings y nombres sin declarar).
- `Ragdoll Arena.rbxlx` — lugar de Studio generado.

## Comprobar la sintaxis
```
node "F:\RobloxJuegos\Plataforme 2v2\tools\check_lua.js" "F:\RobloxJuegos\Plataforme 2v2"
```

## Generar y abrir el lugar de Studio
```
node "F:\RobloxJuegos\Plataforme 2v2\tools\make_rbxlx.js" "F:\RobloxJuegos\Plataforme 2v2" "F:\RobloxJuegos\Plataforme 2v2\Ragdoll Arena.rbxlx"
```
Abre el `.rbxlx` con Roblox Studio y prueba con **Test → Clients and Servers** (2 jugadores = 1v1, 4 = 2v2).

## Nota
Nada se ha probado jugando todavía. Los errores de scripts se leen en `%LOCALAPPDATA%\Roblox\logs\*_Studio_*_last.log` (buscar `CreatorError`).
