// =============================================================================
// Distals_v3.scad  —  e-NABLE distal phalanx (fingertip), parametric loft
// =============================================================================
// Method: BOSL2 skin() loft of measured X-Z cross-sections along the finger's
//         long axis (Y). v3 replaces the v2 rounded-rect sections with
//         continuously curved egg/oval profiles (fingerator idiom: smooth
//         convex sections instead of boxy corners), each FITTED to the
//         original mesh occupancy at that station (scratchpad/fit_v2.py).
//
// ALL dimensions below are MEASURED, not invented. Source:
//   scripts/Distals.stl -> trimesh.split() into 5 bodies -> per-body occupancy
//   sweep perpendicular to Y (outer silhouette), then least-squares fit of the
//   section family below at each station. Fit rms 0.02-0.14 mm per station.
//
// Profile table columns:  [ h, Xw, Zmin, Zmax, zw, et, st, eb, sb, bb ]
//   h    = distance along Y from the body's y_min  (the long axis / loft path)
//   Xw   = section width  in model X               (full extent Xmax-Xmin)
//   Zmin = section bottom in model Z  (~ -0.17 => flat, resting on plate)
//   Zmax = section top    in model Z
//   zw   = Z of the widest point (the egg's "equator")
//   et,st= top    falloff: superellipse exponent + linear taper (see ftap())
//   eb,sb= bottom falloff: superellipse exponent + linear taper
//   bb   = bottom falloff half-span; bb > (zw-Zmin) means the curve is clipped
//          flat at Zmin (plate side) before closing -> flat bottom + soft corner
// half-width(z) =
//   z>=zw:  Xw/2 * (1 - st*t) * (1 - t^et)^(1/et),   t = (z-zw)/(Zmax-zw)
//   z< zw:  Xw/2 * (1 - sb*t) * (1 - t^eb)^(1/eb),   t = (zw-z)/bb
// This reproduces the flat underside, the barrel sides, the narrow dorsal
// dome AND the true egg sections of the curled tip (h>=27) in one family.
// =============================================================================

include <BOSL2/std.scad>

/* [Display] */
// Finger size to render (single-finger mode)
which = "std";          // [std, thumb, short]
// Render all 5 fingers as a set
show_set = false;
// Overlay the original STL as a transparent ghost (to compare)
show_ghost = false;

/* [Section] */
// Cut away half the model (and ghost) to expose the interior
section = "off";        // [off, longitudinal, transverse, horizontal]
// Position of the section plane along its axis (mm)
section_at = 0;         // [-30:0.5:50]

/* [Hidden] */
// folder holding the pre-aligned original STLs for the ghost overlay
ghost_dir = "/home/pec/dev/openscad-parametric-reconstructor/tmp/openscad-projects/distals-reconstructed/output";

// ---- smoothness ------------------------------------------------------------
NT = 20;                // profile samples, top half (apex..equator)
NB = 20;                // profile samples, bottom half (equator..Zmin)
NP = 96;                // resampled perimeter points (IDENTICAL for every
                        //   station -> skin() correspondence, no twist)
loft_slices = 2;        // interpolation slices between adjacent profiles
hole_fn   = 48;         // facets for the pin hole / joint cylinders

// ---- internal features (measured per size; occupancy maps of each body) -----
// Coordinates are finger-LOCAL: h = distance along Y from heel; thickness = Z.
add_internals = true;   // subtract clevis slot + pin hole + tendon channel
// CONSTANT across all 3 sizes (standardised joint interface):
slot_w  = 5.90;         // clevis slot X width  (inner walls, centred on axis)
// pivot pin hole: NOT a plain circle — a round bore FLATTENED top & bottom in Z
// (the e-NABLE no-overhang horizontal hole). Measured: round sides r=2.27, flats
// at z=+-2.0 (so width-h 4.54, height-z 4.0).
pin_r    = 2.27;        // bore radius (round sides, in the h direction)
pin_flat = 2.00;        // top & bottom flattened at +-pin_flat in Z
pin_h    = 6.20;        // pin hole along length (h-centre ~6.0 from heel)
// Joint cylinders CONCENTRIC WITH THE PIN (fingerator idiom, radii measured on
// all 3 bodies — identical, it is the standardised PIP interface):
slot_end_r = 7.39;      // clevis slot END face = cylinder about the pin axis
                        //   (slot web reaches h 13.10@z4.0 .. 13.60@z6.6, meas.)
