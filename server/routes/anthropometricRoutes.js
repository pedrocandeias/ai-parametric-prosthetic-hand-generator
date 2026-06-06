'use strict';

const express = require('express');
const path = require('path');
const fs = require('fs');
const { z } = require('zod');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const importer = require('../services/anthropometricImporter');
const { mapProfileToModelParameters } = require('../services/profileMapping');

const router = express.Router();

// Write/CRUD endpoints are admin-only. The two read endpoints below
// (/options, /:id/model-parameters) use requireAuth only: they expose
// population-level reference data (no patient PII), which any authenticated
// clinician needs in the configurator to seed a design.
const adminOnly = [requireAuth, requireRole('admin')];

// Lazily load models-config.json for parameter bounds (clamping).
let _modelsConfig = null;
function getModelsConfig() {
    if (_modelsConfig) return _modelsConfig;
    try {
        const p = path.join(__dirname, '..', '..', 'models', 'models-config.json');
        _modelsConfig = JSON.parse(fs.readFileSync(p, 'utf8'));
    } catch {
        _modelsConfig = { models: [] };
    }
    return _modelsConfig;
}

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

// ── GET /api/anthropometric/options  (lightweight list for pickers) ───────────
// Authenticated (any role): population reference data, no patient PII.
router.get('/options', requireAuth, (req, res) => {
    const profiles = db.prepare(`
        SELECT id, group_name, country, gender, age_group, percentile, sample_size,
               json_extract(ai_context, '$.uncertainty') AS uncertainty
        FROM anthropometric_profiles
        ORDER BY group_name ASC
    `).all();
    res.json(profiles);
});

