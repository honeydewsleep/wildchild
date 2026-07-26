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
use <matched/ring_ds.scad>

mode = "clearance";

// seated threaded ring stem, in shell coordinates (shoulder on the
// shell top face); lift = extra z to avoid degenerate contact sheets
module seated_stem(lift = 0.02) {
    RBc = m_ring_od/2 + m_boss_len;
    translate([0, 0, m_shell_h + RBc + lift])
        rotate([90, 0, 0])
            translate([0, 0, -m_ring_t/2])
                stem_only();
}

// standalone replica of the threaded collar region (much cheaper for
// CGAL than intersecting the whole shell): collar + top plate disc
// with the same female stem-thread cavity the shell uses
module collar_chunk(threaded = true) {
    difference() {
        union() {
            translate([0, 0, m_shell_h - m_shell_top_t - m_collar_h])
                cylinder(h = m_collar_h, d = m_collar_d, $fn = 96);
            translate([0, 0, m_shell_h - m_shell_top_t])
                cylinder(h = m_shell_top_t, d = m_collar_d + 8, $fn = 96);
        }
        stem_thread_cavity();
    }
}

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
// ring stem screwed fully into the threaded shell collar
else if (mode == "s_clearance")
    intersection() {
        collar_chunk(true);
        seated_stem(0.02);
    }
else if (mode == "s_engagement")
    intersection() {
        // stem thread ribs vs an un-threaded collar plug
        translate([0, 0, m_shell_h - m_shell_top_t - m_collar_h])
            difference() {
                cylinder(h = m_collar_h + m_shell_top_t - 0.1, d = m_collar_d, $fn = 96);
                translate([0, 0, -EPS])
                    cylinder(h = m_collar_h + m_shell_top_t + 2,
                             r = stem_thr_root_r + stem_thr_clr, $fn = 96);
            }
        seated_stem(0.02);
    }
