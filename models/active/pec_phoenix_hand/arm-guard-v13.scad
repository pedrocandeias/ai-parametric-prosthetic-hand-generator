// ============================================
// Arm Guard — Parametric Reconstruction v13
// Fixes vs v12:
//   Center rib transition: linear hull → fitted circular arc top
//     (arc center Y=23.58 Z=-11.14 R=16.05; matches probed 3.0/3.9/4.5/4.8/4.9 at Y=16/18/20/22/24).
//   Side ribs: outer face inset 1.0mm so a wing-height lip remains at the part edge
//     (probed: rib top ends ~1mm inboard of outer polygon, then drops to wing_h).
// v12 fixes:
//   Boss: nominal radius 7.85→8.0mm; toroidal fillet on top outer edge.
//   Probed: fillet_r=1.017mm, center at (R=6.983, Z=2.783). Verified at R=7.1-7.9mm.
// ============================================

$fn = 64;
eps = 0.01;

// Layer heights
base_h         = 1.40;
wing_h         = 1.80;
side_rib_h     = 2.80;
rib_h          = 4.892;

// Wing zone
wing_x_cut     = 14.5;

// Side rib zone: chamfered inner face — slope_start (at wing_h) to slope_end (at side_rib_h)
// Probed: 1.5mm wide chamfer, slope -0.15/mm of Y (parallel to outer polygon edge)
// slope_start at Y=0: X=36.25, at Y=61: X=27.10
// slope_end  at Y=0: X=37.75, at Y=61: X=28.60
// Chamfer narrowed 1.5→1.0mm wide (probed: inner face ramps 1.8→2.8 over ~1.0mm in X)
rib_inner_x_bot_start = 36.50;  // inner boundary at wing_h (slope start) at Y=0
rib_inner_x_top_start = 27.20;  // inner boundary at wing_h (slope start) at Y=62
rib_inner_x_bot_end   = 37.50;  // inner boundary at side_rib_h (slope end) at Y=0
rib_inner_x_top_end   = 28.20;  // inner boundary at side_rib_h (slope end) at Y=62
side_rib_y_end         = 62.0;  // probed: rib end is slanted (inner~61.5, outer~62.5); 62.0 compromise
side_rib_outer_lip    = 1.0;    // wing-height border outboard of rib (rib outer face inset this far)

// Lower base profile (concave inner area above Y=56)
lower_base_h   = 0.90;
lower_base_y   = 56.0;

// Boss geometry (toroidal fillet on top outer edge)
boss_nominal_r = 8.00;   // actual outer radius (probed: extends to R≈7.995mm)
boss_fillet_r  = 1.017;  // toroidal fillet radius (fitted to probe data)
boss_fillet_rc = boss_nominal_r - boss_fillet_r;  // 6.983: fillet center R
boss_fillet_zc = 3.80 - boss_fillet_r;             // 2.783: fillet center Z
boss_x    = 30.145;
boss_y    = 79.005;
boss_h    = 3.80;
// Boss hole = central through-slot + wider bottom counterbore (probed by vertical ray columns):
//   through (full depth): 5.0(x) x 5.25(y); counterbore (from bottom, 2.3 deep): 5.0(x) x 6.75(y)
//   leaves a 1.5mm-thick roof at the two Y-ends of the pocket.
boss_through_w = 5.00;
boss_through_h = 5.25;
boss_cb_w      = 5.00;
boss_cb_h      = 6.75;
boss_cb_depth  = 2.30;

