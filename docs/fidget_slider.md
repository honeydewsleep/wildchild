# Fidget slider — DADA / LOOPLET size & feel mockup

Parametric OpenSCAD remake of the **"DADA" Infinite Slider** (Kickstarter
campaign by firstedc, previously named LOOPLET) so you can hold the size
and try the magnet array before backing it. Source: `scad/fidget_slider/slider.scad`.

## What the campaign tells us

Nothing in the campaign text gives dimensions; everything below was read
off the campaign images (parameter sheet, exploded "Structural
Innovation" animation, hand photos).

| Item | Original | This model |
|---|---|---|
| Footprint | 1.83 × 1.18 in | 46.5 × 30 mm, corner R 6 |
| Assembled thickness | 0.65 in | 16.5 mm (pillow 9.8 + track 1.2 + base 5.5) |
| Weight | 53 g (Gr5 titanium) | ~30–35 g in PLA with magnets |
| Top half | sculpted pillow shell + magnet carrier plate (2 screws) | pillow cap + carrier plate, glued, 2 filament dowels |
| Bottom half | sculpted base shell + thin grooved track plate (centre screw) | sculpted base shell + 1.2 mm grooved track plate, glued, 2 filament dowels |
| Magnets per half | 4 large corner + 6 small (2 × 3 grid) + centre element | 4 × Ø6×3 + 6 × Ø4×3 (positions in `big_pos` / `small_pos`) |
| Click feedback | spring-loaded centre pin riding over concentric rectangular grooves | Ø3 steel ball + pen spring, concentric grooves 2.6 mm pitch on **both** sliding faces |
| Finish | mirror / sandblasted / stonewashed titanium, UV-resin edition | – |

The exploded render shows, left to right: pillow, a serpentine flat
spring with a square centre block (the "guided retracting structure"),
the carrier plate with its 10 round pockets and a square centre hole,
the grooved track plate with its centre screw, and the base shell with
the same magnet layout. The halves are held together only by magnets,
so the slider has no end stops and can rotate in its own plane; the
pin clicking over the grooves is what gives the "pocket rhythm".

Two deliberate departures: the base shell is a shallower copy of the
sculpted pillow (the original's base is a rounded shell too, this model
first had a flat slab), and the top half's sliding face is patterned as
well. Its pattern is straight stripes at 45° (`carrier_groove_angle`),
not a copy of the track's rings: identical rings would nest into each
other every 2.6 mm and ratchet, and whenever they nested the carrier
would drop 0.5 mm and swallow the ball's reach. Crossed stripes always
ride ridge on ridge, so the gap is constant, the ball's reach past the
ridges is constant, and the contact is a grid of points, which glides
more easily than two flat faces. `carrier_groove_angle = 0` gives the
nesting rings, `carrier_grooves = false` a smooth face.

Only faces that slide get the 0.6 mm edge chamfer. Glued seat faces
(base under the track) are square, so those seams are flush butt joints
like the cap/carrier one; a chamfer there reads as a V-notch.

## Parts and print orientation

Every STL is already in its print orientation. No supports anywhere.
Parts whose ridged face lands on the bed (the embedded halves) print the
ridge tops as the first layer; add a brim if those thin strips lift.

**Recommended 4-part build** (no printer tricks, magnets captured):

| STL | What | Print side on the bed |
|---|---|---|
| `stl/slider_carrier.stl` | 4.1 mm plate, lower part of the pillow outline; ridged sliding face with the ball mouth, pockets open towards the cap | pockets down, ridges up |
| `stl/slider_pillow_cap.stl` | sculpted pillow, flat underside with Ø3.8 × 3.9 spring pocket | flat face down |
| `stl/slider_base.stl` | sculpted base shell, pockets open towards the track plate | pocket face down, dome up |
| `stl/slider_track.stl` | 1.2 mm grooved track plate | grooves up |

The track's ring pattern has four ridge-level spokes along the diagonals
(like the original's corner lines); the ball rides over them like any
ridge.

Each glued pair (cap/carrier, base/track) has two Ø1.9 holes at ±12 mm;
5 mm stubs of 1.75 mm filament align them (or just line up the edges).

**Snap variant** (`snap = true`, STLs `stl/slider_snap_*.stl`, project
files `3mf/slider_4part_snap_*.3mf`): no glue. Four barbed posts stand
on the back of the carrier and of the track plate; the cap and the base
each carry two flex beams (0.6 mm thick, 14 mm span, free on both long
sides) bridged across a cavity. Pressing a cap on, the barbs' ramps lift
the beams 0.5 mm, pass, and the beams drop back under the barbs. Pull
firmly to release (the 45° barb underside cams the beams up again).
Only the plates change orientation: carrier and track print with their
ridged face **on the bed** so the posts can grow upwards (the diagonal
spokes in the track pattern tie its ring ridges together for that first
layer; add a brim if the ridges lift). The caps still print face-down;
the beams and cavities inside them are plain bridges. The flex beams
are the one unverified element of this model: if a beam snaps, raise
`snap_beam_t` to 0.8 or print the cap and base in PETG; if the latch is
too loose, raise `snap_barb`.

**Snap variant, plates on edge** (`snap = true` + `stand = true`, STLs
`stl/slider_snap_stand_*.stl`, project files
`3mf/slider_4part_snap_stand_*.3mf`): carrier and track print standing
on their −y long edge with a 5 mm brim, no supports; the ridged face
becomes a vertical wall (crisp pattern, nothing bridged) and the posts
grow sideways. To keep every barb printing upwards, both latches face
+y in this variant: the second beam sits across the centre of the cap
and base, so the ball bore is gone (`detent_on` is false) and the cap
goes on one way round only (match the two posts near the carrier's
centre line to the centre beam). Posts carry 45° gussets underneath,
the carrier's magnet pockets are teardrops, and the cap/base channels
are extended to clear the gussets. Caps print face-down as before. The
1.2 mm track standing 30 mm tall is the fussy print: slow it down; if it
wobbles, the glued grooves-up track is the fallback.

**1-piece-per-half, pause-and-insert** (`slider_pillow_embedded.stl`,
`slider_base_embedded.stl`): both print ridged face down. Closed pockets
whose ceilings sit on the 0.2 mm layer grid, so the pauses are plain
layer tops (the render echoes them): magnets at z = 4.2 in **both**
halves, then ball + spring at the bore ceiling z = 8.0 in the pillow
(the spring must then be ≤ 5 mm free length). Pause **before** the
layer above that height starts, i.e. the first layer that closes the
pocket.

Ready-made project files are in `3mf/`, one pair per slicer family —
`*_bambu.3mf` for Bambu Studio / OrcaSlicer (carries an A1 printer
profile from the template; switch to your printer after opening, the
pauses stay) and `*_prusa.3mf` for PrusaSlicer / SuperSlicer:

- `slider_4part_*.3mf` — the four capped-build parts on one plate.
- `slider_embedded_*.3mf` — both embedded halves on one plate with the
  two pauses in the layer slider (verified on the Prusa file by
  slicing: M601 at Z4.2 and Z8.0).

They are built by `scripts/make_3mf.py` from the STLs (see its
docstring).

**Simplest** (`slider_pillow_open.stl`, `slider_base_open.stl`):
pockets open at the sliding face, magnets glued 0.2 mm below the
surface, no detent, no grooves — the usual MakerWorld construction.

## Bill of materials (4-part build)

- 8 × Ø6 × 3 mm disc magnets (corners) and 12 × Ø4 × 3 mm (inner grid).
  Ø4 × 2 works too (`mag_small_t = 2`; pockets follow the thickness).
- 1 × Ø3 mm steel ball + 1 compression spring, OD ≤ 3.6 mm (a ballpoint
  pen spring cut to ~7 mm). Both optional: without them it is a
  pure magnetic slider (`detent = false` removes the bore).
- CA glue; optional 2 stubs of 1.75 mm filament as dowels for the track.

### Where to buy (Amazon, checked Oct 2026)

| Part | Qty per slider | Links |
|---|---|---|
| Ø6 × 3 mm disc magnets | 8 | [20-pack](https://www.amazon.com/dp/B0FQMPK65H) · [30-pack N52](https://www.amazon.com/dp/B0CLTWR8Z1) · [150-pack N52](https://www.amazon.com/dp/B0GF7CJVMY) |
| Ø4 × 3 mm disc magnets | 12 | [100-pack](https://www.amazon.com/dp/B0H28LQ1WZ) · [50-pack](https://www.amazon.com/dp/B0CD87R29Y) (multi-size listing, choose 4×3 mm) |
| Ø3 mm steel ball | 1 | [50-pack 304 stainless](https://www.amazon.com/dp/B0174MEUWA) · [50-pack 316L](https://www.amazon.com/dp/B087CZ5ML5) — any grade works, the spring supplies the detent force |
| Compression spring 3 mm OD × 0.3 mm wire | 1 | [20-pack, 10 mm free length](https://www.amazon.com/dp/B0F9PM65H2) · [10-pack, 10 mm](https://www.amazon.com/dp/B0D9Y4FG2J) — cut to ~7 mm for ~1 N preload; a ballpoint-pen spring also fits the Ø3.8 bore |

## Assembly

1. Base: drop the magnets in (**all the same pole up**), glue the track
   plate on top, grooves out, edges flush (dowels optional).
2. Carrier: press the ball into the centre bore from the pocket side (it
   seats in the tapered mouth and sticks out ~0.4 mm past the ridges),
   add the spring, drop the magnets in with the **opposite pole facing
   down** so that every magnet attracts its counterpart when the halves
   are aligned.
3. Glue the pillow cap onto the carrier (dowels locate it; the spring is
   compressed by the cap's pocket). Done — slide, spin, click.

### Polarity: two arrangements, two feels

The campaign never shows the magnet poles, so pick by feel. Whatever
the pattern, the top half must mirror the bottom so that every pair
attracts at the home (aligned) position.

- **All attract** (every base magnet N up, every pillow magnet S down):
  one strong home position plus soft catches every 8 mm along the
  length where the inner 2 × 3 grid realigns with its neighbours. The
  top glides and can park a step off-centre.
- **Chequerboard inner grid, corners attract** (base: inner magnets
  alternate N/S along each row and between the rows; the four Ø6
  corners all N up; pillow mirrors): home is the only comfortable
  position. Pushed half a pitch the inner pairs repel while the big
  corners pull it back, so it springs home when released — the
  push-pull, "retracting" behaviour in the campaign video. The corners
  are 33 mm apart and never meet anything but their own partners, so
  they only add holding force at home.

The 4-part build lets you test before gluing the cap: load the base,
drop magnets into the carrier, hold it on the track and slide. Swap
magnets until it feels right, then glue.

### What the ball rides on

The ball (0.38 mm proud of the carrier's ridges) needs recesses on the
opposite face, and those are the track plate's grooves: every 1.8 mm
groove is a 0.3 mm dip (a click), and the lowered centre slot is the
home detent it drops into fully. There is no separate dimple. This is
why the carrier's own pattern must not nest into the track (see above).

## Tolerances to confirm on the first print

- `mag_clr = 0.3` on pocket diameter (same number the lamp uses).
- `mouth_d = 2.0`: ball protrusion ≈ 0.38 mm. Larger mouth = more
  protrusion = stronger clicks.
- `groove_w = 1.8`, `groove_d = 0.5`: wide enough for a Ø3 ball to dip
  ~0.3 mm; the carrier face rides on the 0.8 mm ridges.
- Thickness split (9.8 / 1.2 / 5.5) was read from side-view photos; the
  campaign's parameter sheet labels the pillow "0.5 in" and the whole
  thing "0.65 in", which do not add up, so expect ±1 mm there.
- Ridges on both faces: if the ratcheting is too coarse, set
  `carrier_grooves = false` (smooth carrier face, 0.5 mm thinner carrier)
  or shallow the pattern with `groove_d`.

## Rendering

```bash
openscad -o stl/slider_carrier.stl -D 'part="carrier"' scad/fidget_slider/slider.scad
python3 scripts/stl2bin.py stl/slider_*.stl
python3 scripts/stl_probe.py stl/slider_carrier.stl 16,8.3 0,0   # pocket / bore ray-casts
```

`part = "preview"` and `"exploded"` are assembly views for PNGs
(`preview/fidget_slider*.png`). The pillow's dome is a height-map
polyhedron (`heightmap_solid()`), so the sculpt is editable through the
`valley_*` parameters; the whole part re-renders in well under a minute.
