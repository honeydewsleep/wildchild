# Bolt-Action Pen — hex "pencil" remix (v1)

A parametric OpenSCAD remix of the "Bolt Action Pen" (`Bolt Body.stl` +
`Bolt Base.stl` in
`Google Drive › The Rabbit Hole › 3D Print Files › Pens › Favorites › Bolt Action Pen`).

**What changed (v1):**

- **Faceted body like a pencil.** The Ø11.52 round barrel is now a
  rounded hexagon, 10.4 mm across flats (11.6 mm across the softened
  corners). In the hand it is noticeably slimmer than the original; the
  wall over the plunger bore is 1.0 mm at the flats (original: 1.56 mm).
- **Straight taper tip** borrowed from the click pen: a 15.2° half-angle
  cone (the click pen's grip taper), which "sharpens" the hex prism —
  the flats end in the same scalloped edge a sharpened pencil has.
- **Interior is identical to the original**, to the hundredth of a
  millimetre: Ø8.40 plunger bore to z=53.2, Ø6.88 refill bore to
  z=113.7, Ø5.52 spring seat, Ø3.72 refill-cone bore, Ø2.92 exit hole,
  124.3 mm overall. Refill, spring and plunger from the original all
  drop in.
- **Bolt track reproduced from the original mesh** — the main slot
  (3.3 mm wide at the bore, walls leaning outward ~12°, rounded lower
  end, big fillet into the flat top), the leaning hook/ramp at the top of
  the slot, and the separate rounded window 76° away. Rebuilt as lofted
  through-cuts so they pass through whatever wall thickness the hex has.
- **Plunger** (`Bolt Base`) is re-modelled parametrically so the repo is
  self-contained; dimensions are unchanged (Ø7.62 × 20, Ø2.75 cross pin
  hole 9.5 mm from the back face, Ø6.0 × 8.1 refill socket).

## Files

```
pen/
  scad/params.scad     every dimension (interior = reference, exterior = remix)
  scad/body.scad       the hex body  (part="body"; part="body_round" = round exterior + new tip, for A/B)
  scad/plunger.scad    the plunger
  scad/fit_check.scad  boolean checks (see render.sh)
  stl/body_hex.stl     print this
  stl/body_hex_slot075.stl   same body, bolt track 0.75 mm closer to the tip (track_dz = 0.75)
  stl/plunger.stl      print this (or reuse an original Bolt Base)
  docs/reference-measurements.md   what was measured on the original meshes + the click pen
  render.sh            stl | check | png
```

## Printing

- Body: stand it on the back rim (z = 0 as exported), tip up. The 15.2°
  taper needs no support; the two internal bore steps are 0.7-0.8 mm
  ledges and bridge fine, exactly like the original.
- Plunger: stand on the back face, socket up.
- 0.4 nozzle, 2-3 perimeters. The flats are 1.0 mm thick, so use 3
  perimeters at 0.4-0.45 line width or 2 perimeters at 0.5.
- Pin: as on the original — a ~10.5 mm length of 2.85 mm filament (or a
  Ø2.5-2.75 pin) pressed through the plunger's cross hole, inserted
  through the main slot with the plunger in the bore.

## Knobs you may want to turn (`scad/params.scad`)

| parameter       | default | effect |
|-----------------|--------:|--------|
| `hex_af`        | 10.4    | across-flats. Wall at the flats = (hex_af − 8.4)/2. 10.2 → 0.9 mm wall, 11.0 → 1.3 mm |
| `hex_corner_r`  | 1.2     | corner softness. 0.5 = crisp pencil, 1.5 = across-corners drops to 11.54 (= original OD) |
| `hex_clock`     | 270     | which way the flats face relative to the bolt slot (270 = slot centred on a flat) |
| `tip_half_angle`| 15.2    | taper angle (click pen value) |
| `tip_r_exit`    | 2.20    | outer radius at the very tip (0.74 mm wall around the exit hole) |
| `back_chamfer`  | 0.5     | chamfer on the back rim |
| `track_dz`      | 0       | shifts the whole bolt track (slot, hook, window) toward the tip. `body_hex_slot075.stl` uses 0.75 |

Across-corners for the default is 11.64 mm; the original barrel was
Ø11.52. If you want the whole thing inside the original envelope, set
`hex_corner_r = 1.5` (11.54) or `hex_af = 10.2`.

Going thinner still would mean shortening the Ø8.40 section of the bore
(the plunger only travels ~11 mm in it; the rest could be Ø6.88 and the
hex could drop to ~9 mm across flats there). That changes the interior,
so it was deliberately *not* done in v1.

## Verification (done on the exported mesh, not by eye)

Measured on `stl/body_hex.stl` against the original `Bolt Body.stl` by
radial ray-casting:

- Interior radius, every 0.5 mm along the axis at 24 angles: worst
  deviation **0.041 mm** (on the tiny 60° cone at z 116.8; everywhere
  else < 0.01).
- Bolt track at the bore surface (where the pin rides), every 0.1 mm of
  height: slot/hook/window edges within **±0.18 mm** of the original,
  mostly within 0.05. The original also has two ~0.2 mm hairline slits
  around the wall island between window and hook (CAD leftovers); those
  are not reproduced.
- Exterior: 10.40 across flats, 11.64 across corners, taper r = 2.28 at
  z 124 (2.2 + 0.3 × tan 15.2°).
- `render.sh check`: plunger-in-bore clearance EMPTY, pin passes the
  slot EMPTY, pin engages the plunger hole NON-empty. All pass, zero
  OpenSCAD warnings.

## Click pen: slim upper housing (`stl/click_housing_slim.stl`) + clip

The click pen's hex upper housing re-shaped so the knurled grip flows
into it. `scad/click_housing_slim.scad` unions/intersects the original
mesh (`ref/Pen_Upper_Housing.stl`) with a new envelope, so bore, thread,
the two long slots and the click-mechanism cam ramps are the original
(verified: inner surface within 0.0004 mm).

| z from the front | exterior |
|---|---|
| 0 | round Ø11.0, = the grip's knurl crests: no step at the joint in any direction. (Grip and housing are threaded, so their rotation is not indexed; a round joint face is the only one that always lines up.) |
| 0 → 10 | smooth blend, circle → rounded hexagon 10.4 across flats / 11.64 across corners |
| 10 → 70 | hexagon grows to 11.0 across flats, 0.3 mm per side over 60 mm (0.3°, invisible) |
| 70 → 85.5 | 11.0 across flats, corners rounded r 1.27. Cannot be smaller: the click cam ramps inside reach r 5.08 and leave ~0.4 mm of wall under the flats already |

Wall at the flats over the Ø9.0 bore: 0.70 mm at the front, 1.0 mm at
the rear. Print with 0.4 nozzle and 0.35 mm line width (2 perimeters).

The knurled grip is unchanged. The clip (`stl/click_clip_slim.stl`,
`scad/click_clip_slim.scad`) keeps the original arm but its ring is a
0.9 mm shell around the housing's blend surface with 0.15 mm clearance,
so it seats in the same place as before (first 6 mm) and its arm lands
over a flat. The clip tip now hovers ~0.15 mm above the flat instead of
touching it; if it holds thin pockets too loosely, shave `clip_clr`.

## v2: two-piece bolt pen (`stl/v2_grip.stl` + `stl/v2_barrel.stl` / `stl/v2_barrel_window.stl`)

The bolt pen rebuilt in the click pen's silhouette: a knurled round grip
that screws into a hex barrel. Same refill, spring and plunger as v1
(reuse `stl/plunger.stl` or an original Bolt Base).

**Grip** (`scad/v2_grip.scad`, prints standing on its thread end, tip up)
- 15.2° straight taper tip, then the click pen's diamond knurl: Ø10
  valleys / Ø11 crests, 30 + 30 V-grooves 0.5 deep, 11.8° helix, from
  10.6 to 45.5 mm from the tip — the grooves run out into the taper
  exactly like the original grip.
- Interior = the v1 bolt body's tip interior, verbatim: Ø2.92 exit,
  Ø3.72 refill-cone bore, Ø5.52 spring seat, Ø6.88 refill bore. Ø6.6
  under the thread (the click pen uses Ø6.5 there; the refill passes).
- Male thread: root Ø8.0, depth 0.6, pitch 1.5, 7.5 mm (5 turns), 45°
  printable flanks, tapered start.

**Barrel** (`scad/v2_barrel.scad`, prints on its sealed back face)
- Sealed back: 1.5 mm wall, perfectly round Ø10 bed face with a 45°
  chamfer up into the 10.4 AF / 11.64 AC rounded hex. Insignia: either
  skip the first layer of a graphic in the slicer, or set `v2_insignia`
  to an SVG file name in `scad/` and it is cut 0.2 mm into the face.
- Bolt track identical to v1 (same distances from the back face).
- Front: round Ø11 neck (= knurl crest, so the joint has no step and
  needs no clocking) 8 mm long carrying the female thread, blended into
  the hex over the next 10 mm.
- Bore Ø8.4 all the way to the thread: the plunger goes in from the
  FRONT (drop it in, push the pin through the main slot), then the grip
  screws on. That is what makes a sealed back possible.
- `barrel_window`: two 3.5 × 30 mm ink windows on opposite flats
  (90° and 270°, 30–60 mm from the back) to see the refill.
- Overall length 125.05: v1's 124.3 plus `v2_stretch = 0.75` between
  the tip and the bolt track (v1 was 0.5–1 mm short there).

**Assembly**: refill + spring into the grip; plunger into the barrel
from the front, pin through the main slot into the plunger; screw the
grip on until its shoulder meets the barrel face.

**Verification** (mesh-level, exported STLs): grip interior vs the v1
reference tip interior within 0.031 mm; barrel bolt track at the bore
surface 1.26 % of cells differ from the original (same as v1, i.e. the
leaning-ramp region); thread fit checks pass (male-in-female clearance
EMPTY, engagement NON-empty, plunger passes the female thread EMPTY);
back wall solid; zero OpenSCAD warnings.

## Next
- Test-print v2; if the thread is tight or loose, change `j_clr`
  (validated 0.30 from the lamp threads is the default).
