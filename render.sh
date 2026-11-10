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
    # xvfb-run: OpenSCAD needs a (virtual) display for PNG export
    xvfb-run -a openscad -o "preview/$1.png" -D "$3=\"$4\"" --imgsize=1280,960 \
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
    # matched series (original Energy Ring dimensions)
    stl shell                matched/shell.scad   part shell
    stl shell_threaded       matched/shell.scad   part shell_threaded
    stl shell_free           matched/shell.scad   part shell_free
    stl stem_locknut         matched/stem_locknut.scad part locknut
    stl chassis              matched/chassis.scad part chassis
    stl chassis_bat_cube     matched/chassis.scad part chassis_bat_cube
    stl chassis_bat_flat4    matched/chassis.scad part chassis_bat_flat4
    stl chassis_bat_flat8    matched/chassis.scad part chassis_bat_flat8
    stl ring_double_sided    matched/ring_ds.scad part ring_ds
    stl ring_ds_diffuser     matched/ring_ds.scad part diffuser_ds   # print x2
    stl chassis_jack         matched/chassis.scad part chassis_jack
    # misc: capsule-filling funnel (size 00, socket-over-body spout) + tamper
    stl capsule_funnel_00    misc/capsule_funnel.scad part funnel
    stl capsule_tamper_00    misc/capsule_funnel.scad part tamper
    stl capsule_stand_00     misc/capsule_funnel.scad part stand
    # misc: Katie Bakes cookie cutter + logo embosser
    stl katiebakes_cutter    misc/katiebakes_cutter.scad part cutter
    stl katiebakes_stamp     misc/katiebakes_cutter.scad part stamp
    # misc: 3" round set — face-up stamp, screw-in handles, cutter rings in 3 heights
    stl katiebakes_round_stamp    misc/katiebakes_round.scad part stamp
    stl katiebakes_round_knob     misc/katiebakes_round.scad part knob
    stl katiebakes_round_bar      misc/katiebakes_round.scad part bar
    for h in 9 13 18; do
        echo "== stl/katiebakes_round_ring_$h.stl"
        openscad -o stl/katiebakes_round_ring_$h.stl -D 'part="ring"' -D "ring_h=$h" \
            scad/misc/katiebakes_round.scad 2>&1 \
            | grep -Ev '^(Geometries|Geometry|Compiling|Parsing|Saving|Total|Top|Simple|Vertices|Halfedges|Edges|Halffacets|Facets|Volumes|Rendering|WARNING: Can.t open lib|ECHO)' || true
    done
    python3 scripts/stl2bin.py stl/katiebakes_round_*.stl >/dev/null
    python3 scripts/make_3mf.py 3mf/katiebakes_round_stamp_kit.3mf --cols 2 --title "Katie Bakes stamp kit" \
        stamp=stl/katiebakes_round_stamp.stl knob=stl/katiebakes_round_knob.stl bar=stl/katiebakes_round_bar.stl
    python3 scripts/make_3mf.py 3mf/katiebakes_round_rings.3mf --cols 2 --title "Katie Bakes cutter rings" \
        ring_9=stl/katiebakes_round_ring_9.stl ring_13=stl/katiebakes_round_ring_13.stl ring_18=stl/katiebakes_round_ring_18.stl
    echo "== stl/capsule_funnel_00_insert.stl"
    openscad -o stl/capsule_funnel_00_insert.stl -D 'part="funnel"' -D 'spout="in"' \
        scad/misc/capsule_funnel.scad 2>&1 \
        | grep -Ev '^(Geometries|Geometry|Compiling|Parsing|Saving|Total|Top|Simple|Vertices|Halfedges|Edges|Halffacets|Facets|Volumes|Rendering|WARNING: Can.t open lib|ECHO)' || true
    # capsule kit as one plate-ready 3MF (run stl2bin on the STLs first!)
    python3 scripts/stl2bin.py stl/capsule_*.stl >/dev/null
    mkdir -p 3mf
    python3 scripts/make_3mf.py 3mf/capsule_filler_kit.3mf \
        stand=stl/capsule_stand_00.stl funnel_socket=stl/capsule_funnel_00.stl \
        funnel_insert=stl/capsule_funnel_00_insert.stl tamper=stl/capsule_tamper_00.stl
    # misc: iPad Pro 12.9" / Air 13" magnetic Smart-Connector charging wall mount
    for mh in 3 4; do
        for p in mount mount_bottom mount_top; do
            echo "== stl/ipad129_${p}_4x$mh.stl"
            openscad -o stl/ipad129_${p}_4x$mh.stl -D "part=\"$p\"" -D "mag_h=$mh" \
                scad/misc/ipad129_mount.scad 2>&1 \
                | grep -Ev '^(Geometries|Geometry|Compiling|Parsing|Saving|Total|Top|Simple|Vertices|Halfedges|Edges|Halffacets|Facets|Volumes|Rendering|WARNING: Can.t open lib|ECHO)' || true
        done
    done
    stl ipad129_template          misc/ipad129_mount.scad part template
    stl ipad129_template_bottom   misc/ipad129_mount.scad part template_bottom
    stl ipad129_template_top      misc/ipad129_mount.scad part template_top
    stl ipad129_plug              misc/ipad129_mount.scad part plug
    stl ipad129_chg_test          misc/ipad129_mount.scad part chg_test
    python3 scripts/stl2bin.py stl/ipad129_*.stl >/dev/null
    python3 scripts/make_3mf.py 3mf/ipad129_plate1_mount_bottom.3mf --center 128,128 --title "iPad 12.9 mount - plate 1 (connector half)" mount_bottom=stl/ipad129_mount_bottom_4x3.stl
    python3 scripts/make_3mf.py 3mf/ipad129_plate2_mount_top.3mf --center 128,128 --title "iPad 12.9 mount - plate 2 (camera half)" mount_top=stl/ipad129_mount_top_4x3.stl
    python3 scripts/make_3mf.py 3mf/ipad129_plate3_template_bottom.3mf --center 128,128 --title "iPad 12.9 mount - plate 3 (template, connector half)" template_bottom=stl/ipad129_template_bottom.stl
    python3 scripts/make_3mf.py 3mf/ipad129_plate4_template_top.3mf --center 128,128 --title "iPad 12.9 mount - plate 4 (template, camera half)" template_top=stl/ipad129_template_top.stl
    python3 scripts/make_3mf.py 3mf/ipad129_plugs.3mf --cols 4 --title "iPad 12.9 mount - screw hole plugs" \
        plug1=stl/ipad129_plug.stl plug2=stl/ipad129_plug.stl plug3=stl/ipad129_plug.stl plug4=stl/ipad129_plug.stl \
        plug5=stl/ipad129_plug.stl plug6=stl/ipad129_plug.stl plug7=stl/ipad129_plug.stl plug8=stl/ipad129_plug.stl
    # bottom port window + front button (multi-flag variant)
    echo "== stl/shell_free_port_button.stl"
    openscad -o stl/shell_free_port_button.stl -D 'part="shell_free"' \
        -D 'm_usb_notch=false' -D 'm_port_window=true' \
        -D 'm_button_hole=true' -D 'm_button_angle=90' -D 'm_button_z=26' \
        scad/matched/shell.scad 2>&1 \
        | grep -Ev '^(Geometries|Geometry|Compiling|Parsing|Saving|Total|Top|Simple|Vertices|Halfedges|Edges|Halffacets|Facets|Volumes|Rendering|WARNING: Can.t open lib|ECHO)' || true
