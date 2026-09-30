@echo off
REM run-test.cmd — wrapper to run the Playwright test with Zoom credentials
REM Usage: run-test user pass [headless] [skip_pages] [scrape_pages]
REM Examples:
REM   run-test user@example.com "p@ssword" 2026-06-10
REM   run-test user@example.com "p@ssword" 2026-06-01 2026-06-10 false
REM   run-test user@example.com "p@ssword" 2026-06-01 2026-06-10 false 2 3

if "%~1"=="" (
  echo Usage: run-test user pass dateOrStart [end] [headless]
  echo Examples:
  echo   run-test user@example.com "p@ssword" false 3 10
  echo   run-test user@example.com "p@ssword"
  goto :eof
)

setlocal
set "ZOOM_USER=%~1"
set "ZOOM_PASS=%~2"
set "HEADLESS=%~5"
set "SKIP_PAGES=%~6"
set "SCRAPE_PAGES=%~7"

if "%HEADLESS%"=="" (
  set "HEADLESS=true"
)

if "%SKIP_PAGES%"=="" (
  set "SKIP_PAGES=0"
)

if "%SCRAPE_PAGES%"=="" (
  set "SCRAPE_PAGES=1"
)

set "RUN_FLAGS="
if /I "%HEADLESS%"=="false" (
  set "RUN_FLAGS=--headed"
)

echo Running Playwright tests...
echo  - ZOOM_USER=%ZOOM_USER%
echo  - HEADED MODE: %RUN_FLAGS%
echo  - SKIP_PAGES: %SKIP_PAGES%
echo  - SCRAPE_PAGES: %SCRAPE_PAGES%

REM Environment variables will be visible to the child process; run Playwright now.
npx playwright test %RUN_FLAGS% --config=playwright.config.js

endlocal
exit /b %ERRORLEVEL%
