# Indicaciones para Claude — 10/11/2026 12:29 (Argentina, UTC-3)

Pedido explícito del usuario: dejar a Claude las indicaciones de esta conversación. Leer primero [[Correcciones 2026-11-10 1228]] y su referencia [[Referencias/espada-concepto.png]]. Obsidian y GitHub son las fuentes actualizadas indicadas por el usuario.

## Pedidos confirmados
1. Desde ahora, cada entrada o corrección de notas debe incluir fecha y hora de Argentina (DD/MM/AAAA HH:mm). Conservar historial; no inventar horas antiguas.
2. Combate: series de combos según dirección. Integrar al diseño direccional vigente, sin asumir que ya están definidas secuencias, longitudes o transiciones. La nota anterior que limitaba el primer prototipo no elimina este nuevo pedido para el diseño completo.
3. Rediseñar TODAS las skins con el nivel visual de la espada adjunta: mejor acabado, más detalle y brillo, formas menos cuadradas y más filosas. El dibujo del usuario es la referencia principal; la imagen de Pinterest fue referencia secundaria de acabado. La espada generada es concepto 2D, no modelo 3D ni UV terminado. Traducir el acabado a assets reales y revisar silueta, materiales y legibilidad en juego.
4. Incluir esta espada y un par de skins más en la MISMA ruleta que entrega monedas y XP. Tiradas diarias; rotación semanal de la skin o recompensa grande. No duplicar la ruleta.
5. Rediseñar la tienda existente con presentación similar a Fortnite y vistas previas, reutilizando lo que ya tenemos. No reemplazar todo desde cero ni copiar su identidad gráfica.
6. Separar armería y tienda: armería para elegir armas, skins e infusión, con vista previa de la selección antes de salir; tienda para comprar skins, multiplicadores y monedas, también con vistas previas.

## Pendiente de definir, sin atribuir al usuario decisiones inventadas
- Secuencias de combos, cambios de dirección, cancelaciones, stamina y balance.
- Cantidad de tiradas diarias, reinicio diario/semanal, probabilidades y duplicados.
- Skins adicionales del primer ciclo y catálogo de recompensas semanales.
- Navegación concreta y controles de las vistas previas.

## Continuación sugerida por Codex
Revisar la arquitectura y el código actuales antes de implementar. Separar primero los flujos de armería y tienda reutilizando catálogo e inventario; establecer una vista previa compartida de arma, skin e infusión; validar una skin con el acabado objetivo antes de extenderlo al catálogo; adaptar la ruleta existente a sus ciclos diario y semanal. Esto es una propuesta de orden, no una prioridad adicional confirmada por el usuario.

No marcar tareas como implementadas o comprobadas por estar documentadas. Probar selección/equipamiento, compra y persistencia, previews, reinicios de ruleta y lectura de combate en Studio cuando se implementen.

## Estado de esta entrega
Codex solo actualizó documentación y guardó el concepto visual. No modificó scripts del juego, modelos ni el place. Las primeras notas y referencia están publicadas en GitHub en el commit 4b01c00. Existe una modificación previa local en Notas/Versión 0.2.md: no fue incluida ni reemplazada por Codex.
