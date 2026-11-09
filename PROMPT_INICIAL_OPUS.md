# Prompt inicial para Opus (copia y pega esto al empezar la nueva sesión)

---

Vas a programar un juego de Roblox llamado provisionalmente **Ragdoll Arena**. Trabaja en la carpeta `F:\RobloxJuegos\Plataforme 2v2`.

**Antes de escribir una línea, lee por completo estos dos archivos:**
1. `RESUMEN_PROYECTO.md` — toda la idea del juego, reglas, controles, armas, infusiones, progresión, arquitectura del código existente, plan por fases y decisiones ya tomadas.
2. `ASSETS_LISTA.md` — lista de animaciones, sonidos y renders que el usuario irá entregando, con las claves exactas que debe usar `Assets.lua`.

**Tu rol:** eres el responsable del **código y las mecánicas**. El usuario se encarga de renders, escenarios, sonidos y animaciones, y te los irá pasando por lotes (empezando por la **Espada**). **No esperes a los assets**: avanza con placeholders y enchufa los IDs cuando lleguen.

**Contexto clave en 10 líneas**
- PvP **1v1 y 2v2**, físicas **ragdoll**, rig **R15**, sin salto, sin escudos (se bloquea con el arma), estilo **dark fantasy**.
- Se gana eliminando al rival: **caer de la arena** o **vida a 0** (en 2v2 hay derribo crítico y rescate).
- Combate tipo For Honor simplificado: M1 combo, E ataque fuerte, F bloqueo/parry, Shift/Espacio esquiva con i-frames, R patada/agarrar/rescatar, Q infusión, T/Y lock-on.
- Tres barras: **Vida, Stun y Guardia**. Derribo por Stun (4 s) o crítico (vida 0).
- **Infusión = la "ulti"**: 6 infusiones (Fuego, Rayo, Sangre, Hielo, Veneno, Sombra) con contras tipo piedra-papel-tijera.
- 5 armas en la Fase 1: Espada, Espadón, Dagas, Estoque, Maza.
- Progresión por maestría de arma, desbloqueos y pagos opcionales que aceleran **tiempo y variedad, nunca poder**.
- Escenario provisional: **cuadrado grande de baldosas que se desmorona por partes**, rondas de **≥ 2 minutos**.
- El código actual en la carpeta es la **versión anterior del diseño** (elementos y ulti): hay que refactorizarlo.
- Las decisiones de diseño pendientes están **resueltas por defecto** en la sección 13 del resumen.

**Empieza así**
1. Lee los documentos y el código existente (`ReplicatedStorage`, `ServerScriptService`, `StarterPlayer`).
2. Resúmeme en pocas líneas lo que entendiste y qué vas a hacer primero.
3. Ejecuta la **Fase 0** (herramientas de prueba: muñeco de práctica, modo práctica de 1 jugador, visualizador de hitboxes, AnimTester, `Assets.lua`, `Theme.lua`) y luego la **Fase A** (núcleo de combate), según la sección 12.

**Reglas de trabajo**
- Responde en **español**, claro y breve.
- Todo valor numérico va en módulos de datos (`WeaponData`, `Infusions`, `Progression`, `Theme`, `Assets`), no dentro de la lógica.
- El **servidor decide todo**; el cliente solo envía acciones.
- **Python no está instalado** en el PC: usa **Node**. El generador del lugar de Studio es `tools\make_rbxlx.js`; los comandos están en la sección 16 del resumen.
- **Pídeme permiso antes de abrir Roblox Studio** o cualquier otro programa. Los errores de scripts se leen en el log de Studio (`%LOCALAPPDATA%\Roblox\logs`).
- No hay analizador de Luau: revisa la sintaxis con cuidado y haz que cada fase **arranque sin errores** antes de pasar a la siguiente.
- Al terminar cada fase, regenera el `.rbxlx`, dime exactamente cómo probarlo y qué debería pasar.
- Nada de contenido con copyright: nombres, diseños y sonidos **originales**.

---
