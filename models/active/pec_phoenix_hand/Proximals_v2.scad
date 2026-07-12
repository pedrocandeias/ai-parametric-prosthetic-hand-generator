// ============================================
// Project: e-NABLE Proximal Phalanx (single piece)
// Reconstructed from Proximals.stl (one of 5 identical pieces, recentered to origin)
//
// Readable parametric build (boxes, cylinders, hulls only):
//   - body     : a flat-bottomed box whose top is rounded into a tombstone by
//                intersecting with a long cylinder; gently domed along its length
//   - knuckles : a round circle fused at each Y end (teardrop blend into body)
//   - holes    : a cross-wise pin hole through each knuckle + one long bottom
//                bore running the whole length, near the flat bottom
//   - fins     : a tilted clip tab on each top shoulder
// Frame: X = width, Y = finger length, Z = height (Z0 = flat bottom)
// "front" = +Y end, "rear" = -Y end.
// ============================================

$fn = 96;
epsilon = 0.01;

// --- Knuckle circles (one round end at each Y end) ---
knuckle_thickness     = 5.2;             // disc thickness in X (both knuckles)
knuckle_center_height = 6.0;             // disc center Z -> disc sits on the flat bottom (both)
// front (+Y, green) knuckle
front_knuckle_offset_y     = 11.25;      // hole / disc center distance from the middle
front_knuckle_radius       = 6.0;        // disc radius
front_knuckle_blend_radius = 4.7;        // radius where the knuckle blends into the body
front_knuckle_blend_y      = 6.5;        // Y of that blend disc (the teardrop join)
front_knuckle_top_z        = 10.1;       // flat-top height at the disc center
front_knuckle_top_slope    = -7.0;         // deg, top declines toward the tip (body meets it at 90deg)
// rear (-Y, orange) knuckle
rear_knuckle_offset_y      = 11.78;
rear_knuckle_radius        = 6.0;
rear_knuckle_blend_radius  = 6.0;
rear_knuckle_blend_y       = 6.5;
rear_knuckle_top_z         = 11.95;     // cut at the flat-top level
rear_knuckle_top_slope     = -1.5;      // small incline
// rectangular pocket carved into the rear (orange) knuckle disc (center + size)
disc_pocket_x     = 0.0;    // X center (disc faces are at +-2.6)
disc_pocket_y     = -17.0;    // Y center
disc_pocket_z     = 4.5;    // Z center
disc_pocket_len_x = 2.4;    // X size (depth/thickness)
disc_pocket_len_y = 2.0;    // Y size
disc_pocket_len_z = 10.0;   // Z size
// central slot cut into each knuckle's underside, leaving two flat-bottom rails
rail_slot_width = 2.4;                   // X gap between the two rails
rail_slot_top   = 3.3;                   // Z the slot rises to from the bottom
// two rails run the whole length along the bottom (between the slot and the
// knuckle edge), giving the flat-bottom-with-two-rails underside
rail_outer_x = knuckle_thickness/2;      // outer X edge of each rail
rail_length  = front_knuckle_offset_y + rear_knuckle_offset_y;  // hole center to hole center

// --- Body (central box, tapered along its length) ---
body_width        = 12.4;                // widest width in X (used for clearances)
body_width_rear   = 12.4;                // X width at the -Y end
body_width_mid    = 12.4;                // X width at the mid station (measured off the mesh)
body_mid_y        = -4.4;                // Y of the mid station: full width holds until here,
                                         // then the plan pulls in faster toward the front
