// ====================================================================
// Snap_Pins — step2scad parametric reconstruction
// source: models/phoenix_components/Snap_Pins.step
// Every dimension is measured from the STEP B-rep (exact faces) or a
// fitted law with its residual cited — see the source comment on each
// parameter. Edit named parameters; geometry follows.
// ====================================================================

// --- Display options ---
show_colors   = false;   // tint top-level features (preview aid) — off so the assembly can recolour the pins
show_original = false;   // ghost the original tessellation overlay
original_stl  = "Snap_Pins_ref.stl";
module tint(c) { if (show_colors) color(c) children(); else children(); }

// --------------------------------------------------------------------
// BODY 0 — semantic parametric plan
//   semantic parametric pin: measured station circles segmented into
//   named plateau cylinders (exact faces where they agree) +
//   transition frustums; head stations and cutters vectorized;
//   engraved digit labels excluded by design — hull-loft along y from
//   measured sections; plan-view concavity cutters (fork slot/barb
//   notches); engraved label grooves (
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b0 ---
b0_axis_x   = 27.792511;  // pin axis position (median of measured station centers, std < 0.001)
b0_axis_z   = 2.430429;  // pin axis height (median of measured station centers)
b0_tip_r    = 2.609331;  // plateau of 1 measured station circles (r spread < 0.012)
b0_tip_s0   = -16.535;  // measured plateau start along the pin axis
b0_tip_s1   = -16.535;  // measured plateau end along the pin axis
b0_seg1_r   = 2.79763;  // plateau of 1 measured station circles (r spread < 0.012)
b0_seg1_s0  = -16.345;  // measured plateau start along the pin axis
b0_seg1_s1  = -16.345;  // measured plateau end along the pin axis
b0_barb_r   = 3;  // EXACT cylinder face #16 (r=3.0)
b0_barb_s0  = -15.945;  // measured plateau start along the pin axis
b0_barb_s1  = -15.545;  // measured plateau end along the pin axis
b0_shaft_r  = 2.5;  // EXACT cylinder face #14 (r=2.5)
b0_shaft_s0 = -15.145;  // measured plateau start along the pin axis
b0_shaft_s1 = -5.145;  // measured plateau end along the pin axis
b0_flat_z0  = 0.530304;  // EXACT plane face (bottom flat) — pin sections are circles clipped by z flats
b0_flat_z1  = 4.9305;  // EXACT plane face (top flat)
b0_fn       = 96;  // curve resolution

module body_0() {
    difference() {
        intersection() {
            union() {
                // b0_tip_blend: measured transition between adjacent station plateaus (frustum)
                translate([b0_axis_x, b0_tip_s1, b0_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b0_seg1_s0) - (b0_tip_s1), r1=b0_tip_r, r2=b0_seg1_r, $fn=b0_fn);
                // b0_seg1_blend: measured transition between adjacent station plateaus (frustum)
                translate([b0_axis_x, b0_seg1_s1, b0_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b0_barb_s0) - (b0_seg1_s1), r1=b0_seg1_r, r2=b0_barb_r, $fn=b0_fn);
                // b0_barb: EXACT cylinder face #16 (r=3.0)
                translate([b0_axis_x, b0_barb_s0, b0_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b0_barb_s1) - (b0_barb_s0), r=b0_barb_r, $fn=b0_fn);
                // b0_barb_blend: measured transition between adjacent station plateaus (frustum)
                translate([b0_axis_x, b0_barb_s1, b0_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b0_shaft_s0) - (b0_barb_s1), r1=b0_barb_r, r2=b0_shaft_r, $fn=b0_fn);
                // b0_shaft: EXACT cylinder face #14 (r=2.5)
                translate([b0_axis_x, b0_shaft_s0, b0_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b0_shaft_s1) - (b0_shaft_s0), r=b0_shaft_r, $fn=b0_fn);
                // b0_head_plate_0: head plate: constant axis-aligned rectangular section 4.40 x 6.75 over 6 measured stations (identical within 0.05; control-slice interp err <= 0.05) — measured section convex hull at y=-4.745 (high-res tessellation)
                translate([24.41751, -4.745, 0.5303]) cube([6.75, 1.86, 4.4002]);
                hull() {
                    // b0_head_0bridge: head station (vectorized: 4 lines + 0 arcs) — measured section convex hull at y=-4.745 (high-res tessellation)
                    rotate([0, -90, -90]) translate([0, 0, -4.745]) linear_extrude(0.02) polygon(concat(
            [[4.9305, 24.41751]],
            [[4.9305, 31.16751]],
            [[0.5303, 31.16751]],
            [[0.5303, 24.41751]]));
                    // b0_shaft_bridge0_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b0_axis_x, b0_shaft_s1, b0_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b0_shaft_s1 + 0.02) - (b0_shaft_s1), r=b0_shaft_r, $fn=b0_fn);
                }
            }
            // b0_flat_slab: z-slab between the EXACT plane flats (vertex circle-fits cannot see flats: all vertices lie on the circle)
            translate([15.792511, -28.535, b0_flat_z0]) cube([24, 35.39, b0_flat_z1 - b0_flat_z0]);
        }
        // b0_pocket0: vectorized cutter (5 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.730402): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(5.400196) polygon(concat(
            [[25.327997, -15.344508]],
            [[24.823364, -15.359508]],
            [[24.808624, -16.109506]],
            [[24.40252, -4.845029]],
            [[25.327997, -4.844508]]));
        // b0_pocket1: vectorized cutter (6 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.730402): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(5.400196) polygon(concat(
            [[31.182479, -4.843524]],
            [[30.791649, -16.095029]],
            [[30.761658, -16.094508]],
            [[30.761658, -15.359508]],
            [[30.257024, -15.344508]],
            [[30.272024, -4.829508]]));
        // b0_pocket2: vectorized cutter (8 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.730402): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(5.400196) polygon(concat(
            [[27.027511, -16.579508]],
            [[27.027799, -9.591582]],
            [[28.548251, -9.58065]],
            [[28.557511, -16.579508]],
            [[30.272024, -16.579508]],
            [[30.285883, -16.600248]],
            [[25.358402, -16.609508]],
            [[25.358402, -16.579508]]));
    }
}

