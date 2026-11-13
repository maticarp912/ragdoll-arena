# Chat local y coordinación de agentes

**Estado** — Propuesta para retomar e implementar. Registrada el 13/11/2026 (Argentina).

## Objetivo

Mati usa un solo chat para registrar bugs, ideas y actualizaciones. Obsidian conserva las decisiones y especificaciones del juego. La IA local consulta las fuentes vigentes y prepara encargos independientes para Codex, Claude Code y Antigravity. Git conserva el cambio exacto y GitHub permite revisarlo y retomarlo.

## Flujo propuesto

1. Registrar el pedido original, los adjuntos y su fecha. Vincular duplicados y pedir por el mismo chat cualquier dato que cambie el alcance.
2. Recuperar fragmentos de las notas relevantes y los archivos necesarios del repo. Guardar rutas, secciones y revisión del repo. Ante fuentes contradictorias, señalar el conflicto.
3. Dividir el pedido en tareas comprobables. Cada tarea tiene un responsable, dependencias, alcance de escritura y criterio de aceptación. Lanzar una sesión nueva por encargo independiente y retomar la misma para sus correcciones.
4. Despachar por CLI cuando la sesión y la cuota del proveedor estén verificadas. Usar una rama y un worktree por tarea que escriba código. Para un asset aislado, preparar una carpeta con sus insumos y su lugar de entrega. Ejecutar en paralelo cuando las tareas sean independientes.
5. Recibir archivos, diffs, capturas y pruebas. El chat muestra qué está implementado, qué se comprobó y qué queda pendiente. Codex integra y verifica en Studio. Registrar decisiones reutilizables en Obsidian y enlazar el commit o PR. Proponer aprobación desde el chat para fusionar o publicar.

## Preparar insumos para los agentes

Usar Markdown breve para las órdenes y extractos de documentación. El ahorro viene de enviar menos texto relevante y evitar lecturas repetidas. Cambiar la extensión a .md por sí solo no reduce los tokens. Mantener los originales como fuente.

| Insumo | Preparación local |
| --- | --- |
| Notas Markdown, PDF o Word | Extraer texto, recuperar solo las secciones pertinentes y conservar encabezados, rutas y páginas. Usar OCR si el PDF es escaneado y señalar lecturas dudosas. |
| Logs de Studio y diffs | Extraer error, pila, pasos de reproducción y fragmentos relevantes. Conservar el mensaje exacto y enlazar el original. |
| Capturas, modelos, animaciones y audio | Adjuntar los originales necesarios. Añadir una ficha corta de lo que hay que observar o verificar. |
| Configuración y código | Enviar el fragmento o archivo original que define el contrato. Conservar nombres, números, unidades y rutas. |

Cada orden incluye **objetivo, contexto mínimo, insumos y fuentes, alcance, entregables, prueba de aceptación y dudas pendientes**. El programa valida estos campos y aplica las reglas de despacho. El modelo local redacta y clasifica. Las instrucciones dentro de logs y documentos se tratan como contenido de referencia.

### Ejemplo · una skin de espada

- **Antigravity** recibe la silueta y el acabado de referencia, el modelo Vigilia Violeta para escala, orientación y origen del mango, y una carpeta de entrega. Devuelve el .blend, FBX, textura y captura. Se comprueba el agarre superponiendo ambos modelos.
- **Codex** recibe los assets resultantes y las instrucciones de integración. Comprueba agarre, visor de Armería y anclajes de estela e infusión en Studio.
- **Claude Code** recibe un caso reproducible y el diff si aparece un desajuste difícil de animación o impacto.

## Reparto y plan de implementación

- **Local:** Ollama con Qwen3.5 4B como punto de partida en la RTX 3060 de 8 GB. Extraer, condensar, agrupar duplicados y preparar encargos. Usar scripts para validaciones repetibles.
- **Codex:** integración, Luau y pruebas en Studio. **Antigravity:** producción acotada de arte técnico, interfaz y arenas. **Claude Code:** revisión puntual de combate, animación y multijugador. Reservar los modelos de mayor esfuerzo para tareas que lo justifiquen.
- **Primera etapa:** probar una interfaz web local con cola persistente, búsqueda por títulos y secciones de Obsidian, y vista previa de la orden Markdown. Usar una skin como piloto de producción y un bug del HUD como piloto de código.
- **Segunda etapa:** conectar `codex exec`, `agy -p` y `claude -p` de a uno. Validar autenticación, modelo y cuota con tareas de lectura antes de habilitar cambios. Ante un límite o fallo, dejar la tarea visible para reintentar desde el chat.
- **Tercera etapa:** conectar ramas, evidencias y actualización de notas. Medir tamaño de la orden, cantidad de ejecuciones en la nube, consumo visible y tiempo de retrabajo. Comparar con el flujo anterior antes de sumar más automatización.

## Aplicación a Ragdoll Arena

Empezar por el duelo Espada vs. Dagas con una arena. Pulir anticipación, impacto y recuperación de los golpes, agarre y skins, lectura del HUD y del borde. Cuando el flujo esté probado, extenderlo a Espadón, Estoque y Maza, más arenas e interfaces. Para PvE, probar más adelante un desafío solitario con dos oleadas de aprendizaje y un jefe que use las reglas de combate direccional. El modo historia queda como idea para desarrollar después de probar el desafío.

Notas relacionadas: [[Indicaciones para las IA]], [[Traspaso a Codex]], [[Versión 0.3]] y [[Catálogo de skins]].
