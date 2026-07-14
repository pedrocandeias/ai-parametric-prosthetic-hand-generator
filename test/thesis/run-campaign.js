#!/usr/bin/env node
'use strict';

// Thesis campaign orchestrator.
//
//   node test/thesis/run-campaign.js <campaign>
//
// campaigns: repetition | robustness | a11y-local | a11y-public | ai-live
//
// Responsibilities:
//   1. create a fresh, non-overwriting campaign directory
//   2. seed an isolated synthetic DB (for local campaigns)
//   3. capture reproducibility metadata (metadados.json) — no secrets
//   4. copy the frozen configs into the campaign
//   5. run the appropriate Playwright projects/specs, writing evidence into it
//   6. finalise metadata and build the SHA-256 evidence manifest
//   7. print an exact command / pass / fail / exclusion summary
//
// It NEVER runs git commit/push or deploy, and never prints secrets.

const path = require('path');
const fs = require('fs');
const { spawnSync } = require('child_process');

// Load .env so the (optional, gated) live-AI suite can reach a provider. Keys
// are only ever forwarded to the child server when RUN_LIVE_AI_TESTS=1.
try { require('dotenv').config(); } catch { /* dotenv optional */ }

const {
    REPO_ROOT, THESIS_PORT, THESIS_LOCAL_URL, THESIS_PUBLIC_URL, RUN_LIVE_AI_TESTS,
} = require('./helpers/env');
const {
    createCampaignDir, captureMetadata, writeMetadata, finishMetadata, buildManifest,
} = require('./helpers/campaign');
const { seed } = require('./helpers/seed');

const CONFIG = path.join(__dirname, 'playwright.thesis.config.js');
const DB_PATH = path.join(REPO_ROOT, 'data', 'thesis-test.db');

const CAMPAIGNS = {
    repetition: {
        label: 'repetition',
        // Two separate Playwright processes: the heavy REP-DET/REP-AI renders,
        // then a memory-clean process for the cross-browser comparison (so it is
        // not falsely classified as incompatible after REP-DET's render load).
        steps: [
            { specs: ['test/thesis/repetition/rep-det.spec.js', 'test/thesis/repetition/rep-ai-mock.spec.js'], projects: ['chromium'] },
            { specs: ['test/thesis/repetition/rep-xbr.spec.js'], projects: ['chromium', 'firefox', 'webkit'] },
        ],
        projects: ['chromium', 'firefox', 'webkit'],
        browsers: ['chromium', 'firefox', 'webkit'],
        server: true,
        environment: 'local',
        tested_url: THESIS_LOCAL_URL,
        test_ids: ['REP-DET-001', 'REP-DET-002', 'REP-DET-003', 'REP-XBR-001', 'REP-AI-001', 'REP-AI-002', 'REP-AI-003'],
    },
    robustness: {
        label: 'robustness',
        specs: ['test/thesis/robustness'],
        projects: ['chromium'],
        browsers: ['chromium'],
        server: true,
        environment: 'local',
        tested_url: THESIS_LOCAL_URL,
        test_ids: ['ROB-NOM-001', 'ROB-LIM-001', 'ROB-LIM-002', 'ROB-INV-001', 'ROB-INV-002', 'ROB-INV-003', 'ROB-INV-004', 'ROB-CON-001', 'ROB-COV-001', 'ROB-MOD-001', 'ROB-SRV-001', 'ROB-SRV-002', 'ROB-REN-001', 'ROB-EXP-001'],
    },
    'a11y-local': {
        label: 'a11y-local',
        specs: ['test/thesis/a11y/a11y-local.spec.js'],
        projects: ['chromium'],
        browsers: ['chromium'],
        server: true,
        environment: 'local',
        tested_url: THESIS_LOCAL_URL,
        test_ids: ['ACC-AUT-001', 'ACC-AUT-002', 'ACC-AUT-003', 'ACC-AUT-004', 'ACC-AUT-005', 'ACC-AUT-006'],
    },
    'a11y-public': {
        label: 'a11y-public',
        specs: ['test/thesis/a11y/a11y-public.spec.js'],
        projects: ['public'],
        browsers: ['chromium'],
        server: false,
        environment: 'public',
        tested_url: THESIS_PUBLIC_URL,
        test_ids: ['ACC-AUT-001'],
    },
    'ai-live': {
        label: 'ai-live',
        specs: ['test/thesis/repetition/rep-ai-live.spec.js'],
        projects: ['chromium'],
        browsers: ['chromium'],
        server: true,
        environment: 'local',
        tested_url: THESIS_LOCAL_URL,
        requiresLive: true,
        test_ids: ['REP-AI-001', 'REP-AI-002', 'REP-AI-003'],
    },
};

