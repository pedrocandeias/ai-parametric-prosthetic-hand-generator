// =============================================================================
// Palm_left_V2.scad  —  e-NABLE Phoenix palm, parametric reconstruction
// =============================================================================
// Method: RECONSTRUCTION_METHOD.md (feature-fidelity + ghost, measure-never-guess).
// Features + finger linkages measured by parallel agents; simple primitives,
// fuse+subtract. Frame: original recentred X/Y-centred, Z min -> 0 (on plate).
// Aligned ghost: output/orig_aligned.stl. Original bbox X +-41.43, Y +-46, Z 0..30.6.
//
// SINGLE-FILE build: the former part includes (shell / thumb / rings / fins /
// wrist back) are now fused inline as clearly marked PART sections below, each
// with its own show_* checkbox in the Customizer [Features] tab so any part can
// be switched off independently. model() unions every enabled part; global pin
// bores / cable channels are cut per part.
//
// Verification harness (Customizer): show_ghost overlays the original STL;
// section + section_at slice both model and ghost so you can read the interior.
// =============================================================================

include <BOSL2/std.scad>
$fn = 48;

/* [Features] */
show_shell      = true;   // dorsal shell: regularised arch + cable channels
show_knuckles   = true;   // finger pivot clevises + dome<->clevis junction
show_fins       = true;   // dorsal shark-fin blades + crown caps
show_thumb      = true;   // thumb pivot mount (lug + bores)
show_wrist      = true;   // wrist hinge ears + gauntlet side walls
show_wrist_back = true;   // gauntlet back wall (ghost-clip band)
show_grid       = true;   // perforated palmar floor + vent grid
debug_colors    = false;  // explode the THUMB into its sub-part colours (deep debug)

/* [Colors] */
// one colour per part, so every piece reads separately in the viewer
color_shell      = "SkyBlue";      // dorsal shell
color_knuckles   = "Orange";       // finger clevises + dome junction
color_fins       = "LimeGreen";    // dorsal fins + crown caps
color_thumb      = "Tomato";       // thumb pivot mount
color_wrist      = "Plum";         // wrist ears + side walls
color_wrist_back = "MediumPurple"; // gauntlet back wall
color_floor      = "Teal";         // palmar floor grid

/* [Display] */
show_ghost  = false;    // overlay the original STL as a transparent ghost
ghost_color = "SkyBlue";// ghost tint (color name or [r,g,b])
ghost_alpha = 0.35;     // ghost opacity 0 (invisible) .. 1 (opaque)

/* [Section] */
section = "off";        // [off, longitudinal, transverse, horizontal]
section_at = 0;         // [-50:0.5:50]

/* [Hidden] */
ghost_dir = "/home/pec/dev/openscad-parametric-reconstructor/tmp/openscad-projects/palm-left-reconstructed/output";
ghost_stl = str(ghost_dir, "/orig_aligned.stl");

// =============================================================================
// PART 1 — DORSAL SHELL                                        [show_shell]
// -----------------------------------------------------------------------------
//  Thin arch shell (open underneath) + 5 internal cable channels — FULLY
//  PARAMETRIC, rebuilt with the Cyborg Beast hull-of-primitives technique
//  (see cyborgpalm001.scad :: cyborgbeast07palm): the outer solid is ONE
//  hull() stretched over a few named control primitives (a flattened crown
//  ellipsoid + two thin wall posts per station), the inner cavity is a second,
//  independently shrunk hull subtracted from it, and the functional cuts (the
//  cable channels) come last. The measured AY/AP point-cloud loft is gone; the
//  three control stations below (wrist rim / mid / finger rim) carry the same
//  measured numbers as editable defaults, so the default render still tracks
//  the original envelope — but every number is now a meaningful parameter.
// =============================================================================

/* [Shell] */
SHELL_WALL   = 5.0;    // shell wall thickness (mm)  [4.6 measured; 5.0 covers roof underfill]
CH_R         = 1.23;   // cable-channel bore radius (Ø2.3 mm measured)
CH_STYLE     = "D";    // channel bore cross-section [D:self-supporting D (round floor + chamfered flat ceiling), round:legacy round bore]
CH_BEND_R    = 1.2;    // [0:0.1:2.4] channel corner smoothing (round_corners joint length, mm; 0 = sharp polyline)
CH_SHEATH_WALL = 1.4;  // [0:0.1:3] wall of the printed pipe sheath that carries a channel wherever it leaves the roof material (0 = no sheath)
SHELL_KNEE_Z = 20.0;   // height where the straight side walls end and the crown curve starts
KNEE_R       = 3.5;    // [0:0.5:8] wall->crown fillet radius at the knee (0 = sharp crease)
CROWN_FLAT   = 0.80;   // crown broadness: fraction of the half-span kept nearly flat on top
CROWN_RZ     = 6.0;    // crown vertical rounding (ellipsoid half-height)
CROWN_RY     = 9.0;    // crown rounding along Y (blends the three stations smoothly)

// Control stations (wrist rim -> mid -> finger rim). Defaults = measured envelope.
SHELL_BACK_Y     = -30.0;  // wrist-rim station Y
SHELL_BACK_XL    = -38.5;  // its left (pinky-side) outer wall X
SHELL_BACK_XR    =  23.1;  // its right (thumb-side) outer wall X
SHELL_BACK_APEX  =  29.3;  // its crown apex height
SHELL_MID_Y      =  -5.0;  // widest / tallest station Y
SHELL_MID_XL     = -41.4;
SHELL_MID_XR     =  24.3;
SHELL_MID_APEX   =  30.6;
SHELL_FRONT_Y    =  23.0;  // finger-rim station Y
SHELL_FRONT_XL   = -36.8;
SHELL_FRONT_XR   =  23.5;
SHELL_FRONT_APEX =  26.3;

/* [Hidden] */

/* ---- CABLE CHANNELS (functional routing, wrist -> finger) ----------
   5 bores (radius CH_R) embedded in the crown roof. Each is a centreline
   polyline [x,y,z], smoothed with round_corners and subtracted as a
   path_sweep of ch_profile() — a self-supporting "D" section (round floor,
   chamfered near-flat ceiling; the paraglider / flexible-flyer channel
   technique flipped for our floor-down print orientation, where the bore
   CEILING is the overhang). Shared with front_assembly() and wrist_back(),
   which re-cut the SAME sweeps via cable_channels() — keep all three
   cut sites on that one module so the re-cuts line up.
   z-values track the parametric crown: embedded in the 5 mm roof band
   (>=~0.4 mm clearance to the cavity ceiling and outer roof) back to
   y~16-22, then each channel dives at ~30-45 deg to its measured exit;
   the dive is carried by a printed pipe sheath (cable_channel_sheaths())
   wherever it leaves the roof material, flexible-flyer style.           */
CH = [
  [[-22.9,-32,24.5],[-22.9,-29,25.3],[-25.0,-12,25.8],[-26.6,-1,24.9],[-27.7,12,24.0],[-28.2,16,23.6],[-28.7,20,19.6],[-29.2,23,16.6],[-29.4,26.5,14.8]],  // ch1 pinky (wrist->finger cap)
  [[-15.3,-32,25.8],[-15.3,-30,26.2],[-15.2,-12,27.1],[-15.1,-4,27.0],[-15.0,4,26.3],[-15.0,12,25.4],[-14.9,18,24.6],[-14.9,24,20.0],[-14.9,26.5,19.9]],   // ch2 ring
  [[ -7.5,-32,26.0],[ -7.5,-29,27.1],[ -5.6,-12,27.5],[ -4.3,0,27.2],[ -2.9,12,26.3],[ -2.0,20,24.8],[ -1.6,24,22.6],[ -1.5,26.5,22.4]],                   // ch3 middle
  [[  0.3,-32,25.7],[  0.3,-29,26.5],[  2.7,-18,26.9],[  4.0,-12,26.6],[  6.5,0,25.9],[  9.3,12,24.6],[ 10.1,16,24.1],[ 11.4,22,20.8],[ 11.6,26.5,19.8]],  // ch4 index
  [[  7.2,-32,24.5],[  7.2,-29,25.3],[  7.3,-18,26.0],[  7.4,-12,25.8],[  8.0,-8,25.5],[  8.8,-5,25.3]]                                                     // ch5 wrist stub
];

// Bore cross-section, centred on the path (profile +Y maps to global +Z on
// these mostly-horizontal paths): semicircular floor from [-r,0] through
// [0,-r] to [r,0], then 45-deg chamfers up to a near-flat ceiling at 0.67r —
// the ceiling self-supports when printed floor-down.
function ch_profile(r) = (CH_STYLE == "round") ? circle(r = r) :
    [ for (a = [180 : 15 : 360]) r * [cos(a), sin(a)],       // round floor
      [r, 0.47*r], [0.8*r, 0.67*r], [-0.8*r, 0.67*r], [-r, 0.47*r] ];  // chamfered flat ceiling
// Smoothed centreline (joint length must fit the shortest CH segment / 2)
function ch_path(p) = (CH_BEND_R <= 0) ? p
    : round_corners(p, method = "smooth", joint = CH_BEND_R, closed = false);

// THE one channel cutter — dorsal_shell(), front_assembly() and wrist_back()
// all subtract exactly this, so the re-cuts line up.
module cable_channels() for (p = CH) path_sweep(ch_profile(CH_R), ch_path(p));

// Printed pipe sheath around each channel (flexible-flyer style): a thicker
// D sweep along the same paths, clipped to the outer shell hull plus a front
// strip up to just short of the exits (y 26.2 < 26.5 keeps the mouths open).
// Inside the roof it vanishes into the wall; where a channel leaves the roof
// (the front dives) it becomes a self-supported tube anchored to the roof
// above and the clevis necks / spine below, so the bore never tears an
// open slot through the cavity ceiling.
module cable_channel_sheaths() {
    if (CH_SHEATH_WALL > 0) intersection() {
        union() for (p = CH) path_sweep(ch_profile(CH_R + CH_SHEATH_WALL), ch_path(p));
        union() {
            shell_solid();
            translate([-45, SHELL_Y1 - 2, 0]) cube([75, (26.2 - SHELL_Y1) + 2, 30]);
        }
    }
}

