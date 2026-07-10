// =============================================================================
// Palm_left_V2.scad  —  e-NABLE Phoenix palm, parametric reconstruction
// =============================================================================
// Method: RECONSTRUCTION_METHOD.md (feature-fidelity + ghost, measure-never-guess).
// Features + finger linkages measured by parallel agents; simple primitives,
// fuse+subtract. Frame: original recentred X/Y-centred, Z min -> 0 (on plate).
// Aligned ghost: output/orig_aligned.stl. Original bbox X +-41.43, Y +-46, Z 0..30.6.
//
// Parts (each in its own include, fused then bored): the dorsal shell/dome that
// everything ties into, the four finger pivot rings, the thumb mount, the wrist
// ears + side walls + gauntlet back wall, and the perforated palmar floor grid.
// model() unions every part; global pin bores / cable channels are cut per part.
//
// Verification harness (Customizer): show_ghost overlays the original STL;
// section + section_at slice both model and ghost so you can read the interior.
// =============================================================================

include <BOSL2/std.scad>
include <Palm_left_V2_shell.scad>   // dorsal_shell() : regularised arch + cable channels
include <Palm_left_V2_thumb.scad>   // thumb_mount()  : readable primitive lug + bores
include <Palm_left_V2_rings.scad>   // finger_rings() : 4 measured pivot clevises (keyhole)
include <Palm_left_V2_fins.scad>    // finger_fins() + fin_supports() : dorsal shark-fins
include <Palm_left_V2_wrist_back.scad> // wrist_back() : gauntlet back wall (ghost-clip)
$fn = 48;

/* [Display] */
show_ghost  = false;    // overlay the original STL as a transparent ghost
ghost_color = "SkyBlue";// ghost tint (color name or [r,g,b])
ghost_alpha = 0.35;     // ghost opacity 0 (invisible) .. 1 (opaque)

/* [Section] */
section = "off";        // [off, longitudinal, transverse, horizontal]
section_at = 0;         // [-50:0.5:50]

/* [Features] */
show_shell    = false;
show_fins     = false;
show_knuckles = true;
show_thumb    = true;
show_wrist    = true;
show_grid     = true;
debug_colors  = false;   // colour each part distinctly (see what's what); else solid yellow

/* [Hidden] */
ghost_dir = "/home/pec/dev/openscad-parametric-reconstructor/tmp/openscad-projects/palm-left-reconstructed/output";

// =============================================================================
// FEATURE 1 — finger pivot rings (the +Y knuckle eyes/clevises), each measured
// individually (IoU 0.90-0.94). -> Palm_left_V2_rings.scad : finger_rings()
//   link_pinky_ring / link_ring_ring / link_middle_ring / link_index_ring
// =============================================================================

// =============================================================================
// FEATURE 2 — thumb pivot mount (+X): readable primitive lug (STN station table +
// fork SLOT + measured pivot/clevis bores). IoU 0.74. -> Palm_left_V2_thumb.scad
//   module thumb_mount();  (bores baked in — no global cut needed)
// =============================================================================

// =============================================================================
// FEATURE 3 — wrist hinge ears (-Y) + side WALLS (gauntlet) that tie the ears to
// the floor and palm body.
// =============================================================================
EAR_BORE_R = 3.00;   // hinge pin through-bore radius
EAR_CB_R   = 3.88;   // inner counterbore radius (pin head recess)
EAR_CB_D   = 0.90;   // inner counterbore depth
EAR_R      = 7.75;   // ear disc radius
EAR_W      = 5.00;   // ear disc thickness (along X, the pin axis)
EAR_Y      = -38.0;  // ear / hinge centre Y
EAR_Z      = 8.0;    // ear / hinge centre Z
// Ear stations: [centre X, inner-face sign]. Shared by wrist() AND wrist_back()
// (which re-cuts the same bores through its ghost-clip) — keep them in lockstep.
EARS       = [[20.5, -1], [-36.0, +1]];