async function main() {
    const campaign = process.argv[2];
    const spec = CAMPAIGNS[campaign];
    if (!spec) {
        console.error(`Unknown campaign "${campaign}". Options: ${Object.keys(CAMPAIGNS).join(', ')}`);
        process.exit(2);
    }
    if (spec.requiresLive && !RUN_LIVE_AI_TESTS) {
        console.error('Refusing to run the live-AI campaign: set RUN_LIVE_AI_TESTS=1 to opt in to paid provider calls.');
        process.exit(2);
    }

    const dir = createCampaignDir(campaign);
    console.log(`\n▶ Campaign "${campaign}" → ${path.relative(REPO_ROOT, dir)}\n`);

    // Free the isolated test port (3100) of any zombie server from a previous
    // interrupted run so the browsers always hit THIS campaign's fresh server on
    // the freshly-seeded synthetic DB. Only ever touches THESIS_PORT — never 3000.
    if (spec.server) {
        try {
            const pids = require('child_process')
                .execSync(`lsof -ti:${THESIS_PORT} || true`, { encoding: 'utf8' }).trim();
            if (pids) {
                pids.split(/\s+/).forEach(pid => { try { process.kill(Number(pid), 'SIGKILL'); } catch { /* gone */ } });
                console.log(`  cleared stale process(es) on port ${THESIS_PORT}: ${pids.replace(/\s+/g, ', ')}`);
            }
        } catch { /* lsof unavailable — Playwright webServer will still detect a busy port */ }
    }

    // Seed isolated synthetic DB for local campaigns.
    if (spec.server) {
        const res = await seed(DB_PATH);
        console.log(`  seeded isolated DB: users=${res.users} profiles=${res.profiles} (${path.relative(REPO_ROOT, DB_PATH)})`);
    }

    // Freeze the frozen configs into the campaign (provenance).
    const frozenSrc = path.join(__dirname, 'fixtures', 'frozen-configs.json');
    fs.copyFileSync(frozenSrc, path.join(dir, 'frozen-configs.json'));

    // A campaign is one or more Playwright invocations ("steps").
    const steps = spec.steps || [{ specs: spec.specs, projects: spec.projects }];
    const cmds = steps.map(s => [
        'npx playwright test', ...s.specs,
        `--config ${path.relative(REPO_ROOT, CONFIG)}`,
        ...s.projects.map(p => `--project ${p}`),
    ].join(' '));
    const cmd = cmds.join('\n');

    const meta = captureMetadata(campaign, {
        environment: spec.environment,
        tested_url: spec.tested_url,
        transport: spec.tested_url.startsWith('https') ? 'https' : 'http',
        browsers: spec.browsers,
        commands: [cmd],
        test_ids: spec.test_ids,
        deviations: spec.server ? [
            `Local campaigns run against an isolated synthetic DB on port ${THESIS_PORT} (HANDFAB_DB_PATH=data/thesis-test.db), not the developer :3000 instance, to satisfy the "isolated DB + synthetic data" requirement.`,
        ] : [
            'Public campaign is strictly non-destructive: no authentication, no data creation/modification.',
        ],
        ai: spec.requiresLive ? { provider: 'anthropic', model_id: 'claude-sonnet-4-6', sampling_settings: { max_tokens: 1024 } } : {},
    });
    writeMetadata(dir, meta);

    // One-time-login session cookie: a temp file OUTSIDE the evidence dir
    // (never an artefact), deleted after the campaign.
    const statePath = path.join(require('os').tmpdir(), `handfab-thesis-auth-${campaign}-${process.pid}.json`);

    // Environment for the Playwright child.
    const env = {
        ...process.env,
        CAMPAIGN_DIR: dir,
        THESIS_PORT: String(THESIS_PORT),
        HANDFAB_DB_PATH: DB_PATH,
        THESIS_NO_SERVER: spec.server ? '' : '1',
        THESIS_STORAGE_STATE: statePath,
    };

    console.log(`  command:\n    ${cmds.join('\n    ')}\n`);
    const started = Date.now();
    let worstStatus = 0;
    for (const s of steps) {
        const run = spawnSync('npx', ['playwright', 'test',
            ...s.specs,
            '--config', CONFIG,
            ...s.projects.flatMap(p => ['--project', p]),
        ], { cwd: REPO_ROOT, env, stdio: 'inherit' });
        if (run.status) worstStatus = run.status;
    }
    const run = { status: worstStatus };
    const durationS = Math.round((Date.now() - started) / 1000);

    if (campaign === 'repetition') aggregateXbr(dir);

    // Remove the session-cookie state file so no credential lingers.
    try { if (fs.existsSync(statePath)) fs.unlinkSync(statePath); } catch { /* best effort */ }

    finishMetadata(dir);
    const manifest = buildManifest(dir, campaign);

    console.log(`\n  duration: ${durationS}s`);
    console.log(`  manifest: ${path.relative(REPO_ROOT, manifest)}`);
    console.log(`  evidence: ${path.relative(REPO_ROOT, dir)}`);
    console.log(`  playwright exit code: ${run.status}`);
    // Do not mask failures: exit non-zero if Playwright failed, but the evidence
    // (including failures) is fully preserved above.
    process.exit(run.status || 0);
}

