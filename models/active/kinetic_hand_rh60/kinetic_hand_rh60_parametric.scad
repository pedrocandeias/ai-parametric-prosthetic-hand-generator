// kinetic_hand_rh60_parametric.scad
// Master assembly — Kinetic Hand RH60 (fully parametric, no STL imports)
//
// Brings together five component files, each of which encodes its geometry
// as polyhedron() calls so no external STL files are required.
//
// Components:
//   kinetic_hand_finger_middle.scad  — proximal phalanx, distal phalanx, 2 hinges
//   kinetic_hand_thumb.scad          — thumb phalanx, thumb hinge
//   kinetic_hand_palm.scad           — palm body
//   kinetic_hand_gauntlet.scad       — gauntlet body + cover
//   kinetic_hand_wrist.scad          — 2 wrist hinges
//
// Assembly coordinate frame (shared with all components):
//   Z = 0    → wrist / gauntlet base
//   Z ≈ 154  → finger base / MCP knuckle line
//   Z ≈ 202  → fingertips
//
// Dynamic-scoping note
// ─────────────────────
// All five component files are loaded with use<> so their modules are
// imported but their top-level render calls and variable assignments are
// NOT executed.  The modules inside those files use dynamic scoping —
// they resolve variable names in the calling scope at render time.
// Therefore every variable that a component module reads must be defined
// here in the assembly file BEFORE the assembly modules are called.
//
// This file re-declares every constant that the component modules depend
// on, so they all resolve correctly from this scope.
//
// ─────────────────────────────────────────────────────────────────────

// ── Component imports ─────────────────────────────────────────────────
use <kinetic_hand_finger_middle.scad>
use <kinetic_hand_thumb.scad>
use <kinetic_hand_palm.scad>
use <kinetic_hand_gauntlet.scad>
use <kinetic_hand_wrist.scad>

// ────────────────────────────────────────────────────────────────────────────
// ANTHROPOMETRIC INPUTS
// ────────────────────────────────────────────────────────────────────────────

/* [Anthropometric] */

// Knuckle-to-knuckle palm breadth — drives XY scale for all hand parts (mm)
palm_breadth_mm = 83;       // [50:1:120]

// Wrist base to middle MCP crease length (mm)
palm_length_mm = 95;        // [60:1:140]

// Palmar to dorsal surface thickness (mm)
palm_thickness_mm = 32;     // [18:1:50]

// Middle finger MCP crease to fingertip — anatomical measurement (mm)
middle_finger_length_mm = 72;  // [40:1:120]

// Thumb MCP crease to fingertip — anatomical measurement (mm)
thumb_length_mm = 65;       // [35:1:100]

// Forearm socket width (mm)
// Derive: gauntlet_width_mm ≈ wrist_circumference_mm / π + 5 mm clearance
gauntlet_width_mm = 62;     // [40:1:90]

// ────────────────────────────────────────────────────────────────────────────
// VISIBILITY
// ────────────────────────────────────────────────────────────────────────────

/* [Visibility] */

// Show palm body
show_palm = true;

// Show all four fingers (index / middle / ring / pinky)
show_fingers = true;

// Show thumb
show_thumb = true;

// Show gauntlet (forearm socket) and cover
show_gauntlet = true;

// Show wrist hinges
show_wrist_hinges = true;

// Show finger and thumb joint hinges
show_hinges = true;

// ────────────────────────────────────────────────────────────────────────────
// INTERNAL CONSTANTS — re-declared from component files so dynamic scoping
// resolves correctly when their modules are called from this file.
// ────────────────────────────────────────────────────────────────────────────

/* [Hidden] */

// ── Finger / thumb reference dimensions (kinetic_hand_finger_middle.scad) ──
REF_FINGER    = 72;       // anatomical MCP-to-tip at scale 1.0 (mm)
REF_PALM      = 83;       // palm breadth at scale 1.0 (mm)
REF_REACH     = 48.3927;  // STL finger reach in assembly space at scale 1.0 (mm)
FINGER_BASE_Z = 154;      // assembly Z where fingers begin (palm top)

// ── Thumb reference dimensions (kinetic_hand_thumb.scad) ─────────────────
REF_THUMB       = 65.0;    // anatomical MCP-to-tip at scale 1.0 (mm)
REF_THUMB_REACH = 31.4713; // STL thumb reach in assembly space at scale 1.0 (mm)
THUMB_BASE_Z    = 101.453; // assembly Z where thumb begins (hinge bottom)

// Thumb part offsets (native coords — no translation required at reference scale)
THUMB_FINGER_OFFSET_X = 0;
THUMB_FINGER_OFFSET_Y = 0;
THUMB_FINGER_OFFSET_Z = 0;
THUMB_HINGE_OFFSET_X  = 0;
THUMB_HINGE_OFFSET_Y  = 0;
THUMB_HINGE_OFFSET_Z  = 0;

