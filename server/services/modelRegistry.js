'use strict';

/**
 * modelRegistry — single source of truth for the list of parametric models.
 *
 * Merges the repository models (models/models-config.json, shipped by deploys)
 * with admin-added models (custom_models table + files in data/models/<id>/,
 * which deploys never touch). Every server path that needs model definitions
 * (config validation, AI grounding, profile clamping) goes through here, so a
 * model added in the admin panel is usable without a server restart.
 */

const path = require('path');
const fs = require('fs');
const { z } = require('zod');
const db = require('../db');

const REPO_CONFIG_PATH = path.join(__dirname, '..', '..', 'models', 'models-config.json');
const CUSTOM_DIR = path.join(db.DATA_DIR, 'models');

const ID_RE = /^[a-z0-9][a-z0-9_-]{1,59}$/;
const FILE_RE = /^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$/;
const ALLOWED_EXT = { '.scad': 'text/plain; charset=utf-8', '.stl': 'application/octet-stream', '.dxf': 'text/plain; charset=utf-8', '.svg': 'text/plain; charset=utf-8' };
const MAX_FILE_BYTES = 5 * 1024 * 1024;
const MAX_FILES = 30;

// ── Repository models (cached until the file changes) ────────────────────────

let _repo = { mtimeMs: -1, models: [] };
function getRepoModels() {
    try {
        const { mtimeMs } = fs.statSync(REPO_CONFIG_PATH);
        if (mtimeMs !== _repo.mtimeMs) {
            const cfg = JSON.parse(fs.readFileSync(REPO_CONFIG_PATH, 'utf8'));
            _repo = { mtimeMs, models: (cfg.models || []).map(m => ({ ...m, source: 'repo' })) };
        }
    } catch {
        _repo = { mtimeMs: -1, models: [] };
    }
    return _repo.models;
}

// ── Custom models ───────────────────────────────────────────────────────────

function decorateCustom(row) {
    let def;
    try { def = JSON.parse(row.definition); } catch { return null; }
    const files = listFiles(row.id).map(f => f.name);
    return {
        ...def,
        id: row.id,
        source: 'custom',
        draft: !row.enabled,
        // The client fetches model files relative to assetBase instead of models/.
        assetBase: `/api/models/files/${row.id}/`,
        dependencies: files.filter(f => f !== def.file).map(f => ({ url: f, path: f })),
    };
}

function getCustomRows() {
    return db.prepare(`SELECT * FROM custom_models ORDER BY created_at`).all();
}

/** All models. Drafts (disabled custom models) only when includeDrafts. */
function getModels({ includeDrafts = false } = {}) {
    const custom = getCustomRows()
        .filter(r => includeDrafts || r.enabled)
        .map(decorateCustom)
        .filter(Boolean);
    return [...getRepoModels(), ...custom];
}

/** One model by id — drafts included, so admins can save configs while testing. */
function getModel(id) {
    if (!id) return null;
    const repo = getRepoModels().find(m => m.id === id);
    if (repo) return repo;
    const row = db.prepare(`SELECT * FROM custom_models WHERE id = ?`).get(id);
    return row ? decorateCustom(row) : null;
}

function isRepoModel(id) {
    return getRepoModels().some(m => m.id === id);
}

// ── Files ───────────────────────────────────────────────────────────────────

function modelDir(id) {
    if (!ID_RE.test(id)) throw new Error('Invalid model id');
    return path.join(CUSTOM_DIR, id);
}

function isValidFileName(name) {
    return FILE_RE.test(name) && !name.includes('..') && Object.prototype.hasOwnProperty.call(ALLOWED_EXT, path.extname(name).toLowerCase());
}

function filePath(id, name) {
    if (!isValidFileName(name)) throw new Error('Invalid file name');
    return path.join(modelDir(id), name);
}

function contentType(name) {
    return ALLOWED_EXT[path.extname(name).toLowerCase()];
}

function listFiles(id) {
    let dir;
    try { dir = modelDir(id); } catch { return []; }
    if (!fs.existsSync(dir)) return [];
    return fs.readdirSync(dir)
        .filter(isValidFileName)
        .map(name => ({ name, size: fs.statSync(path.join(dir, name)).size }))
        .sort((a, b) => a.name.localeCompare(b.name));
}

function writeFile(id, name, buffer) {
    fs.mkdirSync(modelDir(id), { recursive: true });
    fs.writeFileSync(filePath(id, name), buffer);
}

