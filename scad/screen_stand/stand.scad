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

// Sunton/QDtech "Cheap Yellow Display" boards. Unlike the Guition
// these are BARE PCBs - the LCD is bonded to the front and there is no
// bezel to land on a rim - so they need a separate face piece, and the
// board is held by screws through its own four mounting holes rather
// than by the pocket walls.
//
// Every number below is off the maker's own LCM OUTLINE drawing
// (ShenZhen QDtech), not measured or inferred:
//   2.8" ESP32-2432S028R = QDtech E32R28T, drawing rev V1.0 2024-08-31
//   4.0" ESP32-4832S040  = QDtech E32R40T, drawing rev V1.0 2025-04-15
// Cross-checked against the user's Front_Panel__Symmetrical_Bezel.stl,
// which is cut for the 2.8": its screw grid measures 78.4 x 42.0 against
// the drawing's 78.00 x 42.00, and its window sits 2.90 mm off the panel
// centre - exactly the drawing's active-area offset. Independent
// agreement on the one number the whole bezel hangs off.
//
//   pcb    PCB outline                     [across, along]
//   hole   mounting-hole grid, 4 x Ø3.20, centred on the PCB both ways
//   glass  LCD BL outline - the glass the face piece lands on
//   vis    RTP VA, the visible window. The aperture may not go inside
//          this or it crops what the user can see.
//   off    the ONE asymmetry: the display sits this far toward the
//          ESP32 end of the PCB, so the board centre is -off from the
//          screen centre. Everything across the short axis is centred.
//   stack  [pcb_t, front total, max SMD height on the back]
c28_pcb   = [50.00,  86.00];   c40_pcb   = [60.88, 111.11];
c28_hole  = [42.00,  78.00];   c40_hole  = [53.28, 104.11];
c28_glass = [50.00,  69.20];   c40_glass = [60.88,  94.57];
c28_vis   = [45.20,  59.45];   c40_vis   = [56.88,  85.22];
c28_off   =   2.90;            c40_off   =   2.875;
c28_stack = [1.60, 5.60, 5.09];  c40_stack = [1.60, 5.65, 5.09];

is_cyd   = (display == "cyd28" || display == "cyd40");
is_c40   = (display == "cyd40");
c_pcb    = is_c40 ? c40_pcb   : c28_pcb;
c_hole   = is_c40 ? c40_hole  : c28_hole;
c_glass  = is_c40 ? c40_glass : c28_glass;
c_vis    = is_c40 ? c40_vis   : c28_vis;
c_off    = is_c40 ? c40_off   : c28_off;
c_stack  = is_c40 ? c40_stack : c28_stack;
pcb_t    = c_stack[0];      // 1.60
stack_t  = c_stack[1];      // front face of PCB to front of glass + pcb
glass_h  = stack_t - pcb_t; // how far the glass stands proud of the PCB
smd_h    = c_stack[2];

// Board centre relative to the FRAME centre. The frame is centred on
// the screen (that is what makes the bezel symmetric), so the board
// hangs off toward its ESP32/USB end by exactly the display offset.
board_dy = -c_off;

/* -------------------------------------------------------------- */
/* thin symmetrical bezel                                          */
/* -------------------------------------------------------------- */
// The whole point of the CYD variants. "Symmetrical" here means
// opposite pairs match - left = right, top = bottom - with each pair
// squeezed to its own minimum, rather than one uniform frame all round
// (which the long axis would force out to ~18 mm on every edge).
//
// Two things set the minimum, and nothing else is free:
//   inner edge  the aperture cannot go inside the visible area, so it
//               is vis + 2*ap_clr and no smaller.
//   outer edge  the frame must still cover the PCB. Centred on the
//               screen, the board reaches pcb/2 + off on its far side,
//               so the half-width is that plus clearance plus wall.
// Everything between those two is bezel, and it falls out - there is
// no bezel width parameter to tune, which is the point.
ap_clr   = 0.20;   // per side, aperture vs visible area
pcb_clr  = 0.25;   // per side, PCB vs pocket wall
aperture = [c_vis[0] + 2*ap_clr, c_vis[1] + 2*ap_clr];
ap_r     = 1.50;   // aperture corner radius
ap_cham  = 0.60;   // chamfer round the front of the window



