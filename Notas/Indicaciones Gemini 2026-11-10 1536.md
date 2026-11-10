# Indicaciones para Gemini — 10/11/2026 15:36 (Argentina, UTC-3)

Pedido del usuario (10/11/2026 15:36): «ahora estoy trabajando con Claude para ahorrar tokens, luego seguiré en Gemini también, dejale las mismas indicaciones a él, así podemos mantener el mismo flujo de trabajo».
Son **las mismas indicaciones** que [[Indicaciones Claude 2026-11-10 1229]], para que Claude, Gemini y Codex trabajen con el mismo flujo. Si una cambia, actualizar las dos notas.

## Leer primero
1. [[Correcciones 2026-11-10 1228]] y su referencia visual [[Referencias/espada-concepto.png]].
2. [[Versión 0.2]]: todo lo que entra en la próxima versión, con responsable y estado.
3. Combate direccional: [[Arquitectura Combate Direccional]], [[Especificación Gemini combate direccional]] y [[Diseño Combate PvP Direccional Roblox]].
4. [[Equilibrio de armas]] («Propuesta de números para la 0.2», pendiente de aprobar).
5. [[Peticiones del usuario]] y [[Contratos etapa 8]] (C0: escáner LihFolk sin errores; C0b: solo el integrador hace commits).

Obsidian (`Notas/`) y GitHub (`maticarp912/ragdoll-arena`, rama `main`) son las fuentes actualizadas.

## Reglas de trabajo (iguales para las tres IA)
- Responder en español rioplatense.
- **Fase actual: solo diseño y notas. No tocar código** hasta que el usuario lo apruebe.
- Cada entrada o corrección en las notas lleva fecha y hora de Argentina (DD/MM/AAAA HH:mm). Conservar el historial; no inventar horas antiguas.
- Registrar cada pedido en [[Peticiones del usuario]] con estado: ✅ comprobado en Studio · 🟡 implementado · 🔧 en curso · ⬜ pendiente · 👤 usuario.
- Separar siempre: implementado / comprobado en Studio / pendiente. No marcar algo como hecho por estar documentado.
- Los valores numéricos van en módulos de datos (`CombatConfig`, `WeaponData`, `UiTheme`, `Economy`…), no sueltos en scripts.
- No atribuir al usuario decisiones que no tomó: las propuestas de cada IA se marcan como propuestas.

## Pedidos confirmados (10/11/2026 12:28)
1. **Horario en las notas**, como arriba.
2. **Combate:** series de combos según la dirección. Integrar al diseño direccional sin dar por definidas secuencias, longitudes ni transiciones.
3. **Skins:** rediseñar TODAS con el nivel visual de la espada de referencia: mejor acabado, más detalle y brillo, formas menos cuadradas y más filosas. El dibujo del usuario es la referencia principal; la imagen de Pinterest, secundaria. La espada generada es un concepto 2D, no un modelo 3D: hay que traducirla a assets reales y revisar silueta, materiales y legibilidad en juego.
4. **Ruleta:** sumar esta espada y un par de skins más a la MISMA ruleta de monedas y XP. Tiradas diarias y skin o premio grande que rota cada semana. No crear otra ruleta.
5. **Tienda:** rediseñar la que ya existe con presentación al estilo Fortnite y vistas previas, reutilizando lo que hay. No copiar su identidad gráfica.
6. **Armería separada de la tienda:**
   - armería: elegir arma, skin e infusión, con vista previa antes de salir;
   - tienda: comprar skins, multiplicadores y monedas, también con vistas previas.

## Pendiente de definir (no inventar respuestas)
- Secuencias de combos, cambios de dirección, cancelaciones, resistencia y equilibrio.
- Tiradas diarias, reinicio diario y semanal, probabilidades y duplicados de la ruleta.
- Skins extra del primer ciclo y catálogo de premios semanales.
- Navegación y controles de las vistas previas.
- En el combate direccional: la tabla de conflictos de [[Arquitectura Combate Direccional]] (sección 0) y los números de [[Equilibrio de armas]] esperan la aprobación del usuario.

## Lo que le toca a Gemini (reparto sugerido, a confirmar)
- Interfaz y lo visual: triángulo invertido del combate direccional (paso 2), HUD nuevo (vida grande abajo al centro e infusión encima), soporte de celular (botones, textos legibles, zonas seguras).
- Tienda y armería nuevas (interfaz y vistas previas), ruleta (interfaz y animación).
- Propuestas de acabado de skins a partir de la espada de referencia.
- Claude: combate, servidor, animaciones y efectos. Codex: datos, guardado, `InputMap`, revisión y pruebas.

## Orden sugerido (propuesta, no prioridad confirmada)
Revisar la arquitectura y el código actuales antes de implementar. Separar primero armería y tienda reutilizando catálogo e inventario; armar una vista previa compartida de arma, skin e infusión; validar una skin con el acabado objetivo antes de extenderlo al catálogo; adaptar la ruleta a sus ciclos diario y semanal.

Cuando se implemente, probar en Studio: selección y equipamiento, compra y guardado, vistas previas, reinicios de la ruleta y lectura del combate.

## Estado de esta entrega
Solo documentación (Claude). No se tocaron scripts, modelos ni el place.
