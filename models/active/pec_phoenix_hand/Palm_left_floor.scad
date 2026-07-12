include <BOSL2/std.scad>   // for path_sweep (smooth wrist cuff band)
// ============================================================
// Project: e-NABLE Palm (LEFT) — reconstruction of Palm_left.stl
// Fresh start. Ghost only for now; we build the model up from here.
//
// Frame (from the STL, world coords):
//   X: -21.4 .. 61.5   (thumb protrudes on +X)
//   Y: -96.9 .. -4.9   (wrist edge ~Y-89  ->  finger edge ~Y-7)
//   Z:  -2.0 .. 28.6   (open palm rim -> dorsal dome top)
//
// STRUCTURE: ALL parameters first (so the Customizer shows every group),
// then ALL modules, then the assembly call last.
// ============================================================

$fn = 48;
eps = 0.02;

/* [Display] */
show_ghost  = true;
ghost_alpha = 0.55;   // ghost opacity 0 (invisible) .. 1 (opaque) — preview only
ghost_color = "SkyBlue"; // ghost tint — any OpenSCAD color name ("Gainsboro","Tan","Plum"...)
ghost_stl   = "../models/Palm_left.stl";
thumb_xray  = false;  // see-through the green thumb (% modifier) to view the fin/pocket inside.
                      // Preview only; EXCLUDES the thumb from F6 render / STL export.
thumb_disable = true;  // thumb clevis body removed — rebuilding a new way; only the fin+cap (f5) remain
export_part = ""; // "" = full model; else render ONLY one part for analysis/export:
                  // "lug_green","lug_teal","box","cyl","cyl2","bored_green","bored_teal"
/* [Section plane] — slice the model + ghost to inspect inside (e.g. hub alignment) */
section_on   = false;  // enable the cut
section_axis = "x";    // cut plane normal: "x", "y" or "z"
section_pos  = 4.0;    // position of the cut along that axis
section_flip = false;  // keep the other side of the plane

/* [Colors] */
show_colors   = true;
color_ear     = "SteelBlue";       // wrist hinge ears (rings 1-2)
color_knuckle = "Orange";          // finger knuckle prongs (rings 3-9)
color_thumb   = "MediumSeaGreen";  // thumb / green cylinder — half 1 (+ pin-axis side)
color_thumb2  = "Teal";            // green cylinder — half 2 (- pin-axis side)
color_mesh    = "Goldenrod";       // perforated palmar floor / mesh
color_fin     = "Purple";          // clip fins + caps (copied from Proximals.scad)

/* [Ring 1] — a circle with a concentric hole, extruded (LEFT wrist ear) */
ring_x   = -16.0;     // X position (mm)
ring_y   = -89.0;   // Y position (mm)
ring_z   = 6.0;    // Z position (mm)
ring_rx  = 90.0;     // rotation about X (deg)  — tilt the disc
ring_ry  = 0.0;     // rotation about Y (deg)
ring_rz  = 90.0;     // rotation about Z (deg)
ring_r   = 8.0;    // outer radius (mm)
ring_hole_r = 3.0;  // inner hole radius (mm)
ring_h   = 4.6;     // extrude height / thickness (mm)

/* [Ring 2] — replica of Ring 1 (RIGHT wrist ear) */
ring2_x   = 40.6;   // X position (mm)
ring2_y   = -89.0;    // Y position (mm)
ring2_z   = 6.0;      // Z position (mm)
ring2_rx  = 90.0;     // rotation about X (deg)
ring2_ry  = 0.0;      // rotation about Y (deg)
ring2_rz  = 90.0;     // rotation about Z (deg)
ring2_r   = 8.0;     // outer radius (mm)
ring2_hole_r = 3.0; // inner hole radius (mm)
ring2_h   = 4.6;    // extrude height / thickness (mm)

/* [Ring 3] — replica (default: pinky knuckle pin) */
ring3_x   = 26.3;  // X position (mm)
ring3_y   = -11.0;    // Y position (mm)
ring3_z   = 4.0;      // Z position (mm)
ring3_rx  = 90.0;     // rotation about X (deg)
ring3_ry  = 0.0;      // rotation about Y (deg)
ring3_rz  = 90.0;     // rotation about Z (deg)
ring3_r   = 6.0;      // outer radius (mm)
ring3_hole_r = 2.6; // inner hole radius (mm)
ring3_h   = 8.2;     // extrude height / thickness (mm)

/* [Ring 4] — pinky knuckle prong (outer) */
ring4_x   = -13.65;
ring4_y   = -21.0;
ring4_z   = 4.0;
ring4_rx  = 90.0;
ring4_ry  = 0.0;
ring4_rz  = 90.0;
ring4_r   = 6.0;
ring4_hole_r = 2.6;
ring4_h   = 3.7;

/* [Ring 5] — pinky knuckle prong (inner) */
ring5_x   = -4.65;
ring5_y   = -21.0;
ring5_z   = 4.0;
ring5_rx  = 90.0;
ring5_ry  = 0.0;
ring5_rz  = 90.0;
ring5_r   = 6.0;
ring5_hole_r = 2.6;
ring5_h   = 1.7;

/* [Ring 6] — ring-finger knuckle prong (outer) */
ring6_x   = 0.35;
ring6_y   = -15.0;
ring6_z   = 4.0;
ring6_rx  = 90.0;
ring6_ry  = 0.0;
ring6_rz  = 90.0;
ring6_r   = 6.0;
ring6_hole_r = 2.6;
ring6_h   = 3.7;

/* [Ring 7] — ring-finger knuckle prong (inner) */
ring7_x   = 9.35;
ring7_y   = -15.0;
ring7_z   = 4.0;
ring7_rx  = 90.0;
ring7_ry  = 0.0;
ring7_rz  = 90.0;
ring7_r   = 6.0;
ring7_hole_r = 2.6;
ring7_h   = 1.7;

/* [Ring 8] — index/middle knuckle prong 1 */
ring8_x   = 15.35;
ring8_y   = -11.0;
ring8_z   = 4.0;
ring8_rx  = 90.0;
ring8_ry  = 0.0;
ring8_rz  = 90.0;
ring8_r   = 6.0;
ring8_hole_r = 2.6;
ring8_h   = 1.7;

/* [Ring 9] — index/middle knuckle prong 3 */
ring9_x   = 38.15;
ring9_y   = -11.0;
ring9_z   = 4.0;
ring9_rx  = 90.0;
ring9_ry  = 0.0;
ring9_rz  = 90.0;
ring9_r   = 6.0;
ring9_hole_r = 2.6;
ring9_h   = 3.0;

/* [Ring 10] — thumb pin (angled ~50 deg in XY, so rz=138 not 90) */
ring10_x   = 50.4;
ring10_y   = -58.35;
ring10_z   = 3.78;
ring10_rx  = 90.0;
ring10_ry  = 0.0;
ring10_rz  = 140.0;   // axis 50deg (fitted to the thumb pin bore)
ring10_r   = 7.0;
ring10_hole_r = 2.7;   // EXACT bore R2.700 (both clevis prongs RMS 0.000mm)
ring10_h   = 15.5;

/* [Knuckle slots] — the outer prong of each finger clevis has a RECTANGULAR
   slot (not a round pin hole): rings 4, 6, 9. Measured ~6 x 4 mm. */
rect_w = 6.0;   // slot size, ring local X  (-> world Y)
rect_h = 4.0;   // slot size, ring local Y  (-> world Z)

/* [Knuckles 3-9] — each finger-clevis prong = SOLID cylinder + bored pin hole.
   Row: [x, y, z, r, h, htype, ha, hb]  htype 0=round(ha=radius) 1=rect(ha=w, hb=h).
   Same axis as the rings (pin along world X). */
