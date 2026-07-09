// =============================================================================
// Distals_v2.scad  —  e-NABLE distal phalanx (fingertip), parametric loft
// =============================================================================
// Method: BOSL2 skin() loft of measured X-Z cross-sections along the finger's
//         long axis (Y). Strategy chosen in Fase 1 (irregular + curved shape).
//
// ALL dimensions below are MEASURED, not invented. Source:
//   scripts/Distals.stl -> trimesh.split() into 5 bodies -> per-body section
//   sweep perpendicular to Y, reading true model X-width and Z-thickness.
//   (scratchpad/measure_xz.py). Each table row is one measured station.
//
// Profile table columns:  [ h ,  Xw ,  Zmin ,  Zmax ]
//   h    = distance along Y from the body's y_min  (the long axis / loft path)
//   Xw   = section width  in model X               (full extent Xmax-Xmin)
//   Zmin = section bottom in model Z  (~ -0.17 => flat, resting on plate)
//   Zmax = section top    in model Z
// The cross-section is modelled as a flat-bottom, round-topped "D" of width Xw,
// thickness (Zmax-Zmin), vertically centred at (Zmin+Zmax)/2 -> reproduces the
// flat underside AND the upward curl of the tip (Zmin rises past h~30).
//
// DEFERRED (NOT yet in this outer-silhouette pass — would be guessing):
//   * hinge socket cavity at the heel (h~0-3, centred tab seen at h=0.87)
//   * pivot pin hole (transverse, along X) and tendon channel
//   These need an X-axis section sweep of one isolated finger to dimension.
//   Per workspace rule: silhouette + bbox first, internal details after.
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
prof_fn   = 48;         // facets for the rounded-rect cross-section corners
loft_slices = 8;        // interpolation slices between adjacent profiles
hole_fn   = 48;         // facets for the pin hole
// Cross-section corner rounding. The real section is a barrel/oval (narrows at
// BOTH top and bottom), NOT a boxy rect — measured fill ratio ~0.87, not ~0.98.
// Top is always domed; the bottom is flat where the finger rests on the plate
// (Zmin~0) and rounds once the tip curls up (Zmin>0). Driven by each row's Zmin.
round_frac = 0.72;      // lifted-bottom (flexor/palm) radius as a fraction of half-width
top_frac   = 0.50;      // dorsal (nail) TOP radius — smaller than the flexor so the
                        //   nail side is flatter (margins stay level with the bridge)
bot_r_flat = 0.90;      // bottom radius when resting flat on the plate

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
groove_z0 = 8.20;       // tendon channel floor Z (material below)
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

// ---- measured profile tables ----------------------------------------------
// Standard finger  = split body [1]:  Ytot=43.60, Xtot=11.24, Ztot=15.30
table_std = [
    // h        Xw      Zmin    Zmax
    [  0.20,  10.58,   5.07,   8.11 ],  // measured heel end-cap (y_min+0.20)
    [  0.87,  10.58,   3.48,   9.70 ],  // heel tab (raised, centred — not on plate)
    [  1.30,  10.58,  -0.17,  10.32 ],  // fast rise to plate (heel face is thin)
    [  2.50,  10.57,  -0.17,  11.45 ],
    [  4.09,  10.55,  -0.17,  12.27 ],  // body begins, flat bottom
    [  7.31,  10.52,  -0.17,  12.50 ],  // tallest section
    [ 10.53,  10.60,  -0.17,  12.36 ],
    [ 13.75,  10.85,  -0.17,  12.18 ],
    [ 16.97,  11.11,  -0.17,  11.99 ],
    [ 20.19,  11.23,  -0.17,  11.82 ],  // widest section
    [ 23.41,  11.16,  -0.17,  11.54 ],
    [ 26.63,  10.89,  -0.17,  11.88 ],  // last flat-bottom station
    [ 29.85,  10.41,   0.73,  12.98 ],  // tip starts to curl up (Zmin>0)
    [ 33.07,   9.99,   2.83,  14.36 ],
    [ 36.29,   9.56,   4.87,  15.09 ],  // top reaches Ztot
    [ 39.50,   8.68,   6.96,  15.00 ],
    [ 42.72,   5.83,   9.52,  13.53 ],  // rounded fingertip nub
    [ 43.40,   3.66,  10.92,  12.79 ],  // measured tip end-cap (y_max-0.20)
];

