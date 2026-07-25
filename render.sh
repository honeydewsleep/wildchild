#!/usr/bin/env bash
# Render all printable STLs + preview PNGs with OpenSCAD.
# Usage: ./render.sh [stl|png|check|all]   (default: all)
set -euo pipefail
cd "$(dirname "$0")"
mode="${1:-all}"
mkdir -p stl preview

stl() {  # stl <outname> <scadfile> <var> <value>
    echo "== stl/$1.stl"
    openscad -o "stl/$1.stl" -D "$3=\"$4\"" "scad/$2" 2>&1 \
        | grep -Ev '^(Geometries|Geometry|Compiling|Parsing|Saving|Total|Top|Simple|Vertices|Halfedges|Edges|Halffacets|Facets|Volumes|Rendering|WARNING: Can.t open lib|ECHO)' || true
}

png() {  # png <outname> <scadfile> <var> <value> <camera>
    echo "== preview/$1.png"
    openscad -o "preview/$1.png" -D "$3=\"$4\"" --imgsize=1280,960 \
        --camera="$5" --colorscheme=Tomorrow --projection=perspective \
        "scad/$2" >/dev/null 2>&1
}

if [[ "$mode" == "stl" || "$mode" == "all" ]]; then
    stl base                 base.scad        part base
    stl base_wallhole        base.scad        part base_wallhole
    stl thread_test_collar   base.scad        part test_collar
    stl bottom_plate         bottom_plate.scad part plate_notched
    stl bottom_plate_plain   bottom_plate.scad part plate_plain
    stl battery_tub_4aa_cube battery_tub.scad part tub_4aa_cube
    stl battery_tub_4aa_flat battery_tub.scad part tub_4aa_flat
    stl battery_tub_8aa_flat battery_tub.scad part tub_8aa_flat
    stl battery_door_cube    battery_tub.scad part door_cube
    stl battery_door_flat    battery_tub.scad part door_flat
    stl ring_half            ring.scad        part ring_half     # print x2
    stl ring_diffuser        ring.scad        part diffuser      # print x2
fi

if [[ "$mode" == "check" || "$mode" == "all" ]]; then
    echo "== fit check: clearance (must be EMPTY)"
    openscad -o /tmp/fit_clearance.stl -D 'mode="clearance"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    echo "== fit check: engagement (must be NON-empty)"
    openscad -o /tmp/fit_engagement.stl -D 'mode="engagement"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    ls -la /tmp/fit_clearance.stl /tmp/fit_engagement.stl 2>/dev/null || true
fi

if [[ "$mode" == "png" || "$mode" == "all" ]]; then
    png assembly_usb       preview_assembly.scad view usb      "0,0,90,70,0,25,700"
    png assembly_battery   preview_assembly.scad view battery  "0,0,80,70,0,25,780"
    png assembly_cutaway   preview_assembly.scad view cutaway  "0,0,90,90,0,90,650"
    png thread_section     preview_assembly.scad view threads  "0,0,4,90,0,90,280"
    png base               base.scad        part base           "0,0,15,55,0,140,330"
    png bottom_plate       bottom_plate.scad part plate_notched "0,0,8,55,0,140,300"
    png battery_tub_cube   battery_tub.scad part tub_4aa_cube   "0,0,25,55,0,140,340"
    png ring_half          ring.scad        part ring_half      "0,0,10,45,0,30,480"
fi
echo "done."
