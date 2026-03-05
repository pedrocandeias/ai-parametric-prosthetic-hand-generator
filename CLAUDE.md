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
  ├── db.js             better-sqlite3 + auto-migration
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
- **DB**: All queries use `better-sqlite3` (synchronous). Wrap async-only code (bcrypt, fetch) in `async` route handlers with `try/catch → next(err)`.
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

## Adding a New API Route

1. Create `server/routes/myRoutes.js`
2. Use `requireAuth` and `requireRole()` from `server/middleware/auth.js`
3. Validate body with `zod`
4. Mount in `server/index.js`: `app.use('/api/my', require('./routes/myRoutes'))`

## Adding a New Model

1. Place `.scad` file in `models/`
2. Add entry to `models/models-config.json`
3. The `model_id` validation in `configRoutes.js` picks up new models automatically on restart

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

Update `CHANGELOG.md` whenever you make a change. Add a new version block at the top:

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
