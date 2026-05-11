# SKILL: STL to Parametric OpenSCAD Reconstruction

## Goal

Reverse-engineer a binary/ASCII STL mesh file into a clean, parametric OpenSCAD source file that reproduces the original geometry within a specified tolerance (e.g. 0.1mm Hausdorff distance).

In this project the target parts are the Kinetic Hand RH60 prosthetic hand components located in `models/kinetic_hand/`. The recommended reconstruction order is: middle finger (proximal + distal phalanx + hinge) → thumb → palm → gauntlet + cover → wrist hinges. See `SPEC.md` for the full specification and `docs/kinetic_hand_rh60_conversion.md` for why the current STL wrapper approach cannot support full anthropometric parametrization.

## When to Use

- You have an STL file of a mechanical prosthetic part and need an editable parametric source
- The part is primarily composed of prismatic (box-like) and cylindrical features — not organic/sculpted shapes
- You need the output to be human-readable and customizable via OpenSCAD Customizer, not just a mesh re-export
- You are reconstructing a Kinetic Hand RH60 part so that anthropometric parameters (`palm_breadth_mm`, `palm_length_mm`, `palm_thickness_mm`, `middle_finger_length_mm`, `thumb_length_mm`, `gauntlet_width_mm`) can drive geometry directly instead of stretching a fixed mesh

## Prerequisites

- **Python packages**: `numpy`, `trimesh`, `scipy`, `shapely`, `networkx`, `rtree`, `numpy-stl`
- **System packages**: `openscad`
- Install with: `pip3 install numpy trimesh scipy shapely networkx rtree numpy-stl` and `sudo apt-get install openscad`

## High-Level Approach

### Phase 1: Mesh Triage

Load the STL with `trimesh` and gather key statistics to understand the scope:

- **Vertex/face count**: Determines complexity. Under ~5k faces is likely a machined/printed part with clean geometry.
- **Bounding box and extents**: Gives the overall dimensions.
- **Volume and watertightness**: Confirms the mesh is valid and closed.
- **Euler number**: Computes genus (number of through-holes). Formula: `genus = (2 - euler_number) / 2`. This tells you how many holes to find.

### Phase 2: Identify Z-Level Structure

For prismatic parts (brackets, enclosures, mounts, phalanges), the geometry is almost always built from features extruded along one principal axis. Identify which axis that is by examining the unique coordinate values of vertices.

1. **Find unique vertex coordinates** along each axis (rounded to ~3 decimal places). The axis with the fewest unique values is the extrusion/stacking axis.
2. **List the discrete levels** on that axis. Each pair of adjacent levels defines a "layer" of constant cross-section.
3. **Count up-facing and down-facing face areas** at each level. Up-facing faces at a Z-level mark the *top* of a feature; down-facing faces mark the *bottom* of a feature starting at that height. The area values serve as checksums for your reconstruction.

### Phase 3: Cross-Section Analysis

Take planar cross-sections at the midpoint of each layer using `trimesh.section()`:

1. **Slice the mesh** at each intermediate Z value.
2. **Convert to 2D polygons** via `section.to_planar()` and examine the `polygons_full` property.
3. **Simplify polygons** with Shapely's `.simplify()` to reduce curved arcs to key vertices while preserving corners.
4. **Transform back to world coordinates** using the planar transform matrix to get actual XY positions.
5. **Record each polygon's exterior and interior (hole) boundaries**. Note how many vertices remain after simplification — a 5-point polygon is a rectangle, a 9-point polygon is an L-shape, a 17-point polygon is a circle approximation, etc.

Track how the cross-section *changes* between layers — this reveals where features start, end, merge, or split.

### Phase 4: Identify Geometric Primitives

From the cross-section data, decompose the shape into CSG primitives:

- **Rectangles** (5 simplified vertices = box cross-section): Record corner coordinates, extrusion height range.
- **L-shapes / U-shapes** (9+ vertices): Decompose into union of rectangles, or model as rectangle-minus-rectangle.
- **Circles / arcs** (17+ vertices after simplification): Compute center as midpoint of extremes, radius as half the span. Verify by checking vertex distances from the computed center — they should all equal the radius.
- **Rings/annuli** (polygon with circular hole): Outer and inner radius from the exterior and interior boundaries.

For each primitive, determine:
- XY bounds or center+radius
- Z range (which layers it spans)
- Whether it's additive (part of the union) or subtractive (a hole to difference out)

### Phase 5: Cross-Validate with Vertex Grouping

For extra confidence, directly examine the raw vertices at each Z-level:

- Group vertices by their Z coordinate.
- For levels with few vertices (≤20), print them all — these directly reveal rectangle corners.
- For levels with many vertices, look for clusters. Compute distances from suspected circle centers and verify constant radius.
- Check that circle parameters (center, radius) are consistent across multiple Z-levels.

### Phase 6: Build the OpenSCAD Model

Structure the `.scad` file for readability and customization:

1. **Constants at the top** in OpenSCAD Customizer sections (`/* [Section Name] */`). Every dimension gets a named variable with a comment showing its physical meaning and original coordinate range. Anthropometric constants must use the canonical field names defined in `CLAUDE.md` (e.g. `palm_breadth_mm`, `middle_finger_length_mm`).
2. **One module per feature**: `proximal_body()`, `hinge_barrel()`, `cable_channel()`, `fingertip_cap()`, etc. Each module is self-contained and uses only the global constants.
3. **Assembly module**: A single top-level module that `union()`s all additive features, then `difference()`s all holes. This keeps the boolean logic clean and makes it easy to toggle features.
4. **Resolution control**: A single `$fn` parameter controls circle smoothness globally.

