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

/* [Segment split] */

// Proximal (base) phalanx length — MCP crease to PIP joint — i.e. how much of
// the finger is the printed base segment; the distal (tip) segment fills the
// remainder up to the total finger length. Defaults reproduce the native Cyborg
// Beast proportion (nothing changes at defaults); anthropometric import / AI
// drives these to digits.<finger>.proximal_length_mm.

// Index — proximal (base) segment length, MCP to PIP (mm)
index_base_length_mm = 22; // [12:1:60]

// Middle — proximal (base) segment length, MCP to PIP (mm)
middle_base_length_mm = 24; // [12:1:60]

// Ring — proximal (base) segment length, MCP to PIP (mm)
ring_base_length_mm = 22; // [12:1:60]

// Pinky — proximal (base) segment length, MCP to PIP (mm)
pinky_base_length_mm = 16; // [10:1:55]

// Thumb — proximal (base) segment length, MCP to IP (mm)
thumb_base_length_mm = 22; // [12:1:45]

// Build the mirror-image (left vs right) hand — set by the UI laterality control
mirrored = false;

/* [Gauntlet] */

// Forearm gauntlet cuff (Normal Gauntlet with Tensioner). Shown at the wrist in the assembled view and as its own printable part in the print layout.
show_gauntlet = true;

// Forearm circumference at the wrist (mm) — sizes the gauntlet cuff girth to the
// wearer, independently of hand scale: cuff width = circumference/PI + clearance.
wrist_circumference_mm = 160; // [110:1:260]

// Wrist hinge pin diameter (mm) — the gauntlet prongs nest inside the palm wrist
// fins and this pin runs through fin-prong-prong-fin. Palm fin bore is ~7.2 mm.
wrist_pin_dia = 7; // [4:0.5:10]

// Clearance around the wrist pin so the gauntlet pivots freely (mm)
wrist_pin_clearance = 0.35; // [0.1:0.05:0.8]

// Forearm droop angle — the gauntlet pivots this far about the wrist pin (deg)
gauntlet_tilt = 12; // [-10:1:40]

// Forearm length multiplier (1 = native reconstructed length)
gauntlet_length_scale = 1.0; // [0.7:0.05:1.5]

// Strap-hole diameters on the gauntlet rim (mm)
gauntlet_rim_hole_d = 2.5; // [1.5:0.5:6]

// Manual fine-tune on top of the automatic wrist-pin seating (local mm)
gauntlet_nudge = [0, 0, 0];

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
color_gauntlet    = "#94a3b8"; // forearm gauntlet cuff

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
include <gauntlet.scad>

// ── Derived sizing ──────────────────────────────────────────────────────────
overall_scale = (palm_breadth_mm + 5) / 55;

// ── Gauntlet sizing & auto-seating ──────────────────────────────────────────
// Girth (X,Z cross-section) is scaled to the wrist circumference; length (Y) by
// gauntlet_length_scale. The pin runs along X, so scaling girth keeps the hinge
// valid — the prong pin-holes just move in/out along the pin. We then solve the
// seat so those holes land exactly on the palm wrist-pin axis (local y=1.4,
// z=3.3) for ANY girth/length/tilt. Measured native gauntlet: width 49.88 mm,
// prong pin-hole at (±22.6, -58.3, -9.8).
G_NATIVE_W = 49.88;                 // native cuff width (X extent), mm
G_PRONG_Y  = -58.3;                 // native prong pin-hole Y
G_PRONG_Z  = -9.8;                  // native prong pin-hole Z
G_PIN_Y    = 1.4;                   // palm wrist-pin axis, local Y
G_PIN_Z    = 3.3;                   // palm wrist-pin axis, local Z

