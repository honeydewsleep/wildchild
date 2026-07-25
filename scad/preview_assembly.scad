// =====================================================================
// Visual assembly preview (not a printable part)
//
// view = "usb"      : full lamp, base + notched plate, USB powered
// view = "battery"  : full lamp on the 4xAA cube battery tub
// view = "cutaway"  : half-section through the cable notch plane
// view = "threads"  : section through base + seated plate threads only
// =====================================================================
include <params.scad>
use <base.scad>
use <bottom_plate.scad>
use <battery_tub.scad>
use <ring.scad>

view = "usb";

module ring_assembled() {
    // ring axis local z -> base y; tab (local -y) -> base -z
    ring_z = base_h - slot_depth + (ring_od/2 + tab_len + 0.5);
    translate([0, 0, ring_z]) rotate([90, 0, 0]) {
        color("WhiteSmoke") translate([0, 0, -ring_t/2]) ring_half();
        color("WhiteSmoke") translate([0, 0, ring_t/2]) rotate([0, 180, 0]) ring_half();
        color("LightCyan", 0.45) {
            translate([0, 0, -ring_t/2 + ring_face_t - rebate_depth]) diffuser();
            translate([0, 0, ring_t/2 - ring_face_t + rebate_depth - diffuser_t])
                diffuser();
        }
    }
}

module lamp_usb() {
    color("DimGray") base_body(true);
    color("SteelBlue") translate([0, 0, -plate_t]) bottom_plate(true);
    ring_assembled();
}

module lamp_battery() {
    color("DimGray") base_body(true);
    tub_h = 3.2 + pocket_cube[2] + tub_top_t;
    color("SteelBlue") translate([0, 0, -tub_h]) battery_tub(pocket_cube, tub_od_cube);
    color("SlateGray") translate([0, 0, -tub_h]) battery_door(pocket_cube);
    ring_assembled();
}

if (view == "usb")
    lamp_usb();
else if (view == "battery")
    lamp_battery();
else if (view == "cutaway")
    difference() {
        lamp_usb();
        translate([0, -300, -300]) cube([600, 600, 600]);  // keep x<0... cut x>0
    }
else if (view == "threads")
    difference() {
        union() {
            color("DimGray") intersection() {
                base_body(true);
                cylinder(h = 14, d = base_od + 2, $fn = 64);
            }
            color("SteelBlue") translate([0, 0, -plate_t]) bottom_plate(true);
        }
        translate([0, -300, -300]) cube([600, 600, 600]);
    }
