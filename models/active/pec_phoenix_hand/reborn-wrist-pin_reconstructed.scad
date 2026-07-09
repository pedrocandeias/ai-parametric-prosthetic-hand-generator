// ============================================
// Reborn_wrist_pin.stl reconstruction
// Snap-pin family: rounded shaft (rect + elliptical half-pipes) + wide head (+Y)
// + slotted legs + wide rounded feet/barbs (-Y). Centred at origin (X0 Y0, z0 bottom).
// ============================================
$fn = 96;
eps = 0.05;

L          = 12.994;   // total length (Y)
shaft      = [4.515, 0.96, 1.64, 2.2575];  // [height, rect_hw, ellipse_rx, ellipse_rz] (area-matched)
head_w     = 6.4575;   // head full width (X)
head_len   = 1.75;     // head length (Y), at +Y
head_r     = 0.20;     // head corner round
slot_w     = 1.57;
fork       = 6.60;     // slot length from the -Y tip
foot_w     = 6.40;     // feet/barb width (X), at -Y
foot_len   = 1.00;
foot_r     = 1.90;     // feet corner round

// shaft cross-section (X-Z): central rectangle + elliptical half-pipe sides, bottom z=0
module pin_xsec(sh, rhw, erx, erz)
    translate([0, sh/2]) union() {
        square([rhw*2, sh], center = true);
        for (s = [-1, 1]) translate([s*rhw, 0]) scale([erx, erz]) circle(r = 1);
    };
module pin_shaft(len, sp)
    rotate([90, 0, 0]) linear_extrude(len, center = true)
        pin_xsec(sp[0], sp[1], sp[2], sp[3]);
module rr_rod(len, w, h, r)
    rotate([90, 0, 0]) linear_extrude(len, center = true)
        translate([0, h/2]) offset(r) offset(-r) square([w, h], center=true);

module wrist_pin() {
    h = shaft[0];
    shaft_len = L - head_len;            // shaft runs from -L/2 up to head
    difference() {
        union() {
            translate([0, -head_len/2, 0]) pin_shaft(shaft_len, shaft);
            translate([0, L/2 - head_len/2, 0]) rr_rod(head_len, head_w, h, head_r);
            translate([0, -L/2 + foot_len/2, 0]) rr_rod(foot_len, foot_w, h, foot_r);
        }
        translate([0, -L/2 + fork/2, h/2])
            cube([slot_w, fork + eps, h + 2*eps], center=true);
    }
}

wrist_pin();
