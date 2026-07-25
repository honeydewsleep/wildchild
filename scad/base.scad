// =====================================================================
// Energy Ring Remix - main base unit (houses the ESP32 on the plate)
//
// z=0 is the open bottom rim where the screw-on bottom plate seats.
// Internal (female) thread lives in a boss ring just inside the wall.
// The cable notch at theta=270 is the lower half of the cable opening;
// the plate's wider notch forms the other half once screwed home.
//
// part = "base"          split cable notch (pairs with notched plate)
// part = "base_wallhole" enclosed cable window fully in the wall,
//                        above the plate (pairs with the plain plate,
//                        no clocking needed at all)
// part = "test_collar"   bottom 12 mm of the base only - cheap print
//                        for thread fit + clock calibration
// =====================================================================
include <params.scad>
use <lib/threads.scad>

part = "base";  // overridden with -D on the command line

base_ir      = base_od/2 - base_wall;            // 43.6
boss_bore_r  = thr_root_r + thr_clr;             // 40.3
boss_top_z   = thr_len + 1.6;                    // 8.6

module base_shell() {
    difference() {
        cylinder(h = base_h, d = base_od, $fn = FN_ROUND);
        // hollow interior, leaves the closed top
        translate([0, 0, -EPS])
            cylinder(h = base_h - base_top_t + EPS, r = base_ir, $fn = FN_ROUND);
    }
}

// internal boss carrying the female thread, with 45-degree cone
// transition above it (base prints inverted, so the cone avoids an
// internal overhang ring)
module thread_boss() {
    rotate_extrude($fn = FN_ROUND)
        polygon([
            [boss_bore_r, 0],
            [base_ir + 0.5, 0],
            [base_ir + 0.5, boss_top_z + (base_ir - boss_bore_r)],
            [boss_bore_r, boss_top_z]
        ]);
}

// pocket + reinforcing block under the top face that grips the ring tab
module slot_block() {
    w = slot_len + 5;
    d = slot_w + 5;
    h = slot_depth + 3;
    translate([-w/2, -d/2, base_h - h])
        cube([w, d, h]);
}

module slot_pocket() {
    translate([-slot_len/2, -slot_w/2, base_h - slot_depth])
        cube([slot_len, slot_w, slot_depth + 1]);
    // wire passage from slot floor into the cavity
    translate([0, 0, base_h - slot_depth - 6])
        cylinder(h = 7, d = slot_wire_d, $fn = 48);
}

// radial cutter for the open-bottom cable notch (half the cable hole);
// extrudes toward -Y, then rotates into place around the base axis
module wall_notch_cut(width, height) {
    rotate([0, 0, notch_angle - 270])
        rotate([90, 0, 0])
            linear_extrude(height = base_od)
                rounded_slot_2d(width, height, 3);
}

// enclosed rounded-rect window fully in the wall, above the plate thread
module wall_window_cut() {
    zc = 16.5; wh = 9;
    rotate([0, 0, notch_angle - 270])
        rotate([90, 0, 0])
            linear_extrude(height = base_od)
                hull() {
                    for (dx = [-1, 1], dz = [-1, 1])
                        translate([dx*(notch_w/2 - 3), zc + dz*(wh/2 - 3)])
                            circle(3, $fn = 32);
                }
}

module female_thread_cut() {
    thread_female_cavity(thr_root_r, thr_depth, thr_pitch, thr_len + 0.4,
                         thr_clr, starts = 1, phase = 0,
                         steps = thr_steps, slices_per_turn = thr_slices_per_turn,
                         crest_deg = thr_crest_deg);
    thread_mouth_chamfer(thr_root_r, thr_depth, thr_clr);
}

module base_body(split_notch = true) {
    difference() {
        union() {
            base_shell();
            thread_boss();
            slot_block();
        }
        slot_pocket();
        female_thread_cut();
        if (split_notch)
            wall_notch_cut(notch_w, notch_h);
        else
            wall_window_cut();
    }
}

// bottom 12 mm only: thread + rim + notch, for calibration prints
module test_collar() {
    intersection() {
        base_body(true);
        cylinder(h = 12, d = base_od + 2, $fn = 64);
    }
}

/* ------------------------- part selection ------------------------- */
// Exported STLs are print-ready: the base prints inverted (top face
// on the bed) so the internal threads and cable notch need no support.
if (part == "base")
    rotate([180, 0, 0]) base_body(true);
else if (part == "base_wallhole")
    rotate([180, 0, 0]) base_body(false);
else if (part == "test_collar")
    rotate([180, 0, 0]) test_collar();