fi

if [[ "$mode" == "check" || "$mode" == "all" ]]; then
    echo "== fit check: Katie Bakes stamp/handle thread clearance (must be EMPTY)"
    openscad -o /tmp/fit_kb_thread.stl -D 'part="fit"' scad/misc/katiebakes_round.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    echo "== fit check: iPad 12.9 mount pockets vs back cutters, 4x3 and 4x4 (must be EMPTY)"
    for mh in 3 4; do
        openscad -o /tmp/fit_ipad129_$mh.stl -D 'part="check"' -D "mag_h=$mh" scad/misc/ipad129_mount.scad 2>&1 \
            | grep -iE 'empty|warning|error' || true
    done
    echo "== fit check: clearance (must be EMPTY)"
    openscad -o /tmp/fit_clearance.stl -D 'mode="clearance"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    echo "== fit check: engagement (must be NON-empty)"
    openscad -o /tmp/fit_engagement.stl -D 'mode="engagement"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    echo "== fit check: matched shell/chassis clearance (must be EMPTY)"
    openscad -o /tmp/fit_m_clearance.stl -D 'mode="m_clearance"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    echo "== fit check: matched engagement (must be NON-empty)"
    openscad -o /tmp/fit_m_engagement.stl -D 'mode="m_engagement"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    echo "== fit check: stem thread clearance (must be EMPTY)"
    openscad -o /tmp/fit_s_clearance.stl -D 'mode="s_clearance"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    echo "== fit check: stem thread engagement (must be NON-empty)"
    openscad -o /tmp/fit_s_engagement.stl -D 'mode="s_engagement"' scad/fit_check.scad 2>&1 \
        | grep -iE 'empty|warning|error' || true
    ls -la /tmp/fit_*.stl 2>/dev/null || true
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