// Center rib (tapered: narrow/short near bottom, grows to full at Y=24)
rib_lo_top_hw = 3.5;  // half-width of flat top at low section (probed: edge at X=3.5)
rib_base_hw   = 5.0;  // half-width at Z=0 base (where rib meets base plate)
rib_hi_hw     = 4.78; // half-width of full section (probed: edge at X≈4.77)
rib_lo_h      = 2.88; // height of low section
rib_hi_h      = 4.88; // height of full section
rib_lo_y      = 1.0;  // rib starts at Y=1
rib_mid_y     = 16.0; // end of low section (probed: flat top until Y=16)
rib_full_y    = 24.0; // end of transition, start of full section (probed: full height from Y=24)
// Transition top follows a circular arc (fitted to probed top-Z at Y=16..24)
rib_arc_yc    = 23.58;  // arc center Y
rib_arc_zc    = -11.14; // arc center Z
rib_arc_R     = 16.05;  // arc radius
rib_trans_n   = 24.0;     // slab count across transition
rib_top_y  = 51.0;  // start of dome cap
rib_cap_hw = 2.5;   // half-width at top of cap
rib_cap_h  = 3.90;  // height at top of cap
rib_cap_y  = 54.0;  // end of dome cap

// Strap slots — probed width 4.2mm; tilted to follow outer polygon edge slope
// Outer edge angle: atan(4.354/28.863) ≈ 8.58° from Y axis (tilts left going up)
slot_w        = 4.2;
slot_len      = 19.82;
slot_rot      = 8.58;   // right side: +8.58° tilts long axis to follow outer edge (dx/dy=-0.151)
slot_upper_x  = 35.041;
slot_upper_y  = 48.998;
slot_lower_x  = 40.035;
slot_lower_y  = 15.888;

