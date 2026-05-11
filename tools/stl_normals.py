#!/usr/bin/env python3
"""
stl_normals.py — Phase 4 face normal grouping for feature detection.

Groups faces by normal direction to separate planar faces (axis-aligned)
from curved surfaces (cylinder walls). Helps identify cylinder axes and
find hidden features.

Usage:
    python3 tools/stl_normals.py <file.stl> [--tol TOL] [--json]
"""

import argparse
import json
import sys
import numpy as np

def analyze(path, tol=0.01):
    import trimesh
    mesh = trimesh.load(path, force='mesh')

    normals = mesh.face_normals
    areas = mesh.area_faces
    centroids = mesh.triangles_center

    groups = {
        "+X": [], "-X": [], "+Y": [], "-Y": [], "+Z": [], "-Z": [],
        "radial_XY": [], "radial_XZ": [], "radial_YZ": [], "oblique": []
    }

    for i, (n, a, c) in enumerate(zip(normals, areas, centroids)):
        if n[2] > 1 - tol:
            groups["+Z"].append(i)
        elif n[2] < -(1 - tol):
            groups["-Z"].append(i)
        elif n[0] > 1 - tol:
            groups["+X"].append(i)
        elif n[0] < -(1 - tol):
            groups["-X"].append(i)
        elif n[1] > 1 - tol:
            groups["+Y"].append(i)
        elif n[1] < -(1 - tol):
            groups["-Y"].append(i)
        elif abs(n[2]) < tol:
            # Horizontal cylinder wall (axis is Z)
            groups["radial_XY"].append(i)
        elif abs(n[1]) < tol:
            # Cylinder wall with axis along Y
            groups["radial_XZ"].append(i)
        elif abs(n[0]) < tol:
            # Cylinder wall with axis along X
            groups["radial_YZ"].append(i)
        else:
            groups["oblique"].append(i)

    summary = {}
    for gname, idxs in groups.items():
        if not idxs:
            continue
        idxs = np.array(idxs)
        total_area = float(np.sum(areas[idxs]))
        c = centroids[idxs]
        summary[gname] = {
            "n_faces": len(idxs),
            "total_area_mm2": round(total_area, 4),
            "centroid_range": {
                "x": [round(float(np.min(c[:, 0])), 3), round(float(np.max(c[:, 0])), 3)],
                "y": [round(float(np.min(c[:, 1])), 3), round(float(np.max(c[:, 1])), 3)],
                "z": [round(float(np.min(c[:, 2])), 3), round(float(np.max(c[:, 2])), 3)],
            }
        }

    # For radial_XY faces (vertical cylinders), try to cluster by XY centroid to find cylinder centers
    cylinders = []
    if "radial_XY" in summary:
        idxs = np.array(groups["radial_XY"])
        xy = centroids[idxs, :2]
        # Simple k-means style: just look at the range and count peaks
        from scipy import ndimage
        from collections import defaultdict

        # Build a 2D histogram
        x_range = [xy[:, 0].min(), xy[:, 0].max()]
        y_range = [xy[:, 1].min(), xy[:, 1].max()]

        # If range is small, likely a single cylinder
        x_span = x_range[1] - x_range[0]
        y_span = y_range[1] - y_range[0]

        if x_span < 5 and y_span < 5:
            center = [float(np.mean(xy[:, 0])), float(np.mean(xy[:, 1]))]
            # Estimate radius from distance from center
            dists = np.sqrt((xy[:, 0] - center[0])**2 + (xy[:, 1] - center[1])**2)
            cylinders.append({
                "axis": "Z",
                "center_xy": center,
                "approx_radius_mm": round(float(np.mean(dists)), 3),
                "z_range": [round(float(centroids[idxs, 2].min()), 3), round(float(centroids[idxs, 2].max()), 3)],
                "n_faces": len(idxs),
            })
        else:
            # Multiple cylinders - use clustering
            try:
                from sklearn.cluster import DBSCAN
                clustering = DBSCAN(eps=2.0, min_samples=3).fit(xy)
                labels = clustering.labels_
                for label in set(labels):
                    if label < 0:
                        continue
                    mask = labels == label
                    sub_xy = xy[mask]
                    center = [float(np.mean(sub_xy[:, 0])), float(np.mean(sub_xy[:, 1]))]
                    dists = np.sqrt((sub_xy[:, 0] - center[0])**2 + (sub_xy[:, 1] - center[1])**2)
                    sub_idxs = idxs[mask]
                    cylinders.append({
                        "axis": "Z",
                        "center_xy": center,
                        "approx_radius_mm": round(float(np.mean(dists)), 3),
                        "z_range": [round(float(centroids[sub_idxs, 2].min()), 3), round(float(centroids[sub_idxs, 2].max()), 3)],
                        "n_faces": int(np.sum(mask)),
                    })
            except ImportError:
                # No sklearn, just report range
                pass

    return {
        "file": path,
        "total_faces": int(len(normals)),
        "groups": summary,
        "detected_cylinders": cylinders,
    }

def main():
    parser = argparse.ArgumentParser(description="Group face normals to detect planar and cylindrical features.")
    parser.add_argument("file", help="Path to STL file")
    parser.add_argument("--tol", type=float, default=0.01, help="Normal axis-alignment tolerance (default: 0.01)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    result = analyze(args.file, tol=args.tol)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"File: {result['file']}  total_faces={result['total_faces']}")
        print()
        print(f"{'Group':<12}  {'Faces':>6}  {'Area mm²':>10}  Centroid Z-range")
        print("-" * 60)
        for gname, g in result['groups'].items():
            zr = g['centroid_range']['z']
            print(f"{gname:<12}  {g['n_faces']:>6}  {g['total_area_mm2']:>10.2f}  {zr[0]:.2f}→{zr[1]:.2f}")
        if result['detected_cylinders']:
            print()
            print("Detected cylinders:")
            for cyl in result['detected_cylinders']:
                print(f"  axis={cyl['axis']}  center=({cyl['center_xy'][0]:.3f},{cyl['center_xy'][1]:.3f})  r≈{cyl['approx_radius_mm']:.3f}  Z={cyl['z_range']}")

if __name__ == "__main__":
    main()
