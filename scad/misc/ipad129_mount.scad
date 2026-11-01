// iPad Pro 12.9" (5th/6th gen, M1/M2) & iPad Air 13" (M2/M3) — magnetic wall
// mount that charges through the Smart Connector.  12.9" remix of
// "iPad Air/Pro 11" magnetic wireless Vesa wall mount" (MakerWorld 3287446,
// GHPM DESIGN): a plate the size of the iPad's back with magnet pockets that
// sit exactly over the iPad's own back magnets, a recess for a pogo-pin
// Smart Connector charger, VESA 100 / VESA 75 / 60 mm wall-box screw holes,
// and a cable groove on the back.  Self-contained (no params.scad).
//
// Magnet positions + polarities come from Apple's Accessory Design
// Guidelines dimensional drawings (iPad Pro 12.9-inch (6th generation),
// sheet 3 "MAGNET DETAIL"; the iPad Air 13-inch (M2) sheet carries the
// identical numbers).  See docs/ipad129-magnet-map.md for the transcription.
//
// FRAME ("face frame", used for every part): looking at the mount's FRONT
// (the face the iPad sits on), +X right, +Y up, origin at the centre of the
// Smart Connector's MIDDLE contact.  This is Apple's magnet-sheet frame
// (a front view "through" the device), so Apple's X/Y are used verbatim.
// Connector edge of the device is at Y = -12.0, camera corner is top-RIGHT.
// All parts are modelled in print orientation; export with no rotation.
//
//   part="mount"           one-piece plate, back on the bed, pockets up.
//                          277.6 × 211.9 × 7 — needs a ≥ 280 mm bed (H2D…).
//   part="mount_bottom"    connector half (jigsaw tabs) — 256 mm beds.
//   part="mount_top"       camera half (jigsaw sockets).
//   part="template"        2 mm tray with a 3 mm lip: flip it onto the iPad's
//                          back, drop the magnets in the holes, they
//                          self-orient.  Also the wall drilling template.
//   part="template_bottom" / "template_top"   split template.
//   part="plug"            cover for unused countersunk screw holes.
//   part="check"           pockets ∩ back-side cutters: must render EMPTY.
//
//   -D mag_h=4             pockets for 4×4 instead of 4×3 mm magnets.
//   -D charger=false       plain magnetic mount: no charger recess/groove and
//                          six more pockets under where the charger would be.

part    = "mount";
mag_h   = 3;        // magnet height: 3 (Ø4×3) or 4 (Ø4×4)
charger = true;

// ---- device (Apple dimensional drawings) --------------------------------
dev_w     = 214.9;   // iPad Pro 12.9 (5th/6th) = iPad Air 13 (M2/M3) outline
dev_h     = 280.6;
dev_r     = 12;      // corner radius
conn_edge = 12.0;    // middle contact centre → device edge (sheet 2: "12.00")
dev_c     = [0, dev_h/2 - conn_edge];      // device centre = (0, 128.3)
cam_c     = [88.5, 249.7];                 // camera bump centre (sheet 2)
cam_sq    = 28;                            // bump footprint ≈ 28 × 28 …
cam_r     = 7;                             // … with ~R7 corners
pin_pitch = 4.97;                          // Smart Connector contact pitch

// ---- plate --------------------------------------------------------------
plate_inset = 1.5;   // plate edge inside the iPad edge
plate_thk   = 7;
plate_w = dev_w - 2*plate_inset;           // 211.9
plate_h = dev_h - 2*plate_inset;           // 277.6
plate_r = dev_r - plate_inset;
cam_clr = 1.5;       // notch clearance around the camera bump

// ---- magnets ------------------------------------------------------------
mag_d    = 4;
mag_clr  = 0.2;      // diametral, press fit in PETG/PLA
mag_sink = 0.2;      // magnet face below the plate face
pocket_d     = mag_d + mag_clr;
pocket_depth = mag_h + mag_sink;

