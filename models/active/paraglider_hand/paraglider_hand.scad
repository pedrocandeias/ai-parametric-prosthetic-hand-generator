/*
  Paraglider Hand — Print Layout
  Anthropometric wrapper around the Paraglider / Flexible Flyer hand
  Original design: Marcus Mendenhall, 2020 (CC BY-SA 4.0)
  Source: https://github.com/mendenmh/flexible_flyer

  Scale derivation:
    palm_breadth_mm=83 → overall_scale=1.25 (uniform palm scale; pin holes
    must stay circular so the palm cannot be scaled non-uniformly).
    middle_finger_length_mm=72 → global_scale=1.25 (finger parts scale
    independently of the palm; REF_FINGER=57.6 calibrated at 72mm/1.25×).

  Generates a flat print layout: palm body on the left, finger/thumb parts
  to the right, ready for slicing directly from this view.

  Channel note: show_channels=false (default) renders the palm without string/
  elastic channel routing. The channel CSG (plug_old_channels + reborn_channels
  from pipe.scad) involves complex swept-tube boolean operations that the
  Manifold backend can fail on. Enable show_channels only when exporting a
  print-ready STL — expect a significantly longer render time.
*/

/* [Anthropometric] */
// Knuckle-to-knuckle metacarpal breadth — drives uniform palm scale (mm)
palm_breadth_mm = 83; // [55:1:110]
// Wrist base to middle MCP crease — stored for AI/profile alignment; palm uses uniform scale from palm_breadth_mm (mm)
palm_length_mm = 95; // [60:1:140]
// Palmar to dorsal surface thickness — stored for AI/profile alignment; palm uses uniform scale from palm_breadth_mm (mm)
palm_thickness_mm = 32; // [18:1:50]
// Index finger MCP crease to tip — drives index finger part scale (mm)
index_finger_length_mm = 68; // [40:1:120]
// Middle finger MCP crease to tip — drives middle finger part scale and global_scale base (mm)
middle_finger_length_mm = 72; // [40:1:120]
// Ring finger MCP crease to tip — drives ring finger part scale (mm)
ring_finger_length_mm = 68; // [40:1:120]
// Pinky finger MCP crease to tip — drives pinky finger part scale (mm)
pinky_finger_length_mm = 55; // [30:1:100]
// Thumb MCP crease to tip — stored for AI/profile alignment; thumb uses finger scale (mm)
thumb_length_mm = 65; // [35:1:100]

/* [Handedness] */
// Mirror X axis for a right-hand orientation (default: left hand)
mirrored = false;

/* [Component] */
// Which piece of the Paraglider system to render/export
component = "Hand"; // [Hand, Box, Gauntlet, Arm]
// Palm style for the Hand component
palm_style = "Reborn"; // [Reborn, UnlimbitedV3]

/* [Hardware] */
// Pivot pin style — sets hole diameters in palm and phalanges
pin_index = 1; // [0: 3mm screws + Delrin, 1: 1/16 inch pins + bearing, 2: 13ga nails + PTFE, 3: 1/16 inch pins no bearing]

/* [Gauntlet] (component = Gauntlet) */
GAU_bearing_only = false;  // print only the wrist bearing tab
GAU_slide_only   = false;  // print only the dovetail track

/* [Arm] (component = Arm) — elbow-powered UnLimbited arm */
ARM_part        = "Cuff";  // [Cuff, Forearm, Palm, Fingers, Phalanx, Pins, Jig]
ARM_LeftRight   = "Left";   // [Left, Right]
ARM_HandLen     = 135;      // [135:230] total hand length (mm)
ARM_ForearmLen  = 140;      // [120:315] forearm length (mm)
ARM_BicepCircum = 160;      // [110:350] bicep circumference (mm)
ARM_CuffLength  = 65;       // [65:90] upper-arm cuff length (mm)
ARM_PinHoleDia  = 3;        // [3:6] joint pin/screw hole diameter (mm)

