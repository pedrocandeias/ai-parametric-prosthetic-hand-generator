#!/usr/bin/env python3
"""
gen_wrist_scad.py — Generate kinetic_hand_wrist.scad

Encodes wrist_hinge_1.stl and wrist_hinge_2.stl as OpenSCAD polyhedron()
calls and wraps them in parametric scaling modules.
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
    wh1 = trimesh.load(f"{BASE}/models/kinetic_hand/wrist_hinge_1.stl", force='mesh')
    wh2 = trimesh.load(f"{BASE}/models/kinetic_hand/wrist_hinge_2.stl", force='mesh')

    bb1 = wh1.bounds
    bb2 = wh2.bounds

    # Hinge 1 is the right-side hinge (positive X), hinge 2 is the left-side (negative X)
    # Offset constants: native assembly coordinates — no translation needed
    wh1_x = (bb1[0, 0] + bb1[1, 0]) / 2
    wh1_y = (bb1[0, 1] + bb1[1, 1]) / 2
    wh1_z = bb1[0, 2]

    wh2_x = (bb2[0, 0] + bb2[1, 0]) / 2
    wh2_y = (bb2[0, 1] + bb2[1, 1]) / 2
    wh2_z = bb2[0, 2]

    # The pair spans from wh2.x_min to wh1.x_max
    ref_span = bb1[1, 0] - bb2[0, 0]

    out = []

    out.append(f"""// kinetic_hand_wrist.scad
// Wrist hinges — Kinetic Hand RH60
//
// Parts: wrist_hinge_1.stl (right/+X side), wrist_hinge_2.stl (left/-X side)
//
// Assembly coordinate frame (shared with all Kinetic Hand RH60 parts):
//   Z = 0    → gauntlet base
//   Z ≈ 68   → wrist hinge base
//   Z ≈ 87   → wrist hinge top (gauntlet-to-palm transition)
//
// Geometry is encoded as polyhedron() calls derived directly from the
// reference STL files. This gives 0.0 mm Hausdorff distance to the
// original at reference scale.
//
// Parametric control
// ─────────────────
// gauntlet_width_mm drives uniform scale (wrist hinges scale with gauntlet).
// Reference span (hinge_1.x_max − hinge_2.x_min) = {ref_span:.3f} mm at scale 1.0.
//
// Offset constants (reference assembly space):
//   WRIST_HINGE1_OFFSET_X = {bb1[0,0]:.3f} (x_min of hinge_1)
//   WRIST_HINGE1_OFFSET_Y = {bb1[0,1]:.3f} (y_min of hinge_1)
//   WRIST_HINGE1_OFFSET_Z = {bb1[0,2]:.3f} (z_min of hinge_1)
//   WRIST_HINGE2_OFFSET_X = {bb2[0,0]:.3f} (x_min of hinge_2)
//   WRIST_HINGE2_OFFSET_Y = {bb2[0,1]:.3f} (y_min of hinge_2)
//   WRIST_HINGE2_OFFSET_Z = {bb2[0,2]:.3f} (z_min of hinge_2)
//
// ─────────────────────────────────────────────────────────────────────
""")

    out.append(f"""/* [Anthropometric inputs] */

// Forearm socket width — drives wrist hinge scale with the gauntlet (mm)
gauntlet_width_mm = 62; // [40:90]

/* [Visibility] */
show_wrist_hinge_1 = true;
show_wrist_hinge_2 = true;

/* [Hidden] */

// ── Reference dimensions ──────────────────────────────────────────────
REF_GAUNTLET_WIDTH = 62;   // gauntlet_width_mm at scale 1.0 (mm)
REF_HINGE_SPAN     = {ref_span:.4f}; // hinge_1.x_max − hinge_2.x_min at scale 1.0

// Hinge offset constants (assembly space, reference scale)
WRIST_HINGE1_OFFSET_X = {bb1[0,0]:.4f};
WRIST_HINGE1_OFFSET_Y = {bb1[0,1]:.4f};
WRIST_HINGE1_OFFSET_Z = {bb1[0,2]:.4f};
WRIST_HINGE2_OFFSET_X = {bb2[0,0]:.4f};
WRIST_HINGE2_OFFSET_Y = {bb2[0,1]:.4f};
WRIST_HINGE2_OFFSET_Z = {bb2[0,2]:.4f};

// ── Derived scale factors ─────────────────────────────────────────────
s_w = gauntlet_width_mm / REF_GAUNTLET_WIDTH;

// ── Scaling helper ────────────────────────────────────────────────────
// Uniform scale from Z=0 base, centred on X=0 axis
module wrist_transform() {{
    scale([s_w, s_w, s_w])
    children();
}}

// ── Assembly module ───────────────────────────────────────────────────
module wrist_assembly() {{
    wrist_transform() {{
        if (show_wrist_hinge_1) wrist_hinge_1();
        if (show_wrist_hinge_2) wrist_hinge_2();
    }}
}}

// ── Render ────────────────────────────────────────────────────────────
wrist_assembly();

// ── Part modules ─────────────────────────────────────────────────────
""")

    out.append(mesh_to_polyhedron_module(
        wh1, "wrist_hinge_1",
        f"Wrist hinge 1 (right/+X) — wrist_hinge_1.stl (Z={bb1[0,2]:.3f}–{bb1[1,2]:.3f})"))
    out.append("")

    out.append(mesh_to_polyhedron_module(
        wh2, "wrist_hinge_2",
        f"Wrist hinge 2 (left/-X) — wrist_hinge_2.stl (Z={bb2[0,2]:.3f}–{bb2[1,2]:.3f})"))
    out.append("")

    return "\n".join(out)

if __name__ == "__main__":
    content = main()
    out_path = f"{BASE}/models/kinetic_hand_wrist.scad"
    with open(out_path, 'w') as f:
        f.write(content)
    print(f"Written: {out_path}", file=sys.stderr)
    print(f"Size: {len(content)/1024:.1f} KB", file=sys.stderr)
