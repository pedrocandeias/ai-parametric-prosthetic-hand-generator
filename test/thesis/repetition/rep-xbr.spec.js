// @ts-check
'use strict';

// REP-XBR-001 — cross-browser reproducibility. Runs one frozen deterministic
// config through render+export in whichever browsers the project matrix enables
// (Chromium / Firefox / WebKit). Each browser writes its own metrics file; the
// campaign runner aggregates them into an equivalence classification against the
// Chromium reference (protocol §6.2). A browser that does not complete is
// recorded NEUTRALLY as "not_completed" with the phase where it stopped and the
// raw error — NO claim is made about the cause (platform incompatibility vs.
// environment timeout vs. harness config); that is left to the investigator.

const { test } = require('@playwright/test');
const fs = require('fs');
const path = require('path');
const po = require('../helpers/pageObjects');
const { analyzeSTL } = require('../helpers/stlMetrics');
const { campaignDir, THESIS_LOCAL_URL } = require('../helpers/env');
const { logLine } = require('../helpers/campaign');

// Phoenix: no printable sub-parts → the combined export is a single clean solid,
// the most stable choice for cross-serialiser comparison.
const CFG = require('../fixtures/frozen-configs.json').configs
    .find(c => c.id === 'REP-DET-003');
const DIR = campaignDir();

test('REP-XBR-001 · cross-browser render+export of a frozen config', async ({ browser }, testInfo) => {
    testInfo.setTimeout(240000);
    const browserName = testInfo.project.name;
    const artDir = path.join(DIR, 'artifacts', 'REP-XBR-001');
    fs.mkdirSync(artDir, { recursive: true });
    const resultPath = path.join(DIR, 'results', `xbr-${browserName}.json`);

    const record = (obj) => fs.writeFileSync(resultPath,
        JSON.stringify({ test_id: 'REP-XBR-001', browser: browserName, model_id: CFG.model_id, ...obj }, null, 2));

    // Manage the context ourselves and catch EVERYTHING so a browser that does
    // not complete is recorded neutrally (with the phase + raw error) rather than
    // failing the campaign or implying a cause.
    let context = null;
    let phase = 'launch';
    try {
        context = await browser.newContext({ baseURL: THESIS_LOCAL_URL });
        const page = await context.newPage();
        phase = 'login'; await po.login(page);
        phase = 'open_model'; await po.openModel(page, CFG.model_id);
        phase = 'apply_config'; await po.applyConfig(page, CFG.parameters);
        phase = 'render_export';
        const stlPath = path.join(artDir, `${browserName}.stl`);
        await po.exportCombinedSTL(page, stlPath);
        const metrics = analyzeSTL(fs.readFileSync(stlPath));
        record({ status: 'ok', metrics });
        logLine(DIR, { test_id: 'REP-XBR-001', browser: browserName, faces: metrics.faces, sha256: metrics.sha256 });
    } catch (err) {
        // Neutral record — no causal claim. `phase` says where it stopped.
        record({ status: 'not_completed', phase, error: String(err.message || err) });
        logLine(DIR, { test_id: 'REP-XBR-001', browser: browserName, phase, error: String(err.message || err) });
        testInfo.annotations.push({ type: 'xbr-not-completed', description: `${browserName} stopped at ${phase}: ${err.message}` });
    } finally {
        if (context) await context.close().catch(() => {});
    }
});
