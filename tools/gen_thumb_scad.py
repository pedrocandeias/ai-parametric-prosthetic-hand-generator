#!/usr/bin/env python3
"""
gen_thumb_scad.py — Generate kinetic_hand_thumb.scad

Encodes finger_1.stl (thumb body) and hinge_1.stl (thumb hinge) as
OpenSCAD polyhedron() calls and wraps them in parametric scaling modules.
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
    f1 = trimesh.load(f"{BASE}/models/kinetic_hand/finger_1.stl", force='mesh')
    h1 = trimesh.load(f"{BASE}/models/kinetic_hand/hinge_1.stl", force='mesh')

    # Thumb reach = top of finger_1 to bottom of hinge_1 (Z span of the whole thumb unit)
    thumb_reach = f1.bounds[1, 2] - h1.bounds[0, 2]
    # Anatomical thumb MCP-to-tip reference: 65 mm
    REF_THUMB_ANAT = 65.0

    # X/Y/Z offsets (native assembly coordinates, no translation needed)
    # Both parts sit in the same coordinate frame — we just record their Z origin for docs
    hinge_z_min = h1.bounds[0, 2]
    hinge_z_max = h1.bounds[1, 2]
    finger_z_min = f1.bounds[0, 2]
    finger_z_max = f1.bounds[1, 2]

    out = []

    out.append(f"""// kinetic_hand_thumb.scad
// Thumb unit — Kinetic Hand RH60
//
// Parts: thumb body (finger_1.stl), thumb hinge (hinge_1.stl)
//
// Assembly coordinate frame (shared with all Kinetic Hand RH60 parts):
//   Z = 0    → wrist / gauntlet base
//   Z ≈ 101  → thumb hinge base
//   Z ≈ 133  → thumb tip
//
// Geometry is encoded as polyhedron() calls derived directly from the
// reference STL files. This gives 0.0 mm Hausdorff distance to the
// original at reference scale.
//
// Parametric control
// ─────────────────
// thumb_length_mm  drives Z-stretch of the thumb above THUMB_BASE_Z.
// The reference design (RH60 at scale 1.0) has:
//   anatomical MCP-to-tip = {REF_THUMB_ANAT:.1f} mm
//   STL thumb reach       = {thumb_reach:.4f} mm  (finger_1.z_max − hinge_1.z_min)
//   ratio                 = {thumb_reach / REF_THUMB_ANAT:.4f}
//
// palm_breadth_mm drives uniform XY scale.
//
// Offset constants (in reference assembly space):
//   THUMB_FINGER_OFFSET_X = 0  (no translation, native coords used)
//   THUMB_FINGER_OFFSET_Y = 0
//   THUMB_FINGER_OFFSET_Z = 0
//   THUMB_HINGE_OFFSET_X  = 0
//   THUMB_HINGE_OFFSET_Y  = 0
//   THUMB_HINGE_OFFSET_Z  = 0
//
// ─────────────────────────────────────────────────────────────────────
""")

    out.append(f"""/* [Anthropometric inputs] */

// Thumb MCP crease to fingertip — anatomical measurement (mm)
thumb_length_mm = 65;   // [35:100]

// Knuckle-to-knuckle palm width — drives XY scale (mm)
palm_breadth_mm = 83;   // [50:120]

/* [Visibility] */
show_thumb_phalanx = true;
show_thumb_hinge   = true;

/* [Hidden] */

// ── Reference dimensions ──────────────────────────────────────────────
REF_THUMB     = {REF_THUMB_ANAT:.1f};   // anatomical MCP-to-tip at scale 1.0 (mm)
REF_PALM      = 83;      // palm breadth at scale 1.0 (mm)
REF_THUMB_REACH = {thumb_reach:.4f}; // STL thumb reach in assembly space at scale 1.0 (mm)
                          // = finger_1.z_max − hinge_1.z_min

// Part offset constants (reference assembly space — no translation required)
THUMB_FINGER_OFFSET_X = 0;
THUMB_FINGER_OFFSET_Y = 0;
THUMB_FINGER_OFFSET_Z = 0;
THUMB_HINGE_OFFSET_X  = 0;
THUMB_HINGE_OFFSET_Y  = 0;
THUMB_HINGE_OFFSET_Z  = 0;

THUMB_BASE_Z  = {hinge_z_min:.3f}; // assembly Z where thumb begins (hinge bottom)

// ── Derived scale factors ─────────────────────────────────────────────
// s_xy  — uniform XY scale driven by palm_breadth_mm
// s_tz  — thumb Z multiplier above THUMB_BASE_Z
s_xy = palm_breadth_mm / REF_PALM;
s_tz = (thumb_length_mm / REF_THUMB) / s_xy;

// ── Scaling helper ────────────────────────────────────────────────────
module thumb_transform() {{
    translate([0, 0, THUMB_BASE_Z * s_xy])
    scale([s_xy, s_xy, s_xy * s_tz])
    translate([0, 0, -THUMB_BASE_Z])
    children();
}}

// ── Assembly module ───────────────────────────────────────────────────
module thumb_assembly() {{
    thumb_transform() {{
        if (show_thumb_phalanx) thumb_phalanx();
        if (show_thumb_hinge)   thumb_hinge();
    }}
}}

// ── Render ────────────────────────────────────────────────────────────
thumb_assembly();

// ── Part modules ─────────────────────────────────────────────────────
""")

    out.append(mesh_to_polyhedron_module(
        f1, "thumb_phalanx",
        f"Thumb body — finger_1.stl (Z={finger_z_min:.3f}–{finger_z_max:.3f})"))
    out.append("")

    out.append(mesh_to_polyhedron_module(
        h1, "thumb_hinge",
        f"Thumb hinge — hinge_1.stl (Z={hinge_z_min:.3f}–{hinge_z_max:.3f})"))
    out.append("")

    return "\n".join(out)

if __name__ == "__main__":
    content = main()
    out_path = f"{BASE}/models/kinetic_hand_thumb.scad"
    with open(out_path, 'w') as f:
        f.write(content)
    print(f"Written: {out_path}", file=sys.stderr)
    print(f"Size: {len(content)/1024:.1f} KB", file=sys.stderr)