body_width_front  = 10.2;                // X width at the +Y end (body narrows toward +Y)
body_front_y      = 7.25;                // +Y edge of the body block (red-fin side)
body_rear_y       = -7.85;               // -Y edge of the body block (purple-fin side)
body_length       = body_front_y - body_rear_y;     // derived length in Y
body_center_y     = (body_front_y + body_rear_y)/2; // derived Y center
body_raw_height   = 16.0;                // box height before the top is rounded off
// crown domes the X-Z top; it is lofted (hull) from a curvier front cross-section
// to a flatter, taller rear one, so the rear top is a wider/flatter arch
front_crown_radius        = 10.9;        // front dome radius (curvier)
front_crown_center_height = 2.8;         // front dome Z center
rear_crown_radius         = 12.9;        // rear dome radius (flatter -> higher flanks)
rear_crown_center_height  = 2.6;         // rear dome Z center (peak = r + center)
// belly: rounds the X-Z bottom corners, lofted (hull of two circles — fingerator
// idiom: profile hulled from scaled circles) from a bigger rear circle to a
// smaller, lower front one, so the underside sides tuck in toward the front
// (keel half-width at a station = sqrt(radius^2 - center_z^2))
belly_radius_rear    = 6.43;             // rear circle radius
belly_center_rear_z  = 4.42;             // rear circle Z center
belly_radius_front   = 4.97;             // front circle radius (smaller -> tucked-in)
belly_center_front_z = 3.76;             // front circle Z center
belly_fill_lift      = 0.6;              // full-width fill starts this far above the local center
lengthwise_dome_radius        = 60.0;    // radius of the long-axis cylinder that domes the top
lengthwise_dome_peak          = 15.8;    // top height at the dome's peak
lengthwise_dome_center_height = lengthwise_dome_peak - lengthwise_dome_radius;
lengthwise_dome_center_y      = -5.0;    // Y of the peak (negative -> top tilts up toward the rear)
// barrel sides: an ellipse-section cylinder (axis Y) that curves the X-Z sides so
// the body bulges at mid-height and tapers toward top/bottom (a flat barrel)
barrel_half_x   = 6.6;    // X half-axis (max side half-width, at mid-height)
barrel_half_z   = 10.0;   // Z half-axis (large -> a flat, gentle barrel)
barrel_center_z = 7.5;    // height of the barrel's widest point
// underside: each end is a concave ellipse-scaled, slightly tilted cylinder scoop
// (cylinder axis along X — fingerator idiom, phalanx_body relief) so the body
// keeps a central keel and each underside sweeps up on a steep wall toward its
// knuckle. The pair is ASYMMETRIC (measured off the mesh): the rear wall foots
// at y~-3.9, the front (deeper) at y~+4.2.
// Each scoop = ellipse ∩ a near-vertical FOOT plane (the original wall foots on
// an almost-planar face: rear (-3.85,z0)..(-4.5,z7.05) = 5.3 deg off vertical).
rear_scoop_center_y  = -10.08;  // ellipse center Y
rear_scoop_center_z  =  1.11;   // ellipse center Z
rear_scoop_half_y    =  6.15;   // ellipse Y semi-axis (small -> steep wall)
rear_scoop_half_z    = 11.83;   // ellipse Z semi-axis
rear_scoop_tilt      = -4.66;   // deg about X
rear_scoop_foot_y    = -3.85;   // foot plane Y at Z0 (no cut forward of it)
rear_scoop_foot_tilt =  5.3;    // foot plane lean (deg about X)
front_scoop_center_y = 10.04;
front_scoop_center_z =  2.91;
front_scoop_half_y   =  6.32;
front_scoop_half_z   =  9.80;
front_scoop_tilt     =  6.38;
front_scoop_foot_y   =  4.00;
front_scoop_foot_tilt = -1.1;
// rear pocket: a flat recess carved into the body top so the purple fin block
// seats into it and fuses flush (instead of perching on the domed top)
rear_pocket_center_y = -8.0;
rear_pocket_width    = 5.4;    // X
rear_pocket_length   = 10.0;   // Y
rear_pocket_floor_z  = 11.95;  // recess floor height (flush with the orange knuckle top)
rear_pocket_corner_r = 2.0;    // rounded corner radius of the pocket footprint

// --- Pin holes (one across each knuckle, along X) ---
pin_hole_radius = 2.33;