wall     = is_orig ? o_wall   : g_wall;
// CYD: the outer is derived from the board and the offset, then the
// pocket falls out of it - the reverse of the Guition path, where the
// module's known body sets the pocket and the outer follows.
cyd_outer = [c_pcb[0] + 2*(pcb_clr + wall[0]),
             c_pcb[1] + 2*(pcb_clr + wall[1]) + 2*c_off];
body     = is_cyd  ? [cyd_outer[0] - 2*wall[0], cyd_outer[1] - 2*wall[1]]
         : is_orig ? o_body : g_body;
// Edge treatment. The geometry is identical in all three; only how the
// OUTER solid's edges are finished differs. Cavity, socket cutout and
// magnet pockets are subtracted afterwards either way, so every fit is
// untouched.
//   "crisp" - as designed: flat facets, plan corners rounded r4
//   "sharp" - plan corners taken to zero as well, so the shell is
//             nothing but flat facets meeting on hard lines (low-poly)
//   "soft"  - every outer edge broken by soft_r. Done by shrinking the
//             solid by soft_r and Minkowski-summing a sphere back on:
//             for a convex solid that returns each face to exactly its
//             original plane and rounds only the edges between them, so
//             the outside dimensions do not move.
//
// SOFT AT r3.0 IS THE FINAL DESIGN - it is what the main STL builds and
// what every derived board variant inherits. r3.0 is close to the
// practical ceiling: the flat back is 17.5 x 89.5 at this radius and the
// socket needs 13.6 x 5.5 of it, so going much rounder starts running
// the socket flange off the flat. "crisp"/"sharp" are kept for the
// low-poly alternates and for the orig43 verification replica.
edges    = "soft";
soft_r   = 3.00;

// Faceted side panels. Splits each +/-Y end into TWO slopes meeting at a
// crease instead of one, which adds a hard angle change down each side.
// Both planes go into the cavity as well as the outer solid - the shell
// is the gap between the two, so a plane added to only one of them would
// thin or breach the 2.5 mm wall. Cutting into the outer alone is not an
// option here: there is only 2.5 mm to give before the cavity, which is
// why this is done as roof geometry rather than as a surface treatment.
end_facet   = false;
ang_end_lo  = 80.00;  // lower slope, near-vertical flank
end_crease_z= 24.00;  // height of the crease - the shoulder line
ang_end_hi  = 35.00;  // upper slope, folding hard away from it

r_out    = (edges == "sharp") ? 0 : (is_orig ? o_r_out : g_r_out);
r_in     = is_orig ? o_r_in   : g_r_in;
relief   = is_orig ? o_relief : g_relief;

/* -------------------------------------------------------------- */
/* shell - all of these are held constant from the original        */
/* -------------------------------------------------------------- */
// Pocket depth / height of the vertical skirt. The Guition module is a
// finished 7.25 mm body so 9.00 holds it; a CYD is a stack - glass
// proud of the PCB, the PCB, then up to 5.09 mm of SMD on its back -
// and the screw posts have to finish inside the skirt too, so it is
// driven rather than chosen: stack_t + smd_h = 10.69 to clear the
// board, stack_t + post_h = 11.60 to contain the posts.
skirt_h    = is_cyd ? 12.00 : 9.00;
roof_t     = 2.50;    // roof wall thickness, measured along its normal
ang_front  = 45.00;   // +X face - the shallow rest face (45 deg tilt)
ang_back   = 57.32;   // -X face - the upright rest face  (57 deg tilt)
ang_end    = 57.78;   // +/-Y end faces

/* -------------------------------------------------------------- */
/* the flat back                                                   */
/* -------------------------------------------------------------- */
// The wedge's apex is the point where the 45 and 57.3 deg faces meet -
// and when the stand sits on its 45 deg face, that apex lies ON THE
// DESK at the rear. Truncating it with a fifth plane therefore does
// not touch the silhouette's proportions or any of the three face
// angles; it just squares off the back corner.
//
// Cut that plane at 45 deg and the new facet comes out exactly
// VERTICAL in use: a small flat back panel standing off the desk, with
// the socket cut square through it so the cable leaves horizontally.
// It is the same construction as the other four faces; only its wall
// thickness differs (back_pan_t, to suit the snap-in socket).
back_flat   = !is_orig;   // replica stays faithful to the donor

