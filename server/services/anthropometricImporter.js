'use strict';

/**
 * AnthropometricDataImporter
 *
 * Ingests anthropometric measurements from manual input, CSV, or JSON and
 * converts them into a validated AnthropometricProfile plus:
 *   - geometry_parameters  — strict numeric vector for the configurator
 *   - ai_context           — semantic object for AI reasoning
 *
 * No CAD geometry or STL generation occurs here — data normalisation only.
 */

const SCHEMA_VERSION = '1.0';

// ── Unit conversion ──────────────────────────────────────────────────────────

const UNIT_FACTORS = { mm: 1, cm: 10, m: 1000, in: 25.4, inch: 25.4, inches: 25.4, '"': 25.4 };

function toMm(value, unit = 'mm') {
    const factor = UNIT_FACTORS[(unit || 'mm').toLowerCase().trim()];
    if (!factor) throw new Error(`Unknown unit: "${unit}"`);
    return Math.round(value * factor * 100) / 100;
}

// ── Reference adult-hand dimensions (50th-percentile, mm) ────────────────────

const REF = {
    palm_length_mm:      100,
    palm_width_mm:        85,
    digit_index_total:    68,
    digit_middle_total:   73,
    digit_ring_total:     68,
    digit_pinky_total:    55,
    wrist_circumference: 165,
};

// ── Hardware tables ───────────────────────────────────────────────────────────

const HARDWARE = {
    m2: { pivot_diameter_mm: 2.0 },
    m3: { pivot_diameter_mm: 3.0 },
    m4: { pivot_diameter_mm: 4.0 },
};

const TOLERANCE = { snug: 0.2, standard: 0.4, loose: 0.6 };

// ── Validation ranges [min_mm, max_mm] ───────────────────────────────────────

const FIELD_RANGES = {
    'palm.width_mm':                    [40,  130],
    'palm.length_mm':                   [60,  180],
    'digits.index.proximal_length_mm':  [15,   70],
    'digits.index.middle_length_mm':    [10,   55],
    'digits.index.distal_length_mm':    [ 8,   40],
    'digits.index.circumference_mm':    [25,  110],
    'digits.middle.proximal_length_mm': [15,   70],
    'digits.middle.middle_length_mm':   [10,   55],
    'digits.middle.distal_length_mm':   [ 8,   40],
    'digits.middle.circumference_mm':   [25,  110],
    'digits.ring.proximal_length_mm':   [15,   70],
    'digits.ring.middle_length_mm':     [10,   55],
    'digits.ring.distal_length_mm':     [ 8,   40],
    'digits.ring.circumference_mm':     [25,  110],
    'digits.pinky.proximal_length_mm':  [12,   60],
    'digits.pinky.middle_length_mm':    [ 8,   50],
    'digits.pinky.distal_length_mm':    [ 6,   35],
    'digits.pinky.circumference_mm':    [20,   90],
    'wrist.circumference_mm':           [90,  290],
    'residual_limb.length_mm':          [ 0,  450],
};

const IMPORTANT_FIELDS = [
    'palm.width_mm', 'palm.length_mm',
    'digits.index.proximal_length_mm', 'digits.index.middle_length_mm', 'digits.index.distal_length_mm',
    'digits.middle.proximal_length_mm',
    'digits.ring.proximal_length_mm',
    'digits.pinky.proximal_length_mm',
    'wrist.circumference_mm',
    'residual_limb.length_mm',
    'residual_limb.circumferences_mm',
];

// ── Flat-key aliases → canonical nested paths ────────────────────────────────