// bore-entry counterbores on the OUTER prong faces (snap-pin seats), measured:
relief_x0  = 4.00;      // both counterbores start at |x| = 4.00 (to the skin)
relief_hc  = 6.15;      // their h-centre (slightly heel-ward of pin_h)
relief_r   = 2.72;      // -x side: ROUND counterbore radius (no flats)
relief_rl  = 5.90;      // +x side: rectangular pocket, length along h
relief_rw  = 3.95;      // +x side: rectangular pocket, height in Z
relief_ra  = 2.9;       // +x side: pocket rotation about the bore axis (deg)
bridge_r  = 0.60;       // tendon bridge rounding (rounded bar, not a sharp box)
// FLEXOR underside (mirror of the dorsal groove+bridge): a scoop pocket of width
// slot_w with a central fin rib. Constant across sizes:
scoop_z1 = 3.30;        // scoop floor Z (pocket cut up to here; measured ~3.4)
scoop_h1 = 24.00;       // pocket ends here (open past the fin to ~h24)
fin_hw    = 1.30;       // central fin half-width (X)  (measured 17 cols @0.15)
fin_h0    = 13.00;      // fin start at this h
fin_h1    = 22.00;      // fin (pill) ends here (full to ~h21, rounds to ~22)
pocket_h0 = 10.00;      // pocket cut starts here — BEFORE the fin, buried in the
                        //   clevis slot, so its rounded heel end is hidden and the
                        //   pocket is FULL WIDTH at h13 (open to the slot, no wall)
// Fin CAP = a wider+longer rounded slab on the fin's flexor (-Z) tip (the cord
// catches under it). Measured on the extracted original faces.
cap_hw = 1.55;          // half-width (vs fin 1.30)
cap_h0 = 12.50;         // heel side (extended per user)
cap_h1 = 22.50;         // tip side (extended per user — longer cap)
cap_z1 = 0.70;          // cap top Z (taller per user, ~0.85 tall from fin_zbot)
fin_zbot = -0.17;       // fin reaches the flat-bottom plate
pocket_r = 2.60;        // pocket footprint corner radius -> rounded (stadium) ends
floor_r  = 1.30;        // cross-section rounding of the pocket floor (Z) -> grooves taper
// PER-SIZE feature vector:
//   [ slot_h1, pin_z, groove_h1, bridge_h0, bridge_h1, bridge_z0, bridge_z1 ]
feat_std   = [ 12.90, 6.65, 24.50, 20.20, 22.40, 10.30, 11.70 ];
feat_thumb = [ 12.90, 6.90, 24.30, 20.20, 22.40, 10.40, 11.80 ];
feat_short = [ 12.60, 6.30, 22.20, 17.80, 20.00, 10.20, 11.40 ];
feat = which == "thumb" ? feat_thumb : which == "short" ? feat_short : feat_std;
// PER-SIZE tendon groove floor (measured: the floor is NOT flat — it SLOPES
// down toward the tip, rises into a rounded end, and the end face is a SLANTED
// cord-exit ramp that overshoots groove_h1 dorsally):
//   [ z@h14, slope(dz/dh), end_radius, ramp_z0, ramp_dh/dz ]
//   floor z(h) = gv[0] - gv[1]*(h - 14);  end face h(z) = ft[2] + (z-gv[3])*gv[4]
grv_std   = [ 8.60, 0.0563, 2.30, 10.40, 0.58 ];
grv_thumb = [ 8.85, 0.0500, 2.20,  9.60, 0.60 ];
grv_short = [ 8.35, 0.0417, 2.20,  9.50, 0.50 ];
grv = which == "thumb" ? grv_thumb : which == "short" ? grv_short : grv_std;

