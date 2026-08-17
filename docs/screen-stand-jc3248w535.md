# Display wedge stand — Guition JC3248W535C (3.5")

`scad/screen_stand/stand.scad` → `stl/screen_stand_jc3248w535.stl`

A re-dimensioned version of the "4.3 inch Screen Stand" wedge, rebuilt
parametrically so it fits the Guition JC3248W535C instead of the 4.3"
module. Screen sits **landscape** (module long axis horizontal), which
is the same module→wedge mapping the original uses.

```bash
openscad -o stl/screen_stand_jc3248w535.stl \
    -D 'display="jc3248w535"' scad/screen_stand/stand.scad
python3 scripts/stl2bin.py stl/screen_stand_jc3248w535.stl
```

## Why it is a rebuild and not a scale factor

The two displays are not similar in plan: X needs ×0.909, Y needs
×0.812. Any single scale factor leaves one axis wrong by ~5 mm. A
non-uniform scale fixes the footprint but drags everything else with
it — 2.5 mm walls become 2.0/2.3, the round corner reliefs turn into
ellipses, the cable trough narrows, and the two rest angles (the whole
point of the wedge) shift. So the form was measured out of the source
mesh and rebuilt from parameters.

## What the source STL actually is

Reverse-engineered from `4.3inch_Screen_Stand.stl` (8622 tris):

| feature | value |
|---|---|
| outer footprint | 69.40 × 117.15, corner r 3.5 |
| display pocket | 65.10 × 112.15, 9.00 deep |
| rim wall | 2.15 (X) / 2.50 (Y) |
| roof | four planes, 2.500 thick on all four |
| front face (+X) | 45.00° from horizontal |
| back face (−X) | 57.32° |
| end faces (±Y) | 57.78° |
| apex | x = −7.58, z = 51.28 |
| corner reliefs | Ø6.8 blind pockets, 2.05 mm inboard of the pocket corners |
| cable trough | 10 mm wide, y = ±5, cut clean through the 45° face from the apex to the rim |

It is a hollow wedge, open at the bottom. The module drops in from the
open face; its bezel lands on the rim and the pocket walls capture its
back body. The stand then rests on the 45° face (reclined) or the
57.3° face (upright) — two viewing angles from one part.

Those four angles are exactly `hull(base prism, ridge line)`, so the
rebuild reproduces them by intersecting four half-spaces with a
rounded-rect prism rather than by hulling.

## What the wall mount gave us

Measured from `Guition_JC3248W535_Wall_Mount_Enclosure.stl`, which the
user confirms fits the display perfectly:

| feature | value |
|---|---|
| outer | 63.10 × 95.10, corner r 4.0 |
| pocket (module back body) | 59.10 × 91.10, corner r 2.0 |
| pocket depth | 7.25 (z 1.00 → 8.25) |
| module seats at | z 3.25 → **5.00 mm from PCB-back plane to front face** |
| corner screw holes | Ø2.5 at 52.25 × 84.50 spacing, centred |
| corner pads | Ø7.5, counterbored Ø7.5 × 1.1 from the back |
| cable slot | 3.5 wide × 5.75 tall, bottom short edge, centred |

Screws enter from behind the plate and land in the module housing's four
corner brass nuts — that is the "corner mounting screw placement". The
stand does not use them: like the original it is a drop-in tray, and its
back is a closed roof with nothing to screw against.

## The new part

| feature | value | from |
|---|---|---|
| outer footprint | 63.10 × 95.10, corner r 4.0 | wall mount outer |
| height | 47.44 | falls out of the angles |
| display pocket | 59.10 × 91.10, corner r 2.0, 9.00 deep | wall mount pocket |
| rim wall | 2.00 | wall mount |
| roof | 2.500 | original |
| face angles | 45.00° / 57.32° / 57.78° | original, held constant |
| cable trough | 10 mm, 45° face | original |
| cable exit | 12 × 9 notch, −Y end wall, centred | see below |

Angles are held rather than scaled: they are what the stand *is*, and
holding them keeps both rest positions identical to the original. The
height therefore drops only 51.29 → 47.44 while the plan shrinks more.

Pocket depth stays at the original's 9.00 mm. The module's back body is
5.00 mm deep (wall mount) and its deepest back components reach 7.25 mm,
so 9.00 clears everything and the bezel lands on the rim with 1.45 mm
(X) / 1.70 mm (Y) of seat. The recess this leaves in front of the glass
is 4.0 mm, within 0.1 mm of what the original gives the 4.3" module.

**Corner reliefs are omitted here.** The original needs them; this
display does not — the wall mount clears the same module with a plain
r2.0 pocket corner, and a Ø6.8 relief in a 2.00 mm wall would leave only
0.65 mm of wall standing. `relief_on` turns them back on.

**The cable exit is the one guess in the part.** The wall mount's only
opening is a 3.5 mm slot — a hardwired-cable pass-through, too narrow
for a USB-C plug — so it does not tell us where the connector is. The
notch here is 12 × 9 mm, wide enough to pass a USB-C plug, at the centre
of the −Y end wall (the module's short edge, which is where the wall
mount puts its slot). If the port on your board sits elsewhere, move it
with `port_x` / `port_end` / `port_w` and re-render.

## Printing

Export orientation is print orientation: rim face down on the bed. Every
outer face is ≥45°, so no supports, no brim. The pocket walls and roof
are 2.0/2.5 mm — 3 perimeters at 0.4 mm nozzle.

## Verification

The same file renders a replica of the source stand
(`-D 'display="orig43"'`). Compared against the source mesh plane by
plane:

| plane | source | replica |
|---|---|---|
| 45° outer / inner | 30.900 / −28.400 | 30.900 / −28.400 |
| 57.3° outer / inner | 34.070 / −31.570 | 34.070 / −31.570 |
| 57.8° outer / inner | 54.360 / −51.860 | 54.350 / −51.850 |
| bounding box | 69.40 × 117.15 × 51.293 | 69.40 × 117.15 × 51.278 |

The 0.01–0.015 mm residuals are the two-decimal rounding on the back and
end angles. The replica intentionally omits the 4.3"-specific side port
cutouts and the Ø6.8→6.4 step in the reliefs.

The shipped part was then checked at the mesh level by ray-casting: rim
solid all round except the trough and the port notch, pocket open over
the full module footprint, roof intact either side of the trough band
and closed left of the apex, 0 OpenSCAD warnings.