const KEY_MAP = {
    // palm
    palm_width:               (v, u) => ['palm', 'width_mm',  toMm(v, u)],
    hand_breadth:             (v, u) => ['palm', 'width_mm',  toMm(v, u)],
    palm_length:              (v, u) => ['palm', 'length_mm', toMm(v, u)],
    hand_length:              (v, u) => ['palm', 'length_mm', toMm(v, u)],
    // wrist
    wrist_circumference:      (v, u) => ['wrist', 'circumference_mm', toMm(v, u)],
    // residual limb
    residual_limb_length:     (v, u) => ['residual_limb', 'length_mm', toMm(v, u)],
    stump_length:             (v, u) => ['residual_limb', 'length_mm', toMm(v, u)],
    residual_limb_circumference: (v, u) => ['residual_limb', 'circumferences_mm', toMm(v, u)],
    stump_circumference:      (v, u) => ['residual_limb', 'circumferences_mm', toMm(v, u)],
    // index
    finger_index_proximal:    (v, u) => ['digits', 'index', 'proximal_length_mm', toMm(v, u)],
    finger_index_middle:      (v, u) => ['digits', 'index', 'middle_length_mm',   toMm(v, u)],
    finger_index_distal:      (v, u) => ['digits', 'index', 'distal_length_mm',   toMm(v, u)],
    finger_index_circumference: (v, u) => ['digits', 'index', 'circumference_mm', toMm(v, u)],
    // middle
    finger_middle_proximal:   (v, u) => ['digits', 'middle', 'proximal_length_mm', toMm(v, u)],
    finger_middle_middle:     (v, u) => ['digits', 'middle', 'middle_length_mm',   toMm(v, u)],
    finger_middle_distal:     (v, u) => ['digits', 'middle', 'distal_length_mm',   toMm(v, u)],
    finger_middle_circumference: (v, u) => ['digits', 'middle', 'circumference_mm', toMm(v, u)],
    // ring
    finger_ring_proximal:     (v, u) => ['digits', 'ring', 'proximal_length_mm', toMm(v, u)],
    finger_ring_middle:       (v, u) => ['digits', 'ring', 'middle_length_mm',   toMm(v, u)],
    finger_ring_distal:       (v, u) => ['digits', 'ring', 'distal_length_mm',   toMm(v, u)],
    finger_ring_circumference: (v, u) => ['digits', 'ring', 'circumference_mm',  toMm(v, u)],
    // pinky
    finger_pinky_proximal:    (v, u) => ['digits', 'pinky', 'proximal_length_mm', toMm(v, u)],
    finger_pinky_middle:      (v, u) => ['digits', 'pinky', 'middle_length_mm',   toMm(v, u)],
    finger_pinky_distal:      (v, u) => ['digits', 'pinky', 'distal_length_mm',   toMm(v, u)],
    finger_pinky_circumference: (v, u) => ['digits', 'pinky', 'circumference_mm', toMm(v, u)],
};

// ── CSV parser ────────────────────────────────────────────────────────────────
// Format A (key-value):  measurement , value [, unit]
// Format B (flat):       header row  + one data row

