# Energy Ring Remix — WLED Notification Light

A fully parametric OpenSCAD rebuild of the
[ENERGY RING (ESP32 + WLED)](https://makerworld.com/en/models/2045449-energy-ring-esp32-wled)
desk lamp by DSL Design, with three revisions for use as a fleet of
email/notification lights:

1. **The base screws together** (coarse single-start thread, ~1.4 turns)
   — no more leaving the bottom on the desk. The single-start thread
   stops at a deterministic rotation, so the USB opening lands aligned
   with the ESP32's USB port every time.
2. **Battery base options**: 4×AA as a "cube" (two 2×AA boxes stacked),
   4×AA flat (four in a row), and an 8×AA double-layer for 12 V strips.
   Batteries load through a screwed door on the underside, so nothing
   unscrews (and no wires twist) for a battery change.
3. **Double-sided ring**: the LED strip mounts around the inside of the
   outer rim firing inward, and translucent diffusers on BOTH the front
   and back faces glow with the light color.

There are **two part series**:

- **Series M ("matched")** — `scad/matched/`, dimensioned from the
  original model's STLs. Same outside dimensions and look as the
  original (Ø96 skirt, tapered Ø95→86.6 shell, Ø180×40 ring, identical
  Ø27.8 stem + snap-diffuser interfaces), but the shell **threads onto
  the chassis** instead of resting on it. Cross-compatible: the new
  double-sided ring fits an original base, and the original ring fits
  the new threaded base. **Print this series to extend your fleet.**
- **Series A ("generic")** — a self-consistent standalone design
  (Ø150 two-half ring in a slotted Ø92 base) built before the original
  files were available. Kept as an alternative aesthetic.


## Also in this repo: Pillow Blower Counter

`counter/` is a separate project: a per-machine pillow counter on the
ESP32 Cheap Yellow Display with panel buttons, a Google Sheet backend and
a wall dashboard. See [`counter/README.md`](counter/README.md).

## The original's problem, measured

Slicing the original STLs shows the base is a tapered shell that simply
*rests* on the chassis cup (Ø82.5 barrel in a Ø82.9 mouth, held by
gravity) — that's the part that stays behind on the desk. Series M
replaces that slip joint with the clocked thread.

## What to print — Series M (matched, recommended)

| Configuration | Parts |
|---|---|
| USB powered | `shell_threaded.stl` (or `shell.stl`), `chassis.stl`, `ring_double_sided.stl`, 2× `ring_ds_diffuser.stl` |
| 4×AA battery (cube boxes) | shell + `chassis_bat_cube.stl`, `battery_door_cube.stl`, + ring parts |
| 4×AA battery (flat holder) | shell + `chassis_bat_flat4.stl`, `battery_door_flat.stl`, + ring parts |
| 8×AA / 12 V | shell + `chassis_bat_flat8.stl`, `battery_door_flat.stl`, + ring parts |
| Thread calibration | `thread_test_collar.stl` + any chassis (same thread as Series A) |

**Three shell options** (the ring's stem is threaded in all cases,
crest at the original Ø27.8):

- `shell_free.stl` + `stem_locknut.stl` — **position-anywhere**: the
  stem drops through a free-spinning bore; aim the ring at any angle,
  then screw the knurled locknut onto the stem from inside the base
  (reach in through the open bottom before the chassis goes on) and
  tighten. The shell top gets clamped between the ring's shoulder and
  the nut. Slip the nut over the wire bundle before connecting the
  wires.
- `shell_threaded.stl` — the ring **screws into the base** (~3.5
  turns) and stops facing forward (single-start; trim with
  `ring_clock_adjust` if your printer shifts the stop a few degrees).
- `shell.stl` — plain crush-rib collar: any ring *push-fits*, including
  unmodified original rings. The threaded ring's crests still grip in
  it, so rings are interchangeable across all shells and original
  bases.

**Bottom-port options** (`shell_free_port_button.stl` — port window at
the original notch position + front dismiss-button hole):

- **Cable through the window**: pair with any standard chassis; the
  USB-C plug passes through the 13×10 window (17×14 funneled mouth)
  and plugs into the board inside.
- **Panel jack in the base** (`chassis_jack.stl`): a Ø9.7 hole in a
  recessed panel across the barrel passage takes a 9.1 mm USB-C chassis
  jack (nut from the open interior, pigtail to the board's 5V/GND).
  The clocked thread lands the shell's window framing the jack. The
  port face sits ~8 mm behind the shell surface, so the plug's
  overmold must be slimmer than ~13×10 mm for its first centimeter —
  typical cable ends fit, extra-chunky ones may not. Flash the board
  before assembly (or use WLED OTA); the board's own USB port isn't
  reachable through the wall in this build.

Ring: print `ring_double_sided.stl` in your body color (the rims are
opaque; white bounces the most light) and the two `ring_ds_diffuser.stl`
trays in translucent/natural. The trays snap in with double beads
exactly like the original diffuser, at any rotation — the stem bulb
is surface-mounted outside the rim wall (like the original), so the
light cavity is completely clear. Print one tray opaque for a
single-sided ring. The COB strip runs the full inside of the rim,
ending at the Ø20 wire hole.

## What to print — Series A (generic)

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

## How the USB alignment works (both series)

The thread is single-start, so the fully-tightened joint always stops at
the same rotation. In Series M the USB hole lives in the shell wall and
the ESP32's port lives in the chassis; the clocked thread stops the hole
right in front of the port (the barrel passage is 5 mm wider than the
hole for slack). In CAD the alignment is exact at seat; first-layer
squish on a real printer can rotate the seat point slightly, so:

1. Print `thread_test_collar.stl` (cheap, fast) and a chassis (or plate).
2. Screw together until snug. If the notch lands rotated, estimate the
   offset in degrees (±10° already works).
3. Set `plate_clock_adjust` in `scad/params.scad` to that offset (flip
   the sign if it gets worse), re-render, reprint the male part only.

The value is per printer+profile — calibrate once and every chassis,
plate and battery tub you print after that will clock correctly. In
Series A you can skip the game entirely with `base_wallhole.stl` +
`bottom_plate_plain.stl` (window fully in the wall, nothing to align).

Threads are 45° flanks, 5 mm pitch, 0.3 mm radial clearance
(`thr_clr`) — loosen to 0.4 if your printer runs tight.

## Electronics

- ESP32 DevKit (30-pin) snaps between the rails on the chassis floor
  (Series M) or plate/tub (Series A), USB end toward the notch angle.
  Feed the USB cable through the hole *before* plugging it in; leave a
  service loop.
- COB WS2812B strip (10 mm wide): Series M ring takes ~550 mm around
  the Ø176 inside of the outer rim (~180 LEDs at 332/m — set a WLED
  current limit, e.g. 1800 mA on a 2 A supply); Series A ring takes
  ~455 mm. Stick it centered, LEDs facing the ring center; start/end
  the strip at the wire hole at the bottom of the rim.
- Series M: wires run down the Ø20 stem bore into the base; Series A:
  through the tab channel and slot-floor hole. Either way leave ~15 cm
  of slack so the base can be unscrewed with everything connected.

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

## Ring assembly — Series M (matched)

1. Stick the COB strip around the inside of the outer rim, centered;
   start/end at the wire hole at the stem angle, wires down the stem.
2. Snap a diffuser tray into each face (double snap beads, exactly like
   the original diffuser — firm push all around). The trays also
   rigidify the ring, so snap both in before handling roughly.
3. Mount per your shell: `shell_free` — drop the stem in, aim the
   ring, slip the locknut up the wires and tighten it from inside;
   `shell_threaded` — screw the stem in clockwise (viewed from above)
   until the shoulder seats facing forward; `shell` — push the stem in
   until the crush ribs seat. Wires continue into the chassis in all
   cases.

## Ring assembly — Series A (generic)

1. Drop a diffuser into each half's rebate (it's captive after joining).
2. Stick the COB strip around the inside of one half's outer rim,
   centered on the joint line; route the wires through the tab groove.
3. Join the halves: the two alignment pins on each half enter the
   sockets on the other (flip one half over — the tab stays at the
   bottom by design). A few dabs of CA or plastic glue on the rim.
4. Seat the tab in the base slot, wires through the slot-floor hole.

## Email notifications (the whole point!)

WLED lamps take simple HTTP commands on your LAN, so a small bridge
watches Gmail and flips presets:

- **`companion/gmail_wled_bridge.py`** — standalone bridge, stdlib
  Python, runs on any always-on machine (Pi, desktop). Polls Gmail
  over IMAP for unread mail from specific senders (or Gmail labels),
  switches all lamps to that rule's WLED preset, and returns them to
  idle once the mail is read. Setup instructions in the file header.
- **Home Assistant alternative**: the `imap` integration fires an
  event per incoming mail; an automation matching the sender calls
  the WLED integration (`light.turn_on` with a color, or select the
  preset entity). Same idea, no extra script, if you already run HA.

Either way, save your looks as WLED presets (1 = idle, 2 = red
breathe, ...) so you can restyle in the WLED app without touching the
bridge. With WLED Sync (one lamp sends, the rest receive) a single
command drives every lamp in the house.

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
