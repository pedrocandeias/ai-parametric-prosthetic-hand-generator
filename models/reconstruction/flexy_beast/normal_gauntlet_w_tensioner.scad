// ============================================
// Project: Flexy Beast — Forearm Gauntlet w/ Tensioner (parametric reconstruction)
// Description: Parametric rebuild of Normal_Gauntlet_w_Tensioner.stl
//   Core cuff = anatomical wall cross-sections lofted along the forearm axis (Y).
//   Features (straps, tensioner boss, crenellations, holes) layered parametrically.
//   The cuff cross-sections in profiles.scad were extracted from the source mesh
//   (angular outer/inner wall sampling) and smoothed; everything else is synthetic.
//   Geometric accuracy vs source mesh ~75% (organic anatomical shell; the open
//   wrist-rim scoop and the hollow tensioner cavity are approximated).
//   Coordinate frame matches the source STL: X=width, Y=forearm axis, Z=dorsal up.
// Author: Claude Code + Pedro Candeias
// ============================================

include <BOSL2/std.scad>
include <gauntlet_profiles.scad>   // station_y[], cuff_profiles[] — extracted (X,Z) wall loops
include <gauntlet_straps.scad>     // strap_stations[] = [y,xmin,xmax,zmin,zmax]; tip-hole params

// --- Global parameters ---
xy_scale   = 1.0;   // uniform scale of the cuff cross-section (anthropometric knob)
len_scale  = 1.0;   // scale along forearm axis
$fn        = 48;
eps        = 0.01;

// --- Feature toggles (built up phase by phase) ---
show_straps      = true;
show_boss        = true;
show_crenels     = true;
show_holes       = true;

// --- Assembly ---
gauntlet();

// --- Verification echo (source mesh: 49.9 x 111.1 x 41.0 mm) ---
echo(str("Gauntlet built. Cuff stations: ", len(cuff_profiles),
         " | scale xy=", xy_scale, " len=", len_scale));

module gauntlet() {
    difference() {
        union() {
            cuff_shell();
            if (show_straps) straps();
            if (show_boss)   tensioner_boss();
        }
        if (show_crenels) crenellations();
        if (show_holes)   dorsal_holes();
    }
}

// ---- Phase 1: core lofted cuff shell ----
module cuff_shell() {
    // Build 3D profiles: each (X,Z) loop placed at its station Y.
    profs = [
        for (i = [0:len(cuff_profiles)-1])
            [ for (p = cuff_profiles[i])
                [ p[0]*xy_scale, station_y[i]*len_scale, p[1]*xy_scale ] ]
    ];
    skin(profs, slices=0, caps=true);
}

// ---- Phase 2: distal straps/tongues ----
// Each strap = solid ~4mm panel, lofted from per-station bbox (rounded-rect),
// running from the cuff base (y=-30) out to the rounded tip (y=-58), pierced
// near the tip by a hole through the panel thickness (X axis).
strap_corner_r = 1.6;   // rounding of the panel cross-section corners

// only loft the genuine panel stations (y <= -30); upper ones blend into arch
function strap_rows() = [ for (s = strap_stations) if (s[0] <= -30 + eps) s ];

module one_strap(mir) {       // mir = +1 right, -1 left
    rows = strap_rows();
    scale([mir,1,1])
    difference() {
        // loft consecutive cross-sections with hull chain (robust for solid panels)
        for (i = [0:len(rows)-2])
            hull() { slab(rows[i]); slab(rows[i+1]); }
        // tip hole through panel thickness (X)
        translate([0, strap_hole_y*len_scale, strap_hole_z*xy_scale])
            rotate([0,90,0]) cylinder(h=80, d=strap_hole_d, center=true);
    }
}
module slab(s) {              // 0.6mm-thin slab of a strap cross-section at its Y
    w=(s[2]-s[1]); h=(s[4]-s[3]); cx=(s[1]+s[2])/2; cz=(s[3]+s[4])/2;
    r=min(strap_corner_r, w/2-0.01, h/2-0.01);
    translate([cx*xy_scale, s[0]*len_scale, cz*xy_scale])
        rotate([90,0,0]) linear_extrude(0.6, center=true)
        offset(r=r) offset(r=-r) square([w*xy_scale, h*xy_scale], center=true);
}

module straps() {
    one_strap(1);   // right
    one_strap(-1);  // left
}
// ---- Phase 3: tensioner boss ----
// Raised rounded pad on the dorsal surface near the proximal end.
boss_cx     = 0.3;    // footprint centre X
boss_cy     = 28.5;   // footprint centre Y
boss_width  = 29.5;   // X extent
boss_length = 20.0;   // Y extent
boss_top_z  = 23.4;   // pad top height
boss_base_z = 13.5;   // embeds into the dorsal wall below
boss_round  = 4.0;    // corner / top-edge rounding

module tensioner_boss() {
    h = boss_top_z - boss_base_z;
    translate([boss_cx*xy_scale, boss_cy*len_scale, (boss_base_z+boss_top_z)/2*xy_scale])
        cuboid([boss_width*xy_scale, boss_length*len_scale, h],
               rounding=boss_round, except=BOTTOM, $fn=32);
}
// ---- Phase 4: crenellation slots + dorsal holes ----
// 5 triangular slots cut through the boss's distal (front) lip.
crenel_x      = [-11.4, -5.0, 0.6, 6.8, 12.4];  // slot centre X positions
crenel_z_base = 15.5;   // triangle base height
crenel_z_apex = 21.0;   // triangle apex height
crenel_w      = 4.6;    // base width (X)
crenel_y0     = 14.0;   // cut start (Y) — outside boss front
crenel_y1     = 22.5;   // cut end   (Y) — into boss body

module crenellations() {
    for (xc = crenel_x)
        translate([xc*xy_scale, crenel_y1*len_scale, 0])
            rotate([90,0,0])             // triangle in X-Z, extrudes toward -Y
            linear_extrude((crenel_y1-crenel_y0)*len_scale)
            polygon([[-crenel_w/2*xy_scale, crenel_z_base*xy_scale],
                     [ crenel_w/2*xy_scale, crenel_z_base*xy_scale],
                     [ 0,                    crenel_z_apex*xy_scale]]);
}

// 2 round holes through the dorsal wall, axis radial (X-Z plane).
hole_x = 12.6; hole_y = 8.5; hole_z = 12.0; hole_d = 3.5;

module dorsal_holes() {
    ang = atan2(hole_z, hole_x);         // radial direction in X-Z (up-out)
    for (sx = [1,-1])
        scale([sx,1,1])
        translate([hole_x*xy_scale, hole_y*len_scale, hole_z*xy_scale])
            rotate([0, 90-ang, 0])       // point cylinder axis along (cos ang,0,sin ang)
            cylinder(h=40, d=hole_d, center=true);
}
