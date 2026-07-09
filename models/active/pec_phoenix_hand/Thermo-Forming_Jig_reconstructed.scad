// ============================================================================
//  Thermo-Forming Jig  —  parametric reconstruction (primitives only)
// ----------------------------------------------------------------------------
//  Built from INDEPENDENT pieces that fuse together:
//    * DOME  : a hollow elliptical arch, raised so it springs from springing_height.
//    * RAILS : two standalone slightly-diagonal side plates (the legs), with
//              their OWN parameters — move/size/angle them freely.
//    * FLOORS: two end gussets closing the bottom between the rails.
//    * TABS  : two boxes at the narrow/back end.
//    * PINS  : two cylinders + half-spheres protruding sideways.
//
//  Axes:  X = width,  Y = length (front Y=0 -> back Y=body_length),  Z = height (Z0 = base)
//  The top slopes down front->back (apex_height_front -> apex_height_back); base stays flat.
//  Coords match the original STL frame (centred at X = arch_center_x).
// ============================================================================

// ---- render quality --------------------------------------------------------
$fn = 96;     // curve smoothness
weld_overlap = 0.05;   // small overlap to keep booleans clean

// ---- comparison overlay ----------------------------------------------------
// Two independent toggles for comparing against the original:
show_reconstruction    = true;   // show OUR reconstruction (uncheck to see only the original STL)
show_original_stl = true;   // show the original STL as a transparent grey ghost (F5 preview only)
if (show_original_stl)
    %import("/home/pec/dev/openscad-parametric-reconstructor/models/Thermo-Forming_Jig.stl");


// ============================================================================
//  PARAMETERS  (edit these)
// ============================================================================

// ---- overall placement -----------------------------------------------------
arch_center_x = -24.6;   // arch centre line in X
body_length = 70.0;      // length of the dome/rails along Y (front Y=0 .. back Y=body_length)

// ---- arch inclination (top slopes down front -> back; base stays flat) ------
apex_height_front = 37.2;   // apex (top) height at the front (Y=0)
apex_height_back  = 23.0;     // back apex (fitted to ghost with the new front profile)

// ---- DOME cross-section at the FRONT (Y=0) ----------------------------------
springing_height  = 10.0;    // Z where the dome springs (lower => wider, more continuous front arch)
dome_half_width  = 26.0;    // outer half-width of the dome at the springing line
dome_wall_thickness = 4.0;     // dome wall thickness
arch_flatness    = 2.2;     // arch top shape: 2 = ellipse, >2 = flatter/boxier, <2 = pointier

// ---- RAILS  (independent side legs — move/size/angle them freely) -----------
rail_foot_half_width  = 27.8;   // outer half-width at the foot (Z=0) — matches arch base
rail_top_half_width   = 24.0;   // outer half-width at the top — tucks inside the curving arch
rail_height     = 21.3;   // rail height (slightly above springing_height so it fuses into the dome)
rail_thickness = 4.3;    // rail plate thickness (X)
rail_tilt_deg   = 0.0;      // extra tilt (deg) about the foot; foot/top widths already angle it
rail_corner_radius = 1.0;  // rounding on the rail edges (< rail_thickness/2)

// ---- taper toward the back (Y = body_length) ----------------------------------------
width_taper  = 0.78;                                 // back width = front width * this (fitted)
height_taper = apex_height_back / apex_height_front;   // height taper (derived from the apex incline)

// ============================================================================
//  FLOOR GUSSETS (green) — front & back, each its own knobs
//  (each spans the arch footprint in X, clipped to *_width; sits on the floor)
// ============================================================================
// FRONT floor gusset  (Lime green)
front_floor_y_start   = 11.0;     // Y start
front_floor_y_end     = 15.0;     // Y end
front_floor_thickness = 4.0;    // thickness (Z)
front_floor_z         = 0.0;      // base height (Z)
front_floor_width     = 80.0;     // X span (clipped to the arch footprint; lower => narrower)
// BACK floor gusset  (Forest green)
back_floor_y_start    = 67.0;     // Y start
back_floor_y_end      = 70.0;     // Y end
back_floor_thickness  = 4.0;    // thickness (Z)
back_floor_z          = 0.0;      // base height (Z)
back_floor_width      = 80.0;     // X span (clipped to the arch footprint; lower => narrower)

