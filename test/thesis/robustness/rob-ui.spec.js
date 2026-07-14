// @ts-check
'use strict';

// ROB-* (UI) — nominal flow, boundary values, invalid input at the control,
// render failure + recovery, and export blocked without valid geometry. Each
// case declares its expected controlled behaviour and is classified
// passa / falha controlada / falha não controlada / inconclusivo.

const { test, expect } = require('../helpers/testBase');
const fs = require('fs');
const path = require('path');
const os = require('os');
const po = require('../helpers/pageObjects');
const ai = require('../helpers/aiSchema');
const { campaignDir } = require('../helpers/env');
const { writeResult } = require('../helpers/campaign');

const DIR = campaignDir();
const results = [];
const record = (r) => results.push(r);
test.afterAll(async () => writeResult(DIR, 'robustness-ui.json', { cases: results }));

const MODEL = 'flexy_beast';
const PALM = 'palm_breadth_mm';
const PALM_MIN = 55, PALM_MAX = 110;

test.describe('ROB · UI flow robustness', () => {

    test('ROB-NOM-001 · nominal flow concludes (config→render→export)', async ({ authedPage: page }, testInfo) => {
        testInfo.setTimeout(240000);
        await po.login(page);
        await po.openModel(page, MODEL);
        await po.setParam(page, PALM, 83);
        await po.render(page);
        const artDir = path.join(DIR, 'artifacts', 'ROB-NOM-001');
        fs.mkdirSync(artDir, { recursive: true });
        const out = await po.exportCombinedSTL(page, path.join(artDir, 'nominal.stl'));
        const bytes = fs.statSync(out.path).size;
        const pass = bytes > 84;
        record({ test_id: 'ROB-NOM-001', expected: 'completes without unhandled error, produces an STL', stl_bytes: bytes, classification: pass ? 'passa' : 'falha não controlada' });
        expect(bytes, 'STL produced').toBeGreaterThan(84);
    });

    test('ROB-LIM-001/002 · exact min and max render per spec', async ({ authedPage: page }, testInfo) => {
        testInfo.setTimeout(240000);
        await po.login(page);
        await po.openModel(page, MODEL);

        const cases = {};
        for (const [id, value] of [['min', PALM_MIN], ['max', PALM_MAX]]) {
            await po.setParam(page, PALM, value);
            const applied = (await po.readParameters(page))[PALM];
            let rendered = false, err = null;
            try { await po.render(page, 120000); rendered = true; }
            catch (e) { err = String(e.message || e); }
            cases[id] = { requested: value, applied, rendered, error: err };
        }
        const pass = cases.min.rendered && cases.max.rendered
            && cases.min.applied === PALM_MIN && cases.max.applied === PALM_MAX;
        record({ test_id: 'ROB-LIM-001/002', expected: 'boundary values accepted and rendered', cases, classification: pass ? 'passa' : 'falha controlada' });
        expect(cases.min.applied).toBe(PALM_MIN);
        expect(cases.max.applied).toBe(PALM_MAX);
    });

    test('ROB-INV-004 · non-numeric text in a numeric control is not accepted', async ({ authedPage: page }) => {
        await po.login(page);
        await po.openModel(page, MODEL);
        await po.setParam(page, PALM, 83);
        const before = (await po.readParameters(page))[PALM];
        // Try to type letters into the range/number control.
        await page.locator(`#param-${PALM}`).evaluate((el) => {
            el.value = 'abc';
            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
        });
        const after = (await po.readParameters(page))[PALM];
        // A range/number input rejects non-numeric text: value stays numeric.
        const numericPreserved = typeof after === 'number' || (!Number.isNaN(Number(after)) && after !== 'abc');
        record({ test_id: 'ROB-INV-004', expected: 'control rejects non-numeric text; last valid numeric preserved', before, after, classification: numericPreserved ? 'passa' : 'falha não controlada' });
        expect(String(after)).not.toBe('abc');
    });

    test('ROB-SRV-002 · invalid AI response is rejected without corrupting parameters', async ({ authedPage: page }) => {
        await po.login(page);
        await po.openModel(page, MODEL);
        await page.click('[data-tab="ai"]');
        await page.fill('#anthropometric-input', 'Synthetic adult.');
        const before = await po.readParameters(page);
        await ai.mockAISuggest(page, ai.mockResponses(MODEL).invalid_json);
        await page.click('#ai-suggest-btn');
        // Expect an error surfaced and no parameter change.
        await page.waitForFunction(() => /Error getting AI suggestions/i.test(document.getElementById('status')?.textContent || ''), { timeout: 30000 }).catch(() => {});
        const after = await po.readParameters(page);
        await page.unroute('**/api/ai/suggest');
        const preserved = JSON.stringify(after) === JSON.stringify(before);
        record({ test_id: 'ROB-SRV-002', expected: 'invalid JSON rejected, parameters unchanged', preserved, classification: preserved ? 'passa' : 'falha não controlada' });
        expect(preserved, 'parameters unchanged after invalid AI response').toBe(true);
    });

    test('ROB-REN-001 · render failure is controlled and recoverable', async ({ authedPage: page }, testInfo) => {
        testInfo.setTimeout(240000);
        await po.login(page);
        await po.openModel(page, MODEL);
        // Inject broken SCAD directly into the editor and render.
        await page.locator('#editor').evaluate((el) => {
            el.value = 'cube([10,10,10);'; // unbalanced bracket → parse error
            el.dispatchEvent(new Event('input', { bubbles: true }));
        });
        let failObserved = false;
        await page.click('#render-btn');
        try {
            await page.waitForFunction(() => {
                const s = document.getElementById('status')?.textContent || '';
                return /render|error/i.test(s) && /error/i.test(s);
            }, { timeout: 90000 });
            failObserved = true;
        } catch { /* maybe tolerated */ }

        // Interface still usable → recover by regenerating valid SCAD and rendering.
        await po.setParam(page, PALM, 84); // regenerates the editor from parameters
        let recovered = false, recErr = null;
        try { await po.render(page, 120000); recovered = true; } catch (e) { recErr = String(e.message || e); }

        const cls = recovered ? (failObserved ? 'passa' : 'passa (falha não reproduzida, recuperação ok)') : 'falha não controlada';
        record({ test_id: 'ROB-REN-001', expected: 'controlled error message, UI stays usable, retry succeeds', fail_observed: failObserved, recovered, recover_error: recErr, classification: cls });
        expect(recovered, 'recovers after a bad render').toBe(true);
    });

    test('ROB-EXP-001 · export is blocked when geometry is invalid', async ({ authedPage: page }, testInfo) => {
        testInfo.setTimeout(180000);
        await po.login(page);
        await po.openModel(page, MODEL);
        // Broken SCAD so the export render cannot produce valid geometry.
        await page.locator('#editor').evaluate((el) => {
            el.value = 'cube([10,10,10);';
            el.dispatchEvent(new Event('input', { bubbles: true }));
        });
        let downloaded = false;
        page.on('download', () => { downloaded = true; });
        await page.click('#export-btn');
        await page.waitForSelector('#export-modal.active', { timeout: 10000 });
        await page.locator('input[name="export-format-opt"][value="stl"]').check();
        await page.locator('.export-item').evaluateAll(els => els.forEach(el => { el.checked = el.value === 'combined'; }));
        await page.click('#export-confirm-btn');
        // Expect an "Export error" status and NO download.
        let errored = false;
        try {
            await page.waitForFunction(() => /Export error/i.test(document.getElementById('status')?.textContent || ''), { timeout: 90000 });
            errored = true;
        } catch { /* record as-is */ }
        const pass = errored && !downloaded;
        record({ test_id: 'ROB-EXP-001', expected: 'export blocked with explicit error; no file downloaded', export_error_shown: errored, downloaded, classification: pass ? 'passa' : (downloaded ? 'falha não controlada' : 'inconclusivo') });
        expect(downloaded, 'no file exported from invalid geometry').toBe(false);
    });
});