knuckle_subtract = true;  // true = bore the holes; false = draw bore tools to position
knuckle_round    = 1.8;   // corner rounding for stadium part (htype 2 & 3 inner end)
knuckle_stadium_depth = 1.5;  // depth of the inner stadium part (htype 3), along the bore
// htype: 0=round(ha=r) 1=rect(ha=w,hb=h) 2=stadium(ha=w,hb=h) 3=rect+stadium(ha,hb,si=inner dir +/-1)
knuckles = [
    [ 26.30, -11, 4, 6, 8.2, 0, 2.5, 0],       // K3 pinky pin (round) — EXACT cylinder fit R2.500 (RMS 0.000mm = 100% IoU)
    [-13.65, -21, 4, 6, 3.7, 3, 3.9, 6,  1],   // K4 pinky outer (RECT + inner STADIUM)
    [ -4.65, -21, 4, 6, 1.7, 0, 2.5, 0],       // K5 pinky inner (round) — EXACT R2.500 (RMS 0.000mm)
    [  0.35, -15, 4, 6, 3.7, 3, 3.9, 6,  1],   // K6 ring outer (RECT + inner STADIUM)
    [  9.35, -15, 4, 6, 1.7, 0, 2.5, 0],       // K7 ring inner (round) — EXACT R2.500 (RMS 0.000mm)
    [ 15.35, -11, 4, 6, 1.7, 0, 2.5, 0],       // K8 idx/mid prong1 (round) — EXACT R2.500 (RMS 0.000mm)
    [ 38.15, -11, 4, 6, 3.0, 3, 3.9, 6, -1],   // K9 idx/mid prong3 (RECT + inner STADIUM)
];

/* [Bore visualization] — draw each cylindrical bore as a colored PIPE so the bores are visible */
show_bores = true;
color_bore = "Red";

/* [Knuckle saddles] — curved half-pipe (top half-cylinder) bridging each finger's prong
   gap, OPEN at the palmar bottom. Row: [cx, cy, cz, r, len, rotz]. axis along local X. */
saddle_on   = false;  // location TBD — gaps between coaxial pairs measured empty
// each: [cx, cy, cz, r, len, rotz] — full cylinder, axis along local X (pin axis)
saddles = [
    [ -9.0, -21, 4, 4, 9, 0],   // pinky hub (between K4 & K5, coaxial @ pin)
    [  4.85, -15, 4, 4, 9, 0],   // ring hub  (between K6 & K7)
];

/* [Hub rings] — two extra RINGS (tube + hole) to place + size by hand. */
hubring_on = true;
/* [Hub ring A] */
hubA_x   = 13.4;
hubA_y = -11.0;
hubA_z = 4;
hubA_rx  = 90.0;
hubA_ry = 0.0;
hubA_rz = 90.0;
hubA_r   = 6.0;
hubA_hole = 2.5;
hubA_h = 2.2;
color_hubA = "Crimson";

/* [Hub ring B] */
hubB_x   = 11.2;
hubB_y = -12.0;
hubB_z = 4.0;
hubB_rx  = 90.0;
hubB_ry = 0.0;
hubB_rz = 90.0;
hubB_r   = 6.0;
hubB_hole = 2.5;
hubB_h = 2.2;
color_hubB = "DodgerBlue";

/* [Hub ring C] */
hubC_x   = -2.8;
hubC_y = -22.0;
hubC_z = 4.0;
hubC_rx  = 90.0;
hubC_ry = 0.0;
hubC_rz = 90.0;
hubC_r   = 4.0;
hubC_hole = 2.5;
hubC_h = 2.2;
color_hubC = "LimeGreen";

/* [Hub shape + box dims] — each hub: "ring" (uses r/hole) or "box" (uses l x w); hub*_h = length along axis */
hubA_shape = "ring";   hubB_shape = "ring";   hubC_shape = "ring";   // "ring" or "box"
hubA_l = 8.0;  hubA_w = 6.0;   // BOX A: length (local X) x width (local Y)
hubB_l = 8.0;  hubB_w = 6.0;   // BOX B: length x width
hubC_l = 8.0;  hubC_w = 6.0;   // BOX C: length x width

/* [Cord channel bores] — straight cylindrical bores matching the ghost voids (verified 100% IoU).
   Only ce2 & ce5 are closed cylindrical bores; ce1/ce3/ce4 are open grooves (not closed bores). */
cordbore_on = true;
color_cordbore = "Cyan";
cordbore_r = 1.15;
// each channel = traced ghost-corridor centerline (rim -> finger), swept as a tube
/* [Thumb conduit] — refine the thumb cord channel (vertical conduit + bottom branch) */
th_x      = 42.8;   // vertical conduit X
th_y      = -49.2;  // vertical conduit Y
th_top_z  = 18.0;   // conduit mouth Z (where the dorsal run turns 90deg down)
th_bot_z  = 0.0;    // conduit bottom depth  (LOWER = main goes deeper)
th_br_z   = 6.5;    // branch take-off height on the conduit (HIGHER = branch higher)
th_br_end = [45.2, -51.6, 3.5];   // branch end point [x,y,z]

cordbores = concat([
    [[-2.8,-80.8,25.08],[-3.5,-74,24.5],[-4.7,-62.3,23.5],[-6.0,-50.5,22.3],[-7.4,-39.2,19.4],[-8.2,-31.3,12.9],[-8.1,-31.1,5.7],[-10.3,-27.1,-0.2],[-15.5,-30.0,-2.7]], // ce1 pinky
    [[4.5,-80.8,25.78],[4.5,-74,25.5],[4.5,-62.0,25.0],[4.5,-50.1,24.7],[4.5,-38.3,22.8],[5.7,-26.9,20.0],[5.3,-25.7,12.7],[5.7,-24.5,4.2],[7.9,-21.3,-2.7]], // ce2 ring
    [[13.1,-80.8,25.99],[13.5,-74,25.7],[14.2,-62.2,25.2],[15.5,-50.4,25.2],[16.9,-38.7,24.5],[18.4,-27.3,21.9],[19.4,-21.4,16.3],[19.4,-21.4,5.9],[22.1,-17.0,-2.6]], // ce3 middle
    [[19.75,-80.8,26.78],[21.5,-74,26.0],[24.4,-62.7,24.7],[26.6,-51.1,24.4],[29.1,-39.6,22.9],[31.5,-28.4,19.9],[32.8,-21.0,15.1],[33.0,-20.8,5.6],[35.8,-17.6,-2.7]], // ce4 index
], [
    concat([[27.0,-80.8,24.5],[27.0,-72,24.0],[27.5,-60.0,24.0],[30.0,-56.5,23.0],[34.0,-54.5,22.5],[38.0,-52.0,21.0]],
           [[th_x,th_y,th_top_z],[th_x,th_y,th_bot_z]]),   // ce5 thumb: dorsal -> 90deg down -> vertical conduit
    [[th_x,th_y,th_br_z], th_br_end]                       // ce5 bottom branch
]);


/* [Mesh grid] — array of square holes through the perforated palmar floor. */
grid_on    = true;
grid_x0    = -8.7; grid_x1 = 38.0;    // X extent of the array (measured from ghost)
grid_y0    = -76.4; grid_y1 = -24.0;  // Y extent of the array
grid_pitch = 4.9;  // centre-to-centre spacing (mm)  (measured 4.9)
grid_cell  = 2.7;  // square hole side (mm)           (measured 2.7)
grid_zbot  = -4.0;   // prism bottom Z (spans the thin palmar floor plate)
grid_ztop  = 3.0;    // prism top Z

/* [Floor panel] — the PERFORATED PALMAR FLOOR plate (the mesh) at Z ~ -1. */
floor_on     = true;
floor_z      = -1.25; // plate mid height (palmar floor, Z -1.7..-0.2)
floor_thick  = 1.5;   // plate thickness
floor_margin = 4.0;     // overhang beyond the grid array
floor_round  = 1.0;     // light corner rounding (was 8 -> filled the teeth/ear notches)
ear_foot_on    = true;  // fuse the wrist ears down to the floor with a solid foot
ear_foot_reach = 16.0;  // how far the foot reaches from the ear back toward the palm/floor (mm)
ear_trim_on    = true;  // remove floor that sticks out past the ear on the wrist side
knuckle_trim_on = true; // remove floor that sticks out past the knuckles on the finger side

