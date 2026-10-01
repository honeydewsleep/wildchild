// =====================================================================
// Magnetic "infinite" fidget slider - size & feel mockup of the
// DADA / LOOPLET Infinite Slider (Kickstarter campaign by firstedc).
//
// Dimensions taken from the campaign's parameter sheet (1.83 x 1.18 in
// footprint, 0.65 in assembled) and the exploded "Structural
// Innovation" render:
//   top half    = sculpted pillow shell + magnet carrier plate
//   bottom half = base shell + thin grooved "track" plate on top
//   per half    = 4 big corner magnets + 6 small magnets (2 x 3 grid)
//                 + a centre spring-loaded pin that clicks over the
//                 concentric grooves of the track plate.
// The two halves are held together only by magnetic attraction, so
// they slide/rotate without end stops ("infinite" slider).
//
// Coordinates: z = 0 is the SLIDING FACE of every part, +z away from
// the face (into the part). All dims in mm.
//
// part =
//   pillow_cap, carrier, base, track   recommended 4-part build:
//                                      magnets captured, no printer
//                                      tricks (face-down prints)
//   pillow_embedded, base_embedded     1 piece per half, magnets and
//                                      ball/spring inserted at a print
//                                      pause (closed pockets)
//   pillow_open, base_open             simplest: pockets open at the
//                                      sliding face, glue magnets in
//   preview, exploded                  assembly mockups (not for print)
// =====================================================================
part = "preview";

$fa = 3;
$fs = 0.25;
SL  = 0.01;              // slab thickness used for hull() profiles

/* ----------------------------- footprint ----------------------------- */
L = 46.5;                // length  (1.83 in)
W = 30.0;                // width   (1.18 in)
R = 6.0;                 // plan corner radius

/* ------------------------------ heights ------------------------------ */
pillow_h      = 10.15;   // sliding face -> plain dome apex (the valleys pull the
                         // real apex ~0.35 mm lower: ~9.8 mm, 16.5 assembled)
pillow_side_h = 4.2;     // vertical side height before the dome starts
pillow_n      = 2.2;     // superellipse exponent of the dome (2 = ellipse,
                         // bigger = fuller / flatter top)
face_c        = 0.6;     // chamfer on the sliding-face edge (printable
                         // face-down; a radius there would droop)
base_h        = 5.5;     // base shell (under the track plate)
track_t       = 1.2;     // grooved track plate
track_c       = 0.4;     // chamfer on the track's top edge (reads as the
                         // seam line of the original)
base_edge_r   = 2.5;     // underside edge radius (capped/open base)
base_ch       = 1.5;     // underside 45deg chamfer (embedded base: it has
                         // to print bottom-down, a radius would overhang)
total_h = pillow_h + track_t + base_h;   // 16.5 = 0.65 in

/* ------------------------------ magnets ------------------------------ */
mag_big_d   = 6;   mag_big_t   = 3;    // 4 corner magnets
mag_small_d = 4;   mag_small_t = 3;    // 6 inner magnets
mag_clr     = 0.3;                     // pocket diameter clearance
skin        = 0.5;                     // plastic between magnet and face
big_pos   = [[ 16, 8.3], [-16, 8.3], [ 16,-8.3], [-16,-8.3]];
small_pos = [[-8, 5.5], [0, 5.5], [8, 5.5], [-8,-5.5], [0,-5.5], [8,-5.5]];
carrier_t = max(mag_big_t, mag_small_t) + 0.1 + skin;   // 3.6

/* ------------------------- centre click detent ------------------------ */
detent          = true;
ball_d          = 3.0;   // steel ball
bore_d          = 3.8;   // bore for ball + spring (pen spring fits)
mouth_d         = 2.0;   // retaining mouth: ball protrudes ~0.38 mm
cone_h          = 1.0;   // mouth -> bore taper
spring_pocket_h = 4.0;   // extra spring room in the pillow above the carrier

/* ------------------------------ grooves ------------------------------ */
grooves       = true;
groove_pitch  = 2.6;     // concentric rounded rectangles
groove_w      = 1.8;     // wide enough for the 3 mm ball to dip ~0.3 mm
groove_d      = 0.5;
groove_margin = 1.0;     // first groove this far in from the edge

/* -------------------------- alignment pegs -------------------------- */
peg_pos     = [[12, 0], [-12, 0]];
peg_d       = 2.4;   peg_h = 2.0;   peg_clr = 0.3;   // carrier -> pillow cap
dowel_d     = 1.9;   dowel_depth = 2.5;              // track -> base: bits of
                                                     // 1.75 mm filament