// ── Palm reference dimensions (kinetic_hand_palm.scad) ───────────────────
REF_PALM_BREADTH = 83;    // palm breadth at scale 1.0 (mm) — X axis
REF_PALM_LENGTH  = 95;    // palm length at scale 1.0 (mm)  — Z axis
REF_PALM_THICK   = 32;    // palm thickness at scale 1.0 (mm) — Y axis

// STL bounding extents at scale 1.0 (used internally by palm_transform)
REF_STL_X = 84.3107;
REF_STL_Y = 43.2793;
REF_STL_Z = 74.2192;

// ── Gauntlet reference dimensions (kinetic_hand_gauntlet.scad) ───────────
REF_GAUNTLET_WIDTH = 62;  // gauntlet X extent at scale 1.0 (mm)

// Gauntlet cover offset constants (assembly space, reference scale)
COVER_OFFSET_X = 0.0000;
COVER_OFFSET_Y = 22.3567;
COVER_OFFSET_Z = 1.7597;

// Gauntlet scale pivot (used by gauntlet_transform)
GAUNTLET_CX = 0.0000;
GAUNTLET_CY = 8.8188;
GAUNTLET_CZ = 0;

// ── Wrist hinge reference dimensions (kinetic_hand_wrist.scad) ───────────
REF_HINGE_SPAN     = 62.3604; // hinge_1.x_max − hinge_2.x_min at scale 1.0

// Wrist hinge offset constants (assembly space, reference scale)
WRIST_HINGE1_OFFSET_X = 21.4221;
WRIST_HINGE1_OFFSET_Y = -1.0000;
WRIST_HINGE1_OFFSET_Z = 68.4479;
WRIST_HINGE2_OFFSET_X = -31.1802;
WRIST_HINGE2_OFFSET_Y = -1.0000;
WRIST_HINGE2_OFFSET_Z = 68.4504;

// ── Finger part-level offsets (kinetic_hand_finger_middle.scad) ───────────
// These are used by middle_finger() when rendering individual instances.
// Set to zero here; per-finger column translation is handled at assembly level.
proximal_x_offset = 0;
proximal_y_offset = 0;
proximal_z_offset = 0;
proximal_hinge_x_offset = 0;
proximal_hinge_y_offset = 0;
proximal_hinge_z_offset = 0;
distal_x_offset = 0;
distal_y_offset = 5;    // matches default in component file
distal_z_offset = 5.5;  // matches default in component file
distal_hinge_x_offset = 0;
distal_hinge_y_offset = 0;
distal_hinge_z_offset = 0;

// ── Visibility flags forwarded to component modules ───────────────────────
// These variable names are read by the component modules via dynamic scoping.
show_proximal_phalanx = show_fingers;
show_distal_phalanx   = show_fingers;
show_thumb_phalanx    = show_thumb;
show_thumb_hinge      = show_hinges;
show_gauntlet_body    = show_gauntlet;
show_gauntlet_cover   = show_gauntlet;
show_wrist_hinge_1    = show_wrist_hinges;
show_wrist_hinge_2    = show_wrist_hinges;

// ── Derived scale factors ─────────────────────────────────────────────────
// Modules in the component files reference these variable names via dynamic
// scoping.  Because use<> skips top-level assignments in the component files,
// these MUST be computed here in the assembly scope so the transform modules
// can resolve them at render time.

// Finger / thumb XY scale (kinetic_hand_finger_middle.scad, kinetic_hand_thumb.scad)
s_xy = palm_breadth_mm / REF_PALM;

// Finger Z multiplier above FINGER_BASE_Z (kinetic_hand_finger_middle.scad)
s_fz = (middle_finger_length_mm / REF_FINGER) / s_xy;

// Thumb Z multiplier above THUMB_BASE_Z (kinetic_hand_thumb.scad)
s_tz = (thumb_length_mm / REF_THUMB) / s_xy;

// Palm independent axis scales (kinetic_hand_palm.scad)
s_x = palm_breadth_mm  / REF_PALM_BREADTH;
s_y = palm_thickness_mm / REF_PALM_THICK;
s_z = palm_length_mm    / REF_PALM_LENGTH;

// Gauntlet uniform scale (kinetic_hand_gauntlet.scad)
s_g = gauntlet_width_mm / REF_GAUNTLET_WIDTH;

// Wrist hinge uniform scale (kinetic_hand_wrist.scad)
s_w = gauntlet_width_mm / REF_GAUNTLET_WIDTH;

