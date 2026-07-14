/*
 * Flexy Beast — Parametric Prosthetic Hand
 *
 * Adapted from the Flexy Beast by daprice
 * https://github.com/daprice/Flexy-Beast  (CC BY-SA 4.0)
 *
 * A mashup of the Parametric Cyborg Beast (MakerBlock) and the Flexy Hand
 * (Steve Wood / Gyrobot). Flexible joints replace Chicago screws and elastics,
 * making the hand lighter, cheaper, and easier to assemble.
 *
 * All dimensions in millimetres. Scale is derived from the Cyborg Beast sizing
 * guide: xScaleFactor = (knuckle_breadth_mm + 5) / 55.
 */

/* [Anthropometric] */

// Knuckle-to-knuckle metacarpal breadth — drives uniform palm and hand scale (mm)
palm_breadth_mm = 83; // [55:1:110]

// Middle finger MCP crease to tip — drives global finger length scale (mm)
middle_finger_length_mm = 72; // [40:1:120]

// Index finger MCP crease to tip (mm)
index_finger_length_mm = 68; // [40:1:120]

// Ring finger MCP crease to tip (mm)
ring_finger_length_mm = 68; // [40:1:120]

// Pinky finger MCP crease to tip (mm)
pinky_finger_length_mm = 55; // [30:1:100]

// Thumb MCP crease to tip (mm)
thumb_length_mm = 65; // [35:1:100]

/* [Hardware] */

// Flexy joint hole diameter (mm) — reduce for small children's hands
joint_dia = 7; // [4:0.5:10]

// Flexy joint slot thickness (mm)
joint_thick = 4; // [1:0.5:6]

/* [Options] */

// Hollow fingertips for casting silicone grip pads
finger_pads = true;

// Show installed silicone grip pads in the preview
show_pads = true;

// Silicone pad color (overlay drawn on top of each fingertip's own colour)
pad_color = "#e8c8a0";

// ── Per-part colours ────────────────────────────────────────────────────────
// One colour per printable part. These show in the preview and are baked into
// the 3MF export (one 3MF material per colour) for multi-material printing.
// base = proximal segment, tip = distal segment.
color_palm        = "#cbd5e1"; // palm body
color_gauntlet    = "#94a3b8"; // forearm cuff
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
color_hinge       = "#2f4b7c"; // flexy joints (flexible filament connectors)

// Show thermoformable mesh on palm interior (for heat-forming to patient)
show_thermoform = true;

// Show the flexy joints — the flexible connector pieces that sit in the gap at
// each finger/thumb joint and act as the living hinge. In the assembled view they
// fill the joint holes between the segments; in print_layout they lay out flat on
// a plate to print in flexible filament (Filaflex/TPU). They are sized from the
// joint hole/slot (joint_dia, joint_thick) and the hand scale, so they track every
// finger and hardware parameter change.
show_hinges = true;

// Mirror geometry for right hand (default produces left hand)
mirrored = false;

// Print-bed layout: spread every part flat side-by-side for 3D printing instead
// of the assembled hand pose. Set true by the STL exporter; the preview keeps the
// assembled view (false). Each part is emitted in its native print orientation;
// the exporter seats each on the bed (Z=0) when writing the STL.
print_layout = false;

/* [Gauntlet] */

// Show the forearm gauntlet — a separate printed part reconstructed from the
// Normal Gauntlet with Tensioner. It is the SAME cuff used by the Cyborg Beast:
// the two hands share the Cyborg Beast palm and wrist hinge, so one part fits
// both. It pins to the palm's wrist hinge axis and is sized to the wearer's
// forearm independently of hand scale.
show_gauntlet = true;

// Forearm circumference at the wrist (mm) — sizes the gauntlet cuff girth to the
// wearer, independently of hand scale: cuff width = circumference/PI + clearance.
wrist_circumference_mm = 160; // [110:1:260]

// Forearm droop angle — the gauntlet pivots this far about the wrist pin (deg)
gauntlet_tilt = 0; // [-10:1:40]

// Forearm length multiplier (1 = native reconstructed length)
gauntlet_length_scale = 0.7; // [0.7:0.05:1.5]

// Strap-hole diameters on the gauntlet rim (mm)
gauntlet_rim_hole_d = 2.5; // [1.5:0.5:6]

// Manual fine-tune on top of the automatic wrist-pin seating (local mm)
gauntlet_nudge = [0, 0, 0];

/* [Wrist Hinge] */

// Wrist hinge pin diameter — the gauntlet prongs nest inside the palm wrist fins
// and this pin runs fin-prong-prong-fin (defaults to the finger joint pin) (mm)
wrist_pin_dia = 7; // [4:0.5:10]

// Clearance around the wrist pin so the gauntlet pivots freely (mm)
wrist_pin_clearance = 0.35; // [0.1:0.05:0.8]

/* [Visibility] */

// Show palm body (per-part STL export)
show_palm = true;
// Show index finger
show_index = true;
// Show middle finger
show_middle = true;
// Show ring finger
show_ring = true;
// Show pinky finger
show_pinky = true;
// Show thumb
show_thumb = true;