/* ---- the hull-of-primitives arch ----------------------------------- */
SHELL_STATIONS = [
    [SHELL_BACK_Y,  SHELL_BACK_XL,  SHELL_BACK_XR,  SHELL_BACK_APEX ],
    [SHELL_MID_Y,   SHELL_MID_XL,   SHELL_MID_XR,   SHELL_MID_APEX  ],
    [SHELL_FRONT_Y, SHELL_FRONT_XL, SHELL_FRONT_XR, SHELL_FRONT_APEX],
];
SHELL_Y0 = SHELL_BACK_Y;   // rim clip planes: the hull is cut flat at both rims
SHELL_Y1 = SHELL_FRONT_Y;
POST     = 0.6;            // control-post thickness (thin: only its outer face shapes the hull)

// One control station: a flattened crown ellipsoid spanning most of the width
// + two thin wall posts rising to the knee. The global hull() stretches a
// smooth skin over all three stations (the Cyborg Beast idiom).
// inset/drop shrink the station for the cavity copy (walls in, roof down);
// post_z0 lets the cavity posts start below the plate (open bottom).
module shell_station(y, xl, xr, apex, inset = 0, drop = 0, post_z0 = 0, knee_r = KNEE_R) {
    cx = (xl + xr)/2;
    a  = ((xr - xl)/2 - inset) * CROWN_FLAT;
    translate([cx, y, apex - drop - CROWN_RZ])
        scale([a, CROWN_RY, CROWN_RZ]) sphere(r = 1, $fn = 96);
    translate([xl + inset,        y - CROWN_RY, post_z0]) cube([POST, 2*CROWN_RY, SHELL_KNEE_Z - post_z0]);
    translate([xr - inset - POST, y - CROWN_RY, post_z0]) cube([POST, 2*CROWN_RY, SHELL_KNEE_Z - post_z0]);
    // knee fillet: a Y-axis cylinder tangent to each outer wall plane at the
    // knee — the hull wraps wall -> arc -> crown, killing the ~90deg crease.
    // The cavity copy passes knee_r = KNEE_R - SHELL_WALL: same centre
    // (xl_outer + KNEE_R), so the arcs are concentric -> uniform wall.
    if (knee_r > 0) {
        translate([xl + inset + knee_r, y, SHELL_KNEE_Z]) rotate([90, 0, 0])
            cylinder(r = knee_r, h = 2*CROWN_RY, center = true, $fn = 64);
        translate([xr - inset - knee_r, y, SHELL_KNEE_Z]) rotate([90, 0, 0])
            cylinder(r = knee_r, h = 2*CROWN_RY, center = true, $fn = 64);
    }
}

// Outer envelope: hull over the three stations, cut flat at the two rim planes.
module shell_solid()
    intersection() {
        hull() for (s = SHELL_STATIONS) shell_station(s[0], s[1], s[2], s[3]);
        translate([-100, SHELL_Y0, 0]) cube([200, SHELL_Y1 - SHELL_Y0, 100]);
    }

// Inner cavity: the same hull shrunk by SHELL_WALL (posts in, roof down), with
// its posts dropped to z-10 and the end stations pushed past both rims, so the
// subtraction leaves an OPEN bottom and OPEN rim rings (wrist_back and
// front_assembly own the material beyond the rims).
module shell_cavity()
    hull() for (i = [0 : len(SHELL_STATIONS)-1]) {
        s = SHELL_STATIONS[i];
        y = s[0] + (i == 0 ? -8 : (i == len(SHELL_STATIONS)-1 ? 8 : 0));
        shell_station(y, s[1] + SHELL_WALL, s[2] - SHELL_WALL, s[3],
                      inset = 0, drop = SHELL_WALL, post_z0 = -10,
                      knee_r = max(KNEE_R - SHELL_WALL, 0));
    }

module dorsal_shell() {
    difference() {
        union() {
            difference() { shell_solid(); shell_cavity(); }
            cable_channel_sheaths();   // pipes carrying the channel dives through the cavity
        }
        cable_channels();              // cable channels (shared cutter)
    }
}

// =============================================================================
// PART 2 — THUMB PIVOT MOUNT (+X)                              [show_thumb]
// -----------------------------------------------------------------------------
// Built from readable PRIMITIVES (dialed interactively in templates/
// thumb_build.scad against the ghost). IoU 0.74.
// thumb_mount() = union(2 side prongs + deck + back wall + base + fin + cap)
//                 minus the 2 cable channels. Editable: change a number per piece.
// Needs BOSL2 (cuboid / edge constants) — included at the top of this file.
// =============================================================================

// ---- helper primitives ------------------------------------------------------
// box with top+bottom horizontal edges rounded (vertical edges sharp)
module rbox(w, l, h, rnd) {
    r = min(rnd, w/2 - 0.05, l/2 - 0.05, h/2 - 0.05);
    if (rnd > 0) cuboid([w, l, h], rounding = r, edges = ["X", "Y"]);
    else cube([w, l, h], center = true);
}
// box with only the chosen top/bottom edges rounded (tf/tb/bf/bb along Y; tl/tr/bl/br along X)
module rbox_edges(w, l, h, rnd, tf, tb, bf, bb, tl, tr, bl, br) {
    ylim = (tf||tb||bf||bb) ? min(w, h)/2 : 1e9;
    xlim = (tl||tr||bl||br) ? min(l, h)/2 : 1e9;
    r = min(rnd, ylim - 0.05, xlim - 0.05);
    es = [ if (tf) TOP+LEFT, if (tb) TOP+RIGHT, if (bf) BOT+LEFT, if (bb) BOT+RIGHT,
           if (tl) TOP+FWD,  if (tr) TOP+BACK,  if (bl) BOT+FWD,  if (br) BOT+BACK ];
    if (rnd > 0 && len(es) > 0) cuboid([w, l, h], rounding = r, edges = es);
    else cube([w, l, h], center = true);
}
// all-edges-rounded box (the fin cap)
module rcap(w, l, h, rnd) {
    r = min(rnd, w/2 - 0.05, l/2 - 0.05, h/2 - 0.05);
    if (r > 0) cuboid([w, l, h], rounding = r);
    else cube([w, l, h], center = true);
}
// placement wrappers: position (x,y,z), rotate (tilt about Y, yaw about Z), grow-anchor (ax,ay,az)
module gbox(x, y, z, w, l, h, rot, tilt, ax, ay, az, rnd)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([ax*w/2, ay*l/2, az*h/2]) rbox(w, l, h, rnd);
module gbox3(x, y, z, w, l, h, rot, tilt, ax, ay, az, rnd, tf, tb, bf, bb, tl, tr, bl, br)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([ax*w/2, ay*l/2, az*h/2]) rbox_edges(w, l, h, rnd, tf, tb, bf, bb, tl, tr, bl, br);
module gcyl(x, y, z, r, len, rot, tilt, az)
    translate([x, y, z]) rotate([0, tilt, rot]) translate([0, 0, az*len/2]) cylinder(r = r, h = len, center = true, $fn = 48);

// keyhole pin bore: round through prong A, rect slot through prong B (measured)
thumb_bore_c = [28.7, -9.6, 5.8];  thumb_bore_ang = 50.3;   // axis 50.3deg in XY at z5.8
module thumb_bore() {
    translate(thumb_bore_c) rotate([0, 0, thumb_bore_ang]) {
        translate([-1, 0, 0]) rotate([0,90,0]) cylinder(h = 8, r = 2.6, center = true, $fn = 64); // round bore
        translate([11, 0, 0]) cube([8, 3.9, 5.9], center = true);                                  // rect slot
    }
}
// top tool: the dorsal crown is a 2-way curved dome (ghost top rises to z20.5 at the inner
// x23 junction, ~19 over the prongs, ~18 at the +X tip) — a flat cut sheared the crown and
// left the prongs proud. Clip the thumb top to the TRUE ghost dome (the box only bounds it).
module thumb_top_round()
    intersection() {
        translate([24, -4, 11]) cube([60, 64, 46], center = true);   // thumb-region safety bound
        import(ghost_stl);                                           // top follows the real ghost dome
    }

// body fill + shell-wall junction — measured boxes CLIPPED to the ghost (conforms to
// the original surface; keeps the bore/channels open).
// FACE GUARD: the ghost boss is locally FULLER than prong B's flat outer face, so a
// bare ghost-clipped fill used to bulge through that face (triangular wedge facets at
// the prong base) and the old fill-box edge at x38 crossed the prong nose, leaving a
// diagonal seam/step on the flat face. The fill may therefore never pass the prong-B
// outer face plane (normal u = [cos(yaw), sin(yaw)]); where the ghost shoulder crosses
// that plane the clip simply extends the prong's flat face until it meets the dome, so
// prong face -> dome reads as one continuous surface.
THUMB_YAW    = 50;                              // prong yaw (the two gbox3 calls below)
THUMB_FACE_U = 33.5*cos(THUMB_YAW) + 5.0/2;     // prong B outer face plane: c_B·u + thickness/2
module thumb_face_clip()                        // half-space u <= THUMB_FACE_U
    rotate([0, 0, THUMB_YAW]) translate([THUMB_FACE_U - 100, 0, 15]) cube([200, 250, 92], center = true);
module thumb_fill() intersection() {
    translate([30, -4, 10.5]) cube([16, 28, 21], center = true);
    import(ghost_stl);
    thumb_face_clip();
}
module thumb_shell_junction() intersection() { translate([18, -4, 10.5]) cube([ 8, 28, 21], center = true); import(ghost_stl); }

