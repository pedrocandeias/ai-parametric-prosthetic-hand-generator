'use strict';

// Thin Playwright page-object helpers for the HandFab SPA. Selectors verified
// against index.html / app.js / screens.js / auth.js (2026-07). The app is a
// History-API SPA; screens are reached by clicking cards, never by URL.

const { THESIS_ADMIN } = require('./env');

const RENDER_TIMEOUT = 180000;
const EXPORT_TIMEOUT = 240000;

async function login(page, creds = THESIS_ADMIN) {
    await page.goto('/');
    // With the shared storageState the refresh cookie restores the session
    // automatically (tryRestoreSession) — no form login, no rate-limit hit.
    const restored = await page.waitForSelector('#app-shell.active', { timeout: 8000 })
        .then(() => true).catch(() => false);
    if (!restored) {
        await page.waitForSelector('#login-form', { timeout: 20000 });
        await page.fill('#login-username', creds.username);
        await page.fill('#login-password', creds.password);
        await page.click('#login-form button[type="submit"]');
        await page.waitForSelector('#app-shell.active', { timeout: 20000 });
    }
    await page.waitForSelector('#screen-selection.active', { timeout: 20000 });
}

async function openModel(page, modelId) {
    // Ensure we're on the selection screen (the shared page may be left on the
    // customization screen by a previous test).
    const onSelection = await page.locator('#screen-selection.active').count();
    if (!onSelection) {
        await page.evaluate(() => window.Screens ? window.Screens.show('selection')
            : (typeof Screens !== 'undefined' && Screens.show('selection')));
        await page.waitForSelector('#screen-selection.active', { timeout: 20000 });
    }
    await page.click(`[data-model-id="${modelId}"]`);
    await page.waitForSelector('#screen-customization.active', { timeout: 20000 });
    // Wait for the parameter controls to be generated.
    await page.waitForFunction(
        (id) => window.parameterEditor && window.parameterEditor.currentModel
            && window.parameterEditor.currentModel.id === id,
        modelId, { timeout: 20000 });
}

// Set one parameter through the real control, dispatching input+change so the
// app's handlers (this.parameters, SCAD editor, value display) all fire.
async function setParam(page, name, value) {
    const sel = `#param-${name}`;
    await page.waitForSelector(sel, { state: 'attached', timeout: 15000 });
    // Set via evaluate + dispatched events so it works regardless of which tab
    // is currently visible (selectOption/fill would require the control to be
    // visible; parameter controls live in tab panes that may be inactive).
    await page.locator(sel).evaluate((el, v) => {
        if (el.tagName === 'SELECT') {
            el.value = String(v);
        } else if (el.type === 'checkbox') {
            el.checked = Boolean(v);
        } else {
            el.value = String(v);
        }
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
    }, value);
}

// Apply an entire frozen config's parameters.
async function applyConfig(page, parameters) {
    for (const [name, value] of Object.entries(parameters)) {
        await setParam(page, name, value);
    }
}

// Read the app's source-of-truth parameter object.
function readParameters(page) {
    return page.evaluate(() => JSON.parse(JSON.stringify(window.parameterEditor.parameters)));
}

// Render the preview and wait for a GLB blob URL (or throw on error status).
async function render(page, timeout = RENDER_TIMEOUT) {
    await page.click('#render-btn');
    await page.waitForFunction(() => {
        const pe = window.parameterEditor;
        return pe && pe.currentGlbUrl && String(pe.currentGlbUrl).startsWith('blob:');
    }, { timeout });
}

// Read the current status bar text (it auto-reverts after 3s, so read promptly).
function statusText(page) {
    return page.locator('#status').textContent();
}

// Export the combined whole model as STL and return the saved file path.
// Renders each selection internally via the worker; captures the download.
async function exportCombinedSTL(page, savePath, timeout = EXPORT_TIMEOUT) {
    await page.click('#export-btn');
    await page.waitForSelector('#export-modal.active', { timeout: 10000 });
    await page.locator('input[name="export-format-opt"][value="stl"]').check();
    // Select only the "combined" whole-model row.
    await page.locator('.export-item').evaluateAll(els => {
        els.forEach(el => { el.checked = el.value === 'combined'; });
    });
    const [download] = await Promise.all([
        page.waitForEvent('download', { timeout }),
        page.click('#export-confirm-btn'),
    ]);
    await download.saveAs(savePath);
    return { path: savePath, suggestedFilename: download.suggestedFilename() };
}

module.exports = {
    login,
    openModel,
    setParam,
    applyConfig,
    readParameters,
    render,
    statusText,
    exportCombinedSTL,
    RENDER_TIMEOUT,
    EXPORT_TIMEOUT,
};
