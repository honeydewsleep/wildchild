#!/usr/bin/env python3
"""Pack binary STLs into one 3MF with the parts laid out on a print plate.

usage: make_3mf.py out.3mf [--center X,Y] [--gap G] [--cols N] [--title T] name=path.stl ...
Parts are placed left-to-right in the order given (wrapping into rows of
--cols parts), bottoms on z=0, the whole group centred on --center (default 90,90: fits every Bambu bed,
A1 mini included). Plain 3MF core spec - Bambu Studio / Orca / Prusa
open it directly with the object names intact.
"""
import struct, sys, zipfile, math, datetime

def read_stl(path):
    b = open(path, 'rb').read()
    n = struct.unpack_from('<I', b, 80)[0]
    verts, index, tris = [], {}, []
    for i in range(n):
        o = 84 + 50*i + 12
        tri = []
        for j in range(3):
            v = struct.unpack_from('<3f', b, o + 12*j)
            k = (round(v[0], 4), round(v[1], 4), round(v[2], 4))
            if k not in index:
                index[k] = len(verts); verts.append(k)
            tri.append(index[k])
        if len(set(tri)) == 3:
            tris.append(tri)
    return verts, tris

def main():
    args = sys.argv[1:]
    out = args.pop(0)
    center, gap, cols, title = (90.0, 90.0), 8.0, 0, 'wildchild kit'
    parts = []
    while args:
        a = args.pop(0)
        if a == '--center': center = tuple(map(float, args.pop(0).split(',')))
        elif a == '--gap': gap = float(args.pop(0))
        elif a == '--cols': cols = int(args.pop(0))
        elif a == '--title': title = args.pop(0)
        else:
            name, path = a.split('=', 1); parts.append((name, path))

    meshes = []
    for name, path in parts:
        v, t = read_stl(path)
        xs = [p[0] for p in v]; ys = [p[1] for p in v]; zs = [p[2] for p in v]
        meshes.append(dict(name=name, v=v, t=t, xmin=min(xs), xmax=max(xs),
                           ymin=min(ys), ymax=max(ys), zmin=min(zs)))
    cols = cols or len(meshes)
    rows = [meshes[i:i+cols] for i in range(0, len(meshes), cols)]
    row_w = [sum(m['xmax'] - m['xmin'] for m in r) + gap*(len(r) - 1) for r in rows]
    row_h = [max(m['ymax'] - m['ymin'] for m in r) for r in rows]
    total_w = max(row_w); total_h = sum(row_h) + gap*(len(rows) - 1)
    y_top = center[1] + total_h/2
    pos = {}
    for r, rw, rh in zip(rows, row_w, row_h):
        x = center[0] - rw/2
        for m in r:
            pos[id(m)] = (x - m['xmin'], (y_top - rh/2) - (m['ymin'] + m['ymax'])/2)
            x += (m['xmax'] - m['xmin']) + gap
        y_top -= rh + gap
    objs, items = [], []
    for i, m in enumerate(meshes, 1):
        tx, ty = pos[id(m)]
        tz = -m['zmin']
        vs = ''.join(f'<vertex x="{a}" y="{b}" z="{c}"/>' for a, b, c in m['v'])
        ts = ''.join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in m['t'])
        objs.append(f'<object id="{i}" name="{m["name"]}" type="model"><mesh>'
                    f'<vertices>{vs}</vertices><triangles>{ts}</triangles></mesh></object>')
        items.append(f'<item objectid="{i}" transform="1 0 0 0 1 0 0 0 1 {tx:.4f} {ty:.4f} {tz:.4f}"/>')
        print(f'{m["name"]}: {len(m["v"])} verts, {len(m["t"])} tris, at x={tx + (m["xmin"]+m["xmax"])/2:.1f} y={ty + (m["ymin"]+m["ymax"])/2:.1f}')
    model = ('<?xml version="1.0" encoding="UTF-8"?>\n'
             '<model unit="millimeter" xml:lang="en-US" '
             'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">'
             f'<metadata name="Title">{title}</metadata>'
             '<metadata name="Application">wildchild/scripts/make_3mf.py</metadata>'
             f'<metadata name="CreationDate">{datetime.date.today().isoformat()}</metadata>'
             f'<resources>{"".join(objs)}</resources><build>{"".join(items)}</build></model>')
    ct = ('<?xml version="1.0" encoding="UTF-8"?>\n'
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
          '</Types>')
    rels = ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Target="/3D/3dmodel.model" Id="rel0" '
            'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>'
            '</Relationships>')
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ct)
        z.writestr('_rels/.rels', rels)
        z.writestr('3D/3dmodel.model', model)
    print(f'wrote {out}, group {total_w:.1f} x {total_h:.1f} mm centred on {center}')

if __name__ == '__main__':
    main()
