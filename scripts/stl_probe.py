#!/usr/bin/env python3
"""Mesh-level checks on binary STLs: bbox, signed volume, vertical ray-casts.

usage: stl_probe.py file.stl [x,y ...]
For each x,y it lists the z values where a vertical ray crosses the mesh
(0 crossings = open hole, pairs = solid spans). Volume < 0 means the faces
are inverted. No eyeballing required.
"""
import struct, sys

def load(path):
    with open(path, 'rb') as f:
        head = f.read(80)
        if head.startswith(b'solid') and b'binary' not in head:
            sys.exit(f"{path}: ASCII STL - run scripts/stl2bin.py first")
        n = struct.unpack('<I', f.read(4))[0]
        data = f.read(50 * n)
    tris = []
    for i in range(n):
        v = struct.unpack_from('<12f', data, 50 * i)
        tris.append(((v[3], v[4], v[5]), (v[6], v[7], v[8]), (v[9], v[10], v[11])))
    return tris

def bbox(tris):
    xs = [p[0] for t in tris for p in t]; ys = [p[1] for t in tris for p in t]; zs = [p[2] for t in tris for p in t]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))

def volume(tris):
    v = 0.0
    for a, b, c in tris:
        v += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) + a[2] * (b[0] * c[1] - b[1] * c[0]))
    return v / 6.0

def raycast(tris, x, y):
    zs = []
    for a, b, c in tris:
        d1 = (b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0])
        d2 = (c[0] - b[0]) * (y - b[1]) - (c[1] - b[1]) * (x - b[0])
        d3 = (a[0] - c[0]) * (y - c[1]) - (a[1] - c[1]) * (x - c[0])
        if (d1 >= 0 and d2 >= 0 and d3 >= 0) or (d1 <= 0 and d2 <= 0 and d3 <= 0):
            ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
            vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
            nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
            if abs(nz) < 1e-12:
                continue
            zs.append(a[2] - (nx * (x - a[0]) + ny * (y - a[1])) / nz)
    zs.sort()
    out = []
    for z in zs:                      # merge shared-edge duplicates
        if not out or abs(z - out[-1]) > 1e-4:
            out.append(z)
    return out

if __name__ == '__main__':
    tris = load(sys.argv[1])
    (x0, x1), (y0, y1), (z0, z1) = bbox(tris)
    print(f"{sys.argv[1]}: {len(tris)} tris  bbox x[{x0:.2f},{x1:.2f}] y[{y0:.2f},{y1:.2f}] z[{z0:.2f},{z1:.2f}]  volume {volume(tris):.1f} mm^3")
    for arg in sys.argv[2:]:
        x, y = (float(s) for s in arg.split(','))
        zs = raycast(tris, x, y)
        print(f"  ray ({x:g},{y:g}): {len(zs)} crossings " + ' '.join(f"{z:.2f}" for z in zs))