// One wrist ear: a disc on the X pin-axis, minus the through-bore, minus an inner
// counterbore. inner_sign = which side (+1 / -1) the disc's inner face is toward.
module wrist_ear(cx, inner_sign) {
    inner_face = cx + inner_sign * EAR_W/2;
    difference() {
        translate([cx, EAR_Y, EAR_Z]) rotate([0,90,0]) cylinder(h = EAR_W, r = EAR_R, center = true);
        translate([cx, EAR_Y, EAR_Z]) rotate([0,90,0]) cylinder(h = EAR_W + 2, r = EAR_BORE_R, center = true);
        translate([inner_face - inner_sign*EAR_CB_D/2, EAR_Y, EAR_Z])
            rotate([0,90,0]) cylinder(h = EAR_CB_D, r = EAR_CB_R, center = true);
    }
}
// Side-wall cross-section in the Y-Z plane (measured), rising from the floor up
// toward the dome rim; linear-extruded along X to make a thin gauntlet wall.
WALL_PROFILE = [ [-44,3.1],[-44,13.1],[-42,14.6],[-40,15.6],[-38,16.6],[-36,17.1],[-34,18.1],
                 [-32,19.1],[-30,20.1],[-28,21.0],[-26,21.0],[-26,0.0],[-38,0.0],[-40,0.6],[-42,1.1] ];
// Extrude WALL_PROFILE (drawn in Y-Z) as a wall `thick` deep along X at X=x0.
// The multmatrix is just an axis swap: profile X->world Z, profile Y->world X,
// extrusion height->world Y, so the Y-Z polygon stands up correctly in 3D.
module yz_wall(x0, thick) {
    translate([x0,0,0]) multmatrix([[0,0,1,0],[1,0,0,0],[0,1,0,0],[0,0,0,1]]) linear_extrude(thick) polygon(WALL_PROFILE);
}
// Left + right gauntlet side walls, each pierced by a hinge window on the pin axis.
// wall = [x0, thick].
module wrist_walls() {
    for (wall = [[-38.5,4.5],[18.5,4.0]]) difference() {
        yz_wall(wall[0], wall[1]);
        translate([wall[0]-1, -38, 8]) rotate([0,90,0]) cylinder(h = wall[1]+2, r = 2.5);   // hinge window
    }
}
module wrist() { for (e = EARS) wrist_ear(e[0], e[1]); wrist_walls(); }

// =============================================================================
// FEATURE 4 — perforated palmar floor + basket-weave vent grid (z 0..2)
// =============================================================================
plate_h = 2.0;        // floor plate thickness (z 0..2)
hole_long = 3.21;     // long side of a vent slot
hole_short = 2.13;    // short side of a vent slot
vent_pitch = 4.9;     // centre-to-centre spacing of the vent grid (both axes)
vent_x0 = 0.6;        // vent grid origin X
vent_y0 = -0.9;       // vent grid origin Y
vent_col0 = -6;       // vent column index range (X)
vent_col1 = 3;
vent_row0 = -5;       // vent row index range (Y)
vent_row1 = 4;
floor_outline = [ [24.4,-9.9],[22.8,-41.9],[17.8,-41.9],[17.8,-30.0],[-33.3,-30.0],[-33.3,-41.9],[-38.3,-41.9],[-40.4,3.6],[-37.4,21.9],[-35.5,26.8],[-35.5,33.3],[-31.7,33.3],[-31.7,23.6],[-25.7,23.6],[-25.7,33.3],[-21.7,33.3],[-21.7,39.3],[-17.7,39.3],[-17.7,29.6],[-11.7,29.6],[-11.7,39.3],[-7.7,39.3],[-7.7,36.7],[-5.7,36.7],[-5.7,40.5],[-7.7,40.5],[-7.7,43.3],[-3.7,43.3],[-3.7,33.6],[2.3,33.6],[2.6,43.3],[10.3,43.3],[10.3,33.6],[16.3,33.6],[16.3,43.3],[19.3,43.3],[23.6,21.3],[24.5,7.4],[30.0,6.2],[39.4,-1.6],[36.2,-5.4],[28.2,1.3],[24.3,-3.3],[32.3,-10.0],[29.1,-13.8] ];
FLOOR_CONFORM_Y = 22;   // +Y of this -> clip the floor FRONT to the ghost (conform under the connections)
module palm_floor_grid() {
    // The +Y front plate overhangs the ghost's hollow front underside under the finger
    // connections -> a protruding LEDGE the round discs sit on with a hard 90deg. Ghost-clip
    // ONLY the front band (Y>=FLOOR_CONFORM_Y): deletes the overhang where the ghost is hollow
    // (pinky/ring) and rounds the front edge down to the disc (middle/index). The back/thumb/
    // wrist floor stays the clean parametric plate (no clip -> no tangency slivers).
    intersection() {
        difference() {   // raw perforated flat plate (z 0..2)
            // offset(delta=0.2) grows the outline 0.2mm so the floor overlaps the
            // walls/ears it meets — turns coincident faces into a small overlap, so
            // the union stays watertight/manifold (no zero-thickness shared face).
            linear_extrude(plate_h) offset(delta = 0.2) polygon(floor_outline);
            // basket-weave vents: rectangles alternating orientation row-to-row
            for (col = [vent_col0:vent_col1]) for (row = [vent_row0:vent_row1]) {
                hole_sz = (row % 2 == 0) ? [hole_long, hole_short] : [hole_short, hole_long];
                translate([vent_x0 + vent_pitch*col, vent_y0 + vent_pitch*row, -0.5])
                    linear_extrude(plate_h + 1) square(hole_sz, center = true);
            }
        }
        union() {   // front (Y>=22): conform to ghost ; back: keep raw
            import(ghost_stl, convexity = 8);
            translate([-100, -200, -10]) cube([200, 200 + FLOOR_CONFORM_Y, 100]);
        }
    }
}

