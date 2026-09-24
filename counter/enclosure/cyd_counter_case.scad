// =====================================================================
// Pillow Blower Counter - enclosure for the ESP32 "Cheap Yellow Display"
// (ESP32-2432S028R, 2.8" 320x240 touch) plus a row of panel buttons.
//
// Layout: screen on top, a row of big glove-friendly buttons below it,
// USB cable out of the right-hand wall, keyholes + zip-tie slots on the
// back for mounting to the blower.
//
// Parts  (openscad -o x.stl -D 'part="box"' cyd_counter_case.scad):
//   fit_test  1.2 mm plate: PCB holes, screen window, button holes.
//             PRINT THIS FIRST and lay it on the board - the CYD
//             dimensions below are from published drawings, not from
//             calipers on this exact board revision.
//   box       back shell (prints as modelled, open side up)
//   bezel     front plate (exported face-down)
//   assembly  exploded preview
//
// All dimensions mm. z = 0 is the outside of the back face, +z toward
// the screen.
// =====================================================================
part = "assembly";

/* ---------------- CYD board - VERIFY with fit_test ------------------ */
include <cyd_board.scad>       // pcb, pcb_holes, glass, active, usb_y, usb_slot, under_pcb ...

/* ---------------- buttons ------------------------------------------ */
// [label, panel hole diameter]. Left to right. Momentary 12 mm for +/-,
// a 16 mm latching switch for BATCH (ON = batch running).
buttons      = [["+", 12.3], ["-", 12.3], ["BATCH", 16.3]];
btn_zone     = 40;             // height of the button strip under the screen
btn_body_depth = 20;           // longest button body behind the panel (sets box depth)
labels       = true;           // recessed labels under the holes

/* ---------------- shell -------------------------------------------- */
wall         = 2.4;
floor_t      = 2.0;
bezel_t      = 2.4;
corner_r     = 5;
margin       = 1.5;            // PCB edge -> inside wall
window_margin = 1.0;           // bezel opening = active area + this per side
post_d       = 7;              // bezel screw posts
post_hole_d  = 2.6;            // M3 self-tapping (use 4.0 for M3 heat-set inserts)
standoff_d   = 6.5;
standoff_hole_d = 2.6;
skirt_h      = 2.0;            // bezel alignment lip that drops into the box
keyholes     = true;           // two keyholes on the back (screw heads up to 8 mm)
keyhole_pitch = 60;
zip_slots    = true;           // 4 slots on the back for zip ties / a strap
aux_hole_d   = 6.5;            // grommet hole in the left wall for a future sensor cable (0 = none)
clr          = 0.3;

$fn = 64;
EPS = 0.01;

/* ---------------- derived ------------------------------------------- */
post_strip  = post_d + 1;                            // strip above the PCB that holds the top posts
in_w        = pcb[0] + 2 * margin;
in_h        = post_strip + margin + pcb[1] + margin + btn_zone;
in_d        = max(under_pcb + pcb_t + glass_h + 0.5, btn_body_depth + 1);
standoff_h  = in_d - 0.5 - glass_h - pcb_t;          // glass top ends 0.5 below the bezel
rim_z       = floor_t + in_d;
pcb_z       = floor_t + standoff_h;                   // PCB underside
pcb_origin  = [-pcb[0] / 2, -in_h / 2 + btn_zone + margin];
hole_pts    = [for (h = pcb_holes) [pcb_origin[0] + h[0], pcb_origin[1] + h[1]]];
active_c    = [pcb_origin[0] + active_pos[0] + active[0] / 2,
               pcb_origin[1] + active_pos[1] + active[1] / 2];
post_in     = post_d / 2 - 0.3;                       // post centre inset from the inside wall
post_pts    = [[-in_w / 2 + post_in,  in_h / 2 - post_in], [in_w / 2 - post_in,  in_h / 2 - post_in],
               [-in_w / 2 + post_in, -in_h / 2 + post_in], [in_w / 2 - post_in, -in_h / 2 + post_in]];
