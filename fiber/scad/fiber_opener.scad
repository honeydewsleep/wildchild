// =====================================================================
// Fiber metering / pre-opening wand for a pillow blower (4" suction hose)
//
// Modular stack, all joined by the same screw thread:
//
//     [funnel] -> [stage] (-> [stage] ...) -> [base: handle + hose cuff]
//      fiber in                                 to blower
//
// Every part is modelled in PRINT orientation: z=0 on the bed is the
// UPSTREAM end (fiber enters at z=0 and travels +z). All internal
// features rise toward +z at >=45 deg, so nothing needs supports and
// every finger/shelf is swept downstream (fiber slides off, no stapling).
//
//   part = "funnel" | "base" | "cuff_test"
//        | "stage_fingers" | "stage_grid" | "stage_baffle" | "stage_cyclone"
//        | "assembly"   (preview only)
//   cut  = true  -> half-section (preview only)
// =====================================================================
use <../../scad/lib/threads.scad>

part = "assembly";
cut  = false;
asm_stage = "stage_fingers";   // which stage the assembly preview shows

// ---- hose (MEASURE YOURS, print "cuff_test" first) -------------------
hose_id     = 101.6;   // 4" hose inner diameter
cuff_taper  = 1.6;     // cuff tip is this much smaller in diameter
cuff_len    = 50;
cuff_wall   = 3.2;

// ---- body ------------------------------------------------------------
R    = 65;             // bore radius (Ø130: 1.6x the hose area, so the
                       // internals can block ~35% and still not choke)
WALL = 3;
Ro   = R + WALL;

// ---- joint thread: same profile + clearance as the test-printed lamp
//      base thread (45 deg flanks, depth 1.6, pitch 5, clr 0.30) -------
thr_depth = 1.6;
thr_pitch = 5;
thr_len   = 12;
thr_clr   = 0.30;
thr_steps = 144;
Rc        = Ro + thr_clr + thr_depth + 3.1;   // socket collar outer r

$fn = 144;
EPS = 0.01;

// =====================================================================
// shared pieces
// =====================================================================
module tube(h) difference() {
    cylinder(r = Ro, h = h);
    translate([0, 0, -1]) cylinder(r = R, h = h + 2);
}

// male thread on the upstream end, z = 0..thr_len (added to a tube)
module male_end() difference() {
    intersection() {
        thread_male(Ro, thr_depth, thr_pitch, thr_len,
                    steps = thr_steps, slices_per_turn = 72);
        union() {            // lead-in taper at the tip (z=0)
            cylinder(h = 2, r1 = Ro + 0.3, r2 = Ro + thr_depth + EPS);
            translate([0, 0, 2]) cylinder(h = thr_len, r = Ro + thr_depth + EPS);
        }
    }
    translate([0, 0, -1]) cylinder(r = R, h = thr_len + 2);
}

// female socket on the downstream end; the next part's tip seats on the
// tube's end face at z = L
module socket(L) difference() {
    union() {
        translate([0, 0, L - (Rc - Ro)]) cylinder(h = Rc - Ro, r1 = Ro, r2 = Rc);
        translate([0, 0, L]) cylinder(h = thr_len, r = Rc);
    }
    translate([0, 0, L])
        thread_female_cavity(Ro, thr_depth, thr_pitch, thr_len + 1, thr_clr,
                             steps = thr_steps, slices_per_turn = 72);
    translate([0, 0, L + thr_len - 2.8])     // mouth chamfer
        cylinder(h = 2.8 + EPS, r1 = Ro + thr_clr, r2 = Ro + thr_clr + thr_depth + 1.2);
    translate([0, 0, L - 20]) cylinder(r = R, h = 21);
}

// a stage shell of length L: male below, socket above
module stage_shell(L) {
    tube(L);
    male_end();
    socket(L);
}

// keeps internals fused into the wall without poking through it
module clip(L) intersection() {
    cylinder(r = Ro - 0.6, h = L);
    children();
}