/* [Wrist arch] — wrist cuff: measured arch wall band (outer+inner contour @ Y-80) + cord-exit slot row */
warch_on    = true;
color_warch = "Tan";
warch_y0    = -81.0;  // back (wrist) edge Y = dome back rim (measured)
warch_y1    = -74.0;  // front edge Y (band depth)
warch_zmin  = 12.0;   // arch keeps only the top cap (Z above this); the ear tabs are the side walls below
// measured cross-section: outer arch surface then inner cavity surface -> the wall band
WARCH_OUTER = [ [-18.3,0.3],[-18.7,7.1],[-18.8,9.2],[-18.8,11.3],[-18.8,13.5],[-18.5,15.6],[-17.3,18.6],[-15.4,21.1],[-12.7,23.2],[-7.8,25.3],[1.0,27.3],[12.5,28.5],[22.6,27.4],[31.2,25.6],[36.0,23.8],[40.0,20.8],[42.1,17.9],[43.1,14.1],[43.1,11.7],[43.0,10.1],[43.0,7.9],[42.8,0.4] ];
WARCH_INNER = [ [37.8,0.2],[38.0,5.8],[38.2,12.2],[38.0,14.9],[36.9,17.0],[35.4,18.4],[35.1,18.7],[33.9,19.4],[31.9,20.2],[28.8,21.2],[24.1,22.2],[2.8,22.3],[-1.1,21.9],[-4.2,21.2],[-8.0,20.0],[-10.1,18.9],[-10.7,18.5],[-11.4,17.9],[-13.1,15.8],[-13.6,13.4],[-13.5,8.9],[-13.3,0.5] ];
// cord-exit slot row through the arch top (X centres measured at Y-80)
warch_slots    = false; // (top slots disabled for now — were mis-cut on the top face)
warch_slot_w   = 2.3;   // slot width (X)
warch_slot_len = 6.0;   // slot length (Y)
warch_slot_z   = 24.0;  // slot centre Z
warch_slot_x   = [-2.9, 4.8, 12.5, 20.4, 27.3];

/* [Ear tabs] — wrist-side unit: measured ear-tab/side-wall outline (lobe+pin hole rising into the wall) */
ear_tab_on     = true;
color_eartab   = "Tan";
eartab_th      = 5.0;     // plate thickness (along X, measured)
eartab_round   = 1.5;     // outline corner rounding (smoothing)
eartab_edge    = 1.5;     // 3D edge rounding on the plate faces (mimics the ghost's rounded edges)
eartab_tilt2   = -3.7;    // +X ear plate lean (deg about Y, measured)
eartab_tilt1   = 3.6;     // -X ear plate lean (deg about Y, measured)
ring_ears_show = false;   // old ring ears (redundant now the tabs carry the pin hole)
// measured wrist-tab outlines [worldY, worldZ] (Y<=-70); closed front edge at Y-70 connects to the wall/arch
EARTAB2 = [ [-70.5,-2.0],[-74.2,-2.0],[-77.3,-2.0],[-80.2,-2.0],[-89.3,-2.0],[-90.8,-1.8],[-92.3,-1.2],[-93.7,-0.5],[-94.8,0.6],[-95.8,1.9],[-96.5,3.3],[-96.8,4.8],[-96.9,6.4],[-96.7,7.9],[-96.3,9.2],[-95.6,10.4],[-94.8,11.5],[-93.9,12.3],[-93.1,12.9],[-92.1,13.3],[-89.3,14.5],[-86.5,15.8],[-81.1,18.1],[-80.9,18.4],[-80.8,19.0],[-80.6,19.5],[-80.3,19.9],[-80.1,20.1],[-79.8,20.2],[-79.5,20.2],[-78.0,20.1],[-76.6,20.0],[-75.9,20.0],[-75.0,20.0],[-74.1,20.1],[-73.1,20.2],[-72.5,20.3],[-71.7,20.4],[-71.0,20.4],[-70.4,20.5] ];
EARTAB1 = [ [-70.4,-2.0],[-74.8,-2.0],[-79.4,-2.0],[-88.9,-2.0],[-90.8,-1.8],[-92.3,-1.3],[-93.9,-0.3],[-95.0,0.8],[-96.1,2.4],[-96.6,3.8],[-96.9,5.7],[-96.8,7.3],[-96.3,9.1],[-95.6,10.5],[-94.4,11.9],[-93.3,12.7],[-91.7,13.5],[-88.7,14.8],[-85.8,16.1],[-84.8,16.5],[-81.1,18.1],[-80.9,18.2],[-80.9,18.8],[-80.9,19.1],[-80.8,19.5],[-80.6,19.8],[-80.4,20.2],[-80.1,20.4],[-79.8,20.5],[-79.5,20.6],[-78.1,21.0],[-77.1,21.3],[-76.1,21.6],[-75.4,21.8],[-74.7,22.0],[-73.6,22.3],[-72.7,22.5],[-72.0,22.6],[-71.2,22.8],[-70.4,22.8] ];

/* [Wrist cuff] — single smooth swept band (BOSL2 path_sweep): ear -> arch -> ear, with lobes + pin holes + slots */
cuff_on      = true;
color_cuff   = "Tan";
cuff_t       = 5.0;    // band thickness (radial)
cuff_w       = 7.0;    // band width (Y depth)
cuff_round   = 2.0;    // cross-section corner rounding
cuff_lobe_r  = 8.0;    // ear lobe radius
cuff_lobe_t  = 5.5;    // ear lobe thickness along X (rounded paddle)
cuff_slots   = true;
cuff_slot_w  = 2.3; cuff_slot_len = 6.0; cuff_slot_z = 24.0; cuff_slot_y = -78.0;
cuff_slot_x  = [-2.9, 4.8, 12.5, 20.4, 27.3];
/* [Side walls] — gauntlet side walls flanking the wrist (rise from the floor side edges) */
sidewall_on    = true;
color_sidewall = "Tan";
sidewall_y0    = -74.0;  // back edge (meets the wrist cuff)
sidewall_y1L   = -21.0;  // -X forward extent (clean side, runs toward the knuckles)
sidewall_y1R   = -68.0;  // +X forward extent (stops at the thumb; the thumb wedge is the wall from here)
sidewall_y0R2  = -43.0;  // +X wall resumes forward of the thumb...
sidewall_y1R2  = -21.0;  // ...up toward the knuckles
thumbwall_x    = 49.0;   // +X wall along the thumb: ties the floor edge to the thumb mount
thumbwall_cy   = -56.0;  // centre Y
thumbwall_len  = 28.0;   // Y length (covers Y -42..-70, joins the side-wall segments)
thumbwall_t    = 13.0;   // thickness: bridges floor edge (~X44) into the thumb body (~X55)
sidewall_xmid  = 12.0;   // split between -X and +X sides
sidewall_zbot  = -2.0;   // floor
sidewall_ztop  = 19.0;   // top (where the dome curves in; measured side-wall top ~Z20)
sidewall_t     = 4.5;    // wall thickness

// rim centerline: ear1 -> up -X side -> over arch top -> down +X side -> ear2
CUFF_PATH = [
    [ring_x, ring_y, ring_z], [ring_x, -83, 5],
    [-15,-78,13],[-11,-78,21],[-2,-78,25],[8,-78,26],[18,-78,25],[28,-78,24],[35,-78,20],[39,-78,12],
    [ring2_x, -83, 5], [ring2_x, ring2_y, ring2_z],
];

