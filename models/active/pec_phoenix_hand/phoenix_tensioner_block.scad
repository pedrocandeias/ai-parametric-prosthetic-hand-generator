// ====================================================================
// Tensioner_Block — step2scad parametric reconstruction
// source: models/phoenix_components/Tensioner_Block.step
// Every dimension is measured from the STEP B-rep (exact faces) or a
// fitted law with its residual cited — see the source comment on each
// parameter. Edit named parameters; geometry follows.
// ====================================================================

// --- Display options ---
show_colors   = false;    // tint top-level features (preview aid)
show_original = false;   // ghost the original tessellation overlay
original_stl  = "Tensioner_Block_ref.stl";
module tint(c) { if (show_colors) color(c) children(); else children(); }

// --------------------------------------------------------------------
// BODY 0 — semantic parametric plan
//   fully parametric: vectorized outlines (tol 0.02), channels as
//   measured rectangles (side pair mirrored, verified exact), exact z
//   planes/bores/sphere. IoU 0.9904 vs v1 0.9984 (parametric cost
//   -0.0080, mostly outline vectorization)
// Anatomy (modules):
//   side_channel() — side pin channel (right
//   flange_bore() — flange pin bore: exact r1.5 cylinder, bottom overshoot 0.5
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- z ---
z_bot         = 0.000976;  // exact bottom plane #9
z_ledge       = 1.297944;  // exact ledge plane #27/#37/#4 (flange top, channel floors)
z_top         = 27.999562;  // exact top plane #35
// --- chan ---
chan_side_cx  = 6.161516;  // side pin-channel rect center x (rect fit res 0.000; left channel = exact mirror, max delta 0.0000)
chan_side_cy  = -0.563786;  // side pin-channel rect center y (same fit)
chan_side_w   = 5.004034;  // side channel width (same fit)
chan_side_h   = 5.004031;  // side channel depth (same fit)
chan_side_ang = 4.998501;  // side channel tilt about z (same fit)
chan_ctr_cy   = -0.866656;  // center channel rect center y (rect fit res 0.000; axis-aligned within 0.2°)
chan_ctr_w    = 4.898075;  // center channel width (same fit)
chan_ctr_h    = 5.004002;  // center channel depth (same fit)
// --- bore ---
bore_r        = 1.5;  // exact flange bore cylinder faces (r=1.5, full circle)
bore_side_x   = 6.146556;  // exact side bore axes (±x)
bore_side_y   = -0.580505;  // exact side bore axes y
bore_ctr_y    = -0.882004;  // exact center bore axis y
fn            = 96;  // curve resolution

