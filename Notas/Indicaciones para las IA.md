# Indicaciones para las IA (Claude, Gemini y Codex)

Una sola nota para las tres: **no hacer copias por IA**. Si algo cambia, se cambia acá. Actualizada: 10/11/2026.

## Leer primero (en este orden, y nada más salvo que haga falta)
1. Esta nota.
2. [[Versión 0.2]]: todo lo que entra en la próxima versión, con responsable y estado.
3. Solo si la tarea es de combate: [[Arquitectura Combate Direccional]] y [[Equilibrio de armas]].
4. Solo si vas a tocar código: [[Contratos etapa 8]] y [[Referencia LihFolk]].

La carpeta `Archivo 0.1/` es historia de la etapa 8 y la beta: **no hace falta leerla**. Obsidian (`Notas/`) y GitHub (`maticarp912/ragdoll-arena`, rama `main`) son las fuentes actualizadas.

## Reglas de trabajo
- Responder en español rioplatense.
- **Fase actual (desde el 10/11/2026): desarrollo de la 0.2** según [[Plan de desarrollo 0.2]], después de que el usuario responda [[Decisiones pendientes 0.2]]. **Nadie abre Studio ni usa la pantalla** hasta la sesión de integración de Claude.
- Cada entrada o corrección lleva fecha y hora de Argentina (DD/MM/AAAA HH:mm). Conservar el historial; no inventar horas antiguas.
- Cada pedido nuevo va en [[Peticiones del usuario]] (una fila) y su detalle en [[Versión 0.2]]. No repetir el mismo texto en varias notas: enlazar.
- Estados: ✅ comprobado en Studio · 🟡 implementado · 🔧 en curso · ⬜ pendiente · 👤 usuario. No marcar algo como hecho por estar documentado.
- Siempre separar: implementado / comprobado en Studio / pendiente.
- Los valores numéricos van en módulos de datos (`CombatConfig`, `WeaponData`, `UiTheme`, `Economy`…).
- No atribuir al usuario decisiones que no tomó: las propuestas de cada IA se marcan como propuestas.
- Codex y Gemini los maneja el usuario desde sus apps; Claude no los ejecuta solo.
- Antes de entregar código: `node tools/check_lua.js .` y el escáner LihFolk sin errores ni avisos (regla C0). Commits: solo el integrador (regla C0b).

## Reparto de la 0.2 (detalle, modelos y archivos en [[Plan de desarrollo 0.2]])
- **Claude:** combate y servidor, animaciones, efectos y sonido, integración y pruebas en Studio.
- **Gemini:** interfaz y lo visual: triángulo del direccional, HUD nuevo, celular, tienda, armería, ruleta, acabado de skins.
- **Codex:** datos y guardado, roles y administración, niveles, `InputMap`, revisión y pruebas.

## Orden sugerido para los pedidos del 10/11 12:28 (propuesta de Codex, no prioridad confirmada)
Revisar la arquitectura y el código actuales antes de implementar. Separar primero armería y tienda reutilizando catálogo e inventario; armar una vista previa compartida de arma, skin e infusión; validar una skin con el acabado objetivo antes de extenderlo al catálogo; adaptar la ruleta a sus ciclos diario y semanal.

## Continuidad entre IA — 10/11/2026 12:50 (Argentina, UTC-3)
Pedido confirmado: continuar conversaciones entre Claude, Gemini y Codex, conservando ideas en discusión.
- Frase: **Continuar desde Obsidian**. Opcional: **Vengo de Codex/Claude/Gemini** y el tema. No es requisito usar la frase para guardar contexto.
- En cada intercambio sustantivo, antes de responder registrar pedido breve en [[Peticiones del usuario]], detalle en [[Versión 0.2]] y actualizar el contexto actual de abajo. Incluir decisiones, motivos, propuestas, alternativas descartadas relevantes, preguntas y próximo paso. No copiar transcripciones ni crear notas por IA.
- Conservar historial fechado en diseño y un único contexto actual. Al retomar, leerlo y seguir las secciones enlazadas.
- Las IA no tienen acceso automático a chats privados de otras apps: la continuidad depende de los archivos. Sin acceso, decirlo y entregar resumen para pegar, sin fingir lectura o guardado.
- Solo Claude hace commits/push según C0b. Codex/Gemini dejan cambios locales e indican qué sincronizar. Desde otra máquina, verificar sincronización.

### Contexto actual — Codex, 10/11/2026 14:11 (Argentina, UTC-3)
Tema actual: desarrollo 0.2 ronda 1 backend según [[0.2 Ronda 1 - Codex]]. Decisiones D1-D22 ya aprobadas en [[Decisiones pendientes 0.2]]; almas son el mismo saldo Coins, sin pérdida al morir (D5). El contexto anterior de dudas de diseño queda superado por esas decisiones.
Entrega y pruebas pendientes: [[Reporte 0.2 Codex]]. APIs finales C17-C22: [[Contratos 0.2]]. Implementados archivos de backend, sin abrir Studio ni modificar place ni hacer commit. Falta integrar el permiso Debug de Tester en CombatService (Claude), overhead/cinemática (Claude) y previews/UI (Gemini); pruebas enumeradas en reporte. Rewards completo se hace en ronda 2.
Próximo paso: Claude revisar, integrar los pedidos y sincronizar GitHub; luego sesión de pruebas separada. No confundir revisión estática con comprobación en Studio.
