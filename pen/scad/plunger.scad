// Bolt-action pen plunger ("Bolt Base"), parametric replica of the
// reference part. Ø7.62 x 20, Ø2.75 cross pin hole, Ø6 refill socket.
//   openscad -o plunger.stl plunger.scad
include <params.scad>

module plunger() {
    difference() {
        // cylinder with 0.5 mm fillets on both outer edges
        rotate_extrude()
            hull() {
                translate([pl_r - pl_fillet, pl_fillet])          circle(r = pl_fillet, $fn = 32);
                translate([pl_r - pl_fillet, pl_len - pl_fillet]) circle(r = pl_fillet, $fn = 32);
                square([EPS, pl_len]);
            }
        // refill-rear socket with chamfered mouth
        translate([0, 0, pl_sock_z]) cylinder(h = pl_len, r = pl_sock_r);
        translate([0, 0, pl_len - pl_sock_chamfer])
            cylinder(h = pl_sock_chamfer + EPS, r1 = pl_sock_r, r2 = pl_sock_r + pl_sock_chamfer + EPS);
        // cross pin hole (axis along Y)
        translate([0, 0, pl_pin_z]) rotate([90, 0, 0]) cylinder(h = 3 * pl_r, r = pl_pin_r, center = true, $fn = 48);
    }
}

plunger();
