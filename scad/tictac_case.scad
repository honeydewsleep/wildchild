// ---------------------------------------------------------------------------
// Pocket clamshell case — hollow "tic tac" version
//
// Reworked from the 6 mm-magnet clamshell (case_6mm.stl).  Kept: the print-in-
// place pin hinge, the Ø6.3 magnet pockets, and the rolled-edge exterior.
// Changed: interior is now a plain open box, length 60 -> 50 mm, closed height
// 15.2 -> 11.0 mm.
//
// Printed FLAT (open, both cavities up) exactly like the original — no
// supports, hinge prints in place.
//
//   ./render.sh stl     -> stl/tictac_case.stl
// ---------------------------------------------------------------------------

part = "case";          // "case" | "left" | "right" | "section" | "closed"
                        //        | "collide" | "shut" | "engage"

/* [Shell] ---------------------------------------------------------------- */
case_len   = 50.0;      // Y — was 60
case_wid   = 35.0;      // X, per half — unchanged
half_h     =  5.5;      // per half -> 11.0 mm closed (was 7.6 -> 15.2)
corner_r   =  9.0;      // plan corner radius — unchanged
wall       =  2.45;     // side wall — unchanged
floor_t    =  1.40;     // floor — unchanged
rim_cham   =  0.40;     // chamfer on the inner rim edge — unchanged
base_cham  =  0.80;     // fillet where the wall meets the floor

// Rolled outer edge.  The original is a circular arc r=7.107 that turns
// vertical 2.18 mm below the rim; both are scaled by the height change
// (5.5/7.6) so the silhouette stays proportionally identical.
edge_r     =  5.14;     // arc radius            (orig 7.107)
edge_tan   =  3.92;     // Z where it goes vertical (orig 5.42)

/* [Magnets] — sizes unchanged from the original ------------------------- */
mag_dia    =  6.30;     // pocket Ø  (6 mm magnet + 0.3 clearance)
mag_depth  =  3.20;     // pocket depth — a 3 mm magnet sits 0.2 mm below the rim
mag_x      =  4.70;     // centre, in from the outer face — as original
mag_boss_r =  4.45;     // boss around the pocket
mag_y      = [case_len*0.25, case_len*0.75];   // two pairs

/* [Hinge] — every dimension measured off case_6mm.stl ------------------- */
half_gap   =  0.50;     // between the halves when laid flat
pin_r      =  1.15;     // Ø2.30 pin                        (orig 1.150)
barrel_r   =  2.15;     // Ø4.30 barrel / knuckles          (orig 2.149)
pin_clr    =  0.20;     // pin <-> barrel bore              (orig bore r 1.350)
body_clr   =  0.25;     // barrel <-> the facing shell      (orig relief r 2.399)
ring_len   = 19.40;     // length of the barrel ring        (orig 20.30..39.70)
knuckle_l  =  1.10;     // full-radius knuckle at each end
cap_l      =  2.50;     // domed tip beyond it — an ELLIPSOID, not a hemisphere:
                        // the original runs out over 2.50 mm, not barrel_r
hinge_ygap =  0.35;     // axial gap ring <-> knuckle       (orig 0.35 / 0.30)
// overall = ring_len + 2*(hinge_ygap + knuckle_l + cap_l) = 27.30, as measured

/* [Thumb scoop] — the divot you get a nail into -------------------------
   Cut by a capsule lying along the rim line, exactly as on case_6mm.stl:
   a rod of radius scoop_r with its axis ON the parting plane, sunk so it
   bites scoop_deep into the flank.  That gives a flat-bottomed groove with
   rounded run-outs, not a dish — which is what it feels like under a thumb.
   Fitted to the original: RMS 0.04 mm over its full depth. */
scoop      = true;
scoop_r    =  2.766;    // capsule radius
scoop_flat = 10.098;    // length of the flat-bottomed part (the axis segment)
scoop_deep =  0.989;    // depth at the rim
// => 14.34 mm long at the rim, running out 2.12 mm below it

$fa = 2; $fs = 0.4;