outer_pts = [
  [42.070, 0.025], [42.608, 0.098], [43.137, 0.220], [43.653, 0.389],
  [44.152, 0.605], [44.629, 0.864], [45.081, 1.166], [45.503, 1.507],
  [45.893, 1.885], [46.248, 2.296], [46.563, 2.738], [46.837, 3.207],
  [47.068, 3.699], [47.254, 4.209], [47.392, 4.735], [47.483, 5.270],
  [47.524, 5.812], [47.517, 6.355], [47.460, 6.895],
  [43.106, 35.758], [38.970, 63.181], [38.140, 68.680],
  [38.140, 79.005], [38.115, 79.632], [38.042, 80.256], [37.919, 80.871],
  [37.749, 81.476], [37.531, 82.065], [37.269, 82.635], [36.962, 83.182],
  [36.613, 83.704], [36.224, 84.197], [35.798, 84.658], [35.337, 85.084],
  [34.844, 85.473], [34.322, 85.822], [33.775, 86.129], [33.205, 86.391],
  [32.616, 86.609], [32.011, 86.779], [31.396, 86.902], [30.772, 86.975],
  [30.145, 87.000], [29.518, 86.975], [28.894, 86.902], [28.279, 86.779],
  [27.674, 86.609], [27.085, 86.391], [26.515, 86.129], [25.968, 85.822],
  [25.446, 85.473], [24.953, 85.084], [24.492, 84.658], [24.066, 84.197],
  [23.677, 83.704], [23.328, 83.182], [23.021, 82.635], [22.759, 82.065],
  [22.541, 81.476], [22.371, 80.871], [22.248, 80.256], [22.175, 79.632],
  [22.150, 79.005], [22.150, 68.680],
  [21.316, 68.349], [20.647, 68.084], [19.804, 67.777], [19.127, 67.531],
  [18.276, 67.248], [17.592, 67.022], [16.733, 66.764], [16.043, 66.558],
  [15.177, 66.325], [14.481, 66.138], [14.170, 66.061], [13.905, 65.997],
  [13.760, 65.474], [13.676, 65.191], [13.501, 64.678], [13.399, 64.400],
  [13.195, 63.898], [13.078, 63.627], [12.845, 63.137], [12.711, 62.874],
  [12.450, 62.398], [12.301, 62.143], [12.014, 61.684], [11.850, 61.438],
  [11.536, 60.996], [11.357, 60.760], [11.018, 60.337], [10.826, 60.112],
  [10.464, 59.709], [10.259, 59.496], [9.873, 59.115], [9.656, 58.915],
  [9.249, 58.556], [9.020, 58.369], [8.593, 58.035], [8.354, 57.862],
  [7.908, 57.553], [7.659, 57.394], [7.196, 57.112], [6.938, 56.968],
  [6.459, 56.713], [6.193, 56.585], [5.701, 56.357], [5.427, 56.246],
  [4.923, 56.047], [4.643, 55.952], [4.128, 55.782], [3.843, 55.704],
  [3.319, 55.565], [3.030, 55.504], [2.499, 55.395], [2.206, 55.351],
  [1.670, 55.273], [1.375, 55.247], [0.835, 55.200], [0.540, 55.191],
  [-0.002, 55.176], [-0.544, 55.191], [-0.839, 55.200], [-1.379, 55.247],
  [-1.674, 55.274], [-2.210, 55.352], [-2.502, 55.396], [-3.033, 55.505],
  [-3.322, 55.566], [-3.846, 55.705], [-4.131, 55.783], [-4.646, 55.953],
  [-4.926, 56.048], [-5.430, 56.247], [-5.704, 56.358], [-6.195, 56.586],
  [-6.462, 56.714], [-6.940, 56.969], [-7.198, 57.113], [-7.661, 57.396],
  [-7.910, 57.554], [-8.355, 57.863], [-8.595, 58.036], [-9.022, 58.371],
  [-9.251, 58.558], [-9.657, 58.916], [-9.875, 59.116], [-10.260, 59.497],
  [-10.465, 59.710], [-10.827, 60.113], [-11.019, 60.338], [-11.358, 60.761],
  [-11.537, 60.997], [-11.850, 61.438], [-12.014, 61.684], [-12.302, 62.144],
  [-12.451, 62.399], [-12.711, 62.874], [-12.845, 63.138], [-13.078, 63.627],
  [-13.195, 63.898], [-13.400, 64.400], [-13.501, 64.678], [-13.676, 65.191],
  [-13.760, 65.475], [-13.905, 65.997], [-14.170, 66.061], [-14.481, 66.138],
  [-15.177, 66.325], [-16.043, 66.558], [-16.733, 66.764], [-17.592, 67.022],
  [-18.276, 67.248], [-19.127, 67.531], [-19.804, 67.777], [-20.647, 68.084],
  [-21.316, 68.349], [-22.150, 68.680],
  [-22.150, 79.005], [-22.175, 79.632], [-22.248, 80.256], [-22.371, 80.871],
  [-22.541, 81.476], [-22.759, 82.065], [-23.021, 82.635], [-23.328, 83.182],
  [-23.677, 83.704], [-24.066, 84.197], [-24.492, 84.658], [-24.953, 85.084],
  [-25.446, 85.473], [-25.968, 85.822], [-26.515, 86.129], [-27.085, 86.391],
  [-27.674, 86.609], [-28.279, 86.779], [-28.894, 86.902], [-29.518, 86.975],
  [-30.145, 87.000], [-30.772, 86.975], [-31.396, 86.902], [-32.011, 86.779],
  [-32.616, 86.609], [-33.205, 86.391], [-33.775, 86.129], [-34.322, 85.822],
  [-34.844, 85.473], [-35.337, 85.084], [-35.798, 84.658], [-36.224, 84.197],
  [-36.613, 83.704], [-36.962, 83.182], [-37.269, 82.635], [-37.531, 82.065],
  [-37.749, 81.476], [-37.919, 80.871], [-38.042, 80.256], [-38.115, 79.632],
  [-38.140, 79.005], [-38.140, 68.680],
  [-38.970, 63.181], [-43.106, 35.758],
  [-47.460, 6.895], [-47.517, 6.355], [-47.524, 5.812], [-47.483, 5.270],
  [-47.392, 4.735], [-47.254, 4.209], [-47.068, 3.699], [-46.837, 3.207],
  [-46.563, 2.738], [-46.248, 2.296], [-45.893, 1.885], [-45.503, 1.507],
  [-45.081, 1.166], [-44.629, 0.864], [-44.152, 0.605], [-43.653, 0.389],
  [-43.137, 0.220], [-42.608, 0.098], [-42.070, 0.025], [-41.527, 0.000],
  [41.527, 0.000]
];