/* [Visibility] */
show_palm           = true;
show_palm_mesh      = true;
show_knuckle_covers = true;
show_index          = true;  // index fingertip + phalanx
show_middle         = true;  // middle fingertip + phalanx
show_ring           = true;  // ring fingertip + phalanx
show_pinky          = true;  // pinky fingertip + phalanx
show_thumb          = true;  // thumb tip + phalanx
show_pins           = true;  // pivot pins at wrist and knuckle positions
// Enable string/elastic channel routing in palm (slow — complex CSG; keep off for preview)
show_channels       = false;
// Assembled view: position finger parts at palm knuckle pins (true) or flat print layout (false)
show_assembled      = true;

/* [Colors] */
color_palm   = "#d4a574"; // palm body
color_index  = "#4a9eff"; // index finger
color_middle = "#ff6b6b"; // middle finger
color_ring   = "#51cf66"; // ring finger
color_pinky  = "#ffd43b"; // pinky finger
color_thumb  = "#cc5de8"; // thumb
color_pins   = "#aaaaaa"; // pivot pins (metal hardware)

/* [Palm Labels] */
serial_line1 = "paraglider";
serial_line2 = "";
serial_line3 = "";

/* [Palm Channels] */
string_channel_scale  = 0.9; // [0.5:0.05:1.0]
elastic_channel_scale = 0.9; // [0.5:0.05:1.5]
old_style_wrist = false;

/* [Hidden] */

// ── Scale derivation ─────────────────────────────────────────────────────────
// 83 mm palm breadth → 1.25 overall_scale per original README ("medium-sized")
// REF_PALM = 66.4 mm (palm breadth at scale 1.0)
overall_scale = palm_breadth_mm / 66.4;

// Finger scale is independent of palm scale so that, e.g., a child hand with
// narrow palm but shorter fingers renders each part at the correct size.
// REF_FINGER = 57.6 mm (total finger assembly length at scale 1.0);
// calibrated so that middle_finger_length_mm=72 → global_scale=1.25.
global_scale = middle_finger_length_mm / 57.6;

// Per-finger scales — each finger length drives its own tip + phalanx geometry.
// global_scale (middle) is the base used for dynamic-scoped fingerator variables
// (adjusted_tabwidth etc.); the ratio fscale/global_scale is applied as an extra
// uniform scale on top of the already-scaled fingerator geometry.
index_scale = index_finger_length_mm / 57.6;
ring_scale  = ring_finger_length_mm  / 57.6;
pinky_scale = pinky_finger_length_mm / 57.6;

// ── Palm variables (dynamic scoping for paraglider_palm_left.scad modules) ──
inch = 25.4;
pivot_extra_clearance = 0;
pins  = true;
main_ghost   = false;
fast_preview = false;
include_wrist_stamping_die = false;

include_mesh           = show_palm_mesh ? 1 : 0;
include_knuckle_covers = show_knuckle_covers;

// Pin diameter in palm holes — maps pin_index to the pin/hole size (mm)
_pin_size_lookup = [
    3 + 0.1,           // 0: 3mm screw
    inch*(1/16),       // 1: 1/16" pin
    inch*0.095,        // 2: 13ga nail
    inch*(1/16)        // 3: 1/16" bare pin
];
pivot_size = _pin_size_lookup[pin_index];

// act_scale flips X for mirroring
act_scale = [mirrored ? -overall_scale : overall_scale, overall_scale, overall_scale];

// Geometry arrays referenced inside palm modules
slot_dx = [
    [[10,0,0],   0],
    [[-4,0,0],   0],
    [[-18,-4,0], 0],
    [[-32,-10,0],0]
];
pin_coordinates = [
    [[-35.4,-38,8],   [0,90,0]],   // left wrist
    [[20.68,-38,8],   [0,90,0]],   // right wrist
    [[6.6,39.5,6.0],  [0,90,0]],   // index + middle knuckle
    [[-16,35.5,6.0],  [0,90,0]],   // ring knuckle
    [[-29.5,29.5,6.0],[0,90,0]],   // pinky knuckle
    [[31,0,6.0],      [0,90,50]]   // thumb MCP
];

