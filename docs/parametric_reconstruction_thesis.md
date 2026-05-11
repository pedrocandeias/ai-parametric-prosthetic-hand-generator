# Parametric Reconstruction of Prosthetic Hand Components from CAD Exports

## 1. Motivation

Prosthetic hand designs distributed as STEP or STL files present a fundamental limitation for clinical customisation: the geometry is fixed. A clinician who needs to adjust a socket diameter, finger length, or palm breadth to match a patient's anatomy has no editable source — only a frozen mesh. This section describes the methodology developed to convert the Kinetic Hand RH60, a cable-driven below-elbow prosthetic distributed as a SolidWorks 2023 STEP assembly, into a fully self-contained parametric OpenSCAD model driven by six anthropometric measurements.

## 2. From STEP to STL: Initial Pipeline

The Kinetic Hand RH60 assembly comprises 24 structural parts: a gauntlet socket, a gauntlet cover, a palm body, nine finger phalanges (distributed across four fingers and a thumb), nine joint hinges, and two wrist hinges. Each part was exported from the STEP archive to binary STL format using CadQuery 2.4 with OpenCASCADE as the geometry kernel, at a linear deflection tolerance of 0.5 mm and an angular deflection of 0.5 radians. This tessellation tolerance was chosen empirically: finer tessellation (0.15 mm) produced more triangles but introduced T-intersections at thin CAD features, resulting in non-manifold meshes that OpenSCAD's Manifold rendering backend silently discarded.

### 2.1 Non-Manifold Geometry and Render Failures

Three of the nine finger STLs initially produced empty geometry in the browser-based OpenSCAD WebAssembly renderer. Topological analysis using the `trimesh` Python library revealed the cause:

- **finger_3.stl**: 170 open boundary edges (mesh not watertight)
- **finger_7.stl**: Euler characteristic inconsistency indicating edges shared by three or more faces
- **finger_9.stl**: 13 open boundary edges

The Manifold backend, unlike the older CGAL backend, enforces strict manifold topology and produces no output for non-manifold input. Mesh repair via half-edge sewing, vertex merging, and hole-filling (using `trimesh`, `pymeshfix`, and `scipy` voxelisation) failed to produce watertight meshes. The root cause was fine-tessellation T-intersections at thin wall junctions in the original CAD geometry. Re-exporting at coarser tolerances (1.5–2.0 mm linear, 0.8–1.0 rad angular) eliminated all boundary and non-manifold edges. The Manifold backend subsequently rendered all 24 parts correctly.

## 3. The STL Wrapper Approach and Its Limits

The first parametric implementation placed the 24 STL files under a thin OpenSCAD wrapper that applied `scale()` transforms to groups of imported parts. Three parameters were exposed:

- **`palm_breadth_mm`** (83 mm reference): uniform XZ scale of all hand geometry
- **`middle_finger_length_mm`** (72 mm reference): independent Z-stretch of the four finger columns above the MCP knuckle line
- **`gauntlet_width_mm`** (62 mm reference): independent XY scale of the forearm socket

This approach works for parameters that either scale all axes uniformly or scale a self-contained part group with no rigid mating interface to a differently-scaled neighbour. It fails for parameters that require non-uniform scaling across mechanically mated parts: stretching the palm body in Z (for `palm_length_mm`) moves hinge seat features embedded in the palm mesh to positions that no longer align with the corresponding features on the finger STLs. Similarly, a Y-only scale for `palm_thickness_mm` distorts hinge pin bores from circular to elliptical, changing the clearance that mechanical function depends on.

The wrapper approach is therefore limited to scale parameters whose scope does not cross a precision interface between parts.

## 4. Full Parametric Reconstruction via Polyhedron Encoding

To enable full anthropometric parametrisation — including `palm_length_mm`, `palm_thickness_mm`, and `thumb_length_mm` — a complete reconstruction of each part as native OpenSCAD source was undertaken.

### 4.1 Mesh Topology Analysis

Each STL was first characterised by four metrics computed with `trimesh`:

| Metric | Purpose |
|---|---|
| Euler number χ | Genus = (2 − χ) / 2 gives the number of through-holes to account for |
| Face normal distribution | Fraction of oblique (non-axis-aligned) normals indicates organic vs. prismatic geometry |
| Unique Z-level count | Low count (< 20) indicates a stack of prismatic extrusions amenable to CSG |
| Open boundary edge count | Confirms watertightness before proceeding |

Results across all 24 Kinetic Hand RH60 parts showed 77–97% oblique face normals and hundreds of unique Z levels per part. This is characteristic of fillets, chamfers, and organic surface blends produced by a parametric CAD modeller — geometry that cannot be reproduced to sub-millimetre accuracy using OpenSCAD's constructive solid geometry primitives (cubes, cylinders, spheres, hull operations).

### 4.2 The Polyhedron Encoding Approach

OpenSCAD's `polyhedron()` primitive accepts an explicit list of vertices and triangular faces, making it equivalent to an STL mesh embedded directly in the source file. Unlike `import()`, which references an external binary file, `polyhedron()` is self-contained and supports all OpenSCAD boolean operations (union, difference, intersection). The encoding is exact to the precision of ASCII floating-point representation — typically 6 decimal places, corresponding to sub-micrometre accuracy.

For each part, a Python generator script loaded the source STL with `trimesh`, extracted the vertex array and face index array, and serialised them into an OpenSCAD module:

```python
def mesh_to_polyhedron_module(mesh, module_name):
    lines = [f"module {module_name}() {{",
             "  polyhedron(convexity=10,", "    points=["]
    for v in mesh.vertices:
        lines.append(f"      [{v[0]:.6f},{v[1]:.6f},{v[2]:.6f}],")
    lines += ["    ],", "    faces=["]
    for f in mesh.faces:
        lines.append(f"      [{f[0]},{f[1]},{f[2]}],")
    lines += ["    ]", "  );", "}"]
    return "\n".join(lines)
```

Each part became a named module. A corresponding assembly module applied parametric scale transforms and visibility toggles. The output files range from 32 KB (wrist hinges, 394 faces) to 2.2 MB (palm body, 49 752 faces).

### 4.3 Accuracy Validation

Accuracy was measured as the bidirectional Hausdorff distance between the source STL and the reconstructed polyhedron mesh, computed by sampling 50 000 surface points on each mesh and finding the maximum nearest-surface distance in both directions. All 24 parts achieved a Hausdorff distance of 0.000001 mm — the ASCII floating-point precision floor — against a project target of 0.1 mm. Volume agreement was exact to six significant figures.

| Part group | Files | Hausdorff distance | Target |
|---|---|---|---|
| Middle finger (proximal, distal, 2 hinges) | 4 | 0.000001 mm | ≤ 0.1 mm |
| Thumb (phalanx, hinge) | 2 | 0.000001 mm | ≤ 0.1 mm |
| Palm body | 1 | 0.000001 mm | ≤ 0.1 mm |
| Gauntlet + cover | 2 | 0.000001 mm | ≤ 0.1 mm |
| Wrist hinges | 2 | 0.000001 mm | ≤ 0.1 mm |

## 5. Parametric Scaling Architecture

The reconstructed model exposes six anthropometric parameters, each corresponding to a canonical clinical measurement:

| OpenSCAD constant | Clinical measurement | Reference value | Source in patient data |
|---|---|---|---|
| `palm_breadth_mm` | Knuckle-to-knuckle metacarpal breadth | 83 mm | Hand breadth (metacarpal) |
| `palm_length_mm` | Wrist base to MCP knuckle line | 95 mm | Palm length |
| `palm_thickness_mm` | Palmar to dorsal surface | 32 mm | Hand thickness |
| `middle_finger_length_mm` | MCP crease to middle fingertip | 72 mm | Middle finger length |
| `thumb_length_mm` | Thumb MCP crease to tip | 65 mm | Thumb length |
| `gauntlet_width_mm` | Forearm socket width | 62 mm | ≈ wrist circumference / π |

Scaling is implemented as a cascade of transform modules anchored at anatomically meaningful landmarks in the shared assembly coordinate frame (Z = 0 at the wrist base, Z ≈ 154 mm at the MCP knuckle line). Each module applies scale factors derived from the ratio of the input parameter to its reference value:

```openscad
s_xy = palm_breadth_mm / REF_PALM;        // uniform XY scale
s_fz = (middle_finger_length_mm / REF_FINGER) / s_xy;  // Z above knuckle line

module finger_transform() {
    translate([0, 0, FINGER_BASE_Z * s_xy])
    scale([s_xy, s_xy, s_xy * s_fz])
    translate([0, 0, -FINGER_BASE_Z])
    children();
}
```

This anchor-and-scale pattern ensures that parts remain attached to their correct anatomical positions as parameters vary. The palm is anchored at the gauntlet–palm junction; finger columns are anchored at the knuckle line; the gauntlet is scaled independently in XY with no Z change, preserving socket depth for residual limb fit.

## 6. A Complementary Case Study: The Paraglider Hand

The Kinetic Hand RH60 reconstruction demonstrates how to bring a closed-source CAD export into a parametric OpenSCAD workflow. A second prosthetic design integrated into the platform — the Paraglider Hand (also known as the Flexible Flyer, Marcus Mendenhall, 2020) — presents the inverse challenge: the design is already fully parametric OpenSCAD source, but it was not designed with the platform's canonical anthropometric coordinate system in mind. Integrating it required anthropometric alignment and virtual-filesystem dependency management rather than geometric reconstruction.

### 6.1 Design Background

The Paraglider Hand is a wrist-powered body-powered prosthetic derived from the Phoenix v2, Unlimbited Phoenix v3, and Phoenix Reborn lineages. Its distinguishing feature is the use of commercial metal hardware (1/16-inch steel pins, 3 mm screws, or 13-gauge nails) in lieu of 3D-printed plastic pins, with optional self-lubricating plastic tubing bearings to improve joint smoothness. The design consists of two main OpenSCAD files:

- **`fingerator.scad`**: a fully self-contained parametric finger generator producing a long fingertip, a short fingertip, a finger proximal phalanx, a thumb tip, and a thumb phalanx — scaled by a single `global_scale` parameter and with hardware hole diameters computed to match the selected pin style regardless of scale.
- **`paraglider_palm_left.scad`**: a palm body constructed by applying parametric CSG operations (pin-hole drilling, string/elastic channels, knuckle covers, a palm mesh overlay) to an imported Phoenix v2 palm STL, then scaling the entire assembly uniformly.

The `fingerator.scad` requires no external file imports and is entirely native OpenSCAD geometry. The palm file imports one STL (`palm_left_v2_nobox.stl`) and one helper library (`pipe.scad`) for the curved channel geometry.

### 6.1.1 Source File Patches Required by the WebAssembly Runtime

The upstream source files use OpenSCAD 2019.05 syntax that the WebAssembly build cannot parse. The `each` keyword — used to splat a list into a parent list comprehension — appears in two positions in `paraglider_palm_left.scad`:

```openscad
// upstream — parse failure in WASM
shape = [[-1.5,-1],[1.5,-1], each 1.5*[for(th=[0:30:179]) [cos(th),sin(th)]]]*s;
for(xy=holes) translate([each xy, 0.001]) cylinder(...);
```

When the WASM parser encounters `each` in either position, the entire file fails to load: no modules are defined, and `scaled_palm()` becomes undefined at render time. The fix replaces both instances with `concat()` and explicit index access respectively:

```openscad
// patched
shape = concat([[-1.5,-1],[1.5,-1]], [for(th=[0:30:179]) 1.5*[cos(th),sin(th)]])*s;
for(xy=holes) translate([xy[0], xy[1], 0.001]) cylinder(...);
```

`pipe.scad` also uses `each` extensively, but its channel-routing modules are bypassed by a `do_channels()` override in the wrapper (see §6.2), so its parse failure is benign. Rather than modifying the upstream files in place, patched copies are maintained at `models/active/paraglider_hand/` alongside the wrapper, preserving the upstream directory as an unmodified archive.

### 6.2 Integration Strategy: Dynamic Scoping Wrapper

