// ============================================================
// anthropometric_cyborgbeast.scad
// ============================================================
// Cyborg Beast prosthetic hand geometry, fully reparametrized
// to accept anthropometric measurement inputs.
//
// Based on Cyborg Beast 07 by Jorge Zuniga / e-NABLE.
// Original CB geometry preserved; all magic constants mapped
// to proportional expressions via a master scale factor
// q = palm_width / 64 (the CB reference palm width).
//
// Hardware hole diameters (pins, tendons, elastic) are kept at
// physical size — they do NOT scale with hand size.
// ============================================================

/* [Orientation] */
right_hand = true;

/* [Scale] */
global_scale = 1.0; // [0.5:0.01:2.0]

/* [Palm — mm] */
palm_width_mm          = 85;
palm_length_mm         = 100;
palm_thickness_mm      = 26;
palm_wall_thickness_mm = 2.5;
palm_structural_thickness = 9.1;

/* [Finger Total Lengths — mm] */
finger_length_index  = 68;
finger_length_middle = 73;
finger_length_ring   = 68;
finger_length_pinky  = 55;
finger_length_thumb  = 58;

/* [Index Phalanx Reference — mm] */
proximal_phalanx_length = 30.6;
middle_phalanx_length   = 21.1;
distal_phalanx_length   = 16.3;

/* [Finger Geometry] */
finger_base_width  = 17;
joint_spacing_mm   = 1.5;

/* [Tendon Routing] */
internal_channel_diameter = 2.0;

/* [Hardware] */
pivot_diameter_mm = 3.0;
clearance_mm      = 0.4;

/* [Wrist Socket] */
socket_diameter_proximal_mm    = 63.7;
socket_diameter_distal_mm      = 54.1;
socket_inner_diameter_mm       = 58.9;
socket_depth_mm                = 60;
socket_taper_angle_deg         = 4.5;
socket_rim_thickness_mm        = 4.5;
socket_distal_cap_thickness_mm = 3;

/* [View] */
show_assembled = true;
$fn = 32;

// ─────────────────────────────────────────────────────────────
// DERIVED — CB-compatible scaling
// ─────────────────────────────────────────────────────────────
S  = global_scale;
PW = palm_width_mm * S;
PL = palm_length_mm * S;
fn = $fn;

// Master CB scale: original reference palmW = 64
q = PW / 64;

// CB global variables, scaled proportionally
knuckleR = max(4.85 * q, pivot_diameter_mm * 1.6);
wristH   = 10 * q;
palmH    = 20 * q;
th       = max(palm_wall_thickness_mm, 3 * q);
sp       = 14.4 * q;
palmW    = PW;

// Hardware — physical dimensions, NOT scaled with hand size
PD = pivot_diameter_mm;
CL = clearance_mm;
CH = internal_channel_diameter;
pin_r     = (PD + CL) / 2;
tendon_r  = CH / 2;
elastic_r = CH * 0.55;

// Per-finger CB "len" parameter
// At finger_s = q:  total ≈ q × (42.5 + len × 4/3)
// Solving:  len = (finger_total × 64 / palm_width − 42.5) × 3/4
function cb_len(ftotal) =
    (ftotal * 64 / palm_width_mm - 42.5) * 3 / 4;

len_index  = cb_len(finger_length_index);
len_middle = cb_len(finger_length_middle);
len_ring   = cb_len(finger_length_ring);
len_pinky  = cb_len(finger_length_pinky);

// Thumb: anatomical 54 / 46 split
// fingermid segment = 23 + 2·len/3; fingertip ≈ 19.5 + 2·len/3
thumb_ref      = finger_length_thumb * 64 / palm_width_mm;
thumb_mid_tgt  = thumb_ref * 0.54;
thumb_tip_tgt  = thumb_ref * 0.46;
len_thumb_mid  = (thumb_mid_tgt - 23) * 3 / 2;
len_thumb_tip  = (thumb_tip_tgt - 19.5) * 3 / 2;

