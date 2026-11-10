# iPad Pro 12.9" / iPad Air 13" back-magnet map (for `scad/misc/ipad129_mount.scad`)

Transcribed from Apple's **Accessory Design Guidelines** dimensional drawings
(developer.apple.com/accessories/dimensional-drawings/):

- `ipad-pro-12.9-inch-6th-generation.pdf`, sheet 3 **MAGNET DETAIL** (vector
  text only, read from 400 dpi renders) and sheet 2 (Smart Connector, camera).
- `ipad-air-13-inch-m2.pdf`, sheet 3 — text-searchable; every labelled
  coordinate that appears on both sheets is identical (HES 1 193.89, compass
  93.12, Pencil column 103.80, BV3 rows 237.18…251.28, BV2 block
  69.79…102.65, …), so the Air 13 (M2/M3) shares this layout. Apple's case
  rules also forbid claiming the 12.9 (5th) and (6th) separately — they are
  one sheet.

Not covered: iPad Pro 13" (M4/M5) — thinner, different outline and layout.

## Frame

Apple draws the magnet sheet as a **front view through the device**:
origin at the centre of the Smart Connector's **middle contact**, +X to the
right, +Y toward the camera edge. The connector is on the device's vertical
centreline, contact centres **12.00 mm** from the overall bottom edge
(10.02 mm to the aluminium enclosure line), pitch **4.97**, pin Ø3.40 in
Ø3.96 openings. Device 280.6 × 214.9, so edges are at X = ±107.45,
Y = −12.0 … 268.6, centre (0, 128.3). Camera bump ≈ 28 × 28 mm centred at
(+88.5, 249.7) in this frame (lenses at X 94.38, Y 115.19/127.21 above
the device centre; flash/mic column at 81.59).

Because the mount's **front face is a mirror of the iPad's back**, this
frame maps onto the mount face **without mirroring**: camera notch top-right,
connector bottom centre. The template is modelled in the same frame and is
flipped over onto the iPad.

Polarity column = Apple's "polarity toward surface of enclosure / closest to
probe", i.e. the pole the iPad shows at its back. A mount magnet must face
the **opposite** pole toward the iPad.

## Clusters

Apple's magnets are ≈ 4.1 mm squares on a 4.7 mm pitch; BVn-11 / BVn-12 are
4 × 12 mm bars. Label = BVc-RC: cluster, column (R), row (C from the
bottom). Bold = positions used by the mount's default `mag_use`.

### BV4 — top-left (camera edge, far from the camera)

| | X −30.91 | X −26.21 | X −21.51 | X −17.21 |
|---|---|---|---|---|
| Y 249.93 (col 5: 249.20) | BV4-24 N | BV4-34 S | BV4-44 S | BV4-54 N |
| Y 245.23 | **BV4-23 S** | BV4-33 N | **BV4-43 N** | BV4-53 S |
| Y 240.53 | BV4-22 S | BV4-32 S | BV4-42 N | BV4-52 S |
| Y 235.83 | **BV4-21 N** | BV4-31 N | **BV4-41 S** | BV4-51 N |

Bars: **BV4-11** (−80.53, 244.43) N, **BV4-12** (−75.43, 244.43) S.

### BV3 — top-right (next to the camera)

Rows Y 237.18 / 241.88 / 246.58 / 251.28.

| col | X | row 1 | row 2 | row 3 | row 4 |
|---|---|---|---|---|---|
| 1 | 28.13 | **BV3-11 S** | BV3-12 N | **BV3-13 S** | BV3-14 N |
| 2 | 32.19 | BV3-21 N | BV3-22 N | BV3-23 S | BV3-24 S |
| 3 | 37.47 | **BV3-31 S** | | | |
| 4 | 42.17 | BV3-41 N | | | |
| 5 | 46.87 | **BV3-51 S** | | | |
| 6 | 51.57 | BV3-61 N | | | |
| 7 | 56.27 | **BV3-71 S** | | | |
| 8 | 61.17 | BV3-81 N | | | |
| 9 | 65.87 | **BV3-91 S** | | | |
| 10 | 70.57 | BV3-10-1 S | BV3-10-2 N | BV3-10-3 S | BV3-10-4 N |

