// ====================================================================
// Tensioner_Pins — step2scad parametric reconstruction
// source: models/phoenix_components/Tensioner_Pins.step
// Every dimension is measured from the STEP B-rep (exact faces) or a
// fitted law with its residual cited — see the source comment on each
// parameter. Edit named parameters; geometry follows.
// ====================================================================

// --- Display options ---
show_colors   = false;    // tint top-level features (preview aid)
show_original = false;   // ghost the original tessellation overlay
original_stl  = "Tensioner_Pins_ref.stl";
module tint(c) { if (show_colors) color(c) children(); else children(); }

// --------------------------------------------------------------------
// BODY 0 — semantic parametric plan
//   fully parametric: expression octagons over exact plane dims; slot
//   walls as fitted arcs (res 0.036/0.005); exact bore. IoU 0.9987 vs
//   v1 0.9991 (parametric cost -0.0004)
// Anatomy (modules):
//   b0_hex_bar() — chamfered bar = intersection of three octagonal prisms whose...
//   b0_tendon_slot() — curved tendon slot between the two bspline walls — both walls are...
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b0 ---
b0_bar_hw       = 2.377583;  // exact wall planes #0/#31 (x = ±bar_hw)
b0_bar_z0       = 0.659863;  // exact bottom plane #24
b0_bar_z1       = 5.413925;  // exact top plane #15
b0_bar_y_end    = 16.559241;  // exact end planes #16/#23 (y = ±bar_y_end)
b0_cham_xz      = 0.278416;  // exact 45° long-edge chamfer width (cone of planes #13/#25/#14/#30; top height differs by 0.0014)
b0_cham_top_h   = 0.277311;  // exact top chamfer axial height (planes #14/#30)
b0_end_cham     = 0.44193;  // exact 45° end/corner chamfer width (planes #4/#7/#26/#28 + #17/#18/#20/#21; equal within 2e-3)
b0_slot_hw      = 1.455185;  // exact slot wall planes #9/#10 (x = ±slot_hw)
b0_slot_head_cy = -16.167652;  // fitted arc center of the head-side slot wall (15 raycast samples, res 0.036)
b0_slot_head_cz = 3.146764;  // same fit
b0_slot_head_r  = 3.012252;  // same fit
b0_slot_bar_cy  = -16.102972;  // fitted arc center of the bar-side slot wall (15 raycast samples, res 0.005)
b0_slot_bar_cz  = 3.156136;  // same fit
b0_slot_bar_r   = 5.980054;  // same fit
b0_bore_r       = 1.507237;  // exact bore cylinder face #2
b0_bore_y_cap   = -8.770356;  // exact blind-end cap plane #1
b0_bore_z       = 3.037447;  // exact bore axis height (face #2)
b0_pin_pitch    = 5.8765;  // exact centroid delta between adjacent pins
b0_fn           = 96;  // curve resolution