// Each finger prints as two separate pieces: a base (proximal segment that
// pins to the palm) and a curved tip (distal segment with the fingertip pad).
// These toggles isolate a single piece for per-part STL export.
// Show index finger base
show_index_base = true;
// Show index fingertip
show_index_tip = true;
// Show middle finger base
show_middle_base = true;
// Show middle fingertip
show_middle_tip = true;
// Show ring finger base
show_ring_base = true;
// Show ring fingertip
show_ring_tip = true;
// Show pinky finger base
show_pinky_base = true;
// Show pinky fingertip
show_pinky_tip = true;
// Show thumb base
show_thumb_base = true;
// Show thumb tip
show_thumb_tip = true;

// ── Derived configuration ─────────────────────────────────────────────────────

// Cyborg Beast sizing guide: (knuckle_width + 5) / 55
xScaleFactor = (palm_breadth_mm + 5) / 55;
yScaleFactor = xScaleFactor;
zScaleFactor = xScaleFactor;

// At scale=1 the finger reach is fingerbase(20) + fingertip_curved(17) = 37 mm.
// fingerLength scales all segment lengths so the middle finger reaches
// middle_finger_length_mm anatomically.
REF_FINGER_MM = 37;
fingerLength = middle_finger_length_mm / (REF_FINGER_MM * xScaleFactor);

// Per-finger length proportions relative to middle finger
indexProp  = index_finger_length_mm  / middle_finger_length_mm;
middleProp = 1;
ringProp   = ring_finger_length_mm   / middle_finger_length_mm;
pinkyProp  = pinky_finger_length_mm  / middle_finger_length_mm;
thumbProp  = thumb_length_mm         / middle_finger_length_mm;

// Low-level config constants (match original Flexy Beast defaults)
knuckleR       = 4.85;
knucklePadding = 0.5;
knuckleW       = 9.5;
wristH         = 10;
palmH          = 20;
palmW          = 64;
th             = 3;
fn             = 32;
jointDia       = joint_dia;
jointThick     = joint_thick;

// ── Flexy joint (hinge) geometry (derived) ────────────────────────────────────
// Each joint hole in the hand is a pin bore (jointDia) crossed by a thin slot
// (jointThick). The flexy joint is the flexible connector that lives in that slot
// and bridges two adjacent knuckle blocks — a "dogbone": two lobes wrapping the
// pin axes joined by a thin flexing web. Every dimension is derived from the joint
// hardware and the hand scale, so the connector resizes with the fingers.
h_wall   = 1.2;                          // material around each pin bore (mm, native)
h_lobe_r = jointDia/2 + h_wall;          // lobe radius (wraps the pin)
h_web_t  = jointThick;                   // flexing web thickness = slot thickness
h_len    = knuckleW * xScaleFactor;      // length along the pin axis (fills slot width)
h_span   = 8 * xScaleFactor;             // lobe centre-to-centre (knuckle-gap bridge)
h_bore   = jointDia;                     // pin clearance bore through each lobe

include <gauntlet.scad>

// ── Gauntlet placement (derived) ──────────────────────────────────────────────
// The gauntlet (Normal Gauntlet with Tensioner) is the SAME reconstructed part
// used by the Cyborg Beast — both hands share the Cyborg Beast palm and wrist
// hinge, so one cuff fits both (this gauntlet.scad is a copy of the Cyborg Beast
// file). It is scaled anisotropically so its two prongs always nest against the
// palm wrist fins (fixed X), its girth tracks wrist_circumference_mm, and its
// length tracks gauntlet_length_scale; then it is auto-seated on the palm
// wrist-pin axis for any girth/length/tilt. Measured native gauntlet: width
// 49.88 mm, prong pin-hole at (±22.6, -58.3, -9.8).
G_NATIVE_W = 49.88;                 // native cuff width (X extent), mm
G_PRONG_X  = 22.6;                  // native prong pin-hole |X|
G_PRONG_Y  = -58.3;                 // native prong pin-hole Y
G_PRONG_Z  = -9.8;                  // native prong pin-hole Z
G_FIN_X    = 26.6;                  // palm wrist-fin |X| (prongs nest just inside)
G_PIN_Y    = -27;                   // palm wrist-pin axis, local Y (hardwarecutouts wrist hinge)
G_PIN_Z    = 5.5;                   // palm wrist-pin axis, local Z (wrist hinge bore z=5.5)

// X: prong pin-holes land 2.6 mm inside the wrist fins (fixed to the palm).
g_hinge = (G_FIN_X - 2.6) / G_PRONG_X;
// Z (cuff girth) sized to wrist_circumference_mm; the /xScaleFactor pre-division
// cancels the outer scale([xScaleFactor…]) in gauntlet_part() so the PRINTED girth
// is exactly circumference/PI + clearance regardless of hand scale.
g_depth = (wrist_circumference_mm / PI + 6) / (G_NATIVE_W * xScaleFactor);
g_len   = gauntlet_length_scale;
// prong pin-hole position after scale([g_hinge,g_len,g_depth]) then rotate([tilt,0,180]):
g_prong_y = -G_PRONG_Y * g_len * cos(gauntlet_tilt) - G_PRONG_Z * g_depth * sin(gauntlet_tilt);
g_prong_z = -G_PRONG_Y * g_len * sin(gauntlet_tilt) + G_PRONG_Z * g_depth * cos(gauntlet_tilt);
g_seat     = [0, G_PIN_Y - g_prong_y, G_PIN_Z - g_prong_z];
g_pin_bore = wrist_pin_dia + 2 * wrist_pin_clearance;

