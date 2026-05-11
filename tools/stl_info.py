#!/usr/bin/env python3
"""
stl_info.py — Phase 1 mesh triage tool.

Reports vertex/face counts, bounding box, volume, watertightness,
Euler number, genus, and connected components for an STL file.

Usage:
    python3 tools/stl_info.py <file.stl> [--json]
"""

import argparse
import json
import sys
import numpy as np

def analyze(path):
    import trimesh
    mesh = trimesh.load(path, force='mesh')
    bb = mesh.bounds
    extents = mesh.extents
    euler = mesh.euler_number
    genus = (2 - euler) // 2

    components = trimesh.graph.connected_components(mesh.face_adjacency)
    n_components = len(components)

    info = {
        "file": path,
        "vertices": int(len(mesh.vertices)),
        "faces": int(len(mesh.faces)),
        "bounds": {
            "x": [float(bb[0][0]), float(bb[1][0])],
            "y": [float(bb[0][1]), float(bb[1][1])],
            "z": [float(bb[0][2]), float(bb[1][2])],
        },
        "extents_mm": {
            "x": float(extents[0]),
            "y": float(extents[1]),
            "z": float(extents[2]),
        },
        "volume_mm3": float(mesh.volume),
        "is_watertight": bool(mesh.is_watertight),
        "euler_number": int(euler),
        "genus": int(genus),
        "n_components": int(n_components),
        "center_of_mass": [float(v) for v in mesh.center_mass],
    }
    return info

def main():
    parser = argparse.ArgumentParser(description="STL mesh triage: stats, topology, genus, components.")
    parser.add_argument("file", help="Path to STL file")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    info = analyze(args.file)

    if args.json:
        print(json.dumps(info, indent=2))
    else:
        print(f"File       : {info['file']}")
        print(f"Vertices   : {info['vertices']}")
        print(f"Faces      : {info['faces']}")
        print(f"Bounds X   : {info['bounds']['x'][0]:.3f} → {info['bounds']['x'][1]:.3f}  ({info['extents_mm']['x']:.3f} mm)")
        print(f"Bounds Y   : {info['bounds']['y'][0]:.3f} → {info['bounds']['y'][1]:.3f}  ({info['extents_mm']['y']:.3f} mm)")
        print(f"Bounds Z   : {info['bounds']['z'][0]:.3f} → {info['bounds']['z'][1]:.3f}  ({info['extents_mm']['z']:.3f} mm)")
        print(f"Volume     : {info['volume_mm3']:.2f} mm³")
        print(f"Watertight : {info['is_watertight']}")
        print(f"Euler χ    : {info['euler_number']}")
        print(f"Genus      : {info['genus']}  (= through-holes)")
        print(f"Components : {info['n_components']}")
        print(f"Center     : {info['center_of_mass']}")

if __name__ == "__main__":
    main()
