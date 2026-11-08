#!/usr/bin/env python3
"""Stretch the Magic Wand 3MF to a new total height, keeping the end caps fixed.

Usage: python3 -I stretch_wand.py in.3mf out.3mf TOTAL_H CAP_H
"""
import re, sys, zipfile

src, dst, total_h, cap_h = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])

zin = zipfile.ZipFile(src)
obj = zin.read('3D/Objects/object_1.model').decode()

V = [(float(a), float(b), float(c)) for a, b, c in
     re.findall(r'<vertex x="([^"]+)" y="([^"]+)" z="([^"]+)"', obj)]
zmin, zmax = min(v[2] for v in V), max(v[2] for v in V)
old_h = zmax - zmin
old_half = old_h / 2
assert abs(zmin + zmax) < 1e-6, "mesh expected centred on z=0"
new_half = total_h / 2
old_mid_half = old_half - cap_h          # where the cap meets the body
new_mid_half = new_half - cap_h

def new_z(z):
    if z >= old_mid_half - 1e-6:        # top cap: rigid shift
        return z + (new_half - old_half)
    if z <= -old_mid_half + 1e-6:       # bottom cap: rigid shift
        return z - (new_half - old_half)
    return z * new_mid_half / old_mid_half  # body: stretch

def repl(m):
    return f'<vertex x="{m.group(1)}" y="{m.group(2)}" z="{new_z(float(m.group(3))):.8g}"/>'
obj2 = re.sub(r'<vertex x="([^"]+)" y="([^"]+)" z="([^"]+)"/>', repl, obj)

shift = new_half - old_half
def fix_offset(text, old, new):
    n = text.count(old)
    assert n > 0, f"pattern not found: {old!r}"
    return text.replace(old, new)

old_off = f'{old_half:g}'            # "89.5"
new_off = f'{new_half:g}'
model = zin.read('3D/3dmodel.model').decode()
model = re.sub(r'(<item [^>]*transform="1 0 0 0 1 0 0 0 1 [^ ]+ [^ ]+ )' + re.escape(old_off) + '"',
               lambda m: m.group(1) + new_off + '"', model)

settings = zin.read('Metadata/model_settings.config').decode()
settings = fix_offset(settings, f'key="source_offset_z" value="{old_off}"',
                      f'key="source_offset_z" value="{new_off}"')
settings = re.sub(r'(<assemble_item object_id="2" instance_id="0" transform="1 0 0 0 1 0 0 0 1 [^ ]+ [^ ]+ )' + re.escape(old_off) + '"',
                  lambda m: m.group(1) + new_off + '"', settings)

gcode = zin.read('Metadata/custom_gcode_per_layer.xml').decode()
old_top_white = f'{old_h - cap_h:g}'   # "147"
new_top_white = f'{total_h - cap_h:g}'
gcode = fix_offset(gcode, f'top_z="{old_top_white}"', f'top_z="{new_top_white}"')

changed = {'3D/Objects/object_1.model': obj2, '3D/3dmodel.model': model,
           'Metadata/model_settings.config': settings,
           'Metadata/custom_gcode_per_layer.xml': gcode}
with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zout:
    for info in zin.infolist():
        data = changed[info.filename].encode() if info.filename in changed else zin.read(info.filename)
        zout.writestr(info, data)

print(f"old height {old_h:g} -> new {total_h:g}; caps {cap_h:g} each; body {old_h-2*cap_h:g} -> {total_h-2*cap_h:g}")
print(f"plate offset {old_off} -> {new_off}; white tool-change top_z {old_top_white} -> {new_top_white}")