// swept radial finger: triangular blade, leading edge rises 45 deg from
// the wall to a free tip at radius rt
module fin(ang, z0, rt, root = 18, rb = 3, rtip = 2.2)
    rotate([0, 0, ang]) hull() {
        translate([R + 1.5, 0, z0 + rb]) sphere(rb, $fn = 16);
        translate([R + 1.5, 0, z0 + rb + root]) sphere(rb, $fn = 16);
        translate([rt, 0, z0 + rb + (R + 1.5 - rt)]) sphere(rtip, $fn = 16);
    }

// swept straight finger for the grid: starts on the wall at (x, side*yw),
// runs toward the centreline, free tip `gap/2` short of it
module bar(x, side, z0, gap = 10, root = 18, rb = 3, rtip = 2.2) {
    yw = sqrt(pow(R + 1.5, 2) - x * x);
    hull() {
        translate([x, side * yw, z0 + rb]) sphere(rb, $fn = 16);
        translate([x, side * yw, z0 + rb + root]) sphere(rb, $fn = 16);
        translate([x, side * gap / 2, z0 + rb + yw - gap / 2]) sphere(rtip, $fn = 16);
    }
}

// =====================================================================
// STAGE A - swept picker fingers (3 staggered rows, long/mid/short)
// =====================================================================
LA = 116;
module stage_fingers() {
    stage_shell(LA);
    clip(LA) {
        for (i = [0:3]) {
            fin(i * 90,        14, 14);        // row 1 long
            fin(i * 90 + 45,   14, 40);        // row 1 short
            fin(i * 90 + 45,   42, 14);        // row 2 long (clocked 45)
            fin(i * 90,        42, 40);        // row 2 short
        }
        for (i = [0:7]) fin(i * 45 + 22.5, 70, 28);   // row 3 mid
    }
}

// =====================================================================
// STAGE B - open grid: two layers of facing swept bars at 90 deg.
// Looks like a ~26 mm grid from the mouth, but no bar is closed at
// both ends, so nothing can drape over a crossing and stay there.
// =====================================================================
LB = 150;
grid_x = [-39, -13, 13, 39];
module stage_grid() {
    stage_shell(LB);
    clip(LB) {
        for (x = grid_x, s = [-1, 1]) bar(x, s, 12);
        rotate([0, 0, 90]) for (x = grid_x, s = [-1, 1]) bar(x, s, 80);
    }
}

// =====================================================================
// STAGE C - spiral baffle: three 45 deg shelves, 120 deg apart, each
// ending in comb teeth. Fiber must corkscrew around them.
// =====================================================================
LC = 162;
shelf_xe    = -20;     // shelf edge (covers ~31% of the bore each)
shelf_tooth = 16;
module shelf2d() {
    translate([-80, -80]) square([80 + shelf_xe, 160]);
    for (y = [-56:16:56]) hull() {
        translate([shelf_xe - 1, y - 3.5]) square([1, 7]);
        translate([shelf_xe + shelf_tooth - 3.5, y]) circle(r = 3.5, $fn = 24);
    }
}
module shelf(ang, z0) rotate([0, 0, ang])
    multmatrix([[1, 0, 0, 0], [0, 1, 0, 0], [1, 0, 1, z0 + R], [0, 0, 0, 1]])
        linear_extrude(height = 5) shelf2d();
module stage_baffle() {
    stage_shell(LC);
    clip(LC) {
        shelf(0, 12);
        shelf(120, 52);
        shelf(240, 92);
    }
}

// =====================================================================
// STAGE D - cyclone: tangential bleed slots spin the air and peel the
// clump; short wall teeth rake the fiber the swirl throws outward.
// Nothing crosses the bore, so it cannot bridge.
// =====================================================================
LD = 118;
slot_n = 8;  slot_w = 4;  slot_h = 42;  slot_ang = 60;
module stage_cyclone() {
    difference() {
        union() {
            stage_shell(LD);
            difference() {         // thick band so the slots act as nozzles
                union() {
                    translate([0, 0, 10]) cylinder(h = 6, r1 = Ro, r2 = Ro + 6);
                    translate([0, 0, 16]) cylinder(h = 46, r = Ro + 6);
                    translate([0, 0, 62]) cylinder(h = 6, r1 = Ro + 6, r2 = Ro);
                }
                translate([0, 0, 9]) cylinder(r = R, h = 60);
            }
        }
        for (i = [0:slot_n - 1]) rotate([0, 0, i * 360 / slot_n])
            translate([R, 0, 18]) rotate([0, 0, slot_ang])
                translate([-12, -slot_w / 2, 0]) cube([40, slot_w, slot_h]);
    }
    clip(LD) for (i = [0:7]) {
        fin(i * 45,        68, 46, root = 12);
        fin(i * 45 + 22.5, 88, 46, root = 12);
    }
}

