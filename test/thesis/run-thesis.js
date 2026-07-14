#!/usr/bin/env node
'use strict';

// Aggregate thesis runner: executes the non-paid, non-destructive campaigns in
// sequence and prints a combined summary. Deliberately EXCLUDES:
//   - the live/paid AI suite (ai-live) — opt-in only via test:thesis:ai:live
//   - any authenticated or fault-injecting run against production
// Each campaign is a separate evidence directory; failures are preserved, not
// masked. A non-zero exit reflects that at least one campaign had test failures.

const { spawnSync } = require('child_process');
const path = require('path');

const CAMPAIGNS = ['repetition', 'robustness', 'a11y-local', 'a11y-public'];
const runner = path.join(__dirname, 'run-campaign.js');

const results = [];
for (const c of CAMPAIGNS) {
    console.log(`\n${'='.repeat(70)}\n  THESIS CAMPAIGN: ${c}\n${'='.repeat(70)}`);
    const r = spawnSync('node', [runner, c], { stdio: 'inherit', env: process.env });
    results.push({ campaign: c, exit: r.status == null ? 1 : r.status });
}

console.log(`\n${'='.repeat(70)}\n  THESIS SUMMARY\n${'='.repeat(70)}`);
for (const r of results) {
    console.log(`  ${r.exit === 0 ? '✓ PASS' : '✗ FAIL'}  ${r.campaign}  (exit ${r.exit})`);
}
console.log('  Excluded by default: ai-live (paid), authenticated/destructive production runs.');
const anyFail = results.some(r => r.exit !== 0);
process.exit(anyFail ? 1 : 0);
