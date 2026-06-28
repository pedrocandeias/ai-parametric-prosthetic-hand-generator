# Flexy Beast — Integration Notes

This document explains how the Flexy Beast prosthetic hand design was integrated into the AI Parametric Prosthetic Hand Generator platform. It covers the source design, what was built, the anthropometric parameter mapping, and the conversion decisions made.

---

## 1. Source Design

The **Flexy Beast** is a wrist-powered prosthetic hand for the [e-NABLE Project](http://enablingthefuture.org), designed by [daprice](https://github.com/daprice/Flexy-Beast) and released under CC BY-SA 4.0. It is a mashup of the [Parametric Cyborg Beast](http://www.thingiverse.com/thing:320173) (MakerBlock) and the [Flexy Hand](http://www.thingiverse.com/thing:380665) (Steve Wood / Gyrobot).

Its key contribution over the Cyborg Beast is replacing Chicago screws and elastics with **flexible joints** (Filaflex inserts or cast silicone) that snap into slots cut into the knuckle blocks. This makes the hand lighter, cheaper, and easier to assemble. Optional silicone finger-pad hollows in the fingertips improve grip.

### Source files

The upstream [Flexy Beast repository](https://www.thingiverse.com/thing:380665) (by daprice) has the following structure:

```
src/
  config.scad                   — sizing variables and scale factors
  assembly.scad                 — hand layout (calls top-level modules)
  parts/
    palm.scad                   — palm body, knuckle blocks, wrist hinges
    thumb_tip.scad              — distal thumb phalanx
    finger_tip_mold.scad        — mold for casting silicone finger pads
    util/
      finger_base.scad          — proximal finger segment module
      finger_mid.scad           — middle finger segment module
      finger_tip.scad           — distal finger segment modules
      thermoform.scad           — thermoformable mesh for palm interior
stl/                            — pre-rendered STL exports (not used)
```

All geometry in `src/` is native OpenSCAD — no STL imports anywhere in the source tree.

---

## 2. Approach: Self-Contained Single File

The upstream source is split across seven SCAD files. Each non-assembly file begins with `include <path/to/config.scad>` to pull in the sizing variables, and each file also has a top-level geometry call (so it renders as a stand-alone part in OpenSCAD's customizer). This structure creates two problems for integration:

1. **Include path collision.** The WASM virtual filesystem is flat — all files end up at the root with no subdirectory structure. The relative `include <../../config.scad>` paths inside `src/parts/util/` would be unresolvable.

2. **Top-level calls.** Each source file renders geometry at the top level, so `use<>`ing them from a master file would silently inherit unwanted top-level renders.

Rather than patching all include paths and stripping all top-level calls across seven files, all geometry was consolidated into a **single self-contained file**:

```
models/active/flexy_beast/flexy_beast.scad
```

This file has no external dependencies and requires no entries in the `"dependencies"` array of `models-config.json`.

---

## 3. What Was Built

`flexy_beast.scad` inlines all module definitions from the upstream source files in the following order:

| Upstream file | Modules inlined |
|---|---|
| `assembly.scad` | `handlayout`, `fingerlayout`, `thumbmid` |
| `parts/palm.scad` | `cyborgbeastpalm`, `cyborgthumbsolid`, `cyborgbeast07palminsidespace`, `hardwarecutouts`, `knuckleblock`, `cyborgbeast07palm` |
| `parts/util/finger_base.scad` | `fingerbase`, `fingerhardwarecutouts`, `fingerbasesolid` |
| `parts/util/finger_mid.scad` | `fingermid` |
| `parts/util/finger_tip.scad` | `fingertip_curved_solid`, `fingertip_solid`, `fingertip_pad`, `fingertip` |
| `parts/thumb_tip.scad` | `thumbtip` |
| `parts/util/thermoform.scad` | `thermoform_mesh` |

`finger_tip_mold.scad` (the silicone casting mold) is not inlined — it is a separate print utility, not part of the hand assembly.

The top-level call is:

```openscad
mirror([mirrored ? 1 : 0, 0, 0])
    handlayout();
```

---

## 4. Conversion Patches

### 4.1 `fingerlayout` parameter-name bug

In the upstream `assembly.scad`, the assembly module passes a named argument `lengthMult` that does not match the module signature:

```openscad
// upstream — module signature and call site disagree
module fingerlayout(length=0) {
    fingertip_curved_solid(length = 17*lengthMult*fingerLength, ...);
    fingerbase(length = 20*lengthMult*fingerLength);
}

fingerlayout(lengthMult=indexProp*fingerLength);  // named arg ignored
```

In OpenSCAD, named arguments that do not match a parameter name are silently ignored. Inside the module body, `lengthMult` would resolve to an undefined variable (effectively `undef`), so the `length` expressions involving it would also be `undef`. The geometry still renders because OpenSCAD degrades gracefully on `undef` arithmetic, but all fingers are rendered at the same default size regardless of the `indexProp` / `ringProp` / `pinkyProp` values.

The fix renames the parameter to match what the body uses:

```openscad
// fixed
module fingerlayout(lengthMult = 1) {
    fingertip_curved_solid(length = 17*lengthMult, ...);
    fingerbase(length = 20*lengthMult);
}
```

Note that `fingerLength` is also removed from inside the expressions — it had been applied twice (once in the call site, once inside), which compounded the scaling. With the fix, the call site passes the already-multiplied value:

```openscad
fingerlayout(indexProp * fingerLength);
```

### 4.2 Deprecated `assign` construct

The upstream `fingertip_pad` module uses `assign($fn=16)` to temporarily override `$fn` for smoother cylinders:

```openscad
assign($fn=16) difference() { ... }   // assign removed in OpenSCAD 2019
```

Modern OpenSCAD (2019+) silently ignores unknown module calls, so `assign` is treated as a no-op. The `$fn` override is lost, but the geometry still renders. The conversion replaces `assign($fn=16) difference()` with a plain `difference()`. The affected cylinders are small silicone-pad attachment features where the resolution difference is not meaningful.

### 4.3 Stray `pad` named argument

Inside `fingertip_pad`, a call to `fingertip()` included `pad=false`:

```openscad
fingertip(length, pad=false, proximalHole=false, cutout=false);
```

The `fingertip` module does not declare a `pad` parameter, so the argument is silently ignored. The conversion removes it to eliminate the OpenSCAD customizer warning.

---

## 5. Anthropometric Parameter Mapping

### Scale factor derivation

The Flexy Beast inherits the Cyborg Beast sizing guide:

> Measure the knuckle width of the non-affected hand in mm. Add 5, then divide by 55.

In the upstream `config.scad`, the user sets `xScaleFactor`, `yScaleFactor`, and `zScaleFactor` manually to that computed value. In the platform integration, `palm_breadth_mm` is the input and the scale is derived automatically:

```openscad
xScaleFactor = (palm_breadth_mm + 5) / 55;
yScaleFactor = xScaleFactor;
zScaleFactor = xScaleFactor;
```

At the default `palm_breadth_mm = 83`, the scale is `(83 + 5) / 55 = 1.6`. The upstream defaults were 1.5 (x, y) and 1.6 (z); the platform uses a single isotropic scale because non-uniform scaling of the palm body distorts the cylindrical string-channel geometry.

The reference point for the formula is the **unscaled palm geometry**: the four finger positions in `hardwarecutouts` are at `i*7` for `i = [-3, -1, 1, 3]`, giving a knuckle span of 42 mm plus half a knuckle width on each side (`knuckleW/2 = 4.75` mm), for an unscaled total of ~51.5 mm. Multiplied by `xScaleFactor = 1.6`, this gives ~82.4 mm — approximately matching `palm_breadth_mm = 83`. The `+5` padding in the formula accounts for clearance so the user's hand fits inside the palm socket.

### Finger length derivation

The upstream model has a global `fingerLength` multiplier that scales all finger segments uniformly. At `fingerLength = 1` and `xScaleFactor = s`, each finger's total reach is:

```
fingerbase (length = 20) × yScaleFactor   +   fingertip_curved (length = 17) × yScaleFactor
= (20 + 17) × s
= 37s mm
```

This is an **internal design reference** — the reach of the printed part from the knuckle pin to the tip — not the anatomical MCP-to-tip length. At the default scale (`s = 1.6`), the internal reach is `37 × 1.6 = 59.2 mm`.

The anatomical middle finger is significantly longer than the printed part's reach because the proximal phalanx (MCP to PIP, roughly 35–40 mm) is represented by the palm-to-knuckle geometry, not the detachable finger part. The detachable finger covers only the distal two segments.

Rather than defining a separate REF constant, the mapping uses the derived scale directly:

```openscad
REF_FINGER_MM = 37;
fingerLength = middle_finger_length_mm / (REF_FINGER_MM * xScaleFactor);
```

At default values (`middle_finger_length_mm = 72`, `xScaleFactor = 1.6`): `fingerLength = 72 / 59.2 = 1.216`. This slightly extends the finger parts beyond the default Flexy Beast length, which is consistent with targeting a clinically measured anatomical length.

Clinicians should understand that `middle_finger_length_mm` drives the **distal two segments** of the finger part. The full MCP-to-tip anatomical length is still the correct input — the model uses it as a relative reference, not an absolute geometric target.

### Per-finger proportions

The upstream model has per-finger proportion variables (`indexProp`, `ringProp`, `pinkyProp`, `thumbProp`) relative to the middle finger (`middleProp = 1`). In the platform integration these are derived from the canonical per-finger length inputs:

```openscad
indexProp  = index_finger_length_mm  / middle_finger_length_mm;
ringProp   = ring_finger_length_mm   / middle_finger_length_mm;
pinkyProp  = pinky_finger_length_mm  / middle_finger_length_mm;
thumbProp  = thumb_length_mm         / middle_finger_length_mm;
```

This means all four lengths are expressed relative to the middle finger, which is anatomically correct: the middle finger is the longest and the natural reference for inter-finger scaling.

### Parameter table

| Platform parameter | Config variable | Derivation | Active / stored |
|---|---|---|---|
| `palm_breadth_mm` | `xScaleFactor` | `(palm_breadth_mm + 5) / 55` | Active — drives all dimensions uniformly |
| `middle_finger_length_mm` | `fingerLength` | `middle_finger_length_mm / (37 × xScaleFactor)` | Active — drives finger reach for all fingers |
| `index_finger_length_mm` | `indexProp` | `index / middle` | Active — scales index relative to middle |
| `ring_finger_length_mm` | `ringProp` | `ring / middle` | Active — scales ring relative to middle |
| `pinky_finger_length_mm` | `pinkyProp` | `pinky / middle` | Active — scales pinky relative to middle |
| `thumb_length_mm` | `thumbProp` | `thumb / middle` | Active — scales thumb relative to middle |
| `palm_length_mm` | — | Not used | Not mapped — palm must scale isotropically |
| `palm_thickness_mm` | — | Not used | Not mapped — palm must scale isotropically |

`palm_length_mm` and `palm_thickness_mm` are not represented as parameters because the Flexy Beast palm geometry is not designed for independent X/Y/Z scaling: the string channels, joint slots, and knuckle cutouts are routed at angles that assume isotropic scale. Separate length or thickness inputs would distort these features.

### Validation

An end-to-end simulation (real `/edit` flow: AI sizing → STL export, then `trimesh`
measurement of every exported part) confirms the mapping above holds in the produced
geometry. Across child/woman/man/default configs the palm length scales **linearly**
with `palm_breadth_mm` (length / breadth ≈ **1.49–1.52**, constant), and each finger
part scales with its `*_finger_length_mm` input. Sized to the same hand, the part
envelopes also match the daprice 160 % demo STLs to within ~1 % on the palm. Full
prompts, AI-applied parameters and per-part dimensions:
[`docs/flexy-beast-ai-sim/`](flexy-beast-ai-sim/flexy-beast_ai-sizing-dimensional-report_2026-06-28.md).

The same run surfaced (and the platform then fixed, v14.16.0) a grounding-matcher bug
that had been anchoring every patient on a male population profile regardless of the
described sex/age — see `docs/ai_anthropometric_validation.md` §2.4. Flexy Beast is a
consumer of that grounding path, so the fix improves its sizing for women and children.

---

## 6. Hardware Parameters

Two hardware parameters are exposed that have no analogue in the other platform models:

**`joint_dia`** (default 7 mm) — diameter of the cylindrical hole cut into each knuckle block and thumb joint to accept the flexy joint insert. The upstream documentation recommends reducing this to 5 mm for smaller children's hands to prevent the joint from tearing through the printed plastic.

**`joint_thick`** (default 4 mm) — thickness of the slot cut through the top of each knuckle block. This must match the thickness of the flexy joint material being used (Filaflex rod or cast silicone). Reducing to 2 mm is recommended alongside reducing `joint_dia` for small hands.

---

## 7. Finger Pad Hollows

The `finger_pads` parameter (default `true`) controls whether the fingertip modules hollow the dorsal face of each fingertip to accept a cast or printed flexible pad. When `true`, `fingertip_curved_solid` and `thumbtip` call `fingertip_pad()` internally to subtract the hollow shape.

The pad cavity includes two small cylindrical retention pegs and a groove around the perimeter that grip a flexible silicone pad by compression. Pads can be:
- Cast in silicone using `finger_tip_mold.scad` from the upstream source (not included in the platform model — render separately from the upstream files).
- Printed directly in flexible filament using the same mold with `padPositive = true`.

Setting `finger_pads = false` produces solid fingertips suitable for dry-finger use or when pads are not needed.

---

## 8. Thermoform Mesh

The `show_thermoform` parameter (default `true`) renders a perforated mesh inside the palm socket. The mesh is intended to be printed in PLA and then heat-formed directly to the patient's residual limb for a custom fit.

The mesh is generated by `thermoform_mesh()` clipped to the palm interior void (`cyborgbeast07palminsidespace()`). The hole pattern uses 1.75 × 5.5 mm oval cutouts on a staggered grid, leaving enough material for structural integrity while allowing air circulation.

For patients with sensitive skin or where a thermoformed fit is not needed, disabling `show_thermoform` renders a solid palm socket interior.

---

## 9. Attribution

Original design: **Flexy Beast** by daprice, https://github.com/daprice/Flexy-Beast, licensed CC BY-SA 4.0.

Based on:
- Parametric Cyborg Beast by MakerBlock, https://www.thingiverse.com/thing:320173
- Flexy Hand by Steve Wood / Gyrobot, https://www.thingiverse.com/thing:380665
