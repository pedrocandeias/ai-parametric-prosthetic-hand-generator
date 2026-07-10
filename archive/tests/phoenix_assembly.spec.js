// @ts-check
// E2E test for the Phoenix "Assembly (seated hand)" default view (v14.36.0).
// Verifies: the model opens on part="Assembly", the seated hand renders through
// the WASM pipeline WITH its reconstructed pin/tensioner/washer dependencies
// (no include-resolution errors), it stays parametric (palm_breadth + right hand),
// and the individual print parts (Palm) still render. Saves screenshots.
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const SHOT_DIR = process.env.SHOT_DIR || path.join(__dirname, '__shots__');
fs.mkdirSync(SHOT_DIR, { recursive: true });

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

async function setControl(page, id, value, isSelect = false) {
    await page.locator(`#${id}`).evaluate((el, v) => {
        el.value = v;
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
    }, value);
}

async function renderAndWait(page) {
    await page.click('#render-btn');
    // Render started: the #loading overlay gains .active. (Best-effort — a very
    // fast render may add+remove it before we observe.)
    await page.waitForFunction(
        () => document.getElementById('loading')?.classList.contains('active'),
        { timeout: 8000 }).catch(() => {});
    // Render finished: overlay loses .active and the viewer has a real image.
    await page.waitForFunction(() => {
        const l = document.getElementById('loading');
        const v = document.getElementById('viewer');
        const done = l && !l.classList.contains('active');
        const painted = v && v.src && v.src !== '' && !v.src.startsWith('about:');
        return done && painted;
    }, { timeout: 240000 });
    await page.waitForTimeout(500); // let the viewer settle/paint
}

async function setCheckbox(page, id, checked) {
    await page.locator(`#${id}`).evaluate((el, v) => {
        if (el.checked !== v) { el.checked = v; el.dispatchEvent(new Event('change', { bubbles: true })); }
    }, checked);
}

test('Phoenix: per-part toggles (no part selector), assembled + print layout, parametric', async ({ page }) => {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', e => errors.push('pageerror: ' + e.message));

    await login(page);
    await page.click('[data-model-id="unlimbed_phoenix_hand"]');
    await page.waitForSelector('#param-show_palm', { state: 'attached', timeout: 15000 });

    // 1) The old single-part selector is gone; every part has its own toggle.
    expect(await page.locator('#param-part').count(), 'part selector removed').toBe(0);
    for (const id of ['param-show_palm', 'param-show_fingers', 'param-show_thumb',
                      'param-show_pins', 'param-show_gauntlet', 'param-show_tensioner',
                      'param-print_layout']) {
        expect(await page.locator(`#${id}`).getAttribute('type'), id).toBe('checkbox');
    }

    // 2) Render the assembled seated hand (all parts on, Left, 82 mm).
    await renderAndWait(page);
    await page.locator('#viewer').screenshot({ path: path.join(SHOT_DIR, '01-assembly-left-82.png') });
    const depErrors = errors.filter(t =>
        /can't open|cannot open|WARNING:.*(phoenix_|assembly)|unknown module|not found/i.test(t));
    expect(depErrors, 'no dependency/include resolution errors').toEqual([]);

    // 3) Per-part visibility: hide gauntlet + tensioner → editor reflects it, re-render.
    await setCheckbox(page, 'param-show_gauntlet', false);
    await setCheckbox(page, 'param-show_tensioner', false);
    await expect(page.locator('#editor')).toHaveValue(/show_gauntlet\s*=\s*false/, { timeout: 5000 });
    await renderAndWait(page);
    await page.locator('#viewer').screenshot({ path: path.join(SHOT_DIR, '02-hand-only.png') });
    await setCheckbox(page, 'param-show_gauntlet', true);
    await setCheckbox(page, 'param-show_tensioner', true);

    // 4) Parametric: bigger palm + right hand → re-render.
    await setControl(page, 'param-palm_breadth_mm', '120');
    await setControl(page, 'param-LeftRight', 'Right', true);
    await expect(page.locator('#editor')).toHaveValue(/LeftRight\s*=\s*"Right"/, { timeout: 5000 });
    await renderAndWait(page);
    await page.locator('#viewer').screenshot({ path: path.join(SHOT_DIR, '03-assembly-right-120.png') });

    // 5) Print-bed layout for export (flat, all parts), size/side restored.
    await setControl(page, 'param-LeftRight', 'Left', true);
    await setControl(page, 'param-palm_breadth_mm', '82');
    await setCheckbox(page, 'param-print_layout', true);
    await expect(page.locator('#editor')).toHaveValue(/print_layout\s*=\s*true/, { timeout: 5000 });
    await renderAndWait(page);
    await page.locator('#viewer').screenshot({ path: path.join(SHOT_DIR, '04-print-layout.png') });

    await page.screenshot({ path: path.join(SHOT_DIR, '05-fullpage.png'), fullPage: true });
    console.log('Screenshots saved to', SHOT_DIR);
    console.log('Console errors seen:', errors.length ? errors : '(none)');
});
