// Genera un lugar de Roblox (.rbxlx) con todos los scripts en su sitio.
// Uso: node make_rbxlx.js <carpeta_src> <salida.rbxlx>
const fs = require("fs");
const path = require("path");

const [src, out] = process.argv.slice(2);
let counter = 0;
const ref = () => `RBX${++counter}`;
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function scriptItem(cls, name, source) {
  if (source.includes("]]>")) throw new Error(`'${name}' contiene ]]> y rompe el CDATA`);
  return `<Item class="${cls}" referent="${ref()}"><Properties><string name="Name">${esc(name)}</string><ProtectedString name="Source"><![CDATA[${source}]]></ProtectedString></Properties></Item>`;
}

function container(cls, name, children, extraProps = "") {
  return `<Item class="${cls}" referent="${ref()}"><Properties><string name="Name">${esc(name)}</string>${extraProps}</Properties>${children.join("")}</Item>`;
}

// StarterPlayer: rig R15 forzado (GameAvatarType: R6=0, R15=1, PlayerChoice=2) y sin Shift Lock (Shift = esquiva)
const starterPlayerProps =
  `<token name="GameSettingsAvatar">1</token>` +
  `<bool name="EnableMouseLockOption">false</bool>`;

function scriptsIn(folder, defaultClass) {
  const items = [];
  if (!fs.existsSync(folder)) return items;
  for (const f of fs.readdirSync(folder).sort()) {
    if (!f.endsWith(".lua")) continue;
    const source = fs.readFileSync(path.join(folder, f), "utf8").replace(/^\uFEFF/, ""); // sin BOM: rompe el script en Roblox
    let cls, name;
    if (f.endsWith(".server.lua")) { cls = "Script"; name = f.slice(0, -".server.lua".length); }
    else if (f.endsWith(".client.lua")) { cls = "LocalScript"; name = f.slice(0, -".client.lua".length); }
    else { cls = defaultClass; name = f.slice(0, -".lua".length); }
    items.push(scriptItem(cls, name, source));
    console.log(`  ${cls.padEnd(12)} ${name}`);
  }
  return items;
}

console.log("Scripts incluidos:");
const rs = scriptsIn(path.join(src, "ReplicatedStorage"), "ModuleScript");
const sss = scriptsIn(path.join(src, "ServerScriptService"), "ModuleScript");
const sps = scriptsIn(path.join(src, "StarterPlayer", "StarterPlayerScripts"), "LocalScript");
// ReplicatedFirst (etapa 8): pantalla de carga. Carpeta opcional; sus .lua son LocalScripts.
const rf = scriptsIn(path.join(src, "ReplicatedFirst"), "LocalScript");

// Iluminación: tecnología Future (sombras y brillos de metal), sombras globales y reflejos del entorno
const lightingProps =
  `<token name="Technology">4</token>` +
  `<bool name="GlobalShadows">true</bool>` +
  `<float name="EnvironmentDiffuseScale">1</float>` +
  `<float name="EnvironmentSpecularScale">1</float>`;

const body =
  container("Workspace", "Workspace", []) +
  container("Lighting", "Lighting", [], lightingProps) +
  container("ReplicatedFirst", "ReplicatedFirst", rf) +
  container("ReplicatedStorage", "ReplicatedStorage", rs) +
  container("ServerScriptService", "ServerScriptService", sss) +
  container("StarterPlayer", "StarterPlayer", [container("StarterPlayerScripts", "StarterPlayerScripts", sps)], starterPlayerProps);

const xml = `<?xml version="1.0" encoding="utf-8"?>\n<roblox version="4">${body}</roblox>\n`;
fs.writeFileSync(out, xml, "utf8");
console.log(`\nCreado: ${out} (${Math.round(xml.length / 1024)} KB)`);
