// ============================================================================
//  PEC PHOENIX HAND — assembled view, V2: the IoU-reworked phalanges
//  (Proximals_v2 0.965 / Distals_v3 0.964-0.972, fingerator-idiom sections).
//  Same seats/tunables as _assembly.scad, which keeps the original phalanges.
//  Render:  openscad _assembly_v2.scad     (or open in the OpenSCAD GUI / F5)
//
//  Pulls each parametric part in with `use<>` and seats it on its MEASURED
//  mating feature (palm finger rings, thumb bore, wrist ears). Every knob you
//  adjust lives in the TUNABLES block below — the MOUNTS block underneath holds
//  the measured hole positions read out of the part files (leave those alone).
//
//  COORDINATE FRAME (palm-native, millimetres — same as the palm part):
//     +X = toward the THUMB / index side     (-X = pinky side)
//     +Y = toward the FINGERTIPS             (-Y = wrist / forearm)
//     +Z = DORSAL (back of hand)             (-Z = palmar / grip)
//
//  Fingers are index, middle, ring, pinky (array order 0..3). Thumb is separate.
//  NOTE: three of the parts (palm, distals, thumb-mount) pull in BOSL2 and the
//  palm/rings/thumb clip to a local ghost STL — so this renders in the desktop
//  OpenSCAD here, but is NOT yet browser-WASM portable (that's the next phase).
// ============================================================================
// The proximal/distal/gauntlet parts import cleanly with `use<>` (namespaced),
// but the PALM's modules depend on file-global variables and a ghost STL that a
// bare `use` does not carry into the module closures — under `use` the palm
// renders empty. So the palm is `include`d LAST (full top-level context, and its
// model()/ghost_stl win the name over the used files). BOSL2's $-special-var
// defaults come in through the palm's own `include <BOSL2/std.scad>` (hoisted to
// global scope), so the used parts' cuboid()/skin() calls resolve too.
use <Proximals_v2.scad>     // proximal()   : one proximal phalanx (fingerator-idiom rework, IoU 0.965)
use <Distals_v3.scad>       // distal_std/short/thumb() : the fingertips (egg sections, IoU 0.96+)
use <arm-guard-v13.scad>    // arm_guard()  : the forearm gauntlet
use <phoenix_snap_pins.scad>  // real Phoenix snap/clip pins + cup washer (STEP reconstruction)
no_assembly = true;         // suppress the palm's own standalone render on include
include <Palm_left_V2.scad> // model()      : the whole parametric palm (+ BOSL2)

$fn = 48;

// Proximals.scad drives its optional wide piece-0 body off the special vars
// $wscale / $wide. Those default at that file's top level, which a bare `use`
// does not run — so set the standard-piece defaults here (special vars are
// dynamically scoped, so proximal() picks them up). Silences the undef warnings.
$wscale = 1;
$wide   = false;

// ============================================================================
//  TUNABLES  — everything you adjust lives here
// ============================================================================

// ── FINGERS — index, middle, ring, pinky (array order) ─────────────────────
// Each proximal is seated with its MCP (palm-end) hole on the matching palm
// finger-ring pin. KX/KY are that pin in palm coordinates; leave them on the
// measured MOUNT_* values below unless a finger needs nudging.
KX    = [13.4, -0.65, -14.75, -28.75];   // per-finger MCP pin X (measured ring gaps)
KY    = [40,   40,    36,     30];        // per-finger MCP pin Y (measured ring cy)
SPLAY = [0, 0, 0, 0];                     // per-finger fan angle about the MCP (deg, +Z)
FLEX  = [0, 0, 0, 0];                     // per-finger curl of the WHOLE finger about the MCP (deg, +=grip)
DX    = 0;  DY = 0;                       // nudge ALL fingers together (+X thumb-ward, +Y tipward)
// which distal size each finger gets: "std" | "short" | "thumb"
DSIZE = ["std", "std", "short", "short"]; // index, middle, ring, pinky
// DISTAL (fingertip) — full independent control per finger, all applied ABOUT
// THE PIP JOINT (the fork↔proximal pivot), so the fork stays put and the tip swings.
//   DIST_OFF = position nudge [x,y,z] mm  (+x thumb-ward, +y tipward, +z dorsal/up)
//   DIST_ROT = rotation [x,y,z] deg:  x = TILT/flex (curl toward grip)
//                                     y = ROLL  (use 180 to flip an inverted tip)
//                                     z = YAW   (swing sideways)
DIST_OFF = [[0,0,0],   [0,0,0],   [0,0,0],   [0,0,0]];     // index, middle, ring, pinky
DIST_ROT = [[10,180,0], [10,180,0], [10,180,0], [10,180,0]];   // y=180 un-inverts the tip (curls toward grip)

