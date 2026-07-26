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
use <../lib/threads.scad>

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
        difference() {
        union() {
            // smooth bulb: oblate spheroid centred ON the rim surface,
            // hulled to the Ø34 stem shoulder disc. Like the original,
            // it wraps over the curved rim (protruding a little past
            // the Ø180 silhouette at the sides) - a flat-based cone
            // here either leaves proud corners or pinches to a
            // zero-width cusp at the rim tangent. The spheroid bites
            // ~14mm into the cavity for a strong weld to the rim.
            hull() {
                rotate([0, 0, notch_angle]) translate([0, 0, T/2])
                    rotate([0, 90, 0]) {
                        translate([0, 0, R])
                            scale([1, 1, 0.5]) sphere(d = 56, $fn = 96);
                        translate([0, 0, stem_r0 - 2])
                            cylinder(h = 2, d = 34, $fn = 96);
                    }
            }
            // threaded stem: crest = Ø27.8 (original stem OD), so it
            // still push-fits a plain shell hole; screws into the
            // shell_threaded collar. Thread phase carries
            // ring_clock_adjust; datum = the shoulder plane.
            rotate([0, 0, notch_angle]) translate([0, 0, T/2])
                rotate([0, 90, 0]) translate([0, 0, stem_r0])
                    intersection() {
                        thread_male(stem_thr_root_r, stem_thr_depth,
                                    stem_thr_pitch, stem_thr_len,
                                    starts = 1, phase = ring_clock_adjust,
                                    steps = 180, slices_per_turn = 90);
                        thread_tip_taper(stem_thr_root_r, stem_thr_depth,
                                         stem_thr_len);
                    }
            // plain pilot tip at root diameter, chamfered
            at_stem(stem_r0 + stem_thr_len - EPS,
                    m_stem_len - stem_thr_len - 1,
                    2*stem_thr_root_r, 2*stem_thr_root_r);
            at_stem(stem_r0 + m_stem_len - 1 - EPS, 1,
                    2*stem_thr_root_r, 2*stem_thr_root_r - 3);
        }
        // SURFACE-MOUNT like the original: remove everything inboard
        // of the rim's inner face (+0.05), so the bulb welds through
        // the 2mm wall but leaves the light cavity completely clear -
        // the diffuser trays keep full-circle skirts, no gap needed
        translate([0, 0, -2])
            cylinder(h = T + 4, r = R - m_rim_wall + 0.05, $fn = FN_ROUND);
        }
        // clip the boss flush with the ring faces, as the original
        translate([-250, -250, 0]) cube([500, 500, T]);
    }
}

// The frustum's wide end is flat but the rim it meets is curved, so
// its corners would stand proud of the Ø180 surface at the sides.
// This cutter removes everything outside the ring's outer cylinder
// that lies above the rim's bottom tangent (y > -R), so the boss
// wraps flush with the rim curve and only necks out below it.
// stem + boss only (no rims), for fast thread fit checks
module stem_only() {
    difference() {
        boss_and_stem_solid();
        wire_bores();
    }
}

module wire_bores() {
    // one constant Ø20 passage from the light cavity straight through
    // bulb, rim and stem into the base - as wide as the stem's thread
    // root allows without growing the stem. Starts just outside the
    // inner rim so it opens through the bulb's cavity-side face.
    at_stem(Ri + m_rim_wall + 0.5,
            stem_r1 - (Ri + m_rim_wall + 0.5) + 2,
            m_stem_bore, m_stem_bore);
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
    // face plate (full circle - it covers the bulb's flush face too)
    difference() {
        cylinder(h = m_dif_face_t, r = R, $fn = FN_ROUND);
        translate([0, 0, -EPS]) cylinder(h = m_dif_face_t + 2*EPS, r = Ri, $fn = FN_ROUND);
    }
    // inner skirt: slides OVER the inner rim, beads grip inward
    skirt_with_beads(m_dif_in_w[0] + diffuser_clr, m_dif_in_w[1], true);
    // outer skirt: slides INSIDE the outer rim, beads grip outward.
    // Full circle - the bulb is surface-mounted outside the wall, so
    // nothing intrudes into the cavity.
    skirt_with_beads(m_dif_out_w[0], m_dif_out_w[1] - diffuser_clr, false);
}

/* ------------------------- part selection -------------------------- */
if (part == "ring_ds")
    ring_ds();
else if (part == "diffuser_ds")
    diffuser_ds();
