// Phoenix Hand v3 - Exact Legacy Palm

use <phoenix_v3_palm_legacy_geometry.scad>

/* [Scaling] */
hand_length_mm = 135; // [120:1:230]
use_anisotropic_scaling = false;

/* [Optional Anisotropic Controls] */
palm_breadth_mm = 82.17; // [55:1:120]
palm_length_mm = 91.96; // [60:1:130]
palm_thickness_mm = 30.55; // [15:1:50]

/* [Orientation] */
left_hand = true;

/* [Hidden] */
REF_HAND_LENGTH_MM = 135;
REF_X = Phoenix_Thermo_Palm_2_dimX();
REF_Y = Phoenix_Thermo_Palm_2_dimY();
REF_Z = Phoenix_Thermo_Palm_2_dimZ();

uniform_scale = hand_length_mm / REF_HAND_LENGTH_MM;
x_scale = use_anisotropic_scaling ? palm_breadth_mm / REF_X : uniform_scale;
y_scale = use_anisotropic_scaling ? palm_length_mm / REF_Y : uniform_scale;
z_scale = use_anisotropic_scaling ? palm_thickness_mm / REF_Z : uniform_scale;

module phoenix_v3_palm_exact() {
    scale([x_scale, y_scale, z_scale]) {
        if (left_hand) {
            Phoenix_Thermo_Palm_2();
        } else {
            mirror([1, 0, 0]) Phoenix_Thermo_Palm_2();
        }
    }
}

phoenix_v3_palm_exact();
