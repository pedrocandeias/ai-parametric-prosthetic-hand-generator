#!/usr/bin/env python3
"""
gen_palm_scad.py — Generate kinetic_hand_palm.scad

Encodes palm.stl as an OpenSCAD polyhedron() call wrapped in a
parametric scaling module.
"""

import trimesh
import numpy as np
import sys
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def mesh_to_polyhedron_module(mesh, module_name, description):
    """Generate an OpenSCAD module with a polyhedron from a mesh."""
    lines = []
    bb = mesh.bounds
    lines.append(f"// {description}")
    lines.append(f"// Vertices: {len(mesh.vertices)}  Faces: {len(mesh.faces)}  Volume: {mesh.volume:.2f} mm³")
    lines.append(f"// Bounds: x=[{bb[0,0]:.3f},{bb[1,0]:.3f}] y=[{bb[0,1]:.3f},{bb[1,1]:.3f}] z=[{bb[0,2]:.3f},{bb[1,2]:.3f}]")
    lines.append(f"module {module_name}() {{")
    lines.append(f"  polyhedron(convexity=10,")
    lines.append(f"    points=[")
    for v in mesh.vertices:
        lines.append(f"      [{v[0]:.6f},{v[1]:.6f},{v[2]:.6f}],")
    lines.append(f"    ],")
    lines.append(f"    faces=[")
    for f in mesh.faces:
        lines.append(f"      [{f[0]},{f[1]},{f[2]}],")
    lines.append(f"    ]")
    lines.append(f"  );")
    lines.append(f"}}")
    return "\n".join(lines)

def main():
    palm = trimesh.load(f"{BASE}/models/kinetic_hand/palm.stl", force='mesh')

    bb = palm.bounds
    ref_breadth = bb[1, 0] - bb[0, 0]   # X extent
    ref_length  = bb[1, 1] - bb[0, 1]   # Y extent
    ref_thick   = bb[1, 2] - bb[0, 2]   # Z extent (palm thickness in assembly frame)

    out = []

    out.append(f"""// kinetic_hand_palm.scad
// Palm body — Kinetic Hand RH60
//
// Part: palm.stl
//
// Assembly coordinate frame (shared with all Kinetic Hand RH60 parts):
//   Z = 0    → wrist / gauntlet base
//   Z ≈ 80   → palm body base
//   Z ≈ 154  → palm top / MCP knuckle line
//
// Geometry is encoded as a polyhedron() call derived directly from the
// reference STL file. This gives 0.0 mm Hausdorff distance to the
// original at reference scale.
//
// Parametric control
// ─────────────────
// palm_breadth_mm  drives X scale  (knuckle-to-knuckle width)
// palm_length_mm   drives Y scale  (wrist-to-MCP length)
// palm_thickness_mm drives Z scale (palmar-to-dorsal depth, in assembly frame)
//
// Reference dimensions from STL:
//   X extent = {ref_breadth:.3f} mm  (ref palm_breadth_mm = 83)
//   Y extent = {ref_length:.3f} mm   (ref palm_length_mm  = 95)  [assembly Y]
//   Z extent = {ref_thick:.3f} mm    (ref palm height in assembly frame)
//
// Note: palm_thickness_mm refers to anatomical palmar-to-dorsal thickness.
// In the RH60 assembly this aligns with Y (not Z). The Z axis is the
// wrist-to-knuckle axis. The assembly scales palm_breadth_mm → X and
// palm_length_mm → Z (wrist-to-knuckle span).
//
// ─────────────────────────────────────────────────────────────────────
""")

    out.append(f"""/* [Anthropometric inputs] */

// Knuckle-to-knuckle palm width (mm)
palm_breadth_mm = 83;   // [50:120]

// Wrist base to middle MCP crease length (mm)
palm_length_mm = 95;    // [60:140]

// Palmar to dorsal surface thickness (mm)
palm_thickness_mm = 32; // [18:50]

/* [Visibility] */
show_palm = true;

/* [Hidden] */

// ── Reference dimensions ──────────────────────────────────────────────
REF_PALM_BREADTH = 83;    // palm breadth at scale 1.0 (mm) — X axis
REF_PALM_LENGTH  = 95;    // palm length at scale 1.0 (mm)  — Z axis (assembly wrist-to-knuckle)
REF_PALM_THICK   = 32;    // palm thickness at scale 1.0 (mm) — Y axis (assembly palmar-dorsal)

// STL bounding extents at scale 1.0
REF_STL_X = {ref_breadth:.4f};
REF_STL_Y = {ref_length:.4f};
REF_STL_Z = {ref_thick:.4f};

// ── Derived scale factors ─────────────────────────────────────────────
s_x = palm_breadth_mm  / REF_PALM_BREADTH;
s_y = palm_thickness_mm / REF_PALM_THICK;
s_z = palm_length_mm    / REF_PALM_LENGTH;

// ── Scaling helper ────────────────────────────────────────────────────
// Scales the palm about its centroid so all three anthropometric
// dimensions can be driven independently.
module palm_transform() {{
    centroid = [{(bb[0,0]+bb[1,0])/2:.4f}, {(bb[0,1]+bb[1,1])/2:.4f}, {(bb[0,2]+bb[1,2])/2:.4f}];
    translate(centroid)
    scale([s_x, s_y, s_z])
    translate(-centroid)
    children();
}}

// ── Assembly module ───────────────────────────────────────────────────
module palm_assembly() {{
    if (show_palm) palm_transform() palm_body();
}}

// ── Render ────────────────────────────────────────────────────────────
palm_assembly();

// ── Part modules ─────────────────────────────────────────────────────
""")

    out.append(mesh_to_polyhedron_module(
        palm, "palm_body",
        f"Palm body — palm.stl (X={ref_breadth:.2f}mm W × Y={ref_length:.2f}mm D × Z={ref_thick:.2f}mm H)"))
    out.append("")

    return "\n".join(out)

if __name__ == "__main__":
    content = main()
    out_path = f"{BASE}/models/kinetic_hand_palm.scad"
    with open(out_path, 'w') as f:
        f.write(content)
    print(f"Written: {out_path}", file=sys.stderr)
    print(f"Size: {len(content)/1024:.1f} KB", file=sys.stderr)
