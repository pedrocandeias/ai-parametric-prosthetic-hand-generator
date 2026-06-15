# Paraglider Hand — Integration Notes

This document explains how the Paraglider / Flexible Flyer prosthetic hand design was integrated into the AI Parametric Prosthetic Hand Generator platform. It covers the source design, what was built, how the anthropometric parameter alignment was achieved, and the trade-offs involved.

---

## 1. Source Design

The **Paraglider Hand** (also called the Flexible Flyer) is an open-source body-powered prosthetic wrist hand designed by Marcus Mendenhall in 2020, released under CC BY-SA 4.0. It is a remix of three established e-NABLE designs: the Phoenix v2, the Unlimbited Phoenix v3, and the Phoenix Reborn.

The design's primary contribution over its predecessors is the use of **commercial metal hardware** — 1/16-inch steel dowel pins, 3 mm screws, or 13-gauge finishing nails — as finger pivot pins, with optional self-lubricating plastic tubing (Delrin or PTFE) inserted as a bearing. Compared to 3D-printed plastic pins, this makes joints significantly smoother and stronger. Hole diameters in both the palm and the finger phalanges are computed parametrically in OpenSCAD to match the selected hardware style, with a configurable clearance to account for individual printer tolerances.

### Source files

| File | Role |
|---|---|
| `fingerator.scad` | Generates all finger parts: long fingertip, short fingertip, finger phalanx, thumb tip, thumb phalanx |
| `paraglider_palm_left.scad` | Generates the palm body by applying CSG operations to an imported Phoenix v2 STL |
| `pipe.scad` | Helper library for routing curved string/elastic channels through the palm |
| `palm_left_v2_nobox.stl` | Repaired Phoenix v2 palm mesh (support box removed in MeshMixer, holes patched) |

`fingerator.scad` is entirely self-contained native OpenSCAD geometry — no imports. `paraglider_palm_left.scad` imports `pipe.scad` and `palm_left_v2_nobox.stl`.

---

## 2. Source File Patches

> **Update (2026-06-15):** the vendored OpenSCAD WASM build has since been upgraded to **2025.03.25**, which fully supports the `each` keyword (added upstream in 2019.05). The `each`→`concat()` rewrites described in §2.1 are therefore **no longer required** — they are retained in the unified `paraglider_hand` copy because they are harmless and already tested, but the variant palms and accessories added later (§12) ship with the **raw upstream `each` usage** and parse correctly. The double-comma fix in §2.2 *is* still required (it is a genuine syntax error rejected by current OpenSCAD).

### 2.1 The `each` keyword in list constructors (historical)

When this model was first integrated, the WASM build of OpenSCAD predated reliable `each` support. OpenSCAD 2019.05 introduced the `each` keyword for splatting a list into a parent list comprehension:

```openscad
// upstream
shape = [[-1.5,-1],[1.5,-1], each 1.5*[for(th=[0:30:179]) [cos(th), sin(th)]]]*shapescale;
```

On that older build the file failed to load — no modules were defined, and `scaled_palm()` became undefined. The original fix replaced `each` with `concat()` (kept in the unified copy):

```openscad
// patched
shape = concat(
    [[-1.5,-1],[1.5,-1]],
    [for(th=[0:30:179]) 1.5*[cos(th), sin(th)]]
)*shapescale;
```

A second instance in the same file used `each` inside a `translate()` call:

```openscad
// upstream
for(xy=holes) translate([each xy, 0.001]) cylinder(...);

// patched
for(xy=holes) translate([xy[0], xy[1], 0.001]) cylinder(...);
```

### 2.2 Double comma in array literal

Line 85 of the upstream file contained a double comma producing an `undef` element:

```openscad
// upstream
[[20.68,-38,8],,[0,90,0]]

// patched
[[20.68,-38,8],[0,90,0]]
```

### 2.3 Patched file location

Rather than modifying the upstream files in `flexible_flyer-master/files/`, patched copies are maintained at:

```
models/active/paraglider_hand/paraglider_palm_left.scad
models/active/paraglider_hand/fingerator.scad
models/active/paraglider_hand/pipe.scad
```

`pipe.scad` uses `each` inside its channel-routing modules; on the current 2025.03.25 WASM build this parses fine, and in any case those modules are bypassed by the `do_channels()` override by default. `fingerator.scad` requires no patches.

