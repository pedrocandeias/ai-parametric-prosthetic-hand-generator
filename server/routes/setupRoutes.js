'use strict';

const express = require('express');
const { z } = require('zod');
const db = require('../db');
const { hashPassword } = require('../services/authService');

const router = express.Router();

const AdminSchema = z.object({
    username: z.string().min(2).max(50).regex(/^\w+$/, 'Username may only contain letters, digits, and underscores'),
    email: z.string().email(),
    password: z.string().min(8).max(128),
});

// GET /api/setup/status
router.get('/status', (req, res) => {
    const row = db.prepare('SELECT COUNT(*) AS cnt FROM users').get();
    res.json({ needsSetup: row.cnt === 0 });
});

// POST /api/setup/admin — hard-gated: only works when zero users exist
router.post('/admin', async (req, res, next) => {
    try {
        const row = db.prepare('SELECT COUNT(*) AS cnt FROM users').get();
        if (row.cnt > 0) {
            return res.status(403).json({ error: 'Setup already complete' });
        }

        const result = AdminSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { username, email, password } = result.data;
        const passwordHash = await hashPassword(password);

        const stmt = db.prepare(
            `INSERT INTO users (username, email, password_hash, role)
             VALUES (?, ?, ?, 'admin')`
        );
        const info = stmt.run(username, email, passwordHash);

        res.status(201).json({ id: info.lastInsertRowid, username, email, role: 'admin' });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
