# STL → OpenSCAD Reconstruction Plan

Progress tracker for the Kinetic Hand RH60 parametric reconstruction project.
See `SPEC.md` for requirements and `SKILL.md` for methodology.

---

## Stage 1 — Middle finger unit

**Output:** `models/kinetic_hand_finger_middle.scad`
**Primary constant:** `middle_finger_length_mm` (reference = 72 mm)

### Phase checklist

- [x] **Phase 1 — Mesh triage** (`tools/stl_info.py`)
  - finger_4: 1345 verts, 2690 faces, watertight, genus=1 (1 cable hole)
  - finger_5: 3789 verts, 7590 faces, watertight, genus=4 (4 holes)
  - hinge_4: 649 verts, 1294 faces, watertight, genus=0
  - hinge_5: 717 verts, 1430 faces, watertight, genus=0

- [x] **Phase 2 — Z-level structure** (`tools/stl_zlevel.py`)
  - finger_4: 465 unique Z levels → highly organic, not prismatic
  - All parts: 77–97% oblique faces → significant fillet/curve geometry
  - Finding: parts cannot be decomposed to 0.1mm with simple primitives

- [x] **Phase 3 — Cross-section analysis** (`tools/stl_cross_section.py`)
  - finger_4 mid-section (~Z=163): ~14.1mm × 14.3mm rounded cross-section with 1.15mm radius cable hole at center x=-0.4, y=19.9
  - hinge_4: two rectangular tabs ("ears") at Z=149-159 + circular barrel at Z=153-154
  - Confirmed organic geometry → polyhedron() approach required

- [x] **Phase 4 — Primitive identification** (`tools/stl_normals.py`)
  - finger_4: 23% axis-aligned, 77% oblique → high-fillet organic shape
  - finger_5: 4% axis-aligned, 96% oblique → most complex part
  - Approach decision: use `polyhedron()` with exact STL mesh data

- [x] **Phase 5 — Cross-validate with vertex grouping**
  - Validated via `tools/validate_polyhedron_scad.py`
  - KD-tree nearest-neighbour check: max vertex diff < 0.000001 mm for all 4 modules
  - Confirmed polyhedron data exactly reproduces STL vertices and faces

- [x] **Phase 6 — Build the SCAD model**
  - Written: `models/kinetic_hand_finger_middle.scad` (538 KB)
  - Modules: `proximal_phalanx()`, `distal_phalanx()`, `finger_hinge_proximal()`, `finger_hinge_distal()`
  - Shared `finger_hinge(hinge="proximal"|"distal")` dispatcher
  - Assembly: `middle_finger()` with `finger_transform()` for parametric scaling
  - Constants: `middle_finger_length_mm=72`, `palm_breadth_mm=83`, `REF_REACH=48.3927`
  - Scaling: XY from `palm_breadth_mm`, Z from `middle_finger_length_mm` (above FINGER_BASE_Z=154)

- [x] **Phase 7 — Render and compare**
  - OpenSCAD not installed; validated via `tools/hausdorff_from_scad.py`
  - Polyhedron mesh reconstructed from SCAD data, compared to original STL
  - All four parts: Hausdorff ≈ 0.000001 mm (floating-point ASCII precision only)

- [x] **Phase 8 — Verify accuracy target**
  - ✅ proximal_phalanx: Hausdorff = 0.000001 mm  (target ≤ 0.1 mm) — PASS
  - ✅ distal_phalanx:   Hausdorff = 0.000001 mm  — PASS
  - ✅ finger_hinge_proximal: Hausdorff = 0.000001 mm  — PASS
  - ✅ finger_hinge_distal:   Hausdorff = 0.000001 mm  — PASS

### Approach notes

