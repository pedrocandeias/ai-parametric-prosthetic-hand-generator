// flexible flyer short gauntlet
// based very closely on Phoenix v2 thermo gauntlet

use <gripper_box_pieces.scad>

// This should match the scale of the hand and gripper box pieces.
global_scale=1.25; // [1:0.01:2]
// Clearance around screw holes to adjust for printer behavior. Screws should be fairly loose-fitting.
hole_clearance=0.5; // [0:0.01:1]

// Print only the wrist bearing tab, to make a thermoforming jig for the bearing plastic.
bearing_only=false;
// Print only the track for the tensioner box, to test the fit.
slide_only=false;

/* [Hidden] */ 
gauntlet_thickness = 2;

base_back_width=95;
base_front_width=78;
base_length=70;
corner_radius=5;
theta1=atan((base_back_width-base_front_width)/(base_length-2*corner_radius)/2);
echo(theta1);

front_curve_dia=150;
bearing_washer_dia=16;

bearing_big_dia=10;
bearing_little_dia=8;
bearing_plastic_thickness=0.5;
bearing_screw_dia=3 + hole_clearance;  // 3mm screw with clearance
bearing_screw_head_dia=5.8 + hole_clearance; // 5.6mm screw head, 5.8mm washer, with clearance
bearing_screw_head_depth=2.5;

bearing_depth=2;

strap_block_center=[(base_back_width+base_front_width)/4,0,0];

pin_center=[base_front_width/2-bearing_washer_dia/2-1, base_length/2+bearing_washer_dia/2+1];

track_outer_width=27;
track_base_thickness=2;
track_cut_thickness=2;
track_cut_width=21;
track_cut_angle=30;
track_length=56;

module racetrack(length, bottom_width, top_width, thickness) {
    hull() for(dy=[-1,1]*(length-bottom_width)/2) translate([0,dy,0]) 
        cylinder(d1=bottom_width, d2=top_width, h=thickness);
}

module flat_baseplate() {
    difference() {
        hull() for(dx=[
            [-base_back_width,-base_length], 
            [base_back_width,-base_length],
            [-base_front_width,base_length], 
            [base_front_width,base_length]]/2)
            translate([dx.x-corner_radius*sign(dx.x),dx.y-corner_radius*sign(dx.y)]) 
                circle(corner_radius);
        translate([0,base_length/2+front_curve_dia/2-5]) 
            circle(d=front_curve_dia, $fn=200);
    }
    for(dx=[-1,1]) scale([dx,1]) 
        translate(pin_center) hull() {
            translate([0,-bearing_washer_dia/2-5]) square([17,1],center=true);
            circle(d=bearing_washer_dia);
        }
}

module solid_base() {
    linear_extrude(gauntlet_thickness) flat_baseplate();

    for(s=[-1,1]) scale([s,1]) translate(strap_block_center+[0,0,gauntlet_thickness-0.1]) 
        rotate(theta1) 
        translate([-5,-2,0]) 
        racetrack(length=65, bottom_width=10, top_width=8, thickness=gauntlet_thickness);
}

module do_straps() {
    difference() {
        children();
        // cut strap slots
        for(s=[1,-1]) scale([s,1]) translate(strap_block_center) rotate(theta1) {
            $fn=20;
            for(dy=[15,-17]) translate([-5.5,dy,0]) {
                translate([0,0,-1]) 
                    racetrack(length=25, bottom_width=4, top_width=4, thickness=10);
                translate([0,0,2*gauntlet_thickness-1]) 
                    racetrack(length=25, bottom_width=4, top_width=8, thickness=3);
                translate([0,0,1]) scale([1,1,-1])
                    racetrack(length=25, bottom_width=4, top_width=8, thickness=3);
            }
        }
    }
}

module track_block() {
    translate([0,-(base_length-track_length)/2,gauntlet_thickness-0.01]) 
        difference() {
            rotate([90,0,0]) linear_extrude(track_length, center=true) hull() {
            translate([0,track_base_thickness/2]) 
                square([track_outer_width, track_base_thickness], center=true);
            translate([0,track_base_thickness+track_cut_thickness+0.01])
                square([track_outer_width-2*tan(30)*track_cut_thickness,
                    0.01], center=true);
            }
            translate([0,track_length/2+25-5,-1]) {
                $fn=100;
                cylinder(d=50,h=10);
                translate([0,0,3]) cylinder(d1=50, d2=60, h=5);
            }
            rotate([90,0,0]) translate([0,0,6])
            linear_extrude(track_length-5, center=true) translate([0,8]) rotate(180) slide(grow=0);
            translate([0,-6,(track_cut_thickness+track_base_thickness)])
                cube([track_cut_width-2*tan(track_cut_angle)*(track_cut_thickness+track_base_thickness)+1,track_length-5, 5],
                center=true);
        }
}

module do_track() {
    difference() {
        children();
        // cut grooves for bending
        for(dx=[-1,1]*(track_outer_width/2+1)) translate([dx,0,gauntlet_thickness])
            rotate([90,0,0]) cylinder(d=1.5, h=200, center=true, $fn=8);
    }
    track_block();    
}

module do_3mm_bearing() {
    sthick=bearing_plastic_thickness/global_scale;
    
    difference() {
        union() {
            children();
            for(s=[-1,1]) scale([s,1,1])
                translate([each pin_center,0]+[0,0,gauntlet_thickness-0.01]) {
                $fn=50;
                translate([0,0,-sthick/0.5]) // cylinder wall slope is 0.5
                    cylinder(d1=bearing_big_dia, d2=bearing_little_dia, h=2);
            }
        }
        for(s=[-1,1]) scale([s,1,1])
            translate([each pin_center,-0.01]) scale(1/global_scale) {
            $fn=20;
            cylinder(d=bearing_screw_dia, h=20);
            cylinder(d=bearing_screw_head_dia, h=bearing_screw_head_depth);
        }
    }
    // supports for flying hole
    for(s=[-1,1]) scale([s,1,1])
        translate([each pin_center,0]) scale(1/global_scale) {
        $fn=20;
        cylinder(d=bearing_screw_head_dia-1, h=bearing_screw_head_depth-0.25);
    }
}

scale(global_scale) intersection() {
    do_track() do_3mm_bearing() do_straps() solid_base();
    if(bearing_only) translate([each pin_center,-0.01]) cube(20, center=true);
    if(slide_only) translate([0,-20,0]) cube(30, center=true);
}