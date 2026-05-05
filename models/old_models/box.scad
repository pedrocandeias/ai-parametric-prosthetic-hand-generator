// Parametric Box
// Customizable box with lid option

/* [Dimensions] */
width = 50;
depth = 50;
height = 30;
wall_thickness = 2;

/* [Style] */
corner_radius = 5;

/* [Features] */
lid = true;

// Main module
module box() {
    difference() {
        // Outer box
        translate([0, 0, height/2])
            roundedBox(width, depth, height, corner_radius);

        // Inner cavity
        translate([0, 0, wall_thickness + (height - wall_thickness)/2])
            roundedBox(
                width - 2*wall_thickness,
                depth - 2*wall_thickness,
                height - wall_thickness + 0.1,
                max(0, corner_radius - wall_thickness)
            );
    }
}

module box_lid() {
    lid_height = wall_thickness * 2;
    lid_lip = wall_thickness * 0.8;

    union() {
        // Lid top
        translate([0, 0, lid_height/2])
            roundedBox(width, depth, lid_height, corner_radius);

        // Lid lip that fits inside box
        translate([0, 0, lid_height + (height - wall_thickness - lid_height)/2])
            roundedBox(
                width - 2*wall_thickness - 0.2,
                depth - 2*wall_thickness - 0.2,
                height - wall_thickness - lid_height,
                max(0, corner_radius - wall_thickness)
            );
    }
}

module roundedBox(w, d, h, r) {
    if (r > 0) {
        hull() {
            for (x = [-(w/2-r), (w/2-r)]) {
                for (y = [-(d/2-r), (d/2-r)]) {
                    translate([x, y, 0])
                        cylinder(h=h, r=r, center=true, $fn=30);
                }
            }
        }
    } else {
        cube([w, d, h], center=true);
    }
}

// Render
if (lid) {
    box();
    translate([0, depth + 10, 0])
        box_lid();
} else {
    box();
}
