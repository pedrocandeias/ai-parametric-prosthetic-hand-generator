// @ts-check
const { test, expect } = require('@playwright/test');

const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };

async function login(page) {
    await page.goto('/');
    await page.waitForSelector('#login-form', { timeout: 10000 });
    await page.fill('#login-username', ADMIN.username);
    await page.fill('#login-password', ADMIN.password);
    await page.click('#login-form button[type="submit"]');
    // Wait for model grid (card-based selector)
    await page.waitForSelector('[data-model-id]', { timeout: 15000 });
}

test('Flexy Beast renders with COFF color groups visible', async ({ page }) => {
    const consoleLogs = [];
    const consoleErrors = [];

    page.on('console', msg => {
        const text = msg.text();
        consoleLogs.push({ type: msg.type(), text });
        if (msg.type() === 'error') consoleErrors.push(text);
    });

    await login(page);

    // Select Flexy Beast by clicking its card
    await page.click('[data-model-id="flexy_beast"]');

    // Wait for the parameter editor to load (params attached to DOM)
    await page.waitForSelector('[id*="param-"]', { state: 'attached', timeout: 15000 });
    await page.waitForTimeout(500);

    // Confirm the model title shows Flexy Beast (not another model)
    const titleText = await page.locator('#model-name, .model-title, h2, h3').first().textContent({ timeout: 5000 }).catch(() => '');
    console.log('Model title:', titleText);

    // Click Render / Preview button
    const renderBtn = page.locator('button:has-text("Render"), button:has-text("Preview"), button:has-text("render"), #render-btn, #preview-btn').first();
    await renderBtn.waitFor({ timeout: 10000 });
    await renderBtn.click();

    // Wait for the model-viewer src to be set (GLB loaded) — src is a DOM property, not attribute
    await page.waitForFunction(() => {
        const viewer = document.getElementById('viewer');
        return viewer && viewer.src && viewer.src !== '' && !viewer.src.startsWith('about:');
    }, { timeout: 120000 });

    // Extra wait for model-viewer WebGL render
    await page.waitForTimeout(4000);

    // Screenshot the result
    await page.screenshot({ path: 'tests/screenshots/coff_render.png', fullPage: false });

    // Print all captured logs
    console.log('\n=== Console logs ===');
    for (const l of consoleLogs) {
        console.log(`[${l.type}] ${l.text}`);
    }

    // Check for COFF color log
    const coffLog = consoleLogs.find(l => l.text.includes('COFF color groups'));
    const glbError = consoleLogs.find(l => l.text.includes('Failed to convert to GLB') || l.text.includes('not found in 3MF'));
    const offData = consoleLogs.find(l => l.text.includes('output.off') || l.text.includes('OFF'));

    console.log('\n=== Key findings ===');
    console.log('COFF color log:', coffLog?.text ?? 'NOT FOUND');
    console.log('GLB error:', glbError?.text ?? 'none');
    console.log('Console errors:', consoleErrors);

    expect(glbError, `GLB conversion error: ${glbError?.text}`).toBeUndefined();
    expect(coffLog, 'Expected COFF color groups log to appear').toBeDefined();
});
