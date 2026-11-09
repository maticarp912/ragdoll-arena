# Pendientes (etapa 8)

Reparto completo, archivos y contratos: [[Reparto etapa 8]].

## Claude
- [x] ✅ Contratos para trabajar en paralelo: fragmentos de idioma (`LocaleCodex`, `LocaleGemini`) y mensajes de partida con clave (`StatusKey`).
- [ ] Combate: vida +35 % (sobre los valores actuales), dash más corto (hoy 16 studs), menos velocidad cargando a un derribado (hoy `CarrySpeedMult` 0,8), lanzamiento más corto (normal y cargado). Conservar los arreglos de tirones, choques y cámara al agarrar o lanzar.
- [ ] Aviso de fuertes: punto rojo en la punta del arma para todos los fuertes; quitar el brillo naranja de toda el arma; señal del momento del golpe e imbloqueable distinguible.
- [ ] Animaciones con las armas nuevas de Gemini (agarre a dos manos, IK, estela) y decisión explícita sobre el alcance del espadón.
- [ ] Ciudad: inspección en Studio (solapamientos, parpadeos, huecos, piezas flotantes, colisiones, cámara) y registro de bugs y arreglos. Estilo de pueblo RPG de `referencias\02_lobby_pueblo_noche.webp`.
- [ ] Cielo de `referencias\01_cielo_estrellas_doradas.webp`: muchísimas estrellas doradas de varios tamaños, resplandor cálido, luna azulada. Comparar con la imagen y explicar límites.
- [ ] Integración final: reportes, `check_lua`, `.rbxlx`, pruebas en Studio (escritorio, pantalla chica, móvil, mando).
- [ ] Probar en partida el arma equipada con skin: estela, aura de infusión, partículas y luz.
- [ ] Dash con objetivo fijado: que siga y rodee al objetivo; arreglar la animación del dash con objetivo.
- [ ] Pulido: SoundGroups y opciones, táctil conectado (`InputBridge`), textos de combate traducidos, cámara de espectador, límite del remoto `Input`.
- [ ] Tableros de clasificación ubicados en la ciudad (C7).

## Codex — [[Tareas Codex etapa 8]]
- [ ] Fase 1: guardado confiable, recibos, monedas de depuración, opciones.
- [ ] Fase 2: estadísticas, monedas por partida, misiones diarias, tablas de clasificación, resumen de partida.
- [ ] Fase 3: auras (catálogo, efectos, servidor).
- [ ] Fase 4: arenas (bug negro del derrumbe, peligros en el vacío, 3 arenas nuevas), doble cola, mensajes traducidos.

## Gemini — [[Tareas Gemini etapa 8]]
- [ ] Fase 1: espada base sencilla y skin `Requiem`; vista previa = arma equipada.
- [ ] Fase 2: espadones (prioridad).
- [ ] Fase 3: sistema de diseño, tienda (Auras, Clasificatorias «Próximamente»), HUD.
- [ ] Fase 4: lobby (cola, misiones, clasificatorias), tableros, fin de partida, ajustes, táctil, carga, iconos.
- [ ] Fase 5: espadas, dagas, mazas óseas, Blender.

## Usuario
- [ ] Pasar [[Tareas Codex etapa 8]] a Codex y [[Tareas Gemini etapa 8]] a Gemini (Antigravity).
- [ ] Crear los Developer Products de las skins y auras de Robux y pegar los IDs (`Skins.lua`, `Auras.lua`).
- [ ] Subir las mallas de Gemini si las hay, y las texturas del cielo si hacen falta.
- [ ] Escuchar los SFX jugando y decir qué ajustar.

## Hecho recientemente
- [x] ✅ SFX del usuario: 18 IDs cargan en Studio (lote 7).
- [x] ✅ Animaciones de Mixamo convertidas e incorporadas sin subirlas: se reproducen sin errores (lote 7). Falta juzgar la sensación jugando.
- [x] 🟡 Patada con tecla propia, controles por defecto nuevos (lote 7).
- [x] 🟡 25 skins modeladas, armas base con más detalle, icono de infusión animado (lote 6, hecho por Claude).
