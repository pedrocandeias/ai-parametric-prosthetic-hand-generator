// @ts-check
'use strict';

// ACC (public) — STRICTLY non-destructive automated WCAG 2.2 A/AA audit of the
// public site's unauthenticated surface only. No login, no data creation or
// modification, no fault injection (protocol §5). Authenticated public journeys
// are intentionally NOT run — no test account is provisioned for production.

const { test } = require('@playwright/test');
const fs = require('fs');
const path = require('path');
const { AxeBuilder } = require('@axe-core/playwright');
const { campaignDir, THESIS_PUBLIC_URL } = require('../helpers/env');
const { writeResult } = require('../helpers/campaign');
const { CHECKLIST } = require('./manual-checklist');

const DIR = campaignDir();
const WCAG_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

test('ACC-PUB · public unauthenticated WCAG 2.2 A/AA audit (non-destructive)', async ({ page }) => {
    test.setTimeout(90000);
    await page.goto('/', { waitUntil: 'domcontentloaded' });
    // Wait for the app shell / login modal to settle without interacting.
    await page.waitForSelector('body', { timeout: 30000 });
    await page.waitForTimeout(1500);

    const results = await new AxeBuilder({ page }).withTags(WCAG_TAGS).analyze();
    const violations = results.violations.map(v => ({
        id: v.id, impact: v.impact, help: v.help, helpUrl: v.helpUrl,
        tags: v.tags.filter(t => t.startsWith('wcag')),
        nodes: v.nodes.map(n => ({ target: n.target, html: n.html.slice(0, 300), failureSummary: n.failureSummary })),
    }));
    const shotDir = path.join(DIR, 'artifacts', 'a11y');
    fs.mkdirSync(shotDir, { recursive: true });
    await page.screenshot({ path: path.join(shotDir, 'ACC-PUB-landing.png') }).catch(() => {});

    writeResult(DIR, 'a11y-public.json', {
        test_id: 'ACC-PUB', tested_url: THESIS_PUBLIC_URL, mode: 'non-destructive, unauthenticated',
        axe_tags: WCAG_TAGS,
        violation_count: violations.length,
        passes: results.passes.length,
        incomplete: results.incomplete.length,
        violations,
        note: 'Public campaign audits the unauthenticated surface only. Absence of violations does NOT authorise a global conformance claim; authenticated journeys were not run in production.',
    });
    writeResult(DIR, 'a11y-manual-checklist.json', CHECKLIST);
    // Never fail the campaign on public violations — evidence is the deliverable,
    // and remediation of a live site is out of this task's scope.
});