// ---- measured + fitted profile tables ---------------------------------------
// columns: [ h, Xw, Zmin, Zmax, zw, et, st, eb, sb, bb ]  (see header)
// Standard finger  = split body [1]:  Ytot=43.60, Xtot=11.24, Ztot=15.30
table_std = [
    [  0.20,  10.58,   5.07,   8.10,   7.31, 14.00,  0.02, 14.00,  0.03,   5.01 ],
    [  0.87,  10.58,   3.48,   9.69,   7.42, 14.00,  0.04, 14.00,  0.04,   9.62 ],
    [  1.05,  10.58,   3.21,   9.98,   7.03, 14.00,  0.05, 14.00,  0.04,  10.45 ],
    [  1.20,  10.58,  -0.17,  10.14,   6.75, 14.00,  0.05,  7.21,  0.03,   7.24 ],
    [  1.30,  10.58,  -0.17,  10.30,   6.68, 14.00,  0.05,  7.19,  0.03,   7.16 ],
    [  2.50,  10.57,  -0.17,  11.42,   6.70, 14.00,  0.09,  6.91,  0.03,   7.26 ],
    [  3.29,  10.56,  -0.17,  11.90,   8.01, 14.00,  0.14,  7.28,  0.02,   8.58 ],
    [  4.09,  10.55,  -0.17,  12.27,   8.28, 14.00,  0.17,  7.58,  0.02,   8.83 ],
    [  5.70,  10.52,  -0.17,  12.54,   3.92, 10.13,  0.11,  6.23,  0.05,   4.48 ],
    [  7.31,  10.52,  -0.17,  12.46,   3.63, 10.04,  0.10,  5.63,  0.06,   4.37 ],
    [  8.92,  10.55,  -0.17,  12.44,   8.63, 14.00,  0.19,  7.83,  0.01,   9.26 ],
    [ 10.53,  10.60,  -0.17,  12.36,   8.18, 14.00,  0.18,  9.16,  0.03,   8.70 ],
    [ 12.14,  10.71,  -0.17,  12.28,   7.86, 14.00,  0.17,  8.00,  0.02,   8.43 ],
    [ 13.75,  10.85,  -0.17,  12.14,   7.45, 12.52,  0.17,  7.07,  0.01,   8.12 ],
    [ 15.36,  10.99,  -0.17,  12.06,   7.27, 12.35,  0.17,  6.87,  0.01,   7.88 ],
    [ 16.97,  11.11,  -0.17,  11.98,   7.10, 11.60,  0.17,  7.23,  0.02,   7.62 ],
    [ 18.58,  11.18,  -0.17,  11.90,   7.12, 11.73,  0.18,  6.47,  0.01,   7.73 ],
    [ 20.19,  11.23,  -0.17,  11.82,   7.05, 11.56,  0.19,  6.36,  0.02,   7.68 ],
    [ 21.80,  11.22,  -0.17,  11.66,   6.98, 10.15,  0.19,  5.84,  0.02,   7.61 ],
    [ 23.41,  11.16,  -0.17,  11.50,   7.12,  8.24,  0.19,  4.83,  0.01,   7.83 ],
    [ 25.02,  11.05,  -0.17,  11.42,   7.10,  6.50,  0.19,  4.53,  0.02,   7.68 ],
    [ 26.63,  10.89,  -0.17,  11.88,   6.60,  2.83,  0.04,  3.78,  0.03,   7.04 ],
    [ 28.24,  10.68,  -0.12,  12.27,   6.60,  2.76,  0.02,  3.19,  0.03,   6.66 ],
    [ 29.85,  10.41,   0.73,  12.96,   7.52,  2.60,  0.02,  3.22,  0.04,   6.71 ],
    [ 31.46,  10.17,   1.78,  13.70,   8.33,  2.76,  0.04,  3.49,  0.06,   6.41 ],
    [ 33.07,   9.99,   2.83,  14.35,   8.87,  2.89,  0.04,  3.13,  0.05,   5.96 ],
    [ 34.68,   9.81,   3.86,  14.81,   9.10,  3.12,  0.02,  2.71,  0.02,   5.22 ],
    [ 36.29,   9.56,   4.87,  15.09,   9.76,  3.05,  0.02,  2.60,  0.00,   4.87 ],
    [ 37.89,   9.17,   5.89,  15.08,   9.89,  3.47,  0.04,  2.55,  0.04,   3.99 ],
    [ 39.50,   8.69,   6.95,  15.00,  10.81,  3.01,  0.05,  2.90,  0.06,   3.80 ],
    [ 40.50,   8.25,   7.57,  14.76,  10.91,  3.34,  0.12,  2.75,  0.05,   3.30 ],
    [ 41.50,   7.58,   8.16,  14.38,  10.62,  3.31,  0.14,  2.41,  0.07,   2.40 ],
    [ 42.00,   7.08,   8.55,  14.06,  11.07,  3.90,  0.25,  2.33, -0.01,   2.45 ],
    [ 42.50,   6.32,   9.14,  13.70,  11.27,  3.99,  0.30,  2.52,  0.01,   2.08 ],
    [ 43.00,   5.08,  10.07,  13.25,  11.25,  2.50,  0.13,  3.34,  0.16,   1.21 ],
    [ 43.40,   3.66,  10.92,  12.75,  11.74,  2.57,  0.28,  3.03,  0.05,   0.91 ],
    [ 43.52,   2.64,  11.41,  12.50,  11.82,  2.42,  0.25,  1.97, -0.10,   0.55 ],
];

