'use strict';

const express = require('express');
const { z } = require('zod');
const db = require('../db');
const { hashPassword } = require('../services/authService');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

const CreateUserSchema = z.object({
    username: z.string().min(2).max(50).regex(/^\w+$/, 'Username may only contain letters, digits, and underscores'),
    email: z.string().email(),
    password: z.string().min(8).max(128),
    role: z.enum(['admin', 'tech', 'user']).default('user'),
});

const UpdateUserSchema = z.object({
    role: z.enum(['admin', 'tech', 'user']).optional(),
    is_active: z.boolean().optional(),
    username: z.string().min(2).max(50).regex(/^\w+$/, 'Username may only contain letters, digits, and underscores').optional(),
    email: z.string().email().optional(),
}).refine(d => [d.role, d.is_active, d.username, d.email].some(v => v !== undefined), {
    message: 'Provide at least one field to update',
});

const PasswordSchema = z.object({
    password: z.string().min(8).max(128),
});

function safeUser(u) {
    return { id: u.id, username: u.username, email: u.email, role: u.role, is_active: u.is_active, created_at: u.created_at };
}

// GET /api/users — admin only
router.get('/', requireAuth, requireRole('admin'), (req, res) => {
    const users = db.prepare(
        `SELECT id, username, email, role, is_active, created_at FROM users ORDER BY id`
    ).all();
    res.json(users);
});

// POST /api/users — admin only
router.post('/', requireAuth, requireRole('admin'), async (req, res, next) => {
    try {
        const result = CreateUserSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { username, email, password, role } = result.data;

        const existing = db.prepare(`SELECT id FROM users WHERE username = ? OR email = ?`).get(username, email);
        if (existing) return res.status(409).json({ error: 'Username or email already taken' });

        const passwordHash = await hashPassword(password);
        const info = db.prepare(
            `INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)`
        ).run(username, email, passwordHash, role);

        res.status(201).json({ id: info.lastInsertRowid, username, email, role, is_active: 1 });
    } catch (err) {
        next(err);
    }
});

// GET /api/users/:id — admin or self
router.get('/:id', requireAuth, (req, res) => {
    const targetId = parseInt(req.params.id, 10);
    if (req.user.role !== 'admin' && req.user.sub !== targetId) {
        return res.status(403).json({ error: 'Insufficient permissions' });
    }

    const user = db.prepare(
        `SELECT id, username, email, role, is_active, created_at FROM users WHERE id = ?`
    ).get(targetId);

    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
});

// PATCH /api/users/:id — admin only (role/active)
router.patch('/:id', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const targetId = parseInt(req.params.id, 10);
        const result = UpdateUserSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const user = db.prepare(`SELECT id FROM users WHERE id = ?`).get(targetId);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const { role, is_active, username, email } = result.data;
        const fields = [];
        const vals = [];

        if (username !== undefined) {
            const clash = db.prepare(`SELECT id FROM users WHERE username = ? AND id != ?`).get(username, targetId);
            if (clash) return res.status(409).json({ error: 'Username already taken' });
            fields.push('username = ?'); vals.push(username);
        }
        if (email !== undefined) {
            const clash = db.prepare(`SELECT id FROM users WHERE email = ? AND id != ?`).get(email, targetId);
            if (clash) return res.status(409).json({ error: 'Email already taken' });
            fields.push('email = ?'); vals.push(email);
        }
        if (role !== undefined) { fields.push('role = ?'); vals.push(role); }
        if (is_active !== undefined) { fields.push('is_active = ?'); vals.push(is_active ? 1 : 0); }
        fields.push("updated_at = datetime('now')");

        db.prepare(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`).run(...vals, targetId);

        const updated = db.prepare(
            `SELECT id, username, email, role, is_active, created_at FROM users WHERE id = ?`
        ).get(targetId);
        res.json(updated);
    } catch (err) {
        next(err);
    }
});

// DELETE /api/users/:id — soft-delete (admin only)
router.delete('/:id', requireAuth, requireRole('admin'), (req, res) => {
    const targetId = parseInt(req.params.id, 10);
    if (targetId === req.user.sub) {
        return res.status(400).json({ error: 'Cannot deactivate your own account' });
    }
    const info = db.prepare(
        `UPDATE users SET is_active = 0, updated_at = datetime('now') WHERE id = ?`
    ).run(targetId);
    if (info.changes === 0) return res.status(404).json({ error: 'User not found' });
    res.json({ ok: true });
});

// PATCH /api/users/:id/password — admin or self
router.patch('/:id/password', requireAuth, async (req, res, next) => {
    try {
        const targetId = parseInt(req.params.id, 10);
        if (req.user.role !== 'admin' && req.user.sub !== targetId) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }

        const result = PasswordSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const passwordHash = await hashPassword(result.data.password);
        const info = db.prepare(
            `UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?`
        ).run(passwordHash, targetId);

        if (info.changes === 0) return res.status(404).json({ error: 'User not found' });
        res.json({ ok: true });
    } catch (err) {
        next(err);
    }
});

// ── Tech Assignments ─────────────────────────────────────────────────────

// GET /api/users/:techId/patients — admin or the tech themselves
router.get('/:techId/patients', requireAuth, (req, res) => {
    const techId = parseInt(req.params.techId, 10);
    if (req.user.role !== 'admin' && req.user.sub !== techId) {
        return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Verify tech exists and has tech role
    const tech = db.prepare(`SELECT id, role FROM users WHERE id = ? AND is_active = 1`).get(techId);
    if (!tech) return res.status(404).json({ error: 'Tech not found' });
    if (tech.role !== 'tech' && req.user.role !== 'admin') {
        return res.status(400).json({ error: 'User is not a tech' });
    }

    const patients = db.prepare(
        `SELECT u.id, u.username, u.email, u.role, ta.assigned_at
         FROM tech_assignments ta
         JOIN users u ON u.id = ta.user_id
         WHERE ta.tech_id = ?
         ORDER BY u.username`
    ).all(techId);

    res.json(patients);
});

// POST /api/users/:techId/patients — admin only
router.post('/:techId/patients', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const techId = parseInt(req.params.techId, 10);
        const { user_id } = req.body;
        if (!user_id || typeof user_id !== 'number') {
            return res.status(400).json({ error: 'user_id (number) required' });
        }

        const tech = db.prepare(`SELECT id, role FROM users WHERE id = ? AND is_active = 1`).get(techId);
        if (!tech) return res.status(404).json({ error: 'Tech not found' });
        if (tech.role !== 'tech') return res.status(400).json({ error: 'Target user is not a tech' });

        const patient = db.prepare(`SELECT id FROM users WHERE id = ? AND is_active = 1`).get(user_id);
        if (!patient) return res.status(404).json({ error: 'Patient user not found' });

        const info = db.prepare(
            `INSERT OR IGNORE INTO tech_assignments (tech_id, user_id, assigned_by) VALUES (?, ?, ?)`
        ).run(techId, user_id, req.user.sub);

        res.status(info.changes ? 201 : 200).json({ ok: true });
    } catch (err) {
        next(err);
    }
});

// DELETE /api/users/:techId/patients/:userId — admin only
router.delete('/:techId/patients/:userId', requireAuth, requireRole('admin'), (req, res) => {
    const techId = parseInt(req.params.techId, 10);
    const userId = parseInt(req.params.userId, 10);
    const info = db.prepare(
        `DELETE FROM tech_assignments WHERE tech_id = ? AND user_id = ?`
    ).run(techId, userId);
    if (info.changes === 0) return res.status(404).json({ error: 'Assignment not found' });
    res.json({ ok: true });
});

module.exports = router;
