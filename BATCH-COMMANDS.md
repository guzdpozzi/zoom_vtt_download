# Meeting Files Organization - Batch Commands

Complete set of batch command wrappers for organizing and renaming Zoom meeting transcripts.

## Available Commands

### 1. `rename-meetings.cmd` - Rename Generic Meetings
Extracts participant names from VTT transcripts and renames generic Zoom_Meeting or Google_Calendar_Meeting files.

**Usage:**
```cmd
rename-meetings.cmd "folder_path"
```

**Example:**
```cmd
rename-meetings.cmd "C:\Baires\zoom_vtt_download\downloads"
```

**What it does:**
- Scans all .txt files for `Zoom_Meeting` or `Google_Calendar_Meeting` in filename
- Reads the VTT transcript to extract the first speaker name
- Renames file to: `TIMESTAMP_1_1_-_SPEAKER_NAME.txt`
- Converts names to proper case (e.g., `mateus.rodrigues` → `Mateus Rodrigues`)

**Output:** Shows count of files renamed

---

### 2. `organize-meetings.cmd` - Organize by Project & Engineer
Moves meeting files into a hierarchical folder structure: `PROJECT\ENGINEER\filename`.

**Usage:**
```cmd
organize-meetings.cmd "folder_path"
```

**Example:**
```cmd
organize-meetings.cmd "C:\Baires\zoom_vtt_download\downloads"
```

**What it does:**
- Scans each file for project keywords in filename and content
- Extracts engineer/focal point name from filename
- Creates folder structure: `PROJECT/ENGINEER/`
- Moves files to appropriate engineer folder
- Handles special files (Gustavo Pozzi meetings, checkpoints) in `General/` folder

**Projects recognized:** 
Caerus, Syneos, UCR, Medical Solutions, BackOps AI, MercySeat, OnePay, Spring Health, Dansons, One Finance, One, BairesDev, Other

**Output:** Shows folder structure created and file counts

---

### 3. `organize-all-meetings.cmd` - Complete Pipeline
Combines rename and organize in one command with options to run separately.

**Usage:**
```cmd
organize-all-meetings.cmd "folder_path" [option]
```

**Options:**
- `(no option)` - Run both rename and organize
- `--rename-only` - Only rename, skip organize
- `--organize-only` - Only organize, skip rename

**Examples:**
```cmd
organize-all-meetings.cmd "C:\downloads\meetings"
organize-all-meetings.cmd "D:\MyMeetings" --rename-only
organize-all-meetings.cmd "D:\MyMeetings" --organize-only
```

**What it does:**
1. **Step 1:** Rename generic meeting files (if not using `--organize-only`)
2. **Step 2:** Organize files by project and engineer (if not using `--rename-only`)
3. **Step 3:** Organize remaining special files (if not using `--rename-only`)

**Output:** Shows progress for each step and final success message

---

## Implementation Details

### PowerShell Scripts Used
Each batch file calls corresponding PowerShell scripts in the same directory:

1. **Rename-MeetingFiles.ps1** - Extracts speaker from VTT, renames files
2. **Organize-MeetingFiles.ps1** - Main organization by project/engineer
3. **Organize-RemainingFiles.ps1** - Handles special file categories

### Requirements
- Windows with PowerShell 5.1+
- All .cmd and .ps1 files in the same directory
- Target folder containing meeting .txt files (VTT transcripts)

### Error Handling
- Validates folder exists before processing
- Reports errors and exits with code 1 if any step fails
- Shows helpful error messages

---

## Usage Scenarios

### Scenario 1: New folder of meetings
Process a new folder containing raw Zoom meeting transcripts:
```cmd
organize-all-meetings.cmd "C:\new-meetings"
```
This will rename generic meetings and organize everything.

### Scenario 2: Already renamed meetings
If meetings are already renamed but not organized:
```cmd
organize-all-meetings.cmd "C:\meetings" --organize-only
```

### Scenario 3: Just rename
To only rename without organizing:
```cmd
organize-all-meetings.cmd "C:\meetings" --rename-only
```

### Scenario 4: Use individual commands
For more control:
```cmd
rename-meetings.cmd "C:\meetings"
organize-meetings.cmd "C:\meetings"
```

---

## File Structure After Organization

```
TARGET_FOLDER/
├── Caerus/
│   ├── Engineer1/
│   │   ├── meeting_file.txt
│   │   └── ...
│   └── Engineer2/
│       └── ...
├── MercySeat/
│   ├── Engineer1/
│   └── ...
├── One/
│   └── ...
├── General/
│   ├── Personal Meetings/
│   ├── Checkpoints/
│   ├── Meetings/
│   └── Uncategorized/
└── [Other Projects]/
```

---

## Tips

1. **Backup first:** Keep a copy of original files before processing large batches
2. **Preview:** Run the `Organize-MeetingFiles-Preview.ps1` script first to see proposed structure
3. **Test:** Try on a small folder first to verify results
4. **Parameters:** All commands support full paths with spaces: `"C:\My Documents\Meetings"`
5. **Rerun safe:** Safe to rerun on same folder (won't duplicate, will skip existing)

---

## Support Files

- **README-RENAME.md** - Details on rename functionality
- **ORGANIZATION-COMPLETE.md** - Summary of organization results
- **Organize-MeetingFiles-Preview.ps1** - Preview proposed folder structure before running