/* ------------------------------- sculpt ------------------------------ */
// The dome is a superellipsoid of the plan outline with two smooth
// Gaussian "thumb valleys" placed point-symmetrically, which
// leaves an S-shaped ridge between them like the original's sculpt.
sculpt       = true;
valley_depth = 1.5;             // mm below the plain dome at the valley centre
valley_sigma = [10, 4.5];       // Gaussian half-widths along / across the valley
valley_pos   = [-8, 4];         // first valley centre; second is at -pos
valley_rot   = 15;              // valley axis angle from the long axis

echo(str("assembled height = ", total_h, " mm; carrier = ", carrier_t,
         " mm; embedded pillow pause at z = ", skin + max(mag_big_t, mag_small_t) + 0.2,
         " mm; embedded base pause at z = ", base_h + track_t - groove_d - skin, " mm"));

/* ============================ primitives ============================ */
module rr(l, w, r) { offset(r = r) square([l - 2*r, w - 2*r], center = true); }
module slab(z, l, w, r) { translate([0, 0, z]) linear_extrude(SL) rr(l, w, r); }

function dome_z(rho) =
    rho >= 1 ? pillow_side_h
             : pillow_side_h + (pillow_h - pillow_side_h) * pow(1 - pow(rho, pillow_n), 1 / pillow_n);

function valley(x, y, s) =
    let(dx = x - s*valley_pos[0], dy = y - s*valley_pos[1],
        u = dx*cos(valley_rot) + dy*sin(valley_rot),
        v = -dx*sin(valley_rot) + dy*cos(valley_rot))
    valley_depth * exp(-(u*u / (valley_sigma[0]*valley_sigma[0]) + v*v / (valley_sigma[1]*valley_sigma[1])));

// dome height at (x, y); rho = 0 at the centre, 1 on the plan outline
function z_top(x, y, rho) =
    let(fade = 1 - pow(min(rho, 1), 6))
    dome_z(rho) - (sculpt ? fade * (valley(x, y, 1) + valley(x, y, -1)) : 0);

// Plan outline of a rounded rectangle as a CCW point list with a fixed
// point count, so outlines of different size can be stitched ring to ring.
pp_arc = 18; pp_long = 44; pp_short = 22;
function outline_pts(l, w, r) =
    let(a = l/2 - r, b = w/2 - r)
    concat(
        [for (i = [0 : pp_short-1]) [ l/2, -b + 2*b*i/pp_short]],            // right side
        [for (i = [0 : pp_arc-1])   let(t = 90*i/pp_arc)   [ a + r*cos(t),  b + r*sin(t)]],
        [for (i = [0 : pp_long-1])  [ a - 2*a*i/pp_long,  w/2]],             // top side
        [for (i = [0 : pp_arc-1])   let(t = 90 + 90*i/pp_arc)  [-a + r*cos(t),  b + r*sin(t)]],
        [for (i = [0 : pp_short-1]) [-l/2,  b - 2*b*i/pp_short]],            // left side
        [for (i = [0 : pp_arc-1])   let(t = 180 + 90*i/pp_arc) [-a + r*cos(t), -b + r*sin(t)]],
        [for (i = [0 : pp_long-1])  [-a + 2*a*i/pp_long, -w/2]],             // bottom side
        [for (i = [0 : pp_arc-1])   let(t = 270 + 90*i/pp_arc) [ a + r*cos(t), -b + r*sin(t)]]);
pp_n = 4*pp_arc + 2*pp_long + 2*pp_short;

