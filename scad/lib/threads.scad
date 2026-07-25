// =====================================================================
// Minimal printable-thread library (twist-extrusion method)
//
// The thread is a helical sweep of a lobed 2D profile: a disc whose
// radius ramps from r_root up to r_root+depth and back, extruded with
// linear_extrude(twist=...). Ramp length is chosen so the thread
// flanks sit at 45 degrees in the axial plane - safely printable with
// the part axis vertical, no supports.
//
// CLOCKING: male and female are generated from the same profile
// function with the same twist rate, each measured from its part's
// z=0 plane. When the two z=0 planes meet (flange face against base
// rim), the parts nest only at ONE relative rotation:
//     seated_rotation = female_phase - male_phase   (single start)
// so the seated orientation is deterministic and can be trimmed with
// a phase offset (see plate_clock_adjust in params.scad).
// =====================================================================

EPS = 0.01;  // local epsilon (this file is `use`d, so it cannot see
             // variables from the including file)

// lobe fraction 0..1 at polar angle a (degrees), single period = 360/starts
function _thr_frac(a, depth, lead, starts, crest_deg) =
    let(period = 360/starts,
        ramp   = 360*depth/lead,          // 45-degree flanks
        t      = ((a % period) + period) % period)
    t < ramp                 ? t/ramp :
    t < ramp + crest_deg     ? 1 :
    t < 2*ramp + crest_deg   ? 1 - (t - ramp - crest_deg)/ramp :
    0;

// full 2D thread profile (lobed disc), phase in degrees
module thread_profile(r_root, depth, lead, starts=1, phase=0, steps=240, crest_deg=12) {
    polygon([
        for (i = [0:steps-1])
            let(a = i*360/steps,
                r = r_root + depth*_thr_frac(a - phase, depth, lead, starts, crest_deg))
            [r*cos(a), r*sin(a)]
    ]);
}

// Solid male threaded rod, z=0..length. Right-hand thread.
module thread_male(r_root, depth, lead, length, starts=1, phase=0,
                   steps=240, slices_per_turn=120, crest_deg=12) {
    slices = max(20, ceil(length/lead*slices_per_turn));
    linear_extrude(height=length, twist=-360*length/lead,
                   slices=slices, convexity=10)
        thread_profile(r_root, depth, lead, starts, phase, steps, crest_deg);
}

// Cavity to subtract for the female thread, z=0..length.
// Same geometry as the male grown radially by `clearance`.
module thread_female_cavity(r_root, depth, lead, length, clearance,
                            starts=1, phase=0, steps=240,
                            slices_per_turn=120, crest_deg=12) {
    slices = max(20, ceil(length/lead*slices_per_turn));
    linear_extrude(height=length, twist=-360*length/lead,
                   slices=slices, convexity=10)
        thread_profile(r_root + clearance, depth, lead, starts, phase, steps, crest_deg);
}

// 45-degree lead-in cone for the female mouth (add to the cavity at z=0)
module thread_mouth_chamfer(r_root, depth, clearance, flare=1.2) {
    r_big = r_root + clearance + depth + flare;
    translate([0, 0, -EPS])
        cylinder(h = depth + flare, r1 = r_big, r2 = r_root + clearance);
}

// Cone to intersect with the male rod so the thread tip tapers in
// (easier starting, no elephant-foot snag). Tapers the LAST `taper` mm.
module thread_tip_taper(r_root, depth, length, taper=1.8) {
    union() {
        cylinder(h = length - taper + EPS, r = r_root + depth + EPS);
        translate([0, 0, length - taper])
            cylinder(h = taper, r1 = r_root + depth + EPS, r2 = r_root + 0.4);
    }
}
