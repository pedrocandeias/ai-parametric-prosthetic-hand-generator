// Phoenix Hand v3 - Exact Legacy Pins

use <phoenix_v3_pins_legacy_geometry.scad>

/* [Scaling] */
hand_length_mm = 135; // [120:1:230]
use_anisotropic_scaling = false;

/* [Optional Anisotropic Controls] */
pins_span_mm = 78.47; // [50:1:120]
pins_length_mm = 44.25; // [25:1:70]
pins_thickness_mm = 4.30; // [2:0.1:10]

/* [Hidden] */
REF_HAND_LENGTH_MM = 135;
REF_X = Phoenix_Pins_dimX();
REF_Y = Phoenix_Pins_dimY();
REF_Z = Phoenix_Pins_dimZ();

uniform_scale = hand_length_mm / REF_HAND_LENGTH_MM;
x_scale = use_anisotropic_scaling ? pins_span_mm / REF_X : uniform_scale;
y_scale = use_anisotropic_scaling ? pins_length_mm / REF_Y : uniform_scale;
z_scale = use_anisotropic_scaling ? pins_thickness_mm / REF_Z : uniform_scale;

module phoenix_v3_pins_exact() {
    scale([x_scale, y_scale, z_scale]) Phoenix_Pins();
}

phoenix_v3_pins_exact();