// ── Fingerator variables (dynamic scoping for fingerator.scad modules) ────────
nominal_clearance       = 0.5;
bearing_pocket_diameter = 0;
bearing_pocket_depth    = 0.4;
pins_for_string         = false;
pin_diameter_clearance  = 0;
screws = (pin_index == 0);

// Bearing outer diameters and pin diameters, matching fingerator.scad arrays
pivot_dia_3mm_screw              = inch*(3/16) + 0.25;
pivot_pin_dia_3mm_screw          = 3 + 0.1;
pivot_dia_8th_delrin             = inch*(1/8) + 0.25;
pivot_pin_dia_16th_pin           = inch*(1/16) + pin_diameter_clearance;
pivot_pin_dia_16th_pin_clearance = pivot_pin_dia_16th_pin + 0.3;
pivot_dia_13ga_nail              = inch*(5/32) + 0.25;
pivot_pin_dia_13ga_nail          = inch*0.095 + pin_diameter_clearance;

pivot_array = [
    pivot_dia_3mm_screw,
    pivot_dia_8th_delrin,
    pivot_dia_13ga_nail,
    pivot_pin_dia_16th_pin_clearance
];
pin_array = [
    pivot_pin_dia_3mm_screw,
    pivot_pin_dia_16th_pin,
    pivot_pin_dia_13ga_nail,
    pivot_pin_dia_16th_pin
];

pivot_dia     = pivot_array[pin_index];
pivot_pin_dia = pin_array[pin_index];

nut_size          = 5.5;
bolt_head_dia     = 5.5 + 0.3;
nominal_slotwidth = 6;
adjusted_tabwidth  = nominal_slotwidth - nominal_clearance / global_scale;
adjusted_slotwidth = nominal_slotwidth;
initial_rotation   = 33.5;

// ── Component files ───────────────────────────────────────────────────────────
use <pipe.scad>
use <fingerator.scad>
use <paraglider_palm_left.scad>

// Drive the v3 palm from the Hand's shared inputs so palm + fingers stay
// consistent. Declared BEFORE the include so the bundle's top-level vars
// (e.g. V3_act_scale) resolve them.
V3_overall_scale           = overall_scale;
V3_include_mesh            = show_palm_mesh ? 1 : 0;
V3_include_knuckle_covers  = show_knuckle_covers;
V3_include_wrist_stamping_die = false;

// ── Namespaced variant/accessory bundles (each exposes a *_main() / *_scaled_palm()) ──
// Generated from the standalone Paraglider sources with every internal identifier
// prefixed so they coexist in one file. Driven by the shared inputs above.
include <pg_v3palm.scad>   // Unlimbited v3 palm → V3_scaled_palm()
include <pg_box.scad>      // tensioner box      → BOX_main()
include <pg_gauntlet.scad> // thermo gauntlet    → GAU_main()
include <pg_arm.scad>      // elbow-powered arm  → ARM_main()

// Skip the v3 palm's fontconfig text labels (no fontconfig in the WASM build).
module V3_do_labels() { children(); }

// ── Label override ─────────────────────────────────────────────────────────────
// Overrides do_labels() from paraglider_palm_left.scad.
// The WASM build has no fontconfig, so text() calls produce warnings and empty
// geometry. Skip the label cuts entirely — the palm body is unaffected.
module do_labels() {
    children();
}

// ── Channel override ──────────────────────────────────────────────────────────
// Overrides do_channels() from paraglider_palm_left.scad.
// When show_channels=false (default), skips plug_old_channels() and
// reborn_channels() — the swept-pipe CSG that stresses the Manifold backend —
// and only applies the structural end-shave cut. Enable show_channels for a
// print-ready export with full channel routing.
module do_channels() {
    if (show_channels) {
        difference() {
            union() {
                children();
                if (!main_ghost) plug_old_channels();
                if (main_ghost)  reborn_channels();
            }
            if (!main_ghost) reborn_channels();
            translate([0,-31.9,30]) cube([100,5,20], center=true);
        }
    } else {
        difference() {
            children();
            translate([0,-31.9,30]) cube([100,5,20], center=true);
        }
    }
}

