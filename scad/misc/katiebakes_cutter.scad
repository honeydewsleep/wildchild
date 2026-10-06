// Katie Bakes — cookie cutter with built-in logo embosser.
// Self-contained (does not use params.scad).
//
// One part: a cutting blade that follows the outline of the "Katie Bakes"
// script wordmark, a top plate, and the lettering hanging from the plate
// so it presses into the dough as you cut.  Designed around `dough_t`
// rolled dough: when the blade bottoms out on the board the letter faces
// sit `imprint` mm below the dough surface.
//
// The lettering comes from `katiebakes_logo.svg` — the cream face layer of
// the logo (katie-bakes.jpg), colour-masked and traced with potrace.
//
// In-use coords: cutting edge at z=0, +z up, letters read correctly when
// viewed from +z (through the plate) → mirrored on the stamp face → the
// imprint on the cookie reads correctly.  Exported inverted (plate on the
// bed, letters and blade pointing up); no supports needed.
//
//   openscad -o stl/katiebakes_cutter.stl -D 'part="cutter"' scad/misc/katiebakes_cutter.scad

part = "cutter";          // "cutter" | "letters2d" | "cookie2d"
inverted = true;          // export in print orientation

// ---- size ------------------------------------------------------------
logo_w    = 100;   // width of the lettering (mm). Cookie ≈ logo_w + 2*margin
bold      = 0.15;  // per-side thickening of the strokes (thinnest ≈ 0.9 → 1.2 mm)
margin    = 5;     // dough border between lettering and the cutting edge
smooth    = 8;     // bridges the word gap / letter gaps in the outline

// ---- dough / imprint -------------------------------------------------
dough_t   = 6;     // rolled dough thickness the cutter is tuned for
imprint   = 1.5;   // depth the letters press into the dough surface
plate_gap = 0.5;   // plate underside clears the dough top by this much

// ---- walls -----------------------------------------------------------
blade_t   = 0.8;   // cutting lip thickness
blade_h   = 3;     // height of the thin lip
wall_t    = 1.6;   // wall above the lip
plate_t   = 2.5;
flange_w  = 4;     // thumb rim around the top
flange_t  = 2;

EPS = 0.01;
$fn = 48;

letter_face_z = dough_t - imprint;        // 4.5
plate_z0      = dough_t + plate_gap;      // 6.5
plate_z1      = plate_z0 + plate_t;       // 9.0  (= total height)
letter_h      = plate_z0 - letter_face_z; // 2.0

module letters_raw()
    resize([logo_w, 0], auto = true) import("katiebakes_logo.svg", center = true);

module letters() offset(r = bold) letters_raw();

// closing (fills the gap between the words and between letters) + margin
module cookie() offset(r = -smooth) offset(r = smooth + margin) letters();

module ring(w) difference() { offset(r = w) cookie(); cookie(); }

module cutter() {
    // thin cutting lip
    linear_extrude(blade_h + EPS) ring(blade_t);
    // wall
    translate([0, 0, blade_h]) linear_extrude(plate_z1 - blade_h) ring(wall_t);
    // thumb flange around the top
    translate([0, 0, plate_z1 - flange_t]) linear_extrude(flange_t) ring(wall_t + flange_w);
    // plate (overlaps the wall footprint)
    translate([0, 0, plate_z0]) linear_extrude(plate_t) offset(r = wall_t) cookie();
    // embossing letters hanging from the plate
    translate([0, 0, letter_face_z]) linear_extrude(letter_h + EPS) letters();
}

if (part == "cutter") {
    if (inverted) translate([0, 0, plate_z1]) rotate([180, 0, 0]) cutter();
    else cutter();
}
if (part == "letters2d") letters();
if (part == "cookie2d")  cookie();