// ── Top-level assembly ────────────────────────────────────────────────────────

mirror([mirrored ? 1 : 0, 0, 0])
    if (print_layout) printlayout();
    else handlayout();

// ── Assembly ──────────────────────────────────────────────────────────────────

module handlayout(sp = 14) {
    if (show_palm) color(color_palm) cyborgbeastpalm();
    translate([20.5*xScaleFactor, 33*yScaleFactor, 7*zScaleFactor])
        rotate([0, 180, 0]) {
        if (show_index)  translate([0*xScaleFactor,    7.5*yScaleFactor, 0]) fingerlayout(indexProp  * fingerLength, base = show_index_base,  tip = show_index_tip,  baseCol = color_index_base,  tipCol = color_index_tip,  hinge = true);
        if (show_middle) translate([sp*xScaleFactor,   7.5*yScaleFactor, 0]) fingerlayout(middleProp * fingerLength, base = show_middle_base, tip = show_middle_tip, baseCol = color_middle_base, tipCol = color_middle_tip, hinge = true);
        if (show_ring)   translate([sp*2*xScaleFactor, 7.5*yScaleFactor, 0]) fingerlayout(ringProp   * fingerLength, base = show_ring_base,   tip = show_ring_tip,   baseCol = color_ring_base,   tipCol = color_ring_tip,   hinge = true);
        if (show_pinky)  translate([sp*3*xScaleFactor, 7.5*yScaleFactor, 0]) fingerlayout(pinkyProp  * fingerLength, base = show_pinky_base,  tip = show_pinky_tip,  baseCol = color_pinky_base,  tipCol = color_pinky_tip,  hinge = true);
    }
    if (show_thumb)
    translate([36*xScaleFactor, -15.5*yScaleFactor, 0.5*zScaleFactor])
        rotate([50, -20, 90]) {
        if (show_thumb_base) color(color_thumb_base) thumbmid();
        if (show_thumb_tip) color(color_thumb_tip) translate([0, -22*yScaleFactor, 0*zScaleFactor]) rotate([0, 0, -90]) thumbtip();
        if (show_hinges) color(color_hinge) thumb_hinges();
    }
    if (show_gauntlet) color(color_gauntlet) gauntlet_part();
}

// ── Print-bed layout ──────────────────────────────────────────────────────────

// Every part spread out flat for 3D printing, instead of handlayout's assembled
// hand pose. Each piece keeps its native print orientation (palm palmar-down,
// fingers on their backs, cuff on its straps); the STL exporter seats each part
// on Z=0 when writing the file. Pieces are gated exactly as handlayout gates them
// so per-part STL export isolates the same geometry. Spacing scales with the hand.
module printlayout() {
    _row    = 15 * yScaleFactor;   // Y pitch between stacked finger pieces
    _base_x = 56 * xScaleFactor;   // X of the finger-base column (clear of the palm)
    _tip_x  = 96 * xScaleFactor;   // X of the fingertip column

    // Palm in its native orientation.
    if (show_palm) color(color_palm) cyborgbeastpalm();

    // Four fingers stacked index→pinky; each piece gated + coloured like handlayout.
    _fingers = [
        [show_index,  show_index_base,  show_index_tip,  indexProp,  color_index_base,  color_index_tip],
        [show_middle, show_middle_base, show_middle_tip, middleProp, color_middle_base, color_middle_tip],
        [show_ring,   show_ring_base,   show_ring_tip,   ringProp,   color_ring_base,   color_ring_tip],
        [show_pinky,  show_pinky_base,  show_pinky_tip,  pinkyProp,  color_pinky_base,  color_pinky_tip],
    ];
    for (i = [0:len(_fingers)-1]) let(f = _fingers[i], _y = (1.5 - i) * _row)
        if (f[0]) {
            if (f[1]) color(f[4]) translate([_base_x, _y, 0]) fingerbase(length = 20 * f[3] * fingerLength);
            if (f[2]) color(f[5]) translate([_tip_x,  _y, 0]) fingertip_curved_solid(length = 17 * f[3] * fingerLength, pad = finger_pads);
        }

    // Thumb base + tip on a row below the fingers.
    if (show_thumb) let(_yt = -2.7 * _row) {
        if (show_thumb_base) color(color_thumb_base) translate([_base_x, _yt, 0]) fingerbase(length = 20 * thumbProp * fingerLength);
        if (show_thumb_tip)  color(color_thumb_tip)  translate([_tip_x,  _yt, 0]) thumbtip();
    }

