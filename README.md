# AI Parametric Prosthetic Hand Generator

AI-powered parametric prosthetic hand customisation platform. Clinicians enter a patient's anthropometric measurements; an AI model (Claude or GPT-4) suggests optimal design parameters; the result renders in-browser via WebAssembly and exports as STL for 3D printing.

Built on [OpenSCAD](https://openscad.org/) and the [OpenSCAD Playground](https://github.com/openscad/openscad-playground) WASM runtime.

---

## Features

- **In-browser 3D rendering** — OpenSCAD runs entirely in WebAssembly; no server round-trip for rendering
- **AI parameter suggestions** — Claude or GPT-4 analyses anthropometric input and recommends parameter values
- **Six canonical anthropometric parameters** — all models share the same measurement definitions (`palm_breadth_mm`, `palm_length_mm`, `palm_thickness_mm`, `middle_finger_length_mm`, `thumb_length_mm`, `gauntlet_width_mm`) so patient profiles auto-populate model inputs
- **Saved configurations** — named parameter sets stored per patient; load across sessions
- **Multi-user RBAC** — Admin / Tech / User roles; techs manage assigned patients
- **Secure API proxy** — AI keys live server-side only
- **STL export** — download print-ready files directly from the browser
- **Admin SCAD code editor** — admins can hand-edit OpenSCAD source and render immediately
- **Anthropometric profile library** — import population-level hand measurement datasets; geometry parameters are auto-derived and mapped to model inputs
- **Bulk CSV import** — load the bundled `data/multi_population_hand.csv` (96 population groups) in one click
- **STL-to-OpenSCAD reconstruction toolkit** — automated pipeline to convert STL/STEP exports into self-contained parametric SCAD files (see `tools/`)

---

## Available Models

| Model | ID | Parameters | Notes |
|---|---|---|---|
| **e-NABLE Phoenix Hand v3** | `phoenix_hand_v3` | Scale factor, hardware dims, part visibility | OpenSCAD surrogate for the Phoenix Hand |
| **Kinetic Hand RH60** | `kinetic_hand_rh60` | `palm_breadth_mm`, `middle_finger_length_mm`, `gauntlet_width_mm` | STL-wrapper; parts imported from STEP exports |
| **Kinetic Hand RH60 (Parametric)** | `kinetic_hand_rh60_parametric` | All 6 anthropometric params + visibility | Fully parametric via polyhedron() reconstruction; no external STL imports |
| **RBE580 Cable-Driven Hand** | `rbe580_hand` | `palm_width`, `middle_length`, `thumb_length`, assembled view, part visibility | WPI RBE580 design; single-motor cable-driven |
| **Passive Cosmetic Hand** | `passive_hand` | Palm dims, socket dims, handedness | Hollow socket; wrist pylon connector |

---

## Requirements

- Node.js 18+
- An Anthropic or OpenAI API key (for AI suggestions; the app works without one but the suggestion button is disabled)

---

## Getting Started

### 1. Install

```bash
git clone <repo>
cd ai-parametric-prosthetic-hand-generator
npm install
```

### 2. Configure

```bash
cp .env.example .env
```

Edit `.env`:

```env
JWT_SECRET=<run: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
PORT=3000
NODE_ENV=production
```

`JWT_SECRET` is required — the server will not start without it.

### 3. Start

```bash
npm start          # production
npm run dev        # development (auto-restarts on file change)
```

### 4. First-run setup

Navigate to `http://localhost:3000`. The app shows a **First-Run Setup** form — create the admin account. You can then create tech and user accounts from the Admin Panel.

**CLI alternative:**

```bash
node scripts/create-admin.js admin admin@example.com MyPassword123
```

---

## Project Structure

```
/
├── index.html                  Main UI
├── auth.js                     Frontend auth (token in memory, refresh cookie)
├── app.js                      ParameterEditor — rendering, UI, save/load
├── admin.html / admin.js       Admin panel
├── anthropometric.js           Anthropometric importer modal (admin)
├── openscad-worker.js          WASM rendering worker
│
├── models/
│   ├── models-config.json                  Model registry + parameter specs
│   ├── e-NABLE Phoenix Hand v3.scad        Phoenix Hand surrogate
│   ├── kinetic_hand_rh60.scad              Kinetic Hand — STL wrapper
│   ├── kinetic_hand_rh60_parametric.scad   Kinetic Hand — full parametric reconstruction
│   ├── kinetic_hand_finger_middle.scad     Middle finger unit (polyhedron)
│   ├── kinetic_hand_thumb.scad             Thumb unit (polyhedron)
│   ├── kinetic_hand_palm.scad              Palm body (polyhedron)
│   ├── kinetic_hand_gauntlet.scad          Gauntlet + cover (polyhedron)
│   ├── kinetic_hand_wrist.scad             Wrist hinges (polyhedron)
│   ├── rbe580_hand.scad                    RBE580 cable-driven hand
│   ├── passive_hand.scad                   Passive cosmetic hand
│   └── kinetic_hand/                       Source STL files for Kinetic Hand
│
├── tools/                          STL analysis and reconstruction toolkit
│   ├── reconstruct.py              Automated STL → parametric SCAD pipeline
│   ├── stl_info.py                 Phase 1: mesh triage
│   ├── stl_zlevel.py               Phase 2: Z-level structure analysis
│   ├── stl_cross_section.py        Phase 3–4: cross-section slicer
│   ├── stl_normals.py              Phase 4: face normal grouping
│   ├── compare_stl.py              Phase 7: Hausdorff distance comparison
│   ├── hausdorff_from_scad.py      Phase 7: SCAD polyhedron validation
│   ├── validate_polyhedron_scad.py Phase 5: polyhedron data verification
│   ├── gen_middle_finger_scad.py   Generator — middle finger
│   ├── gen_thumb_scad.py           Generator — thumb
│   ├── gen_palm_scad.py            Generator — palm
│   ├── gen_gauntlet_scad.py        Generator — gauntlet
│   ├── gen_wrist_scad.py           Generator — wrist hinges
│   └── README.md                   Tool usage reference
│
├── docs/
│   ├── kinetic_hand_rh60_conversion.md     STL-wrapper approach and limitations
│   └── parametric_reconstruction_thesis.md Methodology write-up (master thesis)
│
├── data/
│   ├── app.db                      SQLite DB (gitignored)
│   └── multi_population_hand.csv   Population hand measurements (96 groups)
│
├── server/
│   ├── index.js                Express server entry point
│   ├── db.js                   SQLite connection (auto-migrates)
│   ├── schema.sql              DB schema
│   ├── middleware/             auth.js, errorHandler.js
│   ├── routes/                 setup, auth, users, configs, ai, anthropometric
│   └── services/              authService.js, aiService.js, anthropometricImporter.js
│
├── scripts/
│   └── create-admin.js         CLI admin creation
│
├── SPEC.md                     STL-to-OpenSCAD reconstruction specification
├── SKILL.md                    Reconstruction methodology (8-phase process)
├── plan.md                     Reconstruction progress checklist
├── CLAUDE.md                   Developer guide for Claude Code
├── CHANGELOG.md                Version history
├── .env.example                Environment template
└── package.json
```

---

## User Roles

| Role | Capabilities |
|---|---|
| **admin** | Full access: manage users, view all configs, tech assignments, SCAD code editor |
| **tech** | Own configs + read/write configs for assigned patients |
| **user** | Own saved configurations only |

---

## Anthropometric Parameters

All models that support auto-population from patient profiles use these canonical parameter names:

| Parameter | Measurement | Typical adult range |
|---|---|---|
| `palm_breadth_mm` | Knuckle-to-knuckle metacarpal breadth | 70–100 mm |
| `palm_length_mm` | Wrist base to MCP knuckle line | 90–120 mm |
| `palm_thickness_mm` | Palmar to dorsal surface | 22–38 mm |
| `middle_finger_length_mm` | MCP crease to middle fingertip | 60–100 mm |
| `thumb_length_mm` | Thumb MCP crease to tip | 45–80 mm |
| `gauntlet_width_mm` | Forearm socket width (≈ wrist circumference / π) | 40–90 mm |

These names must match exactly in `.scad` files and `models-config.json` so patient profiles imported from CSV auto-populate the correct fields.

### Importing the population dataset

1. Log in as admin → open **Admin Panel**
2. Go to **Anthropometric Profiles** tab
3. Click **⬆ Import CSV Dataset** and select `data/multi_population_hand.csv`
4. A confirmation shows how many profiles were created (re-importing is safe — duplicates are skipped)

---

## Adding a Model

1. Place your `.scad` file in `models/`
2. Add an entry to `models/models-config.json`:

```json
{
  "id": "my_model",
  "name": "My Prosthetic Model",
  "description": "...",
  "file": "my_model.scad",
  "parameters": [
    {
      "name": "palm_breadth_mm",
      "type": "number",
      "initial": 83,
      "min": 55,
      "max": 110,
      "step": 1,
      "caption": "Knuckle-to-knuckle palm breadth (mm)",
      "group": "Anthropometric"
    }
  ]
}
```

3. Restart the server — the model appears in the dropdown immediately.

**Parameter types:**

| Type | Control | Notes |
|---|---|---|
| `number` with `min`/`max` | Slider | |
| `number` without `min`/`max` | Number input | |
| `boolean` | Checkbox | |
| `string` | Text input | |

If the model references external STL files via `import()` or `use<>`, list them under `dependencies`:

```json
"dependencies": [
  { "url": "subdir/part.stl", "path": "part.stl" }
]
```

The `url` is relative to `models/` on the server; `path` is where the file lands in the WASM virtual filesystem (must be flat — no subdirectories).

---

## STL to OpenSCAD Reconstruction

The `tools/` directory contains a full pipeline for converting STL/STEP exports into self-contained parametric OpenSCAD files. See `SKILL.md` for the methodology and `SPEC.md` for the project specification.

**Quick start:**

```bash
# Install Python dependencies
pip3 install numpy trimesh scipy shapely networkx rtree numpy-stl

# Triage a part before committing to reconstruction
python3 tools/reconstruct.py models/kinetic_hand/finger_4.stl --triage-only

# Reconstruct a single part (auto-selects polyhedron vs CSG, auto-validates)
python3 tools/reconstruct.py models/kinetic_hand/finger_4.stl \
    --module proximal_phalanx \
    --param middle_finger_length_mm=72 palm_breadth_mm=83 \
    --output models/finger_proximal.scad

# Reconstruct multiple parts with an assembly module
python3 tools/reconstruct.py \
    models/kinetic_hand/finger_4.stl \
    models/kinetic_hand/finger_5.stl \
    --modules proximal_phalanx distal_phalanx \
    --assembly middle_finger \
    --param middle_finger_length_mm=72 palm_breadth_mm=83 \
    --output models/middle_finger.scad

# Validate an existing SCAD against its source STL
python3 tools/reconstruct.py models/kinetic_hand/finger_4.stl \
    --validate models/kinetic_hand_finger_middle.scad \
    --module proximal_phalanx
```

The tool automatically selects between `polyhedron()` encoding (for organic/filleted CAD geometry — oblique-face ratio ≥ 0.40) and a CSG skeleton with TODO markers (for simple prismatic parts). All Kinetic Hand RH60 parts were encoded as `polyhedron()`, achieving 0.000001 mm Hausdorff distance against the source STLs.

---

## API Overview

| Endpoint | Description |
|---|---|
| `GET /api/setup/status` | First-run check |
| `POST /api/setup/admin` | Create first admin |
| `POST /api/auth/login` | Login |
| `POST /api/auth/register` | Self-register |
| `POST /api/auth/refresh` | Rotate tokens via cookie |
| `POST /api/auth/logout` | Revoke refresh token |
| `GET /api/users` | List users (admin) |
| `POST /api/users` | Create user (admin) |
| `GET /api/configurations` | List accessible configs |
| `POST /api/configurations` | Save config |
| `PUT /api/configurations/:id` | Update config |
| `DELETE /api/configurations/:id` | Delete config |
| `POST /api/ai/suggest` | AI parameter suggestion proxy |
| `GET /api/anthropometric` | List anthropometric profiles (admin) |
| `POST /api/anthropometric` | Create profile from manual/CSV/JSON (admin) |
| `POST /api/anthropometric/import-csv-bulk` | Bulk-import population CSV (admin) |
| `GET /api/anthropometric/:id` | Fetch profile with derived geometry params |
| `PUT /api/anthropometric/:id` | Update profile |
| `DELETE /api/anthropometric/:id` | Delete profile |

**Rate limits:** login 5/15 min · register 3/hr · AI suggestions 10/min · all others 500/15 min

---

## Security

- Passwords hashed with bcrypt (cost 12)
- JWT access tokens: 15-minute expiry, stored in JS memory only (never localStorage)
- Refresh tokens: 7-day expiry, stored as SHA-256 hashes, rotated on every use
- `/.env` and `/config.json` return 404 — blocked before static middleware
- All request bodies validated with Zod
- Helmet CSP headers
- AI API keys never leave the server

---

## Configuration Reference

| Variable | Required | Description |
|---|---|---|
| `JWT_SECRET` | Yes | 64-char hex string for JWT signing |
| `ANTHROPIC_API_KEY` | For AI | Claude API key |
| `OPENAI_API_KEY` | For AI | OpenAI API key |
| `PORT` | No | HTTP port (default: 3000) |
| `NODE_ENV` | No | `development` or `production` |

---

## Password Reset (CLI)

```bash
node -e "
const db = require('./server/db');
const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('newpassword', 12);
db.prepare('UPDATE users SET password_hash = ? WHERE username = ?').run(hash, 'admin');
console.log('done');
"
```

---

## Credits

- [OpenSCAD Playground](https://github.com/openscad/openscad-playground) — WASM rendering runtime
- [OpenSCAD](https://openscad.org/) — parametric 3D modelling language
- [Kinetic Hand RH60](https://kinetic.com) — SolidWorks assembly converted to parametric SCAD
- [e-NABLE Phoenix Hand v3](https://enablingthefuture.org) — open-source prosthetic hand design
- [RBE580 Prosthetic Hand](https://github.com/jeffmiscione/RBE580-Project) — WPI RBE580 Fall 2016 (CC BY)
