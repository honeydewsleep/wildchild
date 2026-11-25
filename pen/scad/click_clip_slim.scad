// Click pen clip for the slim housing.
//   openscad -o click_clip_slim.stl click_clip_slim.scad
// The original clip is a round ring (Ø11 bore, 6 mm tall) that sits on
// the housing's front collar, plus a 40 mm arm. The slim housing has no
// collar: its first 6 mm is the round→hex blend. So the ring is rebuilt
// as a 0.9 mm shell around that exact blend surface (+ clearance); the
// arm is kept from the original mesh and lands over a flat.
include <params.scad>
use <click_housing_slim.scad>

clip_ref   = "../ref/Pen_Clip.stl";
clip_axis  = [110.17, 142.73];   // ring centre in the original mesh
clip_ring_h = 6.0;
clip_clr   = 0.15;               // ring bore clearance to the housing
clip_wall  = 0.9;

module original_clip() translate([-clip_axis[0], -clip_axis[1], 0]) import(clip_ref, convexity = 6);

module clip() {
    union() {
        // arm + arm root: the original minus its round ring
        difference() { original_clip(); translate([0, 0, -1]) cylinder(h = clip_ring_h + 2, r = 6.15); }
        // new ring: housing envelope offset by wall, minus envelope offset by clearance
        intersection() {
            difference() { envelope(clip_clr + clip_wall); envelope(clip_clr); }
            cylinder(h = clip_ring_h, r = 20);
        }
    }
}

clip();
