// =====================================================================
// SHAPE OPTIONS - VISUAL MOCKUPS ONLY (not print-ready parts)
//
// Each lamp uses the same construction language as the double-sided
// ring: opaque outline band, translucent diffuser faces on BOTH
// sides, surface-mounted bulb + threaded stem into the matched base.
// Pick favourites and they get engineered into full print-ready
// parts (strip channel, diffuser snap trays, wire passage, etc).
//
// shape = heart | peace | star | hex | moon | cloud
// =====================================================================
include <../params.scad>

shape = "heart";
BAND  = 22;     // glow band width
DEPTH = 40;     // front-to-back, same as the ring

/* --------------------------- 2D outlines -------------------------- */
module heart2d() {
    s = 118;
    // gentle closing on the top notch only; bottom tip stays sharp
    translate([0, -83]) offset(r = -6) offset(r = 6)
        rotate(45) union() {
            square([s, s]);
            translate([s/2, s]) circle(d = s, $fn = 120);
            translate([s, s/2]) circle(d = s, $fn = 120);
        }
}
// peace sign as ONE connected hollow glow region: ring band + bars,
// leaving three window openings (each gets its own edge walls)
module peace2d() {
    union() {
        difference() {
            circle(d = 180, $fn = 160);
            circle(d = 180 - 2*BAND, $fn = 160);
        }
        intersection() {
            union() {
                translate([-7, -90]) square([14, 180]);
                for (a = [45, -45])
                    rotate(a) translate([-7, -92]) square([14, 92]);
            }
            circle(d = 180 - 2*BAND + 4, $fn = 160);
        }
    }
}
module star2d() {
    offset(r = 6) offset(r = -6-9) offset(r = 9)
        polygon([for (i = [0:9])
            let(a = 90 + i*36, r = (i % 2 == 0) ? 97 : 48)
            [r*cos(a), r*sin(a)]]);
}
module hex2d() { offset(r = 14) circle(r = 76, $fn = 6); }
module moon2d() {
    // solid crescent (glows across its whole area)
    offset(r = 5) offset(r = -5) difference() {
        circle(r = 88, $fn = 160);
        translate([34, 22]) circle(r = 74, $fn = 160);
    }
}
module cloud2d() {
    // solid cloud
    offset(r = 6) offset(r = -6) intersection() {
        union() {
            translate([-52, 12]) circle(r = 34, $fn = 96);
            translate([-8, 32]) circle(r = 44, $fn = 96);
            translate([42, 16]) circle(r = 36, $fn = 96);
            translate([-6, -4]) square([110, 40], center = true);
        }
        translate([0, 26]) square([220, 130], center = true);
    }
}

/* ------------------- generic mockup lamp builder ------------------- */
// solid=true: shape glows across its full area (region may have holes)
// sharp=true: inner outline uses mitered offset - inside corners come
//             to points mirroring the outside (heart's bottom V)
module lamp_mock(solid = false, sharp = false) {
    // opaque edge walls
    color("WhiteSmoke") linear_extrude(DEPTH) difference() {
        children(0);
        offset(r = -2) children(0);
    }
    if (!solid)
        color("WhiteSmoke") linear_extrude(DEPTH) difference() {
            if (sharp) offset(delta = -BAND + 2) children(0);
            else offset(r = -BAND + 2) children(0);
            if (sharp) offset(delta = -BAND) children(0);
            else offset(r = -BAND) children(0);
        }
    // translucent faces, both sides
    for (z = [-1.2, DEPTH])
        color("LightCyan", 0.5) translate([0, 0, z]) linear_extrude(1.2)
            difference() {
                children(0);
                if (!solid) {
                    if (sharp) offset(delta = -BAND) children(0);
                    else offset(r = -BAND) children(0);
                }
            }
}

// stem + bulb + matched base, attached at the outline's lowest point
module on_base(ylow) {
    sc = 59.5;   // base height (skirt + shell)
    color("DimGray") {
        translate([0, 0, 9.5]) cylinder(h = 50, d1 = 95, d2 = 86.6, $fn = 96);
        cylinder(h = 9.5, d = 96, $fn = 96);
    }
    color("WhiteSmoke") translate([0, 0, sc - 2])
        cylinder(h = ylow != 0 ? abs(ylow) : 16, d = m_stem_d, $fn = 64);
    // bulb blend suggestion
    color("WhiteSmoke") translate([0, 0, sc + 14])
        scale([1, 1, 0.55]) sphere(d = 46, $fn = 64);
}

module shape_lamp(solid = false, ylow = -90, sharp = false) {
    on_base(ylow);
    translate([0, 0, 59.5 + 14 - ylow]) rotate([90, 0, 0])
        translate([0, 0, -DEPTH/2]) lamp_mock(solid, sharp) children(0);
}

/* --------------------------- selection ----------------------------- */
if (shape == "heart")  shape_lamp(false, -86, true) heart2d();
else if (shape == "peace")
    // bars are hollow glowing cavities too - whole sign lights up
    shape_lamp(true, -90) peace2d();
else if (shape == "star")  shape_lamp(false, -75) star2d();
else if (shape == "hex")   shape_lamp(false, -90) hex2d();
else if (shape == "moon")  shape_lamp(true, -92) moon2d();
else if (shape == "cloud") shape_lamp(true, -26) cloud2d();