btn_yc      = -in_h / 2 + btn_zone / 2 + 2;
n_btn       = len(buttons);
btn_span    = in_w - 2 * (post_d + 1);
btn_xs      = [for (i = [0 : n_btn - 1]) -btn_span / 2 + btn_span * (i + 0.5) / n_btn];

echo(str("outer size ", in_w + 2 * wall, " x ", in_h + 2 * wall, " x ", rim_z + bezel_t,
         " mm, standoff ", standoff_h));

/* ---------------- 2D helpers ---------------------------------------- */
module rrect(size, r) { offset(r = r) offset(delta = -r) square(size, center = true); }
module outer2d()    { rrect([in_w + 2 * wall, in_h + 2 * wall], corner_r); }
module interior2d() { rrect([in_w, in_h], corner_r - wall); }
module window2d(grow = 0) {
    translate(active_c) rrect([active[0] + 2 * (window_margin + grow),
                               active[1] + 2 * (window_margin + grow)], 2 + grow);
}

/* ---------------- box ------------------------------------------------ */
module box() {
    difference() {
        union() {
            difference() {
                linear_extrude(rim_z) outer2d();
                translate([0, 0, floor_t]) linear_extrude(in_d + 1) interior2d();
            }
            for (p = post_pts) translate([p[0], p[1], 0]) cylinder(d = post_d, h = rim_z);
            for (p = hole_pts) translate([p[0], p[1], 0]) cylinder(d = standoff_d, h = pcb_z);
        }
        // bezel screws + PCB screws
        for (p = post_pts) translate([p[0], p[1], rim_z - 12]) cylinder(d = post_hole_d, h = 13);
        for (p = hole_pts) translate([p[0], p[1], pcb_z - 8]) cylinder(d = standoff_hole_d, h = 9);
        // USB cable slot in the +x wall (plug body sits under the PCB)
        translate([in_w / 2 - EPS, pcb_origin[1] + usb_y, pcb_z - 1.0])   // slot centred 1 mm under the PCB
            rotate([90, 0, 90]) linear_extrude(wall + 2 * EPS) rrect(usb_slot, 2);
        // future sensor cable grommet, -x wall, near the floor
        if (aux_hole_d > 0)
            translate([-in_w / 2 - wall - EPS, pcb_origin[1] + pcb[1] / 2, floor_t + aux_hole_d / 2 + 1])
                rotate([0, 90, 0]) cylinder(d = aux_hole_d, h = wall + 2 * EPS);
        // wall-mount keyholes (screw head <= 8 mm, shank <= 4.3 mm), slot runs upward
        if (keyholes) for (sx = [-1, 1]) translate([sx * keyhole_pitch / 2, pcb_origin[1] + pcb[1] / 2 - 6, -EPS]) {
            cylinder(d = 8.5, h = floor_t + 2 * EPS);
            translate([-2.25, 0, 0]) cube([4.5, 10, floor_t + 2 * EPS]);
            translate([0, 10, 0]) cylinder(d = 4.5, h = floor_t + 2 * EPS);
        }
        // zip-tie / strap slots through the back
        if (zip_slots) for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * (in_w / 2 - 8), sy * 22 + pcb_origin[1] + pcb[1] / 2 - 6, -EPS])
                linear_extrude(floor_t + 2 * EPS) square([8, 3.2], center = true);
    }
}

/* ---------------- bezel --------------------------------------------- */
module label_text(t) {
    text(t, size = t == "+" || t == "-" ? 7 : 5, halign = "center", valign = "center",
         font = "Liberation Sans:style=Bold");
}

