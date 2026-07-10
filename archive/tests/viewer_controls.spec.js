// @ts-check
// Verify the /edit viewer toolbar buttons: zoom in/out, pan mode, fullscreen.
const { test, expect } = require('@playwright/test');

const ADMIN = {
    username: process.env.TEST_ADMIN_USER || 'handadmin',
    password: process.env.TEST_ADMIN_PASSWORD || 'handfabin',
};

async function login(page) {
    await page.goto('/');
    await page.waitForSelector('#login-form', { timeout: 10000 });
    await page.fill('#login-username', ADMIN.username);
    await page.fill('#login-password', ADMIN.password);
    await page.click('#login-form button[type="submit"]');
    await page.waitForSelector('[data-model-id]', { timeout: 15000 });
}

async function renderAndWait(page) {
    await page.click('#render-btn');
    await page.waitForFunction(() => {
        const l = document.getElementById('loading');
        const v = document.getElementById('viewer');
        const done = l && !l.classList.contains('active');
        const painted = v && v.src && v.src !== '' && !v.src.startsWith('about:');
        return done && painted;
    }, { timeout: 240000 });
    await page.waitForTimeout(500);
}

test('viewer toolbar buttons work', async ({ page }) => {
    const errors = [];
    page.on('pageerror', e => errors.push('pageerror: ' + e.message));

    await login(page);
    await page.click('[data-model-id="flexy_beast"]');
    await page.waitForSelector('#param-palm_breadth_mm', { state: 'attached', timeout: 15000 });
    await renderAndWait(page);

    const orbit = () => page.evaluate(() => {
        const o = document.getElementById('viewer').getCameraOrbit();
        return { theta: o.theta, phi: o.phi, radius: o.radius };
    });

    // Zoom in shrinks the orbit radius; zoom out grows it back.
    const r0 = (await orbit()).radius;
    await page.click('#zoom-in-btn');
    await page.waitForTimeout(400);
    const r1 = (await orbit()).radius;
    expect(r1).toBeLessThan(r0);
    await page.click('#zoom-out-btn');
    await page.waitForTimeout(400);
    const r2 = (await orbit()).radius;
    expect(r2).toBeGreaterThan(r1);

    // Fullscreen enters and exits.
    await page.click('#fullscreen-btn');
    await page.waitForFunction(() => !!document.fullscreenElement, { timeout: 3000 });
    await page.click('#fullscreen-btn');
    await page.waitForFunction(() => !document.fullscreenElement, { timeout: 3000 });

    // Pan mode: activate, drag on the viewer, camera target must move and orbit angles must NOT.
    await page.click('#pan-btn');
    await expect(page.locator('#pan-btn')).toHaveClass(/active/);
    const before = await page.evaluate(() => {
        const v = document.getElementById('viewer');
        const t = v.getCameraTarget(); const o = v.getCameraOrbit();
        return { t: { x: t.x, y: t.y, z: t.z }, theta: o.theta, phi: o.phi };
    });
    const box = await page.locator('#viewer').boundingBox();
    const cx = box.x + box.width / 2, cy = box.y + box.height / 2;
    await page.mouse.move(cx, cy);
    await page.mouse.down();
    await page.mouse.move(cx + 80, cy + 40, { steps: 8 });
    await page.mouse.up();
    await page.waitForTimeout(300);
    const after = await page.evaluate(() => {
        const v = document.getElementById('viewer');
        const t = v.getCameraTarget(); const o = v.getCameraOrbit();
        return { t: { x: t.x, y: t.y, z: t.z }, theta: o.theta, phi: o.phi };
    });
    const moved = Math.hypot(after.t.x - before.t.x, after.t.y - before.t.y, after.t.z - before.t.z);
    expect(moved).toBeGreaterThan(0.0001);
    expect(Math.abs(after.theta - before.theta)).toBeLessThan(0.01);
    expect(Math.abs(after.phi - before.phi)).toBeLessThan(0.01);

    // Deactivate pan mode: drag orbits again.
    await page.click('#pan-btn');
    await expect(page.locator('#pan-btn')).not.toHaveClass(/active/);
    const t0 = await page.evaluate(() => document.getElementById('viewer').getCameraOrbit().theta);
    await page.mouse.move(cx, cy);
    await page.mouse.down();
    await page.mouse.move(cx + 80, cy, { steps: 8 });
    await page.mouse.up();
    await page.waitForTimeout(300);
    const t1 = await page.evaluate(() => document.getElementById('viewer').getCameraOrbit().theta);
    expect(Math.abs(t1 - t0)).toBeGreaterThan(0.01);

    expect(errors).toEqual([]);
});