// Pillow as one polyhedron: dome rings are scaled copies of the outline
// (dense near the rim where the dome is steep), the rim ring lies exactly
// on the outline at z = pillow_side_h, vertical walls down to z0, and the
// sliding-face chamfer when z0 < face_c.
dome_rings = 60;
function dome_rho(i) = 1 - pow(i / dome_rings, 2);       // i = 0 rim .. dome_rings-1
module pillow_poly(z0) {
    o  = outline_pts(L, W, R);
    oc = outline_pts(L - 2*face_c, W - 2*face_c, R - face_c);
    cham = z0 < face_c;
    nr = dome_rings;                                     // ring count (excl. apex)
    pts = concat(
        [for (i = [0 : nr-1], j = [0 : pp_n-1]) let(k = dome_rho(i), x = k*o[j][0], y = k*o[j][1]) [x, y, z_top(x, y, k)]],
        [[0, 0, z_top(0, 0, 0)]],                        // apex, index nr*pp_n
        cham ? concat([for (j = [0 : pp_n-1]) [o[j][0], o[j][1], face_c]],
                      [for (j = [0 : pp_n-1]) [oc[j][0], oc[j][1], z0]])
             : [for (j = [0 : pp_n-1]) [o[j][0], o[j][1], z0]],
        [[0, 0, z0]]);                                   // bottom apex, last index
    apex = nr * pp_n;
    w0   = apex + 1;                                     // first wall ring
    nw   = cham ? 2 : 1;
    bot  = w0 + nw * pp_n;
    function rg(i, j) = i * pp_n + (j % pp_n);
    function wr(i, j) = w0 + i * pp_n + (j % pp_n);
    faces = concat(
        [for (i = [0 : nr-2], j = [0 : pp_n-1]) [rg(i, j), rg(i+1, j), rg(i+1, j+1), rg(i, j+1)]],
        [for (j = [0 : pp_n-1]) [rg(nr-1, j), apex, rg(nr-1, j+1)]],
        [for (j = [0 : pp_n-1]) [rg(0, j), rg(0, j+1), wr(0, j+1), wr(0, j)]],
        cham ? [for (j = [0 : pp_n-1]) [wr(0, j), wr(0, j+1), wr(1, j+1), wr(1, j)]] : [],
        [for (j = [0 : pp_n-1]) [bot, wr(nw-1, j), wr(nw-1, j+1)]]);
    polyhedron(points = pts, faces = faces, convexity = 10);
}

// plan-outline prism with the sliding-face edge chamfer, z = 0 .. h
module outline_prism(h) {
    hull() {
        slab(0, L - 2*face_c, W - 2*face_c, R - face_c);
        slab(face_c, L, W, R);
        slab(h - SL, L, W, R);
    }
}
// full pillow: face at z = 0, sculpted dome on top
module pillow_shape() { pillow_poly(0); }

// base outline, z = 0 (underside) .. h (sliding face / track seat)
module base_solid(h, bottom) {
    hull() {
        if (bottom == "round") {
            for (i = [0 : 6]) {
                th = 90 * i / 6;
                ins = base_edge_r * (1 - sin(th));
                slab(base_edge_r * (1 - cos(th)), L - 2*ins, W - 2*ins, R - ins);
            }
        } else {
            slab(0, L - 2*base_ch, W - 2*base_ch, R - base_ch);
            slab(base_ch, L, W, R);
        }
        slab(h - face_c, L, W, R);
        slab(h - SL, L - 2*face_c, W - 2*face_c, R - face_c);
    }
}

// magnet pockets: [zb0, zb1] for the big ones, [zs0, zs1] for the small
module pockets(zb0, zb1, zs0, zs1) {
    for (p = big_pos)   translate([p[0], p[1], zb0]) cylinder(d = mag_big_d + mag_clr,   h = zb1 - zb0);
    for (p = small_pos) translate([p[0], p[1], zs0]) cylinder(d = mag_small_d + mag_clr, h = zs1 - zs0);
}

// ball detent bore: mouth at the face (z = 0), bore up to h_top
module detent_cut(h_top) {
    translate([0, 0, -SL]) cylinder(d1 = mouth_d, d2 = bore_d, h = cone_h + SL);
    translate([0, 0, cone_h - SL]) cylinder(d = bore_d, h = h_top - cone_h + SL);
}

// concentric rounded-rectangle grooves cut into a face at z_top
module groove_rings() {
    n = floor((W/2 - groove_margin) / groove_pitch);
    for (i = [0 : n]) {
        ins = groove_margin + i * groove_pitch;
        difference() {
            offset(r = -ins) rr(L, W, R);
            offset(r = -(ins + groove_w)) rr(L, W, R);
        }
    }
}
module groove_cut(z_top) { translate([0, 0, z_top - groove_d]) linear_extrude(groove_d + 1) groove_rings(); }

