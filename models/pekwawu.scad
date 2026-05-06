// ============================================================
// pekwawu.scad  — PeKwawu v2 Procedural Parametric Arm
// ============================================================
// Fully procedural prosthetic arm for long forearm residual limbs.
// No STL imports — renders completely in the browser via WASM.
//
// Anthropometric parameter names match geometry_parameters fields
// from server/services/anthropometricImporter.js so DB profiles
// apply directly.
// ============================================================

/* [Orientation] */
right_arm = true;

/* [Hand & Arm Measurements] */
palm_breadth_mm                    = 96;   // [65:1:186]
residual_length_mm                 = 282;  // [50:1:500]
residual_circumference_proximal_mm = 270;  // [70:1:542]
bicep_circumference_mm             = 294;  // [100:1:600]

/* [Comfort & Hardware] */
padding_thickness_mm = 2;    // [0:0.5:10]
pivot_diameter_mm    = 4;    // [2:0.5:6]
clearance_mm         = 0.4;  // [0.1:0.1:1.0]
strap_width_mm       = 25;   // [10:1:60]

/* [View] */
show_assembled = true;
$fn = 40;

// ─────────────────────────────────────────────────────────────
// DERIVED SCALARS
// ─────────────────────────────────────────────────────────────
PI  = 3.14159265;
S   = palm_breadth_mm / 96;      // master scale (96 mm = reference)
PW  = palm_breadth_mm;
RL  = residual_length_mm;
RC  = residual_circumference_proximal_mm;
PAD = padding_thickness_mm;
PD  = pivot_diameter_mm;
CL  = clearance_mm;
SW  = strap_width_mm;

// Socket geometry (forearm wrap, axis along Y)
SOCK_R_PROX = (RC / PI + PAD) / 2;   // inner radius proximal (elbow) end
SOCK_R_DIST = SOCK_R_PROX * 0.88;    // inner radius distal (wrist) end
SOCK_DEPTH  = RL * 0.55;             // socket length = 55% residual length
SOCK_WALL   = max(2.5, RC * 0.025);  // shell wall thickness

// Frame geometry
FRAME_W = PW * 0.30;
FRAME_H = PW * 0.15;

// Palm geometry
PL  = PW * 1.05;
PST = PW * 0.28;
WT  = max(2.0, PW * 0.025);
FW  = PW * 0.20;   // finger tab full width (pin hole span)

// Finger/hinge geometry
KR    = max(PD * 1.6, PW * 0.076);
FTAB  = PW * 0.072;
FSLOT = FTAB + CL * 2;
SP    = PW / 5;
KY    = PL * 0.44;
WY    = -PL * 0.20;
WA    = PW * 0.42;
CH    = max(2.0, min(4.0, FTAB * 0.25));
fn    = $fn;

// Phalanx ratios
PR  = 0.45;  MR  = 0.31;  DR  = 0.24;
TPR = 0.54;  TDR = 0.46;
JG  = 1.5 * S;

// Finger total lengths (proportional to palm breadth)
FI = PW * 0.71;
FM = PW * 0.76;
FR = PW * 0.71;
FP = PW * 0.57;
FT = PW * 0.60;

// Knuckle X-positions
KX = [for (i=[-1.5, -0.5, 0.5, 1.5]) i * SP];

// ─────────────────────────────────────────────────────────────
// KNUCKLE BLOCK
// ─────────────────────────────────────────────────────────────
module knuckle_block() {
    difference() {
        hull()
            for (j=[-1,1]) for (i=[-1,1])
                translate([KR*0.52*i, 0, KR*0.5*j])
                    rotate([90,0,0])
                    cylinder(r=KR*0.3, h=KR*2, center=true, $fn=fn/2);
        cube([FSLOT, KR*2.2, KR*1.1], center=true);
    }
}

