// =====================================================================
// Pillow Blower Counter - desk stand for the CYD with 3 top buttons.
//
// Remix of the "32 degree, symmetrical bezel" CYD desk stand STL: same
// 32-degree screen tilt, same front-panel-in-a-pocket construction,
// but the top no longer slopes down to the back. It runs straight back
// (horizontal) far enough to carry a row of 16 mm chassis-mount push
// buttons facing UP, so an operator in gloves can slap them from above.
//
// Parts  (openscad -o x.stl -D 'part="base"' cyd_desk_stand.scad):
//   base      the stand (prints as modelled, floor down; the flat top
//             bridges ~40 mm - fine on any printer)
//   bezel     front panel, exported face-down (Y flipped in mesh probes)
//   btn_test  30 mm square with one button hole - print first to check
//             the 16 mm hole and nut on the 3.2 mm top
//   assembly  preview with board + buttons
//   check_*   boolean interference checks - must render EMPTY:
//             check_buttons (button bodies vs board envelope),
//             check_bosses  (bezel screw bosses vs board envelope)
//
// Assembly: screw the CYD to the bezel posts from behind (4x M3 self-
// tapping through the PCB holes), drop the bezel+board into the front
// pocket, 4x M3 countersunk through the bezel corners into the base
// bosses. Buttons drop through the top, nuts inside (reach in through
// the front opening before fitting the bezel). USB cable out the side.
//
// Coordinates (in use): x across, y depth with the BACK FACE at y = 0
// and the screen toward -y, z up from the desk.
// =====================================================================
part = "assembly";

/* ---------------- CYD board (shared with the wall case) ----------- */
include <cyd_board.scad>       // pcb, pcb_holes, glass, active, usb_y, usb_slot, under_pcb ...
pcb_shift    = 0;              // slide the board sideways in the panel (+x = toward the USB side)

/* ---------------- buttons (16 mm chassis mount, nut from inside) ----- */
buttons      = [["+", 16.3], ["-", 16.3], ["BATCH", 16.3]];   // [label, panel hole dia], left to right
btn_pitch    = 30;             // centre spacing along the top
btn_nut_d    = 22;             // across-corners of the mounting nut (sets the top depth)
btn_body_d   = 18;             // widest part of the body below the panel
btn_body_len = 30;             // body + terminals below the panel (preview / clearance)
btn_clr      = 1.0;            // air around nut / body
labels       = true;           // engraved labels in front of the holes
label_h      = 5;

/* ---------------- stand ------------------------------------------- */
tilt         = 32;             // screen tilt back from vertical (degrees)
H            = 62;             // height of the flat top
panel        = [104, 58.4];    // bezel outline (original was 100 x 58.4 - widened for corner screws)
rim          = 1.4;            // body around the panel pocket -> front face 106.8 x 61.2
wall         = 2.4;
top_t        = 3.2;            // button panel thickness
floor_t      = 2.4;
corner_r     = 3;              // rear vertical edges and the top-back edge
toe_angle    = 45;             // undercut under the screen (printable overhang)
top_depth_min = 0;             // force a deeper top (e.g. for a cable gland); 0 = as needed

/* ---------------- bezel & fixings --------------------------------- */
bezel_t      = 2.0;            // plate; sits flush in a pocket of the same depth
panel_clr    = 0.2;            // pocket clearance per side
glass_gap    = 0.5;            // glass top -> back of the bezel plate
post_d       = 6;              // bezel posts that the PCB screws onto
post_hole_d  = 2.6;            // M3 self-tapping (4.0 for heat-set inserts)
window_margin = 1.0;           // window = active area + this per side
opening_clr  = 0.75;           // base opening = PCB + this per side
boss_d       = 6.5;            // base bosses for the bezel corner screws
boss_len     = 10;
boss_hole_d  = 2.6;
boss_inset   = 4.5;            // screw centre from the panel edges
usb_side     = 1;              // +1 = cable out the right wall (CYD USB end), -1 = left
aux_hole_d   = 0;              // grommet hole in the back wall (0 = none)
aux_hole_z   = 20;

$fn = 64;
EPS = 0.01;

/* ---------------- derived ------------------------------------------- */
W        = panel[0] + 2 * rim;                    // overall width
L        = panel[1] + 2 * rim;                    // front face length along the slope
frame_t  = bezel_t + glass_gap + glass_h;         // front face -> PCB top surface
stack    = frame_t + pcb_t + under_pcb;           // front face -> deepest board component
sT = sin(tilt); cT = cos(tilt); tT = tan(tilt);

