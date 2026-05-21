# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: compare_renders.spec.js >> render comparison: STEP mesh vs parametric SCAD
- Location: tests/compare_renders.spec.js:62:1

# Error details

```
TimeoutError: page.waitForSelector: Timeout 15000ms exceeded.
Call log:
  - waiting for locator('#model-select') to be visible
    34 × locator resolved to hidden <select id="model-select">…</select>

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
    - generic [ref=e34]:
      - generic [ref=e35]:
        - img [ref=e37]
        - generic [ref=e40]:
          - generic [ref=e41]: Admin Dashboard
          - generic [ref=e42]: Manage users, models and configurations
      - link "Open Dashboard" [ref=e43] [cursor=pointer]:
        - /url: admin.html
    - generic [ref=e44]:
      - heading "Available Models" [level=2] [ref=e45]
      - generic [ref=e46]:
        - button "Configure Paraglider Hand (Flexible Flyer)" [ref=e47] [cursor=pointer]:
          - img [ref=e49]
          - generic [ref=e56]:
            - heading "Paraglider Hand (Flexible Flyer)" [level=3] [ref=e57]:
              - img [ref=e58]
              - text: Paraglider Hand (Flexible Flyer)
            - paragraph [ref=e59]: Parametric wrist-powered prosthetic hand derived from the Phoenix Reborn / Unlimbited Phoenix v3 lineage. Fully OpenSCAD-native — …
          - button "Start New" [ref=e61]
        - button "Configure Kinetic Hand RH60 (Parametric)" [ref=e62] [cursor=pointer]:
          - img [ref=e64]
          - generic [ref=e71]:
            - heading "Kinetic Hand RH60 (Parametric)" [level=3] [ref=e72]:
              - img [ref=e73]
              - text: Kinetic Hand RH60 (Parametric)
            - paragraph [ref=e74]: Kinetic Hand RH60 right-hand assembly rebuilt as a fully parametric SCAD model — no external STL imports required. All five compon…
          - button "Start New" [ref=e76]
        - button "Configure Phoenix Hand v3" [ref=e77] [cursor=pointer]:
          - img [ref=e79]
          - generic [ref=e86]:
            - heading "Phoenix Hand v3" [level=3] [ref=e87]:
              - img [ref=e88]
              - text: Phoenix Hand v3
            - paragraph [ref=e89]: Phoenix v3 full-hand assembled preview using extracted native OpenSCAD geometry for the palm, distal fingers, proximal phalanx ban…
          - button "Start New" [ref=e91]
    - generic [ref=e92]:
      - heading "Saved Configurations" [level=2] [ref=e93]
      - generic [ref=e94]:
        - button "Load perfil1" [ref=e95] [cursor=pointer]:
          - generic [ref=e96]:
            - img [ref=e97]
            - text: perfil1
          - generic [ref=e99]:
            - generic [ref=e100]: anthropometric_hand
            - generic [ref=e101]: Mar 26, 2026
          - paragraph [ref=e102]: Nota
          - button "Load Profile" [ref=e104]
        - button "Load Testemodel" [ref=e105] [cursor=pointer]:
          - generic [ref=e106]:
            - img [ref=e107]
            - text: Testemodel
          - generic [ref=e109]:
            - generic [ref=e110]: fingerator
            - generic [ref=e111]: Mar 2, 2026
          - button "Load Profile" [ref=e113]
    - contentinfo [ref=e114]:
      - generic [ref=e115]:
        - generic [ref=e116]:
          - generic [ref=e117]:
            - heading "Hand Fab" [level=3] [ref=e118]
            - paragraph [ref=e119]: Custom hand prosthetic configuration system
          - generic [ref=e120]:
            - heading "Support" [level=3] [ref=e121]
            - list [ref=e122]:
              - listitem [ref=e123]:
                - link "Help Center" [ref=e124] [cursor=pointer]:
                  - /url: "#"
              - listitem [ref=e125]:
                - link "Documentation" [ref=e126] [cursor=pointer]:
                  - /url: "#"
              - listitem [ref=e127]:
                - link "Tutorials" [ref=e128] [cursor=pointer]:
                  - /url: "#"
          - generic [ref=e129]:
            - heading "Contact" [level=3] [ref=e130]
            - list [ref=e131]:
              - listitem [ref=e132]:
                - link "Email Support" [ref=e133] [cursor=pointer]:
                  - /url: "#"
              - listitem [ref=e134]:
                - link "Live Chat" [ref=e135] [cursor=pointer]:
                  - /url: "#"
              - listitem [ref=e136]:
                - link "Schedule Call" [ref=e137] [cursor=pointer]:
                  - /url: "#"
          - generic [ref=e138]:
            - heading "Legal" [level=3] [ref=e139]
            - list [ref=e140]:
              - listitem [ref=e141]:
                - link "Privacy Policy" [ref=e142] [cursor=pointer]:
                  - /url: "#"
              - listitem [ref=e143]:
                - link "Terms of Service" [ref=e144] [cursor=pointer]:
                  - /url: "#"
              - listitem [ref=e145]:
                - link "Accessibility" [ref=e146] [cursor=pointer]:
                  - /url: "#"
        - generic [ref=e147]: © 2026 Hand Fab. All rights reserved.
```

