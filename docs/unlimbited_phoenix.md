# UnLimbited Phoenix Hand — Integration Notes

This document explains how the Team UnLimbited Phoenix Hand was integrated into the
AI Parametric Prosthetic Hand Generator platform: the source design, the model
structure, the (single) anthropometric mapping, and the scale-floor behaviour.

## 1. Source Design

**Team UnLimbited Phoenix Hand V1.0**, by Stephen Robert Davies & Drew Murray / Team
UnLimbited (original Phoenix Hand by Jason Bryant), licensed **CC BY-NC-SA 4.0**
(teamunlimbited.org). Upstream is a Thingiverse Customizer thing
([thing:1674320](https://www.thingiverse.com/thing:1674320)): the user picks left/right
and a scale, and a `.zip` of all parts is generated at that scale.

The geometry is **not** procedural — the palm, fingers, phalanx, pins, tension box and
gauntlet are fixed meshes captured as OpenSCAD `polyhedron()` point/face arrays. The
palm used here is the **Thermo-palm Phoenix Palm** (`Phoenix_Thermo_Palm_2`), whose
unscaled (100%) bounding box is **82.17 × 91.96 × 30.55 mm**.

### Source files

| Repo path | Purpose |
|---|---|
| `models/active/unlimbed_phoenix_hand/UnLimbitedPhoenix.scad` | the integrated, self-contained model |
| `tests/UnLimbited_Arm_V2.2.scad` | upstream Team UnLimbited source (arm + hand), used as the dimensional **reference** (its `part = 5` palm embeds the same `Phoenix_Thermo_Palm_2` mesh) |

## 2. Approach: Self-Contained Single File

As with the other models, the upstream multi-file Customizer was consolidated into one
self-contained `.scad` with the meshes embedded inline (no `use<>`, `include<>`, or
`import()` — so it runs in OpenSCAD-WASM with no dependency files). The configurator
declares **no `parts`** in `models-config.json`, so "Export STL" produces a **single
file** — whichever part `part` selects (default `Palm`).

## 3. What Was Built

A `print_part()` dispatcher renders one part at a time, scaled by `HandPerc/100` and
mirrored for the right hand:

| `part` value | Module | Notes |
|---|---|---|
| `Palm` *(default)* | `Phoenix_Thermo_Palm_2()` | the exported part by default |
| `Box` | `3Pin_Tensioner_Box()` | wrist tension box |
| `TPins` | `3Tensionpins()` | tension pins |
| `Fingers` | `Phoenix_Fingers_Left()` | finger tips |
| `Phalanx` | `Phoenix_Phalanx_Left()` | proximal phalanxes |
| `Pins` | `Phoenix_Pins()` | hinge pins |
| `Gauntlet` | `Gauntlet_V4()` | Reverse-Dovetail thermo gauntlet |
| `Jig` | — | assembly jig |

`LeftRight` (`Left`/`Right`) mirrors the geometry along X.

## 4. Anthropometric Parameter Mapping

Unlike the Flexy Beast and Paraglider, the Phoenix mesh is a **single fixed shape that
can only be scaled uniformly** — there is one anthropometric input:

| Platform parameter | Derivation | Active / stored |
|---|---|---|
| `palm_breadth_mm` (range **82–131**) | `HandPerc = palm_breadth_mm / 82 × 100`, clamped **100–160%** | Active — drives the uniform print scale |
| `HandPerc_override` (range 0–160) | `0` = auto (use the line above); `100–160` = set the scale directly | Active — manual escape hatch |

```openscad
REF_PALM_BREADTH = 82;   // breadth of the unscaled (100%) Phoenix mesh
HandPerc = HandPerc_override > 0
    ? max(100, min(160, HandPerc_override))
    : max(100, min(160, palm_breadth_mm / REF_PALM_BREADTH * 100));
```

### The 100% floor (and why)

The Phoenix mesh **cannot be printed below its native 100% size** (≈82 mm palm breadth);
shrinking it further produces walls and channels too thin to print and assemble. The
model therefore **clamps the scale to 100–160%** and the `palm_breadth_mm` slider starts
at 82. For hands narrower than ~82 mm, use a model that scales down further — the
**Flexy Beast** (the model help says so explicitly).

> **Both scale paths are floored (fix v14.18.0).** `HandPerc_override`'s declared range
> is `[0:160]`, but only `0` (auto) and `100–160` (direct) are meaningful — the `1–99`
> band is a dead zone. It previously had **no floor**, so a value like `76` scaled the
> palm to 76% (62 mm), bypassing the 100% minimum that `palm_breadth_mm` enforces. The
> AI-sizing simulation hit exactly this (a child profile produced `HandPerc_override = 76`).
> The override branch now applies the same `max(100, min(160, …))` clamp, so **neither**
> path can drop below 100%. See `docs/phoenix-ai-sim/` §5.

## 5. Validation

An end-to-end simulation (real `/edit` flow: AI sizing → STL export → `trimesh`
measurement) confirms the integration reproduces the upstream Phoenix palm **exactly**:
the exported palm equals the `tests/UnLimbited_Arm_V2.2.scad` reference mesh × `HandPerc/100`
to within ≤0.06 mm, and the 100% exports are byte-identical to the 82.17 mm reference. It
also surfaced (and the platform fixed) the override floor gap above, and confirmed the
size floor for the small profiles. Full prompts, AI-applied parameters and dimensions:
[`docs/phoenix-ai-sim/`](phoenix-ai-sim/unlimbited-phoenix-hand_ai-sizing-dimensional-report_2026-06-28.md).

Grounding for this model anchors only `palm_breadth_mm` (its single anatomical input);
see the matcher notes in `ai_anthropometric_validation.md` §2.4.

## 6. Attribution

Team UnLimbited Phoenix Hand V1.0 — Stephen Robert Davies & Drew Murray / Team UnLimbited;
original Phoenix Hand by Jason Bryant. Licensed **CC BY-NC-SA 4.0**
([teamunlimbited.org](https://www.teamunlimbited.org)). Integrated here with the geometry
unchanged; only the sizing front-end (anthropometric `palm_breadth_mm` → uniform print
scale) was added.
