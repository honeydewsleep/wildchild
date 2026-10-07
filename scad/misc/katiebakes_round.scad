// Katie Bakes — 3" round cookie cutter with the two-line logo stamp.
// Self-contained (does not use params.scad).
//
// A one-piece "cutter + stamp + handle" cannot print support-free: the
// letters hang from the plate above the blade edge, so they float in every
// orientation that keeps the handle up.  Hence two parts that click together
// into one tool:
//
//   part="ring"    — the cutting ring (print upright, blade on the bed).
//                    Ø76.2 bore = the cookie; 0.8 mm lip, 1.6 mm wall, a shallow
//                    snap groove just below the rim.
//   part="insert"  — plate + lettering + bar handle (print face-down, handle
//                    up).  A 2 mm skirt drops into the ring bore with 3 snap
//                    nubs; the plate rests on the ring rim, so with the blade
//                    on the board the letter faces sit `imprint` below the top
//                    of `dough_t` dough.  Pops out for cleaning / solo stamping.
//   part="onepiece" — everything fused, for printing upright WITH slicer
//                    supports under the letters (letter faces will show
//                    support scarring).  Provided for completeness.
//
// Lettering: cream face layer of "Katie Bakes Logo (2 lines).png",
// colour-masked and traced (potrace) → katiebakes_logo2.svg.  logo_w /
// logo_off were computed so the letters' minimal enclosing circle is exactly
// cookie_d - 2*margin and centred on the axis.
//
// Letters read correctly from +z (handle side) → mirrored on the face → the
// imprint reads correctly.

part = "insert";          // "ring" | "insert" | "onepiece" | "letters2d"

// ---- cookie ----------------------------------------------------------
cookie_d  = 76.2;         // 3" — diameter of the cut cookie (blade bore)
margin    = 5;            // letters stay this far inside the blade
logo_w    = 61.46;        // SVG width in mm; 62.26 puts the enclosing circle at cookie_d - 2*margin,
                          // trimmed so the traced+offset outline tops out at r = 33.15
logo_off  = [0.245, 3.850]; // shifts the SVG bbox centre so the enclosing circle is centred
bold      = 0.15;         // per-side stroke thickening (thinnest ≈ 1.0 → 1.3 mm)

// ---- dough / imprint -------------------------------------------------
dough_t   = 6;
imprint   = 1.5;
plate_gap = 0.5;          // plate underside above the dough top

// ---- ring ------------------------------------------------------------
blade_t   = 0.8;  blade_h = 3;
wall_t    = 1.6;
groove_d  = 0.35; groove_h = 1.0; groove_z = 1.0;   // below the rim, centre

// ---- insert ----------------------------------------------------------
plate_t   = 3;
plate_lip = 2;            // plate overhangs the ring wall by this much
skirt_t   = 1.5;  skirt_clr = 0.15;
nub_d     = 1.0;  nub_proud = 0.3;  nubs = 3;
handle_l  = 60;   handle_w_base = 9;  handle_d_top = 7;  handle_h = 20;

EPS = 0.01;
$fn = 96;

R_bore   = cookie_d / 2;
ring_h   = dough_t + plate_gap;                 // 6.5 — plate rests on the rim
letter_h = ring_h - (dough_t - imprint);        // 2.0
plate_d  = cookie_d + 2 * (wall_t + plate_lip); // 83.4
R_skirt  = R_bore - skirt_clr;

module letters_raw()
    translate(logo_off) resize([logo_w, 0], auto = true)
        import("katiebakes_logo2.svg", center = true);
module letters() offset(r = bold) letters_raw();

module handle(z0) hull() {
    translate([0, 0, z0 - EPS]) linear_extrude(EPS) square([handle_l, handle_w_base], center = true);
    for (sx = [-1, 1])
        translate([sx * (handle_l - handle_d_top) / 2, 0, z0 + handle_h - handle_d_top / 2])
            sphere(d = handle_d_top, $fn = 48);
}

// ring cross-section (r, z); 45° step from lip to wall; snap groove near the rim
module ring_profile(top, groove = true) {
    Ro = R_bore + wall_t;
    g0 = ring_h - groove_z - groove_h / 2;  g1 = g0 + groove_h;
    polygon(groove ?
        [[R_bore, 0], [R_bore + blade_t, 0], [R_bore + blade_t, blade_h],
         [Ro, blade_h + (wall_t - blade_t)], [Ro, top], [R_bore, top],
         [R_bore, g1], [R_bore + groove_d, g1], [R_bore + groove_d, g0], [R_bore, g0]] :
        [[R_bore, 0], [R_bore + blade_t, 0], [R_bore + blade_t, blade_h],
         [Ro, blade_h + (wall_t - blade_t)], [Ro, top], [R_bore, top]]);
}

module ring() rotate_extrude() ring_profile(ring_h, true);

// print orientation: letter faces and skirt bottom on z=0, handle up
module insert() {
    linear_extrude(letter_h + EPS) letters();
    difference() {                                    // skirt
        cylinder(r = R_skirt, h = letter_h + EPS);
        translate([0, 0, -1]) cylinder(r = R_skirt - skirt_t, h = letter_h + 2);
    }
    for (i = [0 : nubs - 1]) rotate([0, 0, 90 + i * 360 / nubs])  // snap nubs
        translate([R_skirt - nub_d / 2 + nub_proud, 0, letter_h - groove_z]) sphere(d = nub_d, $fn = 24);
    translate([0, 0, letter_h]) cylinder(d = plate_d, h = plate_t);
    handle(letter_h + plate_t);
}

// in-use orientation (blade on the board); needs supports under the letters
module onepiece() {
    top = ring_h + plate_t;
    rotate_extrude() ring_profile(top, false);
    translate([0, 0, ring_h]) cylinder(r = R_bore + wall_t, h = plate_t);
    translate([0, 0, dough_t - imprint]) linear_extrude(letter_h + EPS) letters();
    handle(top);
}

if (part == "ring")      ring();
if (part == "insert")    insert();
if (part == "onepiece")  onepiece();
if (part == "letters2d") letters();
