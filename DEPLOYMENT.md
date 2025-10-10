# Deployment Guide

This guide explains how to deploy the Prosthetic Hand AI Parameter Generator to a web server.

## Prerequisites

- A web server with HTTP/HTTPS support (Apache, Nginx, or similar)
- SSH access to your server
- Domain name or public IP address

## Deployment Steps

### 1. Prepare the Application

On your local machine:

```bash
cd /home/pec/dev/prostfab4/openscad-parameter-editor

# Make sure config.json exists with your API keys
cp config.example.json config.json
# Edit config.json and add your real API keys

# Create a deployment package (exclude development files)
mkdir -p deploy
rsync -av --exclude='deploy' \
         --exclude='.git' \
         --exclude='node_modules' \
         --exclude='.vscode' \
         --exclude='*.log' \
         . deploy/
```

### 2. Upload to Web Server

#### Option A: Using SCP

```bash
# Replace with your server details
SERVER_USER=your_username
SERVER_HOST=your-server.com
SERVER_PATH=/var/www/html/prosthetic-hand

# Upload the files
scp -r deploy/* ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/
```

#### Option B: Using rsync (recommended)

```bash
# Replace with your server details
SERVER_USER=your_username
SERVER_HOST=your-server.com
SERVER_PATH=/var/www/html/prosthetic-hand

# Sync files to server
rsync -avz --progress deploy/ ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/
```

#### Option C: Using FTP/SFTP

Use an FTP client like FileZilla:
1. Connect to your server
2. Navigate to your web directory (e.g., `/var/www/html/`)
3. Create a folder called `prosthetic-hand`
4. Upload all files from the `deploy` folder

### 3. Configure Web Server

#### Apache Configuration

Create or edit `.htaccess` in your deployment directory:

```apache
# Enable CORS for API requests
<IfModule mod_headers.c>
    Header set Access-Control-Allow-Origin "*"
    Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
    Header set Access-Control-Allow-Headers "Content-Type"
</IfModule>

# Set proper MIME types
<IfModule mod_mime.c>
    AddType application/wasm .wasm
    AddType application/json .json
    AddType model/gltf-binary .glb
    AddType model/stl .stl
</IfModule>

# Enable gzip compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript application/json
</IfModule>

# Cache static assets
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType application/wasm "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 week"
    ExpiresByType text/css "access plus 1 week"
    ExpiresByType model/gltf-binary "access plus 1 month"
</IfModule>
```

#### Nginx Configuration

Add to your nginx site configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    root /var/www/html/prosthetic-hand;
    index index.html;

    # Main application
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Serve models
    location /models/ {
        try_files $uri $uri/ =404;
    }

    # Serve config
    location /config.json {
        try_files $uri =404;
    }

    # Set proper MIME types
    location ~ \.wasm$ {
        types { application/wasm wasm; }
        add_header Cache-Control "public, max-age=2592000";
    }

    location ~ \.glb$ {
        types { model/gltf-binary glb; }
        add_header Cache-Control "public, max-age=2592000";
    }

    location ~ \.stl$ {
        types { model/stl stl; }
        add_header Cache-Control "public, max-age=2592000";
    }

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/wasm;
}
```

### 4. Set Correct Permissions

On your server:

```bash
# Navigate to deployment directory
cd /var/www/html/prosthetic-hand

# Set proper ownership (replace www-data with your web server user)
sudo chown -R www-data:www-data .

# Set proper permissions
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

# Protect config.json (optional - make it readable only by web server)
chmod 640 config.json
```

### 5. Configure HTTPS (Recommended)

#### Using Let's Encrypt (Certbot)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx  # For Nginx
# OR
sudo apt-get install certbot python3-certbot-apache  # For Apache

# Get SSL certificate
sudo certbot --nginx -d your-domain.com  # For Nginx
# OR
sudo certbot --apache -d your-domain.com  # For Apache
```

### 6. Test the Deployment

1. Open your browser and navigate to:
   - `http://your-domain.com/` or
   - `http://your-server-ip/`

