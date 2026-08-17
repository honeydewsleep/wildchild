// =====================================================================
// Display wedge stand - parametric rebuild of the "4.3 inch Screen
// Stand" wedge, re-dimensioned for the Guition JC3248W535C (3.5").
//
// The original STL is a hollow wedge: a vertical skirt whose open
// bottom face is the display pocket, closed by a hip roof made of four
// planes (45 deg front, 57.3 deg back, 57.8 deg ends). The display
// module drops in from the open face; its bezel lands on the rim and
// its back body is captured by the pocket walls. The stand then rests
// on the 45 deg face (shallow tilt) or the 57.3 deg face (upright).
//
// Everything here is driven by the two source STLs the user supplied:
//   - a495b342-4.3inch_Screen_Stand.stl        -> form, angles, walls
//   - 1b409a3b-..._Wall_Mount_Enclosure.stl    -> JC3248W535C fit data
//
// Print face-down as exported: every outer face is >= 45 deg, so the
// whole part is self-supporting with no supports and no brim needed.
//
// Units mm. z=0 is the open rim face (the display side), +z into the
// wedge. Display long axis runs along Y => screen sits LANDSCAPE.
// =====================================================================

/* -------------------------------------------------------------- */
/* which display                                                   */
/* -------------------------------------------------------------- */
// "jc3248w535" - Guition 3.5" 320x480 (the new part)
// "orig43"     - replica of the source 4.3" stand, for verification
display = "jc3248w535";

$fa = 2;
$fs = 0.4;
EPS = 0.01;
BIG = 1000;

/* -------------------------------------------------------------- */
/* display data                                                    */
/* -------------------------------------------------------------- */
// Guition JC3248W535C, measured off the wall-mount STL that fits it:
//   pocket (module back body)  59.10 x 91.10, 7.25 deep
//   frame outer                63.10 x 95.10, corner r 4.0
//   corner brass nuts          52.25 x 84.50 spacing
//   module outline (datasheet) 62.0 x 94.5
g_body   = [59.10,  91.10];   // pocket = module back body + clearance
g_wall   = [ 2.00,   2.00];   // rim wall  -> outer 63.10 x 95.10
g_r_out  =   4.00;            // outer corner radius (matches the mount)
g_r_in   =   2.00;            // pocket corner radius (matches the mount)
g_relief = [52.25,  84.50];   // corner relief centres = brass-nut grid

// Source 4.3" stand, reverse-engineered from its mesh:
o_body   = [65.10, 112.15];
o_wall   = [ 2.15,   2.50];   // -> outer 69.40 x 117.15
o_r_out  =   3.50;
o_r_in   =   3.00;
o_relief = [61.00, 108.15];   // Ø6.8 corner reliefs at +/-30.5, +/-54.075
                              // (2.05 mm inboard of the pocket corners)

is_orig  = (display == "orig43");

body     = is_orig ? o_body   : g_body;
wall     = is_orig ? o_wall   : g_wall;
r_out    = is_orig ? o_r_out  : g_r_out;
r_in     = is_orig ? o_r_in   : g_r_in;
relief   = is_orig ? o_relief : g_relief;

/* -------------------------------------------------------------- */
/* shell - all of these are held constant from the original        */
/* -------------------------------------------------------------- */
skirt_h    = 9.00;    // pocket depth / height of the vertical skirt
roof_t     = 2.50;    // roof wall thickness, measured along its normal
ang_front  = 45.00;   // +X face - the shallow rest face (45 deg tilt)
ang_back   = 57.32;   // -X face - the upright rest face  (57 deg tilt)
ang_end    = 57.78;   // +/-Y end faces

// Corner reliefs. The original needs them: its Ø6.8 pockets sit 2.05 mm
// inboard of the pocket corners and scallop into the corner mass. The
// JC3248W535C does not - the wall mount clears this module with a plain
// r2.0 pocket corner, and a Ø6.8 relief in a 2.0 mm wall would leave
// only 0.65 mm of wall standing. So: replica only.
relief_d   = 6.80;
relief_on  = is_orig;