// Thumb / pollux  = split body [0]:  Ytot=43.60, Xtot=16.06, Ztot=15.19
table_thumb = [
    [  0.20,  14.45,   5.35,   8.34 ],  // measured heel end-cap
    [  0.87,  14.41,   3.75,   9.94 ],
    [  1.30,  14.38,  -0.17,  10.56 ],  // fast rise to plate
    [  2.50,  14.21,  -0.17,  11.70 ],
    [  4.09,  13.88,  -0.17,  12.53 ],
    [  7.31,  13.22,  -0.17,  12.75 ],
    [ 10.53,  13.15,  -0.17,  12.58 ],
    [ 13.75,  13.63,  -0.17,  12.37 ],
    [ 16.97,  14.52,  -0.17,  12.17 ],
    [ 20.19,  15.40,  -0.17,  12.04 ],
    [ 23.41,  15.89,  -0.17,  11.70 ],
    [ 26.63,  16.06,  -0.17,  12.14 ],  // widest (Xtot)
    [ 29.85,  15.77,   1.01,  13.28 ],
    [ 33.07,  15.13,   3.30,  14.43 ],
    [ 36.29,  14.00,   5.43,  14.88 ],
    [ 39.51,  12.02,   7.28,  14.99 ],
    [ 42.73,   7.18,   9.68,  13.77 ],
    [ 43.40,   3.71,  11.17,  13.05 ],  // measured tip end-cap
];

// Short finger  = split body [3]:  Ytot=39.77, Xtot=11.21, Ztot=14.15
table_short = [
    [  0.20,  10.58,   4.79,   7.83 ],  // measured heel end-cap
    [  0.80,  10.58,   3.34,   9.28 ],
    [  1.30,  10.58,  -0.17,  10.03 ],  // fast rise to plate
    [  2.50,  10.57,  -0.17,  11.17 ],
    [  3.73,  10.55,  -0.17,  11.86 ],
    [  6.67,  10.51,  -0.17,  12.22 ],
    [  9.61,  10.56,  -0.17,  12.12 ],
    [ 12.54,  10.75,  -0.17,  12.00 ],
    [ 15.48,  11.02,  -0.17,  11.85 ],
    [ 18.42,  11.17,  -0.17,  11.61 ],
    [ 21.35,  11.18,  -0.17,  11.39 ],
    [ 24.29,  10.87,  -0.17,  11.66 ],
    [ 27.23,  10.49,   0.36,  12.37 ],
    [ 30.16,  10.07,   2.09,  13.38 ],
    [ 33.10,   9.64,   4.12,  13.97 ],
    [ 36.04,   8.74,   5.95,  13.68 ],
    [ 38.98,   6.18,   8.14,  12.29 ],
    [ 39.57,   4.47,   8.92,  11.56 ],  // measured tip end-cap
];

table = which == "thumb" ? table_thumb
      : which == "short" ? table_short
      :                    table_std;

// ---- build -----------------------------------------------------------------
// One 2D cross-section: rounded rect of (Xw, Zt) centred on X, lifted to Zmid.
// Built in the XY plane (local x = model X width, local y = model Z thickness),
// then the whole loft is rotated so its stacking axis becomes model Y.
function zt(row)   = row[3] - row[2];          // thickness  = Zmax - Zmin
function zmid(row) = (row[3] + row[2]) / 2;    // vertical centre
// Per-corner rounding, clamped so it never exceeds the section (the tip end-cap
// is only 1.87 thick). $fn stays fixed so every profile keeps the same point
// count -> skin() correspondence is preserved (all radii must stay > 0).
function topr(row) = min(top_frac * row[1] / 2, zt(row) * 0.55);
function botr(row) = let(zmin = row[2], lift = round_frac * row[1] / 2,
        b = zmin < 0.5 ? bot_r_flat
          : zmin > 2.0 ? lift
          : bot_r_flat + (lift - bot_r_flat) * (zmin - 0.5) / 1.5)
        min(b, zt(row) * 0.40);
