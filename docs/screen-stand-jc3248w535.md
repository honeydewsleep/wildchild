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
| height | 50.98 in use (43.43 in part space) | falls out of the angles |
| display pocket | 59.10 × 91.10, corner r 2.0, 9.00 deep | wall mount pocket |
| rim wall | 2.00 | wall mount |
| roof | 2.500 | original |
| face angles | 45.00° / 57.32° / 57.78° | original, held constant |
| flat back | 26.0 tall × 74.9 wide, vertical in use | squares off the apex |
| USB-C socket | Ø16.6 bore, 13 mm up the flat back | panel mount, M16 × 1 |
| magnet bosses | 4 × Ø6.2 × 3.0, seat z 7.00 | corner insert grid |
| internal cable relief | 13 × 9 notch, −Y end wall | see below |

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

## Cable system

The donor routes its cable through a 10 mm trough cut clean through the
45° face, from the apex to the rim. That is gone. Instead a **round
threaded panel-mount USB-C socket** clamps into a flat back panel,
and a short jumper inside the shell feeds the module.

### The flat back

The socket does not go into the sloping 57.3° face. A round bore in the
middle of that face reads as a hole punched through a taper, and there
is no honestly flat panel for the connector to sit square on.

Instead the wedge gets a **fifth plane**. Its apex — where the 45° and
57.3° faces meet — lies *on the desk at the rear* once the stand is
sitting on its 45° face, so truncating it costs nothing: none of the
three face angles move, the silhouette keeps its proportions, and the
in-use height is unchanged at 50.98 because the display's top edge sets
that, not the apex.

Cut that fifth plane at **45°** and the new facet comes out **exactly
vertical in use** — measured off the mesh at 0.000° from vertical. That
gives a small flat back panel standing straight up off the desk, with
the socket bored square through it so the cable leaves horizontally
instead of pointing skyward.

| | |
|---|---|
| panel height | 26.00 mm, from the desk up (`back_flat_h`) |
| panel width | 74.9 mm, tapering with the hips |
| panel thickness | 2.495 mm — the same seat the flat-face version had |
| bore centre | 13 mm up the panel (`usb_h`) |
| stand depth | 55.05 mm, ~6 shorter than the untruncated wedge |

It is built as the same kind of half-space as the other four faces, so
the 2.50 mm wall falls out of the shared `inset` rather than being
maintained by hand — and `back_flat = false` puts the apex back.

Bore is Ø16.6 for an M16 × 1 barrel, nominal thread + 0.6: it runs
square through a 45° face, so its worst inside surface is a 45° overhang
and droops slightly, and 0.1 mm of radial clearance would bind on that.
`usb_bore_d` takes 12.60 for M12 or 22.60 for M22.

**Assembly order matters**: the nut lands inside the shell, so fit the
socket through the open front *before* the module goes in.

## Retention — magnets

**Brass and copper are not ferromagnetic.** A magnet glued behind those
corner inserts pulls on nothing. Nickel-plated brass is no better; the
plating is microns thick.

What works is to put steel in the loop. A **steel M3 button-head screw
into each of the module's four corner inserts**, fitted with the module
in hand before it goes anywhere near the stand — which is also the
answer to "the closed back means I can't reach them to screw it in". The
four heads are then the ferrous targets, and four Ø6 × 3 magnets in the
stand hold the module in.

The seat height is fixed by that screw: the module's corner pads land at
z 5.00, an ISO 7380 button head stands 1.65 proud, plus a 0.35 air gap →
**magnet face at z 7.00**. `ret_head_h` covers other heads, but a socket
cap (3.0 tall) would push the magnet into the 45° roof — drop `mag_l` to
2.00 if you use one.

Two constraints squeeze this feature from both sides, and the geometry
only just fits between them:

- **From above**: at the +X corners the 45° roof is the lowest. The cap
  over the magnet bore measures **0.937 mm** perpendicular to that face
  at the bore rim — the tightest wall in the part. A 3 mm magnet is the
  most that fits; a taller screw head or a longer magnet breaks through.
- **From below**: the module's back is not flat. The wall mount's z=3.25
  surface is four corner pads of ~7.9 × 7.8 (area 206.8 ≈ 4 × 50), and
  between them the back protrudes 2.25 mm deeper. So the boss footprint
  has to stay inside those pads: Ø8.4 at 3.425 / 3.30 from the walls
  reaches 7.63 / 7.50 inboard, just inside the 7.93 / 7.80 pad.

The seat sits 3.3 mm inboard of both pocket walls, so it cannot hang off
one wall without a long drooping overhang. Each pad is instead hulled
out to a foot buried in *each* wall, so its first layer is anchored at
both ends and the ~9 mm span across the corner prints as a bridge.

## The one thing still unverified

**Where the module's own USB-C connector is.** The wall mount cannot
tell us: its only opening is a 3.5 mm slot, and a USB-C plug's metal
shell alone is 8.3 × 2.5, so that slot was never meant to pass one — its
designer hardwired power instead.

So the internal cable relief (13 × 9 in the −Y end wall, `port_*`) is a
best guess at where the jumper needs to reach the board. Two outcomes:

- If the connector faces **rearward** into the cavity, set
  `port_on = false` and the shell closes up completely.
- If it faces **out of an edge**, the jumper's plug needs roughly 6 mm
  beyond that edge and the skirt only offers 2 mm of wall, so some of
  the plug body will stand outside the notch. A 90° plug minimises it.

Measure the board and this is a one-line change.

## Bill of materials

| qty | part |
|---|---|
| 4 | M3 × 5 steel button-head screws (ISO 7380) — into the module's corner inserts |
| 4 | Ø6 × 3 mm neodymium disc magnets — glued into the bosses |
| 1 | panel-mount USB-C socket, M16 × 1 threaded barrel + nut |
| 1 | short USB-C jumper, socket → module (90° plug preferred) |

## Printing

Export orientation is print orientation: rim face down on the bed. Every
outer face is ≥45°, so no supports, no brim. The pocket walls and roof
are 2.0/2.5 mm — 3 perimeters at 0.4 mm nozzle. The only bridged feature
is the underside of the four magnet bosses, ~9 mm across each corner.

Assemble in this order: panel-mount socket first (its nut is inside the
shell and only reachable through the open front), then glue the magnets
in flush with the boss undersides, then screws into the module, then
plug in the jumper and drop the module into the pocket.

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
