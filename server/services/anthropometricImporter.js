'use strict';

/**
 * AnthropometricDataImporter
 *
 * Ingests anthropometric measurements from manual input, CSV, or JSON and
 * converts them into a validated AnthropometricProfile plus:
 *   - geometry_parameters  — strict numeric vector for the configurator
 *   - ai_context           — semantic object for AI reasoning
 *
 * Hierarchy:
 *   1. Primary inputs   — directly measured (palm, fingers, residual limb)
 *   2. Derived geometry — computed from primaries (phalanx segments, socket geometry)
 *   3. Functional       — per-digit finger lengths, joint positions
 *   4. Manufacturing    — clearance, hardware, reinforcement zones
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
    palm_length_mm:           100,
    palm_width_mm:             85,
    palm_thickness_mm:         26,
    digit_thumb_total:         58,
    digit_index_total:         68,
    digit_middle_total:        73,
    digit_ring_total:          68,
    digit_pinky_total:         55,
    average_finger_width_mm:   17,
    wrist_circumference:      165,
    residual_circ_proximal:   200,
    residual_circ_distal:     170,
};

// ── Phalanx proportional ratios (anatomical, index finger as reference) ───────
// Source: mean ratios from cadaveric and radiographic studies
// 3-phalanx fingers (index, middle, ring, pinky)
const PHALANX_RATIOS = {
    proximal: 0.45,   // ~45% of total finger length
    middle:   0.31,   // ~31%
    distal:   0.24,   // ~24%
    // Thumb (2 phalanges)
    thumb_proximal: 0.54,
    thumb_distal:   0.46,
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
    // Palm (primary inputs)
    'palm.width_mm':                         [40,  130],
    'palm.length_mm':                        [60,  180],
    'palm.thickness_mm':                     [10,   60],
    'palm.average_finger_width_mm':          [ 8,   35],
    // Digits — segment lengths (legacy / detailed input)
    'digits.index.proximal_length_mm':       [15,   70],
    'digits.index.middle_length_mm':         [10,   55],
    'digits.index.distal_length_mm':         [ 8,   40],
    'digits.index.circumference_mm':         [25,  110],
    'digits.middle.proximal_length_mm':      [15,   70],
    'digits.middle.middle_length_mm':        [10,   55],
    'digits.middle.distal_length_mm':        [ 8,   40],
    'digits.middle.circumference_mm':        [25,  110],
    'digits.ring.proximal_length_mm':        [15,   70],
    'digits.ring.middle_length_mm':          [10,   55],
    'digits.ring.distal_length_mm':          [ 8,   40],
    'digits.ring.circumference_mm':          [25,  110],
    'digits.pinky.proximal_length_mm':       [12,   60],
    'digits.pinky.middle_length_mm':         [ 8,   50],
    'digits.pinky.distal_length_mm':         [ 6,   35],
    'digits.pinky.circumference_mm':         [20,   90],
    // Digits — total lengths (new primary inputs)
    'digits.thumb.total_length_mm':          [25,   90],
    'digits.index.total_length_mm':          [40,  115],
    'digits.middle.total_length_mm':         [45,  120],
    'digits.ring.total_length_mm':           [40,  115],
    'digits.pinky.total_length_mm':          [28,   88],
    // Wrist
    'wrist.circumference_mm':                [90,  290],
    // Residual limb
    'residual_limb.length_mm':               [ 0,  450],
    'residual_limb.circumference_proximal_mm': [70, 380],
    'residual_limb.circumference_distal_mm': [50,  300],
};

// Fields whose absence is notable (used for completeness scoring)
const IMPORTANT_FIELDS = [
    'palm.width_mm',
    'palm.length_mm',
    'palm.thickness_mm',
    'digits.index.proximal_length_mm',
    'digits.index.middle_length_mm',
    'digits.index.distal_length_mm',
    'digits.middle.proximal_length_mm',
    'digits.ring.proximal_length_mm',
    'digits.pinky.proximal_length_mm',
    'wrist.circumference_mm',
    'residual_limb.length_mm',
    'residual_limb.circumference_proximal_mm',
];

// ── Flat-key aliases → canonical nested paths ────────────────────────────────

const KEY_MAP = {
    // palm
    palm_width:               (v, u) => ['palm', 'width_mm',  toMm(v, u)],
    hand_breadth:             (v, u) => ['palm', 'width_mm',  toMm(v, u)],
    palm_breadth:             (v, u) => ['palm', 'width_mm',  toMm(v, u)],  // primary alias
    palm_length:              (v, u) => ['palm', 'length_mm', toMm(v, u)],
    hand_length:              (v, u) => ['palm', 'length_mm', toMm(v, u)],
    palm_thickness:           (v, u) => ['palm', 'thickness_mm', toMm(v, u)],  // new primary
    average_finger_width:     (v, u) => ['palm', 'average_finger_width_mm', toMm(v, u)],  // new primary
    finger_avg_width:         (v, u) => ['palm', 'average_finger_width_mm', toMm(v, u)],
    // wrist
    wrist_circumference:      (v, u) => ['wrist', 'circumference_mm', toMm(v, u)],
    // residual limb
    residual_limb_length:        (v, u) => ['residual_limb', 'length_mm', toMm(v, u)],
    stump_length:                (v, u) => ['residual_limb', 'length_mm', toMm(v, u)],
    residual_length:             (v, u) => ['residual_limb', 'length_mm', toMm(v, u)],  // new primary alias
    // New dedicated circumference fields (proximal + distal)
    residual_circumference_proximal: (v, u) => ['residual_limb', 'circumference_proximal_mm', toMm(v, u)],
    residual_circumference_distal:   (v, u) => ['residual_limb', 'circumference_distal_mm',   toMm(v, u)],
    // Legacy circumference (backwards compat — maps to array)
    residual_limb_circumference: (v, u) => ['residual_limb', 'circumferences_mm', toMm(v, u)],
    stump_circumference:         (v, u) => ['residual_limb', 'circumferences_mm', toMm(v, u)],
    // thumb (new primary)
    thumb_length_total:       (v, u) => ['digits', 'thumb',  'total_length_mm', toMm(v, u)],
    finger_thumb_total:       (v, u) => ['digits', 'thumb',  'total_length_mm', toMm(v, u)],
    // finger total lengths (new primary inputs)
    index_length_total:       (v, u) => ['digits', 'index',  'total_length_mm', toMm(v, u)],
    middle_length_total:      (v, u) => ['digits', 'middle', 'total_length_mm', toMm(v, u)],
    ring_length_total:        (v, u) => ['digits', 'ring',   'total_length_mm', toMm(v, u)],
    little_length_total:      (v, u) => ['digits', 'pinky',  'total_length_mm', toMm(v, u)],
    finger_index_total:       (v, u) => ['digits', 'index',  'total_length_mm', toMm(v, u)],
    finger_middle_total:      (v, u) => ['digits', 'middle', 'total_length_mm', toMm(v, u)],
    finger_ring_total:        (v, u) => ['digits', 'ring',   'total_length_mm', toMm(v, u)],
    finger_pinky_total:       (v, u) => ['digits', 'pinky',  'total_length_mm', toMm(v, u)],
    // index segments
    finger_index_proximal:    (v, u) => ['digits', 'index', 'proximal_length_mm', toMm(v, u)],
    finger_index_middle:      (v, u) => ['digits', 'index', 'middle_length_mm',   toMm(v, u)],
    finger_index_distal:      (v, u) => ['digits', 'index', 'distal_length_mm',   toMm(v, u)],
    finger_index_circumference: (v, u) => ['digits', 'index', 'circumference_mm', toMm(v, u)],
    // middle segments
    finger_middle_proximal:   (v, u) => ['digits', 'middle', 'proximal_length_mm', toMm(v, u)],
    finger_middle_middle:     (v, u) => ['digits', 'middle', 'middle_length_mm',   toMm(v, u)],
    finger_middle_distal:     (v, u) => ['digits', 'middle', 'distal_length_mm',   toMm(v, u)],
    finger_middle_circumference: (v, u) => ['digits', 'middle', 'circumference_mm', toMm(v, u)],
    // ring segments
    finger_ring_proximal:     (v, u) => ['digits', 'ring', 'proximal_length_mm', toMm(v, u)],
    finger_ring_middle:       (v, u) => ['digits', 'ring', 'middle_length_mm',   toMm(v, u)],
    finger_ring_distal:       (v, u) => ['digits', 'ring', 'distal_length_mm',   toMm(v, u)],
    finger_ring_circumference: (v, u) => ['digits', 'ring', 'circumference_mm',  toMm(v, u)],
    // pinky segments
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
    // Special handling for legacy circumferences array
    if (last === 'circumferences_mm') {
        if (!Array.isArray(cur[last])) cur[last] = [];
        cur[last].push(value);
    } else {
        cur[last] = value;
    }
}

function r1(x) { return Math.round(x * 10) / 10; }
function r3(x) { return Math.round(x * 1000) / 1000; }

function emptyMeasurements() {
    return {
        palm: {},
        digits: { thumb: {}, index: {}, middle: {}, ring: {}, pinky: {} },
        wrist: {},
        residual_limb: {},
    };
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
        for (const d of ['thumb', 'index', 'middle', 'ring', 'pinky']) {
            if (src.digits[d]) Object.assign(measurements.digits[d], src.digits[d]);
        }
    }

    return measurements;
}

// ── Validation ────────────────────────────────────────────────────────────────

function validateMeasurements(measurements) {
    const outliers = [];
    const errors   = [];

    // Range checks
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

    // Cross-field: palm thickness should not exceed palm width
    const palmThick = getDeep(measurements, 'palm.thickness_mm');
    if (palmThick && palmWid && palmThick > palmWid * 0.6) {
        outliers.push({ field: 'palm.thickness_mm', value: palmThick, range: [0, palmWid * 0.6],
            note: 'Palm thickness unexpectedly large relative to palm width' });
    }

    // Cross-field: residual distal circumference ≤ proximal
    const circProx = getDeep(measurements, 'residual_limb.circumference_proximal_mm');
    const circDist = getDeep(measurements, 'residual_limb.circumference_distal_mm');
    if (circProx && circDist && circDist > circProx * 1.05) {
        outliers.push({ field: 'residual_limb.circumference_distal_mm', value: circDist,
            range: [0, circProx],
            note: 'Distal residual circumference larger than proximal — check measurement orientation' });
    }

    // Cross-field: finger total vs segment sum (when both provided)
    for (const digit of ['index', 'middle', 'ring', 'pinky']) {
        const seg = measurements.digits?.[digit] || {};
        const total = seg.total_length_mm;
        const segSum = (seg.proximal_length_mm || 0) + (seg.middle_length_mm || 0) + (seg.distal_length_mm || 0);
        if (total && segSum > 0) {
            const diff = Math.abs(total - segSum) / total;
            if (diff > 0.08) {  // >8% discrepancy
                outliers.push({ field: `digits.${digit}.total_length_mm`, value: total,
                    range: [segSum * 0.92, segSum * 1.08],
                    note: `Total length differs from segment sum (${r1(segSum)} mm) by ${Math.round(diff * 100)}%` });
            }
        }
    }

    return { outliers, errors };
}

// ── Missing field detection ───────────────────────────────────────────────────

function detectMissing(measurements) {
    const missing = [];

    // Standard scalar fields
    const scalarFields = [
        'palm.width_mm', 'palm.length_mm', 'palm.thickness_mm',
        'wrist.circumference_mm', 'residual_limb.length_mm',
    ];
    for (const f of scalarFields) {
        const val = getDeep(measurements, f);
        if (val === undefined || val === null) missing.push(f);
    }

    // Residual circumference — accept either new dedicated field or legacy array
    const circProx = getDeep(measurements, 'residual_limb.circumference_proximal_mm');
    const circArr  = getDeep(measurements, 'residual_limb.circumferences_mm');
    const hasResidualCirc = circProx || (Array.isArray(circArr) && circArr.length > 0);
    if (!hasResidualCirc) missing.push('residual_limb.circumference_proximal_mm');

    // Finger lengths — accept either total OR individual segments
    for (const digit of ['index', 'middle', 'ring', 'pinky']) {
        const seg = measurements.digits?.[digit] || {};
        const hasTotal    = !!seg.total_length_mm;
        const hasSegments = !!(seg.proximal_length_mm || seg.middle_length_mm || seg.distal_length_mm);
        if (!hasTotal && !hasSegments) {
            missing.push(`digits.${digit}.length`);
        } else if (!hasTotal && hasSegments) {
            // segments provided but not total — check at least proximal
            if (!seg.proximal_length_mm) missing.push(`digits.${digit}.proximal_length_mm`);
        }
    }

    return missing;
}

// ── Derived value computation ─────────────────────────────────────────────────
//
// Hierarchy:
//   primaries → derived geometry → functional → manufacturing
//
// Proportional formulas used:
//   global_scale              = palm_length / REF.palm_length_mm
//   proximal_phalanx_length   = 0.45 × finger_total   (or direct measurement)
//   middle_phalanx_length     = 0.31 × finger_total
//   distal_phalanx_length     = 0.24 × finger_total
//   palm_structural_thickness = 0.35 × palm_thickness  (or 0.077 × palm_width fallback)
//   finger_base_width         = average_finger_width   (or palm_width / 5)
//   internal_channel_diameter = clamp(0.25 × finger_base_width, 2, 4)
//   socket_inner_diam         = circumference / π
//   socket_depth              = 0.60 × residual_length
//   taper_angle               = atan2((diam_prox - diam_dist)/2, socket_depth)
//   socket_rim_thickness      = max(2.5, diam_prox × 0.08)
//   distal_cap_thickness      = max(2.0, diam_dist × 0.07)

function computeDerived(measurements, constraints) {
    const derived = {};

    // ── 1. Global scale ───────────────────────────────────────────────────────
    const palmLen = getDeep(measurements, 'palm.length_mm');
    derived.global_scale = palmLen
        ? r3(palmLen / REF.palm_length_mm)
        : 1.0;

    // ── 2. Per-digit finger total lengths and scale ratios ────────────────────
    const DIGIT_REF = {
        thumb:  REF.digit_thumb_total,
        index:  REF.digit_index_total,
        middle: REF.digit_middle_total,
        ring:   REF.digit_ring_total,
        pinky:  REF.digit_pinky_total,
    };
    derived.finger_scale_ratios = {};
    for (const [d, ref] of Object.entries(DIGIT_REF)) {
        const seg = measurements.digits?.[d] || {};
        const segSum = (seg.proximal_length_mm || 0) + (seg.middle_length_mm || 0) + (seg.distal_length_mm || 0);
        const total  = seg.total_length_mm || (segSum > 0 ? segSum : 0);
        if (total > 0) derived.finger_scale_ratios[d] = r3(total / ref);
    }

    // ── 3. Phalanx segment derivation from totals ─────────────────────────────
    // When only total length is provided, decompose into segments via anatomical ratios.
    // When segments are provided directly, use them as-is.
    derived.phalanx_segments = {};

    for (const digit of ['index', 'middle', 'ring', 'pinky']) {
        const seg = measurements.digits?.[digit] || {};
        const hasSegments = !!(seg.proximal_length_mm || seg.middle_length_mm || seg.distal_length_mm);

        if (hasSegments) {
            derived.phalanx_segments[digit] = {
                proximal_length_mm: seg.proximal_length_mm || 0,
                middle_length_mm:   seg.middle_length_mm   || 0,
                distal_length_mm:   seg.distal_length_mm   || 0,
                source: 'measured',
            };
        } else if (seg.total_length_mm) {
            const t = seg.total_length_mm;
            derived.phalanx_segments[digit] = {
                proximal_length_mm: r1(t * PHALANX_RATIOS.proximal),
                middle_length_mm:   r1(t * PHALANX_RATIOS.middle),
                distal_length_mm:   r1(t * PHALANX_RATIOS.distal),
                source: 'derived_from_total',
            };
        }
    }

    // Thumb (2-phalanx)
    const thumbSeg = measurements.digits?.thumb || {};
    if (thumbSeg.proximal_length_mm || thumbSeg.distal_length_mm) {
        derived.phalanx_segments.thumb = {
            proximal_length_mm: thumbSeg.proximal_length_mm || 0,
            distal_length_mm:   thumbSeg.distal_length_mm   || 0,
            source: 'measured',
        };
    } else if (thumbSeg.total_length_mm) {
        const t = thumbSeg.total_length_mm;
        derived.phalanx_segments.thumb = {
            proximal_length_mm: r1(t * PHALANX_RATIOS.thumb_proximal),
            distal_length_mm:   r1(t * PHALANX_RATIOS.thumb_distal),
            source: 'derived_from_total',
        };
    }

    // ── 4. Representative phalanx lengths (from index finger) ─────────────────
    // Used as single-value parameters for models that treat all fingers equally.
    const idxDirect = measurements.digits?.index || {};
    const idxDeriv  = derived.phalanx_segments.index || {};

    derived.proximal_phalanx_length =
        idxDirect.proximal_length_mm ||
        idxDeriv.proximal_length_mm  ||
        (palmLen ? r1(palmLen * 0.38) : null);

    derived.middle_phalanx_length =
        idxDirect.middle_length_mm ||
        idxDeriv.middle_length_mm  ||
        (derived.proximal_phalanx_length ? r1(derived.proximal_phalanx_length * 0.69) : null);

    derived.distal_phalanx_length =
        idxDirect.distal_length_mm ||
        idxDeriv.distal_length_mm  ||
        (derived.proximal_phalanx_length ? r1(derived.proximal_phalanx_length * 0.53) : null);

    // ── 5. Joint positions (cumulative from MCP joint, index finger) ──────────
    if (derived.proximal_phalanx_length) {
        derived.joint_positions = {
            // PIP = proximal interphalangeal (after proximal phalanx)
            pip_mm: r1(derived.proximal_phalanx_length),
            // DIP = distal interphalangeal (after middle phalanx)
            dip_mm: derived.middle_phalanx_length
                ? r1(derived.proximal_phalanx_length + derived.middle_phalanx_length)
                : null,
            // Fingertip
            tip_mm: (derived.middle_phalanx_length && derived.distal_phalanx_length)
                ? r1(derived.proximal_phalanx_length + derived.middle_phalanx_length + derived.distal_phalanx_length)
                : null,
        };
    }

    // joint_spacing_mm: legacy scalar (backwards compat)
    const idxProx = idxDirect.proximal_length_mm || idxDeriv.proximal_length_mm;
    if (idxProx) derived.joint_spacing_mm = r1(idxProx * 0.85);

    // ── 6. Palm structural thickness ──────────────────────────────────────────
    const palmThick = getDeep(measurements, 'palm.thickness_mm');
    const palmWid   = getDeep(measurements, 'palm.width_mm');
    if (palmThick) {
        // Shell wall = 35% of external thickness
        derived.palm_structural_thickness = r1(palmThick * 0.35);
    } else if (palmWid) {
        // Fallback: ~7.7% of palm width ≈ 6.5 mm for 85mm palm
        derived.palm_structural_thickness = r1(palmWid * 0.077);
    }

    // ── 7. Finger base width ──────────────────────────────────────────────────
    const avgFW = getDeep(measurements, 'palm.average_finger_width_mm');
    if (avgFW) {
        derived.finger_base_width = r1(avgFW);
    } else if (palmWid) {
        derived.finger_base_width = r1(palmWid / 5);
    }

    // ── 8. Internal channel diameter (tendon / cable routing) ─────────────────
    if (derived.finger_base_width) {
        const raw = derived.finger_base_width * 0.25;
        derived.internal_channel_diameter = r1(Math.min(Math.max(raw, 2.0), 4.0));
    }

    // ── 9. Residual limb geometry ─────────────────────────────────────────────
    // Prefer new dedicated fields; fall back to legacy circumferences array.
    const circProx = getDeep(measurements, 'residual_limb.circumference_proximal_mm') ||
        (() => { const c = getDeep(measurements, 'residual_limb.circumferences_mm'); return Array.isArray(c) ? c[0] : undefined; })();
    const circDist = getDeep(measurements, 'residual_limb.circumference_distal_mm') ||
        (() => { const c = getDeep(measurements, 'residual_limb.circumferences_mm'); return Array.isArray(c) ? c[1] : undefined; })();
    const residLen = getDeep(measurements, 'residual_limb.length_mm');

    // ── 10. Local reinforcement zones ─────────────────────────────────────────
    if (circProx) {
        const diamProx = circProx / Math.PI;
        const diamDist = circDist ? circDist / Math.PI : diamProx;

        derived.local_reinforcement_zones = {
            // Socket rim needs enough material to resist pull-off forces
            socket_rim_thickness: r1(Math.max(2.5, diamProx * 0.08)),
            // Distal end cap
            distal_cap_thickness: r1(Math.max(2.0, diamDist * 0.07)),
            // Rim always reinforced; mid-zone if significant taper
            rim_zone: true,
            mid_zone: !!(circDist && Math.abs(circProx - circDist) > 20),
        };

        if (circDist && residLen && residLen > 0) {
            const taper = (diamProx - diamDist) / (2 * residLen);
            derived.local_reinforcement_zones.taper_mm_per_mm = r3(taper);
        }
    }

    // ── 11. Socket internal geometry ──────────────────────────────────────────
    if (circProx) {
        const diamProx = r1(circProx / Math.PI);
        const diamDist = circDist ? r1(circDist / Math.PI) : diamProx;
        const sockDepth = residLen ? r1(residLen * 0.60) : null;

        derived.socket_internal_geometry = {
            inner_diameter_proximal_mm: diamProx,
            inner_diameter_distal_mm:   diamDist,
            socket_depth_mm:            sockDepth,
            taper_angle_deg: sockDepth
                ? r1(Math.atan2((diamProx - diamDist) / 2, sockDepth) * (180 / Math.PI))
                : null,
        };

        // scalar backwards compat
        derived.socket_inner_diameter_mm = diamProx;
    }

    // ── 12. Wrist diameter (backwards compat) ─────────────────────────────────
    const wristCirc = getDeep(measurements, 'wrist.circumference_mm');
    if (wristCirc) derived.wrist_diameter_mm = r1(wristCirc / Math.PI);

    return derived;
}

// ── Geometry parameter vector ─────────────────────────────────────────────────
// Flat numeric map consumed by the configurator and AI suggestion engine.

function buildGeometryParameters(measurements, derived, constraints) {
    const hw  = HARDWARE[constraints?.hardware_standard]  || HARDWARE.m3;
    const tol = TOLERANCE[constraints?.tolerance_preference] || TOLERANCE.standard;

    const params = {
        // Layer 4: manufacturing / constraint
        global_scale:      derived.global_scale ?? 1.0,
        clearance_mm:      tol,
        pivot_diameter_mm: hw.pivot_diameter_mm,
    };

    // Layer 3: functional — per-digit total lengths
    for (const d of ['index', 'middle', 'ring', 'pinky']) {
        const seg = measurements.digits?.[d] || {};
        const segSum = (seg.proximal_length_mm || 0) + (seg.middle_length_mm || 0) + (seg.distal_length_mm || 0);
        const derivedSegs = derived.phalanx_segments?.[d] || {};
        const derivedSum  = (derivedSegs.proximal_length_mm || 0) + (derivedSegs.middle_length_mm || 0) + (derivedSegs.distal_length_mm || 0);
        const total = seg.total_length_mm || (segSum > 0 ? segSum : derivedSum) || 0;
        if (total > 0) params[`finger_length_${d}`] = r1(total);
    }

    // Thumb total
    const thumbSeg = measurements.digits?.thumb || {};
    const thumbDeriv = derived.phalanx_segments?.thumb || {};
    const thumbTotal = thumbSeg.total_length_mm ||
        ((thumbSeg.proximal_length_mm || 0) + (thumbSeg.distal_length_mm || 0)) ||
        ((thumbDeriv.proximal_length_mm || 0) + (thumbDeriv.distal_length_mm || 0));
    if (thumbTotal > 0) params.finger_length_thumb = r1(thumbTotal);

    // Layer 2: derived geometry — phalanx lengths (index finger as representative)
    if (derived.proximal_phalanx_length) params.proximal_phalanx_length = derived.proximal_phalanx_length;
    if (derived.middle_phalanx_length)   params.middle_phalanx_length   = derived.middle_phalanx_length;
    if (derived.distal_phalanx_length)   params.distal_phalanx_length   = derived.distal_phalanx_length;

    // Joint positions
    if (derived.joint_positions) {
        if (derived.joint_positions.pip_mm) params.joint_pos_pip_mm = derived.joint_positions.pip_mm;
        if (derived.joint_positions.dip_mm) params.joint_pos_dip_mm = derived.joint_positions.dip_mm;
    }

    // Palm structural parameters
    if (derived.palm_structural_thickness != null) params.palm_structural_thickness = derived.palm_structural_thickness;
    if (derived.finger_base_width   != null)       params.finger_base_width         = derived.finger_base_width;
    if (derived.internal_channel_diameter != null) params.internal_channel_diameter = derived.internal_channel_diameter;

    // Socket / residual limb geometry
    if (derived.socket_inner_diameter_mm != null) params.socket_inner_diameter_mm = derived.socket_inner_diameter_mm;
    const sg = derived.socket_internal_geometry;
    if (sg) {
        if (sg.inner_diameter_proximal_mm != null) params.socket_diameter_proximal_mm = sg.inner_diameter_proximal_mm;
        if (sg.inner_diameter_distal_mm   != null) params.socket_diameter_distal_mm   = sg.inner_diameter_distal_mm;
        if (sg.socket_depth_mm            != null) params.socket_depth_mm             = sg.socket_depth_mm;
        if (sg.taper_angle_deg            != null) params.socket_taper_angle_deg      = sg.taper_angle_deg;
    }
    const lrz = derived.local_reinforcement_zones;
    if (lrz?.socket_rim_thickness != null) params.socket_rim_thickness_mm  = lrz.socket_rim_thickness;
    if (lrz?.distal_cap_thickness  != null) params.socket_distal_cap_thickness_mm = lrz.distal_cap_thickness;

    // Legacy scalars
    if (derived.joint_spacing_mm   != null) params.joint_spacing_mm   = derived.joint_spacing_mm;
    if (derived.wrist_diameter_mm  != null) params.wrist_diameter_mm  = derived.wrist_diameter_mm;

    // Palm wall (alias for palm_structural_thickness, matches cyborgbeast 'th' concept)
    if (derived.palm_structural_thickness != null) params.palm_wall_thickness_mm = derived.palm_structural_thickness;

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

    // Note which phalanx segments were derived vs measured
    for (const [d, segs] of Object.entries(derived.phalanx_segments || {})) {
        if (segs.source === 'derived_from_total') {
            notes.push(`${d} phalanx segments estimated from total length using anatomical ratios`);
        }
    }

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
