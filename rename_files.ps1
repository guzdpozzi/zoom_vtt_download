$downloadsPath = 'c:\Baires\zoom_vtt_download\downloads'
$renameCount = 0
$errorCount = 0

# Get all Zoom_Meeting and Google_Calendar_Meeting files
$files = @(Get-ChildItem -Path $downloadsPath -Filter '*Zoom_Meeting.txt') + @(Get-ChildItem -Path $downloadsPath -Filter '*Google_Calendar_Meeting*.txt')

Write-Host "Starting rename of $($files.Count) files..." -ForegroundColor Cyan

function ConvertToProperCase {
    param([string]$text)
    
    # Handle special cases
    if ($text -match '^\w+\.\w+$') {
        # Email-like format: mateus.rodrigues -> Mateus Rodrigues
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
                $newPath = Join-Path $downloadsPath $newName
                
                # Check if new name already exists
                if (Test-Path $newPath) {
                    Write-Host "[SKIP] $oldName (target already exists)" -ForegroundColor Yellow
                    $errorCount++
                } else {
                    # Perform the rename
                    Rename-Item -Path $file.FullName -NewName $newName
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

Write-Host "`n================================" -ForegroundColor Magenta
Write-Host "Total renamed: $renameCount" -ForegroundColor Green
Write-Host "Errors/Skipped: $errorCount" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Magenta