// Which rest position the facet is tuned for. Cutting the facet square
// to a rest face is what makes the panel stand vertical there and the
// socket point horizontally - but a facet can only be square to ONE of
// them, since the two rest faces are 77.68 deg apart.
//
//   "flat45"   - square to the 45 deg face: panel vertical when the
//                stand sits at 45 deg. This cut runs straight ACROSS
//                the 57.3 deg face though, taking it 45.7 -> 19.1 mm,
//                which is why the stand tips backwards standing up.
//
//   "upright"  - square to the 57.3 deg face instead. That cut runs
//                nearly parallel to the face it trims, so it barely
//                shortens it (42.2 mm) and the panel is vertical THERE.
//
//   "parallel" - facet parallel to the SCREEN. Square to neither, so
//                the panel leans in both positions (45 deg at 45,
//                32.7 deg upright) - but it trims the two faces evenly
//                rather than gutting one, and is the only cut that is
//                comfortably stable in BOTH. The catch is in the name:
//                parallel to the screen means the socket points
//                directly AWAY from the screen, which is downwards in
//                both positions, so it needs a 90 deg cable.
//
// Printing watches one surface: the inside of the panel is a ceiling
// over the cavity, lying at exactly |back_cut_a| from horizontal.
//   45.0 deg -> 0.20 mm step per 0.2 layer   prints clean
//   32.7 deg -> 0.31 mm                      prints clean
//    0.0 deg -> flat, so it is a BRIDGE      prints clean (12.8 mm span)
// The band to avoid is shallow-but-not-flat: at 10 deg the step is
// 1.13 mm and it sags, right behind the socket.
variant     = "parallel";   // the standard
is_upright  = (variant == "upright");
is_parallel = (variant == "parallel");
back_cut_a  = is_upright  ? ang_back - 90
            : is_parallel ? 0
            :               90 - ang_front;
back_flat_h = is_upright ? 16.00 : is_parallel ? 20.00 : 26.00;   // facet length

// How far the panel leans from vertical in each rest position. Zero in
// the position its own cut was made square to.
tilt_at_45  = abs(back_cut_a - (90 - ang_front));
tilt_at_57  = abs(back_cut_a - (ang_back - 90));

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

// Cable relief in the end wall. OFF: the module is fed from the
// panel-mount socket in the flat back, nothing needs to pass through
// the rim, so the skirt stays unbroken all the way round. Set true if
// you ever need a jumper to reach a connector on the module's edge.
// Optional cable relief through an end wall. OFF everywhere: every
// build feeds from the panel-mount socket in the flat back, so the
// skirt stays unbroken all the way round.
//
// Set true on a CYD and it opens onto the board's own USB-C, which sits
// on the -Y edge - the board hangs that way by c_off, so its tail is
// hard against that wall while the +Y end carries the slack. Centred on
// the board width, per the drawing's back view. Useful if you would
// rather plug straight into the board than run an internal lead.
cyd_port_w = 13.00;
cyd_port_h =  7.50;
cyd_port_z = stack_t + 0.90 - cyd_port_h/2;   // straddles the connector
port_on    = false;
port_w     = is_cyd ? cyd_port_w : 13.00;
port_h     = is_cyd ? cyd_port_h : skirt_h;
port_x     = 0.00;    // offset along the edge from centre
port_z     = is_cyd ? cyd_port_z : 0.00;   // bottom of the opening
port_end   = -1;      // -1 = -Y wall, +1 = +Y wall

