// =============================================================================
// thumb_build.scad — interactive 3-cube builder for the THUMB form.
// Dial the cubes in the Customizer against the ghost; tell me the values and
// I rebuild thumb_mount() from them. Each cube: position xyz, size w/l/h,
// rotation (yaw about Z), tilt (about Y), and a GROWTH ANCHOR per axis:
//   anchor  0 = grow both ways from the centre
//   anchor +1 = the - face stays at the position, grow toward +
//   anchor -1 = the + face stays at the position, grow toward -
// (so you choose which direction each dimension grows). w=X, l=Y, h=Z.
// =============================================================================
include <BOSL2/std.scad>

ghost_stl   = "/home/pec/dev/openscad-parametric-reconstructor/tmp/openscad-projects/palm-left-reconstructed/output/orig_aligned.stl";

/* [Display] */
show_ghost  = true;
ghost_alpha = 0.75;     // [0:0.05:1]

/* [Cube 1 - RED] */
c1_x = 27.3;  
c1_y = -9;  
c1_z = 0;     // [-50:0.5:50] anchor point
c1_w = 5.2;   
c1_l = 19;  
c1_h = 20;    // [0:0.5:40]  size (w=X, l=Y, h=Z)
c1_rot = 50;                            // [-90:1:90]  yaw about Z
c1_tilt = 0;                           // [-90:1:90]  tilt about Y
c1_ax = 0;                             // [-1:grow -X, 0:both, 1:grow +X]
c1_ay = 0;                             // [-1:grow -Y, 0:both, 1:grow +Y]
c1_az = 1;                             // [-1:grow -Z, 0:both, 1:grow +Z]
c1_round = 7;                        // [0:0.5:10]  round top & bottom edges
c1_e_tf = false;                       // round TOP edge, -X (front)
c1_e_tb = false;                       // round TOP edge, +X (back)
c1_e_bf = false;                       // round BOTTOM edge, -X (front)
c1_e_bb = false;                       // round BOTTOM edge, +X (back)
c1_e_tl = true;                       // round TOP edge, -Y end
c1_e_tr = false;                       // round TOP edge, +Y end
c1_e_bl = true;                       // round BOTTOM edge, -Y end
c1_e_br = false;                       // round BOTTOM edge, +Y end

/* [Cube 2 - GREEN] */
c2_x = 18;  
c2_y = -4;  
c2_z = 0;     // [-50:0.5:50]
c2_w = 15;   
c2_l = 9;   
c2_h = 2;    // [0:0.5:40]
c2_rot = 50;                            // [-90:1:90]
c2_tilt = 0;                           // [-90:1:90]
c2_ax = 1;                             // [-1:grow -X, 0:both, 1:grow +X]
c2_ay = 0;                             // [-1:grow -Y, 0:both, 1:grow +Y]
c2_az = 1;                             // [-1:grow -Z, 0:both, 1:grow +Z]
c2_round = 0;                          // [0:0.5:10]  round top & bottom edges
c2_clip = true;                        // cut the part of c2 that falls OUTSIDE the ghost

/* [Cube 3 - BLUE] */
c3_x = 33.5;  
c3_y = -0;  
c3_z = 0;     // [-50:0.5:50]
c3_w = 5;  
 c3_l = 17;   
 c3_h = 20;    // [0:0.5:40]
c3_rot = 50;                            // [-90:1:90]
c3_tilt = 0;                           // [-90:1:90]
c3_ax = 0;                             // [-1:grow -X, 0:both, 1:grow +X]
c3_ay = 0;                             // [-1:grow -Y, 0:both, 1:grow +Y]
c3_az = 1;                             // [-1:grow -Z, 0:both, 1:grow +Z]
c3_round = 7;                        // [0:0.5:10]  round top & bottom edges
c3_e_tf = false;                        // round TOP-FRONT edge
c3_e_tb = false;                        // round TOP-BACK edge
c3_e_bf = false;                        // round BOTTOM-FRONT edge
c3_e_bb = false;                        // round BOTTOM-BACK edge
c3_e_tl = true;                       // round TOP edge on the -Y end
c3_e_tr = false;                       // round TOP edge on the +Y end
c3_e_bl = true;                       // round BOTTOM edge on the -Y end
c3_e_br = false;                       // round BOTTOM edge on the +Y end

