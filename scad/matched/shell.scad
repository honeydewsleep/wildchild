// =====================================================================
// Matched series - SHELL (original Energy Ring outer dimensions)
//
// The original shell just rests on the chassis by gravity; this one
// screws on. In-use coords: z=0 at the open rim (which seats on the
// chassis skirt), +z up, closed top at z=50 with the ring stem hole.
//
// - Female thread in the mouth: same thread system as series A, so
//   the same test collar calibrates plate_clock_adjust.
// - USB hole in the wall at notch_angle: the clocked thread stops the
//   shell with this hole facing the ESP32's USB port in the chassis.
// - Stem collar under the top face: 10mm deep bore with three crush
//   ribs grips the ring stem (the original had only a 3mm floor).
//
// part = "shell"
// =====================================================================
include <../params.scad>
use <../lib/threads.scad>

part = "shell";

r_rim = m_shell_od_rim/2;    // 47.5 at the desk end
r_top = m_shell_od_top/2;    // 43.3 at the top
boss_bore_r = thr_root_r + thr_clr;          // 40.3
boss_top_z  = thr_len + 1.6;

module shell_outer() {
    rotate_extrude($fn = FN_ROUND)
        polygon([
            [0, m_shell_h],
            [r_top - 1.5, m_shell_h],
            [r_top, m_shell_h - 1.5],        // top edge chamfer
            [r_rim, 0],
            [0, 0]
        ]);
}

module shell_cavity() {
    rotate_extrude($fn = FN_ROUND)
        polygon([
            [0, -EPS],
            [r_rim - m_shell_wall, -EPS],
            [r_top - m_shell_wall, m_shell_h - m_shell_top_t],
            [0, m_shell_h - m_shell_top_t]
        ]);
}

module stem_collar() {
    z0 = m_shell_h - m_shell_top_t - m_collar_h;
    translate([0, 0, z0])
        cylinder(h = m_collar_h + 1, d = m_collar_d, $fn = 96);
}

module stem_bore() {
    z0 = m_shell_h - m_shell_top_t - m_collar_h;
    difference() {
        translate([0, 0, z0 - EPS])
            cylinder(h = m_collar_h + m_shell_top_t + 2, d = m_stem_hole_d, $fn = 96);
        // crush ribs: vertical half-round beads gripping the stem
        for (a = [0, 120, 240])
            rotate([0, 0, a])
                translate([m_stem_hole_d/2 + 0.7 - m_crush_rib, 0, z0 - EPS])
                    cylinder(h = m_collar_h + m_shell_top_t + 2, d = 1.4, $fn = 24);
    }
    // entry chamfer on top for the stem
    translate([0, 0, m_shell_h - 1.2])
        cylinder(h = 1.3, d1 = m_stem_hole_d, d2 = m_stem_hole_d + 2.6, $fn = 96);
}

// internal boss ring at the mouth carrying the female thread,
// 45-degree cone transition above (prints inverted, no overhang)
module thread_boss() {
    r_int = r_rim - m_shell_wall + 0.6;
    rotate_extrude($fn = FN_ROUND)
        polygon([
            [boss_bore_r, 0],
            [r_int, 0],
            [r_int, boss_top_z + (r_int - boss_bore_r)],
            [boss_bore_r, boss_top_z]
        ]);
}

module female_thread_cut() {
    thread_female_cavity(thr_root_r, thr_depth, thr_pitch, thr_len + 0.4,
                         thr_clr, starts = 1, phase = 0,
                         steps = thr_steps, slices_per_turn = thr_slices_per_turn,
                         crest_deg = thr_crest_deg);
    thread_mouth_chamfer(thr_root_r, thr_depth, thr_clr);
}

module usb_hole_cut() {
    zc = m_usb_z + m_usb_h/2;
    rotate([0, 0, notch_angle - 270])
        rotate([90, 0, 0])
            linear_extrude(height = r_rim + 8)
                hull() {
                    for (dx = [-1, 1], dz = [-1, 1])
                        translate([dx*(m_usb_w/2 - 2.5), zc + dz*(m_usb_h/2 - 2.5)])
                            circle(2.5, $fn = 32);
                }
}

module shell_body() {
    difference() {
        union() {
            difference() { shell_outer(); shell_cavity(); }
            thread_boss();
            stem_collar();
        }
        stem_bore();
        female_thread_cut();
        usb_hole_cut();
    }
}

/* ------------------------- part selection ------------------------- */
// print-ready: inverted, top face on the bed (threads + hole face up)
if (part == "shell")
    rotate([180, 0, 0]) shell_body();
