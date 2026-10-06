// =====================================================================
// Mini capsule-filling funnel (size 00 default) + matching tamper
//
// Goal: the biggest possible hole for a stubborn powder, with the
// thinnest walls that still print.
//
// Two spout styles:
//   spout = "over"  (default) - the spout is a thin SOCKET that slips
//            OVER the capsule body. The hole is then limited only by
//            the capsule's own bore (~Ø7.6 for a 00), not by a printed
//            wall. Also self-centres on the body.
//   spout = "in"    - super-thin tube that drops INTO the body, so
//            nothing can spill between funnel and capsule. Wall is a
//            SINGLE extrusion line (0.45 mm @ 0.4 nozzle - enable thin
//            wall detection / Arachne in the slicer). Hole = body ID -
//            insert_clr - 2*insert_wall (~Ø6.9 for a 00). The cone
//            shoulder lands on the capsule rim as a depth stop.
//
// Cone is steep (cone_angle from horizontal) and the inside is one
// smooth polygon of revolution - no steps for powder to bridge on.
//
// parts:  part = "funnel"  (exports mouth-down, ready to print)
//         part = "tamper"  (rod that fits the bore, handle-down)
//         part = "preview" (funnel in use orientation + ghost capsule)
//
// Standalone: does not include params.scad.
// =====================================================================

part        = "funnel";
capsule     = "00";      // "000" | "00" | "0" | "1"
spout       = "over";    // "over" | "in"

// --- capsule table: [name, body OD, cap OD, body length] (mm, std) ---
capsule_tbl = [
    ["000", 9.55, 9.91, 22.20],
    ["00",  8.18, 8.53, 20.22],
    ["0",   7.34, 7.65, 18.44],
    ["1",   6.63, 6.91, 16.61],
];
cap_wall_t  = 0.12;      // gelatin/HPMC shell thickness (per side)

// --- printing ---------------------------------------------------------
wall        = 0.8;       // cone wall, measured normal to the surface
                         // (2 perimeters @ 0.4 nozzle; 0.6 ok w/ Arachne)
spout_wall  = 0.6;       // "over" socket wall
insert_wall = 0.45;      // "in" tube wall: one extrusion line. Do not go
                         // below your nozzle width - it won't print.
rim_w       = 2.0;       // flat grip rim around the mouth (also the
                         // print bed contact when printed mouth-down)
rim_t       = 1.2;

// --- geometry ---------------------------------------------------------
mouth_d     = 30;        // inner diameter at the top
cone_angle  = 68;        // cone slope from horizontal (steeper = taller)
throat_h    = 1.5;       // straight bore between cone and spout
socket_h    = 5.0;       // "over": how far the socket sleeves the body
socket_clr  = 0.30;      // "over": diametral clearance over body OD
bore_margin = 0.30;      // "over": hole = body ID - this (keeps the
                         // hole edge from landing outside the body rim)
insert_h    = 4.0;       // "in": how far the tube goes into the body
insert_clr  = 0.15;      // "in": diametral clearance inside body ID
                         // (the tube is only 4 mm long, so tight is ok)

// --- tamper -----------------------------------------------------------
tamper_clr  = 0.5;       // diametral, vs the funnel bore
tamper_len  = 45;        // rod length below the handle
tamper_hd   = 16;        // handle disc diameter
tamper_ht   = 3;         // handle disc thickness

$fn = 128;
EPS = 0.01;

// =====================================================================
// derived
// =====================================================================
function cap_row(n) = [for (r = capsule_tbl) if (r[0] == n) r][0];
row      = cap_row(capsule);
body_od  = row[1];
body_id  = body_od - 2*cap_wall_t;
body_len = row[3];

over     = (spout == "over");

// hole radius
bore_in_r = (body_id - insert_clr)/2 - insert_wall;   // "in" hole
bore_r   = over ? (body_id - bore_margin)/2 : bore_in_r;
// spout tube radii
sock_r   = (body_od + socket_clr)/2;              // "over" socket ID/2
sp_in_r  = over ? sock_r : bore_r;               // spout inner radius
sp_out_r = over ? sock_r + spout_wall
                : (body_id - insert_clr)/2;      // spout outer radius
