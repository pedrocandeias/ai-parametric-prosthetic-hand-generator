# Quick Deployment

## TL;DR — Deploy in 5 steps

### 1. Upload

```bash
rsync -avz --progress \
    --exclude='.git' --exclude='node_modules' --exclude='data' --exclude='.env' \
    ./ user@your-server.com:/opt/prosthetic-hand/
```

### 2. Install + configure

```bash
ssh user@your-server.com
cd /opt/prosthetic-hand
npm install --omit=dev
cp .env.example .env && chmod 600 .env
nano .env   # set JWT_SECRET and API keys
```

Generate a JWT secret:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3. Create first admin

```bash
node scripts/create-admin.js admin admin@yourorg.com 'StrongPassword!'
```

### 4. Start with pm2

```bash
npm install -g pm2
pm2 start server/index.js --name prosthetic-hand
pm2 save && pm2 startup   # follow printed instructions to enable on reboot
```

### 5. Reverse proxy (Nginx)

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    # ... ssl config ...
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## Smoke Test

```bash
curl https://your-domain.com/api/setup/status
# → {"needsSetup":false}

curl -o /dev/null -w "%{http_code}\n" https://your-domain.com/.env
# → 404

curl -o /dev/null -w "%{http_code}\n" https://your-domain.com/config.json
# → 404
```

---

## Updating

```bash
# Upload new code
rsync -avz --progress \
    --exclude='.git' --exclude='node_modules' --exclude='data' --exclude='.env' \
    ./ user@your-server.com:/opt/prosthetic-hand/

# On server — zero-downtime reload
ssh user@your-server.com "cd /opt/prosthetic-hand && npm install --omit=dev && pm2 reload prosthetic-hand"
```

---

## File Structure on Server

```
/opt/prosthetic-hand/
├── index.html
├── auth.js
├── app.js
├── admin.html
├── admin.js
├── openscad.wasm
├── openscad-worker.js
├── models/
│   ├── models-config.json
│   └── fingerator.scad
├── server/
├── scripts/
├── data/           ← SQLite DB lives here (auto-created)
│   └── app.db
├── .env            ← secrets (chmod 600)
└── package.json
```

---

## Need More?

See [DEPLOYMENT.md](DEPLOYMENT.md) for:
- systemd service unit
- Full Nginx config with TLS
- Backup cron job
- File permissions
- Monitoring commands
