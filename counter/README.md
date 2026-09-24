# Pillow Blower Counter

A per-machine counting station for the pillow blowers, built on the
ESP32 "Cheap Yellow Display" (CYD, ESP32-2432S028R: 2.8" 320×240 touch
screen, WiFi, about $10). Each device logs who is running the blower,
which pillow type they are making, every pillow counted (and un-counted),
defective skins, and batch start/finish. Events go over WiFi to a Google
Sheet through a small Apps Script, and the same script serves a wall
dashboard for the manager's desk.

```
 blower 1 ──┐                                        ┌── wall TV (Dashboard.html)
 blower 2 ──┼─ CYD counters ─ WiFi ─▶ Apps Script ─▶ Google Sheet ─┤
 blower 3 ──┘   (firmware/)            (backend/)     Events/Batches/Live/Config
                                                      └── Config tab: names, pillow types,
                                                          daily target, "make next" list
```

| Folder | What |
|---|---|
| `firmware/` | PlatformIO project for the CYD. Touch UI + panel buttons, offline queue, batch state that survives power loss. |
| `backend/` | `Code.gs` (Apps Script: ingest, config, dashboard data) and `Dashboard.html` (the wall display). |
| `enclosure/` | Parametric OpenSCAD case with a row of glove-friendly buttons under the screen; rendered STLs in `enclosure/stl/`. |

## How a worker uses it

Three panel buttons: **green +**, **red −**, **black** (start / confirm /
finish). Everything also works on the touch screen, which is resistive
and responds through gloves.

1. **Start a batch** – press black (or tap START BATCH). The screen asks
   *Who is running?* then *Which pillow?*: green/red move the highlight,
   black confirms, holding black goes back. Or just tap a tile.
2. **Count** – green for each finished pillow, red undoes one. Holding
   black (or tapping DEFECT) logs a bad skin without changing the count.
3. **Finish** – press black; the FINISH button turns yellow and a second
   press within 4 s ends the batch, so a stray press can't end one. A
   summary shows count, defects and minutes; black or green returns to Idle.

A latching switch can replace the black button (`BTN_BATCH_LATCHING
true`): ON starts a batch, OFF finishes it, no confirmation needed.

Everything is logged the moment it happens. If WiFi is down the device
keeps counting, shows `OFFLINE n` in the header, and uploads the backlog
(in order, with original timestamps) when the link returns. A power cut
mid-batch resumes on the next boot with the same operator, type and count.
The on-board RGB LED blinks green per +, red per −, and stays red when
there is an unsent backlog.

## Bill of materials (per station)

- ESP32-2432S028R "Cheap Yellow Display" 2.8" (ILI9341). The newer
  "2 USB" boards use an ST7789 panel: same firmware, different build env.
- 3× momentary panel buttons, 12 mm: green (+), red (−), black (start /
  confirm / finish). Other sizes: change `buttons` in the SCAD.
- Optional 4th momentary button (DEFECT) – needs a free pin, see below.
- 1× 10 kΩ resistor (pull-up for the input-only pin the BATCH switch uses).
- 2× 4-pin 1.25 mm JST pigtails (the CYD ships with them) for CN1 and P3.
- 5 V USB power supply + micro-USB cable (right-angle plugs are handy).
- 8× M3×8 self-tapping screws (or M3 heat-set inserts + machine screws).
- Printed `box.stl` + `bezel.stl`; print `fit_test.stl` first.

Shared: one Google account for the Sheet, and any browser on the wall
TV (a Chromecast/Fire stick/old laptop in kiosk mode pointing at the web-app URL).

## Wiring

Diagram: `docs/wiring.html` (open in a browser). All buttons wire between the GPIO and GND (active-low; internal pull-ups
are used where the ESP32 has them).

| Function | GPIO | Where on the CYD | Notes |
|---|---|---|---|
| Green (+) | 22 | CN1 connector (GND, IO22, IO27, 3V3) | internal pull-up |
| Red (−) | 27 | CN1 | internal pull-up; hold at power-on = setup portal |
| Black (start / confirm / finish) | 35 | P3 connector (GND, IO35, IO22, IO21) | **input-only, no internal pull-up: add 10 kΩ from IO35 to 3V3** |
| DEFECT (optional) | – | – | set `PIN_BTN_DEFECT` – see "free pins" |
| Backlight | 21 | P3 | do not use, it drives the screen backlight |

