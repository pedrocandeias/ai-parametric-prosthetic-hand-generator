'use strict';

const express = require('express');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');
const { callAnthropic, callOpenAI } = require('../services/aiService');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// 10 requests per minute per IP (authenticated users only)
const aiLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 10,
    keyGenerator: (req) => String(req.user?.sub ?? req.ip),
    message: { error: 'AI rate limit exceeded, please wait a moment' },
    standardHeaders: true,
    legacyHeaders: false,
});

const SuggestSchema = z.object({
    provider: z.enum(['anthropic', 'openai']).default('anthropic'),
    prompt: z.string().min(1).max(4000),
});

// POST /api/ai/suggest
router.post('/suggest', requireAuth, aiLimiter, async (req, res, next) => {
    try {
        const result = SuggestSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { provider, prompt } = result.data;

        let text;
        if (provider === 'anthropic') {
            text = await callAnthropic(prompt);
        } else {
            text = await callOpenAI(prompt);
        }

        res.json({ text });
    } catch (err) {
        // Pass AI provider errors with their original status code (e.g. 503 if not configured)
        next(err);
    }
});

module.exports = router;