    // Gauntlet as its own printable part: sized to the wrist, opening up, seated
    // on the bed (native min z = -17.66, scaled by the cuff-depth factor g_depth).
    if (show_gauntlet)
        color(color_gauntlet)
            scale([xScaleFactor, yScaleFactor, zScaleFactor])
                translate([-70, -60, 17.66 * g_depth])
                    scale([g_hinge, g_len, g_depth])
                        gauntlet(pin_hole_d = g_pin_bore, rim_hole_d = gauntlet_rim_hole_d);

    // Flexy joints laid flat on a plate, off to the side of the palm.
    if (show_hinges)
        color(color_hinge) translate([-70 * xScaleFactor, 10 * yScaleFactor, 0]) hinge_plate();
}

// ── Gauntlet (forearm cuff, shared with the Cyborg Beast) ─────────────────────

// Place the sized gauntlet, seated on the palm wrist pin. Wrapped in the hand's
// uniform scale so the local-frame seat math (G_PIN_Y/Z) lands on the scaled palm
// wrist bore; g_depth already divides by xScaleFactor so the girth stays physical.
// The prong pin-holes are drilled by gauntlet(pin_hole_d=…); with the default
// gauntlet_length_scale the Y/Z scale factors are near-equal so they stay round.
module gauntlet_part() {
    scale([xScaleFactor, yScaleFactor, zScaleFactor])
        translate(g_seat + gauntlet_nudge)
            rotate([gauntlet_tilt, 0, 180])
                scale([g_hinge, g_len, g_depth])
                    gauntlet(pin_hole_d = g_pin_bore, rim_hole_d = gauntlet_rim_hole_d);
}

// lengthMult: positional arg — fixes the original Flexy Beast parameter-name mismatch.
// base/tip select which of the finger's two printable pieces to emit. hinge adds
// the two flexy joints (MCP + PIP) in the finger's own frame so they inherit the
// finger pose and length scaling; handlayout passes it, printlayout does not.
module fingerlayout(lengthMult = 1, base = true, tip = true, baseCol = "#cccccc", tipCol = "#cccccc", hinge = false) {
    if (tip)
    color(tipCol)
    rotate([180, -10, 90])
        translate([15*lengthMult, -8, -10])
            fingertip_curved_solid(length = 17*lengthMult, pad = finger_pads);
    if (base)
    color(baseCol)
    rotate([180, -5, 90])
        translate([-20, -8, -12])
            fingerbase(length = 20*lengthMult);
    // Flexy joints: placed in fingerbase's output frame, at the proximal (MCP) and
    // distal (PIP) pin bores — exactly where fingerhardwarecutouts drills them.
    if (hinge && show_hinges)
    color(color_hinge)
    rotate([180, -5, 90])
        translate([-20, -8, -12]) {
            _bx = 7 - 15/jointDia;                       // pin bore along length (proximal)
            _by = knuckleW*xScaleFactor/2;               // pin bore across width
            _bz = 6*zScaleFactor - 1.8/jointThick;       // pin bore height
            _dx = 20*lengthMult*yScaleFactor - _bx;      // pin bore along length (distal)
            // One lobe sits on this segment's pin; the other reaches into the
            // neighbour (MCP → toward palm/-X; PIP → toward tip/+X).
            translate([_bx - h_span/2, _by, _bz]) rotate([90, 90, 0]) flexy_joint();
            translate([_dx + h_span/2, _by, _bz]) rotate([90, 90, 0]) flexy_joint();
        }
}

module thumbmid() {
    rotate([0, 0, -90]) fingerbase(length = 20 * thumbProp * fingerLength);
}

// ── Palm ──────────────────────────────────────────────────────────────────────

module cyborgbeastpalm() {
    difference() {
        scale([xScaleFactor, yScaleFactor, zScaleFactor]) {
            difference() {
                cyborgbeast07palm();
                cyborgbeast07palminsidespace();
                for (i = [-3, -1, 1, 3]) translate([i*7, 28, 0]) {
                    translate([0, 4.5, 0]) {
                        cube([knuckleW + knucklePadding, 10, 21.6], center = true);
                        rotate([-45, 0, 0]) cube([knuckleW + knucklePadding, 14, 21.6], center = true);
                    }
                    translate([0, 0.1, 0.5]) rotate([90, 0, 0]) cylinder(r=1.25, h=5, $fn=fn/2);
                    translate([0, -4.5, 0]) rotate([30, 0, i*-6]) cylinder(r=1.25, h=100, center=false, $fn=fn/2);
                    render() difference() {
                        hull() translate([0, -4.5, 0]) {
                            rotate([30, 0, i*-6]) cylinder(r=1.25, h=100, center=false, $fn=fn/2);
                            rotate([0, 0, 0])     cylinder(r=1.25, h=100, center=false, $fn=fn/2);
                        }
                        translate([0, 0, -100/2 + 10]) cube(100, center=true);
                    }
                }
                translate([40, -13, 6.5]) {
                    translate([0, 5.5, -5]) rotate([0, 90, 40]) translate([0, 0, -7.5])
                        cylinder(r=1.25*(1/yScaleFactor), h=5, $fn=fn/2);
                    rotate([-70, 20, 0])
                        translate([11, 4.1, 0]) {
                            cube([21.6, 15, knuckleW + knucklePadding], center=true);
                            rotate([0, 0, -50]) cube([50, 19.5, knuckleW + knucklePadding], center=true);
                        }
                }
                translate([0, 0, -100/2]) cube(100, center=true);
            }
        }
        hardwarecutouts();
    }