// fin blade + crown: ONE generous rounded envelope centred on the measured blade line
// (34,-7.5,12.5 · tilt 45 · yaw -40 — UNCHANGED: the thumb proximal's clip fin
// continues this line, see _assembly_v2.scad TH_ROT/TH_ROLL). The global ghost
// intersection in thumb_mount() then keeps exactly the ORIGINAL fin surface (blade +
// rounded crown + its base blend into the dome), so the fin grows out of the dome as
// one continuous ridge instead of a boxy blade + separately poking cap rod (the old
// 5x2.5 blade ∩ ghost-fin left the cap emerging through flat facets). Local z runs
// -2 (buried in the dome mass, so the base fuses) .. +6.5 (clear of the crown).
// (local +x is the blade's DESCENDING end — the original fin runs on, down the boss
// face, before fusing into it; the envelope is stretched +4 that way so the ghost
// keeps that whole run and the blade doesn't end in a chopped facet + orphan sliver.)
module thumb_fin()
    translate([34.0, -7.5, 12.5]) rotate([0, 45, -40]) translate([2, 0, 2.25])
        rcap(12, 4.5, 8.5, 1.5);

// ---- the thumb mount --------------------------------------------------------
module thumb_mount() {
  intersection() {
    difference() {
        union() {
            // two clevis side prongs (rounded -Y ends)
            gbox3(27.3, -9.0, 0,  5.2, 19, 20,  50, 0,  0,0,1, 7, false,false,false,false, true,false,true,false); // prong A
            gbox3(33.5,  0.0, 0,  5.0, 17, 20,  50, 0,  0,0,1, 7, false,false,false,false, true,false,true,false); // prong B
            gbox (28.5, -7.5, 18, 10,  8,  1, -40, 50, 1,1,1, 0);   // top deck (bridges the prongs)
            gbox (24.0,  6.0, 0,  2,  10, 19,  90, 0,  0,0,1, 0);   // back wall (+Y)
            gbox (18.0, -4.0, 0,  15,  9,  2,  50, 0,  1,0,1, 0);   // base plate (-> palm)
            thumb_fin();              // fin blade + crown envelope (ghost keeps the original fin)
            thumb_fill();             // body mass (ghost-clipped, face-guarded)
            thumb_shell_junction();   // fuse into the dome +X wall (ghost-clipped)
        }
        gcyl(22.5, 2.0, 0,  1, 23,    0,  0, 1);   // cable channel 1
        gcyl(25.0, 0.0, 6,  1, 15.5, 140, 25, 0);  // cable channel 2
        thumb_bore();                              // keyhole pin bore (round + rect)
    }
    thumb_top_round();                             // round the dorsal top into a dome
  }
}

// ---- coloured view (each part a distinct colour, for identification) --------
module thumb_colored() {
    color("Red")      gbox3(27.3, -9.0, 0,  5.2, 19, 20,  50, 0, 0,0,1, 7, false,false,false,false, true,false,true,false); // prong A
    color("Blue")     gbox3(33.5,  0.0, 0,  5.0, 17, 20,  50, 0, 0,0,1, 7, false,false,false,false, true,false,true,false); // prong B
    color("Orange")   gbox (28.5, -7.5, 18, 10,  8,  1, -40, 50, 1,1,1, 0);   // deck
    color("Purple")   gbox (24.0,  6.0, 0,  2,  10, 19,  90, 0,  0,0,1, 0);    // back wall
    color("Green")    gbox (18.0, -4.0, 0,  15,  9,  2,  50, 0,  1,0,1, 0);    // base plate
    color("Indigo")   intersection() { thumb_fin(); import(ghost_stl); } // fin envelope (shown ghost-clipped, as rendered)
    color("Cyan")     gcyl(22.5, 2.0, 0,  1, 23,    0,  0, 1);   // channel 1 (subtracted)
    color("Magenta")  gcyl(25.0, 0.0, 6,  1, 15.5, 140, 25, 0);  // channel 2 (subtracted)
}

// =============================================================================
// PART 3 — FINGER PIVOT CLEVISES (knuckles, +Y)                [show_knuckles]
// -----------------------------------------------------------------------------
// FULLY PARAMETRIC rebuild with the Cyborg Beast hull-of-primitives technique
// (the PART 1 idiom): every clevis is now a union of per-prong convex hulls
// whose OWN shape is final — the ghost-STL clip (clip_ghost / the junction-band
// intersection) is GONE from this part. All numbers below were MEASURED from
// orig_aligned.stl (0.4 mm voxel occupancy + ray probes; scratchpad
// measure_knuckles.py / analyze_band.py / probe_extra.py).
//
// Measured structure of the band (y 22.7 .. 46):
//   * SEVEN physical prongs carry the four keyholes (middle+index SHARE one
//     prong; each declared keyhole X-band below simply tunnels on through the
//     X-adjacent neighbour prong, exactly as in the original).
//   * Each prong = hull( FOOT disc r5.9 tangent to the plate at z0.1 (EXACT,
//     measured, unchanged) ; 0-2 raised TOP-fill discs sized to the measured
//     top/back reach ; two thin RIM posts at y22.7 whose measured z-ranges
//     reproduce the dome->clevis junction slope ; a rear floor strip where the
//     ghost neck is solid to the plate ). Concave valleys between fingers come
//     free from the union of separate convex prongs.
//   * GAP SLABS (hull of rim posts + a front bar) carry the dome roof over each
//     finger gap up to the measured "window" edge (the open pocket behind each
//     spine bridge), plus the west sliver and the tapering east wall foot.
//   * spine() bridges (rear top rim + window floor) kept as measured cubes.
// KEYHOLE pin passage kept EXACT: round bore r2.5 (z6) / rect slot 4x6, cut
// LAST as before:
//   pinky : slot[-35.5,-31.8] | bore[-25.7,-18.0]  (eye cy30 z6)
//   ring  : slot[-21.5,-17.8] | bore[-11.7, -5.2]  (eye cy36 z6)
//   middle: bore[-11.5,-3.8]  | shared bore[2.5,10.3] (eye cy40 z6)
//   index : shared bore[2.5,10.3] | slot[16.5,19.8]   (eye cy40 z6)
// =============================================================================
// --- KEYHOLE pin-passage dimensions (kept EXACT; functional mating interface) ---
// Each clevis passes the pin through one prong as a round BORE (r=BR) and the
// other as a rect SLOT (SW x SH) so the finger tab can drop in and rotate.
BR = 2.5;     // round pin bore radius (find_holes: r2.50, 100% circularity)
SW = 4.0;     // rect slot width  (Y)
SH = 6.0;     // rect slot height (Z)
CZ = 6.0;     // eye / bore centre Z
// MEASURED disc geometry (ray-cast about (cy, z6) on orig_aligned.stl):
//   exposed face front+bottom (angles 270deg->0->90) = clean circle R_FOOT=5.9 -> disc BOTTOM at
//     z = 6 - 5.9 = 0.1 == TANGENT to the plate (smooth round-to-floor, no chord, no foot).
//   top/back reach beyond R_FOOT is prong-specific and carried by the per-prong
//   TOP-fill discs in KN_PRONGS (all raised so no disc ever plunges sub-floor).
R_FOOT   = 5.9;    // exposed eye disc radius -> bottom tangent to plate at z0.1 (measured-exact)
KN_RIM_Y = 22.0;   // rim-station Y (post CENTRES): 1.0 behind the shell rim plane so the
                   // junction hulls start UNDER the crown skin and emerge near-tangent
                   // through it (kills the recessed seam shadow band)
KN_RIM_T = 0.6;    // front-bar thickness along Y (bar-mode slabs only)
KN_POST_W= 0.6;    // post thickness along X (bar-mode slabs only)
KN_EDGE_R= 0.6;    // [0.5:0.1:3] control-post rounding radius. DEFAULT LOW (crisp
                   // chamfer-style band, per user direction): the dome->clevis skin is
                   // now the KN_RAMPS inclined faces, so the big arcs are off; re-raise
                   // for the old rounded-bar look (then re-probe the rim tops below)
KN_BULGE = 0.0;    // [0:0.1:2] mid-station lift on long slab descents (mm). DEFAULT OFF:
                   // the slabs are now interior fill under the KN_RAMPS inclines — a
                   // bulge would poke through the flat ramp faces (max safe ~0.8)
P2_FRONT = 33.7;   // pinky inner prong front face Y (measured flat truncation, z0..~11)

/* Prong table — one row per PHYSICAL prong (7; middle+index share #6):
   [x0, x1, cy, [rimL_z0,rimL_z1], [rimR_z0,rimR_z1], floor_y0, y_front, tops]
   x0..x1    prong X-band (mm; welded 0.2-0.5 into X-neighbours where measured contiguous)
   cy        pivot / eye centre Y (eye centre = (cy, CZ))
   rimL/rimR rim post z-interval at the seam: z0 = measured GHOST curtain bottom
             (0 -> solid to the plate; >0 -> hanging roof band); z1 = the TOP of
             OUR parametric shell surface at that x, measured on the CURRENT
             shell (KNEE_R fillet included) at y=KN_RIM_Y, minus 0.15 — the
             posts sit just under the crown skin so the junction emerges
             near-tangent, with no step, ledge or shadow band (the ghost dome
             sits 0.2-5 lower in places — smoothness at the shell connection
             wins over raw ghost fidelity here; re-measure these tops if the
             SHELL_FRONT / CROWN / KNEE_R parameters change)
   floor_y0  Y where the neck under-side is measured solid to the plate (rear
             floor strip runs floor_y0 -> cy); KN_RIM_Y = solid all the way back
   y_front   front-face truncation Y (0 = none; only pinky inner is trimmed)
   tops      raised TOP-fill discs [dy_back_from_cy, z_centre, r] sized so the
             hull top tracks the measured neck slope (all bottoms >= z0.4)     */
