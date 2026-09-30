$downloadsPath = 'c:\Baires\zoom_vtt_download\downloads'
$results = @()

# Get all Zoom_Meeting and Google_Calendar_Meeting files
$files = @(Get-ChildItem -Path $downloadsPath -Filter '*Zoom_Meeting.txt') + @(Get-ChildItem -Path $downloadsPath -Filter '*Google_Calendar_Meeting*.txt')

Write-Host "Found $($files.Count) files to process" -ForegroundColor Cyan

foreach ($file in $files | Select-Object -First 30) {
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
                $newName = "$timestamp`_1_1_-_$($mainParticipant).txt"
                
                $results += [PSCustomObject]@{
                    OldName = $oldName
                    NewName = $newName
                    Participant = $mainParticipant
                    FullPath = $file.FullName
                }
            }
        }
    } catch {
        Write-Host "Error processing $($file.Name): $_" -ForegroundColor Red
    }
}

# Show preview
Write-Host "`n=== PROPOSED RENAMES ===" -ForegroundColor Magenta
$results | ForEach-Object {
    Write-Host "`nOLD: $($_.OldName)" -ForegroundColor Yellow
    Write-Host "NEW: $($_.NewName)" -ForegroundColor Green
    Write-Host "Participant: $($_.Participant)" -ForegroundColor Cyan
}

Write-Host "`n`nTotal files to rename: $($results.Count)" -ForegroundColor Magenta

# Export results for confirmation
$results | Export-Csv -Path 'c:\Baires\zoom_vtt_download\rename_preview.csv' -NoTypeInformation
Write-Host "`nResults exported to rename_preview.csv" -ForegroundColor Green