assert(corner_r <= case_wid/2 && corner_r <= case_len/2, "corner_r too large for the plan");
assert(mag_x - mag_dia/2 > 0.8, "magnet pocket breaks out through the outer wall");
assert(mag_depth < half_h - floor_t, "magnet pocket is deeper than the wall is tall");
assert(hinge_len + 2 <= case_len, "hinge is longer than the case");
assert(scoop_deep < scoop_r, "scoop depth must be less than the capsule radius");

// === geometry ===============================================================

hinge_ax = case_wid + half_gap/2;               // X of the pivot axis
hz  = half_h;                                   // hinge axis height (parting plane)
ymid = case_len/2;
by0 = ymid - ring_len/2;                        // barrel ring span
by1 = ymid + ring_len/2;
hy0 = by0 - hinge_ygap;                         // knuckle cylinders, outboard of the ring
hy1 = by1 + hinge_ygap;
hinge_len = ring_len + 2*(hinge_ygap + knuckle_l + cap_l);   // 27.30 overall

function roll_inset(z) = (z >= edge_tan) ? 0
    : edge_r - sqrt(max(0, edge_r*edge_r - (edge_tan - z)*(edge_tan - z)));

module plan()
    hull() for (x = [corner_r, case_wid - corner_r],
                y = [corner_r, case_len - corner_r])
        translate([x, y]) circle(r = corner_r, $fn = 96);

// outer solid: flat bottom, arc-rolled flank, straight band up to the rim
module outer_solid() {
    n = 18;
    for (i = [0 : n-1]) {
        z0 = edge_tan * i / n;
        z1 = edge_tan * (i+1) / n;
        hull() {
            translate([0,0,z0]) linear_extrude(0.01) offset(r = -roll_inset(z0)) plan();
            translate([0,0,z1]) linear_extrude(0.01) offset(r = -roll_inset(z1)) plan();
        }
    }
    translate([0,0,edge_tan]) linear_extrude(half_h - edge_tan) plan();
}

// the open box: filleted at the floor, chamfered at the rim
module cavity() {
    zb = floor_t + base_cham;
    zt = half_h  - rim_cham;
    hull() {
        translate([0,0,floor_t]) linear_extrude(0.01) offset(r = -(wall + base_cham)) plan();
        translate([0,0,zb])      linear_extrude(0.01) offset(r = -wall) plan();
    }
    translate([0,0,zb]) linear_extrude(zt - zb + 0.01) offset(r = -wall) plan();
    hull() {
        translate([0,0,zt])      linear_extrude(0.01) offset(r = -wall) plan();
        translate([0,0,half_h])  linear_extrude(0.01) offset(r = -(wall - rim_cham)) plan();
    }
    translate([0,0,half_h]) linear_extrude(barrel_r + 2) offset(r = -(wall - rim_cham)) plan();
}

module axis_cyl(r, ya, yb)
    translate([hinge_ax, ya, hz]) rotate([-90,0,0]) cylinder(r = r, h = yb - ya, $fn = 72);
module axis_ball(r, y)
    translate([hinge_ax, y, hz]) sphere(r = r, $fn = 72);

// A domed tip.  The original's is NOT a hemisphere — it runs out over 1.25 mm,
// not 2.15, which is what kept its hinge 27.3 mm long overall instead of 31.3.
module axis_cap(r, ylen, y, dir)
    translate([hinge_ax, y, hz]) scale([1, ylen/r, 1]) sphere(r = r, $fn = 72);

// pin half of the hinge: two knuckles, each a short cylinder with a domed tip
module hinge_knuckles(rc = 0, yc = 0) {
    r = barrel_r + rc;
    cl = cap_l + yc;
    axis_cyl(r, hy0 - knuckle_l, hy0 + yc);  axis_cap(r, cl, hy0 - knuckle_l, -1);
    axis_cyl(r, hy1 - yc, hy1 + knuckle_l);  axis_cap(r, cl, hy1 + knuckle_l, +1);
}
// ... joined by the pin, which runs the whole span and is what the barrel
// rides on.  Inflated by rc it also cuts the barrel's bore.
// Spans knuckle to knuckle, not out to the cap tips: at the tip the clearance
// envelope has tapered to about the pin radius, so a full-length rod would
// touch it and fuse the halves.  The caps are solid, so the pin is continuous
// with them regardless.
module hinge_pin_rod(rc = 0)
    axis_cyl(pin_r + rc, hy0 - knuckle_l, hy1 + knuckle_l);