// --- Bottom bore: a short circular channel in the CENTRAL body (not full length) ---
bore_radius = 1.12;
bore_height = 2.15;                       // center height above the flat bottom
bore_y_lo   = -4.0;                       // channel start (toward -Y)
bore_y_hi   =  3.5;                       // channel end (toward +Y)

// --- Top clip fins (a tilted tab sitting on each knuckle shoulder) ---
// A fin is a rounded box of width (X) x length (along the tab) x height (Z),
// centered at (center_y, center_z), then tilted about X by tilt degrees.
// center_z is measured from the flat bottom; the tab grows +-height/2 around it.
fin_rounding = 0.5;     // tab edge rounding
fin_cap_rounding = 0.78;


// front (+Y) clip — shown RED
front_fin_center_y = 12.8;
front_fin_center_z = 9.83;
front_fin_width    = 2.5;   // X
front_fin_length   = 8.2;     // along the tab (mostly Y)
front_fin_height   = 6.0;     // Z (before tilt)
front_fin_tilt     = -15.0;   // degrees about X (leans down toward +Y)


// --- Fin caps (a cube fused on top of each fin, centered in X and Y on the fin) ---
front_fin_cap_width  = 2.7;   // X  (slightly wider than the fin)
front_fin_cap_length = 8.5;   // along the tab (slightly longer than the fin)
front_fin_cap_height = 1.6;   // Z
front_fin_cap_tilt   = 1.5;  // extra lean about X, relative to the fin below it


// rear (-Y) clip — shown PURPLE. Built from a Y-Z profile (a trapezoid): a vertical
// rear face, an angled-back front face, and a flat sloped top — extruded along X.
// Parameterized like the front fin: center_y + width/length/height, plus the two
// shape params (top slope and front chamfer) the trapezoid needs.
rear_fin_center_y    = -8.35;   // tab center Y
rear_fin_base_z      = 11.6;    // bottom of the tab (sinks into the body to fuse)
rear_fin_width       = 2.6;     // X
rear_fin_length      = 6.8;     // Y (rear edge to front edge)
rear_fin_height      = 3.6;     // Z (base to the rear-top)
rear_fin_rear_flat_y = -11.5;   // Y where the rear end is clipped flat (cap rear not round)
rear_fin_top_drop    = 0.9;     // how much the top is lower at the front than the rear
rear_fin_front_chamfer = -0.1;  // how far the front face slopes back going up (+ = back)
rear_fin_rounding    = 0.7;     // edge rounding of the profile

// rear cap = a small raised lip at the rear-top of the purple fin
rear_fin_cap_width    = 2.8;   // X
rear_fin_cap_length   = 7.6;   // Y length of the lip
rear_fin_cap_height   = 1.3;   // Z thickness of the lip
rear_fin_cap_y        = -8.2;  // Y center of the lip
rear_fin_cap_z        = 15.25; // Z center of the lip
rear_fin_cap_rotation = -6.0;     // tilt about X (deg)
rear_fin_cap_top_round    = 0.5;  // fillet on the cap's top edge
rear_fin_cap_bottom_round = 0.5;  // fillet on the cap's bottom edge

// --- Part colors (shown in the F5 preview) ---
color_body         = "SteelBlue";
color_front_knuckle = "MediumSeaGreen";   // +Y circle
color_rear_knuckle  = "Orange";           // -Y circle
color_front_fin     = "Crimson";          // red  clip over the +Y knuckle
color_rear_fin      = "MediumPurple";     // purple clip over the -Y knuckle
show_colors         = true;               // false -> plain single-color model
show_disc_pocket    = false;              // overlay the disc pocket box (visual aid)
color_disc_pocket   = [1, 0, 1, 0.45];    // translucent magenta

// --- Comparison overlay ---
show_original = true;                      // ghost the original mesh to compare against
original_stl  = "Proximals_single.stl";    // recentered single part, sits at origin (single-piece view)
original_set_stl    = "../models/Proximals.stl";        // the full 5-piece original (set view)
original_set_offset = [-54.186, -72.597, 0.170];        // aligns its part1 with our origin