/* [Cube 4 - ORANGE] */
c4_x = 28.5;     // [-50:0.5:50]
c4_y = -7.5;     // [-50:0.5:50]
c4_z = 18;     // [-50:0.5:50]
c4_w = 10;     // [0:0.5:40]
c4_l = 8;     // [0:0.5:40]
c4_h = 1;     // [0:0.5:40]
c4_rot = -40;    // [-90:1:90]  yaw Z
c4_tilt =50;  // [-90:1:90]  tilt Y
c4_ax = 1;   // [-1:grow -X, 0:both, 1:grow +X]
c4_ay = 1;   // [-1:grow -Y, 0:both, 1:grow +Y]
c4_az = 1;   // [-1:grow -Z, 0:both, 1:grow +Z]
c4_round = 0;  // [0:0.5:10]  round top & bottom edges

/* [Cube 5 - PURPLE] */
c5_x = 24;     // [-50:0.5:50]
c5_y = 6;     // [-50:0.5:50]
c5_z = 0;     // [-50:0.5:50]
c5_w = 2;     // [0:0.5:40]
c5_l = 10;     // [0:0.5:40]
c5_h = 19;     // [0:0.5:40]
c5_rot = 90;    // [-90:1:90]  yaw Z
c5_tilt = 0;  // [-90:1:90]  tilt Y
c5_ax = 0;   // [-1:grow -X, 0:both, 1:grow +X]
c5_ay = 0;   // [-1:grow -Y, 0:both, 1:grow +Y]
c5_az = 1;   // [-1:grow -Z, 0:both, 1:grow +Z]
c5_round = 0;  // [0:0.5:10]  round top & bottom edges

/* [Cylinder 1 - CYAN] */
y1_x = 22.5;     // [-50:0.5:50]
y1_y = 2;     // [-50:0.5:50]
y1_z = 0;     // [-50:0.5:50]
y1_r = 1;     // [0:0.5:40]  radius
y1_len = 23;   // [0:0.5:40]  length (local Z)
y1_rot = 0;    // [-180:1:180]  yaw Z
y1_tilt = 0;  // [-180:1:180]  tilt Y (90 = lay along X)
y1_az = 1;   // [-1:grow -, 0:both, 1:grow +]

/* [Cylinder 2 - MAGENTA] */
y2_x = 25;     // [-50:0.5:50]
y2_y = 0;     // [-50:0.5:50]
y2_z = 6;     // [-50:0.5:50]
y2_r = 1;     // [0:0.5:40]  radius
y2_len = 15.5;   // [0:0.5:40]  length (local Z)
y2_rot = 140;    // [-180:1:180]  yaw Z
y2_tilt = 25;  // [-180:1:180]  tilt Y (90 = lay along X)
y2_az = 0;   // [-1:grow -, 0:both, 1:grow +]

/* [Fin] */
fin_x = 34;     // [-50:0.5:50]
fin_y = -7.5;     // [-50:0.5:50]
fin_z = 12.5;     // [-50:0.5:50]
fin_w = 5;    // [0:0.5:40]  thin (X)
fin_l = 2.5;      // [0:0.5:40]  along Y
fin_h = 3.1;      // [0:0.5:40]  height (Z, grows up)
fin_rot = -40;    // [-90:1:90]  yaw Z
fin_tilt = 45;   // [-90:1:90]  tilt Y

/* [Fin Cap] (sits ON TOP of the fin, slightly larger, rounded faces) */
cap_over = 0.2;    // [0:0.2:5]   how much wider + longer than the fin (per side)
cap_h = 1.2;     // [0:0.5:20]  cap height
cap_round = 0.2;   // [0:0.2:4]   round the cap faces/edges

/* [Pocket - the cova (recess, subtracted in final)] */
pk_x = 33;      // [-50:0.5:50]
pk_y = -6;      // [-50:0.5:50]
pk_z = 8;       // [-50:0.5:50]
pk_w = 9;       // [0:0.5:40]
pk_l = 8;       // [0:0.5:40]
pk_h = 0;      // [0:0.5:40]
pk_rot = 0;     // [-90:1:90]
pk_show = true; // show the pocket marker (grey)

// ----------------------------------------------------------------------------
// box with the TOP and BOTTOM horizontal edges rounded by rnd (all z=top and
// z=bottom edges, all around); the vertical edges stay sharp. 4(BOSL2 cuboid)
module rbox(w, l, h, rnd) {
    r = min(rnd, w/2 - 0.05, l/2 - 0.05, h/2 - 0.05);   // clamp so it never exceeds a half-dim
    if (rnd > 0) cuboid([w, l, h], rounding = r, edges = ["X", "Y"]);
    else cube([w, l, h], center = true);
}
// anchor offset: keeps the chosen face at (x,y,z), grows in the chosen direction
module gbox(x, y, z, w, l, h, rot, tilt, ax, ay, az, rnd)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([ax*w/2, ay*l/2, az*h/2]) rbox(w, l, h, rnd);
module gcyl(x, y, z, r, len, rot, tilt, az)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([0, 0, az*len/2]) cylinder(r = r, h = len, center = true, $fn = 48);

