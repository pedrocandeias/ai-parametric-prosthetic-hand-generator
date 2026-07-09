// Hybrid refinement of the optimizer result.
// This version preserves the optimizer shell and only expands the back plate
// envelope enough to better match the measured width and height.
plate_width = 24.8;
plate_height = 50.0;
plate_thickness = 3.0;

frame_depth = 14.957;
frame_outer_width = 12.8;
frame_outer_height = 27.4;
frame_back_width = 13.9;
frame_back_height = 29.8;
frame_inner_front_width = 9.7;
frame_inner_front_height = 25.2;
frame_inner_back_width = 9.75;
frame_inner_back_height = 24.4;

lug_center_z = 20.15;
lug_outer_radius = 4.85;
lug_hole_radius = 2.15;

show_reference = false;
reference_offset_x = 32.0;

$fn = 64;

module back_plate_profile() {
    hull() {
        translate([0, lug_center_z]) circle(r = lug_outer_radius);
        translate([0, -lug_center_z]) circle(r = lug_outer_radius);
        translate([plate_width / 2 - 1, 0]) circle(r = 1);
        translate([-plate_width / 2 + 1, 0]) circle(r = 1);
    }
}

module back_plate() {
    translate([0, -plate_thickness, 0])
        rotate([-90, 0, 0])
            linear_extrude(height = plate_thickness)
                back_plate_profile();
}

module front_frame_shell() {
    hull() {
        translate([-frame_outer_width / 2, -frame_depth, -frame_outer_height / 2])
            cube([frame_outer_width, 0.02, frame_outer_height]);
        translate([-frame_back_width / 2, -plate_thickness, -frame_back_height / 2])
            cube([frame_back_width, 0.01, frame_back_height]);
    }
}

module front_opening_cut() {
    hull() {
        translate([-frame_inner_front_width / 2, -frame_depth - 1.0, -frame_inner_front_height / 2])
            cube([frame_inner_front_width, 0.01, frame_inner_front_height]);
        translate([-frame_inner_back_width / 2, 1.0, -frame_inner_back_height / 2])
            cube([frame_inner_back_width, 0.01, frame_inner_back_height]);
    }
}

module lug_hole(z_pos) {
    translate([0, -frame_depth - 1, z_pos])
        rotate([-90, 0, 0])
            cylinder(h = frame_depth + plate_thickness + 2, r = lug_hole_radius);
}

module reconstructed_part() {
    difference() {
        union() {
            back_plate();
            front_frame_shell();
        }
        front_opening_cut();
        lug_hole(lug_center_z);
        lug_hole(-lug_center_z);
    }
}

module original_reference() {
    import("../../../../base.stl");
}

reconstructed_part();

if (show_reference) {
    color([0.2, 0.6, 0.9, 0.45])
        translate([reference_offset_x, 0, 0])
            original_reference();
}
