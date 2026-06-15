// ===== namespaced bundle: /tmp/gau_combined.scad (prefix GAU_) =====
// (library) ===== namespaced bundle: paraglider/gripper_box_pieces.scad (prefix ) =====
// parts for flexible-flyer parametric variant of Phoenix Reborn

// this should match the scale of the hand and gauntlet
// --- Anthropometric sizing (added for the parametric-prosthetic-hand-generator) ---
// Knuckle-to-knuckle metacarpal palm breadth (mm). Drives global_scale; the unscaled
// Paraglider hand spans REF_PALM_BREADTH mm at scale 1.0. Use the same value across the
// matching palm, fingers, tensioner box and gauntlet for a fitting set.
// [dispatcher-driven] palm_breadth_mm
// Manual scale-factor override (x). 0 = derive automatically from palm_breadth_mm.
// [dispatcher-driven] scale_override
// Palm breadth (mm) of the unscaled (scale 1.0) Paraglider hand.
// [dispatcher-driven] REF_PALM_BREADTH
// derived hand scale, clamped to the printable 1.0-2.0x range
// [dispatcher-driven] global_scale

// this sets how much clearance is on the dovetail.  It shouldn't depend on the scale
GAU_slide_clearance=0.2; // [0:0.01:0.5]

// The (approximately) root diameter of the screw thread for a nice fit
GAU_screw_thread_dia=2.8; // seems to work for m3
GAU_screw_clearance_dia=GAU_screw_thread_dia+0.5;
// diameter of screw head
GAU_screw_head_dia=5.5; // m3 screw
// distance between edge of screw heads and slider rail
GAU_screw_head_clearance=1.0; // minimum distance of screw heads above slider rail

module GAU_slide(grow) {
    // make a scalable slide profile, inset by the specified amount for clearance
    union() {
        hull() {
            translate([0,6.65]) square([20+grow,0.70], center=true);
            translate([0,4.3]) square([17+grow,0.5], center=true);
        }
        translate([0,4.5]) square([17,5], center=true);
    }
}

