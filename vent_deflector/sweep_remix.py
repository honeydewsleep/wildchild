#!/usr/bin/env python3
"""Remix of the "6-20 Expandable Vent Cover / Vent Deflector" (MakerWorld 2722921,
6-12" profile): keep the two telescoping halves exactly as designed, but grow the
curved sweep of the scoop from 4" (R 100 mm) to 12" (R 304.8 mm).

Everything the slide depends on is preserved at its original size: wall thickness,
the interlocking rails at the hood and mid-arc, the end caps, the magnet bosses and
their pockets. Only the plain arc between features is stretched. The two cap magnet
bosses are moved to the middle of the (now 12") wall-contact face.

How it works: both halves are put in one frame (arc centre C, hood at 90 deg, exit
edge at 180 deg). Each vertex is mapped in polar coordinates about C:
  radius: r -> r + dR for the wall band (r >= 70), scaled for the flat cap inside;
  angle:  piecewise linear. Bands where either profile has a rail or lip keep their
          original arc length; the plain bands between them absorb the rest.
Both halves get the identical map, so their nesting fit is unchanged (verified by
the 2D profile overlap and 3D intersection volume at several slide positions).

Usage:  python3 sweep_remix.py [original.3mf] [sweep_inches]
Needs:  numpy, trimesh, shapely, manifold3d, rtree
"""
import re, sys, zipfile, json, os
import numpy as np, trimesh
from shapely.geometry import Polygon
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "original", "6-12-Inch_Vent_Deflector_Chasing_Filament.3mf")
SWEEP_IN = float(sys.argv[2]) if len(sys.argv) > 2 else 12.0
OUT = os.path.join(HERE, "stl")

R_OLD = 100.0                     # outer radius of the outer half's arc
R_NEW = SWEEP_IN * 25.4
DR = R_NEW - R_OLD
C = np.array([50.0, -50.0])       # arc centre in the outer half's frame
R0 = 70.0                         # inside this radius (flat cap only) scale instead of offset
LEFT_X_SHIFT = 1.16               # inner half's arc centre is 1.16 mm off its own bbox frame
CAP_TOP_R, CAP_TOP_L = -74.0, -72.8   # cap top faces (outer half 1 mm cap, inner half 2 mm)

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
for n, m in [("outer", outer), ("inner", inner)]:
    assert m.is_watertight, n

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
merged = []
for a, b in ivs:
    if merged and a <= merged[-1][1]: merged[-1] = (merged[-1][0], max(merged[-1][1], b))
    else: merged.append((a, b))
if merged[0][0] < 91.5: merged[0] = (90.0, merged[0][1])
CF = R_OLD / R_NEW
featw = sum(b - a for a, b in merged); K = (90 - CF * featw) / (90 - featw)
xs, ys = [90.0], [90.0]
for a, b in merged:
    if a > xs[-1]: xs.append(a); ys.append(ys[-1] + (a - xs[-2]) * K)
    xs.append(b); ys.append(ys[-1] + (b - a) * CF)
if xs[-1] < 180: xs.append(180.0); ys.append(ys[-1] + (180 - xs[-2]) * K)
assert abs(ys[-1] - 180) < 1e-6
print(f"sweep {R_OLD:.0f} -> {R_NEW:.1f} mm; feature bands {np.round(merged, 1).tolist()}; plain-arc angle factor {K:.4f}")

def fmap(v):
    v = v.copy(); r, th = polar(v[:, :2]); th = np.clip(th, 90, 180)
    rn = np.where(r >= R0, r + DR, r * (R0 + DR) / R0); tn = np.radians(np.interp(th, xs, ys))
    v[:, 0] = C[0] + rn * np.cos(tn); v[:, 1] = C[1] + rn * np.sin(tn); return v

# ------------------ cap bosses: cut out, move rigidly to mid-face, weld back on
def box(x0, x1, y0, y1, z0, z1): return trimesh.creation.box(bounds=[[x0, y0, z0], [x1, y1, z1]])
def split(m, b):
    return (trimesh.boolean.intersection([m, b], engine="manifold"),
            trimesh.boolean.difference([m, b], engine="manifold"))
mid_face = ((R_NEW - 50) + (-50)) / 2          # wall face now spans y = -50 .. R_NEW-50
def rebuild(m, bossbox, weld_dir):
    boss, rest = split(m, bossbox)
    mapped = trimesh.Trimesh(fmap(rest.vertices), rest.faces, process=False)
    boss.apply_translation([0, mid_face, 0.3 * weld_dir])        # 0.3 mm into the cap plate
    out = trimesh.boolean.union([mapped, boss], engine="manifold"); out.merge_vertices()
    assert out.is_watertight; return out
new_outer = rebuild(outer, box(40.5, 50.6, -13, 13, CAP_TOP_R, -62.5), -1)
new_inner = rebuild(innerc, box(40.5, 50.6, -13, 13, 62.5, -CAP_TOP_L), +1)

# ------------------------------------------------------------- verify the fit
ov0 = section(outer, 0).intersection(section(innerc, 0)).area
ov1 = section(new_outer, 0).intersection(section(new_inner, 0)).area
print(f"nested profile overlap at z=0: original {ov0:.4f} mm^2, new {ov1:.4f} mm^2")
for s in [2, 60, 120]:
    o = trimesh.boolean.intersection([outer, innerc.copy().apply_translation([0, 0, s])], engine="manifold").volume
    n = trimesh.boolean.intersection([new_outer, new_inner.copy().apply_translation([0, 0, s])], engine="manifold").volume
    print(f"slide {s:3} mm: interference original {o:6.3f} mm^3, new {n:6.3f} mm^3")
    assert n < 2.5 and abs(n - o) < 1.0
pts = np.array(section(new_outer, 0).exterior.coords); r, th = polar(pts); plain = r[(th > 105) & (th < 135)]
print(f"new outer-half wall radii {plain.min():.2f}..{plain.max():.2f}, bounds {np.round(new_outer.bounds, 1).tolist()}")

# ------------------------------------------ export, print frames (cap on z=0)
os.makedirs(OUT, exist_ok=True)
tag = f"{SWEEP_IN:g}in_sweep"
o = new_outer.copy(); o.apply_translation([0, 0, -o.bounds[0][2]]); o.export(os.path.join(OUT, f"vent_deflector_{tag}_outer.stl"))
i = inner_from_common(new_inner); i.apply_translation([0, 0, -i.bounds[0][2]]); i.export(os.path.join(OUT, f"vent_deflector_{tag}_inner.stl"))
print("wrote", os.listdir(OUT))
