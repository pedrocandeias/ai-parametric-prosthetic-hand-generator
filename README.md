# AI Parametric Prosthetic Hand Generator

**🔗 Live: [handfab.pedrocandeias.net](https://handfab.pedrocandeias.net)**

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
- **STL export** — download print-ready files directly from the browser; models with defined parts offer a selection modal to export the whole model or individual parts (multiple parts download as a ZIP). On the Flexy Beast, each finger splits into a separate **base** and **tip** piece so every printable component can be exported and oriented on its own
- **Admin SCAD code editor** — admins can hand-edit OpenSCAD source and render immediately
- **Anthropometric profile library** — import population-level hand measurement datasets; geometry parameters are auto-derived and mapped to model inputs
- **Bulk CSV import** — load a population hand-measurement dataset (e.g. the `multi_population_hand.csv` research dataset, ~96 groups) through your browser's file picker in one click. The import reads the file locally and uploads its contents; re-running is safe (duplicate groups are skipped)

---

## Available Models

| Model | ID | Parameters | Notes |
|---|---|---|---|
| **Flexy Beast** | `flexy_beast` | All anthropometric params + flexy-joint hardware + grip pads | Fully parametric, self-contained — no external STL imports |
| **Paraglider Hand (Flexible Flyer)** | `paraglider_hand` | All anthropometric params + pivot hardware + channel routing | Parametric fingers; palm imports a repaired Phoenix v2 mesh as its base body |

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

## Deployment

The app is a single Node.js process that serves both the REST API and the static
frontend, so deploying means shipping the source tree (minus secrets, the dev
database, and `node_modules`) and running `npm ci` + `npm start` on the server.

`deploy.sh` automates this in two modes:

```bash
# Stage every server-bound file into ./deploy/ (nothing leaves the machine).
# Add --tar to also produce deploy.tar.gz.
./deploy.sh collect --tar

# Stage, then rsync the package to a remote host.
# Add --delete to mirror (remove stale remote files); --yes to skip the prompt.
./deploy.sh deploy user@your-server.com:/opt/prosthetic-hand --delete
```

The collected package **excludes** secrets (`.env`), the dev SQLite DB (`data/`),
`node_modules`, `.git`, tests, and local tooling — a post-stage safety check
aborts if any of those slip through. `.env.example` *is* included as a template.

On the server, after the files land:

```bash
cd /opt/prosthetic-hand
cp .env.example .env        # then edit: JWT_SECRET + API keys
npm ci --omit=dev           # compiles native modules (better-sqlite3, bcrypt) for this host
node scripts/create-admin.js admin admin@example.com 'StrongPassword!'   # first run only
npm start                   # or run under pm2 / systemd
```

See [DEPLOY-QUICKSTART.md](DEPLOY-QUICKSTART.md) for a pm2 + Nginx walkthrough and
[DEPLOYMENT.md](DEPLOYMENT.md) for the full production guide (systemd, TLS, backups).

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
│   └── active/
│       ├── flexy_beast/                     Flexy Beast — self-contained parametric SCAD
│       └── paraglider_hand/                 Paraglider Hand — parametric SCAD + palm mesh base
│
├── docs/
│   ├── flexy_beast.md              Flexy Beast model notes
│   └── paraglider.md              Paraglider Hand model notes
│
├── data/                          (gitignored — created/supplied locally, not in the repo)
│   ├── app.db                      SQLite DB (auto-created on first run)
│   └── multi_population_hand.csv   Population hand measurements (~96 groups; supply separately)
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

The dataset CSV is **not bundled in the repo** (`data/` is gitignored). Obtain
`multi_population_hand.csv` separately and place it anywhere on your machine first.

1. Log in as admin → open **Admin Panel**
2. Go to **Anthropometric Profiles** tab
3. Click **⬆ Import CSV Dataset** — your browser opens a file picker. Browse to wherever you
   saved `multi_population_hand.csv` (in this project it lives at `data/`) and choose it. The
   file is read locally in the browser and its contents are uploaded; the app does not fetch it
   by path.
4. A confirmation shows how many profiles were created (re-importing is safe — duplicate groups
   are skipped)

> The CSV must conform to the bulk-import schema (columns `measurement_name`, `population`,
> `country`, `sex`, `age_group`, `stat_type`, `value_mm`, …); only `mean` rows are imported.
> See [docs/ai_anthropometric_validation.md](docs/ai_anthropometric_validation.md) Appendix C
> for the full pipeline.

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
- [Flexy Beast](https://www.thingiverse.com/thing:380665) by daprice — a mashup of the Parametric Cyborg Beast and the Flexy Hand
- [e-NABLE](https://enablingthefuture.org) — open-source prosthetic hand designs (Phoenix / Unlimbited lineage behind the Paraglider Hand)
