#!/usr/bin/env python3
"""
compare_stl.py — Phase 7 bidirectional surface distance comparison.

Computes Hausdorff distance, volume difference, bounds match, and topology
between two STL files. Samples 50k points on each surface.

Usage:
    python3 tools/compare_stl.py <reference.stl> <reconstructed.stl> [--samples N] [--json]
"""

import argparse
import json
import sys
import numpy as np

def compare(ref_path, rec_path, n_samples=50000):
    import trimesh

    ref = trimesh.load(ref_path, force='mesh')
    rec = trimesh.load(rec_path, force='mesh')

    # Sample points on each surface
    ref_pts, _ = trimesh.sample.sample_surface(ref, n_samples)
    rec_pts, _ = trimesh.sample.sample_surface(rec, n_samples)

    # Forward distances: ref → rec
    _, dists_fwd, _ = trimesh.proximity.closest_point(rec, ref_pts)
    # Backward distances: rec → ref
    _, dists_bwd, _ = trimesh.proximity.closest_point(ref, rec_pts)

    all_dists = np.concatenate([dists_fwd, dists_bwd])

    ref_bounds = ref.bounds
    rec_bounds = rec.bounds

    result = {
        "reference": ref_path,
        "reconstructed": rec_path,
        "samples": n_samples,
        "distance": {
            "mean_mm": float(np.mean(all_dists)),
            "max_mm": float(np.max(all_dists)),
            "p95_mm": float(np.percentile(all_dists, 95)),
            "p99_mm": float(np.percentile(all_dists, 99)),
            "hausdorff_mm": float(max(np.max(dists_fwd), np.max(dists_bwd))),
        },
        "forward_distance": {
            "mean_mm": float(np.mean(dists_fwd)),
            "max_mm": float(np.max(dists_fwd)),
        },
        "backward_distance": {
            "mean_mm": float(np.mean(dists_bwd)),
            "max_mm": float(np.max(dists_bwd)),
        },
        "volume": {
            "reference_mm3": float(ref.volume),
            "reconstructed_mm3": float(rec.volume),
            "diff_mm3": float(abs(rec.volume - ref.volume)),
            "diff_pct": float(abs(rec.volume - ref.volume) / ref.volume * 100) if ref.volume != 0 else None,
        },
        "bounds": {
            "reference": {
                "x": [float(ref_bounds[0][0]), float(ref_bounds[1][0])],
                "y": [float(ref_bounds[0][1]), float(ref_bounds[1][1])],
                "z": [float(ref_bounds[0][2]), float(ref_bounds[1][2])],
            },
            "reconstructed": {
                "x": [float(rec_bounds[0][0]), float(rec_bounds[1][0])],
                "y": [float(rec_bounds[0][1]), float(rec_bounds[1][1])],
                "z": [float(rec_bounds[0][2]), float(rec_bounds[1][2])],
            },
            "max_bounds_diff_mm": float(np.max(np.abs(ref_bounds - rec_bounds))),
        },
        "topology": {
            "reference_euler": int(ref.euler_number),
            "reconstructed_euler": int(rec.euler_number),
            "reference_watertight": bool(ref.is_watertight),
            "reconstructed_watertight": bool(rec.is_watertight),
        },
        "pass": float(max(np.max(dists_fwd), np.max(dists_bwd))) <= 0.1,
    }
    return result

def main():
    parser = argparse.ArgumentParser(description="Compare two STL files: Hausdorff distance, volume, bounds, topology.")
    parser.add_argument("reference", help="Reference (original) STL file")
    parser.add_argument("reconstructed", help="Reconstructed STL file to evaluate")
    parser.add_argument("--samples", type=int, default=50000, help="Number of surface sample points (default: 50000)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    result = compare(args.reference, args.reconstructed, n_samples=args.samples)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        d = result['distance']
        v = result['volume']
        b = result['bounds']
        t = result['topology']

        status = "PASS" if result['pass'] else "FAIL"
        print(f"Result: {status}")
        print()
        print(f"Hausdorff distance : {d['hausdorff_mm']:.4f} mm  (target ≤ 0.1 mm)")
        print(f"Mean distance      : {d['mean_mm']:.4f} mm")
        print(f"95th percentile    : {d['p95_mm']:.4f} mm")
        print(f"99th percentile    : {d['p99_mm']:.4f} mm")
        print(f"Max forward        : {result['forward_distance']['max_mm']:.4f} mm")
        print(f"Max backward       : {result['backward_distance']['max_mm']:.4f} mm")
        print()
        print(f"Volume reference   : {v['reference_mm3']:.2f} mm³")
        print(f"Volume reconstructed: {v['reconstructed_mm3']:.2f} mm³")
        print(f"Volume diff        : {v['diff_mm3']:.2f} mm³  ({v['diff_pct']:.2f}%)")
        print()
        print(f"Bounds max diff    : {b['max_bounds_diff_mm']:.4f} mm")
        print()
        print(f"Euler (ref/rec)    : {t['reference_euler']} / {t['reconstructed_euler']}")
        print(f"Watertight (ref/rec): {t['reference_watertight']} / {t['reconstructed_watertight']}")

if __name__ == "__main__":
    main()