The palm base mesh now lives as a **real file** at `models/active/paraglider_hand/palm_left_v2_nobox.stl` (a copy of the repaired Phoenix v2 mesh). The earlier integration used a symlink into a `flexible_flyer-master/` working copy; when that directory was removed the symlink dangled and the `import()` silently produced empty geometry. The model file set is now self-contained.

---

## 3. What Was Built

A master assembly SCAD file was created at:

```
models/active/paraglider_hand/paraglider_hand.scad
```

This file is a **thin parametric wrapper** — it does not reproduce or copy the geometry of the source files. Instead it:

1. Declares the canonical anthropometric parameters and derives scale factors from them.
2. Re-declares every variable that the source file modules reference internally, so that OpenSCAD's dynamic scoping mechanism routes the correct values into those modules at render time.
3. Calls `scaled_palm()` from `paraglider_palm_left.scad` for the palm section.
4. Defines shared finger modules (`_long_finger`, `_short_finger`, `_finger_phalanx`, etc.) that wrap fingerator calls with per-finger scale factors.
5. Renders either an **assembled view** (default) — finger parts positioned at the palm's knuckle pin coordinates — or a **flat print layout** — all parts laid side by side for slicing.

### Module overrides

Two modules from `paraglider_palm_left.scad` are overridden in the wrapper:

**`do_labels()`** — The WASM build has no fontconfig, so `text()` calls produce "Can't get font" warnings and empty geometry. The override passes children through without calling `text()`:

```openscad
module do_labels() { children(); }
```

**`do_channels()`** — The channel CSG (`plug_old_channels`, `reborn_channels` from `pipe.scad`) involves complex swept-tube boolean operations that stress the Manifold backend significantly. The override skips channel routing by default and only applies the structural end-shave cut, dramatically reducing render time. Set `show_channels = true` to enable full channel routing for a print-ready export.

---

## 4. Dynamic Scoping Approach

OpenSCAD's `use<file.scad>` directive imports the modules and functions defined in the file but does not execute top-level code and does not import variable bindings. When an imported module is later called, OpenSCAD resolves variable references using **dynamic scoping**: it walks up the call stack looking for a definition, starting from the calling scope.

This means that if the wrapper defines `overall_scale = 1.35` and then calls `scaled_palm()` (imported from `paraglider_palm_left.scad`), the module will use `overall_scale = 1.35` from the wrapper's scope — overriding the `overall_scale = 1.25` that appears in the original file.

The consequence is that **every variable referenced inside the source modules must be defined in the wrapper**. This includes not only the obvious scalar parameters but also derived arrays and constants:

```openscad
slot_dx = [[[10,0,0],0],[[-4,0,0],0],[[-18,-4,0],0],[[-32,-10,0],0]];
pin_coordinates = [
    [[-35.4,-38,8],[0,90,0]],    // left wrist
    [[20.68,-38,8],[0,90,0]],    // right wrist
    [[6.6,39.5,6.0],[0,90,0]],   // index + middle knuckle
    [[-16,35.5,6.0],[0,90,0]],   // ring knuckle
    [[-29.5,29.5,6.0],[0,90,0]], // pinky knuckle
    [[31,0,6.0],[0,90,50]]       // thumb MCP
];

initial_rotation   = 33.5;
nominal_slotwidth  = 6;
adjusted_tabwidth  = nominal_slotwidth - nominal_clearance / global_scale;
nut_size           = 5.5;
bolt_head_dia      = 5.5 + 0.3;
```

---

## 5. WebAssembly Dependency Management

The platform renders OpenSCAD in the browser using the OpenSCAD WebAssembly runtime. Before rendering, dependency files are loaded into a **flat virtual filesystem** — no subdirectory support. All file references inside SCAD source (`use<>`, `import()`) must use bare filenames with no path components.

The dependency configuration in `models-config.json` uses two path fields per file:

| Field | Meaning |
|---|---|
| `url` | Server path relative to `models/`, used to fetch the file via HTTP |
| `path` | Filename in the WASM virtual filesystem (always flat) |

For the Paraglider Hand:

```json
"dependencies": [
  { "url": "active/paraglider_hand/fingerator.scad",         "path": "fingerator.scad" },
  { "url": "active/paraglider_hand/paraglider_palm_left.scad","path": "paraglider_palm_left.scad" },
  { "url": "active/paraglider_hand/pipe.scad",               "path": "pipe.scad" },
  { "url": "flexible_flyer-master/files/palm_left_v2_nobox.stl","path": "palm_left_v2_nobox.stl" }
]
```