**Free pins for later.** The TF-card slot pins (GPIO 5, 18, 19, 23) are
unused if no SD card is fitted; a micro-SD breakout board plugged into
the slot brings them out cleanly. That is the home for a DEFECT button
and the vibration sensor. GPIO 34 has the light sensor, 26 the speaker,
4/16/17 the RGB LED.

Pin numbers are all in `firmware/include/config.h`; `-1` disables a button.

## Setup

### 1. Google Sheet + Apps Script (10 minutes)

1. Create a new Google Sheet (e.g. "Pillow Counter").
2. Extensions → Apps Script. Replace `Code.gs` with `backend/Code.gs`,
   add an HTML file named `Dashboard` with the contents of
   `backend/Dashboard.html`. Project settings → tick *Show appsscript.json*
   and replace it with `backend/appsscript.json` (sets the time zone – edit it).
3. In `Code.gs` set `API_KEY` to a long random string.
4. Run `setup()` once (authorise when asked). It creates the tabs:
   `Events`, `Batches`, `Live`, `Config`.
5. Fill the `Config` tab: operator names in column A, pillow types in
   B, station ids/names in C/D (`blower-1` / `Blower 1`), daily target in
   F2, and optionally a "make next" list in G (see Roadmap).
6. Deploy → New deployment → Web app, *Execute as: Me*, *Who has access:
   Anyone*. Copy the `/exec` URL – that is `SHEET_URL` for the devices
   and the address for the wall TV.

Re-deploy (Manage deployments → edit → new version) after changing the script.

Devices pick up new names/types within 10 minutes without reflashing.
`archiveOldEvents()` can be put on a monthly time-driven trigger to keep
the Events tab fast (it moves rows older than 60 days to `Events_Archive`).

### 2. Firmware

**Easiest: flash from a browser, no toolchain.** Each release build is a
single image (`counter/firmware/dist/pillow-counter-cyd.bin`, or the
`-st7789` one for the newer 2-USB boards). In Chrome or Edge:

1. Plug the CYD into USB. Open https://espressif.github.io/esptool-js/
2. *Connect*, pick the board's serial port (on Windows the CH340 driver
   may be needed first), set the flash address to `0x0`, choose the
   `.bin`, *Program*. Takes about a minute. Press the board's RST button.
3. On first boot the screen goes to **SETUP MODE**: on a phone join the
   WiFi hotspot `PillowCounter-blower-1`, a page opens (or browse to
   `192.168.4.1`), pick your WiFi and type the Apps Script URL, the API
   key, the station id (`blower-2`, …) and its display name. Save.

The device remembers all of that. To change it later, hold the **−**
button (or the screen) while powering on. If the panel shows inverted
colours you have the ST7789 variant: flash the other image.

**From source** (needed to change pins, timing or the UI):

```bash
cd counter/firmware
cp include/config.h.example include/config.h   # optional: compile-in WiFi/URL defaults, pins
pio run -e cyd -t upload          # original CYD (ILI9341)
pio run -e cyd_st7789 -t upload   # newer 2-USB boards
pio device monitor -b 115200
```

`./merge_bin.sh` rebuilds both single-file images into `dist/`.
Touch mapping constants live in `include/pins.h`; build with
`-D SERIAL_TOUCH_DEBUG` to print raw touch coordinates if taps land off.
The device talks to Google over TLS with certificate checking disabled
(`setInsecure()`), the usual trade-off on ESP32 for Google's rotating
certificate chain; the shared `API_KEY` is what gates writes.

### 3. Enclosure

```bash
cd counter/enclosure
openscad -o stl/fit_test.stl -D 'part="fit_test"' cyd_counter_case.scad
openscad -o stl/box.stl      -D 'part="box"'      cyd_counter_case.scad
openscad -o stl/bezel.stl    -D 'part="bezel"'    cyd_counter_case.scad
python3 ../../scripts/stl2bin.py stl/*.stl
```

**Print `fit_test.stl` first** (15 minutes). Lay it on the CYD: the four
holes should line up with the PCB holes, the window should frame the
visible LCD, and your buttons should drop into the holes in the strip.
The board dimensions in the SCAD (`pcb_holes`, `active_pos`, `usb_y`,
`glass_h`) come from published drawings, not from calipers on this
board revision – adjust and re-render before printing the box.

