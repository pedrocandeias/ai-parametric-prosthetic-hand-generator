// ============================================================
// anthropometric_hand.scad  — Organic Parametric Prosthetic Hand
// ============================================================
// All parameters map to the geometry_parameters vector from
// server/services/anthropometricImporter.js
//
// Design inspired by Cyborg Beast / e-NABLE open prosthetics:
//   • Hull-based organic palm with cosmetic cutouts
//   • Cylindrical hinge joints at MCP / PIP / DIP
//   • Wrist pivot arms for tenodesis actuation
//   • Grip-textured fingertips
//   • Flat-bottom segments for FDM printing
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
// DERIVED SCALARS
// ─────────────────────────────────────────────────────────────
S   = global_scale;
PW  = palm_width_mm * S;
PL  = palm_length_mm * S;
PST = palm_structural_thickness * S;
FW  = finger_base_width * S;
JG  = joint_spacing_mm * S;
PD  = pivot_diameter_mm;
CL  = clearance_mm;
CH  = internal_channel_diameter;
WT  = palm_wall_thickness_mm;

// Phalanx proportional ratios
PR  = 0.45;  MR  = 0.31;  DR  = 0.24;
TPR = 0.54;  TDR = 0.46;

// Organic geometry constants
KR   = max(PD * 1.6, PW * 0.076);   // knuckle hinge radius
FTAB = PW * 0.072;                    // finger tab width
FSLOT = FTAB + CL * 2;               // knuckle slot width
SP   = PW / 4;                        // finger lateral spacing

// Palm topology positions
KY  = PL * 0.44;      // knuckle bar Y (from palm centre)
WY  = -PL * 0.20;     // wrist arms Y
WA  = PW * 0.42;      // wrist arm X offset
fn  = $fn;

// Finger knuckle X-positions (centered, evenly spaced)
KX = [for (i=[-1.5, -0.5, 0.5, 1.5]) i * SP];

