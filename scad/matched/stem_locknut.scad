// =====================================================================
// Matched series - STEM LOCKNUT ("position-anywhere" mounting)
//
// Pairs with shell_free.stl: the ring's threaded stem drops through
// the shell's plain bore and spins freely; aim the ring wherever you
// like, then screw this nut onto the stem from inside the base (reach
// in through the open bottom before the chassis goes on) and tighten.
// The shell top gets clamped between the ring's Ø34 shoulder outside
// and this nut inside.
//
// Wires pass straight through the nut's bore - slip the nut over the
// wire bundle BEFORE crimping/connecting, or feed the wires after.
//
// Same female thread the shell_threaded collar uses (already verified
// against the stem: empty seated intersection, 0.3 mm clearance).
//
// part = "locknut"
// =====================================================================
include <../params.scad>
use <../lib/threads.scad>

part = "locknut";

module locknut() {
    difference() {
        cylinder(h = nut_h, d = nut_od, $fn = FN_ROUND);
        // grip scallops
        for (i = [0:nut_grip_n - 1])
            rotate([0, 0, i*360/nut_grip_n])
                translate([nut_od/2, 0, -EPS])
                    cylinder(h = nut_h + 2*EPS, d = 5, $fn = 24);
        // female thread, full height
        translate([0, 0, -EPS])
            thread_female_cavity(stem_thr_root_r, stem_thr_depth,
                                 stem_thr_pitch, nut_h + 2*EPS,
                                 stem_thr_clr, starts = 1, phase = 0,
                                 steps = 180, slices_per_turn = 90);
        // entry chamfers on both faces (nut is reversible)
        bore = 2*(stem_thr_root_r + stem_thr_clr);
        translate([0, 0, -EPS])
            cylinder(h = 1.4, d1 = bore + 4, d2 = bore, $fn = 96);
        translate([0, 0, nut_h - 1.4 + EPS])
            cylinder(h = 1.4, d1 = bore, d2 = bore + 4, $fn = 96);
    }
}

if (part == "locknut")
    locknut();