// ── Shared modules for finger parts ──────────────────────────────────────────
// fscale defaults to global_scale (middle finger); pass index_scale / ring_scale /
// pinky_scale for per-finger sizing. The ratio fscale/global_scale is applied as a
// uniform rescale on top of fingerator's already-scaled geometry.
module _long_finger(fscale=global_scale) {
    _sf = fscale / global_scale;
    if (screws)
        scale([_sf,_sf,_sf]) adjusted_bolt_holes(global_scale, outer_width=13,
            offsets=[[[0,-20,9],0]],
            bolt_dia=pivot_pin_dia, nut_size=nut_size, bolt_head_dia=bolt_head_dia)
            finger(slotwidth=nominal_slotwidth, thumb=false);
    else
        scale([_sf,_sf,_sf]) adjusted_holes(global_scale,
            offsets=[[[0,-20,9],0]], dia=pivot_pin_dia)
            finger(slotwidth=nominal_slotwidth, thumb=false);
}
module _short_finger(fscale=global_scale) {
    _sf = fscale / global_scale;
    if (screws)
        scale([_sf,_sf,_sf]) adjusted_bolt_holes(global_scale, outer_width=13,
            offsets=[[[0,-20*0.9,9],0]],
            bolt_dia=pivot_pin_dia, nut_size=nut_size, bolt_head_dia=bolt_head_dia)
            scale([1,0.9,1]) finger(slotwidth=nominal_slotwidth, thumb=false);
    else
        scale([_sf,_sf,_sf]) adjusted_holes(global_scale,
            offsets=[[[0,-20*0.9,9],0]], dia=pivot_pin_dia)
            scale([1,0.9,1]) finger(slotwidth=nominal_slotwidth, thumb=false);
}
module _thumb_tip(fscale=global_scale) {
    _sf = fscale / global_scale;
    if (screws)
        scale([_sf,_sf,_sf]) adjusted_bolt_holes(global_scale, outer_width=13,
            offsets=[[[0,-20*0.77,9*0.72],0]],
            bolt_dia=pivot_pin_dia, nut_size=nut_size, bolt_head_dia=bolt_head_dia)
            scale([1.1,0.77,0.72]) finger(slotwidth=nominal_slotwidth/1.1, thumb=true);
    else
        scale([_sf,_sf,_sf]) adjusted_holes(global_scale,
            offsets=[[[0,-20*0.77,9*0.72],0]], dia=pivot_pin_dia)
            scale([1.1,0.77,0.72]) finger(slotwidth=nominal_slotwidth/1.1, thumb=true);
}
module _finger_phalanx(fscale=global_scale) {
    cut_phalanx(palm_pivot_size=pivot_dia, knuckle_pivot_size=pivot_dia,
        tab_thickness=adjusted_tabwidth, scale_size=fscale, thumb=false);
}
module _thumb_phalanx(fscale=global_scale) {
    scale([1.1,1,1]) cut_phalanx(palm_pivot_size=pivot_dia, knuckle_pivot_size=pivot_dia,
        tab_thickness=adjusted_tabwidth/1.1, scale_size=fscale, thumb=true);
}

