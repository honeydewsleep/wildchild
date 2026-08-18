# Display wedge stand — Guition JC3248W535C (3.5")

`scad/screen_stand/stand.scad` →
`stl/screen_stand_jc3248w535.stl` (sits at 45°) and
`stl/screen_stand_jc3248w535_upright.stl` (stands at 57.3°)

A re-dimensioned version of the "4.3 inch Screen Stand" wedge, rebuilt
parametrically so it fits the Guition JC3248W535C instead of the 4.3"
module. Screen sits **landscape** (module long axis horizontal), which
is the same module→wedge mapping the original uses.

```bash
openscad -o stl/screen_stand_jc3248w535.stl \
    -D 'variant="flat45"'  scad/screen_stand/stand.scad
openscad -o stl/screen_stand_jc3248w535_upright.stl \
    -D 'variant="upright"' scad/screen_stand/stand.scad
python3 scripts/stl2bin.py stl/*.stl
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
| height | 50.98 sitting at 45° | falls out of the angles |
| display pocket | 59.10 × 91.10, corner r 2.0, 9.00 deep | wall mount pocket |
| rim wall | 2.00 | wall mount |
| roof | 2.500 | original |
| face angles | 45.00° / 57.32° / 57.78° | original, held constant |
| flat back | 26.0 mm (`flat45`) / 16.0 mm (`upright`) | squares off the apex |
| USB-C socket | 13.60 × 5.50 cutout, 8.95 up the flat back | copied from the 45° base STL |
| magnet bosses | 4 × Ø6.2 × 3.0, seat z 7.00 | corner insert grid |

Angles are held rather than scaled: they are what the stand *is*, and
holding them keeps both rest positions identical to the original. The
height therefore drops only 51.29 → 47.44 before the flat back
truncates the apex, while the plan shrinks more.

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
45° face, from the apex to the rim. That is gone. Instead a
**rectangular snap-in panel-mount USB-C socket** sits in a flat back
panel, and a short jumper inside the shell feeds the module.

### The flat back, and why there are two variants

The wedge's apex is the corner where the 45° and 57.3° faces meet, and
it lies *on the desk* in whichever position the stand is in. Truncating
it with a fifth plane costs none of the three face angles and none of
the silhouette's proportions — it just squares off that corner into a
flat panel for the socket.

Cut that plane **perpendicular to one of the rest faces** and the panel
comes out exactly vertical when the stand sits on that face, which is
what puts the socket square-on and its cable horizontal. But a plane
can only be perpendicular to one of them: the two rest faces are
**77.68° apart**. Hence a variant per position.

| | `flat45` | `upright` |
|---|---|---|
| cut angle | 90 − `ang_front` = +45.00° | `ang_back` − 90 = −32.68° |
| perpendicular to | the 45° face | the 57.3° face |
| panel | 26.0 mm, vertical at 45° | 16.0 mm, vertical at 57.3° |
| patch sitting at 45° | 48.7 mm, margin 18.9 | 38.0 mm, margin 7.3 |
| patch standing at 57.3° | 19.1 mm, **margin −5.8** | 42.2 mm, margin 17.2 |
| socket above the desk | 9.0 mm at 45°, 3.6 upright | 9.0 mm upright, 1.5 at 45° |

Margins are the centre of mass to the nearer edge of the contact patch,
computed from each mesh's own volume centroid. They are for the bare
shell; the module's mass sits forward of the shell's centroid in both
positions, so it only improves them.

That −5.8 is the tipping the `flat45` print shows: cutting perpendicular
to the *front* face runs the plane straight across the back one, taking
it from 45.7 mm down to 19.1 and leaving the centre of mass 5.8 mm
behind the patch. Cutting perpendicular to the *back* face instead runs
nearly parallel to it, so it barely shortens it — 42.2 mm — while doing
the same trimming job on the front face that `flat45` did on the back.

Both variants keep the display pocket, magnets, closed rim and socket
opening identical. Each stands in *both* positions; what differs is
which one the socket is usable in, since the panel lies nearly flat
against the desk in the other.

**Why not one part for both.** A middle cut angle looks tempting and it
does make the socket usable in both positions (~5.5 mm of clearance
each). It fails on printing instead. The inside of the panel is a
ceiling over the cavity at exactly |cut angle| from horizontal, so a
0.2 mm layer steps out `0.2/tan(angle)`:

| cut | inner ceiling | step per layer |
|---|---|---|
| ±45° | 45° | 0.20 mm — prints clean |
| −32.68° | 32.7° | 0.31 mm — prints clean |
| −10° (a middle compromise) | 10° | **1.13 mm — sags** |

Both shipped angles happen to sit above 32°. A compromise angle lands
in the sagging band, and that sag is directly behind the socket, where
the snap-in needs a clean 2.00 mm panel. `variant` takes any angle via
`back_cut_a` if you want to try it anyway.

### The socket opening

Not a threaded barrel — a **rectangular snap-in socket**, with the
opening copied from `Base__45_Degree__Symmetrical_Bezel.stl`, which is
dimensioned for the sockets recommended for that model:

| | measured | ours |
|---|---|---|
| opening | 13.600 × 5.500, corner r 1.200 | identical |
| centre above the floor | 8.950 | 8.950 |
| profile through the wall | constant at three depths — a straight extrusion, no draft | same |
| panel thickness | 2.00 | 2.00 (`back_pan_t`) |

The panel is the one thing that is *not* simply inherited. Everywhere
else the shell is 2.50 mm, but a snap-in socket grips a specific panel
thickness rather than clamping any thickness the way a nut does, so the
flat back alone is thinned to the donor's 2.00 mm. That is why the
fifth plane takes `back_pan_t` instead of `roof_t` for its inset.

The cutout's lower wall is a 45° overhang — right at the printable
limit, and only 5.5 mm of it — so it needs no support.

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

## The shell is closed

Earlier revisions carried a 13 × 9 relief in the −Y end wall so a jumper
could reach a connector on the module's edge. It is off: the module is
fed from the socket in the flat back, nothing needs to pass through the
rim, and the user confirmed they will not plug in from that side. The
skirt is now unbroken the whole way round — checked at both ends.

`port_on = true` brings it back if a jumper ever has to reach an edge
connector. Worth knowing if you do: the plug wants roughly 6 mm beyond
the module's edge and the skirt only offers 2 mm of wall, so part of the
plug body would stand outside the notch. A 90° plug minimises it.

## Bill of materials

| qty | part |
|---|---|
| 4 | M3 × 5 steel button-head screws (ISO 7380) — into the module's corner inserts |
| 4 | Ø6 × 3 mm neodymium disc magnets — glued into the bosses |
| 1 | panel-mount USB-C socket, rectangular snap-in for a 13.6 × 5.5 opening in a 2.0 mm panel |
| 1 | short USB-C jumper, socket → module (90° plug preferred) |

## Printing

Export orientation is print orientation: rim face down on the bed. Every
outer face is ≥45°, so no supports, no brim. The pocket walls and roof
are 2.0/2.5 mm — 3 perimeters at 0.4 mm nozzle. The only bridged feature
is the underside of the four magnet bosses, ~9 mm across each corner.
The socket cutout's lower wall is a 45° overhang, right at the limit.

Print `screen_stand_jc3248w535.stl` for the 45° position or
`..._upright.stl` for the 57.3° one — they are otherwise identical, so
printing both gives you the display at either angle.

Assemble in this order: snap the socket into the flat back, glue the
magnets in flush with the boss undersides, screw the four steel screws
into the module's corner inserts, then plug in the jumper and drop the
module into the pocket. The shell has no other opening, so anything
that has to go inside goes in through the open front first.

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
