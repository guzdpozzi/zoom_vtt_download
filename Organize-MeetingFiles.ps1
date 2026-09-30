param(
    [Parameter(Mandatory=$true, HelpMessage="Path to the folder containing meeting files")]
    [string]$FolderPath,
    
    [Parameter(HelpMessage="Create archive subfolder for organized files")]
    [switch]$CreateArchive
)

# Validate folder exists
if (-not (Test-Path -Path $FolderPath -PathType Container)) {
    Write-Host "ERROR: Folder does not exist: $FolderPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "Meeting Files Organization Tool" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Source folder: $FolderPath" -ForegroundColor Cyan
Write-Host ""

$organizedCount = 0
$errorCount = 0
$skipCount = 0

# Known projects/companies (can be expanded)
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
    "one finance - lucas" = "One Finance"
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
    
    # Look for company mentions in the transcript
    foreach ($key in $projectMap.Keys) {
        if ($content -match $key) {
            return $projectMap[$key]
        }
    }
    
    return $null
}

function ExtractEngineerFromFilename {
    param([string]$filename)
    
    # Pattern: TIMESTAMP_TYPE_-_ENGINEER_-_PROJECT or TIMESTAMP_TYPE_-_ENGINEER
    # Extract the part between the first dash and either another dash or .txt
    if ($filename -match '_-_([^-]+?)(?:_-_|\.txt)') {
        $engineer = $Matches[1].Trim()
        return $engineer
    }
    
    return $null
}

function GetSafeFilename {
    param([string]$name)
    
    # Remove invalid filename characters
    $invalid = @('[', ']', '{', '}', '(', ')', '<', '>', ':', '"', '|', '?', '*', '/')
    foreach ($char in $invalid) {
        $name = $name.Replace($char, '')
    }
    
    # Remove leading/trailing spaces
    $name = $name.Trim()
    
    return $name
}

# Get all text files
$files = Get-ChildItem -Path $FolderPath -Filter "*.txt" -File

Write-Host "Found $($files.Count) files to organize" -ForegroundColor Cyan
Write-Host ""

$filesByProject = @{}

foreach ($file in $files) {
    try {
        $filename = $file.Name
        
        # Extract engineer name from filename
        $engineer = ExtractEngineerFromFilename $filename
        if (-not $engineer) {
            Write-Host "[SKIP] $filename (cannot extract engineer name)" -ForegroundColor Yellow
            $skipCount++
            continue
        }
        
        # Clean up engineer name
        $engineer = $engineer -replace '_', ' '
        $engineer = GetSafeFilename $engineer
        
        # Extract project from filename first
        $project = ExtractProjectFromFilename $filename
        
        # If not found in filename, try to extract from content
        if (-not $project) {
            try {
                $content = Get-Content -Path $file.FullName -Raw
                $project = ExtractProjectFromContent $content
            } catch {
                # If we can't read the file, skip it
            }
        }
        
        # If still not found, use "Other"
        if (-not $project) {
            $project = "Other"
        }
        
        # Clean up project name
        $project = GetSafeFilename $project
        
        # Create folder structure
        $projectFolder = Join-Path $FolderPath $project
        $engineerFolder = Join-Path $projectFolder $engineer
        
        # Create directories if they don't exist
        if (-not (Test-Path -Path $engineerFolder)) {
            New-Item -ItemType Directory -Path $engineerFolder -Force | Out-Null
        }
        
        # Build the new path
        $newPath = Join-Path $engineerFolder $filename
        
        # Check if file already exists in destination
        if (Test-Path -Path $newPath) {
            Write-Host "[SKIP] $filename (already exists at destination)" -ForegroundColor Yellow
            $skipCount++
            continue
        }
        
        # Move the file
        Move-Item -Path $file.FullName -Destination $newPath -ErrorAction Stop
        Write-Host "[OK] $filename -> $project/$engineer/" -ForegroundColor Green
        $organizedCount++
        
        # Track for summary
        if (-not $filesByProject[$project]) {
            $filesByProject[$project] = @{}
        }
        $filesByProject[$project][$engineer] = $filesByProject[$project][$engineer] + 1
        
    } catch {
        Write-Host "[ERROR] Error processing $($file.Name): $_" -ForegroundColor Red
        $errorCount++
    }
}

# Print summary
Write-Host ""
Write-Host "================================" -ForegroundColor Magenta
Write-Host "Total organized: $organizedCount" -ForegroundColor Green
Write-Host "Skipped: $skipCount" -ForegroundColor Yellow
Write-Host "Errors: $errorCount" -ForegroundColor Red
Write-Host "================================" -ForegroundColor Magenta

# Print folder structure summary
if ($filesByProject.Count -gt 0) {
    Write-Host ""
    Write-Host "Organization Summary:" -ForegroundColor Cyan
    foreach ($project in $filesByProject.Keys | Sort-Object) {
        Write-Host "  [$project]" -ForegroundColor Yellow
        foreach ($engineer in $filesByProject[$project].Keys | Sort-Object) {
            Write-Host "    - $engineer" -ForegroundColor Gray
        }
    }
}

Write-Host ""
