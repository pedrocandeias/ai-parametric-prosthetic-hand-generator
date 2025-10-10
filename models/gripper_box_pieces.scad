// parts for flexible-flyer parametric variant of Phoenix Reborn

// this should match the scale of the hand and gauntlet
global_scale=1.25; // [1:0.01:2]

// this sets how much clearance is on the dovetail.  It shouldn't depend on the scale
slide_clearance=0.2; // [0:0.01:0.5]

// The (approximately) root diameter of the screw thread for a nice fit
screw_thread_dia=2.8; // seems to work for m3
screw_clearance_dia=screw_thread_dia+0.5;
// diameter of screw head
screw_head_dia=5.5; // m3 screw
// distance between edge of screw heads and slider rail
screw_head_clearance=1.0; // minimum distance of screw heads above slider rail

module slide(grow) {
    // make a scalable slide profile, inset by the specified amount for clearance
    union() {
        hull() {
            translate([0,6.65]) square([20+grow,0.70], center=true);
            translate([0,4.3]) square([17+grow,0.5], center=true);
        }
        translate([0,4.5]) square([17,5], center=true);
    }
}

module box() {
    cl=slide_clearance/global_scale;
    difference() {
        linear_extrude(height=28) union() {
          square([30,8], center=true);
          slide(grow=-cl);
        };
        whip_box_x=11.2+cl;
        whip_box_y=5;
        
        translate([-1.8,6.0-whip_box_y/2+cl,22]) 
            cube([whip_box_x,whip_box_y,40], center=true);


        piv_box_x=22.0+cl;
        piv_box_y=5.4+cl;
        
        translate([-3,2.5-piv_box_y/2,22]) 
            cube([piv_box_x,piv_box_y,40], center=true);
        
        thumb_pin=4.8+cl;
        translate([11.5,0,22]) 
            cube([thumb_pin,thumb_pin,40], center=true);
        
        
        for(dx=[[11.5,0,0],[-4.6,4.2,0],[1,4.2,0]]) translate(dx)
            cylinder(d=screw_clearance_dia/global_scale+.25, h=40, $fn=20, center=true); 
    }
}

module thumb_tensioner() {
    // translate([-15.0,69.8,-25.5]) import("thumb_v2_tensioner_pin.stl", convexity=10);
    translate([0,0,2.4]) difference() {
        rotate([-90,0,0]) intersection() {
            cube([4.8,4.8,20.5], center=true);
            rotate(45) cube([4.8*sqrt(2)-0.5, 4.8*sqrt(2)-0.5, 45], center=true);
        }
        translate([0,-3,0])
            rotate([90,0,0]) 
                cylinder(d=screw_thread_dia/global_scale, h=15, center=true, $fn=20);
        // translate([0,8,0]) cylinder(d=2, h=15, center=true, $fn=20);
        translate([0,10.3,0]) scale([1,1.2,1])
            rotate([0,90,0]) rotate_extrude(angle=180, convexity=10, $fn=50) 
                translate([-2.5,0]) circle(d=2.5, $fn=20);
    }
            
}

module pivot() {
    translate([0,0,3.5/2]) {
        difference() {
            translate([0,0,0]) cube([11,20,3.5], center=true);
            for(dx=[-2.8,2.8]) translate([dx,0,0]) rotate([90,0,0]) 
                cylinder(d=screw_thread_dia/global_scale, h=50, center=true, $fn=20);
        }
        translate([-1.1,3,1.74]) difference() {
            cylinder(d=6.5, h=5, $fn=20);
            scale([1,0.3,1]) translate([0, -10*sqrt(2)/2,0]) rotate(45) cube([10,10,12], center=true);
        }
    }
}

module whipple_tree() {
    // %import("whippletree_JD3.stl", convexity=10); 
    thickness=5.4-slide_clearance/global_scale;
    ht=thickness/2;
    difference() {
        linear_extrude(height=thickness) difference() {
            hull() {
                $fn=20;
                translate([0,-3.8,0]) circle(d=7);
                translate([6.3,1,0]) circle(d=8);
                translate([-6.3,1,0]) circle(d=8);
            }
            difference() {
                translate([0,-1]) circle(d=9);
                translate([0,-9]) rotate(45) square(5);
            }
        }
        for(dx=[-1,1]*5.3) translate([dx,5.2,ht]) scale([0.7,1,1])
            rotate_extrude(angle=360, $fn=50) translate([5,0]) 
                scale([1/0.7,1]) circle(d=2, $fn=16);
    }
}

scale(global_scale) translate([-5,-15,0]) rotate(0) pivot();

scale(global_scale) translate([5,-15,0]) rotate(0) thumb_tensioner();

scale(global_scale) box();

translate([0,15*global_scale,0]) rotate(180) scale(global_scale) whipple_tree();
