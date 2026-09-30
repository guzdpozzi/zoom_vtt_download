const { test } = require('@playwright/test');
const fs = require('fs');
const path = require('path');
const { timeout } = require('../playwright.config');

function sanitizeName(name) {
  if (!name) return 'meeting';
  // replace vertical bar with hyphen, other illegal filename chars -> underscore, collapse whitespace
  return name.replace(/\|/g, '-').replace(/[<>:"\/\\?*]/g, '_').replace(/\s+/g, '_');
}

async function formatToYYYYMMDD(input) {
  const s = String(input).replace(/(^["']|["']$)/g, '').trim();
  // Matches: Mon DD, YYYY [HH:MM [AM|PM]]
  const m = s.match(/^([A-Za-z]{3})\s+(\d{1,2}),\s*(\d{4})(?:\s+(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?)?$/);
  if (!m) throw new Error('Unrecognized date format: ' + input);
  const months = { Jan: '01', Feb: '02', Mar: '03', Apr: '04', May: '05', Jun: '06',
                   Jul: '07', Aug: '08', Sep: '09', Oct: '10', Nov: '11', Dec: '12' };
  const mon = months[m[1]];
  if (!mon) throw new Error('Unknown month: ' + m[1]);
  const day = String(m[2]).padStart(2, '0');
  const year = m[3];

  const hourPart = m[4];
  const minutePart = m[5];
  let meridiem = m[6];
  if (!hourPart) {
    // no time provided
    return `${year}${mon}${day}`;
  }
  let hourNum = parseInt(hourPart, 10);
  const minute = String(minutePart || '00').padStart(2, '0');

  // Convert to 24-hour clock
  if (meridiem) {
    meridiem = meridiem.toUpperCase();
    if (meridiem === 'AM') {
      if (hourNum === 12) hourNum = 0;
    } else if (meridiem === 'PM') {
      if (hourNum < 12) hourNum = hourNum + 12;
    }
  }
  // If no meridiem provided, assume hourPart is already 24-hour
  const hour24 = String(hourNum).padStart(2, '0');
  const second = '00';
  return `${year}${mon}${day}_${hour24}${minute}${second}`;

}

async function downloadTranscriptIfAvailable(page, downloadsDir, meetingTitle, meetingTime) {
  
  let sanitized;
  try {
    const datePart = await formatToYYYYMMDD(meetingTime);
    sanitized = `${datePart}_${sanitizeName(meetingTitle)}.txt`;
  } catch (e) {
    console.log('Failed to parse meeting time, omitting date from filename for', meetingTitle, e.message || e);
    sanitized = `${sanitizeName(meetingTitle)}.txt`;
  }

  // check presence of the generic button and log
  const downloadLinkCount = await page.locator('button.zm-button.zm-button--link.zm-button--small').count();
  console.log(' [INFO] Attempting to download transcript with filename:', sanitized, '. Generic button matches:', downloadLinkCount);

  if (downloadLinkCount > 0) {

    try {

      // 1. Start waiting for the download event before clicking
      const downloadPromise = page.waitForEvent('download', { timeout: 10000 });

      // 2. Use a more specific locator: button inside the .item_list_header.relative container
      //const actionBtn = page.locator('.item_list_header.relative').locator('button.zm-button.zm-button--link.zm-button--small').first();
      const actionBtn = page.locator('button.zm-button.zm-button--link.zm-button--small').first();
      await actionBtn.waitFor({ state: 'visible', timeout: 10000 }).catch(() => {});

      // Try normal click, then force click as fallback
      try {
        await actionBtn.click();
      } catch (e) {
        await actionBtn.click({ force: true }).catch(() => { throw e; });
      }

      // 3. Wait for the download process to complete
      const download = await downloadPromise;

      // 4. Define the new name and path
      const downloadPath = path.join(downloadsDir, sanitized);

      // 5. Save the file to the desired location with the new name
      await download.saveAs(downloadPath);

      console.log(` [INFO] File downloaded and saved to: ${downloadPath}`);
    } catch (e) {
      console.log(' [ERROR] Failed to download transcript for: ', meetingTitle, e.message || e);
    }
    
  } else {
    console.log(' [INFO] Transcript download not available for: ', meetingTitle);
  }

}


test('download transcripts from recordings JSON', async ({ page }) => {
  test.setTimeout(300 * 15 * 60 * 1000);

  const USER = process.env.ZOOM_USER;
  const PASS = process.env.ZOOM_PASS;
  const RECORDINGS_FILE = process.env.RECORDINGS_FILE; // optional

  if (!USER || !PASS) throw new Error('Please set environment variables ZOOM_USER and ZOOM_PASS');

  // locate recordings json: explicit file or latest in outputs/
  let recordingsPath = RECORDINGS_FILE;

  if (!recordingsPath) {
    const outDir = path.resolve(process.cwd(), 'outputs');
    if (!fs.existsSync(outDir)) throw new Error('No RECORDINGS_FILE provided and outputs/ does not exist');
    const files = fs.readdirSync(outDir).filter(f => f.endsWith('.json'));
    if (!files.length) throw new Error('No JSON files found in outputs/');
    files.sort((a,b) => fs.statSync(path.join(outDir,b)).mtimeMs - fs.statSync(path.join(outDir,a)).mtimeMs);
    recordingsPath = path.join(outDir, files[0]);
  }

  const raw = fs.readFileSync(recordingsPath, 'utf8');
  let records = [];
  try { records = JSON.parse(raw); } catch (e) { throw new Error('Failed to parse recordings JSON: ' + e.message); }
  if (!Array.isArray(records) || !records.length) throw new Error('Recordings JSON is empty or not an array');

  // Optionally skip the first N records (useful to resume processing)
  const SKIP_RECORDS = parseInt(process.env.SKIP_RECORDS || '0', 10) || 0;
  if (SKIP_RECORDS > 0) {
    console.log('Skipping first', SKIP_RECORDS, 'records');
  }

  const downloadsDir = path.resolve(process.cwd(), 'downloads');
  if (!fs.existsSync(downloadsDir)) fs.mkdirSync(downloadsDir, { recursive: true });

  // Sign in
  await page.goto('https://zoom.us/signin#/', { waitUntil: 'networkidle', timeout: 60000 });
  await page.locator('#email').fill(USER);
  await page.locator("[data-testid='account-next-btn']").click().catch(() => {});
  await page.locator('#password').fill(PASS);
  await page.locator("[data-testid='signin-btn']").click().catch(() => {});
  await page.waitForNavigation({ waitUntil: 'networkidle', timeout: 5000 }).catch(() => {});

  for (let idx = SKIP_RECORDS; idx < records.length; idx++) {
    const rec = records[idx];
    const title = rec.name || 'meeting';
    const time = rec.startTime;
    const href = rec.href;

    try {
      if (!href) {
        console.log(' - no href, skipping');
        continue;
      }

      console.log(`\nProcessing[${idx+1}]: ${title}, ${time}, ${href}`);

      // Navigate to the meeting recording page with retries
      const MAX_NAV_RETRIES = 3;
      let navSucceeded = false;
      for (let attempt = 1; attempt <= MAX_NAV_RETRIES; attempt++) {
        try {
          await page.goto(href, { waitUntil: 'commit', timeout: 15000 });
          await page.waitForLoadState('domcontentloaded', { timeout: 10000 }).catch(() => {
            console.log('   [INFO] Page did not finish loading; continuing with current page');
          });
          await page.waitForTimeout(1500);
          navSucceeded = true;
          break;
        } catch (e) {
          console.log('   [INFO] Failed to open (attempt', attempt + '):', title, e.message || e);
          if (attempt < MAX_NAV_RETRIES) await page.waitForTimeout(2000);
        }
      }
      if (!navSucceeded) {
        console.log('[ERROR] Failed to open after', MAX_NAV_RETRIES, 'attempts for', title, href);
        break; // stop processing further records
      }

      // Attempt download (helper handles its own errors)
      await downloadTranscriptIfAvailable(page, downloadsDir, title, time);

    } catch (e) {

      console.log('[ERROR] Processing failed for record:', e.message || e);
      return; // stops the test and the loop
    }
  }

});