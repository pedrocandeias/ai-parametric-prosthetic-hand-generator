'use strict';

// Campaign evidence utilities: timestamped campaign directory, machine metadata
// capture, structured result writing, an append-only run log, and a SHA-256
// evidence manifest compatible with manifesto_evidencias.csv.
//
// No secret is ever written: metadata records ONLY the presence (boolean) of
// API keys, never their value; environment snapshots are allow-listed.

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');
const { REPO_ROOT } = require('./env');

const MANIFEST_HEADER =
    'evidence_id,campaign_id,test_id,data_hora,caminho,tipo,formato,sha256,gerado_por,descricao,observacoes';

function pad(n) { return String(n).padStart(2, '0'); }

// Local timestamp folder name: AAAA-MM-DD_HH-MM-SS.
function timestampSlug(d = new Date()) {
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}_` +
        `${pad(d.getHours())}-${pad(d.getMinutes())}-${pad(d.getSeconds())}`;
}

function sh(cmd) {
    try { return execSync(cmd, { cwd: REPO_ROOT, encoding: 'utf8' }).trim(); }
    catch { return null; }
}

function sha256File(p) {
    const h = crypto.createHash('sha256');
    h.update(fs.readFileSync(p));
    return h.digest('hex');
}

function sha256String(s) {
    return crypto.createHash('sha256').update(String(s)).digest('hex');
}

// Create the campaign directory (never overwriting a previous campaign).
function createCampaignDir(campaign, root) {
    const base = root || path.join(REPO_ROOT, 'test-results', 'thesis-evaluation');
    let dir = path.join(base, `${timestampSlug()}_${campaign}`);
    let n = 1;
    while (fs.existsSync(dir)) dir = path.join(base, `${timestampSlug()}_${campaign}_${n++}`);
    fs.mkdirSync(path.join(dir, 'artifacts'), { recursive: true });
    fs.mkdirSync(path.join(dir, 'results'), { recursive: true });
    fs.mkdirSync(path.join(dir, 'logs'), { recursive: true });
    return dir;
}

// Capture reproducibility metadata for a campaign. `extra` merges campaign
// specifics (tested_url, environment, ai info, commands, test_ids...).
function captureMetadata(campaign, extra = {}) {
    let playwrightVersion = null;
    try { playwrightVersion = require('@playwright/test/package.json').version; } catch { /* not installed */ }
    let axeVersion = null;
    try { axeVersion = require('axe-core/package.json').version; } catch { /* optional */ }
    let pkgVersion = null;
    try { pkgVersion = require(path.join(REPO_ROOT, 'package.json')).version; } catch { /* n/a */ }

    const status = sh('git status --porcelain');
    const meta = {
        campaign_id: campaign,
        started_at: new Date().toISOString(),
        finished_at: null,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'Europe/Lisbon',
        executor: process.env.THESIS_EXECUTOR || process.env.USER || null,
        platform: {
            repository: REPO_ROOT,
            environment: extra.environment || null,
            tested_url: extra.tested_url || null,
            transport: extra.transport || null,
            branch: sh('git rev-parse --abbrev-ref HEAD'),
            commit: sh('git rev-parse HEAD'),
            working_tree_status: status === '' ? 'clean' : 'dirty',
            working_tree_changes: status ? status.split('\n').length : 0,
            version: pkgVersion,
        },
        environment: {
            operating_system: `${process.platform} ${sh('uname -r') || ''}`.trim(),
            architecture: process.arch,
            node: process.version,
            package_manager: `npm ${sh('npm -v') || '?'}`,
            playwright: playwrightVersion,
            axe_core: axeVersion,
            browsers: extra.browsers || [],
            openscad_wasm: 'in-browser WebAssembly (openscad.wasm, served from repo root)',
        },
        ai: {
            // Presence booleans ONLY — never the key material.
            anthropic_key_present: Boolean(process.env.ANTHROPIC_API_KEY),
            openai_key_present: Boolean(process.env.OPENAI_API_KEY),
            live_ai_enabled: process.env.RUN_LIVE_AI_TESTS === '1',
            provider: extra.ai?.provider || null,
            model_id: extra.ai?.model_id || null,
            sampling_settings: extra.ai?.sampling_settings || {},
            prompt_sha256: extra.ai?.prompt_sha256 || null,
            schema_sha256: extra.ai?.schema_sha256 || null,
        },
        commands: extra.commands || [],
        test_ids: extra.test_ids || [],
        deviations: extra.deviations || [],
        notes: extra.notes || null,
    };
    return meta;
}

function writeMetadata(dir, meta) {
    fs.writeFileSync(path.join(dir, 'metadados.json'), JSON.stringify(meta, null, 2));
}

function finishMetadata(dir) {
    const p = path.join(dir, 'metadados.json');
    if (!fs.existsSync(p)) return;
    const meta = JSON.parse(fs.readFileSync(p, 'utf8'));
    meta.finished_at = new Date().toISOString();
    fs.writeFileSync(p, JSON.stringify(meta, null, 2));
}

// Append a JSON result document under results/.
function writeResult(dir, name, obj) {
    const p = path.join(dir, 'results', name.endsWith('.json') ? name : `${name}.json`);
    fs.writeFileSync(p, JSON.stringify(obj, null, 2));
    return p;
}

// Append-only NDJSON run log.
function logLine(dir, obj) {
    const line = JSON.stringify({ ts: new Date().toISOString(), ...obj });
    fs.appendFileSync(path.join(dir, 'logs', 'run.ndjson'), line + '\n');
}

// Build the SHA-256 evidence manifest by walking the campaign directory.
// `campaignId` labels rows. `describe(relPath)` may return {test_id, tipo,
// descricao, observacoes, gerado_por} overrides.
function buildManifest(dir, campaignId, describe = () => ({})) {
    const rows = [MANIFEST_HEADER];
    const now = new Date().toISOString();
    let i = 0;
    const walk = (d) => {
        for (const name of fs.readdirSync(d).sort()) {
            const full = path.join(d, name);
            const st = fs.statSync(full);
            if (st.isDirectory()) { walk(full); continue; }
            const rel = path.relative(dir, full);
            if (rel === 'manifesto_evidencias.csv') continue; // don't hash self
            const info = describe(rel) || {};
            // Infer the test id from the path when the describer didn't supply one
            // (e.g. artifacts/REP-DET-001/run-00.stl → REP-DET-001).
            const inferred = (rel.match(/(REP|ROB|ACC)-[A-Z]+-\d+/) || [])[0] || '';
            const ext = path.extname(name).slice(1).toLowerCase() || 'bin';
            const evidenceId = `${campaignId}-${String(++i).padStart(4, '0')}`;
            const cell = (v) => {
                const s = v == null ? '' : String(v);
                return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
            };
            rows.push([
                evidenceId,
                campaignId,
                info.test_id || inferred,
                now,
                rel,
                info.tipo || classifyType(rel),
                ext,
                sha256File(full),
                info.gerado_por || 'automated',
                info.descricao || '',
                info.observacoes || '',
            ].map(cell).join(','));
        }
    };
    walk(dir);
    const out = path.join(dir, 'manifesto_evidencias.csv');
    fs.writeFileSync(out, rows.join('\n') + '\n');
    return out;
}

function classifyType(rel) {
    if (rel.startsWith('results/')) return 'resultado';
    if (rel.startsWith('logs/')) return 'log';
    if (/\.(stl|3mf)$/i.test(rel)) return 'geometria';
    if (/\.png$/i.test(rel)) return 'captura';
    if (/\.(webm|mp4)$/i.test(rel)) return 'video';
    if (/\.zip$/i.test(rel)) return 'trace';
    if (/\.html$/i.test(rel)) return 'relatorio';
    if (rel === 'metadados.json') return 'metadados';
    if (/frozen|config/i.test(rel)) return 'configuracao';
    return 'artefacto';
}

module.exports = {
    timestampSlug,
    createCampaignDir,
    captureMetadata,
    writeMetadata,
    finishMetadata,
    writeResult,
    logLine,
    buildManifest,
    sha256File,
    sha256String,
    MANIFEST_HEADER,
};
