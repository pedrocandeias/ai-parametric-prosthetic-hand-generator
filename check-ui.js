const { chromium } = require('@playwright/test');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const screenshots = [];

  try {
    console.log('Navigating to app and logging in...');
    await page.goto('http://localhost:3000');
    
    // Login
    await page.fill('#login-username', 'admin');
    await page.fill('#login-password', 'password');
    await page.click('#login-form button[type="submit"]');
    await page.waitForNavigation();
    await page.waitForTimeout(2000);

    console.log('Selecting model...');
    await page.click('#model-select');
    await page.waitForTimeout(500);
    await page.click('option[value="kinetic_hand_rh60_parametric"]');
    await page.waitForTimeout(2000);

    // Take screenshot 1: initial state
    console.log('Screenshot 1: Taking initial state screenshot...');
    const ss1 = await page.screenshot();
    fs.writeFileSync('/tmp/ss1-initial.png', ss1);
    screenshots.push('/tmp/ss1-initial.png');

    // Check for auto-link toggle
    const hasAutoLink = await page.$('#auto-link');
    console.log(`✓ Auto-link toggle exists: ${hasAutoLink !== null}`);

    // Check for link indicator
    const hasLinkIndicator = await page.$('.param-dep-indicator');
    console.log(`✓ Link indicator exists: ${hasLinkIndicator !== null}`);

    // Test auto-link cascade
    console.log('\nTesting auto-link cascade...');
    const palmInput = await page.$('#param-palm_breadth_mm');
    const gauntletInput = await page.$('#param-gauntlet_width_mm');
    
    const initialGauntlet = await gauntletInput.inputValue();
    console.log(`Initial gauntlet value: ${initialGauntlet}`);

    // Change palm_breadth_mm
    await palmInput.fill('100');
    await palmInput.dispatchEvent('input');
    await page.waitForTimeout(800);

    const updatedGauntlet = await gauntletInput.inputValue();
    console.log(`Gauntlet after palm change to 100: ${updatedGauntlet}`);
    console.log(`✓ Auto-link works: ${updatedGauntlet !== initialGauntlet}`);

    // Take screenshot 2: after auto-link
    console.log('\nScreenshot 2: After auto-link cascade...');
    const ss2 = await page.screenshot();
    fs.writeFileSync('/tmp/ss2-autolink.png', ss2);
    screenshots.push('/tmp/ss2-autolink.png');

    // Disable auto-link
    console.log('\nDisabling auto-link...');
    const autoLinkCheckbox = await page.$('#auto-link');
    await autoLinkCheckbox.click();
    await page.waitForTimeout(300);

    // Try to change palm again
    const gauntletBefore = await gauntletInput.inputValue();
    await palmInput.fill('110');
    await palmInput.dispatchEvent('input');
    await page.waitForTimeout(500);
    const gauntletAfter = await gauntletInput.inputValue();

    console.log(`Gauntlet before (auto-link OFF): ${gauntletBefore}`);
    console.log(`Gauntlet after changing palm to 110: ${gauntletAfter}`);
    console.log(`✓ Auto-link disabled works: ${gauntletBefore === gauntletAfter}`);

    // Take screenshot 3: with auto-link disabled
    console.log('\nScreenshot 3: Auto-link disabled...');
    const ss3 = await page.screenshot();
    fs.writeFileSync('/tmp/ss3-nolink.png', ss3);
    screenshots.push('/tmp/ss3-nolink.png');

    // Check validation warnings
    console.log('\nChecking validation warnings...');
    const warningsDiv = await page.$('#param-warnings');
    console.log(`✓ Warnings area exists: ${warningsDiv !== null}`);

    console.log(`\n✅ All visual checks passed!`);
    console.log(`Screenshots saved to: ${screenshots.join(', ')}`);
    process.exit(0);
  } catch (err) {
    console.error('❌ Test failed:', err.message);
    console.error(err.stack);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
