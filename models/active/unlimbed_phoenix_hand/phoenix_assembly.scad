// ============================================================================
//  phoenix_assembly.scad — seated-hand recipe (SHARED, single source of truth)
//
//  Defines module phoenix_assembly(): the full Phoenix hand with palm, fingers,
//  thumb, wrist/finger pins, gauntlet, tensioner block/pins and washers all
//  seated together in one palm-native frame at 100% (native mesh) scale.
//
//  It is INCLUDEd (not used) by two files:
//    • UnLimbitedPhoenix.scad — the served model, wraps phoenix_assembly() in the
//      uniform HandPerc scale for the "Assembly" part option.
//    • _assembly.scad         — the dev harness, renders it standalone for tuning.
//  Both of those provide the part modules (Phoenix_Thermo_Palm_2, Phoenix_Fingers_Left,
//  Phoenix_Phalanx_Left, Gauntlet_V4). This file only pulls in the reconstructed
//  fasteners it does not get from them.
//
//  COORDINATE FRAME (palm-native, millimetres):
//     +X = toward the THUMB side   (-X = pinky)
//     +Y = toward the FINGERTIPS   (-Y = wrist)
//     +Z = DORSAL (back of hand)   (-Z = palmar/grip)
//  Fingers are index, middle, ring, pinky (array order 0..3). Thumb is column 4.
//
//  Because every part scales uniformly about the origin, seating this recipe at
//  100% and wrapping the whole module in one scale() keeps it seated at any size.
// ============================================================================
use <phoenix_snap_pins.scad>       // real Phoenix pins + wrist washers (STEP reconstruction, dev/step2scad)
use <phoenix_tensioner_block.scad> // tensioner housing (STEP reconstruction)
use <phoenix_tensioner_pins.scad>  // three flat tensioner pins (STEP reconstruction)
use <phoenix_preview_meshes.scad>  // palm_preview()/fingers_preview() — manifold remeshes (below)

// PREVIEW-ONLY manifold remeshes of the two non-manifold Phoenix meshes.
// The original Phoenix_Thermo_Palm_2 (palm) and Phoenix_Fingers_Left (distals)
// are non-manifold (self-intersections / edges shared by >2 faces). They render
// fine as a single printable part, but the assembled view UNIONs many parts, and
// the manifold backend (used by the browser preview) silently DROPS any mesh that
// fails PolySet->Manifold conversion — so palm + fingertips vanished. palm_preview()
// and fingers_preview() (phoenix_preview_meshes.scad) are voxel-remeshed, watertight
// polyhedra used ONLY by the assembled preview; the printable part options still use
// the exact original meshes.

// ============================================================================
//  TUNABLES  — everything you adjust lives here
// ============================================================================

// ── FINGERS — index, middle, ring, pinky (array order) ─────────────────────
// Each finger origin is (KX,KY,KZ); its proximal MCP hole ends up at world
// (KX, KY+MCP_HOLE_Y, KZ+PROX_PIN_Z). To seat it on a palm knuckle hole set
// KX=holeX, KY=holeY-MCP_HOLE_Y, KZ=holeZ-PROX_PIN_Z.
KX   = [75.7, 61.8, 47.7, 34];      // per-finger X
KY   = [-66, -66, -70, -76.1];      // per-finger Y (pinky set back for the knuckle arch)
KZ   = [4.3, 4.3, 4.3, 4.3];        // per-finger Z (lower = drop onto the knuckles)
SPLAY= [0, 0, 0, 0];                // per-finger fan angle (deg)
CURL = 0;                           // palmar curl of all fingers about the MCP (deg)
DX   = 0;  DY = 0;                  // nudge ALL fingers together (+X thumb-ward, +Y tipward)
DIST = [[0, -8, 1],   // index      // distal (fingertip) offset per finger [x,y,z]
        [0, -8, 1],   // middle
        [0, -8, 1],   // ring
        [0, -8, 1]];  // pinky
