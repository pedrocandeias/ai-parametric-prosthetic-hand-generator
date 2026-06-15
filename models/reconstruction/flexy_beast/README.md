# Flexy Beast — Gauntlet reconstruction (dev-only)

Source files and variants from reverse-engineering the forearm gauntlet. **None of
these are used by the platform** — they are excluded from deploy. The platform model
is `models/active/flexy_beast/flexy_beast.scad`, which already contains the finished
(primitive) gauntlet inlined.

| File | What it is |
|------|------------|
| `Normal_Gauntlet_w_Tensioner.stl` | Original source mesh that was reconstructed |
| `normal_gauntlet_w_tensioner.scad` | Organic reconstruction (lofts mesh-extracted wall profiles via BOSL2 `skin`) — needs `gauntlet_profiles.scad` + `gauntlet_straps.scad`. **Requires BOSL2** (not WASM-safe) |
| `gauntlet_profiles.scad` | Extracted cuff wall cross-sections (data) for the organic variant |
| `gauntlet_straps.scad` | Extracted strap station data |
| `normal_gauntlet_w_tensioner_primitive.scad` | Primitive rebuild — tapered oval half-pipe tunnel + features. No BOSL2 (OpenSCAD-WASM-safe). This is the version that was merged into `flexy_beast.scad` |
| `normal_gauntlet_w_tensioner_reconstructed.stl` | Exported organic reconstruction |
| `output/`, `previews/` | Build artifacts (regenerate on render) |

Coordinate frame (all variants): X = width, Y = forearm axis (+Y = wrist/proximal),
Z = dorsal up. ~75% geometric accuracy (organic) / volume within ~0.5% (primitive).
