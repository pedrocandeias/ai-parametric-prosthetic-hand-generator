// Phoenix Hand v3 - Proximal Phalanx
// Parametric reconstruction from STEP geometry analysis + cross-section slicing
//
// Reference solid S22 (STEP): 12.40 x 35.52 x 16.16 mm  vol=2639.8 mm3
// S22/S23/S25/S26 identical (4 fingers); S24 thumb (16.36 x 35.52 x 17.19 mm)
//
// This file intentionally does more than apply a single outer scale():
// - finger_length_mm drives the longitudinal Y layout
// - palm_breadth_mm drives X girth
// - palm_thickness_mm drives Z dorsal-palmar thickness
// - hole diameters remain explicit hardware dimensions in millimetres

/* [Anthropometric] */
finger_length_mm = 35.52; // [25:1:55]
palm_breadth_mm = 82.17;  // [55:1:110]
palm_thickness_mm = 30.55; // [18:1:50]
phalanx_type = "finger"; // [finger, thumb]

/* [Hardware] */
mcp_pin_r = 2.30;
pip_pin_r = 2.38;
string_r = 3.00;
guide_r = 1.12;
snap_r = 1.60;

/* [Preview] */
show_reference_axes = false;

/* [Hidden] */
$fn = 64;

REF_PALM_BREADTH = 82.17;
REF_PALM_THICKNESS = 30.55;

REF_L = 35.52;
REF_W = 12.40;
REF_H = 16.16;

THUMB_W = 16.36;
THUMB_H = 17.19;

function _ref_w(kind) = kind == "thumb" ? THUMB_W : REF_W;
function _ref_h(kind) = kind == "thumb" ? THUMB_H : REF_H;

module _scaled_xz(x_scale, z_scale) {
    scale([x_scale, 1, z_scale]) children();
}

module _section_capsule(x_span, z_span, y_thickness) {
    hull() {
        translate([x_span * 0.28, 0, z_span * 0.5])
            scale([x_span * 0.24, y_thickness * 0.5, z_span * 0.34])
            sphere(1);
        translate([x_span * 0.72, 0, z_span * 0.5])
            scale([x_span * 0.24, y_thickness * 0.5, z_span * 0.34])
            sphere(1);
    }
}

module _shell_section(x_span, z_span, y_thickness, crown=1.0, belly=1.0) {
    hull() {
        translate([x_span * 0.18, 0, z_span * 0.16 * belly])
            scale([x_span * 0.18, y_thickness * 0.44, z_span * 0.16])
            sphere(1);
        translate([x_span * 0.82, 0, z_span * 0.16 * belly])
            scale([x_span * 0.18, y_thickness * 0.44, z_span * 0.16])
            sphere(1);
        translate([x_span * 0.10, 0, z_span * 0.50])
            scale([x_span * 0.10, y_thickness * 0.42, z_span * 0.20])
            sphere(1);
        translate([x_span * 0.90, 0, z_span * 0.50])
            scale([x_span * 0.10, y_thickness * 0.42, z_span * 0.20])
            sphere(1);
        translate([x_span * 0.50, 0, z_span * 0.94 * crown])
            scale([x_span * 0.24, y_thickness * 0.40, z_span * 0.12])
            sphere(1);
    }
}

module _rounded_block(size, rounding) {
    hull() {
        for (sx = [-1, 1], sy = [-1, 1], sz = [-1, 1])
            translate([
                sx * max(size[0] / 2 - rounding, 0),
                sy * max(size[1] / 2 - rounding, 0),
                sz * max(size[2] / 2 - rounding, 0)
            ])
                sphere(r=max(rounding, 0.01));
    }
}

module _x_cyl(h, r) {
    rotate([0, 90, 0]) cylinder(h=h, r=r, center=true);
}