/* -------------------------------------------------------------- */
/* panel-mount USB-C socket, in the flat back                      */
/* -------------------------------------------------------------- */
// Rectangular snap-in socket, not the threaded barrel. Opening copied
// from Base__45_Degree__Symmetrical_Bezel.stl, which is dimensioned
// for the sockets recommended for that model:
//
//   13.600 x 5.500, corner radius 1.200, prismatic through the wall
//   centred 8.950 above the floor
//
// Measured off that mesh, not eyeballed: the cutout profile is
// identical at three depths through its 2.00 mm wall, so it is a
// straight extrusion with no draft.
//
// That donor panel is 2.00 mm where our roof is 2.50, and a snap-in
// socket grips a panel thickness rather than clamping any thickness
// like a nut does - so the flat back is thinned to 2.00 to match.
usb_on     = !is_orig;
usb_cut    = [13.60, 5.50];  // [across the panel, up the panel]
usb_cut_r  =  1.20;
// Socket height up the panel. The square-cut variants take the donor's
// 8.95 straight, since their panel is vertical in its own position. The
// parallel one is vertical in neither, so instead its socket is placed
// where the two positions give it the SAME clearance above the desk:
// d*cos(tilt_45) = (L-d)*cos(tilt_57).
usb_h      = is_parallel
             ? back_flat_h*cos(tilt_at_57)/(cos(tilt_at_45) + cos(tilt_at_57))
             : 8.95;
usb_y      =  0.00;   // offset across the panel from centre
back_pan_t =  2.00;   // flat back wall thickness (donor's panel)

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
mag_on     = !is_orig && !is_cyd;   // CYD is screwed, not magnetic
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
/* face piece and screw posts (CYD only)                           */
/* -------------------------------------------------------------- */
// The face piece is NOT a separate object bolted onto the front - it
// is the front slice of the same solid. The outer is extruded from
// z = -face_t instead of z = 0 and then cut at z = 0, so the plate
// carries the identical rounded-rect outline and the identical soft
// edge, and the parting line lands flush all the way round. Building
// it as its own part would mean matching the Minkowski result by hand.
//
// The z >= z_front trim that keeps the bed face flat now applies to
// the plate's front instead of the body's rim, so the screen face is
// flat and crisp - which is what you want around a window - and every
// other edge stays soft.
face_t   = 2.40;                  // visible plate thickness
z_front  = is_cyd ? -face_t : 0;  // where the solid starts

// Assembly stack, from the plate's back face at z = 0:
//   0 .. glass_h    the LCD standing proud of the PCB; the plate lands
//                   on the glass, and a collar at each screw carries
//                   the load down to the PCB so tightening cannot bow
//                   the plate across the 4 mm air gap.
//   .. stack_t      the PCB
//   stack_t ..      the post, which the screw threads into.
// Magnetic attachment - nothing breaks the front face. The plate is
// pulled onto the tub by four magnet pairs that face each other THROUGH
// the PCB: one in a collar on the plate's back, one in a post below,
// coaxial with the board's own mounting holes. FR4 is not magnetic and
// the Ø3.20 hole sits right between them, so the only real gap is the
// board's 1.60 mm. The same force clamps the board.
//
// Where they can go is not a free choice. On the front of these boards
// the ONLY clear band is between the glass edge and the PCB edge -
// 8.40 mm on the 2.8", 8.27 mm on the 4.0" - which is exactly where the
// maker put the mounting holes. That caps the collar at Ø7.0 (checked
// against the glass edge, the PCB edge and the pocket wall on both
// boards, all four corners), so these are Ø5 magnets, not the Ø6 the
// Guition uses. Fit all eight the same way round in each part so the
// pairs attract.
cyd_mag_d = 5.00;
cyd_mag_l = 3.00;
cyd_mag_clr = 0.20;   // pocket = mag_d + clr
col_d    = 7.00;   // collar OD - Ø5.2 pocket leaves 0.9 mm of wall
post_d   = 7.60;   // the post has the pocket walls to itself, so beefier
post_h   = 6.00;
// The collar stands 0.05 proud of the glass height, so it lands on the
// PCB just before the plate's lip would land on the glass. The glass
// carries no clamping load.
col_bear = 0.05;

// Registration. Magnets alone would let the plate wander before they
// snap; the plate's silhouette is the tub's silhouette so any offset
// shows. A lip on the plate's back drops into the pocket at each ±Y
// end - the only two places the glass leaves clear - and picks up the
// ±X pocket walls across its width, which locates x, y and rotation.
lip_h    = 1.50;
lip_clr  = 0.15;   // per side, lip vs pocket wall
lip_gap  = 0.60;   // lip stands off the glass edge by this
// Beyond the PCB's far edge the lip deepens into a stop, so the board
// cannot slide toward the slack +Y end during assembly.
stop_gap = 0.35;

