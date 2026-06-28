'use strict';

const express = require('express');
const path = require('path');
const fs = require('fs');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');
const { callAnthropic, callOpenAI, extractPatientAttributes } = require('../services/aiService');
const { requireAuth } = require('../middleware/auth');
const db = require('../db');
const {
    mapProfileToModelParameters,
    findBestProfileMatch,
    buildGroundingBlock,
    normGender,
    extractAge,
} = require('../services/profileMapping');

const router = express.Router();

// Lazily load models-config.json (for parameter bounds when grounding).
let _modelsConfig = null;
function getModelDef(modelId) {
    if (!modelId) return null;
    if (!_modelsConfig) {
        try {
            const p = path.join(__dirname, '..', '..', 'models', 'models-config.json');
            _modelsConfig = JSON.parse(fs.readFileSync(p, 'utf8'));
        } catch {
            _modelsConfig = { models: [] };
        }
    }
    return _modelsConfig.models.find(m => m.id === modelId) || null;
}

/**
 * If a patient description and model are supplied, find the closest population
 * profile and return a grounding block to anchor the LLM. Best-effort: any
 * failure returns '' so suggestions still work ungrounded.
 */
async function buildGrounding(patientText, modelId) {
    try {
        const modelDef = getModelDef(modelId);
        if (!patientText || !modelDef) return '';

        const candidates = db.prepare(`
            SELECT id, group_name, country, gender, age_group, sample_size
            FROM anthropometric_profiles
        `).all();

        // Resolve the patient's gender/age to anchor the population match. The
        // deterministic parser is reliable and free, so we only spend an LLM call
        // when it leaves a gap (e.g. qualitative descriptions in any language).
        let hints = { gender: normGender(patientText), age: extractAge(patientText) };
        if (!hints.gender || hints.age == null) {
            const llm = await extractPatientAttributes(patientText);
            if (llm) {
                hints = {
                    gender: hints.gender || llm.gender,
                    age: hints.age != null ? hints.age : llm.age,
                };
            }
        }

        const match = findBestProfileMatch(patientText, candidates, hints);
        if (!match) return '';

        const row = db.prepare('SELECT profile, ai_context FROM anthropometric_profiles WHERE id = ?')
            .get(match.id);
        if (!row) return '';

        const profile = JSON.parse(row.profile);
        const aiContext = JSON.parse(row.ai_context);
        const mapped = mapProfileToModelParameters(profile, modelDef);
        return buildGroundingBlock(match, mapped, aiContext);
    } catch {
        return '';
    }
}

// 10 requests per minute per IP (authenticated users only)
const aiLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 30,
    keyGenerator: (req) => String(req.user?.sub ?? req.ip),
    message: { error: 'AI rate limit exceeded, please wait a moment' },
    standardHeaders: true,
    legacyHeaders: false,
});

const SuggestSchema = z.object({
    provider: z.enum(['anthropic', 'openai']).default('anthropic'),
    prompt: z.string().min(1).max(16000),
    // Optional grounding inputs — when present, the server anchors the prompt
    // on the closest matching population profile. Backward compatible.
    patient_text: z.string().max(4000).optional(),
    model_id: z.string().max(100).optional(),
});

// POST /api/ai/suggest
router.post('/suggest', requireAuth, aiLimiter, async (req, res, next) => {
    try {
        const result = SuggestSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { provider, prompt, patient_text, model_id } = result.data;

        // Anchor on dataset means when we can match a population group.
        const grounding = await buildGrounding(patient_text, model_id);
        const finalPrompt = grounding ? `${prompt}\n${grounding}` : prompt;

        let text;
        if (provider === 'anthropic') {
            text = await callAnthropic(finalPrompt);
        } else {
            text = await callOpenAI(finalPrompt);
        }

        res.json({ text, grounded: Boolean(grounding) });
    } catch (err) {
        // Never forward 401/403 from AI providers to the client — those status codes
        // mean "user session expired" to fetchWithAuth, causing an unintended logout.
        // Map upstream auth errors to 502 Bad Gateway instead.
        if (err.status === 401 || err.status === 403) {
            err.status = 502;
        }
        next(err);
    }
});

module.exports = router;