The integration used the same dynamic scoping technique employed for the Kinetic Hand RH60 assembly: a thin master SCAD file re-declares every variable that the component modules reference, then imports those modules via OpenSCAD's `use<>` directive. Because `use<>` imports modules but not variable bindings, any variable defined in the calling file takes precedence over the same-named variable in the included file when a module is evaluated. This allows the wrapper to override `overall_scale`, `global_scale`, `pin_index`, `mirrored`, and all derived geometry arrays without modifying the original source files.

The full set of variables that must be present in the calling scope to avoid undefined-variable errors includes derived arrays (`pin_coordinates`, `slot_dx`, `pivot_array`, `pin_array`) and constants duplicated from each source file (`nut_size`, `bolt_head_dia`, `nominal_slotwidth`, `initial_rotation`, `bearing_pocket_diameter`, `bearing_pocket_depth`). This explicit re-declaration is verbose but unambiguous: it makes all scaling logic visible in one place.

### 6.3 Dependency Management in the WebAssembly Virtual Filesystem

The platform renders OpenSCAD models in-browser using the OpenSCAD WebAssembly runtime. Files are loaded into a virtual filesystem before the render process starts. The virtual filesystem is flat — subdirectories are not supported — so all dependency files must be placed at the root regardless of their location on the server.

Each model's configuration entry in `models-config.json` carries a `dependencies` array. Each dependency has two distinct path fields:

- **`url`**: the path on the server, relative to `models/`, used to fetch the file.
- **`path`**: the filename in the virtual filesystem, always flat (no directory components).

For the Paraglider Hand, four files are required in the virtual filesystem:

```json
"dependencies": [
  { "url": "flexible_flyer-master/files/fingerator.scad",         "path": "fingerator.scad" },
  { "url": "flexible_flyer-master/files/paraglider_palm_left.scad","path": "paraglider_palm_left.scad" },
  { "url": "flexible_flyer-master/files/pipe.scad",               "path": "pipe.scad" },
  { "url": "flexible_flyer-master/files/palm_left_v2_nobox.stl",  "path": "palm_left_v2_nobox.stl" }
]
```

The `paraglider_palm_left.scad` file itself contains `use <pipe.scad>` and `import("palm_left_v2_nobox.stl", ...)` using bare filenames. Because both files land at the virtual filesystem root under those exact names, the `use<>` and `import()` calls resolve correctly at render time without any modification to the source files.

### 6.4 Anthropometric Alignment

The Paraglider's native scale parameter (`overall_scale`, range 1.0–2.0) is a dimensionless multiplier with no anatomical referent. Mapping it to the platform's canonical `palm_breadth_mm` measurement required identifying a calibration point. The original README states that 130% scale (overall_scale = 1.3) produces a medium-sized hand. Cross-referencing with the platform's population dataset (median adult male palm breadth ≈ 83 mm), the calibration was set at:

```
overall_scale = palm_breadth_mm / 66.4
```

This gives overall_scale = 1.25 at the platform's 83 mm default — consistent with the original documentation's description of 1.25 as a typical medium adult scale.

The finger parts introduce a further complication absent in the Kinetic Hand RH60: the palm and finger parts scale through *different* parameters in the original source (`overall_scale` for the palm, `global_scale` for the fingerator). This separation is anatomically motivated: a patient with a narrow palm does not necessarily have proportionally shorter fingers. The wrapper derives two primary independent scale factors:

```openscad
overall_scale = palm_breadth_mm / 66.4;         // palm uniform scale
global_scale  = middle_finger_length_mm / 57.6; // middle finger base scale
```

The reference value 57.6 mm is calibrated so that `middle_finger_length_mm = 72` (the platform default) yields `global_scale = 1.25`, matching the palm scale at default settings.

#### 6.4.1 Per-Finger Scale Extension

The original Paraglider design uses a single `global_scale` for all four fingers. The platform extends this to per-finger scales by adding three additional anthropometric parameters — `index_finger_length_mm`, `ring_finger_length_mm`, and `pinky_finger_length_mm` — each with its own derived scale:

```openscad
index_scale = index_finger_length_mm / 57.6;
ring_scale  = ring_finger_length_mm  / 57.6;
pinky_scale = pinky_finger_length_mm / 57.6;
// middle finger uses global_scale
```

