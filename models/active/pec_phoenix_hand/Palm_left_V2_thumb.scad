// =============================================================================
// Palm_left_V2_thumb.scad — thumb pivot mount, built from readable PRIMITIVES
// (dialed interactively in templates/thumb_build.scad against the ghost).
// thumb_mount() = union(2 side prongs + deck + back wall + base + fin + cap)
//                 minus the 2 cable channels. Editable: change a number per piece.
// Needs BOSL2 (cuboid / edge constants) — provided by the parent Palm_left_V2.scad.
// =============================================================================

// ---- helper primitives ------------------------------------------------------
// box with top+bottom horizontal edges rounded (vertical edges sharp)
module rbox(w, l, h, rnd) {
    r = min(rnd, w/2 - 0.05, l/2 - 0.05, h/2 - 0.05);
    if (rnd > 0) cuboid([w, l, h], rounding = r, edges = ["X", "Y"]);
    else cube([w, l, h], center = true);
}
// box with only the chosen top/bottom edges rounded (tf/tb/bf/bb along Y; tl/tr/bl/br along X)
module rbox_edges(w, l, h, rnd, tf, tb, bf, bb, tl, tr, bl, br) {
    ylim = (tf||tb||bf||bb) ? min(w, h)/2 : 1e9;
    xlim = (tl||tr||bl||br) ? min(l, h)/2 : 1e9;
    r = min(rnd, ylim - 0.05, xlim - 0.05);
    es = [ if (tf) TOP+LEFT, if (tb) TOP+RIGHT, if (bf) BOT+LEFT, if (bb) BOT+RIGHT,
           if (tl) TOP+FWD,  if (tr) TOP+BACK,  if (bl) BOT+FWD,  if (br) BOT+BACK ];
    if (rnd > 0 && len(es) > 0) cuboid([w, l, h], rounding = r, edges = es);
    else cube([w, l, h], center = true);
}
// all-edges-rounded box (the fin cap)
module rcap(w, l, h, rnd) {
    r = min(rnd, w/2 - 0.05, l/2 - 0.05, h/2 - 0.05);
    if (r > 0) cuboid([w, l, h], rounding = r);
    else cube([w, l, h], center = true);
}
// placement wrappers: position (x,y,z), rotate (tilt about Y, yaw about Z), grow-anchor (ax,ay,az)
module gbox(x, y, z, w, l, h, rot, tilt, ax, ay, az, rnd)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([ax*w/2, ay*l/2, az*h/2]) rbox(w, l, h, rnd);
module gbox3(x, y, z, w, l, h, rot, tilt, ax, ay, az, rnd, tf, tb, bf, bb, tl, tr, bl, br)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([ax*w/2, ay*l/2, az*h/2]) rbox_edges(w, l, h, rnd, tf, tb, bf, bb, tl, tr, bl, br);
module gcyl(x, y, z, r, len, rot, tilt, az)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([0, 0, az*len/2]) cylinder(r = r, h = len, center = true, $fn = 48);

// keyhole pin bore: round through prong A, rect slot through prong B (measured)
thumb_bore_c = [28.7, -9.6, 5.8];  thumb_bore_ang = 50.3;   // axis 50.3deg in XY at z5.8
module thumb_bore() {
    translate(thumb_bore_c) rotate([0, 0, thumb_bore_ang]) {
        translate([-1, 0, 0]) rotate([0,90,0]) cylinder(h = 8, r = 2.6, center = true, $fn = 64); // round bore
        translate([11, 0, 0]) cube([8, 3.9, 5.9], center = true);                                  // rect slot
    }
}
// top tool: the dorsal crown is a 2-way curved dome (ghost top rises to z20.5 at the inner
// x23 junction, ~19 over the prongs, ~18 at the +X tip) — a flat cut sheared the crown and
// left the prongs proud. Clip the thumb top to the TRUE ghost dome (the box only bounds it).
module thumb_top_round()
    intersection() {
        translate([24, -4, 11]) cube([60, 64, 46], center = true);   // thumb-region safety bound
        import(ghost_stl);                                           // top follows the real ghost dome
    }

