// Phoenix Hand v3 - Split-Digit Assembled Preview

use <phoenix_v3_palm_legacy_geometry.scad>
use <phoenix_v3_pins_legacy_geometry.scad>
use <phoenix_v3_fingers_split_geometry.scad>
use <phoenix_v3_phalanx_split_geometry.scad>

/* [Scaling] */
hand_length_mm = 135; // [120:1:230]

/* [Orientation] */
left_hand = true;

/* [Visibility] */
show_palm = true;
show_fingers = true;
show_phalanx_bank = true;
show_pins = false;

/* [Colors] */
show_colors = true;
color_palm = "#e5e5ea";
color_fingers = "#dcbba4";
color_phalanx_bank = "#c9dceb";
color_pins = "#f2b84d";

/* [Assembly Placement] */
main_digit_x_targets = [33, 49, 65, 81];
thumb_x_target = 95;
main_mcp_y = -49.5;
main_mcp_z = 12;
thumb_proximal_y = -60;
thumb_proximal_z = 11;
thumb_finger_y = -44;
thumb_finger_z = 10;
thumb_proximal_rotate_z_deg = -24;
thumb_finger_rotate_z_deg = -32;
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

function rotate_x_points(points, deg) =
    [for (p = points) [
        p[0],
        cos(deg) * p[1] - sin(deg) * p[2],
        sin(deg) * p[1] + cos(deg) * p[2]
    ]];

function rotate_y_points(points, deg) =
    [for (p = points) [
        cos(deg) * p[0] + sin(deg) * p[2],
        p[1],
        -sin(deg) * p[0] + cos(deg) * p[2]
    ]];

function transform_anchor(point, anchor, rx, ry, rz) =
    rotate_z_points(
        rotate_y_points(
            rotate_x_points([[point[0] - anchor[0], point[1] - anchor[1], point[2] - anchor[2]]], rx),
            ry
        ),
        rz
    )[0];

function transform_points_about_anchor(points, anchor, rx, ry, rz, target) =
    [for (p = points)
        let(tp = transform_anchor(p, anchor, rx, ry, rz))
        [tp[0] + target[0], tp[1] + target[1], tp[2] + target[2]]
    ];

function scale_points(points, sx, sy, sz) =
    [for (p = points) [p[0] * sx, p[1] * sy, p[2] * sz]];

function offset_faces(faces, offset) =
    [for (f = faces) [for (idx = f) idx + offset]];

