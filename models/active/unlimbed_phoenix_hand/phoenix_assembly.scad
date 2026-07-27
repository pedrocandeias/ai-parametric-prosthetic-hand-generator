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
GAUNT_POS = [55, -235, 2];          // more negative y slides it out past the palm to the wrist
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
PIN_FLIP_THUMB = [1, 1];            // thumb [MCP, PIP] — MCP flipped: rectangular head into the saddle's rectangular recess (thumb-local -X side)
PIN_FLIP_WRIST = [0, 1];            // wrist [pinky-side, thumb-side]
PIN_SHOW_MCP   = [1, 1, 1, 1];      // knuckle pins    [index,middle,ring,pinky]
PIN_SHOW_PIP   = [1, 1, 1, 1];      // mid-finger pins [index,middle,ring,pinky]
PIN_SHOW_THUMB = [1, 1];            // thumb [MCP, PIP]
PIN_SHOW_WRIST = [1, 1];            // wrist [pinky-side, thumb-side]
PIN_OFF_MCP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];
PIN_OFF_PIP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];
PIN_OFF_THUMB  = [[0,0,0], [0,0,-0.5]]; // zero = pins exactly on the thumb part hole axes (MCP & PIP)
PIN_OFF_WRIST  = [[-2,1,0], [2,1,0]];
// Extra rotation per pin [x,y,z] deg, applied AFTER the offset — the pin rotates
// about its own seat point, in the local axes of the part it sits in. The pin
// body lies along local X, so Z swings it in-plane, Y tilts its axis, and X
// rolls it about itself (head orientation, e.g. the MCP rectangular head).
PIN_ROT_MCP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];  // knuckle pins    [index,middle,ring,pinky]
PIN_ROT_PIP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];  // mid-finger pins [index,middle,ring,pinky]
PIN_ROT_THUMB  = [[0,0,0], [0,0,0]];                    // thumb [MCP, PIP]
PIN_ROT_WRIST  = [[0,0,0], [0,0,0]];                    // wrist [pinky-side, thumb-side] (world axes)

// ── TENSIONER MECHANISM & WASHERS (real reconstructed parts) ────────────────
WASHER_SHOW    = [1, 1];             // cup washers on the two wrist pins [pinky, thumb]
// Washers sit FLAT on the gauntlet's wrist holes (the gauntlet previews flat —
// it thermoforms around the arm — so its wrist holes run through Z). Each bore
// is concentric with its hole: hole centres measured at (31.86,-151)/(92.14,-151),
// boss top z=5.8. Flat base down against the plate, cup up to receive the pin head.
WASHER_POS     = [[23.86, -141, 7.8], [85.14, -141, 7.8]];  // one per gauntlet wrist hole (world)
WASHER_ROT     = [[0,-90,0], [0,90,0]];  // per-washer; bore along Z, concentric with the gauntlet hole
TBLOCK_SHOW    = 1;                  // tensioner block (stadium housing)
TBLOCK_POS     = [55, -220, 10];      // world seat; more -y = further out toward the wrist
TBLOCK_ROT     = [-90, 0, 0];        // stand the tower dorsally, length along the forearm
TPINS_SHOW     = 1;                  // three flat tensioner pins
TPINS_POS      = [55, -200, 7.5];     // world seat near the wrist
TPINS_ROT      = [0, 0, 180];          // flat, long axis along the forearm (Y)

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

