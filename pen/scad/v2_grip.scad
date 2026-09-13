// v2 bolt pen, part 1: knurled round grip with the straight taper tip.
//   openscad -o v2_grip.stl v2_grip.scad
// z = 0 at the TIP face, +z toward the barrel (prints standing on the
// thread end, tip up). Exterior copies the click pen's grip: 15.2°
// taper, Ø10/Ø11 diamond knurl, shoulder at 45.5. Interior is the v1
// bolt body's tip interior verbatim (exit hole, refill-cone bore, spring
// seat, Ø6.88 refill bore), Ø6.6 under the thread.
include <params.scad>
use <../../scad/lib/threads.scad>

g_len = g_knurl_end + j_len;          // 53.0
tip_slope = tan(tip_half_angle);
z_cone_full = (g_knurl_r - tip_r_exit) / tip_slope;   // 12.13: where the taper reaches the crest radius

// --- exterior ------------------------------------------------------
module smooth_body() {
    // taper cone into a plain Ø11 cylinder up to the shoulder
    cylinder(h = z_cone_full, r1 = tip_r_exit, r2 = g_knurl_r);
    translate([0, 0, z_cone_full - EPS]) cylinder(h = g_knurl_end - z_cone_full + EPS, r = g_knurl_r);
}

// 2D: circle r with n V-notches of `depth`, `land` deg of flat crest between them
module knurl_profile(r, depth, n, land) {
    period = 360 / n;
    polygon([for (k = [0:n-1]) each [
        [r * cos(k*period - land/2), r * sin(k*period - land/2)],
        [r * cos(k*period + land/2), r * sin(k*period + land/2)],
        [(r - depth) * cos(k*period + period/2), (r - depth) * sin(k*period + period/2)]]]);
}

// one helix family of grooves = twisted extrusion of the notched disc
module knurl_family(sign) {
    h = g_knurl_end - g_knurl_start + EPS;
    translate([0, 0, g_knurl_start])
        linear_extrude(height = h, twist = sign * 360 * h / g_knurl_lead,
                       slices = ceil(h / 0.25), convexity = 10)
            knurl_profile(g_knurl_r + EPS, g_knurl_depth + EPS, g_knurl_n, g_knurl_land);
}

module knurl_keep() {   // material to keep: both families in the knurl zone, everything elsewhere
    union() {
        intersection() { knurl_family(+1); knurl_family(-1); }
        translate([0, 0, -1]) cylinder(h = g_knurl_start + 1, r = g_knurl_r + 1);
        translate([0, 0, g_knurl_end - EPS]) cylinder(h = 20, r = g_knurl_r + 1);
    }
}

module male_thread() {
    translate([0, 0, g_knurl_end - EPS])
        intersection() {
            thread_male(j_root_r, j_depth, j_pitch, j_len + EPS, 1, 0, 240, 120, j_crest_deg);
            thread_tip_taper(j_root_r, j_depth, j_len + EPS, 1.2);
        }
}

// --- interior (v1 tip interior, measured from the tip) --------------
module bore() {
    L = body_len;   // v1 z positions were from the back; convert: from tip = L - z
    translate([0, 0, -1])                    cylinder(h = 1 + (L - bore_z4b) + EPS, r = bore_r_exit);
    translate([0, 0, L - bore_z4b - EPS])    cylinder(h = bore_z4b - bore_z4 + 2*EPS, r1 = bore_r_exit, r2 = bore_r_tip);
    translate([0, 0, L - bore_z4 - EPS])     cylinder(h = bore_z4 - bore_z3b + 2*EPS, r = bore_r_tip);
    translate([0, 0, L - bore_z3b - EPS])    cylinder(h = bore_z3b - bore_z3 + 2*EPS, r1 = bore_r_tip, r2 = bore_r_spring);
    translate([0, 0, L - bore_z3 - EPS])     cylinder(h = bore_z3 - bore_z2 + 2*EPS, r = bore_r_spring);
    translate([0, 0, L - bore_z2 - EPS])     cylinder(h = g_knurl_end - (L - bore_z2) + 2*EPS, r = bore_r_refill);
    translate([0, 0, g_knurl_end - EPS])     cylinder(h = j_len + 2, r = g_thread_bore_r);
}

module grip() {
    difference() {
        union() {
            intersection() { smooth_body(); knurl_keep(); }
            male_thread();
        }
        bore();
    }
}

grip();
