inch=25.4*1; // hidden from customizer by equation, useful for pins
/* [Main setup] */
// size of hand relative to tiny 100% model
overall_scale=1.25; // [1.0:0.01:2.0]
// mirrored for right-hand?
mirrored=false; // [false:left, true:right]
// an identifying string for this hand, i.e. build date, builder, serial, etc. (15 characters/line max)
serial_line1="paraglider"; // 15
serial_line2="serial 1234"; // 15
serial_line3="2020-12-10"; // 15
// include a stamping die for thermoforming 0.5mm thick Igus bearing plastic for wrist
include_wrist_stamping_die=true; // [true: die included, false: no die]
/* [Structural parameters] */
// size of pivot pins
pivot_size=1.5875; // [1.5:metric 1.5, 1.5875:16th inch, 3.0:3mm screw]
// extra clearance for pivots to adjust for printer tolerances
pivot_extra_clearance=0; // [-0.5:0.01:0.5]
// drill holes for steel pins
pins=true; // [1:steel pins, 0: plastic pins]
// create plugs for steel pins, or leave old holes for plastic pins 
plugs=true; // [1:steel pins, 0: plastic pins]
// include fused-in palm mesh?
include_mesh=1; // [0:standard mesh, 1:simplified mesh]
// include nice covers for knuckles
include_knuckle_covers=true;
// set size of channels for strings
string_channel_scale=0.9; // [0.5:0.05:1.0]
// set size of channels for elastic
elastic_channel_scale=0.9; // [0.5:0.05:1.5]
// even if using steel pins on the fingers, use plastic pins on the wrist if old-style
old_style_wrist=false; // [true:old style, false:m3 wrist screws]
/* [Development] */
// make main object a ghost for debugging
main_ghost=false; // [1:ghost, 0:real]
// leave out string channels in preview, for much faster viewing
fast_preview=false;

use <segmented_pipe_tensor.scad>
module channel(waypoints, shapescale=1, bendradius=5, 
    fix_translation=true) {
    shape=[[-1.5,-0.7],[-1.2,-1],[1.2,-1],[1.5,-0.7],
        each 1.5*[for(th=[0:30:180]) [cos(th), sin(th)]]
    ]*shapescale;
    
    // insert 0 'phi' values, if only 3 coordinates were given
    // otherwise, copy 4'th coordinate to phi
    path=[for(w = waypoints) 
        [0,[w[0],w[1],w[2]],1,
            ((len(w)==4)?w[3]:0)]];
                
    // note: do a translation so that the curved _bottom_ of the pipe is
    // invariant under scaling, relative to its position when scale=0.9.
    // This is for historical continuity
    y_trans=fix_translation?1.5*(shapescale-0.9):0;
    translate([0,0,y_trans]) multi_pipe([shape], 
        smooth_bends(path, 2, bendradius),
        maximum_segment_length=3, untwist=true,
        accumulate_phi=true,
        initial_bend_perp = [0,0,-1]
        );
}
// channel([[0,0,0],[5,30,-2],[5,40,-5],[5,40,-20]]);

module do_supports() {
    children(); 
    for(dy=[-29:5:10]) translate([0,dy,0]) {
        translate([-7,0.5,21]) cube([52,2,0.5],  center=true);
        translate([-7,0,22]) cube([52,0.4,2],  center=true);
        // translate([-7,0,22]) cube([45,0.4,3],  center=true);
        translate([-7,0,23]) cube([45,0.4,3],  center=true);
        translate([-7,0,23]) cube([30,0.4,3],  center=true);
    }
}

module rounded_cutter(width=6, radius=1.5, height=20) {
    linear_extrude(height=height, center=false) 
    hull() {
        translate([0,-20]) square([width,1], center=true);
        translate([-width/2+radius,5]) 
            circle(r=radius, $fn=20);
        translate([ width/2-radius,5]) 
            circle(r=radius, $fn=20);
    }    
}

slot_dx=[[[10,0,0],0],[[-4,0,0],0],[[-18,-4,0],0],
    [[-32,-10,0],0]];

module plug_old_channels() {
    translate([-28.6,-49.5,22]) channel(
        [ [6.8,19,4.1], [4.2,40,3.5],[3.1, 47.5, 3.3],  [1.9,55,1.4], 
            [1.15, 62.5, 0],  [0.8,70, -4.7] ],
        shapescale=1.3, fix_translation=false
    );

    translate([-14.5,-43,24.5]) channel(
        [ [-0.5,13,3], [0,40,3.1], [0,55,1.4,2], 
        [0,63, -1.0], [0,67,-4] ],
        shapescale=1.3, fix_translation=false
    );

