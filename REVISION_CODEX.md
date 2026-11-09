# Revisión Codex — 8/11/2026

## Cambios preparados
- Tarea 1: el panel de derribo y los avisos de interacción/carga se ocultan al morir.
- Tarea 2: los golpes de muñecos dejan al jugador con un mínimo configurable de 1 de vida fuera de partidas (decisión confirmada por el usuario). Los lanzamientos usan la misma función de daño. La carga de infusión cuenta el daño efectivamente recibido, también ante ForceField.
- Tarea 4: protección del cálculo IK ante un objetivo coincidente o huesos sin longitud. No se cambiaron ángulos sin verlos en Studio.
- Tarea 6: desconexión del evento Died del cargado al soltarlo; evita acumular callbacks al repetir agarres.
- Tarea 9: nueve botones del menú usan Activated para admitir ratón, toque y mando. Navegación y persistencia aún necesitan prueba interactiva.
- Tareas 10–11: el efecto FOV añade y retira su aporte sobre el FOV actual; no fuerza 70 cuando está inactivo y admite cambio de cámara. Hitstop centralizado en Animator para clips procedurales y AnimationTracks; pausas superpuestas prolongan el plazo y restauran la velocidad original.
- Tarea 12: reutilización de buffers de pose y transforms por personaje; menos tablas temporales para la postura base. Optimización parcial: aún hay vectores temporales y no se midió rendimiento.
- Estelas: reiniciar el estado de estela al interrumpir un clip por ragdoll o muerte.

## Comprobaciones
- Chequeo básico de los 27 archivos Luau: correcto. No equivale a compilar Luau ni ejecutar Roblox.
- Lugar de prueba generado desde los fuentes y comprobado contra el contenido de todos los scripts.
- El generador ya escribe Technology=4 (intención Future) y GameSettingsAvatar=1 (intención R15), además de desactivar Shift Lock. Falta comprobar que la versión de Studio los acepte.
- No se ejecutó Play ni se confirmó visualmente ninguna pose, sonido o comportamiento físico durante esta revisión.

## Prueba en Studio
1. Guardar cualquier trabajo manual que interese antes de cambiar de lugar. Abrir Ragdoll Arena - Codex.rbxlx y pulsar Play.
2. P: práctica; muñeco en Fuertes. Recibir golpes hasta llegar a 1 de vida. Deben continuar el Stun y los derribos, sin muerte por sus golpes. Resetear el personaje estando derribado: el panel debe desaparecer y reaparecer solo ante un nuevo derribo.
3. Golpe fuerte y parry repetidos: comprobar que los clips se recuperan sin quedar lentos; revisar cámara con lock-on y sin él.
4. Repetir agarre, soltar y lanzamiento. Revisar orientación sobre los hombros, fuerza y escape. Probar interrupción con un segundo jugador.
5. B: probar todos los botones con ratón y mando; cambiar asignaciones, volver a entrar y comprobar persistencia (requiere guardar datos correctamente).
6. Cambiar por las cinco armas y revisar postura, guardia, combo y fuerte. En Espadón/Maza comprobar mano izquierda sobre el mango y codo natural; en Dagas, orientación de la izquierda.
7. Leer Salida: errores de Animator, carga de sonidos, propiedades del lugar y DataStore.

## Pendiente
- Tareas 3–8: validación visual de clips, agarre a dos manos, ragdoll, lanzamientos y modelos; audios solo se sustituyen si se verifica un fallo.
- Tareas 9–10: encuadre de vistas, navegación completa con mando, guardado real, cantidad de partículas y viñeta.
- Tarea 13: aceptación real en Studio de iluminación y rig.
- Fases B completa, C, E y botones móviles siguen pendientes. No se implementaron sistemas nuevos en este lote de correcciones.

Los archivos de traspaso anteriores contienen descripciones históricas que ya no coinciden completamente con el código. Para esta revisión se tomó TAREAS_CODEX.md como lista actual y el código como evidencia; no se reinició el desarrollo desde Fase A.

## Segunda revisión: cámara y transiciones
- Se libera el objetivo al iniciar PickUp, al cargar, al ser cargado o al morir. No se puede volver a fijar un cuerpo cargado. La dirección de lanzamiento usa la cámara libre.
- Suavizado de cámara independiente de FPS.
- Mezcla desde la pose visible al cambiar de acción y recuperación gradual al terminar. Afecta a todos los arquetipos y clips genéricos.
- Defensa diferenciada para cinco arquetipos; dagas responden con ambos brazos.
- Arma oculta durante recogida y lanzamiento, además de durante la carga.
- IK admite agarre AnimationConstraint y JointInstance.
- Chequeo estático correcto; falta prueba visual en Studio. No se considera terminado el pulido artístico de todas las animaciones.
- Prueba prioritaria: T sobre muñeco, derribarlo, R para alzarlo, caminar y girar, mantener E y soltar. La cámara debe permanecer libre y el lanzamiento seguir la mirada.