    if (show_thermoform) intersection() {
        scale([xScaleFactor+0.1, yScaleFactor+0.1, zScaleFactor+0.1])
            cyborgbeast07palminsidespace();
        translate([-35*xScaleFactor, -22*yScaleFactor, 0])
            thermoform_mesh(size=[70*xScaleFactor, 50*yScaleFactor]);
    }
}

module cyborgthumbsolid() {
    translate([-1.5, -2.4, 0]) rotate([91, 90, 20]) knuckleblock();
    hull() {
        translate([-20, 0, 5]) rotate([0, 30, 0]) scale([1, 1, 0.5]) sphere(r=9);
        hull() {
            cylinder(r=4.5, h=14-1, center=true, $fn=fn*2);
            translate([-10, -1, 0]) cylinder(r=4.5, h=12, center=true, $fn=fn*2);
            rotate([-10, 0, 0]) translate([-10, -6, -1]) cylinder(r=4.5, h=11, center=true, $fn=fn*2);
        }
        hull() {
            rotate([-20, 0, 0]) translate([-10, -8, -3]) cylinder(r=5, h=7, center=true, $fn=fn*2);
            rotate([-10, 0, 0]) translate([-10, -6, -1]) cylinder(r=4.5, h=9, center=true, $fn=fn*2);
            rotate([-20, 0, 0]) translate([-16, -10, -1]) cylinder(r=4.5, h=9, center=true, $fn=fn*2);
        }
    }
}

module cyborgbeast07palminsidespace() {
    for (i = [0, 1]) mirror([i, 0, 0]) {
        hull() {
            translate([13, 13, 0]) cylinder(r=3, h=100, center=true, $fn=fn/2);
            translate([10, 5, 0])  cylinder(r=2, h=100, center=true, $fn=fn/2);
        }
        hull() {
            translate([10, 5, 0]) cylinder(r=2, h=100, center=true, $fn=fn/2);
            translate([5, -5, 0]) cylinder(r=1.5, h=100, center=true, $fn=fn/2);
        }
    }
    hull() {
        translate([0, -3.5, 0]) cube([48, 40, 20], center=true);
        for (i = [-1, 1]) translate([17*i, 4, 0]) cylinder(r=11, h=20, center=true);
        translate([0, 4, 15])   rotate([-10, 0, 0])  scale([1, 1, 0.3]) sphere(r=10);
        translate([14, 4, 15])  rotate([-10, 10, 0]) scale([1, 1, 0.3]) sphere(r=10);
        translate([-14, 4, 15]) rotate([-10, -10, 0]) scale([1, 1, 0.3]) sphere(r=10);
        translate([0, -24, 19]) rotate([-10, 0, 0])  scale([1, 1, 0.3]) sphere(r=20);
    }
}

module hardwarecutouts() {
    for (i = [-1, 0, 1]) translate([18*i*xScaleFactor, (pow(i,2)*-12+3)*yScaleFactor, 0])
        cylinder(r=4/2, h=100, center=true, $fn=fn/2);
    for (i = [-3, -1, 1, 3]) translate([i*7*xScaleFactor, 0, 0])
        translate([0, 24.75*yScaleFactor, 6*zScaleFactor]) {
            rotate([0, 90, 0]) cylinder(d=jointDia, h=knuckleW*xScaleFactor + knucklePadding*yScaleFactor, center=true, $fn=fn/2);
            translate([0, 25, 0]) cube([knuckleW*xScaleFactor + knucklePadding*yScaleFactor, 50, jointThick], center=true);
        }
    translate([0, -27*yScaleFactor, 5.5*zScaleFactor]) rotate([0, 90, 0])
        cylinder(d=wrist_pin_dia, h=100, center=true, $fn=fn/2);   // wrist hinge pin (press-fit)
    translate([0, -10*yScaleFactor, (palmW/2-5)*zScaleFactor]) rotate([-4, 0, 0]) {
        for (i = [-3, -1, 1, 3]) translate([i*2*xScaleFactor, 0, (pow(i,2)*-0.05)*zScaleFactor])
            rotate([90, 0, i*-2]) cylinder(r=1, h=100, center=true, $fn=fn/4);
        translate([5*2*xScaleFactor, 0, (pow(5,2)*-0.05)*zScaleFactor])
            rotate([90, 0, 5*-2])
                union() translate([0, 0, 10*zScaleFactor]) {
                    cylinder(r=1, h=100, center=false, $fn=fn/4);
                    rotate([0, 120, -15]) cylinder(r=1, h=100, center=false, $fn=fn/4);
                    sphere(1.25);
                }
    }
    translate([40*xScaleFactor, -13*yScaleFactor, 5*zScaleFactor])
        rotate([-70, 20, 0]) translate([-4.75, -0.5*yScaleFactor, 0.7]) {
            cylinder(d=7, h=knuckleW*yScaleFactor + knucklePadding*yScaleFactor, center=true, $fn=fn/2);
            translate([25, 0, 0]) cube([50, jointThick, knuckleW*yScaleFactor + knucklePadding*yScaleFactor], center=true);
        }
    translate([33*xScaleFactor, -13*yScaleFactor, 5*zScaleFactor])
        rotate([90-72, -90, -30]) rotate([0, -20, 0]) rotate([10, 90, 0])
            translate([0, 0, -4.5*xScaleFactor])
                cylinder(r=1, h=100, center=false, $fn=fn/2);
    translate([33*xScaleFactor, -13*yScaleFactor, 5*zScaleFactor])
        rotate([90-72, -90, -30]) rotate([0, -20, 0]) rotate([10, 90, 0])
            translate([0, 0, 5*zScaleFactor])
                cylinder(r1=1, r2=20, h=100, center=false, $fn=fn/2);
}

