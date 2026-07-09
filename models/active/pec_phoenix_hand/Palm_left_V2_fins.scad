// =============================================================================
// Palm_left_V2_fins.scad — dorsal finger FINS (blade) + FIN CAPS (rounded crown).
// Measured from the ghost: ring/middle/index each have a back-swept blade with an
// integral rounded crown (the crown is the blade's narrowed teardrop top, split
// into finger_fin_caps() — NOT a wider thumb-style overhang). PINKY has no fin.
// =============================================================================

// [ name, xc, yf(front face Y), base_z, shoulder_z, peak_z, depth(Y), thk(X) ]
finger_fins_tbl = [
    [ "pinky",  -28.75, 24.40, 13.0, 16.00, 18.35, 5.50, 2.85 ],  // smaller, shifted back/down
    [ "ring",   -14.80, 30.32, 13.0, 16.23, 18.51, 5.68, 2.85 ],
    [ "middle",  -0.80, 34.32, 13.0, 16.23, 18.51, 5.68, 2.85 ],
    [ "index",   13.20, 34.32, 13.0, 16.23, 18.51, 5.68, 2.85 ],
];
fin_round   = 0.7;   // 2D edge rounding (vertical edges + crown)
fin_peak_dy = 0.38;  // crown apex offset in +Y from the front face
cap_overlap = 0.8;   // crown roots this far down into the blade (clean seam)

// A Y-Z polygon profile, extruded `thk` along X (the blade is thin in X). The
// offset(r)/offset(-r) pair rounds the 2D outline's corners by fin_round before
// extruding (grow-then-shrink leaves rounded convex corners, sharp footprint).
module _fin_extrude(xc, yf, base_z, thk, pts)
    translate([xc, yf, base_z]) rotate([90, 0, 90]) translate([0, 0, -thk/2])
        linear_extrude(height = thk) offset(r = fin_round) offset(delta = -fin_round) polygon(pts);

// Lower blade: a rectangle from the base up to the shoulder (heights are local,
// measured up from base_z).
module fin_blade(xc, yf, base_z, shoulder_z, depth, thk) {
    shoulder_h = shoulder_z - base_z;
    _fin_extrude(xc, yf, base_z, thk, [[0,0], [depth,0], [depth,shoulder_h], [0,shoulder_h]]);
}
module finger_fins() { for (f = finger_fins_tbl) fin_blade(f[1],f[2],f[3],f[4],f[6],f[7]); }

// Crown cap: the teardrop top of the blade. Roots cap_overlap below the shoulder
// (clean seam into the blade) and tapers to a peak pulled fin_peak_dy in +Y.
module fin_cap(xc, yf, base_z, shoulder_z, peak_z, depth, thk) {
    root_h = shoulder_z - base_z - cap_overlap;
    peak_h = peak_z - base_z;
    _fin_extrude(xc, yf, base_z, thk,
        [[0,root_h], [depth,root_h], [depth, shoulder_z-base_z], [fin_peak_dy, peak_h]]);
}
module finger_fin_caps() { for (f = finger_fins_tbl) fin_cap(f[1],f[2],f[3],f[4],f[5],f[6],f[7]); }
