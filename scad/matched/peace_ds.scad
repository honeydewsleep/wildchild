// =====================================================================
// Matched series - PEACE SIGN LAMP (double-sided, Ø180 envelope + stem)
//
// The double-sided ring's construction language applied to a peace
// sign: the WHOLE sign is one connected hollow glow region - the outer
// band AND the three bars are lit cavities, not silhouettes - closed by
// a translucent diffuser on each face. The window openings between the
// bars stay open (through-holes) and get their own 2 mm edge walls, so
// the sign reads as a peace sign from both sides.
//
// Construction: a single 2 mm wall follows the outline and every window
// edge for the full 40 mm depth (`offset(r = -m_rim_wall)` of the
// outline gives the cavity, so walls and windows come out of one 2D
// operation). The bars tie the outer band together, so the ring's
// spokes are not needed. Stem and bulb are the ring's, verbatim: the
// outline's lowest point is the same Ø180 circle bottom, so the
// surface-mounted bulb welds through the outer wall and the threaded
// Ø27.8 stem screws into the same shell collar with the same clocking.
//
// COB strip: sticks around the inside of the outer band wall (Ø176 ≈
// 553 mm of strip), LEDs firing inward, start/end at the Ø20 wire hole
// above the stem - the 20 mm of wall between the two diffuser skirts is
// the 10.5 mm strip's channel. The cavity is connected, so light spills
// from the band into the bars; expect the bars to glow dimmer than the
// band. Do not try to route strip along the bars.
//
// Print: sign face-down flat (as exported), diffusers flat with the
// beads up. One diffuser STL serves both faces - the outline is mirror
// symmetric about the vertical axis, so you flip the second one over.
//
// part = "peace_ds" | "diffuser_peace"   (print 2 diffusers per sign)
// =====================================================================
include <../params.scad>
use <../lib/threads.scad>

part = "peace_ds";

R  = peace_od/2;             // 90
T  = m_ring_t;               // 40, same depth as the ring
stem_r0 = R + m_boss_len;    // 107.5 - boss ends, stem tube starts
stem_r1 = stem_r0 + m_stem_len;

/* ------------------------- the 2D outline -------------------------- */
// ONE connected region: the outer band annulus plus the three bars
// (vertical full-diameter, two lower diagonals at ±45°), each bar
// clipped to the band's inner circle grown by peace_bar_lap so it
// fuses into the band instead of just touching it. The region has
// four window holes (two large upper, two lower wedges); every one of
// them gets edge walls below.
module peace_2d() {
    union() {
        difference() {
            circle(d = peace_od, $fn = FN_ROUND);
            circle(d = peace_od - 2*peace_band, $fn = FN_ROUND);
        }
        intersection() {
            union() {
                translate([-peace_bar_w/2, -peace_od/2])
                    square([peace_bar_w, peace_od]);
                for (a = [45, -45])
                    rotate(a) translate([-peace_bar_w/2, -peace_od/2 - 2])
                        square([peace_bar_w, peace_od/2 + 2]);
            }
            circle(d = peace_od - 2*peace_band + peace_bar_lap, $fn = FN_ROUND);
        }
    }
}

// the glow cavity cross-section: the outline eroded by the wall
// thickness. Erosion shrinks away from EVERY boundary, so this opens
// the band, the bars and the window surrounds in one go (inside
// corners come out rounded at r = m_rim_wall, which is fine here).
module peace_cavity_2d() {
    offset(r = -m_rim_wall) peace_2d();
}

// the cavity boundary walked inwards by d (negative d walks outwards,
// into the wall - that is how the snap beads get their interference)
module peace_cavity_off(d) {
    offset(r = -d) peace_cavity_2d();
}

// full-depth edge walls: outline + all four window surrounds
module peace_walls() {
    linear_extrude(height = T, convexity = 12)
        difference() {
            peace_2d();
            peace_cavity_2d();
        }
}

/* ----------------------- stem + bulb (ring's) ---------------------- */
// helper: solid built along +X (axis at y=0,z=0), then swung to the
// stem angle with the axis lifted to the sign's mid-plane
module p_at_stem(r_from, length, d1, d2) {
    rotate([0, 0, notch_angle]) translate([0, 0, T/2])
        rotate([0, 90, 0])
            translate([0, 0, r_from])
                cylinder(h = length, d1 = d1, d2 = d2, $fn = 96);
}