    translate([-0.3,-39,25.5]) channel(
        [ [-7.2,9,2.4], [-3.5,40,1.8], [-2.75, 47.5, 1.7],  
            [-2,55,1.0], 
            [-1,62.5,-0.7], [0,69, -3.5],  ],
        shapescale=1.2, fix_translation=false
    );    

    translate([13.5,-39,23.5]) channel(
        [ [-13.5,9,3.9], [-8.5,30,3.2], [-6.8,40,3.0], 
        [-5, 47.5, 2.7], [-3.5,55,0.5,-2], 
        [-2, 62, -0.9], [-0.4,69, -4.4], ],
        shapescale=1.3, fix_translation=false          
    );

    //thumb channel
    translate([21.2,-39,22]) channel(
        [ [-13.5,9.8,4], [-13.5,32,4.0], 
        [-10.5,35.5,3.7], [-6,37.3,2.5, -2],  [2,43,-3.5]  ],
        shapescale=1.2,  fix_translation=false          
    );
    // extra button to plug top of down-pipe
    translate([23,4,19.2]) rotate([-5,25,0]) scale([1,1,0.4]) sphere(d=6, $fn=20);
    // translate([24,4.5,17.75]) rotate([-5,20,0]) cylinder(d=4,h=3, $fn=20, center=true);
    
    // a kicker to deflect the string out of the thumb down tube
    cc = pin_coordinates[5][0];
    translate([cc[0],cc[1],0]) rotate(pin_coordinates[5][1]) rotate([0,-90,0]) 
        translate([1,13,0])
        intersection() {
            cylinder(d=4, h=10, $fn=8, center=false);
            translate([0,4,0]) rotate([45,0,0]) cube(15, center=true);
        }
    for(v=[[13.5,31,18], [-0.5,31.5,21.0], [-14.2,28,20],  [-28.5,22,18],
        
        ]) translate([v.x,v.y,0]) cylinder(d=4,h=v.z,$fn=20);
}

module final_bend(angle=90) {
    translate([0,-3.5,0]) rotate([90,0,90]) rotate_extrude(angle=angle, $fn=40, convexity=10)
        translate([5,0]) square([3,3], center=true);
}

module reborn_channels() {
    // pinkie string
    translate([-29.6,-48.5,21]) channel(
        [ [7.6,0,6], [3,40,3.5], [1.8,55,2.4], [1.0,70, -5] ],
        shapescale=string_channel_scale/overall_scale
    );
    // pinkie elastic
    translate([-26.6,-48.5,22]) channel(
        [ [7.5,0,5.4], [4.4,30,3.7], [3,45,2.8], 
        [1.8,55,1.5], [-1.0,70, -6] ],
        shapescale=elastic_channel_scale/overall_scale
    );
    // pinkie threading assist
    translate([-28,21,12.6]) final_bend(75);
    
    // ring elastic
    translate([-14.5,-43,24]) channel(
        [ [-1,0,2.7], [-1,40,3], [-1,58,1], [-0.5,71, -7]],
        shapescale=elastic_channel_scale/overall_scale
    );
    // ring string
    translate([-14.5,-43,24]) channel(
        [ [2,0,2.8], [2.5,38,3], [2,55,2], [0.5,71, -7]],
        shapescale=string_channel_scale/overall_scale
    );
    // ring threading assist
    translate([-14.5,27.5,14.25]) final_bend(65);
    
    // middle string
    translate([-0.3,-39,25.5]) channel(
        [ [-7,0,1.5], [-2,40,1.5], [-2.5,55,0], [-0.5,71, -7]],
        shapescale=string_channel_scale/overall_scale
    );  
    // middle elastic  
    translate([-0.3,-39,25.5]) channel(
        [ [-4,0,1.5], [2,40,1.3], [1,55,0], [0.5,71, -7]],
        shapescale=elastic_channel_scale/overall_scale
    );  
    // middle threading assist
    translate([-0.2,31.25,15.25]) final_bend(65);
    
    // index elastic  
    translate([13.5,-39,23.5]) channel(
        [ [-13.5,6,3.5], [-8.5,30,3.2], [-6.5,40,2.5], 
        [-4,55,0.5], [-0.5,71, -7.5]],
        shapescale=elastic_channel_scale/overall_scale
    );
    // index string
    translate([13.5,-39,23.5]) channel(
        [ [-10,6,3.5], [-5,30,3.2], [-3,40,2.5], 
        [-1,55,0], [0.5,71, -7.5]],
        shapescale=string_channel_scale/overall_scale
    );
    // index threading assist
    translate([13.6,30.5,13.25]) final_bend(65);
    