// ─────────────────────────────────────────────────────────────
// KNUCKLE BLOCK
// Fork that receives the finger tab at each finger root.
// From cyborgpalm001.scad — positions scaled by q.
// ─────────────────────────────────────────────────────────────
module knuckleblock() {
    difference() {
        hull()
            for (j=[-1,1]) for (i=[-1,1])
                translate([2.6*q*i, 0, 2.5*q*j])
                    rotate([90,0,0])
                    cylinder(r=1.5*q, h=10*q, center=true, $fn=fn/2);
        cube([5*q, 11*q, 5.5*q], center=true);
    }
}

// ─────────────────────────────────────────────────────────────
// THUMB BOSS
// Organic solid for thumb mount on radial side of palm.
// From cyborgpalm001.scad cyborgthumbsolid() — scaled by q.
// ─────────────────────────────────────────────────────────────
module cyborgthumbsolid() {
    translate([-1.5*q, -2.4*q, 0])
        rotate([91, 90, 20]) knuckleblock();
    hull() {
        translate([-20*q, 0, 5*q])
            rotate([0,30,0]) scale([1,1,0.5])
            sphere(r=9*q);
        hull() {
            cylinder(r=4.5*q, h=10*q, center=true, $fn=fn*2);
            translate([-10*q, -1*q, 0])
                cylinder(r=4.5*q, h=10*q, center=true, $fn=fn*2);
            rotate([-10,0,0])
                translate([-10*q, -6*q, 0])
                cylinder(r=4.5*q, h=9*q, center=true, $fn=fn*2);
        }
        hull() {
            rotate([-20,0,0])
                translate([-10*q, -8*q, -3*q])
                cylinder(r=5*q, h=7*q, center=true, $fn=fn*2);
            rotate([-10,0,0])
                translate([-10*q, -6*q, -1*q])
                cylinder(r=4.5*q, h=9*q, center=true, $fn=fn*2);
            rotate([-20,0,0])
                translate([-16*q, -10*q, -1*q])
                cylinder(r=4.5*q, h=9*q, center=true, $fn=fn*2);
        }
    }
}

// ─────────────────────────────────────────────────────────────
// PALM INTERIOR CAVITY
// From cyborgpalm001.scad cyborgbeast07palminsidespace() — q.
// ─────────────────────────────────────────────────────────────
module cyborgbeast07palminsidespace() {
    // Cosmetic through-cuts (teardrop pairs, mirrored)
    for (m=[0,1]) mirror([m,0,0]) {
        hull() {
            translate([13*q, 13*q, 0])
                cylinder(r=3*q, h=100, center=true, $fn=fn/2);
            translate([10*q, 5*q, 0])
                cylinder(r=2*q, h=100, center=true, $fn=fn/2);
        }
        hull() {
            translate([10*q, 5*q, 0])
                cylinder(r=2*q, h=100, center=true, $fn=fn/2);
            translate([5*q, -5*q, 0])
                cylinder(r=1.5*q, h=100, center=true, $fn=fn/2);
        }
    }
    // Interior cavity
    hull() {
        translate([0, -3.5*q, 0])
            cube([48*q, 40*q, 20*q], center=true);
        for (i=[-1,1])
            translate([17*q*i, 4*q, 0])
            cylinder(r=11*q, h=20*q, center=true);
        translate([0, 4*q, 15*q])
            rotate([-10,0,0]) scale([1,1,0.3])
            sphere(r=10*q);
        translate([14*q, 4*q, 15*q])
            rotate([-10,10,0]) scale([1,1,0.3])
            sphere(r=10*q);
        translate([-14*q, 4*q, 15*q])
            rotate([-10,-10,0]) scale([1,1,0.3])
            sphere(r=10*q);
        translate([0, -24*q, 19*q])
            rotate([-10,0,0]) scale([1,1,0.3])
            sphere(r=20*q);
    }
}

// ─────────────────────────────────────────────────────────────
// HARDWARE CUTOUTS
// Positions proportional to q; hole diameters at physical size.
// From cyborgpalm001.scad hardwarecutouts().
// ─────────────────────────────────────────────────────────────
module hardwarecutouts() {
    // Velcro strap holes (3)
    for (i=[-1,0,1])
        translate([18*q*i, pow(i,2)*-12*q + 3*q, 0])
        cylinder(r=pin_r, h=100, center=true, $fn=fn/2);

