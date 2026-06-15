// ===== namespaced bundle: /tmp/v3_combined.scad (prefix V3_) =====
// (library) ===== namespaced bundle: paraglider/pipe.scad (prefix ) =====
// take a polygonal cross section, defined by the set of 2d points polygon_points,
// and extrude it along the path [ [xyz0, size0, phi0], [xyz1, size1, phi1], ...]
// where the phi values are extra rotations the user can inset  to untwist the connections 
// the polygon must be defined counterclockwise.
// If you are describing a circle or helix, the positive 'y' of the polygon
// will point to the outside.  Useful for threading.

// Written by Marcus H. Mendenhall, May 27, 2020

// pipe is just a simplified call to multi_pipe.
// It wraps the polygon_points in a deeper list 
// and adds the polygon index 0 to all the path_points
module V3_pipe(polygon_points, path_points, 
    V3_join_ends=false, untwist=true, V3_triangularize_ends=true)
{
    V3_multi_pipe(
        [polygon_points],
        [for(xx=path_points) [0, each xx]],
        V3_join_ends=V3_join_ends, untwist=untwist,
        V3_triangularize_ends=V3_triangularize_ends
    );
}


// simple_pipe has no scale-per-step or phi-per-step
// it just takes a polygon and a list of xyz
module V3_simple_pipe(polygon_points, path_points, V3_join_ends=false,
    V3_triangularize_ends=true)
{
    V3_multi_pipe(
        [polygon_points],
        [for(xx=path_points) [0, xx, 1, 0]],
        V3_join_ends=V3_join_ends, 
        V3_triangularize_ends=V3_triangularize_ends
    );
}

// return caz and saz, remembering old values near singularities,
// by running backwards from the singularity to a good value
function V3_preen(transforms, idx) = (
    (idx==0 && is_undef(transforms[idx][1])) ? 
        [1, 0] : // first point is singular, use default rotation
        is_undef(transforms[idx][1]) ?
            V3_preen(transforms, idx-1) : // point is singular, walk back
            [transforms[idx][1], transforms[idx][2]] // point is good
    );

