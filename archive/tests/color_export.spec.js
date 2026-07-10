// @ts-check
// End-to-end tests for the colour customiser: dedicated Colors tab, per-part
// swatches, coloured live preview, and coloured 3MF export. Exercises the real
// OpenSCAD WASM pipeline. (v14.22.0 + v14.23.0)
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ADMIN = {
    username: process.env.TEST_ADMIN_USER || 'admin',
    password: process.env.TEST_ADMIN_PASSWORD || 'admin1234',
};

async function login(page) {
    await page.goto('/');
    await page.waitForSelector('#login-form', { timeout: 10000 });
    await page.fill('#login-username', ADMIN.username);
    await page.fill('#login-password', ADMIN.password);
    await page.click('#login-form button[type="submit"]');
    await page.waitForSelector('[data-model-id]', { timeout: 15000 });
}

// Set a native <input type="color"> value and fire the events the app listens for.
async function setColor(page, id, hex) {
    await page.locator(`#${id}`).evaluate((el, v) => {
        el.value = v;
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
    }, hex);
}

test('Colors tab sits between Parameters and Saved, holds per-part swatches', async ({ page }) => {
    await login(page);
    await page.click('[data-model-id="paraglider_hand"]');
    await page.waitForSelector('#param-color_palm', { state: 'attached', timeout: 15000 });

    // Tab order: AI → Parameters → Colors → Saved.
    const order = await page.locator('.hf-tab-list:has([data-tab="ai"]) .hf-tab-btn').evaluateAll(
        els => els.map(e => e.getAttribute('data-tab')));
    expect(order).toEqual(['ai', 'params', 'colors', 'saved']);

    // The colour swatches live in the Colors pane, not the Parameters pane.
    await page.click('.hf-tab-btn[data-tab="colors"]');
    await expect(page.locator('#tab-colors')).toBeVisible();
    await expect(page.locator('#param-color_palm')).toBeVisible();
    expect(await page.locator('#param-color_palm').getAttribute('type')).toBe('color');
    // Paraglider: 7 per-part colours.
    const swatches = await page.locator('#color-parameters input[type="color"]').count();
    expect(swatches).toBe(7);
});

test('Flexy Beast: per-segment (distal/proximal) colour → SCAD → coloured 3MF', async ({ page }) => {
    const consoleLogs = [];
    page.on('console', msg => consoleLogs.push(msg.text()));

    await login(page);
    await page.click('[data-model-id="flexy_beast"]');
    await page.waitForSelector('#param-color_index_tip', { state: 'attached', timeout: 15000 });

    await page.click('.hf-tab-btn[data-tab="colors"]');
    // Distal + proximal swatches for a finger exist and are colour inputs.
    for (const id of ['param-color_index_base', 'param-color_index_tip', 'param-color_palm', 'param-color_gauntlet']) {
        expect(await page.locator(`#${id}`).getAttribute('type'), id).toBe('color');
    }
    // pad_color + 12 per-part colours = 13 swatches.
    expect(await page.locator('#color-parameters input[type="color"]').count()).toBe(13);

    // Set the index DISTAL segment to a distinctive colour.
    await setColor(page, 'param-color_index_tip', '#0a0b0c');
    await expect(page.locator('#editor')).toHaveValue(/color_index_tip\s*=\s*"#0a0b0c"/i, { timeout: 5000 });

    // Render → coloured preview loads with many COFF colour groups.
    await page.click('#render-btn');
    await page.waitForFunction(() => {
        const v = document.getElementById('viewer');
        return v && v.src && v.src !== '' && !v.src.startsWith('about:');
    }, { timeout: 180000 });
    const coff = consoleLogs.find(t => /COFF color groups: \d+/.test(t));
    expect(coff).toBeDefined();
    console.log('Flexy preview:', coff);

    // Export the index DISTAL part as 3MF; it must carry the chosen colour.
    await page.click('#export-btn');
    await page.waitForSelector('#export-modal.active', { timeout: 5000 });
    await page.locator('input[name="export-format-opt"][value="3mf"]').check();
    await page.locator('.export-item').evaluateAll(els => {
        els.forEach(el => { el.checked = el.value === 'index_tip'; });
    });
    const [download] = await Promise.all([
        page.waitForEvent('download', { timeout: 180000 }),
        page.click('#export-confirm-btn'),
    ]);
    const outPath = path.join(os.tmpdir(), `hf_${download.suggestedFilename()}`);
    await download.saveAs(outPath);

    expect(download.suggestedFilename()).toMatch(/index_tip\.3mf$/);
    const text = fs.readFileSync(outPath).toString('latin1');
    expect(text).toContain('unit="millimeter"');
    expect(text).toContain('<basematerials');
    expect(text, 'distal colour baked into the 3MF').toMatch(/displaycolor="#0A0B0C/i);
    console.log('Flexy 3MF:', download.suggestedFilename(), '— #0A0B0C present:', /0A0B0C/i.test(text));
    fs.unlinkSync(outPath);
});