/* [Thumb clevis] — tapering wedge body + bottom slot (fork) + pivot bore (replaces ring10 green tube) */
thumb_on       = true;   // false = old green cylinder (ring10 tube); true = clevis wedge
thumb_z0       = -2.0;   // wedge bottom Z
thumb_z1       = 17.0;   // wedge top Z
thumb_ang      = 48.0;   // pivot/pin axis angle in XY (deg)
thumb_cx       = 54.6;   // slot + bore centre X
thumb_cy       = -59.0;  // slot + bore centre Y
thumb_slot_w   = 5.0;    // slot gap between the two legs (along pin axis)
thumb_slot_top = 8.5;    // slot cut from the bottom up to this Z (above = solid)
thumb_bore_r   = 2.0;    // pivot bore radius
thumb_bore_z   = 5.0;    // pivot bore Z height
thumb_round    = 1.5;    // footprint edge rounding
thumb_dome_on  = true;   // round the top (intersect wedge with a squashed sphere)
thumb_dome_cx  = 48.0;   // dome centre X (fit to measured top: peak Z17 @X48 -> Z13 @X60)
thumb_dome_cy  = -57.0;  // dome centre Y
thumb_dome_z   = -3.0;   // dome sphere centre Z (top = dome_z + dome_r*dome_sq)
thumb_dome_r   = 20.0;   // dome sphere radius (fit to measured top slope)
thumb_dome_sq  = 1.0;    // dome Z squash (>1 = taller arch, <1 = flatter)
thumb_pocket_on    = true;  // recess in the dome top where fin 5 (clip) nests
thumb_pocket_w     = 4.0;   // pocket width across the fin
thumb_pocket_l     = 8.0;   // pocket length along the fin
thumb_pocket_depth = 3.0;   // pocket floor depth below the fin base
thumb_pocket_round = 1.2;   // pocket corner rounding
thumb_cbore_on     = true;  // square counterbore (recess) around the pin bore on each leg face
thumb_cbore_sq     = 6.0;   // square recess side
thumb_cbore_depth  = 1.5;   // recess depth into the leg face
thumb_cbore_pos    = 8.0;   // distance from centre to the leg outer face (along pin axis)
thumb_botround_on  = false; // round the underside — off: aggressive version collapses the base to a point + breaks floor contact. Ghost bottom is flat inboard, only the outboard beak overhangs.
thumb_botround_r   = 30.0;  // bottom rounding sphere radius (>= footprint half-width)
thumb_botround_sq  = 2;   // bottom rounding Z squash (smaller = gentler round)

/* [Cut cylinder] — red tool cylinder co-located with the green one (ring10).
   Placed/positioned now; will be SUBTRACTED later. */
cut_on  = true;
cut_subtract = true; // true = subtract cut from the green cylinder; false = just draw it red
cut_x   = 51.0;     // same as ring10
cut_y   = -55.8;
cut_z   = 4.6;
cut_rx  = 90.0;
cut_ry  = 0.0;
cut_rz  = 138.0;
cut_r   = 9.0;      // > ring10_r (7) so it fully splits the tube — equal radii leave a sliver
cut_h   = 6.0;     // length along the pin axis (= gap width between the two cylinders)
color_cut = "Red";
/* [Bore tools] — BOX cut from the green (+pin) lug = square hole; CYLINDER cut from the
   other (-pin) lug = round hole. Placed on the pin axis (measured from ghost).
   bore_subtract=false draws them in colour to position; =true subtracts them. */
bore_subtract = true;
// BOX tool (square/rect hole) — ghost square hole ~6x4 @ (55.1,-52.8,3.8)
box_x  = 56; 
box_y = -51.8; 
box_z = 3.8;
box_rx = 90.0; 
box_ry = 90.0;  
box_rz = 138.0;
box_w   = 6;    // hole width  (cross-section)
box_h2  = 4;    // hole height (cross-section)
box_len = 12.0;   // length along the pin axis (spans the 4.7mm lug -> through-hole)
color_box = "Yellow";
// CYLINDER tool (round hole) — ghost round hole d~5 @ (48.8,-60.5,3.8)
borecyl_x  = 47.8; 
borecyl_y = -61.5; 
borecyl_z = 3.8;
borecyl_rx = 90.0; 
borecyl_ry = 0.0;  
borecyl_rz = 138.0;
borecyl_r   = 2.7;   // round hole radius
borecyl_len = 12.0;  // length along the pin axis (spans the 4.7mm lug -> through-hole)
color_borecyl = "Magenta";
// CYLINDER tool 2 — sits NEXT TO the box, also subtracted from the green (+pin) lug
// so that lug's bore = square (box) + round (this) side by side (keyhole)
borecyl2_x  = 54.5;
borecyl2_y  = -51.8;
borecyl2_z  = 3.8;
borecyl2_rx = 90.0;
borecyl2_ry = 0.0;
borecyl2_rz = 138.0;
borecyl2_r   = 2.7;
borecyl2_len = 12.0;  // spans the 4.7mm lug -> through-hole
color_borecyl2 = "Cyan";

/* [Fin shape — shared detail] */
fin_flip_y        = true;   // mirror in Y (Proximals fin points the other way)
fin_top_drop      = 0.0;      // top slope (0 = flat top; was 0.9 = diagonal)
fin_front_chamfer = 0.0;      // front face slope going up (0 = vertical/flat)
fin_rounding      = 0.7;    // fin footprint edge rounding
fin_cap_rounding  = 0.78;   // cap vertical-edge rounding
fin_cap_top_round    = 0.5; // cap top fillet
fin_cap_bottom_round = 0.5; // cap bottom fillet
fin_flat        = true;     // straight (flat) cut on the rear side of fin + cap
fin_flat_y      = -2.5;     // local Y of the flat cut (keeps everything forward of it)
fin_clip_to_cap = true;     // trim the tab to the cap's downward shadow (no overpass)

/* [Fin 1 — pinky] */    // x,y,z position; rotz/tilt orientation; w/len/h fin; cap w/len/h
f1_x=-8.75;
f1_y=-23.5;
f1_z=11.2;
f1_rotz=0.0;
f1_tilt=0.0;
f1_w=2.6;
f1_len=5.0;
f1_h=4.6;
f1_capw=2.8;
f1_caplen=6.6;
f1_caph=1.0;
f1_captilt=24.0;
f1_capx=0.0;
f1_capy=0.0;
f1_capz=-1.0;

/* [Fin 2 — ring] */
f2_x=5.2;
f2_y=-17.5;
f2_z=11.2;
f2_rotz=0.0;
f2_tilt=0.0;
f2_w=2.6;
f2_len=5.0;
f2_h=4.6;
f2_capw=2.8;
f2_caplen=6.6;
f2_caph=1.0;
f2_captilt=24.0;
f2_capx=0.0;
f2_capy=0.0;
f2_capz=-1.0;

/* [Fin 3 — middle] */
f3_x=19.2;
f3_y=-13.5;
f3_z=11.2;
f3_rotz=0.0;
f3_tilt=0.0;
f3_w=2.6;
f3_len=5.0;
f3_h=4.6;
f3_capw=2.8;
f3_caplen=6.6;
f3_caph=1.0;
f3_captilt=24.0;
f3_capx=0.0;
f3_capy=0.0;
f3_capz=-1.0;

/* [Fin 4 — index] */
f4_x=33.0;
f4_y=-13.5;
f4_z=11.2;
f4_rotz=0.0;
f4_tilt=0.0;
f4_w=2.6;
f4_len=6.8;
f4_h=4.6;
f4_capw=2.8;
f4_caplen=6.6;
f4_caph=1.0;
f4_captilt=24.0;
f4_capx=0.0;
f4_capy=0.0;
f4_capz=-1.0;

/* [Fin 5 — thumb] */    // DETECTED feature: centroid X54.9,Y-59.1, top Z15.9, axis 48deg, ~5.6x2.4mm
f5_x=54.6;     // centered on bracket U-slot cavity (measured center 54.6,-59.0)
f5_y=-59.0;
f5_z=12.0;     // base seats fin in the bracket; cap aligns with bracket arch top (z~17)
f5_rotz=51.0;  // along the bracket lean axis (PCA up-dir [0.336,-0.273,0.901])
f5_tilt=26.0;  // leans ~26 deg from vertical to match the bracket's lean
f5_w=2.4;
f5_len=5.6;
f5_h=3.5;
f5_capw=2.6;
f5_caplen=5.5;
f5_caph=1.0;
f5_captilt=5.0;
f5_capx=0.0;
f5_capy=0.0;
f5_capz=0.0;
fin_root=6.0;  // how far the fin post plugs DOWN below its base into the solid (through the relief pocket)

/* [Fin pockets] — rounded-rect seating recess for each fin/cap. Defaults match each fin's
   position + cap footprint; tune per-pocket below. Draw to position, subtract later. */
