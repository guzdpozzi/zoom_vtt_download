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
Write-Host "Meeting Files Organization Preview" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Source folder: $FolderPath" -ForegroundColor Cyan
Write-Host ""

# Known projects/companies
$projectMap = @{
    "caerus" = "Caerus"
    "syneos" = "Syneos"
    "syneos health" = "Syneos"
    "ucr" = "UCR"
    "medical_solutions" = "Medical Solutions"
    "medical solutions" = "Medical Solutions"
    "medicalsolutions" = "Medical Solutions"
    "backops_ai" = "BackOps AI"
    "backops" = "BackOps"
    "backops ai" = "BackOps AI"
    "mercyseat" = "MercySeat"
    "onepay" = "OnePay"
    "spring_health" = "Spring Health"
    "spring health" = "Spring Health"
    "springhealth" = "Spring Health"
    "dansons" = "Dansons"
    "one finance" = "One Finance"
    "one" = "One"
    "bairesdev" = "BairesDev"
}

function ExtractProjectFromFilename {
    param([string]$filename)
    foreach ($key in $projectMap.Keys) {
        if ($filename -match $key) {
            return $projectMap[$key]
        }
    }
    return $null
}

function ExtractProjectFromContent {
    param([string]$content)
    foreach ($key in $projectMap.Keys) {
        if ($content -match $key) {
            return $projectMap[$key]
        }
    }
    return $null
}

function ExtractEngineerFromFilename {
    param([string]$filename)
    if ($filename -match '_-_([^-]+?)(?:_-_|\.txt)') {
        return $Matches[1].Trim()
    }
    return $null
}

function GetSafeFilename {
    param([string]$name)
    $invalid = @('[', ']', '{', '}', '(', ')', '<', '>', ':', '"', '|', '?', '*', '/')
    foreach ($char in $invalid) {
        $name = $name.Replace($char, '')
    }
    return $name.Trim()
}

# Get all text files
$files = Get-ChildItem -Path $FolderPath -Filter "*.txt" -File

Write-Host "Found $($files.Count) files" -ForegroundColor Cyan
Write-Host ""

$previewData = @()
$countByProjectAndEngineer = @{}

foreach ($file in $files) {
    try {
        $filename = $file.Name
        
        # Extract engineer name
        $engineer = ExtractEngineerFromFilename $filename
        if (-not $engineer) {
            continue
        }
        
        $engineer = $engineer -replace '_', ' '
        $engineer = GetSafeFilename $engineer
        
        # Extract project
        $project = ExtractProjectFromFilename $filename
        
        if (-not $project) {
            try {
                $content = Get-Content -Path $file.FullName -Raw
                $project = ExtractProjectFromContent $content
            } catch { }
        }
        
        if (-not $project) {
            $project = "Other"
        }
        
        $project = GetSafeFilename $project
        
        $previewData += [PSCustomObject]@{
            OriginalFile = $filename
            Project = $project
            Engineer = $engineer
            TargetPath = "$project/$engineer"
        }
        
        # Count
        $key = "$project|$engineer"
        if (-not $countByProjectAndEngineer[$key]) {
            $countByProjectAndEngineer[$key] = 0
        }
        $countByProjectAndEngineer[$key]++
        
    } catch { }
}

# Show preview grouped by project and engineer
$groupedByProject = $previewData | Group-Object -Property Project | Sort-Object -Property Name

Write-Host "PROPOSED FOLDER STRUCTURE:" -ForegroundColor Cyan
Write-Host ""

foreach ($projectGroup in $groupedByProject) {
    Write-Host "  [$($projectGroup.Name)]" -ForegroundColor Yellow
    $engineerGroups = $projectGroup.Group | Group-Object -Property Engineer | Sort-Object -Property Name
    
    foreach ($engineerGroup in $engineerGroups) {
        $count = $engineerGroup.Count
        Write-Host "    ├─ $($engineerGroup.Name) ($count files)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Show summary statistics
Write-Host "SUMMARY STATISTICS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total files to organize: $($previewData.Count)" -ForegroundColor Green
Write-Host "  Total projects: $($groupedByProject.Count)" -ForegroundColor Green
Write-Host ""

foreach ($projectGroup in $groupedByProject) {
    $engineerCount = ($projectGroup.Group | Group-Object -Property Engineer).Count
    $fileCount = $projectGroup.Count
    Write-Host "  $($projectGroup.Name): $fileCount files, $engineerCount engineers" -ForegroundColor White
}

Write-Host ""
Write-Host "To apply this organization, run:" -ForegroundColor Cyan
Write-Host "  .\Organize-MeetingFiles.ps1 -FolderPath `"$FolderPath`"" -ForegroundColor Yellow
Write-Host ""