/* -------------------------------------------------------------- */
/* derived                                                         */
/* -------------------------------------------------------------- */
outer   = [body[0] + 2*wall[0], body[1] + 2*wall[1]];
ztop    = skirt_h + 2*max(outer[0], outer[1]);   // scratch height

// Crease point of the faceted ends: where the lower slope has got to by
// end_crease_z, which is where the upper slope starts from.
end_d_lo    = sin(ang_end_lo)*outer[1]/2 + cos(ang_end_lo)*skirt_h;
end_yc      = (end_d_lo - cos(ang_end_lo)*end_crease_z) / sin(ang_end_lo);


// apex of the two X-facing planes (ridge line height and position)
apex_dz = outer[0] / (1/tan(ang_front) + 1/tan(ang_back));
apex_x  = outer[0]/2 - apex_dz/tan(ang_front);
apex_z  = skirt_h + apex_dz;

// magnet seat: just clear of the screw heads standing on the module back
mag_face_z = mod_back_z + ret_head_h + mag_gap;

// Back-flat geometry, for ANY cut angle. The facet plane is
//   -sin(a)x + cos(a)z = dc
// and its two ends are where that meets the front and back faces. Both
// ends are affine in dc, so the facet's length is too - sample it at
// dc = 0 and 1 and invert to get the dc for a wanted length.
front_d = sin(ang_front)*outer[0]/2 + cos(ang_front)*skirt_h;
back_d  = sin(ang_back) *outer[0]/2 + cos(ang_back) *skirt_h;

function fct_fx(dc) = (front_d*cos(back_cut_a) - cos(ang_front)*dc)
                      / sin(ang_front + back_cut_a);
function fct_fz(dc) = (sin(ang_front)*dc + sin(back_cut_a)*front_d)
                      / sin(ang_front + back_cut_a);
function fct_bx(dc) = (back_d*cos(back_cut_a) - cos(ang_back)*dc)
                      / sin(back_cut_a - ang_back);
function fct_bz(dc) = (-sin(ang_back)*dc + sin(back_cut_a)*back_d)
                      / sin(back_cut_a - ang_back);
function fct_len(dc) = norm([fct_fx(dc) - fct_bx(dc),
                             fct_fz(dc) - fct_bz(dc)]);

back_L0 = fct_len(0);
back_L1 = fct_len(1);
back_dc = (back_flat_h - back_L0) / (back_L1 - back_L0);

// the facet's two ends: "front foot" sits on the desk in the 45 deg
// rest, "back foot" sits on it in the 57.3 deg rest
facet_fx = fct_fx(back_dc);  facet_fz = fct_fz(back_dc);
facet_bx = fct_bx(back_dc);  facet_bz = fct_bz(back_dc);

// Socket centre. usb_h is its height above the desk in the variant's
// own rest position, so it is measured from whichever foot is down
// there: the front foot at 45 deg, the back foot when upright.
usb_up  = is_upright ? back_flat_h - usb_h : usb_h;
usb_x   = facet_fx - usb_up*cos(back_cut_a);
usb_z   = facet_fz - usb_up*sin(back_cut_a);

