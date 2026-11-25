# Fiber metering / pre-opening wand

Hand-held attachment for the 4" suction hose of a pillow blower. It meters
how much siliconized microfiber reaches the fan at once and pre-opens the
bale layers, so the fan blades can finish the job without a carding pass.

Modular stack, every joint is the same screw thread (same 45° profile and
0.30 clearance as the test-printed lamp base thread):

    funnel  ->  stage (one or more, any order)  ->  base (handle + hose cuff)

| File | What it is |
|---|---|
| `stl/cuff_test.stl` | Hose cuff only. Print first to check the hose fit. |
| `stl/funnel.stl` | Bell mouth. Prints mouth-down. |
| `stl/base.stl` | 45° pistol grip, reducer, 4" hose cuff. |
| `stl/stage_fingers.stl` | A: three staggered rows of swept picker fingers. |
| `stl/stage_grid.stl` | B: two layers of facing swept bars, ~26 mm grid. |
| `stl/stage_baffle.stl` | C: three 45° comb-edged shelves in a spiral. |
| `stl/stage_cyclone.stl` | D: tangential air slots + short wall teeth. |

All parts print as exported (upstream end on the bed), no supports.
Everything is parametric in `scad/fiber_opener.scad` (`hose_id`, finger
lengths, shelf coverage, slot count/width, ...). `scad/preview.scad`
renders the half-section images in `preview/` from the STLs.

    openscad -o stl/stage_fingers.stl -D 'part="stage_fingers"' scad/fiber_opener.scad
    python3 ../scripts/stl2bin.py stl/*.stl
