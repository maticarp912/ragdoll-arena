# Producción de videojuegos con IA

Investigación y propuesta para Ragdoll Arena · 13/11/2026 (Argentina). Continúa [[Chat local y coordinación de agentes]]. Se revisó documentación pública. Las herramientas todavía requieren un piloto en el proyecto.

## Qué tomar de repositorios públicos

| Referencia | Qué muestra | Aplicación |
| --- | --- | --- |
| [GitHub Spec Kit](https://github.com/github/spec-kit/blob/main/docs/quickstart.md) | Especificación, plan, tareas y verificación como pasos distintos. | Especificación completa en Obsidian para funciones grandes como un jefe PvE. Cada agente recibe su tarea y los contratos que usa. |
| [Anthropic Skills](https://github.com/anthropics/skills) y [Agent Skills](https://github.com/agentskills/agentskills/blob/main/docs/specification.mdx) | Instrucciones reutilizables con scripts y referencias que se cargan según la necesidad. | Procedimientos por área para armas, animación R15, HUD, audio y arenas. Un índice breve permite al chat local recuperar la sección pertinente. |
| [Roblox Creator Docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/ai/build-with-assistant.md) y [Studio MCP](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md) | Prototipo, prueba en Studio y pulido. MCP da acceso al place abierto. | Codex integra y comprueba en una copia de prueba. Las pruebas de jugabilidad y las capturas llegan al chat único. |
| [ComfyUI](https://github.com/Comfy-Org/ComfyUI) | Flujos de generación visual reutilizables. | Evaluar más adelante un flujo local para variantes de iconos y texturas. Probar el modelo elegido con 8 GB de VRAM antes de incorporarlo. |

La longitud del prompt depende de cuántas decisiones necesita tomar el agente. Guardar el detalle en tres niveles: **guía del proyecto**, **procedimiento del área** y **orden concreta**. Un arma puede necesitar dos referencias, una ficha de mango y una prueba en Studio. Un jefe necesita reglas de combate, estados, fases, condiciones de victoria, comportamiento al reiniciar y casos de prueba.

## Herramientas a evaluar

| Área | Herramienta | Piloto y criterio |
| --- | --- | --- |
| Concepto, iconos, HUD y promoción | Generación de imágenes de ChatGPT o Gemini, usando las cuentas actuales según disponibilidad. ComfyUI como opción para repetir un flujo local. | Producir tres propuestas con la misma referencia. Aprobar silueta, legibilidad y paleta. Implementar botones y textos como UI de Roblox. |
| Props, armas y skins | [Roblox Assistant](https://create.roblox.com/docs/assistant/guide), [Meshy](https://docs.meshy.ai/en/api/image-to-3d) y [Tripo](https://developers.tripo3d.ai/en/pricing). Blender Python para normalizar, validar y exportar. | Usar la misma imagen para comparar un arma y un prop. Medir tiempo total hasta importación, geometría, textura, escala, origen del mango, colisión y legibilidad en combate. Usar el catálogo y los scripts Blender existentes como referencia. |
| Animaciones de golpes y jefes | [DeepMotion Animate 3D](https://www.deepmotion.com/pricing-animate3d) para video a FBX. Blender y los scripts de retarget R15 del repo para agarre, trayectoria, poses y timing. | Comparar tres ataques de un arma con el flujo actual. Verificar que la anticipación se lea, las manos mantengan el agarre y el cuadro de contacto coincida con HitAt. Probar desde ambos clientes. |
| SFX y voces | [ElevenLabs Sound Effects](https://elevenlabs.io/sound-effects) y TTS para voces ficticias. | Armar un set de golpe, bloqueo, parry, fallo y alerta de jefe. Validar si se distinguen sin HUD y registrar origen, plan y permiso por asset. Para música comprobar los [términos específicos](https://elevenlabs.io/eleven-music-model-specific-terms) según uso y plan antes de incorporar un tema. |
| Diseño, narrativa, programación y QA | Codex, Claude Code y Antigravity. Studio MCP, chequeos existentes y pruebas de cliente-servidor. | Codex integra. Antigravity produce interfaces, arenas o guiones acotados. Claude revisa casos difíciles de timing, economía o lógica de NPC. Automatizar reproducibilidad y evidencia. Mati aprueba arte, mecánicas y publicación. |
| Importación y entrega | [Blender por CLI](https://docs.blender.org/manual/es/5.0/advanced/command_line/arguments.html), [Roblox Open Cloud Assets](https://create.roblox.com/docs/cloud/guides/usage-assets) y Studio. | Probar los formatos y permisos por tipo. Para mallas nuevas usar el importador o validar la subida como Model. Las animaciones tienen su propio formato de subida. Comprobar IDs, moderación y acceso desde el place de prueba. |

### Costos de referencia

- Meshy anuncia Pro a US$20/mes con acceso a API y derechos comerciales según su [comparación de planes](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra). Tripo publica API por créditos y cobra operaciones adicionales según el flujo. Elegir uno tras el mismo piloto.
- DeepMotion muestra Starter a US$9/mes con facturación anual. Confirmar el plan, los derechos de uso y el acceso a API antes de comprar.
- ElevenLabs muestra Starter a US$6/mes después del precio inicial. La [tarifa de ElevenAPI](https://elevenlabs.io/pricing/api) se consulta por separado. Precios en USD sujetos a cambios e impuestos.
- Primera compra propuesta: solo la herramienta que reduzca el tiempo hasta obtener un asset aprobado. Comparar costo por asset aceptado, incluyendo regeneraciones, limpieza e integración.

## Cómo conservar el estilo de Mati

Guardar referencias aprobadas y rechazadas con una razón concreta. Para Ragdoll Arena, documentar siluetas por familia de arma, materiales y paleta, claridad del impacto, ventanas de reacción, composición del HUD y lectura de bordes de arena. Una referencia visual aprobada viaja con la tarea. Al aprobar o rechazar, el chat pregunta qué atributo repetir o corregir y lo propone como actualización de Obsidian. Conservar el historial de cambios y vincular la evidencia en Studio.

### Orden piloto · ataque fuerte de espada

- **Objetivo.** Entregar una variante que conserve agarre y lógica direccional, con anticipación, contacto y recuperación legibles.
- **Insumos.** Clip actual, arma de referencia, rig R15 del repo y contrato de impacto del servidor. Añadir video de referencia si se usa mocap.
- **Entregables.** Fuente editable, FBX o clip compatible con el flujo actual, captura lateral y frontal, registro del cuadro de contacto y diff de integración si corresponde.
- **Aceptación.** En Studio, comprobar el agarre durante el arco, sincronizar el impacto con HitAt y verificar bloqueo y parry contra un segundo cliente. Mati aprueba la sensación jugando.
- **Alcance.** La tarea cubre animación e integración del ataque especificado. Una propuesta de cambio de reglas o balance se registra para decisión aparte.

## Etapas propuestas

1. **Duelo Espada vs. Dagas.** Un golpe de referencia por arma, una skin y un set de SFX. Comparar calidad, tiempo, cuota y retrabajo frente al flujo actual. Pulir el HUD móvil y probar una partida en línea.
2. **Producción por tandas.** Validar exportación y revisión por familia de arma. Reutilizar el procedimiento para más ataques, skins y una segunda arena. Guardar entrada, parámetros, versión, licencia y resultado por asset.
3. **PvE.** Una arena, dos oleadas de aprendizaje y un jefe con patrones direccionales. Los agentes preparan diseño, código, modelo, animación, UI, sonido y pruebas. Mati elige la dirección y acepta la jugabilidad. Evaluar historia después de comprobar que el encuentro tiene valor de repetición.
4. **Reusar el proceso en otro juego.** Conservar la cola, plantillas, validadores y exportadores. Darle al juego nuevo su propia guía de estilo, mecánicas, referencias y pruebas de aceptación.

El objetivo es delegar la producción de punta a punta y llegar a aprobaciones con evidencia. El nivel de automatización de cada etapa se mide por lo que el flujo ya puede generar, integrar y comprobar en Studio.