- `box.stl` prints as-is (open side up), no supports. ~94 × 106 × 25 mm.
  Four standoffs take the PCB (M3 self-tapping into Ø2.6 holes, or just
  rest it on them); four corner posts take the bezel screws. USB cable
  exits the right wall; a Ø6.5 grommet hole on the left wall is for a
  future sensor cable. Back face: two keyholes (60 mm apart) and four
  zip-tie slots for strapping to a frame tube.
- `bezel.stl` prints face-down (already flipped in the STL). Screen
  window with a chamfer, three button holes (12.3 / 12.3 / 16.3 mm) with
  recessed **+ − BATCH** labels, countersunk M3 holes. A strip of 1 mm
  foam tape around the window on the inside stops the glass rattling.
- Everything is parametric: `buttons` (labels + hole sizes),
  `btn_body_depth` (box depth), `keyholes`, `zip_slots`, `aux_hole_d`,
  `post_hole_d` (4.0 for heat-set inserts).

Mounting on a vibrating machine: use the keyholes with rubber washers, or
zip-tie to a guard/handle, and route the USB cable with strain relief.

#### Desk stand variant (`cyd_desk_stand.scad`)

A remix of the common "32° CYD desk stand" for stations that sit on a
bench: same 32° screen tilt and flush front panel in a pocket, but the top
runs straight back (horizontal) and carries **three 16 mm chassis-mount
buttons facing up**, so an operator in gloves can hit them from above.
The top depth is derived from the button nut and the board envelope, so
it grows or shrinks with `btn_nut_d` / `btn_body_d` / `under_pcb`.
Footprint ~107 × 75 × 62 mm.

```bash
cd counter/enclosure
openscad -o stl/desk_stand_btn_test.stl -D 'part="btn_test"' cyd_desk_stand.scad
openscad -o stl/desk_stand_base.stl     -D 'part="base"'     cyd_desk_stand.scad
openscad -o stl/desk_stand_bezel.stl    -D 'part="bezel"'    cyd_desk_stand.scad
python3 ../../scripts/stl2bin.py stl/desk_stand_*.stl
```

- `desk_stand_btn_test.stl` – 30 mm square with one 16.3 mm hole on the
  3.2 mm top thickness: check your buttons and nuts on it first.
- `desk_stand_base.stl` prints as modelled (floor down), no supports; the
  flat top is a ~40 mm bridge. Bezel pocket with an opening for the
  board behind it, four Ø6.5 screw bosses at the panel corners, USB slot
  in the right wall (`usb_side = -1` for the left), optional `aux_hole_d`
  grommet in the back.
- `desk_stand_bezel.stl` prints face-down (already flipped). 104 × 58.4 mm
  plate, chamfered window, four Ø6 posts behind the PCB holes with blind
  Ø2.6 holes: screw the CYD to the bezel **from behind** (4× M3×6
  self-tapping), then drop the pair into the pocket and fix it with 4×
  M3×10 countersunk into the base bosses.
- Buttons: drop through the top, nut inside (reach in through the front
  opening before the bezel goes on). Labels **+ − BATCH** are engraved
  in front of the holes. The same firmware pins apply as for the wall
  case; the BATCH button can be latching or momentary.
- `check_buttons` / `check_bosses` parts are boolean interference checks
  (button bodies and screw bosses against the board envelope) and must
  render empty.

#### Desk stand v2 - the "CYD Desk Buddy" with a flat button top (`cyd_desk_stand_v2.scad`)

The second variant keeps the original **CYD Desk Buddy** base (MakerWorld
model 2787810, 32° / symmetrical-bezel variant, files in `enclosure/src/`)
exactly as downloaded - centred screen, symmetrical bezel, no screws or
cable openings on the front or sides, hidden screws along the screen's
tilt axis, rounded corners - and grafts a flat-topped rear section onto
it so three 16 mm chassis-mount buttons can face up. The SCAD imports the
source mesh; only the sloped top wall is removed. **Use the supplied
Front Panel STL unchanged.** No labels on the buttons.

