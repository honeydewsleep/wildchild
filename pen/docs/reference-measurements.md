# Reference measurements (from the original STL meshes)

Source files (user's Google Drive, *The Rabbit Hole › 3D Print Files ›
Pens › Favorites*): `Bolt Action Pen/Bolt Body.stl`, `Bolt Action
Pen/Bolt Base.stl` (`push.stl` is a byte-identical-size copy of the
base), `Click Pen/Pen Grip.STL.stl`, `Click Pen/Pen Upper Housing.STL.stl`,
`Click Pen/Pen Cap.STL.stl`, `Pen Clip`, `Pen Clicker`, `Pen Spacer`.
Measured by slicing the binary STLs and radial ray-casting (numpy);
nothing was eyeballed. Not committed to the repo (third-party models).

## Bolt Body (reference body)

- Overall 124.3 mm, exterior plain cylinder Ø11.52 (r 5.759), axis at
  mesh (5.759, 5.759). z=0 = open back end, z=124.3 = tip face.
- Back rim: 0.33 mm outer chamfer (r 5.43 at z=0 → 5.76 at z=0.5).
- Bore, back to front:
  - r 4.20 (Ø8.40) z 0 → 53.2 (plunger bore)
  - r 3.44 (Ø6.88) z 53.2 → 113.7 (refill bore)
  - r 2.76 (Ø5.52) z 113.7 → 116.3 (spring seat)
  - cone r 2.76 → 1.86 over z 116.3 → 116.85
  - r 1.86 (Ø3.72) z 116.85 → 121.75 (refill cone bore; ±0.03 barrel)
  - cone r 1.86 → 1.46 over z 121.75 → 121.95
  - r 1.46 (Ø2.92) z 121.95 → 124.3 (exit)
- Original tip: rounded ogive, outer r 5.76 at z 108.5 → 1.53 at 124.3.

### Bolt track (all through the wall; angles about the axis)

Every cut's walls lean: the opening is ~3° per side wider at the bore
(r 4.2) than at the outer surface (r 5.75). Main slot: ±23° at the bore
(3.29 mm), ±20° outside (3.93 mm); the wall passes through Cartesian
(3.875, ±1.645) and (5.404, ±1.967) in the slot's radial frame.

- **Main slot** centred at 270°: bottom (rounded, R≈2) at z 9.51,
  straight walls, right wall leaves into a R≈2.85 fillet at z 17.75 that
  ends on a flat top at z 20.6.
- **Hook / ramp** at the top-left of the main slot: a wedge whose apex
  is at z 17.0, at 233.5° on the outer surface but 223.5° at the bore
  (the ramp face leans ~30° through the wall). Upper edge runs from the
  apex up-right to the slot's left wall at the top (≈250° outer /
  247.8° bore at z 20.5); lower edge runs from the apex down-right to
  the slot's left wall at z 15.9 (250° outer / 247° bore), via
  (238°,16.5) (244°,16.25) (248°,16.0) outer.
- **Window** centred at 194° (76° from the slot): D-shaped, flat right
  wall at 214° (outer) from z 16.3 to 20.6, flat top at 20.6, bottom at
  15.27, fully rounded left end reaching 174° at z 16.4-18.4. Same
  ±20°/±23° wall lean. Not connected to the slot for a Ø2.75 pin: the
  wall between them (214°-234°) is full thickness from z 16.75 to 20.4,
  the gap over the top is only ~0.25 mm. It is reproduced verbatim (a
  clip/service window, most likely).
- Solid body has no other features (no inner grooves) between z 8 and
  z 46.

## Bolt Base (plunger)

- Ø7.62 (r 3.81) × 20.0. 0.5 mm fillets on both outer edges.
- Cross hole Ø2.75, axis perpendicular, centre z 9.475 (edges 8.10-10.85).
- Socket Ø6.00 from the front face, floor at z 11.9 (8.1 deep), 0.5 mm
  chamfer at the mouth (r 3.0 → 3.49).

## Click pen (for the tip shape now, and the grip for v2)

`Pen Grip`: 58 mm long, Ø11 max.

- **Tip taper**: straight cone, outer r 2.126 at z 0.1 → 4.98 at z 10.6:
  slope 0.272 mm/mm = **15.2° half-angle**. Bore r 1.35 at the exit,
  slightly tapered r 1.61→1.99 over z 1.3-7.0, then r 3.25 (Ø6.5).
- **Grip (z 10.6 → 45.5, 35 mm)**: base cylinder r 4.99 (Ø10.0) with a
  **diamond knurl** to r 5.50 (Ø11.0):
  - two helix families (left- and right-hand), **30 grooves each**,
    12° angular pitch; at a fixed angle a groove of one family passes
    every 5.5 mm → helix angle ≈ 11.8° from the axis (lead 165 mm).
    Diamonds are therefore tall and narrow: ~1.15 mm wide × 5.5 mm tall
    (crossing points every 2.75 mm).
  - groove profile: V, 0.5 mm deep (5.50 → 5.00), ~6.5° (0.62 mm) wide
    at the surface, ~5.5° (0.53 mm) flat land between grooves at the
    crest; ~55° included angle.
  - the knurl starts abruptly at z 10.6 (the taper meets the Ø10 base,
    grooves run out into the taper) and ends at z 45.5.
- **Thread** (grip → upper housing): z 45.75-55.75, root r 4.25
  (Ø8.5), crest r 4.63 (Ø9.26), pitch 1.5 mm, ~6.5 turns.
- `Pen Upper Housing`: hexagon **11.0 across flats / 12.7 across
  corners** (sharp corners), 85.5 long; bore r 3.75 at the front, r 4.5
  (Ø9.0) behind; internal click-mechanism ramps z 31-62.
- `Pen Cap`: Ø7.2 × 21.65, bore Ø5.5.

The user's verdict: the knurl grip is the best they have had on a
printed pen (use it in v2); the hex housing at 11 AF is thicker than
they'd like (hence 10.4 AF here); the straight tip is preferred over the
bolt pen's rounded one.
