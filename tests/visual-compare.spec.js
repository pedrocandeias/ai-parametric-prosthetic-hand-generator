// @ts-check
/**
 * Visual comparison: local app vs Figma Make reference
 * Saves screenshots to /tmp/visual-compare/
 * Run: TEST_ADMIN_PASSWORD=admin1234 npx playwright test tests/visual-compare.spec.js --reporter=list
 */
const { test, expect } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
const OUT_DIR = '/tmp/visual-compare';
const FIGMA_URL = 'https://www.figma.com/make/FLDijElRhatYiTLQK7Mdcr/Hand-Fab-prosthetic-configurator';
const VIEWPORT = { width: 1440, height: 900 };

test.use({ viewport: VIEWPORT });

test.beforeAll(() => {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
});

// ── Local app helpers ─────────────────────────────────────────────────────────

async function loginLocal(page) {
  await page.goto('http://localhost:3000');
  await page.waitForSelector('#login-form', { timeout: 15000 });
  await page.fill('#login-username', ADMIN.username);
  await page.fill('#login-password', ADMIN.password);
  await page.click('#login-form button[type="submit"]');
  // Wait for selection screen
  await page.waitForSelector('#screen-selection.active, #selection-models-grid', { timeout: 15000 });
}

// ── LOCAL SCREENSHOTS ─────────────────────────────────────────────────────────

test('local: login page', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.waitForSelector('#login-modal.active, #login-form', { timeout: 10000 });
  await page.screenshot({ path: path.join(OUT_DIR, 'local-01-login.png'), fullPage: false });
});

test('local: selection page', async ({ page }) => {
  await loginLocal(page);
  // Wait for model cards to render
  await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  await page.waitForTimeout(600); // let animations settle
  await page.screenshot({ path: path.join(OUT_DIR, 'local-02-selection.png'), fullPage: false });
});

test('local: selection page — full', async ({ page }) => {
  await loginLocal(page);
  await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(OUT_DIR, 'local-02-selection-full.png'), fullPage: true });
});

test('local: customization page', async ({ page }) => {
  await loginLocal(page);
  await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  // Click the first model card
  await page.locator('.sel-model-card').first().click();
  await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(OUT_DIR, 'local-03-customization.png'), fullPage: false });
});

test('local: customization — parameters tab', async ({ page }) => {
  await loginLocal(page);
  await page.waitForSelector('.sel-model-card', { timeout: 10000 });
  await page.locator('.sel-model-card').first().click();
  await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  // Switch to Parameters tab
  await page.click('.hf-tab-btn[data-tab="params"]');
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(OUT_DIR, 'local-03-customization-params.png'), fullPage: false });
});

// ── FIGMA MAKE SCREENSHOTS ────────────────────────────────────────────────────

test('figma: login page', async ({ page }) => {
  try {
    await page.goto(FIGMA_URL, { timeout: 30000, waitUntil: 'networkidle' });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(OUT_DIR, 'figma-01-login.png'), fullPage: false });
  } catch (e) {
    console.log('Figma login screenshot failed:', e.message);
    // Not fatal — still pass
  }
});

test('figma: selection page (if accessible)', async ({ page }) => {
  try {
    await page.goto(FIGMA_URL, { timeout: 30000, waitUntil: 'networkidle' });
    await page.waitForTimeout(4000);
    // Try clicking into the app if there's a demo/preview link
    const bodyText = await page.locator('body').innerText().catch(() => '');
    await page.screenshot({ path: path.join(OUT_DIR, 'figma-02-landing.png'), fullPage: false });
    console.log('Page title:', await page.title());
    console.log('Body excerpt:', bodyText.slice(0, 200));
  } catch (e) {
    console.log('Figma selection screenshot failed:', e.message);
  }
});