sp_h     = over ? socket_h : insert_h;           // spout height

mouth_r  = mouth_d/2;
z1       = sp_h + throat_h;                      // cone starts here
H        = z1 + (mouth_r - bore_r) * tan(cone_angle);  // overall height
w_h      = wall / sin(cone_angle);               // cone wall, horizontal
r_c1     = bore_r + w_h;                         // cone outer radius @ z1
function r_cone_out(z) = r_c1 + (z - z1) / tan(cone_angle);
function z_cone_out(r) = z1 + (r - r_c1) * tan(cone_angle);

// shoulder the cone sits on, above the spout
sh_r     = over ? max(r_c1, sp_out_r) : max(r_c1, body_od/2 + 0.8);

echo(str("capsule ", capsule, "  body OD ", body_od, "  body ID ", body_id));
echo(str("spout=", spout, "  HOLE Ø", 2*bore_r, "  spout OD ", 2*sp_out_r,
         "  height ", H, "  mouth Ø", mouth_d));

// =====================================================================
// cross-section (r, z), in-use coords: z=0 at spout bottom, +z up
// =====================================================================
inner_pts = over
    ? [ [sp_in_r + 0.4, 0],               // entry chamfer for the body
        [sp_in_r, 0.4],
        [sp_in_r, sp_h - (sp_in_r - bore_r)],
        [bore_r, sp_h],                   // 45° land from socket to bore
        [bore_r, z1],
        [mouth_r, H] ]
    : [ [bore_r + 0.3, 0],                // tip chamfer
        [bore_r, 0.3],
        [bore_r, z1],
        [mouth_r, H] ];

// outer, top to bottom
outer_pts = concat(
    [ [mouth_r + rim_w, H],
      [mouth_r + rim_w, H - rim_t],
      [r_cone_out(H - rim_t), H - rim_t] ],
    // cone outer meets the shoulder radius
    (sh_r > r_c1)
        ? [ [sh_r, z_cone_out(sh_r)] ]
        : [ [r_c1, z1] ],
    // shoulder -> spout outer
    over
        ? ( (sh_r > sp_out_r)
            ? [ [sh_r, sp_h], [sp_out_r, sp_h - (sh_r - sp_out_r)] ]  // 45° chamfer
            : [] )
        : [ [sh_r, sp_h], [sp_out_r, sp_h] ],
    [ [sp_out_r, 0.3], [sp_out_r - 0.3, 0] ]  // tiny outer chamfer at the tip
);

profile = concat(inner_pts, outer_pts);

module funnel_body() {
    rotate_extrude() polygon(profile);
}

module tamper() {
    // sized to the smaller ("in") bore so one tamper fits both funnels
    d = 2*bore_in_r - tamper_clr;
    // handle disc on the bed, rod up
    cylinder(h = tamper_ht, d = tamper_hd);
    translate([0, 0, tamper_ht - EPS]) {
        cylinder(h = tamper_len - 1 + EPS, d = d);
        translate([0, 0, tamper_len - 1])
            cylinder(h = 1, d1 = d, d2 = d - 1.2);   // soft tip
    }
}

module capsule_ghost() {
    %color([0.9, 0.5, 0.2, 0.35])
        translate([0, 0, -body_len + (over ? sp_h : -insert_h + sp_h)])
            difference() {
                cylinder(h = body_len, d = body_od, $fn = 64);
                translate([0, 0, cap_wall_t])
                    cylinder(h = body_len, d = body_id, $fn = 64);
            }
}

if (part == "funnel") {
    // print mouth-down: flip so the rim is on the bed
    translate([0, 0, H]) rotate([180, 0, 0]) funnel_body();
} else if (part == "tamper") {
    tamper();
} else if (part == "preview") {
    funnel_body();
    capsule_ghost();
}
