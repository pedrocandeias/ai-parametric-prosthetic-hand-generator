# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser                                                         │
│                                                                  │
│  index.html ── auth.js ── app.js ── openscad-worker.js          │
│       │           │         │             │                      │
│       │      JWT memory  UI logic    WASM renderer               │
│       │      cookie mgr  save/load   (in Web Worker)            │
└───────┼───────────┼─────────┼─────────────┼────────────────────┘
        │           │         │             │
        │     HTTP/REST   HTTP/REST     (no network)
        │           │         │
┌───────▼───────────▼─────────▼────────────────────────────────────┐
│  Express Server (server/index.js)                                 │
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │
│  │  Static     │  │  API Routes  │  │  Security Middleware     │ │
│  │  Serving    │  │  /api/*      │  │  helmet, rate-limit,     │ │
│  │  (express   │  │              │  │  cookie-parser, morgan   │ │
│  │   .static)  │  │  /api/setup  │  └──────────────────────────┘ │
│  └─────────────┘  │  /api/auth   │                               │
│                   │  /api/users  │  ┌──────────────────────────┐ │
│  Blocked paths:   │  /api/confs  │  │  Auth Middleware         │ │
│  /.env → 404      │  /api/ai     │  │  requireAuth()           │ │
│  /config.json→404 └──────┬───────┘  │  requireRole('admin')    │ │
│  /data/* → 404           │          └──────────────────────────┘ │
└──────────────────────────┼──────────────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼──────────┐
   │  SQLite DB   │  │ authService │  │  aiService     │
   │  (data/      │  │ bcrypt      │  │  Anthropic API │
   │   app.db)    │  │ JWT HS256   │  │  OpenAI API    │
   │              │  │ refresh     │  │  (server-side  │
   │  users       │  │ token       │  │   keys only)   │
   │  configs     │  │ rotation    │  └────────────────┘
   │  assignments │  └─────────────┘
   │  refresh_tok │
   └─────────────┘
```

## Authentication Flow

### Login
```
POST /api/auth/login  { login, password }
  → bcrypt.compare(password, hash)
  → issue JWT access token (15 min, HS256)  → response body
  → issue opaque refresh token (7 days)
      → SHA-256 hash stored in refresh_tokens table
      → raw token set in HttpOnly + SameSite=Strict cookie
```

### Authenticated Request
```
GET /api/configurations
  Authorization: Bearer <access_token>
  → requireAuth middleware: jwt.verify(token, JWT_SECRET)
  → attaches req.user = { sub, username, role }
  → route handler checks RBAC
```

### Token Refresh (silent, on page load or 401)
```
POST /api/auth/refresh
  (no body, cookie sent automatically)
  → consumeRefreshToken():
      1. hash cookie token → look up in DB
      2. check not revoked, not expired, user is active
      3. revoke the old token (rotation)
  → issue new access token + new refresh token
```

### Logout
```
POST /api/auth/logout
  Authorization: Bearer <access_token>
  → revokeRefreshToken(cookie_token)
  → clearCookie('refresh_token')
```

## Role-Based Access Control

| Role | Own Configs | Assigned Patient Configs | All Configs | User Mgmt |
|------|-------------|--------------------------|-------------|-----------|
| user | R/W/D | — | — | — |
| tech | R/W/D | R/W | — | — |
| admin | R/W/D | R/W/D (all) | R/W/D | Full |

Tech assignments are managed via `/api/users/:techId/patients` (admin only).

## Database Schema

```sql
users               -- id, username, email, password_hash, role, is_active
tech_assignments    -- tech_id → user_id (many-to-many)
configurations      -- user_id, model_id, name, parameters (JSON), notes
refresh_tokens      -- user_id, token_hash (SHA-256), expires_at, revoked
```

Cascade deletes: removing a user removes their configs, assignments, and refresh tokens.

## Frontend Modules

### `auth.js` — `Auth` singleton
- `Auth.login(login, password)` — POST /api/auth/login, stores token in closure
- `Auth.fetchWithAuth(url, opts)` — injects `Authorization` header, handles 401 → silent refresh
- `Auth.tryRestoreSession()` — called on page load, attempts cookie-based refresh
- `Auth.logout()` — server revoke + local clear
- Token is **never** written to localStorage or sessionStorage

### `app.js` — `ParameterEditor` class
- `loadConfiguration()` — fetches `models/models-config.json` (public, no auth)
- `getAISuggestions()` — POSTs to `/api/ai/suggest` via `Auth.fetchWithAuth`
- `loadConfigList()` — fetches `/api/configurations?model_id=X`
- `saveCurrentConfig()` — POST or PATCH `/api/configurations`
- `loadSelectedConfig()` — GET `/api/configurations/:id`, applies parameters

### OpenSCAD WASM
Rendering runs entirely in a `Web Worker` (`openscad-worker.js`). No server round-trip for rendering — the `.scad` code is compiled and rendered to `.off`, converted to `.glb` in-browser, displayed via `<model-viewer>`.

## API Reference

### Auth  `/api/auth/`
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/login` | No | Login → access token (body) + refresh cookie |
| POST | `/register` | No | Self-register (role=user) |
| POST | `/logout` | Bearer | Revoke token, clear cookie |
| POST | `/refresh` | Cookie | Rotate tokens |
| GET | `/me` | Bearer | Return `{id, username, email, role}` |

### Setup  `/api/setup/`
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/status` | No | `{needsSetup: bool}` |
| POST | `/admin` | No | Create first admin (403 if users exist) |

### Users  `/api/users/`
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | admin | List all users |
| POST | `/` | admin | Create user |
| GET | `/:id` | admin or self | Get user |
| PATCH | `/:id` | admin | Update role/active |
| DELETE | `/:id` | admin | Soft-delete |
| PATCH | `/:id/password` | admin or self | Change password |
| GET | `/:techId/patients` | admin or tech | List assignments |
| POST | `/:techId/patients` | admin | Assign patient |
| DELETE | `/:techId/patients/:userId` | admin | Remove assignment |

### Configurations  `/api/configurations/`
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | Bearer | Own / assigned / all, filter by `?model_id=` |
| POST | `/` | Bearer | Save config |
| GET | `/:id` | Bearer | Load config (ownership check) |
| PATCH | `/:id` | Bearer | Update config |
| DELETE | `/:id` | Bearer | Delete config |

### AI Proxy  `/api/ai/`
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/suggest` | Bearer | Proxy to Anthropic or OpenAI, rate-limited |

## Security Controls

| Control | Detail |
|---------|--------|
| Password hashing | bcrypt, cost factor 12 |
| Token algorithm | JWT HS256, 256-bit secret from env |
| Refresh token storage | SHA-256 hash in DB; raw token in HttpOnly cookie |
| Token rotation | Each refresh revokes the previous token |
| HTTP security headers | `helmet` with restrictive CSP |
| Rate limiting | `express-rate-limit` per route (see CLAUDE.md) |
| Input validation | `zod` on all request bodies |
| Sensitive file blocking | `.env` and `config.json` return 404 unconditionally |
| AI key exposure | Keys only in `process.env`, never sent to client |
| Soft deletes | Users are deactivated (`is_active=0`), not hard-deleted |

## File Structure

```
/
├── index.html              Main SPA
├── auth.js                 Frontend auth module
├── app.js                  Frontend application logic
├── admin.html              Admin panel
├── admin.js                Admin panel logic
├── anthropometric.js       Anthropometric data importer + profile UI
├── openscad-worker.js      Web Worker (WASM rendering)
├── openscad.wasm           OpenSCAD compiled to WASM
├── 24c27bd4337db6fc47cb.wasm  Secondary WASM module
├── browserfs.min.js        Virtual filesystem for WASM
├── model-viewer.min.js     Google model-viewer
├── favicon.ico
│
├── models/
│   ├── models-config.json      Model definitions & parameters
│   ├── cyborgbeast07l.scad     Cyborg Beast — full hand assembly
│   ├── cyborgpalm001.scad      Cyborg Beast — palm component
│   ├── cyborgfingermid002.scad Cyborg Beast — finger mid segment
│   ├── cyborgfingertip002.scad Cyborg Beast — fingertip
│   ├── paraglider_palm_left.scad  Paraglider/Phoenix Reborn palm
│   ├── pipe.scad               Swept-pipe utility (paraglider dep)
│   ├── fingerator.scad         Fingerator prosthetic finger
│   ├── gripper_box_pieces.scad Gripper box components
│   ├── gear.scad               Parametric involute gear
│   └── box.scad                Parametric box
│
├── server/
│   ├── index.js            Express entry point
│   ├── db.js               Database connection + migration
│   ├── schema.sql          SQLite schema
│   ├── middleware/
│   │   ├── auth.js         requireAuth, requireRole()
│   │   └── errorHandler.js Central error handler
│   ├── routes/
│   │   ├── setupRoutes.js
│   │   ├── authRoutes.js
│   │   ├── userRoutes.js
│   │   ├── configRoutes.js
│   │   └── aiRoutes.js
│   └── services/
│       ├── authService.js  bcrypt, JWT, refresh tokens
│       └── aiService.js    Anthropic/OpenAI HTTPS proxy
│
├── scripts/
│   └── create-admin.js     CLI admin creation fallback
│
├── data/                   SQLite database (gitignored)
│   └── app.db
│
├── package.json
├── .env                    Secrets (gitignored)
├── .env.example            Template
├── .gitignore
├── start-server.sh
├── CLAUDE.md
├── ARCHITECTURE.md         This file
├── README.md
├── OVERVIEW.md
├── QUICK-START.md
├── DEPLOYMENT.md
├── DEPLOY-QUICKSTART.md
├── TROUBLESHOOTING.md
└── CHANGELOG.md
```
