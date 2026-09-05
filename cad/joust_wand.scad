// Joust wand — PlayStation-Move-style handheld shell for the Joust PCB.
//
// Coordinate frame: Z is the wand axis (ball is +Z). Origin is the center of
// the PCB's TOP surface. X/Y match the KiCad board frame except Y is flipped
// (Y_here = -Y_kicad), so looking down from the ball you see the board as in
// the KiCad editor.
//
// Parts:  head     — board pocket, light chamber, ping-pong ball socket
//         grip     — handle, battery ribs, motor pocket, trigger mechanism
//         trigger  — lever, pivots on a 3 mm pin through the grip walls
//
// Board orientation inside the wand:
//   -X face : USB-C receptacle (charging slot)
//   +Y face : power slide switch (slot)
//   -Y face : BLE module antenna edge (keep metal away) — trigger side below
//   bottom  : JST PH battery + motor connectors face down into the grip
//
// Print: head upside-down on its ring with a brim (or right-side up with supports
// under the four bosses), grip butt-down, trigger on its side. Hardware: 2x M2x8 self-tapping screws, 1x 3 mm pin 40 mm long
// (filament or M3 shaft), 6x6x5 THT tactile switch, ping-pong ball, one 2.5 mm zip tie.
//
// Set `view` below or from the CLI:  openscad -D 'view="head"' -o head.stl joust_wand.scad

view = "assembly";   // assembly | exploded | section | head | grip | trigger
$fn = (view == "head" || view == "grip" || view == "trigger") ? 96 : 48;

// ---------------------------------------------------------------- board ----
board_w   = 40;      // square, mm
board_r   = 10;      // corner radius
board_t   = 1.6;
board_clr = 0.3;     // per side
hole_d    = 2.2;     // M2 mounting holes
// (x, y) of the four mounting holes, KiCad y flipped
holes = [[-13.45, 13.95], [13.62, 13.95], [13.62, -13.08], [-13.45, -13.08]];

// key components (from layout.kicad_pcb)
usb_y      =  3.89;  // USB-C receptacle center along the -X edge
usb_h      =  3.2;   // receptacle height above board
sw_x       = -1.44;  // slide switch center along the +Y edge
jst_h      =  6.0;   // JST PH vertical, hangs below the board
top_comp_h =  4.0;   // tallest top-side part (switch knob / USB)

// ------------------------------------------------------------ envelope ----
wall     = 2.7;
head_w   = board_w + 2*board_clr + 2*wall;   // 46.0
head_r   = board_r + board_clr + wall;       // 13.0
pocket_w = board_w + 2*board_clr;            // 40.6
pocket_r = board_r + board_clr;              // 10.3
corner_c = pocket_w/2 - pocket_r;            // 10.0 — pocket corner arc centers at (±c, ±c)

// ------------------------------------------------------------ Z levels ----
z_joint      = -10;                   // head/grip joint plane
z_funnel0    = top_comp_h + 0.5;      // ceiling above components starts
chamber_d    = 30;                    // light chamber diameter
z_funnel1    = z_funnel0 + (pocket_w/2 - chamber_d/2);  // 45° funnel top
ball_d       = 40;                    // ping-pong ball
ball_clr     = 0.25;
ball_r       = ball_d/2 + ball_clr;
z_ball       = 32.0;                  // ball center
rim_below    = 11;                    // cup rim this far below the ball center (~77% of ball exposed)
z_head_top   = z_ball - rim_below;
rim_r        = sqrt(ball_r*ball_r - rim_below*rim_below);   // cup opening radius (17.0)
lip_t        = 0.7;                   // thickness of the lip where it meets the ball
z_shoulder   = 6;                     // square head starts necking down here
// ball retention: zip tie through two holes in the ball, looped around a bar in the chamber
tie_hole_r   = 10;                    // ball holes at ±10 mm (X) from the axis, on the underside
tie_hole_d   = 3.5;
bar_z        = 8;                     // bar center height (funnel zone, clears 4 mm components)
bar_d        = 3;

