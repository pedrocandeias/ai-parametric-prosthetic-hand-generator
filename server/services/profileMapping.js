'use strict';

/**
 * profileMapping — bridge between stored anthropometric profiles and live
 * parametric models.
 *
 * Background: the importer's `geometry_parameters` are built for the
 * Kwawu/cyborgbeast socket-and-phalanx design and use names (e.g.
 * `finger_length_index`) that do NOT match the canonical model inputs. The
 * clean, model-agnostic source is the normalized `profile.measurements` tree,
 * whose anatomical paths line up 1:1 with the canonical parameter names
 * documented in CLAUDE.md ("Anthropometric Parameter Alignment").
 *
 * This module is the single source of truth for that translation; it is used
 * by both the configurator "apply baseline" endpoint and the AI grounding path.
 */

// Canonical model-parameter name → path inside profile.measurements.
// Matches the "Platform source" column in CLAUDE.md exactly.
const PARAM_TO_MEASUREMENT_PATH = {
    palm_breadth_mm:         'palm.width_mm',
    palm_length_mm:          'palm.length_mm',
    palm_thickness_mm:       'palm.thickness_mm',
    index_finger_length_mm:  'digits.index.total_length_mm',
    middle_finger_length_mm: 'digits.middle.total_length_mm',
    ring_finger_length_mm:   'digits.ring.total_length_mm',
    pinky_finger_length_mm:  'digits.pinky.total_length_mm',
    thumb_length_mm:         'digits.thumb.total_length_mm',
};

function getDeep(obj, dottedPath) {
    return dottedPath.split('.').reduce(
        (acc, key) => (acc == null ? undefined : acc[key]),
        obj,
    );
}

function round1(n) {
    return Math.round(n * 10) / 10;
}

/**
 * Map a stored profile onto a model's parameters.
 *
 * Only parameters that (a) exist on the model, (b) are numeric, (c) are in the
 * canonical map, and (d) have a finite measurement in the profile are applied.
 * Values are clamped to each parameter's declared min/max. Non-anatomical
 * parameters (hardware, visibility, mirrored, …) are never touched.
 *
 * @param {object} profile   parsed `profile` JSON ({ measurements, ... })
 * @param {object} modelDef  a model entry from models-config.json
 * @returns {{ parameters: object, applied: string[], skipped: string[], clamped: object[] }}
 */
function mapProfileToModelParameters(profile, modelDef) {
    const measurements = profile?.measurements || {};
    const parameters = {};
    const applied = [];
    const skipped = [];
    const clamped = [];

    const paramDefs = Array.isArray(modelDef?.parameters) ? modelDef.parameters : [];

    for (const def of paramDefs) {
        const path = PARAM_TO_MEASUREMENT_PATH[def.name];
        if (!path || def.type !== 'number') continue;

        const raw = getDeep(measurements, path);
        if (raw == null || !Number.isFinite(Number(raw)) || Number(raw) <= 0) {
            skipped.push(def.name);
            continue;
        }

        let value = round1(Number(raw));
        if (typeof def.min === 'number' && value < def.min) {
            clamped.push({ name: def.name, from: value, to: def.min });
            value = def.min;
        } else if (typeof def.max === 'number' && value > def.max) {
            clamped.push({ name: def.name, from: value, to: def.max });
            value = def.max;
        }

        parameters[def.name] = value;
        applied.push(def.name);
    }

    return { parameters, applied, skipped, clamped };
}

// ── AI grounding ───────────────────────────────────────────────────────────

const GENDER_TOKENS = {
    male:   ['man', 'male', 'boy', 'gentleman', 'm,', ' m '],
    female: ['woman', 'female', 'girl', 'lady', 'f,', ' f '],
};

const AGE_TOKENS = {
    child:   ['child', 'kid', 'boy', 'girl', 'toddler', 'infant'],
    elderly: ['elderly', 'senior', 'old', 'aged', 'geriatric'],
};

