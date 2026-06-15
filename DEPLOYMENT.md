# Deployment Guide

## Overview

The app is a Node.js process serving both the REST API and static frontend files.
For production, run it behind an Nginx reverse proxy with TLS.

---

## Prerequisites

```bash
# Node.js 18+
node --version   # must be 18 or higher

# npm 9+
npm --version

# (recommended) pm2 for process management
npm install -g pm2
```

---

## 1. Upload the Application

```bash
# From your local machine — stage the deployable tree and rsync it up.
# deploy.sh excludes secrets (.env), the dev DB (data/), node_modules, .git,
# tests and local tooling, and aborts if a secret would be shipped.
./deploy.sh deploy user@your-server.com:/opt/prosthetic-hand --delete
```

To inspect the package before sending it anywhere, stage it locally first:

```bash
./deploy.sh collect --tar     # → ./deploy/ and ./deploy.tar.gz
```

Then on the server:

```bash
cd /opt/prosthetic-hand
npm ci --omit=dev
```

---

## 2. Create `.env`

```bash
cd /opt/prosthetic-hand
cp .env.example .env
chmod 600 .env        # restrict read access
nano .env
```

Minimum required:

```env
JWT_SECRET=<64-char hex — run: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
PORT=3000
NODE_ENV=production
```

---

## 3. Create the First Admin

```bash
node scripts/create-admin.js admin admin@yourorg.com 'StrongPassword!'
```

---

## 4. Process Management

### Option A — pm2 (recommended)

```bash
# Start
pm2 start server/index.js --name prosthetic-hand

# Auto-start on reboot
pm2 save
pm2 startup   # follow the printed instructions

# Useful commands
pm2 status
pm2 logs prosthetic-hand
pm2 restart prosthetic-hand
pm2 reload prosthetic-hand   # zero-downtime reload
```

### Option B — systemd

Create `/etc/systemd/system/prosthetic-hand.service`:

```ini
[Unit]
Description=Prosthetic Hand AI Parameter Generator
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/prosthetic-hand
EnvironmentFile=/opt/prosthetic-hand/.env
ExecStart=/usr/bin/node server/index.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable prosthetic-hand
sudo systemctl start prosthetic-hand
sudo systemctl status prosthetic-hand
```

### Option C — cPanel (Phusion Passenger)

On shared cPanel hosting you do **not** run `npm start`, `pm2`, `systemd`, or your own
Nginx. cPanel's **Setup Node.js App** tool runs the app under Phusion Passenger and
proxies your domain to it automatically. The app is already compatible: it reads
`process.env.PORT` (Passenger injects it), loads `dotenv`, and its entry point is
`server/index.js`.

**Order matters — create the app first, then push files into the folder it makes.**

1. **cPanel → Setup Node.js App → Create Application**

   | Field | Value |
   |---|---|
   | Node.js version | 18 or 20 LTS (best native-module compatibility) |
   | Application mode | Production |
   | Application root | e.g. `prosthetic-hand` (under your home dir) |
   | Application URL | your domain/subdomain |
   | Application startup file | `server/index.js` |

2. **Upload the build** into the Application root (`/home/<cpaneluser>/prosthetic-hand`).
   Do **not** ship `node_modules` — `bcrypt` and `better-sqlite3` are native and must be
   compiled on the server. With SSH enabled, rsync the staged tree **without `--delete`**
   so cPanel's Passenger `.htaccess` in the app root is preserved:

   ```bash
   ./deploy.sh deploy <cpaneluser>@<host>:/home/<cpaneluser>/prosthetic-hand
   # custom SSH port? prefix with: RSYNC_RSH="ssh -p 2222"
   ```

3. **Install dependencies** — click **Run NPM Install** in the panel, or via SSH activate
   the venv shown in the panel header, then:

   ```bash
   source ~/nodevenv/prosthetic-hand/<ver>/bin/activate && cd ~/prosthetic-hand
   npm ci --omit=dev
   ```

