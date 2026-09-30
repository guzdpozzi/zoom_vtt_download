param(
    [Parameter(Mandatory=$true, HelpMessage="Path to the folder containing meeting files")]
    [string]$FolderPath
)

# Validate folder exists
if (-not (Test-Path -Path $FolderPath -PathType Container)) {
    Write-Host "ERROR: Folder does not exist: $FolderPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "Meeting File Rename Tool" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Target folder: $FolderPath" -ForegroundColor Cyan
Write-Host ""

$renameCount = 0
$errorCount = 0

# Get all Zoom_Meeting and Google_Calendar_Meeting files
$files = @(Get-ChildItem -Path $FolderPath -Filter '*Zoom_Meeting.txt' -ErrorAction SilentlyContinue) + @(Get-ChildItem -Path $FolderPath -Filter '*Google_Calendar_Meeting*.txt' -ErrorAction SilentlyContinue)

Write-Host "Found $($files.Count) files to process" -ForegroundColor Cyan
Write-Host ""

function ConvertToProperCase {
    param([string]$text)
    
    # Handle email-like format: mateus.rodrigues -> Mateus Rodrigues
    if ($text -match '^\w+\.\w+$') {
        $parts = $text -split '\.'
        return ($parts | ForEach-Object { [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($_) }) -join ' '
    }
    
    # Regular name: convert to title case
    return [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($text)
}

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Extract speaker names from VTT format
        $speakers = @()
        $lines = $content -split '\n'
        
        foreach ($line in $lines) {
            if ($line -match '^([^:]+):\s+') {
                $speaker = $Matches[1].Trim()
                if ($speaker -and $speaker -ne 'Gustavo Pozzi' -and $speaker -ne 'WEBVTT' -and $speakers -notcontains $speaker) {
                    $speakers += $speaker
                }
            }
        }
        
        if ($speakers.Count -gt 0) {
            $mainParticipant = $speakers[0]
            $oldName = $file.Name
            
            # Extract timestamp from filename
            if ($oldName -match '^(\d{8}_\d{6})') {
                $timestamp = $Matches[1]
                
                # Convert to proper case
                $properName = ConvertToProperCase $mainParticipant
                $newName = "$timestamp`_1_1_-_$properName.txt"
                $newPath = Join-Path $FolderPath $newName
                
                # Check if new name already exists
                if (Test-Path $newPath) {
                    Write-Host "[SKIP] $oldName (target already exists)" -ForegroundColor Yellow
                    $errorCount++
                } else {
                    # Perform the rename
                    Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                    Write-Host "[OK] $oldName -> $newName" -ForegroundColor Green
                    $renameCount++
                }
            }
        }
    } catch {
        Write-Host "[ERROR] Error processing $($file.Name): $_" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Magenta
Write-Host "Total renamed: $renameCount" -ForegroundColor Green
Write-Host "Errors/Skipped: $errorCount" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Magenta
Write-Host ""
