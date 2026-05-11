#!/usr/bin/env python3
"""
stl_cross_section.py — Phase 3–4 cross-section analysis.

Slices the STL at specified heights and classifies the resulting 2D polygons
(rectangles, circles, L-shapes, etc.) with simplified vertices.

Usage:
    python3 tools/stl_cross_section.py <file.stl> [--axis x|y|z] [--at Z [Z ...]] [--simplify TOL] [--json]

If --at is not specified, slices at the midpoint of each layer pair found
by stl_zlevel.py logic.
"""

import argparse
import json
import sys
import numpy as np

def classify_polygon(n_verts, has_holes):
    if n_verts <= 5:
        return "rectangle"
    elif n_verts <= 9:
        return "L-shape or pentagon"
    elif n_verts <= 16:
        return "complex polygon"
    else:
        if has_holes:
            return "ring/annulus"
        return "circle/arc"

def analyze(path, axis='z', at_values=None, simplify_tol=0.05):
    import trimesh
    from shapely.geometry import Polygon

    mesh = trimesh.load(path, force='mesh')
    ax = {'x': 0, 'y': 1, 'z': 2}[axis]
    normal = np.zeros(3)
    normal[ax] = 1

    # Determine slice positions
    if at_values is None:
        coords = mesh.vertices[:, ax]
        unique = np.unique(np.round(coords, 2))
        # find midpoints between consecutive unique values that differ by > 0.5mm
        gaps = []
        for i in range(len(unique) - 1):
            if unique[i+1] - unique[i] > 0.5:
                gaps.append((unique[i] + unique[i+1]) / 2.0)
        at_values = gaps if gaps else [(mesh.bounds[0][ax] + mesh.bounds[1][ax]) / 2]

    sections = []
    for pos in at_values:
        origin = np.zeros(3)
        origin[ax] = pos

        try:
            section = mesh.section(plane_origin=origin, plane_normal=normal)
        except Exception as e:
            sections.append({"at": float(pos), "error": str(e), "polygons": []})
            continue

        if section is None:
            sections.append({"at": float(pos), "polygons": []})
            continue

        try:
            planar, to_3d = section.to_planar()
        except Exception as e:
            sections.append({"at": float(pos), "error": str(e), "polygons": []})
            continue

        polys = []
        for poly in planar.polygons_full:
            # Simplify
            simplified = poly.simplify(simplify_tol, preserve_topology=True)

            # Transform exterior to 3D world coords
            ext_coords = np.array(simplified.exterior.coords)
            # Add the planar dimension back
            ext_3d = np.column_stack([
                ext_coords,
                np.zeros(len(ext_coords))
            ])
            world_coords = trimesh.transform_points(ext_3d, to_3d)

            # Get the two non-axis coordinates
            axes = [0, 1, 2]
            axes.remove(ax)
            a1, a2 = axes

            n_ext = len(ext_coords) - 1  # last == first for closed ring
            has_holes = len(list(simplified.interiors)) > 0

            # Bounds of exterior
            ext_arr = np.array(simplified.exterior.coords)
            bounds = {
                "u_min": float(np.min(ext_arr[:, 0])),
                "u_max": float(np.max(ext_arr[:, 0])),
                "v_min": float(np.min(ext_arr[:, 1])),
                "v_max": float(np.max(ext_arr[:, 1])),
            }

            # World-space bounds
            world_ext = world_coords[:, [a1, a2]]
            world_bounds = {
                f"{['x','y','z'][a1]}_min": float(np.min(world_ext[:, 0])),
                f"{['x','y','z'][a1]}_max": float(np.max(world_ext[:, 0])),
                f"{['x','y','z'][a2]}_min": float(np.min(world_ext[:, 1])),
                f"{['x','y','z'][a2]}_max": float(np.max(world_ext[:, 1])),
            }

            hole_info = []
            for interior in simplified.interiors:
                h_coords = np.array(interior.coords)
                h_3d = np.column_stack([h_coords, np.zeros(len(h_coords))])
                h_world = trimesh.transform_points(h_3d, to_3d)
                hole_info.append({
                    "n_vertices": len(h_coords) - 1,
                    "bounds": {
                        f"{['x','y','z'][a1]}_min": float(np.min(h_world[:, a1])),
                        f"{['x','y','z'][a1]}_max": float(np.max(h_world[:, a1])),
                        f"{['x','y','z'][a2]}_min": float(np.min(h_world[:, a2])),
                        f"{['x','y','z'][a2]}_max": float(np.max(h_world[:, a2])),
                    },
                    "center": [
                        float(np.mean(h_world[:, a1])),
                        float(np.mean(h_world[:, a2])),
                    ],
                    "approx_radius": float(np.mean(np.sqrt(
                        (h_world[:, a1] - np.mean(h_world[:, a1]))**2 +
                        (h_world[:, a2] - np.mean(h_world[:, a2]))**2
                    ))),
                })

            polys.append({
                "n_exterior_vertices": n_ext,
                "has_holes": has_holes,
                "type": classify_polygon(n_ext, has_holes),
                "area_mm2": float(poly.area),
                "world_bounds": world_bounds,
                "world_exterior_vertices": [[round(float(v[a1]), 4), round(float(v[a2]), 4)]
                                            for v in world_coords[:-1]],
                "holes": hole_info,
            })

        sections.append({
            "at": float(pos),
            "n_polygons": len(polys),
            "polygons": polys,
        })

    return {
        "file": path,
        "axis": axis,
        "sections": sections,
    }

def main():
    parser = argparse.ArgumentParser(description="Slice STL and classify 2D cross-section polygons.")
    parser.add_argument("file", help="Path to STL file")
    parser.add_argument("--axis", choices=['x', 'y', 'z'], default='z', help="Slice axis (default: z)")
    parser.add_argument("--at", type=float, nargs='+', help="Explicit slice positions along the axis")
    parser.add_argument("--simplify", type=float, default=0.05, help="Shapely simplification tolerance in mm (default: 0.05)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    result = analyze(args.file, axis=args.axis, at_values=args.at, simplify_tol=args.simplify)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"File: {result['file']}  axis={result['axis']}")
        for sec in result['sections']:
            print(f"\n--- Slice at {result['axis']}={sec['at']:.3f} ---")
            if 'error' in sec:
                print(f"  ERROR: {sec['error']}")
                continue
            print(f"  Polygons: {sec.get('n_polygons', 0)}")
            for i, p in enumerate(sec.get('polygons', [])):
                print(f"  [{i}] type={p['type']}  verts={p['n_exterior_vertices']}  area={p['area_mm2']:.2f}mm²  holes={len(p['holes'])}")
                wb = p['world_bounds']
                keys = list(wb.keys())
                if len(keys) >= 4:
                    print(f"       world: {keys[0]}={wb[keys[0]]:.3f}→{wb[keys[1]]:.3f}  {keys[2]}={wb[keys[2]]:.3f}→{wb[keys[3]]:.3f}")
                for j, h in enumerate(p['holes']):
                    print(f"       hole[{j}]: verts={h['n_vertices']}  center=({h['center'][0]:.3f},{h['center'][1]:.3f})  r≈{h['approx_radius']:.3f}")

if __name__ == "__main__":
    main()