// Thumb / pollux  = split body [0]:  Ytot=43.60, Xtot=16.06, Ztot=15.19
table_thumb = [
    [  0.20,  14.45,   5.35,   8.31,   7.72, 14.00,  0.02, 14.00,  0.01,   2.97 ],
    [  0.87,  14.41,   3.75,   9.91,   7.57, 14.00,  0.04,  9.50,  0.02,   5.01 ],
    [  1.05,  14.40,   3.47,  10.19,   7.39, 14.00,  0.05,  7.58,  0.02,   5.04 ],
    [  1.20,  14.39,  -0.17,  10.38,   7.31, 14.00,  0.06,  3.75,  0.02,   7.90 ],
    [  1.30,  14.38,  -0.17,  10.54,   7.25, 14.00,  0.06,  3.70,  0.02,   7.85 ],
    [  2.50,  14.21,  -0.17,  11.66,   7.69, 14.00,  0.12,  3.81,  0.01,   8.26 ],
    [  3.29,  14.06,  -0.17,  12.14,   8.71, 14.00,  0.17,  4.14,  0.00,   9.22 ],
    [  4.09,  13.88,  -0.17,  12.53,   8.92, 14.00,  0.21,  4.13, -0.00,   9.45 ],
    [  5.70,  13.48,  -0.17,  12.78,   4.43,  8.14,  0.11,  3.55,  0.08,   5.06 ],
    [  7.31,  13.22,  -0.17,  12.75,   9.31, 14.00,  0.22,  4.62, -0.01,   9.78 ],
    [  8.92,  13.13,  -0.17,  12.67,   8.98, 14.00,  0.21,  4.56,  0.00,   9.49 ],
    [ 10.53,  13.15,  -0.17,  12.54,   8.33, 10.72,  0.18,  4.61,  0.02,   8.82 ],
    [ 12.14,  13.31,  -0.17,  12.46,   8.31, 10.03,  0.19,  4.34,  0.01,   8.84 ],
    [ 13.75,  13.63,  -0.17,  12.37,   8.33, 10.67,  0.22,  4.17,  0.01,   8.90 ],
    [ 15.36,  14.05,  -0.17,  12.22,   8.09,  9.00,  0.23,  4.06,  0.01,   8.65 ],
    [ 16.97,  14.52,  -0.17,  12.14,   7.92,  8.00,  0.25,  3.86,  0.01,   8.49 ],
    [ 18.58,  14.98,  -0.17,  12.12,   7.91,  7.80,  0.29,  3.73,  0.01,   8.49 ],
    [ 20.19,  15.40,  -0.17,  12.04,   7.76,  6.31,  0.29,  3.72,  0.01,   8.29 ],
    [ 21.80,  15.70,  -0.17,  11.82,   7.58,  5.67,  0.27,  3.47,  0.01,   8.14 ],
    [ 23.41,  15.89,  -0.17,  11.66,   7.36,  4.48,  0.24,  3.13,  0.01,   7.94 ],
    [ 25.02,  16.00,  -0.17,  11.66,   7.45,  3.90,  0.25,  2.81, -0.00,   7.97 ],
    [ 26.63,  16.06,  -0.17,  12.14,   6.45,  2.25, -0.00,  2.51,  0.05,   6.83 ],
    [ 28.24,  15.98,   0.10,  12.58,   6.58,  2.29,  0.00,  2.42,  0.08,   6.46 ],
    [ 29.85,  15.77,   1.00,  13.24,   7.38,  2.42,  0.06,  2.35,  0.05,   6.37 ],
    [ 31.46,  15.49,   2.14,  13.96,   7.96,  2.32,  0.02,  2.36,  0.05,   5.81 ],
    [ 33.07,  15.13,   3.30,  14.42,   9.00,  2.50,  0.07,  2.40,  0.04,   5.69 ],
    [ 34.68,  14.65,   4.41,  14.71,   9.57,  2.51,  0.03,  2.50,  0.07,   5.15 ],
    [ 36.29,  14.00,   5.43,  14.86,  10.38,  2.71,  0.05,  2.48,  0.06,   4.94 ],
    [ 37.89,  13.14,   6.34,  14.98,  10.69,  2.89,  0.04,  2.53,  0.09,   4.31 ],
    [ 39.51,  12.02,   7.28,  14.95,  11.50,  3.42,  0.11,  2.31,  0.01,   4.22 ],
    [ 40.50,  11.14,   7.84,  14.79,  11.73,  3.57,  0.12,  2.21, -0.03,   3.89 ],
    [ 41.50,   9.97,   8.41,  14.49,  11.64,  3.15,  0.08,  2.01, -0.07,   3.22 ],
    [ 42.00,   9.14,   8.78,  14.22,  11.83,  3.59,  0.14,  2.12, -0.08,   3.00 ],
    [ 42.50,   7.96,   9.32,  13.95,  11.53,  2.74,  0.04,  2.24,  0.01,   2.17 ],
    [ 43.00,   5.98,  10.23,  13.51,  11.60,  2.52,  0.04,  3.06,  0.13,   1.37 ],
    [ 43.40,   3.73,  11.16,  13.05,  11.88,  1.95,  0.08,  3.57,  0.15,   0.79 ],
    [ 43.52,   2.75,  11.62,  12.74,  12.09,  3.24,  0.34,  4.71,  0.12,   0.46 ],
];