module bezel() {
    difference() {
        union() {
            translate([0, 0, rim_z]) linear_extrude(bezel_t) outer2d();
            // alignment skirt inside the box wall, notched around the posts
            translate([0, 0, rim_z - skirt_h]) linear_extrude(skirt_h) difference() {
                offset(delta = -clr) interior2d();
                offset(delta = -clr - 1.6) interior2d();
                for (p = post_pts) translate(p) circle(d = post_d + 2 * clr + 0.4);
            }
        }
        // screen window, with a 1.2 mm 45-degree chamfer on the front edge
        translate([0, 0, rim_z - 1]) linear_extrude(bezel_t + 2) window2d();
        hull() {
            translate([0, 0, rim_z + bezel_t - 1.2]) linear_extrude(EPS) window2d();
            translate([0, 0, rim_z + bezel_t]) linear_extrude(EPS) window2d(1.2);
        }
        // countersunk M3 screws into the posts
        for (p = post_pts) translate([p[0], p[1], rim_z - skirt_h - 1]) {
            cylinder(d = 3.4, h = bezel_t + skirt_h + 2);
            translate([0, 0, skirt_h + 1 + bezel_t - 1.6]) cylinder(d1 = 3.4, d2 = 6.6, h = 1.6 + EPS);
        }
        // button holes + labels
        for (i = [0 : n_btn - 1]) {
            translate([btn_xs[i], btn_yc, rim_z - 1]) cylinder(d = buttons[i][1], h = bezel_t + 2);
            if (labels)
                translate([btn_xs[i], btn_yc - buttons[i][1] / 2 - 4.5, rim_z + bezel_t - 0.6])
                    linear_extrude(0.6 + EPS) label_text(buttons[i][0]);
        }
    }
}

/* ---------------- fit test plate ------------------------------------ */
module fit_test() {
    strip = 26;
    size = [pcb[0] + 8, pcb[1] + 8 + strip];
    difference() {
        linear_extrude(1.2) rrect(size, 3);
        // PCB holes + active window, PCB corner at (-pcb/2 + 4, -size.y/2 + strip + 4)
        o = [-pcb[0] / 2, -size[1] / 2 + strip + 4];
        for (h = pcb_holes) translate([o[0] + h[0], o[1] + h[1], -1]) cylinder(d = pcb_hole_d + 0.2, h = 3);
        translate([o[0] + active_pos[0] + active[0] / 2, o[1] + active_pos[1] + active[1] / 2, -1])
            linear_extrude(3) rrect(active, 1);
        // engraved PCB and glass outlines (0.4 deep) to compare against the board
        translate([0, 0, 0.8]) linear_extrude(1) difference() {
            translate([o[0] + pcb[0] / 2, o[1] + pcb[1] / 2]) square(pcb, center = true);
            translate([o[0] + pcb[0] / 2, o[1] + pcb[1] / 2]) square(pcb - [0.8, 0.8], center = true);
        }
        translate([0, 0, 0.8]) linear_extrude(1) difference() {
            translate([o[0] + glass_pos[0] + glass[0] / 2, o[1] + glass_pos[1] + glass[1] / 2]) square(glass, center = true);
            translate([o[0] + glass_pos[0] + glass[0] / 2, o[1] + glass_pos[1] + glass[1] / 2]) square(glass - [0.8, 0.8], center = true);
        }
        // USB position notch on the +x edge
        translate([o[0] + pcb[0] + 4, o[1] + usb_y, -1]) linear_extrude(3) square([4, usb_slot[0]], center = true);
        // one hole per button diameter in the lower strip
        for (i = [0 : n_btn - 1])
            translate([btn_xs[i], -size[1] / 2 + strip / 2, -1]) cylinder(d = buttons[i][1], h = 3);
    }
}

/* ---------------- preview ------------------------------------------- */
module pcb_mock() {
    translate([pcb_origin[0], pcb_origin[1], pcb_z]) {
        color("darkgreen") linear_extrude(pcb_t) square(pcb);
        color("white") translate([glass_pos[0], glass_pos[1], pcb_t]) linear_extrude(glass_h - 0.3) square(glass);
        color("black") translate([active_pos[0], active_pos[1], pcb_t + glass_h - 0.3]) linear_extrude(0.3) square(active);
    }
}

if (part == "box")      box();
if (part == "bezel")    translate([0, 0, rim_z + bezel_t]) rotate([180, 0, 0]) bezel();
if (part == "fit_test") fit_test();
if (part == "assembly") { box(); pcb_mock(); translate([0, 0, 15]) color("gold", 0.8) bezel(); }
