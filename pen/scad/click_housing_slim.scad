// Click pen: slimmer hex upper housing that flows into the knurled grip.
//   openscad -o click_housing_slim.stl click_housing_slim.scad
//
// The original "Pen Upper Housing" is an 11.0 mm across-flats hexagon
// (12.7 across the sharp corners) with a round Ø11 collar at the front.
// This file keeps the original mesh — bore, thread, the two long slots
// and the click-mechanism cam ramps in the rear — and re-shapes only the
// OUTSIDE:
//
//   z 0         round Ø11, exactly the knurl-crest diameter of the grip,
//               so the joint has no step in any direction (the grip and
//               housing are threaded together, so their rotation is not
//               indexed — a round joint face is the only one that always
//               lines up);
//   z 0 → 10    smooth blend from that circle into the rounded hexagon
//               (10.4 across flats, 11.64 across corners) — a convex
//               hull, whose sections are exact circle→hex morphs;
//   z 10 → 70   the hexagon grows imperceptibly to 11.0 across flats
//               (0.3 mm per side over 60 mm, 0.3°), because
//   z 70 → 85.5 the click cam ramps inside reach r 5.08 and leave only
//               ~0.4 mm of wall under 11.0 AF flats already. Corners are
//               still rounded here (r 1.27), that costs no wall.
//
// The front collar zone is first "filled" out to the hex at the corners
// (union with a ring), since the original round collar has no material
// beyond r 5.5; everything is then cut to the envelope.
include <params.scad>

ch_ref      = "../ref/Pen_Upper_Housing.stl";  // original mesh (third-party, user's copy)
ch_axis     = [142.137, 142.52];               // bore axis of the original mesh (fitted)
ch_len      = 85.5;
ch_af       = 10.4;    // across-flats at the front. Wall over the Ø9.0 bore = (ch_af - 9.0)/2 = 0.70
ch_af_rear  = 11.0;    // across-flats from ch_taper_end to the rear (cam-ramp section needs it)
ch_corner_r = 1.2;     // corner rounding at the front (scales with the taper)
ch_joint_r  = 5.5;     // round joint face radius = grip knurl crest (Ø11)
ch_blend    = 10;      // length of the round → hex blend
ch_taper_end = 70;     // where the hexagon reaches ch_af_rear
ch_fill_z   = 5.6;     // original round collar zone (gets filled out to the hex)

// original mesh, axis on z
module original() translate([-ch_axis[0], -ch_axis[1], 0]) import(ch_ref, convexity = 8);

// hexagon with flats at 0, 60, 120... deg (as the original), rounded corners
module hex_flat0(af, rc = 0) {
    r = (af / 2) / cos(30);
    if (rc > 0) offset(r = rc) offset(delta = -rc) rotate(30) circle(r = r, $fn = 6);
    else rotate(30) circle(r = r, $fn = 6);
}

// the whole exterior envelope, offset by d (for the clip ring)
module envelope(d = 0) {
    s = ch_af_rear / ch_af;
    // round → hex blend
    hull() {
        translate([0, 0, -1])       cylinder(h = 1 + EPS, r = ch_joint_r + d);
        translate([0, 0, ch_blend]) linear_extrude(EPS) hex_flat0(ch_af + 2*d, ch_corner_r + d);
    }
    // slow taper up to the rear width
    translate([0, 0, ch_blend - EPS])
        linear_extrude(ch_taper_end - ch_blend + 2*EPS, scale = s) hex_flat0(ch_af + 2*d, ch_corner_r + d);
    // constant rear
    translate([0, 0, ch_taper_end - EPS])
        linear_extrude(ch_len - ch_taper_end + 2) hex_flat0(ch_af_rear + 2*d*s, (ch_corner_r + d) * s);
}

module fill_ring() {   // material to add in the collar zone, trimmed by the envelope afterwards
    difference() { cylinder(h = ch_fill_z, r = 8); translate([0, 0, -1]) cylinder(h = ch_fill_z + 2, r = 5.3); }
}

module housing() intersection() { union() { original(); fill_ring(); } envelope(); }

housing();