pocket_on       = true;
pocket_subtract = false;  // false = draw the recess; true = bore it from the body
pocket_round    = 1.2;    // corner rounding of the rounded-rectangle (shared)
pocket_floor_on = true;   // add a closed floor at the bottom of each pocket (blind recess)
pocket_floor_t  = 1.5;    // floor thickness (shared)
color_pocket    = "Tomato";
/* [Fin pocket 1 — pinky] */    // [x,y,z, rotz,tilt, w,len, depth]
fp1_x=-8.7;  
fp1_y=-24.9; 
fp1_z=15.0; 
fp1_rotz=0.0;  
fp1_tilt=0.0;  
fp1_w=5.8; 
fp1_len=10.2; 
fp1_depth=8.0;
/* [Fin pocket 2 — ring] */
fp2_x= 5.3;  
fp2_y=-18.3; 
fp2_z=15.0; 
fp2_rotz=0.0;  
fp2_tilt=0.0;  
fp2_w=5.8; 
fp2_len=10.2; 
fp2_depth=8.0;
/* [Fin pocket 3 — middle] */
fp3_x=19.3;  
fp3_y=-14; 
fp3_z=13.0; 
fp3_rotz=0.0;  
fp3_tilt=0.0;  
fp3_w=5.8; 
fp3_len=10.2; 
fp3_depth=8.0;
/* [Fin pocket 4 — index] */
fp4_x=33.2;  
fp4_y=-14.3; 
fp4_z=13.0; 
fp4_rotz=0.0;  
fp4_tilt=0.0;  
fp4_w=5.6; 
fp4_len=10.2; 
fp4_depth=8.0;
/* [Fin pocket 5 — thumb] */
fp5_x=52.6;  
fp5_y=-56.4; 
fp5_z=13.0; 
fp5_rotz=51.0; 
fp5_tilt=26.0; 
fp5_w=3.4; 
fp5_len=6.0; 
fp5_depth=5.0;

// assembled: [x, y, z, rotz, tilt, w, len, depth]
pockets = [
    [fp1_x,fp1_y,fp1_z, fp1_rotz,fp1_tilt, fp1_w,fp1_len, fp1_depth],
    [fp2_x,fp2_y,fp2_z, fp2_rotz,fp2_tilt, fp2_w,fp2_len, fp2_depth],
    [fp3_x,fp3_y,fp3_z, fp3_rotz,fp3_tilt, fp3_w,fp3_len, fp3_depth],
    [fp4_x,fp4_y,fp4_z, fp4_rotz,fp4_tilt, fp4_w,fp4_len, fp4_depth],
    [fp5_x,fp5_y,fp5_z, fp5_rotz,fp5_tilt, fp5_w,fp5_len, fp5_depth],
];

/* [Hidden] */
// Thumb wedge top-view footprint (world XY): wide base near the palm tapering to
// the +X tip. Measured from the ghost X-stations (X48 Y[-44,-67] -> X60 Y~[-52,-55]).
// measured mound footprint (voxel fill, Z=2): inboard edge X40 (blends to palm),
// outboard "beak" at X60/Y-55, narrowing to X44 at the back (Y-67)
thumb_outline = [
    [40,-45], [40,-67], [44,-68], [54,-64], [60,-55], [56,-48], [52,-45]
];
// Palm-body outline at the floor level (world XY) — EXACT section of the ghost at
// Z-0.9 (simplified 1mm). Follows the real footprint incl. thumb spike, finger
// clevis teeth and wrist-ear bases, so the floor doesn't overhang the ghost.
palm_outline = [
    [44.4,-54.3], [48.2,-49.7], [56.3,-56.5], [59.5,-52.6], [50,-44.8], [44.5,-43.5],
    [43.7,-30.1], [39.3,-7.5], [36.3,-7.5], [36.3,-17.3], [30.3,-17.3], [30.3,-7.5],
    [27.9,-7.5], [22.3,-7.5], [22.3,-17.3], [16.3,-17.3], [16.3,-7.5], [12.3,-7.5],
    [12.3,-10.4], [14.3,-10.4], [14.3,-14.2], [12.3,-14.2], [12.3,-11.5], [8.3,-11.5],
    [8.3,-21.3], [2.3,-21.3], [2.3,-11.5], [-1.7,-11.5], [-1.7,-17.5], [-5.7,-17.5],
    [-5.7,-27.3], [-11.7,-27.3], [-11.7,-17.5], [-15.5,-17.5], [-15.5,-24.1], [-20.4,-47.5],
    [-18.3,-93], [-13.3,-93], [-13.3,-80.9], [37.8,-80.9], [37.8,-93], [42.8,-93],
    [42.7,-75.7], [44.4,-60.9], [49.2,-64.9], [52.4,-61.1],
];
// Mesh-hole region (block + finger-end taper), measured from ghost occupancy.
grid_region = [ [-11,-79],[38,-79],[38,-36],[35,-30],[31,-24],[16,-24],[1,-30],[-11,-36] ];
// extra holes through the floor not covered by the mesh grid: [x, y, size, shape]
// shape 0 = round (d=size), 1 = square (side=size). Measured from the ghost.
extra_holes = [
    [42.7, -49.1, 2.5, 0],   // thumb cord hole (round)
    [-2.7, -22.3, 3.1, 1],   // finger-edge hole (square)
    [11.3, -16.3, 3.1, 1],   // finger-edge hole (square)
];

// ============================================================
//  MODULES
// ============================================================
module tint(c) { if (show_colors) color(c) children(); else children(); }

// A disc of outer radius r with a concentric hole, extruded h thick, placed at
// (x,y,z) and oriented by the three rotations. hole_w>0 -> RECTANGULAR hole.
module ring(x, y, z, rx, ry, rz, r, hole_r, h, hole_w = 0, hole_h = 0) {
    translate([x, y, z])
        rotate([rx, ry, rz])
            linear_extrude(height = h, center = true)
                difference() {
                    circle(r = r);
                    if (hole_w > 0) square([hole_w, hole_h], center = true);
                    else            circle(r = hole_r);
                }
}

// --- Knuckles 3-9: solid cylinder + bore (round or rect), table-driven ---
// placeable hub: "ring" (annulus) or "box" (l x w), height h along the local axis
module hub_draw(shape, x,y,z, rx,ry,rz, h, r,hole, l,w) {
    translate([x,y,z]) rotate([rx,ry,rz])
        if (shape=="box") cube([l,w,h], center=true);
        else linear_extrude(height=h, center=true) difference(){ circle(r); circle(hole); }
}

// cord/tendon channel: a round tube running A -> B (knuckle up the dome to the wrist)
module cordbores_build() {
    if (cordbore_on) color(color_cordbore)
        for (path = cordbores)
            for (i = [0:len(path)-2])
                hull(){ translate(path[i])   sphere(r=cordbore_r,$fn=16);
                        translate(path[i+1]) sphere(r=cordbore_r,$fn=16); }
}


module knuckle_solid(k) {
    translate([k[0], k[1], k[2]]) rotate([90, 0, 90])
        cylinder(r = k[3], h = k[4], center = true, $fn = 48);
}
// bore through the prong (along world X).
// htype 0=round, 1=rect, 2=stadium, 3=rect (outer) + stadium (inner end), stacked along bore.
module knuckle_bore(k) {
    ha = k[6]; hb = k[7];
    translate([k[0], k[1], k[2]]) rotate([90, 0, 90]) {
        if (k[5] == 3) {
            h = k[4]; m = 2; sd = knuckle_stadium_depth; si = k[8];   // si = inner direction (+/-1 along X)
            zr0 = (si > 0) ? -h/2 - m : -h/2 + sd;   // rect (outer/main) span
            zr1 = (si > 0) ?  h/2 - sd :  h/2 + m;
            translate([0, 0, zr0]) linear_extrude(zr1 - zr0) square([ha, hb], center = true);
            zs0 = (si > 0) ?  h/2 - sd : -h/2 - m;   // stadium (inner, rounded) span
            zs1 = (si > 0) ?  h/2 + m  : -h/2 + sd;
            translate([0, 0, zs0]) linear_extrude(zs1 - zs0)
                offset(knuckle_round) offset(-knuckle_round) square([ha, hb], center = true);
        }
        else if (k[5] == 2) linear_extrude(100, center = true)
                                offset(knuckle_round) offset(-knuckle_round) square([ha, hb], center = true);
        else if (k[5] == 1) linear_extrude(100, center = true) square([ha, hb], center = true);
        else                linear_extrude(100, center = true) circle(r = ha, $fn = 32);
    }
}
module knuckles_build() {
    tint(color_knuckle)
        for (k = knuckles)
            difference() { knuckle_solid(k); if (knuckle_subtract) knuckle_bore(k); }
}