```bash
cd counter/enclosure
openscad -o stl/desk_stand_v2_base.stl     -D 'part="base"'     cyd_desk_stand_v2.scad   # ~1 min
openscad -o stl/desk_stand_v2_btn_test.stl -D 'part="btn_test"' cyd_desk_stand_v2.scad
openscad -o stl/desk_stand_v2_panel.stl    -D 'part="panel"'    cyd_desk_stand_v2.scad   # source panel, as-is
openscad -o stl/desk_stand_v2_panel_slim.stl -D 'part="panel_slim"' cyd_desk_stand_v2.scad   # -0.2 mm per edge
python3 ../../scripts/stl2bin.py stl/desk_stand_v2_*.stl
```

- Same footprint width and height as the original (102.8 × 62 mm); depth
  grows from 45 to 71 mm. The top runs flat from the original top-front
  edge back to a new vertical back wall. The rear section is extruded
  from the original body's own cross-section, so its 6.2 mm side fillets
  continue straight through and wrap round the new back edges at the
  same radius.
- Buttons: three 16.3 mm holes on a 30 mm pitch, 2.4 mm top, nuts inside.
  They sit in a rear compartment behind the original back wall, which is
  cut down to two pads (carrying its countersunk screw holes) and a
  bottom strip, so the compartment is open to the front through the
  bezel opening. It has its own 2 mm floor (`rear_floor = false` for an
  open underside). Fit the nuts before the bezel goes on.
- Hidden screws: unchanged from the original, **4× M2.5 × 10 mm pan or
  socket head** (thread-forming into the panel's Ø2.1 post holes; a
  plain M2.5 machine screw cuts its own thread in PLA). Measured on the
  mesh: each screw seats on a shoulder inside a Ø6.4 counterbore, passes
  a 5.5 mm Ø3.2 bore through the boss and the 1.6 mm PCB, then gets
  3.3 mm of bite in the 4 mm deep post hole - 12 mm would bottom out on
  the plate, 8 mm bites only 1.3 mm. Head must be under Ø6.4. Two come
  up through the floor slots (the shoulder is 22 mm up the bore: use a
  long driver, magnetic tip). The two that entered through the old back
  wall now go in through Ø7 access holes in the new back wall on the
  same axes, seating 9 mm inside the partition. The source's screw
  pattern is offset 2.9 mm to the right like its PCB, so the two access
  holes are not symmetric - that is correct.
- USB-C: the original 13.6 × 5.5 mm panel-mount slot is repeated in the
  new back wall; the cable and the button wires simply pass through the
  open partition (its original bottom slot is still there too).
- Magnets: four press-fit cups for 8 × 2 mm discs, a full 4.2 mm of
  straight Ø8.15 bore with a 0.4 mm lead-in flare above it, **opening
  upward** from the floor over a 1 mm skin, so the magnets are hidden and
  the bottom face stays closed (stack two, or push one to the bottom).
  Two in the front section between the screw slots, two on the rear
  floor 18 mm either side of centre just behind the partition's bottom
  strip - inside its window, so all four are pressed in through the
  bezel opening before the buttons go in. `magnets = false` to omit;
  `magnet_d` / `magnet_depth` / `magnet_skin` / `magnet_flare` /
  `magnet_pos`.
- Front panel: `desk_stand_v2_panel.stl` is the source Front Panel
  re-exported (identical, face down). The pocket is 100.4 × 58.8 mm and
  the panel 100 × 58.4, only 0.2 mm a side, so a slightly fat print will
  not drop in. `desk_stand_v2_panel_slim.stl` is the same panel with 0.2
  mm shaved off each outer edge (99.6 × 58.0; window, posts and holes
  untouched) for prints that come out tight - `panel_trim` sets it.
- Prints floor down without supports, like the original.
- The source model is MakerWorld's; check its licence before sharing
  these derived files outside this private repo.

## Data model (the Sheet)

- **Events** – one row per action: server time, device time, station,
  operator, pillow type, event (`batch_start`, `add`, `sub`, `defect`,
  `batch_end`), delta (+1/−1), running count, defects, batch id, sequence.
  This is the raw truth; everything else derives from it.
- **Batches** – one row per finished batch with duration and pillows/hour.
- **Live** – one row per station, rewritten on every heartbeat (30 s):
  what is being made right now and by whom. The dashboard marks a
  station *offline* after 3 minutes of silence.
- **Config** – operators, pillow types, stations, daily target, suggested types.

