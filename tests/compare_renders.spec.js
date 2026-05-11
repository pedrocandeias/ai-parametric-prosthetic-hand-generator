// @ts-check
const { test, expect } = require('@playwright/test');
const path = require('path');

const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };
const SCREENSHOT_DIR = path.join(__dirname, '..', 'test-renders');

async function login(page) {
    await page.goto('/');
    await page.waitForSelector('#login-form', { timeout: 10000 });
    await page.fill('#login-username', ADMIN.username);
    await page.fill('#login-password', ADMIN.password);
    // Submit the form inside the modal (not the navbar #login-btn)
    await page.click('#login-form button[type="submit"]');
    await page.waitForSelector('#model-select', { timeout: 15000 });
}

async function renderModel(page, modelValue, screenshotName) {
    await page.selectOption('#model-select', { value: modelValue });
    await page.waitForTimeout(1000);

    // Click render button
    await page.click('#render-btn');
    console.log(`[renderModel] Clicked render for ${modelValue}`);

    // Wait for status to change from "Ready" (confirms render started)
    await page.waitForFunction(() => {
        const s = document.getElementById('status');
        return s && s.textContent !== 'Ready' && s.textContent !== '';
    }, { timeout: 15000 }).catch(() => {
        console.log('[renderModel] Status never changed from Ready — render may not have started');
    });

    const statusText = await page.locator('div#status').textContent();
    console.log(`[renderModel] Status after render click: "${statusText}"`);

    // Wait for model-viewer src property to be set (WASM render → GLB blob URL)
    // or for an error status
    await page.waitForFunction(() => {
        const mv = document.getElementById('viewer');
        const status = document.getElementById('status');
        const done = mv && mv.src && mv.src.startsWith('blob:');
        const failed = status && status.classList.contains('error');
        return done || failed;
    }, { timeout: 300000 });

    const finalStatus = await page.locator('div#status').textContent();
    console.log(`[renderModel] Final status: "${finalStatus}"`);

    // Let the 3D viewer paint the frame
    await page.waitForTimeout(4000);

    const fs = require('fs');
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
    await page.screenshot({
        path: `${SCREENSHOT_DIR}/${screenshotName}.png`,
        fullPage: false,
    });
    console.log(`Screenshot saved: ${screenshotName}.png`);
}

test('render comparison: STEP mesh vs parametric SCAD', async ({ page }) => {
    // Capture all browser console output for diagnosis
    page.on('console', msg => {
        const type = msg.type();
        if (type === 'error' || type === 'warn' || msg.text().includes('OpenSCAD') || msg.text().includes('WASM') || msg.text().includes('worker') || msg.text().includes('SharedArray') || msg.text().includes('GLB') || msg.text().includes('OFF')) {
            console.log(`[BROWSER ${type.toUpperCase()}] ${msg.text()}`);
        }
    });
    page.on('pageerror', err => console.error(`[PAGE ERROR] ${err.message}`));

    const fs = require('fs');
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });

    await login(page);

    await renderModel(page, 'passive_hand_step', 'step_reference');
    await renderModel(page, 'passive_hand',      'scad_parametric');

    // Both screenshots should exist and be non-trivial size
    const step = fs.statSync(`${SCREENSHOT_DIR}/step_reference.png`);
    const scad = fs.statSync(`${SCREENSHOT_DIR}/scad_parametric.png`);
    expect(step.size).toBeGreaterThan(10000);
    expect(scad.size).toBeGreaterThan(10000);
});