// Aggregate the per-browser REP-XBR metric files into one equivalence
// classification against the Chromium reference (protocol §6.2).
function aggregateXbr(dir) {
    const { compareAnalyses } = require('./helpers/stlMetrics');
    const { GEOMETRY_TOL_MM } = require('./helpers/env');
    const resultsDir = path.join(dir, 'results');
    if (!fs.existsSync(resultsDir)) return;
    // Per-browser files only — exclude the aggregated xbr-comparison.json itself
    // (matters when the aggregation is re-run over an existing evidence dir).
    const files = fs.readdirSync(resultsDir).filter(f => /^xbr-.*\.json$/.test(f) && f !== 'xbr-comparison.json');
    if (!files.length) return;
    const byBrowser = {};
    for (const f of files) {
        const d = JSON.parse(fs.readFileSync(path.join(resultsDir, f), 'utf8'));
        byBrowser[d.browser] = d;
    }
    const ref = byBrowser.chromium && byBrowser.chromium.status === 'ok' ? byBrowser.chromium.metrics : null;
    const comparison = {
        test_id: 'REP-XBR-001',
        reference_browser: ref ? 'chromium' : null,
        tolerance_mm: GEOMETRY_TOL_MM,
        browsers: {},
    };
    for (const [browser, d] of Object.entries(byBrowser)) {
        // Neutral: report non-completion with the phase + error, no causal claim.
        if (d.status !== 'ok') { comparison.browsers[browser] = { classification: 'not_completed', phase: d.phase, error: d.error }; continue; }
        if (!ref) { comparison.browsers[browser] = { classification: 'no_reference', metrics: d.metrics }; continue; }
        const cmp = compareAnalyses(ref, d.metrics, GEOMETRY_TOL_MM);
        // Map the geometry class to the protocol §6.2 vocabulary.
        const map = {
            identical: 'serialization_identical',
            serialization_only: 'serialization_difference_no_geometry_change',
            within_tolerance: 'geometry_difference_within_tolerance',
            out_of_tolerance: 'geometry_difference_out_of_tolerance',
        };
        comparison.browsers[browser] = { classification: map[cmp.geometry_class] || cmp.geometry_class, deltas: cmp.deltas };
    }
    fs.writeFileSync(path.join(resultsDir, 'xbr-comparison.json'), JSON.stringify(comparison, null, 2));
    console.log(`  cross-browser comparison written (${Object.keys(byBrowser).join(', ')})`);
}

main().catch(err => { console.error('Campaign runner error:', err); process.exit(1); });