module knuckleblock(width = 4.8) { }   // structural nub — solid block omitted in flexy variant

module cyborgbeast07palm() {
    translate([40, -13, 5]) rotate([-72, 0, 0]) cyborgthumbsolid();
    for (i = [-3, -1, 1, 3]) translate([i*7, 23.9, 4+4]) knuckleblock(width=knuckleW/2);
    hull() {
        translate([20.5, 10, 15.7]) rotate([-18, 10, 0])  scale([1, 1, 0.4]) sphere(10);
        translate([0, 11, 18.1])    rotate([-23, 0, 0])   scale([1, 1, 0.2]) sphere(10);
        translate([-20, 10, 14.5]) rotate([-18, -20, 0]) scale([1, 1, 0.4]) sphere(10);
        translate([0, 27, knuckleR]) rotate([0, 90, 0])
            cylinder(r=knuckleR, h=55, center=true, $fn=fn);
        translate([0, 2, 0]) scale([1, 0.8, 1]) cylinder(r=palmW/2-0.5, h=wristH/2, $fn=fn*2);
        difference() {
            translate([0, -1, wristH-1]) rotate([-10, -5, 0]) scale([1, 0.8, 0.3])
                sphere(r=palmW/2+1.25, $fn=fn*2);
            translate([0, 0, -1000/2]) cube(1000, center=true);
        }
        for (i = [-1, 1]) translate([26.6*i, -12, wristH/2]) cube([th, 10, wristH], center=true);
        translate([0, -18, 0]) {
            translate([0, 0, 17]) scale([1, 1, 0.4]) rotate([90, 0, 0])
                cylinder(r=palmW/2-6, h=th, center=true, $fn=fn);
            rotate([90, 0, 0]) intersection() {
                cylinder(r=palmW/2-4, h=th, center=true, $fn=fn);
                translate([0, palmW, 0]) cube(palmW*2, center=true);
            }
        }
        translate([0, -19, 26]) intersection() {
            rotate([-20, 0, 0]) scale([0.5, 0.3, 0.1]) sphere(r=palmW/2-6);
        }
    }
    for (i = [-1, 1]) translate([26.6*i, -12, wristH/2]) {
        cube([th, 30, wristH], center=true);
        translate([0, -30+wristH*1.5, 0]) rotate([0, 90, 0])
            cylinder(r=wristH/2, h=th, center=true, $fn=fn);
    }
}

// ── Finger modules ────────────────────────────────────────────────────────────

module fingerbase(length = 20, proximalHole = true, distalHole = true) {
    difference() {
        scale([yScaleFactor, xScaleFactor, zScaleFactor])
            fingerbasesolid(length);
        if (proximalHole)
            translate([0, knucklePadding/2 * xScaleFactor, 0])
                fingerhardwarecutouts(jointDia, jointThick, knuckleW = knuckleW-knucklePadding, fingerLen = length);
        if (distalHole)
            translate([length * yScaleFactor, 0, 0]) mirror([1, 0, 0])
                fingerhardwarecutouts(jointDia, jointThick, knuckleW = knuckleW, fingerLen = length);
    }
}

module fingerhardwarecutouts(jDia, jThick, knuckleW, fingerLen, holeCutoff = 100) {
    translate([7 - (15/jDia), 0, 6*zScaleFactor - (1.8/jThick)]) {
        rotate([90, 0, 0]) translate([-0.25, 0, -knuckleW*xScaleFactor])
            cylinder(d=jDia, h=knuckleW*xScaleFactor, $fn=50);
        translate([-25, (knuckleW*xScaleFactor)/2, 0])
            cube([50, knuckleW*xScaleFactor, jThick], center=true);
    }
    translate([-100, 0, 0]) cube([100, knuckleW*xScaleFactor, 100]);
    translate([-13/zScaleFactor, 0, 0]) rotate([0, 45, 0]) translate([-50, 0, 0])
        cube([100, knuckleW*xScaleFactor, 10]);
    translate([-fingerLen/2 * yScaleFactor, knuckleW/2 * xScaleFactor, 2.3])
        rotate([0, 90, 0]) cylinder(d=2.5, h=holeCutoff, $fn=50);
}

