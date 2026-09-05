// Joust wand — organic variant. One continuous body from the butt to the ball
// lip, superellipse cross-sections, no visible fasteners.
//
// Coordinate frame: Z is the wand axis (ball is +Z). Origin is the center of
// the PCB's TOP surface. X/Y match the KiCad board frame except Y is flipped
// (Y_here = -Y_kicad), so looking down from the ball you see the board as in
// the KiCad editor.
//
// Parts:  head — board pocket, light chamber, ball lip, four hanging tabs
//         grip — handle, haptic motor shelf under the board, battery ribs
//
// Fastening: two 3 mm pins pass through the grip side walls and the head's
// tabs. Push the pins out to remove the head. The only visible hardware is
// four flush dots.
//
// Board orientation inside the wand:
//   -X face : USB-C receptacle (charging slot)
//   +Y face : power slide switch (slot)
//   -Y face : BLE module antenna edge (keep metal away)
//   bottom  : JST PH battery + motor connectors face down into the grip
//
// Print: head upside-down on its lip with a brim (or right-side up with supports
// under the bosses/tabs), grip butt-down.
// Hardware: 2x 3 mm pins 40 mm long (filament or M3 rod), 12x3.4 mm coin ERM
// haptic motor, ping-pong ball, one 2.5 mm zip tie.
//
// Set `view` below or from the CLI:  openscad -D 'view="head"' -o head.stl joust_wand.scad

view = "assembly";   // assembly | exploded | section | head | grip
$fn = (view == "head" || view == "grip") ? 96 : 48;
step = (view == "head" || view == "grip") ? 1.5 : 3;   // loft station spacing (mm)

// ---------------------------------------------------------------- board ----
board_w   = 40;
board_r   = 10;
board_t   = 1.6;
board_clr = 0.3;
hole_d    = 2.2;
holes = [[-13.45, 13.95], [13.62, 13.95], [13.62, -13.08], [-13.45, -13.08]];

usb_y      =  3.89;  usb_h = 3.2;
sw_x       = -1.44;
jst_h      =  6.0;
top_comp_h =  4.0;

// ------------------------------------------------------------ envelope ----
wall     = 2.7;
head_w   = board_w + 2*board_clr + 2*wall;   // 46.0
pocket_w = board_w + 2*board_clr;            // 40.6
pocket_r = board_r + board_clr;              // 10.3
corner_c = pocket_w/2 - pocket_r;
grip_wall = 2.4;

// ------------------------------------------------------------ Z levels ----
z_joint    = -10;
z_funnel0  = top_comp_h + 0.5;
chamber_d  = 30;
z_funnel1  = z_funnel0 + (pocket_w/2 - chamber_d/2);
ball_d     = 40;  ball_clr = 0.25;  ball_r = ball_d/2 + ball_clr;
z_ball     = 32.0;
rim_below  = 11;
z_top      = z_ball - rim_below;
rim_r      = sqrt(ball_r*ball_r - rim_below*rim_below);
lip_t      = 0.7;
z_bot      = -151;
z_floor    = -140;
z_web      = -16;

// ball retention
tie_hole_r = 10;  tie_hole_d = 3.5;  bar_z = 8;  bar_d = 3;

// -------------------------------------------------------------- pins ------
pin_y      = 15;                     // |Y| of both pin axes
pin_z      = -20;
pin_d      = 3.0;  pin_len = 39.5;

// ------------------------------------------------------- haptic motor -----
// 12 x 3.4 mm coin ERM (e.g. Precision Microdrives 312-101 or generic "1234"),
// stuck into a pocket on a shelf under the board, leads exit toward J_MOT (+X).
motor_d    = 12.0;  motor_t = 3.4;
motor_clr  = 0.25;
shelf_x    = 16;                     // shelf width (X), clears JST plugs and head tabs
shelf_top  = -10.4;                  // just below the joint plane
shelf_t    = motor_t + 0.8;

// head tabs: hang down inside the grip, pinned on both faces
tab_x      = [8.6, 11.1];            // |X| range (clears lever hub and pillars)
tab_y      = 4.0;                    // thickness around the pin axis
tab_bot    = -25;

batt       = [21, 6.5, 33];