g_girth = (wrist_circumference_mm / PI + 6) / (G_NATIVE_W * overall_scale);
g_len   = gauntlet_length_scale;
// prong pin-hole after scale([g_girth,g_len,g_girth]) then rotate([tilt,0,180]):
g_prong_y = -G_PRONG_Y * g_len * cos(gauntlet_tilt) - G_PRONG_Z * g_girth * sin(gauntlet_tilt);
g_prong_z = -G_PRONG_Y * g_len * sin(gauntlet_tilt) + G_PRONG_Z * g_girth * cos(gauntlet_tilt);
g_seat    = [0, G_PIN_Y - g_prong_y, G_PIN_Z - g_prong_z];
g_pin_bore = wrist_pin_dia + 2 * wrist_pin_clearance;

// Place the sized gauntlet, seated on the palm wrist pin. Children none.
module seat_gauntlet() {
    translate(g_seat + gauntlet_nudge)
        rotate([gauntlet_tilt, 0, 180])
            scale([g_girth, g_len, g_girth])
                gauntlet(pin_hole_d = g_pin_bore, rim_hole_d = gauntlet_rim_hole_d);
}

// Measured reach calibration for the two-segment printed finger (local units, scale 1)
REF_R0    = 60.85;   // total reach (MCP→tip) at len = 0
SLOPE_POS = 1.584;   // dReach/dlen for len ≥ 0
SLOPE_NEG = 1.328;   // dReach/dlen for len < 0
LEN_MIN   = -22;     // safe geometry floor (segment stays printable)
LEN_MAX   = 50;      // safe geometry ceiling

// ── Independent proximal (base) / distal (tip) split ────────────────────────
// The two printed segments each carry their own `len` lever:
//   base = fingermid (proximal phalanx, MCP→PIP), driven by lp
//   tip  = fingertip (middle+distal phalanx, PIP→tip), driven by ld
// The proximal span is exactly the fingermid hinge-to-hinge distance, which is
// analytic from the geometry: the two hinge holes sit at ±(11.5 + lp/3), so
//   proximal span (MCP→PIP) = 23 + (2/3)·lp        [local units, scale 1]
// The total reach REF_R0 therefore splits as proximal(23) + distal(37.85) at
// len 0, and the distal reach follows by difference from the measured total:
//   distal reach (PIP→tip) = 37.85 + (SLOPE−2/3)·ld
// Both reduce to the original shared-`len` finger when lp == ld.
PSPAN0  = 23;               // proximal span (MCP→PIP) at lp = 0
PSLOPE  = 2/3;              // d(proximal span)/dlp
DREACH0 = REF_R0 - PSPAN0;  // 37.85 — distal reach (PIP→tip) at ld = 0

function pspan_local(lp) = PSPAN0 + PSLOPE * lp;
function inv_dreach(d_local) =
    d_local >= DREACH0
        ? (d_local - DREACH0) / (SLOPE_POS - PSLOPE)
        : (d_local - DREACH0) / (SLOPE_NEG - PSLOPE);

// Proximal lever from the requested base (proximal phalanx) length.
function base_lp(base_mm) =
    max(LEN_MIN, min(LEN_MAX, ((base_mm / overall_scale) - PSPAN0) / PSLOPE));

// Distal lever: fill the remainder of the total finger length after the base.
// Preserves total MCP→tip length given the (possibly clamped) proximal segment.
function tip_ld(total_mm, base_mm) =
    max(LEN_MIN, min(LEN_MAX,
        inv_dreach((total_mm / overall_scale) - pspan_local(base_lp(base_mm)))));

// Thumb: uniform scale of the two-segment sub-assembly hits the total thumb
// length; the proximal/distal split is set independently by moving len between
// the two segments at constant sub-assembly reach (THUMB_BASE_REACH), so the
// uniform scale — and therefore the total length — is unchanged by the split.
//   reach_local(lp,ld) = A + B·lp + C·ld   (measured on a 5×4 lp/ld grid,
//                                            max residual 0.74 mm; render-fitted)
// The PIP hinge stays coaxial when the tip is placed at
//   y = -(THUMB_JOIN0 + lp/3 + ld/3)       (render-calibrated; 23.667 → -18 at
//                                            the native -12/-5 split)
THUMB_BASE_REACH = 44.93;   // reference straight MCP→tip reach at scale 1
THUMB_JOIN0      = 23.667;  // PIP join-offset constant
THUMB_REACH_A    = 55.84;   // reach_local intercept
THUMB_REACH_B    = 0.6185;  // d(reach_local)/dlp
THUMB_REACH_C    = 0.77;    // d(reach_local)/dld