// grip profile stations: [z, width_x, width_y, corner_r]
grip_profile = [
  [z_joint,  head_w, head_w, head_r],
  [-40,      38,     36,     13],
  [-120,     36,     33,     12],
  [-138,     42,     38,     14],
  [-146,     36,     32,     12],
  [-148,     30,     26,     10],
];
grip_wall  = 2.4;
z_floor    = -140;                    // cavity floor
z_web      = -16;                     // internal features below the joint attach down to here

// ------------------------------------------------------------- trigger ----
trig_x_w     = 14;                    // slot width (X)
lever_w      = 12;                    // paddle width (X)
pivot        = [-15.0, -20];          // [y, z] of pivot axis (axis runs along X)
pin_d        = 3.0;                   // 3 mm filament or M3 shaft
pin_len      = 39.5;                  // flush with the outer skin at the pivot
slot_z       = [-47, -22];            // slot extent in the -Y wall
paddle_top   = [-16.5, -23];
paddle_tip   = [-24.0, -42];
paddle_t     = 3.2;
// tactile switch cradle (6x6x5 THT tact switch, button facing -Y toward paddle)
bridge_z     = -32;
bridge_h     = 6.5;
bridge_y     = [-11, -3];             // -Y face to +Y face of the bridge
tact_body    = 6.2;                   // pocket size
tact_depth   = 3.5;
tact_btn_y   = bridge_y[0] - (5 - tact_depth) - 1.0;   // button face at rest
nub_gap      = 0.5;

// --------------------------------------------------------------- misc -----
screw_x      = 6;                     // grip screws at (∓6, ±Y)
screw_z      = z_joint + 3.5;
screw_pilot  = 1.7;                   // M2 self-tapping into printed boss
screw_clr    = 2.3;
batt         = [21, 6.5, 33];         // 502030 LiPo w/ PCM: X, Y(thick), Z
motor_d      = 10.6; motor_t = 3.6;   // coin ERM pocket

// ============================================================ helpers =====
module rr(w, h, r) {
  if (w - 2*r < 0.01 || h - 2*r < 0.01) scale([w, h]) circle(d=1);   // fully round station
  else offset(r) square([w-2*r, h-2*r], center=true);
}

module slab(p, inset=0) {
  translate([0,0,p[0]]) linear_extrude(0.01)
    rr(p[1]-2*inset, p[2]-2*inset, max(0.5, p[3]-inset));
}

module lofted(profile, inset=0) {
  for (i = [0 : len(profile)-2])
    hull() { slab(profile[i], inset); slab(profile[i+1], inset); }
}

// slot along X: length l, height w (Z), depth h (Y)
module rounded_slot(l, w, h) {
  hull() for (s=[-1,1]) translate([s*(l-w)/2, 0, 0]) rotate([90,0,0]) cylinder(d=w, h=h, center=true);
}

module board_outline(inset=0) { rr(board_w-2*inset, board_w-2*inset, board_r-inset); }

function sgn(v) = v < 0 ? -1 : 1;
// point on the diagonal through a pocket corner, at distance `d` from that corner's arc center
function corner_pt(h, d) = [sgn(h[0])*(corner_c + d/sqrt(2)), sgn(h[1])*(corner_c + d/sqrt(2))];

// ============================================================== HEAD ======
// outer skin: straight square below the board, then one continuous curve that
// necks down and rounds off, meeting the ball as a thin lip (~0.7 mm)
function head_outer_profile() = concat(
  [[z_joint, head_w, head_w, head_r], [z_shoulder, head_w, head_w, head_r]],
  [for (i = [1:12]) let(t = i/12, sm = pow(t, 1.5),
       z = z_shoulder + t*(z_head_top - z_shoulder),
       h = head_w/2 + sm*((rim_r + lip_t) - head_w/2),
       r = head_r   + sm*((rim_r + lip_t) - head_r)) [z, 2*h, 2*h, r]]
);