// Cable trough down the 45 deg face. The original routes its cable
// through here; this build feeds the module from a panel-mount socket
// instead, so the face stays closed. Replica only.
trough_w   = 10.00;
trough_on  = is_orig;

// Internal cable relief in the end wall - lets the short jumper reach
// the module's own connector. NOT the external cable exit any more;
// that is the panel-mount socket below. Set port_on = false to close
// the shell completely if your module's connector faces rearward into
// the cavity instead of out of an edge.
port_on    = !is_orig;
port_w     = 13.00;
port_h     = skirt_h; // full skirt height
port_x     = 0.00;    // offset along the edge from centre
port_end   = -1;      // -1 = -Y wall, +1 = +Y wall

/* -------------------------------------------------------------- */
/* panel-mount USB-C socket, back (57.3 deg) face                  */
/* -------------------------------------------------------------- */
// Round threaded barrel clamped by its nut. The roof is a uniform
// 2.50 mm slab with parallel inner and outer faces, so a plain bore
// normal to the face gives the connector a flat seat on both sides -
// no pad or boss needed. 2.50 mm sits inside the 1-4 mm panel range
// these connectors are built for.
//
// Bore for an M16 x 1 barrel. M12 -> 12.60, M22 -> 22.60.
// Nominal thread OD + 0.6: the bore runs normal to a 57.3 deg face, so
// its up-slope inside is a 32.7 deg overhang and droops slightly. 0.1 mm
// of radial clearance would bind on that droop; 0.3 will not.
usb_on     = !is_orig;
usb_bore_d = 16.60;
usb_z      = 26.00;   // height of the bore centre up the back face
usb_y      =  0.00;   // offset along the face from centre

// A bare bore in the middle of a big sloped triangle reads as a hole
// punched in the form, so the socket gets a plinth: a flat landing
// that grows out of the back face. Its sides taper in the same
// direction as the wedge's own hip lines, so it belongs to the shape
// rather than sitting on it.
//
// Printing sets the profile. Printed rim-down, a face is an overhang
// only where its normal turns downward, so the plinth's uphill and
// side walls are free - only the DOWNHILL wall would overhang, at a
// hopeless 32.7 deg. Extending the foot 4.5 mm downhill swings that
// wall to 89 deg, near vertical.
pad_h      =  2.00;   // how far the landing stands proud of the face
pad_len    = 26.00;   // along-slope
pad_w_lo   = 50.00;   // width at the downhill end; the uphill width is
                      // derived so the sides run parallel to the hips
pad_r      =  1.50;   // corner radius
pad_grow   =  3.00;   // taper run at the foot, all round
pad_shift  =  1.50;   // extra run downhill, for the overhang above

// The plinth thickens the panel the socket clamps to, 2.50 -> 4.50 mm.
// M16 barrels are threaded 8-10 mm so that is well inside their range,
// but if yours is short, set usb_cb_d to your flange diameter + 0.4 and
// the flange drops into a well that puts the seat back at 2.50 mm.
usb_cb_d   =  0.00;

/* -------------------------------------------------------------- */
/* magnet retention                                                */
/* -------------------------------------------------------------- */
// Brass/copper inserts are not ferromagnetic, so a magnet cannot pull
// on them directly. Instead a steel M3 button-head screw goes into
// each of the module's four corner inserts BEFORE the module is
// dropped in - which is also the answer to "the closed back means I
// can't reach them", since the screws are fitted with the module in
// hand and never touched again. The heads are then the ferrous targets
// for these four magnets.
mag_on     = !is_orig;
mag_d      =  6.00;
mag_l      =  3.00;
mag_clr    =  0.20;   // pocket diameter = mag_d + mag_clr
mag_gap    =  0.35;   // air gap, magnet face to screw head
// The module's back is NOT flat: the wall mount's z=3.25 surface is
// four corner pads of ~7.9 x 7.8 (area 206.8 = 4 x ~50), and between
// them the back protrudes 2.25 mm deeper. So the boss footprint has to
// stay inside those pads. At 3.425 / 3.30 from the walls, Ø8.4 reaches
// 7.63 / 7.50 inboard - just inside the 7.93 / 7.80 pad.
mag_boss_d =  8.40;
mod_back_z =  5.00;   // the corner pads' plane, below the rim
ret_head_h =  1.65;   // M3 button head, ISO 7380. Pan head = 2.1,
                      // socket cap = 3.0 - raising this pushes the
                      // magnet toward the 45 deg roof, so drop mag_l
                      // to 2.00 if you use a socket cap screw.
