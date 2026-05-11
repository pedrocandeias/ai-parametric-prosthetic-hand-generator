// Phoenix Hand v3 - Exact Legacy Fingers

use <phoenix_v3_fingers_legacy_geometry.scad>

/* [Scaling] */
hand_length_mm = 135; // [120:1:230]
use_anisotropic_scaling = false;

/* [Optional Anisotropic Controls] */
finger_span_mm = 78.32; // [50:1:120]
finger_length_mm = 43.55; // [25:1:70]
finger_thickness_mm = 15.72; // [8:1:30]

/* [Orientation] */
left_hand = true;

/* [Hidden] */
REF_HAND_LENGTH_MM = 135;
REF_X = Phoenix_Fingers_Left_dimX();
REF_Y = Phoenix_Fingers_Left_dimY();
REF_Z = Phoenix_Fingers_Left_dimZ();

uniform_scale = hand_length_mm / REF_HAND_LENGTH_MM;
x_scale = use_anisotropic_scaling ? finger_span_mm / REF_X : uniform_scale;
y_scale = use_anisotropic_scaling ? finger_length_mm / REF_Y : uniform_scale;
z_scale = use_anisotropic_scaling ? finger_thickness_mm / REF_Z : uniform_scale;

module phoenix_v3_fingers_exact() {
    scale([x_scale, y_scale, z_scale]) {
        if (left_hand) {
            Phoenix_Fingers_Left();
        } else {
            mirror([1, 0, 0]) Phoenix_Fingers_Left();
        }
    }
}

phoenix_v3_fingers_exact();
