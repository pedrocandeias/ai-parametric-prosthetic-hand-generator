# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: visual-compare.spec.js >> local: selection page — full
- Location: tests/visual-compare.spec.js:50:1

# Error details

```
TimeoutError: page.waitForSelector: Timeout 15000ms exceeded.
Call log:
  - waiting for locator('#screen-selection.active, #selection-models-grid') to be visible
    34 × locator resolved to 2 elements. Proceeding with the first one: <div id="screen-selection" class="app-screen active">…</div>

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
  1   | // @ts-check
  2   | /**
  3   |  * Visual comparison: local app vs Figma Make reference
  4   |  * Saves screenshots to /tmp/visual-compare/
  5   |  * Run: TEST_ADMIN_PASSWORD=admin1234 npx playwright test tests/visual-compare.spec.js --reporter=list
  6   |  */
  7   | const { test, expect } = require('@playwright/test');
  8   | const path = require('path');
  9   | const fs = require('fs');
  10  | 
  11  | const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
  12  | const OUT_DIR = '/tmp/visual-compare';
  13  | const FIGMA_URL = 'https://www.figma.com/make/FLDijElRhatYiTLQK7Mdcr/Hand-Fab-prosthetic-configurator';
  14  | const VIEWPORT = { width: 1440, height: 900 };
  15  | 
  16  | test.use({ viewport: VIEWPORT });
  17  | 
  18  | test.beforeAll(() => {
  19  |   if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
  20  | });
  21  | 
  22  | // ── Local app helpers ─────────────────────────────────────────────────────────
  23  | 
  24  | async function loginLocal(page) {
  25  |   await page.goto('http://localhost:3000');
  26  |   await page.waitForSelector('#login-form', { timeout: 15000 });
  27  |   await page.fill('#login-username', ADMIN.username);
  28  |   await page.fill('#login-password', ADMIN.password);
  29  |   await page.click('#login-form button[type="submit"]');
  30  |   // Wait for selection screen
> 31  |   await page.waitForSelector('#screen-selection.active, #selection-models-grid', { timeout: 15000 });
      |              ^ TimeoutError: page.waitForSelector: Timeout 15000ms exceeded.
  32  | }
  33  | 
  34  | // ── LOCAL SCREENSHOTS ─────────────────────────────────────────────────────────
  35  | 
  36  | test('local: login page', async ({ page }) => {
  37  |   await page.goto('http://localhost:3000');
  38  |   await page.waitForSelector('#login-modal.active, #login-form', { timeout: 10000 });
  39  |   await page.screenshot({ path: path.join(OUT_DIR, 'local-01-login.png'), fullPage: false });
  40  | });
  41  | 
  42  | test('local: selection page', async ({ page }) => {
  43  |   await loginLocal(page);
  44  |   // Wait for model cards to render
  45  |   await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  46  |   await page.waitForTimeout(600); // let animations settle
  47  |   await page.screenshot({ path: path.join(OUT_DIR, 'local-02-selection.png'), fullPage: false });
  48  | });
  49  | 
  50  | test('local: selection page — full', async ({ page }) => {
  51  |   await loginLocal(page);
  52  |   await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  53  |   await page.waitForTimeout(600);
  54  |   await page.screenshot({ path: path.join(OUT_DIR, 'local-02-selection-full.png'), fullPage: true });
  55  | });
  56  | 
  57  | test('local: customization page', async ({ page }) => {
  58  |   await loginLocal(page);
  59  |   await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  60  |   // Click the first model card
  61  |   await page.locator('.sel-model-card').first().click();
  62  |   await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  63  |   await page.waitForTimeout(800);
  64  |   await page.screenshot({ path: path.join(OUT_DIR, 'local-03-customization.png'), fullPage: false });
  65  | });
  66  | 
  67  | test('local: customization — parameters tab', async ({ page }) => {
  68  |   await loginLocal(page);
  69  |   await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  70  |   await page.locator('.sel-model-card').first().click();
  71  |   await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  72  |   // Switch to Parameters tab
  73  |   await page.click('.hf-tab-btn[data-tab="params"]');
  74  |   await page.waitForTimeout(600);
  75  |   await page.screenshot({ path: path.join(OUT_DIR, 'local-03-customization-params.png'), fullPage: false });
  76  | });
  77  | 
  78  | // ── FIGMA MAKE SCREENSHOTS ────────────────────────────────────────────────────
  79  | 
  80  | test('figma: login page', async ({ page }) => {
  81  |   try {
  82  |     await page.goto(FIGMA_URL, { timeout: 30000, waitUntil: 'networkidle' });
  83  |     await page.waitForTimeout(3000);
  84  |     await page.screenshot({ path: path.join(OUT_DIR, 'figma-01-login.png'), fullPage: false });
  85  |   } catch (e) {
  86  |     console.log('Figma login screenshot failed:', e.message);
  87  |     // Not fatal — still pass
  88  |   }
  89  | });
  90  | 
  91  | test('figma: selection page (if accessible)', async ({ page }) => {
  92  |   try {
  93  |     await page.goto(FIGMA_URL, { timeout: 30000, waitUntil: 'networkidle' });
  94  |     await page.waitForTimeout(4000);
  95  |     // Try clicking into the app if there's a demo/preview link
  96  |     const bodyText = await page.locator('body').innerText().catch(() => '');
  97  |     await page.screenshot({ path: path.join(OUT_DIR, 'figma-02-landing.png'), fullPage: false });
  98  |     console.log('Page title:', await page.title());
  99  |     console.log('Body excerpt:', bodyText.slice(0, 200));
  100 |   } catch (e) {
  101 |     console.log('Figma selection screenshot failed:', e.message);
  102 |   }
  103 | });
  104 | 
```