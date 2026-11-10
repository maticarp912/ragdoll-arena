# Equilibrio de armas

Valores en `ReplicatedStorage/WeaponData.lua` (y la sensación en `WeaponData.Feel`). Todo es propuesta a calibrar jugando. 🟡 Sin comprobar en Studio.

| Arma | Ventaja real | Desventaja clara | Le favorece | Le cuesta |
|---|---|---|---|---|
| **Espada** | Consistente: combo fluido, fuerte rápido (0,5 s) y fintable, alcance medio (7) | Nada destaca: ni el más rápido ni el más fuerte | Cualquier situación; aprender el juego; castigar errores con el fuerte | Rivales que la superan en su terreno (Dagas de cerca, Estoque de lejos) |
| **Espadón** | Alcance (9,5) y barrido ancho (7,5): difícil de esquivar de lado. **Hiperarmadura en los golpes 2 y 3** (los golpes rápidos no lo frenan). Gasta ×1,6 de Guardia al bloquearlo. Empuja lejos (ring-out) | Lento y previsible (preparación larga = fácil de parrear o esquivar). Dash más corto y más caro (×1,25 de stamina) | Presionar a quien bloquea; controlar espacio; sacar rivales por el borde; 2v2 (golpea a dos) | Parry bien leído; Estoque manteniendo distancia; quedar sin stamina |
| **Dagas** | Las más rápidas; golpes que interrumpen; dash más largo y barato (×0,75) | Alcance corto (5), poca Guardia (80), casi sin empuje: no sacan a nadie de la arena | Pegarse al rival, cortar sus preparaciones, perseguir | Hiperarmadura del Espadón y la Maza; rivales que mantienen distancia |
| **Estoque** | Mucho alcance frontal (10, fuerte 11); **golpe en la punta +25 %**; la Puntada atraviesa el bloqueo | Caja estrecha (2,5): de lado falla. Poco Stun y poco empuje | Mantener distancia y castigar a quien avanza en línea recta | Rivales que se mueven de lado o se pegan (Dagas) |
| **Maza** | **Destroza la Guardia** (×2 de gasto) y acumula mucho Stun; Machaque imbloqueable; hiperarmadura en el 3º golpe | Lenta, alcance corto (6,5) y dash pesado (×1,25 de stamina) | Romper guardias; derribos por Stun; rivales que solo bloquean | Rivales que esquivan y castigan su recuperación larga |

## Por qué el Espadón no se arregló solo con daño
Su daño subió poco (17/19/26). Lo que cambia su papel es el alcance y el barrido, la hiperarmadura en el combo, la presión sobre la Guardia y el empuje hacia el borde. Su precio es ser previsible: la preparación larga se ve venir y se castiga con parry o esquiva.

## Parry, Guardia y rotura de guardia (CombatConfig)
- **Parry**: detiene el ataque; el atacante se tambalea solo **0,45 s** (antes 0,9) y recibe poco Stun. Quien parrea tiene **0,7 s de contraataque** con +20 % de daño.
- **Guardia**: aguante bloqueando; cada golpe bloqueado la gasta según el arma que golpea.
- **Rotura de guardia**: tambaleo corto (0,6 s) y luego **2,4 s sin poder bloquear**, durante los que el **Stun entra ×1,5**.

## Etapa 8 (9/11)
- Vida +35 %: Espada 243, Espadón 290, Dagas 216, Estoque 230, Maza 317.
- Stamina por golpe (básico / fuerte): Espada 6 / 20, Espadón 10 / 28, Dagas 4 / 14, Estoque 5 / 16, Maza 11 / 30. Un combo completo de espadón cuesta 30; uno de dagas, 12.
- Dash 12 studs (antes 16). Cargando a un derribado: velocidad ×0,6 (×0,45 cargando el lanzamiento). Lanzamiento ~30 % más corto.
- Fijar objetivo: hasta 28 studs.
- **Alcance del espadón con la hoja nueva de Gemini** (6,0 → 7,6 studs): se mantiene el alcance actual (combo 9,5, fuerte 10). Desde el centro del personaje, brazo + hoja nueva miden ~9,6 studs: con la hoja vieja el golpe llegaba más lejos de lo que se veía y ahora coincide. No hay ventaja oculta. (La propuesta de Gemini usaba campos que no existen en `WeaponData`.)
- **Maza 30 % más grande** (pedido del usuario): todo el modelo escala ×1,3 (`WeaponBuilder.ClassScale`). Alcance ajustado de forma explícita para que el golpe coincida con lo que se ve: combo 6,5 → 7 y fuerte 7 → 7,5. Sigue siendo la más corta después de las dagas.
- **Ritmo de combate (9/11, tarde)**: esquiva cada 0,5 s y cancelable tras el impacto de un básico o patada; buffer de M1 0,35 s. Bloquear regenera stamina al 35 %. Lanzamiento cargado máximo 52 (antes 67).

## Matriz de arquetipos (propuesta de Gemini, corregida por Claude, 9/11)
Sirve para hablar de diseño: cómo gana cada arma. Los números de referencia siguen siendo los de `WeaponData`.

**Columnas:**
- **TTK:** tiempo para matar a una Espada (243 de vida) solo con combos que aciertan todos. Es teórico.
- **Empuje del fuerte:** decide el ring-out, que en este juego elimina al instante. Pesa tanto como el TTK.