module head() {
  difference() {
    lofted(head_outer_profile());

    // --- board pocket: joint zone + board + component clearance
    translate([0,0,z_joint-1]) linear_extrude(z_funnel0 - z_joint + 1) rr(pocket_w, pocket_w, pocket_r);
    // --- 45° funnel up to the light chamber (doubles as a reflector)
    hull() {
      translate([0,0,z_funnel0-0.01]) linear_extrude(0.01) rr(pocket_w, pocket_w, pocket_r);
      translate([0,0,z_funnel1]) cylinder(d=chamber_d, h=0.01);
    }
    // --- light chamber
    translate([0,0,z_funnel1-0.01]) cylinder(d=chamber_d, h=z_ball - z_funnel1 + 0.02);
    // --- ball socket
    translate([0,0,z_ball]) sphere(r=ball_r);

    // --- USB-C slot on the -X face (fits a plug overmold)
    translate([-head_w/2, usb_y, usb_h/2]) rotate([0,0,90]) rounded_slot(13, 7, wall*3);
    // receptacle sticks ~1 mm past the board edge: relief in the wall
    translate([-pocket_w/2 - 1.5, usb_y - 5.5, -0.3]) cube([1.6, 11, usb_h + 0.6]);

    // --- power slide switch slot on the +Y face
    translate([sw_x, head_w/2, 3.0]) rounded_slot(10, 3.5, wall*3);
    translate([sw_x - 5, pocket_w/2 - 0.1, -0.3]) cube([10, 1.6, 4.8]);

    // --- screws for the grip: through the ±Y walls into the grip bosses
    for (s=[-1,1]) translate([-s*screw_x, s*head_w/2, screw_z]) rotate([s*90,0,0]) {
      cylinder(d=screw_clr, h=wall*2 + 2, center=true);
      cylinder(d1=4.4, d2=screw_clr, h=1.4);   // countersink on the outside face
    }
  }
  // --- hold-down bosses over the mounting holes, with pegs through the board
  for (h = holes) translate([h[0], h[1], 0]) {
    cylinder(d=4.0, h=z_funnel1 + 2);
    translate([0,0,-(board_t + 0.9)]) cylinder(d=1.8, h=board_t + 1.0);
  }
  // --- zip tie bar across the light funnel (tie loops under it, up through the ball)
  intersection() {
    translate([0,0,bar_z]) rotate([90,0,0]) cylinder(d=bar_d, h=head_w, center=true);
    lofted(head_outer_profile());
  }
}

// ============================================================== GRIP ======
module grip_body()   { lofted(grip_profile); }
module grip_cavity() {
  // pocket-sized at the joint so the JST plugs fit, then normal wall
  cav = [
    [z_joint + 1, pocket_w, pocket_w, pocket_r],
    [z_web,       pocket_w, pocket_w, pocket_r],
    [-40,         38 - 2*grip_wall, 36 - 2*grip_wall, 13 - grip_wall],
    [-120,        36 - 2*grip_wall, 33 - 2*grip_wall, 12 - grip_wall],
    [z_floor,     34 - 2*grip_wall, 31 - 2*grip_wall, 11 - grip_wall],
  ];
  lofted(cav);
}

module pillar(h) {
  // board support pillar + fin to the pocket corner; below the joint a web runs into the wall
  hull() {
    translate([h[0], h[1], z_web]) cylinder(d=3.6, h=(-board_t) - z_web);
    translate([corner_pt(h, pocket_r - 2.0)[0], corner_pt(h, pocket_r - 2.0)[1], z_web]) cylinder(d=3.6, h=(-board_t) - z_web);
  }
  hull() {
    translate([corner_pt(h, pocket_r - 2.0)[0], corner_pt(h, pocket_r - 2.0)[1], z_web]) cylinder(d=3.6, h=z_joint - 0.2 - z_web);
    translate([corner_pt(h, pocket_r + 1.5)[0], corner_pt(h, pocket_r + 1.5)[1], z_web]) cylinder(d=3.6, h=z_joint - 0.2 - z_web);
  }
}

