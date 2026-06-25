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

// Silicone pad color
pad_color = "#e8c8a0";

// Show thermoformable mesh on palm interior (for heat-forming to patient)
show_thermoform = true;

// Mirror geometry for right hand (default produces left hand)
mirrored = false;

// Print-bed layout: spread every part flat side-by-side for 3D printing instead
// of the assembled hand pose. Set true by the STL exporter; the preview keeps the
// assembled view (false). Each part is emitted in its native print orientation;
// the exporter seats each on the bed (Z=0) when writing the STL.
print_layout = false;

/* [Gauntlet] */

// Show the forearm gauntlet — a separate printed part (wrist-powered tensioner
// cuff) that pins to the palm's wrist hinge axis. Modelled from primitive shapes
// (a tapered oval half-pipe tunnel) so it runs in OpenSCAD-WASM.
show_gauntlet = true;

// Forearm socket width — no direct anthropometric import; derive as
// wrist_circumference_mm / PI + ~6 mm clearance (mm)
gauntlet_width_mm = 60; // [40:1:90]

// Gauntlet length along the forearm (mm)
gauntlet_length_mm = 108; // [70:1:150]

// Cuff wall thickness (mm)
gauntlet_wall_mm = 3; // [2:0.5:5]

// Slide the gauntlet along the forearm axis to fine-tune the wrist-pin fit (mm)
gauntlet_pos_adjust = 0; // [-25:1:25]

/* [Wrist Hinge] */

// Wrist hinge pin diameter — sizes the pivot holes for a pin/bolt you supply
// (defaults to the finger joint pin size) (mm)
wrist_pin_dia = 7; // [3:0.5:8]

// Clearance around the pin so the gauntlet straps rotate freely (mm)
wrist_pin_clearance = 0.35; // [0.1:0.05:0.8]

// Nudge the strap-tip splay so the flaps sit just inside the palm wrist fins (mm)
strap_splay_adjust = 0; // [-8:0.5:8]

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

// ── Gauntlet placement (derived) ──────────────────────────────────────────────
// The gauntlet is authored in native mm (outer width ~50, length ~108) with its
// own frame: +Y = wrist/proximal, -Y = hand/distal (straps), +Z = dorsal.
// We rotate it 180° about Z so the straps face the hand (+Y of the palm), scale
// it to the patient's forearm, and translate it so the strap-tip pivot holes
// land on the palm's wrist hinge pin axis.
G_REF_WIDTH  = 50;    // native gauntlet outer width (mm)
G_REF_LENGTH = 108;   // native gauntlet length (mm)
g_sx = gauntlet_width_mm  / G_REF_WIDTH;    // width / cross-section scale
g_sy = gauntlet_length_mm / G_REF_LENGTH;   // forearm-axis length scale
g_fn = 48;

// Palm wrist hinge pin axis (matches hardwarecutouts: Y=-27, Z=5.5 unscaled)
g_pivot_y = -27 * yScaleFactor;
g_pivot_z = 5.5 * zScaleFactor;

// Native strap-tip hole sits at (X±22, Y-53, Z-10); after the 180° Z-rotation the
// Y flips to +53. Solve the translation so that hole lands on the pin axis.
g_pos_y = g_pivot_y - 53 * g_sy + gauntlet_pos_adjust;
g_pos_z = g_pivot_z + 10 * g_sx;

// ── Wrist hinge (derived) ─────────────────────────────────────────────────────
// Palm wrist fins (cyborgbeast07palm): centre X=26.6, thickness th, both scaled.
g_fin_cx    = 26.6 * xScaleFactor;            // fin centre X (scaled)
g_fin_th    = th   * xScaleFactor;            // fin thickness in X (scaled)
g_fin_inner = g_fin_cx - g_fin_th/2;          // fin inner face X (scaled)
g_pin_span  = 2*g_fin_cx + g_fin_th;          // fin-outer to fin-outer (scaled)

// Native strap-tip half-thickness ~1.85 mm; place each strap flap just inside its
// fin (face-to-face with clearance). g_strap_splay is the native X the tip moves out.
g_strap_halfw      = 1.85 * g_sx;
g_strap_tip_target = g_fin_inner - wrist_pin_clearance - g_strap_halfw + strap_splay_adjust;
g_strap_splay      = g_strap_tip_target / g_sx - 22.95;   // native (current tip centre ≈22.95)

// ── Top-level assembly ────────────────────────────────────────────────────────

mirror([mirrored ? 1 : 0, 0, 0])
    if (print_layout) printlayout();
    else handlayout();

// ── Assembly ──────────────────────────────────────────────────────────────────

