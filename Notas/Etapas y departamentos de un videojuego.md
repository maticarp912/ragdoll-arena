# Etapas y departamentos de un videojuego

Investigación y propuesta · 13/11/2026. Continúa [[Producción de videojuegos con IA]] y [[Chat local y coordinación de agentes]]. Las herramientas se eligen por tipo de entrega y compatibilidad con el motor. Son candidatas para validar mediante un piloto.

## Etapas y entregables

| Etapa | Entrega y decisión |
| --- | --- |
| Concepto y viabilidad | Público, plataformas, fantasía del jugador, ciclo principal, alcance, presupuesto y riesgos. Elegir qué prototipar. |
| Preproducción | Prototipos de mecánicas, guía visual y sonora, arquitectura, herramientas y plan. Resolver los riesgos principales. |
| Vertical slice | Tramo representativo con calidad objetivo y flujo completo de producción. Medir qué cuesta reproducirlo. |
| Producción | Sistemas, niveles, assets y contenido por tandas. Integrar y probar continuamente. |
| Alfa | Hacer jugable el alcance acordado de punta a punta. Detectar contenido faltante y problemas estructurales. |
| Beta y estabilización | Regresión, rendimiento, accesibilidad, dispositivos, localización, balance, soporte y pruebas externas. |
| Candidato y lanzamiento | Compilación aprobada, tienda, clasificación aplicable, permisos de assets, publicación y plan de recuperación. |
| Operación y cierre | Telemetría, soporte, moderación, parches, contenido y eventual transición, archivo o cierre. |

La nomenclatura depende del estudio. QA, dirección y producción atraviesan las etapas. En un indie una persona puede llevar varias funciones.

## Departamentos y primera elección

| Departamento | Herramienta propuesta y entrega |
| --- | --- |
| Dirección creativa y producción | Gemini o ChatGPT para explorar y criticar. Ollama + Obsidian para recuperar decisiones. GitHub para responsables, dependencias y evidencia. |
| Diseño de juego y economía | Claude o Gemini para especificar reglas y casos límite. Python para simular progresión y balance. Validación jugando y con telemetría. |
| Narrativa y audio narrativo | Claude para biblia, diálogos y ramas. ElevenLabs si hay voces. Aprobar canon y actuación. |
| Concepto y dirección de arte | ChatGPT Images o Gemini para variantes visuales. Guardar referencias aprobadas y criterios. |
| Modelado 3D y materiales | Blender dirigido por Antigravity para armas modulares. Meshy o Tripo para bases orgánicas. Substance 3D Sampler si hay volumen de materiales PBR. |
| Rigging y animación | DeepMotion para video a movimiento. Cascadeur para poses y física asistidas. Blender para retarget, contactos y exportación. |
| Arte técnico, VFX e iluminación | Antigravity o Claude Code con Blender y herramientas del motor. Presupuestos de geometría, memoria y efectos por dispositivo. |
| Niveles y encuentros | Gemini para iterar el diseño, agente del motor para bloquear y probar. Medir rutas, cámara, legibilidad y dificultad. |
| UX, UI y accesibilidad | Antigravity para implementar en el motor. Figma Make si hace falta un prototipo navegable. Pruebas con usuarios y dispositivos. |
| Audio y música | ElevenLabs para SFX y voz. Herramienta de audio para mezcla, loops y niveles. Revisar licencia antes de publicar música. |
| Ingeniería, backend y builds | Claude Code o Codex, un responsable. Separar gameplay, motor, red, datos, builds y seguridad según tamaño. CI, revisión y pruebas. |
| QA y rendimiento | Agente de código + pruebas nativas del motor primero. Evaluar GameDriver para Unity/Unreal o modl.ai según escala. Playtests humanos para sensación y comprensión. |
| Localización | DeepL con glosario y revisión contextual de Claude/Gemini. Probar textos, variables y tamaños dentro del juego. |
| Publicación y marketing | ChatGPT o Gemini para fichas y materiales. Capturas reales para mostrar gameplay. Veo para piezas promocionales cuando corresponda. Aprobar envíos. |
| Operación, comunidad y datos | Analítica del motor o GameAnalytics más IA para resumir, priorizar y preparar respuestas. Validar alertas y cambios de balance. |

## Cómo se conectan

Obsidian conserva la especificación general. El chat local genera un encargo por entrega, con entradas, responsable, criterio de aceptación y enlaces. GitHub conserva revisiones y evidencia. El integrador arma la versión de prueba. Mati aprueba arte, mecánicas y salida pública.

Piloto Ragdoll Arena: una arena, Espada vs. Dagas, un fuerte pulido por arma, una skin y cuatro señales de audio. Usar las herramientas actuales primero y comparar una especializada por vez cuando haya un cuello de botella medible. Para extender el flujo a otro motor, cambiar los adaptadores de importación, prueba y publicación.

## Fuentes

- [Mapa de roles de ScreenSkills](https://www.screenskills.com/media/xskl5wdb/2756-games-career-map-interactive-feb25-final.pdf) · [Etapas de desarrollo](https://www.gamedevfoundry.com/StagesOfGameDevelopment.html) · [GitHub Spec Kit](https://github.com/github/spec-kit/blob/main/docs/how-to/spec-of-specs.md)
- [Meshy](https://docs.meshy.ai/en/api/image-to-3d) · [Cascadeur](https://cascadeur.com/help) · [DeepMotion](https://www.deepmotion.com/animate-3d) · [Substance 3D Sampler](https://experienceleague.adobe.com/en/docs/substance-3d-sampler/using/filters/tools/image-to-material)
- [Figma Make](https://help.figma.com/hc/es-419/articles/31304485164695-Crear-y-editar-un-prototipo-funcional-o-una-app-web) · [ElevenLabs SFX](https://elevenlabs.io/docs/overview/capabilities/sound-effects) · [Veo](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/veo/3-1-generate)
- [Roblox Studio MCP](https://create.roblox.com/docs/studio/mcp) · [Unity Test Framework](https://docs.unity3d.com/es/current/Manual/com.unity.test-framework.html) · [GameDriver](https://www2.gamedriver.io/en-us/pricing) · [Steamworks Release Process](https://partner.steamgames.com/documentation/releasing)
- [DeepL API](https://developers.deepl.com/docs/learning-how-tos/examples-and-guides/how-to-use-translation-memories) · [GameAnalytics](https://docs.gameanalytics.com/products-and-features/analytics-iq/dashboards/overview/) · [Roblox Retention](https://create.roblox.com/docs/production/analytics/retention)
