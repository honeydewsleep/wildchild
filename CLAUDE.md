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

## `counter/` — Pillow Blower Counter (separate project)

CYD (ESP32-2432S028R) pillow counter: `counter/firmware` (PlatformIO,
`pio run -e cyd`; copy `include/config.h.example` to `config.h` first),
`counter/backend` (Apps Script `Code.gs` + `Dashboard.html`; the HTML
renders with demo data when opened locally), `counter/enclosure`
(`cyd_counter_case.scad` wall case, parts `fit_test|box|bezel|assembly`;
`cyd_desk_stand.scad` 32° desk stand with 3 up-facing 16 mm buttons on
a flat top, parts `base|bezel|btn_test|assembly|check_buttons|check_bosses`
— the `check_*` parts must render EMPTY; `cyd_desk_stand_v2.scad` grafts
the same flat button top onto the ORIGINAL "CYD Desk Buddy" mesh
(`counter/enclosure/src/*.stl`, imported; keeps its hidden fixing and
symmetrical bezel — use the source Front Panel STL as-is; ~1 min render.
Lessons: union the imported mesh with new geometry FIRST and cut
afterwards — CGAL's union asserts on a mesh that was already cut; and
keep new faces 0.02 mm inside the mesh's faces, never exactly
coincident. Its screw pattern is offset +2.9 mm like the PCB, not
symmetric; its fixing is 4× M2.5 × 10 pan head (Ø6.4 counterbores,
Ø3.2 boss bores, Ø2.1 × 4 mm post holes — NOT countersunk M3). Its fillets: top-side/front corners r≈6.2, rear verticals
4.8, top-back edge sharp — the new back edges use 6.2 at the user's
request. The old back wall is cut to two screw pads + a bottom strip so
the button compartment is reachable from the front; the rear section
has its own 2 mm floor (`rear_floor`). Four Ø8.15 × 4.2 press-fit
magnet cups open UPWARD over a 1 mm skin, straight bore + 0.4 flare
above (bottom face closed; cups on the front floor and in the rear
corners, clipped to the shell). `panel` / `panel_slim` parts re-export
the source Front Panel, the slim one trimmed `panel_trim` (0.2) per
edge — the pocket has only 0.2 mm a side of clearance; STLs in
`counter/enclosure/stl/`, binary-converted like the lamp STLs). CYD board
dims live in `counter/enclosure/cyd_board.scad`, included by both files —
they are unverified against a real board: `fit_test` exists for that.
Both bezels export inverted (face down) — Y is flipped in mesh probes,
same as the lamp shells. The desk stand's top depth is derived from the
button nut/body and the board envelope (`stack`), not set directly.
OpenSCAD is not preinstalled in the remote sandbox; `apt-get update &&
apt-get install -y openscad xvfb` works (2021.01). Firmware compiles
clean; nothing has run on hardware yet.

### Drive mirror of `counter/` (standing instruction)

The user reads the counter project from the shared drive, not GitHub:
folder "PIllow Batch Counter and Production Dashboard" (Drive id
`1DEdu3ccgfV6wMw81nnKKMdXqBjNUtbzG`, shared drive "App and Code
Database Assets"). Subfolders `firmware/{src,include}`, `backend`,
`enclosure`, `docs` mirror the repo; the root holds `README.md` and
"READ ME FIRST - downloads and versions.txt" (version, commit, and the
GitHub raw links for the `.bin` images and STLs, which are too big for
the Drive MCP - only inline text/base64 ≤ ~25 KB per call works).
**After every counter change:** move the current root files into a
`v<N> (<date>)` subfolder, upload the new versions to the root and the
mirrored subfolders, bump the version note. Use `search_files` with
`parentId = '<id>'` to verify uploads (a batch of parallel `create_file`
calls can return "internal error" while still succeeding). The Drive MCP
cannot MOVE files (`update_file` with `parentId` → "caller does not have
permission"); it can rename and trash. So archive by re-uploading the
old versions into the `v<N>` folder (old text comes from `git show
<commit>:counter/...`), then trash the superseded root/subfolder copies.