// polygon_point_sets is a list of polygons,
// all of which must have the same number of sides, 
// and path_points is [ [poly_select, xyz, scale, phi], ...]
// if join_ends is true, the two ends are stitched together
// instead of being capped with flat caps.
// if untwist is true, it attempts to remove the azimuthal
// rotation from the phi rotation, resulting in straighter pipes.
// this tends to break threading, and some other things.
module V3_multi_pipe(polygon_point_sets, path_points, 
    V3_join_ends=false, untwist=true,
    V3_triangularize_ends=true)
{
    V3_np=len(path_points);
    connections=[];
    psel=[for(x=path_points) x[0] ];
    V3_xyz =[for(x=path_points) x[1] ];
    V3_scl =[for(x=path_points) x[2] ];
    V3_phi =[for(x=path_points) x[3] ];
    
    // make 3d points from 2d polygons for full rotations
    v3=[for(V3_pp=polygon_point_sets) [for(v=V3_pp) [v.x,v.y,0]]]; 
        
    // have to do whole cal in a list comprehension,
    // since openscad can't append to a list...
    transforms=[for(i=[0:V3_np-1]) let(
        // the normal for a joint is parallel to the line connecting
        // the two points adjacent to the joint,
        // except for the end caps, 
        // which are cut perpendicular to the terminal line
        V3_x2=V3_xyz[min(i+1,V3_np-1)],
        V3_x1=V3_xyz[i],
        V3_x0=V3_xyz[max(i-1,0)], 
        V3_dx21=V3_x2-V3_x1,
        V3_dx10=V3_x1-V3_x0,
        V3_dx20=V3_x2-V3_x0,
        V3_u= V3_dx20/norm(V3_dx20), // unit vector norm to joint plane
        rho=norm([V3_u.x, V3_u.y]), // cylindrical sine, cos is just z
        mat1=[[V3_u.z,0,rho],[0,1,0],[-rho,0,V3_u.z]], // euler polar rot
        // check for very close to the 'z' axis before computing azimuthal matrix
        caz=(rho > 1e-6)?(V3_u.x/rho):undef,
        saz=(rho > 1e-6)?(V3_u.y/rho):undef 
        ) 
        //[pts, caz, saz, xyz[i]] // transform info
        [v3[psel[i]]*V3_scl[i], caz, saz, mat1, V3_phi[i], V3_u.z, V3_xyz[i] ]
    ];
    // now, preen the azimuthal rotations
    // to avoid singularities along the 'z' axis
    // note that preening can be as bad as an n^2 operation,
    // if the entire object is along the 'z' axis.
    // better to lay things out along 'x', and then rotate afterwards.
    vertices=[for(i=[0:len(transforms)-1])
        let (
            xfrm=transforms[i],
            V3_vv=xfrm[0],
            mat1=xfrm[3],
            V3_phi=xfrm[4],
            cth=xfrm[5], 
            V3_x0=xfrm[6], 
            az=V3_preen(transforms, i),
            caz=az[0], saz=az[1],
            mat2=[[caz, -saz,0],[saz, caz, 0],[0,0,1]], // azimuth
            p=V3_phi-(untwist?cth*atan2(saz,caz):0), // untwisted from azimuth
            phimat=[[cos(p), -sin(p),0],[sin(p), cos(p),0],[0,0,1]],
            pts=[for(x=V3_vv) mat2*mat1*phimat*x + V3_x0] // fixed azimuthal xfrm
        )
        each pts
    ];
    // now have to build connection triangles
    // no geometry here, just counting
    // could let OpenSCAD automatically split quads, 
    // rather than create triangles,
    // but just do it explicitly here.
    nn=len(polygon_point_sets[0]);
    t1=[for (j=[0:V3_np-2]) for(i=[0:nn-1]) 
        let(b=j*nn, bp1=(j+1)*nn, ip1=(i+1) % nn) 
        each [
            [b+ip1, b+i, bp1+i], //bottom triangles
            [bp1+i,  bp1+ip1, b+ip1], // top triangles
        ]
    ];
    
    //create triangularized end caps (works for convex polys)
    // find bounding boxes for both ends
    pl0=[for(i=[0:nn-1]) vertices[i]]; // first transformed polygon
    pl1=[for(i=[0:nn-1]) vertices[(V3_np-1)*nn+i]]; // last transformed polygon
    
    bboxx0=(min([for(aa=pl0) aa.x])+max([for(aa=pl0) aa.x]))/2;
    bboxy0=(min([for(aa=pl0) aa.y])+max([for(aa=pl0) aa.y]))/2;
    bboxz0=(min([for(aa=pl0) aa.z])+max([for(aa=pl0) aa.z]))/2;
    bboxx1=(min([for(aa=pl1) aa.x])+max([for(aa=pl1) aa.x]))/2;
    bboxy1=(min([for(aa=pl1) aa.y])+max([for(aa=pl1) aa.y]))/2;
    bboxz1=(min([for(aa=pl1) aa.z])+max([for(aa=pl1) aa.z]))/2;

    extra_verts_tri_caps=[
        [bboxx0, bboxy0, bboxz0],
        [bboxx1, bboxy1, bboxz1]
    ];
    
    tri_caps=[
        each [for(i=[0:nn-2]) [i,i+1,V3_np*nn]], 
        [nn-1,0,V3_np*nn],
        each [for(i=[V3_np*nn-2:-1:(V3_np-1)*nn]) [i+1,i,V3_np*nn+1]],
        [(V3_np-1)*nn, V3_np*nn-1, V3_np*nn+1]
    ];
    
    // simple end caps (not triangularized)
    plain_caps=[[for(i=[0:nn-1]) i],  [for(i=[V3_np*nn-1:-1:(V3_np-1)*nn]) i]];
    extra_verts_plain_caps=[];
    
    caps=V3_triangularize_ends?tri_caps:plain_caps;
    extra_verts_cap=V3_triangularize_ends?extra_verts_tri_caps:extra_verts_plain_caps;
    
    // create end join
    join=[for(i=[0:nn-1])
        let(b=(V3_np-1)*nn, bp1=0, ip1=(i+1) % nn) 
        each [
            [b+ip1, b+i, bp1+i], //bottom triangles
            [bp1+i,  bp1+ip1, b+ip1], // top triangles
        ]
    ];
    extra_verts_join=[];
    
    allverts=[each vertices, each (V3_join_ends?extra_verts_join:extra_verts_cap)];
    
    V3_t2=[each t1, each (V3_join_ends?join:caps)];
    
    polyhedron(points=allverts, faces=V3_t2, convexity=10);
}