tower_outline_pts = concat(
            [[3.748039, 4.126619]],
            [[5.492145, 2.319238]],
            [[-5.492142, 2.319238]],
            [[-3.748036, 4.126619]],
            [[-3.748036, 4.549237]],
            [[-3.867543, 4.549237]],
            [[-4.834481, 5.516236]],
            [[-6.14127, 5.516236]],
            [for (k = [1 : 5]) [(-3.978985) + (9.205339)*cos((103.584238) + k*((131.561369) - (103.584238))/5), (-3.432351) + (9.205339)*sin((103.584238) + k*((131.561369) - (103.584238))/5)]],
            [for (k = [1 : 11]) [(-7.573113) + (4.007753)*cos((128.597162) + k*((192.04694) - (128.597162))/11), (0.307516) + (4.007753)*sin((128.597162) + k*((192.04694) - (128.597162))/11)]],
            [for (k = [1 : 8]) [(-6.54195) + (5.154118)*cos((-163.826756) + k*((-120.0765) - (-163.826756))/8), (0.906015) + (5.154118)*sin((-163.826756) + k*((-120.0765) - (-163.826756))/8)]],
            [[-8.931038, -3.982764]],
            [for (k = [1 : 5]) [(-5.492671) + (6.341919)*cos((-122.876101) + k*((-97.149786) - (-122.876101))/5), (1.337006) + (6.341919)*sin((-122.876101) + k*((-97.149786) - (-122.876101))/5)]],
            [for (k = [1 : 3]) [(-1.356136) + (23.996609)*cos((-101.848233) + k*((-92.394679) - (-101.848233))/3), (18.521564) + (23.996609)*sin((-101.848233) + k*((-92.394679) - (-101.848233))/3)]],
            [for (k = [1 : 3]) [(0.040342) + (47.929829)*cos((-92.869166) + k*((-87.501519) - (-92.869166))/3), (42.415001) + (47.929829)*sin((-92.869166) + k*((-87.501519) - (-92.869166))/3)]],
            [[3.012273, -5.407047]],
            [for (k = [1 : 3]) [(1.789834) + (21.4768)*cos((-86.736987) + k*((-74.622355) - (-86.736987))/3), (16.034746) + (21.4768)*sin((-86.736987) + k*((-74.622355) - (-86.736987))/3)]],
            [for (k = [1 : 4]) [(6.196284) + (4.737969)*cos((-74.215672) + k*((-54.744153) - (-74.215672))/4), (-0.11401) + (4.737969)*sin((-74.215672) + k*((-54.744153) - (-74.215672))/4)]],
            [[9.134355, -3.570344]],
            [for (k = [1 : 7]) [(6.446311) + (5.281343)*cos((-59.513371) + k*((-19.133048) - (-59.513371))/7), (0.995486) + (5.281343)*sin((-59.513371) + k*((-19.133048) - (-59.513371))/7)]],
            [for (k = [1 : 11]) [(7.625574) + (3.954466)*cos((-15.550123) + k*((50.316981) - (-15.550123))/11), (0.325423) + (3.954466)*sin((-15.550123) + k*((50.316981) - (-15.550123))/11)]],
            [for (k = [1 : 3]) [(4.20308) + (8.797261)*cos((47.358423) + k*((63.288968) - (47.358423))/3), (-3.088481) + (8.797261)*sin((47.358423) + k*((63.288968) - (47.358423))/3)]],
            [for (k = [1 : 3]) [(3.41089) + (10.860656)*cos((64.07917) + k*((75.440089) - (64.07917))/3), (-4.996012) + (10.860656)*sin((64.07917) + k*((75.440089) - (64.07917))/3)]],
            [[4.834484, 5.516236]],
            [[3.867546, 4.549237]],
            [[3.748039, 4.549237]]);  // vectorized measured outline: 14 lines + 12 fitted arcs (0 snapped to exact B-rep faces), tol 0.02
