# Recompensas y retención 0.2 — 10/11/2026 (Argentina, UTC-3)

Pedido del usuario (D10): ruleta, cajas de suerte y todo el sistema de recompensas: **gancho para jugadores nuevos** y **motivos para volver a entrar**. Diseño de Claude sobre la investigación de Codex ([[Versión 0.2]], sección 12). Todos los números van en `Rewards.lua` y `Progression.lua` y son **iniciales**: se ajustan con la telemetría.
La moneda se llama **almas** (D5). Nada cuesta Robux en la 0.2 (D20). Ninguna recompensa da poder: solo apariencia, multiplicadores de progreso y títulos.

## 1. Los primeros 10 minutos (gancho)
| Momento | Qué pasa | Recompensa |
|---|---|---|
| Entra por primera vez | Bienvenida corta (2 pantallas como máximo) y **elige su primera skin** entre 3 comunes (elegir crea apego). | Skin elegida |
| Tutorial en el patio (3 pasos) | 1) atacar con dirección, 2) bloquear del lado correcto y hacer un parry, 3) patear a un muñeco derribado. Se puede saltear. | 100 almas por paso |
| Al terminar el tutorial | **Primera tirada de la ruleta, gratis**, con premio bueno garantizado (multiplicador ×2 de 30 min). | Engancha con la ruleta |
| Primera partida | Gane o pierda, pantalla de progreso animada. | Bonus «primera partida» 300 almas |
| Niveles 1 a 5 | Curva muy corta al principio: un nivel por partida, aprox. | Premio en cada nivel |
| Cadena «Primeros pasos» | 7 misiones simples a lo largo de los primeros días (jugar 3 partidas, ganar 1, hacer 5 parrys, equipar una skin, girar la ruleta, abrir una caja, llegar a nivel 5). | Al completarlas: **skin épica garantizada** |

## 2. Cada partida
- Almas y XP **siempre**, también al perder (hoy 220 / 65 almas). Un jugador que no se mueve no recibe nada (anti-AFK).
- **Primera victoria del día: ×2.**
- Pantalla de progreso al final: barra de XP que se llena, almas que vuelan al contador, misiones que avanzan, maestría del arma.

## 3. Cada día
- **Ruleta: 1 tirada gratis por día** (reinicio a las 00:00 de Argentina). Tiradas extra: hasta 3 por día con almas (precio creciente) y por misiones.
- **Racha de ingreso (calendario de 7 días):** 50 · 75 · 100 · 125 · 150 · 200 almas · el día 7 una **Caja de Reliquias**. Si falta un día, la racha **se pausa** en vez de volver a cero (un día de gracia por semana). No castigar por faltar.
- **3 misiones diarias** (ya existen), variadas: no solo ganar; también parrys, patadas, ring-outs.
- **Tienda «Destacado»** que cambia cada día (D12).

## 4. Cada semana
- **Premio grande de la ruleta** que rota cada lunes (semana 1: la espada de referencia; D15). Se muestra en 3D en la ciudad, en un pedestal, con cuenta regresiva.
- **Desafío semanal** (por ejemplo, 15 victorias o 40 parrys): Caja de Reliquias.

## 5. Largo plazo
- **Niveles 1 a 100** (D9): premio cada 5 niveles (almas) y cada 10 (caja); títulos en 25, 50, 75 y 100.
- **Maestría por arma:** niveles propios de cada arma por usarla; desbloquea acabados de color, estela y título («Maestro de la Maza»).
- **Colección:** álbum de skins por arma con porcentaje completo; completar un arma da un aura exclusiva.
- **Regreso:** si vuelve después de 3 días o más, «Bienvenido de vuelta» con una tirada gratis extra.

## 6. Ruleta
- 8 sectores con pesos en `Rewards.lua`: almas (chico, mediano, grande), XP, multiplicador ×1,5, multiplicador ×2, caja, **premio grande de la semana**.
- Probabilidades visibles con un botón «i».
- **Garantía:** cada 30 tiradas sin el premio grande, la siguiente lo da (o, si ya lo tiene, almas equivalentes).
- El servidor decide el premio **antes** de animar; la interfaz solo lo muestra.

## 7. Cajas de suerte (se compran con almas)
| Caja | Precio inicial | Contiene |
|---|---|---|
| Caja de Almas | 500 | almas (de 300 a 1500) y multiplicadores |
| Caja de Reliquias | 1500 | skins (común 60 %, rara 28 %, épica 10 %, legendaria 2 %) |
- **Garantía:** épica o mejor cada 10 Cajas de Reliquias.
- **Duplicado = almas** (40 % del precio de la skin).
- Multiplicadores ×1,5 / ×2 / ×3 de XP o almas, por 15 / 30 / 60 min **de partida** (el tiempo corre solo jugando, para no perderlo estando desconectado). No se suman: se toma el más alto y se alarga el tiempo.

## 8. Dopamina: cómo se siente cada premio
- Colores por rareza (común gris, rara azul, épica violeta, legendaria dorado) en todo el juego.
- **Ruleta:** tictac que se frena, pausa breve antes de parar, festejo según la rareza. Legendario: destello de pantalla, sonido propio y **aviso en el servidor** («X ganó Y»).
- **Cajas:** la caja tiembla, se abre con luz del color de la rareza y la skin gira en 3D.
- **Almas:** partículas que vuelan desde el rival caído o el botín hasta el contador, con sonido de absorber (D5).
- **Subir de nivel:** fanfarria corta, número grande, premios en fila.
- **Avisos rojos** («!») en los botones con premios sin reclamar (ruleta, misiones, racha).
- **Reglas:** nada de casi-premios falsos (la ruleta no frena «al lado» del legendario a propósito); probabilidades siempre visibles; si algún día se vende algo al azar con Robux, cumplir las reglas de Roblox (guía `roblox-monetization-compliance`).

## 9. Medición (telemetría, C22)
Embudo: entra → termina tutorial → primera partida → nivel 5 → vuelve al día 1, 7 y 30. Además: tiradas, cajas abiertas, premios reclamados y abandonos. Ajustar números con esto, de a pocos cambios.

## Reparto
| IA | Parte |
|---|---|
| **Codex** (Sol, High) | Todo el servidor y los datos: `Rewards.lua`, `RewardService` (ruleta, cajas, garantías, racha, semanal, regreso, avisos en el servidor), `Progression` (niveles, maestría, colección, primera victoria), cadena «Primeros pasos», anti-AFK, telemetría, migración segura del perfil. Ronda 2. |
| **Gemini** (Flash, High) | Interfaz: ruleta, apertura de cajas, calendario de racha, pantalla de progreso pospartida, bienvenida y elección de la primera skin, colección, avisos rojos, pedestal del premio semanal (modelo). Ronda 2. |
| **Claude** (Opus) | Tutorial de 3 pasos en el patio, partículas y sonido de absorber almas, fanfarria de nivel y destellos de rareza (efectos y sonido). Ronda 2. |
