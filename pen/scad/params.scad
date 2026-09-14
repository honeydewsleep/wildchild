// Bolt-action pen, hex ("pencil") remix — shared parameters.
// All dimensions in mm. Body coordinates: z=0 at the open BACK end
// (where the plunger goes in), +z toward the writing tip.
//
// INTERIOR dimensions are copied verbatim from the reference
// "Bolt Body.stl" / "Bolt Base.stl" (measured from the meshes, see
// docs/reference-measurements.md). Do not change them: they are what
// fits the user's refills, spring and plunger.

$fn = 120;
EPS = 0.01;

// ---------------------------------------------------------------- body
body_len       = 124.3;   // overall length, back rim to tip face

// bore (back to front). Radii.
bore_r_plunger = 4.20;    // Ø8.40 plunger bore, z = 0 .. bore_z1
bore_z1        = 53.2;    // step down to refill bore
bore_r_refill  = 3.44;    // Ø6.88 refill bore, z = bore_z1 .. bore_z2
bore_z2        = 113.7;   // step down to spring seat
bore_r_spring  = 2.76;    // Ø5.52 spring seat bore, z = bore_z2 .. bore_z3
bore_z3        = 116.25;  // start of ~60° cone down to the tip bore
bore_z3b       = 116.85;  // end of that cone
bore_r_tip     = 1.86;    // Ø3.72 refill-cone bore, z = bore_z3b .. bore_z4
bore_z4        = 121.70;  // start of short cone down to the exit hole
bore_z4b       = 121.97;  // end of that cone
bore_r_exit    = 1.46;    // Ø2.92 exit hole, z = bore_z4b .. body_len

// ------------------------------------------------ exterior (the remix)
// Reference body was a plain Ø11.52 cylinder (wall 1.56 over the
// plunger bore).  The remix is a rounded hexagon like a pencil.
hex_af       = 10.4;    // across-flats. Wall over the Ø8.4 bore = (hex_af-8.4)/2 = 1.0
hex_corner_r = 1.2;     // corner rounding radius (a pencil has soft corners)
hex_clock    = 270;     // angle (deg) of the flat that carries the bolt slot
back_chamfer = 0.5;     // 45° chamfer on the back rim (reference had 0.33)

// Straight taper tip, copied from the click pen's grip section:
// half-angle 15.2° (Ø11 -> Ø4.25 over 10.5 mm there).
tip_half_angle = 15.2;  // deg
tip_r_exit     = 2.20;  // outer radius at the tip face (wall 0.74 around the Ø2.92 exit)

// ------------------------------------------------------- bolt track
// Reference slot geometry (through-cuts in the wall).  Angles are
// measured around the body axis; the reference slot walls are NOT
// radial: every cut is ~3° wider (per side) at the bore surface than
// at the outer surface, i.e. the walls lean outward — that is what the
// pin (Ø2.75) actually rides on.
track_dz     = 0;       // shift the whole bolt track (slot, hook, window) toward the tip, mm.
                        // body_hex_slot075.stl is rendered with -D 'track_dz=0.75'
slot_r_in    = 4.20;    // reference bore radius the inner outline lives on
slot_r_out   = 5.75;    // reference outer radius the outer outline lives on
slot_angle   = 270;     // main slot centre (deg)
slot_half_out = 20;     // main slot half-width at r_out (deg)  -> 3.93 mm wide
slot_half_in  = 22.65;  // main slot half-width at r_in  (deg)  -> 3.23 mm wide
slot_z_bottom = 9.55;   // lowest point of the slot (rounded end)
slot_z_top    = 20.6;   // flat top of the slot / hook / window
slot_end_r    = 2.0;    // rounded bottom end radius (mm, at r_out)
slot_fillet_r = 2.85;   // big fillet, right wall -> top
slot_fillet_z = 17.6;   // where that fillet leaves the right wall
window_angle  = 194.6;  // separate rounded window (clip / service window) centre
window_half_out = 19.3; // half-width at r_out (deg)
window_half_in  = 21.4; // half-width at r_in  (deg)

// ------------------------------------------------------- plunger
// (= "Bolt Base.stl", reproduced verbatim so the repo is self-contained)
pl_r        = 3.81;     // Ø7.62, slides in the Ø8.40 bore
pl_len      = 20.0;
pl_fillet   = 0.5;      // both outer edges
pl_pin_r    = 1.375;    // Ø2.75 cross hole (press-fit 2.85 filament / 2.5 pin)
pl_pin_z    = 9.475;    // cross hole centre from the plunger back face
pl_sock_r   = 3.0;      // Ø6.0 refill-rear socket
pl_sock_z   = 11.9;     // socket floor (socket depth = pl_len - pl_sock_z = 8.1)
pl_sock_chamfer = 0.5;  // 45° lead-in at the socket mouth

// ------------------------------------------------------- helpers
function polar(r, a, z) = [r*cos(a), r*sin(a), z];

// ================================================================ v2
// Two-piece bolt pen: knurled round grip (tip end) threaded into a hex
// barrel (bolt track, sealed round-faced back). Looks like the click
// pen; takes the same refill, spring and plunger as v1.
v2_stretch    = 0.75;   // extra length between tip and bolt track (v1 was 0.5-1 mm short)
v2_len        = body_len + v2_stretch;   // 125.05 overall, tip face to back face
v2_back_wall  = 1.5;    // sealed back wall (insignia relief goes into its outer face)
v2_back_face_r = 5.0;   // radius of the perfectly round bed face; 45° chamfer up to the hex from there

// grip (all from the TIP face, like the click pen's grip)
g_knurl_start = 10.6;   // knurl grooves start (they run out into the taper)
g_knurl_end   = 45.5;   // knurl ends = shoulder = joint face (click pen value)
g_knurl_r     = 5.5;    // knurl crest radius (Ø11.0)
g_knurl_depth = 0.5;    // groove depth (valleys Ø10.0)
g_knurl_n     = 30;     // grooves per helix family
g_knurl_lead  = 165;    // mm per turn -> 11.8° helix (click pen)
g_knurl_land  = 5.5;    // deg of flat land between grooves (at the crest)
g_thread_bore_r = 3.30; // Ø6.6 bore under the male thread (click pen uses Ø6.5; refill passes)

// joint thread (grip male, barrel female), 45° flanks, single start
j_root_r  = 4.0;        // male root radius (wall to the Ø6.6 bore = 0.70)
j_depth   = 0.6;        // crest r 4.6
j_pitch   = 1.5;
j_len     = 7.5;        // 5 turns
j_clr     = 0.30;       // validated print clearance from the lamp threads
j_crest_deg = 12;

// barrel (from the BACK face)
b_hex_af     = hex_af;      // 10.4 like v1
b_hex_corner = hex_corner_r;
b_neck_len   = 8.0;         // round Ø11 neck at the front that carries the female thread
b_blend_len  = 10.0;        // round -> hex blend behind the neck
b_joint_z    = v2_len - g_knurl_end;   // 79.55: barrel front face / grip shoulder
b_bore_r     = bore_r_plunger;         // Ø8.4 all the way to the thread (plunger goes in from the front)

// ink windows (barrel_window variant): two opposite slots on the flats
w_angles = [90, 270];
w_z0     = 30;
w_z1     = 60;
w_width  = 3.5;

// insignia: an SVG file name (in scad/) cut 1 layer deep into the back face; "" = none
v2_insignia      = "";
v2_insignia_size = 8.0;     // mm, longest side
v2_insignia_depth = 0.2;
