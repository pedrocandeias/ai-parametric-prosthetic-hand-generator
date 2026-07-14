// @ts-check
'use strict';

// ROB-* (API + grounding logic) — controlled handling of invalid input, service
// unavailability, uncovered populations, contradictions and model floors.
// Every case has its EXPECTED controlled behaviour declared before execution and
// is classified as passa / falha controlada / falha não controlada / inconclusivo.
// No real people or datasets are used — only the synthetic seed + synthetic text.

const { test, expect } = require('@playwright/test');
const path = require('path');
const { THESIS_ADMIN, campaignDir } = require('../helpers/env');
const { writeResult } = require('../helpers/campaign');

// The platform's own deterministic sizing/grounding logic (unit-level, no AI).
const pm = require('../../../server/services/profileMapping');
const MODELS = require('../../../models/models-config.json').models;
const phoenix = MODELS.find(m => m.id === 'unlimbed_phoenix_hand');
const flexy = MODELS.find(m => m.id === 'flexy_beast');
const DIR = campaignDir();

const results = [];
function record(r) { results.push(r); }

// Log in ONCE for the whole file (stay under the 5/15min login limiter).
let SHARED_JWT = null;
test.beforeAll(async ({ request }) => {
    const res = await request.post('/api/auth/login', {
        data: { login: THESIS_ADMIN.username, password: THESIS_ADMIN.password },
    });
    SHARED_JWT = (await res.json()).accessToken;
});

test.afterAll(async () => {
    writeResult(DIR, 'robustness-api.json', { cases: results });
});

async function token() { return SHARED_JWT; }

