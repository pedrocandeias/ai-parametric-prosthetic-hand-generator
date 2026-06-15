'use strict';

const express = require('express');
const { z } = require('zod');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

// ── Footer ────────────────────────────────────────────────────────────────

// Default footer — mirrors the original hardcoded markup so the site looks
// unchanged until an admin edits it.
const DEFAULT_FOOTER = {
    brandTitle: 'Hand Fab',
    tagline: 'Custom hand prosthetic configuration system',
    copyright: '© 2026 Hand Fab. All rights reserved.',
    columns: [
        { title: 'Support', links: [
            { label: 'Help Center', type: 'url', target: '#' },
            { label: 'Documentation', type: 'url', target: '#' },
            { label: 'Tutorials', type: 'url', target: '#' },
        ] },
        { title: 'Contact', links: [
            { label: 'Email Support', type: 'url', target: '#' },
            { label: 'Live Chat', type: 'url', target: '#' },
            { label: 'Schedule Call', type: 'url', target: '#' },
        ] },
        { title: 'Legal', links: [
            { label: 'Privacy Policy', type: 'url', target: '#' },
            { label: 'Terms of Service', type: 'url', target: '#' },
            { label: 'Accessibility', type: 'url', target: '#' },
        ] },
    ],
};

const linkSchema = z.object({
    label: z.string().trim().min(1).max(80),
    type: z.enum(['page', 'url']),
    target: z.string().trim().min(1).max(300),
});
const columnSchema = z.object({
    title: z.string().trim().min(1).max(80),
    links: z.array(linkSchema).max(20),
});
const footerSchema = z.object({
    brandTitle: z.string().trim().max(80),
    tagline: z.string().trim().max(200),
    copyright: z.string().trim().max(200),
    columns: z.array(columnSchema).max(8),
});

// GET /api/content/footer — public
router.get('/footer', (req, res, next) => {
    try {
        const row = db.prepare(`SELECT value FROM site_settings WHERE key = 'footer'`).get();
        if (!row) return res.json(DEFAULT_FOOTER);
        res.json(JSON.parse(row.value));
    } catch (err) { next(err); }
});

// PUT /api/content/footer — admin
router.put('/footer', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const result = footerSchema.safeParse(req.body);
        if (!result.success) return res.status(400).json({ error: result.error.errors[0].message });
        const value = JSON.stringify(result.data);
        db.prepare(
            `INSERT INTO site_settings (key, value, updated_at) VALUES ('footer', ?, datetime('now'))
             ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = datetime('now')`
        ).run(value);
        res.json(result.data);
    } catch (err) { next(err); }
});

// ── Pages ───────────────────────────────────────────────────────────────────

const slugSchema = z.string().trim().toLowerCase().min(1).max(80)
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Slug must be lowercase letters, numbers and hyphens');
const langSchema = z.string().trim().toLowerCase().regex(/^[a-z]{2}$/, 'Language must be a 2-letter code');
const pageCreateSchema = z.object({
    slug: slugSchema,
    title: z.string().trim().min(1).max(160),
    body: z.string().max(50000).default(''),
    is_published: z.boolean().default(true),
    language: langSchema.default('en'),
    translation_group: z.string().trim().max(120).optional(),
});
const pageUpdateSchema = z.object({
    slug: slugSchema.optional(),
    title: z.string().trim().min(1).max(160).optional(),
    body: z.string().max(50000).optional(),
    is_published: z.boolean().optional(),
    language: langSchema.optional(),
});

// GET /api/content/pages — admin: list all pages (incl. unpublished). Ordered so
// translations of the same page sit together.
router.get('/pages', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const rows = db.prepare(
            `SELECT id, slug, title, body, is_published, language, translation_group, created_at, updated_at
             FROM pages ORDER BY translation_group COLLATE NOCASE, language`
        ).all();
        res.json(rows.map(r => ({ ...r, is_published: !!r.is_published })));
    } catch (err) { next(err); }
});

// GET /api/content/pages/:slug?lang=xx — public: a published page; if a translation
// in the requested language exists in the same group, return that instead.
router.get('/pages/:slug', (req, res, next) => {
    try {
        const base = db.prepare(`SELECT * FROM pages WHERE slug = ? COLLATE NOCASE`).get(req.params.slug);
        if (!base || !base.is_published) return res.status(404).json({ error: 'Page not found' });
        let row = base;
        const lang = String(req.query.lang || '').toLowerCase();
        if (/^[a-z]{2}$/.test(lang) && lang !== base.language && base.translation_group) {
            const alt = db.prepare(
                `SELECT * FROM pages WHERE translation_group = ? AND language = ? AND is_published = 1`
            ).get(base.translation_group, lang);
            if (alt) row = alt;
        }
        res.json({ slug: row.slug, title: row.title, body: row.body, language: row.language, updated_at: row.updated_at });
    } catch (err) { next(err); }
});

