// =====================================================================
// Pillow Blower Counter - desk stand v2: the "CYD Desk Buddy" base
// (32 degree, symmetrical bezel; MakerWorld model 2787810) with a flat
// top for three 16 mm chassis-mount buttons facing up.
//
// Unlike cyd_desk_stand.scad (a from-scratch parametric stand), this
// file keeps the ORIGINAL MESH: the front section - pocket, symmetrical
// bezel seat, hidden screw bosses, the rounded corners, the floor
// screw slots, the countersunk back-wall screw holes and the USB-C
// cable slot - is the untouched source STL. Only the sloped top wall is
// removed and a flat-topped rear section is grafted on, extruded from
// the original body's own cross-section at its top-front edge so the
// side fillets run straight through. The supplied Front Panel STL is
// used unchanged.
//
// Parts (openscad -o x.stl -D 'part="base"' cyd_desk_stand_v2.scad):
//   base       the stand (prints as modelled, floor down, no supports;
//              the flat top bridges 12 mm + 24 mm over the partition)
//   btn_test   30 mm square, one 16.3 mm hole, 2.4 mm thick
//   assembly   preview with the original front panel and buttons
//   check_orig the imported source mesh only (sanity)
//
// Assembly: as the original - CYD screwed to the panel posts, panel
// drops into the pocket, two screws come in through the floor slots
// and two through the (former) back wall, now an internal partition;
// those two are reached through matching access holes in the new back
// wall (a long driver, screw on the tip). Buttons drop through the top
// and take their nuts from inside the rear compartment, which is open
// underneath. The USB-C panel-mount slot is repeated in the new back
// wall; its cable (and the button wires) pass through the partition's
// original slot or the wire notch at the top of the partition.
//
// Coordinates: the source mesh's own frame (x 383.8..486.6, front face
// toward -y, back face y = 150.7, z up); the exported part is centred
// on x and keeps y as-is.
// =====================================================================
part = "assembly";

src_base  = "src/desk_buddy_base_32deg_symmetrical.stl";
src_panel = "src/desk_buddy_front_panel_symmetrical.stl";

/* ---------------- measured from the source mesh (do not retune) ------ */
tilt      = 32;                      // screen tilt, and the axis of the hidden screws
x0        = 435.2;                   // body centre line
W         = 102.8;                   // outer width (383.8 .. 486.6)
wall      = 2.0;
y_back0   = 150.7;                   // original back face -> becomes the partition
y_apex    = 137.834;                 // top-front edge (highest line of the body)
z_top     = 61.955;
frame_yp  = 92.3;                    // tilted-frame depth of the front frame's back face
top_in_zp = 123.6;                   // tilted-frame height of the sloped top's inner face
screw_x   = [398.92, 477.49];        // upper hidden screws (offset +2.9 like the PCB): axes cross y = 149.7 at z = 43.5
screw_z   = 43.5;
usb_slot  = [13.6, 5.5, 1.2];        // USB-C cable slot in the back wall: w, h, corner r
usb_pos   = [437.44, 8.95];          // its centre (x, z)

/* ---------------- buttons (16 mm chassis mount, nut from inside) ----- */
n_btn     = 3;
btn_hole  = 16.3;
btn_pitch = 30;
btn_nut_d = 22;                      // across-corners of the mounting nut (sets the rear depth)
btn_clr   = 1.0;
btn_body_d   = 18;                   // preview only
btn_body_len = 30;
top_t     = 2.4;                     // new flat top thickness (original walls are 2.0)

/* ---------------- rear section ------------------------------------- */
D_ext     = wall + btn_nut_d + 2 * btn_clr;          // partition -> new back face (26)
y_back    = y_back0 + D_ext;
y_btn     = y_back0 + (D_ext - wall) / 2;
wire_notch = [20, 8];                // pass-through at the top of the partition (0 = none)
corner_r  = 3;                       // rear vertical edges + top-back edge, as the original

$fn = 64;
EPS = 0.01;
btn_xs = [for (i = [0 : n_btn - 1]) x0 + (i - (n_btn - 1) / 2) * btn_pitch];
echo(str("v2 stand ", W, " W x ", y_back - 105.3, " D x ", z_top, " H mm; rear section ", D_ext,
         "; buttons at y=", y_btn, " x=", btn_xs));

/* ---------------- source mesh ------------------------------------- */
module orig() import(src_base, convexity = 10);

// world -> tilted frame used for the measurements: y' = y cosT - z sinT, z' = y sinT + z cosT
module in_tilted() rotate([-tilt, 0, 0]) children();

// remove the sloped top wall behind the front frame (side/back walls are rebuilt by the new shell)
module top_cutter() in_tilted() translate([x0 - 100, frame_yp + 0.7, top_in_zp - 0.6]) cube([200, 100, 40]);