// --- Per-piece overrides (special vars; default = standard piece 1-4) ---
// The 5 proximals are identical except piece 0: wider body + its own rear fin/cap.
$wscale = 1;       // body width multiplier (piece 0 is wider; knuckles unchanged)
$wide   = false;   // true -> render the wide piece's own rear fin + cap (vars below)
show_set = false;  // false: single piece (+ghost);  true: all 5 in a row

// --- Wide piece (part 0) rear fin + cap: fully independent, tune manually ---
// Each is a simple positioned/sized/oriented box. tilt = lean about X, rotation = yaw about Z.
wide_fin_x = 0.0;    
wide_fin_y = -8.6;   
wide_fin_z = 13.4;     // tab position
wide_fin_width = 2.6;  
wide_fin_length = 6.6;  
wide_fin_height = 3.8;  // tab size
wide_fin_tilt = -8.0;    
wide_fin_rotation = 0.0;                  // tab orientation
wide_fin_cap_x = 0.0;  
wide_fin_cap_y = -9.0;  
wide_fin_cap_z = 16.0;    // cap position
wide_fin_cap_width = 2.8; 
wide_fin_cap_length = 6.0;
wide_fin_cap_height = 1.3;  // cap size
wide_fin_cap_tilt = -16.0; 
wide_fin_cap_rotation = 0.0;          // cap orientation

// --- Assembly ---
// An external driver can set no_assembly=true (before `include`) to suppress this
// top-level render and drive the modules itself (e.g. to export just the wide piece).
if (is_undef(no_assembly) || !no_assembly)
if (show_set) {
    proximal_set();
    if (show_original) translate(original_set_offset) %import(original_set_stl);
} else {
    proximal();
    if (show_original) %import(original_stl);
    if (show_disc_pocket) color(color_disc_pocket) rear_disc_pocket();
}

// All five proximals in the original layout: four standard + one wide (piece 0).
module proximal_set() {
    wide_wscale = 16.11/12.14;   // piece-0 body is ~4 mm wider
    translate([-15.5, 0, 0])
        let($wscale = wide_wscale, $wide = true)   // wider body + its own rear fin/cap
            proximal();
    translate([  0.0, 0, 0]) proximal();
    translate([ 13.75,0, 0]) proximal();
    translate([ 27.5, 0, 0]) proximal();
    translate([ 41.25,0, 0]) proximal();
}

module proximal() {
    difference() {
        union() {
            tint(color_body)          body();
            tint(color_body)          rails();
            tint(color_front_knuckle) knuckle( front_knuckle_offset_y, front_knuckle_radius,
                                               front_knuckle_blend_radius,  front_knuckle_blend_y,
                                               front_knuckle_top_z, front_knuckle_top_slope);
            tint(color_rear_knuckle)  knuckle(-rear_knuckle_offset_y,  rear_knuckle_radius,
                                               rear_knuckle_blend_radius,  -rear_knuckle_blend_y,
                                               rear_knuckle_top_z, rear_knuckle_top_slope);
            tint(color_front_fin)     front_fin();
            if ($wide) tint(color_rear_fin) wide_rear_fin();
            else       tint(color_rear_fin) rear_fin();
            tint(color_body)          green_cube();   // integrated into the blue body
        }
        // holes — cut last
        pin_hole( front_knuckle_offset_y);
        pin_hole(-rear_knuckle_offset_y);
        bottom_bore();
        rear_disc_pocket();
    }
}

// Rectangular pocket carved into the rear knuckle disc (a box: center + size)
module rear_disc_pocket() {
    translate([disc_pocket_x, disc_pocket_y, disc_pocket_z])
        cube([disc_pocket_len_x, disc_pocket_len_y, disc_pocket_len_z], center = true);
}

// Apply a reference color only when show_colors is on
module tint(c) {
    if (show_colors) color(c) children();
    else children();
}