// ====================================================== body profile ======
// keyframes: [z, width_x, width_y, superellipse exponent], ascending z.
// The head must stay >= 45.4 wide between z_joint and z_funnel0 (pocket + walls).
body_keys = [
  [z_bot,      12,   11,   2.0],
  [-148,       30,   27,   2.3],
  [-140,       40.5, 36.5, 2.7],
  [-128,       37.5, 34.5, 2.6],
  [-100,       35.5, 32.5, 2.6],
  [-60,        37,   34,   2.7],
  [-38,        40.5, 37.5, 3.0],
  [-22,        45,   43.5, 3.6],
  [-12,        46.2, 46.2, 4.0],
  [4,          46.2, 46.2, 4.0],
  [11,         44,   44,   3.2],
  [17,         39.6, 39.6, 2.4],
  [z_top,      2*(rim_r+lip_t), 2*(rim_r+lip_t), 2.0],
];

function seg(keys, z) = [for (j=[0:len(keys)-2]) if (z >= keys[j][0] && z <= keys[j+1][0]) j][0];
function tang(keys, i, c) =
  i == 0 ? (keys[1][c]-keys[0][c])/(keys[1][0]-keys[0][0]) :
  i == len(keys)-1 ? (keys[i][c]-keys[i-1][c])/(keys[i][0]-keys[i-1][0]) :
  (keys[i+1][c]-keys[i-1][c])/(keys[i+1][0]-keys[i-1][0]);
function hermite(z, z0, z1, v0, v1, m0, m1) =
  let(h = z1-z0, t = (z-z0)/h, t2 = t*t, t3 = t2*t)
  (2*t3-3*t2+1)*v0 + (t3-2*t2+t)*h*m0 + (-2*t3+3*t2)*v1 + (t3-t2)*h*m1;
function kf(keys, z, c) = let(zz = max(keys[0][0], min(keys[len(keys)-1][0], z)), i = seg(keys, zz))
  hermite(zz, keys[i][0], keys[i+1][0], keys[i][c], keys[i+1][c], tang(keys,i,c), tang(keys,i+1,c));

function superellipse(wx, wy, n, N=64) = [for (i=[0:N-1]) let(a = i*360/N, c = cos(a), s = sin(a))
  [wx/2*sign(c)*pow(abs(c), 2/n), wy/2*sign(s)*pow(abs(s), 2/n)]];

module body_slab(z, inset=0) {
  translate([0,0,z]) linear_extrude(0.01)
    polygon(superellipse(max(1, kf(body_keys,z,1) - 2*inset), max(1, kf(body_keys,z,2) - 2*inset), kf(body_keys,z,3)));
}
// solid body between z0 and z1 (inclusive), stations every `step`
module body(z0, z1, inset=0) {
  zs = concat([for (z=[z0:step:z1-0.001]) z], [z1]);
  for (i=[0:len(zs)-2]) hull() { body_slab(zs[i], inset); body_slab(zs[i+1], inset); }
}

// ============================================================ helpers =====
module rr(w, h, r) {
  if (w - 2*r < 0.01 || h - 2*r < 0.01) scale([w, h]) circle(d=1);
  else offset(r) square([w-2*r, h-2*r], center=true);
}
module rr_slab(z, w, h, r) { translate([0,0,z]) linear_extrude(0.01) rr(w, h, r); }
module rounded_slot(l, w, h) {   // along X: length l, height w (Z), depth h (Y)
  hull() for (s=[-1,1]) translate([s*(l-w)/2, 0, 0]) rotate([90,0,0]) cylinder(d=w, h=h, center=true);
}
function sgn(v) = v < 0 ? -1 : 1;
function corner_pt(h, d) = [sgn(h[0])*(corner_c + d/sqrt(2)), sgn(h[1])*(corner_c + d/sqrt(2))];

// ============================================================== HEAD ======
module head_tabs() {
  ty = pin_y;
  tw = tab_x[1] - tab_x[0];
  difference() {
    for (sy=[-1,1]) for (sx=[-1,1]) {
      xc = sx*(tab_x[0]+tab_x[1])/2;
      // vertical tab, rounded around the pin
      hull() {
        translate([xc, sy*ty, (z_joint + pin_z)/2]) cube([tw, tab_y, z_joint - pin_z], center=true);
        translate([xc, sy*ty, pin_z]) rotate([0,90,0]) cylinder(d=tab_y + 2, h=tw, center=true);
      }
      // bridge: from the tab outward into the head's wall, in the space under the board
      y0 = ty - tab_y/2; y1 = pocket_w/2 + 1.5;
      translate([xc - tw/2, sy > 0 ? y0 : -y1, z_joint]) cube([tw, y1 - y0, (-board_t - 1.0) - z_joint]);
    }
    // never intrude on the board itself
    translate([0,0,-board_t - 0.5]) linear_extrude(10) rr(pocket_w + 1, pocket_w + 1, pocket_r);
  }
}

