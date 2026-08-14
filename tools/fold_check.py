#!/usr/bin/env python3
"""Swept-clearance check for the tictac case hinge.

The OpenSCAD fit checks only test two poses: flat on the bed, and fully shut.
Neither catches a rub that happens *between* those, while the lid is swinging.
This walks the fold and reports the worst clearance at each station along the
hinge, so a chafe shows up as a number.

Rotation is about a line parallel to Y, so every point stays in its own XZ
plane -- a per-Y 2D test is therefore exact, not an approximation.

    python3 tools/fold_check.py stl/tictac_case.stl 5.5
    python3 tools/fold_check.py some_reference.stl 7.6   # to compare

Needs trimesh + shapely + scipy.  Not wired into render.sh: that stays a
pure-OpenSCAD build.
"""
import sys
import numpy as np
import trimesh
from shapely.geometry import Polygon
from shapely import affinity

AXIS_X = 35.25


def halves(path):
    parts = trimesh.load(path).split(only_watertight=False)
    left = [p for p in parts if p.bounds[0][0] < 1]
    right = [p for p in parts if p.bounds[0][0] > 33]
    if not left or not right:
        sys.exit(f"{path}: expected two separate halves, found {len(parts)} body(s). "
                 "If it is one body the halves are fused -- check part=\"collide\".")
    return left[0], right[0]


def sections(body, y):
    """Cross-section at Y, as solid polygons in (X, -Z)."""
    s = body.section(plane_origin=[0, y, 0], plane_normal=[0, 1, 0])
    if s is None:
        return []
    t = np.eye(4)
    t[:3, :3] = [[1, 0, 0], [0, 0, 1], [0, 1, 0]]
    t[:3, 3] = -np.array(t[:3, :3]).dot([0, y, 0])
    if np.linalg.det(t[:3, :3]) < 0:
        t[1, :] *= -1
    flat, _ = s.to_planar(to_2D=t, check=False)
    out = []
    for poly in flat.polygons_full:
        p = Polygon(poly.exterior)
        for hole in poly.interiors:
            p = p.difference(Polygon(hole))
        if p.is_valid and p.area > 1e-6:
            out.append(p)
    return out


def scan(path, axis_z, y_mid, max_angle=170.0, step=2.5):
    left, right = halves(path)
    print(f"\n{path}   axis Z={axis_z}, hinge centred on Y={y_mid}")
    print(f"  worst clearance over fold angles 0..{max_angle:g} deg "
          f"(full close excluded: the rims are meant to meet there)")
    print(f"  {'Yrel':>7} | {'min clr':>8} | at angle")
    worst = (9e9, None, None)
    for rel in [-14, -12, -11, -10, -9, -8, -6, -3, 0, 3, 6, 8, 9, 10, 11, 12, 14]:
        y = y_mid + rel
        ls, rs = sections(left, y), sections(right, y)
        if not ls or not rs:
            continue
        best = (9e9, None)
        for phi in np.arange(0, max_angle + 1e-9, step):
            near = 9e9
            for lp in ls:
                spun = affinity.rotate(lp, phi, origin=(AXIS_X, -axis_z))
                for rp in rs:
                    hit = spun.intersection(rp)
                    d = -np.sqrt(hit.area) if (not hit.is_empty and hit.area > 1e-9) \
                        else spun.distance(rp)
                    near = min(near, d)
            if near < best[0]:
                best = (near, phi)
        flag = "  <-- tight" if best[0] < 0.15 else ""
        print(f"  {rel:+7.1f} | {best[0]:8.3f} | {best[1]:5.1f}{flag}")
        if best[0] < worst[0]:
            worst = (best[0], rel, best[1])
    print(f"  worst overall: {worst[0]:.3f} mm at Yrel={worst[1]:+g}, angle={worst[2]:g}")
    if worst[0] < 0:
        print("  INTERFERENCE -- the halves overlap mid-swing.")
    return worst[0]


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    stl = sys.argv[1]
    axis_z = float(sys.argv[2])
    y_mid = float(sys.argv[3]) if len(sys.argv) > 3 else \
        trimesh.load(stl).bounds[1][1] / 2
    scan(stl, axis_z, y_mid)