KN_PRONGS = [                       // (rim tops sampled at the POST-CENTRE x, i.e. x_edge -+ the clamped KN_EDGE_R)
 [-35.5,-31.8, 30, [ 0  ,23.75], [ 0 ,24.7 ], KN_RIM_Y,  0  , []                          ], // 1 pinky outer (slot): pure eye disc, wall-foot rim
 [-25.7,-21.2, 30, [ 0  ,25.5 ], [ 0 ,25.7 ], KN_RIM_Y, P2_FRONT, [[2,12.6,4.2],[4,14.0,4.3]] ], // 2 pinky inner (bore): hood z16.8@y28 + knee z18.3@y26 (fast fall off the rim), front cut y33.7
 [-21.5,-17.8, 36, [ 0  ,25.75], [ 0 ,25.9 ], KN_RIM_Y,  0  , [[2.5,10.4,3.5],[8,13.3,4.5]] ], // 3 ring outer (slot): hood z13.9@y33.5 + knee z17.8@y28
 [-11.7, -7.4, 36, [13.0,26.35], [15.2,26.45], 26.0  ,  0  , [[1.5,12.6,2.5],[4,17,2]]   ], // 4 ring inner (bore): hood z15.1@y34.5 + knee z19@y32
 [ -7.5, -3.8, 40, [15.3,26.45], [17.0,26.45], 27.0  ,  0  , [[2  ,10.8,2.7]]            ], // 5 middle outer (bore): hood z13.5@y38
 [  2.5, 10.3, 40, [17.7,26.0 ], [16.9,25.55], 28.0  ,  0  , [[3  ,8  ,6.5],[4,13.2,4.0]]], // 6 middle/index SHARED (bore): hood z14.5@y37 + knee z17.2@y36
 [ 16.5, 19.8, 40, [12.6,24.9 ], [ 0  ,24.35], 24.5   ,  0  , [[3  ,7.9,6.0]]             ], // 7 index outer (slot): hood z13.9@y37
];

/* Gap-slab table — dome roof / wall material carried over the finger gaps and
   the band's outer corners, each a hull(rear posts @yA, front posts @yB):
   [x0, x1, yA, [zAL0,zAL1], [zAR0,zAR1], yB, [zBL0,zBL1], [zBR0,zBR1]]
   (last entry optional: omitted -> front is one full-height bar).
   ANTI-STAIRCASE RULE: every front-post TOP is set to the height of the
   NEIGHBOURING prong's fall line at (x_edge, yB), so adjacent pieces meet C0
   at both stations — the band reads as one continuous descending surface.
   The concave per-finger window pockets are then CUT by kn_window() (below)
   instead of stair-stepping the slab fronts.                                  */
KN_SLABS = [
 // -- pinky (link 0) --
 [-36.9,-35.2, KN_RIM_Y, [ 0  ,23.05], [ 0 ,23.3 ], 24.7, [ 0  , 6.0], [ 0 ,19.5]], //  0 west sliver: rounded -X corner, east edge matched to pinky-outer fall
 // -- ring (link 1..2): rear + front segment; knee/front tops matched to p3/p4 fall lines --
 [-18.1,-11.4, KN_RIM_Y, [ 2.7,25.95], [12.9,26.3], 26.0, [ 0  ,20.7], [ 0 ,23.6]], //  1 ring gap roof, rear (rim -> knee y26)
 [-18.1,-11.4, 25.8    , [ 0  ,20.7], [ 0  ,23.6], 27.3, [ 0  ,18.7], [ 0 ,22.5]], //  2 ring gap roof, front (knee -> flank edge; window pocket cut by kn_window)
 // -- middle (link 3..4): knee tops matched to p5/p6 fall lines --
 [ -4.1,  2.8, KN_RIM_Y, [17.1,26.4], [17.7,26.05], 25.0, [17.4,24.4], [17.4,24.2]], //  3 middle gap roof, rear segment (apex band -> knee)
 [ -4.1,  2.8, 24.8    , [17.4,24.4], [17.4,24.2], 31.3, [ 0  ,19.0], [ 0 ,20.1]], //  4 middle gap roof, front segment (window pocket cut by kn_window)
 // -- index (link 5..7): rear + front segment + foot; knee tops matched to p6/p7 --
 [ 10.0, 16.8, KN_RIM_Y, [16.7,25.5 ], [13.2,25.05], 26.7, [ 8  ,22.8], [ 6 ,21.3]], //  5 index gap roof, rear (rim -> knee y26.6)
 [ 10.0, 16.8, 26.5    , [ 8  ,22.8], [ 6  ,21.3], 31.2, [ 0  ,20.3], [ 0 ,18.1]], //  6 index gap roof, front (window pocket cut by kn_window; kn_ch4_trench reopens the tendon groove)
 [ 10.0, 16.8, 25.8    , [ 0  , 5.5], [ 0  , 5.5], 29.4, [ 0  ,17.5]             ], //  7 index gap front foot (measured solid-to-plate from y26 under the roof)
 // -- east wall (link 8..9): two bands, shared-edge heights matched --
 [ 19.5, 21.9, KN_RIM_Y, [ 0  ,23.9], [ 0  ,23.25], 34.6, [ 0  ,15.7], [ 0 ,10.5]], //  8 east wall foot, inner band (west edge matched to index-outer fall)
 [ 21.6, 23.5, KN_RIM_Y, [ 0  ,22.75], [ 0 ,21.85], 27.6, [ 0  ,17.5], [ 0 , 9.0]], //  9 east wall foot, outer band (short taper to the ghost corner; east top held UNDER the steep east bevel — the flat-topped r0.6 post spans to x23.5 where the dome is only z21.38)
];

/* Measured per-finger WINDOW POCKETS (the rounded open bites behind each spine
   bridge; open above the z~2.3 window floor which spine()/PART 7 own):
   [centre x, centre y, half-width x, half-depth y]                            */
KN_WINDOWS = [
 [-14.7, 28.4, 1.5, 2.5],   // ring   (measured open y26..30 at x-14.75, closing to y27.5 at the flanks)
 [ -0.3, 31.9, 1.5, 2.3],   // middle (open y30..33 at x-0.65..1, edges solid to y31.5)
 [ 13.0, 31.9, 1.6, 2.3],   // index  (open y30..33 at x12.2..14.2)
];
module kn_window(w)
    translate([w[0], w[1], 2.35]) scale([w[2], w[3], 1]) cylinder(h = 28, r = 1, $fn = 48);
module kn_windows_ring()   kn_window(KN_WINDOWS[0]);
module kn_windows_middle() kn_window(KN_WINDOWS[1]);
module kn_windows_index()  kn_window(KN_WINDOWS[2]);

/* Rear interior curtain (y 18.9 -> 23.0): the ghost dome is not a thin arch at
   the finger side — a measured curtain of material hangs below the roof (and is
   solid to the plate on the pinky/ring and index flanks) between y~18 and the
   junction rim, welding the knuckle band into the palm interior (the old
   ghost-clipped backboxes carried this mass). Same slab format; hidden inside
   the cavity mouth. Skips the pinky window band (x -31.9..-25.5 stops at y19.8
   where the measured window opens).                                           */
KN_CURTAIN = [
 [-35.9,-31.6, 18.9, [ 0  ,20.6], [ 0  ,20.6], 23.0, [ 0  ,20.6]], // pinky outer / -X wall interior
 [-31.9,-25.5, 18.9, [ 0  ,18.6], [ 0  ,18.6], 19.8, [ 0  ,17.5]], // behind the pinky window (window itself stays open y20+)
 [-26.1,-17.6, 18.9, [ 0  ,22.5], [ 0  ,22.5], 23.0, [ 0  ,22.5]], // pinky inner + ring outer curtain (solid to plate)
 [-17.9,-11.5, 18.9, [11.8,22.5], [11.8,22.5], 23.0, [11.8,22.5]], // ring gap hanging curtain
 [-11.9, -5.3, 18.9, [13.9,22.8], [13.9,22.8], 23.0, [13.9,22.8]], // ring inner / middle outer hanging curtain
 [ -5.6,  9.7, 18.9, [17.0,22.8], [17.0,22.8], 23.0, [17.0,22.8]], // crown mid hanging curtain (thicker than the 5mm roof)
 [  9.7, 20.5, 18.9, [ 0  ,21.7], [ 0  ,21.7], 23.0, [ 0  ,21.7]], // index flank / +X wall interior (solid to plate)
];

// measured clearance notch in the pinky inner prong's +X front-bottom corner
// (ghost open x-22.9..-21.1, y27.4.., z~2..8.8; the palmar plate below is PART 7's)
module kn_p2_notch() translate([-22.95, 27.4, 1.9]) cube([1.85, 23, 6.9]);
// ch3/ch4 tendon trenches (measured open grooves in the ghost's gap slopes):
// let the middle/index cable mouths ((-1.5, 26.5, z22.4) / (11.6, 26.5, z19.8))
// emerge to air. The bores themselves stay enclosed by the printed sheath tubes
// (cable_channel_sheaths, part of the shell) which poke through these grooves
// up to y26.2 — flexible-flyer style.
module kn_ch3_trench() translate([-2.9, 24.0, 21.2]) cube([2.6, 8.0, 8]);
module kn_ch4_trench() translate([10.4, 24.2, 19.2]) cube([2.4, 3.2, 8]);

module bore(x0,x1,cy) translate([x0-1,cy,CZ]) rotate([0,90,0]) cylinder(h=x1-x0+2,r=BR);
module slot(x0,x1,cy) translate([x0-1,cy-SW/2,CZ-SH/2]) cube([x1-x0+2,SW,SH]);
module spine(sx0,sx1,cy) {
    translate([sx0-0.4,cy-5.2,13.0]) cube([sx1-sx0+0.8,4.2,2.6]);  // back top rim
    translate([sx0-0.4,cy-10.0, 0.0]) cube([sx1-sx0+0.8,3.2,2.4]); // back floor
}
// ROUNDED control post (the anti-crease primitive): a round-ended vertical
// cylinder centred at (x, y). Every hull edge that leaves it becomes an arc of
// radius re instead of a cube crease; hanging posts (z0 > 0.5) get a rounded
// bottom too. re is clamped by the caller to the element's half-width.
module kn_rpost(x, y, z0, z1, re) {
    h  = max(z1 - z0, 0.5);
    rr = max(min(re - 0.05, h/2 - 0.05), 0);
    translate([x, y, z0])
        cyl(h = h, r = re, rounding2 = rr, rounding1 = (z0 > 0.5 ? rr : 0),
            anchor = BOTTOM, $fn = 36);
}