// take a set of path_points, and if a bend is more than the specified 
// max_bend limit,  break it down into bends less than that,
// and interpolate everything except the polygon index
function V3_smooth_bends(path_points, max_bend, bend_radius) = (
  let (
    V3_np=len(path_points),
    V3_multi=!is_list(path_points[0][0]), // check for poly index
    V3_xyzidx=V3_multi?1:0,
    V3_xyz=[for(xx=path_points) xx[V3_xyzidx]], // extract coordinates
    V3_scl=[for(xx=path_points) xx[V3_xyzidx+1]], // extract scales
    V3_phi=[for(xx=path_points) xx[V3_xyzidx+2]], // extract rotations
    V3_verts=[for(i=[1:V3_np-2]) let(
        V3_x2=V3_xyz[i+1],
        V3_x1=V3_xyz[i],
        V3_x0=V3_xyz[i-1], 
        V3_dx21=V3_x2-V3_x1,
        V3_dx10=V3_x1-V3_x0,
        V3_dx20=V3_x2-V3_x0,
        V3_u= V3_dx20/norm(V3_dx20), // unit vector norm to joint plane
        V3_bendcross=cross(V3_dx21, V3_dx10)/(norm(V3_dx21)*norm(V3_dx10)),
        V3_bend=asin(norm(V3_bendcross)), // the sine of the bend angle
        V3_nbend=floor(1+V3_bend/max_bend)
    ) if (V3_bend < max_bend) path_points[i] else each [ 
        for(j=[0:V3_nbend]) let (
            V3_t=j/V3_nbend,
            // how far away to start the bend
            // avoiding collisions with smoothing from 
            // the other end of each segment
            V3_backoff=min(bend_radius*V3_bend*3.14/180, norm(V3_dx21)/2.5, norm(V3_dx10)/2.5),
            // knots for cubic spline, middle knot used twice
            V3_p0=V3_x1-V3_backoff*V3_dx10/norm(V3_dx10),
            V3_p12=V3_x1,
            V3_p3=V3_x1+V3_backoff*V3_dx21/norm(V3_dx21),
// swiped from some of my old python code 
//        spline=lambda t: vec_scale_sum(vec_scale_sum(vec_scale_sum(vec_scale_sum((0.,0.),
//           p0, (1-t)**3),  p1, 3*(1-t)**2*t),  p2, 3*(1-t)*t**2),  p3, t**3)
           V3_s=1-V3_t,
           V3_s2=V3_s*V3_s,
           V3_s3=V3_s2*V3_s,
           V3_t2=V3_t*V3_t,
           V3_t3=V3_t2*V3_t,
           V3_vv=V3_p0*V3_s3+3*V3_p12*V3_s*V3_t+V3_p3*V3_t3,
           V3_ss=V3_scl[i-1]*V3_s3+3*V3_scl[i]*V3_s*V3_t+V3_scl[i+1]*V3_t3,
           V3_pp=V3_phi[i-1]*V3_s3+3*V3_phi[i]*V3_s*V3_t+V3_phi[i+1]*V3_t3
        )
        // put back polygon index if it was there
        [each V3_multi?path_points[i][0]:[], each [V3_vv, V3_ss, V3_pp]]
      ]
    ]
  )
  [path_points[0], each V3_verts, path_points[V3_np-1]]
);

module V3_tests() {
    // demonstrate a lumpy pipe
    V3_pipe([for(th=[0:30:359]) [cos(th), sin(th)]],
        [for(th=[0:5:719]) 
            [[10*cos(th), 10*sin(th), 0.02*th], 
                (1-0.0005*th)*(1+0.5*cos(th*2)), 0]
        ], untwist=false, V3_triangularize_ends=false
      );
     
    // demonstrate lumpy torus
    translate([-20,-20,0]) V3_pipe([for(th=[0:30:359]) [cos(th), sin(th)]],
        [for(th=[0:5:359]) 
            [[10*cos(th), 10*sin(th), 0], 1+0.5*cos(6*th), 0]
        ], V3_join_ends=true
      );


    // a lumpy pipe hollowed out of a cube, 
    // with sections appended to the ends to penetrate the sides of the cube
    translate([0,50,0]) difference() {
        translate([0,0,8]) cube([24,24,20], center=true);
        V3_pipe([for(th=[0:10:359]) [cos(th), sin(th)]],
        [[[10,-4,-5],1,0], each [for(th=[0:10:720]) [[10*cos(th), 10*sin(th), 0.02*th], (1-0.0005*th)*(1+0.5*cos(th*2)), 0]], [[10,4,20],0.4,0]]
      );
    }

    // demonstrate a pipe with alternating polygons
    translate([24,0,0]) V3_multi_pipe(
        [ [ [1,1],[-1,1],[-1,-1],[1,-1] ],
          [ [1.,0],[0,1.],[-1.,0],[0,-1.] ] ],
        [for(th=[0:5:720]) 
            [(th/5) % 2, [10*cos(th), 10*sin(th), 0.02*th], 
                (1-0.0005*th)*(1+0.5*cos(th*2)), 0]
        ]
    );
        
    // a square-circle adapter
    n_sq_circ_steps=24; //must be a divisor of 360!
    side_steps=[0:n_sq_circ_steps/4-1]; // counter for sides of square
    side_pos=[for(i=side_steps) 8*i/n_sq_circ_steps]; 
        
