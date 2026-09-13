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

## Next: v2

Same pen with the click pen's diamond-knurl grip (the user's favourite
grip). The knurl was measured; parameters are in
`docs/reference-measurements.md` under *Click pen grip*.
