// Chequeo básico de los scripts Luau (no hay analizador de Luau instalado).
// Detecta: bloques sin cerrar (function/if/do/repeat vs end/until), paréntesis/llaves/corchetes
// desbalanceados, strings sin cerrar y nombres que no están declarados en ningún sitio del archivo
// (posibles erratas). No es un analizador completo: revisa a mano lo que marque.
// Uso: node check_lua.js <carpeta_proyecto>
const fs = require("fs");
const path = require("path");

const root = process.argv[2] || ".";
const DIRS = ["ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", path.join("StarterPlayer", "StarterPlayerScripts"), path.join("StarterPlayer", "StarterCharacterScripts")];

const KEYWORDS = new Set(("and break do else elseif end false for function if in local nil not or repeat return then true until while continue").split(" "));
const GLOBALS = new Set(("game workspace script Instance Vector3 Vector2 CFrame Color3 ColorSequence ColorSequenceKeypoint NumberSequence " +
  "NumberSequenceKeypoint NumberRange UDim UDim2 Enum Ray RaycastParams OverlapParams BrickColor TweenInfo task math string table os " +
  "print warn error pcall xpcall typeof type tostring tonumber pairs ipairs next select setmetatable getmetatable require rawget " +
  "rawset rawequal unpack utf8 coroutine debug buffer DateTime Random Axes Faces PhysicalProperties Region3 Rect assert self _G " +
  "shared tick time wait delay spawn elapsedTime Font Content PathWaypoint SharedTable").split(" "));

function tokenize(src, file, problems) {
  const toks = [];
  let i = 0, line = 1;
  const n = src.length;
  const longBracket = (pos) => {
    // devuelve nivel si en pos hay [=*[
    if (src[pos] !== "[") return -1;
    let j = pos + 1, lvl = 0;
    while (src[j] === "=") { lvl++; j++; }
    return src[j] === "[" ? lvl : -1;
  };
  const skipLong = (pos, lvl) => {
    const close = "]" + "=".repeat(lvl) + "]";
    const end = src.indexOf(close, pos);
    if (end < 0) { problems.push(`${file}:${line}: string/comentario largo sin cerrar`); return n; }
    for (let k = pos; k < end; k++) if (src[k] === "\n") line++;
    return end + close.length;
  };
  while (i < n) {
    const ch = src[i];
    if (ch === "\n") { line++; i++; continue; }
    if (/\s/.test(ch)) { i++; continue; }
    if (src.startsWith("--", i)) {
      const lvl = longBracket(i + 2);
      if (lvl >= 0) { i = skipLong(i + 2 + lvl + 2, lvl); continue; }
      while (i < n && src[i] !== "\n") i++;
      continue;
    }
    if (ch === '"' || ch === "'" || ch === "`") {
      const startLine = line;
      let j = i + 1;
      while (j < n && src[j] !== ch) {
        if (src[j] === "\\") j++;
        else if (src[j] === "\n" && ch !== "`") { problems.push(`${file}:${startLine}: string sin cerrar`); break; }
        if (src[j] === "\n") line++;
        j++;
      }
      toks.push({ t: "str", v: "", line: startLine });
      i = j + 1;
      continue;
    }
    const lvl = longBracket(i);
    if (lvl >= 0) { const l0 = line; i = skipLong(i + lvl + 2, lvl); toks.push({ t: "str", v: "", line: l0 }); continue; }
    if (/[0-9]/.test(ch) || (ch === "." && /[0-9]/.test(src[i + 1]))) {
      let j = i;
      while (j < n && /[0-9a-fA-FxX_.]/.test(src[j])) {
        if ((src[j] === "e" || src[j] === "E") && (src[j + 1] === "-" || src[j + 1] === "+")) j++;
        j++;
      }
      toks.push({ t: "num", v: src.slice(i, j), line });
      i = j;
      continue;
    }
    if (/[A-Za-z_]/.test(ch)) {
      let j = i;
      while (j < n && /[A-Za-z0-9_]/.test(src[j])) j++;
      const w = src.slice(i, j);
      toks.push({ t: KEYWORDS.has(w) ? "kw" : "id", v: w, line });
      i = j;
      continue;
    }
    const three = src.substr(i, 3);
    const two = src.substr(i, 2);
    if (three === "...") { toks.push({ t: "op", v: three, line }); i += 3; continue; }
    if (["==", "~=", "<=", ">=", "..", "::", "->", "+=", "-=", "*=", "/=", "%=", "^=", "//"].includes(two)) {
      if (two === ".." && src[i + 2] === "=") { toks.push({ t: "op", v: "..=", line }); i += 3; continue; }
      if (two === "//" && src[i + 2] === "=") { toks.push({ t: "op", v: "//=", line }); i += 3; continue; }
      toks.push({ t: "op", v: two, line }); i += 2; continue;
    }
    toks.push({ t: "op", v: ch, line });
    i++;
  }
  return toks;
}