// ════════════════════════════════════════════════════════════════════════════════
// COMPONENT DISPATCH
// ════════════════════════════════════════════════════════════════════════════════
if (component == "Box")      BOX_main();
else if (component == "Gauntlet") GAU_main();
else if (component == "Arm")      ARM_main();
else if (component == "Hand") {

// ── Palm (both modes) ─────────────────────────────────────────────────────────
if (show_palm)
    color(color_palm) {
        if (palm_style == "UnlimbitedV3") V3_scaled_palm();
        else scaled_palm();
    }

if (!show_assembled) {
// ════════════════════════════════════════════════════════════════════════════════
// PRINT LAYOUT MODE — parts laid flat side-by-side, ready for slicing
// ════════════════════════════════════════════════════════════════════════════════
// _fp = X origin, shifted 65 mm right of the palm thumb-side edge.
// Each finger has a single X anchor (_x_*); both its phalanx (Y=0) and its
// fingertip (Y=_tip_row) share that anchor — move one, the other follows.
_fp = 31 * overall_scale + 65;

// ── Per-finger column X positions — edit these to reposition a whole finger column
_x_index  = _fp +   0;
_x_middle = _fp +  30;
_x_ring   = _fp +  60;
_x_pinky  = _fp +  90;
_x_thumb  = _fp + 125;

// ── Row Y offsets — phalanxes at Y=0, fingertips offset above
_tip_row   = 50;  // mm above phalanx row

if (show_index) color(color_index) {
    translate([_x_index, 0,        0]) rotate([0, 180, 0]) _finger_phalanx(index_scale);
    translate([_x_index, _tip_row, 0]) rotate([0, 180, 0]) _long_finger(index_scale);
}

if (show_middle) color(color_middle) {
    translate([_x_middle, 0,        0]) rotate([0, 180, 0]) _finger_phalanx(global_scale);
    translate([_x_middle, _tip_row, 0]) rotate([0, 180, 0]) _long_finger(global_scale);
}

if (show_ring) color(color_ring) {
    translate([_x_ring, 0,        0]) rotate([0, 180, 0]) _finger_phalanx(ring_scale);
    translate([_x_ring, _tip_row, 0]) rotate([0, 180, 0]) _short_finger(ring_scale);
}

if (show_pinky) color(color_pinky) {
    translate([_x_pinky, 0,        0]) rotate([0, 180, 0]) _finger_phalanx(pinky_scale);
    translate([_x_pinky, _tip_row, 0]) rotate([0, 180, 0]) _short_finger(pinky_scale);
}

if (show_thumb) color(color_thumb) {
    translate([_x_thumb, 0,        0]) rotate([0, 180, 0]) _thumb_phalanx(global_scale);
    translate([_x_thumb, _tip_row, 0]) rotate([0, 180, 0]) _thumb_tip(global_scale);
}

} else {
// ════════════════════════════════════════════════════════════════════════════════
// ASSEMBLED VIEW MODE — finger parts placed at palm knuckle pin positions
// ════════════════════════════════════════════════════════════════════════════════
//
// Knuckle pin world positions = pin_coordinates[n][0] × overall_scale:
//   [2] Index + Middle  [6.6,  39.5, 6.0]  shared long pin
//   [3] Ring            [-16,  35.5, 6.0]
//   [4] Pinky           [-29.5,29.5, 6.0]
//   [5] Thumb MCP       [31,   0,    6.0]  angle: rotate Z=50°
//
// Phalanx pivots (local, before scale(global_scale)):
//   proximal [0, -11.8, 6.0] → translate phalanx to [kx, ky + 11.8×gs]
//   distal   [0, +12.3, 5.8]
//
// Fingertip joint (in adjusted_holes local, before scale(global_scale)):
//   long  [0, -20,        9]  → place at phalanx distal + 20×gs in Y
//   short [0, -20×0.9,    9]  → place at phalanx distal + 18×gs in Y
//   thumb [0, -20×0.77, 6.48] → place at phalanx distal + 15.4×gs in Y

_gs = global_scale;
_os = overall_scale;

// Y offsets (all in world mm)
_prox_y = 11.8 * _gs;      // phalanx: proximal pivot → module origin
_dist_y = 12.3 * _gs;      // phalanx: module origin → distal pivot
_tip_long_y  = _prox_y + _dist_y + 20   * _gs;  // long fingertip Y from knuckle
_tip_short_y = _prox_y + _dist_y + 18   * _gs;  // short fingertip Y from knuckle
_tip_thumb_y = _prox_y + _dist_y + 15.4 * _gs;  // thumb tip Y from MCP

// Mirror factor: flips all X coordinates and the thumb rotation for right-hand
_mx = mirrored ? -1 : 1;

// Lateral half-offset to split index and middle fingers at the shared pin
_half = 6 * _gs;

// Knuckle X,Y in world coordinates (X flipped by _mx for right-hand)
_kx_im  =  6.6  * _os * _mx;   _ky_im  = 39.5 * _os;  // index+middle
_kx_rng = -16   * _os * _mx;   _ky_rng = 35.5 * _os;  // ring
_kx_pnk = -29.5 * _os * _mx;   _ky_pnk = 29.5 * _os;  // pinky
_kx_thm =  31   * _os * _mx;   _ky_thm =  0   * _os;  // thumb MCP

// Index/middle split: index is always on the thumb side of the shared pin
_idx_x = _kx_im + _half * _mx;
_mid_x = _kx_im - _half * _mx;

// Thumb rotation flips sign for right hand
_thm_rot = mirrored ? 130 : -130;

// Index and middle share a knuckle pin — each offset to the thumb/pinky side respectively.
if (show_index) color(color_index) {
    translate([_idx_x+1, _ky_im + _prox_y,         0])  rotate([0,   0, 0]) _finger_phalanx(index_scale);
    translate([_idx_x+1, _ky_im + _tip_long_y,     15]) rotate([5, 180, 0]) _long_finger(index_scale);
}

if (show_middle) color(color_middle) {
    translate([_mid_x-1.5, _ky_im + _prox_y,          0])  rotate([0,   0, 0]) _finger_phalanx(global_scale);
    translate([_mid_x-1.5, _ky_im + _tip_long_y + 2,  15]) rotate([5, 180, 0]) _long_finger(global_scale);
}

if (show_ring) color(color_ring) {
    translate([_kx_rng + 2 * _mx, _ky_rng + _prox_y ,        0])  rotate([0,   0, 0]) _finger_phalanx(ring_scale);
    translate([_kx_rng + 2 * _mx, _ky_rng + _tip_short_y ,  15]) rotate([5, 180, 0]) _short_finger(ring_scale);
}

if (show_pinky) color(color_pinky) {
    translate([_kx_pnk + 1.5 * _mx, _ky_pnk + _prox_y,       0])  rotate([0,   0, 0]) _finger_phalanx(pinky_scale);
    translate([_kx_pnk + 1.5 * _mx, _ky_pnk + _tip_short_y -8,  12]) rotate([5, 180, 0]) _short_finger(pinky_scale);
}

if (show_thumb) color(color_thumb) {
    translate([_kx_thm, _ky_thm, 0]) rotate([0, 0, _thm_rot]) {
        translate([0, _prox_y,      20]) rotate([0, 180, 0]) _thumb_phalanx(global_scale);
        translate([0, _tip_thumb_y, 20]) rotate([0, 180, 0]) _thumb_tip(global_scale);
    }
}

// ── Pivot pins — cylinders at each wrist and knuckle pin location ──────────────
// Pin_coordinates orientations are [0,90,rot_z]: rotate([0,90,0]) aligns a Z
// cylinder to the X axis; thumb adds a further 50° Z rotation.
if (show_pins) color(color_pins) {
    _plen = 30 * _os;   // pin visual length (spans through phalanx tabs)
    _kz   =  6 * _os;   // knuckle pin Z height (from pin_coordinates)
    _wz   =  8 * _os;   // wrist pin Z height

    // Wrist pins
    translate([-35.4 * _os * _mx, -38 * _os, _wz]) rotate([0, 90, 0]) cylinder(d=pivot_dia, h=_plen, center=true, $fn=16);
    translate([ 20.68 * _os * _mx, -38 * _os, _wz]) rotate([0, 90, 0]) cylinder(d=pivot_dia, h=_plen, center=true, $fn=16);

    // Knuckle pins — index + middle share one pin
    translate([_kx_im,  _ky_im,  _kz]) rotate([0, 90, 0]) cylinder(d=pivot_dia, h=_plen, center=true, $fn=16);
    translate([_kx_rng, _ky_rng, _kz]) rotate([0, 90, 0]) cylinder(d=pivot_dia, h=_plen, center=true, $fn=16);
    translate([_kx_pnk, _ky_pnk, _kz]) rotate([0, 90, 0]) cylinder(d=pivot_dia, h=_plen, center=true, $fn=16);

    // Thumb MCP pin — rotated 50° (or -50° when mirrored) around Z
    translate([_kx_thm, _ky_thm, _kz])
        rotate([0, 0, mirrored ? -50 : 50])
            rotate([0, 90, 0]) cylinder(d=pivot_dia, h=_plen, center=true, $fn=16);
}

} // end assembled

} // end component == "Hand"