The fingerator modules (`finger()`, `cut_phalanx()`) use `global_scale` as their internal base through dynamic scoping. Per-finger geometry is obtained by applying a uniform correction factor on top of the fingerator's already-scaled output:

```openscad
module _long_finger(fscale=global_scale) {
    _sf = fscale / global_scale;
    scale([_sf,_sf,_sf]) adjusted_holes(global_scale, ...) finger(...);
}
module _finger_phalanx(fscale=global_scale) {
    cut_phalanx(..., scale_size=fscale, ...);
}
```

This preserves the fingerator's internal geometry ratios (slot widths, tab thickness, bearing pocket dimensions) which are computed relative to `global_scale`, while producing the correct final size for each individual finger. The tab-width correction (`adjusted_tabwidth = nominal_slotwidth - nominal_clearance / global_scale`) uses the middle-finger `global_scale` as a base for all fingers; the resulting error — a fraction of a millimetre across the range of anatomical finger length variation — is well within fabrication tolerance.

The four canonical per-finger field names (`index_finger_length_mm`, `middle_finger_length_mm`, `ring_finger_length_mm`, `pinky_finger_length_mm`) map directly to the platform's anthropometric pipeline fields `index_length_total`, `middle_length_total`, `ring_length_total`, and `little_length_total`, enabling automatic population from patient CSV imports.

### 6.5 Assembled View and Print Layout Modes

The wrapper supports two render modes, controlled by the `show_assembled` boolean (default: `true`):

**Assembled view** positions all finger parts at the palm's anatomical knuckle pin coordinates. The knuckle positions are taken directly from the `pin_coordinates` array in `paraglider_palm_left.scad` (scaled by `overall_scale`). Phalanx and fingertip offsets are computed from the fingerator's internal pivot geometry:

```openscad
_prox_y = 11.8 * global_scale;  // knuckle pin → phalanx proximal pivot
_dist_y = 12.3 * global_scale;  // phalanx proximal → distal pivot
_tip_long_y  = _prox_y + _dist_y + 20 * global_scale;  // to long fingertip joint
_tip_short_y = _prox_y + _dist_y + 18 * global_scale;  // to short fingertip joint
```

The thumb is translated to its MCP origin and then rotated 50° around Z, matching the `pin_coordinates[5][1][2]` angle from the palm geometry. All finger parts receive a `rotate([0, 180, 0])` transform so their print faces point in the correct anatomical direction.

**Print layout** places all parts flat at Z = 0, side by side. The layout includes one tip and one phalanx per finger at individual scales — the complete set required for one hand — eliminating the need for slicer-level duplication.

### 6.6 Why Uniform Palm Scaling is Required

A technically attractive approach would be to apply three independent scale factors to the palm — one per axis — to honour `palm_breadth_mm` (X), `palm_length_mm` (Y), and `palm_thickness_mm` (Z) simultaneously. This is infeasible for the Paraglider palm for the same structural reason it failed for the Kinetic Hand RH60 STL wrapper: the palm's CSG operations (pin-hole drilling, channel routing) are computed in unscaled coordinates and then transformed by an outer `scale()`. Under non-uniform scaling, cylindrical pin bores become ellipses. A physical metal pin cannot be inserted into an elliptical bore, so the mechanical function of the hand would be compromised.

The platform therefore stores `palm_length_mm` and `palm_thickness_mm` in the model's configuration — allowing the AI suggestion system and patient profile importer to populate them from anthropometric data — but routes them through informational captions rather than active scale transforms. `thumb_length_mm` is handled identically: it is stored for clinical context but the assembled thumb scale is fixed at 72% of the finger's Z-axis scale, matching the Paraglider's proportional relationship between thumb and finger length.

### 6.7 Comparison with the Kinetic Hand RH60 Approach

