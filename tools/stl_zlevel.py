#!/usr/bin/env python3
"""
stl_zlevel.py — Phase 2 Z-level structure analysis.

Finds discrete height levels, face areas at each level, and vertex
coordinates at each Z-level for prismatic part decomposition.

Usage:
    python3 tools/stl_zlevel.py <file.stl> [--axis x|y|z] [--tol TOL] [--vertices] [--json]
"""

import argparse
import json
import sys
import numpy as np

def analyze(path, axis='z', tol=0.01, show_vertices=False):
    import trimesh
    mesh = trimesh.load(path, force='mesh')

    ax = {'x': 0, 'y': 1, 'z': 2}[axis]

    # Find unique levels along the axis
    coords = mesh.vertices[:, ax]
    unique = np.unique(np.round(coords, 3))

    # Cluster close values
    clusters = []
    current = [unique[0]]
    for v in unique[1:]:
        if v - current[-1] < tol:
            current.append(v)
        else:
            clusters.append(np.mean(current))
            current = [v]
    clusters.append(np.mean(current))
    levels = np.array(clusters)

    # For each face, compute face centroid component and normal component
    face_centroids = mesh.triangles_center[:, ax]
    face_normals = mesh.face_normals[:, ax]
    face_areas = mesh.area_faces

    # Build per-level stats
    level_stats = []
    for i, lv in enumerate(levels):
        # Faces whose centroid is within tol of this level
        mask = np.abs(face_centroids - lv) < tol
        if not np.any(mask):
            continue

        up_mask = mask & (face_normals > 0.9)
        down_mask = mask & (face_normals < -0.9)
        up_area = float(np.sum(face_areas[up_mask]))
        down_area = float(np.sum(face_areas[down_mask]))

        # Vertices at this level
        vert_mask = np.abs(mesh.vertices[:, ax] - lv) < tol
        verts_at_level = mesh.vertices[vert_mask]

        entry = {
            "level": float(lv),
            "n_faces": int(np.sum(mask)),
            "up_area_mm2": round(up_area, 4),
            "down_area_mm2": round(down_area, 4),
            "n_vertices": int(np.sum(vert_mask)),
        }
        if show_vertices:
            other_axes = [a for a in range(3) if a != ax]
            entry["vertices"] = sorted(
                [[round(float(v[other_axes[0]]), 4), round(float(v[other_axes[1]]), 4)]
                 for v in verts_at_level],
                key=lambda p: (round(p[0], 1), round(p[1], 1))
            )
        level_stats.append(entry)

    # Count unique values per axis to suggest extrusion axis
    unique_counts = {}
    for a, name in enumerate(['x', 'y', 'z']):
        uc = len(np.unique(np.round(mesh.vertices[:, a], 2)))
        unique_counts[name] = uc

    result = {
        "file": path,
        "axis": axis,
        "n_levels": len(levels),
        "unique_coords_per_axis": unique_counts,
        "levels": level_stats,
    }
    return result

def main():
    parser = argparse.ArgumentParser(description="Find discrete height levels and face areas in an STL.")
    parser.add_argument("file", help="Path to STL file")
    parser.add_argument("--axis", choices=['x', 'y', 'z'], default='z', help="Analysis axis (default: z)")
    parser.add_argument("--tol", type=float, default=0.01, help="Clustering tolerance in mm (default: 0.01)")
    parser.add_argument("--vertices", action="store_true", help="Include vertex coords at each level")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    result = analyze(args.file, axis=args.axis, tol=args.tol, show_vertices=args.vertices)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"File: {result['file']}  axis={result['axis']}  levels={result['n_levels']}")
        print(f"Unique coords per axis: X={result['unique_coords_per_axis']['x']}  Y={result['unique_coords_per_axis']['y']}  Z={result['unique_coords_per_axis']['z']}")
        print()
        print(f"{'Level':>10}  {'Faces':>6}  {'UpArea':>10}  {'DnArea':>10}  {'Verts':>6}")
        print("-" * 50)
        for lv in result['levels']:
            print(f"{lv['level']:>10.3f}  {lv['n_faces']:>6}  {lv['up_area_mm2']:>10.4f}  {lv['down_area_mm2']:>10.4f}  {lv['n_vertices']:>6}")
            if args.vertices and 'vertices' in lv:
                for v in lv['vertices']:
                    print(f"             ({v[0]:.3f}, {v[1]:.3f})")

if __name__ == "__main__":
    main()
