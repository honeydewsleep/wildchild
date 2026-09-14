// Bolt-action pen body, hex "pencil" remix.
//   openscad -o body_hex.stl -D 'part="body"' body.scad
// Interior is a verbatim copy of the reference "Bolt Body.stl"; the
// exterior is a rounded hexagon with a straight 15.2° pencil taper.
include <params.scad>

part = "body";   // "body" | "body_round" (reference-style round exterior, same remix code path)

// ------------------------------------------------------------ 2D hex
// Regular hexagon with flats at 30+60k deg (circle($fn=6) puts a corner
// at 0 deg), rotated so one flat faces hex_clock.
module rhex2d(af = hex_af, rc = hex_corner_r) {
    rotate(hex_clock - 270)
        offset(r = rc) offset(delta = -rc)
            circle(r = (af / 2) / cos(30), $fn = 6);
}

// --------------------------------------------------------- exterior
module body_outer() {
    cone_r0 = tip_r_exit + body_len * tan(tip_half_angle);
    intersection() {
        union() {
            // 45° chamfer on the back rim
            hull() {
                linear_extrude(EPS) offset(r = -back_chamfer) rhex2d();
                translate([0, 0, back_chamfer]) linear_extrude(EPS) rhex2d();
            }
            translate([0, 0, back_chamfer - EPS])
                linear_extrude(body_len - back_chamfer + EPS) rhex2d();
        }
        // straight taper: the cone simply "sharpens" the hex prism
        cylinder(h = body_len, r1 = cone_r0, r2 = tip_r_exit);
    }
}

module round_outer() {   // reference Ø11.52 cylinder, for A/B comparison renders
    cone_r0 = tip_r_exit + body_len * tan(tip_half_angle);
    intersection() {
        cylinder(h = body_len, r = 5.76);
        cylinder(h = body_len, r1 = cone_r0, r2 = tip_r_exit);
    }
}

// ------------------------------------------------------------- bore
module bore() {
    translate([0, 0, -1])              cylinder(h = bore_z1 + 1,                r = bore_r_plunger);
    translate([0, 0, bore_z1 - EPS])   cylinder(h = bore_z2 - bore_z1 + 2*EPS,   r = bore_r_refill);
    translate([0, 0, bore_z2 - EPS])   cylinder(h = bore_z3 - bore_z2 + 2*EPS,   r = bore_r_spring);
    translate([0, 0, bore_z3 - EPS])   cylinder(h = bore_z3b - bore_z3 + 2*EPS,  r1 = bore_r_spring, r2 = bore_r_tip);
    translate([0, 0, bore_z3b - EPS])  cylinder(h = bore_z4 - bore_z3b + 2*EPS,  r = bore_r_tip);
    translate([0, 0, bore_z4 - EPS])   cylinder(h = bore_z4b - bore_z4 + 2*EPS,  r1 = bore_r_tip, r2 = bore_r_exit);
    translate([0, 0, bore_z4b - EPS])  cylinder(h = body_len - bore_z4b + 1,    r = bore_r_exit);
}

include <lib/track.scad>

// ------------------------------------------------------------ parts
module body(outer = "hex") {
    difference() {
        if (outer == "hex") body_outer(); else round_outer();
        bore();
        wall_cut(slot_angle,   slot_out,   slot_in);
        wall_cut(slot_angle,   notch_out,  notch_in);
        wall_cut(window_angle, window_out, window_in);
    }
}

if (part == "body")        body("hex");
if (part == "body_round")  body("round");
if (part == "cuts_only")   { wall_cut(slot_angle, slot_out, slot_in); wall_cut(slot_angle, notch_out, notch_in); wall_cut(window_angle, window_out, window_in); }