// ─────────────────────────────────────────────────────────────
// THUMB BOSS
// ─────────────────────────────────────────────────────────────
module thumb_boss() {
    translate([-KR*0.3, -KR*0.5, 0])
        rotate([91,90,20]) knuckle_block();
    hull() {
        translate([-PW*0.12, 0, KR*0.5])
            rotate([0,30,0]) scale([1,1,0.5])
            sphere(r=KR*1.8, $fn=fn);
        hull() {
            cylinder(r=KR*0.9, h=KR*2.2-1, center=true, $fn=fn*2);
            translate([-PW*0.06, -KR*0.2, 0])
                cylinder(r=KR*0.9, h=KR*2, center=true, $fn=fn*2);
            rotate([-10,0,0]) translate([-PW*0.06, -KR*1.2, -KR*0.2])
                cylinder(r=KR*0.9, h=KR*1.8, center=true, $fn=fn*2);
        }
        hull() {
            rotate([-20,0,0]) translate([-PW*0.06, -KR*1.6, -KR*0.6])
                cylinder(r=KR, h=KR*1.4, center=true, $fn=fn*2);
            rotate([-10,0,0]) translate([-PW*0.06, -KR*1.2, -KR*0.2])
                cylinder(r=KR*0.9, h=KR*1.8, center=true, $fn=fn*2);
            rotate([-20,0,0]) translate([-PW*0.1, -KR*2, -KR*0.2])
                cylinder(r=KR*0.9, h=KR*1.8, center=true, $fn=fn*2);
        }
    }
}

// ─────────────────────────────────────────────────────────────
// FINGER MID SEGMENT
// ─────────────────────────────────────────────────────────────
module finger_seg(seg_l) {
    half_l = seg_l / 2;
    hr = KR - 0.2;
    tw = FTAB - 0.2;
    difference() {
        union() {
            hull() {
                for (s=[-1,1])
                    translate([0, s*half_l, KR])
                        rotate([0,90,0])
                        cylinder(r=hr, h=tw, center=true, $fn=fn);
                translate([0, 0, 1])
                    cube([tw, seg_l, 2], center=true);
            }
            hull()
                translate([0, 0, KR+0.5])
                intersection() {
                    scale([1, 2, 1]) rotate([90,0,0])
                        cylinder(r2=hr*0.95, r1=hr*1.15,
                                 h=seg_l*0.7, center=true, $fn=fn*2);
                    cube([tw*2.4, seg_l, KR*2.5], center=true);
                }
        }
        for (s=[-1,1])
            translate([0, s*half_l, KR])
                rotate([0,90,0])
                cylinder(d=PD+CL, h=tw*3, center=true, $fn=fn/2);
        translate([0, 0, KR+KR*0.65])
            rotate([90,0,0])
            cylinder(d=CH, h=seg_l*3, center=true, $fn=fn/4);
        translate([0, 0, KR*0.35])
            rotate([90,0,0])
            cylinder(d=CH, h=seg_l*3, center=true, $fn=fn/4);
        for (s=[0,1]) mirror([0,s,0])
            hull() for (zi=[0,1])
                translate([0, -half_l*0.45, KR*0.2 - KR*0.55*zi])
                    rotate([90,0,0])
                    cylinder(d=CH, h=seg_l*0.6, center=false, $fn=fn/4);
        for (sy=[0,1]) mirror([0,sy,0])
            for (sx=[0,1]) mirror([sx,0,0])
                hull() {
                    translate([tw/2, -half_l, KR]) {
                        rotate([-150,0,0]) translate([0,0,-KR*2])
                            rotate([0,90,0])
                            cylinder(r=KR+CL*2, h=KR*2, $fn=fn);
                        translate([0,0,-KR*2])
                            rotate([0,90,0])
                            cylinder(r=KR+CL*2, h=KR*2, $fn=fn);
                        rotate([0,90,0])
                            cylinder(r=KR+CL*2, h=KR*2, $fn=fn);
                    }
                }
    }
}