// Short finger  = split body [3]:  Ytot=39.77, Xtot=11.21, Ztot=14.15
table_short = [
    [  0.20,  10.58,   4.79,   7.82,   7.13, 14.00,  0.03, 14.00,  0.03,   5.11 ],
    [  0.80,  10.58,   3.33,   9.29,   8.10, 14.00,  0.04, 14.00,  0.08,  23.85 ],
    [  1.00,  10.58,   3.01,   9.61,   7.02, 14.00,  0.04, 14.00,  0.04,  10.15 ],
    [  1.20,  10.58,  -0.17,   9.90,   6.63, 14.00,  0.05,  7.92,  0.03,   7.31 ],
    [  1.30,  10.58,  -0.17,   9.98,   6.49, 14.00,  0.05,  7.71,  0.03,   7.19 ],
    [  2.50,  10.57,  -0.17,  11.17,   6.56, 14.00,  0.09,  7.63,  0.03,   7.25 ],
    [  3.73,  10.55,  -0.17,  11.82,   7.93, 14.00,  0.15,  7.88,  0.02,   8.68 ],
    [  5.20,  10.52,  -0.17,  12.22,   8.55, 14.00,  0.20,  8.93,  0.02,   9.22 ],
    [  6.67,  10.51,  -0.17,  12.22,   8.64, 14.00,  0.20,  9.18,  0.02,   9.34 ],
    [  8.14,  10.53,  -0.17,  12.14,   8.41, 13.67,  0.19,  7.25,  0.02,   9.43 ],
    [  9.61,  10.56,  -0.17,  12.12,   8.15, 14.00,  0.18,  8.36,  0.02,   9.04 ],
    [ 11.07,  10.63,  -0.17,  12.06,   7.51, 12.16,  0.16,  8.15,  0.02,   8.38 ],
    [ 12.54,  10.75,  -0.17,  11.98,   7.37, 13.22,  0.17, 10.38,  0.02,   7.97 ],
    [ 14.01,  10.89,  -0.17,  11.90,   7.04, 14.00,  0.17,  9.74,  0.02,   7.68 ],
    [ 15.48,  11.02,  -0.17,  11.82,   6.81, 13.34,  0.17,  8.05,  0.01,   7.56 ],
    [ 16.95,  11.12,  -0.17,  11.74,   6.86, 13.78,  0.18,  7.01,  0.01,   7.66 ],
    [ 18.42,  11.17,  -0.17,  11.58,   7.04, 12.60,  0.18,  6.56,  0.01,   7.82 ],
    [ 19.89,  11.21,  -0.17,  11.48,   7.13, 12.72,  0.20,  6.16,  0.03,   7.96 ],
    [ 21.35,  11.18,  -0.17,  11.34,   6.89,  9.25,  0.19,  4.98,  0.03,   7.89 ],
    [ 22.82,  11.05,  -0.17,  11.34,   6.89,  7.76,  0.19,  4.95,  0.03,   7.51 ],
    [ 24.29,  10.87,  -0.17,  11.66,   5.92,  3.77,  0.09,  3.81,  0.02,   6.31 ],
    [ 25.76,  10.68,  -0.15,  11.92,   5.82,  3.37,  0.07,  3.23,  0.01,   5.84 ],
    [ 27.23,  10.49,   0.36,  12.36,   5.99,  2.86,  0.02,  2.75,  0.00,   5.55 ],
    [ 28.00,  10.38,   0.73,  12.62,   6.65,  2.69,  0.02,  2.76, -0.01,   5.85 ],
    [ 28.70,  10.27,   1.12,  12.87,   6.98,  2.66,  0.01,  2.78, -0.00,   5.78 ],
    [ 30.16,  10.07,   2.08,  13.36,   7.86,  2.79,  0.02,  2.91,  0.02,   5.70 ],
    [ 31.63,   9.88,   3.12,  13.76,   9.00,  2.94,  0.04,  3.13,  0.04,   5.80 ],
    [ 33.10,   9.64,   4.12,  13.95,   9.70,  3.01,  0.05,  3.15,  0.05,   5.51 ],
    [ 34.57,   9.27,   5.06,  13.93,   9.95,  2.94,  0.04,  2.96,  0.04,   4.83 ],
    [ 36.04,   8.74,   5.95,  13.68,   9.96,  3.03,  0.06,  2.74,  0.02,   3.96 ],
    [ 37.00,   8.34,   6.51,  13.39,   9.68,  3.08,  0.08,  2.69,  0.04,   3.11 ],
    [ 38.00,   7.65,   7.18,  12.94,  10.00,  3.16,  0.18,  2.57, -0.00,   2.76 ],
    [ 38.98,   6.17,   8.14,  12.29,   9.86,  2.82,  0.17,  2.55,  0.10,   1.67 ],
    [ 39.20,   5.71,   8.41,  12.08,   9.98,  3.00,  0.21,  2.17,  0.04,   1.56 ],
    [ 39.57,   4.48,   8.92,  11.55,   9.99,  2.75,  0.15,  2.83,  0.12,   1.10 ],
    [ 39.70,   2.61,   9.32,  10.75,  10.46,  5.01,  0.26, 14.00, -0.25,   1.14 ],
];

