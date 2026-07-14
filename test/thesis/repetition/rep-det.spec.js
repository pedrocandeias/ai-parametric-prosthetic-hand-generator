// @ts-check
'use strict';

// REP-DET-001/002/003 — deterministic repetition of the digital pathway.
// For each frozen config, drive the real UI: render + export the combined STL
// REP_RUNS times (protocol: ≥10) through the OpenSCAD WASM pipeline, analyse
// every mesh, and classify equivalence with a PRE-DECLARED tolerance.
//
// This exercises the genuine render→bed-seat→merge→STL pipeline each iteration
// (runExport re-renders per export), so it is a true repetition, not a re-hash.

const { test, expect, chromium } = require('@playwright/test');
const fs = require('fs');
const path = require('path');
const po = require('../helpers/pageObjects');
const { analyzeSTL, compareAnalyses } = require('../helpers/stlMetrics');
const { REP_RUNS, GEOMETRY_TOL_MM, campaignDir, THESIS_LOCAL_URL } = require('../helpers/env');
const { writeResult, logLine } = require('../helpers/campaign');

const FROZEN = require('../fixtures/frozen-configs.json').configs;
const DIR = campaignDir();

test.describe('REP-DET · deterministic repetition', () => {
    for (const cfg of FROZEN) {
        test(`${cfg.id} · ${cfg.label} · ${REP_RUNS}× render+export`, async ({}, testInfo) => {
            testInfo.setTimeout(REP_RUNS * 90000 + 120000); // generous per-run budget

            const artDir = path.join(DIR, 'artifacts', cfg.id);
            fs.mkdirSync(artDir, { recursive: true });

            // ONE browser per model, a FRESH CONTEXT per run. A fresh context is
            // an isolated browsing session (its own cache, storage and page), so
            // each repetition is an independent cold render+export with no DOM or
            // GLB-blob carry-over — but without the heavy churn (and OS pressure)
            // of launching a whole browser 10× per model. `--disable-dev-shm-usage`
            // avoids /dev/shm stalls on constrained hosts.
            const browser = await chromium.launch({ args: ['--disable-dev-shm-usage'] });
            let applied = null;
            const runs = [];
            try {
                for (let i = 0; i < REP_RUNS; i++) {
                    const stlPath = path.join(artDir, `run-${String(i).padStart(2, '0')}.stl`);
                    // One retry absorbs a transient WASM stall (a genuine platform
                    // fault fails both attempts and is preserved as such); logged.
                    const attempts = [];
                    let done = null;
                    for (let attempt = 0; attempt < 2 && !done; attempt++) {
                        const started = Date.now();
                        const context = await browser.newContext({ baseURL: THESIS_LOCAL_URL });
                        const page = await context.newPage();
                        try {
                            await po.login(page);
                            await po.openModel(page, cfg.model_id);
                            await po.applyConfig(page, cfg.parameters);
                            if (i === 0 && !applied) applied = await po.readParameters(page);
                            await po.exportCombinedSTL(page, stlPath);
                            const metrics = analyzeSTL(fs.readFileSync(stlPath));
                            done = { run: i, conclusion: true, attempt, ms: Date.now() - started, metrics };
                            logLine(DIR, { test_id: cfg.id, run: i, attempt, faces: metrics.faces, sha256: metrics.sha256 });
                        } catch (err) {
                            attempts.push({ attempt, ms: Date.now() - started, error: String(err.message || err) });
                            logLine(DIR, { test_id: cfg.id, run: i, attempt, error: String(err.message || err) });
                        } finally {
                            await context.close().catch(() => {});
                            await new Promise(r => setTimeout(r, 800));
                        }
                    }
                    runs.push(done || { run: i, conclusion: false, attempts, ms: attempts.reduce((a, b) => a + b.ms, 0) });
                }
            } finally {
                await browser.close();
            }

            // Classify equivalence against the first successful run.
            const ok = runs.filter(r => r.conclusion);
            const ref = ok[0]?.metrics || null;
            const comparisons = ok.map(r => ({
                run: r.run,
                ...(ref ? compareAnalyses(ref, r.metrics, GEOMETRY_TOL_MM) : {}),
            }));
            const distinctChecksums = new Set(ok.map(r => r.metrics.sha256)).size;
            const classes = comparisons.map(c => c.geometry_class);
            const allEquivalent = comparisons.every(c =>
                ['identical', 'serialization_only', 'within_tolerance'].includes(c.geometry_class));

            const result = {
                test_id: cfg.id,
                model_id: cfg.model_id,
                requested_parameters: cfg.parameters,
                applied_parameters: applied,
                runs_requested: REP_RUNS,
                runs_concluded: ok.length,
                tolerance_mm: GEOMETRY_TOL_MM,
                distinct_checksums: distinctChecksums,
                binary_stable: distinctChecksums === 1,
                geometry_classes: classes,
                all_geometrically_equivalent: allEquivalent,
                reference_metrics: ref,
                runs,
                comparisons,
                verdict: ok.length === REP_RUNS && allEquivalent ? 'passa'
                    : (ok.length === REP_RUNS ? 'falha controlada (divergência geométrica)' : 'inconclusivo'),
            };
            writeResult(DIR, `${cfg.id}.json`, result);

            // Preserve evidence first, THEN assert so real drift surfaces as a
            // failure but is never hidden. Ten conclusions is the hard gate.
            expect(ok.length, `${cfg.id}: concluded runs`).toBe(REP_RUNS);
            expect(allEquivalent, `${cfg.id}: all runs equivalent within ${GEOMETRY_TOL_MM}mm (classes: ${classes.join(',')})`).toBe(true);
        });
    }
});
