# 12" Vent Deflector, magnets 8.5" apart

Remix of the **6-20 Expandable Vent Cover / Vent Deflector**
([MakerWorld 2722921](https://makerworld.com/en/models/2722921-6-20-expandable-vent-cover-vent-deflector),
6-12" profile). The original is two 6" halves that telescope; the magnets ride
on the end caps, so their spacing is tied to the overall length. This version
fixes the overall length at **12"** (304.8 mm) and puts the two magnet bosses
**8.5"** (215.9 mm) apart, 1.75" in from each end, so the scoop covers nearly the
whole vent while the magnets land where you want them.

Everything else is copied from the original: 100 mm quarter-round scoop,
2 mm wall, open toward the wall and open on the exit side, closed end caps,
two Ø6.7 × 1.9 mm magnet pockets per boss on 9.7 mm centres (for **6 × 2 mm
disc magnets**, glued in, sitting ~0.1 mm proud for good contact).

## Parts (`stl/`)

| File | What | Print |
|---|---|---|
| `vent_deflector_12in_half_A.stl` | cap end + **outer** half-lap | cap down, as exported |
| `vent_deflector_12in_half_B.stl` | cap end + **inner** half-lap | cap down, as exported |

Each half is 160 mm tall (145 mm of full wall + a 15 mm half-thickness lap).
Slide the two laps together: half B's inner lap goes inside half A's outer lap,
0.30 mm radial clearance. The assembled scoop is 304.8 mm; the outside and
inside surfaces stay flush across the joint. The magnets hold each half to the
vent on their own, so the joint is only for alignment. A drop of glue in the lap
is optional.

A one-piece 12" print was rejected on purpose: standing cap-down it would need
a 305 mm tall print with an unsupported top cap. Two halves print the same way
the original does, with no supports.

## Magnet bosses

The bosses hang under the hood (the top edge of the scoop, where the arc meets
the wall at a right angle), the same spot the original designer used for the
inner half's magnets. That location prints cap-down with no support: each boss
has a 45° chamfer on its underside. The pockets open toward the wall face.

Set `cap_magnets = true` to add the original's mid-face magnet boss on each end
cap as well (also support-free). Default off: the brief was 8.5" spacing only.

## Printing

Original profile targets a Bambu Lab H2D at 0.2 mm, 2 walls, 15 % infill, no
supports. Both halves fit any 256 mm bed standing up (100 × 100 footprint,
160 mm tall).

## Parameters (`vent_deflector.scad`)

- `total_len` (304.8), `magnet_spacing` (215.9): the two numbers from the brief.
- `R` (100), `wall` (2), `cap_t` (2): scoop section.
- `lap_len` (15), `lap_clr` (0.15 per side): the middle joint.
- `pocket_d` (6.7), `pocket_depth` (1.9), `pocket_pitch` (9.7): magnet pockets.
- `part`: `half_A`, `half_B`, `assembly` (preview), `fit_check` (must render empty).

```bash
openscad -o stl/vent_deflector_12in_half_A.stl -D 'part="half_A"' vent_deflector.scad
openscad -o stl/vent_deflector_12in_half_B.stl -D 'part="half_B"' vent_deflector.scad
python3 ../scripts/stl2bin.py stl/*.stl
```
