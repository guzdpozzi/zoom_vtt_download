@echo off
REM Organize meeting files into project/engineer folders
REM Usage: organize-meetings.cmd "C:\path\to\folder"

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo ERROR: No folder path provided
    echo.
    echo Usage: organize-meetings.cmd "folder_path"
    echo.
    echo Example:
    echo   organize-meetings.cmd "c:\Baires\zoom_vtt_download\downloads"
    echo   organize-meetings.cmd "D:\MyMeetings"
    echo.
    exit /b 1
)

set "TARGET_FOLDER=%~1"

REM Check if folder exists
if not exist "!TARGET_FOLDER!" (
    echo.
    echo ERROR: Folder does not exist: !TARGET_FOLDER!
    echo.
    exit /b 1
)

REM Get the script directory (where this batch file is located)
set "SCRIPT_DIR=%~dp0"
set "POWERSHELL_SCRIPT=!SCRIPT_DIR!Organize-MeetingFiles.ps1"

REM Check if PowerShell script exists
if not exist "!POWERSHELL_SCRIPT!" (
    echo.
    echo ERROR: PowerShell script not found: !POWERSHELL_SCRIPT!
    echo.
    exit /b 1
)

echo.
echo ========================================
echo Meeting Files Organization Tool
echo ========================================
echo Target folder: !TARGET_FOLDER!
echo.

REM Run the PowerShell script with the folder path
powershell -NoProfile -ExecutionPolicy Bypass -File "!POWERSHELL_SCRIPT!" -FolderPath "!TARGET_FOLDER!"

endlocal