// ─────────────────────────────────────────────────────────────
// KNUCKLE BLOCK
// Fork at each finger position — slot receives the finger tab.
// Origin = hinge pin centre.
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
// PALM
// Organic hull + knuckle blocks + wrist arms + thumb
// ─────────────────────────────────────────────────────────────
module palm() {
    difference() {
        union() {
            // ── Organic palm solid (hull of spheres & cylinders) ──
            hull() {
                // Knuckle bar — cylinder spanning finger positions
                translate([0, KY, KR])
                    rotate([0,90,0])
                    cylinder(r=KR, h=PW-KR*4, center=true, $fn=fn);

                // Dorsal back-of-knuckle organic bumps
                translate([ PW*0.24, KY*0.75, PST+KR*1.5])
                    rotate([-18, 10,0]) scale([1,1,0.4]) sphere(r=PW*0.12, $fn=fn);
                translate([ 0,       KY*0.73, PST+KR*1.8])
                    rotate([-23, 0,0]) scale([1,1,0.2]) sphere(r=PW*0.12, $fn=fn);
                translate([-PW*0.24, KY*0.75, PST+KR*1.2])
                    rotate([-18,-20,0]) scale([1,1,0.4]) sphere(r=PW*0.12, $fn=fn);

                // Palm base disc
                translate([0, PL*0.03, 0])
                    scale([1, 0.8, 1])
                    cylinder(r=PW/2-0.5, h=PST*0.45, $fn=fn*2);

                // Dorsal surface hump (large flattened sphere)
                translate([0, -PL*0.01, PST-1])
                    rotate([-10,-5,0]) scale([1, 0.8, 0.3])
                    sphere(r=PW/2+1.25, $fn=fn*2);

                // Wrist bar stubs (pull hull toward wrist)
                for (i=[-1,1])
                    translate([WA*i, WY, PST/2])
                    cube([WT, PL*0.12, PST], center=true);

                // Back of wrist arches
                translate([0, WY-PL*0.04, PST*1.6])
                    scale([1,1,0.4]) rotate([90,0,0])
                    cylinder(r=PW/2-KR*2, h=WT, center=true, $fn=fn);
                translate([0, WY-PL*0.04, 0])
                    rotate([90,0,0]) intersection() {
                        cylinder(r=PW/2-PD*2, h=WT, center=true, $fn=fn);
                        translate([0,PW,0]) cube(PW*2, center=true);
                    }

                // Dorsal wrist tendon outlet bump
                translate([0, WY-PL*0.06, PST*2.6])
                    scale([0.5, 0.3, 0.1]) sphere(r=PW/2-KR*2, $fn=fn);
            }

            // ── Knuckle blocks ──
            for (kx = KX)
                translate([kx, KY, KR+KR])
                    knuckle_block();

            // ── Thumb solid (radial side) ──
            translate([PW*0.48, -PL*0.16, KR])
                rotate([-72,0,0])
                thumb_boss();
        }

        // ── Interior cavity ──
        hull() {
            translate([0, -PL*0.04, 0])
                cube([PW*0.72, PL*0.6, PST*2], center=true);
            for (i=[-1,1])
                translate([PW*0.2*i, KY*0.25, 0])
                cylinder(r=PW*0.13, h=PST*2, center=true, $fn=fn);
            translate([0, KY*0.25, PST*1.5])
                rotate([-10,0,0]) scale([1,1,0.3])
                sphere(r=PW*0.12, $fn=fn);
            for (i=[-1,1])
                translate([PW*0.16*i, KY*0.25, PST*1.5])
                rotate([-10,10*i,0]) scale([1,1,0.3])
                sphere(r=PW*0.12, $fn=fn);
            translate([0, WY+PL*0.06, PST*1.9])
                rotate([-10,0,0]) scale([1,1,0.3])
                sphere(r=PW*0.24, $fn=fn);
        }

        // ── Cosmetic through-cuts (teardrop slots) ──
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

        // ── Knuckle bar pin hole ──
        translate([0, KY, KR])
            rotate([0,90,0])
            cylinder(d=PD+CL, h=PW*1.1, center=true, $fn=fn/2);

        // ── Wrist hinge pin hole ──
        translate([0, WY-PL*0.21+PST*0.75, PST/2])
            rotate([0,90,0])
            cylinder(d=PD+CL, h=PW*1.1, center=true, $fn=fn/2);

        // ── Finger knuckle slots ──
        for (kx = KX) {
            translate([kx, KY, 0])
                cube([FSLOT, KR*3, KR*2.2], center=true);
            // Tendon guide angled from knuckle through palm
            translate([kx, KY-KR, KR*0.35])
                rotate([30, 0, kx*0.06])
                cylinder(d=CH*1.1, h=PL*0.6, center=false, $fn=fn/4);
        }

        // ── Tendon routing channels (one per finger, fanning through palm) ──
        for (i=[0:3]) {
            kx = KX[i];
            translate([kx, 0, PW/2-KR])
                rotate([-4,0,0])
                rotate([90, 0, kx*-2/(PW/2)])
                cylinder(d=CH, h=PL, center=true, $fn=fn/4);
        }

        // ── Elastic return holes near knuckles ──
        for (i=[-1,1])
            translate([SP*2*i, KY-KR*2.5, 0])
            for (j=[-1,1])
                translate([KR*0.4*j, 0, 0])
                cylinder(d=CH*1.25, h=100, center=true, $fn=fn/4);

        // ── Velcro strap holes ──
        for (xi=[-1,0,1])
            translate([PW*0.21*xi, pow(xi,2)*-PL*0.18+PL*0.04, 0])
            cylinder(d=PD+CL, h=100, center=true, $fn=fn/2);

        // ── Thumb hinge hole ──
        translate([PW*0.48, -PL*0.16, KR])
            rotate([-72,0,0])
            cylinder(d=PD+CL, h=PW*0.35, center=true, $fn=fn/2);

        // ── Flat bottom cutoff ──
        translate([0,0,-500]) cube(1000, center=true);
    }

    // ── Wrist hinge arms (separate from hull — like Cyborg Beast) ──
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
// THUMB BOSS
// Organic solid for the thumb mount (radial side of palm).
// Origin at hinge centre; extends in -Y direction.
// ─────────────────────────────────────────────────────────────
module thumb_boss() {
    // Knuckle block for thumb
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
// FINGER MID SEGMENT (proximal or middle phalanx)
//
// Coordinate: origin = segment centre
//   Y = finger axis (hinges at ±seg_l/2)
//   Z = 0 = build plate (palmar flat surface)
//   Hinge centres at Z = KR
//
// For assembly: rotate([0,180,0]) flips so flat bottom becomes
// dorsal surface (top of finger when worn).
// ─────────────────────────────────────────────────────────────
module finger_seg(seg_l) {
    half_l = seg_l / 2;
    hr = KR - 0.2;
    tw = FTAB - 0.2;

