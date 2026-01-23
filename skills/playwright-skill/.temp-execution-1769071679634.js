const { chromium } = require('playwright');

const TARGET_URL = 'http://localhost:3000';

// All pages to test
const PAGES = [
  // Static routes
  { path: '/', name: 'Landing Page', expectRedirect: true },
  { path: '/dashboard', name: 'Dashboard' },
  { path: '/essay', name: 'Essay Submission' },
  { path: '/essay/history', name: 'Essay History' },
  { path: '/flashcards', name: 'Flashcard Decks' },
  { path: '/flashcards/review', name: 'Flashcard Review' },
  { path: '/flashcards/quiz', name: 'Flashcard Quiz' },
  { path: '/translation', name: 'Translation Hub' },
  { path: '/translation/practice', name: 'Translation Practice' },
  { path: '/translation/history', name: 'Translation History' },
  { path: '/leaderboard', name: 'Leaderboard' },
  { path: '/badges', name: 'Badges' },
  { path: '/profile', name: 'Profile' },
  { path: '/settings', name: 'Settings' },
  { path: '/subscription', name: 'Subscription' },
  // Dynamic routes
  { path: '/essay/1', name: 'Essay Detail (ID: 1)' },
  { path: '/flashcards/1', name: 'Flashcard Deck (ID: 1)' },
  { path: '/translation/1', name: 'Translation Detail (ID: 1)' },
];

(async () => {
  const browser = await chromium.launch({ headless: false, slowMo: 50 });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 }
  });
  const page = await context.newPage();

  // Collect console errors
  const consoleErrors = {};
  page.on('console', msg => {
    if (msg.type() === 'error') {
      const url = page.url();
      if (!consoleErrors[url]) consoleErrors[url] = [];
      consoleErrors[url].push(msg.text());
    }
  });

  // Track page errors
  const pageErrors = {};
  page.on('pageerror', error => {
    const url = page.url();
    if (!pageErrors[url]) pageErrors[url] = [];
    pageErrors[url].push(error.message);
  });

  const results = [];

  console.log('🧪 Starting AceWriter Page Tests');
  console.log('=' .repeat(60));
  console.log(`Testing ${PAGES.length} pages at ${TARGET_URL}\n`);

  for (let i = 0; i < PAGES.length; i++) {
    const { path, name, expectRedirect } = PAGES[i];
    const fullUrl = `${TARGET_URL}${path}`;
    const testNum = i + 1;

    console.log(`\n[${testNum}/${PAGES.length}] Testing: ${name}`);
    console.log(`   URL: ${path}`);

    const result = {
      number: testNum,
      name,
      path,
      status: 'unknown',
      finalUrl: '',
      title: '',
      heading: '',
      screenshot: '',
      consoleErrors: [],
      pageErrors: [],
      loadTime: 0,
    };

    const startTime = Date.now();

    try {
      // Navigate to page
      const response = await page.goto(fullUrl, {
        waitUntil: 'networkidle',
        timeout: 15000
      });

      result.loadTime = Date.now() - startTime;
      result.finalUrl = page.url();

      // Check response status
      const statusCode = response?.status() || 0;

      if (statusCode >= 400) {
        result.status = 'fail';
        console.log(`   ❌ HTTP ${statusCode}`);
      } else {
        // Get page title
        result.title = await page.title();

        // Try to get main heading
        try {
          const h1 = await page.locator('h1').first().textContent({ timeout: 2000 });
          result.heading = h1?.trim() || '';
        } catch {
          // Try h2 if no h1
          try {
            const h2 = await page.locator('h2').first().textContent({ timeout: 1000 });
            result.heading = h2?.trim() || '';
          } catch {
            result.heading = '(no heading found)';
          }
        }

        // Check if page has content (not blank)
        const bodyContent = await page.locator('body').innerHTML();
        const hasContent = bodyContent.length > 100;

        if (!hasContent) {
          result.status = 'warning';
          console.log(`   ⚠️  Page appears empty`);
        } else {
          result.status = 'pass';
          console.log(`   ✅ Loaded successfully (${result.loadTime}ms)`);
        }

        // Log redirect if occurred
        if (expectRedirect && result.finalUrl !== fullUrl) {
          console.log(`   ↪️  Redirected to: ${result.finalUrl.replace(TARGET_URL, '')}`);
        }

        // Log title/heading
        if (result.heading) {
          console.log(`   📄 Heading: "${result.heading}"`);
        }
      }

      // Take screenshot
      const screenshotName = path.replace(/\//g, '-').replace(/^-/, '') || 'home';
      const screenshotPath = `/tmp/acewriter-${screenshotName}.png`;
      await page.screenshot({ path: screenshotPath, fullPage: true });
      result.screenshot = screenshotPath;
      console.log(`   📸 Screenshot: ${screenshotPath}`);

    } catch (error) {
      result.status = 'error';
      result.error = error.message;
      console.log(`   ❌ Error: ${error.message}`);

      // Try to take screenshot even on error
      try {
        const screenshotName = path.replace(/\//g, '-').replace(/^-/, '') || 'home';
        const screenshotPath = `/tmp/acewriter-${screenshotName}-error.png`;
        await page.screenshot({ path: screenshotPath });
        result.screenshot = screenshotPath;
      } catch {}
    }

    // Collect any errors for this URL
    result.consoleErrors = consoleErrors[result.finalUrl] || consoleErrors[fullUrl] || [];
    result.pageErrors = pageErrors[result.finalUrl] || pageErrors[fullUrl] || [];

    if (result.consoleErrors.length > 0) {
      console.log(`   ⚠️  Console errors: ${result.consoleErrors.length}`);
      result.consoleErrors.forEach(err => console.log(`      - ${err.substring(0, 80)}`));
    }
    if (result.pageErrors.length > 0) {
      console.log(`   ⚠️  Page errors: ${result.pageErrors.length}`);
      result.pageErrors.forEach(err => console.log(`      - ${err.substring(0, 80)}`));
    }

    results.push(result);

    // Small delay between pages
    await page.waitForTimeout(300);
  }

  await browser.close();

  // Print summary
  console.log('\n');
  console.log('=' .repeat(60));
  console.log('📊 TEST SUMMARY');
  console.log('=' .repeat(60));

  const passed = results.filter(r => r.status === 'pass');
  const failed = results.filter(r => r.status === 'fail' || r.status === 'error');
  const warnings = results.filter(r => r.status === 'warning');

  console.log(`\n✅ Passed: ${passed.length}/${results.length}`);
  console.log(`❌ Failed: ${failed.length}/${results.length}`);
  console.log(`⚠️  Warnings: ${warnings.length}/${results.length}`);

  console.log('\n📋 Detailed Results:');
  console.log('-'.repeat(60));

  results.forEach(r => {
    const icon = r.status === 'pass' ? '✅' : r.status === 'warning' ? '⚠️' : '❌';
    const errors = r.consoleErrors.length + r.pageErrors.length;
    const errorNote = errors > 0 ? ` (${errors} errors)` : '';
    console.log(`${icon} [${r.number}] ${r.name} - ${r.path}${errorNote}`);
    if (r.error) console.log(`      Error: ${r.error}`);
  });

  console.log('\n📸 Screenshots saved to /tmp/acewriter-*.png');

  // List failed pages
  if (failed.length > 0) {
    console.log('\n❌ FAILED PAGES:');
    failed.forEach(r => {
      console.log(`   - ${r.name} (${r.path}): ${r.error || 'HTTP error'}`);
    });
  }

  // Exit with error code if any failures
  process.exit(failed.length > 0 ? 1 : 0);
})();
