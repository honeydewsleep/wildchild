// vent_deflector.scad — 12" magnetic wall-vent deflector, magnets 8.5" apart.
//
// Remix of "6-20 Expandable Vent Cover / Vent Deflector" (MakerWorld 2722921,
// 6-12" profile). The original is two telescoping 6" halves; this version is
// two fixed-length halves joined with a half-lap at the middle so the scoop
// spans 12" while the magnets sit 8.5" apart (1.75" in from each end).
//
// Cross-section (both parts): quarter-cylinder scoop, outer R 100, wall 2 mm,
// arc centre at the origin. Wall-contact face is the plane x = 0 (part lies
// in x <= 0), the open air-exit face is y = 0, the "hood" (where the arc meets
// the wall at a right angle) is at y = 100. Each half prints standing on its
// end cap (cap on the bed, +z up), exactly like the original.
//
// Magnet pockets: two per boss, dia 6.7 x 1.9 deep, open toward the wall face,
// on 9.7 mm centres — copied from the original (fits 6 x 2 mm disc magnets,
// glue in). The bosses hang under the hood, the same location the original
// designer used for the inner half's magnets, so they print cap-down without
// support (45 deg chamfer on the underside).
//
// Parts:
//   part = "half_A"    cap end + outer lap  (prints cap-down)
//   part = "half_B"    cap end + inner lap  (prints cap-down)
//   part = "assembly"  both halves joined, for preview / measuring
//   part = "fit_check" intersection of the two halves — must render EMPTY

part = "half_A";

// ---- dimensions ----------------------------------------------------------
total_len      = 12 * 25.4;    // 304.8 — overall scoop length (2 halves joined)
magnet_spacing = 8.5 * 25.4;   // 215.9 — centre-to-centre between the two bosses
R      = 100;                  // outer radius = projection off the wall = height
wall   = 2;
cap_t  = 2;                    // end-cap thickness (original: 1-2 mm)

// half-lap joint at the middle
lap_len = 15;                  // overlap length
lap_clr = 0.15;                // radial clearance per side (0.30 total)

// hood magnet boss (block under the hood at the wall face)
boss_d       = 9;              // depth away from the wall face (x)
boss_w       = 14;             // height down from the hood (y)
boss_h       = 18;             // length along z
boss_chamfer = 15;             // 45 deg chamfer under the boss (print support)
pocket_d     = 6.7;            // magnet pocket dia (6 mm magnet + 0.35/side)
pocket_depth = 1.9;            // 2 mm magnet sits ~0.1 proud for good contact
pocket_pitch = 9.7;            // centre spacing of the two pockets in a boss

// optional extra magnets on the end caps, mid-face, like the original's cap
// bosses (also prints cap-down). Off by default: the user asked for 8.5" only.
cap_magnets = false;
cap_boss_d  = 4;               // pocket block depth (x) before the fillet
cap_boss_w  = 20;              // width along the face (y), centred
cap_boss_h  = 10.5;            // from the cap's outer face
cap_boss_fillet = 8.5;

// ---- derived --------------------------------------------------------------
half_len = (total_len + lap_len) / 2;         // each half incl. its lap zone
boss_z   = (total_len - magnet_spacing) / 2;  // boss centre, from the cap face
R_in     = R - wall;
R_mid    = R - wall / 2;
EPS      = 0.01;
$fa = 1; $fs = 0.3;

// ---- primitives -----------------------------------------------------------
// quarter ring (angle 0..90 in the x<=0, y>=0 quadrant) between radii, z0..z1
module qring(r_in, r_out, z0, z1) {
    mirror([1, 0, 0]) rotate_extrude(angle = 90)
        translate([r_in, z0]) square([r_out - r_in, z1 - z0]);
}
module qdisc(r, z0, z1) {
    mirror([1, 0, 0]) rotate_extrude(angle = 90)
        translate([0, z0]) square([r, z1 - z0]);
}

module hood_boss() {
    hull() {
        translate([-boss_d, R - 1 - boss_w, boss_z - boss_h / 2])
            cube([boss_d, boss_w, boss_h]);
        // sliver on the hood wall, below: gives the 45 deg underside chamfer
        translate([-boss_d, R - 1 - 0.1, boss_z - boss_h / 2 - boss_chamfer])
            cube([boss_d, 0.1, 0.1]);
    }
}
module hood_pockets() {
    for (s = [-1, 1])
        translate([-pocket_depth, R - 1 - boss_w / 2, boss_z + s * pocket_pitch / 2])
            rotate([0, 90, 0]) cylinder(d = pocket_d, h = pocket_depth + EPS);
}

// cap boss: block on the cap at mid-face with a quarter-round fillet toward
// the inside, profile in the x-z plane extruded along y
module cap_boss() {
    translate([0, R / 2 - cap_boss_w / 2, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
        linear_extrude(cap_boss_w) polygon(concat(
            [[0, 0], [0, cap_boss_h], [-cap_boss_d, cap_boss_h]],
            [for (a = [0 : 5 : 90])
                [-cap_boss_d - cap_boss_fillet + cap_boss_fillet * cos(a),
                 cap_t + cap_boss_fillet - cap_boss_fillet * sin(a)]],
            [[-cap_boss_d - cap_boss_fillet, 0]]));
}
module cap_pockets() {
    for (s = [-1, 1])
        translate([-pocket_depth, R / 2 + s * pocket_pitch / 2, cap_boss_h - 5])
            rotate([0, 90, 0]) cylinder(d = pocket_d, h = pocket_depth + EPS);
}

// ---- halves ---------------------------------------------------------------
module half(kind) {
    difference() {
        union() {
            qdisc(R, 0, cap_t);                              // end cap
            qring(R_in, R, cap_t - EPS, half_len - lap_len); // full wall
            if (kind == "A")                                 // outer lap
                qring(R_mid + lap_clr, R, half_len - lap_len - EPS, half_len);
            else                                             // inner lap
                qring(R_in, R_mid - lap_clr, half_len - lap_len - EPS, half_len);
            hood_boss();
            if (cap_magnets) cap_boss();
        }
        hood_pockets();
        if (cap_magnets) cap_pockets();
    }
}

module assembly() {
    half("A");
    translate([0, 0, total_len]) mirror([0, 0, 1]) half("B");
}

if (part == "half_A") half("A");
else if (part == "half_B") half("B");
else if (part == "assembly") assembly();
else if (part == "fit_check")
    intersection() {
        half("A");
        translate([0, 0, total_len]) mirror([0, 0, 1]) half("B");
    }