    translate([0,24,0]) V3_multi_pipe(
        [ 
            [for(th=[0:360/n_sq_circ_steps:359]) 
                [cos(th+45), sin(th+45)]
            ],
            [
               each [for(i=side_steps) [ 1-side_pos[i], 1] ],
               each [for(i=side_steps) [-1, 1-side_pos[i]] ],
               each [for(i=side_steps) [ side_pos[i]-1,-1] ],
               each [for(i=side_steps) [ 1, side_pos[i]-1] ]
            ]
        ],
        [ [0,[0,0,0],10,0], [1,[0,0,20],10,0], [0,[0,0,40],5,0] ]
    );

    // test azimuthal preening and smoothed bends
    straw=[ 
       [0,[0,0,0],1,0], [0,[10,5,0],1,0],
       [0, [15,10,5], 1, 0], [0,[15,10,10], 1, 0], 
       [0,[15,10,15], 1, 0], [0, [20,20,25],1, 0]
    ];       
    translate([20,20,0]) V3_multi_pipe(
        [ [for(th=[0:90:359]) [cos(th), sin(th)]]],
        V3_smooth_bends(straw, 5, 3), untwist=true
    );
    translate([20,25,0]) V3_multi_pipe(
        [ [for(th=[0:90:359]) [cos(th), sin(th)]]],
        straw, untwist=true
    );
}

V3_inch=25.4*1; // hidden from customizer by equation, useful for pins

// size of hand relative to tiny 100% model
// --- Anthropometric sizing (added for the parametric-prosthetic-hand-generator) ---
// Knuckle-to-knuckle metacarpal palm breadth (mm). Drives overall_scale; the unscaled
// Paraglider Unlimbited v3 palm spans REF_PALM_BREADTH mm at scale 1.0. Use the same value across the
// matching palm, fingers, tensioner box and gauntlet for a fitting set.
// [dispatcher-driven] palm_breadth_mm
// Manual scale-factor override (x). 0 = derive automatically from palm_breadth_mm.
V3_scale_override = 0; // [0:0.01:2.0]
// Palm breadth (mm) of the unscaled (scale 1.0) Paraglider Unlimbited v3 palm.
V3_REF_PALM_BREADTH = 82.8;
// derived hand scale, clamped to the printable 1.0-2.0x range
// [dispatcher-driven] overall_scale
// mirrored for right-hand?
// [dispatcher-driven] mirrored
// an identifying string for this hand, i.e. build date, builder, serial, etc. (15 characters/line max)
V3_serial_line1="paraglider"; // 15
V3_serial_line2="serial 1234"; // 15
V3_serial_line3="2020-12-10"; // 15
// include a stamping die for thermoforming 0.5mm thick Igus bearing plastic for wrist
// [dispatcher-driven] include_wrist_stamping_die

// size of pivot pins
V3_pivot_size=1.5875; // [1.5:metric 1.5, 1.5875:16th inch, 3.0:3mm screw]
// extra clearance for pivots to adjust for printer tolerances
V3_pivot_extra_clearance=0; // [-0.5:0.01:0.5]
// drill holes for steel pins
V3_pins=true; // [1:steel pins, 0: plastic pins]
// create plugs for steel pins, or leave old holes for plastic pins 
V3_plugs=true; // [1:steel pins, 0: plastic pins]
// include fused-in palm mesh?
// [dispatcher-driven] include_mesh
// include nice covers for knuckles
// [dispatcher-driven] include_knuckle_covers
// set size of channels for strings
V3_string_channel_scale=0.9; // [0.5:0.05:1.0]
// set size of channels for elastic
V3_elastic_channel_scale=0.9; // [0.5:0.05:1.5]
// even if using steel pins on the fingers, use plastic pins on the wrist if old-style
V3_old_style_wrist=false; // [true:old style, false:m3 wrist screws]

// make main object a ghost for debugging
V3_main_ghost=false; // [1:ghost, 0:real]
// leave out string channels in preview, for much faster viewing
V3_fast_preview=false;

module V3_channel(waypoints, shapescale=1, bendradius=5,
    V3_fix_translation=true) {
    // the bends work best if the primary length is along 'x' here,
    // but the hand is along 'y', 
    // so we will adjust the coordinates, 
    // and then re-rotate the whole thing
    shape=[[-1.5,-1],[1.5,-1],
        each 1.5*[for(th=[0:30:179]) [cos(th), sin(th)]]
    ]*shapescale;
    path=[for(w = waypoints) 
        [0,[w[1],-w[0],w[2]],1,
            -90+((len(w)==4)?w[3]:0)]];
    // note: do a translation so that the curved _bottom_ of the pipe is
    // invariant under scaling, relative to its position when scale=0.9.
    // This is for historical continuity
    y_trans=V3_fix_translation?1.5*(shapescale-0.9):0;
    translate([0,0,y_trans]) rotate(90) V3_multi_pipe([shape], V3_smooth_bends(path, 2, bendradius));
}

