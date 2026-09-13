// v2 fit checks. Standalone thread replicas (fast).
//   -D 'mode="j_clearance"'  -> EMPTY      (male thread inside the female cavity)
//   -D 'mode="j_engagement"' -> NON-empty  (male thread overlaps the barrel's thread ring solid)
//   -D 'mode="plunger_pass"' -> EMPTY      (plunger passes the female thread zone)
include <params.scad>
use <../../scad/lib/threads.scad>
use <plunger.scad>

mode = "j_clearance";

module male()   intersection() { thread_male(j_root_r, j_depth, j_pitch, j_len, 1, 0, 240, 120, j_crest_deg);
                                 thread_tip_taper(j_root_r, j_depth, j_len, 1.2); }
module ring()   difference() { cylinder(h = j_len, r = g_knurl_r); translate([0, 0, -1]) cylinder(h = j_len + 2, r = j_root_r - 0.5); }
module female() difference() { ring(); thread_female_cavity(j_root_r, j_depth, j_pitch, j_len + 1, j_clr, 1, 0, 240, 120, j_crest_deg); }

if (mode == "j_clearance")  intersection() { translate([0, 0, 0.02]) male(); female(); }
if (mode == "j_engagement") intersection() { male(); ring(); }
if (mode == "plunger_pass") intersection() { female(); translate([0, 0, -2]) plunger(); }