// rounding vector order = [top-right, top-left, bottom-left, bottom-right]
function rvec(row) = [topr(row), topr(row), botr(row), botr(row)];

module section(row) {
    move([0, zmid(row)])
        rect([row[1], zt(row)], rounding = rvec(row), $fn = prof_fn);
}

// Solid outer loft, built in the LOCAL frame (loft axis = +Z = h, thickness = Y).
module finger_solid(tbl) {
    profiles = [ for (r = tbl) move([0, zmid(r)],
                    rect([r[1], zt(r)], rounding = rvec(r), $fn = prof_fn)) ];
    heights  = [ for (r = tbl) r[0] ];
    skin(profiles, z = heights, slices = loft_slices, caps = true);
}

// Internal cuts in the LOCAL frame (x=width, y=thickness/Z, z=h along length).
// ft = per-size feature vector [slot_h1,pin_z,groove_h1,bh0,bh1,bz0,bz1].
module internal_cuts(ft) {
    // clevis fork slot — through the full thickness, from below the heel to slot_h1
    translate([-slot_w/2, -2, -1]) cube([slot_w, 20, ft[0] + 1]);
    // pivot pin hole — round bore flattened top & bottom (axis along local x)
    intersection() {
        translate([0, ft[1], pin_h]) rotate([0, 90, 0])
            cylinder(h = 24, r = pin_r, center = true, $fn = hole_fn);
        translate([-12, ft[1] - pin_flat, pin_h - 4]) cube([24, 2 * pin_flat, 8]);
    }
    // tendon top groove — only the upper part (Z >= groove_z0), continues the slot
    translate([-slot_w/2, groove_z0, ft[0]])
        cube([slot_w, 18 - groove_z0, ft[2] - ft[0]]);
    // flexor underside: two rounded grooves leave a central fin, then an open pocket
    flexor_cut();
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
    translate([0, (ft[5] + ft[6]) / 2, (ft[3] + ft[4]) / 2])
        cuboid([slot_w, ft[6] - ft[5], ft[4] - ft[3]],
               rounding = bridge_r, edges = "X", $fn = 24);
}

// One finger: outer loft minus internal features. tbl = profile table, ft = feats.
module finger(tbl, ft) {
    // rotate([90,0,0]) lays the loft axis along Y with thickness up (+Z); mirror
    // flips it so the heel sits at the +Y origin and the tip points +Y.
    mirror([0, 1, 0])
        rotate([90, 0, 0])
            if (add_internals)
                union() {
                    difference() { finger_solid(tbl); internal_cuts(ft); }
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
    [ table_thumb, feat_thumb, -27.08 ],   // thumb  (orig Xc 40.76)
    [ table_std,   feat_std,   -12.40 ],   // index  (orig Xc 55.44)
    [ table_std,   feat_std,     0.66 ],   // middle (orig Xc 68.50)
    [ table_short, feat_short,  13.26 ],   // ring   (orig Xc 81.10)
    [ table_short, feat_short,  25.57 ],   // pinky  (orig Xc 93.41)
];

module model() {
    if (show_set) for (e = set_layout) translate([e[2], 0, 0]) finger(e[0], e[1]);
    else          finger(table, feat);
}

// --- Assembly entry points ---------------------------------------------------
// Named wrappers so an external assembly can `use <Distals_v2.scad>` and draw a
// specific size directly (the `which` global can't be set across a `use`). Each
// draws a distal in its own frame: heel (PIP fork) at Y=0, tip toward +Y, flat
// bottom on Z0; the PIP pin passes at (Y = pin_h, Z = pin_z) along X.
module distal_std()   finger(table_std,   feat_std);
module distal_short() finger(table_short, feat_short);
module distal_thumb() finger(table_thumb, feat_thumb);

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
