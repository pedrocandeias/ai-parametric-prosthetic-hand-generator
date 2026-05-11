// Phoenix Hand v3 - Exact Legacy Assembly

use <phoenix_v3_palm_legacy_geometry.scad>
use <phoenix_v3_fingers_legacy_geometry.scad>
use <phoenix_v3_phalanx_legacy_geometry.scad>
use <phoenix_v3_pins_legacy_geometry.scad>

/* [Scaling] */
hand_length_mm = 135; // [120:1:230]

/* [Orientation] */
left_hand = true;

/* [Visibility] */
show_palm = true;
show_fingers = true;
show_phalanx_bank = true;
show_pins = true;

/* [Colors] */
show_colors = true;
color_palm = "#e5e5ea";
color_fingers = "#dcbba4";
color_phalanx_bank = "#c9dceb";
color_pins = "#f2b84d";

/* [Assembly Placement] */
fingers_translate_x_mm = 31.7;
fingers_translate_y_mm = -4.5;
fingers_translate_z_mm = 0;
phalanx_translate_x_mm = 31.9;
phalanx_translate_y_mm = -66.0;
phalanx_translate_z_mm = 0;
pins_translate_x_mm = 95;
pins_translate_y_mm = -42;
pins_translate_z_mm = 8;
pins_rotate_z_deg = 90;

/* [Hidden] */
REF_HAND_LENGTH_MM = 135;
uniform_scale = hand_length_mm / REF_HAND_LENGTH_MM;
mirror_scale_x = left_hand ? uniform_scale : -uniform_scale;

function translate_points(points, offset) =
    [for (p = points) [p[0] + offset[0], p[1] + offset[1], p[2] + offset[2]]];

function rotate_z_points(points, deg) =
    [for (p = points) [
        cos(deg) * p[0] - sin(deg) * p[1],
        sin(deg) * p[0] + cos(deg) * p[1],
        p[2]
    ]];

function scale_points(points, sx, sy, sz) =
    [for (p = points) [p[0] * sx, p[1] * sy, p[2] * sz]];

function offset_faces(faces, offset) =
    [for (f = faces) [for (idx = f) idx + offset]];

function palm_points_assembled() =
    show_palm ? scale_points(Phoenix_Thermo_Palm_2_points(), mirror_scale_x, uniform_scale, uniform_scale) : [];

function fingers_points_assembled() =
    show_fingers
        ? scale_points(
            translate_points(Phoenix_Fingers_Left_points(), [fingers_translate_x_mm, fingers_translate_y_mm, fingers_translate_z_mm]),
            mirror_scale_x, uniform_scale, uniform_scale
          )
        : [];

function phalanx_points_assembled() =
    show_phalanx_bank
        ? scale_points(
            translate_points(Phoenix_Phalanx_Left_points(), [phalanx_translate_x_mm, phalanx_translate_y_mm, phalanx_translate_z_mm]),
            mirror_scale_x, uniform_scale, uniform_scale
          )
        : [];

function pins_points_assembled() =
    show_pins
        ? scale_points(
            translate_points(
                rotate_z_points(Phoenix_Pins_points(), pins_rotate_z_deg),
                [pins_translate_x_mm, pins_translate_y_mm, pins_translate_z_mm]
            ),
            mirror_scale_x, uniform_scale, uniform_scale
          )
        : [];

function palm_faces_assembled() = show_palm ? Phoenix_Thermo_Palm_2_faces() : [];
function fingers_faces_assembled() = show_fingers ? Phoenix_Fingers_Left_faces() : [];
function phalanx_faces_assembled() = show_phalanx_bank ? Phoenix_Phalanx_Left_faces() : [];
function pins_faces_assembled() = show_pins ? Phoenix_Pins_faces() : [];

palm_pts = palm_points_assembled();
fingers_pts = fingers_points_assembled();
phalanx_pts = phalanx_points_assembled();
pins_pts = pins_points_assembled();

palm_faces = palm_faces_assembled();
fingers_faces = fingers_faces_assembled();
phalanx_faces = phalanx_faces_assembled();
pins_faces = pins_faces_assembled();

palm_count = len(palm_pts);
fingers_count = len(fingers_pts);
phalanx_count = len(phalanx_pts);

all_points = concat(palm_pts, fingers_pts, phalanx_pts, pins_pts);
all_faces = concat(
    offset_faces(palm_faces, 0),
    offset_faces(fingers_faces, palm_count),
    offset_faces(phalanx_faces, palm_count + fingers_count),
    offset_faces(pins_faces, palm_count + fingers_count + phalanx_count)
);

module phoenix_v3_assembly_exact() {
    if (len(all_points) > 0 && len(all_faces) > 0) {
        polyhedron(points = all_points, faces = all_faces, convexity = 10);
    }
}

phoenix_v3_assembly_exact();