// --------------------------------------------------------------------
// BODY 1 — semantic parametric plan
//   semantic parametric pin: measured station circles segmented into
//   named plateau cylinders (exact faces where they agree) +
//   transition frustums; head stations and cutters vectorized;
//   engraved digit labels excluded by design — hull-loft along x from
//   measured sections; plan-view concavity cutters (fork slot/barb
//   notches); engraved label grooves (
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b1 ---
b1_axis_y    = 5.650405;  // pin axis position (median of measured station centers, std < 0.001)
b1_axis_z    = 2.033255;  // pin axis height (median of measured station centers)
b1_shaft_r   = 2;  // EXACT cylinder face #32 (r=2.0)
b1_shaft_s0  = -7.612;  // measured plateau start along the pin axis
b1_shaft_s1  = -0.012;  // measured plateau end along the pin axis
b1_seg1_r    = 2.280821;  // plateau of 1 measured station circles (r spread < 0.012)
b1_seg1_s0   = 0.388;  // measured plateau start along the pin axis
b1_seg1_s1   = 0.388;  // measured plateau end along the pin axis
b1_barb_r    = 2.362499;  // plateau of 2 measured station circles (r spread < 0.012)
b1_barb_s0   = 0.788;  // measured plateau start along the pin axis
b1_barb_s1   = 1.188;  // measured plateau end along the pin axis
b1_seg3_r    = 2.352554;  // plateau of 1 measured station circles (r spread < 0.012)
b1_seg3_s0   = 1.588;  // measured plateau start along the pin axis
b1_seg3_s1   = 1.588;  // measured plateau end along the pin axis
b1_collar_r  = 2.264702;  // plateau of 1 measured station circles (r spread < 0.012)
b1_collar_s0 = 1.748;  // measured plateau start along the pin axis
b1_collar_s1 = 1.748;  // measured plateau end along the pin axis
b1_flat_z0   = 0.530304;  // EXACT plane face (bottom flat) — pin sections are circles clipped by z flats
b1_flat_z1   = 3.733424;  // EXACT plane face (top flat)
b1_fn        = 96;  // curve resolution

module body_1() {
    difference() {
        intersection() {
            union() {
                // b1_shaft: EXACT cylinder face #32 (r=2.0)
                translate([b1_shaft_s0, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_shaft_s1) - (b1_shaft_s0), r=b1_shaft_r, $fn=b1_fn);
                // b1_shaft_blend: measured transition between adjacent station plateaus (frustum)
                translate([b1_shaft_s1, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_seg1_s0) - (b1_shaft_s1), r1=b1_shaft_r, r2=b1_seg1_r, $fn=b1_fn);
                // b1_seg1_blend: measured transition between adjacent station plateaus (frustum)
                translate([b1_seg1_s1, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_barb_s0) - (b1_seg1_s1), r1=b1_seg1_r, r2=b1_barb_r, $fn=b1_fn);
                // b1_barb: plateau of 2 measured station circles (r spread < 0.012)
                translate([b1_barb_s0, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_barb_s1) - (b1_barb_s0), r=b1_barb_r, $fn=b1_fn);
                // b1_barb_blend: measured transition between adjacent station plateaus (frustum)
                translate([b1_barb_s1, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_seg3_s0) - (b1_barb_s1), r1=b1_barb_r, r2=b1_seg3_r, $fn=b1_fn);
                // b1_seg3_blend: measured transition between adjacent station plateaus (frustum)
                translate([b1_seg3_s1, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_collar_s0) - (b1_seg3_s1), r1=b1_seg3_r, r2=b1_collar_r, $fn=b1_fn);
                hull() {
                    // b1_head_0a: head station (vectorized: 5 lines + 2 arcs) — measured section convex hull at x=-8.602 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.602]) linear_extrude(0.02) polygon(concat(
            [[7.74646, 0.5303]],
            [for (k = [1 : 11]) [(5.891298) + (2.407027)*cos((-39.414752) + k*((22.367858) - (-39.414752))/11), (2.054947) + (2.407027)*sin((-39.414752) + k*((22.367858) - (-39.414752))/11)]],
            [[7.81376, 3.48193]],
            [[7.27118, 3.72613]],
            [[3.91132, 3.70437]],
            [for (k = [1 : 16]) [(4.887723) + (1.961842)*cos((120.191663) + k*((211.697594) - (120.191663))/16), (2.026179) + (1.961842)*sin((120.191663) + k*((211.697594) - (120.191663))/16)]],
            [[3.55482, 0.5303]]));
                    // b1_head_2b: head station (vectorized: 9 lines + 0 arcs) — measured section convex hull at x=-8.012 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.012]) linear_extrude(0.02) polygon(concat(
            [[8.14385, 1.21712]],
            [[8.07186, 3.11869]],
            [[7.35688, 3.71043]],
            [[3.68592, 3.61888]],
            [[3.26518, 3.19815]],
            [[3.15064, 2.73342]],
            [[3.27663, 0.85061]],
            [[3.55482, 0.5303]],
            [[7.77134, 0.55111]]));
                }
                hull() {
                    // b1_head_-1bridge: head station (vectorized: 9 lines + 0 arcs) — measured section convex hull at x=-8.012 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.012]) linear_extrude(0.02) polygon(concat(
            [[8.14385, 1.21712]],
            [[8.07186, 3.11869]],
            [[7.35688, 3.71043]],
            [[3.68592, 3.61888]],
            [[3.26518, 3.19815]],
            [[3.15064, 2.73342]],
            [[3.27663, 0.85061]],
            [[3.55482, 0.5303]],
            [[7.77134, 0.55111]]));
                    // b1_shaft_bridge-1_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b1_shaft_s0, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_shaft_s0 + 0.02) - (b1_shaft_s0), r=b1_shaft_r, $fn=b1_fn);
                }
                hull() {
                    // b1_head_0bridge: head station (vectorized: 5 lines + 2 arcs) — measured section convex hull at x=-8.602 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.602]) linear_extrude(0.02) polygon(concat(
            [[7.74646, 0.5303]],
            [for (k = [1 : 11]) [(5.891298) + (2.407027)*cos((-39.414752) + k*((22.367858) - (-39.414752))/11), (2.054947) + (2.407027)*sin((-39.414752) + k*((22.367858) - (-39.414752))/11)]],
            [[7.81376, 3.48193]],
            [[7.27118, 3.72613]],
            [[3.91132, 3.70437]],
            [for (k = [1 : 16]) [(4.887723) + (1.961842)*cos((120.191663) + k*((211.697594) - (120.191663))/16), (2.026179) + (1.961842)*sin((120.191663) + k*((211.697594) - (120.191663))/16)]],
            [[3.55482, 0.5303]]));
                    // b1_shaft_bridge0_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b1_shaft_s0, b1_axis_y, b1_axis_z]) rotate([0, 90, 0]) cylinder(h=(b1_shaft_s0 + 0.02) - (b1_shaft_s0), r=b1_shaft_r, $fn=b1_fn);
                }
            }
            // b1_flat_slab: z-slab between the EXACT plane flats (vertex circle-fits cannot see flats: all vertices lie on the circle)
            translate([-19.612, -6.349595, b1_flat_z0]) cube([33.36, 24, b1_flat_z1 - b1_flat_z0]);
        }
        // b1_pocket0: vectorized cutter (4 lines + 1 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.131864): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.20312) polygon(concat(
            [[1.458226, 8.070119]],
            [[1.459535, 8.040192]],
            [for (k = [1 : 20]) [(0.998506) + (0.711042)*cos((49.738286) + k*((169.020944) - (49.738286))/20), (7.495828) + (0.711042)*sin((49.738286) + k*((169.020944) - (49.738286))/20)]],
            [[-7.70693, 7.645461]],
            [[-7.693254, 8.16558]]));
        // b1_pocket1: vectorized cutter (8 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.131864): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.20312) polygon(concat(
            [[1.79307, 5.135639]],
            [[-3.694856, 5.135927]],
            [[-3.705788, 6.156379]],
            [[1.79307, 6.165639]],
            [[1.79307, 7.70532]],
            [[1.81381, 7.719178]],
            [[1.82307, 3.595957]],
            [[1.79307, 3.595957]]));
        // b1_pocket2: vectorized cutter (3 lines + 1 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.131864): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.20312) polygon(concat(
            [[0.308066, 3.671503]],
            [for (k = [1 : 20]) [(1.018833) + (0.732592)*cos((-169.339918) + k*((-49.52955) - (-169.339918))/20), (3.805291) + (0.732592)*sin((-169.339918) + k*((-49.52955) - (-169.339918))/20)]],
            [[-7.691774, 3.13564]],
            [[-7.691925, 3.670817]]));
    }
}