// ────────────────────────────────────────────────────────────────────────────
// FINGER COLUMN X-OFFSETS
// ────────────────────────────────────────────────────────────────────────────
// The middle_finger() module geometry is positioned at the middle finger
// column (native assembly X ≈ −1 mm at reference scale).
// The four finger columns are spaced ~14 mm apart at reference scale.
// Offsets are proportional to palm_breadth_mm so spacing scales with hand size.
//
// At reference scale (palm_breadth_mm = 83):
//   index  → +21 mm from middle column centre
//   middle →   0 mm (native)
//   ring   → −14 mm
//   pinky  → −27 mm
//
// These are in pre-scale assembly space; finger_transform() applies s_xy
// uniformly, so the spacing will be correct at any palm_breadth_mm.

FINGER_INDEX_X  =  21;   // X offset for index finger column (mm, reference scale)
FINGER_MIDDLE_X =   0;   // X offset for middle finger column (0 = native position)
FINGER_RING_X   = -14;   // X offset for ring finger column (mm, reference scale)
FINGER_PINKY_X  = -27;   // X offset for pinky finger column (mm, reference scale)

// Y and Z offsets for finger columns (tuning only — leave at 0 for default fit)
FINGER_INDEX_Y  = 0;
FINGER_INDEX_Z  = 0;
FINGER_MIDDLE_Y = 0;
FINGER_MIDDLE_Z = 0;
FINGER_RING_Y   = 0;
FINGER_RING_Z   = 0;
FINGER_PINKY_Y  = 0;
FINGER_PINKY_Z  = 0;

// ────────────────────────────────────────────────────────────────────────────
// THUMB COLUMN OFFSET
// ────────────────────────────────────────────────────────────────────────────
// The thumb geometry (kinetic_hand_thumb.scad) already positions the thumb
// at the correct X in the right-hand assembly (x ≈ [35, 64] at ref scale).
// No additional X translation is required.

THUMB_COLUMN_X = 0;
THUMB_COLUMN_Y = 0;
THUMB_COLUMN_Z = 0;

// ────────────────────────────────────────────────────────────────────────────
// ASSEMBLY — place each component in the shared coordinate frame
// ────────────────────────────────────────────────────────────────────────────

// ── Gauntlet (forearm socket + cover) ────────────────────────────────────
// gauntlet_assembly() calls gauntlet_transform() → uniform s_g scale from Z=0.
// show_gauntlet_body and show_gauntlet_cover are resolved via dynamic scoping.
if (show_gauntlet) gauntlet_assembly();

// ── Wrist hinges ──────────────────────────────────────────────────────────
// wrist_assembly() calls wrist_transform() → uniform s_w scale from Z=0.
// show_wrist_hinge_1 and show_wrist_hinge_2 resolved via dynamic scoping.
if (show_wrist_hinges) wrist_assembly();

// ── Palm ──────────────────────────────────────────────────────────────────
// palm_assembly() calls palm_transform() → independent s_x / s_y / s_z scale
// about the palm centroid.
// show_palm resolved via dynamic scoping.
if (show_palm) palm_assembly();

// ── Thumb ─────────────────────────────────────────────────────────────────
// thumb_assembly() calls thumb_transform() → XY by s_xy, Z by s_xy * s_tz
// pivoting at THUMB_BASE_Z.
// show_thumb_phalanx and show_thumb_hinge resolved via dynamic scoping.
if (show_thumb) thumb_assembly();

// ── Four finger columns ───────────────────────────────────────────────────
// middle_finger() calls finger_transform() → XY by s_xy, Z-above-FINGER_BASE_Z
// by s_xy * s_fz.
// Translate each instance in pre-scale reference space so that
// finger_transform() will apply s_xy uniformly to both the geometry and
// the column offset.
//
// Note: the translate() wraps the entire finger_transform() call.
// finger_transform() itself translates into scaled space, so the per-column
// translate here must be applied in the same coordinate frame as the input
// to finger_transform() (i.e. reference / pre-scale space at the finger
// base level). We achieve this by placing the translate *inside* a helper
// that first descends to reference space, translates, then re-applies scale —
// but since finger_transform() already handles the pivot and scale, the
// cleanest approach is to translate the whole assembled finger in world
// (already-scaled) space. At reference scale s_xy=1 so the offsets are
// identical; at other scales we must multiply by s_xy.
//
// s_xy is already computed above in the derived scale factors section.
// World-space X column shifts are scaled proportionally to palm_breadth_mm.

if (show_fingers) {
    // Index finger
    translate([FINGER_INDEX_X * s_xy, FINGER_INDEX_Y, FINGER_INDEX_Z])
        middle_finger();

    // Middle finger (native position)
    translate([FINGER_MIDDLE_X * s_xy, FINGER_MIDDLE_Y, FINGER_MIDDLE_Z])
        middle_finger();

    // Ring finger
    translate([FINGER_RING_X * s_xy, FINGER_RING_Y, FINGER_RING_Z])
        middle_finger();

    // Pinky finger
    translate([FINGER_PINKY_X * s_xy, FINGER_PINKY_Y, FINGER_PINKY_Z])
        middle_finger();
}