// Button row: nut clears the back wall; body clears the board envelope
// (a plane parallel to the screen, `stack` behind it) at the top.
y_btn    = -(wall + btn_nut_d / 2 + btn_clr);
y_tf_a   = y_btn - (stack / cT - top_t * tT + btn_body_d / 2 + btn_clr);   // board clearance
y_tf_b   = y_btn - (btn_nut_d / 2 + btn_clr) - wall / cT + top_t * tT;     // nut vs front wall
y_tf     = min(y_tf_a, y_tf_b, -top_depth_min);   // top-front edge (y)
top_depth = -y_tf;
y_bf     = y_tf - L * sT;   z_bf = H - L * cT;    // bottom-front edge of the screen face
yc       = y_tf - L / 2 * sT;  zc = H - L / 2 * cT;   // centre of the screen face
toe_run  = z_bf / tan(toe_angle);
D        = -y_bf;                                  // overall depth

n_btn    = len(buttons);
btn_xs   = [for (i = [0 : n_btn - 1]) (i - (n_btn - 1) / 2) * btn_pitch];
pcb_o    = [-pcb[0] / 2 + pcb_shift, -pcb[1] / 2];          // PCB corner in the panel frame (u,v)
hole_uv  = [for (h = pcb_holes) [pcb_o[0] + h[0], pcb_o[1] + h[1]]];
active_c = [pcb_o[0] + active_pos[0] + active[0] / 2, pcb_o[1] + active_pos[1] + active[1] / 2];
boss_uv  = [for (sx = [-1, 1], sy = [-1, 1]) [sx * (panel[0] / 2 - boss_inset), sy * (panel[1] / 2 - boss_inset)]];
opening  = [pcb[0] + 2 * opening_clr, pcb[1] + 2 * opening_clr];

echo(str("stand ", W, " W x ", D, " D x ", H, " H mm; top depth ", top_depth,
         "; buttons at y=", y_btn, " x=", btn_xs, "; screen face ", W, " x ", L));
assert(z_bf > floor_t + 3, "screen face runs into the floor - reduce panel height or raise H");
assert(n_btn * btn_pitch - btn_pitch + btn_nut_d + 2 * btn_clr < W - 2 * wall, "button row too wide");

/* ---------------- frames & 2D helpers ------------------------------ */
// Panel frame: origin at the centre of the screen face, x across,
// y up the slope, z = outward normal (into the base is -z).
module at_front() translate([0, yc, zc]) rotate([90 - tilt, 0, 0]) children();

module rrect(size, r) { offset(r = r) offset(delta = -r) square(size, center = true); }

