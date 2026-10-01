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
| Top half | sculpted pillow shell + magnet carrier plate (2 screws) | pillow cap + carrier plate, glued, 2 pegs |
| Bottom half | base shell + thin grooved track plate (centre screw) | base + 1.2 mm grooved track plate, glued |
| Magnets per half | 4 large corner + 6 small (2 × 3 grid) + centre element | 4 × Ø6×3 + 6 × Ø4×3 (positions in `big_pos` / `small_pos`) |
| Click feedback | spring-loaded centre pin riding over concentric rectangular grooves | Ø3 steel ball + pen spring, concentric grooves 2.6 mm pitch |
| Finish | mirror / sandblasted / stonewashed titanium, UV-resin edition | – |

The exploded render shows, left to right: pillow, a serpentine flat
spring with a square centre block (the "guided retracting structure"),
the carrier plate with its 10 round pockets and a square centre hole,
the grooved track plate with its centre screw, and the base shell with
the same magnet layout. The halves are held together only by magnets,
so the slider has no end stops and can rotate in its own plane; the
pin clicking over the grooves is what gives the "pocket rhythm".

## Parts and print orientation

Every part exports with its **sliding face on the bed** (the face the
other half glides on) except the embedded base, which has to print
bottom-down because its grooves are on the top surface. No supports.

**Recommended 4-part build** (no printer tricks, magnets captured):

| STL | What | Notes |
|---|---|---|
| `stl/slider_carrier.stl` | 3.6 mm plate, lower part of the pillow outline | pockets open towards the cap, ball-detent bore, two Ø2.4 pegs up |
| `stl/slider_pillow_cap.stl` | sculpted pillow, flat underside | peg holes, Ø3.8 × 4 spring pocket |
| `stl/slider_base.stl` | 5.5 mm base shell | pockets open on the (bed-side) top face, two Ø1.9 dowel holes |
| `stl/slider_track.stl` | 1.2 mm grooved track plate | grooves up, Ø1.9 dowel holes |

**1-piece-per-half, pause-and-insert** (`slider_pillow_embedded.stl`,
`slider_base_embedded.stl`): closed pockets; the render echoes the
pause heights (pillow: magnets at z = 3.7, ball + spring at the bore
ceiling z = 7.6 — the spring must then be ≤ 5 mm free length; base:
magnets at z = 5.7, printed bottom-down).

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

## Assembly

1. Base: drop the magnets in (**all the same pole up**), glue the track
   plate on top, grooves out, edges flush (dowels optional).
2. Carrier: press the ball into the centre bore from the top (it seats in
   the tapered mouth and sticks out ~0.4 mm), add the spring, drop the
   magnets in with the **opposite pole facing down** so that every
   magnet attracts its counterpart when the halves are aligned.
3. Glue the pillow cap onto the carrier (pegs locate it; the spring is
   compressed by the cap's pocket). Done — slide, spin, click.

With uniform polarity every 8 mm step along the length lands on a new
attracting alignment, so the slider "clicks" through positions without
end stops, like the original. Flipping individual magnets changes the
feel; the array positions are plain lists in the SCAD if you want to
try a chequerboard.

## Tolerances to confirm on the first print

- `mag_clr = 0.3` on pocket diameter (same number the lamp uses).
- `mouth_d = 2.0`: ball protrusion ≈ 0.38 mm. Larger mouth = more
  protrusion = stronger clicks.
- `groove_w = 1.8`, `groove_d = 0.5`: wide enough for a Ø3 ball to dip
  ~0.3 mm; the carrier face rides on the 0.8 mm ridges.
- Thickness split (9.8 / 1.2 / 5.5) was read from side-view photos; the
  campaign's parameter sheet labels the pillow "0.5 in" and the whole
  thing "0.65 in", which do not add up, so expect ±1 mm there.

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