// body fill + shell-wall junction — measured boxes CLIPPED to the ghost (conforms to
// the original surface; keeps the bore/channels open). Uses the parent's ghost_stl.
module thumb_fill()           intersection() { translate([30, -4, 10.5]) cube([16, 28, 21], center = true); import(ghost_stl); }
module thumb_shell_junction() intersection() { translate([18, -4, 10.5]) cube([ 8, 28, 21], center = true); import(ghost_stl); }

// ---- the thumb mount --------------------------------------------------------
module thumb_mount() {
  intersection() {
    difference() {
        union() {
            // two clevis side prongs (rounded -Y ends)
            gbox3(27.3, -9.0, 0,  5.2, 19, 20,  50, 0,  0,0,1, 7, false,false,false,false, true,false,true,false); // prong A
            gbox3(33.5,  0.0, 0,  5.0, 17, 20,  50, 0,  0,0,1, 7, false,false,false,false, true,false,true,false); // prong B
            gbox (28.5, -7.5, 18, 10,  8,  1, -40, 50, 1,1,1, 0);   // top deck (bridges the prongs)
            gbox (24.0,  6.0, 0,  2,  10, 19,  90, 0,  0,0,1, 0);   // back wall (+Y)
            gbox (18.0, -4.0, 0,  15,  9,  2,  50, 0,  1,0,1, 0);   // base plate (-> palm)
            // fin blade + cap on top
            gbox (34.0, -7.5, 12.5, 5, 2.5, 3.1, -40, 45, 0,0,1, 0);                                  // fin
            translate([34.0,-7.5,12.5]) rotate([0,45,-40]) translate([0,0,3.1 + 1.2/2])
                rcap(5 + 0.4, 2.5 + 0.4, 1.2, 0.2);                                                    // fin cap
            thumb_fill();             // body mass (ghost-clipped)
            thumb_shell_junction();   // fuse into the dome +X wall (ghost-clipped)
        }
        gcyl(22.5, 2.0, 0,  1, 23,    0,  0, 1);   // cable channel 1
        gcyl(25.0, 0.0, 6,  1, 15.5, 140, 25, 0);  // cable channel 2
        thumb_bore();                              // keyhole pin bore (round + rect)
    }
    thumb_top_round();                             // round the dorsal top into a dome
  }
}

// ---- coloured view (each part a distinct colour, for identification) --------
module thumb_colored() {
    color("Red")      gbox3(27.3, -9.0, 0,  5.2, 19, 20,  50, 0, 0,0,1, 7, false,false,false,false, true,false,true,false); // prong A
    color("Blue")     gbox3(33.5,  0.0, 0,  5.0, 17, 20,  50, 0, 0,0,1, 7, false,false,false,false, true,false,true,false); // prong B
    color("Orange")   gbox (28.5, -7.5, 18, 10,  8,  1, -40, 50, 1,1,1, 0);   // deck
    color("Purple")   gbox (24.0,  6.0, 0,  2,  10, 19,  90, 0,  0,0,1, 0);    // back wall
    color("Green")    gbox (18.0, -4.0, 0,  15,  9,  2,  50, 0,  1,0,1, 0);    // base plate
    color("Indigo")   gbox (34.0, -7.5, 12.5, 5, 2.5, 3.1, -40, 45, 0,0,1, 0); // fin
    color("DeepPink") translate([34.0,-7.5,12.5]) rotate([0,45,-40]) translate([0,0,3.1 + 1.2/2]) rcap(5.4, 2.9, 1.2, 0.2); // fin cap
    color("Cyan")     gcyl(22.5, 2.0, 0,  1, 23,    0,  0, 1);   // channel 1 (subtracted)
    color("Magenta")  gcyl(25.0, 0.0, 6,  1, 15.5, 140, 25, 0);  // channel 2 (subtracted)
}
