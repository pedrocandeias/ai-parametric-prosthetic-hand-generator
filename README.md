# Prosthetic Hand AI Parameter Generator

AI-powered parametric prosthetic hand customisation tool. Clinicians enter a patient's anthropometric data; an AI model (Claude or GPT-4) suggests optimal 3D-printing parameters; the result is previewed in-browser and exported as STL.

Built on [OpenSCAD Playground](https://github.com/openscad/openscad-playground) for WASM rendering.

---

## Features

- **AI Parameter Suggestions** — Claude or GPT-4 analyses anthropometric input and recommends parameter values
- **Real-time 3D Preview** — OpenSCAD renders in-browser via WebAssembly; no server round-trip
- **Saved Configurations** — Named parameter sets stored per patient; load them across sessions
- **Multi-user RBAC** — Admin / Tech / User roles; techs manage their assigned patients
- **Secure API Proxy** — AI keys live server-side; clients never see them
- **STL Export** — Download print-ready files directly from the browser
- **Admin Panel** — Create users, assign patients to techs, manage anthropometric profiles
- **Anthropometric Profile Library** — Import and store population-level hand measurement datasets; geometry parameters are auto-derived and made available to models
- **Bulk CSV Import** — Load the bundled `multi_population_hand.csv` (96 population groups) into the profile library in one click

---

## Requirements

- Node.js 18+
- An Anthropic or OpenAI API key (for AI suggestions)

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
JWT_SECRET=<generate with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
PORT=3000
NODE_ENV=production
```

### 3. Start

```bash
npm start
```

### 4. First-run setup

Navigate to `http://localhost:3000` — the app shows a **First-Run Setup** form.
Create the admin account. You can then log in and create tech/user accounts from the Admin Panel.

**CLI alternative:**

```bash
node scripts/create-admin.js admin admin@example.com MyPassword123
```

---

## Project Structure

```
/
├── index.html              Main UI
├── auth.js                 Frontend auth (token in memory, refresh cookie)
├── app.js                  ParameterEditor — rendering, UI, save/load
├── admin.html              Admin panel
├── admin.js                Admin panel logic
├── anthropometric.js       Anthropometric importer modal (admin)
├── openscad-worker.js      WASM rendering worker
├── models/
│   ├── models-config.json  Model definitions + parameter specs
│   ├── pekwawu.scad        PeKwawu — Kwawu Arm Wrap for long residual limbs
│   ├── anthropometric_hand.scad     Full parametric prosthetic hand
│   ├── anthropometric_cyborgbeast.scad  Cyborg Beast with anthropometric params
│   └── fingerator.scad     Fingerator prosthetic model (and others)
├── data/
│   ├── app.db              SQLite DB (gitignored)
│   └── multi_population_hand.csv   Population hand measurement reference dataset
├── server/
│   ├── index.js            Express server
│   ├── db.js               SQLite connection (auto-migrates)
│   ├── schema.sql          DB schema
│   ├── middleware/         auth.js, errorHandler.js
│   ├── routes/             setup, auth, users, configs, ai, anthropometric
│   └── services/           authService.js, aiService.js, anthropometricImporter.js
├── scripts/
│   └── create-admin.js     CLI admin creation
├── .env                    Secrets (gitignored)
├── .env.example            Template
└── package.json
```

---

## Configuration Reference

### `.env` variables

| Variable            | Required | Description                        |
| ------------------- | -------- | ---------------------------------- |
| `JWT_SECRET`        | Yes      | 256-bit hex secret for JWT signing |
| `ANTHROPIC_API_KEY` | For AI   | Claude API key                     |
| `OPENAI_API_KEY`    | For AI   | OpenAI API key                     |
| `PORT`              | No       | HTTP port (default: 3000)          |
| `NODE_ENV`          | No       | `development` or `production`      |

### `models/models-config.json` — parameter types

```json
{
  "name": "global_scale",
  "type": "number",
  "initial": 1.25,
  "min": 1.0,
  "max": 2.0,
  "step": 0.01,
  "caption": "Overall scale factor",
  "group": "Scale"
}
```

| Type                    | Control      | Notes |
| ----------------------- | ------------ | ----- |
| `number` (with min/max) | Slider       |       |
| `number` (no min/max)   | Number input |       |
| `boolean`               | Checkbox     |       |
| `string`                | Text input   |       |

Parameter names must match variable names in the `.scad` file exactly.

---

## User Roles

| Role      | Capabilities                                                  |
| --------- | ------------------------------------------------------------- |
| **admin** | Full access: manage users, view all configs, tech assignments |
| **tech**  | Own configs + read/write configs for assigned patients        |
| **user**  | Own saved configurations only                                 |

---

## API Overview

| Base path                                    | Description                                  |
| -------------------------------------------- | -------------------------------------------- |
| `GET /api/setup/status`                      | First-run check                              |
| `POST /api/setup/admin`                      | Create first admin                           |
| `POST /api/auth/login`                       | Login                                        |
| `POST /api/auth/register`                    | Self-register                                |
| `POST /api/auth/refresh`                     | Rotate tokens via cookie                     |
| `POST /api/auth/logout`                      | Revoke token                                 |
| `GET /api/users`                             | List users (admin)                           |
| `POST /api/users`                            | Create user (admin)                          |
| `GET /api/configurations`                    | List accessible configs                      |
| `POST /api/configurations`                   | Save config                                  |
| `POST /api/ai/suggest`                       | AI parameter suggestion proxy                |
| `GET /api/anthropometric`                    | List anthropometric profiles (admin)         |
| `POST /api/anthropometric`                   | Create profile from manual/CSV/JSON (admin)  |
| `POST /api/anthropometric/preview`           | Process profile without saving (admin)       |
| `POST /api/anthropometric/import-csv-bulk`   | Bulk-import multi_population_hand.csv (admin)|
| `GET /api/anthropometric/:id`                | Fetch full profile with geometry params      |
| `PUT /api/anthropometric/:id`                | Update existing profile                      |
| `DELETE /api/anthropometric/:id`             | Delete profile                               |

Full API docs: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Security Notes

- Passwords hashed with bcrypt (cost 12)
- JWT access tokens expire after 15 minutes, stored in JS memory only
- Refresh tokens expire after 7 days, stored as SHA-256 hashes; rotated on every use
- `/.env` and `/config.json` return 404 — served before static middleware
- All inputs validated with Zod
- Helmet CSP headers applied
- Rate limits on login (5/15min), register (3/hr), AI (10/min)

---

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for full production setup with pm2 / systemd / Nginx.

---

## Available Models

| Model | File | Description |
|-------|------|-------------|
| **PeKwawu** | `pekwawu.scad` | Kwawu Arm 3.0 Wrap (CC BY 4.0) — for long forearm residual limbs. Parameters map directly to anthropometric profile fields. |
| **Anthropometric Hand** | `anthropometric_hand.scad` | Full parametric prosthetic hand driven by per-finger phalanx lengths, palm dimensions, and wrist socket geometry. |
| **Anthropometric Cyborg Beast** | `anthropometric_cyborgbeast.scad` | Cyborg Beast geometry reparametrized with anthropometric measurements. |
| **Cyborg Beast** | `cyborgbeast07l.scad` | Classic Cyborg Beast full assembly. |
| **Fingerator** | `fingerator.scad` | Phoenix Reborn / Fingerator prosthetic finger. |
| **Paraglider Palm** | `paraglider_palm_left.scad` | Paraglider Palm left-hand model. |

## Adding Models

1. Put your `.scad` file in `models/`
2. Add an entry to `models/models-config.json` (see format above)
3. Restart the server

The new model appears in the dropdown immediately.

## Anthropometric Profiles

The admin panel's **Anthropometric Profiles** tab lets you build a library of population-level hand measurement datasets. Profiles are processed by `server/services/anthropometricImporter.js` which derives:

- Per-finger phalanx segment lengths (from totals via anatomical ratios)
- Palm structural thickness, finger base width, tendon channel diameter
- Socket internal geometry (diameter, depth, taper) from residual limb measurements
- A `pekwawu` block mapping measurements to Kwawu Arm parameters

### Importing multi_population_hand.csv

The repo ships with `data/multi_population_hand.csv` — 96 population groups from published anthropometric studies. To load them all at once:

1. Log in as admin → open **Admin Panel**
2. Go to **Anthropometric Profiles** tab
3. Click **⬆ Import CSV Dataset** and select `data/multi_population_hand.csv`
4. A toast confirms how many profiles were created (re-importing is safe — duplicates are skipped)

---

## Password Reset (CLI)

If you lose admin credentials, reset via Node:

```bash
node -e "
const db = require('./server/db');
const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('newpassword', 12);
db.prepare('UPDATE users SET password_hash = ? WHERE username = ?').run(hash, 'USERNAME');
console.log('done');
"
```

Replace `newpassword` and `USERNAME` with your new password and target username.


## Credits

- [OpenSCAD Playground](https://github.com/openscad/openscad-playground) — WASM rendering
- [OpenSCAD](https://openscad.org/) — parametric 3D modelling
- [Fingerator](https://www.thingiverse.com/thing:2729448) — prosthetic finger model
- [Kwawu Arm 3.0 Wrap](https://github.com/JacquinBuchanan/Kwawu3Wrap) by Jacqun Buchanan / e-NABLE community — basis for the PeKwawu model (CC BY 4.0)
