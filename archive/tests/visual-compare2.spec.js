// @ts-check
const { test } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
const OUT = '/tmp/visual-compare';
const FIGMA_URL = 'https://www.figma.com/make/FLDijElRhatYiTLQK7Mdcr/Hand-Fab-prosthetic-configurator';

test.use({ viewport: { width: 1440, height: 900 } });

async function loginLocal(page) {
  await page.goto('http://localhost:3000');
  await page.waitForSelector('#login-form', { timeout: 15000 });
  await page.fill('#login-username', ADMIN.username);
  await page.fill('#login-password', ADMIN.password);
  await page.click('#login-form button[type="submit"]');
  await page.waitForSelector('.sel-model-card', { timeout: 15000 });
  await page.waitForTimeout(800);
}

test('local: customization clean (AI tab)', async ({ page }) => {
  await loginLocal(page);
  await page.locator('.sel-model-card').first().click();
  await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  // Wait for loading overlay to disappear
  await page.waitForSelector('.loading-overlay, #render-loading, .processing-overlay', { state: 'hidden', timeout: 20000 }).catch(() => {});
  // Also just wait a bit
  await page.waitForTimeout(3000);
  // Dismiss any visible overlay by pressing Escape
  await page.keyboard.press('Escape');
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(OUT, 'local-04-customization-ai.png'), fullPage: false });
});

test('local: customization params tab clean', async ({ page }) => {
  await loginLocal(page);
  await page.locator('.sel-model-card').first().click();
  await page.waitForSelector('#screen-customization.active', { timeout: 10000 });
  await page.waitForTimeout(3000);
  await page.keyboard.press('Escape');
  await page.click('.hf-tab-btn[data-tab="params"]');
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(OUT, 'local-05-customization-params-clean.png'), fullPage: false });
});

test('figma: try to reach running app', async ({ page }) => {
  // Navigate directly to the Make app's preview URL
  await page.goto(FIGMA_URL, { timeout: 30000, waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(5000);

  // Try to find the app iframe
  const frames = page.frames();
  console.log('Frames found:', frames.map(f => f.url()).join('\n'));

  // Take full page shot
  await page.screenshot({ path: path.join(OUT, 'figma-03-full.png'), fullPage: false });

  // Try to find the preview iframe and scroll to it
  const iframe = page.frameLocator('iframe').first();
  try {
    await page.screenshot({ path: path.join(OUT, 'figma-04-app-area.png'), fullPage: false,
      clip: { x: 370, y: 50, width: 1000, height: 800 } });
  } catch (e) {
    console.log('iframe clip failed:', e.message);
  }
});

test('local: selection page full scroll', async ({ page }) => {
  await loginLocal(page);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(OUT, 'local-06-selection-full.png'), fullPage: true });
});
