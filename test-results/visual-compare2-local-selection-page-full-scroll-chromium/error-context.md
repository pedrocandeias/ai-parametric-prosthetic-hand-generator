# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: visual-compare2.spec.js >> local: selection page full scroll
- Location: tests/visual-compare2.spec.js:69:1

# Error details

```
TimeoutError: page.waitForSelector: Timeout 15000ms exceeded.
Call log:
  - waiting for locator('.sel-model-card') to be visible

```

# Page snapshot

```yaml
- generic [ref=e2]:
  - generic [ref=e4]:
    - img [ref=e5]
    - generic [ref=e13]: Hand Fab
  - generic [ref=e16]:
    - generic [ref=e17]:
      - img [ref=e18]
      - generic [ref=e29]: Hand Fab
    - paragraph [ref=e30]: Custom Hand Prosthetic Configuration System
    - generic [ref=e31]: Too many login attempts, try again in 15 minutes
    - generic [ref=e32]:
      - textbox "Username" [ref=e34]: admin
      - textbox "Password" [ref=e36]: admin1234
      - button "Login" [ref=e37] [cursor=pointer]
    - generic [ref=e38]: Don't have an account? Register · Reset Password
  - contentinfo [ref=e39]:
    - generic [ref=e40]:
      - generic [ref=e41]:
        - generic [ref=e42]:
          - heading "Hand Fab" [level=3] [ref=e43]
          - paragraph [ref=e44]: Custom hand prosthetic configuration system
        - generic [ref=e45]:
          - heading "Support" [level=3] [ref=e46]
          - list [ref=e47]:
            - listitem [ref=e48]:
              - link "Help Center" [ref=e49] [cursor=pointer]:
                - /url: "#"
            - listitem [ref=e50]:
              - link "Documentation" [ref=e51] [cursor=pointer]:
                - /url: "#"
            - listitem [ref=e52]:
              - link "Tutorials" [ref=e53] [cursor=pointer]:
                - /url: "#"
        - generic [ref=e54]:
          - heading "Contact" [level=3] [ref=e55]
          - list [ref=e56]:
            - listitem [ref=e57]:
              - link "Email Support" [ref=e58] [cursor=pointer]:
                - /url: "#"
            - listitem [ref=e59]:
              - link "Live Chat" [ref=e60] [cursor=pointer]:
                - /url: "#"
            - listitem [ref=e61]:
              - link "Schedule Call" [ref=e62] [cursor=pointer]:
                - /url: "#"
        - generic [ref=e63]:
          - heading "Legal" [level=3] [ref=e64]
          - list [ref=e65]:
            - listitem [ref=e66]:
              - link "Privacy Policy" [ref=e67] [cursor=pointer]:
                - /url: "#"
            - listitem [ref=e68]:
              - link "Terms of Service" [ref=e69] [cursor=pointer]:
                - /url: "#"
            - listitem [ref=e70]:
              - link "Accessibility" [ref=e71] [cursor=pointer]:
                - /url: "#"
      - generic [ref=e72]: © 2026 Hand Fab. All rights reserved.
```

# Test source

```ts
  1  | // @ts-check
  2  | const { test } = require('@playwright/test');
  3  | const path = require('path');
  4  | const fs = require('fs');
  5  | 
  6  | const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
  7  | const OUT = '/tmp/visual-compare';
  8  | const FIGMA_URL = 'https://www.figma.com/make/FLDijElRhatYiTLQK7Mdcr/Hand-Fab-prosthetic-configurator';
  9  | 
  10 | test.use({ viewport: { width: 1440, height: 900 } });
  11 | 
  12 | async function loginLocal(page) {
  13 |   await page.goto('http://localhost:3000');
  14 |   await page.waitForSelector('#login-form', { timeout: 15000 });
  15 |   await page.fill('#login-username', ADMIN.username);
  16 |   await page.fill('#login-password', ADMIN.password);
  17 |   await page.click('#login-form button[type="submit"]');
> 18 |   await page.waitForSelector('.sel-model-card', { timeout: 15000 });
     |              ^ TimeoutError: page.waitForSelector: Timeout 15000ms exceeded.
  19 |   await page.waitForTimeout(800);
  20 | }
  21 | 
  22 | test('local: customization clean (AI tab)', async ({ page }) => {
  23 |   await loginLocal(page);
  24 |   await page.locator('.sel-model-card').first().click();
  25 |   await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  26 |   // Wait for loading overlay to disappear
  27 |   await page.waitForSelector('.loading-overlay, #render-loading, .processing-overlay', { state: 'hidden', timeout: 20000 }).catch(() => {});
  28 |   // Also just wait a bit
  29 |   await page.waitForTimeout(3000);
  30 |   // Dismiss any visible overlay by pressing Escape
  31 |   await page.keyboard.press('Escape');
  32 |   await page.waitForTimeout(500);
  33 |   await page.screenshot({ path: path.join(OUT, 'local-04-customization-ai.png'), fullPage: false });
  34 | });
  35 | 
  36 | test('local: customization params tab clean', async ({ page }) => {
  37 |   await loginLocal(page);
  38 |   await page.locator('.sel-model-card').first().click();
  39 |   await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  40 |   await page.waitForTimeout(3000);
  41 |   await page.keyboard.press('Escape');
  42 |   await page.click('.hf-tab-btn[data-tab="params"]');
  43 |   await page.waitForTimeout(800);
  44 |   await page.screenshot({ path: path.join(OUT, 'local-05-customization-params-clean.png'), fullPage: false });
  45 | });
  46 | 
  47 | test('figma: try to reach running app', async ({ page }) => {
  48 |   // Navigate directly to the Make app's preview URL
  49 |   await page.goto(FIGMA_URL, { timeout: 30000, waitUntil: 'domcontentloaded' });
  50 |   await page.waitForTimeout(5000);
  51 | 
  52 |   // Try to find the app iframe
  53 |   const frames = page.frames();
  54 |   console.log('Frames found:', frames.map(f => f.url()).join('\n'));
  55 | 
  56 |   // Take full page shot
  57 |   await page.screenshot({ path: path.join(OUT, 'figma-03-full.png'), fullPage: false });
  58 | 
  59 |   // Try to find the preview iframe and scroll to it
  60 |   const iframe = page.frameLocator('iframe').first();
  61 |   try {
  62 |     await page.screenshot({ path: path.join(OUT, 'figma-04-app-area.png'), fullPage: false,
  63 |       clip: { x: 370, y: 50, width: 1000, height: 800 } });
  64 |   } catch (e) {
  65 |     console.log('iframe clip failed:', e.message);
  66 |   }
  67 | });
  68 | 
  69 | test('local: selection page full scroll', async ({ page }) => {
  70 |   await loginLocal(page);
  71 |   await page.waitForTimeout(800);
  72 |   await page.screenshot({ path: path.join(OUT, 'local-06-selection-full.png'), fullPage: true });
  73 | });
  74 | 
```