    // Knuckle bar hinge pin
    translate([0, 27*q, 5*q])
        rotate([0,90,0])
        cylinder(r=pin_r, h=100, center=true, $fn=fn/2);

    // Wrist hinge pin
    translate([0, -27*q, 5.5*q])
        rotate([0,90,0])
        cylinder(r=pin_r, h=100, center=true, $fn=fn/2);

    // Elastic cord tie-off holes at knuckles
    for (i=[-1,1])
        translate([14.6*q*i, 22*q, 0])
        for (j=[-1,1])
            translate([2*q*j, 0, 0])
            cylinder(r=elastic_r, h=100, center=true, $fn=fn/4);

    // Tendon routing channels at wrist
    translate([0, -10*q, palmW/2 - 5*q])
        rotate([-4,0,0]) {
            for (i=[-3,-1,1,3])
                translate([i*2*q, 0, pow(i,2)*-0.05*q])
                rotate([90, 0, i*-2])
                cylinder(r=tendon_r, h=100, center=true, $fn=fn/4);
            // Thumb tendon fan-out
            translate([10*q, 0, pow(5,2)*-0.05*q])
                rotate([90, 0, -10])
                translate([0, 0, 10*q]) {
                    cylinder(r=tendon_r, h=100, center=false, $fn=fn/4);
                    rotate([0, 120, -15])
                        cylinder(r=tendon_r, h=100, center=false, $fn=fn/4);
                    sphere(elastic_r);
                }
        }

    // Thumb knuckle pin
    translate([40*q, -13*q, 5*q])
        rotate([-72,0,0])
        cylinder(r=pin_r, h=40*q, center=true, $fn=fn/2);

    // Thumb elastic return
    translate([31*q, -13*q, 16*q])
        rotate([-72,0,0])
        cylinder(r=elastic_r, h=40*q, center=true, $fn=fn/2);

    // Thumb tendon channel
    translate([33*q, -13*q, 5*q])
        rotate([18, -90, -30])
        rotate([0, -20, 0])
        rotate([10, 90, 0])
        translate([0, 0, -10*q])
        cylinder(r=tendon_r, h=100, center=false, $fn=fn/2);

    // Thumb tendon flare
    translate([33*q, -13*q, 5*q])
        rotate([18, -90, -30])
        rotate([0, -20, 0])
        rotate([10, 90, 0])
        translate([0, 0, 5*q])
        cylinder(r1=tendon_r, r2=20*q, h=100, center=false, $fn=fn/2);

    // Finger connector slots + tendon guides through palm
    for (i=[-3,-1,1,3])
        translate([i*7.3*q, 28*q, 0]) {
            cube([5*q, 15*q, 21.6*q], center=true);
            translate([0, -4.5*q, 0])
                rotate([30, 0, i*-6])
                cylinder(r=elastic_r, h=100, center=false, $fn=fn/2);
            render() difference() {
                hull() translate([0, -4.5*q, 0]) {
                    rotate([30, 0, i*-6])
                        cylinder(r=elastic_r, h=100, center=false, $fn=fn/2);
                    cylinder(r=elastic_r, h=100, center=false, $fn=fn/2);
                }
                translate([0, 0, -50 + 10*q])
                    cube(100, center=true);
            }
        }

    // Thumb connector slot
    translate([40*q, -13*q, 5*q])
        rotate([-72,0,0])
        translate([4*q, 4.1*q, 0])
        cube([21.6*q, 15*q, 5*q], center=true);
}

// ─────────────────────────────────────────────────────────────
// PALM SOLID
// Organic hull of spheres, cylinders, flattened shapes.
// From cyborgpalm001.scad cyborgbeast07palm() — q-scaled.
// Variables palmW, knuckleR, wristH, th are already scaled.
// ─────────────────────────────────────────────────────────────
module cyborgbeast07palm() {
    // Thumb boss
    translate([40*q, -13*q, 5*q])
        rotate([-72,0,0])
        cyborgthumbsolid();

    // Knuckle blocks (4 fingers)
    for (i=[-3,-1,1,3])
        translate([i*7.3*q, 23.9*q, 8*q])
        knuckleblock();

