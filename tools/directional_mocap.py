"""Retarget de ataques direccionales. Ejecutar con Blender en segundo plano."""
import json
import math
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from zipfile import ZipFile

from mathutils import Matrix, Vector

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from mixamo_to_r15 import convert, euler_xyz
from sword_heavy_pilot import cframe, segment_in_box, transform, unwrap

LEFT = "Sword And Shield Attack"
UP = "Standing Melee Attack Downward"
RIGHT = "Standing Melee Attack Backhand"
SOURCES = {
    "Greatsword": {"DirUp": "great sword attack", "HeavyUp": "great sword jump attack",
                   "HeavyLeft": "great sword slash (3)", "HeavyRight": "great sword slash"},
    "Dagger": {"DirUp": UP, "DirLeft": LEFT, "DirRight": RIGHT,
               "HeavyUp": UP, "HeavyLeft": LEFT, "HeavyRight": RIGHT},
    "Rapier": {"DirUp": UP, "DirLeft": LEFT, "DirRight": RIGHT,
               "HeavyUp": LEFT, "HeavyLeft": UP, "HeavyRight": RIGHT},
    "Mace": {"DirUp": "great sword attack", "DirLeft": "great sword slash (5)",
             "HeavyUp": "great sword jump attack", "HeavyLeft": "great sword slash (3)",
             "HeavyRight": "great sword slash (2)"},
}
WINDUP = 0.40
HIT = 0.57
RECOVERY = 0.79
STAGES = (0, WINDUP, HIT, RECOVERY, 1)
MARGIN = 0.08
SAMPLE_COUNT = 30
FORWARD = Vector((0, 0, -1))
UP_AXIS = Vector((0, 1, 0))


def smooth(t):
    return t * t * (3 - 2 * t)


def mix(values, times, t):
    for i in range(1, len(times)):
        if t <= times[i]:
            u = smooth((t - times[i - 1]) / (times[i] - times[i - 1]))
            return values[i - 1].lerp(values[i], u)
    return values[-1].copy()


def sample_source(clip, u):
    frames = clip["keys"]
    start = max(0, clip["windup"] - 0.32 / clip["dur"])
    end = min(1, clip["hit"] + 0.46 / clip["dur"])
    times = (start, max(start, clip["windup"]), clip["hit"], (end + clip["hit"]) / 2, end)
    t = mix([Vector((v, 0)) for v in times], STAGES, u).x
    for (a, pa), (b, pb) in zip(frames, frames[1:]):
        if t <= b:
            f = max(0, (t - a) / (b - a))
            pose = {}
            for joint, values in pa.items():
                other = unwrap(pb[joint], values)
                pose[joint] = [x + (y - x) * f for x, y in zip(values, other)]
            return pose
    return {joint: list(values) for joint, values in frames[-1][1].items()}


def continuous(values, prior):
    if prior is None:
        return values
    primary = unwrap(values, prior)
    x, y, z = values[:3]
    other = unwrap([x + 180, 180 - y, z + 180] + values[3:], prior)
    return min((primary, other), key=lambda v: math.dist(v[:3], prior[:3]))


def track(side, heavy, thrust, lead=1):
    sign = {"Right": 1, "Left": -1, "Up": 0}[side]
    amount = 1.0 if heavy else 0.76
    if thrust:
        positions = [(0.75, -0.15, -0.63), (0.48 + sign * 0.62, 0.67 if not sign else 0.27, -0.44),
                     (sign * 0.38 + 0.23, 0.68 if not sign else 0.24, -1.56),
                     (sign * 0.32 + 0.31, 0.54 if not sign else 0.11, -1.16), (0.73, -0.15, -0.63)]
        axes = [(0.1, 0.30, -1), (sign * 0.26, 0.24 if not sign else 0.08, -1),
                (-sign * 0.09, 0.04 if not sign else -0.03, -1), (sign * 0.15, 0.12, -1), (0.1, 0.30, -1)]
        if heavy:
            positions[1] = (positions[1][0], positions[1][1] + 0.20, -0.20)
            positions[2] = (positions[2][0], positions[2][1], -1.67)
    else:
        positions = [(lead * 0.47, -0.12, -0.82),
                     (sign * 0.69 * amount + lead * 0.16, (0.96 if not sign else 0.42) * amount, -0.78),
                     (-sign * 0.20 + lead * 0.11, 0.25 if not sign else 0.26, -1.21),
                     (-sign * 0.55 + lead * 0.12, -0.44 if not sign else -0.14, -0.92),
                     (lead * 0.47, -0.12, -0.82)]
        axes = [(lead * 0.32, 0.37, -1),
                (sign * 0.88, 0.97 if not sign else 0.49, -0.46),
                (-sign * 0.13, -0.24 if not sign else 0.05, -1),
                (-sign * 0.78, -0.72 if not sign else -0.26, -0.66),
                (lead * 0.32, 0.37, -1)]
    return [Vector(p) for p in positions], [Vector(v).normalized() for v in axes]