test.describe('ROB · API validation & service robustness', () => {

    test('ROB-INV-001/002 · out-of-range parameter is rejected by config API', async ({ request }) => {
        const jwt = await token(request);
        const auth = { Authorization: `Bearer ${jwt}`, 'Content-Type': 'application/json' };

        // below minimum (palm_breadth_mm min 55)
        const low = await request.post('/api/configurations', {
            headers: auth, data: { model_id: 'flexy_beast', name: 'rob-low', parameters: { palm_breadth_mm: 10 } },
        });
        // above maximum (max 110)
        const high = await request.post('/api/configurations', {
            headers: auth, data: { model_id: 'flexy_beast', name: 'rob-high', parameters: { palm_breadth_mm: 999 } },
        });
        const lowBody = await low.json();
        const highBody = await high.json();

        const expected = 'controlled rejection (HTTP 400) with a validation message; no silent apply';
        const pass = low.status() === 400 && high.status() === 400;
        record({
            test_id: 'ROB-INV-001/002', expected,
            below_min: { status: low.status(), body: lowBody },
            above_max: { status: high.status(), body: highBody },
            classification: pass ? 'passa' : 'falha não controlada',
        });
        expect(low.status(), 'below-min rejected').toBe(400);
        expect(high.status(), 'above-max rejected').toBe(400);
    });

    test('ROB-INV-003 · missing required field is detected', async ({ request }) => {
        const jwt = await token(request);
        const auth = { Authorization: `Bearer ${jwt}`, 'Content-Type': 'application/json' };
        // Omit required `name`.
        const res = await request.post('/api/configurations', {
            headers: auth, data: { model_id: 'flexy_beast', parameters: { palm_breadth_mm: 83 } },
        });
        const body = await res.json();
        const pass = res.status() === 400 && !!body.error;
        record({
            test_id: 'ROB-INV-003', expected: 'HTTP 400 with explicit message; no silent creation',
            status: res.status(), body, classification: pass ? 'passa' : 'falha não controlada',
        });
        expect(res.status()).toBe(400);
    });

    test('ROB-INV-004 · wrong type in numeric parameter (observed behaviour)', async ({ request }) => {
        const jwt = await token(request);
        const auth = { Authorization: `Bearer ${jwt}`, 'Content-Type': 'application/json' };
        // parameters is z.record(z.unknown) — a string value is not type-checked by
        // zod, and validateParameterValues only compares numbers to min/max. This
        // documents (not fixes) whether a non-numeric value can slip through.
        const res = await request.post('/api/configurations', {
            headers: auth, data: { model_id: 'flexy_beast', name: 'rob-type', parameters: { palm_breadth_mm: 'wide' } },
        });
        const body = await res.json();
        const accepted = res.status() === 201;
        record({
            test_id: 'ROB-INV-004', expected: 'ideally rejected or coerced; observe actual',
            status: res.status(), body_keys: Object.keys(body || {}),
            observation: accepted
                ? 'string value ACCEPTED by config API (numeric bounds check skips non-numbers) — recorded finding, not fixed here'
                : 'string value rejected',
            classification: accepted ? 'falha controlada (aceite sem coerção — defeito registado)' : 'passa',
        });
        // Do not assert a specific status — this case is observational by design.
        expect([201, 400]).toContain(res.status());
    });

    test('ROB-SRV-001 · AI unavailable does not destroy a saved configuration', async ({ request }) => {
        const jwt = await token(request);
        const auth = { Authorization: `Bearer ${jwt}`, 'Content-Type': 'application/json' };
        // 1) save a valid config
        const created = await request.post('/api/configurations', {
            headers: auth, data: { model_id: 'flexy_beast', name: 'rob-srv', parameters: { palm_breadth_mm: 83 } },
        });
        const cfg = await created.json();
        // 2) AI call with the isolated (key-less) server → controlled 503
        const ai = await request.post('/api/ai/suggest', {
            headers: auth, data: { provider: 'anthropic', prompt: 'size this hand', model_id: 'flexy_beast' },
        });
        const aiBody = await ai.json();
        // 3) config still intact
        const after = await request.get(`/api/configurations/${cfg.id}`, { headers: auth });
        const afterBody = await after.json();
        const pass = ai.status() === 503 && !!aiBody.error && after.status() === 200
            && afterBody.parameters.palm_breadth_mm === 83;
        record({
            test_id: 'ROB-SRV-001', expected: 'AI failure returns a controlled error; saved config preserved & recoverable',
            ai_status: ai.status(), ai_error: aiBody.error,
            config_preserved: after.status() === 200 && afterBody.parameters?.palm_breadth_mm === 83,
            classification: pass ? 'passa' : 'falha controlada',
        });
        expect(ai.status(), 'AI unavailable → controlled 503').toBe(503);
        expect(after.status(), 'config preserved').toBe(200);
    });

    test('ROB-MOD-001 · profile below the Phoenix floor triggers an explicit clamp', async () => {
        // Synthetic child profile far below Phoenix palm minimum (82 mm).
        const childProfile = {
            measurements: {
                palm: { width_mm: 58, length_mm: 70, thickness_mm: 18 },
                digits: {
                    index: { total_length_mm: 60, proximal_length_mm: 20 },
                    middle: { total_length_mm: 60, proximal_length_mm: 22 },
                    ring: { total_length_mm: 60, proximal_length_mm: 20 },
                    pinky: { total_length_mm: 60, proximal_length_mm: 18 },
                    thumb: { total_length_mm: 50, proximal_length_mm: 19 },
                },
            },
        };
        const mapped = pm.mapProfileToModelParameters(childProfile, phoenix);
        const palmClamp = (mapped.clamped || []).find(c => c.name === 'palm_breadth_mm');
        const floor = phoenix.parameters.find(p => p.name === 'palm_breadth_mm').min;
        const pass = !!palmClamp && palmClamp.to === floor && mapped.parameters.palm_breadth_mm === floor;
        record({
            test_id: 'ROB-MOD-001', expected: 'value below floor is clamped to the model minimum and reported (no silent change)',
            phoenix_floor_mm: floor, mapped_palm: mapped.parameters.palm_breadth_mm,
            clamp_record: palmClamp || null, classification: pass ? 'passa' : 'falha não controlada',
        });
        expect(mapped.parameters.palm_breadth_mm, 'clamped to floor').toBe(floor);
        expect(palmClamp, 'clamp explicitly reported').toBeTruthy();
    });

    test('ROB-COV-001 · country without coverage yields a traceable substitute, not a false direct match', async () => {
        const candidates = [
            { id: 1, group_name: 'SYNTHETIC Adult Male 50th', country: 'Testland', gender: 'male', age_group: 'Adult (18-40)' },
            { id: 2, group_name: 'SYNTHETIC Adult Female 50th', country: 'Testland', gender: 'female', age_group: 'Adult (18-40)' },
        ];
        // Patient from a country with no dataset coverage.
        const patient = 'Homem adulto, 30 anos, de Portugal.';
        const match = pm.findBestProfileMatch(patient, candidates);
        const directCountry = match && new RegExp(match.country, 'i').test(patient);
        const pass = !!match && !directCountry && match.gender === 'male';
        record({
            test_id: 'ROB-COV-001', expected: 'no direct-country match; a gender/age substitute group is returned and its country differs (traceable)',
            matched_group: match?.group_name, matched_country: match?.country,
            is_direct_country_match: !!directCountry,
            classification: pass ? 'passa' : 'inconclusivo',
        });
        expect(match, 'a substitute match is returned').toBeTruthy();
        expect(directCountry, 'not presented as a direct-country match').toBeFalsy();
    });

    test('ROB-CON-001 · contradictory age/description resolved by a documented rule', async () => {
        // Contradiction: the word "criança" (child) with an explicit adult age.
        const patient = 'Criança de 40 anos.';
        const age = pm.extractAge(patient);
        const bucket = pm.ageGroupFromYears(age);
        // Documented rule: an explicit numeric age takes priority over a qualitative
        // child/adult word for age-bucketing.
        const pass = age === 40 && bucket === 'adult';
        record({
            test_id: 'ROB-CON-001', expected: 'explicit numeric age wins over qualitative term (documented priority)',
            parsed_age: age, age_bucket: bucket,
            rule: 'numeric age > qualitative descriptor for age bucketing',
            classification: pass ? 'passa' : 'inconclusivo',
        });
        expect(age).toBe(40);
        expect(bucket).toBe('adult');
    });
});