    // Main palm hull
    hull() {
        // Dorsal bumps near knuckles
        translate([20.5*q, 10*q, 15.7*q])
            rotate([-18, 10, 0]) scale([1,1,0.4])
            sphere(10*q);
        translate([0, 11*q, 18.1*q])
            rotate([-23, 0, 0]) scale([1,1,0.2])
            sphere(10*q);
        translate([-20*q, 10*q, 14.5*q])
            rotate([-18, -20, 0]) scale([1,1,0.4])
            sphere(10*q);

        // Knuckle bar cylinder
        translate([0, 27*q, knuckleR])
            rotate([0,90,0])
            cylinder(r=knuckleR, h=55*q, center=true, $fn=fn);

        // Palm base disc
        translate([0, 2*q, 0])
            scale([1, 0.8, 1])
            cylinder(r=palmW/2 - 0.5, h=wristH/2, $fn=fn*2);

        // Dorsal surface hump
        difference() {
            translate([0, -1*q, wristH - 1*q])
                rotate([-10, -5, 0]) scale([1, 0.8, 0.3])
                sphere(r=palmW/2 + 1.25*q, $fn=fn*2);
            translate([0, 0, -500]) cube(1000, center=true);
        }

        // Wrist bar stubs
        for (i=[-1,1])
            translate([26.6*q*i, -12*q, wristH/2])
            cube([th, 10*q, wristH], center=true);

        // Back of wrist
        translate([0, -18*q, 0]) {
            translate([0, 0, 17*q])
                scale([1, 1, 0.4]) rotate([90,0,0])
                cylinder(r=palmW/2 - 6*q, h=th, center=true, $fn=fn);
            rotate([90,0,0])
                intersection() {
                    cylinder(r=palmW/2 - 4*q, h=th, center=true, $fn=fn);
                    translate([0, palmW, 0])
                        cube(palmW*2, center=true);
                }
        }

        // Dorsal wrist tendon outlet bump
        translate([0, -19*q, 26*q])
            rotate([-20, 0, 0]) scale([0.5, 0.3, 0.1])
            sphere(r=palmW/2 - 6*q);
    }

    // Wrist hinge arms (outside hull, not enveloped)
    for (i=[-1,1])
        translate([26.6*q*i, -12*q, wristH/2]) {
            cube([th, 30*q, wristH], center=true);
            translate([0, -30*q + wristH*1.5, 0])
                rotate([0,90,0])
                cylinder(r=wristH/2, h=th, center=true, $fn=fn);
        }
}

// ─────────────────────────────────────────────────────────────
// PALM ASSEMBLY (solid − cavity − hardware − flat bottom)
// From cyborgpalm001.scad cyborgbeastpalm().
// ─────────────────────────────────────────────────────────────
module cyborgbeastpalm() {
    difference() {
        difference() {
            cyborgbeast07palm();
            cyborgbeast07palminsidespace();
            translate([0, 0, -50]) cube(100, center=true);
        }
        hardwarecutouts();
    }
}

// ─────────────────────────────────────────────────────────────
// FINGER MID SEGMENT (proximal phalanx)
// From cyborgfingermid002.scad — internal geometry at CB
// reference scale, then uniformly scaled by s in the wrapper.
// Hardware holes at physical (PD, CL, CH) dimensions.
// ─────────────────────────────────────────────────────────────
module fingermidsolid(len=0, rad=5) {
    difference() {
        union() {
            hull() {
                translate([0, (13+rad*2+len/3*2)/-2, 7.5])
                    rotate([0,-90,0])
                    intersection() {
                        cylinder(r=5, h=4.6, center=true, $fn=fn);
                        translate([0, 0, -50]) cube(100, center=false);
                    }
                translate([0, 0, 1])
                    cube([4.4, (11.5+len/3)*2, 2], center=true);
            }
            hull() {
                for (i=[-1,1])
                    translate([0, (-11.5-len/3)*i, 5])
                    rotate([0,90,0])
                    cylinder(r=4.9, h=4.4, center=true, $fn=fn);
                translate([0, 0, 1])
                    cube([4.4, (11.5+len/3)*2, 2], center=true);
            }
            hull()
                translate([0, 0, 5.5])
                intersection() {
                    scale([1, 2, 1]) rotate([90,0,0])
                        cylinder(r2=5.75, r1=6.75,
                                 h=11.5+rad+len/3, center=true, $fn=fn*2);
                    cube([11, (11.5+len/3)*2, 11], center=true);
                }
        }
        // Side scallops — carve corners to reveal narrow tab
        for (j=[0:1]) mirror([0,j,0])
            for (i=[0:1]) mirror([i,0,0])
            hull() {
                translate([2.2, -(11.5+len/3), 5]) {
                    rotate([-150, 0, 0])
                        translate([0, 0, -10])
                        rotate([0,90,0])
                        cylinder(r=5.4, h=10, center=false, $fn=fn);
                    translate([0, 0, -10])
                        rotate([0,90,0])
                        cylinder(r=5.4, h=10, center=false, $fn=fn);
                    rotate([0,90,0])
                        cylinder(r=5.4, h=10, center=false, $fn=fn);
                }
            }
    }
}