DROT = [[-9,0,0], [-9,0,0], [-9,0,0], [-9,0,0]];  // distal rotation per finger [x,y,z] deg

// ── THUMB (column 4) ───────────────────────────────────────────────────────
TH_POS = [91.8, -106.5, 5.7];       // seat x,y,z — lower z drops it onto the boss
TH_ROT = [-40, 0, -130];            // angle [YZ-tilt, _, XY-swing]
TH_DIST = [0.3, -7.9, 0.7];         // thumb distal (fingertip) offset [x,y,z]
TH_DROT = [-10, 0, 0];              // thumb distal rotation [x,y,z] deg

// ── ARM GUARD (gauntlet) ───────────────────────────────────────────────────
GAUNT_POS = [62, -230, 2];          // more negative y slides it out past the palm to the wrist
GAUNT_ROT = [90, 0, 0];

// ── WRIST HINGE PINS (palm <-> gauntlet) ───────────────────────────────────
WRIST_PIN_A = [27, -142, 8];        // pinky-side hinge pin
WRIST_PIN_B = [83, -142, 8];        // thumb-side hinge pin

// ── PINS — a head marks the insertion side; flip picks which side it goes in ─
PIN_DIA = 4.2;
PIN_LEN = 10;
PIN_HEAD_D = 7;
PIN_HEAD_H = 2;
PIN_FLIP_MCP   = [0, 0, 0, 1];      // knuckle pins    [index,middle,ring,pinky]
PIN_FLIP_PIP   = [0, 0, 0, 0];      // mid-finger pins [index,middle,ring,pinky]
PIN_FLIP_THUMB = [0, 0];            // thumb [MCP, PIP]
PIN_FLIP_WRIST = [1, 0];            // wrist [pinky-side, thumb-side]
PIN_SHOW_MCP   = [1, 1, 1, 1];      // knuckle pins    [index,middle,ring,pinky]
PIN_SHOW_PIP   = [1, 1, 1, 1];      // mid-finger pins [index,middle,ring,pinky]
PIN_SHOW_THUMB = [1, 1];            // thumb [MCP, PIP]
PIN_SHOW_WRIST = [1, 1];            // wrist [pinky-side, thumb-side]
PIN_OFF_MCP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];
PIN_OFF_PIP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];
PIN_OFF_THUMB  = [[1,1,1], [1,1,1]];
PIN_OFF_WRIST  = [[5,0,0], [-5,0,0]];

// ── TENSIONER MECHANISM & WASHERS (real reconstructed parts) ────────────────
WASHER_SHOW    = [1, 1];             // cup washers on the two wrist pins [pinky, thumb]
WASHER_POS     = [[20, -142, 8], [90, -142, 8]];  // one per wrist pin (world)
WASHER_ROT     = [0, 90, 0];         // bore lies along X to slip over the wrist pin
TBLOCK_SHOW    = 1;                  // tensioner block (stadium housing)
TBLOCK_POS     = [55, -168, 3];      // world seat; more -y = further out toward the wrist
TBLOCK_ROT     = [-90, 0, 0];        // stand the tower dorsally, length along the forearm
TPINS_SHOW     = 1;                  // three flat tensioner pins
TPINS_POS      = [55, -150, 12];     // world seat near the wrist
TPINS_ROT      = [0, 0, 0];          // flat, long axis along the forearm (Y)

// ── COLOURS ────────────────────────────────────────────────────────────────
// Colours come from the injectable color_* model parameters (defined by the
// includer: UnLimbitedPhoenix.scad / _assembly.scad), so the Colors tab drives them.
FCOL     = [color_index, color_middle, color_ring, color_pinky];  // index, middle, ring, pinky
TH_COL   = color_thumb;             // thumb
PALM_COL = color_palm;
GAUNT_COL= color_gauntlet;
PIN_COL  = color_pins;
TBLOCK_COL = color_tensioner_block; // tensioner block
TPINS_COL  = color_tensioner_pins;  // tensioner pins
WASHER_COL = color_washers;         // washers
COLMAP   = [0, 1, 2, 3];            // which block column feeds index..pinky