// ── PER-FINGER LENGTH ───────────────────────────────────────────────────────
// The Phoenix meshes are fixed, but we can lengthen a finger WITHOUT distorting
// its pin holes: split the column at Y=[ylo,yhi], keep the yhi (hinge) end put,
// stretch only the hole-free shaft band, and shift the far end out by d mm. The
// pin-hole zones never scale, so the holes stay perfectly round and printable.
// FLEN/FBASE come from the injectable *_finger_length_mm / *_base_length_mm params
// (defined by the includer); REF_* are the native mesh lengths at which d = 0.
REF_PROX = 31;  REF_DIST = 41;     // native proximal (MCP->PIP) / distal (PIP->tip), mm
// index..pinky + thumb (col 4 shares the finger part geometry, so the same REF applies)
FLEN  = [index_finger_length_mm, middle_finger_length_mm, ring_finger_length_mm, pinky_finger_length_mm, thumb_length_mm];
FBASE = [index_base_length_mm,   middle_base_length_mm,   ring_base_length_mm,   pinky_base_length_mm,   thumb_base_length_mm];
function bd_of(i) = FBASE[i] - REF_PROX;                 // proximal (base) extra length, mm
function td_of(i) = (FLEN[i] - FBASE[i]) - REF_DIST;     // distal (tip)   extra length, mm

// keep everything at/above yhi fixed; grow the shaft band [ylo,yhi]; push the
// sub-ylo part out by d (toward -Y). d may be negative (shorter).
module stretch_shaft(ylo, yhi, d){
    intersection(){ children(); translate([-60,yhi,-30]) cube([160,400,60]); }               // hinge end (fixed)
    translate([0,yhi,0]) scale([1,(yhi-ylo+d)/(yhi-ylo),1]) translate([0,-yhi,0])             // shaft band (grown)
      intersection(){ children(); translate([-60,ylo,-30]) cube([160,yhi-ylo,60]); }
    translate([0,-d,0]) intersection(){ children(); translate([-60,ylo-400,-30]) cube([160,400,60]); }  // far end (shifted)
}
// proximal column: MCP end (native Y~48) fixed, PIP end (native Y~17) pushed out by bd
module ph_col_s(i, bd){ stretch_shaft(20, 42, bd) ph_col(i); }
// distal column: fork/PIP end (native Y~-9) fixed, tip end (native Y~-52) pushed out by td
module fn_col_s(i, td){ stretch_shaft(-48, -14, td) fn_col(i); }