    //thumb plumbing
    // this may get crowded around the bend, so we make this channel smaller than the others
    // extra translation for v3 palm 
    translate([1,-5,0]) {
        translate([21.2,-39,22]) channel(
            [ [-13.5,8,4], [-10,25,3], [-7.0,34,2.0], 
            [19.2,2.2,20]-[21.2,-39,22]  ],
            shapescale=0.7*string_channel_scale/overall_scale
        );
        // keep the bottom of the toroidal bend at a fixed location
        // independent of azuimuth and arc angle and arc radius
        radius=10;
        translate([22,6,11]) rotate([90,0,55]) translate([-radius,0,0]) 
            rotate_extrude(angle=60, $fn=32) 
            translate([radius,0]) circle(d=2.2/overall_scale, $fn=8);
        translate([19.2,2.2,19.4]) sphere(d=2.8*string_channel_scale/overall_scale, $fn=12); // just to clean up joint
    }
    
}

// try a module to handle both plugging and drilling channels()
module do_channels() {
    difference() {
        union() {
            children();
            if(!main_ghost) translate([0,-2,0]) plug_old_channels();
            if(main_ghost) reborn_channels();
        }
        if(!(fast_preview && $preview) && !main_ghost) reborn_channels();
        translate([0,-32.8,30]) cube([100,5,20], center=true); // shave end
    }
}

module knuckles() {
    // re-insert clean finger stops
    for(dx=slot_dx) translate(dx[0]+[3.7,38.5,12.5]) 
        rotate([90,0,-90+dx[1]]) linear_extrude(height=8, center=true)
            hull() {
                translate([3,0]) square([0.1,3]);
                translate([0,0.5]) circle(1, $fn=10);
            };
    // smooth covers for knuckles
    // compute individul offsets to place them nicely
    cover_dx=[
        [[-1,-4,-2.5],[-113,0,-3],3],
        [[0,-2,0],[-120,0,0],2],
        [[1,-3,-1],[-115,0,3],2],
        [[1,-4,-2.35],[-113,0,3],3]
    ];
                
    if(include_knuckle_covers) for(idx=[0:3]) 
        translate(cover_dx[idx][0]+slot_dx[idx][0]+[3.7,25,23]) {
        intersection() {
            rotate(cover_dx[idx][1]) difference() {
                hull() {
                    scale([1,0.5,1]) cylinder(d=10, h=0.1, $fn=20);
                    translate([0,0,19]) cylinder(d=10,h=0.1, $fn=20);
                }
                hull() {
                    translate([0,0,-1]) scale([1,0.5,1]) cylinder(d=8, h=0.1, $fn=6);
                    translate([0,0,21]) cylinder(d=8,h=0.1, $fn=6);
                }
                translate([0,10,-1]) cube([20,20,50], center=true);
            }
            translate([0,cover_dx[idx][2],0]) cube([15,30,20], center=true);
        }
    }
}

module mesh_cutout() {
    translate([-19.6,50.5,2.17]) union() { // chop out old mesh
        translate([12,-65,0]) cube([50,50,5], center=true);
        translate([17,-42,0]) scale([1,0.8,1]) cylinder(d=40, h=5, center=true);
        translate([-2,-42,0]) cylinder(d=20, h=5, center=true);
        translate([25,-32,0]) rotate(-20) scale([1,0.6,1]) 
            cylinder(d=25, h=5, center=true);        
    } 
}

module do_mesh() {
    if(include_mesh==1) 
        union() {
            difference() {
                children();
                mesh_cutout();
            }
            mesh();
        }
    else children();
}

// plug up all holes and slots which need to be parametric
module chamfered_cylinder(d=20, h=20, center=true)
{
    union() {
        cylinder(d=d, h=h-1, center=true);
        translate([0,0,h/2-.51]) cylinder(d1=d, d2=d-1, h=0.5);
        translate([0,0,-h/2+0.01]) cylinder(d1=d-1, d2=d, h=0.5);
    }
}

pin_coordinates=[
    [[-35.6,-38,8],[0,90,0]], //left wrist
    [[20.9,-38,8],,[0,90,0]], // right wrist
    [[6.6,39.5,6.0],[0,90,0]], // index and middle finger
    [[-16,35.5,6.0],[0,90,0]], // ring finger
    [[-29.5,29.5,6.0],[0,90,0]], // pinky
    [[32.2,-5.9,5.6],[0,90,50]], // thumb

];

