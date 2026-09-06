# Energy Ring Remix — agent notes

Parametric OpenSCAD remix of the "ENERGY RING ESP32 + WLED" lamp
(MakerWorld 2045449). Read `README.md` for the product story. This file
is workflow knowledge for agents working in the repo.

## Layout

- `scad/params.scad` — ALL shared parameters, both series. Edit here first.
- `scad/lib/threads.scad` — thread primitives (twist-extrusion, printable
  45° flanks). `use`'d files can't see includer variables, so the lib
  defines its own local `EPS`.
- `scad/matched/` — **Series M**: dimensioned from the original model
  (Ø96 skirt, Ø180×40 ring, Ø27.8 stem). This is the series the user
  prints. `shell.scad`, `chassis.scad`, `ring_ds.scad`,
  `stem_locknut.scad`, `shapes_preview.scad` (mockups only).
- `scad/*.scad` (root) — Series A generic design. Stable; rarely touched.
- `scad/screen_stand/` — **unrelated part**: a display wedge stand,
  reverse-engineered from a donor 4.3" STL. Does not share
  `params.scad`. One file, four displays via `display=`: the Guition
  JC3248W535C (`jc3248w535`, the standard — soft r3.0, `parallel` back),
  the donor replica (`orig43`), and the Cheap Yellow Displays
  (`cyd28`, `cyd40`) and the 5" `jc8048w550`, which are two-part prints
  — add `part="face"` for the bezel plate. The 5" has two joint styles,
  `retain="snap"` and `retain="cap"`. See
  `docs/screen-stand-jc3248w535.md`.
- `scad/fit_check.scad` — boolean interference checks (see below).
- `stl/` — exported binary STLs, committed. `render.sh` — batch pipeline.
- `docs/` — handoff specs for planned work.

## Build & verify

```bash
./render.sh stl        # all parts; single part example:
openscad -o stl/x.stl -D 'part="shell_free"' -D 'm_jack_hole=true' scad/matched/shell.scad
python3 scripts/stl2bin.py stl/*.stl   # OpenSCAD 2021.01 writes ASCII (~28 MB); ALWAYS convert before committing
./render.sh check      # fit checks: "clearance" modes must render EMPTY, "engagement" NON-empty
xvfb-run -a openscad -o out.png --imgsize=1280,960 --camera=... file.scad   # PNGs need the virtual display
```

- Renders take minutes (CGAL). Run them in background tasks; batch
  everything needed into ONE task (render → warning grep → stl2bin →
  mesh probe → commit → push). Never poll or sleep-wait.
- `grep -c` exits 1 on zero matches — write `W=$(grep -icE 'warning|error' log || true)`
  or the whole `set -e` chain dies silently.
- Accept a render only with **0 warnings** (no "normalized", no
  non-manifold). Verify features at the MESH level, not by eyeballing:
  parse the binary STL (`struct`, 50 bytes/tri, count vertices in a
  bounding box) or ray-cast through hole centers (0 crossings = open,
  >0 = solid). Vertex counts near the thread band are meaningless —
  threads dominate; use ray-casts there.

## Export & mesh-coordinate conventions

- In-use coords: z=0 at the open bottom rim, +z up. Cable notch faces
  `notch_angle = 270°` (−Y, the "back").
- Shells/bases export **inverted** (`rotate([180,0,0])`) for printing:
  in the STL, in-use z=Z appears at mesh z=−Z and **Y is flipped** —
  the back wall (270°) shows up at **+Y** in mesh probes. Get this
  wrong and every probe lies to you.
- Rings/plates/diffusers export flat, not inverted.

## Validated print tolerances — do NOT retune

These were calibrated by the user's actual test prints. Reuse verbatim;
never "improve" them:

- Base thread: root r40.0, depth 1.6, pitch 5, len 7, `thr_clr` 0.30 —
  **test-printed, fits perfectly**, `plate_clock_adjust = 0` on their printer.
- Stem thread: root r12.6, depth 1.3, pitch 4, len 14.5, crest Ø27.8
  (= original stem OD, keeps cross-compatibility), `stem_thr_clr` 0.30.
- `diffuser_clr = 0.30` (0.15 test-printed too tight), snap bead 0.45
  proud = 0.15 bite per bead.
- Single-start threads only: the seated rotation is deterministic, which
  is what clocks the USB opening. `phase`/`*_clock_adjust` trims it.

## Geometry lessons already paid for

- Stem bulb: **surface-mount** it — `hull(scale([1,1,0.5]) sphere +
  shoulder disc)` on the rim outside, then subtract
  `cylinder(r = R_outer − wall + 0.05)` so it welds through the 2 mm wall
  and the light cavity stays clear. Flush-trimming a boss against the
  curved rim is geometrically doomed (tangency cusp, non-manifold).
- Female stem thread in the shell is built through the assembled ring's
  exact transform chain so phases nest by construction — copy
  `stem_thread_cavity()` in `scad/matched/shell.scad` if you need it.
- Fit checks on full parts can hit 10-minute CGAL timeouts — use
  standalone replica chunks (see `fit_check.scad` s_* modes). A
  "non-empty clearance" result can be a zero-volume contact sheet:
  lift one part by 0.02 before believing it.

## Repo / git conventions

- Git identity: `git -c user.email="jonathan@honeydewsleep.com" -c user.name="Claude" commit ...`
- STLs are committed **binary only** (ASCII bloats the repo 4×).
- The user is cost-conscious: work in long single turns, don't schedule
  periodic check-ins/polling (a previous hourly PR-watch loop burned
  ~20% of their credits overnight), don't re-render parts that didn't
  change, and don't render PNG previews unless asked.