// =============================================================================
// MODEL — features fused (union) then global bores subtracted (difference)
// =============================================================================
module model() {
    if (show_shell)    dorsal_shell();
    if (show_knuckles) front_assembly();  // 4 round clevises + dome<->clevis junction (one clip)
    if (show_fins)   { finger_fins(); finger_fin_caps(); }  // ring/middle/index blade + crown cap
    if (show_thumb)    thumb_mount();   // readable primitive lug + bores
    if (show_wrist)  { wrist(); wrist_back(); }  // ears+walls + gauntlet back band
    if (show_grid)     palm_floor_grid();
}
// coloured per-part view (debug_colors) — each feature a distinct colour
module model_colored() {
    if (show_shell)    color("SkyBlue")    dorsal_shell();
    if (show_knuckles) color("Orange") front_assembly();  // connections + dome junction
    if (show_fins)   { color("LimeGreen")  finger_fins(); color("SpringGreen") finger_fin_caps(); }
    if (show_thumb)    thumb_colored();    // thumb sub-parts each a colour (see thumb file)
    if (show_wrist)  { color("Plum") wrist(); color("MediumPurple") wrist_back(); }
    if (show_grid)     color("Khaki")      palm_floor_grid();
}

// ---- output / verification harness -----------------------------------------
module section_cube() {
    b = 300;
    if      (section == "longitudinal") translate([section_at, -b/2, -b/2]) cube(b);
    else if (section == "transverse")   translate([-b/2, section_at, -b/2]) cube(b);
    else if (section == "horizontal")   translate([-b/2, -b/2, section_at]) cube(b);
}
ghost_stl = str(ghost_dir, "/orig_aligned.stl");
module ghost() { if (show_ghost) color(ghost_color, ghost_alpha) children(); }
// Standalone render — suppressed when a driver (e.g. _assembly.scad) sets
// no_assembly=true before `include`-ing this file, so it can call model() itself.
if (is_undef(no_assembly) || !no_assembly) {
if (section == "off") {
    if (debug_colors) model_colored();
    else color([0.95, 0.85, 0.20]) model();
    ghost() import(ghost_stl);   // drawn LAST -> shows as a transparent overlay (not occluded)
} else {
    difference() {
        if (debug_colors) model_colored(); else color([0.95, 0.85, 0.20]) model();
        section_cube();
    }
    ghost() difference() { import(ghost_stl); section_cube(); }
}
}
