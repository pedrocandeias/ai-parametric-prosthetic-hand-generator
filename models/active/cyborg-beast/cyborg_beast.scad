/*
 * Cyborg Beast — Parametric Prosthetic Hand
 *
 * The original mechanical Cyborg Beast by MakerBlock / e-NABLE
 * (Chicago-screw + elastic-cord assembly). Palm geometry, finger segments and
 * thumb are the original modules (cyborgpalm001 / cyborgfingermid002 /
 * cyborgfingertip002); this file adds an anthropometric parameter layer,
 * per-part colours and a flat print-bed layout on top of them.
 *
 * All dimensions in millimetres.
 *
 * Sizing model (calibrated by measuring the original geometry):
 *   overall_scale = (palm_breadth_mm + 5) / 55   — the Cyborg Beast sizing guide
 *                                                   (base geometry ≈ 50 mm breadth)
 * Each finger's printed reach is driven to its absolute anatomical length via the
 * design's native `len` lever, inverting the measured reach curve
 *   R(len) = 60.85 + 1.584·len   (len ≥ 0)
 *   R(len) = 60.85 + 1.328·len   (len < 0)     [local units, at scale 1]
 * so a longer finger_length_mm lengthens only that finger, while palm and finger
 * thickness track overall_scale. The thumb is driven by a uniform scale of its
 * two-segment sub-assembly (keeps the segments attached, gap-free).
 */

/* [Anthropometric] */

// Knuckle-to-knuckle metacarpal breadth — drives uniform palm and hand scale via the Cyborg Beast formula: scale = (breadth + 5) / 55 (mm)
palm_breadth_mm = 83; // [55:1:110]

// Middle finger MCP crease to tip (mm)
middle_finger_length_mm = 72; // [40:1:120]

// Index finger MCP crease to tip (mm)
index_finger_length_mm = 68; // [40:1:120]

// Ring finger MCP crease to tip (mm)
ring_finger_length_mm = 68; // [40:1:120]

// Pinky finger MCP crease to tip (mm)
pinky_finger_length_mm = 55; // [30:1:100]

// Thumb MCP crease to tip (mm)
thumb_length_mm = 65; // [35:1:100]

// Build the mirror-image (left vs right) hand — set by the UI laterality control
mirrored = false;

/* [Options] */

// Print-bed layout: spread every part flat side-by-side for 3D printing instead of the assembled hand (false).
print_layout = false;

/* [Colors] */

// One colour per printable part — shown in the preview and baked into the 3MF export (one material per colour). base = proximal segment, tip = distal segment.
color_palm        = "#cbd5e1"; // palm body
color_index_base  = "#4a9eff"; // index — proximal
color_index_tip   = "#7cc0ff"; // index — distal
color_middle_base = "#ff6b6b"; // middle — proximal
color_middle_tip  = "#ffa0a0"; // middle — distal
color_ring_base   = "#51cf66"; // ring — proximal
color_ring_tip    = "#8ce89b"; // ring — distal
color_pinky_base  = "#ffd43b"; // pinky — proximal
color_pinky_tip   = "#ffe680"; // pinky — distal
color_thumb_base  = "#cc5de8"; // thumb — proximal
color_thumb_tip   = "#e0a0f0"; // thumb — distal

/* [Visibility] */

// Whole-finger toggles (isolate a digit for per-part STL export)
show_palm   = true;
show_index  = true;
show_middle = true;
show_ring   = true;
show_pinky  = true;
show_thumb  = true;

// Per-segment toggles (isolate a single printable piece)
show_index_base  = true;
show_index_tip   = true;
show_middle_base = true;
show_middle_tip  = true;
show_ring_base   = true;
show_ring_tip    = true;
show_pinky_base  = true;
show_pinky_tip   = true;
show_thumb_base  = true;
show_thumb_tip   = true;

// ── Internal base constants (original Cyborg Beast geometry) ─────────────────
knuckleR = 4.85;
wristH   = 10;
palmH    = 20;
palmW    = 64;
th       = 3;
fn       = 32;

include <cyborgpalm001.scad>
include <cyborgfingertip002.scad>
include <cyborgfingermid002.scad>

// ── Derived sizing ──────────────────────────────────────────────────────────
overall_scale = (palm_breadth_mm + 5) / 55;

// Measured reach calibration for the two-segment printed finger (local units, scale 1)
REF_R0    = 60.85;   // reach at len = 0
SLOPE_POS = 1.584;   // dReach/dlen for len ≥ 0
SLOPE_NEG = 1.328;   // dReach/dlen for len < 0
LEN_MIN   = -22;     // safe geometry floor (finger stays printable)
LEN_MAX   = 50;      // safe geometry ceiling