table = which == "thumb" ? table_thumb
      : which == "short" ? table_short
      :                    table_std;

// ---- build -----------------------------------------------------------------
// One 2D cross-section: fitted egg/oval (see header), built in the XY plane
// (local x = model X width, local y = model Z thickness). Every station is
// sampled the SAME way (NT+NB per side) and resampled to the SAME perimeter
// count NP starting from the same seam -> skin() correspondence is preserved.
function ftap(t, e, s) = (1 - s * t) * pow(max(1 - pow(t, e), 0), 1 / e);

function prof_path(r) = let(
    W2 = r[1] / 2, zmin = r[2], zmax = r[3], zw = r[4],
    et = r[5], st = r[6], eb = r[7], sb = r[8], bb = r[9],
    bt = zmax - zw,
    // cosine-spaced samples: dense near the apex and the bottom, so the
    // resampled polygon hugs the dome instead of chord-cutting it
    top = [for (i = [0:NT]) let(t = (1 + cos(180 * i / NT)) / 2)
              [W2 * ftap(t, et, st), zw + bt * t]],
    bot = [for (i = [1:NB]) let(z = zw - (zw - zmin) * (1 - cos(180 * i / NB)) / 2)
              [max(W2 * ftap((zw - z) / bb, eb, sb), 0.01), z]],
    right = concat(top, bot),
    left  = [for (i = [len(right) - 1:-1:1]) [-right[i][0], right[i][1]]]
) reverse(concat(right, left));       // reverse -> CCW, like BOSL2 rect()

function prof_pts(r) = resample_path(prof_path(r), n = NP, closed = true);

// Solid outer loft, built in the LOCAL frame (loft axis = +Z = h, thickness = Y).
module finger_solid(tbl) {
    profiles = [ for (r = tbl) prof_pts(r) ];
    heights  = [ for (r = tbl) r[0] ];
    skin(profiles, z = heights, slices = loft_slices, caps = true);
}

