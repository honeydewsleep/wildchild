#!/usr/bin/env bash
# Render the pen parts. Usage: ./render.sh [stl|check|png|all]
set -euo pipefail
cd "$(dirname "$0")"
mode="${1:-all}"
mkdir -p stl preview
filt() { grep -Ev '^(Geometries|Geometry|Compiling|Parsing|Saving|Total|Top|Simple|Vertices|Halfedges|Edges|Halffacets|Facets|Volumes|Rendering|ECHO)' || true; }

if [[ "$mode" == "stl" || "$mode" == "all" ]]; then
    echo "== stl/body_hex.stl"; openscad -o stl/body_hex.stl -D 'part="body"' scad/body.scad 2>&1 | filt
    echo "== stl/plunger.stl";  openscad -o stl/plunger.stl scad/plunger.scad 2>&1 | filt
    python3 ../scripts/stl2bin.py stl/*.stl      # OpenSCAD 2021 writes ASCII; commit binary only
fi
if [[ "$mode" == "check" || "$mode" == "all" ]]; then
    for m in clearance pin_clearance pin_engagement; do
        echo "== fit check: $m  (clearance modes must be EMPTY, engagement NON-empty)"
        openscad -o /tmp/pen_fit_$m.stl -D "mode=\"$m\"" scad/fit_check.scad 2>&1 | grep -iE 'empty|warning|error' || true
        ls -la /tmp/pen_fit_$m.stl 2>/dev/null || true
    done
fi
if [[ "$mode" == "png" ]]; then   # previews are NOT part of "all" (cost)
    echo "== preview/*.png"
    xvfb-run -a openscad -o preview/pen_hex.png --imgsize=1600,900 --projection=p --colorscheme=Tomorrow \
        --camera=110,-160,120,0,0,62 -D 'part="body"' scad/body.scad >/dev/null 2>&1
    xvfb-run -a openscad -o preview/pen_hex_track.png --imgsize=1200,900 --projection=p --colorscheme=Tomorrow \
        --camera=-22,-30,32,3,3,16 -D 'part="body"' scad/body.scad >/dev/null 2>&1
fi
