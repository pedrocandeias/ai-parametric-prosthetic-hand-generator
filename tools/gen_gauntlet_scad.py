#!/usr/bin/env python3
"""
gen_gauntlet_scad.py — Generate kinetic_hand_gauntlet.scad

Encodes gauntlet.stl and gauntlet_cover.stl as OpenSCAD polyhedron()
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
    gauntlet = trimesh.load(f"{BASE}/models/kinetic_hand/gauntlet.stl", force='mesh')
    cover    = trimesh.load(f"{BASE}/models/kinetic_hand/gauntlet_cover.stl", force='mesh')

    # gauntlet_width_mm: X extent of gauntlet (left-right wrist width)
    ref_width = gauntlet.bounds[1, 0] - gauntlet.bounds[0, 0]  # ~62.36 mm

    # Cover position offsets relative to gauntlet origin (native assembly coords)
    # Cover sits at the back (high-Y) of the gauntlet
    cover_bb = cover.bounds
    gauntlet_bb = gauntlet.bounds

    cover_offset_x = 0  # cover is centered at X~0 same as gauntlet
    cover_offset_y = cover_bb[0, 1] - gauntlet_bb[0, 1]
    cover_offset_z = cover_bb[0, 2] - gauntlet_bb[0, 2]

    out = []

    out.append(f"""// kinetic_hand_gauntlet.scad
// Gauntlet and cover — Kinetic Hand RH60
//
// Parts: gauntlet body (gauntlet.stl), gauntlet cover (gauntlet_cover.stl)
//
// Assembly coordinate frame (shared with all Kinetic Hand RH60 parts):
//   Z = 0    → gauntlet base / wrist strap
//   Z ≈ 76   → gauntlet top (where palm socket begins)
//
// Geometry is encoded as polyhedron() calls derived directly from the
// reference STL files. This gives 0.0 mm Hausdorff distance to the
// original at reference scale.
//
// Parametric control
// ─────────────────
// gauntlet_width_mm  drives X scale (forearm socket width).
// The reference design has:
//   STL X extent = {ref_width:.3f} mm  (ref gauntlet_width_mm = 62)
//
// Derivation note (CLAUDE.md §Anthropometric Parameter Alignment):
//   gauntlet_width_mm has no direct platform anthropometric import.
//   Derive from wrist circumference: gauntlet_width_mm ≈ wrist_circumference_mm / π + clearance.
//
// Cover offset constants (in reference assembly space):
//   COVER_OFFSET_X = {cover_offset_x:.3f}
//   COVER_OFFSET_Y = {cover_offset_y:.3f}
//   COVER_OFFSET_Z = {cover_offset_z:.3f}
//
// ─────────────────────────────────────────────────────────────────────
""")

    out.append(f"""/* [Anthropometric inputs] */

// Forearm socket width (mm)
// Derive: gauntlet_width_mm ≈ wrist_circumference_mm / π + clearance
gauntlet_width_mm = 62; // [40:90]

/* [Visibility] */
show_gauntlet_body  = true;
show_gauntlet_cover = true;

/* [Hidden] */

// ── Reference dimensions ──────────────────────────────────────────────
REF_GAUNTLET_WIDTH = 62;   // gauntlet X extent at scale 1.0 (mm)

// Cover offset constants (assembly space, reference scale)
COVER_OFFSET_X = {cover_offset_x:.4f};
COVER_OFFSET_Y = {cover_offset_y:.4f};
COVER_OFFSET_Z = {cover_offset_z:.4f};

// ── Derived scale factors ─────────────────────────────────────────────
// Uniform scale: gauntlet_width_mm drives all three axes equally
// (the gauntlet is an organic wrist cuff — uniform scaling preserves form)
s_g = gauntlet_width_mm / REF_GAUNTLET_WIDTH;

// ── Scaling helpers ───────────────────────────────────────────────────
// Centre of gauntlet in assembly space (used as scale pivot)
GAUNTLET_CX = {(gauntlet_bb[0,0]+gauntlet_bb[1,0])/2:.4f};
GAUNTLET_CY = {(gauntlet_bb[0,1]+gauntlet_bb[1,1])/2:.4f};
GAUNTLET_CZ = 0;  // scale from base Z=0

module gauntlet_transform() {{
    translate([GAUNTLET_CX * s_g, GAUNTLET_CY * s_g, 0])
    scale([s_g, s_g, s_g])
    translate([-GAUNTLET_CX, -GAUNTLET_CY, 0])
    children();
}}

// ── Assembly module ───────────────────────────────────────────────────
module gauntlet_assembly() {{
    gauntlet_transform() {{
        if (show_gauntlet_body)  gauntlet_body();
        if (show_gauntlet_cover) gauntlet_cover();
    }}
}}

// ── Render ────────────────────────────────────────────────────────────
gauntlet_assembly();

// ── Part modules ─────────────────────────────────────────────────────
""")

    out.append(mesh_to_polyhedron_module(
        gauntlet, "gauntlet_body",
        f"Gauntlet body — gauntlet.stl (forearm socket)"))
    out.append("")

    out.append(mesh_to_polyhedron_module(
        cover, "gauntlet_cover",
        f"Gauntlet cover — gauntlet_cover.stl (dorsal cover panel)"))
    out.append("")

    return "\n".join(out)

if __name__ == "__main__":
    content = main()
    out_path = f"{BASE}/models/kinetic_hand_gauntlet.scad"
    with open(out_path, 'w') as f:
        f.write(content)
    print(f"Written: {out_path}", file=sys.stderr)
    print(f"Size: {len(content)/1024:.1f} KB", file=sys.stderr)