module fingermid(s=1, len=0, rad=5) {
    difference() {
        scale([s, s, s]) fingermidsolid(len=len, rad=rad);
        // Pin holes — physical size
        for (i=[-1,1])
            translate([0, (-11.5-len/3)*s*i, 5*s])
            rotate([0,90,0])
            cylinder(r=pin_r, h=20, center=true, $fn=fn/2);
        // Elastic + tendon channels — physical size
        for (i=[-1,1])
            translate([0, 0, 5*s + 3.25*s*i])
            rotate([90,0,0])
            cylinder(r=tendon_r, h=40+len, $fn=fn/2, center=true);
        // Tendon constriction bends
        for (i=[0,1]) mirror([0,i,0])
            hull() for (j=[0,1])
                translate([0, (-6-len/3)*s, (1.75-3.25*j)*s])
                rotate([90,0,0])
                cylinder(r=tendon_r, h=20+len, $fn=fn/2, center=false);
    }
}

// ─────────────────────────────────────────────────────────────
// GRIP TEXTURE
// From cyborgfingertip002.scad fingerpoint() / fingerpoints().
// ─────────────────────────────────────────────────────────────
module fingerpoint(rad=5) {
    translate([0, 0, rad+3.33])
        rotate([45, 35, 90])
        cube(1.5, center=true);
}

module fingerpoints(rows=3, rad=5) {
    for (j=[0,1]) mirror([0,j,0])
        scale([0.78, 1, 1.1])
        for (i=[-rows:rows])
            rotate([0, i*15, 0])
            rotate([0, 0, round(i%2)*180])
            fingerpoint(rad);
}