// ── THUMB (proximal + thumb distal on the +X thumb boss) ───────────────────
TH_POS = [33.5, -6.6, 5.8];    // seat = measured thumb pivot bore centre
// TH_ROT orients the whole thumb about its MCP [x-tilt, y-tilt, z-yaw]; TH_ROLL then
// spins the thumb about ITS OWN long axis (like the unlimbed proximal's 180° fin-up
// flip) so its clip fins face dorsal and continue the palm thumb-mount fin
// (mount fin at (34,-7.5,12.5), tilt45/yaw-40). Tune TH_ROLL first for the fins, then
// TH_ROT for where the thumb points.
TH_ROT  = [-40, 0, -130];
TH_ROLL = 0;                   // roll about the thumb's own long axis (deg)
TH_FLEX = 0;                    // curl the whole thumb about its MCP (deg)
TH_DIST_OFF = [0, 0, 0];       // thumb distal position nudge [x,y,z] mm (about the PIP)
TH_DIST_ROT = [0, -180, 0];     // thumb distal rotation [tilt, roll, yaw] deg; y=180 un-inverts the tip

// ── ARM GUARD (gauntlet) — placed BY ITS HINGE so move + rotate are independent ─
// GAUNT_POS = where the gauntlet's boss/hinge centre sits (default = the palm's
// wrist-ear centre). GAUNT_ROT = tilt the forearm ABOUT that hinge, so changing the
// angle never slides the hinge off the ears. GAUNT_HINGE_LOCAL (in MOUNTS) is the
// boss centre in the gauntlet's own frame; leave it be.
//   GAUNT_POS = [x, y, z]  — +x thumb-ward, +y tipward, +z dorsal/up
//   GAUNT_ROT = [x, y, z]  — x = cuff-tilt (lift the forearm), y = roll, z = yaw/flip(180)
GAUNT_POS = [-7.75, -38, 8];   // hinge target = measured wrist-ear centre
GAUNT_ROT = [0, 0, 0];       // 180 flips it to run down the forearm (-Y); raise x to cuff it up

// ── PINS — REAL Phoenix snap pins (phoenix_snap_pins.scad, STEP reconstruction) ─
// Finger/thumb joints take the small snap pin (body_1, ~Ø4); the wrist ears take
// the larger clip pin (body_0, ~Ø5) with its countersunk cup washer (body_9).
// These are fixed-size measured parts, so there are no length/Ø knobs any more —
// if a head lands on the wrong side, flip that pin instead.
PIN_COL        = "#3b3b6d";
// show / hide each pin (1 = show, 0 = hide)
PIN_SHOW_MCP   = [1, 1, 1, 1];   // knuckle pins    [index, middle, ring, pinky]
PIN_SHOW_PIP   = [1, 1, 1, 1];   // mid-finger pins [index, middle, ring, pinky]
PIN_SHOW_THUMB = [1, 1];         // thumb [MCP, PIP]
PIN_SHOW_WRIST = [1, 1];         // wrist [thumb-side, pinky-side]
SHOW_WASHERS   = true;           // cup washers on the wrist pins
// head side per pin along the joint axis (0 = head at +X, 1 = head at -X)
PIN_FLIP_MCP   = [0, 0, 0, 0];
PIN_FLIP_PIP   = [0, 0, 0, 0];
PIN_FLIP_THUMB = [0, 0];
PIN_FLIP_WRIST = [0, 1];         // heads face outward on each side of the wrist
// nudge each pin off its joint [x,y,z] (finger/thumb: local finger frame; wrist: world)
PIN_OFF_MCP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];
PIN_OFF_PIP    = [[0,0,0], [0,0,0], [0,0,0], [0,0,0]];
PIN_OFF_THUMB  = [[0,0,0], [0,0,0]];
PIN_OFF_WRIST  = [[0,0,0], [0,0,0]];