// =====================================================================
// FUNNEL - bell mouth, prints mouth-down
// =====================================================================
LF = 57;  mouth_r = 95;
module funnel() {
    difference() {
        union() {
            cylinder(h = 45, r1 = mouth_r + WALL, r2 = Ro);
            cylinder(h = 6, r = mouth_r + 5);          // rolled rim
            translate([0, 0, 45]) cylinder(h = LF - 45, r = Ro);
        }
        translate([0, 0, -EPS]) cylinder(h = 45 + 2 * EPS, r1 = mouth_r, r2 = R);
        translate([0, 0, 45]) cylinder(h = LF, r = R);
    }
    socket(LF);
}

// =====================================================================
// BASE - handle + reducer + hose cuff
// =====================================================================
HS = 55;  cone_h = 30;
cuff_r0 = hose_id / 2 - 0.2;               // at the shoulder
cuff_r1 = cuff_r0 - cuff_taper / 2;        // at the tip
cuff_bore = cuff_r1 - cuff_wall;
grip_r = 16;  grip_len = 150;

module cuff(z) {
    translate([0, 0, z]) difference() {
        union() {
            cylinder(h = cuff_len, r1 = cuff_r0, r2 = cuff_r1);
            translate([0, 0, cuff_len - 12]) cylinder(h = 2, r1 = cuff_r1, r2 = cuff_r0 + 0.1);
            translate([0, 0, cuff_len - 10]) cylinder(h = 2, r1 = cuff_r0 + 0.1, r2 = cuff_r1);
        }
        translate([0, 0, -1]) cylinder(h = cuff_len + 2, r = cuff_bore);
    }
}
module grip() {
    // 45 deg pistol grip (prints support-free), blended into a wall pad
    hull() {
        translate([R + 1, -17, 12]) cube([2, 34, 40]);
        translate([R - 3, 0, 22]) rotate([0, 45, 0]) translate([0, 0, 30])
            scale([1, 0.85, 1]) cylinder(r = grip_r, h = 1, $fn = 48);
    }
    translate([R - 3, 0, 22]) rotate([0, 45, 0]) scale([1, 0.85, 1]) {
        cylinder(r = grip_r, h = grip_len, $fn = 48);
        translate([0, 0, grip_len]) sphere(grip_r, $fn = 48);
    }
}
module base() {
    difference() {
        union() {
            cylinder(h = HS, r = Ro);
            translate([0, 0, HS]) cylinder(h = cone_h, r1 = Ro, r2 = cuff_r0);
            grip();
        }
        translate([0, 0, -1]) cylinder(h = HS + 1 + EPS, r = R);
        translate([0, 0, HS]) cylinder(h = cone_h + EPS, r1 = R, r2 = cuff_bore);
    }
    male_end();
    cuff(HS + cone_h);
}
module cuff_test() { cuff(0); }

// =====================================================================
module stage(name) {
    if (name == "stage_fingers") stage_fingers();
    if (name == "stage_grid")    stage_grid();
    if (name == "stage_baffle")  stage_baffle();
    if (name == "stage_cyclone") stage_cyclone();
}
function stage_len(name) =
    name == "stage_fingers" ? LA : name == "stage_grid" ? LB :
    name == "stage_baffle" ? LC : LD;

module show() {
    if (part == "funnel") funnel();
    else if (part == "base") base();
    else if (part == "cuff_test") cuff_test();
    else if (part == "assembly") {
        color("SteelBlue") funnel();
        translate([0, 0, LF]) color("Orange") stage(asm_stage);
        translate([0, 0, LF + stage_len(asm_stage)]) color("SlateGray") base();
    }
    else stage(part);
}

if (cut) difference() {
    show();
    translate([-300, -300, -10]) cube([600, 300, 700]);
} else show();
