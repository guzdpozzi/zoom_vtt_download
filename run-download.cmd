@echo off
REM run-download.cmd — wrapper to run the Playwright download test (download-transcripts.spec.js)
REM Usage: run-download user pass [headed] [recordings_file] [skip_records] [keep_browser]
REM Example:
REM   run-download user@example.com "p@ssword" false outputs\recordings-1781286729586.json 0 1

if "%~1"=="" (
  echo Usage: run-download user pass [headed] [recordings_file] [skip_records]
  goto :eof
)

setlocal
set "ZOOM_USER=%~1"
@echo set "ZOOM_PASS=%~2"
set "ZOOM_PASS=---------->>>>>PASSWORD_HERE"
set "HEADLESS=%~3"

set "RECORDINGS_FILE=%~4"
set "SKIP_RECORDS=%~5"

if "%HEADLESS%"=="" (
  set "HEADLESS=true"
)

set "RUN_FLAGS="
if /I "%HEADLESS%"=="false" (
  set "RUN_FLAGS=--headed"
)

echo Running download test...
echo  - ZOOM_USER=%ZOOM_USER%
echo  - Headed mode: %RUN_FLAGS%
echo  - RECORDINGS_FILE=%RECORDINGS_FILE%
echo  - SKIP_RECORDS: %SKIP_RECORDS%

npx playwright test tests/download-transcripts.spec.js %RUN_FLAGS% --config=playwright.config.js

endlocal
exit /b %ERRORLEVEL%
