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
// part = "shell"           crush-rib collar: ring stem push-fits
//                          (accepts original rings and the threaded
//                          ring's crest alike)
// part = "shell_threaded"  female thread in the collar: the ring
//                          SCREWS in and stops facing forward
//                          (deterministic, trimmed by ring_clock_adjust)
// part = "shell_free"      plain free-spinning bore + shallow collar:
//                          aim the ring anywhere, then clamp it with
//                          stem_locknut.stl from inside the base
// =====================================================================
include <../params.scad>
use <../lib/threads.scad>

part = "shell";

RB = m_ring_od/2 + m_boss_len;   // ring centre to stem shoulder (107.5)

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

module stem_collar(h = m_collar_h, d = m_collar_d) {
    z0 = m_shell_h - m_shell_top_t - h;
    translate([0, 0, z0])
        cylinder(h = h + 1, d = d, $fn = 96);
}

// free-spinning bore for the locknut option: the stem drops through,
// rotates to taste, and the nut clamps against the collar's bottom face
module stem_bore_free() {
    z0 = m_shell_h - m_shell_top_t - free_collar_h;
    translate([0, 0, z0 - EPS])
        cylinder(h = free_collar_h + m_shell_top_t + 2, d = free_bore_d, $fn = 96);
    translate([0, 0, m_shell_h - 1.2])
        cylinder(h = 1.3, d1 = free_bore_d, d2 = free_bore_d + 2.6, $fn = 96);
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

// Female stem thread, built through the SAME transform chain as the
// assembled ring's stem (ring centre directly above the top face,
// shoulder seated on it) - so male and female nest exactly at the
// modeled position and the seated facing is deterministic.
module stem_thread_cavity() {
    translate([0, 0, m_shell_h + RB])
        rotate([90, 0, 0])
            rotate([0, 0, notch_angle])
                rotate([0, 90, 0])
                    translate([0, 0, RB])
                        thread_female_cavity(stem_thr_root_r, stem_thr_depth,
                                             stem_thr_pitch,
                                             m_collar_h + m_shell_top_t,
                                             stem_thr_clr, starts = 1, phase = 0,
                                             steps = 180, slices_per_turn = 90);
    // mouth chamfer at the top face
    translate([0, 0, m_shell_h - 1.4])
        cylinder(h = 1.5, d1 = 2*(stem_thr_root_r + stem_thr_clr),
                 d2 = 2*(stem_thr_root_r + stem_thr_clr) + 4.5, $fn = 96);
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

// bottom port window: straight rounded-rect tunnel through wall+boss
// at notch_angle, plus a funneled mouth on the exterior (hull of a
// wide outer slab and a thin window-sized slab just inside the skin)
module port_rrect_2d(w, h, zc) {
    hull()
        for (dx = [-1, 1], dz = [-1, 1])
            translate([dx*(w/2 - 3), zc + dz*(h/2 - 3)])
                circle(3, $fn = 32);
}

module port_window_cut() {
    rotate([0, 0, notch_angle - 270]) rotate([90, 0, 0]) {
        linear_extrude(height = r_rim + 8)
            port_rrect_2d(m_port_w, m_port_h, m_port_zc);
        hull() {
            translate([0, 0, r_rim - 1.8]) linear_extrude(height = 9.8)
                port_rrect_2d(m_port_w + 2*m_port_flare,
                              m_port_h + 2*m_port_flare, m_port_zc);
            translate([0, 0, r_rim - 3.6]) linear_extrude(height = 0.1)
                port_rrect_2d(m_port_w, m_port_h, m_port_zc);
        }
    }
}

// round radial hole in the shell wall at a given angle/height
module wall_round_hole(angle, z, d) {
    rotate([0, 0, angle - 270])
        rotate([90, 0, 0])
            translate([0, z, 0])
                linear_extrude(height = r_rim + 8)
                    circle(d = d, $fn = 64);
}

module button_hole_cut() { wall_round_hole(m_button_angle, m_button_z, m_button_d); }
module jack_hole_cut()   { wall_round_hole(notch_angle, m_jack_z, m_jack_d); }

// stem_mode: "ribs" (push fit) | "threaded" (screws in) | "free"
// (spins freely, clamped by stem_locknut from inside)
module shell_body(stem_mode = "ribs") {
    difference() {
        union() {
            difference() { shell_outer(); shell_cavity(); }
            thread_boss();
            if (stem_mode == "free")
                stem_collar(free_collar_h, free_collar_d);
            else
                stem_collar();
        }
        if (stem_mode == "threaded") stem_thread_cavity();
        else if (stem_mode == "free") stem_bore_free();
        else stem_bore();
        female_thread_cut();
        if (m_usb_notch) usb_hole_cut();
        if (m_port_window) port_window_cut();
        if (m_button_hole) button_hole_cut();
        if (m_jack_hole) jack_hole_cut();
    }
}

/* ------------------------- part selection ------------------------- */
// print-ready: inverted, top face on the bed (threads + hole face up)
if (part == "shell")
    rotate([180, 0, 0]) shell_body("ribs");
else if (part == "shell_threaded")
    rotate([180, 0, 0]) shell_body("threaded");
else if (part == "shell_free")
    rotate([180, 0, 0]) shell_body("free");