// Inner scalloped valley polygon (defines the lower-profile zone)
inner_scallop_pts = [
  [22.150, 68.680], [21.316, 68.349], [20.647, 68.084], [19.804, 67.777],
  [19.127, 67.531], [18.276, 67.248], [17.592, 67.022], [16.733, 66.764],
  [16.043, 66.558], [15.177, 66.325], [14.481, 66.138], [14.170, 66.061],
  [13.905, 65.997], [13.760, 65.474], [13.676, 65.191], [13.501, 64.678],
  [13.399, 64.400], [13.195, 63.898], [13.078, 63.627], [12.845, 63.137],
  [12.711, 62.874], [12.450, 62.398], [12.301, 62.143], [12.014, 61.684],
  [11.850, 61.438], [11.536, 60.996], [11.357, 60.760], [11.018, 60.337],
  [10.826, 60.112], [10.464, 59.709], [10.259, 59.496], [9.873, 59.115],
  [9.656, 58.915], [9.249, 58.556], [9.020, 58.369], [8.593, 58.035],
  [8.354, 57.862], [7.908, 57.553], [7.659, 57.394], [7.196, 57.112],
  [6.938, 56.968], [6.459, 56.713], [6.193, 56.585], [5.701, 56.357],
  [5.427, 56.246], [4.923, 56.047], [4.643, 55.952], [4.128, 55.782],
  [3.843, 55.704], [3.319, 55.565], [3.030, 55.504], [2.499, 55.395],
  [2.206, 55.351], [1.670, 55.273], [1.375, 55.247], [0.835, 55.200],
  [0.540, 55.191], [-0.002, 55.176], [-0.544, 55.191], [-0.839, 55.200],
  [-1.379, 55.247], [-1.674, 55.274], [-2.210, 55.352], [-2.502, 55.396],
  [-3.033, 55.505], [-3.322, 55.566], [-3.846, 55.705], [-4.131, 55.783],
  [-4.646, 55.953], [-4.926, 56.048], [-5.430, 56.247], [-5.704, 56.358],
  [-6.195, 56.586], [-6.462, 56.714], [-6.940, 56.969], [-7.198, 57.113],
  [-7.661, 57.396], [-7.910, 57.554], [-8.355, 57.863], [-8.595, 58.036],
  [-9.022, 58.371], [-9.251, 58.558], [-9.657, 58.916], [-9.875, 59.116],
  [-10.260, 59.497], [-10.465, 59.710], [-10.827, 60.113], [-11.019, 60.338],
  [-11.358, 60.761], [-11.537, 60.997], [-11.850, 61.438], [-12.014, 61.684],
  [-12.302, 62.144], [-12.451, 62.399], [-12.711, 62.874], [-12.845, 63.138],
  [-13.078, 63.627], [-13.195, 63.898], [-13.400, 64.400], [-13.501, 64.678],
  [-13.676, 65.191], [-13.760, 65.475], [-13.905, 65.997], [-14.170, 66.061],
  [-14.481, 66.138], [-15.177, 66.325], [-16.043, 66.558], [-16.733, 66.764],
  [-17.592, 67.022], [-18.276, 67.248], [-19.127, 67.531], [-19.804, 67.777],
  [-20.647, 68.084], [-21.316, 68.349], [-22.150, 68.680], [22.150, 68.680]
];

module center_rib() {
    len_lo = rib_mid_y - rib_lo_y;  // Y=1 to Y=15

    union() {
        // Low section flat-top body (Y=1-15): cube at full height, narrower top
        translate([-rib_lo_top_hw, rib_lo_y, 0])
            cube([rib_lo_top_hw*2, len_lo, rib_lo_h]);

