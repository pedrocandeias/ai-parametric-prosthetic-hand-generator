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
module pipe(polygon_points, path_points, 
    join_ends=false, untwist=true, triangularize_ends=true)
{
    multi_pipe(
        [polygon_points],
        [for(xx=path_points) [0, each xx]],
        join_ends=join_ends, untwist=untwist,
        triangularize_ends=triangularize_ends
    );
}


// simple_pipe has no scale-per-step or phi-per-step
// it just takes a polygon and a list of xyz
module simple_pipe(polygon_points, path_points, join_ends=false,
    triangularize_ends=true)
{
    multi_pipe(
        [polygon_points],
        [for(xx=path_points) [0, xx, 1, 0]],
        join_ends=join_ends, 
        triangularize_ends=triangularize_ends
    );
}

// return caz and saz, remembering old values near singularities,
// by running backwards from the singularity to a good value
function preen(transforms, idx) = (
    (idx==0 && is_undef(transforms[idx][1])) ? 
        [1, 0] : // first point is singular, use default rotation
        is_undef(transforms[idx][1]) ?
            preen(transforms, idx-1) : // point is singular, walk back
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
module multi_pipe(polygon_point_sets, path_points, 
    join_ends=false, untwist=true,
    triangularize_ends=true)
{
    np=len(path_points);
    connections=[];
    psel=[for(x=path_points) x[0] ];
    xyz =[for(x=path_points) x[1] ];
    scl =[for(x=path_points) x[2] ];
    phi =[for(x=path_points) x[3] ];
    
    // make 3d points from 2d polygons for full rotations
    v3=[for(pp=polygon_point_sets) [for(v=pp) [v.x,v.y,0]]]; 
        
    // have to do whole cal in a list comprehension,
    // since openscad can't append to a list...
    transforms=[for(i=[0:np-1]) let(
        // the normal for a joint is parallel to the line connecting
        // the two points adjacent to the joint,
        // except for the end caps, 
        // which are cut perpendicular to the terminal line
        x2=xyz[min(i+1,np-1)],
        x1=xyz[i],
        x0=xyz[max(i-1,0)], 
        dx21=x2-x1,
        dx10=x1-x0,
        dx20=x2-x0,
        u= dx20/norm(dx20), // unit vector norm to joint plane
        rho=norm([u.x, u.y]), // cylindrical sine, cos is just z
        mat1=[[u.z,0,rho],[0,1,0],[-rho,0,u.z]], // euler polar rot
        // check for very close to the 'z' axis before computing azimuthal matrix
        caz=(rho > 1e-6)?(u.x/rho):undef,
        saz=(rho > 1e-6)?(u.y/rho):undef 
        ) 
        //[pts, caz, saz, xyz[i]] // transform info
        [v3[psel[i]]*scl[i], caz, saz, mat1, phi[i], u.z, xyz[i] ]
    ];
    // now, preen the azimuthal rotations
    // to avoid singularities along the 'z' axis
    // note that preening can be as bad as an n^2 operation,
    // if the entire object is along the 'z' axis.
    // better to lay things out along 'x', and then rotate afterwards.
    vertices=[for(i=[0:len(transforms)-1])
        let (
            xfrm=transforms[i],
            vv=xfrm[0],
            mat1=xfrm[3],
            phi=xfrm[4],
            cth=xfrm[5], 
            x0=xfrm[6], 
            az=preen(transforms, i),
            caz=az[0], saz=az[1],
            mat2=[[caz, -saz,0],[saz, caz, 0],[0,0,1]], // azimuth
            p=phi-(untwist?cth*atan2(saz,caz):0), // untwisted from azimuth
            phimat=[[cos(p), -sin(p),0],[sin(p), cos(p),0],[0,0,1]],
            pts=[for(x=vv) mat2*mat1*phimat*x + x0] // fixed azimuthal xfrm
        )
        each pts
    ];
    // now have to build connection triangles
    // no geometry here, just counting
    // could let OpenSCAD automatically split quads, 
    // rather than create triangles,
    // but just do it explicitly here.
    nn=len(polygon_point_sets[0]);
    t1=[for (j=[0:np-2]) for(i=[0:nn-1]) 
        let(b=j*nn, bp1=(j+1)*nn, ip1=(i+1) % nn) 
        each [
            [b+ip1, b+i, bp1+i], //bottom triangles
            [bp1+i,  bp1+ip1, b+ip1], // top triangles
        ]
    ];
    
    //create triangularized end caps (works for convex polys)
    // find bounding boxes for both ends
    pl0=[for(i=[0:nn-1]) vertices[i]]; // first transformed polygon
    pl1=[for(i=[0:nn-1]) vertices[(np-1)*nn+i]]; // last transformed polygon
    
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
        each [for(i=[0:nn-2]) [i,i+1,np*nn]], 
        [nn-1,0,np*nn],
        each [for(i=[np*nn-2:-1:(np-1)*nn]) [i+1,i,np*nn+1]],
        [(np-1)*nn, np*nn-1, np*nn+1]
    ];
    
    // simple end caps (not triangularized)
    plain_caps=[[for(i=[0:nn-1]) i],  [for(i=[np*nn-1:-1:(np-1)*nn]) i]];
    extra_verts_plain_caps=[];
    
    caps=triangularize_ends?tri_caps:plain_caps;
    extra_verts_cap=triangularize_ends?extra_verts_tri_caps:extra_verts_plain_caps;
    
    // create end join
    join=[for(i=[0:nn-1])
        let(b=(np-1)*nn, bp1=0, ip1=(i+1) % nn) 
        each [
            [b+ip1, b+i, bp1+i], //bottom triangles
            [bp1+i,  bp1+ip1, b+ip1], // top triangles
        ]
    ];
    extra_verts_join=[];
    
    allverts=[each vertices, each (join_ends?extra_verts_join:extra_verts_cap)];
    
    t2=[each t1, each (join_ends?join:caps)];
    
    polyhedron(points=allverts, faces=t2, convexity=10);
}

