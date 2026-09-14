// Bolt track cutters shared by the v1 one-piece body and the v2 barrel.
// Expects params.scad to be included by the includer (slot_* etc.).
// ------------------------------------------------- lofted wall cuts
// A through-cut of the wall defined by its outline on the reference
// bore surface (r = slot_r_in) and on the reference outer surface
// (r = slot_r_out). Each outline is a list of [dtheta_deg, z] with the
// same vertex count; vertex k of one corresponds to vertex k of the
// other. The cut is the ruled surface through both, extended inward
// (into the bore) and outward (past the hex corners) so it cuts clean
// through whatever wall thickness the exterior has.
function cut_pts(center, out_pts, in_pts, ext_in = 0.7, ext_out = 1.3) =
    let(n = len(out_pts))
    concat(
        [for (k = [0:n-1]) let(
            po = polar(slot_r_out, center + out_pts[k][0], out_pts[k][1]),
            pi = polar(slot_r_in,  center + in_pts[k][0],  in_pts[k][1]))
            pi + (pi - po) * ext_in],
        [for (k = [0:n-1]) let(
            po = polar(slot_r_out, center + out_pts[k][0], out_pts[k][1]),
            pi = polar(slot_r_in,  center + in_pts[k][0],  in_pts[k][1]))
            po + (po - pi) * ext_out]);

function centroid(pts) = let(n = len(pts)) [for (i = [0:2]) (sum_col(pts, i) / n)];
function sum_col(pts, i, k = 0) = k >= len(pts) ? 0 : pts[k][i] + sum_col(pts, i, k + 1);

// signed area of a closed [x,y] outline (>0 = counter-clockwise)
function signed_area(pts, k = 0) = k >= len(pts) ? 0 :
    let(a = pts[k], b = pts[(k + 1) % len(pts)]) (a[0]*b[1] - b[0]*a[1]) / 2 + signed_area(pts, k + 1);
function reversed(pts) = [for (k = [len(pts)-1:-1:0]) pts[k]];

module wall_cut(center, out_pts_raw, in_pts_raw) {
    // normalise winding: outline counter-clockwise in (dtheta, z) as seen
    // from outside the body, so the face orientation below is right.
    ccw     = signed_area(out_pts_raw) > 0;
    out_pts = ccw ? out_pts_raw : reversed(out_pts_raw);
    in_pts  = ccw ? in_pts_raw  : reversed(in_pts_raw);
    n   = len(out_pts);
    p   = cut_pts(center, out_pts, in_pts);
    ca  = centroid([for (k = [0:n-1]) p[k]]);       // inner cap centre (index 2n)
    cb  = centroid([for (k = [0:n-1]) p[n + k]]);   // outer cap centre (index 2n+1)
    pts = concat(p, [ca, cb]);
    faces = concat(
        // side wall, two triangles per station (clockwise seen from outside)
        [for (k = [0:n-1]) [k, n + k, n + ((k + 1) % n)]],
        [for (k = [0:n-1]) [k, n + ((k + 1) % n), (k + 1) % n]],
        // caps (fans)
        [for (k = [0:n-1]) [2*n, k, (k + 1) % n]],
        [for (k = [0:n-1]) [2*n + 1, n + ((k + 1) % n), n + k]]);
    translate([0, 0, track_dz]) polyhedron(points = pts, faces = faces, convexity = 6);
}

// --- outlines -------------------------------------------------------
// t (mm on the outer reference surface) -> degrees
function t2deg(t) = t / slot_r_out * 180 / PI;
in_scale = slot_half_in / slot_half_out;   // 1.15: cuts are 15% wider (in angle) at the bore

// Main slot: rounded bottom, straight walls, big fillet into a flat top.
w_o  = slot_r_out * slot_half_out * PI / 180;   // 2.007 mm half-width (arc length) at r_out
zc_b = slot_z_bottom + w_o;                // centre of the bottom semicircle
fc   = [w_o - slot_fillet_r, slot_fillet_z];
slot_outline_t = concat(
    [for (a = [180:10:360]) [w_o * cos(a), zc_b + w_o * sin(a)]],   // bottom semicircle
    [[w_o, slot_fillet_z]],                                          // right wall top
    [for (a = [10:10:90]) [fc[0] + slot_fillet_r * cos(a), fc[1] + slot_fillet_r * sin(a)]],
    [[-w_o, slot_z_top]]);                                           // top-left corner
slot_out = [for (p = slot_outline_t) [t2deg(p[0]), p[1]]];
slot_in  = [for (p = slot_out) [p[0] * in_scale, p[1]]];

// Hook / notch at the top-left of the main slot: a wedge with a leaning
// ramp. Vertex order: apex, ramp top, two helper points inside the main
// slot, then the curved lower edge from the slot's left wall back up to
// the apex. Inner (bore) and outer outlines measured separately — the
// ramp leans ~30° through the wall, the lower edge ~2-8°.
notch_out = [[-37.6, 16.85], [-18.5, slot_z_top], [-10, slot_z_top], [-10, 15.0],
             [-20.0, 15.2], [-21.0, 15.4], [-22.9, 15.8], [-24.3, 16.0], [-26.5, 16.2],
             [-29.8, 16.4], [-34.0, 16.6], [-36.8, 16.75]];
notch_in  = [[-46.0, 16.9],  [-21.1, slot_z_top], [-11.5, slot_z_top], [-11.5, 15.0],
             [-22.65, 15.2], [-23.6, 15.4], [-25.2, 15.8], [-26.5, 16.0], [-30.5, 16.2],
             [-35.5, 16.4], [-41.0, 16.6], [-44.5, 16.75]];

// Separate rounded window ("D" shape: flat right wall & top, round left
// end), outline at r_out in degrees about window_angle.
wsc = window_half_out / 19.3;   // scale if someone changes the width
window_out = [for (p = [[19.3, slot_z_top], [19.3, 16.3], [17, 16.15], [13, 15.62], [11, 15.45], [9, 15.37],
              [3, 15.27], [-3, 15.27], [-9, 15.36], [-13, 15.65], [-16, 15.87], [-18, 16.1],
              [-19.3, 16.5], [-19.3, 18.3], [-18, 18.8], [-14, 19.45], [-9, 19.85], [-5, 20.05],
              [-3, 20.15], [3, 20.35], [9, 20.5], [15, slot_z_top]]) [p[0] * wsc, p[1]]];
window_in  = [for (p = window_out) [p[0] * window_half_in / window_half_out, p[1]]];