    difference() {
        union() {
            // Main body hull — two hinge cylinders + flat base
            hull() {
                for (s=[-1,1])
                    translate([0, s*half_l, KR])
                        rotate([0,90,0])
                        cylinder(r=hr, h=tw, center=true, $fn=fn);
                translate([0, 0, 1])
                    cube([tw, seg_l, 2], center=true);
            }

            // Dorsal organic rounding
            hull()
                translate([0, 0, KR+0.5])
                intersection() {
                    scale([1, 2, 1]) rotate([90,0,0])
                        cylinder(r2=hr*0.95, r1=hr*1.15,
                                 h=seg_l*0.7, center=true, $fn=fn*2);
                    cube([tw*2.4, seg_l, KR*2.5], center=true);
                }
        }

        // Hinge pin holes
        for (s=[-1,1])
            translate([0, s*half_l, KR])
                rotate([0,90,0])
                cylinder(d=PD+CL, h=tw*3, center=true, $fn=fn/2);

        // Elastic channel (dorsal side, above hinge)
        translate([0, 0, KR+KR*0.65])
            rotate([90,0,0])
            cylinder(d=CH, h=seg_l*3, center=true, $fn=fn/4);

        // Tendon channel (palmar side, below hinge)
        translate([0, 0, KR*0.35])
            rotate([90,0,0])
            cylinder(d=CH, h=seg_l*3, center=true, $fn=fn/4);

        // Tendon constriction channels (allow cable to bend finger)
        for (s=[0,1]) mirror([0,s,0])
            hull() for (zi=[0,1])
                translate([0, -half_l*0.45, KR*0.2 - KR*0.55*zi])
                    rotate([90,0,0])
                    cylinder(d=CH, h=seg_l*0.6, center=false, $fn=fn/4);

        // Side scallops at 4 corners — carve away material to reveal narrow tab
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
// FINGERTIP (distal phalanx — dome + grip texture)
//
// Same coordinate convention as finger_seg.
// Proximal hinge at Y = -seg_l*0.4 receives the previous
// segment's distal hinge via a fork cutout.
// ─────────────────────────────────────────────────────────────
module finger_tip(seg_l, grip=true) {
    hr  = KR - 0.25;
    tw  = FTAB;
    rad = KR;

    difference() {
        union() {
            // Tip body hull — hinge to dome
            hull() {
                // Proximal hinge cylinder
                translate([0, -seg_l*0.4, KR])
                    rotate([0,90,0])
                    cylinder(r=hr, h=tw, center=true, $fn=fn);
                // Flat bottom
                translate([0, -seg_l*0.1, 1])
                    cube([tw, seg_l*0.6, 2], center=true);
                // Dome sphere
                translate([0, seg_l*0.35, KR])
                    sphere(r=hr, $fn=fn);
                // Dome flattened cap
                translate([0, seg_l*0.35, KR]) intersection() {
                    cylinder(r=hr*0.95, h=KR*2, center=true, $fn=fn);
                    rotate([90,0,0])
                        cylinder(r=hr, h=KR*2, center=true, $fn=fn);
                    translate([0,0,-500]) cube(1000, center=true);
                }
            }

            // Finger mid hull blending (above hinge to dome)
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

            // Grip texture bumps (dorsal surface)
            if (grip) {
                for (i=[0:4])
                    translate([0, -seg_l*0.2+i*KR*0.35, 0])
                    fingerpoints(rad);
                // Wrap-around tip grip
                translate([0, seg_l*0.12, 0]) rotate([30,0,0])
                    translate([0, KR*1.2, -KR*0.6])
                    for (i=[0:3])
                        translate([0, i*KR*0.35, 0])
                        fingerpoints(rad);
            }
        }

        // Fork cutout at proximal end (slot to receive prev segment's hinge)
        hull()
            for (j=[0, KR*0.8]) for (zi=[KR, KR*2])
                translate([0, -seg_l*0.4-j, zi])
                    rotate([0,90,0])
                    cylinder(r=hr+CL+0.1, h=FSLOT, center=true, $fn=fn);

        // Proximal pin hole
        translate([0, -seg_l*0.4, KR])
            rotate([0,90,0])
            cylinder(d=PD+CL, h=FW, center=true, $fn=fn/2);

        // Elastic channel
        translate([0, 0, KR*0.3])
            rotate([90,0,0])
            cylinder(d=CH, h=seg_l*3, center=true, $fn=fn/4);
        // Elastic exit bend
        hull() for (zi=[0,1])
            translate([0, seg_l*0.15, KR*0.3+KR*zi*1.2])
                rotate([90,0,0])
                cylinder(d=CH*1.1, h=seg_l*0.4, $fn=fn/4);

        // Tendon channel
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

// Grip texture point
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
// GAUNTLET / FOREARM CUFF
// Connects to palm via wrist hinge pins.
// Origin at distal face; extends in +Z toward elbow.
// ─────────────────────────────────────────────────────────────
module gauntlet() {
    sd   = socket_depth_mm * S;
    ri   = socket_diameter_distal_mm   * S / 2;
    ro   = socket_diameter_proximal_mm * S / 2;
    wall = max(socket_rim_thickness_mm, WT * 1.5);
    cap  = socket_distal_cap_thickness_mm;

    difference() {
        union() {
            // Tapered shell
            cylinder(h=sd, r1=ri+wall, r2=ro+wall, $fn=fn);
            // Distal cap / flange
            cylinder(h=cap, r=ri+wall+3, $fn=fn);
            // Proximal rim reinforcement
            translate([0, 0, sd-socket_rim_thickness_mm])
                difference() {
                    cylinder(h=socket_rim_thickness_mm+2,
                             r=ro+wall+socket_rim_thickness_mm*0.5, $fn=fn);
                    translate([0,0,-1])
                        cylinder(h=socket_rim_thickness_mm+4, r=ro, $fn=fn);
                }
            // Wrist hinge tabs at distal end
            for (i=[-1,1])
                translate([WA*i-WT/2, -PST*0.6, 0])
                    cube([WT, PST*1.2, cap+PST]);
            for (i=[-1,1])
                translate([WA*i, 0, cap+PST])
                    rotate([0,90,0])
                    cylinder(r=PST/2, h=WT, center=true, $fn=fn);
        }
        // Inner bore (tapered)
        translate([0, 0, cap])
            cylinder(h=sd, r1=ri, r2=ro, $fn=fn);
        // Distal through-hole
        cylinder(h=cap+1, r=ri*0.82, $fn=fn/2);
        // Wrist hinge pin holes
        for (i=[-1,1])
            translate([WA*i, 0, cap+PST])
                rotate([0,90,0])
                cylinder(d=PD+CL, h=WT+2, center=true, $fn=fn/2);
    }
}

// ─────────────────────────────────────────────────────────────
// HAND ASSEMBLY
// ─────────────────────────────────────────────────────────────
module hand_assembly() {
    // ── Palm ──
    palm();

    if (show_assembled) {
        totals = [finger_length_index, finger_length_middle,
                  finger_length_ring,  finger_length_pinky];
        // Y stagger for natural hand arch
        y_off = [0, 2.5*S, 2*S, -2.5*S];

        // ── Four fingers ──
        // Segments are designed with Z=0 as print surface.
        // rotate([0,180,0]) flips so flat bottom becomes dorsal surface.
        for (i=[0:3]) {
            kx = KX[i];
            ft = totals[i] * S;
            pl = ft * PR;   // proximal phalanx length
            ml = ft * MR;   // middle phalanx length
            dl = ft * DR;   // distal phalanx length

            // Proximal phalanx — proximal hinge at knuckle position
            translate([kx, KY + y_off[i] + pl/2, KR*2])
                rotate([0,180,0])
                finger_seg(pl);

            // Middle phalanx
            translate([kx, KY + y_off[i] + pl + JG + ml/2, KR*2])
                rotate([0,180,0])
                finger_seg(ml);

            // Distal phalanx (fingertip)
            translate([kx, KY + y_off[i] + pl + ml + JG*2 + dl*0.4, KR*2])
                rotate([0,180,0])
                finger_tip(dl);
        }

        // ── Thumb ──
        ft_t = finger_length_thumb * S;
        translate([PW*0.48, -PL*0.12, -KR*0.6])
            rotate([50, -20, 90]) {
                // Thumb mid (proximal)
                finger_seg(ft_t * TPR * 0.65);
                // Thumb tip
                translate([0, -ft_t*TPR*0.3, KR*0.5])
                    rotate([30, 180, 180])
                    finger_tip(ft_t * TDR * 0.8, grip=true);
            }

        // ── Gauntlet ──
        wrist_hinge_y = WY - PL*0.21 + PST*0.75;
        translate([0, wrist_hinge_y, PST/2])
            rotate([90, 0, 0])
            gauntlet();
    }
}

// ─────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────
mirror(right_hand ? [0,0,0] : [1,0,0])
    hand_assembly();