def rear_dagger(lead):
    points = [(lead * 0.72, -0.32, -0.70), (lead * 0.87, 0.03, -0.49),
              (lead * 0.81, 0.17, -0.70), (lead * 0.80, -0.09, -0.61), (lead * 0.72, -0.32, -0.70)]
    directions = [(lead * 0.67, 0.35, -0.70), (lead * 0.76, 0.54, -0.54),
                  (lead * 0.46, 0.38, -1), (lead * 0.65, 0.36, -0.65), (lead * 0.67, 0.35, -0.70)]
    return [Vector(p) for p in points], [Vector(v).normalized() for v in directions]


def frame_from_axis(point, direction, roll=1):
    z = direction.normalized()
    x = UP_AXIS.cross(z)
    if x.length < 0.0001:
        x = Vector((1, 0, 0))
    x = x.normalized() * roll
    y = z.cross(x)
    result = Matrix((x, y, z)).transposed().to_4x4()
    result.translation = point
    return result


class Rig:
    def __init__(self, common, weapon):
        self.joints = {j: (cframe(c0), cframe(c1)) for j, (c0, c1) in common["joints"].items()}
        self.extents = [Vector(common[name]) / 2 for name in ("lower", "upper")]
        self.right_grip = tuple(map(cframe, weapon["grip"]))
        self.left_grip = tuple(map(cframe, weapon.get("leftGrip", weapon["grip"])))
        self.blade = (Vector(weapon["base"]), Vector(weapon["tip"]))
        self.left_blade = (Vector(weapon["leftBase"]), Vector(weapon["leftTip"])) if "leftBase" in weapon else None
        self.offhand = weapon.get("offhand")

    def link(self, parent, joint, pose):
        c0, c1 = self.joints[joint]
        return parent @ c0 @ transform(pose[joint]) @ c1.inverted()

    def body(self, pose):
        lower = self.link(Matrix.Identity(4), "R", pose)
        return lower, self.link(lower, "W", pose)

    def arm(self, upper, side, pose):
        parts = []
        for joint in ("S", "E", "W"):
            upper = self.link(upper, side + joint, pose)
            parts.append(upper)
        return parts

    def handle(self, hand, grip):
        return hand @ grip[0] @ grip[1].inverted()

    def solve_arm(self, upper, side, hand):
        names = tuple(side + j for j in ("S", "E", "W"))
        ((s0, s1), (e0, e1), (w0, w1)) = (self.joints[name] for name in names)
        shoulder_cf = upper @ s0
        shoulder = shoulder_cf.translation
        wrist = (hand @ w1).translation
        along = wrist - shoulder
        sign = 1 if side == "R" else -1
        bone1 = e0.translation - s1.translation
        bone2 = w0.translation - e1.translation
        length1, length2 = bone1.length, bone2.length
        distance = min(length1 + length2 - 0.012, max(abs(length1 - length2) + 0.02, along.length))
        axis = along.normalized() if along.length > 0.0001 else upper.to_3x3() @ FORWARD
        pole = upper.to_3x3() @ Vector((0.58 * sign, -1, 0.42))
        pole = (pole - axis * pole.dot(axis)).normalized()
        along_elbow = (distance * distance + length1 * length1 - length2 * length2) / (2 * distance)
        elbow = shoulder + axis * along_elbow + pole * math.sqrt(max(0, length1 * length1 - along_elbow * along_elbow))
        actual_wrist = shoulder + axis * distance
        normal = pole.cross(axis).normalized()

        def part(origin, direction, own_origin, bone):
            y = -direction.normalized()
            z = normal.cross(y).normalized()
            x = y.cross(z).normalized()
            result = Matrix((x, y, z)).transposed().to_4x4()
            # La dirección real de cada hueso puede diferir levemente del -Y del R15.
            actual = result.to_3x3() @ bone
            result = actual.rotation_difference(direction).to_matrix().to_4x4() @ result
            result.translation = origin - result.to_3x3() @ own_origin
            return result

        upper_arm = part(shoulder, elbow - shoulder, s1.translation, bone1)
        forearm = part(elbow, actual_wrist - elbow, e1.translation, bone2)
        actual_hand = hand.copy()
        actual_hand.translation += actual_wrist - wrist
        result = (shoulder_cf.inverted() @ upper_arm @ s1,
                  (upper_arm @ e0).inverted() @ forearm @ e1,
                  (forearm @ w0).inverted() @ actual_hand @ w1)
        return dict(zip(names, (euler_xyz(m.to_3x3()) for m in result))), (actual_wrist - wrist).length

    def collision(self, body, handle, blade):
        a, b = (handle @ v for v in blade)
        return any(segment_in_box(t.inverted() @ a, t.inverted() @ b, size + Vector((MARGIN,) * 3))
                   for t, size in zip(body, self.extents))

    def audit(self, pose):
        body = self.body(pose)
        right = self.arm(body[1], "R", pose)[-1]
        left = self.arm(body[1], "L", pose)[-1]
        handle = self.handle(right, self.right_grip)
        collides = self.collision(body, handle, self.blade)
        grip_error = ((right @ self.right_grip[0]).translation - (handle @ self.right_grip[1]).translation).length
        if self.offhand is not None:
            grip_error = max(grip_error, ((left @ self.left_grip[0]).translation - handle @ Vector((0, 0, self.offhand))).length)
        if self.left_blade:
            collides = collides or self.collision(body, self.handle(left, self.left_grip), self.left_blade)
        return collides, grip_error


