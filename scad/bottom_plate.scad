// =====================================================================
// Energy Ring Remix - screw-on bottom plate
//
// Modeled in print orientation, which is also assembled orientation:
// desk face at z=0, flange 0..plate_t, male thread ring rising above.
// The ESP32 rides on rails ON THE PLATE, so unscrewing the plate
// brings the board out with it for easy access.
//
// The male thread phase carries plate_clock_adjust so the seated
// (fully tightened) plate lands with its cable notch aligned to the
// base's notch. Calibrate once with the test collar, then set
// plate_clock_adjust in params.scad if needed.
//
// part = "plate_notched"  cable notch in the flange (pairs with "base")
// part = "plate_plain"    no notch (pairs with "base_wallhole")
// =====================================================================
include <params.scad>
use <lib/threads.scad>

part = "plate_notched";

boss_ir = thr_root_r - plate_boss_wall;   // 36

/* --------- male thread ring, z=0 at the datum (flange) face -------- */
module male_thread_ring(phase = plate_clock_adjust) {
    difference() {
        intersection() {
            thread_male(thr_root_r, thr_depth, thr_pitch, thr_len,
                        starts = 1, phase = phase,
                        steps = thr_steps, slices_per_turn = thr_slices_per_turn,
                        crest_deg = thr_crest_deg);
            thread_tip_taper(thr_root_r, thr_depth, thr_len);
        }
        translate([0, 0, -EPS])
            cylinder(h = thr_len + 2*EPS, r = boss_ir, $fn = FN_ROUND);
    }
}

/* ----------------- flange disc with grip scallops ------------------ */
module flange_disc() {
    difference() {
        cylinder(h = plate_t, d = base_od, $fn = FN_ROUND);
        // grip scallops around the rim
        for (i = [0:grip_n - 1])
            rotate([0, 0, i*360/grip_n])
                translate([base_od/2, 0, -EPS])
                    cylinder(h = plate_t + 2*EPS, d = grip_d, $fn = 24);
        // recesses for adhesive rubber feet (skip the notch angle)
        for (a = [45, 135, 225, 315])
            rotate([0, 0, a])
                translate([foot_r_pos, 0, -EPS])
                    cylinder(h = foot_depth + EPS, d = foot_d, $fn = 48);
    }
}

/* --- cutter for the cable notch through flange + thread ring ------- */
// wider than the base notch so the two align with slack to spare
module plate_notch_cut() {
    rotate([0, 0, notch_angle - 270])
        translate([-plate_notch_w/2, -base_od/2 - 4, -1])
            cube([plate_notch_w, (base_od/2 + 4) - 31, plate_t + thr_len + 2]);
}

/* ------------- ESP32 rails, z=0 at the mounting face --------------- */
// Board slides down between the C-rails; USB end faces the notch (-Y).
module esp_rails() {
    rail_len = esp_l - 5;
    inner_x  = (esp_w + esp_clr)/2;
    for (sx = [-1, 1]) scale([sx, 1, 1]) {
        // rail body
        translate([inner_x, -rail_len/2, 0])
            cube([rail_t, rail_len, rail_h]);
        // ledge the board rests on (pin tails hang in the gap below)
        translate([inner_x - 1.2, -rail_len/2, 0])
            cube([1.2, rail_len, rail_ledge_z]);
        // short retaining lip segments above the board edge (board
        // tilts in under one pair, then snaps under the other)
        for (sy = [-1, 1])
            translate([inner_x - 0.8, sy*rail_len/2 - (sy > 0 ? 8 : 0), rail_ledge_z + 1.9])
                cube([0.8, 8, rail_h - rail_ledge_z - 1.9]);
    }
    // end stop away from the USB end
    translate([-10, esp_l/2 - 1, 0])
        cube([20, 2.5, rail_h - 1]);
}

module zip_slots_cut(face_t) {
    for (sx = [-1, 1])
        translate([sx*(esp_w/2 + rail_t + 2.2) - zip_slot[0]/2, -zip_slot[1]/2, -EPS])
            cube([zip_slot[0], zip_slot[1], face_t + 2*EPS]);
}

/* ------------------------- whole plate ----------------------------- */
module bottom_plate(notched = true) {
    difference() {
        union() {
            flange_disc();
            translate([0, 0, plate_t]) male_thread_ring();
            translate([0, 0, plate_t]) esp_rails();
        }
        zip_slots_cut(plate_t);
        if (notched) plate_notch_cut();
    }
}

/* ------------------------- part selection -------------------------- */
if (part == "plate_notched")
    bottom_plate(true);
else if (part == "plate_plain")
    bottom_plate(false);