module screw_boss(s) {
  // above the joint: inside the pocket (0.25 clr); below: merges into the wall
  y0 = 14.5; y1 = pocket_w/2 - 0.25;
  translate([-s*screw_x - 5, 0, 0]) {
    translate([0, min(s*y0, s*y1), z_web]) cube([10, abs(y1-y0), -4 - z_web]);
    translate([0, min(s*y0, s*(y1+2)), z_web]) cube([10, abs(y1+2-y0), z_joint - 0.2 - z_web]);
  }
}

module grip() {
  difference() {
    union() {
      difference() { grip_body(); grip_cavity(); }
      for (h = holes) pillar(h);
      for (s=[-1,1]) screw_boss(s);

      // --- trigger switch bridge (spans wall to wall, tact switch pocket faces -Y)
      translate([0, (bridge_y[0]+bridge_y[1])/2, bridge_z])
        cube([44, bridge_y[1]-bridge_y[0], bridge_h], center=true);

      // --- battery ribs on the +Y wall
      for (s=[-1,1]) translate([s*(batt[0]/2 + 1.5/2 + 0.25), 13, -77.5])
        cube([1.5, 9, batt[2]+2], center=true);
      // --- pivot pin bosses on the inner side walls
      for (s=[-1,1]) translate([s*17, pivot[0], pivot[1]]) rotate([0,90,0]) cylinder(d=7, h=10, center=true);
      // --- motor cradle on the +Y wall
      translate([0, 13.5, -112]) cube([motor_d+4, 8, motor_d+4], center=true);
    }
    // keep every added feature inside the outer skin
    difference() { translate([0,0,-200]) cube(400, center=true); grip_body(); }

    // --- board pillar sockets for the head pegs
    for (h = holes) translate([h[0], h[1], -board_t - 1.5]) cylinder(d=2.0, h=3);

    // --- tact switch pocket + lead hole in the bridge
    translate([0, bridge_y[0] - 0.01, bridge_z]) rotate([-90,0,0]) {
      linear_extrude(tact_depth + 0.01) square(tact_body, center=true);
      cylinder(d=4, h=20);
    }
    // --- motor pocket (coin ERM, faces -Y)
    translate([0, 9.5 - 0.01, -112]) rotate([-90,0,0]) cylinder(d=motor_d, h=motor_t + 0.02);

    // --- trigger slot in the -Y wall
    hull() for (z = [slot_z[0] + trig_x_w/2, slot_z[1] - trig_x_w/2])
      translate([0, -19, z]) rotate([90,0,0]) cylinder(d=trig_x_w, h=12, center=true);

    // --- pivot pin hole through both side walls
    translate([0, pivot[0], pivot[1]]) rotate([0,90,0]) cylinder(d=pin_d + 0.25, h=head_w + 2, center=true);

    // --- screw pilot holes in the bosses
    for (s=[-1,1]) translate([-s*screw_x, s*(head_w/2 + 1), screw_z]) rotate([s*90,0,0])
      cylinder(d=screw_pilot, h=(head_w/2 + 1 - 15)*1);

    // --- wrist strap hole through the butt
    translate([0, 0, -143.5]) rotate([0,90,0]) cylinder(d=3.5, h=60, center=true);
  }
}

// ============================================================ TRIGGER =====
function paddle_y_at(z) = paddle_top[0] + (paddle_tip[0]-paddle_top[0]) * (z - paddle_top[1]) / (paddle_tip[1]-paddle_top[1]);

module trigger() {
  bore = pin_d + 0.3;
  nub_tip = tact_btn_y - nub_gap;      // Y of the nub's contact face at rest
  rotate([90,0,90]) difference() {     // draw in (Y,Z), extrude along X
    union() {
      // hub with stop ears (wider than the slot so the lever can't fall out)
      linear_extrude(lever_w + 4, center=true) translate(pivot) circle(r=3.2);
      // paddle
      linear_extrude(lever_w, center=true) hull() {
        translate(pivot) circle(r=3.2);
        translate(paddle_top) circle(d=paddle_t);
        translate(paddle_tip) circle(d=paddle_t);
      }
      // switch nub: from the paddle inward to just short of the tact button
      linear_extrude(5, center=true) hull() {
        translate([paddle_y_at(bridge_z), bridge_z]) circle(d=paddle_t);
        translate([nub_tip - 1.5, bridge_z]) circle(d=3);
      }
    }
    linear_extrude(lever_w + 8, center=true) translate(pivot) circle(d=bore);
  }
}