// ---- charger (LULULOOK Smart Connector pill as used by the original mount;
// measured off the listing photos via a homography on its VESA 100 screws:
// 67 x 31, contacts 9.9 mm from the pill's outer long edge, centred along
// its length; 5 mm thick per the listings.  Check with calipers.) ---------
chg_len       = 67;    // pill length (along the device edge)
chg_wid       = 31;    // pill width
chg_thk       = 5;     // pill thickness
chg_pin_off   = 5.7;   // pill centre is this far INBOARD (+Y) of the pin row
chg_clr       = 0.4;   // per side
chg_proud     = 0.2;   // pill face stands this much above the plate face
chg_floor_min = 1.6;   // never leave a thinner floor than this
chg_cable_end = -1;    // -1: cable leaves the pill's left end (face view), +1 right
chg_open_edge = true;  // let the recess run out through the plate's bottom edge
chg_c     = [0, chg_pin_off];
chg_depth = min(chg_thk - chg_proud, plate_thk - chg_floor_min);

// ---- back: mounting + cable ----------------------------------------------
hole_d      = 4.6;            // M4 clearance
cs_d        = 9.5;            // 90° countersink
vesa        = [100, 75];
eu_box      = 60;             // wall-box screw spacing, both orientations
center_slot = [13, 7.5];      // passes a USB-C plug
groove_w    = 5;
groove_d    = 3.5;

// ---- split for 256 mm beds ------------------------------------------------
split_y  = dev_c[1] + 12;     // 140.3: clear of every hole and the groove
tab_xs   = [-90, -45, 45, 90];
tab_neck = 10; tab_head = 15; tab_reach = 10; tab_clr = 0.15;

// ---- template tray --------------------------------------------------------
tpl_thk = 2; tpl_lip_h = 3; tpl_lip_t = 1.6; tpl_clr = 0.25; tpl_hole_clr = 0.4;

// ==========================================================================
// Apple magnet map: [label, X, Y, pole showing at the iPad's back surface]
// ("POLARITY TOWARD SURFACE OF ENCLOSURE / CLOSEST TO PROBE" column).
// BV1 = bottom-left, BV2 = bottom-right (connector edge), BV3 = top-right,
// BV4 = top-left (camera edge).  BVn-11/12 are the 4 × 12 mm bars.
// ==========================================================================
bv2_cols = [69.79, 74.45, 79.15, 83.85, 88.55, 93.25, 97.95, 102.65];   // cols 10..17
bv2_rows = [6.62, 11.32, 16.02, 20.72];
bv2_pol  = [["N","S","N","N"], ["N","S","S","N"], ["S","N","N","S"], ["N","S","S","S"],
            ["S","N","N","N"], ["N","S","S","S"], ["N","N","S","N"], ["", "S","N","S"]];
bv2_block = [for (i = [0:7]) for (j = [0:3]) if (bv2_pol[i][j] != "")
             [str("BV2-", i+10, "-", j+1), bv2_cols[i], bv2_rows[j], bv2_pol[i][j]]];