// One physical prong: convex hull of measured control primitives. The FOOT disc
// is the exact exposed pivot eye (tangent to the plate); the TOP-fill discs give
// the measured top/back reach; the ROUNDED rim posts (centres at KN_RIM_Y,
// tops just under the crown skin) weld the neck into the dome near-tangent;
// the rear floor strip keeps the neck solid to the plate where the ghost is.
// Optional front truncation (pinky inner).
module kn_prong(p) {
    x0 = p[0]; x1 = p[1]; cy = p[2]; w = x1 - x0;
    re = min(KN_EDGE_R, w/2 - 0.05);
    intersection() {
        hull() {
            translate([x0,cy,CZ]) rotate([0,90,0]) cylinder(h=w, r=R_FOOT, $fn=96); // FOOT disc (exact)
            for (t = p[7])
                translate([x0, cy-t[0], t[1]]) rotate([0,90,0]) cylinder(h=w, r=t[2], $fn=64);
            kn_rpost(x0 + re, KN_RIM_Y, p[3][0], p[3][1], re);
            kn_rpost(x1 - re, KN_RIM_Y, p[4][0], p[4][1], re);
            translate([x0, p[5], 0]) cube([w, max(cy - p[5], 1), 0.6]);  // rear floor strip
        }
        translate([x0-1, -50, -1]) cube([w+2, (p[6] > 0 ? p[6] : 100) + 50, 40]); // front face trim
    }
}
// One gap slab: hull(two rear rounded posts, front rounded posts / bar).
// With the optional 8th entry the front is two posts whose tops are matched to
// the neighbouring prongs' fall lines (anti-staircase); without it the front is
// one full-width bar (interior curtain / foot rows). Long descents (> 4.5 mm)
// get an automatic pair of MID posts lifted by KN_BULGE, so the flank curves
// (barrel) instead of being a single flat ruled facet.
module kn_slab(s) {
    re = min(KN_EDGE_R, (s[1] - s[0])/2 - 0.05);
    xl = s[0] + re;  xr = s[1] - re;
    two = len(s) > 7;
    yf  = two ? s[5] + KN_RIM_T - re : s[5];   // keep the tuned forward extreme s[5]+KN_RIM_T
    hull() {
        kn_rpost(xl, s[2], s[3][0], s[3][1], re);
        kn_rpost(xr, s[2], s[4][0], s[4][1], re);
        if (two) {
            kn_rpost(xl, yf, s[6][0], s[6][1], re);
            kn_rpost(xr, yf, s[7][0], s[7][1], re);
            if (yf - s[2] > 4.5) {   // curved flank: bulged mid station
                ym = (s[2] + yf)/2;
                kn_rpost(xl, ym, (s[3][0]+s[6][0])/2, (s[3][1]+s[6][1])/2 + KN_BULGE, re);
                kn_rpost(xr, ym, (s[4][0]+s[7][0])/2, (s[4][1]+s[7][1])/2 + KN_BULGE, re);
            }
        } else
            translate([s[0], s[5], s[6][0]]) cube([s[1]-s[0], KN_RIM_T, max(s[6][1]-s[6][0], 0.4)]);
    }
}

/* --- DIRECT INCLINED TRANSITION FACES (chamfer-style dome->clevis skin) -------
   Per user direction: no rounded hoods — ONE continuous ruled incline per finger
   band, starting ON the crown skin (a line behind the rim, flush with the dome)
   and running straight down/forward to the prong hood/eye crests. Each ramp is a
   hull of: a rear row of small spheres lying ON the dome at y=KN_RAMP_Y0, a rim
   row ON the dome at y=KN_RAMP_Y1 (just inside the SHELL_Y1 clip, so the ramp
   rises OVER the shell's vertical rim face and emerges flush with the crown),
   the landing crest points tangent on the prong hood discs, and two dropped rim
   anchors at z_lo that fill the wedge solid (covers the clip face, kills the
   valley). The old KN_SLABS stay underneath as interior fill; the ramps are the
   visible skin that absorbs them. Dome z values PROBED from the current
   parametric shell_solid() (scratchpad probe_ramp.py) — re-probe if the
   SHELL_FRONT / CROWN / KNEE_R parameters or KN_RAMP_Y0/Y1 change. The pinky
   finger gap (x -31.8..-25.7) stays OPEN (measured window), so the pinky gets
   two prong strips instead of one full-band face.                              */
KN_RAMP_Y0 = 20.5;   // [16:0.1:22.5] ramp start line Y (on the dome, behind the rim)
KN_RAMP_Y1 = 22.9;   // rim row Y, just inside the SHELL_Y1=23 clip plane
KN_RAMP_R  = 0.5;    // [0.2:0.05:1.5] ramp edge rounding (small = crisp chamfer)

/* [y_start, rear row [[x, z_dome]..] @y_start, rim row [[x, z_dome]..] @KN_RAMP_Y1,
   landing crests [[x, y, z]..] (on the prong hood/eye tops), z_lo rim fill]      */
KN_RAMPS = [
 [KN_RAMP_Y0, [[-36.0,23.48],[-34.4,24.25],[-32.3,25.0]], [[-36.0,23.3],[-34.4,24.05],[-32.3,24.75]],
              [[-36.4,24.9,6.3],[-35.4,29.8,11.9],[-31.9,29.8,11.9]],  6.0], // 0 pinky outer strip (sliver + prong 1 -> eye crest; west end inboard of the west knee bevel — x<=-36.4 pokes through it)
 [KN_RAMP_Y0, [[-25.2,25.85],[-21.7,26.1]], [[-25.2,25.5],[-21.7,25.7]],
              [[-25.3,28.0,16.8],[-21.6,28.0,16.8]],                  15.5], // 1 pinky inner strip (prong 2 -> hood crest z16.8@y28; knee disc buried under the chord)
 [KN_RAMP_Y0, [[-21.0,26.15],[-15.0,26.5],[-7.3,26.85]], [[-21.0,25.75],[-15.0,26.15],[-7.3,26.5]],
              [[-21.1,33.5,13.9],[-17.9,33.5,13.9],[-11.6,32.0,19.0],[-7.4,32.0,19.0]], 13.0], // 2 ring band (prongs 3+4 + gap -> hood z13.9@y33.5 / knee z19@y32)
 [KN_RAMP_Y0, [[-7.6,26.85],[-1.0,26.65],[9.8,25.95]], [[-7.6,26.45],[-1.0,26.3],[9.8,25.55]],
              [[-7.1,38.0,13.5],[-4.2,38.0,13.5],[2.9,36.0,17.2],[9.9,36.0,17.2]],      12.8], // 3 middle band (prongs 5+6 + gap -> hood z13.5@y38 / knee z17.2@y36)
 [KN_RAMP_Y0, [[3.0,26.4],[11.0,25.85],[15.0,25.55],[17.0,25.2],[19.3,24.5]], [[3.0,26.0],[11.0,25.5],[15.0,25.2],[17.0,25.0],[19.3,24.4]],
              [[2.9,36.0,17.2],[9.9,36.0,17.2],[16.9,37.0,13.9],[19.4,37.0,13.9]],      13.0], // 4 index band (prongs 6+7 + gap; stops at the east wall band x19.8)
];
module kn_ramp(r) hull() {
    for (p = r[1]) translate([p[0], r[0],        p[1] - KN_RAMP_R - 0.08]) sphere(r = KN_RAMP_R, $fn = 32);
    for (p = r[2]) translate([p[0], KN_RAMP_Y1,  p[1] - KN_RAMP_R - 0.08]) sphere(r = KN_RAMP_R, $fn = 32);
    for (p = r[3]) translate([p[0], p[1],        p[2] - KN_RAMP_R])        sphere(r = KN_RAMP_R, $fn = 32);
    // dropped rim anchors: solid wedge down to z_lo -> the SHELL_Y1 vertical
    // rim face is covered and the crown-front valley is filled (the underside
    // stays >= ~z13 over the finger gaps = the spine bridge band, swing-safe)
    translate([r[2][0][0],           KN_RAMP_Y1, r[4]]) sphere(r = KN_RAMP_R, $fn = 32);
    translate([r[2][len(r[2])-1][0], KN_RAMP_Y1, r[4]]) sphere(r = KN_RAMP_R, $fn = 32);
}

// --- the four clevises --------------------------------------------------------
// Each: union its physical prongs + spine bridge + gap slabs (all parametric,
// no ghost), then cut the keyhole (slot through one prong, bore through other).
module link_pinky_ring() {
    difference() {
        union() {
            kn_prong(KN_PRONGS[0]); kn_prong(KN_PRONGS[1]);
            spine(-31.8,-25.7,30);  kn_slab(KN_SLABS[0]);
            kn_ramp(KN_RAMPS[0]);   kn_ramp(KN_RAMPS[1]);
        }
        slot(-35.5,-31.8,30); bore(-25.7,-18.0,30);
        kn_p2_notch();
    }
}
module link_ring_ring() {
    difference() {
        union() {
            kn_prong(KN_PRONGS[2]); kn_prong(KN_PRONGS[3]);
            spine(-17.8,-11.7,36);  kn_slab(KN_SLABS[1]); kn_slab(KN_SLABS[2]);
            kn_ramp(KN_RAMPS[2]);
        }
        slot(-21.5,-17.8,36); bore(-11.7,-5.2,36);
        kn_windows_ring();
    }
}
module link_middle_ring() {
    difference() {
        union() {
            kn_prong(KN_PRONGS[4]); kn_prong(KN_PRONGS[5]);
            spine(-3.8,2.5,40);
            kn_slab(KN_SLABS[3]); kn_slab(KN_SLABS[4]);
            kn_ramp(KN_RAMPS[3]);
        }
        bore(-11.5,-3.8,40); bore(2.5,10.3,40);
        kn_windows_middle(); kn_ch3_trench();
    }
}
module link_index_ring() {
    difference() {
        union() {
            kn_prong(KN_PRONGS[5]); kn_prong(KN_PRONGS[6]);
            spine(10.3,16.5,40);
            for (i = [5:9]) kn_slab(KN_SLABS[i]);
            kn_ramp(KN_RAMPS[4]);
        }
        bore(2.5,10.3,40); slot(16.5,19.8,40);
        kn_windows_index(); kn_ch4_trench();
    }
}
module finger_rings() { link_pinky_ring(); link_ring_ring(); link_middle_ring(); link_index_ring(); }

