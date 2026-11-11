# Cofres: probabilidades, vista previa y regulación — Codex

> **Modelo: gpt-6.1-sol, high.** Agregado al encargo «Almas, monedas, títulos y party». Si Codex todavía está con ese, pegalo cuando termine (o en el mismo chat como continuación). Escrito por Claude el 11/11/2026.

---
Continuación del encargo de almas y monedas (`Notas/Almas, monedas, títulos y party - Codex.md`). Mismas reglas y archivos.

**Pedido del usuario:**
- **Vista previa.** Antes de abrir, cada cofre tiene que poder mostrar qué puede salir y con qué probabilidad: una skin mala, o una legendaria con el 0,5 %.
- **Formato de las probabilidades.** Como máximo 3 cifras y sin ceros a la derecha: 3,2 % · 12,5 % · 0,5 % · 100 %.
- **Dificultad.** Que sea difícil sacar legendarias y exclusivas, pero que abriendo muchos cofres se pueda.

**Tareas:**
1. **Vista previa por cofre** (`Rewards.client.lua`):
   - En cada tarjeta, un botón «Ver recompensas» (ícono de ojo) junto a «Abrir».
   - Abre una ventana de ese cofre solo. Arriba, las probabilidades por rareza con su color. Debajo, cada premio posible (skin con nombre y miniatura, almas, monedas, multiplicadores), con su probabilidad individual.
   - Si la suerte está activa, mostrar el antes y el después.
   - También: la conversión de repetidas (40 %) y la garantía («Legendaria asegurada en N cofres»).
   - Que se pueda abrir el cofre desde esa ventana.
2. **Formato.** Usá `ReplicatedStorage/Format.lua` → `Format.percent(fraccion, idioma)` (lo hizo Claude; ya cumple la regla) en **todas** las probabilidades del juego: cofres, ruleta y tienda.
3. **Exclusivas aparte.** Las skins de la ruleta (`roulette = true`, las del Eclipse Carmesí) son un escalón propio, «Exclusiva», por encima de Legendaria en la tabla y con su color (usá `UiTheme.Rarities.Mythic`).
4. **Probabilidades nuevas** (reemplazan a las actuales; los cofres 1 y 2 siguen la regla del 10 % y el 17 % de skin):

   | Cofre | Común/Rara | Épica | Legendaria | Exclusiva | Garantía |
   |---|---|---|---|---|---|
   | 1 (almas) | skin 10 %: Rara 8 % | 1,8 % | 0,2 % | — | — |
   | 2 (almas) | skin 17 %: Rara 12 % | 4 % | 0,9 % | 0,1 % | Épica cada 10 (la de hoy) |
   | 3 Tormenta (monedas) | Rara 70 % | 26 % | 3,5 % | 0,5 % | — |
   | 4 Tormenta (monedas) | Rara 40 % | 50 % | 9 % | 1 % | — |
   | 5 Tormenta (monedas) | — | 75 % | 22,5 % | 2,5 % | — |
   | 6 Eclipse (monedas) | — | 55 % | 40 % | 5 % | Legendaria cada 10 · Exclusiva a los 40 |

   - Las garantías se guardan por cofre en el perfil (como `relicPity`) y se ven en la vista previa.
   - **Resultado esperado** (simulación de Claude con esta tabla):
     - cofre 1: una legendaria cada ~500 cofres, nunca exclusiva;
     - cofre 3: legendaria cada 25 y exclusiva cada 200;
     - cofre 5: legendaria cada 4 y exclusiva cada 40;
     - cofre 6: legendaria cada ~2 y exclusiva cada ~17 (como máximo 40).
   - Hoy el cofre 6 da una exclusiva cada 3 o 4, porque es 100 % legendaria y 5 de 18 son exclusivas: eso hay que cortarlo.
5. **Prueba de regulación.** Con los módulos reales y servicios simulados, abrí 100.000 cofres de cada tipo y anotá en el reporte la tabla de lo que salió (porcentajes reales contra los esperados, cofres promedio hasta la primera legendaria y la primera exclusiva, almas y monedas promedio por cofre). Si algo se desvía más de un 10 % de lo esperado, corregilo.
6. Mantener las probabilidades exactas que muestra la interfaz iguales a las que usa el servidor (misma función).
