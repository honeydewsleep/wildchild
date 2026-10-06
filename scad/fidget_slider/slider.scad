// =====================================================================
// Magnetic "infinite" fidget slider - size & feel mockup of the
// DADA / LOOPLET Infinite Slider (Kickstarter campaign by firstedc).
//
// Dimensions taken from the campaign's parameter sheet (1.83 x 1.18 in
// footprint, 0.65 in assembled) and the exploded "Structural
// Innovation" render:
//   top half    = sculpted pillow shell + magnet carrier plate
//   bottom half = sculpted base shell + thin grooved "track" plate on top
//   per half    = 4 big corner magnets + 6 small magnets (2 x 3 grid)
//                 + a centre spring-loaded pin that clicks over the
//                 concentric grooves of the track plate.
// Both halves carry the sculpted "topographic" dome, and both sliding
// faces carry the concentric ridge pattern (carrier_grooves switches the
// top half's off if the ridge-in-groove ratcheting feels too rough).
// The two halves are held together only by magnetic attraction, so
// they slide/rotate without end stops ("infinite" slider).
//
// Coordinates: z = 0 is the SLIDING FACE of every part, +z away from
// the face (into the part). All dims in mm.
//
// part =
//   pillow_cap, carrier, base, track   recommended 4-part build:
//                                      magnets captured, no printer
//                                      tricks (face-down prints).
//                                      snap=true turns the glued joints
//                                      into snap latches (see below)
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
base_h        = 5.7;     // base shell: pocket face -> dome apex (nominal,
                         // the valleys pull the real apex to ~5.5)
base_dome_h   = 3.3;     // dome height of the base shell above its side
track_t       = 1.2;     // grooved track plate
track_c       = 0.4;     // chamfer on the track's top edge (reads as the
                         // seam line of the original)
total_h = pillow_h + track_t + base_h;   // ~16.5 = 0.65 in

/* ------------------------------ grooves ------------------------------ */
grooves       = true;
groove_pitch  = 2.6;     // concentric rounded rectangles
groove_w      = 1.8;     // wide enough for the 3 mm ball to dip ~0.3 mm
groove_d      = 0.5;
groove_margin = 1.0;     // first groove this far in from the edge
groove_spokes = true;    // ridge-level bars along the diagonals (like the
                         // original's corner lines); they also tie the ring
                         // ridges together when a track prints ridges-down

/* ------------------------------ magnets ------------------------------ */
mag_big_d   = 6;   mag_big_t   = 3;    // 4 corner magnets
mag_small_d = 4;   mag_small_t = 3;    // 6 inner magnets
mag_clr     = 0.3;                     // pocket diameter clearance
skin        = 0.5;                     // plastic between magnet and face
big_pos   = [[ 16, 8.3], [-16, 8.3], [ 16,-8.3], [-16,-8.3]];
small_pos = [[-8, 5.5], [0, 5.5], [8, 5.5], [-8,-5.5], [0,-5.5], [8,-5.5]];
carrier_grooves = true;                // ridge pattern on the top half's face too
carrier_groove_angle = 45;             // 0 = same concentric rings as the track (the
                                       // ridges then nest into the track grooves and
                                       // ratchet); 45 = straight stripes crossing the
                                       // track's rings, so the faces always ride ridge
                                       // on ridge and the ball keeps a constant reach
island_d = 6;                          // flat disc around the ball mouth, ridge level
mag_floor = (carrier_grooves ? groove_d : 0) + skin;   // pocket floor above the face
carrier_t = mag_floor + max(mag_big_t, mag_small_t) + 0.1;   // 4.1

/* ------------------------- centre click detent ------------------------ */
detent          = true;
ball_d          = 3.0;   // steel ball
bore_d          = 3.8;   // bore for ball + spring (pen spring fits)
mouth_d         = 2.0;   // retaining mouth: ball protrudes ~0.38 mm
cone_h          = 1.0;   // mouth -> bore taper
spring_pocket_h = 3.9;   // extra spring room in the pillow above the carrier
                         // (carrier_t + this = bore ceiling, keep it on the
                         // 0.2 mm layer grid: 8.0)

/* -------------------------- alignment dowels ------------------------- */
// Ø1.9 holes in both parts of each glued pair (cap/carrier, base/track),
// bridged by 5 mm stubs of 1.75 mm filament. Holes print in any
// orientation, pegs would not.
peg_pos     = [[12, 0], [-12, 0]];
dowel_d     = 1.9;   dowel_depth = 2.5;

