'use strict';

/**
 * scadParser — extract Customizer parameters from an OpenSCAD source so the
 * admin "Models" tab can pre-fill a model definition.
 *
 * Follows OpenSCAD's Customizer conventions:
 *   /* [Group] *\/                  → group heading ([Hidden] hides what follows)
 *   // Description                  → caption for the next assignment
 *   x = 83;       // [55:1:110]     → number slider (min:step:max, min:max or max)
 *   s = "a";      // [a, b, c]      → dropdown; "val:Label" pairs are allowed
 *   flag = true;                    → checkbox
 *   c = "#ff0000";                  → colour picker
 * Only top-level literal assignments before the first module/function count —
 * the same scope the Customizer shows. Expressions and vectors are reported as
 * skipped rather than guessed.
 */

const { PARAM_TO_MEASUREMENT_PATH } = require('./profileMapping');

// Canonical anthropometric inputs (CLAUDE.md "Anthropometric Parameter Alignment").
const CANONICAL_PARAMS = new Set([...Object.keys(PARAM_TO_MEASUREMENT_PATH), 'gauntlet_width_mm']);
const ANATOMY_HINT = /(palm|finger|thumb|wrist|hand|forearm|index|middle|ring|pinky|little)/i;
const LATERALITY_HINT = /^(mirror|mirrored|is_left|is_right|left_hand|right_hand|left|right|handedness|side|hand_side)$/i;

const NUM_RE = /^[-+]?(\d+\.?\d*|\.\d+)(e[-+]?\d+)?$/i;
const HEX_COLOR_RE = /^#([0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i;

function parseLiteral(raw) {
    const s = raw.trim();
    if (NUM_RE.test(s)) return { ok: true, value: Number(s) };
    if (s === 'true' || s === 'false') return { ok: true, value: s === 'true' };
    const m = s.match(/^"((?:[^"\\]|\\.)*)"$/);
    if (m) return { ok: true, value: m[1].replace(/\\(.)/g, '$1') };
    return { ok: false };
}

function decimals(n) {
    const s = String(n);
    const i = s.indexOf('.');
    return i < 0 ? 0 : s.length - i - 1;
}

// "[55:1:110]" / "[a, b:Label]" → { range } | { options } | null
function parseAnnotation(text) {
    const m = text.match(/^\[(.*)\]$/);
    if (!m) return null;
    const inner = m[1].trim();
    if (!inner) return null;
    if (inner.includes(',')) {
        const options = inner.split(',').map(part => {
            const p = part.trim();
            const ci = p.indexOf(':');
            const rawVal = ci >= 0 ? p.slice(0, ci).trim() : p;
            const label = ci >= 0 ? p.slice(ci + 1).trim() : p;
            const value = NUM_RE.test(rawVal) ? Number(rawVal)
                : (rawVal === 'true' || rawVal === 'false') ? rawVal === 'true'
                : rawVal.replace(/^"|"$/g, '');
            return { label: String(label).replace(/^"|"$/g, ''), value };
        }).filter(o => o.label !== '' || o.value !== '');
        return options.length ? { options } : null;
    }
    const nums = inner.split(':').map(x => x.trim());
    if (nums.every(x => NUM_RE.test(x))) {
        const v = nums.map(Number);
        if (v.length === 1) return { range: { min: 0, max: v[0] } };
        if (v.length === 2) return { range: { min: v[0], max: v[1] } };
        if (v.length === 3) return { range: { min: v[0], step: v[1], max: v[2] } };
    }
    // Single value without comma: a one-option dropdown is meaningless; treat
    // "[a:Label]" as one option so the admin still sees it.
    if (nums.length === 2) return { options: [{ value: NUM_RE.test(nums[0]) ? Number(nums[0]) : nums[0], label: nums[1] }] };
    return null;
}

// Remove // and /* */ comments plus string contents so brace counting and
// module detection aren't fooled by text inside them.
function codeOnly(line, state) {
    let out = '';
    for (let i = 0; i < line.length; i++) {
        const c = line[i], n = line[i + 1];
        if (state.inBlock) {
            if (c === '*' && n === '/') { state.inBlock = false; i++; }
            continue;
        }
        if (state.inString) {
            if (c === '\\') { i++; continue; }
            if (c === '"') state.inString = false;
            continue;
        }
        if (c === '/' && n === '/') break;
        if (c === '/' && n === '*') { state.inBlock = true; i++; continue; }
        if (c === '"') { state.inString = true; continue; }
        out += c;
    }
    return out;
}

