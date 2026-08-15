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
                        //        | "collide" | "shut" | "engage" | "latch"

// How it stays shut.  "magnet" is the original: 4 x Ø6x3 discs in the rim.
// "snap" needs no hardware at all — an interlocking rim with a snap bead —
// and is dimensionally identical from the outside.
closure = "magnet";     // "magnet" | "snap"

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
magnets    = (closure == "magnet");
snaprim    = (closure == "snap");

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

/* [Snap rim] — closure = "snap" only ------------------------------------
   A short cantilever standing on the rim cannot work here: with only ~3 mm
   of depth to play with, deflecting a 1.1 mm tab far enough to hold (0.3 mm)
   needs 5-13 % bending strain and PLA lets go at 2-3 %.  So the flexing
   member is a long run of the case WALL instead — the rim interlocks, and a
   bead on the tongue makes the outer wall bow out by bead_d over a 17-32 mm
   span.  That is 0.1-1.0 % strain, which the material does not mind.

   The rims step into each other rather than butting: the inner part of one
   rim stands proud by lip_h and drops into a matching recess in the other.
   Outside dimensions are untouched. */
lip_h      =  1.60;     // tongue height above the parting plane
lip_x      =  1.90;     // outer wall left in front of the tongue.  Sized off
                        // the divot: it cuts 0.99 deep, so this leaves 0.91.
lip_t      =  1.00;     // tongue thickness (it overhangs the cavity by 0.45)
lip_clr    =  0.15;     // clearance, tongue <-> recess
lip_tip    =  0.35;     // lead-in chamfer on the tongue tip
bead_d     =  0.45;     // how far the bead stands proud.  Net engagement is
                        // bead_d - lip_clr = 0.30; the wall bows that far.
bead_h     =  0.90;     // bead height
bead_z     =  0.80;     // bead centre, above the parting plane
lip_hinge_keepout = 7.0;   // tongue stops short of the hinge

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
assert(closure == "magnet" || closure == "snap", "closure must be \"magnet\" or \"snap\"");
assert(lip_x - scoop_deep > 0.6, "snap rim leaves too little wall under the divot");
assert(lip_h + lip_clr < half_h - floor_t, "snap rim recess would cut into the floor");
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

// === snap rim ===============================================================
// The rim ring the tongue lives in.  da moves the OUTER face out, db moves the
// INNER face in, so lip_ring(-c,-c) is the tongue grown by c all round.
module lip_ring(da = 0, db = 0)
    difference() {
        offset(r = -(lip_x + da)) plan();
        offset(r = -(lip_x + lip_t - db)) plan();
    }

// Where the tongue is allowed: the three free sides, stopping short of the
// hinge.  It runs unbroken past the divot — that is why lip_x is 1.90.
module lip_zone(g = 0)
    offset(r = g)
    translate([-20, -20]) square([case_wid - lip_hinge_keepout + 20, case_len + 40]);

// Where the bead is allowed: only the straight runs, which are the parts of
// the wall that can bow.  A bead in a corner has nothing to give.
module bead_zone(g = 0)
    offset(r = g)
    intersection() {
        lip_zone();
        union() {
            // the two short ends, mid-width
            for (y = [-20, case_len - 4])
                translate([corner_r + 1, y]) square([case_wid - 2*corner_r - 2, 24]);
            // the free edge, clear of both the corners and the divot
            for (y = [corner_r + 1, case_len - corner_r - 8])
                translate([-20, y]) square([24, 7]);
        }
    }

// A tapered run of the rim ring, built as a short stack of slices.
// NOT hull() — these slices are rings, and the convex hull of a ring fills its
// middle in and bridges straight across the keepout gaps.
module lip_stack(z0, z1, da0, da1, db0, db1, bead = false, g = 0, n = 6)
    for (i = [0 : n-1]) {
        tm = (i + 0.5) / n;
        translate([0, 0, z0 + (z1 - z0)*i/n])
            linear_extrude((z1 - z0)/n + 0.002)
                intersection() {
                    lip_ring(da0 + (da1 - da0)*tm, db0 + (db1 - db0)*tm);
                    if (bead) bead_zone(g); else lip_zone(g);
                }
    }

// the tongue: a plain rib with a trapezoidal bead partway up and a chamfered tip
module lip_tongue() {
    b0 = half_h + bead_z - bead_h/2;
    bm = half_h + bead_z;
    b1 = half_h + bead_z + bead_h/2;
    translate([0,0,half_h]) linear_extrude(lip_h - lip_tip)
        intersection() { lip_ring(); lip_zone(); }
    lip_stack(half_h + lip_h - lip_tip, half_h + lip_h,        // chamfered tip
              0, lip_tip, 0, lip_tip);
    lip_stack(b0, bm, 0, -bead_d, 0, 0, true);                 // bead, ramped
    lip_stack(bm, b1, -bead_d, 0, 0, 0, true);                 // both ways
}

// the recess: a plain slot the tongue drops into, plus a groove for the bead.
// The slot mouth is deliberately narrower than the bead — squeezing through it
// is the snap.
module lip_recess(groove = true) {
    g  = lip_clr;
    b0 = half_h - bead_z - bead_h/2 - lip_clr;
    bm = half_h - bead_z;
    b1 = half_h - bead_z + bead_h/2 + lip_clr;
    translate([0,0,half_h - lip_h - lip_clr]) linear_extrude(lip_h + lip_clr + 1)
        intersection() { lip_ring(-lip_clr, -lip_clr); lip_zone(g); }
    if (groove) {
        lip_stack(b0, bm, -lip_clr, -(bead_d + lip_clr), -lip_clr, -lip_clr, true, g);
        lip_stack(bm, b1, -(bead_d + lip_clr), -lip_clr, -lip_clr, -lip_clr, true, g);
    }
}

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
module tray(kind, groove = true) {
    union() {
        difference() {
            union() {
                difference() {
                    outer_solid();
                    difference() {                  // cavity, less the magnet bosses
                        cavity();
                        if (magnets)
                            for (y = mag_y)
                                translate([mag_x, y, 0])
                                    cylinder(r = mag_boss_r, h = half_h + 1, $fn = 64);
                    }
                }
                if (kind == "pin")    hinge_knuckles();
                if (kind == "barrel") hinge_barrel_side();
                if (snaprim && kind == "barrel") lip_tongue();
            }
            if (magnets) magnet_bores();
            if (snaprim && kind == "pin") lip_recess(groove);
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

// fit check: with closure="snap" this must be NON-EMPTY, and it is the only
// check that proves the bead has anything to snap over.  It intersects the
// closed case against a recess built WITHOUT its bead groove, so what is left
// is exactly the material the bead has to ride over on the way in.  If the
// bead were missing, or too shallow, or landed at the wrong depth, every other
// check would still pass and this one would come up empty.
if (part == "snapfit")
    intersection() {
        translate([2*hinge_ax, 0, 0]) mirror([1,0,0]) tray("pin", false);
        fold_shut() tray("barrel");
    }

// the snap rim on its own, for eyeballing where tongue and bead actually land
if (part == "latch")
    intersection() {
        case_flat();
        translate([-10, -10, half_h - lip_h - 1]) cube([2*hinge_ax + 20, case_len + 20, lip_h + 3]);
    }

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
