# Referencia LihFolk (desde el 9/11)

Contexto: [[00 Inicio]], [[Contratos etapa 8]], [[Reparto etapa 8]], [[Peticiones del usuario]].

LihFolk V2 es una biblioteca externa de guías de Roblox (más de 1.300 notas) con un **revisor de código** que detecta errores típicos de Luau y Roblox. El usuario la descargó y autorizó usarla en el proyecto.

> **Licencia:** se puede usar para nosotros y para el juego, pero **no se copia** su contenido a este vault ni a otro sitio. Aquí solo van rutas y reglas; para consultar algo, se abre la nota original y se cita su título.

## Dónde está
| Qué | Ruta |
|---|---|
| Plugin (revisor, skills, agentes) | `F:\obsidian\vault git\LIH.FOLK.VAULT.V2.FULL\LihFolk Vault V2` |
| Notas (guías) | `F:\obsidian\vault git\LIH.FOLK.VAULT.V2.FULL\LihFolk Vault V2\LihFolk Vault V2` |
| Paquete de recursos (materiales, modelos) | `F:\obsidian\vault git\LIH.FOLK.VAULT.V2.FULL\LihFolk Asset Pack` |
| Revisor (Windows) | `…\LihFolk Vault V2\hooks\scripts\lihfolk-check.ps1` |
| Reglas del revisor | `…\LihFolk Vault V2\hooks\scripts\rules.tsv` (17 reglas) |

Abajo, `NOTAS` es la carpeta de notas (`…\LihFolk Vault V2\LihFolk Vault V2`).

## Regla nueva para todas las IA
Antes de dar una tarea por terminada, además de `node tools/check_lua.js .`, pasá el revisor desde la carpeta del proyecto:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "F:\obsidian\vault git\LIH.FOLK.VAULT.V2.FULL\LihFolk Vault V2\hooks\scripts\lihfolk-check.ps1" -Scan ServerScriptService ReplicatedStorage StarterPlayer ReplicatedFirst
```

- Tiene que terminar con **0 errores**.
- Cada **aviso nuevo** en tus archivos se arregla o se justifica en tu reporte (es heurístico: puede marcar cosas que ya están validadas).
- Es solo lectura: no escribe archivos ni usa la red.
- Si tu entorno no puede ejecutar archivos fuera del proyecto, decilo en el reporte y Claude lo pasa al integrar.

**Estado al 9/11, 18:20:** 71 archivos, 0 errores, 0 avisos. Claude arregló los 3 avisos del primer escaneo (tipo de `action` en los remotos `Queue`, `Missions` y `Settings`). También agregó `PlayerData.saveSoon`: agrupa guardados de opciones, idioma y auras para que un cliente no sature el DataStore.

Claude Code tiene además el plugin instalado (`.claude/settings.json` del proyecto): el revisor corre solo cada vez que Claude edita un `.lua`.

## Cómo buscar en las guías (sin Python)
El buscador `vault.py` de LihFolk necesita Python, y en esta PC Python no funciona. Se busca a mano:

1. **Por nombre de API o tema:** buscá la palabra en `NOTAS\INDEX_SLIM.md`. Cada línea tiene título, ruta y etiquetas.
2. **Por síntoma de un bug:** buscá en `NOTAS\SYMPTOMS.md`. Cada línea tiene síntoma, causa, arreglo y nota.
3. **Mapa general:** `NOTAS\ROUTER.md` (~5 KB) relaciona temas con sus mejores notas. Leelo solo al empezar una tarea grande.
4. **Resumen de una nota:** leé solo su bloque TL;DR. Ejemplo: `grep -A 10 "tldr:start" "<ruta de la nota>"`. Abrí una sección completa solo si hace falta.
5. **Temas delicados:** para datos, compras, recibos, remotos o seguridad, leé siempre las secciones `## Common mistakes` y `## Checklist` de la nota.
6. **En el reporte:** citá el título de la nota que usaste.

## Guías útiles por área
Están en `…\LihFolk Vault V2\skills\<nombre>\SKILL.md` (y como notas `NOTAS\Skill - *.md`).

| Área | Skill | Quién la usa |
|---|---|---|
| Remotos seguros | `roblox-secure-remotes` | Codex (revisión), Claude |
| DataStore y guardado | `roblox-datastore-safety` | Codex (revisión), Claude |
| Compras con Robux y políticas | `roblox-monetization-compliance` | Codex, Claude (antes de publicar productos) |
| Rendimiento | `roblox-performance-audit` | todas (ciudad, arenas, cielo) |
| Anti-trampas | `roblox-anti-exploit-review` | Codex (revisión) |
| Interfaz | `roblox-ui-builder`, `lihfolk-ui` | Gemini, Codex |
| Mundo y escenarios | `lihfolk-worldbuilding` | Gemini (ciudad, arenas) |
| Efectos visuales | `lihfolk-vfx` | Claude, Gemini |
| Sonido | `lihfolk-sfx` | Claude |
| Depuración | `roblox-debugging` | todas |

Carpetas de notas más útiles para este juego:
- `03 Architecture and Networking` y `22 Anti-Exploit and Security`: remotos y validación.
- `04 Data and Persistence`: guardado.
- `06 World Building and Art` y `33 Level Design`: ciudad y arenas.
- `07 Lighting VFX and Audio`: luces, efectos y sonido.
- `08 Animation`: animaciones.
- `12 Performance Testing and Debugging`: rendimiento y pruebas.
