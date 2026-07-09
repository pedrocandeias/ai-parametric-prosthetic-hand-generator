// ============================================
// Project: Tensioner_Pins.stl reconstruction
// Description: Three identical tensioner pins - square rods with a square
//              strap hole near one end and a round bore along the length.
// Author: Claude Code + User
// ============================================
// Each pin: 4.76(X) x 33.12(Y) x 4.75(Z). 3 pins spaced 5.877mm in X.
// Centred at origin (X0 Y0), sitting on the build plate (Z0).

$fn = 96;
eps = 0.05;

// --- Pin body ---
pin_w   = 4.76;     // [mm] width  (X)
pin_l   = 33.12;    // [mm] length (Y)
pin_h   = 4.75;     // [mm] height (Z)
chamfer = 0.3;      // [mm] edge chamfer

// --- Square strap hole (through Z), near the head end ---
sq_x    = 2.91;     // [mm] X size
sq_y    = 3.05;     // [mm] Y size (mid-height; edges chamfered)
sq_yoff = -11.94;   // [mm] Y offset from pin centre

// --- Round bore (along Y, open at the far/+Y end) ---
bore_d  = 3.0;      // [mm]
bore_y0 = -8.90;    // [mm] bore start (Y offset from pin centre)

// --- Layout ---
n_pins   = 3.0;
pin_dx   = 5.877;   // [mm] X spacing

module rod() {
    c = chamfer;
    hull() {
        linear_extrude(eps) offset(delta = -c) square([pin_w, pin_l], center = true);
        translate([0, 0, c])        linear_extrude(eps) square([pin_w, pin_l], center = true);
        translate([0, 0, pin_h - c]) linear_extrude(eps) square([pin_w, pin_l], center = true);
        translate([0, 0, pin_h - eps]) linear_extrude(eps) offset(delta = -c) square([pin_w, pin_l], center = true);
    }
}

module pin() {
    cz = pin_h/2;
    difference() {
        // chamfered square rod (top/bottom edges), bottom on plate
        rod();
        // square strap hole through Z
        translate([0, sq_yoff, -eps])
            linear_extrude(pin_h + 2*eps)
                square([sq_x, sq_y], center = true);
        // round bore along Y (open at the +Y end)
        translate([0, bore_y0, cz])
            rotate([-90, 0, 0])
                cylinder(d = bore_d, h = pin_l/2 - bore_y0 + eps);
    }
}

// Assembly: 3 pins centred on origin
for (i = [0 : n_pins-1])
    translate([(i - (n_pins-1)/2) * pin_dx, 0, 0])
        pin();

echo(str("pin bbox ", pin_w, " x ", pin_l, " x ", pin_h));
