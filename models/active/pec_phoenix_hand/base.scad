// ============================================
// Project: base.stl reconstruction
// Description: Two-bolt mounting flange with a hollow rectangular
//              socket protruding from a thickened central body.
// Author: Claude Code + User
// ============================================
// Original STL frame:  width=X (+-12.5), depth=Y (0 .. -15), height=Z (+-25)
// Modeled in a local frame (local x=width, local y=height), extruded along
// local +Z (=depth); rotate([90,0,0]) maps local +Z -> global -Y.

$fn = 128;
eps = 0.01;

// --- Flange outline (hexagonal diamond, two rounded lugs) ---
lug_r   = 6.5;     // [mm] lug radius
lug_z   = 18.5;    // [mm] lug centre height (+-)
tip_x   = 12.5;    // [mm] left/right vertex X
tip_z   = 2.02;    // [mm] half-height of vertical side edge

// --- Depths (along Y) ---
plate_t     = 3.0;     // [mm] thin lug-tab / front plate thickness
body_t      = 5.0;     // [mm] thickened central body thickness
body_clip_z = 16.5;    // [mm] central body half-height (lugs excluded)
total_depth = 15.0;    // [mm] overall Y depth

// --- Socket / window ---
box_w   = 13.2;    // [mm] socket outer width  (X)
box_h   = 28.2;    // [mm] socket outer height (Z)
win_w   = 10.0;    // [mm] window/bore width  (X)
win_h   = 25.0;    // [mm] window/bore height (Z)

bolt_d  = 4.2;     // [mm]

module flange() {
    hull() {
        translate([0,  lug_z]) circle(r = lug_r);
        translate([0, -lug_z]) circle(r = lug_r);
        translate([ tip_x,  tip_z]) circle(r = eps);
        translate([ tip_x, -tip_z]) circle(r = eps);
        translate([-tip_x,  tip_z]) circle(r = eps);
        translate([-tip_x, -tip_z]) circle(r = eps);
    }
}

// central body = diamond clipped to the mid band (lugs removed)
module body_outline() {
    intersection() {
        flange();
        square([2*tip_x + 2, 2*body_clip_z], center = true);
    }
}

module solid_body() {
    union() {
        linear_extrude(plate_t) flange();                          // full diamond, 3mm
        linear_extrude(body_t)  body_outline();                    // thick central body
        translate([0, 0, body_t])
            linear_extrude(total_depth - body_t)
                square([box_w, box_h], center = true);             // socket
    }
}

rotate([90, 0, 0])
difference() {
    solid_body();
    translate([0, 0, -eps])
        linear_extrude(total_depth + 2*eps)
            square([win_w, win_h], center = true);                 // through window
    for (s = [1, -1])
        translate([0, s*lug_z, -eps])
            linear_extrude(body_t + 2*eps)
                circle(d = bolt_d);                                // bolt holes
}

echo(str("BBOX target 25 x 15 x 50"));