// The whole knuckle band as ONE parametric union (prongs + spines + gap slabs
// double as the dome<->clevis junction via their rim posts at KN_RIM_Y), then
// the keyholes and cable channels are subtracted LAST — no ghost clip anywhere.
module front_assembly() {
  difference() {
    union() {
        for (p = KN_PRONGS) kn_prong(p);
        spine(-31.8,-25.7,30); spine(-17.8,-11.7,36);
        spine( -3.8,  2.5,40); spine( 10.3, 16.5,40);
        for (s = KN_SLABS)   kn_slab(s);   // interior fill under the ramps + east/west feet
        for (s = KN_CURTAIN) kn_slab(s);   // rear interior curtain (palm-body weld)
        for (r = KN_RAMPS)   kn_ramp(r);   // direct inclined dome->clevis faces (visible skin)
    }
    kn_p2_notch();
    for (w = KN_WINDOWS) kn_window(w);   // rounded per-finger window pockets
    kn_ch3_trench(); kn_ch4_trench();
    slot(-35.5,-31.8,30); bore(-25.7,-18.0,30);
    slot(-21.5,-17.8,36); bore(-11.7,-5.2,36);
    bore(-11.5,-3.8,40);  bore( 2.5,10.3,40);
    bore( 2.5,10.3,40);   slot(16.5,19.8,40);
    cable_channels();   // keep cable channels open (same cutter as dorsal_shell)
  }
}

// =============================================================================
// PART 4 — DORSAL FINGER FINS (blade) + FIN CAPS (rounded crown)  [show_fins]
// -----------------------------------------------------------------------------
// Measured from the ghost: ring/middle/index each have a back-swept blade with an
// integral rounded crown (the crown is the blade's narrowed teardrop top, split
// into finger_fin_caps() — NOT a wider thumb-style overhang). PINKY has no fin.
// =============================================================================

// [ name, xc, yf(front face Y), base_z, shoulder_z, peak_z, depth(Y), thk(X) ]
finger_fins_tbl = [
    [ "pinky",  -28.75, 24.40, 13.0, 16.00, 18.35, 5.50, 2.85 ],  // smaller, shifted back/down
    [ "ring",   -14.80, 30.32, 13.0, 16.23, 18.51, 5.68, 2.85 ],
    [ "middle",  -0.80, 34.32, 13.0, 16.23, 18.51, 5.68, 2.85 ],
    [ "index",   13.20, 34.32, 13.0, 16.23, 18.51, 5.68, 2.85 ],
];
fin_round   = 0.7;   // 2D edge rounding (vertical edges + crown)
fin_peak_dy = 0.38;  // crown apex offset in +Y from the front face
cap_overlap = 0.8;   // crown roots this far down into the blade (clean seam)

// A Y-Z polygon profile, extruded `thk` along X (the blade is thin in X). The
// offset(r)/offset(-r) pair rounds the 2D outline's corners by fin_round before
// extruding (grow-then-shrink leaves rounded convex corners, sharp footprint).
module _fin_extrude(xc, yf, base_z, thk, pts)
    translate([xc, yf, base_z]) rotate([90, 0, 90]) translate([0, 0, -thk/2])
        linear_extrude(height = thk) offset(r = fin_round) offset(delta = -fin_round) polygon(pts);

// Lower blade: a rectangle from the base up to the shoulder (heights are local,
// measured up from base_z).
module fin_blade(xc, yf, base_z, shoulder_z, depth, thk) {
    shoulder_h = shoulder_z - base_z;
    _fin_extrude(xc, yf, base_z, thk, [[0,0], [depth,0], [depth,shoulder_h], [0,shoulder_h]]);
}
module finger_fins() { for (f = finger_fins_tbl) fin_blade(f[1],f[2],f[3],f[4],f[6],f[7]); }

// Crown cap: the teardrop top of the blade. Roots cap_overlap below the shoulder
// (clean seam into the blade) and tapers to a peak pulled fin_peak_dy in +Y.
module fin_cap(xc, yf, base_z, shoulder_z, peak_z, depth, thk) {
    root_h = shoulder_z - base_z - cap_overlap;
    peak_h = peak_z - base_z;
    _fin_extrude(xc, yf, base_z, thk,
        [[0,root_h], [depth,root_h], [depth, shoulder_z-base_z], [fin_peak_dy, peak_h]]);
}
module finger_fin_caps() { for (f = finger_fins_tbl) fin_cap(f[1],f[2],f[3],f[4],f[5],f[6],f[7]); }

// =============================================================================
// PART 5 — WRIST HINGE EARS (-Y) + SIDE WALLS (gauntlet)        [show_wrist]
// -----------------------------------------------------------------------------
// The hinge ears + the thin side walls that tie the ears to the floor and palm
// body.
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
// PART 6 — WRIST CUFF: back band + shell->band inclined planes [show_wrist_back]
// -----------------------------------------------------------------------------
//  FULLY PARAMETRIC replacement of the old ghost-clip wrist_back(): the last
//  import(ghost_stl) in the model geometry is GONE. Two jobs in one part:
//
//  1) BAND SLABS — the ghost band is just the two thick side bands that carry
//     the hinge ears (the middle is the open wrist mouth). Each slab is a
//     yz_wall() extrusion of the SAME measured WALL_PROFILE as the PART 5 thin
//     walls, but at the band's MEASURED x-envelope (trimesh ray probes on
//     orig_aligned.stl: left x -38.5..-33.5, right x 18.0..23.0, tops z~20 at
//     y-30 falling to ~13 at y-44) — the thin walls under-filled these by
//     0.5..1.0 mm. The PART 5 ear discs close the rounded tips beyond y-44.
//
//  2) WRIST RAMPS — direct inclined transition planes (the PART 3 KN_RAMPS
//     idiom mirrored to the BACK rim, per user direction): the shell used to
//     stop at the SHELL_Y0=-30 clip with an exposed ~90 deg vertical rim face
//     and a recessed channel next to the band. Each ramp span is one hull of
//     small spheres — a rear row lying ON the crown skin at WR_RAMP_Y0, a rim
//     row ON the skin just inside the clip plane (both PROBED from the current
//     parametric shell — scratchpad probe_shell.py; re-probe if the SHELL_BACK
//     / CROWN / KNEE_R parameters change), a landing row on the band tops /
//     visor lip, and dropped rim anchors that fill the wedge down to the
//     cavity ceiling — so the vertical face and the recess disappear under
//     crisp ruled inclines. Five C0-continuous spans (shared seam points):
//       side L (wall->ear) | corner L | centre W + centre E (crown visor,
//       lip held at z24 ~ the cavity ceiling so the WRIST MOUTH keeps its
//       full original entry height) | corner R | side R (wall->ear).
//
//  Functional voids are re-cut EXACTLY as the old ghost-clip band did:
//    - one r=EAR_BORE_R tunnel per ear along X (EAR_Y,EAR_Z): clears the lug
//      bore AND the wall hinge window (same axis). The tunnel is wider than
//      the r2.5 wall window, but the union with the parametric wall (solid in
//      the r2.5..r3 annulus) restores the measured r2.5 window.
//    - the inner counterbores (EAR_CB_R/EAR_CB_D at the EARS inner faces —
//      snap-pin + cup-washer seats, unchanged).
//    - the shared cable_channels() PLUS straight entry extensions
//      (wr_channel_entries): the centre ramps now wrap past the CH y=-32
//      entry points, so each bore is extended backward along its own first
//      segment to keep the mouths open where they emerge through the incline.
// =============================================================================

/* [Wrist cuff] */
WR_RAMP_Y0 = -26.5;  // [-29:0.1:-24] ramp start line Y (on the crown, before the rim)
WR_RAMP_Y1 = -29.9;  // rim row Y, just inside the SHELL_Y0=-30 clip plane
WR_RAMP_R  = 0.6;    // [0.2:0.05:1.5] ramp edge rounding (small = crisp chamfer)
WR_LIP_Y   = -33.0;  // crown visor lip Y (how far the centre incline reaches back)
WR_LIP_Z   = 24.0;   // crown visor lip Z (~cavity ceiling: keeps the mouth entry open)
WR_LAND_Y  = -34.5;  // side-span landing Y on the band tops (before the ears)
WR_LAND_Z  = 17.8;   // side-span landing Z (band top at WR_LAND_Y minus 0.05 tuck)

/* [Hidden] */
// Band slabs [outer x0, thickness]: measured ghost band x-envelopes
// (left -38.5..-33.5, right 18.0..23.0), inset 0.02 per side so the slab
// faces are not EXACTLY coplanar with the PART 5 ear-disc / thin-wall faces
// on the same planes (triple-coincident faces degrade the exported mesh).
WBAND = [ [-38.48, 4.96], [18.02, 4.96] ];

/* Ramp spans [rear row [[x,z]] @WR_RAMP_Y0, rim row [[x,z]] @WR_RAMP_Y1,
   landing [[x,y,z]], rim anchors [[x,z]] @WR_RAMP_Y1, optional x-clip [x0,x1]].
   All z on the rear/rim rows = probed shell-skin heights; anchor z = local
   cavity-ceiling/band-top minus a 0.3..0.8 weld so no sliver of the old rim
   face survives below the wedge. Seam x-stations are SHARED between adjacent
   spans (C0: one continuous skin).                                          */