// ---- body 2 (strategy: instance_of body 1 — agent plan) ----
b2_offset = [0, -14.032569, -0.000063];  // centroid delta body2-body1; canonical-anchor face signature matches except the engraved digit (<2.2 mm² faces)

module body_2() {
    translate(b2_offset) body_1();
}

// ---- body 3 (strategy: instance_of body 0 — agent plan) ----
b3_offset = [0.000014, 18.428702, 0.000238];  // centroid delta body3-body0; canonical-anchor face signature matches except the engraved digit (<2.2 mm² faces)

module body_3() {
    translate(b3_offset) body_0();
}

// ---- body 4 (strategy: instance_of body 1 — agent plan) ----
b4_offset = [0, -6.932079, -0.00012];  // centroid delta body4-body1; canonical-anchor face signature matches except the engraved digit (<2.2 mm² faces)

module body_4() {
    translate(b4_offset) body_1();
}

// --------------------------------------------------------------------
// BODY 5 — semantic parametric plan
//   semantic parametric pin: measured station circles segmented into
//   named plateau cylinders (exact faces where they agree) +
//   transition frustums; head stations and cutters vectorized;
//   engraved digit labels excluded by design — hull-loft along x from
//   measured sections; plan-view concavity cutters (fork slot/barb
//   notches); engraved label grooves (
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b5 ---
b5_axis_y    = 16.106303;  // pin axis position (median of measured station centers, std < 0.001)
b5_axis_z    = 2.230303;  // pin axis height (median of measured station centers)
b5_shaft_r   = 2;  // EXACT cylinder face #31 (r=2.0)
b5_shaft_s0  = -6.941;  // measured plateau start along the pin axis
b5_shaft_s1  = 0.659;  // measured plateau end along the pin axis
b5_barb_r    = 2.356681;  // plateau of 7 measured station circles (r spread < 0.012)
b5_barb_s0   = 1.059;  // measured plateau start along the pin axis
b5_barb_s1   = 3.459;  // measured plateau end along the pin axis
b5_collar_r  = 2.282705;  // plateau of 1 measured station circles (r spread < 0.012)
b5_collar_s0 = 3.639;  // measured plateau start along the pin axis
b5_collar_s1 = 3.639;  // measured plateau end along the pin axis
b5_flat_z0   = 0.530304;  // EXACT plane face (bottom flat) — pin sections are circles clipped by z flats
b5_flat_z1   = 3.930304;  // EXACT plane face (top flat)
b5_fn        = 96;  // curve resolution

module body_5() {
    difference() {
        intersection() {
            union() {
                // b5_shaft: EXACT cylinder face #31 (r=2.0)
                translate([b5_shaft_s0, b5_axis_y, b5_axis_z]) rotate([0, 90, 0]) cylinder(h=(b5_shaft_s1) - (b5_shaft_s0), r=b5_shaft_r, $fn=b5_fn);
                // b5_shaft_blend: measured transition between adjacent station plateaus (frustum)
                translate([b5_shaft_s1, b5_axis_y, b5_axis_z]) rotate([0, 90, 0]) cylinder(h=(b5_barb_s0) - (b5_shaft_s1), r1=b5_shaft_r, r2=b5_barb_r, $fn=b5_fn);
                // b5_barb: plateau of 7 measured station circles (r spread < 0.012)
                translate([b5_barb_s0, b5_axis_y, b5_axis_z]) rotate([0, 90, 0]) cylinder(h=(b5_barb_s1) - (b5_barb_s0), r=b5_barb_r, $fn=b5_fn);
                // b5_barb_blend: measured transition between adjacent station plateaus (frustum)
                translate([b5_barb_s1, b5_axis_y, b5_axis_z]) rotate([0, 90, 0]) cylinder(h=(b5_collar_s0) - (b5_barb_s1), r1=b5_barb_r, r2=b5_collar_r, $fn=b5_fn);
                // b5_head_plate_0: head plate: constant axis-aligned rectangular section 5.00 x 3.40 over 7 measured stations (identical within 0.05; control-slice interp err <= 0.05) — measured section convex hull at x=-9.531 (high-res tessellation)
                translate([-9.531, 13.6063, 0.5303]) cube([2.21, 5, 3.4]);
                hull() {
                    // b5_head_-1bridge: head station (vectorized: 4 lines + 0 arcs) — measured section convex hull at x=-7.341 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -7.341]) linear_extrude(0.02) polygon(concat(
            [[18.6063, 0.5303]],
            [[18.6063, 3.9303]],
            [[13.6063, 3.9303]],
            [[13.6063, 0.5303]]));
                    // b5_shaft_bridge-1_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b5_shaft_s0, b5_axis_y, b5_axis_z]) rotate([0, 90, 0]) cylinder(h=(b5_shaft_s0 + 0.02) - (b5_shaft_s0), r=b5_shaft_r, $fn=b5_fn);
                }
            }
            // b5_flat_slab: z-slab between the EXACT plane flats (vertex circle-fits cannot see flats: all vertices lie on the circle)
            translate([-18.941, 4.106303, b5_flat_z0]) cube([34.58, 24, b5_flat_z1 - b5_flat_z0]);
        }
        // b5_pocket0: vectorized cutter (5 lines + 1 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.230304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.4) polygon(concat(
            [[3.398642, 18.50092]],
            [[1.065662, 18.498981]],
            [for (k = [1 : 16]) [(1.136757) + (0.343869)*cos((102.019355) + k*((192.306087) - (102.019355))/16), (18.16506) + (0.343869)*sin((102.019355) + k*((192.306087) - (102.019355))/16)]],
            [[-7.216358, 18.102733]],
            [[-7.20123, 18.621303]],
            [[3.39877, 18.53092]]));
        // b5_pocket1: vectorized cutter (5 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.230304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.4) polygon(concat(
            [[-3.232828, 15.591375]],
            [[-3.246285, 16.607773]],
            [[3.683642, 16.621303]],
            [[3.700113, 18.230848]],
            [[3.713642, 15.606303]]));
        // b5_pocket2: vectorized cutter (4 lines + 1 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.230304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.4) polygon(concat(
            [[0.798649, 14.121303]],
            [for (k = [1 : 16]) [(1.136755) + (0.343867)*cos((167.693738) + k*((257.980915) - (167.693738))/16), (14.047545) + (0.343867)*sin((167.693738) + k*((257.980915) - (167.693738))/16)]],
            [[3.413642, 13.69675]],
            [[-7.20123, 13.591304]],
            [[-7.201351, 14.124874]]));
    }
}