Column 10 is skipped by the mount: it is 2 mm from the camera notch.

### BV1 — bottom-left (connector edge)

| | X −30.84 | X −26.21 | X −21.51 | X −17.21 |
|---|---|---|---|---|
| Y 21.21 | BV1-24 N | BV1-34 S | BV1-44 S | BV1-54 N |
| Y 16.51 | BV1-23 N | BV1-33 N | BV1-43 S | BV1-53 N |
| Y 11.81 | BV1-22 S | BV1-32 S | BV1-42 N | BV1-52 S |
| Y 7.11 | BV1-21 S | BV1-31 N | BV1-41 N | BV1-51 S |

Bars: **BV1-11** (−80.53, 11.64) S, **BV1-12** (−75.43, 11.64) N.
The 4 × 4 grid sits under the charger pill; `charger=false` adds
BV1-21/23/41/43 to the mount.

### BV2 — bottom-right (connector edge)

Rows Y 6.62 / 11.32 / 16.02 / 20.72.

| col | X | row 1 | row 2 | row 3 | row 4 |
|---|---|---|---|---|---|
| 1 | 28.13 | BV2-11 S | BV2-12 N | BV2-13 N | BV2-14 N |
| 2 | 32.19 | BV2-21 N | BV2-22 S | BV2-23 S | BV2-24 S |
| 3 | 36.89 | | | | BV2-34 S |
| 4 | 41.59 | | | | **BV2-44 N** |
| 5 | 46.29 | | | | BV2-54 S |
| 6 | 50.99 | | | | **BV2-64 N** |
| 7 | 55.69 | | | | BV2-74 S |
| 8 | 60.39 | | | | **BV2-84 N** |
| 9 | 65.09 | | | | BV2-94 S |
| 10 | 69.79 | **BV2-10-1 N** | BV2-10-2 S | **BV2-10-3 N** | BV2-10-4 N |
| 11 | 74.45 | BV2-11-1 N | BV2-11-2 S | BV2-11-3 S | BV2-11-4 N |
| 12 | 79.15 | **BV2-12-1 S** | BV2-12-2 N | **BV2-12-3 N** | BV2-12-4 S |
| 13 | 83.85 | BV2-13-1 N | BV2-13-2 S | BV2-13-3 S | BV2-13-4 S |
| 14 | 88.55 | **BV2-14-1 S** | BV2-14-2 N | **BV2-14-3 N** | BV2-14-4 N |
| 15 | 93.25 | BV2-15-1 N | BV2-15-2 S | BV2-15-3 S | BV2-15-4 S |
| 16 | 97.95 | **BV2-16-1 N** | BV2-16-2 N | **BV2-16-3 S** | BV2-16-4 N |
| 17 | 102.65 | — | BV2-17-2 S | BV2-17-3 N | BV2-17-4 S |

Columns 1–2 are under the charger pill (`charger=false` adds BV2-11/13).

### Not used

Edge strips (CV1–9, SP-*, PM-* Pencil magnets, CG1–4, C3M-1–4 under the
camera bump, OR1–4 orientation magnets at the connector edge) and the Hall
sensors (HES 1 at (−89.62, 193.89), HES 2 at (87.54, 244.47)). Keep mount
magnets away from the Hall sensors or the iPad may think a cover closed.

## Selection rule used by the mount

Every other magnet of each cluster (a 9.4 mm lattice) → Ø4.2 pockets with
≥ 5 mm walls, 25 positions with the charger, 31 without. The template-flip
assembly makes polarity automatic, but the parts also carry marks: on the
**mount** a dot beside a pocket means that magnet's **N faces the iPad**; on
the **template** a small hole beside a magnet hole means the **iPad shows N**
there (so the dropped-in magnet lands N-up).