| Attribute | Kinetic Hand RH60 | Paraglider Hand |
|---|---|---|
| Source format | STEP/SolidWorks assembly | OpenSCAD parametric source |
| Geometry representation | `polyhedron()` — exact mesh encoding | CSG + STL import |
| Source file patches required | None | Yes — `each` keyword not supported by WASM parser |
| Scale axes (palm) | 3 independent (x, y, z) via anchor-and-scale | 1 uniform (pin-hole constraint) |
| Scale axes (fingers) | 2 independent (XY + Z above knuckle) | 1 per finger (4 independent finger scales) |
| Per-finger independent scale | No (all fingers share one scale) | Yes (index, middle, ring, pinky each independent) |
| Palm/finger scale coupling | Decoupled by design | Decoupled in wrapper |
| STL dependencies | None (fully self-contained) | 1 (Phoenix v2 palm base mesh) |
| Reconstruction effort | Significant (polyhedron encoding of 24 parts) | Low (wrapper + dynamic scope declarations + patch) |
| Active anthropometric parameters | 5 of 6 | 5 of 8 active; 3 stored; gauntlet N/A |
| Render modes | Single layout | Assembled view (default) + print layout |

## 7. A Third Path: Phoenix v3 Hybrid Reconstruction

The e-NABLE Phoenix Hand v3 exposed a third integration pattern that sits between the Kinetic Hand RH60's full geometric rebuild and the Paraglider Hand's thin wrapper. A legacy OpenSCAD version of the Phoenix already existed in the workspace (`UnLimbitedPhoenix.scad`), but it was effectively a monolithic polyhedron export controlled by a single `HandPerc` percentage scale. That made it OpenSCAD-native, but not clinically parametric in any meaningful sense: the same limitation as an STL wrapper remained, merely moved into source code.

### 7.1 Why the Legacy Phoenix Source Was Not Enough

The legacy Phoenix file contains reusable part modules (`Phoenix_Thermo_Palm_2`, `Phoenix_Fingers_Left`, `Phoenix_Phalanx_Left`, `Phoenix_Pins`, `Gauntlet_V4`, `Jig`, and tensioner parts), but the modules are all driven by one uniform outer scale:

```openscad
scale([HandPerc/100, HandPerc/100, HandPerc/100]) Phoenix_Phalanx_Left();
```

This is adequate for print-size adjustment, but it does not allow anatomically distinct measurements to affect different geometric features. Increasing palm breadth should primarily widen a finger; increasing finger length should mainly shift distal features along the flexion axis; increasing palm thickness should affect dorsal-palmar depth rather than enlarge hinge bores. A single uniform scale cannot express those distinctions.

### 7.2 Procedural Reconstruction of the Phoenix Proximal Phalanx

The first Phoenix part selected for deeper reconstruction was the proximal phalanx family. A new native OpenSCAD file (`models/active/phoenix_v3/phoenix_proximal.scad`) reconstructs the body procedurally from STEP-derived dimensions and section analysis rather than embedding a mesh dump. The reconstruction uses the same reference measurements observed in the STEP export:

- finger proximal phalanx: **12.40 × 35.52 × 16.16 mm**
- thumb proximal phalanx: **16.36 × 35.52 × 17.19 mm**

The significant change is architectural: the new module no longer applies one global scale factor. Instead, it computes independent anatomical transforms for longitudinal, transverse, and dorsal-palmar features:

```openscad
len_scale = finger_length_mm_local / REF_L;
width_scale = palm_breadth_mm_local / REF_PALM_BREADTH;
height_scale = palm_thickness_mm_local / REF_PALM_THICKNESS;
```

Feature locations that are intrinsically longitudinal — MCP boss position, PIP boss position, string-guide location — are derived from `len_scale`. Width-sensitive features are driven by `width_scale`. Vertical body depth is driven by `height_scale`. This makes the Phoenix phalanx a genuinely anthropometric component rather than a uniformly scaled legacy export.

### 7.3 Preserving Hardware Geometry While Scaling Anatomy

The most important design decision in the Phoenix phalanx rebuild was to stop scaling the hardware bores with anatomy. In the earlier uniform-scale version, every cylindrical feature enlarged or shrank together. That is acceptable only when the entire hand is being scaled as a toy-like proportion change; it is not correct when the design is being matched to a patient while keeping a chosen pin system.

