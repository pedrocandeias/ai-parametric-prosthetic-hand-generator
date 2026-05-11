// Kinetic Hand RH60 — Right Hand, 60 mm gauntlet width
// Parts converted from STEP (SolidWorks 2023) via CadQuery/OpenCASCADE.
// All structural parts are in assembly coordinate space:
//   Z=0   → wrist / gauntlet base
//   Z≈79  → palm body starts
//   Z≈154 → palm top / finger bases
//   Z≈200 → fingertips
// X=0, Y≈9 → approximate wrist joint centre
//
// Parametric control is limited to uniform or sub-group scaling because the geometry
// is fixed STL meshes — see docs/kinetic_hand_rh60_conversion.md for details.

// ── Anthropometric inputs ─────────────────────────────────────────────────────
// RH60 reference at scale 1.0:
//   palm_breadth_mm         = 83  (knuckle-to-knuckle, X-span ≈ 83 mm)
//   middle_finger_length_mm = 72  (MCP crease to fingertip — anatomical measurement;
//                                  the RH60 STL finger reach above the palm is 48 mm,
//                                  which is REF_FINGER_REACH / REF_FINGER = 48/72 of the
//                                  anatomical reference — this ratio is held constant as
//                                  middle_finger_length_mm changes)
//   gauntlet_width_mm       = 62  (forearm socket X-span ≈ 62 mm;
//                                  ≈ wrist_circumference_mm / π + ~5 mm clearance)
palm_breadth_mm         = 83;   // Knuckle-to-knuckle palm width (mm)
middle_finger_length_mm = 72;   // Middle finger MCP crease to tip — anatomical (mm)
gauntlet_width_mm       = 62;   // Forearm socket width — ≈ wrist_circ/π + clearance (mm)

// Reference dimensions of the RH60 design
REF_PALM    = 83;
REF_FINGER  = 72;   // anatomical MCP-to-tip for the reference design
REF_GAUNTLET= 62;

// Derived scale factors
// s_hand  — uniform hand scale (XYZ) based on palm breadth
// s_gz    — additional gauntlet Z stretch to preserve socket height when s_hand changes
// s_fg    — finger-Z multiplier relative to the already-scaled palm top
s_hand  = palm_breadth_mm / REF_PALM;
s_gx    = gauntlet_width_mm / REF_GAUNTLET;   // gauntlet XY independent
s_fz    = (middle_finger_length_mm / REF_FINGER) / s_hand; // finger Z on top of s_hand

FINGER_BASE_Z = 154;   // Z in original coords where fingers begin

// ── Visibility toggles ────────────────────────────────────────────────────────
show_gauntlet      = true;
show_gauntlet_cover= true;
show_palm          = true;
show_wrist_hinges  = true;

// Fingers (odd = proximal phalanx, even = distal phalanx)
// 1=thumb, 2-3=index, 4-5=middle, 6-7=ring, 8-9=pinky
show_finger_1      = true;   // thumb
show_finger_2      = true;   // index proximal
show_finger_3      = true;   // index distal
show_finger_4      = true;   // middle proximal
show_finger_5      = true;   // middle distal
show_finger_6      = true;   // ring proximal
show_finger_7      = true;   // ring distal
show_finger_8      = true;   // pinky proximal
show_finger_9      = true;   // pinky distal

// Hinges at each finger joint
show_hinges        = true;

// ── Helpers ───────────────────────────────────────────────────────────────────

// Gauntlet: independent XY scale, Z unchanged (socket height is fixed by residual limb)
module gauntlet_scale() {
    scale([s_gx, s_gx, 1]) children();
}

// Palm + proximal elements: uniform hand scale
module hand_scale() {
    scale([s_hand, s_hand, s_hand]) children();
}

// Fingers: hand XY scale + independent finger-Z stretch from the knuckle line
module finger_scale() {
    translate([0, 0, FINGER_BASE_Z * s_hand])
    scale([s_hand, s_hand, s_hand * s_fz])
    translate([0, 0, -FINGER_BASE_Z])
    children();
}

// ── Render ────────────────────────────────────────────────────────────────────

// Gauntlet group (socket, wrist)
gauntlet_scale() {
    if (show_gauntlet)       import("gauntlet.stl");
    if (show_gauntlet_cover) import("gauntlet_cover.stl");
    if (show_wrist_hinges) {
        import("wrist_hinge_1.stl");
        import("wrist_hinge_2.stl");
    }
}

// Palm
if (show_palm) hand_scale() import("palm.stl");

// Thumb (sits mid-palm, scales with hand)
if (show_finger_1) hand_scale() import("finger_1.stl");
if (show_hinges)   hand_scale() import("hinge_1.stl");

// Index finger
if (show_finger_2) finger_scale() import("finger_2.stl");
if (show_finger_3) finger_scale() import("finger_3.stl");
if (show_hinges) {
    finger_scale() import("hinge_2.stl");
    finger_scale() import("hinge_3.stl");
}

// Middle finger
if (show_finger_4) finger_scale() import("finger_4.stl");
if (show_finger_5) finger_scale() import("finger_5.stl");
if (show_hinges) {
    finger_scale() import("hinge_4.stl");
    finger_scale() import("hinge_5.stl");
}

// Ring finger
if (show_finger_6) finger_scale() import("finger_6.stl");
if (show_finger_7) finger_scale() import("finger_7.stl");
if (show_hinges) {
    finger_scale() import("hinge_6.stl");
    finger_scale() import("hinge_7.stl");
}

// Pinky finger
if (show_finger_8) finger_scale() import("finger_8.stl");
if (show_finger_9) finger_scale() import("finger_9.stl");
if (show_hinges) {
    finger_scale() import("hinge_8.stl");
    finger_scale() import("hinge_9.stl");
}