// canonical finger: MCP pin at origin, extends +Y, palmar/curl down (-Z), dorsal up (+Z).
module finger_unit(i, fcol, doff=[0,-3.9,0.7], drot=[0,0,0], bd=0, td=0){
    color(fcol){
      // proximal — flipped 180° about its long axis at the pin line so the fork fins point UP,
      // keeping both pin holes on the axis and the tall knuckle at the MCP/palm end.
      // MCP stays seated; ph_col_s adds bd mm toward the PIP so the finger grows outward.
      translate([0,0,PROX_PIN_Z]) rotate([0,180,0]) translate([0,0,-PROX_PIN_Z])
        rotate([180,0,0]) translate([-PH_XC[i], -PH_KNUCKLE_Y, -PH_KNUCKLE_Z]) ph_col_s(i, bd);
      // fingertip — shifted out by bd (follows the lengthened proximal's PIP), then offset by
      // doff, rotated by drot about the PIP joint; fn_col_s adds td mm toward the tip.
      translate([0,bd,0])
        translate([0,PIP_HOLE_Y,PROX_PIN_Z]) rotate(drot) translate([0,-PIP_HOLE_Y,-PROX_PIN_Z])
          translate(doff)
            rotate([180,0,0]) translate([-FN_XC[i], PH_DISTAL_Y-PH_KNUCKLE_Y-FN_FORK_Y, PH_DISTAL_Z-PH_KNUCKLE_Z-FN_FORK_Z]) fn_col_s(i, td);
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
          finger_unit(COLMAP[f], FCOL[f], DIST[f], DROT[f], bd_of(f), td_of(f));

    if(show_thumb) translate(TH_POS) rotate(TH_ROT) finger_unit(4, TH_COL, TH_DIST, TH_DROT, bd_of(4), td_of(4));  // thumb

    if(show_pins){
      for(f=[0:3])                                                        // finger pins
        translate([KX[f]+DX,KY[f]+DY,KZ[f]]) rotate([0,0,SPLAY[f]]) rotate([CURL,0,0]){
          if(PIN_SHOW_MCP[f]) translate([0,MCP_HOLE_Y,PROX_PIN_Z]+PIN_OFF_MCP[f]) rotate(PIN_ROT_MCP[f]) pin(PIN_FLIP_MCP[f]);
          if(PIN_SHOW_PIP[f]) translate([0,PIP_HOLE_Y+bd_of(f),PROX_PIN_Z]+PIN_OFF_PIP[f]) rotate(PIN_ROT_PIP[f]) pin(PIN_FLIP_PIP[f]); }
      translate(TH_POS) rotate(TH_ROT){                                  // thumb pins
          if(PIN_SHOW_THUMB[0]) translate([0,MCP_HOLE_Y,PROX_PIN_Z]+PIN_OFF_THUMB[0]) rotate(PIN_ROT_THUMB[0]) pin(PIN_FLIP_THUMB[0]);
          if(PIN_SHOW_THUMB[1]) translate([0,PIP_HOLE_Y+bd_of(4),PROX_PIN_Z]+PIN_OFF_THUMB[1]) rotate(PIN_ROT_THUMB[1]) pin(PIN_FLIP_THUMB[1]); }
      if(PIN_SHOW_WRIST[0]) translate(WRIST_PIN_A+PIN_OFF_WRIST[0]) rotate(PIN_ROT_WRIST[0]) wpin(PIN_FLIP_WRIST[0]);   // wrist pins
      if(PIN_SHOW_WRIST[1]) translate(WRIST_PIN_B+PIN_OFF_WRIST[1]) rotate(PIN_ROT_WRIST[1]) wpin(PIN_FLIP_WRIST[1]);
    }

    if(show_gauntlet) color(GAUNT_COL) translate(GAUNT_POS) rotate(GAUNT_ROT) Gauntlet_V4();  // arm guard

    if(show_washers){                                                     // wrist-pin cup washers, flats facing each other
      if(WASHER_SHOW[0]) color(WASHER_COL) translate(WASHER_POS[0]) rotate(WASHER_ROT[0]) washer_centered();
      if(WASHER_SHOW[1]) color(WASHER_COL) translate(WASHER_POS[1]) rotate(WASHER_ROT[1]) washer_centered();
    }

    if(show_tensioner){                                                   // tensioner mechanism
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
    // fingers laid out per-column at their CUSTOM lengths (stretched shafts, holes intact),
    // so the exported STL matches the assembled preview. Proximals row + distals row.
    if(show_fingers)
      for(f=[0:3]){
        color(FCOL[f]) translate([120+f*24,  0, 0]) translate([-PH_XC[f],0,0]) ph_col_s(f, bd_of(f));
        color(FCOL[f]) translate([120+f*24, 70, 0]) translate([-FN_XC[f],0,0]) fn_col_s(f, td_of(f));
      }
    if(show_thumb){
        color(TH_COL) translate([120+4*24,  0, 0]) translate([-PH_XC[4],0,0]) ph_col_s(4, bd_of(4));
        color(TH_COL) translate([120+4*24, 70, 0]) translate([-FN_XC[4],0,0]) fn_col_s(4, td_of(4));
    }
    if(show_pins)     color(PIN_COL)    translate([215, -40, 0]) Phoenix_Pins();
    if(show_gauntlet) color(GAUNT_COL)  translate([-10, 60, 0]) rotate([90,0,0]) Gauntlet_V4();
    if(show_tensioner){ color(TBLOCK_COL) translate([230, -40, 0]) tensioner_block_centered();
                        color(TPINS_COL)  translate([270, -40, 0]) tensioner_pins_centered(); }
    if(show_washers)    color(WASHER_COL){ translate([297, -40, 0]) washer_centered();
                                           translate([315, -40, 0]) washer_centered(); }
}

// Dispatcher: assembled seated preview or the flat print-bed layout.
module phoenix_render(){ if(print_layout) phoenix_printlayout(); else phoenix_assembly(); }
