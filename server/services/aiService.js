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

async function callAnthropicModel(promptText, { model = 'claude-sonnet-4-6', maxTokens = 1024, temperature } = {}) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) throw Object.assign(new Error('ANTHROPIC_API_KEY not configured'), { status: 503 });

    const body = {
        model,
        max_tokens: maxTokens,
        messages: [{ role: 'user', content: promptText }],
    };
    if (typeof temperature === 'number') body.temperature = temperature;

    const data = await httpsPost(
        'https://api.anthropic.com/v1/messages',
        { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
        body
    );
    return data.content[0].text;
}

async function callAnthropic(promptText) {
    return callAnthropicModel(promptText, { model: 'claude-sonnet-4-6', maxTokens: 1024 });
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
            model: 'gpt-4',
            messages: [{ role: 'user', content: promptText }],
            max_tokens: 1024,
            temperature: 0.7,
        }
    );
    return data.choices[0].message.content;
}

module.exports = { callAnthropic, callAnthropicModel, callOpenAI, extractPatientAttributes };
