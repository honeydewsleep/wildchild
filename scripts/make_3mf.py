#!/usr/bin/env python3
"""Build a slicer project 3MF (with print pauses) from binary STLs.

usage: make_3mf.py --flavor bbl|prusa --out file.3mf [--pause Z[:message]]...
                   NAME=path.stl@X,Y ...

bbl   : Bambu Studio / OrcaSlicer project (Metadata/custom_gcode_per_layer.xml,
        model_settings.config, project_settings.config from the bundled
        template so the file loads as a project and keeps its pauses).
prusa : PrusaSlicer / SuperSlicer project
        (Metadata/Prusa_Slicer_custom_gcode_per_print_z.xml).

Pause Z is the layer top height (print coordinates, part sitting on the bed);
the pause happens before the layer above it starts. Parts are placed with
their XY bounding-box centre at X,Y and their lowest point on the bed.
Format details were taken from BambuStudio's bbs_3mf.cpp and a project
exported by Bambu Studio 2.0.
"""
import argparse, datetime, os, struct, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
BBL_VER = "02.00.02.01"

def read_stl(path):
    with open(path, 'rb') as f:
        head = f.read(80)
        if head.startswith(b'solid') and b'binary' not in head:
            raise SystemExit(f"{path}: ASCII STL - run stl2bin.py first")
        n = struct.unpack('<I', f.read(4))[0]
        data = f.read(50 * n)
    verts, index, tris = [], {}, []
    for i in range(n):
        v = struct.unpack_from('<12f', data, 50 * i)
        ids = []
        for k in (3, 6, 9):
            key = (round(v[k], 4), round(v[k+1], 4), round(v[k+2], 4))
            j = index.get(key)
            if j is None:
                j = len(verts); index[key] = j; verts.append(key)
            ids.append(j)
        tris.append(tuple(ids))
    xs = [p[0] for p in verts]; ys = [p[1] for p in verts]; zs = [p[2] for p in verts]
    cx, cy, z0 = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)
    verts = [(x - cx, y - cy, z - z0) for x, y, z in verts]   # XY centred, bottom at z=0
    return verts, tris

