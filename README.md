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
- **Admin Panel** — Create users, assign patients to techs

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
├── openscad-worker.js      WASM rendering worker
├── models/
│   ├── models-config.json  Model definitions + parameter specs
│   └── fingerator.scad     Fingerator prosthetic model
├── server/
│   ├── index.js            Express server
│   ├── db.js               SQLite connection (auto-migrates)
│   ├── schema.sql          DB schema
│   ├── middleware/         auth.js, errorHandler.js
│   ├── routes/             setup, auth, users, configs, ai
│   └── services/           authService.js, aiService.js
├── scripts/
│   └── create-admin.js     CLI admin creation
├── data/                   SQLite DB (gitignored)
├── .env                    Secrets (gitignored)
├── .env.example            Template
└── package.json
```

---

## Configuration Reference

### `.env` variables

| Variable | Required | Description |
|----------|----------|-------------|
| `JWT_SECRET` | Yes | 256-bit hex secret for JWT signing |
| `ANTHROPIC_API_KEY` | For AI | Claude API key |
| `OPENAI_API_KEY` | For AI | OpenAI API key |
| `PORT` | No | HTTP port (default: 3000) |
| `NODE_ENV` | No | `development` or `production` |

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

| Type | Control | Notes |
|------|---------|-------|
| `number` (with min/max) | Slider | |
| `number` (no min/max) | Number input | |
| `boolean` | Checkbox | |
| `string` | Text input | |

Parameter names must match variable names in the `.scad` file exactly.

---

## User Roles

| Role | Capabilities |
|------|-------------|
| **admin** | Full access: manage users, view all configs, tech assignments |
| **tech** | Own configs + read/write configs for assigned patients |
| **user** | Own saved configurations only |

---

## API Overview

| Base path | Description |
|-----------|-------------|
| `GET /api/setup/status` | First-run check |
| `POST /api/setup/admin` | Create first admin |
| `POST /api/auth/login` | Login |
| `POST /api/auth/register` | Self-register |
| `POST /api/auth/refresh` | Rotate tokens via cookie |
| `POST /api/auth/logout` | Revoke token |
| `GET /api/users` | List users (admin) |
| `POST /api/users` | Create user (admin) |
| `GET /api/configurations` | List accessible configs |
| `POST /api/configurations` | Save config |
| `POST /api/ai/suggest` | AI parameter suggestion proxy |

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

## Adding Models

1. Put your `.scad` file in `models/`
2. Add an entry to `models/models-config.json` (see format above)
3. Restart the server

The new model appears in the dropdown immediately.

---

## Credits

- [OpenSCAD Playground](https://github.com/openscad/openscad-playground) — WASM rendering
- [OpenSCAD](https://openscad.org/) — parametric 3D modelling
- [Fingerator](https://www.thingiverse.com/thing:2729448) — prosthetic finger model
