#!/usr/bin/env python3
"""
gen_middle_finger_scad.py — Generate kinetic_hand_finger_middle.scad

Encodes the four middle-finger STL meshes as OpenSCAD polyhedron() calls
and wraps them in parametric scaling modules.
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
    # Load meshes
    f4 = trimesh.load(f"{BASE}/models/kinetic_hand/finger_4.stl", force='mesh')
    f5 = trimesh.load(f"{BASE}/models/kinetic_hand/finger_5.stl", force='mesh')
    h4 = trimesh.load(f"{BASE}/models/kinetic_hand/hinge_4.stl", force='mesh')
    h5 = trimesh.load(f"{BASE}/models/kinetic_hand/hinge_5.stl", force='mesh')

    # Compute key reference dimensions
    # finger reach = distance from bottom of hinge_4 to top of finger_5
    ref_reach = f5.bounds[1, 2] - h4.bounds[0, 2]  # 202.386 - 148.366 = 54.02
    # Or finger bottom to finger_5 top (anatomical finger portion):
    finger_reach = f5.bounds[1, 2] - f4.bounds[0, 2]  # 202.386 - 153.993 = 48.39

    out = []

    out.append("""// kinetic_hand_finger_middle.scad
// Middle finger unit — Kinetic Hand RH60
//
// Parts: proximal phalanx (finger_4.stl), distal phalanx (finger_5.stl),
//        proximal joint hinge (hinge_4.stl), distal joint hinge (hinge_5.stl)
//
// Assembly coordinate frame (shared with all Kinetic Hand RH60 parts):
//   Z = 0    → wrist / gauntlet base
//   Z ≈ 154  → finger base / MCP knuckle line
//   Z ≈ 202  → fingertip
//
// Geometry is encoded as polyhedron() calls derived directly from the
// reference STL files. This gives 0.0 mm Hausdorff distance to the
// original at reference scale and requires no external STL imports.
//
// Parametric control
// ─────────────────
// middle_finger_length_mm  drives Z-stretch of the finger above FINGER_BASE_Z.
// The reference design (RH60 at scale 1.0) has:
//   anatomical MCP-to-tip = 72 mm
//   STL finger reach       = {:.2f} mm  (finger_5.z_max − finger_4.z_min)
//   ratio                  = {:.4f}  (held constant as middle_finger_length_mm changes)
//
// palm_breadth_mm drives uniform XY scale.
//
// ─────────────────────────────────────────────────────────────────────
""".format(finger_reach, finger_reach / 72.0))

    out.append("""/* [Anthropometric inputs] */

// Middle finger MCP crease to fingertip — anatomical measurement (mm)
middle_finger_length_mm = 72;   // [40:120]

// Knuckle-to-knuckle palm width — drives XY scale (mm)
palm_breadth_mm = 83;           // [50:120]

/* [Visibility] */
show_proximal_phalanx  = true;
show_distal_phalanx    = true;
show_hinges            = true;

/* [Hidden] */

// ── Reference dimensions ─────────────────────────────────────────────
REF_FINGER    = 72;      // anatomical MCP-to-tip at scale 1.0 (mm)
REF_PALM      = 83;      // palm breadth at scale 1.0 (mm)
REF_REACH     = {:.4f}; // STL finger reach in assembly space at scale 1.0 (mm)
                         // = finger_5.z_max − finger_4.z_min
FINGER_BASE_Z = 154;     // assembly Z where fingers begin (palm top)

// ── Derived scale factors ─────────────────────────────────────────────
// s_xy  — uniform XY scale driven by palm_breadth_mm
// s_fz  — finger Z multiplier above FINGER_BASE_Z, driven by
//          middle_finger_length_mm and then normalised by s_xy
s_xy = palm_breadth_mm  / REF_PALM;
s_fz = (middle_finger_length_mm / REF_FINGER) / s_xy;

// ── Scaling helper ────────────────────────────────────────────────────
// Applies uniform XY scale and finger-Z stretch above FINGER_BASE_Z.
// The pivot point is FINGER_BASE_Z so the palm-top stays fixed while
// the fingers grow or shrink upward.
module finger_transform() {{
    translate([0, 0, FINGER_BASE_Z * s_xy])
    scale([s_xy, s_xy, s_xy * s_fz])
    translate([0, 0, -FINGER_BASE_Z])
    children();
}}

// ── Assembly module ───────────────────────────────────────────────────
// Places all four parts in their assembly positions (same coordinate
// frame as the source STLs).
module middle_finger() {{
    finger_transform() {{
        if (show_proximal_phalanx) proximal_phalanx();
        if (show_distal_phalanx)   distal_phalanx();
        if (show_hinges) {{
            finger_hinge(hinge="proximal");
            finger_hinge(hinge="distal");
        }}
    }}
}}

// Shared hinge module — select "proximal" or "distal"
module finger_hinge(hinge="proximal") {{
    if (hinge == "proximal") finger_hinge_proximal();
    else                     finger_hinge_distal();
}}

// ── Render ────────────────────────────────────────────────────────────
middle_finger();

// ── Part modules ─────────────────────────────────────────────────────
// Each module encodes the reference geometry as a polyhedron().
// All coordinates are in the shared assembly frame (Z=0 at wrist base).
// Parametric scaling is applied by finger_transform() in middle_finger().

""".format(finger_reach))

    out.append(mesh_to_polyhedron_module(
        f4, "proximal_phalanx",
        "Proximal phalanx — finger_4.stl (middle finger, MCP-to-PIP segment)"))
    out.append("")

    out.append(mesh_to_polyhedron_module(
        f5, "distal_phalanx",
        "Distal phalanx — finger_5.stl (middle finger, PIP-to-tip segment)"))
    out.append("")

    out.append(mesh_to_polyhedron_module(
        h4, "finger_hinge_proximal",
        "Proximal joint hinge — hinge_4.stl (MCP hinge, Z≈148–160)"))
    out.append("")

    out.append(mesh_to_polyhedron_module(
        h5, "finger_hinge_distal",
        "Distal joint hinge — hinge_5.stl (PIP hinge, Z≈162–174)"))
    out.append("")

    return "\n".join(out)

if __name__ == "__main__":
    content = main()
    out_path = f"{BASE}/models/kinetic_hand_finger_middle.scad"
    with open(out_path, 'w') as f:
        f.write(content)
    print(f"Written: {out_path}", file=sys.stderr)
    print(f"Size: {len(content)/1024:.1f} KB", file=sys.stderr)