// take a set of path_points, and if a bend is more than the specified 
// max_bend limit,  break it down into bends less than that,
// and interpolate everything except the polygon index
function smooth_bends(path_points, max_bend, bend_radius) = (
  let (
    np=len(path_points),
    multi=!is_list(path_points[0][0]), // check for poly index
    xyzidx=multi?1:0,
    xyz=[for(xx=path_points) xx[xyzidx]], // extract coordinates
    scl=[for(xx=path_points) xx[xyzidx+1]], // extract scales
    phi=[for(xx=path_points) xx[xyzidx+2]], // extract rotations
    verts=[for(i=[1:np-2]) let(
        x2=xyz[i+1],
        x1=xyz[i],
        x0=xyz[i-1], 
        dx21=x2-x1,
        dx10=x1-x0,
        dx20=x2-x0,
        u= dx20/norm(dx20), // unit vector norm to joint plane
        bendcross=cross(dx21, dx10)/(norm(dx21)*norm(dx10)),
        bend=asin(norm(bendcross)), // the sine of the bend angle
        nbend=floor(1+bend/max_bend)
    ) if (bend < max_bend) path_points[i] else each [ 
        for(j=[0:nbend]) let (
            t=j/nbend,
            // how far away to start the bend
            // avoiding collisions with smoothing from 
            // the other end of each segment
            backoff=min(bend_radius*bend*3.14/180, norm(dx21)/2.5, norm(dx10)/2.5),
            // knots for cubic spline, middle knot used twice
            p0=x1-backoff*dx10/norm(dx10),
            p12=x1,
            p3=x1+backoff*dx21/norm(dx21),
// swiped from some of my old python code 
//        spline=lambda t: vec_scale_sum(vec_scale_sum(vec_scale_sum(vec_scale_sum((0.,0.),
//           p0, (1-t)**3),  p1, 3*(1-t)**2*t),  p2, 3*(1-t)*t**2),  p3, t**3)
           s=1-t,
           s2=s*s,
           s3=s2*s,
           t2=t*t,
           t3=t2*t,
           vv=p0*s3+3*p12*s*t+p3*t3,
           ss=scl[i-1]*s3+3*scl[i]*s*t+scl[i+1]*t3,
           pp=phi[i-1]*s3+3*phi[i]*s*t+phi[i+1]*t3
        )
        // put back polygon index if it was there
        [each multi?path_points[i][0]:[], each [vv, ss, pp]]
      ]
    ]
  )
  [path_points[0], each verts, path_points[np-1]]
);

module tests() {
    // demonstrate a lumpy pipe
    pipe([for(th=[0:30:359]) [cos(th), sin(th)]],
        [for(th=[0:5:719]) 
            [[10*cos(th), 10*sin(th), 0.02*th], 
                (1-0.0005*th)*(1+0.5*cos(th*2)), 0]
        ], untwist=false, triangularize_ends=false
      );
     
    // demonstrate lumpy torus
    translate([-20,-20,0]) pipe([for(th=[0:30:359]) [cos(th), sin(th)]],
        [for(th=[0:5:359]) 
            [[10*cos(th), 10*sin(th), 0], 1+0.5*cos(6*th), 0]
        ], join_ends=true
      );


    // a lumpy pipe hollowed out of a cube, 
    // with sections appended to the ends to penetrate the sides of the cube
    translate([0,50,0]) difference() {
        translate([0,0,8]) cube([24,24,20], center=true);
        pipe([for(th=[0:10:359]) [cos(th), sin(th)]],
        [[[10,-4,-5],1,0], each [for(th=[0:10:720]) [[10*cos(th), 10*sin(th), 0.02*th], (1-0.0005*th)*(1+0.5*cos(th*2)), 0]], [[10,4,20],0.4,0]]
      );
    }

    // demonstrate a pipe with alternating polygons
    translate([24,0,0]) multi_pipe(
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
        
    translate([0,24,0]) multi_pipe(
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
    translate([20,20,0]) multi_pipe(
        [ [for(th=[0:90:359]) [cos(th), sin(th)]]],
        smooth_bends(straw, 5, 3), untwist=true
    );
    translate([20,25,0]) multi_pipe(
        [ [for(th=[0:90:359]) [cos(th), sin(th)]]],
        straw, untwist=true
    );
}

tests();