module handlayout(sp = 14) {
    if (show_palm) cyborgbeastpalm();
    translate([20.5*xScaleFactor, 33*yScaleFactor, 7*zScaleFactor])
        rotate([0, 180, 0]) {
        if (show_index)  translate([0*xScaleFactor,    7.5*yScaleFactor, 0]) fingerlayout(indexProp  * fingerLength, base = show_index_base,  tip = show_index_tip);
        if (show_middle) translate([sp*xScaleFactor,   7.5*yScaleFactor, 0]) fingerlayout(middleProp * fingerLength, base = show_middle_base, tip = show_middle_tip);
        if (show_ring)   translate([sp*2*xScaleFactor, 7.5*yScaleFactor, 0]) fingerlayout(ringProp   * fingerLength, base = show_ring_base,   tip = show_ring_tip);
        if (show_pinky)  translate([sp*3*xScaleFactor, 7.5*yScaleFactor, 0]) fingerlayout(pinkyProp  * fingerLength, base = show_pinky_base,  tip = show_pinky_tip);
    }
    if (show_thumb)
    translate([36*xScaleFactor, -15.5*yScaleFactor, 0.5*zScaleFactor])
        rotate([50, -20, 90]) {
        if (show_thumb_base) thumbmid();
        if (show_thumb_tip) translate([0, -22*yScaleFactor, 0*zScaleFactor]) rotate([0, 0, -90]) thumbtip();
    }
    if (show_gauntlet) gauntlet_part();
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
    if (show_palm) cyborgbeastpalm();

    // Four fingers stacked index→pinky; each piece gated like handlayout.
    _fingers = [
        [show_index,  show_index_base,  show_index_tip,  indexProp],
        [show_middle, show_middle_base, show_middle_tip, middleProp],
        [show_ring,   show_ring_base,   show_ring_tip,   ringProp],
        [show_pinky,  show_pinky_base,  show_pinky_tip,  pinkyProp],
    ];
    for (i = [0:len(_fingers)-1]) let(f = _fingers[i], _y = (1.5 - i) * _row)
        if (f[0]) {
            if (f[1]) translate([_base_x, _y, 0]) fingerbase(length = 20 * f[3] * fingerLength);
            if (f[2]) translate([_tip_x,  _y, 0]) fingertip_curved_solid(length = 17 * f[3] * fingerLength, pad = finger_pads);
        }

    // Thumb base + tip on a row below the fingers.
    if (show_thumb) let(_yt = -2.7 * _row) {
        if (show_thumb_base) translate([_base_x, _yt, 0]) fingerbase(length = 20 * thumbProp * fingerLength);
        if (show_thumb_tip)  translate([_tip_x,  _yt, 0]) thumbtip();
    }

    // Gauntlet (forearm cuff) below the palm, in its native cuff orientation.
    if (show_gauntlet)
        translate([0, -72 * yScaleFactor, 0]) scale([g_sx, g_sy, g_sx]) gauntlet();
}

// ── Gauntlet (forearm cuff) ───────────────────────────────────────────────────

// Placed + scaled forearm gauntlet. Straps face the hand and pin onto the palm
// wrist hinge axis; the cuff extends down the forearm (toward -Y).
module gauntlet_part() {
    difference() {
        translate([0, g_pos_y, g_pos_z])
            rotate([0, 0, 180])
            scale([g_sx, g_sy, g_sx])
            gauntlet();
        // round wrist-pin clearance hole through the strap flaps (assembly space)
        translate([0, g_pivot_y, g_pivot_z]) rotate([0, 90, 0])
            cylinder(d=wrist_pin_dia + 2*wrist_pin_clearance, h=g_pin_span + 10, center=true, $fn=28);
    }
}

