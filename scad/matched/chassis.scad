// =====================================================================
// Matched series - CHASSIS (replaces the original slip-fit cup)
//
// Skirt Ø96 sits on the desk exactly like the original; the barrel
// above it now carries a MALE thread and the shell screws down onto
// it. The ESP32 rides on rails on the chassis floor, USB port facing
// notch_angle, so the clocked thread stops the shell's USB hole right
// in front of the port.
//
// Battery variants extend the skirt downward into a battery tub with
// the same underside screw door as series A (same door STLs).
//
// z=0 at the desk. Datum plane (shell rim seat) = top of the skirt.
// The male thread starts exactly at the datum plane - same clocking
// convention as the series A bottom plate, calibrated by the same
// plate_clock_adjust.
//
// part = chassis | chassis_bat_cube | chassis_bat_flat4 | chassis_bat_flat8
// (battery doors: use door_cube / door_flat from battery_tub.scad)
// =====================================================================
include <../params.scad>
use <../lib/threads.scad>
use <../bottom_plate.scad>   // male_thread_ring(), esp_rails(), zip_slots_cut()
use <../battery_tub.scad>    // door_outline_2d()

part = "chassis";

skirt_r  = m_skirt_od/2;          // 48
skirt_ir = skirt_r - 3;           // 45
barrel_or = thr_root_r;           // 40 (thread ribs rise to 41.6)
barrel_ir = 36.4;
ear_w = 14; ear_d = 12; recess_t = 2.5; floor_bat_t = 3.2;

/* --------------- core: skirt + threaded barrel + rails ------------- */
// skirt_h: desk to datum plane; floor_top: where the ESP32 rails sit
module chassis_core(skirt_h, floor_top) {
    difference() {
        union() {
            // skirt with rounded bottom edge
            rotate_extrude($fn = FN_ROUND)
                polygon([
                    [0, 0], [skirt_r - 1.5, 0], [skirt_r, 1.5],
                    [skirt_r, skirt_h], [0, skirt_h]
                ]);
            // barrel: plain pilot above the thread for easy starting
            translate([0, 0, skirt_h])
                cylinder(h = m_barrel_h, r = barrel_or, $fn = FN_ROUND);
            translate([0, 0, skirt_h]) male_thread_ring();
            translate([0, 0, floor_top]) esp_rails();
        }
        // hollow: from the floor top upward through the barrel
        translate([0, 0, floor_top])
            cylinder(h = skirt_h + m_barrel_h, r = barrel_ir, $fn = FN_ROUND);
        // taper the pilot tip
        translate([0, 0, skirt_h + m_barrel_h - 1.5])
            difference() {
                cylinder(h = 1.6, r = barrel_or + 2, $fn = FN_ROUND);
                cylinder(h = 1.6, r1 = barrel_or, r2 = barrel_or - 1.5, $fn = FN_ROUND);
            }
        // feet dimples
        for (a = [30, 150, 210, 330])
            rotate([0, 0, a])
                translate([skirt_r - 7, 0, -EPS])
                    cylinder(h = 0.6 + EPS, d = foot_d, $fn = 48);
        // USB passage through the barrel wall at the notch angle,
        // wider than the shell's hole so alignment has slack
        rotate([0, 0, notch_angle - 270])
            translate([-8, -skirt_r - 2, skirt_h])
                cube([16, skirt_r - 25, m_barrel_h + 1]);
    }
}

/* ------------------- standard (USB power) chassis ------------------ */
module chassis_std() {
    floor_top = m_skirt_h - 4;    // rails start 4 below the datum
    difference() {
        union() {
            chassis_core(m_skirt_h, floor_top);
            // floor disc carrying the rails
            cylinder(h = floor_top, r = skirt_ir + 0.5, $fn = FN_ROUND);
        }
        zip_slots_cut_at(floor_top);
        // wire pass for lamps living on battery bases too (spare)
        translate([23, 12, -EPS]) cylinder(h = floor_top + 2, d = 6, $fn = 32);
    }
}

module zip_slots_cut_at(face_t) {
    for (sx = [-1, 1])
        translate([sx*(esp_w/2 + rail_t + 2.2) - zip_slot[0]/2, -zip_slot[1]/2, -EPS])
            cube([zip_slot[0], zip_slot[1], face_t + 2*EPS]);
}

/* ----------------------- battery chassis --------------------------- */
module chassis_battery(pocket, use_switch = switch_cutout) {
    skirt_h  = floor_bat_t + pocket[2] + m_floor_t + 4;
    floor_top = skirt_h - 4;
    op = [pocket[0] - 2*door_ledge, pocket[1] - 2*door_ledge];
    px = pocket[0]/2 + 4.5;
    switch_vertical = pocket[2] >= switch_h + 5;

    difference() {
        union() {
            chassis_core(skirt_h, floor_top);
            // solid interior between door recess and the ESP32 floor;
            // the pocket is carved out of it below the floor
            cylinder(h = floor_top, r = skirt_ir + 0.5, $fn = FN_ROUND);
            // door screw pads (rise inside, beyond the pocket ends)
            for (sx = [-1, 1]) scale([sx, 1, 1]) {
                translate([px, 0, recess_t]) cylinder(h = 8, d = 9, $fn = 48);
                translate([px, -3, recess_t]) cube([skirt_ir - px + 0.5, 6, 7.5]);
            }
        }
        // battery pocket
        translate([-pocket[0]/2, -pocket[1]/2, floor_bat_t])
            cube([pocket[0], pocket[1], pocket[2]]);
        // door opening + recess in the underside
        translate([0, 0, -EPS]) {
            linear_extrude(height = floor_bat_t + 2*EPS)
                square([op[0], op[1]], center = true);
            linear_extrude(height = recess_t + EPS)
                door_outline_2d(pocket, grow = 0.3);
        }
        for (sx = [-1, 1])
            translate([sx*px, 0, recess_t - EPS])
                cylinder(h = 8.2, d = 2.7, $fn = 24);
        // pack-lead hole through the ESP32 floor
        translate([23, 12, floor_bat_t + pocket[2] - EPS])
            cylinder(h = m_floor_t + 4 + 1, d = tub_wire_hole_d, $fn = 48);
        zip_slots_cut_at_z(floor_top - m_floor_t, m_floor_t);
        // rocker switch in the skirt wall, front (theta = 90)
        if (use_switch) {
            sw = switch_vertical ? [switch_w, switch_h] : [switch_h, switch_w];
            rotate([0, 0, 90 - 270])
                rotate([90, 0, 0])
                    translate([0, floor_bat_t + pocket[2]/2, 0])
                        linear_extrude(height = skirt_r + 5)
                            square(sw, center = true);
        }
    }
}

module zip_slots_cut_at_z(z0, t) {
    for (sx = [-1, 1])
        translate([sx*(esp_w/2 + rail_t + 2.2) - zip_slot[0]/2, -zip_slot[1]/2, z0 - EPS])
            cube([zip_slot[0], zip_slot[1], t + 2*EPS]);
}

/* ------------------------- part selection -------------------------- */
if (part == "chassis")               chassis_std();
else if (part == "chassis_bat_cube") chassis_battery(pocket_cube);
else if (part == "chassis_bat_flat4") chassis_battery(pocket_flat4);
else if (part == "chassis_bat_flat8") chassis_battery(pocket_flat8);