// side profile (2D x = world y, 2D y = world z); convex
module profile2d() hull() {
    translate([-corner_r, H - corner_r]) circle(corner_r);
    polygon([[0, 0], [0, H - corner_r], [y_tf, H], [y_bf, z_bf], [y_bf + toe_run, 0]]);
}
// plan (XY): rounded rear corners, near-sharp front corners
module plan2d() hull() {
    for (sx = [-1, 1]) {
        translate([sx * (W / 2 - corner_r), -corner_r]) circle(corner_r);
        translate([sx * (W / 2 - 0.5), y_bf - 0.5]) circle(0.5);
    }
}
module body(inset = 0) intersection() {
    rotate([90, 0, 90]) linear_extrude(W - 2 * inset, center = true) offset(r = -inset) profile2d();
    translate([0, 0, -1]) linear_extrude(H + 2) offset(r = -inset) plan2d();
}
module label_text(s) text(s, size = label_h, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");

/* ---------------- base ---------------------------------------------- */
module base() {
    difference() {
        union() {
            difference() {
                body();
                intersection() {                     // cavity: wall everywhere, thicker top
                    body(wall);
                    translate([-W, -2 * D, floor_t]) cube([2 * W, 4 * D, H - top_t - floor_t]);
                }
            }
            intersection() {                         // front frame (bezel seat) + corner bosses
                body();
                at_front() {
                    translate([0, 0, -frame_t]) linear_extrude(frame_t) difference() {
                        square([W + 2, L + 2], center = true);
                        rrect(opening, 2);
                    }
                    for (p = boss_uv) translate([p[0], p[1], -boss_len - bezel_t])
                        cylinder(d = boss_d, h = boss_len + bezel_t);
                }
            }
        }
        at_front() {
            // bezel pocket (flush) and the opening behind it
            translate([0, 0, -bezel_t]) linear_extrude(bezel_t + 5) rrect(panel + [2 * panel_clr, 2 * panel_clr], 3);
            translate([0, 0, -frame_t - 1]) linear_extrude(frame_t + 2) rrect(opening, 2);
            for (p = boss_uv) translate([p[0], p[1], -boss_len - bezel_t + 1]) cylinder(d = boss_hole_d, h = boss_len + 1);
            // USB cable slot through the side wall, below the PCB
            usb_u = usb_side > 0 ? pcb_o[0] + pcb[0] : pcb_o[0];
            translate([usb_u, pcb_o[1] + usb_y, -frame_t - pcb_t - usb_slot[1] / 2 + 0.5])
                rotate([0, 90, 0]) hull() for (s = [-1, 1])
                    translate([0, s * (usb_slot[0] - usb_slot[1]) / 2, 0])
                        cylinder(d = usb_slot[1], h = 2 * (W / 2 - abs(usb_u) + 2), center = true);
        }
        // button holes + labels in the top
        for (i = [0 : n_btn - 1]) {
            translate([btn_xs[i], y_btn, H - top_t - 1]) cylinder(d = buttons[i][1], h = top_t + 2);
            if (labels)
                translate([btn_xs[i], y_btn - buttons[i][1] / 2 - label_h / 2 - 2.5, H - 0.6])
                    linear_extrude(0.6 + EPS) label_text(buttons[i][0]);
        }
        if (aux_hole_d > 0) translate([0, 1, aux_hole_z]) rotate([90, 0, 0]) cylinder(d = aux_hole_d, h = wall + 2);
    }
}

/* ---------------- bezel (panel frame, front face at z = 0) ---------- */
module window2d(grow = 0) translate(active_c) rrect(active + [2 * (window_margin + grow), 2 * (window_margin + grow)], 2 + grow);

module bezel() {
    difference() {
        union() {
            hull() {                                 // plate with a 0.8 mm chamfer on the front edge
                translate([0, 0, -bezel_t]) linear_extrude(bezel_t - 0.8) rrect(panel, 3);
                translate([0, 0, -EPS]) linear_extrude(EPS) rrect(panel - [1.6, 1.6], 2.2);
            }
            for (p = hole_uv) translate([p[0], p[1], -bezel_t - (glass_gap + glass_h)])
                cylinder(d = post_d, h = glass_gap + glass_h + EPS);
        }
        translate([0, 0, -bezel_t - 1]) linear_extrude(bezel_t + 2) window2d();
        hull() {                                     // 1 mm 45-degree chamfer on the window
            translate([0, 0, -1]) linear_extrude(EPS) window2d();
            linear_extrude(EPS) window2d(1);
        }
        for (p = hole_uv) translate([p[0], p[1], -bezel_t - glass_gap - glass_h - 1])
            cylinder(d = post_hole_d, h = glass_gap + glass_h + 1 + bezel_t - 0.6);   // blind, 0.6 mm short of the face
        for (p = boss_uv) translate([p[0], p[1], -bezel_t - 1]) {          // countersunk M3
            cylinder(d = 3.4, h = bezel_t + 2);
            translate([0, 0, bezel_t + 1 - 1.6]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.6 + EPS);
        }
    }
}

/* ---------------- mock-ups / checks --------------------------------- */
module pcb_envelope() at_front() translate([pcb_o[0], pcb_o[1], -stack]) cube([pcb[0], pcb[1], stack - frame_t + glass_h]);
module pcb_mock() at_front() translate([pcb_o[0], pcb_o[1], -frame_t]) {
    color("darkgreen") translate([0, 0, -pcb_t]) cube([pcb[0], pcb[1], pcb_t]);
    color("white") translate([glass_pos[0], glass_pos[1], 0]) cube([glass[0], glass[1], glass_h - 0.3]);
    color("black") translate([active_pos[0], active_pos[1], glass_h - 0.3]) cube([active[0], active[1], 0.3]);
    color("dimgray", 0.5) translate([0, 0, -pcb_t - under_pcb]) cube([pcb[0], pcb[1], under_pcb]);
}
module button_bodies() for (x = btn_xs) translate([x, y_btn, H - top_t - btn_body_len]) cylinder(d = btn_body_d, h = btn_body_len);
module button_mock() for (x = btn_xs) translate([x, y_btn, 0]) {
    color("silver") translate([0, 0, H - top_t - btn_body_len]) cylinder(d = btn_body_d, h = btn_body_len);
    color("silver") translate([0, 0, H - top_t - 3.5]) cylinder(d = btn_nut_d / 1.15, h = 3.5, $fn = 6);
    color("black") translate([0, 0, H - 0.5]) cylinder(d = 18, h = 3.5);
}
module bosses() at_front() for (p = boss_uv) translate([p[0], p[1], -boss_len - bezel_t]) cylinder(d = boss_d, h = boss_len + bezel_t);

module btn_test() difference() {
    linear_extrude(top_t) rrect([30, 30], 3);
    translate([0, 0, -1]) cylinder(d = buttons[0][1], h = top_t + 2);
}

if (part == "base")          base();
if (part == "bezel")         rotate([180, 0, 0]) bezel();
if (part == "btn_test")      btn_test();
if (part == "assembly")      { base(); pcb_mock(); button_mock(); at_front() translate([0, 0, 12]) color("gold", 0.8) bezel(); }
if (part == "check_buttons") intersection() { button_bodies(); pcb_envelope(); }
if (part == "check_bosses")  intersection() { bosses(); translate([0, 0, 0.02]) pcb_envelope(); }