// lengthMult: positional arg — fixes the original Flexy Beast parameter-name mismatch.
// base/tip select which of the finger's two printable pieces to emit.
module fingerlayout(lengthMult = 1, base = true, tip = true) {
    if (tip)
    rotate([180, -10, 90])
        translate([15*lengthMult, -8, -10])
            fingertip_curved_solid(length = 17*lengthMult, pad = finger_pads);
    if (base)
    rotate([180, -5, 90])
        translate([-20, -8, -12])
            fingerbase(length = 20*lengthMult);
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

// ── Gauntlet modules (primitive forearm cuff) ─────────────────────────────────
// Authored in native mm; gauntlet_part() scales/places the whole thing. Pure
// core primitives (no BOSL2). All identifiers are g_-prefixed to stay isolated
// from the hand. $fn is set inside gauntlet() so it does not affect the hand.

g_eps  = 0.01;
// Native wall thickness: divide by the width scale so the printed wall ends up
// at gauntlet_wall_mm after gauntlet_part() applies g_sx.
g_wall = gauntlet_wall_mm / g_sx;

g_open_half_x = 17.0;   // half-width of the palmar opening
g_open_top_z  = 3.0;    // how high the central opening reaches

// Cuff cross-section stations: [y, rx, rz, cz] (outer oval)
g_cuff_discs = [
    [-30, 20.8, 16.0, -1.0],   // distal (toward hand)
    [-10, 22.8, 17.0, -0.5],
    [ 10, 24.0, 17.5,  0.0],
    [ 30, 25.0, 18.5,  0.5],   // proximal body (fullest wrap)
    [ 44, 25.0, 17.0, -1.0],   // wrist rim
    [ 50, 23.5, 13.5, -2.5],   // rim mouth
];

// Right strap stations: [y, xmin, xmax, zmin, zmax]; left = mirror
g_strap_stations = [
    [-58.00,21.68,24.19,-13.29,-6.49], [-56.00,21.33,24.61,-14.79,-4.81],
    [-54.00,21.12,24.81,-15.50,-3.89], [-52.00,20.97,24.89,-15.83,-3.27],
    [-50.00,20.81,24.93,-16.05,-2.72], [-48.00,20.64,24.91,-16.15,-2.22],
    [-46.00,20.45,24.82,-16.16,-1.75], [-44.00,20.22,24.65,-16.11,-1.25],
    [-42.00,19.94,24.38,-16.03,-0.69], [-40.00,19.61,24.01,-15.95,-0.05],
    [-38.00,19.21,23.52,-15.86,0.72],  [-36.00,18.70,22.95,-15.79,1.68],
    [-34.00,18.06,22.32,-15.77,2.86],  [-32.00,17.27,21.77,-15.81,4.32],
    [-30.00,12.90,21.39,-15.90,8.82],
];
g_strap_corner_r = 1.6;   // strap cross-section corner rounding (pin hole drilled in assembly space)

g_boss_cx=0.3; g_boss_cy=28.5; g_boss_width=29.5; g_boss_length=20.0;
g_boss_top_z=23.4; g_boss_base_z=13.5; g_boss_round=4.0;

g_crenel_x=[-11.4,-5.0,0.6,6.8,12.4];
g_crenel_z_base=15.5; g_crenel_z_apex=21.0; g_crenel_w=4.6;
g_crenel_y0=14.0; g_crenel_y1=22.5;

g_hole_x=12.6; g_hole_y=8.5; g_hole_z=12.0; g_hole_d=3.5;

module gauntlet() {
    $fn = g_fn;
    difference() {
        union() {
            g_cuff_halfpipe();
            g_straps();
            g_boss();
        }
        g_crenellations();
        g_holes();
    }
}

// Cuff: tapered oval half-pipe tunnel
module g_oval_disc(d, dr=0) {   // d=[y,rx,rz,cz]; dr shrinks radii for the bore
    translate([0, d[0], d[3]]) rotate([90,0,0])
        linear_extrude(0.5, center=true) scale([d[1]+dr, d[2]+dr]) circle(r=1);
}
module g_oval_tube(dr=0) {
    for (i = [0:len(g_cuff_discs)-2])
        hull() { g_oval_disc(g_cuff_discs[i], dr); g_oval_disc(g_cuff_discs[i+1], dr); }
}
module g_cuff_halfpipe() {
    difference() {
        g_oval_tube(0);
        g_oval_tube(-g_wall);
        translate([0, 0, g_open_top_z - 100]) cube([2*g_open_half_x, 400, 200], center=true);
    }
}

// Distal straps/tongues. The pivot end splays outward (g_splay) so each flap sits
// just inside its palm wrist fin. The pin hole is drilled round in assembly space
// by gauntlet_part() (stays circular despite the cuff's non-uniform scaling).
function g_strap_rows() = [ for (s = g_strap_stations) if (s[0] <= -30 + g_eps) s ];
function g_splay(y) = g_strap_splay * max(0, min(1, (-30 - y) / 28));   // 0 at cuff, full at tip
module g_slab(s) {
    w=(s[2]-s[1]); h=(s[4]-s[3]); cx=(s[1]+s[2])/2 + g_splay(s[0]); cz=(s[3]+s[4])/2;
    r=min(g_strap_corner_r, w/2-0.01, h/2-0.01);
    translate([cx, s[0], cz]) rotate([90,0,0]) linear_extrude(0.6, center=true)
        offset(r=r) offset(r=-r) square([w, h], center=true);
}
module g_one_strap(mir) {
    rows = g_strap_rows();
    scale([mir,1,1])
        for (i = [0:len(rows)-2]) hull() { g_slab(rows[i]); g_slab(rows[i+1]); }
}
module g_straps() { g_one_strap(1); g_one_strap(-1); }

// Tensioner boss (rounded pad via minkowski)
module g_boss() {
    h = g_boss_top_z - g_boss_base_z; r = g_boss_round;
    translate([g_boss_cx, g_boss_cy, (g_boss_base_z+g_boss_top_z)/2])
        minkowski() {
            cube([g_boss_width-2*r, g_boss_length-2*r, max(h-2*r,0.1)], center=true);
            sphere(r=r, $fn=20);
        }
}

// Triangular crenellation slots
module g_crenellations() {
    for (xc = g_crenel_x)
        translate([xc, g_crenel_y1, 0]) rotate([90,0,0])
            linear_extrude(g_crenel_y1-g_crenel_y0)
            polygon([[-g_crenel_w/2, g_crenel_z_base],
                     [ g_crenel_w/2, g_crenel_z_base],
                     [ 0,            g_crenel_z_apex]]);
}

// Dorsal round holes (radial)
module g_holes() {
    ang = atan2(g_hole_z, g_hole_x);
    for (sx = [1,-1]) scale([sx,1,1])
        translate([g_hole_x, g_hole_y, g_hole_z])
            rotate([0, 90-ang, 0]) cylinder(h=40, d=g_hole_d, center=true);
}
