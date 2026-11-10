# Tareas ronda 5 — Gemini (9/11, 17:35)

> Prompt completo para Gemini. **Modelo: Gemini 3.8 Flash, Medium** (son ajustes concretos; la Mano completa queda para más adelante con Argon).
> Archivos tuyos: `ServerScriptService/ArenaBuilder.lua`, `ReplicatedStorage/ArenaConfig.lua`, `StarterPlayer/StarterPlayerScripts/ArenaBackdrop.client.lua`, `StarterPlayer/StarterPlayerScripts/Arena.client.lua`. **No toques la interfaz**: ahora es de Codex (ronda 4) y la está editando.
> Reglas de siempre:
> - No regeneres `Ragdoll Arena.rbxlx`.
> - `node tools/check_lua.js .` tiene que dar OK.
> - Reporte en `Notas/Reporte Gemini etapa 8.md`, sección «Ronda 5».

Claude probó en Studio tus 4 arenas nuevas (ronda 3B). El aislamiento a 4.500 studs y los bordes temáticos funcionan, y **el Cañón quedó muy bien** (coliseo con gradas y braseros, se lee perfecto). Ajustes:

1. **Arenas demasiado oscuras en partida**: con la noche global (más oscura desde el 9/11), la Mano y el Bosque casi no se ven y el suelo se lee mal.
   - Subí la luz **solo en la arena y solo con `InMatch`**: brillo o exposición de tu `ArenaTone` (ColorCorrection) por variante.
   - Agregá algunas luces locales cálidas o frías alrededor del borde de la plataforma (≤ 6 `PointLight` por arena, sin sombras), como los braseros del Cañón.
   - El suelo de la plataforma tiene que leerse claro desde la cámara de combate.
2. **Templo**: los anillos y tiras de jeroglíficos salen en **verde lima neón** muy chillón.
   - Tienen que ser **dorados** como en `referencias\arena 3.jpg`: oro cálido (≈ 255, 190, 90) en `Metal` o `Foil`, y solo un brillo `Neon` sutil y fino en algunas líneas. Menos neón en general.
   - Revisá que las columnas no tapen la cámara cerca del borde.
3. **Mano**: todavía **no se entiende como mano**; los dedos parecen rocas con musgo arriba.
   - Para la beta, **sacala de `ArenaConfig.Variants`** (que roten Bosque, Cañón y Templo) y dejá su código como está, para rehacerla más adelante con Argon.
4. **Desenfoque al caer**: verificá que `ArenaFallBlur` y `ArenaFallColor` se apaguen siempre al reaparecer, al terminar la partida o si el jugador sale; que no quede la pantalla borrosa en la ciudad.
