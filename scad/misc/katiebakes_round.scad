// Katie Bakes — 3" round cookie set: separate cutter rings + face-up stamp
// with a screw-in handle (Etsy-style cutter + stamp set).  Self-contained
// apart from the thread library.
//
//   part="stamp"   — Ø75.2 disc (slides inside the cutter bore as a guide),
//                    8.5 mm thick, two-line "Katie / Bakes" lettering 3 mm
//                    proud, female thread in the base.  Print FACE UP as
//                    exported (plate on the bed, letters up): the thread
//                    cavity opens downward onto the bed, its 45° flanks print
//                    without supports, the flat ceiling is a short bridge.
//   part="knob"    — mushroom knob, flat top; part="bar" — 70 mm bar grip.
//                    Both carry the male thread.  Print as exported (grip
//                    face on the bed, thread pointing up).
//   part="ring"    — cutting ring, Ø76.2 bore, height ring_h (9 / 13 / 18 mm
//                    exported) with a 45°-backed thumb flange.  Print upright.
//   part="fit"     — thread clearance check: must render EMPTY.
//
// Lettering: cream face layer of "Katie Bakes Logo (2 lines).png" traced to
// katiebakes_logo2.svg; logo_w / logo_off put its enclosing circle at Ø66,
// centred.  The stamp face points +z, so the letters are MIRRORED here and
// the imprint reads correctly.
//
// Thread: root r7.0, depth 1.2, pitch 3, 6.5 long, clearance 0.30 (same
// printable 45°-flank profile and clearance as the lamp's validated
// threads).  Axis vertical on both parts as exported.

use <../lib/threads.scad>

part   = "stamp";   // "stamp" | "knob" | "bar" | "ring" | "fit" | "letters2d"
ring_h = 13;        // cutter ring height for part="ring"

// ---- cookie / lettering ------------------------------------------------
cookie_d  = 76.2;          // 3" — bore of the cutter = cookie diameter
stamp_clr = 0.5;           // radial gap stamp ↔ bore (stamp Ø75.2)
logo_w    = 61.46;         // see katiebakes_round history: enclosing circle Ø66.3
logo_off  = [0.245, 3.850];
bold      = 0.15;          // per-side stroke thickening
letter_h  = 3;             // relief of the lettering (= imprint depth)

// ---- stamp body -------------------------------------------------------
plate_t   = 8.5;           // thread length + 2 mm ceiling
edge_ch   = 0.6;           // chamfer on the bed edge

// ---- thread (stamp female / handle male) ------------------------------
thr_r     = 7.0;  thr_depth = 1.2;  thr_pitch = 3;  thr_len = 6.5;  thr_clr = 0.30;

// ---- handles ----------------------------------------------------------
knob_cap_d = 36;  knob_cap_t = 5;  knob_stem_d = 20;  knob_base_d = 30;  knob_h = 24;
bar_l = 70;  bar_w = 14;  bar_t = 6;  bar_h = 23;

// ---- cutter ring ------------------------------------------------------
blade_t = 0.8;  blade_h = 3;  wall_t = 1.6;  flange_w = 3;  flange_t = 2;

EPS = 0.01;
$fn = 96;

R_bore  = cookie_d / 2;
stamp_d = cookie_d - 2 * stamp_clr;

module letters_raw()
    translate(logo_off) resize([logo_w, 0], auto = true)
        import("katiebakes_logo2.svg", center = true);
module letters() offset(r = bold) letters_raw();

module female_thread() {              // cavity, opening at z=0
    translate([0, 0, -EPS]) thread_female_cavity(thr_r, thr_depth, thr_pitch, thr_len + EPS, thr_clr);
    thread_mouth_chamfer(thr_r, thr_depth, thr_clr);
}
module male_thread() intersection() {  // rod, z=0..thr_len
    thread_male(thr_r, thr_depth, thr_pitch, thr_len);
    thread_tip_taper(thr_r, thr_depth, thr_len);
}

// print orientation: bed face at z=0, letters up
module stamp() difference() {
    union() {
        rotate_extrude() polygon([[0, 0], [stamp_d/2 - edge_ch, 0], [stamp_d/2, edge_ch],
                                  [stamp_d/2, plate_t], [0, plate_t]]);
        translate([0, 0, plate_t - EPS]) linear_extrude(letter_h + EPS) mirror([1, 0, 0]) letters();
    }
    female_thread();
}

// print orientation: flat cap on the bed, thread up
module knob() {
    rc = knob_cap_d/2; rs = knob_stem_d/2; rb = knob_base_d/2;
    rotate_extrude() polygon([[0, 0], [rc - 1, 0], [rc, 1], [rc, knob_cap_t],
                              [rs, knob_cap_t + 3], [rs, knob_h - 3 - (rb - rs)],
                              [rb, knob_h - 3], [rb, knob_h], [0, knob_h]]);
    translate([0, 0, knob_h - EPS]) male_thread();
}

module bar() {
    hull() {
        linear_extrude(bar_t) hull() for (sx = [-1, 1]) translate([sx * (bar_l - bar_w)/2, 0]) circle(d = bar_w);
        translate([0, 0, bar_h - 3]) cylinder(d = knob_base_d, h = 3);
    }
    translate([0, 0, bar_h - EPS]) male_thread();
}

module ring(h = ring_h) {
    Ro = R_bore + wall_t; Rf = Ro + flange_w;
    z_step = blade_h + (wall_t - blade_t);        // 45° lip→wall step
    z_fl   = max(z_step, h - flange_t - flange_w); // 45° flange underside
    rotate_extrude() polygon([[R_bore, 0], [R_bore + blade_t, 0], [R_bore + blade_t, blade_h],
                              [Ro, z_step], [Ro, z_fl], [Rf, z_fl + flange_w], [Rf, h], [R_bore, h]]);
}

if (part == "stamp")     stamp();
if (part == "knob")      knob();
if (part == "bar")       bar();
if (part == "ring")      ring(ring_h);
if (part == "letters2d") mirror([1, 0, 0]) letters();
// Both threads are measured from their own z=0 (knob base face / stamp bed
// face), which meet when seated — so compare them at the same origin.  (An
// axial shift would rotate the helix: 1 mm = 120° at pitch 3.)
if (part == "fit")       difference() { male_thread(); translate([0, 0, -EPS]) thread_female_cavity(thr_r, thr_depth, thr_pitch, thr_len + 2 * EPS, thr_clr); }