// ─────────────────────────────────────────────────────────────
// FINGERTIP
// ─────────────────────────────────────────────────────────────
module finger_tip(seg_l, grip=true) {
    hr  = KR - 0.25;
    tw  = FTAB;
    rad = KR;
    difference() {
        union() {
            hull() {
                translate([0, -seg_l*0.4, KR])
                    rotate([0,90,0])
                    cylinder(r=hr, h=tw, center=true, $fn=fn);
                translate([0, -seg_l*0.1, 1])
                    cube([tw, seg_l*0.6, 2], center=true);
                translate([0, seg_l*0.35, KR])
                    sphere(r=hr, $fn=fn);
                translate([0, seg_l*0.35, KR]) intersection() {
                    cylinder(r=hr*0.95, h=KR*2, center=true, $fn=fn);
                    rotate([90,0,0])
                        cylinder(r=hr, h=KR*2, center=true, $fn=fn);
                    translate([0,0,-500]) cube(1000, center=true);
                }
            }
            hull() {
                translate([0, -seg_l*0.4, KR])
                    rotate([0,90,0])
                    cylinder(r=hr, h=tw, center=true, $fn=fn);
                translate([0, 0, KR+0.5]) intersection() {
                    scale([1, 1.5, 1]) rotate([90,0,0])
                        cylinder(r=hr*1.1, h=seg_l*0.6, center=true, $fn=fn*2);
                    cube([tw*2, seg_l, KR*2.5], center=true);
                }
                translate([0, seg_l*0.35, KR])
                    sphere(r=hr, $fn=fn);
            }
            if (grip) {
                for (i=[0:4])
                    translate([0, -seg_l*0.2+i*KR*0.35, 0])
                    fingerpoints(rad);
                translate([0, seg_l*0.12, 0]) rotate([30,0,0])
                    translate([0, KR*1.2, -KR*0.6])
                    for (i=[0:3])
                        translate([0, i*KR*0.35, 0])
                        fingerpoints(rad);
            }
        }
        hull()
            for (j=[0, KR*0.8]) for (zi=[KR, KR*2])
                translate([0, -seg_l*0.4-j, zi])
                    rotate([0,90,0])
                    cylinder(r=hr+CL+0.1, h=FSLOT, center=true, $fn=fn);
        translate([0, -seg_l*0.4, KR])
            rotate([0,90,0])
            cylinder(d=PD+CL, h=FW, center=true, $fn=fn/2);
        translate([0, 0, KR*0.3])
            rotate([90,0,0])
            cylinder(d=CH, h=seg_l*3, center=true, $fn=fn/4);
        hull() for (zi=[0,1])
            translate([0, seg_l*0.15, KR*0.3+KR*zi*1.2])
                rotate([90,0,0])
                cylinder(d=CH*1.1, h=seg_l*0.4, $fn=fn/4);
        hull() {
            translate([0, -seg_l*0.3, KR+KR*0.65])
                rotate([90,0,0])
                cylinder(d=CH, h=seg_l*0.5, center=true, $fn=fn/4);
            translate([0, seg_l*0.1, KR+KR*0.65])
                rotate([30,0,0]) rotate([-90,0,0])
                cylinder(d=CH*1.5, h=seg_l*0.3, $fn=fn/4);
        }
    }
}

module fingerpoints(rad) {
    for (j=[0,1]) mirror([0,j,0])
        scale([0.78,1,1.1])
        for (i=[-2:2])
            rotate([0, i*15, 0])
            rotate([0, 0, (i%2)*180])
            translate([0, 0, rad+KR*0.8])
                rotate([45,35,90])
                cube(KR*0.14, center=true);
}

