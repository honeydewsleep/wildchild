// v2 bolt pen, part 2: hex barrel with the bolt track, sealed back.
//   openscad -o v2_barrel.stl        -D 'part="barrel"'        v2_barrel.scad
//   openscad -o v2_barrel_window.stl -D 'part="barrel_window"' v2_barrel.scad
// z = 0 at the BACK face (on the bed), +z toward the grip. Exterior:
// perfectly round Ø10 back face with a 45° chamfer into the 10.4 AF
// rounded hex; hex up to the blend; round Ø11 neck (= knurl crest) at
// the joint carrying the female thread. Bolt track = v1 (same z from
// the back). Bore Ø8.4 to the thread so the plunger goes in from the
// front before the grip screws on.
include <params.scad>
include <lib/track.scad>
use <../../scad/lib/threads.scad>

part = "barrel";

module rhex2d(af = b_hex_af, rc = b_hex_corner) {
    rotate(hex_clock - 270) offset(r = rc) offset(delta = -rc) circle(r = (af / 2) / cos(30), $fn = 6);
}

module outer() {
    z_blend0 = b_joint_z - b_neck_len - b_blend_len;   // 61.55
    intersection() {
        union() {
            // hex prism from the back up to the blend
            linear_extrude(z_blend0 + EPS) rhex2d();
            // blend hex -> round neck (convex hull = exact morph)
            hull() {
                translate([0, 0, z_blend0]) linear_extrude(EPS) rhex2d();
                translate([0, 0, b_joint_z - b_neck_len]) cylinder(h = EPS, r = g_knurl_r);
            }
            // round neck up to the joint face
            translate([0, 0, b_joint_z - b_neck_len - EPS]) cylinder(h = b_neck_len + EPS, r = g_knurl_r);
        }
        // round bed face + 45° chamfer: cone growing from v2_back_face_r
        cylinder(h = b_joint_z + 1, r1 = v2_back_face_r, r2 = v2_back_face_r + b_joint_z + 1);
    }
}

module bore() {
    translate([0, 0, v2_back_wall]) cylinder(h = b_joint_z - v2_back_wall + 1, r = b_bore_r);
    // female thread cavity, mouth at the joint face
    translate([0, 0, b_joint_z]) mirror([0, 0, 1]) {
        thread_female_cavity(j_root_r, j_depth, j_pitch, j_len, j_clr, 1, 0, 240, 120, j_crest_deg);
        thread_mouth_chamfer(j_root_r, j_depth, j_clr, 0.6);
    }
}

module ink_windows() {
    for (a = w_angles) rotate([0, 0, a]) rotate([0, -90, 0])   // slot lying in the (radial x, z) plane at angle a
        translate([-(w_z1 + w_z0) / 2, 0, -8]) linear_extrude(16)
            hull() { translate([-(w_z1 - w_z0) / 2 + w_width / 2, 0]) circle(d = w_width);
                     translate([ (w_z1 - w_z0) / 2 - w_width / 2, 0]) circle(d = w_width); }
}

module insignia() {
    if (v2_insignia != "")
        translate([0, 0, -EPS]) linear_extrude(v2_insignia_depth + EPS)
            resize([v2_insignia_size, 0], auto = true) mirror([1, 0]) import(v2_insignia, center = true);
}

module barrel(windows = false) {
    difference() {
        outer();
        bore();
        wall_cut(slot_angle,   slot_out,   slot_in);
        wall_cut(slot_angle,   notch_out,  notch_in);
        wall_cut(window_angle, window_out, window_in);
        if (windows) ink_windows();
        insignia();
    }
}

if (part == "barrel")        barrel(false);
if (part == "barrel_window") barrel(true);
