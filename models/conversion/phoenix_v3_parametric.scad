/*
  Phoenix Hand v3 — Parametric Native OpenSCAD Wrapper

  Source references:
    - STEP assembly: e_nable_phoenix_hand_v3.step
    - Native OpenSCAD geometry: unlimbed_phoenix_hand/UnLimbitedPhoenix.scad

  This file keeps the model fully OpenSCAD-native and avoids STL imports.
  It wraps the existing Phoenix polyhedron modules in a cleaner parameter
  interface with calibrated anthropometric scaling.

  Important limitation:
    The legacy Phoenix source was authored around a single print-scale knob.
    Safe scaling for the palm is therefore uniform. Independent finger scaling
    is exposed as an opt-in because it can break fit with the palm and pins.
*/

use <unlimbed_phoenix_hand/UnLimbitedPhoenix.scad>

/* [Anthropometric] */
// Knuckle-to-knuckle palm breadth. This is the primary active scale driver.
palm_breadth_mm = 82.17; // [55:1:110]
// Wrist base to middle MCP crease. Stored for downstream alignment; palm stays uniformly scaled.
palm_length_mm = 91.96; // [60:1:140]
// Palmar-to-dorsal palm thickness. Stored for downstream alignment; palm stays uniformly scaled.
palm_thickness_mm = 30.55; // [18:1:50]
// Middle finger MCP crease to fingertip. Can optionally drive finger-only scale.
middle_finger_length_mm = 79.08; // [45:1:110]
// Thumb MCP crease to tip. Stored only; the legacy Phoenix source does not separate thumb scaling cleanly.
thumb_length_mm = 70; // [35:1:100]

/* [Handedness] */
mirrored = false;

/* [Scaling] */
// Keep this off unless you explicitly want finger parts resized independently.
use_independent_finger_scale = false;

/* [Visibility] */
show_palm = true;
show_fingers = true;
show_phalanges = true;
show_pins = true;
show_tension_box = true;
show_tension_pins = true;
show_gauntlet = true;
show_jig = false;

/* [Layout] */
show_print_layout = true;
layout_spacing_mm = 16;

/* [Hidden] */
$fn = 64;

// Reference spans extracted from the native Phoenix OpenSCAD source.
REF_PALM_BREADTH = 82.17;
REF_PALM_LENGTH = 91.96;
REF_PALM_THICKNESS = 30.55;
REF_FINGERS_LENGTH = 43.55;
REF_PHALANX_LENGTH = 35.53;
REF_FULL_FINGER_LENGTH = REF_FINGERS_LENGTH + REF_PHALANX_LENGTH;
REF_GAUNTLET_WIDTH = 95.05;

hand_scale = palm_breadth_mm / REF_PALM_BREADTH;
finger_scale = use_independent_finger_scale
    ? (middle_finger_length_mm / REF_FULL_FINGER_LENGTH)
    : hand_scale;
gauntlet_scale = hand_scale;

palm_span_x = 82.17 * hand_scale;
fingers_span_x = 78.32 * finger_scale;
phalanx_span_x = 80.85 * finger_scale;
pins_span_x = 65.19 * finger_scale;
box_span_x = 23.62 * hand_scale;
tension_pins_span_x = 22.61 * hand_scale;
gauntlet_span_x = 95.05 * gauntlet_scale;
jig_span_x = 82.17 * hand_scale;

module orient_for_hand() {
    if (mirrored) {
        mirror([1, 0, 0]) children();
    } else {
        children();
    }
}

module phoenix_palm() {
    orient_for_hand()
        scale([hand_scale, hand_scale, hand_scale])
        Phoenix_Thermo_Palm_2();
}

module phoenix_fingers() {
    orient_for_hand()
        scale([finger_scale, finger_scale, finger_scale])
        Phoenix_Fingers_Left();
}

module phoenix_phalanges() {
    orient_for_hand()
        scale([finger_scale, finger_scale, finger_scale])
        Phoenix_Phalanx_Left();
}

module phoenix_pins_module() {
    orient_for_hand()
        scale([finger_scale, finger_scale, finger_scale])
        Phoenix_Pins();
}

module phoenix_tension_box() {
    orient_for_hand()
        scale([hand_scale, hand_scale, hand_scale])
        3Pin_Tensioner_Box();
}

module phoenix_tension_pins_module() {
    orient_for_hand()
        scale([hand_scale, hand_scale, hand_scale])
        3Tensionpins();
}

module phoenix_gauntlet() {
    orient_for_hand()
        rotate([90, 0, 0])
        scale([gauntlet_scale, gauntlet_scale, gauntlet_scale])
        Gauntlet_V4();
}

module phoenix_jig() {
    orient_for_hand()
        rotate([90, 0, 0])
        scale([hand_scale, hand_scale, hand_scale])
        Jig();
}

module phoenix_v3_print_layout() {
    x0 = 0;
    x1 = x0 + palm_span_x + layout_spacing_mm;
    x2 = x1 + fingers_span_x + layout_spacing_mm;
    x3 = x2 + phalanx_span_x + layout_spacing_mm;
    x4 = x3 + pins_span_x + layout_spacing_mm;
    x5 = x4 + box_span_x + layout_spacing_mm;
    x6 = x5 + tension_pins_span_x + layout_spacing_mm;

    if (show_palm) translate([x0, 0, 0]) phoenix_palm();
    if (show_fingers) translate([x1, 0, 0]) phoenix_fingers();
    if (show_phalanges) translate([x2, 0, 0]) phoenix_phalanges();
    if (show_pins) translate([x3, 0, 0]) phoenix_pins_module();
    if (show_tension_box) translate([x4, 0, 0]) phoenix_tension_box();
    if (show_tension_pins) translate([x5, 0, 0]) phoenix_tension_pins_module();
    if (show_gauntlet) translate([x6, 0, 0]) phoenix_gauntlet();
    if (show_jig) translate([x0, -140 * hand_scale, 0]) phoenix_jig();
}

module phoenix_v3_single_origin() {
    if (show_palm) phoenix_palm();
    if (show_fingers) phoenix_fingers();
    if (show_phalanges) phoenix_phalanges();
    if (show_pins) phoenix_pins_module();
    if (show_tension_box) phoenix_tension_box();
    if (show_tension_pins) phoenix_tension_pins_module();
    if (show_gauntlet) phoenix_gauntlet();
    if (show_jig) phoenix_jig();
}

if (show_print_layout) {
    phoenix_v3_print_layout();
} else {
    phoenix_v3_single_origin();
}
