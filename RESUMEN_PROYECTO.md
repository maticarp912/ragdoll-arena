# Ragdoll Arena — resumen del proyecto (v6: documento de traspaso final)

> Documento de traspaso para la siguiente sesión de Claude Code (Opus). Léelo entero antes de tocar nada.
> Carpeta del proyecto: `F:\RobloxJuegos\Plataforme 2v2`
> Idioma de trabajo con el usuario: **español**.

---

## 0. Instrucciones para quien implemente (Opus)
- **Tu foco: código y mecánicas del juego.** El usuario se encarga de **renders (modelos 3D, UI, texturas, VFX), escenarios y efectos de sonido**. Las **animaciones** las conseguirá aparte (ver sección 14). No esperes los assets: trabaja con **placeholders** y deja todo listo para enchufarlos sin tocar código (contrato en la sección 14.4).
- **Los assets llegan por lotes** (lista en `ASSETS_LISTA.md`). Mientras tanto, avanza con el código y las mecánicas usando placeholders; cuando el usuario pase IDs, ponlos en `Assets.lua`. No bloquees el desarrollo esperando arte.
- El código actual en la carpeta es la **versión anterior del diseño** (elementos y ulti). Hay que refactorizarlo según este documento. Empieza por la **Fase A** (sección 12).
- Todo valor numérico es una **propuesta a calibrar**: ponlo en módulos de datos (`WeaponData`, `Infusions`, `Progression`), nunca dentro de la lógica.
- **Las decisiones de la sección 13 ya están tomadas por defecto** (el usuario pidió que se decidiera lo mejor). Impleméntalas tal cual; si el usuario dice otra cosa, manda el usuario. Todo valor va en datos para poder cambiarlo.
- Windows: **Python no está instalado; usa Node**. Los errores de Studio se leen en `%LOCALAPPDATA%\Roblox\logs\*_Studio_*_last.log` (buscar `CreatorError`). Generador del lugar de Studio en `tools\make_rbxlx.js`. No hay analizador de Luau: revisa la sintaxis con cuidado.
- Todo se decide en el **servidor** (daño, alcance, equipos, cooldowns, desbloqueos, compras). El cliente solo envía acciones.
- **Rig fijo: R15** (decidido por el usuario) para todo el juego, las animaciones y los modelos. En Studio: *Game Settings → Avatar → Avatar Type = R15* (no *Player Choice*) para forzarlo; también conviene limitar las escalas de avatar permitidas para evitar ventajas de hitbox y que las animaciones se vean bien. El ragdoll, el agarre y las armas asumen las articulaciones R15 (Motor6D); **no hay que soportar R6**.
- **Cómo trabaja el usuario:** habla español rioplatense; es directo y quiere resultados. Prepara **renders, escenarios, sonidos y animaciones** por su cuenta y te los pasa **por lotes, empezando por la Espada** (sus animaciones las está haciendo con ChatGPT) y después el resto de armas. **Tú no esperas los assets**: avanzas con código y mecánicas con placeholders y los integras cuando lleguen (ver flujo en la sección 14).
- **Permisos:** el usuario autorizó escribir en `F:\RobloxJuegos\Plataforme 2v2`. **Pídele permiso antes de abrir Roblox Studio** o cualquier otro programa, y antes de acciones fuera de esa carpeta.
- **Verificación:** no hay analizador de Luau ni se ha probado nada jugando. Tras cada fase, regenera el `.rbxlx`, pide al usuario que pruebe y lee los errores del log de Studio. Prioriza que cada fase **arranque sin errores** antes de seguir.
- **Meta del proyecto:** que el juego genere dinero (gratis para jugar, progresión acelerable con Robux, skins). Decisiones de diseño que dañen el equilibrio o parezcan *pay-to-win* están descartadas.

---

## 1. Visión
Juego de Roblox **PvP 1v1 y 2v2 con físicas ragdoll** sobre una **plataforma grande que se desmorona**. Combate con **armas al estilo Dark Souls 1 y For Honor**, en versión rápida y reactiva. Gratis de jugar. Se monetiza con **progresión acelerable** (tiempo y variedad, no poder) y **skins cosméticas**.

**Historial de decisiones** (para no repetir debates):
1. Simulador de farmeo con mascotas → descartado al pivotar al PvP.
2. "Steal a Brainrot" de anime con Naruto/Goku → **descartado por copyright** (DMCA). Todo es original.
3. Clases con habilidades y 4 elementos clásicos → simplificado.
4. Combate tipo For Honor simplificado + arsenal tipo Dark Souls 1.
5. La "ulti" desaparece como ataque: **la infusión activable con Q es la ulti**.
6. **Decisión final:** **6 infusiones** (Fuego, Rayo, Sangre, Hielo, Veneno, Sombra), **todas disponibles para cada arma**, equilibradas con un sistema de **contras tipo piedra-papel-tijera**, y **desbloqueables con progresión** (con pagos opcionales para ir más rápido).

---

## 1.5 Dirección de arte: dark fantasy
**Estilo decidido por el usuario: dark fantasy** (ruinas góticas, acero desgastado, niebla y brasas), con la sobriedad de Dark Souls pero **diseño 100% original**. Guía completa de paleta, materiales, iluminación, interfaz, VFX y sonido en `ASSETS_LISTA.md` (sección "Dirección de arte").