module peace_boss_and_stem() {
    intersection() {
        difference() {
        union() {
            // smooth bulb: oblate spheroid centred ON the outer band
            // surface, hulled to the Ø34 stem shoulder disc. The
            // outline's lowest point is the Ø180 circle, exactly the
            // ring's situation, so this transfers unchanged.
            hull() {
                rotate([0, 0, notch_angle]) translate([0, 0, T/2])
                    rotate([0, 90, 0]) {
                        translate([0, 0, R])
                            scale([1, 1, 0.5]) sphere(d = 56, $fn = 96);
                        translate([0, 0, stem_r0 - 2])
                            cylinder(h = 2, d = 34, $fn = 96);
                    }
            }
            // threaded stem: crest = Ø27.8 (original stem OD), so the
            // sign also push-fits a plain shell hole; screws into the
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
            p_at_stem(stem_r0 + stem_thr_len - EPS,
                      m_stem_len - stem_thr_len - 1,
                      2*stem_thr_root_r, 2*stem_thr_root_r);
            p_at_stem(stem_r0 + m_stem_len - 1 - EPS, 1,
                      2*stem_thr_root_r, 2*stem_thr_root_r - 3);
        }
        // SURFACE-MOUNT like the ring: remove everything inboard of the
        // outer band's inner face (+0.05), so the bulb welds through
        // the 2 mm wall but leaves the light cavity completely clear -
        // the diffusers keep uninterrupted skirts, no gap needed
        translate([0, 0, -2])
            cylinder(h = T + 4, r = R - m_rim_wall + 0.05, $fn = FN_ROUND);
        }
        // clip the boss flush with the sign's faces
        translate([-250, -250, 0]) cube([500, 500, T]);
    }
}

module peace_wire_bore() {
    // one constant Ø20 passage from the light cavity straight through
    // bulb, band wall and stem into the base. Starts at peace_wire_r0,
    // deep enough inside the band cavity that the full Ø20 mouth is in
    // open air (the vertical bar's junction with the band is nearby).
    p_at_stem(peace_wire_r0, stem_r1 - peace_wire_r0 + 2,
              m_stem_bore, m_stem_bore);
}

// stem + bulb only (no walls), for fast thread fit checks
module peace_stem_only() {
    difference() {
        peace_boss_and_stem();
        peace_wire_bore();
    }
}

module peace_ds() {
    difference() {
        union() {
            peace_walls();
            peace_boss_and_stem();
        }
        peace_wire_bore();
    }
}

/* ------------------ snap-in diffuser (print 2) --------------------- */
// The ring's tray interface, generalised off the circle: instead of two
// concentric skirts, ONE skirt band follows the cavity boundary - which
// means it runs around the outline AND around every window - sitting
// diffuser_clr inside the cavity walls. `bulge` grows the band back
// outwards, which is how the snap beads are made: crest bulge =
// m_dif_bead (0.45) lands 0.15 past the wall = the ring's validated
// 0.15 bite per bead.
module peace_skirt_band(bulge = 0) {
    difference() {
        peace_cavity_off(diffuser_clr - bulge);
        peace_cavity_off(diffuser_clr + peace_skirt_t);
    }
}

// round bead of radius m_dif_bead centred at z = zc, approximated by
// peace_bead_n slabs (a rotate_extrude torus is only available to a
// circular rim; this shape needs the profile swept along the outline)
module peace_bead(zc) {
    b = m_dif_bead;
    n = peace_bead_n;
    for (k = [0 : n-1]) {
        dz0 = -b + 2*b*k/n;
        dz1 = -b + 2*b*(k+1)/n;
        dzc = (dz0 + dz1)/2;
        translate([0, 0, zc + dz0])
            linear_extrude(height = dz1 - dz0, convexity = 12)
                peace_skirt_band(sqrt(b*b - dzc*dzc));
    }
}

module peace_diffuser(beads = true) {
    // face plate: the whole sign outline (the windows are already holes
    // in it), covering the walls and the bulb's flush face like the
    // ring's tray does
    linear_extrude(height = m_dif_face_t, convexity = 12) peace_2d();
    // retention skirt down into the cavity
    linear_extrude(height = m_dif_face_t + m_dif_skirt_h, convexity = 12)
        peace_skirt_band();
    if (beads)
        for (bz = m_dif_bead_z)
            peace_bead(m_dif_face_t + bz);
}

/* ------------------------- part selection -------------------------- */
// exported flat (like the ring and its trays), NOT inverted
if (part == "peace_ds")
    peace_ds();
else if (part == "diffuser_peace")
    peace_diffuser();