function deleteFile(id, name) {
    const p = filePath(id, name);
    if (fs.existsSync(p)) fs.unlinkSync(p);
}

function removeModelDir(id) {
    fs.rmSync(modelDir(id), { recursive: true, force: true });
}

// ── Definition validation ───────────────────────────────────────────────────

// Admin text ends up in the configurator UI; plain text only.
const text = (max) => z.string().max(max).refine(s => !/[<>]/.test(s), { message: 'HTML is not allowed in model text' });
const scalar = z.union([z.number(), z.string().max(200), z.boolean()]);

const paramSchema = z.object({
    name: z.string().regex(/^[A-Za-z_][A-Za-z0-9_]{0,79}$/, 'Parameter names must be valid OpenSCAD identifiers'),
    type: z.enum(['number', 'boolean', 'enum', 'color', 'string']),
    initial: scalar,
    min: z.number().optional(),
    max: z.number().optional(),
    step: z.number().positive().optional(),
    options: z.array(z.object({ label: text(120), value: scalar }).passthrough()).max(100).optional(),
    role: z.enum(['laterality']).optional(),
    group: text(80).optional(),
    label: text(120).optional(),
    label_pt: text(120).optional(),
    caption: text(500).optional(),
    caption_pt: text(500).optional(),
    help: text(2000).optional(),
    help_pt: text(2000).optional(),
}).passthrough().superRefine((p, ctx) => {
    const bad = (message) => ctx.addIssue({ code: z.ZodIssueCode.custom, message: `${p.name}: ${message}` });
    if (p.type === 'number') {
        if (typeof p.initial !== 'number') bad('initial value must be a number');
        if (p.min !== undefined && p.max !== undefined && p.min > p.max) bad('min is greater than max');
        if (typeof p.initial === 'number' && ((p.min !== undefined && p.initial < p.min) || (p.max !== undefined && p.initial > p.max))) bad('initial value is outside min–max');
    }
    if (p.type === 'boolean' && typeof p.initial !== 'boolean') bad('initial value must be true or false');
    if (p.type === 'color' && !/^#[0-9a-f]{3,8}$/i.test(String(p.initial))) bad('initial value must be a #hex colour');
    if (p.type === 'enum') {
        if (!p.options || !p.options.length) bad('a dropdown needs options');
        else if (!p.options.some(o => o.value === p.initial)) bad('initial value is not one of the options');
    }
});

const definitionSchema = z.object({
    name: text(120).refine(s => s.trim().length > 0, { message: 'Model name is required' }),
    name_pt: text(120).optional(),
    description: text(4000).optional(),
    description_pt: text(4000).optional(),
    file: z.string().refine(isValidFileName, { message: 'Main file must be a .scad file name' })
        .refine(f => f.toLowerCase().endsWith('.scad'), { message: 'Main file must be a .scad file' }),
    limb: z.string().max(40).optional(),
    renderBackend: z.enum(['manifold', 'cgal']).optional(),
    exportLayout: z.record(z.any()).optional(),
    aiGuidance: z.string().max(4000).optional(),
    renderCall: z.string().max(500).optional(),
    parts: z.array(z.object({
        id: z.string().max(60),
        name: text(120),
        toggles: z.array(z.string().max(80)).max(20),
    }).passthrough()).max(60).optional(),
    parameters: z.array(paramSchema).min(1, 'At least one parameter is required').max(400),
}).passthrough().superRefine((d, ctx) => {
    const names = new Set();
    for (const p of d.parameters) {
        if (names.has(p.name)) ctx.addIssue({ code: z.ZodIssueCode.custom, message: `Duplicate parameter: ${p.name}` });
        names.add(p.name);
    }
});

/** Validate a definition; strips fields the server owns. Returns zod result. */
function validateDefinition(def) {
    const result = definitionSchema.safeParse(def);
    if (!result.success) return result;
    const clean = { ...result.data };
    for (const k of ['id', 'source', 'draft', 'assetBase', 'dependencies']) delete clean[k];
    return { success: true, data: clean };
}

module.exports = {
    getModels,
    getModel,
    getRepoModels,
    isRepoModel,
    listFiles,
    writeFile,
    deleteFile,
    removeModelDir,
    filePath,
    contentType,
    isValidFileName,
    validateDefinition,
    ID_RE,
    MAX_FILE_BYTES,
    MAX_FILES,
};
