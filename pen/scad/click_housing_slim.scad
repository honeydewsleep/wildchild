// Click pen: slimmer hex upper housing.
//   openscad -o click_housing_slim.stl click_housing_slim.scad
//
// The original "Pen Upper Housing" is an 11.0 mm across-flats hexagon
// (12.7 across the sharp corners) around a Ø9.0 bore, so its flats sit
// exactly on the knurl crests of the grip (Ø11) and its corners stand
// 0.85 mm proud of them. This file keeps the original mesh — bore,
// thread, the two long slots and the click-mechanism cam ramps in the
// rear — and only re-cuts the OUTSIDE to a smaller rounded hexagon, so
// the grip's knurl reads as (nearly) flush: the knurl valleys are Ø10.0,
// the new flats are 10.4 across, the softened corners 11.64.
//
// The round Ø11 front collar (first 6 mm) is kept too: the pen clip is a
// ring that snaps onto exactly that collar.
//
// The rear 16 mm cannot shrink: the click cam ramps inside reach r 5.08,
// leaving only ~0.4 mm of wall under the original flats already. That
// section is left exactly as the original (11 AF), joined by a short
// 45° chamfer.
include <params.scad>

ch_ref      = "../ref/Pen_Upper_Housing.stl";  // original mesh (third-party, user's copy)
ch_axis     = [142.137, 142.52];               // bore axis of the original mesh (fitted)
ch_len      = 85.5;
ch_af       = 10.4;    // new across-flats. Wall over the Ø9.0 bore = (ch_af - 9.0)/2 = 0.70
ch_corner_r = 1.2;     // corner rounding (0 = sharp like the original -> 12.0 across corners)
ch_collar_z = 5.6;     // the original round Ø11 collar (z 0..5.6) is kept: the pen clip's ring sits on it
ch_keep_from = 69.5;   // z from which the original exterior is kept (cam-ramp section)
ch_trans    = 0.85;    // length of the 45° step up to the original hex
ch_orig_ac  = 12.75;   // original across-corners (envelope for the kept section)

// original mesh, axis on z
module original() translate([-ch_axis[0], -ch_axis[1], 0]) import(ch_ref, convexity = 8);

// hexagon with flats at 0, 60, 120... deg (as the original)
module hex_flat0(af, rc = 0) {
    r = (af / 2) / cos(30);
    if (rc > 0) offset(r = rc) offset(delta = -rc) rotate(30) circle(r = r, $fn = 6);
    else rotate(30) circle(r = r, $fn = 6);
}

module envelope() {
    z0 = ch_keep_from - ch_trans;
    translate([0, 0, -1]) cylinder(h = ch_collar_z + 1, r = ch_orig_ac / 2);            // collar: original
    translate([0, 0, ch_collar_z - EPS]) linear_extrude(z0 - ch_collar_z + 2*EPS) hex_flat0(ch_af, ch_corner_r);
    hull() {
        translate([0, 0, z0])           linear_extrude(EPS) hex_flat0(ch_af, ch_corner_r);
        translate([0, 0, ch_keep_from]) linear_extrude(EPS) rotate(30) circle(r = ch_orig_ac / 2, $fn = 6);
    }
    translate([0, 0, ch_keep_from - EPS]) linear_extrude(ch_len - ch_keep_from + 2) rotate(30) circle(r = ch_orig_ac / 2, $fn = 6);
}

intersection() { original(); envelope(); }
