# Vent deflector, 12" sweep remix

Remix of the **6-20 Expandable Vent Cover / Vent Deflector**
([MakerWorld 2722921](https://makerworld.com/en/models/2722921-6-20-expandable-vent-cover-vent-deflector),
6-12" profile, `original/`). The two telescoping halves are kept exactly as
designed: same 6-12" slide, same interlocking rails, same end caps, same magnet
bosses and pockets. The only change is the **curved sweep of the scoop: 4"
(R 100 mm) becomes 12" (R 304.8 mm)**, so the deflector reaches 12" off the wall
and 12" along it instead of 4".

![before / after](before_after.png)

## Files

| File | What |
|---|---|
| `stl/vent_deflector_12in_sweep_outer.stl` | outer half (the original "Right Side"), print cap down |
| `stl/vent_deflector_12in_sweep_inner.stl` | inner half (the original "Left Side"), print cap down |
| `sweep_remix.py` | regenerates both STLs from the original 3MF; `python3 sweep_remix.py [file.3mf] [sweep_inches]` |
| `original/` | the MakerWorld 3MF this is derived from |

Footprint of each half is 305 × 305 mm (cap), 150 mm tall standing, like the
original. That fits the H2D bed (350 × 320); it does **not** fit a 256 mm bed.
Magnets are the same as the original's pockets: Ø6.7 × 1.9 mm, for 6 × 2 mm discs.
The two cap-mounted magnet bosses were moved to the middle of the (now 12") wall
face, the same relative spot they had on the 4" face; the inner half's hood boss
stays at the hood.

## How the stretch was done

Mesh-level transform, not a redraw, so nothing that the slide depends on was
re-modelled. Both halves are placed in one frame (shared arc centre, hood at 90°,
exit edge at 180°) and every vertex is mapped in polar coordinates:

- radius: the wall band is offset outward by 204.8 mm (wall stays 2 mm thick,
  rails keep their depth); the flat cap inside is scaled to meet it;
- angle: the bands holding the hood lip and the mid-arc rails keep their original
  arc length; the plain arc between them is stretched to make up the 90°.

Both halves get the identical map, so the nesting fit is unchanged. Checks run by
the script: nested-profile overlap at z = 0 is 0.011 mm² before and after; 3D
interference volume at 2, 60 and 120 mm of slide matches the original within
0.1 mm³ (about 1 mm³, i.e. rail contact only); both outputs watertight.

The curvature itself is of course different (R 305 vs 100), so the rails now sit
on a flatter wall. The hooks' cross-sections are preserved to ~0.2 mm; the
inner/outer radial clearance (0.19 mm) is unchanged.