// Flat-bottomed box, top rounded into a tombstone (crown cylinder), then
// gently domed front-to-back by a large long-axis cylinder.
module body() {
    difference() {
        intersection() {
            tapered_body_block();                                           // box, narrower at +Y
            crown_round();                                                  // rounds only the X-Z top
            belly_round();                                                  // rounds only the X-Z bottom
            barrel_sides();                                                 // curves the X-Z sides (barrel)
            translate([0, lengthwise_dome_center_y, lengthwise_dome_center_height])  // domes the top
                rotate([0, 90, 0]) cylinder(r = lengthwise_dome_radius, h = body_width*$wscale + 2, center = true);
        }
        underside_scoop(front_scoop_center_y, front_scoop_center_z,   // +Y underside (deeper)
                        front_scoop_half_y, front_scoop_half_z, front_scoop_tilt,
                        front_scoop_foot_y, front_scoop_foot_tilt, +1);
        underside_scoop(rear_scoop_center_y, rear_scoop_center_z,     // -Y underside (shallower)
                        rear_scoop_half_y, rear_scoop_half_z, rear_scoop_tilt,
                        rear_scoop_foot_y, rear_scoop_foot_tilt, -1);
        rear_fin_pocket();                  // recess for the purple fin to seat into
    }
}

// An ellipse-section cylinder (axis along Y) that curves the body's X-Z sides into
// a flat barrel (widest at barrel_center_z, tapering toward top and bottom).
module barrel_sides() {
    translate([0, body_center_y, barrel_center_z])
        scale([barrel_half_x * $wscale, 1, barrel_half_z])
            rotate([90, 0, 0])
                cylinder(r = 1, h = body_length + 4, center = true, $fn = 128);
}

// Concave ellipse-scaled, tilted cylinder scoop carved from one end's underside
// (cylinder axis along X): rotate(tilt) scale([1, half_y, half_z]) over a unit
// cylinder — a steep, curved wall sweeping up toward that knuckle
// (fingerator idiom: tilted ellipse-scaled cylinder subtracted as a relief).
// The cut is clipped by a near-vertical FOOT plane through (foot_y, z0), leaned
// by foot_tilt about X, so the wall foots abruptly like the original.
// side: +1 = front scoop (cut lives at y > foot), -1 = rear (y < foot).
module underside_scoop(center_y, center_z, half_y, half_z, tilt,
                       foot_y, foot_tilt, side) {
    intersection() {
        translate([0, center_y, center_z]) rotate([tilt, 0, 0])
            scale([1, half_y, half_z]) rotate([0, 90, 0])
                cylinder(r = 1, h = body_width*$wscale + 4, center = true, $fn = 128);
        translate([0, foot_y, 0]) rotate([foot_tilt, 0, 0])
            translate([0, side * 30, 0])
                cube([body_width*$wscale + 6, 60, 70], center = true);
    }
}

// A flat-floored recess (rounded-rectangle footprint) carved into the body top
// so the rear fin seats and fuses
module rear_fin_pocket() {
    translate([0, rear_pocket_center_y, rear_pocket_floor_z])
        linear_extrude(height = 20)
            offset(r = rear_pocket_corner_r)
                square([rear_pocket_width  - 2*rear_pocket_corner_r,
                        rear_pocket_length - 2*rear_pocket_corner_r], center = true);
}

// The crown rounding: a dome that rounds the X-Z top, LOFTED (hull) from a curvier
// front cross-section to a flatter rear one, plus a full box below so the lower
// body stays full and reaches the flat bottom (Z0).
module crown_round() {
    hull() {
        translate([0, body_front_y, front_crown_center_height])
            rotate([90, 0, 0]) cylinder(r = front_crown_radius, h = 0.1, center = true);
        translate([0, body_rear_y, rear_crown_center_height])
            rotate([90, 0, 0]) cylinder(r = rear_crown_radius, h = 0.1, center = true);
    }
    crown_base_z = max(front_crown_center_height, rear_crown_center_height);
    translate([0, body_center_y, crown_base_z/2])
        cube([body_width*$wscale + 2, body_length + 2, crown_base_z], center = true);
}

