#!/usr/bin/env python3
"""Remix of the "6-20 Expandable Vent Cover / Vent Deflector" (MakerWorld 2722921,
6-12" profile): keep the two telescoping halves exactly as designed, but change the
curved sweep of the scoop. The original sweep is a quarter circle, R 100 mm (4" off
the wall, 4" along it). This script re-sweeps it along a quarter ellipse with
semi-axes OUT (off the wall) and ALONG (along the wall), e.g. 304.8 x 304.8 for a
12" quarter circle or 100 x 302 for 4" out and 11.9" along the wall.

Everything the slide depends on is preserved at its original size: wall thickness,
the interlocking rails at the hood and mid-arc, the end caps, the magnet bosses and
their pockets. Only the plain arc between features is stretched. The cap magnet
boss is replicated CAP_BOSSES times, evenly spaced along the new wall-contact face.

How: both halves are put in one frame (arc centre C, hood at 90 deg on the wall face
x = 50, exit edge at 180 deg on y = -50). Each vertex (r, theta) about C maps to
    E(t') + (r - R) * n(t')          for the wall band (r >= 70)
where E is the ellipse, n its outward unit normal (so wall thickness and rail depth
are kept), and t' comes from an arc-length map: bands holding rails/lips keep their
original arc length, plain bands absorb the rest. The flat cap inside r < 70 is
scaled to meet the wall band. Both halves get the identical map, so their nesting
fit is unchanged (verified by the 2D profile overlap and the 3D intersection volume
at several slide positions).

Usage:  python3 sweep_remix.py [--src original.3mf] [ALONG_mm OUT_mm TAG] ...
        default builds both  304.8 304.8 12in_sweep  and  302 100 ellipse_302x100
Needs:  numpy, trimesh, shapely, manifold3d, rtree
"""
import re, sys, zipfile, os
import numpy as np, trimesh
from shapely.geometry import Polygon
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[1:]
SRC = os.path.join(HERE, "original", "6-12-Inch_Vent_Deflector_Chasing_Filament.3mf")
if args and args[0] == "--src": SRC = args[1]; args = args[2:]
VARIANTS = [(float(args[i]), float(args[i + 1]), args[i + 2]) for i in range(0, len(args), 3)] or \
           [(304.8, 304.8, "12in_sweep"), (302.0, 100.0, "ellipse_302x100")]
OUT = os.path.join(HERE, "stl")

R_OLD = 100.0                     # outer radius of the original arc
C = np.array([50.0, -50.0])       # arc centre in the outer half's frame
R0 = 70.0                         # inside this radius (flat cap only) scale instead of offset
LEFT_X_SHIFT = 1.16               # inner half's arc centre is 1.16 mm off its own bbox frame
CAP_TOP_R, CAP_TOP_L = -74.0, -72.8   # cap top faces (outer half 1 mm cap, inner half 2 mm)
CAP_BOSSES = 3                    # magnet bosses per end cap, spread evenly along the wall face (original: 1)

# ---------------------------------------------------------------- load the 3MF
def load_3mf_object(zf, path):
    t = zf.read(path).decode()
    v = np.array([[float(x) for x in m] for m in re.findall(r'<vertex x="([^"]+)" y="([^"]+)" z="([^"]+)"', t)])
    f = np.array([[int(x) for x in m] for m in re.findall(r'<triangle v1="(\d+)" v2="(\d+)" v3="(\d+)"', t)])
    return trimesh.Trimesh(v, f, process=False)
with zipfile.ZipFile(SRC) as zf:
    cfg = zf.read("Metadata/model_settings.config").decode()
    names = dict(re.findall(r'<object id="(\d+)">\s*<metadata key="name" value="([^"]+)"', cfg))
    rels = zf.read("3D/3dmodel.model").decode()
    paths = dict(re.findall(r'<object id="(\d+)"[^>]*>\s*<components>\s*<component p:path="([^"]+)"', rels))
    meshes = {names[i]: load_3mf_object(zf, p.lstrip("/")) for i, p in paths.items()}
