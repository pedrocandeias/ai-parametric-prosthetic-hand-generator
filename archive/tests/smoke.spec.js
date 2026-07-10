// @ts-check
const { test, expect } = require('@playwright/test');

const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };

test.describe('Login', () => {
  test('shows login modal on load', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('#login-modal, #auth-modal, .login-modal, [id*="login"]').first()).toBeVisible({ timeout: 10000 });
  });

  test('logs in with admin credentials', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#login-form', { timeout: 10000 });
    await page.fill('#login-username', ADMIN.username);
    await page.fill('#login-password', ADMIN.password);
    await page.click('#login-form button[type="submit"]');
    await expect(page.locator('#model-select')).toBeVisible({ timeout: 10000 });
  });
});

test.describe('Model selector', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#login-form', { timeout: 10000 });
    await page.fill('#login-username', ADMIN.username);
    await page.fill('#login-password', ADMIN.password);
    await page.click('#login-form button[type="submit"]');
    await page.waitForSelector('#model-select', { timeout: 10000 });
  });

  test('lists PeKwawu v2 and Parahand models', async ({ page }) => {
    const options = await page.locator('#model-select option').allTextContents();
    expect(options.some(o => o.includes('PeKwawu'))).toBeTruthy();
    expect(options.some(o => o.includes('Parahand'))).toBeTruthy();
  });

  test('loads Parahand parameters when selected', async ({ page }) => {
    await page.selectOption('#model-select', { label: /Parahand/ });
    await expect(page.locator('[id*="palm_breadth_mm"], #param-palm_breadth_mm')).toBeVisible({ timeout: 5000 });
  });

  test('loads PeKwawu v2 parameters when selected', async ({ page }) => {
    await page.selectOption('#model-select', { value: 'pekwawu' });
    await expect(page.locator('#param-palm_breadth_mm, [id*="palm_breadth_mm"]')).toBeVisible({ timeout: 5000 });
  });
});