// Anatomical finger length (mm) → native `len` lever, compensating overall_scale
function raw_len(target_mm) =
    (target_mm / overall_scale) >= REF_R0
        ? ((target_mm / overall_scale) - REF_R0) / SLOPE_POS
        : ((target_mm / overall_scale) - REF_R0) / SLOPE_NEG;
function finger_len(target_mm) = max(LEN_MIN, min(LEN_MAX, raw_len(target_mm)));

// Thumb: uniform scale of the two-segment sub-assembly (base reach ≈ 44.93 at scale 1)
THUMB_BASE_REACH = 44.93;
function thumb_scale() =
    max(0.6, min(1.7, thumb_length_mm / (overall_scale * THUMB_BASE_REACH)));

// ── Top-level ───────────────────────────────────────────────────────────────
mirror([mirrored ? 1 : 0, 0, 0])
    scale(overall_scale)
        if (print_layout) printlayout(); else handlayout();

// Assembled hand (original pose), per-finger length + per-part colour/visibility
module handlayout(sp = 14.4) {
    if (show_palm) color(color_palm) cyborgbeastpalm();
    translate([22, 29, 10]) rotate([0, 180, 0]) {
        if (show_index)
            translate([0,    10,   0]) fingerlayout(finger_len(index_finger_length_mm),
                show_index_base,  show_index_tip,  color_index_base,  color_index_tip);
        if (show_middle)
            translate([sp,   12.5, 0]) fingerlayout(finger_len(middle_finger_length_mm),
                show_middle_base, show_middle_tip, color_middle_base, color_middle_tip);
        if (show_ring)
            translate([sp*2, 12,   0]) fingerlayout(finger_len(ring_finger_length_mm),
                show_ring_base,   show_ring_tip,   color_ring_base,   color_ring_tip);
        if (show_pinky)
            translate([sp*3, 7.5,  0]) fingerlayout(finger_len(pinky_finger_length_mm),
                show_pinky_base,  show_pinky_tip,  color_pinky_base,  color_pinky_tip);
    }
    if (show_thumb)
        translate([41, -9.5, -4]) rotate([50, -20, 90]) scale(thumb_scale()) {
            if (show_thumb_base) color(color_thumb_base) thumbmid();
            if (show_thumb_tip)  color(color_thumb_tip)
                translate([0, -18, 5]) rotate([30, 180, 180]) thumbtip();
        }
}

// One finger: distal (tip) + proximal (base) segments, each colourable/toggleable
module fingerlayout(len = 0, base = true, tip = true, baseCol = "#cccccc", tipCol = "#dddddd") {
    if (tip)
        color(tipCol) render()
            translate([0, 23 + len*2/3, 1.5]) rotate([10, 0, 0]) fingertip(s = 1, grip = 1, len = len);
    if (base)
        color(baseCol) render()
            mirror([0, 0, 1]) mirror([0, 1, 0]) translate([0, 0, -10]) fingermid(s = 1, len = len);
}

// Flat print-bed layout: every part spread side-by-side in its native (flat-
// bottomed) print orientation. The STL/3MF exporter seats each part on Z=0.
module printlayout() {
    row = 24;
    _fingers = [
        [show_index,  show_index_base,  show_index_tip,  index_finger_length_mm,  color_index_base,  color_index_tip],
        [show_middle, show_middle_base, show_middle_tip, middle_finger_length_mm, color_middle_base, color_middle_tip],
        [show_ring,   show_ring_base,   show_ring_tip,   ring_finger_length_mm,   color_ring_base,   color_ring_tip],
        [show_pinky,  show_pinky_base,  show_pinky_tip,  pinky_finger_length_mm,  color_pinky_base,  color_pinky_tip],
    ];
    if (show_palm) color(color_palm) cyborgbeastpalm();
    for (i = [0:len(_fingers)-1]) let(f = _fingers[i], L = finger_len(f[3]), y = -i*row) {
        if (f[0] && f[1]) color(f[4]) translate([58, y, 0]) fingermid(len = L);
        if (f[0] && f[2]) color(f[5]) translate([88, y, 0]) fingertip(len = L, grip = 1);
    }
    if (show_thumb) let(yt = -4*row) scale(thumb_scale()) {
        if (show_thumb_base) color(color_thumb_base) translate([58/thumb_scale(), yt/thumb_scale(), 0]) thumbmid();
        if (show_thumb_tip)  color(color_thumb_tip)  translate([88/thumb_scale(), yt/thumb_scale(), 0]) thumbtip();
    }
}

module thumbmid() { fingermid(len = -12); }
module thumbtip() { fingertip(len = -5, grip = 1); }