apple_mags = concat([
  // BV1 — bottom-left
  ["BV1-11",-80.53,11.64,"S"], ["BV1-12",-75.43,11.64,"N"],
  ["BV1-21",-30.84,7.11,"S"], ["BV1-22",-30.84,11.81,"S"], ["BV1-23",-30.84,16.51,"N"], ["BV1-24",-30.84,21.21,"N"],
  ["BV1-31",-26.21,7.11,"N"], ["BV1-32",-26.21,11.81,"S"], ["BV1-33",-26.21,16.51,"N"], ["BV1-34",-26.21,21.21,"S"],
  ["BV1-41",-21.51,7.11,"N"], ["BV1-42",-21.51,11.81,"N"], ["BV1-43",-21.51,16.51,"S"], ["BV1-44",-21.51,21.21,"S"],
  ["BV1-51",-17.21,7.11,"S"], ["BV1-52",-17.21,11.81,"S"], ["BV1-53",-17.21,16.51,"N"], ["BV1-54",-17.21,21.21,"N"],
  // BV2 — bottom-right (plus the 8-column block below)
  ["BV2-11",28.13,6.62,"S"], ["BV2-12",28.13,11.32,"N"], ["BV2-13",28.13,16.02,"N"], ["BV2-14",28.13,20.72,"N"],
  ["BV2-21",32.19,6.62,"N"], ["BV2-22",32.19,11.32,"S"], ["BV2-23",32.19,16.02,"S"], ["BV2-24",32.19,20.72,"S"],
  ["BV2-34",36.89,20.72,"S"], ["BV2-44",41.59,20.72,"N"], ["BV2-54",46.29,20.72,"S"], ["BV2-64",50.99,20.72,"N"],
  ["BV2-74",55.69,20.72,"S"], ["BV2-84",60.39,20.72,"N"], ["BV2-94",65.09,20.72,"S"],
  // BV3 — top-right
  ["BV3-11",28.13,237.18,"S"], ["BV3-12",28.13,241.88,"N"], ["BV3-13",28.13,246.58,"S"], ["BV3-14",28.13,251.28,"N"],
  ["BV3-21",32.19,237.18,"N"], ["BV3-22",32.19,241.88,"N"], ["BV3-23",32.19,246.58,"S"], ["BV3-24",32.19,251.28,"S"],
  ["BV3-31",37.47,237.18,"S"], ["BV3-41",42.17,237.18,"N"], ["BV3-51",46.87,237.18,"S"], ["BV3-61",51.57,237.18,"N"],
  ["BV3-71",56.27,237.18,"S"], ["BV3-81",61.17,237.18,"N"], ["BV3-91",65.87,237.18,"S"],
  ["BV3-10-1",70.57,237.18,"S"], ["BV3-10-2",70.57,241.88,"N"], ["BV3-10-3",70.57,246.58,"S"], ["BV3-10-4",70.57,251.28,"N"],
  // BV4 — top-left
  ["BV4-11",-80.53,244.43,"N"], ["BV4-12",-75.43,244.43,"S"],
  ["BV4-21",-30.91,235.83,"N"], ["BV4-22",-30.91,240.53,"S"], ["BV4-23",-30.91,245.23,"S"], ["BV4-24",-30.91,249.93,"N"],
  ["BV4-31",-26.21,235.83,"N"], ["BV4-32",-26.21,240.53,"S"], ["BV4-33",-26.21,245.23,"N"], ["BV4-34",-26.21,249.93,"S"],
  ["BV4-41",-21.51,235.83,"S"], ["BV4-42",-21.51,240.53,"N"], ["BV4-43",-21.51,245.23,"N"], ["BV4-44",-21.51,249.93,"S"],
  ["BV4-51",-17.21,235.83,"N"], ["BV4-52",-17.21,240.53,"S"], ["BV4-53",-17.21,245.23,"S"], ["BV4-54",-17.21,249.20,"N"]
], bv2_block);

// Pockets used: every other magnet of each cluster (9.4 mm lattice → ≥ 5 mm
// walls between Ø4.2 pockets), skipping the BV3-10 column next to the
// camera notch and, with a charger, everything under the charger pill.
mag_use_base = [
  "BV4-21", "BV4-23", "BV4-41", "BV4-43", "BV4-11", "BV4-12",        // camera corner
  "BV3-11", "BV3-13", "BV3-31", "BV3-51", "BV3-71", "BV3-91",        // top-right
  "BV1-11", "BV1-12",                                                // bottom-left bars
  "BV2-44", "BV2-64", "BV2-84",                                      // bottom row
  "BV2-10-1", "BV2-10-3", "BV2-12-1", "BV2-12-3",                    // bottom-right block
  "BV2-14-1", "BV2-14-3", "BV2-16-1", "BV2-16-3"];
mag_use_nocharger = ["BV1-21", "BV1-23", "BV1-41", "BV1-43", "BV2-11", "BV2-13"];
mag_use = charger ? mag_use_base : concat(mag_use_base, mag_use_nocharger);
// The 4 × 12 bars take one Ø4 magnet each, staggered so the two pockets
// (5.1 mm apart in X) keep a wall between them.
bar_dy = [["BV4-11", -3.1], ["BV4-12", 3.2], ["BV1-11", -3.1], ["BV1-12", 3.2]];