| Arma | Arquetipo | Alcance (ancho) | Costo del dash | TTK | Desgaste de guardia | Empuje del fuerte | Cómo gana | Estado |
|---|---|---|---|---|---|---|---|---|
| Espada | Todo terreno | 7 (5) | ×1,0 | ~11,1 s | ×1,0 | 26 | Se adapta y castiga los errores de las armas extremas. | 🟢 Es la base de comparación. |
| Dagas | Presión de cerca | 5 (4) | ×0,75 | ~9,5 s | ×0,9 | 12 | Pegarse al rival y abrumarlo con velocidad (impacto a los 0,15 s). | 🟡 Con ping, casi imposibles de leer. Casi no sacan a nadie de la arena. |
| Estoque | Control de distancia | 10 (2,5) | ×0,9 | ~9,0 s (~7,2 s en la punta) | ×0,9 (su fuerte atraviesa el bloqueo) | 20 | Mantener al rival en la punta. | 🟠 Fuerte, pero no «OP»: es angosto, falla de costado, tiene 230 de vida y empuja poco. El problema real es que atraviesa el bloqueo y además tiene el mayor alcance. |
| Espadón | Intercambio de golpes | 9,5 (7,5) | ×1,25 | ~11,3 s | ×1,6 | **55** | Hiperarmadura: gana los intercambios y empuja hacia el borde. | 🟢 Sano. Probablemente la mejor arma para ring-out. Vigilarla en la beta. |
| Maza | Tanque y rompe-guardias | 7 (5) | ×1,25 | ~15,8 s | ×2,0 (y el fuerte aturde 85) | 36 | Romper la guardia y la resistencia, fuerte imbloqueable, empujar afuera. | 🟡 Floja contra quien esquiva, aunque es la que más vida tiene (317) y cada esquiva del rival gasta resistencia. |

### Cambios a probar en la 0.2 (con datos de la beta)
1. **Estoque:** fallar un golpe gasta más resistencia. Castiga el «retroceder y pinchar» sin quitarle su identidad.
2. **Dagas:** más tiempo entre el golpe 2 y el 3, para dejar una ventana de parry. El primer golpe se mantiene en 0,15 s.
3. **Maza:**
   - si entra el combate direccional: un poco de seguimiento del rival en el golpe lateral;
   - si no: un barrido más ancho en el golpe 3.

## Diseño 0.2 direccional — aclaraciones pendientes (9/11)
Propuestas de diseño, NO cambios a WeaponData ni pruebas en Studio. Ver [[Diseño Combate PvP Direccional Roblox]]. Conservar identidad por arma, pero probar Espada primero antes de trasladar todos los números de la beta.
- La idea de Maza superior imbloqueable se propone limitar a su especial/fuerte con aviso propio; no aplicar por defecto a todos los básicos superiores.
- Estoque: comparar tres guardias con estocadas estrechas; su especial de penetración necesita ser distinguible y no invalidar todas las coberturas.
- Dagas: agilidad de cambio no equivale a ataque sin anticipación; estudiar lectura con ping. Espadón mantiene alcance/empuje y compromiso.
- No aumentar velocidad de defensa ni ventana de parry por ser celular; propuesta de misma regla y compensación acotada, pendiente de validar con mando conectado al teléfono.
**Implementado:** sin cambios. **Comprobado en Studio:** sin pruebas nuevas. **Pendiente:** aprobación, prototipo y mediciones por arma/dispositivo.

## Propuesta de números para la 0.2 (Claude, 10/11) — pendiente de aprobar
**Pedido del usuario:**
- más alcance para todas las armas;
- reforzar la maza y bajar las dagas y el estoque;
- las armas grandes se sienten muy débiles y hay mucha diferencia de velocidad.

Lo habló con Gemini Pro desde el celular, sin acceso al vault ni al código. Estos números salen de `WeaponData`.

**Objetivo:** todas las armas en una franja de **20 a 24 de daño por segundo** en combo. Las grandes compensan su lentitud con empuje, aturdimiento e hiperarmadura, no con menos daño. La espada (21,9) es la referencia.

**Alcance:** el general sube con `CombatConfig.Directional.ReachMult = 1,25`. Las armas grandes además suben su alcance propio:

| Arma | Daño combo (antes → propuesta) | Duración por golpe (antes → propuesta) | Daño por segundo (antes → propuesta) | Alcance propio (antes → propuesta) | Otros |
|---|---|---|---|---|---|
| Espada | 11·12·16 (sin cambio) | 0,55·0,55·0,68 (sin cambio) | 21,9 | 7 | Referencia. |
| Espadón | 17·19·26 → **19·21·29** | sin cambio | 21,5 → **23,9** | 9,5 → **10** | Fuerte: 45 → **50**. |
| Maza | 13·15·20 → **17·19·26** | sin cambio | 15,4 → **19,9** | 7 → **8** | Golpe 3 más ancho (5 → 6,5). Fuerte: 40 → **46**. |
| Dagas | 7·8·12 → **6·7·11** | 0,32·0,32·0,42 → **0,32·0,40·0,48** | 25,5 → **20,0** | 5 | El primer golpe sigue en 0,15 s. El 2 y el 3 impactan más tarde (0,15 → **0,19**, 0,21 → **0,25**), así queda lugar para el parry. |
| Estoque | 9·11·15 → **8·10·14** | 0,40·0,40·0,50 → **0,40·0,45·0,55** | 26,9 → **22,9** | 10 | Punta: +25 % → **+15 %** (en la punta queda en 26,3, antes 33,7). Fallar un golpe gasta +50 % de resistencia. |

**Por qué:**
- La maza era la única muy por debajo de la franja (15,4).
- Las dagas y el estoque estaban por arriba, y además son las más rápidas. Con ping eso se siente injusto.
- Las grandes ganan daño **por golpe**, que es lo que se siente al pegar (encaja con el pedido de sensación de combate).

**A medir en la beta:** qué arma eligen y cuál gana más. La 0.2 debería guardar esa estadística.