        // Sloped side wedges (Y=1-15): from X=3.5 (Z=2.88) down to X=5.0 (Z=base_h)
        // Right side
        hull() {
            translate([rib_lo_top_hw, rib_lo_y, base_h]) cube([1.5, len_lo, eps]);
            translate([rib_lo_top_hw, rib_lo_y, rib_lo_h]) cube([eps, len_lo, eps]);
        }
        // Left side (mirror)
        hull() {
            translate([-rib_lo_top_hw - 1.5, rib_lo_y, base_h]) cube([1.5, len_lo, eps]);
            translate([-rib_lo_top_hw - eps, rib_lo_y, rib_lo_h]) cube([eps, len_lo, eps]);
        }

        // Transition (Y=16-24): top follows a circular arc, width grows lo→full.
        // Slab i spans [y0,y1]; height = arc value at slab midpoint (clamped to rib_hi_h).
        for (i = [0 : rib_trans_n - 1]) {
            y0 = rib_mid_y + i       * (rib_full_y - rib_mid_y) / rib_trans_n;
            y1 = rib_mid_y + (i + 1) * (rib_full_y - rib_mid_y) / rib_trans_n;
            ym = (y0 + y1) / 2;
            f  = (ym - rib_mid_y) / (rib_full_y - rib_mid_y);
            fw = min(1, f / 0.30);  // width reaches full by ~Y=18.4 (probed: full width by Y=18)
            hw = rib_lo_top_hw + fw * (rib_hi_hw - rib_lo_top_hw);
            zarc = rib_arc_zc + sqrt(rib_arc_R*rib_arc_R - (ym - rib_arc_yc)*(ym - rib_arc_yc));
            h  = min(zarc, rib_hi_h);
            translate([-hw, y0, 0]) cube([hw*2, y1 - y0, h]);
        }

        // Full section: vertical walls (Y=26-51)
        translate([-rib_hi_hw, rib_full_y, 0])
            cube([rib_hi_hw*2, rib_top_y - rib_full_y, rib_hi_h]);

        // Dome cap: hull from full to small cap (Y=51-54)
        hull() {
            translate([-rib_hi_hw, rib_top_y, 0])
                cube([rib_hi_hw*2, eps, rib_hi_h]);
            translate([-rib_cap_hw, rib_cap_y, 0])
                cube([rib_cap_hw*2, eps, rib_cap_h]);
        }
    }
}

// Boss with toroidal fillet on top outer edge: rotate_extrude of RZ cross-section
module boss_profile_2d() {
    n = 20;
    arc_pts = [for (i = [0:n])
        let(a = i / n * 90)
        [boss_fillet_rc + boss_fillet_r * cos(a), boss_fillet_zc + boss_fillet_r * sin(a)]
    ];
    polygon(concat(
        [[0, 0], [boss_nominal_r, 0], [boss_nominal_r, boss_fillet_zc]],
        arc_pts,
        [[0, boss_h]]
    ));
}

module boss_3d() { rotate_extrude($fn=64) boss_profile_2d(); }

module strap_slot_2d(w, len) {
    r = w / 2;
    hull() {
        translate([0,  (len/2 - r)]) circle(r=r);
        translate([0, -(len/2 - r)]) circle(r=r);
    }
}

module boss_hole_2d(w, h) { translate([-w/2, -h/2]) square([w, h]); }

// Wing zone: full polygon for |X| > wing_x_cut (both sides)
module wing_zone_2d() {
    for (sx = [-1, 1])
        intersection() {
            polygon(outer_pts);
            translate([sx > 0 ? wing_x_cut : -200, -eps])
                square([200 - wing_x_cut, 87 + 2*eps]);
        }
}

