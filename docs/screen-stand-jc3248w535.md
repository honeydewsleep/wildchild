# Display wedge stand — Guition JC3248W535C (3.5")

All from `scad/screen_stand/stand.scad`:

| STL | what it is |
|---|---|
| `screen_stand_jc3248w535.stl` | **the standard** — back parallel to the screen, stable at both angles |
| `..._lowpoly.stl` | standard, every plan corner taken to zero — all flat facets |
| `..._soft.stl` | standard, every outer edge broken by 1.2 mm |
| `..._softer.stl` | same, broken by 3.0 mm |
| `..._lowpoly_faceted.stl` | low-poly with each side panel split into two slopes |
| `..._flat45.stl` | earlier variant, panel vertical sitting at 45° |
| `..._upright.stl` | earlier variant, panel vertical standing at 57.3° |

A re-dimensioned version of the "4.3 inch Screen Stand" wedge, rebuilt
parametrically so it fits the Guition JC3248W535C instead of the 4.3"
module. Screen sits **landscape** (module long axis horizontal), which
is the same module→wedge mapping the original uses.

```bash
./render.sh stl                       # all seven, or one at a time:
openscad -o stl/screen_stand_jc3248w535.stl \
    -D 'variant="parallel"' -D 'edges="crisp"' scad/screen_stand/stand.scad
python3 scripts/stl2bin.py stl/*.stl   # OpenSCAD writes ASCII
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
| flat back | 26.0 / 16.0 / 20.0 mm by variant | squares off the apex |
| USB-C socket | 13.60 × 5.50 cutout | copied from the 45° base STL |
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

### The flat back, and why there are three variants

The wedge's apex is the corner where the 45° and 57.3° faces meet, and
it lies *on the desk* in whichever position the stand is in. Truncating
it with a fifth plane costs none of the three face angles and none of
the silhouette's proportions — it just squares off that corner into a
flat panel for the socket.

Cut that plane **perpendicular to one of the rest faces** and the panel
comes out exactly vertical when the stand sits on that face, which is
what puts the socket square-on and its cable horizontal. But a plane
can only be perpendicular to one of them: the two rest faces are
**77.68° apart**. Hence a variant per position, plus a third that is
square to neither and works in both.

| | `flat45` | `upright` | `parallel` |
|---|---|---|---|
| cut angle | +45.00° | −32.68° | 0° |
| square to | the 45° face | the 57.3° face | neither — parallel to the screen |
| panel | 26.0 mm, vertical at 45° | 16.0 mm, vertical at 57.3° | 20.0 mm, leaning in both |
| patch sitting at 45° | 48.7 mm, margin 18.9 | 38.0 mm, margin 7.3 | 37.1 mm, margin 7.7 |
| patch standing at 57.3° | 19.1 mm, **margin −5.8** | 42.2 mm, margin 17.2 | 31.2 mm, margin 7.2 |
| socket above the desk | 9.0 at 45°, 3.6 upright | 9.0 upright, 1.5 at 45° | 7.69 in **both** |
| socket aims | horizontally at 45° | horizontally upright | −45° / −32.7°, i.e. down |
| cable | straight | straight | **90° plug** |

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

All three variants keep the display pocket, magnets, closed rim and socket
opening identical. Each stands in *both* positions; what differs is
which one the socket is usable in, since the panel lies nearly flat
against the desk in the other.

### `parallel` — the one that does both

Cutting the facet parallel to the screen is square to neither rest face,
so the panel never stands vertical. What it buys is symmetry: instead of
running across one rest face and gutting it, the cut trims both evenly.
That makes it the only one of the three comfortably stable in *both*
positions — margins 7.7 and 7.2, against `flat45`'s −5.8 standing up.

Its socket sits at the point where both positions give the same
clearance, solved rather than guessed: `d·cos(tilt₄₅) = (L−d)·cos(tilt₅₇)`
puts it 10.87 mm up a 20 mm panel, 7.69 mm above the desk either way.

**The catch is in the name.** Parallel to the screen means the socket
points directly *away* from the screen — which is downwards in both
positions, −45.0° sitting and −32.7° standing. A plug therefore reaches
only 10.9 mm (sitting) or 14.2 mm (standing) before it meets the desk.
A 90° USB-C plug clears that; a straight one does not.

Raising the socket to fix it does not work: clearing a straight ~20 mm
plug needs the socket 14 mm up, which needs a ~24 mm panel, which cuts
the margins back to ~3 and puts the tipping problem back.

### Printing the three cuts

The surface that decides this is the *inside* of the panel — a ceiling
over the cavity lying at exactly |cut angle| from horizontal:

| cut | inner ceiling | per 0.2 mm layer |
|---|---|---|
| +45° (`flat45`) | 45° | 0.20 mm step — clean |
| −32.68° (`upright`) | 32.7° | 0.31 mm step — clean |
| 0° (`parallel`) | flat → a **bridge** | 12.8 mm span — clean |
| −10° (a middle compromise) | 10° | **1.13 mm step — sags** |

All three shipped cuts are fine; it is the shallow-but-not-flat band in
between that fails, and it fails directly behind the socket where the
snap-in needs a clean 2.00 mm panel. `back_cut_a` takes any angle if you
want to explore it.

### Edge treatment

`edges` finishes the outer shell three ways. The geometry underneath is
the same in all three, and the cavity, socket cutout and magnet pockets
are subtracted *afterwards* in every case, so no fit changes.

| `edges` | what it does | tris |
|---|---|---|
| `crisp` | as designed — flat facets, plan corners at r4 | 1680 |
| `sharp` | plan corners to zero as well: nothing but flat facets on hard lines | 1420 |
| `soft` | every outer edge broken by `soft_r` = 1.2 | 3800 |
| `soft`, `soft_r = 3.0` | as far as the radius can go before the socket's flat seat gets tight | 3268 |

`soft` is not a chamfer pass. The outer shell is a convex solid, so it
is shrunk by `soft_r` on every face and a sphere of that radius is
Minkowski-summed back on — which returns each face to *exactly* its
original plane and rounds only the edges between them. The outside
dimensions therefore do not move: measured 63.095 × 95.095 × 35.254
against the standard's 63.100 × 95.100 × 35.257, the 5 µm being the
48-facet sphere.

Two details make it printable. The result is trimmed at z ≥ 0, so the
bed face stays flat and full-size and its edge stays crisp — that edge
is what the module's bezel seats against, and rounding it would have
eaten into the 1.45 mm of seat. And because every rounded edge is
convex and upward-facing, the overhang audit is unchanged across all
three: same 2000 mm², same z range, nothing new below 45°.

### Faceted side panels

`end_facet` splits each ±Y end into **two** slopes instead of one — a
near-vertical 80° flank up to a shoulder at z 24, then a hard fold to a
shallow 35° above it. It reads as a deliberate architectural break down
each side rather than the single 57.78° plane.

It has to be done as roof geometry, not as a surface treatment. There is
only 2.5 mm between the outer skin and the cavity, so cutting a facet
into the outer alone would thin or breach the wall within about 1.5 mm —
nowhere near enough to see. Instead both new planes go into the cavity
too, exactly like the other five, and the shell thickness comes out of
the shared `inset` as usual.

Costs, measured: bounding box unchanged; the flat back narrows 62.0 →
57.7 mm, still far more than the 13.6 mm socket needs; tipping margins
7.7/7.2 → 7.5/6.9. The upper 35° slope puts its inner face at 35° from
horizontal — 0.29 mm of step per 0.2 mm layer, the same order as the
32.7° panel ceiling the `upright` variant already prints.

One OpenSCAD trap worth recording: the alternative planes were first
written as `if (...) { A; B; } else { C; D; }` inside `intersection()`.
Braces make a **group**, and a group inside `intersection()` is the
*union* of its children — so the planes silently stopped cutting and the
flat back came out full width. One plane per `if`, no braces.

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

---

# Cheap Yellow Display forks — 2.8" and 4.0"

Same source file (`display = "cyd28" | "cyd40"`), same wedge, same soft
r3.0 finish, same `parallel` flat back. What changes is what is being
held. The Guition is a finished module: it has its own bezel, so the
stand is a tray and the module's frame lands on the rim. A CYD is a bare
PCB with the LCD bonded to its front — nothing to land on a rim, nothing
to hold it in — so each of these is a **two-part print**: the tub, plus a
face piece that provides the bezel and traps the board.

## Board data

Every number is off the manufacturer's own LCM OUTLINE drawing, not
measured off a photo and not inferred from the diagonal:

- 2.8" ESP32-2432S028R = QDtech **E32R28T**, rev V1.0, 2024-08-31
- 4.0" ESP32-4832S040 = QDtech **E32R40T**, rev V1.0, 2025-04-15

| | 2.8" | 4.0" |
|---|---|---|
| PCB | 50.00 × 86.00 × 1.60 | 60.88 × 111.11 × 1.60 |
| hole grid, 4 × Ø3.20 | 42.00 × 78.00 | 53.28 × 104.11 |
| LCD glass (BL) | 50.00 × 69.20 | 60.88 × 94.57 |
| visible window (RTP VA) | 45.20 × 59.45 | 56.88 × 85.22 |
| active area (LCD AA) | 43.20 × 57.60 | 55.68 × 83.52 |
| front stack / max SMD on back | 5.60 / 5.09 | 5.65 / 5.09 |
| display offset from PCB centre | 2.90 | 2.875 |

Across the short axis everything on these boards is centred — hole grid,
glass, visible area, active area all share the PCB centreline. Along the
long axis only the **hole grid and the glass** are centred; the visible
and active areas are not. They sit toward the ESP32 end, because the
bottom of the board has to carry the LCD's own flex tail as well as the
USB-C and the two buttons. That single offset is the whole reason the
bezel problem is interesting.

The 2.8" numbers were confirmed independently. The user supplied
`Front_Panel__Symmetrical_Bezel.stl`, a commercial face piece cut for
this board; tearing it down gives a screw grid of 78.4 × 42.0 against the
drawing's 78.00 × 42.00, and its window centre sits 2.90 mm off its screw
grid centre — exactly the drawing's active-area offset, arrived at from a
completely different direction.

## Minimum symmetrical bezel

"Symmetrical" here means opposite pairs match — left = right, top =
bottom — each pair squeezed to its own minimum. Not one uniform frame all
round: the long axis would force *every* edge out to ~18 mm, and the
stand would grow with it.

Centre the frame on the **screen**, not on the board. Then only two
things set the bezel, and neither is a free choice:

- **inner edge** — the aperture may not go inside the visible area or it
  crops what the user can see. So aperture = VA + 2 × `ap_clr` (0.20 per
  side) and no smaller.
- **outer edge** — the frame still has to cover the PCB. Centred on the
  screen, the board reaches `pcb/2 + offset` on its far side, so the
  half-width is that plus `pcb_clr` (0.25) plus `wall` (2.00).

Everything between the two is bezel. It falls out of those numbers;
there is no bezel-width parameter to tune, which is the point.

| | 2.8" | 4.0" |
|---|---|---|
| outer | 54.50 × 96.30 | 65.38 × 121.36 |
| aperture | 45.60 × 59.85 | 57.28 × 85.62 |
| **bezel across / along** | **4.45 / 18.23** | **4.05 / 17.87** |
| glass overlap, thinnest edge | 2.20 / 1.78 | 1.80 / 1.60 |

For scale, the commercial 2.8" panel is 100.0 × 58.4 with a 61.2 × 45.6
window — bezels of 19.4 and 6.4. This is 1.2 mm thinner per side along
and 1.9 mm thinner across, and it gets there by shrinking the *outer*
rather than by opening the window wider.

The along-axis figure is ~18 mm on both boards and cannot be improved
without giving something up. It is not slack: it is the board's own tail
— ESP32, USB-C, buttons — being covered on one side, and mirrored on the
other so the frame stays symmetric. Options if it ever matters: let the
tail poke out through a slot in the end wall (thin frame, visible board),
or accept an asymmetric frame.

## The face piece is a slice, not a separate object

The plate is not modelled as its own part and bolted on. The outer solid
is extruded from `z = -face_t` instead of `z = 0` and then cut at
`z = 0`. So the plate carries the identical rounded-rect outline and the
identical Minkowski soft edge as the tub, and the parting line lands
flush all the way round by construction. Drawing it separately would mean
reproducing a Minkowski result by hand.

The `z >= z_front` trim that keeps the bed face flat now applies to the
plate's front rather than the tub's rim. That is deliberate: the screen
face comes out flat and crisp, which is what you want framing a window,
and every other edge on the assembly stays soft.

## The assembly stack

Measured from the plate's back face at `z = 0`:

| z | what |
|---|---|
| 0 → `glass_h` (4.00 / 4.05) | the LCD standing proud of the PCB |
| → `stack_t` (5.60 / 5.65) | the PCB |
| `stack_t` → +6.00 | the screw post |

Away from the glass the plate is 4 mm above the board, so the four
collars on its back carry that gap: each reaches down to the PCB front
face and holds a magnet. The plate's own back would otherwise land on
the **glass** — on these boards the glass runs the full board width, so
there is no PCB shoulder for it to press on — and the collars stand
0.05 mm proud (`col_bear`) specifically so they touch the PCB first and
the glass carries no clamping load at all.

The posts have the same problem the magnet bosses had on the Guition:
the seat sits ~4 mm inboard of the pocket wall and everything below it
is PCB, so a post cannot grow up from the floor. Same fix — hull the pad
out to a foot in *each* wall, so the span is a bridge anchored at both
ends rather than a cantilever, and its underside at `z = stack_t` prints
as a flat bridge instead of a sagging ramp.

## Magnetic attachment — nothing breaks the front face

The face piece has no fasteners through it. Four magnet pairs face each
other **through the PCB**: one in each collar on the plate's back, one in
each post below, coaxial with the board's own mounting holes. FR4 is not
magnetic and the Ø3.20 hole sits directly between them, so the only real
separation is the board's 1.60 mm. The same pull clamps the board.

Where they can go is not a free choice. The only clear band on the front
of these boards is between the glass edge and the PCB edge — 8.40 mm on
the 2.8", 8.27 mm on the 4.0" — and that is exactly where the maker put
the mounting holes, because it is the only place left. Checked against
the glass edge, the PCB edge and the pocket wall at all four corners on
both boards, the collar caps out at **Ø7.0**, which is why these take
**Ø5 × 3** magnets rather than the Ø6 × 3 the Guition uses. The pockets
are blind: 1 mm of collar plus the full 2.40 mm of plate stays in front
of each one, so the front face is unbroken apart from the window.

Fit all eight the same way round in each part, or the pairs will repel.

Magnets alone would let the plate wander before they snapped it into
place, and because the plate's silhouette *is* the tub's silhouette, any
offset shows on the outline. So the plate's back carries a registration
lip that drops into the pocket at each ±Y end — the two places the glass
leaves clear — running the full pocket width, so it picks up the ±X walls
as well and locates x, y and rotation together. Past the board's far edge
the lip deepens into a stop, so the board cannot drift toward the slack
+Y end while you are assembling it.

`skirt_h` goes 9.00 → 12.00 for these. It is driven, not chosen:
`stack_t + smd_h` = 10.69 to clear the components on the back of the
board, and `stack_t + post_h` = 11.60 to contain the posts.

## Power — the same flat-back socket as the Guition

Same snap-in panel-mount socket, same 13.60 × 5.50 opening with its
1.20 corner radius, square through the flat back, on the same
`back_pan_t` 2.00 panel. Nothing about the cable system differs between
the three displays, which is the point — one type of chassis port across
the whole family.

The end wall is unbroken. `port_on` still exists and still opens onto the
board's own USB-C on the −Y edge if you would rather plug straight in
than run an internal lead, but it is off everywhere.

**One thing to know before wiring.** The socket needs its inner end
connected to the board, and on a CYD the board's USB-C is on that −Y
edge with the pocket wall **0.25 mm** in front of it. There is no room to
insert a plug there — a USB-C plug needs something like 8 mm of axial
clearance even at right angles. That gap is the direct cost of the thin
bezel: the board's tail is hard against the wall precisely because the
frame is centred on the screen rather than the board.

So the internal connection is wires, not a plug: take 5 V and GND from
the socket to the board's 5 V/GND pins (the UART connector carries both).
The roof cavity above the board is wide open, so the run itself is easy —
it is only the final axial insertion that has nowhere to go.

If you would rather plug in, the fix is to grow both ±Y ends by ~9 mm,
which takes the along-axis bezel from 18.23 to about 27 and the 2.8"
stand from 96.30 to 114.30 long. It has to be both ends, not just the
one that needs it, or the frame stops being symmetric.

## Verification

Five renders, **0 warnings** each. Everything below is read off the
meshes, not eyeballed.

- **Guition regression** — the shipped 3.5" part re-rendered after all of
  this: 3268 tris, 1634 vertices, max coordinate deviation **0.001 mm**
  against the committed STL. The fork changed nothing underneath it.
- **Outer** — 54.487 × 96.287 and 65.367 × 121.347 against targets of
  54.50 × 96.30 and 65.38 × 121.36. The −0.013 is the soft edge's facet
  approximation, the same residual the Guition part carries. Face pieces
  come out 7.800 and 7.850 deep (plate, plus the stop section of the
  lip) on the same outline.
- **Face piece** — window open on axis; material confirmed present
  immediately outside the aperture on both axes.
- **Magnet pockets** — probed 0.3 mm off the mesh seam, since on-seam
  probes return meaningless odd crossing counts. A ray fired at the
  front face along each of the four magnet axes hits solid material, so
  the pockets really are blind and the face really is unbroken; a ray
  from inside each collar and each post finds its pocket floor.
- **Socket** — the opening sections at exactly 13.600 × 5.500 mid-panel
  on both boards, the same as the Guition's. The flat back around it
  measures 21.585 × 70.965 (2.8") and 21.585 × 87.671 (4.0"), so the
  smallest margin from the opening to a facet edge is ~7 mm. A ray down
  the bore axis passes straight through; 9 mm to the side it meets the
  panel. The −Y end wall reads solid at the height the old cable port
  used to be.
- **Interference** — the tub and the face piece, booleaned together in
  their assembled positions, intersect in nothing. The lip, the stop and
  the four collars all clear the pocket.
- **USB port** — open through the −Y wall at the connector height, solid
  wall 6 mm below it.
- **Tipping**, both rest positions, plastic + board mass:

| | 45° rest | 57.3° rest |
|---|---|---|
| 2.8" assembled (64 g) | 16.7 / 11.0 | 11.4 / 11.9 |
| 4.0" assembled (93 g) | 21.9 / 15.2 | 15.0 / 16.1 |

Both are comfortably stable in both positions, and better than the
Guition's 28.4/6.7 and 6.0/23.5 — the face piece and the board put mass
low and forward, which centres the load over the contact patch instead
of hanging it off one end.

## Bill of materials, per stand

- 8 × Ø5 × 3 mm disc magnet — four into the face piece's collars, four
  into the tub's posts, all the same way round in each part so the pairs
  attract. Note these are **Ø5**, not the Ø6 × 3 the Guition build uses.
- 1 × snap-in panel-mount USB-C socket, 13.60 × 5.50 — the same part the
  Guition build uses
- the board itself; no screws, no inserts

Assembly: magnets into all eight pockets, board down onto the posts, face
piece on. The lip drops into the pocket and the magnets pull the plate
down until the collars land on the PCB.

Print both parts as exported: the tub on its rim face, the face piece on
its window face. Both are flat on the bed and need no supports.

---

# 5.0" Guition JC8048W550C

Third architecture in the family. The Guition 3.5" is a finished module
that drops into a tray; the CYDs are bare PCBs held by magnets through
their own mounting holes; this one is a bare PCB with **no mounting
holes at all**, and a glass that leaves only a 1.46 mm shoulder on the
long sides — nowhere to put a magnet collar. So it is snapped together
instead, and there are two builds of the snap to compare.

## Board data, and where it came from

There is no manufacturer drawing for this board and Guition publish only
the diagonal. What there is instead is a case the user confirms fits the
board perfectly — "5IN Display Holder", MakerWorld 981775 — so its front
geometry is copied verbatim rather than re-derived:

| feature | measured off the reference |
|---|---|
| board pocket | 123.952 × 81.280 |
| window | 121.032 × 76.378, square corners |
| seat, front face to board front | 5.283 |
| board + rear components | 6.35 |

That window back-solves. Subtract it from the pocket and the ledge is
1.460 per side on the long axis, 2.451 on the short. The standard 5.0"
800×480 panel outline of 120.70 × 75.80 leaves exactly that shoulder on
a ~123.5 × 80.8 PCB — agreement to a tenth, from a direction the case
designer had no reason to arrange. Active area is 108.00 × 64.80.

## The window is the glass, not the image

Unlike the CYDs, the aperture here is the **glass**, and that is
deliberate on three counts:

- It is the thinnest plastic bezel available. A smaller aperture would
  only cover screen, and the bezel is measured from the aperture edge
  outward — opening it up makes the frame narrower, not wider.
- The plate then lands on the PCB shoulder exactly as the reference
  does, instead of clamping the glass.
- It sidesteps the one number no source gives: where the active area
  sits *inside* the glass. On both CYDs the glass was centred while the
  image inside it was not, by 2.9 mm. Nothing available here could have
  settled that either way, and a wrong guess is a visibly lopsided
  screen.

## Two snaps, because the wall is the whole argument

The bezel is `ledge + wall`, and the ledge is fixed by the board. So the
wall is the only lever there is, and the two builds differ in whether
the joint has to live inside it.

**A — `retain="snap"`.** The plate's outer edge continues as a skirt
that drops inside the tub wall. That wall has to hold a standing wall,
a clearance and the skirt, so it goes 2.00 → 3.00.

**B — `retain="cap"`.** The user's suggestion, and the better one: move
the joint *behind* the board, where there is room to spare. The plate
becomes a deep cap that carries the pocket itself — the board goes into
the plate from behind and lands on its front ledge — and the tub's lip
stands up inside the cap. The bead is on the plate's bore and the groove
is in the lip, the reverse of A. Because the overlap is now inboard of
the pocket rather than inside the wall, the wall stays 2.00.

| | A `snap` | B `cap` |
|---|---|---|
| wall | 3.00 | 2.00 |
| outer | 87.280 × 129.952 | 85.280 × 127.952 |
| **bezel across / along** | **5.45 / 4.46** | **4.45 / 3.46** |
| parting line | at the screen face | 8.00 mm behind it |
| board backstop | four corner pads | the tub's lip |

B is a millimetre thinner on every edge — the thinnest frame in the
whole family, against the 3.5"'s 2.00 wall on a module that brought its
own bezel.

**B's cost, and it is real.** The tub prints lip-down, so its outer wall
appears all at once at the parting plane, leaving an annular overhang of
`wall + cap_clr` = 2.25 mm right at the visible seam. A has the same
transition but only 1.50 mm of it, and A's seam is at the screen face
where the plate's edge covers it. Which of those matters more is a
question about how they look in the hand, which is why both are built.

## Retention numbers

Bead 0.45 proud against 0.30 clearance in A, 0.25 in B — 0.15 and 0.20
of bite, the same order as the diffuser snaps this repo already has
test-printed. In both the bead's 45° ramp faces the direction its mate
arrives from, and the flat retaining face points back toward the screen.

That direction is not cosmetic. In A the tub prints rim-down, so the
ramp is also the downward-facing side; putting it the other way round
would leave an unsupported ledge exactly where the snap needs to be
crisp.

A thumbnail catch sits in the plate's −X edge at the joint — that edge
is against the desk in both rest positions, so it is out of sight.

## Verification

Six renders, **0 warnings** each.

- **Regressions** — the Guition and the CYD face piece both re-render to
  within 0.001 mm of their committed STLs, so none of this disturbed
  what came before.
- **Cap engagement, off the mesh** — the plate's bore reads 81.280 ×
  123.952 below the bead and 80.380 × 123.052 through it; the lip reads
  80.780 outer with a groove floor at 79.880. The bead therefore sits
  inside the groove with the lip flexing 0.20 per side to get there.
- **Snap engagement** — at z = 2.50 the tub's bead measures 84.980,
  which is 0.35 of its 0.45 ramp, exactly on the slope. The plate's
  skirt bore reads 84.880 and opens to 85.780 through the groove.
- **Interference** — both builds intersect their own face piece in
  nothing. A's first attempt did not: the seat pads' wall feet reached
  42.89 where the skirt travels to 42.44, a 0.45 mm clash over exactly
  the z range the intersection reported. The pads are now clamped to the
  standing wall's footprint rather than to `outer_solid()`.

## Bill of materials

Nothing. No screws, no magnets, no inserts — the board is a friction fit
and the plate snaps on. The flat-back panel-mount socket is unchanged
from the rest of the family.

The one feature with no proven original is A's board backstop: the
reference case has none, because it clamps the board with a separate
back plate that a closed wedge cannot have. Four corner pads bridge the
pocket corners at the board's back plane. Corners are the safest place
to touch a populated board, but they are unverified against this board's
rear components. B does not need them — its lip does that job.