// ============================================================================
//  MAGENTA object  (the LEFT TAB) — its own knobs, manipulate freely
// ============================================================================
magenta_x        = -44.13;     // X centre
magenta_y        = 78.25;      // Y centre (along the body)
magenta_z        = 6.75;       // Z centre (height)
magenta_width    = 4.5;        // size in X
magenta_length   = 20.5;       // size in Y
magenta_height   = 13.5;       // size in Z
magenta_rotation = [0, 0, 0];  // rotation in degrees [X,Y,Z]
magenta_round    = 0.8;        // edge rounding radius

// ============================================================================
//  CYAN object  (the LEFT PIN) — its own knobs, manipulate freely
// ============================================================================
cyan_x        = -45.0;           // X position of the root
cyan_y        = 80.0;            // Y position (along the body)
cyan_z        = 8.0;             // Z position (height of the axis)
cyan_radius   = 2.0;             // radius / thickness
cyan_length   = 4.0;             // length (how far it sticks out)
cyan_rotation = [0, -90, 0];   // rotation in degrees [X,Y,Z]   ([0,-90,0] points -X)
// ============================================================================
//  RED object  (the RIGHT PIN) — its own knobs, manipulate freely
// ============================================================================
red_x        = -4.0;          // X position of the root
red_y        = 80.0;          // Y position (along the body)
red_z        = 8.0;           // Z position (height of the axis)
red_radius   = 2.0;           // radius / thickness
red_length   = 4.0;           // length (how far it sticks out)
red_rotation = [0, 90, 0];  // rotation in degrees [X,Y,Z]   ([0,90,0] points +X)

// ============================================================================
//  PURPLE object  (the RIGHT TAB) — its own knobs, manipulate freely
// ============================================================================
purple_x        = -5.12;      // X centre
purple_y        = 78.25;      // Y centre (along the body)
purple_z        = 6.75;       // Z centre (height)
purple_width    = 4.5;        // size in X
purple_length   = 20.5;       // size in Y
purple_height   = 13.5;       // size in Z
purple_rotation = [0, 0, 0];  // rotation in degrees [X,Y,Z]
purple_round    = 0.8;        // edge rounding radius

// ---- extremity rounding ----------------------------------------------------
end_round = 4.5;   // radius of the rounded bottom at the FRONT & BACK ends (0 = sharp 90 deg)

// ---- BULGE  (a cylinder; the part sitting ABOVE the arch is added as a bulge) --
bulge_enable   = true;        // add the bulge (the cylinder's part above the arch)
bulge_preview  = false;       // hide the orange positioning cylinder (bulge stays)
bulge_radius   = 11.0;          // cylinder radius
bulge_length   = 24.0;          // cylinder length
bulge_x        = -24.6;       // X of the cylinder axis
bulge_y        = 59.2;           // Y of the axis (along the body)
bulge_z        = 15.6;          // Z of the axis (height)
bulge_rotation = [90, 0, 0];  // axis orientation in deg (now along Y / the length)
bulge_shape    = "cylinder";  // "cylinder" or "sphere"
bulge_flatten  = 0.9;         // Z squash (1 = round, <1 = flatter)  // axis orientation in deg  ([0,90,0] = along X / across width)
bulge_color    = [1.0, 0.4, 0.1, 0.35];  // preview colour [R,G,B,Alpha]  (Alpha<1 = transparent)

// ---- derived ---------------------------------------------------------------
apex_height   = apex_height_front;          // dome top at the front
inner_apex_height   = apex_height   - dome_wall_thickness;
inner_half_width = dome_half_width - dome_wall_thickness;
// inner-cavity taper: chosen so the dome wall stays ~constant toward the back
// (instead of thinning, which is what a single solid-scaled taper does).
dome_inner_xtaper = (dome_half_width*width_taper - dome_wall_thickness) / inner_half_width;
dome_inner_ztaper = (apex_height_back        - dome_wall_thickness) / inner_apex_height;


// ============================================================================
//  MODULES  (shape definitions — rarely need editing)
// ============================================================================