function normGender(text) {
    const t = ` ${text.toLowerCase()} `;
    if (GENDER_TOKENS.female.some(k => t.includes(k))) return 'female';
    if (GENDER_TOKENS.male.some(k => t.includes(k)))   return 'male';
    return null;
}

/** Pull the first plausible age (years) from free text, if any. */
function extractAge(text) {
    const m = text.match(/(\d{1,2})\s*(?:years?|yrs?|yo|year-old|y\/o)\b/i) ||
              text.match(/\bage[d]?\s*[:=]?\s*(\d{1,2})\b/i);
    return m ? parseInt(m[1], 10) : null;
}

function ageGroupFromYears(age) {
    if (age == null) return null;
    if (age < 16) return 'child';
    if (age >= 65) return 'elderly';
    return 'adult';
}

/**
 * Heuristically pick the population profile that best matches a free-text
 * patient description. Scores on gender, country (substring of group_name or
 * country column), and age group. Returns null when nothing scores.
 *
 * @param {string} text       free-text patient description
 * @param {object[]} profiles rows with { id, group_name, country, gender, age_group }
 * @returns {object|null} the best-matching row, or null
 */
function findBestProfileMatch(text, profiles) {
    if (!text || !Array.isArray(profiles) || profiles.length === 0) return null;

    const lower = text.toLowerCase();
    const wantGender = normGender(text);
    const wantAgeGroup = ageGroupFromYears(extractAge(text)) ||
        (AGE_TOKENS.child.some(k => lower.includes(k)) ? 'child'
            : AGE_TOKENS.elderly.some(k => lower.includes(k)) ? 'elderly' : null);

    let best = null;
    let bestScore = 0;

    for (const p of profiles) {
        let score = 0;

        if (wantGender && p.gender) {
            if (p.gender === wantGender) score += 3;
            else if (p.gender !== 'mixed' && p.gender !== 'other') score -= 2;
        }

        const country = (p.country || '').toLowerCase().trim();
        if (country && country !== 'global' && lower.includes(country)) score += 3;

        if (wantAgeGroup && p.age_group) {
            const ag = p.age_group.toLowerCase();
            if (ag.includes(wantAgeGroup)) score += 2;
            else if (wantAgeGroup === 'adult' && (ag.includes('young') || ag.includes('18'))) score += 1;
        }

        // Mild preference for 50th-percentile / mean groups when otherwise tied.
        const gn = (p.group_name || '').toLowerCase();
        if (gn.includes('50th') || gn.includes('mean') || gn.includes('median')) score += 0.5;

        if (score > bestScore) { bestScore = score; best = p; }
    }

    return bestScore >= 3 ? best : null;
}

/**
 * Build a prompt grounding block from a matched profile and its derived params.
 *
 * @param {object} match    the matched profile row (for labelling)
 * @param {object} mapped   result of mapProfileToModelParameters()
 * @param {object} aiContext parsed `ai_context` JSON (uncertainty/notes)
 * @returns {string} text to append to the AI prompt, or '' if nothing usable
 */
function buildGroundingBlock(match, mapped, aiContext) {
    if (!mapped || mapped.applied.length === 0) return '';

    const lines = mapped.applied.map(name => `  ${name}: ${mapped.parameters[name]} mm`);
    const sample = match.sample_size ? `, n=${match.sample_size}` : '';
    const uncertainty = aiContext?.uncertainty ? ` (dataset completeness: ${aiContext.uncertainty})` : '';

    return [
        '',
        'Reference population data — the closest matching group in our anthropometric',
        `dataset is "${match.group_name}"${sample}${uncertainty}. Its measured mean values are:`,
        ...lines,
        'Anchor your estimate on these measured means, adjusting for the patient\'s specific',
        'description (build, height, stated measurements). Supplied patient measurements always',
        'take precedence over these population means.',
    ].join('\n');
}

module.exports = {
    PARAM_TO_MEASUREMENT_PATH,
    getDeep,
    mapProfileToModelParameters,
    findBestProfileMatch,
    buildGroundingBlock,
};
