# Meeting File Rename Tool

Automatically rename generic "Zoom_Meeting" and "Google_Calendar_Meeting" files by extracting participant names from VTT transcripts.

## Features

- Extracts speaker names from VTT transcript files
- Converts names to proper case (e.g., `mateus.rodrigues` → `Mateus Rodrigues`)
- Excludes "Gustavo Pozzi" from participant names
- Follows the naming format: `TIMESTAMP_1_1_-_PARTICIPANT_NAME.txt`
- Works with any folder path

## Usage

### Method 1: Batch Command (Recommended for Command Prompt)

```cmd
rename-meetings.cmd "C:\path\to\folder"
```

**Examples:**

```cmd
rename-meetings.cmd "c:\Baires\zoom_vtt_download\downloads"
rename-meetings.cmd "D:\MyMeetings"
rename-meetings.cmd "%USERPROFILE%\Documents\Meetings"
```

### Method 2: PowerShell Script

```powershell
.\Rename-MeetingFiles.ps1 -FolderPath "C:\path\to\folder"
```

**Examples:**

```powershell
.\Rename-MeetingFiles.ps1 -FolderPath "c:\Baires\zoom_vtt_download\downloads"
.\Rename-MeetingFiles.ps1 -FolderPath "D:\MyMeetings"
```

## Files Included

- **rename-meetings.cmd** - Batch script wrapper (call this from Command Prompt)
- **Rename-MeetingFiles.ps1** - PowerShell script (call this from PowerShell)

## How It Works

1. Scans the target folder for files matching:
   - `*Zoom_Meeting.txt`
   - `*Google_Calendar_Meeting*.txt`

2. Reads each VTT transcript file and extracts speaker names

3. Identifies the first speaker (excluding "Gustavo Pozzi")

4. Converts the name to proper case

5. Renames the file following the format: `TIMESTAMP_1_1_-_PARTICIPANT.txt`

## Example Output

```
========================================
Meeting File Rename Tool
========================================
Target folder: c:\Baires\zoom_vtt_download\downloads

Found 99 files to process

[OK] 20260225_093100_Zoom_Meeting.txt -> 20260225_093100_1_1_-_Renatafaraco.txt
[OK] 20260302_104400_Zoom_Meeting.txt -> 20260302_104400_1_1_-_Natanael De Sousa.txt
[OK] 20260306_111500_Zoom_Meeting.txt -> 20260306_111500_1_1_-_Wallace Viana.txt
[SKIP] 20260307_120000_1_1_-_Jorge.txt (target already exists)
[ERROR] 20260308_153000_Invalid.txt: Error reading file

================================
Total renamed: 96
Errors/Skipped: 3
================================
```

## Error Handling

The script handles:
- Missing folders (displays error and exits)
- Files that already have the target name (skips with [SKIP] message)
- Read/write errors (displays [ERROR] message)
- Invalid VTT format (skips the file)

## Notes

- Both scripts require PowerShell to be available on the system
- The scripts are read-only - they don't modify the original VTT content
- Files are renamed in-place in the specified folder
- Requires Windows 7 SP1 or later with PowerShell 3.0+

## Troubleshooting

### "rename-meetings.cmd is not recognized"

Run with full path:
```cmd
"c:\Baires\zoom_vtt_download\rename-meetings.cmd" "c:\your\folder"
```

### PowerShell execution policy error

Use this PowerShell command:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

Then run the script normally.

### No files found in folder

Make sure the folder contains `.txt` files with VTT content from Zoom/Google Calendar recordings.
