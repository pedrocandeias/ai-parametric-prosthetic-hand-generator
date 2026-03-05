# Project Overview

## What This Project Does

A web application for clinicians and prosthetists to:

1. Load parametric OpenSCAD prosthetic hand models
2. Edit parameters using auto-generated sliders, checkboxes, and inputs
3. Preview the 3D model in real-time (rendered in-browser via OpenSCAD WebAssembly)
4. Get AI-suggested parameter values from a patient's anthropometric data
5. Save named configurations per patient and load them later
6. Export customised models as STL files ready for 3D printing

Multi-user support with three roles: **Admin**, **Tech** (prosthetist), and **User** (patient). Techs can see and edit configurations for their assigned patients.

---

## Architecture at a Glance

```
┌──────────────────────────────────────────────────┐
│  Browser                                          │
│                                                   │
│  index.html  auth.js  app.js  openscad-worker.js  │
│   (UI)       (auth)  (logic)  (WASM rendering)    │
└───────────────────┬──────────────────────────────┘
                    │  HTTP/REST
┌───────────────────▼──────────────────────────────┐
│  Node.js / Express  (server/index.js)             │
│                                                   │
│  /api/setup  /api/auth  /api/users                │
│  /api/configurations  /api/ai                     │
│                                                   │
│  Helmet · Rate limits · Cookie parser             │
└──────────┬──────────────────┬────────────────────┘
           │                  │
    ┌──────▼──────┐    ┌──────▼──────┐
    │  SQLite DB  │    │  AI APIs    │
    │  data/app.db│    │  Anthropic  │
    │             │    │  OpenAI     │
    └─────────────┘    └─────────────┘
```

**Key design decisions:**

- OpenSCAD rendering is 100% client-side (WebAssembly). No server load for 3D rendering.
- The server handles auth, persistence, and AI proxying only.
- AI API keys are server-side only — clients never see them.
- Access tokens live in JavaScript memory (not localStorage) for XSS resistance.
- Refresh tokens are stored in HttpOnly cookies (CSRF-resistant via SameSite=Strict).

---

## Key Components

### Frontend

| File | Purpose |
|------|---------|
| `index.html` | Single-page app shell — login modal, sidebar, 3D viewer |
| `auth.js` | `Auth` singleton: login, logout, token storage, silent refresh, `fetchWithAuth` |
| `app.js` | `ParameterEditor` class: model loading, parameter UI, rendering, save/load configs |
| `admin.html` / `admin.js` | Admin panel: user management, tech assignments |
| `openscad-worker.js` | Web Worker that runs OpenSCAD WASM for rendering |

### Backend

| File | Purpose |
|------|---------|
| `server/index.js` | Express app — security middleware, route mounting, static serving |
| `server/db.js` | SQLite connection, auto-applies `schema.sql` on startup |
| `server/services/authService.js` | bcrypt hashing, JWT sign/verify, refresh token management |
| `server/middleware/auth.js` | `requireAuth` and `requireRole()` middleware factories |
| `server/routes/setupRoutes.js` | First-run admin creation (hard-gated) |
| `server/routes/authRoutes.js` | login, register, logout, refresh, me |
| `server/routes/userRoutes.js` | User CRUD + tech-patient assignments |
| `server/routes/configRoutes.js` | Saved configuration CRUD with ownership enforcement |
| `server/routes/aiRoutes.js` | Authenticated proxy to Anthropic/OpenAI |
| `server/services/aiService.js` | Server-side HTTPS calls to AI providers |

### Data

| Table | Purpose |
|-------|---------|
| `users` | Accounts (username, email, bcrypt hash, role, active flag) |
| `tech_assignments` | Many-to-many tech ↔ patient relationships |
| `configurations` | Named saved parameter sets (JSON blob per row) |
| `refresh_tokens` | Hashed refresh tokens with expiry and revocation |

---

## User Roles

| Role | Can do |
|------|--------|
| **admin** | Manage all users, view/edit all configs, assign techs to patients |
| **tech** | View and edit configs for their assigned patients + own configs |
| **user** | View and edit own configs only |

---

## AI Integration

AI calls originate from the **server**, not the browser. The flow is:

1. User types anthropometric data (e.g. `woman, 42yo, 172cm, 75kg, arm 65cm`)
2. `app.js` builds a prompt including current model parameters
3. POST `/api/ai/suggest` — server authenticates the user, applies rate limit
4. `server/services/aiService.js` calls Anthropic or OpenAI using env-var API keys
5. JSON parameter suggestions are returned to the browser and applied to the UI

API keys are read from `process.env` only and are never sent to the client.

---

## OpenSCAD Rendering

Rendering is fully client-side:

1. Parameter controls update the OpenSCAD source code string (in memory)
2. The code is sent to `openscad-worker.js` via `postMessage`
3. The worker runs OpenSCAD WASM, outputs an `.off` mesh
4. `app.js` converts the `.off` to a `.glb` binary
5. `<model-viewer>` displays the result with camera controls

No server involvement. Typical render time: 500ms – 3000ms depending on model complexity.

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 18+ |
| HTTP framework | Express 4 |
| Database | SQLite via better-sqlite3 |
| Auth | bcrypt + JWT (HS256) + HttpOnly cookies |
| Validation | Zod |
| Security headers | Helmet |
| Rate limiting | express-rate-limit |
| 3D rendering | OpenSCAD WebAssembly + Google model-viewer |
| Frontend | Vanilla JavaScript (no framework) |