// --------------------------------------------------------------------
// BODY 6 — semantic parametric plan
//   semantic parametric pin: measured station circles segmented into
//   named plateau cylinders (exact faces where they agree) +
//   transition frustums; head stations and cutters vectorized;
//   engraved digit labels excluded by design — hull-loft along y from
//   measured sections; plan-view concavity cutters (fork slot/barb
//   notches); engraved label grooves (
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b6 ---
b6_axis_x   = -26.854375;  // pin axis position (median of measured station centers, std < 0.001)
b6_axis_z   = 2.180301;  // pin axis height (median of measured station centers)
b6_tip_r    = 2.009169;  // plateau of 1 measured station circles (r spread < 0.012)
b6_tip_s0   = -19.147;  // measured plateau start along the pin axis
b6_tip_s1   = -19.147;  // measured plateau end along the pin axis
b6_seg1_r   = 2.198753;  // plateau of 1 measured station circles (r spread < 0.012)
b6_seg1_s0  = -18.957;  // measured plateau start along the pin axis
b6_seg1_s1  = -18.957;  // measured plateau end along the pin axis
b6_barb_r   = 2.4;  // EXACT cylinder face #39 (r=2.4)
b6_barb_s0  = -18.557;  // measured plateau start along the pin axis
b6_barb_s1  = -18.157;  // measured plateau end along the pin axis
b6_shaft_r  = 1.9;  // EXACT cylinder face #50 (r=1.9)
b6_shaft_s0 = -17.757;  // measured plateau start along the pin axis
b6_shaft_s1 = -8.957;  // measured plateau end along the pin axis
b6_flat_z0  = 0.530304;  // EXACT plane face (bottom flat) — pin sections are circles clipped by z flats
b6_flat_z1  = 3.830304;  // EXACT plane face (top flat)
b6_fn       = 96;  // curve resolution

module body_6() {
    difference() {
        intersection() {
            union() {
                // b6_tip_blend: measured transition between adjacent station plateaus (frustum)
                translate([b6_axis_x, b6_tip_s1, b6_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b6_seg1_s0) - (b6_tip_s1), r1=b6_tip_r, r2=b6_seg1_r, $fn=b6_fn);
                // b6_seg1_blend: measured transition between adjacent station plateaus (frustum)
                translate([b6_axis_x, b6_seg1_s1, b6_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b6_barb_s0) - (b6_seg1_s1), r1=b6_seg1_r, r2=b6_barb_r, $fn=b6_fn);
                // b6_barb: EXACT cylinder face #39 (r=2.4)
                translate([b6_axis_x, b6_barb_s0, b6_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b6_barb_s1) - (b6_barb_s0), r=b6_barb_r, $fn=b6_fn);
                // b6_barb_blend: measured transition between adjacent station plateaus (frustum)
                translate([b6_axis_x, b6_barb_s1, b6_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b6_shaft_s0) - (b6_barb_s1), r1=b6_barb_r, r2=b6_shaft_r, $fn=b6_fn);
                // b6_shaft: EXACT cylinder face #50 (r=1.9)
                translate([b6_axis_x, b6_shaft_s0, b6_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b6_shaft_s1) - (b6_shaft_s0), r=b6_shaft_r, $fn=b6_fn);
                // b6_head_plate_0: head plate: constant axis-aligned rectangular section 3.30 x 5.50 over 7 measured stations (identical within 0.05; control-slice interp err <= 0.05) — measured section convex hull at y=-8.557 (high-res tessellation)
                translate([-29.60438, -8.557, 0.5303]) cube([5.5, 2.31, 3.3]);
                hull() {
                    // b6_head_0bridge: head station (vectorized: 4 lines + 0 arcs) — measured section convex hull at y=-8.557 (high-res tessellation)
                    rotate([0, -90, -90]) translate([0, 0, -8.557]) linear_extrude(0.02) polygon(concat(
            [[3.8303, -29.60438]],
            [[3.8303, -24.10438]],
            [[0.5303, -24.10438]],
            [[0.5303, -29.60438]]));
                    // b6_shaft_bridge0_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b6_axis_x, b6_shaft_s1, b6_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b6_shaft_s1 + 0.02) - (b6_shaft_s1), r=b6_shaft_r, $fn=b6_fn);
                }
            }
            // b6_flat_slab: z-slab between the EXACT plane flats (vertex circle-fits cannot see flats: all vertices lie on the circle)
            translate([-38.854375, -31.147, b6_flat_z0]) cube([24, 34.19, b6_flat_z1 - b6_flat_z0]);
        }
        // b6_pocket0: vectorized cutter (5 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-28.735812, -18.008093]],
            [[-29.239377, -18.021623]],
            [[-29.254115, -18.721621]],
            [[-29.619368, -8.707148]],
            [[-28.73574, -8.706623]]));
        // b6_pocket1: vectorized cutter (6 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-24.089409, -8.705643]],
            [[-24.439386, -18.707148]],
            [[-24.469377, -18.706623]],
            [[-24.469377, -18.021623]],
            [[-24.972942, -18.008093]],
            [[-24.959484, -8.691695]]));
        // b6_pocket2: vectorized cutter (4 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-26.352907, -11.291695]],
            [[-26.339449, -19.208093]],
            [[-27.354377, -19.221623]],
            [[-27.369305, -11.305153]]));
    }
}

