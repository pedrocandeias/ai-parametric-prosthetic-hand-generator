# Troubleshooting

## Server won't start

### "JWT_SECRET env var must be set"

The server requires a `JWT_SECRET` of at least 32 characters.

```bash
# Generate one
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
# Paste into .env:
JWT_SECRET=<output>
```

If there is no `.env` file yet:
```bash
cp .env.example .env
nano .env
```

### `Cannot find module 'express'` / `Cannot find module 'better-sqlite3'`

Dependencies are not installed:
```bash
npm install
```

### Port already in use

```bash
PORT=3001 node server/index.js
# or edit PORT= in .env
```

---

## Login / Auth issues

### Login loop — keeps returning to the login screen

1. Clear the `refresh_token` cookie in your browser (DevTools → Application → Cookies)
2. If you changed `JWT_SECRET` since last login, all sessions are invalidated — log in again
3. Check the server logs for `Invalid or expired token` to confirm

### "Invalid credentials" when password is correct

- Username/email lookup is case-insensitive — try the exact value you registered with
- If you created the admin via the CLI script, verify no extra spaces in the password

### "Setup already complete" on POST /api/setup/admin

At least one user already exists in the database. Use the Admin Panel to create more users, or log in with the existing admin account.

### Session expires immediately

- `JWT_SECRET` in `.env` must be stable across restarts. If it is randomly generated each time (e.g. from `start-server.sh` without a `.env`), sessions will not survive a restart.
- Set a permanent value in `.env`.

---

## AI suggestions not working

### "ANTHROPIC_API_KEY not configured" / "OPENAI_API_KEY not configured"

Add the key to `.env`:
```env
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
```
Then restart the server (`npm start` / `pm2 restart prosthetic-hand`).

### "AI rate limit exceeded"

You are hitting 10 requests/minute. Wait 60 seconds and try again.

### "AI response was not valid JSON"

The model returned prose instead of JSON. Retry — this is usually transient.

### AI suggest returns 503

The AI provider is down or the key is invalid. Check [status.anthropic.com](https://status.anthropic.com) or the OpenAI status page.

---

## 3D rendering

### 3D viewer blank after selecting a model

1. Open browser DevTools (F12 → Console)
2. Look for errors mentioning `openscad.wasm` or `openscad-worker.js`
3. Ensure those files are present in the project root:
   ```bash
   ls -lh openscad.wasm openscad-worker.js 24c27bd4337db6fc47cb.wasm
   ```
4. Hard-refresh: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)

### "Network error" loading the worker

The server must be started from the project root — `node server/index.js` or `npm start`.
Do **not** open `index.html` directly from the filesystem (`file://` URLs block Web Workers).

### Rendering takes forever / timeout

- First render after page load is slower (WASM initialisation, ~3–5s)
- Complex models with high `$fn` values take longer — this is normal
- 30-second timeout is enforced; if it fires consistently, check console for errors

### Model renders but looks wrong

Click **Reset to Defaults** then **Render Preview**.

---

## Saved configurations

### "Cannot save config for another user"

Non-admin users can only save configs for themselves. If you need to save on behalf of a patient, use an admin or tech account.

### Saved config doesn't appear in the dropdown

The config list filters by the currently selected model. Switch to the correct model first, then the dropdown will populate.

### Tech can't see patient's configs

1. Check the patient is assigned to the tech in the Admin Panel → Tech Assignments tab
2. Verify the patient account is active (not suspended)

---

## Admin panel

### Redirected to `index.html` instead of admin panel

Your session either expired or your account doesn't have the `admin` role. Log in as an admin and retry.

### Role change doesn't take effect immediately

The user's active session still has the old role in their JWT. They need to log out and back in (or wait up to 15 minutes for the access token to expire and refresh).

---

## WASM / browser compatibility

### Chrome / Edge

Works best. Ensure DevTools is closed for first render (slight perf impact with DevTools open).

### Firefox

- Web Workers must be enabled: `about:config` → `dom.workers.enabled` = true
- If CSP errors appear in the console, check that `helmet`'s CSP in `server/index.js` includes `blob:` in `workerSrc`

### Safari

May block Service Workers in private browsing mode. Use a normal window.

---

## Database

### DB file missing or corrupted

```bash
# Back up if possible
cp data/app.db data/app.db.bak

# Delete and let the server recreate it
rm data/app.db
npm start
# Re-run first-admin setup in the browser
```

### "SQLITE_BUSY" errors under load

The SQLite WAL mode is enabled by default (`PRAGMA journal_mode = WAL`), which handles concurrent reads well. For high-concurrency production workloads, consider PostgreSQL via a different ORM.

---

## Deployment / production

### `/.env` returns content instead of 404

The Express block is in `server/index.js` before `express.static`. If you have overridden static serving or added a custom handler, check the middleware order.

### Cookies not set on HTTPS

In production (`NODE_ENV=production`) the refresh cookie has `Secure: true`. Ensure your reverse proxy forwards `X-Forwarded-Proto: https`.

### pm2 process keeps restarting

```bash
pm2 logs prosthetic-hand --lines 50
```

The most common causes:
1. Missing `.env` file or missing `JWT_SECRET`
2. Port conflict — set a different `PORT=` in `.env`
3. Missing `node_modules` — run `npm install --omit=dev`

---

## Quick diagnostic checklist

```bash
# Is the server running?
curl -s http://localhost:3000/api/setup/status

# Is .env loaded?
node -e "require('dotenv').config(); console.log(!!process.env.JWT_SECRET)"

# Are WASM files present?
ls -lh openscad.wasm 24c27bd4337db6fc47cb.wasm openscad-worker.js

# Is the database accessible?
node -e "const db=require('./server/db'); console.log(db.prepare('SELECT COUNT(*) AS n FROM users').get())"

# Are sensitive files blocked?
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/.env          # should be 404
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/config.json   # should be 404
```
