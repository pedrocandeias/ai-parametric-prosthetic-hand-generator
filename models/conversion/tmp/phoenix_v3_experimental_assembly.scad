use <phoenix_v3_palm_temp_geometry.scad>
use <phoenix_v3_pins_temp_geometry.scad>
use <phoenix_v3_fingers_split_geometry.scad>
use <phoenix_v3_phalanx_split_geometry.scad>

$fn = 64;

hand_length_mm = 135;
legacy_hand_length_mm = 135;

show_palm = true;
show_fingers = true;
show_proximals = true;
show_pins = false;

show_colors = true;
color_palm = "#f2efe6";
color_fingers = "#5f7cff";
color_proximals = "#8f63d5";
color_pins = "#4f4f55";

// Experimental assembly targets in the shared palm coordinate frame.
// These are independent per-digit placements, not the original print layout.
main_digit_x_targets = [33, 49, 65, 81];
thumb_x_target = 95;

main_mcp_y = -52.5;
main_mcp_z = 17;
thumb_proximal_y = -64;
thumb_proximal_z = 16;
thumb_finger_y = -47;
thumb_finger_z = 15;

main_finger_rotate = [0, 180, 0];
thumb_finger_rotate = [0, 180, -32];
thumb_proximal_rotate = [0, 0, -24];

pins_translate = [95, -42, 8];
pins_rotate = [0, 0, 90];

scale_factor = hand_length_mm / legacy_hand_length_mm;

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

module tint(hex) {
    if (show_colors) color(hex) children();
    else children();
}

function v_add(a, b) = [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
function v_sub(a, b) = [a[0] - b[0], a[1] - b[1], a[2] - b[2]];

module place_from_anchor(local_anchor, world_target, rotation = [0, 0, 0]) {
    translate(world_target)
        rotate(rotation)
            translate([-local_anchor[0], -local_anchor[1], -local_anchor[2]])
                children();
}

module assemble_proximals() {
    for (i = [0:3]) {
        place_from_anchor(
            proximal_mcp_anchors()[i],
            [main_digit_x_targets[i], main_mcp_y, main_mcp_z]
        ) children(i);
    }
}

module assemble_fingers() {
    for (i = [0:3]) {
        place_from_anchor(
            finger_joint_anchors()[i],
            v_add(
                [main_digit_x_targets[i], main_mcp_y, main_mcp_z],
                v_sub(proximal_distal_anchors()[i], proximal_mcp_anchors()[i])
            ),
            main_finger_rotate
        ) children(i);
    }
}

module phoenix_v3_experimental_assembly() {
    scale([scale_factor, scale_factor, scale_factor]) {
        if (show_palm)
            tint(color_palm) phoenix_v3_palm_temp();

        if (show_proximals)
            tint(color_proximals) {
                assemble_proximals() {
                    phoenix_v3_phalanx_pinky();
                    phoenix_v3_phalanx_ring();
                    phoenix_v3_phalanx_middle();
                    phoenix_v3_phalanx_index();
                }

                place_from_anchor(
                    proximal_mcp_anchors()[4],
                    [thumb_x_target, thumb_proximal_y, thumb_proximal_z],
                    thumb_proximal_rotate
                ) phoenix_v3_phalanx_thumb();
            }

        if (show_fingers)
            tint(color_fingers) {
                assemble_fingers() {
                    phoenix_v3_fingers_pinky();
                    phoenix_v3_fingers_ring();
                    phoenix_v3_fingers_middle();
                    phoenix_v3_fingers_index();
                }

                place_from_anchor(
                    finger_joint_anchors()[4],
                    [thumb_x_target, thumb_finger_y, thumb_finger_z],
                    thumb_finger_rotate
                ) phoenix_v3_fingers_thumb();
            }

        if (show_pins)
            tint(color_pins)
                translate(pins_translate)
                    rotate(pins_rotate)
                        phoenix_v3_pins_temp();
    }
}

phoenix_v3_experimental_assembly();