// --------------------------------------------------------------------
// BODY 7 — semantic parametric plan
//   VERIFIED y-mirror of body 1 about y=-4.7474 (every axis dim equal
//   within 0.003) — kept own params: the plan schema has no cross-body
//   module refs; semantic parametric pin: measured station circles
//   segmented into named plateau cylinders (exact faces where they
//   agree) + transition frustums; head stations and cutters
//   vectorized; engraved digit labels excluded by design — hull-loft
//   along x from measured sections; plan-view concavity cutters (fork
//   slot/barb notches); engraved label grooves (
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b7 ---
b7_axis_y    = -15.145295;  // pin axis position (median of measured station centers, std < 0.001)
b7_axis_z    = 2.03325;  // pin axis height (median of measured station centers)
b7_shaft_r   = 2;  // EXACT cylinder face #32 (r=2.0)
b7_shaft_s0  = -7.612;  // measured plateau start along the pin axis
b7_shaft_s1  = -0.012;  // measured plateau end along the pin axis
b7_seg1_r    = 2.278204;  // plateau of 1 measured station circles (r spread < 0.012)
b7_seg1_s0   = 0.388;  // measured plateau start along the pin axis
b7_seg1_s1   = 0.388;  // measured plateau end along the pin axis
b7_barb_r    = 2.364425;  // plateau of 2 measured station circles (r spread < 0.012)
b7_barb_s0   = 0.788;  // measured plateau start along the pin axis
b7_barb_s1   = 1.188;  // measured plateau end along the pin axis
b7_seg3_r    = 2.350162;  // plateau of 1 measured station circles (r spread < 0.012)
b7_seg3_s0   = 1.588;  // measured plateau start along the pin axis
b7_seg3_s1   = 1.588;  // measured plateau end along the pin axis
b7_collar_r  = 2.263066;  // plateau of 1 measured station circles (r spread < 0.012)
b7_collar_s0 = 1.748;  // measured plateau start along the pin axis
b7_collar_s1 = 1.748;  // measured plateau end along the pin axis
b7_flat_z0   = 0.530304;  // EXACT plane face (bottom flat) — pin sections are circles clipped by z flats
b7_flat_z1   = 3.733424;  // EXACT plane face (top flat)
b7_fn        = 96;  // curve resolution

module body_7() {
    difference() {
        intersection() {
            union() {
                // b7_shaft: EXACT cylinder face #32 (r=2.0)
                translate([b7_shaft_s0, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_shaft_s1) - (b7_shaft_s0), r=b7_shaft_r, $fn=b7_fn);
                // b7_shaft_blend: measured transition between adjacent station plateaus (frustum)
                translate([b7_shaft_s1, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_seg1_s0) - (b7_shaft_s1), r1=b7_shaft_r, r2=b7_seg1_r, $fn=b7_fn);
                // b7_seg1_blend: measured transition between adjacent station plateaus (frustum)
                translate([b7_seg1_s1, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_barb_s0) - (b7_seg1_s1), r1=b7_seg1_r, r2=b7_barb_r, $fn=b7_fn);
                // b7_barb: plateau of 2 measured station circles (r spread < 0.012)
                translate([b7_barb_s0, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_barb_s1) - (b7_barb_s0), r=b7_barb_r, $fn=b7_fn);
                // b7_barb_blend: measured transition between adjacent station plateaus (frustum)
                translate([b7_barb_s1, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_seg3_s0) - (b7_barb_s1), r1=b7_barb_r, r2=b7_seg3_r, $fn=b7_fn);
                // b7_seg3_blend: measured transition between adjacent station plateaus (frustum)
                translate([b7_seg3_s1, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_collar_s0) - (b7_seg3_s1), r1=b7_seg3_r, r2=b7_collar_r, $fn=b7_fn);
                hull() {
                    // b7_head_0a: head station (vectorized: 5 lines + 2 arcs) — measured section convex hull at x=-8.602 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.602]) linear_extrude(0.02) polygon(concat(
            [[-13.04924, 0.5303]],
            [[-12.70557, 0.99081]],
            [[-12.64505, 1.33342]],
            [for (k = [1 : 19]) [(-13.987189) + (1.590721)*cos((-32.782874) + k*((77.439525) - (-32.782874))/19), (2.197802) + (1.590721)*sin((-32.782874) + k*((77.439525) - (-32.782874))/19)]],
            [[-16.88437, 3.70437]],
            [for (k = [1 : 16]) [(-15.919478) + (1.953642)*cos((119.926444) + k*((211.923499) - (119.926444))/16), (2.028162) + (1.953642)*sin((119.926444) + k*((211.923499) - (119.926444))/16)]],
            [[-17.24087, 0.5303]]));
                    // b7_head_2b: head station (vectorized: 10 lines + 0 arcs) — measured section convex hull at x=-8.012 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.012]) linear_extrude(0.02) polygon(concat(
            [[-12.70557, 0.99081]],
            [[-12.64505, 1.33342]],
            [[-12.72383, 3.11869]],
            [[-13.43881, 3.71043]],
            [[-16.99966, 3.66844]],
            [[-17.46804, 3.30149]],
            [[-17.64505, 2.73342]],
            [[-17.52207, 0.8558]],
            [[-17.24087, 0.5303]],
            [[-13.01514, 0.55882]]));
                }
                hull() {
                    // b7_head_-1bridge: head station (vectorized: 10 lines + 0 arcs) — measured section convex hull at x=-8.012 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.012]) linear_extrude(0.02) polygon(concat(
            [[-12.70557, 0.99081]],
            [[-12.64505, 1.33342]],
            [[-12.72383, 3.11869]],
            [[-13.43881, 3.71043]],
            [[-16.99966, 3.66844]],
            [[-17.46804, 3.30149]],
            [[-17.64505, 2.73342]],
            [[-17.52207, 0.8558]],
            [[-17.24087, 0.5303]],
            [[-13.01514, 0.55882]]));
                    // b7_shaft_bridge-1_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b7_shaft_s0, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_shaft_s0 + 0.02) - (b7_shaft_s0), r=b7_shaft_r, $fn=b7_fn);
                }
                hull() {
                    // b7_head_0bridge: head station (vectorized: 5 lines + 2 arcs) — measured section convex hull at x=-8.602 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -8.602]) linear_extrude(0.02) polygon(concat(
            [[-13.04924, 0.5303]],
            [[-12.70557, 0.99081]],
            [[-12.64505, 1.33342]],
            [for (k = [1 : 19]) [(-13.987189) + (1.590721)*cos((-32.782874) + k*((77.439525) - (-32.782874))/19), (2.197802) + (1.590721)*sin((-32.782874) + k*((77.439525) - (-32.782874))/19)]],
            [[-16.88437, 3.70437]],
            [for (k = [1 : 16]) [(-15.919478) + (1.953642)*cos((119.926444) + k*((211.923499) - (119.926444))/16), (2.028162) + (1.953642)*sin((119.926444) + k*((211.923499) - (119.926444))/16)]],
            [[-17.24087, 0.5303]]));
                    // b7_shaft_bridge0_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b7_shaft_s0, b7_axis_y, b7_axis_z]) rotate([0, 90, 0]) cylinder(h=(b7_shaft_s0 + 0.02) - (b7_shaft_s0), r=b7_shaft_r, $fn=b7_fn);
                }
            }
            // b7_flat_slab: z-slab between the EXACT plane flats (vertex circle-fits cannot see flats: all vertices lie on the circle)
            translate([-19.612, -27.145295, b7_flat_z0]) cube([33.36, 24, b7_flat_z1 - b7_flat_z0]);
        }
        // b7_pocket0: vectorized cutter (4 lines + 1 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.131864): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.20312) polygon(concat(
            [[1.458226, -12.725572]],
            [[1.459535, -12.755499]],
            [for (k = [1 : 20]) [(0.998506) + (0.711043)*cos((49.738363) + k*((169.020862) - (49.738363))/20), (-13.299864) + (0.711043)*sin((49.738363) + k*((169.020862) - (49.738363))/20)]],
            [[-7.70693, -13.15023]],
            [[-7.693254, -12.630111]]));
        // b7_pocket1: vectorized cutter (8 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.131864): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.20312) polygon(concat(
            [[1.79307, -15.660052]],
            [[-3.694856, -15.659764]],
            [[-3.705788, -14.639312]],
            [[1.79307, -14.630052]],
            [[1.79307, -13.090371]],
            [[1.81381, -13.076513]],
            [[1.82307, -17.199734]],
            [[1.79307, -17.199734]]));
        // b7_pocket2: vectorized cutter (3 lines + 1 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.131864): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.20312) polygon(concat(
            [[0.308066, -17.124188]],
            [for (k = [1 : 20]) [(1.018833) + (0.732592)*cos((-169.339918) + k*((-49.52955) - (-169.339918))/20), (-16.9904) + (0.732592)*sin((-169.339918) + k*((-49.52955) - (-169.339918))/20)]],
            [[-7.691774, -17.660051]],
            [[-7.691925, -17.124874]]));
    }
}

