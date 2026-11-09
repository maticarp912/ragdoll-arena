# Aporte independiente de Codex

El usuario pidió ayudar con animaciones y arena mientras Claude trabaja. Este paquete agrega archivos nuevos; no reemplaza AnimClips, Animator, MatchService ni el lugar abierto.

## Integración

Copiar ArenaArtConfig.lua a ReplicatedStorage y los dos LocalScripts a StarterPlayerScripts. El generador actual los incluye automáticamente al generar desde esas carpetas. No requieren assets externos, plugins ni servicios de pago.

ArenaArt dibuja fragmentos de montaña bajo cada Tile en Arena_1v1/2v2. Siguen la caída, emiten polvo al desprenderse y se reconstruyen cuando vuelve la baldosa. Las rocas no colisionan ni participan en raycasts. La configuración permite apagar el efecto o limitar distancia/densidad. Es una primera base geométrica: falta la revisión visual del perfil, iluminación y rendimiento con 490 baldosas.

PoseReview: F8, solo con DebugAllowed. Lista automáticamente todos los ataques, defensas y genéricas disponibles. Permite congelar 0/25/50/75/100% y liberar la pose. Cambiar arma con B; probar reposo y bloqueo normalmente con F. Usa PoseFreeze del Animator existente; no mueve cámaras ni cambia daño. Cerrarlo antes de jugar normalmente.

## Revisión de animaciones pendiente

1. Espada, espadón, dagas, estoque y maza: revisar en vista lateral y frontal, ataques a 0/25/50/75/100%; confirmar arma fuera del torso y codos naturales. Mantener los tiempos Hit/WindupEnd del servidor.
2. Mano izquierda en armas pesadas: confirmar RightGrip en el rig real; la compatibilidad implementada antes necesita prueba de Attachment0/1 y orientación. No invertir el polo sin verlo.
3. Corrección importante a verificar en Animator: los clips reales de Assets pueden seguir siendo sobrescritos por poses procedurales de torso/brazos. Ceder las articulaciones al AnimationTrack durante clips reales y al probarlos con AnimTester.
4. Las animaciones genéricas StunLoop, Crawl, GetUpFront, CarryIdle/Walk, ReviveChannel, Victory/Defeat figuran en Assets pero no todas tienen fallback en AnimClips. Implementarlas conforme a los estados realmente disponibles; no marcar el catálogo completo como terminado.
5. Transiciones: comprobar cancelación de fuerte, ragdoll durante un ataque, recuperación de piernas y mezcla al encadenar combos. La segunda revisión Codex añadió mezcla y recuperación, aún sin prueba visual.
6. Agarre: la fijación debe liberarse desde PickUp y no apuntar al cuerpo cargado. Lanzar debe seguir la mirada.

## Pruebas de arena

Probar las dos arenas: inicio, aviso rojo, desprendimiento, final de ronda y reinicio. Mirar desde un borde para verificar que no quedan rocas suspendidas ni superficies visuales que parezcan transitables. Medir FPS en un dispositivo modesto. StreamingEnabled puede entregar una arena parcial: el centro estimado en ese caso requiere mejora antes de habilitar streaming.

No se ejecutó Play ni se aprobaron visualmente las poses o la arena durante la preparación de este paquete. Coordinar con el usuario y registrar resultados reales antes de declararlo pulido.
