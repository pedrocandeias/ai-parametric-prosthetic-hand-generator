// ============================================
// snap_lib.scad — Snap_Pins reconstruction, PRIMITIVE model
// Each pin = central rectangle + two elliptical half-pipe sides (rounded shaft)
// + rounded-rect head + box slot (the fork) + rounded-rect barb at the tips.
// No measured polygons. Included by main.scad (plate) and partgen.scad (one part).
// ============================================

$fn = 96;
eps = 0.05;

// ---- shaft specs: [height, rect_half_width, ellipse_rx, ellipse_rz] ----
//   shaft cross-section = square(2*rhw x height) + an elliptical half-pipe each side
shaft_A55  = [3.30, 0.58, 1.33, 1.650];   // b1,b2,b3 (area-matched)
shaft_A50  = [3.20, 1.00, 0.95, 1.600];   // b5-b8
shaft_A50T = [3.40, 1.00, 1.00, 1.700];   // b4 (taller)
shaft_b0   = [3.30, 0.96, 1.14, 1.650];   // b0 (area-matched)
shaft_B    = [4.05, 1.03, 1.47, 2.025];  // b11,b12 clip (area-matched)

// ---- snap-pin (type A) defaults ----
pinA_head_len = 2.5;
pinA_head_r   = 0.55;
pinA_fork     = 6.5;
pinA_slot     = 1.0;
pinA_barb_w   = 4.8;
pinA_barb_len = 1.3;
pinA_barb_r   = 1.45;

// ---- clip-pin (type B) defaults ----
clip_h        = 4.05;   // shaft height
clip_head_h   = 4.40;   // head/barb height (taller than shaft)
clip_head_len = 1.9;
clip_head_r   = 0.5;
clip_fork     = 7.4;
clip_slot     = 1.5;
clip_barb_w   = 5.6;
clip_barb_len = 1.7;

// shaft cross-section (X-Z): central rectangle + elliptical half-pipe sides, bottom z=0
module pin_xsec(sh, rhw, erx, erz)
    translate([0, sh/2]) union() {
        square([rhw*2, sh], center = true);
        for (s = [-1, 1]) translate([s*rhw, 0]) scale([erx, erz]) circle(r = 1);
    };
module pin_shaft(len, shaft)
    rotate([90, 0, 0]) linear_extrude(len, center = true)
        pin_xsec(shaft[0], shaft[1], shaft[2], shaft[3]);

// rounded-rect rod along Y (head + barbs), bottom z=0
module rr_rod(len, w, h, r)
    rotate([90, 0, 0]) linear_extrude(len, center = true)
        translate([0, h/2]) offset(r) offset(-r) square([w, h], center=true);

// --- Snap pin (type A): head at +Y, fork at -Y, centred at origin ---
module snap_pin(L, shaft, head_w, head_len=pinA_head_len, fork=pinA_fork, slot=pinA_slot,
                barb_len=pinA_barb_len, barb_w=pinA_barb_w, barb_r=pinA_barb_r,
                head_r=pinA_head_r) {
    h = shaft[0];
    shaft_len = L - head_len;
    difference() {
        union() {
            translate([0, -head_len/2, 0]) pin_shaft(shaft_len, shaft);
            translate([0, L/2 - head_len/2, 0]) rr_rod(head_len, head_w, h, head_r);
            translate([0, -L/2 + barb_len/2, 0]) rr_rod(barb_len, barb_w, h, barb_r);
        }
        translate([0, -L/2 + fork/2, h/2])
            cube([slot, fork + eps, h + 2*eps], center=true);
    }
}

// --- Clip pin (type B) ---
module clip_pin(L, head_w) {
    shaft_len = L - clip_head_len;
    difference() {
        union() {
            translate([0, -clip_head_len/2, 0]) pin_shaft(shaft_len, shaft_B);
            translate([0, L/2 - clip_head_len/2, 0]) rr_rod(clip_head_len, head_w, clip_head_h, clip_head_r);
            translate([0, -L/2 + clip_barb_len/2, 0]) rr_rod(clip_barb_len, clip_barb_w, clip_head_h, 1.5);
        }
        translate([0, -L/2 + clip_fork/2, clip_head_h/2])
            cube([clip_slot, clip_fork + eps, clip_head_h + 2*eps], center=true);
    }
}

// --- Domed cup washer (rotationally symmetric) ---
washer_profile = [
  [2.7,0.5],[3.2,0.0],[4.0,0.0],[7.75,0.0],[8.25,0.5],[8.25,0.91],[8.21,1.2],
  [8.15,1.49],[8.06,1.77],[7.94,2.04],[7.8,2.29],[7.64,2.54],[7.45,2.76],
  [7.24,2.97],[7.01,3.15],[6.77,3.32],[6.51,3.45],[6.24,3.57],[5.96,3.65],
  [5.67,3.71],[5.38,3.75],[4.94,3.75],[4.7,3.31],[4.7,2.0],[2.7,2.0],
];
module dome_washer() { rotate_extrude($fn = 128) polygon(washer_profile); }

// ---- Layout (origin-centred: original coords shifted by +43.77,-49.84) ----
module place(x, y, rz) translate([x, y, 0]) rotate([0, 0, rz]) children();

place(-23.17, 16.45, -90) snap_pin(16.00, shaft_b0,  5.5, slot=1.6);                               // b0 wide
place(-26.85,-12.71,   0) snap_pin(13.00, shaft_A55, 5.5, fork=7.8, barb_len=1.6, barb_r=1.3);     // b1
place(-26.85,  2.50,   0) snap_pin(13.00, shaft_A55, 5.5, fork=7.8, barb_len=1.6, barb_r=1.3);     // b2
place(-18.54, -5.42,   0) snap_pin(27.00, shaft_A55, 5.5);                                         // b3
place( -2.95, 16.10,  90) snap_pin(13.29, shaft_A50T,5.0, 2.24, 6.85, barb_len=2.90, barb_r=1.45); // b4 tall
place( -3.43,-15.15,  90) snap_pin(10.47, shaft_A50, 5.0, 0.9, 5.4);                               // b5
place( -3.43, -8.39,  90) snap_pin(10.47, shaft_A50, 5.0, 0.9, 5.4);                               // b6
place( -3.43, -1.29,  90) snap_pin(10.47, shaft_A50, 5.0, 0.9, 5.4);                               // b7
place( -3.43,  5.64,  90) snap_pin(10.47, shaft_A50, 5.0, 0.9, 5.4);                               // b8
place( 14.43, -9.15,   0) dome_washer();                                                          // b9
place( 14.43,  8.26,   0) dome_washer();                                                          // b10
place( 27.79, -9.73,   0) clip_pin(13.75, 6.75);                                                   // b11
place( 27.79,  8.70,   0) clip_pin(13.75, 6.75);                                                   // b12
