// @ts-check
'use strict';

// ACC-AUT-* (local, isolated HTTP) — automated WCAG 2.2 A/AA audit with
// @axe-core/playwright across authentication, dashboard, profile, model
// configuration, AI-suggestion states and the 3D viewer. Violations are
// preserved with rule, impact, affected element, selector and help. A manual
// checklist is emitted for what automation cannot decide. Zero automated
// violations does NOT establish global conformance (protocol §6.5).

const { test } = require('../helpers/testBase');
const fs = require('fs');
const path = require('path');
const { AxeBuilder } = require('@axe-core/playwright');
const po = require('../helpers/pageObjects');
const ai = require('../helpers/aiSchema');
const { campaignDir } = require('../helpers/env');
const { writeResult } = require('../helpers/campaign');
const { CHECKLIST } = require('./manual-checklist');

const DIR = campaignDir();
const WCAG_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];
const summary = [];

const shotDir = path.join(DIR, 'artifacts', 'a11y');

async function audit(page, testId, state) {
    fs.mkdirSync(shotDir, { recursive: true });
    const results = await new AxeBuilder({ page }).withTags(WCAG_TAGS).analyze();
    const violations = results.violations.map(v => ({
        id: v.id, impact: v.impact, help: v.help, helpUrl: v.helpUrl,
        tags: v.tags.filter(t => t.startsWith('wcag')),
        nodes: v.nodes.map(n => ({ target: n.target, html: n.html.slice(0, 300), failureSummary: n.failureSummary })),
    }));
    const shot = path.join(shotDir, `${testId}-${state}.png`);
    await page.screenshot({ path: shot, fullPage: false }).catch(() => {});
    const rec = {
        test_id: testId, state, tags: WCAG_TAGS,
        violation_count: violations.length,
        passes: results.passes.length,
        incomplete: results.incomplete.length,
        violations,
    };
    writeResult(DIR, path.join('acc', `${testId}-${state}.json`).replace(/[\\/]/g, '__'), rec);
    summary.push({ test_id: testId, state, violations: violations.length, incomplete: results.incomplete.length });
    return rec;
}

test.describe.configure({ mode: 'serial' });

test.describe('ACC · local automated WCAG 2.2 A/AA audit', () => {

    test.afterAll(async () => {
        writeResult(DIR, 'a11y-local-summary.json', {
            note: 'Automated axe-core coverage only. Absence of violations does NOT authorise a global conformance claim.',
            axe_tags: WCAG_TAGS,
            states: summary,
            total_violations: summary.reduce((a, s) => a + s.violations, 0),
        });
        writeResult(DIR, 'a11y-manual-checklist.json', CHECKLIST);
    });

    test('ACC-AUT-001 · authentication (unauthenticated login)', async ({ page, context }) => {
        // Force the unauthenticated state regardless of the shared storageState.
        await context.clearCookies();
        await page.addInitScript(() => { try { localStorage.clear(); sessionStorage.clear(); } catch {} });
        await page.goto('/');
        await page.waitForSelector('#login-form', { timeout: 20000 });
        await audit(page, 'ACC-AUT-001', 'login');
    });

    test('ACC-AUT-002 · dashboard (authenticated)', async ({ authedPage: page }) => {
        await po.login(page);
        await page.waitForSelector('#screen-selection.active');
        await audit(page, 'ACC-AUT-002', 'dashboard');
    });

    test('ACC-AUT-003 · profile (initial + error state)', async ({ authedPage: page }) => {
        await po.login(page);
        await page.click('#user-menu-toggle');
        await page.click('#user-menu-profile');
        await page.waitForSelector('#screen-profile.active', { timeout: 20000 });
        await audit(page, 'ACC-AUT-003', 'initial');
        // Provoke an error state: try to save a password change with mismatch.
        await page.fill('#profile-new-pw', 'abc12345').catch(() => {});
        await page.fill('#profile-confirm-pw', 'different').catch(() => {});
        await page.click('#profile-save-pw-btn').catch(() => {});
        await page.waitForTimeout(500);
        await audit(page, 'ACC-AUT-003', 'error');
    });

    test('ACC-AUT-004 · model configuration (parameter controls)', async ({ authedPage: page }) => {
        await po.login(page);
        await po.openModel(page, 'flexy_beast');
        await page.click('[data-tab="params"]');
        await audit(page, 'ACC-AUT-004', 'params');
    });

    test('ACC-AUT-005 · AI suggestion (before + after, mocked)', async ({ authedPage: page }) => {
        await po.login(page);
        await po.openModel(page, 'flexy_beast');
        await page.click('[data-tab="ai"]');
        await audit(page, 'ACC-AUT-005', 'before');
        // Apply a mocked suggestion (no provider call) and audit the result state.
        await page.fill('#anthropometric-input', 'Synthetic adult.');
        await ai.mockAISuggest(page, ai.mockResponses('flexy_beast').valid);
        await page.click('#ai-suggest-btn');
        await page.waitForTimeout(1500);
        await audit(page, 'ACC-AUT-005', 'after');
        await page.unroute('**/api/ai/suggest').catch(() => {});
    });

    test('ACC-AUT-006 · 3D viewer (rendered geometry)', async ({ authedPage: page }, testInfo) => {
        testInfo.setTimeout(180000);
        await po.login(page);
        await po.openModel(page, 'flexy_beast');
        await po.setParam(page, 'palm_breadth_mm', 83);
        try { await po.render(page, 120000); } catch { /* audit whatever state exists */ }
        const rec = await audit(page, 'ACC-AUT-006', 'rendered');
        // Note the 3D-alternative concern for the manual checklist.
        rec.note = 'The <model-viewer> canvas is non-text; the parametric alternative (control values + status text) is verified manually — see MAN-3D-ALT.';
    });
});