// Internal cuts in the LOCAL frame (x=width, y=thickness/Z, z=h along length).
// ft = per-size feature vector [slot_h1,pin_z,groove_h1,bh0,bh1,bz0,bz1].
// gv = per-size groove floor  [z@h14, slope, end_radius].
module internal_cuts(ft, gv) {
    // clevis fork slot — through the full thickness, from below the heel to slot_h1
    translate([-slot_w/2, -2, -1]) cube([slot_w, 20, ft[0] + 1]);
    // slot END face = cylinder CONCENTRIC with the pin (fingerator idiom: the
    // web between the prongs is turned about the joint axis, r measured 7.39)
    translate([0, ft[1], pin_h]) rotate([0, 90, 0])
        cylinder(h = slot_w, r = slot_end_r, center = true, $fn = hole_fn);
    // pivot pin hole — round bore flattened top & bottom (axis along local x)
    intersection() {
        translate([0, ft[1], pin_h]) rotate([0, 90, 0])
            cylinder(h = 24, r = pin_r, center = true, $fn = hole_fn);
        translate([-12, ft[1] - pin_flat, pin_h - 4]) cube([24, 2 * pin_flat, 8]);
    }
    // bore-entry counterbores on the outer prong faces (measured, both sides):
    // -x: round seat r=2.72 (no flats); +x: 5.9 x 3.95 pocket tilted 2.9 deg
    translate([-relief_x0, ft[1], relief_hc]) rotate([0, -90, 0])
        cylinder(h = 3, r = relief_r, $fn = hole_fn);
    translate([relief_x0, ft[1], relief_hc]) rotate([relief_ra, 0, 0])
        translate([0, -relief_rw/2, -relief_rl/2]) cube([3, relief_rw, relief_rl]);
    // tendon top groove — sloped floor + rounded end (see grv_* comment)
    groove_cut(ft, gv);
    // flexor underside: two rounded grooves leave a central fin, then an open pocket
    flexor_cut();
}

// Tendon groove with the MEASURED sloped floor, rounded (cylindrical) end and
// slanted cord-exit ramp. Floor line: z = gv[0] - gv[1]*(h-14); end arc radius
// gv[2] tangent to the floor; above z=gv[3] the end face ramps tip-ward with
// slope dh/dz = gv[4] (it passes through (groove_h1, ramp_z0)).
module groove_cut(ft, gv) {
    er = gv[2];
    ch = ft[2] - er;                          // end-arc centre, h
    cz = gv[0] - gv[1] * (ch - 14) + er;      // end-arc centre, Z
    intersection() {
        // half-space above the sloped floor (within slot width)
        translate([0, gv[0], 14]) rotate([atan(gv[1]), 0, 0])
            translate([-slot_w/2, 0, -40]) cube([slot_w, 20, 80]);
        union() {
            // main run: slot end .. end-arc centre
            translate([-slot_w/2, 0, ft[0]]) cube([slot_w, 20, ch - ft[0]]);
            // rounded floor-to-end transition
            translate([0, cz, ch]) rotate([0, 90, 0])
                cylinder(h = slot_w, r = er, center = true, $fn = hole_fn);
            // slanted cord-exit end face above ramp_z0 (measured slope gv[4])
            translate([0, gv[3], ft[2]]) rotate([atan(gv[4]), 0, 0])
                translate([-slot_w/2, 0, -60]) cube([slot_w, 25, 60]);
        }
    }
}

// Flexor scoop = a pocket with a ROUNDED (stadium) footprint, cut into the
// underside; the central fin (added back) is a PILL with rounded ends. Built in
// the LOCAL frame: x=X(width), y=model-Z(depth), z=h(length); edges="Y" rounds
// the vertical edges -> rounded footprint corners in the X-h plane.
module flexor_cut() {
    depth = scoop_z1 + 1.2;                       // model-Z span: -1.2 .. scoop_z1
    len   = scoop_h1 - pocket_h0;
    translate([0, (scoop_z1 - 1.2) / 2, (pocket_h0 + scoop_h1) / 2])
        intersection() {
            // rounded (stadium) footprint in the X-h plane (vertical edges)
            cuboid([slot_w, depth, len], rounding = pocket_r, edges = "Y", $fn = 32);
            // rounded floor: same size, round only the top (+model-Z) face edges
            cuboid([slot_w, depth, len], rounding = floor_r, edges = BACK, $fn = 24);
        }
}

// Central fin = a PILL (rounded-end rib) sitting in the scoop pocket.
module flexor_fin() {
    depth = scoop_z1 - fin_zbot;                  // model-Z span: fin_zbot .. scoop_z1
    len   = fin_h1 - fin_h0;
    translate([0, (scoop_z1 + fin_zbot) / 2, (fin_h0 + fin_h1) / 2])
        // pill footprint (rounded ends); flat top -> the fin stays full and
        // merges into the web (only the pocket floor rounds, not the fin).
        cuboid([2 * fin_hw, depth, len], rounding = fin_hw * 0.95, edges = "Y", $fn = 32);
}

