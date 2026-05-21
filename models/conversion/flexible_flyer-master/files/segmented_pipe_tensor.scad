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
    join_ends=false, untwist=false, triangularize_ends=true,
    maximum_segment_length = undef,
    show_segment_breaks = false)
{
    multi_pipe(
        [polygon_points],
        [for(xx=path_points) [0, each xx]],
        join_ends=join_ends, untwist=untwist,
        triangularize_ends=triangularize_ends,
        maximum_segment_length = maximum_segment_length,
        show_segment_breaks = show_segment_breaks
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

function transpose(m) = [
    [m[0][0],m[1][0],m[2][0]],
    [m[0][1],m[1][1],m[2][1]],
    [m[0][2],m[1][2],m[2][2]]
    ];

function rotations(path_points, initial_bend_perp) = let(
    np=len(path_points),
    xyz =[for(x=path_points) x[1] ],
    has_perp = !is_undef(initial_bend_perp), 
    bpgu = has_perp ? 
        initial_bend_perp/norm(initial_bend_perp) : 
        undef, // unit vector or undef
    
    // create a nameless function to handle geometry, 
    // to make for loop list comprehension less messy
    fg = function (i, old_up) let(
        ibase  = min(max(i-1,0),np-3), 
        x2=xyz[ibase+2],
        x1=xyz[ibase+1],
        x0=xyz[ibase], 
        dx10_u = (x1-x0) / norm(x1-x0), dx21_u = (x2-x1) / norm(x2-x1),
        up_sine_vec = cross(dx10_u, dx21_u),
        bendsine = norm(up_sine_vec),
        use_bend = (bendsine > 1e-6) && (i!=0 || !has_perp),
        xx = assert(use_bend || !is_undef(old_up), 
            "segmented_pipe has colinear initial segments and no initial bend vector"), 
        up_a = use_bend ? up_sine_vec/bendsine : old_up,
        up_u = up_a * ((i != 0 && up_a*old_up < 0) ? -1:1), 
        bendcos = ((i==0) || (i==(np-1))) ? 1 : dx10_u * dx21_u, // cos of full bend angle
        halfbendcos = sqrt((1+bendcos)/2), // cos of half bend angle
        path_vec_a = (i==0) ? dx10_u : (
            (i==np-1) ? dx21_u : (dx10_u + dx21_u)),
        path_vec_u = path_vec_a / norm(path_vec_a), 
        bend_vec_a = cross(up_u, path_vec_u), // unnorm
        bend_vec_u = bend_vec_a / norm(bend_vec_a), // bend this way 
        fixed_up = cross(path_vec_u, bend_vec_u) // really perpendicular after guess may not be
        ) [halfbendcos, [bend_vec_u, path_vec_u, fixed_up]] // transpose of rotation
        
    ) [for(i=0, val=fg(i,bpgu); i < np; 
            i=i+1, val=fg(i, val[1][2]) )
            [val[0], transpose(val[1])] // full rotation into frame
        ];

// directly from OpenSCAD help
function cumsum(v) = [for (a = v[0]-v[0], i = 0; i < len(v); a = a+v[i], i = i+1) a+v[i]];
    
// compute a rotation angle phi such that the length of a vector
// mat1*phimat*[1, 1, 0]-mat0*[1,1,0] 
// is minimized
// this is tail-recursive to iterate

function minimize_twist(mat0, mat1, phi0=-190, phi1=190) = let (
        ml = function (p) let(
            pm = [ [cos(p), 0, sin(p)],[0,1,0],[-sin(p),0,cos(p)]]
        ) norm((mat1*pm-mat0)*[10,1,0]) + norm((mat1*pm-mat0)*[0,1,10]),

        phi2 = ( (phi1-phi0) < 5 ? (phi0 + phi1) / 2 : let (
            step = (phi1-phi0)/10,
            // lengths of twisted vectors until minimum is passed
            ll = [
                for(p1=phi0,
                    l1=ml(phi0), l2=ml(phi0+step),l3=ml(phi0+2*step);
                    (l1 < l2 || l3 < l2) && p1 <= phi1;
                    p1 = p1 + step, l1 = l2, l2 = l3, l3 = ml(p1+2*step)
                    ) p1+step
            ],
            maxp = ll[len(ll)-1]+step
           ) minimize_twist(mat0, mat1, maxp-step, maxp+step)   
        )
    ) phi2;
   
// generate the polyhedral vertices for each rotate polygon, and return the data
// polygon_point_sets is a list of polygons,
// all of which must have the same number of sides, 
// and path_points is [ [poly_select, xyz, scale, phi], ...]
// if untwist is true, it attempts to remove the azimuthal
// rotation from the phi rotation, resulting in straighter pipes.
// this tends to break threading, and some other things.
function multi_pipe_vertices(polygon_point_sets, path_points, 
    untwist, initial_bend_perp, accumulate_phi) = let(
    np=len(path_points),
    psel=[for(x=path_points) x[0] ],
    xyz =[for(x=path_points) x[1] ],
    scl =[for(x=path_points) x[2] ],
    phi =[for(x=path_points) x[3] ],
    // make 3d points from 2d polygons for full rotations
    v3=[for(pp=polygon_point_sets) [for(v=pp) [v.x,v.y,0]]],
    
    xf = rotations(path_points, initial_bend_perp), 
    
    transforms=[for(i=[0:np-1]) 
        [v3[psel[i]]*scl[i], 
        xf[i], 
        phi[i], xyz[i] ]
    ], 
    
    // prepare untwisted rotations, if requested
    // and add in twist tweaks from explicit phi
    phisum = accumulate_phi? cumsum(phi) : phi,
    twistphi = !untwist? undef : cumsum(
            [0, each [for(i=[0:np-2]) minimize_twist(xf[i][1], xf[i+1][1])] ]),
    allphi = untwist? (phisum  + twistphi) : phisum,
            
    vertices=[for(i=[0:len(transforms)-1])
        let (
            xfrm=transforms[i],
            vv=xfrm[0],
            halfbendcos=xfrm[1][0], // correction for distortion at bend
            mat=xfrm[1][1],
            phi=allphi[i],
            x0=xfrm[3], 
            caz = cos(phi), saz = sin(phi),
            mat2 = mat * [
                [caz,0,saz]/halfbendcos,[0,1,0],[-saz,0,caz]],
            pts=[for(x=vv) mat2*[x.x,0,x.y] + x0] // fixed azimuthal xfrm
        )
        each pts
    ]) 
    vertices;


// polygon_point_sets is a list of polygons,
// all of which must have the same number of sides, 
// and vertices is a list from multi_pipe_vertices()
// if join_ends is true, the two ends are stitched together
// instead of being capped with flat caps.
// if untwist is true, it attempts to remove the azimuthal
// rotation from the phi rotation, resulting in straighter pipes.
// this tends to break threading, and some other things.
module multi_pipe_segment(polygon_point_sets, vertices, 
    join_ends=false, untwist=true,
    triangularize_ends=true)
{    
    // now have to build connection triangles
    // no geometry here, just counting
    // could let OpenSCAD automatically split quads, 
    // rather than create triangles,
    // but just do it explicitly here.
    nn=len(polygon_point_sets[0]);
    np=len(vertices)/nn;
    
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

// polygon_point_sets is a list of polygons,
// all of which must have the same number of sides, 
// and vertices is a list from multi_pipe_vertices()
// if join_ends is true, the two ends are stitched together
// instead of being capped with flat caps.
// if untwist is true, it attempts to remove the azimuthal
// rotation from the phi rotation, resulting in straighter pipes.
// this tends to break threading, and some other things.
// initial_bend_perp is used on the first step,
// to set the perpendicular to the bend plane.
// If it is undef, the first three steps cannot be colinear.
module multi_pipe(polygon_point_sets, path_points, 
    join_ends=false, untwist=false,
    triangularize_ends=true,
    maximum_segment_length = undef,
    show_segment_breaks = false, 
    accumulate_phi = false, 
    initial_bend_perp = undef)
{
    segmenting = !is_undef(maximum_segment_length);

    // loop both ends of path for closed, segmented curve
    // this guarantees appropriate continuity on the matching faces
    // at the join
    looped = (join_ends && segmenting);
    xpath =  looped ?
        [path_points[len(path_points)-1], each path_points, path_points[0], 
            path_points[1]] 
        : path_points;

    vertices=multi_pipe_vertices(
        polygon_point_sets, xpath, untwist=untwist,
        initial_bend_perp = initial_bend_perp, 
        accumulate_phi = accumulate_phi
    );
    np = len(xpath);
    polysides = len(polygon_point_sets[0]);
    
    maxseg = segmenting ? maximum_segment_length : np;
    
    startface = looped?1:0; // if front is looped, skip it
    segbounds = [for(i=[startface:maxseg:np-3]) [i, min(np-1, i+maxseg)]];
    nseg = len(segbounds);
    
    // echo(np=np, maxseg=maxseg, sb = segbounds);
    
    for(sidx = [0 : nseg-1]) let(
        last = (sidx == nseg-1), 
        s = segbounds[sidx],
        base=s[0]*polysides, 
        // final segment may need to have looped bit removed leaving end cap
        top= last ? (looped? len(vertices)-polysides-1 : len(vertices)-1) :
            (show_segment_breaks? s[1] : s[1]+1)*polysides - 1, 
        vv = [for(i=[base:top]) vertices[i]]
            // xxx = echo(base=base, top=top )
        )   
        multi_pipe_segment(polygon_point_sets, vv, 
            join_ends= !segmenting && join_ends,
            triangularize_ends=triangularize_ends);
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
            [[10*cos(th), 10*sin(th), 0.05*th], 
                (1-0.0005*th)*(1+0.5*cos(th*2)), 0]
        ], untwist=false, triangularize_ends=false,
        maximum_segment_length = 10,
        show_segment_breaks = true
      );
     
    // demonstrate lumpy torus
    translate([-20,-20,0]) pipe([for(th=[0:30:359]) [cos(th), sin(th)]],
        [for(th=[0:5:359]) 
            [[10*cos(th), 10*sin(th), 0], 1+0.5*cos(6*th), 0]
        ], join_ends=true, maximum_segment_length = 10, 
            show_segment_breaks = false
        
      );


    // a lumpy pipe hollowed out of a cube, 
    // with sections appended to the ends to penetrate the sides of the cube
    translate([0,50,0]) difference() {
        translate([0,0,8]) cube([24,24,20], center=true);
        pipe([for(th=[0:10:359]) [cos(th), sin(th)]],
        [[[10,-4,-5],1,0], each [for(th=[0:10:720]) [[10*cos(th), 10*sin(th), 0.02*th], (1-0.0005*th)*(1+0.5*cos(th*2)), 0]], [[10,4,20],0.4,0]],
            untwist=true
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
        [ [0,[0,0,0],10,0], [1,[0,0,20],10,0], [0,[0,0,40],5,0] ],
        initial_bend_perp = [0,1,0]
    );

    // test azimuthal preening and smoothed bends
    // insert manual phi values to untwist case with auto-untwist off
    straw=[ 
       [0,[0,0,0],1,0], [0,[10,5,0],1,0],
       [0, [15,10,5], 1, 40], [0,[15,9,11], 1, 20], 
       [0,[15,8,14], 1, -10], [0, [20,20,25],1, 0]
    ];       
    notweaks = [for (x=straw) [x[0],x[1],x[2],0]]; // remove phi for untwist test
    translate([20,20,0]) multi_pipe(
        [ [for(th=[0:10:359]) [cos(th), sin(th)]]]/2,
        smooth_bends(notweaks, 5, 3), untwist=true,
        accumulate_phi = true
    );
    translate([20,25,0]) multi_pipe(
        [ [for(th=[0:10:359]) [cos(th), sin(th)]]]/2,
        straw, untwist=false,
        accumulate_phi = true
    );
}

tests();