screws     = [52.25, 84.50];   // corner insert grid, from the wall mount

/* -------------------------------------------------------------- */
/* derived                                                         */
/* -------------------------------------------------------------- */
outer   = [body[0] + 2*wall[0], body[1] + 2*wall[1]];
ztop    = skirt_h + 2*max(outer[0], outer[1]);   // scratch height

// apex of the two X-facing planes (ridge line height and position)
apex_dz = outer[0] / (1/tan(ang_front) + 1/tan(ang_back));
apex_x  = outer[0]/2 - apex_dz/tan(ang_front);
apex_z  = skirt_h + apex_dz;

// magnet seat: just clear of the screw heads standing on the module back
mag_face_z = mod_back_z + ret_head_h + mag_gap;

// outward normal / plane offset of the back face, for the USB bore
back_d  = sin(ang_back)*outer[0]/2 + cos(ang_back)*skirt_h;
usb_x   = (cos(ang_back)*usb_z - back_d) / sin(ang_back);

// How fast the back face narrows per mm travelled up its slope - i.e.
// the slope of its own hip edges, in the face's plane. The plinth uses
// the same rate, so its sides read as parallel to them.
hip_rate = sin(ang_back) / tan(ang_end);
pad_w_hi = pad_w_lo - 2*hip_rate*pad_len;

echo(str("outer = ", outer, "  apex z = ", apex_z, "  apex x = ", apex_x));
echo(str("magnet seat z = ", mag_face_z, "  usb bore centre = [", usb_x, ",", usb_y, ",", usb_z, "]"));

/* -------------------------------------------------------------- */
/* primitives                                                      */
/* -------------------------------------------------------------- */
module rrect(sx, sy, r) {
    offset(r = r) square([sx - 2*r, sy - 2*r], center = true);
}

// Half-space keeping material at x <= the plane that passes through
// (px, z=pz) and climbs inboard at `ang` above horizontal.
module halfspace_x(px, pz, ang) {
    translate([px, 0, pz])
        rotate([0, ang - 90, 0])
            translate([-BIG, -BIG/2, -BIG/2]) cube(BIG);
}

// The hip-roof wedge: a rounded-rect prism cut by the four planes.
//   foot  - the extruded rounded rect (skirt footprint)
//   inset - shifts every roof plane inboard along its OWN normal, which
//           is exactly how the inner face of a constant-thickness roof
//           sits. The planes are always derived from `outer`, never
//           from `foot`, so roof thickness stays equal to `inset`.
module wedge(foot, r, inset = 0, z0 = 0) {
    intersection() {
        translate([0, 0, z0]) linear_extrude(ztop - z0) rrect(foot[0], foot[1], r);
                         halfspace_x(outer[0]/2 - inset/sin(ang_front), skirt_h, ang_front);
        mirror([1,0,0])  halfspace_x(outer[0]/2 - inset/sin(ang_back),  skirt_h, ang_back);
        rotate([0,0, 90]) halfspace_x(outer[1]/2 - inset/sin(ang_end),  skirt_h, ang_end);
        rotate([0,0,-90]) halfspace_x(outer[1]/2 - inset/sin(ang_end),  skirt_h, ang_end);
    }
}

