# Troubleshooting Guide

## Network Error when Loading OpenSCAD Worker

### Symptom
```
NetworkError: A network error occurred.
openscad-worker.js:1
```

### Cause
The OpenSCAD worker.js file is trying to load WASM files, but either:
1. The server isn't serving files with correct MIME types
2. CORS restrictions prevent the worker from loading the WASM file
3. The paths are incorrect

### Solution 1: Use the Correct Server Root

**IMPORTANT:** The server must be started from the `openscad-parameter-editor` directory, NOT from `public`:

```bash
# CORRECT ✅
cd openscad-parameter-editor
python3 -m http.server 8000
# Open http://localhost:8000/public/

# WRONG ❌
cd openscad-parameter-editor/public
python3 -m http.server 8000
# This won't work!
```

### Solution 2: Check MIME Types

Make sure your server sends correct MIME types:
- `.wasm` files should be `application/wasm`
- `.js` files should be `text/javascript`

Python's `http.server` should handle this automatically in Python 3.6+.

### Solution 3: Check File Permissions

Ensure all files are readable:
```bash
cd openscad-parameter-editor/public
chmod 644 *.wasm *.js *.html
```

### Solution 4: Clear Browser Cache

Sometimes the browser caches old versions:
1. Open DevTools (F12)
2. Right-click refresh button
3. Select "Empty Cache and Hard Reload"

### Solution 5: Check Console for Detailed Errors

Open browser DevTools (F12) and check:
1. **Console tab**: Look for JavaScript errors
2. **Network tab**: Check which files failed to load
3. **Sources tab**: Verify all files are loading

## Common Issues

### Issue: "Failed to load WASM"

**Check:**
```bash
ls -lh openscad-parameter-editor/public/*.wasm
```

Should show:
```
-rw-rw-r-- openscad.wasm (9.2MB)
-rw-rw-r-- 24c27bd4337db6fc47cb.wasm (9.2MB)
```

If files are missing, copy them again:
```bash
cp openscad-playground/dist/*.wasm openscad-parameter-editor/public/
cp openscad-playground/dist/openscad-worker.js openscad-parameter-editor/public/
```

### Issue: "Cannot find model-viewer"

Copy the model-viewer library:
```bash
cp openscad-playground/public/model-viewer.min.js openscad-parameter-editor/public/
```

### Issue: Rendering Takes Forever

**Tips:**
- First render is slower (WASM initialization)
- Complex models with high `$fn` values take longer
- Check browser console for actual errors
- Try a simpler model first (box instead of gear)

### Issue: Model Doesn't Update

**Solutions:**
1. Check that parameters are changing (watch the value display)
2. Wait for "Rendered in Xms" status message
3. Try clicking "Render Preview" manually
4. Check browser console for errors

## Debugging Steps

### Step 1: Verify Server is Running

```bash
curl http://localhost:8000/public/index.html | head -5
```

Should show HTML content.

### Step 2: Verify WASM Files are Accessible

```bash
curl -I http://localhost:8000/public/openscad.wasm
```

Should show `200 OK` with `Content-Type: application/wasm`

### Step 3: Verify Worker is Accessible

```bash
curl -I http://localhost:8000/public/openscad-worker.js
```

Should show `200 OK` with `Content-Type: application/javascript`

### Step 4: Check Browser Console

Open DevTools (F12) and look for:
- ✅ "Configuration loaded successfully"
- ✅ "Loaded model: Parametric Box"
- ✅ "Rendering preview..."
- ✅ "Rendered in XXXms"

If you see errors, check which file failed to load.

## Browser-Specific Issues

### Firefox
- May block Web Workers in certain security configurations
- Check: `about:config` → `dom.workers.enabled` should be `true`

### Chrome/Edge
- Strict CORS policy
- Must use a proper HTTP server (file:// won't work)

### Safari
- May need "Develop" → "Disable Cross-Origin Restrictions"

## Still Not Working?

### Create a Test File

Create `test.html` in the `public/` directory:

```html
<!DOCTYPE html>
<html>
<head><title>Worker Test</title></head>
<body>
<h1>Worker Test</h1>
<div id="status">Testing...</div>
<script>
try {
    const worker = new Worker('./openscad-worker.js');
    worker.onmessage = (e) => {
        document.getElementById('status').textContent = 'Worker loaded! ' + JSON.stringify(e.data);
    };
    worker.onerror = (e) => {
        document.getElementById('status').textContent = 'Worker error: ' + e.message;
        console.error('Worker error:', e);
    };
    worker.postMessage({test: true});
} catch (e) {
    document.getElementById('status').textContent = 'Failed to create worker: ' + e.message;
    console.error('Worker creation failed:', e);
}
</script>
</body>
</html>
```

Then navigate to `http://localhost:8000/public/test.html`

### Check Server Logs

If using Python http.server, check the terminal output:
```
127.0.0.1 - - [date] "GET /public/openscad-worker.js HTTP/1.1" 200 -
127.0.0.1 - - [date] "GET /public/openscad.wasm HTTP/1.1" 200 -
```

If you see `404` errors, files are missing or paths are wrong.

### Alternative: Use a Different Server

If Python http.server doesn't work, try:

**Node.js (http-server):**
```bash
npx http-server openscad-parameter-editor -p 8000 -c-1
```

**PHP:**
```bash
cd openscad-parameter-editor
php -S localhost:8000
```

**Nginx (production):**
```nginx
server {
    listen 8000;
    root /path/to/openscad-parameter-editor;

    location /public/ {
        try_files $uri $uri/ =404;
    }

    location ~ \.wasm$ {
        types { application/wasm wasm; }
    }
}
```

## Contact/Support

If you're still having issues:
1. Check the browser console (F12 → Console tab)
2. Check the Network tab (F12 → Network tab)
3. Look for red/failed requests
4. Note the exact error message
5. Check this guide for matching solutions

## Quick Checklist

Before asking for help, verify:
- [ ] Server started from correct directory
- [ ] Accessing `http://localhost:8000/public/` (not `file://`)
- [ ] All `.wasm` files present in `public/` directory
- [ ] All `.js` files present in `public/` directory
- [ ] `model-viewer.min.js` present
- [ ] Browser console shows no 404 errors
- [ ] Web Workers enabled in browser
- [ ] No CORS errors in console
- [ ] Tried hard refresh (Ctrl+Shift+R)