Modeling patterns:
- **Rectangular frame**: `difference()` of outer `cube()` minus inner `cube()`.
- **L-shaped plate**: `union()` of two overlapping `cube()` calls.
- **Through-hole**: `cylinder()` with height extending past the material (add 1mm on each side with `-1` offset and `+2` height to ensure clean boolean cuts).
- **Ring/post**: `cylinder()` for the outer, with a through `cylinder()` subtracted.
- **Hinge barrel**: Coaxial cylinders centered on the pivot axis, with pin bore subtracted.

### Phase 7: Render and Compare

1. **Render** with `openscad -o output.stl model.scad`.
2. **Compare** using a reusable Python comparison tool that computes:
   - **Bidirectional surface distance**: Sample 50k points on each surface, find nearest point on the other surface using `trimesh.nearest.on_surface()`. Report mean, max, 95th/99th percentile.
   - **Volume difference**: Compare `mesh.volume` values.
   - **Bounds match**: Check bounding boxes agree within tolerance.
   - **Topology match**: Compare Euler numbers.
3. **Iterate** if the Hausdorff distance exceeds the tolerance. Common fixes:
   - Wrong dimension by a small amount → re-examine vertex coordinates at that Z-level
   - Missing feature → look at the worst-mismatch sample points to locate the problem area
   - Circle approximation error → increase `$fn`

### Phase 8: Verify the Accuracy Target

The final gate is the bidirectional Hausdorff distance. The target for this project is **0.1mm** (per `SPEC.md`). The residual error from circle approximation at `$fn=64` is `r × (1 - cos(π/64))` ≈ 0.002mm for a 2mm-radius pin bore — well within tolerance.

## Key Lessons

1. **Z-level analysis is the critical insight for prismatic parts.** If the mesh has only a handful of unique Z values, the part is a stack of extruded profiles and can be exactly decomposed.
2. **Cross-sections + simplification finds the primitives fast.** Shapely's `simplify()` with a small tolerance (0.05–0.1mm) collapses arcs to their key points while preserving sharp corners.
3. **Euler number tells you how many holes to find.** Don't stop looking for features until you can account for all `(2 - χ) / 2` topological handles.
4. **Face normal grouping separates flat vs. curved surfaces.** Axis-aligned normals (±X, ±Y, ±Z) are planar faces; all others are cylinder walls. The Z-component of non-axis normals reveals whether cylinders are vertical (Z=0) or angled.
5. **Up/down face area sums serve as checksums.** Compute the expected area of each horizontal surface from your model parameters and verify it matches the STL. This catches dimension errors before rendering.
6. **Model in original coordinates, not relocated.** Keeping the STL's native coordinate system avoids translation errors and makes comparison trivial. For the Kinetic Hand this matters because all parts share the same assembly coordinate frame (Z=0 at wrist, Z≈154 at knuckle line).
7. **Build the comparison tool first.** A reusable `tools/compare_stl.py` with surface sampling and Hausdorff distance makes iteration fast and objective.

## Reusable Tools

All tools live in `tools/` with CLI interfaces, `--help`, and `--json` output.
See `tools/README.md` for full usage.

| Tool | Phase | Purpose |
|------|-------|---------|
| `tools/stl_info.py` | 1 | Mesh triage: stats, topology, genus, components |
| `tools/stl_zlevel.py` | 2 | Find discrete height levels, face areas, vertex coords |
| `tools/stl_cross_section.py` | 3–4 | Slice mesh, extract & classify 2D polygons |
| `tools/stl_normals.py` | 4 | Face normal grouping, cylinder feature detection |
| `tools/compare_stl.py` | 7 | Bidirectional Hausdorff distance, volume, topology |

### Quick-start workflow

```bash
python3 tools/stl_info.py models/kinetic_hand/finger_4.stl          # What am I dealing with?
python3 tools/stl_zlevel.py models/kinetic_hand/finger_4.stl --vertices   # Layer structure + corners
python3 tools/stl_cross_section.py models/kinetic_hand/finger_4.stl       # Auto-slice cross-sections
python3 tools/stl_normals.py models/kinetic_hand/finger_4.stl             # Find cylinders and holes
python3 tools/stl_cross_section.py models/kinetic_hand/finger_4.stl --axis x --at 0  # Hidden internals
# ... write OpenSCAD model ...
openscad -o models/kinetic_hand_rh60_output.stl models/kinetic_hand_rh60.scad
python3 tools/compare_stl.py models/kinetic_hand/finger_4.stl models/kinetic_hand_rh60_output.stl
```

## Deliverables

| File | Purpose |
|------|---------|
| `tools/` | Reusable analysis toolkit (see `tools/README.md`) |
| `models/kinetic_hand_rh60.scad` | Parametric OpenSCAD source replacing the STL wrapper |
| `models/kinetic_hand_rh60_output.stl` | Rendered STL for accuracy comparison |
| `plan.md` | Progress checklist with one entry per part, including failed approaches |