// exact outer outline of the body at the top-front edge (2D: x, z)
module section2d() hull() projection(cut = true) rotate([-90, 0, 0]) translate([0, -y_apex, 0]) orig();

/* ---------------- new rear shell ---------------------------------- */
// sk: the new shell sits 0.02 inside the source surfaces where they overlap -
// exactly coincident faces make CGAL's union throw an assertion.
sk = 0.02;
module rear_outer() hull() {
    translate([0, y_apex + EPS, 0]) rotate([90, 0, 0]) linear_extrude(EPS) offset(delta = -sk) section2d();
    for (sx = [-1, 1]) translate([x0 + sx * (W / 2 - corner_r - sk), y_back - corner_r, 0]) {
        cylinder(r = corner_r, h = z_top - corner_r);
        translate([0, 0, z_top - corner_r]) sphere(corner_r);
    }
}
module rear_inner() intersection() {
    hull() {
        translate([0, y_apex - 1, 0]) rotate([90, 0, 0]) linear_extrude(EPS) union() {
            offset(delta = -(wall + sk)) section2d();
            translate([x0, 2]) square([W - 2 * wall, 6], center = true);   // open underneath
        }
        for (sx = [-1, 1]) translate([x0 + sx * (W / 2 - corner_r - sk), y_back - corner_r, -1]) {
            cylinder(r = corner_r - wall, h = z_top - corner_r + 1);
            translate([0, 0, z_top - corner_r + 1]) sphere(corner_r - wall);
        }
    }
    translate([x0 - 100, 0, -2]) cube([200, 400, z_top - top_t + 2]);
}
// the original back wall carried up to the new top, so it supports the bridge
module partition_ext() translate([x0 - W / 2 + wall - 0.05, y_back0 - wall - 0.05, 48]) cube([W - 2 * wall + 0.1, wall + 0.1, z_top - 1 - 48]);

module rrect(size, r) offset(r = r) offset(delta = -r) square(size, center = true);

module cutouts() {
    // USB-C cable slot through the new back wall, same as the original's
    translate([usb_pos[0], y_back + 1, usb_pos[1]]) rotate([90, 0, 0]) linear_extrude(wall + 2) rrect([usb_slot[0], usb_slot[1]], usb_slot[2]);
    // access holes for the two upper hidden screws, on their own (tilted) axes
    for (x = screw_x) translate([x, 149.7, screw_z]) rotate([-(90 + tilt), 0, 0]) translate([0, 0, 1.5]) cylinder(d = 7, h = 60);
    // wire notch at the top of the partition
    if (wire_notch[0] > 0)
        translate([x0, y_back0 - wall - 1, z_top - top_t - wire_notch[1] / 2]) rotate([-90, 0, 0])
            linear_extrude(wall + 2) rrect(wire_notch, 2);
    // button holes
    for (x = btn_xs) translate([x, y_btn, z_top - top_t - 1]) cylinder(d = btn_hole, h = top_t + 2);
}

// Union first, then cut: CGAL's union asserts if the source mesh is cut
// before it is joined to the new shell. The old sloped top is removed
// only where it lies inside the new cavity.
module base_raw() difference() {
    union() {
        orig();
        difference() { rear_outer(); rear_inner(); }
        partition_ext();
    }
    difference() { intersection() { top_cutter(); rear_inner(); } partition_ext(); }
    cutouts();
}
module base() translate([-x0, 0, 0]) base_raw();

/* ---------------- preview ----------------------------------------- */
// original front panel: its face (z = 0) on the base's front face, posts inward
face_c = [x0, 83.7 * cos(tilt) + 95.0 * sin(tilt), -83.7 * sin(tilt) + 95.0 * cos(tilt)];
n_out  = [0, -cos(tilt), sin(tilt)];
module panel(explode = 0) translate(face_c + explode * n_out) rotate([90 - tilt, 0, 0]) rotate([0, 180, 0])
    translate([-128, -128, 0]) import(src_panel, convexity = 6);
module button_mock() for (x = btn_xs) translate([x, y_btn, 0]) {
    color("silver") translate([0, 0, z_top - top_t - btn_body_len]) cylinder(d = btn_body_d, h = btn_body_len);
    color("silver") translate([0, 0, z_top - top_t - 3.5]) cylinder(d = btn_nut_d / 1.15, h = 3.5, $fn = 6);
    color("black") translate([0, 0, z_top - 0.5]) cylinder(d = 18, h = 3.5);
}
module btn_test() difference() {
    linear_extrude(top_t) rrect([30, 30], 3);
    translate([0, 0, -1]) cylinder(d = btn_hole, h = top_t + 2);
}

if (part == "base")       base();
if (part == "btn_test")   btn_test();
if (part == "check_orig") translate([-x0, 0, 0]) orig();
if (part == "assembly")   translate([-x0, 0, 0]) { base_raw(); color("gold", 0.85) panel(12); button_mock(); }