Duplicate uploads (device missed our reply) are dropped by sequence number.

## Dashboard

`Dashboard.html` polls every 15 s and shows: pillows today against the
daily target, batches finished, defects, blowers running; a card per
blower (operator, type, count in this batch, elapsed, rate, defects); pillows
per operator today; pillows by type today; production by hour; last 7
days; recent batches. It is dark by default for a wall TV; add
`data-theme="light"` on the `<html>` tag for a light version. Open the
file locally and it renders with demo data.

`?action=dashboard` on the web-app URL returns the same numbers as JSON
if you ever want a different front end (Looker Studio, Home Assistant, etc.).

## Roadmap

Already supported by the code, no rework needed:

- **Pillow type per batch** – the picker after the operator screen.
- **Defect logging** – DEFECT touch button now; a physical button by
  setting `PIN_BTN_DEFECT`.
- **"Make this next" guidance** – put pillow types in `Config!G`
  (most urgent first) and every device shows them at the top of the
  picker within 10 minutes. The natural next step is a scheduled script
  that fills column G from Luminous (sales velocity, forecast, stock on
  hand) instead of a person typing it, and the dashboard showing the
  same list as a "make next" panel.

Later:

- **Per-batch targets / work orders** – pull open Luminous work orders
  into the picker so a batch is tied to an order, and post the finished
  count back.
- **Operator badges** – a cheap RC522 RFID reader on the free SPI pins
  so workers tap a badge instead of picking a name.

## Vibration sensing: can we automate the count?

Yes, there are three sensor classes, and only one is worth putting on the
machine:

1. **SW-420 / tilt-ball "vibration switches"** ($1) – give a binary
   pulse when shaken past a fixed threshold. On a blower that vibrates
   continuously they are on all the time; no pattern to learn. Skip.
2. **Piezo discs** ($1) – an analog voltage proportional to vibration
   through one axis. Cheap and works with the ESP32 ADC, but noisy,
   needs a bias circuit, and the signal depends on how it is stuck on.
   Fine for a quick experiment.
3. **MEMS accelerometer** (LIS3DH, ADXL345 or MPU-6050 breakout, $3–5)
   – the right tool. Three axes, ±2–16 g, sampled at 400–1000 Hz over
   I²C, with the sensor rigidly bolted to the blower frame near the
   motor. This is exactly what industrial machine-monitoring uses.

**Recommended:** an LIS3DH or MPU-6050 on I²C. The CYD's I²C pins are
GPIO 22/27 – the same CN1 pins the +/− buttons use in v1 – so when the
sensor goes on, move the buttons to the TF-card pins (5/18/19/23) via a
micro-SD breakout, or hang a PCF8574 I²C port expander on the same bus
for all the buttons. The Ø6.5 hole in the box's left wall is for the
sensor cable.

**What to log.** Do not stream raw samples to the Sheet (a day at 1 kHz
is 86 million rows). The device computes features once per second –
RMS acceleration per axis, peak, and energy in a few frequency bands
from a small FFT – and stores them locally (SD card, or a `features`
file), with the manual `add` events as labels. After a few weeks you
have a labelled dataset: what does "finishing a pillow, reaching for the
next skin" look like versus steady blowing. Most likely the signature is
a short dip in motor load between pillows, which is visible as a change
in the dominant frequency and RMS. The first version of automation is a
simple rule (dip longer than X ms after at least Y seconds of blowing =
one pillow) with the +/− buttons kept as correction; only if the rule is
not reliable is it worth training a small classifier and running it on
the ESP32.

A less glamorous but very robust alternative for automation is a **current
clamp (SCT-013) on the blower motor lead**: motor current tracks load
directly and is far cleaner than vibration. Worth trying side by side.

## Development notes

- Firmware builds clean with PlatformIO (`espressif32@6.7.0`, TFT_eSPI
  2.5.43, ArduinoJson 7). Touch uses PaulStoffregen's XPT2046 library on
  its own SPI bus, as the CYD requires.
- The UI, uplink task and persistence are separate files
  (`ui.cpp`, `uplink.cpp`, `state.cpp`) so the screen never waits on the
  network; the uplink task runs on core 0.
- Hardware validation still to do on a real board: touch calibration,
  the enclosure dimensions (hence `fit_test`), and confirming which
  panel driver your CYD batch has.