module head() {
  difference() {
    union() {
      difference() {
        body(z_joint, z_top);
        // --- board pocket
        translate([0,0,z_joint-1]) linear_extrude(z_funnel0 - z_joint + 1) rr(pocket_w, pocket_w, pocket_r);
        // --- funnel + chamber + ball socket
        hull() { rr_slab(z_funnel0-0.01, pocket_w, pocket_w, pocket_r); translate([0,0,z_funnel1]) cylinder(d=chamber_d, h=0.01); }
        translate([0,0,z_funnel1-0.01]) cylinder(d=chamber_d, h=z_ball - z_funnel1 + 0.02);
        translate([0,0,z_ball]) sphere(r=ball_r);
        // --- USB-C slot (-X) and relief
        translate([-head_w/2, usb_y, usb_h/2]) rotate([0,0,90]) rounded_slot(13, 7, wall*3);
        translate([-pocket_w/2 - 1.5, usb_y - 5.5, -0.3]) cube([1.6, 11, usb_h + 0.6]);
        // --- power switch (+Y): fingertip-sized pill so the knob 3 mm inside the
        //     wall can be slid with a finger pad, not just a nail
        translate([sw_x, head_w/2, 3.2]) rounded_slot(12, 6, wall*3);
        translate([sw_x - 5.5, pocket_w/2 - 0.1, -0.3]) cube([11, 1.1, 5.3]);
      }
      // --- pin tabs (added after the pocket cut so their bridges survive)
      intersection() { head_tabs(); body(z_joint - 20, z_top); }
      // --- hold-down bosses + pegs
      for (h = holes) translate([h[0], h[1], 0]) {
        cylinder(d=4.0, h=z_funnel1 + 2);
        translate([0,0,-(board_t + 0.9)]) cylinder(d=1.8, h=board_t + 1.0);
      }
      // --- zip tie bar
      intersection() {
        translate([0,0,bar_z]) rotate([90,0,0]) cylinder(d=bar_d, h=head_w, center=true);
        body(z_joint, z_top);
      }
    }
    // --- pin holes through the tabs
    for (sy=[-1,1]) translate([0, sy*pin_y, pin_z]) rotate([0,90,0]) cylinder(d=pin_d + 0.3, h=head_w, center=true);
  }
}

// ============================================================== GRIP ======
module grip_cavity() {
  // pocket-sized to z_web (JST plugs + head tabs), then follows the skin
  hull() { rr_slab(z_joint + 1, pocket_w, pocket_w, pocket_r); rr_slab(z_web, pocket_w, pocket_w, pocket_r); }
  hull() { rr_slab(z_web, pocket_w, pocket_w, pocket_r); body_slab(z_web - 8, grip_wall); }
  body(z_floor, z_web - 8, grip_wall);
}

module pillar(h) {
  hull() {
    translate([h[0], h[1], z_web]) cylinder(d=3.6, h=(-board_t) - z_web);
    translate([corner_pt(h, pocket_r - 2.0)[0], corner_pt(h, pocket_r - 2.0)[1], z_web]) cylinder(d=3.6, h=(-board_t) - z_web);
  }
  hull() {
    translate([corner_pt(h, pocket_r - 2.0)[0], corner_pt(h, pocket_r - 2.0)[1], z_web]) cylinder(d=3.6, h=z_joint - 0.2 - z_web);
    translate([corner_pt(h, pocket_r + 1.5)[0], corner_pt(h, pocket_r + 1.5)[1], z_web]) cylinder(d=3.6, h=z_joint - 0.2 - z_web);
  }
}