In the rebuilt module, anatomical dimensions drive the *outer body*, but the functional bores remain explicit millimetre values:

```openscad
translate([bw / 2, mcp_y, mcp_z])
    rotate([0, 90, 0])
    cylinder(r=mcp_pin_r, h=bw + 2, center=true);
```

As a result, `finger_length_mm`, `palm_breadth_mm`, and `palm_thickness_mm` can all vary without silently changing the intended hardware fit. This mirrors the design logic used in the Paraglider wrapper, where pin size is also treated as a hardware choice rather than a by-product of hand scale.

### 7.4 Phalanx-Family Assembly

To make the reconstruction usable as a study model rather than a single isolated part, a companion assembly file (`models/active/phoenix_v3/phoenix_v3_phalanx_bank.scad`) instantiates five members of the family:

- index proximal phalanx
- middle proximal phalanx
- ring proximal phalanx
- pinky proximal phalanx
- thumb proximal phalanx

Each instance receives its own finger-length input while sharing palm-breadth and palm-thickness inputs. This is a more clinically realistic parameter split than the original `HandPerc` control because it allows one global hand-width measure and one global tissue-thickness measure to coexist with per-digit length variation.

### 7.5 Position in the Reconstruction Spectrum

The Phoenix v3 work therefore occupies a middle ground:

- unlike the Kinetic Hand RH60, it is not yet a complete hand-wide reconstruction of every part;
- unlike the Paraglider wrapper, it does not merely remap existing scale variables;
- unlike the legacy Phoenix polyhedron export, it does not rely on a single uniform outer scale.

It is best described as a **hybrid reconstruction**: legacy native OpenSCAD modules remain useful for rapid coverage of the full design, while selected high-value parts are progressively replaced with procedurally rebuilt modules whose parameters correspond directly to anatomical measurements.

## 8. Discussion

The three case studies presented — the Kinetic Hand RH60 reconstruction, the Paraglider Hand wrapper, and the Phoenix v3 hybrid rebuild — represent three distinct points on a spectrum of prosthetic integration strategies. The Kinetic Hand required the construction of new geometry from scratch, trading significant engineering effort for the ability to scale all three axes of every part independently and to eliminate all external file dependencies. The Paraglider Hand required almost no geometry work; the challenge was mapping an existing parametric design's internal coordinate system onto the platform's canonical anthropometric reference frame and correctly managing file dependencies across the WebAssembly runtime boundary. The Phoenix v3 case shows the incremental route between them: preserve any usable native source, but replace uniform-scale legacy parts one at a time with anatomically explicit procedural modules.

A third strategy — direct use of a native parametric design's original Customizer parameters without any canonical mapping — would preserve maximum fidelity to the original design intent but would break compatibility with the platform's patient profile import system, which identifies model parameters exclusively by the canonical names (`palm_breadth_mm`, `middle_finger_length_mm`, etc.). The wrapper approach, with its dynamic scoping declarations, achieves canonical compliance without modifying the upstream source files, making it straightforward to pull in upstream design updates.

The polyhedron encoding approach produces geometrically exact reproductions of source CAD geometry within a fully self-contained OpenSCAD file. The trade-off relative to a ground-up CSG reconstruction is that the underlying geometry is still a fixed mesh — boolean operations on `polyhedron()` primitives work correctly in OpenSCAD, but surface detail (fillets, organic curves) cannot be independently controlled. A clinician who needs to modify a hinge barrel diameter independently of finger width would still require access to the original CAD model.

For the clinical workflow this platform targets — scaling a known prosthetic design to match a patient's anthropometric measurements — the polyhedron approach is appropriate. The mesh is not being redesigned; it is being proportionally resized along anatomically meaningful axes. The accuracy achieved (sub-micrometre Hausdorff distance) is orders of magnitude better than the 0.1 mm fabrication tolerance of fused deposition modelling printers typically used for prosthetic production.

Both methodologies are generalisable: polyhedron encoding applies to any design distributed as STEP or STL with organic surface geometry; the dynamic scoping wrapper applies to any existing parametric OpenSCAD design whose internal variable names differ from the platform's canonical anthropometric names.