// The belly rounding: rounds the X-Z bottom corners (leaving a flat keel at Z0),
// LOFTED (hull) from a bigger rear circle to a smaller, lower front one so the
// underside tucks in toward the front, plus a full-width wedge just above the
// (slanted) centerline so the upper body stays full. Stations sit 1 beyond each
// body end, linearly extrapolated so the interior loft matches the measurements.
module belly_round() {
    dr = (belly_radius_front    - belly_radius_rear)   / body_length;  // per-mm slopes
    dz = (belly_center_front_z  - belly_center_rear_z) / body_length;
    hull() {
        translate([0, body_rear_y - 1, belly_center_rear_z - dz]) rotate([90, 0, 0])
            cylinder(r = (belly_radius_rear - dr) * $wscale, h = 0.1, center = true);
        translate([0, body_front_y + 1, belly_center_front_z + dz]) rotate([90, 0, 0])
            cylinder(r = (belly_radius_front + dr) * $wscale, h = 0.1, center = true);
    }
    hull() {
        translate([0, body_rear_y - 1,
                   belly_center_rear_z - dz + belly_fill_lift + body_raw_height/2])
            cube([body_width*$wscale + 2, 0.1, body_raw_height], center = true);
        translate([0, body_front_y + 1,
                   belly_center_front_z + dz + belly_fill_lift + body_raw_height/2])
            cube([body_width*$wscale + 2, 0.1, body_raw_height], center = true);
    }
}

// The body block: a flat-bottomed prism whose plan tapers on a convex curve —
// a 3-station hull (rear / mid / front plates): the plan holds full width from
// the rear to body_mid_y, then pulls in faster toward the front knuckle
// (fingerator idiom: plan profile hulled from measured stations).
module tapered_body_block() {
    rear_y  = body_center_y - body_length/2;
    front_y = body_center_y + body_length/2;
    hull() {
        translate([0, rear_y,  body_raw_height/2])
            cube([body_width_rear  * $wscale, 0.01, body_raw_height], center = true);
        translate([0, body_mid_y, body_raw_height/2])
            cube([body_width_mid   * $wscale, 0.01, body_raw_height], center = true);
        translate([0, front_y, body_raw_height/2])
            cube([body_width_front * $wscale, 0.01, body_raw_height], center = true);
    }
}

// Round knuckle disc (axis along X), blended toward the body as a teardrop.
// A central slot is cut from its underside so the bottom reads as two rails.
module knuckle(center_y, radius, blend_radius, blend_y, top_z, top_slope) {
    difference() {
        hull() {
            translate([-knuckle_thickness/2, center_y, knuckle_center_height]) rotate([0,90,0])
                cylinder(h = knuckle_thickness, r = radius);
            translate([-knuckle_thickness/2, blend_y, knuckle_center_height]) rotate([0,90,0])
                cylinder(h = knuckle_thickness, r = blend_radius);
        }
        rail_slot();
        // flatten the top to an inclined plane (so the body meets it at a 90deg step)
        translate([0, center_y, top_z]) rotate([top_slope, 0, 0])
            translate([0, 0, 30]) cube([60, 90, 60], center = true);
    }
}

// The central bottom slot between the two rails (cut from the knuckles only, so the
// body keel still fills it in the middle). The ceiling is a round arch (a half-pipe)
// rather than flat: a box open to the bottom, topped by a cylinder along Y.
module rail_slot() {
    pipe_r = rail_slot_width/2;            // channel radius (peaks at rail_slot_top)
    zc     = rail_slot_top - pipe_r;       // cylinder axis height
    translate([0, 0, (zc - 0.5)/2])
        cube([rail_slot_width, 60, zc + 0.5], center = true);
    translate([0, 0, zc]) rotate([90, 0, 0])
        cylinder(r = pipe_r, h = 60, center = true, $fn = 64);
}

