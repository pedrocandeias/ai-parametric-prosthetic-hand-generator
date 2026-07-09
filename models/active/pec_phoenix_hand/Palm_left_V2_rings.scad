// =============================================================================
// Palm_left_V2_rings.scad - finger pivot CLEVISES rebuilt as ROUND eye lobes.
// Each prong BODY is a CYLINDER about the pin axis X (a true round pivot eye /
// boss), measured radius EYE_R~6 (radial occupancy of orig_aligned.stl: the eye
// lobe front/down reach 5.9mm), centred on the bore (cy, z6), spanning the
// prong's measured X-band, HULLED to a small floor footprint so the neck tapers
// (rounded) to the plate. A rear-only palm-merge BACKBOX (entirely behind the
// eye centre, -Y) fills the neck that welds into the palm body for volume/IoU;
// because it stops AT the eye centre it never touches the +Y front, so the front
// silhouette stays the round lobe. Everything clip_ghost-trimmed to the true
// envelope. KEYHOLE pin passage kept EXACT: round bore r2.5 (z6) / rect slot 4x6.
//   pinky : slot[-35.5,-31.8] | bore[-25.7,-18.0]  (eye cy30 z6)
//   ring  : slot[-21.5,-17.8] | bore[-11.7, -5.2]  (eye cy36 z6)
//   middle: bore[-11.5,-3.8]  | shared bore[2.5,10.3] (eye cy40 z6)
//   index : shared bore[2.5,10.3] | slot[16.5,19.8]   (eye cy40 z6)
// =============================================================================
$fn = 64;
// --- KEYHOLE pin-passage dimensions (kept EXACT; functional mating interface) ---
// Each clevis passes the pin through one prong as a round BORE (r=BR) and the
// other as a rect SLOT (SW x SH) so the finger tab can drop in and rotate.
BR = 2.5;     // round pin bore radius (find_holes: r2.50, 100% circularity)
SW = 4.0;     // rect slot width  (Y)
SH = 6.0;     // rect slot height (Z)
CZ = 6.0;     // eye / bore centre Z
// MEASURED disc geometry (ray-cast about (cy, z6) on orig_aligned.stl):
//   exposed face front+bottom (angles 270deg->0->90) = clean circle R_FOOT=5.9 -> disc BOTTOM at
//     z = 6 - 5.9 = 0.1 == TANGENT to the plate (smooth round-to-floor, no chord, no foot).
//   top/back (angles 90->240) grows to ~7.2..8.9 where the disc merges into the spine + palm body.
// The old single cylinder used r=7.6 centred at z6 -> the disc BOTTOM was at z=-1.6, i.e. it plunged
// 1.6mm THROUGH the plate and got sliced into a wide flat chord with a hard right-angle dihedral =
// the square FOOT. Fix: hull a FOOT disc (R_FOOT, tangent) with a raised TOP-fill disc (R_TOP) so the
// model's OWN bottom is the tangent circle (round to the floor) yet the top/back still overfills for
// clip to carve the exact ghost. No reliance on clip to hide a sub-floor plunge.
R_FOOT = 5.9;   // exposed disc radius -> bottom tangent to plate at z0.1
R_TOP  = 7.6;   // raised top-fill disc radius (overfills top/back; clip_ghost trims to envelope)
Z_TOP  = 8.6;   // centre Z of the top-fill disc (its bottom z=1.0, never below the plate)
NECK_B = 14;  // palm-merge backbox reach back toward palm (-Y from cy)
NECK_Z = 20;  // palm-merge backbox height (above ghost dorsal ~17.4 so clip carves the rounded top)

module bore(x0,x1,cy) translate([x0-1,cy,CZ]) rotate([0,90,0]) cylinder(h=x1-x0+2,r=BR);
module slot(x0,x1,cy) translate([x0-1,cy-SW/2,CZ-SH/2]) cube([x1-x0+2,SW,SH]);
module spine(sx0,sx1,cy) {
    translate([sx0-0.4,cy-5.2,13.0]) cube([sx1-sx0+0.8,4.2,2.6]);  // back top rim
    translate([sx0-0.4,cy-10.0, 0.0]) cube([sx1-sx0+0.8,3.2,2.4]); // back floor
}
// ROUND eye lobe: cylinder boss about the pin axis (R=EYE_R), tangent to the plate so the
// disc rounds SMOOTHLY into the floor (no plunge -> no flat chord, no square foot). A thin
// ROUNDED coaxial floor bead set BEHIND the disc front (toward the palm, -Y) is hulled in to
// taper the neck down to the plate; because the bead stays behind cy the +Y silhouette is the
// pure round disc. No flat rect root -> the model's OWN shape is round to the floor.
module eye_lobe(x0,x1,cy) hull() {
    translate([x0,cy,CZ])    rotate([0,90,0]) cylinder(h=x1-x0, r=R_FOOT, $fn=96); // FOOT disc: tangent to plate
    translate([x0,cy,Z_TOP]) rotate([0,90,0]) cylinder(h=x1-x0, r=R_TOP,  $fn=96); // TOP-fill disc (raised, never sub-floor)
    translate([x0, cy-NECK_B, 0.0]) cube([x1-x0, NECK_B, 0.6]); // solid flat rear floor root (behind disc front; no foot)
}
// rear-only palm-merge fill: behind the eye centre (-Y), width spans the finger so
// adjacent fingers' boxes overlap and weld; clip_ghost makes it the exact ghost neck.
module backbox(xc, cy) translate([xc-9, cy-NECK_B, 0]) cube([18, NECK_B, NECK_Z]);