// chamfered bar = intersection of three octagonal prisms whose vertices are EXPRESSIONS over the exact plane dimensions (change bar_hw / cham_xz / end_cham and the whole bar follows)
module b0_hex_bar() {
    intersection() {
        // b0_xsec: XZ octagon: exact wall/top/bottom planes + 45° chamfers
        rotate([0, -90, -90]) translate([0, 0, -b0_bar_y_end]) linear_extrude((b0_bar_y_end) - (-b0_bar_y_end)) polygon([[b0_bar_z0, b0_bar_hw - b0_cham_xz], [b0_bar_z0 + b0_cham_xz, b0_bar_hw], [b0_bar_z1 - b0_cham_top_h, b0_bar_hw], [b0_bar_z1, b0_bar_hw - b0_cham_xz], [b0_bar_z1, -(b0_bar_hw - b0_cham_xz)], [b0_bar_z1 - b0_cham_top_h, -b0_bar_hw], [b0_bar_z0 + b0_cham_xz, -b0_bar_hw], [b0_bar_z0, -(b0_bar_hw - b0_cham_xz)]]);
        // b0_plan_xy: XY octagon: exact walls/ends + 45° corner chamfers
        translate([0, 0, b0_bar_z0 - 0.5]) linear_extrude((b0_bar_z1 + 0.5) - (b0_bar_z0 - 0.5)) polygon([[b0_bar_hw, b0_bar_y_end - b0_end_cham], [b0_bar_hw - b0_end_cham, b0_bar_y_end], [-(b0_bar_hw - b0_end_cham), b0_bar_y_end], [-b0_bar_hw, b0_bar_y_end - b0_end_cham], [-b0_bar_hw, -(b0_bar_y_end - b0_end_cham)], [-(b0_bar_hw - b0_end_cham), -b0_bar_y_end], [b0_bar_hw - b0_end_cham, -b0_bar_y_end], [b0_bar_hw, -(b0_bar_y_end - b0_end_cham)]]);
        // b0_side_yz: YZ octagon: exact ends/top/bottom + 45° end chamfers
        rotate([90, 0, 90]) translate([0, 0, -b0_bar_hw - 0.5]) linear_extrude((b0_bar_hw + 0.5) - (-b0_bar_hw - 0.5)) polygon([[b0_bar_y_end - b0_end_cham, b0_bar_z0], [b0_bar_y_end, b0_bar_z0 + b0_end_cham], [b0_bar_y_end, b0_bar_z1 - b0_end_cham], [b0_bar_y_end - b0_end_cham, b0_bar_z1], [-(b0_bar_y_end - b0_end_cham), b0_bar_z1], [-b0_bar_y_end, b0_bar_z1 - b0_end_cham], [-b0_bar_y_end, b0_bar_z0 + b0_end_cham], [-(b0_bar_y_end - b0_end_cham), b0_bar_z0]]);
    }
}

// curved tendon slot between the two bspline walls — both walls are circular ARCS (fit residuals in the params), near-concentric around the tendon bend center; cut spans the exact slot wall planes in x
module b0_tendon_slot() {
    // b0_slot_cut: slot profile: two fitted wall arcs swept between declared z overshoots 0.40/5.70
    rotate([90, 0, 90]) translate([0, 0, -b0_slot_hw]) linear_extrude((b0_slot_hw) - (-b0_slot_hw)) polygon(concat(
            [for (k = [1 : 16]) [(b0_slot_head_cy) + (b0_slot_head_r)*cos((-65.76421) + k*((57.95342) - (-65.76421))/16), (b0_slot_head_cz) + (b0_slot_head_r)*sin((-65.76421) + k*((57.95342) - (-65.76421))/16)]],
            [for (k = [1 : 16]) [(b0_slot_bar_cy) + (b0_slot_bar_r)*cos((25.175441) + k*((-27.444433) - (25.175441))/16), (b0_slot_bar_cz) + (b0_slot_bar_r)*sin((25.175441) + k*((-27.444433) - (25.175441))/16)]]));
}

module tpins_body_0() {
    difference() {
        b0_hex_bar();  // b0_bar_i
        b0_tendon_slot();  // b0_slot_i
        // b0_tendon_bore: blind tendon bore: exact cylinder face #2 + cap plane #1; +y end overshoots the exit by 1
        translate([0, b0_bore_y_cap, b0_bore_z]) rotate([-90, 0, 0]) cylinder(h=(b0_bar_y_end + 1) - (b0_bore_y_cap), r=b0_bore_r, $fn=b0_fn);
    }
}

// ---- body 1 (strategy: instance_of body 0 — agent plan) ----
b1_offset = [5.8765, 0, 0];  // exact centroid delta (= pin_pitch param)

module tpins_body_1() {
    translate(b1_offset) tpins_body_0();
}

// ---- body 2 (strategy: instance_of body 0 — agent plan) ----
b2_offset = [-5.8765, 0, 0];  // exact centroid delta (= -pin_pitch)

module tpins_body_2() {
    translate(b2_offset) tpins_body_0();
}


// ---- assembly helper: all three flat tensioner pins, centred on XY origin ----
module tensioner_pins_centered(){ tpins_body_0(); tpins_body_1(); tpins_body_2(); }
