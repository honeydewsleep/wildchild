// =====================================================================
// Matched series - DOUBLE-SIDED RING (original Ø180 envelope + stem)
//
// The original ring has a closed front face and one snap-in diffuser
// tray on the back. This ring is open on BOTH faces and takes two
// diffuser trays (same snap interface as the original diffuser), so
// it glows front and back. The stem is dimensionally identical to
// the original (Ø27.8 x 16, Ø20 wire bore), so this ring also fits
// an unmodified original base - and the original single-sided ring
// fits the new threaded base.
//
// Construction: outer rim + inner rim, tied by 3 thin mid-depth
// spokes and the stem boss; the two snapped-in diffuser trays make
// the assembly rigid. COB strip sticks to the inside of the outer
// rim firing inward; the strip's start/end lands at the wire hole at
// the bottom (stem angle), wires down the stem bore into the base.
//
// Print flat on a face; spokes print as short bridges.
//
// part = "ring_ds" | "diffuser_ds"   (print 2 diffusers per ring)
// =====================================================================
include <../params.scad>

part = "ring_ds";

R  = m_ring_od/2;            // 90
Ri = m_ring_id/2;            // 58
T  = m_ring_t;               // 40
stem_r0 = R + m_boss_len;    // 107.5 - boss ends, stem tube starts
stem_r1 = stem_r0 + m_stem_len;

module rim_walls() {
    difference() {
        cylinder(h = T, r = R, $fn = FN_ROUND);
        translate([0, 0, -EPS]) cylinder(h = T + 2*EPS, r = R - m_rim_wall, $fn = FN_ROUND);
    }
    difference() {
        cylinder(h = T, r = Ri + m_rim_wall, $fn = FN_ROUND);
        translate([0, 0, -EPS]) cylinder(h = T + 2*EPS, r = Ri, $fn = FN_ROUND);
    }
}

module spokes() {
    for (a = [90, 225, 315])
        rotate([0, 0, a])
            translate([Ri + 1, -m_spoke_w/2, T/2 - m_spoke_t/2])
                cube([R - m_rim_wall - Ri, m_spoke_w, m_spoke_t]);
}

// helper: solid built along +X (axis at y=0,z=0), then swung to the
// stem angle with the axis lifted to the ring mid-plane
module at_stem(r_from, length, d1, d2) {
    rotate([0, 0, notch_angle]) translate([0, 0, T/2])
        rotate([0, 90, 0])
            translate([0, 0, r_from])
                cylinder(h = length, d1 = d1, d2 = d2, $fn = 96);
}

module boss_and_stem_solid() {
    intersection() {
        union() {
            // dome boss: wide against the outer rim, narrowing outward
            at_stem(R - 2.5, stem_r0 - (R - 2.5), m_boss_d, m_stem_d + 2);
            // stem tube (solid; bored later)
            at_stem(stem_r0 - 1, m_stem_len + 1, m_stem_d, m_stem_d);
            // slight entry chamfer at the tip
        }
        // clip the boss flush with the ring faces, as the original
        translate([-250, -250, 0]) cube([500, 500, T]);
    }
}

module wire_bores() {
    // wide bore through the stem
    at_stem(stem_r0 - 2, m_stem_len + 3, m_stem_bore, m_stem_bore);
    // narrower channel continuing through boss + outer rim into the
    // light cavity - also where the strip's wires start/end
    at_stem(R - m_rim_wall - 2.5, m_boss_len + 4, 10, 10);
}

module ring_ds() {
    difference() {
        union() {
            rim_walls();
            spokes();
            boss_and_stem_solid();
        }
        wire_bores();
    }
}

/* ----------------- snap-in diffuser tray (print 2) ----------------- */
module skirt_with_beads(r_in, r_out, bead_on_inside) {
    difference() {
        cylinder(h = m_dif_face_t + m_dif_skirt_h, r = r_out, $fn = FN_ROUND);
        translate([0, 0, -EPS])
            cylinder(h = m_dif_face_t + m_dif_skirt_h + 2*EPS, r = r_in, $fn = FN_ROUND);
    }
    for (bz = m_dif_bead_z)
        translate([0, 0, m_dif_face_t + bz])
            rotate_extrude($fn = FN_ROUND)
                translate([bead_on_inside ? r_in : r_out, 0])
                    circle(d = 2*m_dif_bead, $fn = 16);
}

module diffuser_ds() {
    // face plate
    difference() {
        cylinder(h = m_dif_face_t, r = R, $fn = FN_ROUND);
        translate([0, 0, -EPS]) cylinder(h = m_dif_face_t + 2*EPS, r = Ri, $fn = FN_ROUND);
    }
    // inner skirt: slides OVER the inner rim, beads grip inward
    skirt_with_beads(m_dif_in_w[0] + diffuser_clr, m_dif_in_w[1], true);
    // outer skirt: slides INSIDE the outer rim, beads grip outward
    skirt_with_beads(m_dif_out_w[0], m_dif_out_w[1] - diffuser_clr, false);
}

/* ------------------------- part selection -------------------------- */
if (part == "ring_ds")
    ring_ds();
else if (part == "diffuser_ds")
    diffuser_ds();
