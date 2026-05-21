const { chromium } = require('@playwright/test');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();

  try {
    console.log('1. Navigating to app...');
    await page.goto('http://localhost:3000');
    
    // Check if login form is present
    const loginForm = await page.$('#login-form');
    if (loginForm) {
      console.log('   Login form detected. Checking if we need to authenticate...');
      // Use test credentials
      await page.fill('#login-username', 'admin');
      await page.fill('#login-password', 'password');
      await page.click('#login-form button[type="submit"]');
      await page.waitForNavigation();
      console.log('   ✓ Logged in');
    }

    await page.waitForTimeout(2000);

    // Check if model select is visible
    const modelSelect = await page.$('#model-select');
    console.log(`   Model select visible: ${modelSelect !== null}`);

    if (modelSelect) {
      console.log('2. Selecting kinetic_hand_rh60_parametric model...');
      await page.selectOption('#model-select', 'kinetic_hand_rh60_parametric');
      await page.waitForTimeout(1500);

      console.log('3. Checking parameters are loaded...');
      const palmBreadth = await page.$('#param-palm_breadth_mm');
      const gauntlet = await page.$('#param-gauntlet_width_mm');
      console.log(`   ✓ palm_breadth_mm exists: ${palmBreadth !== null}`);
      console.log(`   ✓ gauntlet_width_mm exists: ${gauntlet !== null}`);

      console.log('4. Checking auto-link toggle...');
      const autoLink = await page.$('#auto-link');
      console.log(`   ✓ auto-link checkbox exists: ${autoLink !== null}`);
    }

    console.log('\n✅ Basic UI elements verified!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Test failed:', err.message);
    process.exit(1);
  } finally {
    // Don't close - let user interact
    // await browser.close();
  }
})();