// ── VISIBILITY ─────────────────────────────────────────────────────────────
SHOW_PALM   = true;
SHOW_FINGERS= [true, true, true, true];   // index, middle, ring, pinky
SHOW_THUMB  = true;
SHOW_GAUNT  = true;

// ── COLOURS ────────────────────────────────────────────────────────────────
PALM_COL  = [0.95, 0.85, 0.20];   // palm (the parts' own internal colours show through where set)
DISTAL_COL= ["#4a9eff", "#ff6b6b", "#51cf66", "#ffd43b"];  // index, middle, ring, pinky tips
TH_DISTAL_COL = "#cc5de8";
GAUNT_COL = "#c0c0c8";

// ============================================================================
//  MOUNTS  — measured hole positions from the part files (leave these alone)
// ============================================================================
PROX_MCP_Y = -11.78;   PROX_MCP_Z = 6.0;    // proximal palm-end (rear) knuckle hole
PROX_PIP_Y =  11.25;   PROX_PIP_Z = 6.0;    // proximal distal-end (front) knuckle hole
PROX_SPAN  = PROX_PIP_Y - PROX_MCP_Y;       // 23.03 mm MCP->PIP along the proximal
DIST_PIP_Y = 6.20;                          // distal fork hole Y from its heel (constant)
function dist_pin_z(sz) = sz=="thumb" ? 6.90 : sz=="short" ? 6.30 : 6.65;  // distal fork hole Z
MCP_Z = 6.0;                                // palm ring pin height (CZ in the rings file)
WRIST_PIN_A = [ 20.5, -38, 8];              // thumb-side wrist ear (X=20.5, measured)
WRIST_PIN_B = [-36.0, -38, 8];              // pinky-side wrist ear (X=-36, measured)
GAUNT_HINGE_LOCAL = [0, 79.005, 1.9];       // gauntlet boss/hinge centre in its OWN frame (measured)

// ============================================================================
//  MODULES
// ============================================================================
// pick a distal by size name
module distal(sz){
    if      (sz=="thumb") distal_thumb();
    else if (sz=="short") distal_short();
    else                  distal_std();
}

// Canonical digit frame: MCP hole at the ORIGIN, finger extends +Y, fins dorsal
// (+Z), flat bottom at Z=-PROX_MCP_Z. `rot` orients the whole digit about the MCP.
// The distal is nudged by `doff` and rotated by `drot` — both applied ABOUT THE
// PIP joint (the fork↔proximal pivot); `sz` picks the fingertip size.
module place_digit(pin, rot, sz, doff, drot, tipcol, roll=0){
    // rot orients the digit about the MCP; rotate([0,roll,0]) (innermost) first spins
    // the whole digit about its own long axis (+Y) — the MCP hole sits on that axis so
    // it stays put. Used for the thumb's fin-up roll (fingers pass roll=0).
    translate(pin) rotate(rot) rotate([0, roll, 0]){
        // proximal — MCP hole (0,PROX_MCP_Y,PROX_MCP_Z) shifted to the origin.
        // keeps its own part colours (green MCP knuckle / orange PIP knuckle / fins).
        translate([0, -PROX_MCP_Y, -PROX_MCP_Z]) proximal();
        // distal — fork hole (0,DIST_PIP_Y,pin_z) meets the proximal PIP at
        // (0,PROX_SPAN,0); doff nudges it and drot rotates it about that PIP point.
        color(tipcol)
            translate([0, PROX_SPAN, 0] + doff) rotate(drot)
                translate([0, -DIST_PIP_Y, -dist_pin_z(sz)]) distal(sz);
    }
}

