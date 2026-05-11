#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import cadquery as cq
import trimesh


HERE = Path(__file__).resolve().parent
DEFAULT_STEP = HERE / "e_nable_phoenix_hand_v3.step"
REFERENCE_DIR = HERE / "e-NABLE Phoenix Hand v3 "
RECONSTRUCT = HERE.parent.parent / "tools" / "reconstruct.py"
DEFAULT_OUTPUT = HERE / "e_nable_phoenix_hand_v3.scad"


def sanitize_module_name(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    if slug and slug[0].isdigit():
        slug = f"part_{slug}"
    return slug or "part"


def mesh_signature(mesh: trimesh.Trimesh) -> dict:
    extents = [float(x) for x in mesh.extents]
    bounds = mesh.bounds
    center = [float(x) for x in mesh.bounding_box.centroid]
    return {
        "extents": extents,
        "bounds": {
            "x": [float(bounds[0, 0]), float(bounds[1, 0])],
            "y": [float(bounds[0, 1]), float(bounds[1, 1])],
            "z": [float(bounds[0, 2]), float(bounds[1, 2])],
        },
        "center": center,
        "volume": float(abs(mesh.volume)) if mesh.is_volume else 0.0,
        "faces": int(len(mesh.faces)),
        "vertices": int(len(mesh.vertices)),
    }


def signature_score(a: dict, b: dict) -> float:
    def rel_sum(xs: list[float], ys: list[float]) -> float:
        total = 0.0
        for x, y in zip(xs, ys):
            denom = max(abs(y), 1e-6)
            total += abs(x - y) / denom
        return total

    ext = rel_sum(sorted(a["extents"]), sorted(b["extents"]))
    ctr = rel_sum(a["center"], b["center"])
    vol = abs(a["volume"] - b["volume"]) / max(abs(b["volume"]), 1e-6)
    return ext * 10.0 + ctr + vol * 3.0


def load_reference_meshes(reference_dir: Path) -> dict[str, dict]:
    refs: dict[str, dict] = {}
    for path in sorted(reference_dir.glob("*.stl")):
        mesh = trimesh.load_mesh(path, force="mesh")
        refs[path.stem] = {
            "path": path,
            "signature": mesh_signature(mesh),
        }
    if not refs:
        raise FileNotFoundError(f"No reference STLs found in {reference_dir}")
    return refs


def export_solids(step_path: Path, out_dir: Path) -> list[dict]:
    imported = cq.importers.importStep(str(step_path))
    solids = imported.val().Solids()
    if not solids:
        raise RuntimeError(f"No solids found in {step_path}")

    exported: list[dict] = []
    for index, solid in enumerate(solids, start=1):
        stl_path = out_dir / f"solid_{index:02d}.stl"
        cq.exporters.export(
            solid,
            str(stl_path),
            cq.exporters.ExportTypes.STL,
            tolerance=0.05,
            angularTolerance=0.05,
        )
        mesh = trimesh.load_mesh(stl_path, force="mesh")
        exported.append(
            {
                "index": index,
                "stl_path": stl_path,
                "signature": mesh_signature(mesh),
            }
        )
    return exported


def match_parts(solids: list[dict], refs: dict[str, dict]) -> list[dict]:
    unmatched_refs = set(refs.keys())
    matched: list[dict] = []

    for solid in solids:
        candidates = sorted(
            (
                (signature_score(solid["signature"], refs[name]["signature"]), name)
                for name in unmatched_refs
            ),
            key=lambda item: item[0],
        )
        best_score, best_name = candidates[0]
        solid["match_name"] = best_name
        solid["match_score"] = best_score
        solid["reference_path"] = refs[best_name]["path"]
        matched.append(solid)
        unmatched_refs.remove(best_name)

    matched.sort(key=lambda item: item["match_name"])
    return matched


def build_mapping_report(matched: list[dict]) -> list[dict]:
    report = []
    for item in matched:
        report.append(
            {
                "solid_index": item["index"],
                "module_name": sanitize_module_name(item["match_name"]),
                "reference_name": item["match_name"],
                "match_score": round(item["match_score"], 6),
                "stl_path": str(item["stl_path"]),
                "reference_path": str(item["reference_path"]),
                "signature": item["signature"],
            }
        )
    return report


def run_reconstruct(matched: list[dict], output_path: Path) -> None:
    stl_paths = [str(item["stl_path"]) for item in matched]
    module_names = [sanitize_module_name(item["match_name"]) for item in matched]
    cmd = [
        sys.executable,
        str(RECONSTRUCT),
        *stl_paths,
        "--modules",
        *module_names,
        "--assembly",
        "e_nable_phoenix_hand_v3",
        "--output",
        str(output_path),
    ]
    subprocess.run(cmd, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert the Phoenix Hand STEP assembly into native OpenSCAD polyhedra."
    )
    parser.add_argument("step", nargs="?", type=Path, default=DEFAULT_STEP)
    parser.add_argument("-o", "--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--mapping-json",
        type=Path,
        default=HERE / "e_nable_phoenix_hand_v3.mapping.json",
    )
    args = parser.parse_args()

    refs = load_reference_meshes(REFERENCE_DIR)
    with tempfile.TemporaryDirectory(prefix="phoenix_step_") as tmpdir:
        solids = export_solids(args.step, Path(tmpdir))
        if len(solids) != len(refs):
            raise RuntimeError(
                f"STEP solid count ({len(solids)}) does not match reference STL count ({len(refs)})"
            )
        matched = match_parts(solids, refs)
        args.mapping_json.write_text(json.dumps(build_mapping_report(matched), indent=2))
        run_reconstruct(matched, args.output)

    print(f"Wrote {args.output}")
    print(f"Wrote {args.mapping_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