// channel([[0,0,0],[5,30,-2],[5,40,-5],[5,40,-20]]);

module V3_do_supports() {
    children(); 
    for(dy=[-29:5:10]) translate([0,dy,0]) {
        translate([-7,0.5,21]) cube([52,2,0.5],  center=true);
        translate([-7,0,22]) cube([52,0.4,2],  center=true);
        // translate([-7,0,22]) cube([45,0.4,3],  center=true);
        translate([-7,0,23]) cube([45,0.4,3],  center=true);
        translate([-7,0,23]) cube([30,0.4,3],  center=true);
    }
}

module V3_rounded_cutter(width=6, radius=1.5, height=20) {
    linear_extrude(height=height, center=false) 
    hull() {
        translate([0,-20]) square([width,1], center=true);
        translate([-width/2+radius,5]) 
            circle(r=radius, $fn=20);
        translate([ width/2-radius,5]) 
            circle(r=radius, $fn=20);
    }    
}

V3_slot_dx=[[[10,0,0],0],[[-4,0,0],0],[[-18,-4,0],0],
    [[-32,-10,0],0]];

module V3_plug_old_channels() {
    translate([-28.6,-49.5,22]) V3_channel(
        [ [6.8,19,4.1], [4.2,40,3.5],[3.1, 47.5, 3.3],  [1.9,55,1.4], 
            [1.15, 62.5, 0],  [0.8,70, -4.7], ],
        shapescale=1.3, V3_fix_translation=false
    );

    translate([-14.5,-43,24.5]) V3_channel(
        [ [-0.5,13,3], [0,40,3.1], [0,55,1.4], [0,63, -1.0,-15], [0,67,-4,-15] ],
        shapescale=1.3, V3_fix_translation=false
    );

    translate([-0.3,-39,25.5]) V3_channel(
        [ [-7.2,9,2.4], [-3.5,40,1.8], [-2.75, 47.5, 1.7],  [-2,55,1.0], 
            [-1,62.5,-0.7], [0,69, -3.5],  ],
        shapescale=1.2, V3_fix_translation=false
    );    

    translate([13.5,-39,23.5]) V3_channel(
        [ [-13.5,9,3.9], [-8.5,30,3.2], [-6.8,40,3.0], [-5, 47.5, 2.7], [-3.5,55,1.0,5], 
        [-2, 62, -0.9, 15], [-0.4,69, -4.4,20], ],
        shapescale=1.3, V3_fix_translation=false          
    );

    //thumb channel
    translate([21.2,-39,22]) V3_channel(
        [ [-13.5,9.8,4], [-13.5,32,4.0,10], [-10.5,35.5,3.7,25], [-6,37.3,2.5,30],  [2,43,-3.5,50]  ],
        shapescale=1.3,  V3_fix_translation=false          
    );
    // extra button to plug top of down-pipe
    translate([23,4,19.2]) rotate([-5,25,0]) scale([1,1,0.4]) sphere(d=6, $fn=20);
    // translate([24,4.5,17.75]) rotate([-5,20,0]) cylinder(d=4,h=3, $fn=20, center=true);
    
    // a kicker to deflect the string out of the thumb down tube
    cc = V3_pin_coordinates[5][0];
    translate([cc[0],cc[1],0]) rotate(V3_pin_coordinates[5][1]) rotate([0,-90,0]) 
        translate([1,13,0])
        intersection() {
            cylinder(d=4, h=10, $fn=8, center=false);
            translate([0,4,0]) rotate([45,0,0]) cube(15, center=true);
        }
    for(v=[[13.5,31,18], [-0.5,31.5,21.0], [-14.2,28,20],  [-28.5,22,18],
        
        ]) translate([v.x,v.y,0]) cylinder(d=4,h=v.z,$fn=20);
}

module V3_final_bend(angle=90) {
    translate([0,-3.5,0]) rotate([90,0,90]) rotate_extrude(angle=angle, $fn=40, convexity=10)
        translate([5,0]) square([3,3], center=true);
}

