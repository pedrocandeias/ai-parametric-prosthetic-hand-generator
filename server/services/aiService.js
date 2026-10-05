'use strict';

const https = require('https');

function httpsPost(url, headers, body) {
    return new Promise((resolve, reject) => {
        const bodyStr = JSON.stringify(body);
        const parsed = new URL(url);
        const options = {
            hostname: parsed.hostname,
            path: parsed.pathname + parsed.search,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(bodyStr),
                ...headers,
            },
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => { data += chunk; });
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    if (res.statusCode >= 400) {
                        const msg = json.error?.message || JSON.stringify(json);
                        reject(Object.assign(new Error(`API error ${res.statusCode}: ${msg}`), { status: res.statusCode }));
                    } else {
                        resolve(json);
                    }
                } catch {
                    reject(new Error('Invalid JSON response from AI provider'));
                }
            });
        });

        req.on('error', reject);
        req.write(bodyStr);
        req.end();
    });
}

const ANTHROPIC_MODEL = process.env.ANTHROPIC_MODEL || 'claude-sonnet-5';

async function callAnthropicModel(promptText, { model = ANTHROPIC_MODEL, maxTokens = 1024, temperature, effort } = {}) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) throw Object.assign(new Error('ANTHROPIC_API_KEY not configured'), { status: 503 });

    const body = {
        model,
        max_tokens: maxTokens,
        messages: [{ role: 'user', content: promptText }],
    };
    // Sonnet 5+ rejects temperature and thinks by default (effort controls depth);
    // Haiku 4.5 still takes temperature and no effort.
    if (typeof temperature === 'number') body.temperature = temperature;
    if (effort) body.output_config = { effort };

    const data = await httpsPost(
        'https://api.anthropic.com/v1/messages',
        { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
        body
    );
    // With thinking on, content[0] is a thinking block — take the text block.
    const textBlock = (data.content || []).find(b => b.type === 'text');
    if (!textBlock) {
        throw Object.assign(new Error(`AI provider returned no text (stop_reason: ${data.stop_reason})`), { status: 502 });
    }
    return textBlock.text;
}

async function callAnthropic(promptText) {
    // max_tokens also covers thinking tokens, so leave headroom over the ~1K answer.
    return callAnthropicModel(promptText, { maxTokens: 8000, effort: 'low' });
}

/**
 * Best-effort structured extraction of patient attributes from a free-text
 * description, used to anchor population-profile grounding (see profileMapping).
 * Returns { gender, age } or null on any failure — callers must fall back to the
 * deterministic text parser. Uses a small, fast model and a tight token budget.
 *
 * @param {string} text  free-text patient description (any language)
 * @returns {Promise<{gender: ('male'|'female'|null), age: (number|null)}|null>}
 */
async function extractPatientAttributes(text) {
    if (!process.env.ANTHROPIC_API_KEY || !text || !String(text).trim()) return null;
    try {
        const out = await callAnthropicModel(
            'Extract attributes from this prosthetics patient description. Respond with ONLY a ' +
            'JSON object: {"gender": "male" | "female" | null, "age": <integer years> | null}. ' +
            'Infer gender from words in ANY language (e.g. "mulher"/"mujer"=female, "homem"/"hombre"=male; ' +
            'a generic "criança"/"child" with no gender stated is null). Use age only if given in years ' +
            '(e.g. "7 anos", "34 years old"). No prose, no markdown.\n\nDescription: ' + String(text),
            { model: 'claude-haiku-4-5-20251001', maxTokens: 80, temperature: 0 }
        );
        const j = JSON.parse((out.match(/\{[\s\S]*\}/) || [out])[0]);
        const gender = (j.gender === 'male' || j.gender === 'female') ? j.gender : null;
        const ageNum = Number(j.age);
        const age = Number.isFinite(ageNum) && ageNum > 0 && ageNum <= 120 ? Math.round(ageNum) : null;
        return { gender, age };
    } catch {
        return null;
    }
}

async function callOpenAI(promptText) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw Object.assign(new Error('OPENAI_API_KEY not configured'), { status: 503 });

    const data = await httpsPost(
        'https://api.openai.com/v1/chat/completions',
        { Authorization: `Bearer ${apiKey}` },
        {
            model: process.env.OPENAI_MODEL || 'gpt-6.1-sol',
            messages: [{ role: 'user', content: promptText }],
            // Reasoning models: max_completion_tokens (not max_tokens) and it also
            // covers hidden reasoning tokens; custom temperature is not supported.
            max_completion_tokens: 4096,
            reasoning_effort: 'low',
        }
    );
    return data.choices[0].message.content;
}

module.exports = { callAnthropic, callAnthropicModel, callOpenAI, extractPatientAttributes };