// ─────────────────────────────────────────────────────────────
// PALM BASE
// Adapted from anthropometric_hand palm() — organic hull,
// knuckle blocks, thumb boss, wrist hinge arms, interior cavity.
// ─────────────────────────────────────────────────────────────
module palm_base() {
    difference() {
        union() {
            hull() {
                translate([0, KY, KR])
                    rotate([0,90,0])
                    cylinder(r=KR, h=PW-KR*4, center=true, $fn=fn);
                translate([ PW*0.24, KY*0.75, PST+KR*1.5])
                    rotate([-18,10,0]) scale([1,1,0.4]) sphere(r=PW*0.12, $fn=fn);
                translate([ 0, KY*0.73, PST+KR*1.8])
                    rotate([-23,0,0]) scale([1,1,0.2]) sphere(r=PW*0.12, $fn=fn);
                translate([-PW*0.24, KY*0.75, PST+KR*1.2])
                    rotate([-18,-20,0]) scale([1,1,0.4]) sphere(r=PW*0.12, $fn=fn);
                translate([0, PL*0.03, 0])
                    scale([1, 0.8, 1])
                    cylinder(r=PW/2-0.5, h=PST*0.45, $fn=fn*2);
                translate([0, -PL*0.01, PST-1])
                    rotate([-10,-5,0]) scale([1, 0.8, 0.3])
                    sphere(r=PW/2+1.25, $fn=fn*2);
                for (i=[-1,1])
                    translate([WA*i, WY, PST/2])
                    cube([WT, PL*0.12, PST], center=true);
                translate([0, WY-PL*0.04, PST*1.6])
                    scale([1,1,0.4]) rotate([90,0,0])
                    cylinder(r=PW/2-KR*2, h=WT, center=true, $fn=fn);
                translate([0, WY-PL*0.04, 0])
                    rotate([90,0,0]) intersection() {
                        cylinder(r=PW/2-PD*2, h=WT, center=true, $fn=fn);
                        translate([0,PW,0]) cube(PW*2, center=true);
                    }
            }
            for (kx=KX)
                translate([kx, KY, KR+KR])
                    knuckle_block();
            translate([PW*0.48, -PL*0.16, KR])
                rotate([-72,0,0])
                thumb_boss();
        }
        // Interior cavity
        hull() {
            translate([0, -PL*0.04, 0])
                cube([PW*0.72, PL*0.6, PST*2], center=true);
            for (i=[-1,1])
                translate([PW*0.2*i, KY*0.25, 0])
                cylinder(r=PW*0.13, h=PST*2, center=true, $fn=fn);
            translate([0, KY*0.25, PST*1.5])
                rotate([-10,0,0]) scale([1,1,0.3])
                sphere(r=PW*0.12, $fn=fn);
        }
        // Cosmetic through-cuts
        for (m=[0,1]) mirror([m,0,0]) {
            hull() {
                translate([PW*0.15, KY*0.42, 0])
                    cylinder(r=KR*0.65, h=100, center=true, $fn=fn/2);
                translate([PW*0.12, KY*0.12, 0])
                    cylinder(r=KR*0.45, h=100, center=true, $fn=fn/2);
            }
            hull() {
                translate([PW*0.12, KY*0.12, 0])
                    cylinder(r=KR*0.45, h=100, center=true, $fn=fn/2);
                translate([PW*0.06, -KY*0.12, 0])
                    cylinder(r=KR*0.3, h=100, center=true, $fn=fn/2);
            }
        }
        // Knuckle bar pin hole
        translate([0, KY, KR])
            rotate([0,90,0])
            cylinder(d=PD+CL, h=PW*1.1, center=true, $fn=fn/2);
        // Wrist hinge pin hole
        translate([0, WY-PL*0.21+PST*0.75, PST/2])
            rotate([0,90,0])
            cylinder(d=PD+CL, h=PW*1.1, center=true, $fn=fn/2);
        // Knuckle fork slots + tendon guides
        for (kx=KX) {
            translate([kx, KY, 0])
                cube([FSLOT, KR*3, KR*2.2], center=true);
            translate([kx, KY-KR, KR*0.35])
                rotate([30, 0, kx*0.06])
                cylinder(d=CH*1.1, h=PL*0.6, center=false, $fn=fn/4);
        }
        // Tendon routing channels
        for (i=[0:3]) {
            kx = KX[i];
            translate([kx, 0, PW/2-KR])
                rotate([-4,0,0])
                rotate([90, 0, kx*-2/(PW/2)])
                cylinder(d=CH, h=PL, center=true, $fn=fn/4);
        }
        // Thumb hinge hole
        translate([PW*0.48, -PL*0.16, KR])
            rotate([-72,0,0])
            cylinder(d=PD+CL, h=PW*0.35, center=true, $fn=fn/2);
        // Flat bottom cutoff
        translate([0,0,-500]) cube(1000, center=true);
    }
    // Wrist hinge arms (outside main difference)
    wrist_hinge_y = WY - PL*0.21 + PST*0.75;
    for (i=[-1,1])
        difference() {
            union() {
                translate([WA*i, WY, PST/2])
                    cube([WT, PL*0.42, PST], center=true);
                translate([WA*i, wrist_hinge_y, PST/2])
                    rotate([0,90,0])
                    cylinder(r=PST/2, h=WT, center=true, $fn=fn);
            }
            translate([0, wrist_hinge_y, PST/2])
                rotate([0,90,0])
                cylinder(d=PD+CL, h=PW*1.1, center=true, $fn=fn/2);
        }
}