def fit(rig, body, side, point, axis, roll=1):
    upper = body[1]
    grip = rig.right_grip if side == "R" else rig.left_grip
    blade = rig.blade if side == "R" else rig.left_blade
    shoulder_bias = 1 if side == "R" else -1
    # Pequeños ajustes hacia el centro y hacia delante si la fuente exige demasiado alcance.
    for weight in (0, 0.12, 0.25, 0.42, 0.65, 1):
        for shift in (0, 0.12, -0.12):
            p = point.lerp(Vector((shoulder_bias * 0.33, 0.18, -0.96)), weight) + Vector((0, 0, -shift))
            a = axis.lerp(FORWARD, weight * 0.55)
            h = upper @ frame_from_axis(p, a, roll) @ Matrix.Translation(-grip[1].translation)
            right_pose, reach = rig.solve_arm(upper, side, h @ grip[1] @ grip[0].inverted())
            if reach > 0.008 or rig.collision(body, h, blade):
                continue
            if rig.offhand is not None:
                left_target = h @ Matrix.Translation(Vector((0, 0, rig.offhand))) @ rig.left_grip[1].to_3x3().to_4x4()
                left_target = left_target @ Matrix.Rotation(math.pi, 4, "Y") @ rig.left_grip[0].inverted()
                left_pose, reach = rig.solve_arm(upper, "L", left_target)
                if reach > 0.008:
                    continue
                right_pose.update(left_pose)
            return right_pose, weight > 0 or shift != 0
    raise ValueError(f"Agarre fuera de alcance: {side}, mano {tuple(point)}, eje {tuple(axis)}")