// ============================================================================
//  MEASURED CONSTANTS  — from the source meshes; usually leave these alone
// ============================================================================
PH_CUT = [6.8,22.2,38.5,54.7,80];   FN_CUT = [5.7,21.3,36.4,52.4,80];
PH_XC  = [-2.2,14.0,30.2,46.4,64.3]; FN_XC = [-2.1,13.5,28.8,44.3,62.6];
PH_KNUCKLE_Y = 48.2;  PH_KNUCKLE_Z = 7.7;   // phalanx MCP pin (native block frame)
PH_DISTAL_Y  = 17.1;  PH_DISTAL_Z  = 6.6;   // phalanx PIP (distal) pin
FN_FORK_Y    = -11.2; FN_FORK_Z    = 6.6;   // fingertip PIP fork pin
PIP_LOCAL  = PH_KNUCKLE_Y - PH_DISTAL_Y;    // MCP->PIP along finger (+Y after flip)
PROX_PIN_Z = 1.7;                           // pin-hole height in the finger frame
MCP_HOLE_Y = 3.2;  PIP_HOLE_Y = 26.1;       // MCP & PIP hole Y in the finger frame

// ============================================================================
//  HELPER MODULES  (part modules Phoenix_*/Gauntlet_V4 come from the includer)
// ============================================================================
function lo(c,i) = i==0 ? -14 : c[i-1];
module ph_col(i){ intersection(){ Phoenix_Phalanx_Left(); translate([lo(PH_CUT,i),-200,-12]) cube([PH_CUT[i]-lo(PH_CUT,i),400,44]); } }
module fn_col(i){ intersection(){ fingers_preview(); translate([lo(FN_CUT,i),-200,-12]) cube([FN_CUT[i]-lo(FN_CUT,i),400,44]); } }

// canonical finger: MCP pin at origin, extends +Y, palmar/curl down (-Z), dorsal up (+Z).
module finger_unit(i, fcol, doff=[0,-3.9,0.7], drot=[0,0,0]){
    color(fcol){
      // proximal — flipped 180° about its long axis at the pin line so the fork fins point UP,
      // keeping both pin holes on the axis and the tall knuckle at the MCP/palm end.
      translate([0,0,PROX_PIN_Z]) rotate([0,180,0]) translate([0,0,-PROX_PIN_Z])
        rotate([180,0,0]) translate([-PH_XC[i], -PH_KNUCKLE_Y, -PH_KNUCKLE_Z]) ph_col(i);
      // fingertip — offset by doff, then rotated by drot about the PIP joint
      translate([0,PIP_HOLE_Y,PROX_PIN_Z]) rotate(drot) translate([0,-PIP_HOLE_Y,-PROX_PIN_Z])
        translate(doff)
          rotate([180,0,0]) translate([-FN_XC[i], PH_DISTAL_Y-PH_KNUCKLE_Y-FN_FORK_Y, PH_DISTAL_Z-PH_KNUCKLE_Z-FN_FORK_Z]) fn_col(i);
    }
}

// Real Phoenix snap pins, reconstructed from the STEP B-rep (phoenix_snap_pins.scad):
//   body_1 = finger/thumb pin (~Ø4), body_0 = larger wrist pin (~Ø5).
module pin(flip=0){ color(PIN_COL) rotate([0, flip?-90:90, 0]) finger_pin_centered(); }
module wpin(flip=0){ color(PIN_COL) rotate([0, flip?-90:90, 0]) wrist_pin_centered(); }

// ============================================================================
//  ASSEMBLY  — the whole seated hand as one module
// ============================================================================
module phoenix_assembly(){
    if(show_palm) color(PALM_COL) palm_preview();                         // palm (manifold preview mesh)

    if(show_fingers)
      for(f=[0:3])                                                        // fingers
        translate([KX[f]+DX,KY[f]+DY,KZ[f]]) rotate([0,0,SPLAY[f]]) rotate([CURL,0,0])
          finger_unit(COLMAP[f], FCOL[f], DIST[f], DROT[f]);