function find_mag(l) = [for (m = apple_mags) if (m[0] == l) m][0];
function dy_of(l)    = let (h = [for (b = bar_dy) if (b[0] == l) b[1]]) len(h) > 0 ? h[0] : 0;
sel = [for (l = mag_use) let (m = find_mag(l)) [m[0], m[1], m[2] + dy_of(l), m[3]]];

mount_pts = concat(
  [for (v = vesa) for (sx = [-1, 1]) for (sy = [-1, 1]) [dev_c[0] + sx*v/2, dev_c[1] + sy*v/2]],
  [for (s = [-1, 1]) [dev_c[0] + s*eu_box/2, dev_c[1]]],
  [for (s = [-1, 1]) [dev_c[0], dev_c[1] + s*eu_box/2]]);

echo(str("magnet pockets: ", len(sel), " (mount dot = N faces the iPad): "),
     [for (m = sel) str(m[0], " @ ", m[1], ",", m[2], " mount-N-out=", m[3] == "S")]);

// ---- 2D helpers -----------------------------------------------------------
module rrect(w, h, r) offset(r = r, $fn = 64) offset(delta = -r) square([w, h], center = true);
module stadium(l, w) hull() for (s = [-1, 1]) translate([s*(l - w)/2, 0]) circle(d = w, $fn = 64);

// rounded-corner notch open to the plate's top-right corner
module cam_notch2d(clr) {
    s = cam_sq + 2*clr;
    translate(cam_c - [s/2, s/2]) offset(r = cam_r + clr, $fn = 48) offset(delta = -(cam_r + clr))
        square([s + 60, s + 60]);
}
module chg2d(clr) translate(chg_c) hull() {
    stadium(chg_len + 2*clr, chg_wid + 2*clr);
    if (chg_open_edge) translate([0, -40]) stadium(chg_len + 2*clr, chg_wid + 2*clr);
}
module tab2d() {                       // jigsaw tab pointing +Y from (0,0)
    translate([0, 2]) square([tab_neck, 6], center = true);
    translate([0, tab_reach]) circle(d = tab_head, $fn = 48);
}

// ---- cutters -------------------------------------------------------------
module pockets(extra = 1) for (m = sel)
    translate([m[1], m[2], plate_thk - pocket_depth]) cylinder(d = pocket_d, h = pocket_depth + extra, $fn = 48);

module groove() {
    e = chg_cable_end;
    pts = [[e*(chg_len/2 - 6), chg_c[1]], [e*(chg_len/2 + 5), chg_c[1]],
           [e*(chg_len/2 + 5), 50], [dev_c[0], dev_c[1]]];
    for (i = [0 : len(pts) - 2]) hull() for (j = [i, i + 1])
        translate([pts[j][0], pts[j][1], -1]) cylinder(d = groove_w, h = groove_d + 1, $fn = 32);
}
module charger_cut() {
    translate([0, 0, plate_thk - chg_depth]) linear_extrude(chg_depth + 1) chg2d(chg_clr);
    translate([0, 0, -1]) linear_extrude(plate_thk + 2) {
        translate([chg_cable_end*(chg_len/2 - 6), chg_c[1]]) rrect(12, 8, 2);   // cable exit
        translate(chg_c + [0, 2]) rrect(22, 8, 2);                             // glue window
    }
}
module back_cuts() {
    for (p = mount_pts) translate([p[0], p[1], 0]) {
        translate([0, 0, -1]) cylinder(d = hole_d, h = plate_thk + 2, $fn = 32);
        translate([0, 0, -0.01]) cylinder(d1 = cs_d, d2 = hole_d, h = (cs_d - hole_d)/2, $fn = 48);
    }
    if (charger) {
        translate([dev_c[0], dev_c[1], -1]) linear_extrude(plate_thk + 2) rrect(center_slot[0], center_slot[1], 3);
        groove();
    }
}

