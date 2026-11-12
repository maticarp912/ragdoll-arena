// Genera un modelo (.rbxmx) con todos los scripts empaquetados en una carpeta __PACK, para importarlo
// en un place ya publicado (Insertar desde archivo) cuando publicar el .rbxlx entero se traba.
// Uso: node tools/make_pack.js . pack.rbxmx
const fs = require("fs");
const path = require("path");
const [src, out] = process.argv.slice(2);
let counter = 0;
const ref = () => `RBX${++counter}`;
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
function scriptItem(cls, name, source) {
  return `<Item class="${cls}" referent="${ref()}"><Properties><string name="Name">${esc(name)}</string><ProtectedString name="Source"><![CDATA[${source}]]></ProtectedString></Properties></Item>`;
}
function folder(name, children) {
  return `<Item class="Folder" referent="${ref()}"><Properties><string name="Name">${esc(name)}</string></Properties>${children.join("")}</Item>`;
}
function scriptsIn(dir, defaultClass) {
  const items = [];
  if (!fs.existsSync(dir)) return items;
  for (const f of fs.readdirSync(dir).sort()) {
    if (!f.endsWith(".lua")) continue;
    const source = fs.readFileSync(path.join(dir, f), "utf8").replace(/^﻿/, "");
    let cls, name;
    if (f.endsWith(".server.lua")) { cls = "Script"; name = f.slice(0, -11); }
    else if (f.endsWith(".client.lua")) { cls = "LocalScript"; name = f.slice(0, -11); }
    else { cls = defaultClass; name = f.slice(0, -4); }
    items.push(scriptItem(cls, name, source));
  }
  return items;
}
const pack = folder("__PACK", [
  folder("RS", scriptsIn(path.join(src, "ReplicatedStorage"), "ModuleScript")),
  folder("SSS", scriptsIn(path.join(src, "ServerScriptService"), "ModuleScript")),
  folder("SPS", scriptsIn(path.join(src, "StarterPlayer", "StarterPlayerScripts"), "LocalScript")),
  folder("SCS", scriptsIn(path.join(src, "StarterPlayer", "StarterCharacterScripts"), "Script")),
  folder("RF", scriptsIn(path.join(src, "ReplicatedFirst"), "LocalScript")),
]);
fs.writeFileSync(out, `<?xml version="1.0" encoding="utf-8"?>\n<roblox version="4">${pack}</roblox>\n`, "utf8");
console.log("Creado", out, counter, "objetos");
