// Boolean fit checks for the hex pen.
//   openscad -o /tmp/x.stl -D 'mode="clearance"' fit_check.scad   -> must be EMPTY
//   openscad -o /tmp/x.stl -D 'mode="pin_clearance"' fit_check.scad -> must be EMPTY
//   openscad -o /tmp/x.stl -D 'mode="pin_engagement"' fit_check.scad -> must be NON-empty
include <params.scad>
use <body.scad>
use <plunger.scad>

mode = "clearance";

// plunger sitting in the bore, pin at the bottom of the main slot
pin_z = slot_z_bottom + slot_r_out * sin(slot_half_out);   // 11.48 = rounded end centre
module plunger_in_place() translate([0, 0, pin_z - pl_pin_z]) rotate([0, 0, slot_angle - 270]) plunger();
// the pin itself: Ø2.75 x 10.5, from the far bore wall out through the slot
module pin() translate([0, 0, pin_z]) rotate([0, 0, slot_angle]) rotate([0, 90, 0])
                 translate([0, 0, -3.5]) cylinder(h = 10.5, r = pl_pin_r, $fn = 48);

if (mode == "clearance")      intersection() { body("hex"); plunger_in_place(); }
if (mode == "pin_clearance")  intersection() { body("hex"); pin(); }          // pin passes the slot at its bottom
if (mode == "pin_engagement") intersection() { plunger_in_place(); pin(); }   // pin is inside the plunger hole
if (mode == "assembly")       { body("hex"); plunger_in_place(); pin(); }
