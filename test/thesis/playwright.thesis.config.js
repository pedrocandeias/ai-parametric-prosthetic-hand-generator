// @ts-check
'use strict';

// Playwright configuration for the thesis evaluation campaigns. Kept separate
// from the repo's archive playwright.config.js so it never mixes with the
// existing model tests. Evidence is written under CAMPAIGN_DIR (set by the
// campaign runner); a stray direct run falls back to a scratch folder.

const path = require('path');
const { defineConfig, devices } = require('@playwright/test');
const {
    THESIS_LOCAL_URL, THESIS_PUBLIC_URL, THESIS_PORT, THESIS_JWT_SECRET, campaignDir,
} = require('./helpers/env');

const CAMPAIGN = campaignDir();
const NO_SERVER = process.env.THESIS_NO_SERVER === '1';
const LIVE_AI = process.env.RUN_LIVE_AI_TESTS === '1';
const DB_PATH = process.env.HANDFAB_DB_PATH
    || path.join(__dirname, '..', '..', 'data', 'thesis-test.db');

module.exports = defineConfig({
    testDir: __dirname,
    // Only spec files under this config's projects; helpers/fixtures ignored.
    testMatch: ['**/*.spec.js'],
    outputDir: path.join(CAMPAIGN, 'artifacts', 'pw-output'),
    fullyParallel: false,     // deterministic ordering; the render pipeline is heavy
    workers: 1,               // one browser at a time — WASM render is CPU-bound
    timeout: 360000,          // up to 6 min per test (10x render+export)
    expect: { timeout: 20000 },
    retries: 0,               // preserve real failures; never mask flakiness
    forbidOnly: true,
    reporter: [
        ['list'],
        ['html', { open: 'never', outputFolder: path.join(CAMPAIGN, 'playwright-report') }],
        ['json', { outputFile: path.join(CAMPAIGN, 'results', 'playwright-results.json') }],
    ],
    use: {
        baseURL: THESIS_LOCAL_URL,
        headless: true,
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
        trace: 'retain-on-failure',
        actionTimeout: 60000,
        navigationTimeout: 60000,
    },
    projects: [
        // Primary local browser — runs repetition, robustness and a11y-local.
        // --disable-dev-shm-usage is Chromium-ONLY (it is not a valid Firefox or
        // WebKit launch flag; applying it globally previously broke WebKit launch,
        // which is a harness-config fault, not a platform incompatibility).
        {
            name: 'chromium',
            use: {
                ...devices['Desktop Chrome'], baseURL: THESIS_LOCAL_URL,
                launchOptions: { args: ['--disable-dev-shm-usage'] },
            },
        },
        // Cross-browser reproducibility (REP-XBR) ONLY.
        {
            name: 'firefox',
            testMatch: '**/rep-xbr.spec.js',
            use: { ...devices['Desktop Firefox'], baseURL: THESIS_LOCAL_URL },
        },
        {
            name: 'webkit',
            testMatch: '**/rep-xbr.spec.js',
            use: { ...devices['Desktop Safari'], baseURL: THESIS_LOCAL_URL },
        },
        // Public, non-destructive a11y audit — different baseURL, no local server.
        {
            name: 'public',
            testMatch: '**/a11y-public.spec.js',
            use: { ...devices['Desktop Chrome'], baseURL: THESIS_PUBLIC_URL },
        },
    ],
    // Isolated local server on a dedicated port + synthetic DB. Skipped for
    // public-only campaigns (THESIS_NO_SERVER=1).
    webServer: NO_SERVER ? undefined : {
        command: 'node server/index.js',
        cwd: path.join(__dirname, '..', '..'),
        url: `${THESIS_LOCAL_URL}/api/setup/status`,
        reuseExistingServer: false,
        timeout: 30000,
        env: {
            PORT: String(THESIS_PORT),
            HANDFAB_DB_PATH: DB_PATH,
            JWT_SECRET: process.env.JWT_SECRET && process.env.JWT_SECRET.length >= 32
                ? process.env.JWT_SECRET : THESIS_JWT_SECRET,
            NODE_ENV: 'test',
            // Isolated test server only: lift the login cap so per-run cold-start
            // logins are not throttled. Production leaves this unset (cap = 5).
            LOGIN_RATE_LIMIT_MAX: '100000',
            // Provider keys are forwarded to the isolated server ONLY when the
            // paid live-AI suite is explicitly enabled. Every other campaign runs
            // the server key-less, so an accidental /api/ai/suggest returns 503
            // instead of spending money.
            ANTHROPIC_API_KEY: LIVE_AI ? (process.env.ANTHROPIC_API_KEY || '') : '',
            OPENAI_API_KEY: LIVE_AI ? (process.env.OPENAI_API_KEY || '') : '',
        },
    },
});
