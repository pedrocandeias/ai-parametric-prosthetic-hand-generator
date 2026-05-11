# Kinetic Hand RH60 — STL-to-SCAD Conversion Notes

## What was done

The Kinetic Hand RH60 was originally designed in SolidWorks 2023 and distributed as a set of STEP files. To integrate it into this platform, each structural part was exported from the STEP assembly to binary STL via CadQuery/OpenCASCADE, and a thin OpenSCAD wrapper (`kinetic_hand_rh60.scad`) was written to assemble and scale them.

The SCAD file does not redefine any geometry. It only:
- `import()`s each STL part
- applies `scale()` transforms to groups of parts
- exposes visibility toggles for each part group

This is fundamentally different from a native parametric SCAD model (like the RBE580 or Phoenix hand), where every dimension is computed from input parameters and the geometry is rebuilt on every render.

## Assembly coordinate space

All 24 STL parts share a common coordinate frame derived from the original SolidWorks assembly:

| Z position | Landmark |
|---|---|
| Z = 0 | Wrist / gauntlet base |
| Z ≈ 79 mm | Gauntlet-palm junction (palm body begins) |
| Z ≈ 154 mm | MCP knuckle line (finger bases) |
| Z ≈ 200 mm | Fingertips |

This coordinate space is preserved exactly in the STL files. The SCAD wrapper applies transforms in world space around these known landmarks.

## Scale modules and what they control

Three scale modules were written to allow independent control of different anatomical regions:

```
gauntlet_scale()  — scale([s_gx, s_gx, 1])
                    XY-only: socket width, no Z change (socket depth is fixed by residual limb)

palm_scale()      — anchored at Z=79, scale([s_hand, s_hy, s_plz])
                    X by palm breadth, Y by palm thickness, Z by palm length

finger_scale()    — anchored at the dynamic knuckle line (79 + 75 × s_plz),
                    scale([s_hand, s_hy, s_hand × s_fz])
                    X/Z by palm breadth, Y by palm thickness, Z additionally by finger length

thumb_scale()     — anchored at estimated thumb MCP Z (≈110 mm),
                    scale([s_hand, s_hy, s_tz])
                    X/Y follow palm, Z independently by thumb length
```

## Parameters that work reliably

| Parameter | Why it works |
|---|---|
| `palm_breadth_mm` | Uniform XZ scale — all parts in the hand group scale together; mating interfaces remain proportional |
| `middle_finger_length_mm` | Scales finger Z as a self-contained group (proximal + distal phalanges + hinges) with no hard interface to a differently-scaled part at the tip |
| `gauntlet_width_mm` | Uniform XY scale of the gauntlet group only; the gauntlet-palm junction is a sliding/socket fit that tolerates minor XY mismatch |

The common property: each of these either scales all axes uniformly, or scales a sub-group that has no rigid mating interface with a differently-scaled neighbour.

## Parameters that are problematic on an STL wrapper

### `palm_thickness_mm` (Y-axis stretch)

Stretches every hand part along Y. Parts still physically mate because the same `s_hy` factor is applied everywhere, but the internal geometry distorts:

- Cylindrical hinge pin bores become oval
- Wall thicknesses grow non-uniformly (thicker in Y, unchanged in X/Z)
- Curved palm surfaces flatten or bulge

For visual inspection of fit this is acceptable. For printable, functional parts it is not — pin clearances and cable routing channels will be wrong.

### `palm_length_mm` (palm Z stretch, different anchor from fingers)

The palm STL is stretched in Z from its base at Z=79. The finger STLs are anchored separately at the (now-shifted) knuckle line. At non-default values:

- The palm top surface moves to a new Z position
- The finger STL bases are translated to match, but the *interface features* on the palm (hinge seats, peg holes) are embedded in the palm mesh and move with the Z-stretch, while the corresponding features on the finger STLs are fixed in the finger mesh and only translated
- Result: interface features will misalign whenever `palm_length_mm ≠ 95`

### `thumb_length_mm` (thumb Z stretch from a different anchor than palm)

The thumb attachment is somewhere around Z=110 in the assembly. The palm is stretched from Z=79 with `s_plz`, which moves the palm's thumb socket feature. The thumb STL is stretched from Z=110 with `s_tz`. Unless `s_plz = s_tz` exactly, the two interface surfaces diverge.

## What a proper fix would require

To make all six anthropometric parameters work correctly on the Kinetic Hand, the model would need to be rewritten as a native parametric SCAD file — geometry computed from parameters, not stretched meshes. This means:

1. Exporting the SolidWorks parts as neutral mesh data and reconstructing their cross-sections
2. Rebuilding each part in SCAD primitives with dimensions driven by the anthropometric inputs
3. Computing all interface features (hinge pin positions, cable routing holes, palm socket) from the same parameter set so they remain aligned at any input value

Alternatively, the STEP files could be re-parameterised in SolidWorks directly and re-exported at discrete patient size variants.

## Current state

The wrapper exposes three parameters that scale reliably:

- `palm_breadth_mm` — uniform hand XZ scale
- `middle_finger_length_mm` — finger Z scale
- `gauntlet_width_mm` — gauntlet XY scale

The three additional parameters (`palm_length_mm`, `palm_thickness_mm`, `thumb_length_mm`) were implemented and then removed because the STL wrapper cannot satisfy their geometric constraints without distorting or misaligning mating interfaces.