// ─────────────────────────────────────────────────────────────
// FINGERTIP (distal phalanx — dome + grip texture)
// From cyborgfingertip002.scad — reference scale, then wrapper
// applies uniform s scaling + physical hardware holes.
// ─────────────────────────────────────────────────────────────
module fingertipsolid(len=0, grip=1, rad=5) {
    difference() {
        union() {
            // Grip bumps on flat face
            if (grip) {
                translate([0, 0.5, 0])
                    for (i=[0:4])
                        translate([0, i*1.75, 0])
                        fingerpoints(rows=2, rad=rad);
                if (len > 0)
                    translate([0, 0.5, 0])
                        for (i=[5 : ceil(len/6)+4])
                            translate([0, i*1.75, 0])
                            fingerpoints(rows=2, rad=rad);
            }
            // Dome tip
            translate([0, len/3, 0]) rotate([30,0,0])
                translate([0, 10.4, -0.5]) {
                    if (grip) {
                        translate([0, 0.5, 0])
                            for (i=[0:4])
                                translate([0, i*1.75+0.75, -5])
                                fingerpoints(rows=2, rad=rad);
                        if (len > 0) {
                            translate([0, 0.5, 0])
                                for (i=[5 : ceil(len/5.5)+4])
                                    translate([0, i*1.75+0.75, -5])
                                    fingerpoints(rows=2, rad=rad);
                            for (i=[1:4])
                                translate([0, 4*1.75+1.3+len/3, 0])
                                rotate([-24*i, 0, 0])
                                translate([0, 0, -5])
                                fingerpoints(rows=2-round(i%2), rad=rad);
                        } else {
                            for (i=[1:4])
                                translate([0, 4*1.75+1.3, 0])
                                rotate([-24*i, 0, 0])
                                translate([0, 0, -5])
                                fingerpoints(rows=2-round(i%2), rad=rad);
                        }
                    }
                    hull() {
                        translate([0, 0.5, 0])
                            sphere(r=rad-0.25, $fn=fn);
                        if (len > 0) {
                            translate([0, 8.5+len/3, 0])
                                sphere(r=rad-0.25, $fn=fn);
                            translate([0, 8.5+len/3, 0])
                                intersection() {
                                    cylinder(r=4.75, h=10, center=true, $fn=fn);
                                    rotate([90,0,0])
                                        cylinder(r=rad-0.25, h=10, center=true, $fn=fn);
                                    translate([0, 0, -50])
                                        cube(100, center=true);
                                }
                        } else {
                            translate([0, 8.5, 0])
                                sphere(r=rad-0.25, $fn=fn);
                            translate([0, 8.5, 0])
                                intersection() {
                                    cylinder(r=rad-0.25, h=10, center=true, $fn=fn);
                                    rotate([90,0,0])
                                        cylinder(r=rad-0.25, h=10, center=true, $fn=fn);
                                    translate([0, 0, -50])
                                        cube(100, center=true);
                                }
                        }
                    }
                }
            // Mid-to-hinge connecting hull + flat base
            union() {
                translate([0, 0, 0.95])
                    hull()
                    for (i=[-1,1])
                        translate([(rad-0.5)*i, -8, 0])
                        rotate([90,0,0])
                        cylinder(r=1, h=8+len/3, $fn=fn/2, center=false);
                hull() {
                    translate([0, 0, 0.95])
                        for (i=[-1,1])
                            translate([(rad-0.5)*i, -8, 0])
                            rotate([90,0,0])
                            cylinder(r=1, h=(8+len/3)/2, $fn=fn/2, center=false);
                    translate([0, -11-len/3, 5])
                        rotate([0,90,0])
                        cylinder(r=4.75, h=10, center=true, $fn=fn);
                    translate([0, len/3, 0]) rotate([30,0,0])
                        translate([0, rad*2+0.3, -0.5])
                        translate([0, 0.5, 0])
                        sphere(r=rad-0.25, $fn=fn);
                }
            }
        }
        // Fork cutout at proximal end
        hull()
            for (j=[0,5]) for (i=[5,10])
                translate([0, -11-len/3-j, i])
                rotate([0,90,0])
                cylinder(r=5.1, h=4.6, center=true, $fn=fn);
    }
}