// ---- body 8 (strategy: instance_of body 6 — agent plan) ----
b8_offset = [0.000013, 15.21636, -0.000248];  // centroid delta body8-body6; canonical-anchor face signature matches except the engraved digit (<2.2 mm² faces)

module body_8() {
    translate(b8_offset) body_6();
}

// ---- body 9 (strategy: rotate_extrude — exact RZ profile) ----
// revolution axis: through [14.425505, -9.144297, 0.530304] along [0, 0, 1]; profile z measured from the axis low end
// Pappus check: profile revolves to 528.51 mm³ vs exact B-rep volume 531.63 mm³
b9_bore_r        = 2.7;  // exact B-rep: cylinder face(s) #2 radius (reversed -> bore)
b9_cbore_r       = 4.7;  // exact B-rep: cylinder face(s) #0 radius (reversed -> bore)
b9_total_h       = 3.75;  // exact B-rep: axial extent of the coaxial faces #0/#2/#3/#6/#7 (v-ranges)
b9_z_step1       = 2;  // exact B-rep: plane face(s) #1 height above the base
b9_cham1         = 0.5;  // exact B-rep: cone face(s) #7 (45° half-angle) radial width = axial height (45°)
b9_bore_bot_cham = 0.5;  // exact B-rep: cone face(s) #3 (45° half-angle) radial width = axial height (45°)
b9_fn            = 128;  // rotate_extrude curve resolution

module body_9() {
    // closed RZ boundary loop: up the bore, across the top,
    // down the outside, across the bottom (ring -> through-bore)
    translate([14.425505, -9.144297, 0.530304]) rotate_extrude($fn = b9_fn)
        polygon(points = [
            [b9_bore_r + b9_bore_bot_cham, 0],     // cone face(s) #3
            [b9_bore_r, b9_bore_bot_cham],         // cone face(s) #3
            [b9_bore_r, b9_z_step1],               // cyl face(s) #2
            [b9_cbore_r, b9_z_step1],              // cyl face(s) #0
            [b9_cbore_r, b9_total_h],              // cyl face(s) #0
            [b9_cbore_r + b9_cham1, b9_total_h],   // arc face(s) #6
            [5.907046, 3.667087],                  // arc face(s) #6
            [6.575728, 3.422848],                  // arc face(s) #6
            [7.169764, 3.030533],                  // arc face(s) #6
            [7.656921, 2.511432],                  // arc face(s) #6
            [8.010766, 1.893709],                  // arc face(s) #6
            [8.212101, 1.210881],                  // arc face(s) #6
            [8.25, b9_cham1],                      // cone face(s) #7
            [7.75, 0]                              // cone face(s) #7
        ]);
}

// --------------------------------------------------------------------
// BODY 10 — semantic parametric plan
//   semantic parametric pin: measured station circles segmented into
//   named plateau cylinders (exact faces where they agree) +
//   transition frustums; head stations and cutters vectorized;
//   engraved digit labels excluded by design — hull-loft along x from
//   measured sections; plan-view concavity cutters (fork slot/barb
//   notches); engraved label grooves (
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b10 ---
b10_axis_y   = 16.456581;  // pin axis position (median of measured station centers, std < 0.001)
b10_axis_z   = 2.180302;  // pin axis height (median of measured station centers)
b10_tip_r    = 2.008027;  // plateau of 1 measured station circles (r spread < 0.012)
b10_tip_s0   = -31.108;  // measured plateau start along the pin axis
b10_tip_s1   = -31.108;  // measured plateau end along the pin axis
b10_seg1_r   = 2.199248;  // plateau of 1 measured station circles (r spread < 0.012)
b10_seg1_s0  = -30.918;  // measured plateau start along the pin axis
b10_seg1_s1  = -30.918;  // measured plateau end along the pin axis
b10_barb_r   = 2.5;  // EXACT cylinder face #20 (r=2.5)
b10_barb_s0  = -30.518;  // measured plateau start along the pin axis
b10_barb_s1  = -29.318;  // measured plateau end along the pin axis
b10_shaft_r  = 2.1;  // EXACT cylinder face #24 (r=2.1)
b10_shaft_s0 = -28.918;  // measured plateau start along the pin axis
b10_shaft_s1 = -17.718;  // measured plateau end along the pin axis
b10_flat_z0  = 0.530304;  // EXACT plane face (bottom flat) — pin sections are circles clipped by z flats
b10_flat_z1  = 3.830304;  // EXACT plane face (top flat)
b10_fn       = 96;  // curve resolution