4. **Environment variables** — add `JWT_SECRET`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`,
   and `NODE_ENV=production` in the panel's *Environment variables* section (leave `PORT`
   to Passenger). This replaces the `.env` file in steps 2–3 above.

5. **First admin + restart** — from the activated venv shell run
   `node scripts/create-admin.js <user> <email> <password>`, then click **Restart**.

> **Gotcha:** if *Run NPM Install* fails, it is almost always the native modules
> (`bcrypt`, `better-sqlite3`) failing to compile on shared hosting. Try a Node version
> with a matching prebuilt binary, or ask the host to permit the build. Skip section 5
> (Nginx) entirely — Passenger handles the reverse proxy and TLS through cPanel.

---

## 5. Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate     /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    # Larger body for API requests
    client_max_body_size 2m;

    # Proxy all traffic to Node
    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Cache large static WASM + GLTF files
    location ~* \.(wasm|glb|stl)$ {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        add_header Cache-Control "public, max-age=2592000, immutable";
    }

    # Compress responses
    gzip on;
    gzip_types text/plain text/css application/json application/javascript
               text/javascript application/wasm;
}
```

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 6. HTTPS with Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
# Certbot auto-renews; verify with:
sudo certbot renew --dry-run
```

---

## 7. File Permissions

```bash
# App files owned by the service user
sudo chown -R www-data:www-data /opt/prosthetic-hand

# .env readable only by owner
chmod 600 /opt/prosthetic-hand/.env

# data/ directory writable by service user (for SQLite)
chmod 750 /opt/prosthetic-hand/data
```

---

## 8. Backup

Back up only the database and environment file:

```bash
# Create daily backup script at /etc/cron.daily/prosthetic-hand-backup
#!/bin/bash
BACKUP_DIR=/var/backups/prosthetic-hand
DATE=$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"
cp /opt/prosthetic-hand/data/app.db "$BACKUP_DIR/app-$DATE.db"
# Keep 30 days
find "$BACKUP_DIR" -name "app-*.db" -mtime +30 -delete
```

```bash
chmod +x /etc/cron.daily/prosthetic-hand-backup
```

---

## 9. Updating

```bash
# On local machine
./deploy.sh deploy user@your-server.com:/opt/prosthetic-hand --delete --yes

# On server
cd /opt/prosthetic-hand
npm ci --omit=dev
pm2 reload prosthetic-hand   # zero-downtime reload
# OR
sudo systemctl restart prosthetic-hand
```

The SQLite schema is applied automatically on startup (`CREATE TABLE IF NOT EXISTS`), so no manual migration is needed for additive schema changes.

---

## 10. Deployment Checklist

- [ ] Node.js 18+ installed
- [ ] `npm install --omit=dev` complete
- [ ] `.env` created with real `JWT_SECRET`, `PORT=3000`, `NODE_ENV=production`
- [ ] AI keys set (if using AI suggestions)
- [ ] First admin created
- [ ] Process manager (pm2 or systemd) configured and enabled
- [ ] Nginx reverse proxy configured
- [ ] HTTPS certificate installed
- [ ] File permissions set (`chmod 600 .env`)
- [ ] Backup cron job configured
- [ ] Smoke test: `GET /api/setup/status` returns `{"needsSetup":false}`
- [ ] Verify `/.env` returns 404
- [ ] Verify `/config.json` returns 404

---

## Monitoring

```bash
# pm2
pm2 logs prosthetic-hand --lines 100
pm2 monit

# systemd
journalctl -u prosthetic-hand -f
journalctl -u prosthetic-hand --since "1 hour ago"

# Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## Environment Variables Quick Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `JWT_SECRET` | Yes | — | ≥32 char secret for JWT signing |
| `ANTHROPIC_API_KEY` | No | — | Enables Claude suggestions |
| `OPENAI_API_KEY` | No | — | Enables GPT-4 suggestions |
| `PORT` | No | 3000 | HTTP port |
| `NODE_ENV` | No | development | Set `production` to enable secure cookies |
