'use strict';

const express = require('express');
const { z } = require('zod');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const importer = require('../services/anthropometricImporter');

const router = express.Router();

// All endpoints are admin-only
const adminOnly = [requireAuth, requireRole('admin')];

// ── Validation ────────────────────────────────────────────────────────────────

const MetaSchema = z.object({
    group_name:           z.string().min(2).max(200),
    country:              z.string().max(100).optional(),
    gender:               z.enum(['male', 'female', 'mixed', 'other']).optional(),
    age_group:            z.string().max(100).optional(),
    percentile:           z.string().max(20).optional(),
    sample_size:          z.number().int().positive().optional(),
    data_source:          z.string().max(500).optional(),
    notes:                z.string().max(2000).optional(),
    tolerance_preference: z.enum(['snug', 'standard', 'loose']).optional(),
    hardware_standard:    z.enum(['m2', 'm3', 'm4']).optional(),
    default_unit:         z.enum(['mm', 'cm', 'in']).optional(),
    measurement_source:   z.string().max(50).optional(),
});

// ── POST /api/anthropometric/preview  (process without saving) ────────────────

router.post('/preview', adminOnly, (req, res, next) => {
    try {
        const { format = 'form', data, meta = {}, csv_text, default_unit } = req.body;

        const metaResult = MetaSchema.safeParse(meta);
        if (!metaResult.success) {
            return res.status(400).json({ error: metaResult.error.errors[0].message });
        }

        const inputData = format === 'csv' ? (csv_text || data) : (data || req.body);
        const result = importer.process({
            format,
            data: inputData,
            meta: metaResult.data,
            default_unit: default_unit || metaResult.data.default_unit || 'mm',
        });

        res.json(result);
    } catch (err) {
        if (err.message.startsWith('Unknown unit') || err.message.startsWith('Empty CSV')) {
            return res.status(400).json({ error: err.message });
        }
        next(err);
    }
});

// ── POST /api/anthropometric  (process + save) ────────────────────────────────

router.post('/', adminOnly, (req, res, next) => {
    try {
        const { format = 'form', data, meta = {}, csv_text, default_unit } = req.body;

        const metaResult = MetaSchema.safeParse(meta);
        if (!metaResult.success) {
            return res.status(400).json({ error: metaResult.error.errors[0].message });
        }

        const inputData = format === 'csv' ? (csv_text || data) : (data || req.body);
        const result = importer.process({
            format,
            data: inputData,
            meta: {
                ...metaResult.data,
                measurement_source: metaResult.data.measurement_source || format,
            },
            default_unit: default_unit || metaResult.data.default_unit || 'mm',
        });

        const m = result.profile.metadata;
        const info = db.prepare(`
            INSERT INTO anthropometric_profiles
                (group_name, country, gender, age_group, percentile,
                 sample_size, data_source, notes, measurement_source,
                 profile, geometry_parameters, ai_context, schema_version)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            m.group_name, m.country, m.gender, m.age_group, m.percentile,
            m.sample_size, m.data_source, m.notes, m.measurement_source,
            JSON.stringify(result.profile),
            JSON.stringify(result.geometry_parameters),
            JSON.stringify(result.ai_context),
            importer.SCHEMA_VERSION,
        );

        res.status(201).json({ id: info.lastInsertRowid, ...result });
    } catch (err) {
        if (err.message.startsWith('Unknown unit') || err.message.startsWith('Empty CSV')) {
            return res.status(400).json({ error: err.message });
        }
        next(err);
    }
});

// ── GET /api/anthropometric  (list, with optional filters) ────────────────────

router.get('/', adminOnly, (req, res) => {
    const { country, gender, age_group } = req.query;

    const conditions = [];
    const params = [];

    if (country)   { conditions.push('country = ?');   params.push(country); }
    if (gender)    { conditions.push('gender = ?');    params.push(gender); }
    if (age_group) { conditions.push('age_group = ?'); params.push(age_group); }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    const profiles = db.prepare(`
        SELECT id, group_name, country, gender, age_group, percentile,
               sample_size, data_source, measurement_source, schema_version, created_at,
               json_extract(ai_context, '$.uncertainty') AS uncertainty
        FROM anthropometric_profiles
        ${where}
        ORDER BY created_at DESC
    `).all(...params);

    res.json(profiles);
});

// ── GET /api/anthropometric/:id  (full profile) ───────────────────────────────

router.get('/:id', adminOnly, (req, res) => {
    const row = db.prepare(`SELECT * FROM anthropometric_profiles WHERE id = ?`)
        .get(parseInt(req.params.id, 10));
    if (!row) return res.status(404).json({ error: 'Profile not found' });

    res.json({
        id:                  row.id,
        group_name:          row.group_name,
        country:             row.country,
        gender:              row.gender,
        age_group:           row.age_group,
        percentile:          row.percentile,
        sample_size:         row.sample_size,
        data_source:         row.data_source,
        notes:               row.notes,
        measurement_source:  row.measurement_source,
        profile:             JSON.parse(row.profile),
        geometry_parameters: JSON.parse(row.geometry_parameters),
        ai_context:          JSON.parse(row.ai_context),
        schema_version:      row.schema_version,
        created_at:          row.created_at,
    });
});

// ── DELETE /api/anthropometric/:id ───────────────────────────────────────────

router.delete('/:id', adminOnly, (req, res) => {
    const info = db.prepare(`DELETE FROM anthropometric_profiles WHERE id = ?`)
        .run(parseInt(req.params.id, 10));
    if (info.changes === 0) return res.status(404).json({ error: 'Profile not found' });
    res.json({ ok: true });
});

module.exports = router;