echo(str("outer = ", outer, "  apex z = ", apex_z, "  apex x = ", apex_x));
if (is_cyd) echo(str("CYD ", display,
    ": outer = ", outer, "  aperture = ", aperture,
    "  bezel [across, along] = [", (outer[0]-aperture[0])/2, ", ",
                                   (outer[1]-aperture[1])/2, "]",
    "  glass overlap = [", (c_glass[0]-aperture[0])/2, ", ",
    "near ", (c_glass[1]/2 + board_dy) - aperture[1]/2, "]",
    "  screws at y = ", board_dy + c_hole[1]/2, " / ",
                        board_dy - c_hole[1]/2));
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
module wedge(foot, r, inset = 0, z0 = 0, pan = -1) {
    pan_i = (pan < 0) ? inset : pan;
    intersection() {
        translate([0, 0, z0]) linear_extrude(ztop - z0) rrect(foot[0], foot[1], r);
                         halfspace_x(outer[0]/2 - inset/sin(ang_front), skirt_h, ang_front);
        mirror([1,0,0])  halfspace_x(outer[0]/2 - inset/sin(ang_back),  skirt_h, ang_back);
        // NB one plane per if - braces would group them, and a group
        // inside intersection() is the UNION of its children, which
        // silently stops them cutting anything.
        if (!end_facet) rotate([0,0, 90]) halfspace_x(outer[1]/2 - inset/sin(ang_end), skirt_h, ang_end);
        if (!end_facet) rotate([0,0,-90]) halfspace_x(outer[1]/2 - inset/sin(ang_end), skirt_h, ang_end);
        if ( end_facet) rotate([0,0, 90]) halfspace_x(outer[1]/2 - inset/sin(ang_end_lo), skirt_h, ang_end_lo);
        if ( end_facet) rotate([0,0,-90]) halfspace_x(outer[1]/2 - inset/sin(ang_end_lo), skirt_h, ang_end_lo);
        if ( end_facet) rotate([0,0, 90]) halfspace_x(end_yc - inset/sin(ang_end_hi), end_crease_z, ang_end_hi);
        if ( end_facet) rotate([0,0,-90]) halfspace_x(end_yc - inset/sin(ang_end_hi), end_crease_z, ang_end_hi);
        // fifth plane uses the panel's own thickness, not roof_t
        // fifth plane, positioned by a point on it so any angle works
        if (back_flat)
            mirror([1,0,0])
                halfspace_x(0, (back_dc - pan_i) / cos(back_cut_a),
                            back_cut_a);
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
        outer_solid();
    }
}

module mag_pockets() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*screws[0]/2, sy*screws[1]/2, mag_face_z - EPS])
            cylinder(h = mag_l + EPS, d = mag_d + mag_clr);
}

// Socket opening, square through the flat back. In this frame local
// +z is the panel normal, +y runs across the panel and +x runs DOWN
// it, so the cut is usb_cut[1] tall by usb_cut[0] wide.
module usb_bore() {
    translate([usb_x, usb_y, usb_z])
        rotate([0, -back_cut_a, 0])
            translate([0, 0, -10]) linear_extrude(20)
                offset(r = usb_cut_r)
                    square([usb_cut[1] - 2*usb_cut_r,
                            usb_cut[0] - 2*usb_cut_r], center = true);
}

// The outer shell. "soft" shrinks it by soft_r on every face and puts
// the radius back as a sphere; the z>=0 trim keeps the bed face flat and
// its edge crisp, which is what the module's bezel seats against.
module outer_solid() {
    if (edges == "soft")
        intersection() {
            minkowski() {
                wedge([outer[0] - 2*soft_r, outer[1] - 2*soft_r],
                      max(0.01, r_out - soft_r),
                      inset = soft_r, z0 = z_front, pan = soft_r);
                sphere(r = soft_r, $fn = 48);
            }
            translate([-BIG/2, -BIG/2, z_front]) cube(BIG);
        }
    else
        wedge(outer, r_out, z0 = z_front);
}

/* -------------------------------------------------------------- */
/* CYD screw posts and face piece                                  */
/* -------------------------------------------------------------- */
// Post pad. Same trick as the magnet bosses: the seat sits 4 mm inboard
// of the pocket wall, and everything below it is PCB, so it cannot grow
// up from the floor. Hulling it out to a foot in EACH wall turns the
// span into a bridge anchored at both ends instead of a cantilever, and
// its underside at z = stack_t prints as a flat bridge rather than a
// sagging ramp.
module post_pad(sx, sy) {
    cx = sx*c_hole[0]/2;   cy = board_dy + sy*c_hole[1]/2;
    ax = sx*(body[0]/2 + wall[0]/2);
    ay = sy*(body[1]/2 + wall[1]/2);
    hull() {
        translate([cx, cy]) circle(d = post_d);
        translate([ax, cy]) circle(d = 3);
        translate([cx, ay]) circle(d = 3);
    }
}

module posts() {
    intersection() {
        translate([0, 0, stack_t])
            linear_extrude(post_h)
                for (sx = [-1, 1], sy = [-1, 1]) post_pad(sx, sy);
        outer_solid();
    }
}

