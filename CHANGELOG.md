# Changelog

All notable changes are recorded here.

Version format: `MAJOR.MINOR.PATCH`
- Bump **MAJOR** on breaking changes
- Bump **MINOR** on new features
- Bump **PATCH** on bug fixes

Entry format follows [Conventional Commits](https://www.conventionalcommits.org/):
`type: description` — types: `feat`, `fix`, `security`, `refactor`, `docs`, `chore`

## v14.36.0 — 2026-07-10

feat: **UnLimbited Phoenix Hand now opens on a fully assembled preview** instead of a single bare part. Added an `Assembly (seated hand)` option to the model's `part` selector and made it the default — it renders the palm, four fingers, thumb, finger/wrist pins, gauntlet, tensioner block/pins and washers all seated together, driven by the same `palm_breadth_mm`/`HandPerc` sizing (the whole assembly is wrapped in one uniform `scale()`, so it stays seated at any size and mirrors correctly for a right hand). The existing per-part options (Palm, Fingers, Phalanx, Pins, Box, TPins, Gauntlet, Jig) are unchanged and remain the way to export each printable piece.
refactor: extracted the seated-hand recipe into a shared `phoenix_assembly.scad` module (single source of truth) that is `include`d by both the served `UnLimbitedPhoenix.scad` (for the `Assembly` part) and the `_assembly.scad` dev harness — no recipe duplication. Registered `phoenix_assembly.scad` + the reconstructed `phoenix_snap_pins.scad` / `phoenix_tensioner_block.scad` / `phoenix_tensioner_pins.scad` as model `dependencies` so the in-browser WASM loader mounts them. Verified: headless render (left/right, 100–146% scale), flat-FS include/use resolution matching the WASM virtual filesystem, and a watertight manifold STL export. Bump `index.html` JS cache-buster to 14.36.0.

## v14.35.0 — 2026-07-10

fix: **Cyborg Beast fingers now seat on the palm knuckle hinge line.** Each finger's proximal (first) `fingermid` hinge hole was floating 4.6–7.1 mm past the palm's knuckle hinge holes, so the assembly pin couldn't pass through both. The cause: the original per-finger y-offsets were hand-tuned for the design's small native `len` values, but the anthropometric layer drives `len` over a much wider range, and the fingermid's hole spacing (`11.5 + len/3`) moves with `len`. Fingers are now seated by a new `place_finger()` module with `yoff = 9.5 + len/3`, which lands the proximal hole on the knuckle hinge line (y = 27) for every finger regardless of length. Verified numerically (pin threads through the base and clears the hole) and visually.
fix: `.scad` model source and text dependencies are now fetched with `{ cache: 'no-cache' }` (like models-config.json in v14.33.0), so edits to a model's geometry reach returning browsers instead of a stale cached copy. Bump `index.html` JS cache-buster to 14.35.0.

## v14.34.0 — 2026-07-09

feat: **Integrate the Flexy Beast finger hinges into the parametric model.** The `Finger_Hinge_Plate.scad` connector plate is now generated inside `flexy_beast.scad` as a parametric flexy joint rather than a fixed STL-measured plate. A new `flexy_joint()` module builds the "dogbone" living-hinge connector (two lobes with pin bores joined by a thin flexing web) entirely from the joint hardware and hand scale — `lobe_r = joint_dia/2 + wall`, `web = joint_thick`, length `= knuckleW × scale`, span `= 8 × scale` — so every connector resizes and repositions when the fingers or `joint_dia`/`joint_thick` change.
feat: In the assembled preview each finger carries its two flexy joints (MCP + PIP) in its own frame via `fingerlayout(hinge=true)`, and the thumb carries its two in the thumb frame — so all ten connectors sit in the joint gaps between the segments and follow the finger pose and length automatically. Each connector is oriented (`rotate([90,90,0])`) so its pin bore runs **across the finger width** (coaxial with the knuckle pin), with one lobe seated on the segment's own pin bore and the other reaching into the neighbouring segment (MCP → palm knuckle, PIP → fingertip), bridging the gap. In `print_layout` the ten connectors lay out flat on a plate (`hinge_plate()`) for printing in flexible filament (Filaflex/TPU).
feat: New `show_hinges` toggle + `color_hinge` colour, a dedicated **Flexy joints (plate)** printable part (`show_hinges` toggle) for isolated STL export, and full EN/PT captions + help. Verified end-to-end: default, small-child (60 mm palm / 5 mm joints / short fingers) and isolated-part exports all render the connectors correctly sized and placed.

## v14.33.0 — 2026-07-09

fix: **Newly-added/edited models now appear for returning browsers.** The model-selection grid (`screens.js`) and the editor config load (`app.js`) fetched `models/models-config.json` with default caching and no `?v=` cache-buster, so a browser holding a cached copy kept showing the old model list — the freshly-deployed Cyborg Beast card was invisible until a hard refresh. Both fetches now use `{ cache: 'no-cache' }` to revalidate against the server (cheap 304 when unchanged, fresh JSON when models change). Bump `index.html` JS cache-buster to 14.33.0.

## v14.32.0 — 2026-07-09

feat: **Integrate the original Cyborg Beast hand** (MakerBlock / e-NABLE — Chicago-screw + elastic-cord mechanical build, distinct from the flexible-joint Flexy Beast). The original palm, two-segment fingers and thumb geometry (`cyborgpalm001` / `cyborgfingermid002` / `cyborgfingertip002`) are wrapped in a new anthropometric parameter layer in `models/active/cyborg-beast/cyborg_beast.scad` and registered as model `cyborg_beast`.
feat: Anthropometric sizing calibrated by measuring the original geometry — whole hand scales by the Cyborg Beast formula `(palm_breadth_mm + 5) / 55`, while each finger is driven independently to its absolute MCP-to-tip length via the design's native `len` lever (inverting the measured reach curve `R = 60.85 + 1.584·len` for len ≥ 0, `+ 1.328·len` for len < 0), with `len` clamped to a print-safe range. Thumb length driven by a uniform, gap-free scale of its two-segment sub-assembly. UI-controlled laterality (`mirrored`, `role:"laterality"`).
feat: Per-part colour customiser (palm + per-segment finger/thumb colours) baked into the 3MF multi-material export, plus a flat print-bed `print_layout` and per-part `show_*` visibility toggles / `parts` map for isolated STL export — matching the Flexy Beast feature set. Full EN + PT captions/help.
chore: Add `tests/cyborg_export.spec.js` — Playwright e2e over the real WASM pipeline: per-segment colour → coloured 3MF (verifies the chosen `displaycolor` is baked in) and a whole-hand combined export carrying all 11 part colours.
chore: Exclude scratch/in-progress build artifacts (`_assembly.*`, `*_preview.png`, `assemblage-*.jpg`) from deploy (`deploy.sh` EXCLUDES) and git (`.gitignore`) so merged-assembly renders and reference photos never ship to prod or get committed. Bump `index.html` JS cache-buster to 14.32.0.

## v14.31.0 — 2026-07-09

refactor: **PEC PHOENIX HAND assembly — gauntlet placed by its hinge.** The gauntlet now rotates about its boss/hinge line instead of its own origin, so `GAUNT_POS` (where the hinge sits — default the measured wrist-ear centre) and `GAUNT_ROT` (forearm tilt about that hinge) are independent — changing the cuff angle no longer slides the hinge off the wrist ears. Added measured `GAUNT_HINGE_LOCAL = [0, 79.005, 1.9]` (boss centre in the gauntlet's own frame) and place it via `translate(GAUNT_POS) rotate(GAUNT_ROT) translate(-GAUNT_HINGE_LOCAL)`.

## v14.30.0 — 2026-07-09

feat: **PEC PHOENIX HAND assembly — hinge pins at every joint.** Added the snap-pins in their measured holes, sized per class from the exploded reference photo (`unlimbed_phoenix_hand/assemblage-main-phoenix-eclatee-fabrication-3d.jpg`): 4 MCP (palm↔proximal) + 4 PIP (proximal↔distal) + 2 thumb (MCP+PIP) at Ø4.5, and 2 bigger wrist pins (palm↔gauntlet) at Ø6 with green dome washers. Each pin is drawn in the SAME placed frame as its digit (a `snap_pin_x()` along the local joint axis), so it sits in the hole and follows the finger through splay/flex/roll. New tunables: `PIN_DIA_*`, `PIN_LEN_*` (per class), `PIN_SHOW_MCP/PIP/THUMB/WRIST` (hide individually), `PIN_OFF_*` (nudge each), `SHOW_WASHERS`; wrist-ear pin centres `WRIST_PIN_A/B` measured at (±, −38, 8).

## v14.29.0 — 2026-07-08

feat: **PEC PHOENIX HAND assembly — full per-distal controls + un-invert default.** Each fingertip now has independent `DIST_OFF[i]` (position nudge x,y,z mm) and `DIST_ROT[i]` (rotation x=tilt/flex, y=roll, z=yaw), plus `TH_DIST_OFF`/`TH_DIST_ROT` for the thumb — all pivoting about the PIP joint so the fork stays mated. Default `DIST_ROT` roll is set to `y=180`, which flips the previously up-curling (inverted) tips down toward the grip. `place_digit()` now takes the offset + rotation and applies both about the PIP. (Trade-off noted for tuning: the 180° roll moves the flexor side dorsal; set `y=0` + a small `x` tilt to keep the flexor palmar instead.)

fix: **thumb orientation — fins now dorsal, aligned to the palm thumb-mount fin.** `TH_ROT` default changed to `[30,35,-120]` so the thumb proximal's clip fins sit dorsal and continue the palm mount fin (measured at (34,-7.5,12.5), tilt45/yaw-40) instead of lying on their side; nudge `TH_ROT` to perfect the fin-to-fin alignment.

feat: **thumb roll-about-own-axis (`TH_ROLL`).** New `TH_ROLL` spins the whole thumb about its own long axis (mirroring the unlimbed Phoenix proximal's 180° fin-up flip) so its clip fins can be rolled to face dorsal and continue the palm mount fin, independently of where `TH_ROT` points the thumb. `place_digit()` gained an optional `roll` param (innermost rotate about local +Y at the MCP, which sits on that axis so the joint stays seated); fingers pass `roll=0`.

## v14.28.0 — 2026-07-08

feat: **PEC PHOENIX HAND — assembled view of the parametric reconstruction.** New `models/active/pec_phoenix_hand/_assembly.scad` seats every parametric part on its **measured** mating feature: the four proximals drop onto the palm's measured finger-ring pins (index/middle at Y40, ring Y36, pinky Y30), each fingertip's PIP fork hole meets the proximal PIP (23.03 mm span), the thumb rides its measured pivot bore (28.7, −9.6, 5.8), and the gauntlet hinges at the wrist ears. All placement lives in a top **TUNABLES** block (per-finger KX/KY/SPLAY/FLEX, distal size + PIP flex, thumb pose, gauntlet pose, per-part visibility/colour); the **MOUNTS** block holds the measured hole positions read out of the part files. The palm is `include`d (its modules need file-globals + a ghost STL that a bare `use` drops), the proximal/distal/gauntlet parts come in via `use<>`; BOSL2's special-var defaults arrive through the palm's own include. Added minimal assembly entry points to the parts: `arm_guard()` wraps the gauntlet's top-level render, `distal_std/short/thumb()` wrap the fingertip sizes, and both the gauntlet and palm standalone renders are now suppressed by a `no_assembly` guard so a driver can drive them. NOTE: renders in desktop OpenSCAD only — the palm/rings/thumb clip to a local ghost STL and three parts pull in BOSL2, so this is **not yet browser-WASM portable** (that, plus anthropometric params + `models-config.json` wiring, is the next phase).

docs: **print-validation per-part 3MF split (Flexy + Paraglider).** Each combined print plate now also ships every printable part as its own colored, bed-seated 3MF under `docs/print-validation/<model>/<age>/parts/` — matching the platform's per-part export modal. Parts are isolated by their toggles, **centered on the bed and dropped to Z=0** (the same drop-to-bed the frontend does), and exported with the per-part colour baked as a 3MF material. Flexy Beast = 12 parts (palm, gauntlet, base+tip of each finger/thumb); Paraglider = 7 parts (palm, 5 fingers, pins); Phoenix was already per-part. Total print-validation set is now 116 `.3mf` files (8 combined plates + 76 individual parts + 32 Phoenix). README updated.

## v14.26.0 — 2026-07-08

docs: **print-validation 3MF set — AI-sized age variations across all three models.** New `docs/print-validation/` follows up `ai_anthropometric_validation.md` by closing the loop from AI numbers to print-ready 3MF. The same Brazilian-male archetype prompt ("Homem 28") is declined into four age groups (`child_8`, `teen_15`, `adult_28`, `elderly_70`) and run through the **live pipeline** (frontend prompt reconstruction → authenticated `POST /api/ai/suggest`, `claude-sonnet-4-6`, dataset grounding active — all 12 runs `grounded: true`) → OpenSCAD 2026 3MF export (mm units, per-part colours as materials). 40 `.3mf` files with `.png` previews: Flexy Beast (whole print plate ×4), Paraglider (disassembled plate ×4), UnLimbited Phoenix (8 parts ×4). Each folder keeps its `params.json` (AI suggestions + grounded flag) and `prompt.txt`. Phoenix `child_8` correctly floors at 82 mm with no `HandPerc_override` bypass (confirms the v14.18.0 fix); exported palm bbox verifies uniform scale (82→90 mm ratio = 1.098 = HandPerc 90/82).

## v14.25.0 — 2026-07-08

feat: **assembled-view render of the UnLimbited Phoenix hand.** `models/active/unlimbed_phoenix_hand/_assembly.scad` places every component in one scene (thermoform palm, four two-segment fingers, thumb, MCP/PIP pivot pins, wrist hinge pins, and the flat gauntlet). Exported presentation meshes committed alongside it: `_assembly.stl`, `_assembly.3mf`, and a `_assembly.png` hero render. Note the STL/3MF are visual triangle-soup meshes, not print-ready solids — the source palm mesh (`Phoenix_Thermo_Palm_2`) is non-watertight, so a normal OpenSCAD export drops it; the committed mesh merges the palm's raw triangles with the rest of the assembly in world coordinates.
fix: **Phoenix assembly finger + thumb joints rebuilt from measured pin holes.** Every joint hole was located in the meshes (enclosed-void flood-fill) and the parts placed so the holes coincide. Proximal phalanges flipped 180° about their long axis so the fork **fins point up** (dorsal) while both pin holes stay on the axis and the tall knuckle (higher part) sits at the MCP/palm end. Fingertips nudged (`PIP_DY/DZ`) so each **distal back hole meets the proximal front (PIP) hole**. Fingers placed so each **proximal back (MCP) hole seats in the palm knuckle pin hole** (measured `(80,-63,5.9)(65,-63,5.9)(55,-63,5.9)(42,-67,5.9)`): `KX=[80,65,55,42]`, `KY=[-66.2,-66.2,-66.2,-70.2]`, `KZ=4.2`. Thumb seated so its MCP hole meets the boss pin hole `(94.6,-111,17)`: `TH_POS=[91.2,-110,16.5]`. Visual pivot pins moved onto the measured hole positions so they run through the joints.
chore: bump front-end `?v=` cache-buster in `index.html` to `14.25.0` to match `package.json`.

## v14.24.0 — 2026-07-01

fix: **cache-bust front-end JS on deploy.** Returning browsers were serving stale cached copies of the static scripts (no `?v=` query, no `Cache-Control` header), so newly deployed strings didn't appear — e.g. the new Colors tab rendered its raw i18n key `cfg.tabColors` because the cached `translations.js` lacked the translation. All local `<script>` tags now carry a `?v=<version>` query (`translations.js`, `i18n.js`, `auth.js`, `footer.js`, `screens.js`, `app.js`); bump it to match `package.json` on each release so a deploy always invalidates the cache. Documented as a `/cpd` safety check. (Production content was already correct — this was purely a client caching problem.)

## v14.23.0 — 2026-07-01

feat: **dedicated Colors tab + per-part colours.** The configuration card gains a **Colors** tab between Parameters and Saved (order: AI Assistant → Parameters → Colors → Saved). `type: "color"` params are split out of the Parameters list and rendered as swatches in the Colors tab, one per printable part; the Parameters tab keeps everything else. Empty/idle states handled (no model → prompt; model without colours → notice). i18n en+pt (`cfg.tabColors`, `cfg.colorsIntro`, …).

feat: **Flexy Beast is now colourable per printable part**, including per finger *segment* (proximal/base and distal/tip separately) — palm, forearm gauntlet, and base+tip of every finger and the thumb (12 colours). Each part's geometry is wrapped in `color()` in both the assembled and print-bed layouts (`fingerlayout` gains `baseCol`/`tipCol`; `handlayout`/`printlayout` pass per-part colours), so the choice shows in the preview and is baked into the 3MF export as a distinct material per part. The silicone grip pad keeps its own `pad_color` overlay (nested `color()` overrides the tip colour on the pad region only). Paraglider was already per-part (7 colours); Phoenix has no printable parts. Verified with the OpenSCAD CLI (both layouts compile manifold with 12 distinct COFF colour groups) and a Playwright end-to-end test (Colors-tab order + 13 swatches + a distal-segment colour baked into the exported 3MF).

## v14.22.0 — 2026-07-01

feat: **colour customiser** — the per-part colour parameters (Paraglider: palm + 5 digits + pins; Flexy Beast: grip pads) now render as native colour **swatches** instead of raw hex text fields, with a live hex readout. Picking a colour flows through the existing parameter pipeline, so the 3D preview repaints immediately and the choice persists in saved configs. Introduces a `type: "color"` parameter kind (`generateParameterControl` renders `<input type="color">`; `updateEditor` quotes it as a SCAD string). Colour params are excluded from the AI sizing list (cosmetic + user-owned), mirroring the laterality exclusion. Captions updated (`preview color` → `colour (preview + 3MF)`), including the Flexy Beast pad help that previously claimed "no effect on the printed STL".

feat: **colours are baked into 3MF export.** 3MF export now renders in colored OFF (COFF) rather than binary STL, so each face's `color()` choice becomes a 3MF material: distinct colours form a `<basematerials>` palette and every triangle carries a `p1` index into it — the core-spec mechanism a multi-material slicer (Bambu/Orca/Prusa MMU) reads to assign a filament per colour. Per-part whole-model exports are rendered, bed-seated, and merged part-by-part in COFF (matching the STL path). The OpenSCAD worker call is refactored into a shared `_runExportWorker(code, out, format)` behind `_renderStlFromCode`/`_renderOffFromCode`. Verified: generated colour 3MF is well-formed OPC XML, `unit=millimeter`, materials round-trip, and loads watertight/seated in trimesh. (Supersedes v14.21.0's uncoloured STL→3MF converter.)

## v14.21.0 — 2026-07-01

feat: export to **3MF** alongside STL. The export modal now has a format selector (STL / 3MF, 3MF marked recommended); every model routes through the modal so the choice is always available (models with no printable `parts` show a single pre-checked "Whole model" row). 3MF is the print-ready modern format — it embeds explicit **millimetre units**, so slicers import at the correct scale instead of guessing from a unitless STL (a real risk for a clinical device). Implemented client-side with zero new dependencies, converting the positioned mesh to an OPC (ZIP) 3MF package at the download step. Multi-part selections zip per-file exactly as before. The "Export STL" button is now labelled "Export"/"Exportar" (i18n en + pt).

## v14.20.0 — 2026-06-29

refactor: make the AI sizing prompt model-driven — first structural step of the universalization roadmap (towards limbs beyond the hand). The hand-specific domain guidance (canonical measurement fields, finger-proportion hint) and the limb noun were hardcoded in `app.js`; they now come from two per-model fields in `models-config.json`: `limb` (e.g. `"hand"`) and `aiGuidance`. The prompt intro reads "prosthetic &lt;limb&gt; model" from config, and the domain-guidance line is injected from the model's `aiGuidance`, so a future lower-limb model (foot/leg) carries its own vocabulary and hints without any code change. Hand-sizing quality is unchanged (verified: same applied parameters, laterality still omitted, grounding intact). Roadmap documented in `docs/ai_anthropometric_validation.md` §9.1.

## v14.19.0 — 2026-06-29

fix: limb side (left/right) is now controlled solely by the user in the UI — the AI no longer infers or overrides it. A UCD evaluation found the AI emitted `mirrored=true` (right hand) regardless of the requested side, so explicit left-hand requests silently produced a right hand (reproducible 4/4) — a safety defect a layperson can't catch until printed. Handedness parameters are now tagged `role: "laterality"` in `models-config.json` (`mirrored` on Flexy Beast & Paraglider, `LeftRight` on Phoenix); `app.js` excludes them from the AI's suggestible parameter list, injects the user's chosen side into the prompt as a fixed fact, and defensively drops any laterality key from `applySuggestions`. Verified: the AI now omits `mirrored` in 9/9 runs (incl. UI-says-left / text-says-right conflict). Designed generically as **laterality** (not "handedness") so it already applies to any future paired limb (arm, foot, leg). The prompt intro was also de-specialised from "prosthetic hand" to "prosthetic" toward broader limb support.

## v14.18.0 — 2026-06-28

fix: the UnLimbited Phoenix Hand print scale can no longer drop below the supported 100% (≈82 mm palm). `HandPerc_override` has a declared range of `[0:160]`, but only `0` (auto) and `100–160` (direct scale) are meaningful — the `1–99` band was a dead zone that bypassed the floor that `palm_breadth_mm` (clamped to 100–160%) enforces. During the AI-sizing simulation the model returned `HandPerc_override = 76` for a child, scaling the Phoenix mesh to 76% (62 mm) — below the minimum the mesh supports, and inconsistently with the woman profile (floored to 100%). Both scale paths in `UnLimbitedPhoenix.scad` are now clamped to 100–160%, so neither an auto-derived small breadth nor a manual override can go sub-100%. Verified: override 76→100% (82.17 mm), 0→82.17 mm, 130→130% (106.8 mm). Found and documented via `docs/phoenix-ai-sim/`.

## v14.17.0 — 2026-06-28

fix: the Paraglider · Hand **Reborn palm** (the default `palm_style`) now resizes to `palm_breadth_mm`. It was frozen at the 83 mm "medium" size for every patient: `scaled_palm()` lives in `paraglider_palm_left.scad`, which is pulled in with `use` (lexically scoped), so it read that file's hardcoded `overall_scale = 1.25` and ignored the anthropometric `overall_scale = palm_breadth_mm / 66.4` computed in the main file. The fingers were unaffected (they receive their scale as a module argument), so a child-sized configuration produced child fingers on an adult palm. Fix re-applies the intended scale at the Reborn call site (`scale(overall_scale / 1.25) scaled_palm()`); verified the palm now scales (breadth 62→84.9 mm, 83→113.7 mm unchanged, 96→131.5 mm) with L/breadth constant. The UnlimbitedV3 palm was already correct (`pg_v3palm.scad` is `include`d). Found via the AI-sizing→STL export simulation (`tests/paraglider-ai-sim/`).

## v14.16.0 — 2026-06-28

fix: AI grounding now picks the right anthropometric population profile. `findBestProfileMatch` (server/services/profileMapping.js) previously anchored almost every patient on *ANSUR I Male 50th Percentile* — the male gender token `'m,'` was a substring of the units `"mm,"`/`"cm,"`, so any description containing a measurement was read as male, and gender/age parsing was English-only. Tokens are now matched on Unicode word boundaries and are multilingual (EN/PT/ES); age parsing understands "anos"/"años"; numeric `age_group` values ("7", "18-30", "80+", "Adult (Military, 17–40)") are bucketed to child/adult/elderly with numeric proximity, so a 7-year-old maps to the age-7 children dataset and a woman to a female dataset.
- feat: optional LLM-based extraction of patient `{gender, age}` (`extractPatientAttributes` in aiService.js, via `claude-haiku-4-5`) anchors grounding for free-text/multilingual descriptions. It runs only when the deterministic parser leaves a gap, and degrades gracefully (falls back to text parsing) on any error or missing key.
- test: add hermetic unit tests for the matcher (`test/profileMapping.test.js`, run with `npm run test:unit`) covering the units-as-male regression, multilingual gender/age parsing, age-group bucketing, and hint overrides.

## v14.15.0 — 2026-06-24

feat: "Export all" STL now lays every part flat on the print bed instead of in the assembled hand pose. Models that render an assembled hand for the on-screen preview (Flexy Beast, Paraglider) switch to a flat print-bed layout only when exporting — the preview stays assembled. Each exported part is seated on Z=0 (the exporter drops every STL's lowest point to the bed), and the "Whole model" single file is built by rendering each part on the bed and merging them into one co-planar plate, so nothing floats or prints as supports-heavy assembled geometry.
- feat: Flexy Beast gains a `print_layout` mode (`printlayout()`) that spreads the palm, gauntlet, four fingers (base + tip), and thumb side-by-side in their native print orientations.
- fix: Paraglider print-bed layout no longer flips finger parts below the bed (parts now rest co-planar on Z=0) and now emits the pivot pins laid flat, so the "Pivot pins" part exports geometry instead of an empty file.
- feat: models can declare an `exportLayout` map in `models-config.json` (e.g. `{ "print_layout": true }`) that the exporter applies to every exported part.
- docs: document the cPanel/Passenger deployment workflow (`./deploy.sh deploy`, dry-run, what needs a cPanel restart, the server-managed `.htaccess`/WASM headers) in `CLAUDE.md` and `README.md`.

## v14.14.0 — 2026-06-22

feat: the appbar help (?) button now opens an anchored help popover instead of a blocking `alert()`. The panel shows a numbered 6-step getting-started walkthrough (pick a model → adjust parameters → AI assistant → import measurements → render & export → save), plus a "More help" section with collapsible documentation: an anatomical field guide (palm/finger/gauntlet measurements) and keyboard/viewer controls, and a contact-support link. Closes on outside click or Esc; fully localised in EN + PT.

## v14.13.1 — 2026-06-16

fix: help button icon now renders its question-mark dot. The appbar help icon (Feather `help-circle`) draws its dot as a zero-length `M12 17h.01` stroke, which is only visible with `stroke-linecap="round"`. The SVG was missing that attribute, so the dot disappeared and the icon looked incomplete. Added `stroke-linecap="round" stroke-linejoin="round"`.

## v14.13.0 — 2026-06-16

fix: Flexy Beast per-part STL export no longer includes the gauntlet in every part. The gauntlet is gated by `show_gauntlet` in the SCAD but was absent from the model's `parts` list, so the per-part export override (which only toggles off variables belonging to a declared part) never set it false — every exported finger/palm STL silently bundled the forearm cuff. Added the gauntlet as its own printable part (`show_gauntlet`), which both excludes it from the other parts' exports and lets it be exported on its own. Verified: palm-only export drops from ~20.6k to 14.4k facets (gauntlet gone); gauntlet-only export is 6.3k facets.

## v14.12.0 — 2026-06-16

feat: add transactional email subsystem (SMTP via nodemailer) powering three flows — self-service "forgot password" (public, non-enumerating `POST /api/auth/forgot-password` that emails a reset link reusing the existing token machinery), email verification on self-service registration (`POST /api/auth/verify-email` + `POST /api/auth/resend-verification`), and an admin "account created" notification when a user is created from the admin panel. New `server/services/emailService.js` lazily builds the SMTP transport and degrades to a logged no-op when SMTP is unconfigured, so nothing breaks until credentials are supplied. Frontend gains a Forgot-password view, a verification view, and handling of `/reset?token=…` and `/verify?token=…` email links (token auto-filled, stripped from the URL); 12 new EN/PT i18n keys (parity 308=308).
feat: email verification is non-breaking and opt-in — new `users.email_verified` column + `email_verification_tokens` table; a migration grandfathers all existing and admin-created accounts to verified. Login enforcement is gated behind the new `REQUIRE_EMAIL_VERIFICATION` env flag (default off): when off, unverified users can still sign in; when on, only unverified self-service registrations are blocked.
chore: add `nodemailer` dependency; document `SMTP_HOST`/`SMTP_PORT`/`SMTP_SECURE`/`SMTP_USER`/`SMTP_PASS`/`MAIL_FROM`/`APP_BASE_URL`/`REQUIRE_EMAIL_VERIFICATION` in `.env.example`; startup log now reports whether SMTP is enabled.

## v14.11.0 — 2026-06-16

refactor: consolidate the Paraglider family from 7 dropdown entries into a single `Paraglider · Hand` model with the variations as in-model options. A new `component` selector (Hand / Tensioner Box / Thermo Gauntlet / UnLimbited Arm) and `palm_style` selector (Phoenix Reborn / Unlimbited v3) replace the separate entries. Implemented by namespacing each component's OpenSCAD source (every internal identifier prefixed, top-level geometry wrapped into a `*_main()` module) so the otherwise-colliding near-duplicate files coexist in one dispatcher via `include`; the bundles are driven by the Hand's shared anthropometric inputs. New `scripts/namespace_scad.py` tool generates the bundles. Each component verified byte-faithful against its standalone render (Box 3246, Gauntlet 2230, Arm/Cuff 10686 facets — exact) through the app's injection + dependency pipeline, zero scoping warnings. Adds `Component` and `Arm` parameter groups (EN/PT). The two integrated-tensioner palm variants were dropped (tensioning is covered by the Tensioner Box component); removed the now-unused `models/active/paraglider/` sources.

## v14.10.0 — 2026-06-15

feat: integrate the Paraglider (Flexible Flyer) prosthetic family by Marcus Mendenhall (parametric Phoenix v2 / UnLimbited v3 / Phoenix Reborn remix using commercial metal-pin joints). Adds 7 models: `paraglider_hand` (the unified palm+fingers hand — re-activated from inactive/, its missing `palm_left_v2_nobox.stl` supplied, wired into models-config.json with the canonical anthropometric params, per-finger scaling, assembled/print-layout views and `show_*` part toggles), plus `paraglider_palm_v3`, two integrated-tensioner palm variants (Reborn + Unlimbited v3), `paraglider_tensioner_box`, `paraglider_thermo_gauntlet`, and the elbow-powered `paraglider_unlimbited_arm`. Variant palms/accessories live under `models/active/paraglider/` and derive a uniform print scale from a canonical `palm_breadth_mm` (REF anchored to each palm's 1.0× width) with a `scale_override`; the arm keeps its native `HandLen` (mm). New `Engraving` parameter group (EN/PT). All 7 verified rendering under the manifold backend via the app's parameter-injection + dependency-mount pipeline.
fix: source patch — removed an upstream double-comma `[[..],,[..]]` array-literal syntax error (rejected by current OpenSCAD) from the four Paraglider palm files; converted the v3 palm mesh from `.3mf` to `.stl` for WASM import safety.
docs: rewrote docs/paraglider.md to reflect activation + the variant/accessory entries, and corrected the stale claim that the WASM build cannot parse the `each` keyword (the vendored build is OpenSCAD 2025.03.25, which supports it).
chore: removed the redundant `models/inactive/paraglider_hand/` copy now that the model is active.

## v14.9.0 — 2026-06-15

feat: complete the European-Portuguese (pt-PT) translation pass. The admin panel's toast/confirmation messages now go through `t()` with `admin.t*` keys, and the entire anthropometric profile modal (section headings, field labels, hint spans, select options, placeholders, and action buttons — 65 `anth.*` keys) is translated via `data-i18n`/`data-i18n-html`/`data-i18n-placeholder` and switches live with the language selector
docs: add `README.pt.md` — full European-Portuguese README, cross-linked with the English README via a language switcher line

## v14.8.0 — 2026-06-15

feat: European-Portuguese (pt-PT) content. The six footer pages (Help Center, Documentation, Tutorials, Privacy Policy, Terms of Service, Accessibility) now have linked PT translations created via the CMS (`scripts/seed-content.js`), so PT visitors read them in Portuguese. All 37 Flexy Beast parameter ⓘ help tooltips gained `help_pt` translations in `models-config.json`

## v14.7.0 — 2026-06-15

docs: accuracy pass on the remaining docs — bump the Node requirement to ≥22 across DEPLOYMENT.md, DEPLOY-QUICKSTART.md, QUICK-START.md and OVERVIEW.md; replace `better-sqlite3` references with `node:sqlite` (DEPLOYMENT.md note, OVERVIEW.md stack table, TROUBLESHOOTING.md); flag the live cPanel/Passenger path in DEPLOY-QUICKSTART; correct the native-module guidance (bcrypt prebuilt, SQLite built into Node) and the model list (Phoenix added, Paraglider under inactive/)

## v14.6.0 — 2026-06-15

docs: bring README.md up to date — add the UnLimbited Phoenix Hand model (Paraglider kept, marked returning), bump the Node requirement to ≥22 (node:sqlite, no native compile), add the multilingual (EN/PT) and editable footer/content-pages (CMS) features, refresh the deployment notes (cPanel/Passenger, bcrypt prebuilt) and project structure (i18n/footer/markdown/page.html, content route, seed-content.js, models active/inactive), and document the `/api/content/*` endpoints

## v14.5.0 — 2026-06-15

docs: add the live deployment URL (handfab.pedrocandeias.net) to the top of README.md

## v14.4.0 — 2026-06-15

feat: multilingual content pages (CMS). Each language is its own linked page record — the `pages` table gains `language` + `translation_group` columns (auto-migrated on startup; existing pages become their own en group). New `POST /api/content/pages/:id/translate` clones a page into a chosen language, pre-filled from the source, that the admin then edits. The public viewer (`/pages/<slug>?lang=xx`) resolves to the visitor's-language translation within the group, falling back to the original. `page.html` gains a language switcher and re-fetches on change; the admin Pages tab shows a Lang column, per-row "+ LANG" Translate buttons, and a language field on the page form

## v14.3.0 — 2026-06-15

feat: integrate the Team UnLimbited Phoenix Hand V1.0 as a second prosthetic model (`unlimbed_phoenix_hand`). The Phoenix ships as fixed STL-derived meshes, so it exposes a uniform print scale rather than per-finger parameters. To keep it in the anthropometric pipeline, the .scad now derives `HandPerc` from a canonical `palm_breadth_mm` input (REF_PALM_BREADTH = 82 mm at 100%, clamped 100–160%), with an optional `HandPerc_override` for direct scale control. A `part` enum selects which of the 8 printable pieces (Palm, Fingers, Phalanx, Pins, Tension Box, Tension Pins, Gauntlet, Jig) to preview/export. Full EN/PT labels, captions and help text; manifold-backend render verified for all parts.
fix: app.js now quotes string-valued `enum` parameters when injecting them into SCAD source (previously only `string`-type params were quoted), so string enums like the Phoenix `part`/`LeftRight` selectors emit valid OpenSCAD (e.g. `part = "Palm";`).

## v14.2.0 — 2026-06-15

feat: translate the configurator's model + parameter text (EN/PT). models-config.json gains per-language fields (`name_pt`, `description_pt`, and per-parameter `label_pt`/`caption_pt`); app.js reads the active-language field via a `locField()` helper and translates group headings through translations.js. Covers the Flexy Beast model name/description, all 37 parameter labels and captions, and the 6 group headings. The detailed ⓘ help-tooltip paragraphs (`help`) still fall back to English — `help_pt` is supported and can be filled in incrementally

## v14.1.0 — 2026-06-15

feat: extend translations (EN/PT) to the admin panel — app bar, tabs, Users tab (form, table, role/status badges, action buttons), Tech Assignments, and the Footer & Pages editor, plus a switcher in the admin bar and live re-render on language change. ~80 admin keys added. Not yet translated: transient toast messages and the detailed anthropometric measurement form labels (English fallback)

## v14.0.0 — 2026-06-15

feat: the platform is now translatable, with a language switcher (English + Portuguese). New lightweight i18n core (`i18n.js` + `translations.js`): static strings use `data-i18n`/`data-i18n-placeholder`/`data-i18n-title` attributes, JS-generated UI uses a global `t(key, vars)`, and the active language is detected from the browser and persisted in localStorage. Switchers sit in the app bar and on the login page; changing language re-renders the dynamic UI in place (no reload, editor state kept)
feat: this first pass covers the main app — login/setup, dashboard, the configurator (tabs, AI panel, buttons, saved-config controls, "Enable"), profile, and the user menu/greeting. Admin panel, parameter tooltips/model descriptions, and CMS content pages are not yet translated (English fallback)

## v13.11.0 — 2026-06-15

docs: rewrite the Privacy Policy and Terms of Service pages to a broad, open-source "use at your own risk / no warranty / no liability" stance — removed all jurisdiction/legal-entity placeholders. Kept the strong "not a medical device" disclaimer. Updated `scripts/seed-content.js` and re-seeded the live pages

## v13.10.0 — 2026-06-15

fix: the bulk anthropometric CSV importer now keeps age groups as distinct profiles. The `group_name` previously omitted `age_group`, so same-population age bands collapsed to one arbitrary band; it now folds in a normalised age label (e.g. "…, age 19–30 (Country)"). Importing `multi_population_hand.csv` yields ~97 profiles instead of 27 — notably preserving a full pediatric series (Dutch children, ages 2–12) that was being silently dropped

## v13.9.0 — 2026-06-15

fix: raise the JSON request body limit from 1 MB to 8 MB so the admin "Import CSV" bulk anthropometric import works for the bundled `multi_population_hand.csv` (~1.1 MB), which previously exceeded the limit and 413'd

## v13.8.0 — 2026-06-15

fix: the admin "New Profile" (and Edit) anthropometric modal now actually opens. `openNew()`/`openEdit()` show it by adding the `active` class, but there was no `#anthro-modal.active` CSS rule, so it stayed `display:none`. Added `#anthro-modal.active { display: flex; }`

## v13.7.0 — 2026-06-15

feat: show the thermoformable palm-interior mesh by default on the Flexy Beast model — `show_thermoform` default flipped to `true` in both `flexy_beast.scad` and `models-config.json`

## v13.6.0 — 2026-06-15

feat: populate the footer content pages — Help Center, Documentation, Tutorials, Privacy Policy, Terms of Service, and Accessibility now have real Markdown content (added via the new idempotent `scripts/seed-content.js`). The footer Contact column is slimmed to a single email (`mailto:hello@handfab.pedrocandeias.net`) plus a GitHub link; Support/Legal columns link to the pages. Legal pages are general-purpose drafts with bracketed placeholders for jurisdiction/entity — they need legal review

## v13.5.0 — 2026-06-15

chore: remove the printed wrist hinge rod from the Flexy Beast model — dropped the `wrist_pin()` part and its `show_wrist_pin` toggle (also removed from `models-config.json`). The wrist pivot holes, clearance, and strap-flap splay remain, so the gauntlet still articulates on a pin/bolt the user supplies (hole sized by `wrist_pin_dia`)

## v13.4.0 — 2026-06-14

chore: move the gauntlet STL→SCAD reconstruction sources out of the platform model dir into `models/reconstruction/flexy_beast/` (source mesh, organic + primitive variant `.scad`, extracted profile/strap data, exported STLs, build artifacts, + a README). `models/active/flexy_beast/` now holds only the platform file `flexy_beast.scad` (which already inlines the finished gauntlet)
chore: exclude `models/reconstruction/` from deploy (`deploy.sh`) — dev-only material, not shipped to the live platform

## v13.3.0 — 2026-06-14

fix: allow Google Fonts under the CSP — `style-src` now includes `https://fonts.googleapis.com` and a new `font-src` allows `https://fonts.gstatic.com`. Node/Passenger-served pages (e.g. the `/pages/<slug>` viewer) now load the DM Sans brand font instead of falling back to a system font

## v13.2.0 — 2026-06-14

feat: make the Flexy Beast wrist an articulating hinge. Added a printed wrist pin (cap-headed rod) that press-fits the palm wrist fins and lets the gauntlet rotate on it; the gauntlet strap flaps now auto-splay outward to sit just inside the fins for a snug pivot, and their pin holes are drilled round in assembly space (with clearance) so the cuff swings freely
feat: new `[Wrist Hinge]` parameters in `models-config.json` — `show_wrist_pin`, `wrist_pin_dia` (defaults to the finger joint pin size), `wrist_pin_clearance`, `strap_splay_adjust`
refactor: the palm wrist pin hole (`hardwarecutouts`) now sizes to `wrist_pin_dia` instead of a fixed 4 mm

## v13.1.0 — 2026-06-14

feat: add a parametric forearm gauntlet (wrist-powered tensioner cuff) to the Flexy Beast model, reconstructed from `Normal_Gauntlet_w_Tensioner.stl`. Built entirely from primitive shapes — a tapered oval half-pipe tunnel (hull of elliptical discs, shelled, palmar opening cut by a box) plus the tensioner boss, triangular crenellation slots, dorsal holes, and two distal straps
feat: new `[Gauntlet]` parameters exposed in `models-config.json` — `show_gauntlet`, `gauntlet_width_mm` (forearm socket width), `gauntlet_length_mm`, `gauntlet_wall_mm`, `gauntlet_pos_adjust`. The cuff is a separate printed part positioned at the wrist, scaled to its own forearm dimensions (independent of knuckle breadth), with strap-tip pivot holes aligned to the palm's wrist hinge pin axis so it pins on as a hinged forearm piece
chore: gauntlet modules use only core OpenSCAD primitives (no BOSL2) and are `g_`-prefixed/`$fn`-scoped, keeping `flexy_beast.scad` OpenSCAD-WASM compatible and isolated from the hand geometry

## v13.0.0 — 2026-06-14

feat: admin-managed footer + content pages (mini-CMS). New admin "Footer & Pages" tab lets admins edit the footer (brand, tagline, copyright, and add/remove/reorder columns + links, each link → an internal page or external URL) and create/edit/delete Markdown content pages
feat: pages render at clean URLs `/pages/<slug>` via a new `page.html` viewer with a small safe Markdown renderer (`markdown.js`); the footer renders dynamically from `/api/content/footer` (`footer.js`) on every page, with the original markup as fallback
feat: clean URL for the admin panel — `/admin` (drop `.html`); internal links updated (`admin.html` → `/admin`, `index.html` → `/`)
feat: new `server/routes/contentRoutes.js` — `GET /api/content/footer` (public) / `PUT` (admin); `GET /api/content/pages` (admin list), `GET /api/content/pages/:slug` (public published), `POST/PUT/DELETE` (admin). New `site_settings` and `pages` tables in schema.sql (auto-created on startup)

## v12.6.0 — 2026-06-14

fix: the footer now appears on the configurator (`/edit`) and every in-app screen. Replaced the per-screen footers (which existed on selection + profile but were missing from customization) with a single shared footer rendered at the `#app-shell` level. The login/logout page keeps its own footer

## v12.5.0 — 2026-06-14

feat: the model name + description in the configurator is now a collapsible accordion (native `<details>`, closed by default) placed above the tab list, so it's available from all three tabs (AI Assistant, Parameters, Saved) instead of only Parameters. Chevron rotates when open; all element IDs preserved so the populate logic is unchanged

## v12.4.0 — 2026-06-14

feat: soften the Saved Configuration Save/Delete buttons in the configurator — muted emerald `#2bb673` and muted rose-red `#d9596a` (down from the saturated `#22c55e`/`#d4183d`), to sit better with the design. Scoped to `#config-save-btn`/`#config-delete-btn` so admin.html's green buttons are unaffected

## v12.3.0 — 2026-06-14

feat: the URL now reflects the active screen — `/dashboard` (model selection), `/edit` (configurator), `/profile`. Navigating updates the address bar via the History API, and browser back/forward switches screens. On a cold load / deep link the app lands on `/dashboard` (the editor and profile can't be restored from the URL alone). `show()` now syncs the URL; added a `popstate` handler

## v12.2.0 — 2026-06-14

feat: the app-bar logo is now a "back to dashboard" button — clicking it (or focusing + Enter/Space) returns to the model-selection screen and reloads it. Added hover/focus affordances and `role="button"`/`aria-label` for accessibility

## v12.1.0 — 2026-06-14

fix: set `app.set('trust proxy', 1)` so the app works correctly behind the cPanel/Passenger→Apache reverse proxy — fixes the `ERR_ERL_UNEXPECTED_X_FORWARDED_FOR` error from express-rate-limit and gives correct client IPs
docs: note that the frontend uses absolute URLs (`/api/...`, `/models/...`) and therefore must be hosted at a domain/subdomain root, not a sub-path (Passenger does not strip a PassengerBaseURI for Node apps)

## v12.0.0 — 2026-06-13

refactor: replace the `better-sqlite3` native module with Node's built-in `node:sqlite` (`DatabaseSync`). `server/db.js` now imports `node:sqlite` and adds a `db.transaction(fn)` shim (BEGIN/COMMIT/ROLLBACK) so existing call sites (authService) are unchanged; all query call sites use positional params and were already compatible. Removes the only compiled dependency that needed a prebuilt binary, eliminating the glibc/compiler problems on the cPanel host (`bcrypt` remains, but it is N-API with a glibc-2.14 prebuilt and loads everywhere)
chore: **requires Node ≥ 22** (where `node:sqlite` is available); added `engines.node >=22`. The production cPanel app runs on Node 24. Drop `better-sqlite3` from dependencies
docs: update CLAUDE.md DB convention (node:sqlite + transaction shim, Node ≥22)

## v11.5.0 — 2026-06-13

feat: deploy.sh gains cPanel conveniences modelled on the bragagenda script — a hardcoded (editable) default target (pedrocan@pedrocandeias.net:/home/pedrocan/public_html/ai-parametric-prosthetic-hand-generator), `--port` for custom SSH ports, `--dry-run`, and a pre-deploy remote backup (sqlite `.backup` of data/app.db + a code tarball into backups/, excluding data/node_modules/backups). rsync now runs over `ssh -p` and still defaults to no `--delete`; the secret-exclusion safety-net and `collect` staging are unchanged. Post-deploy hint now describes the cPanel Node.js App setup instead of `npm start`

## v11.4.0 — 2026-06-13

docs: add a cPanel (Phusion Passenger) deployment path to DEPLOYMENT.md as "Option C" — create-app-first ordering, `server/index.js` startup file, rsync without `--delete` to preserve Passenger's `.htaccess`, panel-based npm install + env vars, and a native-module (bcrypt/better-sqlite3) build caveat

## v11.3.0 — 2026-06-13

feat: parameter help tooltips now show a detailed "Objective / Outcome" explanation for every Flexy Beast parameter (new `help` field per parameter in `models-config.json`). The tooltip prefers `help` and falls back to the short `caption`; the inline caption line is unchanged. Tooltip widened to 320px for the longer text

## v11.2.0 — 2026-06-13

feat: add help tooltips (ⓘ icon) next to every parameter label in the configurator. Hovering or keyboard-focusing the icon shows the parameter's description in a body-level tooltip that is never clipped by the scrollable panel; the existing always-visible caption line is retained

## v11.1.0 — 2026-06-13

chore: deactivate the Paraglider Hand model — moved `models/active/paraglider_hand/` to `models/inactive/paraglider_hand/` and removed its entry from `models-config.json`, so the configurator now only offers Flexy Beast. Files are retained under `models/inactive/` for future reactivation

## v11.0.0 — 2026-06-06

feat: imported anthropometric datasets now drive the design flow. New `server/services/profileMapping.js` maps a profile's `measurements` (palm.width_mm, digits.*.total_length_mm) onto canonical model parameters, clamped to each parameter's bounds
feat: configurator gains a "Population baseline" picker (AI Assistant panel) — seed the flexy_beast sliders from any imported population group in one click, then fine-tune
feat: AI suggestions are now grounded — `/api/ai/suggest` accepts optional `patient_text`/`model_id`, finds the closest population group (by gender/country/age), and anchors the prompt on its measured means
feat: add `GET /api/anthropometric/options` and `GET /api/anthropometric/:id/model-parameters?model_id=` (requireAuth; population reference data, no PII)
fix: replace the dead `applyGeometryParameters` bridge in app.js, which targeted Kwawu/cyborgbeast parameter names that never matched flexy_beast
docs: update ai_anthropometric_validation.md for grounding — new §2.4 (Dataset grounding), grounding block in Appendix A, limitation #7 (experiments predate grounding), grounded re-validation in Future Work, and a grounding-control note in Reproducibility

## v10.12.0 — 2026-06-06

docs: clarify README population-dataset import — it is a local browser file picker (not a server-path fetch) and the CSV is gitignored/supplied separately, not bundled

## v10.11.0 — 2026-06-06

docs: add Appendix C to ai_anthropometric_validation.md documenting the population dataset bulk-import pipeline (local file picker, mean-row filtering, group_name idempotency, gitignored-dataset caveat)

---

## v10.10.0 — 2026-06-06

docs: refresh `ARCHITECTURE.md`, `OVERVIEW.md`, and `QUICK-START.md` to match the current codebase — replace the removed Fingerator/Cyborg/old `.scad` references with the `models/active/{flexy_beast,paraglider_hand}` layout, document the `/api/anthropometric` route, the `anthropometricImporter` service, and the `anthropometric_profiles`/`password_reset_tokens` tables, add `/data/*` to the blocked-paths/security notes, note `deploy.sh`, and update the Quick Start walkthrough + UI sketch to the Flexy Beast (incl. per-finger base/tip export)

## v10.9.0 — 2026-06-06

docs: add a Deployment section to `README.md` covering `deploy.sh collect`/`deploy`, and note that Flexy Beast fingers export as separate base/tip pieces; update `DEPLOY-QUICKSTART.md` and `DEPLOYMENT.md` to use `./deploy.sh` + `npm ci` instead of the hand-written rsync/`npm install` flow, and fix the stale `fingerator.scad` reference in the server file-tree

## v10.8.0 — 2026-06-06

chore: rework `deploy.sh` into `collect`/`deploy` modes — `./deploy.sh collect [--tar]` stages every server-bound file into `./deploy/` (optionally tars it) without touching the network; `./deploy.sh deploy <user@host:/path> [--delete] [--yes]` collects then rsyncs to the remote. Replaces the deprecated `config.json` gate with the `.env` model and hardens the exclude list so secrets (`.env`), the dev SQLite DB (`data/`), `node_modules`, tests, and local tooling are never shipped; adds a post-stage safety check that aborts if a secret or the DB slips through, and Node-appropriate remote next-steps (`npm ci`, create-admin, `npm start`)
chore: gitignore `deploy/` and `deploy.tar.gz` (deploy staging output)

## v10.7.0 — 2026-06-06

feat: split each Flexy Beast finger into separately exportable base and tip pieces for 3D printing — `flexy_beast.scad` gains per-segment visibility toggles (`show_<finger>_base`/`show_<finger>_tip` for index/middle/ring/pinky/thumb), and `fingerlayout()` / the thumb assembly honour them. Previously each finger exported as one fused STL (base + curved tip); now the printable parts list in `models-config.json` offers a base and a tip per finger so each can be oriented for printing

## v10.6.0 — 2026-06-05

feat: per-part STL export with a selection modal — clicking Export STL on a model that declares printable `parts` now opens a modal to choose the whole model and/or individual parts (with select-all); one selection downloads a single STL, multiple selections download a ZIP. Includes a dependency-free store-only ZIP writer (CRC32 + central directory)
feat: add per-part visibility toggles (`show_palm`/`show_index`/`show_middle`/`show_ring`/`show_pinky`/`show_thumb`) to `flexy_beast.scad`, exposed as Visibility parameters, plus a `parts` map in `models-config.json` so the six components can be isolated and exported separately
refactor: split `exportSTL()` into reusable `runExport()` / `_renderStlFromCode()` / `_buildPartCode()` helpers (the per-part override appends toggle assignments; OpenSCAD honours the last assignment)

## v10.5.0 — 2026-06-05

fix: STL export was completely broken — `exportSTL()` (1) omitted the `--backend manifold` flag that every active model requires, so OpenSCAD produced no output, and (2) ran `atob()` on the worker's output, which is a binary `Uint8Array` (not base64), corrupting/throwing on the rare success. Export now passes the model's `renderBackend` (matching the preview pipeline), wraps the `Uint8Array` directly into the Blob, emits compact `binstl`, and surfaces the real OpenSCAD error on failure instead of a generic message. Verified end-to-end (Playwright): parameter changes flow into a valid 14,440-triangle binary STL download

## v10.4.0 — 2026-06-05

docs: rewrite `docs/ai_anthropometric_validation.md` as a structured academic validation study — abstract, motivation, system architecture, methodology (validation criteria + non-determinism), two experiments with refreshed run data, discussion, limitations/threats to validity, future work, reproducibility, and appendices (prompt template, canonical ranges)

## v10.3.0 — 2026-06-05

docs: extend `docs/ai_anthropometric_validation.md` with an input-spectrum + contralateral/handedness test — direct intact-hand measurements (used verbatim), partial+demographics, and demographics-only, all unilateral amputations; documents that the AI sets `mirrored` to the amputated side correctly but that the mirror rule is currently inferred rather than instructed

## v10.2.0 — 2026-06-05

docs: add `docs/ai_anthropometric_validation.md` — records a representative validation run of the AI sizing flow for Flexy Beast (5 UI-style indirect-proxy profiles), with the prompt template, proposed-value tables, validation checks, and a note that the AI is non-deterministic

## v10.1.0 — 2026-06-05

fix: AI suggestion prompt was hardcoded for the removed "Fingerator" model — it framed the request around nonexistent parameters (`global_scale`, `nominal_clearance`, `print_long_fingers`, `bearing_pocket_diameter`), so suggestions were silently dropped by the `hasOwnProperty` guard in `applySuggestions`; prompt is now model-agnostic, names the current model, and steers the AI toward the canonical anthropometric fields within each parameter's min/max
chore: update Anthropic model from `claude-3-5-sonnet-20241022` to `claude-sonnet-4-6` in `aiService.js`

## v10.0.0 — 2026-06-05

chore: trim the model registry to two active models — Paraglider Hand and Flexy Beast (Flexy Beast is the only fully self-contained parametric model; Paraglider's palm imports a mesh base)
refactor: remove the Kinetic Hand RH60 (parametric) and Phoenix Hand v3 models — SCAD/STL sources and `models-config.json` entries deleted
chore: remove the STL→OpenSCAD reconstruction/conversion toolchain — `tools/` toolkit, `scripts/convert_kinetic_hand.py`, `SKILL.md`, `SPEC.md`, `plan.md`, and the `models/conversion/` upstream sources; this project no longer performs mesh conversion
chore: remove obsolete root debug scripts `test-dependency.js` and `check-ui.js` (exercised the removed kinetic model's auto-link cascade)
docs: rewrite README Available Models, Project Structure, and Credits to reflect the two-model layout; drop the reconstruction docs (`docs/kinetic_hand_rh60_conversion.md`, `docs/parametric_reconstruction_thesis.md`)

## v9.3.0 — 2026-05-26

fix: AI provider 401/403 errors no longer forwarded as HTTP 401 to client — previously an invalid/unconfigured API key caused fetchWithAuth to treat the response as a user session expiry, logging the user out and redirecting to model selection; now remapped to 502
fix: error handler now surfaces messages for explicitly-classified errors (status set on the error object) — previously all 5xx errors returned the opaque "Internal server error" string, hiding useful messages like "ANTHROPIC_API_KEY not configured"
fix: extend palm SVG in model card logo to cover the full hand width (right edge x=125 → x=146) so the gauntlet reaches the pinky finger

## v9.2.0 — 2026-05-25

fix: replace fingerpad_solid custom approximation with direct fingertip_pad() invocation — pad preview now shows the exact silicone piece geometry (the positive of the cavity) rather than an independent slab intersection
fix: remove alpha from pad color() call — pads were semi-transparent at 0.85; now fully opaque so they're clearly visible in the 3D preview
fix: change show_thermoform default to false — the holey thermoform mesh was overlaid on the palm by default, making the whole hand appear see-through; users can enable it when needed

## v9.1.0 — 2026-05-25

feat: add Flexy Beast parametric prosthetic hand model (adapted from daprice/Flexy-Beast, CC BY-SA 4.0) — self-contained SCAD, no STL imports, all geometry driven by canonical anthropometric parameters
feat: add show_pads / pad_color parameters to Flexy Beast — renders installed silicone grip pads as colored solids in the preview cavity
fix: switch preview render pipeline from OFF to 3MF — OFF discards color(); 3MF preserves per-triangle material index; multi-material GLB now built from 3MF basematerials, restoring color display for all models
fix: sync parameterEditor.config from screens.js after loadModels() to prevent stale-cache mismatch where selection grid showed a new model but pe.loadModel() couldn't find it
docs: add docs/flexy_beast.md integration notes

---

## v9.0.0 — 2026-05-21

feat: add parametric dependency system — palm_breadth_mm auto-updates gauntlet_width_mm via configurable ratio when auto-link is enabled
feat: add frontend parameter validation — bounds clamping, anatomical ratio warnings, auto-link toggle per parameter group
feat: add server-side parameter bounds validation — POST/PATCH /api/configurations returns 400 with details for out-of-range values
docs: add drives/dependsOn/ratio metadata schema to models-config.json for kinetic_hand_rh60_parametric

## v8.15.0 — 2026-05-20

feat: main site user menu matches admin style — pill shape, gradient avatar initial, "Hello, {username}" greeting, chevron rotates on open
fix: dropdown items use consistent 0.8125rem sizing and accent-subtle hover; Log Out item styled red; divider before Log Out

## v8.14.0 — 2026-05-20

feat: admin app bar now shows "Hello, {username}" greeting with avatar initial and chevron dropdown
feat: dropdown contains Back to App and Log Out actions; closes on outside click

## v8.13.0 — 2026-05-20

fix: role card content padding increased to 28px/24px to match Figma
fix: role card "Open Dashboard" button uses pill border-radius to match Figma screenshot

## v8.12.0 — 2026-05-20

fix: remove legacy hf-footer from customization screen (replaced by 4-col footer elsewhere)
fix: update _setCustomizationTitle to use breadcrumb format "Customize Your Prosthetic — Type: {name}"
feat: slider fill gradient now driven by --range-pct CSS variable, initialized on render and updated on input

## v8.11.0 — 2026-05-20

feat: role banner redesigned to match Figma — admin gets 2-column grid (Editor Dashboard green + Admin Dashboard purple), tech gets single green card
fix: role banner icons updated to Lucide FileEdit (editor) and Settings (admin) matching Figma imports
fix: role card gradients, border colours, and icon container backgrounds match Figma exactly

---

## v8.10.0 — 2026-05-20

fix: logo gradient corrected to purple-600→pink-600→orange-600 (#a855f7→#ec4899→#f97316) matching Figma HandFabLogo component
fix: added white joint-indicator circles to hand SVG logos across login, app bar, and admin panel
fix: removed "Prosthetic Configurator" subtitle from navbar logos — Figma Header shows logo + "Hand Fab" only
fix: admin panel button text icons replaced with inline SVGs (plus, upload)
fix: admin.html gains -webkit-font-smoothing: antialiased matching main app

---

## v8.9.0 — 2026-05-20

feat: restyle admin panel to match main app design system — DM Sans font, white background, dot pattern, segmented-control tabs, updated cards/tables/badges/buttons/modals

---

## v8.8.0 — 2026-05-20

fix: login card padding reduced to 24px and max-width set to 28rem (448px) to match Figma
fix: login logo enlarged to 48px, labels removed from login inputs, placeholders added, button text changed to "Login"
fix: all footers updated — wrapped in inner container, h4 headings changed to h3, removed "Powered by OpenSCAD" from copyright
fix: login page footer replaced with full 4-column footer matching selection and profile screens

---

## v8.7.0 — 2026-05-20

fix: body background changed to #ffffff (white) matching Figma — animated dot pattern provides the only color, not a blue gradient

---

## v8.6.0 — 2026-05-20

fix: login inputs now use borderless #f3f3f5 fill matching Figma's shadcn --input-background style

---

## v8.5.0 — 2026-05-20

fix: reorder customization tabs — AI Assistant first, Parameters second, Saved third
fix: tab shape changed to segmented-control (muted #ececf0 background, white active tab with shadow) matching Figma
fix: flatten param-item — remove individual gray background/border boxes from parameter items
fix: model card thumbnails now use neutral gray gradients instead of vivid colored ones
fix: model card grid uses fixed 4-column layout (2 at ≤900px, 1 at ≤560px) matching Figma grid-cols-4
fix: --radius-xl reduced to 14px to match Figma's calc(0.625rem + 4px)
fix: hf-container padding reverted to 24px
fix: ai-empty-state now visible by default when no model loaded (AI tab is now default active)

---

## v8.4.0 — 2026-05-20

feat: model cards now use aspect-square full-width thumbnail with hover scale (matching Figma)
feat: section headings changed to larger plain text (no divider line)
feat: hf-container max-width reduced to 1152px (Figma max-w-6xl), customization to 1280px
feat: model card button renamed "Start New" with Plus icon in card title
feat: saved config cards now include "Load Profile" button
feat: app bar — replaced initials circle with User icon SVG, added circular help button
feat: user menu now shows "Welcome, {username}" prefix
feat: selection page heading updated to "Prosthetic Hand Configurator" with larger font (2.25rem)

---

## v8.3.0 — 2026-05-20

feat: align all colors and typography with Figma Make theme — buttons now black (#030213) matching Figma --primary, not blue
feat: replace all indigo focus rings and borders with neutral dark rings (rgba(3,2,19,0.08))
feat: update design tokens: --text-primary → #030213, --text-secondary → #717182, --accent-subtle → #ececf0 (neutral gray)
feat: active tabs now use black-fill white-text pill matching Figma's active tab style
feat: login inputs and button now h-14 (3.5rem) with text-lg (1.0625rem) matching reference
feat: login page now has full-page layout with logo header above the card and footer below
feat: base font-size updated from 15px to 16px matching Figma --font-size

## v8.2.0 — 2026-05-20

feat: implement Hand Fab Figma Make design — transparent login backdrop shows gradient background, updated animated two-dot radial pattern matching reference
feat: add 4-column footer (Support / Contact / Legal) to selection and profile screens
feat: restructure profile screen with Profile Information / Security tabs replacing flat card layout
feat: add role banner on selection screen for admin and tech users with direct Admin Panel / Tech Dashboard link

## v8.1.0 — 2026-05-20

fix: remove redundant "Select Model" card from customization screen — model is already chosen on the selection page
feat: auto-render 3D preview immediately after a model or saved config is loaded from the selection screen
feat: display the model's display name in the customization screen header instead of the internal model ID

## v8.0.0 — 2026-05-20

feat: implement full multi-screen page flow matching Hand Fab reference app (login → selection → customization → profile)
feat: add Selection screen showing available models as cards and saved configurations after login
feat: add Profile screen with account info display and password change form wired to PATCH /api/users/:id/password
feat: add sticky frosted-glass app bar (logo + user menu) shared across all authenticated screens
feat: add screens.js module managing screen transitions, model/config loading, and navigation events
refactor: move configurator layout into #screen-customization with back-to-selection navigation
feat: add "Edit Profile" entry to user dropdown menu
feat: login modal now shows Hand Fab logo and subtitle for visual consistency

## v7.11.0 — 2026-05-20

refactor: replace all inline CSS in index.html with Hand Fab design system theme
feat: add theme.css using OKLCH-based color palette (primary #030213, semantic destructive, muted, accent tokens) matching Hand Fab configurator aesthetic
refactor: convert modal and menu visibility from inline style.display to .active CSS class toggles in auth.js and anthropometric.js
fix: move theme.css to project root so Express static middleware serves it correctly
refactor: remove inline styles from ai-assistant section; add .ai-provider-group, .ai-description, .btn-block, .empty-state utility classes
fix: remove flex: 1 / overflow-y from .parameters so sidebar scrolls the full parameter list rather than clipping it

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
