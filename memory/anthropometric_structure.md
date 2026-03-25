---
name: Anthropometric data model and derivation pipeline
description: Primary input fields, derived geometry parameters, and the 4-layer hierarchy in the anthropometric importer
type: project
---

The anthropometric pipeline follows a strict 4-layer hierarchy:

1. **Primary inputs** — directly measured by clinician or from dataset
2. **Derived geometry** — computed from primaries (phalanx segments, socket geometry)
3. **Functional** — per-digit total lengths, joint positions
4. **Manufacturing/constraint** — clearance, hardware standard, reinforcement zones

## Primary input fields (as of v4.0.0)

**Hand:** palm_length, palm_breadth (= palm_width), palm_thickness, average_finger_width, wrist_circumference

**Fingers (total lengths, primary):** thumb_length_total, index_length_total, middle_length_total, ring_length_total, little_length_total

**Finger segments (optional detail):** finger_{index,middle,ring,pinky}_{proximal,middle,distal,circumference}

**Residual limb:** residual_length, residual_circumference_proximal, residual_circumference_distal

## Key derivation formulas

- Phalanx segments from total: proximal = 0.45×total, middle = 0.31×total, distal = 0.24×total
- Thumb: proximal = 0.54×total, distal = 0.46×total
- palm_structural_thickness = 0.35 × palm_thickness (or 0.077 × palm_width fallback)
- finger_base_width = average_finger_width (or palm_width / 5)
- internal_channel_diameter = clamp(0.25 × finger_base_width, 2, 4) mm
- socket_inner_diameter = circumference / π
- socket_depth = 0.60 × residual_length
- socket_taper_angle = atan2((diam_prox - diam_dist)/2, socket_depth)

## Backwards compatibility

Legacy keys (stump_circumference, residual_limb_circumference) still map to the circumferences_mm array. The new circumference_proximal_mm / circumference_distal_mm scalar fields are preferred and used for socket_internal_geometry computation.

**Why:** Existing saved profiles in DB use circumferences_mm; new profiles should use the dedicated scalar fields.
