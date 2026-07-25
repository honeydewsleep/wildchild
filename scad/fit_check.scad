// =====================================================================
// Automated interference / engagement checks (not a printable part)
//
// mode = "clearance"  : intersection of the seated plate with the base
//                       -> MUST be empty (threads clear each other)
// mode = "engagement" : intersection of the plate thread with the
//                       base's un-threaded boss ring -> MUST be
//                       non-empty (the thread ribs actually engage)
//
// The plate is placed in its fully-seated position: flange datum face
// (z = plate_t in plate coords) coincident with the base rim (z = 0).
// =====================================================================
include <params.scad>
use <lib/threads.scad>
use <base.scad>
use <bottom_plate.scad>
use <matched/shell.scad>
use <matched/chassis.scad>

mode = "clearance";

// seated position, dropped 0.02 so the coincident flange/rim faces
// don't produce a degenerate zero-volume contact sheet in the output
module seated_plate() {
    translate([0, 0, -plate_t - 0.02]) bottom_plate(true);
}

// base boss ring WITHOUT the female thread cut, for engagement check
module bare_boss() {
    difference() {
        cylinder(h = thr_len, r = base_od/2 - base_wall + 0.5, $fn = FN_ROUND);
        translate([0, 0, -EPS])
            cylinder(h = thr_len + 2*EPS, r = thr_root_r + thr_clr, $fn = FN_ROUND);
    }
}

if (mode == "clearance")
    intersection() {
        test_collar();   // bottom 12 mm of the base: all mating geometry
        seated_plate();
    }
else if (mode == "engagement")
    intersection() {
        bare_boss();
        seated_plate();
    }
// matched series: shell screwed fully onto the chassis.
// Shell rim plane (z=0 in shell coords) seats on the chassis skirt
// top (z = m_skirt_h); raised 0.02 to avoid a degenerate contact sheet.
else if (mode == "m_clearance")
    intersection() {
        chassis_std();
        translate([0, 0, m_skirt_h + 0.02]) shell_body();
    }
else if (mode == "m_engagement")
    intersection() {
        // chassis thread ribs vs the shell's un-threaded boss ring
        translate([0, 0, m_skirt_h + 0.02]) difference() {
            cylinder(h = thr_len, r = m_shell_od_rim/2 - m_shell_wall + 0.5, $fn = FN_ROUND);
            translate([0, 0, -EPS])
                cylinder(h = thr_len + 2*EPS, r = thr_root_r + thr_clr, $fn = FN_ROUND);
        }
        chassis_std();
    }
