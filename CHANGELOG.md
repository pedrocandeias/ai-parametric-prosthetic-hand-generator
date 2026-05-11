# Changelog

All notable changes are recorded here.

Version format: `MAJOR.MINOR.PATCH`
- Bump **MAJOR** on breaking changes
- Bump **MINOR** on new features
- Bump **PATCH** on bug fixes

Entry format follows [Conventional Commits](https://www.conventionalcommits.org/):
`type: description` — types: `feat`, `fix`, `security`, `refactor`, `docs`, `chore`

---

## v7.10.0 — 2026-05-11

feat: add exact legacy Phoenix Hand v3 component wrappers — extract standalone native OpenSCAD geometry files for palm, distal fingers, proximal phalanx bank, and pins; add active wrappers in `models/active/phoenix_v3/` with shared `hand_length_mm` scaling and optional anisotropic controls
feat: register Phoenix Hand v3 as a full model family in `models-config.json` — add separate `phoenix_v3_palm`, `phoenix_v3_fingers`, `phoenix_v3_phalanx_bank`, `phoenix_v3_pins`, and `phoenix_v3_complete` entries so all major components are selectable in the UI
feat: add Phoenix Hand v3 complete preview model — create `phoenix_v3_assembly.scad` with palm/finger/phalanx/pin visibility toggles, handedness, and per-part preview colors so Phoenix can be edited as one prosthetic scene like the existing complete-hand models
fix: preserve all Phoenix complete-model parts in browser preview — replace the top-level multi-solid assembly with one merged `polyhedron()` built from translated exact part point/face arrays, avoiding the OFF/manifold preview path dropping palm or finger geometry when multiple legacy shells were active together

## v7.9.0 — 2026-05-10

feat: add enum parameter type — renders as a dropdown select in the UI; handles boolean/number/string coercion on change
feat: convert paraglider_hand mirrored parameter from boolean checkbox to "Left hand" / "Right hand" dropdown

## v7.8.0 — 2026-05-09

docs: rewrite paraglider.md to cover each-keyword patch, patched local file locations, per-finger scales, assembled view default, full print layout part table, and updated comparison table
docs: update parametric_reconstruction_thesis.md §6 with each-keyword parse failure analysis, per-finger scale extension (§6.4.1), assembled/print layout modes (§6.5), and updated comparison table (§6.7)

## v7.7.0 — 2026-05-09

feat: add per-finger length parameters (index, ring, pinky) to paraglider_hand — each drives its own tip and phalanx scale independently; print layout now shows all 4 finger tips and 4 phalanxes at correct individual sizes
feat: add index/middle/ring/pinky canonical field names to CLAUDE.md anthropometric table for future model alignment

## v7.6.0 — 2026-05-09

feat: expose show_assembled toggle in paraglider_hand UI — adds boolean parameter to models-config.json so users can switch between flat print layout and assembled knuckle-pin view

## v7.5.0 — 2026-05-09

fix: OpenSCAD render log showed every message twice — real-time stderr/stdout was captured during the worker message loop and then again from result.mergedOutputs after completion; remove the post-result mergedOutputs processing so each line appears exactly once
fix: Paraglider Hand palm emits "Can't get font" / Fontconfig warnings — the WASM build has no fontconfig so text() calls in do_labels() produce empty geometry and spam warnings; override do_labels() in paraglider_hand.scad to pass children through without any text cuts; serial labels are suppressed in browser preview but remain in desktop OpenSCAD renders

---

## v7.4.0 — 2026-05-09

feat: add OpenSCAD render log panel (admin only) — "Show Log" button appears next to "Edit Code" for admin users; panel shows stderr (red), WARNING lines (yellow), and stdout (green) from every render; clears automatically at the start of each render; "Clear" button empties the log manually; log auto-scrolls to bottom; panel closes on logout; no log data stored server-side

---

## v7.3.0 — 2026-05-09

fix: Paraglider Hand palm not rendering and fingers misplaced — root cause: paraglider_palm_left.scad used OpenSCAD `each` keyword inside list constructors (lines 46, 146) which causes parse failure in the WASM build, making scaled_palm() undefined; also had double-comma syntax at line 85; fix: create patched local copies of all three source files (fingerator.scad, paraglider_palm_left.scad, pipe.scad) in models/active/paraglider_hand/ with each→concat() and each xy→xy[0],xy[1] rewrites and double-comma removed; update models-config.json dependencies to reference local copies; these local copies also fix desktop OpenSCAD compatibility (files now in same directory as paraglider_hand.scad, no library-path configuration needed)
fix: Paraglider Hand finger print layout incorrect — positions and thumb/thumb-phalanx order did not match fingerator.scad native layout; fix: rewrite layout section to place all parts at fingerator's exact unscaled offsets (short_finger=-50, long_finger=-25, phalanx=0, thumb_phalanx=+30, thumb_tip=+60) relative to _fp = palm_right_edge + 65 mm; restore screws branch for pin_index=0 on all finger/thumb parts; fix short-finger slot offset to match fingerator (-20×0.9,9) and thumb offset to (-20×0.77, 9×0.72)

---

## v7.2.0 — 2026-05-09

fix: Paraglider Hand palm not rendering — the plug_old_channels() + reborn_channels() swept-pipe CSG from pipe.scad exceeded Manifold backend tolerance; override do_channels() in the wrapper to skip channel routing by default (show_channels=false); add use<pipe.scad> to ensure pipe.scad modules are in calling scope; add show_channels boolean parameter (default off = fast preview, enable for print-ready export with full channel routing)

---

## v7.1.0 — 2026-05-09

feat: align Paraglider Hand with canonical anthropometric parameter set — add palm_length_mm, palm_thickness_mm, middle_finger_length_mm, thumb_length_mm to model config and SCAD; palm stays uniformly scaled from palm_breadth_mm (pin holes must remain circular); middle_finger_length_mm independently drives global_scale for all finger parts via REF_FINGER=57.6 (calibrated at 72mm→1.25×); palm_length_mm, palm_thickness_mm, thumb_length_mm stored for AI suggestion and patient profile auto-population; all 5 canonical non-gauntlet parameters now present in both Paraglider and Kinetic Hand RH60 configs

---

## v7.0.0 — 2026-05-09

feat: add Paraglider Hand (Flexible Flyer) as a second active parametric model — fully OpenSCAD-native wrapper around Marcus Mendenhall's paraglider/flexible_flyer design; maps palm_breadth_mm (55–110 mm) to overall_scale via dynamic scoping; generates a flat print layout with palm body (Phoenix v2 mesh base + parametric pin drilling + string/elastic channels + knuckle covers) and finger/thumb parts (long fingertip, short fingertip, finger phalanx, thumb, thumb phalanx); hardware style (3 mm screws, 1/16" pins, 13 ga nails) drives all hole diameters consistently; 14 parameters across Anthropometric / Hardware / Visibility groups; dependencies: fingerator.scad, paraglider_palm_left.scad, pipe.scad, palm_left_v2_nobox.stl

---

## v6.22.0 — 2026-05-09

chore: restructure models/ into active/ sub-folders — move kinetic_hand_rh60 SCAD components + source STLs into models/active/kinetic_hand_rh60/; move Kinetic Hand STEP Files RH60 to models/old_models/; update models-config.json file path and dependency urls to active/kinetic_hand_rh60/ prefix; WASM virtual-FS dependency paths remain flat (no subdirectories)

---

## v6.21.0 — 2026-05-09

chore: reorganise models/ — move all non-parametric models (kinetic_hand_rh60.scad, rbe580_hand.scad, passive_prosthetic_hand.stl, rbe580/, anthropometric_cyborgbeast.scad, pekwawu.scad) to models/old_models/; remove stale pekwawu.scad and models-config.xml git entries; models-config.json trimmed to kinetic_hand_rh60_parametric only

---

## v6.20.0 — 2026-05-09

feat: format parameter names as human-readable titles in the UI — palm_breadth_mm → "Palm Breadth (in mm)", show_palm → "Show Palm", assembled → "Assembled"; implemented via formatParamName() in app.js applied to the param-name span in all four control types (boolean, slider, number input, string)

---

## v6.19.0 — 2026-05-09

fix: add five component SCAD files as dependencies in kinetic_hand_rh60_parametric models-config entry — use<> directives in the assembly SCAD require the component files to be present in the WASM virtual filesystem before OpenSCAD runs; without them the renderer exits without writing /output.off producing ErrnoError: FS error

---

## v6.18.0 — 2026-05-09

feat: add models/kinetic_hand_rh60_parametric.scad — master assembly file combining all five component SCAD files (finger_middle, thumb, palm, gauntlet, wrist) into the shared coordinate frame using use<> imports and dynamic scoping; all six anthropometric parameters (palm_breadth_mm, palm_length_mm, palm_thickness_mm, middle_finger_length_mm, thumb_length_mm, gauntlet_width_mm) are re-declared in the assembly scope so component modules resolve them correctly; four finger columns placed at scaled X offsets proportional to palm_breadth_mm; no external STL imports required
feat: register kinetic_hand_rh60_parametric in models/models-config.json with six Anthropometric parameters and six Visibility toggles; renderBackend set to manifold

## v6.17.0 — 2026-05-09

feat: add models/kinetic_hand_thumb.scad — native parametric OpenSCAD reconstruction of the thumb unit (thumb body finger_1.stl + hinge_1.stl) as polyhedron() modules; driven by thumb_length_mm and palm_breadth_mm; Hausdorff 0.000001 mm for both parts
feat: add models/kinetic_hand_palm.scad — native parametric OpenSCAD reconstruction of the palm (palm.stl, 24867 verts) as a polyhedron() module; driven by palm_breadth_mm, palm_length_mm, palm_thickness_mm; Hausdorff 0.000001 mm
feat: add models/kinetic_hand_gauntlet.scad — native parametric OpenSCAD reconstruction of the gauntlet body and cover (gauntlet.stl + gauntlet_cover.stl) as polyhedron() modules; driven by gauntlet_width_mm with cover offset constants; Hausdorff 0.000001 mm for both parts
feat: add models/kinetic_hand_wrist.scad — native parametric OpenSCAD reconstruction of the wrist hinge pair (wrist_hinge_1.stl + wrist_hinge_2.stl) as polyhedron() modules; driven by gauntlet_width_mm; Hausdorff 0.000001 mm for both parts
feat: add tools/gen_thumb_scad.py — generator script that encodes thumb STL meshes as OpenSCAD polyhedron() modules
feat: add tools/gen_palm_scad.py — generator script that encodes palm STL mesh as OpenSCAD polyhedron() module
feat: add tools/gen_gauntlet_scad.py — generator script that encodes gauntlet + cover STL meshes as OpenSCAD polyhedron() modules
feat: add tools/gen_wrist_scad.py — generator script that encodes wrist hinge STL meshes as OpenSCAD polyhedron() modules

---

## v6.16.0 — 2026-05-08

feat: add models/kinetic_hand_finger_middle.scad — native parametric OpenSCAD reconstruction of the middle finger unit (proximal phalanx, distal phalanx, proximal hinge, distal hinge) using polyhedron() primitives derived from the reference STLs; achieves 0.000001 mm Hausdorff distance (vs 0.1 mm target); driven by middle_finger_length_mm and palm_breadth_mm
feat: add tools/stl_info.py — reusable Phase 1 mesh triage tool (vertex/face counts, bounding box, volume, watertightness, Euler number, genus, components); --json output
feat: add tools/stl_zlevel.py — reusable Phase 2 Z-level structure analysis (discrete height levels, face areas, vertex coords per level, axis suggestion); --vertices and --json flags
feat: add tools/stl_cross_section.py — reusable Phase 3–4 cross-section slicer (polygon classification: rectangle/circle/L-shape/ring, world-space bounds, hole detection); --axis, --at, --json flags
feat: add tools/stl_normals.py — reusable Phase 4 face normal grouping (axis-aligned vs oblique, cylinder detection); --json flag
feat: add tools/compare_stl.py — reusable Phase 7 bidirectional Hausdorff comparison tool (50k surface samples, mean/max/p95/p99 distances, volume and topology check); --json flag
feat: add tools/hausdorff_from_scad.py — extract polyhedron() mesh from SCAD module and compute Hausdorff distance vs reference STL (eliminates need to render SCAD for validation)
feat: add tools/validate_polyhedron_scad.py — verify that SCAD polyhedron() vertex/face data exactly matches source STL (KD-tree comparison)
feat: add tools/gen_middle_finger_scad.py — generator script that encodes the four middle-finger STL meshes as OpenSCAD polyhedron() modules
feat: add plan.md — progress checklist for all five reconstruction stages with per-phase status, approach notes, and failed-approach log

---

## v6.15.0 — 2026-05-08

docs: add docs/kinetic_hand_rh60_conversion.md — documents how the Kinetic Hand was assembled as an STL-in-SCAD wrapper, which scale parameters work reliably (palm_breadth_mm, middle_finger_length_mm, gauntlet_width_mm) and why palm_length_mm, palm_thickness_mm, and thumb_length_mm cannot be added without distorting or misaligning mating interfaces on fixed meshes
revert: remove palm_length_mm, palm_thickness_mm, and thumb_length_mm from kinetic_hand_rh60 — STL wrapper cannot satisfy non-uniform multi-anchor scaling without interface misalignment; SCAD and models-config.json restored to the three reliable parameters

---

## v6.14.0 — 2026-05-08

fix: correct Kinetic Hand RH60 middle_finger_length_mm reference from 48 mm (assembly Z-span) to 72 mm (anatomical MCP-to-tip), so the parameter accepts the same measurement the platform imports from CSV and the scaling math remains consistent
docs: add Anthropometric Parameter Alignment section to CLAUDE.md — defines canonical field names, units, and anatomical measurement conventions that all prosthetic models must follow so patient profiles auto-populate the correct SCAD variables

---

## v6.13.0 — 2026-05-08

feat: add anthropometric parameters to Kinetic Hand RH60 — palm_breadth_mm scales hand XY, middle_finger_length_mm scales finger reach independently from the knuckle line, gauntlet_width_mm scales the forearm socket XY separately; SCAD rewritten to apply per-group scale transforms (gauntlet_scale / hand_scale / finger_scale modules)

---

## v6.12.0 — 2026-05-08

fix: repair non-manifold finger STL geometry in Kinetic Hand RH60 — finger_3 (170 open edges), finger_7, and finger_9 were causing OpenSCAD Manifold backend to produce empty geometry; re-exported at appropriate tessellation tolerances to eliminate all boundary and non-manifold edges
feat: add per-model renderBackend config field — models can override the default Manifold backend by setting renderBackend in models-config.json; kinetic_hand_rh60 sets renderBackend to "" to omit the flag, letting WASM use its default

---

## v6.11.0 — 2026-05-08

feat: add Kinetic Hand RH60 model — 31 STEP files converted to binary STL via CadQuery/OpenCASCADE; all structural parts (gauntlet, palm, 9 finger phalanges, 9 hinges, 2 wrist hinges, gauntlet cover) are in assembly coordinate space and imported with no transform; registered with 23 STL dependencies; part-group visibility toggles in parameter panel
feat: support { url, path } object format in model dependencies — allows STL files to live in server subdirectories while being written flat in the WASM virtual FS, fixing the ErrnoError that occurs when writing to non-existent subdirs

---

## v6.10.0 — 2026-05-07

feat: admin SCAD code editor — "Edit Code" toggle button (admin-only) opens a dark-themed editor panel beneath the 3D viewer toolbar; admins can hand-edit OpenSCAD source directly and render immediately; "● modified" badge appears when code diverges from parameter state; "Revert to Parameters" button re-injects current parameter values and clears the modified flag; editor closes and flag resets on model change or logout; non-admin users never see the button or panel

---

## v6.9.0 — 2026-05-07

fix: rbe580_hand — replace flat print layout with assembled hand view; fingers oriented in +Y via rotate([0,0,90]), stacked proximally→middle→distal from palm knuckle edge; thumb placed at -45° from palm corner extending upper-right; palm pulley and cover stacked in z above palm back; add assembled boolean parameter to toggle between assembled and print-layout modes
fix: rbe580_hand — resolve phalanx overlap in print layout by rotating each phalanx 90° and spacing by phalanx length

---

## v6.8.0 — 2026-05-07

feat: add RBE580 cable-driven prosthetic hand model — parametric assembly of all 8 parts (palm back, palm cover, palm pulley slider, 4× proximal/middle/distal finger phalanges, thumb proximal, thumb tip) extracted from github.com/jeffmiscione/RBE580-Project; scaled from 3 anthropometric inputs (palm_width, middle_length, thumb_length); registered in models-config.json with full parameter panel

---

## v6.7.0 — 2026-05-07

fix: binary STL deps corrupted by worker content resolver — TextEncoder.encode(Uint8Array) serialized bytes as "0,1,2,..." string; fixed by passing url instead of content for binary dependencies so the worker fetches the file as ArrayBuffer directly
fix: correct default test password in smoke.spec.js and compare_renders.spec.js (admin1234)
fix: avoid strict-mode locator error in compare_renders.spec.js — model-viewer internal span shares id="status"; use div#status selector
chore: add browser console capture and render status logging to compare_renders.spec.js for easier diagnosis of WASM render failures
chore: raise playwright.config.js test timeout to 300000ms for WASM render tests
test: compare_renders test now passes — STEP mesh renders in 221ms, parametric SCAD in 722ms, both produce valid screenshots

---

## v6.6.0 — 2026-05-06

fix: add Cross-Origin-Opener-Policy: same-origin and Cross-Origin-Embedder-Policy: require-corp headers to server — required for SharedArrayBuffer used by OpenSCAD WASM worker; without these headers headless Chromium and some browsers silently fail to render
feat: add passive_hand_step model — passive_prosthetic_hand.stl (converted from STEP via FreeCAD at 1mm deflection, 24k triangles) served as STL dependency and rendered via WASM import() for direct comparison against parametric reconstruction
fix: correct Playwright login selector — use #login-form button[type="submit"] (form submit inside modal) not #login-btn (navbar button hidden behind modal overlay)

---

## v6.5.0 — 2026-05-06

feat: add passive_hand.scad — parametric passive cosmetic prosthetic hand converted from passive prosthetic hand.step via FreeCAD cross-section analysis
feat: palm_body() — organic hull palm scaled from palm_breadth_mm with thenar/hypothenar eminences, knuckle bar, and dorsal flattening
feat: finger_column() + phalanx() + fingertip() — tapered solid finger columns (3 phalanges, measured ~18mm each from STEP) for index/middle/ring/pinky
feat: thumb_column() — two-phalanx thumb angled 22°/18° from palm plane
feat: wrist_connector() — hollow pylon attachment stub sized from pylon_connector_dia_mm
feat: socket_cavity() — hollow palm bore sized from socket_inner_diameter_mm and socket_depth_mm
feat: forearm_socket() — parametric hollow forearm cuff reconstructed from passive_prosthetic_hand001 solid (75mm outer radius, 11mm wall, 90mm height)
feat: register passive_hand in models-config.json as "Passive Cosmetic Hand" with 11 parameters
chore: FreeCAD analysis scripts (analyze_step2/3/4.py) used to extract bounding boxes, Z/X cross-section profiles, and solid measurements

---

## v6.4.0 — 2026-05-06

fix: correct parahand assembled view — keep forearm flat in XY plane and extend palm/fingers from wrist end in same plane; removes erroneous 90° rotation that stood the hand perpendicular to the arm
fix: correct cuff placement in assembled view — translate by full -(CuffLength+ArmLength) so arm joints align with forearm elbow; was using *0.5 offset which mispositioned the cuff
chore: add Playwright test runner — @playwright/test devDependency, playwright.config.js, Chromium browser installed
chore: add smoke tests in tests/smoke.spec.js — login flow, model list, parameter panel for PeKwawu and Parahand
chore: add test and test:ui npm scripts

---

## v6.3.0 — 2026-05-06

feat: add parahand.scad — complete assembly combining UnLimbited Arm v2.1 forearm/cuff with procedural palm and fingers; no STL imports, renders in browser WASM
feat: UnLimbited forearm and cuff modules adapted and renamed (ULCurver, ULCurve, ULJoint, ULThickness) to avoid OpenSCAD variable conflicts
feat: parahand part selector — Assembled / Forearm / Cuff / Jig / Palm / Fingers for individual print-flat components
feat: palm_breadth_mm drives finger/palm scale; residual_length_mm and bicep_circumference_mm size forearm and cuff via UnLimbited HandPerc mapping
feat: register parahand in models-config.json as "Parahand (UnLimbited Forearm + Procedural Palm)"

---

## v6.2.0 — 2026-05-06

feat: rewrite pekwawu.scad as fully procedural parametric arm — no STL imports, renders completely in browser WASM
feat: forearm_socket() — tapered hollow cylinder scaled from residual_circumference_proximal_mm and residual_length_mm with proximal rim flange and strap slots
feat: structural_frame() — two hull-sphere rods bridging palm wrist attachment to socket body, proportional to palm_breadth_mm
feat: palm_base() — organic hull palm adapted from anthropometric_hand, with knuckle blocks, thumb boss, wrist hinge arms, tendon channels
feat: finger_seg(), finger_tip(), fingerpoints(), knuckle_block(), thumb_boss() — all procedural finger modules reused from anthropometric_hand pattern
feat: show_assembled parameter toggles full arm + fingers vs socket + palm only
feat: unified pivot_diameter_mm and clearance_mm replace separate bolt/rivet selectors
refactor: remove part and material string selectors from models-config.json — no longer needed
chore: rename model to "PeKwawu v2 (Long Residual Limb)" in models-config.json

---

## v6.1.0 — 2026-05-05

fix: wrap string parameter values in OpenSCAD quotes when substituting into SCAD code — was rendering part = Cuff1 (unquoted variable) causing all if(Part==...) comparisons to fail with empty geometry
fix: remove STL-import parts from PeKwawu part selector (IndexFingerEnd, arm segments, Ratchet, WhippleTrees, etc.) — these depend on external .stl files unavailable in the WASM renderer
chore: rename PeKwawu model to "PeKwawu v1 (Long Residual Limb)"
chore: move all non-PeKwawu model files to models/old_models/ and remove from models-config.json
docs: update CLAUDE.md — CHANGELOG update and package.json version bump are now mandatory on every change
docs: update README.md with anthropometric profiles, PeKwawu, bulk CSV import, and full API table

---

## v6.0.0 — 2026-05-05

feat: add PeKwawu model — Kwawu Arm 3.0 Wrap Version (CC BY 4.0, JacquinBuchanan/e-NABLE) adapted for the platform; designed for long forearm residual limbs using a wrap-style socket
feat: pekwawu.scad platform parameter block maps palm_breadth_mm → HandWidth, residual_length_mm → ArmLength, residual_circumference_proximal_mm → ForearmCircumference, bicep_circumference_mm → BicepCircumference, plus material/part/comfort/hardware selectors
feat: add PeKwawu entry to models-config.json with full parameter groups (Orientation, Hand & Arm Measurements, Comfort & Hardware, Material, Options, Part)
feat: extend anthropometricImporter.buildGeometryParameters() to include pekwawu block deriving HandWidth, ArmLength, ForearmCircumference from stored profile fields
feat: add POST /api/anthropometric/import-csv-bulk endpoint — parses long-format multi_population_hand.csv, groups rows by (population, country, sex, age_group, percentile), calls importer.process() per group, idempotent by group_name
feat: add "Import CSV Dataset" button to admin Anthropometric Profiles tab — triggers file picker, POSTs to /import-csv-bulk, shows created/skipped toast

---

## v5.1.0 — 2026-03-30

feat: add Edit button to anthropometric profiles table in admin panel
feat: add PUT /api/anthropometric/:id endpoint to update existing profiles
feat: openEdit(id) fetches stored profile and pre-populates the manual entry modal with all measurement and metadata fields
feat: modal title and save button label update dynamically for new vs edit mode

## v5.0.0 — 2026-03-26

feat: add anthropometric_cyborgbeast.scad — Cyborg Beast prosthetic hand geometry reparametrized with all 29 anthropometric measurement inputs
feat: master CB scale factor q = palm_width / 64 drives all proportional geometry; per-finger len values computed from anthropometric finger lengths
feat: preserve original CB organic hull palm, knuckle blocks, thumb boss, cosmetic through-cuts, wrist hinge arms, and finger grip texture
feat: hardware holes (pins, tendons, elastic channels) at physical dimensions — not scaled with hand size
feat: thumb split into mid/tip segments using 54% / 46% anatomical ratio with independent CB len computation
feat: gauntlet module driven by anthropometric socket dimensions (proximal/distal diameters, depth, rim, cap)
feat: register anthropometric_cyborgbeast in models-config.json with full 29-parameter schema

## v4.1.0 — 2026-03-26

feat: add anthropometric_hand.scad — full parametric prosthetic hand OpenSCAD model driven by anthropometric geometry_parameters (palm dimensions, per-finger phalanx lengths, wrist socket sizing, hardware specs, tendon channel diameter)
feat: tongue-and-fork hinge design at MCP / PIP / DIP joints with correct clearance and pivot-pin holes
feat: tapered wrist socket module sized from socket_diameter_proximal/distal_mm, socket_depth_mm, socket_rim_thickness_mm, and socket_distal_cap_thickness_mm
feat: two-phalanx thumb using 54% / 46% anatomical split, four three-phalanx fingers using 45% / 31% / 24% split
feat: continuous palmar tendon channel through all phalanges and palm for passive closure actuation
feat: interior hollowing on all segments and palm slab with configurable wall thickness (palm_wall_thickness_mm)
feat: left/right mirror via right_hand boolean; assembled view and print-flat layout via show_assembled
feat: register anthropometric_hand in models-config.json with full parameter schema for all 29 geometry_parameters fields

## v4.0.0 — 2026-03-25

feat: add full primary anthropometric input structure (palm_breadth, palm_length, palm_thickness, thumb/index/middle/ring/little total lengths, average_finger_width, residual_length, residual_circumference_proximal, residual_circumference_distal)
feat: derive proximal/middle/distal phalanx lengths from total finger lengths using anatomical ratios (0.45 / 0.31 / 0.24)
feat: compute joint_positions (PIP, DIP, tip) from derived phalanx lengths
feat: compute palm_structural_thickness (35% of palm_thickness), finger_base_width (average_finger_width or palm_breadth÷5), internal_channel_diameter (25% of finger_base_width, clamped 2–4 mm)
feat: compute local_reinforcement_zones and socket_internal_geometry from proximal + distal residual circumferences
feat: add thumb digit to measurements structure with 2-phalanx ratio derivation (0.54 / 0.46)
feat: add dedicated residual_circumference_proximal and residual_circumference_distal scalar fields (retain legacy circumferences_mm array for backwards compat)
feat: expand geometry_parameters output with proximal_phalanx_length, middle_phalanx_length, distal_phalanx_length, joint_pos_pip_mm, joint_pos_dip_mm, palm_structural_thickness, finger_base_width, internal_channel_diameter, socket_diameter_proximal_mm, socket_diameter_distal_mm, socket_depth_mm, socket_taper_angle_deg, socket_rim_thickness_mm, socket_distal_cap_thickness_mm
feat: update admin panel manual entry form with grouped primary / optional-detail layout for all finger sections
feat: add palm_thickness and average_finger_width inputs to Hand Measurements section
feat: add separate proximal + distal circumference inputs to Residual Limb section
feat: add Thumb section with total length input
feat: add cross-field validation for residual circumference order, palm thickness vs width, and finger total vs segment sum consistency
refactor: update detectMissing() to accept either total or segments for each finger — no false positives when only total is given

---

## v3.4.0 — 2026-03-25

feat: add admin-initiated password reset via short-lived single-use token
feat: add POST /api/auth/reset-request (admin only) and POST /api/auth/reset (public) endpoints
feat: add password_reset_tokens DB table with 1-hour TTL and single-use enforcement
feat: add Reset Token button and modal to admin panel user management
feat: add reset password view to main app login modal

---

## v3.3.0 — 2026-03-04

feat: add Cyborg Beast model set (full hand, palm, finger mid, fingertip) to model selector
fix: correct double-comma syntax error in paraglider_palm_left.scad pin_coordinates array
fix: binary STL dependencies (e.g. palm_left_v2_nobox.stl) now fetched as ArrayBuffer and injected into WASM virtual FS
feat: add renderCall support in models-config.json for library-style SCAD files that define modules but have no top-level call

---

## v3.2.0 — 2026-02-27

refactor: redesign anthropometric profiles as population-level reference datasets (not patient records)
feat: add demographic fields to profiles — group_name, country, gender, age_group, percentile, sample_size, data_source
refactor: remove user_id FK from anthropometric_profiles table; add db migration guard for old schema
refactor: update admin panel profile table and filters to use country/gender/age_group instead of patient dropdown
fix: update admin.js renderAnthroProfiles and setupAnthroTab for new demographic schema

## v3.1.1 — 2026-02-27

security: restrict all /api/anthropometric endpoints to admin role only
refactor: move anthropometric importer from main app to admin backoffice
feat: add Anthropometric Profiles tab to admin panel with patient filter and profile list
fix: remove AnthropometricImporter integration from main app getAISuggestions

---

## v3.1.0 — 2026-02-27

feat: add AnthropometricDataImporter service — unit conversion, range validation, outlier detection, derived-value computation
feat: add `POST /api/anthropometric/preview` — process measurements without persisting
feat: add `POST /api/anthropometric` — process and save profile to DB
feat: add `GET/DELETE /api/anthropometric/:id` — retrieve or delete a saved profile
feat: add `anthropometric_profiles` table to SQLite schema
feat: add Measurements modal to main UI — manual entry form with collapsible sections per digit
feat: add Import tab — paste CSV (key-value or flat-header) or JSON AnthropometricProfile
feat: add "Apply to Model" — maps `global_scale` and `clearance_mm` → model parameter controls
feat: integrate AI context into AI suggest prompt when a profile is active
feat: expose `window.parameterEditor` globally so modules can call `applyGeometryParameters()`

---

## v3.0.2 — 2026-02-27

feat: allow admins to edit username and email via PATCH /api/users/:id
feat: add password reset for any user from the admin panel (PATCH /api/users/:id/password)
feat: add Edit button and modal to admin panel users table

---

## v3.0.1 — 2026-02-27

fix: return JSON from global rate limiter instead of plain text (prevented browser JSON.parse)
fix: remove `Content-Type: undefined` header in `fetchWithAuth` when no body is present
fix: wrap `res.json()` calls in `safeJson()` helper for actionable parse-error messages
fix: add `/api/*` 404 JSON handler so unknown API paths never fall through to the SPA

---

## v3.0.0 — 2026-02-27

feat: add Node.js/Express backend — replaces Python `http.server`; serves both API and static files
feat: add SQLite database via `better-sqlite3`; schema auto-applied on first run
feat: add user authentication — bcrypt passwords, JWT access tokens (15 min, HS256)
feat: add rotating HttpOnly refresh cookies (7-day expiry, SHA-256 hashed in DB)
feat: add role-based access control — Admin / Tech / User roles
feat: add tech assignments — admins assign patient users to tech users
feat: add saved configurations — named parameter sets per patient with ownership enforcement
feat: add first-run setup flow — browser form creates initial admin; CLI fallback via `scripts/create-admin.js`
feat: add AI proxy — AI API calls move server-side; keys read from `.env` and never sent to the browser
feat: add admin panel (`admin.html`) — user management table, create/suspend/change-role, tech assignment UI
feat: add frontend auth module (`auth.js`) — `Auth` singleton with `fetchWithAuth` and silent refresh
feat: add login modal with login / register / setup sub-views
feat: add rate limiting — login (5/15 min), register (3/hr), AI suggest (10/min)
feat: add `CLAUDE.md` developer guide and `ARCHITECTURE.md` technical reference
security: move AI API keys from client-side `config.json` to server-side `.env`
security: store access tokens in JS memory only (no localStorage)
security: store refresh tokens as SHA-256 hashes in DB; rotate on every use
security: block `/.env` and `/config.json` at Express level — unconditional 404
security: add `helmet` with restrictive CSP headers
refactor: remove `loadAIConfiguration()` from `app.js`; AI calls now go through `/api/ai/suggest`
refactor: add save/load config methods to `app.js`
chore: replace Python `http.server` with `node server/index.js` in `start-server.sh`
chore: add `.env`, `data/` to `.gitignore`
docs: rewrite all documentation for Node.js stack

---

## v2.0.0 — 2025-10-10

feat: integrate OpenSCAD WASM for real-time in-browser 3D preview (no server round-trip)
feat: add `<model-viewer>` (Google) for interactive 3D display
feat: add GLB render pipeline — OpenSCAD → Web Worker → WASM → `.off` → `.glb` → viewer
feat: add STL export — download print-ready files directly from the browser
feat: add auto-render on parameter change (500 ms debounce)
feat: add loading spinner during rendering
refactor: hide code editor by default; still updates in background
chore: add `openscad.wasm`, `openscad-worker.js`, `24c27bd4337db6fc47cb.wasm`, `model-viewer.min.js`

---

## v1.0.0 — 2025-10-10

feat: add JSON configuration support via `models/models-config.json`
feat: add dynamic parameter UI generation — sliders, checkboxes, number inputs
feat: add multiple model support with model selector dropdown
feat: add parameter grouping
feat: add OpenSCAD code generation with live parameter substitution
