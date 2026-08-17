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

trough_w   = 10.00;   // cable/finger trough down the 45 deg front face
trough_on  = true;

// Cable exit. On this module the connector edge is a SHORT edge, which
// in landscape becomes a Y end, so the notch goes in the end wall.
// Widen / move it here if the port on your board sits elsewhere.
port_on    = !is_orig;
port_w     = 12.00;   // wide enough to pass a USB-C plug
port_h     = skirt_h; // full skirt height
port_x     = 0.00;    // offset along the edge from centre
port_end   = -1;      // -1 = -Y wall, +1 = +Y wall

/* -------------------------------------------------------------- */
/* derived                                                         */
/* -------------------------------------------------------------- */
outer   = [body[0] + 2*wall[0], body[1] + 2*wall[1]];
ztop    = skirt_h + 2*max(outer[0], outer[1]);   // scratch height

// apex of the two X-facing planes (ridge line height and position)
apex_dz = outer[0] / (1/tan(ang_front) + 1/tan(ang_back));
apex_x  = outer[0]/2 - apex_dz/tan(ang_front);
apex_z  = skirt_h + apex_dz;

echo(str("outer = ", outer, "  apex z = ", apex_z, "  apex x = ", apex_x));

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
/* the part                                                        */
/* -------------------------------------------------------------- */
module stand() {
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

        // cable exit through the end wall
        if (port_on)
            translate([port_x - port_w/2,
                       port_end > 0 ? body[1]/2 - 1 : -outer[1]/2 - 1,
                       -EPS])
                cube([port_w, wall[1] + 2, port_h + EPS]);
    }
}

stand();
