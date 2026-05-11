# STL to OpenSCAD Reconstruction

You are running inside a Debian system with sudo, brew, python3 and whatever you need to accomplish this task.

Your job is to take the STL files in this workspace and reconstruct them using OpenSCAD, replacing the current STL-wrapper approach in `models/kinetic_hand_rh60.scad` with a fully parametric native SCAD model.

If an STL is too large or complex, you can try decimating it/using octrees/segmenting it/using marching cubes as needed.

Read `SKILL.md` before starting — it contains the full methodology, reusable tool descriptions, and key lessons from prior reconstruction work.

## Requirements

- The final STL file must be within 0.1mm accuracy of the original
- The OpenSCAD code must be modular, readable, and have relevant constants surfaced at the beginning for a customizer
- Anthropometric constants must use the canonical field names from `CLAUDE.md`: `palm_breadth_mm`, `palm_length_mm`, `palm_thickness_mm`, `middle_finger_length_mm`, `thumb_length_mm`, `gauntlet_width_mm`
- You should focus on building reusable tools, not one-off scripts
- You should maintain a `plan.md` file with your progress checklist and tick off items (including failed approaches) as you make progress

## Reconstruction Order

Work through the Kinetic Hand RH60 parts in this order. Each stage builds on the methodology and modules established by the previous one.

### Stage 1 — Middle finger unit (start here)

Files: `models/kinetic_hand/finger_4.stl` (proximal phalanx), `models/kinetic_hand/finger_5.stl` (distal phalanx), `models/kinetic_hand/hinge_4.stl` + `models/kinetic_hand/hinge_5.stl`

Why first: self-contained with no mating interfaces to differently-scaled parts; the module will be reused for all four fingers (8 phalanx STLs + 8 hinge STLs); validates the 0.1mm accuracy requirement before investing in larger parts; `middle_finger_length_mm` scaling is the primary anthropometric output of this stage.

### Stage 2 — Thumb

Files: `models/kinetic_hand/finger_1.stl`, `models/kinetic_hand/hinge_1.stl`

Different proportions from the four fingers and a single-piece design with no proximal/distal split. Establishes `thumb_length_mm` as an independent scale driver.

### Stage 3 — Palm

Files: `models/kinetic_hand/palm.stl`

Most geometrically complex part. By this stage the design language is established. Palm drives `palm_breadth_mm`, `palm_length_mm`, and `palm_thickness_mm`.

### Stage 4 — Gauntlet and cover

Files: `models/kinetic_hand/gauntlet.stl`, `models/kinetic_hand/gauntlet_cover.stl`

Largely cosmetic, less precision-critical. Drives `gauntlet_width_mm`.

### Stage 5 — Wrist hinges

Files: `models/kinetic_hand/wrist_hinge_1.stl`, `models/kinetic_hand/wrist_hinge_2.stl`

Small parts, high precision required. Complete the full assembly.