// Two flat-bottom rails running the whole length, from the slot edge out to the
// knuckle edge, so the underside reads as a flat bottom with two rails.
module rails() {
    inner = rail_slot_width/2;
    for (side = [1, -1])
        translate([side * (inner + rail_outer_x)/2, 0, rail_slot_top/2])
            cube([rail_outer_x - inner, rail_length, rail_slot_top], center = true);
}

module pin_hole(center_y) {
    translate([-20, center_y, knuckle_center_height]) rotate([0,90,0])
        cylinder(h = 40, r = pin_hole_radius);
}

module bottom_bore() {
    // a short circular channel spanning bore_y_lo..bore_y_hi (the central body only)
    translate([0, bore_y_hi, bore_height]) rotate([90,0,0])
        cylinder(h = bore_y_hi - bore_y_lo, r = bore_radius);
}

// Each fin = the tilted tab + a cap fused on top. The tab leans by *_fin_tilt;
// the cap sits on the tab top and adds its own *_fin_cap_tilt on top of that.
// A small block the width of the green knuckle, integrating the body toward it
module green_cube() {
    translate([0, front_knuckle_offset_y - 5, front_knuckle_top_z + 1.5])
        cube([knuckle_thickness, 2, 3], center = true);
}

module front_fin() {
    fin_frame(front_fin_center_y, front_fin_center_z, front_fin_tilt) {
        rounded_box(front_fin_width, front_fin_length, front_fin_height);     // the tab
        translate([0, 0, front_fin_height/2])                                 // cap on the tab top
            rotate([front_fin_cap_tilt, 0, 0])                                // extra lean, relative to the tab
                rounded_fin_cap(front_fin_cap_width, front_fin_cap_length, front_fin_cap_height);
    }
}
// Purple fin: a Y-Z trapezoid profile (vertical rear, angled front, sloped top)
// extruded along X, plus a small raised lip at the rear-top. The four corners are
// derived from center_y + length/height + top_drop + front_chamfer.
module rear_fin() {
    rear_y     = rear_fin_center_y - rear_fin_length/2;   // rear edge (anchored at the disc)
    front_y    = rear_fin_center_y + rear_fin_length/2;   // front edge
    top_rear_z = rear_fin_base_z + rear_fin_height;       // top at the rear
    front_top_y = front_y - rear_fin_front_chamfer;
    front_top_z = top_rear_z - rear_fin_top_drop;
    w     = rear_fin_width;
    mid_y = (rear_y + front_y)/2;                         // split point: rear stays sharp
    corners = [[rear_y, rear_fin_base_z], [rear_y, top_rear_z],
               [front_top_y, front_top_z], [front_y, rear_fin_base_z]];
    // tab and cap fused (union -> connected but each keeps its own tapered geometry),
    // then the REAR end is clipped flat at rear_fin_rear_flat_y so the cap's rear is
    // flat (not round) while the front stays rounded.
    intersection() {
        union() {
            // tab = the sharp Y-Z trapezoid (extruded along X) intersected with an X-Y
            // footprint whose FRONT corners are rounded -> rounds the front SIDE edges only.
            intersection() {
                rotate([90, 0, 90])
                    linear_extrude(height = w, center = true) polygon(corners);
                linear_extrude(height = 2*top_rear_z + 4, center = true)
                    union() {
                        offset(r = rear_fin_rounding) offset(delta = -rear_fin_rounding)
                            polygon([[-w/2, rear_y], [w/2, rear_y], [w/2, front_y], [-w/2, front_y]]);
                        polygon([[-w/2, rear_y], [w/2, rear_y], [w/2, mid_y], [-w/2, mid_y]]);  // sharp rear
                    }
            }
            // the cap lip, fused on top
            translate([0, rear_fin_cap_y, rear_fin_cap_z])
                rotate([rear_fin_cap_rotation, 0, 0])
                    rear_fin_cap_solid(rear_fin_cap_width, rear_fin_cap_length, rear_fin_cap_height);
        }
        // flat rear clip (keeps everything forward of rear_fin_rear_flat_y)
        translate([0, rear_fin_rear_flat_y + 50, 0]) cube([100, 100, 100], center = true);
    }
}

