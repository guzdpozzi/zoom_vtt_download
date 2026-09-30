Zoom Transcript Download Playwright Test

Overview
- This Playwright test automates signing in to Zoom, filtering recordings by date, and downloading transcripts for each meeting found.

Prerequisites
- Node.js (16+ recommended)

Setup
1. From the project root, install dependencies:

```bash
npm install
npx playwright install
```

Running the test
- Provide credentials and date(s) via environment variables.

Single date (same start and end):

```powershell
$env:ZOOM_USER="you@example.com"; $env:ZOOM_PASS="yourpass"; $env:ZOOM_DATE="2024-10-01"; npx playwright test
```

Range:

```powershell
$env:ZOOM_USER="you@example.com"; $env:ZOOM_PASS="yourpass"; $env:START_DATE="2024-10-01"; $env:END_DATE="2024-10-02"; npx playwright test
```

Notes
- The script uses a set of heuristics for selectors. If Zoom updates their UI or your account uses SSO, you may need to adjust selectors in `tests/download-transcripts.spec.js`.
- Downloads are saved into a `downloads` folder in the project root, named using the meeting title (sanitized).
- For debugging, edit `playwright.config.js` to run with `headless: false`.

If you want, I can run the test here or adapt selectors to your specific Zoom account UI.
