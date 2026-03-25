# Changelog

All notable changes are recorded here.

Version format: `MAJOR.MINOR.PATCH`
- Bump **MAJOR** on breaking changes
- Bump **MINOR** on new features
- Bump **PATCH** on bug fixes

Entry format follows [Conventional Commits](https://www.conventionalcommits.org/):
`type: description` — types: `feat`, `fix`, `security`, `refactor`, `docs`, `chore`

---

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