module body_10() {
    difference() {
        intersection() {
            union() {
                // b10_tip_blend: measured transition between adjacent station plateaus (frustum)
                translate([b10_tip_s1, b10_axis_y, b10_axis_z]) rotate([0, 90, 0]) cylinder(h=(b10_seg1_s0) - (b10_tip_s1), r1=b10_tip_r, r2=b10_seg1_r, $fn=b10_fn);
                // b10_seg1_blend: measured transition between adjacent station plateaus (frustum)
                translate([b10_seg1_s1, b10_axis_y, b10_axis_z]) rotate([0, 90, 0]) cylinder(h=(b10_barb_s0) - (b10_seg1_s1), r1=b10_seg1_r, r2=b10_barb_r, $fn=b10_fn);
                // b10_barb: EXACT cylinder face #20 (r=2.5)
                translate([b10_barb_s0, b10_axis_y, b10_axis_z]) rotate([0, 90, 0]) cylinder(h=(b10_barb_s1) - (b10_barb_s0), r=b10_barb_r, $fn=b10_fn);
                // b10_barb_blend: measured transition between adjacent station plateaus (frustum)
                translate([b10_barb_s1, b10_axis_y, b10_axis_z]) rotate([0, 90, 0]) cylinder(h=(b10_shaft_s0) - (b10_barb_s1), r1=b10_barb_r, r2=b10_shaft_r, $fn=b10_fn);
                // b10_shaft: EXACT cylinder face #24 (r=2.1)
                translate([b10_shaft_s0, b10_axis_y, b10_axis_z]) rotate([0, 90, 0]) cylinder(h=(b10_shaft_s1) - (b10_shaft_s0), r=b10_shaft_r, $fn=b10_fn);
                // b10_head_plate_0: head plate: constant axis-aligned rectangular section 5.50 x 3.30 over 7 measured stations (identical within 0.05; control-slice interp err <= 0.05) — measured section convex hull at x=-17.318 (high-res tessellation)
                translate([-17.318, 13.70662, 0.5303]) cube([2.11, 5.5, 3.3]);
                hull() {
                    // b10_head_0bridge: head station (vectorized: 4 lines + 0 arcs) — measured section convex hull at x=-17.318 (high-res tessellation)
                    rotate([90, 0, 90]) translate([0, 0, -17.318]) linear_extrude(0.02) polygon(concat(
            [[19.20662, 0.5303]],
            [[19.20662, 3.8303]],
            [[13.70662, 3.8303]],
            [[13.70662, 0.5303]]));
                    // b10_shaft_bridge0_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b10_shaft_s1, b10_axis_y, b10_axis_z]) rotate([0, 90, 0]) cylinder(h=(b10_shaft_s1 + 0.02) - (b10_shaft_s1), r=b10_shaft_r, $fn=b10_fn);
                }
            }
            // b10_flat_slab: z-slab between the EXACT plane flats (vertex circle-fits cannot see flats: all vertices lie on the circle)
            translate([-43.108, 4.456581, b10_flat_z0]) cube([37.39, 24, b10_flat_z1 - b10_flat_z0]);
        }
        // b10_pocket0: vectorized cutter (6 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-30.567806, 13.945468]],
            [[-30.567511, 13.975465]],
            [[-29.182511, 13.975465]],
            [[-29.167511, 14.375434]],
            [[-17.652511, 14.360434]],
            [[-17.666316, 13.691671]]));
        // b10_pocket1: vectorized cutter (8 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-31.152511, 17.271623]],
            [[-24.161771, 17.270481]],
            [[-24.153653, 15.650883]],
            [[-31.152511, 15.641623]],
            [[-31.152511, 14.56026]],
            [[-31.173251, 14.546402]],
            [[-31.182511, 18.280101]],
            [[-31.152511, 18.280101]]));
        // b10_pocket2: vectorized cutter (5 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-29.167511, 18.537812]],
            [[-29.182511, 18.937781]],
            [[-30.58251, 18.952633]],
            [[-17.667806, 19.22162]],
            [[-17.667511, 18.537812]]));
    }
}

// ---- body 11 (strategy: rotate_extrude — exact RZ profile) ----
// revolution axis: through [14.425505, 8.269981, 0.530304] along [0, 0, 1]; profile z measured from the axis low end
// Pappus check: profile revolves to 528.51 mm³ vs exact B-rep volume 531.63 mm³
b11_bore_r        = 2.7;  // exact B-rep: cylinder face(s) #2 radius (reversed -> bore)
b11_cbore_r       = 4.7;  // exact B-rep: cylinder face(s) #0 radius (reversed -> bore)
b11_total_h       = 3.75;  // exact B-rep: axial extent of the coaxial faces #0/#2/#3/#6/#7 (v-ranges)
b11_z_step1       = 2;  // exact B-rep: plane face(s) #1 height above the base
b11_cham1         = 0.5;  // exact B-rep: cone face(s) #7 (45° half-angle) radial width = axial height (45°)
b11_bore_bot_cham = 0.5;  // exact B-rep: cone face(s) #3 (45° half-angle) radial width = axial height (45°)
b11_fn            = 128;  // rotate_extrude curve resolution

module body_11() {
    // closed RZ boundary loop: up the bore, across the top,
    // down the outside, across the bottom (ring -> through-bore)
    translate([14.425505, 8.269981, 0.530304]) rotate_extrude($fn = b11_fn)
        polygon(points = [
            [b11_bore_r + b11_bore_bot_cham, 0],      // cone face(s) #3
            [b11_bore_r, b11_bore_bot_cham],          // cone face(s) #3
            [b11_bore_r, b11_z_step1],                // cyl face(s) #2
            [b11_cbore_r, b11_z_step1],               // cyl face(s) #0
            [b11_cbore_r, b11_total_h],               // cyl face(s) #0
            [b11_cbore_r + b11_cham1, b11_total_h],   // arc face(s) #6
            [5.907046, 3.667087],                     // arc face(s) #6
            [6.575728, 3.422848],                     // arc face(s) #6
            [7.169764, 3.030533],                     // arc face(s) #6
            [7.656921, 2.511432],                     // arc face(s) #6
            [8.010766, 1.893709],                     // arc face(s) #6
            [8.212101, 1.210881],                     // arc face(s) #6
            [8.25, b11_cham1],                        // cone face(s) #7
            [7.75, 0]                                 // cone face(s) #7
        ]);
}

// --------------------------------------------------------------------
// BODY 12 — semantic parametric plan
//   semantic parametric pin: measured station circles segmented into
//   named plateau cylinders (exact faces where they agree) +
//   transition frustums; head stations and cutters vectorized;
//   engraved digit labels excluded by design — hull-loft along y from
//   measured sections; plan-view concavity cutters (fork slot/barb
//   notches); engraved label grooves (
// --------------------------------------------------------------------