module post_mag_pockets() {
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*c_hole[0]/2, board_dy + sy*c_hole[1]/2, stack_t - EPS])
            cylinder(h = cyd_mag_l + EPS, d = cyd_mag_d + cyd_mag_clr);
}

// Window, with a chamfer round its front lip.
module aperture_cut() {
    translate([0, 0, z_front - 1])
        linear_extrude(-z_front + glass_h + 2)
            rrect(aperture[0], aperture[1], ap_r);
    hull() {
        translate([0, 0, z_front - EPS]) linear_extrude(EPS)
            rrect(aperture[0] + 2*ap_cham, aperture[1] + 2*ap_cham,
                  ap_r + ap_cham);
        translate([0, 0, z_front + ap_cham]) linear_extrude(EPS)
            rrect(aperture[0], aperture[1], ap_r);
    }
}

// Glass and PCB edges in frame coordinates - these bound everything on
// the back of the plate.
glass_t  = board_dy + c_glass[1]/2;   glass_b = board_dy - c_glass[1]/2;
pcb_t_y  = board_dy + c_pcb[1]/2;     pcb_b_y = board_dy - c_pcb[1]/2;

// One ±Y band of the plate's back, clipped to the pocket outline.
module lip_band(y0, y1, h) {
    intersection() {
        linear_extrude(h)
            rrect(body[0] - 2*lip_clr, body[1] - 2*lip_clr, r_in);
        translate([-BIG/2, y0, -EPS]) cube([BIG, y1 - y0, h + 2*EPS]);
    }
}

module face_piece() {
  translate([0, 0, -z_front])       // prints as exported: window face down
  difference() {
    union() {
        intersection() {
            outer_solid();
            translate([-BIG/2, -BIG/2, z_front]) cube([BIG, BIG, -z_front]);
        }
        // registration lip at each end, clear of the glass
        lip_band(glass_t + lip_gap,  body[1]/2, lip_h);
        lip_band(-body[1]/2, glass_b - lip_gap, lip_h);
        // and its deeper section past the board, as a board stop
        lip_band(pcb_t_y + stop_gap, body[1]/2, stack_t - 0.20);
        // collars carrying the magnets down to the PCB
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*c_hole[0]/2, board_dy + sy*c_hole[1]/2, 0])
                cylinder(h = glass_h + col_bear, d = col_d);
    }
    aperture_cut();
    // magnet pockets, opening at the collar face. Blind: 1 mm of collar
    // plus the full plate thickness stays in front of them, so the
    // front face is unbroken apart from the window.
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*c_hole[0]/2, board_dy + sy*c_hole[1]/2,
                   glass_h + col_bear - cyd_mag_l])
            cylinder(h = cyd_mag_l + EPS, d = cyd_mag_d + cyd_mag_clr);
  }
}

/* -------------------------------------------------------------- */
/* the part                                                        */
/* -------------------------------------------------------------- */
module stand() {
  difference() {
    union() {
      if (mag_on) mag_bosses();
      if (is_cyd)  posts();
      difference() {
        outer_solid();

        // Cavity = straight display pocket for the full skirt height,
        // then the roof cavity above it. The step where they meet is
        // the soffit the module's back body stops against.
        union() {
            translate([0, 0, -EPS])
                linear_extrude(skirt_h + EPS) rrect(body[0], body[1], r_in);
            wedge(body, r_in, inset = roof_t, z0 = skirt_h,
                  pan = back_pan_t);
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
                       port_z])
                cube([port_w, wall[1] + 2, port_h]);
      }
    }

    if (mag_on) mag_pockets();
    if (is_cyd) post_mag_pockets();
    if (usb_on) usb_bore();
  }
}

/* -------------------------------------------------------------- */
/* part selection                                                  */
/* -------------------------------------------------------------- */
// "stand" - the tub. "face" - the bezel plate (CYD only); the Guition
// module brings its own bezel and needs no face piece.
part = "stand";

if (part == "face") {
    if (is_cyd) face_piece();
    else echo("part=\"face\" only exists for the CYD displays");
} else if (is_cyd) {
    intersection() { stand(); translate([-BIG/2, -BIG/2, 0]) cube(BIG); }
} else stand();
