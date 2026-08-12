#!/usr/bin/env python3
"""Convert ASCII STL files to binary STL in place (lossless)."""
import struct, sys, os

def convert(path):
    with open(path, 'rb') as f:
        head = f.read(6)
    if not head.startswith(b'solid'):
        print(f"skip (already binary): {path}")
        return
    tris = []
    normal = (0.0, 0.0, 0.0)
    verts = []
    with open(path) as f:
        for line in f:
            t = line.split()
            if not t:
                continue
            if t[0] == 'facet' and t[1] == 'normal':
                normal = tuple(float(x) for x in t[2:5])
            elif t[0] == 'vertex':
                verts.append(tuple(float(x) for x in t[1:4]))
                if len(verts) == 3:
                    tris.append((normal, verts))
                    verts = []
    tmp = path + '.tmp'
    with open(tmp, 'wb') as f:
        f.write(b'binary STL (converted from OpenSCAD ASCII)'.ljust(80, b' '))
        f.write(struct.pack('<I', len(tris)))
        for n, vs in tris:
            f.write(struct.pack('<3f', *n))
            for v in vs:
                f.write(struct.pack('<3f', *v))
            f.write(struct.pack('<H', 0))
    os.replace(tmp, path)
    print(f"converted: {path} ({len(tris)} tris, {os.path.getsize(path)//1024} KiB)")

for p in sys.argv[1:]:
    convert(p)
