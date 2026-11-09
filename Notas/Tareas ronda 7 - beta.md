# Tareas ronda 7: preparar la beta (9/11, 19:00)

> **Para Codex (ChatGPT). Modelo: Sol, High.** En esta ronda Codex reemplaza a Claude como **integrador**: puede tocar cualquier archivo de código, regenerar el place y hacer commits.
> Contexto: [[Reparto etapa 8]], [[Contratos etapa 8]], [[Referencia LihFolk]], [[Peticiones del usuario]], tu propio reporte de la ronda 6 en [[Reporte Codex etapa 8]].

## Reglas
- `node tools/check_lua.js .` tiene que dar OK.
- El revisor LihFolk (comando en [[Referencia LihFolk]]) tiene que dar 0 errores y 0 avisos.
- Los valores numéricos van en los módulos de datos (`Economy`, `CombatConfig`, etc.), no sueltos en el código.
- Textos nuevos en `LocaleCodex.lua`, con las mismas claves en ES, EN y PT-BR.
- **Git (la regla C0b se cambia solo en esta ronda):** podés hacer commits en `main` y `git push`. Hacé un commit por tarea, con un mensaje claro en castellano. No reescribas el historial: nada de `reset --hard`, `push --force` ni `rebase`.
- Al terminar: `node tools/make_rbxlx.js . "Ragdoll Arena.rbxlx"`.
- Reporte en `Notas/Reporte Codex etapa 8.md`, sección «Ronda 7». Separá implementado / comprobado / pendiente de Studio, y anotá lo que el usuario tiene que probar.
- Actualizá también `Notas/Peticiones del usuario.md` y `Notas/Registro de cambios.md`.

## 0. Integrar el trabajo de Gemini (ronda 6A)
Gemini terminó fachadas y tejados. Sus cambios están sin commit: `ServerScriptService/LobbyBuilder.lua`, `ReplicatedStorage/CityConfig.lua` y `Notas/Reporte Gemini etapa 8.md`.
- Revisá el diff con `git diff`. Comprobá:
  - que solo tocó las funciones de edificios;
  - que se respeta el presupuesto de ~3.500 piezas;
  - que no hay piezas superpuestas en el mismo plano;
  - que siguen intactos los ganchos de `CityProps`/`CityNPCs`, los círculos de cola, la puerta y la armería.
- Si está bien, hacé el commit tal cual: «Gemini ronda 6: fachadas y tejados».

## 1. Nada con Robux por ahora (pedido del usuario)
«Por ahora monedas del propio juego, no dejes nada en Robux.»
- Todo lo que hoy tenga `currency = "Robux"` pasa a monedas, con un precio coherente con los demás artículos de su misma rareza. Hoy son la skin `Requiem` y las auras `WatchingEyes` y `PaleFracture`. Están en `Skins`, `Auras` y los módulos de datos relacionados: buscá con `grep -rn Robux`.
- En la tienda no tiene que quedar ningún texto, icono ni botón de Robux.
- Dejá intacto el código de `ProcessReceipt` y de recibos, para cuando se vuelva a vender con Robux. Solo que ningún artículo lo use.

## 2. Arreglos de tu revisión (ronda 6) antes de la beta
1. **Hallazgo 1: Studio no escribe el perfil real.**
   - En Studio, el DataStore tiene que tener otro nombre (por ejemplo `RagdollArena_v2_Studio`). Se decide con `RunService:IsStudio()`; los nombres van en `Economy`.
   - Lo mismo para los `OrderedDataStore` de `LeaderboardService`.
2. **Hallazgo 2: guardado final con reintentos.** `PlayerData.save(player, true)` (al salir y en `BindToClose`):
   - Reintenta `persist` hasta N veces, con espera creciente. N y la espera van en `Economy`.
   - `BindToClose` espera como máximo ~25 s en total.
   - `PlayerRemoving` borra el `cache` solo después de los intentos.
   - Si todos fallan, `warn` con el UserId.
3. **Hallazgo 3: límite de frecuencia en la tienda.**
   - `SelectWeapon`, `SelectInfusion` y `Equip` no hacen nada si eso ya está elegido.
   - Ponele un límite por jugador a `ShopRF` y a `DebugRemote` (por ejemplo, 1 acción cada 0,25 s, valor en `Economy`), y limpiá ese estado al salir el jugador.
4. **Hallazgo 4: carga abortada.** Si el jugador sale mientras `PlayerData.load` espera:
   - no publiques el `cache`;
   - liberá el bloqueo de sesión recién tomado (un `UpdateAsync` que ponga `Session = nil` si el id es el nuestro).
5. **Hallazgo 6: direcciones y objetivos.**
   - `validDir` en `CombatService` rechaza componentes infinitos y largos absurdos.
   - `validTarget` exige que el objetivo esté en `workspace` y tenga la etiqueta `Combatant`.
6. Los hallazgos 5, 7, 8 y 9 quedan para después de la beta. Anotalos como pendientes en Peticiones.

## 3. Comprobar
- Pasá `check_lua` y LihFolk, regenerá el place, y hacé commit y `git push`.
- En el reporte, dejá una lista de pruebas en Studio para el usuario:
  - Play solo: la tienda compra auras y la skin con monedas.
  - Servidor y clientes con 2 jugadores: partida 1v1 completa.
  - Device Simulator: iPhone.

## Ya hecho por Claude (no repetir)
- Prueba en Studio del 9/11, 18:45: funcionan la partida 1v1 con 2 jugadores, las 5 armas, el celular y el emulador de mando.
- Arreglo de «vivo» en 2v2: `Eliminated` + estado Dead en `MatchService` y `Controls`.
- `saveSoon` y la validación de tipo de `action`.
- Repositorio en GitHub: `maticarp912/ragdoll-arena`, privado.