2. Check that:
   - ✅ Page loads correctly
   - ✅ Model selector works
   - ✅ 3D viewer displays
   - ✅ AI suggestions work (check browser console for API errors)
   - ✅ STL export functions

3. Open browser developer console (F12) and check for:
   - ❌ No 404 errors
   - ❌ No CORS errors
   - ❌ No MIME type errors

## Security Considerations

### Protect API Keys

**Important**: Never commit `config.json` to version control!

Option 1: Use environment variables (recommended for production):

Create a PHP or Node.js backend to serve the config:

```php
<?php
// config-api.php
header('Content-Type: application/json');

$config = [
    'ai' => [
        'provider' => getenv('AI_PROVIDER') ?: 'anthropic',
        'anthropic_api_key' => getenv('ANTHROPIC_API_KEY'),
        'openai_api_key' => getenv('OPENAI_API_KEY')
    ]
];

echo json_encode($config);
?>
```

Then update `app.js` to fetch from `config-api.php` instead of `config.json`.

Option 2: Use server-side proxy for API calls (most secure):

Instead of calling AI APIs directly from the browser, create a backend endpoint that:
1. Receives the anthropometric data from the frontend
2. Makes the API call server-side
3. Returns the suggestions to the frontend

This way, API keys never leave your server.

### File Permissions

```bash
# Recommended permissions
chmod 755 /var/www/html/prosthetic-hand
chmod 755 /var/www/html/prosthetic-hand/models
chmod 644 /var/www/html/prosthetic-hand/*.html
chmod 644 /var/www/html/prosthetic-hand/*.js
chmod 644 /var/www/html/prosthetic-hand/*.wasm
chmod 644 /var/www/html/prosthetic-hand/models/*
chmod 640 /var/www/html/prosthetic-hand/config.json
```

## Troubleshooting

### Files Not Loading

Check:
- Web server has read permissions
- MIME types are configured correctly
- File paths in HTML are correct

### CORS Errors

Add CORS headers:
```apache
Header set Access-Control-Allow-Origin "*"
```

### WASM Not Loading

Check MIME type:
```apache
AddType application/wasm .wasm
```

### 404 Errors

Check:
- Files are in correct location
- Paths in code match server structure
- Web server document root is correct

### API Errors

Check:
- `config.json` exists and has valid API keys
- API keys have correct permissions
- Browser can access `config.json` (check Network tab)
- No CORS issues blocking API calls

## Monitoring

### Check Server Logs

```bash
# Apache
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log

# Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Browser Console

Monitor for:
- JavaScript errors
- Failed network requests
- API response errors

## Updating the Application

```bash
# On local machine, in deploy directory
rsync -avz --progress deploy/ ${SERVER_USER}@${SERVER_HOST}:${SERVER_PATH}/

# On server
cd ${SERVER_PATH}
# Clear any cached files if needed
```

## Performance Optimization

1. **Enable Gzip Compression** - Reduce file sizes
2. **Enable Browser Caching** - Cache static assets
3. **Use CDN** - Serve static files from CDN
4. **Minify JavaScript** - Reduce `app.js` size
5. **Optimize WASM** - Ensure WASM files are served with correct headers

## Backup

Regular backup of:
- `config.json` (API keys)
- `models/` directory (custom models)
- `models-config.json` (model configurations)

```bash
# Create backup
tar -czf backup-$(date +%Y%m%d).tar.gz \
    config.json \
    models/ \
    models-config.json
```

## Support

For issues:
1. Check browser console (F12)
2. Check server logs
3. Verify file permissions
4. Test API keys separately
5. Check this deployment guide

## Quick Deployment Checklist

- [ ] Configure `config.json` with API keys
- [ ] Upload files to server
- [ ] Set correct file permissions
- [ ] Configure web server (Apache/Nginx)
- [ ] Enable HTTPS (recommended)
- [ ] Test all functionality
- [ ] Monitor server logs
- [ ] Set up backups
