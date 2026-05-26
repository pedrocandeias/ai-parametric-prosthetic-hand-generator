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
show_thermoform = false;

// Mirror geometry for right hand (default produces left hand)
mirrored = false;

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

// ── Top-level assembly ────────────────────────────────────────────────────────

mirror([mirrored ? 1 : 0, 0, 0])
    handlayout();

// ── Assembly ──────────────────────────────────────────────────────────────────

module handlayout(sp = 14) {
    cyborgbeastpalm();
    translate([20.5*xScaleFactor, 33*yScaleFactor, 7*zScaleFactor])
        rotate([0, 180, 0]) {
        translate([0*xScaleFactor,    7.5*yScaleFactor, 0]) fingerlayout(indexProp  * fingerLength);
        translate([sp*xScaleFactor,   7.5*yScaleFactor, 0]) fingerlayout(middleProp * fingerLength);
        translate([sp*2*xScaleFactor, 7.5*yScaleFactor, 0]) fingerlayout(ringProp   * fingerLength);
        translate([sp*3*xScaleFactor, 7.5*yScaleFactor, 0]) fingerlayout(pinkyProp  * fingerLength);
    }
    translate([36*xScaleFactor, -15.5*yScaleFactor, 0.5*zScaleFactor])
        rotate([50, -20, 90]) {
        thumbmid();
        translate([0, -22*yScaleFactor, 0*zScaleFactor]) rotate([0, 0, -90]) thumbtip();
    }
}

// lengthMult: positional arg — fixes the original Flexy Beast parameter-name mismatch
module fingerlayout(lengthMult = 1) {
    rotate([180, -10, 90])
        translate([15*lengthMult, -8, -10])
            fingertip_curved_solid(length = 17*lengthMult, pad = finger_pads);
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
        cylinder(r=4/2, h=100, center=true, $fn=fn/2);
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