module fingerbasesolid(length = 50, cutout = true) {
    difference() {
        translate([0, 0.001 + knucklePadding/2, 1])
            cube([length, knuckleW - knucklePadding - 0.002, 8]);
    }
    intersection() {
        difference() {
            union() {
                translate([length-4, -5, 5]) rotate([-90, 0, 0]) cylinder(r=8, h=knuckleW+10);
                translate([0, -5, -5]) cube([length, knuckleW+10, 20]);
            }
            if (cutout) {
                translate([-4, -knuckleW+0.001, 5.3]) rotate([-90, 0, 0]) cylinder(r=11, h=10);
                translate([-4, knuckleW - knucklePadding*(1/xScaleFactor), 5.3]) rotate([-90, 0, 0]) cylinder(r=11, h=10);
            }
        }
        hull() {
            for (i = [-1, 1], j = [-1, 1]) {
                translate([length/10, i*2.4 + knuckleW/2, j*2.2 + 5]) rotate([i*j*-4, j*86, 0]) cylinder(d=6, h=20, center=true);
                translate([length+4,  i*2.4 + knuckleW/2, j*2.2 + 5]) rotate([i*j*-4, j*-86, 0]) cylinder(d=6, h=20, center=true);
            }
        }
    }
}

module fingermid(length = 19, proximalHole = true, distalHole = true) {
    difference() {
        scale([yScaleFactor, xScaleFactor, zScaleFactor])
            fingerbasesolid(length);
        if (proximalHole)
            translate([0, knucklePadding/2 * xScaleFactor, 0])
                fingerhardwarecutouts(jointDia, jointThick, knuckleW = knuckleW-knucklePadding, fingerLen = length);
        if (distalHole)
            translate([length * yScaleFactor, 0, 0]) mirror([1, 0, 0])
                fingerhardwarecutouts(jointDia, jointThick, knuckleW = knuckleW, fingerLen = length);
    }
}

module fingertip_curved_solid(length = 17, pad = true, hole = true) {
    render() difference() {
        union() {
            fingermid(length = length+3, proximalHole = true, distalHole = false);
            translate([length*yScaleFactor - 0.5, 0, 1.6*zScaleFactor])
                rotate([0, 30, 0]) fingertip(length = 15, proximalHole = false, cutout = false);
        }
        if (hole)
            translate([0, xScaleFactor * knuckleW/2, 2]) rotate([0, 90, 0])
                cylinder(d=2.5, h=100, $fn=50);
        if (pad)
            translate([length*yScaleFactor - 0.5, 0, 1.6*zScaleFactor])
                rotate([0, 30, 0]) fingertip_pad(length=15);
    }
    if (pad && show_pads)
        translate([length*yScaleFactor - 0.5, 0, 1.6*zScaleFactor])
            rotate([0, 30, 0]) fingerpad_solid(length=15);
}

module fingertip_solid(length = 15, pad = true) {
    if (!pad)
        fingertip(length=length);
    else
        render() difference() {
            fingertip(length=length);
            if (pad) fingertip_pad(length);
        }
}

module fingertip_pad(length) {
    difference() {
        fingertip(length, proximalHole=false, cutout=false);
        translate([0, -10, -10]) cube([length-7, 50, 50]);
        difference() {
            translate([0, 0.2*xScaleFactor, 3.2*zScaleFactor])
                cube([length+(3.3*yScaleFactor), xScaleFactor*(knuckleW - knucklePadding), 5.75*zScaleFactor]);
            translate([(length+(3.3*yScaleFactor))/3*2, 0.2*xScaleFactor, 3.2*zScaleFactor])
                cylinder(d=2.5*yScaleFactor, h=5.75*zScaleFactor);
            translate([(length+(3.3*yScaleFactor))/3*2, 0.2*xScaleFactor + (xScaleFactor*(knuckleW - knucklePadding)), 3.2*zScaleFactor])
                cylinder(d=2.5*yScaleFactor, h=5.75*zScaleFactor);
            translate([(length+(3.3*yScaleFactor))/3*2, 0.2*xScaleFactor, 3.2*zScaleFactor])
                rotate([-90, 0, 0]) cylinder(d=2*zScaleFactor, h=xScaleFactor*(knuckleW - knucklePadding));
            translate([(length+(3.3*yScaleFactor))/3*2, 0.2*xScaleFactor, 3.2*zScaleFactor + 5.75*zScaleFactor])
                rotate([-90, 0, 0]) cylinder(d=1.25*zScaleFactor, h=xScaleFactor*(knuckleW - knucklePadding));
        }
        translate([0, xScaleFactor * knuckleW/2, 0])
            rotate([0, 60, 0]) cylinder(d=8, h=100);
    }
}

// Silicone grip pad that fills the fingertip cavity — rendered only in preview.
// fingertip_pad() is the exact subtracted shape, so rendering it as a colored
// solid shows precisely what the silicone piece looks like in-situ.
module fingerpad_solid(length = 15) {
    color(pad_color)
    fingertip_pad(length);
}

