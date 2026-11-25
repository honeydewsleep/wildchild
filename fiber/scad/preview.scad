// Preview helper: half-section views straight from the exported STLs.
which = "stage_fingers";   // stl name, or "assembly"
asm   = "stage_fingers";
LF = 57;
function slen(n) = n == "stage_fingers" ? 116 : n == "stage_grid" ? 150 :
                   n == "stage_baffle" ? 162 : 118;
module halfcut() difference() {
    children();
    translate([-300, -300, -10]) cube([600, 300, 700]);
}
if (which == "assembly") halfcut() {
    color("SteelBlue") import("../stl/funnel.stl", convexity = 10);
    translate([0, 0, LF]) color("Orange")
        import(str("../stl/", asm, ".stl"), convexity = 10);
    translate([0, 0, LF + slen(asm)]) color("Silver")
        import("../stl/base.stl", convexity = 10);
} else halfcut() color("Orange") import(str("../stl/", which, ".stl"), convexity = 10);
