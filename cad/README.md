# Joust wand enclosure (organic branch)

Experimental variant: one continuous superellipse body from butt to ball lip,
no visible fasteners, no trigger. The head is held by two 3 mm pins through the
grip's side walls and tabs hanging from the head.

Code-driven CAD for the handheld shell, in OpenSCAD. You never open a modeling
tool: edit numbers in `joust_wand.scad` (or ask Claude to), press F5 in
OpenSCAD to preview, F6 + export for STL.

```bash
# preview images / STLs from the terminal
openscad -D 'view="head"'    -o joust_head.stl    joust_wand.scad
openscad -D 'view="grip"'    -o joust_grip.stl    joust_wand.scad
```

## Parts

| Part | Print orientation | Notes |
|---|---|---|
| head | upside down on its lip, with a brim (or right side up with supports under bosses and tabs) | board pocket, light funnel, ball lip, four pin tabs, USB and power-switch slots |
| grip | butt down | pillars for the board, pin bosses, haptic motor shelf, battery ribs, strap hole |

Hardware: two 40 mm lengths of 3 mm filament or M3 rod, a 40 mm ping-pong
ball, one 2.5 mm zip tie, a 502030 LiPo, and a 12 x 3.4 mm coin ERM haptic
motor (Precision Microdrives 312-101 or a generic "1234" coin, 3 V, ~75 mA)
with a JST PH pigtail.

## Assembly

1. Ball first, while the head is empty. Drill two 3.5 mm holes in the ball,
   20 mm apart, straddling the bottom pole. Feed a zip tie in one hole and out
   the other (it curves along the inside of the shell on its own). Seat the
   ball in the cup, pass both tie ends down into the head, loop under the bar
   across the light chamber, close the tie and pull tight. Trim the tail.
2. Battery between the ribs, wires up.
3. Stick the coin motor into the pocket on the shelf, leads out the +X notch
   to the board's motor connector.
4. Board onto the four pillars, top side up, USB toward the -X face. Plug in
   battery and motor.
5. Head on top: pegs go through the board holes into the pillars, tabs slide
   down inside the grip. Push both pins through the side walls and tabs.
   Trim flush.

## Board assumptions baked into the model

Taken from `layout/Joust/layout.kicad_pcb`. Re-check after a layout re-sync.

- 40 x 40 mm, 10 mm corner radius, four M2 holes at (±13.5, ±13.5).
- USB-C on the -X edge at y = -3.89 (KiCad frame). Power slide switch on the
  +Y edge at x = -1.44, knob toward the edge.
- Antenna keep-out on the -Y edge (KiCad +y). Keep metal away from that face.
- JST PH battery and motor connectors on the bottom, 6 mm tall.
- The WS2812B pixel is not in the layout yet. The light chamber is a 30 mm
  circle centered on the board, so place it within ~12 mm of center, top side.