Resumen para el código:
- **Paleta central en un módulo `ReplicatedStorage/Theme.lua`** (colores, fuentes, tamaños): la UI, los placeholders y los VFX provisionales leen de ahí, para que el arte final se aplique cambiando un solo archivo.
- **Color vivo solo en las infusiones y en los avisos de combate**: el mundo es oscuro y desaturado, así lo importante destaca.
- **Legibilidad:** los jugadores deben leerse sobre fondos oscuros: contorno/*Highlight* tenue con el color del equipo (rojo/azul) y buena silueta.
- **Colores de aviso vs. infusiones:** Fuego (naranja) y Sangre (rojo) se parecen al aviso naranja del fuerte y al rojo del imbloqueable. Los avisos se distinguen por **forma y sonido** (anillo/destello en el arma + sonido de aviso + icono sobre la cabeza), no solo por color. Ver decisión 10 de la sección 13.
- **Contenido:** la sangre es **estilizada** (partículas rojo oscuro, sin gore realista) para cuidar la clasificación de contenido de Roblox. Completar el cuestionario de edad de la experiencia al publicar.
- **Rendimiento:** pensar en móvil y gama baja (texturas ≤ 512, pocas partículas simultáneas, niebla con `Atmosphere` en lugar de efectos pesados).
- **Propiedad intelectual:** no copiar elementos reconocibles de Dark Souls (rótulo "YOU DIED", la hoguera exacta, el frasco, tipografías y logotipos). Todo original.

---

## 2. Controles
| Entrada | Acción |
|---|---|
| **Clic izquierdo (M1)** | Combo básico de 3 golpes. No rompe guardia; **drena la Guardia** del rival |
| **E** (M2 como alias opcional) | **Ataque fuerte**: *windup* pronunciado, daño masivo y mucho Stun. Rompe la guardia pasiva. Castigable con parry o esquiva |
| **Shift / Espacio** | **Esquiva** direccional con **0,25 s de i-frames**. No hay salto |
| **F (mantener)** | Bloqueo frontal (consume la Guardia) |
| **F (toque justo al impacto)** | **Parry**: el atacante queda en Stun |
| **R** (contextual) | **Neutro:** patada rompe-guardias · **rival derribado:** lo alza al hombro para lanzarlo (M1 corto / M2 potente) · **aliado derribado:** lo levanta/revive |
| **Q** | **Activar infusión** (barra llena). Sin cinemática |
| **T / Y** | Fijar objetivo / cambiar objetivo (lock-on) |
| **B** | Menú: arma, infusión, progresión y skins |

Se puede **cancelar el inicio de un ataque fuerte** con F o con la esquiva.

---

## 3. Bucle de combate
Importan la **distancia (*spacing*)**, la lectura de ataques, las esquivas con i-frames y el castigo a la imprudencia.

- **No hay escudos: se bloquea con el arma.** Cada arma tiene su propia pose de guardia, animación de parry y reacción al golpe bloqueado.
- **Atacar no consume resistencia.** La Guardia solo se gasta al **bloquear pasivamente**; acampar cubriéndote rompe la guardia.
- **Parry** (sonido y destello, sin escena): **hitstop** breve, empuja al atacante, lo deja en **Stun** y te da prioridad para contraatacar.
- **Semáforo visual**:
  | Visual | Tipo | Respuesta |
  |---|---|---|
  | Sin brillo | Ataque básico | Bloquear con F |
  | **Destello naranja en el arma** | Ataque fuerte (rompe guardia pasiva) | **Parry** o **esquiva** |
  | **Destello rojo** | Imbloqueable (p. ej. *Machaque* de la Maza) | **Parry** o **esquiva**; bloquear no sirve |
  | Destello azul/metálico | Feedback de parry exitoso | — |
- Contras básicos: bloqueo > rápidos · fuerte rompe bloqueo · parry > fuerte · esquiva > fuerte · patada (R) rompe el bloqueo pasivo.

---

## 4. Infusiones (la "ulti")
Un **estado temporal del arma**, no un ataque. Al activarlo, el arma se enciende y durante unos segundos **cambian las reglas**: ventajas para ti y desventajas para quien golpeas.

### 4.1 Reglas comunes
- **Equipada antes de la partida** (una por arma). Visible para el rival (icono sobre la cabeza) para que se pueda jugar el contra. Propuesta: **se puede cambiar entre rondas** (contra-pick).
- **Q la activa** cuando la barra (0–100) está llena. Se carga **infligiendo y recibiendo daño** (recibir carga algo menos). Reutiliza el medidor `Ult` existente.
- **Duración orientativa 12 s.** No se puede cancelar ni reactivar hasta recargar. Al terminar hay un breve **agotamiento** (sin ganar carga unos segundos).
- **Visual:** arma ardiendo/helada/etc., aura en los pies y sonido de activación. Sin cinemática ni pausa.
- Cada infusión tiene **ventajas**, **efectos al golpear** y un **coste**. Se construyen con la biblioteca de efectos (sección 5): añadir o ajustar una es solo **datos**.
- **Todas valen para cualquier arma** (5 armas × 6 infusiones = 30 builds en la Fase 1).

### 4.2 Las seis infusiones
| Infusión | Idea | Ventajas (portador) | Efectos al golpear (rival) | Coste |
|---|---|---|---|---|
| **Fuego** — *Furia Ígnea* | Presión y daño | +20% daño · atraviesa 30% del bloqueo (chip a la Vida) · aura de calor · hiperarmadura parcial en el fuerte | **Quemadura** (~4 dps, 4 s, no apila) · su Guardia se regenera 50% más lento | −30% Stun por golpe · −10% velocidad de movimiento |
| **Rayo** — *Tormenta* | Tempo y control | +25% velocidad de ataque · +10% velocidad de movimiento · **Stun +50%** · cadena en 2v2 (20% del daño salta al otro enemigo a <8 studs) | **Conmoción**: bloquear drena +50% de Guardia · cada 3 golpes → aturdimiento de 0,6 s | −20% daño directo · menos alcance en el fuerte |
| **Sangre** — *Sed Carmesí* | Duelista vampírico | **Robo de vida** 25% del daño (tope 8 por golpe) | **Sangrado** en cada golpe (3 s, hasta 3 acumulaciones; **más daño mientras el rival se mueve o esquiva**) | −30% Guardia máxima |
| **Hielo** — *Escarcha* | Control y distancia | +50% regeneración de Guardia · mantiene la distancia | **Ralentización** (−30%, 2 s) + **Fragilidad** (+15% daño recibido, 4 s) tras 3 golpes | −15% velocidad de ataque · −10% daño |
| **Veneno** — *Ponzoña* | Desgaste | Los efectos se acumulan (hasta 4) | **Veneno** (daño bajo, 6 s) · **Debilidad** (−15% su daño) · **Corrosión de la Guardia** · **−50% a su robo de vida y regeneración** | −15% daño directo · sin daño inmediato extra |
| **Sombra** — *Velo* | Movilidad y ráfaga | Esquiva +30% distancia y **+0,1 s de i-frames** · +15% velocidad de movimiento · +20% daño por la espalda | **Marca** tras esquivar o golpear por la espalda (+25% daño al siguiente golpe, 6 s) | −30% Guardia máxima · −20% Stun por golpe |

### 4.3 Equilibrio: el hexágono de contras
Disposición circular **Hielo → Sombra → Fuego → Rayo → Veneno → Sangre → (Hielo)**. Cada infusión **gana a las 2 siguientes**, **pierde contra las 2 anteriores** y es **neutral contra la opuesta**. Así ninguna es mejor que otra: todas ganan 2, pierden 2 y empatan 1.

| Infusión | Gana a | Pierde contra | Neutral |
|---|---|---|---|
| **Hielo** | Sombra, Fuego | Veneno, Sangre | Rayo |
| **Sombra** | Fuego, Rayo | Hielo, Sangre | Veneno |
| **Fuego** | Rayo, Veneno | Sombra, Hielo | Sangre |
| **Rayo** | Veneno, Sangre | Fuego, Sombra | Hielo |
| **Veneno** | Sangre, Hielo | Rayo, Fuego | Sombra |
| **Sangre** | Hielo, Sombra | Veneno, Rayo | Fuego |

**Por qué gana cada una** (las contras salen de la mecánica, no de la lore):
| Gana | Contra | Razón |
|---|---|---|
| Hielo | Sombra | La ralentización anula los dashes y la esquiva larga |
| Hielo | Fuego | Fuego es lento (−10%) y sin control: no cierra la distancia; la Guardia de Hielo aguanta el chip |
| Sombra | Fuego | Las esquivas con i-frames evaden sus golpes lentos y Fuego no tiene Stun para frenarla |
| Sombra | Rayo | La esquiva larga escapa de los combos rápidos y la Marca multiplica el único golpe que conecta |
| Fuego | Rayo | Rayo hace −20% daño: Fuego gana la carrera de daño y su chip atraviesa el bloqueo que Rayo quiere drenar |
| Fuego | Veneno | La presión mata antes de que el veneno acumule |
| Rayo | Veneno | La Conmoción interrumpe y el Stun +50% derriba antes de que el veneno se acumule |
| Rayo | Sangre | El Stun potenciado y los aturdimientos cortan combos; el robo de vida no compensa los derribos |
| Veneno | Sangre | Reduce a la mitad su robo de vida y su regeneración |
| Veneno | Hielo | Las peleas largas favorecen el daño en el tiempo; Debilidad y Corrosión anulan su juego pasivo |
| Sangre | Hielo | El sangrado castiga al que se mueve/kitea y el robo de vida supera su daño bajo |
| Sangre | Sombra | El sangrado hace más daño mientras se mueve o esquiva; Sombra tiene poca Guardia |

**Reglas de balance**
- Las contras son **blandas**: pueden anularse con habilidad (parry, esquiva, distancia). Objetivo: la ventaja da ~55–60% de victorias, no más.
- Para que se note, se añade una **afinidad explícita pequeña**: **±8% de daño y de Stun** si tu infusión gana/pierde contra la infusión **equipada** del rival. Ajustable en datos (puede quedar en 0 si basta con los efectos).
- Cada infusión solo domina un tipo de estilo: ninguna es la mejor contra todas.
- **Telemetría:** registrar infusión por jugador y resultado (p. ej. con `AnalyticsService` o un log propio) para ver tasas de victoria por emparejamiento. Objetivo global **45–55%** por infusión.
- En 2v2 los compañeros se cubren entre sí: la composición del equipo compensa los contras.
- Todos los números viven en `Infusions.lua` para parchear sin tocar lógica.

---

## 5. Biblioteca de efectos
Valores base orientativos. La implementa `Effects.lua`.

### 5.1 Negativos para el rival
| Efecto | Qué hace | Tope / duración | Contra-juego |
|---|---|---|---|
| **Quemadura** | Daño en el tiempo (~4 dps) | 4 s, no apila, se refresca | Esperar o matar rápido |
| **Sangrado** | Daño en el tiempo; **más daño si se mueve/esquiva** | 3 s, hasta 3 acumulaciones | Quedarse quieto/bloquear |
| **Veneno** | Daño bajo; reduce regeneración y robo de vida | 6 s, hasta 4 acumulaciones | Terminar la pelea pronto |
| **Conmoción** | Aturde 0,6 s cada 3 golpes; drena Guardia extra | Cooldown 4 s por objetivo | Esquivar |
| **Stun potenciado** | Sube el Stun más rápido (+50%) | Mientras dure la infusión | Parry y esquiva |
| **Ralentización** | −30% velocidad de movimiento | 2 s | Esquiva |
| **Fragilidad** | Recibe +15% daño | 4 s | Evitar golpes |
| **Debilidad** | Inflige −15% daño | 4 s | Cambiar de objetivo |
| **Corrosión de la Guardia** | Reduce la Guardia máxima y su regeneración | Hasta vaciarse | No bloquear pasivamente |
| **Marca** | El siguiente golpe de cualquiera del equipo hace +25% | 1 golpe, 6 s | Aliado cerca |
| **Silencio de carga** | Gana menos carga de infusión | 5 s | — (anti bola de nieve) |
| **Pesadez** | Esquiva más corta, menos i-frames | 3 s | Bloquear |

### 5.2 Positivos para quien lleva el arma
Daño aumentado · **Robo de vida** · velocidad de ataque · velocidad de movimiento · hiperarmadura · penetración de guardia · regeneración de Guardia · esquiva mejorada · ventana de parry ampliada · alcance extra · cadena · aura de contacto.

---

## 6. Barras de estado
Sobre la cabeza de cada jugador:
1. **Vida (roja)**: a 0 → **Derribo Crítico**.
2. **Stun (amarilla)**: sube con golpes, fuertes y patadas; **se vacía rápido** tras 2 s sin castigo. Al 100% → **Derribo por Stun**.
3. **Guardia (azul, fina)**: se gasta al bloquear **con el arma**; a 0 se **rompe la guardia** y quedas aturdido.
4. **Icono de infusión** equipada/activa y **iconos de estado** (quemadura, sangrado, etc.). La carga de infusión propia va en el HUD.

---

## 7. Derribo, agarre y expulsión (mecánica central)
| Tipo | Causa | Duración | Recuperación |
|---|---|---|---|
| **Derribo por Stun** | Stun al 100% | **4 s** (ragdoll temporal) | Se levanta solo o **machacando teclas** (Espacio/clics). Un **aliado** lo pone en pie con una palmada (R, **0,5 s**) |
| **Derribo Crítico** | Vida a 0 | Permanente | **No puede levantarse solo.** Gatea lento. El **rival** puede alzarlo y lanzarlo fuera. Un **aliado** lo salva con R durante **2 s ininterrumpidos** y revive con **35% de vida** |

**Agarre y lanzamiento (rival derribado)**: **R** junto al cuerpo → al hombro (**−20% de velocidad**) · **M1**: tirón corto · **M2 cargado**: lanzamiento potente en parábola (~30°) hacia el vacío. **Solo se agarra a rivales derribados.** Cruzar el borde = **eliminado al instante**.

**2v2**: cualquier golpe básico **interrumpe** al que rescata y al que carga. **Intercepción:** si lanzan a tu aliado al vacío y estás cerca del borde, R o un golpe lo salva en el último segundo.

**Ganar la ronda:** eliminar a todos los rivales. Partidas al mejor de 3. Cuándo cuenta el derribo crítico como eliminación: ver decisión 3 de la sección 13.

---

## 8. Arena
**Escenario provisional (decidido por el usuario):** algo **básico y grande**: un **cuadrado de baldosas que se desmorona por partes**. Sin decoración. Material de piedra oscura (Slate/Cobblestone, colores apagados; **no** SmoothPlastic) para ir en la línea dark fantasy. El arte final llegará después (ver `ASSETS_LISTA.md`).

- **Una ronda debe poder durar al menos 2 minutos**: la arena es lo bastante grande y el derrumbe lo bastante lento como para que no se acabe antes por culpa del mapa.
- **2v2: cuadrado grande** de 21×21 baldosas de 10 studs (210 studs de lado). Empieza a desmoronarse a los **30 s**; cada **12 s** cae un anillo de fuera hacia dentro. El último anillo exterior cae hacia los **~140 s**. El centro (anillo 0) nunca cae.
- **1v1: cuadrado más pequeño** de 7×7 baldosas. Empieza a los **30 s** y cae un anillo cada **30 s**.
- **Tiempo máximo de ronda: 180 s.** Si se agota, gana el equipo con más vida total.
- Cada baldosa avisa en rojo ~1,3 s antes de caer. Sin paredes ni bordes: se puede caer (ring-out).
- Todos estos valores están en `MODES` y `CONFIG` de `MatchService`.

---

## 9. Arsenal

### 9.1 Fase 1 (núcleo) — números
Combo de 3 golpes (el 3º con más Stun).

| Arma | Vida | Vel. | Daño básico (1-2-3) | Stun básico (1-2-3) | Fuerte (daño / Stun / windup) | Perfil |
|---|---|---|---|---|---|---|
| **Espada** | 100 | 16 | 10-12-16 | 15-15-30 | 28 / 45 / 0,45 s | Equilibrada. *Tajo Cruzado* rápido |
| **Espadón** | 120 | 13 | 16-18-24 | 25-25-45 | 45 / 70 / 0,75 s | Lenta, hiperarmadura parcial. *Tajo Aplastante* destruye la guardia (+60% Stun) |
| **Dagas** | 90 | 18 | 7-8-12 | 10-10-20 | 20 / 25 / 0,30 s | Ágil. *Doble Estocada* con sangrado propio. Sus golpes interrumpen agarres y rescates |
| **Estoque** | 95 | 17 | 9-11-15 | 12-12-25 | 26 / 35 / 0,40 s | Rango. *Puntada Perforante* atraviesa el bloqueo |
| **Maza** | 130 | 13 | 14-16-22 | 30-30-50 | 40 / 85 / 0,70 s | Contundente. *Machaque Pesado* imbloqueable |

> **No hay escudos en el juego:** todas las armas bloquean con el arma (cada una con su propia pose de guardia).

### 9.2 Arsenal completo (Dark Souls 1 / For Honor)
| Arma | Inspiración | Rol | Vel | Daño | Stun | Alcance | Rasgo |
|---|---|---|---|---|---|---|---|
| Espada | DS1 espada recta / Warden | Equilibrada | 3 | 3 | 3 | 3 | Combo fluido |
| Espadón | DS1 Claymore | Barrido | 2 | 4 | 4 | 4 | Golpea a 2 |
| Espada Colosal | DS1 ultra espadón; arquetipo "Guts" (nombre propio) | Castigador | 1 | 5 | 5 | 4 | Hiperarmadura en el fuerte |
| Katana | DS1 Uchigatana / Kensei | Duelista | 4 | 3 | 2 | 3 | Sangrado propio |
| Estoque | DS1 estoque | Pinchazos | 5 | 2 | 2 | 5 | Parry +30% |
| Dagas | DS1 daga / Shinobi | Asesino | 5 | 1–2 | 1 | 1 | Sangrado; esquiva larga |
| Lanza | DS1 lanza | Distancia | 3 | 3 | 2 | 5 | Buena contra cargas |
| Alabarda | DS1 alabarda | Zona | 2 | 3 | 3 | 5 | Arcos amplios |
| Hacha de Guerra | For Honor hacha pesada | Aturdidor | 2 | 3 | 5 | 3 | Gran Stun |
| Maza | DS1 maza | Aplastaguardias | 3 | 3 | 4 | 2 | Más daño a la Guardia |
| Martillo Gigante | DS1 gran martillo; arquetipo "Jayce" (nombre propio) | Sísmico | 1 | 5 | 5 | 3 | Onda de choque |

**Fases:** 1 = Espada, Espadón, Dagas, Estoque, Maza · 2 = Katana, Lanza, Alabarda, Hacha · 3 = Espada Colosal, Martillo Gigante. La infusión es genérica: **las armas nuevas no necesitan habilidad propia**.

> Propiedad intelectual: "Guts", "Jayce", For Honor y Dark Souls son solo referencias de estilo. Nombres, diseños y modelos deben ser **originales**.

---

## 10. Progresión y monetización

### 10.1 Inicio del jugador
- **1 arma** a elegir entre las armas iniciales (propuesta: Espada, Espadón o Dagas, tres estilos distintos) y **2 infusiones** a elegir de las 6 para esa arma.
- El resto de armas e infusiones se **desbloquea jugando** (o acelerando con pagos).

### 10.2 Progresión (se gana jugando)
- **Nivel de cuenta** y **Maestría por arma** (XP por partida: más por ganar; bonus por parries, derribos y ring-outs).
- **Infusiones por arma** (propuesta): 2 al inicio · 3ª en maestría 3 · 4ª en 5 · 5ª en 7 · 6ª en 10. La maestría es **por arma**, así que probar armas nuevas da variedad.
- **Armas nuevas** (propuesta): por nivel de cuenta o comprándolas con monedas. Todas se pueden conseguir gratis.
- **Monedas** por partida, misiones diarias y primer triunfo del día.
- Valores en `Progression.lua` (nivel → XP, desbloqueos, precios).

### 10.3 Pagos (aceleran tiempo y variedad, **no dan poder**)
| Producto | Tipo | Qué da |
|---|---|---|
| **XP x2** | Game Pass | Más XP y monedas por partida, permanente |
| **Impulso de XP** (1 h) | Developer Product | XP x2 temporal |
| **Desbloquear arma** | Developer Product | Salta el requisito de nivel/monedas de esa arma |
| **Desbloquear infusión** | Developer Product | Abre una infusión de un arma sin esperar a la maestría |
| **Pase de temporada** (futuro) | Game Pass / producto | Pista de recompensas (cosméticos y atajos) |

Principio: **todo lo que se paga se puede conseguir gratis jugando**. Más opciones no son estrictamente más fuertes (el hexágono de contras lo evita), así que no es *pay-to-win*. Las compras se validan en el servidor con `ProcessReceipt`.

### 10.4 Skins (se sumarán después)
Hay una tienda básica con 6 skins temporales (Acero, Carbón, Hielo, Oro Real con monedas; Neón Cyber y Sangre Real con Robux, `productId = 0` hasta crear los productos). **Hay que renombrarlas para el estilo dark fantasy y para no chocar con las infusiones:** Acero Viejo, Obsidiana, Hueso, Oro Ceniciento (monedas) · Runas Etéreas, Linaje Carmesí (Robux).

---

## 11. Estado del código y cambios necesarios
Ruta: `F:\RobloxJuegos\Plataforme 2v2\` (estructura compatible con Rojo). **Es la versión anterior del diseño.**

**ReplicatedStorage**: `Ragdoll`, `WeaponData`, `Elements`, `Skins`
**ServerScriptService**: `Remotes`, `PlayerData`, `WeaponBuilder`, `Combat` (módulos) · `CombatService`, `ShopService`, `MatchService` (scripts)
**StarterPlayerScripts**: `HUD`, `Controls`, `Overhead`, `Shop`

Ya implementado (sin verificar jugando): ragdoll con servidor como dueño de la física, bloqueo/parry/guardia, combo de 3 con 3º derriba, estados (quemadura, sangrado, ralentización, aturdimiento), agarrar/lanzar, lock-on con cámara, barras de vida y guardia, arenas de baldosas que se desmoronan, cola de partidas (4 → 2v2; 2 → 1v1 tras 12 s), tienda de skins con DataStore protegido por `pcall`, HUD de teclas a la derecha. IDs actuales: `Sword`, `Greatsword`, `Dagger`, `Rapier`, `Mace`. Existe un medidor `Ult` (0–100): se reutiliza para la infusión.

| Archivo | Cambio |
|---|---|
| `Elements.lua` | **Eliminar**; sustituir por `Infusions.lua` (6 infusiones: efectos, duración, coste, tabla de contras y afinidad ±8%) |
| `WeaponData.lua` | Quitar `ult`. Por arma: vida, velocidad, daño/Stun por golpe del combo (listas), fuerte (daño/Stun/windup), rasgo |
| *(nuevo)* `Effects.lua` | Implementa la biblioteca de la sección 5 (aplicar, acumular, expirar, topes) |
| *(nuevo)* `Progression.lua` | XP, niveles, maestría por arma, desbloqueos y precios |
| `PlayerData.lua` | Guardar: monedas, armas desbloqueadas, **infusiones desbloqueadas por arma**, infusión equipada por arma, XP/maestría, skins |
| `Combat.lua` | Barras de Stun y Guardia, esquiva con i-frames, hitstop, parry que deja Stun, **estado de infusión** (activar, duración, agotamiento, afinidad), derribo por Stun (4 s + mash) y crítico, patada R, rescate de aliados, interrupciones, intercepción |
| `CombatService.server.lua` | Acciones: `Heavy` (E/M2), `Dodge`, `Kick/Interact` (R), `Infuse` (Q); quitar ejecutores de ulti elemental |
| `ShopService.server.lua` | Compras de skins, desbloqueos con monedas/Robux, `ProcessReceipt`, validación de desbloqueos |
| `MatchService.server.lua` | Regla de eliminación con derribo crítico y rescate; XP y monedas al final; cambio de infusión entre rondas |
| `Controls.client.lua` | Reasignar teclas; Q = infusión; destellos; hitstop y sacudida de cámara; barra de carga de infusión |
| `Overhead.client.lua` | Barra de Stun, icono de infusión y estados |
| `Shop.client.lua` | Menú: arma, infusión (bloqueada/desbloqueada), progresión, skins y compras |
| `WeaponBuilder.lua` | Quitar la gema elemental; cargar modelos reales si existen; efectos de infusión activos |

**Borrador de código previo** (de otra fuente): era solo una guía (usa `Combat.getState`/`updateOverhead` inexistentes, IDs distintos y un `applyHit` incompleto). Se adoptaron sus **números de Stun**, no su código.

---

## 12. Plan de implementación
0. **Fase 0 — herramientas de prueba (hazlo primero):** el juego es PvP y probar con 2+ jugadores es incómodo. Crea: **muñeco de práctica** (dummy que bloquea, esquiva y ataca según un modo), **modo práctica de 1 jugador**, **visualizador de hitboxes** (activable), **AnimTester** (cargar un ID de animación y reproducirlo en tu personaje con el marcador `Hit` visible), panel de depuración (estados, barras, cooldowns) y los módulos `Assets.lua` y `Theme.lua` con placeholders.
1. **Fase A — núcleo:** quitar elementos/ulti, nuevos controles, barras de Stun y Guardia, esquiva con i-frames, parry con hitstop, semáforo de avisos, bloqueo con el arma.
2. **Integración del Lote 1 (Espada):** cuando el usuario pase los IDs (modelo + 8 animaciones + sonidos), enchufarlos, sincronizar daño con el marcador `Hit` y ajustar tiempos.
3. **Fase B — derribo y rescate:** Stun/crítico, carga al hombro, lanzamientos, revivir/levantar aliado, interrupciones, intercepción.
4. **Fase C — infusiones:** `Infusions.lua` y `Effects.lua`, las 6 infusiones, activación con Q, hexágono de contras y afinidad, icono visible.
5. **Fase D — arsenal:** reestructurar `WeaponData` y añadir Espadón, Dagas, Estoque y Maza (cada arma se integra cuando el usuario pase su lote).
6. **Fase E — progresión y tienda:** `Progression.lua`, desbloqueos, XP, monedas, Game Passes y Developer Products.
7. **Fase F — pulido:** animaciones restantes, sonidos, VFX, hitstop y cámara, arte de la arena y la interfaz.

Después de cada fase: regenerar el `.rbxlx`, pedir prueba al usuario y corregir lo que salga en el log.

---

## 13. Decisiones por defecto (tomadas por Claude a petición del usuario; modificables)
El usuario dijo "haz lo que creas mejor". Estas son las decisiones adoptadas. Cámbialas solo si el usuario lo pide; todas viven en datos.

| # | Tema | Decisión |
|---|---|---|
| 1 | **Infusión: duración y carga** | Dura **12 s**; agotamiento posterior de **5 s**. La barra (0–100) sube **+1,2 × daño infligido** y **+0,8 × daño recibido** (tope 15 por golpe). Objetivo: llenarse tras ~40 s de pelea activa |
| 2 | **Ataque fuerte infundido** | Mientras la infusión está activa, el fuerte es **imbloqueable (destello rojo) pero parreable y esquivable**. Interruptor `InfusedHeavyUnblockable = true` en `Infusions.lua` |
| 3 | **Vida a 0** | **1v1:** eliminado al instante. **2v2:** derribo crítico con **desangrado de 20 s**; el compañero vivo lo salva con R (2 s, 35% de vida); el rival puede alzarlo y lanzarlo (eliminado al caer). La ronda termina cuando todos los de un equipo están **eliminados o en derribo crítico a la vez** |
| 4 | **Contra-pick** | La **infusión se puede cambiar entre rondas**; el arma queda fija durante la partida |
| 5 | **Afinidad** | **Sí**, ±8% de daño y Stun frente a la infusión equipada del rival, con un pequeño indicador de ventaja/desventaja |
| 6 | **Armas iniciales** | Espada, Espadón y Dagas (tres estilos). 2 infusiones a elegir de las 6 |
| 7 | **Tecla del fuerte** | **E**, con M2 como alias |
| 8 | **Hiperarmadura** | Solo contra golpes básicos y solo durante la preparación del fuerte: Espadón, Espada Colosal (futura) e infusión de Fuego (parcial). Nunca protege del parry ni de derribos |
| 9 | **Aspecto de los personajes** | Cada jugador usa su **avatar R15**; el equipo se marca con un contorno tenue (rojo/azul) y se prevén capas/hombreras cosméticas |
| 10 | **Avisos vs. infusiones** | Se distinguen por **forma y sonido** (anillo/destello en el arma + sonido de aviso + icono sobre la cabeza), no solo por color |
| 11 | **Progresión (valores iniciales)** | XP por partida: victoria 100, derrota 40; bonus: parry +10, derribo +15, ring-out +25. XP para subir de nivel de arma ≈ 150 × nivel; cuenta ≈ 200 × nivel. Monedas: victoria 50, derrota 15, misión diaria 100, primer triunfo del día +50. Armas nuevas: por nivel de cuenta (Estoque 3, Maza 5…) o con monedas (500–1500) |
| 12 | **Pagos (precios provisionales)** | Desbloquear arma 149 R$ · desbloquear infusión de un arma 79 R$ · XP x2 permanente 299 R$ · impulso de XP 1 h 39 R$. **El usuario fijará los precios definitivos** |
| 13 | **Escenario provisional** | Cuadrado grande de baldosas básicas que se desmorona; rondas de ≥ 2 min posibles (sección 8) |
| 14 | **Números de armas y efectos** | Los de este documento; calibrar jugando con telemetría (objetivo 45–55% de victorias por infusión) |

---

## 14. Arte, animación y sonido: reparto de trabajo
> **Lista detallada y checklist: `ASSETS_LISTA.md`** (claves, marcadores, prioridades y orden de entrega).
**Opus (código):** sistema que reproduce animaciones, sonidos y VFX; sincronización con marcadores; hitstop; blending; ragdoll y levantarse; lógica de todo. **No hace** modelos 3D, texturas, sonidos ni keyframes. Mientras no haya assets usa **placeholders** (partes simples, animación procedural provisional, silencio).

### 14.1 Lo que prepara el usuario (renders y escenarios)
| Prioridad | Qué | Notas técnicas |
|---|---|---|
| 1 | **Armas 3D** (5 de la Fase 1; **no hay escudos**) | MeshPart con origen en el agarre; Attachments `GripPoint`, `BladeBase`, `BladeTip` (para estelas); 4–7 studs; ≤ ~5k triángulos; texturas separables para hacer skins |
| 2 | **VFX de las 6 infusiones** | Por infusión: aura del arma, estela, impacto, aura en los pies, icono de estado. Texturas de partículas (llamas, arcos eléctricos, gotas de sangre, cristales de hielo, nube/gotas de veneno, volutas de sombra) |
| 3 | **VFX de combate** | Parry (destello metálico), rotura de guardia, destellos naranja/rojo de telégrafo, polvo de derribo, arcos de ataque por arma, imagen residual de esquiva |
| 4 | **UI** | Iconos de teclas (F, E, R, Q, Shift, Espacio, ratón), 5–12 iconos de armas, 6 de infusiones, ~12 de estados, barras (vida/Stun/Guardia), menú, tarjetas de skin, moneda, **logo, icono del juego (512×512) y miniaturas**, pantalla de carga |
| 5 | **Escenarios** | Baldosa modular (normal, agrietada, borde), 2 arenas (1v1 y 2v2), cielo y entorno alrededor del vacío, lobby, polvo y escombros al desmoronarse |
| 6 | Personaje (opcional) | Accesorios/armaduras cosméticas sobre el rig R15 |

### 14.2 Animaciones
Opus **no puede crear keyframes**. Necesitas archivos de animación subidos a Roblox. Opciones:
- **Hacerlas tú** con el *Animation Editor* de Studio (gratis), el plugin *Moon Animator* o *Cascadeur* (asistido por física).
- **Mixamo** (gratis) → Blender → importar a Studio con rig R15 (requiere ajustar el rig).
- **Creator Store/Toolbox**: hay packs, pero **una animación solo se reproduce en tu juego si la subió tu cuenta o grupo** (hasta donde sé; comprobar), así que habría que re-subirlas respetando la licencia.
- **Contratar un animador** (DevForum de Roblox, Fiverr).
- *Animation Capture* de Studio (grabar con cámara) si está disponible en tu versión.

**Fase 1: 64 animaciones** = 8 por arma × 5 armas (reposo, guardia, golpe bloqueado, parry, combo ×3, fuerte) + 24 genéricas (esquivas, patada, reacciones, derribo, levantarse, gatear, agarrar, lanzar, rescatar, activar infusión, victoria/derrota). Detalle en `ASSETS_LISTA.md`.
Cada animación de ataque debe incluir **marcadores** (`Hit`, `WindupEnd`) para sincronizar daño y telégrafo.

### 14.2b Flujo de integración de assets (importante)
- El usuario entrega **por lotes** (ver `ASSETS_LISTA.md`, sección 5). **Primero la Espada completa** (modelo, 8 animaciones, sonidos, efectos del parry), después el resto de armas.
- **Las animaciones de la Espada las está generando el usuario con ChatGPT.** Una IA de texto no produce archivos de animación de Roblox directamente: lo habitual es un script de Luau que construye un `KeyframeSequence` en Studio, que luego hay que abrir en el *Animation Editor* y publicar con la cuenta del usuario para obtener un ID. Calidad y rig pueden variar. **Cuando llegue una animación, comprueba:** que sea R15, que dure lo indicado, que traiga los marcadores (`Hit`, `WindupEnd`, `Release`, `Slap`) y que no rompa el ragdoll. Si falla, díselo al usuario con el motivo (duración, pose, falta de marcador) para que la rehaga.
- **Si una animación aún no existe**, el código usa el placeholder (animación por defecto de la herramienta o un movimiento procedural mínimo) y la lógica de daño usa un **tiempo fijo configurable**; al llegar la animación, el daño pasa a dispararse en el marcador `Hit`.
- Cuando el usuario pegue una tabla `Clave | ID | Notas`, vuelca los IDs en `Assets.lua`, prueba con el AnimTester, ajusta tiempos y reporta qué se integró y qué falta.
- Asegura que **todo se carga desde `Assets.lua` y `Theme.lua`**: nada de IDs ni colores sueltos en el código.

### 14.3 Sonidos
Categorías: golpes (ligero/pesado por tipo de arma), impactos, bloqueo, **parry (choque metálico)**, rotura de guardia, esquiva, patada, derribo, agarrar/lanzar, caída al vacío (viento), baldosas desmoronándose, **activación y bucle de cada infusión + impactos por infusión (×6)**, UI (clics, compra, subida de nivel, desbloqueo), cuenta atrás, victoria/derrota, **música** (lobby, combate, victoria) y ambiente.
Dónde conseguirlos (comprobar siempre la licencia):
- **Creator Store/Toolbox** (audio gratuito de Roblox).
- **Freesound.org** (CC0/CC-BY), **Kenney.nl** y **OpenGameArt** (CC0), **Pixabay** (efectos y música), **Zapsplat** (gratis con atribución), packs gratuitos de **Sonniss GDC**.
- Generadores de efectos con IA (p. ej. ElevenLabs) como complemento.
- Al subir audio a Roblox pueden aplicar límites, costes y moderación: revisar las reglas actuales. Nada de música con copyright.

### 14.4 Contrato de assets (cómo se enchufan sin tocar código)
Opus crea `ReplicatedStorage/Assets.lua` con tablas de IDs y **todo el código lee de ahí**. Si un ID es `0` o está vacío, se usa el placeholder.
```lua
return {
  Animations = {
    Generic = { DodgeF = 0, DodgeB = 0, DodgeL = 0, DodgeR = 0, Kick = 0, HitReactFront = 0, HitReactBack = 0, GuardBreakStagger = 0, ParriedStagger = 0, StunLoop = 0, KnockdownFall = 0, GetUpFront = 0, GetUpBack = 0, Crawl = 0, PickUp = 0, CarryIdle = 0, CarryWalk = 0, ThrowShort = 0, ThrowFar = 0, ReviveChannel = 0, ReviveSlap = 0, InfuseActivate = 0, Victory = 0, Defeat = 0 },
    Weapons = { Sword = { Idle = 0, Block = 0, BlockHit = 0, Parry = 0, M1_1 = 0, M1_2 = 0, M1_3 = 0, Heavy = 0 } --[[ resto de armas igual ]] },
  },
  Sounds = { Swing = {}, Hit = {}, Parry = 0, GuardBreak = 0, Infusion = { Fire = { Start = 0, Loop = 0, Hit = 0 } --[[ ... ]] } },
  Models = { Weapons = { Sword = 0 --[[ MeshId o Tool en ServerStorage ]] } },
  Icons = { Weapons = {}, Infusions = {}, Status = {}, Keys = {} },
}
```
Flujo del usuario: subir el asset a Roblox → copiar el ID → pegarlo en `Assets.lua`. Los marcadores de animación y los `Attachment` de las armas deben usar los nombres de esta sección.

---

## 15. Realismo y game feel (parte de código)
- **Hitstop:** al conectar un fuerte o un parry, bajar un instante la velocidad de la animación del atacante (`AnimationTrack:AdjustSpeed(0.05)` ~0,08 s) y sacudir la cámara del receptor.
- **Levantarse:** no teletransportar al personaje erguido; quitar el ragdoll con animación de rodar/reincorporarse.
- **Lanzamiento:** impulso a ~30° con trayectoria que permita intercepciones.
- **Sincronizar golpes** con `AnimationEvent` en lugar de `task.wait(windup)`.
- Ragdoll: transición animación → ragdoll suave, límites de articulación, menos jitter.
- Reproducción de VFX y sonidos por evento desde `Assets.lua`.

---

## 16. Entorno del usuario (Windows)
- **Python NO está instalado** (solo el alias de la Store). Usar **Node**.
- Generar el lugar de Studio:
  ```
  node "F:\RobloxJuegos\Plataforme 2v2\tools\make_rbxlx.js" "F:\RobloxJuegos\Plataforme 2v2" "F:\RobloxJuegos\Plataforme 2v2\Ragdoll Arena.rbxlx"
  ```
  y abrir `Ragdoll Arena.rbxlx` con `%LOCALAPPDATA%\Roblox\Versions\<versión>\RobloxStudioBeta.exe`. Probar con **Test → Clients and Servers** (2 jugadores = 1v1, 4 = 2v2).
- Error ya resuelto: `GetDataStore` lanzaba excepción en un lugar sin publicar y dejaba el mundo vacío; ahora va con `pcall`.
- Para guardar datos en Studio: publicar el lugar y activar *Enable Studio Access to API Services*.
- Para que genere dinero: publicar, buen icono y miniatura, primeros minutos pulidos (el tráfico decide).
- El usuario también tiene Codex CLI y Gemini CLI para segundas opiniones (ver su `CLAUDE.md` global).