// ─────────────────────────────────────────────────────────────
// FOREARM SOCKET
// Tapered hollow cylinder. Axis along Y (rotate([90,0,0])).
// Wrist/distal end (small) at Y=WY; elbow/proximal (large)
// extends to Y = WY - SOCK_DEPTH.
// ─────────────────────────────────────────────────────────────
module forearm_socket() {
    translate([0, WY, PST/2])
    rotate([90, 0, 0])
    difference() {
        union() {
            // Tapered shell: r1=distal(wrist), r2=proximal(elbow)
            cylinder(h=SOCK_DEPTH,
                     r1=SOCK_R_DIST+SOCK_WALL,
                     r2=SOCK_R_PROX+SOCK_WALL, $fn=fn);
            // Proximal rim flange
            translate([0, 0, SOCK_DEPTH-SOCK_WALL])
                cylinder(h=SOCK_WALL+4,
                         r=SOCK_R_PROX+SOCK_WALL*1.8, $fn=fn);
        }
        // Inner bore (tapered)
        translate([0, 0, -1])
            cylinder(h=SOCK_DEPTH+2,
                     r1=SOCK_R_DIST, r2=SOCK_R_PROX, $fn=fn);
        // Strap slots — opposing sides
        for (a=[0, 180])
            rotate([0, 0, a])
            translate([SOCK_R_PROX*0.85, 0, SOCK_DEPTH*0.4])
                cube([SOCK_WALL*3, SW, SOCK_DEPTH*0.45], center=true);
    }
}

// ─────────────────────────────────────────────────────────────
// STRUCTURAL FRAME
// Two rods bridging palm wrist attachment to socket body.
// ─────────────────────────────────────────────────────────────
module structural_frame() {
    wrist_hinge_y = WY - PL*0.21 + PST*0.75;
    sock_attach_y = WY - SOCK_DEPTH * 0.35;
    sock_outer_r  = SOCK_R_DIST + SOCK_WALL;

    for (side=[-1, 1])
        hull() {
            translate([WA*side, wrist_hinge_y, PST/2])
                sphere(r=FRAME_H/2, $fn=fn/2);
            translate([side * sock_outer_r, sock_attach_y, PST/2])
                sphere(r=FRAME_H/2, $fn=fn/2);
        }
}

// ─────────────────────────────────────────────────────────────
// FULL ASSEMBLY
// ─────────────────────────────────────────────────────────────
module pekwawu_assembly() {
    palm_base();
    forearm_socket();
    structural_frame();

    if (show_assembled) {
        totals = [FI, FM, FR, FP];
        y_off  = [0, 2.5*S, 2*S, -2.5*S];

        for (i=[0:3]) {
            kx = KX[i];
            ft = totals[i];
            pl = ft * PR;
            ml = ft * MR;
            dl = ft * DR;

            translate([kx, KY + y_off[i] + pl/2, KR*2])
                rotate([0,180,0])
                finger_seg(pl);
            translate([kx, KY + y_off[i] + pl + JG + ml/2, KR*2])
                rotate([0,180,0])
                finger_seg(ml);
            translate([kx, KY + y_off[i] + pl + ml + JG*2 + dl*0.4, KR*2])
                rotate([0,180,0])
                finger_tip(dl);
        }

        // Thumb
        translate([PW*0.48, -PL*0.12, -KR*0.6])
            rotate([50, -20, 90]) {
                finger_seg(FT * TPR * 0.65);
                translate([0, -FT*TPR*0.3, KR*0.5])
                    rotate([30, 180, 180])
                    finger_tip(FT * TDR * 0.8, grip=true);
            }
    }
}

// ─────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────
mirror(right_arm ? [0,0,0] : [1,0,0])
    pekwawu_assembly();
