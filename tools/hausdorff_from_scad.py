#!/usr/bin/env python3
"""
hausdorff_from_scad.py — Compute Hausdorff distance between polyhedron() in SCAD and reference STL.

Extracts the polyhedron mesh from a SCAD module, reconstructs it as a trimesh object,
and runs a bidirectional surface-sample Hausdorff comparison.

Usage:
    python3 tools/hausdorff_from_scad.py <scad_file> <module_name> <reference.stl> [--samples N] [--json]
"""

import argparse
import json
import re
import sys
import numpy as np


def extract_nested_block(text, keyword):
    """Find keyword=[ ... ] and return the inner content."""
    idx = text.find(keyword)
    if idx < 0:
        raise ValueError(f"Keyword '{keyword}' not found")
    bracket_start = text.find('[', idx)
    depth = 0
    pos = bracket_start
    while pos < len(text):
        if text[pos] == '[':
            depth += 1
        elif text[pos] == ']':
            depth -= 1
            if depth == 0:
                return text[bracket_start:pos+1], pos + 1
        pos += 1
    raise ValueError(f"Unmatched bracket after '{keyword}'")


def extract_polyhedron(scad_content, module_name):
    """Extract vertices and faces from a polyhedron() inside a named module."""
    idx = scad_content.find(f'module {module_name}()')
    if idx < 0:
        raise ValueError(f"Module '{module_name}' not found in SCAD")

    # Extract the module body (between matching braces)
    brace = scad_content.find('{', idx)
    depth = 0
    pos = brace
    while pos < len(scad_content):
        if scad_content[pos] == '{':
            depth += 1
        elif scad_content[pos] == '}':
            depth -= 1
            if depth == 0:
                break
        pos += 1
    body = scad_content[brace:pos+1]

    pts_block, _ = extract_nested_block(body, 'points=[')
    pts_raw = re.findall(r'\[([^\[\]]+)\]', pts_block)
    points = np.array([[float(v) for v in p.split(',')] for p in pts_raw])

    fcs_block, _ = extract_nested_block(body, 'faces=[')
    fcs_raw = re.findall(r'\[([^\[\]]+)\]', fcs_block)
    faces = np.array([[int(v) for v in f.split(',')] for f in fcs_raw])

    return points, faces


def compute_hausdorff(scad_path, module_name, stl_path, n_samples=20000):
    import trimesh

    with open(scad_path) as f:
        content = f.read()

    pts, fcs = extract_polyhedron(content, module_name)
    rec_mesh = trimesh.Trimesh(vertices=pts, faces=fcs, process=False)
    ref_mesh = trimesh.load(stl_path, force='mesh')

    ref_pts, _ = trimesh.sample.sample_surface(ref_mesh, n_samples)
    rec_pts, _ = trimesh.sample.sample_surface(rec_mesh, n_samples)

    _, d_fwd, _ = trimesh.proximity.closest_point(rec_mesh, ref_pts)
    _, d_bwd, _ = trimesh.proximity.closest_point(ref_mesh, rec_pts)

    all_d = np.concatenate([d_fwd, d_bwd])

    return {
        "scad": scad_path,
        "module": module_name,
        "stl": stl_path,
        "n_vertices_scad": len(pts),
        "n_faces_scad": len(fcs),
        "n_vertices_ref": len(ref_mesh.vertices),
        "n_faces_ref": len(ref_mesh.faces),
        "hausdorff_mm": float(max(d_fwd.max(), d_bwd.max())),
        "mean_mm": float(all_d.mean()),
        "p95_mm": float(np.percentile(all_d, 95)),
        "p99_mm": float(np.percentile(all_d, 99)),
        "volume_scad_mm3": float(rec_mesh.volume),
        "volume_ref_mm3": float(ref_mesh.volume),
        "volume_diff_mm3": float(abs(rec_mesh.volume - ref_mesh.volume)),
        "pass": bool(max(d_fwd.max(), d_bwd.max()) <= 0.1),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Hausdorff distance between SCAD polyhedron() and reference STL.")
    parser.add_argument("scad", help="Path to SCAD file")
    parser.add_argument("module", help="Module name containing the polyhedron")
    parser.add_argument("stl", help="Reference STL file")
    parser.add_argument("--samples", type=int, default=20000, help="Surface sample count (default: 20000)")
    parser.add_argument("--json", dest="as_json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    result = compute_hausdorff(args.scad, args.module, args.stl, args.samples)

    if args.as_json:
        print(json.dumps(result, indent=2))
    else:
        status = "PASS" if result["pass"] else "FAIL"
        print(f"Result: {status}  (target ≤ 0.1 mm)")
        print(f"Module      : {result['module']}")
        print(f"Hausdorff   : {result['hausdorff_mm']:.6f} mm")
        print(f"Mean dist   : {result['mean_mm']:.6f} mm")
        print(f"P95 dist    : {result['p95_mm']:.6f} mm")
        print(f"Volume diff : {result['volume_diff_mm3']:.4f} mm³")
        print(f"Vertices    : SCAD={result['n_vertices_scad']}  STL={result['n_vertices_ref']}")
        print(f"Faces       : SCAD={result['n_faces_scad']}  STL={result['n_faces_ref']}")


if __name__ == "__main__":
    main()