module fingertip(length = 15, proximalHole = true, cutout = true) {
    intersection() {
        difference() {
            scale([yScaleFactor, xScaleFactor, zScaleFactor])
                fingerbasesolid(length, cutout);
            if (proximalHole) {
                translate([0, knucklePadding/2 * xScaleFactor, 0])
                    fingerhardwarecutouts(jointDia, jointThick, knuckleW = knuckleW-knucklePadding,
                        fingerLen = length, holeCutoff = (length-0.5)*2);
                translate([(length-5) * yScaleFactor, (knuckleW/2) * xScaleFactor, 0])
                    rotate([0, 30, 0]) translate([0, 0, 2]) cylinder(d=2.5, h=100, $fn=50);
            }
        }
        translate([(length-10)*xScaleFactor, 0, 21*zScaleFactor])
            rotate([-90, 0, 0]) cylinder(d=70, h=100, center=true);
    }
}

// ── Thumb ─────────────────────────────────────────────────────────────────────

module thumbtip() {
    fingertip_solid(length=18, pad=finger_pads);
    if (finger_pads && show_pads)
        fingerpad_solid(length=18);
}

// ── Thermoform mesh ───────────────────────────────────────────────────────────

module thermoform_mesh(size = [50, 50], thickness = 5, hole_spacing = 1.5) {
    hole_size = [1.75, 5.5];
    difference() {
        cube([size[0], size[1], thickness/2], center=false);
        translate([hole_size[0]/2 + hole_spacing, hole_size[1]/2 + hole_spacing, -thickness])
            for (x = [-1 : size[0] / (hole_size[0]+hole_spacing)],
                 y = [-1 : size[1] / (hole_size[1]+hole_spacing)]) {
                translate([x * (hole_size[0] + hole_spacing),
                           y * (hole_size[1] + hole_spacing) + (x % 2) * (hole_size[1]/2),
                           0])
                    resize([hole_size[0], hole_size[1], thickness*2]) cylinder(d=1, h=thickness, $fn=8);
            }
    }
}

// ── Flexy joints (living-hinge connectors) ────────────────────────────────────
// A parametric generalisation of the measured Finger_Hinge_Plate dogbone. The
// profile lies in XY (span along Y, web along X); linear_extrude along Z fills the
// joint slot along the pin axis. Placement modules below rotate Z onto each joint's
// physical pin axis. All dimensions come from h_* (derived from joint_dia/thick and
// scale), so the connector tracks the fingers during parameter manipulation.
module flexy_joint(span = h_span, lobe_r = h_lobe_r, web_t = h_web_t,
                   len = h_len, bore = h_bore) {
    linear_extrude(height = len, center = true)
        difference() {
            union() {
                translate([0, -span/2]) circle(r = lobe_r, $fn = fn*2);
                translate([0,  span/2]) circle(r = lobe_r, $fn = fn*2);
                square([web_t, span], center = true);
            }
            if (bore > 0) {
                translate([0, -span/2]) circle(d = bore, $fn = fn);
                translate([0,  span/2]) circle(d = bore, $fn = fn);
            }
        }
}

// Thumb flexy joints. Called inside the thumb group frame, so — like the fingers —
// the two connectors ride the thumb pose. thumbmid = rotate([0,0,-90]) fingerbase,
// so the same bore offsets used for the fingers land on the thumb MCP and tip pins.
module thumb_hinges() {
    _len = 20 * thumbProp * fingerLength;
    _bx = 7 - 15/jointDia;
    _by = knuckleW*xScaleFactor/2;
    _bz = 6*zScaleFactor - 1.8/jointThick;
    rotate([0, 0, -90]) {
        translate([_bx - h_span/2, _by, _bz]) rotate([90, 90, 0]) flexy_joint();
        translate([_len*yScaleFactor - _bx + h_span/2, _by, _bz]) rotate([90, 90, 0]) flexy_joint();
    }
}

// Print-bed plate: all ten connectors laid flat in a grid, like the original
// Finger_Hinge_Plate. One column per digit (index→pinky, thumb) × two joints
// (MCP, PIP). This is a single printable unit gated by show_hinges at the call
// site, so a per-part export of the hinges yields the whole set regardless of
// which finger toggles are on. Every connector is identical (hinge size depends
// on the joint hardware + scale, not on finger length), so it is a plain grid.
module hinge_plate(cols = 5, rows = 2) {
    _pitch  = h_lobe_r*2 + 2.5;              // Y pitch between stacked connectors
    _colgap = h_span + h_lobe_r*2 + 3;       // X pitch between digit columns
    for (c = [0:cols-1], r = [0:rows-1])
        translate([c * _colgap, r * _pitch, h_len/2])
            rotate([0, 0, 90]) flexy_joint();
}

// ── Gauntlet (forearm cuff) ───────────────────────────────────────────────────
// The gauntlet geometry now lives in the shared gauntlet.scad (included above) —
// the same reconstructed part used by the Cyborg Beast. gauntlet_part() and the
// print-layout branch size and seat it; there is no primitive cuff inlined here.