outer = next(m for n, m in meshes.items() if "Right" in n)   # "Right Side" = outer half
inner = next(m for n, m in meshes.items() if "Left" in n)    # "Left Side"  = inner half
assert outer.is_watertight and inner.is_watertight

# ----------------------------------------------- common frame (outer half's)
def inner_to_common(m):      # flip end-for-end about x, then centre its arc on C
    v = m.vertices.copy(); v[:, 1] *= -1; v[:, 2] *= -1; v[:, 0] += LEFT_X_SHIFT
    return trimesh.Trimesh(v, m.faces, process=False)
def inner_from_common(m):
    v = m.vertices.copy(); v[:, 0] -= LEFT_X_SHIFT; v[:, 1] *= -1; v[:, 2] *= -1
    return trimesh.Trimesh(v, m.faces, process=False)
innerc = inner_to_common(inner)

def section(m, z):
    s = m.section(plane_origin=[0, 0, z], plane_normal=[0, 0, 1])
    ps = [Polygon(s.vertices[e.points][:, :2]).buffer(0) for e in s.entities if len(e.points) > 3]
    o = max(ps, key=lambda p: p.area); holes = [p for p in ps if p is not o and o.contains(p)]
    return o.difference(unary_union(holes)) if holes else o
def polar(xy):
    d = xy - C; r = np.hypot(d[:, 0], d[:, 1]); th = np.degrees(np.arctan2(d[:, 1], d[:, 0]))
    return r, np.where(th < 0, th + 360, th)

# ------------------------------------- feature bands (rails, lips) along the arc
def bands(m, rlo, rhi):
    p = np.array(section(m, 0).exterior.coords); r, th = polar(p)
    ths = np.sort(th[(r < rlo) | (r > rhi)]); g = []
    for t in ths:
        if g and t - g[-1][-1] < 1.2: g[-1].append(t)
        else: g.append([t])
    return [(x[0], x[-1]) for x in g if len(x) > 2]
ivs = sorted((max(90, a - 0.6), min(180, b + 0.6)) for a, b in bands(outer, 97.9, 100.05) + bands(innerc, 95.7, 97.9))
FEAT = []
for a, b in ivs:
    if FEAT and a <= FEAT[-1][1]: FEAT[-1] = (FEAT[-1][0], max(FEAT[-1][1], b))
    else: FEAT.append((a, b))
if FEAT[0][0] < 91.5: FEAT[0] = (90.0, FEAT[0][1])
print("feature bands (deg):", np.round(FEAT, 1).tolist())

def box(x0, x1, y0, y1, z0, z1): return trimesh.creation.box(bounds=[[x0, y0, z0], [x1, y1, z1]])
def split(m, b):
    return (trimesh.boolean.intersection([m, b], engine="manifold"),
            trimesh.boolean.difference([m, b], engine="manifold"))

