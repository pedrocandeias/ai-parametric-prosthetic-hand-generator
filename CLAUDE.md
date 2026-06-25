# CLAUDE.md — Developer Guide for Claude Code

This file tells Claude Code how to work in this repository.

## Project Summary

Node.js/Express backend + vanilla-JS frontend for AI-assisted parametric prosthetic hand design.
OpenSCAD runs entirely in-browser via WebAssembly. The backend handles auth, saved configs, and AI key proxying.

## Commands

```bash
# Install dependencies
npm install

# Start server (requires .env)
npm start                        # node server/index.js
npm run dev                      # node --watch server/index.js  (auto-restart)

# First-run admin (CLI fallback)
node scripts/create-admin.js <username> <email> <password>

# Generate a JWT_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Environment

Copy `.env.example` → `.env` and fill in:
```
JWT_SECRET=<64-char hex string>
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
PORT=3000
NODE_ENV=development
```

**The server will not start correctly without `JWT_SECRET`.**

## Architecture

```
browser
  ├── index.html        main UI
  ├── auth.js           Auth module (access token in memory, refresh cookie)
  └── app.js            ParameterEditor class (OpenSCAD rendering)

server/
  ├── index.js          Express entry point
  ├── db.js             node:sqlite (built-in) + auto-migration
  ├── schema.sql        DB schema
  ├── middleware/
  │   ├── auth.js       requireAuth, requireRole()
  │   └── errorHandler.js
  ├── routes/
  │   ├── setupRoutes.js   /api/setup/*
  │   ├── authRoutes.js    /api/auth/*
  │   ├── userRoutes.js    /api/users/*
  │   ├── configRoutes.js  /api/configurations/*
  │   └── aiRoutes.js      /api/ai/*
  └── services/
      ├── authService.js   bcrypt, JWT, refresh token rotation
      └── aiService.js     Anthropic/OpenAI HTTPS proxy
```

## Key Conventions

- **Auth**: Access tokens go in `Authorization: Bearer <token>` header only. Never store in localStorage. Refresh token lives in HttpOnly cookie.
- **DB**: All queries use Node's built-in `node:sqlite` (`DatabaseSync`, synchronous) — **requires Node ≥ 22**. No native module to compile. `server/db.js` adds a `db.transaction(fn)` shim (BEGIN/COMMIT/ROLLBACK) for better-sqlite3-style call sites. Wrap async-only code (bcrypt, fetch) in `async` route handlers with `try/catch → next(err)`.
- **Validation**: All request bodies validated with `zod` before touching the DB.
- **Error responses**: Always `{ error: "message" }` JSON — never HTML error pages from API routes.
- **RBAC**: `admin` > `tech` > `user`. Tech users can access configs for their assigned patients. Ownership checks are in `configRoutes.js` `canAccessConfig()`.
- **AI keys**: Only read from `process.env` in `server/services/aiService.js`. Never reference `config.json` — it is blocked at the Express level.

## Database Location

`data/app.db` — created automatically on first run. The `data/` directory is gitignored.

## Sensitive Files

These are blocked by Express before static serving and must never be served:
- `/.env` → 404
- `/config.json` → 404
- `/data/*` → 404

Do not add any route that reads from `.env` or `config.json` and forwards values to the client.

## Deployment

The live site runs on **cPanel + Phusion Passenger** at `pedrocandeias.net`
(app root `/home/pedrocan/public_html/sites/handfab`). Deployment is just an
rsync of the working tree — there is no build step; `app.js`, `models/`, and the
`.scad` files are served as-is.

```bash
./deploy.sh deploy --dry-run     # preview exactly what will transfer (no changes)
./deploy.sh deploy               # → configured cPanel target, after a remote DB+code backup
```

- With **no destination argument** it uses the configured cPanel target. Pass
  `user@host:/path` (and `--port N`) to override; `--yes` skips the confirm
  prompt; `--delete` mirrors (removes stale remote files — use with care).
- `deploy.sh` **collects** the tree first, hard-excluding `.env`, `data/` (the
  live SQLite DB), `node_modules/`, `.git/`, `tests/`, and **`.htaccess`**, then
  rsyncs. A post-stage safety check aborts if a secret or `data/` slips through.
- **`.htaccess` is server-managed and never shipped.** It holds the CloudLinux
  Passenger block *and* the `Cross-Origin-Opener-Policy: same-origin` +
  `Cross-Origin-Embedder-Policy: require-corp` headers that the OpenSCAD WASM
  needs (Passenger serves static files bypassing Express, so these live in
  `.htaccess`, not `server/index.js`). If prod 3D rendering breaks, check these
  headers **first**.

**What needs a restart after deploy:**
- **Client-only changes** (`app.js`, `index.html`, `models/`, `.scad`, `auth.js`)
  are live as soon as the browser refetches — no restart needed.
- **Server changes** (`server/**`) need a **Restart** in the cPanel "Setup
  Node.js App" panel; new dependencies also need **Run NPM Install** there.

Full production guide (first-run cPanel app setup, env vars, TLS, backups) is in
[DEPLOYMENT.md](DEPLOYMENT.md); a pm2 + Nginx VPS alternative is in
[DEPLOY-QUICKSTART.md](DEPLOY-QUICKSTART.md).

## Adding a New API Route

1. Create `server/routes/myRoutes.js`
2. Use `requireAuth` and `requireRole()` from `server/middleware/auth.js`
3. Validate body with `zod`
4. Mount in `server/index.js`: `app.use('/api/my', require('./routes/myRoutes'))`

## Adding a New Model

1. Place `.scad` file in `models/`
2. Add entry to `models/models-config.json`
3. The `model_id` validation in `configRoutes.js` picks up new models automatically on restart

## Anthropometric Parameter Alignment

All prosthetic model parameters **must** use the same measurement definitions as the platform's anthropometric import pipeline so that patient profiles imported from CSV auto-populate the correct fields.

**Canonical field names and units** (match these exactly in `.scad` variables and `models-config.json` `name` fields):

| SCAD / config `name` | Anatomical measurement | Typical adult range | Platform source |
|---|---|---|---|
| `palm_breadth_mm` | Knuckle-to-knuckle breadth (metacarpal) | 70–100 mm | `palm_breadth` → `palm.width_mm` |
| `palm_length_mm` | Wrist base to middle MCP line | 90–120 mm | `palm_length` → `palm.length_mm` |
| `palm_thickness_mm` | Palmar to dorsal surface | 22–38 mm | `palm_thickness` → `palm.thickness_mm` |
| `index_finger_length_mm` | Index MCP crease to tip | 55–110 mm | `index_length_total` → `digits.index.total_length_mm` |
| `middle_finger_length_mm` | Middle MCP crease to tip | 60–115 mm | `middle_length_total` → `digits.middle.total_length_mm` |
| `ring_finger_length_mm` | Ring MCP crease to tip | 55–110 mm | `ring_length_total` → `digits.ring.total_length_mm` |
| `pinky_finger_length_mm` | Pinky MCP crease to tip | 40–85 mm | `little_length_total` → `digits.pinky.total_length_mm` |
| `thumb_length_mm` | Thumb MCP crease to tip | 45–80 mm | `thumb_length_total` → `digits.thumb.total_length_mm` |
| `gauntlet_width_mm` | Forearm socket width | 40–90 mm | no direct import; derive as `wrist_circumference_mm / π + clearance` |

**Rules:**
- Use **anatomical MCP-to-tip** for finger lengths — not the finger's Z-span in assembly coordinate space, which is a design-specific fraction of the anatomical length.
- All measurements are in **millimetres**.
- When a SCAD model uses internal reference geometry that differs from the anatomical reference (e.g., an STL finger reach of 48 mm for a 72 mm anatomical reference), encode the anatomical value as `REF_FINGER` and derive the internal scaling ratio, keeping the input parameter anatomically meaningful.
- If a measurement has no platform import equivalent (e.g., `gauntlet_width_mm`), document the derivation in the `caption` field so a clinician can compute it manually.

## Frontend Auth Flow

```
page load
  → Auth.tryRestoreSession()   // POST /api/auth/refresh using cookie
    → ok  → app loads normally
    → fail → showLoginModal()
             → first-run?  → show setup view
             → else        → show login view
```

After login, `Auth.fetchWithAuth(url, opts)` handles token injection and silent refresh on 401.

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| POST /api/auth/login | 5 / 15 min per IP |
| POST /api/auth/register | 3 / hour per IP |
| POST /api/ai/suggest | 10 / min per user |
| All others | 500 / 15 min per IP |

## Changelog Maintenance

**Always update `CHANGELOG.md` as part of every change — no exceptions.** Every code change, however small, must be accompanied by a CHANGELOG entry before the work is considered done. Add a new version block at the top:

```
## vX.Y.Z — YYYY-MM-DD

type: description of change
type: description of change
```

**Version bump rules:**
- `vX.0.0` — **major version**: significant new capability, breaking API/schema change, or architectural overhaul
- `vX.Y.0` — **minor version**: fixes, small additions, refinements, and non-breaking improvements

When in doubt: if the change meaningfully extends what the project can do, bump major. If it corrects or polishes existing behaviour, bump minor.

**Entry types:** `feat`, `fix`, `security`, `refactor`, `docs`, `chore`

**Example:**
```
## v3.1.0 — 2026-03-01

feat: add password reset via email token
fix: correct timezone handling in token expiry
docs: add API rate limit table to ARCHITECTURE.md
```

**Always keep `package.json` `version` in sync with the latest CHANGELOG version.** After writing the CHANGELOG entry, update the `version` field in `package.json` to match (e.g. `"version": "3.1.0"`).