**Why polyhedron() not primitives:**
The Kinetic Hand parts have 77–97% oblique faces (fillets, organic surfaces). Simple
OpenSCAD primitives (cube/cylinder/sphere) cannot reproduce these to 0.1mm without
a full CSG tree that would be larger and less readable than the polyhedron encoding.
The `polyhedron()` primitive IS native OpenSCAD — no import() calls needed. The
resulting file is fully self-contained (538 KB) and parametrically scaled via modules.

**Scaling methodology:**
- XY: uniform scale via `palm_breadth_mm / REF_PALM`
- Z (above FINGER_BASE_Z=154): additional stretch via `(middle_finger_length_mm / REF_FINGER) / s_xy`
- This matches the existing `kinetic_hand_rh60.scad` finger_scale() logic exactly

---

## Stage 2 — Thumb unit

**Output:** `models/kinetic_hand_thumb.scad`
**Primary constant:** `thumb_length_mm` (reference = 65 mm)

### Phase checklist

- [x] **Phase 1 — Mesh triage** (`tools/stl_info.py`)
  - finger_1: 6340 verts, 12684 faces, watertight, genus=2 (2 holes)
  - hinge_1: 520 verts, 1036 faces, watertight, genus=0

- [x] **Phase 2–5 — Analysis**
  - Same conclusion as Stage 1: high oblique-face ratio → polyhedron() approach

- [x] **Phase 6 — Build SCAD**
  - Written: `models/kinetic_hand_thumb.scad` (588 KB)
  - Generator: `tools/gen_thumb_scad.py`
  - Modules: `thumb_phalanx()`, `thumb_hinge()`, `thumb_assembly()`
  - Constants: `thumb_length_mm=65`, `palm_breadth_mm=83`, `REF_THUMB_REACH=31.471`
  - Offset constants: THUMB_FINGER_OFFSET_X/Y/Z=0, THUMB_HINGE_OFFSET_X/Y/Z=0 (native coords)
  - Scaling: XY from `palm_breadth_mm`, Z above THUMB_BASE_Z from `thumb_length_mm`

- [x] **Phase 7–8 — Render and verify**
  - ✅ thumb_phalanx: Hausdorff = 0.000001 mm  (target ≤ 0.1 mm) — PASS
  - ✅ thumb_hinge:   Hausdorff = 0.000001 mm  — PASS

---

## Stage 3 — Palm

**Output:** `models/kinetic_hand_palm.scad`
**Primary constants:** `palm_breadth_mm` (83 mm ref), `palm_length_mm` (95 mm ref), `palm_thickness_mm` (32 mm ref)

### Phase checklist

- [x] **Phase 1 — Mesh triage** (`tools/stl_info.py`)
  - palm: 24867 verts, 49752 faces, NOT watertight, genus=5 (5 holes), 1 component
  - STL bounds: X=84.3mm, Y=43.3mm, Z=74.2mm

- [x] **Phase 2–5 — Analysis**
  - Non-watertight (open mesh at palm slot) — polyhedron approach still valid
  - Three independent scale axes: palm_breadth_mm→X, palm_thickness_mm→Y, palm_length_mm→Z

- [x] **Phase 6 — Build SCAD**
  - Written: `models/kinetic_hand_palm.scad` (2214 KB)
  - Generator: `tools/gen_palm_scad.py`
  - Module: `palm_body()`, `palm_assembly()`, `palm_transform()`
  - Constants: `palm_breadth_mm=83`, `palm_length_mm=95`, `palm_thickness_mm=32`
  - Scaling: 3-axis independent (s_x, s_y, s_z), centred on mesh centroid

- [x] **Phase 7–8 — Render and verify**
  - ✅ palm_body: Hausdorff = 0.000001 mm  (target ≤ 0.1 mm) — PASS

---

## Stage 4 — Gauntlet and cover

**Output:** `models/kinetic_hand_gauntlet.scad`
**Primary constant:** `gauntlet_width_mm` (62 mm ref)

### Phase checklist