module V3_reborn_channels() {
    // pinkie string
    translate([-29.6,-48.5,21]) V3_channel(
        [ [7.6,0,6], [3,40,3.5], [1.8,55,2.4], [1.0,70, -5] ],
        shapescale=V3_string_channel_scale/V3_overall_scale
    );
    // pinkie elastic
    translate([-26.6,-48.5,22]) V3_channel(
        [ [7.5,0,5.4], [4.4,30,3.7], [3,45,2.8], [1.8,55,1.5], [-1.0,70, -6] ],
        shapescale=V3_elastic_channel_scale/V3_overall_scale
    );
    // pinkie threading assist
    translate([-28,21,12.6]) V3_final_bend(75);
    // ring elastic
    translate([-14.5,-43,24]) V3_channel(
        [ [-1,0,2.7], [-1,40,3], [-1,58,1], [-0.5,71, -7]],
        shapescale=V3_elastic_channel_scale/V3_overall_scale
    );
    // ring string
    translate([-14.5,-43,24]) V3_channel(
        [ [2,0,2.8], [2.5,38,3], [2,55,2], [0.5,71, -7]],
        shapescale=V3_string_channel_scale/V3_overall_scale
    );
    // ring threading assist
    translate([-14.5,27.5,14.25]) V3_final_bend(65);
    // middle string
    translate([-0.3,-39,25.5]) V3_channel(
        [ [-7,0,1.5], [-2,40,1.5], [-2.5,55,0], [-0.5,71, -7]],
        shapescale=V3_string_channel_scale/V3_overall_scale
    );  
    // middle elastic  
    translate([-0.3,-39,25.5]) V3_channel(
        [ [-4,0,1.5], [2,40,1.3], [1,55,0], [0.5,71, -7]],
        shapescale=V3_elastic_channel_scale/V3_overall_scale
    );  
    // middle threading assist
    translate([-0.2,31.25,15.25]) V3_final_bend(65);
    // index elastic  
    translate([13.5,-39,23.5]) V3_channel(
        [ [-13.5,6,3.5], [-8.5,30,3.2], [-6.5,40,2.5], [-4,55,0.5], [-0.5,71, -7.5]],
        shapescale=V3_elastic_channel_scale/V3_overall_scale
    );
    // index string
    translate([13.5,-39,23.5]) V3_channel(
        [ [-10,6,3.5], [-5,30,3.2], [-3,40,2.5], [-1,55,0], [0.5,71, -7.5]],
        shapescale=V3_string_channel_scale/V3_overall_scale
    );
    // index threading assist
    translate([13.6,30.5,13.25]) V3_final_bend(65);
    //thumb plumbing
    // this may get crowded around the bend, so we make this channel smaller than the others
    // extra translation for v3 palm 
    translate([1,-5,0]) {
        translate([21.2,-39,22]) V3_channel(
            [ [-13.5,8,4], [-10,25,3], [-7.0,34,2.0], [19.2,2.2,20]-[21.2,-39,22]  ],
            shapescale=0.7*V3_string_channel_scale/V3_overall_scale
        );
        // keep the bottom of the toroidal bend at a fixed location
        // independent of azuimuth and arc angle and arc radius
        radius=10;
        translate([22,6,11]) rotate([90,0,55]) translate([-radius,0,0]) 
            rotate_extrude(angle=60, $fn=32) 
            translate([radius,0]) circle(d=2.2/V3_overall_scale, $fn=8);
        translate([19.2,2.2,19.4]) sphere(d=2.8*V3_string_channel_scale/V3_overall_scale, $fn=12); // just to clean up joint
    }
    
}

// try a module to handle both plugging and drilling channels()
module V3_do_channels() {
    difference() {
        union() {
            children();
            if(!V3_main_ghost) translate([0,-2,0]) V3_plug_old_channels();
            if(V3_main_ghost) V3_reborn_channels();
        }
        if(!(V3_fast_preview && $preview) && !V3_main_ghost) V3_reborn_channels();
        translate([0,-32.8,30]) cube([100,5,20], center=true); // shave end
    }
}

module V3_knuckles() {
    // re-insert clean finger stops
    for(dx=V3_slot_dx) translate(dx[0]+[3.7,38.5,12.5]) 
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
                