The patched SCAD files are served from `active/paraglider_hand/`; the STL is served from the original upstream location (no patches needed for the STL). All four files land at the virtual filesystem root, matching the bare-filename `use<>` and `import()` calls inside the source files.

---

## 6. Anthropometric Parameter Alignment

The platform's anthropometric pipeline produces patient measurements under canonical names. Model parameters that match these names exactly are auto-populated when a patient profile is loaded:

| Canonical name | Clinical measurement | Active / stored |
|---|---|---|
| `palm_breadth_mm` | Knuckle-to-knuckle metacarpal breadth | Active — drives uniform palm scale |
| `palm_length_mm` | Wrist base to middle MCP crease | Stored — palm must scale uniformly (pin-hole constraint) |
| `palm_thickness_mm` | Palmar to dorsal surface | Stored — palm must scale uniformly (pin-hole constraint) |
| `index_finger_length_mm` | Index MCP crease to tip | Active — drives index tip and phalanx scale |
| `middle_finger_length_mm` | Middle MCP crease to tip | Active — drives middle tip and phalanx scale; sets `global_scale` base |
| `ring_finger_length_mm` | Ring MCP crease to tip | Active — drives ring tip and phalanx scale |
| `pinky_finger_length_mm` | Pinky MCP crease to tip | Active — drives pinky tip and phalanx scale |
| `thumb_length_mm` | Thumb MCP crease to tip | Stored — thumb scales proportionally with finger |

### Scale calibration

```
REF_PALM   = 66.4 mm   →  overall_scale = palm_breadth_mm / 66.4
REF_FINGER = 57.6 mm   →  global_scale  = middle_finger_length_mm / 57.6
```

At default values (83 mm palm, 72 mm middle finger) both scales equal 1.25 — consistent with the original documentation's description of 1.25 as a typical medium adult scale. For non-default measurements the two diverge, correctly reflecting that hand breadth and finger length are independently variable.

### Per-finger scales

Each finger derives its own scale from its anatomical length:

```openscad
index_scale = index_finger_length_mm / 57.6;
ring_scale  = ring_finger_length_mm  / 57.6;
pinky_scale = pinky_finger_length_mm / 57.6;
// middle uses global_scale
```

The fingerator modules (`finger()`, `cut_phalanx()`) use `global_scale` (middle) as their internal base. Per-finger tips and phalanxes apply a uniform correction factor `fscale / global_scale` on top, so the geometry remains consistent with the fingerator's slot and tab geometry at scale:

```openscad
module _long_finger(fscale=global_scale) {
    _sf = fscale / global_scale;
    scale([_sf,_sf,_sf]) adjusted_holes(global_scale, ...) finger(...);
}
module _finger_phalanx(fscale=global_scale) {
    cut_phalanx(..., scale_size=fscale, ...);
}
```

### Why uniform palm scaling is required

Applying non-uniform scale to the palm would turn cylindrical pin bores into ellipses. A metal pin cannot be inserted into an elliptical bore. The palm must therefore scale uniformly. `palm_length_mm` and `palm_thickness_mm` are stored for AI suggestion context but do not alter geometry.

---

## 7. Assembled View and Print Layout

The model supports two render modes controlled by `show_assembled`:

### Assembled view (default, `show_assembled = true`)

Finger parts are positioned at the palm's knuckle pin coordinates from `pin_coordinates[]`, scaled by `overall_scale`. Phalanx proximal pivots are offset `11.8 × global_scale` mm above the knuckle; fingertip joints are a further `12.3 + 20 × global_scale` mm (long) or `+ 18 × global_scale` mm (short) above that. The thumb is rotated 50° around Z from its MCP origin to match the palm's thumb knuckle angle.

This mode is intended for visual inspection and patient communication — it shows the hand as it will look when assembled.

### Print layout (`show_assembled = false`)

All parts are laid flat at Z = 0, side by side, ready for slicing. The layout produces one tip and one phalanx per finger (four fingers + thumb), at their individual scales:

| Position (relative to palm right edge + 65 mm) | Part | Scale |
|---|---|---|
| `_fp + 0` | Index fingertip (long) | `index_scale` |
| `_fp + 25` | Middle fingertip (long) | `global_scale` |
| `_fp + 50` | Ring fingertip (short) | `ring_scale` |
| `_fp + 75` | Pinky fingertip (short) | `pinky_scale` |
| `_fp + 100` | Index phalanx | `index_scale` |
| `_fp + 125` | Middle phalanx | `global_scale` |
| `_fp + 150` | Ring phalanx | `ring_scale` |
| `_fp + 175` | Pinky phalanx | `pinky_scale` |
| `_fp + 205` | Thumb phalanx | `global_scale` |
| `_fp + 235` | Thumb tip | `global_scale` |

All finger parts are rotated 180° around Y (`rotate([0, 180, 0])`) so the finger face (print surface) lies flat on the bed.

---

## 8. Model Parameters

| Parameter | Group | Effect |
|---|---|---|
| `palm_breadth_mm` | Anthropometric | Uniform palm scale |
| `palm_length_mm` | Anthropometric | Stored; informs AI suggestions |
| `palm_thickness_mm` | Anthropometric | Stored; informs AI suggestions |
| `index_finger_length_mm` | Anthropometric | Index tip and phalanx scale |
| `middle_finger_length_mm` | Anthropometric | Middle tip and phalanx scale; global_scale base |
| `ring_finger_length_mm` | Anthropometric | Ring tip and phalanx scale |
| `pinky_finger_length_mm` | Anthropometric | Pinky tip and phalanx scale |
| `thumb_length_mm` | Anthropometric | Stored; thumb scales with finger |
| `mirrored` | Handedness | Flip X for right-hand orientation |
| `pin_index` | Hardware | 0 = 3 mm screws, 1 = 1/16" pins + bearing, 2 = 13ga nails, 3 = 1/16" bare |
| `string_channel_scale` | Palm Channels | String channel diameter relative to hand scale |
| `elastic_channel_scale` | Palm Channels | Elastic channel diameter relative to hand scale |
| `old_style_wrist` | Palm Channels | Use plastic wrist pins instead of M3 screws |
| `show_palm` | Visibility | Show/hide palm body |
| `show_palm_mesh` | Visibility | Show/hide fused palm mesh overlay |
| `show_knuckle_covers` | Visibility | Show/hide smooth knuckle covers |
| `show_long_finger` | Visibility | Show/hide index and middle fingertips |
| `show_short_finger` | Visibility | Show/hide ring and pinky fingertips |
| `show_finger_phalanx` | Visibility | Show/hide all four finger phalanxes |
| `show_thumb` | Visibility | Show/hide thumb tip |
| `show_thumb_phalanx` | Visibility | Show/hide thumb phalanx |
| `show_channels` | Visibility | Enable string/elastic channel routing (slow CSG; keep off for preview) |
| `show_assembled` | Visibility | Assembled view (true, default) or flat print layout (false) |

---

## 9. Comparison with the Kinetic Hand RH60

| Attribute | Kinetic Hand RH60 | Paraglider Hand |
|---|---|---|
| Source format | STEP / SolidWorks | OpenSCAD parametric source |
| Integration method | Polyhedron encoding of 24 parts | Dynamic scoping wrapper + patched local copies |
| Palm geometry | `polyhedron()` — reconstructed mesh | `import()` of repaired STL |
| STL dependencies | None | 1 (palm base mesh) |
| Active anthropometric params | 5 | 5 (`palm_breadth_mm`, 4× finger lengths) |
| Stored-only params | 0 | 3 (`palm_length_mm`, `palm_thickness_mm`, `thumb_length_mm`) |
| Independent finger/palm scale | Yes | Yes (decoupled `overall_scale` / `global_scale`) |
| Per-finger scale | No (all fingers share one scale) | Yes (index, middle, ring, pinky each independent) |
| Render modes | Single layout | Assembled view + print layout |
| Reconstruction effort | High (mesh analysis, polyhedron generation) | Low (variable audit, wrapper authoring, patch) |
| Upstream update path | Re-run reconstruction pipeline | Update patched copies, re-audit variables |

---

## 10. Printing Guide

### Recommended settings (per original design documentation)

- Layer height: 240–320 µm from a 0.4 mm nozzle
- Infill: 30%
- Perimeters / walls: 3
- Supports: none required for the palm arch (flying supports are built in)
- Rafts: none

### Print layout

