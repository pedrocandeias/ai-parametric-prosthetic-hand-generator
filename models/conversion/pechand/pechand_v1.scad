// PECHand v1 — Parametric prosthetic hand model
// Generated: 2025-01-15
// Description: Modular hand assembly with configurable palm and digits

/* [Anthropometric] */
palm_width_mm = 82;          // [50:1:120]
palm_length_mm = 92;         // [50:1:140]
palm_thickness_mm = 18;      // [10:1:40]
index_finger_length_mm = 68; // [40:1:120]
middle_finger_length_mm = 74; // [40:1:130]
ring_finger_length_mm = 70;  // [40:1:120]
pinky_finger_length_mm = 58; // [30:1:100]
thumb_length_mm = 62;        // [30:1:100]

/* [Layout] */
show_palm = true;
show_index = true;
show_middle = true;
show_ring = true;
show_pinky = true;
show_thumb = true;
show_assembled = true;
mirrored = false;

/* [Style] */
finger_shape = "box"; // ["box","cylinder"]
segment_gap_mm = 2.5; // [0:0.5:8]
finger_thickness_mm = 14; // [6:1:24]
thumb_thickness_mm = 16;  // [6:1:24]

/* [Colors] */
color_palm   = "#d9b382";
color_index  = "#4a9eff";
color_middle = "#ff6b6b";
color_ring   = "#51cf66";
color_pinky  = "#ffd43b";
color_thumb  = "#f783ac";

$fn = $preview ? 32 : 64;

finger_segment_ratios = [0.43, 0.32, 0.25];
thumb_segment_ratios  = [0.58, 0.42];

function _segment_offset(i, usable_length, segment_ratios, gap) =
    i <= 0 ? 0 :
    _segment_offset(i - 1, usable_length, segment_ratios, gap) +
    usable_length * segment_ratios[i - 1] + gap;

module palm_placeholder() {
    translate([-palm_width_mm / 2, -palm_length_mm / 2, 0])
        cube([palm_width_mm, palm_length_mm, palm_thickness_mm]);
}

module segment_shape(length, width, thickness) {
    if (finger_shape == "cylinder")
        rotate([0, 90, 0])
            cylinder(h=length, r=min(width, thickness) / 2, center=false);
    else
        cube([length, width, thickness]);
}

module segment_chain(total_length, widths, thickness, segment_ratios, gap=segment_gap_mm) {
    _n = len(segment_ratios);
    _gap_total = gap * (_n - 1);
    _usable_length = max(1, total_length - _gap_total);

    for (i = [0:_n - 1]) {
        _seg_len = _usable_length * segment_ratios[i];
        _x = _segment_offset(i, _usable_length, segment_ratios, gap);
        translate([_x, -widths[i] / 2, 0]) segment_shape(_seg_len, widths[i], thickness);
    }
}

module finger_placeholder(total_length, base_width=18, thickness=finger_thickness_mm) {
    _widths = [base_width, base_width * 0.86, base_width * 0.72];
    segment_chain(total_length, _widths, thickness, finger_segment_ratios);
}

module thumb_placeholder(total_length, base_width=20, thickness=thumb_thickness_mm) {
    _widths = [base_width, base_width * 0.8];
    segment_chain(total_length, _widths, thickness, thumb_segment_ratios);
}

module hand_layout() {
    _dir = mirrored ? -1 : 1;
    _base_y = palm_length_mm / 2 - 14;
    _x_index  =  28 * _dir;
    _x_middle =  10 * _dir;
    _x_ring   =  -8 * _dir;
    _x_pinky  = -24 * _dir;

    if (show_palm) color(color_palm) palm_placeholder();

    if (show_index) color(color_index)
        translate([_x_index, _base_y, palm_thickness_mm * 0.75])
            rotate([0, 0, 90]) finger_placeholder(index_finger_length_mm, base_width=18);

    if (show_middle) color(color_middle)
        translate([_x_middle, _base_y, palm_thickness_mm * 0.75])
            rotate([0, 0, 90]) finger_placeholder(middle_finger_length_mm, base_width=19);

    if (show_ring) color(color_ring)
        translate([_x_ring, _base_y, palm_thickness_mm * 0.75])
            rotate([0, 0, 90]) finger_placeholder(ring_finger_length_mm, base_width=18);

    if (show_pinky) color(color_pinky)
        translate([_x_pinky, _base_y - 2, palm_thickness_mm * 0.75])
            rotate([0, 0, 90]) finger_placeholder(pinky_finger_length_mm, base_width=15, thickness=12);

    if (show_thumb) color(color_thumb)
        translate([(palm_width_mm / 2 - 6) * _dir, -8, palm_thickness_mm * 0.7])
            rotate([0, 0, mirrored ? 140 : 40]) thumb_placeholder(thumb_length_mm, base_width=20);
}

module print_layout() {
    if (show_palm) color(color_palm)
        translate([-90, 0, 0]) palm_placeholder();

    if (show_index) color(color_index)
        translate([0, 34, 0]) finger_placeholder(index_finger_length_mm, base_width=18);

    if (show_middle) color(color_middle)
        translate([0, 10, 0]) finger_placeholder(middle_finger_length_mm, base_width=19);

    if (show_ring) color(color_ring)
        translate([0, -14, 0]) finger_placeholder(ring_finger_length_mm, base_width=18);

    if (show_pinky) color(color_pinky)
        translate([0, -36, 0]) finger_placeholder(pinky_finger_length_mm, base_width=15, thickness=12);

    if (show_thumb) color(color_thumb)
        translate([0, -66, 0]) thumb_placeholder(thumb_length_mm, base_width=20);
}

if (show_assembled)
    hand_layout();
else
    print_layout();
