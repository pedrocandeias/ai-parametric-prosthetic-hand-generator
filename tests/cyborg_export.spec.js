// @ts-check
// End-to-end test for the Cyborg Beast integration (v14.32.0): per-part colour
// customiser → coloured live preview → coloured 3MF export. Exercises the real
// OpenSCAD WASM pipeline against the newly-integrated model.
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ADMIN = {
    username: process.env.TEST_ADMIN_USER || 'handadmin',
    password: process.env.TEST_ADMIN_PASSWORD || 'handfabin',
};

async function login(page) {
    await page.goto('/');
    await page.waitForSelector('#login-form', { timeout: 10000 });
    await page.fill('#login-username', ADMIN.username);
    await page.fill('#login-password', ADMIN.password);
    await page.click('#login-form button[type="submit"]');
    await page.waitForSelector('[data-model-id]', { timeout: 15000 });
}

async function setColor(page, id, hex) {
    await page.locator(`#${id}`).evaluate((el, v) => {
        el.value = v;
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
    }, hex);
}

test('Cyborg Beast: per-segment colour → SCAD → coloured 3MF export', async ({ page }) => {
    const consoleLogs = [];
    page.on('console', msg => consoleLogs.push(msg.text()));

    await login(page);
    await page.click('[data-model-id="cyborg_beast"]');
    await page.waitForSelector('#param-color_middle_tip', { state: 'attached', timeout: 15000 });

    await page.click('.hf-tab-btn[data-tab="colors"]');
    // Per-part swatches exist and are colour inputs.
    for (const id of ['param-color_palm', 'param-color_middle_base', 'param-color_middle_tip', 'param-color_thumb_tip']) {
        expect(await page.locator(`#${id}`).getAttribute('type'), id).toBe('color');
    }
    // Cyborg Beast: palm + 5 digits × (base + tip) = 11 per-part colours (no pad/gauntlet).
    expect(await page.locator('#color-parameters input[type="color"]').count()).toBe(11);

    // Set the middle DISTAL segment to a distinctive colour.
    await setColor(page, 'param-color_middle_tip', '#0a0b0c');
    await expect(page.locator('#editor')).toHaveValue(/color_middle_tip\s*=\s*"#0a0b0c"/i, { timeout: 5000 });

    // Render → coloured preview loads with COFF colour groups.
    await page.click('#render-btn');
    await page.waitForFunction(() => {
        const v = document.getElementById('viewer');
        return v && v.src && v.src !== '' && !v.src.startsWith('about:');
    }, { timeout: 180000 });
    const coff = consoleLogs.find(t => /COFF color groups: \d+/.test(t));
    expect(coff).toBeDefined();
    console.log('Cyborg preview:', coff);

    // Export the middle DISTAL part as 3MF; it must carry the chosen colour.
    await page.click('#export-btn');
    await page.waitForSelector('#export-modal.active', { timeout: 5000 });
    await page.locator('input[name="export-format-opt"][value="3mf"]').check();
    await page.locator('.export-item').evaluateAll(els => {
        els.forEach(el => { el.checked = el.value === 'middle_tip'; });
    });
    const [download] = await Promise.all([
        page.waitForEvent('download', { timeout: 180000 }),
        page.click('#export-confirm-btn'),
    ]);
    const outPath = path.join(os.tmpdir(), `hf_${download.suggestedFilename()}`);
    await download.saveAs(outPath);

    expect(download.suggestedFilename()).toMatch(/middle_tip\.3mf$/);
    const text = fs.readFileSync(outPath).toString('latin1');
    expect(text).toContain('unit="millimeter"');
    expect(text).toContain('<basematerials');
    expect(text, 'distal colour baked into the 3MF').toMatch(/displaycolor="#0A0B0C/i);
    console.log('Cyborg 3MF:', download.suggestedFilename(), '— #0A0B0C present:', /0A0B0C/i.test(text));
    fs.unlinkSync(outPath);
});

test('Cyborg Beast: whole-hand combined 3MF carries multiple part colours', async ({ page }) => {
    await login(page);
    await page.click('[data-model-id="cyborg_beast"]');
    await page.waitForSelector('#param-color_palm', { state: 'attached', timeout: 15000 });

    await page.click('#render-btn');
    await page.waitForFunction(() => {
        const v = document.getElementById('viewer');
        return v && v.src && v.src !== '' && !v.src.startsWith('about:');
    }, { timeout: 180000 });

    // Export the whole assembled hand (all parts) as one 3MF.
    await page.click('#export-btn');
    await page.waitForSelector('#export-modal.active', { timeout: 5000 });
    await page.locator('input[name="export-format-opt"][value="3mf"]').check();
    await page.locator('.export-item').evaluateAll(els => { els.forEach(el => { el.checked = true; }); });
    const [download] = await Promise.all([
        page.waitForEvent('download', { timeout: 240000 }),
        page.click('#export-confirm-btn'),
    ]);
    const outPath = path.join(os.tmpdir(), `hf_${download.suggestedFilename()}`);
    await download.saveAs(outPath);

    const text = fs.readFileSync(outPath).toString('latin1');
    // A multi-material plate: several distinct displaycolor materials from the default palette.
    const colors = new Set((text.match(/displaycolor="#[0-9A-F]{6,8}"/gi) || []).map(s => s.toUpperCase()));
    console.log('Cyborg combined 3MF colours:', download.suggestedFilename(), [...colors]);
    expect(colors.size, 'combined plate should bake in multiple part colours').toBeGreaterThan(3);
    fs.unlinkSync(outPath);
});