// visualize the cylindrical bore holes as colored pipes (solid cylinders filling each bore)
module bore_pipes() {
    color(color_bore) {
        for (k = knuckles) if (k[5]==0)   // round pin bores only (htype 0): K3/K5/K7/K8
            translate([k[0],k[1],k[2]]) rotate([90,0,90]) cylinder(r=k[6], h=k[4]+1.5, center=true, $fn=48);
        translate([ring_x, ring_y, ring_z])    rotate([ring_rx,ring_ry,ring_rz])    cylinder(r=ring_hole_r,   h=ring_h+1.5,   center=true, $fn=48);
        translate([ring2_x,ring2_y,ring2_z])   rotate([ring2_rx,ring2_ry,ring2_rz])  cylinder(r=ring2_hole_r,  h=ring2_h+1.5,  center=true, $fn=48);
        translate([ring10_x,ring10_y,ring10_z]) rotate([ring10_rx,ring10_ry,ring10_rz]) cylinder(r=ring10_hole_r, h=ring10_h+1.5, center=true, $fn=48);
    }
}

// coaxial hub cylinder bridging the two prong circles of a clevis (axis along local X)
module saddle(s) {
    cx = s[0]; cy = s[1]; cz = s[2]; r = s[3]; len = s[4]; rz = s[5];
    translate([cx, cy, cz]) rotate([0, 0, rz]) rotate([0, 90, 0])
        cylinder(r = r, h = len, center = true, $fn = 40);
}
module saddles_build() {
    if (saddle_on) tint(color_knuckle) for (s = saddles) saddle(s);
}

// Array of vertical square prisms = the perforations, clipped to grid_region.
module mesh_grid() {
    nx = floor((grid_x1 - grid_x0) / grid_pitch);
    ny = floor((grid_y1 - grid_y0) / grid_pitch);
    h  = grid_ztop - grid_zbot;
    intersection() {
        union()
            for (i = [0:nx], j = [0:ny])
                translate([grid_x0 + i*grid_pitch, grid_y0 + j*grid_pitch, grid_zbot + h/2])
                    cube([grid_cell, grid_cell, h], center = true);
        translate([0,0,grid_zbot-1]) linear_extrude(height = h+2) polygon(grid_region);
    }
}

// Thumb clevis: tapering wedge body, slotted from the bottom into a 2-leg fork,
// with a pivot bore through both legs along the pin axis. Replaces the green tube.
// Red tool cylinder (to be subtracted later), co-located with ring10.
module cut_cylinder() {
    translate([cut_x, cut_y, cut_z])
        rotate([cut_rx, cut_ry, cut_rz])
            cylinder(r = cut_r, h = cut_h, center = true, $fn = 48);
}

// the green cylinder/clevis, with the red cut tool subtracted when cut_subtract is on
module thumb_body() {
    if (cut_on && cut_subtract) difference() { thumb_or_ring(); cut_cylinder(); }
    else thumb_or_ring();
}

// one side of thumb_body, split by the plane perpendicular to the pin axis at the cut
// centre. side = +1 / -1 selects the two cut cylinders so each can be coloured.
module thumb_half(side) {
    intersection() {
        thumb_body();
        translate([cut_x, cut_y, cut_z]) rotate([cut_rx, cut_ry, cut_rz])
            translate([0, 0, side * 100]) cube(200, center = true);
    }
}

module thumb_or_ring() {
    if (thumb_on) thumb();
    else ring(ring10_x, ring10_y, ring10_z, ring10_rx, ring10_ry, ring10_rz, ring10_r, ring10_hole_r, ring10_h);
}

// --- Two SOLID pin lugs (green-cylinder mode, thumb_on=false) ---
// half-space cube on one side of the cut plane (perpendicular to the pin axis)
module pin_halfspace(side) {
    translate([cut_x, cut_y, cut_z]) rotate([cut_rx, cut_ry, cut_rz])
        translate([0, 0, side * 100]) cube(200, center = true);
}
// SOLID pin cylinder (not a ring), with the gap cut by cut_cylinder
module thumb_solid() {
    difference() {
        translate([ring10_x, ring10_y, ring10_z]) rotate([ring10_rx, ring10_ry, ring10_rz])
            cylinder(r = ring10_r, h = ring10_h, center = true, $fn = 48);
        if (cut_on && cut_subtract) cut_cylinder();
    }
}
// BORE TOOLS (placed on the pin axis): box = square hole, cylinder = round hole
module bore_box() {
    translate([box_x, box_y, box_z]) rotate([box_rx, box_ry, box_rz])
        cube([box_w, box_h2, box_len], center = true);
}
module bore_cyl() {
    translate([borecyl_x, borecyl_y, borecyl_z]) rotate([borecyl_rx, borecyl_ry, borecyl_rz])
        cylinder(r = borecyl_r, h = borecyl_len, center = true, $fn = 32);
}
module bore_cyl2() {
    translate([borecyl2_x, borecyl2_y, borecyl2_z]) rotate([borecyl2_rx, borecyl2_ry, borecyl2_rz])
        cylinder(r = borecyl2_r, h = borecyl2_len, center = true, $fn = 32);
}
// green (+pin) lug = box (square) + cyl2 (round) side by side; teal (-pin) lug = cylinder (round)
module thumb_pins() {
    // render() bakes each CSG lug to a mesh so colours show correctly in preview
    // (multiple coloured difference() siblings otherwise share one colour in OpenCSG).
    color(color_thumb)
        render() difference() { intersection() { thumb_solid(); pin_halfspace(1);  } if (bore_subtract) { bore_box(); bore_cyl2(); } }
    color(color_thumb2)
        render() difference() { intersection() { thumb_solid(); pin_halfspace(-1); } if (bore_subtract) bore_cyl(); }
}

module thumb() {
    difference() {
        intersection() {
            // wedge body, with an optional domed top (intersect with a squashed sphere)
            intersection() {
                translate([0, 0, thumb_z0])
                    linear_extrude(height = thumb_z1 - thumb_z0 + (thumb_dome_on ? 10 : 0))
                        offset(r = thumb_round) offset(r = -thumb_round)
                            polygon(thumb_outline);
                if (thumb_dome_on)
                    translate([thumb_dome_cx, thumb_dome_cy, thumb_dome_z])
                        scale([1, 1, thumb_dome_sq]) sphere(r = thumb_dome_r, $fn = 64);
                else
                    translate([thumb_dome_cx, thumb_dome_cy, -500]) cube(1000, center = true);
            }
            // round the underside: keep inside a squashed sphere (bottom touches z0),
            // hulled up to a big block so only the bottom rounds.
            if (thumb_botround_on)
                hull() {
                    translate([thumb_dome_cx, thumb_dome_cy, thumb_z0 + thumb_botround_r*thumb_botround_sq])
                        scale([1, 1, thumb_botround_sq]) sphere(r = thumb_botround_r, $fn = 64);
                    translate([thumb_dome_cx, thumb_dome_cy, thumb_z0 + thumb_botround_r*thumb_botround_sq + 30])
                        cube([90, 90, 60], center = true);
                }
            else
                translate([thumb_dome_cx, thumb_dome_cy, 500]) cube(1000, center = true);
        }
        // slot -> fork: thin slab along the pin axis, cut from below up to slot_top
        translate([thumb_cx, thumb_cy, (thumb_z0 - 2 + thumb_slot_top) / 2])
            rotate([0, 0, thumb_ang])
                cube([thumb_slot_w, 60, thumb_slot_top - thumb_z0 + 2], center = true);
        // pivot bore through both legs, along the pin axis
        translate([thumb_cx, thumb_cy, thumb_bore_z])
            rotate([0, 0, thumb_ang]) rotate([0, 90, 0])
                cylinder(r = thumb_bore_r, h = 60, center = true, $fn = 32);
        // square counterbore (recess) around the bore on each leg's outer face
        if (thumb_cbore_on)
            for (s = [-1, 1])
                translate([thumb_cx, thumb_cy, thumb_bore_z])
                    rotate([0, 0, thumb_ang]) rotate([0, 90, 0])
                        translate([0, 0, s * (thumb_cbore_pos - thumb_cbore_depth + 10)])
                            cube([thumb_cbore_sq, thumb_cbore_sq, 20], center = true);
        // pocket in the dome top where fin 5 nests (cut in the fin's own frame)
        if (thumb_pocket_on)
            translate([f5_x, f5_y, f5_z]) rotate([f5_tilt, 0, f5_rotz])
                translate([0, 0, -thumb_pocket_depth])
                    linear_extrude(height = thumb_pocket_depth + 40)
                        offset(r = thumb_pocket_round) offset(r = -thumb_pocket_round)
                            square([thumb_pocket_w, thumb_pocket_l], center = true);
    }
}