function parseScadParameters(source) {
    const lines = String(source || '').replace(/\r\n?/g, '\n').split('\n');
    const parameters = [];
    const skipped = [];
    const warnings = [];
    const seen = new Set();
    const state = { inBlock: false, inString: false };
    let depth = 0;
    let group = null;
    let hidden = false;
    let pendingCaption = null;

    for (const line of lines) {
        const trimmed = line.trim();
        const wasInBlock = state.inBlock;

        // Customizer group marker: /* [Name] */
        const g = !wasInBlock && depth === 0 && trimmed.match(/^\/\*\s*\[([^\]]+)\]\s*\*\/$/);
        if (g) {
            const name = g[1].trim();
            hidden = /^hidden$/i.test(name);
            group = /^global$/i.test(name) ? null : name;
            pendingCaption = null;
            continue;
        }

        const code = codeOnly(line, state);

        if (!wasInBlock && depth === 0) {
            if (/^\s*(module|function)\b/.test(code)) break;   // Customizer scope ends here

            // Consecutive // lines form one caption for the next assignment.
            const lc = trimmed.match(/^\/\/\s?(.*)$/);
            if (lc) {
                const text = lc[1].trim();
                // Decorative rules (//////, ----, vvvv) break a caption like a blank line.
                if (!text || !/[A-Za-z0-9]/.test(text) || /^(.)\1{5,}$/.test(text)) pendingCaption = null;
                else pendingCaption = pendingCaption ? pendingCaption + ' ' + text : text;
                continue;
            }

            const a = line.match(/^\s*([A-Za-z_$][\w$]*)\s*=(?!=)\s*(.*?)\s*;\s*(?:\/\/\s*(.*?))?\s*$/);
            if (a) {
                const [, name, rawValue, trailing] = a;
                const caption = pendingCaption;
                pendingCaption = null;
                if (name.startsWith('$')) continue;          // $fn etc. are render settings
                if (hidden) continue;
                if (seen.has(name)) continue;                 // first declaration wins
                const lit = parseLiteral(rawValue);
                if (!lit.ok) {
                    skipped.push({ name, reason: rawValue.startsWith('[') ? 'vector' : 'expression' });
                    continue;
                }
                seen.add(name);
                const ann = trailing ? parseAnnotation(trailing) : null;
                const param = { name };
                const v = lit.value;

                if (ann && ann.options) {
                    param.type = 'enum';
                    param.initial = v;
                    param.options = ann.options;
                    if (!ann.options.some(o => o.value === v)) param.options.unshift({ label: String(v), value: v });
                } else if (typeof v === 'boolean') {
                    param.type = 'boolean';
                    param.initial = v;
                } else if (typeof v === 'number') {
                    param.type = 'number';
                    param.initial = v;
                    if (ann && ann.range) {
                        Object.assign(param, ann.range);
                        if (param.step === undefined) param.step = Math.max(decimals(param.min), decimals(param.max), decimals(v)) > 0 ? 0.1 : 1;
                    } else {
                        // No range annotation — propose one and flag it for review.
                        const step = decimals(v) > 0 ? Math.pow(10, -Math.min(decimals(v), 3)) : 1;
                        const span = Math.max(Math.abs(v), 10);
                        param.min = v >= 0 ? 0 : Number((v - span * 2).toFixed(3));
                        param.max = Number((v + span * 2).toFixed(3));
                        param.step = step;
                        warnings.push({ name, code: 'inferred_range' });
                    }
                } else if (HEX_COLOR_RE.test(v)) {
                    param.type = 'color';
                    param.initial = v;
                } else {
                    param.type = 'string';
                    param.initial = v;
                }

                if (group) param.group = group;
                const cap = caption || (trailing && !ann ? trailing : null);
                if (cap) param.caption = cap.length > 500 ? cap.slice(0, 497) + '…' : cap;
                if (LATERALITY_HINT.test(name) && (param.type === 'boolean' || param.type === 'enum')) {
                    warnings.push({ name, code: 'laterality_candidate' });
                }
                if (/_mm$/.test(name) && ANATOMY_HINT.test(name) && !CANONICAL_PARAMS.has(name)) {
                    warnings.push({ name, code: 'non_canonical' });
                }
                parameters.push(param);
                continue;
            }
            pendingCaption = null;   // blank line or other code: caption must sit directly above
        }

        for (const c of code) {
            if (c === '{') depth++;
            else if (c === '}') depth = Math.max(0, depth - 1);
        }
    }

    return { parameters, skipped, warnings };
}

module.exports = { parseScadParameters, CANONICAL_PARAMS };