function inv_pspan(sp_local) = (sp_local - PSPAN0) / PSLOPE; // proximal span → lp
function thumb_scale() =
    max(0.6, min(1.7, thumb_length_mm / (overall_scale * THUMB_BASE_REACH)));

// Proximal fraction of the thumb → proximal lever (exact printed MCP→IP length =
// overall_scale · thumb_scale · pspan(lp) = thumb_base_length_mm).
function thumb_lp() =
    max(LEN_MIN, min(LEN_MAX,
        inv_pspan((thumb_base_length_mm / thumb_length_mm) * THUMB_BASE_REACH)));
// Distal lever holds the sub-assembly reach at THUMB_BASE_REACH, so the uniform
// thumb_scale keeps the total length exact regardless of the split.
function thumb_ld() =
    max(LEN_MIN, min(LEN_MAX,
        (THUMB_BASE_REACH - THUMB_REACH_A - THUMB_REACH_B * thumb_lp()) / THUMB_REACH_C));

// ── Top-level ───────────────────────────────────────────────────────────────
mirror([mirrored ? 1 : 0, 0, 0])
    scale(overall_scale)
        if (print_layout) printlayout(); else handlayout();

// Assembled hand (original pose), per-finger length + per-part colour/visibility
module handlayout(sp = 14.4) {
    if (show_palm) color(color_palm) cyborgbeastpalm();
    translate([22, 29, 10]) rotate([0, 180, 0]) {
        if (show_index)  place_finger(0,
                base_lp(index_base_length_mm),  tip_ld(index_finger_length_mm,  index_base_length_mm),
                show_index_base,  show_index_tip,  color_index_base,  color_index_tip);
        if (show_middle) place_finger(sp,
                base_lp(middle_base_length_mm), tip_ld(middle_finger_length_mm, middle_base_length_mm),
                show_middle_base, show_middle_tip, color_middle_base, color_middle_tip);
        if (show_ring)   place_finger(sp*2,
                base_lp(ring_base_length_mm),   tip_ld(ring_finger_length_mm,   ring_base_length_mm),
                show_ring_base,   show_ring_tip,   color_ring_base,   color_ring_tip);
        if (show_pinky)  place_finger(sp*3,
                base_lp(pinky_base_length_mm),  tip_ld(pinky_finger_length_mm,  pinky_base_length_mm),
                show_pinky_base,  show_pinky_tip,  color_pinky_base,  color_pinky_tip);
    }
    if (show_thumb)
        translate([41, -9.5, -4]) rotate([50, -20, 90]) scale(thumb_scale()) {
            if (show_thumb_base) color(color_thumb_base) thumbmid();
            if (show_thumb_tip)  color(color_thumb_tip)
                translate([0, -(THUMB_JOIN0 + thumb_lp()/3 + thumb_ld()/3), 5])
                    rotate([30, 180, 180]) thumbtip();
        }
    // Forearm gauntlet auto-seated on the palm wrist-pin axis (prongs nest inside
    // the wrist fins), sized to wrist_circumference_mm, drooping by gauntlet_tilt.
    if (show_gauntlet)
        color(color_gauntlet) seat_gauntlet();
}

