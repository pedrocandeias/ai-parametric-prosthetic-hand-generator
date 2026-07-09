// ============================================
// Project: Tensioner_Block.stl reconstruction
// Description: Curved (crescent) tensioner block - a constant Z-extrusion
//              of a hooked crescent profile, with three square strap pockets
//              over a thin floor pierced by screw holes.
// Author: Claude Code + User
// ============================================
// Original STL: bbox X 120.47..143.64, Y 42.88..53.91, Z -0.171..27.829
// Z is a near-perfect extrusion (stability 0.0015). Profile captured at mid-Z.

$fn = 96;
eps = 0.02;

// --- Placement: centred at origin (X0 Y0), sitting on the build plate (Z0) ---
cx = 0.0;                // [mm] X centre
cy = 0.0;                // [mm] Y centre
z0 = 0.0;                // [mm] part bottom (Z)

// --- Overall ---
height   = 28.0;       // [mm] Z extrusion length
floor_h  = 1.29;       // [mm] base floor thickness (square pockets start here)

// --- Square strap pockets (open at top, down to the floor) ---
pocket    = 5.0;       // [mm] square side
pockets   = [          // [x, y, rotation_deg] recentred profile coords
    [-6.15, -0.38, -5],
    [ 0.00, -0.68,  0],
    [ 6.15, -0.38,  5],
];

// --- Screw holes through the floor ---
screw_d  = 3.0;        // [mm]

// --- Detent nub (sphere) in the central slot ---
nub_r    = 1.08;       // [mm]
nub_pos  = [0, 2.52, 2.23 - z0];   // recentred XY, local Z (abs z 2.23)

// --- Crescent outer profile (recentred, mid-Z cross-section) ---
outer_pts = [
    [4.83,5.72],[3.87,4.75],[3.75,4.75],[3.75,4.33],[5.49,2.52],[-5.49,2.52],
    [-3.75,4.33],[-3.75,4.75],[-3.87,4.75],[-4.83,5.72],[-6.14,5.72],[-7.67,5.20],
    [-8.78,4.62],[-9.80,3.90],[-10.48,3.25],[-11.04,2.50],[-11.42,1.64],[-11.57,0.88],
    [-11.54,-0.05],[-11.28,-0.95],[-11.00,-1.50],[-10.54,-2.14],[-9.88,-2.79],[-9.13,-3.37],
    [-8.86,-3.83],[-8.27,-4.18],[-7.55,-4.45],[-5.28,-4.96],[-1.93,-5.28],[2.22,-5.26],
    [5.31,-4.95],[7.05,-4.59],[8.03,-4.28],[8.93,-3.78],[9.13,-3.37],[10.30,-2.40],
    [11.02,-1.46],[11.39,-0.65],[11.56,0.07],[11.56,0.96],[11.41,1.69],[11.04,2.50],
    [10.51,3.22],[9.76,3.94],[8.78,4.62],[7.72,5.18],[6.14,5.72],
];

module body() {
    linear_extrude(height) polygon(outer_pts);
}

module pocket_cuts() {
    for (p = pockets)
        translate([p[0], p[1], floor_h])
            rotate([0, 0, p[2]])
                linear_extrude(height - floor_h + eps)
                    square(pocket, center = true);
}

module screw_cuts() {
    for (p = pockets)
        translate([p[0], p[1], -eps])
            cylinder(d = screw_d, h = floor_h + 2*eps);
}

module nub() {
    translate(nub_pos) sphere(r = nub_r);
}

translate([cx, cy, z0])
difference() {
    union() {
        body();
        nub();
    }
    pocket_cuts();
    screw_cuts();
}

echo(str("BBOX target 23.17 x 11.03 x 28.0"));