/* ============================ printed parts ============================ */
// ---- recommended 4-part build --------------------------------------
// carrier plate: lower carrier_t of the pillow outline, pockets open
// towards the pillow cap (magnets captured), detent bore, pegs up.
module carrier() {
    difference() {
        union() {
            outline_prism(carrier_t);
            for (p = peg_pos) translate([p[0], p[1], carrier_t - SL]) cylinder(d = peg_d, h = peg_h + SL);
        }
        pockets(carrier_t - mag_big_t - 0.1, carrier_t + 1, carrier_t - mag_small_t - 0.1, carrier_t + 1);
        if (detent) detent_cut(carrier_t + 1);
    }
}
// pillow cap: the rest of the pillow, flat face at z = 0 for printing
module pillow_cap() {
    translate([0, 0, -carrier_t]) difference() {
        pillow_poly(carrier_t);
        for (p = peg_pos) translate([p[0], p[1], carrier_t - SL]) cylinder(d = peg_d + peg_clr, h = peg_h + 0.3);
        if (detent) translate([0, 0, carrier_t - SL]) cylinder(d = bore_d, h = spring_pocket_h + SL);
    }
}
// base shell: pockets open at the top (capped by the track plate),
// dowel holes for alignment. In-use orientation (underside at z = 0).
module base_capped() {
    difference() {
        base_solid(base_h, "round");
        pockets(base_h - mag_big_t - 0.1, base_h + 1, base_h - mag_small_t - 0.1, base_h + 1);
        for (p = peg_pos) translate([p[0], p[1], base_h - dowel_depth]) cylinder(d = dowel_d, h = dowel_depth + 1);
    }
}
// grooved track plate, z = 0 underside .. track_t grooved top
module track() {
    difference() {
        hull() {
            slab(0, L, W, R);
            slab(track_t - track_c, L, W, R);
            slab(track_t - SL, L - 2*track_c, W - 2*track_c, R - track_c);
        }
        if (grooves) groove_cut(track_t);
        for (p = peg_pos) translate([p[0], p[1], -1]) cylinder(d = dowel_d, h = track_t + 2);
    }
}

// ---- 1 piece per half, pause-and-insert ------------------------------
module pillow_embedded() {
    difference() {
        pillow_shape();
        pockets(skin, skin + mag_big_t + 0.2, skin, skin + mag_small_t + 0.2);
        if (detent) detent_cut(carrier_t + spring_pocket_h);
    }
}
module base_embedded() {          // prints bottom-down (grooves on top)
    h  = base_h + track_t;
    zt = h - groove_d - skin;     // pocket tops
    difference() {
        base_solid(h, "chamfer");
        pockets(zt - mag_big_t - 0.2, zt, zt - mag_small_t - 0.2, zt);
        if (grooves) groove_cut(h);
    }
}

// ---- simplest: pockets open at the sliding face ---------------------
module pillow_open() {
    difference() {
        pillow_shape();
        pockets(-1, mag_big_t + 0.2, -1, mag_small_t + 0.2);
    }
}
module base_open() {              // in-use orientation (underside at z = 0)
    h = base_h + track_t;
    difference() {
        base_solid(h, "round");
        pockets(h - mag_big_t - 0.2, h + 1, h - mag_small_t - 0.2, h + 1);
    }
}

/* ============================== previews ============================== */
module magnets_mockup(z0) {       // magnets drawn for the exploded view
    color("dimgray") {
        for (p = big_pos)   translate([p[0], p[1], z0]) cylinder(d = mag_big_d,   h = mag_big_t);
        for (p = small_pos) translate([p[0], p[1], z0]) cylinder(d = mag_small_d, h = mag_small_t);
    }
}
module assembly(gap = 0, slide = [0, 0]) {
    color("royalblue")  base_capped();
    color("silver")     translate([0, 0, base_h + gap]) track();
    translate([slide[0], slide[1], base_h + track_t + 2*gap]) {
        color("lightsteelblue") carrier();
        color("silver") translate([0, 0, carrier_t + gap]) pillow_cap();
    }
}

/* =============================== export =============================== */
if (part == "pillow_cap")       pillow_cap();
if (part == "carrier")          carrier();
if (part == "base")             translate([0, 0, base_h]) mirror([0, 0, 1]) base_capped();   // face down
if (part == "track")            track();
if (part == "pillow_embedded")  pillow_embedded();
if (part == "base_embedded")    base_embedded();
if (part == "pillow_open")      pillow_open();
if (part == "base_open")        translate([0, 0, base_h + track_t]) mirror([0, 0, 1]) base_open();   // face down
if (part == "preview")          assembly(0, [7, 2.5]);
if (part == "exploded") {
    assembly(8, [0, 0]);
    magnets_mockup(base_h + 8 - mag_big_t - 1);
    translate([0, 0, base_h + track_t + 16 + carrier_t + 1]) magnets_mockup(0);
}
