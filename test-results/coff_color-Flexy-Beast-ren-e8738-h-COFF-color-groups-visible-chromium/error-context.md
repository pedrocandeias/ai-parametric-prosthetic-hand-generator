# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: coff_color.spec.js >> Flexy Beast renders with COFF color groups visible
- Location: tests/coff_color.spec.js:16:1

# Error details

```
Test timeout of 300000ms exceeded.
```

```
Error: page.waitForFunction: Test timeout of 300000ms exceeded.
```

# Page snapshot

```yaml
- generic [ref=e2]:
  - generic [ref=e4]:
    - generic [ref=e5]:
      - img [ref=e6]
      - generic [ref=e18]: Hand Fab
    - generic [ref=e19]:
      - button "Help" [ref=e20] [cursor=pointer]:
        - img [ref=e21]
      - button "A Hello, admin" [ref=e25] [cursor=pointer]:
        - generic [ref=e26]: A
        - generic [ref=e27]: Hello, admin
        - img [ref=e28]
  - generic [ref=e31]:
    - generic [ref=e32]:
      - button "Back" [ref=e33] [cursor=pointer]:
        - img [ref=e34]
        - text: Back
      - generic [ref=e36]: "Customize Your Prosthetic — Type: Flexy Beast"
    - generic [ref=e37]:
      - generic [ref=e39]:
        - generic [ref=e40]:
          - button "AI Assistant" [ref=e41] [cursor=pointer]
          - button "Parameters" [ref=e42] [cursor=pointer]
          - button "Saved" [ref=e43] [cursor=pointer]
        - generic [ref=e45]:
          - heading "AI Parameter Assistant" [level=3] [ref=e46]
          - generic [ref=e47]:
            - generic [ref=e48]: AI Provider
            - combobox "AI Provider" [ref=e49]:
              - option "Anthropic (Claude)" [selected]
              - option "OpenAI (GPT-4)"
          - paragraph [ref=e50]: Describe the patient's anthropometric data (e.g., "woman, 42 years old, 75 kg, 172 cm, arm length 65 cm")
          - textbox "woman, 42 years old, 75kg, 172cm height, portugal, arm length 65cm" [ref=e51]
          - button "Get AI Suggestions" [ref=e52] [cursor=pointer]
      - generic [ref=e53]:
        - generic [ref=e54]:
          - generic [ref=e55]:
            - generic [ref=e56]:
              - heading "3D Preview" [level=3] [ref=e57]
              - paragraph [ref=e58]: Interactive model viewer
            - generic [ref=e59]:
              - button "Reset view" [ref=e60] [cursor=pointer]:
                - img [ref=e61]
              - button "Pan" [ref=e64]:
                - img [ref=e65]
              - button "Zoom in" [ref=e67] [cursor=pointer]:
                - img [ref=e68]
              - button "Zoom out" [ref=e71] [cursor=pointer]:
                - img [ref=e72]
              - button "Fullscreen" [ref=e75] [cursor=pointer]:
                - img [ref=e76]
              - button "Toggle grid" [ref=e78] [cursor=pointer]:
                - img [ref=e79]
              - button "Render" [active] [ref=e85] [cursor=pointer]
              - button "Export STL" [ref=e86] [cursor=pointer]
              - button "Edit Code" [ref=e87] [cursor=pointer]
              - button "Show Log" [ref=e88] [cursor=pointer]
          - generic [ref=e90]:
            - generic [ref=e91]:
              - img "3D model preview. Use mouse, touch or arrow keys to move." [ref=e92]
              - generic:
                - generic:
                  - generic:
                    - img
            - region "Live announcements":
              - status
        - generic [ref=e97]: Ready
```

# Test source

```ts
  1  | // @ts-check
  2  | const { test, expect } = require('@playwright/test');
  3  | 
  4  | const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
  5  | 
  6  | async function login(page) {
  7  |     await page.goto('/');
  8  |     await page.waitForSelector('#login-form', { timeout: 10000 });
  9  |     await page.fill('#login-username', ADMIN.username);
  10 |     await page.fill('#login-password', ADMIN.password);
  11 |     await page.click('#login-form button[type="submit"]');
  12 |     // Wait for model grid (card-based selector)
  13 |     await page.waitForSelector('[data-model-id]', { timeout: 15000 });
  14 | }
  15 | 
  16 | test('Flexy Beast renders with COFF color groups visible', async ({ page }) => {
  17 |     const consoleLogs = [];
  18 |     const consoleErrors = [];
  19 | 
  20 |     page.on('console', msg => {
  21 |         const text = msg.text();
  22 |         consoleLogs.push({ type: msg.type(), text });
  23 |         if (msg.type() === 'error') consoleErrors.push(text);
  24 |     });
  25 | 
  26 |     await login(page);
  27 | 
  28 |     // Select Flexy Beast by clicking its card
  29 |     await page.click('[data-model-id="flexy_beast"]');
  30 | 
  31 |     // Wait for the parameter editor to load (params attached to DOM)
  32 |     await page.waitForSelector('[id*="param-"]', { state: 'attached', timeout: 15000 });
  33 |     await page.waitForTimeout(500);
  34 | 
  35 |     // Confirm the model title shows Flexy Beast (not another model)
  36 |     const titleText = await page.locator('#model-name, .model-title, h2, h3').first().textContent({ timeout: 5000 }).catch(() => '');
  37 |     console.log('Model title:', titleText);
  38 | 
  39 |     // Click Render / Preview button
  40 |     const renderBtn = page.locator('button:has-text("Render"), button:has-text("Preview"), button:has-text("render"), #render-btn, #preview-btn').first();
  41 |     await renderBtn.waitFor({ timeout: 10000 });
  42 |     await renderBtn.click();
  43 | 
  44 |     // Wait for the model-viewer src to be set (GLB loaded) — src is a DOM property, not attribute
> 45 |     await page.waitForFunction(() => {
     |                ^ Error: page.waitForFunction: Test timeout of 300000ms exceeded.
  46 |         const viewer = document.getElementById('viewer');
  47 |         return viewer && viewer.src && viewer.src !== '' && !viewer.src.startsWith('about:');
  48 |     }, { timeout: 120000 });
  49 | 
  50 |     // Extra wait for model-viewer WebGL render
  51 |     await page.waitForTimeout(4000);
  52 | 
  53 |     // Screenshot the result
  54 |     await page.screenshot({ path: 'tests/screenshots/coff_render.png', fullPage: false });
  55 | 
  56 |     // Print all captured logs
  57 |     console.log('\n=== Console logs ===');
  58 |     for (const l of consoleLogs) {
  59 |         console.log(`[${l.type}] ${l.text}`);
  60 |     }
  61 | 
  62 |     // Check for COFF color log
  63 |     const coffLog = consoleLogs.find(l => l.text.includes('COFF color groups'));
  64 |     const glbError = consoleLogs.find(l => l.text.includes('Failed to convert to GLB') || l.text.includes('not found in 3MF'));
  65 |     const offData = consoleLogs.find(l => l.text.includes('output.off') || l.text.includes('OFF'));
  66 | 
  67 |     console.log('\n=== Key findings ===');
  68 |     console.log('COFF color log:', coffLog?.text ?? 'NOT FOUND');
  69 |     console.log('GLB error:', glbError?.text ?? 'none');
  70 |     console.log('Console errors:', consoleErrors);
  71 | 
  72 |     expect(glbError, `GLB conversion error: ${glbError?.text}`).toBeUndefined();
  73 |     expect(coffLog, 'Expected COFF color groups log to appear').toBeDefined();
  74 | });
  75 | 
```