module grip() {
  difference() {
    union() {
      difference() { body(z_bot, z_joint); grip_cavity(); }
      for (h = holes) pillar(h);
      // haptic motor shelf: spans the cavity front to back, under the board center
      translate([-shelf_x/2, -head_w/2, shelf_top - shelf_t]) cube([shelf_x, head_w, shelf_t]);
      // battery ribs (+Y wall)
      for (s=[-1,1]) translate([s*(batt[0]/2 + 1.5/2 + 0.25), 13, -77.5]) cube([1.5, 9, batt[2]+2], center=true);
      // pin bosses on both inner side walls, both faces
      for (sx=[-1,1]) for (sy=[-1,1]) translate([sx*17, sy*pin_y, pin_z]) rotate([0,90,0]) cylinder(d=7, h=10, center=true);
    }
    // trim to the outer skin
    difference() { translate([0,0,-200]) cube(400, center=true); body(z_bot, z_joint); }

    for (h = holes) translate([h[0], h[1], -board_t - 1.5]) cylinder(d=2.0, h=3);
    // motor pocket in the shelf, open upward; lead notch toward J_MOT on +X
    translate([0, 0, shelf_top - motor_t - motor_clr]) cylinder(d=motor_d + 2*motor_clr, h=motor_t + motor_clr + 1);
    translate([motor_d/2 - 1, -1.5, shelf_top - 2.0]) cube([shelf_x/2 - motor_d/2 + 2, 3, 3]);
    // pin holes, both faces
    for (sy=[-1,1]) translate([0, sy*pin_y, pin_z]) rotate([0,90,0]) cylinder(d=pin_d + 0.25, h=head_w + 2, center=true);
    // wrist strap
    translate([0, 0, -145]) rotate([0,90,0]) cylinder(d=3.5, h=60, center=true);
  }
}

module pins() { for (sy=[-1,1]) translate([0, sy*pin_y, pin_z]) rotate([0,90,0]) cylinder(d=pin_d, h=pin_len, center=true); }

// ========================================================== reference =====
module board() {
  color("#2a7a3a") difference() {
    translate([0,0,-board_t]) linear_extrude(board_t) rr(board_w, board_w, board_r);
    for (h = holes) translate([h[0], h[1], -5]) cylinder(d=hole_d, h=10);
  }
  color("silver") translate([-16.33-4.5, usb_y-4.5, 0]) cube([9, 9, usb_h]);
  color("black")  translate([sw_x-4.5, 15.09-2, 0]) cube([9, 4, 3.5]);
  color("#444")   translate([1.94-5.5, -8.62-7.4, 0]) cube([11, 14.8, 2.0]);
  color("white")  for (p = [[-15.28, -6.17], [16.47, -0.22]]) translate([p[0]-3.75, p[1]-4.2, -board_t-jst_h]) cube([7.5, 8.4, jst_h]);
  color("gold")   translate([2, 5, 0]) cube([1, 1, 0.6]);
}
module ball() {
  color("white", 0.35) difference() {
    translate([0,0,z_ball]) sphere(d=ball_d);
    for (s=[-1,1]) translate([s*tie_hole_r, 0, z_ball - ball_d/2]) cylinder(d=tie_hole_d, h=8, center=true);
  }
}
module tie() {
  z_hole = z_ball - sqrt(pow(ball_d/2,2) - pow(tie_hole_r,2));
  color("#222") rotate([90,0,0]) linear_extrude(2.5, center=true) difference() {
    offset(1.0) polygon([[-tie_hole_r, z_hole+2], [-tie_hole_r, bar_z], [tie_hole_r, bar_z], [tie_hole_r, z_hole+2]]);
    polygon([[-tie_hole_r+1, z_hole+3], [-tie_hole_r+1, bar_z+1], [tie_hole_r-1, bar_z+1], [tie_hole_r-1, z_hole+3]]);
    translate([0, z_hole+2]) square([2*tie_hole_r+4, 20]);
  }
}
module lipo()  { color("#5060c0") translate([-batt[0]/2, 14.9 - batt[1], -77.5 - batt[2]/2]) cube(batt); }
module motor() { color("#777") translate([0, 0, shelf_top - motor_t]) cylinder(d=motor_d, h=motor_t); }

// ============================================================= views ======
module assembly(explode=0) {
  color("#e8e8e8") translate([0,0, explode*1.0]) head();
  color("#dcdcdc") translate([0,0,-explode*1.0]) grip();
  color("#666")    translate([explode*0.9,0,-explode*1.0]) pins();
  translate([0,0,explode*1.6]) { ball(); tie(); }
  board();
  translate([0,0,-explode*1.0]) { lipo(); motor(); }
}

if (view == "assembly") assembly(0);
if (view == "exploded") assembly(35);
if (view == "section")  difference() { assembly(0); translate([0,-200,-300]) cube([200,400,600]); }
if (view == "head")     head();
if (view == "grip")     grip();