GHOST_STL = "/home/pec/dev/openscad-parametric-reconstructor/tmp/openscad-projects/palm-left-reconstructed/output/orig_aligned.stl";
// clip children to the ORIGINAL envelope: trims lobe/neck/backbox overflow to the
// true ghost surface; the keyhole bore + finger-tab slot are voids in the ghost so
// the clip leaves them open; each link still difference()s its bore/slot afterwards.
module clip_ghost() intersection() { children(); import(GHOST_STL, convexity=8); }

// --- the four clevises (same names as V2 so they drop in) --------------------
// Each: build the two eye lobes + spine + palm-merge backbox, clip the lot to the
// ghost envelope, then cut the keyhole (slot through one prong, bore through other).
module link_pinky_ring() {
    difference() {
        clip_ghost() union() {
            eye_lobe(-35.5,-31.8,30); eye_lobe(-25.7,-18.0,30);
            spine(-31.8,-25.7,30);    backbox(-28.8,30);
        }
        slot(-35.5,-31.8,30); bore(-25.7,-18.0,30);
    }
}
module link_ring_ring() {
    difference() {
        clip_ghost() union() {
            eye_lobe(-21.5,-17.8,36); eye_lobe(-11.7,-5.2,36);
            spine(-17.8,-11.7,36);    backbox(-14.8,36);
        }
        slot(-21.5,-17.8,36); bore(-11.7,-5.2,36);
    }
}
module link_middle_ring() {
    difference() {
        clip_ghost() union() {
            eye_lobe(-11.5,-3.8,40); eye_lobe(2.5,10.3,40);
            spine(-3.8,2.5,40);      backbox(-0.7,40);
        }
        bore(-11.5,-3.8,40); bore(2.5,10.3,40);
    }
}
module link_index_ring() {
    difference() {
        clip_ghost() union() {
            eye_lobe(2.5,10.3,40); eye_lobe(16.5,19.8,40);
            spine(10.3,16.5,40);   backbox(13.3,40);
        }
        bore(2.5,10.3,40); slot(16.5,19.8,40);
    }
}
module finger_rings() { link_pinky_ring(); link_ring_ring(); link_middle_ring(); link_index_ring(); }

// finger_rings();  // uncomment for standalone preview

// dome<->clevis junction merged with the clevises in ONE ghost-clip (manifold):
// raw lobes/spines/backboxes + a front junction band, clipped once, then bores/
// slots/cable-channels subtracted. Closes the gap between the dome and the clevises.
module front_assembly() {
  difference() {
    intersection() {
      union() {
        eye_lobe(-35.5,-31.8,30); eye_lobe(-25.7,-18.0,30); spine(-31.8,-25.7,30); backbox(-28.8,30);
        eye_lobe(-21.5,-17.8,36); eye_lobe(-11.7, -5.2,36); spine(-17.8,-11.7,36); backbox(-14.8,36);
        eye_lobe(-11.5, -3.8,40); eye_lobe(  2.5, 10.3,40); spine( -3.8,  2.5,40); backbox(-0.7,40);
        eye_lobe(  2.5, 10.3,40); eye_lobe( 16.5, 19.8,40); spine( 10.3, 16.5,40); backbox(13.3,40);
        translate([-37,22,10]) cube([57,20,14]);   // dome->clevis junction band
      }
      import(GHOST_STL, convexity=8);
    }
    slot(-35.5,-31.8,30); bore(-25.7,-18.0,30);
    slot(-21.5,-17.8,36); bore(-11.7,-5.2,36);
    bore(-11.5,-3.8,40);  bore( 2.5,10.3,40);
    bore( 2.5,10.3,40);   slot(16.5,19.8,40);
    for (channel = CH) path_sweep(circle(r=CH_R), channel);   // keep cable channels open
  }
}
