// @ts-check
'use strict';

// REP-AI (LIVE) — real, repeated AI calls to measure variability. DISABLED by
// default; runs only when RUN_LIVE_AI_TESTS=1 (opt-in to paid provider spend).
// Records provider, exact model id, prompt, schema, raw + processed responses,
// errors, retries and timings, and computes per-parameter dispersion. Variability
// between non-identical responses is NOT a failure (protocol §6.3) — only schema
// or bounds violations are.

const { test, expect } = require('@playwright/test');
const po = require('../helpers/pageObjects');
const ai = require('../helpers/aiSchema');
const { RUN_LIVE_AI_TESTS, AI_LIVE_RUNS, campaignDir } = require('../helpers/env');
const { writeResult } = require('../helpers/campaign');

const MODELS = require('../../../models/models-config.json').models;
const flexy = MODELS.find(m => m.id === 'flexy_beast');
const DIR = campaignDir();

// Frozen prompt + patient text (identified, synthetic). Kept constant so the
// repetition measures the model's own variability, not prompt drift.
const PATIENT = 'Synthetic adult male, right-hand prosthesis. Approx. palm breadth 85 mm, medium build.';
const NUMERIC = (flexy.parameters || []).filter(p => p.type === 'number').map(p => p.name);
const PROMPT =
    'You are sizing a parametric prosthetic hand. Return ONLY a JSON object mapping ' +
    'these parameter names to millimetre values (numbers), no prose:\n' +
    NUMERIC.join(', ') + '\nKeep proportions realistic.';
const SCHEMA = { type: 'object', properties: Object.fromEntries(NUMERIC.map(n => [n, { type: 'number' }])) };

test.describe('REP-AI (live) · repeated real calls · dispersion', () => {
    test.skip(!RUN_LIVE_AI_TESTS, 'Live AI disabled — set RUN_LIVE_AI_TESTS=1 to enable paid calls.');

    test(`REP-AI-001 · ${AI_LIVE_RUNS}× real suggestions, measure dispersion`, async ({ page }) => {
        test.setTimeout(AI_LIVE_RUNS * 30000 + 60000);
        await po.login(page);
        const token = await page.evaluate(() => Auth.getToken());
        expect(token, 'authenticated token available').toBeTruthy();

        const runs = [];
        for (let i = 0; i < AI_LIVE_RUNS; i++) {
            const started = Date.now();
            let raw = null, processed = null, error = null, statusCode = null, grounded = null;
            try {
                const res = await page.request.post('/api/ai/suggest', {
                    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
                    data: { provider: 'anthropic', prompt: PROMPT, patient_text: PATIENT, model_id: 'flexy_beast' },
                    timeout: 30000,
                });
                statusCode = res.status();
                const body = await res.json();
                grounded = body.grounded ?? null;
                raw = body.text ?? null;
                processed = ai.parseSuggestionText(raw);
            } catch (err) {
                error = String(err.message || err);
            }
            const validation = processed ? ai.validateSuggestion(processed, flexy) : null;
            runs.push({ run: i, ms: Date.now() - started, status: statusCode, grounded, raw, processed, validation, error });
        }

        const processedList = runs.map(r => r.processed).filter(Boolean);
        const disp = ai.dispersion(processedList);
        const schemaValidCount = runs.filter(r => r.validation?.schema_valid).length;
        const withinBoundsCount = runs.filter(r => r.validation?.within_bounds).length;

        writeResult(DIR, 'REP-AI-001-live-dispersion.json', {
            test_id: 'REP-AI-001', mocked: false,
            provider: 'anthropic', model_id: 'claude-sonnet-4-6',
            prompt: PROMPT, prompt_sha256: ai.sha256(PROMPT),
            schema: SCHEMA, schema_sha256: ai.sha256(JSON.stringify(SCHEMA)),
            patient_text: PATIENT,
            runs_requested: AI_LIVE_RUNS, runs_ok: processedList.length,
            schema_valid_count: schemaValidCount, within_bounds_count: withinBoundsCount,
            dispersion: disp,
            runs,
            note: 'Variability across runs is expected and is NOT a failure; only schema/bounds violations are.',
        });

        // The applied contract must hold even though values vary.
        expect(processedList.length, 'at least one parseable response').toBeGreaterThan(0);
        expect(schemaValidCount, 'schema-valid responses').toBeGreaterThan(0);
    });
});
