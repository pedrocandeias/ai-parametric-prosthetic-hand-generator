# Quick Deployment Guide

## TL;DR - Deploy in 3 Steps

### Step 1: Configure API Keys

```bash
cd /home/pec/dev/prostfab4/openscad-parameter-editor
cp config.example.json config.json
nano config.json  # Add your real API keys
```

### Step 2: Deploy to Server

```bash
# Using the deployment script
./deploy.sh user@your-server.com:/var/www/html/prosthetic-hand

# OR manually with rsync
rsync -avz --progress \
    --exclude='.git' \
    --exclude='deploy' \
    . user@your-server.com:/var/www/html/prosthetic-hand/
```

### Step 3: Set Permissions on Server

```bash
# SSH into your server
ssh user@your-server.com

# Navigate to deployment directory
cd /var/www/html/prosthetic-hand

# Set permissions
chmod 755 .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod 640 config.json

# Set owner (replace www-data with your web server user)
sudo chown -R www-data:www-data .
```

### Step 4: Access Your Application

Open browser and navigate to:
- `http://your-domain.com/`
- OR `http://your-server-ip/`

---

## Troubleshooting

### Application doesn't load
- Check file permissions
- Check web server error logs: `sudo tail -f /var/log/apache2/error.log`

### AI suggestions don't work
- Verify `config.json` has real API keys
- Check browser console (F12) for errors
- Test API key separately

### WASM files don't load
- Check MIME types in `.htaccess`
- Verify `.htaccess` is being read by Apache
- Check: `application/wasm` MIME type is set

### 404 Errors
- Verify files were uploaded correctly
- Check paths in browser Network tab (F12)
- Verify web server document root

---

## File Structure on Server

```
/var/www/html/prosthetic-hand/
├── index.html              # Main application
├── app.js                  # Application logic
├── config.json             # Your API keys (chmod 640)
├── config.example.json     # Template
├── .htaccess              # Apache configuration
├── openscad.wasm          # OpenSCAD WebAssembly
├── openscad-worker.js     # Worker thread
├── browserfs.min.js       # Virtual filesystem
├── model-viewer.min.js    # 3D viewer
├── models/
│   ├── models-config.json
│   └── fingerator.scad
└── README.md
```

---

## Important Security Notes

⚠️ **Never commit `config.json` to version control!**

The `.gitignore` file protects you, but always verify before pushing:
```bash
git status  # Should NOT show config.json
```

---

## Need More Details?

See [DEPLOYMENT.md](DEPLOYMENT.md) for:
- Nginx configuration
- HTTPS setup with Let's Encrypt
- Server-side API proxy (most secure)
- Performance optimization
- Monitoring and logging

---

## Quick Commands Reference

```bash
# Deploy
./deploy.sh user@server.com:/var/www/html/prosthetic-hand

# Check server logs
ssh user@server.com "tail -f /var/log/apache2/error.log"

# Update config remotely
scp config.json user@server.com:/var/www/html/prosthetic-hand/

# Restart web server
ssh user@server.com "sudo systemctl restart apache2"
```
