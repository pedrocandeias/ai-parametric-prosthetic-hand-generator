# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: smoke.spec.js >> Model selector >> lists PeKwawu v2 and Parahand models
- Location: tests/smoke.spec.js:32:3

# Error details

```
TimeoutError: page.waitForSelector: Timeout 10000ms exceeded.
Call log:
  - waiting for locator('#model-select') to be visible
    25 × locator resolved to hidden <select id="model-select">…</select>

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
  18 |     await expect(page.locator('#model-select')).toBeVisible({ timeout: 10000 });
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
> 29 |     await page.waitForSelector('#model-select', { timeout: 10000 });
     |                ^ TimeoutError: page.waitForSelector: Timeout 10000ms exceeded.
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