module hinge_pin_side(rc = 0, yc = 0) {
    hinge_knuckles(rc, yc);
    hinge_pin_rod(rc);
}

// what the barrel half must clear: the knuckles at body_clr, the pin at pin_clr
module hinge_pin_clearance() {
    hinge_knuckles(body_clr, hinge_ygap);
    hinge_pin_rod(pin_clr);
}

// barrel half of the hinge (a plain closed ring rides the pin)
module hinge_barrel_side(rc = 0, yc = 0)
    axis_cyl(barrel_r + rc, by0 - yc, by1 + yc);

module magnet_bores()
    for (y = mag_y)
        translate([mag_x, y, half_h - mag_depth])
            cylinder(d = mag_dia, h = mag_depth + 1, $fn = 64);

module thumb_scoop()
    if (scoop)
        hull()
            for (s = [-1, 1])
                translate([scoop_deep - scoop_r,
                           case_len/2 + s*scoop_flat/2,
                           half_h])
                    sphere(r = scoop_r, $fn = 96);

// one tray.  kind = "pin" (knuckles + pin) or "barrel" (ring)
//
// The pin is unioned on AFTER the clearance cuts.  The barrel-clearance cut
// that notches this shell clear of the mating ring is a solid cylinder on the
// axis, so cutting with it first would shear the pin off inside the barrel —
// leaving a case that passes both "must be EMPTY" checks and still falls apart.
module tray(kind) {
    union() {
        difference() {
            union() {
                difference() {
                    outer_solid();
                    difference() {                  // cavity, less the magnet bosses
                        cavity();
                        for (y = mag_y)
                            translate([mag_x, y, 0])
                                cylinder(r = mag_boss_r, h = half_h + 1, $fn = 64);
                    }
                }
                if (kind == "pin")    hinge_knuckles();
                if (kind == "barrel") hinge_barrel_side();
            }
            magnet_bores();
            thumb_scoop();
            // clearance for the mating half's hinge
            if (kind == "barrel") hinge_pin_clearance();
            if (kind == "pin")    hinge_barrel_side(body_clr, body_clr);
        }
        if (kind == "pin") hinge_pin_rod();
    }
}

// the left tray folded 180 deg about the pivot, i.e. the case shut
module fold_shut()
    translate([hinge_ax,0,hz]) rotate([0,180,0]) translate([-hinge_ax,0,-hz]) children();

module case_closed() {
    translate([2*hinge_ax, 0, 0]) mirror([1,0,0]) tray("pin");
    fold_shut() tray("barrel");
}

module case_flat() {
    tray("barrel");                                         // left  half
    translate([2*hinge_ax, 0, 0]) mirror([1,0,0]) tray("pin");   // right half
}

if (part == "case")    case_flat();
if (part == "left")    tray("barrel");
if (part == "right")   tray("pin");
if (part == "section")
    difference() {
        case_flat();
        translate([-10, -1, -1]) cube([2*hinge_ax + 20, case_len/2 + 1, half_h + 10]);
    }

// fit check: must render EMPTY — the two halves may not touch anywhere, or the
// print-in-place hinge fuses solid on the bed.
if (part == "collide")
    intersection() {
        tray("barrel");
        translate([2*hinge_ax, 0, 0]) mirror([1,0,0]) tray("pin");
    }

if (part == "closed") case_closed();

// fit check: must render NON-EMPTY — the pin has to actually run through the
// barrel, or the halves are two loose trays.  The EMPTY checks above cannot
// catch a missing pin: deleting it makes them pass more easily.
if (part == "engage")
    intersection() {
        translate([2*hinge_ax, 0, 0]) mirror([1,0,0]) tray("pin");
        axis_cyl(barrel_r, by0, by1);
    }

// fit check: must render EMPTY.  The halves are expected to meet exactly on the
// parting plane (that is the seal), so that plane is excluded; anything left
// over is real interference.
if (part == "shut")
    difference() {
        intersection() {
            translate([2*hinge_ax, 0, 0]) mirror([1,0,0]) tray("pin");
            fold_shut() tray("barrel");
        }
        translate([-10, -10, hz - 0.05]) cube([2*hinge_ax + 20, case_len + 20, 0.10]);
    }
