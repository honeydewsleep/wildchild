# Energy Ring Remix — agent notes

Parametric OpenSCAD remix of the "ENERGY RING ESP32 + WLED" lamp
(MakerWorld 2045449). Read `README.md` for the product story. This file
is workflow knowledge for agents working in the repo.

## Layout

- `pen/` — **separate project**: bolt-action pen remixes (see `pen/README.md`
  and the *Pen project* section at the end of this file).

- `scad/params.scad` — ALL shared parameters, both series. Edit here first.
- `scad/lib/threads.scad` — thread primitives (twist-extrusion, printable
  45° flanks). `use`'d files can't see includer variables, so the lib
  defines its own local `EPS`.
- `scad/matched/` — **Series M**: dimensioned from the original model
  (Ø96 skirt, Ø180×40 ring, Ø27.8 stem). This is the series the user
  prints. `shell.scad`, `chassis.scad`, `ring_ds.scad`,
  `stem_locknut.scad`, `shapes_preview.scad` (mockups only).
- `scad/*.scad` (root) — Series A generic design. Stable; rarely touched.
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

## Pen project (`pen/`)

Bolt-action pen remixes. Reference models live in the user's Google
Drive (*The Rabbit Hole › 3D Print Files › Pens › Favorites*), reachable
through the Google Drive connector (`search_files` by title, then
`download_file_content`; large results land in a tool-results file —
decode the base64 `content` field to get the binary STL). Measurements
already taken are in `pen/docs/reference-measurements.md`; do not
re-download unless something new is needed.

- `pen/scad/params.scad` holds every dimension. INTERIOR values are the
  reference pen's and must not change (they fit the user's refills).
- Pen bodies export **upright, not inverted**: z=0 is the back rim on
  the bed, tip up. Mesh z = design z.
- The bolt track is cut with `wall_cut()` in `pen/scad/body.scad`: a
  lofted polyhedron between an outline on the reference bore surface
  (r 4.2) and one on the reference outer surface (r 5.75), extended
  inward/outward, so the cut is independent of the hex wall thickness.
  The reference cuts lean ~3°/side (wider at the bore); the hook ramp
  leans ~30°. Outline winding is normalised inside the module; keep
  `inner` and `outer` outlines vertex-for-vertex matched.
- Verify against the reference by ray-casting the exported mesh
  (interior radius per z, and an unrolled through/wall map of the
  track), not by eye. A hex exterior can never match the leaning-ramp
  region cell-for-cell; compare the bore-surface map.
- Renders are fast here (~10 s per part, CGAL) — no need for
  background batching, but still convert STLs to binary before commit.
- `pen/ref/` holds the one third-party mesh we derive from directly
  (`Pen_Upper_Housing.stl`); `click_housing_slim.scad` intersects it
  with an envelope — the front collar (clip ring seat) and the rear cam
  section (0.4 mm wall) must stay original.
- v2 is two-piece: `v2_grip.scad` (z from the TIP) + `v2_barrel.scad` (z
  from the BACK; bolt-track z values identical to v1 via `lib/track.scad`).
  The joint is a round Ø11 neck + 45°-flank thread from `scad/lib/threads.scad`
  (root r 4.0, depth 0.6, pitch 1.5, clr 0.30). The knurl is the
  intersection of two twisted extrusions of a 30-notch disc (CGAL-slow:
  minutes). Plunger loads from the front through the female thread
  (bore Ø8.4 to the thread) — never reintroduce a Ø6.88 section in the
  barrel or a sealed back becomes un-assemblable.