function parseCsv(csvText) {
    const lines = csvText.trim().split(/\r?\n/)
        .map(l => l.trim())
        .filter(l => l && !l.startsWith('#'));

    if (lines.length === 0) throw new Error('Empty CSV');

    const split = line => line.split(',').map(c => c.trim().replace(/^["']|["']$/g, ''));
    const headers = split(lines[0]).map(h => h.toLowerCase());

    if (['measurement', 'field', 'name', 'key'].includes(headers[0])) {
        // Format A
        const result = {};
        for (let i = 1; i < lines.length; i++) {
            const [key, val, unit] = split(lines[i]);
            if (!key || val === undefined) continue;
            result[key.toLowerCase().replace(/[-\s]/g, '_')] = { value: parseFloat(val), unit: unit || 'mm' };
        }
        return result;
    }

    // Format B
    if (lines.length < 2) throw new Error('CSV Format B requires at least a header row and one data row');
    const values = split(lines[1]);
    const result = {};
    headers.forEach((h, i) => {
        if (values[i] !== undefined && values[i] !== '') {
            result[h.replace(/[-\s]/g, '_')] = { value: parseFloat(values[i]), unit: 'mm' };
        }
    });
    return result;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function getDeep(obj, dotPath) {
    return dotPath.split('.').reduce((o, k) => (o != null ? o[k] : undefined), obj);
}

function setDeep(obj, path, value) {
    let cur = obj;
    for (let i = 0; i < path.length - 1; i++) {
        if (!cur[path[i]]) cur[path[i]] = {};
        cur = cur[path[i]];
    }
    const last = path[path.length - 1];
    // Special handling for arrays (circumferences)
    if (last === 'circumferences_mm') {
        if (!Array.isArray(cur[last])) cur[last] = [];
        cur[last].push(value);
    } else {
        cur[last] = value;
    }
}

function emptyMeasurements() {
    return { palm: {}, digits: { index: {}, middle: {}, ring: {}, pinky: {} }, wrist: {}, residual_limb: {} };
}

// ── Normalise flat input (from CSV or flat JSON/form POST) ────────────────────

function normaliseFlatInput(flatData, defaultUnit = 'mm') {
    const measurements = emptyMeasurements();

    for (const [key, entry] of Object.entries(flatData)) {
        const cleanKey = key.toLowerCase().replace(/[-\s]/g, '_');
        const mapper = KEY_MAP[cleanKey];
        if (!mapper) continue;

        let value, unit;
        if (typeof entry === 'object' && entry !== null && 'value' in entry) {
            value = parseFloat(entry.value);
            unit  = entry.unit || defaultUnit;
        } else {
            value = parseFloat(entry);
            unit  = defaultUnit;
        }

        if (isNaN(value)) continue;

        try {
            const pathAndVal = mapper(value, unit);
            const mm  = pathAndVal.pop();
            setDeep(measurements, pathAndVal, mm);
        } catch { /* unknown unit — skip */ }
    }

    return measurements;
}

// ── Normalise nested AnthropometricProfile JSON ───────────────────────────────

function normaliseNestedInput(input, defaultUnit = 'mm') {
    function recurse(v) {
        if (v === null || v === undefined) return undefined;
        if (typeof v === 'number')         return v;
        if (typeof v === 'string')         return parseFloat(v) || undefined;
        if (typeof v === 'object' && 'value' in v) {
            const n = parseFloat(v.value);
            return isNaN(n) ? undefined : toMm(n, v.unit || defaultUnit);
        }
        if (Array.isArray(v)) return v.map(recurse).filter(x => x !== undefined);
        const out = {};
        for (const [k, val] of Object.entries(v)) {
            const r = recurse(val);
            if (r !== undefined) out[k] = r;
        }
        return out;
    }

    const measurements = emptyMeasurements();
    const src = recurse(input.measurements || {});

    if (src.palm)          Object.assign(measurements.palm, src.palm);
    if (src.wrist)         Object.assign(measurements.wrist, src.wrist);
    if (src.residual_limb) Object.assign(measurements.residual_limb, src.residual_limb);
    if (src.digits) {
        for (const d of ['index', 'middle', 'ring', 'pinky']) {
            if (src.digits[d]) Object.assign(measurements.digits[d], src.digits[d]);
        }
    }

    return measurements;
}

// ── Validation ────────────────────────────────────────────────────────────────

function validateMeasurements(measurements) {
    const outliers = [];
    const errors   = [];

    for (const [path, [min, max]] of Object.entries(FIELD_RANGES)) {
        const val = getDeep(measurements, path);
        if (val === undefined || val === null) continue;
        if (typeof val !== 'number') { errors.push(`${path} is not a number`); continue; }
        if (val < min || val > max) {
            outliers.push({ field: path, value: val, range: [min, max] });
        }
    }

    // Cross-field: palm width should not exceed palm length
    const palmLen = getDeep(measurements, 'palm.length_mm');
    const palmWid = getDeep(measurements, 'palm.width_mm');
    if (palmLen && palmWid && palmWid > palmLen * 1.2) {
        outliers.push({ field: 'palm.width_mm', value: palmWid, range: [0, palmLen * 1.2],
            note: 'Palm width unexpectedly large relative to palm length' });
    }

    return { outliers, errors };
}

// ── Missing field detection ───────────────────────────────────────────────────

function detectMissing(measurements) {
    const missing = [];
    for (const f of IMPORTANT_FIELDS) {
        const val = getDeep(measurements, f);
        if (val === undefined || val === null || (Array.isArray(val) && val.length === 0)) {
            missing.push(f);
        }
    }
    return missing;
}

// ── Derived value computation ─────────────────────────────────────────────────

function computeDerived(measurements, constraints) {
    const derived = {};

    // global_scale: palm-length ratio vs reference adult
    const palmLen = getDeep(measurements, 'palm.length_mm');
    derived.global_scale = palmLen
        ? Math.round((palmLen / REF.palm_length_mm) * 1000) / 1000
        : 1.0;

    // per-digit scale ratios
    const DIGIT_REF = { index: REF.digit_index_total, middle: REF.digit_middle_total,
                        ring:  REF.digit_ring_total,  pinky:  REF.digit_pinky_total };
    derived.finger_scale_ratios = {};
    for (const [d, ref] of Object.entries(DIGIT_REF)) {
        const seg = measurements.digits?.[d] || {};
        const total = (seg.proximal_length_mm || 0) + (seg.middle_length_mm || 0) + (seg.distal_length_mm || 0);
        if (total > 0) derived.finger_scale_ratios[d] = Math.round((total / ref) * 1000) / 1000;
    }

    // joint_spacing_mm: estimated from index proximal phalanx
    const idxProx = getDeep(measurements, 'digits.index.proximal_length_mm');
    if (idxProx) derived.joint_spacing_mm = Math.round(idxProx * 0.85 * 10) / 10;

    // socket_inner_diameter_mm: from residual limb circumference
    const circs = getDeep(measurements, 'residual_limb.circumferences_mm');
    const firstCirc = Array.isArray(circs) ? circs[0] : undefined;
    if (firstCirc) derived.socket_inner_diameter_mm = Math.round((firstCirc / Math.PI) * 10) / 10;

    // wrist_diameter_mm
    const wristCirc = getDeep(measurements, 'wrist.circumference_mm');
    if (wristCirc) derived.wrist_diameter_mm = Math.round((wristCirc / Math.PI) * 10) / 10;

    return derived;
}

// ── Geometry parameter vector ─────────────────────────────────────────────────

function buildGeometryParameters(measurements, derived, constraints) {
    const hw  = HARDWARE[constraints?.hardware_standard]  || HARDWARE.m3;
    const tol = TOLERANCE[constraints?.tolerance_preference] || TOLERANCE.standard;

    const params = {
        global_scale:     derived.global_scale ?? 1.0,
        clearance_mm:     tol,
        pivot_diameter_mm: hw.pivot_diameter_mm,
    };

    // Per-digit total lengths
    for (const d of ['index', 'middle', 'ring', 'pinky']) {
        const seg = measurements.digits?.[d] || {};
        const total = (seg.proximal_length_mm || 0) + (seg.middle_length_mm || 0) + (seg.distal_length_mm || 0);
        if (total > 0) params[`finger_length_${d}`] = Math.round(total * 10) / 10;
    }

    if (derived.socket_inner_diameter_mm) params.socket_inner_diameter_mm = derived.socket_inner_diameter_mm;
    if (derived.joint_spacing_mm)         params.joint_spacing_mm         = derived.joint_spacing_mm;

    return params;
}

// ── AI context object ─────────────────────────────────────────────────────────

function buildAiContext(measurements, derived, constraints, validation, missing) {
    const notes = [];

    const src = constraints?.measurement_source || 'manual';
    if (src === 'manual') notes.push('Manually entered measurements');
    else if (src === 'csv')  notes.push('Imported from CSV file');
    else if (src === 'json') notes.push('Imported from JSON file');
    else if (src === 'scan') notes.push('Scan-derived measurements');

    if (missing.length > 0) notes.push(`${missing.length} measurement(s) missing — defaults or ratios used`);
    for (const o of validation.outliers) {
        notes.push(`Outlier: ${o.field} = ${o.value} mm (expected ${o.range[0]}–${o.range[1]} mm)${o.note ? ' — ' + o.note : ''}`);
    }

    const uncertainty = missing.length <= 2 ? 'low' : missing.length <= 6 ? 'medium' : 'high';

    return {
        schema_version:       SCHEMA_VERSION,
        missing_measurements: missing,
        uncertainty,
        measurement_source:   src,
        notes,
        outliers:             validation.outliers.map(o => ({ field: o.field, value: o.value, expected_range: o.range })),
        derived_confidence:   derived.global_scale !== 1.0 ? 'computed' : 'default',
        hardware_standard:    constraints?.hardware_standard    || 'm3',
        tolerance_preference: constraints?.tolerance_preference || 'standard',
    };
}

// ── Main entry point ──────────────────────────────────────────────────────────

/**
 * Process raw anthropometric input.
 *
 * @param {object} input
 * @param {'csv'|'json'|'form'} [input.format='form']
 * @param {string|object}        input.data          — raw data
 * @param {object}               [input.meta={}]     — metadata / constraints
 * @param {string}               [input.default_unit='mm']
 * @returns {{ profile, geometry_parameters, ai_context }}
 */
function process(input) {
    const { format = 'form', data, meta = {}, default_unit = 'mm' } = input;

    let measurements;
    if (format === 'csv') {
        const flat = parseCsv(typeof data === 'string' ? data : String(data));
        measurements = normaliseFlatInput(flat, default_unit);
    } else if (format === 'json' && typeof data === 'object' && data !== null && data.measurements) {
        measurements = normaliseNestedInput(data, default_unit);
    } else {
        measurements = normaliseFlatInput(data || {}, default_unit);
    }

    const constraints = {
        tolerance_preference: meta.tolerance_preference || 'standard',
        hardware_standard:    meta.hardware_standard    || 'm3',
        measurement_source:   meta.measurement_source   || format,
    };

    const validation = validateMeasurements(measurements);
    const missing    = detectMissing(measurements);
    const derived    = computeDerived(measurements, constraints);

    const profile = {
        schema_version: SCHEMA_VERSION,
        metadata: {
            group_name:         meta.group_name         || null,
            country:            meta.country            || null,
            gender:             meta.gender             || null,
            age_group:          meta.age_group          || null,
            percentile:         meta.percentile         || null,
            sample_size:        meta.sample_size        || null,
            data_source:        meta.data_source        || null,
            notes:              meta.notes              || null,
            measurement_source: constraints.measurement_source,
            timestamp:          new Date().toISOString(),
        },
        measurements,
        derived,
        constraints,
    };

    const geometry_parameters = buildGeometryParameters(measurements, derived, constraints);
    const ai_context          = buildAiContext(measurements, derived, constraints, validation, missing);

    return { profile, geometry_parameters, ai_context };
}

module.exports = { process, parseCsv, SCHEMA_VERSION };