// Gauntlet side walls: thin wall along the palm-outline side edges, clipped to a Y band and one X side.
module side_wall_one(xside, y0, y1) {   // xside: -1 = -X side, +1 = +X side
    intersection() {
        translate([0, 0, sidewall_zbot])
            linear_extrude(height = sidewall_ztop - sidewall_zbot)
                difference() {
                    offset(r =  sidewall_t/2) polygon(palm_outline);
                    offset(r = -sidewall_t/2) polygon(palm_outline);
                }
        translate([0, (y0 + y1)/2, sidewall_zbot + 200]) cube([600, y1 - y0, 400], center = true);          // Y band
        translate([xside*300 + sidewall_xmid, 0, sidewall_zbot + 200]) cube([600, 600, 400], center = true); // one X side
    }
}
module side_walls() {
    if (sidewall_on) color(color_sidewall) {
        side_wall_one(-1, sidewall_y0, sidewall_y1L);    // -X side wall (runs forward)
        side_wall_one( 1, sidewall_y0, sidewall_y1R);    // +X side wall (back, stops before the thumb)
        side_wall_one( 1, sidewall_y0R2, sidewall_y1R2); // +X side wall (forward of the thumb -> knuckles)
    }
}

// Smooth wrist cuff: one swept band (BOSL2) from ear to ear over the arch, with ear lobes, pin holes, slot row.
module wrist_cuff() {
    if (cuff_on) color(color_cuff)
    difference() {
        union() {
            path_sweep(rect([cuff_t, cuff_w], rounding = cuff_round, $fn = 24), CUFF_PATH);
        }
        translate([ring_x,  ring_y,  ring_z])  rotate([0,90,0]) cylinder(r = ring_hole_r,  h = 40, center = true, $fn = 32);
        translate([ring2_x, ring2_y, ring2_z]) rotate([0,90,0]) cylinder(r = ring2_hole_r, h = 40, center = true, $fn = 32);
        if (cuff_slots) for (sx = cuff_slot_x)
            translate([sx, cuff_slot_y, cuff_slot_z]) cube([cuff_slot_w, cuff_slot_len, 30], center = true);
    }
}

// Wrist-side ear tab: thin plate (Y-Z, extruded along X) = lobe around the pin hulled forward to a
// strip at the arch (floor->dome), minus the pin hole. rotate([90,0,90]): 2D (x,y) -> world (Y,Z), extrude -> X.
module ear_tab(ex, ey, ez, ehole, outline, tilt) {
    if (ear_tab_on) color(color_eartab)
        translate([ex, ey, ez]) rotate([0, tilt, 0]) translate([-ex, -ey, -ez])  // lean to align with the floor
            translate([ex, 0, 0]) rotate([90, 0, 90]) linear_extrude(eartab_th, center = true)
                difference() {
                    offset(r = eartab_round) offset(r = -eartab_round) polygon(outline);  // flat wall plate (2D-smoothed outline)
                    translate([ey, ez]) circle(r = ehole, $fn = 48);                       // simple pin ring hole
                }
}

// Wrist cuff: measured arch wall band (outer curve + inner curve), open palmar bottom, swept along Y, with slot row.
module warch_profile() { polygon(concat(WARCH_OUTER, WARCH_INNER)); }
module wrist_arch() {
    if (warch_on) color(color_warch)
    intersection() {
        difference() {
            translate([0, warch_y1, 0]) rotate([90, 0, 0]) linear_extrude(warch_y1 - warch_y0) warch_profile();
            if (warch_slots)
                for (sx = warch_slot_x)
                    translate([sx, (warch_y0 + warch_y1)/2, warch_slot_z])
                        cube([warch_slot_w, warch_slot_len, 30], center = true);  // vertical cut through the arch top
        }
        translate([0, 0, warch_zmin + 200]) cube([600, 600, 400], center = true);  // keep only the top cap (Z>warch_zmin); ear tabs are the sides
    }
}

// Thin plate following the palm outline (rounded), centred at floor_z.
module floor_panel() {
    translate([0, 0, floor_z])
        linear_extrude(height = floor_thick, center = true)
            offset(r = floor_round) offset(r = -floor_round)   // smooth corners
                polygon(palm_outline);
}

// foot that fuses a raised wrist ear down to the floor: a block bridging from the ear's lower
// solid (below the pin hole) across to the floor, within the ear's X-thickness so it never exceeds the ear.
module ear_foot(ex, ey, eth, ehole, ez) {
    z0 = floor_z - floor_thick/2;   // floor bottom
    z1 = ez - ehole;                // up to just below the pin hole (ear is solid here)
    translate([ex, ey + ear_foot_reach/2, (z0 + z1)/2])
        cube([eth, ear_foot_reach, z1 - z0], center = true);
}

// tool that removes floor sticking out past an ear on the wrist side (Y <= ey),
// while protecting the ear's own outer-cylinder footprint and the palm-side floor.
// dir = +1 trims the -Y (wrist) side (ears); dir = -1 trims the +Y (finger) side (knuckles)
module ear_trim(ex, ey, ez, er, erx, ery, erz, dir) {
    difference() {
        translate([ex, ey - dir*30, ez]) cube([er*2 + 8, 60, er*4], center = true);  // region on the away-from-palm side
        translate([ex, ey, ez]) rotate([erx, ery, erz]) cylinder(r = er, h = 300, center = true, $fn = 72); // protect the cylinder footprint
    }
}

// Extra holes through the floor (round or square), cut vertically.
module extra_floor_holes() {
    for (h = extra_holes)
        translate([h[0], h[1], floor_z])
            if (h[3] == 0) cylinder(d = h[2], h = floor_thick + 2, center = true, $fn = 24);
            else cube([h[2], h[2], floor_thick + 2], center = true);
}

module palm() {
    // thumb: clevis wedge (or the old ring10 tube if thumb_on=false).
    // thumb_xray uses the % background modifier = reliable see-through grey in the GUI
    // (alpha on a CSG result renders opaque/black in preview, so % is the way to peek
    // inside). NOTE: % excludes the thumb from F6 render / STL export — turn it off to export.
    if (thumb_disable) ; // hidden for comparison
    else if (thumb_on) {                         // clevis wedge
        if (thumb_xray)        %thumb_body();
        else if (!show_colors) thumb_body();
        else                   color(color_thumb) thumb_body();
    } else {                                     // two solid pin lugs (round + square holes)
        if (thumb_xray)        %thumb_solid();
        else                   thumb_pins();
    }
    // wrist hinge ears (old rings — superseded by ear tabs)
    if (ring_ears_show) tint(color_ear) {
        ring(ring_x,  ring_y,  ring_z,  ring_rx,  ring_ry,  ring_rz,  ring_r,  ring_hole_r,  ring_h);
        ring(ring2_x, ring2_y, ring2_z, ring2_rx, ring2_ry, ring2_rz, ring2_r, ring2_hole_r, ring2_h);
    }
    // finger knuckle prongs — solid cylinders + bored pin holes (table-driven)
    knuckles_build();
    if (show_bores) bore_pipes();
    saddles_build();
    if (hubring_on) {
        color(color_hubA) hub_draw(hubA_shape, hubA_x,hubA_y,hubA_z, hubA_rx,hubA_ry,hubA_rz, hubA_h, hubA_r,hubA_hole, hubA_l,hubA_w);
        color(color_hubB) hub_draw(hubB_shape, hubB_x,hubB_y,hubB_z, hubB_rx,hubB_ry,hubB_rz, hubB_h, hubB_r,hubB_hole, hubB_l,hubB_w);
        color(color_hubC) hub_draw(hubC_shape, hubC_x,hubC_y,hubC_z, hubC_rx,hubC_ry,hubC_rz, hubC_h, hubC_r,hubC_hole, hubC_l,hubC_w);
    }
    // purple clip fins (5 copies) — each fully parametric (see Fin 1..5 blocks)
    tint(color_fin) {
        place_fin(f1_x,f1_y,f1_z,f1_rotz,f1_tilt) fin(f1_w,f1_len,f1_h,f1_capw,f1_caplen,f1_caph,f1_captilt,f1_capx,f1_capy,f1_capz); // pinky
        place_fin(f2_x,f2_y,f2_z,f2_rotz,f2_tilt) fin(f2_w,f2_len,f2_h,f2_capw,f2_caplen,f2_caph,f2_captilt,f2_capx,f2_capy,f2_capz); // ring
        place_fin(f3_x,f3_y,f3_z,f3_rotz,f3_tilt) fin(f3_w,f3_len,f3_h,f3_capw,f3_caplen,f3_caph,f3_captilt,f3_capx,f3_capy,f3_capz); // middle
        place_fin(f4_x,f4_y,f4_z,f4_rotz,f4_tilt) fin(f4_w,f4_len,f4_h,f4_capw,f4_caplen,f4_caph,f4_captilt,f4_capx,f4_capy,f4_capz); // index
        place_fin(f5_x,f5_y,f5_z,f5_rotz,f5_tilt) fin(f5_w,f5_len,f5_h,f5_capw,f5_caplen,f5_caph,f5_captilt,f5_capx,f5_capy,f5_capz); // thumb
    }
}

