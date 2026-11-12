# Versiones en Studio

## Para abrir

- **Desarrollo local 0.3:** `F:\RobloxJuegos\Plataforme 2v2\Ragdoll Arena.rbxlx`. Es el único place local activo de Ragdoll Arena. Los scripts fuente se editan en el repositorio en F:.
- **Juego en línea:** la tarjeta «[BETA] Dark Fantasy Plataforme 2v2 1v1 PVP» de Roblox, place 91305058765116. Se actualiza al publicar desde Studio.
- **Plantilla y catálogo:** `F:\RobloxJuegos\Plantilla juegos de roblox\PlantillaRoblox.rbxlx` es la demo Cristal Rush para iniciar otros juegos. `F:\RobloxJuegos\Plantilla juegos de roblox\KitUI\CatalogoVisual.rbxlx` reúne pantallas y estilos reutilizables de esa plantilla.

## Copias anteriores

Quedaron en `F:\RobloxJuegos\Archivo Ragdoll Arena`:

- `Trabajo de Codex/Ragdoll 0.3 - prueba local.rbxlx`: la copia que se usó para probar la 0.3. Es la base del place local activo.
- `Trabajo de Codex/Ragdoll preview benchmark.rbxlx`: prueba del rendimiento de Cofres y Tienda.
- `Places anteriores/Ragdoll Arena - local anterior.rbxlx`: el place local previo a la unificación.
- `Recuperaciones Studio`: archivos de recuperación de Ragdoll que estaban en C:.
- `Archivos trasladados.csv`: inventario de origen, destino y huella SHA-256.

Studio puede conservar accesos viejos en Recientes. Para ir al archivo actual, abrilo desde F:.

## 12/11/2026 17:45 (Claude)
- **Ragdoll Sword pilot test.rbxlx** (`F:\RobloxJuegos\Archivo Ragdoll Arena`) quedó guardado con los 109 scripts del commit 0895f60: es la copia para probar lo último.
- **Ragdoll Sword pilot playable.rbxlx** tiene scripts viejos. No copiar de ahí al proyecto.
- MocapClips supera los 200.000 caracteres: por MCP solo se carga con ScriptEditorService:UpdateSourceAsync (Source da error). Conviene partirlo en varios módulos antes de crecer más.

## Mocap por arma (punto A)
- **Ragdoll Sword pilot test.rbxlx** quedó guardado por MCP con el índice y los cuatro módulos. Es la copia local que se usó para probar los fuertes de Espada después de la división.
- El módulo más grande tiene 86.747 bytes. El detalle de las pruebas y las capturas está en [[Versión 0.3#Mocap por arma (punto A)]].
