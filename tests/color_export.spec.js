// @ts-check
// End-to-end test for the colour customiser + coloured 3MF export (v14.22.0).
// Exercises the real OpenSCAD WASM pipeline: swatch → SCAD → coloured preview → 3MF.
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ADMIN = { username: 'admin', password: process.env.TEST_ADMIN_PASSWORD || 'admin1234' };

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

test('colour customiser: swatch → SCAD → coloured preview → coloured 3MF export', async ({ page }) => {
    const consoleLogs = [];
    page.on('console', msg => consoleLogs.push(msg.text()));

    await login(page);

    // Paraglider has per-part colour params.
    await page.click('[data-model-id="paraglider_hand"]');
    await page.waitForSelector('#param-color_palm', { state: 'attached', timeout: 15000 });

    // 1) Colour params render as native colour swatches, not text inputs.
    const palmType = await page.locator('#param-color_palm').getAttribute('type');
    expect(palmType, 'color_palm should be a native colour input').toBe('color');
    const indexType = await page.locator('#param-color_index').getAttribute('type');
    expect(indexType).toBe('color');

    // 2) Changing a swatch writes a quoted colour into the SCAD source.
    await setColor(page, 'param-color_palm', '#123456');
    await expect(page.locator('#editor')).toHaveValue(/color_palm\s*=\s*"#123456"/i, { timeout: 5000 });

    // 3) The adjacent hex readout reflects the new value.
    const hexReadout = await page.locator('#param-color_palm').locator('xpath=../span[@class="color-swatch-hex"]').textContent();
    expect(hexReadout?.toUpperCase()).toContain('123456');

    // 4) Render → coloured OFF (COFF) preview loads with multiple colour groups.
    await page.click('#render-btn');
    await page.waitForFunction(() => {
        const v = document.getElementById('viewer');
        return v && v.src && v.src !== '' && !v.src.startsWith('about:');
    }, { timeout: 120000 });
    const coffLog = consoleLogs.find(t => t.includes('COFF color groups'));
    expect(coffLog, 'expected a COFF color groups log from the coloured preview').toBeDefined();
    console.log('Preview:', coffLog);

    // 5) Export the palm part as 3MF and capture the download.
    await page.click('#export-btn');
    await page.waitForSelector('#export-modal.active', { timeout: 5000 });
    // pick 3MF format
    await page.locator('input[name="export-format-opt"][value="3mf"]').check();
    // select ONLY the palm part (fast single render, carries the changed colour)
    await page.locator('.export-item').evaluateAll(els => {
        els.forEach(el => { el.checked = el.value === 'palm'; });
    });

    const [download] = await Promise.all([
        page.waitForEvent('download', { timeout: 180000 }),
        page.click('#export-confirm-btn'),
    ]);
    const outPath = path.join(os.tmpdir(), `hf_test_${download.suggestedFilename()}`);
    await download.saveAs(outPath);

    // 6) The downloaded file is a .3mf carrying the chosen colour as a material.
    expect(download.suggestedFilename()).toMatch(/\.3mf$/);
    const buf = fs.readFileSync(outPath);
    const text = buf.toString('latin1'); // store-ZIP: model XML is plaintext inside

    expect(text, 'OPC content types present').toContain('3dmanufacturing-3dmodel');
    expect(text, '3MF declares millimetre units').toContain('unit="millimeter"');
    expect(text, '3MF has a materials palette').toContain('<basematerials');
    expect(text, 'chosen palm colour baked into a material').toMatch(/displaycolor="#123456/i);
    expect(text, 'triangles carry per-material index').toMatch(/<triangle[^>]*p1=/);

    console.log('3MF file:', download.suggestedFilename(), buf.length, 'bytes — colour #123456 present:', /123456/i.test(text));
    fs.unlinkSync(outPath);
});