WR_RAMPS = [
 [[[-38.2,23.0],[-36.0,24.12],[-33.6,25.16]], [[-38.2,22.8],[-36.0,23.93],[-33.6,24.88]],
  [[-38.2,WR_LAND_Y,WR_LAND_Z],[-33.7,WR_LAND_Y,WR_LAND_Z]], [[-38.2,19.3],[-33.7,19.3]],
  [-38.5,-10]],                                                              // side L: wall -> left ear band
 [[[-33.6,25.16],[-28.5,26.85]], [[-33.6,24.88],[-28.5,26.57]],
  [[-33.7,WR_LAND_Y,WR_LAND_Z],[-28.5,WR_LIP_Y,WR_LIP_Z]], [[-33.7,19.8],[-28.5,21.5]]], // corner L: band top -> visor lip twist
 [[[-28.5,26.85],[-22.0,28.43],[-15.0,29.25],[-7.7,29.50]],
  [[-28.5,26.57],[-22.0,28.22],[-15.0,29.05],[-7.7,29.32]],
  [[-28.5,WR_LIP_Y,WR_LIP_Z],[-7.7,WR_LIP_Y,WR_LIP_Z]], [[-28.5,21.5],[-7.7,23.65]]],    // centre W: crown visor (pinky half)
 [[[-7.7,29.50],[0,29.19],[7,28.31],[12.9,26.81]],
  [[-7.7,29.32],[0,29.02],[7,28.13],[12.9,26.61]],
  [[-7.7,WR_LIP_Y,WR_LIP_Z],[12.9,WR_LIP_Y,WR_LIP_Z]], [[-7.7,23.65],[12.9,21.4]]],      // centre E: crown visor (index half)
 [[[12.9,26.81],[17.9,25.05]], [[12.9,26.61],[17.9,24.85]],
  [[12.9,WR_LIP_Y,WR_LIP_Z],[18.2,WR_LAND_Y,WR_LAND_Z]], [[12.9,21.4],[17.9,19.8]]],     // corner R: visor lip -> band top twist
 [[[18.3,24.90],[20.7,23.70],[22.7,22.45]], [[18.3,24.71],[20.7,23.61],[22.7,22.27]],
  [[18.2,WR_LAND_Y,WR_LAND_Z],[22.7,WR_LAND_Y,WR_LAND_Z]], [[18.3,19.3],[22.7,19.3]],
  [10,23.0]],                                                                // side R: wall -> right ear band
];

// One inclined span: hull(rear row ON the skin, rim row ON the skin, landing
// row, dropped rim anchors). Rows follow the kn_ramp sphere idiom (centres
// tucked R+0.08 under the skin / R under the landing). The optional x-clip
// keeps the outer spans flush with the wall/band outer planes.
module wr_ramp_hull(r) hull() {
    for (p = r[0]) translate([p[0], WR_RAMP_Y0, p[1] - WR_RAMP_R - 0.08]) sphere(r = WR_RAMP_R, $fn = 32);
    for (p = r[1]) translate([p[0], WR_RAMP_Y1, p[1] - WR_RAMP_R - 0.08]) sphere(r = WR_RAMP_R, $fn = 32);
    for (p = r[2]) translate([p[0], p[1],      p[2] - WR_RAMP_R])         sphere(r = WR_RAMP_R, $fn = 32);
    for (p = r[3]) translate([p[0], WR_RAMP_Y1, p[1]])                    sphere(r = WR_RAMP_R, $fn = 32);
}
module wr_ramp(r) {
    if (len(r) > 4) intersection() {
        wr_ramp_hull(r);
        translate([r[4][0], -60, -10]) cube([r[4][1] - r[4][0], 60, 60]);
    } else wr_ramp_hull(r);
}

// Straight backward extension of each cable-channel entry: the profile (shrunk
// 0.02 so its lateral walls sit strictly INSIDE the main bore — co-surface
// sweeps would leave degenerate slivers in the mesh) swept backward along the
// bore's own first-segment direction, overlapping 1.0 forward into the main
// cable_channels() void. Keeps the y=-32 entries open where the centre ramps
// now wrap behind them; the 0.02 step at the hand-off is invisible.
module wr_channel_entries() for (p = CH) {
    u = unit(p[1] - p[0]);
    path_sweep(ch_profile(CH_R - 0.02), [p[0] - 3.5*u, p[0] + 1.0*u]);
}

module wrist_back() {
    difference() {
        union() {
            for (b = WBAND) yz_wall(b[0], b[1]);   // parametric band slabs (ghost clip GONE)
            for (r = WR_RAMPS) wr_ramp(r);         // shell -> band inclined planes
        }
        // --- keep the 2 hinge bores + counterbores + windows OPEN (as before) ---
        for (ear = EARS) {
            cx = ear[0]; inner_sign = ear[1];
            translate([cx, EAR_Y, EAR_Z]) rotate([0,90,0])
                cylinder(h = 40, r = EAR_BORE_R, center = true);                  // through bore
            inner_face = cx + inner_sign*EAR_W/2;
            translate([inner_face - inner_sign*EAR_CB_D/2, EAR_Y, EAR_Z]) rotate([0,90,0])
                cylinder(h = EAR_CB_D, r = EAR_CB_R, center = true);              // inner counterbore
        }
        // --- keep the cable-channel entries OPEN ---
        cable_channels();      // same cutter as dorsal_shell / front_assembly
        wr_channel_entries();  // straight entry extensions through the ramps
    }
}

// =============================================================================
// PART 7 — PERFORATED PALMAR FLOOR + basket-weave vent grid (z 0..2) [show_grid]
// -----------------------------------------------------------------------------
//  Fully PARAMETRIC rebuild (Palm_left_floor.scad :: floor_panel technique —
//  a thin plate extruded from a 2D outline smoothed with an offset() chain).
//  The measured 45-point floor_outline and the ghost-STL front clip are GONE.
//  The footprint is now a UNION of named primitives, each anchored to the
//  part it mates with (the old outline's coordinates survive as defaults):
//    - body       : corner-station polygon (left bulge/knee, rims, thumb notch)
//    - aprons     : one per finger clevis (PART 3 spans), stopping floor_clear
//                   behind the pivot line cy so the curling finger can swing
//    - front tabs : one strip per clevis prong, DERIVED from KN_PRONGS
//    - wrist tabs : derived from the hinge-ear stations (PART 5 EARS)
//    - thumb pads : two angled pads under the thumb-mount prongs (PART 2)
//  The union is smoothed by CLOSE (concave fillet) then OPEN (convex round)
//  -> one smooth outline, no jagged point cloud, no ghost dependency.
//  FLUSH SEATS: the exposed END of every front tab / thumb pad / wrist tab is
//  re-shaped in 3D by a cutter coaxial with the mating curved face (eye-lobe
//  foot disc r R_FOOT at (cy,CZ); thumb prong bottom-front rounding r7; wrist
//  hinge-ear disc r EAR_R at (EAR_Y,EAR_Z)) so the floor edge CONTINUES the
//  curve down to the plate — nothing protrudes past the round faces, no
//  90-degree step under the curves (transição correcta).
// =============================================================================

/* [Floor] */
plate_h           = 2.0;    // floor plate thickness (z 0..2)
floor_weld        = 0.2;    // outward overlap into walls/ears/clevises (keeps unions manifold)
floor_round       = 1.2;    // convex corner rounding of the outline (mm)
floor_fillet      = 1.2;    // concave corner fillet of the outline (mm)
floor_back_y      = -30.0;  // main back edge (under the shell wrist rim)
floor_tab_back_y  = -43.0;  // nominal wrist-tab reach BEFORE the flush cut (keep <=
                            // EAR_Y - sqrt(EAR_R^2-(EAR_Z-plate_h)^2) ~ -42.9 so the
                            // coaxial ear-disc cut owns the whole exposed tip)
floor_back_tab_w  = 5.0;    // wrist-tab width (= EAR_W, spans each ear disc / wall foot)
floor_clear       = 6.4;    // finger-swing clearance: notch bottom = clevis pivot cy - this
floor_tab_past    = 4.5;    // nominal strip reach past the pivot line BEFORE the flush cut
                            // (keep >= sqrt(R_FOOT^2-(CZ-plate_h)^2) ~ 4.35 so the coaxial
                            // lobe cut owns the whole exposed end face)
floor_face_tuck   = 0.35;   // setback behind a truncated prong's FLAT front face (P2_FRONT)
floor_seat_inset  = 0.05;   // flush-cut inset inside the mating curved face (guards facet mismatch)
floor_thumb_tab_w = 5.0;    // width of the angled pads under the thumb-mount prongs
// basket-weave vent grid
hole_long  = 3.21;   // long side of a vent slot
hole_short = 2.13;   // short side of a vent slot
vent_pitch = 4.9;    // centre-to-centre spacing of the vent grid (both axes)
vent_x0    = 0.6;    // vent grid origin X
vent_y0    = -0.9;   // vent grid origin Y
vent_col0  = -6;     // vent column index range (X)
vent_col1  = 3;
vent_row0  = -5;     // vent row index range (Y)
vent_row1  = 4;

/* [Hidden] */
// Body corner stations (measured): smooth left bulge riding under the shell
// wall feet (SHELL_MID_XL -41.4 .. SHELL_FRONT_XL -36.8), right edge under the
// +X wall foot, back edge under the shell wrist rim.
FLOOR_BODY = [
    [-38.9, floor_back_y],  // back-left corner (under the -X wall foot)
    [-40.4,   3.6],         // left bulge — widest station (under SHELL_MID_XL)
    [-37.4,  21.9],         // left knee — edge tucks in toward the finger rim
    [ 23.6,  21.3],         // front-right corner (shell front rim, +X side)
    [ 24.5,   7.4],         // right edge (under the +X wall foot)
    [ 24.4,  -9.9],         // right edge at the thumb notch
    [ 23.4, floor_back_y],  // back-right corner
];
// front-left corner patch: floor rides up under the pinky-side shell rim foot,
// capped at the west-sliver slab's solid front (KN_SLABS[0] yB 24.7) so it
// never pokes out past the -X corner wall
FLOOR_FL_PATCH = [ [-37.4,18.0],[-37.4,21.9],[-35.9,24.3],[-35.0,24.3],[-35.0,18.0] ];
// front-right steps: under the index slot prong (to its pivot line; the flush
// cut shapes the tip), then tucked under the east-wall foot slabs' solid
// fronts (KN_SLABS[8] yB 34.6 / KN_SLABS[9] yB 27.6), down to the rim corner
FLOOR_FR_WEDGE = [ [19.0,18.0],[19.0,40.0],[19.8,40.0],[19.8,34.2],[21.9,34.2],
                   [21.9,27.2],[23.0,27.2],[23.6,21.3],[23.6,18.0] ];