module plugs(size_scale=1, chop=false) {
    chopper=[13,13,30];
    
    // index and middle combined pin
    translate(pin_coordinates[2][0]) rotate(pin_coordinates[2][1]) 
        scale(size_scale) intersection() {
            chamfered_cylinder(d=8,h=27.5, center=true, $fn=16);
            if(chop) translate([6,6,0]) rotate(45) cube(chopper, center=true);
        }
    // ring pin
    translate(pin_coordinates[3][0]) rotate(pin_coordinates[3][1]) 
        scale(size_scale) intersection() {
            chamfered_cylinder(d=11,h=11, center=true, $fn=16);
            if(chop) translate([6,6,0]) rotate(45) cube(chopper, center=true);
        }
    // pinky pin
    translate(pin_coordinates[4][0]) rotate(pin_coordinates[4][1]) 
        scale(size_scale) intersection() {
            chamfered_cylinder(d=11,h=11.5, center=true, $fn=16);
            if(chop) translate([6,6,0]) rotate(45) cube(chopper, center=true);
        }
    // thumb pin
    translate(pin_coordinates[5][0]) rotate(pin_coordinates[5][1]) 
        scale(size_scale) intersection() {
            chamfered_cylinder(d=11,h=16, center=true, $fn=16);
            if(chop) rotate(-45) translate([6,6,0]) cube(chopper, center=true);
        }
 }

module m3_wrist_plug() {
    rotate([0,90,0]) cylinder(d=10,h=4.99, center=true);            
}

module m3_wrist_drill() {
    rotate([0,90,0]) {
        cylinder(d=3.5/overall_scale,h=20, center=true, $fn=20);
        translate([0,0,-(4.99-2/overall_scale)/2-0.1]) 
            rotate(30) cylinder(d=5.6/cos(30)/overall_scale, h=2/overall_scale, 
                center=true, $fn=6);
        translate([0,0,(4.99-2)/2+0.2])
            cylinder(d1=8, d2=10, h=2, center=true, $fn=50);
    }
}

module do_wrist() {
    if(!old_style_wrist) 
        difference() {
            union() {
                children();                
                translate(pin_coordinates[0][0]) m3_wrist_plug();
                translate(pin_coordinates[1][0]) scale([-1,1,1]) m3_wrist_plug();
            }
            translate(pin_coordinates[0][0]) m3_wrist_drill();
            translate(pin_coordinates[1][0]) scale([-1,1,1]) m3_wrist_drill();
            translate((pin_coordinates[0][0]+pin_coordinates[1][0])/2)
                rotate([0,90,0]) cylinder(h=52, d=17.5, center=true, $fn=16);
    } else children();
}

module mesh(mesh_thickness=2) {
    holes=[ // plug all screw holes
            [8.7,62.6], [7.7,51.7], [6.5,40.6], [6.9,28.4],
            [10.1,19.4], [22.7,13], [36.6,7.4], [50.6,6.1], [62.5,10], 
            [65.6, 17.3], [66.5,26.6], [66.0,47.4], [64.7, 60.2], 
        ];
    
    // convenient aliases
    m2=mesh_thickness/2;
    m4=mesh_thickness/4;
    m1=mesh_thickness;
    
    for(dy=[-30:10:20]) translate([-7,dy,(dy==-30)?m2:m4])
        cube([60,5,(dy==-30)?m1:m2], center=true);
    for(dx=[-20:10:20]) translate([-7+dx,-1,3*m4])
        cube([5,62,m2], center=true);

    translate([-43.6,37.1,0]) scale([1,-1,1]) // flip chirality 
        for(xy=holes) translate([each xy, 0.001]) cylinder(d=3.5, h=13, $fn=16);
}

module drilling(palm_scale, 
    pin_dia, pin23_length, pin45_length, pin_1_length,
    pin_head_square, pins=true)