// Seat a finger so its proximal (first) hinge hole lands on the palm knuckle
// hinge line. The palm knuckle hinge hole is at y = 27 (in the pre-rotation
// palm frame); the fingermid's proximal hole ends up at
//   29 + yoff - (11.5 + lp/3)
// after the handlayout translate/rotate, so yoff = 9.5 + lp/3 aligns it to 27
// for every finger regardless of its length — the pin then passes cleanly
// through the knuckle block and the finger. The offset tracks the *proximal*
// lever lp only (the base segment's hole spacing), so the finger stays seated
// no matter how the proximal/distal split is set.
module place_finger(x, lp, ld, base = true, tip = true, baseCol = "#cccccc", tipCol = "#dddddd") {
    translate([x, 9.5 + lp/3, 0])
        fingerlayout(lp, ld, base, tip, baseCol, tipCol);
}

// One finger: distal (tip, lever ld) + proximal (base, lever lp) segments, each
// colourable/toggleable. The tip is pushed out by lp/3 (the base's distal-hole
// shift) + ld/3 (the tip's own hinge-hole shift) so the PIP pin passes cleanly
// through both segments for any proximal/distal split. Reduces to the original
// 23 + len·2/3 seating when lp == ld.
module fingerlayout(lp = 0, ld = 0, base = true, tip = true, baseCol = "#cccccc", tipCol = "#dddddd") {
    if (tip)
        color(tipCol) render()
            translate([0, 23 + lp/3 + ld/3, 1.5]) rotate([10, 0, 0]) fingertip(s = 1, grip = 1, len = ld);
    if (base)
        color(baseCol) render()
            mirror([0, 0, 1]) mirror([0, 1, 0]) translate([0, 0, -10]) fingermid(s = 1, len = lp);
}

// Flat print-bed layout: every part spread side-by-side in its native (flat-
// bottomed) print orientation. The STL/3MF exporter seats each part on Z=0.
module printlayout() {
    row = 24;
    _fingers = [
        [show_index,  show_index_base,  show_index_tip,  index_finger_length_mm,  color_index_base,  color_index_tip,  index_base_length_mm],
        [show_middle, show_middle_base, show_middle_tip, middle_finger_length_mm, color_middle_base, color_middle_tip, middle_base_length_mm],
        [show_ring,   show_ring_base,   show_ring_tip,   ring_finger_length_mm,   color_ring_base,   color_ring_tip,   ring_base_length_mm],
        [show_pinky,  show_pinky_base,  show_pinky_tip,  pinky_finger_length_mm,  color_pinky_base,  color_pinky_tip,  pinky_base_length_mm],
    ];
    if (show_palm) color(color_palm) cyborgbeastpalm();
    for (i = [0:len(_fingers)-1]) let(f = _fingers[i], lp = base_lp(f[6]), ld = tip_ld(f[3], f[6]), y = -i*row) {
        if (f[0] && f[1]) color(f[4]) translate([58, y, 0]) fingermid(len = lp);
        if (f[0] && f[2]) color(f[5]) translate([88, y, 0]) fingertip(len = ld, grip = 1);
    }
    if (show_thumb) let(yt = -4*row) scale(thumb_scale()) {
        if (show_thumb_base) color(color_thumb_base) translate([58/thumb_scale(), yt/thumb_scale(), 0]) thumbmid();
        if (show_thumb_tip)  color(color_thumb_tip)  translate([88/thumb_scale(), yt/thumb_scale(), 0]) thumbtip();
    }
    // Gauntlet as its own printable part: opening up, seated on the bed (min z = -17.66).
    // Gauntlet as its own printable part: sized to the wrist, opening up, seated
    // on the bed (native min z = -17.66, scaled by the girth factor).
    if (show_gauntlet)
        color(color_gauntlet) translate([-70, -60, 17.66 * g_girth])
            scale([g_girth, g_len, g_girth])
                gauntlet(pin_hole_d = g_pin_bore, rim_hole_d = gauntlet_rim_hole_d);
}

module thumbmid() { fingermid(len = thumb_lp()); }
module thumbtip() { fingertip(len = thumb_ld(), grip = 1); }