// ======== PARAMETERS (every value measured; sources cited) ========
// --- b12 ---
b12_axis_x   = -18.540155;  // pin axis position (median of measured station centers, std < 0.001)
b12_axis_z   = 2.180301;  // pin axis height (median of measured station centers)
b12_tip_r    = 2.00915;  // plateau of 1 measured station circles (r spread < 0.012)
b12_tip_s0   = -18.854;  // measured plateau start along the pin axis
b12_tip_s1   = -18.854;  // measured plateau end along the pin axis
b12_seg1_r   = 2.198994;  // plateau of 1 measured station circles (r spread < 0.012)
b12_seg1_s0  = -18.664;  // measured plateau start along the pin axis
b12_seg1_s1  = -18.664;  // measured plateau end along the pin axis
b12_barb_r   = 2.4;  // EXACT cylinder face #29 (r=2.4)
b12_barb_s0  = -18.264;  // measured plateau start along the pin axis
b12_barb_s1  = -17.864;  // measured plateau end along the pin axis
b12_shaft_r  = 1.9;  // EXACT cylinder face #24 (r=1.9)
b12_shaft_s0 = -17.464;  // measured plateau start along the pin axis
b12_shaft_s1 = 5.336;  // measured plateau end along the pin axis
b12_flat_z0  = 0.530304;  // EXACT plane face (bottom flat) — pin sections are circles clipped by z flats
b12_flat_z1  = 3.830304;  // EXACT plane face (top flat)
b12_fn       = 96;  // curve resolution

module body_12() {
    difference() {
        intersection() {
            union() {
                // b12_tip_blend: measured transition between adjacent station plateaus (frustum)
                translate([b12_axis_x, b12_tip_s1, b12_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b12_seg1_s0) - (b12_tip_s1), r1=b12_tip_r, r2=b12_seg1_r, $fn=b12_fn);
                // b12_seg1_blend: measured transition between adjacent station plateaus (frustum)
                translate([b12_axis_x, b12_seg1_s1, b12_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b12_barb_s0) - (b12_seg1_s1), r1=b12_seg1_r, r2=b12_barb_r, $fn=b12_fn);
                // b12_barb: EXACT cylinder face #29 (r=2.4)
                translate([b12_axis_x, b12_barb_s0, b12_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b12_barb_s1) - (b12_barb_s0), r=b12_barb_r, $fn=b12_fn);
                // b12_barb_blend: measured transition between adjacent station plateaus (frustum)
                translate([b12_axis_x, b12_barb_s1, b12_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b12_shaft_s0) - (b12_barb_s1), r1=b12_barb_r, r2=b12_shaft_r, $fn=b12_fn);
                // b12_shaft: EXACT cylinder face #24 (r=1.9)
                translate([b12_axis_x, b12_shaft_s0, b12_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b12_shaft_s1) - (b12_shaft_s0), r=b12_shaft_r, $fn=b12_fn);
                // b12_head_plate_0: head plate: constant axis-aligned rectangular section 3.30 x 5.50 over 7 measured stations (identical within 0.05; control-slice interp err <= 0.05) — measured section convex hull at y=5.736 (high-res tessellation)
                translate([-21.29016, 5.736, 0.5303]) cube([5.5, 2.31, 3.3]);
                hull() {
                    // b12_head_0bridge: head station (vectorized: 4 lines + 0 arcs) — measured section convex hull at y=5.736 (high-res tessellation)
                    rotate([0, -90, -90]) translate([0, 0, 5.736]) linear_extrude(0.02) polygon(concat(
            [[3.8303, -21.29016]],
            [[3.8303, -15.79016]],
            [[0.5303, -15.79016]],
            [[0.5303, -21.29016]]));
                    // b12_shaft_bridge0_disc: thin disc at the plateau boundary (bridges head block to the chain)
                    translate([b12_axis_x, b12_shaft_s1, b12_axis_z]) rotate([-90, 0, 0]) cylinder(h=(b12_shaft_s1 + 0.02) - (b12_shaft_s1), r=b12_shaft_r, $fn=b12_fn);
                }
            }
            // b12_flat_slab: z-slab between the EXACT plane flats (vertex circle-fits cannot see flats: all vertices lie on the circle)
            translate([-30.540155, -30.854, b12_flat_z0]) cube([24, 48.19, b12_flat_z1 - b12_flat_z0]);
        }
        // b12_pocket0: vectorized cutter (5 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-20.421519, -17.713607]],
            [[-20.925155, -17.728607]],
            [[-20.940046, -18.428607]],
            [[-21.305154, 5.586174]],
            [[-20.421519, 5.586393]]));
        // b12_pocket1: vectorized cutter (6 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-16.125157, -18.413826]],
            [[-16.155155, -18.413607]],
            [[-16.155155, -17.728607]],
            [[-16.658792, -17.713607]],
            [[-16.643792, 5.601393]],
            [[-15.775157, 5.586174]]));
        // b12_pocket2: vectorized cutter (4 lines + 0 arcs; capsule fit rejected, res 0.23-0.41) — plan-view concavity (silhouette hull minus measured outline at z=2.180304): fork slot / barb notch, vertical walls
        translate([0, 0, 0.030304]) linear_extrude(4.3) polygon(concat(
            [[-17.982229, -11.698895]],
            [[-17.970444, -18.916533]],
            [[-19.095155, -18.928607]],
            [[-19.109867, -11.710681]]));
    }
}

// full part = union of all bodies
body_0();
body_1();
body_2();
body_3();
body_4();
body_5();
body_6();
body_7();
body_8();
body_9();
body_10();
body_11();
body_12();
if (show_original) %import(original_stl);

// ====================================================================
// Assembly helpers — a SINGLE pin, recentred to the origin with its axis
// along +Z and the head at +Z. These live here (not in the assembly) so the
// b0_*/b1_* measured parameters stay in scope. `use <phoenix_snap_pins.scad>`
// imports these modules while ignoring the plate draw-calls above.
// ====================================================================
module finger_pin_centered(){    // body_1 — finger/thumb pin (axis along X, head at -X)
    rotate([0,90,0]) translate([-(b1_shaft_s0+b1_shaft_s1)/2, -b1_axis_y, -b1_axis_z]) body_1();
}
module wrist_pin_centered(){     // body_0 — larger wrist pin (axis along Y, head at +Y)
    rotate([90,0,0]) translate([-b0_axis_x, -(b0_shaft_s0+b0_shaft_s1)/2, -b0_axis_z]) body_0();
}
// countersunk wrist-pin washer (body_9), recentred: bore on +Z axis, cup base at z=0
module washer_centered(){
    translate([-14.425505, 9.144297, -0.530304]) body_9();
}
