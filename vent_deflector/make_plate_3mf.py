#!/usr/bin/env python3
"""Pack the two halves into one Bambu Studio project 3MF, one part per plate, each
rotated about z to the angle that fits a square bed and centred on its plate.

Usage: python3 make_plate_3mf.py OUT.3mf BED_mm part1.stl part2.stl ...
Bambu Studio lays plates out left to right with a stride of 1.2 x the bed width;
select your 256 mm printer before opening the file so the plates line up.
"""
import sys, os, uuid, zipfile
import numpy as np, trimesh
from scipy.spatial import ConvexHull

out, bed = sys.argv[1], float(sys.argv[2]); files = sys.argv[3:]
STRIDE = bed * 1.2

def best_rotation(m):
    pts = m.vertices[:, :2]; h = pts[ConvexHull(pts).vertices]; best = (1e9, 0.0)
    for phi in np.radians(np.linspace(0, 180, 3601)):
        R = np.array([[np.cos(phi), -np.sin(phi)], [np.sin(phi), np.cos(phi)]]); q = h @ R.T
        e = max(np.ptp(q[:, 0]), np.ptp(q[:, 1]))
        if e < best[0]: best = (e, phi)
    return best

objects = []   # (name, mesh centred at origin, translation)
for k, f in enumerate(files):
    m = trimesh.load(f); ext, phi = best_rotation(m)
    assert ext <= bed, f"{f}: needs {ext:.1f} mm, bed is {bed:.0f}"
    m.apply_transform(trimesh.transformations.rotation_matrix(phi, [0, 0, 1]))
    c = (m.bounds[0] + m.bounds[1]) / 2; m.apply_translation(-c)          # centre mesh at origin
    size = m.bounds[1] - m.bounds[0]
    t = [k * STRIDE + bed / 2, bed / 2, size[2] / 2]                        # plate k, centred, on the bed
    name = os.path.splitext(os.path.basename(f))[0]
    objects.append((name, m, t))
    print(f"plate {k+1}: {name}: rotated {np.degrees(phi):.1f} deg, footprint {size[0]:.1f} x {size[1]:.1f} mm "
          f"(margin {(bed-size[0])/2:.1f} / {(bed-size[1])/2:.1f} mm per side), placed at x={t[0]:.1f} y={t[1]:.1f}")

def U(): return str(uuid.uuid4())
def obj_model(oid, m):
    v = "\n".join(f'     <vertex x="{x:.6g}" y="{y:.6g}" z="{z:.6g}"/>' for x, y, z in m.vertices)
    t = "\n".join(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in m.faces)
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
  <object id="{oid}" p:UUID="{U()}" type="model">
   <mesh>
    <vertices>
{v}
    </vertices>
    <triangles>
{t}
    </triangles>
   </mesh>
  </object>
 </resources>
 <build/>
</model>
'''
res, items, rels, cfg_objs, plates, assemble, fseq = [], [], [], [], [], [], {}
for k, (name, m, t) in enumerate(objects):
    mesh_id, obj_id, part_id = 2 * k + 1, 2 * k + 2, 2 * k + 1
    path = f"/3D/Objects/object_{mesh_id}.model"
    res.append(f'''  <object id="{obj_id}" p:UUID="{U()}" type="model">
   <components>
    <component p:path="{path}" objectid="{mesh_id}" p:UUID="{U()}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>
   </components>
  </object>''')
    tr = f"1 0 0 0 1 0 0 0 1 {t[0]:.6g} {t[1]:.6g} {t[2]:.6g}"
    items.append(f'  <item objectid="{obj_id}" p:UUID="{U()}" transform="{tr}" printable="1"/>')
    rels.append(f' <Relationship Target="{path}" Id="rel-{k+1}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
    cfg_objs.append(f'''  <object id="{obj_id}">
    <metadata key="name" value="{name}"/>
    <metadata key="extruder" value="1"/>
    <metadata face_count="{len(m.faces)}"/>
    <part id="{part_id}" subtype="normal_part">
      <metadata key="name" value="{name}"/>
      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>
      <metadata key="source_file" value="{name}.stl"/>
      <metadata key="source_object_id" value="0"/>
      <metadata key="source_volume_id" value="0"/>
      <metadata key="source_offset_x" value="{t[0]:.6g}"/>
      <metadata key="source_offset_y" value="{t[1]:.6g}"/>
      <metadata key="source_offset_z" value="{t[2]:.6g}"/>
      <mesh_stat face_count="{len(m.faces)}" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>
    </part>
  </object>''')
    plates.append(f'''  <plate>
    <metadata key="plater_id" value="{k+1}"/>
    <metadata key="plater_name" value=""/>
    <metadata key="locked" value="false"/>
    <model_instance>
      <metadata key="object_id" value="{obj_id}"/>
      <metadata key="instance_id" value="0"/>
      <metadata key="identify_id" value="{100+k}"/>
    </model_instance>
  </plate>''')
    assemble.append(f'   <assemble_item object_id="{obj_id}" instance_id="0" transform="{tr}" offset="0 0 0" />')
    fseq[f"plate_{k+1}"] = {"nozzle_sequence": [], "optimal_assignment": [], "sequence": []}
    objects[k] = (name, m, t, mesh_id)

model = f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="Application">BambuStudio-02.05.03.61</metadata>
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <metadata name="Title">Vent deflector, 4in x 11.9in sweep</metadata>
 <resources>
{chr(10).join(res)}
 </resources>
 <build p:UUID="{U()}">
{chr(10).join(items)}
 </build>
</model>
'''
model_settings = f'''<?xml version="1.0" encoding="UTF-8"?>
<config>
{chr(10).join(cfg_objs)}
{chr(10).join(plates)}
  <assemble>
{chr(10).join(assemble)}
  </assemble>
</config>
'''
import json
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
 <Default Extension="png" ContentType="image/png"/>
</Types>
''')
    z.writestr("_rels/.rels", '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
''')
    z.writestr("3D/3dmodel.model", model)
    z.writestr("3D/_rels/3dmodel.model.rels", '<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n' + "\n".join(rels) + "\n</Relationships>\n")
    for name, m, t, mesh_id in objects: z.writestr(f"3D/Objects/object_{mesh_id}.model", obj_model(mesh_id, m))
    z.writestr("Metadata/model_settings.config", model_settings)
    z.writestr("Metadata/cut_information.xml", '<?xml version="1.0" encoding="utf-8"?>\n<objects>\n' + "".join(f' <object id="{k+1}">\n  <cut_id id="0" check_sum="1" connectors_cnt="0"/>\n </object>\n' for k in range(len(objects))) + '</objects>\n')
    z.writestr("Metadata/filament_sequence.json", json.dumps(fseq))
    z.writestr("Metadata/slice_info.config", '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n  <header>\n    <header_item key="X-BBL-Client-Type" value="slicer"/>\n    <header_item key="X-BBL-Client-Version" value="02.05.03.61"/>\n  </header>\n</config>\n')
print("wrote", out)