# Test source

```ts
  1  | // @ts-check
  2  | const { test, expect } = require('@playwright/test');
  3  | const path = require('path');
  4  | 
  5  | const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
  6  | const SCREENSHOT_DIR = path.join(__dirname, '..', 'test-renders');
  7  | 
  8  | async function login(page) {
  9  |     await page.goto('/');
  10 |     await page.waitForSelector('#login-form', { timeout: 10000 });
  11 |     await page.fill('#login-username', ADMIN.username);
  12 |     await page.fill('#login-password', ADMIN.password);
  13 |     // Submit the form inside the modal (not the navbar #login-btn)
  14 |     await page.click('#login-form button[type="submit"]');
> 15 |     await page.waitForSelector('#model-select', { timeout: 15000 });
     |                ^ TimeoutError: page.waitForSelector: Timeout 15000ms exceeded.
  16 | }
  17 | 
  18 | async function renderModel(page, modelValue, screenshotName) {
  19 |     await page.selectOption('#model-select', { value: modelValue });
  20 |     await page.waitForTimeout(1000);
  21 | 
  22 |     // Click render button
  23 |     await page.click('#render-btn');
  24 |     console.log(`[renderModel] Clicked render for ${modelValue}`);
  25 | 
  26 |     // Wait for status to change from "Ready" (confirms render started)
  27 |     await page.waitForFunction(() => {
  28 |         const s = document.getElementById('status');
  29 |         return s && s.textContent !== 'Ready' && s.textContent !== '';
  30 |     }, { timeout: 15000 }).catch(() => {
  31 |         console.log('[renderModel] Status never changed from Ready — render may not have started');
  32 |     });
  33 | 
  34 |     const statusText = await page.locator('div#status').textContent();
  35 |     console.log(`[renderModel] Status after render click: "${statusText}"`);
  36 | 
  37 |     // Wait for model-viewer src property to be set (WASM render → GLB blob URL)
  38 |     // or for an error status
  39 |     await page.waitForFunction(() => {
  40 |         const mv = document.getElementById('viewer');
  41 |         const status = document.getElementById('status');
  42 |         const done = mv && mv.src && mv.src.startsWith('blob:');
  43 |         const failed = status && status.classList.contains('error');
  44 |         return done || failed;
  45 |     }, { timeout: 300000 });
  46 | 
  47 |     const finalStatus = await page.locator('div#status').textContent();
  48 |     console.log(`[renderModel] Final status: "${finalStatus}"`);
  49 | 
  50 |     // Let the 3D viewer paint the frame
  51 |     await page.waitForTimeout(4000);
  52 | 
  53 |     const fs = require('fs');
  54 |     fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  55 |     await page.screenshot({
  56 |         path: `${SCREENSHOT_DIR}/${screenshotName}.png`,
  57 |         fullPage: false,
  58 |     });
  59 |     console.log(`Screenshot saved: ${screenshotName}.png`);
  60 | }
  61 | 
  62 | test('render comparison: STEP mesh vs parametric SCAD', async ({ page }) => {
  63 |     // Capture all browser console output for diagnosis
  64 |     page.on('console', msg => {
  65 |         const type = msg.type();
  66 |         if (type === 'error' || type === 'warn' || msg.text().includes('OpenSCAD') || msg.text().includes('WASM') || msg.text().includes('worker') || msg.text().includes('SharedArray') || msg.text().includes('GLB') || msg.text().includes('OFF')) {
  67 |             console.log(`[BROWSER ${type.toUpperCase()}] ${msg.text()}`);
  68 |         }
  69 |     });
  70 |     page.on('pageerror', err => console.error(`[PAGE ERROR] ${err.message}`));
  71 | 
  72 |     const fs = require('fs');
  73 |     fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  74 | 
  75 |     await login(page);
  76 | 
  77 |     await renderModel(page, 'passive_hand_step', 'step_reference');
  78 |     await renderModel(page, 'passive_hand',      'scad_parametric');
  79 | 
  80 |     // Both screenshots should exist and be non-trivial size
  81 |     const step = fs.statSync(`${SCREENSHOT_DIR}/step_reference.png`);
  82 |     const scad = fs.statSync(`${SCREENSHOT_DIR}/scad_parametric.png`);
  83 |     expect(step.size).toBeGreaterThan(10000);
  84 |     expect(scad.size).toBeGreaterThan(10000);
  85 | });
  86 | 
```