def mesh_xml(verts, tris, indent=' '):
    out = [f'{indent}<mesh>', f'{indent} <vertices>']
    out += [f'{indent}  <vertex x="{x:.5f}" y="{y:.5f}" z="{z:.5f}"/>' for x, y, z in verts]
    out += [f'{indent} </vertices>', f'{indent} <triangles>']
    out += [f'{indent}  <triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris]
    out += [f'{indent} </triangles>', f'{indent}</mesh>']
    return '\n'.join(out)

def esc(s):
    return s.replace('&', '&amp;').replace('"', '&quot;').replace('<', '&lt;').replace('>', '&gt;')

CORE_NS = 'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02"'
PROD_NS = 'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06"'
BBL_NS = 'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021"'
CONTENT_TYPES = ('<?xml version="1.0" encoding="UTF-8"?>\n'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
    ' <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
    ' <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>\n'
    ' <Default Extension="png" ContentType="image/png"/>\n'
    ' <Default Extension="gcode" ContentType="text/x.gcode"/>\n'
    '</Types>\n')
RELS = ('<?xml version="1.0" encoding="UTF-8"?>\n'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
    ' <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>\n'
    '</Relationships>\n')

def build_bbl(parts, pauses, title):
    """parts: list of (name, verts, tris, x, y)"""
    today = datetime.date.today().isoformat()
    files = {'[Content_Types].xml': CONTENT_TYPES, '_rels/.rels': RELS}
    n = len(parts)
    # one sub-model file per part (sub-object ids 1..n), root component objects n+1..2n
    rels = ['<?xml version="1.0" encoding="UTF-8"?>',
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">']
    root = ['<?xml version="1.0" encoding="UTF-8"?>',
            f'<model unit="millimeter" xml:lang="en-US" {CORE_NS} {BBL_NS} {PROD_NS} requiredextensions="p">',
            f' <metadata name="Application">BambuStudio-{BBL_VER}</metadata>',
            ' <metadata name="BambuStudio:3mfVersion">1</metadata>',
            ' <metadata name="Copyright"></metadata>',
            f' <metadata name="CreationDate">{today}</metadata>',
            ' <metadata name="Description"></metadata>',
            ' <metadata name="Designer"></metadata>',
            ' <metadata name="DesignerCover"></metadata>',
            ' <metadata name="DesignerUserId"></metadata>',
            ' <metadata name="License"></metadata>',
            f' <metadata name="ModificationDate">{today}</metadata>',
            ' <metadata name="Origin"></metadata>',
            f' <metadata name="Title">{esc(title)}</metadata>',
            ' <resources>']
    build, cfg_objs, cfg_inst, cfg_asm, cut = [], [], [], [], []
    for i, (name, verts, tris, x, y) in enumerate(parts, start=1):
        sub, rootid = i, n + i
        files[f'3D/Objects/object_{i}.model'] = '\n'.join([
            '<?xml version="1.0" encoding="UTF-8"?>',
            f'<model unit="millimeter" xml:lang="en-US" {CORE_NS} {BBL_NS} {PROD_NS} requiredextensions="p">',
            ' <metadata name="BambuStudio:3mfVersion">1</metadata>',
            ' <resources>',
            f'  <object id="{sub}" p:UUID="{sub:04x}0000-81cb-4c03-9d28-80fed5dfa1dc" type="model">',
            mesh_xml(verts, tris, '   '),
            '  </object>', ' </resources>', ' <build/>', '</model>', ''])
        rels.append(f' <Relationship Target="/3D/Objects/object_{i}.model" Id="rel-{i}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
        root += [f'  <object id="{rootid}" p:UUID="{rootid:08x}-61cb-4c03-9d28-80fed5dfa1dc" type="model">',
                 '   <components>',
                 f'    <component p:path="/3D/Objects/object_{i}.model" objectid="{sub}" p:UUID="{sub:04x}0000-b206-40ff-9872-83e8017abed1" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>',
                 '   </components>', '  </object>']
        build.append(f'  <item objectid="{rootid}" p:UUID="{rootid:08x}-b1ec-4553-aec9-835e5b724bb4" transform="1 0 0 0 1 0 0 0 1 {x} {y} 0" printable="1"/>')
        cfg_objs += [f'  <object id="{rootid}">',
                     f'    <metadata key="name" value="{esc(name)}"/>',
                     '    <metadata key="extruder" value="1"/>',
                     f'    <metadata face_count="{len(tris)}"/>',
                     f'    <part id="{sub}" subtype="normal_part">',
                     f'      <metadata key="name" value="{esc(name)}"/>',
                     '      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>',
                     f'      <metadata key="source_file" value="{esc(name)}.stl"/>',
                     '      <metadata key="source_object_id" value="0"/>',
                     '      <metadata key="source_volume_id" value="0"/>',
                     '      <metadata key="source_offset_x" value="0"/>',
                     '      <metadata key="source_offset_y" value="0"/>',
                     '      <metadata key="source_offset_z" value="0"/>',
                     f'      <mesh_stat face_count="{len(tris)}" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>',
                     '    </part>', '  </object>']
        cfg_inst += ['    <model_instance>',
                     f'      <metadata key="object_id" value="{rootid}"/>',
                     '      <metadata key="instance_id" value="0"/>',
                     f'      <metadata key="identify_id" value="{100 + i}"/>',
                     '    </model_instance>']
        cfg_asm.append(f'   <assemble_item object_id="{rootid}" instance_id="0" transform="1 0 0 0 1 0 0 0 1 {x} {y} 0" offset="0 0 0" />')
        cut += [f' <object id="{i}">', '  <cut_id id="0" check_sum="1" connectors_cnt="0"/>', ' </object>']
    rels.append('</Relationships>')
    root += [' </resources>', ' <build p:UUID="2c7c17d8-22b5-4d84-8835-1976022ea369">'] + build + [' </build>', '</model>', '']
    files['3D/_rels/3dmodel.model.rels'] = '\n'.join(rels) + '\n'
    files['3D/3dmodel.model'] = '\n'.join(root)
    files['Metadata/model_settings.config'] = '\n'.join(
        ['<?xml version="1.0" encoding="UTF-8"?>', '<config>'] + cfg_objs +
        ['  <plate>', '    <metadata key="plater_id" value="1"/>', '    <metadata key="plater_name" value=""/>',
         '    <metadata key="locked" value="false"/>'] + cfg_inst + ['  </plate>', '  <assemble>'] + cfg_asm +
        ['  </assemble>', '</config>', ''])
    files['Metadata/cut_information.xml'] = '\n'.join(['<?xml version="1.0" encoding="utf-8"?>', '<objects>'] + cut + ['</objects>', ''])
    files['Metadata/slice_info.config'] = ('<?xml version="1.0" encoding="UTF-8"?>\n<config>\n  <header>\n'
        '    <header_item key="X-BBL-Client-Type" value="slicer"/>\n'
        f'    <header_item key="X-BBL-Client-Version" value="{BBL_VER}"/>\n  </header>\n</config>\n')
    with open(os.path.join(HERE, 'bbl_project_settings_template.json')) as f:
        files['Metadata/project_settings.config'] = f.read()
    # pause list: type 1 = PausePrint (CustomGCode::Type), "extra" = message shown on the printer
    gc = ['<?xml version="1.0" encoding="utf-8"?>', '<custom_gcodes_per_layer>', '<plate>', '<plate_info id="1"/>']
    gc += [f'<layer top_z="{z}" type="1" extruder="1" color="#FFFFFF" extra="{esc(msg)}" gcode="M400 U1"/>' for z, msg in pauses]
    gc += ['<mode value="SingleExtruder"/>', '</plate>', '</custom_gcodes_per_layer>', '']
    files['Metadata/custom_gcode_per_layer.xml'] = '\n'.join(gc)
    return files

def build_prusa(parts, pauses, title):
    today = datetime.date.today().isoformat()
    files = {'[Content_Types].xml': CONTENT_TYPES, '_rels/.rels': RELS}
    root = ['<?xml version="1.0" encoding="UTF-8"?>',
            f'<model unit="millimeter" xml:lang="en-US" {CORE_NS} xmlns:slic3rpe="http://schemas.slic3r.org/3mf/2017/06">',
            ' <metadata name="slic3rpe:Version3mf">1</metadata>',
            f' <metadata name="Title">{esc(title)}</metadata>',
            ' <metadata name="Designer"></metadata>', f' <metadata name="Description">{esc(title)}</metadata>',
            ' <metadata name="Copyright"></metadata>', ' <metadata name="LicenseTerms"></metadata>',
            ' <metadata name="Rating"></metadata>', f' <metadata name="CreationDate">{today}</metadata>',
            f' <metadata name="ModificationDate">{today}</metadata>',
            ' <metadata name="Application">PrusaSlicer-2.7.2</metadata>', ' <resources>']
    build, cfg = [], ['<?xml version="1.0" encoding="UTF-8"?>', '<config>']
    for i, (name, verts, tris, x, y) in enumerate(parts, start=1):
        root += [f'  <object id="{i}" type="model">', mesh_xml(verts, tris, '   '), '  </object>']
        build.append(f'  <item objectid="{i}" transform="1 0 0 0 1 0 0 0 1 {x} {y} 0" printable="1"/>')
        cfg += [f' <object id="{i}" instances_count="1">',
                f'  <metadata type="object" key="name" value="{esc(name)}"/>',
                f'  <volume firstid="0" lastid="{len(tris) - 1}">',
                f'   <metadata type="volume" key="name" value="{esc(name)}.stl"/>',
                '   <metadata type="volume" key="volume_type" value="ModelPart"/>',
                '   <metadata type="volume" key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>',
                f'   <metadata type="volume" key="source_file" value="{esc(name)}.stl"/>',
                '   <mesh edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>',
                '  </volume>', ' </object>']
    root += [' </resources>', ' <build>'] + build + [' </build>', '</model>', '']
    files['3D/3dmodel.model'] = '\n'.join(root)
    files['Metadata/Slic3r_PE_model.config'] = '\n'.join(cfg + ['</config>', ''])
    gc = ['<?xml version="1.0" encoding="utf-8"?>', '<custom_gcodes_per_print_z>']
    gc += [f'<code print_z="{z}" type="1" extruder="1" color="" extra="{esc(msg)}" gcode="M601"/>' for z, msg in pauses]
    gc += ['<mode value="SingleExtruder"/>', '</custom_gcodes_per_print_z>', '']
    files['Metadata/Prusa_Slicer_custom_gcode_per_print_z.xml'] = '\n'.join(gc)
    return files

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--flavor', choices=['bbl', 'prusa'], required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--title', default='')
    ap.add_argument('--pause', action='append', default=[], metavar='Z[:MESSAGE]')
    ap.add_argument('parts', nargs='+', metavar='NAME=file.stl@X,Y')
    a = ap.parse_args()
    parts = []
    for spec in a.parts:
        name, rest = spec.split('=', 1)
        path, pos = rest.split('@')
        x, y = (float(s) for s in pos.split(','))
        verts, tris = read_stl(path)
        parts.append((name, verts, tris, x, y))
    pauses = []
    for p in a.pause:
        z, _, msg = p.partition(':')
        pauses.append((float(z), msg))
    pauses.sort()
    title = a.title or os.path.splitext(os.path.basename(a.out))[0]
    files = build_bbl(parts, pauses, title) if a.flavor == 'bbl' else build_prusa(parts, pauses, title)
    with zipfile.ZipFile(a.out, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, content in files.items():
            z.writestr(name, content)
    print(f"wrote {a.out}: {len(parts)} parts, {len(pauses)} pauses, {os.path.getsize(a.out)//1024} KiB")

if __name__ == '__main__':
    main()
