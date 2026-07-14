'use strict';

// AI-suggestion contract + validators + deterministic mock fixtures.
//
// The server returns { text } where `text` is a JSON object mapping model
// parameter names to suggested values (the client parses it in
// app.js:getAISuggestions / applySuggestions). These helpers let the mocked
// suite check schema conformance, bounds and laterality WITHOUT any paid call,
// and let the live suite quantify per-parameter dispersion.

const crypto = require('crypto');

// Extract the first JSON object from an LLM text response (handles ```json fences).
function parseSuggestionText(text) {
    if (typeof text !== 'object' && typeof text !== 'string') return null;
    if (typeof text === 'object') return text;
    const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
    const candidate = fenced ? fenced[1] : (text.match(/\{[\s\S]*\}/) || [null])[0];
    if (!candidate) return null;
    try { return JSON.parse(candidate); } catch { return null; }
}

// Build a { name -> def } map of numeric params and the set of laterality names.
function modelParamIndex(modelDef) {
    const numeric = {};
    const laterality = new Set();
    for (const p of modelDef.parameters || []) {
        if (p.role === 'laterality') laterality.add(p.name);
        if (p.type === 'number') numeric[p.name] = p;
    }
    return { numeric, laterality };
}

// Classify a suggestion object against a model definition.
// Returns per-field verdicts and rollup counts (valid/corrected/rejected/…).
function validateSuggestion(suggestion, modelDef) {
    const { numeric, laterality } = modelParamIndex(modelDef);
    const fields = {};
    const counts = { valid: 0, out_of_range: 0, wrong_type: 0, unknown: 0, laterality_present: 0 };

    if (!suggestion || typeof suggestion !== 'object') {
        return { schema_valid: false, fields, counts, reason: 'not_an_object' };
    }
    for (const [name, value] of Object.entries(suggestion)) {
        if (laterality.has(name)) {
            fields[name] = { verdict: 'laterality_ignored', value };
            counts.laterality_present++;
            continue;
        }
        const def = numeric[name];
        if (!def) { fields[name] = { verdict: 'unknown_field', value }; counts.unknown++; continue; }
        if (typeof value !== 'number' || !Number.isFinite(value)) {
            fields[name] = { verdict: 'wrong_type', value }; counts.wrong_type++; continue;
        }
        if (value < def.min || value > def.max) {
            fields[name] = { verdict: 'out_of_range', value, min: def.min, max: def.max };
            counts.out_of_range++; continue;
        }
        fields[name] = { verdict: 'valid', value };
        counts.valid++;
    }
    return {
        schema_valid: counts.wrong_type === 0 && counts.unknown === 0,
        within_bounds: counts.out_of_range === 0,
        fields,
        counts,
    };
}

// Per-parameter dispersion across repeated suggestions (live suite).
function dispersion(suggestions) {
    const byParam = {};
    for (const s of suggestions) {
        if (!s || typeof s !== 'object') continue;
        for (const [k, v] of Object.entries(s)) {
            if (typeof v !== 'number' || !Number.isFinite(v)) continue;
            (byParam[k] = byParam[k] || []).push(v);
        }
    }
    const out = {};
    for (const [k, arr] of Object.entries(byParam)) {
        const n = arr.length;
        const mean = arr.reduce((a, b) => a + b, 0) / n;
        const variance = n > 1 ? arr.reduce((a, b) => a + (b - mean) ** 2, 0) / (n - 1) : 0;
        const sd = Math.sqrt(variance);
        const min = Math.min(...arr), max = Math.max(...arr);
        out[k] = {
            n, mean: round(mean), sd: round(sd), min, max, range: round(max - min),
            cv_pct: mean !== 0 ? round((sd / mean) * 100) : null,
            distinct: new Set(arr).size,
            values: arr,
        };
    }
    return out;
}

function round(v) { return Math.round(v * 1000) / 1000; }

function sha256(s) { return crypto.createHash('sha256').update(String(s)).digest('hex'); }

// Deterministic mock server responses (the { text, grounded } payload the real
// endpoint returns). Used with page.route to exercise schema / limits / errors
// / recovery without any provider call. `model` picks realistic param names.
function mockResponses(model = 'flexy_beast') {
    const valid = {
        flexy_beast: { palm_breadth_mm: 85, middle_finger_length_mm: 74, index_finger_length_mm: 70, thumb_length_mm: 66 },
        paraglider_hand: { palm_breadth_mm: 85, palm_length_mm: 96, middle_finger_length_mm: 74, thumb_length_mm: 66 },
        unlimbed_phoenix_hand: { palm_breadth_mm: 100, index_finger_length_mm: 74, thumb_length_mm: 70 },
    }[model] || {};

    return {
        valid: { text: JSON.stringify(valid), grounded: false },
        valid_fenced: { text: '```json\n' + JSON.stringify(valid) + '\n```', grounded: true },
        out_of_range_high: { text: JSON.stringify({ palm_breadth_mm: 999 }), grounded: false },
        out_of_range_low: { text: JSON.stringify({ palm_breadth_mm: 1 }), grounded: false },
        includes_laterality: { text: JSON.stringify({ ...valid, mirrored: true, LeftRight: 'Right' }), grounded: false },
        unknown_field: { text: JSON.stringify({ ...valid, not_a_real_param: 42 }), grounded: false },
        wrong_type: { text: JSON.stringify({ palm_breadth_mm: 'large' }), grounded: false },
        invalid_json: { text: 'Sorry, I could not produce measurements for this patient.', grounded: false },
        empty_object: { text: '{}', grounded: false },
    };
}

// Install a page.route that intercepts POST /api/ai/suggest and returns a fixed
// payload — a MOCK, never a real AI call. Returns the captured request bodies.
async function mockAISuggest(page, payload, { status = 200 } = {}) {
    const requests = [];
    await page.route('**/api/ai/suggest', async (route) => {
        try { requests.push(JSON.parse(route.request().postData() || '{}')); } catch { requests.push(null); }
        await route.fulfill({
            status,
            contentType: 'application/json',
            body: JSON.stringify(payload),
        });
    });
    return requests;
}

module.exports = {
    parseSuggestionText,
    validateSuggestion,
    modelParamIndex,
    dispersion,
    mockResponses,
    mockAISuggest,
    sha256,
};