// per-edge rounded box: round each of the 4 long top/bottom edges independently
// (front = local -X = LEFT; back = +X = RIGHT). Vertical edges always sharp.
module rbox_edges(w, l, h, rnd, tf, tb, bf, bb, tl, tr, bl, br) {
    ylim = (tf||tb||bf||bb) ? min(w, h)/2 : 1e9;  // -X/+X edges fillet in the X-Z plane (limited by thin w)
    xlim = (tl||tr||bl||br) ? min(l, h)/2 : 1e9;  // -Y/+Y end edges fillet in the Y-Z plane (limit ~9.5)
    r = min(rnd, ylim - 0.05, xlim - 0.05);
    es = [ if (tf) TOP+LEFT, if (tb) TOP+RIGHT, if (bf) BOT+LEFT, if (bb) BOT+RIGHT,   // along Y (front/back = -X/+X)
           if (tl) TOP+FWD,  if (tr) TOP+BACK,  if (bl) BOT+FWD,  if (br) BOT+BACK ];  // along X (ends = -Y/+Y)
    if (rnd > 0 && len(es) > 0) cuboid([w, l, h], rounding = r, edges = es);
    else cube([w, l, h], center = true);
}
module gbox3(x, y, z, w, l, h, rot, tilt, ax, ay, az, rnd, tf, tb, bf, bb, tl, tr, bl, br)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([ax*w/2, ay*l/2, az*h/2]) rbox_edges(w, l, h, rnd, tf, tb, bf, bb, tl, tr, bl, br);
// all-edges-rounded box (the fin cap): rounded faces all around
module rcap(w, l, h, rnd) {
    r = min(rnd, w/2 - 0.05, l/2 - 0.05, h/2 - 0.05);
    if (r > 0) cuboid([w, l, h], rounding = r);
    else cube([w, l, h], center = true);
}


color("red",    0.85) gbox3(c1_x,c1_y,c1_z, c1_w,c1_l,c1_h, c1_rot,c1_tilt, c1_ax,c1_ay,c1_az, c1_round, c1_e_tf,c1_e_tb,c1_e_bf,c1_e_bb, c1_e_tl,c1_e_tr,c1_e_bl,c1_e_br);
color("green",  0.85) {                                  // c2: cut the part outside the ghost
    if (c2_clip) render() intersection() { gbox(c2_x,c2_y,c2_z, c2_w,c2_l,c2_h, c2_rot,c2_tilt, c2_ax,c2_ay,c2_az, c2_round); import(ghost_stl); }
    else gbox(c2_x,c2_y,c2_z, c2_w,c2_l,c2_h, c2_rot,c2_tilt, c2_ax,c2_ay,c2_az, c2_round);
}
color("blue",   0.85) gbox3(c3_x,c3_y,c3_z, c3_w,c3_l,c3_h, c3_rot,c3_tilt, c3_ax,c3_ay,c3_az, c3_round, c3_e_tf,c3_e_tb,c3_e_bf,c3_e_bb, c3_e_tl,c3_e_tr,c3_e_bl,c3_e_br);
color("orange", 0.85) gbox(c4_x,c4_y,c4_z, c4_w,c4_l,c4_h, c4_rot,c4_tilt, c4_ax,c4_ay,c4_az, c4_round);
color("purple", 0.85) gbox(c5_x,c5_y,c5_z, c5_w,c5_l,c5_h, c5_rot,c5_tilt, c5_ax,c5_ay,c5_az, c5_round);
color("cyan",   0.85) gcyl(y1_x,y1_y,y1_z, y1_r,y1_len, y1_rot,y1_tilt, y1_az);
color("magenta",0.85) gcyl(y2_x,y2_y,y2_z, y2_r,y2_len, y2_rot,y2_tilt, y2_az);

color("Indigo",  0.9 ) gbox(fin_x,fin_y,fin_z, fin_w,fin_l,fin_h, fin_rot,fin_tilt, 0,0,1, 0);
color("DeepPink",0.9 ) translate([fin_x,fin_y,fin_z]) rotate([0,fin_tilt,fin_rot])
                          translate([0,0,fin_h + cap_h/2]) rcap(fin_w + 2*cap_over, fin_l + 2*cap_over, cap_h, cap_round);
if (pk_show) color([0.5,0.5,0.5],0.30) gbox(pk_x,pk_y,pk_z, pk_w,pk_l,pk_h, pk_rot,0, 0,0,1, 0);

// ghost drawn LAST so the colored objects show through its transparency
if (show_ghost) color([0.55, 0.72, 0.92], ghost_alpha) import(ghost_stl);