// Fin cap: a wider+longer rounded-perimeter slab on the fin's flexor tip (-Z).
// Full width down to the exposed bottom face; only the footprint (pill) margins
// are rounded (edges="Y"), so it stays at cap_hw right to the plate.
module flexor_cap() {
    depth = cap_z1 - fin_zbot;                    // model-Z span: fin_zbot .. cap_z1
    translate([0, (cap_z1 + fin_zbot) / 2, (cap_h0 + cap_h1) / 2])
        cuboid([2 * cap_hw, depth, cap_h1 - cap_h0],
               rounding = cap_hw * 0.9, edges = "Y", $fn = 24);
}

// Cord-retaining bridge that re-spans the groove top: a ROUNDED bar across the
// groove width (edges="X" rounds the h-Z profile -> lens shape, flush, no
// sharp box corners overshooting the groove margins).
module tendon_bridge(ft) {
    // bar bottom at bz0 (cord side, edges rounded); the top OVERSHOOTS bz1 and
    // is clipped by the body envelope -> flush with the dorsal dome (measured:
    // the original bridge merges into the outer surface, no step)
    translate([0, (ft[5] + ft[6] + 1.2) / 2, (ft[3] + ft[4]) / 2])
        cuboid([slot_w, ft[6] + 1.2 - ft[5], ft[4] - ft[3]],
               rounding = bridge_r, edges = [FRONT+BOT, FRONT+TOP], $fn = 24);
}

// One finger: outer loft minus internal features. tbl = profile table, ft = feats.
module finger(tbl, ft, gv) {
    // rotate([90,0,0]) lays the loft axis along Y with thickness up (+Z); mirror
    // flips it so the heel sits at the +Y origin and the tip points +Y.
    mirror([0, 1, 0])
        rotate([90, 0, 0])
            if (add_internals)
                union() {
                    difference() { finger_solid(tbl); internal_cuts(ft, gv); }
                    // clip the bridge to the body envelope so it sits FLUSH with the
                    // (curved) dorsal surface and never protrudes above the margins
                    intersection() { finger_solid(tbl); tendon_bridge(ft); }
                    flexor_fin();
                    flexor_cap();
                }
            else
                finger_solid(tbl);
}

// ---- output ----------------------------------------------------------------
// 5-finger layout: relative X centres measured in Distals.stl (heels Y-aligned).
// order left->right: thumb, std, std, short, short  (centred about X=0).
set_layout = [
    [ table_thumb, feat_thumb, grv_thumb, -27.08 ],   // thumb  (orig Xc 40.76)
    [ table_std,   feat_std,   grv_std,   -12.40 ],   // index  (orig Xc 55.44)
    [ table_std,   feat_std,   grv_std,     0.66 ],   // middle (orig Xc 68.50)
    [ table_short, feat_short, grv_short,  13.26 ],   // ring   (orig Xc 81.10)
    [ table_short, feat_short, grv_short,  25.57 ],   // pinky  (orig Xc 93.41)
];

module model() {
    if (show_set) for (e = set_layout) translate([e[3], 0, 0]) finger(e[0], e[1], e[2]);
    else          finger(table, feat, grv);
}

// --- Assembly entry points ---------------------------------------------------
// Named wrappers so an external assembly can `use <Distals_v3.scad>` and draw a
// specific size directly (the `which` global can't be set across a `use`). Each
// draws a distal in its own frame: heel (PIP fork) at Y=0, tip toward +Y, flat
// bottom on Z0; the PIP pin passes at (Y = pin_h, Z = pin_z) along X.
module distal_std()   finger(table_std,   feat_std,   grv_std);
module distal_short() finger(table_short, feat_short, grv_short);
module distal_thumb() finger(table_thumb, feat_thumb, grv_thumb);

// half-space cube that removes everything beyond the section plane
module section_cube() {
    b = 250;
    if      (section == "longitudinal") translate([section_at, -b/2, -b/2]) cube(b);
    else if (section == "transverse")   translate([-b/2, section_at, -b/2]) cube(b);
    else if (section == "horizontal")   translate([-b/2, -b/2, section_at]) cube(b);
}

ghost_stl = str(ghost_dir, "/orig_", show_set ? "set" : which, "_aligned.stl");

if (section == "off") {
    if (show_ghost) %import(ghost_stl);
    model();
} else {
    difference() { model(); section_cube(); }
    if (show_ghost) %difference() { import(ghost_stl); section_cube(); }
}
