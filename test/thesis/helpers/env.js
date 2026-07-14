'use strict';

// Central configuration for the thesis evaluation campaigns. Every knob is an
// environment variable so a campaign is fully described by its command line and
// captured verbatim into metadados.json. Nothing here reads secrets.

const path = require('path');
const os = require('os');

const REPO_ROOT = path.join(__dirname, '..', '..', '..');

// Where the one-time authenticated storageState lives. Deliberately OUTSIDE the
// evidence directory: it contains a session refresh cookie, and requirement #6
// forbids secrets/cookies in any artefact. A single login is reused across tests
// so the login rate limiter (5/15min) never throttles a campaign.
function storageStatePath() {
    return process.env.THESIS_STORAGE_STATE
        || path.join(os.tmpdir(), 'handfab-thesis-auth.json');
}

// Isolated local server for functional / repetition / robustness / a11y-local.
// Deliberately HTTP and a dedicated port + synthetic DB so it never collides
// with a developer's running instance on :3000 or touches production data.
const THESIS_PORT = Number(process.env.THESIS_PORT || 3100);
const THESIS_LOCAL_URL = process.env.THESIS_LOCAL_URL || `http://localhost:${THESIS_PORT}`;

// Public environment — read-only, non-destructive checks only.
const THESIS_PUBLIC_URL = process.env.THESIS_PUBLIC_URL || 'https://handfab.pedrocandeias.net';

// Synthetic test admin (created by seed.js in the isolated DB). NOT a real
// account. The password is a throwaway used only against the local synthetic DB.
const THESIS_ADMIN = {
    username: process.env.THESIS_ADMIN_USER || 'thesis_admin',
    email: process.env.THESIS_ADMIN_EMAIL || 'thesis_admin@example.invalid',
    password: process.env.THESIS_ADMIN_PASSWORD || 'thesis-synthetic-pw-0000',
};

// Test-only JWT secret (≥32 chars) for the isolated server. Not a production
// secret; it only signs tokens for the synthetic DB.
const THESIS_JWT_SECRET =
    process.env.THESIS_JWT_SECRET || 'thesis-evaluation-isolated-jwt-secret-000000';

// Number of deterministic repetitions per case (protocol: at least ten).
const REP_RUNS = Math.max(1, Number(process.env.THESIS_REP_RUNS || 10));

// Number of repeated LIVE AI calls per scenario (only used when explicitly
// enabled). Kept modest to bound paid-API spend; still ≥ protocol minimum.
const AI_LIVE_RUNS = Math.max(1, Number(process.env.THESIS_AI_LIVE_RUNS || 10));

// Paid live-AI tests are OFF unless this is exactly '1'.
const RUN_LIVE_AI_TESTS = process.env.RUN_LIVE_AI_TESTS === '1';

// Pre-declared geometric tolerance for cross-run / cross-browser comparison
// (millimetres, on bounding-box dimensions). MUST be fixed before observing
// results — see protocol §6.1. Overridable only to widen for a documented reason.
const GEOMETRY_TOL_MM = Number(process.env.THESIS_GEOMETRY_TOL_MM || 0.05);

// Where campaign evidence is written. The runner sets CAMPAIGN_DIR; specs and
// helpers read it. Falls back to a scratch path so a stray direct run is safe.
function campaignDir() {
    return process.env.CAMPAIGN_DIR
        || path.join(REPO_ROOT, 'test-results', 'thesis-evaluation', 'adhoc');
}

module.exports = {
    REPO_ROOT,
    THESIS_PORT,
    THESIS_LOCAL_URL,
    THESIS_PUBLIC_URL,
    THESIS_ADMIN,
    THESIS_JWT_SECRET,
    REP_RUNS,
    AI_LIVE_RUNS,
    RUN_LIVE_AI_TESTS,
    GEOMETRY_TOL_MM,
    campaignDir,
    storageStatePath,
};
