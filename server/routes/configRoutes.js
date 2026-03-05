'use strict';

const express = require('express');
const path = require('path');
const fs = require('fs');
const { z } = require('zod');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// Load valid model IDs from models-config.json
let validModelIds = null;
function getValidModelIds() {
    if (validModelIds) return validModelIds;
    try {
        const configPath = path.join(__dirname, '..', '..', 'models', 'models-config.json');
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        validModelIds = new Set(config.models.map(m => m.id));
    } catch {
        validModelIds = new Set();
    }
    return validModelIds;
}

const ConfigSchema = z.object({
    model_id: z.string().min(1).max(100),
    name: z.string().min(1).max(200),
    parameters: z.record(z.unknown()),
    notes: z.string().max(1000).optional().default(''),
    user_id: z.number().int().positive().optional(),
});

const UpdateConfigSchema = z.object({
    name: z.string().min(1).max(200).optional(),
    parameters: z.record(z.unknown()).optional(),
    notes: z.string().max(1000).optional(),
}).refine(d => d.name !== undefined || d.parameters !== undefined || d.notes !== undefined, {
    message: 'Provide at least one field to update',
});

// Determine which user IDs the requester can see configs for
function accessibleUserIds(req) {
    const { sub: userId, role } = req.user;
    if (role === 'admin') return null; // null = all

    if (role === 'tech') {
        const rows = db.prepare(
            `SELECT user_id FROM tech_assignments WHERE tech_id = ?`
        ).all(userId);
        return [userId, ...rows.map(r => r.user_id)];
    }

    // regular user — own only
    return [userId];
}

function canAccessConfig(req, config) {
    const { sub: userId, role } = req.user;
    if (role === 'admin') return true;
    if (config.user_id === userId) return true;
    if (role === 'tech') {
        const assignment = db.prepare(
            `SELECT id FROM tech_assignments WHERE tech_id = ? AND user_id = ?`
        ).get(userId, config.user_id);
        return !!assignment;
    }
    return false;
}

// GET /api/configurations
router.get('/', requireAuth, (req, res) => {
    const ids = accessibleUserIds(req);
    const modelFilter = req.query.model_id || null;

    let query = `SELECT c.*, u.username FROM configurations c JOIN users u ON u.id = c.user_id`;
    const params = [];
    const where = [];

    if (ids !== null) {
        where.push(`c.user_id IN (${ids.map(() => '?').join(',')})`);
        params.push(...ids);
    }
    if (modelFilter) {
        where.push(`c.model_id = ?`);
        params.push(modelFilter);
    }

    if (where.length) query += ` WHERE ${where.join(' AND ')}`;
    query += ` ORDER BY c.updated_at DESC`;

    const rows = db.prepare(query).all(...params);
    // Parse parameters JSON
    res.json(rows.map(r => ({ ...r, parameters: JSON.parse(r.parameters) })));
});

// POST /api/configurations
router.post('/', requireAuth, (req, res, next) => {
    try {
        const result = ConfigSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { model_id, name, parameters, notes, user_id: bodyUserId } = result.data;

        // Validate model_id
        const validIds = getValidModelIds();
        if (validIds.size > 0 && !validIds.has(model_id)) {
            return res.status(400).json({ error: `Unknown model_id: ${model_id}` });
        }

        // Non-admins can only save for themselves
        let targetUserId = req.user.sub;
        if (bodyUserId && bodyUserId !== req.user.sub) {
            if (req.user.role !== 'admin') {
                return res.status(403).json({ error: 'Cannot save config for another user' });
            }
            targetUserId = bodyUserId;
        }

        const info = db.prepare(
            `INSERT INTO configurations (user_id, model_id, name, parameters, notes)
             VALUES (?, ?, ?, ?, ?)`
        ).run(targetUserId, model_id, name, JSON.stringify(parameters), notes);

        res.status(201).json({ id: info.lastInsertRowid, user_id: targetUserId, model_id, name, parameters, notes });
    } catch (err) {
        next(err);
    }
});

// GET /api/configurations/:id
router.get('/:id', requireAuth, (req, res) => {
    const configId = parseInt(req.params.id, 10);
    const config = db.prepare(`SELECT * FROM configurations WHERE id = ?`).get(configId);

    if (!config) return res.status(404).json({ error: 'Configuration not found' });
    if (!canAccessConfig(req, config)) return res.status(403).json({ error: 'Insufficient permissions' });

    res.json({ ...config, parameters: JSON.parse(config.parameters) });
});

// PATCH /api/configurations/:id
router.patch('/:id', requireAuth, (req, res, next) => {
    try {
        const configId = parseInt(req.params.id, 10);
        const config = db.prepare(`SELECT * FROM configurations WHERE id = ?`).get(configId);

        if (!config) return res.status(404).json({ error: 'Configuration not found' });
        if (!canAccessConfig(req, config)) return res.status(403).json({ error: 'Insufficient permissions' });

        const result = UpdateConfigSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { name, parameters, notes } = result.data;
        const fields = [];
        const vals = [];

        if (name !== undefined) { fields.push('name = ?'); vals.push(name); }
        if (parameters !== undefined) { fields.push('parameters = ?'); vals.push(JSON.stringify(parameters)); }
        if (notes !== undefined) { fields.push('notes = ?'); vals.push(notes); }
        fields.push("updated_at = datetime('now')");

        db.prepare(`UPDATE configurations SET ${fields.join(', ')} WHERE id = ?`).run(...vals, configId);

        const updated = db.prepare(`SELECT * FROM configurations WHERE id = ?`).get(configId);
        res.json({ ...updated, parameters: JSON.parse(updated.parameters) });
    } catch (err) {
        next(err);
    }
});

// DELETE /api/configurations/:id
router.delete('/:id', requireAuth, (req, res) => {
    const configId = parseInt(req.params.id, 10);
    const config = db.prepare(`SELECT * FROM configurations WHERE id = ?`).get(configId);

    if (!config) return res.status(404).json({ error: 'Configuration not found' });
    if (!canAccessConfig(req, config)) return res.status(403).json({ error: 'Insufficient permissions' });

    db.prepare(`DELETE FROM configurations WHERE id = ?`).run(configId);
    res.json({ ok: true });
});

module.exports = router;