/* -------------------------------------------------------------- */
/* magnet bosses                                                   */
/* -------------------------------------------------------------- */
// The seat sits 3.3 mm inboard of both pocket walls, so it cannot be
// cantilevered off one wall without a long droopy overhang. Instead
// the pad is hulled out to a foot in EACH wall, so its first layer is
// anchored at both ends and the span across the corner prints as a
// ~9 mm bridge. Nothing reaches below mag_face_z, so the module's back
// frame at z = 5.00 stays clear.
module mag_pad(sx, sy) {
    cx = sx*screws[0]/2;   cy = sy*screws[1]/2;
    ax = sx*(body[0]/2 + wall[0]/2);   // foot buried in the X wall
    ay = sy*(body[1]/2 + wall[1]/2);   // foot buried in the Y wall
    hull() {
        translate([cx, cy])              circle(d = mag_boss_d);
        translate([ax, cy - sy*2.5])     circle(d = 3);
        translate([cx - sx*2.5, ay])     circle(d = 3);
    }
}

module mag_bosses() {
    intersection() {
        translate([0, 0, mag_face_z])
            linear_extrude(mag_l + 1.5)
                for (sx = [-1, 1], sy = [-1, 1]) mag_pad(sx, sy);
        wedge(outer, r_out);
    }
}

module mag_pockets() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*screws[0]/2, sy*screws[1]/2, mag_face_z - EPS])
            cylinder(h = mag_l + EPS, d = mag_d + mag_clr);
}

// Everything below works in a frame sitting on the back face:
// rotate([0,-ang_back,0]) sends local +x up-slope, +y across the face
// and +z out along its normal.
module on_back_face() {
    translate([usb_x, usb_y, usb_z]) rotate([0, -ang_back, 0]) children();
}

// Plinth outline, local +x up-slope. Narrower uphill, echoing the hips.
module pad_profile(grow = 0) {
    offset(r = grow + pad_r) offset(delta = -pad_r)
        polygon([[-pad_len/2, -pad_w_lo/2], [-pad_len/2,  pad_w_lo/2],
                 [ pad_len/2,  pad_w_hi/2], [ pad_len/2, -pad_w_hi/2]]);
}

module usb_pad() {
    on_back_face() hull() {
        // foot, sunk into the roof so it merges cleanly
        translate([-pad_shift, 0, -2]) linear_extrude(2) pad_profile(pad_grow);
        // landing
        translate([0, 0, pad_h - EPS]) linear_extrude(EPS) pad_profile();
    }
}

// Bore normal to the face, through the roof slab and the plinth.
module usb_bore() {
    on_back_face() {
        translate([0, 0, -10]) cylinder(h = 20 + pad_h, d = usb_bore_d);
        // optional flange well, seat back down at the original face
        if (usb_cb_d > 0)
            cylinder(h = pad_h + 10, d = usb_cb_d);
    }
}

/* -------------------------------------------------------------- */
/* the part                                                        */
/* -------------------------------------------------------------- */
module stand() {
  difference() {
    union() {
      if (mag_on) mag_bosses();
      if (usb_on) usb_pad();
      difference() {
        wedge(outer, r_out);

        // Cavity = straight display pocket for the full skirt height,
        // then the roof cavity above it. The step where they meet is
        // the soffit the module's back body stops against.
        union() {
            translate([0, 0, -EPS])
                linear_extrude(skirt_h + EPS) rrect(body[0], body[1], r_in);
            wedge(body, r_in, inset = roof_t, z0 = skirt_h);
        }

        // corner reliefs so the module's corner bosses drop in clean
        if (relief_on)
            for (sx = [-1, 1], sy = [-1, 1])
                translate([sx*relief[0]/2, sy*relief[1]/2, -EPS])
                    cylinder(h = skirt_h + EPS, d = relief_d);

        // cable / finger trough down the middle of the 45 deg face
        if (trough_on)
            translate([apex_x, -trough_w/2, -EPS])
                cube([outer[0], trough_w, ztop]);

        // internal cable relief through the end wall
        if (port_on)
            translate([port_x - port_w/2,
                       port_end > 0 ? body[1]/2 - 1 : -outer[1]/2 - 1,
                       -EPS])
                cube([port_w, wall[1] + 2, port_h + EPS]);
      }
    }

    if (mag_on) mag_pockets();
    if (usb_on) usb_bore();
  }
}

stand();