    if(show_thumb) translate(TH_POS) rotate(TH_ROT) finger_unit(4, TH_COL, TH_DIST, TH_DROT);  // thumb

    if(show_pins){
      for(f=[0:3])                                                        // finger pins
        translate([KX[f]+DX,KY[f]+DY,KZ[f]]) rotate([0,0,SPLAY[f]]) rotate([CURL,0,0]){
          if(PIN_SHOW_MCP[f]) translate([0,MCP_HOLE_Y,PROX_PIN_Z]+PIN_OFF_MCP[f]) pin(PIN_FLIP_MCP[f]);
          if(PIN_SHOW_PIP[f]) translate([0,PIP_HOLE_Y,PROX_PIN_Z]+PIN_OFF_PIP[f]) pin(PIN_FLIP_PIP[f]); }
      translate(TH_POS) rotate(TH_ROT){                                  // thumb pins
          if(PIN_SHOW_THUMB[0]) translate([0,MCP_HOLE_Y,PROX_PIN_Z]+PIN_OFF_THUMB[0]) pin(PIN_FLIP_THUMB[0]);
          if(PIN_SHOW_THUMB[1]) translate([0,PIP_HOLE_Y,PROX_PIN_Z]+PIN_OFF_THUMB[1]) pin(PIN_FLIP_THUMB[1]); }
      if(PIN_SHOW_WRIST[0]) translate(WRIST_PIN_A+PIN_OFF_WRIST[0]) wpin(PIN_FLIP_WRIST[0]);   // wrist pins
      if(PIN_SHOW_WRIST[1]) translate(WRIST_PIN_B+PIN_OFF_WRIST[1]) wpin(PIN_FLIP_WRIST[1]);
    }

    if(show_gauntlet) color(GAUNT_COL) translate(GAUNT_POS) rotate(GAUNT_ROT) Gauntlet_V4();  // arm guard

    if(show_tensioner){                                                   // tensioner mechanism & washers
      if(WASHER_SHOW[0]) color(WASHER_COL) translate(WASHER_POS[0]) rotate(WASHER_ROT) washer_centered();
      if(WASHER_SHOW[1]) color(WASHER_COL) translate(WASHER_POS[1]) rotate(WASHER_ROT) washer_centered();
      if(TBLOCK_SHOW)    color(TBLOCK_COL) translate(TBLOCK_POS) rotate(TBLOCK_ROT) tensioner_block_centered();
      if(TPINS_SHOW)     color(TPINS_COL)  translate(TPINS_POS)  rotate(TPINS_ROT)  tensioner_pins_centered();
    }
}

// ============================================================================
//  PRINT-BED LAYOUT  — every visible part laid flat, side by side, for export
//  Uses the manifold-safe meshes (palm/distals repaired) so the whole plate
//  survives the manifold backend; each part keeps its own print orientation.
// ============================================================================
module phoenix_printlayout(){
    if(show_palm)     color(PALM_COL)   translate([0,   0,  0]) palm_preview();
    if(show_fingers){ color(FCOL[0])    translate([115, 0,  0]) Phoenix_Phalanx_Left();   // proximals plate
                      color(FCOL[2])    translate([115, 60, 0]) fingers_preview(); }      // distals plate
    if(show_pins)     color(PIN_COL)    translate([210, 0,  0]) Phoenix_Pins();
    if(show_gauntlet) color(GAUNT_COL)  translate([-10, 60, 0]) rotate([90,0,0]) Gauntlet_V4();
    if(show_tensioner){ color(TBLOCK_COL) translate([210, 70, 0]) tensioner_block_centered();
                        color(TPINS_COL)  translate([250, 70, 0]) tensioner_pins_centered(); }
}

// Dispatcher: assembled seated preview or the flat print-bed layout.
module phoenix_render(){ if(print_layout) phoenix_printlayout(); else phoenix_assembly(); }