// POST /api/content/pages — admin: create
router.post('/pages', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const result = pageCreateSchema.safeParse(req.body);
        if (!result.success) return res.status(400).json({ error: result.error.errors[0].message });
        const { slug, title, body, is_published, language } = result.data;
        const group = result.data.translation_group || slug;
        const exists = db.prepare(`SELECT 1 FROM pages WHERE slug = ? COLLATE NOCASE`).get(slug);
        if (exists) return res.status(409).json({ error: 'A page with that slug already exists' });
        const info = db.prepare(
            `INSERT INTO pages (slug, title, body, is_published, language, translation_group) VALUES (?, ?, ?, ?, ?, ?)`
        ).run(slug, title, body, is_published ? 1 : 0, language, group);
        res.status(201).json({ id: info.lastInsertRowid, slug, title, body, is_published, language, translation_group: group });
    } catch (err) { next(err); }
});

// POST /api/content/pages/:id/translate — admin: create a linked translation,
// pre-filled from the source page, in the requested language.
router.post('/pages/:id/translate', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const src = db.prepare(`SELECT * FROM pages WHERE id = ?`).get(Number(req.params.id));
        if (!src) return res.status(404).json({ error: 'Page not found' });
        const lr = langSchema.safeParse((req.body || {}).language);
        if (!lr.success) return res.status(400).json({ error: 'A valid 2-letter target language is required' });
        const language = lr.data;
        const group = src.translation_group || src.slug;
        const existing = db.prepare(`SELECT id, slug FROM pages WHERE translation_group = ? AND language = ?`).get(group, language);
        if (existing) return res.status(409).json({ error: `A ${language} translation already exists`, id: existing.id, slug: existing.slug });
        let newSlug = `${src.slug}-${language}`;
        let n = 2;
        while (db.prepare(`SELECT 1 FROM pages WHERE slug = ? COLLATE NOCASE`).get(newSlug)) newSlug = `${src.slug}-${language}-${n++}`;
        if (!src.translation_group) db.prepare(`UPDATE pages SET translation_group = ? WHERE id = ?`).run(group, src.id);
        const info = db.prepare(
            `INSERT INTO pages (slug, title, body, is_published, language, translation_group) VALUES (?, ?, ?, ?, ?, ?)`
        ).run(newSlug, src.title, src.body, src.is_published, language, group);
        res.status(201).json({ id: info.lastInsertRowid, slug: newSlug, title: src.title, body: src.body, is_published: !!src.is_published, language, translation_group: group });
    } catch (err) { next(err); }
});

// PUT /api/content/pages/:id — admin: update
router.put('/pages/:id', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const id = Number(req.params.id);
        const page = db.prepare(`SELECT id FROM pages WHERE id = ?`).get(id);
        if (!page) return res.status(404).json({ error: 'Page not found' });
        const result = pageUpdateSchema.safeParse(req.body);
        if (!result.success) return res.status(400).json({ error: result.error.errors[0].message });
        const data = result.data;
        if (data.slug) {
            const clash = db.prepare(`SELECT 1 FROM pages WHERE slug = ? COLLATE NOCASE AND id != ?`).get(data.slug, id);
            if (clash) return res.status(409).json({ error: 'A page with that slug already exists' });
        }
        const fields = [];
        const values = [];
        if (data.slug !== undefined)         { fields.push('slug = ?');         values.push(data.slug); }
        if (data.title !== undefined)        { fields.push('title = ?');        values.push(data.title); }
        if (data.body !== undefined)         { fields.push('body = ?');         values.push(data.body); }
        if (data.is_published !== undefined) { fields.push('is_published = ?'); values.push(data.is_published ? 1 : 0); }
        if (data.language !== undefined)     { fields.push('language = ?');     values.push(data.language); }
        if (!fields.length) return res.status(400).json({ error: 'No fields to update' });
        fields.push(`updated_at = datetime('now')`);
        db.prepare(`UPDATE pages SET ${fields.join(', ')} WHERE id = ?`).run(...values, id);
        const updated = db.prepare(
            `SELECT id, slug, title, body, is_published, language, translation_group, created_at, updated_at FROM pages WHERE id = ?`
        ).get(id);
        res.json({ ...updated, is_published: !!updated.is_published });
    } catch (err) { next(err); }
});

// DELETE /api/content/pages/:id — admin
router.delete('/pages/:id', requireAuth, requireRole('admin'), (req, res, next) => {
    try {
        const info = db.prepare(`DELETE FROM pages WHERE id = ?`).run(Number(req.params.id));
        if (info.changes === 0) return res.status(404).json({ error: 'Page not found' });
        res.json({ ok: true });
    } catch (err) { next(err); }
});

module.exports = router;