// One apron per finger clevis [x0, x1, pivot cy] (spans copied from PART 3):
// floor in front of the dome up to cy - floor_clear (the prong-gap notch bottom).
FLOOR_APRONS = [
    [-35.5, -18.0, 30],   // pinky
    [-21.5,  -5.2, 36],   // ring
    [-11.5,  10.3, 40],   // middle
    [  2.5,  19.8, 40],   // index
];
FLOOR_APRON_Y0 = 18.0;    // apron base Y (inside the body -> overlap weld)
// Front tabs [x0, x1, pivot cy]: one strip under each PHYSICAL clevis prong,
// DERIVED from the PART 3 prong table so the floor auto-tracks the knuckles.
// The 2D strip runs to cy + floor_tab_past; floor_front_cutter() then re-cuts
// the exposed end flush with the prong's eye-lobe curve (see below).
FLOOR_FRONT_TABS = [ for (p = KN_PRONGS) [p[0], p[1], p[2]] ];
// Thumb pads [anchor x, anchor y, prong w, prong l, bottom-front rounding r,
// inward reach]: first five numbers = the PART 2 prong gbox3 calls (anchor,
// footprint, BOT+FWD edge rounding). Each pad runs along the prong axis (yaw
// below): outward past the prong tip (floor_thumb_cutter() then re-cuts it
// flush with the prong's rounded bottom-front face) and inward until it welds
// into the body edge.
FLOOR_THUMB_PADS = [
    [33.5,  0.0, 5.0, 17, 7, 13.0],   // under prong B (long inward run into the body)
    [27.3, -9.0, 5.2, 19, 7,  6.0],   // under prong A
];
FLOOR_THUMB_ANG = 50;   // pad yaw = thumb prong yaw (PART 2 gbox rot / bore axis)

// 2D footprint: union of the named pieces, then smooth (close, then open).
module floor_footprint() {
    offset(r =  floor_round) offset(r = -floor_round)     // OPEN: round convex corners
    offset(r = -floor_fillet) offset(r =  floor_fillet)   // CLOSE: fillet concave corners
    union() {
        polygon(FLOOR_BODY);
        polygon(FLOOR_FL_PATCH);
        polygon(FLOOR_FR_WEDGE);
        for (a = FLOOR_APRONS)      // clevis apron up to the swing-clearance line
            translate([a[0], FLOOR_APRON_Y0])
                square([a[1] - a[0], a[2] - floor_clear - FLOOR_APRON_Y0]);
        for (t = FLOOR_FRONT_TABS)  // strip under each prong (base overlaps the apron)
            translate([t[0], t[2] - floor_clear - 4])
                square([t[1] - t[0], floor_clear + 4 + floor_tab_past]);
        for (e = EARS)              // wrist tab under each hinge ear / wall foot
            translate([e[0] - floor_back_tab_w/2, floor_tab_back_y])
                square([floor_back_tab_w, floor_back_y - floor_tab_back_y + 2]);
        for (t = FLOOR_THUMB_PADS)  // angled pad under each thumb-mount prong
            translate([t[0], t[1]]) rotate(FLOOR_THUMB_ANG)
                translate([-floor_thumb_tab_w/2, -t[3]/2])
                    square([floor_thumb_tab_w, t[3]/2 + t[5]]);
    }
}

// ---- FLUSH-SEAT CUTTERS (kill the 90-degree steps under the curved faces) ----
// The lobe volume prong p's floor may occupy: the exact FOOT-disc cylinder of
// the PART 3 eye lobe (same centre (cy,CZ), same $fn), inset floor_seat_inset
// so the floor face sits just inside the lobe skin; truncated prongs (P2) are
// additionally capped floor_face_tuck behind their measured flat front face.
module floor_lobe_seat(p) {
    w = p[1] - p[0];
    intersection() {
        translate([p[0], p[2], CZ]) rotate([0, 90, 0])
            cylinder(h = w, r = R_FOOT - floor_seat_inset, $fn = 96);
        translate([p[0] - 1, -50, -10])
            cube([w + 2, 50 + (p[6] > 0 ? p[6] - floor_face_tuck : 100), 40]);
    }
}
// Everything a front tab grew beyond its pivot line, MINUS all lobe seats:
// subtracting this from the plate leaves each tab end as a concave seat that
// continues the eye-lobe curve down to the plate (flush, no step). Where prong
// bands overlap, the neighbour's seat protects its own tab (single difference).
module floor_front_cutter() {
    difference() {
        for (p = KN_PRONGS)   // beyond-the-pivot-line band, per prong (+ weld margin)
            translate([p[0] - 0.6, p[2], -1])
                cube([p[1] - p[0] + 1.2, 30, plate_h + 2]);
        for (p = KN_PRONGS) floor_lobe_seat(p);
    }
}
// Same for the thumb pads: each PART 2 prong ends in a BOT+FWD rounding of
// radius r — its bottom-front skin is a cylinder (axis along the prong width)
// centred at local (y = -(l/2 - r), z = r). Cut everything outward of that
// arc-centre plane except the (inset) rounding cylinder, so the pad end
// follows the prong's curve down to the plate.
module floor_thumb_cutter() {
    for (t = FLOOR_THUMB_PADS)
        translate([t[0], t[1], 0]) rotate([0, 0, FLOOR_THUMB_ANG]) {
            yc = -(t[3]/2 - t[4]);   // bottom-front arc centre plane (local Y)
            difference() {
                translate([-t[2]/2 - 1, yc - 12, -1]) cube([t[2] + 2, 12, plate_h + 2]);
                translate([-t[2]/2, yc, t[4]]) rotate([0, 90, 0])
                    cylinder(h = t[2], r = t[4] - floor_seat_inset, $fn = 96);
            }
        }
}
// Same for the wrist tabs: each hinge-ear disc (PART 5) is a cylinder r EAR_R
// on the X pin axis at (EAR_Y, EAR_Z) whose underside recedes to nothing at
// plate level (disc bottom z = EAR_Z - EAR_R = 0.25) — a flat full-height tab
// tip shows as a bare step under it. Cut everything the tab grew beyond the
// ear centre plane (y < EAR_Y) except the (inset) disc volume, so the tab
// tip's underside continues the ear's circular silhouette down to the plate.
// The covered run behind the ear (under the side wall / back band) is not
// touched — it stays full height for the weld, like the knuckle collars.
module floor_wrist_cutter() {
    for (e = EARS)
        difference() {
            translate([e[0] - floor_back_tab_w/2 - 1, EAR_Y - 12, -1])
                cube([floor_back_tab_w + 2, 12, plate_h + 2]);
            translate([e[0] - floor_back_tab_w/2, EAR_Y, EAR_Z]) rotate([0, 90, 0])
                cylinder(h = floor_back_tab_w, r = EAR_R - floor_seat_inset, $fn = 96);
        }
}

module palm_floor_grid() {
    difference() {   // perforated flat plate (z 0..plate_h)
        // floor_weld grows the outline so the floor overlaps the walls/ears/
        // clevises it meets — turns coincident faces into a small overlap, so
        // the union stays watertight/manifold (no zero-thickness shared face).
        linear_extrude(plate_h) offset(delta = floor_weld) floor_footprint();
        // basket-weave vents: rectangles alternating orientation row-to-row
        for (col = [vent_col0:vent_col1]) for (row = [vent_row0:vent_row1]) {
            hole_sz = (row % 2 == 0) ? [hole_long, hole_short] : [hole_short, hole_long];
            translate([vent_x0 + vent_pitch*col, vent_y0 + vent_pitch*row, -0.5])
                linear_extrude(plate_h + 1) square(hole_sz, center = true);
        }
        floor_front_cutter();   // tab ends -> flush with the knuckle eye-lobe curves
        floor_thumb_cutter();   // pad ends -> flush with the thumb prongs' rounded feet
        floor_wrist_cutter();   // wrist-tab tips -> flush with the hinge-ear discs
    }
}

// =============================================================================
// MODEL — enabled features fused (union); global bores are cut per part
// =============================================================================
// Every part carries its own [Colors] colour, so the pieces read separately in
// the viewer (inner color() wins over any outer wrap, e.g. _assembly's PALM_COL).
// debug_colors explodes the THUMB into its sub-part colours (see PART 2).
module model() {
    if (show_shell)      color(color_shell)      dorsal_shell();
    if (show_knuckles)   color(color_knuckles)   front_assembly();  // 4 round clevises + dome<->clevis junction
    if (show_fins)       color(color_fins)     { finger_fins(); finger_fin_caps(); }  // blade + crown cap
    if (show_thumb)    { if (debug_colors) thumb_colored();
                         else color(color_thumb) thumb_mount(); }   // readable primitive lug + bores
    if (show_wrist)      color(color_wrist)      wrist();           // hinge ears + gauntlet side walls
    if (show_wrist_back) color(color_wrist_back) wrist_back();      // gauntlet back band (ghost-clip)
    if (show_grid)       color(color_floor)      palm_floor_grid();
}

// ---- output / verification harness -----------------------------------------
module section_cube() {
    b = 300;
    if      (section == "longitudinal") translate([section_at, -b/2, -b/2]) cube(b);
    else if (section == "transverse")   translate([-b/2, section_at, -b/2]) cube(b);
    else if (section == "horizontal")   translate([-b/2, -b/2, section_at]) cube(b);
}
module ghost() { if (show_ghost) color(ghost_color, ghost_alpha) children(); }
// Standalone render — suppressed when a driver (e.g. _assembly.scad) sets
// no_assembly=true before `include`-ing this file, so it can call model() itself.
if (is_undef(no_assembly) || !no_assembly) {
if (section == "off") {
    model();
    ghost() import(ghost_stl);   // drawn LAST -> shows as a transparent overlay (not occluded)
} else {
    difference() { model(); section_cube(); }
    ghost() difference() { import(ghost_stl); section_cube(); }
}
}
