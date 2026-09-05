# Joust wand enclosure

Code-driven CAD for the handheld shell, in OpenSCAD. You never open a modeling
tool: edit numbers in `joust_wand.scad` (or ask Claude to), press F5 in
OpenSCAD to preview, F6 + export for STL.

```bash
# preview images / STLs from the terminal
openscad -D 'view="head"'    -o joust_head.stl    joust_wand.scad
openscad -D 'view="grip"'    -o joust_grip.stl    joust_wand.scad
openscad -D 'view="trigger"' -o joust_trigger.stl joust_wand.scad
```

## Parts

| Part | Print orientation | Notes |
|---|---|---|
| head | upside down on its ring, with a brim (or right side up with supports under the four bosses) | board pocket, light funnel, ball cup, USB and power-switch slots |
| grip | butt down | pillars for the board, screw bosses, trigger slot, battery ribs, motor pocket, strap hole |
| trigger | on its side | pivots on a 3 mm pin |

Hardware: 2x M2x8 self-tapping screws, one 40 mm length of 3 mm filament or
M3 rod for the trigger pin, a 6x6x5 mm through-hole tactile switch, a 40 mm
ping-pong ball, one 2.5 mm zip tie, a 502030 LiPo, a 10 mm coin ERM motor.

## Assembly

1. Ball first, while the head is empty. Drill two 3.5 mm holes in the ball,
   20 mm apart, straddling the bottom pole. Feed a zip tie in one hole and out
   the other (it curves along the inside of the shell on its own). Seat the
   ball in the cup, pass both tie ends down into the head, loop under the bar
   across the light chamber, close the tie and pull tight. Trim the tail.
2. Push the tact switch into the pocket on the bridge inside the grip, leads
   out the back. Wire it to the board's button input.
3. Drop the trigger into the grip from the top, paddle out through the slot,
   and push the pin through both side walls.
4. Battery between the ribs, motor in its pocket, wires up.
5. Board onto the four pillars, top side up, USB toward the -X face.
6. Head on top: pegs go through the board holes into the pillars. Two M2
   screws through the head's front and back faces into the grip bosses.

## Board assumptions baked into the model

Taken from `layout/Joust/layout.kicad_pcb`. Re-check after a layout re-sync.

- 40 x 40 mm, 10 mm corner radius, four M2 holes at (±13.5, ±13.5).
- USB-C on the -X edge at y = -3.89 (KiCad frame). Power slide switch on the
  +Y edge at x = -1.44, knob toward the edge.
- Antenna keep-out on the -Y edge (KiCad +y). Keep metal away from that face.
- JST PH battery and motor connectors on the bottom, 6 mm tall.
- The WS2812B pixel is not in the layout yet. The light chamber is a 30 mm
  circle centered on the board, so place it within ~12 mm of center, top side.
