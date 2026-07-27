// =====================================================================
// Energy Ring Remix - screw-on battery tub (replaces the flat plate)
//
// Same male thread and clocking as the bottom plate, but the plate
// extends downward into a battery compartment. Batteries load through
// a screw-fastened door on the underside (2x M3 self-tapping), so the
// tub itself never needs to come off for a battery change.
//
// Pocket sizes fit common purchased battery boxes:
//   tub_4aa_cube : two 2xAA boxes (~58x31.5x15.5) stacked, or one
//                  4xAA 2x2 "cube" holder (~58x32x29)
//   tub_4aa_flat : one flat 4xAA holder (~62x58x15.5), 4 cells in a row
//   tub_8aa_flat : two flat 4xAA holders stacked -> 8 cells, 12 V pack
//
// part = tub_4aa_cube | tub_4aa_flat | tub_8aa_flat | door_cube | door_flat
// =====================================================================
include <params.scad>
use <lib/threads.scad>
use <bottom_plate.scad>   // male_thread_ring(), esp_rails(), plate_notch geometry

part = "tub_4aa_cube";

/* ------------------------- derived helpers ------------------------ */
function tub_h(pocket)       = tub_floor_t + pocket[2] + tub_top_t;
function opening_sz(pocket)  = [pocket[0] - 2*door_ledge, pocket[1] - 2*door_ledge];
function pad_x(pocket)       = pocket[0]/2 + 4.5;

ear_w    = 14;    // door ear tab width (along X)
ear_d    = 12;    // door ear tab depth (along Y)
recess_t = 2.5;   // door recess depth in the floor
tub_floor_t_eff = 3.2;   // slightly thicker floor than params default

/* -------- door outline: main rect + screw ear tabs at +/-X --------- */
module door_outline_2d(pocket, grow = 0) {
    op = opening_sz(pocket);
    ox = pad_x(pocket);
    square([op[0] - 0.6 + 2*grow, op[1] - 0.6 + 2*grow], center = true);
    for (sx = [-1, 1]) scale([sx, 1])
        translate([0, -ear_d/2 - grow])
            square([ox + ear_w/2 + grow, ear_d + 2*grow]);
}

/* ------------------------------ tub -------------------------------- */
module battery_tub(pocket, od, use_switch = switch_cutout) {
    H   = tub_floor_t_eff + pocket[2] + tub_top_t;
    ir  = od/2 - tub_wall;
    op  = opening_sz(pocket);
    px  = pad_x(pocket);
    switch_vertical = pocket[2] >= switch_h + 5;

    difference() {
        union() {
            // shell: outer cylinder with floor and top plate
            difference() {
                cylinder(h = H, d = od, $fn = FN_ROUND);
                translate([0, 0, tub_floor_t_eff])
                    cylinder(h = H - tub_floor_t_eff - tub_top_t, r = ir, $fn = FN_ROUND);
            }
            // rectangular pocket walls inside the bore
            translate([-(pocket[0]/2 + 2), -(pocket[1]/2 + 2), tub_floor_t_eff - EPS])
                cube([pocket[0] + 4, pocket[1] + 4, pocket[2] + EPS]);
            // door screw pads + gussets to the wall
            for (sx = [-1, 1]) scale([sx, 1, 1]) {
                translate([px, 0, recess_t])
                    cylinder(h = 8, d = 9, $fn = 48);
                translate([px, -3, recess_t])
                    cube([ir - px + 0.5, 6, 7.5]);
            }
            // male thread ring on the datum (top) face
            translate([0, 0, H]) male_thread_ring();
            // ESP32 rails ride on the tub top
            translate([0, 0, H]) esp_rails();
        }

        // battery pocket
        translate([-pocket[0]/2, -pocket[1]/2, tub_floor_t_eff])
            cube([pocket[0], pocket[1], pocket[2] + EPS]);
        // door opening + recess in the floor
        translate([0, 0, -EPS]) {
            linear_extrude(height = tub_floor_t_eff + 2*EPS)
                square([op[0], op[1]], center = true);
            linear_extrude(height = recess_t + EPS)
                door_outline_2d(pocket, grow = 0.3);
        }
        // screw pilot holes
        for (sx = [-1, 1])
            translate([sx*px, 0, recess_t - EPS])
                cylinder(h = 8.2, d = 2.7, $fn = 24);
        // pack-lead pass-through in the top plate
        translate([23, 12, H - tub_top_t - EPS])
            cylinder(h = tub_top_t + 2*EPS, d = tub_wire_hole_d, $fn = 48);
        // cable notch through the top plate edge + thread ring,
        // matching the bottom plate's notch (same clocking)
        rotate([0, 0, notch_angle - 270])
            translate([-plate_notch_w/2, -od/2 - 4, H - tub_top_t - EPS])
                cube([plate_notch_w, (od/2 + 4) - 31, tub_top_t + thr_len + 2]);
        // grip scallop band near the top of the wall
        for (i = [0:grip_n - 1])
            rotate([0, 0, (i + 0.5)*360/grip_n])
                translate([od/2, 0, H - 14])
                    cylinder(h = 14 + thr_len, d = grip_d, $fn = 24);
        // optional rocker switch cutout, front wall (theta=90)
        if (use_switch) {
            sw = switch_vertical ? [switch_w, switch_h] : [switch_h, switch_w];
            rotate([0, 0, 90 - 270])
                rotate([90, 0, 0])
                    translate([0, tub_floor_t_eff + pocket[2]/2, 0])
                        linear_extrude(height = od)
                            square(sw, center = true);
        }
        // feet dimples (locate adhesive rubber feet), angled to stay
        // clear of the door recess and its ear tabs
        for (a = [30, 150, 210, 330])
            rotate([0, 0, a])
                translate([od/2 - 6.5, 0, -EPS])
                    cylinder(h = 0.6 + EPS, d = foot_d, $fn = 48);
    }
}

/* ------------------------------ door ------------------------------- */
module battery_door(pocket) {
    difference() {
        linear_extrude(height = door_t)
            door_outline_2d(pocket, grow = 0);
        for (sx = [-1, 1]) {
            translate([sx*pad_x(pocket), 0, -EPS])
                cylinder(h = door_t + 2*EPS, d = 3.4, $fn = 24);
            // countersink on the outside (desk) face
            translate([sx*pad_x(pocket), 0, -EPS])
                cylinder(h = 1.6, d1 = 6.4, d2 = 3.4, $fn = 24);
        }
    }
}

/* ------------------------- part selection -------------------------- */
if (part == "tub_4aa_cube")
    battery_tub(pocket_cube, tub_od_cube);
else if (part == "tub_4aa_flat")
    battery_tub(pocket_flat4, tub_od_flat);
else if (part == "tub_8aa_flat")
    battery_tub(pocket_flat8, tub_od_flat);
else if (part == "door_cube")
    battery_door(pocket_cube);
else if (part == "door_flat")
    battery_door(pocket_flat4);