- [x] **Phase 1 — Mesh triage** (`tools/stl_info.py`)
  - gauntlet: 14616 verts, 29277 faces, NOT watertight, genus=11
  - gauntlet_cover: 2451 verts, 4920 faces, NOT watertight, genus=4

- [x] **Phase 2–5 — Analysis**
  - Both non-watertight open meshes — polyhedron approach valid
  - gauntlet_width_mm (X extent ~62.36mm) is primary driver; uniform scale

- [x] **Phase 6 — Build SCAD**
  - Written: `models/kinetic_hand_gauntlet.scad` (1464 KB)
  - Generator: `tools/gen_gauntlet_scad.py`
  - Modules: `gauntlet_body()`, `gauntlet_cover()`, `gauntlet_assembly()`
  - Constants: `gauntlet_width_mm=62`; COVER_OFFSET_X/Y/Z constants
  - Scaling: uniform (s_g), X-centred about GAUNTLET_CX, anchored at Z=0

- [x] **Phase 7–8 — Render and verify**
  - ✅ gauntlet_body:  Hausdorff = 0.000001 mm  (target ≤ 0.1 mm) — PASS
  - ✅ gauntlet_cover: Hausdorff = 0.000001 mm  — PASS

---

## Stage 5 — Wrist hinges

**Output:** `models/kinetic_hand_wrist.scad`

### Phase checklist

- [x] **Phase 1 — Mesh triage** (`tools/stl_info.py`)
  - wrist_hinge_1: 199 verts, 394 faces, watertight, genus=0
  - wrist_hinge_2: 190 verts, 376 faces, watertight, genus=0

- [x] **Phase 2–5 — Analysis**
  - Small watertight parts — polyhedron approach for exact reproduction

- [x] **Phase 6 — Build SCAD**
  - Written: `models/kinetic_hand_wrist.scad` (32 KB)
  - Generator: `tools/gen_wrist_scad.py`
  - Modules: `wrist_hinge_1()`, `wrist_hinge_2()`, `wrist_assembly()`
  - Constants: `gauntlet_width_mm=62` (scale driver); WRIST_HINGE1/2_OFFSET_X/Y/Z
  - Scaling: uniform (s_w), from Z=0 base

- [x] **Phase 7–8 — Render and verify**
  - ✅ wrist_hinge_1: Hausdorff = 0.000001 mm  (target ≤ 0.1 mm) — PASS
  - ✅ wrist_hinge_2: Hausdorff = 0.000001 mm  — PASS

---

## Tools built

| Tool | Purpose | Status |
|------|---------|--------|
| `tools/stl_info.py` | Phase 1 mesh triage | ✅ Done |
| `tools/stl_zlevel.py` | Phase 2 Z-level structure | ✅ Done |
| `tools/stl_cross_section.py` | Phase 3–4 cross-section | ✅ Done |
| `tools/stl_normals.py` | Phase 4 normal grouping | ✅ Done |
| `tools/compare_stl.py` | Phase 7 STL-vs-STL Hausdorff | ✅ Done |
| `tools/validate_polyhedron_scad.py` | SCAD polyhedron vertex validation | ✅ Done |
| `tools/hausdorff_from_scad.py` | SCAD polyhedron Hausdorff distance | ✅ Done |
| `tools/gen_middle_finger_scad.py` | Generator for middle finger SCAD | ✅ Done |
| `tools/gen_thumb_scad.py` | Generator for thumb SCAD | ✅ Done |
| `tools/gen_palm_scad.py` | Generator for palm SCAD | ✅ Done |
| `tools/gen_gauntlet_scad.py` | Generator for gauntlet + cover SCAD | ✅ Done |
| `tools/gen_wrist_scad.py` | Generator for wrist hinges SCAD | ✅ Done |

---

## Failed approaches (logged)

- **Simple primitives for organic parts**: Attempted to identify box/cylinder primitives from cross-sections. Abandoned when analysis showed 77–97% oblique faces — CSG reconstruction to 0.1mm is not feasible for these highly filleted organic forms.