/* ----------------------------- snap latches ------------------------------ */
// snap = true replaces glue + dowels: four barbed posts stand on the back of
// the carrier and of the track plate; the cap and the base carry two flex
// beams (bridged across a cavity, free on both long sides, anchored at
// both ends) that the barbs push up and then hook under. Caps still print
// face-down; carrier and track then print with their ridged face on the
// bed so the posts can grow upwards.
snap          = false;
snap_beam_y   = 9.7;     // beam centre line |y|, the beam runs along x
snap_beam_len = 14;      // free span between the anchors
snap_beam_w   = 2.0;
snap_beam_t   = 0.6;     // 3 layers, bends up into the void
snap_gap      = 0.4;     // side gaps that free the beam
snap_hole_h   = 1.1;     // open cavity under the beam
snap_void_h   = 0.5;     // room above the beam = barb engagement
snap_post_x   = 4.0;     // posts at (+-snap_post_x, +-snap_post_y)
snap_post_w   = 2.2;     // square post footprint
snap_clr      = 0.2;     // post-to-channel clearance
snap_barb     = 0.5;     // barb reach over the beam's edge
snap_post_y   = snap_beam_y - snap_beam_w/2 - snap_clr - snap_post_w/2;   // 7.4
// stand = true (with snap): carrier and track print standing on their -y
// long edge with a brim, no supports. Both latches then face +y (barbs
// print upwards, never as floating tips), which puts the second beam at
// the centre of the cap/base where the ball bore was, so the detent is
// off in this variant. Posts get 45 deg gussets underneath, magnet
// pockets become teardrops. Caps still print face-down.
stand         = false;
snap_b_beam_y = -1.3;    // second latch, stand mode: beam centre |y|...
snap_b_post_y = -3.6;    // ...and post centre (barbs toward +y)
print_orient  = true;    // false exports every part un-rotated (for probes)
detent_on     = detent && !(snap && stand);   // no ball in the standing variant
snap_barb_len = snap_clr + snap_barb;                                     // 0.7
snap_beam_top = snap_hole_h + snap_beam_t;                                // 1.7
snap_post_top = snap_beam_top + snap_void_h + 0.7;                        // 2.9
snap_chan_top = snap_post_top + 0.2;                                      // 3.1

/* ------------------------------- sculpt ------------------------------ */
// The dome is a superellipsoid of the plan outline with two smooth
// Gaussian "thumb valleys" placed point-symmetrically, which
// leaves an S-shaped ridge between them like the original's sculpt.
sculpt       = true;
valley_depth = 1.5;             // mm below the plain dome at the valley centre
valley_sigma = [10, 4.5];       // Gaussian half-widths along / across the valley
valley_pos   = [-8, 4];         // first valley centre; second is at -pos
valley_rot   = 15;              // valley axis angle from the long axis

/* ---------------------- embedded (pause-and-insert) ------------------- */
emb_layer = 0.2;                 // layer height the pause heights align to
function ceil_to(v, s)  = ceil(v / s - 1e-6) * s;
function floor_to(v, s) = floor(v / s + 1e-6) * s;
// both single-piece halves print face-down, pockets measured from the face
emb_pocket_floor = groove_d + skin;                                              // 1.0
emb_pocket_top   = ceil_to(emb_pocket_floor + max(mag_big_t, mag_small_t) + 0.2, emb_layer);  // 4.2

// actual apex heights (the valleys pull the nominal apex down a little)
pillow_apex = z_top(0, 0, 0, pillow_h, pillow_side_h, valley_depth);
base_apex   = z_top(0, 0, 0, base_h, base_h - base_dome_h, valley_depth * base_dome_h / (pillow_h - pillow_side_h));
echo(str("assembled height = ", pillow_apex + track_t + base_apex, " mm (pillow ", pillow_apex,
         " + track ", track_t, " + base ", base_apex, "); carrier = ", carrier_t, " mm"));
echo(str("embedded halves (printed face-down): pause at z = ", emb_pocket_top,
         " (magnets, both halves) and z = ", carrier_t + spring_pocket_h,
         " (pillow: ball + spring)"));

/* ============================ primitives ============================ */
module rr(l, w, r) { offset(r = r) square([l - 2*r, w - 2*r], center = true); }
module slab(z, l, w, r) { translate([0, 0, z]) linear_extrude(SL) rr(l, w, r); }

function dome_z(rho, h, side_h) =
    rho >= 1 ? side_h
             : side_h + (h - side_h) * pow(1 - pow(rho, pillow_n), 1 / pillow_n);

