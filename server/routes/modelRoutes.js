'use strict';

const express = require('express');
const fs = require('fs');
const { z } = require('zod');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { verifyAccessToken } = require('../services/authService');
const registry = require('../services/modelRegistry');
const { parseScadParameters } = require('../services/scadParser');

const router = express.Router();
const adminOnly = [requireAuth, requireRole('admin')];

// Optional auth: a valid admin Bearer token reveals draft models.
function isAdminRequest(req) {
    const h = req.headers['authorization'];
    if (!h || !h.startsWith('Bearer ')) return false;
    try { return verifyAccessToken(h.slice(7)).role === 'admin'; } catch { return false; }
}

// ── Public ──────────────────────────────────────────────────────────────────

// GET /api/models — repository + enabled custom models (+ drafts for admins)
router.get('/', (req, res, next) => {
    try {
        res.set('Cache-Control', 'no-cache');
        res.json({ models: registry.getModels({ includeDrafts: isAdminRequest(req) }) });
    } catch (err) { next(err); }
});

// GET /api/models/files/:id/:file — a custom model's .scad / dependency.
// Always served as plain text or octet-stream (never HTML) with nosniff.
router.get('/files/:id/:file', (req, res, next) => {
    try {
        const { id, file } = req.params;
        if (!registry.ID_RE.test(id) || !registry.isValidFileName(file)) {
            return res.status(404).json({ error: 'File not found' });
        }
        const row = db.prepare(`SELECT id FROM custom_models WHERE id = ?`).get(id);
        const p = row && registry.filePath(id, file);
        if (!p || !fs.existsSync(p)) return res.status(404).json({ error: 'File not found' });
        res.set({
            'Content-Type': registry.contentType(file),
            'X-Content-Type-Options': 'nosniff',
            'Cache-Control': 'no-cache',
            'Content-Disposition': 'inline',
        });
        res.send(fs.readFileSync(p));
    } catch (err) { next(err); }
});

// ── Admin ───────────────────────────────────────────────────────────────────

const fileUploadSchema = z.object({
    name: z.string().refine(registry.isValidFileName, { message: 'File names may only use letters, digits, _ . - and must end in .scad, .stl, .dxf or .svg' }),
    content_base64: z.string().max(Math.ceil(registry.MAX_FILE_BYTES * 4 / 3) + 4, 'File is larger than 5 MB'),
});

const createSchema = z.object({
    id: z.string().regex(registry.ID_RE, 'Model id: 2–60 chars, lowercase letters, digits, _ or -, starting with a letter or digit'),
    enabled: z.boolean().optional(),
    definition: z.record(z.any()),
    files: z.array(fileUploadSchema).max(registry.MAX_FILES),
});

const updateSchema = z.object({
    enabled: z.boolean().optional(),
    definition: z.record(z.any()).optional(),
    files: z.array(fileUploadSchema).max(registry.MAX_FILES).optional(),
    removeFiles: z.array(z.string()).max(registry.MAX_FILES).optional(),
});

function decodeFiles(files) {
    return (files || []).map(f => {
        const buf = Buffer.from(f.content_base64, 'base64');
        if (buf.length > registry.MAX_FILE_BYTES) throw Object.assign(new Error(`${f.name} is larger than 5 MB`), { status: 400 });
        return { name: f.name, buf };
    });
}

function summarize(row) {
    let def = {};
    try { def = JSON.parse(row.definition); } catch { /* ignore */ }
    return {
        id: row.id,
        name: def.name || row.id,
        name_pt: def.name_pt,
        file: def.file,
        paramCount: (def.parameters || []).length,
        enabled: !!row.enabled,
        created_at: row.created_at,
        updated_at: row.updated_at,
        files: registry.listFiles(row.id),
    };
}

function configCount(id) {
    return db.prepare(`SELECT COUNT(*) AS n FROM configurations WHERE model_id = ?`).get(id).n;
}

// POST /api/models/parse-scad — Customizer parameters from a .scad source
router.post('/parse-scad', ...adminOnly, (req, res) => {
    const r = z.object({ source: z.string().max(registry.MAX_FILE_BYTES) }).safeParse(req.body);
    if (!r.success) return res.status(400).json({ error: r.error.errors[0].message });
    res.json(parseScadParameters(r.data.source));
});

// GET /api/models/admin — repository (read-only) + all custom models
router.get('/admin', ...adminOnly, (req, res, next) => {
    try {
        const repo = registry.getRepoModels().map(m => ({
            id: m.id, name: m.name, name_pt: m.name_pt, file: m.file,
            paramCount: (m.parameters || []).length, configCount: configCount(m.id),
        }));
        const custom = db.prepare(`SELECT * FROM custom_models ORDER BY created_at`).all()
            .map(r => ({ ...summarize(r), configCount: configCount(r.id) }));
        res.json({ repo, custom });
    } catch (err) { next(err); }
});

