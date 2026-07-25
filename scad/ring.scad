// =====================================================================
// Energy Ring Remix - DOUBLE-SIDED ring
//
// The ring is built from TWO IDENTICAL HALVES (print ring_half twice).
// Pin/socket angles are flip-symmetric about the Y axis, so a half
// flipped over (rotate 180 about Y) mates with an unflipped one and
// the bottom tab stays at the bottom.
//
// Construction, outside to inside:
//   - opaque outer rim; the COB WS2812B strip sticks to its INNER
//     face, LEDs firing inward across the rim toward the centre
//   - each half's face flange has an annular glow window with a
//     rebate; a translucent diffuser ring drops into the rebate from
//     the inside BEFORE the halves are joined, and is captive after
//   - opaque inner rim closes the channel; light bounces inside the
//     cavity and exits through BOTH faces
//   - bottom tab (half per side) with a wire groove along the joint
//     plane, out through the tab bottom into the base's ring slot
//
// One-sided option: print one diffuser in translucent filament and
// the other in opaque white - same parts, single-sided glow.
//
// Local coords (print orientation): face on the bed at z=0, joint
// plane at z=ring_t/2.
//
// part = "ring_half" | "diffuser"
// =====================================================================
include <params.scad>

part = "ring_half";

R_o   = ring_od/2;                 // 75
R_i   = R_o - ring_rim_w;          // 50
half_t = ring_t/2;                 // 12
tab_r_in  = R_o - 2;               // tab overlaps into the outer wall
tab_r_out = R_o + tab_len + 0.5;   // 85.5

module annulus(r_in, r_out, h) {
    difference() {
        cylinder(h = h, r = r_out, $fn = FN_ROUND);
        translate([0, 0, -EPS]) cylinder(h = h + 2*EPS, r = r_in, $fn = FN_ROUND);
    }
}

module pin_boss(a) {
    rotate([0, 0, a])
        translate([boss_r_in, -pin_boss_w/2, 2.6])
            cube([boss_r_out - boss_r_in, pin_boss_w, half_t - 2.6]);
}

module ring_half() {
    difference() {
        union() {
            // face flange
            annulus(R_i, R_o, ring_face_t);
            // outer and inner rim walls
            annulus(R_o - ring_wall, R_o, half_t);
            annulus(R_i, R_i + ring_wall, half_t);
            // pin + socket bosses on the inner rim
            for (a = concat(pin_angles, socket_angles)) pin_boss(a);
            // alignment pins rising from the joint face
            for (a = pin_angles)
                rotate([0, 0, a])
                    translate([pin_r_pos, 0, half_t - EPS])
                        cylinder(h = pin_h, d = pin_d, $fn = 32);
            // half of the bottom tab
            translate([-tab_w/2, -tab_r_out, half_t - tab_t/2])
                cube([tab_w, tab_r_out - tab_r_in, tab_t/2]);
        }
        // glow window through the face
        translate([0, 0, -EPS]) annulus(win_r_in, win_r_out, ring_face_t + 2*EPS);
        // diffuser rebate on the interior side of the face
        translate([0, 0, ring_face_t - rebate_depth])
            annulus(win_r_in - rebate_lap, win_r_out + rebate_lap, rebate_depth + EPS);
        // pin sockets in the joint face
        for (a = socket_angles)
            rotate([0, 0, a])
                translate([pin_r_pos, 0, half_t - pin_h - 0.5])
                    cylinder(h = pin_h + 0.5 + EPS, d = pin_d + 2*pin_clr, $fn = 32);
        // wire groove along the joint plane: tab bottom -> LED cavity
        translate([0, -(R_o - ring_wall - 2.5), half_t])
            rotate([90, 0, 0])
                cylinder(h = tab_r_out - R_o + ring_wall + 3.5, d = wire_d, $fn = 32);
    }
}

// translucent diffuser ring - drops into the rebate from the inside.
// Four scallops on the inner edge let it pass the pin bosses on its
// way down; they end up hidden behind the opaque band (r < win_r_in).
module diffuser() {
    linear_extrude(height = diffuser_t)
        difference() {
            circle(r = win_r_out + rebate_lap - diffuser_clr, $fn = FN_ROUND);
            circle(r = win_r_in - rebate_lap + diffuser_clr, $fn = FN_ROUND);
            for (a = concat(pin_angles, socket_angles))
                rotate([0, 0, a])
                    translate([boss_r_in - 3, -(pin_boss_w/2 + 1.5)])
                        square([boss_r_out + 0.4 - (boss_r_in - 3),
                                pin_boss_w + 3]);
        }
}

/* ------------------------- part selection -------------------------- */
if (part == "ring_half")
    ring_half();
else if (part == "diffuser")
    diffuser();