// drill out everything that needs to be done to attach fingers and wrist pins
// with proper scaling for pins and slots
// this is where all the parmetric processes happen.  
// they are done by inverse-scaling objects by the hand scale, so when the whole object is scaled,
// they come out the expected size.
// this assumes the 1x-scaled finger has a slot width of 6 mm
{
    finger_scale=palm_scale;
    base_slot_width=6;
    base_rotation_offset=6; // distance of nominal pin center from front of hand, half of cylinder diameter of 12 mm
    // cut out finger slots
    for(dx=slot_dx) translate(dx[0]+[3.7,43,-10]) 
        rotate(dx[1]+180) translate([0,5,5]) 
            rounded_cutter(width=base_slot_width*finger_scale/palm_scale, height=40);
    // make holes for pins
    center_offset=[0, base_rotation_offset*(palm_scale/finger_scale-1), 0];
    if(pins) {
    translate(pin_coordinates[2][0]+center_offset) rotate(pin_coordinates[2][1]) 
        cylinder(d=pin_dia, h=30, $fn=20, center=true);
    translate(pin_coordinates[3][0]+center_offset) rotate(pin_coordinates[3][1]) 
        cylinder(d=pin_dia, h=15, $fn=20, center=true);
    translate(pin_coordinates[4][0]+center_offset) rotate(pin_coordinates[4][1]) 
        cylinder(d=pin_dia, h=15, $fn=20, center=true);    
    translate(pin_coordinates[5][0]+center_offset) rotate(pin_coordinates[5][1]) 
        cylinder(d=pin_dia, h=17, $fn=20, center=true);
    }
    // block to mill out old rubber-band attachment for thumb
    translate([30,-5,-5]) rotate(49.5) {
        translate([0.55,-6,0]) 
        rounded_cutter(width=base_slot_width*finger_scale/palm_scale, height=30);
        translate([0.55,-4,8]) cube([6,20,20], center=true);
    }
}

module do_pins() {
    difference() {
        union() {
            children();
            plugs();
        }
        drilling(
            palm_scale=overall_scale, 
            pin_dia=pivot_size/overall_scale, pin23_length=25, pin45_length=10, 
            pin_1_length=15
        );
    }
}

module do_knuckles() {
    union() {
        children();
        knuckles(); // insert backstops and knuckle cover
        // add cylindrical pin for thumb
        translate(pin_coordinates[5][0]+[0,0,7]) 
        rotate(pin_coordinates[5][1]) 
        translate([-1,-2,0]) cylinder(d=4, h=8, center=true, $fn=20);
    }
}

module do_labels() {
    textscale=[mirrored?-1:1,1];
    difference() {
        children();
        translate([21.2, 3, 6]) rotate([90,0,-90])
            linear_extrude(slices=1, height=1) scale(textscale) 
            text(str(overall_scale*100), size=4, halign="center");
        translate([-35.5,-19,2.001]) hull() { // flat plate for text
            cube([0.1,30,12]);
            translate([5,-4,0]) cube([3,38,14]);
        }
        translate([-36.5, -4, 11]) rotate([90,0,90])
            linear_extrude(slices=1, height=1.5) scale(textscale) intersection() {
                group() {
                    text(serial_line1, size=3.5, halign="center");
                    translate([0,-4])text(serial_line2, size=3.5, halign="center");
                    translate([0,-8])text(serial_line3, size=3.5, halign="center");
                }
                translate([0,-3]) square([29,12], center=true);
            }
    }
}

act_scale=[mirrored?-overall_scale:overall_scale, overall_scale, overall_scale];
// collect everything together as concatenated functional operators
module scaled_palm() 
{
    scale(act_scale)
    do_labels() 
    do_wrist() 
    do_knuckles()
    do_pins() 
    do_mesh() 
    do_channels() 
    do_supports()
    translate([-19.6,50.5,2.17]) 
    if(!main_ghost) 
        import("palm_v3.3mf", convexity=10);      
    else
        %import("palm_v3.3mf", convexity=10);
}

scaled_palm();

if(include_wrist_stamping_die) scale(overall_scale) {  $fn=50; 
    translate(mirrored?[20,-50,4.99/2]:[5,-50,4.99/2]) difference() {
        rotate([0,-90,0]) difference() {
            scale([1,2.5,2.5]) m3_wrist_plug();
            intersection() {
                    m3_wrist_drill();
                    translate([5,0,0]) cube([10,20,20], center=true);
                }
            }
        cylinder(d=3.6/overall_scale, h=50, center=true, $fn=20);  // drilling guide hole
    }       
    translate(mirrored?[-6,-50,4.99/2]:[-21,-50,4.99/2]) difference() {
        rotate([0,90,0]) union() {
            scale([1,2.5,2.5]) m3_wrist_plug();
            translate([-5.1+0.5,0,0]) intersection() {
                m3_wrist_drill();
                translate([2.5,0,0]) cube([4,20,20], center=true);
            }
        }
        cylinder(d=3.6/overall_scale, h=50, center=true, $fn=20); // drilling guide hole
        translate([0,3,-4.99/2-0.01]) linear_extrude(slices=1, height=0.5) 
            scale([-1,1]) text(str(overall_scale*100), size=4, halign="center");
    }
}