// GET /api/models/admin/:id — full custom model for editing
router.get('/admin/:id', ...adminOnly, (req, res, next) => {
    try {
        const row = db.prepare(`SELECT * FROM custom_models WHERE id = ?`).get(req.params.id);
        if (!row) return res.status(404).json({ error: 'Model not found' });
        res.json({ ...summarize(row), definition: JSON.parse(row.definition) });
    } catch (err) { next(err); }
});

// POST /api/models/admin — create
router.post('/admin', ...adminOnly, (req, res, next) => {
    const parsed = createSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
    const { id, enabled, definition, files } = parsed.data;

    if (registry.isRepoModel(id) || db.prepare(`SELECT 1 FROM custom_models WHERE id = ?`).get(id)) {
        return res.status(409).json({ error: `A model with id "${id}" already exists` });
    }
    const v = registry.validateDefinition(definition);
    if (!v.success) return res.status(400).json({ error: v.error.errors[0].message });

    let decoded;
    try { decoded = decodeFiles(files); } catch (err) { return res.status(err.status || 400).json({ error: err.message }); }
    if (!decoded.some(f => f.name === v.data.file)) {
        return res.status(400).json({ error: `Upload the main file ${v.data.file}` });
    }

    try {
        decoded.forEach(f => registry.writeFile(id, f.name, f.buf));
        db.prepare(
            `INSERT INTO custom_models (id, definition, enabled, created_by) VALUES (?, ?, ?, ?)`
        ).run(id, JSON.stringify(v.data), enabled ? 1 : 0, req.user.sub);
    } catch (err) {
        registry.removeModelDir(id);
        return next(err);
    }
    const row = db.prepare(`SELECT * FROM custom_models WHERE id = ?`).get(id);
    res.status(201).json({ ...summarize(row), definition: v.data });
});

// PUT /api/models/admin/:id — update definition / files / enabled
router.put('/admin/:id', ...adminOnly, (req, res, next) => {
    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: parsed.error.errors[0].message });
    const { id } = req.params;
    const row = db.prepare(`SELECT * FROM custom_models WHERE id = ?`).get(id);
    if (!row) return res.status(404).json({ error: 'Model not found' });

    let def = JSON.parse(row.definition);
    if (parsed.data.definition) {
        const v = registry.validateDefinition(parsed.data.definition);
        if (!v.success) return res.status(400).json({ error: v.error.errors[0].message });
        def = v.data;
    }

    let decoded;
    try { decoded = decodeFiles(parsed.data.files); } catch (err) { return res.status(err.status || 400).json({ error: err.message }); }
    const remove = (parsed.data.removeFiles || []).filter(registry.isValidFileName);

    // The main file must still exist after this change.
    const after = new Set(registry.listFiles(id).map(f => f.name));
    remove.forEach(n => after.delete(n));
    decoded.forEach(f => after.add(f.name));
    if (!after.has(def.file)) return res.status(400).json({ error: `Main file ${def.file} is missing — upload it or pick another main file` });
    if (after.size > registry.MAX_FILES) return res.status(400).json({ error: `At most ${registry.MAX_FILES} files per model` });

    try {
        remove.forEach(n => registry.deleteFile(id, n));
        decoded.forEach(f => registry.writeFile(id, f.name, f.buf));
        const enabled = parsed.data.enabled === undefined ? row.enabled : (parsed.data.enabled ? 1 : 0);
        db.prepare(
            `UPDATE custom_models SET definition = ?, enabled = ?, updated_at = datetime('now') WHERE id = ?`
        ).run(JSON.stringify(def), enabled, id);
    } catch (err) { return next(err); }
    const updated = db.prepare(`SELECT * FROM custom_models WHERE id = ?`).get(id);
    res.json({ ...summarize(updated), definition: def });
});

// DELETE /api/models/admin/:id — refused while saved configurations use it
router.delete('/admin/:id', ...adminOnly, (req, res, next) => {
    try {
        const { id } = req.params;
        const row = db.prepare(`SELECT id FROM custom_models WHERE id = ?`).get(id);
        if (!row) return res.status(404).json({ error: 'Model not found' });
        const n = configCount(id);
        if (n > 0) {
            return res.status(409).json({ error: `${n} saved configuration(s) use this model — disable it instead of deleting` });
        }
        db.prepare(`DELETE FROM custom_models WHERE id = ?`).run(id);
        registry.removeModelDir(id);
        res.json({ ok: true });
    } catch (err) { next(err); }
});

module.exports = router;