    if(V3_include_knuckle_covers) for(idx=[0:3]) 
        translate(cover_dx[idx][0]+V3_slot_dx[idx][0]+[3.7,25,23]) {
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

module V3_mesh_cutout() {
    translate([-19.6,50.5,2.17]) union() { // chop out old mesh
        translate([12,-65,0]) cube([50,50,5], center=true);
        translate([17,-42,0]) scale([1,0.8,1]) cylinder(d=40, h=5, center=true);
        translate([-2,-42,0]) cylinder(d=20, h=5, center=true);
        translate([25,-32,0]) rotate(-20) scale([1,0.6,1]) 
            cylinder(d=25, h=5, center=true);        
    } 
}

module V3_do_mesh() {
    if(V3_include_mesh==1) 
        union() {
            difference() {
                children();
                V3_mesh_cutout();
            }
            V3_mesh();
        }
    else children();
}

// plug up all holes and slots which need to be parametric
module V3_chamfered_cylinder(d=20, h=20, center=true)
{
    union() {
        cylinder(d=d, h=h-1, center=true);
        translate([0,0,h/2-.51]) cylinder(d1=d, d2=d-1, h=0.5);
        translate([0,0,-h/2+0.01]) cylinder(d1=d-1, d2=d, h=0.5);
    }
}

V3_pin_coordinates=[
    [[-35.6,-38,8],[0,90,0]], //left wrist
    [[20.9,-38,8],[0,90,0]], // right wrist
    [[6.6,39.5,6.0],[0,90,0]], // index and middle finger
    [[-16,35.5,6.0],[0,90,0]], // ring finger
    [[-29.5,29.5,6.0],[0,90,0]], // pinky
    [[32.2,-5.9,5.6],[0,90,50]], // thumb

];

module V3_plugs(size_scale=1, chop=false) {
    chopper=[13,13,30];
    
    // index and middle combined pin
    translate(V3_pin_coordinates[2][0]) rotate(V3_pin_coordinates[2][1]) 
        scale(size_scale) intersection() {
            V3_chamfered_cylinder(d=8,h=27.5, center=true, $fn=16);
            if(chop) translate([6,6,0]) rotate(45) cube(chopper, center=true);
        }
    // ring pin
    translate(V3_pin_coordinates[3][0]) rotate(V3_pin_coordinates[3][1]) 
        scale(size_scale) intersection() {
            V3_chamfered_cylinder(d=11,h=11, center=true, $fn=16);
            if(chop) translate([6,6,0]) rotate(45) cube(chopper, center=true);
        }
    // pinky pin
    translate(V3_pin_coordinates[4][0]) rotate(V3_pin_coordinates[4][1]) 
        scale(size_scale) intersection() {
            V3_chamfered_cylinder(d=11,h=11.5, center=true, $fn=16);
            if(chop) translate([6,6,0]) rotate(45) cube(chopper, center=true);
        }
    // thumb pin
    translate(V3_pin_coordinates[5][0]) rotate(V3_pin_coordinates[5][1]) 
        scale(size_scale) intersection() {
            V3_chamfered_cylinder(d=11,h=16, center=true, $fn=16);
            if(chop) rotate(-45) translate([6,6,0]) cube(chopper, center=true);
        }
 }

module V3_m3_wrist_plug() {
    rotate([0,90,0]) cylinder(d=10,h=4.99, center=true);            
}

module V3_m3_wrist_drill() {
    rotate([0,90,0]) {
        cylinder(d=3.5/V3_overall_scale,h=20, center=true, $fn=20);
        translate([0,0,-(4.99-2/V3_overall_scale)/2-0.1]) 
            rotate(30) cylinder(d=5.6/cos(30)/V3_overall_scale, h=2/V3_overall_scale, 
                center=true, $fn=6);
        translate([0,0,(4.99-2)/2+0.2])
            cylinder(d1=8, d2=10, h=2, center=true, $fn=50);
    }
}

module V3_do_wrist() {
    if(!V3_old_style_wrist) 
        difference() {
            union() {
                children();                
                translate(V3_pin_coordinates[0][0]) V3_m3_wrist_plug();
                translate(V3_pin_coordinates[1][0]) scale([-1,1,1]) V3_m3_wrist_plug();
            }
            translate(V3_pin_coordinates[0][0]) V3_m3_wrist_drill();
            translate(V3_pin_coordinates[1][0]) scale([-1,1,1]) V3_m3_wrist_drill();
            translate((V3_pin_coordinates[0][0]+V3_pin_coordinates[1][0])/2)
                rotate([0,90,0]) cylinder(h=52, d=17.5, center=true, $fn=16);
    } else children();
}

module V3_mesh(mesh_thickness=2) {
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

module V3_drilling(palm_scale, 
    pin_dia, pin23_length, pin45_length, pin_1_length,
    pin_head_square, V3_pins=true)
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
    for(dx=V3_slot_dx) translate(dx[0]+[3.7,43,-10]) 
        rotate(dx[1]+180) translate([0,5,5]) 
            V3_rounded_cutter(width=base_slot_width*finger_scale/palm_scale, height=40);
    // make holes for pins
    center_offset=[0, base_rotation_offset*(palm_scale/finger_scale-1), 0];
    if(V3_pins) {
    translate(V3_pin_coordinates[2][0]+center_offset) rotate(V3_pin_coordinates[2][1]) 
        cylinder(d=pin_dia, h=30, $fn=20, center=true);
    translate(V3_pin_coordinates[3][0]+center_offset) rotate(V3_pin_coordinates[3][1]) 
        cylinder(d=pin_dia, h=15, $fn=20, center=true);
    translate(V3_pin_coordinates[4][0]+center_offset) rotate(V3_pin_coordinates[4][1]) 
        cylinder(d=pin_dia, h=15, $fn=20, center=true);    
    translate(V3_pin_coordinates[5][0]+center_offset) rotate(V3_pin_coordinates[5][1]) 
        cylinder(d=pin_dia, h=17, $fn=20, center=true);
    }
    // block to mill out old rubber-band attachment for thumb
    translate([30,-5,-5]) rotate(49.5) {
        translate([0.55,-6,0]) 
        V3_rounded_cutter(width=base_slot_width*finger_scale/palm_scale, height=30);
        translate([0.55,-4,8]) cube([6,20,20], center=true);
    }
}

module V3_do_pins() {
    difference() {
        union() {
            children();
            V3_plugs();
        }
        V3_drilling(
            palm_scale=V3_overall_scale, 
            pin_dia=V3_pivot_size/V3_overall_scale, pin23_length=25, pin45_length=10, 
            pin_1_length=15
        );
    }
}

module V3_do_knuckles() {
    union() {
        children();
        V3_knuckles(); // insert backstops and knuckle cover
        // add cylindrical pin for thumb
        translate(V3_pin_coordinates[5][0]+[0,0,7]) 
        rotate(V3_pin_coordinates[5][1]) 
        translate([-1,-2,0]) cylinder(d=4, h=8, center=true, $fn=20);
    }
}

module V3_do_labels() {
    textscale=[mirrored?-1:1,1];
    difference() {
        children();
        translate([21.2, 3, 6]) rotate([90,0,-90])
            linear_extrude(slices=1, height=1) scale(textscale) 
            text(str(V3_overall_scale*100), size=4, halign="center");
        translate([-35.5,-19,2.001]) hull() { // flat plate for text
            cube([0.1,30,12]);
            translate([5,-4,0]) cube([3,38,14]);
        }
        translate([-36.5, -4, 11]) rotate([90,0,90])
            linear_extrude(slices=1, height=1.5) scale(textscale) intersection() {
                group() {
                    text(V3_serial_line1, size=3.5, halign="center");
                    translate([0,-4])text(V3_serial_line2, size=3.5, halign="center");
                    translate([0,-8])text(V3_serial_line3, size=3.5, halign="center");
                }
                translate([0,-3]) square([29,12], center=true);
            }
    }
}

V3_act_scale=[mirrored?-V3_overall_scale:V3_overall_scale, V3_overall_scale, V3_overall_scale];
// collect everything together as concatenated functional operators
module V3_scaled_palm() 
{
    scale(V3_act_scale)
    V3_do_labels() 
    V3_do_wrist() 
    V3_do_knuckles()
    V3_do_pins() 
    V3_do_mesh() 
    V3_do_channels() 
    V3_do_supports()
    translate([-19.6,50.5,2.17]) 
    if(!V3_main_ghost) 
        import("palm_v3.stl", convexity=10);      
    else
        %import("palm_v3.stl", convexity=10);
}

module V3_main() {

V3_scaled_palm();

if(V3_include_wrist_stamping_die) scale(V3_overall_scale) {  $fn=50; 
    translate(mirrored?[20,-50,4.99/2]:[5,-50,4.99/2]) difference() {
        rotate([0,-90,0]) difference() {
            scale([1,2.5,2.5]) V3_m3_wrist_plug();
            intersection() {
                    V3_m3_wrist_drill();
                    translate([5,0,0]) cube([10,20,20], center=true);
                }
            }
        cylinder(d=3.6/V3_overall_scale, h=50, center=true, $fn=20);  // drilling guide hole
    }       
    translate(mirrored?[-6,-50,4.99/2]:[-21,-50,4.99/2]) difference() {
        rotate([0,90,0]) union() {
            scale([1,2.5,2.5]) V3_m3_wrist_plug();
            translate([-5.1+0.5,0,0]) intersection() {
                V3_m3_wrist_drill();
                translate([2.5,0,0]) cube([4,20,20], center=true);
            }
        }
        cylinder(d=3.6/V3_overall_scale, h=50, center=true, $fn=20); // drilling guide hole
        translate([0,3,-4.99/2-0.01]) linear_extrude(slices=1, height=0.5) 
            scale([-1,1]) text(str(V3_overall_scale*100), size=4, halign="center");
    }
}
}