module GAU_box() {
    cl=GAU_slide_clearance/GAU_global_scale;
    difference() {
        linear_extrude(height=28) union() {
          square([30,8], center=true);
          GAU_slide(grow=-cl);
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
            cylinder(d=GAU_screw_clearance_dia/GAU_global_scale+.25, h=40, $fn=20, center=true); 
    }
}

module GAU_thumb_tensioner() {
    // translate([-15.0,69.8,-25.5]) import("thumb_v2_tensioner_pin.stl", convexity=10);
    translate([0,0,2.4]) difference() {
        rotate([-90,0,0]) intersection() {
            cube([4.8,4.8,20.5], center=true);
            rotate(45) cube([4.8*sqrt(2)-0.5, 4.8*sqrt(2)-0.5, 45], center=true);
        }
        translate([0,-3,0])
            rotate([90,0,0]) 
                cylinder(d=GAU_screw_thread_dia/GAU_global_scale, h=15, center=true, $fn=20);
        // translate([0,8,0]) cylinder(d=2, h=15, center=true, $fn=20);
        translate([0,10.3,0]) scale([1,1.2,1])
            rotate([0,90,0]) rotate_extrude(angle=180, convexity=10, $fn=50) 
                translate([-2.5,0]) circle(d=2.5, $fn=20);
    }
            
}

module GAU_pivot() {
    translate([0,0,3.5/2]) {
        difference() {
            translate([0,0,0]) cube([11,20,3.5], center=true);
            for(dx=[-2.8,2.8]) translate([dx,0,0]) rotate([90,0,0]) 
                cylinder(d=GAU_screw_thread_dia/GAU_global_scale, h=50, center=true, $fn=20);
        }
        translate([-1.1,3,1.74]) difference() {
            cylinder(d=6.5, h=5, $fn=20);
            scale([1,0.3,1]) translate([0, -10*sqrt(2)/2,0]) rotate(45) cube([10,10,12], center=true);
        }
    }
}

module GAU_whipple_tree() {
    // %import("whippletree_JD3.stl", convexity=10); 
    thickness=5.4-GAU_slide_clearance/GAU_global_scale;
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

// flexible flyer short gauntlet
// based very closely on Phoenix v2 thermo gauntlet


// This should match the scale of the hand and gripper box pieces.
// --- Anthropometric sizing (added for the parametric-prosthetic-hand-generator) ---
// Knuckle-to-knuckle metacarpal palm breadth (mm). Drives global_scale; the unscaled
// Paraglider hand spans REF_PALM_BREADTH mm at scale 1.0. Use the same value across the
// matching palm, fingers, tensioner box and gauntlet for a fitting set.
// [dispatcher-driven] palm_breadth_mm
// Manual scale-factor override (x). 0 = derive automatically from palm_breadth_mm.
GAU_scale_override = 0; // [0:0.01:2.0]
// Palm breadth (mm) of the unscaled (scale 1.0) Paraglider hand.
GAU_REF_PALM_BREADTH = 80.6;
// derived hand scale, clamped to the printable 1.0-2.0x range
GAU_global_scale = GAU_scale_override > 0 ? GAU_scale_override : max(1.0, min(2.0, palm_breadth_mm / GAU_REF_PALM_BREADTH));
// Clearance around screw holes to adjust for printer behavior. Screws should be fairly loose-fitting.
GAU_hole_clearance=0.5; // [0:0.01:1]

// Print only the wrist bearing tab, to make a thermoforming jig for the bearing plastic.
// [dispatcher-driven] bearing_only
// Print only the track for the tensioner box, to test the fit.
// [dispatcher-driven] slide_only

 
GAU_gauntlet_thickness = 2;

GAU_base_back_width=95;
GAU_base_front_width=78;
GAU_base_length=70;
GAU_corner_radius=5;
GAU_theta1=atan((GAU_base_back_width-GAU_base_front_width)/(GAU_base_length-2*GAU_corner_radius)/2);

GAU_front_curve_dia=150;
GAU_bearing_washer_dia=16;

GAU_bearing_big_dia=10;
GAU_bearing_little_dia=8;
GAU_bearing_plastic_thickness=0.5;
GAU_bearing_screw_dia=3 + GAU_hole_clearance;  // 3mm screw with clearance
GAU_bearing_screw_head_dia=5.8 + GAU_hole_clearance; // 5.6mm screw head, 5.8mm washer, with clearance
GAU_bearing_screw_head_depth=2.5;

GAU_bearing_depth=2;

GAU_strap_block_center=[(GAU_base_back_width+GAU_base_front_width)/4,0,0];

GAU_pin_center=[GAU_base_front_width/2-GAU_bearing_washer_dia/2-1, GAU_base_length/2+GAU_bearing_washer_dia/2+1];

GAU_track_outer_width=27;
GAU_track_base_thickness=2;
GAU_track_cut_thickness=2;
GAU_track_cut_width=21;
GAU_track_cut_angle=30;
GAU_track_length=56;

module GAU_racetrack(length, bottom_width, top_width, thickness) {
    hull() for(dy=[-1,1]*(length-bottom_width)/2) translate([0,dy,0]) 
        cylinder(d1=bottom_width, d2=top_width, h=thickness);
}

module GAU_flat_baseplate() {
    difference() {
        hull() for(dx=[
            [-GAU_base_back_width,-GAU_base_length], 
            [GAU_base_back_width,-GAU_base_length],
            [-GAU_base_front_width,GAU_base_length], 
            [GAU_base_front_width,GAU_base_length]]/2)
            translate([dx.x-GAU_corner_radius*sign(dx.x),dx.y-GAU_corner_radius*sign(dx.y)]) 
                circle(GAU_corner_radius);
        translate([0,GAU_base_length/2+GAU_front_curve_dia/2-5]) 
            circle(d=GAU_front_curve_dia, $fn=200);
    }
    for(dx=[-1,1]) scale([dx,1]) 
        translate(GAU_pin_center) hull() {
            translate([0,-GAU_bearing_washer_dia/2-5]) square([17,1],center=true);
            circle(d=GAU_bearing_washer_dia);
        }
}

module GAU_solid_base() {
    linear_extrude(GAU_gauntlet_thickness) GAU_flat_baseplate();