// ---- parts ---------------------------------------------------------------
module mount_body() difference() {
    translate([dev_c[0], dev_c[1], 0]) linear_extrude(plate_thk) rrect(plate_w, plate_h, plate_r);
    translate([0, 0, -1]) linear_extrude(plate_thk + 2) cam_notch2d(cam_clr);
    pockets();
    // polarity dot beside pockets whose magnet shows N to the iPad (iPad shows S)
    for (m = sel) if (m[3] == "S")
        translate([m[1] + pocket_d/2 + 1.5, m[2], plate_thk - 0.6]) cylinder(d = 1.4, h = 1, $fn = 16);
    if (charger) charger_cut();
    back_cuts();
}
module half(top) intersection() {
    mount_body();
    translate([-500, top ? split_y : split_y - 1000, -1]) cube([1000, 1000, plate_thk + 2]);
}
module mount_bottom() union() {
    half(false);
    linear_extrude(plate_thk) for (x = tab_xs) translate([x, split_y]) tab2d();
}
module mount_top() difference() {
    half(true);
    translate([0, 0, -1]) linear_extrude(plate_thk + 2)
        for (x = tab_xs) translate([x, split_y]) offset(r = tab_clr, $fn = 24) tab2d();
}

module template_body() {
    ow = dev_w + 2*(tpl_clr + tpl_lip_t); oh = dev_h + 2*(tpl_clr + tpl_lip_t);
    difference() {
        union() {
            translate([dev_c[0], dev_c[1], 0]) linear_extrude(tpl_thk) rrect(ow, oh, dev_r + tpl_clr + tpl_lip_t);
            translate([dev_c[0], dev_c[1], 0]) linear_extrude(tpl_thk + tpl_lip_h) difference() {
                rrect(ow, oh, dev_r + tpl_clr + tpl_lip_t);
                rrect(dev_w + 2*tpl_clr, dev_h + 2*tpl_clr, dev_r + tpl_clr);
            }
        }
        for (m = sel) {
            translate([m[1], m[2], -1]) cylinder(d = mag_d + tpl_hole_clr, h = 10, $fn = 48);
            // small hole beside holes where the iPad's own magnet shows N
            if (m[3] == "N") translate([m[1] + mag_d/2 + 1.9, m[2], -1]) cylinder(d = 1.3, h = 10, $fn = 12);
        }
        translate([cam_c[0], cam_c[1], -1]) linear_extrude(10) rrect(cam_sq + 1.6, cam_sq + 1.6, cam_r + 0.8);
        for (i = [-1 : 1]) translate([i*pin_pitch, 0, -1]) cylinder(d = 1.6, h = 10, $fn = 12);
        for (p = concat(mount_pts, [dev_c])) translate([p[0], p[1], -1]) cylinder(d = 3, h = 10, $fn = 24);
    }
}
module template_half(top) intersection() {
    template_body();
    translate([-500, top ? split_y : split_y - 1000, -1]) cube([1000, 1000, 20]);
}

module plug() {
    cone = (cs_d - hole_d)/2;
    cylinder(d1 = cs_d - 0.3, d2 = hole_d - 0.2, h = cone - 0.05, $fn = 48);
    translate([0, 0, cone - 0.1]) cylinder(d = hole_d - 0.3, h = 3, $fn = 32);
}

// pockets must never break into the back-side cutters (groove, countersinks,
// charger recess, camera notch): renders EMPTY when the layout is sound.
module check() intersection() {
    union() pockets(0);
    union() {
        back_cuts();
        for (p = mount_pts) translate([p[0], p[1], -1]) cylinder(d = cs_d, h = plate_thk + 2, $fn = 24);
        if (charger) charger_cut();
        translate([0, 0, -1]) linear_extrude(plate_thk + 2) cam_notch2d(cam_clr);
    }
}

if      (part == "mount")           mount_body();
else if (part == "mount_bottom")    mount_bottom();
else if (part == "mount_top")       mount_top();
else if (part == "template")        template_body();
else if (part == "template_bottom") template_half(false);
else if (part == "template_top")    template_half(true);
else if (part == "plug")            plug();
else if (part == "check")           check();
