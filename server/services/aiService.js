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

async function callAnthropic(promptText) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) throw Object.assign(new Error('ANTHROPIC_API_KEY not configured'), { status: 503 });

    const data = await httpsPost(
        'https://api.anthropic.com/v1/messages',
        { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
        {
            model: 'claude-3-5-sonnet-20241022',
            max_tokens: 1024,
            messages: [{ role: 'user', content: promptText }],
        }
    );
    return data.content[0].text;
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

module.exports = { callAnthropic, callOpenAI };
