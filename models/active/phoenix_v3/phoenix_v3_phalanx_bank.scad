// Phoenix Hand v3 - Exact Legacy Phalanx Bank

use <phoenix_v3_phalanx_legacy_geometry.scad>

/* [Scaling] */
hand_length_mm = 135; // [120:1:230]
use_anisotropic_scaling = false;

/* [Optional Anisotropic Controls] */
palm_breadth_mm = 80.85; // [55:1:110]
phalanx_bank_length_mm = 35.53; // [25:1:60]
phalanx_bank_thickness_mm = 17.19; // [10:1:30]

/* [Orientation] */
left_hand = true;

/* [Hidden] */
REF_HAND_LENGTH_MM = 135;
REF_X = Phoenix_Phalanx_Left_dimX();
REF_Y = Phoenix_Phalanx_Left_dimY();
REF_Z = Phoenix_Phalanx_Left_dimZ();

uniform_scale = hand_length_mm / REF_HAND_LENGTH_MM;
x_scale = use_anisotropic_scaling ? palm_breadth_mm / REF_X : uniform_scale;
y_scale = use_anisotropic_scaling ? phalanx_bank_length_mm / REF_Y : uniform_scale;
z_scale = use_anisotropic_scaling ? phalanx_bank_thickness_mm / REF_Z : uniform_scale;

module phoenix_v3_phalanx_bank_exact() {
    scale([x_scale, y_scale, z_scale]) {
        if (left_hand) {
            Phoenix_Phalanx_Left();
        } else {
            mirror([1, 0, 0]) Phoenix_Phalanx_Left();
        }
    }
}

phoenix_v3_phalanx_bank_exact();