module phoenix_proximal_phalanx(
    finger_length_mm_local = finger_length_mm,
    palm_breadth_mm_local = palm_breadth_mm,
    palm_thickness_mm_local = palm_thickness_mm,
    phalanx_type_local = phalanx_type
) {
    len_scale = finger_length_mm_local / REF_L;
    width_scale = palm_breadth_mm_local / REF_PALM_BREADTH;
    height_scale = palm_thickness_mm_local / REF_PALM_THICKNESS;

    ref_w = _ref_w(phalanx_type_local);
    ref_h = _ref_h(phalanx_type_local);

    bw = ref_w * width_scale;
    bh = ref_h * height_scale;

    mcp_y = 3.00 * len_scale;
    mcp_z = 6.00 * height_scale;
    mcp_r_outer = 6.00 * min(width_scale, height_scale);

    pip_y = 29.00 * len_scale;
    pip_z = 4.50 * height_scale;
    pip_r_outer = 4.50 * min(width_scale, height_scale);

    chan_y = 33.56 * len_scale;
    chan_z = 8.59 * height_scale;

    guide_y = 17.92 * len_scale;
    guide_z = 2.13 * height_scale;

    snap_z = 13.46 * height_scale;
    snap_y = 13.69 * len_scale;

    dorsal_mid_z = bh * 0.58;
    dorsal_top_z = bh * 0.72;
    dorsal_tail_z = bh * 0.60;
    cheek_inset = bw * 0.16;
    cheek_z = bh * 0.38;
    cheek_thickness_y = 5.2 * len_scale;
    cheek_crown_y = mcp_y + 1.8 * len_scale;
    cheek_crown_z = bh * 0.58;
    cheek_crown_x = bw * 0.17;
    guide_block_w = bw * 0.18;
    guide_block_h = bh * 0.14;
    guide_block_y = 3.8 * len_scale;
    rear_tab_y = 2.2 * len_scale;
    rear_tab_z = bh * 0.76;
    body_y0 = mcp_y + 4.0 * len_scale;
    body_y1 = guide_y - 1.0 * len_scale;
    body_y2 = pip_y - 2.4 * len_scale;
    shell_lift = bh * 0.12;
    fork_slot_w = bw * 0.22;
    fork_slot_y = 6.2 * len_scale;
    fork_slot_z = bh * 0.58;
    front_tab_y = mcp_y + 5.2 * len_scale;
    front_tab_z = bh * 0.68;
    front_tab_w = bw * 0.16;
    front_tab_len = 4.2 * len_scale;
    front_saddle_y = mcp_y + 6.8 * len_scale;
    front_saddle_z = bh * 0.57;
    front_saddle_w = bw * 0.44;
    front_saddle_len = 5.8 * len_scale;
    front_saddle_h = bh * 0.12;
    front_saddle_cut_y = mcp_y + 5.8 * len_scale;
    front_saddle_cut_z = bh * 0.70;
    front_saddle_cut_r = bh * 0.11;
    front_saddle_cut_len = front_saddle_w * 0.92;
    front_relief_w = bw * 0.22;
    front_relief_len = 4.4 * len_scale;
    front_relief_h = bh * 0.20;
    front_relief_y = front_saddle_y + 0.7 * len_scale;
    front_relief_z = bh * 0.76;
    front_relief_side_r = bw * 0.12;
    rear_tab_len = 2.3 * len_scale;
    side_scoop_z = bh * 0.56;
    side_scoop_y = guide_y + 1.2 * len_scale;
    side_scoop_len = 9.0 * len_scale;
    shoulder_y0 = body_y0 + 1.6 * len_scale;
    shoulder_y1 = guide_y + 0.8 * len_scale;
    shoulder_z0 = bh * 0.36;
    shoulder_z1 = bh * 0.48;
    spine_y = guide_y + 0.8 * len_scale;
    spine_z = bh * 0.69;
    fork_round_y = mcp_y + 2.8 * len_scale;
    fork_round_z = bh * 0.33;

    groove_w = 2.10 * width_scale;
    groove_depth = 6.20 * height_scale;
    groove_y0 = mcp_y + mcp_r_outer * 0.7;
    groove_y1 = pip_y - pip_r_outer * 0.7;

    difference() {
        union() {
            translate([bw / 2, mcp_y, mcp_z])
                _scaled_xz(width_scale * (ref_w / REF_W), height_scale)
                _x_cyl(h=REF_W, r=6.00);

            // MCP hinge cheeks: build them from rounded lobes so the fork
            // resembles the CAD reference more closely.
            hull() {
                translate([cheek_inset, mcp_y + cheek_thickness_y * 0.25, cheek_z])
                    scale([bw * 0.15, cheek_thickness_y * 0.55, bh * 0.32]) sphere(1);
                translate([cheek_inset, body_y0, cheek_z + shell_lift])
                    scale([bw * 0.12, cheek_thickness_y * 0.35, bh * 0.20]) sphere(1);
                translate([cheek_crown_x, cheek_crown_y, cheek_crown_z])
                    scale([bw * 0.11, cheek_thickness_y * 0.32, bh * 0.16]) sphere(1);
            }

            hull() {
                translate([bw - cheek_inset, mcp_y + cheek_thickness_y * 0.25, cheek_z])
                    scale([bw * 0.15, cheek_thickness_y * 0.55, bh * 0.32]) sphere(1);
                translate([bw - cheek_inset, body_y0, cheek_z + shell_lift])
                    scale([bw * 0.12, cheek_thickness_y * 0.35, bh * 0.20]) sphere(1);
                translate([bw - cheek_crown_x, cheek_crown_y, cheek_crown_z])
                    scale([bw * 0.11, cheek_thickness_y * 0.32, bh * 0.16]) sphere(1);
            }

            // Lateral shoulders keep the fork-to-body transition fuller,
            // closer to the measured STEP side profile.
            hull() {
                translate([bw * 0.12, shoulder_y0, shoulder_z0])
                    scale([bw * 0.10, 2.8 * len_scale, bh * 0.18]) sphere(1);
                translate([bw * 0.22, shoulder_y1, shoulder_z1])
                    scale([bw * 0.12, 4.6 * len_scale, bh * 0.22]) sphere(1);
            }

            hull() {
                translate([bw * 0.88, shoulder_y0, shoulder_z0])
                    scale([bw * 0.10, 2.8 * len_scale, bh * 0.18]) sphere(1);
                translate([bw * 0.78, shoulder_y1, shoulder_z1])
                    scale([bw * 0.12, 4.6 * len_scale, bh * 0.22]) sphere(1);
            }

            // Main body shell: keep the measured three-section profile idea,
            // but express it with native hulls so the file stays portable.
            hull() {
                translate([0, body_y0, shell_lift]) _shell_section(bw * 0.96, bh * 0.90, 1.8 * len_scale, crown=0.92, belly=1.08);
                translate([0, body_y1, 0]) _shell_section(bw * 0.90, bh * 0.98, 1.8 * len_scale, crown=1.00, belly=1.00);
            }

            hull() {
                translate([0, body_y1, 0]) _shell_section(bw * 0.90, bh * 0.98, 1.8 * len_scale, crown=1.00, belly=1.00);
                translate([0, body_y2, 0]) _shell_section(bw * 0.76, bh * 0.78, 1.5 * len_scale, crown=0.90, belly=0.96);
            }

            // A shallow dorsal ridge improves the cylindrical top shell
            // without introducing the blocky deck seen in earlier revisions.
            hull() {
                translate([bw / 2, body_y0 + 2.0 * len_scale, bh * 0.78])
                    _rounded_block([bw * 0.16, 2.6 * len_scale, bh * 0.10], rounding=bh * 0.03);
                translate([bw / 2, body_y1 + 0.8 * len_scale, bh * 0.82])
                    _rounded_block([bw * 0.12, 2.8 * len_scale, bh * 0.08], rounding=bh * 0.025);
            }

            // Blend body into both hinge cylinders.
            hull() {
                translate([0, body_y0, dorsal_mid_z]) _section_capsule(bw * 0.90, bh * 0.80, 1.1 * len_scale);
                translate([bw / 2, mcp_y + mcp_r_outer * 0.55, mcp_z + mcp_r_outer * 0.32])
                    _scaled_xz(width_scale * (ref_w / REF_W) * 0.92, height_scale)
                    _x_cyl(h=REF_W, r=6.00 * 0.72);
            }

            hull() {
                translate([0, body_y2, dorsal_tail_z]) _section_capsule(bw * 0.74, bh * 0.44, 1.0 * len_scale);
                translate([bw / 2, pip_y - pip_r_outer * 0.35, pip_z * 1.18])
                    _scaled_xz(width_scale * (ref_w / REF_W) * 0.88, height_scale)
                    _x_cyl(h=REF_W, r=4.50);
            }

            translate([bw / 2, pip_y, pip_z])
                _scaled_xz(width_scale * (ref_w / REF_W), height_scale)
                _x_cyl(h=REF_W, r=4.50);

            translate([bw / 2, chan_y, chan_z])
                _scaled_xz(width_scale * (ref_w / REF_W), height_scale)
                _x_cyl(h=REF_W, r=string_r * 1.6);

            // Front top deck: measured slices at y≈61 mm show a broad upper
            // saddle plus a narrower raised tab, not just a single block.
            hull() {
                translate([bw / 2, front_saddle_y, front_saddle_z])
                    _rounded_block([front_saddle_w, front_saddle_len, front_saddle_h], rounding=min(front_saddle_h * 0.42, front_saddle_w * 0.12));
                translate([bw / 2, front_saddle_y + 0.8 * len_scale, front_saddle_z - front_saddle_h * 0.14])
                    _rounded_block([front_saddle_w * 0.92, front_saddle_len * 0.55, front_saddle_h * 0.74], rounding=min(front_saddle_h * 0.28, front_saddle_w * 0.10));
            }

            // Raised center tab above the saddle.
            hull() {
                translate([bw / 2, front_tab_y, front_tab_z])
                    _rounded_block([front_tab_w, front_tab_len, guide_block_h * 0.72], rounding=min(guide_block_h * 0.20, front_tab_w * 0.12));
                translate([bw / 2, front_tab_y + 1.4 * len_scale, front_tab_z - guide_block_h * 0.14])
                    _rounded_block([front_tab_w * 0.82, front_tab_len * 0.48, guide_block_h * 0.56], rounding=min(guide_block_h * 0.18, front_tab_w * 0.10));
                translate([bw / 2, front_tab_y - 0.9 * len_scale, front_tab_z - guide_block_h * 0.28])
                    _rounded_block([front_tab_w * 0.92, front_tab_len * 0.34, guide_block_h * 0.42], rounding=min(guide_block_h * 0.16, front_tab_w * 0.10));
            }

            // Blend the front saddle into the shell so it reads as a molded
            // deck feature instead of a freestanding block.
            hull() {
                translate([bw / 2, front_saddle_y + front_saddle_len * 0.30, front_saddle_z - front_saddle_h * 0.10])
                    _rounded_block([front_saddle_w * 0.84, front_saddle_len * 0.40, front_saddle_h * 0.70], rounding=min(front_saddle_h * 0.25, front_saddle_w * 0.10));
                translate([0, body_y0 + 1.4 * len_scale, bh * 0.68])
                    _shell_section(bw * 0.76, bh * 0.30, 1.4 * len_scale, crown=0.92, belly=1.02);
            }

            // Rear guide post and tab near the distal cylinder.
            hull() {
                translate([bw / 2, guide_y - guide_block_y * 0.42, dorsal_top_z - guide_block_h * 0.28])
                    _rounded_block([guide_block_w, guide_block_y, guide_block_h], rounding=min(guide_block_h * 0.18, guide_block_w * 0.10));
                translate([bw / 2, pip_y - rear_tab_y, rear_tab_z])
                    _rounded_block([guide_block_w * 0.76, rear_tab_len, guide_block_h * 0.62], rounding=min(guide_block_h * 0.14, guide_block_w * 0.08));
            }
        }

        translate([bw / 2, (groove_y0 + groove_y1) / 2, -0.01])
            cube([groove_w, groove_y1 - groove_y0, groove_depth * 2 + 0.02], center=true);

        // Fork slot between the two MCP cheeks.
        translate([bw / 2, mcp_y + fork_slot_y * 0.38, fork_slot_z])
            cube([fork_slot_w, fork_slot_y, bh * 0.54], center=true);

        // Carve the measured front saddle relief so the tab sits within a
        // recessed deck instead of on a solid wedge.
        translate([bw / 2, front_relief_y, front_relief_z])
            _rounded_block(
                [front_relief_w, front_relief_len, front_relief_h],
                rounding=min(front_relief_h * 0.22, front_relief_w * 0.12)
            );

        // Cut the saddle curve visible in the STEP part so the front deck is
        // split into a lower platform and narrower raised tab.
        translate([bw / 2, front_saddle_cut_y, front_saddle_cut_z])
            rotate([0, 90, 0])
            cylinder(r=front_saddle_cut_r, h=front_saddle_cut_len, center=true);

        translate([bw * 0.26, front_relief_y + 0.2 * len_scale, front_relief_z - bh * 0.03])
            rotate([0, 18, 0])
            sphere(r=front_relief_side_r);

        translate([bw * 0.74, front_relief_y + 0.2 * len_scale, front_relief_z - bh * 0.03])
            rotate([0, -18, 0])
            sphere(r=front_relief_side_r);

        // Round the front fork opening so the leading edge looks less rectangular.
        translate([bw / 2, fork_round_y, fork_round_z])
            rotate([0, 90, 0])
            cylinder(r=bh * 0.14, h=fork_slot_w * 1.28, center=true);

        // Side scallops soften the body and remove the remaining wedge look.
        translate([bw * 0.16, side_scoop_y, side_scoop_z])
            rotate([0, 10, 0])
            scale([bw * 0.10, side_scoop_len, bh * 0.24])
            sphere(1);

        translate([bw * 0.84, side_scoop_y, side_scoop_z])
            rotate([0, -10, 0])
            scale([bw * 0.10, side_scoop_len, bh * 0.24])
            sphere(1);

        // Hardware bores are explicit dimensions and are not stretched by anatomy.
        translate([bw / 2, mcp_y, mcp_z])
            rotate([0, 90, 0])
            cylinder(r=mcp_pin_r, h=bw + 2, center=true);

        translate([bw / 2, pip_y, pip_z])
            rotate([0, 90, 0])
            cylinder(r=pip_pin_r, h=bw + 2, center=true);

        translate([bw / 2, chan_y, chan_z])
            rotate([0, 90, 0])
            cylinder(r=string_r, h=bw + 2, center=true);

        translate([bw / 2, guide_y, guide_z])
            rotate([90, 0, 0])
            cylinder(r=guide_r, h=bw + 2, center=true);

        translate([bw / 2, snap_y, snap_z])
            cylinder(r=snap_r, h=bh + 2, center=true);
    }
}

module _reference_axes(size = 50) {
    color("red") cube([size, 0.6, 0.6], center=false);
    color("green") cube([0.6, size, 0.6], center=false);
    color("blue") cube([0.6, 0.6, size], center=false);
}

if (show_reference_axes) {
    _reference_axes();
}

phoenix_proximal_phalanx();