function v_add(a, b) = [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
function v_sub(a, b) = [a[0] - b[0], a[1] - b[1], a[2] - b[2]];

function proximal_distal_anchors() = [
    [-2.161, 26.484, 12.061],
    [14.060, 26.484, 12.061],
    [30.282, 26.484, 12.061],
    [46.503, 26.484, 12.061],
    [64.517, 26.326, 11.810]
];

function proximal_mcp_anchors() = [
    [-2.229, 44.861, 8.154],
    [13.992, 44.861, 8.154],
    [30.214, 44.861, 8.154],
    [46.435, 44.861, 8.154],
    [64.281, 45.112, 8.170]
];

function finger_joint_anchors() = [
    [-2.028, -21.987, 9.090],
    [13.577, -21.987, 9.090],
    [28.815, -22.073, 9.154],
    [44.420, -22.073, 9.154],
    [62.628, -21.866, 9.040]
];

function main_digit_target(i) = [main_digit_x_targets[i], main_mcp_y, main_mcp_z];

function distal_target(i) =
    v_add(main_digit_target(i), v_sub(proximal_distal_anchors()[i], proximal_mcp_anchors()[i]));

function part_points(points, show, anchor, rx, ry, rz, target) =
    show
        ? scale_points(
            transform_points_about_anchor(points, anchor, rx, ry, rz, target),
            mirror_scale_x, uniform_scale, uniform_scale
          )
        : [];

function palm_points_assembled() =
    show_palm ? scale_points(Phoenix_Thermo_Palm_2_points(), mirror_scale_x, uniform_scale, uniform_scale) : [];

function finger_pinky_points_assembled() =
    part_points(phoenix_v3_fingers_pinky_points(), show_fingers, finger_joint_anchors()[0], 0, 180, 0, distal_target(0));
function finger_ring_points_assembled() =
    part_points(phoenix_v3_fingers_ring_points(), show_fingers, finger_joint_anchors()[1], 0, 180, 0, distal_target(1));
function finger_middle_points_assembled() =
    part_points(phoenix_v3_fingers_middle_points(), show_fingers, finger_joint_anchors()[2], 0, 180, 0, distal_target(2));
function finger_index_points_assembled() =
    part_points(phoenix_v3_fingers_index_points(), show_fingers, finger_joint_anchors()[3], 0, 180, 0, distal_target(3));
function finger_thumb_points_assembled() =
    part_points(
        phoenix_v3_fingers_thumb_points(),
        show_fingers,
        finger_joint_anchors()[4],
        0, 180, thumb_finger_rotate_z_deg,
        [thumb_x_target, thumb_finger_y, thumb_finger_z]
    );

function phalanx_pinky_points_assembled() =
    part_points(phoenix_v3_phalanx_pinky_points(), show_phalanx_bank, proximal_mcp_anchors()[0], 0, 0, 0, main_digit_target(0));
function phalanx_ring_points_assembled() =
    part_points(phoenix_v3_phalanx_ring_points(), show_phalanx_bank, proximal_mcp_anchors()[1], 0, 0, 0, main_digit_target(1));
function phalanx_middle_points_assembled() =
    part_points(phoenix_v3_phalanx_middle_points(), show_phalanx_bank, proximal_mcp_anchors()[2], 0, 0, 0, main_digit_target(2));
function phalanx_index_points_assembled() =
    part_points(phoenix_v3_phalanx_index_points(), show_phalanx_bank, proximal_mcp_anchors()[3], 0, 0, 0, main_digit_target(3));
function phalanx_thumb_points_assembled() =
    part_points(
        phoenix_v3_phalanx_thumb_points(),
        show_phalanx_bank,
        proximal_mcp_anchors()[4],
        0, 0, thumb_proximal_rotate_z_deg,
        [thumb_x_target, thumb_proximal_y, thumb_proximal_z]
    );

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
function finger_pinky_faces_assembled() = show_fingers ? phoenix_v3_fingers_pinky_faces() : [];
function finger_ring_faces_assembled() = show_fingers ? phoenix_v3_fingers_ring_faces() : [];
function finger_middle_faces_assembled() = show_fingers ? phoenix_v3_fingers_middle_faces() : [];
function finger_index_faces_assembled() = show_fingers ? phoenix_v3_fingers_index_faces() : [];
function finger_thumb_faces_assembled() = show_fingers ? phoenix_v3_fingers_thumb_faces() : [];
function phalanx_pinky_faces_assembled() = show_phalanx_bank ? phoenix_v3_phalanx_pinky_faces() : [];
function phalanx_ring_faces_assembled() = show_phalanx_bank ? phoenix_v3_phalanx_ring_faces() : [];
function phalanx_middle_faces_assembled() = show_phalanx_bank ? phoenix_v3_phalanx_middle_faces() : [];
function phalanx_index_faces_assembled() = show_phalanx_bank ? phoenix_v3_phalanx_index_faces() : [];
function phalanx_thumb_faces_assembled() = show_phalanx_bank ? phoenix_v3_phalanx_thumb_faces() : [];
function pins_faces_assembled() = show_pins ? Phoenix_Pins_faces() : [];

palm_pts = palm_points_assembled();
finger_pinky_pts = finger_pinky_points_assembled();
finger_ring_pts = finger_ring_points_assembled();
finger_middle_pts = finger_middle_points_assembled();
finger_index_pts = finger_index_points_assembled();
finger_thumb_pts = finger_thumb_points_assembled();
phalanx_pinky_pts = phalanx_pinky_points_assembled();
phalanx_ring_pts = phalanx_ring_points_assembled();
phalanx_middle_pts = phalanx_middle_points_assembled();
phalanx_index_pts = phalanx_index_points_assembled();
phalanx_thumb_pts = phalanx_thumb_points_assembled();
pins_pts = pins_points_assembled();

palm_faces = palm_faces_assembled();
finger_pinky_faces = finger_pinky_faces_assembled();
finger_ring_faces = finger_ring_faces_assembled();
finger_middle_faces = finger_middle_faces_assembled();
finger_index_faces = finger_index_faces_assembled();
finger_thumb_faces = finger_thumb_faces_assembled();
phalanx_pinky_faces = phalanx_pinky_faces_assembled();
phalanx_ring_faces = phalanx_ring_faces_assembled();
phalanx_middle_faces = phalanx_middle_faces_assembled();
phalanx_index_faces = phalanx_index_faces_assembled();
phalanx_thumb_faces = phalanx_thumb_faces_assembled();
pins_faces = pins_faces_assembled();

palm_count = len(palm_pts);
finger_pinky_count = len(finger_pinky_pts);
finger_ring_count = len(finger_ring_pts);
finger_middle_count = len(finger_middle_pts);
finger_index_count = len(finger_index_pts);
finger_thumb_count = len(finger_thumb_pts);
phalanx_pinky_count = len(phalanx_pinky_pts);
phalanx_ring_count = len(phalanx_ring_pts);
phalanx_middle_count = len(phalanx_middle_pts);
phalanx_index_count = len(phalanx_index_pts);
phalanx_thumb_count = len(phalanx_thumb_pts);

all_points = concat(
    palm_pts,
    finger_pinky_pts, finger_ring_pts, finger_middle_pts, finger_index_pts, finger_thumb_pts,
    phalanx_pinky_pts, phalanx_ring_pts, phalanx_middle_pts, phalanx_index_pts, phalanx_thumb_pts,
    pins_pts
);

all_faces = concat(
    offset_faces(palm_faces, 0),
    offset_faces(finger_pinky_faces, palm_count),
    offset_faces(finger_ring_faces, palm_count + finger_pinky_count),
    offset_faces(finger_middle_faces, palm_count + finger_pinky_count + finger_ring_count),
    offset_faces(finger_index_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count),
    offset_faces(finger_thumb_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count + finger_index_count),
    offset_faces(phalanx_pinky_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count + finger_index_count + finger_thumb_count),
    offset_faces(phalanx_ring_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count + finger_index_count + finger_thumb_count + phalanx_pinky_count),
    offset_faces(phalanx_middle_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count + finger_index_count + finger_thumb_count + phalanx_pinky_count + phalanx_ring_count),
    offset_faces(phalanx_index_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count + finger_index_count + finger_thumb_count + phalanx_pinky_count + phalanx_ring_count + phalanx_middle_count),
    offset_faces(phalanx_thumb_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count + finger_index_count + finger_thumb_count + phalanx_pinky_count + phalanx_ring_count + phalanx_middle_count + phalanx_index_count),
    offset_faces(pins_faces, palm_count + finger_pinky_count + finger_ring_count + finger_middle_count + finger_index_count + finger_thumb_count + phalanx_pinky_count + phalanx_ring_count + phalanx_middle_count + phalanx_index_count + phalanx_thumb_count)
);

module phoenix_v3_assembly_exact() {
    if (len(all_points) > 0 && len(all_faces) > 0) {
        polyhedron(points = all_points, faces = all_faces, convexity = 10);
    }
}

phoenix_v3_assembly_exact();