// Real Phoenix pins, lying along the LOCAL X axis (the joint axis), centred on
// the hole. The *_centered() helpers from phoenix_snap_pins.scad put the pin
// axis on +Z with the head at +Z; rotate that onto ±X (flip picks the head side).
// Drop one at a joint that is already in the finger's placed frame.
module snap_pin_x(flip=0){ color(PIN_COL) rotate([0, flip?-90:90, 0]) finger_pin_centered(); }
module clip_pin_x(flip=0){ color(PIN_COL) rotate([0, flip?-90:90, 0]) wrist_pin_centered(); }
// Countersunk cup washer (body_9) for the wrist pins — bore along the X pin axis.
module wrist_washer(){
    color("#2f9e44") rotate([0,90,0]) washer_centered();
}

// ============================================================================
//  ASSEMBLY
// ============================================================================
if (SHOW_PALM) model();   // palm colours itself per part ([Colors] group in Palm_left_V2.scad)

for (f = [0:3]) if (SHOW_FINGERS[f])                            // four fingers
    place_digit([KX[f]+DX, KY[f]+DY, MCP_Z], [FLEX[f], 0, SPLAY[f]],
                DSIZE[f], DIST_OFF[f], DIST_ROT[f], DISTAL_COL[f]);

if (SHOW_THUMB)                                                 // thumb
    place_digit(TH_POS, [TH_ROT[0]+TH_FLEX, TH_ROT[1], TH_ROT[2]],
                "thumb", TH_DIST_OFF, TH_DIST_ROT, TH_DISTAL_COL, TH_ROLL);

if (SHOW_GAUNT) color(GAUNT_COL)                               // forearm gauntlet
    translate(GAUNT_POS) rotate(GAUNT_ROT)                     // rotate about the hinge...
        translate(-GAUNT_HINGE_LOCAL) arm_guard();            // ...by seating the boss centre first

// ---- HINGE PINS — same placed frame as each digit, so they sit in the holes ----
for (f = [0:3]) if (SHOW_FINGERS[f])                            // finger MCP + PIP pins
    translate([KX[f]+DX, KY[f]+DY, MCP_Z]) rotate([FLEX[f], 0, SPLAY[f]]) {
        if (PIN_SHOW_MCP[f]) translate(PIN_OFF_MCP[f]) snap_pin_x(PIN_FLIP_MCP[f]);
        if (PIN_SHOW_PIP[f]) translate([0,PROX_SPAN,0]+PIN_OFF_PIP[f]) snap_pin_x(PIN_FLIP_PIP[f]);
    }

if (SHOW_THUMB)                                                 // thumb MCP + PIP pins
    translate(TH_POS) rotate([TH_ROT[0]+TH_FLEX, TH_ROT[1], TH_ROT[2]]) rotate([0,TH_ROLL,0]) {
        if (PIN_SHOW_THUMB[0]) translate(PIN_OFF_THUMB[0]) snap_pin_x(PIN_FLIP_THUMB[0]);
        if (PIN_SHOW_THUMB[1]) translate([0,PROX_SPAN,0]+PIN_OFF_THUMB[1]) snap_pin_x(PIN_FLIP_THUMB[1]);
    }

if (PIN_SHOW_WRIST[0]) translate(WRIST_PIN_A+PIN_OFF_WRIST[0]) {   // wrist hinge pins + washers
    clip_pin_x(PIN_FLIP_WRIST[0]); if (SHOW_WASHERS) wrist_washer(); }
if (PIN_SHOW_WRIST[1]) translate(WRIST_PIN_B+PIN_OFF_WRIST[1]) {
    clip_pin_x(PIN_FLIP_WRIST[1]); if (SHOW_WASHERS) wrist_washer(); }
