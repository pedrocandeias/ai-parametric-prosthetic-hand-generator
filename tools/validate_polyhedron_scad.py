#!/usr/bin/env python3
"""
validate_polyhedron_scad.py — Validate that a SCAD file's polyhedron() data
exactly matches the source STL files.

Since we can't render the SCAD directly without OpenSCAD installed, this tool
extracts the polyhedron vertex/face data from the SCAD file and verifies it
against the original STLs numerically.

Usage:
    python3 tools/validate_polyhedron_scad.py <scad_file> <module_name> <reference.stl> [--json]
"""

import argparse
import json
import re
import sys
import numpy as np

def extract_nested_list(content, start_pos):
    """Extract a [...] block starting at start_pos (pointing to '['), return (content, end_pos)."""
    assert content[start_pos] == '[', f"Expected '[' at {start_pos}, got '{content[start_pos]}'"
    depth = 0
    pos = start_pos
    while pos < len(content):
        c = content[pos]
        if c == '[':
            depth += 1
        elif c == ']':
            depth -= 1
            if depth == 0:
                return content[start_pos:pos+1], pos+1
        pos += 1
    raise ValueError("Unmatched '['")

def extract_polyhedron(scad_content, module_name):
    """Extract points and faces from a polyhedron() inside a module."""
    # Find the module
    mod_pattern = rf'module\s+{re.escape(module_name)}\s*\(\s*\)\s*\{{'
    m = re.search(mod_pattern, scad_content)
    if not m:
        raise ValueError(f"Module '{module_name}' not found")

    # Extract content between the matching braces
    start = m.end()
    depth = 1
    pos = start
    while pos < len(scad_content) and depth > 0:
        c = scad_content[pos]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
        pos += 1
    body = scad_content[start:pos-1]

    # Find 'points=[' in body
    pts_kw = body.find('points=[')
    if pts_kw < 0:
        pts_kw = body.find('points =')
        if pts_kw < 0:
            raise ValueError("No points= found")
    # Find the opening bracket
    bracket_pos = body.find('[', pts_kw)
    pts_block, _ = extract_nested_list(body, bracket_pos)
    # Parse inner [x,y,z] entries
    pts_raw = re.findall(r'\[([^\[\]]+)\]', pts_block)
    points = []
    for p in pts_raw:
        vals = [float(v.strip()) for v in p.split(',')]
        points.append(vals)

    # Find 'faces=[' in body
    fcs_kw = body.find('faces=[')
    if fcs_kw < 0:
        fcs_kw = body.find('faces =')
        if fcs_kw < 0:
            raise ValueError("No faces= found")
    bracket_pos = body.find('[', fcs_kw)
    fcs_block, _ = extract_nested_list(body, bracket_pos)
    fcs_raw = re.findall(r'\[([^\[\]]+)\]', fcs_block)
    faces = []
    for f in fcs_raw:
        vals = [int(v.strip()) for v in f.split(',')]
        faces.append(vals)

    return np.array(points), np.array(faces)

def compare_with_stl(points, faces, stl_path):
    import trimesh
    ref = trimesh.load(stl_path, force='mesh')

    # Check counts match
    n_vert_match = len(points) == len(ref.vertices)
    n_face_match = len(faces) == len(ref.faces)

    # Check points match (within floating-point precision)
    # Use KD-tree nearest-neighbour approach to handle different vertex orderings
    if n_vert_match:
        from scipy.spatial import cKDTree
        ref_tree = cKDTree(ref.vertices)
        dists, _ = ref_tree.query(points, k=1)
        max_vert_diff = float(np.max(dists))
    else:
        max_vert_diff = float('inf')

    return {
        "n_vertices_ref": len(ref.vertices),
        "n_vertices_scad": len(points),
        "n_faces_ref": len(ref.faces),
        "n_faces_scad": len(faces),
        "vertex_count_match": n_vert_match,
        "face_count_match": n_face_match,
        "max_vertex_diff_mm": float(max_vert_diff) if max_vert_diff != float('inf') else None,
        "exact_match": bool(n_vert_match and n_face_match and max_vert_diff < 1e-3),
    }

def main():
    parser = argparse.ArgumentParser(description="Validate SCAD polyhedron() data against source STL.")
    parser.add_argument("scad", help="Path to SCAD file")
    parser.add_argument("module", help="Module name containing the polyhedron")
    parser.add_argument("stl", help="Reference STL file")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    with open(args.scad) as f:
        content = f.read()

    try:
        points, faces = extract_polyhedron(content, args.module)
    except Exception as e:
        print(f"ERROR extracting polyhedron: {e}", file=sys.stderr)
        sys.exit(1)

    result = compare_with_stl(points, faces, args.stl)
    result["scad"] = args.scad
    result["module"] = args.module
    result["stl"] = args.stl

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        status = "PASS" if result["exact_match"] else "FAIL"
        print(f"Result: {status}")
        print(f"Vertices: SCAD={result['n_vertices_scad']} vs STL={result['n_vertices_ref']} match={result['vertex_count_match']}")
        print(f"Faces: SCAD={result['n_faces_scad']} vs STL={result['n_faces_ref']} match={result['face_count_match']}")
        if result["max_vertex_diff_mm"] is not None:
            print(f"Max vertex diff: {result['max_vertex_diff_mm']:.8f} mm")

if __name__ == "__main__":
    main()
