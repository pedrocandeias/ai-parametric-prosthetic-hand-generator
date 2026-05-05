// Parametric Gear
// Based on public domain gear script

/* [Gear Properties] */
number_of_teeth = 20;
circular_pitch = 5;
pressure_angle = 20;
clearance = 0.2;

/* [Dimensions] */
gear_thickness = 5;
rim_thickness = 5;
hub_thickness = 10;
bore = 5;

// Calculated values
pitch_radius = number_of_teeth * circular_pitch / (2 * PI);

// Gear module
module gear() {
    difference() {
        union() {
            // Gear teeth
            linear_extrude(height=gear_thickness)
                gear_2d(
                    number_of_teeth=number_of_teeth,
                    circular_pitch=circular_pitch,
                    pressure_angle=pressure_angle,
                    clearance=clearance
                );

            // Rim
            if (rim_thickness > gear_thickness) {
                translate([0, 0, gear_thickness])
                    cylinder(
                        h=rim_thickness-gear_thickness,
                        r=pitch_radius * 0.8,
                        $fn=number_of_teeth*2
                    );
            }

            // Hub
            if (hub_thickness > rim_thickness) {
                translate([0, 0, rim_thickness])
                    cylinder(
                        h=hub_thickness-rim_thickness,
                        r=pitch_radius * 0.4,
                        $fn=number_of_teeth
                    );
            }
        }

        // Center bore
        if (bore > 0) {
            translate([0, 0, -0.5])
                cylinder(h=hub_thickness+1, r=bore/2, $fn=30);
        }
    }
}

module gear_2d(
    number_of_teeth,
    circular_pitch,
    pressure_angle,
    clearance
) {
    pitch_radius = number_of_teeth * circular_pitch / (2 * PI);
    base_radius = pitch_radius * cos(pressure_angle);
    outer_radius = pitch_radius + circular_pitch / PI - clearance;
    root_radius = pitch_radius - circular_pitch / PI - clearance;

    // Generate gear profile
    difference() {
        union() {
            // Outer circle
            circle(r=outer_radius, $fn=number_of_teeth*4);

            // Teeth
            for (i = [0:number_of_teeth-1]) {
                rotate([0, 0, i*360/number_of_teeth])
                    gear_tooth(
                        base_radius=base_radius,
                        outer_radius=outer_radius,
                        half_tooth_angle=180/number_of_teeth
                    );
            }
        }

        // Remove center for root
        circle(r=root_radius, $fn=number_of_teeth*2);
    }
}

module gear_tooth(base_radius, outer_radius, half_tooth_angle) {
    angle_step = 0.5;
    points = [
        for (t = [0:angle_step:half_tooth_angle])
            let(
                r = base_radius + (outer_radius - base_radius) * (t / half_tooth_angle),
                a = t
            )
            [r * cos(a), r * sin(a)]
    ];

    mirror_points = [
        for (i = [len(points)-1:-1:0])
            [points[i][0], -points[i][1]]
    ];

    polygon(concat(points, mirror_points));
}

// Render the gear
gear();
