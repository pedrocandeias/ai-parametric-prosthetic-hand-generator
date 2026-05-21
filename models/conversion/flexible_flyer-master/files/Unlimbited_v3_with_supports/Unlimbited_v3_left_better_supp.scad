translate([-20,51.5,2.75]) import("Unlimbited_v3_palm_left_f360.stl", convexity=10);

difference() {    
    group () for(dy=[-29:5:15]) translate([0,dy,0]) {
        translate([-7,0.5,21]) cube([52,2,0.5],  center=true);
        translate([-7,0,22]) cube([52,0.4,2],  center=true);
        // translate([-7,0,22]) cube([45,0.4,3],  center=true);
        translate([-7,0,23]) cube([45,0.4,3],  center=true);
        translate([-7,0,23]) cube([30,0.4,3],  center=true);
    }
    // remove intrusion of supports into pinky control hole
    translate([-27,0,25])
    rotate([-5,0,11]) cube([5,50,5], center=true);
    // and clear thumb string intrusion, too
    translate([15,-3,25]) cube(5, center=true);
}