// Elliptical arch curve points: (-spring,sz) over the apex (0,az) to (spring,sz).
function arch_curve_points(spring, sz, az, n) = [ for (i = [0:n])
    let (a = 180 - i*180/n, c = cos(a), s = sin(a))
    [ spring * (c<0?-1:1) * pow(abs(c), 2/arch_flatness),
      sz + (az-sz) * pow(abs(s), 2/arch_flatness) ] ];

// Closed arch outline (2D): bottom edge at base_z, up the sides, arch over the top.
module arch_outline(foot, spring, sz, az, base_z)
    polygon(concat([[-foot, base_z]], arch_curve_points(spring, sz, az, 40), [[foot, base_z]]));

// extrude any 2D cross-section along Y with a given front->back taper [x,z]
module extrude_taper(taper)
    translate([arch_center_x, 0, 0]) mirror([0,1,0]) rotate([90,0,0])
        linear_extrude(height = body_length, scale = taper) children();

// default body taper (outer surfaces of dome + rails + floors)
module extrude_along_length() extrude_taper([width_taper, height_taper]) children();

// bulge tool: a cylinder you size / move / rotate; only its part above the arch is kept
module bulge_blank()
    translate([bulge_x, bulge_y, bulge_z]) rotate(bulge_rotation) scale([1, 1, bulge_flatten])
        if (bulge_shape == "sphere")
            scale([1, bulge_length/(2*bulge_radius), 1]) sphere(r = bulge_radius);
        else
            cylinder(r = bulge_radius, h = bulge_length, center = true);

// solid filling the whole inside / underside of the arch (cavity extended down).
// Subtracting this from the cylinder removes the part UNDER the arch, leaving only
// the part ABOVE it, which fuses onto the dome as a bulge.
module under_arch()
    extrude_taper([dome_inner_xtaper, dome_inner_ztaper])
        arch_outline(inner_half_width, inner_half_width, springing_height, inner_apex_height, -20);

// the kept part of the cylinder: the bit above the arch only
module bulge()
    difference() { bulge_blank(); under_arch(); }

// Solid filling the dome's outer shell (no cavity) — used to carve the rails so
// they sit OUTSIDE the dome and never intrude on the interior surface.
module dome_outer_solid()
    extrude_taper([width_taper, height_taper])
        arch_outline(dome_half_width, dome_half_width, springing_height, apex_height, springing_height - 3);

// ---- DOME (just the raised arch, hollow; small skirt below for fusion) ------
module dome()
    union() {
        difference() {
            dome_outer_solid();                                     // outer surface
            extrude_taper([dome_inner_xtaper, dome_inner_ztaper])    // inner cavity (own taper => wall ~constant)
                arch_outline(inner_half_width, inner_half_width, springing_height, inner_apex_height, springing_height - 4);
        }
        if (bulge_enable) bulge();                             // add bulge: cylinder above the arch
    }

// ---- RAILS (independent) ---------------------------------------------------
// One rail cross-section: a leaning parallelogram plate.  s = +1 right, -1 left.
module rail_cross_section(s)
    translate([s*rail_foot_half_width, 0]) rotate(s*rail_tilt_deg) translate([-s*rail_foot_half_width, 0])
        offset(r=rail_corner_radius) offset(delta=-rail_corner_radius)
        polygon([ [s*rail_foot_half_width,                 0],
              [s*rail_top_half_width,                  rail_height],
              [s*(rail_top_half_width  - rail_thickness),  rail_height],
              [s*(rail_foot_half_width - rail_thickness),  0] ]);

// Rails carved by the dome's outer shell (shrunk a hair so they still overlap and
// union cleanly): the rails keep only their outer splay + the base below the dome,
// so the dome alone forms the whole interior — no rail edges show inside.
module rails()
    difference() {
        extrude_along_length() { rail_cross_section(1); rail_cross_section(-1); }
        translate([arch_center_x, 0, 0]) scale([0.98, 1, 0.98])
            translate([-arch_center_x, 0, 0]) dome_outer_solid();
    }

