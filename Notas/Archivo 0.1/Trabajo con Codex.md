# Trabajo con Codex

## Cómo nos repartimos
- Codex lo manejas tú desde ChatGPT. Claude **no lo ejecuta**.
- Cuando Claude delega, deja un archivo `TAREAS_CODEX_N.md` en la carpeta del juego y un mensaje listo para copiar.
- Cada tarea dice **qué archivos puede tocar Codex** y **cuáles está tocando Claude**, para no pisarse.
- Al terminar, Codex escribe `REVISION_CODEX_N.md`. Claude lo revisa, integra y regenera `Ragdoll Arena.rbxlx`.

## Consumo de tokens
- **Codex ejecutado desde la sesión de Claude**: el trabajo de Codex se cobra a tu plan de ChatGPT/Codex, no a Claude. Claude solo gasta en lanzarlo, leer su resumen o su registro y revisar los archivos que cambió. Lo caro es esa revisión, y existe igual en los dos casos.
- **Codex manejado por ti**: Claude no gasta nada mientras Codex trabaja. Solo gasta cuando le pidas revisar el resultado. Además ves y diriges a Codex en tiempo real, sin que Claude espere ni lea registros largos.
- **Conclusión**: la diferencia para Claude es pequeña, porque solo ahorra lanzar y vigilar. Manejarlo tú es mejor para el control y para no saturar la sesión de Claude con registros.

## Abrir esta bóveda en Obsidian
1. Abre Obsidian.
2. En la pantalla inicial, elige **Abrir carpeta como bóveda** (Open folder as vault).
3. Selecciona `F:\RobloxJuegos\Plataforme 2v2\Notas` y empieza por [[00 Inicio]].
4. Si prefieres ver también los documentos del juego (`RESUMEN_PROYECTO.md`, tareas, revisiones), abre como bóveda la carpeta entera `F:\RobloxJuegos\Plataforme 2v2`. Obsidian solo muestra los `.md` e ignora los scripts.
