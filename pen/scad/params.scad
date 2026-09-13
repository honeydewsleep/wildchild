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