flange_outline_pts = concat(
            [[3.748019, 4.126359]],
            [[5.492123, 2.318979]],
            [[-5.492161, 2.318979]],
            [[-3.748056, 4.126359]],
            [[-3.750613, 4.548977]],
            [[-3.867563, 4.548977]],
            [[-4.834501, 5.515976]],
            [[-6.14129, 5.515976]],
            [for (k = [1 : 6]) [(-4.16436) + (8.803844)*cos((102.960297) + k*((137.403644) - (102.960297))/6), (-3.074201) + (8.803844)*sin((102.960297) + k*((137.403644) - (102.960297))/6)]],
            [for (k = [1 : 14]) [(-7.702393) + (3.878664)*cos((139.093715) + k*((220.534792) - (139.093715))/14), (0.334276) + (3.878664)*sin((139.093715) + k*((220.534792) - (139.093715))/14)]],
            [for (k = [1 : 3]) [(-5.261413) + (7.020838)*cos((-140.29582) + k*((-123.468596) - (-140.29582))/3), (2.287772) + (7.020838)*sin((-140.29582) + k*((-123.468596) - (-140.29582))/3)]],
            [[-8.931059, -3.983024]],
            [for (k = [1 : 5]) [(-5.764875) + (5.707575)*cos((-123.722932) + k*((-99.089822) - (-123.722932))/5), (0.760355) + (5.707575)*sin((-123.722932) + k*((-99.089822) - (-123.722932))/5)]],
            [for (k = [1 : 3]) [(-0.068585) + (34.830874)*cos((-100.927494) + k*((-84.929835) - (-100.927494))/3), (29.297865) + (34.830874)*sin((-100.927494) + k*((-84.929835) - (-100.927494))/3)]],
            [for (k = [1 : 3]) [(2.287607) + (18.309193)*cos((-87.738465) + k*((-71.173053) - (-87.738465))/3), (12.898815) + (18.309193)*sin((-87.738465) + k*((-71.173053) - (-87.738465))/3)]],
            [[8.525207, -4.240757]],
            [[8.931021, -3.983024]],
            [[9.134334, -3.570604]],
            [for (k = [1 : 7]) [(6.446295) + (5.281338)*cos((-59.513402) + k*((-19.133032) - (-59.513402))/7), (0.995223) + (5.281338)*sin((-59.513402) + k*((-19.133032) - (-59.513402))/7)]],
            [for (k = [1 : 11]) [(7.625553) + (3.954466)*cos((-15.550132) + k*((50.316972) - (-15.550132))/11), (0.325163) + (3.954466)*sin((-15.550132) + k*((50.316972) - (-15.550132))/11)]],
            [for (k = [1 : 5]) [(3.987894) + (9.193426)*cos((47.792872) + k*((76.459052) - (47.792872))/5), (-3.425255) + (9.193426)*sin((47.792872) + k*((76.459052) - (47.792872))/5)]],
            [[4.834463, 5.515976]],
            [[3.864969, 4.548977]],
            [[3.748019, 4.548977]]);  // vectorized measured outline: 15 lines + 9 fitted arcs (0 snapped to exact B-rep faces), tol 0.02

// side pin channel (right; the left one is the exact mirror): rotated-rect prism from the ledge plane through the top
module side_channel() {
    // side_chan_box: measured rotated rectangle (fit residual in params); floor = exact ledge plane
    translate([chan_side_cx, chan_side_cy, (z_ledge + z_top + 1)/2]) rotate([0, 0, chan_side_ang]) cube([chan_side_w, chan_side_h, z_top + 1 - z_ledge], center=true);
}

// flange pin bore: exact r1.5 cylinder, bottom overshoot 0.5
module flange_bore(cx, cy) {
    // bore_cyl: exact full-circle cylinder face (r = bore_r)
    translate([cx, cy, z_bot - 0.5]) cylinder(h=(z_ledge) - (z_bot - 0.5), r=bore_r, $fn=fn);
}

module tblock_body_0() {
    difference() {
        union() {
            // flange: bottom flange: vectorized measured outline between the exact bottom and ledge planes
            translate([0, 0, z_bot]) linear_extrude((z_ledge) - (z_bot)) polygon(flange_outline_pts);
            // tower: prismatic tower: vectorized measured outline between the exact ledge and top planes
            translate([0, 0, z_ledge]) linear_extrude((z_top) - (z_ledge)) polygon(tower_outline_pts);
            // detent: snap-detent boss: exact sphere face #0
            translate([-0.001453, 2.319861, 2.400416]) sphere(r=1.081224, $fn=fn);
        }
        side_channel();  // chan_right
        mirror([1, 0, 0]) {  // chan_left
            side_channel();  // chan_left_i
        }
        // center_channel: center pin channel: measured axis-aligned rectangle (fit residual in params); floor = exact ledge plane
        translate([0, chan_ctr_cy, (z_ledge + z_top + 1)/2]) cube([chan_ctr_w, chan_ctr_h, z_top + 1 - z_ledge], center=true);
        flange_bore(bore_side_x, bore_side_y);  // bore_right
        flange_bore(-bore_side_x, bore_side_y);  // bore_left
        flange_bore(0, bore_ctr_y);  // bore_center
    }
}


// ---- assembly helper: block sits base-at-z0, oval section centred on XY origin ----
module tensioner_block_centered(){ tblock_body_0(); }