// ---- FLOOR GUSSETS ---------------------------------------------------------
// Filled footprint used to clip the floor slabs. Legs reach only to the CENTRE
// of each rail (rail_foot_half_width - rail_thickness/2), so the gusset ends are
// buried inside the rails — no end rounding needed.
module floor_footprint()
    extrude_along_length() arch_outline(rail_foot_half_width - rail_thickness/2, dome_half_width, springing_height, apex_height, 0);

module floor_gusset(y0, y1, thick, zbase, width)
    intersection() {
        floor_footprint();
        translate([arch_center_x - width/2, y0, zbase])
            cube([width, y1 - y0, thick]);
    }

// ---- the four small parts: each its own positioned / rotated object ---------
// CYAN object = left pin
module cyan_object()
    translate([cyan_x, cyan_y, cyan_z]) rotate(cyan_rotation)
        union() {
            cylinder(r = cyan_radius, h = cyan_length);
            translate([0, 0, cyan_length]) sphere(r = cyan_radius);
        }

// MAGENTA object = left tab
module magenta_object()
    translate([magenta_x, magenta_y, magenta_z]) rotate(magenta_rotation)
        minkowski() {
            cube([magenta_width  - 2*magenta_round,
                  magenta_length - 2*magenta_round,
                  magenta_height - 2*magenta_round], center = true);
            sphere(r = magenta_round, $fn = 24);
        }



// RED object = right pin: cylinder + half-sphere, fully positioned/rotated by its own knobs.
module red_object()
    translate([red_x, red_y, red_z]) rotate(red_rotation)
        union() {
            cylinder(r = red_radius, h = red_length);
            translate([0, 0, red_length]) sphere(r = red_radius);
        }

// PURPLE object = right tab: rounded box, positioned/rotated by its own knobs.
module purple_object()
    translate([purple_x, purple_y, purple_z]) rotate(purple_rotation)
        minkowski() {
            cube([purple_width  - 2*purple_round,
                  purple_length - 2*purple_round,
                  purple_height - 2*purple_round], center = true);
            sphere(r = purple_round, $fn = 24);
        }

// Mask that rounds the bottom edge at the two Y-extremities (front & back).
// Intersecting the model with this fillets those sharp 90-deg edges by end_round.
module end_round_mask() {
    big  = 400;
    ymax = max(magenta_y + magenta_length/2, purple_y + purple_length/2);                 // back-most extremity of the model
    union() {
        translate([arch_center_x - big/2, end_round, 0])
            cube([big, ymax - 2*end_round, big]);          // bottom strip, away from the ends
        translate([arch_center_x - big/2, 0, end_round])
            cube([big, ymax, big]);                        // everything above Z = end_round
        translate([arch_center_x - big/2, end_round, end_round])
            rotate([0,90,0]) cylinder(r = end_round, h = big);             // front-bottom fillet
        translate([arch_center_x - big/2, ymax - end_round, end_round])
            rotate([0,90,0]) cylinder(r = end_round, h = big);             // back-bottom fillet
    }
}

// ============================================================================
//  ASSEMBLY   (red when overlaid with the original grey ghost)
// ============================================================================
// each part is clipped by the end-round mask, then given its own colour so you
// can reference parts by colour. (Colours are preview-only; the STL export is
// the union of all parts, unaffected.)
module clip() render() intersection() { children(); end_round_mask(); }

if (show_reconstruction) {
    color("SteelBlue")   clip() dome();                          // DOME        = blue
    color("Orange")      clip() rails();                         // RAILS       = orange
    color("Lime")        clip() floor_gusset(front_floor_y_start, front_floor_y_end, front_floor_thickness, front_floor_z, front_floor_width); // FRONT FLOOR = bright green
    color("ForestGreen") clip() floor_gusset(back_floor_y_start, back_floor_y_end, back_floor_thickness, back_floor_z, back_floor_width);   // BACK FLOOR = dark green
    color("Magenta")     clip() magenta_object();               // MAGENTA = left tab (own params)
    color("DarkViolet")  clip() purple_object();                // PURPLE = right tab (own params)
    color("Cyan")        clip() cyan_object();                  // CYAN = left pin (own params)
    color("Crimson")     clip() red_object();                   // RED = right pin (own params)
    if (bulge_preview) color(bulge_color) bulge_blank();     // coloured transparent positioning aid
}
