#!/usr/bin/env python3
"""
Convert Kinetic Hand RH60 STEP files to binary STL and extract assembly placements.
Outputs: models/kinetic_hand/*.stl  +  assembly placement data to stdout.
"""
import cadquery as cq
import os, sys, json, math
from pathlib import Path

STEP_DIR = Path(__file__).parent.parent / "models" / "Kinetic Hand STEP Files RH60"
OUT_DIR  = Path(__file__).parent.parent / "models" / "kinetic_hand"
OUT_DIR.mkdir(exist_ok=True)

# Map filename → safe output name
PARTS = {
    "Palm RH60.STEP":          "palm",
    "Palm cover RH60.STEP":    "palm_cover",
    "Gauntlet RH60.STEP":      "gauntlet",
    "Gauntlet cover RH60.STEP":"gauntlet_cover",
    "Tensioner RH60.STEP":     "tensioner",
    "Finger 1 RH60.STEP":      "finger_1",
    "Finger 2 RH60.STEP":      "finger_2",
    "Finger 3 RH60.STEP":      "finger_3",
    "Finger 4 RH60.STEP":      "finger_4",
    "Finger 5 RH60.STEP":      "finger_5",
    "Finger 6 RH60.STEP":      "finger_6",
    "Finger 7 RH60.STEP":      "finger_7",
    "Finger 8 RH60.STEP":      "finger_8",
    "Finger 9 RH60.STEP":      "finger_9",
    "Grip 1 RH60.STEP":        "grip_1",
    "Grip 3 RH60.STEP":        "grip_3",
    "Grip 5 RH60.STEP":        "grip_5",
    "Grip 7 RH60.STEP":        "grip_7",
    "Grip 9 RH60.STEP":        "grip_9",
    "Hinge 1 RH60.STEP":       "hinge_1",
    "Hinge 2 RH60.STEP":       "hinge_2",
    "Hinge 3 RH60.STEP":       "hinge_3",
    "Hinge 4 RH60.STEP":       "hinge_4",
    "Hinge 5 RH60.STEP":       "hinge_5",
    "Hinge 6 RH60.STEP":       "hinge_6",
    "Hinge 7 RH60.STEP":       "hinge_7",
    "Hinge 8 RH60.STEP":       "hinge_8",
    "Hinge 9 RH60.STEP":       "hinge_9",
    "Wrist Hinge 1 RH60.STEP": "wrist_hinge_1",
    "Wrist Hinge 2 RH60.STEP": "wrist_hinge_2",
    "All Hinges thickened RH60.STEP": "all_hinges",
}

results = {}

for step_name, safe_name in PARTS.items():
    step_path = STEP_DIR / step_name
    stl_path  = OUT_DIR / f"{safe_name}.stl"

    if not step_path.exists():
        print(f"MISSING: {step_name}", file=sys.stderr)
        continue

    if stl_path.exists():
        print(f"SKIP (exists): {safe_name}.stl")
    else:
        print(f"Converting: {step_name} → {safe_name}.stl ...", end=" ", flush=True)
        try:
            shape = cq.importers.importStep(str(step_path))
            cq.exporters.export(shape, str(stl_path), cq.exporters.ExportTypes.STL,
                                tolerance=0.1, angularTolerance=0.1)
            print("OK")
        except Exception as e:
            print(f"ERROR: {e}", file=sys.stderr)
            continue

    # Get bounding box for placement info
    try:
        shape = cq.importers.importStep(str(step_path))
        bb = shape.val().BoundingBox()
        results[safe_name] = {
            "file": f"kinetic_hand/{safe_name}.stl",
            "bbox": {
                "x": [round(bb.xmin,2), round(bb.xmax,2)],
                "y": [round(bb.ymin,2), round(bb.ymax,2)],
                "z": [round(bb.zmin,2), round(bb.zmax,2)],
            },
            "center": [
                round((bb.xmin+bb.xmax)/2, 2),
                round((bb.ymin+bb.ymax)/2, 2),
                round((bb.zmin+bb.zmax)/2, 2),
            ]
        }
    except Exception as e:
        print(f"BBox error for {safe_name}: {e}", file=sys.stderr)

print("\n=== Placement data ===")
print(json.dumps(results, indent=2))

# Write placement data for use by SCAD generator
with open(OUT_DIR / "placements.json", "w") as f:
    json.dump(results, f, indent=2)
print(f"\nWrote placements.json to {OUT_DIR}")