// ── GET /api/anthropometric/:id/model-parameters?model_id=  ───────────────────
// Maps a profile's measurements onto a model's parameters (clamped to bounds).
router.get('/:id/model-parameters', requireAuth, (req, res) => {
    const modelId = String(req.query.model_id || '');
    if (!modelId) return res.status(400).json({ error: 'model_id query parameter is required' });

    const modelDef = getModelsConfig().models.find(m => m.id === modelId);
    if (!modelDef) return res.status(404).json({ error: `Unknown model_id: ${modelId}` });

    const row = db.prepare('SELECT profile, ai_context, group_name FROM anthropometric_profiles WHERE id = ?')
        .get(parseInt(req.params.id, 10));
    if (!row) return res.status(404).json({ error: 'Profile not found' });

    let profile, aiContext;
    try {
        profile = JSON.parse(row.profile);
        aiContext = JSON.parse(row.ai_context);
    } catch {
        return res.status(500).json({ error: 'Stored profile is corrupt' });
    }

    const mapped = mapProfileToModelParameters(profile, modelDef);
    if (mapped.applied.length === 0) {
        return res.status(422).json({
            error: `Profile has no measurements that map to model "${modelId}"`,
            skipped: mapped.skipped,
        });
    }

    res.json({
        model_id:    modelId,
        group_name:  row.group_name,
        parameters:  mapped.parameters,
        applied:     mapped.applied,
        skipped:     mapped.skipped,
        clamped:     mapped.clamped,
        uncertainty: aiContext?.uncertainty || null,
    });
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

// ── PUT /api/anthropometric/:id  (update existing) ───────────────────────────

router.put('/:id', adminOnly, (req, res, next) => {
    try {
        const id = parseInt(req.params.id, 10);
        const existing = db.prepare('SELECT id FROM anthropometric_profiles WHERE id = ?').get(id);
        if (!existing) return res.status(404).json({ error: 'Profile not found' });

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
        db.prepare(`
            UPDATE anthropometric_profiles SET
                group_name = ?, country = ?, gender = ?, age_group = ?, percentile = ?,
                sample_size = ?, data_source = ?, notes = ?, measurement_source = ?,
                profile = ?, geometry_parameters = ?, ai_context = ?, schema_version = ?
            WHERE id = ?
        `).run(
            m.group_name, m.country, m.gender, m.age_group, m.percentile,
            m.sample_size, m.data_source, m.notes, m.measurement_source,
            JSON.stringify(result.profile),
            JSON.stringify(result.geometry_parameters),
            JSON.stringify(result.ai_context),
            importer.SCHEMA_VERSION,
            id,
        );

        res.json({ id, ...result });
    } catch (err) {
        if (err.message.startsWith('Unknown unit') || err.message.startsWith('Empty CSV')) {
            return res.status(400).json({ error: err.message });
        }
        next(err);
    }
});

// ── POST /api/anthropometric/import-csv-bulk ──────────────────────────────────
// Parses multi_population_hand.csv (long-format anthropometric database) and
// creates one anthropometric profile per unique (population, country, sex,
// age_group, percentile) group.  Idempotent — skips groups already in the DB.

const MEASUREMENT_MAP = {
    // Palm breadth / knuckle width → HandWidth (KEY_MAP key: palm_breadth)
    'hand breadth (metacarpal)':          'palm_breadth',
    'hand breadth metacarpal':            'palm_breadth',
    'hand breadth metacarpal (minimum)':  'palm_breadth',
    'maximum hand breadth':               'palm_breadth',
    'hand width':                         'palm_breadth',
    'hand width (without thumb)':         'palm_breadth',
    // Palm length (KEY_MAP key: palm_length)
    'palm length':                        'palm_length',
    'palmar length':                      'palm_length',
    'hand length':                        'palm_length',
    'hand length (wrist crease to middle fingertip)': 'palm_length',
    // Palm thickness (KEY_MAP key: palm_thickness)
    'hand thickness':                     'palm_thickness',
    'hand depth metacarpal 3':            'palm_thickness',
    // Wrist circumference
    'wrist circumference':                'wrist_circumference',
    // Finger total lengths
    'finger length (right hand) - thumb':             'thumb_length_total',
    'finger length (combined, right hand) - thumb':   'thumb_length_total',
    'finger length to crotch level - digit 1 (thumb)':'thumb_length_total',
    'finger length (right hand) - index finger':      'index_length_total',
    'finger length (combined, right hand) - index finger': 'index_length_total',
    'index finger (d2) length (mcp crease to tip)':   'index_length_total',
    'finger length to crotch level - digit 2 (index)':'index_length_total',
    'finger length (right hand) - middle finger':     'middle_length_total',
    '3rd digit (middle finger) length':               'middle_length_total',
    'middle finger length':                           'middle_length_total',
    'finger length (middle finger)':                  'middle_length_total',
    'finger length to crotch level - digit 3 (middle)':'middle_length_total',
    'finger length (right hand) - ring finger':       'ring_length_total',
    'finger length (combined, right hand) - ring finger': 'ring_length_total',
    'finger length to crotch level - digit 4 (ring)': 'ring_length_total',
    'finger length (right hand) - little finger':     'little_length_total',
    'finger length (combined, right hand) - little finger': 'little_length_total',
    'finger length to crotch level - digit 5 (little)':'little_length_total',
};

// RFC 4180 CSV row parser — handles quoted fields with embedded commas/newlines
function parseCsvRow(line) {
    const fields = [];
    let i = 0;
    while (i < line.length) {
        if (line[i] === '"') {
            let field = '';
            i++; // skip opening quote
            while (i < line.length) {
                if (line[i] === '"' && line[i + 1] === '"') { field += '"'; i += 2; }
                else if (line[i] === '"') { i++; break; }
                else { field += line[i++]; }
            }
            fields.push(field.trim());
            if (line[i] === ',') i++;
        } else {
            const end = line.indexOf(',', i);
            if (end === -1) { fields.push(line.slice(i).trim()); break; }
            fields.push(line.slice(i, end).trim());
            i = end + 1;
        }
    }
    return fields;
}

router.post('/import-csv-bulk', adminOnly, (req, res, next) => {
    try {
        const { csv_text } = req.body;
        if (!csv_text || typeof csv_text !== 'string') {
            return res.status(400).json({ error: 'csv_text is required' });
        }

        // Split on newlines but preserve quoted multi-line fields by re-joining broken rows
        const rawLines = csv_text.trim().split(/\r?\n/);
        const lines = [];
        let buf = '';
        for (const raw of rawLines) {
            buf = buf ? buf + '\n' + raw : raw;
            // Count unescaped quotes — even count = balanced
            const quotes = (buf.match(/"/g) || []).length;
            if (quotes % 2 === 0) { lines.push(buf); buf = ''; }
        }
        if (buf) lines.push(buf);

        if (lines.length < 2) return res.status(400).json({ error: 'CSV is empty' });

        const headers = parseCsvRow(lines[0]).map(h => h.toLowerCase());
        const colIdx  = name => headers.indexOf(name);

        const ci = {
            name:        colIdx('measurement_name'),
            population:  colIdx('population'),
            country:     colIdx('country'),
            sex:         colIdx('sex'),
            age_group:   colIdx('age_group'),
            sample_size: colIdx('sample_size'),
            stat_type:   colIdx('stat_type'),
            percentile:  colIdx('percentile'),
            value_mm:    colIdx('value_mm'),
            source_doc:  colIdx('source_document'),
            source_cit:  colIdx('source_citation'),
        };

        // Group rows by composite key; collect only mean values
        const groups = new Map();
        for (let i = 1; i < lines.length; i++) {
            const cells = parseCsvRow(lines[i]);
            if (cells.length < 5) continue;

            const statType = cells[ci.stat_type] || '';
            if (statType !== 'mean') continue;

            const measName = (cells[ci.name] || '').trim().toLowerCase();
            const field    = MEASUREMENT_MAP[measName];
            if (!field) continue;

            const valueMm = parseFloat(cells[ci.value_mm]);
            if (isNaN(valueMm) || valueMm <= 0) continue;

            const pop        = cells[ci.population]  || '';
            const country    = cells[ci.country]     || '';
            const sex        = cells[ci.sex]         || '';
            const ageGroup   = cells[ci.age_group]   || '';
            const percentile = cells[ci.percentile]  || '';
            const sampleSize = parseInt(cells[ci.sample_size], 10) || null;
            const dataSource = cells[ci.source_cit]  || cells[ci.source_doc] || '';

            const key = `${pop}|||${country}|||${sex}|||${ageGroup}|||${percentile}`;
            if (!groups.has(key)) {
                groups.set(key, {
                    population: pop, country, sex, age_group: ageGroup,
                    percentile, sample_size: sampleSize, data_source: dataSource,
                    measurements: {},
                });
            }
            const g = groups.get(key);
            // First mean wins for each field per group
            if (!(field in g.measurements)) g.measurements[field] = valueMm;
            if (sampleSize && !g.sample_size) g.sample_size = sampleSize;
        }

        if (groups.size === 0) {
            return res.status(400).json({ error: 'No usable mean measurements found in CSV' });
        }

        const genderNorm = s => {
            const l = (s || '').toLowerCase();
            if (l === 'female' || l === 'f') return 'female';
            if (l === 'male'   || l === 'm') return 'male';
            if (l === 'mixed')               return 'mixed';
            return 'other';
        };

        let created = 0, skipped = 0;

        for (const [, g] of groups) {
            const percentileLabel = g.percentile ? `— ${g.percentile}` : '';
            const sexLabel        = g.sex ? ` ${g.sex}` : '';
            const group_name      = `${g.population}${sexLabel} (${g.country})${percentileLabel}`.trim();

            // Idempotency check
            const existing = db.prepare(
                'SELECT id FROM anthropometric_profiles WHERE group_name = ?'
            ).get(group_name);
            if (existing) { skipped++; continue; }

            const meta = {
                group_name,
                country:            g.country    || null,
                gender:             genderNorm(g.sex),
                age_group:          g.age_group  || null,
                percentile:         g.percentile || null,
                sample_size:        g.sample_size || null,
                data_source:        g.data_source || null,
                notes:              'Imported from multi_population_hand.csv',
                measurement_source: 'csv_bulk',
            };

            const result = importer.process({
                format: 'form',
                data:   g.measurements,
                meta,
                default_unit: 'mm',
            });

            const m = result.profile.metadata;
            db.prepare(`
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
            created++;
        }

        res.json({ created, skipped, total_groups: groups.size });
    } catch (err) {
        next(err);
    }
});

// ── DELETE /api/anthropometric/:id ───────────────────────────────────────────

router.delete('/:id', adminOnly, (req, res) => {
    const info = db.prepare(`DELETE FROM anthropometric_profiles WHERE id = ?`)
        .run(parseInt(req.params.id, 10));
    if (info.changes === 0) return res.status(404).json({ error: 'Profile not found' });
    res.json({ ok: true });
});

module.exports = router;
