# Energy Ring Remix — WLED Notification Light

A fully parametric OpenSCAD rebuild of the
[ENERGY RING (ESP32 + WLED)](https://makerworld.com/en/models/2045449-energy-ring-esp32-wled)
desk lamp by DSL Design, with three revisions for use as a fleet of
email/notification lights:

1. **The bottom plate screws onto the base** (coarse single-start thread,
   ~1.4 turns) — no more leaving the bottom plate behind on the desk. The
   cable notches in the plate and base line up when fully tightened, and
   the ESP32 rides on the plate itself, so unscrewing it brings the board
   out for easy access.
2. **Battery base options**: screw-on tubs sized for common purchased AA
   battery boxes — 4×AA as a "cube" (two 2×AA boxes stacked), 4×AA flat
   (four in a row), and an 8×AA double-layer for powering 12 V strips.
   Batteries load through a screwed door on the underside, so the tub
   never has to come off (and no wires get twisted) for a battery change.
3. **Double-sided ring**: the LED strip mounts around the inside of the
   outer rim firing inward, and translucent diffusers on BOTH the front
   and back faces glow with the light color.

> **Note on the original model:** the MakerWorld files can't be fetched
> programmatically (login + bot protection), so this is a ground-up
> parametric remix rather than an edit of the original meshes. Everything
> is driven from `scad/params.scad` — if you drop the original STL/3MF
> into this repo, dimensions can be re-matched to it exactly.

## What to print

| Configuration | Parts |
|---|---|
| USB powered (aligned split notch) | `base.stl`, `bottom_plate.stl`, 2× `ring_half.stl`, 2× `ring_diffuser.stl` |
| USB powered (zero-alignment option) | `base_wallhole.stl`, `bottom_plate_plain.stl`, + ring parts |
| 4×AA battery (cube boxes) | `base.stl`, `battery_tub_4aa_cube.stl`, `battery_door_cube.stl`, + ring parts |
| 4×AA battery (flat holder) | `base.stl`, `battery_tub_4aa_flat.stl`, `battery_door_flat.stl`, + ring parts |
| 8×AA / 12 V | `base.stl`, `battery_tub_8aa_flat.stl`, `battery_door_flat.stl`, + ring parts |
| Thread calibration | `thread_test_collar.stl` (bottom 12 mm of the base only) |

Print the two `ring_half.stl` copies in your opaque color (white interior
diffuses best) and the two `ring_diffuser.stl` copies in translucent/natural
filament. For a **single-sided** ring, print one diffuser translucent and
one in opaque white — same parts.

All STLs are exported print-ready (no supports needed):

- `base*.stl` prints inverted (as exported) — threads and notch face up.
- Plates/tubs print desk-face down — threads face up.
- Ring halves print face down; diffusers and doors print flat.
- The battery tub ceiling bridges over the pocket (internal, cosmetic only).

**Suggested settings:** 0.2 mm layers, 3 walls, 15 % infill. PETG or PLA.

## Screw-on plate: how the notch alignment works

The thread is single-start, so the fully-tightened plate always stops at
the same rotation. In CAD, the notches align exactly at seat; first-layer
squish on a real printer can rotate the seat point slightly, so:

1. Print `thread_test_collar.stl` (cheap, fast) and your plate.
2. Screw the plate in until snug. If the plate notch lands rotated from
   the collar notch, estimate the offset in degrees (the plate notch is
   6 mm wider than the base notch, so ±10° already works).
3. Set `plate_clock_adjust` in `scad/params.scad` to that offset (flip
   the sign if it gets worse), re-render, reprint the plate only.

The value is per printer+profile — calibrate once and every plate and
battery tub you print after that will clock correctly. If you'd rather
skip the whole game, use `base_wallhole.stl` + `bottom_plate_plain.stl`:
the cable window sits entirely in the base wall above the plate, so
nothing needs to align.

Threads are 45° flanks, 5 mm pitch, 0.3 mm radial clearance
(`thr_clr`) — loosen to 0.4 if your printer runs tight.

## Electronics

- ESP32 DevKit (30-pin) snaps between the rails on the plate/tub, USB
  end toward the cable notch. Feed the USB cable through the notch
  *before* plugging it in; leave a service loop.
- COB WS2812B strip (10 mm wide), ~455 mm around the inside of the outer
  rim. Stick it centered, LEDs facing the ring center; wires exit through
  the joint-plane channel in the tab, down into the base, to the board
  (5 V, GND, and data → GPIO16 or your preferred pin).
- Ring wires pass through the slot-floor hole; leave ~15 cm of slack so
  the plate can be unscrewed with everything connected.
- Set a WLED current limit (e.g. 1800 mA for a 2 A USB supply).
  Notification colors at modest brightness draw far less.

### Battery wiring

| Pack | Chemistry | Connect |
|---|---|---|
| 4×AA | **NiMH (recommended)** — 4.8 V nominal | Pack + → strip 5 V and ESP32 5 V pin, pack − → GND |
| 4×AA | Alkaline — 6.0 V fresh | Add 1–2 series diodes (1N5817) to stay ≤5.3 V for the strip |
| 8×AA | 12 V pack | 12 V strip (WS2815 or 12 V COB) direct; buck converter (MP1584 etc.) → 5 V for the ESP32 |

Pack leads route up through the 8 mm hole in the tub top plate. A KCD1
rocker switch snaps into the cutout on the front wall of every tub
(disable with `switch_cutout = false`). Battery door takes two M3×8
self-tapping screws.

*About "the battery boxes from the fume extractor project":* I couldn't
find that project in the repos this session can see, so the pockets are
sized for the common 58×31.5×15.5 mm 2×AA boxes and 62×58×15.5 mm flat
4×AA holders, with wiggle room. If yours differ, edit `pocket_cube` /
`pocket_flat4` / `pocket_flat8` in `scad/params.scad` (L×W×H + a couple
mm) and re-render.

## Ring assembly

1. Drop a diffuser into each half's rebate (it's captive after joining).
2. Stick the COB strip around the inside of one half's outer rim,
   centered on the joint line; route the wires through the tab groove.
3. Join the halves: the two alignment pins on each half enter the
   sockets on the other (flip one half over — the tab stays at the
   bottom by design). A few dabs of CA or plastic glue on the rim.
4. Seat the tab in the base slot, wires through the slot-floor hole.

## Rendering

```bash
./render.sh          # everything: STLs, fit checks, preview PNGs
./render.sh stl      # just the printable STLs
./render.sh check    # thread interference/engagement verification
```

Requires OpenSCAD (tested with 2021.01).

## Roadmap

- **Other shapes (heart, peace sign, …)** — planned next, as discussed.
  The double-sided construction (two flip-symmetric halves + captive
  diffusers + tab) is shape-agnostic; the circle modules in
  `scad/ring.scad` will be generalized to arbitrary outlines. Note the
  peace sign's interior bars will need a lighting decision (lit bars vs
  silhouette bars).
- Printed-contact AA holder (springs from salvaged holders) if the
  purchased-box pockets don't suit.
