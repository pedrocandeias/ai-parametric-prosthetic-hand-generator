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

// Whole-word gender tokens, matched with \b boundaries (NOT substring) so that
// units like "mm," / "cm," can never be read as the male token "m". Multilingual
// (EN / PT / ES) because patient descriptions arrive in the clinician's language.
const GENDER_WORDS = {
    male:   ['man', 'male', 'boy', 'gentleman', 'homem', 'menino', 'rapaz', 'masculino', 'hombre', 'chico', 'niño', 'nino'],
    female: ['woman', 'female', 'girl', 'lady', 'mulher', 'menina', 'rapariga', 'feminino', 'mujer', 'chica', 'niña', 'nina'],
};

// Whole-word age-category cues (used only when no numeric age is present).
const AGE_WORDS = {
    child:   ['child', 'children', 'kid', 'boy', 'girl', 'toddler', 'infant', 'baby',
              'criança', 'crianca', 'menino', 'menina', 'bebé', 'bebe', 'niño', 'nino', 'niña', 'nina'],
    elderly: ['elderly', 'senior', 'aged', 'geriatric', 'idoso', 'idosa', 'ancião', 'anciao', 'anciano', 'mayor'],
};

function hasWord(lowerText, word) {
    // Unicode-aware word boundary: the token must be flanked by non-letters.
    const w = word.toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return new RegExp(`(^|[^\\p{L}])${w}([^\\p{L}]|$)`, 'u').test(lowerText);
}

function normGender(text) {
    const t = (text || '').toLowerCase();
    if (GENDER_WORDS.female.some(w => hasWord(t, w))) return 'female';
    if (GENDER_WORDS.male.some(w => hasWord(t, w)))   return 'male';
    return null;
}

/** Pull the first plausible age (years) from free text, if any. EN/PT/ES. */
function extractAge(text) {
    const t = String(text || '');
    const m = t.match(/(\d{1,3})\s*(?:years?|yrs?|yo|year-old|y\/o|anos?|años?|anys?)\b/i) ||
              t.match(/\b(?:age[d]?|idade|edad)\s*[:=]?\s*(\d{1,3})\b/i);
    if (!m) return null;
    const age = parseInt(m[1], 10);
    return age > 0 && age <= 120 ? age : null;
}

function ageGroupFromYears(age) {
    if (age == null) return null;
    if (age < 16) return 'child';
    if (age >= 65) return 'elderly';
    return 'adult';
}

/**
 * Reduce a stored `age_group` string to a representative age in years. Handles
 * numeric singletons ("7"), ranges ("18-30", "17–40"), open ranges ("80+",
 * "65+"), and descriptive labels ("Adult (Military, 17–40)"). Returns null when
 * no number can be recovered.
 */
function profileAgeYears(ageGroup) {
    if (ageGroup == null) return null;
    const s = String(ageGroup);
    const nums = (s.match(/\d{1,3}/g) || []).map(Number).filter(n => n > 0 && n <= 120);
    if (nums.length === 0) return null;
    if (/\+/.test(s) && nums.length === 1) return nums[0] + 5; // "65+" → ~70
    if (nums.length === 1) return nums[0];
    return Math.round((Math.min(...nums) + Math.max(...nums)) / 2); // range midpoint
}

/**
 * Heuristically pick the population profile that best matches a free-text
 * patient description. Scores on gender, age category + numeric proximity,
 * country, and dataset quality. Returns null when nothing meaningful matches.
 *
 * @param {string} text       free-text patient description
 * @param {object[]} profiles rows with { id, group_name, country, gender, age_group }
 * @param {object} [hints]    optional structured override { gender, age } —
 *                            e.g. extracted by an LLM. Falls back to text parsing.
 * @returns {object|null} the best-matching row, or null
 */
function findBestProfileMatch(text, profiles, hints = null) {
    if (!Array.isArray(profiles) || profiles.length === 0) return null;
    const lower = (text || '').toLowerCase();

    const wantGender = (hints && hints.gender) || normGender(lower);
    const wantAge = (hints && Number.isFinite(hints.age)) ? hints.age : extractAge(lower);
    const wantAgeGroup = ageGroupFromYears(wantAge) ||
        (AGE_WORDS.child.some(w => hasWord(lower, w)) ? 'child'
            : AGE_WORDS.elderly.some(w => hasWord(lower, w)) ? 'elderly' : null);

    let best = null;
    let bestScore = 0;

    for (const p of profiles) {
        let score = 0;

        // Gender — strong signal. Penalise a clear opposite-gender mismatch.
        if (wantGender && p.gender) {
            if (p.gender === wantGender) score += 3;
            else if (p.gender !== 'mixed' && p.gender !== 'other') score -= 3;
        }

        // Age category match (child / adult / elderly) — strong, discriminative.
        const pAge = profileAgeYears(p.age_group);
        const pAgeGroup = ageGroupFromYears(pAge);
        if (wantAgeGroup && pAgeGroup) {
            if (pAgeGroup === wantAgeGroup) score += 3;
            else score -= 2; // wrong life stage (e.g. adult dataset for a child)
        }

        // Numeric age proximity — disambiguates within a category (e.g. age 7 vs 2).
        if (Number.isFinite(wantAge) && Number.isFinite(pAge)) {
            score += 1.5 * (1 - Math.min(Math.abs(wantAge - pAge), 40) / 40);
        }

        // Country — substring of the patient text.
        const country = (p.country || '').toLowerCase().trim();
        if (country && country !== 'global' && lower.includes(country)) score += 1.5;

        // Dataset-quality preference: representative percentiles and surveys that
        // actually carry full hand measurements (so the grounding block won't be
        // empty). Acts as a tiebreak, not a primary signal.
        const gn = (p.group_name || '').toLowerCase();
        if (gn.includes('50th') || gn.includes('mean') || gn.includes('median')) score += 1;
        if (gn.includes('hand')) score += 1;

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
    // exported for unit tests
    normGender,
    extractAge,
    ageGroupFromYears,
    profileAgeYears,
};
