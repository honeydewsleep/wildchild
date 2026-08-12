# Handoff spec: peace-sign lamp (print-ready)

Turn the approved peace-sign mockup into print-ready parts. Read
`CLAUDE.md` first for build/verify workflow and the tolerances that must
be reused verbatim. This document contains every design decision already
made with the user — do not re-open them.

## What the user approved

`scad/matched/shapes_preview.scad`, `shape = "peace"`: the peace sign as
**one connected hollow glow region** — outer ring band plus the three
bars — rendered with `lamp_mock(solid = true)`. The user's explicit
revision: *"make the Peace sign interior also a hollow cavity with the
diffusers on both sides, so that I can also make that part light up"* —
i.e. the WHOLE sign glows, not just the ring; the bars are lit cavities,
not silhouettes.

Geometry of the approved outline (`peace2d()`):

- Outer circle Ø180 (matches the Series M ring), glow band `BAND = 22`
  (annulus Ø180 → Ø136).
- Bars 14 wide: one vertical full-diameter bar, two lower diagonals at
  ±45°, all clipped to the inner circle (+4 overlap so they fuse with
  the band).
- The three non-glowing window openings between the bars remain open
  (through-holes), each bounded by its own edge walls.
- Depth 40 front-to-back (same as `m_ring_t`).

## Construction — mirror `scad/matched/ring_ds.scad`

Build `scad/matched/peace_ds.scad` using the double-sided ring as the
template. Same construction language throughout:

- 2 mm walls (`m_rim_wall`) around the outline AND around each of the
  three window openings, full 40 mm depth. The bars' walls tie the
  structure together, so no spokes are needed.
- **Stem + bulb: reuse the ring's implementation.** The outline's lowest
  point is the Ø180 circle bottom (y = −90), exactly like the ring, so
  the threaded stem (`stem_thr_*` params, Ø20 wire bore through to the
  cavity) and the surface-mounted bulb (hull of squashed sphere +
  shoulder disc, minus `cylinder(r = 90 − m_rim_wall + 0.05)`) transfer
  nearly verbatim. Keep `stem_only()`-style export for fit checks and
  keep `ring_clock_adjust` phase trim so the seated sign faces forward.
- LED strip: 10.5 mm channel space along the inside of the outer band
  wall (Ø176 inside ≈ 553 mm of COB strip), LEDs firing inward. Strip
  start/end at the wire hole above the stem. The cavity is connected, so
  light spills from the band into the bars — the bars will glow dimmer
  than the band (acceptable; note it in the README). Do not attempt to
  route strip along the bars.
- Diffusers on BOTH faces: full sign outline with the three windows cut
  out, `m_dif_face_t` = 1.0 face. Snap retention like the ring's trays —
  10 mm skirts with double beads (0.45 proud, positions
  `m_dif_bead_z`) — but the skirts follow **offsets of the outline
  polygon** (and of each window edge) instead of circles: skirt outer
  surface = cavity edge − `diffuser_clr` (0.30). The peace outline is
  mirror-symmetric about the vertical axis, so ONE diffuser STL fits
  both faces (flip it over) — export one `peace_ds_diffuser.stl`,
  print ×2.
- Sharp-corner caution: where bars meet the band, `offset(r = ...)`
  rounds inside corners; that is fine here (the mockup already uses
  round-friendly geometry). Avoid `offset(delta)` on this shape — it
  can self-intersect at the 45° junctions.

## Parameters

Add a small `/* peace sign */` block in `scad/params.scad` (Ø180 outline,
band 22, bar width 14, reuse `m_ring_t`, `m_rim_wall`, `m_dif_*`,
`diffuser_clr`, `stem_thr_*`). No new tolerance values — everything fit-
critical already exists and is print-validated.

## Deliverables

1. `scad/matched/peace_ds.scad` — `part = "peace_ds" | "diffuser_peace"`.
   Sign exports face-down flat (NOT inverted — rings/diffusers export
   flat, only shells/bases invert). Diffuser exports flat, beads up.
2. `stl/peace_sign.stl` + `stl/peace_ds_diffuser.stl`, binary
   (`python3 scripts/stl2bin.py`), 0 render warnings.
3. Add the two parts to `render.sh` (stl section).
4. Verification before pushing (see CLAUDE.md for technique):
   - mesh probe: stem present at bottom, Ø20 bore open (ray-cast down
     the stem axis), three window through-holes open, faces at z = 0/40;
   - stem thread engagement vs the shell collar replica (pattern:
     `s_clearance` / `s_engagement` modes in `scad/fit_check.scad` —
     add `p_*` modes or reuse, clearance EMPTY, engagement NON-empty);
   - diffuser skirt vs cavity: clearance check with the 0.02 lift trick.
5. README: add the peace sign under a "Shape lamps" section (parts
   table row, assembly = same as ring, note the bars glow dimmer via
   spill light).
6. Commit (identity in CLAUDE.md), push, attach both STLs to the user
   with SendUserFile.

## Out of scope (do not build yet)

The heart (sharp inner V via mitered offset) and other shapes from
`shapes_preview.scad` — the user will ask separately. Do not modify
Series A, the shells, the chassis, or any validated tolerance.