function check(file) {
  const src = fs.readFileSync(file, "utf8");
  const rel = path.relative(root, file);
  const problems = [];
  if (src.includes("]]>")) problems.push(`${rel}: contiene ]]> (rompe el CDATA del .rbxlx)`);
  const toks = tokenize(src, rel, problems);

  // Bloques y paréntesis
  const stack = [];
  for (let k = 0; k < toks.length; k++) {
    const tk = toks[k];
    if (tk.t === "kw") {
      if (["function", "if", "do", "repeat"].includes(tk.v)) stack.push(tk);
      else if (tk.v === "end") {
        const top = stack.pop();
        if (!top || !["function", "if", "do"].includes(top.v)) problems.push(`${rel}:${tk.line}: 'end' sin bloque abierto (cierra ${top ? top.v + " de la línea " + top.line : "nada"})`);
      } else if (tk.v === "until") {
        const top = stack.pop();
        if (!top || top.v !== "repeat") problems.push(`${rel}:${tk.line}: 'until' sin 'repeat'`);
      } else if (tk.v === "elseif" || tk.v === "else") {
        const top = stack[stack.length - 1];
        if (!top || top.v !== "if") problems.push(`${rel}:${tk.line}: '${tk.v}' fuera de un 'if' (¿if-expresión?)`);
      }
    } else if (tk.t === "op" && "({[".includes(tk.v)) stack.push(tk);
    else if (tk.t === "op" && ")}]".includes(tk.v)) {
      const want = { ")": "(", "}": "{", "]": "[" }[tk.v];
      const top = stack.pop();
      if (!top || top.v !== want) problems.push(`${rel}:${tk.line}: '${tk.v}' no cierra bien (abierto: ${top ? "'" + top.v + "' línea " + top.line : "nada"})`);
    }
  }
  for (const s of stack) problems.push(`${rel}:${s.line}: '${s.v}' sin cerrar`);

  // Nombres declarados en el archivo
  const declared = new Set();
  for (let k = 0; k < toks.length; k++) {
    const tk = toks[k];
    if (tk.t === "kw" && tk.v === "local") {
      let j = k + 1;
      if (toks[j] && toks[j].v === "function") { if (toks[j + 1]) declared.add(toks[j + 1].v); continue; }
      while (toks[j] && toks[j].t === "id") {
        declared.add(toks[j].v);
        j++;
        // saltar anotación de tipo
        if (toks[j] && toks[j].v === ":") { j++; while (toks[j] && !["," , "="].includes(toks[j].v) && toks[j].line === tk.line) j++; }
        if (toks[j] && toks[j].v === ",") { j++; continue; }
        break;
      }
    } else if (tk.t === "kw" && tk.v === "function") {
      let j = k + 1;
      if (toks[j] && toks[j].t === "id" && toks[j + 1] && toks[j + 1].v === "(") declared.add(toks[j].v);
      while (toks[j] && toks[j].v !== "(") j++;
      j++;
      let depth = 0;
      while (toks[j] && !(toks[j].v === ")" && depth === 0)) {
        if (toks[j].v === "(" || toks[j].v === "{") depth++;
        else if (toks[j].v === ")" || toks[j].v === "}") depth--;
        else if (toks[j].t === "id" && depth === 0 && (toks[j - 1].v === "(" || toks[j - 1].v === ",")) declared.add(toks[j].v);
        j++;
      }
    } else if (tk.t === "kw" && tk.v === "for") {
      let j = k + 1;
      while (toks[j] && toks[j].t === "id") { declared.add(toks[j].v); j++; if (toks[j] && toks[j].v === ",") j++; else break; }
    }
  }

  // Usos de nombres no declarados
  const braceStack = [];
  for (let k = 0; k < toks.length; k++) {
    const tk = toks[k];
    if (tk.t === "op" && "({[".includes(tk.v)) braceStack.push(tk.v);
    if (tk.t === "op" && ")}]".includes(tk.v)) braceStack.pop();
    if (tk.t !== "id") continue;
    const prev = toks[k - 1], next = toks[k + 1];
    if (prev && (prev.v === "." || prev.v === ":" || prev.v === "::" || prev.v === "->")) continue;
    if (next && next.v === "=" && braceStack[braceStack.length - 1] === "{" && prev && (prev.v === "{" || prev.v === ",")) continue; // clave de tabla
    if (declared.has(tk.v) || GLOBALS.has(tk.v)) continue;
    // anotaciones de tipo tipo "x: Model?" o genéricos
    if (next && next.v === "?") continue;
    problems.push(`${rel}:${tk.line}: '${tk.v}' no está declarado en este archivo (¿errata?)`);
  }
  return problems;
}

let all = [];
let count = 0;
for (const d of DIRS) {
  const dir = path.join(root, d);
  if (!fs.existsSync(dir)) continue;
  for (const f of fs.readdirSync(dir).sort()) {
    if (!f.endsWith(".lua")) continue;
    count++;
    all = all.concat(check(path.join(dir, f)));
  }
}
if (all.length === 0) console.log(`OK: ${count} archivos sin problemas detectados.`);
else { console.log(all.join("\n")); console.log(`\n${all.length} aviso(s) en ${count} archivos.`); process.exitCode = 1; }