Switch to print layout (`show_assembled = false`) to get all parts flat on the bed in a single view. The layout includes one of each part per finger — no slicer duplication needed for a complete hand.

| Part | Quantity in layout |
|---|---|
| Index fingertip (long) | 1 |
| Middle fingertip (long) | 1 |
| Ring fingertip (short) | 1 |
| Pinky fingertip (short) | 1 |
| Index phalanx | 1 |
| Middle phalanx | 1 |
| Ring phalanx | 1 |
| Pinky phalanx | 1 |
| Thumb tip | 1 |
| Thumb phalanx | 1 |
| Palm | 1 |

Mirror the palm in the slicer for the right-hand version, or set `mirrored = true` in the model parameters.

---

## 11. Source and Credits

- **Design**: Marcus Mendenhall, 2020, Germantown MD, USA — [GitHub repository](https://github.com/mendenmh/flexible_flyer)
- **Licence**: CC BY-SA 4.0
- **Based on**: Phoenix v2 (Thingiverse 1453190), Unlimbited Phoenix v3 (Thingiverse 1674320), Phoenix Reborn (Thingiverse 2217431)
- **Platform integration**: AI Parametric Prosthetic Hand Generator, v7.7.0, 2026-05-09; re-activated and expanded to the full family in v14.10.0, 2026-06-15

---

## 12. Single-entry consolidation (v14.11.0)

The whole Paraglider system is now exposed as **one** dropdown entry, `Paraglider · Hand`, with the variations as in-model options:

- **`component`** selector — `Hand` (palm + fingers), `Box` (tensioner box), `Gauntlet` (thermo gauntlet), `Arm` (elbow-powered UnLimbited arm).
- **`palm_style`** selector — `Reborn` (v2-derived mesh) or `UnlimbitedV3` (higher-res mesh) for the Hand.

### Why a transpile step

The components are separate `.scad` programs, and the four palm files are near-duplicate forks that share ~20 module names (`scaled_palm`, `do_channels`, `channel`, `mesh`, `plugs`, …). OpenSCAD's `use<>` resolves a module's free variables only against **file-top-level globals** (not the caller's locals — verified empirically), so the components cannot simply be `use`d together. They are instead **namespaced**: `scripts/namespace_scad.py` prefixes every identifier a file *defines* (modules, functions, top-level variables — never built-ins or string literals), wraps the file's top-level geometry into a `PREFIX_main()` module, and (for cross-deps like gauntlet→box or palm→pipe) inlines the dependency's library defs. The dispatcher `paraglider_hand.scad` then `include`s the prefixed bundles and dispatches on `component`/`palm_style`, driving each bundle from the Hand's shared inputs (`palm_breadth_mm`, `mirrored`, `overall_scale`).

### Generated bundles (all under `models/active/paraglider_hand/`)

| Bundle | Source | Prefix | Inlined libs |
|---|---|---|---|
| `pg_v3palm.scad` | `paraglider_palm_unlimbited_v3.scad` | `V3_` | `pipe.scad` |
| `pg_box.scad` | `gripper_box_pieces.scad` | `BOX_` | — |
| `pg_gauntlet.scad` | `thermo_gauntlet.scad` | `GAU_` | `gripper_box_pieces.scad` defs |
| `pg_arm.scad` | `UnLimbited_Arm_paraglider_v2.1.scad` | `ARM_` | — |

Each bundle was verified to render **byte-faithfully** against its standalone source (Box 3246, Gauntlet 2230, Arm/Cuff 10686 facets — exact matches), and the assembled dispatcher renders all five paths (Hand/Reborn, Hand/v3, Box, Gauntlet, Arm) with zero scoping warnings through the app's injection + dependency pipeline.

### Notes / trade-offs

- The two **integrated-tensioner palm variants** were dropped; tensioning is provided by the `Box` component.
- For `palm_style = UnlimbitedV3` the v3 palm is driven at the Hand's `overall_scale` (Reborn-calibrated) so palm and fingers stay the same scale; the v3 mesh's native breadth differs from the Reborn mesh by ~3 %, so assembled-view knuckle alignment is approximate (the print-layout and palm geometry are unaffected).
- The standalone upstream sources (`models/active/paraglider/`) were removed after generating the bundles; regenerate with `scripts/namespace_scad.py` from a fresh clone of the [upstream repo](https://github.com/mendenmh/flexible_flyer) if needed.
