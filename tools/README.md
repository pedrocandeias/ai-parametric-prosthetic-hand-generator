# STL Analysis Tools

Reusable CLI tools for the Kinetic Hand RH60 STL-to-OpenSCAD reconstruction project.
All tools support `--help` and `--json` flags.

## Tools

### stl_info.py — Phase 1: Mesh triage

```
python3 tools/stl_info.py <file.stl> [--json]
```

Reports: vertex/face counts, bounding box, volume, watertightness, Euler number, genus, components.

### stl_zlevel.py — Phase 2: Z-level structure

```
python3 tools/stl_zlevel.py <file.stl> [--axis x|y|z] [--tol TOL] [--vertices] [--json]
```

Finds discrete height levels, face areas at each level, and vertex coordinates.
Use `--vertices` to print all vertex positions at each level (useful for corner detection).

### stl_cross_section.py — Phase 3–4: Cross-section analysis

```
python3 tools/stl_cross_section.py <file.stl> [--axis x|y|z] [--at Z...] [--simplify TOL] [--json]
```

Slices the mesh at specified heights and classifies polygons (rectangle, circle, L-shape, ring/annulus).
Automatically selects midpoints of each layer if `--at` is not specified.

### stl_normals.py — Phase 4: Face normal grouping

```
python3 tools/stl_normals.py <file.stl> [--tol TOL] [--json]
```

Groups faces by normal direction to separate planar (±X/Y/Z) from curved (radial, oblique) surfaces.
Reports total area per group and centroid Z-range. Detects simple vertical cylinder clusters.

### compare_stl.py — Phase 7: STL-vs-STL comparison

```
python3 tools/compare_stl.py <reference.stl> <reconstructed.stl> [--samples N] [--json]
```

Bidirectional surface-sample Hausdorff distance (default 50k samples per mesh).
Reports mean/max/p95/p99 distances, volume difference, bounds match, and topology.
PASS threshold: Hausdorff ≤ 0.1 mm.

### hausdorff_from_scad.py — Phase 7: SCAD polyhedron validation

```
python3 tools/hausdorff_from_scad.py <scad_file> <module_name> <reference.stl> [--samples N] [--json]
```

Extracts the `polyhedron()` geometry from a named SCAD module, reconstructs it as a mesh,
and computes Hausdorff distance against the reference STL. Useful when OpenSCAD is not
installed for rendering. PASS threshold: Hausdorff ≤ 0.1 mm.

### validate_polyhedron_scad.py — Phase 5: Polyhedron data verification

```
python3 tools/validate_polyhedron_scad.py <scad_file> <module_name> <reference.stl> [--json]
```

Verifies that the vertex/face data in a SCAD `polyhedron()` module exactly matches the source STL
(using KD-tree nearest-neighbour comparison, threshold < 0.001 mm).

### reconstruct.py — Automated STL-to-OpenSCAD pipeline

```
python3 tools/reconstruct.py <file.stl> [<file2.stl> ...] [options]
```

End-to-end automation: triage → strategy selection → polyhedron() or CSG skeleton → SCAD output → auto-validation.

**Options:**
- `--module NAME` — module name for single-STL mode
- `--modules N1 N2 ...` — module names for multi-STL mode (one per STL)
- `--assembly NAME` — wrap all modules in a named assembly module
- `--param KEY=VALUE ...` — anthropometric parameters to surface in the Customizer
- `--organic-threshold F` — oblique-face ratio cutoff for polyhedron vs CSG (default: 0.40)
- `--output FILE` — write to file (default: stdout)
- `--triage-only` — print mesh stats and exit without generating SCAD
- `--validate SCAD` — compare existing SCAD against source STL(s) and report Hausdorff distance
- `--json` — machine-readable output

**Strategy selection:** parts with oblique-face ratio ≥ threshold are encoded as `polyhedron()` (exact mesh reproduction). Parts below the threshold receive a CSG bounding-box skeleton with TODO markers for manual completion.

**Examples:**
```bash
# Single part — auto strategy, auto-validated
python3 tools/reconstruct.py models/kinetic_hand/finger_4.stl \
    --module proximal_phalanx \
    --param middle_finger_length_mm=72 palm_breadth_mm=83 \
    --output models/finger_proximal.scad

# Multiple parts with assembly module
python3 tools/reconstruct.py \
    models/kinetic_hand/finger_4.stl \
    models/kinetic_hand/finger_5.stl \
    models/kinetic_hand/hinge_4.stl \
    --modules proximal_phalanx distal_phalanx finger_hinge \
    --assembly middle_finger \
    --param middle_finger_length_mm=72 palm_breadth_mm=83 \
    --output models/middle_finger.scad

# Triage only — useful before committing to reconstruction
python3 tools/reconstruct.py models/kinetic_hand/palm.stl --triage-only

# Validate existing SCAD
python3 tools/reconstruct.py models/kinetic_hand/finger_4.stl \
    --validate models/kinetic_hand_finger_middle.scad \
    --module proximal_phalanx
```

### gen_middle_finger_scad.py — Generator for middle finger SCAD

```
python3 tools/gen_middle_finger_scad.py
```

Generates `models/kinetic_hand_finger_middle.scad` from the four source STL files.
Re-run after modifying the generator script or if the source STLs change.

## Quick-start workflow

```bash
# Phase 1
python3 tools/stl_info.py models/kinetic_hand/finger_4.stl

# Phase 2
python3 tools/stl_zlevel.py models/kinetic_hand/finger_4.stl --vertices

# Phase 3–4
python3 tools/stl_cross_section.py models/kinetic_hand/finger_4.stl
python3 tools/stl_normals.py models/kinetic_hand/finger_4.stl

# Phase 7 (after rendering with OpenSCAD)
python3 tools/compare_stl.py models/kinetic_hand/finger_4.stl output.stl

# Phase 7 (without rendering, for polyhedron-based SCAD)
python3 tools/hausdorff_from_scad.py models/kinetic_hand_finger_middle.scad proximal_phalanx models/kinetic_hand/finger_4.stl
```
