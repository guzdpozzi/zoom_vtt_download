const { test } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

test('list zoom recordings titles and hrefs', async ({ page }) => {

  const USER = process.env.ZOOM_USER;
  const PASS = process.env.ZOOM_PASS;
  const SKIP_PAGES = parseInt(process.env.SKIP_PAGES || '0', 10) || 0;
  const SCRAPE_PAGES = parseInt(process.env.SCRAPE_PAGES || '1', 10) || 1;
  
  if (!USER || !PASS) {
     throw new Error('Please set environment variables ZOOM_USER and ZOOM_PASS');
   }
 
   // 1) Sign in
   await page.goto("https://zoom.us/signin#/", { waitUntil: 'networkidle', timeout: 60000 });
   await page.locator("#email").fill(USER);
   await page.locator("[data-testid='account-next-btn']").click()
   await page.locator("#password").fill(PASS);
   await page.locator("[data-testid='signin-btn']").click()
 
   await page.waitForNavigation({ waitUntil: 'networkidle' }).catch(() => {});
 
   await page.waitForTimeout(1000);
 
   // 2) Go to recordings
   await page.goto('https://zoom.us/recording/', { waitUntil: 'domcontentloaded', timeout: 5000 });

   await page.waitForSelector('a.title-context-container', { state: 'visible' });
   await page.getByTestId('rec-layout-view-list').click();

   await page.waitForTimeout(1000);

  // helper to advance to next page robustly: click next and wait until rows change
  const advanceToNextPage = async (opts = {}) => {
    const timeoutMs = opts.timeoutMs || 12000;
    const pollInterval = opts.pollInterval || 1000;
    const nextBtn = page.locator('button.btn-next').first();
    if (!(await nextBtn.count())) {
      console.log('No next button found');
      return false;
    }
    // wait until enabled
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
      const enabled = await nextBtn.isEnabled().catch(() => false);
      if (enabled) break;
      await page.waitForTimeout(pollInterval);
    }
    const before = await page.$$eval('tr.zoom-virtual-table__row', rows => rows.map(r => {
      const a = r.querySelector('a');
      return (a ? a.href : r.textContent || '').trim().slice(0, 200);
    }));

    try {
      await nextBtn.click();
    } catch (e) {
      console.log('Click next failed:', e.message || e);
      return false;
    }

    // wait for table to change or timeout
    const waitStart = Date.now();
    while (Date.now() - waitStart < timeoutMs) {
      await page.waitForTimeout(pollInterval);
      const after = await page.$$eval('tr.zoom-virtual-table__row', rows => rows.map(r => {
        const a = r.querySelector('a');
        return (a ? a.href : r.textContent || '').trim().slice(0, 200);
      }));
      if (after.length !== before.length) return true;
      // check if content changed
      let changed = false;
      for (let i = 0; i < Math.min(before.length, after.length); i++) {
        if (before[i] !== after[i]) { changed = true; break; }
      }
      if (changed) return true;
    }
    console.log('Timed out waiting for page to change after clicking next');
    return false;
  };

  console.log('Skipping first', SKIP_PAGES, 'pages');
  if (SKIP_PAGES > 0) {
    for (let i = 0; i < SKIP_PAGES; i++) {
      const ok = await advanceToNextPage({ timeoutMs: 12000 });
      if (!ok) {
        console.log('Stopping skip due to pagination issue at iteration', i);
        break;
      }
      // small pause to allow UI to settle
      await page.waitForTimeout(500);
    }
  }

  const results = [];

  console.log('Scraping next', SCRAPE_PAGES, 'pages');

  try {
    for (let pageIndex = 0; pageIndex < SCRAPE_PAGES; pageIndex++) {

    console.log('Scraping page', pageIndex + 1, 'of', SCRAPE_PAGES);
    let meetings = [];
    let attempts = 0;
    const maxAttempts = 3;
    while (attempts < maxAttempts) {
      try {
        meetings = await page.$$eval('tr.zoom-virtual-table__row', (rows) => {
          return rows.map(row => {
            const nameCell = row.querySelector('.zoom-virtual-table_1_column_3');
            const linkElement = nameCell?.querySelector('a');
            const timeCell = row.querySelector('.zoom-virtual-table_1_column_5');
            return {
              name: linkElement ? linkElement.textContent.trim() : (nameCell ? nameCell.textContent.trim() : null),
              href: linkElement ? linkElement.href : null,
              startTime: timeCell ? timeCell.textContent.trim() : null
            };
          });
        });
        // success
        break;
      } catch (e) {
        attempts++;
        console.log(`Failed to scrape page ${pageIndex + 1} (attempt ${attempts}/${maxAttempts}):`, e.message || e);
        if (attempts >= maxAttempts) {
          console.log('Giving up on this page and continuing to next page');
          meetings = [];
          break;
        }
        // try to recover: wait a bit and reload or wait for load state
        await page.waitForTimeout(2000);
        try {
          await page.reload({ waitUntil: 'domcontentloaded', timeout: 10000 }).catch(() => {});
        } catch (_) {}
      }
    }

    // append found meetings
    for (const m of meetings) results.push(m);

    // advance to next page if needed
    if (pageIndex < SCRAPE_PAGES - 1) {
      const ok = await advanceToNextPage({ timeoutMs: 12000 });
      if (!ok) {
        console.log('Stopping pagination due to pagination issue on page', pageIndex + 1);
        break;
      }
      // small pause to allow UI to settle
      await page.waitForTimeout(1000);
    }
    }
  } catch (fatal) {
    console.log('Fatal error during scraping loop:', fatal && (fatal.message || fatal));
  } finally {
    // always write output (partial results if any)
    try {
      const outDir = path.resolve(process.cwd(), 'outputs');
      if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
      const outPath = path.join(outDir, `recordings-${Date.now()}.json`);
      fs.writeFileSync(outPath, JSON.stringify(results, null, 2), 'utf8');
      console.log('Wrote', outPath, 'entries=', results.length);
    } catch (writeErr) {
      console.log('Failed to write output file:', writeErr && (writeErr.message || writeErr));
    }
  }
 
});