def make_clip(rig, source, weapon, action):
    heavy = action.startswith("Heavy")
    side = action[5:] if heavy else action[3:]
    thrust = weapon == "Rapier"
    dual = rig.left_blade is not None
    primary = "L" if dual and side == "Left" else "R"
    path, axes = track(side, heavy, thrust, -1 if primary == "L" else 1)
    rear = "R" if primary == "L" else "L"
    rear_path, rear_axes = rear_dagger(1 if rear == "R" else -1)
    if dual and heavy:
        # Segunda daga entra después de la primera. Cada mano conserva su propia empuñadura.
        rear_path[3] = Vector((0.63 if rear == "R" else -0.63, -0.02, -1.38))
        rear_axes[3] = Vector((0.10 if rear == "R" else -0.10, -0.19, -1)).normalized()
    def pose_at(u):
        pose = sample_source(source, u)
        pre = pose.copy()
        original_crossing = rig.audit(pre)[0]
        # Retenemos peso y paso de la fuente, limitando los giros que borrarían la dirección anunciada.
        for j in ("R", "W", "N"):
            angles = [(angle + 180) % 360 - 180 for angle in pose[j][:3]]
            weights = (0.33, 0.22, 0.33) if j == "R" else (0.49, 0.35, 0.43)
            pose[j][:3] = [max(-32, min(32, a * w)) for a, w in zip(angles, weights)]
        pose["R"][3:] = [max(-0.22, min(0.22, v * 0.45)) for v in pose["R"][3:]]
        if thrust:
            for j, weight in (("LS", 0.38), ("LE", 0.42), ("LW", 0.42)):
                pose[j] = [value * weight for value in pose[j]]
        body = rig.body(pose)
        main, adjustment = fit(rig, body, primary, mix(path, STAGES, u), mix(axes, STAGES, u))
        pose.update(main)
        if dual:
            other, adjusted_other = fit(rig, body, rear, mix(rear_path, STAGES, u), mix(rear_axes, STAGES, u), -1)
            pose.update(other)
            adjustment = adjustment or adjusted_other
        return pose, adjustment, original_crossing

    def measure(a, b, alpha):
        sample = {j: [x + (y - x) * alpha for x, y in zip(a[j], continuous(b[j], a[j]))] for j in a}
        return rig.audit(sample)

    def refine(a, b, depth=0):
        if depth >= 5 or all(not hit and err <= 0.055
                             for hit, err in (measure(a[1], b[1], f) for f in (0.25, 0.5, 0.75))):
            return [b]
        u = round((a[0] + b[0]) / 2, 5)
        mid = [u, pose_at(u)[0]]
        return refine(a, mid, depth + 1) + refine(mid, b, depth + 1)

    keys, corrected, original = [], 0, 0
    for u in sorted(set(STAGES).union(round(i / SAMPLE_COUNT, 5) for i in range(SAMPLE_COUNT + 1))):
        pose, adjustment, source_crossing = pose_at(u)
        keys.append([u, pose])
        corrected += int(adjustment)
        original += int(source_crossing)
    source_keys = len(keys)
    refined = [keys[0]]
    for a, b in zip(keys, keys[1:]):
        refined.extend(refine(a, b))
    keys, prior, max_error = [], {}, 0
    for u, raw in refined:
        pose = {j: [round(v, 4) for v in continuous(values, prior.get(j))] for j, values in raw.items()}
        hit, error = rig.audit(pose)
        if hit:
            raise ValueError(f"{weapon}.{action}: cruce de torso en {u}")
        max_error = max(max_error, error)
        keys.append([u, pose])
        prior = pose
    between = 0
    for (_, a), (_, b) in zip(keys, keys[1:]):
        for f in (0.25, 0.5, 0.75):
            sample = {j: [x + (y - x) * f for x, y in zip(a[j], b[j])] for j in a}
            hit, error = rig.audit(sample)
            between += int(hit)
            max_error = max(max_error, error)
    if between or max_error > 0.08:
        raise ValueError(f"{weapon}.{action}: {between} cruces intermedios, error {max_error:.4f} studs")
    return {"dur": round(source["dur"], 4), "windup": WINDUP, "hit": HIT, "keys": keys}, {
        "frames": len(keys), "retargetedFrames": source_keys, "insertedKeys": len(keys) - source_keys,
        "sourceTorsoCrossings": original, "reachCorrections": corrected,
        "intersections": 0, "intersectionsBetweenKeys": between, "maxGripErrorStuds": round(max_error, 6),
    }


def main(source_dir, output, common, rigs_file, weapons):
    common = json.loads(common.read_text(encoding="utf-8-sig"))
    measured = json.loads(rigs_file.read_text(encoding="utf-8-sig"))
    cache = {}
    with TemporaryDirectory() as scratch, ZipFile(source_dir / "Great Sword Pack.zip") as archive:
        for weapon in weapons:
            clips, report = {}, {}
            rig = Rig(common, measured[weapon])
            for action, name in SOURCES[weapon].items():
                filename = name + ".fbx"
                if name not in cache:
                    file = source_dir / filename
                    if not file.exists():
                        file = Path(scratch) / filename
                        file.write_bytes(archive.read(filename))
                    cache[name] = convert(str(file), sample_step=1)
                    if "error" in cache[name]:
                        raise RuntimeError(f"{filename}: {cache[name]['error']}")
                key = weapon + action
                clips[key], report[key] = make_clip(rig, cache[name], weapon, action)
                clips[key]["source"] = filename
                report[key]["source"] = filename
                print(key, report[key], flush=True)
            (output / (weapon + ".json")).write_text(json.dumps(clips, separators=(",", ":")), encoding="utf-8")
            (output / (weapon + "_validacion.json")).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:]
    main(*map(Path, args[:4]), args[4:] or SOURCES)
