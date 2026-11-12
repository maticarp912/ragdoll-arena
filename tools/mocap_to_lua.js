// Genera MocapClips y sus modulos por arma a partir del JSON de tools/mixamo_to_r15.py
// Uso: node tools/mocap_to_lua.js <mocap.json>
// Cada clip se recorta alrededor del golpe (preparación - Pre s .. golpe + Post s) salvo "full".
const fs = require("fs");
const path = require("path");
const src = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));

// Los clips sin arma asignada se comparten entre armas.
const PICK = {
	GS_Slash1: { weapon: "Greatsword", src: "great sword slash" },
	GS_Slash2: { weapon: "Greatsword", src: "great sword slash (3)" },
	GS_Slash3: { weapon: "Greatsword", src: "great sword slash (4)" },
	GS_Slash4: { weapon: "Mace", src: "great sword slash (2)" },
	GS_Slash5: { weapon: "Mace", src: "great sword slash (5)" },
	GS_Attack: { weapon: "Mace", src: "great sword attack" },
	GS_Spin: { weapon: "Greatsword", src: "great sword high spin attack", pre: 0.45, post: 0.6 },
	GS_Kick: { weapon: "Greatsword", src: "great sword kick (2)" },
	GS_Kick2: { weapon: "Greatsword", src: "great sword kick" , mode: "full" },
	GS_Block1: { weapon: "Greatsword", src: "great sword blocking", mode: "full" },
	GS_Block3: { weapon: "Greatsword", src: "great sword blocking (3)", mode: "full" },
	Impact1: { src: "great sword impact", mode: "full" },
	Impact2: { src: "great sword impact (2)", mode: "full" },
	Impact3: { src: "great sword impact (3)", mode: "full" },
	Impact4: { src: "great sword impact (4)", mode: "full" },
	Impact5: { src: "great sword impact (5)", mode: "full" },
	Death1: { src: "two handed sword death", mode: "full" },
	Melee_Backhand: { weapon: "Sword", src: "Standing Melee Attack Backhand" },
	Melee_Downward: { weapon: "Sword", src: "Standing Melee Attack Downward" },
	SwordShield: { weapon: "Sword", src: "Sword And Shield Attack" },
	KickBlock: { src: "patada bloqueo" },
};
const PRE = 0.3, POST = 0.55;

const fmt = (v) => (Number.isInteger(v) ? String(v) : String(Math.round(v * 100) / 100));
const modules = { Greatsword: [], Mace: [], Sword: [], Dagger: [], Rapier: [], Shared: [] };
const generated = "-- Generado por tools/mocap_to_lua.js. No editar a mano.\n";
const clipHeader = `-- Animaciones de Mixamo convertidas a poses R15 con tools/mixamo_to_r15.py (Blender).
-- Formato igual que AnimClips: keys = { {t, pose}, ... }, t de 0 a 1; hit/windup = momentos del golpe.
local C = {}
`;
for (const [name, p] of Object.entries(PICK)) {
	const c = src[p.src];
	if (!c || c.error) { console.log("!! falta", p.src); continue; }
	let t0 = 0, t1 = 1;
	if (p.mode !== "full") {
		const pre = (p.pre ?? PRE) / c.dur, post = (p.post ?? POST) / c.dur;
		t0 = Math.max(0, c.windup - pre);
		t1 = Math.min(1, c.hit + post);
	}
	const span = t1 - t0;
	const keys = c.keys.filter((k) => k[0] >= t0 - 1e-6 && k[0] <= t1 + 1e-6);
	const lines = keys.map(([t, pose]) => {
		const parts = Object.entries(pose).map(([j, v]) => `${j}={${v.map(fmt).join(",")}}`);
		return `\t\t{${fmt(Math.round(((t - t0) / span) * 1000) / 1000)},{${parts.join(",")}}},`;
	});
	modules[p.weapon ?? "Shared"].push(`C.${name} = { src = ${JSON.stringify(p.src)}, dur = ${fmt(Math.round(c.dur * span * 1000) / 1000)}, hit = ${fmt(Math.round(((c.hit - t0) / span) * 1000) / 1000)}, windup = ${fmt(Math.round(((c.windup - t0) / span) * 1000) / 1000)}, keys = {\n${lines.join("\n")}\n} }\n`);
}
function appendRetargeted(weapon, file) {
	const clips = JSON.parse(fs.readFileSync(file, "utf8"));
	for (const [name, clip] of Object.entries(clips)) {
		if (!clip || !clip.keys.length) throw new Error("Falta el clip " + name);
		let out = "C." + name + " = { src = " + JSON.stringify(clip.source) + ", dur = " + clip.dur +
			", hit = " + clip.hit + ", windup = " + clip.windup + ", keys = {\n";
		for (const [time, pose] of clip.keys) {
			const parts = Object.entries(pose).map(([joint, values]) => joint + "={" + values.map(fmt).join(",") + "}");
			out += "\t\t{" + time + ",{" + parts.join(",") + "}},\n";
		}
		modules[weapon].push(out + "} }\n");
	}
}

const models = path.join(__dirname, "..", "modelos_armas", "v0.3");
const pilotPath = path.join(models, "Piloto Espada", "FuertesR15.json");
if (fs.existsSync(pilotPath)) appendRetargeted("Sword", pilotPath);
for (const weapon of ["Greatsword", "Dagger", "Rapier", "Mace"]) {
	const file = path.join(models, "Animaciones direccionales", weapon + ".json");
	if (fs.existsSync(file)) appendRetargeted(weapon, file);
}
const dest = path.join(__dirname, "..", "ReplicatedStorage");
const imports = [];
for (const [weapon, clips] of Object.entries(modules)) {
	if (!clips.length) continue;
	const name = "MocapClips" + weapon;
	const source = generated + clipHeader + clips.join("") + "return C\n";
	if (source.length >= 200000) throw new Error(name + " supera el límite de tamaño");
	fs.writeFileSync(path.join(dest, name + ".lua"), source);
	imports.push(`\trequire(script.Parent:WaitForChild("${name}")),`);
	console.log(name + ".lua", clips.length, "clips", Buffer.byteLength(source), "bytes");
}

const index = `${generated}-- Conserva las claves de los clips para los consumidores de MocapClips.
local clips = {}
for _, group in {
${imports.join("\n")}
} do
	for name, clip in group do
		clips[name] = clip
	end
end
return clips
`;
fs.writeFileSync(path.join(dest, "MocapClips.lua"), index);
