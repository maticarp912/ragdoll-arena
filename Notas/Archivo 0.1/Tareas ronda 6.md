# Tareas ronda 6 (9/11, 17:55)

Contexto: [[Reparto etapa 8]], [[Contratos etapa 8]], [[Peticiones del usuario]].

Reglas de siempre:
- Tocá solo tus archivos.
- No regeneres `Ragdoll Arena.rbxlx`.
- `node tools/check_lua.js .` tiene que dar OK.
- **Nuevo (regla C0):** pasá también el revisor LihFolk antes de terminar. El comando está en [[Referencia LihFolk]].
  - Tiene que dar 0 errores. Hoy da 0 errores y 0 avisos en 71 archivos.
  - Cada aviso nuevo en tus archivos se arregla o se justifica en el reporte.
- **Nuevo (regla C0b): la carpeta ahora es un repositorio de Git.** Podés mirar tus cambios con `git status` y `git diff`. No hagas commits, no cambies de rama ni deshagas cambios con Git: eso lo hace Claude al integrar.
- Textos nuevos en tu archivo de idioma, con las mismas claves en ES, EN y PT-BR.
- Reporte con implementado / comprobado / pendiente de Studio.
- **Guías:** en [[Referencia LihFolk]] está cómo buscar en las guías de LihFolk sin Python. Citá en el reporte el título de la nota que uses. No copies su contenido al vault (licencia).

Claude integró y probó en Studio las rondas 4 y 5.
- **Funciona:**
  - La interfaz: botones a la izquierda, RANKED, Armería, HUD vertical que se ve en batalla o con objetivo fijado, y vista previa de auras sobre el propio personaje.
  - Los caminos y la vida de la ciudad.
  - El Templo dorado y la luz de las arenas.
- **Arreglado por Claude:**
  - `Localization` fallaba si la pantalla de carga lo pedía antes de que llegaran los idiomas, y rompía toda la interfaz.
  - La vista previa de auras recortaba el panel.

---

## A. Gemini — fachadas y tejados de la ciudad (modelo: **Gemini 4 Argon, High**)
Archivo que pasa a ser tuyo en esta ronda: `ServerScriptService/LobbyBuilder.lua`. **Solo** las funciones de edificios (`building`, `windowsOnFace`, `fillBlock`, `clockTower`) y `ReplicatedStorage/CityConfig.lua` (colores y medidas de edificios). No toques el resto de `LobbyBuilder`: suelo, ganchos de `CityProps` y `CityNPCs`, colas, puerta, armería, guía.

**Pedido del usuario:** pueblo de juego de rol **dark fantasy** como en `referencias\02_lobby_pueblo_noche.webp` y `03_lobby_calle_taberna.webp`. Hoy los edificios son cajas de ladrillo con ventanas planas.
- **Tejados con forma**: a dos aguas o cónicos, con aleros que sobresalen, tejas oscuras (pizarra o madera), algunas buhardillas y chimeneas.
- **Fachadas**: entramado de madera (vigas oscuras sobre revoque claro) en la planta alta y piedra en la baja; puertas con arco; ventanas con marco, alféizar y algunas con postigos; un par de balcones o voladizos; maceteros y faroles de pared.
- **Variedad**: que no haya dos fachadas iguales seguidas (alturas, anchos y colores dentro de la paleta).
- Mantené la planta de las manzanas (`CityConfig.Blocks`), las calles libres y las ventanas encendidas con luz cálida (ámbar).
- **Presupuesto**: la ciudad entera hoy tiene ~2.000 piezas, más ~1.400 de `CityProps`. Los edificios nuevos no deberían pasar de ~3.500 piezas en total. Detalles chicos sin colisión.
- **Sin caras superpuestas en el mismo plano**: el piso de la ciudad ya está en capas (`CityConfig.FloorLayerStep`).
- **Guías de LihFolk recomendadas**:
  - Skill `lihfolk-worldbuilding` y las carpetas `06 World Building and Art` y `33 Level Design`, para composición, siluetas y variedad de fachadas.
  - Skill `roblox-performance-audit`, para el presupuesto de piezas en celular.

## B. Codex — revisión técnica antes de la beta, solo lectura (modelo: **Sol, Medium**)
No edites archivos de código. Escribí los hallazgos en `Notas/Reporte Codex etapa 8.md`, sección «Ronda 6», con archivo, línea, problema y arreglo propuesto, ordenados por gravedad.

**Herramientas**: ver [[Referencia LihFolk]].
- Empezá pasando el revisor LihFolk en modo `-Scan` (el comando está en esa nota). Hoy da 0 avisos; si te da otra cosa, anotalo.
- El revisor solo encuentra patrones simples, así que **no alcanza**. Para cada punto, usá como lista de control la sección `## Checklist` de las guías de LihFolk:
  - `roblox-secure-remotes` y `roblox-anti-exploit-review` para el punto 2.
  - `roblox-datastore-safety` para el punto 4.
  - `roblox-monetization-compliance` para recibos y productos.
  - `roblox-performance-audit` para fugas y rendimiento.
  - Citá la nota en cada hallazgo.

**Ya revisado por Claude (9/11, 18:20), no lo repitas**:
- Los remotos `Queue`, `Missions` y `Settings` ya comprueban el tipo de `action`.
- `Settings` y la equipación de auras ya no guardan en cada petición: usan `PlayerData.saveSoon`, un solo guardado cada 6 s (`Economy.SaveDebounce`).
- Sí revisá si queda **otro** remoto que guarde o haga trabajo caro en cada llamada sin límite de frecuencia.

Buscá sobre todo:
1. **Carreras de carga en el cliente**: módulos que hacen `require(script.Parent.X)` o acceden a hijos sin `WaitForChild` y que pueden ejecutarse antes de que el contenido haya replicado. Claude encontró una de estas en `Localization`, que rompía toda la interfaz.
2. **Remotos sin validar**: tipos, rangos, frecuencia y objetos de otros jugadores en todos los `OnServerEvent` / `OnServerInvoke`.
3. **Fugas**: conexiones que no se desconectan al reaparecer o al salir (personajes, partidas, auras, efectos de ciudad).
4. **Datos**: caminos donde se puedan perder o duplicar monedas, compras o estadísticas (reaparición durante una compra, salir a mitad de partida, dos servidores).
5. **Partida**: qué pasa si un jugador sale a mitad de ronda en 1v1 y 2v2 (cola, `InMatch`, `Eliminated`, arena, resumen, monedas).
6. **Celular**: interfaces que dependan del ratón o del teclado sin alternativa táctil o de mando.
