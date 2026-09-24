// =====================================================================
// ESP32 "Cheap Yellow Display" (ESP32-2432S028R) board dimensions.
// Shared by cyd_counter_case.scad and cyd_desk_stand.scad - edit here.
//
// VERIFY with fit_test (cyd_counter_case.scad) before trusting these:
// they come from published drawings, not from calipers on the board.
// Coordinates are from the (-x,-y) PCB corner; USB end faces +x.
// =====================================================================
pcb          = [86.5, 50.0];   // PCB outline
pcb_t        = 1.6;
pcb_holes    = [[3.5, 3.5], [83.0, 3.5], [3.5, 46.5], [83.0, 46.5]];
pcb_hole_d   = 3.0;
glass        = [69.0, 50.0];   // display module footprint
glass_pos    = [0.5, 0];       // module (-x,-y) corner relative to the PCB corner
glass_h      = 4.0;            // PCB top surface -> glass top surface
active       = [57.6, 43.2];   // visible LCD area (2.8" ILI9341)
active_pos   = [6.0, 3.4];     // its (-x,-y) corner relative to the PCB corner
usb_y        = 25.0;           // micro-USB centre along the +x edge, from the -y corner
usb_slot     = [13, 8.5];      // cable slot [width, height]; plug body sits below the PCB
under_pcb    = 9.0;            // minimum clearance under the PCB (ESP32 module, JST plugs)