// The rear cap: a slab with rounded vertical edges (fin_cap_rounding) plus filleted
// top and bottom edges (their own radii) — a hull of a bottom rim and a top rim.
module rear_fin_cap_solid(w = rear_fin_cap_width, len = rear_fin_cap_length, h = rear_fin_cap_height) {
    tr = rear_fin_cap_top_round;
    br = rear_fin_cap_bottom_round;
    hull() {
        translate([0, 0, -h/2 + br]) cap_rim(w, len, br);
        translate([0, 0,  h/2 - tr]) cap_rim(w, len, tr);
    }
}

// Wide piece (part 0) rear fin: a tab box + a cap slab, each fully independent
// (its own x/y/z, width/length/height, tilt about X, rotation about Z).
module wide_rear_fin() {
    // tab, clipped to live strictly inside the cap's downward "shadow" — the beveled cap
    // solid swept straight down. This bounds the tab by the cap's real (curved) top surface
    // and its footprint everywhere, so the tab can never poke through the cap no matter how
    // the tab/cap tilts differ. The body fills in below.
    intersection() {
        translate([wide_fin_x, wide_fin_y, wide_fin_z])
            rotate([wide_fin_tilt, 0, wide_fin_rotation])
                rounded_box(wide_fin_width, wide_fin_length, wide_fin_height);
        hull() {
            wide_cap_solid();
            translate([0, 0, -40]) wide_cap_solid();
        }
    }
    wide_cap_solid();
}

// The wide piece's cap: the rounded slab, with its back (outer) end sheared in the cap's
// OWN tilted frame. The cut is DIAGONAL (the half-space is rotated about X around the cut
// line), so the back face bevels like the ghost instead of cutting straight across.
// 0.8 = how far in from the cap's rear edge the bevel starts; -35 = bevel angle.
module wide_cap_solid() {
    translate([wide_fin_cap_x, wide_fin_cap_y, wide_fin_cap_z])
        rotate([wide_fin_cap_tilt, 0, wide_fin_cap_rotation])
            intersection() {
                rear_fin_cap_solid(wide_fin_cap_width, wide_fin_cap_length, wide_fin_cap_height);
                translate([0, -wide_fin_cap_length/2 + 0.8, 0])
                    rotate([-35, 0, 0])
                        translate([0, 50, 0])
                            cube([100, 100, 100], center = true);
            }
}
// A thin rounded rim: the footprint (vertical edges rounded by fin_cap_rounding)
// swept by a sphere of radius r, so its outer Z edge is filleted by r.
module cap_rim(w, l, r) {
    rr = max(r, 0.001);
    minkowski() {
        linear_extrude(0.01)
            offset(r = fin_cap_rounding) offset(delta = -fin_cap_rounding)
                square([w - 2*rr, l - 2*rr], center = true);
        sphere(r = rr);
    }
}

// Place children in a fin's tilted frame (tab + cap live here together)
module fin_frame(center_y, center_z, tilt) {
    translate([0, center_y, center_z]) rotate([tilt, 0, 0]) children();
}

// A flat-topped box with rounded vertical edges (flat top/bottom, rounded X-Y
// corners) — width (X) x length (Y) x height (Z).
module rounded_box(width, length, height) {
    linear_extrude(height = height, center = true)
        offset(r = fin_rounding)
            square([width - 2*fin_rounding, length - 2*fin_rounding], center = true);
}


module rounded_fin_cap(width, length, height) {
    minkowski() {
        cube([width  - 2*fin_cap_rounding,
              length - 2*fin_cap_rounding,
              height - 2*fin_cap_rounding], center = true);
        sphere(r = fin_cap_rounding);
    }
}