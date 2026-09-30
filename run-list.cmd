@echo off
REM run-list.cmd — wrapper to run the Playwright listing test (list-recordings.spec.js)
REM Usage: run-list user pass [dateOrStart] [end] [headed] [skip_pages] [scrape_pages]
REM Example:
REM   run-list gustavo.pozzi@bairesdev.com password false 0 3

if "%~1"=="" (
  echo Usage: run-list user pass [headed] [skip_pages] [scrape_pages]
  goto :eof
)

setlocal
set "ZOOM_USER=%~1"
@echo set "ZOOM_PASS=%~2"
set "ZOOM_PASS=---------->>>>>PASSWORD_HERE"
set "HEADLESS=%~3"
set "SKIP_PAGES=%~4"
set "SCRAPE_PAGES=%~5"

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

echo Running listing test...
echo  - ZOOM_USER=%ZOOM_USER%
echo  - HEADED MODE: %RUN_FLAGS%
echo  - SKIP_PAGES: %SKIP_PAGES%
echo  - SCRAPE_PAGES: %SCRAPE_PAGES%

npx playwright test tests/list-recordings.spec.js %RUN_FLAGS% --config=playwright.config.js

endlocal
exit /b %ERRORLEVEL%
