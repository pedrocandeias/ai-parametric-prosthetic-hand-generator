'use strict';

// Extended Playwright test providing authenticated browsing that is both
// rate-limit-safe and memory-safe:
//
//   authedContext  (worker-scoped)  — logs in exactly ONCE per worker via a
//     throwaway page, then hands out the authenticated context. One form login
//     per browser keeps the whole campaign under the 5/15min login limiter; the
//     refresh-token rotation is a non-issue because the single live context
//     keeps its rotated cookie.
//
//   authedPage     (test-scoped)    — a FRESH page from that context per test,
//     closed afterwards so heavy WASM renders never accumulate across tests.
//     The session restores automatically from the context's refresh cookie.
//
// Tests that repeat renders many times (REP-DET) take `authedContext` directly
// and open a fresh page PER RUN via `newAuthedPage` so no single page is asked
// to render ten times in a row.

const base = require('@playwright/test').test;
const po = require('./pageObjects');

const test = base.extend({
    authedContext: [async ({ browser }, use) => {
        const context = await browser.newContext();
        const page = await context.newPage();
        await po.login(page);      // one form login for the whole worker
        await page.close();
        await use(context);
        await context.close();
    }, { scope: 'worker' }],

    authedPage: async ({ authedContext }, use) => {
        const page = await authedContext.newPage();
        await use(page);
        await page.close();
    },
});

// Open a fresh authenticated page (session restored from the context cookie).
// Caller is responsible for closing it.
async function newAuthedPage(context) {
    const page = await context.newPage();
    await po.login(page); // goto '/' → tryRestoreSession via cookie (no new login)
    return page;
}

module.exports = { test, expect: require('@playwright/test').expect, newAuthedPage };
