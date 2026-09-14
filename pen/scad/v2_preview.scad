// v2 assembly preview (not a print file)
include <params.scad>
use <v2_barrel.scad>
use <v2_grip.scad>
use <plunger.scad>
gap = 0;   // set >0 to explode
color("steelblue") barrel(false);
translate([0, 0, b_joint_z + gap]) rotate([180, 0, 0]) translate([0, 0, -g_knurl_end]) color("slategray") grip();
color("orange") translate([0, 0, 1.75]) plunger();
