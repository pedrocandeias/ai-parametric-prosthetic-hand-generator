// ============================================
// Project: Flexy Beast — Forearm Gauntlet w/ Tensioner (PRIMITIVE rebuild)
// Description: Primitive-shape rebuild of Normal_Gauntlet_w_Tensioner.stl.
//   The cuff is modelled as a HALF-PIPE / TUNNEL: a tapered oval tube (hull of
//   elliptical discs along the forearm axis Y), shelled, with the palmar bottom
//   cut open. Features (straps, tensioner boss, crenellations, holes) layered on.
//   Pure core OpenSCAD primitives — NO BOSL2 — so it runs in OpenSCAD-WASM.
//   Coordinate frame matches the source STL: X=width, Y=forearm axis (+Y wrist),
//   Z=dorsal up.
// Author: Claude Code + Pedro Candeias
// ============================================

include <gauntlet_straps.scad>   // strap_stations[] = [y,xmin,xmax,zmin,zmax]; tip-hole params

// --- Rendering quality ---
$fn  = 64;
eps  = 0.01;

// --- Global parameters ---
wall = 3.0;          // [mm] cuff wall thickness
open_half_x = 17.0;  // [mm] half-width of the palmar opening (legs sit outside this)
open_top_z  = 3.0;   // [mm] how high up the central opening reaches (arch underside)

// --- Feature toggles ---
show_straps   = true;
show_boss     = true;
show_crenels  = true;
show_holes    = true;

// --- Cuff cross-section stations: [y, rx, rz, cz] (outer oval) ---
// rx = X half-width, rz = Z half-height, cz = vertical centre of the oval.
cuff_discs = [
    [-30, 20.8, 16.0, -1.0],   // distal (toward hand)
    [-10, 22.8, 17.0, -0.5],
    [ 10, 24.0, 17.5,  0.0],
    [ 30, 25.0, 18.5,  0.5],   // proximal body (fullest wrap)
    [ 44, 25.0, 17.0, -1.0],   // wrist rim
    [ 50, 23.5, 13.5, -2.5],   // rim mouth (tapers/scoops in)
];

// --- Assembly ---
gauntlet();

module gauntlet() {
    difference() {
        union() {
            cuff_halfpipe();
            if (show_straps) straps();
            if (show_boss)   tensioner_boss();
        }
        if (show_crenels) crenellations();
        if (show_holes)   dorsal_holes();
    }
}

// ---- Cuff: half-pipe tunnel ----
module oval_disc(d, dr=0) {   // d = [y, rx, rz, cz]; dr shrinks radii (for inner shell)
    translate([0, d[0], d[3]])
        rotate([90, 0, 0])
        linear_extrude(0.5, center=true)
        scale([d[1]+dr, d[2]+dr]) circle(r=1);
}

module oval_tube(dr=0) {       // tapered oval solid = hull of consecutive disc pairs
    for (i = [0:len(cuff_discs)-2])
        hull() { oval_disc(cuff_discs[i], dr); oval_disc(cuff_discs[i+1], dr); }
}

module cuff_halfpipe() {
    difference() {
        oval_tube(0);            // outer solid
        oval_tube(-wall);        // hollow the bore
        // cut the palmar opening (centred box) -> ∩ tunnel: legs at the sides
        translate([0, 0, open_top_z - 100])
            cube([2*open_half_x, 400, 200], center=true);
    }
}

// ---- Distal straps/tongues (core primitives) ----
strap_corner_r = 1.6;
function strap_rows() = [ for (s = strap_stations) if (s[0] <= -30 + eps) s ];

module slab(s) {              // thin slab of a strap cross-section at its Y
    w=(s[2]-s[1]); h=(s[4]-s[3]); cx=(s[1]+s[2])/2; cz=(s[3]+s[4])/2;
    r=min(strap_corner_r, w/2-0.01, h/2-0.01);
    translate([cx, s[0], cz])
        rotate([90,0,0]) linear_extrude(0.6, center=true)
        offset(r=r) offset(r=-r) square([w, h], center=true);
}
module one_strap(mir) {
    rows = strap_rows();
    scale([mir,1,1])
    difference() {
        for (i = [0:len(rows)-2]) hull() { slab(rows[i]); slab(rows[i+1]); }
        translate([0, strap_hole_y, strap_hole_z])
            rotate([0,90,0]) cylinder(h=80, d=strap_hole_d, center=true);
    }
}
module straps() { one_strap(1); one_strap(-1); }

// ---- Tensioner boss: rounded box via minkowski (no BOSL2) ----
boss_cx=0.3; boss_cy=28.5; boss_width=29.5; boss_length=20.0;
boss_top_z=23.4; boss_base_z=13.5; boss_round=4.0;

module tensioner_boss() {
    h = boss_top_z - boss_base_z;
    r = boss_round;
    translate([boss_cx, boss_cy, (boss_base_z+boss_top_z)/2])
        minkowski() {
            cube([boss_width-2*r, boss_length-2*r, max(h-2*r, 0.1)], center=true);
            sphere(r=r, $fn=24);
        }
}

// ---- Crenellation slots (triangular prisms) ----
crenel_x=[-11.4,-5.0,0.6,6.8,12.4];
crenel_z_base=15.5; crenel_z_apex=21.0; crenel_w=4.6;
crenel_y0=14.0; crenel_y1=22.5;

module crenellations() {
    for (xc = crenel_x)
        translate([xc, crenel_y1, 0])
            rotate([90,0,0])
            linear_extrude(crenel_y1-crenel_y0)
            polygon([[-crenel_w/2, crenel_z_base],
                     [ crenel_w/2, crenel_z_base],
                     [ 0,          crenel_z_apex]]);
}

// ---- Dorsal round holes (radial cylinders) ----
hole_x=12.6; hole_y=8.5; hole_z=12.0; hole_d=3.5;

module dorsal_holes() {
    ang = atan2(hole_z, hole_x);
    for (sx = [1,-1])
        scale([sx,1,1])
        translate([hole_x, hole_y, hole_z])
            rotate([0, 90-ang, 0])
            cylinder(h=40, d=hole_d, center=true);
}

echo(str("Primitive gauntlet built. Discs: ", len(cuff_discs), " | wall=", wall,
         " | open_half_x=", open_half_x, " | open_top_z=", open_top_z));