function valley(x, y, s, vd) =
    let(dx = x - s*valley_pos[0], dy = y - s*valley_pos[1],
        u = dx*cos(valley_rot) + dy*sin(valley_rot),
        v = -dx*sin(valley_rot) + dy*cos(valley_rot))
    vd * exp(-(u*u / (valley_sigma[0]*valley_sigma[0]) + v*v / (valley_sigma[1]*valley_sigma[1])));

// dome height at (x, y); rho = 0 at the centre, 1 on the plan outline.
// h = nominal apex, side_h = vertical side height, vd = valley depth
function z_top(x, y, rho, h, side_h, vd) =
    let(fade = 1 - pow(min(rho, 1), 6))
    dome_z(rho, h, side_h) - (sculpt ? fade * (valley(x, y, 1, vd) + valley(x, y, -1, vd)) : 0);

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
// chamfer: only for a face that slides on the other half; a glued seat
// face (base under the track plate) stays square so the seam is a flush
// butt joint instead of a V-notch.
module pillow_poly(z0, h = pillow_h, side_h = pillow_side_h, vd = valley_depth, chamfer = true) {
    o  = outline_pts(L, W, R);
    oc = outline_pts(L - 2*face_c, W - 2*face_c, R - face_c);
    cham = chamfer && z0 < face_c;
    nr = dome_rings;                                     // ring count (excl. apex)
    pts = concat(
        [for (i = [0 : nr-1], j = [0 : pp_n-1]) let(k = dome_rho(i), x = k*o[j][0], y = k*o[j][1]) [x, y, z_top(x, y, k, h, side_h, vd)]],
        [[0, 0, z_top(0, 0, 0, h, side_h, vd)]],         // apex, index nr*pp_n
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
// base shell with the same sculpt, scaled to its shallower dome; h = apex
// height above its (sliding / track-seat) face at z = 0
module base_shape(h, chamfer = true) {
    pillow_poly(0, h, h - base_dome_h, valley_depth * base_dome_h / (pillow_h - pillow_side_h), chamfer);
}

// magnet pockets: [zb0, zb1] for the big ones, [zs0, zs1] for the small
// tear = true: teardrop section (45 deg roof towards +y) for a pocket that
// prints with its axis horizontal and +y up
module pocket_cyl(d, h, tear) {
    if (tear) linear_extrude(h) hull() { circle(d = d); translate([0, d/2 * sqrt(2) - 0.01]) square(0.02, center = true); }
    else cylinder(d = d, h = h);
}
module pockets(zb0, zb1, zs0, zs1, tear = false) {
    for (p = big_pos)   translate([p[0], p[1], zb0]) pocket_cyl(mag_big_d + mag_clr,   zb1 - zb0, tear);
    for (p = small_pos) translate([p[0], p[1], zs0]) pocket_cyl(mag_small_d + mag_clr, zs1 - zs0, tear);
}

// ball detent bore: mouth at the face (z = 0), bore up to h_top
module detent_cut(h_top) {
    translate([0, 0, -SL]) cylinder(d1 = mouth_d, d2 = bore_d, h = cone_h + SL);
    translate([0, 0, cone_h - SL]) cylinder(d = bore_d, h = h_top - cone_h + SL);
}

// concentric rounded-rectangle grooves cut into a face at z_top
// with_slot: the innermost "ring" has no inner edge left and becomes a
// lowered centre slot (home position for the ball on the track plate);
// the faces that carry the ball mouth skip it so the ball keeps its reach.
module groove_rings(with_slot = true) {
    n = floor((W/2 - groove_margin) / groove_pitch);
    difference() {
        for (i = [0 : n]) {
            ins = groove_margin + i * groove_pitch;
            if (with_slot || ins + groove_w < W/2)
                difference() {
                    offset(r = -ins) rr(L, W, R);
                    offset(r = -(ins + groove_w)) rr(L, W, R);
                }
        }
        if (groove_spokes)
            difference() {
                for (sx = [-1, 1], sy = [-1, 1])
                    rotate(atan2(sy * (W/2 - R), sx * (L/2 - R))) translate([0, -0.4]) square([L, 0.8]);
                offset(r = -(groove_margin + n * groove_pitch) + 0.01) rr(L, W, R);   // keep the centre slot open
            }
    }
}
// straight stripes at an angle, same pitch/width, with a flat island
// around the ball mouth (top half's face when carrier_groove_angle != 0)
module stripe_grooves(angle) {
    difference() {
        intersection() {
            offset(r = -groove_margin) rr(L, W, R);
            rotate(angle) for (i = [-24 : 24]) translate([i*groove_pitch - groove_w/2, -70]) square([groove_w, 140]);
        }
        if (detent_on) circle(d = island_d);
    }
}
// grooves into a top face at z_top (track plate)
module groove_cut(z_top) { translate([0, 0, z_top - groove_d]) linear_extrude(groove_d + 1) groove_rings(true); }
// grooves into a sliding face at z = 0 (parts modelled face-at-zero):
// kind = "track" (rings + centre slot), "top" (the top half's pattern)
module face_groove_cut(kind) {
    translate([0, 0, -1]) linear_extrude(groove_d + 1)
        if (kind == "track") groove_rings(true);
        else if (carrier_groove_angle == 0) groove_rings(false);
        else stripe_grooves(carrier_groove_angle);
}

/* ============================ snap latch ============================= */
// barbed post, base at z = 0, barb on the +y face (mirror for -y)
module snap_post() {
    w = snap_post_w;
    translate([-w/2, -w/2, 0]) cube([w, w, snap_post_top]);
    translate([-w/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(w)
        polygon([[w/2, 1.0], [w/2 + snap_barb_len, 1.0 + snap_barb_len],
                 [w/2 + snap_barb_len, snap_beam_top + snap_void_h], [w/2, snap_post_top]]);
}
// 45 deg gusset under a post's -y face (stand mode: -y is down in the print)
module snap_gusset() {
    w = snap_post_w; h = snap_post_top;
    translate([-w/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(w)
        polygon([[-w/2, 0], [-w/2, h], [-w/2 - h, 0]]);
}
module snap_posts(z) {
    if (snap && stand) {
        for (sx = [-1, 1], py = [snap_post_y, snap_b_post_y])
            translate([sx*snap_post_x, py, z]) { snap_post(); snap_gusset(); }
    } else {
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*snap_post_x, sy*snap_post_y, z]) mirror([0, sy < 0 ? 1 : 0, 0]) snap_post();
    }
}
// cavities cut into a face-down cap/base (face at z = 0) for one latch:
// beam centred on y = by (runs along x), posts centred on y = py < by,
// barbs towards +y. What is left between hole and void is the beam.
module snap_female(by = snap_beam_y, py = snap_post_y) {
    bw = snap_beam_w; g = snap_gap; Lb = snap_beam_len;
    y0 = by - bw/2 - g;  wy = bw + 2*g;
    translate([-Lb/2, y0, -1]) cube([Lb, wy, 1 + snap_hole_h]);                        // hole under the beam
    translate([-Lb/2, y0, snap_beam_top]) cube([Lb, wy, snap_void_h]);                 // void above it
    for (sy = [y0, by + bw/2]) translate([-Lb/2, sy, -1]) cube([Lb, g, 1 + snap_beam_top + snap_void_h]);   // side gaps
    cw = snap_post_w + 2*snap_clr;
    ext = (snap && stand) ? snap_post_top + snap_clr : 0;      // room for the gusset
    for (sx = [-1, 1]) {
        translate([sx*snap_post_x - cw/2, py - cw/2 - ext, -1]) cube([cw, (by - bw/2) - (py - cw/2 - ext), 1 + snap_chan_top]);   // post channel
        translate([sx*snap_post_x - cw/2, by - bw/2, snap_beam_top]) cube([cw, snap_barb + 0.3, snap_chan_top - snap_beam_top]);   // barb room
    }
}
module snap_females() {
    snap_female();
    if (snap && stand) snap_female(snap_b_beam_y, snap_b_post_y);
    else mirror([0, 1, 0]) snap_female();
}

/* ============================ printed parts ============================ */
// ---- recommended 4-part build --------------------------------------
// carrier plate: lower carrier_t of the pillow outline, sliding face at
// z = 0 (ridged, with the ball mouth), pockets open towards the cap.
// Exported flipped (face up) so the ridges print as a top surface.
module carrier() {
    difference() {
        outline_prism(carrier_t);
        pockets(carrier_t - mag_big_t - 0.1, carrier_t + 1, carrier_t - mag_small_t - 0.1, carrier_t + 1, snap && stand);
        if (detent_on) detent_cut(carrier_t + 1);
        if (grooves && carrier_grooves) face_groove_cut("top");
        if (!snap) for (p = peg_pos) translate([p[0], p[1], carrier_t - dowel_depth]) cylinder(d = dowel_d, h = dowel_depth + 1);
    }
    if (snap) snap_posts(carrier_t - SL);
}
// pillow cap: the rest of the pillow, flat face at z = 0 for printing
module pillow_cap() {
    translate([0, 0, -carrier_t]) difference() {
        pillow_poly(carrier_t);
        if (!snap) for (p = peg_pos) translate([p[0], p[1], carrier_t - SL]) cylinder(d = dowel_d, h = dowel_depth + SL);
        if (snap) translate([0, 0, carrier_t]) snap_females();
        if (detent_on) translate([0, 0, carrier_t - SL]) cylinder(d = bore_d, h = spring_pocket_h + SL);
    }
}
// base shell: sculpted dome, track-seat face at z = 0 with the pockets
// open towards the track plate (capped by it). Print orientation as is.
module base_capped() {
    difference() {
        base_shape(base_h, false);          // square seat edge: flush seam with the track
        pockets(-1, mag_big_t + 0.1, -1, mag_small_t + 0.1);
        if (!snap) for (p = peg_pos) translate([p[0], p[1], -1]) cylinder(d = dowel_d, h = dowel_depth + 1);
        if (snap) snap_females();
    }
}
// snap track plate in print orientation: ridged face on the bed (z = 0),
// barbed posts up from its back
module track_snap() {
    difference() {
        hull() {
            slab(0, L - 2*track_c, W - 2*track_c, R - track_c);
            slab(track_c, L, W, R);
            slab(track_t - SL, L, W, R);
        }
        if (grooves) face_groove_cut("track");
    }
    snap_posts(track_t - SL);
}
// grooved track plate, z = 0 underside .. track_t grooved top (glued build)
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
// Both print face-down (ridges on the bed, use a brim if they lift).
// Pocket ceilings sit on the emb_layer grid so the slicer never samples a
// layer exactly at the ceiling, and the pause heights are plain layer tops.
module pillow_embedded() {
    difference() {
        pillow_shape();
        pockets(emb_pocket_floor, emb_pocket_top, emb_pocket_floor, emb_pocket_top);
        if (detent) detent_cut(carrier_t + spring_pocket_h);
        if (grooves && carrier_grooves) face_groove_cut("top");
    }
}
module base_embedded() {
    difference() {
        base_shape(base_h + track_t);
        pockets(emb_pocket_floor, emb_pocket_top, emb_pocket_floor, emb_pocket_top);
        if (grooves) face_groove_cut("track");
    }
}

// ---- simplest: pockets open at the sliding face (no ridges, no detent) --
module pillow_open() {
    difference() {
        pillow_shape();
        pockets(-1, mag_big_t + 0.2, -1, mag_small_t + 0.2);
    }
}
module base_open() {
    difference() {
        base_shape(base_h + track_t);
        pockets(-1, mag_big_t + 0.2, -1, mag_small_t + 0.2);
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
    color("royalblue")  translate([0, 0, base_h]) mirror([0, 0, 1]) base_capped();   // dome down
    color("silver")     translate([0, 0, base_h + gap]) if (snap) translate([0, 0, track_t]) mirror([0, 0, 1]) track_snap(); else track();
    translate([slide[0], slide[1], base_h + track_t + 2*gap]) {
        color("lightsteelblue") carrier();
        color("silver") translate([0, 0, carrier_t + gap]) pillow_cap();
    }
}

/* =============================== export =============================== */
if (part == "pillow_cap")       pillow_cap();
// standing on the -y long edge: x stays, part y -> print z, posts point -y
module on_edge() { if (snap && stand && print_orient) translate([0, 0, W/2]) rotate([90, 0, 0]) children(); else children(); }
if (part == "carrier")          if (snap) on_edge() carrier(); else translate([0, 0, carrier_t]) mirror([0, 0, 1]) carrier();   // glued: ridges up; snap: posts up / on edge
if (part == "base")             base_capped();                                          // face down
if (part == "track")            if (snap) on_edge() track_snap(); else track();
if (part == "pillow_embedded")  pillow_embedded();
if (part == "base_embedded")    base_embedded();
if (part == "pillow_open")      pillow_open();
if (part == "base_open")        base_open();                                            // face down
if (part == "preview")          assembly(0, [7, 2.5]);
if (part == "exploded") {
    assembly(8, [0, 0]);
    magnets_mockup(base_h + 8 - mag_big_t - 1);
    translate([0, 0, base_h + track_t + 16 + carrier_t + 1]) magnets_mockup(0);
}