module fingertip(s=1, len=0, grip=1) {
    difference() {
        scale([s, s, s]) fingertipsolid(len=len, grip=grip);
        // Pin hole — physical size
        translate([0, (-11-len/3)*s, 5*s])
            rotate([0,90,0])
            cylinder(r=pin_r, h=20, center=true, $fn=fn/2);
        // Elastic channel
        translate([0, 0, 3*s])
            rotate([90,0,0])
            cylinder(r=elastic_r, h=(40+len*4)*s, center=true, $fn=fn/2);
        translate([0, 8.5*s, 3*s])
            rotate([-90,0,0])
            cylinder(r=elastic_r*1.4, h=(40+len*4)*s, center=false, $fn=fn/2);
        hull()
            for (i=[-1,3])
                translate([0, -1.5*s, i*s])
                rotate([90,0,0])
                cylinder(r=elastic_r, h=(40+len*4)*s, center=false, $fn=fn/2);
        // Tendon channel
        hull()
            for (i=[0:1])
                translate([0, 5*s, 8*s+10*s*i])
                rotate([90,0,0])
                cylinder(r=tendon_r, h=(40+len*4)*s, center=false, $fn=fn/2);
        translate([0, (17+len/3)*s, 8*s]) {
            rotate([90,0,0])
                cylinder(r=tendon_r, h=(40+len*4)*s, center=false, $fn=fn/2);
            rotate([30,0,0]) {
                rotate([-90,0,0])
                    cylinder(r=tendon_r*1.5, h=(40+len*4)*s,
                             center=false, $fn=fn/2);
                rotate([-90,0,0])
                    sphere(r=tendon_r*1.5, $fn=fn/2);
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// FINGER LAYOUT — positions mid + tip for one finger
// From cyborgbeast07l.scad fingerlayout().
// ─────────────────────────────────────────────────────────────
module fingerlayout(size=1, length=0) {
    translate([0, (23+length*2/3)*size, 1.5*size])
        rotate([10,0,0])
        fingertip(s=size, grip=1, len=length);
    mirror([0,0,1]) mirror([0,1,0])
        translate([0, 0, -10*size])
        fingermid(s=size, len=length);
}

// ─────────────────────────────────────────────────────────────
// GAUNTLET / FOREARM CUFF
// Wrist socket sized from anthropometric residual limb data.
// Connects to palm via wrist hinge pins.
// ─────────────────────────────────────────────────────────────
module gauntlet() {
    sd   = socket_depth_mm * S;
    ri   = socket_diameter_distal_mm * S / 2;
    ro   = socket_diameter_proximal_mm * S / 2;
    wall = max(socket_rim_thickness_mm, palm_wall_thickness_mm * 1.5);
    cap  = socket_distal_cap_thickness_mm;

    difference() {
        union() {
            cylinder(h=sd, r1=ri+wall, r2=ro+wall, $fn=fn);
            cylinder(h=cap, r=ri+wall+3, $fn=fn);
            translate([0, 0, sd - socket_rim_thickness_mm])
                difference() {
                    cylinder(h=socket_rim_thickness_mm+2,
                             r=ro+wall+socket_rim_thickness_mm*0.5, $fn=fn);
                    translate([0, 0, -1])
                        cylinder(h=socket_rim_thickness_mm+4, r=ro, $fn=fn);
                }
            // Wrist hinge tabs at distal end
            for (i=[-1,1]) {
                translate([26.6*q*i - th/2, -wristH*0.6, 0])
                    cube([th, wristH*1.2, cap + wristH]);
                translate([26.6*q*i, 0, cap + wristH])
                    rotate([0,90,0])
                    cylinder(r=wristH/2, h=th, center=true, $fn=fn);
            }
        }
        translate([0, 0, cap])
            cylinder(h=sd, r1=ri, r2=ro, $fn=fn);
        cylinder(h=cap+1, r=ri*0.82, $fn=fn/2);
        for (i=[-1,1])
            translate([26.6*q*i, 0, cap + wristH])
            rotate([0,90,0])
            cylinder(r=pin_r, h=th+2, center=true, $fn=fn/2);
    }
}

// ─────────────────────────────────────────────────────────────
// HAND ASSEMBLY
// Places palm, 4 anthropometric fingers, thumb, and gauntlet.
// From cyborgbeast07l.scad handlayout() — uses computed lens.
// ─────────────────────────────────────────────────────────────
module handlayout() {
    cyborgbeastpalm();

    if (show_assembled) {
        lens   = [len_index, len_middle, len_ring, len_pinky];
        y_offs = [10*q, 12.5*q, 12*q, 7.5*q];

        // Four fingers
        translate([22*q, 29*q, 10*q])
            rotate([0, 180, 0])
            for (i=[0:3])
                translate([sp*i, y_offs[i], 0])
                    render() fingerlayout(size=q, length=lens[i]);

        // Thumb
        translate([41*q, -9.5*q, -4*q])
            rotate([50, -20, 90]) {
                fingermid(s=q, len=len_thumb_mid);
                translate([0, -18*q, 5*q])
                    rotate([30, 180, 180])
                    fingertip(s=q, len=len_thumb_tip, grip=1);
            }

        // Gauntlet
        translate([0, -27*q, 5.5*q])
            rotate([90, 0, 0])
            gauntlet();
    }
}

// ─────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────
translate([0, 0, 0.01]) cube(0.02, center=true);

mirror(right_hand ? [0,0,0] : [1,0,0])
    handlayout();
