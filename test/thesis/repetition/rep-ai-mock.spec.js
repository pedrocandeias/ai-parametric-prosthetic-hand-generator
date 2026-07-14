// @ts-check
'use strict';

// REP-AI (MOCKED) — schema, limits, errors and recovery for the AI-suggestion
// path, using intercepted responses ONLY. No provider is contacted, so nothing
// here may ever be presented as a real repetition of the AI (protocol §6.3 +
// requirement: mocked results are never real AI repetition). The live dispersion
// suite is rep-ai-live.spec.js, gated by RUN_LIVE_AI_TESTS.

const { test, expect } = require('../helpers/testBase');
const po = require('../helpers/pageObjects');
const ai = require('../helpers/aiSchema');
const { campaignDir } = require('../helpers/env');
const { writeResult } = require('../helpers/campaign');

const MODELS = require('../../../models/models-config.json').models;
const flexy = MODELS.find(m => m.id === 'flexy_beast');
const DIR = campaignDir();
const MOCKS = ai.mockResponses('flexy_beast');
const PATIENT = 'Synthetic adult, palm about 85 mm.'; // synthetic, no real data

async function openAi(page) {
    await po.login(page);
    await po.openModel(page, 'flexy_beast');
    await page.click('[data-tab="ai"]');
    await page.fill('#anthropometric-input', PATIENT);
}

// Trigger a suggestion with a mocked response; return {requests, before, after}.
async function suggest(page, payload, { expectApply, status = 200 } = {}) {
    const before = await po.readParameters(page);
    const requests = await ai.mockAISuggest(page, payload, { status });
    await page.click('#ai-suggest-btn');
    // Wait for either the parameters to change (applied) or the error status.
    await page.waitForFunction((prev) => {
        const pe = window.parameterEditor;
        const changed = JSON.stringify(pe.parameters) !== prev;
        const st = (document.getElementById('status')?.textContent || '');
        return changed || /Error getting AI suggestions/i.test(st);
    }, JSON.stringify(before), { timeout: 30000 }).catch(() => { /* timeout tolerated → record as-is */ });
    const after = await po.readParameters(page);
    await page.unroute('**/api/ai/suggest');
    return { requests, before, after };
}

test.describe('REP-AI (mocked) · schema, limits, laterality, recovery', () => {

    // REP-AI-003 — schema conformance & value classification.
    test('REP-AI-003 · valid mock applies and conforms to schema', async ({ authedPage: page }) => {
        await openAi(page);
        const parsed = ai.parseSuggestionText(MOCKS.valid.text);
        const validation = ai.validateSuggestion(parsed, flexy);
        const { requests, before, after } = await suggest(page, MOCKS.valid, { expectApply: true });

        const changed = Object.keys(parsed).filter(k => after[k] === parsed[k]);
        writeResult(DIR, 'REP-AI-003-schema.json', {
            test_id: 'REP-AI-003', mocked: true, note: 'MOCK response — not a real AI repetition',
            request_body: requests[0], parsed_suggestion: parsed, validation,
            parameters_before: before, parameters_after: after, applied_fields: changed,
            verdict: validation.schema_valid && validation.within_bounds && changed.length ? 'passa' : 'falha controlada',
        });

        expect(validation.schema_valid).toBe(true);
        expect(validation.within_bounds).toBe(true);
        expect(changed.length, 'valid suggestion applied to parameters').toBeGreaterThan(0);
        // Request carried the documented fields.
        expect(requests[0]).toMatchObject({ provider: 'anthropic', model_id: 'flexy_beast', patient_text: PATIENT });
    });

    // REP-AI-001 (mocked variant) — limit handling: an out-of-range suggestion is
    // detectable against the schema; record how the client treats it.
    test('REP-AI-001 · out-of-range suggestion is classified against bounds', async ({ authedPage: page }) => {
        await openAi(page);
        const parsed = ai.parseSuggestionText(MOCKS.out_of_range_high.text); // palm_breadth_mm: 999 (max 110)
        const validation = ai.validateSuggestion(parsed, flexy);
        const { after } = await suggest(page, MOCKS.out_of_range_high);

        // Observation only (not a fix): the client applySuggestions path writes the
        // raw value into parameters without clamping (app.js:2207); the range slider
        // clamps the DOM but the model source-of-truth keeps the raw number. Record it.
        const observed = {
            parameters_after_palm: after.palm_breadth_mm,
            client_clamped_source_of_truth: after.palm_breadth_mm <= flexy.parameters.find(p => p.name === 'palm_breadth_mm').max,
        };
        writeResult(DIR, 'REP-AI-001-limits.json', {
            test_id: 'REP-AI-001', mocked: true, note: 'MOCK response — schema/limit check only',
            parsed_suggestion: parsed, validation, observed,
            verdict: validation.counts.out_of_range > 0 ? 'passa (fora de gama detectável no esquema)' : 'inconclusivo',
        });
        expect(validation.counts.out_of_range, 'out-of-range value detected by schema check').toBeGreaterThan(0);
    });

    // REP-AI-002 — laterality is NOT driven by AI inference.
    test('REP-AI-002 · laterality suggestion is ignored (deterministic UI control)', async ({ authedPage: page }) => {
        await openAi(page);
        await po.setParam(page, 'mirrored', false); // UI pins Left hand
        const before = await po.readParameters(page);
        const { after, requests } = await suggest(page, MOCKS.includes_laterality);

        writeResult(DIR, 'REP-AI-002-laterality.json', {
            test_id: 'REP-AI-002', mocked: true, note: 'MOCK response includes mirrored:true / LeftRight:Right',
            request_body: requests[0],
            laterality_before: before.mirrored, laterality_after: after.mirrored,
            preserved: after.mirrored === before.mirrored,
            verdict: after.mirrored === before.mirrored ? 'passa' : 'falha não controlada (lateralidade alterada pela IA)',
        });
        expect(after.mirrored, 'AI must not flip the user-chosen hand').toBe(before.mirrored);
    });

    // REP-AI-003 (recovery) — an invalid JSON response is rejected and the prior
    // configuration is preserved; a subsequent valid response then applies.
    test('REP-AI-003 · invalid response rejected, state preserved, retry recovers', async ({ authedPage: page }) => {
        await openAi(page);
        const before = await po.readParameters(page);
        const bad = await suggest(page, MOCKS.invalid_json);
        const preserved = JSON.stringify(bad.after) === JSON.stringify(before);

        // Retry with a valid mock → recovery.
        const good = await suggest(page, MOCKS.valid, { expectApply: true });
        const parsed = ai.parseSuggestionText(MOCKS.valid.text);
        const recovered = Object.keys(parsed).some(k => good.after[k] === parsed[k]);

        writeResult(DIR, 'REP-AI-003-recovery.json', {
            test_id: 'REP-AI-003', mocked: true,
            invalid_response_preserved_state: preserved,
            retry_recovered: recovered,
            parameters_before: before, parameters_after_invalid: bad.after, parameters_after_retry: good.after,
            verdict: preserved && recovered ? 'passa' : 'falha controlada',
        });
        expect(preserved, 'invalid AI response must not corrupt parameters').toBe(true);
        expect(recovered, 'valid retry recovers').toBe(true);
    });
});