// Side rib zone: chamfered inner face modeled as hull of two cross-sections
// At wing_h: inner boundary at slope_start (wider); at side_rib_h: at slope_end (narrower)
module side_rib_zone_chamfer() {
    for (sx = [-1, 1]) {
        mirror([sx < 0 ? 1 : 0, 0])
        hull() {
            translate([0, 0, wing_h]) linear_extrude(eps)
                intersection() {
                    offset(r = -side_rib_outer_lip) polygon(outer_pts);
                    polygon([
                        [rib_inner_x_bot_start, -eps],
                        [200, -eps],
                        [200, side_rib_y_end + eps],
                        [rib_inner_x_top_start, side_rib_y_end + eps]
                    ]);
                }
            translate([0, 0, side_rib_h]) linear_extrude(eps)
                intersection() {
                    offset(r = -side_rib_outer_lip) polygon(outer_pts);
                    polygon([
                        [rib_inner_x_bot_end, -eps],
                        [200, -eps],
                        [200, side_rib_y_end + eps],
                        [rib_inner_x_top_end, side_rib_y_end + eps]
                    ]);
                }
        }
    }
}

// Groove zone: 2.5mm ring OUTSIDE inner_scallop boundary, clipped to Y=56–68
// This lowers the base from 1.40mm to 0.90mm at the scallop boundary transition
module lower_zone_2d() {
    intersection() {
        difference() {
            offset(r = 2.5) polygon(inner_scallop_pts);
            polygon(inner_scallop_pts);
        }
        translate([-30, lower_base_y]) square([60, 12]);  // Y=56 to Y=68
    }
}

// --- Assembly ---
// Wrapped in a module so an external assembly can `use <arm-guard-v13.scad>` and
// place arm_guard() without the standalone render firing. no_assembly suppresses
// the standalone call when this file is included by a driver.
module arm_guard()
difference() {
    union() {
        // Layer 1: Full base plate
        linear_extrude(height = base_h) polygon(outer_pts);

        // Layer 2: Outer wings (above base plate)
        translate([0, 0, base_h])
            linear_extrude(h = wing_h - base_h)
                wing_zone_2d();

        // Layer 3: Outer side ribs with chamfered inner face
        side_rib_zone_chamfer();

        // Bosses (with toroidal fillet on top outer edge)
        for (sx = [-1, 1])
            translate([sx * boss_x, boss_y, 0])
                boss_3d();

        // Center rib (tapered)
        center_rib();

        // Inner scallop floor: 0.9mm thin plate clipped to Y=56-64 (probed: floor only there)
        linear_extrude(height = lower_base_h)
            intersection() {
                polygon(inner_scallop_pts);
                translate([-25, 56]) square([50, 8]);
            }
    }

    // Boss holes: central through-slot + wider bottom counterbore (leaves roof at Y-ends)
    for (sx = [-1, 1]) {
        translate([sx * boss_x, boss_y, -eps])
            linear_extrude(height = boss_h + 2*eps)
                boss_hole_2d(boss_through_w, boss_through_h);
        translate([sx * boss_x, boss_y, -eps])
            linear_extrude(height = boss_cb_depth + eps)
                boss_hole_2d(boss_cb_w, boss_cb_h);
    }

    // Strap slots — tilted to align with slanted outer edge (sx mirrors tilt for left side)
    for (sx = [-1, 1]) {
        translate([sx * slot_upper_x, slot_upper_y, -eps])
            rotate([0, 0, sx * slot_rot])
            linear_extrude(height = side_rib_h + 2*eps)
                strap_slot_2d(slot_w, slot_len);
        translate([sx * slot_lower_x, slot_lower_y, -eps])
            rotate([0, 0, sx * slot_rot])
            linear_extrude(height = side_rib_h + 2*eps)
                strap_slot_2d(slot_w, slot_len);
    }

    // Lower base profile: concave inner zone (Y > 56, |X| < 14.5) thinner at 0.9mm
    translate([0, 0, lower_base_h])
        linear_extrude(h = base_h - lower_base_h + eps)
            lower_zone_2d();
}

// standalone render (suppressed when a driver sets no_assembly=true before use/include)
if (is_undef(no_assembly) || !no_assembly) arm_guard();
