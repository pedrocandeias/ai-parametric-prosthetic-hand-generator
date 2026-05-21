# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: smoke.spec.js >> Login >> logs in with admin credentials
- Location: tests/smoke.spec.js:12:3

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator:  locator('#model-select')
Expected: visible
Received: hidden
Timeout:  10000ms

Call log:
  - Expect "toBeVisible" with timeout 10000ms
  - waiting for locator('#model-select')
    14 × locator resolved to <select id="model-select">…</select>
       - unexpected value "hidden"

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
  3  | 
  4  | const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
  5  | 
  6  | test.describe('Login', () => {
  7  |   test('shows login modal on load', async ({ page }) => {
  8  |     await page.goto('/');
  9  |     await expect(page.locator('#login-modal, #auth-modal, .login-modal, [id*="login"]').first()).toBeVisible({ timeout: 10000 });
  10 |   });
  11 | 
  12 |   test('logs in with admin credentials', async ({ page }) => {
  13 |     await page.goto('/');
  14 |     await page.waitForSelector('#login-form', { timeout: 10000 });
  15 |     await page.fill('#login-username', ADMIN.username);
  16 |     await page.fill('#login-password', ADMIN.password);
  17 |     await page.click('#login-form button[type="submit"]');
> 18 |     await expect(page.locator('#model-select')).toBeVisible({ timeout: 10000 });
     |                                                 ^ Error: expect(locator).toBeVisible() failed
  19 |   });
  20 | });
  21 | 
  22 | test.describe('Model selector', () => {
  23 |   test.beforeEach(async ({ page }) => {
  24 |     await page.goto('/');
  25 |     await page.waitForSelector('#login-form', { timeout: 10000 });
  26 |     await page.fill('#login-username', ADMIN.username);
  27 |     await page.fill('#login-password', ADMIN.password);
  28 |     await page.click('#login-form button[type="submit"]');
  29 |     await page.waitForSelector('#model-select', { timeout: 10000 });
  30 |   });
  31 | 
  32 |   test('lists PeKwawu v2 and Parahand models', async ({ page }) => {
  33 |     const options = await page.locator('#model-select option').allTextContents();
  34 |     expect(options.some(o => o.includes('PeKwawu'))).toBeTruthy();
  35 |     expect(options.some(o => o.includes('Parahand'))).toBeTruthy();
  36 |   });
  37 | 
  38 |   test('loads Parahand parameters when selected', async ({ page }) => {
  39 |     await page.selectOption('#model-select', { label: /Parahand/ });
  40 |     await expect(page.locator('[id*="palm_breadth_mm"], #param-palm_breadth_mm')).toBeVisible({ timeout: 5000 });
  41 |   });
  42 | 
  43 |   test('loads PeKwawu v2 parameters when selected', async ({ page }) => {
  44 |     await page.selectOption('#model-select', { value: 'pekwawu' });
  45 |     await expect(page.locator('#param-palm_breadth_mm, [id*="palm_breadth_mm"]')).toBeVisible({ timeout: 5000 });
  46 |   });
  47 | });
  48 | 
```