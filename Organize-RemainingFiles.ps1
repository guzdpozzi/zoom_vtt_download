param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "Organizing Remaining Files" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

$movedCount = 0
$skippedCount = 0

# Files in root
$rootFiles = Get-ChildItem -Path $FolderPath -Filter "*.txt" -File

Write-Host "Found $($rootFiles.Count) files in root to organize" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $rootFiles) {
    $filename = $file.Name
    
    # Determine folder based on filename content
    $targetFolder = $null
    $folderName = $null
    
    if ($filename -match "Gustavo_Pozzi") {
        # Personal meeting room - put in General
        $targetFolder = "General"
        $folderName = "Personal Meetings"
    }
    elseif ($filename -match "CP_about|CP_") {
        # Check-in/Checkpoint - need to extract from content
        try {
            $content = Get-Content -Path $file.FullName -Raw
            
            # Try to extract project or person from content
            $projects = @("Caerus", "Medical Solutions", "Syneos", "BackOps", "OnePay", "MercySeat", "Spring Health", "UCR", "Dansons")
            $targetProject = $null
            
            foreach ($project in $projects) {
                if ($content -match $project) {
                    $targetProject = $project
                    break
                }
            }
            
            if ($targetProject) {
                $targetFolder = $targetProject
                $folderName = "Checkpoints"
            } else {
                $targetFolder = "General"
                $folderName = "Checkpoints"
            }
        } catch {
            $targetFolder = "General"
            $folderName = "Checkpoints"
        }
    }
    elseif ($filename -match "Feedback|Review|Status|Management_Team|Team_Building|Onboarding|Walkthrough|JIRA|Testathon|Budget|Org_Chart|Wipe") {
        # Project-related meetings - try to extract project
        try {
            $content = Get-Content -Path $file.FullName -Raw
            
            $projects = @("Caerus", "Medical Solutions", "Syneos", "BackOps", "OnePay", "MercySeat", "Spring Health", "UCR", "Dansons")
            $targetProject = $null
            
            foreach ($project in $projects) {
                if ($content -match $project) {
                    $targetProject = $project
                    break
                }
            }
            
            if ($targetProject) {
                $targetFolder = $targetProject
                $folderName = "General"
            } else {
                $targetFolder = "General"
                $folderName = "Meetings"
            }
        } catch {
            $targetFolder = "General"
            $folderName = "Meetings"
        }
    }
    else {
        # Try to extract from content
        try {
            $content = Get-Content -Path $file.FullName -Raw
            
            $projects = @("Caerus", "Medical Solutions", "Syneos", "BackOps", "OnePay", "MercySeat", "Spring Health", "UCR", "Dansons")
            $targetProject = $null
            
            foreach ($project in $projects) {
                if ($content -match $project) {
                    $targetProject = $project
                    break
                }
            }
            
            if ($targetProject) {
                $targetFolder = $targetProject
                $folderName = "General"
            } else {
                $targetFolder = "General"
                $folderName = "Uncategorized"
            }
        } catch {
            $targetFolder = "General"
            $folderName = "Uncategorized"
        }
    }
    
    if ($targetFolder) {
        $targetPath = Join-Path $FolderPath "$targetFolder\$folderName"
        
        if (-not (Test-Path -Path $targetPath)) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }
        
        $newFilePath = Join-Path $targetPath $filename
        
        if (Test-Path -Path $newFilePath) {
            Write-Host "[SKIP] $filename (already exists)" -ForegroundColor Yellow
            $skippedCount++
        } else {
            Move-Item -Path $file.FullName -Destination $newFilePath
            Write-Host "[OK] $filename -> $targetFolder/$folderName/" -ForegroundColor Green
            $movedCount++
        }
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Magenta
Write-Host "Total moved: $movedCount" -ForegroundColor Green
Write-Host "Skipped: $skippedCount" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Magenta
Write-Host ""