// place a fin: position + yaw (rotz) + lean (tilt about X)
module place_fin(x,y,z,rotz,tilt) translate([x,y,z]) rotate([tilt,0,rotz]) children();

// one fin (trapezoid tab + cap lip), built at local origin (base at Z0, centred Y).
// one fin: a plain rectangular post + a slightly larger, short cap on top.
// Primitives only for now (no edge rounding — that comes later).
module fin(w, len, h, capw, caplen, caph, captilt = 0, capx = 0, capy = 0, capz = 0) {
    translate([0, 0, (h - fin_root)/2]) cube([w, len, h + fin_root], center = true);  // post: extruded rectangle, plugs down by fin_root into the solid
    translate([capx, capy, h + capz]) rotate([captilt, 0, 0])
        translate([0, 0, caph/2]) cube([capw, caplen, caph], center = true);  // cap: larger w/len, short h
}

// the cap, placed on top of the fin (offset + tilt)
module cap_placed(top_rear_z, capx, capy, capz, captilt, capw, caplen, caph) {
    translate([0,0,top_rear_z]) translate([capx,capy,capz]) rotate([captilt,0,0])
        fin_cap(capw, caplen, caph);
}

module fin_cap(w, len, h) {
    tr = fin_cap_top_round; br = fin_cap_bottom_round;
    hull() {
        translate([0,0,-h/2+br]) cap_rim(w, len, br);
        translate([0,0, h/2-tr]) cap_rim(w, len, tr);
    }
}

module cap_rim(w, l, r) {
    rr = max(r, 0.001);
    minkowski() {
        linear_extrude(0.01)
            offset(r = fin_cap_rounding) offset(delta = -fin_cap_rounding)
                square([w - 2*rr, l - 2*rr], center = true);
        sphere(r = rr);
    }
}

// rounded-rectangle seating pocket: [x,y,z, rotz,tilt, w,len, depth]
module fin_pocket(p) {
    rr = max(pocket_round, 0.001);
    translate([p[0], p[1], p[2]]) rotate([p[4], 0, p[3]])
        linear_extrude(height = p[7], center = true)
            offset(r = rr) offset(delta = -rr) square([p[5], p[6]], center = true);
}
module fin_pockets() { for (p = pockets) fin_pocket(p); }

// floor slab closing the bottom of a pocket (in the pocket's local frame)
module fin_pocket_floor(p) {
    rr = max(pocket_round, 0.001);
    translate([p[0], p[1], p[2]]) rotate([p[4], 0, p[3]])
        translate([0, 0, -p[7]/2 - pocket_floor_t/2])
            linear_extrude(height = pocket_floor_t, center = true)
                offset(r = rr) offset(delta = -rr) square([p[5], p[6]], center = true);
}
module fin_pocket_floors() { for (p = pockets) fin_pocket_floor(p); }

// ============================================================
//  ASSEMBLY  (must stay last)
// ============================================================
// half-space cube that keeps one side of the section plane
module clip_box() {
    b = 500; o = section_pos + (section_flip ? -b/2 : b/2);
    if      (section_axis == "x") translate([o, 0, 0]) cube(b, center = true);
    else if (section_axis == "y") translate([0, o, 0]) cube(b, center = true);
    else                          translate([0, 0, o]) cube(b, center = true);
}
// full model + ghost (wrapped so the section plane can clip it)
module model_and_ghost() {
    palm();
    cordbores_build();
    if (pocket_on && !pocket_subtract) color(color_pocket) fin_pockets();      // fin/cap seating recesses
    if (pocket_on && pocket_floor_on)  color(color_pocket) fin_pocket_floors(); // closed floor under each pocket
    if (cut_on && !cut_subtract) color(color_cut) cut_cylinder();  // red tool only when not subtracting
    if (!bore_subtract) { color(color_box) bore_box(); color(color_borecyl) bore_cyl(); color(color_borecyl2) bore_cyl2(); }  // bore tools (positioning)
    if (!knuckle_subtract) for (k = knuckles) color("Red") knuckle_bore(k);  // knuckle bore tools (positioning)
    if (floor_on) tint(color_mesh) difference() {
        union() {
            difference() { floor_panel(); mesh_grid(); extra_floor_holes(); }   // perforated floor
            if (ear_foot_on) {
                ear_foot(ring2_x, ring2_y, ring2_h, ring2_hole_r, ring2_z);  // fuse ring2 to the floor
                ear_foot(ring_x,  ring_y,  ring_h,  ring_hole_r,  ring_z);   // fuse ring  to the floor
            }
        }
        if (ear_trim_on) {
            ear_trim(ring2_x, ring2_y, ring2_z, ring2_r, ring2_rx, ring2_ry, ring2_rz, 1);  // trim floor excess past ring2
            ear_trim(ring_x,  ring_y,  ring_z,  ring_r,  ring_rx,  ring_ry,  ring_rz, 1);   // trim floor excess past ring
        }
        if (knuckle_trim_on)
            for (k = knuckles) ear_trim(k[0], k[1], k[2], k[3], 90, 0, 90, -1);  // trim floor excess past each knuckle (finger side)
    }
    wrist_cuff();  // swept cuff band (arch over the top)
    ear_tab(ring2_x, ring2_y, ring2_z, ring2_hole_r, EARTAB2, eartab_tilt2);  // +X wrist wall (flat plate)
    ear_tab(ring_x,  ring_y,  ring_z,  ring_hole_r,  EARTAB1, eartab_tilt1);  // -X wrist wall (flat plate)
    side_walls();  // gauntlet side walls (floor edges up toward the dome)
    // adjustable-transparency ghost; $preview keeps it out of F6 renders / STL exports
    if (show_ghost && $preview) color(ghost_color, ghost_alpha) import(ghost_stl);
}

if (export_part == "") {
    if (section_on) intersection() { model_and_ghost(); clip_box(); }
    else            model_and_ghost();
} else {
    // single-part export for analysis (overlap detection, etc.)
    if (export_part == "lug_green") intersection() { thumb_solid(); pin_halfspace(1); }
    else if (export_part == "lug_teal") intersection() { thumb_solid(); pin_halfspace(-1); }
    else if (export_part == "box")  bore_box();
    else if (export_part == "cyl")  bore_cyl();
    else if (export_part == "cyl2") bore_cyl2();
    else if (export_part == "bored_green") difference() { intersection() { thumb_solid(); pin_halfspace(1);  } bore_box(); bore_cyl2(); }
    else if (export_part == "bored_teal")  difference() { intersection() { thumb_solid(); pin_halfspace(-1); } bore_cyl(); }
}