module pin() { translate([0, pivot[0], pivot[1]]) rotate([0,90,0]) cylinder(d=pin_d, h=pin_len, center=true); }

// ========================================================== reference =====
module board() {
  color("#2a7a3a") difference() {
    translate([0,0,-board_t]) linear_extrude(board_t) board_outline();
    for (h = holes) translate([h[0], h[1], -5]) cylinder(d=hole_d, h=10);
  }
  // rough component blocks so clearances are visible
  color("silver") translate([-16.33-4.5, usb_y-4.5, 0]) cube([9, 9, usb_h]);          // USB-C
  color("black")  translate([sw_x-4.5, 15.09-2, 0]) cube([9, 4, 3.5]);                   // slide switch
  color("#444")   translate([1.94-5.5, -8.62-7.4, 0]) cube([11, 14.8, 2.0]);            // NORA-B206
  color("white")  for (p = [[-15.28, -6.17], [16.47, -0.22]]) translate([p[0]-3.75, p[1]-4.2, -board_t-jst_h]) cube([7.5, 8.4, jst_h]); // JST PH
  color("gold")   translate([2, 5, 0]) cube([1, 1, 0.6]);                                // ~ where the WS2812B pixel should land
}
module ball()  {
  color("white", 0.35) difference() {
    translate([0,0,z_ball]) sphere(d=ball_d);
    for (s=[-1,1]) translate([s*tie_hole_r, 0, z_ball - ball_d/2]) cylinder(d=tie_hole_d, h=8, center=true);
  }
}
// zip tie path: down from one ball hole, under the bar, up through the other, closed inside the ball
module tie() {
  z_hole = z_ball - sqrt(pow(ball_d/2,2) - pow(tie_hole_r,2));   // where the holes sit on the ball
  color("#222") rotate([90,0,0]) linear_extrude(2.5, center=true) difference() {
    offset(1.0) polygon([[-tie_hole_r, z_hole+2], [-tie_hole_r, bar_z], [tie_hole_r, bar_z], [tie_hole_r, z_hole+2]]);
    offset(-0.0) polygon([[-tie_hole_r+1, z_hole+3], [-tie_hole_r+1, bar_z+1], [tie_hole_r-1, bar_z+1], [tie_hole_r-1, z_hole+3]]);
    translate([0, z_hole+2]) square([2*tie_hole_r+4, 20]);   // open at the top (inside the ball it follows the shell)
  }
}
module lipo()  { color("#5060c0") translate([-batt[0]/2, 14.9 - batt[1], -77.5 - batt[2]/2]) cube(batt); }
module tact()  { color("#333") translate([-3, tact_btn_y + 1.0, bridge_z - 3]) cube([6, 5, 6]); color("#888") translate([-1.75, tact_btn_y, bridge_z-1.75]) cube([3.5, 1.0, 3.5]); }

// ============================================================= views ======
module assembly(explode=0) {
  color("#d9d9d9") translate([0,0, explode*1.0]) head();
  color("#c8c8c8") translate([0,0,-explode*1.0]) grip();
  color("#e05a2b") translate([0,-explode*0.6,-explode*1.0]) trigger();
  color("#666")    translate([explode*0.9,0,-explode*1.0]) pin();
  translate([0,0,explode*1.6]) { ball(); tie(); }
  board();
  translate([0,0,-explode*1.0]) { lipo(); tact(); }
}

if (view == "assembly") assembly(0);
if (view == "exploded") assembly(35);
if (view == "section")  difference() { assembly(0); translate([0,-200,-300]) cube([200,400,600]); }  // remove +X half
if (view == "head")     head();
if (view == "grip")     grip();
if (view == "trigger")  trigger();