def remix(ALONG, OUTW, tag):
    print(f"\n=== {tag}: sweep {OUTW:g} mm off the wall x {ALONG:g} mm along it ===")
    a, b = OUTW, ALONG
    # ellipse E(t) = C + (a cos t, b sin t), t in [90,180] deg; arc-length table
    tt = np.radians(np.linspace(90, 180, 40001)); ex, ey = a * np.cos(tt), b * np.sin(tt)
    ss = np.r_[0, np.cumsum(np.hypot(np.diff(ex), np.diff(ey)))]; S = ss[-1]
    featw = sum(hi - lo for lo, hi in FEAT); Lfeat = np.radians(featw) * R_OLD
    KS = (S - Lfeat) / (np.radians(90 - featw) * R_OLD)          # plain-arc stretch factor
    xs, ys = [90.0], [0.0]
    for lo, hi in FEAT:
        if lo > xs[-1]: xs.append(lo); ys.append(ys[-1] + np.radians(lo - xs[-2]) * R_OLD * KS)
        xs.append(hi); ys.append(ys[-1] + np.radians(hi - lo) * R_OLD)
    if xs[-1] < 180: xs.append(180.0); ys.append(ys[-1] + np.radians(180 - xs[-2]) * R_OLD * KS)
    assert abs(ys[-1] - S) < 1e-6
    print(f"ellipse quarter arc {S:.1f} mm; plain-arc stretch x{KS:.3f}; rail bands kept at original length")
    def place(r, th):
        s = np.interp(np.clip(th, 90, 180), xs, ys); t = np.interp(s, ss, tt)
        E = np.c_[C[0] + a * np.cos(t), C[1] + b * np.sin(t)]
        n = np.c_[b * np.cos(t), a * np.sin(t)]; n /= np.linalg.norm(n, axis=1)[:, None]
        return E + (r - R_OLD)[:, None] * n
    def fmap(v):
        v = v.copy(); r, th = polar(v[:, :2])
        wall = place(np.maximum(r, R0), th)                     # r >= R0: normal offset of the ellipse
        cap = C + (r / R0)[:, None] * (place(np.full_like(r, R0), th) - C)   # r < R0: scaled flat cap
        v[:, :2] = np.where((r >= R0)[:, None], wall, cap); return v
    # wall face spans y = C.y .. C.y + b; bosses at 1/(n+1), 2/(n+1), ... of it (n=1 -> mid-face)
    boss_y = [C[1] + b * k / (CAP_BOSSES + 1) for k in range(1, CAP_BOSSES + 1)]
    print("cap magnet bosses at y =", np.round(boss_y, 1).tolist(), "(2 pockets each)")
    def rebuild(m, bossbox, weld_dir):
        boss, rest = split(m, bossbox)
        mapped = trimesh.Trimesh(fmap(rest.vertices), rest.faces, process=False)
        copies = [boss.copy().apply_translation([0, y, 0.3 * weld_dir]) for y in boss_y]  # 0.3 mm into the cap
        out = trimesh.boolean.union([mapped] + copies, engine="manifold"); out.merge_vertices()
        assert out.is_watertight; return out
    new_outer = rebuild(outer, box(40.5, 50.6, -13, 13, CAP_TOP_R, -62.5), -1)
    new_inner = rebuild(innerc, box(40.5, 50.6, -13, 13, 62.5, -CAP_TOP_L), +1)
    # ---- verify the fit against the original
    ov0 = section(outer, 0).intersection(section(innerc, 0)).area
    ov1 = section(new_outer, 0).intersection(section(new_inner, 0)).area
    print(f"nested profile overlap at z=0: original {ov0:.4f} mm^2, new {ov1:.4f} mm^2")
    for s in [2, 60, 120]:
        o = trimesh.boolean.intersection([outer, innerc.copy().apply_translation([0, 0, s])], engine="manifold").volume
        n = trimesh.boolean.intersection([new_outer, new_inner.copy().apply_translation([0, 0, s])], engine="manifold").volume
        print(f"slide {s:3} mm: interference original {o:6.3f} mm^3, new {n:6.3f} mm^3")
        assert n < 2.5 and abs(n - o) < 1.0
    print(f"outer half bounds {np.round(new_outer.bounds, 1).tolist()}")
    # ---- export, print frames (cap on z=0)
    os.makedirs(OUT, exist_ok=True)
    o = new_outer.copy(); o.apply_translation([0, 0, -o.bounds[0][2]]); o.export(os.path.join(OUT, f"vent_deflector_{tag}_outer.stl"))
    i = inner_from_common(new_inner); i.apply_translation([0, 0, -i.bounds[0][2]]); i.export(os.path.join(OUT, f"vent_deflector_{tag}_inner.stl"))
    print("wrote", f"vent_deflector_{tag}_outer.stl", f"vent_deflector_{tag}_inner.stl")

for ALONG, OUTW, tag in VARIANTS: remix(ALONG, OUTW, tag)