    for(s=[-1,1]) scale([s,1]) translate(GAU_strap_block_center+[0,0,GAU_gauntlet_thickness-0.1]) 
        rotate(GAU_theta1) 
        translate([-5,-2,0]) 
        GAU_racetrack(length=65, bottom_width=10, top_width=8, thickness=GAU_gauntlet_thickness);
}

module GAU_do_straps() {
    difference() {
        children();
        // cut strap slots
        for(s=[1,-1]) scale([s,1]) translate(GAU_strap_block_center) rotate(GAU_theta1) {
            $fn=20;
            for(dy=[15,-17]) translate([-5.5,dy,0]) {
                translate([0,0,-1]) 
                    GAU_racetrack(length=25, bottom_width=4, top_width=4, thickness=10);
                translate([0,0,2*GAU_gauntlet_thickness-1]) 
                    GAU_racetrack(length=25, bottom_width=4, top_width=8, thickness=3);
                translate([0,0,1]) scale([1,1,-1])
                    GAU_racetrack(length=25, bottom_width=4, top_width=8, thickness=3);
            }
        }
    }
}

module GAU_track_block() {
    translate([0,-(GAU_base_length-GAU_track_length)/2,GAU_gauntlet_thickness-0.01]) 
        difference() {
            rotate([90,0,0]) linear_extrude(GAU_track_length, center=true) hull() {
            translate([0,GAU_track_base_thickness/2]) 
                square([GAU_track_outer_width, GAU_track_base_thickness], center=true);
            translate([0,GAU_track_base_thickness+GAU_track_cut_thickness+0.01])
                square([GAU_track_outer_width-2*tan(30)*GAU_track_cut_thickness,
                    0.01], center=true);
            }
            translate([0,GAU_track_length/2+25-5,-1]) {
                $fn=100;
                cylinder(d=50,h=10);
                translate([0,0,3]) cylinder(d1=50, d2=60, h=5);
            }
            rotate([90,0,0]) translate([0,0,6])
            linear_extrude(GAU_track_length-5, center=true) translate([0,8]) rotate(180) GAU_slide(grow=0);
            translate([0,-6,(GAU_track_cut_thickness+GAU_track_base_thickness)])
                cube([GAU_track_cut_width-2*tan(GAU_track_cut_angle)*(GAU_track_cut_thickness+GAU_track_base_thickness)+1,GAU_track_length-5, 5],
                center=true);
        }
}

module GAU_do_track() {
    difference() {
        children();
        // cut grooves for bending
        for(dx=[-1,1]*(GAU_track_outer_width/2+1)) translate([dx,0,GAU_gauntlet_thickness])
            rotate([90,0,0]) cylinder(d=1.5, h=200, center=true, $fn=8);
    }
    GAU_track_block();    
}

module GAU_do_3mm_bearing() {
    sthick=GAU_bearing_plastic_thickness/GAU_global_scale;
    
    difference() {
        union() {
            children();
            for(s=[-1,1]) scale([s,1,1])
                translate([each GAU_pin_center,0]+[0,0,GAU_gauntlet_thickness-0.01]) {
                $fn=50;
                translate([0,0,-sthick/0.5]) // cylinder wall slope is 0.5
                    cylinder(d1=GAU_bearing_big_dia, d2=GAU_bearing_little_dia, h=2);
            }
        }
        for(s=[-1,1]) scale([s,1,1])
            translate([each GAU_pin_center,-0.01]) scale(1/GAU_global_scale) {
            $fn=20;
            cylinder(d=GAU_bearing_screw_dia, h=20);
            cylinder(d=GAU_bearing_screw_head_dia, h=GAU_bearing_screw_head_depth);
        }
    }
    // supports for flying hole
    for(s=[-1,1]) scale([s,1,1])
        translate([each GAU_pin_center,0]) scale(1/GAU_global_scale) {
        $fn=20;
        cylinder(d=GAU_bearing_screw_head_dia-1, h=GAU_bearing_screw_head_depth-0.25);
    }
}

module GAU_main() {
echo(GAU_theta1);

scale(GAU_global_scale) intersection() {
    GAU_do_track() GAU_do_3mm_bearing() GAU_do_straps() GAU_solid_base();
    if(GAU_bearing_only) translate([each GAU_pin_center,-0.01]) cube(20, center=true);
    if(GAU_slide_only) translate([0,-20,0]) cube(30, center=true);
}
}
