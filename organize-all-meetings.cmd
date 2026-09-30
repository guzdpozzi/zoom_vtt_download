@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo ERROR: No folder path provided
    echo.
    echo Usage: organize-all-meetings.cmd "folder_path" [option]
    echo.
    echo Options:
    echo   --rename-only       Only rename files, skip organize
    echo   --organize-only     Only organize, skip rename
    echo.
    echo Examples:
    echo   organize-all-meetings.cmd "c:\Baires\zoom_vtt_download\downloads"
    echo   organize-all-meetings.cmd "D:\MyMeetings" --rename-only
    echo.
    exit /b 1
)

set "TARGET_FOLDER=%~1"
set "MODE=both"

if not "%~2"=="" (
    if "%~2"=="--rename-only" set "MODE=rename"
    if "%~2"=="--organize-only" set "MODE=organize"
)

if not exist "!TARGET_FOLDER!" (
    echo.
    echo ERROR: Folder does not exist: !TARGET_FOLDER!
    echo.
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"

echo.
echo ========================================
echo Meeting Files Organization Tool
echo ========================================
echo Target folder: !TARGET_FOLDER!
echo Mode: !MODE!
echo.

if "!MODE!"=="both" goto RunBoth
if "!MODE!"=="rename" goto RunRename
if "!MODE!"=="organize" goto RunOrganize
exit /b 1

:RunBoth
    echo [STEP 1/3] Renaming generic meeting files...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!Rename-MeetingFiles.ps1" -FolderPath "!TARGET_FOLDER!"
    if !errorlevel! neq 0 exit /b 1
    echo.
    
    echo [STEP 2/3] Organizing files by project and engineer...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!Organize-MeetingFiles.ps1" -FolderPath "!TARGET_FOLDER!"
    if !errorlevel! neq 0 exit /b 1
    echo.
    
    echo [STEP 3/3] Organizing remaining special files...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!Organize-RemainingFiles.ps1" -FolderPath "!TARGET_FOLDER!"
    if !errorlevel! neq 0 exit /b 1
    echo.
    goto End

:RunRename
    echo [STEP 1/1] Renaming generic meeting files...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!Rename-MeetingFiles.ps1" -FolderPath "!TARGET_FOLDER!"
    if !errorlevel! neq 0 exit /b 1
    echo.
    goto End

:RunOrganize
    echo [STEP 1/2] Organizing files by project and engineer...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!Organize-MeetingFiles.ps1" -FolderPath "!TARGET_FOLDER!"
    if !errorlevel! neq 0 exit /b 1
    echo.
    
    echo [STEP 2/2] Organizing remaining special files...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!Organize-RemainingFiles.ps1" -FolderPath "!TARGET_FOLDER!"
    if !errorlevel! neq 0 exit /b 1
    echo.
    goto End

:End
    echo ========================================
    echo Process Complete!
    echo ========================================
    echo.
    echo Your meetings are now organized by:
    echo   - Project folder
    echo   - Engineer/Focal point subfolder
    echo.
    echo Location: !TARGET_FOLDER!
    echo.
    endlocal
    exit /b 0
